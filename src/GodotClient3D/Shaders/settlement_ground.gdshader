shader_type spatial;
render_mode diffuse_burley, specular_disabled;
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
	ALBEDO = COLOR.rgb * mix(0.83, 1.12, broad) * mix(0.96, 1.04, fine);
	ROUGHNESS = 0.97;
}
