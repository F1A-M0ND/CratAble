extends Control

@onready var creator_panel = $RoomCreatorPanel

var deck_file_dialog: FileDialog
var field_file_dialog: FileDialog

func _ready():
	$Header/CreateBtn.pressed.connect(_on_create_room_pressed)
	$RoomCreatorPanel/VBoxContainer/ConfirmBtn.pressed.connect(_on_confirm_create_pressed)
	$RoomCreatorPanel/VBoxContainer/CancelBtn.pressed.connect(_on_close_creator_pressed)
	
	# Clear selection variables when arriving at Lobby
	Global.play_mode = false
	Global.loaded_field_path = ""
	Global.selected_deck_path = ""
	Global.loaded_field_data = {}
	Global.selected_deck_data = {}
	
	# Connect Selection buttons in creator panel
	$RoomCreatorPanel/VBoxContainer/AssetBtn.pressed.connect(_on_select_deck_pressed)
	$RoomCreatorPanel/VBoxContainer/FieldBtn.pressed.connect(_on_select_field_pressed)
	
	_init_online_dialogs()

func _on_create_room_pressed():
	creator_panel.show()

func _on_close_creator_pressed():
	creator_panel.hide()

var online_deck_popup: ConfirmationDialog
var online_deck_list: ItemList
var online_decks_cache = []

var online_field_popup: ConfirmationDialog
var online_field_list: ItemList
var online_fields_cache = []

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

func _on_select_field_pressed():
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
