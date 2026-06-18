extends GridContainer

var deck_viewer_ref: Node = null

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY and data.get("type") == "deck_viewer_card":
		if deck_viewer_ref != null:
			deck_viewer_ref._set_deck_viewer_hover(null, 0)
		return true
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var from_idx = data.get("index", -1)
	if from_idx != -1 and deck_viewer_ref != null:
		deck_viewer_ref._clear_deck_viewer_hover()
		var target_idx = deck_viewer_ref._get_drop_index_at_global_position(get_global_transform() * at_position)
		deck_viewer_ref._reorder_deck_viewer_card(from_idx, target_idx)

