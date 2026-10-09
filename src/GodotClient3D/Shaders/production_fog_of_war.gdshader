shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, depth_draw_never, blend_mix, fog_disabled;

// The Director: GFX-I/J world-space shroud (kept, but hidden). Live FOW
// is production_fog_screen.gdshader. Texture stores shroud amount:
// 0.0 visible, 0.45 explored, 1.0 unexplored. Colour #17272A.
// Frontier feathers 1–1.5 cells. GFX-H island haze is gone.
uniform sampler2D visibility_texture : filter_linear, repeat_disable;
uniform vec3 unknown_color = vec3(0.090, 0.153, 0.165); // #17272A
uniform vec3 mist_color = vec3(0.090, 0.153, 0.165);
uniform vec2 world_min_xz = vec2(-87.5, -87.5);
uniform vec2 world_size_xz = vec2(175.0, 175.0);
uniform float unknown_opacity : hint_range(0.0, 1.0) = 1.0;
uniform float explored_opacity : hint_range(0.0, 1.0) = 0.45;
uniform float cell_metres = 2.5;
uniform float feather_cells = 1.25;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.55;
uniform float shore_fade_metres = 4.0;

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
	vec2 raw_uv = (world_xz - world_min_xz) / max(world_size_xz, vec2(0.001));
	float inside = step(0.0, raw_uv.x) * step(raw_uv.x, 1.0) * step(0.0, raw_uv.y) * step(raw_uv.y, 1.0);
	vec2 world_uv = clamp(raw_uv, vec2(0.0), vec2(1.0));
	// Irregular 1–2 cell feather: jitter the sample in world metres, not a
	// wide island veil. Explored settlement stays at authored shroud.
	float n1 = value_noise(world_xz / max(cell_metres, 0.01) * 0.55);
	float n2 = value_noise(world_xz / max(cell_metres, 0.01) * 1.35 + vec2(17.0, 9.0));
	vec2 jitter = vec2(n1 - 0.5, n2 - 0.5) * 2.0 * noise_strength * feather_cells * cell_metres;
	vec2 jitter_uv = jitter / max(world_size_xz, vec2(0.001));
	float shroud = texture(visibility_texture, clamp(world_uv + jitter_uv, vec2(0.0), vec2(1.0))).r;
	ALBEDO = unknown_color;
	// Off-map stays fully unknown so zoom-out cannot read a diamond board.
	float offmap = 1.0 - inside;
	ALPHA = max(shroud * unknown_opacity * inside, offmap);
}
