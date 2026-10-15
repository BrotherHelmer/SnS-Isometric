shader_type spatial;
render_mode unshaded, cull_disabled, skip_vertex_transform, depth_test_disabled, depth_draw_never, blend_mix, fog_disabled;

// The Director: GFX-K screen-composited shroud. Viewport overlay so
// off-map sky / water / AABB cuts cannot print a dark triangle.
// Texture stores shroud: 0 visible, ~0.45 explored, 1 unexplored.
// Colour #17272A. Visible 0 / explored 0.55 / unexplored+off-map 1.0.
// Feather 1.25 cells; noise displacement caps at 0.15 cells.
//
// Test #13: do not unproject NDC z=0. That is the far plane under
// reverse-Z, and walking 8000 m back to y=0.04 throws -Z halls off the
// 320 slab so every pixel becomes unknown teal. Rebuild XZ from the
// live ortho camera plus scene depth.

uniform sampler2D visibility_texture : filter_linear, repeat_disable;
uniform sampler2D scene_depth : hint_depth_texture, filter_nearest;
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
uniform vec3 camera_world_position = vec3(0.0, 32.0, 32.0);
uniform float camera_near = 0.2;
uniform float haze_light = 1.0;
// R32 candidate (gate flag --gate-r32-fog-lite): identical output, less work.
// Skips the cloud noise where it cannot affect the result and discards
// fully transparent (visible-area) pixels instead of blending alpha 0.
uniform float lite = 0.0;

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
	vec3 world_right = INV_VIEW_MATRIX[0].xyz;
	vec3 world_up = INV_VIEW_MATRIX[1].xyz;
	vec3 world_forward = -INV_VIEW_MATRIX[2].xyz;
	// Ortho half-extents from the projection. Independent of far-plane Z.
	float half_w = 1.0 / max(abs(PROJECTION_MATRIX[0][0]), 0.0001);
	float half_h = 1.0 / max(abs(PROJECTION_MATRIX[1][1]), 0.0001);
	vec3 world_near = camera_world_position
		+ world_right * (ndc.x * half_w)
		+ world_up * (ndc.y * half_h)
		+ world_forward * camera_near;
	float t = 0.0;
	if (abs(world_forward.y) > 0.0001) {
		t = (ground_height - world_near.y) / world_forward.y;
	}
	vec2 plane_xz = (world_near + world_forward * t).xz;

	float depth = texture(scene_depth, SCREEN_UV).x;
	// Reverse-Z: far / empty is ~0. A real surface sits clearly above that.
	float has_surface = step(0.0008, depth);
	vec4 view_d = INV_PROJECTION_MATRIX * vec4(ndc, depth, 1.0);
	view_d.xyz /= max(abs(view_d.w), 0.0001);
	vec3 world_depth = (INV_VIEW_MATRIX * vec4(view_d.xyz, 1.0)).xyz;
	vec2 world_xz = mix(plane_xz, world_depth.xz, has_surface);

	vec2 raw_uv = (world_xz - world_min_xz) / max(world_size_xz, vec2(0.001));
	float inside = step(0.0, raw_uv.x) * step(raw_uv.x, 1.0) * step(0.0, raw_uv.y) * step(raw_uv.y, 1.0);
	vec2 depth_uv = (world_depth.xz - world_min_xz) / max(world_size_xz, vec2(0.001));
	float depth_inside = step(0.0, depth_uv.x) * step(depth_uv.x, 1.0) * step(0.0, depth_uv.y) * step(depth_uv.y, 1.0);
	inside = max(inside, has_surface * depth_inside);
	raw_uv = mix(raw_uv, depth_uv, has_surface * depth_inside);
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
	if (lite > 0.5) {
		float ez = (1.0 - smoothstep(0.58, 0.92, shroud)) * inside;
		if (inside > 0.5 && unknown <= 0.0) {
			discard;
		}
		if (ez <= 0.0) {
			ALBEDO = unknown_color;
			ALPHA = max(unknown * inside, 1.0 - inside);
		} else {
			float cl = value_noise(world_xz * 0.045 + vec2(TIME * 0.012, TIME * 0.007)) * 0.65
				+ value_noise(world_xz * 0.11 - vec2(TIME * 0.01, 0.0)) * 0.35;
			vec3 hz = mix(unknown_color, vec3(0.34, 0.42, 0.44) * max(haze_light, 0.3), 0.30 + 0.35 * cl);
			float ezn = 1.0 - smoothstep(0.58, 0.92, shroud);
			ALBEDO = mix(unknown_color, hz, ezn * inside);
			ALPHA = max(unknown * inside * mix(1.0, 0.82 + 0.3 * cl, ezn), 1.0 - inside);
		}
	} else {
	// Beta: drifting cloud tone so the explored shroud reads as haze over the
	// land, not one flat dark-green mass with lobed edges.
	float cloud = value_noise(world_xz * 0.045 + vec2(TIME * 0.012, TIME * 0.007)) * 0.65
		+ value_noise(world_xz * 0.11 - vec2(TIME * 0.01, 0.0)) * 0.35;
	vec3 haze = mix(unknown_color, vec3(0.34, 0.42, 0.44) * max(haze_light, 0.3), 0.30 + 0.35 * cloud);
	float explored_zone = 1.0 - smoothstep(0.58, 0.92, shroud);
	ALBEDO = mix(unknown_color, haze, explored_zone * inside);
	// Off-map is fully unknown so a zoomed viewport never shows a
	// triangular sky / water / AABB cut.
	ALPHA = max(unknown * inside * mix(1.0, 0.82 + 0.3 * cloud, explored_zone), 1.0 - inside);
	}
}
