extends Control

@onready var name_search = $Split/LibraryPanel/Margin/VBox/NameSearch
@onready var tag_search_input = $Split/LibraryPanel/Margin/VBox/TagSearchRow/TagInput
@onready var add_tag_btn = $Split/LibraryPanel/Margin/VBox/TagSearchRow/AddTagBtn
@onready var active_tags_container = $Split/LibraryPanel/Margin/VBox/ActiveTags
@onready var card_grid = $Split/LibraryPanel/Margin/VBox/Scroll/CardGrid

@onready var deck_name_input = $Split/DeckPanel/Margin/VBox/Header/DeckName
@onready var open_btn = $Split/DeckPanel/Margin/VBox/Header/OpenBtn
@onready var save_btn = $Split/DeckPanel/Margin/VBox/Header/SaveBtn
@onready var back_btn = $Split/DeckPanel/Margin/VBox/Header/BackBtn
@onready var add_group_btn = $Split/DeckPanel/Margin/VBox/AddGroupBtn
@onready var groups_vbox = $Split/DeckPanel/Margin/VBox/GroupsScroll/GroupsVBox

@onready var file_dialog = $FileDialog
@onready var group_dialog = $GroupDialog
@onready var error_dialog = $ErrorDialog

@onready var gn_input = $GroupDialog/VBox/GNInput
@onready var min_spin = $GroupDialog/VBox/HBox/MinSpin
@onready var max_spin = $GroupDialog/VBox/HBox/MaxSpin
@onready var shuffle_check = $GroupDialog/VBox/ShuffleCheck

var loaded_cards = [] 
var active_filter_tags = []
var card_cache = {} # path -> card data

var deck_data = {
	"deck_name": "New Deck",
	"groups": [
		{
			"name": "Main Deck",
			"min": 40,
			"max": 60,
			"shuffle_at_start": false,
			"cards": {} # path -> count
		}
	]
}
var active_group_idx: int = 0
var editing_group_idx: int = -1 # for the settings dialog

var pressed_card_paths = {}
var amount_popup: ConfirmationDialog
var amount_spin: SpinBox
var target_path_for_amount: String = ""

func _ready():
	back_btn.pressed.connect(_on_back_pressed)
	open_btn.pressed.connect(_on_open_pressed)
	save_btn.pressed.connect(_on_save_pressed)
	add_group_btn.pressed.connect(_on_add_group_pressed)
	
	name_search.text_changed.connect(_on_search_text_changed)
	add_tag_btn.pressed.connect(_on_add_tag_pressed)
	tag_search_input.text_submitted.connect(func(_t): _on_add_tag_pressed())
	
	file_dialog.file_selected.connect(_on_file_selected)
	group_dialog.confirmed.connect(_on_group_settings_saved)
	deck_name_input.text_changed.connect(func(text): deck_data["deck_name"] = text)
	
	amount_popup = ConfirmationDialog.new()
	amount_popup.title = "Add Multiple"
	
	var popup_vbox = VBoxContainer.new()
	var popup_lbl = Label.new()
	popup_lbl.text = "How many copies do you want to add?"
	
	amount_spin = SpinBox.new()
	amount_spin.min_value = 1
	amount_spin.max_value = 999
	amount_spin.value = 1
	amount_spin.rounded = true
	
	popup_vbox.add_child(popup_lbl)
	popup_vbox.add_child(amount_spin)
	
	amount_popup.add_child(popup_vbox)
	amount_popup.confirmed.connect(_on_amount_confirmed)
	add_child(amount_popup)
	
	_load_library_cards()
	_refresh_deck_ui()

func _process(delta):
	for path in pressed_card_paths.keys():
		pressed_card_paths[path] += delta
		if pressed_card_paths[path] >= 0.5:
			pressed_card_paths.erase(path)
			_show_amount_popup(path)

func _show_amount_popup(path: String):
	target_path_for_amount = path
	amount_spin.value = 1
	amount_popup.popup_centered()

func _on_amount_confirmed():
	if target_path_for_amount != "":
		_add_card_copies(target_path_for_amount, int(amount_spin.value))

# --- Library Area ---
func _load_library_cards():
	loaded_cards.clear()
	card_cache.clear()
	for child in card_grid.get_children():
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
				_create_library_thumbnail(file_path, file_name)
			file_name = dir.get_next()

func _create_library_thumbnail(file_path: String, file_name: String):
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
					
	var card_name_str = data.get("name", file_name.replace(".json", ""))
	
	# Cache for easy retrieval later
	card_cache[file_path] = {
		"name": card_name_str,
		"image_tex": image_tex,
		"has_image": has_image
	}
	
	var margin = MarginContainer.new()
	margin.custom_minimum_size = Vector2(100, 140)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var tex = TextureRect.new()
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if has_image:
		tex.texture = image_tex
		
	var lbl = Label.new()
	lbl.text = card_name_str
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size = Vector2(10, 0)
	
	vbox.add_child(tex)
	vbox.add_child(lbl)
	
	var btn = Button.new()
	btn.modulate = Color(1, 1, 1, 0)
	btn.button_down.connect(func(): pressed_card_paths[file_path] = 0.0)
	btn.button_up.connect(func():
		if pressed_card_paths.has(file_path):
			var time_held = pressed_card_paths[file_path]
			pressed_card_paths.erase(file_path)
			if time_held < 0.5:
				_add_card_copies(file_path, 1)
	)
	
	var panel = Panel.new()
	
	margin.add_child(panel)
	margin.add_child(vbox)
	margin.add_child(btn)
	
	card_grid.add_child(margin)
	
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


# --- Deck Area ---

func _get_current_group_card_count(group: Dictionary) -> int:
	var total = 0
	for p in group["cards"]:
		total += int(group["cards"][p])
	return total

func _add_card_copies(path: String, amount: int):
	if deck_data["groups"].size() == 0:
		return
	if active_group_idx < 0 or active_group_idx >= deck_data["groups"].size():
		active_group_idx = 0
	
	var group = deck_data["groups"][active_group_idx]
	if group["cards"].has(path):
		group["cards"][path] += amount
	else:
		group["cards"][path] = amount
	
	_refresh_deck_ui()

func _on_deck_card_pressed(path: String, group_idx: int):
	var group = deck_data["groups"][group_idx]
	if group["cards"].has(path):
		group["cards"][path] -= 1
		if group["cards"][path] <= 0:
			group["cards"].erase(path)
	_refresh_deck_ui()

func _refresh_deck_ui():
	deck_name_input.text = deck_data.get("deck_name", "New Deck")
	
	for child in groups_vbox.get_children():
		child.queue_free()
		
	for i in range(deck_data["groups"].size()):
		var group = deck_data["groups"][i]
		
		var group_panel = PanelContainer.new()
		
		# Change border/color if active
		if i == active_group_idx:
			group_panel.modulate = Color(1.2, 1.2, 1.5)
		else:
			group_panel.modulate = Color(1.0, 1.0, 1.0)
			
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 5)
		margin.add_theme_constant_override("margin_top", 5)
		margin.add_theme_constant_override("margin_right", 5)
		margin.add_theme_constant_override("margin_bottom", 5)
		group_panel.add_child(margin)
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 5)
		margin.add_child(vbox)
		
		# --- Header ---
		var header_hbox = HBoxContainer.new()
		var gname_lbl = Label.new()
		gname_lbl.text = group["name"]
		gname_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header_hbox.add_child(gname_lbl)
		
		var current_count = _get_current_group_card_count(group)
		var count_lbl = Label.new()
		count_lbl.text = str(int(current_count)) + " (" + str(int(group["min"])) + "-" + str(int(group["max"])) + ")"
		
		if current_count > group["max"]:
			count_lbl.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
		elif current_count < group["min"]:
			count_lbl.add_theme_color_override("font_color", Color(1, 1, 0.4))
		
		header_hbox.add_child(count_lbl)
		
		var edit_btn = Button.new()
		edit_btn.text = "Edit"
		edit_btn.pressed.connect(_open_group_dialog.bind(i))
		header_hbox.add_child(edit_btn)
		
		var activate_btn = Button.new()
		activate_btn.text = "Select"
		activate_btn.pressed.connect(func():
			active_group_idx = i
			_refresh_deck_ui()
		)
		header_hbox.add_child(activate_btn)
		
		var del_btn = Button.new()
		del_btn.text = "X"
		del_btn.pressed.connect(func():
			deck_data["groups"].remove_at(i)
			if active_group_idx >= deck_data["groups"].size():
				active_group_idx = deck_data["groups"].size() - 1
			_refresh_deck_ui()
		)
		header_hbox.add_child(del_btn)
		
		vbox.add_child(header_hbox)
		
		var hsep = HSeparator.new()
		vbox.add_child(hsep)
		
		# --- Cards Flow Container ---
		var cards_flow = HFlowContainer.new()
		for card_path in group["cards"].keys():
			var count = group["cards"][card_path]
			var card_ui = _create_deck_card_ui(card_path, count, i)
			cards_flow.add_child(card_ui)
			
		vbox.add_child(cards_flow)
		
		groups_vbox.add_child(group_panel)

func _create_deck_card_ui(path: String, count: int, group_idx: int) -> Control:
	var margin = MarginContainer.new()
	margin.custom_minimum_size = Vector2(80, 110)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var c_cache = card_cache.get(path, {"name": "Unknown", "has_image": false, "image_tex": null})
	
	var tex = TextureRect.new()
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if c_cache["has_image"]:
		tex.texture = c_cache["image_tex"]
		
	var lbl = Label.new()
	lbl.text = "x" + str(int(count))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 14)
	
	vbox.add_child(tex)
	vbox.add_child(lbl)
	
	var btn = Button.new()
	btn.modulate = Color(1, 1, 1, 0)
	btn.pressed.connect(_on_deck_card_pressed.bind(path, group_idx))
	
	var overlay_vbox = VBoxContainer.new()
	overlay_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var top_hbox = HBoxContainer.new()
	top_hbox.alignment = BoxContainer.ALIGNMENT_END
	top_hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var del_btn = Button.new()
	del_btn.text = "X"
	del_btn.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	del_btn.pressed.connect(func():
		var group = deck_data["groups"][group_idx]
		group["cards"].erase(path)
		_refresh_deck_ui()
	)
	
	top_hbox.add_child(del_btn)
	overlay_vbox.add_child(top_hbox)
	
	var panel = Panel.new()
	
	margin.add_child(panel)
	margin.add_child(vbox)
	margin.add_child(btn)
	margin.add_child(overlay_vbox)
	
	return margin

# --- Dialogs and Settings ---

func _on_add_group_pressed():
	deck_data["groups"].append({
		"name": "New Group",
		"min": 0,
		"max": 60,
		"shuffle_at_start": false,
		"cards": {}
	})
	active_group_idx = deck_data["groups"].size() - 1
	_refresh_deck_ui()

func _open_group_dialog(idx: int):
	editing_group_idx = idx
	var group = deck_data["groups"][idx]
	gn_input.text = group["name"]
	min_spin.value = group["min"]
	max_spin.value = group["max"]
	shuffle_check.button_pressed = group.get("shuffle_at_start", false)
	group_dialog.popup_centered()

func _on_group_settings_saved():
	if editing_group_idx >= 0 and editing_group_idx < deck_data["groups"].size():
		var group = deck_data["groups"][editing_group_idx]
		group["name"] = gn_input.text
		group["min"] = int(min_spin.value)
		group["max"] = int(max_spin.value)
		group["shuffle_at_start"] = shuffle_check.button_pressed
		_refresh_deck_ui()

# --- Saving / Loading ---

func _on_save_pressed():
	var safe_name = deck_data["deck_name"]
	safe_name = safe_name.replace("/", "_").replace("\\", "_").replace(":", "_").replace("*", "_").replace("?", "_").replace("\"", "_").replace("<", "_").replace(">", "_").replace("|", "_")
	if safe_name.strip_edges() == "":
		safe_name = "New_Deck"
	
	var path = "res://deck/" + safe_name + ".json"
	_save_deck_to_file(path)

func _on_open_pressed():
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.current_dir = "res://deck"
	file_dialog.popup_centered()

func _on_file_selected(path: String):
	if file_dialog.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		_save_deck_to_file(path)
	else:
		_load_deck_from_file(path)

func _save_deck_to_file(path: String):
	var dir = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
		
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		var json = JSON.stringify(deck_data, "\t")
		file.store_string(json)
		file.close()
		print("Deck saved: ", path)
	else:
		error_dialog.dialog_text = "Failed to save file."
		error_dialog.popup_centered()

func _load_deck_from_file(path: String):
	if FileAccess.file_exists(path):
		var str = FileAccess.get_file_as_string(path)
		var json = JSON.new()
		if json.parse(str) == OK:
			var data = json.get_data()
			# Validate minimum format
			if typeof(data) == TYPE_DICTIONARY and data.has("groups"):
				deck_data = data
				active_group_idx = 0
				_refresh_deck_ui()
			else:
				error_dialog.dialog_text = "Invalid deck file format."
				error_dialog.popup_centered()
		else:
			error_dialog.dialog_text = "Error parsing JSON."
			error_dialog.popup_centered()

func _on_back_pressed():
	Global.switch_scene("res://scenes/CustomMenu.tscn")
