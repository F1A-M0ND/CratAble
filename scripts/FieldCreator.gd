extends Control

@onready var asset_list = $HBoxContainer/LeftSide/AssetContainer/ItemList
@onready var tabletop_view = $HBoxContainer/RightSide/TabletopPreview # ใช้ SubViewport หรือ Panel

func _ready():
	$Header/BackBtn.pressed.connect(_on_back_pressed)
	$HBoxContainer/LeftSide/ImportAssetBtn.pressed.connect(_on_import_asset_pressed)
	$HBoxContainer/LeftSide/SaveFieldBtn.pressed.connect(_on_save_field_pressed)

func _on_import_asset_pressed():
	# ระบบสำหรับเลือกไฟล์ภาพเข้ามาเป็น Token/Card ในสนาม
	# ในที่นี้จำลองการสร้าง Sprite ใหม่ลงในสนาม
	spawn_tabletop_object("res://icon.svg")

func spawn_tabletop_object(texture_path: String):
	var new_obj = Sprite2D.new()
	new_obj.texture = load(texture_path)
	new_obj.position = Vector2(200, 200) # หรือจุดกึ่งกลางสนาม
	
	# เพิ่มสคริปต์ลากวาง (Drag) ให้กับวัตถุที่สร้างใหม่
	new_obj.set_script(load("res://scripts/TabletopObject.gd"))
	tabletop_view.add_child(new_obj)

func _on_save_field_pressed():
	# บันทึกตำแหน่งและ Asset ทั้งหมดในโต๊ะ
	print("Field Layout Saved!")

func _on_back_pressed():
	Global.switch_scene("res://scenes/CustomMenu.tscn")
