extends SceneTree

## Night audio: the falling-sweep scream cue must not retrigger every few
## seconds, and dusk tension must not sit under the night bed.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	if game.audio_director == null:
		failures.append("audio director missing")
		_finish(game)
		return
	var director = game.audio_director
	game.start_new_3d(game.DEFAULT_SEED)
	var sim = game.simulation_host.simulation
	sim.day_count = 2
	sim.is_night = false
	sim.phase_time = 40.0
	sim.enemies.clear()
	_ticks(game, 3)

	sim.is_night = true
	sim.phase_time = 20.0
	sim.last_combat_elapsed = -1000.0
	_ticks(game, 4)
	_check(String(director.current_state) == "night", "calm night state")
	var night_stems: Array = director.evidence_snapshot().get("stems", [])
	_check(night_stems.has("night"), "night bed stays audible")
	_check(not night_stems.has("dusk"), "dusk tension is not layered under night")

	# 25 s of night is two old scream periods (10 s). One scare is allowed.
	_ticks(game, 63)
	var screams := int(director.screams_played)
	print("NIGHT_AUDIO screams=%d cooldown=%.1f stems=%s" % [
		screams, float(director.scream_cooldown), ",".join(night_stems)
	])
	_check(screams <= 1, "scream sweep plays at most once per night")
	_check(float(director.scream_cooldown) < 0.0 or screams == 0, "scream timer does not re-arm")

	# Entering combat must not start a 5.5 s scream loop.
	sim._spawn_enemy(sim.town_hall_position + Vector2i(2, 0), 8, 1, 0.0, 0, sim.ENEMY_RAIDER)
	sim.last_combat_elapsed = sim.elapsed_seconds
	_ticks(game, 20)
	var screams_after_raid := int(director.screams_played)
	print("NIGHT_AUDIO after_raid screams=%d state=%s" % [screams_after_raid, director.current_state])
	_check(screams_after_raid <= 1, "raid does not retrigger the sweep")
	_finish(game)


func _ticks(game, count: int) -> void:
	for _i in count:
		game._tick_audio(0.4)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)


func _finish(game) -> void:
	game.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	print("T_NIGHT_AUDIO_SWEEP %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)
