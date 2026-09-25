extends SceneTree

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var report: Array[String] = []
	var failures: Array[String] = []
	var packed_scene: PackedScene = load("res://src/GodotClient/Scenes/main.tscn")
	var view = packed_scene.instantiate()
	root.add_child(view)
	await process_frame

	_check(view.main_menu_root != null and view.main_menu_root.visible, "launch opens the release main menu", report, failures)
	_check(not view.game_started, "simulation waits behind the main menu", report, failures)
	_check(view.how_to_card != null and view.settings_card != null, "How to Play and Settings are available", report, failures)
	_check(view.pause_menu_root != null, "pause menu is present", report, failures)

	view._start_new_demo()
	await process_frame
	_check(view.game_started and not view.main_menu_root.visible, "Play Demo starts the authored presentation run", report, failures)
	_check(view.simulation.is_town_hall_founded(), "New Game begins with a completed Town Hall", report, failures)
	_check(view.current_mode == view.MODE_SELECT, "the opening begins in Select rather than Town Hall placement", report, failures)
	_check(view.simulation.get_workers().size() == 1, "the opening contains exactly one settler", report, failures)
	_check(view.command_dock != null and view.info_panel == null, "the left command dock replaces the permanent terrain inspector", report, failures)

	view._cycle_speed()
	var speed_two := is_equal_approx(view.simulation_speed, 2.0)
	view._cycle_speed()
	var speed_four := is_equal_approx(view.simulation_speed, 4.0)
	view._cycle_speed()
	var speed_one := is_equal_approx(view.simulation_speed, 1.0)
	_check(speed_two and speed_four and speed_one, "speed control cycles 1x, 2x, and 4x", report, failures)

	var simulation = view.simulation
	simulation.start_new_run(70, 70, 919191, true)
	simulation.day_count = 2
	simulation.enemies.clear()
	simulation._spawn_wave()
	var roles := {}
	for enemy in simulation.enemies:
		roles[String(enemy.get("enemy_type", ""))] = true
	_check(
		roles.has(Simulation.ENEMY_RAIDER)
		and roles.has(Simulation.ENEMY_SKITTERER)
		and roles.has(Simulation.ENEMY_BRUTE)
		and roles.has(Simulation.ENEMY_HEXER),
		"second-night roster contains raider, skitterer, brute, and hexer roles",
		report,
		failures
	)
	var skitterer := _first_enemy(simulation.enemies, Simulation.ENEMY_SKITTERER)
	var brute := _first_enemy(simulation.enemies, Simulation.ENEMY_BRUTE)
	var hexer := _first_enemy(simulation.enemies, Simulation.ENEMY_HEXER)
	_check(
		float(skitterer.get("speed_multiplier", 1.0)) < 1.0
		and float(brute.get("speed_multiplier", 1.0)) > 1.0
		and int(hexer.get("attack_range", 1)) >= 4,
		"enemy roles have distinct movement and attack profiles",
		report,
		failures
	)

	view._open_pause_menu()
	_check(view.paused and view.pause_menu_root.visible, "pause menu stops the match", report, failures)
	view._return_to_main_menu()
	_check(not view.game_started and view.main_menu_root.visible, "return to main menu is clean", report, failures)

	for line in report:
		print(line)
	if failures.is_empty():
		print("RELEASE_SMOKE PASS")
		view.queue_free()
		await process_frame
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("RELEASE_SMOKE FAIL (%d)" % failures.size())
		view.queue_free()
		await process_frame
		quit(1)


func _first_enemy(enemies: Array, enemy_type: String) -> Dictionary:
	for enemy in enemies:
		if String(enemy.get("enemy_type", "")) == enemy_type:
			return enemy
	return {}


func _check(condition: bool, label: String, report: Array[String], failures: Array[String]) -> void:
	report.append("%s %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		failures.append(label)
