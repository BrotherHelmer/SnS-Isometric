shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_disabled;

// The Director: G1 cheap island water. Subtle vertex waves by day,
// foam only in a short shore band. Flat world-up normals so panning
// cannot stripe the flats the way the old ground bump did.
uniform vec2 world_min_xz;
uniform vec2 world_size_xz;
uniform vec3 deep_color : source_color = vec3(0.22, 0.36, 0.37); // #385C5E
	uniform vec3 shallow_color : source_color = vec3(0.42, 0.56, 0.50); // #6B8F80
	uniform vec3 foam_color : source_color = vec3(0.88, 0.84, 0.74); // #E0D6BD
uniform float wave = 0.04;
uniform float foam_metres = 5.0;
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
	// Keep a thin overlap under the rim so the slab does not flash a gap.
	vec2 inset = vec2(1.1) / max(world_size_xz, vec2(1.0));
	if (raw.x > inset.x && raw.y > inset.y && raw.x < 1.0 - inset.x && raw.y < 1.0 - inset.y) {
		discard;
	}
	vec2 outside = max(world_min_xz - world_pos.xz, world_pos.xz - (world_min_xz + world_size_xz));
	float dist_out = max(max(outside.x, outside.y), 0.0);
	float foam = 1.0 - smoothstep(0.35, foam_metres, dist_out);
	float ripple = lod_cheap > 0.5 ? 0.5 : (sin(world_pos.x * 1.55 + world_pos.z * 1.15 + TIME * 0.35) * 0.5 + 0.5);
	vec3 water = mix(deep_color, shallow_color, clamp(foam * 0.70 + ripple * 0.10, 0.0, 1.0));
	ALBEDO = mix(water, foam_color, foam * 0.70) * mix(0.72, 1.0, atmosphere);
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	ROUGHNESS = mix(0.20, 0.58, foam);
	METALLIC = 0.06;
	SPECULAR = 0.48;
}
