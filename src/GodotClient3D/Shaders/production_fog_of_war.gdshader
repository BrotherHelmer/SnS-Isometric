shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, depth_draw_never, blend_mix, fog_disabled;

uniform sampler2D visibility_texture : filter_linear, repeat_disable;
uniform vec3 unknown_color = vec3(0.045, 0.08, 0.07);
uniform vec3 mist_color = vec3(0.07, 0.13, 0.11);
uniform vec2 world_min_xz = vec2(-87.5, -87.5);
uniform vec2 world_size_xz = vec2(175.0, 175.0);
uniform float unknown_opacity : hint_range(0.0, 1.0) = 0.998;
uniform float edge_softness : hint_range(0.01, 0.5) = 0.42;
uniform float noise_strength : hint_range(0.0, 0.3) = 0.22;

varying vec2 world_xz;

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 local = fract(p);
	local = local * local * (3.0 - 2.0 * local);
	float a = hash21(cell);
	float b = hash21(cell + vec2(1.0, 0.0));
	float c = hash21(cell + vec2(0.0, 1.0));
	float d = hash21(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, local.x), mix(c, d, local.x), local.y);
}

void fragment() {
	// Derive mask coordinates from the same authoritative world bounds used by
	// terrain generation. Mesh UV orientation and camera state are irrelevant.
	vec2 raw_uv = (world_xz - world_min_xz) / max(world_size_xz, vec2(0.001));
	float inside = step(0.0, raw_uv.x) * step(raw_uv.x, 1.0) * step(0.0, raw_uv.y) * step(raw_uv.y, 1.0);
	vec2 world_uv = clamp(raw_uv, vec2(0.0), vec2(1.0));
	float visibility = texture(visibility_texture, world_uv).r;
	float broad_noise = value_noise(world_uv * 17.0 + vec2(TIME * 0.008, -TIME * 0.006));
	float edge_noise = (broad_noise - 0.5) * noise_strength;
	float revealed = smoothstep(0.5 - edge_softness, 0.5 + edge_softness, visibility + edge_noise) * inside;
	float unknown = 1.0 - revealed;
	float mist = value_noise(world_uv * 8.0 + vec2(-TIME * 0.004, TIME * 0.005));
	ALBEDO = mix(unknown_color, mist_color, mist * 0.34);
	// Off-map is fully unknown. Multiplying by `inside` used to punch a hole
	// through the sheet so cliff wedges and water read before the edge was
	// explored. Explored map-edge tiles still feather through smoothstep.
	ALPHA = unknown * unknown_opacity;
}
