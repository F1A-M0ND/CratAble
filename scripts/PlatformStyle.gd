extends RefCounted

const INK = Color("f5f9ff")
const MUTED = Color("a5b3cf")
const ACCENT = Color("73ceff")
const INDIGO = Color("6677ef")
const SURFACE = Color("121b30")
const BODY_FONT = preload("res://assets/fonts/NotoSansThai.ttf")
const DISPLAY_FONT = preload("res://assets/fonts/Barlow-BlackItalic.ttf")
const ARROW_FONT = preload("res://assets/fonts/NotoSansSymbols.ttf")
const SYMBOL_FONT = preload("res://assets/fonts/NotoSansSymbols2-Regular.ttf")
static var _body_font: Font
static var _display_font: Font

static func body_font() -> Font:
	# ThemeDB's fallback is the project Thai font itself. Use an explicit bundled
	# symbol font instead, so Web exports need neither OS fonts nor a cyclic chain.
	if not _body_font:
		var body = FontVariation.new()
		body.base_font = BODY_FONT
		body.fallbacks = [_ui_symbol_font(ARROW_FONT), _ui_symbol_font(SYMBOL_FONT)]
		_body_font = body
	return _body_font

static func _ui_symbol_font(source: FontFile) -> FontFile:
	var symbols = source.duplicate() as FontFile
	# Godot takes the tallest metrics in the entire fallback chain, even for text
	# with no symbols. Noto Symbols includes very tall specialist glyphs; constrain
	# its line metrics to our Thai body font for all UI sizes, leaving outlines intact.
	# Work on copies so the original resources and authored card fonts are untouched.
	for font_size in range(1, 257):
		symbols.set_cache_ascent(0, font_size, BODY_FONT.get_ascent(font_size))
		symbols.set_cache_descent(0, font_size, BODY_FONT.get_descent(font_size))
	return symbols

static func display_font() -> Font:
	if not _display_font:
		var display = FontVariation.new()
		display.base_font = DISPLAY_FONT
		display.fallbacks = [body_font()]
		_display_font = display
	return _display_font

static func glass(color: Color, radius: int = 14) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_border_width_all(1)
	style.border_color = Color(0.62, 0.78, 1.0, 0.19)
	style.border_width_top = 1
	style.shadow_color = Color(0.015, 0.025, 0.08, 0.34)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

static func apply(root: Control):
	var theme = Theme.new()
	theme.default_font = body_font()
	theme.default_font_size = 22
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_color", "LineEdit", INK)
	theme.set_color("font_placeholder_color", "LineEdit", MUTED)
	theme.set_stylebox("panel", "PanelContainer", glass(SURFACE))
	theme.set_stylebox("panel", "Panel", glass(SURFACE))
	theme.set_stylebox("normal", "LineEdit", glass(Color("0b1221"), 10))
	var input_focus = glass(Color(0, 0, 0, 0), 10)
	input_focus.border_color = ACCENT
	input_focus.set_border_width_all(2)
	theme.set_stylebox("focus", "LineEdit", input_focus)
	theme.set_color("caret_color", "LineEdit", ACCENT)
	theme.set_color("selection_color", "LineEdit", Color("344880"))
	theme.set_stylebox("normal", "TextEdit", glass(Color("0b1221"), 10))
	theme.set_stylebox("focus", "TextEdit", input_focus)
	theme.set_color("font_color", "TextEdit", INK)
	theme.set_color("caret_color", "TextEdit", ACCENT)
	theme.set_stylebox("panel", "PopupMenu", glass(Color("10182c")))
	theme.set_stylebox("hover", "PopupMenu", glass(Color("24365a"), 8))
	theme.set_color("font_color", "PopupMenu", INK)
	theme.set_color("font_hover_color", "PopupMenu", Color.WHITE)
	theme.set_stylebox("panel", "ItemList", glass(Color("0b1221")))
	theme.set_stylebox("selected", "ItemList", glass(Color("2b3c69"), 8))
	theme.set_stylebox("selected_focus", "ItemList", glass(Color("354b7c"), 8))
	theme.set_color("font_color", "ItemList", INK)
	theme.set_color("font_color", "CheckBox", INK)
	theme.set_color("font_color", "OptionButton", INK)
	root.theme = theme
	if not root.has_node("PlatformBackground"):
		var background = ColorRect.new()
		background.name = "PlatformBackground"
		background.material = space_material()
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(background)
		root.move_child(background, 0)
	_style_controls(root)
	var header = root.get_node_or_null("Header")
	if header and not root.has_node("GlassHeader"):
		var strip = Panel.new()
		strip.name = "GlassHeader"
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		strip.offset_bottom = 64
		strip.add_theme_stylebox_override("panel", glass(Color(0.035, 0.055, 0.10, 0.94), 0))
		root.add_child(strip)
		root.move_child(strip, 1)
		header.offset_bottom = 64
		var body = root.get_node_or_null("HBoxContainer")
		if body: body.offset_top = 76
		var title = header.get_node_or_null("Title")
		if title:
			title.add_theme_font_size_override("font_size", 26)
			if root.scene_file_path == "res://SCENE/Main.tscn":
				title.text = "CratAble  /  " + ("Online table" if Global.online_room_id != "" else "Local table")
				var badge = Label.new()
				badge.text = ("●  " + Global.online_player_role) if Global.online_room_id != "" else "●  Local play"
				badge.add_theme_color_override("font_color", ACCENT)
				header.add_child(badge)
	if "tabletop_view" in root and is_instance_valid(root.tabletop_view):
		root.tabletop_view.add_theme_stylebox_override("panel", glass(Color(0.025, 0.04, 0.075, 0.50), 18))
	if "field_canvas" in root and is_instance_valid(root.field_canvas):
		decorate_board(root.field_canvas)
	if "hand_scroll" in root and is_instance_valid(root.hand_scroll):
		root.hand_scroll.add_theme_stylebox_override("panel", glass(Color(0.04, 0.06, 0.11, 0.94), 18))

static func _style_controls(node: Node):
	# Custom screens own their component styles; only their children are themed.
	# Tabletop objects are excluded entirely below so their saved geometry survives.
	if node is Button and not node.get_meta("style_owned", false):
		preload("res://scripts/InteractionMotion.gd").button(node)
		var accent = "Play" in str(node.name) or "Confirm" in str(node.name) or "Save" in str(node.name)
		var base = Color("5365ce") if accent else Color("1b2942")
		node.add_theme_stylebox_override("normal", glass(base, 12))
		var hover = glass(base.lightened(0.16), 12)
		hover.border_color = Color(0.52, 0.79, 1.0, 0.62)
		node.add_theme_stylebox_override("hover", hover)
		node.add_theme_stylebox_override("pressed", glass(base.darkened(0.16), 12))
		node.add_theme_stylebox_override("disabled", glass(Color("111a2b"), 12))
		node.add_theme_color_override("font_disabled_color", Color("74829c"))
		var focus = glass(Color(0, 0, 0, 0), 12)
		focus.border_color = ACCENT
		focus.set_border_width_all(2)
		node.add_theme_stylebox_override("focus", focus)
		node.add_theme_color_override("font_color", INK)
		if node.name == "CollapseBar":
			for state in ["normal", "hover", "pressed"]:
				var style = node.get_theme_stylebox(state).duplicate()
				style.content_margin_top = 4
				style.content_margin_bottom = 4
				node.add_theme_stylebox_override(state, style)
	if node is LineEdit and not node.get_meta("style_owned", false):
		node.add_theme_stylebox_override("normal", glass(Color("0b1221"), 10))
	for child in node.get_children():
		# User-created tabletop components retain their geometry and controls.
		if not child.has_meta("component_category"): _style_controls(child)

static func decorate_board(board: Control):
	if board.has_node("BoardSurface"): return
	var surface = ColorRect.new()
	surface.name = "BoardSurface"
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader = Shader.new()
	shader.code = """shader_type canvas_item;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void fragment() {
 vec2 uv = UV;
 float plank = floor(uv.y*7.0);
 float seed = hash(vec2(plank,2.0));
 float y = fract(uv.y*7.0);
 float bend = sin(uv.x*9.0+seed*20.0)*0.08 + sin(uv.x*23.0+seed*10.0)*0.025;
 float grain = sin((y+bend)*115.0+sin(uv.x*15.0)*2.0);
 float fine = sin((y+bend)*420.0+uv.x*30.0);
 vec3 wood = mix(vec3(0.19,0.085,0.035),vec3(0.43,0.24,0.11),0.5+0.5*seed);
 wood += grain*0.008+fine*0.002;
 float seam = smoothstep(0.0,0.016,y)*smoothstep(0.0,0.016,1.0-y);
 wood *= mix(0.70,1.0,seam);
 wood += vec3(0.04,0.025,0.012)*exp(-length(uv-vec2(0.4,0.3))*3.0);
 float edge = step(0.006,uv.x)*step(uv.x,0.994)*step(0.009,uv.y)*step(uv.y,0.991);
 COLOR = vec4(mix(vec3(0.11,0.045,0.018),wood,edge),1.0);
}"""
	var material = ShaderMaterial.new()
	material.shader = shader
	surface.material = material
	board.add_child(surface)
	board.move_child(surface, 0)

# Static, inexpensive atmosphere: a distant planet rim and a sparse starfield.
# No TIME, extra screen reads, loops, or input interception on low-end laptops.
static func space_material() -> ShaderMaterial:
	var shader = Shader.new()
	shader.code = """shader_type canvas_item;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void fragment() {
 vec2 uv = UV;
 vec2 p = (uv-vec2(0.82,0.34))*vec2(1.65,1.0);
 float halo = exp(-length(p)*3.8);
 float indigo_glow = exp(-length((uv-vec2(0.12,0.90))*vec2(1.8,1.0))*4.0);
 vec3 color = vec3(0.021,0.032,0.057);
 color += vec3(0.018,0.043,0.095)*halo + vec3(0.028,0.020,0.090)*indigo_glow;
 float planet = length((uv-vec2(0.92,1.58))*vec2(1.55,1.0));
 float rim = exp(-abs(planet-0.94)*130.0);
 float atmosphere = exp(-abs(planet-0.94)*17.0);
 color += vec3(0.12,0.26,0.40)*rim*0.42;
 color += vec3(0.018,0.055,0.13)*atmosphere;
 vec2 cell = floor(uv*vec2(160.0,95.0));
 vec2 local = fract(uv*vec2(160.0,95.0));
 float seed = hash(cell);
 float star = (1.0-smoothstep(0.02,0.12,length(local-vec2(0.5))))*step(0.988,seed);
 color += vec3(0.70,0.83,1.0)*star*(0.18+seed*0.34);
 COLOR = vec4(color,1.0);
}"""
	var material = ShaderMaterial.new()
	material.shader = shader
	return material
