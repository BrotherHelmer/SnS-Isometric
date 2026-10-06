extends SceneTree

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")

var failures: Array[String] = []


func _init() -> void:
	_run()
	for line in failures:
		print("FAIL %s" % line)
	print("T_FOG_REVEAL %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _run() -> void:
	_test_building_vision_radii()
	_test_completed_buildings_reveal()
	_test_unit_tile_change_reveal()


func _test_building_vision_radii() -> void:
	var sim: Simulation = Simulation.new(8, 8, 1, false)
	_check(sim.building_vision_radius(Defs.BUILDING_WATCHTOWER) > sim.building_vision_radius(Defs.BUILDING_OUTPOST), "Watchtower vision is larger than Outpost")
	_check(sim.building_vision_radius(Defs.BUILDING_OUTPOST) > sim.building_vision_radius(Defs.BUILDING_LUMBER_CAMP), "Outpost vision is larger than a workplace")
	_check(sim.building_vision_radius(Defs.BUILDING_LUMEN_PILLAR) > sim.building_vision_radius(Defs.BUILDING_HOUSE), "Lumen Pillar vision is larger than a House")
	_check(sim.building_vision_radius(Defs.BUILDING_HOUSE) == Simulation.VISION_BUILDING, "ordinary buildings use the small workplace ring")
	_check(sim.unit_vision_radius("guard") > sim.unit_vision_radius("carrier"), "soldiers see farther than workers")


func _test_completed_buildings_reveal() -> void:
	var sim := _founded()
	var far := sim.town_hall_position + Vector2i(26, 0)
	_prepare_clear(sim, far, Vector2i(3, 3))
	_check(not sim.is_revealed(far), "a far tile starts unexplored")
	var site := sim._create_building(Defs.BUILDING_CONSTRUCTION_SITE, far)
	site["planned_type"] = Defs.BUILDING_WATCHTOWER
	site["construction"] = true
	sim.buildings.append(site)
	sim._reveal_from_world()
	_check(not sim.is_revealed(far), "a construction site does not reveal fog")
	sim.finish_construction(site)
	_check(sim.is_revealed(far), "a completed Watchtower reveals its tile")
	_check(_count_revealed_near(sim, far, sim.building_vision_radius(Defs.BUILDING_WATCHTOWER)) > 80, "Watchtower paints a large vision disk")
	var outpost_tile := sim.town_hall_position + Vector2i(0, 26)
	_prepare_clear(sim, outpost_tile, Vector2i(2, 2))
	_check(not sim.is_revealed(outpost_tile), "a second far tile starts unexplored")
	var outpost := sim._create_building(Defs.BUILDING_OUTPOST, outpost_tile)
	sim.buildings.append(outpost)
	sim._reveal_from_world()
	_check(sim.is_revealed(outpost_tile), "a completed Outpost reveals fog")
	var outpost_count := _count_revealed_near(sim, outpost_tile, sim.building_vision_radius(Defs.BUILDING_OUTPOST))
	var lumber_tile := sim.town_hall_position + Vector2i(-26, 0)
	_prepare_clear(sim, lumber_tile, Vector2i(3, 3))
	var lumber := sim._create_building(Defs.BUILDING_LUMBER_CAMP, lumber_tile)
	sim.buildings.append(lumber)
	sim._reveal_from_world()
	var lumber_count := _count_revealed_near(sim, lumber_tile, sim.building_vision_radius(Defs.BUILDING_LUMBER_CAMP))
	_check(outpost_count > lumber_count, "Outpost reveals more tiles than a Lumber Camp")
	_check(sim.is_revealed(lumber_tile), "Lumber Camp reveals its own workplace")


func _test_unit_tile_change_reveal() -> void:
	var sim := _founded()
	var far := sim.town_hall_position + Vector2i(24, 24)
	_prepare_clear(sim, far, Vector2i(1, 1))
	_check(not sim.is_revealed(far), "walker target starts in fog")
	var worker: Dictionary = sim.workers[0]
	worker["position"] = far
	worker["type"] = "carrier"
	worker.erase("last_vision_tile")
	sim._update_unit_vision()
	_check(sim.is_revealed(far), "a worker stepping onto a tile reveals it")
	_check(_count_revealed_near(sim, far, Simulation.VISION_WORKER) >= 9, "workers paint a small vision disk")
	var before := sim.revealed_tiles.size()
	sim._update_unit_vision()
	_check(sim.revealed_tiles.size() == before, "standing still does not recost a vision flood")
	var farther := far + Vector2i(6, 0)
	_prepare_clear(sim, farther, Vector2i(1, 1))
	_check(not sim.is_revealed(farther), "soldier target starts in fog")
	var guard := {
		"id": sim.next_worker_id,
		"type": "guard",
		"position": farther,
		"hp": Simulation.WORKER_MAX_HP,
		"path": [],
		"state": "Patrolling"
	}
	sim.next_worker_id += 1
	sim.workers.append(guard)
	sim._update_unit_vision()
	_check(sim.is_revealed(farther), "a soldier stepping onto a tile reveals it")
	_check(_count_revealed_near(sim, farther, Simulation.VISION_SOLDIER) > _count_revealed_near(sim, far, Simulation.VISION_WORKER), "soldiers reveal a larger ring than workers")


func _founded() -> Simulation:
	var sim: Simulation = Simulation.new(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 717171, false)
	sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 717171, true)
	return sim


func _prepare_clear(sim: Simulation, anchor: Vector2i, footprint: Vector2i) -> void:
	for y in range(footprint.y):
		for x in range(footprint.x):
			var tile := anchor + Vector2i(x, y)
			if sim.is_inside_map(tile):
				sim._prepare_test_tile(tile, Defs.TILE_GRASS)


func _count_revealed_near(sim: Simulation, center: Vector2i, radius: int) -> int:
	var count := 0
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			if absi(x) + absi(y) > radius:
				continue
			var tile := center + Vector2i(x, y)
			if sim.is_inside_map(tile) and sim.is_revealed(tile):
				count += 1
	return count


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
