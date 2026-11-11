extends Node

signal expired
var service: Node
var room_id = ""
var token = ""
var timer: Timer
var pending = false
var stopped = false
var quitting = false

func start(api: Node, id: String, session_token: String):
	if id.is_empty() or session_token.is_empty(): return
	service = api
	room_id = id
	token = session_token
	timer = Timer.new()
	timer.wait_time = 30.0
	timer.timeout.connect(send_heartbeat)
	add_child(timer)
	timer.start()
	get_tree().auto_accept_quit = false
	send_heartbeat()

func send_heartbeat():
	if stopped or pending or not is_instance_valid(service): return
	pending = true
	var self_ref = weakref(self)
	service.request_supabase("/rest/v1/rpc/cratable_room_heartbeat", HTTPClient.METHOD_POST,
		{"p_room_id": room_id, "p_token": token}, Callable(), func(status, data):
			var session = self_ref.get_ref()
			if not is_instance_valid(session): return
			session.pending = false
			if session.stopped: return
			if status == 404:
				# Deployment has not reached this server yet; avoid repeated missing-RPC requests.
				session.stop()
			elif status == 200 and data is Dictionary and data.get("active") == false:
				session.stop()
				session.expired.emit()
	)

func stop():
	stopped = true
	if is_instance_valid(timer): timer.stop()

func _notification(what):
	if what != NOTIFICATION_WM_CLOSE_REQUEST or quitting or room_id.is_empty(): return
	quitting = true
	stop()
	var tree = get_tree()
	# Give graceful exit a short window. A killed/offline process is handled by server expiry.
	service.request_supabase("/rest/v1/rpc/cratable_leave_room", HTTPClient.METHOD_POST,
		{"p_room_id": room_id, "p_token": token}, Callable(), func(_status, _data):
			if is_instance_valid(tree): tree.quit()
	)
	tree.create_timer(2.0).timeout.connect(func():
		if is_instance_valid(tree): tree.quit()
	)

func _exit_tree():
	stop()
	get_tree().auto_accept_quit = true
