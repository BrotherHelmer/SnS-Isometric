extends SceneTree

## 100-seed founding-site gate. Every new game must have one real Town Hall,
## no fake buildings, an irregular clearing, reachable wood/stone/food,
## bridges that cross the creek, and a Lumber Camp quest.

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")

const SEED_COUNT := 100
const BASE_SEED := 260821

var failures: Array[String] = []
var rows: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var dest := ProjectSettings.globalize_path("res://artifacts/first_screen")
	DirAccess.make_dir_recursive_absolute(dest)
	var t0 := Time.get_ticks_msec()
	var passed := 0
	for i in SEED_COUNT:
		var seed_value := BASE_SEED + i * 97
		var sim = Simulation.new()
		sim.start_new_run(70, 70, seed_value, true)
		var audit: Dictionary = sim.founding_audit()
		var ok := _check_audit(audit, seed_value)
		if ok:
			passed += 1
		rows.append("%d\t%d\t%d\t%d\t%.1f\t%.1f\t%s\t%s\t%s\t%s\t%s\t%s" % [
			seed_value,
			int(audit.get("functional_buildings", -1)),
			int(audit.get("fake_buildings", -1)),
			int(audit.get("clearing_trees", -1)),
			float(audit.get("clearing_rx", 0.0)),
			float(audit.get("clearing_ry", 0.0)),
			str(audit.get("tree_reachable", false)),
			str(audit.get("rock_reachable", false)),
			str(audit.get("food_reachable", false)),
			str(audit.get("bridges_cross", false)),
			str(audit.get("quest_target", false)),
			"PASS" if ok else "FAIL",
		])
	var sim_ms := float(Time.get_ticks_msec() - t0)
	print("T_FOUNDING_SEEDS sim_pass=%d/%d sim_ms=%.0f" % [passed, SEED_COUNT, sim_ms])

	var mesh_seeds := [BASE_SEED, BASE_SEED + 97, BASE_SEED + 194]
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	for seed_value in mesh_seeds:
		var t1 := Time.get_ticks_msec()
		game.start_new_3d(int(seed_value))
		game._hide_start_menu()
		game.simulation_host.paused = true
		if game.has_method("_update_ui"):
			game._update_ui()
		for _i in 3:
			await process_frame
		var fake: Array[String] = game.world_view.non_inspectable_building_meshes(-1.0)
		var start_ms := float(Time.get_ticks_msec() - t1)
		print("T_FOUNDING_SEEDS mesh_seed=%d fake=%s start_ms=%.0f" % [seed_value, str(fake), start_ms])
		_check(fake.is_empty(), "seed %d has 0 fake building meshes" % seed_value)
		var sim = game.simulation_host.simulation
		_check(int(sim.founding_audit().get("functional_buildings", 0)) == 1, "seed %d 3D has one Town Hall" % seed_value)
		_check(game.objective_button != null and String(game.objective_button.text).contains("Lumber Camp"), "seed %d HUD quest says Lumber Camp" % seed_value)

	var report := dest.path_join("founding_seeds.txt")
	var file := FileAccess.open(report, FileAccess.WRITE)
	if file != null:
		file.store_line("seed\tfunctional\tfake\tclearing_trees\trx\try\ttree\trock\tfood\tbridges\tquest\tresult")
		for row in rows:
			file.store_line(row)
		file.store_line("sim_pass=%d/%d sim_ms=%.0f" % [passed, SEED_COUNT, sim_ms])
		file.close()
	print("T_FOUNDING_SEEDS report=%s" % report)
	print("T_FOUNDING_SEEDS %s" % ("PASS" if failures.is_empty() else "FAIL"))
	for failure in failures:
		print("  FAIL %s" % failure)
	if game != null:
		game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)


func _check_audit(audit: Dictionary, seed_value: int) -> bool:
	var ok := true
	ok = _check(int(audit.get("functional_buildings", 0)) == 1, "seed %d exactly 1 functional building" % seed_value) and ok
	ok = _check(int(audit.get("fake_buildings", 1)) == 0, "seed %d 0 fake buildings" % seed_value) and ok
	ok = _check(int(audit.get("clearing_trees", 1)) == 0, "seed %d clearing has no trees" % seed_value) and ok
	ok = _check(int(audit.get("clearing_rocks", 1)) == 0, "seed %d clearing has no rocks" % seed_value) and ok
	ok = _check(float(audit.get("clearing_rx", 0.0)) >= 7.0 and float(audit.get("clearing_rx", 0.0)) <= 10.0, "seed %d clearing rx in range" % seed_value) and ok
	ok = _check(float(audit.get("clearing_ry", 0.0)) >= 6.0 and float(audit.get("clearing_ry", 0.0)) <= 10.0, "seed %d clearing ry in range" % seed_value) and ok
	ok = _check(bool(audit.get("tree_reachable", false)), "seed %d wood reachable" % seed_value) and ok
	ok = _check(bool(audit.get("rock_reachable", false)), "seed %d stone reachable" % seed_value) and ok
	ok = _check(bool(audit.get("food_reachable", false)), "seed %d food reachable" % seed_value) and ok
	ok = _check(bool(audit.get("creek_continuous", false)), "seed %d creek is continuous" % seed_value) and ok
	ok = _check(bool(audit.get("bridges_cross", false)), "seed %d bridges cross water" % seed_value) and ok
	ok = _check(bool(audit.get("quest_target", false)), "seed %d quest targets Lumber Camp" % seed_value) and ok
	return ok


func _check(condition: bool, label: String) -> bool:
	if not condition:
		failures.append(label)
		return false
	return true
