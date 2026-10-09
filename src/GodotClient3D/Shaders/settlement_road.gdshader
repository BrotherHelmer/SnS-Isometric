shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled, blend_mix;

// The Director: GFX-K worn medieval paths. Compacted earth centre,
// grass-blended shoulders, dark ruts and sparse gravel. Not a brown ribbon.
uniform vec4 road_color : source_color = vec4(0.690, 0.573, 0.424, 1.0); // #B0926C
uniform vec3 clay_color : source_color = vec3(0.690, 0.573, 0.424); // #B0926C
uniform vec3 dirt_edge : source_color = vec3(0.533, 0.424, 0.286); // #886C49
uniform vec3 gravel_color : source_color = vec3(0.573, 0.565, 0.502); // #929080
uniform vec3 light_tint : source_color = vec3(1.0);
uniform float value_lift = 0.06;
uniform float worn_darken = 0.16;
uniform float shoulder_lift = 0.0;
uniform float edge_noise = 0.42;
uniform float road_width_metres = 1.47;

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
	float across = abs(UV.x - 0.5) * 2.0;
	float chew = noise2(world_pos.xz * 0.18 + vec2(9.0, 4.0));
	float irregular = across + (chew - 0.5) * 0.20;
	// Centre 70% packed earth, 15% shoulder each side.
	float edge = smoothstep(0.35, 0.70, irregular);
	vec3 clay = mix(road_color.rgb, clay_color, 0.70);
	vec3 dirt = mix(road_color.rgb, dirt_edge, 0.86);
	vec3 albedo = mix(clay, dirt * (1.0 + shoulder_lift), edge);
	float worn = smoothstep(0.72, 0.94, noise2(world_pos.xz * 1.15 + vec2(4.0, 11.0)));
	albedo = mix(albedo, dirt_edge, worn * 0.10);
	float gravel = smoothstep(0.82, 0.96, noise2(world_pos.xz * 3.4 + vec2(2.2, 7.0)));
	albedo = mix(albedo, gravel_color, gravel * 0.18 * (1.0 - edge));
	// Two cart ruts at ±0.22R, each ~0.035R.
	float rut_l = abs(UV.x - (0.5 - 0.22));
	float rut_r = abs(UV.x - (0.5 + 0.22));
	float ruts = (1.0 - smoothstep(0.0, 0.035, min(rut_l, rut_r))) * (1.0 - edge);
	albedo = mix(albedo, dirt_edge, ruts * 0.55);
	albedo *= mix(0.90, 1.08, noise2(world_pos.xz * 3.2)) * light_tint * (1.0 + value_lift);
	float rim = min(UV.x, 1.0 - UV.x);
	float alpha = max(road_color.a, 0.92);
	if (rim < 0.10) {
		alpha *= mix(0.35, 1.0, smoothstep(0.02, 0.10, rim + (chew - 0.5) * edge_noise * 0.10));
		if (alpha < 0.18) {
			discard;
		}
	}
	ALBEDO = albedo;
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	ROUGHNESS = mix(0.90, 0.96, edge);
	ALPHA = alpha;
	SPECULAR = 0.0;
	vec3 moonlit = mix(albedo, vec3(0.62, 0.68, 0.78), 0.28);
	EMISSION = moonlit * value_lift * 0.16;
}
