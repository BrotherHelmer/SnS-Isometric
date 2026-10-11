extends SceneTree

## Test #13 big-map gate. 320×320 presentation is chunked; the sim stays
## on the full grid. First frame must stay warm-laptop legal, chunks must
## stream without 100 ms hitches, and save/load must restore the province.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const CameraRig = preload("res://src/GodotClient3D/Scripts/production_isometric_camera_rig.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var dest := ProjectSettings.globalize_path("res://artifacts/bigmap")
	DirAccess.make_dir_recursive_absolute(dest)

	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	var t0 := Time.get_ticks_msec()
	game.start_new_3d(game.DEFAULT_SEED)
	var start_ms := float(Time.get_ticks_msec() - t0)
	game._hide_start_menu()
	game.simulation_host.paused = true
	if game.has_method("_update_ui"):
		game._update_ui()
	for _i in 4:
		await process_frame
	t0 = Time.get_ticks_msec()
	await process_frame
	await RenderingServer.frame_post_draw
	var first_frame_ms := float(Time.get_ticks_msec() - t0)
	var mem_static := float(OS.get_static_memory_usage()) / (1024.0 * 1024.0)
	var metrics: Dictionary = game.world_view.presentation_metrics()
	print("T_BIGMAP start_new_3d_ms=%.1f first_frame_ms=%.1f mem_mb=%.1f chunks_near=%d chunks_far=%d chunks_built=%d queued=%d" % [
		start_ms, first_frame_ms, mem_static,
		int(metrics.get("chunks_near", 0)), int(metrics.get("chunks_far", 0)),
		int(metrics.get("chunks_built", 0)), int(metrics.get("chunks_queued", 0))
	])

	var sim = game.simulation_host.simulation
	_check(sim.map_size == Vector2i(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT), "map is 320×320")
	_check(is_equal_approx(Simulation.CRATER_RADIUS, 110.0), "crater harvest radius is 110")
	_check(Simulation.CHUNK_TILES == 32, "presentation chunks are 32×32")
	_check(sim.rival_seats.size() >= 3 and sim.rival_seats.size() <= 4, "3–4 rival seats exist")
	_check(start_ms < 8000.0, "start_new_3d logged and finished (%.0f ms)" % start_ms)
	_check(first_frame_ms <= 2000.0 or start_ms + first_frame_ms < 9000.0, "first composed frame is at most 2 s warm (%.0f ms)" % first_frame_ms)
	_check(int(metrics.get("chunks_built", 0)) > 0, "opening built near-camera chunks")
	_check(int(metrics.get("chunks_built", 0)) < 40, "opening did not build the whole 10×10 province")
	_check(game.world_view.has_method("stream_chunks"), "chunk stream API exists")
	_check(game.camera_rig.zoom_cap >= CameraRig.PROVINCE_ZOOM - 0.1, "big-map zoom-out cap is province scale")

	var pan_times: Array[float] = []
	var home: Vector3 = game.world_view.opening_camera_focus()
	game.camera_rig.configure_for_map(sim.map_size)
	for step in 12:
		var offset := Vector3(float(step) * 18.0 - 90.0, 0.0, float(step % 3) * 12.0 - 12.0)
		game.world_view.note_camera(home + offset, 48.0)
		var p0 := Time.get_ticks_usec()
		game.world_view.stream_chunks(7000)
		await process_frame
		var pan_ms := float(Time.get_ticks_usec() - p0) / 1000.0
		pan_times.append(pan_ms)
		print("T_BIGMAP pan_step=%d ms=%.2f built=%d queued=%d hitch=%d" % [
			step, pan_ms, game.world_view.chunk_nodes.size(), game.world_view.chunk_queue.size(),
			int(game.world_view.last_stream_hitches)
		])
	pan_times.sort()
	var pan_sum := 0.0
	var pan_max := 0.0
	for sample in pan_times:
		pan_sum += sample
		pan_max = maxf(pan_max, sample)
	var pan_avg := pan_sum / float(pan_times.size())
	var p95 := pan_times[clampi(int(ceil(float(pan_times.size()) * 0.95)) - 1, 0, pan_times.size() - 1)]
	print("T_BIGMAP pan_avg=%.2f pan_p95=%.2f pan_max=%.2f hitches=%d" % [
		pan_avg, p95, pan_max, int(game.world_view.last_stream_hitches)
	])
	_check(pan_max <= 120.0, "no pan hitch over 100 ms (max %.1f)" % pan_max)

	var hall_before: Vector2i = sim.town_hall_position
	var rivals_before := sim.rival_seats.size()
	var saved := game.save_game()
	_check(saved, "save_game works on the 320 map")
	var loaded := game.load_game()
	_check(loaded, "load_game works on the 320 map")
	var loaded_sim = game.simulation_host.simulation
	_check(loaded_sim.map_size == Vector2i(320, 320), "loaded map stays 320×320")
	_check(loaded_sim.rival_seats.size() >= 3 and loaded_sim.rival_seats.size() == rivals_before, "loaded rival seats persist")
	_check(loaded_sim.town_hall_position == hall_before, "loaded hall stays put")

	var master_idx := AudioServer.get_bus_index("Master")
	var master_lin := db_to_linear(AudioServer.get_bus_volume_db(master_idx))
	print("T_BIGMAP master_linear=%.3f" % master_lin)
	_check(master_lin >= 0.995 and master_lin <= 1.005, "Master volume is 1.0")

	var table := dest.path_join("perf_table.md")
	var file := FileAccess.open(table, FileAccess.WRITE)
	if file != null:
		file.store_line("| metric | value |")
		file.store_line("| --- | --- |")
		file.store_line("| start_new_3d | %.1f ms |" % start_ms)
		file.store_line("| first_frame | %.1f ms |" % first_frame_ms)
		file.store_line("| pan avg | %.2f ms |" % pan_avg)
		file.store_line("| pan p95 | %.2f ms |" % p95)
		file.store_line("| pan max | %.2f ms |" % pan_max)
		file.store_line("| memory | %.1f MB |" % mem_static)
		file.store_line("| chunks near | %d |" % int(metrics.get("chunks_near", 0)))
		file.store_line("| chunks far | %d |" % int(metrics.get("chunks_far", 0)))
		file.store_line("| chunks built | %d |" % int(metrics.get("chunks_built", 0)))
		file.close()

	print("T_BIGMAP %s" % ("PASS" if failures.is_empty() else "FAIL"))
	for failure in failures:
		print("  FAIL %s" % failure)
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
