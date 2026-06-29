extends Control

signal play_clicked

@onready var play_btn = $MarginContainer/HBoxContainer/InfoCard/MarginContainer/InfoContainer/PlayBtn
@onready var cover_card = $MarginContainer/HBoxContainer/CoverCard
@onready var info_card = $MarginContainer/HBoxContainer/InfoCard

func _ready():
	play_btn.pressed.connect(_on_play_pressed)
	_apply_premium_styles()
	_init_liquid_auras()

func _on_play_pressed():
	emit_signal("play_clicked")

func _apply_premium_styles():
	# Orange Liquid Glass styles for Get Started button
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.98, 0.45, 0.08, 0.85) # Vibrant orange semi-transparent
	btn_normal.set_border_width_all(1)
	btn_normal.border_color = Color(1.0, 1.0, 1.0, 0.2)
	btn_normal.set_corner_radius_all(12)
	btn_normal.shadow_color = Color(0.98, 0.45, 0.08, 0.25)
	btn_normal.shadow_size = 12
	btn_normal.shadow_offset = Vector2(0, 4)
	
	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color(1.0, 0.55, 0.15, 0.95) # Brighter glow orange
	btn_hover.set_border_width_all(2)
	btn_hover.border_color = Color(1.0, 1.0, 1.0, 0.3)
	btn_hover.set_corner_radius_all(12)
	btn_hover.shadow_color = Color(1.0, 0.55, 0.15, 0.5)
	btn_hover.shadow_size = 20
	btn_hover.shadow_offset = Vector2(0, 6)
	
	var btn_pressed = StyleBoxFlat.new()
	btn_pressed.bg_color = Color(0.85, 0.35, 0.05, 0.9)
	btn_pressed.set_border_width_all(1)
	btn_pressed.border_color = Color(1.0, 1.0, 1.0, 0.15)
	btn_pressed.set_corner_radius_all(12)
	btn_pressed.shadow_color = Color(0.85, 0.35, 0.05, 0.2)
	btn_pressed.shadow_size = 8
	btn_pressed.shadow_offset = Vector2(0, 2)
	
	play_btn.add_theme_stylebox_override("normal", btn_normal)
	play_btn.add_theme_stylebox_override("hover", btn_hover)
	play_btn.add_theme_stylebox_override("pressed", btn_pressed)
	play_btn.add_theme_stylebox_override("focus", btn_hover)
	
	# Add custom text color
	play_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	play_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	play_btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9))
	
	# Apply glassmorphic styles to CoverCard and InfoCard
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.08, 0.08, 0.08, 0.45) # Dark semi-transparent glass
	card_style.set_border_width_all(1)
	card_style.border_color = Color(1.0, 1.0, 1.0, 0.14) # Clean reflection edge
	card_style.set_corner_radius_all(24)
	card_style.shadow_color = Color(0, 0, 0, 0.3)
	card_style.shadow_size = 12
	card_style.shadow_offset = Vector2(0, 8)
	
	cover_card.add_theme_stylebox_override("panel", card_style)
	info_card.add_theme_stylebox_override("panel", card_style)
	
	# Connect hover animations for cards and button
	_setup_card_hover_animations(cover_card)
	_setup_card_hover_animations(info_card)
	_setup_btn_hover_animations(play_btn)

func _setup_card_hover_animations(card: Control):
	card.mouse_entered.connect(func():
		var tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		card.pivot_offset = card.size / 2.0
		tween.tween_property(card, "scale", Vector2(1.015, 1.015), 0.3)
		var hover_style = card.get_theme_stylebox("panel").duplicate()
		hover_style.border_color = Color(0.98, 0.45, 0.08, 0.4) # Soft orange border glow
		hover_style.shadow_color = Color(0.98, 0.45, 0.08, 0.15)
		card.add_theme_stylebox_override("panel", hover_style)
	)
	
	card.mouse_exited.connect(func():
		var tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		card.pivot_offset = card.size / 2.0
		tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.3)
		var normal_style = card.get_theme_stylebox("panel").duplicate()
		normal_style.border_color = Color(1.0, 1.0, 1.0, 0.14)
		normal_style.shadow_color = Color(0, 0, 0, 0.3)
		card.add_theme_stylebox_override("panel", normal_style)
	)

func _setup_btn_hover_animations(btn: Button):
	btn.mouse_entered.connect(func():
		var tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		btn.pivot_offset = btn.size / 2.0
		tween.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.2)
	)
	btn.mouse_exited.connect(func():
		var tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		btn.pivot_offset = btn.size / 2.0
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.2)
	)

func _init_liquid_auras():
	# Container for radial background glows
	var aura_container = Control.new()
	aura_container.name = "AuraContainer"
	aura_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aura_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(aura_container)
	move_child(aura_container, 0)
	
	var grad = Gradient.new()
	grad.colors = PackedColorArray([
		Color(0.98, 0.42, 0.05, 0.16),
		Color(0.98, 0.35, 0.05, 0.05),
		Color(0.98, 0.3, 0.05, 0.0)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 512
	tex.height = 512
	
	# Left Blob (behind CoverCard)
	var blob_left = TextureRect.new()
	blob_left.texture = tex
	blob_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blob_left.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	blob_left.custom_minimum_size = Vector2(700, 700)
	blob_left.size = Vector2(700, 700)
	blob_left.position = Vector2(-150, -50)
	blob_left.pivot_offset = Vector2(350, 350)
	aura_container.add_child(blob_left)
	
	# Right Blob (behind InfoCard)
	var blob_right = TextureRect.new()
	blob_right.texture = tex
	blob_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blob_right.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	blob_right.custom_minimum_size = Vector2(700, 700)
	blob_right.size = Vector2(700, 700)
	blob_right.position = Vector2(900, 150)
	blob_right.pivot_offset = Vector2(350, 350)
	aura_container.add_child(blob_right)
	
	# Soft float animation for blobs
	var tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(blob_left, "scale", Vector2(1.06, 1.06), 4.0)
	tween.parallel().tween_property(blob_right, "scale", Vector2(0.94, 0.94), 4.0)
	tween.tween_property(blob_left, "scale", Vector2(0.94, 0.94), 4.0)
	tween.parallel().tween_property(blob_right, "scale", Vector2(1.06, 1.06), 4.0)
