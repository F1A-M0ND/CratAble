extends Node
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
	s.set_process(false)
	var zone = table._spawn_zone("Card Zone", false)
	zone.set_meta("component_id", "AuditHover")
	s.history.record()
	zone.position.x += 100
	s.history.record()
	s.undo()
	zone = table._find_component("AuditHover")
	print("AUDIT_BEFORE_HOVER cursor=", s.history.cursor, " states=", s.history.states.size(), " pivot=", zone.pivot_offset)
	zone._on_mouse_entered()
	s.history.record()
	print("AUDIT_AFTER_HOVER cursor=", s.history.cursor, " states=", s.history.states.size(), " redo_available=", s.history.cursor < s.history.states.size()-1)
	var practice = preload("res://scripts/TutorialPractice.gd").new()
	practice.size = Vector2(360,240)
	add_child(practice)
	practice.reset_layout()
	print("AUDIT_PRACTICE width=", practice.size.x, " dice_right=", practice.dice_button.position.x + practice.dice_button.size.x)
	for count in [50, 200, 500]:
		var all = []
		table._gather_components(table.field_canvas, all)
		for i in range(count-all.size()): table._spawn_zone("Card Zone", false)
		var start = Time.get_ticks_usec()
		s.history.record()
		print("AUDIT_HISTORY ", count, " objects ms=", (Time.get_ticks_usec()-start)/1000.0)
	table.queue_free()
	practice.queue_free()
	await get_tree().process_frame
	get_tree().quit()
