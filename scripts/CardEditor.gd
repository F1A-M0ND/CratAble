extends Control

@onready var card_name = $VBoxContainer/NameInput
@onready var atk_val = $VBoxContainer/StatRow/ATKSpin
@onready var def_val = $VBoxContainer/StatRow/DEFSpin

func _ready():
	$Header/BackBtn.pressed.connect(_on_back_pressed)
	$VBoxContainer/BottomRow/SaveBtn.pressed.connect(_on_save_card_pressed)

func _on_save_card_pressed():
	var new_card = {
		"name": card_name.text,
		"atk": atk_val.value,
		"def": def_val.value,
		"tags": [] # วนลูปเก็บจาก UI ที่เพิ่มใหม่ได้
	}
	Global.card_library.append(new_card)
	print("Card Saved: ", new_card.name)

func _on_back_pressed():
	Global.switch_scene("res://scenes/CustomMenu.tscn")
