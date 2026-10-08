extends SceneTree

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Scout = preload("res://src/GodotClient/Scripts/one_shard_scout.gd")

var failures: Array[String] = []


func _init() -> void:
	_run()
	for line in failures:
		print("FAIL %s" % line)
	print("T_SCOUT_DIRECTION %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _run() -> void:
	_test_order_and_return()
	_test_auto_scout_reveals_fog()
	_test_low_health_and_death()
	_test_waypoint_score()


func _test_order_and_return() -> void:
	var sim := _ready_scout()
	var guard: Dictionary = _patrol(sim)
	var bread_before := int(sim.central_inventory.get(Defs.RESOURCE_BREAD, 0))
	var revealed_before := sim.revealed_tiles.size()
	var target := _fog_tile(sim, guard["position"])
	var result: Dictionary = sim.request_scout_direction(int(guard["id"]), target)
	_check(bool(result.get("success", false)), "a free soldier accepts Scout Direction")
	_check(int(sim.central_inventory.get(Defs.RESOURCE_BREAD, 0)) == bread_before - Scout.FOOD_COST, "scouting costs 1 bread")
	_check(guard.has("scout_mission"), "the soldier stores a scout mission")
	sim._simulate_seconds_for_test(24.0)
	_check(sim.revealed_tiles.size() > revealed_before, "walking into fog reveals tiles")
	sim.phase_time = float(sim.DAY_LENGTH_SECONDS) - 10.0
	sim._update_scout_worker(guard, 0.1)
	_check(bool(Dictionary(guard.get("scout_mission", {})).get("returning", false)), "dusk sends the scout home")
	sim._simulate_seconds_for_test(40.0)
	_check(not guard.has("scout_mission") or String(guard.get("state", "")) == "Patrolling", "the scout resumes patrol after returning")
	_check(bool(sim.intention_flags.get("scouted_frontier", false)) or sim.revealed_tiles.size() > revealed_before, "frontier reveal can complete the scout intention")


func _test_auto_scout_reveals_fog() -> void:
	var sim := _ready_scout()
	var guard: Dictionary = _patrol(sim)
	var bread_before := int(sim.central_inventory.get(Defs.RESOURCE_BREAD, 0))
	var revealed_before := sim.revealed_tiles.size()
	var result: Dictionary = sim.request_scout_auto(int(guard["id"]))
	_check(bool(result.get("success", false)), "Y / SCOUT auto-scouts without a map click")
	_check(int(sim.central_inventory.get(Defs.RESOURCE_BREAD, 0)) == bread_before - Scout.FOOD_COST, "auto scout still costs 1 bread")
	_check(guard.has("scout_mission"), "auto scout stores a mission")
	_check(String(guard.get("state", "")) == "Scouting", "auto scout shows the Scouting state")
	var target: Vector2i = Dictionary(guard.get("scout_mission", {})).get("target", Vector2i.ZERO)
	_check(sim.is_inside_map(target) and not sim.is_revealed(target), "auto scout aims at the nearest fog tile")
	sim._simulate_seconds_for_test(28.0)
	_check(sim.revealed_tiles.size() > revealed_before, "auto scout reveals fog cells over time")


func _test_low_health_and_death() -> void:
	var sim := _ready_scout()
	var guard: Dictionary = _patrol(sim)
	var target := _fog_tile(sim, guard["position"])
	sim.request_scout_direction(int(guard["id"]), target)
	guard = sim.get_worker_by_id(int(guard["id"]))
	_check(guard.has("scout_mission"), "low-health case still has a mission")
	guard["hp"] = int(floor(float(guard.get("max_hp", 40)) * 0.4))
	var reason := sim._scout_return_reason(guard)
	_check(reason == Scout.REASON_HEALTH, "about 50% HP turns the scout back")
	if reason == Scout.REASON_HEALTH:
		sim._begin_scout_return(guard, reason)
		_check(bool(Dictionary(guard.get("scout_mission", {})).get("returning", false)), "low health starts the walk home")
	var dying := _ready_scout()
	var lost: Dictionary = _patrol(dying)
	dying.request_scout_direction(int(lost["id"]), _fog_tile(dying, lost["position"]))
	dying._damage_worker(int(lost["id"]), 999)
	_check(dying.get_map_markers().size() >= 1, "a dead scout leaves a map marker")
	_check(String(dying.last_message).contains("SCOUT LOST"), "death posts a SCOUT LOST message")


func _test_waypoint_score() -> void:
	var rich := Scout.score_waypoint(12, 1.0, 4.0, 0.0)
	var risky := Scout.score_waypoint(12, 1.0, 4.0, 2.0)
	_check(rich > risky, "known enemy risk outweighs a similar unexplored leg")


func _ready_scout() -> Simulation:
	var sim: Simulation = Simulation.new(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 909091, false)
	sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 909091, true)
	sim.soldiers_total = 1
	sim._sync_production_workers()
	return sim


func _patrol(sim: Simulation) -> Dictionary:
	for worker in sim.workers:
		if sim.is_patrol_scout(worker):
			return worker
	return {}


func _fog_tile(sim: Simulation, from: Vector2i) -> Vector2i:
	var origin: Vector2i = sim.town_hall_position
	for offset in [Vector2i(18, 0), Vector2i(-18, 0), Vector2i(0, 18), Vector2i(0, -18), Vector2i(16, 16)]:
		var tile: Vector2i = origin + offset
		if sim.is_inside_map(tile) and not sim.is_revealed(tile):
			return tile
	return from + Vector2i(12, 0)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
