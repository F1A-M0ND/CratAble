extends PanelContainer

var card_index: int = -1
var deck_viewer_ref: Node = null # Reference to FieldCreator instance

func _get_drag_data(_at_position: Vector2) -> Variant:
	# Only allow dragging if this is the inserting card
	if deck_viewer_ref == null or card_index != deck_viewer_ref.inserting_card_index:
		return null
		
	# Create drag preview
	var preview = TextureRect.new()
	var tr = null
	for child in get_children():
		if child is VBoxContainer:
			for subchild in child.get_children():
				if subchild is TextureRect:
					tr = subchild
					break
			break
			
	if tr and tr.texture:
		preview.texture = tr.texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview.custom_minimum_size = Vector2(100, 140)
	preview.size = Vector2(100, 140)
	set_drag_preview(preview)
	
	return {"type": "deck_viewer_card", "index": card_index}

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY and data.get("type") == "deck_viewer_card":
		var side = -1 if at_position.x <= size.x / 2.0 else 1
		if deck_viewer_ref != null:
			deck_viewer_ref._set_deck_viewer_hover(self, side)
		return true
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var from_idx = data.get("index", -1)
	var to_idx = card_index
	if at_position.x > size.x / 2.0:
		to_idx += 1
		
	if from_idx != -1 and deck_viewer_ref != null:
		deck_viewer_ref._clear_deck_viewer_hover()
		deck_viewer_ref._reorder_deck_viewer_card(from_idx, to_idx)

func _draw() -> void:
	if deck_viewer_ref != null and deck_viewer_ref.deck_viewer_hovered_item == self:
		var side = deck_viewer_ref.deck_viewer_hover_side
		var color = Color(1.0, 0.85, 0.2, 1.0) # Gold
		var width = 4.0
		if side == -1:
			draw_line(Vector2(2, 0), Vector2(2, size.y), color, width)
		elif side == 1:
			draw_line(Vector2(size.x - 2, 0), Vector2(size.x - 2, size.y), color, width)

