extends SceneTree

# Audit tool: compares runtime asset paths vs export_presets.cfg
# Usage: godot --script tools/audit_export_packing.gd

const ProductionAssetCatalog3D = preload("res://src/GodotClient3D/Scripts/production_asset_catalog.gd")

const AUDIO_STEM_PATHS := {
	"day": "res://assets/settlement/audio/presentation/bgm_settlement_loop.ogg",
	"activity": "res://assets/settlement/audio/presentation/score_settlement_activity.wav",
	"dusk": "res://assets/settlement/audio/presentation/score_dusk_tension.wav",
	"night": "res://assets/settlement/audio/presentation/score_night_percussion.wav",
	"raid": "res://assets/settlement/audio/presentation/score_metal_combat.wav",
	"ambience": "res://assets/settlement/audio/presentation/ambient_world.wav",
	"wyrd": "res://assets/settlement/audio/presentation/wyrd_drone.wav",
	"lumen": "res://assets/settlement/audio/presentation/lumen_hum.wav"
}

const AUDIO_CUE_PATHS := {
	"click": "res://assets/settlement/audio/presentation/ui_click.wav",
	"nightfall": "res://assets/settlement/audio/presentation/nightfall_sting.wav",
	"dawn": "res://assets/settlement/audio/presentation/dawn_release.wav",
	"victory": "res://assets/settlement/audio/presentation/victory_motif.wav",
	"defeat": "res://assets/settlement/audio/presentation/defeat_motif.wav",
	"reckoning": "res://assets/settlement/audio/presentation/reckoning_pulse.wav",
	"scream": "res://assets/settlement/audio/presentation/night_scream.wav",
	"enemy": "res://assets/settlement/audio/enemy.wav",
	"night_event": "res://assets/settlement/audio/night.wav",
	"attack": "res://assets/settlement/audio/attack.wav",
	"tower": "res://assets/settlement/audio/tower.wav",
	"build_start": "res://assets/settlement/audio/build_start.wav",
	"build_complete": "res://assets/settlement/audio/build_complete.wav",
	"soldier": "res://assets/settlement/audio/soldier.wav",
	"farm_complete": "res://assets/settlement/audio/farm_animal.wav",
	"farm_ambient": "res://assets/settlement/audio/farm_ambient.wav",
	"barracks_complete": "res://assets/settlement/audio/barracks_ready.wav",
	"settler_spawn_worker": "res://assets/settlement/audio/settler_arrive_worker.wav",
	"settler_spawn_soldier": "res://assets/settlement/audio/settler_arrive_soldier.wav",
	"settler_spawn_generic": "res://assets/settlement/audio/settler_arrive_generic.wav"
}

const AUDIO_WORK_PATHS := [
	"res://assets/settlement/audio/presentation/work_chop.wav",
	"res://assets/settlement/audio/saw.wav",
	"res://assets/settlement/audio/presentation/work_hammer.wav"
]

func _init() -> void:
	var all_runtime: Array[String] = []
	
	# Collect asset catalog paths
	all_runtime.append_array(ProductionAssetCatalog3D.all_runtime_paths())
	
	# Collect audio paths
	for stem_path in AUDIO_STEM_PATHS.values():
		if not all_runtime.has(String(stem_path)):
			all_runtime.append(String(stem_path))
	
	for cue_path in AUDIO_CUE_PATHS.values():
		if not all_runtime.has(String(cue_path)):
			all_runtime.append(String(cue_path))
	
	for work_path in AUDIO_WORK_PATHS:
		if not all_runtime.has(work_path):
			all_runtime.append(work_path)
	
	print("\n=== RUNTIME ASSET AUDIT ===\n")
	print("Total runtime paths: %d\n" % all_runtime.size())
	
	# Load export_presets.cfg
	var export_config := ConfigFile.new()
	var err := export_config.load("res://export_presets.cfg")
	if err != OK:
		print("ERROR: Could not load export_presets.cfg (code %d)" % err)
		quit(1)
		return
	
	var export_files: PackedStringArray = export_config.get_value("preset.0", "export_files", PackedStringArray())
	print("Export files count: %d\n" % export_files.size())
	
	# Find missing paths
	var missing: Array[String] = []
	var exists_but_missing: Array[String] = []
	
	for runtime_path in all_runtime:
		if not export_files.has(runtime_path):
			missing.append(runtime_path)
			if FileAccess.file_exists(runtime_path):
				exists_but_missing.append(runtime_path)
	
	if missing.is_empty():
		print("✓ All runtime paths are in export_files!\n")
	else:
		print("⚠ MISSING FROM EXPORT: %d paths\n" % missing.size())
		print("Files that EXIST on disk but are NOT in export_files:\n")
		for path in exists_but_missing:
			print("  - %s" % path)
		print("\nPaths referenced but don't exist on disk (expected for some):\n")
		for path in missing:
			if not exists_but_missing.has(path):
				print("  - %s" % path)
	
	print("\n=== AUDIT COMPLETE ===\n")
	quit(0 if exists_but_missing.is_empty() else 1)
