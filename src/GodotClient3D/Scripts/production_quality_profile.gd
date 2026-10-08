class_name ProductionQualityProfile3D
extends RefCounted

## Access-1 presets. High is the current GFX look. Low is the cheap path.
## recommended / scalable_low stay as aliases so older tests and saves keep working.

const PRESETS := ["low", "medium", "high"]

const PROFILES := {
	"high": {
		"name": "high",
		"foliage_density": 1.0,
		"ground_detail": 1.0,
		"shadows": true,
		"shadow_distance": 48.0,
		"pssm_splits": 2,
		"water_detail": 1.0,
		"vfx_density": 1.0,
		"animation_lod": 1.0,
		"ambient_actor_budget": 0,
		"msaa": 2,
		"fxaa": false,
		"render_scale": 1.0,
		"anti_aliasing": "msaa_2x",
		"ssil": false,
		"glow": false,
		"volumetric_fog": false,
		"ssao": true,
	},
	"medium": {
		"name": "medium",
		"foliage_density": 0.70,
		"ground_detail": 0.70,
		"shadows": true,
		"shadow_distance": 40.0,
		"pssm_splits": 2,
		"water_detail": 0.70,
		"vfx_density": 0.70,
		"animation_lod": 0.85,
		"ambient_actor_budget": 0,
		"msaa": 0,
		"fxaa": true,
		"render_scale": 0.85,
		"anti_aliasing": "fxaa",
		"ssil": false,
		"glow": false,
		"volumetric_fog": false,
		"ssao": true,
	},
	"low": {
		"name": "low",
		"foliage_density": 0.40,
		"ground_detail": 0.35,
		"shadows": false,
		"shadow_distance": 28.0,
		"pssm_splits": 1,
		"water_detail": 0.30,
		"vfx_density": 0.35,
		"animation_lod": 0.55,
		"ambient_actor_budget": 0,
		"msaa": 0,
		"fxaa": false,
		"render_scale": 0.70,
		"anti_aliasing": "disabled",
		"ssil": false,
		"glow": false,
		"volumetric_fog": false,
		"ssao": false,
	},
	"recommended": {
		"name": "recommended",
		"foliage_density": 1.0,
		"ground_detail": 1.0,
		"shadows": true,
		"shadow_distance": 48.0,
		"pssm_splits": 2,
		"water_detail": 1.0,
		"vfx_density": 1.0,
		"animation_lod": 1.0,
		"ambient_actor_budget": 0,
		"msaa": 2,
		"fxaa": false,
		"render_scale": 1.0,
		"anti_aliasing": "project_default",
		"ssil": false,
		"glow": false,
		"volumetric_fog": false,
		"ssao": true,
	},
	"scalable_low": {
		"name": "scalable_low",
		"foliage_density": 0.40,
		"ground_detail": 0.35,
		"shadows": false,
		"shadow_distance": 28.0,
		"pssm_splits": 1,
		"water_detail": 0.30,
		"vfx_density": 0.35,
		"animation_lod": 0.55,
		"ambient_actor_budget": 0,
		"msaa": 0,
		"fxaa": false,
		"render_scale": 0.70,
		"anti_aliasing": "disabled_by_launch_profile",
		"ssil": false,
		"glow": false,
		"volumetric_fog": false,
		"ssao": false,
	},
}

const ALIASES := {
	"recommended": "high",
	"scalable_low": "low",
	"high": "high",
	"medium": "medium",
	"low": "low",
}


static func resolve_name(profile_name: String) -> String:
	var key := profile_name.strip_edges().to_lower()
	if key == "recommended":
		return "high"
	if key == "scalable_low":
		return "low"
	if PRESETS.has(key):
		return key
	return "high"


static func get_profile(profile_name: String) -> Dictionary:
	if PROFILES.has(profile_name):
		return Dictionary(PROFILES[profile_name]).duplicate(true)
	var resolved := resolve_name(profile_name)
	return Dictionary(PROFILES.get(resolved, PROFILES["high"])).duplicate(true)


static func apply_viewport(viewport: Viewport, quality: Dictionary) -> void:
	if viewport == null:
		return
	var msaa := int(quality.get("msaa", 2 if bool(quality.get("shadows", true)) else 0))
	match msaa:
		8:
			viewport.msaa_3d = Viewport.MSAA_8X
		4:
			viewport.msaa_3d = Viewport.MSAA_4X
		2:
			viewport.msaa_3d = Viewport.MSAA_2X
		_:
			viewport.msaa_3d = Viewport.MSAA_DISABLED
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if bool(quality.get("fxaa", false)) else Viewport.SCREEN_SPACE_AA_DISABLED
	viewport.scaling_3d_scale = clampf(float(quality.get("render_scale", 1.0)), 0.50, 1.0)


static func apply_sun(light: DirectionalLight3D, quality: Dictionary) -> void:
	if light == null:
		return
	var splits := int(quality.get("pssm_splits", 2))
	if splits >= 4:
		light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	elif splits >= 2:
		light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	else:
		light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	light.directional_shadow_blend_splits = splits >= 2
	light.directional_shadow_split_1 = 0.82 if splits >= 2 else 0.1
	light.directional_shadow_max_distance = float(quality.get("shadow_distance", 48.0))
	light.directional_shadow_fade_start = 0.86
	light.directional_shadow_pancake_size = 4.0
	light.shadow_bias = 0.06
	light.shadow_normal_bias = 1.6
	light.shadow_enabled = bool(quality.get("shadows", true))
	light.light_angular_distance = 0.0
