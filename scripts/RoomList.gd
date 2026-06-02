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
	
	# Connect Selection buttons in creator panel
	$RoomCreatorPanel/VBoxContainer/AssetBtn.pressed.connect(_on_select_deck_pressed)
	$RoomCreatorPanel/VBoxContainer/FieldBtn.pressed.connect(_on_select_field_pressed)
	
	# Setup File Dialogs
	deck_file_dialog = FileDialog.new()
	deck_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	deck_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	deck_file_dialog.filters = PackedStringArray(["*.json ; Deck Files"])
	deck_file_dialog.size = Vector2(600, 400)
	deck_file_dialog.use_native_dialog = true
	deck_file_dialog.file_selected.connect(_on_deck_selected)
	add_child(deck_file_dialog)
	
	field_file_dialog = FileDialog.new()
	field_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	field_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	field_file_dialog.filters = PackedStringArray(["*.json ; Field Layout Files"])
	field_file_dialog.size = Vector2(600, 400)
	field_file_dialog.use_native_dialog = true
	field_file_dialog.file_selected.connect(_on_field_selected)
	add_child(field_file_dialog)

func _on_create_room_pressed():
	creator_panel.show()

func _on_close_creator_pressed():
	creator_panel.hide()

func _on_select_deck_pressed():
	if not DirAccess.dir_exists_absolute("res://deck"):
		DirAccess.make_dir_absolute("res://deck")
	deck_file_dialog.current_dir = "res://deck"
	deck_file_dialog.popup_centered()

func _on_select_field_pressed():
	if not DirAccess.dir_exists_absolute("res://fields"):
		DirAccess.make_dir_absolute("res://fields")
	field_file_dialog.current_dir = "res://fields"
	field_file_dialog.popup_centered()

func _on_deck_selected(path: String):
	Global.selected_deck_path = path
	var deck_name = path.get_file().replace(".json", "")
	$RoomCreatorPanel/VBoxContainer/AssetBtn.text = "Deck: " + deck_name

func _on_field_selected(path: String):
	Global.loaded_field_path = path
	var field_name = path.get_file().replace(".json", "")
	$RoomCreatorPanel/VBoxContainer/FieldBtn.text = "Field: " + field_name

func _on_confirm_create_pressed():
	if Global.loaded_field_path == "":
		var err_dialog = AcceptDialog.new()
		err_dialog.title = "Selection Required"
		err_dialog.dialog_text = "Please select a Field Layout before creating a room."
		add_child(err_dialog)
		err_dialog.popup_centered()
		return
		
	print("Room Created! Loading field: ", Global.loaded_field_path)
	creator_panel.hide()
	Global.play_mode = true
	Global.switch_scene("res://scenes/FieldCreator.tscn")
