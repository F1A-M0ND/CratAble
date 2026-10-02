extends RefCounted

const INK = Color("fff1e7")
const MUTED = Color("b6aaa3")
const ACCENT = Color("ff8a3d")
const SURFACE = Color("19191f")

static func glass(color: Color, radius: int = 14) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_border_width_all(1)
	style.border_color = Color(1.0, 0.65, 0.42, 0.30)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

static func apply(root: Control):
	var theme = Theme.new()
	theme.default_font_size = 24
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_color", "LineEdit", INK)
	theme.set_color("font_placeholder_color", "LineEdit", MUTED)
	theme.set_stylebox("panel", "PanelContainer", glass(SURFACE))
	theme.set_stylebox("panel", "Panel", glass(SURFACE))
	theme.set_stylebox("normal", "LineEdit", glass(Color("101015"), 10))
	theme.set_stylebox("focus", "LineEdit", glass(Color("37241c"), 10))
	theme.set_stylebox("panel", "PopupMenu", glass(Color("1c191c")))
	root.theme = theme
	var background = ColorRect.new()
	background.name = "PlatformBackground"
	background.material = space_material()
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	root.move_child(background, 0)
	_style_controls(root)
	var header = root.get_node_or_null("Header")
	if header:
		var strip = Panel.new()
		strip.name = "GlassHeader"
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		strip.offset_bottom = 64
		strip.add_theme_stylebox_override("panel", glass(Color(0.055, 0.05, 0.065, 0.88), 0))
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
		root.tabletop_view.add_theme_stylebox_override("panel", glass(Color(0.025, 0.025, 0.04, 0.50), 18))
	if "field_canvas" in root and is_instance_valid(root.field_canvas):
		decorate_board(root.field_canvas)
	if "hand_scroll" in root and is_instance_valid(root.hand_scroll):
		root.hand_scroll.add_theme_stylebox_override("panel", glass(Color(0.06, 0.05, 0.06, 0.94), 18))

static func _style_controls(node: Node):
	if node is Button:
		var accent = "Play" in str(node.name) or "Confirm" in str(node.name) or "Save" in str(node.name)
		var base = Color("a44114") if accent else Color(0.10, 0.09, 0.105, 0.86)
		node.add_theme_stylebox_override("normal", glass(base, 12))
		node.add_theme_stylebox_override("hover", glass(base.lightened(0.18), 12))
		node.add_theme_stylebox_override("pressed", glass(base.darkened(0.16), 12))
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
	if node is LineEdit:
		node.add_theme_stylebox_override("normal", glass(Color("101015"), 10))
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
void fragment() {
 vec2 uv = UV;
 float glow = exp(-length((uv-vec2(0.82,0.12))*vec2(1.0,1.3))*5.0);
 vec3 base = vec3(0.035,0.035,0.05) + vec3(0.19,0.065,0.015)*glow;
 float grid = step(0.987,fract(uv.x*20.0)) + step(0.987,fract(uv.y*14.0));
 float edge = step(0.002,uv.x)*step(uv.x,0.998)*step(0.003,uv.y)*step(uv.y,0.997);
 float sheen = 0.018 * pow(1.0-uv.y,5.0);
 COLOR = vec4(mix(vec3(0.64,0.29,0.12),base+grid*0.009+sheen,edge),1.0);
}"""
	var material = ShaderMaterial.new()
	material.shader = shader
	surface.material = material
	board.add_child(surface)
	board.move_child(surface, 0)

# Static procedural atmosphere: no textures, animation or input interception.
static func space_material() -> ShaderMaterial:
	var shader = Shader.new()
	shader.code = """shader_type canvas_item;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void fragment() {
 vec2 uv = UV;
 vec2 p = (uv-vec2(0.80,0.28))*vec2(1.6,1.0);
 float halo = exp(-length(p)*5.0);
 float orbit = exp(-abs(length(p)-0.48)*180.0)*0.12;
 vec3 color = vec3(0.018,0.019,0.03)+vec3(0.22,0.062,0.012)*halo;
 color += vec3(0.65,0.23,0.07)*orbit;
 vec2 cell = floor(uv*vec2(160.0,95.0));
 vec2 local = fract(uv*vec2(160.0,95.0));
 float seed = hash(cell);
 float star = (1.0-smoothstep(0.02,0.13,length(local-vec2(0.5))))*step(0.979,seed);
 color += vec3(0.85,0.75,0.63)*star*(0.25+seed*0.45);
 COLOR = vec4(color,1.0);
}"""
	var material = ShaderMaterial.new()
	material.shader = shader
	return material
