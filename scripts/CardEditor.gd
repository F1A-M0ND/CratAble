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
	
	if Global.current_card_path != "":
		_load_existing_card()
	else:
		delete_btn.hide()

func _mark_unsaved(_discard = null):
	has_unsaved_changes = true

func _reset_unsaved():
	has_unsaved_changes = false

func _load_existing_card():
	if FileAccess.file_exists(Global.current_card_path):
		var str = FileAccess.get_file_as_string(Global.current_card_path)
		var json = JSON.new()
		if json.parse(str) == OK:
			var data = json.get_data()
			card_name.text = data.get("name", "")
			
			if data.has("atk"):
				atk_check.button_pressed = true
				atk_spin.value = data["atk"]
			
			if data.has("def"):
				def_check.button_pressed = true
				def_spin.value = data["def"]
			
			if data.has("image_path") and data["image_path"] != "":
				_on_file_selected(data["image_path"])
				
			if data.has("custom_stats"):
				for stat in data["custom_stats"]:
					_add_custom_stat(stat, data["custom_stats"][stat])
					
			if data.has("tags"):
				for tag in data["tags"]:
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
		print("DEBUG: User attempted to save without an image. Blocked.")
		return
		
	var safe_name = card_name.text.strip_edges()
	if safe_name == "":
		safe_name = "UntitledCard"
	safe_name = safe_name.replace(" ", "_").replace("/", "-").replace("\\", "-").replace(":", "-")
	
	var save_dir = "res://cards"
	var potential_path = save_dir + "/" + safe_name + ".json"
	
	if FileAccess.file_exists(potential_path) and Global.current_card_path != potential_path:
		print("DEBUG: Card overwrite conflict detected.")
		overwrite_dialog.popup_centered()
	else:
		print("DEBUG: Prompting standard save confirmation.")
		save_confirm.popup_centered()

func _do_save_card():
	var new_card = {
		"name": card_name.text,
		"image_path": current_image_path,
		"custom_stats": {},
		"tags": []
	}
	
	if preview_image.texture != null:
		var size = preview_image.texture.get_size()
		new_card["image_size"] = {"x": size.x, "y": size.y}
	else:
		new_card["image_size"] = {"x": 0, "y": 0}
	
	if atk_check.button_pressed:
		new_card["atk"] = atk_spin.value
		
	if def_check.button_pressed:
		new_card["def"] = def_spin.value
		
	for child in custom_stats_container.get_children():
		if child is HBoxContainer:
			var s_name = child.get_child(0).text
			var s_val = child.get_child(1).value
			if s_name != "":
				new_card.custom_stats[s_name] = s_val
				
	for child in custom_tags_container.get_children():
		if child is HBoxContainer:
			var tag_name = child.get_child(0).text
			if tag_name != "":
				new_card.tags.append(tag_name)
				
	var save_dir = "res://cards"
	if not DirAccess.dir_exists_absolute(save_dir):
		DirAccess.make_dir_absolute(save_dir)
		
	var safe_name = new_card.name.strip_edges()
	if safe_name == "":
		safe_name = "UntitledCard"
	safe_name = safe_name.replace(" ", "_").replace("/", "-").replace("\\", "-").replace(":", "-")
	
	var file_path = save_dir + "/" + safe_name + ".json"
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(new_card, "\t")
		file.store_string(json_string)
		file.close()
		Global.current_card_path = file_path
		
		# Optional: update library footprint in Global
		print("DEBUG: Card saved to JSON successfully (", file_path, ")")
		_reset_unsaved()
	else:
		print("DEBUG ERROR: Error saving JSON to ", file_path)

func _on_delete_pressed():
	print("DEBUG: Prompting delete confirmation.")
	delete_confirm.popup_centered()

func _do_delete_card():
	if Global.current_card_path != "" and FileAccess.file_exists(Global.current_card_path):
		var err = DirAccess.remove_absolute(Global.current_card_path)
		if err == OK:
			print("DEBUG: Deleted card JSON successfully (", Global.current_card_path, ")")
			Global.current_card_path = ""
			Global.switch_scene("res://scenes/CardSelector.tscn")
		else:
			print("DEBUG ERROR: Failed to delete card JSON (", Global.current_card_path, ")")

func _on_back_pressed():
	if has_unsaved_changes:
		unsaved_dialog.popup_centered()
	else:
		Global.switch_scene("res://scenes/CardSelector.tscn")
