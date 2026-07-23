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
var field_card_w: SpinBox
var field_card_h: SpinBox

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

var component_templates: Dictionary = {}
var template_context_node: Control = null
var context_menu: PopupMenu
var save_template_dialog: ConfirmationDialog
var template_name_input: LineEdit

var template_selector: ConfirmationDialog
var template_list: ItemList
var context_template_meta: Dictionary
var template_action_menu: PopupMenu

var is_test_mode: bool = false
var test_mode_btn: Button
var pre_test_state: Array = []
var test_spawned_nodes: Array = []
var current_changeling_card: Control = null

var hand_scroll: Control  # เป็น Control ธรรมดา ไม่ clip overflow
<<<<<<< Updated upstream
var hand_zone: HBoxContainer
=======
var hand_zone: Control
var opponent_hand_box: HBoxContainer
>>>>>>> Stashed changes
var drag_layer: Control  # layer สำหรับการ์ดที่กำลังลากจากมือ (อยู่เหนือสุดทุกอย่าง)

var _hand_collapsed: bool = false
var _hand_normal_offset: float = -160.0
var _resizing_hand: bool = false
var _resize_start_y: float = 0.0
var _resize_start_offset: float = 0.0
const HAND_BAR_HEIGHT: float = 32.0
var hand_hscroll: HScrollBar  # แถบเลื่อนแนวนอน

func _ready():
	$Header/BackBtn.pressed.connect(_on_back_pressed)
	$HBoxContainer/LeftSide/SaveFieldBtn.pressed.connect(_on_save_field_pressed)
	
<<<<<<< Updated upstream
=======
	if Global.online_room_id != "":
		var rt_script = load("res://scripts/SupabaseRealtime.gd")
		if rt_script:
			realtime_client = Node.new()
			realtime_client.set_script(rt_script)
			add_child(realtime_client)
			realtime_client.card_moved.connect(_on_remote_card_moved)
			realtime_client.card_flipped.connect(_on_remote_card_flipped)
			realtime_client.card_tapped.connect(_on_remote_card_tapped)
			realtime_client.deck_shuffled.connect(_on_remote_deck_shuffled)
			realtime_client.card_spawned.connect(_on_remote_card_spawned)
			realtime_client.card_sent_to_hand.connect(_on_remote_card_sent_to_hand)
			realtime_client.card_inserted_into_deck.connect(_on_remote_card_inserted_into_deck)
			realtime_client.deck_drawn.connect(_on_remote_deck_drawn)
			realtime_client.zone_shuffled.connect(_on_remote_zone_shuffled)
			
			# Realtime custom signals
			realtime_client.connection_established.connect(func():
				print("Realtime Connection Established!")
				# Send a join signal or broadcast who we are
				realtime_client.send_broadcast("player_joined", {"player_name": Global.online_player_name, "role": Global.online_player_role})
			)
			
			# Listen to other custom events
			var ref_rt = realtime_client
			ref_rt.process_mode = PROCESS_MODE_ALWAYS
			# Handle other events dynamically by patching _handle_message handler
			# Or we can handle it inside _handle_message by adding custom signals to SupabaseRealtime.gd, 
			# but it is simpler to just connect to room and handle in _input or handle custom event broadcast.
			
			realtime_client.connect_to_room(Global.online_room_id, SupabaseService.SUPABASE_KEY)
	
	# Setup Load Button programmatically right after Save Button
	var load_btn = Button.new()
	load_btn.name = "LoadFieldBtn"
	load_btn.text = "Load Field"
	$HBoxContainer/LeftSide.add_child(load_btn)
	$HBoxContainer/LeftSide.move_child(load_btn, $HBoxContainer/LeftSide/SaveFieldBtn.get_index() + 1)
	load_btn.pressed.connect(_on_load_field_pressed)
	
	# Setup Field File Dialog
	field_file_dialog = FileDialog.new()
	field_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	field_file_dialog.filters = PackedStringArray(["*.json ; Field Layout Files"])
	field_file_dialog.size = Vector2(600, 400)
	field_file_dialog.use_native_dialog = true
	field_file_dialog.file_selected.connect(_on_field_file_selected)
	add_child(field_file_dialog)
	_init_online_field_dialogs()
	_init_opponent_hand()
	SupabaseService.fetch_all_cards(Callable()) # cache all cards in memory
	
>>>>>>> Stashed changes
	# Hand zone — ใช้ Control ธรรมดา (ไม่ clip) เพื่อให้การ์ดที่ขยายตอน hover โผล่เหนือขอบได้
	hand_scroll = Control.new()
	hand_scroll.name = "HandScroll"
	hand_scroll.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hand_scroll.offset_top = _hand_normal_offset
	hand_scroll.offset_bottom = 0
	hand_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	hand_scroll.clip_contents = false
	hand_scroll.z_index = 10  # อยู่เหนือ field_canvas แต่ต่ำกว่า drag_layer
	
	# พื้นหลัง hand zone
	var bg = ColorRect.new()
	bg.name = "HandBg"
	bg.color = Color(0.05, 0.05, 0.1, 0.88)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand_scroll.add_child(bg)
	
	# --- Resize Handle (แถบบนสุด 8px, cursor = resize) ---
	var resize_handle = Control.new()
	resize_handle.name = "ResizeHandle"
	resize_handle.set_anchors_preset(Control.PRESET_TOP_WIDE)
	resize_handle.offset_bottom = 8
	resize_handle.mouse_default_cursor_shape = Control.CURSOR_VSIZE
	resize_handle.mouse_filter = Control.MOUSE_FILTER_STOP
	resize_handle.z_index = 2
	
	var rh_bg = ColorRect.new()
	rh_bg.color = Color(0.35, 0.45, 0.7, 0.55)
	rh_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	rh_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	resize_handle.add_child(rh_bg)
	
	# grip dots ตกแต่ง
	var grip_lbl = Label.new()
	grip_lbl.text = "• • • • •"
	grip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grip_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	grip_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	grip_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grip_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	grip_lbl.add_theme_font_size_override("font_size", 8)
	resize_handle.add_child(grip_lbl)
	
	resize_handle.gui_input.connect(func(event: InputEvent):
		if _hand_collapsed: return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_resizing_hand = true
				_resize_start_y = event.global_position.y
				_resize_start_offset = hand_scroll.offset_top
			else:
				_resizing_hand = false
				_hand_normal_offset = hand_scroll.offset_top
				_update_hand_zone_sizing()
		if event is InputEventMouseMotion and _resizing_hand:
			var delta = event.global_position.y - _resize_start_y
			hand_scroll.offset_top = clamp(_resize_start_offset + delta, -520.0, -HAND_BAR_HEIGHT - 20.0)
			_update_hand_zone_sizing()
	)
	hand_scroll.add_child(resize_handle)
	
	# --- Collapse Bar (ปุ่มแถบยาวใต้ resize handle) ---
	var collapse_bar = Button.new()
	collapse_bar.name = "CollapseBar"
	collapse_bar.text = "▲  Hand Zone  ▲"
	collapse_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	collapse_bar.offset_top = 8
	collapse_bar.offset_bottom = 8 + HAND_BAR_HEIGHT - 8  # = HAND_BAR_HEIGHT
	collapse_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	collapse_bar.z_index = 2
	
	var cb_normal = StyleBoxFlat.new()
	cb_normal.bg_color = Color(0.12, 0.15, 0.25, 0.92)
	cb_normal.border_width_top = 1
	cb_normal.border_width_bottom = 1
	cb_normal.border_color = Color(0.3, 0.4, 0.7, 0.5)
	var cb_hover = cb_normal.duplicate()
	cb_hover.bg_color = Color(0.18, 0.22, 0.38, 0.95)
	collapse_bar.add_theme_stylebox_override("normal", cb_normal)
	collapse_bar.add_theme_stylebox_override("pressed", cb_normal)
	collapse_bar.add_theme_stylebox_override("hover", cb_hover)
	collapse_bar.add_theme_stylebox_override("focus", cb_normal)
	collapse_bar.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0, 0.9))
	collapse_bar.add_theme_font_size_override("font_size", 12)
	
	collapse_bar.pressed.connect(func():
		_hand_collapsed = not _hand_collapsed
		if _hand_collapsed:
			_hand_normal_offset = hand_scroll.offset_top
			hand_scroll.offset_top = -HAND_BAR_HEIGHT
			hand_zone.hide()
			collapse_bar.text = "▼  Hand Zone  ▼"
		else:
			hand_scroll.offset_top = _hand_normal_offset
			hand_zone.show()
			collapse_bar.text = "▲  Hand Zone  ▲"
	)
	hand_scroll.add_child(collapse_bar)
	
	hand_scroll.hide() # Hidden until test mode
	
	# --- Hand Zone (HBoxContainer ที่อยู่ใต้ bar) ---
	hand_zone = HBoxContainer.new()
	hand_zone.name = "HandZone"
	hand_zone.set_anchors_preset(Control.PRESET_FULL_RECT)
	hand_zone.offset_top = HAND_BAR_HEIGHT  # เริ่มใต้ collapse bar
	hand_zone.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_zone.add_theme_constant_override("separation", 12)
	hand_zone.clip_contents = false
	hand_scroll.add_child(hand_zone)
	
	# --- HScrollBar แนวนอน (แสดงเมื่อการ์ดเกินความกว้าง) ---
	hand_hscroll = HScrollBar.new()
	hand_hscroll.name = "HandHScroll"
	hand_hscroll.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hand_hscroll.offset_top = -14
	hand_hscroll.offset_bottom = 0
	hand_hscroll.mouse_filter = Control.MOUSE_FILTER_STOP
	hand_hscroll.step = 1.0
	hand_hscroll.hide()
	hand_hscroll.value_changed.connect(func(v: float):
		hand_zone.position.x = -v
	)
	hand_scroll.add_child(hand_hscroll)
	
	add_child(hand_scroll)
	
	# DragLayer — วางไว้เหนือสุดสำหรับการ์ดที่ floating ระหว่างลาก
	drag_layer = Control.new()
	drag_layer.name = "DragLayer"
	drag_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	drag_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_layer.z_index = 200
	add_child(drag_layer)
	
	test_mode_btn = Button.new()
	test_mode_btn.text = "Switch to Test Mode"
	test_mode_btn.custom_minimum_size = Vector2(150, 40)
	test_mode_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	test_mode_btn.offset_right = -10
	test_mode_btn.offset_top = 10
	test_mode_btn.pressed.connect(_toggle_test_mode)
	$Header.add_child(test_mode_btn)
	
	# Prototype features
	$HBoxContainer/LeftSide/AddZoneBtn.pressed.connect(func():
		_spawn_zone("Card Zone")
	)
	
	if $HBoxContainer/LeftSide.has_node("AddDeckZoneBtn"):
		$HBoxContainer/LeftSide/AddDeckZoneBtn.pressed.connect(func():
			_spawn_zone("Deck Zone")
		)
	
	if $HBoxContainer/LeftSide.has_node("AddFieldZoneBtn"):
		$HBoxContainer/LeftSide/AddFieldZoneBtn.pressed.connect(func():
			_spawn_sub_field()
		)
	
	$HBoxContainer/LeftSide/AddDiceBtn.pressed.connect(_on_add_dice_pressed)
	$HBoxContainer/LeftSide/AddCounterBtn.pressed.connect(_on_add_counter_pressed)
	
	var sep1 = HSeparator.new()
	$HBoxContainer/LeftSide.add_child(sep1)
	$HBoxContainer/LeftSide.move_child(sep1, 1)
	
	var lbl_temp_ui = Label.new()
	lbl_temp_ui.text = "Templates"
	lbl_temp_ui.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_temp_ui.add_theme_font_size_override("font_size", 18)
	$HBoxContainer/LeftSide.add_child(lbl_temp_ui)
	$HBoxContainer/LeftSide.move_child(lbl_temp_ui, 2)
	
	var btn_browse_temp = Button.new()
	btn_browse_temp.text = "Browse Templates"
	$HBoxContainer/LeftSide.add_child(btn_browse_temp)
	$HBoxContainer/LeftSide.move_child(btn_browse_temp, 3)
	btn_browse_temp.pressed.connect(func(): 
		_update_template_dropdowns()
		template_selector.popup_centered()
	)
	
	template_action_menu = PopupMenu.new()
	template_action_menu.id_pressed.connect(_on_template_action_menu_id_pressed)
	add_child(template_action_menu)
	
	_init_template_selector()
	
	var sep2 = HSeparator.new()
	$HBoxContainer/LeftSide.add_child(sep2)
	$HBoxContainer/LeftSide.move_child(sep2, 5)
	
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
	border.add_to_group("editor_only")
	field_canvas.add_child(border)
	
	var f_settings_btn = Button.new()
	f_settings_btn.text = "⚙ Field"
	f_settings_btn.custom_minimum_size = Vector2(60, 30)
	f_settings_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	f_settings_btn.offset_left = 10
	f_settings_btn.offset_top = 10
	f_settings_btn.pressed.connect(func(): _open_field_settings(field_canvas))
	f_settings_btn.add_to_group("editor_only")
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
	
	_load_templates()
	
	context_menu = PopupMenu.new()
	context_menu.add_item("Save as Template", 0)
	context_menu.id_pressed.connect(_on_context_menu_id_pressed)
	add_child(context_menu)
	
	save_template_dialog = ConfirmationDialog.new()
	save_template_dialog.title = "Save Template"
	var vb_temp = VBoxContainer.new()
	var lbl_temp = Label.new()
	lbl_temp.text = "Template Name:"
	vb_temp.add_child(lbl_temp)
	template_name_input = LineEdit.new()
	vb_temp.add_child(template_name_input)
	save_template_dialog.add_child(vb_temp)
	save_template_dialog.confirmed.connect(_on_save_template_confirmed)
	add_child(save_template_dialog)

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
	elif event is InputEventKey and event.pressed and not event.echo:
		var ctrl = event.ctrl_pressed
		if ctrl and event.keycode == KEY_EQUAL:   # Ctrl + = หรือ Ctrl + +
			_zoom_canvas(1.1, tabletop_view.size / 2.0)
			get_viewport().set_input_as_handled()
		elif ctrl and event.keycode == KEY_MINUS:  # Ctrl + -
			_zoom_canvas(1.0 / 1.1, tabletop_view.size / 2.0)
			get_viewport().set_input_as_handled()

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
		var speed = 800.0
		field_canvas.position += move_vec.normalized() * speed * delta

func _zoom_canvas(factor: float, mouse_pos: Vector2):
	var old_zoom = field_zoom
	field_zoom = clamp(field_zoom * factor, 0.2, 5.0)
	
	var local_mouse = field_canvas.get_local_mouse_position()
	
	field_canvas.scale = Vector2(field_zoom, field_zoom)
	
	var new_parent_pos = field_canvas.get_transform() * local_mouse
	field_canvas.position += mouse_pos - new_parent_pos

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
		
		current_editing_zone.set_meta("zone_type", new_type)
		if new_type == "Card Zone":
			current_editing_zone.color = Color(0.2, 0.6, 1.0, 0.3)
		elif new_type == "Deck Zone":
			current_editing_zone.color = Color(0.8, 0.4, 0.1, 0.3)
			
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
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(580, 350)
	
	asset_grid = GridContainer.new()
	asset_grid.columns = 5
	scroll.add_child(asset_grid)
	
	vbox.add_child(scroll)
	
	var hb = HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_END
	var shuffle_check = CheckBox.new()
	shuffle_check.name = "ShuffleCheck"
	shuffle_check.text = "Shuffle at start"
	shuffle_check.button_pressed = true # default to true
	hb.add_child(shuffle_check)
	vbox.add_child(hb)
	
	asset_selector.add_child(vbox)
	add_child(asset_selector)
	
	var ok_btn = asset_selector.get_ok_button()
	if ok_btn: ok_btn.hide()
	var cancel_btn = asset_selector.get_cancel_button()
	if cancel_btn: cancel_btn.text = "Close"

func _show_asset_selector(type: String):
	for child in asset_grid.get_children():
		child.queue_free()
		
	var shuffle_check = asset_selector.find_child("ShuffleCheck", true, false)
	if shuffle_check:
		shuffle_check.visible = (type == "deck")
		
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
	
	if not data.has("file_path"):
		data["file_path"] = path
		
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
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lbl)
	btn.add_child(vbox)
	if type == "card" and data.has("file_path"):
		btn.button_mask = MOUSE_BUTTON_LEFT
		Global.make_card_inspectable(btn, data["file_path"])
		
	btn.pressed.connect(func():
		var shuffle_at_start = false
		var shuffle_check = asset_selector.find_child("ShuffleCheck", true, false)
		if shuffle_check and shuffle_check.visible:
			shuffle_at_start = shuffle_check.button_pressed
			
		asset_selector.hide()
		
		if current_changeling_card and is_instance_valid(current_changeling_card):
			var spawned_obj = spawn_card_object(data) if type == "card" else spawn_deck_object(data)
			if type == "deck": spawned_obj.set_meta("shuffle_at_start", shuffle_at_start)
			
			var origin_zone = current_changeling_card.get_meta("origin_zone")
			if origin_zone and is_instance_valid(origin_zone):
				_apply_card_size(spawned_obj, field_canvas, origin_zone)
				spawned_obj.set_meta("origin_zone", origin_zone)
			else:
				spawned_obj.custom_minimum_size = current_changeling_card.custom_minimum_size
				spawned_obj.size = current_changeling_card.size
				
			spawned_obj.position = current_changeling_card.position
			spawned_obj.scale = current_changeling_card.scale
			spawned_obj.rotation = current_changeling_card.rotation
			
			_setup_changeling(spawned_obj, type)
			
			current_changeling_card.queue_free()
			current_changeling_card = null
			return
			
		elif current_target_zone and is_instance_valid(current_target_zone):
			var settings = current_target_zone.get_meta("zone_settings", {})
			if is_test_mode and settings.get("purpose", 0) == 1:
				var spawned_obj = spawn_card_object(data) if type == "card" else spawn_deck_object(data)
				if type == "deck": spawned_obj.set_meta("shuffle_at_start", shuffle_at_start)
				
				_apply_card_size(spawned_obj, field_canvas, current_target_zone)
				spawned_obj.set_meta("origin_zone", current_target_zone)
				spawned_obj.position = current_target_zone.position + (current_target_zone.size / 2.0) - ((spawned_obj.size * spawned_obj.scale) / 2.0)
				
				var face = settings.get("face", 0)
				if face == 1:
					_set_card_face_down(spawned_obj, true)
				
				var allow_move = settings.get("allow_move", true)
				if not allow_move and "locked" in spawned_obj:
					spawned_obj.locked = true
					
				_setup_changeling(spawned_obj, type)
				
				current_target_zone.hide()
				current_target_zone = null
				return
				
			var spawned_obj = spawn_card_object(data) if type == "card" else spawn_deck_object(data)
			if type == "deck": spawned_obj.set_meta("shuffle_at_start", shuffle_at_start)
			spawned_obj.position = current_target_zone.position
			current_target_zone.queue_free()
			current_target_zone = null
		else:
			var spawned_obj = spawn_card_object(data) if type == "card" else spawn_deck_object(data)
			if type == "deck": spawned_obj.set_meta("shuffle_at_start", shuffle_at_start)
	)
	asset_grid.add_child(btn)

func _setup_changeling(obj: Control, asset_type: String):
	test_spawned_nodes.append(obj)
	obj.set_meta("is_changeling", true)
	
	if asset_type == "deck":
		_setup_deck_changeling(obj)
		return
	
	# card: click to reselect
	var click_state = {"press_pos": Vector2.ZERO}
	obj.gui_input.connect(func(event):
		if not is_test_mode: return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				click_state["press_pos"] = event.global_position
			else:
				if event.global_position.distance_to(click_state["press_pos"]) < 5.0:
					current_changeling_card = obj
					_show_asset_selector(asset_type)
	)

func _setup_deck_changeling(deck_obj: Control):
	# --- Hover Overlay ---
	# สร้าง overlay เป็น Panel โปร่งแสงที่ปรากฏตอนเมาส์ชี้เท่านั้น
	var overlay = Panel.new()
	overlay.name = "DeckHoverOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 10
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ไม่รับเมาส์เอง ให้ parent รับ
	var ov_style = StyleBoxFlat.new()
	ov_style.bg_color = Color(0, 0, 0, 0.55)
	ov_style.corner_radius_top_left = 8
	ov_style.corner_radius_top_right = 8
	ov_style.corner_radius_bottom_left = 8
	ov_style.corner_radius_bottom_right = 8
	overlay.add_theme_stylebox_override("panel", ov_style)
	overlay.hide()
	deck_obj.add_child(overlay)
	
	# ชื่อ Deck
	var name_lbl = Label.new()
	var deck_data_meta = deck_obj.get_meta("deck_data", {})
	var total_cards = 0
	if deck_data_meta.has("groups"):
		for g in deck_data_meta["groups"]:
			for p in g.get("cards", {}):
				total_cards += int(g["cards"][p])
	name_lbl.text = deck_data_meta.get("deck_name", "Deck")
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	name_lbl.offset_bottom = 40
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	name_lbl.add_theme_constant_override("outline_size", 3)
	name_lbl.add_theme_font_size_override("font_size", 14)
	overlay.add_child(name_lbl)
	
	# จำนวนการ์ด
	var count_lbl = Label.new()
	count_lbl.name = "CountLabel"
	count_lbl.text = str(total_cards) + " Cards"
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_lbl.set_anchors_preset(Control.PRESET_CENTER)
	count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	count_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	count_lbl.add_theme_constant_override("outline_size", 3)
	count_lbl.add_theme_font_size_override("font_size", 13)
	overlay.add_child(count_lbl)
	deck_obj.set_meta("deck_count_label", count_lbl)
	
	# --- ปุ่มวงกลม (Change = ฟ้า, Confirm = เขียว) ---
	var btn_row = HBoxContainer.new()
	btn_row.name = "DeckBtnRow"
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	btn_row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	btn_row.offset_top = -40
	btn_row.offset_bottom = -8
	btn_row.mouse_filter = Control.MOUSE_FILTER_PASS
	overlay.add_child(btn_row)
	
	var _make_circle_btn = func(col_n: Color, col_h: Color, icon: String) -> Button:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(32, 32)
		btn.text = icon
		var s = StyleBoxFlat.new()
		s.bg_color = col_n
		s.corner_radius_top_left = 16
		s.corner_radius_top_right = 16
		s.corner_radius_bottom_left = 16
		s.corner_radius_bottom_right = 16
		btn.add_theme_stylebox_override("normal", s)
		btn.add_theme_stylebox_override("pressed", s)
		var sh = s.duplicate()
		sh.bg_color = col_h
		btn.add_theme_stylebox_override("hover", sh)
		btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		return btn
	
	var change_btn: Button = _make_circle_btn.call(
		Color(0.18, 0.47, 0.90, 0.92), Color(0.40, 0.65, 1.00, 1.0), "↺"
	)
	change_btn.tooltip_text = "Change Deck"
	btn_row.add_child(change_btn)
	
	var confirm_btn: Button = _make_circle_btn.call(
		Color(0.10, 0.60, 0.22, 0.92), Color(0.20, 0.80, 0.35, 1.0), "✔"
	)
	confirm_btn.tooltip_text = "Confirm Deck"
	btn_row.add_child(confirm_btn)
	
	# --- mouse_entered / mouse_exited ควบคุม overlay ---
	deck_obj.mouse_entered.connect(func():
		if deck_obj.get_meta("deck_confirmed", false): return
		if not is_instance_valid(overlay): return
		overlay.show()
	)
	deck_obj.mouse_exited.connect(func():
		if not is_instance_valid(overlay): return
		var local = deck_obj.get_local_mouse_position()
		if Rect2(Vector2.ZERO, deck_obj.size).has_point(local): return
		overlay.hide()
	)
	
	# --- Logic ปุ่ม ---
	change_btn.pressed.connect(func():
		if not is_test_mode: return
		overlay.hide()
		current_changeling_card = deck_obj
		_show_asset_selector("deck")
	)
	
	confirm_btn.pressed.connect(func():
		if not is_test_mode: return
		deck_obj.set_meta("deck_confirmed", true)
		overlay.hide()
		overlay.queue_free()
		
		var badge = Label.new()
		badge.text = "✔"
		badge.set_anchors_preset(Control.PRESET_TOP_LEFT)
		badge.offset_left = 4
		badge.offset_top = 4
		badge.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4, 1.0))
		badge.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		badge.add_theme_constant_override("outline_size", 4)
		badge.add_theme_font_size_override("font_size", 20)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		deck_obj.add_child(badge)
		
		# สร้าง HoverInfo panel สำหรับแสดงตอนชี้เด็คที่ยืนยันแล้ว
		var hover_panel = Panel.new()
		hover_panel.name = "HoverInfo"
		hover_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		hover_panel.z_index = 10
		hover_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var hp_style = StyleBoxFlat.new()
		hp_style.bg_color = Color(0, 0, 0, 0.60)
		hp_style.corner_radius_top_left = 8; hp_style.corner_radius_top_right = 8
		hp_style.corner_radius_bottom_left = 8; hp_style.corner_radius_bottom_right = 8
		hover_panel.add_theme_stylebox_override("panel", hp_style)
		hover_panel.hide()
		deck_obj.add_child(hover_panel)
		
		var hover_lbl = Label.new()
		hover_lbl.name = "HoverLabel"
		hover_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hover_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hover_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		hover_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hover_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		hover_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		hover_lbl.add_theme_constant_override("outline_size", 3)
		hover_lbl.add_theme_font_size_override("font_size", 13)
		hover_panel.add_child(hover_lbl)
		
		# connect mouse hover เพื่อ show/hide hover info
		deck_obj.mouse_entered.connect(func():
			if not is_instance_valid(hover_panel): return
			hover_panel.show()
		)
		deck_obj.mouse_exited.connect(func():
			if not is_instance_valid(hover_panel): return
			var local = deck_obj.get_local_mouse_position()
			if Rect2(Vector2.ZERO, deck_obj.size).has_point(local): return
			hover_panel.hide()
		)
		
		var deck_data = deck_obj.get_meta("deck_data", {})
		var draw_pile = []
		if deck_data.has("groups"):
			for g in deck_data["groups"]:
				for p in g.get("cards", {}):
					for i in range(int(g["cards"][p])):
						draw_pile.append(p)
		
		if deck_obj.get_meta("shuffle_at_start", false):
			draw_pile.shuffle()
			
		deck_obj.set_meta("draw_pile", draw_pile)
		_update_deck_count_label(deck_obj)
	)

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
	
	# (ชื่อและจำนวนการ์ดแสดงผ่าน overlay ใน _setup_deck_changeling เท่านั้น)
	
	var highlight = ReferenceRect.new()
	highlight.name = "DragHighlight"
	highlight.set_anchors_preset(Control.PRESET_FULL_RECT)
	highlight.border_color = Color(0, 1, 0, 1)
	highlight.border_width = 4
	highlight.editor_only = false
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight.hide()
	root_obj.add_child(highlight)
	
	root_obj.set_script(load("res://scripts/DraggableControl.gd"))
	if root_obj.has_signal("drag_ended"):
		root_obj.drag_ended.connect(func(): _on_card_drag_ended(root_obj))
	if root_obj.has_signal("drag_moved"):
		root_obj.drag_moved.connect(func(): _on_card_drag_moved(root_obj))
	if root_obj.has_signal("left_clicked"):
		root_obj.left_clicked.connect(func(): _on_deck_left_clicked(root_obj))
		
	root_obj.set_meta("component_category", "deck")
	root_obj.set_meta("deck_data", deck_data)
	root_obj.z_index = 2  # อยู่เหนือ zone (z=0) เสมอ
	
	_add_delete_button(root_obj)
	_apply_card_size(root_obj, field_canvas, null)
	field_canvas.add_child(root_obj)
	return root_obj

func spawn_card_object(card_data: Dictionary, auto_add: bool = true) -> Control:
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
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	name_lbl.offset_top = 0
	name_lbl.offset_bottom = 30
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	name_lbl.add_theme_constant_override("outline_size", 4)
	
	name_lbl.hide()
	root_obj.mouse_entered.connect(func(): name_lbl.show())
	root_obj.mouse_exited.connect(func(): name_lbl.hide())
	
	root_obj.add_child(name_lbl)
	
	root_obj.position = Vector2(200, 200)
	
	var highlight = ReferenceRect.new()
	highlight.name = "DragHighlight"
	highlight.set_anchors_preset(Control.PRESET_FULL_RECT)
	highlight.border_color = Color(0, 1, 0, 1)
	highlight.border_width = 4
	highlight.editor_only = false
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight.hide()
	root_obj.add_child(highlight)
	
	root_obj.set_script(load("res://scripts/DraggableControl.gd"))
	if root_obj.has_signal("drag_ended"):
		root_obj.drag_ended.connect(func(): _on_card_drag_ended(root_obj))
	if root_obj.has_signal("drag_moved"):
		root_obj.drag_moved.connect(func(): _on_card_drag_moved(root_obj))
	if root_obj.has_signal("drag_started"):
		root_obj.drag_started.connect(func(): _on_card_drag_started(root_obj))
		
	root_obj.set_meta("component_category", "card")
	root_obj.set_meta("card_data", card_data)
	root_obj.z_index = 2  # อยู่เหนือ zone (z=0) เสมอ
	
	if card_data.has("file_path"):
		Global.make_card_inspectable(root_obj, card_data["file_path"])
	
	_add_delete_button(root_obj)
	if auto_add:
		_apply_card_size(root_obj, field_canvas, null)
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
	delete_btn.add_to_group("editor_only")
	target_node.add_child(delete_btn)
	if is_test_mode: delete_btn.hide()

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
	handle.add_to_group("editor_only")
	
	target_node.add_child(handle)
	if is_test_mode: handle.hide()
	
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
	handle.add_to_group("editor_only")
	
	target_node.add_child(handle)
	if is_test_mode: handle.hide()
	
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
	
	zone.size = Vector2(150, 210) # ขนาดการ์ดมาตรฐาน
	zone.position = Vector2(100, 100)
	
	# ทำให้ Zone สามารถลากได้ด้วยสคริปต์ลาก UI
	zone.set_script(load("res://scripts/DraggableControl.gd"))
	
	zone.set_meta("component_category", "zone")
	if zone.has_signal("right_clicked"):
		zone.right_clicked.connect(func(): _on_component_right_clicked(zone))
		
	zone.gui_input.connect(func(event):
		if not is_test_mode: return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			var settings = zone.get_meta("zone_settings", {})
			if settings.get("purpose", 0) == 1: # Select
				current_target_zone = zone
				var z_type = zone.get_meta("zone_type", "Card Zone")
				if z_type == "Card Zone":
					_show_asset_selector("card")
				else:
					_show_asset_selector("deck")
	)
		
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
	select_btn.add_to_group("editor_only")
	vbox.add_child(select_btn)
	
	_add_delete_button(zone)
	_add_resize_handle(zone, Vector2(100, 100))
	_add_rotate_handle(zone)
	field_canvas.add_child(zone)
	return zone

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
	
	root_obj.set_meta("component_category", "counter")
	if root_obj.has_signal("right_clicked"):
		root_obj.right_clicked.connect(func(): _on_component_right_clicked(root_obj))
		
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
	settings_btn.add_to_group("editor_only")
	root_obj.add_child(settings_btn)
	
	_add_delete_button(root_obj)
	_add_resize_handle(root_obj, Vector2(60, 60))
	_add_rotate_handle(root_obj)
	field_canvas.add_child(root_obj)
	return root_obj

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
	
	var hbox_card_size = HBoxContainer.new()
	var lbl_card_size = Label.new()
	lbl_card_size.text = "Card Size (W,H) 0=Auto:"
	hbox_card_size.add_child(lbl_card_size)
	field_card_w = SpinBox.new()
	field_card_w.min_value = 0
	field_card_w.max_value = 10000
	field_card_w.value = 0
	hbox_card_size.add_child(field_card_w)
	field_card_h = SpinBox.new()
	field_card_h.min_value = 0
	field_card_h.max_value = 10000
	field_card_h.value = 0
	hbox_card_size.add_child(field_card_h)
	vbox.add_child(hbox_card_size)
	
	field_settings_dialog.add_child(vbox)
	field_settings_dialog.confirmed.connect(_on_field_settings_confirmed)
	add_child(field_settings_dialog)

func _apply_card_size(card_obj: Control, field: Control, target_zone: Control = null):
	var w = float(field.get_meta("card_custom_width", 0))
	var h = float(field.get_meta("card_custom_height", 0))
	var final_w = 150.0
	var final_h = 210.0
	
	if w > 0 and h > 0:
		final_w = w
		final_h = h
	elif w > 0:
		final_w = w
		final_h = w * (210.0 / 150.0)
	elif h > 0:
		final_h = h
		final_w = h * (150.0 / 210.0)
	else:
		if target_zone:
			var z_w = target_zone.size.x
			var z_h = target_zone.size.y
			var scale_factor = min(z_w / 150.0, z_h / 210.0)
			final_w = 150.0 * scale_factor
			final_h = 210.0 * scale_factor
			
	card_obj.custom_minimum_size = Vector2(final_w, final_h)
	card_obj.size = Vector2(final_w, final_h)
	card_obj.scale = Vector2.ONE

func _update_all_cards_size(node: Node, field: Control):
	for child in node.get_children():
		if child is Control and child.has_meta("component_category") and child.get_meta("component_category") in ["card", "deck"]:
			var p = child.get_parent()
			var zone = p if p is Control and p.has_meta("component_category") and p.get_meta("component_category") == "zone" else null
			_apply_card_size(child, field, zone)
		_update_all_cards_size(child, field)

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
	
	field_card_w.value = current_editing_field.get_meta("card_custom_width", 0)
	field_card_h.value = current_editing_field.get_meta("card_custom_height", 0)
	
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
	
	current_editing_field.set_meta("card_custom_width", field_card_w.value)
	current_editing_field.set_meta("card_custom_height", field_card_h.value)
	_update_all_cards_size(current_editing_field, current_editing_field)

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
	
	sub_field.set_meta("component_category", "field")
	if sub_field.has_signal("right_clicked"):
		sub_field.right_clicked.connect(func(): _on_component_right_clicked(sub_field))
	
	sub_field.resized.connect(func(): sub_field.pivot_offset = sub_field.size / 2.0)
	
	var border = ReferenceRect.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.border_color = Color(1.0, 1.0, 1.0, 0.5)
	border.border_width = 4.0
	border.editor_only = false
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.add_to_group("editor_only")
	sub_field.add_child(border)
	
	var f_settings_btn = Button.new()
	f_settings_btn.text = "⚙ Field"
	f_settings_btn.custom_minimum_size = Vector2(60, 30)
	f_settings_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	f_settings_btn.offset_left = 10
	f_settings_btn.offset_top = 10
	f_settings_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	f_settings_btn.pressed.connect(func(): _open_field_settings(sub_field))
	f_settings_btn.add_to_group("editor_only")
	sub_field.add_child(f_settings_btn)
	
	_add_delete_button(sub_field)
	_add_resize_handle(sub_field, Vector2(200, 200))
	_add_rotate_handle(sub_field)
	
	field_canvas.add_child(sub_field)
	return sub_field

func _on_component_right_clicked(node: Control):
	template_context_node = node
	context_menu.position = get_viewport().get_mouse_position()
	context_menu.popup()

func _on_context_menu_id_pressed(id: int):
	if id == 0:
		template_name_input.text = ""
		save_template_dialog.popup_centered(Vector2i(250, 100))

func _on_save_template_confirmed():
	var t_name = template_name_input.text.strip_edges()
	if t_name == "" or not is_instance_valid(template_context_node): return
	
	var cat = template_context_node.get_meta("component_category", "")
	var t_data = {}
	if cat == "zone":
		t_data = template_context_node.get_meta("zone_settings").duplicate()
		t_data["zone_type"] = template_context_node.get_meta("zone_type")
	elif cat == "counter":
		t_data = {
			"counter_name": template_context_node.counter_name if "counter_name" in template_context_node else "",
			"name_position": template_context_node.name_position if "name_position" in template_context_node else 0,
			"default_value": template_context_node.default_value if "default_value" in template_context_node else 0,
			"name_auto_scale": template_context_node.name_auto_scale if "name_auto_scale" in template_context_node else true,
			"name_custom_size": template_context_node.name_custom_size if "name_custom_size" in template_context_node else 14,
			"is_vertical": template_context_node.is_vertical if "is_vertical" in template_context_node else false,
			"rotation_degrees": template_context_node.rotation_degrees
		}
	elif cat == "field":
		t_data = {
			"field_name": template_context_node.get_meta("field_name", "Sub Field"),
			"field_size_x": template_context_node.size.x,
			"field_size_y": template_context_node.size.y,
			"field_rot": template_context_node.rotation_degrees,
			"field_perms": template_context_node.get_meta("field_perms", {"move": true, "play": true}).duplicate()
		}
	
	if cat != "":
		if not component_templates.has(cat): component_templates[cat] = {}
		component_templates[cat][t_name] = t_data
		_save_templates()
		_update_template_dropdowns()

func _load_templates():
	if FileAccess.file_exists("user://templates.json"):
		var str = FileAccess.get_file_as_string("user://templates.json")
		var json = JSON.new()
		if json.parse(str) == OK:
			var data = json.get_data()
			if typeof(data) == TYPE_DICTIONARY:
				component_templates = data
	_update_template_dropdowns()

func _save_templates():
	var file = FileAccess.open("user://templates.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(component_templates))

func _init_template_selector():
	template_selector = ConfirmationDialog.new()
	template_selector.title = "Select Template"
	template_selector.min_size = Vector2i(400, 300)
	
	template_list = ItemList.new()
	template_list.set_anchors_preset(Control.PRESET_FULL_RECT)
	template_list.custom_minimum_size = Vector2(380, 250)
	
	template_list.item_clicked.connect(func(index, at_pos, mouse_btn):
		if mouse_btn == MOUSE_BUTTON_RIGHT:
			context_template_meta = template_list.get_item_metadata(index)
			template_action_menu.clear()
			template_action_menu.add_item("Delete Template", 0)
			template_action_menu.position = get_viewport().get_mouse_position()
			template_action_menu.popup()
	)
	
	template_list.item_activated.connect(func(index):
		_spawn_template_from_meta(template_list.get_item_metadata(index))
		template_selector.hide()
	)
	
	template_selector.add_child(template_list)
	
	template_selector.get_ok_button().text = "Spawn"
	template_selector.confirmed.connect(func():
		var sel = template_list.get_selected_items()
		if sel.size() > 0:
			_spawn_template_from_meta(template_list.get_item_metadata(sel[0]))
	)
	
	add_child(template_selector)

func _update_template_dropdowns():
	if is_instance_valid(template_list):
		template_list.clear()
		for cat in component_templates.keys():
			for k in component_templates[cat].keys():
				var display_name = cat.capitalize() + ": " + k
				var idx = template_list.add_item(display_name)
				template_list.set_item_metadata(idx, {"cat": cat, "name": k})

func _spawn_template_from_meta(meta: Dictionary):
	if typeof(meta) != TYPE_DICTIONARY: return
	var cat = meta.get("cat", "")
	var t_name = meta.get("name", "")
	if not component_templates.has(cat) or not component_templates[cat].has(t_name): return
	
	var t_data = component_templates[cat][t_name]
	if cat == "zone":
		var z_type = t_data.get("zone_type", "Card Zone")
		var new_zone = _spawn_zone(z_type)
		if new_zone:
			var s_data = {
				"purpose": t_data.get("purpose", 0),
				"face": t_data.get("face", 0),
				"allow_move": t_data.get("allow_move", true),
				"has_max_cards": t_data.get("has_max_cards", false),
				"max_cards": t_data.get("max_cards", 1)
			}
			new_zone.set_meta("zone_settings", s_data)
			
			var lbl = new_zone.get_node_or_null("VBoxContainer/Label")
			if lbl:
				var p_str = "Place" if s_data["purpose"] == 0 else "Select"
				var f_str = "Up" if s_data["face"] == 0 else ("Down" if s_data["face"] == 1 else "Free")
				var m_str = "Move: Yes" if s_data.get("allow_move", true) else "Move: No"
				var limit_str = "Max: " + str(s_data.get("max_cards", 1)) if s_data.get("has_max_cards", false) else "Max: ∞"
				lbl.text = z_type + "\n(" + p_str + " | " + f_str + ")\n" + m_str + " | " + limit_str
	elif cat == "counter":
		var new_counter = _on_add_counter_pressed()
		if new_counter:
			new_counter.set_counter_properties(
				t_data.get("counter_name", ""),
				t_data.get("name_position", 0),
				t_data.get("default_value", 0),
				t_data.get("name_auto_scale", true),
				t_data.get("name_custom_size", 14)
			)
			new_counter.set_orientation(t_data.get("is_vertical", false))
			new_counter.rotation_degrees = t_data.get("rotation_degrees", 0)
	elif cat == "field":
		var new_field = _spawn_sub_field()
		if new_field:
			new_field.set_meta("field_name", t_data.get("field_name", "Sub Field"))
			new_field.size = Vector2(t_data.get("field_size_x", 600), t_data.get("field_size_y", 400))
			new_field.custom_minimum_size = new_field.size
			new_field.rotation_degrees = t_data.get("field_rot", 0)
			new_field.set_meta("field_perms", t_data.get("field_perms", {"move": true, "play": true}))

func _on_template_action_menu_id_pressed(id: int):
	if id == 0:
		if typeof(context_template_meta) != TYPE_DICTIONARY: return
		var cat = context_template_meta.get("cat", "")
		var t_name = context_template_meta.get("name", "")
		
		if component_templates.has(cat) and component_templates[cat].has(t_name):
			component_templates[cat].erase(t_name)
			_save_templates()
			_update_template_dropdowns()

func _toggle_test_mode():
	is_test_mode = not is_test_mode
	
	if is_test_mode:
		test_mode_btn.text = "Switch to Build Mode"
		test_mode_btn.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
		
		if hand_scroll: hand_scroll.show()
		
		pre_test_state.clear()
		test_spawned_nodes.clear()
		for child in field_canvas.get_children():
			if child is Control:
				var state = {
					"node": child,
					"position": child.position,
					"rotation": child.rotation,
					"size": child.size,
					"visible": child.visible,
					"parent": child.get_parent()
				}
				if child.has_meta("component_category") and child.get_meta("component_category") == "zone":
					var zone_children_state = []
					for zc in child.get_children():
						if zc is Control and zc.has_meta("component_category"):
							zone_children_state.append({
								"node": zc,
								"position": zc.position,
								"rotation": zc.rotation,
								"size": zc.size,
								"visible": zc.visible,
								"parent": zc.get_parent()
							})
					state["zone_children"] = zone_children_state
				pre_test_state.append(state)
	else:
		test_mode_btn.text = "Switch to Test Mode"
		test_mode_btn.remove_theme_color_override("font_color")
		
		if hand_scroll: hand_scroll.hide()
		
		for node in test_spawned_nodes:
			if is_instance_valid(node) and not node.is_queued_for_deletion():
				node.queue_free()
		test_spawned_nodes.clear()
		
		for state in pre_test_state:
			var node = state["node"]
			if is_instance_valid(node):
				if node.get_parent() != state["parent"]:
					if node.get_parent():
						node.get_parent().remove_child(node)
					if state["parent"]:
						state["parent"].add_child(node)
				node.position = state["position"]
				node.rotation = state["rotation"]
				node.size = state["size"]
				node.visible = state["visible"]
				
				if state.has("zone_children"):
					for zc_state in state["zone_children"]:
						var zc = zc_state["node"]
						if is_instance_valid(zc):
							if zc.get_parent() != zc_state["parent"]:
								if zc.get_parent():
									zc.get_parent().remove_child(zc)
								if zc_state["parent"]:
									zc_state["parent"].add_child(zc)
							zc.position = zc_state["position"]
							zc.rotation = zc_state["rotation"]
							zc.size = zc_state["size"]
							zc.visible = zc_state["visible"]
		pre_test_state.clear()
		
		# ลบการ์ดทั้งหมดบนมือ
		if hand_zone:
			for c in hand_zone.get_children():
				c.queue_free()
		
		# ลบการ์ดที่ถูกจั่วออกมาอยู่บนสนาม
		for child in field_canvas.get_children():
			var cat = child.get_meta("component_category", "")
			if cat == "card":
				child.queue_free()
				continue
			# reset สถานะ deck กลับ
			if cat == "deck":
				var deck_out_node = child.get_node_or_null("DeckOutOverlay")
				if deck_out_node: deck_out_node.queue_free()
				var hover_info = child.get_node_or_null("HoverInfo")
				if hover_info: hover_info.hide()
		
		for child in field_canvas.get_children():
			if child.has_meta("component_category") and child.get_meta("component_category") == "zone":
				if child.has_meta("original_color"):
					child.color = child.get_meta("original_color")
				var default_lbl = child.get_node_or_null("VBoxContainer")
				if default_lbl:
					default_lbl.show()
		
	$HBoxContainer/LeftSide.visible = not is_test_mode
	
	# ซ่อน/แสดง UI สำหรับ Editor
	var editor_nodes = get_tree().get_nodes_in_group("editor_only")
	for node in editor_nodes:
		if node is Control:
			node.visible = not is_test_mode
			
	# ปรับสถานะ Lock ของ Component ต่างๆ
	for child in field_canvas.get_children():
		var cat = child.get_meta("component_category", "")
		if cat in ["zone", "field", "counter", "dice", "image"]:
			if "locked" in child:
				child.locked = is_test_mode

func _on_card_drag_ended(card: Control):
	if not is_test_mode: return
	
	# ตรวจว่าปล่อยการ์ดใน hand zone หรือเปล่า
	if hand_scroll and hand_scroll.visible:
		if hand_scroll.get_global_rect().has_point(get_global_mouse_position()):
			_add_card_to_hand(card)
			return
	
	# ปล่อยนอก hand zone → คืนขนาด field ก่อน แล้วค่อยวางบนสนาม
	if card.get_meta("in_hand", false):
		var field_sz = card.get_meta("field_size", card.size)
		var field_sc = card.get_meta("field_scale", Vector2.ONE)
		card.custom_minimum_size = field_sz
		card.size = field_sz
		card.pivot_offset = field_sz / 2.0
		if card.has_method("update_base_scale"):
			card.update_base_scale(field_sc)
		else:
			card.scale = field_sc
		# center การ์ดบน cursor (ขนาดเพิ่งเปลี่ยน)
		card.global_position = get_global_mouse_position() - field_sz / 2.0
	
	card.set_meta("in_hand", false)
	
	var drop_global = get_global_mouse_position()
	var card_rect = Rect2(card.global_position, card.size * card.scale)
	var card_center = card_rect.get_center()
	
	# reparent เข้า field_canvas ก่อนเช็ค zone
	if card.get_parent() != field_canvas:
		var g_pos = card.global_position
		card.get_parent().remove_child(card)
		field_canvas.add_child(card)
		card.global_position = g_pos
	
	# รีเซ็ต hover state หลัง reparent
	# (การ reparent ยิง mouse_exited + mouse_entered ทันที ทำให้ hover scale ถูก apply ซ้อน)
	var htween = card.get("hover_tween")
	if htween and htween is Tween: htween.kill()
	card.set("is_hovering", false)
	var base = card.get("base_scale")
	if base: card.scale = base
	
	# เช็คว่าวางบน zone ไหมหรือเปล่า
	var handled = false
	for child in field_canvas.get_children():
		if child == card: continue
		if child.has_meta("component_category") and child.get_meta("component_category") == "zone":
			if not child.visible: continue
			var zone_rect = Rect2(child.global_position, child.size * child.scale)
			if zone_rect.has_point(card_center):
				_handle_card_dropped_on_zone(card, child)
				handled = true
				break
				
	if not handled:
		# ตำแหน่งการ์ดถูกตามเมาส์อยู่แล้วผ่าน drag_offset ใน DraggableControl
		# ไม่ต้องคำนวณใหม่ — global_position ของการ์ดคือตำแหน่งที่ถูกต้องแล้ว
		pass
			
	var prev_zone = card.get_meta("current_hovered_zone", null)
	if prev_zone:
		_clear_zone_highlight(prev_zone)
		card.set_meta("current_hovered_zone", null)
	_highlight_card(card, false)

func _on_card_drag_moved(card: Control):
	if not is_test_mode: return
	var card_rect = Rect2(card.global_position, card.size * card.scale)
	var card_center = card_rect.get_center()
	
	var target_zone = null
	for child in field_canvas.get_children():
		if child == card: continue
		if child.has_meta("component_category") and child.get_meta("component_category") == "zone":
			if not child.visible: continue
			var zone_rect = Rect2(child.global_position, child.size * child.scale)
			if zone_rect.has_point(card_center):
				if _will_zone_accept_card(child, card):
					target_zone = child
				break
				
	var prev_zone = card.get_meta("current_hovered_zone", null)
	if prev_zone != target_zone:
		if prev_zone:
			_clear_zone_highlight(prev_zone)
		if target_zone:
			_highlight_zone(target_zone)
		card.set_meta("current_hovered_zone", target_zone)
		
	if target_zone:
		_highlight_card(card, true)
	else:
		_highlight_card(card, false)

func _on_card_drag_started(card: Control):
	# ถ้าการ์ดอยู่บนมือ ไม่ต้องทำอะไร — ให้อยู่ใน hand_zone ระหว่าง drag
	# (field size จะถูกคืนตอน drop ใน _on_card_drag_ended เหมือนกับที่ deck ทำ)
	if card.get_meta("in_hand", false): return

func _add_card_to_hand(card: Control):
	card.set_meta("in_hand", true)
	
	# บันทึกขนาดบนสนาม ก่อนที่จะเปลี่ยนอะไรทั้งนั้น
	# ต้องทำก่อน update_base_scale เพราะ base_scale ยังเป็นค่าบนสนามอยู่
	var current_bs = card.get("base_scale")
	card.set_meta("field_size", card.size)  # always overwrite (อาจถูก resize บนสนาม)
	card.set_meta("field_scale", current_bs if current_bs != null else card.scale)
	
	if card.get_parent():
		card.get_parent().remove_child(card)
	# kill hover_tween ที่อาจค้างจาก mouse_exited ตอน remove_child
	var htween = card.get("hover_tween")
	if htween and htween is Tween: htween.kill()
	card.set("is_hovering", false)
	# reset scale ก่อน (ขนาดจะถูกคำนวณใหม่ใน _update_hand_zone_sizing)
	if card.has_method("update_base_scale"):
		card.update_base_scale(Vector2.ONE)
	else:
		card.scale = Vector2.ONE
	if hand_zone:
		hand_zone.add_child(card)
		_update_hand_zone_sizing.call_deferred()

func _update_hand_zone_sizing():
	if _hand_collapsed or not hand_scroll.visible: return
	
	# ความสูงที่ใช้ได้จริง (หักลบ bar + hscrollbar)
	var zone_h = abs(hand_scroll.offset_top) - HAND_BAR_HEIGHT - 14.0
	if zone_h < 20: return
	
	var sep = 12
	var total_w = 0.0
	var child_count = 0
	for card in hand_zone.get_children():
		# อ่านขนาดบนสนามจาก meta เสมอ
		var field_size: Vector2 = card.get_meta("field_size", Vector2(150, 210))
		var aspect = field_size.x / max(field_size.y, 1.0)
		var card_w = zone_h * aspect
		
		# ตั้ง size ตรงๆ เพื่อให้ HBoxContainer + pivot_offset ทำงานถูกต้อง
		# (field_size ยังอยู่ใน meta ครบ ตอน drag จะ restore จาก meta เสมอ)
		card.custom_minimum_size = Vector2(card_w, zone_h)
		card.size = Vector2(card_w, zone_h)
		card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		# reset scale กลับ Vector2.ONE (pivot_offset = size/2 ของ hand display)
		if card.has_method("update_base_scale"):
			card.update_base_scale(Vector2.ONE)
		else:
			card.scale = Vector2.ONE
		total_w += card_w
		child_count += 1
	
	if child_count > 1:
		total_w += sep * (child_count - 1)
	
	# อัพเดต scrollbar
	var visible_w = hand_scroll.size.x
	if visible_w <= 0: visible_w = get_viewport().size.x
	if total_w > visible_w:
		hand_hscroll.max_value = total_w - visible_w + 16
		hand_hscroll.page = visible_w
		hand_hscroll.show()
		hand_zone.offset_bottom = -14
	else:
		hand_hscroll.value = 0
		hand_zone.position.x = 0
		hand_hscroll.hide()
		hand_zone.offset_bottom = 0

func _will_zone_accept_card(zone: Control, card: Control) -> bool:
	var settings = zone.get_meta("zone_settings", {})
	if settings.get("purpose", 0) != 0:
		return false
	if settings.get("has_max_cards", false):
		var current_cards = 0
		for c in zone.get_children():
			if c.has_meta("component_category") and c.get_meta("component_category") in ["card", "deck"]:
				current_cards += 1
		if card.get_parent() != zone and current_cards >= settings.get("max_cards", 1):
			return false
	return true

func _highlight_zone(zone: Control):
	if not zone.has_meta("base_color"):
		zone.set_meta("base_color", zone.color)
	zone.color = Color(0.2, 0.8, 0.2, 0.6)

func _clear_zone_highlight(zone: Control):
	if is_instance_valid(zone) and zone.has_meta("base_color"):
		zone.color = zone.get_meta("base_color")

func _highlight_card(card: Control, show: bool):
	var h = card.get_node_or_null("DragHighlight")
	if h:
		h.visible = show

func _handle_card_dropped_on_zone(card: Control, zone: Control):
	var settings = zone.get_meta("zone_settings", {})
	var purpose = settings.get("purpose", 0) # 0 = Place, 1 = Select
	
	if purpose == 0: # Place
		var current_cards = 0
		for child in zone.get_children():
			if child.has_meta("component_category") and child.get_meta("component_category") in ["card", "deck"]:
				current_cards += 1
				
		if settings.get("has_max_cards", false) and card.get_parent() != zone:
			var max_c = settings.get("max_cards", 1)
			if current_cards >= max_c:
				# Reject drop: snap back or just do nothing
				# Since we didn't store original pos, let's just snap it to the edge
				return
				
		if card.get_parent() != zone:
			card.get_parent().remove_child(card)
			zone.add_child(card)
		# center card = center zone
		# ไม่คูณ card.scale เพราะ pivot_offset = size/2 จัดการ scale ให้แล้ว
		card.pivot_offset = card.size / 2.0
		card.position = (zone.size / 2.0) - (card.size / 2.0)
			
		var face = settings.get("face", 0) # 0 = Up, 1 = Down, 2 = Free
		if face == 1:
			_set_card_face_down(card, true)
		elif face == 0:
			_set_card_face_down(card, false)
			
		var allow_move = settings.get("allow_move", true)
		if not allow_move:
			if "locked" in card:
				card.locked = true
				
	elif purpose == 1: # Select
		# Visual effect
		var original_color = zone.color
		var tween = create_tween()
		tween.tween_property(zone, "color", Color(1, 0, 0, 0.6), 0.15)
		tween.tween_property(zone, "color", original_color, 0.15)
		
		if card.get_parent() != field_canvas:
			var global_pos = card.global_position
			card.get_parent().remove_child(card)
			field_canvas.add_child(card)
			card.global_position = global_pos
		# ไม่ต้องทำอะไรถ้าอยู่ใน field_canvas อยู่แล้ว

func _set_card_face_down(card: Control, is_down: bool):
	if is_down:
		if not card.has_node("CardBack"):
			var back = ColorRect.new()
			back.name = "CardBack"
			back.color = Color(0.15, 0.15, 0.25, 1.0)
			back.set_anchors_preset(Control.PRESET_FULL_RECT)
			back.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var style = StyleBoxFlat.new()
			style.bg_color = back.color
			style.border_width_left = 4
			style.border_width_top = 4
			style.border_width_right = 4
			style.border_width_bottom = 4
			style.border_color = Color(0.8, 0.8, 0.8, 1.0)
			style.corner_radius_top_left = 6
			style.corner_radius_top_right = 6
			style.corner_radius_bottom_right = 6
			style.corner_radius_bottom_left = 6
			
			var panel = Panel.new()
			panel.set_anchors_preset(Control.PRESET_FULL_RECT)
			panel.add_theme_stylebox_override("panel", style)
			panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			back.add_child(panel)
			
			var lbl = Label.new()
			lbl.text = "CratAble"
			lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			back.add_child(lbl)
			card.add_child(back)
		card.get_node("CardBack").show()
	else:
		if card.has_node("CardBack"):
			card.get_node("CardBack").hide()

func _update_deck_count_label(deck_obj: Control):
	var draw_pile = deck_obj.get_meta("draw_pile", [])
	var is_out = draw_pile.is_empty()
	var count_text = str(draw_pile.size()) + " Cards"
	# อัปเดต CountLabel ใน overlay (ก่อนยืนยัน)
	if deck_obj.has_meta("deck_count_label"):
		var lbl = deck_obj.get_meta("deck_count_label")
		if is_instance_valid(lbl):
			lbl.text = count_text
	# อัปเดต HoverLabel (หลังยืนยัน - แสดงตอน hover บนเด็คที่ lock แล้ว)
	var hover_lbl = deck_obj.find_child("HoverLabel", true, false)
	if hover_lbl:
		var d_name = deck_obj.get_meta("deck_data", {}).get("deck_name", "Deck")
		hover_lbl.text = d_name + "\n" + count_text
	# แสดง / ซ่อน "Deck Out" overlay เมื่อการ์ดหมด
	var deck_out_node = deck_obj.get_node_or_null("DeckOutOverlay")
	if is_out:
		if not deck_out_node:
			deck_out_node = _create_deck_out_overlay()
			deck_out_node.name = "DeckOutOverlay"
			deck_obj.add_child(deck_out_node)
		deck_out_node.show()
	else:
		if deck_out_node:
			deck_out_node.hide()

func _create_deck_out_overlay() -> Control:
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 1.0)  # ทึบ 100%
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lbl = Label.new()
	lbl.text = "Deck Out"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_color_override("font_color", Color(0.85, 0.15, 0.15, 1.0))
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lbl.add_theme_constant_override("outline_size", 4)
	overlay.add_child(lbl)
	return overlay

func _on_deck_left_clicked(deck_obj: Control):
	if not is_test_mode: return
	if not deck_obj.get_meta("deck_confirmed", false): return
	
	var draw_pile = deck_obj.get_meta("draw_pile", [])
	if draw_pile.is_empty(): return
	
	var card_path = draw_pile.pop_back()
	deck_obj.set_meta("draw_pile", draw_pile)
	_update_deck_count_label(deck_obj)
	
	if not FileAccess.file_exists(card_path): return
	var json_str = FileAccess.get_file_as_string(card_path)
	var json = JSON.new()
	if json.parse(json_str) != OK: return
	
	var card_data = json.get_data()
	card_data["file_path"] = card_path
	
	# สร้างการ์ดโดยไม่ add เข้า field_canvas ก่อน (ไม่ใช่ changeling)
	var card = spawn_card_object(card_data, false)
	
	# บันทึกขนาดบนสนามที่ควรจะเป็น (เท่ากับ deck)
	var field_size = deck_obj.size
	var field_scale = deck_obj.get("base_scale")
	if field_scale == null: field_scale = deck_obj.scale
	card.custom_minimum_size = field_size
	card.size = field_size
	card.set_meta("field_size", field_size)
	card.set_meta("field_scale", field_scale)
	card.set_meta("in_hand", true)
	
	# scale = 1 สำหรับแสดงบนมือ ขนาดจะถูกคำนวณใหม่ใน _update_hand_zone_sizing
	card.scale = Vector2.ONE
	hand_zone.add_child(card)
	_update_hand_zone_sizing.call_deferred()
<<<<<<< Updated upstream
=======
	
	# Play flip animation midway during translation
	var scale_tween = get_tree().create_tween()
	scale_tween.tween_property(card, "scale:x", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	scale_tween.tween_callback(func(): _set_card_face_down(card, false))
	scale_tween.tween_property(card, "scale:x", 1.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# ==========================================
# In-Play Gameplay Operations & Callbacks
# ==========================================

func _init_tabletop_popup_menu():
	tabletop_popup_menu = PopupMenu.new()
	tabletop_popup_menu.id_pressed.connect(_on_tabletop_popup_menu_id_pressed)
	add_child(tabletop_popup_menu)

func _init_tabletop_viewers():
	# 1. Deck Peeker Prompt Dialog
	peeker_prompt_dialog = ConfirmationDialog.new()
	peeker_prompt_dialog.title = "Look at Top Cards"
	var hb = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = "Number of cards to peek:"
	hb.add_child(lbl)
	
	peeker_prompt_spinbox = SpinBox.new()
	peeker_prompt_spinbox.min_value = 1
	peeker_prompt_spinbox.max_value = 100
	peeker_prompt_spinbox.value = 3
	hb.add_child(peeker_prompt_spinbox)
	peeker_prompt_dialog.add_child(hb)
	peeker_prompt_dialog.confirmed.connect(func():
		if is_instance_valid(peeker_deck_target):
			_open_deck_peeker_with_count(peeker_deck_target, int(peeker_prompt_spinbox.value))
	)
	add_child(peeker_prompt_dialog)

	# 2. Deck Peeker Dialog
	peeker_dialog = ConfirmationDialog.new()
	peeker_dialog.title = "Deck Peeker"
	peeker_dialog.min_size = Vector2i(700, 350)
	
	var peeker_scroll = ScrollContainer.new()
	peeker_scroll.custom_minimum_size = Vector2(680, 280)
	peeker_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	peeker_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	peeker_cards_container = HBoxContainer.new()
	peeker_cards_container.add_theme_constant_override("separation", 15)
	peeker_scroll.add_child(peeker_cards_container)
	peeker_dialog.add_child(peeker_scroll)
	
	peeker_dialog.confirmed.connect(_on_peeker_dialog_confirmed)
	peeker_dialog.canceled.connect(_on_peeker_dialog_confirmed)
	add_child(peeker_dialog)

	# 3. Zone Pile Viewer Dialog
	zone_viewer_dialog = ConfirmationDialog.new()
	zone_viewer_dialog.title = "Zone Pile Viewer"
	zone_viewer_dialog.min_size = Vector2i(600, 400)
	
	var zone_scroll = ScrollContainer.new()
	zone_scroll.custom_minimum_size = Vector2(580, 330)
	zone_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	zone_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	
	zone_viewer_grid = GridContainer.new()
	zone_viewer_grid.columns = 4
	zone_viewer_grid.add_theme_constant_override("h_separation", 15)
	zone_viewer_grid.add_theme_constant_override("v_separation", 15)
	zone_scroll.add_child(zone_viewer_grid)
	zone_viewer_dialog.add_child(zone_scroll)
	add_child(zone_viewer_dialog)

	# 4. Deck Viewer Panel (non-modal overlay — allows drag & drop to hand/field)
	deck_viewer_dialog = PanelContainer.new()
	deck_viewer_dialog.name = "DeckViewerPanel"
	deck_viewer_dialog.custom_minimum_size = Vector2(760, 520)
	deck_viewer_dialog.top_level = true
	deck_viewer_dialog.z_index = 2000
	deck_viewer_dialog.set_anchors_preset(Control.PRESET_CENTER)
	deck_viewer_dialog.hide()
	
	var dv_style = StyleBoxFlat.new()
	dv_style.bg_color = Color(0.1, 0.12, 0.18, 0.97)
	dv_style.border_width_left = 2
	dv_style.border_width_top = 2
	dv_style.border_width_right = 2
	dv_style.border_width_bottom = 2
	dv_style.border_color = Color(0.35, 0.55, 0.9, 0.8)
	dv_style.corner_radius_top_left = 8
	dv_style.corner_radius_top_right = 8
	dv_style.corner_radius_bottom_left = 8
	dv_style.corner_radius_bottom_right = 8
	deck_viewer_dialog.add_theme_stylebox_override("panel", dv_style)
	
	var dv_margin = MarginContainer.new()
	dv_margin.add_theme_constant_override("margin_left", 12)
	dv_margin.add_theme_constant_override("margin_top", 12)
	dv_margin.add_theme_constant_override("margin_right", 12)
	dv_margin.add_theme_constant_override("margin_bottom", 12)
	deck_viewer_dialog.add_child(dv_margin)
	
	var dv_vbox = VBoxContainer.new()
	dv_vbox.add_theme_constant_override("separation", 8)
	dv_margin.add_child(dv_vbox)
	
	# Header
	var dv_header = HBoxContainer.new()
	var dv_title = Label.new()
	dv_title.text = "Deck Viewer"
	dv_title.add_theme_font_size_override("font_size", 18)
	dv_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dv_header.add_child(dv_title)
	
	var dv_hint = Label.new()
	dv_hint.text = "ลากการ์ดจัดเรียง / ลากออกไปสนามหรือมือ"
	dv_hint.add_theme_font_size_override("font_size", 12)
	dv_hint.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0, 0.7))
	dv_header.add_child(dv_hint)
	dv_vbox.add_child(dv_header)
	
	var dv_sep = HSeparator.new()
	dv_vbox.add_child(dv_sep)
	
	# Card grid scroll area
	deck_viewer_scroll = ScrollContainer.new()
	deck_viewer_scroll.custom_minimum_size = Vector2(720, 360)
	deck_viewer_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	deck_viewer_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	deck_viewer_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	
	deck_viewer_grid = Control.new()
	deck_viewer_grid.set_script(load("res://scripts/DeckViewerGrid.gd"))
	deck_viewer_grid.deck_viewer_ref = self
	deck_viewer_grid.columns = 4
	deck_viewer_grid.h_separation = 15.0
	deck_viewer_grid.v_separation = 15.0
	deck_viewer_scroll.add_child(deck_viewer_grid)
	dv_vbox.add_child(deck_viewer_scroll)
	
	# Footer buttons
	var dv_footer_sep = HSeparator.new()
	dv_vbox.add_child(dv_footer_sep)
	
	var dv_footer = HBoxContainer.new()
	dv_footer.alignment = BoxContainer.ALIGNMENT_END
	dv_footer.add_theme_constant_override("separation", 10)
	

	
	var dv_ok_btn = Button.new()
	dv_ok_btn.text = "OK"
	dv_ok_btn.custom_minimum_size = Vector2(90, 32)
	dv_ok_btn.pressed.connect(func():
		Global.play_sfx("res://SFX/Throw Card.ogg", -6.0, 1.8)
		_on_deck_viewer_confirmed()
	)
	dv_footer.add_child(dv_ok_btn)
	
	var dv_cancel_btn = Button.new()
	dv_cancel_btn.text = "Cancel"
	dv_cancel_btn.custom_minimum_size = Vector2(90, 32)
	dv_cancel_btn.pressed.connect(func():
		Global.play_sfx("res://SFX/Throw Card.ogg", -6.0, 1.4)
		_on_deck_viewer_canceled()
	)
	dv_footer.add_child(dv_cancel_btn)
	
	dv_vbox.add_child(dv_footer)
	
	add_child(deck_viewer_dialog)

func _on_card_right_clicked(card: Control):
	if not is_test_mode: return
	# การ์ดในมือจะไม่แสดงเมนูคลิกขวา
	if card.get_meta("in_hand", false): return
	_show_tabletop_context_menu(card, "card")

func _on_card_double_clicked(card: Control):
	if not is_test_mode: return
	if card.get_meta("in_hand", false): return
	_toggle_card_tap(card)

func _on_deck_right_clicked(deck: Control):
	if not is_test_mode: return
	if not deck.get_meta("deck_confirmed", false): return
	_show_tabletop_context_menu(deck, "deck")

func _on_zone_right_clicked(zone: Control):
	if not is_test_mode: return
	_show_tabletop_context_menu(zone, "zone")

func _show_tabletop_context_menu(node: Control, type: String):
	context_tabletop_node = node
	tabletop_popup_menu.clear()
	# ลบ metadata เด็คที่ค้างไว้
	tabletop_popup_menu.remove_meta("target_deck")
	
	if type == "card":
		var current_rot = node.rotation_degrees
		var is_tapped = abs(current_rot) > 45.0
		tabletop_popup_menu.add_item("Untap" if is_tapped else "Tap (90°)", 10)
		
		var is_face_down = node.has_node("CardBack")
		tabletop_popup_menu.add_item("Face Up" if is_face_down else "Face Down", 11)
		
		tabletop_popup_menu.add_item("Send to Hand", 12)
		tabletop_popup_menu.add_item("Send to Deck (Top)", 13)
		tabletop_popup_menu.add_item("Send to Deck (Bottom)", 14)
		
	elif type == "deck":
		tabletop_popup_menu.add_item("Draw Card", 20)
		tabletop_popup_menu.add_item("Shuffle Deck", 21)
		tabletop_popup_menu.add_item("Look at Top Cards...", 22)
		tabletop_popup_menu.add_item("View All Cards in Deck", 23)
		
	elif type == "zone":
		var settings = node.get_meta("zone_settings", {})
		if settings.get("purpose", 0) == 0: # Place
			var card_count = 0
			for child in node.get_children():
				if child.has_meta("component_category") and child.get_meta("component_category") in ["card", "deck"]:
					card_count += 1
			tabletop_popup_menu.add_item("View Cards in Pile (%d)" % card_count, 30)
			tabletop_popup_menu.add_item("Shuffle Pile", 31)
			
	if tabletop_popup_menu.item_count > 0:
		tabletop_popup_menu.position = get_viewport().get_mouse_position()
		tabletop_popup_menu.popup()

func _on_tabletop_popup_menu_id_pressed(id: int):
	if not is_instance_valid(context_tabletop_node): return
	
	match id:
		10: # Tap/Untap
			_toggle_card_tap(context_tabletop_node)
		11: # Flip face
			var is_face_down = context_tabletop_node.has_node("CardBack") and context_tabletop_node.get_node("CardBack").visible
			_set_card_face_down(context_tabletop_node, not is_face_down)
		12: # Send to Hand
			_add_card_to_hand(context_tabletop_node)
		13: # Send to Deck (Top)
			var target_deck = tabletop_popup_menu.get_meta("target_deck", null)
			if target_deck:
				_insert_card_into_deck(context_tabletop_node, target_deck, true)
			else:
				_send_card_to_deck(context_tabletop_node, true)
		14: # Send to Deck (Bottom)
			var target_deck = tabletop_popup_menu.get_meta("target_deck", null)
			if target_deck:
				_insert_card_into_deck(context_tabletop_node, target_deck, false)
			else:
				_send_card_to_deck(context_tabletop_node, false)
			
		20: # Draw
			_on_deck_left_clicked(context_tabletop_node)
		21: # Shuffle
			_shuffle_deck_programmatically(context_tabletop_node)
		22: # Look at Top Cards
			_open_deck_peeker(context_tabletop_node)
		23: # View All Cards
			_open_deck_viewer(context_tabletop_node)
			
		30: # View Cards
			_open_zone_viewer(context_tabletop_node)
		31: # Shuffle Zone Pile
			_shuffle_zone_pile(context_tabletop_node)

func _toggle_card_tap(card: Control, broadcast: bool = true):
	var current_rot = card.rotation_degrees
	var target_rot = 90.0 if abs(current_rot) < 45.0 else 0.0
	
	Global.play_sfx("res://SFX/Draw sfx.ogg", -5.0, 1.6)
	var tween = create_tween()
	tween.tween_property(card, "rotation_degrees", target_rot, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if broadcast and is_instance_valid(realtime_client) and realtime_client.is_connected:
		realtime_client.broadcast_card_tapped(card.name, target_rot != 0.0)

func _send_card_to_deck(card: Control, to_top: bool):
	var closest_deck: Control = null
	var min_dist = 999999.0
	var card_gpos = card.global_position
	
	for child in field_canvas.get_children():
		if child.has_meta("component_category") and child.get_meta("component_category") == "deck":
			var dist = child.global_position.distance_to(card_gpos)
			if dist < min_dist:
				min_dist = dist
				closest_deck = child
				
	if closest_deck:
		_insert_card_into_deck(card, closest_deck, to_top)
	else:
		print("No deck found on the tabletop to send the card to!")

func _insert_card_into_deck(card: Control, deck: Control, to_top: bool, broadcast: bool = true):
	var card_data = card.get_meta("card_data", {})
	var card_path = card_data.get("file_path", "")
	if card_path == "":
		card_path = card_data.get("image_path", "")
	
	if card_path != "":
		var draw_pile = deck.get_meta("draw_pile", [])
		if to_top:
			draw_pile.append(card_path)
		else:
			draw_pile.push_front(card_path)
		deck.set_meta("draw_pile", draw_pile)
		_update_deck_count_label(deck)
		
		if broadcast and is_instance_valid(realtime_client) and realtime_client.is_connected:
			realtime_client.send_broadcast("card_inserted_into_deck", {
				"card_name": card.name,
				"deck_name": deck.name,
				"to_top": to_top
			})
		
		# อนิมเมจย่อการ์ดหายวาบเข้ากองเด็ค
		var tween = create_tween()
		tween.tween_property(card, "scale", Vector2.ZERO, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(func():
			if is_instance_valid(card):
				card.queue_free()
		)

func _play_shuffle_sfx():
	Global.play_sfx("res://SFX/Draw sfx.ogg", 0.0, 0.8)
	await get_tree().create_timer(0.08).timeout
	Global.play_sfx("res://SFX/Draw sfx.ogg", 0.0, 0.95)
	await get_tree().create_timer(0.08).timeout
	Global.play_sfx("res://SFX/Draw sfx.ogg", 0.0, 1.1)

func _shuffle_deck_programmatically(deck: Control, broadcast: bool = true):
	var draw_pile = deck.get_meta("draw_pile", [])
	if draw_pile.size() > 1:
		draw_pile.shuffle()
		deck.set_meta("draw_pile", draw_pile)
		_play_shuffle_sfx()
		
		if broadcast and is_instance_valid(realtime_client) and realtime_client.is_connected:
			realtime_client.broadcast_deck_shuffled(deck.name)
		
		# เล่น Visual Effect กระพริบเบาๆ
		var original_color = deck.modulate
		var tween = create_tween()
		tween.tween_property(deck, "modulate", Color(0.5, 1.5, 0.5, 1.0), 0.1)
		tween.tween_property(deck, "modulate", original_color, 0.1)

func _shuffle_zone_pile(zone: Control, broadcast: bool = true):
	var cards = []
	for child in zone.get_children():
		if child.has_meta("component_category") and child.get_meta("component_category") in ["card", "deck"]:
			cards.append(child)
			
	if cards.size() > 1:
		cards.shuffle()
		for c in cards:
			zone.remove_child(c)
		for c in cards:
			zone.add_child(c)
			
		for i in range(cards.size()):
			var c = cards[i]
			c.position = (zone.size / 2.0) - (c.size / 2.0)
			
		_play_shuffle_sfx()
		
		if broadcast and is_instance_valid(realtime_client) and realtime_client.is_connected:
			realtime_client.send_broadcast("zone_shuffled", {
				"zone_name": zone.name
			})
			
		var original_color = zone.color
		var tween = create_tween()
		tween.tween_property(zone, "color", Color(0.2, 0.8, 0.2, 0.6), 0.1)
		tween.tween_property(zone, "color", original_color, 0.1)

func _open_deck_peeker(deck: Control):
	peeker_deck_target = deck
	var draw_pile = deck.get_meta("draw_pile", [])
	peeker_prompt_spinbox.max_value = max(1, draw_pile.size())
	peeker_prompt_spinbox.value = min(3, draw_pile.size())
	peeker_prompt_dialog.popup_centered()

func _open_deck_peeker_with_count(deck: Control, count: int):
	peeker_deck_target = deck
	var draw_pile = deck.get_meta("draw_pile", [])
	
	peeker_held_cards.clear()
	for i in range(min(count, draw_pile.size())):
		peeker_held_cards.append(draw_pile.pop_back())
	
	deck.set_meta("draw_pile", draw_pile)
	_update_deck_count_label(deck)
	
	_refresh_peeker_view()
	peeker_dialog.popup_centered()

func _load_card_data_from_path(card_path: String) -> Dictionary:
	var card_data = {}
	if FileAccess.file_exists(card_path):
		var json_str = FileAccess.get_file_as_string(card_path)
		var json = JSON.new()
		if json.parse(json_str) == OK:
			card_data = json.get_data()
			card_data["file_path"] = card_path
	elif SupabaseService.card_cache.has(card_path):
		var row = SupabaseService.card_cache[card_path]
		card_data = row.get("stats", {}).duplicate()
		card_data["name"] = row.get("name", "Untitled")
		card_data["image_path"] = row.get("image_url", "")
		card_data["file_path"] = row.get("id", "")
		card_data["id"] = row.get("id", "")
	return card_data

func _create_peeker_card_node(card_path: String, index: int) -> Control:
	var item = PanelContainer.new()
	item.custom_minimum_size = Vector2(130, 240)
	
	var vb = VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	item.add_child(vb)
	
	var tr = TextureRect.new()
	tr.custom_minimum_size = Vector2(100, 140)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	vb.add_child(tr)
	
	var card_data = _load_card_data_from_path(card_path)
	var card_name = card_data.get("name", "Unknown")
	var img_path = card_data.get("image_path", "")
	
	var tex = null
	if img_path != "":
		if img_path.begins_with("http"):
			SupabaseService.get_texture_or_load(img_path, func(loaded_tex):
				if loaded_tex and is_instance_valid(tr):
					tr.texture = loaded_tex
			)
		elif img_path.begins_with("res://"):
			if ResourceLoader.exists(img_path):
				tex = load(img_path)
		else:
			var img = Image.new()
			if img.load(img_path) == OK:
				tex = ImageTexture.create_from_image(img)
				
	if tex:
		tr.texture = tex
	elif not img_path.begins_with("http"):
		var bg = ColorRect.new()
		bg.color = Color(0.2, 0.2, 0.2, 0.8)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.add_child(bg)
	vb.add_child(tr)
	
	var name_lbl = Label.new()
	name_lbl.text = card_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	vb.add_child(name_lbl)
	
	var hb_move = HBoxContainer.new()
	hb_move.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var btn_left = Button.new()
	btn_left.text = "<"
	btn_left.pressed.connect(func(): _move_peeker_card(index, -1))
	hb_move.add_child(btn_left)
	
	var btn_right = Button.new()
	btn_right.text = ">"
	btn_right.pressed.connect(func(): _move_peeker_card(index, 1))
	hb_move.add_child(btn_right)
	
	vb.add_child(hb_move)
	
	var hb_actions = HBoxContainer.new()
	hb_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var btn_hand = Button.new()
	btn_hand.text = "Hand"
	btn_hand.pressed.connect(func(): _pull_peeker_card_to_hand(index))
	hb_actions.add_child(btn_hand)
	
	var btn_board = Button.new()
	btn_board.text = "Board"
	btn_board.pressed.connect(func(): _pull_peeker_card_to_board(index))
	hb_actions.add_child(btn_board)
	
	vb.add_child(hb_actions)
	return item

func _move_peeker_card(index: int, direction: int):
	var new_index = index + direction
	if new_index >= 0 and new_index < peeker_held_cards.size():
		var temp = peeker_held_cards[index]
		peeker_held_cards[index] = peeker_held_cards[new_index]
		peeker_held_cards[new_index] = temp
		_refresh_peeker_view()

func _pull_peeker_card_to_hand(index: int):
	var card_path = peeker_held_cards[index]
	peeker_held_cards.remove_at(index)
	_refresh_peeker_view()
	
	var card_data = _load_card_data_from_path(card_path)
	if not card_data.is_empty():
		var card = spawn_card_object(card_data, false)
		var field_size = peeker_deck_target.size
		card.custom_minimum_size = field_size
		card.size = field_size
		card.set_meta("field_size", field_size)
		card.set_meta("field_scale", peeker_deck_target.scale)
		card.set_meta("in_hand", true)
		
		card.position = hand_zone.get_global_transform().affine_inverse() * peeker_deck_target.global_position
		_set_card_face_down(card, false)
		hand_zone.add_child(card)
		_update_hand_zone_sizing.call_deferred()

func _pull_peeker_card_to_board(index: int):
	var card_path = peeker_held_cards[index]
	peeker_held_cards.remove_at(index)
	_refresh_peeker_view()
	
	var card_data = _load_card_data_from_path(card_path)
	if not card_data.is_empty():
		var card = spawn_card_object(card_data, true)
		var field_size = peeker_deck_target.size
		var field_scale = peeker_deck_target.get("base_scale")
		if field_scale == null: field_scale = peeker_deck_target.scale
		card.custom_minimum_size = field_size
		card.size = field_size
		card.set_meta("field_size", field_size)
		card.set_meta("field_scale", field_scale)
		if card.has_method("update_base_scale"):
			card.update_base_scale(field_scale)
		else:
			card.scale = field_scale
		card.global_position = peeker_deck_target.global_position + Vector2(180, 0)
		_set_card_face_down(card, false)

func _refresh_peeker_view():
	for child in peeker_cards_container.get_children():
		child.queue_free()
	for i in range(peeker_held_cards.size()):
		var card_path = peeker_held_cards[i]
		var card_node = _create_peeker_card_node(card_path, i)
		peeker_cards_container.add_child(card_node)

func _on_peeker_dialog_confirmed():
	if is_instance_valid(peeker_deck_target):
		var draw_pile = peeker_deck_target.get_meta("draw_pile", [])
		while peeker_held_cards.size() > 0:
			var card_path = peeker_held_cards.pop_back()
			draw_pile.append(card_path)
		peeker_deck_target.set_meta("draw_pile", draw_pile)
		_update_deck_count_label(peeker_deck_target)

func _open_zone_viewer(zone: Control):
	zone_viewer_target = zone
	_refresh_zone_viewer()
	zone_viewer_dialog.popup_centered()

func _refresh_zone_viewer():
	for child in zone_viewer_grid.get_children():
		child.queue_free()
		
	if not is_instance_valid(zone_viewer_target): return
	
	var cards_in_zone = []
	for child in zone_viewer_target.get_children():
		if child.has_meta("component_category") and child.get_meta("component_category") in ["card", "deck"]:
			cards_in_zone.append(child)
			
	for card in cards_in_zone:
		var item = PanelContainer.new()
		item.custom_minimum_size = Vector2(120, 200)
		
		var vb = VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		item.add_child(vb)
		
		var tr = TextureRect.new()
		tr.custom_minimum_size = Vector2(90, 126)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		if card is TextureRect and card.texture:
			tr.texture = card.texture
		else:
			var bg = ColorRect.new()
			bg.color = Color(0.2, 0.2, 0.2, 0.8)
			bg.set_anchors_preset(Control.PRESET_FULL_RECT)
			tr.add_child(bg)
		vb.add_child(tr)
		
		var card_name = "Unknown Card"
		var card_data = card.get_meta("card_data", {})
		if card_data.has("name"):
			card_name = card_data["name"]
			
		var name_lbl = Label.new()
		name_lbl.text = card_name
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		vb.add_child(name_lbl)
		
		var hb = HBoxContainer.new()
		hb.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var btn_hand = Button.new()
		btn_hand.text = "Hand"
		btn_hand.pressed.connect(func():
			_pull_card_from_zone_to_hand(card)
		)
		hb.add_child(btn_hand)
		
		var btn_board = Button.new()
		btn_board.text = "Board"
		btn_board.pressed.connect(func():
			_pull_card_from_zone_to_board(card)
		)
		hb.add_child(btn_board)
		vb.add_child(hb)
		
		zone_viewer_grid.add_child(item)

func _pull_card_from_zone_to_hand(card: Control):
	if is_instance_valid(card):
		_add_card_to_hand(card)
		_organize_remaining_zone_cards(zone_viewer_target)
		_refresh_zone_viewer()

func _pull_card_from_zone_to_board(card: Control):
	if is_instance_valid(card):
		if card.get_parent():
			card.get_parent().remove_child(card)
		field_canvas.add_child(card)
		card.global_position = get_viewport().size / 2.0 - card.size / 2.0
		_apply_card_size(card, field_canvas, null)
		card.set_meta("in_hand", false)
		
		_organize_remaining_zone_cards(zone_viewer_target)
		_refresh_zone_viewer()

func _organize_remaining_zone_cards(zone: Control):
	if not is_instance_valid(zone): return
	var cards = []
	for child in zone.get_children():
		if child.has_meta("component_category") and child.get_meta("component_category") in ["card", "deck"]:
			cards.append(child)
	for c in cards:
		c.position = (zone.size / 2.0) - (c.size / 2.0)

func _close_deck_viewer_keep_card():
	# ปิด deck viewer แต่ไม่แตะการ์ดที่ยังลากอยู่
	# เอาการ์ดที่กำลัง insert ออกจาก deck_viewer_cards (ถ้ามี)
	if inserting_card_index >= 0 and inserting_card_index < deck_viewer_cards.size():
		deck_viewer_cards.remove_at(inserting_card_index)
	
	deck_viewer_inserting_card = null
	deck_viewer_dragging_card = null
	deck_viewer_has_entered = false
	deck_viewer_target = null
	deck_viewer_cards.clear()
	inserting_card_index = -1
	deck_viewer_selected_index = -1
	deck_viewer_dragging_index = -1
	if is_instance_valid(deck_viewer_drag_preview):
		deck_viewer_drag_preview.queue_free()
	deck_viewer_drag_preview = null
	deck_viewer_grid.set_insert_indicator(-1)
	
	deck_viewer_dialog.hide()

func _center_deck_viewer_panel():
	deck_viewer_dialog.show()
	await get_tree().process_frame
	var viewport_size = get_viewport_rect().size
	deck_viewer_dialog.position = (viewport_size - deck_viewer_dialog.size) / 2.0

func _open_deck_viewer(deck: Control):
	deck_viewer_target = deck
	deck_viewer_inserting_card = null
	inserting_card_index = -1
	deck_viewer_cards = deck.get_meta("draw_pile", []).duplicate()
	_refresh_deck_viewer()
	_center_deck_viewer_panel()

func _open_deck_viewer_for_insertion(deck: Control, card: Control):
	deck_viewer_target = deck
	deck_viewer_inserting_card = card
	deck_viewer_dragging_card = card  # track การ์ดที่ยังลากอยู่
	deck_viewer_has_entered = false   # รีเซ็ตสถานะการลากเมาส์เข้ามาในพาเนล
	
	# ไม่ซ่อนการ์ด — การ์ดยังลากอยู่ตามปกติ
	
	deck_viewer_cards = deck.get_meta("draw_pile", []).duplicate()
	
	var card_data = card.get_meta("card_data", {})
	var card_path = card_data.get("file_path", "")
	if card_path == "":
		card_path = card_data.get("image_path", "")
		
	# ไม่เพิ่มการ์ดลงใน array จนกว่าจะปล่อยเมาส์
	inserting_card_index = -1
	
	_refresh_deck_viewer()
	# สมมติตำแหน่งเริ่มต้น
	deck_viewer_grid.set_insert_indicator(deck_viewer_cards.size())
	_center_deck_viewer_panel()

func _on_deck_viewer_confirmed():
	if is_instance_valid(deck_viewer_target):
		deck_viewer_target.set_meta("draw_pile", deck_viewer_cards.duplicate())
		_update_deck_count_label(deck_viewer_target)
		if is_instance_valid(deck_viewer_inserting_card):
			deck_viewer_inserting_card.queue_free()
			
	deck_viewer_inserting_card = null
	deck_viewer_target = null
	deck_viewer_cards.clear()
	inserting_card_index = -1
	deck_viewer_selected_index = -1
	deck_viewer_dragging_index = -1
	deck_viewer_dragged_card_path = ""
	deck_viewer_dragged_item = null
	if is_instance_valid(deck_viewer_drag_preview):
		deck_viewer_drag_preview.queue_free()
	deck_viewer_drag_preview = null
	deck_viewer_grid.set_insert_indicator(-1)
	deck_viewer_dialog.hide()

func _on_deck_viewer_canceled():
	# ถ้ายังลากอยู่ ไม่ต้องทำอะไรกับการ์ด (มันยังลอยอยู่กับ mouse)
	# ถ้าไม่ได้ลาก (เปิด viewer ด้วย right-click menu แล้ว cancel) ให้คืนการ์ดไปมือ
	if is_instance_valid(deck_viewer_inserting_card):
		if not deck_viewer_inserting_card.get("dragging"):
			deck_viewer_inserting_card.show()
			_add_card_to_hand(deck_viewer_inserting_card)
		
	deck_viewer_inserting_card = null
	deck_viewer_dragging_card = null
	deck_viewer_target = null
	deck_viewer_cards.clear()
	inserting_card_index = -1
	deck_viewer_selected_index = -1
	deck_viewer_dragging_index = -1
	deck_viewer_dragged_card_path = ""
	deck_viewer_dragged_item = null
	if is_instance_valid(deck_viewer_drag_preview):
		deck_viewer_drag_preview.queue_free()
	deck_viewer_drag_preview = null
	deck_viewer_grid.set_insert_indicator(-1)

func _refresh_deck_viewer():
	for child in deck_viewer_grid.get_children():
		child.queue_free()
		
	if not is_instance_valid(deck_viewer_target): return
	
	for i in range(deck_viewer_cards.size()):
		var card_path = deck_viewer_cards[i]
		var is_inserting = false
		if is_instance_valid(deck_viewer_inserting_card) and i == inserting_card_index:
			is_inserting = true
			
		var card_node = _create_deck_viewer_card_node(card_path, i, is_inserting)
		deck_viewer_grid.add_child(card_node)
		
	if deck_viewer_grid.has_method("update_layout"):
		deck_viewer_grid.update_layout(false)

func _update_deck_viewer_labels():
	var children = deck_viewer_grid.get_children()
	var total_size = children.size()
	for i in range(total_size):
		var child = children[i]
		if "card_index" in child:
			child.card_index = i
		var vb = child.get_node_or_null("VBox")
		if vb:
			var lbl = vb.get_node_or_null("OrderLabel")
			if lbl is Label:
				var text = "Card %d" % (i + 1)
				if is_instance_valid(deck_viewer_inserting_card) and i == inserting_card_index:
					text += " [NEW]"
				if i == 0:
					text += " (Bottom)"
				elif i == total_size - 1:
					text += " (Top)"
				lbl.text = text

func _create_deck_viewer_card_node(card_path: String, index: int, is_inserting: bool = false) -> Control:
	var item = PanelContainer.new()
	item.set_script(load("res://scripts/DeckViewerCardItem.gd"))
	item.card_index = index
	item.deck_viewer_ref = self
	item.custom_minimum_size = Vector2(140, 260)
	
	if is_inserting or index == deck_viewer_selected_index:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.25, 0.25, 0.1, 0.8) # Goldish tint
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.border_color = Color(1.0, 0.85, 0.2, 1.0) # Gold border
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		item.add_theme_stylebox_override("panel", style)
		
	var vb = VBoxContainer.new()
	vb.name = "VBox"
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_PASS
	item.add_child(vb)
	
	var order_lbl = Label.new()
	order_lbl.name = "OrderLabel"
	order_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var total_size = deck_viewer_cards.size()
	order_lbl.text = "Card %d" % (index + 1)
	if is_inserting:
		order_lbl.text += " [NEW]"
	if index == 0:
		order_lbl.text += " (Bottom)"
	elif index == total_size - 1:
		order_lbl.text += " (Top)"
	order_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	order_lbl.add_theme_font_size_override("font_size", 12)
	vb.add_child(order_lbl)
	
	var tr = TextureRect.new()
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.custom_minimum_size = Vector2(100, 140)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	vb.add_child(tr)
	
	var card_data = _load_card_data_from_path(card_path)
	var card_name = card_data.get("name", "Unknown")
	var img_path = card_data.get("image_path", "")
	
	var tex = null
	if img_path != "":
		if img_path.begins_with("http"):
			SupabaseService.get_texture_or_load(img_path, func(loaded_tex):
				if loaded_tex and is_instance_valid(tr):
					tr.texture = loaded_tex
			)
		elif img_path.begins_with("res://"):
			if ResourceLoader.exists(img_path):
				tex = load(img_path)
		else:
			var img = Image.new()
			if img.load(img_path) == OK:
				tex = ImageTexture.create_from_image(img)
				
	if tex:
		tr.texture = tex
	elif not img_path.begins_with("http"):
		var bg = ColorRect.new()
		bg.color = Color(0.2, 0.2, 0.2, 0.8)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.add_child(bg)
		
	var name_lbl = Label.new()
	name_lbl.text = card_name
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.add_theme_font_size_override("font_size", 12)
	vb.add_child(name_lbl)
	
	# Move buttons
	var hb_move = HBoxContainer.new()
	hb_move.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var btn_left = Button.new()
	btn_left.text = "<"
	btn_left.pressed.connect(func():
		Global.play_sfx("res://SFX/Draw sfx.ogg", -8.0, 1.8)
		_move_deck_viewer_card(index, -1)
	)
	hb_move.add_child(btn_left)
	
	var btn_right = Button.new()
	btn_right.text = ">"
	btn_right.pressed.connect(func():
		Global.play_sfx("res://SFX/Draw sfx.ogg", -8.0, 1.8)
		_move_deck_viewer_card(index, 1)
	)
	hb_move.add_child(btn_right)
	
	vb.add_child(hb_move)
	
	var hb_actions = HBoxContainer.new()
	hb_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var btn_hand = Button.new()
	btn_hand.text = "Hand"
	btn_hand.pressed.connect(func():
		Global.play_sfx("res://SFX/Draw sfx.ogg", -3.0, 1.2)
		_pull_deck_viewer_card_to_hand(index)
	)
	hb_actions.add_child(btn_hand)
	
	var btn_board = Button.new()
	btn_board.text = "Board"
	btn_board.pressed.connect(func():
		Global.play_sfx("res://SFX/Draw sfx.ogg", -3.0, 1.2)
		_pull_deck_viewer_card_to_board(index)
	)
	hb_actions.add_child(btn_board)
	
	vb.add_child(hb_actions)
	return item

func _move_deck_viewer_card(index: int, direction: int):
	var new_index = index + direction
	if new_index >= 0 and new_index < deck_viewer_cards.size():
		var temp = deck_viewer_cards[index]
		deck_viewer_cards[index] = deck_viewer_cards[new_index]
		deck_viewer_cards[new_index] = temp
		
		# If we are moving the inserting card, update its index
		if index == inserting_card_index:
			inserting_card_index = new_index
		elif new_index == inserting_card_index:
			inserting_card_index = index
			
		_refresh_deck_viewer()

func _reorder_deck_viewer_card(from_idx: int, to_idx: int):
	to_idx = clamp(to_idx, 0, deck_viewer_cards.size())
	if from_idx == to_idx:
		return
		
	var item = deck_viewer_cards[from_idx]
	deck_viewer_cards.remove_at(from_idx)
	
	var dest_idx = to_idx
	if from_idx < to_idx:
		dest_idx -= 1
		
	deck_viewer_cards.insert(dest_idx, item)
	
	# Update inserting_card_index
	if from_idx == inserting_card_index:
		inserting_card_index = dest_idx
	elif inserting_card_index > from_idx and inserting_card_index <= dest_idx:
		inserting_card_index -= 1
	elif inserting_card_index < from_idx and inserting_card_index >= dest_idx:
		inserting_card_index += 1
		
	# Move the actual child node in the UI to match the array without destroying all nodes
	if from_idx < deck_viewer_grid.get_child_count():
		var child_node = deck_viewer_grid.get_child(from_idx)
		deck_viewer_grid.move_child(child_node, dest_idx)
	
	_update_deck_viewer_labels()
	
	# ปล่อยให้มันเล่น animate อัตโนมัติ (ข้าม skip_index = -1 เพื่อเปิดโชว์ใหม่)
	deck_viewer_grid.update_layout(true, -1)

func _get_drop_index_at_global_position(global_pos: Vector2) -> int:
	var all_children = deck_viewer_grid.get_children()
	var children = []
	for c in all_children:
		if c is Control and c.visible and not c.is_queued_for_deletion():
			children.append(c)
			
	if children.is_empty():
		return 0
		
	var columns = deck_viewer_grid.columns
	var num_children = children.size()
	var row_count = int(ceil(num_children / float(columns)))
	
	# 1. Detect which row the global_pos.y falls into
	var target_row = 0
	for r in range(row_count):
		var start_idx = r * columns
		if start_idx >= num_children:
			break
		var row_child = children[start_idx]
		if not row_child is Control: continue
		var rect = row_child.get_global_rect()
		
		# If there is a next row, check the boundary midpoint
		var next_row_start_idx = (r + 1) * columns
		if next_row_start_idx < num_children:
			var next_row_child = children[next_row_start_idx]
			if next_row_child is Control:
				var next_rect = next_row_child.get_global_rect()
				var midpoint_y = (rect.position.y + rect.size.y + next_rect.position.y) / 2.0
				if global_pos.y < midpoint_y:
					target_row = r
					break
			else:
				if global_pos.y < rect.position.y + rect.size.y + 7.5: # 7.5 is half of v_separation (15)
					target_row = r
					break
		else:
			# Last row
			target_row = r
			break
			
	# 2. Within target_row, find the column based on global_pos.x
	var row_start_idx = target_row * columns
	var row_end_idx = min(num_children, (target_row + 1) * columns)
	
	for i in range(row_start_idx, row_end_idx):
		var child = children[i]
		if not child is Control: continue
		var rect = child.get_global_rect()
		if global_pos.x < rect.position.x + rect.size.x / 2.0:
			return i
			
	return row_end_idx

func _on_dv_card_clicked(index: int):
	deck_viewer_selected_index = index
	_refresh_deck_viewer()

func _on_dv_card_drag_started(index: int):
	deck_viewer_selected_index = index
	deck_viewer_dragging_index = index
	
	deck_viewer_dragged_card_path = deck_viewer_cards[index]
	
	var original_item = deck_viewer_grid.get_child(index)
	deck_viewer_dragged_item = original_item
	
	# Create drag preview (ภาพลอยตามเมาส์)
	if is_instance_valid(deck_viewer_drag_preview):
		deck_viewer_drag_preview.queue_free()
	
	var preview = original_item.duplicate()
	preview.set_script(null)
	_set_mouse_filter_ignore_recursive(preview)
	
	preview.custom_minimum_size = original_item.custom_minimum_size
	preview.size = original_item.custom_minimum_size
	preview.top_level = true
	preview.z_index = 2500
	
	add_child(preview)
	preview.global_position = get_global_mouse_position() - preview.custom_minimum_size / 2.0
	deck_viewer_drag_preview = preview
	
	# นำข้อมูลการ์ดออกจากอาเรย์เพื่อคิดตำแหน่งการแทรกใหม่แบบแรกรอบ
	deck_viewer_cards.remove_at(index)
	
	# ซ่อนโหนดการ์ดเดิม (ไม่ลบออกจาก Scene Tree เพื่อรักษา Input Capture) 
	# แล้วเลื่อนการ์ดอื่นๆ ข้างๆ เข้ามาแทนที่
	deck_viewer_grid.update_layout(true, index)

func _on_dv_card_drag_moved(global_pos: Vector2):
	if is_instance_valid(deck_viewer_drag_preview):
		deck_viewer_drag_preview.global_position = global_pos - deck_viewer_drag_preview.custom_minimum_size / 2.0
		
	var target_idx = _get_drop_index_at_global_position(global_pos)
	deck_viewer_grid.set_insert_indicator(target_idx)

func _on_dv_card_drag_ended(index: int):
	if is_instance_valid(deck_viewer_drag_preview):
		deck_viewer_drag_preview.queue_free()
		deck_viewer_drag_preview = null
		
	var target_idx = deck_viewer_grid.insert_indicator_index
	deck_viewer_grid.set_insert_indicator(-1)
	
	if target_idx == -1:
		target_idx = _get_drop_index_at_global_position(get_global_mouse_position())
		
	target_idx = clamp(target_idx, 0, deck_viewer_cards.size())
	
	deck_viewer_cards.insert(target_idx, deck_viewer_dragged_card_path)
	
	# ดึงโหนดการ์ดเดิม ย้ายตำแหน่งในตาราง และแสดงให้เห็นอีกครั้ง
	if is_instance_valid(deck_viewer_dragged_item):
		deck_viewer_dragged_item.visible = true
		deck_viewer_grid.move_child(deck_viewer_dragged_item, target_idx)
		deck_viewer_dragged_item.position = deck_viewer_grid.get_local_mouse_position()
	
	_update_deck_viewer_labels()
	deck_viewer_grid.update_layout(true)
	
	deck_viewer_dragging_index = -1
	deck_viewer_dragged_card_path = ""
	deck_viewer_dragged_item = null

func _on_dv_card_drag_scrolled(button_index: int):
	if not is_instance_valid(deck_viewer_scroll): return
	
	var scroll_speed = 30.0
	if button_index == MOUSE_BUTTON_WHEEL_UP:
		deck_viewer_scroll.scroll_vertical -= scroll_speed
	elif button_index == MOUSE_BUTTON_WHEEL_DOWN:
		deck_viewer_scroll.scroll_vertical += scroll_speed
		
	if is_instance_valid(deck_viewer_dragging_card):
		_on_card_drag_moved(deck_viewer_dragging_card)
	else:
		_on_dv_card_drag_moved(get_global_mouse_position())

func _on_tabletop_card_drag_scrolled(card: Control, button_index: int):
	if is_instance_valid(deck_viewer_dialog) and deck_viewer_dialog.visible and deck_viewer_dragging_card == card:
		_on_dv_card_drag_scrolled(button_index)

func _set_mouse_filter_ignore_recursive(node: Node):
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_filter_ignore_recursive(child)

func _notification(what: int):
	pass


func _pull_deck_viewer_card_to_hand(index: int):
	var card_path = deck_viewer_cards[index]
	deck_viewer_cards.remove_at(index)
	
	# Adjust inserting card index
	if index == inserting_card_index:
		if is_instance_valid(deck_viewer_inserting_card):
			deck_viewer_inserting_card.queue_free()
		deck_viewer_inserting_card = null
		inserting_card_index = -1
	elif index < inserting_card_index:
		inserting_card_index -= 1
		
	_refresh_deck_viewer()
	
	var card_data = _load_card_data_from_path(card_path)
	if not card_data.is_empty():
		var card = spawn_card_object(card_data, false)
		var field_size = deck_viewer_target.size
		card.custom_minimum_size = field_size
		card.size = field_size
		card.set_meta("field_size", field_size)
		card.set_meta("field_scale", deck_viewer_target.scale)
		card.set_meta("in_hand", true)
		
		card.position = hand_zone.get_global_transform().affine_inverse() * deck_viewer_target.global_position
		_set_card_face_down(card, false)
		hand_zone.add_child(card)
		_update_hand_zone_sizing.call_deferred()

func _pull_deck_viewer_card_to_board(index: int):
	var card_path = deck_viewer_cards[index]
	deck_viewer_cards.remove_at(index)
	
	# Adjust inserting card index
	if index == inserting_card_index:
		if is_instance_valid(deck_viewer_inserting_card):
			deck_viewer_inserting_card.queue_free()
		deck_viewer_inserting_card = null
		inserting_card_index = -1
	elif index < inserting_card_index:
		inserting_card_index -= 1
		
	_refresh_deck_viewer()
	
	var card_data = _load_card_data_from_path(card_path)
	if not card_data.is_empty():
		var card = spawn_card_object(card_data, true)
		var field_size = deck_viewer_target.size
		var field_scale = deck_viewer_target.get("base_scale")
		if field_scale == null: field_scale = deck_viewer_target.scale
		card.custom_minimum_size = field_size
		card.size = field_size
		card.set_meta("field_size", field_size)
		card.set_meta("field_scale", field_scale)
		if card.has_method("update_base_scale"):
			card.update_base_scale(field_scale)
		else:
			card.scale = field_scale
		card.global_position = deck_viewer_target.global_position + Vector2(180, 0)
		_set_card_face_down(card, false)

# ==========================================
# Global Drop Data (Extracting from Deck Viewer)
# ==========================================

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY and data.get("type") == "deck_viewer_card":
		return true
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if typeof(data) == TYPE_DICTIONARY and data.get("type") == "deck_viewer_card":
		var index = data.get("index", -1)
		if index >= 0 and index < deck_viewer_cards.size():
			var card_path = deck_viewer_cards[index]
			deck_viewer_cards.remove_at(index)
			
			var card_data = {}
			if FileAccess.file_exists(card_path):
				var json_str = FileAccess.get_file_as_string(card_path)
				var json = JSON.new()
				if json.parse(json_str) == OK:
					card_data = json.get_data()
					card_data["file_path"] = card_path
			else:
				if SupabaseService.card_cache.has(card_path):
					var row = SupabaseService.card_cache[card_path]
					card_data = row.get("stats", {}).duplicate()
					card_data["name"] = row.get("name", "Untitled")
					card_data["image_path"] = row.get("image_url", "")
					card_data["file_path"] = row.get("id", "")
					card_data["id"] = row.get("id", "")
					
			var new_card = spawn_card_object(card_data, false)
			if new_card:
				var field_size = Vector2(150, 210)
				if is_instance_valid(deck_viewer_target):
					field_size = deck_viewer_target.size
					var field_scale = deck_viewer_target.get("base_scale")
					if field_scale == null: field_scale = deck_viewer_target.scale
					new_card.set_meta("field_size", field_size)
					new_card.set_meta("field_scale", field_scale)
					
				new_card.custom_minimum_size = field_size
				new_card.size = field_size
				new_card.scale = Vector2.ONE
				
				# ตรวจสอบว่าดรอปในมือหรือไม่
				if hand_scroll and hand_scroll.visible and hand_scroll.get_global_rect().has_point(get_global_mouse_position()):
					new_card.set_meta("in_hand", true)
					hand_zone.add_child(new_card)
					_update_hand_zone_sizing.call_deferred()
				else:
					new_card.set_meta("in_hand", false)
					field_canvas.add_child(new_card)
					new_card.global_position = get_global_mouse_position() - (new_card.size / 2.0)
					_apply_card_size(new_card, field_canvas, null)
					
			var child_node = deck_viewer_grid.get_child(index)
			if child_node: child_node.queue_free()
			
			_update_deck_viewer_labels()
			if deck_viewer_grid.has_method("update_layout"):
				deck_viewer_grid.update_layout(true)

# --- ONLINE MULTIPLAYER REALTIME RECEIVERS ---
func _on_remote_card_moved(card_name: String, pos: Vector2):
	var node = field_canvas.find_child(card_name, true, false)
	if is_instance_valid(node):
		node.position = pos

func _on_remote_card_flipped(card_name: String, is_down: bool):
	var node = field_canvas.find_child(card_name, true, false)
	if is_instance_valid(node):
		_set_card_face_down(node, is_down, false)

func _on_remote_card_tapped(card_name: String, tapped: bool):
	var node = field_canvas.find_child(card_name, true, false)
	if is_instance_valid(node):
		var current_rot = node.rotation_degrees
		var current_tapped = abs(current_rot) >= 45.0
		if current_tapped != tapped:
			_toggle_card_tap(node, false)

func _on_remote_deck_shuffled(deck_name: String):
	var node = field_canvas.find_child(deck_name, true, false)
	if is_instance_valid(node):
		_shuffle_deck_programmatically(node, false)

func _on_remote_card_spawned(card_name: String, card_data: Dictionary, pos: Vector2):
	var node = self.find_child(card_name, true, false)
	if is_instance_valid(node):
		if node.get_parent() != field_canvas:
			node.get_parent().remove_child(node)
			field_canvas.add_child(node)
			_apply_card_size(node, field_canvas, null)
		node.position = pos
	else:
		var new_card = spawn_card_object(card_data, true)
		if new_card:
			new_card.name = card_name
			new_card.position = pos

func _on_remote_card_sent_to_hand(card_name: String):
	var node = field_canvas.find_child(card_name, true, false)
	if is_instance_valid(node) and is_instance_valid(opponent_hand_box):
		if node.get_parent():
			node.get_parent().remove_child(node)
		opponent_hand_box.add_child(node)
		_set_card_face_down(node, true, false)
		node.custom_minimum_size = Vector2(70, 100)
		node.scale = Vector2.ONE
		node.rotation_degrees = 0
		var htween = node.get("hover_tween")
		if htween and htween is Tween: htween.kill()
		node.set("is_hovering", false)
	elif is_instance_valid(node):
		node.queue_free()

func _on_remote_card_inserted_into_deck(card_name: String, deck_name: String, to_top: bool):
	var card = field_canvas.find_child(card_name, true, false)
	var deck = field_canvas.find_child(deck_name, true, false)
	if is_instance_valid(card) and is_instance_valid(deck):
		_insert_card_into_deck(card, deck, to_top, false)

func _on_remote_deck_drawn(deck_name: String):
	var deck = field_canvas.find_child(deck_name, true, false)
	if is_instance_valid(deck):
		var draw_pile = deck.get_meta("draw_pile", [])
		if not draw_pile.is_empty():
			draw_pile.pop_back()
			deck.set_meta("draw_pile", draw_pile)
			_update_deck_count_label(deck)

func _on_remote_zone_shuffled(zone_name: String):
	var zone = field_canvas.find_child(zone_name, true, false)
	if is_instance_valid(zone):
		_shuffle_zone_pile(zone, false)

func _init_opponent_hand():
	var scroll = ScrollContainer.new()
	scroll.name = "OpponentHandScroll"
	scroll.set_anchors_preset(Control.PRESET_TOP_WIDE)
	scroll.custom_minimum_size = Vector2(0, 140)
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.z_index = 10
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.add_child(bg)
	
	opponent_hand_box = HBoxContainer.new()
	opponent_hand_box.name = "OpponentHandZone"
	opponent_hand_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	opponent_hand_box.alignment = BoxContainer.ALIGNMENT_CENTER
	opponent_hand_box.add_theme_constant_override("separation", 10)
	scroll.add_child(opponent_hand_box)
	
	add_child(scroll)
	
	if Global.online_room_id == "":
		scroll.hide()
>>>>>>> Stashed changes
