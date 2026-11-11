extends Node
var failures = 0
var checks = 0
func check(label, value):
	checks += 1
	if not value:
		failures += 1
		push_error(label)
func _ready(): call_deferred("run")
func run():
	Global.reset_online_session()
	Global.play_mode = false
	Global.loaded_field_data = {}
	Global.loaded_field_path = ""
	var table = load("res://scenes/FieldCreator.tscn").instantiate()
	add_child(table)
	await get_tree().process_frame
	await get_tree().process_frame
	var s = table.editor_selection
	var a = table._spawn_zone("Card Zone", false)
	a.set_meta("component_id", "QA_original")
	a.position = Vector2(100, 100)
	s.select_rect(Rect2(-10000, -10000, 20000, 20000), false)
	check("marquee", a in s.selected)
	s.selected = [a]
	s.copy_selected()
	check("clipboard", s.clipboard.size() == 1)
	s.paste_selected()
	check("paste", s.selected.size() == 1)
	var copy = s.selected[0]
	check("identity", copy != a and copy.get_meta("component_id") != a.get_meta("component_id"))
	check("original", a.position == Vector2(100, 100) and a.get_parent() == table.field_canvas)
	check("offset", copy.position.is_equal_approx(a.position + Vector2(24, 24)))
	s.delete_selected()
	check("delete", copy.is_queued_for_deletion() and not a.is_queued_for_deletion())
	var child = table._spawn_zone("Card Zone", false)
	child.set_meta("component_id", "QA_child")
	child.reparent(a)
	child.position = Vector2(15, 20)
	a.rotation = 0.3
	s.selected = [a, child]
	check("nested roots", s.roots() == [a])
	s.copy_selected()
	s.paste_selected()
	check("nested copy root", s.selected.size() == 1)
	var copied_parent = s.selected[0]
	var copied_children = []
	table._gather_components(copied_parent, copied_children)
	check("nested child copied", copied_children.size() == 1)
	check("nested local position", copied_children[0].position.is_equal_approx(child.position))
	check("rotation preserved", is_equal_approx(copied_parent.rotation, a.rotation))
	var before = copied_parent.position
	s.moving = true
	var motion = InputEventMouseMotion.new()
	motion.relative = Vector2(20, 10)
	check("drag handled", s.handle_event(motion))
	check("group moves", not copied_parent.position.is_equal_approx(before))
	check("child moves once", copied_children[0].position.is_equal_approx(child.position))
	s.moving = false
	s.delete_selected()
	s.selected = [a]
	table.is_test_mode = true
	s.delete_selected()
	check("test guard", not a.is_queued_for_deletion())
	table.is_test_mode = false
	Global.play_mode = true
	check("play guard", not s.enabled())
	Global.play_mode = false
	var edit = LineEdit.new()
	table.add_child(edit)
	edit.grab_focus()
	s.delete_selected()
	check("typing guard", not a.is_queued_for_deletion())
	edit.release_focus()
	s.canvas_active = true
	var key = InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_DELETE
	check("key handled", s.handle_event(key))
	check("key deleted", a.is_queued_for_deletion())
	table.queue_free()
	await get_tree().process_frame
	for audio_player in Global.get_children():
		if audio_player is AudioStreamPlayer:
			audio_player.stop()
			audio_player.stream = null
			audio_player.queue_free()
	await get_tree().create_timer(0.3).timeout
	print("EDITOR_SELECTION_RESULT ", checks-failures, "/", checks)
	get_tree().quit(1 if failures else 0)

