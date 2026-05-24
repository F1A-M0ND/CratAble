extends Control

var dragging = false
var drag_offset = Vector2()
var locked: bool = false

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

func _on_mouse_entered():
	if locked or dragging: return
	is_hovering = true
	original_z_index = z_index
	z_index = 100
	base_scale = scale
	if hover_tween: hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", base_scale * 1.05, 0.1)

func _on_mouse_exited():
	if locked or dragging: return
	is_hovering = false
	z_index = original_z_index
	if hover_tween: hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", base_scale, 0.1)

func _gui_input(event):
	if locked: return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_offset = global_position - get_global_mouse_position()
				move_to_front()
				if is_hovering:
					if hover_tween: hover_tween.kill()
					scale = base_scale
					z_index = original_z_index
				drag_started.emit()
			else:
				if dragging:
					dragging = false
					drag_ended.emit()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if not event.pressed:
				right_clicked.emit()
	
	if event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position() + drag_offset
		drag_moved.emit()
