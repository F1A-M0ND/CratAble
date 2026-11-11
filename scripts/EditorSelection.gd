extends Control

var editor: Control
var selected: Array = []
var clipboard: Array = []
var marquee = false
var moving = false
var start = Vector2.ZERO
var finish = Vector2.ZERO
var canvas_active = false
var paste_serial = 0
var history = preload("res://scripts/EditorHistory.gd").new()
var history_pending = false
var last_outline: Array = []
var drag_origins: Dictionary = {}
var guides: Array = []
var toast_text = ""
var toast_time = 0.0

func notify_edit(message: String):
	toast_text = message
	toast_time = 2.0

func undo(redo: bool = false):
	if not enabled() or blocked(): return
	if history.travel(1 if redo else -1):
		selected.clear()
		notify_edit("Redo" if redo else "Undo")


func _ready():
	history.editor = editor
	history.record()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 4096
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func enabled() -> bool:
	return is_instance_valid(editor) and not editor.is_test_mode and not Global.play_mode and Global.online_room_id.is_empty()

func blocked() -> bool:
	var focus = get_viewport().gui_get_focus_owner()
	return focus is LineEdit or focus is TextEdit or _has_dialog(editor)

func _has_dialog(node: Node) -> bool:
	for child in node.get_children():
		if child is Window and child.visible: return true
		if _has_dialog(child): return true
	return false

func _process(delta):
	var had_toast = toast_time > 0
	toast_time = maxf(0, toast_time - delta)
	if history_pending and enabled() and not blocked() and not moving and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		history_pending = false
		history.record()
	selected = selected.filter(func(n): return is_instance_valid(n) and not n.is_queued_for_deletion())
	if not enabled():
		selected.clear()
		marquee = false
		moving = false
		canvas_active = false
	var outline = []
	for node in selected: outline.append(corners(node))
	if outline != last_outline or marquee or moving or had_toast:
		queue_redraw()
	last_outline = outline

func components() -> Array:
	var nodes = []
	editor._gather_components(editor.field_canvas, nodes)
	return nodes.filter(func(n): return n.is_visible_in_tree() and not n.is_queued_for_deletion())

func corners(node: Control) -> PackedVector2Array:
	var t = node.get_global_transform()
	return PackedVector2Array([t * Vector2.ZERO, t * Vector2(node.size.x, 0), t * node.size, t * Vector2(0, node.size.y)])

func select_rect(rect: Rect2, additive: bool):
	if not enabled() or blocked(): return
	if not additive: selected.clear()
	for node in components():
		var inside = true
		for point in corners(node):
			if not rect.has_point(point): inside = false
		if inside and not node in selected: selected.append(node)

func roots() -> Array:
	return selected.filter(func(n):
		for other in selected:
			if other != n and other.is_ancestor_of(n): return false
		return true
	)

func handle_event(event: InputEvent) -> bool:
	if event is InputEventKey or (event is InputEventMouseButton and not event.pressed): history_pending = true
	if enabled() and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and editor.tabletop_view.get_global_rect().has_point(event.position) and not _has_dialog(editor):
		var focus = get_viewport().gui_get_focus_owner()
		if focus is LineEdit or focus is TextEdit: focus.release_focus()
	if not enabled() or blocked():
		marquee = false
		moving = false
		return false
	if event is InputEventKey and event.pressed and not event.echo and canvas_active:
		if event.keycode == KEY_ESCAPE:
			selected.clear()
			marquee = false
			moving = false
			return true
		if event.keycode == KEY_DELETE:
			delete_selected()
			return true
		if event.ctrl_pressed or event.meta_pressed:
			match event.keycode:
				KEY_Z: undo(event.shift_pressed)
				KEY_Y: undo(true)
				KEY_C: copy_selected()
				KEY_V: paste_selected()
				KEY_D:
					if selected.is_empty(): return true
					copy_selected()
					paste_selected()
				KEY_A: selected = components()
				_: return false
			return true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			if marquee:
				finish = event.position
				select_rect(Rect2(start, finish - start).abs(), event.shift_pressed)
			if moving:
				_finish_move()
				history.record()
			guides.clear()
			drag_origins.clear()
			var handled = marquee or moving
			marquee = false
			moving = false
			return handled
		var hovered = get_viewport().gui_get_hovered_control()
		if hovered is BaseButton or (is_instance_valid(hovered) and str(hovered.name) in ["RotateHandle", "ResizeHandle"]):
			return false
		canvas_active = editor.tabletop_view.get_global_rect().has_point(event.position)
		if not canvas_active: return false
		var target = hovered
		while is_instance_valid(target) and target != editor.field_canvas and not target.has_meta("component_category"):
			target = target.get_parent() as Control
		if is_instance_valid(target) and target != editor.field_canvas and editor.field_canvas.is_ancestor_of(target):
			if event.shift_pressed and target in selected:
				selected.erase(target)
				return true
			if not target in selected:
				if not event.shift_pressed: selected.clear()
				selected.append(target)
			for node in roots():
				if node.has_method("force_exit_hover"):
					node.force_exit_hover()
					if node.hover_tween: node.hover_tween.kill()
					node.scale = node.base_scale
			history.record()
			drag_origins.clear()
			for node in roots(): drag_origins[node] = node.global_position
			moving = true
		else:
			if not event.shift_pressed: selected.clear()
			marquee = true
		start = event.position
		finish = start
		return true
	if event is InputEventMouseMotion:
		finish = event.position
		if moving:
			var delta = finish - start
			if event.shift_pressed:
				if absf(delta.x) >= absf(delta.y): delta.y = 0
				else: delta.x = 0
			for node in roots():
				if drag_origins.has(node): node.global_position = drag_origins[node] + delta
				else: node.position += node.get_parent().get_global_transform().affine_inverse().basis_xform(event.relative)
			_update_guides(event.alt_pressed, event.shift_pressed)
		return moving or marquee
	return false

func copy_selected():
	if not enabled() or blocked() or selected.is_empty(): return
	clipboard.clear()
	var state = editor._capture_current_field_state()
	var source_roots = roots()
	for data in state.components_layout:
		var node = editor._find_component(str(data.component_id))
		if not is_instance_valid(node): continue
		var include = false
		for root in source_roots:
			if root == node or root.is_ancestor_of(node): include = true
		if not include: continue
		var entry = data.duplicate(true)
		entry["copy_root"] = node in source_roots
		entry["copy_parent"] = str(node.get_parent().get_meta("component_id", "FieldCanvas"))
		var transform = node.get_transform()
		if entry.copy_root:
			transform = editor.field_canvas.get_global_transform().affine_inverse() * node.get_global_transform()
		entry["copy_transform"] = transform
		entry["copy_size"] = node.size
		clipboard.append(entry)
	paste_serial = 0
	notify_edit("Copied %d objects" % source_roots.size())

func paste_selected():
	if not enabled() or blocked() or clipboard.is_empty(): return
	history.record()
	paste_serial += 1
	var entries = clipboard.duplicate(true)
	var prefix = "Copy_" + str(Time.get_ticks_usec()) + "_" + str(paste_serial) + "_"
	for entry in entries:
		entry.component_id = prefix + str(entry.id)
		if entry.copy_root: entry.parent_id = -1
	var canvas = editor._capture_current_field_state().canvas_settings
	editor._load_field_from_dict({"canvas_settings": canvas, "components_layout": entries}, true, true)
	selected.clear()
	for entry in entries:
		var node = editor._find_component(entry.component_id)
		if not is_instance_valid(node): continue
		node.custom_minimum_size = Vector2.ZERO
		node.size = entry.copy_size
		node.pivot_offset = node.size / 2
		var transform: Transform2D = entry.copy_transform
		node.rotation = transform.get_rotation()
		node.scale = transform.get_scale()
		# Control.position is before the pivot transform.
		node.position = transform.origin - node.pivot_offset + transform.basis_xform(node.pivot_offset)
		if entry.copy_root:
			node.position += Vector2(24, 24) * paste_serial
			selected.append(node)
		if node.has_method("update_base_scale"): node.update_base_scale(node.scale)

	for entry in entries:
		if not entry.copy_root: continue
		var node = editor._find_component(entry.component_id)
		var parent = editor._find_component(entry.copy_parent)
		if is_instance_valid(node) and is_instance_valid(parent) and parent != editor.field_canvas:
			preload("res://scripts/TabletopPlacement.gd").reparent_preserving_pose(node, parent)
	_finish_move(true)
	history.record()
	notify_edit("Pasted %d objects" % selected.size())

func delete_selected():
	if not enabled() or blocked() or selected.is_empty(): return
	history.record()
	var count = roots().size()
	for node in roots():
		node.get_parent().remove_child(node)
		node.queue_free()
	selected.clear()
	history.record()
	notify_edit("Deleted %d objects / Ctrl+Z to undo" % count)

func _draw():
	if not enabled(): return
	var inverse = get_global_transform().affine_inverse()
	var area = editor.tabletop_view.get_global_rect()
	for guide in guides:
		var a = Vector2(guide[1], area.position.y) if guide[0] == 0 else Vector2(area.position.x, guide[1])
		var b = Vector2(guide[1], area.end.y) if guide[0] == 0 else Vector2(area.end.x, guide[1])
		draw_line(inverse * a, inverse * b, Color(0.45, 0.81, 1, 0.6), 1)
	if toast_time > 0:
		var font = ThemeDB.fallback_font
		var pos = inverse * (area.position + Vector2(24, 40))
		var width = font.get_string_size(toast_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		draw_style_box(preload("res://scripts/PlatformStyle.gd").glass(Color("121b30")), Rect2(pos - Vector2(12, 25), Vector2(width + 24, 40)))
		draw_string(font, pos, toast_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("e2f3ff"))
	for node in selected:
		if not is_instance_valid(node): continue
		var polygon = corners(node)
		for i in range(polygon.size()): polygon[i] = inverse * polygon[i]
		polygon.append(polygon[0])
		draw_polyline(polygon, Color("73ceff"), 2.0, true)
	if marquee:
		var rect = Rect2(inverse * start, inverse.basis_xform(finish - start)).abs()
		draw_rect(rect, Color(0.45, 0.81, 1, 0.12))
		draw_rect(rect, Color("73ceff"), false, 1.5)

func _update_guides(disabled: bool, axis_locked: bool):
	guides.clear()
	if disabled or roots().is_empty(): return
	var anchor = roots()[0]
	var box = Rect2(corners(anchor)[0], Vector2.ZERO)
	for point in corners(anchor): box = box.expand(point)
	var correction = Vector2.ZERO
	var best = Vector2(7, 7)
	var targets = Vector2.ZERO
	for other in components():
		if other in selected: continue
		var skip = false
		for root in roots():
			if root.is_ancestor_of(other) or other.is_ancestor_of(root): skip = true
		if skip: continue
		var target = Rect2(corners(other)[0], Vector2.ZERO)
		for point in corners(other): target = target.expand(point)
		for axis in [0, 1]:
			for source in [box.position[axis], box.get_center()[axis], box.end[axis]]:
				for dest in [target.position[axis], target.get_center()[axis], target.end[axis]]:
					if absf(dest - source) < best[axis]:
						best[axis] = absf(dest - source)
						correction[axis] = dest - source
						targets[axis] = dest
	for axis in [0, 1]:
		if best[axis] < 7: guides.append([axis, targets[axis]])
	if not axis_locked:
		for node in roots(): node.global_position += correction

func _finish_move(keep_parent: bool = false):
	var items = roots()
	var placement = preload("res://scripts/TabletopPlacement.gd")
	for node in items:
		var parent = node.get_parent()
		if keep_parent and parent == editor.field_canvas and node.get_meta("component_category", "") != "field":
			for candidate in items:
				if candidate.get_meta("component_category", "") != "field": continue
				var point = candidate.get_global_transform().affine_inverse() * (node.get_global_transform() * (node.size / 2))
				if Rect2(Vector2.ZERO, candidate.size).has_point(point):
					parent = candidate
					placement.reparent_preserving_pose(node, parent)
		if not keep_parent:
			var center = node.get_global_transform() * (node.size / 2)
			var excluded = items if node.get_meta("component_category", "") == "field" else [node]
			parent = placement.surface_at(editor.field_canvas, center, excluded, false)
			placement.reparent_preserving_pose(node, parent)
		placement.clamp_inside(node, parent)
		node.move_to_front()
	queue_redraw()
