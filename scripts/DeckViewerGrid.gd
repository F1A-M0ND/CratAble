extends Control

var deck_viewer_ref: Node = null
var columns: int = 4
var h_separation: float = 15.0
var v_separation: float = 15.0

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

func update_layout(animate: bool = true):
	var children = get_children()
	var num_children = children.size()
	
	var max_height = 0.0
	
	var row = 0
	var col = 0
	
	for i in range(num_children):
		var child = children[i]
		if not child is Control or not child.visible or child.is_queued_for_deletion():
			continue
			
		var card_size = child.custom_minimum_size
		if card_size == Vector2.ZERO:
			card_size = child.size
			
		var target_x = col * (card_size.x + h_separation)
		var target_y = row * (card_size.y + v_separation)
		var target_pos = Vector2(target_x, target_y)
		
		# Animate
		if animate:
			var prev_tween = child.get_meta("layout_tween", null)
			if prev_tween and prev_tween.is_valid():
				prev_tween.kill()
			
			var tween = get_tree().create_tween()
			child.set_meta("layout_tween", tween)
			tween.tween_property(child, "position", target_pos, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			child.position = target_pos
		
		col += 1
		if col >= columns:
			col = 0
			row += 1
			
		var end_y = target_y + card_size.y
		if end_y > max_height:
			max_height = end_y
			
	custom_minimum_size.y = max_height

