extends Control

signal play_clicked

@onready var play_btn = $MarginContainer/HBoxContainer/InfoContainer/PlayBtn

func _ready():
	play_btn.pressed.connect(_on_play_pressed)
	_apply_button_styles()

func _on_play_pressed():
	emit_signal("play_clicked")

func _apply_button_styles():
	# Make the Get Started button look stunning and premium (green style like chess.com)
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.3, 0.65, 0.25) # Premium vibrant green
	normal_style.set_corner_radius_all(10)
	normal_style.shadow_color = Color(0, 0, 0, 0.3)
	normal_style.shadow_size = 4
	normal_style.shadow_offset = Vector2(0, 4)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.35, 0.75, 0.3) # Slightly brighter green
	hover_style.set_corner_radius_all(10)
	hover_style.shadow_color = Color(0, 0, 0, 0.4)
	hover_style.shadow_size = 5
	hover_style.shadow_offset = Vector2(0, 4)
	
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.25, 0.55, 0.2) # Darker green on press
	pressed_style.set_corner_radius_all(10)
	pressed_style.shadow_color = Color(0, 0, 0, 0.2)
	pressed_style.shadow_size = 2
	pressed_style.shadow_offset = Vector2(0, 2)
	
	play_btn.add_theme_stylebox_override("normal", normal_style)
	play_btn.add_theme_stylebox_override("hover", hover_style)
	play_btn.add_theme_stylebox_override("pressed", pressed_style)
	play_btn.add_theme_stylebox_override("focus", hover_style)
	
	# Add custom text color
	play_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	play_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	play_btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9))
