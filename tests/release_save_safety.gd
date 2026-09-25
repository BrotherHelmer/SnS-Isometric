extends SceneTree

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Store = preload("res://src/GodotClient/Scripts/one_shard_save_store.gd")
var failures: Array[String] = []

func _init() -> void:
	var folder := "user://save_safety_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(folder)
	var path := folder + "/realm.json"
	var sim = Simulation.new(70, 70, 260821, false, true)
	check(sim.save_to_path(path), "initial save: " + sim.last_message)
	check(FileAccess.file_exists(path + ".bak"), "first save has recovery copy")
	for tick in 30:
		sim.advance_tick()
	check(sim.save_to_path(path), "replacement save: " + sim.last_message)
	var restored = Simulation.new(70, 70, 123, false, true)
	check(restored.load_from_path(path), "disk reload")
	check(restored.tick_number == sim.tick_number and restored.rng.state == sim.rng.state, "clock and RNG preserved")
	check(restored.central_inventory == sim.central_inventory, "resource ledger preserved")
	_write(path, "{truncated")
	check(restored.load_from_path(path) and "Recovered" in restored.last_message, "corrupt primary recovers backup")
	check(restored.tick_number == 0, "recovery is previous valid run")
	check(restored.save_to_path(path), "saving recovered realm does not copy corruption over backup")
	check(Store.read_save(path + ".bak", false).get("success", false), "backup remains valid")
	var future: Dictionary = sim._serialize_state().duplicate(true)
	future.version = 999
	_write(path, JSON.stringify(future))
	var before: Dictionary = restored._serialize_state().duplicate(true)
	check(not restored.load_from_path(path), "future schema rejected even with older backup")
	check(restored.tick_number == before.tick_number and restored.central_inventory == before.central_inventory, "failed load leaves live realm intact")
	for version in [6, 7, 8]:
		var migrated: Dictionary = sim._serialize_state().duplicate(true)
		migrated.version = version
		_write(folder + "/migration.json", JSON.stringify(migrated))
		check(restored.load_from_path(folder + "/migration.json"), "supported schema %d loads" % version)
	for mutation in ["missing_map", "wrong_width", "duplicate_id", "bad_inventory", "bad_path", "bad_local_inventory", "bad_footprint", "bad_counter", "bad_projectile", "bad_rivalry"]:
		var bad: Dictionary = sim._serialize_state().duplicate(true)
		match mutation:
			"missing_map": bad.erase("map_tiles")
			"wrong_width": bad.height_map[0] = []
			"duplicate_id": bad.buildings.append(bad.buildings[0].duplicate(true))
			"bad_inventory": bad.central_inventory.wood = -20
			"bad_path": bad.workers[0].path = [{"x": 900, "y": 0}]
			"bad_local_inventory": bad.buildings[0].local_inventory.wood = []
			"bad_footprint": bad.buildings[0].footprint = "broken"
			"bad_counter": bad.next_worker_id = 1
			"bad_projectile": bad.projectiles = ["broken"]
			"bad_rivalry": bad.rivalry_state.realms.player.claim = []
		check(Store.validate(bad) != "", "reject " + mutation)
		_write(folder + "/invalid.json", JSON.stringify(bad))
		var unchanged_tick: int = restored.tick_number
		check(not restored.load_from_path(folder + "/invalid.json") and restored.tick_number == unchanged_tick, "bad disk state rejected before mutation: " + mutation)
	sim.priority_clear_tiles["20,20"] = 8
	check(sim.save_to_path(path) and restored.load_from_path(path) and int(restored.priority_clear_tiles.get("20,20", 0)) == 8, "clearing priorities survive reload")
	# Simulate interruption before replacement: an incomplete temp file is never
	# chosen instead of a valid primary. A failed write leaves that primary intact.
	check(sim.save_to_path(path), "restore valid primary")
	_write(path + ".tmp", "{")
	check(restored.load_from_path(path) and restored.tick_number == sim.tick_number, "interrupted temporary write ignored")
	check(not sim.save_to_path(folder + "/missing/realm.json"), "unwritable destination reports failure")
	check(Store.read_save(path, false).get("success", false), "failed write preserves earlier save")
	print("RELEASE_SAVE_SAFETY %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)

func _write(path: String, contents: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(contents)
	file.close()

func check(condition: bool, label: String) -> void:
	print("%s %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		failures.append(label)
