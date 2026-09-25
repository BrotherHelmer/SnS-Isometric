extends SceneTree

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const RivalryTuning = preload("res://src/GodotClient/Scripts/one_shard_rivalry_tuning.gd")


func _init() -> void:
	var simulation = Simulation.new(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 246810, false)
	var failures: Array[String] = []
	check(simulation.map_size == Vector2i(70, 70), "province is 70x70 microtiles", failures)
	check(_count_tile(simulation, Defs.TILE_SHARD) == 1, "province contains exactly one Shard", failures)
	check(_height_levels(simulation).size() >= 3, "terrain contains broad elevation levels", failures)
	check(_resource_layers_are_exclusive(simulation), "forest and rock deposits never share a tile", failures)
	check(simulation.population_current == 2 and simulation.housing_capacity == 5, "a new settlement starts with two of five residents", failures)
	check(not simulation.is_town_hall_founded() and simulation.rivalry == null, "the match waits for the player to found the Town Hall", failures)
	check(simulation.get_workers().size() == 2 and String(simulation.get_workers()[0].get("type", "")) == "founder", "two confused founding settlers wait beside the supplies", failures)
	check(not bool(simulation.validate_placement(Defs.BUILDING_ROAD, simulation._town_hall_entrance_tile()).get("success", false)), "nothing except the Town Hall can be planned during founding", failures)
	var original_founding_site: Vector2i = simulation.town_hall_position
	var chosen_founding_site: Vector2i = original_founding_site + Vector2i(-2, -1)
	_prepare_footprint(simulation, chosen_founding_site, Defs.building_footprint(Defs.BUILDING_TOWN_HALL), Defs.TILE_GRASS)
	var founding_result: Dictionary = simulation.request_build(Defs.BUILDING_TOWN_HALL, chosen_founding_site)
	check(
		bool(founding_result.get("success", false)) and simulation.town_hall_position == chosen_founding_site,
		"the player can choose any valid visible Town Hall site",
		failures
	)
	for founding_step in range(70):
		simulation.advance_tick()
		if simulation.is_town_hall_founded():
			break
	check(simulation.is_town_hall_founded() and simulation.rivalry != null, "finishing the Town Hall starts the live match", failures)
	check(is_zero_approx(simulation.phase_time), "the day clock does not start during founding construction", failures)
	var founding_nodes_hidden := true
	for wyrd_site in simulation.rivalry.get_wyrd_sites():
		if simulation.is_revealed(wyrd_site.get("position", Vector2i.ZERO)):
			founding_nodes_hidden = false
	check(founding_nodes_hidden, "Wyrd nodes never appear inside the opening visible area", failures)
	var founding_sources: Array = simulation.get_protection_sources()
	check(
		not founding_sources.is_empty()
		and String(founding_sources[0].get("kind", "")) == "Town Hall"
		and is_equal_approx(float(founding_sources[0].get("radius", 0.0)), 8.0)
		and bool(founding_sources[0].get("powered", false)),
		"the completed Town Hall raises a powered eight-tile protection bubble",
		failures
	)
	var duplicate_player_workers := 0
	for rivalry_worker in simulation.rivalry.get_workers():
		if String(rivalry_worker.get("realm_id", "")) == "player":
			duplicate_player_workers += 1
	check(duplicate_player_workers == 0, "no duplicate autonomous player workers stand outside the population system", failures)
	var town_hall: Dictionary = simulation._find_town_hall()
	check(int(town_hall.get("local_capacity", -1)) == 0, "the Town Hall has no local resource storage", failures)

	var growth_sim = Simulation.new(30, 30, 97531, false, true)
	growth_sim._update_population_growth(Simulation.FOUNDING_POP_GROWTH_INTERVAL - 1.0)
	var stayed_at_two: bool = growth_sim.population_current == 2
	growth_sim._update_population_growth(2.0)
	check(stayed_at_two and growth_sim.population_current == 3, "new settlers arrive gradually rather than spawning immediately", failures)

	var starter_road: Vector2i = simulation._town_hall_entrance_tile()
	check(simulation._is_road_tile(starter_road) and simulation.get_workers().size() == 1 and simulation.get_workers()[0]["position"] == starter_road, "the Town Hall starts with an entrance road and waiting carrier", failures)
	var road_tile: Vector2i = starter_road + Vector2i.LEFT
	simulation._prepare_test_tile(road_tile, Defs.TILE_GRASS)
	var wood_before := int(simulation.central_inventory[Defs.RESOURCE_WOOD])
	var road_result: Dictionary = simulation.request_build(Defs.BUILDING_ROAD, road_tile)
	check(
		bool(road_result.get("success", false))
		and int(simulation.central_inventory[Defs.RESOURCE_WOOD]) == wood_before
		and bool(Dictionary(road_result.get("building", {})).get("construction", false)),
		"roads are free plans rather than instant construction",
		failures
	)
	for road_step in range(80):
		simulation.advance_tick()
	var completed_road: Dictionary = simulation.get_building_at_tile(road_tile)
	check(
		String(completed_road.get("type", "")) == Defs.BUILDING_ROAD
		and simulation.connected_roads.has(simulation._tile_key(road_tile)),
		"a free peasant walks out and completes a planned road while time runs",
		failures
	)
	var side_road: Vector2i = simulation.town_hall_position + Vector2i(-1, 0)
	simulation._prepare_test_tile(side_road, Defs.TILE_GRASS)
	check(not bool(simulation.validate_placement(Defs.BUILDING_ROAD, side_road).get("success", false)), "the Town Hall road network starts only at its visible door", failures)
	var clear_tile: Vector2i = road_tile + Vector2i.LEFT
	simulation._prepare_test_tile(clear_tile, Defs.TILE_TREE)
	simulation.tree_deposits[simulation._tile_key(clear_tile)] = 24
	check(bool(simulation.request_clear(clear_tile).get("success", false)), "a free worker can be ordered to clear a resource tile", failures)
	for clear_step in range(80):
		simulation._update_clear_workers(Simulation.TICK_SECONDS)
	check(simulation.get_tile(clear_tile) == Defs.TILE_GRASS, "the clearing worker removes the obstacle after reaching it", failures)

	var house_anchor: Vector2i = road_tile + Vector2i.DOWN
	_prepare_footprint(simulation, house_anchor, Defs.building_footprint(Defs.BUILDING_HOUSE), Defs.TILE_GRASS)
	check(bool(simulation.validate_placement(Defs.BUILDING_HOUSE, house_anchor).get("success", false)), "multi-tile buildings validate their full footprint", failures)
	var hill_road := road_tile + Vector2i.DOWN
	simulation._prepare_test_tile(hill_road, Defs.TILE_GRASS)
	simulation.height_map[hill_road.y][hill_road.x] = simulation.get_height(road_tile) + 2
	check(bool(simulation.validate_placement(Defs.BUILDING_ROAD, hill_road).get("success", false)), "roads can climb a two-level hill transition", failures)

	var quarry_anchor: Vector2i = simulation.town_hall_position + Vector2i(7, 5)
	_prepare_footprint(simulation, quarry_anchor, Defs.building_footprint(Defs.BUILDING_QUARRY), Defs.TILE_GRASS)
	var quarry_rock: Vector2i = quarry_anchor + Vector2i.ONE
	simulation._prepare_test_tile(quarry_rock, Defs.TILE_ROCK)
	simulation.rock_deposits[simulation._tile_key(quarry_rock)] = 32
	simulation.height_map[quarry_anchor.y][quarry_anchor.x] += 1
	simulation.connected_roads[simulation._tile_key(quarry_anchor + Vector2i(-1, 1))] = true
	check(bool(simulation.validate_placement(Defs.BUILDING_QUARRY, quarry_anchor).get("success", false)), "quarries can level a gently sloped rock deposit", failures)

	check(not Defs.building_cost(Defs.BUILDING_SAWMILL).has(Defs.RESOURCE_STONE), "sawmills do not require quarry output to start the plank chain", failures)
	var full_sawmill := simulation._create_building(Defs.BUILDING_SAWMILL, simulation.town_hall_position + Vector2i(12, 10))
	full_sawmill["local_inventory"][Defs.RESOURCE_WOOD] = int(full_sawmill["local_capacity"])
	check(
		simulation._produce_from_building(full_sawmill)
		and int(full_sawmill["local_inventory"][Defs.RESOURCE_WOOD]) == int(full_sawmill["local_capacity"]) - 2
		and int(full_sawmill["local_inventory"][Defs.RESOURCE_PLANKS]) == 2,
		"a sawmill can convert a full Wood input bin into Planks",
		failures
	)
	check(simulation._oriented_footprint(Defs.BUILDING_FARM, 1) == Vector2i(3, 4), "rotating a rectangular building swaps its footprint", failures)
	var tower_tile := road_tile + Vector2i.DOWN
	simulation._prepare_test_tile(tower_tile, Defs.TILE_GRASS)
	simulation.central_inventory[Defs.RESOURCE_STONE] = 40
	simulation.central_inventory[Defs.RESOURCE_PLANKS] = 30
	check(bool(simulation.validate_placement(Defs.BUILDING_WATCHTOWER, tower_tile).get("success", false)), "a Watchtower can be founded directly from a connected road", failures)
	var unanchored_wall := tower_tile + Vector2i.DOWN
	simulation._prepare_test_tile(unanchored_wall, Defs.TILE_GRASS)
	check(not bool(simulation.validate_placement(Defs.BUILDING_WALL, unanchored_wall).get("success", false)), "the first wall requires a completed Watchtower", failures)
	simulation._add_completed_building(Defs.BUILDING_WATCHTOWER, tower_tile)
	simulation._rebuild_occupied_tiles()
	simulation._recompute_road_network()
	check(bool(simulation.validate_placement(Defs.BUILDING_WALL, unanchored_wall).get("success", false)), "walls extend from a completed Watchtower", failures)
	var chained_wall := unanchored_wall + Vector2i.DOWN
	simulation._prepare_test_tile(chained_wall, Defs.TILE_GRASS)
	check(bool(simulation.request_build(Defs.BUILDING_WALL, unanchored_wall).get("success", false)), "the first wall can be planned from the Watchtower", failures)
	check(bool(simulation.validate_placement(Defs.BUILDING_WALL, chained_wall).get("success", false)), "construction walls support the next wall tile", failures)

	for resource_type in Defs.RESOURCE_TYPES:
		simulation.central_inventory[resource_type] = simulation.get_storage_limit(resource_type)
	check(simulation.get_storage_room(Defs.RESOURCE_WHEAT) == 0, "central storage has a hard resource cap", failures)
	var base_wood_limit := simulation.get_storage_limit(Defs.RESOURCE_WOOD)
	var storehouse := simulation._create_building(Defs.BUILDING_STOREHOUSE, simulation.town_hall_position + Vector2i(12, 0))
	storehouse["connected"] = true
	simulation.buildings.append(storehouse)
	check(simulation.get_storage_limit(Defs.RESOURCE_WOOD) == base_wood_limit + int(Defs.STOREHOUSE_BONUS[Defs.RESOURCE_WOOD]), "Storehouses expand central capacity", failures)
	check(int(simulation.get_storage_limits()[Defs.RESOURCE_WOOD]) >= int(Defs.STOREHOUSE_BONUS[Defs.RESOURCE_WOOD]), "Storehouse capacity is visible in the resource bar", failures)
	var farm := simulation._create_building(Defs.BUILDING_FARM, simulation.town_hall_position + Vector2i(8, 0))
	farm["connected"] = true
	farm["local_inventory"][Defs.RESOURCE_WHEAT] = 8
	simulation.buildings.append(farm)
	var carrier := {"capacity": 5, "position": road_tile, "task": {}, "state": "Idle", "path": [], "carried_amount": 0}
	check(not simulation._assign_output_fetch(carrier), "full central storage leaves production in local output stores", failures)

	var tree_tile: Vector2i = simulation.town_hall_position + Vector2i(-9, 0)
	simulation._prepare_test_tile(tree_tile, Defs.TILE_TREE)
	simulation.tree_deposits[simulation._tile_key(tree_tile)] = 2
	simulation._consume_deposit(tree_tile, 2)
	check(simulation.get_tile(tree_tile) == Defs.TILE_GRASS, "harvesting consumes the visible tree node", failures)
	simulation._update_tree_regrowth(Simulation.TREE_REGROWTH_SECONDS + 1.0)
	check(simulation.get_tile(tree_tile) == Defs.TILE_GRASS and simulation.get_deposit_remaining(tree_tile) == 0, "harvested forest stands remain visibly cleared", failures)

	var tower := simulation._create_building(Defs.BUILDING_WATCHTOWER, simulation.town_hall_position + Vector2i(5, 4))
	tower["connected"] = true
	simulation.buildings.append(tower)
	check(not bool(simulation.restaff_building(int(tower["id"])).get("success", false)), "tower restaffing requires a trained soldier", failures)
	simulation.soldiers_total = 1
	check(bool(simulation.restaff_building(int(tower["id"])).get("success", false)) and int(tower.get("soldiers_assigned", 0)) == 1, "trained soldiers can restaff towers", failures)
	var tower_bubble_found := false
	for protection_source in simulation.get_protection_sources():
		if String(protection_source.get("kind", "")) == "Watchtower" and is_equal_approx(float(protection_source.get("radius", 0.0)), 3.0):
			tower_bubble_found = true
	check(tower_bubble_found, "connected towers add three-tile protection bubbles", failures)
	var hidden_position: Vector2i = simulation.shard_position
	var enemy := {"id": 1, "position": hidden_position, "hp": 20, "max_hp": 20}
	simulation.enemies = [enemy]
	check(simulation._find_enemy_in_range(tower["position"], 200).is_empty(), "towers cannot target enemies through fog", failures)
	simulation._reveal_radius(hidden_position, 0)
	check(not simulation._find_enemy_in_range(tower["position"], 200).is_empty(), "towers acquire enemies after scouting reveals them", failures)

	simulation.enemies.clear()
	simulation.hidden_threat_level = 3
	simulation.day_count = 3
	simulation._spawn_wave()
	check(simulation.enemies.size() >= 3 and simulation.enemies.size() <= 10 and int(simulation.enemies[0]["hp"]) < 40, "night waves stay at a readable, bounded size", failures)
	simulation._retreat_enemies_at_dawn()
	check(bool(simulation.enemies[0].get("retreating", false)), "surviving raiders retreat toward fog at dawn", failures)

	var first_wave_sim = Simulation.new(30, 30, 86420, false, true)
	first_wave_sim.enemies.clear()
	first_wave_sim.day_count = 1
	first_wave_sim._spawn_wave()
	check(first_wave_sim.enemies.size() >= 2 and first_wave_sim.enemies.size() <= 3, "the first raid teaches danger without annihilation", failures)

	var full_quarry_sim = Simulation.new(30, 30, 11223, false, true)
	full_quarry_sim.population_current = 5
	var full_quarry := full_quarry_sim._create_building(Defs.BUILDING_QUARRY, full_quarry_sim.town_hall_position + Vector2i(7, 0))
	full_quarry["connected"] = true
	full_quarry["deposit_remaining"] = 40
	full_quarry["assigned_staff"] = 1
	full_quarry["staffed"] = true
	full_quarry["production_timer"] = 3.0
	full_quarry["local_inventory"][Defs.RESOURCE_STONE] = int(full_quarry["local_capacity"])
	full_quarry_sim.buildings.append(full_quarry)
	full_quarry_sim._recalculate_workers_assigned()
	var quarry_deposit_before := int(full_quarry["deposit_remaining"])
	full_quarry_sim._update_production(10.0)
	check(
		bool(full_quarry.get("storage_paused", false))
		and int(full_quarry.get("assigned_staff", -1)) == 0
		and is_zero_approx(float(full_quarry.get("production_timer", -1.0)))
		and int(full_quarry.get("deposit_remaining", -1)) == quarry_deposit_before,
		"a full quarry freezes progress, preserves its deposit, and releases its worker",
		failures
	)

	var pooled_storage_sim = Simulation.new(70, 70, 22446, false, true)
	pooled_storage_sim.central_inventory[Defs.RESOURCE_PLANKS] = 28
	pooled_storage_sim.central_inventory[Defs.RESOURCE_STONE] = 2
	pooled_storage_sim.enemy_camps.clear()
	var stored_quarry := pooled_storage_sim._create_building(
		Defs.BUILDING_QUARRY,
		pooled_storage_sim.town_hall_position + Vector2i(8, 0)
	)
	stored_quarry["local_inventory"][Defs.RESOURCE_STONE] = 12
	pooled_storage_sim.buildings.append(stored_quarry)
	var bakery_anchor := Vector2i(10, 10)
	_prepare_footprint(pooled_storage_sim, bakery_anchor, Defs.building_footprint(Defs.BUILDING_BAKERY), Defs.TILE_GRASS)
	var pooled_road := bakery_anchor + Vector2i.LEFT
	pooled_storage_sim._prepare_test_tile(pooled_road, Defs.TILE_GRASS)
	pooled_storage_sim.connected_roads[pooled_storage_sim._tile_key(pooled_road)] = true
	var pooled_bakery_result: Dictionary = pooled_storage_sim.request_build(Defs.BUILDING_BAKERY, bakery_anchor)
	check(
		bool(pooled_bakery_result.get("success", false))
		and int(stored_quarry["local_inventory"][Defs.RESOURCE_STONE]) == 10
		and int(pooled_storage_sim.reserved_inventory[Defs.RESOURCE_STONE]) == 4,
		"construction can reserve materials shown in producer storage without deadlocking",
		failures
	)

	check(_soldier_balance_regression(1, true), "one open-field soldier defeats one raider", failures)
	check(_soldier_balance_regression(2, false), "two raiders defeat one open-field soldier", failures)

	var shield_sim = Simulation.new(30, 30, 99001, false, true)
	var shield_center := shield_sim._footprint_center(shield_sim.town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	var shield_enemy_tile := shield_center + Vector2i(9, 0)
	shield_sim._prepare_test_tile(shield_enemy_tile, Defs.TILE_GRASS)
	shield_sim._reveal_radius(shield_enemy_tile, 2)
	var shield_town: Dictionary = shield_sim._find_town_hall()
	var shield_hp_before := int(shield_town["hp"])
	shield_sim.is_night = true
	shield_sim.day_count = 2
	shield_sim.phase_time = 0.0
	shield_sim.central_inventory[Defs.RESOURCE_WYRD] = 3
	shield_sim.protection_powered = true
	shield_sim._spawn_enemy(shield_enemy_tile, 30, 10)
	for shield_step in range(240):
		shield_sim._update_enemies(Simulation.TICK_SECONDS)
	check(int(shield_town["hp"]) < shield_hp_before, "Lumen no longer blocks raiders from damaging the yard", failures)
	check(shield_sim.is_tile_protected(shield_center), "Lumen still claims the town as lighting and shelter", failures)
	shield_sim.central_inventory[Defs.RESOURCE_WYRD] = 3
	shield_sim.protection_powered = true
	shield_sim._update_wyrd_network(81.0)
	check(int(shield_sim.central_inventory[Defs.RESOURCE_WYRD]) == 2, "the Town Hall bubble consumes meaningful Wyrd each night minute", failures)
	var harvest_site: Dictionary = shield_sim.rivalry.get_wyrd_sites()[0]
	var harvest_outpost := {
		"id": 999,
		"realm_id": "player",
		"type": RivalryTuning.STRUCTURE_CLAIMANT_OUTPOST,
		"position": Vector2i(harvest_site["position"]) - Vector2i.ONE,
		"footprint": Vector2i(2, 2),
		"hp": 220,
		"max_hp": 220,
		"active": true,
		"connected": true
	}
	shield_sim.rivalry.structures.append(harvest_outpost)
	var wyrd_before_harvest := int(shield_sim.central_inventory[Defs.RESOURCE_WYRD])
	shield_sim._update_outpost_wyrd_harvest(Simulation.WYRD_OUTPOST_HARVEST_SECONDS + 0.1)
	check(
		int(shield_sim.central_inventory[Defs.RESOURCE_WYRD]) == wyrd_before_harvest + 1
		and shield_sim.outpost_has_wyrd_node(harvest_outpost),
		"an Outpost within three tiles harvests one Wyrd every thirty seconds",
		failures
	)

	var barracks := simulation._create_building(Defs.BUILDING_BARRACKS, simulation.town_hall_position + Vector2i(10, 8))
	barracks["connected"] = true
	barracks["assigned_staff"] = 1
	barracks["staffed"] = true
	simulation.buildings.append(barracks)
	simulation.population_current = 10
	simulation.central_inventory[Defs.RESOURCE_BREAD] = 10
	simulation.central_inventory[Defs.RESOURCE_PLANKS] = 10
	var soldiers_before: int = simulation.soldiers_total
	simulation._update_barracks(Simulation.BARRACKS_TRAIN_SECONDS + 0.1)
	check(simulation.soldiers_total == soldiers_before + 1, "Barracks convert a free settler and supplies into a soldier", failures)

	var camp: Dictionary = simulation.enemy_camps[0]
	simulation._activate_revealed_enemy_camps()
	check(not bool(camp.get("active", false)), "enemy camps remain dormant until a road discovers them", failures)
	simulation.connected_roads[simulation._tile_key(camp["position"] + Vector2i(2, 0))] = true
	simulation._activate_revealed_enemy_camps()
	check(bool(camp.get("active", false)), "roads wake nearby enemy camps", failures)

	var gate_sim = Simulation.new(30, 30, 445566, false, true)
	var gate_tile: Vector2i = gate_sim._town_hall_entrance_tile() + Vector2i(-3, 0)
	gate_sim._prepare_test_tile(gate_tile, Defs.TILE_GRASS)
	gate_sim._add_completed_building(Defs.BUILDING_ROAD, gate_tile)
	gate_sim._add_completed_building(Defs.BUILDING_WALL, gate_tile + Vector2i.LEFT)
	gate_sim._add_completed_building(Defs.BUILDING_WALL, gate_tile + Vector2i.RIGHT)
	gate_sim._rebuild_occupied_tiles()
	gate_sim._recompute_road_network()
	check(gate_sim.is_gate_tile(gate_tile), "opposing walls automatically form a gate across a road", failures)
	gate_sim.phase_time = Simulation.DAY_LENGTH_SECONDS - 20.0
	check(gate_sim.is_gate_closed(), "gates close during the final thirty seconds before night", failures)

	var saved_state: Dictionary = simulation._serialize_state().duplicate(true)
	var restored = Simulation.new(12, 12, 13579, false, true)
	restored._restore_state(saved_state)
	check(restored.map_size == Vector2i(70, 70) and restored.height_map == simulation.height_map, "save state preserves the larger elevated province", failures)
	check(restored.enemy_camps.size() == simulation.enemy_camps.size() and restored.soldiers_total == simulation.soldiers_total, "save state preserves camps and trained soldiers", failures)

	var shelter_sim = Simulation.new(70, 70, 112233, false, true)
	var shelter_town: Vector2i = shelter_sim.town_hall_position
	for x in range(5):
		var path_tile := shelter_town + Vector2i(x, 4)
		shelter_sim._prepare_test_tile(path_tile, Defs.TILE_GRASS)
		shelter_sim._add_completed_building(Defs.BUILDING_ROAD, path_tile)
	var house_position := shelter_town + Vector2i(0, 5)
	var lumber_position := shelter_town + Vector2i(3, 5)
	_prepare_footprint(shelter_sim, house_position, Defs.building_footprint(Defs.BUILDING_HOUSE), Defs.TILE_GRASS)
	_prepare_footprint(shelter_sim, lumber_position, Defs.building_footprint(Defs.BUILDING_LUMBER_CAMP), Defs.TILE_GRASS)
	shelter_sim.population_current = 8
	shelter_sim.housing_capacity = 10
	shelter_sim._add_completed_building(Defs.BUILDING_HOUSE, house_position)
	shelter_sim._add_completed_building(Defs.BUILDING_LUMBER_CAMP, lumber_position)
	shelter_sim._rebuild_occupied_tiles()
	shelter_sim._recompute_road_network()
	shelter_sim._auto_staff_unstaffed_buildings()
	shelter_sim._sync_production_workers()
	shelter_sim.is_night = true
	shelter_sim._send_workers_to_shelter()
	for step in range(220):
		shelter_sim._update_production_workers(Simulation.TICK_SECONDS)
	check(shelter_sim.get_sheltered_worker_count() > 0, "civilian workers walk into their houses at night", failures)

	var no_worker_sim = Simulation.new(30, 30, 778899, false, true)
	var blocked_clear_tile: Vector2i = no_worker_sim._town_hall_entrance_tile() + Vector2i(-2, 0)
	no_worker_sim._prepare_test_tile(blocked_clear_tile, Defs.TILE_TREE)
	no_worker_sim.tree_deposits[no_worker_sim._tile_key(blocked_clear_tile)] = 10
	no_worker_sim.population_current = 0
	var no_worker_result: Dictionary = no_worker_sim.validate_clear(blocked_clear_tile)
	check(
		not bool(no_worker_result.get("success", false))
		and String(no_worker_result.get("message", "")).contains("Build a House"),
		"clear-land failure explains how to gain another worker",
		failures
	)

	var depleted_quarry := simulation._create_building(Defs.BUILDING_QUARRY, simulation.town_hall_position + Vector2i(14, 8))
	depleted_quarry["assigned_staff"] = 1
	depleted_quarry["staffed"] = true
	simulation.buildings.append(depleted_quarry)
	simulation._mark_quarry_depleted(depleted_quarry)
	check(
		bool(depleted_quarry.get("depleted", false))
		and not bool(depleted_quarry.get("staffing_enabled", true))
		and int(depleted_quarry.get("assigned_staff", 1)) == 0,
		"a depleted quarry becomes a worker-free husk",
		failures
	)

	var forest_origin: Vector2i = simulation.town_hall_position + Vector2i(10, 0)
	for offset in simulation._radius_offsets(8):
		simulation._prepare_test_tile(forest_origin + offset, Defs.TILE_GRASS)
	var inner_tree: Vector2i = simulation.town_hall_position + Vector2i(4, 0)
	var outer_tree: Vector2i = simulation.town_hall_position + Vector2i(11, 0)
	for tree in [inner_tree, outer_tree]:
		simulation._prepare_test_tile(tree, Defs.TILE_TREE)
		simulation.tree_deposits[simulation._tile_key(tree)] = 18
	check(
		simulation._find_nearby_deposit(forest_origin, Defs.TILE_TREE, 8) == inner_tree,
		"lumber crews harvest Town-Hall-nearest trees first",
		failures
	)
	var work_tile: Vector2i = simulation._nearest_tree_work_tile(forest_origin, inner_tree)
	check(
		work_tile != inner_tree
		and simulation.get_tile(work_tile) == Defs.TILE_GRASS
		and simulation._manhattan(work_tile, inner_tree) == 1,
		"lumber crews stand beside trees instead of walking into blocked tree tiles",
		failures
	)

	shelter_sim.is_night = false
	shelter_sim._wake_workers_at_dawn()
	for wake_step in range(40):
		shelter_sim._update_production_workers(Simulation.TICK_SECONDS)
	shelter_sim.phase_time = Simulation.DAY_LENGTH_SECONDS - Simulation.NIGHT_FINAL_WARNING_SECONDS - 1.0
	shelter_sim.night_final_warning_sent = false
	shelter_sim._update_time(2.0)
	var recalled_at_dusk: bool = shelter_sim.night_final_warning_sent
	for worker in shelter_sim.get_workers():
		if String(worker.get("type", "")) != "guard" and String(worker.get("state", "")) not in ["Going to shelter", "Sheltered", "No shelter"]:
			recalled_at_dusk = false
	check(recalled_at_dusk, "the final dusk warning recalls every civilian before night", failures)

	if failures.is_empty():
		print("REBUILD_SMOKE PASS")
		quit(0)
	else:
		for failure in failures:
			print("FAIL: %s" % failure)
		print("REBUILD_SMOKE FAIL (%d)" % failures.size())
		quit(1)


func _soldier_balance_regression(enemy_count: int, expect_soldier_survives: bool) -> bool:
	var duel = Simulation.new(30, 30, 55110 + enemy_count, false, true)
	duel.workers.clear()
	duel.enemies.clear()
	duel.protection_powered = false
	duel.soldiers_total = 1
	var guard: Dictionary = duel._create_patrol_worker(0, "test-patrol")
	var guard_tile: Vector2i = duel._town_hall_entrance_tile()
	guard["position"] = guard_tile
	guard["path"] = []
	duel.workers.append(guard)
	var enemy_tile := guard_tile + Vector2i.LEFT
	duel._prepare_test_tile(enemy_tile, Defs.TILE_GRASS)
	duel._reveal_radius(enemy_tile, 1)
	for enemy_index in range(enemy_count):
		duel._spawn_enemy(enemy_tile, 18, 10, -0.02 * enemy_index)
	for combat_step in range(220):
		duel._update_enemies(Simulation.TICK_SECONDS)
		duel._update_patrol_combat(Simulation.TICK_SECONDS)
	var guard_alive := false
	for worker in duel.workers:
		if String(worker.get("type", "")) == "guard" and int(worker.get("hp", 0)) > 0:
			guard_alive = true
			break
	if expect_soldier_survives:
		return guard_alive and duel.enemies.is_empty()
	return not guard_alive


func check(condition: bool, label: String, failures: Array[String]) -> void:
	print("%s %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		failures.append(label)


func _count_tile(simulation, tile_type: String) -> int:
	var count := 0
	for row in simulation.map_tiles:
		for tile in row:
			if String(tile) == tile_type:
				count += 1
	return count


func _height_levels(simulation) -> Dictionary:
	var levels := {}
	for row in simulation.height_map:
		for level in row:
			levels[int(level)] = true
	return levels


func _resource_layers_are_exclusive(simulation) -> bool:
	for key in simulation.tree_deposits.keys():
		if simulation.rock_deposits.has(key):
			return false
	return true


func _prepare_footprint(simulation, anchor: Vector2i, footprint: Vector2i, terrain: String) -> void:
	var level: int = simulation.get_height(anchor)
	for y in range(footprint.y):
		for x in range(footprint.x):
			var tile := anchor + Vector2i(x, y)
			simulation._prepare_test_tile(tile, terrain)
			simulation.height_map[tile.y][tile.x] = level
