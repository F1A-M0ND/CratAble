extends Node
var checks = 0
var failures = 0
func check(label, ok):
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _ready(): call_deferred("run")
func run():
	Global.reset_online_session()
	Global.play_mode = false
	Global.loaded_field_data = {}
	Global.loaded_field_path = ""
	var editor = load("res://scenes/FieldCreator.tscn").instantiate()
	add_child(editor)
	await get_tree().process_frame
	await get_tree().process_frame
	var selection = editor.editor_selection
	var zone = editor._spawn_zone("Card Zone", false)
	zone.set_meta("component_id", "UndoFixture")
	zone.position = Vector2(100, 100)
	selection.history.record()
	selection.selected = [zone]
	selection.delete_selected()
	selection.undo()
	zone = editor._find_component("UndoFixture")
	check("undo delete restores", is_instance_valid(zone) and zone.position == Vector2(100, 100))
	selection.undo(true)
	check("redo delete", not is_instance_valid(editor._find_component("UndoFixture")))
	selection.undo()
	zone = editor._find_component("UndoFixture")
	selection.selected = [zone]
	selection.copy_selected()
	selection.paste_selected()
	var copy_id = str(selection.selected[0].get_meta("component_id"))
	selection.undo()
	check("undo paste", not is_instance_valid(editor._find_component(copy_id)))
	selection.undo(true)
	check("redo paste", is_instance_valid(editor._find_component(copy_id)))
	selection.undo()
	zone = editor._find_component("UndoFixture")
	zone.position.x = 210
	selection.history.record()
	check("new edit discards redo", not selection.history.travel(1))
	selection.undo()
	zone = editor._find_component("UndoFixture")
	check("undo movement", zone.position == Vector2(100, 100))
	var align = editor._spawn_zone("Card Zone", false)
	align.position = zone.position + Vector2(zone.size.x + 4, 150)
	selection.selected = [zone]
	selection._update_guides(false, false)
	check("snap guide visible", not selection.guides.is_empty())
	selection._update_guides(true, false)
	check("Alt disables guide", selection.guides.is_empty())
	selection.start = Vector2.ZERO
	selection.drag_origins = {zone: zone.global_position}
	var origin = zone.global_position
	selection.moving = true
	var movement = InputEventMouseMotion.new()
	movement.position = Vector2(60, 10)
	movement.shift_pressed = true
	selection.handle_event(movement)
	check("Shift locks drag axis", is_equal_approx(zone.global_position.y, origin.y) and is_equal_approx(zone.global_position.x, origin.x + 60))
	selection.moving = false
	selection.history.record()
	var history_cursor = selection.history.cursor
	editor.is_test_mode = true
	selection.undo()
	check("Undo disabled in test mode", selection.history.cursor == history_cursor)
	editor.is_test_mode = false
	for i in range(50): editor._spawn_zone("Card Zone", false)
	var started = Time.get_ticks_usec()
	selection.history.record()
	print("HISTORY_CAPTURE_52_OBJECTS_MS ", (Time.get_ticks_usec() - started) / 1000.0)
	var dice = editor._on_add_dice_pressed(false)
	var before = dice.position
	dice.left_clicked.emit()
	dice.left_clicked.emit()
	await get_tree().create_timer(0.3).timeout
	check("dice animation keeps position", dice.position == before)
	check("dice resets visual", dice.get_node("DiceLabel").scale.is_equal_approx(Vector2.ONE))
	var p = preload("res://scripts/InteractionMotion.gd")
	p.remote_pose(dice, Vector2(10, 10), 90, false)
	p.remote_pose(dice, Vector2(50, 50), 180, false)
	p.remote_pose(dice, Vector2(100, 100), 270, true)
	await get_tree().create_timer(0.1).timeout
	check("final network pose cancels interpolation", dice.position == Vector2(100, 100) and is_equal_approx(dice.rotation_degrees, 270))
	editor.queue_free()
	await get_tree().process_frame
	Global.main_menu_tab = "HELP"
	var menu = load("res://scenes/MainMenu.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	await get_tree().process_frame
	var help = menu.current_page
	check("help topics", help.topic_buttons.size() == 6)
	help.show_lesson(1)
	check("creator shortcuts documented", "Ctrl+Z" in help.lesson_body.text)
	var practice = help.practice
	practice.card.position = practice.target.position
	practice.drop()
	practice.flip()
	practice.roll()
	check("interactive practice completed", practice.completed.count(true) == 3)
	practice.reset_practice()
	check("practice reset", practice.completed.count(true) == 0)
	help.show_lesson(0)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("output="):
			await get_tree().create_timer(0.5).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(arg.trim_prefix("output="))
	menu.queue_free()
	for audio in Global.get_children():
		if audio is AudioStreamPlayer:
			audio.stop()
			audio.stream = null
			audio.queue_free()
	await get_tree().create_timer(0.3).timeout
	print("INTERACTION_POLISH_RESULT ", checks-failures, "/", checks)
	get_tree().quit(1 if failures else 0)
