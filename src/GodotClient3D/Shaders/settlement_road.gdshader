shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled, blend_mix;

// The Director: GFX-06 roads as terrain. Compacted clay centre, darker dirt
// edges, noisy smoothstep into the grass. No uniform bright shoulder.
uniform vec4 road_color : source_color = vec4(0.639, 0.525, 0.373, 1.0); // #A3865F
uniform vec3 clay_color : source_color = vec3(0.639, 0.525, 0.373); // #A3865F
uniform vec3 dirt_edge : source_color = vec3(0.522, 0.416, 0.298); // #856A4C
uniform vec3 light_tint : source_color = vec3(1.0);
uniform float value_lift = 0.06;
uniform float worn_darken = 0.10;
uniform float shoulder_lift = 0.0;
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
	float across = abs(UV.x - 0.5) * 2.0;
	float chew = noise2(world_pos.xz * 2.1 + vec2(9.0, 4.0));
	float edge = smoothstep(0.26 + chew * 0.22, 0.90 + chew * 0.14, across);
	vec3 clay = mix(road_color.rgb, clay_color, 0.62) * (1.0 - worn_darken * (1.0 - edge));
	vec3 dirt = mix(road_color.rgb, dirt_edge, 0.78);
	// shoulder_lift stays 0 — pale graphic borders were the board-game read.
	vec3 albedo = mix(clay, dirt * (1.0 + shoulder_lift), edge);
	albedo *= mix(0.94, 1.05, noise2(world_pos.xz * 3.2)) * light_tint * (1.0 + value_lift);
	float rim = min(UV.x, 1.0 - UV.x);
	float alpha = road_color.a;
	if (rim < 0.16) {
		alpha *= mix(0.12, 1.0, smoothstep(0.02, 0.16, rim + (chew - 0.5) * edge_noise * 0.14));
		if (alpha < 0.10) {
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
