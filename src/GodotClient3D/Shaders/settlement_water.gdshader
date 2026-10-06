shader_type spatial;
render_mode unshaded, specular_disabled, cull_disabled, fog_disabled;

// The Director: G1 cheap island water. Unshaded + fog_disabled so
// dusk sun-scatter cannot paint cream streaks across the sea.
// A noisy inset carves coves so the slab is not a ruler-cut plate.
// Colour fades into the sky-ground; the plane outruns max zoom.
uniform vec2 world_min_xz;
uniform vec2 world_size_xz;
uniform vec3 deep_color : source_color = vec3(0.16, 0.26, 0.28);
uniform vec3 shallow_color : source_color = vec3(0.22, 0.34, 0.33);
uniform vec3 foam_color : source_color = vec3(0.40, 0.38, 0.32);
uniform vec3 horizon_color : source_color = vec3(0.145, 0.240, 0.255);
uniform float wave = 0.04;
uniform float foam_metres = 4.8;
uniform float beach_margin_metres = 5.0;
uniform float coast_jut_metres = 12.0;
uniform float fade_start = 70.0;
uniform float fade_end = 380.0;
uniform float lod_cheap = 0.0;
uniform float atmosphere = 1.0;

varying vec3 world_pos;

float coast_noise(vec2 p) {
	return sin(p.x * 0.048 + p.y * 0.037 + 0.41) * 0.42
		+ sin(p.x * 0.11 + p.y * 0.07 + 1.27) * 0.32
		+ sin(p.x * 0.031 - p.y * 0.045 + 2.19) * 0.18
		+ sin((p.x + p.y) * 0.019) * 0.08;
}

// Signed land: positive inland. Playable AABB + 2-tile beach is always
// land. Corners are quarter-circles of beach_margin so the waterline is
// a rounded rectangle, not a saw of 2.5 m tiles. Noise only juts seaward.
float island_land(vec2 world_xz) {
	vec2 center = world_min_xz + 0.5 * world_size_xz;
	vec2 half = 0.5 * world_size_xz;
	vec2 q = abs(world_xz - center) - half;
	float sd = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - beach_margin_metres;
	float jut = max(coast_noise(world_xz), 0.0) * coast_jut_metres;
	return -sd + jut;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	if (lod_cheap < 0.5) {
		float gust = sin(TIME * 0.52 + world_pos.x * 0.19 + world_pos.z * 0.15);
		float swell = sin(TIME * 0.23 + world_pos.x * 0.07 - world_pos.z * 0.09);
		VERTEX.y += (gust * 0.72 + swell * 0.28) * wave;
		world_pos.y = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
	}
}

void fragment() {
	float land = island_land(world_pos.xz);
	if (land > 0.0) {
		discard;
	}
	vec2 outside = max(world_min_xz - world_pos.xz, world_pos.xz - (world_min_xz + world_size_xz));
	float dist_out = max(max(outside.x, outside.y), 0.0);
	float from_shore = max(-land, 0.0);
	float foam = 1.0 - smoothstep(0.35, foam_metres, from_shore);
	float ripple = lod_cheap > 0.5 ? 0.5 : (sin(world_pos.x * 1.35 + world_pos.z * 1.05 + TIME * 0.28) * 0.5 + 0.5);
	vec3 water = mix(deep_color, shallow_color, clamp(foam * 0.34 + ripple * 0.06, 0.0, 1.0));
	water = mix(water, foam_color, foam * 0.28);
	float fade = smoothstep(fade_start, fade_end, dist_out);
	ALBEDO = mix(water, horizon_color, fade) * mix(0.50, 0.82, atmosphere);
}
