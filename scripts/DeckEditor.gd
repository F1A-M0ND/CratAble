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
	amount_popup.get_ok_button().text = "Set"
	amount_popup.add_button("Add", true, "add_copies")
	amount_popup.confirmed.connect(_on_amount_confirmed)
	amount_popup.custom_action.connect(func(action):
		if action == "add_copies" and target_path_for_amount != "":
			_add_card_copies(target_path_for_amount, int(amount_spin.value))
			amount_popup.hide()
	)
	add_child(amount_popup)
	
	_init_online_dialogs()
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
		_set_card_copies(target_path_for_amount, int(amount_spin.value))

func _set_card_copies(path: String, amount: int):
	if deck_data["groups"].size() == 0:
		return
	if active_group_idx < 0 or active_group_idx >= deck_data["groups"].size():
		active_group_idx = 0
	
	var group = deck_data["groups"][active_group_idx]
	if amount <= 0:
		group["cards"].erase(path)
	else:
		group["cards"][path] = amount
	
	_refresh_deck_ui()

# --- Library Area ---
func _load_library_cards():
	loaded_cards.clear()
	card_cache.clear()
	for child in card_grid.get_children():
		child.queue_free()
		
	SupabaseService.fetch_all_cards(func(status, data):
		if status == 200 and typeof(data) == TYPE_ARRAY:
			for card_row in data:
				_create_library_thumbnail(card_row)
		else:
			print("Failed to fetch library cards: ", status)
	)

func _create_library_thumbnail(card_row: Dictionary):
	var stats_data = {}
	if card_row.has("stats") and typeof(card_row["stats"]) == TYPE_DICTIONARY:
		stats_data = card_row["stats"]
	else:
		stats_data = card_row
		
	var card_name_str = card_row.get("name", "Untitled")
	var card_uuid = card_row.get("id", "")
	
	card_cache[card_uuid] = {
		"name": card_name_str,
		"image_tex": null,
		"has_image": false,
		"card_row": card_row
	}
	
	var margin = MarginContainer.new()
	margin.custom_minimum_size = Vector2(100, 140)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var tex = TextureRect.new()
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var img_url = card_row.get("image_url", "")
	if img_url == "" and stats_data.has("image_path"):
		img_url = stats_data["image_path"]
		
	if img_url != "":
		if img_url.begins_with("http"):
			SupabaseService.get_texture_or_load(img_url, func(texture):
				if texture and is_instance_valid(tex):
					tex.texture = texture
					if card_cache.has(card_uuid):
						card_cache[card_uuid]["image_tex"] = texture
						card_cache[card_uuid]["has_image"] = true
						_refresh_deck_ui()
			)
		else:
			var img = Image.new()
			if img.load(img_url) == OK:
				var texture = ImageTexture.create_from_image(img)
				tex.texture = texture
				card_cache[card_uuid]["image_tex"] = texture
				card_cache[card_uuid]["has_image"] = true
		
	var lbl = Label.new()
	lbl.text = card_name_str
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lbl.custom_minimum_size = Vector2(10, 0)
	
	vbox.add_child(tex)
	vbox.add_child(lbl)
	
	var btn = Button.new()
	btn.modulate = Color(1, 1, 1, 0)
	btn.button_down.connect(func(): pressed_card_paths[card_uuid] = 0.0)
	btn.button_up.connect(func():
		if pressed_card_paths.has(card_uuid):
			var time_held = pressed_card_paths[card_uuid]
			pressed_card_paths.erase(card_uuid)
			if time_held < 0.5:
				_add_card_copies(card_uuid, 1)
	)
	Global.make_card_inspectable(btn, card_row)
	
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
		
		var up_btn = Button.new()
		up_btn.text = "↑"
		up_btn.disabled = (i == 0)
		up_btn.pressed.connect(func():
			var temp = deck_data["groups"][i]
			deck_data["groups"][i] = deck_data["groups"][i - 1]
			deck_data["groups"][i - 1] = temp
			if active_group_idx == i:
				active_group_idx = i - 1
			elif active_group_idx == i - 1:
				active_group_idx = i
			_refresh_deck_ui()
		)
		header_hbox.add_child(up_btn)
		
		var down_btn = Button.new()
		down_btn.text = "↓"
		down_btn.disabled = (i == deck_data["groups"].size() - 1)
		down_btn.pressed.connect(func():
			var temp = deck_data["groups"][i]
			deck_data["groups"][i] = deck_data["groups"][i + 1]
			deck_data["groups"][i + 1] = temp
			if active_group_idx == i:
				active_group_idx = i + 1
			elif active_group_idx == i + 1:
				active_group_idx = i
			_refresh_deck_ui()
		)
		header_hbox.add_child(down_btn)
		
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
	Global.make_card_inspectable(btn, path)
	
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

var online_load_popup: ConfirmationDialog
var online_load_list: ItemList
var online_decks_cache = []

func _init_online_dialogs():
	online_load_popup = ConfirmationDialog.new()
	online_load_popup.title = "Open Online Deck"
	online_load_popup.min_size = Vector2i(500, 400)
	
	var vbox = VBoxContainer.new()
	
	var lbl = Label.new()
	lbl.text = "Select a deck to load from Supabase:"
	vbox.add_child(lbl)
	
	online_load_list = ItemList.new()
	online_load_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	online_load_list.custom_minimum_size = Vector2(0, 250)
	vbox.add_child(online_load_list)
	
	online_load_popup.add_child(vbox)
	online_load_popup.confirmed.connect(_on_online_load_confirmed)
	
	online_load_popup.add_button("Delete Selected", true, "delete_deck")
	online_load_popup.custom_action.connect(_on_online_deck_custom_action)
	
	add_child(online_load_popup)

func _on_online_deck_custom_action(action: String):
	if action == "delete_deck":
		var selected = online_load_list.get_selected_items()
		if selected.size() > 0:
			var idx = selected[0]
			var deck = online_decks_cache[idx]
			var db_id = deck.get("id", "")
			if db_id != "":
				var confirm_del = ConfirmationDialog.new()
				confirm_del.title = "Confirm Delete"
				confirm_del.dialog_text = "Are you sure you want to delete deck '" + deck.get("name", "Untitled") + "'?"
				confirm_del.confirmed.connect(func():
					SupabaseService.delete_deck(db_id, func(status, response):
						if status == 200 or status == 204:
							print("Deck deleted successfully")
							# Refresh the list
							_on_open_pressed()
						else:
							error_dialog.dialog_text = "Failed to delete deck."
							error_dialog.popup_centered()
					)
				)
				add_child(confirm_del)
				confirm_del.popup_centered()

func _on_save_pressed():
	var deck_name_str = deck_data.get("deck_name", "New Deck").strip_edges()
	if deck_name_str == "":
		deck_name_str = "New Deck"
		
	save_btn.disabled = true
	save_btn.text = "Saving..."
	
	var db_id = deck_data.get("db_id", "")
	var cards_data_to_save = deck_data.duplicate()
	cards_data_to_save.erase("db_id")
	
	var on_save_complete = func(status, response):
		save_btn.disabled = false
		save_btn.text = "Save"
		if status == 200 or status == 201:
			print("Deck saved successfully!")
			if typeof(response) == TYPE_ARRAY and response.size() > 0:
				deck_data["db_id"] = response[0].get("id", "")
			elif typeof(response) == TYPE_DICTIONARY:
				deck_data["db_id"] = response.get("id", "")
				
			var success_dialog = AcceptDialog.new()
			success_dialog.title = "Save Successful"
			success_dialog.dialog_text = "Deck '" + deck_name_str + "' saved to Supabase!"
			add_child(success_dialog)
			success_dialog.popup_centered()
		else:
			error_dialog.dialog_text = "Failed to save deck to Supabase. (Status: " + str(status) + ")"
			error_dialog.popup_centered()
			
	if db_id != "":
		SupabaseService.update_deck(db_id, deck_name_str, cards_data_to_save, on_save_complete)
	else:
		SupabaseService.insert_deck(deck_name_str, cards_data_to_save, on_save_complete)

func _on_open_pressed():
	open_btn.disabled = true
	open_btn.text = "Loading..."
	SupabaseService.fetch_all_decks(func(status, data):
		open_btn.disabled = false
		open_btn.text = "Open"
		if status == 200 and typeof(data) == TYPE_ARRAY:
			online_decks_cache = data
			online_load_list.clear()
			for deck in data:
				var dname = deck.get("name", "Untitled Deck")
				online_load_list.add_item(dname)
			online_load_popup.popup_centered()
		else:
			error_dialog.dialog_text = "Failed to fetch decks from Supabase. (Status: " + str(status) + ")"
			error_dialog.popup_centered()
	)

func _on_online_load_confirmed():
	var selected_indices = online_load_list.get_selected_items()
	if selected_indices.size() > 0:
		var idx = selected_indices[0]
		var deck = online_decks_cache[idx]
		
		var db_cards_data = deck.get("cards_data", {})
		if typeof(db_cards_data) == TYPE_DICTIONARY and db_cards_data.has("groups"):
			deck_data = db_cards_data
			deck_data["deck_name"] = deck.get("name", "New Deck")
		else:
			deck_data = {
				"deck_name": deck.get("name", "New Deck"),
				"groups": [
					{
						"name": "Main Deck",
						"min": 40,
						"max": 60,
						"shuffle_at_start": false,
						"cards": db_cards_data
					}
				]
			}
		
		deck_data["db_id"] = deck.get("id", "")
		active_group_idx = 0
		_refresh_deck_ui()

func _on_file_selected(path: String):
	pass

func _save_deck_to_file(path: String):
	pass

func _load_deck_from_file(path: String):
	pass

func _on_back_pressed():
	Global.main_menu_tab = "CUSTOM"
	Global.switch_scene("res://scenes/MainMenu.tscn")
