extends RefCounted

# Named, node-bound tweens cancel their predecessor: fast input never queues motion.
static func tween(node: Control, key: String) -> Tween:
	var previous = node.get_meta(key) if node.has_meta(key) else null
	if previous is Tween and previous.is_valid(): previous.kill()
	var result = node.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	node.set_meta(key, result)
	return result

static func button(button_node: Button):
	if button_node.has_meta("motion_ready"): return
	button_node.set_meta("motion_ready", true)
	button_node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button_node.mouse_entered.connect(func(): _button_scale(button_node, 1.025))
	button_node.mouse_exited.connect(func(): _button_scale(button_node, 1.0))
	button_node.button_down.connect(func(): _button_scale(button_node, 0.975))
	button_node.button_up.connect(func(): _button_scale(button_node, 1.0))

static func _button_scale(node: Button, factor: float):
	if node.disabled: factor = 1.0
	node.pivot_offset = node.size / 2
	tween(node, "button_motion").tween_property(node, "scale", Vector2.ONE * factor, 0.12)

static func reveal(node: Control):
	node.modulate.a = 0.0
	tween(node, "reveal_motion").tween_property(node, "modulate:a", 1.0, 0.16)

static func dice(node: Control, result: int):
	var label = node.get_node_or_null("DiceLabel")
	if not label: return
	# Animate only the label, so rolling cannot change the board's shared geometry.
	label.pivot_offset = label.size / 2
	label.text = "D6: " + str(result)
	label.rotation = -0.2
	label.scale = Vector2(0.8, 0.8)
	var motion = tween(label, "roll_motion").set_parallel(true)
	motion.tween_property(label, "rotation", 0.0, 0.2)
	motion.tween_property(label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)

static func remote_pose(node: Control, pos: Vector2, angle: float, immediate: bool = false):
	var motion = tween(node, "remote_motion")
	if immediate:
		motion.kill()
		node.position = pos
		node.rotation_degrees = angle
		return
	var target_angle = node.rotation + wrapf(deg_to_rad(angle) - node.rotation, -PI, PI)
	motion.set_parallel(true)
	motion.tween_property(node, "position", pos, 0.06)
	motion.tween_property(node, "rotation", target_angle, 0.06)

static func flip_visual(card: Control):
	# Animate visual children only; layout, hit testing and network state stay exact.
	for child in card.get_children():
		if child is Control and child.mouse_filter == Control.MOUSE_FILTER_IGNORE and not child.is_in_group("editor_only"):
			child.pivot_offset = child.size / 2
			child.scale.x = 0.12
			tween(child, "flip_motion").tween_property(child, "scale:x", 1.0, 0.16)
