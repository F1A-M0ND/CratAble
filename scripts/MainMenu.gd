extends Control

const Style = preload("res://scripts/PlatformStyle.gd")
const Motion = preload("res://scripts/InteractionMotion.gd")

var content_container: PanelContainer
var play_btn: Button
var custom_btn: Button
var help_btn: Button
var credit_btn: Button
var title_btn: Button
var home_btn: Button
var room_list_scene = preload("res://scenes/RoomList.tscn")
var custom_menu_scene = preload("res://scenes/CustomMenu.tscn")
var lobby_home_scene = preload("res://scenes/LobbyHome.tscn")
var current_page = null
var _static_backdrop_material: Material

func _ready():
	_build_shell()
	Style.apply(self)
	_static_backdrop_material = $PlatformBackground.material
	# The shell owns its transparent surfaces, independent from editor dialogs.
	content_container.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	play_btn.pressed.connect(_on_play_pressed)
	custom_btn.pressed.connect(_on_custom_pressed)
	help_btn.pressed.connect(_on_help_pressed)
	credit_btn.pressed.connect(_on_credit_pressed)
	title_btn.pressed.connect(_on_home_pressed)
	home_btn.pressed.connect(_on_home_pressed)
	match Global.main_menu_tab:
		"CUSTOM": _on_custom_pressed()
		"HELP": _on_help_pressed()
		"CREDIT": _on_credit_pressed()
		"PLAY": _on_play_pressed()
		_: _on_home_pressed()

func _build_shell():
	var frame = VBoxContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_constant_override("separation", 0)
	add_child(frame)
	var header = PanelContainer.new()
	header.name = "Navigation"
	header.custom_minimum_size.y = 112
	var surface = Style.glass(Color(0.025, 0.04, 0.075, 0.82), 0)
	surface.set_border_width_all(0)
	surface.border_width_bottom = 1
	surface.border_color = Color(0.6, 0.77, 1.0, 0.14)
	surface.shadow_size = 0
	surface.content_margin_left = 74
	surface.content_margin_right = 74
	header.add_theme_stylebox_override("panel", surface)
	frame.add_child(header)
	var nav = HBoxContainer.new()
	nav.add_theme_constant_override("separation", 14)
	header.add_child(nav)
	title_btn = _nav_button("CRATABLE", "Brand")
	title_btn.custom_minimum_size.x = 260
	title_btn.add_theme_font_size_override("font_size", 38)
	title_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	nav.add_child(title_btn)
	var spacer = Control.new()
	spacer.custom_minimum_size.x = 50
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(spacer)
	home_btn = _nav_button("HOME", "HomeBtn")
	play_btn = _nav_button("PLAY", "PlayBtn")
	custom_btn = _nav_button("CREATE", "CustomBtn")
	help_btn = _nav_button("HOW TO PLAY", "HelpBtn")
	credit_btn = _nav_button("CREDITS", "CreditBtn")
	for button in [home_btn, play_btn, custom_btn, help_btn, credit_btn]:
		nav.add_child(button)
	var end_spacer = Control.new()
	end_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(end_spacer)
	var note = Label.new()
	note.text = "YOUR RULES.\nYOUR TABLE."
	note.add_theme_font_size_override("font_size", 16)
	note.add_theme_font_override("font", Style.display_font())
	note.add_theme_color_override("font_color", Color("93adc8"))
	nav.add_child(note)
	content_container = PanelContainer.new()
	content_container.name = "ContentContainer"
	content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.add_child(content_container)

func _nav_button(text: String, node_name: String) -> Button:
	var button = Button.new()
	button.name = node_name
	button.text = text
	button.set_meta("style_owned", true)
	button.custom_minimum_size = Vector2(125, 56)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_override("font", Style.display_font())
	button.add_theme_font_size_override("font_size", 24)
	Motion.button(button)
	return button

func _load_page(scene_resource):
	var backdrop = get_node_or_null("PlatformBackground")
	if backdrop:
		# Home draws its own moving atmosphere. Keep a cheap dark fill under the
		# translucent navigation instead of running two full-screen space shaders.
		backdrop.material = null if scene_resource == lobby_home_scene else _static_backdrop_material
		backdrop.color = Color("05080f") if scene_resource == lobby_home_scene else Color.WHITE
	if is_instance_valid(current_page):
		content_container.remove_child(current_page)
		current_page.queue_free()
	current_page = null
	if scene_resource:
		current_page = scene_resource.instantiate()
		content_container.add_child(current_page)
		Style._style_controls(current_page)
		Motion.reveal(current_page)

func _on_home_pressed():
	Global.main_menu_tab = "HOME"
	_load_page(lobby_home_scene)
	current_page.play_clicked.connect(_on_play_pressed)
	current_page.create_clicked.connect(_on_custom_pressed)
	current_page.help_clicked.connect(_on_help_pressed)
	_update_tab_visuals()

func _on_play_pressed():
	Global.main_menu_tab = "PLAY"
	_load_page(room_list_scene)
	_update_tab_visuals()

func _on_custom_pressed():
	Global.main_menu_tab = "CUSTOM"
	_load_page(custom_menu_scene)
	_update_tab_visuals()

func _on_help_pressed():
	Global.main_menu_tab = "HELP"
	_load_page(preload("res://scenes/HelpPage.tscn"))
	_update_tab_visuals()

func _on_credit_pressed():
	Global.main_menu_tab = "CREDIT"
	_load_page(null)
	var center = CenterContainer.new()
	content_container.add_child(center)
	current_page = center
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	center.add_child(column)
	var title = Label.new()
	title.text = "MADE FOR YOUR IDEAS."
	title.add_theme_font_override("font", Style.display_font())
	title.add_theme_font_size_override("font_size", 62)
	title.add_theme_color_override("font_color", Style.ACCENT)
	column.add_child(title)
	var description = Label.new()
	description.text = "CratAble — Card Game Prototyping\nแพลตฟอร์มสร้างและเล่นเกมการ์ดบนโต๊ะเสมือน\nคุณกำหนดกติกา เราเตรียมโต๊ะและอุปกรณ์ให้"
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.add_theme_font_size_override("font_size", 24)
	column.add_child(description)
	_update_tab_visuals()

func _update_tab_visuals():
	var buttons = {home_btn: "HOME", play_btn: "PLAY", custom_btn: "CUSTOM", help_btn: "HELP", credit_btn: "CREDIT", title_btn: "BRAND"}
	for button in buttons:
		var active = buttons[button] == Global.main_menu_tab
		var normal = Style.glass(Color(0.30, 0.57, 0.83, 0.13) if active else Color(0, 0, 0, 0), 14)
		normal.shadow_size = 0
		normal.border_color = Color(0.53, 0.77, 1.0, 0.28) if active else Color.TRANSPARENT
		var hover = Style.glass(Color(0.36, 0.59, 0.83, 0.16), 14)
		hover.shadow_size = 0
		var focus = Style.glass(Color.TRANSPARENT, 14)
		focus.border_color = Style.ACCENT
		focus.shadow_size = 0
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", hover)
		button.add_theme_stylebox_override("focus", focus)
		button.add_theme_color_override("font_color", Style.ACCENT if active else Color("d4e1f0"))
		button.add_theme_color_override("font_hover_color", Color.WHITE)
	title_btn.add_theme_color_override("font_color", Color.WHITE)
