extends SceneTree

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Wyrdfall = preload("res://src/GodotClient/Scripts/one_shard_wyrdfall.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Tuning = preload("res://src/GodotClient/Scripts/one_shard_rivalry_tuning.gd")


func _init() -> void:
	var failures: Array[String] = []
	var quiet := Wyrdfall.compute_pressure({
		"cumulative_wyrd_extracted": 0,
		"active_wyrd_outposts": 0,
		"shard_control": 0.0,
		"binding_progress": 0.0,
		"player_binding": false,
		"day_count": 1
	})
	check(String(quiet.get("band", "")) == Wyrdfall.BAND_QUIET and float(quiet.get("value", 99.0)) < 20.0, "an unexpanded settlement stays QUIET", failures)

	var late_conservative := Wyrdfall.compute_pressure({
		"cumulative_wyrd_extracted": 0,
		"active_wyrd_outposts": 0,
		"shard_control": 0.0,
		"day_count": 8
	})
	check(float(late_conservative.get("value", 0.0)) <= 12.0, "passing days are only a mild baseline", failures)

	var exploited := Wyrdfall.compute_pressure({
		"cumulative_wyrd_extracted": 18,
		"active_wyrd_outposts": 2,
		"shard_control": 1.0,
		"day_count": 3
	})
	check(float(exploited.get("value", 0.0)) > float(late_conservative.get("value", 0.0)) + 20.0, "Wyrd exploitation dominates pressure versus time", failures)
	check(String(exploited.get("band", "")) in [Wyrdfall.BAND_DANGEROUS, Wyrdfall.BAND_SEVERE, Wyrdfall.BAND_CRITICAL], "heavy extraction reads as dangerous or worse", failures)

	var binding := Wyrdfall.compute_pressure({
		"cumulative_wyrd_extracted": 8,
		"active_wyrd_outposts": 1,
		"shard_control": 1.0,
		"player_binding": true,
		"binding_progress": 0.2,
		"day_count": 4
	})
	check(String(binding.get("band", "")) == Wyrdfall.BAND_CRITICAL, "Binding forces CRITICAL pressure", failures)

	var first_plan := Wyrdfall.wave_plan(0.0, 1, true, false)
	var later_plan := Wyrdfall.wave_plan(float(exploited.get("value", 50.0)), 4, false, false)
	check(int(first_plan.get("size", 0)) == 2, "first night is two raiders", failures)
	check(int(later_plan.get("size", 0)) > int(first_plan.get("size", 0)), "high-pressure nights are measurably larger than the first night", failures)

	var simulation = Simulation.new(70, 70, 260821, false, true)
	check(_count_tile(simulation, Defs.TILE_SHARD) == 1, "each map has exactly one central Shard", failures)
	check(simulation.impact_factor(simulation.shard_position) >= 0.99, "the Shard sits in a generated impact zone", failures)
	var pressure := simulation.get_wyrd_pressure()
	check(String(pressure.get("band", "")) == Wyrdfall.BAND_QUIET, "a new founded realm starts QUIET", failures)
	var objective: Dictionary = simulation.get_macro_objective()
	check(String(objective.get("id", "")) in [Wyrdfall.OBJECTIVE_SURVIVE, Wyrdfall.OBJECTIVE_REACH], "opening macro objective is Survive or Reach", failures)

	simulation.cumulative_wyrd_extracted = 16
	simulation.day_count = 4
	simulation._spawn_wave()
	var high_count: int = simulation.enemies.size()
	simulation.enemies.clear()
	simulation.cumulative_wyrd_extracted = 0
	simulation.day_count = 1
	simulation._spawn_wave()
	var first_count: int = simulation.enemies.size()
	check(high_count > first_count, "the same settlement faces a larger raid after exploiting Wyrd", failures)

	simulation.population_current = 0
	simulation._check_population_defeat()
	check(simulation.game_finished and not simulation.victory, "population collapse is a clear defeat", failures)

	var bind_sim = Simulation.new(70, 70, 717171, false, true)
	_configure_ready_claim(bind_sim, bind_sim.rivalry, Tuning.PLAYER_REALM)
	var begin := bind_sim.request_begin_binding()
	check(bool(begin.get("success", false)) and bind_sim.reckoning_active, "explicit Binding starts the Reckoning", failures)
	bind_sim.rivalry._update_claims(Wyrdfall.BINDING_DURATION_SECONDS, true, 0.0, Simulation.NIGHT_LENGTH_SECONDS)
	check(bind_sim.victory and bind_sim.game_finished, "held Binding completes player victory", failures)

	var rival_sim = Simulation.new(70, 70, 818181, false, true)
	_configure_ready_claim(rival_sim, rival_sim.rivalry, Tuning.AI_REALM)
	rival_sim.rivalry.elapsed_seconds = Tuning.AI_CLAIM_UNLOCK_SECONDS + 1.0
	var rival_begin: Dictionary = rival_sim.rivalry.request_begin_claim(Tuning.AI_REALM)
	check(bool(rival_begin.get("success", false)), "the rival can begin Binding when ready", failures)
	rival_sim.rivalry._update_claims(Wyrdfall.BINDING_DURATION_SECONDS, false, 0.0, Simulation.DAY_LENGTH_SECONDS)
	check(rival_sim.game_finished and not rival_sim.victory, "rival Binding first is a player defeat", failures)

	var save_sim = Simulation.new(70, 70, 260821, false, true)
	save_sim.cumulative_wyrd_extracted = 9
	save_sim.peak_wyrd_pressure = 44.0
	save_sim.shard_contacted = true
	var saved: Dictionary = save_sim._serialize_state()
	check(int(saved.get("version", 0)) == Simulation.SAVE_VERSION, "Wyrdfall state uses save schema 8", failures)
	var restored = Simulation.new(70, 70, 1, false)
	restored._restore_state(saved)
	check(
		restored.cumulative_wyrd_extracted == 9
		and is_equal_approx(restored.peak_wyrd_pressure, 44.0)
		and restored.shard_contacted,
		"save/load restores pressure-relevant Wyrdfall state",
		failures
	)

	if failures.is_empty():
		print("PHASE4_WYRDFALL_SMOKE PASS")
		quit(0)
	else:
		for failure in failures:
			print("FAIL: %s" % failure)
		print("PHASE4_WYRDFALL_SMOKE FAIL (%d)" % failures.size())
		quit(1)


func check(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(label)


func _count_tile(simulation, tile_type: String) -> int:
	var count := 0
	for y in range(simulation.map_size.y):
		for x in range(simulation.map_size.x):
			if String(simulation.map_tiles[y][x]) == tile_type:
				count += 1
	return count


func _configure_ready_claim(simulation, rivalry, realm_id: String) -> void:
	var realm: Dictionary = rivalry.realms[realm_id]
	var entrance: Vector2i = realm["entrance"]
	var outpost_anchor: Vector2i = simulation.shard_position + (Vector2i(3, -1) if realm_id == Tuning.AI_REALM else Vector2i(-4, 0))
	var road_target: Vector2i = outpost_anchor + (Vector2i.RIGHT if realm_id == Tuning.AI_REALM else Vector2i.LEFT)
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
	if realm_id == Tuning.AI_REALM:
		rivalry.get_sovereign(realm_id)["position"] = Vector2(simulation.shard_position)
