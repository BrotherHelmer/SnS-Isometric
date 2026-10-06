extends RefCounted

## Access-1 built-in benchmark. Measures wall-clock frame time and GPU time.
## The Director: TIME_PROCESS stays in the CSV for continuity; it is not frame time.

const QualityProfile = preload("res://src/GodotClient3D/Scripts/production_quality_profile.gd")

const PACKED_SAVE := "res://src/GodotClient3D/Data/eighteen_step_playthrough.json"
const DEV_SAVE := "res://artifacts/phase3_2/persistence/eighteen_step_playthrough.json"
const PRESETS := ["low", "medium", "high"]
const PERIODS := ["day", "dusk", "night"]
const DEFAULT_WARM := 8
const DEFAULT_SAMPLE := 120

var last_csv_path := ""
var last_rows: Array = []
var last_save_used := ""


static func requested_from(launch: Dictionary) -> bool:
	if bool(launch.get("benchmark", false)):
		return true
	return OS.get_environment("SNS_BENCHMARK") == "1"


static func frame_override() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--benchmark-frames="):
			return maxi(1, int(argument.trim_prefix("--benchmark-frames=")))
	var env := OS.get_environment("SNS_BENCHMARK_FRAMES")
	if env.is_valid_int():
		return maxi(1, int(env))
	return 0


static func resolve_save_path() -> String:
	if ResourceLoader.exists(PACKED_SAVE) or FileAccess.file_exists(PACKED_SAVE):
		return PACKED_SAVE
	if FileAccess.file_exists(DEV_SAVE):
		return DEV_SAVE
	return ""


func run(game, quit_after := true, warm_frames := DEFAULT_WARM, sample_frames := DEFAULT_SAMPLE) -> String:
	var override := frame_override()
	if override > 0:
		sample_frames = override
		warm_frames = mini(warm_frames, 2)
	last_rows.clear()
	last_csv_path = ""
	if game == null:
		return ""
	_prepare_scene(game)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var viewport: Viewport = game.get_viewport()
	var rid := viewport.get_viewport_rid() if viewport != null else RID()
	if rid.is_valid():
		RenderingServer.viewport_set_measure_render_time(rid, true)
	var tree: SceneTree = game.get_tree()
	for preset in PRESETS:
		game.apply_quality_profile(preset)
		for period in PERIODS:
			_compose_period(game, period)
			await _sample(tree, rid, preset, period, warm_frames, sample_frames)
	last_csv_path = _write_csv()
	print("ACCESS_BENCHMARK csv=%s rows=%d save=%s" % [last_csv_path, last_rows.size(), last_save_used])
	if quit_after and tree != null:
		tree.quit(0)
	return last_csv_path


func _prepare_scene(game) -> void:
	var save_path := resolve_save_path()
	last_save_used = save_path
	if save_path != "" and game.simulation_host != null:
		if game.simulation_host.load_from_path(save_path):
			game._initialize_presentation()
		else:
			last_save_used = "new:%d" % int(game.DEFAULT_SEED)
			game.start_new_3d(game.DEFAULT_SEED)
	else:
		last_save_used = "new:%d" % int(game.DEFAULT_SEED)
		game.start_new_3d(game.DEFAULT_SEED)
	if game.has_method("_hide_start_menu"):
		game._hide_start_menu()
	if game.simulation_host != null:
		game.simulation_host.paused = true
	if game.has_method("set_process"):
		game.set_process(false)
	_compose_gate_camera(game)


func _compose_gate_camera(game) -> void:
	if game.simulation_host == null or game.world_view == null or game.camera_rig == null:
		return
	var sim = game.simulation_host.simulation
	var home: Vector3 = game.world_view.tile_to_world(Vector2(sim.town_hall_position) + Vector2(1.5, 1.5))
	game.camera_rig.compose_view(home, 34.0)


func _compose_period(game, period: String) -> void:
	var sim = game.simulation_host.simulation
	match period:
		"dusk":
			sim.is_night = false
			sim.phase_time = float(sim.DAY_LENGTH_SECONDS) - 6.0
		"night":
			sim.is_night = true
			sim.phase_time = 20.0
		_:
			sim.is_night = false
			sim.phase_time = 80.0
	if game.has_method("_update_day_night_lighting"):
		game._update_day_night_lighting()
	if game.has_method("_sync_presentation"):
		game._sync_presentation()
	_compose_gate_camera(game)


func _sample(tree: SceneTree, rid: RID, preset: String, period: String, warm_frames: int, sample_frames: int) -> void:
	for _warm in warm_frames:
		await tree.process_frame
	var walls: Array[float] = []
	var gpus: Array[float] = []
	var cpus: Array[float] = []
	var processes: Array[float] = []
	for _i in sample_frames:
		var t0 := Time.get_ticks_usec()
		await tree.process_frame
		var wall_ms := float(Time.get_ticks_usec() - t0) / 1000.0
		walls.append(wall_ms)
		processes.append(float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0)
		if rid.is_valid():
			gpus.append(RenderingServer.viewport_get_measured_render_time_gpu(rid))
			cpus.append(RenderingServer.viewport_get_measured_render_time_cpu(rid))
		else:
			gpus.append(0.0)
			cpus.append(0.0)
	last_rows.append(_summarize(preset, period, walls, gpus, cpus, processes))


func _summarize(preset: String, period: String, walls: Array[float], gpus: Array[float], cpus: Array[float], processes: Array[float]) -> Dictionary:
	var wall_avg := _avg(walls)
	return {
		"preset": preset,
		"period": period,
		"frames": walls.size(),
		"wall_avg_ms": wall_avg,
		"wall_p95_ms": _percentile(walls, 0.95),
		"wall_fps": 1000.0 / maxf(wall_avg, 0.001),
		"gpu_avg_ms": _avg(gpus),
		"gpu_p95_ms": _percentile(gpus, 0.95),
		"cpu_avg_ms": _avg(cpus),
		"cpu_p95_ms": _percentile(cpus, 0.95),
		"process_avg_ms": _avg(processes),
		"process_p95_ms": _percentile(processes, 0.95),
	}


func _write_csv() -> String:
	var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var folder := "user://benchmark"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var path := "%s/benchmark_%s.csv" % [folder, stamp]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return ""
	var size := DisplayServer.window_get_size()
	var adapter := RenderingServer.get_video_adapter_name()
	var driver := "%s/%s" % [OS.get_current_rendering_method(), OS.get_current_rendering_driver_name()]
	var mode := "windowed"
	match DisplayServer.window_get_mode():
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			mode = "fullscreen"
		DisplayServer.WINDOW_MODE_FULLSCREEN:
			mode = "borderless"
	file.store_line("preset,period,frames,wall_avg_ms,wall_p95_ms,wall_fps,gpu_avg_ms,gpu_p95_ms,cpu_avg_ms,cpu_p95_ms,process_avg_ms,process_p95_ms,adapter,driver,resolution,window_mode,save")
	for row in last_rows:
		file.store_line("%s,%s,%d,%.3f,%.3f,%.2f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%s,%s,%dx%d,%s,%s" % [
			row["preset"], row["period"], int(row["frames"]),
			row["wall_avg_ms"], row["wall_p95_ms"], row["wall_fps"],
			row["gpu_avg_ms"], row["gpu_p95_ms"],
			row["cpu_avg_ms"], row["cpu_p95_ms"],
			row["process_avg_ms"], row["process_p95_ms"],
			adapter.replace(",", " "), driver,
			size.x, size.y, mode, last_save_used,
		])
	file.close()
	return path


func _avg(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += value
	return total / float(values.size())


func _percentile(values: Array[float], fraction: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	var index := clampi(int(ceil(float(sorted.size()) * fraction)) - 1, 0, sorted.size() - 1)
	return sorted[index]
