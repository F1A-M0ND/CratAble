extends RefCounted

# Hit testing uses each surface's local coordinates, including nested rotated fields.
static func surface_at(parent: Control, point: Vector2, excluded: Array = [], zones: bool = true) -> Control:
	var children = parent.get_children()
	children.reverse()
	for child in children:
		if not child is Control or not child.is_visible_in_tree() or child.is_queued_for_deletion(): continue
		var skip = false
		for item in excluded:
			if item == child or item.is_ancestor_of(child): skip = true
		if skip: continue
		var category = child.get_meta("component_category", "")
		if category not in ["field", "zone"]: continue
		var local = child.get_global_transform().affine_inverse() * point
		if not Rect2(Vector2.ZERO, child.size).has_point(local): continue
		if category == "field":
			return surface_at(child, point, excluded, zones)
		if zones: return child
	return parent

static func reparent_preserving_pose(node: Control, parent: Control):
	if node.get_parent() == parent: return
	var transform = parent.get_global_transform().affine_inverse() * node.get_global_transform()
	node.reparent(parent, false)
	node.rotation = transform.get_rotation()
	node.scale = transform.get_scale()
	node.position = transform.origin - node.pivot_offset + transform.basis_xform(node.pivot_offset)
	if node.has_method("update_base_scale"): node.update_base_scale(node.scale)

static func clamp_inside(node: Control, parent: Control):
	var t = node.get_transform()
	var bounds = Rect2(t * Vector2.ZERO, Vector2.ZERO)
	for point in [Vector2(node.size.x, 0), node.size, Vector2(0, node.size.y)]: bounds = bounds.expand(t * point)
	var offset = Vector2.ZERO
	for axis in [0, 1]:
		if bounds.size[axis] > parent.size[axis]:
			offset[axis] = (parent.size[axis] - bounds.size[axis]) / 2 - bounds.position[axis]
		elif bounds.position[axis] < 0: offset[axis] = -bounds.position[axis]
		elif bounds.end[axis] > parent.size[axis]: offset[axis] = parent.size[axis] - bounds.end[axis]
	node.position += offset

static func place_card(table: Control, card: Control, point: Vector2):
	var surface = surface_at(table.field_canvas, point, [card])
	if surface.get_meta("component_category", "") == "zone":
		if table._will_zone_accept_card(surface, card):
			table._handle_card_dropped_on_zone(card, surface)
			card.move_to_front()
			return
		# A full/select-only zone must not hide or consume a rejected card.
		surface = surface_at(table.field_canvas, point, [card], false)
	reparent_preserving_pose(card, surface)
	table._apply_card_size(card, surface, null)
	if card.has_method("update_base_scale"): card.update_base_scale(card.scale)
	clamp_inside(card, surface)
	card.move_to_front()
