extends Node

signal component_state(state: Dictionary)

signal card_moved(card_name: String, parent_name: String, position: Vector2)
signal card_flipped(card_name: String, is_down: bool)
signal card_tapped(card_name: String, target_rot: float)
signal deck_shuffled(deck_name: String, card_array: Array)
signal connection_established()
signal connection_closed()

signal card_spawned(card_name: String, card_path: String, parent_name: String, position: Vector2, rot: float, card_data: Dictionary)
signal card_sent_to_hand(card_name: String)
signal card_inserted_into_deck(card_name: String, deck_name: String, to_top: bool)
signal deck_drawn(deck_name: String)
signal zone_shuffled(zone_name: String, card_array: Array)
signal opponent_hand_updated(player_name: String, count: int)
signal action_logged(text: String)
signal player_joined(player_name: String, role: String)

# --- New Sync Signals ---
signal zone_spawned(zone_type: String, zone_name: String, position: Vector2, size: Vector2)
signal deck_spawned(deck_name: String, deck_data: Dictionary, position: Vector2)
signal dice_spawned(dice_name: String, position: Vector2)
signal dice_rolled(dice_name: String, result: int)
signal counter_spawned(counter_name: String, position: Vector2)
signal counter_updated(counter_name: String, value: int)
signal request_field_state(requester_id: String)
signal sync_field_state(state: Dictionary)

var socket = WebSocketPeer.new()
var is_connected = false
var room_id = ""
var apikey = ""
var channel_name = ""
var heartbeat_timer: Timer
var ref_id = 1
var join_sent = false
var join_ref = ""
var stopped = false

func log_to_file(text: String):
	# Debug details can contain credentials, room snapshots and private cards.
	pass

func connect_to_room(room_uuid: String, key: String):
	if stopped: return
	join_sent = false
	is_connected = false
	socket = WebSocketPeer.new()
	room_id = room_uuid
	apikey = key
	channel_name = "realtime:room_" + room_id
	
	var url = SupabaseService.SUPABASE_URL.replace("https://", "wss://") + "/realtime/v1/websocket?apikey=" + apikey + "&vsn=1.0.0"
	log_to_file("Connecting to Supabase Realtime: " + url)
	var err = socket.connect_to_url(url)
	if err != OK:
		log_to_file("Failed to start connection to websocket URL. Retrying in 3s...")
		var t = get_tree().create_timer(3.0)
		t.timeout.connect(func():
			if is_inside_tree() and not stopped: connect_to_room(room_id, apikey)
		)
		return
		
	set_process(true)

func _ready():
	set_process(false)
	heartbeat_timer = Timer.new()
	heartbeat_timer.wait_time = 30.0
	heartbeat_timer.autostart = false
	heartbeat_timer.timeout.connect(_send_heartbeat)
	add_child(heartbeat_timer)

func _process(delta):
	socket.poll()
	var state = socket.get_ready_state()
	
	if state == WebSocketPeer.STATE_OPEN:
		if not join_sent:
			join_sent = true
			log_to_file("WebSocket Connected! Joining channel: " + channel_name)
			_join_channel()
			heartbeat_timer.start()
			
		while socket.get_available_packet_count() > 0:
			var packet = socket.get_packet()
			var text = packet.get_string_from_utf8()
			_handle_message(text)
			
	elif state == WebSocketPeer.STATE_CLOSED:
		var was_connected = is_connected
		is_connected = false
		heartbeat_timer.stop()
		log_to_file("WebSocket Closed! Attempting reconnect in 3s...")
		if was_connected:
			connection_closed.emit()
		set_process(false)

		var t = get_tree().create_timer(3.0)
		t.timeout.connect(func():
			if is_inside_tree() and not stopped and room_id != "" and apikey != "":
				connect_to_room(room_id, apikey)
		)

func _join_channel():
	join_ref = str(ref_id)
	var join_msg = {
		"topic": channel_name,
		"event": "phx_join",
		"payload": {
			"access_token": apikey,
			"config": {
				"broadcast": {
					"ack": false,
					"self": false
				},
				"presence": {
					"key": ""
				}
			}
		},
		"ref": str(ref_id)
	}
	ref_id += 1
	socket.send_text(JSON.stringify(join_msg))

func _send_heartbeat():
	if not is_connected: return
	var msg = {
		"topic": "phoenix",
		"event": "heartbeat",
		"payload": {},
		"ref": str(ref_id)
	}
	ref_id += 1
	socket.send_text(JSON.stringify(msg))

func send_broadcast(event_name: String, payload: Dictionary):
	if not is_connected: return
	var msg = {
		"topic": channel_name,
		"event": "broadcast",
		"payload": {
			"type": "broadcast",
			"event": event_name,
			"payload": payload
		},
		"ref": str(ref_id)
	}
	ref_id += 1
	log_to_file("Sending broadcast: " + event_name + " payload: " + str(payload))
	socket.send_text(JSON.stringify(msg))

func broadcast_card_moved(card_name: String, parent_name: String, local_pos: Vector2):
	send_broadcast("card_moved", {
		"card_name": card_name,
		"parent_name": parent_name,
		"x": local_pos.x,
		"y": local_pos.y
	})

func broadcast_counter_updated(counter_name: String, value: int):
	send_broadcast("counter_updated", {
		"counter_name": counter_name,
		"value": value
	})

func broadcast_card_flipped(card_name: String, is_down: bool):
	send_broadcast("card_flipped", {
		"card_name": card_name,
		"is_down": is_down
	})

func broadcast_card_tapped(card_name: String, target_rot: float):
	send_broadcast("card_tapped", {
		"card_name": card_name,
		"rot": target_rot
	})

func broadcast_deck_shuffled(deck_name: String, draw_pile: Array):
	send_broadcast("deck_shuffled", {
		"deck_name": deck_name,
		"draw_pile": draw_pile
	})

func _handle_message(text: String):
	log_to_file("Incoming Raw: " + text)
	var json = JSON.new()
	if json.parse(text) != OK: return
	var msg = json.get_data()
	if typeof(msg) != TYPE_DICTIONARY: return
	
	var event = msg.get("event", "")
	var topic = msg.get("topic", "")
	
	if topic != channel_name: return
	if event == "phx_reply" and str(msg.get("ref", "")) == join_ref:
		if msg.get("payload", {}).get("status", "") == "ok":
			is_connected = true
			connection_established.emit()
		else:
			socket.close()
		return
	
	if event == "broadcast":
		var payload_wrapper = msg.get("payload", {})
		var broadcast_event = payload_wrapper.get("event", "")
		var inner_payload = payload_wrapper.get("payload", {})
		print("[Realtime] Received broadcast event: ", broadcast_event)
		
		match broadcast_event:
			"component_state":
				component_state.emit(inner_payload)
			"card_moved":
				var c_name = inner_payload.get("card_name", "")
				var p_name = inner_payload.get("parent_name", "")
				var x = inner_payload.get("x", 0.0)
				var y = inner_payload.get("y", 0.0)
				card_moved.emit(c_name, p_name, Vector2(x, y))
			"card_flipped":
				var c_name = inner_payload.get("card_name", "")
				var is_down = inner_payload.get("is_down", false)
				card_flipped.emit(c_name, is_down)
			"card_tapped":
				var c_name = inner_payload.get("card_name", "")
				var rot = inner_payload.get("rot", 90.0 if inner_payload.get("tapped", false) else 0.0)
				card_tapped.emit(c_name, float(rot))
			"deck_shuffled":
				var d_name = inner_payload.get("deck_name", "")
				var d_pile = inner_payload.get("draw_pile", [])
				deck_shuffled.emit(d_name, d_pile)
			"card_spawned":
				var c_name = inner_payload.get("card_name", "")
				var c_path = inner_payload.get("card_path", "")
				if c_path == "":
					var c_data = inner_payload.get("card_data", {})
					c_path = c_data.get("file_path", c_data.get("image_path", ""))
				var p_name = inner_payload.get("parent_name", "")
				var x = inner_payload.get("x", 0.0)
				var y = inner_payload.get("y", 0.0)
				var rot = inner_payload.get("rot", 0.0)
				card_spawned.emit(c_name, c_path, p_name, Vector2(x, y), float(rot), inner_payload.get("card_data", {}))
			"card_sent_to_hand":
				var c_name = inner_payload.get("card_name", "")
				card_sent_to_hand.emit(c_name)
			"card_inserted_into_deck":
				var c_name = inner_payload.get("card_name", "")
				var d_name = inner_payload.get("deck_name", "")
				var to_top = inner_payload.get("to_top", true)
				card_inserted_into_deck.emit(c_name, d_name, to_top)
			"deck_draw":
				var d_name = inner_payload.get("deck_name", "")
				deck_drawn.emit(d_name)
			"zone_shuffled":
				var z_name = inner_payload.get("zone_name", "")
				var z_cards = inner_payload.get("card_names", [])
				zone_shuffled.emit(z_name, z_cards)
			"opponent_hand_updated":
				var p_name = inner_payload.get("player_name", "")
				var count = inner_payload.get("count", 0)
				opponent_hand_updated.emit(p_name, count)
			"action_logged":
				var txt = inner_payload.get("text", "")
				action_logged.emit(txt)
			"player_joined":
				var p_name = inner_payload.get("player_name", "")
				var role = inner_payload.get("role", "")
				player_joined.emit(p_name, role)
			"zone_spawned":
				zone_spawned.emit(inner_payload.get("zone_type", ""), inner_payload.get("zone_name", ""), Vector2(inner_payload.get("x", 0), inner_payload.get("y", 0)), Vector2(inner_payload.get("w", 150), inner_payload.get("h", 210)))
			"deck_spawned":
				deck_spawned.emit(inner_payload.get("deck_name", ""), inner_payload.get("deck_data", {}), Vector2(inner_payload.get("x", 0), inner_payload.get("y", 0)))
			"dice_spawned":
				dice_spawned.emit(inner_payload.get("dice_name", ""), Vector2(inner_payload.get("x", 0), inner_payload.get("y", 0)))
			"dice_rolled":
				dice_rolled.emit(inner_payload.get("dice_name", ""), inner_payload.get("result", 1))
			"counter_spawned":
				counter_spawned.emit(inner_payload.get("counter_name", ""), Vector2(inner_payload.get("x", 0), inner_payload.get("y", 0)))
			"counter_updated":
				counter_updated.emit(inner_payload.get("counter_name", ""), inner_payload.get("value", 0))
			"request_field_state":
				request_field_state.emit(inner_payload.get("requester_id", ""))
			"sync_field_state":
				sync_field_state.emit(inner_payload.get("state", {}))

func disconnect_from_room():
	stopped = true
	is_connected = false
	set_process(false)
	if is_instance_valid(heartbeat_timer): heartbeat_timer.stop()
	socket.close()

func _exit_tree():
	disconnect_from_room()
