extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var failures: Array[String] = []
	if game.audio_director == null:
		failures.append("audio director missing")
	else:
		game._show_start_menu()
		game._tick_audio(0.4)
		_expect_state(game, "menu", failures)
		_expect_stem(game, "day", failures)
		game.start_new_3d(game.DEFAULT_SEED)
		var simulation = game.simulation_host.simulation
		simulation.phase_time = 40.0
		simulation.is_night = false
		game._tick_audio(0.4)
		_expect_state(game, "day", failures)
		_expect_stem(game, "day", failures)
		_expect_stem(game, "ambience", failures)
		simulation.phase_time = simulation.DAY_LENGTH_SECONDS - 20.0
		game._tick_audio(0.4)
		_expect_state(game, "dusk", failures)
		_expect_stem(game, "dusk", failures)
		simulation.is_night = true
		simulation.phase_time = 20.0
		game._tick_audio(0.4)
		_expect_state(game, "night", failures)
		_expect_stem(game, "night", failures)
		_expect_stem(game, "wyrd", failures)
		simulation.enemies.clear()
		simulation.day_count = 2
		simulation._spawn_wave()
		game._tick_audio(0.4)
		_expect_state(game, "raid", failures)
		_expect_stem(game, "raid", failures)
		print("PHASE42_AUDIO_EVIDENCE %s" % JSON.stringify(game.audio_director.evidence_snapshot()))
	if failures.is_empty():
		print("PHASE42_AUDIO_EVIDENCE PASS")
		quit(0)
	else:
		push_error("PHASE42_AUDIO_EVIDENCE FAIL %s" % "; ".join(failures))
		quit(1)


func _expect_state(game, expected: String, failures: Array[String]) -> void:
	var actual := String(game.audio_director.current_state)
	if actual != expected:
		failures.append("expected %s got %s" % [expected, actual])
	print("PHASE42_AUDIO_STATE %s stems=%s" % [actual, ",".join(game.audio_director.evidence_snapshot().get("stems", []))])


func _expect_stem(game, stem_name: String, failures: Array[String]) -> void:
	var stems: Array = game.audio_director.evidence_snapshot().get("stems", [])
	if not stems.has(stem_name):
		failures.append("missing stem %s" % stem_name)
