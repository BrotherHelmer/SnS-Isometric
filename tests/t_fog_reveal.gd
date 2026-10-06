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
	_test_unit_vision_survives_json_string()


func _test_building_vision_radii() -> void:
	var sim: Simulation = Simulation.new(8, 8, 1, false)
	_check(sim.building_vision_radius(Defs.BUILDING_WATCHTOWER) > sim.building_vision_radius(Defs.BUILDING_OUTPOST), "Watchtower vision is larger than Outpost")
	_check(sim.building_vision_radius(Defs.BUILDING_OUTPOST) > sim.building_vision_radius(Defs.BUILDING_LUMBER_CAMP), "Outpost vision is larger than a workplace")
	_check(sim.building_vision_radius(Defs.BUILDING_LUMEN_PILLAR) > sim.building_vision_radius(Defs.BUILDING_HOUSE), "Lumen Pillar vision is larger than a House")
	_check(sim.building_vision_radius(Defs.BUILDING_HOUSE) == Simulation.VISION_BUILDING, "ordinary buildings use the small workplace ring")
	_check(sim.unit_vision_radius("guard") > sim.unit_vision_radius("carrier"), "soldiers see farther than workers")


func _test_completed_buildings_reveal() -> void:
	var sim := _founded()
	var far := _far_unrevealed(sim, 3)
	_check(far.x >= 0, "found an in-map unexplored plot for the Watchtower")
	_flatten_hidden(sim, far, Vector2i(3, 3))
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
	var outpost_tile := _far_unrevealed(sim, 2)
	_flatten_hidden(sim, outpost_tile, Vector2i(2, 2))
	_check(not sim.is_revealed(outpost_tile), "a second far tile starts unexplored")
	var outpost := sim._create_building(Defs.BUILDING_OUTPOST, outpost_tile)
	sim.buildings.append(outpost)
	sim._reveal_from_world()
	_check(sim.is_revealed(outpost_tile), "a completed Outpost reveals fog")
	var outpost_count := _count_revealed_near(sim, outpost_tile, sim.building_vision_radius(Defs.BUILDING_OUTPOST))
	var lumber_tile := _far_unrevealed(sim, 3)
	_flatten_hidden(sim, lumber_tile, Vector2i(3, 3))
	var lumber := sim._create_building(Defs.BUILDING_LUMBER_CAMP, lumber_tile)
	sim.buildings.append(lumber)
	sim._reveal_from_world()
	var lumber_count := _count_revealed_near(sim, lumber_tile, sim.building_vision_radius(Defs.BUILDING_LUMBER_CAMP))
	_check(outpost_count > lumber_count, "Outpost reveals more tiles than a Lumber Camp")
	_check(sim.is_revealed(lumber_tile), "Lumber Camp reveals its own workplace")


func _test_unit_tile_change_reveal() -> void:
	var sim := _founded()
	var far := _far_unrevealed(sim, 1)
	_flatten_hidden(sim, far, Vector2i(1, 1))
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
	var farther := _far_unrevealed(sim, 1)
	_flatten_hidden(sim, farther, Vector2i(1, 1))
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


func _test_unit_vision_survives_json_string() -> void:
	var sim := _founded()
	var worker: Dictionary = sim.workers[0]
	worker["last_vision_tile"] = "(%d, %d)" % [int(worker["position"].x), int(worker["position"].y)]
	sim._update_unit_vision()
	_check(typeof(worker.get("last_vision_tile")) == TYPE_VECTOR2I or worker["position"] == sim._cached_vision_tile(worker), "stringified last_vision_tile does not crash the vision pass")
	worker["last_vision_tile"] = worker["position"]
	var serialized: Array = sim._serialize_workers()
	_check(serialized.size() > 0 and not serialized[0].has("last_vision_tile"), "vision cache is not written into the save")
	sim.workers = sim._restore_workers(serialized)
	sim._update_unit_vision()
	_check(sim.workers.size() > 0, "workers restore after stripping the vision cache")


func _founded() -> Simulation:
	var sim: Simulation = Simulation.new(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 717171, false)
	sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 717171, true)
	return sim


func _far_unrevealed(sim: Simulation, clearance: int) -> Vector2i:
	var origin: Vector2i = sim._footprint_center(sim.town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	var candidates: Array[Vector2i] = [
		origin + Vector2i(22, 0),
		origin + Vector2i(-22, 0),
		origin + Vector2i(0, 22),
		origin + Vector2i(0, -22),
		origin + Vector2i(18, 18),
		origin + Vector2i(-18, 18),
		origin + Vector2i(18, -18),
		origin + Vector2i(-18, -18),
		Vector2i(2, 2),
		Vector2i(sim.map_size.x - 4, 2),
		Vector2i(2, sim.map_size.y - 4),
		Vector2i(sim.map_size.x - 4, sim.map_size.y - 4)
	]
	for candidate in candidates:
		if _hidden_plot_fits(sim, candidate, clearance):
			return candidate
	return Vector2i(-1, -1)


func _hidden_plot_fits(sim: Simulation, anchor: Vector2i, clearance: int) -> bool:
	for y in range(clearance):
		for x in range(clearance):
			var tile := anchor + Vector2i(x, y)
			if not sim.is_inside_map(tile) or sim.is_revealed(tile):
				return false
	return true


func _flatten_hidden(sim: Simulation, anchor: Vector2i, footprint: Vector2i) -> void:
	# Do not use _prepare_test_tile: that helper also reveals the plot.
	for y in range(footprint.y):
		for x in range(footprint.x):
			var tile := anchor + Vector2i(x, y)
			if sim.is_inside_map(tile):
				sim._set_tile(tile, Defs.TILE_GRASS)
				sim.revealed_tiles.erase(sim._tile_key(tile))


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
