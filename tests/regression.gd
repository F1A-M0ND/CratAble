extends Node
var evidence = {}
var runner
var result_dir = "user://"
func record(key, data):
	evidence[key] = data
	runner.write_json("local_suite.json", evidence)
	print("QA_LOCAL_CASE ", key, " ", JSON.stringify(data))

func _ready():
	runner = self
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("qa-results="): result_dir = arg.trim_prefix("qa-results=")
	call_deferred("run")

func run():
	SupabaseService.card_cache["qa-uuid"] = {"name": "QA cached card", "stats": {"atk": 250}}
	Global.online_room_id = ""
	Global.online_player_role = "Host"
	Global.play_mode = false
	Global.local_player_count = 1
	Global.loaded_field_data = {}
	Global.loaded_field_path = ""
	var de = load("res://scenes/DeckEditor.tscn").instantiate()
	add_child(de)
	await get_tree().create_timer(1.0).timeout
	de._add_card_copies("res://cards/Blade_Fairy.json", 3)
	var dp = runner.result_dir.path_join("qa_deck.json")
	de._save_deck_to_file(dp)
	_hide_dialogs(de)
	de._load_deck_from_file(dp)
	record("deck_new_format_roundtrip", {"groups": de.deck_data.get("groups", []).size(), "copies": de.deck_data.get("groups", [{}])[0].get("cards", {}).get("res://cards/Blade_Fairy.json", 0)})
	de._load_deck_from_file("res://deck/Test.json")
	record("bundled_deck_load", {"has_groups": de.deck_data.has("groups"), "group_count": de.deck_data.get("groups", []).size()})
	if SupabaseService.card_cache.size() > 0:
		CardInspector.show_card(SupabaseService.card_cache.keys()[0])
		record("inspect_database_card_by_id", {"opened": CardInspector.is_open})
		if CardInspector.is_open: CardInspector.hide_card()
	de.queue_free()
	await get_tree().process_frame
	var fc = load("res://scenes/FieldCreator.tscn").instantiate()
	add_child(fc)
	await get_tree().create_timer(0.5).timeout
	var sub = fc._spawn_sub_field()
	var card = fc.spawn_card_object({"name": "QA nested", "image_path": "res://card_images/Blade_Fairy_img.PNG"})
	card.reparent(sub)
	card.position = Vector2(40, 50)
	var counter = fc._on_add_counter_pressed()
	counter.set_counter_properties("QA counter", 1, 10, true, 14)
	var zone = fc._spawn_zone("Card Zone")
	zone.position = Vector2(150, 160)
	var fp = runner.result_dir.path_join("qa_field.json")
	fc._save_field_to_file(fp)
	_hide_dialogs(fc)
	fc._load_field_from_file(fp)
	await get_tree().process_frame
	var components = []
	fc._gather_components(fc.field_canvas, components)
	var nested = null
	var ctr = null
	for n in components:
		if n.get_meta("component_category") == "card": nested = n
		if n.get_meta("component_category") == "counter": ctr = n
	record("field_roundtrip", {"components": components.size(), "nested_card_parent_category": nested.get_parent().get_meta("component_category", "") if nested else "missing", "counter_default": ctr.default_value if ctr else -1})
	fc._toggle_test_mode()
	nested.position = Vector2(180, 190)
	fc._toggle_test_mode()
	record("nested_test_mode_restore", {"expected_x": 40, "expected_y": 50, "actual_x": nested.position.x, "actual_y": nested.position.y})
	ctr.set_value(10, false)
	ctr.is_pressing = true
	ctr.press_direction = 1
	ctr.is_dragging_really = false
	ctr.hold_time = 0
	ctr._process(0.6)
	var e = InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = false
	ctr._gui_input(e)
	record("counter_long_press", {"value_before": 10, "value_after_release": ctr.value, "dialog_open": ctr.amount_popup.visible})
	ctr.amount_popup.hide()
	fc._on_load_field_pressed()
	var chooser = fc.get_child(fc.get_child_count() - 1)
	fc.field_file_dialog.use_native_dialog = false
	chooser.custom_action.emit("local")
	record("field_load_button", {"local_file_dialog_visible": fc.field_file_dialog.visible, "open_mode": fc.field_file_dialog.file_mode == FileDialog.FILE_MODE_OPEN_FILE})
	fc.field_file_dialog.hide()
	fc.queue_free()
	await get_tree().process_frame
	Global.play_mode = true
	var main = load("res://SCENE/Main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(0.5).timeout
	var bc = main.spawn_card_object({"name": "QA face down", "image_path": "res://card_images/Blade_Fairy_img.PNG"})
	bc.name = "QAFaceDown"
	bc.set_meta("component_id", "QAFaceDown")
	main._set_card_face_down(bc, true, false)
	var count = main._on_add_counter_pressed(false)
	count.name = "QACounter"
	count.set_meta("component_id", "QACounter")
	count.set_value(27)
	var d = main.spawn_deck_object({"deck_name": "QA", "groups": [{"name": "QA", "cards": {"res://cards/Blade_Fairy.json": 6}}]})
	d.name = "QASyncDeck"
	d.set_meta("component_id", "QASyncDeck")
	main._confirm_deck_programmatically(d, false)
	d.set_meta("draw_pile", ["res://cards/Blade_Fairy.json", "res://cards/Blade_Fairy.json"])
	var state = main._capture_current_field_state()
	var before_face = bc.has_node("CardBack") and bc.get_node("CardBack").visible
	main._load_field_from_dict(state, true)
	await get_tree().process_frame
	var after_card = main._find_component("QAFaceDown")
	var after_counter = main._find_component("QACounter")
	var after_deck = main._find_component("QASyncDeck")
	record("game_state_roundtrip", {"face_down_before": before_face, "face_down_after": after_card.has_node("CardBack") and after_card.get_node("CardBack").visible, "counter_before": 27, "counter_after": after_counter.value, "deck_cards_before": 2, "deck_cards_after": after_deck.get_meta("draw_pile", []).size(), "deck_confirmed_after": after_deck.get_meta("deck_confirmed", false)})
	main._on_remote_card_spawned("QARaw", "", "FieldCanvas", Vector2.ZERO, 0.0, {"name": "Raw card", "atk": 123})
	record("raw_card_payload", main._find_component("QARaw").get_meta("card_data"))
	main.queue_free()
	await get_tree().process_frame
	Global.current_card_data = {}
	var ce = load("res://scenes/CardEditor.tscn").instantiate()
	add_child(ce)
	ce.card_name.text = "QA saved card"
	ce._on_file_selected("res://card_images/Blade_Fairy_img.PNG")
	ce._add_custom_stat("power", 250)
	var cp = result_dir.path_join("qa_saved_card.json")
	ce._save_card_to_file(cp)
	Global.current_card_data = JSON.parse_string(FileAccess.get_file_as_string(cp))
	ce.queue_free()
	await get_tree().process_frame
	ce = load("res://scenes/CardEditor.tscn").instantiate()
	add_child(ce)
	record("card_roundtrip", {"image": ce.preview_image.texture != null, "path": ce.current_image_path, "power": ce.custom_stats_container.get_child(0).get_child(1).value})
	ce.queue_free()
	await get_tree().process_frame
	var checks = {
		"legacy_deck": evidence.bundled_deck_load.group_count == 2,
		"new_deck": evidence.deck_new_format_roundtrip.copies == 3,
		"inspect_uuid": evidence.inspect_database_card_by_id.opened,
		"field_parent": evidence.field_roundtrip.nested_card_parent_category == "field",
		"nested_restore": evidence.nested_test_mode_restore.actual_x == 40 and evidence.nested_test_mode_restore.actual_y == 50,
		"counter_hold": evidence.counter_long_press.value_after_release == 10,
		"load_local": evidence.field_load_button.local_file_dialog_visible and evidence.field_load_button.open_mode,
		"face_down": evidence.game_state_roundtrip.face_down_after,
		"counter_snapshot": evidence.game_state_roundtrip.counter_after == 27,
		"deck_snapshot": evidence.game_state_roundtrip.deck_cards_after == 2 and evidence.game_state_roundtrip.deck_confirmed_after,
		"raw_card": evidence.raw_card_payload.get("atk") == 123,
		"card_image": evidence.card_roundtrip.image and evidence.card_roundtrip.path != "",
		"custom_stat": evidence.card_roundtrip.power == 250,
	}
	record("checks", checks)
	var failures = checks.values().count(false)
	record("suite_complete", true)
	print("REGRESSION_RESULT ", checks.size() - failures, "/", checks.size())
	get_tree().quit(1 if failures else 0)

func _hide_dialogs(node):
	for child in node.get_children():
		if child is Window: child.hide()
		_hide_dialogs(child)

func write_json(filename, data):
	var f = FileAccess.open(result_dir.path_join(filename), FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "\t"))

