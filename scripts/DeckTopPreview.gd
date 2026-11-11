extends RefCounted

# The last entry is the next card drawn by pop_back().
static func refresh(deck: Control):
	var cover = deck.get_node_or_null("DeckCover") as TextureRect
	if not cover: return
	var top = ""
	if deck.has_meta("draw_pile"):
		var pile = deck.get_meta("draw_pile")
		if pile is Array and not pile.is_empty(): top = str(pile.back())
	else:
		# Before confirmation, use the same group iteration as pile construction.
		for group in deck.get_meta("deck_data", {}).get("groups", []):
			for key in group.get("cards", {}):
				if int(group.cards[key]) > 0: top = str(key)
	var down = bool(deck.get_meta("deck_data", {}).get("pile_face_down", false))
	if cover.get_meta("top_card", "") == top and cover.get_meta("face_down", false) == down:
		if cover.has_meta("top_card") and (top.is_empty() or down or cover.texture != null or cover.get_meta("loading", false)): return
	cover.set_meta("face_down", down)
	cover.set_meta("top_card", top)
	var revision = int(cover.get_meta("preview_revision", 0)) + 1
	cover.set_meta("preview_revision", revision)
	cover.set_meta("loading", false)
	cover.texture = null
	cover.tooltip_text = ""
	var back = deck.get_node_or_null("DeckBack")
	if is_instance_valid(back): back.visible = down and not top.is_empty()
	if top.is_empty(): return
	if down:
		if not is_instance_valid(back): _create_back(deck)
		return
	var service = deck.get_node("/root/SupabaseService")
	if top.get_extension().to_lower() == "json" and FileAccess.file_exists(top):
		var data = JSON.parse_string(FileAccess.get_file_as_string(top))
		if data is Dictionary: _show_data(cover, revision, data, service)
	elif top.begins_with("http") or FileAccess.file_exists(top):
		_show_data(cover, revision, {"image_path": top}, service)
	elif service.card_cache.has(top):
		_show_row(cover, revision, service.card_cache[top], service)
	else:
		var cover_ref = weakref(cover)
		cover.set_meta("loading", true)
		service.request_supabase("/rest/v1/cards?id=eq." + top.uri_encode(), HTTPClient.METHOD_GET, null, Callable(), func(status, rows):
			var target = cover_ref.get_ref()
			if not _current(target, revision): return
			target.set_meta("loading", false)
			if status == 200 and rows is Array and not rows.is_empty():
				service.card_cache[top] = rows[0]
				_show_row(target, revision, rows[0], service)
		)

static func _current(cover, revision: int) -> bool:
	return is_instance_valid(cover) and not cover.is_queued_for_deletion() and cover.get_meta("preview_revision", -1) == revision

static func _show_row(cover: TextureRect, revision: int, row: Dictionary, service: Node):
	var data = row.get("stats", {}).duplicate()
	data["name"] = row.get("name", "")
	var image = str(row.get("image_url", ""))
	if not image.is_empty(): data["image_path"] = image
	_show_data(cover, revision, data, service)

static func _show_data(cover: TextureRect, revision: int, data: Dictionary, service: Node):
	if not _current(cover, revision): return
	cover.tooltip_text = str(data.get("name", ""))
	var path = str(data.get("image_path", data.get("image_url", "")))
	if path.is_empty(): return
	if path.begins_with("http"):
		var cover_ref = weakref(cover)
		cover.set_meta("loading", true)
		service.get_texture_or_load(path, func(texture):
			var target = cover_ref.get_ref()
			if _current(target, revision):
				target.set_meta("loading", false)
				target.texture = texture
		, cover)
	elif path.begins_with("res://") and ResourceLoader.exists(path):
		cover.texture = load(path) as Texture2D
	elif FileAccess.file_exists(path):
		var image = Image.load_from_file(path)
		if image and not image.is_empty(): cover.texture = ImageTexture.create_from_image(image)

static func _create_back(deck: Control):
	var back = Panel.new()
	back.name = "DeckBack"
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("111a30")
	style.border_color = Color("6677ef")
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	back.add_theme_stylebox_override("panel", style)
	deck.add_child(back)
	deck.move_child(back, deck.get_node("DeckCover").get_index() + 1)
	var label = Label.new()
	label.text = "✦\nCRATABLE\n✦"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("a1deff"))
	label.add_theme_font_size_override("font_size", 15)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back.add_child(label)
