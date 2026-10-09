shader_type spatial;
render_mode diffuse_burley, specular_disabled;

// The Director: GFX-H ground. Vertex colour carries occupation
// (roads / aprons / crop fields). Meadow is world-space multi-scale
// noise plus dirt, tufts, flowers and pebbles so 2.5 m tiles cannot
// print an olive sheet. Palette stays GFX-G yellow-olive so the
// opening grade (hue ~71°) does not drift.
uniform vec3 light_tint : source_color = vec3(1.0);
uniform float tint_floor = 0.0;
uniform float tint_wash_lo = 0.70;
uniform float tint_wash_hi = 0.94;
uniform vec3 grass_sunlit : source_color = vec3(0.459, 0.533, 0.318); // #758851
uniform vec3 grass_moss : source_color = vec3(0.224, 0.310, 0.200); // #394F33
uniform vec3 dirt_color : source_color = vec3(0.537, 0.424, 0.298); // #896C4C
uniform vec3 meadow_lush : source_color = vec3(0.333, 0.427, 0.247); // #556D3F
uniform vec3 meadow_warm : source_color = vec3(0.459, 0.533, 0.318); // #758851
uniform vec3 flower_warm : source_color = vec3(0.820, 0.678, 0.302); // #D1AD4D
uniform vec3 flower_cool : source_color = vec3(0.878, 0.831, 0.682); // #E0D4AE
uniform vec3 gravel_color : source_color = vec3(0.573, 0.565, 0.502); // #929080
uniform vec3 forest_floor : source_color = vec3(0.208, 0.282, 0.204); // #354834
uniform vec3 road_earth : source_color = vec3(0.682, 0.565, 0.427); // #AE906D
uniform vec3 wheat_gold : source_color = vec3(0.788, 0.635, 0.290); // #C9A24A
uniform vec3 wheat_furrow : source_color = vec3(0.420, 0.310, 0.165);
uniform float macro_metres = 8.0;
uniform float patch_metres = 1.94;
uniform float detail_metres = 1.10;
uniform float macro_amount = 0.22;
uniform float detail_amount = 0.12;
uniform float dirt_amount = 0.56;
uniform float flower_amount = 0.40;
uniform float stone_amount = 0.34;
uniform float crop_amount = 1.0;
// 1 at night / distant LOD: one-octave noise, no 4-tap detail normals.
uniform float lod_cheap = 0.0;
// G1: same noisy waterline as settlement_water.gdshader.
uniform vec2 world_min_xz = vec2(-87.5, -87.5);
uniform vec2 world_size_xz = vec2(175.0, 175.0);
// GFX-G/H: shore dissolves into the wilderness shroud so zoom 42/68
// cannot print a diamond island or a dark beach rim.
uniform vec3 beach_color : source_color = vec3(0.090, 0.153, 0.165); // #17272A
uniform vec3 rock_shore : source_color = vec3(0.078, 0.125, 0.141); // #142024
uniform vec3 wet_sand : source_color = vec3(0.070, 0.110, 0.125); // #121C20
uniform sampler2D meadow_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D forest_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D dirt_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float tex_mix = 0.20;
uniform float tex_repeat_meadow = 3.64;
uniform float tex_repeat_forest = 2.91;
uniform sampler2D road_control_tex : hint_default_black, filter_linear, repeat_disable;
uniform float road_control_amount = 1.0;
uniform float road_debug = 0.0;
uniform float beach_margin_metres = 5.0;
uniform float coast_jut_metres = 14.0;
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
	// Broad 20–40 m, medium 5–12 m, fine < 1 m. World-space so tile
	// vertices cannot reprint a diagonal checkerboard.
	vec2 broad_uv = world_pos.xz / max(macro_metres, 16.0);
	vec2 patch_uv = world_pos.xz / max(patch_metres, 5.0) + vec2(3.7, 11.2);
	vec2 detail_uv = world_pos.xz / max(detail_metres, 0.4) + vec2(8.2, 3.7);
	float broad = lod_cheap > 0.5 ? noise2(broad_uv) : fbm(broad_uv);
	float patch = lod_cheap > 0.5 ? noise2(patch_uv) : fbm(patch_uv);
	float detail = lod_cheap > 0.5 ? 0.5 : fbm(detail_uv);
	float dirt_noise = lod_cheap > 0.5 ? broad : fbm(world_pos.xz / (macro_metres * 1.15) + vec2(4.8, 21.0));
	float dirt_mask = smoothstep(0.48, 0.82, dirt_noise);
	vec3 grass = mix(grass_moss, meadow_lush, clamp(broad * 0.55 + patch * 0.45, 0.0, 1.0));
	// GFX-N: palette owns the meadow. Poly Haven maps are luminance
	// detail only — they must not paint a sandy khaki wash.
	float dark_grass = smoothstep(0.08, 0.46, 1.0 - patch) * (0.55 + 0.45 * (1.0 - broad));
	grass = mix(grass, grass_sunlit, smoothstep(0.62, 0.94, patch) * 0.08);
	grass = mix(grass, meadow_warm, smoothstep(0.74, 0.98, broad) * 0.04);
	grass = mix(grass, forest_floor, clamp(dark_grass * 0.82, 0.0, 0.34));
	if (tex_mix > 0.01) {
		vec2 muv = world_pos.xz / max(tex_repeat_meadow, 1.5);
		vec2 fuv = world_pos.xz / max(tex_repeat_forest, 1.2);
		float meadow_luma = dot(texture(meadow_tex, muv).rgb, vec3(0.2126, 0.7152, 0.0722));
		float forest_luma = dot(texture(forest_tex, fuv).rgb, vec3(0.2126, 0.7152, 0.0722));
		float dirt_luma = dot(texture(dirt_tex, muv * 1.15).rgb, vec3(0.2126, 0.7152, 0.0722));
		float detail_luma = mix(meadow_luma, forest_luma, clamp(dark_grass * 0.85, 0.0, 0.55));
		detail_luma = mix(detail_luma, dirt_luma, dirt_mask * 0.10);
		// Recentre luma so a bright sandy scan cannot lift the lawn.
		detail_luma = clamp(0.42 + (detail_luma - 0.50) * 0.28, 0.28, 0.62);
		float variation = smoothstep(0.20, 0.80, detail_luma);
		vec3 palette_meadow = mix(grass_moss, meadow_lush, variation);
		grass = mix(grass, palette_meadow * (0.92 + detail_luma * 0.16), tex_mix);
	}
	// Blade-scale tuft striping so the meadow is not a painted slab.
	if (lod_cheap < 0.5) {
		float tuft = abs(fract(world_pos.x * 1.85 + world_pos.z * 0.35 + patch * 0.4) - 0.5);
		grass = mix(grass, grass * vec3(0.82, 0.88, 0.70), (1.0 - smoothstep(0.08, 0.28, tuft)) * 0.22);
		float bloom = noise2(world_pos.xz / 3.6 + vec2(17.0, 5.0));
		float blossom_w = smoothstep(0.70, 0.92, patch) * smoothstep(0.62, 0.88, bloom);
		vec3 blossom = mix(flower_warm, flower_cool, step(0.5, noise2(world_pos.xz * 0.37)));
		grass = mix(grass, mix(grass, blossom, 0.55), blossom_w * flower_amount);
	}
	// COLOR.a is the occupation splat. Some backends drop vertex alpha
	// to 1; then brown RGB (r > g) still marks roads / aprons, and
	// gold (g - b high) marks crop rows.
	float occupy = clamp(COLOR.a, 0.0, 1.0);
	if (occupy > 0.98) {
		occupy = max(
			smoothstep(0.04, 0.14, length(COLOR.rgb - grass)),
			smoothstep(0.0, 0.08, COLOR.r - COLOR.g)
		);
	}
	// GFX-N: 512² road-control mask. Union (max) so intersections stay
	// solid instead of averaging away at the Town Hall junction.
	vec2 road_uv = (world_pos.xz - world_min_xz) / max(world_size_xz, vec2(0.001));
	// ImageTexture / spatial V can disagree on lavapipe. Union both
	// orientations so the 512² mask cannot miss the settlement.
	vec2 ru = clamp(road_uv, vec2(0.0), vec2(1.0));
	vec2 rf = vec2(ru.x, 1.0 - ru.y);
	float control = max(texture(road_control_tex, ru).r, texture(road_control_tex, rf).r) * road_control_amount;
	occupy = max(occupy, control);
	if (road_debug > 0.5) {
		ALBEDO = mix(vec3(0.22, 0.28, 0.20), vec3(1.0, 0.0, 1.0), clamp(control, 0.0, 1.0));
		ROUGHNESS = 1.0;
		METALLIC = 0.0;
		return;
	}
	float crop = occupy * crop_amount
		* smoothstep(0.18, 0.30, COLOR.g - COLOR.b)
		* smoothstep(0.06, 0.14, COLOR.r - COLOR.g);
	// Irregular chewed edge so footprints are not board-game rectangles.
	// Do not chew the unioned road-control mask — intersections stay solid.
	float chew = lod_cheap > 0.5 ? 0.5 : noise2(world_pos.xz * 1.65 + vec2(2.4, 9.1));
	occupy = max(occupy * clamp(0.84 + (chew - 0.5) * 0.24, 0.68, 1.0), control);
	// Road shoulders: 20–35% of the road width, world-space noise, not
	// a hard tile edge. Mid occupy = shoulder; high occupy = packed clay.
	float shoulder = smoothstep(0.18, 0.55, occupy) * (1.0 - smoothstep(0.72, 0.94, occupy));
	vec3 occupy_albedo = mix(dirt_color, road_earth, smoothstep(0.28, 0.82, max(COLOR.r, control)));
	occupy_albedo = mix(occupy_albedo, COLOR.rgb, 0.12);
	occupy_albedo = mix(occupy_albedo, mix(dirt_color, vec3(0.325, 0.416, 0.251), 0.40), shoulder * 0.28);
	vec3 ground = mix(grass, occupy_albedo, occupy * (1.0 - crop));
	if (crop > 0.08) {
		float furrow = abs(fract(world_pos.x * 0.64 + world_pos.z * 0.05) - 0.5);
		float ridge = smoothstep(0.05, 0.34, furrow);
		vec3 wheat = mix(wheat_furrow, wheat_gold, ridge);
		wheat = mix(wheat, wheat * 0.78, dirt_mask * 0.28);
		ground = mix(ground, wheat, clamp(crop * 0.96, 0.0, 1.0));
	}
	// Keep dirt_amount for older gates; visually cap it so the meadow
	// stays green. Earth belongs on roads and yards, not the lawn.
	ground = mix(ground, dirt_color, dirt_mask * dirt_amount * 0.07 * (1.0 - occupy * 0.90) * (1.0 - crop));
	float gravel_n = lod_cheap > 0.5 ? 0.0 : smoothstep(0.72, 0.93, noise2(world_pos.xz / 7.5 + vec2(2.2, 14.0)));
	ground = mix(ground, gravel_color, gravel_n * 0.34 * stone_amount * (0.22 + occupy));
	if (lod_cheap < 0.5) {
		float pebble = hash21(floor(world_pos.xz * 2.4));
		float pebble_w = step(0.965, pebble) * (1.0 - occupy * 0.4) * (1.0 - crop);
		ground = mix(ground, mix(gravel_color, dirt_color, 0.35), pebble_w * stone_amount);
	}
	float macro_var = mix(1.0 - macro_amount, 1.0 + macro_amount, broad);
	float detail_var = mix(1.0 - detail_amount * 0.55, 1.0 + detail_amount, detail);
	float wash = smoothstep(tint_wash_lo, max(tint_wash_lo + 0.02, tint_wash_hi), broad);
	vec3 albedo = ground * mix(vec3(1.0), light_tint, mix(tint_floor, 1.0, wash)) * macro_var * detail_var;
	vec3 shore = mix(beach_color, rock_shore, clamp(dirt_mask * 0.65 + broad * 0.35, 0.0, 1.0));
	albedo = mix(albedo, shore, beach * (apron_mode > 0.5 ? 0.98 : 0.88));
	if (apron_mode > 0.5) {
		float wet = 1.0 - smoothstep(0.0, 4.8, max(land, 0.0));
		albedo = mix(albedo, wet_sand, wet * 0.78);
	}
	ALBEDO = albedo;
	if (lod_cheap > 0.5) {
		NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	} else {
		// Reuse patch/detail already paid for. Four extra fbm taps
		// were a lavapipe first-frame tax for almost no camera read.
		float bump_w = mix(0.36, 0.72, dirt_mask + crop * 0.4 + occupy * 0.25);
		vec3 bump = normalize(vec3((detail - 0.5) * bump_w, 1.0, (patch - 0.5) * bump_w));
		NORMAL = normalize((VIEW_MATRIX * vec4(bump, 0.0)).xyz);
	}
	ROUGHNESS = mix(0.94, mix(0.90, 0.82, crop), occupy * 0.55 + dirt_mask * 0.20);
	METALLIC = 0.0;
}
