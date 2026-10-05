shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled, blend_mix;

// Lit dirt lane: worn darker centre, dusty shoulders, irregular feathered edge.
// Responds to the sun so night roads keep a readable value lift.
uniform vec4 road_color : source_color = vec4(0.55, 0.40, 0.26, 1.0);
uniform vec3 light_tint : source_color = vec3(1.0);
uniform float value_lift = 0.06;
uniform float worn_darken = 0.22;
uniform float shoulder_lift = 0.16;
uniform float edge_noise = 0.55;

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
	float across = UV.x;
	float centre = 1.0 - smoothstep(0.16, 0.46, abs(across - 0.5) * 2.0);
	float shoulder = smoothstep(0.42, 0.78, abs(across - 0.5) * 2.0);
	float grain = mix(0.92, 1.08, noise2(world_pos.xz * 2.4));
	vec3 worn = road_color.rgb * (1.0 - worn_darken);
	vec3 dust = road_color.rgb * (1.0 + shoulder_lift);
	vec3 albedo = mix(road_color.rgb, worn, centre);
	albedo = mix(albedo, dust, shoulder * 0.85);
	albedo *= grain * light_tint * (1.0 + value_lift);
	float rim = min(across, 1.0 - across);
	float chew = noise2(world_pos.xz * 3.1 + vec2(17.0, 9.0));
	float alpha = road_color.a;
	if (rim < 0.14) {
		alpha *= mix(0.15, 1.0, smoothstep(0.02, 0.14, rim + (chew - 0.5) * edge_noise * 0.12));
		if (alpha < 0.12) {
			discard;
		}
	}
	ALBEDO = albedo;
	ROUGHNESS = mix(0.94, 0.80, shoulder);
	ALPHA = alpha;
	SPECULAR = 0.0;
}
