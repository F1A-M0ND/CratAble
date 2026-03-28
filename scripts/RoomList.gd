extends Control

@onready var creator_panel = $RoomCreatorPanel

func _ready():
	$Header/BackBtn.pressed.connect(_on_back_pressed)
	$Header/CreateBtn.pressed.connect(_on_create_room_pressed)
	$RoomCreatorPanel/VBoxContainer/ConfirmBtn.pressed.connect(_on_confirm_create_pressed)
	$RoomCreatorPanel/VBoxContainer/CancelBtn.pressed.connect(_on_close_creator_pressed)

func _on_create_room_pressed():
	creator_panel.show()

func _on_back_pressed():
	Global.switch_scene("res://scenes/MainMenu.tscn")

func _on_close_creator_pressed():
	creator_panel.hide()

func _on_confirm_create_pressed():
	print("Room Created!")
	creator_panel.hide()
