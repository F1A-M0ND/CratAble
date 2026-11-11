extends Control

@onready var card_list = $VBoxContainer/ScrollContainer/CardList
@onready var create_new_btn = $VBoxContainer/CreateNewBtn
@onready var back_btn = $Header/BackBtn
@onready var library_status: Label = $VBoxContainer/LibraryStatus/Status
@onready var retry_btn: Button = $VBoxContainer/LibraryStatus/Retry

@onready var name_search = $VBoxContainer/SearchArea/NameSearch
@onready var tag_search_input = $VBoxContainer/SearchArea/TagSearchRow/TagSearchInput
@onready var add_tag_btn = $VBoxContainer/SearchArea/TagSearchRow/AddTagBtn
@onready var active_tags_container = $VBoxContainer/SearchArea/ActiveTags

var loaded_cards = [] 
var active_filter_tags = []

func _ready():
	back_btn.pressed.connect(_on_back_pressed)
	create_new_btn.pressed.connect(_on_create_new_pressed)
	retry_btn.pressed.connect(_load_cloud_cards)
	
	name_search.text_changed.connect(_on_search_text_changed)
	add_tag_btn.pressed.connect(_on_add_tag_pressed)
	tag_search_input.text_submitted.connect(func(text): _on_add_tag_pressed())
	
	_load_existing_cards()

func _load_existing_cards():
	loaded_cards.clear()
	for child in card_list.get_children():
		child.queue_free()
	if OS.has_feature("web"):
		var directory = DirAccess.open("user://cards")
		if directory:
			for filename in directory.get_files():
				if filename.ends_with(".json"):
					var path = "user://cards/" + filename
					var data = JSON.parse_string(FileAccess.get_file_as_string(path))
					if data is Dictionary:
						data["_local_path"] = path
						_create_card_thumbnail(data)
		
	_load_cloud_cards()

func _load_cloud_cards():
	retry_btn.hide()
	library_status.text = "กำลังโหลดการ์ดออนไลน์…"
	SupabaseService.fetch_all_cards(_on_cloud_cards_loaded)

func _on_cloud_cards_loaded(status, data):
	if status == 200 and data is Array:
		var local_count = loaded_cards.size()
		for card_row in data:
			_create_card_thumbnail(card_row)
		library_status.text = "การ์ดออนไลน์ %d ใบ" % data.size()
		if OS.has_feature("web"):
			library_status.text += "   ·   บนเบราว์เซอร์นี้ %d ใบ" % local_count
		_filter_cards()
	else:
		if status == 0:
			library_status.text = "โหลดการ์ดออนไลน์ไม่สำเร็จ กรุณาตรวจการเชื่อมต่อแล้วลองอีกครั้ง"
		else:
			library_status.text = "โหลดการ์ดออนไลน์ไม่สำเร็จ (HTTP %d)" % status
		retry_btn.show()

func _create_card_thumbnail(card_row: Dictionary):
	var stats_data = {}
	if card_row.has("stats") and typeof(card_row["stats"]) == TYPE_DICTIONARY:
		stats_data = card_row["stats"]
	else:
		stats_data = card_row
		
	var card_name_str = card_row.get("name", "Untitled")
	
	var margin = MarginContainer.new()
	margin.custom_minimum_size = Vector2(160, 220)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var tex = TextureRect.new()
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Load image asynchronously
	var img_url = card_row.get("image_url", card_row.get("image_path", ""))
	if img_url == "" and stats_data.has("image_path"):
		img_url = stats_data["image_path"]
		
	if img_url != "":
		if img_url.begins_with("http"):
			SupabaseService.get_texture_or_load(img_url, func(texture):
				if texture and is_instance_valid(tex):
					tex.texture = texture
			, self)
		else:
			var img = Image.new()
			if img.load(img_url) == OK:
				tex.texture = ImageTexture.create_from_image(img)
		
	var lbl = Label.new()
	lbl.text = card_name_str
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lbl.custom_minimum_size = Vector2(10, 0)
	
	vbox.add_child(tex)
	vbox.add_child(lbl)
	
	var btn = Button.new()
	btn.modulate = Color(1, 1, 1, 0)
	btn.pressed.connect(_on_existing_card_pressed.bind(card_row))
	Global.make_card_inspectable(btn, card_row)
	
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
	
	if stats_data.has("tags"):
		for t in stats_data["tags"]:
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
	Global.current_card_data = {}
	Global.switch_scene("res://scenes/CardEditor.tscn")

func _on_existing_card_pressed(card_row: Dictionary):
	Global.current_card_data = card_row
	Global.switch_scene("res://scenes/CardEditor.tscn")

func _on_back_pressed():
	Global.main_menu_tab = "CUSTOM"
	Global.switch_scene("res://scenes/MainMenu.tscn")
