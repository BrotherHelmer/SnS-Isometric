extends SceneTree

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Tuning = preload("res://src/GodotClient/Scripts/one_shard_rivalry_tuning.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")


func _init() -> void:
	var day := _sample_phase("day", func(simulation):
		simulation.is_night = false
		simulation.phase_time = 40.0
	)
	var night := _sample_phase("night", func(simulation):
		simulation.day_count = 4
		simulation.cumulative_wyrd_extracted = 16
		simulation.is_night = true
		simulation.phase_time = 20.0
		simulation._spawn_wave()
	)
	var reckoning := _sample_phase("reckoning", func(simulation):
		simulation.day_count = 5
		simulation.cumulative_wyrd_extracted = 20
		_configure_ready_claim(simulation, simulation.rivalry, Tuning.PLAYER_REALM)
		simulation.request_begin_binding()
		simulation.is_night = true
		simulation.phase_time = 10.0
	)
	print("PHASE4_PERF day_avg_ms=%.3f night_avg_ms=%.3f reckoning_avg_ms=%.3f ticks=80" % [
		float(day.get("tick_average_ms", 0.0)),
		float(night.get("tick_average_ms", 0.0)),
		float(reckoning.get("tick_average_ms", 0.0))
	])
	print("PHASE4_PERF_SAMPLE PASS")
	quit(0)


func _sample_phase(label: String, setup: Callable) -> Dictionary:
	var simulation = Simulation.new(70, 70, 260821, false, true)
	setup.call(simulation)
	simulation.set_performance_profiling(true, true)
	for _tick in range(80):
		simulation.advance_tick()
	var report: Dictionary = simulation.get_performance_profile()
	print("PHASE4_PERF_PHASE %s avg_ms=%.3f p95_ms=%.3f max_ms=%.3f enemies=%d" % [
		label,
		float(report.get("tick_average_ms", 0.0)),
		float(report.get("tick_p95_ms", 0.0)),
		float(report.get("tick_max_ms", 0.0)),
		simulation.enemies.size()
	])
	return report


func _configure_ready_claim(simulation, rivalry, realm_id: String) -> void:
	var realm: Dictionary = rivalry.realms[realm_id]
	var entrance: Vector2i = realm["entrance"]
	var outpost_anchor: Vector2i = simulation.shard_position + Vector2i(-4, 0)
	var road_target: Vector2i = outpost_anchor + Vector2i.LEFT
	var current := entrance
	while current.x != road_target.x:
		current += Vector2i(1 if road_target.x > current.x else -1, 0)
		realm["roads"][rivalry._key(current)] = true
	while current.y != road_target.y:
		current += Vector2i(0, 1 if road_target.y > current.y else -1)
		realm["roads"][rivalry._key(current)] = true
	var home_center: Vector2 = rivalry._home_center(realm_id)
	for fraction in [0.18, 0.36, 0.54, 0.72, 0.88]:
		var pillar_position: Vector2i = Vector2i(home_center.lerp(Vector2(simulation.shard_position), float(fraction)))
		var pillar: Dictionary = {
			"id": rivalry.next_structure_id,
			"realm_id": realm_id,
			"type": Tuning.STRUCTURE_LUMEN_PILLAR,
			"position": pillar_position,
			"footprint": Vector2i.ONE,
			"hp": 90,
			"max_hp": 90,
			"active": true,
			"connected": true,
			"damage_flash": 0.0
		}
		rivalry.next_structure_id += 1
		rivalry.structures.append(pillar)
		realm["structures"].append(pillar["id"])
	var outpost: Dictionary = {
		"id": rivalry.next_structure_id,
		"realm_id": realm_id,
		"type": Tuning.STRUCTURE_CLAIMANT_OUTPOST,
		"position": outpost_anchor,
		"footprint": Vector2i(2, 2),
		"hp": 220,
		"max_hp": 220,
		"active": true,
		"connected": true,
		"damage_flash": 0.0
	}
	rivalry.next_structure_id += 1
	rivalry.structures.append(outpost)
	realm["structures"].append(outpost["id"])
	realm["claim"]["outpost_id"] = outpost["id"]
	rivalry.get_resources(realm_id)[Defs.RESOURCE_WYRD] = 100
