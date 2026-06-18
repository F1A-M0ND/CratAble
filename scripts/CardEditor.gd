extends Control

@onready var card_name = $VBoxContainer/NameInput
@onready var atk_check = $VBoxContainer/StatRow/ATKCheck
@onready var atk_spin = $VBoxContainer/StatRow/ATKSpin
@onready var def_check = $VBoxContainer/StatRow/DEFCheck
@onready var def_spin = $VBoxContainer/StatRow/DEFSpin
@onready var stat_add_btn = $VBoxContainer/StatRow/StatAddBtn
@onready var custom_stats_container = $VBoxContainer/CustomStatsContainer

@onready var tag_add_btn = $VBoxContainer/TagsRow/TagAddBtn
@onready var custom_tags_container = $VBoxContainer/CustomTagsContainer

@onready var preview_image = $VBoxContainer/BottomSection/ExamplePanel/PreviewImage
@onready var preview_label = $VBoxContainer/BottomSection/ExamplePanel/Label

@onready var save_btn = $VBoxContainer/BottomSection/ActionHBox/SaveBtn
@onready var delete_btn = $VBoxContainer/BottomSection/ActionHBox/DeleteBtn

@onready var save_confirm = $SaveConfirmDialog
@onready var overwrite_dialog = $OverwriteDialog
@onready var delete_confirm = $DeleteConfirmDialog
@onready var error_dialog = $ErrorDialog

var file_dialog: FileDialog
var current_image_path: String = ""
var has_unsaved_changes: bool = false
var unsaved_dialog: ConfirmationDialog

@onready var fullscreen_viewer = $FullscreenViewer
@onready var zoom_container = $FullscreenViewer/ZoomContainer
@onready var zoom_image = $FullscreenViewer/ZoomContainer/ZoomImage
@onready var viewer_close_btn = $FullscreenViewer/ViewerCloseBtn

var dragging_zoom: bool = false

func _ready():
	$Header/BackBtn.pressed.connect(_on_back_pressed)
	save_btn.pressed.connect(_on_save_button_pressed)
	delete_btn.pressed.connect(_on_delete_pressed)
	$VBoxContainer/BottomSection/CardPictureBtn.pressed.connect(_on_upload_pressed)
	
	atk_spin.editable = atk_check.button_pressed
	def_spin.editable = def_check.button_pressed
	
	atk_check.toggled.connect(func(toggled_on): atk_spin.editable = toggled_on)
	def_check.toggled.connect(func(toggled_on): def_spin.editable = toggled_on)
	
	stat_add_btn.pressed.connect(func(): _add_custom_stat("", 0))
	tag_add_btn.pressed.connect(func(): _add_custom_tag(""))
	
	file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg ; Supported Images"])
	file_dialog.file_selected.connect(_on_file_selected)
	file_dialog.size = Vector2(600, 400)
	file_dialog.use_native_dialog = true
	add_child(file_dialog)
	
	unsaved_dialog = ConfirmationDialog.new()
	unsaved_dialog.title = "Unsaved Changes"
	unsaved_dialog.dialog_text = "You have unsaved changes. Are you sure you want to go back without saving?"
	unsaved_dialog.confirmed.connect(func(): Global.switch_scene("res://scenes/CardSelector.tscn"))
	add_child(unsaved_dialog)
	
	card_name.text_changed.connect(_mark_unsaved)
	atk_check.toggled.connect(_mark_unsaved)
	atk_spin.value_changed.connect(_mark_unsaved)
	def_check.toggled.connect(_mark_unsaved)
	def_spin.value_changed.connect(_mark_unsaved)
	
	save_confirm.confirmed.connect(_do_save_card)
	overwrite_dialog.confirmed.connect(_do_save_card)
	delete_confirm.confirmed.connect(_do_delete_card)
	
	if not Global.current_card_data.is_empty():
		_load_existing_card()
	else:
		delete_btn.hide()
		
	viewer_close_btn.pressed.connect(hide_fullscreen)
	preview_image.gui_input.connect(_on_preview_image_gui_input)
	zoom_container.gui_input.connect(_on_zoom_container_gui_input)
	fullscreen_viewer.hide()

func _on_preview_image_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if preview_image.texture != null:
			show_fullscreen()

func show_fullscreen():
	zoom_image.texture = preview_image.texture
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

func _mark_unsaved(_discard = null):
	has_unsaved_changes = true

func _reset_unsaved():
	has_unsaved_changes = false

func _load_existing_card():
	var data = Global.current_card_data
	if data.is_empty():
		return
		
	# Normalize stats for both local JSON layout and Supabase structure
	var stats_data = {}
	if data.has("stats") and typeof(data["stats"]) == TYPE_DICTIONARY:
		stats_data = data["stats"]
	else:
		stats_data = data
		
	card_name.text = data.get("name", "")
	
	if stats_data.has("atk"):
		atk_check.button_pressed = true
		atk_spin.value = stats_data["atk"]
	
	if stats_data.has("def"):
		def_check.button_pressed = true
		def_spin.value = stats_data["def"]
	
	var image_src = ""
	if data.has("image_url") and data["image_url"] != "":
		image_src = data["image_url"]
	elif stats_data.has("image_path") and stats_data["image_path"] != "":
		image_src = stats_data["image_path"]
		
	if image_src != "":
		if image_src.begins_with("http"):
			preview_label.text = "Downloading..."
			preview_label.show()
			SupabaseService.get_texture_or_load(image_src, func(tex):
				if tex and is_instance_valid(preview_image):
					preview_image.texture = tex
					preview_label.hide()
					current_image_path = image_src
			)
		else:
			_on_file_selected(image_src)
		
	if stats_data.has("custom_stats"):
		for stat in stats_data["custom_stats"]:
			_add_custom_stat(stat, stats_data["custom_stats"][stat])
			
	if stats_data.has("tags"):
		for tag in stats_data["tags"]:
			_add_custom_tag(tag)
	
	_reset_unsaved()

func _add_custom_stat(stat_name: String, stat_val: int):
	var hb = HBoxContainer.new()
	
	var name_input = LineEdit.new()
	name_input.placeholder_text = "Stat Name"
	name_input.text = stat_name
	name_input.custom_minimum_size = Vector2(100, 0)
	
	var val_spin = SpinBox.new()
	val_spin.value = stat_val
	
	var del_btn = Button.new()
	del_btn.text = "X"
	del_btn.pressed.connect(func():
		_mark_unsaved()
		hb.queue_free()
	)
	
	name_input.text_changed.connect(_mark_unsaved)
	val_spin.value_changed.connect(_mark_unsaved)
	_mark_unsaved()
	
	hb.add_child(name_input)
	hb.add_child(val_spin)
	hb.add_child(del_btn)
	custom_stats_container.add_child(hb)

func _add_custom_tag(tag_str: String):
	var hb = HBoxContainer.new()
	
	var tag_input = LineEdit.new()
	tag_input.placeholder_text = "Tag"
	tag_input.text = tag_str
	tag_input.custom_minimum_size = Vector2(80, 0)
	
	var del_btn = Button.new()
	del_btn.text = "X"
	del_btn.pressed.connect(func(): 
		_mark_unsaved()
		hb.queue_free()
	)
	
	tag_input.text_changed.connect(_mark_unsaved)
	_mark_unsaved()
	
	hb.add_child(tag_input)
	hb.add_child(del_btn)
	custom_tags_container.add_child(hb)

func _on_upload_pressed():
	file_dialog.popup_centered()

func _on_file_selected(path: String):
	var image = Image.new()
	var err = image.load(path)
	if err == OK:
		var tex = ImageTexture.create_from_image(image)
		preview_image.texture = tex
		preview_label.hide()
		current_image_path = path
		_mark_unsaved()
	else:
		print("Failed to load image at: ", path)

func _on_save_button_pressed():
	if current_image_path == "":
		error_dialog.dialog_text = "Cannot save card: Image is missing!"
		error_dialog.popup_centered()
		return
	save_confirm.popup_centered()

func _do_save_card():
	save_btn.disabled = true
	save_btn.text = "Saving..."
	
	var stats = {
		"custom_stats": {},
		"tags": []
	}
	
	if preview_image.texture != null:
		var size = preview_image.texture.get_size()
		stats["image_size"] = {"x": size.x, "y": size.y}
	else:
		stats["image_size"] = {"x": 0, "y": 0}
		
	if atk_check.button_pressed:
		stats["atk"] = atk_spin.value
	if def_check.button_pressed:
		stats["def"] = def_spin.value
		
	for child in custom_stats_container.get_children():
		if child is HBoxContainer:
			var s_name = child.get_child(0).text
			var s_val = child.get_child(1).value
			if s_name != "":
				stats.custom_stats[s_name] = s_val
				
	for child in custom_tags_container.get_children():
		if child is HBoxContainer:
			var tag_name = child.get_child(0).text
			if tag_name != "":
				stats.tags.append(tag_name)
				
	var card_name_str = card_name.text.strip_edges()
	if card_name_str == "":
		card_name_str = "UntitledCard"
		
	var on_db_save_complete = func(status_code, response_data):
		save_btn.disabled = false
		save_btn.text = "Save"
		if status_code == 200 or status_code == 201:
			print("Card saved to Supabase successfully!")
			_reset_unsaved()
			Global.switch_scene("res://scenes/CardSelector.tscn")
		else:
			print("Failed to save card: ", status_code, " ", response_data)
			error_dialog.dialog_text = "Failed to save card to database. (Status: " + str(status_code) + ")"
			error_dialog.popup_centered()

	if current_image_path.begins_with("http"):
		_save_card_data_to_db(card_name_str, current_image_path, stats, on_db_save_complete)
	else:
		if not FileAccess.file_exists(current_image_path):
			save_btn.disabled = false
			save_btn.text = "Save"
			error_dialog.dialog_text = "Local image file not found: " + current_image_path
			error_dialog.popup_centered()
			return
			
		var file_bytes = FileAccess.get_file_as_bytes(current_image_path)
		if file_bytes.size() == 0:
			save_btn.disabled = false
			save_btn.text = "Save"
			error_dialog.dialog_text = "Failed to read image file bytes."
			error_dialog.popup_centered()
			return
			
		SupabaseService.upload_card_image(current_image_path.get_file(), file_bytes, func(success, public_url):
			if success:
				_save_card_data_to_db(card_name_str, public_url, stats, on_db_save_complete)
			else:
				save_btn.disabled = false
				save_btn.text = "Save"
				error_dialog.dialog_text = "Failed to upload card image to storage."
				error_dialog.popup_centered()
		)

func _save_card_data_to_db(c_name: String, img_url: String, stats: Dictionary, callback: Callable):
	var is_edit = not Global.current_card_data.is_empty()
	if is_edit:
		var uuid = Global.current_card_data.get("id", "")
		SupabaseService.update_card(uuid, c_name, img_url, "custom", stats, callback)
	else:
		SupabaseService.insert_card(c_name, img_url, "custom", stats, callback)

func _on_delete_pressed():
	print("DEBUG: Prompting delete confirmation.")
	delete_confirm.popup_centered()

func _do_delete_card():
	if not Global.current_card_data.is_empty():
		var uuid = Global.current_card_data.get("id", "")
		delete_btn.disabled = true
		SupabaseService.delete_card(uuid, func(status, data):
			delete_btn.disabled = false
			if status == 200 or status == 204:
				print("Deleted card from Supabase successfully")
				Global.current_card_data = {}
				Global.switch_scene("res://scenes/CardSelector.tscn")
			else:
				error_dialog.dialog_text = "Failed to delete card from database."
				error_dialog.popup_centered()
		)

func _on_back_pressed():
	if has_unsaved_changes:
		unsaved_dialog.popup_centered()
	else:
		Global.switch_scene("res://scenes/CardSelector.tscn")
