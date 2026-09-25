extends SceneTree

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Adapter = preload("res://src/GodotClient3D/Scripts/production_presentation_adapter.gd")
const Fixture = preload("res://src/GodotClient3D/Scripts/production_demo_fixture.gd")

const POPULATION_COUNTS := [25, 50, 100, 150, 200]
const WARMUP_TICKS := 20
const SAMPLE_TICKS := 120
const SNAPSHOT_SAMPLES := 30

var output_path := "res://artifacts/phase3/performance/baseline_authoritative_profile.json"
var profile_label := "baseline"


func _init() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")
		elif argument.begins_with("--label="):
			profile_label = argument.trim_prefix("--label=")
	call_deferred("_run")


func _run() -> void:
	var results: Array[Dictionary] = []
	for population in POPULATION_COUNTS:
		print("PHASE3_PROFILE_BEGIN label=%s inhabitants=%d" % [profile_label, population])
		var result := _profile_population(population)
		results.append(result)
		print("PHASE3_PROFILE_RESULT inhabitants=%d avg=%.3fms p95=%.3fms p99=%.3fms max=%.3fms scans_per_tick=%.1f" % [
			population,
			float(result.get("tick_average_ms", 0.0)),
			float(result.get("tick_p95_ms", 0.0)),
			float(result.get("tick_p99_ms", 0.0)),
			float(result.get("tick_max_ms", 0.0)),
			float(result.get("dictionary_scan_items_per_tick", 0.0)),
		])
	var payload := {
		"phase": "Phase 3 authoritative simulation scale",
		"profile_label": profile_label,
		"seed": 260821,
		"tick_seconds": Simulation.TICK_SECONDS,
		"warmup_ticks": WARMUP_TICKS,
		"sample_ticks": SAMPLE_TICKS,
		"method": "Developed deterministic authoritative fixture; synthetic population uses real worker dictionaries and all agents remain live; presentation extraction measured separately.",
		"results": results,
	}
	var absolute_path := ProjectSettings.globalize_path(output_path)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		push_error("Unable to write Phase 3 simulation profile: %s" % absolute_path)
		quit(1)
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	print("PHASE3_SIMULATION_PROFILE_PASS label=%s path=%s" % [profile_label, absolute_path])
	quit(0)


func _profile_population(target: int) -> Dictionary:
	var simulation = Simulation.new(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 260821, false, true)
	var fixture_result: Dictionary = Fixture.new().apply(simulation, "developed")
	if not bool(fixture_result.get("success", false)):
		push_error("Profile fixture failed for %d inhabitants: %s" % [target, fixture_result.get("report", [])])
		return {"inhabitants": target, "fixture_failed": true}
	_scale_authoritative_population(simulation, target)
	for _index in WARMUP_TICKS:
		simulation.advance_tick()
	var memory_before := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	simulation.set_performance_profiling(true, true)
	for _index in SAMPLE_TICKS:
		simulation.advance_tick()
	var memory_after := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var result: Dictionary = simulation.get_performance_profile()
	simulation.set_performance_profiling(false, false)
	var adapter_metrics := _measure_adapter(simulation)
	result["requested_inhabitants"] = target
	result["tick_ms_per_inhabitant"] = snappedf(float(result.get("tick_average_ms", 0.0)) / float(target), 0.00001)
	var scan_total := 0
	for scan_value in Dictionary(result.get("dictionary_entity_scan_items", {})).values():
		scan_total += int(scan_value)
	result["dictionary_scan_items_total"] = scan_total
	result["dictionary_scan_items_per_tick"] = snappedf(float(scan_total) / float(SAMPLE_TICKS), 0.01)
	result["dictionary_scan_items_per_inhabitant_tick"] = snappedf(float(scan_total) / float(SAMPLE_TICKS * target), 0.001)
	result["static_memory_delta_bytes"] = memory_after - memory_before
	result["presentation_snapshot_extraction"] = adapter_metrics
	result["outcome"] = _outcome_signature(simulation)
	return result


func _scale_authoritative_population(simulation, target: int) -> void:
	var production_templates: Array[Dictionary] = []
	for worker_value in simulation.workers:
		var worker: Dictionary = worker_value
		if String(worker.get("type", "")) != "carrier":
			production_templates.append(worker.duplicate(true))
	simulation.housing_capacity = target
	simulation.population_current = target
	simulation._ensure_carriers()
	if production_templates.is_empty():
		return
	var center: Vector2i = Vector2i(simulation.town_hall_position) + Vector2i(1, 1)
	while simulation.workers.size() < target:
		var template: Dictionary = production_templates[simulation.workers.size() % production_templates.size()].duplicate(true)
		var index: int = simulation.workers.size()
		template["id"] = simulation.next_worker_id
		template["position"] = Vector2i(
			clampi(center.x + index % 18 - 9, 0, simulation.map_size.x - 1),
			clampi(center.y + floori(float(index) / 18.0) % 12 - 6, 0, simulation.map_size.y - 1)
		)
		template["path"] = []
		template["move_elapsed"] = 0.0
		template["carried_resource"] = ""
		template["carried_amount"] = 0
		simulation.workers.append(template)
		simulation.next_worker_id += 1


func _measure_adapter(simulation) -> Dictionary:
	var adapter := Adapter.new()
	var samples: Array[float] = []
	for _index in SNAPSHOT_SAMPLES:
		var started := Time.get_ticks_usec()
		adapter.capture_frame(simulation)
		samples.append(float(Time.get_ticks_usec() - started) / 1000.0)
	return {
		"calls": SNAPSHOT_SAMPLES,
		"average_ms": snappedf(_mean(samples), 0.0001),
		"p95_ms": snappedf(_percentile(samples, 0.95), 0.0001),
		"p99_ms": snappedf(_percentile(samples, 0.99), 0.0001),
	}


func _outcome_signature(simulation) -> Dictionary:
	var building_state: Array[Dictionary] = []
	for building_value in simulation.buildings:
		var building: Dictionary = building_value
		building_state.append({
			"id": int(building.get("id", 0)),
			"type": String(building.get("type", "")),
			"planned_type": String(building.get("planned_type", "")),
			"construction": bool(building.get("construction", false)),
			"status": String(building.get("status", "")),
			"assigned_staff": int(building.get("assigned_staff", 0)),
			"local_inventory": Dictionary(building.get("local_inventory", {})).duplicate(true),
			"hp": int(building.get("hp", 0)),
		})
	building_state.sort_custom(func(first: Dictionary, second: Dictionary) -> bool: return int(first["id"]) < int(second["id"]))
	var worker_states: Dictionary = {}
	var cargo: Dictionary = {}
	for worker_value in simulation.workers:
		var worker: Dictionary = worker_value
		var state_key := "%s:%s" % [String(worker.get("type", "")), String(worker.get("state", ""))]
		worker_states[state_key] = int(worker_states.get(state_key, 0)) + 1
		var resource := String(worker.get("carried_resource", ""))
		if resource != "":
			cargo[resource] = int(cargo.get(resource, 0)) + int(worker.get("carried_amount", 0))
	var signature_data := {
		"tick": simulation.tick_number,
		"resources": simulation.get_resources(),
		"reserved": simulation.get_reserved_resources(),
		"population": simulation.population_current,
		"housing": simulation.housing_capacity,
		"hungry": simulation.hungry_population,
		"worker_states": worker_states,
		"cargo": cargo,
		"buildings": building_state,
		"enemies": simulation.enemies.size(),
		"projectiles": simulation.projectiles.size(),
	}
	return {
		"hash": JSON.stringify(signature_data).hash(),
		"state": signature_data,
	}


func _mean(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += value
	return total / float(values.size())


func _percentile(values: Array[float], ratio: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[clampi(ceili(float(sorted.size()) * ratio) - 1, 0, sorted.size() - 1)]
