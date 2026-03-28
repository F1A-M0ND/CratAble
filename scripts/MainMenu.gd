extends Control

func _ready():
	$VBoxContainer/PlayBtn.pressed.connect(_on_play_pressed)
	$VBoxContainer/CustomBtn.pressed.connect(_on_custom_pressed)
	$VBoxContainer/CreditBtn.pressed.connect(_on_credit_pressed)

func _on_play_pressed():
	Global.switch_scene("res://scenes/RoomList.tscn")

func _on_custom_pressed():
	Global.switch_scene("res://scenes/CustomMenu.tscn")

func _on_credit_pressed():
	print("App created for Card Game Prototyping")
