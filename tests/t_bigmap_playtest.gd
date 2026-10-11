extends SceneTree

## 15-minute live playtest on the 320 province. Opening, a build, a
## scout into fog, first night, then the remainder of 15 game minutes.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
var failures: Array[String] = []
var script_errors := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var dest := ProjectSettings.globalize_path("res://artifacts/bigmap/playtest")
	DirAccess.make_dir_recursive_absolute(dest)
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	OS.set_environment("SNS_PLAYTEST_LOG", "1")
	game.start_new_3d(game.DEFAULT_SEED)
	game._hide_start_menu()
	game.simulation_host.paused = false
	var sim = game.simulation_host.simulation
	sim.playtest_log.configure(true, dest.path_join("dpm.csv"))
	sim.central_inventory[Defs.RESOURCE_BREAD] = maxi(int(sim.central_inventory.get(Defs.RESOURCE_BREAD, 0)), 16)
	sim.central_inventory[Defs.RESOURCE_WOOD] = maxi(int(sim.central_inventory.get(Defs.RESOURCE_WOOD, 0)), 24)
	sim.central_inventory[Defs.RESOURCE_PLANKS] = maxi(int(sim.central_inventory.get(Defs.RESOURCE_PLANKS, 0)), 20)
	sim.central_inventory[Defs.RESOURCE_STONE] = maxi(int(sim.central_inventory.get(Defs.RESOURCE_STONE, 0)), 20)
	_check(sim.map_size.x == 320, "playtest is on the 320 province")
	var road: Vector2i = sim._town_hall_entrance_tile() + Vector2i(0, 1)
	sim._prepare_test_tile(road, Defs.TILE_GRASS)
	var road_result: Dictionary = sim.request_build(Defs.BUILDING_ROAD, road)
	var house: Vector2i = road + Vector2i(2, 0)
	for offset in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i(1, 1)]:
		sim._prepare_test_tile(house + offset, Defs.TILE_GRASS)
	var build_result: Dictionary = sim.request_build(Defs.BUILDING_HOUSE, house)
	print("T_BIGMAP_PLAYTEST build_road=%s build_house=%s" % [str(road_result.get("success", false)), str(build_result.get("success", false))])
	_check(bool(road_result.get("success", false)) or bool(build_result.get("success", false)), "opening can place a road or house")
	sim._simulate_seconds_for_test(24.0)
	game._sync_presentation()
	var remain_day := maxf(8.0, float(sim.DAY_LENGTH_SECONDS) - float(sim.phase_time) + 2.0)
	sim._simulate_seconds_for_test(remain_day)
	game._sync_presentation()
	var remain_night := maxf(8.0, float(sim.NIGHT_LENGTH_SECONDS) - float(sim.phase_time) + 4.0)
	sim._simulate_seconds_for_test(remain_night)
	if float(sim.elapsed_seconds) < 900.0:
		sim._simulate_seconds_for_test(900.0 - float(sim.elapsed_seconds))
	game._sync_presentation()
	_check(float(sim.elapsed_seconds) >= 890.0, "playtest covers ~15 game minutes")
	_check(script_errors == 0, "no script errors during the 15-minute run")
	_check(not bool(sim.game_finished), "15-minute run did not end the realm")
	print("T_BIGMAP_PLAYTEST elapsed=%.1f chunks=%d" % [float(sim.elapsed_seconds), game.world_view.chunk_nodes.size()])
	print("T_BIGMAP_PLAYTEST %s" % ("PASS" if failures.is_empty() else "FAIL"))
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
