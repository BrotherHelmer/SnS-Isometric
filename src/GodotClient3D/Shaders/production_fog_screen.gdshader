shader_type spatial;
render_mode unshaded, cull_disabled, skip_vertex_transform, depth_test_disabled, depth_draw_never, blend_mix, fog_disabled;

// The Director: GFX-K screen-composited shroud. Viewport overlay so
// off-map sky / water / AABB cuts cannot print a dark triangle.
// Texture stores shroud: 0 visible, ~0.45 explored, 1 unexplored.
// Colour #17272A. Visible 0 / explored 0.55 / unexplored+off-map 1.0.
// Feather 1.25 cells; noise displacement caps at 0.15 cells.

uniform sampler2D visibility_texture : filter_linear, repeat_disable;
uniform vec3 unknown_color = vec3(0.090, 0.153, 0.165); // #17272A
uniform vec3 mist_color = vec3(0.090, 0.153, 0.165);
uniform vec2 world_min_xz = vec2(-87.5, -87.5);
uniform vec2 world_size_xz = vec2(175.0, 175.0);
uniform float unknown_opacity : hint_range(0.0, 1.0) = 1.0;
uniform float explored_opacity : hint_range(0.0, 1.0) = 0.55;
uniform float cell_metres = 2.5;
uniform float feather_cells = 1.25;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.12;
uniform float ground_height = 0.04;

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

void vertex() {
	// Fullscreen triangle in clip space. Always covers the viewport.
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec2 ndc = SCREEN_UV * 2.0 - 1.0;
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 0.0, 1.0);
	view.xyz /= max(abs(view.w), 0.0001);
	vec3 world_origin = (INV_VIEW_MATRIX * vec4(view.xyz, 1.0)).xyz;
	vec3 world_forward = -INV_VIEW_MATRIX[2].xyz;
	float t = 0.0;
	if (abs(world_forward.y) > 0.0001) {
		t = (ground_height - world_origin.y) / world_forward.y;
	}
	vec2 world_xz = (world_origin + world_forward * t).xz;
	vec2 raw_uv = (world_xz - world_min_xz) / max(world_size_xz, vec2(0.001));
	float inside = step(0.0, raw_uv.x) * step(raw_uv.x, 1.0) * step(0.0, raw_uv.y) * step(raw_uv.y, 1.0);
	vec2 world_uv = clamp(raw_uv, vec2(0.0), vec2(1.0));
	float n1 = value_noise(world_xz / max(cell_metres, 0.01) * 0.55);
	float n2 = value_noise(world_xz / max(cell_metres, 0.01) * 1.35 + vec2(17.0, 9.0));
	// noise_strength * feather_cells <= 0.15 cells of displacement.
	vec2 jitter = vec2(n1 - 0.5, n2 - 0.5) * 2.0 * noise_strength * feather_cells * cell_metres;
	vec2 jitter_uv = jitter / max(world_size_xz, vec2(0.001));
	vec2 sample_uv = clamp(world_uv + jitter_uv, vec2(0.0), vec2(1.0));
	ivec2 tex_size = textureSize(visibility_texture, 0);
	float has_mask = step(1.0, float(tex_size.x * tex_size.y));
	// Missing / invalid mask is unexplored, never visible.
	float shroud = mix(1.0, texture(visibility_texture, sample_uv).r, has_mask);
	float explored = mix(0.0, explored_opacity, smoothstep(0.04, 0.42, shroud));
	float unknown = mix(explored, unknown_opacity, smoothstep(0.58, 0.92, shroud));
	ALBEDO = unknown_color;
	// Off-map is fully unknown so a zoomed viewport never shows a
	// triangular sky / water / AABB cut.
	ALPHA = max(unknown * inside, 1.0 - inside);
}
