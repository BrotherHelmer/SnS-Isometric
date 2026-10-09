shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

// The Director: GFX-O. Diagnose then own the final albedo.
// terrain_debug 1 = magenta (shader is live), 2 = solid #556D3F,
// 3 = red road mask over dark green. Road control is linear data.
uniform vec3 light_tint : source_color = vec3(1.0);
uniform float tint_floor = 0.0;
uniform float tint_wash_lo = 0.70;
uniform float tint_wash_hi = 0.94;
uniform vec3 grass_sunlit : source_color = vec3(0.451, 0.525, 0.314); // #738650
uniform vec3 grass_moss : source_color = vec3(0.227, 0.318, 0.208); // #3A5135
uniform vec3 dirt_color : source_color = vec3(0.525, 0.404, 0.282); // #866748
uniform vec3 meadow_lush : source_color = vec3(0.333, 0.427, 0.247); // #556D3F
uniform vec3 meadow_warm : source_color = vec3(0.451, 0.525, 0.314); // #738650
uniform vec3 meadow_shade : source_color = vec3(0.243, 0.349, 0.220); // #3E5938
uniform vec3 flower_warm : source_color = vec3(0.820, 0.678, 0.302);
uniform vec3 flower_cool : source_color = vec3(0.878, 0.831, 0.682);
uniform vec3 gravel_color : source_color = vec3(0.729, 0.659, 0.557); // #BAA88E
uniform vec3 forest_floor : source_color = vec3(0.204, 0.286, 0.208); // #344935
uniform vec3 road_earth : source_color = vec3(0.678, 0.553, 0.400); // #AD8D66
uniform vec3 road_shoulder : source_color = vec3(0.525, 0.404, 0.282); // #866748
uniform vec3 road_rut : source_color = vec3(0.408, 0.322, 0.231); // #68523B
uniform vec3 wheat_gold : source_color = vec3(0.788, 0.635, 0.290);
uniform vec3 wheat_furrow : source_color = vec3(0.420, 0.310, 0.165);
uniform float macro_metres = 8.0;
uniform float patch_metres = 1.94;
uniform float detail_metres = 1.10;
uniform float macro_amount = 0.12;
uniform float detail_amount = 0.12;
uniform float dirt_amount = 0.56;
uniform float flower_amount = 0.22;
uniform float stone_amount = 0.22;
uniform float crop_amount = 1.0;
uniform float lod_cheap = 0.0;
uniform vec2 world_min_xz = vec2(-87.5, -87.5);
uniform vec2 world_size_xz = vec2(175.0, 175.0);
uniform vec3 beach_color : source_color = vec3(0.090, 0.153, 0.165);
uniform vec3 rock_shore : source_color = vec3(0.078, 0.125, 0.141);
uniform vec3 wet_sand : source_color = vec3(0.070, 0.110, 0.125);
uniform sampler2D meadow_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D forest_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D dirt_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float tex_mix = 0.12;
uniform float tex_repeat_meadow = 3.64;
uniform float tex_repeat_forest = 2.91;
// Linear mask. Do not mark this source_color.
uniform sampler2D road_control_tex : hint_default_black, filter_linear, repeat_disable;
uniform float road_control_amount = 1.0;
uniform float road_debug = 0.0;
uniform float terrain_debug = 0.0;
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

vec2 road_control_uv(vec2 world_xz) {
	vec2 uv = (world_xz - world_min_xz) / max(world_size_xz, vec2(0.001));
	// Image Y=0 is top. World +Z maps to the bottom row.
	uv.y = 1.0 - uv.y;
	return clamp(uv, vec2(0.0), vec2(1.0));
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (terrain_debug > 0.5 && terrain_debug < 1.5) {
		ALBEDO = vec3(1.0, 0.0, 1.0);
		ROUGHNESS = 1.0;
		METALLIC = 0.0;
		return;
	}
	if (terrain_debug > 1.5 && terrain_debug < 2.5) {
		ALBEDO = meadow_lush;
		ROUGHNESS = 0.94;
		METALLIC = 0.0;
		return;
	}
	float control = texture(road_control_tex, road_control_uv(world_pos.xz)).r * road_control_amount;
	if (terrain_debug > 2.5 || road_debug > 0.5) {
		ALBEDO = mix(vec3(0.16, 0.22, 0.14), vec3(0.86, 0.08, 0.08), smoothstep(0.12, 0.80, control));
		ROUGHNESS = 1.0;
		METALLIC = 0.0;
		return;
	}

	float land = island_land(world_pos.xz);
	float inward = inward_metres(world_pos.xz);
	if (apron_mode > 0.5) {
		if (inward > 0.25 || land <= 0.0) {
			discard;
		}
	}
	float beach = 1.0 - smoothstep(0.0, beach_margin_metres + 1.8, max(land, 0.0));

	vec2 broad_uv = world_pos.xz / max(macro_metres, 5.0 * 2.425);
	vec2 patch_uv = world_pos.xz / max(patch_metres, 1.2) + vec2(3.7, 11.2);
	vec2 detail_uv = world_pos.xz / max(detail_metres, 0.4) + vec2(8.2, 3.7);
	float broad = lod_cheap > 0.5 ? noise2(broad_uv) : fbm(broad_uv);
	float patch = lod_cheap > 0.5 ? noise2(patch_uv) : fbm(patch_uv);
	float detail = lod_cheap > 0.5 ? 0.5 : fbm(detail_uv);

	// Palette owns the meadow. No brightening above the lush hex.
	vec3 grass = mix(grass_moss, meadow_lush, clamp(broad * 0.55 + patch * 0.45, 0.0, 1.0));
	grass = mix(grass, grass_sunlit, smoothstep(0.70, 0.96, patch) * 0.16);
	// Soft shade patches: #3E5938, max 0.35, 35–50% feather, 5R macro.
	float shade_macro = fbm(world_pos.xz / max(macro_metres * 1.52, 12.0) + vec2(9.4, 2.1));
	float shade_w = smoothstep(0.42, 0.78, shade_macro) * 0.35;
	grass = mix(grass, meadow_shade, shade_w);
	grass = mix(grass, forest_floor, smoothstep(0.62, 0.92, 1.0 - patch) * 0.14);

	if (tex_mix > 0.01) {
		vec2 muv = world_pos.xz / max(tex_repeat_meadow, 1.5);
		float meadow_luma = dot(texture(meadow_tex, muv).rgb, vec3(0.2126, 0.7152, 0.0722));
		float forest_luma = dot(texture(forest_tex, world_pos.xz / max(tex_repeat_forest, 1.2)).rgb, vec3(0.2126, 0.7152, 0.0722));
		float detail_luma = mix(meadow_luma, forest_luma, shade_w);
		detail_luma = clamp(0.46 + (detail_luma - 0.50) * 0.22, 0.34, 0.58);
		grass *= (0.94 + detail_luma * 0.12);
		grass = mix(grass, grass * (0.90 + detail * 0.10), tex_mix);
	}

	if (lod_cheap < 0.5) {
		float tuft = abs(fract(world_pos.x * 1.85 + world_pos.z * 0.35 + patch * 0.4) - 0.5);
		grass = mix(grass, grass * vec3(0.90, 0.94, 0.86), (1.0 - smoothstep(0.08, 0.28, tuft)) * 0.12);
		float bloom = noise2(world_pos.xz / 3.6 + vec2(17.0, 5.0));
		float blossom_w = smoothstep(0.78, 0.94, patch) * smoothstep(0.70, 0.90, bloom);
		vec3 blossom = mix(flower_warm, flower_cool, step(0.5, noise2(world_pos.xz * 0.37)));
		grass = mix(grass, mix(grass, blossom, 0.35), blossom_w * flower_amount);
	}

	// Occupation: brown vertex (r > g) or the world-space road mask.
	// Never treat dropped-alpha grass verts as dirt — that was the
	// chalk-white GFX-N lawn.
	float occupy = 0.0;
	if (COLOR.r > COLOR.g + 0.04) {
		occupy = max(COLOR.a, smoothstep(0.02, 0.10, COLOR.r - COLOR.g));
	}
	float crop = occupy * crop_amount
		* smoothstep(0.18, 0.30, COLOR.g - COLOR.b)
		* smoothstep(0.06, 0.14, COLOR.r - COLOR.g);
	occupy *= (1.0 - crop);

	vec3 ground = grass;
	if (crop > 0.08) {
		float furrow = abs(fract(world_pos.x * 0.64 + world_pos.z * 0.05) - 0.5);
		vec3 wheat = mix(wheat_furrow, wheat_gold, smoothstep(0.05, 0.34, furrow));
		ground = mix(ground, wheat, clamp(crop * 0.96, 0.0, 1.0));
	}

	// Macro only darkens meadow. Never lift it toward chalk.
	float macro_var = mix(1.0 - macro_amount, 1.0, broad);
	ground *= macro_var;
	ground = mix(ground, dirt_color, 0.04 * dirt_amount * (1.0 - occupy) * (1.0 - crop));

	// Roads win last. smoothstep over the finished ground.
	float road_w = smoothstep(0.12, 0.80, control);
	float across = abs(fract(world_pos.x * 0.21 + world_pos.z * 0.17) - 0.5);
	float rut = (1.0 - smoothstep(0.0, 0.07, abs(across - 0.22)))
		+ (1.0 - smoothstep(0.0, 0.07, abs(across - 0.28)));
	vec3 road_col = mix(road_earth, road_shoulder, smoothstep(0.18, 0.62, 1.0 - control));
	road_col = mix(road_col, road_rut, clamp(rut * 0.45 * road_w, 0.0, 0.45));
	road_col = mix(road_col, gravel_color, smoothstep(0.82, 0.96, noise2(world_pos.xz * 3.1)) * 0.16 * road_w);
	ground = mix(ground, road_col, road_w);

	float wash = smoothstep(tint_wash_lo, max(tint_wash_lo + 0.02, tint_wash_hi), broad);
	vec3 albedo = ground * mix(vec3(1.0), min(light_tint, vec3(1.0)), mix(tint_floor, 0.12, wash));
	vec3 shore = mix(beach_color, rock_shore, clamp(broad * 0.45, 0.0, 1.0));
	albedo = mix(albedo, shore, beach * (apron_mode > 0.5 ? 0.98 : 0.88));
	if (apron_mode > 0.5) {
		albedo = mix(albedo, wet_sand, (1.0 - smoothstep(0.0, 4.8, max(land, 0.0))) * 0.78);
	}
	ALBEDO = albedo;
	if (lod_cheap > 0.5) {
		NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	} else {
		float bump_w = mix(0.20, 0.36, road_w);
		vec3 bump = normalize(vec3((detail - 0.5) * bump_w, 1.0, (patch - 0.5) * bump_w));
		NORMAL = normalize((VIEW_MATRIX * vec4(bump, 0.0)).xyz);
	}
	ROUGHNESS = 0.94;
	METALLIC = 0.0;
}
