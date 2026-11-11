extends Node
var checks = 0
var failures = 0
func check(label, ok):
	checks += 1
	if not ok:
		failures += 1
		push_error("CREATOR_INTEGRITY: " + label)
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
	var s = editor.editor_selection
	var board = editor._spawn_sub_field(false)
	var board_id = str(board.get_meta("component_id"))
	check("new field gets a stable id", board_id.begins_with("Field_") and editor._find_component(board_id) == board)
	board.position = Vector2(200, 100)
	board.rotation = 0.15
	var zone = editor._spawn_zone("Card Zone", false)
	zone.reparent(board, false)
	zone.position = Vector2(40, 45)
	zone.set_meta("component_id", "AuditZone")
	s.history.record()
	zone.position.x += 50
	s.history.record()
	s.undo()
	zone = editor._find_component("AuditZone")
	zone._on_mouse_entered()
	s.history.record()
	check("hover preserves redo", s.history.cursor < s.history.states.size()-1)
	s.undo(true)
	zone = editor._find_component("AuditZone")
	check("redo still restores edit", is_equal_approx(zone.position.x, 90))
	board = editor._find_component(board_id)
	s.select_rect(Rect2(-10000, -10000, 20000, 20000), false)
	s.copy_selected()
	s.paste_selected()
	check("marquee paste has one field root", s.selected.size() == 1 and s.selected[0].get_meta("component_category") == "field")
	var copied = s.selected[0]
	var children = []
	editor._gather_components(copied, children)
	var copied_zone = children[0]
	check("copied zone stays nested", copied_zone.get_parent() == copied and copied_zone.position.is_equal_approx(zone.position))
	check("copy has unique identity", copied.get_meta("component_id") != board.get_meta("component_id"))
	check("copied field rotation", is_equal_approx(copied.rotation, board.rotation))
	var id = str(copied.get_meta("component_id"))
	var zone_id = str(copied_zone.get_meta("component_id"))
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://cards/Blade_Fairy.json"))
	var card = editor.spawn_card_object(data)
	editor.is_test_mode = true
	var point = copied_zone.get_global_transform() * (copied_zone.size / 2)
	card.global_position = point - card.size / 2
	editor._on_card_drag_ended(card, point)
	check("drop reaches nested copied zone", card.get_parent() == copied_zone)
	point = copied.get_global_transform() * Vector2(430, 280)
	card.global_position = point - card.size / 2
	editor._on_card_drag_ended(card, point)
	check("card stays above copied field", card.get_parent() == copied)
	editor.is_test_mode = false
	s.selected = [card]
	s.copy_selected()
	s.paste_selected()
	check("copy child alone keeps field parent", s.selected[0].get_parent() == copied)
	# Reload saved snapshots including geometry and hierarchy.
	copied.update_base_scale(Vector2(0.8, 0.8))
	var state = editor._capture_current_field_state()
	editor._load_field_from_dict(state, true)
	copied = editor._find_component(id)
	copied_zone = editor._find_component(zone_id)
	check("snapshot keeps field scale", copied.scale.is_equal_approx(Vector2(0.8,0.8)))
	check("snapshot keeps hierarchy", copied_zone.get_parent() == copied)
	# Idle frames must not capture new document snapshots.
	var cursor = s.history.cursor
	s.history_pending = false
	await get_tree().create_timer(0.65).timeout
	check("idle does not record history", s.history.cursor == cursor)
	var doc = editor.editor_document
	check("changed document is dirty", doc.is_dirty())
	var exit_called = [false]
	doc.request_exit(func(): exit_called[0] = true)
	check("unsaved exit is blocked", not exit_called[0] and doc.leave_dialog.visible)
	doc.leave_dialog.canceled.emit()
	doc.leave_dialog.hide()
	doc.request_exit(func(): exit_called[0] = true)
	editor.field_file_dialog.canceled.emit()
	check("cancel save cancels pending exit", not doc.pending_exit.is_valid())
	doc.leave_dialog.hide()
	# Persistence is exercised only in the isolated QA user directory.
	doc.persistence_enabled = true
	doc.save_draft()
	editor.field_canvas.set_meta("field_name", "Draft revision 2")
	doc.save_draft()
	var draft_file = FileAccess.open(doc.DRAFT, FileAccess.READ)
	check("recovery draft written", draft_file != null)
	var draft = draft_file.get_var(false) if draft_file else {}
	check("recovery draft keeps hierarchy", draft.get("components_layout", []).size() == doc.history.capture().components_layout.size())
	check("draft overwrite is atomic and current", draft.get("name", "") == "Draft revision 2")
	if draft_file: draft_file.close()
	editor.field_canvas.set_meta("field_name", "Temporary")
	doc._offer_recovery()
	var recovery_dialog = editor.get_child(editor.get_child_count() - 1)
	recovery_dialog.confirmed.emit()
	recovery_dialog.hide()
	check("recovery restores document", editor.field_canvas.get_meta("field_name") == "Draft revision 2")
	doc.mark_saved()
	check("saved document clears recovery draft", not FileAccess.file_exists(doc.DRAFT))
	doc.persistence_enabled = false
	check("save clears dirty state", not doc.is_dirty())
	doc.request_exit(func(): exit_called[0] = true)
	check("clean document can exit", exit_called[0])
	var counter = editor._on_add_counter_pressed(false)
	counter.set_meta("component_id", "TestCounter")
	counter.set_value(7, false)
	editor._toggle_test_mode()
	counter.set_value(90, false)
	editor._toggle_test_mode()
	check("test mode changes do not leak into document", editor._find_component("TestCounter").value == 7)
	var legacy = editor._spawn_sub_field(false)
	legacy.set_meta("component_id", "@ColorRect@legacy")
	check("legacy generated name resolves to subfield", editor._find_component("@ColorRect@legacy") == legacy)
	# Replay same saved scene in actual gameplay.
	editor.queue_free()
	await get_tree().process_frame
	Global.play_mode = true
	var table = load("res://SCENE/Main.tscn").instantiate()
	add_child(table)
	await get_tree().process_frame
	table._load_field_from_dict(state, true)
	copied_zone = table._find_component(zone_id)
	card = table.spawn_card_object(data)
	point = copied_zone.get_global_transform() * (copied_zone.size / 2)
	card.global_position = point - card.size / 2
	table._on_card_drag_ended(card, point)
	check("gameplay drop reaches nested copied zone", card.get_parent() == copied_zone)
	var practice = preload("res://scripts/TutorialPractice.gd").new()
	practice.size = Vector2(360, 290)
	add_child(practice)
	practice.reset_layout()
	check("narrow tutorial fits horizontally", practice.dice_button.get_rect().end.x <= practice.size.x and practice.target.get_rect().end.x <= practice.size.x)
	check("narrow tutorial fits vertically", practice.dice_button.get_rect().end.y <= practice.custom_minimum_size.y)
	practice.queue_free()
	table.queue_free()
	for audio in Global.get_children():
		if audio is AudioStreamPlayer:
			audio.stop()
			audio.stream = null
			audio.queue_free()
	await get_tree().create_timer(0.3).timeout
	print("CREATOR_INTEGRITY_RESULT ", checks-failures, "/", checks)
	get_tree().quit(1 if failures else 0)
