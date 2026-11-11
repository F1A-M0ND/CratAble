extends RefCounted

const STYLE = preload("res://scripts/PlatformStyle.gd")
const ART = preload("res://scripts/ChooserArtwork.gd")

static func heading(parent: Control, eyebrow: String, title_text: String, description: String):
	var column := VBoxContainer.new()
	column.name = "ChooserHeading"
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	column.offset_left = 116
	column.offset_top = 50
	column.offset_right = -116
	column.add_theme_constant_override("separation", 5)
	parent.add_child(column)
	var kicker := _label(eyebrow, 18, Color("83d4ff"))
	kicker.add_theme_font_override("font", STYLE.display_font())
	column.add_child(kicker)
	var title := _label(title_text, 58, Color("f5f8ff"))
	title.add_theme_font_override("font", STYLE.display_font())
	column.add_child(title)
	column.add_child(_label(description, 22, Color("abb9d3")))

static func card(button: Button, number: String, title_text: String, description: String, action: String, motif: String, violet: bool = false):
	button.set_meta("style_owned", true)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for child in button.get_children():
		button.remove_child(child)
		child.queue_free()
	var accent := Color("acb2ff") if violet else Color("7dd4ff")
	var normal = STYLE.glass(Color("111a32"), 24)
	normal.border_color = Color(accent, 0.23)
	var hover = STYLE.glass(Color("192748"), 24)
	hover.border_color = Color(accent, 0.8)
	hover.shadow_color = Color(accent, 0.12)
	hover.shadow_size = 14
	var pressed = STYLE.glass(Color("243961"), 24)
	pressed.border_color = accent
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, normal if state == "normal" else pressed if state == "pressed" else hover)
	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 36
	content.offset_top = 24
	content.offset_right = -36
	content.offset_bottom = -24
	content.add_theme_constant_override("separation", 10)
	button.add_child(content)
	var number_label := _label(number, 19, accent)
	number_label.add_theme_font_override("font", STYLE.display_font())
	content.add_child(number_label)
	var art := ART.new()
	art.motif = motif
	art.accent = accent
	art.custom_minimum_size = Vector2(0, 160)
	content.add_child(art)
	var title := _label(title_text, 40, Color("f7f9ff"))
	title.add_theme_font_override("font", STYLE.display_font())
	content.add_child(title)
	var desc := _label(description, 21, Color("b3c0d8"))
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(desc)
	var link := _label(action + "   →", 22, accent)
	content.add_child(link)
	preload("res://scripts/InteractionMotion.gd").button(button)

static func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
