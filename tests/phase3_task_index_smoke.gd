extends SceneTree

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Fixture = preload("res://src/GodotClient3D/Scripts/production_demo_fixture.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var first = _make_scaled_simulation(200)
	var second = _make_scaled_simulation(200)
	_check(failures, first.workers.size() == 200 and second.workers.size() == 200, "200 inhabitants remain fully represented by live authority")
	for tick in 120:
		first.advance_tick()
		second.advance_tick()
		if tick % 10 == 0:
			_check_task_indexes(failures, first, "tick %d" % tick)
	var first_outcome := _economic_outcome(first)
	var second_outcome := _economic_outcome(second)
	_check(failures, first_outcome == second_outcome, "200-inhabitant economic outcome remains deterministic")
	_check(failures, first.workers.size() == 200, "scale test does not pause, deactivate, or discard inhabitants")
	var path_start: Vector2i = first._first_connected_road_tile()
	var path_goal: Vector2i = first._town_hall_entrance_tile()
	first.path_grid_dirty = true
	var rebuild_before: int = first.path_grid_rebuild_count
	first._find_worker_path(path_start, path_goal)
	var rebuild_after_first: int = first.path_grid_rebuild_count
	first._find_worker_path(path_start, path_goal)
	_check(failures, rebuild_after_first == rebuild_before + 1, "dirty authoritative path cache rebuilds exactly once")
	_check(failures, first.path_grid_rebuild_count == rebuild_after_first, "unchanged authoritative path cache is reused")
	_finish(failures)


func _make_scaled_simulation(target: int):
	var simulation = Simulation.new(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 260821, false, true)
	Fixture.new().apply(simulation, "developed")
	var templates: Array[Dictionary] = []
	for worker_value in simulation.workers:
		var worker: Dictionary = worker_value
		if String(worker.get("type", "")) != "carrier":
			templates.append(worker.duplicate(true))
	simulation.population_current = target
	simulation.housing_capacity = target
	simulation._ensure_carriers()
	while simulation.workers.size() < target:
		var template: Dictionary = templates[simulation.workers.size() % templates.size()].duplicate(true)
		template["id"] = simulation.next_worker_id
		template["path"] = []
		template["state"] = "Working"
		template["move_elapsed"] = 0.0
		template["carried_resource"] = ""
		template["carried_amount"] = 0
		simulation.workers.append(template)
		simulation.next_worker_id += 1
	return simulation


func _check_task_indexes(failures: Array[String], simulation, label: String) -> void:
	simulation._rebuild_task_indexes()
	for building_value in simulation.buildings:
		var building: Dictionary = building_value
		var id := int(building.get("id", 0))
		for resource_type in Defs.RESOURCE_TYPES:
			_check(failures, simulation._incoming_amount(id, resource_type) == _brute_incoming(simulation, id, resource_type), "%s indexed incoming reservations match tasks" % label)
			_check(failures, simulation._outgoing_amount(id, resource_type) == _brute_outgoing(simulation, id, resource_type), "%s indexed outgoing reservations match tasks" % label)
	for resource_type in Defs.RESOURCE_TYPES:
		_check(failures, simulation._incoming_to_central(resource_type) == _brute_central(simulation, resource_type), "%s indexed central reservations match tasks" % label)


func _brute_incoming(simulation, building_id: int, resource_type: String) -> int:
	var total := 0
	for worker_value in simulation.workers:
		var worker: Dictionary = worker_value
		var task: Dictionary = worker.get("task", {})
		var destination = task.get("destination", null)
		if typeof(destination) in [TYPE_INT, TYPE_FLOAT] and int(destination) == building_id and str(task.get("resource", "")) == resource_type:
			total += int(task.get("amount", 0))
	return total


func _brute_outgoing(simulation, building_id: int, resource_type: String) -> int:
	var total := 0
	for worker_value in simulation.workers:
		var worker: Dictionary = worker_value
		var task: Dictionary = worker.get("task", {})
		var source = task.get("source", null)
		if typeof(source) in [TYPE_INT, TYPE_FLOAT] and int(source) == building_id and str(task.get("resource", "")) == resource_type:
			total += int(task.get("amount", 0))
	return total


func _brute_central(simulation, resource_type: String) -> int:
	var total := 0
	for worker_value in simulation.workers:
		var worker: Dictionary = worker_value
		var task: Dictionary = worker.get("task", {})
		var destination = task.get("destination", null)
		if typeof(destination) == TYPE_STRING and destination == "central" and str(task.get("resource", "")) == resource_type:
			total += int(task.get("amount", 0))
	return total


func _economic_outcome(simulation) -> Dictionary:
	var local_inventories: Array = []
	for building_value in simulation.buildings:
		var building: Dictionary = building_value
		local_inventories.append({
			"id": int(building.get("id", 0)),
			"type": String(building.get("type", "")),
			"inventory": Dictionary(building.get("local_inventory", {})).duplicate(true),
			"status": String(building.get("status", "")),
		})
	return {
		"resources": simulation.get_resources(),
		"reserved": simulation.get_reserved_resources(),
		"population": simulation.population_current,
		"hungry": simulation.hungry_population,
		"workers": simulation.workers.size(),
		"local": local_inventories,
	}


func _check(failures: Array[String], condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
		print("FAIL %s" % label)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("PHASE3_TASK_INDEX_SMOKE PASS")
		quit(0)
	else:
		print("PHASE3_TASK_INDEX_SMOKE FAIL count=%d" % failures.size())
		quit(1)
