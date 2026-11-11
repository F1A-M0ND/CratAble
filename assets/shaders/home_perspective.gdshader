shader_type canvas_item;
render_mode unshaded;

uniform vec2 plane_size = vec2(1.0);
uniform vec2 tilt = vec2(0.0);
uniform float focal_length = 1750.0;
uniform vec4 atlas_bounds = vec4(0.0, 0.0, 1.0, 1.0);
varying vec2 projected_uv;
varying float reciprocal_depth;
varying vec4 tint;

void vertex() {
	vec3 p = vec3(VERTEX - plane_size * 0.5, 0.0);
	float cx = cos(tilt.x);
	float sx = sin(tilt.x);
	float cy = cos(tilt.y);
	float sy = sin(tilt.y);
	// Rotate the actual four corners around X/Y before projecting them.
	p = vec3(p.x, p.y * cx - p.z * sx, p.y * sx + p.z * cx);
	p = vec3(p.x * cy + p.z * sy, p.y, -p.x * sy + p.z * cy);
	reciprocal_depth = 1.0 / max(0.25, 1.0 + p.z / focal_length);
	VERTEX = plane_size * 0.5 + p.xy * reciprocal_depth;
	// Canvas quads interpolate affinely: divide again in fragment() to keep
	// artwork straight and continuous across both triangles of the tilted card.
	projected_uv = UV * reciprocal_depth;
	tint = COLOR;
}

void fragment() {
	vec2 uv = projected_uv / reciprocal_depth;
	vec2 inset = TEXTURE_PIXEL_SIZE * 0.5;
	uv = clamp(uv, atlas_bounds.xy + inset, atlas_bounds.zw - inset);
	vec4 artwork = texture(TEXTURE, uv) * tint;
	float light = 1.0 + sin(tilt.y) * 0.065 - sin(tilt.x) * 0.04;
	COLOR = vec4(artwork.rgb * light, artwork.a);
}
