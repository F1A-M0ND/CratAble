extends Node

class FakeService extends Node:
	var calls = []
	var reply: Callable
	func request_supabase(path, _method, body, _headers, callback):
		calls.append({"path": path, "body": body})
		reply = callback

var checks = 0
var failures = 0
var expired_count = 0

func check(label: String, passed: bool):
	checks += 1
	if not passed:
		failures += 1
		push_error("ROOM_SESSION: " + label)

func _ready(): call_deferred("run")

func run():
	var api = FakeService.new()
	add_child(api)
	var monitor = preload("res://scripts/RoomSession.gd").new()
	add_child(monitor)
	monitor.expired.connect(func(): expired_count += 1)
	monitor.start(api, "", "")
	check("no local request", api.calls.is_empty())
	monitor.start(api, "fixture-room", "fixture-token")
	check("immediate authenticated heartbeat", api.calls.size() == 1 and api.calls[0].body.p_token == "fixture-token")
	check("recurring heartbeat", monitor.timer.wait_time == 30.0 and not monitor.timer.is_stopped())
	monitor.send_heartbeat()
	check("no overlapping requests", api.calls.size() == 1)
	api.reply.call(0, null)
	check("transient failure keeps room", expired_count == 0 and not monitor.stopped)
	monitor.send_heartbeat()
	check("retry after failure", api.calls.size() == 2)
	api.reply.call(200, {"active": true})
	check("active session retained", expired_count == 0)
	monitor.send_heartbeat()
	api.reply.call(200, {"active": false})
	check("expired session stops", expired_count == 1 and monitor.stopped and monitor.timer.is_stopped())
	monitor.send_heartbeat()
	check("no heartbeat after stop", api.calls.size() == 3)
	monitor.queue_free()
	await get_tree().process_frame
	check("restore normal quit", get_tree().auto_accept_quit)
	monitor = preload("res://scripts/RoomSession.gd").new()
	add_child(monitor)
	monitor.start(api, "fixture-room", "fixture-token")
	api.reply.call(404, {})
	check("missing deployment stops retries", monitor.stopped)
	monitor.queue_free()
	api.queue_free()
	await get_tree().process_frame
	print("ROOM_SESSION_RESULT ", checks - failures, "/", checks)
	get_tree().quit(1 if failures else 0)
