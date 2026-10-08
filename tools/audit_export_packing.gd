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
	"settler_spawn_generic": "res://assets/settlement/audio/settler_arrive_generic.wav",
	"monster_kill_cheer": "res://assets/settlement/audio/monster_kill_cheer.wav"
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

	# GFX-E: also scan production scripts for string-loaded models.
	# export_filter="resources" does not follow load("res://...") by name.
	var code_models := _scan_code_model_paths()
	print("Code-referenced model paths: %d\n" % code_models.size())
	for model_path in code_models:
		if not all_runtime.has(model_path):
			all_runtime.append(model_path)
	
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


func _scan_code_model_paths() -> Array[String]:
	var paths: Array[String] = []
	var seen: Dictionary = {}
	_walk_scripts("res://src", paths, seen)
	return paths


func _walk_scripts(dir_path: String, paths: Array[String], seen: Dictionary) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = dir.get_next()
			continue
		var child := dir_path.path_join(entry)
		if dir.current_is_dir():
			_walk_scripts(child, paths, seen)
		elif entry.ends_with(".gd"):
			_collect_script_models(child, paths, seen)
		entry = dir.get_next()
	dir.list_dir_end()


func _collect_script_models(script_path: String, paths: Array[String], seen: Dictionary) -> void:
	var file := FileAccess.open(script_path, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var regex := RegEx.new()
	regex.compile("res://[A-Za-z0-9_./-]+\\.(?:tscn|res|gltf|glb)")
	for match in regex.search_all(text):
		var found := String(match.get_string())
		if found.begins_with("res://assets/settlement3d/"):
			_remember_model(found, paths, seen)
	var concat := RegEx.new()
	concat.compile("(?:ROOT|Catalog\\.ROOT)\\s*\\+\\s*\"([^\"]+\\.(?:tscn|res|gltf|glb))\"")
	for match in concat.search_all(text):
		var frag := String(match.get_string(1))
		if not frag.begins_with("/"):
			frag = "/" + frag
		_remember_model("res://assets/settlement3d/runtime" + frag, paths, seen)
	var names := RegEx.new()
	names.compile("\"([a-z][a-z0-9_]*)\"")
	if text.contains("opening_style/") or text.contains("_is_tree_path") or text.contains("_is_scatter_path"):
		for match in names.search_all(text):
			var candidate := "res://assets/settlement3d/runtime/opening_style/%s.tscn" % String(match.get_string(1))
			if FileAccess.file_exists(candidate):
				_remember_model(candidate, paths, seen)


func _remember_model(path_value: String, paths: Array[String], seen: Dictionary) -> void:
	if seen.has(path_value):
		return
	seen[path_value] = true
	paths.append(path_value)
	if path_value.ends_with(".tscn"):
		var sibling := path_value.trim_suffix(".tscn") + ".res"
		if FileAccess.file_exists(sibling) and not seen.has(sibling):
			seen[sibling] = true
			paths.append(sibling)
