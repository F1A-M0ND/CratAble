extends Sprite2D

var dragging = false

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and get_rect().has_point(to_local(event.position)):
				dragging = true
			else:
				dragging = false
	
	if event is InputEventMouseMotion and dragging:
		position += event.relative
