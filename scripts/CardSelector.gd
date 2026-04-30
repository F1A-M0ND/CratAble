extends Control

@onready var card_list = $VBoxContainer/ScrollContainer/CardList
@onready var create_new_btn = $VBoxContainer/CreateNewBtn
@onready var back_btn = $Header/BackBtn

@onready var name_search = $VBoxContainer/SearchArea/NameSearch
@onready var tag_search_input = $VBoxContainer/SearchArea/TagSearchRow/TagSearchInput
@onready var add_tag_btn = $VBoxContainer/SearchArea/TagSearchRow/AddTagBtn
@onready var active_tags_container = $VBoxContainer/SearchArea/ActiveTags

var loaded_cards = [] 
var active_filter_tags = []

func _ready():
	back_btn.pressed.connect(_on_back_pressed)
	create_new_btn.pressed.connect(_on_create_new_pressed)
	
	name_search.text_changed.connect(_on_search_text_changed)
	add_tag_btn.pressed.connect(_on_add_tag_pressed)
	tag_search_input.text_submitted.connect(func(text): _on_add_tag_pressed())
	
	_load_existing_cards()

func _load_existing_cards():
	loaded_cards.clear()
	for child in card_list.get_children():
		child.queue_free()
		
	var save_dir = "res://cards"
	if not DirAccess.dir_exists_absolute(save_dir):
		return
		
	var dir = DirAccess.open(save_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var file_path = save_dir + "/" + file_name
				_create_card_thumbnail(file_path, file_name)
			file_name = dir.get_next()

func _create_card_thumbnail(file_path: String, file_name: String):
	var data = {}
	var has_image = false
	var image_tex = null
	
	if FileAccess.file_exists(file_path):
		var str = FileAccess.get_file_as_string(file_path)
		var json = JSON.new()
		if json.parse(str) == OK:
			data = json.get_data()
			if data.has("image_path") and data["image_path"] != "":
				var img = Image.new()
				if img.load(data["image_path"]) == OK:
					image_tex = ImageTexture.create_from_image(img)
					has_image = true
					
	var margin = MarginContainer.new()
	margin.custom_minimum_size = Vector2(160, 220)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var tex = TextureRect.new()
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if has_image:
		tex.texture = image_tex
		
	var card_name_str = data.get("name", file_name.replace(".json", ""))
	
	var lbl = Label.new()
	lbl.text = card_name_str
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lbl.custom_minimum_size = Vector2(10, 0)
	
	vbox.add_child(tex)
	vbox.add_child(lbl)
	
	var btn = Button.new()
	btn.modulate = Color(1, 1, 1, 0)
	btn.pressed.connect(_on_existing_card_pressed.bind(file_path))
	Global.make_card_inspectable(btn, file_path)
	
	var panel = Panel.new()
	
	margin.add_child(panel)
	margin.add_child(vbox)
	margin.add_child(btn)
	
	card_list.add_child(margin)
	
	# Cache layout info for searching
	var card_info = {
		"node": margin,
		"name": card_name_str.to_lower(),
		"tags": []
	}
	
	if data.has("tags"):
		for t in data["tags"]:
			card_info["tags"].append(str(t).to_lower())
			
	loaded_cards.append(card_info)

func _on_search_text_changed(new_text: String):
	_filter_cards()

func _on_add_tag_pressed():
	var tag_str = tag_search_input.text.strip_edges()
	if tag_str == "":
		return
		
	var lower_tag = tag_str.to_lower()
	if lower_tag in active_filter_tags:
		tag_search_input.text = ""
		return
		
	active_filter_tags.append(lower_tag)
	tag_search_input.text = ""
	
	var tag_ui = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = tag_str
	
	var del_btn = Button.new()
	del_btn.text = "X"
	del_btn.pressed.connect(func():
		active_filter_tags.erase(lower_tag)
		tag_ui.queue_free()
		_filter_cards()
	)
	
	tag_ui.add_child(lbl)
	tag_ui.add_child(del_btn)
	active_tags_container.add_child(tag_ui)
	
	_filter_cards()

func _filter_cards():
	var search_query = name_search.text.to_lower().strip_edges()
	
	for card in loaded_cards:
		var name_match = true
		if search_query != "" and card["name"].find(search_query) == -1:
			name_match = false
			
		var tag_match = true
		for required_tag in active_filter_tags:
			if not required_tag in card["tags"]:
				tag_match = false
				break
				
		if name_match and tag_match:
			card["node"].visible = true
		else:
			card["node"].visible = false

func _on_create_new_pressed():
	Global.current_card_path = ""
	Global.switch_scene("res://scenes/CardEditor.tscn")

func _on_existing_card_pressed(path: String):
	Global.current_card_path = path
	Global.switch_scene("res://scenes/CardEditor.tscn")

func _on_back_pressed():
	Global.main_menu_tab = "CUSTOM"
	Global.switch_scene("res://scenes/MainMenu.tscn")
