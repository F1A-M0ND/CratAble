extends Control

# Decorative layers only. Pointer polling allows all menu controls to retain input.
const PLANET = preload("res://assets/art/space-planet-layer.png")
const PIECES = preload("res://assets/art/space-pieces-atlas.png")
const PERSPECTIVE = preload("res://assets/shaders/home_perspective.gdshader")
const PLANET_MOTION = preload("res://assets/shaders/home_planet.gdshader")
const DESIGN_SIZE = Vector2(1536, 1024)
var _layers: Array[Dictionary] = []
var _elapsed = 0.0
var _view = Vector2.ZERO
var _motion_enabled = true
var _window_focused = true
var _fit = 1.0
var _origin = Vector2.ZERO
var _planet: TextureRect
var _planet_hover = 0.0
var _orbit_time = 0.0

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Back-to-front: distant crescent, star card, globe, foreground cards and dice.
	_add_crescent()
	_add_piece("StarCard", Rect2(768, 0, 768, 512), Vector2(735, 263), Vector2(790, 527), 0.65, 1.2, 1.7)
	_add_layer("CanyonPlanet", PLANET, Vector2(768, 512), DESIGN_SIZE, 0.30, 2.6, 0.5)
	_add_piece("LandscapeCard", Rect2(0, 0, 768, 512), Vector2(345, 575), Vector2(1040, 693), 1.10, 0.0, 2.4)
	_add_piece("OrbitCard", Rect2(0, 512, 768, 512), Vector2(1180, 622), Vector2(940, 627), 0.90, 2.1, -2.2)
	_add_piece("Dice", Rect2(768, 512, 768, 512), Vector2(1005, 868), Vector2(430, 287), 1.55, 3.5, 6.0)
	resized.connect(_layout)
	visibility_changed.connect(_update_processing)
	_layout()
	_update_processing()

func _add_piece(node_name: String, region: Rect2, center: Vector2, extent: Vector2, depth: float, phase: float, turn: float):
	var texture = AtlasTexture.new()
	texture.atlas = PIECES
	texture.region = region
	texture.filter_clip = true
	_add_layer(node_name, texture, center, extent, depth, phase, turn)

func _add_layer(node_name: String, texture: Texture2D, center: Vector2, extent: Vector2, depth: float, phase: float, turn: float):
	var layer = TextureRect.new()
	layer.name = node_name
	layer.texture = texture
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_SCALE
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var perspective = ShaderMaterial.new()
	perspective.shader = PLANET_MOTION if node_name == "CanyonPlanet" else PERSPECTIVE
	if node_name == "CanyonPlanet":
		_planet = layer
	if texture is AtlasTexture:
		var atlas: AtlasTexture = texture
		var atlas_size = atlas.atlas.get_size()
		perspective.set_shader_parameter("atlas_bounds", Vector4(atlas.region.position.x / atlas_size.x, atlas.region.position.y / atlas_size.y, atlas.region.end.x / atlas_size.x, atlas.region.end.y / atlas_size.y))
	layer.material = perspective
	add_child(layer)
	_layers.append({"node": layer, "center": center, "extent": extent, "depth": depth, "phase": phase, "turn": turn})

func _add_crescent():
	var crescent = ColorRect.new()
	crescent.name = "DistantPlanet"
	crescent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader = Shader.new()
	shader.code = """shader_type canvas_item;
void fragment() {
 vec2 p = (UV - vec2(0.5)) * 2.0;
 float r = length(p);
 float sphere = 1.0 - smoothstep(0.92, 0.94, r);
 float z = sqrt(max(0.0, 1.0-dot(p,p)));
 float light = max(0.0,dot(normalize(vec3(p,z)),normalize(vec3(0.85,-0.45,-0.25))));
 float rim = exp(-abs(r-0.94)*95.0);
 float haze = exp(-abs(r-0.94)*22.0);
 vec3 color = mix(vec3(0.008,0.02,0.065),vec3(0.10,0.41,0.85),pow(light,1.7));
 color += vec3(0.28,0.65,1.0)*rim*(0.15+light*2.0);
 COLOR=vec4(color+haze*vec3(0.015,0.07,0.18),max(sphere,haze*0.35));
}"""
	var glow = ShaderMaterial.new()
	glow.shader = shader
	crescent.material = glow
	add_child(crescent)
	_layers.append({"node": crescent, "center": Vector2(1035, 310), "extent": Vector2(580, 580), "depth": 0.12, "phase": 0.5, "turn": 0.0})

func _layout():
	_fit = maxf(0.001, minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y))
	_origin = (size - DESIGN_SIZE * _fit) * 0.5
	for layer in _layers:
		var node: Control = layer.node
		node.size = layer.extent * _fit
		node.pivot_offset = node.size * 0.5
		if node is TextureRect:
			node.material.set_shader_parameter("plane_size", node.size)
			node.material.set_shader_parameter("focal_length", 1750.0 * _fit)
	_pose_layers()

func _process(delta: float):
	var step = minf(delta, 0.05)
	_elapsed += step
	var hover_target = 0.0
	if is_instance_valid(_planet) and _planet.size.x > 0.0 and _planet.size.y > 0.0:
		var point = _planet.get_local_mouse_position() / _planet.size
		# Poll the globe's silhouette without putting an input-catching Control
		# above the hero or menu. Hover energizes the orbit instead of adding tilt.
		hover_target = 1.0 if ((point - Vector2(0.53, 0.51)) / Vector2(0.23, 0.36)).length() < 1.0 else 0.0
	_planet_hover = lerpf(_planet_hover, hover_target, 1.0 - exp(-3.0 * step))
	_orbit_time += step * (1.0 + _planet_hover * 0.35)
	_pose_layers()

# Home supplies one eased camera for the entire viewport, including the copy area.
func set_view(view: Vector2):
	_view = view.clamp(Vector2(-1, -1), Vector2.ONE) if _motion_enabled else Vector2.ZERO
	# The parent runs first; the regular process combines view and idle drift once.
	if not is_processing():
		_pose_layers()

func _pose_layers():
	for layer in _layers:
		var node: Control = layer.node
		var drift = Vector2.ZERO
		var angle = 0.0
		var tilt = Vector2.ZERO
		var perspective_scale = 1.0
		if _motion_enabled:
			var phase: float = layer.phase
			var depth: float = layer.depth
			drift = Vector2(sin(_elapsed * 0.32 + phase) * 2.5, sin(_elapsed * 0.45 + phase) * 5.0) * depth
			# Near objects travel further than the globe and distant crescent.
			drift -= Vector2(_view.x * 48.0, _view.y * 30.0) * depth
			angle = deg_to_rad(float(layer.turn)) * (sin(_elapsed * 0.28 + phase) * 0.38 - _view.x * 0.75 + _view.y * 0.2)
			var tilt_strength = 0.22 if node.name == "CanyonPlanet" else 0.8 + depth * 0.22
			tilt = Vector2(_view.y * 0.28, -_view.x * 0.40) * tilt_strength
			tilt += Vector2(sin(_elapsed * 0.21 + phase), cos(_elapsed * 0.24 + phase)) * 0.025 * tilt_strength
			perspective_scale += (_view.x * (Vector2(layer.center).x / DESIGN_SIZE.x - 0.5) * 0.045 + _view.y * 0.012) * depth
			if node == _planet:
				# A slower precession, elliptical drift and a traveling orbit give
				# the globe its own rhythm, distinct from the cursor-tilted cards.
				drift += Vector2(sin(_elapsed * 0.24) * 9.0, cos(_elapsed * 0.31) * 15.0)
				angle += deg_to_rad(4.2) * sin(_elapsed * 0.19)
				tilt += Vector2(sin(_elapsed * 0.22) * 0.09, cos(_elapsed * 0.17) * 0.14)
				perspective_scale += sin(_elapsed * 0.27) * 0.01
		node.position = _origin + (Vector2(layer.center) - Vector2(layer.extent) * 0.5 + drift) * _fit
		node.rotation = angle
		node.scale = Vector2.ONE * perspective_scale
		if node is TextureRect:
			node.material.set_shader_parameter("tilt", tilt)
		if node == _planet:
			node.material.set_shader_parameter("elapsed", _elapsed)
			node.material.set_shader_parameter("orbit_time", _orbit_time)
			node.material.set_shader_parameter("hover_energy", _planet_hover)
			node.material.set_shader_parameter("motion_amount", 1.0 if _motion_enabled else 0.0)

func set_motion_enabled(enabled: bool):
	_motion_enabled = enabled
	if not enabled:
		_view = Vector2.ZERO
		_planet_hover = 0.0
		_pose_layers()
	_update_processing()

func _notification(what: int):
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_window_focused = false
		_view = Vector2.ZERO
		_planet_hover = 0.0
		_pose_layers()
		_update_processing()
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_window_focused = true
		_update_processing()

func _update_processing():
	set_process(_motion_enabled and _window_focused and is_visible_in_tree())
