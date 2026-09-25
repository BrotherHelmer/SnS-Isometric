extends SceneTree

const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Tuning = preload("res://src/GodotClient/Scripts/one_shard_rivalry_tuning.gd")

var view
var capture_failures: Array[String] = []
var output_dir := "res://artifacts/demo_screenshots"


func _init() -> void:
	if DisplayServer.get_name() == "headless":
		print("DEMO_CAPTURE SKIP: a rendered display is required.")
		quit(0)
		return
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	var packed_scene: PackedScene = load("res://src/GodotClient/Scenes/main.tscn")
	view = packed_scene.instantiate()
	view.visible = false
	root.add_child(view)
	await process_frame
	view._start_new_demo()
	view.paused = false
	await process_frame
	_prepare_settlement()
	view.visible = true

	await _capture_scene("01_day_settlement.png")

	var workers: Array = view.simulation.get_workers()
	var cargo := [Defs.RESOURCE_WOOD, Defs.RESOURCE_STONE, Defs.RESOURCE_PLANKS, Defs.RESOURCE_BREAD]
	for index in range(mini(4, workers.size())):
		workers[index]["carried_resource"] = cargo[index]
		workers[index]["carried_amount"] = 4 + index
		workers[index]["position"] = view.simulation.town_hall_position + Vector2i(-4 + index * 2, 4)
		workers[index]["previous_position"] = workers[index]["position"]
	view.camera.zoom = Vector2(1.5, 1.5)
	view.pre_shard_zoom = 1.5
	view.simulation.last_message = "Settlers haul Wood, Stone, Planks, and Bread through the road network."
	view._update_ui()
	await _capture_scene("02_hauling_and_production.png")

	view.camera.zoom = Vector2(1.30, 1.30)
	view.pre_shard_zoom = 1.30
	view.simulation.phase_time = Simulation.DAY_LENGTH_SECONDS - 18.0
	view.simulation.last_message = "Dusk approaches — civilians are returning home."
	view._update_visual_modes(4.0)
	view._update_ui()
	await _capture_scene("03_sunset_warning.png")

	_prepare_night_defense()
	await _capture_scene("04_night_defense_roles.png")

	_prepare_claim_moment()
	await _capture_scene("05_shard_claim.png")

	if capture_failures.is_empty():
		print("DEMO_CAPTURE PASS: %s" % ProjectSettings.globalize_path(output_dir))
		quit(0)
	else:
		for failure in capture_failures:
			print("FAIL: %s" % failure)
		print("DEMO_CAPTURE FAIL (%d)" % capture_failures.size())
		quit(1)


func _prepare_settlement() -> void:
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
		_add_building(simulation, Defs.BUILDING_WATCHTOWER if x == town.x + 10 else Defs.BUILDING_WALL, Vector2i(x, town.y - 4))
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
	simulation.day_count = 2
	simulation.phase_time = 118.0
	simulation.last_message = "Your settlement is working. Extend roads before the next dusk."
	view.current_mode = "SELECT"
	view.selected_tile = Vector2i(-1, -1)
	view.selected_building_id = 0
	view.camera.position = view.tile_to_world(center) + Vector2(0, 28)
	view.camera.zoom = Vector2(1.30, 1.30)
	view.pre_shard_zoom = 1.30
	view._invalidate_revealed_tile_cache()
	view._refresh_static_world_if_needed(true)
	view._update_visual_modes(3.0)
	view._update_ui()


func _prepare_night_defense() -> void:
	var simulation = view.simulation
	simulation.is_night = true
	simulation.phase_time = 42.0
	var town: Vector2i = simulation.town_hall_position
	var roles := [
		Simulation.ENEMY_RAIDER,
		Simulation.ENEMY_SKITTERER,
		Simulation.ENEMY_BRUTE,
		Simulation.ENEMY_HEXER
	]
	for index in range(12):
		var origin := town + Vector2i(-7 + index % 6, -5 + int(index / 6))
		simulation._prepare_test_tile(origin, Defs.TILE_GRASS)
		simulation._reveal_radius(origin, 2)
		simulation._spawn_enemy(origin, 24, 10, 0.0, 0, roles[index % roles.size()])
	simulation.last_message = "Night assault — Skitterers rush workers, Brutes breach walls, Hexers drain Wyrd."
	view._invalidate_revealed_tile_cache()
	view._refresh_static_world_if_needed(true)
	view._update_visual_modes(4.0)
	view._update_ui()


func _prepare_claim_moment() -> void:
	var simulation = view.simulation
	simulation.enemies.clear()
	simulation.is_night = false
	simulation.phase_time = 326.0
	_configure_ready_claim(simulation, simulation.rivalry)
	var sovereign: Dictionary = simulation.rivalry.get_sovereign(Tuning.PLAYER_REALM)
	sovereign["position"] = Vector2(simulation.shard_position + Vector2i(-1, 1))
	sovereign["previous_position"] = sovereign["position"]
	simulation._reveal_radius(simulation.shard_position, 13)
	simulation.rivalry.request_begin_claim(Tuning.PLAYER_REALM)
	simulation.last_message = "Shard claim begun — hold the Outpost, Lumen, and Sovereign through the night."
	view.camera.position = view.tile_to_world(simulation.shard_position)
	view.camera.zoom = Vector2(1.38, 1.38)
	view.pre_shard_zoom = 1.38 / 1.10
	view._invalidate_revealed_tile_cache()
	view._refresh_static_world_if_needed(true)
	view._update_visual_modes(4.0)
	view._update_ui()


func _capture_scene(file_name: String) -> void:
	view.selected_tile = Vector2i(-1, -1)
	view.selected_building_id = 0
	view._refresh_static_world_if_needed(true)
	view.queue_redraw()
	for _frame in range(6):
		await process_frame
	var texture := root.get_texture()
	if texture == null:
		capture_failures.append("%s has no viewport texture" % file_name)
		return
	var image := texture.get_image()
	if image == null:
		capture_failures.append("%s has no readable image" % file_name)
		return
	var error := image.save_png("%s/%s" % [output_dir, file_name])
	if error != OK:
		capture_failures.append("%s could not be saved: %s" % [file_name, error_string(error)])
	else:
		print("CAPTURED %s" % file_name)


func _add_building(simulation, building_type: String, anchor: Vector2i) -> void:
	var footprint := Defs.building_footprint(building_type)
	var level: int = simulation.get_height(anchor)
	for y in range(footprint.y):
		for x in range(footprint.x):
			var tile := anchor + Vector2i(x, y)
			if simulation.is_inside_map(tile):
				simulation._prepare_test_tile(tile, Defs.TILE_GRASS)
				simulation.height_map[tile.y][tile.x] = level
	simulation._add_completed_building(building_type, anchor)


func _configure_ready_claim(simulation, rivalry) -> void:
	var realm: Dictionary = rivalry.realms[Tuning.PLAYER_REALM]
	var outpost_anchor: Vector2i = simulation.shard_position + Vector2i(-4, 0)
	var road_target: Vector2i = outpost_anchor + Vector2i.LEFT
	var current: Vector2i = realm["entrance"]
	while current.x != road_target.x:
		current += Vector2i(1 if road_target.x > current.x else -1, 0)
		realm["roads"][rivalry._key(current)] = true
	while current.y != road_target.y:
		current += Vector2i(0, 1 if road_target.y > current.y else -1)
		realm["roads"][rivalry._key(current)] = true
	for fraction in [0.34, 0.67]:
		var pillar_position := Vector2i(rivalry._home_center(Tuning.PLAYER_REALM).lerp(Vector2(simulation.shard_position), float(fraction)))
		var pillar := {
			"id": rivalry.next_structure_id,
			"realm_id": Tuning.PLAYER_REALM,
			"type": Tuning.STRUCTURE_LUMEN_PILLAR,
			"position": pillar_position,
			"footprint": Vector2i.ONE,
			"hp": 90,
			"max_hp": 90,
			"active": true,
			"connected": true,
			"damage_flash": 0.0
		}
		rivalry.next_structure_id += 1
		rivalry.structures.append(pillar)
		realm["structures"].append(pillar["id"])
	var outpost := {
		"id": rivalry.next_structure_id,
		"realm_id": Tuning.PLAYER_REALM,
		"type": Tuning.STRUCTURE_CLAIMANT_OUTPOST,
		"position": outpost_anchor,
		"footprint": Vector2i(2, 2),
		"hp": 220,
		"max_hp": 220,
		"active": true,
		"connected": true,
		"damage_flash": 0.0
	}
	rivalry.next_structure_id += 1
	rivalry.structures.append(outpost)
	realm["structures"].append(outpost["id"])
	realm["claim"]["outpost_id"] = outpost["id"]
	rivalry.get_resources(Tuning.PLAYER_REALM)[Defs.RESOURCE_WYRD] = 100
