extends SceneTree

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Adapter = preload("res://src/GodotClient3D/Scripts/production_presentation_adapter.gd")
const Fixture = preload("res://src/GodotClient3D/Scripts/production_demo_fixture.gd")

const SAVE_PATH := "res://artifacts/phase2/persistence/vertical_slice_round_trip.json"


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/phase2/persistence"))
	var failures: Array[String] = []
	var simulation := Simulation.new(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 260821, false, true)
	var result: Dictionary = Fixture.new().apply(simulation, "developed")
	for message in result.get("report", []):
		print("FIXTURE %s" % message)
	_check(failures, bool(result.get("success", false)), "deterministic production fixture uses authoritative commands successfully")
	var completed_types: Dictionary = {}
	var completed_road_count := 0
	var completed_road_tiles: Dictionary = {}
	for building_value in simulation.get_buildings():
		var building: Dictionary = building_value
		if bool(building.get("construction", false)):
			continue
		var type_name := String(building.get("type", ""))
		completed_types[type_name] = int(completed_types.get(type_name, 0)) + 1
		if type_name == Defs.BUILDING_ROAD:
			completed_road_count += 1
			var road_tile: Vector2i = building.get("position", Vector2i.ZERO)
			completed_road_tiles["%d,%d" % [road_tile.x, road_tile.y]] = true
	_check(failures, completed_road_count >= 6, "real connected road graph grows beyond the founding entrance")
	_check(failures, completed_types.has(Defs.BUILDING_LUMBER_CAMP), "lumber building completes through production construction")
	_check(failures, completed_types.has(Defs.BUILDING_FARM), "farm second chain completes through production construction")
	_check(failures, completed_types.has(Defs.BUILDING_HOUSE), "housing wrapper has authoritative production state")
	var adapter := Adapter.new()
	var frame: Dictionary = adapter.capture_frame(simulation)
	_check(failures, frame.get("roads", []).size() == completed_road_tiles.size(), "unique authoritative road cells map one-to-one into semantic road snapshots")
	_check(failures, frame.get("workers", []).size() == simulation.get_workers().size(), "worker creation maps one-to-one by stable entity ID")
	var semantic_ids: Dictionary = {}
	var semantic_valid := true
	for worker_value in frame.get("workers", []):
		var worker: Dictionary = worker_value
		semantic_ids[int(worker.get("id", 0))] = true
		semantic_valid = semantic_valid and String(worker.get("state", "")) in Adapter.ALL_STATES
	_check(failures, semantic_ids.size() == frame.get("workers", []).size() and semantic_valid, "worker semantic mapping preserves unique IDs and valid states")
	var saved := simulation.save_to_path(SAVE_PATH)
	_check(failures, saved, "production save serializer writes the Phase 2 fixture")
	var save_text := ""
	if saved:
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file != null:
			save_text = file.get_as_text()
	var presentation_free := ".glb" not in save_text and ".gltf" not in save_text and ".tscn" not in save_text and "animation_playback" not in save_text and "runtime_transform" not in save_text
	_check(failures, presentation_free, "save payload contains no 3D presentation paths or transient transforms")
	var reloaded := Simulation.new(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 7, false, true)
	var loaded := reloaded.load_from_path(SAVE_PATH)
	_check(failures, loaded, "production save payload reloads through the normal restore path")
	_check(failures, reloaded.rng_seed == simulation.rng_seed, "fixed seed survives save/load")
	_check(failures, reloaded.get_buildings().size() == simulation.get_buildings().size(), "building authority survives save/load")
	_check(failures, reloaded.get_workers().size() == simulation.get_workers().size(), "worker authority survives save/load")
	var reconstructed: Dictionary = adapter.capture_frame(reloaded)
	_check(failures, reconstructed.get("buildings", []).size() == frame.get("buildings", []).size(), "3D building presentation reconstructs from loaded authority")
	_check(failures, reconstructed.get("roads", []).size() == frame.get("roads", []).size(), "3D road presentation reconstructs from loaded authority")
	_check(failures, reconstructed.get("workers", []).size() == frame.get("workers", []).size(), "3D worker presentation reconstructs from loaded authority")
	_finish(failures)


func _check(failures: Array[String], condition: bool, label: String) -> void:
	print("%s %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		failures.append(label)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("PHASE2_VERTICAL_SLICE PASS")
		quit(0)
	else:
		print("PHASE2_VERTICAL_SLICE FAIL count=%d" % failures.size())
		quit(1)
