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

var inspect_timer: Timer
var target_inspect_card_path: String = ""

func _ready():
	inspect_timer = Timer.new()
	inspect_timer.wait_time = 0.5
	inspect_timer.one_shot = true
	inspect_timer.timeout.connect(_on_inspect_timer_timeout)
	add_child(inspect_timer)
	
	print("Tabletop System Initialized")

func _on_inspect_timer_timeout():
	if target_inspect_card_path != "" and has_node("/root/CardInspector"):
		var inspector = get_node("/root/CardInspector")
		inspector.show_card(target_inspect_card_path)

func make_card_inspectable(node: Control, card_path: String):
	if not node.gui_input.is_connected(_on_card_gui_input.bind(card_path)):
		node.gui_input.connect(_on_card_gui_input.bind(card_path))

func _on_card_gui_input(event: InputEvent, card_path: String):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			target_inspect_card_path = card_path
			inspect_timer.start()
		else:
			inspect_timer.stop()
			target_inspect_card_path = ""

func switch_scene(path: String):
	get_tree().change_scene_to_file(path)

func format_num(value) -> String:
	if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
		var float_val = float(value)
		if float_val == int(float_val):
			return str(int(float_val))
		else:
			return str(value)
	return str(value)
