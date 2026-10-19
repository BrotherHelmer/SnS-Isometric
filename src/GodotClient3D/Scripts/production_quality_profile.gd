class_name ProductionQualityProfile3D
extends RefCounted

const PROFILES := {
	"recommended": {
		"name": "recommended",
		"foliage_density": 1.0,
		"grass_density": 1.0,
		"shadows": true,
		"shadow_distance": 56.0,
		"shadow_blur": 1.0,
		"shadow_splits": 1,
		"water_detail": 1.0,
		"vfx_density": 1.0,
		"animation_lod": 1.0,
		"ambient_actor_budget": 0,
		"anti_aliasing": "project_default",
		"ssil": false,
		"glow": false,
		"volumetric_fog": false,
		"ssao": true,
	},
	"high": {
		"name": "high",
		"foliage_density": 1.0,
		"grass_density": 1.0,
		"shadows": true,
		"shadow_distance": 52.0,
		"shadow_blur": 1.6,
		"shadow_splits": 1,
		"water_detail": 1.0,
		"vfx_density": 1.0,
		"animation_lod": 1.0,
		"ambient_actor_budget": 0,
		"anti_aliasing": "project_default",
		"ssil": false,
		"glow": true,
		"volumetric_fog": false,
		"ssao": true,
	},
	"scalable_low": {
		"name": "scalable_low",
		# Hotfix 5: iGPU default (sun shadow OFF, 2 splits = pre-freeze state, hotfix 7,
		# most vegetation) while dropping SSAO, MSAA and glow; 3D at 1.0 (Helmer 2026-10-15: 100% render scale required; no 75% option).
		"foliage_density": 0.85,
		"grass_density": 0.70,
		"shadows": false,
		"shadow_distance": 40.0,
		"shadow_blur": 1.0,
		"shadow_splits": 1,
		"water_detail": 0.6,
		"vfx_density": 0.6,
		"animation_lod": 0.8,
		"ambient_actor_budget": 0,
		"anti_aliasing": "disabled_by_launch_profile",
		"render_scale": 1.0,
		"msaa": false,
		"ssil": false,
		"glow": false,
		"volumetric_fog": false,
		"ssao": false,
	},
}


static func get_profile(profile_name: String) -> Dictionary:
	return Dictionary(PROFILES.get(profile_name, PROFILES["recommended"])).duplicate(true)
