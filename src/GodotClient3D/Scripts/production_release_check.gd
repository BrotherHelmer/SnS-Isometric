extends RefCounted

## Explicit packaged-build diagnostic. Inactive during normal play.
const Catalog = preload("production_asset_catalog.gd")

static func run(game) -> void:
	var tree: SceneTree = game.get_tree()
	var failures: Array[String] = []
	var duration := 4.0
	var validation_save := ""
	var capture := "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--soak-seconds="):
			duration = maxf(4.0, float(arg.trim_prefix("--soak-seconds=")))
		if arg.begins_with("--validation-save="):
			validation_save = arg.trim_prefix("--validation-save=")
	_check(failures, Catalog.integrity_report().success, "all dynamic runtime models included")
	for path in ["res://tests", "res://artifacts", "res://phase1_3d_lab", "res://assets/settlement/founding", "res://src/Simulation"]:
		_check(failures, not DirAccess.dir_exists_absolute(path), "excluded " + path)
	_check(failures, game.startup_overlay.visible, "title menu opens")
	if capture:
		await tree.create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		tree.root.get_texture().get_image().save_png("user://release_menu.png")
	game._start_review_seed()
	if capture:
		await tree.create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		tree.root.get_texture().get_image().save_png("user://release_opening.png")
	if validation_save != "":
		_check(failures, game.simulation_host.load_from_path(validation_save), "load diagnostic settlement")
		game._initialize_presentation()
	game.simulation_host.paused = true
	_check(failures, game.save_game(), "packaged save")
	var seed: int = game.simulation_host.simulation.rng_seed
	game.start_new_3d(717171)
	_check(failures, game.load_game(), "packaged continue")
	_check(failures, game.simulation_host.simulation.rng_seed == seed, "restored saved realm")
	game.simulation_host.paused = false
	game.simulation_host.speed_multiplier = 4.0
	var elapsed := 0.0
	var cycle := 0
	var memory := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var peak_memory := memory
	var audio_samples: Array = []
	var started := Time.get_ticks_msec()
	while elapsed < duration:
		await tree.create_timer(minf(30.0, duration - elapsed)).timeout
		elapsed = float(Time.get_ticks_msec() - started) / 1000.0
		cycle += 1
		if AudioServer.get_driver_name() != "Dummy":
			var mix_age := AudioServer.get_time_since_last_mix()
			audio_samples.append({"seconds": elapsed, "seconds_since_mix": mix_age, "device": AudioServer.output_device})
			_check(failures, mix_age >= 0.0 and mix_age < 2.0, "audio mixer alive cycle %d" % cycle)
		_check(failures, game.save_game(), "save cycle %d" % cycle)
		_check(failures, game.load_game(), "continue cycle %d" % cycle)
		game._show_start_menu()
		_check(failures, game.simulation_host.paused, "menu pauses cycle %d" % cycle)
		game._resume_from_menu()
		if game.simulation_host.simulation.game_finished or cycle % 20 == 0:
			game.start_new_3d(260821 + cycle)
			if validation_save != "":
				_check(failures, game.simulation_host.load_from_path(validation_save), "reload diagnostic settlement")
				game._initialize_presentation()
		game.simulation_host.paused = false
		peak_memory = maxi(peak_memory, int(Performance.get_monitor(Performance.MEMORY_STATIC)))
		print("SOAK elapsed=%.1f cycle=%d memory=%d day=%d enemies=%d" % [elapsed, cycle, int(Performance.get_monitor(Performance.MEMORY_STATIC)), game.simulation_host.simulation.day_count, game.simulation_host.simulation.enemies.size()])
	var report := FileAccess.open("user://release_check.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"version": ProjectSettings.get_setting("application/config/version"), "duration_seconds": elapsed, "cycles": cycle, "baseline_memory": memory, "peak_memory": peak_memory, "audio_driver": AudioServer.get_driver_name(), "audio_samples": audio_samples, "failures": failures}, "\t"))
	report.close()
	print("RELEASE_PACKAGE_PROBE %s cycles=%d seconds=%.1f" % ["PASS" if failures.is_empty() else "FAIL", cycle, elapsed])
	game.queue_free()
	await tree.process_frame
	await tree.create_timer(0.5).timeout
	tree.quit(0 if failures.is_empty() else 1)

static func _check(failures: Array[String], ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
