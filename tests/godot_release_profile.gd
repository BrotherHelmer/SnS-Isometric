extends SceneTree

const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")

var started_usec := 0
var view


func _init() -> void:
	if DisplayServer.get_name() == "headless":
		print("RELEASE_PROFILE SKIP: a rendered display is required.")
		quit(0)
		return
	started_usec = Time.get_ticks_usec()
	call_deferred("_run_profile")


func _run_profile() -> void:
	var packed_scene: PackedScene = load("res://src/GodotClient/Scenes/main.tscn")
	view = packed_scene.instantiate()
	root.add_child(view)
	await process_frame
	await process_frame
	var startup_ms := float(Time.get_ticks_usec() - started_usec) / 1000.0

	view._start_new_demo()
	view.simulation.diagnostics_enabled = false
	await process_frame
	var results := {
		"engine": Engine.get_version_info().get("string", "unknown"),
		"renderer": RenderingServer.get_video_adapter_name(),
		"cpu_threads": OS.get_processor_count(),
		"startup_ms": startup_ms,
		"opening": await _sample("opening", 180)
	}

	_prepare_busy_settlement()
	results["busy_day"] = await _sample("busy_day", 240)
	_prepare_night_attack()
	results["night_attack"] = await _sample("night_attack", 240)
	print("RELEASE_PROFILE_JSON %s" % JSON.stringify(results))
	quit(0)


func _sample(label: String, frame_count: int) -> Dictionary:
	var simulation = view.simulation
	var start_usec := Time.get_ticks_usec()
	var start_paths: int = simulation.path_query_count
	var start_rebuilds: int = simulation.path_grid_rebuild_count
	var start_draws: int = view.render_pass_count
	var start_ui: int = view.ui_update_count
	var process_seconds := 0.0
	var physics_seconds := 0.0
	var draw_calls := 0.0
	var max_draw_calls := 0.0
	var max_nodes := 0
	for _frame in range(frame_count):
		await process_frame
		process_seconds += Performance.get_monitor(Performance.TIME_PROCESS)
		physics_seconds += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
		var frame_draw_calls := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		draw_calls += frame_draw_calls
		max_draw_calls = maxf(max_draw_calls, frame_draw_calls)
		max_nodes = maxi(max_nodes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	var elapsed_seconds := float(Time.get_ticks_usec() - start_usec) / 1000000.0
	var agents: int = simulation.workers.size() + simulation.enemies.size()
	if simulation.rivalry != null:
		agents += simulation.rivalry.get_workers().size() + 2
	return {
		"label": label,
		"frames": frame_count,
		"elapsed_seconds": snappedf(elapsed_seconds, 0.001),
		"fps": snappedf(float(frame_count) / maxf(elapsed_seconds, 0.001), 0.1),
		"frame_ms": snappedf(elapsed_seconds * 1000.0 / float(frame_count), 0.01),
		"avg_process_ms": snappedf(process_seconds * 1000.0 / float(frame_count), 0.001),
		"avg_physics_ms": snappedf(physics_seconds * 1000.0 / float(frame_count), 0.001),
		"avg_draw_calls": roundi(draw_calls / float(frame_count)),
		"max_draw_calls": roundi(max_draw_calls),
		"node_count": max_nodes,
		"visible_agents": agents,
		"path_queries": simulation.path_query_count - start_paths,
		"path_grid_rebuilds": simulation.path_grid_rebuild_count - start_rebuilds,
		"render_passes": view.render_pass_count - start_draws,
		"ui_updates": view.ui_update_count - start_ui
	}


func _prepare_busy_settlement() -> void:
	var simulation = view.simulation
	simulation.start_new_run(70, 70, 707070, true)
	simulation.diagnostics_enabled = false
	simulation.population_current = 24
	simulation.housing_capacity = 30
	simulation.central_inventory[Defs.RESOURCE_WOOD] = 54
	simulation.central_inventory[Defs.RESOURCE_PLANKS] = 34
	simulation.central_inventory[Defs.RESOURCE_STONE] = 48
	simulation.central_inventory[Defs.RESOURCE_WHEAT] = 22
	simulation.central_inventory[Defs.RESOURCE_BREAD] = 28
	simulation.soldiers_total = 3
	var town: Vector2i = simulation.town_hall_position
	var center: Vector2i = simulation._footprint_center(town, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	simulation._clear_area(center, 17)
	simulation._flatten_area(center, 12)
	for x in range(town.x - 8, town.x + 15):
		_add_building(simulation, Defs.BUILDING_ROAD, Vector2i(x, town.y + 4))
	for y in range(town.y - 8, town.y + 14):
		_add_building(simulation, Defs.BUILDING_ROAD, Vector2i(town.x + 4, y))
	for x in range(town.x + 5, town.x + 14):
		var type := Defs.BUILDING_WATCHTOWER if x == town.x + 10 else Defs.BUILDING_WALL
		_add_building(simulation, type, Vector2i(x, town.y - 4))
	_add_building(simulation, Defs.BUILDING_HOUSE, town + Vector2i(-5, 0))
	_add_building(simulation, Defs.BUILDING_HOUSE, town + Vector2i(-5, 3))
	_add_building(simulation, Defs.BUILDING_STOREHOUSE, town + Vector2i(6, 0))
	_add_building(simulation, Defs.BUILDING_LUMBER_CAMP, town + Vector2i(-7, 6))
	_add_building(simulation, Defs.BUILDING_SAWMILL, town + Vector2i(-3, 6))
	_add_building(simulation, Defs.BUILDING_FARM, town + Vector2i(1, 6))
	_add_building(simulation, Defs.BUILDING_BARRACKS, town + Vector2i(6, 6))
	_add_building(simulation, Defs.BUILDING_BAKERY, town + Vector2i(6, -8))
	_add_building(simulation, Defs.BUILDING_QUARRY, town + Vector2i(1, -8))
	simulation._rebuild_occupied_tiles()
	simulation._recompute_road_network()
	for building in simulation.buildings:
		building["connected"] = true
	simulation._reveal_radius(center, 22)
	simulation._auto_staff_unstaffed_buildings()
	simulation._sync_production_workers()
	view._invalidate_revealed_tile_cache()
	view.camera.position = view.tile_to_world(center) + Vector2(0, 28)
	view.camera.zoom = Vector2(1.30, 1.30)
	view.pre_shard_zoom = 1.30
	view.current_mode = "SELECT"
	view.selected_tile = Vector2i(-1, -1)
	view._update_ui()
	view.queue_redraw()


func _prepare_night_attack() -> void:
	var simulation = view.simulation
	simulation.is_night = true
	simulation.phase_time = 28.0
	var town: Vector2i = simulation.town_hall_position
	var roles := [
		Simulation.ENEMY_RAIDER,
		Simulation.ENEMY_SKITTERER,
		Simulation.ENEMY_BRUTE,
		Simulation.ENEMY_HEXER
	]
	for index in range(14):
		var origin: Vector2i = town + Vector2i(-9 + index % 7, -5 + int(index / 7))
		simulation._prepare_test_tile(origin, Defs.TILE_GRASS)
		simulation._reveal_radius(origin, 2)
		simulation._spawn_enemy(origin, 24, 10, -0.03 * float(index), 0, roles[index % roles.size()])
	view._invalidate_revealed_tile_cache()
	view._update_visual_modes(3.0)
	view._update_ui()
	view.queue_redraw()


func _add_building(simulation, building_type: String, anchor: Vector2i) -> void:
	var footprint := Defs.building_footprint(building_type)
	var level: int = simulation.get_height(anchor)
	for y in range(footprint.y):
		for x in range(footprint.x):
			var tile := anchor + Vector2i(x, y)
			if not simulation.is_inside_map(tile):
				continue
			simulation._prepare_test_tile(tile, Defs.TILE_GRASS)
			simulation.height_map[tile.y][tile.x] = level
	simulation._add_completed_building(building_type, anchor)
