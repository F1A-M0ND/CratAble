extends Control

@onready var content_container = $HBoxContainer/ContentContainer
@onready var play_btn = $HBoxContainer/SidebarContainer/VBoxContainer/PlayBtn
@onready var custom_btn = $HBoxContainer/SidebarContainer/VBoxContainer/CustomBtn
@onready var credit_btn = $HBoxContainer/SidebarContainer/VBoxContainer/CreditBtn
@onready var title_btn = $HBoxContainer/SidebarContainer/VBoxContainer/Title

var room_list_scene = preload("res://scenes/RoomList.tscn")
var custom_menu_scene = preload("res://scenes/CustomMenu.tscn")
var lobby_home_scene = preload("res://scenes/LobbyHome.tscn")
var current_page = null

func _ready():
	play_btn.pressed.connect(_on_play_pressed)
	custom_btn.pressed.connect(_on_custom_pressed)
	credit_btn.pressed.connect(_on_credit_pressed)
	title_btn.pressed.connect(_on_home_pressed)
	
	# Connect micro-animations for hover scaling
	_setup_btn_hover_animations(play_btn)
	_setup_btn_hover_animations(custom_btn)
	_setup_btn_hover_animations(credit_btn)
	
	if Global.main_menu_tab == "CUSTOM":
		call_deferred("_on_custom_pressed")
	elif Global.main_menu_tab == "CREDIT":
		call_deferred("_on_credit_pressed")
	elif Global.main_menu_tab == "PLAY":
		call_deferred("_on_play_pressed")
	else:
		call_deferred("_on_home_pressed")

func _load_page(scene_resource):
	if current_page != null:
		current_page.queue_free()
	
	if scene_resource:
		var instance = scene_resource.instantiate()
		content_container.add_child(instance)
		current_page = instance
	else:
		current_page = null

func _on_home_pressed():
	Global.main_menu_tab = "HOME"
	_load_page(lobby_home_scene)
	if current_page and current_page.has_signal("play_clicked"):
		current_page.play_clicked.connect(_on_play_pressed)
	_update_tab_visuals()

func _on_play_pressed():
	Global.main_menu_tab = "PLAY"
	_load_page(room_list_scene)
	_update_tab_visuals()

func _on_custom_pressed():
	Global.main_menu_tab = "CUSTOM"
	_load_page(custom_menu_scene)
	_update_tab_visuals()

func _on_credit_pressed():
	Global.main_menu_tab = "CREDIT"
	_load_page(null)
	var label = Label.new()
	label.text = "CratAble - Card Game Prototyping\n\nDeveloped for Tabletop Card Games"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content_container.add_child(label)
	current_page = label
	_update_tab_visuals()

func _update_tab_visuals():
	# 1. Style the Sidebar Panel Container (Liquid Glass)
	var sidebar_style = StyleBoxFlat.new()
	sidebar_style.bg_color = Color(0.07, 0.07, 0.09, 0.55) # Dark transparent glass
	sidebar_style.set_border_width_all(0)
	sidebar_style.border_width_right = 1 # Soft right edge reflection line
	sidebar_style.border_color = Color(1.0, 1.0, 1.0, 0.08)
	sidebar_style.set_corner_radius_all(0)
	sidebar_style.corner_radius_top_right = 16
	sidebar_style.corner_radius_bottom_right = 16
	
	# Content margins to push buttons inwards cleanly
	sidebar_style.content_margin_left = 18
	sidebar_style.content_margin_top = 25
	sidebar_style.content_margin_right = 18
	sidebar_style.content_margin_bottom = 25
	
	$HBoxContainer/SidebarContainer.add_theme_stylebox_override("panel", sidebar_style)
	
	# 2. Style the Content Area Panel Container
	var content_style = StyleBoxFlat.new()
	content_style.bg_color = Color(0.04, 0.04, 0.05, 0.95) # Dark content container background
	content_style.set_border_width_all(0)
	content_container.add_theme_stylebox_override("panel", content_style)
	
	# 3. Style the Title logo/button
	var title_normal = StyleBoxEmpty.new()
	title_btn.add_theme_stylebox_override("normal", title_normal)
	title_btn.add_theme_stylebox_override("hover", title_normal)
	title_btn.add_theme_stylebox_override("pressed", title_normal)
	title_btn.add_theme_stylebox_override("focus", title_normal)
	title_btn.add_theme_color_override("font_color", Color(0.98, 0.45, 0.08)) # Orange brand color
	title_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.55, 0.15))
	
	# 4. Button styles (Normal/Inactive, Hover, Active/Selected)
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0, 0, 0, 0) # Flat/transparent inactive state
	btn_normal.set_border_width_all(0)
	btn_normal.set_corner_radius_all(10)
	
	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color(1.0, 1.0, 1.0, 0.05) # Soft white hover highlight
	btn_hover.set_border_width_all(1)
	btn_hover.border_color = Color(1.0, 1.0, 1.0, 0.1)
	btn_hover.set_corner_radius_all(10)
	
	var btn_active = StyleBoxFlat.new()
	btn_active.bg_color = Color(0.98, 0.45, 0.08, 0.85) # Orange liquid glass active tab
	btn_active.set_border_width_all(1)
	btn_active.border_color = Color(1.0, 1.0, 1.0, 0.2)
	btn_active.set_corner_radius_all(10)
	btn_active.shadow_color = Color(0.98, 0.45, 0.08, 0.3)
	btn_active.shadow_size = 8
	btn_active.shadow_offset = Vector2(0, 2)
	
	var buttons = [play_btn, custom_btn, credit_btn]
	for btn in buttons:
		var tab_name = btn.name.replace("Btn", "").to_upper()
		btn.custom_minimum_size = Vector2(0, 48) # Taller premium button size
		
		if tab_name == Global.main_menu_tab:
			btn.add_theme_stylebox_override("normal", btn_active)
			btn.add_theme_stylebox_override("hover", btn_active)
			btn.add_theme_stylebox_override("pressed", btn_active)
			btn.add_theme_stylebox_override("focus", btn_active)
			btn.add_theme_color_override("font_color", Color(1, 1, 1))
			btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
		else:
			btn.add_theme_stylebox_override("normal", btn_normal)
			btn.add_theme_stylebox_override("hover", btn_hover)
			btn.add_theme_stylebox_override("pressed", btn_hover)
			btn.add_theme_stylebox_override("focus", btn_hover)
			btn.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
			btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))

func _setup_btn_hover_animations(btn: Button):
	btn.mouse_entered.connect(func():
		var tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		btn.pivot_offset = btn.size / 2.0
		tween.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.2)
	)
	btn.mouse_exited.connect(func():
		var tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		btn.pivot_offset = btn.size / 2.0
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.2)
	)
