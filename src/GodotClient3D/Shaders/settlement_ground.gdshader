shader_type spatial;
render_mode diffuse_burley, specular_disabled;

// The Director: GFX-D designed ground. Vertex colour carries occupation
// (roads / aprons / forest floor). Shader adds meadow, flower tint and
// gravel without the black speckle that made GFX-C look like a prototype.
uniform vec3 light_tint : source_color = vec3(1.0);
uniform float tint_floor = 0.0;
uniform float tint_wash_lo = 0.70;
uniform float tint_wash_hi = 0.94;
uniform vec3 grass_sunlit : source_color = vec3(0.353, 0.545, 0.267); // #5A8B44
uniform vec3 grass_moss : source_color = vec3(0.227, 0.408, 0.251); // #3A6840
uniform vec3 dirt_color : source_color = vec3(0.502, 0.388, 0.278); // #806347
uniform vec3 meadow_lush : source_color = vec3(0.420, 0.600, 0.280);
uniform vec3 meadow_warm : source_color = vec3(0.520, 0.580, 0.250);
uniform vec3 flower_warm : source_color = vec3(0.780, 0.420, 0.280);
uniform vec3 flower_cool : source_color = vec3(0.620, 0.380, 0.560);
uniform vec3 gravel_color : source_color = vec3(0.420, 0.400, 0.360);
uniform float macro_metres = 14.0;
uniform float detail_metres = 1.2;
uniform float macro_amount = 0.28;
uniform float detail_amount = 0.062;
uniform float dirt_amount = 0.42;
uniform float flower_amount = 0.38;
// 1 at night / distant LOD: one-octave noise, no 4-tap detail normals.
uniform float lod_cheap = 0.0;
// G1: same noisy waterline as settlement_water.gdshader.
uniform vec2 world_min_xz = vec2(-87.5, -87.5);
uniform vec2 world_size_xz = vec2(175.0, 175.0);
uniform vec3 beach_color : source_color = vec3(0.62, 0.52, 0.38);
uniform vec3 rock_shore : source_color = vec3(0.36, 0.34, 0.30);
uniform vec3 wet_sand : source_color = vec3(0.42, 0.36, 0.28);
uniform float beach_margin_metres = 5.0;
uniform float coast_jut_metres = 12.0;
uniform float apron_mode = 0.0;

varying vec3 world_pos;

float coast_noise(vec2 p) {
	return sin(p.x * 0.048 + p.y * 0.037 + 0.41) * 0.42
		+ sin(p.x * 0.11 + p.y * 0.07 + 1.27) * 0.32
		+ sin(p.x * 0.031 - p.y * 0.045 + 2.19) * 0.18
		+ sin((p.x + p.y) * 0.019) * 0.08;
}

float inward_metres(vec2 world_xz) {
	vec2 raw = (world_xz - world_min_xz) / max(world_size_xz, vec2(0.001));
	return min(min(raw.x, 1.0 - raw.x), min(raw.y, 1.0 - raw.y)) * min(world_size_xz.x, world_size_xz.y);
}

// Same rounded-rect + seaward jut as settlement_water.gdshader.
float island_land(vec2 world_xz) {
	vec2 center = world_min_xz + 0.5 * world_size_xz;
	vec2 half = 0.5 * world_size_xz;
	vec2 q = abs(world_xz - center) - half;
	float sd = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - beach_margin_metres;
	float jut = max(coast_noise(world_xz), 0.0) * coast_jut_metres;
	return -sd + jut;
}

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
	float land = island_land(world_pos.xz);
	float inward = inward_metres(world_pos.xz);
	if (apron_mode > 0.5) {
		if (inward > 0.25) {
			discard;
		}
		if (land <= 0.0) {
			discard;
		}
	}
	float beach = 1.0 - smoothstep(0.0, beach_margin_metres + 1.8, max(land, 0.0));
	vec2 macro_uv = world_pos.xz / max(macro_metres, 1.0);
	vec2 detail_uv = world_pos.xz / max(detail_metres, 0.4) + vec2(8.2, 3.7);
	float macro = lod_cheap > 0.5 ? noise2(macro_uv) : fbm(macro_uv);
	// Night LOD: skip the 0.8–2 m octave. Strategy cam barely reads it
	// and the extra noise2 is the last lavapipe millisecond we can spare.
	float detail = lod_cheap > 0.5 ? 0.5 : fbm(detail_uv);
	float dirt_noise = lod_cheap > 0.5 ? macro : fbm(world_pos.xz / (macro_metres * 1.35) + vec2(4.8, 21.0));
	float dirt_mask = smoothstep(0.46, 0.82, dirt_noise);
	vec3 grass = mix(grass_moss, grass_sunlit, clamp(macro * 0.62 + detail * 0.38, 0.0, 1.0));
	float meadow = lod_cheap > 0.5 ? macro : noise2(world_pos.xz / 14.0 + vec2(3.1, 9.7));
	float meadow_b = lod_cheap > 0.5 ? macro : noise2(world_pos.xz / 22.0 + vec2(11.4, 2.2));
	grass = mix(grass, meadow_lush, smoothstep(0.38, 0.78, meadow) * 0.72);
	grass = mix(grass, meadow_warm, smoothstep(0.50, 0.88, meadow_b) * 0.42);
	// Flower tint is a hue lift, never a dark speck.
	if (lod_cheap < 0.5) {
		float bloom = noise2(world_pos.xz / 3.4 + vec2(17.0, 5.0));
		float patch = smoothstep(0.68, 0.90, meadow) * smoothstep(0.62, 0.88, bloom);
		vec3 blossom = mix(flower_warm, flower_cool, step(0.5, noise2(world_pos.xz * 0.37)));
		grass = mix(grass, mix(grass, blossom, 0.70), patch * flower_amount);
	}
	// COLOR.a is the occupation splat. Some backends drop vertex alpha
	// to 1; then brown RGB (r > g) still marks roads / aprons.
	float occupy = clamp(COLOR.a, 0.0, 1.0);
	if (occupy > 0.98) {
		occupy = max(
			smoothstep(0.05, 0.18, length(COLOR.rgb - grass)),
			smoothstep(0.0, 0.10, COLOR.r - COLOR.g)
		);
	}
	vec3 occupy_albedo = COLOR.rgb;
	vec3 ground = mix(grass, occupy_albedo, occupy);
	ground = mix(ground, dirt_color, dirt_mask * dirt_amount * (1.0 - occupy * 0.70));
	float gravel_n = lod_cheap > 0.5 ? 0.0 : smoothstep(0.70, 0.92, noise2(world_pos.xz / 8.0 + vec2(2.2, 14.0)));
	ground = mix(ground, gravel_color, gravel_n * 0.28 * (0.20 + occupy));
	float macro_var = mix(1.0 - macro_amount, 1.0 + macro_amount, macro);
	float detail_var = mix(1.0 - detail_amount * 0.55, 1.0 + detail_amount, detail);
	float wash = smoothstep(tint_wash_lo, max(tint_wash_lo + 0.02, tint_wash_hi), macro);
	vec3 albedo = ground * mix(vec3(1.0), light_tint, mix(tint_floor, 1.0, wash)) * macro_var * detail_var;
	vec3 shore = mix(beach_color, rock_shore, clamp(dirt_mask * 0.65 + macro * 0.35, 0.0, 1.0));
	albedo = mix(albedo, shore, beach * (apron_mode > 0.5 ? 0.92 : 0.22));
	if (apron_mode > 0.5) {
		float wet = 1.0 - smoothstep(0.0, 3.2, max(land, 0.0));
		albedo = mix(albedo, wet_sand, wet * 0.55);
	}
	ALBEDO = albedo;
	// Flat world-up normals. The 4-tap bump plus half-res SSAO painted
	// diagonal stripes that crawled when the camera panned. Colour breakup
	// above still reads from the strategy camera.
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	ROUGHNESS = mix(0.96, 0.88, dirt_mask);
}
