extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Adapter = preload("res://src/GodotClient3D/Scripts/production_presentation_adapter.gd")
const Fixture = preload("res://src/GodotClient3D/Scripts/production_demo_fixture.gd")

const SAVE_PATH := "res://artifacts/phase3/persistence/combat_round_trip.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var simulation = game.simulation_host.simulation
	var fixture := Fixture.new()
	var developed: Dictionary = fixture.apply(simulation, "developed")
	_check(failures, bool(developed.get("success", false)), "developed authoritative settlement fixture is healthy")
	_add_review_resources(simulation)
	var bakery_site: Vector2i = fixture._ensure_site(simulation, Defs.BUILDING_BAKERY, simulation.town_hall_position + Vector2i(11, 10))
	var bakery_id := fixture._request_and_complete(simulation, Defs.BUILDING_BAKERY, bakery_site)
	var bread_before := int(simulation.central_inventory.get(Defs.RESOURCE_BREAD, 0))
	simulation.central_inventory[Defs.RESOURCE_WHEAT] = int(simulation.central_inventory.get(Defs.RESOURCE_WHEAT, 0)) + 20
	for _tick in 260:
		simulation.advance_tick()
	var bakery: Dictionary = simulation.get_building_by_id(bakery_id)
	var bread_visible := int(simulation.central_inventory.get(Defs.RESOURCE_BREAD, 0)) > bread_before or int(Dictionary(bakery.get("local_inventory", {})).get(Defs.RESOURCE_BREAD, 0)) > 0
	_check(failures, bakery_id > 0 and bread_visible, "Farm/Wheat/Bakery/Bread chain remains observable")
	game._initialize_presentation()
	await process_frame
	var settlement: Dictionary = game.current_frame_snapshot.get("settlement", {})
	_check(failures, int(settlement.get("population", 0)) > 0 and int(settlement.get("housing_capacity", 0)) >= int(settlement.get("population", 0)), "population and housing capacity reach the 3D HUD adapter")
	_check(failures, settlement.has("food") and settlement.has("hungry") and settlement.has("workers_free"), "food, hunger, and staffing diagnostics reach the 3D HUD adapter")
	_check_identity(failures, game, Defs.BUILDING_FARM, "FarmSiloSilhouette", "Farm has a distinct normal-zoom silhouette")
	_check_identity(failures, game, Defs.BUILDING_STOREHOUSE, "StorehouseWing", "Storehouse has a distinct normal-zoom silhouette")
	_check_identity(failures, game, Defs.BUILDING_BAKERY, "BakeryChimney", "Bakery has a distinct normal-zoom silhouette")
	simulation.phase_time = simulation.DAY_LENGTH_SECONDS - 0.05
	simulation.advance_tick()
	for _tick in 260:
		simulation.advance_tick()
	game._sync_presentation()
	var night_frame: Dictionary = game.current_frame_snapshot
	var night_settlement: Dictionary = night_frame.get("settlement", {})
	_check(failures, bool(night_settlement.get("is_night", false)), "authoritative day/night state reaches production 3D")
	_check(failures, int(night_settlement.get("sheltered", 0)) > 0, "civilian shelter transitions complete at night")
	_check(failures, _frame_has_hidden_sleeper(night_frame), "sheltered residents consistently disappear into buildings")
	_check(failures, _frame_has_occupied_house(night_frame), "houses expose actual sheltered occupancy")
	game._update_day_night_lighting()
	_check(failures, game.sun_light.light_energy < 0.60, "night lighting is darker while retaining strategy readability")
	simulation._end_night()
	var tower_site: Vector2i = fixture._ensure_site(simulation, Defs.BUILDING_WATCHTOWER, simulation.town_hall_position + Vector2i(13, 8))
	var tower: Dictionary = simulation._add_completed_building(Defs.BUILDING_WATCHTOWER, tower_site)
	var tower_id := int(tower.get("id", 0))
	simulation._rebuild_occupied_tiles()
	simulation._recompute_road_network()
	simulation.soldiers_total = maxi(1, simulation.soldiers_total)
	tower["soldiers_assigned"] = 1
	tower["staffed"] = true
	tower["status"] = "Watching."
	simulation._sync_production_workers()
	_check(failures, tower_id > 0 and not bool(tower.get("construction", true)) and bool(tower.get("connected", false)) and int(tower.get("soldiers_assigned", 0)) == 1, "Watchtower is complete, road-connected, and staffed by a soldier")
	var tower_center: Vector2i = simulation._footprint_center(tower["position"], simulation._building_footprint(tower))
	var enemy_tile := tower_center + Vector2i(4, 0)
	var hidden_tile := _find_unknown_grass(simulation)
	simulation._spawn_enemy(hidden_tile, 40, 7, 0.0, 0, simulation.ENEMY_HEXER)
	var enemy: Dictionary = simulation.enemies.back()
	var hidden_descriptor := Adapter.new().enemy_descriptor(enemy, simulation)
	_check(failures, not bool(hidden_descriptor.get("visible", true)), "unknown enemies stay hidden by authoritative fog")
	simulation._prepare_test_tile(enemy_tile, Defs.TILE_GRASS)
	enemy["position"] = enemy_tile
	simulation._reveal_radius(enemy_tile, 6)
	enemy["attack_flash"] = simulation.ENEMY_ATTACK_ANIMATION_SECONDS
	var attack_descriptor := Adapter.new().enemy_descriptor(enemy, simulation)
	_check(failures, String(attack_descriptor.get("state", "")) == "Ranged", "ranged hostile attacks map to semantic military animation")
	simulation._update_towers(0.2)
	_check(failures, not simulation.projectiles.is_empty(), "staffed Watchtower creates an authoritative projectile event")
	var hp_before := int(tower.get("hp", 0))
	simulation._damage_building(tower, 1)
	_check(failures, int(tower.get("hp", 0)) == hp_before - 1, "building damage remains authoritative")
	_create_gate_fixture(simulation)
	game._sync_presentation()
	await process_frame
	var combat_frame: Dictionary = game.current_frame_snapshot
	_check(failures, not combat_frame.get("combatants", []).is_empty(), "enemy and military presentation lifecycle is populated from snapshots")
	_check(failures, not combat_frame.get("projectiles", []).is_empty() and game.world_view.projectile_views.size() > 0, "projectile view lifecycle follows authoritative attacks")
	_check(failures, game.world_view.gate_views.size() > 0, "connection-aware walls produce a readable gate view")
	_check(failures, game.world_view.fog_root.get_child_count() > 0, "world-space unknown fog mask is active")
	simulation._reveal_radius(simulation.rival_town_hall_position, 10)
	game._sync_presentation()
	_check(failures, _has_rival_home(game.current_frame_snapshot), "actual rival home and activity appear after scouting")
	_check(failures, game.world_view.rivalry_structure_views.size() > 0 and game.world_view.rival_road_views.size() > 0, "rival structures and owned roads have 3D lifecycle views")
	var enemy_view_id := int(attack_descriptor.get("id", 0))
	_check(failures, game.world_view.combatant_views.has(enemy_view_id), "revealed hostile creates a stable combatant wrapper")
	enemy["hp"] = 0
	simulation._update_enemies(0.1)
	game._sync_presentation()
	_check(failures, not game.world_view.combatant_views.has(enemy_view_id), "dead hostile leaves the active registry and enters bounded death cleanup")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/phase3/persistence"))
	var enemies_before_save: int = simulation.enemies.size()
	var saved: bool = game.simulation_host.save_to_path(SAVE_PATH)
	game.simulation_host.start_new(12, true)
	var loaded: bool = game.simulation_host.load_from_path(SAVE_PATH)
	game._initialize_presentation()
	_check(failures, saved and loaded, "save/load succeeds after combat")
	_check(failures, game.simulation_host.simulation.enemies.size() == enemies_before_save, "combat entity authority reconstructs after load")
	var save_json = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	_check(failures, typeof(save_json) == TYPE_DICTIONARY and int(save_json.get("version", 0)) == 7, "combat round trip preserves save schema version 7")
	game.queue_free()
	await process_frame
	_finish(failures)


func _add_review_resources(simulation) -> void:
	for resource_type in [Defs.RESOURCE_WOOD, Defs.RESOURCE_PLANKS, Defs.RESOURCE_STONE, Defs.RESOURCE_WHEAT, Defs.RESOURCE_BREAD, Defs.RESOURCE_WYRD]:
		simulation.central_inventory[resource_type] = maxi(int(simulation.central_inventory.get(resource_type, 0)), 80)


func _check_identity(failures: Array[String], game, building_type: String, child_name: String, label: String) -> void:
	var found := false
	for view_value in game.world_view.building_views.values():
		var view: ProductionBuildingView3D = view_value
		if view.building_type == building_type and view.workyard_root != null and view.workyard_root.find_child(child_name, true, false) != null:
			found = true
			break
	_check(failures, found, label)


func _frame_has_hidden_sleeper(frame: Dictionary) -> bool:
	for worker_value in frame.get("workers", []):
		var worker: Dictionary = worker_value
		if String(worker.get("state", "")) == "Sleep" and not bool(worker.get("visible", true)):
			return true
	return false


func _frame_has_occupied_house(frame: Dictionary) -> bool:
	for building_value in frame.get("buildings", []):
		var building: Dictionary = building_value
		if String(building.get("type", "")) == Defs.BUILDING_HOUSE and int(building.get("sheltered_occupants", 0)) > 0:
			return true
	return false


func _create_gate_fixture(simulation) -> void:
	for building_value in simulation.buildings:
		var road: Dictionary = building_value
		if String(road.get("type", "")) != Defs.BUILDING_ROAD or bool(road.get("construction", false)):
			continue
		var tile: Vector2i = road.get("position", Vector2i.ZERO)
		var left := tile + Vector2i.LEFT
		var right := tile + Vector2i.RIGHT
		if simulation.is_inside_map(left) and simulation.is_inside_map(right) and simulation.get_building_at_tile(left).is_empty() and simulation.get_building_at_tile(right).is_empty():
			simulation._prepare_test_tile(left, Defs.TILE_GRASS)
			simulation._prepare_test_tile(right, Defs.TILE_GRASS)
			simulation._add_completed_building(Defs.BUILDING_WALL, left)
			simulation._add_completed_building(Defs.BUILDING_WALL, right)
			simulation._rebuild_occupied_tiles()
			simulation._recompute_road_network()
			return


func _find_unknown_grass(simulation) -> Vector2i:
	for y in range(2, simulation.map_size.y - 2):
		for x in range(2, simulation.map_size.x - 2):
			var tile := Vector2i(x, y)
			if not simulation.is_revealed(tile) and simulation.get_building_at_tile(tile).is_empty():
				return tile
	return Vector2i(2, 2)


func _has_rival_home(frame: Dictionary) -> bool:
	for structure_value in frame.get("rivalry_structures", []):
		var structure: Dictionary = structure_value
		if String(structure.get("realm", "")) == "rival" and String(structure.get("type", "")) == Defs.BUILDING_TOWN_HALL:
			return true
	return false


func _check(failures: Array[String], condition: bool, label: String) -> void:
	print("%s %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		failures.append(label)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("PHASE3_LIVING_COMBAT_SMOKE PASS")
		quit(0)
	else:
		print("PHASE3_LIVING_COMBAT_SMOKE FAIL count=%d" % failures.size())
		quit(1)
