extends Control

var dragging = false
var is_dragging_really = false
var start_click_pos = Vector2()
var drag_offset = Vector2()
var drag_threshold = 5.0

var value: int = 0
var is_pressing = false
var hold_time = 0.0
var press_timer = 0.0
var press_direction = 0

var is_vertical = false

var counter_name: String = ""
var name_position: int = 0 # 0: Hidden, 1: Top, 2: Bottom, 3: Left, 4: Right, 5: Center
var default_value: int = 0
var name_auto_scale: bool = true
var name_custom_size: int = 14

var is_right_pressing = false
var right_hold_time = 0.0

var amount_popup: ConfirmationDialog
var amount_spin: SpinBox

@onready var val_label = $MarginContainer/Label
@onready var name_label = Label.new()

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_on_resized)
	
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	name_label.add_theme_font_size_override("font_size", 14)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.5)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	name_label.add_theme_stylebox_override("normal", style)
	add_child(name_label)
	
	_on_resized()
	update_label()
	
	amount_popup = ConfirmationDialog.new()
	amount_popup.title = "Set Counter Value"
	
	var popup_vbox = VBoxContainer.new()
	var popup_lbl = Label.new()
	popup_lbl.text = "Enter new value:"
	
	amount_spin = SpinBox.new()
	amount_spin.min_value = -9999
	amount_spin.max_value = 9999
	amount_spin.value = value
	amount_spin.rounded = true
	
	popup_vbox.add_child(popup_lbl)
	popup_vbox.add_child(amount_spin)
	
	amount_popup.add_child(popup_vbox)
	amount_popup.get_ok_button().text = "Set"
	amount_popup.add_button("Add", true, "add_val")
	amount_popup.confirmed.connect(_on_amount_confirmed)
	amount_popup.custom_action.connect(func(action):
		if action == "add_val":
			value += int(amount_spin.value)
			update_label()
			amount_popup.hide()
	)
	add_child(amount_popup)

func _on_amount_confirmed():
	value = int(amount_spin.value)
	update_label()

func _process(delta):
	if is_pressing and not is_dragging_really:
		hold_time += delta
		if hold_time >= 0.5:
			is_pressing = false
			dragging = false
			amount_spin.value = value
			amount_popup.popup_centered()
			
	if is_right_pressing:
		right_hold_time += delta
		if right_hold_time >= 0.5:
			is_right_pressing = false
			value = default_value
			update_label()

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				is_pressing = true
				hold_time = 0.0
				press_timer = 0.0
				start_click_pos = event.position
				is_dragging_really = false
				drag_offset = global_position - get_global_mouse_position()
				move_to_front()
				
				var center = size / 2
				if is_vertical:
					if event.position.y < center.y:
						press_direction = 1 # up = +
					else:
						press_direction = -1 # down = -
				else:
					if event.position.x > center.x:
						press_direction = 1 # right = +
					else:
						press_direction = -1 # left = -
						
			else:
				dragging = false
				is_pressing = false
				if not is_dragging_really:
					value += press_direction
					update_label()
				is_dragging_really = false
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				is_right_pressing = true
				right_hold_time = 0.0
			else:
				is_right_pressing = false
	
	if event is InputEventMouseMotion and dragging:
		if not is_dragging_really and event.position.distance_to(start_click_pos) > drag_threshold:
			is_dragging_really = true
			is_pressing = false
			
		if is_dragging_really:
			global_position = get_global_mouse_position() + drag_offset

func update_label():
	if val_label:
		val_label.text = str(value)

func _on_resized():
	pivot_offset = size / 2.0
	var min_dim = min(size.x, size.y)
	if val_label:
		val_label.add_theme_font_size_override("font_size", int(min_dim * 0.6))
	if name_label:
		if name_auto_scale:
			name_label.add_theme_font_size_override("font_size", int(min_dim * 0.2))
		else:
			name_label.add_theme_font_size_override("font_size", name_custom_size)
	_update_name_label()

func set_counter_properties(c_name: String, c_pos: int, def_val: int, auto_scale: bool, custom_size: int):
	counter_name = c_name
	name_position = c_pos
	name_auto_scale = auto_scale
	name_custom_size = custom_size
	
	if default_value != def_val:
		default_value = def_val
		value = default_value
		update_label()
		
	_on_resized()

func _update_name_label():
	if not name_label: return
	name_label.text = counter_name
	
	if name_position == 0 or counter_name.strip_edges() == "":
		name_label.hide()
		return
		
	name_label.show()
	name_label.reset_size()
	var lbl_size = name_label.get_minimum_size()
	
	var offset = 5
	if name_position == 1: # Top
		name_label.position = Vector2((size.x - lbl_size.x) / 2, -lbl_size.y - offset)
	elif name_position == 2: # Bottom
		name_label.position = Vector2((size.x - lbl_size.x) / 2, size.y + offset)
	elif name_position == 3: # Left
		name_label.position = Vector2(-lbl_size.x - offset, (size.y - lbl_size.y) / 2)
	elif name_position == 4: # Right
		name_label.position = Vector2(size.x + offset, (size.y - lbl_size.y) / 2)
	elif name_position == 5: # Center
		name_label.position = Vector2((size.x - lbl_size.x) / 2, (size.y - lbl_size.y) / 2)

func set_orientation(vertical: bool):
	is_vertical = vertical
	# Adjust proportions roughly
	var current_center = position + size / 2
	if is_vertical and size.x > size.y:
		size = Vector2(size.y, size.x)
	elif not is_vertical and size.y > size.x:
		size = Vector2(size.y, size.x)
	custom_minimum_size = size
	position = current_center - size / 2
