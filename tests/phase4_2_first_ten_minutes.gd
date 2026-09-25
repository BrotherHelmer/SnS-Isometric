extends SceneTree

## Headless stand-in for the required 15-minute / first-two-nights playtest.
## It cannot judge audio quality. It does measure friction, direction, storage,
## and Night 2 contact on review seed 260821.

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Wyrdfall = preload("res://src/GodotClient/Scripts/one_shard_wyrdfall.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")


func _init() -> void:
	var failures: Array[String] = []
	var sim: Simulation = Simulation.new(70, 70, 260821, false, true)
	var center := sim._footprint_center(sim.town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	var grass := 0
	for offset in sim._radius_offsets(6):
		if sim.get_tile(center + offset) == Defs.TILE_GRASS:
			grass += 1
	check(grass >= 80, "founding apron is buildable", failures)

	var lumber := sim._add_completed_building(Defs.BUILDING_LUMBER_CAMP, sim.town_hall_position + Vector2i(5, 0))
	lumber["connected"] = true
	lumber["assigned_staff"] = 1
	sim._try_staff_building(lumber)
	sim._sync_production_workers()
	var nearby := sim._find_nearby_deposit(Vector2i(lumber.get("position", sim.town_hall_position)), Defs.TILE_TREE, Simulation.LUMBER_REACH)
	if nearby.x >= 0:
		sim.tree_deposits[sim._tile_key(nearby)] = 6
	var trees_before := _count_tile(sim, Defs.TILE_TREE)
	sim._simulate_seconds_for_test(45.0)
	var trees_after := _count_tile(sim, Defs.TILE_TREE)
	check(trees_after < trees_before, "one woodcutter visibly removes a tree within 45s", failures)
	print("FLOW trees_before=%d trees_after_45s=%d" % [trees_before, trees_after])

	sim._add_completed_building(Defs.BUILDING_HOUSE, sim.town_hall_position + Vector2i(6, 4))
	sim._add_completed_building(Defs.BUILDING_FARM, sim.town_hall_position + Vector2i(6, 8))
	var objective: Dictionary = sim.get_macro_objective()
	check(String(objective.get("id", "")) == Wyrdfall.OBJECTIVE_REACH, "starter economy points at REACH THE SHARD", failures)
	var steps := " ".join(objective.get("steps", []))
	check("Outpost" in steps, "next steps name an Outpost", failures)
	print("FLOW objective=%s steps=%s" % [String(objective.get("title", "")), steps])

	var storage_sim: Simulation = Simulation.new(70, 70, 260821, false, true)
	storage_sim.population_current = 8
	storage_sim.housing_capacity = 10
	for resource_type in [Defs.RESOURCE_WOOD, Defs.RESOURCE_PLANKS, Defs.RESOURCE_STONE]:
		storage_sim.central_inventory[resource_type] = storage_sim.get_storage_limit(resource_type)
	var store_road := storage_sim._town_hall_entrance_tile() + Vector2i(1, 0)
	storage_sim._prepare_test_tile(store_road, Defs.TILE_GRASS)
	storage_sim.request_build(Defs.BUILDING_ROAD, store_road)
	var store := store_road + Vector2i(1, 0)
	for y in range(3):
		for x in range(4):
			storage_sim._prepare_test_tile(store + Vector2i(x, y), Defs.TILE_TREE)
			storage_sim.tree_deposits[storage_sim._tile_key(store + Vector2i(x, y))] = 1
	var planned := storage_sim.request_build(Defs.BUILDING_STOREHOUSE, store)
	print("FLOW storehouse success=%s reason=%s message=%s" % [str(planned.get("success", false)), String(planned.get("reason", "")), String(planned.get("message", ""))])
	check(bool(planned.get("success", false)), "Storehouse can be planned while storage is full and trees occupy the pad", failures)

	sim.soldiers_total = 1
	var tower := sim._add_completed_building(Defs.BUILDING_WATCHTOWER, sim.town_hall_position + Vector2i(2, 1))
	tower["connected"] = true
	tower["soldiers_assigned"] = 1
	sim._try_staff_building(tower)
	sim._sync_production_workers()
	sim.day_count = 1
	sim._start_night()
	check(sim.enemies.size() == 2, "Night 1 is a teaching wave of 2", failures)
	sim._simulate_seconds_for_test(sim.NIGHT_LENGTH_SECONDS + 1.0)
	check(not sim.game_finished, "Night 1 remains survivable", failures)

	sim.day_count = 2
	sim.is_night = true
	sim.enemies.clear()
	sim._spawn_wave()
	check(sim.enemies.size() == 5, "Night 2 spawns a real encounter", failures)
	var closest := 999
	for _second in 24:
		sim._simulate_seconds_for_test(1.0)
		for enemy in sim.enemies:
			closest = mini(closest, sim._manhattan(sim.town_hall_position, Vector2i(enemy.get("position", Vector2i.ZERO))))
	print("FLOW night2_closest=%d alive=%d finished=%s" % [closest, sim.enemies.size(), str(sim.game_finished)])
	check(closest <= 4, "Night 2 reaches the yard under ordinary one-tower prep", failures)
	check(not sim.game_finished, "Night 2 remains reasonably survivable", failures)

	if failures.is_empty():
		print("PHASE42_FIRST_TEN PASS")
		quit(0)
	else:
		for line in failures:
			print("FAIL %s" % line)
		print("PHASE42_FIRST_TEN FAIL %d" % failures.size())
		quit(1)


func check(ok: bool, label: String, failures: Array[String]) -> void:
	if not ok:
		failures.append(label)
	print("%s %s" % ["PASS" if ok else "FAIL", label])


func _count_tile(sim: Simulation, tile_type: String) -> int:
	var total := 0
	for y in range(sim.map_size.y):
		for x in range(sim.map_size.x):
			if sim.get_tile(Vector2i(x, y)) == tile_type:
				total += 1
	return total
