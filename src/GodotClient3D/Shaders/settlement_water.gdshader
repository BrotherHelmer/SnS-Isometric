shader_type spatial;
render_mode unshaded, specular_disabled, cull_disabled;

// The Director: G1 cheap island water. Unshaded so a flat sea cannot
// throw a sun-glint streak at far zoom. Foam stays a short, muted
// shore band. Colour fades into the sky-ground so the disk has no rim.
uniform vec2 world_min_xz;
uniform vec2 world_size_xz;
uniform vec3 deep_color : source_color = vec3(0.20, 0.32, 0.33);
uniform vec3 shallow_color : source_color = vec3(0.30, 0.42, 0.40);
uniform vec3 foam_color : source_color = vec3(0.62, 0.58, 0.50);
uniform vec3 horizon_color : source_color = vec3(0.165, 0.275, 0.290);
uniform float wave = 0.04;
uniform float foam_metres = 6.0;
uniform float fade_start = 70.0;
uniform float fade_end = 320.0;
uniform float lod_cheap = 0.0;
uniform float atmosphere = 1.0;

varying vec3 world_pos;

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
	vec2 raw = (world_pos.xz - world_min_xz) / max(world_size_xz, vec2(0.001));
	vec2 inset = vec2(1.1) / max(world_size_xz, vec2(1.0));
	if (raw.x > inset.x && raw.y > inset.y && raw.x < 1.0 - inset.x && raw.y < 1.0 - inset.y) {
		discard;
	}
	vec2 outside = max(world_min_xz - world_pos.xz, world_pos.xz - (world_min_xz + world_size_xz));
	float dist_out = max(max(outside.x, outside.y), 0.0);
	float foam = 1.0 - smoothstep(0.45, foam_metres, dist_out);
	float ripple = lod_cheap > 0.5 ? 0.5 : (sin(world_pos.x * 1.35 + world_pos.z * 1.05 + TIME * 0.28) * 0.5 + 0.5);
	vec3 water = mix(deep_color, shallow_color, clamp(foam * 0.45 + ripple * 0.08, 0.0, 1.0));
	water = mix(water, foam_color, foam * 0.22);
	float fade = smoothstep(fade_start, fade_end, dist_out);
	ALBEDO = mix(water, horizon_color, fade) * mix(0.55, 0.92, atmosphere);
}
