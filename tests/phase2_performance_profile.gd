extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const DemoFixture = preload("res://src/GodotClient3D/Scripts/production_demo_fixture.gd")
const QualityProfile = preload("res://src/GodotClient3D/Scripts/production_quality_profile.gd")

const WARMUP_SECONDS := 1.0
const SAMPLE_SECONDS := 3.0

var actor_target := 6
var profile_name := "recommended"
var output_path := "res://artifacts/phase2/performance/recommended_6.json"
var capture_size := Vector2i(1920, 1080)
var simulation_live := false


func _init() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--actors="):
			actor_target = maxi(1, int(argument.trim_prefix("--actors=")))
		elif argument.begins_with("--quality="):
			profile_name = argument.trim_prefix("--quality=")
		elif argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")
		elif argument == "--live":
			simulation_live = true
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	call_deferred("_run")


func _run() -> void:
	root.size = capture_size
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(capture_size)
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	print("PHASE2_PROFILE_STAGE scene_ready actors=%d quality=%s" % [actor_target, profile_name])
	game.quality_profile = QualityProfile.get_profile(profile_name)
	game.fixture_result = DemoFixture.new().apply(game.simulation_host.simulation, "developed")
	if not bool(game.fixture_result.get("success", false)):
		push_error("Phase 2 performance fixture failed: %s" % game.fixture_result.get("report", []))
		quit(1)
		return
	_scale_authoritative_population(game, actor_target)
	game._initialize_presentation()
	game.simulation_host.paused = not simulation_live
	_apply_live_quality(game)
	game.camera_rig.set_zoom_preset("strategic")
	var warmup_start := Time.get_ticks_usec()
	var warmup_frames := 0
	while float(Time.get_ticks_usec() - warmup_start) / 1000000.0 < WARMUP_SECONDS:
		await process_frame
		warmup_frames += 1
	print("PHASE2_PROFILE_STAGE warmup_complete frames=%d seconds=%.1f" % [warmup_frames, WARMUP_SECONDS])
	var samples_ms: Array[float] = []
	var draw_calls: Array[int] = []
	var primitives: Array[int] = []
	var sample_start := Time.get_ticks_usec()
	var last_stamp := sample_start
	var frame := 0
	while float(Time.get_ticks_usec() - sample_start) / 1000000.0 < SAMPLE_SECONDS:
		await process_frame
		var now := Time.get_ticks_usec()
		samples_ms.append(float(now - last_stamp) / 1000.0)
		last_stamp = now
		draw_calls.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		primitives.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
		frame += 1
		if frame > 0 and frame % 300 == 0:
			print("PHASE2_PROFILE_STAGE sampled=%d" % frame)
	var sampled_seconds := float(Time.get_ticks_usec() - sample_start) / 1000000.0
	var metrics: Dictionary = game.world_view.presentation_metrics()
	var frame_mean := _mean_float(samples_ms)
	var result := {
		"phase": "Phase 2 production 3D migration",
		"method": "one-second warm-up followed by at least three rendered seconds, VSync disabled, developed deterministic fixture; simulation %s" % ["running" if simulation_live else "paused to isolate presentation scaling"],
		"renderer": "Forward+",
		"quality_profile": profile_name,
		"resolution": {"width": capture_size.x, "height": capture_size.y},
		"seed": int(game.simulation_host.simulation.rng_seed),
		"requested_authoritative_actors": actor_target,
		"displayed_authoritative_actors": int(metrics.get("real_workers", 0)),
		"active_job_actors": int(metrics.get("active_job_workers", 0)),
		"carrier_actors": _count_type(game.simulation_host.simulation.workers, "carrier"),
		"ambient_actors": 0,
		"simulation_running": simulation_live,
		"buildings": int(metrics.get("building_views", 0)),
		"road_cells": int(metrics.get("road_views", 0)),
		"nature_regions": int(metrics.get("nature_regions", 0)),
		"frames_sampled": samples_ms.size(),
		"sample_duration_seconds": snappedf(sampled_seconds, 0.001),
		"frame_ms_mean": snappedf(frame_mean, 0.001),
		"frame_ms_p95": snappedf(_percentile(samples_ms, 0.95), 0.001),
		"frame_ms_p99": snappedf(_percentile(samples_ms, 0.99), 0.001),
		"effective_fps_mean": snappedf(1000.0 / maxf(frame_mean, 0.001), 0.1),
		"draw_calls_mean": roundi(_mean_int(draw_calls)),
		"primitives_mean": roundi(_mean_int(primitives)),
		"video_memory_bytes": int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),
		"adapter_name": RenderingServer.get_video_adapter_name(),
		"adapter_vendor": RenderingServer.get_video_adapter_vendor(),
		"quality": game.quality_profile.duplicate(true),
	}
	var absolute_path := ProjectSettings.globalize_path(output_path)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		push_error("Unable to write Phase 2 performance result: %s" % absolute_path)
		quit(1)
		return
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("PHASE2_PROFILE_PASS actors=%d quality=%s mean_ms=%.3f p95_ms=%.3f fps=%.1f draw_calls=%d path=%s" % [
		int(metrics.get("real_workers", 0)), profile_name, frame_mean,
		float(result["frame_ms_p95"]), float(result["effective_fps_mean"]),
		int(result["draw_calls_mean"]), absolute_path,
	])
	game.queue_free()
	await process_frame
	quit(0)


func _scale_authoritative_population(game, target: int) -> void:
	var simulation = game.simulation_host.simulation
	var production_templates: Array[Dictionary] = []
	for worker in simulation.workers:
		if String(worker.get("type", "")) != "carrier":
			production_templates.append(Dictionary(worker).duplicate(true))
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


func _count_type(workers: Array, type_name: String) -> int:
	var count := 0
	for worker in workers:
		if String(worker.get("type", "")) == type_name:
			count += 1
	return count


func _apply_live_quality(game) -> void:
	var sun := game.lighting_rig.get_node_or_null("Sun") as DirectionalLight3D
	if sun != null:
		sun.shadow_enabled = bool(game.quality_profile.get("shadows", true))
		sun.directional_shadow_max_distance = float(game.quality_profile.get("shadow_distance", 170.0))


func _mean_float(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += value
	return total / float(values.size())


func _mean_int(values: Array[int]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += float(value)
	return total / float(values.size())


func _percentile(values: Array[float], ratio: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	var index := clampi(ceili(float(sorted.size()) * ratio) - 1, 0, sorted.size() - 1)
	return sorted[index]
