extends SceneTree

const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Tuning = preload("res://src/GodotClient/Scripts/one_shard_rivalry_tuning.gd")

var failures: Array[String] = []


func _init() -> void:
	if DisplayServer.get_name() == "headless":
		print("DEMO_PLAYTHROUGH SKIP: a rendered display is required.")
		quit(0)
		return
	call_deferred("_run")


func _run() -> void:
	var packed_scene: PackedScene = load("res://src/GodotClient/Scenes/main.tscn")
	var view = packed_scene.instantiate()
	root.add_child(view)
	await process_frame
	await process_frame
	_check(view.main_menu_root.visible, "rendered match begins at the release menu")

	view._start_new_demo()
	await process_frame
	_check(view.game_started and not view.main_menu_root.visible, "Play Demo enters the founding scene")
	_check(not view.simulation.is_town_hall_founded(), "new match begins with the Town Hall founding choice")

	var simulation = view.simulation
	simulation.start_new_run(70, 70, 818181, true)
	simulation.diagnostics_enabled = false
	simulation.population_current = 12
	simulation.housing_capacity = 16
	simulation.central_inventory[Defs.RESOURCE_WOOD] = 80
	simulation.central_inventory[Defs.RESOURCE_PLANKS] = 48
	simulation.central_inventory[Defs.RESOURCE_STONE] = 64
	simulation.central_inventory[Defs.RESOURCE_BREAD] = 36
	var town: Vector2i = simulation.town_hall_position
	var center: Vector2i = simulation._footprint_center(town, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	simulation._clear_area(center, 12)
	simulation._flatten_area(center, 10)
	for x in range(town.x - 7, town.x + 11):
		_add_building(simulation, Defs.BUILDING_ROAD, Vector2i(x, town.y + 4))
	_add_building(simulation, Defs.BUILDING_HOUSE, town + Vector2i(-5, 0))
	_add_building(simulation, Defs.BUILDING_LUMBER_CAMP, town + Vector2i(-6, 5))
	_add_building(simulation, Defs.BUILDING_STOREHOUSE, town + Vector2i(5, 0))
	_add_building(simulation, Defs.BUILDING_WATCHTOWER, town + Vector2i(6, -3))
	for x in range(town.x + 3, town.x + 10):
		_add_building(simulation, Defs.BUILDING_WALL, Vector2i(x, town.y - 3))
	simulation._rebuild_occupied_tiles()
	simulation._recompute_road_network()
	simulation._reveal_radius(center, 18)
	simulation._auto_staff_unstaffed_buildings()
	simulation._sync_production_workers()
	view.camera.position = view.tile_to_world(center)
	view.camera.zoom = Vector2(1.3, 1.3)
	view.pre_shard_zoom = 1.3
	view._invalidate_revealed_tile_cache()
	view._refresh_static_world_if_needed(true)
	view._update_ui()
	await process_frame
	_check(simulation.is_town_hall_founded() and simulation.buildings.size() > 5, "the settlement phase renders with logistics and defenses")

	simulation.day_count = 2
	simulation.is_night = true
	simulation.phase_time = 12.0
	var roles := [
		Simulation.ENEMY_RAIDER,
		Simulation.ENEMY_SKITTERER,
		Simulation.ENEMY_BRUTE,
		Simulation.ENEMY_HEXER
	]
	for index in range(8):
		var origin := town + Vector2i(-7 + index, -5)
		simulation._prepare_test_tile(origin, Defs.TILE_GRASS)
		simulation._reveal_radius(origin, 1)
		simulation._spawn_enemy(origin, 24, 10, 0.0, 0, roles[index % roles.size()])
	view._update_visual_modes(3.0)
	view._refresh_static_world_if_needed(true)
	view._update_ui()
	await process_frame
	_check(simulation.enemies.size() == 8, "a rendered second-night defense contains the four enemy roles")

	simulation.enemies.clear()
	simulation.is_night = false
	simulation.phase_time = 60.0
	_configure_ready_claim(simulation, simulation.rivalry)
	var player_sovereign: Dictionary = simulation.rivalry.get_sovereign(Tuning.PLAYER_REALM)
	player_sovereign["position"] = Vector2(simulation.shard_position)
	player_sovereign["previous_position"] = player_sovereign["position"]
	simulation._reveal_radius(simulation.shard_position, 10)
	var claim_result: Dictionary = simulation.rivalry.request_begin_claim(Tuning.PLAYER_REALM)
	_check(bool(claim_result.get("success", false)), "the live realm begins a valid Shard claim")

	simulation.is_night = true
	simulation.phase_time = 0.0
	simulation.rivalry._on_night_started()
	simulation.rivalry._update_claims(
		Simulation.NIGHT_LENGTH_SECONDS,
		true,
		Simulation.NIGHT_LENGTH_SECONDS,
		Simulation.NIGHT_LENGTH_SECONDS
	)
	simulation.rivalry._on_dawn(Simulation.NIGHT_LENGTH_SECONDS)
	view._update_summary_panel()
	view._update_ui()
	await process_frame
	await process_frame
	_check(simulation.game_finished and simulation.victory, "holding the claim through dawn completes the full match")
	_check(view.summary_panel.visible, "the rendered victory summary is presented")

	if failures.is_empty():
		print("DEMO_PLAYTHROUGH PASS")
		quit(0)
	else:
		for failure in failures:
			print("FAIL: %s" % failure)
		print("DEMO_PLAYTHROUGH FAIL (%d)" % failures.size())
		quit(1)


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
	var entrance: Vector2i = realm["entrance"]
	var outpost_anchor: Vector2i = simulation.shard_position + Vector2i(-4, 0)
	var road_target: Vector2i = outpost_anchor + Vector2i.LEFT
	var current: Vector2i = entrance
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


func _check(condition: bool, label: String) -> void:
	print("%s %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		failures.append(label)
