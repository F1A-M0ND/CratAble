extends ColorRect

# Homepage-only atmosphere. Uses one lightweight canvas shader; no particles,
# textures, screen reads or accumulated tweens. It never receives pointer input.
var _elapsed: float = 0.0
var _motion_enabled: bool = true
var _window_focused: bool = true
var _view: Vector2 = Vector2.ZERO

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader = Shader.new()
	shader.code = """shader_type canvas_item;
uniform float elapsed = 0.0;
uniform vec2 view = vec2(0.0);

float hash(vec2 p) {
 return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Infinite procedural layers have no texture edges to expose while looking
// around. Each layer has a different depth, density and apparent star size.
float star_layer(vec2 uv, vec2 grid, vec2 offset, float density, float size, float time) {
 vec2 position = (uv + offset) * grid;
 vec2 cell = floor(position);
 float seed = hash(cell);
 vec2 center = vec2(0.28) + fract(vec2(seed * 23.17, seed * 51.93)) * 0.44;
 float star = 1.0 - smoothstep(0.015, size, length(fract(position) - center));
 float twinkle = 0.86 + 0.14 * sin(time * (0.35 + seed * 0.22) + seed * 48.0);
 return star * step(density, seed) * (0.18 + seed * 0.34) * twinkle;
}

void fragment() {
 vec2 uv = UV;
 float t = elapsed;
 vec2 sky = uv + view * vec2(0.012, 0.017);
 vec2 p = (sky - vec2(0.82, 0.34)) * vec2(1.65, 1.0);
 float halo = exp(-length(p) * 3.8);
 float indigo_glow = exp(-length((sky - vec2(0.12, 0.90)) * vec2(1.8, 1.0)) * 4.0);
 vec3 color = vec3(0.021, 0.032, 0.057);
 color += vec3(0.018, 0.043, 0.095) * halo;
 color += vec3(0.028, 0.020, 0.090) * indigo_glow;

 // The nearby planet moves more than the stars. Reproject its spherical
 // surface through camera yaw/pitch instead of sliding a flat planet image.
 vec2 planet_center = vec2(0.92, 1.58) - view * vec2(0.036, 0.045);
 vec2 globe = (uv - planet_center) * vec2(1.55, 1.0);
 float radius = 0.94;
 float distance_to_center = length(globe);
 vec2 sphere_xy = globe / radius;
 float depth = sqrt(max(0.0, 1.0 - dot(sphere_xy, sphere_xy)));
 vec3 sphere_normal = normalize(vec3(sphere_xy, depth));
 float yaw = view.x * 0.16;
 float pitch = -view.y * 0.11;
 vec3 pitched = vec3(sphere_normal.x,
                     sphere_normal.y * cos(pitch) - sphere_normal.z * sin(pitch),
                     sphere_normal.y * sin(pitch) + sphere_normal.z * cos(pitch));
 vec3 world_normal = vec3(pitched.x * cos(yaw) + pitched.z * sin(yaw),
                         pitched.y,
                         -pitched.x * sin(yaw) + pitched.z * cos(yaw));
 float longitude = atan(world_normal.x, world_normal.z + 0.0001) + t * 0.018;
 float latitude = asin(clamp(world_normal.y, -1.0, 1.0));
 float surface = 1.0 - smoothstep(radius - 0.006, radius, distance_to_center);
 float coast = sin(longitude * 5.0 + sin(latitude * 7.0) * 1.8);
 coast += sin(longitude * 11.0 - latitude * 9.0) * 0.37;
 float continents = smoothstep(0.10, 0.65, coast);
 float clouds = 0.5 + 0.5 * sin(longitude * 13.0 + latitude * 17.0 + sin(longitude * 4.0 - latitude * 11.0) * 1.4 + t * 0.007);
 clouds = smoothstep(0.52, 0.90, clouds);
 float limb = 1.0 - smoothstep(0.0, 0.64, depth);
 vec3 planet_color = vec3(0.012, 0.025, 0.063);
 planet_color += vec3(0.014, 0.032, 0.065) * continents;
 planet_color += vec3(0.020, 0.041, 0.074) * clouds * (0.30 + limb * 0.70);
 float sunlight = max(0.0, dot(world_normal, normalize(vec3(-0.45, -0.55, 0.75))));
 planet_color *= 0.72 + sunlight * 0.40;

 // Sparse tiny lights travel with the sphere rather than sliding across the UI.
 vec2 city_grid = vec2(longitude * 39.0, latitude * 49.0);
 float city_seed = hash(floor(city_grid));
 float city = (1.0 - smoothstep(0.03, 0.17, length(fract(city_grid) - vec2(0.5))));
 city *= step(0.955, city_seed) * continents * surface;
 planet_color += vec3(0.11, 0.25, 0.40) * city * 0.32;
 color = mix(color, planet_color, surface * 0.72);

 float rim = exp(-abs(distance_to_center - radius) * 130.0);
 float atmosphere = exp(-abs(distance_to_center - radius) * 17.0);
 float arc_angle = atan(globe.y, globe.x);
 float traveling_light = pow(max(0.0, cos(arc_angle + t * 0.035 + 1.1 + yaw * 0.8 + pitch * 0.5)), 18.0);
 color += vec3(0.12, 0.26, 0.40) * rim * (0.30 + sunlight * 0.16 + traveling_light * 0.28);
 color += vec3(0.018, 0.055, 0.13) * atmosphere * (0.82 + sunlight * 0.22);

 // Looking around reveals depth: distant stars barely move, nearby stars
 // travel farther, and all stay behind the curved silhouette of the planet.
 float far_stars = star_layer(uv, vec2(160.0, 95.0), view * vec2(0.004, 0.006), 0.992, 0.12, t);
 float middle_stars = star_layer(uv, vec2(100.0, 60.0), view * vec2(0.010, 0.015) + vec2(2.3, 4.7), 0.992, 0.10, t);
 float near_stars = star_layer(uv, vec2(64.0, 38.0), view * vec2(0.020, 0.030) + vec2(8.1, 1.9), 0.994, 0.10, t);
 vec3 starlight = vec3(0.52, 0.68, 0.94) * far_stars * 0.62;
 starlight += vec3(0.70, 0.83, 1.0) * middle_stars * 0.82;
 starlight += vec3(0.82, 0.92, 1.0) * near_stars;
 color += starlight * (1.0 - surface);
 COLOR = vec4(color, 1.0);
}"""
	var atmosphere = ShaderMaterial.new()
	atmosphere.shader = shader
	material = atmosphere
	atmosphere.set_shader_parameter("view", _view)
	visibility_changed.connect(_update_processing)
	_update_processing()

func _process(delta: float):
	# Clamp resumed frame times so returning to a background tab never jumps.
	_elapsed += minf(delta, 0.1)
	(material as ShaderMaterial).set_shader_parameter("elapsed", _elapsed)

func set_motion_enabled(enabled: bool):
	_motion_enabled = enabled
	if not enabled:
		set_view(Vector2.ZERO)
	_update_processing()

# Shared homepage camera supplies an already smoothed, normalized cursor.
# No pointer event is consumed here, so every menu control remains clickable.
func set_view(view: Vector2):
	_view = view.clamp(Vector2(-1.0, -1.0), Vector2.ONE) if _motion_enabled else Vector2.ZERO
	if material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter("view", _view)

func _notification(what: int):
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_window_focused = false
		_update_processing()
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_window_focused = true
		_update_processing()

func _update_processing():
	set_process(_motion_enabled and _window_focused and is_visible_in_tree())
