extends SceneTree

# Black 20/10 gate: on the 320 province the deterministic rival AI (no player
# pressure) must win inside the designed 40-50 minute match window.
const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Tuning = preload("res://src/GodotClient/Scripts/one_shard_rivalry_tuning.gd")

const SEEDS := [515151, 260821, 424242]
const STRATEGIC_STEP := 0.5
const WINDOW_MIN_SECONDS := 2400.0
const WINDOW_MAX_SECONDS := 3000.0


func _init() -> void:
	var failures: Array[String] = []
	check(Tuning.max_lumen_pillars_for_map(Vector2i(70, 70)) == Tuning.MAX_LUMEN_PILLARS_PER_REALM, "rival Pillar cap is unchanged on 70x70", failures)
	check(Tuning.max_lumen_pillars_for_map(Vector2i(320, 320)) == 28, "rival Pillar cap scales to 28 on 320x320", failures)
	for seed_value in SEEDS:
		var simulation = Simulation.new(320, 320, seed_value, false, true)
		var rivalry = simulation.rivalry
		var phase_time := 0.0
		var is_night := false
		var seconds := 0.0
		var won := false
		while seconds < WINDOW_MAX_SECONDS + 600.0:
			seconds += STRATEGIC_STEP
			phase_time += STRATEGIC_STEP
			if not is_night and phase_time >= Simulation.DAY_LENGTH_SECONDS:
				is_night = true
				phase_time = 0.0
			elif is_night and phase_time >= Simulation.NIGHT_LENGTH_SECONDS:
				is_night = false
				phase_time = 0.0
			rivalry.advance(STRATEGIC_STEP, is_night, phase_time, Simulation.NIGHT_LENGTH_SECONDS)
			if rivalry.match_state == Tuning.MATCH_AI_VICTORY:
				won = true
				break
		print("RIVAL_320 seed=%d won=%s minutes=%.1f pillars=%d" % [seed_value, str(won), seconds / 60.0, rivalry._count_structures(Tuning.AI_REALM, Tuning.STRUCTURE_LUMEN_PILLAR)])
		check(won and seconds >= WINDOW_MIN_SECONDS and seconds <= WINDOW_MAX_SECONDS, "seed %d: rival AI wins on 320 within 40-50 min" % seed_value, failures)
	if failures.is_empty():
		print("RIVALRY_320_WIN PASS")
		quit(0)
	else:
		for failure in failures:
			print("FAIL: %s" % failure)
		print("RIVALRY_320_WIN FAIL (%d)" % failures.size())
		quit(1)


func check(condition: bool, label: String, failures: Array[String]) -> void:
	print("%s %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		failures.append(label)
