shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_opaque, shadows_disabled;

// The Director: GFX-06 batched road stamps — tracks, mud, broken edges.
// Three MultiMeshes for the whole map, never one Decal per tile.
uniform vec4 stamp_color : source_color = vec4(0.43, 0.33, 0.25, 0.55);
uniform float edge_noise = 0.45;

varying vec3 world_pos;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1, 0)), f.x), mix(hash21(i + vec2(0, 1)), hash21(i + vec2(1, 1)), f.x), f.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float r = length(uv);
	float chew = (noise2(world_pos.xz * 3.4) - 0.5) * edge_noise;
	float mask = 1.0 - smoothstep(0.72 + chew, 1.05, r);
	if (mask < 0.04) {
		discard;
	}
	ALBEDO = stamp_color.rgb * mix(0.88, 1.06, noise2(world_pos.xz * 5.1));
	ALPHA = stamp_color.a * mask;
}
