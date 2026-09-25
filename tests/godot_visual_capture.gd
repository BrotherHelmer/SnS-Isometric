extends SceneTree

const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")


func _init() -> void:
	if DisplayServer.get_name() == "headless":
		print("VISUAL_CAPTURE SKIP: the headless display driver has no readable framebuffer.")
		quit(0)
		return
	call_deferred("_prepare_and_capture")


func _prepare_and_capture() -> void:
	print("VISUAL fixture: loading")
	var packed_scene: PackedScene = load("res://src/GodotClient/Scenes/main.tscn")
	var view = packed_scene.instantiate()
	view.visible = false
	root.add_child(view)
	await process_frame
	view._start_new_demo()
	await process_frame
	view.paused = true
	print("VISUAL fixture: scene ready")

	var simulation = view.simulation
	simulation.diagnostics_enabled = false
	simulation.start_new_run(70, 70, 707070, true)
	simulation.population_current = 24
	simulation.housing_capacity = 30
	simulation.central_inventory[Defs.RESOURCE_WOOD] = 48
	simulation.central_inventory[Defs.RESOURCE_PLANKS] = 32
	simulation.central_inventory[Defs.RESOURCE_STONE] = 46
	simulation.central_inventory[Defs.RESOURCE_WHEAT] = 24
	simulation.central_inventory[Defs.RESOURCE_BREAD] = 24
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

	for offset in simulation._radius_offsets(5):
		var tree_tile: Vector2i = town + Vector2i(-10, 7) + offset
		if simulation.is_inside_map(tree_tile) and simulation.get_tile(tree_tile) == Defs.TILE_GRASS and not simulation.is_tile_occupied(tree_tile):
			simulation._set_tile(tree_tile, Defs.TILE_TREE)
			simulation.tree_deposits[simulation._tile_key(tree_tile)] = 24
	for offset in simulation._radius_offsets(3):
		var rock_tile: Vector2i = town + Vector2i(3, -10) + offset
		if simulation.is_inside_map(rock_tile) and simulation.get_tile(rock_tile) == Defs.TILE_GRASS and not simulation.is_tile_occupied(rock_tile):
			simulation._set_tile(rock_tile, Defs.TILE_ROCK)
			simulation.rock_deposits[simulation._tile_key(rock_tile)] = 32

	simulation._rebuild_occupied_tiles()
	simulation._recompute_road_network()
	for building in simulation.buildings:
		building["connected"] = true
	simulation._reveal_radius(center, 22)
	simulation._auto_staff_unstaffed_buildings()
	simulation._sync_production_workers()
	print("VISUAL fixture: settlement ready")
	view._invalidate_revealed_tile_cache()
	view._refresh_static_world_if_needed(true)
	view.cached_map_bounds = Rect2()
	view.camera.position = view.tile_to_world(center) + Vector2(0, 30)
	view.camera.zoom = Vector2(1.36, 1.36)
	view.pre_shard_zoom = 1.36
	view.visible = true

	view.selected_tile = town + Vector2i(6, 0)
	view._update_selected_building_id()
	view._update_ui()
	view.queue_redraw()
	for _frame in range(3):
		await process_frame
	print("VISUAL fixture: day rendered")
	var day_result := _save_viewport_capture("res://docs/design/current_gameplay_capture.png")

	simulation.central_inventory[Defs.RESOURCE_BREAD] = 2
	simulation.central_inventory[Defs.RESOURCE_WHEAT] = 0
	simulation.is_night = true
	simulation.phase_time = 12.0
	simulation.hungry_population = simulation.population_current - 2
	simulation._refresh_worker_hunger_flags()
	view._update_ui()
	view._update_visual_modes(3.0)
	view.queue_redraw()
	for _frame in range(3):
		await process_frame
	print("VISUAL fixture: night rendered")
	var night_result := _save_viewport_capture("res://docs/design/current_night_capture.png")

	simulation.is_night = false
	simulation.hunger_penalty_remaining = simulation.DAY_LENGTH_SECONDS * simulation.HUNGER_RECOVERY_FRACTION
	view._update_ui()
	view.queue_redraw()
	for _frame in range(3):
		await process_frame
	print("VISUAL fixture: hunger rendered")
	var hunger_result := _save_viewport_capture("res://docs/design/current_hunger_capture.png")

	view._toggle_event_log()
	for _frame in range(3):
		await process_frame
	var log_result := _save_viewport_capture("res://docs/design/current_log_capture.png")
	var passed := day_result == OK and night_result == OK and hunger_result == OK and log_result == OK
	print("VISUAL_CAPTURE %s" % ("PASS" if passed else "FAIL"))
	quit(0 if passed else 1)


func _save_viewport_capture(path: String) -> Error:
	if DisplayServer.get_name() == "headless":
		push_warning("VISUAL capture unavailable: the headless display driver has no readable framebuffer.")
		return ERR_UNAVAILABLE
	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		push_warning("VISUAL capture unavailable: the active renderer exposes no viewport texture.")
		return ERR_UNAVAILABLE
	var image := viewport_texture.get_image()
	if image == null:
		push_warning("VISUAL capture unavailable: the viewport texture exposes no readable image.")
		return ERR_UNAVAILABLE
	return image.save_png(path)


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
