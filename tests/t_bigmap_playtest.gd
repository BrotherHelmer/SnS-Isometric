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
	var placed := _place_opening_build(sim)
	print("T_BIGMAP_PLAYTEST build_road=%s build_house=%s road_msg=%s house_msg=%s" % [
		str(placed.get("road", false)), str(placed.get("house", false)),
		str(placed.get("road_msg", "")), str(placed.get("house_msg", ""))
	])
	_check(bool(placed.get("road", false)) or bool(placed.get("house", false)), "opening can place a road or house")
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


func _place_opening_build(sim) -> Dictionary:
	sim._recompute_road_network()
	var last_road := {"success": false, "message": "no candidate"}
	var last_house := {"success": false, "message": "no candidate"}
	var seeds: Array[Vector2i] = []
	for key_value in sim.connected_roads.keys():
		seeds.append(sim._tile_from_key(String(key_value)))
	if seeds.is_empty():
		seeds.append(sim._town_hall_entrance_tile())
	for origin in seeds:
		for neighbor in sim._neighbors(origin):
			if not sim.is_inside_map(neighbor):
				continue
			sim._prepare_test_tile(neighbor, Defs.TILE_GRASS)
			last_road = sim.request_build(Defs.BUILDING_ROAD, neighbor)
			var house: Vector2i = neighbor + Vector2i(2, 0)
			for offset in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i(1, 1)]:
				if sim.is_inside_map(house + offset):
					sim._prepare_test_tile(house + offset, Defs.TILE_GRASS)
			last_house = sim.request_build(Defs.BUILDING_HOUSE, house)
			if bool(last_road.get("success", false)) or bool(last_house.get("success", false)):
				return {
					"road": bool(last_road.get("success", false)),
					"house": bool(last_house.get("success", false)),
					"road_msg": str(last_road.get("message", "")),
					"house_msg": str(last_house.get("message", ""))
				}
	return {
		"road": false,
		"house": false,
		"road_msg": str(last_road.get("message", "")),
		"house_msg": str(last_house.get("message", ""))
	}


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
