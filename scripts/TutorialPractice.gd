extends Control

signal progressed(message: String)
var card: PanelContainer
var face: Label
var target: Panel
var dice_button: Button
var completed = [false, false, false]
var dragging = false
var grab = Vector2.ZERO
var down = false
var flip_menu: PopupMenu

func _ready():
	custom_minimum_size = Vector2(0, 240)
	target = Panel.new()
	target.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.size = Vector2(120, 164)
	var style = preload("res://scripts/PlatformStyle.gd").glass(Color(0.26, 0.66, 1.0, 0.08), 14)
	style.border_color = Color("73ceff")
	style.set_border_width_all(2)
	target.add_theme_stylebox_override("panel", style)
	add_child(target)
	var hint = Label.new()
	hint.text = "วางที่นี่"
	hint.add_theme_color_override("font_color", Color("73ceff"))
	hint.add_theme_font_size_override("font_size", 20)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	target.add_child(hint)
	card = PanelContainer.new()
	card.size = Vector2(106, 148)
	card.mouse_default_cursor_shape = Control.CURSOR_DRAG
	var card_style = preload("res://scripts/PlatformStyle.gd").glass(Color("e9f4ff"), 12)
	card_style.border_color = Color("73ceff")
	card_style.set_border_width_all(2)
	card.add_theme_stylebox_override("panel", card_style)
	add_child(card)
	face = Label.new()
	face.text = "✦\nEXPLORER\n01"
	face.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	face.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.add_theme_font_size_override("font_size", 19)
	face.add_theme_font_override("font", preload("res://scripts/PlatformStyle.gd").display_font())
	face.add_theme_color_override("font_color", Color("17234e"))
	card.add_child(face)
	card.gui_input.connect(_card_input)
	dice_button = Button.new()
	dice_button.text = "ทอย D6"
	dice_button.size = Vector2(130, 52)
	dice_button.set_meta("style_owned", true)
	dice_button.pressed.connect(roll)
	add_child(dice_button)
	var dice_style = preload("res://scripts/PlatformStyle.gd").glass(Color("ffffff"), 12)
	dice_style.border_color = Color("05080e")
	dice_style.set_border_width_all(2)
	var dice_hover = dice_style.duplicate()
	dice_hover.bg_color = Color("e0f3ff")
	for state in ["normal", "pressed", "disabled"]: dice_button.add_theme_stylebox_override(state, dice_style)
	for state in ["hover", "focus"]: dice_button.add_theme_stylebox_override(state, dice_hover)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		dice_button.add_theme_color_override(state, Color("05080e"))
	preload("res://scripts/InteractionMotion.gd").button(dice_button)
	flip_menu = PopupMenu.new()
	flip_menu.add_item("พลิกการ์ด / Face Up–Down", 0)
	flip_menu.id_pressed.connect(func(_id): flip())
	add_child(flip_menu)
	resized.connect(reset_layout)
	reset_layout()

func reset_layout():
	if not is_instance_valid(card): return
	if size.x < 290:
		custom_minimum_size.y = 460
		card.position = Vector2(maxf(0, (size.x - card.size.x) / 2), 12)
		target.position = Vector2(maxf(0, (size.x - target.size.x) / 2), 178)
		dice_button.position = Vector2(maxf(0, (size.x - dice_button.size.x) / 2), 370)
	elif size.x < 600:
		custom_minimum_size.y = 290
		card.position = Vector2(12, 30)
		target.position = Vector2(size.x - target.size.x - 12, 22)
		dice_button.position = Vector2((size.x - dice_button.size.x) / 2, 218)
	else:
		custom_minimum_size.y = 240
		card.position = Vector2(24, 42)
		target.position = Vector2(size.x * 0.45 - 60, 34)
		dice_button.position = Vector2(size.x - 160, 90)

func _card_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			flip_menu.position = Vector2i(get_screen_transform() * get_local_mouse_position())
			flip_menu.popup()
			accept_event()
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var motion = card.get_meta("drop_motion") if card.has_meta("drop_motion") else null
				if motion is Tween and motion.is_valid(): motion.kill()
			dragging = event.pressed
			grab = card.get_local_mouse_position()
			if not dragging: drop()
			accept_event()
	if event is InputEventMouseMotion and dragging:
		card.position = get_local_mouse_position() - grab
		card.position = card.position.clamp(Vector2.ZERO, (size - card.size).max(Vector2.ZERO))
		accept_event()

func drop():
	if target.get_rect().has_point(card.position + card.size / 2):
		preload("res://scripts/InteractionMotion.gd").tween(card, "drop_motion").tween_property(card, "position", target.position + (target.size - card.size) / 2, 0.12)
		completed[0] = true
		progressed.emit("วางสำเร็จ! ต่อไปลองคลิกขวาที่การ์ดเพื่อพลิก")
	else:
		progressed.emit("ลากให้กึ่งกลางการ์ดอยู่ในกรอบสีฟ้า แล้วปล่อย")

func flip():
	down = not down
	face.text = "✦\nCRATABLE" if down else "✦\nEXPLORER\n01"
	preload("res://scripts/InteractionMotion.gd").flip_visual(card)
	completed[1] = true
	progressed.emit("พลิกแล้ว! ในโต๊ะจริง คลิกขวาแล้วเลือก Face Up / Face Down")

func roll():
	dice_button.text = "D6  /  %d" % randi_range(1, 6)
	completed[2] = true
	progressed.emit("ทอยแล้ว! ผลอยู่ระหว่าง 1–6 ลองกดซ้ำได้")

func reset_practice():
	completed = [false, false, false]
	var motion = card.get_meta("drop_motion") if card.has_meta("drop_motion") else null
	if motion is Tween and motion.is_valid(): motion.kill()
	dragging = false
	down = false
	face.text = "✦\nEXPLORER\n01"
	dice_button.text = "ทอย D6"
	reset_layout()
	progressed.emit("เริ่มจากลากการ์ดไปวางในกรอบสีฟ้า")
