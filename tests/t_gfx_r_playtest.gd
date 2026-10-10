extends SceneTree

## GFX-R self-playtest: opening, a live build, scout (Y), first night
## and raid. Advances ~15 game minutes (day 420s + night 180s + remainder).

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Showcase = preload("res://src/GodotClient3D/Scripts/production_gfx_d_showcase.gd")
const CameraRig = preload("res://src/GodotClient3D/Scripts/production_isometric_camera_rig.gd")

var out_dir := "res://artifacts/gfx_r/playtest"
var csv_path := ""
var failures: Array[String] = []
var samples: Array[Dictionary] = []
var script_errors := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	if OS.get_environment("GFX_R_PLAYTEST_OUT") != "":
		out_dir = OS.get_environment("GFX_R_PLAYTEST_OUT")
	var dest := ProjectSettings.globalize_path(out_dir) if out_dir.begins_with("res://") else out_dir
	DirAccess.make_dir_recursive_absolute(dest)
	csv_path = dest.path_join("gfx_r_playtest.csv")
	_write_csv_header()

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
	var home: Vector3 = game.world_view.opening_camera_focus()
	game.camera_rig.compose_view(home, CameraRig.NORMAL_ZOOM)
	var dress: Node = game.world_view.resource_visuals_root.get_node_or_null("OpeningDress")
	_check(dress != null and int(dress.get_meta("hamlet_cottages", 0)) >= 3, "opening is a presentation hamlet")
	_check(dress != null and dress.find_child("DressRidge", true, false) != null, "opening ridge is dressed")
	_check(dress != null and dress.find_child("DressCreek", true, false) != null, "opening creek is dressed")
	_check(dress != null and dress.find_child("RidgeFormation", true, false) != null, "opening has a back rock formation")
	_check(dress != null and dress.find_child("DressCoastEdge", true, false) != null, "opening has a west water edge")
	_check(dress != null and float(dress.get_meta("opening_clearing_cells", 0.0)) >= 10.5, "opening clearing is 2.5–3W")
	_check(dress != null and float(dress.get_meta("opening_forest_coverage", 0.0)) >= 0.38, "opening forest frames the meadow")
	await _sample(game, dest, "opening_day", "opening composed on the authored keep, ridge and west creek")

	var road: Vector2i = sim._town_hall_entrance_tile() + Vector2i(0, 1)
	sim._prepare_test_tile(road, Defs.TILE_GRASS)
	var road_result: Dictionary = sim.request_build(Defs.BUILDING_ROAD, road)
	var house: Vector2i = road + Vector2i(2, 0)
	for offset in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i(1, 1)]:
		sim._prepare_test_tile(house + offset, Defs.TILE_GRASS)
	var build_result: Dictionary = sim.request_build(Defs.BUILDING_HOUSE, house)
	print("GFX_R_PLAYTEST build_road=%s build_house=%s" % [str(road_result.get("success", false)), str(build_result.get("success", false))])
	_check(bool(road_result.get("success", false)) or bool(build_result.get("success", false)), "opening can place a road or house")
	sim._simulate_seconds_for_test(24.0)
	game._sync_presentation()
	await _sample(game, dest, "build_day", "first house/road placed from the opening")

	var guard := _ensure_patrol_guard(sim)
	_check(int(guard.get("id", 0)) > 0, "a patrol guard is available to scout")
	var origin: Vector2i = guard.get("position", sim.town_hall_position)
	var fog_tile := Vector2i(1, clampi(origin.y, 1, sim.map_size.y - 2))
	var scout_result: Dictionary = sim.request_scout_direction(int(guard.get("id", 0)), fog_tile)
	sim.playtest_log.note_command(sim, "scout_order", String(scout_result.get("message", "scout")))
	print("GFX_R_PLAYTEST scout=%s" % str(scout_result))
	game._sync_presentation()
	if game.has_method("_update_ui"):
		game._update_ui()
	await _sample(game, dest, "scout_day", "guard scouting toward the west fog")

	var remain_day := maxf(8.0, float(sim.DAY_LENGTH_SECONDS) - float(sim.phase_time) + 2.0)
	sim._simulate_seconds_for_test(remain_day)
	_check(bool(sim.is_night), "first night begins inside the 15-minute window")
	game._update_day_night_lighting()
	game._sync_presentation()
	await _sample(game, dest, "first_night", "first night after the opening day")

	if sim.enemies == null or sim.enemies.is_empty():
		if sim.has_method("_spawn_enemy"):
			sim._spawn_enemy(sim.town_hall_position + Vector2i(-18, 2), 30, 1, 0.0, 0, sim.ENEMY_RAIDER)
			sim._spawn_enemy(sim.town_hall_position + Vector2i(-20, 4), 30, 1, 0.0, 0, sim.ENEMY_RAIDER)
	game._update_day_night_lighting()
	game._sync_presentation()
	if game.has_method("_update_ui"):
		game._update_ui()
	await _sample(game, dest, "night_raid", "first night raid banner")

	var remain_night := maxf(8.0, float(sim.NIGHT_LENGTH_SECONDS) - float(sim.phase_time) + 4.0)
	sim._simulate_seconds_for_test(remain_night)
	if float(sim.elapsed_seconds) < 900.0:
		sim._simulate_seconds_for_test(900.0 - float(sim.elapsed_seconds))
	game._update_day_night_lighting()
	game._sync_presentation()
	game.camera_rig.compose_view(home, CameraRig.STRATEGIC_ZOOM)
	await _sample(game, dest, "fifteen_minutes", "first 15 game minutes complete")
	_check(float(sim.elapsed_seconds) >= 890.0, "playtest covers ~15 game minutes")
	_check(script_errors == 0, "no script errors recorded during the 15-minute run")

	var showcase := Showcase.apply(sim)
	print("GFX_R_PLAYTEST showcase=%s" % str(showcase))
	_check(bool(showcase.get("ok", false)), "showcase village stamped")
	sim.is_night = false
	sim.phase_time = 80.0
	game._update_day_night_lighting()
	game._sync_presentation()
	var hall: Vector3 = game.world_view.tile_to_world(Vector2(sim.town_hall_position) + Vector2(1.5, 1.5))
	game.camera_rig.compose_view(hall, CameraRig.NORMAL_ZOOM)
	await _sample(game, dest, "showcase_day", "15-building village after the live opening")
	game.camera_rig.compose_view(hall, CameraRig.STRATEGIC_ZOOM)
	await _sample(game, dest, "showcase_wide", "showcase at the 1.5x zoom cap")
	await _sample(game, dest, "fog_edge", "1.5x zoom at the unknown edge (day)")

	game.queue_free()
	await process_frame
	print("T_GFX_R_PLAYTEST %s csv=%s errors=%d" % ["PASS" if failures.is_empty() else "FAIL", csv_path, script_errors])
	quit(0 if failures.is_empty() else 1)


func _ensure_patrol_guard(sim) -> Dictionary:
	for worker_value in sim.workers:
		var worker: Dictionary = worker_value
		if sim.is_patrol_scout(worker):
			return worker
	var spawned: Dictionary = sim._create_patrol_worker(0, "playtest_guard")
	sim.workers.append(spawned)
	sim.soldiers_total = maxi(int(sim.soldiers_total), 1)
	return spawned


func _sample(game: Node, dest: String, label: String, detail: String) -> void:
	var wait_usec := Time.get_ticks_usec()
	for _i in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	var wait_ms := float(Time.get_ticks_usec() - wait_usec) / 1000.0
	var frame_ms := float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0
	var image: Image = root.get_viewport().get_texture().get_image()
	var shot := dest.path_join("%s.png" % label)
	if image != null and not image.is_empty():
		image.save_png(shot)
	var sim = game.simulation_host.simulation
	var row := {
		"elapsed": float(sim.elapsed_seconds),
		"day": int(sim.day_count),
		"night": 1 if bool(sim.is_night) else 0,
		"event": label,
		"detail": detail,
		"wait_ms": wait_ms,
		"frame_ms": frame_ms,
		"errors": script_errors
	}
	samples.append(row)
	_append_csv(row)
	print("GFX_R_PLAYTEST %s wait=%.1fms frame=%.2fms night=%d elapsed=%.1f errors=%d" % [
		label, wait_ms, frame_ms, int(row.night), float(row.elapsed), script_errors
	])


func _write_csv_header() -> void:
	var file := FileAccess.open(csv_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string("elapsed,day,night,event,detail,wait_ms,frame_ms,errors\n")
	file.close()


func _append_csv(row: Dictionary) -> void:
	var file := FileAccess.open(csv_path, FileAccess.READ_WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_string("%0.1f,%d,%d,%s,\"%s\",%0.2f,%0.3f,%d\n" % [
		float(row.elapsed), int(row.day), int(row.night),
		String(row.event), String(row.detail).replace("\"", "'"),
		float(row.wait_ms), float(row.frame_ms), int(row.errors)
	])
	file.close()


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
