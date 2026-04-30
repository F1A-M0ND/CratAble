extends Control

var dragging = false
var drag_offset = Vector2()

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_offset = global_position - get_global_mouse_position()
				move_to_front()
			else:
				dragging = false
	
	if event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position() + drag_offset
