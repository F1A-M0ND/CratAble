extends Node

var checks = 0
var failures = 0

func check(label: String, passed: bool):
	checks += 1
	if not passed:
		failures += 1
		push_error("DECK_SELECTION: " + label)

func _ready(): call_deferred("run")

func run():
	Global.reset_online_session()
	Global.play_mode = true
	Global.loaded_field_data = {}
	Global.loaded_field_path = ""
	for scene in ["res://SCENE/Main.tscn", "res://scenes/FieldCreator.tscn"]:
		var table = load(scene).instantiate()
		add_child(table)
		await get_tree().process_frame
		table.is_test_mode = true
		var zone = table._spawn_zone("Deck Zone", false)
		zone.set_meta("component_id", "SelectionFixture")
		zone.set_meta("zone_settings", {"purpose": 1, "allow_move": true})
		table.current_target_zone = zone
		table._create_online_selector_button({"name": "Selected fixture", "cards_data": {"groups": [{"cards": {"res://cards/Blade_Fairy.json": 2}}]}}, "deck")
		table.asset_grid.get_child(table.asset_grid.get_child_count() - 1).pressed.emit()
		check("selector hidden", not zone.visible)
		check("dialog closed", not table.asset_selector.visible)
		var deck: Control
		for child in table.field_canvas.get_children():
			if child.get_meta("component_category", "") == "deck": deck = child
		check("ready immediately", is_instance_valid(deck) and deck.get_meta("deck_confirmed", false) and deck.get_meta("draw_pile", []).size() == 2)
		check("no select overlay", not deck.has_node("DeckHoverOverlay"))
		table._on_deck_left_clicked(deck, false)
		check("can draw", deck.get_meta("draw_pile").size() == 1)
		var dice = table._on_add_dice_pressed(false)
		check("black numbers", dice.get_node("DiceLabel").get_theme_color("font_color") == Color.BLACK)
		if scene == "res://SCENE/Main.tscn":
			var state = table._capture_current_field_state()
			table._load_field_from_dict(state, true)
			check("snapshot keeps selector hidden", not table._find_component("SelectionFixture").visible)
			var embedded = {"id":0, "component_id":"EmbeddedDeck", "category":"deck",
				"deck_data":{"groups":[{"cards":{"res://cards/Blade_Fairy.json":2}}]}}
			table._load_field_from_dict({"canvas":{}, "components":[embedded]})
			var saved_deck = table._find_component("EmbeddedDeck")
			check("saved field deck is playable", saved_deck.get_meta("deck_confirmed", false))
			table._on_deck_left_clicked(saved_deck, false)
			check("saved field deck draws exactly once", saved_deck.get_meta("draw_pile").size() == 1)
			await check_guest_picker_during_sync(table)
		await get_tree().create_timer(0.4).timeout
		table.queue_free()
		await get_tree().process_frame
	for child in Global.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
			child.queue_free()
	await get_tree().create_timer(0.3).timeout
	print("DECK_SELECTION_RESULT ", checks - failures, "/", checks)
	get_tree().quit(1 if failures else 0)

func check_guest_picker_during_sync(table):
	Global.online_player_role = "Guest"
	var state = {"canvas_settings":{"size_x":1500,"size_y":1000}, "components_layout":[
		{"id":9,"category":"zone","zone_type":"Deck Zone","rotation_degrees":-180,
		"position_x":700,"position_y":400,"zone_settings":{"purpose":0,"allow_move":false}},
		{"id":10,"component_id":"OtherDeck","category":"deck","position_x":350,"position_y":350,
		"deck_data":{"groups":[{"cards":{"res://cards/Blade_Fairy.json":2}}]}}]}
	table._load_field_from_dict(state)
	await get_tree().process_frame
	var zone = table._find_component("Component_9")
	var point: Vector2 = zone.get_global_transform_with_canvas() * (zone.size / 2)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.global_position = point
	event.pressed = true
	get_viewport().push_input(event, true)
	# Every incoming full snapshot replaces the Control which owns the mouse press.
	table._on_remote_sync_field_state(state)
	await get_tree().process_frame
	event.pressed = false
	get_viewport().push_input(event, true)
	check("guest deck picker stays open across a snapshot during a click",
		table.asset_selector.visible and table.current_target_zone == table._find_component("Component_9"))
	table.asset_selector.hide()
	table._on_deck_right_clicked(table._find_component("OtherDeck"))
	table._on_remote_sync_field_state(state)
	await get_tree().process_frame
	table.tabletop_popup_menu.hide()
	table.tabletop_popup_menu.id_pressed.emit(23)
	check("guest opens the current deck after the menu target is replaced",
		table.deck_viewer_dialog.visible and table.deck_viewer_target == table._find_component("OtherDeck")
		and table.deck_viewer_cards.size() == 2)
	for button in table.deck_viewer_dialog.find_children("*", "Button", true, false):
		if button.text == "Cancel":
			button.pressed.emit()
			break
	await get_tree().process_frame
	event.pressed = true
	get_viewport().push_input(event, true)
	event.pressed = false
	get_viewport().push_input(event, true)
	check("cancel returns to the table and allows another deck selection",
		not table.deck_viewer_dialog.visible and table.asset_selector.visible)
	table.asset_selector.hide()
	Global.online_player_role = "Host"
