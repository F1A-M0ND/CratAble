extends Control

@onready var content_container = $HBoxContainer/ContentContainer
@onready var play_btn = $HBoxContainer/SidebarContainer/VBoxContainer/PlayBtn
@onready var custom_btn = $HBoxContainer/SidebarContainer/VBoxContainer/CustomBtn
@onready var credit_btn = $HBoxContainer/SidebarContainer/VBoxContainer/CreditBtn

var room_list_scene = preload("res://scenes/RoomList.tscn")
var custom_menu_scene = preload("res://scenes/CustomMenu.tscn")
var current_page = null

func _ready():
	play_btn.pressed.connect(_on_play_pressed)
	custom_btn.pressed.connect(_on_custom_pressed)
	credit_btn.pressed.connect(_on_credit_pressed)
	
	if Global.main_menu_tab == "CUSTOM":
		call_deferred("_on_custom_pressed")
	elif Global.main_menu_tab == "CREDIT":
		call_deferred("_on_credit_pressed")
	else:
		call_deferred("_on_play_pressed")

func _load_page(scene_resource):
	if current_page != null:
		current_page.queue_free()
	
	if scene_resource:
		var instance = scene_resource.instantiate()
		content_container.add_child(instance)
		current_page = instance
	else:
		current_page = null

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
	var active_color = Color(0.15, 0.15, 0.15)
	var inactive_color = Color(0.1, 0.1, 0.1)
	var border_color = Color(0.8, 0.8, 0.8)
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = inactive_color
	normal_style.border_color = border_color
	normal_style.set_border_width_all(2)
	
	var active_style = StyleBoxFlat.new()
	active_style.bg_color = active_color
	active_style.border_color = border_color
	active_style.set_border_width_all(2)
	active_style.border_width_right = 0
	
	var content_style = StyleBoxFlat.new()
	content_style.bg_color = active_color
	content_style.border_color = border_color
	content_style.set_border_width_all(2)
	content_container.add_theme_stylebox_override("panel", content_style)
	
	var buttons = [play_btn, custom_btn, credit_btn]
	for btn in buttons:
		var tab_name = btn.name.replace("Btn", "").to_upper()
		if tab_name == Global.main_menu_tab:
			btn.add_theme_stylebox_override("normal", active_style)
			btn.add_theme_stylebox_override("hover", active_style)
			btn.add_theme_stylebox_override("pressed", active_style)
			btn.add_theme_stylebox_override("focus", active_style)
		else:
			btn.add_theme_stylebox_override("normal", normal_style)
			btn.add_theme_stylebox_override("hover", normal_style)
			btn.add_theme_stylebox_override("pressed", normal_style)
			btn.add_theme_stylebox_override("focus", normal_style)
