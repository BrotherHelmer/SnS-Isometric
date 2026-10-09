shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, depth_draw_never, blend_mix, fog_disabled;

// The Director: GFX-B atmospheric unknown. Cool slate wisps, not a
// painted olive floor. Reveal set is unchanged (#47 on-map unknown).
uniform sampler2D visibility_texture : filter_linear, repeat_disable;
uniform vec3 unknown_color = vec3(0.10, 0.13, 0.16);
uniform vec3 mist_color = vec3(0.16, 0.19, 0.22);
uniform vec2 world_min_xz = vec2(-87.5, -87.5);
uniform vec2 world_size_xz = vec2(175.0, 175.0);
uniform float unknown_opacity : hint_range(0.0, 1.0) = 0.998;
uniform float edge_softness : hint_range(0.01, 0.8) = 0.58;
uniform float noise_strength : hint_range(0.0, 0.3) = 0.22;
// Explored shoreline only. Unexplored off-map stays fully unknown (#47).
uniform float shore_fade_metres = 16.0;

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
	float n1 = value_noise(world_uv * 14.0 + vec2(TIME * 0.006, -TIME * 0.004));
	float n2 = value_noise(world_uv * 28.0 + vec2(-TIME * 0.008, TIME * 0.005));
	float n3 = value_noise(world_uv * 6.0 + vec2(TIME * 0.003, TIME * 0.002));
	float mist = n1 * 0.50 + n2 * 0.28 + n3 * 0.22;
	float edge_noise = (mist - 0.5) * noise_strength;
	float revealed = smoothstep(0.5 - edge_softness, 0.5 + edge_softness, visibility + edge_noise) * inside;
	float unknown = 1.0 - revealed;
	// Cool slate + luminance troughs so the sheet reads as volume, not khaki paint.
	vec3 cool = mix(unknown_color, mist_color, mist);
	ALBEDO = cool * mix(0.74, 1.16, mist);
	// Off-map stays opaque wilderness. Multiplying alpha by `inside`
	// used to punch a diamond hole onto the water / peach beach.
	vec2 outside = max(world_min_xz - world_xz, world_xz - (world_min_xz + world_size_xz));
	float dist_out = max(max(outside.x, outside.y), 0.0);
	float frontier = (1.0 - inside) * (1.0 - smoothstep(0.6, max(shore_fade_metres * 0.55, 2.5), dist_out));
	ALBEDO = mix(ALBEDO, mist_color, frontier * 0.35);
	ALPHA = mix(unknown_opacity, unknown * unknown_opacity, inside);
}
