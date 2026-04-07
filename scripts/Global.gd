extends Node

# คลังข้อมูลหลัก
var card_library = []
var saved_decks = []
var custom_fields = []
var current_card_path = ""

# ข้อมูลสำหรับ Tabletop System (Field Creator)
var tabletop_assets = {
	"cards": [],
	"tokens": [],
	"boards": []
}

func _ready():
	# จำลองข้อมูลเบื้องต้น
	print("Tabletop System Initialized")

func switch_scene(path: String):
	get_tree().change_scene_to_file(path)
