shader_type canvas_item;
render_mode unshaded;

uniform vec2 plane_size = vec2(1.0);
uniform vec2 tilt = vec2(0.0);
uniform float focal_length = 1750.0;
uniform float elapsed = 0.0;
uniform float orbit_time = 0.0;
uniform float hover_energy = 0.0;
uniform float motion_amount = 1.0;
varying vec2 projected_uv;
varying float reciprocal_depth;
varying vec4 tint;

void vertex() {
	// Same projection as the surrounding card planes; all effects are painted
	// in source UVs so the orbit remains attached when the planet precesses.
	vec3 p = vec3(VERTEX - plane_size * 0.5, 0.0);
	float cx = cos(tilt.x);
	float sx = sin(tilt.x);
	float cy = cos(tilt.y);
	float sy = sin(tilt.y);
	p = vec3(p.x, p.y * cx - p.z * sx, p.y * sx + p.z * cx);
	p = vec3(p.x * cy + p.z * sy, p.y, -p.x * sy + p.z * cy);
	reciprocal_depth = 1.0 / max(0.25, 1.0 + p.z / focal_length);
	VERTEX = plane_size * 0.5 + p.xy * reciprocal_depth;
	projected_uv = UV * reciprocal_depth;
	tint = COLOR;
}

void fragment() {
	vec2 uv = projected_uv / reciprocal_depth;
	vec4 artwork = texture(TEXTURE, clamp(uv, vec2(0.0), vec2(1.0)));
	// Only the bright river/waterfalls shimmer; the cliff texture stays rigid.
	float corridor = 1.0 - smoothstep(0.65, 1.0, length((uv - vec2(0.565, 0.425)) / vec2(0.085, 0.17)));
	float water = corridor * smoothstep(0.52, 0.88, artwork.g) * smoothstep(0.15, 0.65, artwork.r);
	water *= smoothstep(0.0, 0.12, artwork.b - artwork.r);
	float flow = pow(0.5 + 0.5 * sin(uv.y * 155.0 - elapsed * 3.4 + sin(uv.x * 70.0) * 1.2), 3.0);
	artwork.rgb += vec3(0.13, 0.22, 0.25) * water * flow * (1.0 + hover_energy * 0.65) * motion_amount;
	artwork.rgb *= 1.0 + sin(tilt.y) * 0.065 - sin(tilt.x) * 0.04;

	// Ellipse fitted to the illustration's ring in its 1536 x 1024 source.
	vec2 pixel = uv * vec2(1536.0, 1024.0);
	vec2 relative = pixel - vec2(760.0, 550.0);
	float c = cos(-0.401426);
	float s = sin(-0.401426);
	vec2 q = vec2(relative.x * c + relative.y * s, -relative.x * s + relative.y * c);
	vec2 axes = vec2(625.0, 137.0);
	vec2 ellipse = q / axes;
	float angle = atan(ellipse.y, ellipse.x + 0.00001);
	float ring_distance = abs(length(ellipse) - 1.0) / max(length(ellipse / axes), 0.0001);
	float phase = orbit_time * 0.28 + 1.4;
	float behind = mod(phase - angle + TAU, TAU);
	float trail = (1.0 - smoothstep(0.0, 0.55 + hover_energy * 0.16, behind));
	trail *= exp(-ring_distance * ring_distance / 22.0);
	// On the far half, opaque terrain covers the light; transparent outer ring
	// stays visible. No second sphere silhouette or floating foreground overlay.
	float front = smoothstep(-0.08, 0.08, sin(angle));
	float globe_mask = 1.0 - smoothstep(0.94, 1.03, length((pixel - vec2(813.0, 535.0)) / vec2(350.0, 355.0)));
	float terrain = smoothstep(0.85, 0.98, artwork.a) * globe_mask;
	float visibility = 1.0 - (1.0 - front) * terrain;
	vec2 orbit_point = axes * vec2(cos(phase), sin(phase));
	vec2 head = vec2(760.0, 550.0) + vec2(orbit_point.x * c - orbit_point.y * s, orbit_point.x * s + orbit_point.y * c);
	float head_distance = length(pixel - head);
	float head_size = mix(7.0, 12.0, 0.5 + 0.5 * sin(phase));
	float core = 1.0 - smoothstep(head_size * 0.25, head_size, head_distance);
	float halo = exp(-head_distance * head_distance / 500.0) * 0.30;
	float energy_alpha = clamp(trail * 0.82 + core + halo, 0.0, 1.0) * visibility * motion_amount;
	vec3 energy_color = mix(vec3(0.18, 0.70, 1.0), vec3(0.88, 0.98, 1.0), core);
	float alpha = artwork.a + energy_alpha * (1.0 - artwork.a);
	vec3 color = (energy_color * energy_alpha + artwork.rgb * artwork.a * (1.0 - energy_alpha)) / max(alpha, 0.0001);
	COLOR = vec4(color, alpha) * tint;
}
