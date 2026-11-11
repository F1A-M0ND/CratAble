extends Control

signal play_clicked
signal create_clicked
signal help_clicked
const Style = preload("res://scripts/PlatformStyle.gd")
const Motion = preload("res://scripts/InteractionMotion.gd")
var _atmosphere: Control
var _art: Control
var _view = Vector2.ZERO
var _motion_enabled = true
var _pointer_inside = true
var _window_focused = true

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if OS.has_feature("web"):
		_motion_enabled = not bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches"))
	var atmosphere = preload("res://scripts/HomeSpaceBackground.gd").new()
	atmosphere.name = "HomeAtmosphere"
	add_child(atmosphere)
	_atmosphere = atmosphere
	atmosphere.set_motion_enabled(_motion_enabled)
	var art = preload("res://scripts/HomeHeroArt.gd").new()
	art.name = "SpaceTabletop"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	_art = art
	art.set_motion_enabled(_motion_enabled)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.anchor_left = 0.45
	art.anchor_right = 1.02
	art.anchor_top = 0.015
	art.anchor_bottom = 0.80
	get_window().mouse_entered.connect(_on_pointer_entered)
	get_window().mouse_exited.connect(_on_pointer_exited)
	visibility_changed.connect(_update_view_processing)
	_update_view_processing()
	var margin = MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 100)
	margin.add_theme_constant_override("margin_right", 100)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_bottom", 32)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var layout = VBoxContainer.new()
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_theme_constant_override("separation", 28)
	margin.add_child(layout)
	var hero_row = HBoxContainer.new()
	hero_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hero_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(hero_row)
	var copy = VBoxContainer.new()
	copy.custom_minimum_size.x = 770
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.size_flags_stretch_ratio = 0.47
	copy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	copy.add_theme_constant_override("separation", 14)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_row.add_child(copy)
	copy.add_child(_label("THE OPEN TABLETOP", 20, Style.ACCENT, true))
	var headline = _label("YOUR GAME.\nYOUR UNIVERSE.", 86, Color.WHITE, true)
	headline.add_theme_constant_override("line_spacing", -12)
	copy.add_child(headline)
	copy.add_child(_label("ทุกไอเดีย มีพื้นที่ให้เล่น", 34, Color("a9dcff")))
	var description = _label("ออกแบบการ์ด จัดเด็ค สร้างสนาม แล้วชวนเพื่อนมาเล่น\nโต๊ะนี้เป็นของคุณ กติกาก็เช่นกัน", 23, Color("a6b6cc"))
	description.add_theme_constant_override("line_spacing", 6)
	copy.add_child(description)
	var gap = Control.new()
	gap.custom_minimum_size.y = 12
	copy.add_child(gap)
	var actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 16)
	copy.add_child(actions)
	var play = _button("เริ่มเล่น  →", true)
	play.name = "PlayBtn"
	play.pressed.connect(func(): play_clicked.emit())
	actions.add_child(play)
	var create = _button("สร้างเกมของคุณ", false)
	create.name = "CreateBtn"
	create.pressed.connect(func(): create_clicked.emit())
	actions.add_child(create)
	var tiny = _label("LOCAL  /  ONLINE 2 PLAYERS", 17, Color("7d91b0"), true)
	copy.add_child(tiny)
	var visual_space = Control.new()
	visual_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visual_space.size_flags_stretch_ratio = 0.53
	hero_row.add_child(visual_space)
	var divider = HSeparator.new()
	divider.modulate = Color(0.6, 0.75, 1, 0.20)
	layout.add_child(divider)
	var paths = HBoxContainer.new()
	paths.add_theme_constant_override("separation", 32)
	layout.add_child(paths)
	_add_path(paths, "01", "MAKE IT YOURS", "ภาพการ์ดของคุณ สนามในแบบคุณ", create_clicked)
	_add_path(paths, "02", "BRING YOUR FRIENDS", "เล่นในเครื่อง หรือออนไลน์ 2 คน", play_clicked)
	_add_path(paths, "03", "LEARN BY PLAYING", "ลองลาก พลิก และทอยไปด้วยกัน", help_clicked)
	var footer = HBoxContainer.new()
	layout.add_child(footer)
	footer.add_child(_label("CRATABLE  /  A TABLE FOR EVERY IDEA", 15, Color("71829d"), true))
	var fill = Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(fill)
	footer.add_child(_label("CREATE. PLAY. REPEAT.", 15, Color("71829d"), true))

# One camera drives both foreground and background, so their depth stays coherent.
# Polling the viewport leaves buttons, keyboard focus and drag gestures untouched.
func _process(delta: float):
	var viewport_rect = get_viewport().get_visible_rect()
	var point = get_viewport().get_mouse_position()
	var target = Vector2.ZERO
	if _pointer_inside and viewport_rect.has_point(point) and viewport_rect.size.x > 0 and viewport_rect.size.y > 0:
		target = ((point - viewport_rect.position) / viewport_rect.size - Vector2(0.5, 0.5)) * 2.0
	_view = _view.lerp(target, 1.0 - exp(-4.0 * minf(delta, 0.05)))
	_apply_view()

func _apply_view():
	if is_instance_valid(_atmosphere): _atmosphere.set_view(_view)
	if is_instance_valid(_art): _art.set_view(_view)

func _on_pointer_entered():
	_pointer_inside = true

func _on_pointer_exited():
	_pointer_inside = false

func _notification(what: int):
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_window_focused = false
		_view = Vector2.ZERO
		_apply_view()
		_update_view_processing()
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_window_focused = true
		_update_view_processing()

func _update_view_processing():
	set_process(_motion_enabled and _window_focused and is_visible_in_tree())

func _label(text: String, font_size: int, color: Color, display: bool = false) -> Label:
	var label = Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if display: label.add_theme_font_override("font", Style.display_font())
	return label

func _button(text: String, primary: bool) -> Button:
	var button = Button.new()
	button.text = text
	button.set_meta("style_owned", true)
	button.custom_minimum_size = Vector2(242, 70)
	button.add_theme_font_size_override("font_size", 24)
	var normal = Style.glass(Color("a1deff") if primary else Color(0.08, 0.13, 0.22, 0.75), 18)
	normal.border_color = Color("c4ecff") if primary else Color(0.62, 0.79, 1.0, 0.25)
	normal.shadow_color = Color(0.23, 0.55, 1.0, 0.18)
	normal.shadow_size = 14 if primary else 0
	var hover = normal.duplicate()
	hover.bg_color = Color("d5efff") if primary else Color("203754")
	hover.border_color = Style.ACCENT
	var focus = Style.glass(Color.TRANSPARENT, 18)
	focus.border_color = Color.WHITE
	focus.set_border_width_all(2)
	for state in ["normal", "pressed"]: button.add_theme_stylebox_override(state, normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", focus)
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(state, Color("071322") if primary else Color.WHITE)
	Motion.button(button)
	return button

func _add_path(parent: HBoxContainer, number: String, title: String, description: String, action: Signal):
	var button = Button.new()
	button.set_meta("style_owned", true)
	button.custom_minimum_size.y = 112
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var normal = Style.glass(Color.TRANSPARENT, 16)
	normal.border_color = Color.TRANSPARENT
	normal.shadow_size = 0
	var hover = Style.glass(Color(0.32, 0.52, 0.82, 0.09), 16)
	hover.shadow_size = 0
	var focus = Style.glass(Color.TRANSPARENT, 16)
	focus.border_color = Style.ACCENT
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", focus)
	button.pressed.connect(func(): action.emit())
	parent.add_child(button)
	var row = HBoxContainer.new()
	button.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 14
	row.offset_right = -14
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 22)
	var index = _label(number, 23, Style.ACCENT, true)
	index.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(index)
	var info = VBoxContainer.new()
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(info)
	info.add_child(_label(title, 26, Color("eff6ff"), true))
	info.add_child(_label(description, 20, Color("96aac4")))
	row.add_child(_label("↗", 28, Style.ACCENT))
	Motion.button(button)
