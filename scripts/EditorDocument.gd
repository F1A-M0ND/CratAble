extends Node

const DRAFT = "user://field_creator_recovery.dat"
var editor: Control
var history: RefCounted
var saved_state: Dictionary = {}
var status: Label
var leave_dialog: ConfirmationDialog
var pending_exit: Callable
var draft_timer: Timer
var persistence_enabled = true
var previous_auto_quit = true

func _ready():
	persistence_enabled = ProjectSettings.get_setting("cratable/recovery_enabled", true)
	saved_state = history.capture()
	previous_auto_quit = get_tree().auto_accept_quit
	get_tree().auto_accept_quit = false
	status = Label.new()
	status.name = "DocumentStatus"
	status.add_theme_font_size_override("font_size", 18)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var toolbox = editor.get_node("HBoxContainer/LeftSide")
	toolbox.add_child(status)
	toolbox.move_child(status, 1)
	history.changed.connect(_changed)
	editor.field_file_dialog.canceled.connect(cancel_exit)
	editor.save_field_dialog.canceled.connect(cancel_exit)
	draft_timer = Timer.new()
	draft_timer.one_shot = true
	draft_timer.wait_time = 2.0
	draft_timer.timeout.connect(save_draft)
	add_child(draft_timer)
	_changed()
	if persistence_enabled and FileAccess.file_exists(DRAFT): call_deferred("_offer_recovery")

func is_dirty() -> bool:
	return history.capture() != saved_state

func mark_saved(state: Dictionary = {}):
	saved_state = history.capture() if state.is_empty() else state.duplicate(true)
	_changed()
	if not is_dirty(): _remove_draft()
	if pending_exit.is_valid() and not is_dirty():
		var action = pending_exit
		pending_exit = Callable()
		action.call()

func _changed():
	var dirty = is_dirty()
	status.text = "● ยังไม่บันทึก" if dirty else "✓ ไม่มีการแก้ไขค้าง"
	status.add_theme_color_override("font_color", Color("73ceff") if dirty else Color("a4bfaf"))
	if dirty and persistence_enabled: draft_timer.start()

func save_draft():
	if not persistence_enabled or editor.is_test_mode or Global.play_mode or not is_dirty(): return
	var file = FileAccess.open(DRAFT + ".tmp", FileAccess.WRITE)
	if not file: return
	file.store_var(history.capture())
	file.close()
	if DirAccess.rename_absolute(DRAFT + ".tmp", DRAFT) == OK:
		status.text = "● สำรองในเครื่องแล้ว · ยังไม่บันทึกไฟล์"

func _remove_draft():
	if persistence_enabled and FileAccess.file_exists(DRAFT): DirAccess.remove_absolute(DRAFT)

func request_exit(action: Callable):
	# Returning from Test Mode restores the document before checking unsaved work.
	if editor.is_test_mode: editor._toggle_test_mode()
	history.record()
	if not is_dirty():
		action.call()
		return
	pending_exit = action
	if not is_instance_valid(leave_dialog):
		leave_dialog = ConfirmationDialog.new()
		leave_dialog.title = "งานยังไม่ได้บันทึก"
		leave_dialog.dialog_text = "บันทึกสนามก่อนออกหรือไม่?"
		leave_dialog.ok_button_text = "บันทึกก่อนออก"
		leave_dialog.cancel_button_text = "แก้ไขต่อ"
		leave_dialog.add_button("ออกโดยไม่บันทึก", false, "discard")
		leave_dialog.confirmed.connect(func(): editor._on_save_field_pressed())
		leave_dialog.canceled.connect(func(): pending_exit = Callable())
		leave_dialog.custom_action.connect(func(action_name):
			if action_name == "discard":
				_remove_draft()
				var exit_action = pending_exit
				pending_exit = Callable()
				exit_action.call()
		)
		editor.add_child(leave_dialog)
	leave_dialog.popup_centered()

func _offer_recovery():
	var file = FileAccess.open(DRAFT, FileAccess.READ)
	if not file: return
	var state = file.get_var(false)
	if not state is Dictionary or not state.has("components_layout"): return
	var dialog = ConfirmationDialog.new()
	dialog.title = "พบสนามที่สำรองไว้"
	dialog.dialog_text = "กู้คืนงานที่ยังไม่ได้บันทึกจากครั้งก่อนหรือไม่?"
	dialog.ok_button_text = "กู้คืนงาน"
	dialog.cancel_button_text = "ไว้ภายหลัง"
	dialog.confirmed.connect(func():
		history.restore(state)
		history.reset()
		history.record()
	)
	editor.add_child(dialog)
	dialog.popup_centered()

func _exit_tree():
	get_tree().auto_accept_quit = previous_auto_quit

func cancel_exit():
	pending_exit = Callable()
