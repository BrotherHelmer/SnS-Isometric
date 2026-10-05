shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;

// Opaque continuation underneath the province. Normal depth testing keeps it
// behind revealed buildings even when the camera is close to a map corner.
uniform vec2 world_min_xz;
uniform vec2 world_size_xz;
uniform float color_scale = 1.0;
varying vec2 world_xz;
float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 local = fract(p);
	local = local * local * (3.0 - 2.0 * local);
	return mix(mix(hash21(cell), hash21(cell + vec2(1, 0)), local.x), mix(hash21(cell + vec2(0, 1)), hash21(cell + vec2(1, 1)), local.x), local.y);
}
void vertex() { world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz; }
void fragment() {
	vec2 raw_uv = (world_xz - world_min_xz) / world_size_xz;
	// Never cover revealed low terrain inside the playable province.
	if (raw_uv.x >= 0.0 && raw_uv.y >= 0.0 && raw_uv.x <= 1.0 && raw_uv.y <= 1.0) { discard; }
	vec2 uv = clamp(raw_uv, vec2(0), vec2(1));
	float mist = value_noise(uv * 8.0 + vec2(-TIME * 0.004, TIME * 0.005));
	ALBEDO = mix(vec3(0.06, 0.12, 0.11), vec3(0.09, 0.16, 0.14), mist * 0.34) * color_scale;
}
