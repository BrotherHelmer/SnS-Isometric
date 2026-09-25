extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Fixture = preload("res://src/GodotClient3D/Scripts/production_demo_fixture.gd")
const QualityProfile = preload("res://src/GodotClient3D/Scripts/production_quality_profile.gd")

const BASE_SAVE := "res://artifacts/phase3_2/persistence/eighteen_step_playthrough.json"
const WARMUP_SECONDS := 3.0
const WARMUP_FRAMES := 120
const SAMPLE_SECONDS := 30.0
const CAPTURE_SIZE := Vector2i(1920, 1080)

var civilian_target := 100
var hostile_target := 20
var profile_name := "recommended"
var output_path := "res://artifacts/phase3/performance/mixed_recommended_100c_20h.json"
var disable_fog_for_diagnostic := false
var pause_authority_for_diagnostic := false
var hide_roads_for_diagnostic := false
var hide_characters_for_diagnostic := false
var hide_workers_for_diagnostic := false
var hide_combatants_for_diagnostic := false
var pause_animation_for_diagnostic := false


func _init() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--civilians="):
			civilian_target = maxi(1, int(argument.trim_prefix("--civilians=")))
		elif argument.begins_with("--hostiles="):
			hostile_target = maxi(1, int(argument.trim_prefix("--hostiles=")))
		elif argument.begins_with("--quality="):
			profile_name = argument.trim_prefix("--quality=")
		elif argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")
		elif argument == "--disable-fog":
			disable_fog_for_diagnostic = true
		elif argument == "--pause-authority":
			pause_authority_for_diagnostic = true
		elif argument == "--hide-roads":
			hide_roads_for_diagnostic = true
		elif argument == "--hide-characters":
			hide_characters_for_diagnostic = true
		elif argument == "--hide-workers":
			hide_workers_for_diagnostic = true
		elif argument == "--hide-combatants":
			hide_combatants_for_diagnostic = true
		elif argument == "--pause-animation":
			pause_animation_for_diagnostic = true
	Engine.max_fps = 240
	OS.low_processor_usage_mode = false
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	call_deferred("_run")


func _run() -> void:
	root.size = CAPTURE_SIZE
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(CAPTURE_SIZE)
		DisplayServer.window_move_to_foreground()
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	if not game.simulation_host.load_from_path(BASE_SAVE):
		push_error("Mixed profile requires the real-game playthrough save.")
		quit(1)
		return
	game.quality_profile = QualityProfile.get_profile(profile_name)
	game._hide_start_menu()
	var simulation = game.simulation_host.simulation
	_scale_population(simulation, civilian_target)
	_spawn_mixed_hostiles(simulation, hostile_target)
	_start_construction(simulation)
	simulation.set_performance_profiling(true)
	game._initialize_presentation()
	if disable_fog_for_diagnostic:
		game.world_view.fog_root.visible = false
	if hide_roads_for_diagnostic:
		game.world_view.roads_root.visible = false
		game.world_view.rival_roads_root.visible = false
	if hide_characters_for_diagnostic:
		game.world_view.characters_root.visible = false
		game.world_view.combatants_root.visible = false
	if hide_workers_for_diagnostic:
		game.world_view.characters_root.visible = false
	if hide_combatants_for_diagnostic:
		game.world_view.combatants_root.visible = false
	if pause_animation_for_diagnostic:
		game.world_view.set_presentation_paused(true)
	game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(simulation.town_hall_position) + Vector2(2.0, 2.0)), 48.0)
	game.simulation_host.paused = pause_authority_for_diagnostic
	_apply_quality(game)
	var warmup_start := Time.get_ticks_usec()
	var warmup_frames := 0
	var requested_warmup_frames := 30 if pause_authority_for_diagnostic else WARMUP_FRAMES
	while float(Time.get_ticks_usec() - warmup_start) / 1000000.0 < WARMUP_SECONDS or warmup_frames < requested_warmup_frames:
		await process_frame
		warmup_frames += 1
	var frame_samples: Array[float] = []
	var draw_samples: Array[int] = []
	var primitive_samples: Array[int] = []
	var process_samples: Array[float] = []
	var physics_samples: Array[float] = []
	var sample_start := Time.get_ticks_usec()
	var last_stamp := sample_start
	while float(Time.get_ticks_usec() - sample_start) / 1000000.0 < SAMPLE_SECONDS:
		await process_frame
		var now := Time.get_ticks_usec()
		frame_samples.append(float(now - last_stamp) / 1000.0)
		last_stamp = now
		draw_samples.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		primitive_samples.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
		process_samples.append(float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0)
		physics_samples.append(float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0)
	var tick_profile: Dictionary = simulation.get_performance_profile()
	var frame_mean := _mean_float(frame_samples)
	var result := {
		"phase": "Phase 3 mixed economy/combat production 3D",
		"method": "scripted developed settlement with deliberately scaled population and hostiles; live economy, construction and combat; at least 3s/120-frame warm-up + 30s rendered sample; VSync disabled",
		"renderer": RenderingServer.get_current_rendering_method() if DisplayServer.get_name() != "headless" else "headless",
		"adapter": RenderingServer.get_video_adapter_name(),
		"quality_profile": profile_name,
		"resolution": {"width": 1920, "height": 1080},
		"seed": simulation.rng_seed,
		"requested_civilians": civilian_target,
		"requested_hostiles": hostile_target,
		"requested_total_active": civilian_target + hostile_target,
		"displayed_workers": game.world_view.character_views.size(),
		"displayed_combatants": game.world_view.combatant_views.size(),
		"remaining_hostiles": simulation.enemies.size(),
		"projectiles_observed": int(tick_profile.get("systems", {}).get("tower_updates", {}).get("calls", 0)) > 0,
		"frames_sampled": frame_samples.size(),
		"frame_ms_mean": snappedf(frame_mean, 0.001),
		"frame_ms_p95": snappedf(_percentile(frame_samples, 0.95), 0.001),
		"frame_ms_p99": snappedf(_percentile(frame_samples, 0.99), 0.001),
		"effective_fps_mean": snappedf(1000.0 / maxf(frame_mean, 0.001), 0.1),
		"draw_calls_mean": roundi(_mean_int(draw_samples)),
		"primitives_mean": roundi(_mean_int(primitive_samples)),
		"process_ms_mean": snappedf(_mean_float(process_samples), 0.001),
		"process_ms_p95": snappedf(_percentile(process_samples, 0.95), 0.001),
		"physics_ms_mean": snappedf(_mean_float(physics_samples), 0.001),
		"physics_ms_p95": snappedf(_percentile(physics_samples, 0.95), 0.001),
		"authoritative_tick_average_ms": float(tick_profile.get("tick_average_ms", 0.0)),
		"authoritative_tick_p95_ms": float(tick_profile.get("tick_p95_ms", 0.0)),
		"authoritative_tick_p99_ms": float(tick_profile.get("tick_p99_ms", 0.0)),
		"authoritative_tick_max_ms": float(tick_profile.get("tick_max_ms", 0.0)),
		"authoritative_profile": tick_profile,
	}
	var absolute_path := ProjectSettings.globalize_path(output_path)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		push_error("Unable to write mixed performance result.")
		quit(1)
		return
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("PHASE3_MIXED_PROFILE PASS quality=%s civilians=%d hostiles=%d fps=%.1f frame_p95=%.3f tick_avg=%.3f tick_p95=%.3f path=%s" % [profile_name, civilian_target, hostile_target, result.effective_fps_mean, result.frame_ms_p95, result.authoritative_tick_average_ms, result.authoritative_tick_p95_ms, absolute_path])
	game.queue_free()
	await process_frame
	quit(0)


func _spawn_mixed_hostiles(simulation, count: int) -> void:
	var tower := _find_building(simulation, Defs.BUILDING_WATCHTOWER)
	var origin: Vector2i = tower.get("position", simulation.town_hall_position) + Vector2i(9, 0)
	for index in count:
		var tile := origin + Vector2i(index % 8, index / 8)
		if not simulation.is_inside_map(tile):
			tile = simulation.shard_position + Vector2i(index % 6, index / 6)
		simulation._prepare_test_tile(tile, Defs.TILE_GRASS)
		var enemy_type: String = [simulation.ENEMY_RAIDER, simulation.ENEMY_SKITTERER, simulation.ENEMY_BRUTE, simulation.ENEMY_HEXER][index % 4]
		simulation._spawn_enemy(tile, 240 + index % 5 * 20, 8, -0.02 * index, 0, enemy_type)
		simulation._reveal_radius(tile, 4)


func _start_construction(simulation) -> void:
	var fixture := Fixture.new()
	var site: Vector2i = fixture._ensure_site(simulation, Defs.BUILDING_HOUSE, simulation.town_hall_position + Vector2i(16, 12))
	if site.x >= 0:
		simulation.request_build(Defs.BUILDING_HOUSE, site)


func _find_building(simulation, building_type: String) -> Dictionary:
	for building_value in simulation.buildings:
		var building: Dictionary = building_value
		if String(building.get("type", "")) == building_type and not bool(building.get("construction", false)):
			return building
	return {}


func _scale_population(simulation, target: int) -> void:
	var templates: Array[Dictionary] = []
	for worker_value in simulation.workers:
		var worker: Dictionary = worker_value
		if String(worker.get("type", "")) != "carrier":
			templates.append(worker.duplicate(true))
	simulation.population_current = target
	simulation.housing_capacity = target
	simulation._ensure_carriers()
	var center := Vector2i(simulation.town_hall_position) + Vector2i(1, 1)
	while simulation.workers.size() < target and not templates.is_empty():
		var index: int = simulation.workers.size()
		var worker: Dictionary = templates[index % templates.size()].duplicate(true)
		worker["id"] = simulation.next_worker_id
		worker["position"] = Vector2i(clampi(center.x + index % 20 - 10, 1, simulation.map_size.x - 2), clampi(center.y + floori(float(index) / 20.0) % 12 - 6, 1, simulation.map_size.y - 2))
		worker["path"] = []
		worker["move_elapsed"] = 0.0
		worker["carried_resource"] = ""
		worker["carried_amount"] = 0
		simulation.workers.append(worker)
		simulation.next_worker_id += 1


func _apply_quality(game) -> void:
	game.sun_light.shadow_enabled = bool(game.quality_profile.get("shadows", true))
	game.sun_light.directional_shadow_max_distance = float(game.quality_profile.get("shadow_distance", 170.0))


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
		total += value
	return total / float(values.size())


func _percentile(values: Array[float], ratio: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	var index := clampi(ceili(float(sorted.size()) * ratio) - 1, 0, sorted.size() - 1)
	return sorted[index]
