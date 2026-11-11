extends Control

const DESIGN = preload("res://scripts/ChooserDesign.gd")

func _ready():
	$HBoxContainer/CardBtn.pressed.connect(_on_card_pressed)
	$HBoxContainer/DeckBtn.pressed.connect(_on_deck_pressed)
	$HBoxContainer/FieldBtn.pressed.connect(_on_field_pressed)
	DESIGN.heading(self, "CREATOR STUDIO", "MAKE IT YOURS.", "เริ่มจากการ์ดหนึ่งใบ แล้วสร้างโลกของเกมในแบบคุณ")
	DESIGN.card($HBoxContainer/CardBtn, "01 / CARDS", "CARD EDITOR", "อัปโหลดภาพ ออกแบบการ์ด\nและปรับขนาดให้เข้ากับเกม", "สร้างการ์ด", "cards")
	DESIGN.card($HBoxContainer/DeckBtn, "02 / DECKS", "DECK BUILDER", "รวมการ์ดเป็นเด็ค\nจัดจำนวนและเตรียมพร้อมเล่น", "จัดเด็ค", "deck", true)
	DESIGN.card($HBoxContainer/FieldBtn, "03 / TABLES", "FIELD CREATOR", "จัดโต๊ะ วางโซนการ์ด\nลูกเต๋า และตัวนับคะแนน", "สร้างสนาม", "field")

func _on_card_pressed():
	Global.switch_scene("res://scenes/CardSelector.tscn")

func _on_deck_pressed():
	Global.switch_scene("res://scenes/DeckEditor.tscn")

func _on_field_pressed():
	Global.switch_scene("res://scenes/FieldCreator.tscn")
