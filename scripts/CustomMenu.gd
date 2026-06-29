extends Control

func _ready():
	$HBoxContainer/CardBtn.pressed.connect(_on_card_pressed)
	$HBoxContainer/DeckBtn.pressed.connect(_on_deck_pressed)
	$HBoxContainer/FieldBtn.pressed.connect(_on_field_pressed)
	
	_apply_card_styles()
	_init_liquid_auras()

func _on_card_pressed():
	Global.switch_scene("res://scenes/CardSelector.tscn")

func _on_deck_pressed():
	Global.switch_scene("res://scenes/DeckEditor.tscn")

func _on_field_pressed():
	Global.switch_scene("res://scenes/FieldCreator.tscn")

func _apply_card_styles():
	var cards = [
		$HBoxContainer/CardBtn,
		$HBoxContainer/DeckBtn,
		$HBoxContainer/FieldBtn
	]
	
	# Premium Glassmorphic normal style (semi-transparent dark glass with light white border)
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.08, 0.08, 0.08, 0.45) # Dark semi-transparent glass
	normal_style.set_border_width_all(1)
	normal_style.border_color = Color(1.0, 1.0, 1.0, 0.14) # Clean reflection edge
	normal_style.set_corner_radius_all(20)
	normal_style.shadow_color = Color(0, 0, 0, 0.35)
	normal_style.shadow_size = 8
	normal_style.shadow_offset = Vector2(0, 8)
	
	# Premium Glassmorphic hover style (brighter glass with orange aura glowing border and shadow)
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.12, 0.12, 0.12, 0.6) # Brighter glass
	hover_style.set_border_width_all(2)
	hover_style.border_color = Color(0.98, 0.45, 0.08, 0.95) # Vibrant orange border
	hover_style.set_corner_radius_all(20)
	hover_style.shadow_color = Color(0.98, 0.45, 0.08, 0.35) # Orange aura glow
	hover_style.shadow_size = 20
	hover_style.shadow_offset = Vector2(0, 8)
	
	# Pressed style (deeper dark glass with thin orange border)
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.06, 0.06, 0.06, 0.5)
	pressed_style.set_border_width_all(2)
	pressed_style.border_color = Color(0.85, 0.35, 0.05, 0.95)
	pressed_style.set_corner_radius_all(20)
	pressed_style.shadow_color = Color(0.85, 0.35, 0.05, 0.25)
	pressed_style.shadow_size = 12
	pressed_style.shadow_offset = Vector2(0, 4)
	
	for card in cards:
		card.add_theme_stylebox_override("normal", normal_style)
		card.add_theme_stylebox_override("hover", hover_style)
		card.add_theme_stylebox_override("pressed", pressed_style)
		card.add_theme_stylebox_override("focus", hover_style)
		
		# Connect scale animations
		card.mouse_entered.connect(func(): _animate_card_scale(card, Vector2(1.03, 1.03)))
		card.mouse_exited.connect(func(): _animate_card_scale(card, Vector2(1.0, 1.0)))

func _animate_card_scale(card: Control, target_scale: Vector2):
	var tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	card.pivot_offset = card.size / 2.0
	tween.tween_property(card, "scale", target_scale, 0.25)

func _init_liquid_auras():
	# Create a container for the background aura effects
	var aura_container = Control.new()
	aura_container.name = "AuraContainer"
	aura_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aura_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Add it at the back so it renders behind the cards
	add_child(aura_container)
	move_child(aura_container, 0)
	
	# Create a soft orange radial gradient texture
	var grad = Gradient.new()
	grad.colors = PackedColorArray([
		Color(0.98, 0.42, 0.05, 0.18), # Vibrant soft orange in center
		Color(0.98, 0.35, 0.05, 0.06), # Dimmer orange midpoint
		Color(0.98, 0.3, 0.05, 0.0)    # Fully transparent at edge
	])
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 512
	tex.height = 512
	
	# BlobCentral (Behind cards)
	var blob = TextureRect.new()
	blob.name = "BlobCentral"
	blob.texture = tex
	blob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blob.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	blob.custom_minimum_size = Vector2(900, 700)
	blob.size = Vector2(900, 700)
	# Center it on the screen
	blob.set_anchors_preset(Control.PRESET_CENTER)
	blob.grow_horizontal = Control.GROW_DIRECTION_BOTH
	blob.grow_vertical = Control.GROW_DIRECTION_BOTH
	blob.pivot_offset = Vector2(450, 350)
	aura_container.add_child(blob)
	
	# Soft float animation for the central aura
	var tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(blob, "scale", Vector2(1.08, 1.08), 3.0)
	tween.tween_property(blob, "scale", Vector2(0.95, 0.95), 3.0)
