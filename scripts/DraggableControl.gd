extends Control
class_name DraggableControl

var dragging = false
var drag_offset = Vector2()
var locked: bool = false

# base_scale เก็บครั้งเดียวตอน _ready ไม่เปลี่ยนระหว่าง hover
var base_scale: Vector2 = Vector2.ONE
var is_hovering = false
var original_z_index = 0
var hover_tween: Tween

signal right_clicked
signal left_clicked
signal drag_started
signal drag_ended
signal drag_moved

var _click_start_pos = Vector2.ZERO

static var _hovered_instance: DraggableControl = null  # track ทั่วกลางว่าใครกำลัง hover

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	original_z_index = z_index
	base_scale = scale  # บันทึกครั้งเดียว ไม่อัปเดตใหม่อีก

func update_base_scale(new_scale: Vector2):
	base_scale = new_scale
	scale = new_scale

func force_exit_hover():
	if not is_hovering: return
	is_hovering = false
	if DraggableControl._hovered_instance == self:
		DraggableControl._hovered_instance = null
	z_index = original_z_index
	pivot_offset = size / 2.0
	if hover_tween: hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", base_scale, 0.1)

func _on_mouse_entered():
	if locked: return
	if is_hovering: return
	# บังคับให้ instance ก่อนหน้า exit ก่อน → มีแค่ใบเดียวที่ hover ได้ในเวลาเดียวกัน
	if DraggableControl._hovered_instance and DraggableControl._hovered_instance != self:
		DraggableControl._hovered_instance.force_exit_hover()
	DraggableControl._hovered_instance = self
	is_hovering = true
	original_z_index = z_index
	z_index = 200 if has_meta("in_hand") and get_meta("in_hand") else 100
	pivot_offset = size / 2.0
	if hover_tween: hover_tween.kill()
	hover_tween = create_tween()
	var factor = 1.3 if has_meta("in_hand") and get_meta("in_hand") else 1.05
	hover_tween.tween_property(self, "scale", base_scale * factor, 0.1)

func _on_mouse_exited():
	if not is_hovering: return
	# ตรวจว่าเมาส์ยังอยู่ใน bounds ของ control นี้หรือเปล่า
	# (กรณีชี้ไป child node เช่น label, overlay ข้างใน deck)
	# adjacent card จะถูก force_exit_hover() จัดการจาก _on_mouse_entered ของ card ถัดไปแทน
	var local_mouse = get_local_mouse_position()
	if Rect2(Vector2.ZERO, size).has_point(local_mouse):
		return
	is_hovering = false
	if DraggableControl._hovered_instance == self:
		DraggableControl._hovered_instance = null
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
				_click_start_pos = global_position
				pivot_offset = size / 2.0
				z_index = 1000
				move_to_front()
				drag_started.emit()
				drag_offset = global_position - get_global_mouse_position()
			else:
				if dragging:
					dragging = false
					z_index = original_z_index
					var end_pos = global_position
					drag_ended.emit()
					if end_pos.distance_to(_click_start_pos) < 5.0:
						left_clicked.emit()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if not event.pressed:
				right_clicked.emit()

	if event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position() + drag_offset
		drag_moved.emit()
