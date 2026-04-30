extends Control

@onready var asset_list = $HBoxContainer/LeftSide/AssetContainer/ItemList
@onready var tabletop_view = $HBoxContainer/RightSide/TabletopPreview # ใช้ SubViewport หรือ Panel

var import_menu: PopupMenu
var asset_selector: ConfirmationDialog
var asset_grid: GridContainer

var current_target_zone: Control = null

var zone_settings_dialog: ConfirmationDialog
var opt_zone_type: OptionButton
var opt_purpose: OptionButton
var opt_face: OptionButton
var opt_allow_move: CheckBox
var opt_has_max_cards: CheckBox
var opt_max_cards_val: SpinBox
var current_editing_zone: Control = null

var field_canvas: Control
var field_zoom: float = 1.0
var is_panning: bool = false

var field_settings_dialog: ConfirmationDialog
var field_name_input: LineEdit
var field_size_x: SpinBox
var field_size_y: SpinBox
var field_rot: SpinBox
var field_can_move_cards: CheckBox
var field_can_play_cards: CheckBox

var current_editing_field: Control = null

var counter_settings_dialog: ConfirmationDialog
var opt_counter_orientation: OptionButton
var opt_counter_rotation: OptionButton
var counter_name_input: LineEdit
var opt_counter_name_pos: OptionButton
var counter_default_val: SpinBox
var counter_name_auto_scale: CheckBox
var counter_name_size: SpinBox
var current_editing_counter: Control = null

func _ready():
	$Header/BackBtn.pressed.connect(_on_back_pressed)
	$HBoxContainer/LeftSide/SaveFieldBtn.pressed.connect(_on_save_field_pressed)
	
	# Prototype features
	$HBoxContainer/LeftSide/AddZoneBtn.pressed.connect(func():
		_spawn_zone("Card Zone")
	)
	
	if $HBoxContainer/LeftSide.has_node("AddFieldZoneBtn"):
		$HBoxContainer/LeftSide/AddFieldZoneBtn.pressed.connect(func():
			_spawn_sub_field()
		)
	
	$HBoxContainer/LeftSide/AddDiceBtn.pressed.connect(_on_add_dice_pressed)
	$HBoxContainer/LeftSide/AddCounterBtn.pressed.connect(_on_add_counter_pressed)
	
	field_canvas = ColorRect.new()
	field_canvas.color = Color(0.15, 0.3, 0.2, 0.5)
	field_canvas.size = Vector2(1500, 1000)
	field_canvas.custom_minimum_size = Vector2(1500, 1000)
	field_canvas.position = Vector2(50, 50)
	field_canvas.pivot_offset = field_canvas.size / 2.0
	field_canvas.set_meta("field_name", "Main Field")
	field_canvas.set_meta("field_perms", {"move": true, "play": true})
	
	field_canvas.resized.connect(func(): field_canvas.pivot_offset = field_canvas.size / 2.0)
	
	var border = ReferenceRect.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.border_color = Color(1.0, 1.0, 1.0, 0.5)
	border.border_width = 4.0
	border.editor_only = false
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	field_canvas.add_child(border)
	
	var f_settings_btn = Button.new()
	f_settings_btn.text = "⚙ Field"
	f_settings_btn.custom_minimum_size = Vector2(60, 30)
	f_settings_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	f_settings_btn.offset_left = 10
	f_settings_btn.offset_top = 10
	f_settings_btn.pressed.connect(func(): _open_field_settings(field_canvas))
	field_canvas.add_child(f_settings_btn)
	
	_add_resize_handle(field_canvas, Vector2(500, 500))
	_add_rotate_handle(field_canvas)
	
	tabletop_view.add_child(field_canvas)
	
	field_zoom = 0.5
	field_canvas.scale = Vector2(field_zoom, field_zoom)
	
	# Keep import_menu for future use, but don't connect it to ImportAssetBtn yet
	import_menu = PopupMenu.new()
	import_menu.add_item("Import Card", 0)
	import_menu.add_item("Import Deck", 1)
	import_menu.add_item("Import Other (Image)", 2)
	import_menu.id_pressed.connect(_on_import_menu_id_pressed)
	add_child(import_menu)
	
	$HBoxContainer/LeftSide/ImportAssetBtn.pressed.connect(_show_other_import_dialog)
	
	_init_asset_selector()
	_init_field_settings()
	_init_zone_settings()
	_init_counter_settings()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				if tabletop_view.get_global_rect().has_point(event.global_position):
					is_panning = true
			else:
				is_panning = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			if tabletop_view.get_global_rect().has_point(event.global_position):
				_zoom_canvas(1.1, tabletop_view.get_local_mouse_position())
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			if tabletop_view.get_global_rect().has_point(event.global_position):
				_zoom_canvas(1.0 / 1.1, tabletop_view.get_local_mouse_position())
	elif event is InputEventMouseMotion and is_panning:
		field_canvas.position += event.relative

func _process(delta: float) -> void:
	# ป้องกันการเลื่อนจอเวลาพิมพ์ข้อความ
	var focus_owner = get_viewport().gui_get_focus_owner()
	if focus_owner is LineEdit or focus_owner is TextEdit:
		return
		
	var move_vec = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move_vec.y += 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move_vec.y -= 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_vec.x += 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_vec.x -= 1
		
	if move_vec != Vector2.ZERO:
		var speed = 600.0 / field_zoom # ชดเชยความเร็วตามระยะซูม
		field_canvas.position += move_vec.normalized() * speed * delta

func _zoom_canvas(factor: float, mouse_pos: Vector2):
	var old_zoom = field_zoom
	field_zoom = clamp(field_zoom * factor, 0.2, 5.0)
	var ratio = field_zoom / old_zoom
	
	var diff = field_canvas.position - mouse_pos
	field_canvas.position = mouse_pos + diff * ratio
	field_canvas.scale = Vector2(field_zoom, field_zoom)

func _init_zone_settings():
	zone_settings_dialog = ConfirmationDialog.new()
	zone_settings_dialog.title = "Zone Settings"
	
	var vbox = VBoxContainer.new()
	
	var hbox_type = HBoxContainer.new()
	var lbl_type = Label.new()
	lbl_type.text = "Zone Type:"
	hbox_type.add_child(lbl_type)
	opt_zone_type = OptionButton.new()
	opt_zone_type.add_item("Card Zone")
	opt_zone_type.add_item("Deck Zone")
	opt_zone_type.add_item("Field Zone")
	hbox_type.add_child(opt_zone_type)
	vbox.add_child(hbox_type)
	
	var hbox_purpose = HBoxContainer.new()
	var lbl_purpose = Label.new()
	lbl_purpose.text = "Purpose:"
	hbox_purpose.add_child(lbl_purpose)
	opt_purpose = OptionButton.new()
	opt_purpose.add_item("Place")
	opt_purpose.add_item("Select")
	hbox_purpose.add_child(opt_purpose)
	vbox.add_child(hbox_purpose)
	
	var hbox_face = HBoxContainer.new()
	var lbl_face = Label.new()
	lbl_face.text = "State:"
	hbox_face.add_child(lbl_face)
	opt_face = OptionButton.new()
	opt_face.add_item("Face Up")
	opt_face.add_item("Face Down")
	opt_face.add_item("Free")
	hbox_face.add_child(opt_face)
	vbox.add_child(hbox_face)
	
	var hbox_move = HBoxContainer.new()
	var lbl_move = Label.new()
	lbl_move.text = "Permission:"
	hbox_move.add_child(lbl_move)
	opt_allow_move = CheckBox.new()
	opt_allow_move.text = "Allow Move"
	opt_allow_move.button_pressed = true
	hbox_move.add_child(opt_allow_move)
	vbox.add_child(hbox_move)
	
	var hbox_max = HBoxContainer.new()
	var lbl_max = Label.new()
	lbl_max.text = "Max Cards:"
	hbox_max.add_child(lbl_max)
	opt_has_max_cards = CheckBox.new()
	opt_has_max_cards.text = "Limit"
	opt_has_max_cards.button_pressed = false
	hbox_max.add_child(opt_has_max_cards)
	opt_max_cards_val = SpinBox.new()
	opt_max_cards_val.min_value = 1
	opt_max_cards_val.max_value = 999
	opt_max_cards_val.value = 1
	opt_max_cards_val.editable = false
	opt_has_max_cards.toggled.connect(func(pressed): opt_max_cards_val.editable = pressed)
	hbox_max.add_child(opt_max_cards_val)
	vbox.add_child(hbox_max)
	
	zone_settings_dialog.add_child(vbox)
	zone_settings_dialog.confirmed.connect(_on_zone_settings_confirmed)
	add_child(zone_settings_dialog)

func _open_zone_settings(zone: Control):
	current_editing_zone = zone
	var z_type = zone.get_meta("zone_type")
	if z_type == "Card Zone":
		opt_zone_type.selected = 0
	elif z_type == "Deck Zone":
		opt_zone_type.selected = 1
	else:
		opt_zone_type.selected = 2
	var settings = zone.get_meta("zone_settings")
	opt_purpose.selected = settings["purpose"]
	opt_face.selected = settings["face"]
	opt_allow_move.button_pressed = settings.get("allow_move", true)
	var has_max = settings.get("has_max_cards", false)
	opt_has_max_cards.button_pressed = has_max
	opt_max_cards_val.value = settings.get("max_cards", 1)
	opt_max_cards_val.editable = has_max
	zone_settings_dialog.popup_centered()

func _on_zone_settings_confirmed():
	if is_instance_valid(current_editing_zone):
		var new_type = "Card Zone"
		if opt_zone_type.selected == 1: new_type = "Deck Zone"
		elif opt_zone_type.selected == 2: new_type = "Field Zone"
		
		current_editing_zone.set_meta("zone_type", new_type)
		if new_type == "Card Zone":
			current_editing_zone.color = Color(0.2, 0.6, 1.0, 0.3)
		elif new_type == "Deck Zone":
			current_editing_zone.color = Color(0.8, 0.4, 0.1, 0.3)
		else:
			current_editing_zone.color = Color(0.2, 0.8, 0.3, 0.3)
			
		var settings = {
			"purpose": opt_purpose.selected,
			"face": opt_face.selected,
			"allow_move": opt_allow_move.button_pressed,
			"has_max_cards": opt_has_max_cards.button_pressed,
			"max_cards": int(opt_max_cards_val.value)
		}
		current_editing_zone.set_meta("zone_settings", settings)
		
		var lbl = current_editing_zone.get_node_or_null("VBoxContainer/Label")
		if lbl:
			var p_str = "Place" if settings["purpose"] == 0 else "Select"
			var f_str = "Up" if settings["face"] == 0 else ("Down" if settings["face"] == 1 else "Free")
			var m_str = "Move: Yes" if settings.get("allow_move", true) else "Move: No"
			var limit_str = "Max: " + str(settings.get("max_cards", 1)) if settings.get("has_max_cards", false) else "Max: ∞"
			lbl.text = new_type + "\n(" + p_str + " | " + f_str + ")\n" + m_str + " | " + limit_str

func _init_counter_settings():
	counter_settings_dialog = ConfirmationDialog.new()
	counter_settings_dialog.title = "Counter Settings"
	
	var vbox = VBoxContainer.new()
	
	var hbox_name = HBoxContainer.new()
	var lbl_name = Label.new()
	lbl_name.text = "Name:"
	hbox_name.add_child(lbl_name)
	counter_name_input = LineEdit.new()
	counter_name_input.custom_minimum_size = Vector2(100, 0)
	hbox_name.add_child(counter_name_input)
	vbox.add_child(hbox_name)
	
	var hbox_pos = HBoxContainer.new()
	var lbl_pos = Label.new()
	lbl_pos.text = "Name Pos:"
	hbox_pos.add_child(lbl_pos)
	opt_counter_name_pos = OptionButton.new()
	opt_counter_name_pos.add_item("Hidden")
	opt_counter_name_pos.add_item("Top")
	opt_counter_name_pos.add_item("Bottom")
	opt_counter_name_pos.add_item("Left")
	opt_counter_name_pos.add_item("Right")
	opt_counter_name_pos.add_item("Center")
	hbox_pos.add_child(opt_counter_name_pos)
	vbox.add_child(hbox_pos)
	
	var hbox_val = HBoxContainer.new()
	var lbl_val = Label.new()
	lbl_val.text = "Default Value:"
	hbox_val.add_child(lbl_val)
	counter_default_val = SpinBox.new()
	counter_default_val.min_value = -9999
	counter_default_val.max_value = 9999
	counter_default_val.rounded = true
	hbox_val.add_child(counter_default_val)
	vbox.add_child(hbox_val)
	
	var hbox_scale = HBoxContainer.new()
	var lbl_scale = Label.new()
	lbl_scale.text = "Name Size:"
	hbox_scale.add_child(lbl_scale)
	
	counter_name_auto_scale = CheckBox.new()
	counter_name_auto_scale.text = "Auto"
	counter_name_auto_scale.button_pressed = true
	hbox_scale.add_child(counter_name_auto_scale)
	
	counter_name_size = SpinBox.new()
	counter_name_size.min_value = 8
	counter_name_size.max_value = 128
	counter_name_size.value = 14
	counter_name_size.editable = false
	counter_name_auto_scale.toggled.connect(func(pressed): counter_name_size.editable = not pressed)
	hbox_scale.add_child(counter_name_size)
	
	vbox.add_child(hbox_scale)
	
	var hbox_ori = HBoxContainer.new()
	var lbl_ori = Label.new()
	lbl_ori.text = "Orientation:"
	hbox_ori.add_child(lbl_ori)
	opt_counter_orientation = OptionButton.new()
	opt_counter_orientation.add_item("Horizontal")
	opt_counter_orientation.add_item("Vertical")
	hbox_ori.add_child(opt_counter_orientation)
	vbox.add_child(hbox_ori)
	
	var hbox_rot = HBoxContainer.new()
	var lbl_rot = Label.new()
	lbl_rot.text = "Rotation:"
	hbox_rot.add_child(lbl_rot)
	opt_counter_rotation = OptionButton.new()
	opt_counter_rotation.add_item("0°")
	opt_counter_rotation.add_item("90°")
	opt_counter_rotation.add_item("180°")
	opt_counter_rotation.add_item("270°")
	hbox_rot.add_child(opt_counter_rotation)
	vbox.add_child(hbox_rot)
	
	counter_settings_dialog.add_child(vbox)
	counter_settings_dialog.confirmed.connect(_on_counter_settings_confirmed)
	add_child(counter_settings_dialog)

func _open_counter_settings(counter: Control):
	current_editing_counter = counter
	
	counter_name_input.text = counter.get("counter_name") if "counter_name" in counter else ""
	opt_counter_name_pos.selected = counter.get("name_position") if "name_position" in counter else 0
	counter_default_val.value = counter.get("default_value") if "default_value" in counter else 0
	
	counter_name_auto_scale.button_pressed = counter.get("name_auto_scale") if "name_auto_scale" in counter else true
	counter_name_size.value = counter.get("name_custom_size") if "name_custom_size" in counter else 14
	counter_name_size.editable = not counter_name_auto_scale.button_pressed
	
	opt_counter_orientation.selected = 1 if counter.is_vertical else 0
	
	var rot = int(counter.rotation_degrees) % 360
	if rot < 0: rot += 360
	var idx = 0
	if rot == 90: idx = 1
	elif rot == 180: idx = 2
	elif rot == 270: idx = 3
	opt_counter_rotation.selected = idx
	
	counter_settings_dialog.popup_centered()

func _on_counter_settings_confirmed():
	if is_instance_valid(current_editing_counter):
		var is_vert = (opt_counter_orientation.selected == 1)
		current_editing_counter.set_orientation(is_vert)
		var rot = opt_counter_rotation.selected * 90.0
		current_editing_counter.rotation_degrees = rot
		
		if current_editing_counter.has_method("set_counter_properties"):
			current_editing_counter.set_counter_properties(
				counter_name_input.text,
				opt_counter_name_pos.selected,
				int(counter_default_val.value),
				counter_name_auto_scale.button_pressed,
				int(counter_name_size.value)
			)

func _on_import_menu_id_pressed(id: int):
	if id == 0:
		_show_asset_selector("card")
	elif id == 1:
		_show_asset_selector("deck")
	elif id == 2:
		_show_other_import_dialog()

func _init_asset_selector():
	asset_selector = ConfirmationDialog.new()
	asset_selector.min_size = Vector2i(600, 400)
	
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.custom_minimum_size = Vector2(580, 350)
	
	asset_grid = GridContainer.new()
	asset_grid.columns = 5
	scroll.add_child(asset_grid)
	
	asset_selector.add_child(scroll)
	add_child(asset_selector)
	
	var ok_btn = asset_selector.get_ok_button()
	if ok_btn: ok_btn.hide()
	var cancel_btn = asset_selector.get_cancel_button()
	if cancel_btn: cancel_btn.text = "Close"

func _show_asset_selector(type: String):
	for child in asset_grid.get_children():
		child.queue_free()
		
	var dir_path = "res://cards" if type == "card" else "res://deck"
	asset_selector.title = "Select " + type.capitalize()
	
	if DirAccess.dir_exists_absolute(dir_path):
		var dir = DirAccess.open(dir_path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir() and file_name.ends_with(".json"):
					var path = dir_path + "/" + file_name
					_create_selector_button(path, type)
				file_name = dir.get_next()
				
	asset_selector.popup_centered()

func _create_selector_button(path: String, type: String):
	var data = {}
	var str = FileAccess.get_file_as_string(path)
	var json = JSON.new()
	if json.parse(str) == OK:
		var parsed = json.get_data()
		if typeof(parsed) == TYPE_DICTIONARY:
			data = parsed
		
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(100, 140)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var tex = TextureRect.new()
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var lbl = Label.new()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	if type == "card":
		if data.has("image_path") and data["image_path"] != "":
			var img = Image.new()
			if img.load(data["image_path"]) == OK:
				tex.texture = ImageTexture.create_from_image(img)
		lbl.text = data.get("name", "Unknown")
	else:
		if data.has("groups") and data["groups"].size() > 0:
			var g = data["groups"][0]
			if g.has("cards") and g["cards"].keys().size() > 0:
				var first_card_path = g["cards"].keys()[0]
				if FileAccess.file_exists(first_card_path):
					var c_str = FileAccess.get_file_as_string(first_card_path)
					var c_json = JSON.new()
					if c_json.parse(c_str) == OK:
						var c_data = c_json.get_data()
						if typeof(c_data) == TYPE_DICTIONARY and c_data.has("image_path") and c_data["image_path"] != "":
							var ipath = c_data["image_path"]
							if ipath.begins_with("res://"):
								if ResourceLoader.exists(ipath): tex.texture = load(ipath)
							else:
								var img = Image.new()
								if img.load(ipath) == OK:
									tex.texture = ImageTexture.create_from_image(img)
		lbl.text = data.get("deck_name", "Deck")

	vbox.add_child(tex)
	vbox.add_child(lbl)
	btn.add_child(vbox)
	btn.pressed.connect(func():
		asset_selector.hide()
		var spawned_obj = null
		if type == "card":
			spawned_obj = spawn_card_object(data)
		else:
			spawned_obj = spawn_deck_object(data)
			
		if current_target_zone and is_instance_valid(current_target_zone) and spawned_obj:
			spawned_obj.position = current_target_zone.position
			current_target_zone.queue_free()
			current_target_zone = null
	)
	asset_grid.add_child(btn)

func _show_other_import_dialog():
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Image Files"])
	file_dialog.use_native_dialog = true
	
	file_dialog.file_selected.connect(_spawn_other_object)
	file_dialog.visibility_changed.connect(func():
		if not file_dialog.visible:
			file_dialog.queue_free()
	)
	
	add_child(file_dialog)
	file_dialog.popup_centered(Vector2(600, 400))

func _spawn_other_object(image_path: String):
	var root_obj = TextureRect.new()
	
	var tex = null
	if image_path.begins_with("res://"):
		if ResourceLoader.exists(image_path):
			tex = load(image_path)
	else:
		var img = Image.new()
		var err = img.load(image_path)
		if err == OK:
			tex = ImageTexture.create_from_image(img)
	
	if tex:
		root_obj.texture = tex
		root_obj.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		root_obj.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		var aspect = float(tex.get_width()) / float(tex.get_height())
		var w = 150.0
		var h = 150.0 / aspect
		if h > 200:
			h = 200.0
			w = 200.0 * aspect
			
		root_obj.custom_minimum_size = Vector2(w, h)
		root_obj.size = Vector2(w, h)
		root_obj.position = Vector2(200, 200)
		
		root_obj.set_script(load("res://scripts/DraggableControl.gd"))
		_add_delete_button(root_obj)
		tabletop_view.add_child(root_obj)

func spawn_deck_object(deck_data: Dictionary):
	var root_obj = Control.new()
	root_obj.custom_minimum_size = Vector2(150, 210)
	root_obj.size = Vector2(150, 210)
	root_obj.position = Vector2(200, 200)
	
	var front_tex = null
	if deck_data.has("groups") and deck_data["groups"].size() > 0:
		var g = deck_data["groups"][0]
		if g.has("cards") and g["cards"].keys().size() > 0:
			var first_card_path = g["cards"].keys()[0]
			if FileAccess.file_exists(first_card_path):
				var c_str = FileAccess.get_file_as_string(first_card_path)
				var c_json = JSON.new()
				if c_json.parse(c_str) == OK:
					var c_data = c_json.get_data()
					if typeof(c_data) == TYPE_DICTIONARY and c_data.has("image_path") and c_data["image_path"] != "":
						var ipath = c_data["image_path"]
						if ipath.begins_with("res://"):
							if ResourceLoader.exists(ipath): front_tex = load(ipath)
						else:
							var img = Image.new()
							if img.load(ipath) == OK:
								front_tex = ImageTexture.create_from_image(img)
	
	var bg = Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.2, 0.1, 1.0)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.8, 0.7, 0.5, 1.0)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	bg.add_theme_stylebox_override("panel", style)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_obj.add_child(bg)
	
	if front_tex:
		var tex_rect = TextureRect.new()
		tex_rect.texture = front_tex
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		tex_rect.offset_left = 4
		tex_rect.offset_top = 4
		tex_rect.offset_right = -4
		tex_rect.offset_bottom = -4
		root_obj.add_child(tex_rect)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var text_panel = PanelContainer.new()
	var text_style = StyleBoxFlat.new()
	text_style.bg_color = Color(0, 0, 0, 0.7)
	text_panel.add_theme_stylebox_override("panel", text_style)
	vbox.add_child(text_panel)
	
	var inner_vbox = VBoxContainer.new()
	text_panel.add_child(inner_vbox)
	
	var lbl = Label.new()
	lbl.text = deck_data.get("deck_name", "Deck")
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	
	var total_cards = 0
	if deck_data.has("groups"):
		for g in deck_data["groups"]:
			for p in g.get("cards", {}):
				total_cards += int(g["cards"][p])
				
	var count_lbl = Label.new()
	count_lbl.text = str(total_cards) + " Cards"
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	
	inner_vbox.add_child(lbl)
	inner_vbox.add_child(count_lbl)
	root_obj.add_child(vbox)
	
	root_obj.set_script(load("res://scripts/DraggableControl.gd"))
	_add_delete_button(root_obj)
	field_canvas.add_child(root_obj)
	return root_obj

func spawn_card_object(card_data: Dictionary) -> Control:
	var root_obj = TextureRect.new()
	
	var has_image = false
	if card_data.has("image_path") and card_data["image_path"] != "":
		var img_path = card_data["image_path"]
		var tex = null
		if img_path.begins_with("res://"):
			if ResourceLoader.exists(img_path):
				tex = load(img_path)
		else:
			var img = Image.new()
			if img.load(img_path) == OK:
				tex = ImageTexture.create_from_image(img)
		
		if tex:
			root_obj.texture = tex
			has_image = true
			
			root_obj.custom_minimum_size = Vector2(150, 210)
			root_obj.size = Vector2(150, 210)
			
	root_obj.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	root_obj.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	if not has_image:
		var bg = ColorRect.new()
		bg.color = Color(0.2, 0.2, 0.2, 0.8)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.show_behind_parent = true
		root_obj.add_child(bg)
		
		root_obj.custom_minimum_size = Vector2(150, 210)
		root_obj.size = Vector2(150, 210)
		
	var name_lbl = Label.new()
	name_lbl.text = card_data.get("name", "Unknown Card")
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	name_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	
	var lbl_bg = ColorRect.new()
	lbl_bg.color = Color(0, 0, 0, 0.6)
	lbl_bg.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	lbl_bg.custom_minimum_size = Vector2(0, 30)
	lbl_bg.position.y = root_obj.size.y - 30
	root_obj.add_child(lbl_bg)
	root_obj.add_child(name_lbl)
	
	root_obj.position = Vector2(200, 200)
	root_obj.set_script(load("res://scripts/DraggableControl.gd"))
	_add_delete_button(root_obj)
	field_canvas.add_child(root_obj)
	return root_obj

func _add_delete_button(target_node: Control):
	var delete_btn = Button.new()
	delete_btn.text = "X"
	delete_btn.custom_minimum_size = Vector2(24, 24)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.8, 0.2, 0.2, 0.9)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	delete_btn.add_theme_stylebox_override("normal", style)
	
	var hover_style = style.duplicate()
	hover_style.bg_color = Color(1.0, 0.4, 0.4, 1.0)
	delete_btn.add_theme_stylebox_override("hover", hover_style)
	
	delete_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	delete_btn.offset_left = -12
	delete_btn.offset_top = -12
	delete_btn.offset_right = 12
	delete_btn.offset_bottom = 12
	
	delete_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	delete_btn.pressed.connect(func(): target_node.queue_free())
	target_node.add_child(delete_btn)

func _add_resize_handle(target_node: Control, min_size: Vector2):
	var handle = ColorRect.new()
	handle.color = Color(1, 1, 1, 0.5)
	handle.custom_minimum_size = Vector2(16, 16)
	handle.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	handle.offset_left = -16
	handle.offset_top = -16
	handle.offset_right = 0
	handle.offset_bottom = 0
	handle.mouse_filter = Control.MOUSE_FILTER_STOP
	handle.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	
	target_node.add_child(handle)
	
	var state = {"resizing": false}
	handle.gui_input.connect(func(event):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					state["resizing"] = true
					handle.accept_event()
				else:
					state["resizing"] = false
		elif event is InputEventMouseMotion and state["resizing"]:
			var local_mouse_pos = target_node.get_local_mouse_position()
			var new_size = local_mouse_pos
			new_size.x = max(new_size.x, min_size.x)
			new_size.y = max(new_size.y, min_size.y)
			target_node.size = new_size
			target_node.custom_minimum_size = new_size
			handle.accept_event()
	)

func _add_rotate_handle(target_node: Control):
	var handle = ColorRect.new()
	handle.color = Color(0.2, 0.8, 0.2, 0.6)
	handle.custom_minimum_size = Vector2(16, 16)
	handle.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	handle.offset_left = 0
	handle.offset_top = -16
	handle.offset_right = 16
	handle.offset_bottom = 0
	handle.mouse_filter = Control.MOUSE_FILTER_STOP
	handle.mouse_default_cursor_shape = Control.CURSOR_CROSS
	
	target_node.add_child(handle)
	
	var state = {
		"rotating": false, 
		"start_angle": 0.0, 
		"prev_mouse_angle": 0.0,
		"accumulated_angle": 0.0,
		"locked_angles": [], 
		"current_snap": null
	}
	handle.gui_input.connect(func(event):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					state["rotating"] = true
					state["start_angle"] = target_node.rotation
					state["accumulated_angle"] = 0.0
					var center = target_node.get_global_transform() * target_node.pivot_offset
					state["prev_mouse_angle"] = center.angle_to_point(event.global_position)
					
					state["locked_angles"] = []
					state["current_snap"] = null
					
					# ป้องกันไม่ให้ล็อคกับมุมที่เป็นอยู่แต่แรก
					var start_deg = fmod(rad_to_deg(state["start_angle"]), 360.0)
					if start_deg < 0: start_deg += 360.0
					
					var closest_start_snap = round(start_deg / 90.0) * 90.0
					if abs(start_deg - closest_start_snap) < 0.1:
						var lock_val = fmod(closest_start_snap, 360.0)
						if lock_val >= 359.9: lock_val = 0.0
						state["locked_angles"].append(lock_val)
						
					handle.accept_event()
				else:
					state["rotating"] = false
					handle.color = Color(0.2, 0.8, 0.2, 0.6) # Reset color
		elif event is InputEventMouseMotion and state["rotating"]:
			var center = target_node.get_global_transform() * target_node.pivot_offset
			var current_mouse_angle = center.angle_to_point(event.global_position)
			var diff = angle_difference(state["prev_mouse_angle"], current_mouse_angle)
			state["prev_mouse_angle"] = current_mouse_angle
			state["accumulated_angle"] += diff
			
			var raw_rot = state["start_angle"] + state["accumulated_angle"]
			var new_rot = raw_rot
			var is_snapped = false
			
			if Input.is_key_pressed(KEY_SHIFT):
				new_rot = round(raw_rot / (PI / 12.0)) * (PI / 12.0)
				is_snapped = true
			else:
				var raw_deg = fmod(rad_to_deg(raw_rot), 360.0)
				if raw_deg < 0: raw_deg += 360.0
				
				var closest_snap = round(raw_deg / 90.0) * 90.0
				var dist = abs(raw_deg - closest_snap)
				var snap_threshold = 8.0 # Snap ภายใน 8 องศา
				
				var snap_id = fmod(closest_snap, 360.0)
				if snap_id >= 359.9: snap_id = 0.0
				
				if dist <= snap_threshold:
					if not state["locked_angles"].has(snap_id):
						if state["current_snap"] == null:
							state["current_snap"] = snap_id
						
						if state["current_snap"] == snap_id:
							var snap_rad = deg_to_rad(closest_snap)
							var diff_to_snap = angle_difference(raw_rot, snap_rad)
							new_rot = raw_rot + diff_to_snap
							is_snapped = true
				else:
					if state["current_snap"] != null:
						# เมื่อหลุดจากระยะล็อค ให้แบนมุมนี้ในการลากครั้งนี้
						state["locked_angles"].append(state["current_snap"])
						state["current_snap"] = null
						
			target_node.rotation = new_rot
			
			if is_snapped:
				handle.color = Color(1.0, 1.0, 0.2, 0.9) # สีเหลืองสว่างเวลาลงล็อค
			else:
				handle.color = Color(0.2, 0.8, 0.2, 0.6) # สีเขียวปกติ
				
			handle.accept_event()
	)

func _spawn_zone(zone_type: String):
	# สร้างพื้นที่วางการ์ดแบบโปร่งใส
	var zone = ColorRect.new()
	if zone_type == "Card Zone":
		zone.color = Color(0.2, 0.6, 1.0, 0.3)
	elif zone_type == "Deck Zone":
		zone.color = Color(0.8, 0.4, 0.1, 0.3)
	else:
		zone.color = Color(0.2, 0.8, 0.3, 0.3)
	
	zone.size = Vector2(150, 210) # ขนาดการ์ดมาตรฐาน
	zone.position = Vector2(100, 100)
	
	# ทำให้ Zone สามารถลากได้ด้วยสคริปต์ลาก UI
	zone.set_script(load("res://scripts/DraggableControl.gd"))
	
	zone.set_meta("zone_type", zone_type)
	zone.set_meta("zone_settings", {
		"purpose": 0,
		"face": 0,
		"allow_move": true,
		"has_max_cards": false,
		"max_cards": 1
	})
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	zone.add_child(vbox)
	
	var label = Label.new()
	label.name = "Label"
	label.text = zone_type + "\n(Place | Up)\nMove: Yes | Max: ∞"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	
	var select_btn = Button.new()
	select_btn.text = "Settings ⚙"
	select_btn.custom_minimum_size = Vector2(100, 30)
	select_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	select_btn.pressed.connect(func():
		_open_zone_settings(zone)
	)
	vbox.add_child(select_btn)
	
	_add_delete_button(zone)
	_add_resize_handle(zone, Vector2(100, 100))
	_add_rotate_handle(zone)
	field_canvas.add_child(zone)

func _on_add_dice_pressed():
	# สร้างคอนเทนเนอร์หลักสำหรับลูกเต๋าเพื่อให้ลากได้
	var root_obj = Control.new()
	root_obj.position = Vector2(300, 100)
	root_obj.size = Vector2(80, 80)
	root_obj.set_script(load("res://scripts/DraggableControl.gd"))
	
	var bg = Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.8, 0.8, 0.8, 1.0)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	bg.add_theme_stylebox_override("panel", style)
	root_obj.add_child(bg)
	
	var dice_btn = Button.new()
	dice_btn.text = "D6: -"
	dice_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	dice_btn.offset_left = 10
	dice_btn.offset_top = 10
	dice_btn.offset_right = -10
	dice_btn.offset_bottom = -10
	
	dice_btn.pressed.connect(func():
		var result = randi() % 6 + 1
		dice_btn.text = "D6: " + str(result)
		var tween = get_tree().create_tween()
		tween.tween_property(root_obj, "position", root_obj.position + Vector2(0, -10), 0.1)
		tween.tween_property(root_obj, "position", root_obj.position, 0.1)
	)
	
	root_obj.add_child(dice_btn)
	_add_delete_button(root_obj)
	field_canvas.add_child(root_obj)

func _on_add_counter_pressed():
	# สร้างตัวนับแต้ม (Token) ที่สามารถลากได้
	var root_obj = Control.new()
	root_obj.position = Vector2(400, 100)
	root_obj.size = Vector2(120, 50)
	root_obj.custom_minimum_size = Vector2(120, 50)
	root_obj.set_script(load("res://scripts/TabletopCounter.gd"))
	
	var bg = Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.8, 0.8, 0.8, 1.0)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	bg.add_theme_stylebox_override("panel", style)
	root_obj.add_child(bg)
	
	var margin_c = MarginContainer.new()
	margin_c.name = "MarginContainer"
	margin_c.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_obj.add_child(margin_c)
	
	var val_label = Label.new()
	val_label.name = "Label"
	val_label.text = "0"
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	val_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin_c.add_child(val_label)
	
	var settings_btn = Button.new()
	settings_btn.text = "⚙"
	settings_btn.custom_minimum_size = Vector2(24, 24)
	settings_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	settings_btn.offset_left = -12
	settings_btn.offset_top = -12
	settings_btn.offset_right = 12
	settings_btn.offset_bottom = 12
	settings_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var s_style = StyleBoxFlat.new()
	s_style.bg_color = Color(0.2, 0.5, 0.8, 0.9)
	s_style.corner_radius_top_left = 12
	s_style.corner_radius_top_right = 12
	s_style.corner_radius_bottom_right = 12
	s_style.corner_radius_bottom_left = 12
	settings_btn.add_theme_stylebox_override("normal", s_style)
	settings_btn.pressed.connect(func(): _open_counter_settings(root_obj))
	root_obj.add_child(settings_btn)
	
	_add_delete_button(root_obj)
	_add_resize_handle(root_obj, Vector2(60, 60))
	_add_rotate_handle(root_obj)
	field_canvas.add_child(root_obj)

func _on_save_field_pressed():
	# บันทึกตำแหน่งและ Asset ทั้งหมดในโต๊ะ
	print("Field Layout Saved!")

func _on_back_pressed():
	Global.main_menu_tab = "CUSTOM"
	Global.switch_scene("res://scenes/MainMenu.tscn")

func _init_field_settings():
	field_settings_dialog = ConfirmationDialog.new()
	field_settings_dialog.title = "Field Zone Settings"
	
	var vbox = VBoxContainer.new()
	
	var hbox_name = HBoxContainer.new()
	var lbl_name = Label.new()
	lbl_name.text = "Name:"
	hbox_name.add_child(lbl_name)
	field_name_input = LineEdit.new()
	field_name_input.text = "Main Field"
	field_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_name.add_child(field_name_input)
	vbox.add_child(hbox_name)
	
	var hbox_size = HBoxContainer.new()
	var lbl_size = Label.new()
	lbl_size.text = "Size (W, H):"
	hbox_size.add_child(lbl_size)
	field_size_x = SpinBox.new()
	field_size_x.min_value = 100
	field_size_x.max_value = 10000
	hbox_size.add_child(field_size_x)
	field_size_y = SpinBox.new()
	field_size_y.min_value = 100
	field_size_y.max_value = 10000
	hbox_size.add_child(field_size_y)
	vbox.add_child(hbox_size)
	
	var hbox_rot = HBoxContainer.new()
	var lbl_rot = Label.new()
	lbl_rot.text = "Rotation (°):"
	hbox_rot.add_child(lbl_rot)
	field_rot = SpinBox.new()
	field_rot.min_value = -360
	field_rot.max_value = 360
	hbox_rot.add_child(field_rot)
	vbox.add_child(hbox_rot)
	
	var hbox_perm = HBoxContainer.new()
	var lbl_perm = Label.new()
	lbl_perm.text = "Permissions:"
	hbox_perm.add_child(lbl_perm)
	
	field_can_move_cards = CheckBox.new()
	field_can_move_cards.text = "Move Cards"
	hbox_perm.add_child(field_can_move_cards)
	
	field_can_play_cards = CheckBox.new()
	field_can_play_cards.text = "Play Cards"
	hbox_perm.add_child(field_can_play_cards)
	
	vbox.add_child(hbox_perm)
	
	field_settings_dialog.add_child(vbox)
	field_settings_dialog.confirmed.connect(_on_field_settings_confirmed)
	add_child(field_settings_dialog)

func _open_field_settings(target_field: Control = null):
	if target_field == null: target_field = field_canvas
	current_editing_field = target_field
	
	field_name_input.text = current_editing_field.get_meta("field_name", "Field")
	field_size_x.value = current_editing_field.size.x
	field_size_y.value = current_editing_field.size.y
	field_rot.value = current_editing_field.rotation_degrees
	var perms = current_editing_field.get_meta("field_perms", {"move": true, "play": true})
	field_can_move_cards.button_pressed = perms["move"]
	field_can_play_cards.button_pressed = perms["play"]
	
	field_settings_dialog.popup_centered()

func _on_field_settings_confirmed():
	if not is_instance_valid(current_editing_field): return
	current_editing_field.set_meta("field_name", field_name_input.text)
	current_editing_field.size = Vector2(field_size_x.value, field_size_y.value)
	current_editing_field.custom_minimum_size = current_editing_field.size
	current_editing_field.rotation_degrees = field_rot.value
	
	current_editing_field.set_meta("field_perms", {
		"move": field_can_move_cards.button_pressed,
		"play": field_can_play_cards.button_pressed
	})

func _spawn_sub_field():
	var sub_field = ColorRect.new()
	sub_field.color = Color(0.15, 0.3, 0.2, 0.5)
	sub_field.size = Vector2(600, 400)
	sub_field.custom_minimum_size = Vector2(600, 400)
	sub_field.position = Vector2(200, 200)
	sub_field.pivot_offset = sub_field.size / 2.0
	sub_field.set_meta("field_name", "Sub Field")
	sub_field.set_meta("field_perms", {"move": true, "play": true})
	
	sub_field.set_script(load("res://scripts/DraggableControl.gd"))
	
	sub_field.resized.connect(func(): sub_field.pivot_offset = sub_field.size / 2.0)
	
	var border = ReferenceRect.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.border_color = Color(1.0, 1.0, 1.0, 0.5)
	border.border_width = 4.0
	border.editor_only = false
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub_field.add_child(border)
	
	var f_settings_btn = Button.new()
	f_settings_btn.text = "⚙ Field"
	f_settings_btn.custom_minimum_size = Vector2(60, 30)
	f_settings_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	f_settings_btn.offset_left = 10
	f_settings_btn.offset_top = 10
	f_settings_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	f_settings_btn.pressed.connect(func(): _open_field_settings(sub_field))
	sub_field.add_child(f_settings_btn)
	
	_add_delete_button(sub_field)
	_add_resize_handle(sub_field, Vector2(200, 200))
	_add_rotate_handle(sub_field)
	
	field_canvas.add_child(sub_field)
