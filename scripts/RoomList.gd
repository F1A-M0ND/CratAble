extends Control

@onready var creator_panel = $RoomCreatorPanel
@onready var mode_selection_ui = $ModeSelection
@onready var local_card = $ModeSelection/HBoxContainer/LocalCard
@onready var online_card = $ModeSelection/HBoxContainer/OnlineCard
@onready var header = $Header
@onready var scroll_container = $ScrollContainer

# Player Count UI elements
@onready var player_count_container = $RoomCreatorPanel/VBoxContainer/PlayerCountContainer
@onready var btn1 = $RoomCreatorPanel/VBoxContainer/PlayerCountContainer/Btn1
@onready var btn2 = $RoomCreatorPanel/VBoxContainer/PlayerCountContainer/Btn2
@onready var count_spin = $RoomCreatorPanel/VBoxContainer/PlayerCountContainer/CountSpin

var field_file_dialog: FileDialog

var is_online_mode: bool = false

# Online cache and popups
var online_field_popup: ConfirmationDialog
var online_field_list: ItemList
var online_fields_cache = []

func _ready():
	call_deferred("_apply_platform_style")
	$Header/CreateBtn.pressed.connect(_on_create_room_pressed)
	var back_button := Button.new()
	back_button.text = "← เลือกโหมด"
	back_button.pressed.connect(func():
		header.hide()
		scroll_container.hide()
		creator_panel.hide()
		mode_selection_ui.show()
	)
	header.add_child(back_button)
	header.move_child(back_button, 0)
	var refresh_button := Button.new()
	refresh_button.text = "รีเฟรช"
	refresh_button.pressed.connect(_refresh_online_rooms)
	header.add_child(refresh_button)
	header.add_theme_constant_override("separation", 18)
	$ScrollContainer/VBoxContainer.add_theme_constant_override("separation", 14)
	$RoomCreatorPanel/VBoxContainer/ConfirmBtn.pressed.connect(_on_confirm_create_pressed)
	$RoomCreatorPanel/VBoxContainer/CancelBtn.pressed.connect(_on_close_creator_pressed)
	
	# Connect Selection buttons in creator panel
	$RoomCreatorPanel/VBoxContainer/FieldBtn.pressed.connect(_on_select_field_pressed)
	
	local_card.pressed.connect(_on_local_mode_selected)
	online_card.pressed.connect(_on_online_mode_selected)
	
	# Connect player count quick buttons
	btn1.pressed.connect(func(): count_spin.value = 1)
	btn2.pressed.connect(func(): count_spin.value = 2)
	count_spin.value_changed.connect(_on_player_count_changed)
	
	# Clear selection variables when arriving at Lobby
	Global.play_mode = false
	Global.loaded_field_path = ""
	Global.selected_deck_path = ""
	Global.loaded_field_data = {}
	Global.selected_deck_data = {}
	Global.local_player_count = 1
	Global.local_active_player_idx = 0
	
	# Initialize dialogs
	_init_online_dialogs()
	_init_local_dialogs()
	
	# Show Mode Selection UI by default, hide room lists
	mode_selection_ui.show()
	header.hide()
	scroll_container.hide()
	creator_panel.hide()
	
	# Apply premium styles
	_apply_card_styles()
	_apply_creator_panel_styles()
	
	preload("res://scripts/ChooserDesign.gd").heading(mode_selection_ui, "PLAY YOUR WAY", "YOUR TABLE. YOUR RULES.", "ทดลองไอเดียในเครื่อง หรือชวนเพื่อนมาเล่นด้วยกันออนไลน์")

func _on_local_mode_selected():
	Global.reset_online_session()
	is_online_mode = false
	mode_selection_ui.hide()
	
	# Reset/Setup creator panel for local play
	$RoomCreatorPanel/VBoxContainer/Title.text = "LOCAL PLAY"
	$RoomCreatorPanel/VBoxContainer/ConfirmBtn.text = "เริ่มเล่น"
	$RoomCreatorPanel/VBoxContainer/FieldBtn.text = "เลือกสนามในเครื่อง"
	creator_panel.offset_top = -240
	creator_panel.offset_bottom = 240
	
	# Hide Password, Desc, and RoomName for local mode
	$RoomCreatorPanel/VBoxContainer/Password.hide()
	$RoomCreatorPanel/VBoxContainer/Desc.hide()
	$RoomCreatorPanel/VBoxContainer/RoomName.hide()
	
	# Show player count UI
	player_count_container.show()
	count_spin.value = 1
	
	creator_panel.show()

func _on_online_mode_selected():
	is_online_mode = true
	mode_selection_ui.hide()
	header.show()
	scroll_container.show()
	_refresh_online_rooms()

func _refresh_online_rooms():
	for child in $ScrollContainer/VBoxContainer.get_children():
		child.queue_free()
		
	var loading_lbl = Label.new()
	loading_lbl.text = "กำลังค้นหาห้องออนไลน์…"
	loading_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$ScrollContainer/VBoxContainer.add_child(loading_lbl)
	
	SupabaseService.fetch_active_rooms(func(status, data):
		if not is_instance_valid(self): return
		for child in $ScrollContainer/VBoxContainer.get_children():
			child.queue_free()
			
		if status == 200 and typeof(data) == TYPE_ARRAY:
			if data.is_empty():
				var no_rooms_lbl = Label.new()
				no_rooms_lbl.text = "ยังไม่มีห้องเปิดอยู่\nสร้างห้อง แล้วชวนเพื่อนเข้ามาเล่นได้เลย"
				no_rooms_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				$ScrollContainer/VBoxContainer.add_child(no_rooms_lbl)
				return
				
			for room in data:
				var btn = Button.new()
				btn.text = "%s    /    %s    → เข้าห้อง" % [room.get("name", "Untitled"), room.get("status", "waiting")]
				btn.custom_minimum_size.y = 80
				btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
				btn.add_theme_font_size_override("font_size", 24)
				
				var btn_style = StyleBoxFlat.new()
				btn_style.bg_color = Color("131f39")
				btn_style.set_corner_radius_all(18)
				btn_style.set_border_width_all(1)
				btn_style.border_color = Color(0.5, 0.75, 1.0, 0.22)
				btn_style.content_margin_left = 28
				btn_style.content_margin_right = 28
				preload("res://scripts/PlatformStyle.gd")._style_controls(btn)
				btn.add_theme_stylebox_override("normal", btn_style)
				
				btn.pressed.connect(func(): _on_join_room_clicked(room))
				$ScrollContainer/VBoxContainer.add_child(btn)
		else:
			var err_lbl = Label.new()
			err_lbl.text = "Online room server update is required." if status == 404 else "Error loading rooms from Supabase."
			err_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			$ScrollContainer/VBoxContainer.add_child(err_lbl)
	)

var joining_room = false

func _on_join_room_clicked(room: Dictionary):
	if joining_room: return
	if room.get("has_password", false):
		var dialog = ConfirmationDialog.new()
		dialog.title = "Room password"
		var input = LineEdit.new()
		input.secret = true
		input.placeholder_text = "Password"
		input.custom_minimum_size = Vector2(300, 40)
		dialog.add_child(input)
		dialog.confirmed.connect(func():
			_join_room_with_password(room, input.text)
			dialog.queue_free()
		)
		dialog.canceled.connect(dialog.queue_free)
		add_child(dialog)
		dialog.popup_centered()
		input.grab_focus()
	else:
		_join_room_with_password(room, "")

func _join_room_with_password(room: Dictionary, password: String):
	if joining_room: return
	joining_room = true
	var guest_name = "Guest_" + str(randi() % 1000)
	SupabaseService.join_room(room.get("id", ""), guest_name, func(status, res):
		if not is_instance_valid(self): return
		joining_room = false
		if status == 200 and res is Dictionary and res.get("id", "") != "":
			Global.online_room_id = res["id"]
			Global.online_room_data = res
			Global.online_player_role = "Guest"
			Global.online_player_name = guest_name
			Global.loaded_field_data = res.get("field_data", {}) if res.get("field_data") is Dictionary else {}
			Global.selected_deck_data = res.get("deck_data", {}) if res.get("deck_data") is Dictionary else {}
			Global.play_mode = true
			Global.switch_scene("res://SCENE/Main.tscn")
		else:
			var err = AcceptDialog.new()
			err.title = "Join Failed"
			err.dialog_text = "Unable to join: check the password and room availability."
			if status == 404: err.dialog_text = "Online room server update is required."
			add_child(err)
			err.popup_centered()
	, password)

func _on_create_room_pressed():
	# Show creator panel for online room
	$RoomCreatorPanel/VBoxContainer/Title.text = "CREATE A ROOM"
	$RoomCreatorPanel/VBoxContainer/ConfirmBtn.text = "สร้างห้อง"
	$RoomCreatorPanel/VBoxContainer/FieldBtn.text = "เลือกสนาม"
	creator_panel.offset_top = -335
	creator_panel.offset_bottom = 335
	
	# Show inputs for online mode
	$RoomCreatorPanel/VBoxContainer/Password.show()
	$RoomCreatorPanel/VBoxContainer/Desc.show()
	$RoomCreatorPanel/VBoxContainer/RoomName.show()
	
	# Hide player count UI for online mode (handled by online lobby)
	player_count_container.hide()
	
	creator_panel.show()

func _on_close_creator_pressed():
	creator_panel.hide()
	if is_online_mode:
		# Return to online room list
		header.show()
		scroll_container.show()
	else:
		# Return to Mode Selection UI
		mode_selection_ui.show()
		header.hide()
		scroll_container.hide()
		# Clean up selections
		Global.loaded_field_path = ""
		Global.selected_deck_path = ""

func _init_local_dialogs():
	field_file_dialog = FileDialog.new()
	field_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	field_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	field_file_dialog.filters = PackedStringArray(["*.json ; Field Layout Files"])
	field_file_dialog.size = Vector2(600, 400)
	field_file_dialog.use_native_dialog = true
	field_file_dialog.file_selected.connect(_on_local_field_selected)
	add_child(field_file_dialog)

func _on_local_field_selected(path: String):
	Global.loaded_field_path = path
	Global.loaded_field_data = {} # Clear online
	$RoomCreatorPanel/VBoxContainer/FieldBtn.text = "Field: " + path.get_file()

func _init_online_dialogs():
	online_field_popup = ConfirmationDialog.new()
	online_field_popup.title = "Select Online Field Layout"
	online_field_popup.min_size = Vector2i(500, 400)
	var vbox_f = VBoxContainer.new()
	var lbl_f = Label.new()
	lbl_f.text = "Select a Field Layout from Supabase:"
	vbox_f.add_child(lbl_f)
	online_field_list = ItemList.new()
	online_field_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	online_field_list.custom_minimum_size = Vector2(0, 250)
	vbox_f.add_child(online_field_list)
	online_field_popup.add_child(vbox_f)
	online_field_popup.confirmed.connect(_on_online_field_confirmed)
	add_child(online_field_popup)

func _on_select_field_pressed():
	if is_online_mode:
		$RoomCreatorPanel/VBoxContainer/FieldBtn.disabled = true
		$RoomCreatorPanel/VBoxContainer/FieldBtn.text = "Loading fields..."
		SupabaseService.fetch_all_fields(func(status, data):
			$RoomCreatorPanel/VBoxContainer/FieldBtn.disabled = false
			$RoomCreatorPanel/VBoxContainer/FieldBtn.text = "Select Field"
			if status == 200 and typeof(data) == TYPE_ARRAY:
				online_fields_cache = data
				online_field_list.clear()
				for field in data:
					online_field_list.add_item(field.get("name", "Untitled Field"))
				online_field_popup.popup_centered()
			else:
				var err = AcceptDialog.new()
				err.title = "Error"
				err.dialog_text = "Failed to load fields from database."
				add_child(err)
				err.popup_centered()
		)
	else:
		field_file_dialog.popup_centered()

func _on_online_field_confirmed():
	var selected = online_field_list.get_selected_items()
	if selected.size() > 0:
		var idx = selected[0]
		var field = online_fields_cache[idx]
		Global.loaded_field_data = field
		$RoomCreatorPanel/VBoxContainer/FieldBtn.text = "Field: " + field.get("name", "Untitled")

func _on_confirm_create_pressed():
	if is_online_mode:
		if Global.loaded_field_data.is_empty():
			var err_dialog = AcceptDialog.new()
			err_dialog.title = "Selection Required"
			err_dialog.dialog_text = "Please select a Field Layout before creating a room."
			add_child(err_dialog)
			err_dialog.popup_centered()
			return
			
		var room_name = $RoomCreatorPanel/VBoxContainer/RoomName.text
		if room_name == "":
			room_name = "Room_" + str(randi() % 1000)
		var password = $RoomCreatorPanel/VBoxContainer/Password.text
		var desc = $RoomCreatorPanel/VBoxContainer/Desc.text
		var host_name = "Host_" + str(randi() % 1000)
		
		Global.online_player_role = "Host"
		Global.online_player_name = host_name
		
		$RoomCreatorPanel/VBoxContainer/ConfirmBtn.disabled = true
		$RoomCreatorPanel/VBoxContainer/ConfirmBtn.text = "Creating room..."
		
		SupabaseService.insert_room(room_name, desc, password, Global.loaded_field_data, Global.selected_deck_data, host_name, func(status, data):
			if not is_instance_valid(self): return
			$RoomCreatorPanel/VBoxContainer/ConfirmBtn.disabled = false
			$RoomCreatorPanel/VBoxContainer/ConfirmBtn.text = "Create!"
			
			if status == 200 or status == 201:
				var created_room = {}
				if typeof(data) == TYPE_ARRAY and data.size() > 0:
					created_room = data[0]
				elif typeof(data) == TYPE_DICTIONARY:
					created_room = data
					
				Global.online_room_id = created_room.get("id", "")
				Global.online_room_data = created_room
				
				print("Room Created on Supabase! ID: ", Global.online_room_id)
				creator_panel.hide()
				Global.play_mode = true
				Global.switch_scene("res://SCENE/Main.tscn")
			else:
				var err_dialog = AcceptDialog.new()
				err_dialog.title = "Error"
				err_dialog.dialog_text = "Online room server update is required." if status == 404 else "Failed to create room on Supabase. (Status: " + str(status) + ")"
				add_child(err_dialog)
				err_dialog.popup_centered()
		)
	else:
		if Global.loaded_field_path == "":
			var err_dialog = AcceptDialog.new()
			err_dialog.title = "Selection Required"
			err_dialog.dialog_text = "Please select a local Field Layout before starting."
			add_child(err_dialog)
			err_dialog.popup_centered()
			return
			
		# Store selected player count in Global
		Global.local_player_count = int(count_spin.value)
		Global.local_active_player_idx = 0
		print("Local game started with %d players! Loading field: %s" % [Global.local_player_count, Global.loaded_field_path])
		
		creator_panel.hide()
		Global.play_mode = true
		Global.switch_scene("res://SCENE/Main.tscn")

func _apply_card_styles():
	var design = preload("res://scripts/ChooserDesign.gd")
	design.card(local_card, "01 / SAME DEVICE", "LOCAL PLAY", "เล่นคนเดียว หรือผลัดกันเล่นในเครื่องเดียว\nเลือกสนามที่บันทึกไว้ แล้วเริ่มได้เลย", "เปิดโต๊ะในเครื่อง", "local")
	design.card(online_card, "02 / TWO PLAYERS", "PLAY ONLINE", "ชวนเพื่อนมาเล่นจากคนละเครื่อง\nสร้างห้องหรือเข้าห้องสำหรับผู้เล่น 2 คน", "ค้นหาห้องออนไลน์", "online", true)

func _apply_creator_panel_styles():
	var style = preload("res://scripts/PlatformStyle.gd")
	var panel = style.glass(Color("10192f"), 24)
	panel.border_color = Color(0.5, 0.76, 1.0, 0.35)
	creator_panel.add_theme_stylebox_override("panel", panel)
	$RoomCreatorPanel/VBoxContainer.add_theme_constant_override("separation", 14)
	$RoomCreatorPanel/VBoxContainer/Title.add_theme_font_override("font", style.display_font())
	$RoomCreatorPanel/VBoxContainer/Title.add_theme_font_size_override("font_size", 36)
	$RoomCreatorPanel/VBoxContainer/PlayerCountContainer/Label.add_theme_font_size_override("font_size", 22)
	for button in [btn1, btn2]:
		button.set_meta("style_owned", true)
		preload("res://scripts/InteractionMotion.gd").button(button)
	_on_player_count_changed(count_spin.value)

func _on_player_count_changed(value: float):
	var style = preload("res://scripts/PlatformStyle.gd")
	for button in [btn1, btn2]:
		var selected: bool = int(value) == (1 if button == btn1 else 2)
		var box = style.glass(Color("4158ba") if selected else Color("18233e"), 10)
		box.border_color = Color("81d4ff") if selected else Color(0.6, 0.7, 1.0, 0.2)
		for state in ["normal", "hover", "pressed", "focus"]:
			button.add_theme_stylebox_override(state, box)

func _apply_platform_style():
	# The menu shell owns the backdrop; this page only styles its controls.
	preload("res://scripts/PlatformStyle.gd")._style_controls(self)
	_apply_creator_panel_styles()
	$Header/Title.add_theme_font_override("font", preload("res://scripts/PlatformStyle.gd").display_font())
	$Header/Title.add_theme_font_size_override("font_size", 42)
