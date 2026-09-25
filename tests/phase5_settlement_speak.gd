extends SceneTree

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Wyrdfall = preload("res://src/GodotClient/Scripts/one_shard_wyrdfall.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")


func _init() -> void:
	var failures: Array[String] = []
	_test_auto_spur(failures)
	_test_night_two_damages_yard(failures)
	_test_night_one_teaching(failures)
	_test_objective_verbs(failures)
	_test_wall_chain(failures)
	if failures.is_empty():
		print("PHASE5_SETTLEMENT_SPEAK PASS")
		quit(0)
	else:
		for line in failures:
			print("FAIL %s" % line)
		print("PHASE5_SETTLEMENT_SPEAK FAIL %d" % failures.size())
		quit(1)


func check(ok: bool, label: String, failures: Array[String]) -> void:
	if not ok:
		failures.append(label)
	print("%s %s" % ["PASS" if ok else "FAIL", label])


func _test_auto_spur(failures: Array[String]) -> void:
	var sim: Simulation = Simulation.new(70, 70, 260821, false, true)
	sim.central_inventory[Defs.RESOURCE_WOOD] = 40
	sim.central_inventory[Defs.RESOURCE_PLANKS] = 20
	sim.central_inventory[Defs.RESOURCE_STONE] = 20
	var origin := _find_spur_house_site(sim)
	check(origin.x >= 0, "a house site exists two tiles off the road", failures)
	if origin.x < 0:
		return
	var spur: Array[Vector2i] = sim._auto_spur_tiles(origin, Defs.building_footprint(Defs.BUILDING_HOUSE))
	check(not spur.is_empty() and spur.size() <= 2, "auto-spur is 1-2 road tiles", failures)
	var validation := sim.validate_placement(Defs.BUILDING_HOUSE, origin)
	check(bool(validation.get("success", false)), "off-road house within spur range validates", failures)
	check("road" in String(validation.get("message", "")).to_lower() or "CLEARING REQUIRED" in String(validation.get("message", "")), "preview mentions the short road or clearing", failures)
	var pads: Dictionary = sim.collect_build_pads(Defs.BUILDING_HOUSE, 0, 40)
	check(not pads.get("valid", []).is_empty() or not pads.get("clearing", []).is_empty(), "pad heatmap finds legal house sites", failures)
	var planned_roads_before := 0
	for building in sim.buildings:
		if bool(building.get("construction", false)) and String(building.get("planned_type", "")) == Defs.BUILDING_ROAD:
			planned_roads_before += 1
	var result := sim.request_build(Defs.BUILDING_HOUSE, origin)
	check(bool(result.get("success", false)), "request_build accepts the auto-spur house", failures)
	var planned_roads_after := 0
	for building in sim.buildings:
		if bool(building.get("construction", false)) and String(building.get("planned_type", "")) == Defs.BUILDING_ROAD:
			planned_roads_after += 1
	check(planned_roads_after >= planned_roads_before + spur.size(), "building off-road plans the spur tiles", failures)


func _find_spur_house_site(sim: Simulation) -> Vector2i:
	var footprint := Defs.building_footprint(Defs.BUILDING_HOUSE)
	for road_key in sim.connected_roads.keys():
		var road := sim._tile_from_key(String(road_key))
		for y in range(-4, 5):
			for x in range(-4, 5):
				var origin := road + Vector2i(x, y)
				if not sim.is_inside_map(origin) or not sim.is_revealed(origin):
					continue
				if sim._footprint_touches_planned_or_connected_road(origin, footprint):
					continue
				var spur: Array[Vector2i] = sim._auto_spur_tiles(origin, footprint)
				if spur.is_empty() or spur.size() > 2:
					continue
				for tile in sim._footprint_tiles(origin, footprint):
					if not sim.is_inside_map(tile):
						continue
					if String(sim.get_tile(tile)) == Defs.TILE_TREE:
						continue
					sim._prepare_test_tile(tile, Defs.TILE_GRASS)
				var validation := sim.validate_placement(Defs.BUILDING_HOUSE, origin)
				if bool(validation.get("success", false)):
					return origin
	return Vector2i(-1, -1)


func _test_night_two_damages_yard(failures: Array[String]) -> void:
	var sim: Simulation = Simulation.new(70, 70, 260821, false, true)
	var town: Dictionary = sim._find_town_hall()
	var hp_before := int(town["hp"])
	sim.day_count = 2
	sim.is_night = true
	sim.phase_time = 0.0
	sim.protection_powered = true
	sim.central_inventory[Defs.RESOURCE_WYRD] = 3
	sim._spawn_wave()
	check(sim.enemies.size() == 5, "Night 2 still spawns five hostiles", failures)
	var closest := 999
	sim._simulate_seconds_for_test(36.0)
	for enemy in sim.enemies:
		closest = mini(closest, sim._manhattan(sim.town_hall_position, Vector2i(enemy.get("position", Vector2i.ZERO))))
	var damaged := int(town["hp"]) < hp_before
	if not damaged:
		for building in sim.buildings:
			if int(building.get("hp", 0)) < int(building.get("max_hp", 0)):
				damaged = true
	print("PHASE5 night2 closest=%d th_hp=%d/%d damaged=%s finished=%s" % [
		closest,
		int(town["hp"]),
		hp_before,
		str(damaged),
		str(sim.game_finished)
	])
	check(damaged or closest <= 2, "Night 2 reaches or damages the yard", failures)
	check(not sim.game_finished, "Night 2 does not instantly end the run", failures)
	check(sim.is_tile_protected(sim._footprint_center(sim.town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))), "Lumen claim remains after the raid enters", failures)


func _test_night_one_teaching(failures: Array[String]) -> void:
	var plan := Wyrdfall.wave_plan(0.0, 1, true, false)
	check(int(plan.get("size", 0)) == 2, "Night 1 remains a teaching wave of 2", failures)
	check(int(plan.get("damage", 0)) == 2, "Night 1 raider damage stays tutorial-low", failures)
	var sim: Simulation = Simulation.new(70, 70, 260821, false, true)
	sim.day_count = 1
	sim._start_night()
	check(sim.enemies.size() == 2, "Night 1 actually spawns two raiders", failures)
	sim._simulate_seconds_for_test(80.0)
	var retreating := 0
	for enemy in sim.enemies:
		if bool(enemy.get("retreating", false)):
			retreating += 1
	check(not sim.game_finished, "Night 1 remains survivable", failures)
	check(retreating > 0 or sim.enemies.is_empty(), "Night 1 raiders retreat after the tutorial window", failures)


func _test_objective_verbs(failures: Array[String]) -> void:
	var opening := Wyrdfall.macro_objective({
		"has_lumber": false,
		"has_house": false,
		"has_farm": false,
		"has_outpost": false,
		"starter_ready": false,
		"connected_roads": 1
	})
	check(String(opening.get("id", "")) == Wyrdfall.OBJECTIVE_SURVIVE, "opening objective is the settle-in stage", failures)
	check(String(opening.get("title", "")).begins_with("FEED") or "SETTLEMENT" in String(opening.get("title", "")), "opening title is a verb, not SURVIVE", failures)
	check(not opening.get("steps", []).is_empty(), "opening objective lists a first action", failures)
	var reach := Wyrdfall.macro_objective({
		"has_lumber": true,
		"has_house": true,
		"has_farm": true,
		"has_outpost": false,
		"starter_ready": true,
		"connected_roads": 10
	})
	check(String(reach.get("id", "")) == Wyrdfall.OBJECTIVE_REACH, "starter economy still unlocks REACH THE SHARD", failures)


func _test_wall_chain(failures: Array[String]) -> void:
	var sim: Simulation = Simulation.new(70, 70, 260821, false, true)
	sim.central_inventory[Defs.RESOURCE_STONE] = 40
	sim.central_inventory[Defs.RESOURCE_PLANKS] = 20
	var tower_tile := sim.town_hall_position + Vector2i(6, 8)
	var first_wall := tower_tile + Vector2i.RIGHT
	var second_wall := first_wall + Vector2i.RIGHT
	sim._prepare_test_tile(tower_tile, Defs.TILE_GRASS)
	sim._prepare_test_tile(first_wall, Defs.TILE_GRASS)
	sim._prepare_test_tile(second_wall, Defs.TILE_GRASS)
	check(not bool(sim.validate_placement(Defs.BUILDING_WALL, first_wall).get("success", false)), "walls still need a completed Watchtower before the first section", failures)
	sim._add_completed_building(Defs.BUILDING_WATCHTOWER, tower_tile)
	sim._rebuild_occupied_tiles()
	check(bool(sim.request_build(Defs.BUILDING_WALL, first_wall).get("success", false)), "the first wall plans against a completed Watchtower", failures)
	check(bool(sim.validate_placement(Defs.BUILDING_WALL, second_wall).get("success", false)), "a planned wall supports the next dragged section", failures)
	check(bool(sim.request_build(Defs.BUILDING_WALL, second_wall).get("success", false)), "hold-and-drag can queue a connected wall run", failures)
