extends Control

func _ready():
	$VBoxContainer/CardBtn.pressed.connect(_on_card_pressed)
	$VBoxContainer/DeckBtn.pressed.connect(_on_deck_pressed)
	$VBoxContainer/FieldBtn.pressed.connect(_on_field_pressed)
	$BackBtn.pressed.connect(_on_back_pressed)

func _on_card_pressed():
	Global.switch_scene("res://scenes/CardEditor.tscn")

func _on_deck_pressed():
	print("Deck Editor not fully implemented yet!")

func _on_field_pressed():
	Global.switch_scene("res://scenes/FieldCreator.tscn")

func _on_back_pressed():
	Global.switch_scene("res://scenes/MainMenu.tscn")
