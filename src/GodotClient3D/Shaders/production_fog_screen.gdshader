shader_type spatial;
render_mode unshaded, cull_disabled, skip_vertex_transform, depth_test_disabled, depth_draw_never, blend_mix, fog_disabled;

// Screen overlay that samples FOW at the ground (y = 0) under each pixel.
// A world-space sheet cannot do this: at a map corner the camera looks through
// unknown tiles in front of the settlement, and the sheet fogs those pixels even
// when the land behind them is already revealed.

uniform sampler2D visibility_texture : filter_linear, repeat_disable;
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;
uniform vec3 unknown_color = vec3(0.012, 0.025, 0.029);
uniform vec3 mist_color = vec3(0.021, 0.038, 0.043);
uniform vec2 world_min_xz = vec2(-87.5, -87.5);
uniform vec2 world_size_xz = vec2(175.0, 175.0);
uniform float unknown_opacity : hint_range(0.0, 1.0) = 1.0;
uniform float edge_softness : hint_range(0.01, 0.5) = 0.28;
uniform float noise_strength : hint_range(0.0, 0.3) = 0.12;
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
	float c = hash21(cell + vec2(1.0, 1.0));
	float d = hash21(cell + vec2(0.0, 1.0));
	return mix(mix(a, b, local.x), mix(c, d, local.x), local.y);
}

void vertex() {
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
	float visibility = texture(visibility_texture, world_uv).r;
	float broad_noise = value_noise(world_uv * 17.0 + vec2(TIME * 0.008, -TIME * 0.006));
	float edge_noise = (broad_noise - 0.5) * noise_strength;
	float revealed = smoothstep(0.5 - edge_softness, 0.5 + edge_softness, visibility + edge_noise) * inside;
	float unknown = 1.0 - revealed;
	float mist = value_noise(world_uv * 8.0 + vec2(-TIME * 0.004, TIME * 0.005));
	ALBEDO = mix(unknown_color, mist_color, mist * 0.34);
	ALPHA = mix(
		unknown * clamp(unknown_opacity + (mist - 0.5) * 0.003, 0.0, 1.0),
		1.0,
		1.0 - inside
	);
}
