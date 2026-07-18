extends Node

signal card_moved(card_name: String, position: Vector2)
signal card_flipped(card_name: String, is_down: bool)
signal card_tapped(card_name: String, tapped: bool)
signal deck_shuffled(deck_name: String)
signal connection_established()
signal connection_closed()

signal card_spawned(card_name: String, card_data: Dictionary, position: Vector2)
signal card_sent_to_hand(card_name: String)
signal card_inserted_into_deck(card_name: String, deck_name: String, to_top: bool)
signal deck_drawn(deck_name: String)
signal zone_shuffled(zone_name: String)

var socket = WebSocketPeer.new()
var is_connected = false
var room_id = ""
var apikey = ""
var channel_name = ""
var heartbeat_timer: Timer
var ref_id = 1

func connect_to_room(room_uuid: String, key: String):
	room_id = room_uuid
	apikey = key
	channel_name = "realtime:room_" + room_id
	
	var url = SupabaseService.SUPABASE_URL.replace("https://", "wss://") + "/realtime/v1/websocket?apikey=" + apikey + "&vsn=1.0.0"
	print("Connecting to Supabase Realtime: ", url)
	var err = socket.connect_to_url(url)
	if err != OK:
		print("Failed to start connection to websocket URL")
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
		if not is_connected:
			is_connected = true
			print("WebSocket Connected! Joining channel: ", channel_name)
			_join_channel()
			heartbeat_timer.start()
			connection_established.emit()
			
		while socket.get_available_packet_count() > 0:
			var packet = socket.get_packet()
			var text = packet.get_string_from_utf8()
			_handle_message(text)
			
	elif state == WebSocketPeer.STATE_CLOSED:
		if is_connected:
			is_connected = false
			heartbeat_timer.stop()
			print("WebSocket Closed!")
			connection_closed.emit()
			set_process(false)

func _join_channel():
	var join_msg = {
		"topic": channel_name,
		"event": "phx_join",
		"payload": {},
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
	socket.send_text(JSON.stringify(msg))

func broadcast_card_moved(card_name: String, global_pos: Vector2):
	send_broadcast("card_moved", {
		"card_name": card_name,
		"x": global_pos.x,
		"y": global_pos.y
	})

func broadcast_card_flipped(card_name: String, is_down: bool):
	send_broadcast("card_flipped", {
		"card_name": card_name,
		"is_down": is_down
	})

func broadcast_card_tapped(card_name: String, tapped: bool):
	send_broadcast("card_tapped", {
		"card_name": card_name,
		"tapped": tapped
	})

func broadcast_deck_shuffled(deck_name: String):
	send_broadcast("deck_shuffled", {
		"deck_name": deck_name
	})

func _handle_message(text: String):
	var json = JSON.new()
	if json.parse(text) != OK: return
	var msg = json.get_data()
	if typeof(msg) != TYPE_DICTIONARY: return
	
	var event = msg.get("event", "")
	var topic = msg.get("topic", "")
	
	if topic != channel_name: return
	
	if event == "broadcast":
		var payload_wrapper = msg.get("payload", {})
		var broadcast_event = payload_wrapper.get("event", "")
		var inner_payload = payload_wrapper.get("payload", {})
		
		match broadcast_event:
			"card_moved":
				var c_name = inner_payload.get("card_name", "")
				var x = inner_payload.get("x", 0.0)
				var y = inner_payload.get("y", 0.0)
				card_moved.emit(c_name, Vector2(x, y))
			"card_flipped":
				var c_name = inner_payload.get("card_name", "")
				var is_down = inner_payload.get("is_down", false)
				card_flipped.emit(c_name, is_down)
			"card_tapped":
				var c_name = inner_payload.get("card_name", "")
				var tapped = inner_payload.get("tapped", false)
				card_tapped.emit(c_name, tapped)
			"deck_shuffled":
				var d_name = inner_payload.get("deck_name", "")
				deck_shuffled.emit(d_name)
			"card_spawned":
				var c_name = inner_payload.get("card_name", "")
				var c_data = inner_payload.get("card_data", {})
				var x = inner_payload.get("x", 0.0)
				var y = inner_payload.get("y", 0.0)
				card_spawned.emit(c_name, c_data, Vector2(x, y))
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
				zone_shuffled.emit(z_name)
