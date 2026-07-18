extends PanelContainer

var card_index: int = -1
var deck_viewer_ref: Node = null

var _pressed: bool = false
var _press_pos: Vector2 = Vector2.ZERO
var _drag_started: bool = false
const DRAG_THRESHOLD: float = 8.0

func _gui_input(event: InputEvent):
	if deck_viewer_ref == null: return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressed = true
			_press_pos = event.global_position
			_drag_started = false
			accept_event()
		else:
			if _drag_started:
				# ปล่อยเมาส์ → จบการลาก
				deck_viewer_ref._on_dv_card_drag_ended(card_index)
			elif _pressed:
				# คลิกปกติ → highlight
				deck_viewer_ref._on_dv_card_clicked(card_index)
			_pressed = false
			_drag_started = false
			accept_event()
	
	if event is InputEventMouseMotion and _pressed and not _drag_started:
		if event.global_position.distance_to(_press_pos) > DRAG_THRESHOLD:
			_drag_started = true
			deck_viewer_ref._on_dv_card_drag_started(card_index)
			_pressed = false
			_drag_started = false
			accept_event()
