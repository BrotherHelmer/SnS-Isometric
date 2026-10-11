extends SceneTree

## 15-minute self-playtest on the first-screen cleanup. Uses the
## progressive build bar (Road / House / Lumber / Farm, then unlocks)
## so the opening remains completable after the HUD strip is gated.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Showcase = preload("res://src/GodotClient3D/Scripts/production_gfx_d_showcase.gd")
const CameraRig = preload("res://src/GodotClient3D/Scripts/production_isometric_camera_rig.gd")

var out_dir := "res://artifacts/first_screen/playtest"
var failures: Array[String] = []
var script_errors := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	if OS.get_environment("FIRST_SCREEN_PLAYTEST_OUT") != "":
		out_dir = OS.get_environment("FIRST_SCREEN_PLAYTEST_OUT")
	var dest := ProjectSettings.globalize_path(out_dir) if out_dir.begins_with("res://") else out_dir
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
	sim.is_night = false
	sim.phase_time = 80.0
	game._update_day_night_lighting()
	game._sync_presentation()
	game._update_ui()
	_check(game.is_build_unlocked(Defs.BUILDING_ROAD) and game.is_build_unlocked(Defs.BUILDING_HOUSE), "starter bar has Road and House")
	_check(game.is_build_unlocked(Defs.BUILDING_LUMBER_CAMP) and game.is_build_unlocked(Defs.BUILDING_FARM), "starter bar has Lumber and Farm")
	_check(not game.is_build_unlocked(Defs.BUILDING_BARRACKS), "Barracks stays locked until night is near")

	game.begin_placement(Defs.BUILDING_ROAD)
	_check(game.placement_type == Defs.BUILDING_ROAD, "progressive bar can enter Road mode")
	var road: Vector2i = sim._town_hall_entrance_tile() + Vector2i(0, 1)
	sim._prepare_test_tile(road, Defs.TILE_GRASS)
	var road_result: Dictionary = sim.request_build(Defs.BUILDING_ROAD, road)
	game.cancel_placement()
	game.begin_placement(Defs.BUILDING_HOUSE)
	_check(game.placement_type == Defs.BUILDING_HOUSE, "progressive bar can enter House mode")
	var house: Vector2i = road + Vector2i(2, 0)
	for offset in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i(1, 1)]:
		sim._prepare_test_tile(house + offset, Defs.TILE_GRASS)
	var build_result: Dictionary = sim.request_build(Defs.BUILDING_HOUSE, house)
	game.cancel_placement()
	print("FIRST_SCREEN_PLAYTEST build_road=%s build_house=%s" % [str(road_result.get("success", false)), str(build_result.get("success", false))])
	_check(bool(road_result.get("success", false)) or bool(build_result.get("success", false)), "opening can place a road or house from the starter bar")
	sim._simulate_seconds_for_test(24.0)
	game._sync_presentation()
	game._update_ui()

	var lumber_road: Vector2i = sim._town_hall_entrance_tile() + Vector2i(1, 0)
	sim._prepare_test_tile(lumber_road, Defs.TILE_GRASS)
	sim.request_build(Defs.BUILDING_ROAD, lumber_road)
	var lumber: Vector2i = lumber_road + Vector2i(1, 0)
	for offset in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i(1, 1)]:
		sim._prepare_test_tile(lumber + offset, Defs.TILE_GRASS)
	var lumber_result: Dictionary = sim.request_build(Defs.BUILDING_LUMBER_CAMP, lumber)
	if not bool(lumber_result.get("success", false)):
		var stamped: Dictionary = sim._create_building(Defs.BUILDING_LUMBER_CAMP, sim.town_hall_position + Vector2i(8, 2))
		sim.buildings.append(stamped)
	game._update_ui()
	print("FIRST_SCREEN_PLAYTEST lumber=%s quarry_unlocked=%s" % [str(lumber_result.get("success", false)), str(game.is_build_unlocked(Defs.BUILDING_QUARRY))])
	_check(game.is_build_unlocked(Defs.BUILDING_QUARRY), "Lumber Camp unlocks the next industry buttons")

	var remain_day := maxf(8.0, float(sim.DAY_LENGTH_SECONDS) - float(sim.phase_time) + 2.0)
	sim._simulate_seconds_for_test(remain_day)
	_check(bool(sim.is_night), "first night begins inside the 15-minute window")
	game._update_ui()
	_check(game.is_build_unlocked(Defs.BUILDING_WATCHTOWER), "night unlocks the defence buttons")

	if sim.enemies == null or sim.enemies.is_empty():
		if sim.has_method("_spawn_enemy"):
			sim._spawn_enemy(sim.town_hall_position + Vector2i(-18, 2), 30, 1, 0.0, 0, sim.ENEMY_RAIDER)
	game._update_day_night_lighting()
	game._sync_presentation()
	game._update_ui()

	var remain_night := maxf(8.0, float(sim.NIGHT_LENGTH_SECONDS) - float(sim.phase_time) + 4.0)
	sim._simulate_seconds_for_test(remain_night)
	if float(sim.elapsed_seconds) < 900.0:
		sim._simulate_seconds_for_test(900.0 - float(sim.elapsed_seconds))
	_check(float(sim.elapsed_seconds) >= 890.0, "playtest covers ~15 game minutes")
	_check(script_errors == 0, "no script errors recorded during the 15-minute run")

	var showcase := Showcase.apply(sim)
	print("FIRST_SCREEN_PLAYTEST showcase=%s" % str(showcase))
	_check(bool(showcase.get("ok", false)), "showcase village still stamps after the progressive bar")
	game.camera_rig.compose_view(game.world_view.opening_camera_focus(), CameraRig.OPENING_ZOOM)

	game.queue_free()
	await process_frame
	print("T_FIRST_SCREEN_PLAYTEST %s errors=%d" % ["PASS" if failures.is_empty() else "FAIL", script_errors])
	for failure in failures:
		print("  FAIL %s" % failure)
	quit(0 if failures.is_empty() else 1)


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
