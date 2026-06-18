extends CanvasLayer

@onready var background = $Background
@onready var main_layout = $MainLayout
@onready var card_image = $MainLayout/CardImage
@onready var name_label = $MainLayout/DetailsPanel/Margin/Scroll/DetailsVBox/NameLabel
@onready var stats_grid = $MainLayout/DetailsPanel/Margin/Scroll/DetailsVBox/StatsGrid
@onready var tags_flow = $MainLayout/DetailsPanel/Margin/Scroll/DetailsVBox/TagsFlow
@onready var close_btn = $CloseBtn

@onready var fullscreen_viewer = $FullscreenViewer
@onready var zoom_container = $FullscreenViewer/ZoomContainer
@onready var zoom_image = $FullscreenViewer/ZoomContainer/ZoomImage
@onready var viewer_close_btn = $FullscreenViewer/ViewerCloseBtn

var tween: Tween
var is_open: bool = false
var dragging_zoom: bool = false

func _ready():
	visible = false
	background.color.a = 0.0
	main_layout.modulate.a = 0.0
	close_btn.modulate.a = 0.0
	
	close_btn.pressed.connect(hide_card)
	viewer_close_btn.pressed.connect(hide_fullscreen)
	
	card_image.gui_input.connect(_on_card_image_gui_input)
	zoom_container.gui_input.connect(_on_zoom_container_gui_input)
	fullscreen_viewer.hide()

func _on_card_image_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if card_image.texture != null:
			show_fullscreen()

func show_fullscreen():
	zoom_image.texture = card_image.texture
	zoom_image.scale = Vector2(1, 1)
	zoom_image.position = Vector2(0, 0)
	fullscreen_viewer.modulate.a = 0.0
	fullscreen_viewer.show()
	var t = create_tween()
	t.tween_property(fullscreen_viewer, "modulate:a", 1.0, 0.2)

func hide_fullscreen():
	var t = create_tween()
	t.tween_property(fullscreen_viewer, "modulate:a", 0.0, 0.2)
	t.tween_callback(func(): fullscreen_viewer.hide())

func _on_zoom_container_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_apply_zoom(1.15, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_apply_zoom(0.85, event.position)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			dragging_zoom = event.pressed
	elif event is InputEventMouseMotion and dragging_zoom:
		zoom_image.position += event.relative

func _apply_zoom(factor: float, mouse_pos: Vector2):
	var min_zoom = 0.5
	var max_zoom = 5.0
	
	var old_scale = zoom_image.scale
	var new_scale = old_scale * factor
	new_scale.x = clamp(new_scale.x, min_zoom, max_zoom)
	new_scale.y = clamp(new_scale.y, min_zoom, max_zoom)
	
	if new_scale == old_scale: return
	
	var actual_factor = new_scale.x / old_scale.x
	zoom_image.position = mouse_pos + (zoom_image.position - mouse_pos) * actual_factor
	zoom_image.scale = new_scale

func show_card(card_data: Variant):
	if is_open: return
	
	var data: Dictionary = {}
	
	if typeof(card_data) == TYPE_DICTIONARY:
		data = card_data
	elif typeof(card_data) == TYPE_STRING:
		if card_data.strip_edges().begins_with("{"):
			var json = JSON.new()
			if json.parse(card_data) == OK:
				data = json.get_data()
		else:
			if FileAccess.file_exists(card_data):
				var str_content = FileAccess.get_file_as_string(card_data)
				var json = JSON.new()
				if json.parse(str_content) == OK:
					data = json.get_data()
					
	if data.is_empty():
		print("DEBUG: Inspector cannot parse card data: ", card_data)
		return
		
	# Normalize stats for both local JSON layout and Supabase structure
	var final_data = {}
	if data.has("stats") and typeof(data["stats"]) == TYPE_DICTIONARY:
		final_data = data["stats"].duplicate()
	else:
		final_data = data.duplicate()
		
	if data.has("name"): final_data["name"] = data["name"]
	if data.has("image_url"): final_data["image_url"] = data["image_url"]
	if data.has("image_path"): final_data["image_path"] = data["image_path"]
	if data.has("card_type"): final_data["card_type"] = data["card_type"]
	
	# Clear old data
	name_label.text = final_data.get("name", "Unknown Card")
	card_image.texture = null
	
	for child in stats_grid.get_children():
		child.queue_free()
	for child in tags_flow.get_children():
		child.queue_free()
		
	# Populate new data
	var image_src = ""
	if final_data.has("image_url") and final_data["image_url"] != "":
		image_src = final_data["image_url"]
	elif final_data.has("image_path") and final_data["image_path"] != "":
		image_src = final_data["image_path"]
		
	if image_src != "":
		if image_src.begins_with("http"):
			SupabaseService.get_texture_or_load(image_src, func(tex):
				if is_open and card_image:
					card_image.texture = tex
			)
		else:
			var img = Image.new()
			if img.load(image_src) == OK:
				card_image.texture = ImageTexture.create_from_image(img)
			
	if final_data.has("atk"):
		_add_stat("ATK", final_data["atk"])
	if final_data.has("def"):
		_add_stat("DEF", final_data["def"])
		
	if final_data.has("custom_stats"):
		for stat in final_data["custom_stats"]:
			_add_stat(stat, final_data["custom_stats"][stat])
			
	if final_data.has("tags"):
		for tag in final_data["tags"]:
			_add_tag(tag)
	
	# Enable interaction
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	main_layout.mouse_filter = Control.MOUSE_FILTER_PASS
	visible = true
	is_open = true
	
	# Animate in
	if tween:
		tween.kill()
	tween = create_tween().set_parallel(true)
	
	# Initial states for animation
	main_layout.scale = Vector2(0.9, 0.9)
	main_layout.pivot_offset = main_layout.size / 2.0
	
	tween.tween_property(background, "color:a", 0.8, 0.3)
	tween.tween_property(main_layout, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE)
	tween.tween_property(main_layout, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(close_btn, "modulate:a", 1.0, 0.3).set_delay(0.2)

func _add_stat(key: String, val):
	var key_lbl = Label.new()
	key_lbl.text = key + ":"
	key_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	
	var val_lbl = Label.new()
	val_lbl.text = Global.format_num(val)
	val_lbl.add_theme_font_size_override("font_size", 20)
	
	stats_grid.add_child(key_lbl)
	stats_grid.add_child(val_lbl)

func _add_tag(tag: String):
	var panel = PanelContainer.new()
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.4, 0.8, 0.5)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)
	
	var lbl = Label.new()
	lbl.text = tag
	lbl.add_theme_font_size_override("font_size", 16)
	
	margin.add_child(lbl)
	panel.add_child(margin)
	tags_flow.add_child(panel)

func hide_card():
	if not is_open: return
	is_open = false
	
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if tween:
		tween.kill()
	tween = create_tween().set_parallel(true)
	
	tween.tween_property(background, "color:a", 0.0, 0.3)
	tween.tween_property(main_layout, "modulate:a", 0.0, 0.2)
	tween.tween_property(main_layout, "scale", Vector2(0.95, 0.95), 0.2)
	tween.tween_property(close_btn, "modulate:a", 0.0, 0.2)
	
	tween.chain().tween_callback(func(): visible = false)
