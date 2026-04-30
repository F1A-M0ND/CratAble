extends Control

func _ready():
	$VBoxContainer/CardBtn.pressed.connect(_on_card_pressed)
	$VBoxContainer/DeckBtn.pressed.connect(_on_deck_pressed)
	$VBoxContainer/FieldBtn.pressed.connect(_on_field_pressed)

func _on_card_pressed():
	Global.switch_scene("res://scenes/CardSelector.tscn")

func _on_deck_pressed():
	Global.switch_scene("res://scenes/DeckEditor.tscn")

func _on_field_pressed():
	Global.switch_scene("res://scenes/FieldCreator.tscn")
