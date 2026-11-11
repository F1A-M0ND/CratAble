extends RefCounted

signal changed

var editor: Control
var states: Array = []
var cursor = -1
var restoring = false

func capture() -> Dictionary:
	var state = editor._capture_current_field_state().duplicate(true)
	state["name"] = editor.field_canvas.get_meta("field_name", "Main Field")
	var by_id = {}
	var nodes = []
	editor._gather_components(editor.field_canvas, nodes)
	for item in nodes: by_id[str(item.get_meta("component_id", item.name))] = item
	for data in state.components_layout:
		var node = by_id.get(str(data.component_id))
		if not is_instance_valid(node): continue
		data["editor_scale"] = node.base_scale if "base_scale" in node else node.scale
		data["editor_pivot"] = node.pivot_offset
	return state

func record():
	if restoring: return
	var state = capture()
	if cursor >= 0 and states[cursor] == state: return
	states.resize(cursor + 1)
	states.append(state)
	if states.size() > 50: states.pop_front()
	cursor = states.size() - 1
	changed.emit()

func reset():
	states.clear()
	cursor = -1

func travel(direction: int) -> bool:
	if direction < 0: record()
	var next = cursor + direction
	if next < 0 or next >= states.size(): return false
	cursor = next
	restore(states[cursor].duplicate(true))
	changed.emit()
	return true

func restore(state: Dictionary):
	restoring = true
	editor._load_field_from_dict(state, true)
	for data in state.components_layout:
		var node = editor._find_component(str(data.component_id))
		if not is_instance_valid(node): continue
		node.custom_minimum_size = Vector2.ZERO
		node.size = Vector2(data.size_x, data.size_y)
		node.pivot_offset = data.editor_pivot
		node.position = Vector2(data.position_x, data.position_y)
		node.scale = data.editor_scale
		if node.has_method("update_base_scale"): node.update_base_scale(node.scale)
	restoring = false
