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

float coast_noise(vec2 p) {
	return sin(p.x * 0.048 + p.y * 0.037 + 0.41) * 0.42
		+ sin(p.x * 0.11 + p.y * 0.07 + 1.27) * 0.32
		+ sin(p.x * 0.031 - p.y * 0.045 + 2.19) * 0.18
		+ sin((p.x + p.y) * 0.019) * 0.08;
}

float island_land(vec2 p_xz) {
	vec2 raw = (p_xz - world_min_xz) / max(world_size_xz, vec2(0.001));
	vec2 p = (raw - vec2(0.5)) * 2.0;
	float ellipse = sqrt(pow(p.x / 0.84, 2.0) + pow(p.y / 0.76, 2.0));
	return 1.0 - (ellipse + coast_noise(p_xz) * 0.22);
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
	// #47: unexplored interior stays fully unknown. The noisy waterline
	// is world geography (G1) — fog does not paint a rectangular pad
	// over the sea or the beach. Off-map stays clear.
	vec2 outside = max(world_min_xz - world_xz, world_xz - (world_min_xz + world_size_xz));
	float dist_out = max(max(outside.x, outside.y), 0.0);
	float land = smoothstep(-0.05, 0.04, island_land(world_xz));
	float lip = (1.0 - land) * smoothstep(0.42, 0.74, visibility) * (1.0 - smoothstep(0.6, max(shore_fade_metres * 0.55, 2.5), dist_out)) * 0.18;
	// Interior unknown stays a mist over land (entities are not spawned).
	// Coast and off-map stay clear so the sea is the sea.
	ALPHA = unknown * unknown_opacity * 0.58 * land + lip;
}
