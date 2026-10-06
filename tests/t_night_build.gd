extends SceneTree

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")

var failures: Array[String] = []


func _init() -> void:
	_run()
	for line in failures:
		print("FAIL %s" % line)
	print("T_NIGHT_BUILD %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _run() -> void:
	_test_night_house_on_live_road()
	_test_night_road_and_house_orders()


func _test_night_house_on_live_road() -> void:
	var sim: Simulation = Simulation.new(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 424201, false)
	sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 424201, true)
	var house_tile := _house_tile_on_entrance(sim)
	_prepare_house_plot(sim, house_tile)
	sim._start_night()
	var house_result: Dictionary = sim.request_build(Defs.BUILDING_HOUSE, house_tile)
	_check(bool(house_result.get("success", false)), "house can be ordered at night")
	var night_site: Dictionary = sim.get_building_at_tile(house_tile)
	_check(bool(night_site.get("construction", false)), "night house stays a construction site until dawn work resumes")
	sim._simulate_seconds_for_test(Simulation.NIGHT_LENGTH_SECONDS + Defs.build_time(Defs.BUILDING_HOUSE) + 8.0)
	var house: Dictionary = sim.get_building_at_tile(house_tile)
	_check(not sim.is_night, "simulation has reached the following day")
	_check(String(house.get("type", "")) == Defs.BUILDING_HOUSE and not bool(house.get("construction", false)), "night-placed house completes after dawn")
	_check(_no_civilian_stuck_in_shelter(sim), "civilians are not left Sheltered after dawn")


func _test_night_road_and_house_orders() -> void:
	var sim: Simulation = Simulation.new(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 424202, false)
	sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 424202, true)
	var entrance := sim._town_hall_entrance_tile()
	var road_tile := entrance + Vector2i(0, 1)
	var house_tile := entrance + Vector2i(1, 1)
	sim._prepare_test_tile(road_tile, Defs.TILE_GRASS)
	_prepare_house_plot(sim, house_tile)
	sim._start_night()
	var road_result: Dictionary = sim.request_build(Defs.BUILDING_ROAD, road_tile)
	var house_result: Dictionary = sim.request_build(Defs.BUILDING_HOUSE, house_tile)
	_check(bool(road_result.get("success", false)) and bool(house_result.get("success", false)), "road and house can both be ordered at night")
	sim._simulate_seconds_for_test(Simulation.NIGHT_LENGTH_SECONDS + Defs.build_time(Defs.BUILDING_HOUSE) + 10.0)
	var road: Dictionary = sim.get_building_at_tile(road_tile)
	var house: Dictionary = sim.get_building_at_tile(house_tile)
	_check(String(road.get("type", "")) == Defs.BUILDING_ROAD and not bool(road.get("construction", false)), "night-placed road completes after dawn")
	_check(String(house.get("type", "")) == Defs.BUILDING_HOUSE and not bool(house.get("construction", false)), "night-placed house completes after its road and dawn")


func _house_tile_on_entrance(sim: Simulation) -> Vector2i:
	return sim._town_hall_entrance_tile() + Vector2i(1, 0)


func _prepare_house_plot(sim: Simulation, house_tile: Vector2i) -> void:
	for offset in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		sim._prepare_test_tile(house_tile + offset, Defs.TILE_GRASS)


func _no_civilian_stuck_in_shelter(sim: Simulation) -> bool:
	for worker_value in sim.get_workers():
		var worker: Dictionary = worker_value
		if String(worker.get("type", "")) == "guard":
			continue
		if String(worker.get("state", "")) in ["Sheltered", "Going to shelter", "No shelter"]:
			return false
	return true


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
