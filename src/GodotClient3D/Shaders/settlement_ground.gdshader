shader_type spatial;
render_mode diffuse_burley, specular_disabled;

// The Director: soft grain only. The old 0.83–1.12 swing read as a
// checkerboard around buildings. light_tint is the period grade so dusk
// grass goes gold instead of staying a dark green that never hits warm-share.
uniform vec3 light_tint : source_color = vec3(1.0);
varying vec3 world_pos;

float hash21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise2(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1,0)), f.x), mix(hash21(i + vec2(0,1)), hash21(i + vec2(1,1)), f.x), f.y);
}
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float broad = noise2(world_pos.xz * 0.11);
	float fine = noise2(world_pos.xz * 1.8);
	// Period tint is patched, not a flat wash: dusk gold hits the brighter
	// noise patches (warm-share) and leaves the rest green.
	float wash = smoothstep(0.70, 0.94, broad);
	ALBEDO = COLOR.rgb * mix(vec3(1.0), light_tint, wash) * mix(0.94, 1.05, broad) * mix(0.98, 1.02, fine);
	// World up in view space, same contract as the road lanes.
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	ROUGHNESS = 0.97;
}
