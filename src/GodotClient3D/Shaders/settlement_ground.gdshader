shader_type spatial;
render_mode diffuse_burley, specular_disabled;

// The Director: GFX-03 two-scale terrain. Macro 8–20 m moisture/dirt
// (±5–8% colour) plus a 0.8–2 m albedo/normal breakup. Dirt/grass blend
// is world-space, not a board of flat green. Period tint still drives dusk
// gold patches. Triplanar stays off on the playable flats.
uniform vec3 light_tint : source_color = vec3(1.0);
uniform float tint_floor = 0.0;
uniform float tint_wash_lo = 0.70;
uniform float tint_wash_hi = 0.94;
uniform vec3 grass_sunlit : source_color = vec3(0.471, 0.506, 0.353); // #78815A
uniform vec3 grass_moss : source_color = vec3(0.345, 0.404, 0.275); // #586746
uniform vec3 dirt_color : source_color = vec3(0.502, 0.388, 0.278); // #806347
uniform float macro_metres = 14.0;
uniform float detail_metres = 1.2;
uniform float macro_amount = 0.078;
uniform float detail_amount = 0.048;
uniform float dirt_amount = 0.36;
// 1 at night / distant LOD: one-octave noise, no 4-tap detail normals.
uniform float lod_cheap = 0.0;

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

float fbm(vec2 p) {
	return noise2(p) * 0.62 + noise2(p * 2.07 + vec2(19.1, 7.3)) * 0.38;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 macro_uv = world_pos.xz / max(macro_metres, 1.0);
	vec2 detail_uv = world_pos.xz / max(detail_metres, 0.4) + vec2(8.2, 3.7);
	float macro = lod_cheap > 0.5 ? noise2(macro_uv) : fbm(macro_uv);
	// Night LOD: skip the 0.8–2 m octave. Strategy cam barely reads it
	// and the extra noise2 is the last lavapipe millisecond we can spare.
	float detail = lod_cheap > 0.5 ? 0.5 : fbm(detail_uv);
	float dirt_noise = lod_cheap > 0.5 ? macro : fbm(world_pos.xz / (macro_metres * 1.35) + vec2(4.8, 21.0));
	float dirt_mask = smoothstep(0.52, 0.84, dirt_noise);
	vec3 grass = mix(grass_moss, grass_sunlit, clamp(macro * 0.7 + detail * 0.3, 0.0, 1.0));
	// Vertex colour used to dominate (0.38), so the two-scale layer read as a
	// flat board from the strategy camera. Prefer authored grass; keep dirt
	// scarce so dusk gold cannot push warm-share over 0.50.
	vec3 ground = mix(COLOR.rgb, grass, 0.48);
	ground = mix(ground, dirt_color, dirt_mask * dirt_amount);
	float macro_var = mix(1.0 - macro_amount, 1.0 + macro_amount, macro);
	float detail_var = mix(1.0 - detail_amount, 1.0 + detail_amount, detail);
	float wash = smoothstep(tint_wash_lo, max(tint_wash_lo + 0.02, tint_wash_hi), macro);
	vec3 albedo = ground * mix(vec3(1.0), light_tint, mix(tint_floor, 1.0, wash)) * macro_var * detail_var;
	ALBEDO = albedo;
	// Flat world-up normals. The 4-tap bump plus half-res SSAO painted
	// diagonal stripes that crawled when the camera panned. Colour breakup
	// above still reads from the strategy camera.
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	ROUGHNESS = mix(0.96, 0.88, dirt_mask);
}
