extends SceneTree

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Intentions = preload("res://src/GodotClient/Scripts/one_shard_intentions.gd")

var failures: Array[String] = []


func _init() -> void:
	_run()
	for line in failures:
		print("FAIL %s" % line)
	print("T_INTENTIONS %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _run() -> void:
	var sim: Simulation = Simulation.new(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 808080, false)
	sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 808080, true)
	var first: Dictionary = sim.get_current_intention()
	_check(String(first.get("id", "")) == Intentions.ID_ESTABLISH, "a new settlement starts with A Settlement Begins")
	_check(sim.get_settlement_intentions().size() >= 1 and sim.get_settlement_intentions().size() <= 2, "1–2 intentions are active")
	_complete_building(sim, Defs.BUILDING_LUMBER_CAMP)
	_complete_building(sim, Defs.BUILDING_QUARRY)
	var after_establish: Dictionary = sim.get_current_intention()
	_check(String(after_establish.get("id", "")) == Intentions.ID_FEED, "lumber + quarry advances to Feed the Settlement")
	_complete_building(sim, Defs.BUILDING_FARM)
	var nightfall: Dictionary = sim.get_current_intention()
	_check(String(nightfall.get("id", "")) == Intentions.ID_NIGHTFALL, "a farm advances to Prepare for Nightfall")
	_complete_building(sim, Defs.BUILDING_WATCHTOWER)
	sim.soldiers_total = 1
	sim.central_inventory[Defs.RESOURCE_BREAD] = 8
	var after_night: Dictionary = sim.get_current_intention()
	_check(String(after_night.get("id", "")) != Intentions.ID_NIGHTFALL, "defence, a soldier, and 8 food complete nightfall")
	sim.intention_flags["first_dawn"] = true
	var scout: Dictionary = sim.get_current_intention()
	_check(String(scout.get("id", "")) == Intentions.ID_SCOUT, "dawn unlocks the frontier scout intention")
	sim.intention_flags["scouted_frontier"] = true
	_check(sim.get_settlement_intentions().size() <= 2, "intentions stay at most two wide after scout")


func _complete_building(sim: Simulation, building_type: String) -> void:
	var tile := _open_tile(sim, Defs.building_footprint(building_type))
	_check(tile.x >= 0, "found a plot for %s" % building_type)
	if building_type == Defs.BUILDING_QUARRY:
		sim._set_tile(tile, Defs.TILE_ROCK)
	var building := sim._create_building(building_type, tile)
	building["construction"] = false
	sim.buildings.append(building)
	Intentions.evaluate(sim)


func _open_tile(sim: Simulation, footprint: Vector2i) -> Vector2i:
	var origin: Vector2i = sim.town_hall_position + Vector2i(6, 0)
	for y in range(-4, 10):
		for x in range(4, 16):
			var tile := origin + Vector2i(x, y)
			var clear := true
			for oy in range(footprint.y):
				for ox in range(footprint.x):
					var sample := tile + Vector2i(ox, oy)
					if not sim.is_inside_map(sample) or not sim.get_building_at_tile(sample).is_empty():
						clear = false
			if clear:
				return tile
	return Vector2i(-1, -1)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
