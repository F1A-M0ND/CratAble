extends Control

var dragging = false
var drag_offset = Vector2()
var locked: bool = false

# base_scale เก็บครั้งเดียวตอน _ready ไม่เปลี่ยนระหว่าง hover
var base_scale: Vector2 = Vector2.ONE
var is_hovering = false
var original_z_index = 0
var hover_tween: Tween

signal right_clicked
signal drag_started
signal drag_ended
signal drag_moved

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	original_z_index = z_index
	base_scale = scale  # บันทึกครั้งเดียว ไม่อัปเดตใหม่อีก

func _on_mouse_entered():
	if locked or dragging: return
	if is_hovering: return  # กัน re-entry จากปุ่มลูก
	is_hovering = true
	original_z_index = z_index
	z_index = 100
	pivot_offset = size / 2.0
	if hover_tween: hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", base_scale * 1.05, 0.1)

func _on_mouse_exited():
	if locked or dragging: return
	# mouse_exited ยิงทั้งตอนออกนอก control จริงๆ และตอนเมาส์เข้าปุ่มลูก
	# ตรวจว่าเมาส์ยังอยู่ใน bounds ของ control นี้อยู่หรือเปล่า
	var local_mouse = get_local_mouse_position()
	if Rect2(Vector2.ZERO, size).has_point(local_mouse):
		return  # ยังอยู่ใน bounds (เช่น เข้าปุ่มลูก) → ไม่ revert
	if not is_hovering: return
	is_hovering = false
	z_index = original_z_index
	pivot_offset = size / 2.0
	if hover_tween: hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", base_scale, 0.1)

func _gui_input(event):
	if locked: return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				pivot_offset = size / 2.0
				drag_offset = global_position - get_global_mouse_position()
				z_index = 1000
				move_to_front()
				if is_hovering:
					if hover_tween: hover_tween.kill()
					scale = base_scale
					is_hovering = false
				drag_started.emit()
			else:
				if dragging:
					dragging = false
					z_index = original_z_index
					drag_ended.emit()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if not event.pressed:
				right_clicked.emit()

	if event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position() + drag_offset
		drag_moved.emit()
