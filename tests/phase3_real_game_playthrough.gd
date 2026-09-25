extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Fixture = preload("res://src/GodotClient3D/Scripts/production_demo_fixture.gd")

const SAVE_PATH := "res://artifacts/phase3/persistence/real_game_playthrough.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/phase3/persistence"))
	var failures: Array[String] = []
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var start_button: Button = game.startup_overlay.find_child("NewReviewSeed", true, false)
	start_button.pressed.emit()
	await process_frame
	var simulation = game.simulation_host.simulation
	var initial_resources: Dictionary = simulation.get_resources()
	var fixture := Fixture.new()
	print("REAL_PLAY_STEP 01 New Settlement seed=%d resources=%s" % [simulation.rng_seed, initial_resources])
	_check(failures, simulation.rng_seed == game.DEFAULT_SEED and simulation.population_current == 2, "start a new production 3D settlement through the actual menu")

	var first_road: Vector2i = fixture._best_road_extension(simulation, simulation.town_hall_position + Vector2i(5, 6))
	var road_result: Dictionary = simulation.request_build(Defs.BUILDING_ROAD, first_road)
	var first_road_id := int(Dictionary(road_result.get("building", {})).get("id", 0))
	var road_complete := bool(road_result.get("success", false)) and fixture._advance_until_complete(simulation, first_road_id, 800)
	_check(failures, road_complete, "build the first road through authoritative placement and economy")
	fixture._build_road_spine(simulation, 20)
	_check(failures, fixture.report.is_empty(), "extend the real road network to support a playable settlement layout")
	print("REAL_PLAY_STEP 02 Road anchor=%s" % first_road)

	var house_id := _build_real(failures, fixture, simulation, Defs.BUILDING_HOUSE, simulation.town_hall_position + Vector2i(5, 5))
	_check(failures, house_id > 0 and simulation.housing_capacity >= 10, "build housing and increase real capacity")
	print("REAL_PLAY_STEP 03 House id=%d housing=%d" % [house_id, simulation.housing_capacity])

	var lumber_id := _build_real(failures, fixture, simulation, Defs.BUILDING_LUMBER_CAMP, simulation.town_hall_position + Vector2i(9, 6))
	var lumber_output := _wait_for_output(simulation, lumber_id, Defs.RESOURCE_WOOD, 1800)
	_check(failures, lumber_id > 0 and lumber_output, "build a Lumber Camp and observe real Wood production/logistics")
	print("REAL_PLAY_STEP 04 Lumber id=%d resources=%s" % [lumber_id, simulation.get_resources()])
	var tower_id := _build_real(failures, fixture, simulation, Defs.BUILDING_WATCHTOWER, simulation.town_hall_position + Vector2i(8, 7))
	var tower: Dictionary = simulation.get_building_by_id(tower_id)
	_check(failures, tower_id > 0 and not bool(tower.get("construction", true)), "build a connected Watchtower foundation for later autonomous defence")
	print("REAL_PLAY_STEP 05 Watchtower tower=%d soldiers=%d" % [tower_id, simulation.soldiers_total])

	var quarry_id := _build_real(failures, fixture, simulation, Defs.BUILDING_QUARRY, simulation.town_hall_position + Vector2i(10, 4))
	var sawmill_id := _build_real(failures, fixture, simulation, Defs.BUILDING_SAWMILL, simulation.town_hall_position + Vector2i(8, 8))
	_check(failures, _wait_for_output(simulation, quarry_id, Defs.RESOURCE_STONE, 2000), "Quarry replenishes Stone through real production")
	_check(failures, _wait_for_output(simulation, sawmill_id, Defs.RESOURCE_PLANKS, 2200), "Sawmill converts real Wood into Planks")
	print("REAL_PLAY_STEP 06 Industry quarry=%d sawmill=%d resources=%s" % [quarry_id, sawmill_id, simulation.get_resources()])

	var farm_id := _build_real(failures, fixture, simulation, Defs.BUILDING_FARM, simulation.town_hall_position + Vector2i(7, 10))
	_check(failures, _wait_for_output(simulation, farm_id, Defs.RESOURCE_WHEAT, 2400), "Farm produces Wheat without injected resources")
	var bakery_id := _build_real(failures, fixture, simulation, Defs.BUILDING_BAKERY, simulation.town_hall_position + Vector2i(11, 9))
	_check(failures, _wait_for_output(simulation, bakery_id, Defs.RESOURCE_BREAD, 2600), "Bakery converts delivered Wheat into Bread")
	var population_ready := _wait_for_population(simulation, 8, 7000)
	_check(failures, population_ready, "food and housing grow the settlement enough to staff industry and defence")
	print("REAL_PLAY_STEP 07 Food farm=%d bakery=%d food=%d population=%d resources=%s" % [farm_id, bakery_id, simulation.get_food_units(), simulation.population_current, simulation.get_resources()])
	var barracks_id := _build_real(failures, fixture, simulation, Defs.BUILDING_BARRACKS, simulation.town_hall_position + Vector2i(12, 10))
	var soldier_ready := _wait_for_soldier(simulation, 1600)
	tower = simulation.get_building_by_id(tower_id)
	_check(failures, barracks_id > 0 and soldier_ready and int(tower.get("soldiers_assigned", 0)) > 0, "train a soldier and autonomously staff the Watchtower")
	print("REAL_PLAY_STEP 08 Defence barracks=%d soldiers=%d tower_staff=%d" % [barracks_id, simulation.soldiers_total, int(tower.get("soldiers_assigned", 0))])
	_check(failures, simulation.rivalry.get_workers("rival").size() > 0 and not simulation.rivalry.get_sovereign("rival").is_empty(), "actual rival realm remains active while the settlement develops")
	print("REAL_PLAY_STEP 08 Rival workers=%d structures=%d" % [simulation.rivalry.get_workers("rival").size(), simulation.rivalry.structures.size()])

	var food_before_night: int = simulation.get_food_units()
	var population_before_night: int = simulation.population_current
	var reached_night := _wait_until_night(simulation, 7000)
	var food_after_meal: int = simulation.get_food_units()
	var meal_details: Dictionary = _latest_event_details(simulation, "night_meal")
	for _tick in 260:
		simulation.advance_tick()
	var sheltered: int = simulation.get_sheltered_worker_count()
	_check(failures, reached_night and sheltered > 0, "reach natural night and observe residents enter authoritative shelter")
	_check(failures, int(meal_details.get("bread_used", 0)) > 0 or int(meal_details.get("wheat_used", 0)) > 0 or int(meal_details.get("hungry", 0)) > 0, "observe real nightly food consumption or hunger pressure")
	print("REAL_PLAY_STEP 09 Night population=%d->%d food=%d->%d sheltered=%d hungry=%d enemies=%d" % [population_before_night, simulation.population_current, food_before_night, food_after_meal, sheltered, simulation.hungry_population, simulation.enemies.size()])

	var raid_started: bool = not simulation.enemies.is_empty() or _wait_for_raid(simulation, 14000)
	var raid_had_attack := false
	var raid_had_projectile := false
	var raid_had_casualty := false
	var enemy_count_start: int = simulation.enemies.size()
	var town_hall_hp_start := _town_hall_hp(simulation)
	for _tick in 1600:
		var enemies_before: int = simulation.enemies.size()
		simulation.advance_tick()
		if not simulation.projectiles.is_empty():
			raid_had_projectile = true
		if simulation.enemies.size() < enemies_before:
			raid_had_casualty = true
		if _town_hall_hp(simulation) < town_hall_hp_start:
			raid_had_attack = true
		if not simulation.is_night:
			break
	_check(failures, raid_started and enemy_count_start > 0, "a raid occurs from the normal day/night simulation")
	_check(failures, raid_had_projectile or raid_had_attack, "autonomous defenders or raiders produce real combat outcomes")
	_check(failures, raid_had_casualty or not simulation.is_night, "raid resolves through casualties or dawn retreat")
	print("REAL_PLAY_STEP 10 Raid start=%d end=%d projectile=%s attack=%s casualty=%s game_over=%s" % [enemy_count_start, simulation.enemies.size(), raid_had_projectile, raid_had_attack, raid_had_casualty, simulation.game_finished])

	game._initialize_presentation()
	var saved_tick: int = simulation.get_tick_number()
	var saved_resources: Dictionary = simulation.get_resources()
	var saved_buildings: int = simulation.buildings.size()
	var saved: bool = game.simulation_host.save_to_path(SAVE_PATH)
	game.simulation_host.start_new(19, true)
	var loaded: bool = game.simulation_host.load_from_path(SAVE_PATH)
	game._initialize_presentation()
	var resumed = game.simulation_host.simulation
	_check(failures, saved and loaded and resumed.get_tick_number() == saved_tick, "save, exit the run, and reload the post-raid settlement")
	_check(failures, resumed.get_resources() == saved_resources and resumed.buildings.size() == saved_buildings, "post-raid economy and buildings reconstruct exactly")
	var resumed_tick: int = resumed.get_tick_number()
	for _tick in 20:
		resumed.advance_tick()
	game._sync_presentation()
	_check(failures, resumed.get_tick_number() == resumed_tick + 20 and game.world_view.building_views.size() > 0, "continue playing with reconstructed 3D views after reload")
	print("REAL_PLAY_STEP 11 Reload tick=%d continued=%d buildings=%d workers=%d" % [saved_tick, resumed.get_tick_number(), resumed.buildings.size(), resumed.workers.size()])
	_check(failures, _starting_resources_match(initial_resources), "demonstration used the intended starting economy with no injected resources")
	game.queue_free()
	await process_frame
	_finish(failures)


func _build_real(failures: Array[String], fixture, simulation, building_type: String, target: Vector2i) -> int:
	var site: Vector2i = fixture._ensure_site(simulation, building_type, target)
	if site.x < 0:
		print("REAL_SITE_FAIL type=%s resources=%s reasons=%s finished=%s" % [building_type, simulation.get_resources(), _placement_reason_counts(simulation, building_type), simulation.game_finished])
		failures.append("find a valid %s site" % Defs.building_name(building_type))
		return 0
	var result: Dictionary = simulation.request_build(building_type, site)
	if not bool(result.get("success", false)):
		failures.append("build %s: %s" % [Defs.building_name(building_type), result.get("message", "rejected")])
		return 0
	var id := int(Dictionary(result.get("building", {})).get("id", 0))
	if not fixture._advance_until_complete(simulation, id, 2400):
		var stalled: Dictionary = simulation.get_building_by_id(id)
		print("REAL_BUILD_STALL type=%s id=%d position=%s status=%s construction=%s delivered=%s needed=%s workers_free=%d night=%s finished=%s neighbors=%s" % [building_type, id, stalled.get("position", Vector2i.ZERO), stalled.get("status", "missing"), stalled.get("construction", null), stalled.get("materials_delivered", {}), stalled.get("materials_needed", {}), simulation.workers_free(), simulation.is_night, simulation.game_finished, _neighbor_debug(simulation, Vector2i(stalled.get("position", Vector2i.ZERO)))])
		failures.append("complete %s" % Defs.building_name(building_type))
	return id


func _neighbor_debug(simulation, tile: Vector2i) -> Array:
	var result := []
	for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		var neighbor: Vector2i = tile + direction
		var building: Dictionary = simulation.get_building_at_tile(neighbor)
		result.append({"tile": neighbor, "type": building.get("type", ""), "planned": building.get("planned_type", ""), "construction": building.get("construction", null), "connected_road": simulation.connected_roads.has(simulation._tile_key(neighbor))})
	return result


func _placement_reason_counts(simulation, building_type: String) -> Dictionary:
	var counts: Dictionary = {}
	for y in range(simulation.map_size.y):
		for x in range(simulation.map_size.x):
			var validation: Dictionary = simulation.validate_placement(building_type, Vector2i(x, y))
			var code := String(validation.get("reason", "success" if bool(validation.get("success", false)) else "unknown"))
			counts[code] = int(counts.get(code, 0)) + 1
	return counts


func _wait_for_output(simulation, building_id: int, resource_type: String, max_ticks: int) -> bool:
	if building_id <= 0:
		return false
	var initial_central := int(simulation.central_inventory.get(resource_type, 0))
	for _tick in max_ticks:
		var building: Dictionary = simulation.get_building_by_id(building_id)
		if int(Dictionary(building.get("local_inventory", {})).get(resource_type, 0)) > 0 or int(simulation.central_inventory.get(resource_type, 0)) > initial_central:
			return true
		simulation.advance_tick()
	return false


func _wait_for_soldier(simulation, max_ticks: int) -> bool:
	for _tick in max_ticks:
		if simulation.soldiers_total > 0:
			return true
		simulation.advance_tick()
	return false


func _wait_for_population(simulation, target: int, max_ticks: int) -> bool:
	for _tick in max_ticks:
		if simulation.population_current >= target:
			return true
		simulation.advance_tick()
	return false


func _wait_for_rival_reveal(simulation, max_ticks: int) -> bool:
	for _tick in max_ticks:
		if simulation.is_revealed(simulation.rival_town_hall_position):
			return true
		simulation.advance_tick()
	return false


func _wait_until_night(simulation, max_ticks: int) -> bool:
	for _tick in max_ticks:
		if simulation.is_night:
			return true
		simulation.advance_tick()
	return simulation.is_night


func _wait_for_raid(simulation, max_ticks: int) -> bool:
	for _tick in max_ticks:
		if not simulation.enemies.is_empty():
			return true
		if simulation.game_finished:
			return false
		simulation.advance_tick()
	return not simulation.enemies.is_empty()


func _latest_event_details(simulation, event_type: String) -> Dictionary:
	for index in range(simulation.run_journal.size() - 1, -1, -1):
		var event: Dictionary = simulation.run_journal[index]
		if String(event.get("event", "")) == event_type:
			return Dictionary(event.get("details", {}))
	return {}


func _starting_resources_match(resources: Dictionary) -> bool:
	for resource_type in Defs.RESOURCE_TYPES:
		if int(resources.get(resource_type, -1)) != int(Defs.STARTING_RESOURCES.get(resource_type, -2)):
			return false
	return true


func _town_hall_hp(simulation) -> int:
	for building_value in simulation.buildings:
		var building: Dictionary = building_value
		if String(building.get("type", "")) == Defs.BUILDING_TOWN_HALL:
			return int(building.get("hp", 0))
	return 0


func _check(failures: Array[String], condition: bool, label: String) -> void:
	print("%s %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		failures.append(label)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("PHASE3_REAL_GAME_PLAYTHROUGH PASS")
		quit(0)
	else:
		print("PHASE3_REAL_GAME_PLAYTHROUGH FAIL count=%d" % failures.size())
		for failure in failures:
			print("  - %s" % failure)
		quit(1)
