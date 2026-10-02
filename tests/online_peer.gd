extends Node

var qa_id = "local"
var result_dir = "res://../results"
var last_seq = -1
var busy = false
var current_op = ""
var extra = {}
var elapsed = 0.0

func _ready():
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("qa-id="): qa_id = arg.trim_prefix("qa-id=")
		if arg.begins_with("qa-results="): result_dir = arg.trim_prefix("qa-results=")
	call_deferred("_start")

func _start():
	reparent(Global)
	get_tree().current_scene = null
	write_json(qa_id + "_ready.json", {"ready": true})

func write_json(filename: String, data):
	var f = FileAccess.open(result_dir.path_join(filename), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()

func _process(delta):
	elapsed += delta
	if busy or elapsed < 0.1: return
	elapsed = 0
	var path = result_dir.path_join(qa_id + "_command.json")
	if not FileAccess.file_exists(path): return
	var c = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not c is Dictionary or int(c.get("seq", -1)) <= last_seq: return
	last_seq = int(c.seq)
	busy = true
	current_op = c.op
	extra = {}
	print("QA_BEGIN ", qa_id, " ", last_seq, " ", current_op)
	await execute(c)
	await get_tree().create_timer(float(c.get("settle", 0.7))).timeout
	var s = snapshot()
	s["seq"] = last_seq
	s["op"] = current_op
	s["extra"] = extra
	write_json(qa_id + "_" + str(last_seq) + ".json", s)
	write_json(qa_id + "_latest.json", s)
	print("QA_END ", qa_id, " ", last_seq, " ", current_op)
	busy = false

func change(path: String):
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout

func blank_field():
	return {"name": "QA empty board", "canvas_settings": {"size_x": 1500, "size_y": 1000}, "components_layout": []}

func get_component(id: String):
	var s = get_tree().current_scene
	if s and s.has_method("_find_component"): return s._find_component(id)
	return null

func execute(c: Dictionary):
	var s = get_tree().current_scene
	match c.op:
		"snapshot": pass
		"scene":
			await change(c.path)
		"boot":
			await change("res://scenes/LoadingScreen.tscn")
		"local_start":
			await change("res://scenes/RoomList.tscn")
			s = get_tree().current_scene
			s._on_local_mode_selected()
			s._on_local_field_selected("res://fields/test1.json")
			s.count_spin.value = int(c.get("players", 2))
			s._on_confirm_create_pressed()
		"create_live_room":
			await change("res://scenes/RoomList.tscn")
			s = get_tree().current_scene
			s.is_online_mode = true
			s._on_create_room_pressed()
			s.get_node("RoomCreatorPanel/VBoxContainer/RoomName").text = "QA_CratAble_20261002"
			s.get_node("RoomCreatorPanel/VBoxContainer/Password").text = "qa-password"
			Global.loaded_field_data = blank_field()
			s._on_confirm_create_pressed()
		"join_live_room":
			await change("res://scenes/RoomList.tscn")
			s = get_tree().current_scene
			s._on_join_room_clicked({"id": c.id, "has_password": true})
			var dialog = s.get_child(s.get_child_count() - 1)
			for child in dialog.get_children():
				if child is LineEdit: child.text = c.password
			dialog.confirmed.emit()
		"exit_live_room":
			s.get_node("Header/BackBtn").pressed.emit()
		"online_start":
			Global.reset_online_session()
			Global.online_room_id = "QA_CratAble_20261002"
			Global.online_room_data = {"channel_id": c.channel}
			Global.online_player_role = c.role
			Global.online_player_name = "QA_" + c.role
			Global.loaded_field_data = blank_field()
			Global.play_mode = true
			await change("res://SCENE/Main.tscn")
		"drop_hand":
			var card = s.hand_zone.get_child(0)
			extra["card_id"] = str(card.get_meta("component_id", card.name))
			extra["drag_end_connections"] = card.drag_ended.get_connections().size()
			card.drag_started.emit()
			var drop_point = s.field_canvas.get_global_transform() * Vector2(float(c.x), float(c.y))
			s._on_card_drag_ended(card, drop_point)
		"return_private_card":
			s._insert_card_into_deck(s.hand_zone.get_child(0), get_component(c.id), true)
		"click_dice":
			var dice = get_component(c.id)
			dice.locked = true
			dice.get_node("DiceLabel").text = "D6: -"
			var press = InputEventMouseButton.new()
			press.button_index = MOUSE_BUTTON_LEFT
			press.position = dice.size / 2
			press.pressed = true
			dice._gui_input(press)
			press.pressed = false
			dice._gui_input(press)
		"rotate_handle":
			var n = get_component(c.id)
			var handle = n.get_node("RotateHandle")
			var center = n.get_global_transform() * n.pivot_offset
			var press = InputEventMouseButton.new()
			press.button_index = MOUSE_BUTTON_LEFT
			press.pressed = true
			press.global_position = center + Vector2(100, 0)
			handle.gui_input.emit(press)
			var motion = InputEventMouseMotion.new()
			motion.global_position = center + Vector2(0, 100)
			handle.gui_input.emit(motion)
			press.pressed = false
			press.global_position = motion.global_position
			handle.gui_input.emit(press)
		"deck":
			var dd = {"deck_name": "QA six cards", "groups": [{"name": "QA", "cards": {"res://cards/Blade_Fairy.json": 2, "res://cards/Gunner_Fairy.json": 2, "res://cards/Maid_Fairy.json": 2}}]}
			var d = s.spawn_deck_object(dd)
			d.name = c.get("id", "QADeck")
			d.set_meta("component_id", str(d.name))
			d.position = Vector2(100, 100)
			s._confirm_deck_programmatically(d)
		"draw":
			s._on_deck_left_clicked(get_component(c.id))
		"counter":
			var n = get_component(c.id)
			n.set_value(int(c.value))
		"add_counter":
			var n = s._on_add_counter_pressed()
			extra["created_id"] = str(n.get_meta("component_id", n.name))
		"add_dice":
			var n = s._on_add_dice_pressed()
			extra["created_id"] = str(n.get_meta("component_id", n.name))
		"roll":
			get_component(c.id).left_clicked.emit()
		"add_zone":
			var n = s._spawn_zone("Card Zone")
			extra["created_id"] = str(n.get_meta("component_id", n.name))
		"card":
			var cd = {"name": "QA custom card", "image_path": "res://card_images/Blade_Fairy_img.PNG", "atk": 123, "file_path": ""}
			var n = s.spawn_card_object(cd)
			n.name = c.get("id", "QACard")
			n.set_meta("component_id", str(n.name))
			n.position = Vector2(350, 250)
			if is_instance_valid(s.realtime_client):
				s.realtime_client.send_broadcast("card_spawned", {"card_name": str(n.name), "card_path": "", "parent_name": str(s.field_canvas.name), "x": 350, "y": 250, "rot": 0, "card_data": cd})
		"flip":
			s._set_card_face_down(get_component(c.id), bool(c.get("down", true)))
		"tap":
			s._toggle_card_tap(get_component(c.id))
		"move":
			var n = get_component(c.id)
			n.position = Vector2(float(c.x), float(c.y))
			if is_instance_valid(s.realtime_client): s.realtime_client.broadcast_card_moved(c.id, str(s.field_canvas.name), n.position)
		"to_hand":
			s._add_card_to_hand(get_component(c.id))
		"switch_player":
			s._switch_active_player(int(c.index))
		"request_sync":
			s.realtime_client.send_broadcast("request_field_state", {"requester_id": Global.online_player_name})
		"disconnect":
			s.realtime_client.socket.close()
		"exit_button":
			Global.online_room_id = ""
			s.get_node("Header/BackBtn").pressed.emit()
		"card_roundtrip":
			Global.current_card_data = {}
			await change("res://scenes/CardEditor.tscn")
			s = get_tree().current_scene
			s.card_name.text = "QA saved card"
			s._on_file_selected("res://card_images/Blade_Fairy_img.PNG")
			s._add_custom_stat("power", 250)
			extra["requested_custom_stat"] = 250
			extra["actual_custom_stat"] = s.custom_stats_container.get_child(0).get_child(1).value
			var p = result_dir.path_join("qa_saved_card.json")
			s._save_card_to_file(p)
			var saved = JSON.parse_string(FileAccess.get_file_as_string(p))
			extra["saved_image_path"] = saved.get("image_path", "")
			Global.current_card_data = saved
			await change("res://scenes/CardEditor.tscn")
			s = get_tree().current_scene
			extra["reopened_image_path"] = s.current_image_path
			extra["reopened_has_texture"] = s.preview_image.texture != null
		"counter_hold":
			var n = get_component(c.id)
			n.set_value(10, false)
			n.is_pressing = true
			n.press_direction = 1
			n.is_dragging_really = false
			n.hold_time = 0
			n._process(0.6)
			var e = InputEventMouseButton.new()
			e.button_index = MOUSE_BUTTON_LEFT
			e.pressed = false
			n._gui_input(e)
			extra["value_after_long_press_release"] = n.value
			extra["dialog_visible"] = n.amount_popup.visible
		"state_roundtrip":
			var before = s._capture_current_field_state()
			write_json(qa_id + "_state_before.json", before)
			s._load_field_from_dict(before)
			await get_tree().process_frame
			write_json(qa_id + "_state_after.json", s._capture_current_field_state())
		"quit":
			write_json(qa_id + "_quit.json", {"quit": true})
			get_tree().quit()
		_: extra["error"] = "Unknown command"

func walk(n: Node, out: Array):
	if n.has_meta("component_category"):
		var item = {"name": str(n.name), "id": str(n.get_meta("component_id", n.name)), "category": n.get_meta("component_category"), "parent": str(n.get_parent().name), "x": n.position.x, "y": n.position.y, "rotation": n.rotation_degrees}
		for k in ["draw_pile", "deck_confirmed", "is_face_down", "in_hand", "counter_value"]:
			if n.has_meta(k): item[k] = n.get_meta(k)
		if n.has_meta("card_data"):
			var cd = n.get_meta("card_data")
			item["card_name"] = cd.get("name", "")
			item["card_atk"] = cd.get("atk", -1)
		if n.has_method("set_value"): item["value"] = n.value
		if n.has_node("DiceLabel"): item["dice"] = n.get_node("DiceLabel").text
		out.append(item)
	for ch in n.get_children(): walk(ch, out)

func snapshot():
	var s = get_tree().current_scene
	var data = {"scene": s.scene_file_path if s else "", "room_id": Global.online_room_id, "role": Global.online_player_role, "player": Global.online_player_name, "play_mode": Global.play_mode, "active_player": Global.local_active_player_idx, "cached_cards": SupabaseService.card_cache.size(), "pending_images": SupabaseService.pending_requests.size()}
	if not s: return data
	var components = []
	walk(s, components)
	data["components"] = components
	if "realtime_client" in s and is_instance_valid(s.realtime_client):
		data["connected"] = s.realtime_client.is_connected
		data["socket_state"] = s.realtime_client.socket.get_ready_state()
	if "hand_zone" in s and is_instance_valid(s.hand_zone): data["hand_count"] = s.hand_zone.get_child_count()
	if "field_canvas" in s and is_instance_valid(s.field_canvas): data["field_rotation"] = s.field_canvas.rotation_degrees
	if "status_label" in s: data["loading_text"] = s.status_label.text
	if "action_log_vbox" in s and is_instance_valid(s.action_log_vbox): data["action_logs"] = s.action_log_vbox.get_child_count()
	return data
