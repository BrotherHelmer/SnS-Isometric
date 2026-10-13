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
		"shadow_splits": 4,
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
		"shadow_splits": 4,
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
		"foliage_density": 0.45,
		"grass_density": 0.50,
		"shadows": false,
		"shadow_distance": 55.0,
		"shadow_blur": 1.0,
		"shadow_splits": 2,
		"water_detail": 0.35,
		"vfx_density": 0.40,
		"animation_lod": 0.60,
		"ambient_actor_budget": 0,
		"anti_aliasing": "disabled_by_launch_profile",
		"ssil": false,
		"glow": false,
		"volumetric_fog": false,
		"ssao": false,
	},
}


static func get_profile(profile_name: String) -> Dictionary:
	return Dictionary(PROFILES.get(profile_name, PROFILES["recommended"])).duplicate(true)
