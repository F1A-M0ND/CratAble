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

var deck_file_dialog: FileDialog
var field_file_dialog: FileDialog

var is_online_mode: bool = false

# Online cache and popups
var online_deck_popup: ConfirmationDialog
var online_deck_list: ItemList
var online_decks_cache = []

var online_field_popup: ConfirmationDialog
var online_field_list: ItemList
var online_fields_cache = []

func _ready():
	$Header/CreateBtn.pressed.connect(_on_create_room_pressed)
	$RoomCreatorPanel/VBoxContainer/ConfirmBtn.pressed.connect(_on_confirm_create_pressed)
	$RoomCreatorPanel/VBoxContainer/CancelBtn.pressed.connect(_on_close_creator_pressed)
	
	# Connect Selection buttons in creator panel
	$RoomCreatorPanel/VBoxContainer/AssetBtn.pressed.connect(_on_select_deck_pressed)
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
	
	# Initialize the floating orange liquid auras
	_init_liquid_auras()

func _on_local_mode_selected():
	is_online_mode = false
	mode_selection_ui.hide()
	
	# Reset/Setup creator panel for local play
	$RoomCreatorPanel/VBoxContainer/Title.text = "Local Play Setup"
	$RoomCreatorPanel/VBoxContainer/ConfirmBtn.text = "Start Local Game"
	$RoomCreatorPanel/VBoxContainer/AssetBtn.text = "Select Local Deck"
	$RoomCreatorPanel/VBoxContainer/FieldBtn.text = "Select Local Field"
	
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

func _on_create_room_pressed():
	# Show creator panel for online room
	$RoomCreatorPanel/VBoxContainer/Title.text = "Room Creator"
	$RoomCreatorPanel/VBoxContainer/ConfirmBtn.text = "Create!"
	$RoomCreatorPanel/VBoxContainer/AssetBtn.text = "Select Deck"
	$RoomCreatorPanel/VBoxContainer/FieldBtn.text = "Select Field"
	
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
	deck_file_dialog = FileDialog.new()
	deck_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	deck_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	deck_file_dialog.filters = PackedStringArray(["*.json ; Deck Files"])
	deck_file_dialog.size = Vector2(600, 400)
	deck_file_dialog.use_native_dialog = true
	deck_file_dialog.file_selected.connect(_on_local_deck_selected)
	add_child(deck_file_dialog)
	
	field_file_dialog = FileDialog.new()
	field_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	field_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	field_file_dialog.filters = PackedStringArray(["*.json ; Field Layout Files"])
	field_file_dialog.size = Vector2(600, 400)
	field_file_dialog.use_native_dialog = true
	field_file_dialog.file_selected.connect(_on_local_field_selected)
	add_child(field_file_dialog)

func _on_local_deck_selected(path: String):
	Global.selected_deck_path = path
	Global.selected_deck_data = {} # Clear online
	$RoomCreatorPanel/VBoxContainer/AssetBtn.text = "Deck: " + path.get_file()

func _on_local_field_selected(path: String):
	Global.loaded_field_path = path
	Global.loaded_field_data = {} # Clear online
	$RoomCreatorPanel/VBoxContainer/FieldBtn.text = "Field: " + path.get_file()

func _init_online_dialogs():
	online_deck_popup = ConfirmationDialog.new()
	online_deck_popup.title = "Select Online Deck"
	online_deck_popup.min_size = Vector2i(500, 400)
	var vbox_d = VBoxContainer.new()
	var lbl_d = Label.new()
	lbl_d.text = "Select a deck from Supabase:"
	vbox_d.add_child(lbl_d)
	online_deck_list = ItemList.new()
	online_deck_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	online_deck_list.custom_minimum_size = Vector2(0, 250)
	vbox_d.add_child(online_deck_list)
	online_deck_popup.add_child(vbox_d)
	online_deck_popup.confirmed.connect(_on_online_deck_confirmed)
	add_child(online_deck_popup)
	
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

func _on_select_deck_pressed():
	if is_online_mode:
		$RoomCreatorPanel/VBoxContainer/AssetBtn.disabled = true
		$RoomCreatorPanel/VBoxContainer/AssetBtn.text = "Loading decks..."
		SupabaseService.fetch_all_decks(func(status, data):
			$RoomCreatorPanel/VBoxContainer/AssetBtn.disabled = false
			$RoomCreatorPanel/VBoxContainer/AssetBtn.text = "Select Deck"
			if status == 200 and typeof(data) == TYPE_ARRAY:
				online_decks_cache = data
				online_deck_list.clear()
				for deck in data:
					online_deck_list.add_item(deck.get("name", "Untitled Deck"))
				online_deck_popup.popup_centered()
			else:
				var err = AcceptDialog.new()
				err.title = "Error"
				err.dialog_text = "Failed to load decks from database."
				add_child(err)
				err.popup_centered()
		)
	else:
		deck_file_dialog.popup_centered()

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

func _on_online_deck_confirmed():
	var selected = online_deck_list.get_selected_items()
	if selected.size() > 0:
		var idx = selected[0]
		var deck = online_decks_cache[idx]
		Global.selected_deck_data = deck
		$RoomCreatorPanel/VBoxContainer/AssetBtn.text = "Deck: " + deck.get("name", "Untitled")

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
			
		print("Room Created! Loading field from Supabase: ", Global.loaded_field_data.get("name"))
		creator_panel.hide()
		Global.play_mode = true
		Global.switch_scene("res://scenes/FieldCreator.tscn")
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
		Global.switch_scene("res://scenes/FieldCreator.tscn")

func _apply_card_styles():
	var cards = [local_card, online_card]
	
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
	# Add it at the back (index 0) so it renders behind the cards
	mode_selection_ui.add_child(aura_container)
	mode_selection_ui.move_child(aura_container, 0)
	
	# Create a soft orange radial gradient texture
	var grad = Gradient.new()
	grad.colors = PackedColorArray([
		Color(0.98, 0.42, 0.05, 0.22), # Vibrant soft orange in center
		Color(0.98, 0.35, 0.05, 0.08), # Dimmer orange midpoint
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
	
	# Blob 1 (Behind Local Card)
	var blob1 = TextureRect.new()
	blob1.name = "Blob1"
	blob1.texture = tex
	blob1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blob1.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	blob1.custom_minimum_size = Vector2(600, 600)
	blob1.size = Vector2(600, 600)
	blob1.position = Vector2(80, 40)
	blob1.pivot_offset = Vector2(300, 300)
	aura_container.add_child(blob1)
	
	# Blob 2 (Behind Online Card)
	var blob2 = TextureRect.new()
	blob2.name = "Blob2"
	blob2.texture = tex
	blob2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blob2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	blob2.custom_minimum_size = Vector2(600, 600)
	blob2.size = Vector2(600, 600)
	blob2.position = Vector2(480, 140)
	blob2.pivot_offset = Vector2(300, 300)
	aura_container.add_child(blob2)
	
	# Start floating animations
	_animate_liquid_auras(blob1, blob2)

func _animate_liquid_auras(blob1: Control, blob2: Control):
	var base_pos1 = blob1.position
	var base_pos2 = blob2.position
	
	# Animate Blob 1: Slow floating in a rounded path, gentle scaling
	var t1 = create_tween().set_loops().set_parallel(true)
	t1.tween_property(blob1, "position", base_pos1 + Vector2(45, -35), 5.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t1.tween_property(blob1, "scale", Vector2(1.18, 1.18), 4.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	t1.chain().tween_property(blob1, "position", base_pos1 + Vector2(-35, 25), 6.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t1.tween_property(blob1, "scale", Vector2(0.88, 0.88), 5.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	t1.chain().tween_property(blob1, "position", base_pos1, 6.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t1.tween_property(blob1, "scale", Vector2(1.0, 1.0), 5.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Animate Blob 2: Slow counter-floating and out-of-sync scaling
	var t2 = create_tween().set_loops().set_parallel(true)
	t2.tween_property(blob2, "position", base_pos2 + Vector2(-45, 40), 6.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t2.tween_property(blob2, "scale", Vector2(0.85, 0.85), 5.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	t2.chain().tween_property(blob2, "position", base_pos2 + Vector2(35, -30), 5.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t2.tween_property(blob2, "scale", Vector2(1.12, 1.12), 6.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	t2.chain().tween_property(blob2, "position", base_pos2, 6.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t2.tween_property(blob2, "scale", Vector2(1.0, 1.0), 4.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _apply_creator_panel_styles():
	# 1. Style RoomCreatorPanel itself as a premium liquid glass panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.1, 0.75) # Dark semi-transparent glass
	panel_style.set_border_width_all(1)
	panel_style.border_color = Color(1.0, 1.0, 1.0, 0.18) # Clean reflection edge
	panel_style.set_corner_radius_all(20)
	panel_style.shadow_color = Color(0.98, 0.45, 0.08, 0.15) # Soft orange glow
	panel_style.shadow_size = 15
	panel_style.shadow_offset = Vector2(0, 8)
	creator_panel.add_theme_stylebox_override("panel", panel_style)

	# 2. Style creator panel title
	var title = $RoomCreatorPanel/VBoxContainer/Title
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	title.add_theme_font_size_override("font_size", 20)
	
	# Set spacing of VBoxContainer to look spacious and premium
	$RoomCreatorPanel/VBoxContainer.add_theme_constant_override("separation", 12)

	# 3. Style LineEdits (RoomName, Password) and TextEdit (Desc)
	var input_normal = StyleBoxFlat.new()
	input_normal.bg_color = Color(0.04, 0.04, 0.06, 0.6)
	input_normal.set_border_width_all(1)
	input_normal.border_color = Color(1.0, 1.0, 1.0, 0.08)
	input_normal.set_corner_radius_all(8)
	
	var input_focus = StyleBoxFlat.new()
	input_focus.bg_color = Color(0.06, 0.06, 0.08, 0.75)
	input_focus.set_border_width_all(1)
	input_focus.border_color = Color(0.98, 0.45, 0.08, 0.8) # Orange border on focus
	input_focus.set_corner_radius_all(8)
	input_focus.shadow_color = Color(0.98, 0.45, 0.08, 0.15)
	input_focus.shadow_size = 6

	var line_edits = [$RoomCreatorPanel/VBoxContainer/RoomName, $RoomCreatorPanel/VBoxContainer/Password]
	for le in line_edits:
		le.add_theme_stylebox_override("normal", input_normal)
		le.add_theme_stylebox_override("focus", input_focus)
		le.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
		le.add_theme_color_override("placeholder_color", Color(0.5, 0.5, 0.5))

	var desc = $RoomCreatorPanel/VBoxContainer/Desc
	desc.add_theme_stylebox_override("normal", input_normal)
	desc.add_theme_stylebox_override("focus", input_focus)
	desc.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))

	# 4. Style AssetBtn and FieldBtn
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.12, 0.12, 0.16, 0.6)
	btn_normal.set_border_width_all(1)
	btn_normal.border_color = Color(1.0, 1.0, 1.0, 0.1)
	btn_normal.set_corner_radius_all(8)
	
	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.16, 0.16, 0.22, 0.8)
	btn_hover.set_border_width_all(1)
	btn_hover.border_color = Color(0.98, 0.45, 0.08, 0.8)
	btn_hover.set_corner_radius_all(8)
	btn_hover.shadow_color = Color(0.98, 0.45, 0.08, 0.15)
	btn_hover.shadow_size = 5

	var btn_pressed = StyleBoxFlat.new()
	btn_pressed.bg_color = Color(0.98, 0.45, 0.08, 0.95)
	btn_pressed.set_border_width_all(1)
	btn_pressed.border_color = Color(1.0, 1.0, 1.0, 0.3)
	btn_pressed.set_corner_radius_all(8)

	var selection_btns = [$RoomCreatorPanel/VBoxContainer/AssetBtn, $RoomCreatorPanel/VBoxContainer/FieldBtn]
	for btn in selection_btns:
		btn.add_theme_stylebox_override("normal", btn_normal)
		btn.add_theme_stylebox_override("hover", btn_hover)
		btn.add_theme_stylebox_override("pressed", btn_pressed)
		btn.add_theme_stylebox_override("focus", btn_hover)

	# 5. Style ConfirmBtn (Primary action)
	var confirm_style_normal = StyleBoxFlat.new()
	confirm_style_normal.bg_color = Color(0.98, 0.45, 0.08, 0.75)
	confirm_style_normal.set_corner_radius_all(8)
	confirm_style_normal.set_border_width_all(1)
	confirm_style_normal.border_color = Color(1.0, 1.0, 1.0, 0.15)

	var confirm_style_hover = StyleBoxFlat.new()
	confirm_style_hover.bg_color = Color(0.98, 0.45, 0.08, 0.95)
	confirm_style_hover.set_corner_radius_all(8)
	confirm_style_hover.set_border_width_all(1)
	confirm_style_hover.border_color = Color(1.0, 1.0, 1.0, 0.35)
	confirm_style_hover.shadow_color = Color(0.98, 0.45, 0.08, 0.35)
	confirm_style_hover.shadow_size = 10

	var confirm_style_pressed = StyleBoxFlat.new()
	confirm_style_pressed.bg_color = Color(0.85, 0.35, 0.05, 0.95)
	confirm_style_pressed.set_corner_radius_all(8)
	confirm_style_pressed.set_border_width_all(1)
	confirm_style_pressed.border_color = Color(1.0, 1.0, 1.0, 0.25)

	var confirm_btn = $RoomCreatorPanel/VBoxContainer/ConfirmBtn
	confirm_btn.add_theme_stylebox_override("normal", confirm_style_normal)
	confirm_btn.add_theme_stylebox_override("hover", confirm_style_hover)
	confirm_btn.add_theme_stylebox_override("pressed", confirm_style_pressed)
	confirm_btn.add_theme_stylebox_override("focus", confirm_style_hover)

	# 6. Style CancelBtn (Secondary action)
	var cancel_btn = $RoomCreatorPanel/VBoxContainer/CancelBtn
	cancel_btn.add_theme_stylebox_override("normal", btn_normal)
	cancel_btn.add_theme_stylebox_override("hover", btn_hover)
	cancel_btn.add_theme_stylebox_override("pressed", btn_pressed)
	cancel_btn.add_theme_stylebox_override("focus", btn_hover)

	# 7. Style PlayerCount quick buttons (Btn1, Btn2)
	_on_player_count_changed(count_spin.value)

	# 8. Style SpinBox LineEdit
	var spin_edit = count_spin.get_line_edit()
	if spin_edit:
		spin_edit.add_theme_stylebox_override("normal", input_normal)
		spin_edit.add_theme_stylebox_override("focus", input_focus)
		spin_edit.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
		spin_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER

	# 9. Style player count label
	$RoomCreatorPanel/VBoxContainer/PlayerCountContainer/Label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	$RoomCreatorPanel/VBoxContainer/PlayerCountContainer/Label.add_theme_font_size_override("font_size", 14)

	# 10. Connect hover scale micro-animations for all buttons
	var all_btns = [
		$RoomCreatorPanel/VBoxContainer/AssetBtn,
		$RoomCreatorPanel/VBoxContainer/FieldBtn,
		$RoomCreatorPanel/VBoxContainer/ConfirmBtn,
		$RoomCreatorPanel/VBoxContainer/CancelBtn,
		btn1,
		btn2
	]
	for btn in all_btns:
		btn.mouse_entered.connect(func(): _animate_card_scale(btn, Vector2(1.02, 1.02)))
		btn.mouse_exited.connect(func(): _animate_card_scale(btn, Vector2(1.0, 1.0)))

func _on_player_count_changed(value: float):
	var active_style = StyleBoxFlat.new()
	active_style.bg_color = Color(0.98, 0.45, 0.08, 0.95) # Glowing orange
	active_style.set_corner_radius_all(6)
	active_style.set_border_width_all(1)
	active_style.border_color = Color(1.0, 1.0, 1.0, 0.35)
	
	var inactive_style = StyleBoxFlat.new()
	inactive_style.bg_color = Color(0.12, 0.12, 0.16, 0.6) # Dark transparent
	inactive_style.set_corner_radius_all(6)
	inactive_style.set_border_width_all(1)
	inactive_style.border_color = Color(1.0, 1.0, 1.0, 0.1)

	var val_int = int(value)
	if val_int == 1:
		btn1.add_theme_stylebox_override("normal", active_style)
		btn1.add_theme_stylebox_override("hover", active_style)
		btn1.add_theme_stylebox_override("pressed", active_style)
		
		btn2.add_theme_stylebox_override("normal", inactive_style)
		btn2.add_theme_stylebox_override("hover", inactive_style)
		btn2.add_theme_stylebox_override("pressed", inactive_style)
	elif val_int == 2:
		btn1.add_theme_stylebox_override("normal", inactive_style)
		btn1.add_theme_stylebox_override("hover", inactive_style)
		btn1.add_theme_stylebox_override("pressed", inactive_style)
		
		btn2.add_theme_stylebox_override("normal", active_style)
		btn2.add_theme_stylebox_override("hover", active_style)
		btn2.add_theme_stylebox_override("pressed", active_style)
	else:
		btn1.add_theme_stylebox_override("normal", inactive_style)
		btn1.add_theme_stylebox_override("hover", inactive_style)
		btn1.add_theme_stylebox_override("pressed", inactive_style)
		
		btn2.add_theme_stylebox_override("normal", inactive_style)
		btn2.add_theme_stylebox_override("hover", inactive_style)
		btn2.add_theme_stylebox_override("pressed", inactive_style)
