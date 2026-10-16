extends Node

## Hotfix 5 gate harness. Only active with `-- --gate-autoplay=<abs dir>`.
## Starts NEW REALM -> BEGIN through the menu handlers, then a scripted
## settler (production_demo_player.gd) issues the same public build commands
## the HUD uses. Runs in real time at 1x, logs FPS each second, every frame
## >100 ms with context, and saves viewport screenshots (HUD + FPS overlay).

const FrameProfiler = preload("res://src/GodotClient3D/Scripts/production_frame_profiler.gd")
const Player = preload("res://src/GodotClient3D/Scripts/production_demo_player.gd")

var game
var dir := ""
var duration := 1200.0
var think_every := 3.0
var player
var t := 0.0
var think_t := 0.0
var sec_t := 0.0
var frames := 0
var worst := 0.0
var fps_log: FileAccess
var stall_log: FileAccess
var shots: Array = []
var shot_index := 0
var night_seen_at := -1.0
var night_shot := false
var day2_logged := false
var started := false
var busy := false
var unfocused_frames := 0
var _think_ms_prev := 0
# D5 measurement
var d5_log: FileAccess
var d5_frames: FileAccess
var d5_scale := -1.0
var d5_vp_rid: RID
var d5_last_compiles := 0
var d5_sec_gpu := 0.0
var d5_sec_cpu := 0.0
var d5_sec_proc := 0.0
var d5_sec_n := 0


func _d5_compiles() -> int:
	var total := 0
	for m in [Performance.PIPELINE_COMPILATIONS_CANVAS, Performance.PIPELINE_COMPILATIONS_MESH, Performance.PIPELINE_COMPILATIONS_SURFACE, Performance.PIPELINE_COMPILATIONS_DRAW, Performance.PIPELINE_COMPILATIONS_SPECIALIZATION]:
		total += int(Performance.get_monitor(m))
	return total
var jump_night := "--gate-jump-night" in OS.get_cmdline_user_args()


func setup(game_value, dir_value: String, duration_value: float) -> void:
	FrameProfiler.enabled = true
	game = game_value
	dir = dir_value
	duration = duration_value
	DirAccess.make_dir_recursive_absolute(dir)
	fps_log = FileAccess.open(dir.path_join("fps.csv"), FileAccess.WRITE)
	fps_log.store_line("t_wall,game_s,fps,worst_ms,day,night,pop,buildings,rebake_queue")
	stall_log = FileAccess.open(dir.path_join("stalls.csv"), FileAccess.WRITE)
	stall_log.store_line("t_wall,frame_ms,game_s,rebake_queue,autosave_task,buildings,harness_think_ms,night,top_sections")
	player = Player.new()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--gate-render-scale="):
			d5_scale = float(a.trim_prefix("--gate-render-scale="))
	d5_log = FileAccess.open(dir.path_join("d5_perf.csv"), FileAccess.WRITE)
	d5_log.store_line("t_wall,game_s,fps,proc_ms,cpu_render_ms,gpu_render_ms,draw_calls,primitives,objects,video_mem_mb,static_mem_mb,nodes,compiles_total,buildings,scale")
	d5_frames = FileAccess.open(dir.path_join("d5_frames.csv"), FileAccess.WRITE)
	d5_frames.store_line("t_wall,frame_ms,cpu_render_ms,gpu_render_ms,proc_ms,compiles_delta,draw_calls,think_ms,buildings,root_ms,sync_frame_ms,sim_ms")
	# [time, name, action]
	shots = [
		[2.0, "01_title_menu", ""],
		[4.0, "02_new_realm_card", "new_realm"],
		[14.0, "03_start", "begin_done"],
		[45.0, "04_build_menu_essentials", "palette:ESSENTIALS"],
		[48.0, "05_build_menu_industry", "palette:INDUSTRY"],
		[51.0, "06_build_menu_military", "palette:MILITARY"],
		[54.0, "07_build_menu_special", "palette:SPECIAL"],
		[60.0, "08_event_log", "log"],
		[66.0, "09_objective_detail", "objective"],
		[72.0, "10_minimap_expanded", "minimap"],
		[78.0, "11_town_hall_inspector", "townhall"],
		[84.0, "12_settings", "settings"],
		[240.0, "13_town_4min", "focus"],
		[480.0, "14_town_8min", "focus"],
		[720.0, "15_town_12min", "focus"],
		[960.0, "16_town_16min", "focus"],
		[1150.0, "17_bottom_strip_late", "focus"],
		[1170.0, "20_console_collapsed", "collapse"],
		[1190.0, "18_town_20min", "focus"],
	]
	if OS.get_cmdline_user_args().has("--gate-census"):
		var cts := [600.0, 960.0, 1180.0]
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--gate-census-at="):
				cts = [float(a.trim_prefix("--gate-census-at="))]
		for ct in cts:
			shots.append([ct, "census_%d" % int(ct), "census"])
		shots.sort_custom(func(a, b) -> bool: return float(a[0]) < float(b[0]))


## R31.2 diagnostic (flag --gate-bot-log): every 30 s, what the test bot is blocked on.
var _bot_log := OS.get_cmdline_user_args().has("--gate-bot-log")
var _bot_log_next := 0.0
var _last_us := 0
var _start_t := 0.0
var _start_gs := 0.0
var _spawn_markers := "--gate-diag-spawn-markers" in OS.get_cmdline_user_args()
var _markers_spawned := false
var _spawn_c0 := 0
var _spawn_watch := 0
var _spawn_worst := 0.0
var _spawn_k := 0
var _spawn_gap := 1.0 if not "--gate-diag-spawn-slow" in OS.get_cmdline_user_args() else 15.0
var _spawn_next := 0.0
var _spawn_round := 1
var _next_think := 0.0
var _det_next := 60.0
var _think_ms_frame := 0


func _on_sim_tick() -> void:
	var sim = game.simulation_host.simulation
	if sim == null or bool(sim.game_finished) or game.simulation_host.paused:
		return
	# R34 determinism probe: a state fingerprint every 60 game seconds.
	if float(sim.elapsed_seconds) >= _det_next:
		_det_next += 60.0
		var types := []
		for bv in sim.buildings:
			types.append(String((bv as Dictionary).get("type", "?")) + str((bv as Dictionary).get("position", "")))
		types.sort()
		_note("detstate gs=%.0f bld=%d pop=%d hash=%d stock=%s" % [float(sim.elapsed_seconds), sim.buildings.size(), int(sim.population_current), hash(str(types)), str(sim.central_inventory)])
	if player.think_phase == 0 and float(sim.elapsed_seconds) < _next_think:
		return
	if player.think_phase == 0:
		_next_think = float(sim.elapsed_seconds) + think_every
	var think_start := Time.get_ticks_usec()
	var phase_ran: int = player.think_phase
	player.think_step(sim)
	var ms := int((Time.get_ticks_usec() - think_start) / 1000)
	_think_ms_frame += ms
	if ms >= 30:
		_note("think_phase %d ms=%d t=%.0f" % [phase_ran, ms, t])


func _process(_engine_delta: float) -> void:
	if game == null:
		return
	# Wall-clock frame time (engine delta can under-report when the OS
	# throttles the window), so FPS/stall numbers are honest.
	var now_us := Time.get_ticks_usec()
	var delta := 0.016 if _last_us == 0 else float(now_us - _last_us) / 1000000.0
	_last_us = now_us
	if not DisplayServer.window_is_focused():
		unfocused_frames += 1
	t += delta
	frames += 1
	worst = maxf(worst, delta)
	var sim = game.simulation_host.simulation
	if sim != null and "performance_profile_enabled" in sim:
		if not sim.performance_profile_enabled:
			sim.performance_profile_enabled = true
		_log_slow_ticks(sim, t)
	if delta > 0.1 and started:
		stall_log.store_line("%.1f,%.0f,%.1f,%d,%d,%d,%d,%d,%s" % [t, delta * 1000.0, float(sim.elapsed_seconds), game.world_view._rebake_queue.size(), game.simulation_host._autosave_task, sim.buildings.size(), _think_ms_prev, int(bool(sim.is_night)), _top_sections()])
		stall_log.flush()
	if d5_frames != null and started:
		if not d5_vp_rid.is_valid():
			d5_vp_rid = game.get_viewport().get_viewport_rid()
			RenderingServer.viewport_set_measure_render_time(d5_vp_rid, true)
		if "--gate-diag-no-shadow" in OS.get_cmdline_user_args() and game.sun_light != null and game.sun_light.shadow_enabled:
			game.sun_light.shadow_enabled = false
		if "--gate-diag-splits4" in OS.get_cmdline_user_args() and game.sun_light != null and game.sun_light.directional_shadow_mode != DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS:
			game.sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		if d5_scale > 0.0 and absf(game.get_viewport().scaling_3d_scale - d5_scale) > 0.001:
			game.get_viewport().scaling_3d_scale = d5_scale
		# Perf checkpoint (measurement only, never shipped defaults):
		# --gate-fps-cap=N, --gate-diag-cheap-ground, --gate-diag-cheap-foliage.
		if frames % 60 == 0:
			_checkpoint_overrides()
			if started and "--gate-diag-hide-ui" in OS.get_cmdline_user_args():
				game.ui_layer.visible = false
			if started and "--gate-diag-hide-chars" in OS.get_cmdline_user_args():
				for v in game.world_view.character_views.values():
					v.visible = false
					v.process_mode = Node.PROCESS_MODE_DISABLED
			apply_iso_overrides(game)
		if not _iso_written and t > 20.0:
			_iso_written = true
			apply_iso_overrides(game)
			var st := FileAccess.open(dir.path_join("iso_state.txt"), FileAccess.WRITE)
			st.store_line(iso_state(game))
			st.close()
		var cpu_r := RenderingServer.viewport_get_measured_render_time_cpu(d5_vp_rid) + RenderingServer.get_frame_setup_time_cpu()
		var gpu_r := RenderingServer.viewport_get_measured_render_time_gpu(d5_vp_rid)
		var proc := float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0
		var comp := _d5_compiles()
		var dc := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		var pv: Dictionary = FrameProfiler.previous
		var root_us := 0
		for k in pv:
			if String(k).begins_with("root."):
				root_us += int(pv[k])
		d5_frames.store_line("%.2f,%.1f,%.2f,%.2f,%.2f,%d,%d,%d,%d,%.2f,%.2f,%.2f" % [t, delta * 1000.0, cpu_r, gpu_r, proc, comp - d5_last_compiles, dc, _think_ms_prev, sim.buildings.size(), root_us / 1000.0, int(pv.get("pres.sync_frame", 0)) / 1000.0, int(pv.get("root.sim_advance", 0)) / 1000.0])
		d5_last_compiles = comp
		d5_sec_gpu += gpu_r; d5_sec_cpu += cpu_r; d5_sec_proc += proc; d5_sec_n += 1
	_think_ms_prev = 0
	sec_t += delta
	if sec_t >= 1.0 and d5_log != null and started and d5_sec_n > 0:
		d5_log.store_line("%.0f,%.0f,%.1f,%.2f,%.2f,%.2f,%d,%d,%d,%.1f,%.1f,%d,%d,%d,%.2f" % [t, float(sim.elapsed_seconds), frames / sec_t, d5_sec_proc / d5_sec_n, d5_sec_cpu / d5_sec_n, d5_sec_gpu / d5_sec_n, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)), int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)), float(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)) / 1048576.0, float(Performance.get_monitor(Performance.MEMORY_STATIC)) / 1048576.0, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), _d5_compiles(), sim.buildings.size(), game.get_viewport().scaling_3d_scale])
		d5_log.flush()
		d5_frames.flush()
		d5_sec_gpu = 0.0; d5_sec_cpu = 0.0; d5_sec_proc = 0.0; d5_sec_n = 0
	if sec_t >= 1.0:
		fps_log.store_line("%.0f,%.0f,%.1f,%.0f,%d,%d,%d,%d,%d" % [t, float(sim.elapsed_seconds), frames / sec_t, worst * 1000.0, int(sim.day_count), int(bool(sim.is_night)), int(sim.population_current), sim.buildings.size(), game.world_view._rebake_queue.size()])
		fps_log.flush()
		sec_t = 0.0
		frames = 0
		worst = 0.0
	if started and jump_night and not busy:
		busy = true
		jump_night = false
		var guard := 0
		while not bool(sim.is_night) and guard < 400:
			player.think(sim)
			sim._simulate_seconds_for_test(3.0)
			guard += 1
		game._select_town_hall()
		game.select_building(0)
		await game.get_tree().create_timer(2.0).timeout
		await RenderingServer.frame_post_draw
		var sz: Vector2 = game.get_viewport().get_visible_rect().size
		game.get_viewport().get_texture().get_image().save_png(dir.path_join("night_topbar_%dx%d.png" % [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y]))
		_note("night jump shot vp=%s night=%s" % [str(sz), str(sim.is_night)])
		game.get_tree().quit()
		return
	# R35 box check (--gate-diag-spawn-markers): from 20 s after start, add one
	# map marker kind per second (twice through the list) and log the worst
	# frame after each, so first-sight costs can be told from rebuild costs.
	if started and _spawn_markers and t >= _start_t + 20.0:
		var kinds: Array = game.world_view.WARMUP_MARKER_KINDS
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--gate-diag-spawn-kinds="):
				kinds = arg.substr(24).split(",")
		if _spawn_k > 0 and _spawn_k <= kinds.size() * 2:
			_spawn_worst = maxf(_spawn_worst, delta)
		if t >= _spawn_next and _spawn_k <= kinds.size() * 2:
			if _spawn_k > 0:
				_note("marker spawn %d %s worst_frame_ms=%.0f compiles=%d" % [_spawn_k, kinds[(_spawn_k - 1) % kinds.size()], _spawn_worst * 1000.0, _d5_compiles() - _spawn_c0])
			_spawn_worst = 0.0
			_spawn_c0 = _d5_compiles()
			if _spawn_k < kinds.size() * 2:
				var hall: Vector2i = sim.town_hall_position
				var k := _spawn_k
				sim.add_map_marker(kinds[k % kinds.size()], hall + Vector2i(-6 + (k % 8) * 2, 4 + (k / 8) * 2), "Test %d" % k, 0.0)
			_spawn_k += 1
			_spawn_next = t + _spawn_gap
	if started and _bot_log and t >= _bot_log_next:
		_bot_log_next = t + 30.0
		_note("botlog t=%.0f game_s=%.0f buildings=%d pop=%d idle=%s fails=%s actions=%s" % [t, float(sim.elapsed_seconds), sim.buildings.size(), int(sim.population_current), player.last_idle_reason, str(player.last_failures), str(player.last_actions)])
	# R34: the test bot runs from the sim tick hook (deterministic game ticks).
	if started and not game.simulation_host.tick_hook.is_valid():
		game.simulation_host.tick_hook = _on_sim_tick
	_think_ms_prev = _think_ms_frame
	_think_ms_frame = 0
	if bool(sim.is_night) and night_seen_at < 0.0 and started:
		night_seen_at = t
	if night_seen_at >= 0.0 and not night_shot and t - night_seen_at >= 25.0 and not busy:
		night_shot = true
		_run_shot("19_night", "focus")
	if not day2_logged and int(sim.day_count) >= 2:
		day2_logged = true
		_note("survived first night: day=%d hall_hp=%s t=%.0f" % [int(sim.day_count), str(_hall_hp(sim)), t])
	if jump_night and shot_index > 2:
		return
	# R34: in-game shots are timed on game time (start + sim seconds), so the
	# same seed gives the same views regardless of frame drops.
	var shot_clock := t if not started else _start_t + float(sim.elapsed_seconds) - _start_gs
	if shot_index < shots.size() and shot_clock >= float(shots[shot_index][0]) and not busy:
		var s: Array = shots[shot_index]
		shot_index += 1
		_run_shot(String(s[1]), String(s[2]))
	if t >= duration and not busy:
		_note("unfocused_frames=%d" % unfocused_frames)
		_note("gate end t=%.0f day=%d pop=%d buildings=%d finished=%s" % [t, int(sim.day_count), int(sim.population_current), sim.buildings.size(), str(sim.game_finished)])
		var _prof = preload("res://src/GodotClient3D/Scripts/production_frame_profiler.gd")
		if _prof.frames > 0:
			var _keys: Array = _prof.totals.keys()
			_keys.sort_custom(func(x, y): return int(_prof.totals[x]) > int(_prof.totals[y]))
			for _k in _keys:
				_note("profile %s avg_us=%d" % [_k, int(_prof.totals[_k]) / _prof.frames])
		game.get_tree().quit()


func _hall_hp(sim) -> int:
	for b in sim.buildings:
		if String(b.get("type", "")) == "TOWN_HALL":
			return int(b.get("hp", -1))
	return -1


## Beta: name the sim systems behind any tick slower than 15 ms.
func _log_slow_ticks(sim, t_now: float) -> void:
	var recs: Array = sim._profile_tick_records
	for rec in recs:
		var us := int(rec.get("tick_usec", 0))
		if us < 15000:
			continue
		var systems: Dictionary = rec.get("systems_usec", {})
		var keys := systems.keys()
		keys.sort_custom(func(a, b): return int(systems[a]) > int(systems[b]))
		var parts: Array[String] = []
		for k in keys.slice(0, 4):
			parts.append("%s=%d" % [k, int(systems[k]) / 1000])
		_note("slow_tick t=%.1f ms=%d %s" % [t_now, us / 1000, " ".join(parts)])
	recs.clear()


func _note(text: String) -> void:
	var f := FileAccess.open(dir.path_join("notes.txt"), FileAccess.READ_WRITE if FileAccess.file_exists(dir.path_join("notes.txt")) else FileAccess.WRITE)
	f.seek_end()
	f.store_line(text)
	f.close()
	print("GATE " + text)


func _run_shot(name: String, action: String) -> void:
	busy = true
	await _shot_async(name, action)
	busy = false


func _shot_async(name: String, action: String) -> void:
	var tree: SceneTree = game.get_tree()
	if started:
		_checkpoint_overrides()
	if action == "census":
		_draw_census()
	match action:
		"new_realm":
			game._show_new_realm_card()
		"begin_done":
			pass
		"log":
			game._toggle_event_log()
		"objective":
			game._show_objective_detail(true)
		"minimap":
			game._toggle_minimap()
		"townhall":
			game._select_town_hall()
		"settings":
			game._show_start_menu()
			game._show_settings_card()
		"focus":
			game._select_town_hall()
			game.select_building(0)
		"collapse":
			game._toggle_console_collapsed()
		_:
			if action.begins_with("palette:"):
				game._set_build_palette_visible(true)
				var cat := action.trim_prefix("palette:")
				for i in game.build_category_select.item_count:
					if String(game.build_category_select.get_item_metadata(i)) == cat:
						game.build_category_select.select(i)
						game._set_build_category(i)
	await tree.create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	# Beta: PNG encoding of a 1920x1200 frame took ~300-400 ms on the main
	# thread and was 6 of the 15 lowest seconds in r10. Encode off-thread.
	var shot_image: Image = game.get_viewport().get_texture().get_image()
	var shot_path: String = dir.path_join(name + ".png")
	WorkerThreadPool.add_task(func(): shot_image.save_png(shot_path))
	_note("shot %s t=%.0f" % [name, t])
	if name == "03_start" and OS.get_cmdline_user_args().has("--gate-diag-layers"):
		await _diag_layer_shots(tree)
	if name == "03_start" and OS.get_cmdline_user_args().has("--gate-group-probe"):
		await _group_probe(tree)
		game.get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("--gate-goals-probe") and name.begins_with("late_05"):
		await _goals_probe(tree)
		game.get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("--gate-day-water") and name.begins_with("late_10"):
		var guard := 0
		while bool(game.simulation_host.simulation.is_night) and guard < 400:
			game.simulation_host.simulation._simulate_seconds_for_test(3.0)
			guard += 1
		await tree.create_timer(2.5).timeout
		await RenderingServer.frame_post_draw
		game.get_viewport().get_texture().get_image().save_png(dir.path_join("day_water.png"))
		_note("day_water shot night=%s guard=%d" % [str(game.simulation_host.simulation.is_night), guard])
		game.get_tree().quit()
		return
	if OS.get_cmdline_user_args().has("--gate-diag-outpost") and name.begins_with("late_10"):
		_pick_diag(Rect2(0.72, 0.17, 0.13, 0.17))
	if name == "11_town_hall_inspector" and OS.get_cmdline_user_args().has("--gate-inspector-probe"):
		await _inspector_probe(tree)
		game.get_tree().quit()
		return
	if name == "03_start" and OS.get_cmdline_user_args().has("--gate-unit-probe"):
		await _unit_probe(tree)
		game.get_tree().quit()
		return
	match action:
		"new_realm":
			for a in OS.get_cmdline_user_args():
				if a.begins_with("--gate-seed=") and game.seed_edit != null:
					game.seed_edit.text = a.trim_prefix("--gate-seed=")
			var lt := _loadtest_seconds()
			if lt > 0.0:
				# Perf A/B only: resume the saved late-game settlement, no shots, fixed duration.
				game.load_game()
				# Late-game UI shots right after the load (same tabs as the gate).
				var late: Array = []
				var k := 0.0
				for sh in shots.slice(3, 12):
					late.append([t + 6.0 + k, "late_" + String(sh[1]), sh[2]])
					k += 3.0
				late.append([t + 6.0 + k, "late_town", "focus"])
				if OS.get_cmdline_user_args().has("--gate-census"):
					late.append([t + 9.0 + k, "late_census_town", "census"])
				shots = late
				shot_index = 0
				duration = t + lt
				game._select_town_hall()
				game.select_building(0)
			else:
				game._start_from_menu()
			started = true
			_start_t = t
			# R36: --gate-ui-scale=1.25 applies the in-game UI scale setting.
			for arg in OS.get_cmdline_user_args():
				if arg.begins_with("--gate-ui-scale="):
					game._apply_ui_scale(float(arg.substr(16)))
					_note("ui scale %s" % arg.substr(16))
			_start_gs = float(game.simulation_host.simulation.elapsed_seconds)
			_note("NEW REALM -> BEGIN seed=%d" % int(game.simulation_host.simulation.rng_seed))
		"log":
			game._toggle_event_log()
		"collapse":
			game._toggle_console_collapsed()
		"objective":
			game._show_objective_detail(false)
		"minimap":
			game._toggle_minimap()
		"townhall":
			game.cancel_placement()
			game.select_building(0)
		"settings":
			game._resume_from_menu()
		_:
			if action.begins_with("palette:") and not action.ends_with("SPECIAL"):
				pass
			elif action.begins_with("palette:"):
				game._set_build_palette_visible(false)


## Hotfix 6: the previous frame's per-section timings (ms), largest first.
func _top_sections() -> String:
	var sections: Dictionary = FrameProfiler.previous
	var keys := sections.keys()
	keys.sort_custom(func(a, b): return sections[a] > sections[b])
	var parts: Array[String] = []
	for key in keys.slice(0, 6):
		if int(sections[key]) >= 2000:
			parts.append("%s=%d" % [key, int(sections[key]) / 1000])
	return " ".join(parts)


var _cheap_foliage_mats: Dictionary = {}


func _checkpoint_overrides() -> void:
	var args := OS.get_cmdline_user_args()
	for arg in args:
		if String(arg).begins_with("--gate-fps-cap="):
			var cap := int(String(arg).get_slice("=", 1))
			if Engine.max_fps != cap:
				Engine.max_fps = cap
	var wv = game.world_view
	if wv == null or wv.chunk_root == null:
		return
	_apply_r32_flags(wv, args)
	var cheap_ground := "--gate-diag-cheap-ground" in args
	var cheap_foliage := "--gate-diag-cheap-foliage" in args
	if not cheap_ground and not cheap_foliage:
		return
	for node in wv.chunk_root.find_children("*", "GeometryInstance3D", true, false):
		var gi := node as GeometryInstance3D
		var mat := gi.material_override
		if cheap_ground and gi is MeshInstance3D and gi.name == "Terrain" and mat is ShaderMaterial:
			(mat as ShaderMaterial).set_shader_parameter("lod_cheap", 1.0)
		elif cheap_foliage and gi is MultiMeshInstance3D and mat is ShaderMaterial:
			var sm := mat as ShaderMaterial
			var albedo = sm.get_shader_parameter("albedo_color")
			if typeof(albedo) != TYPE_VECTOR3:
				continue
			var key := str(albedo)
			if not _cheap_foliage_mats.has(key):
				var std := StandardMaterial3D.new()
				std.albedo_color = Color(albedo.x, albedo.y, albedo.z)
				std.roughness = 0.9
				std.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
				_cheap_foliage_mats[key] = std
			gi.material_override = _cheap_foliage_mats[key]


## Isolation pass (measurement only, gate/shots flags; shipped defaults untouched):
## --gate-iso-ssao=0|1 --gate-iso-msaa=0|2|4 --gate-iso-glow=0|1 --gate-iso-ssr=0|1
## --gate-iso-splits=1|2|4 --gate-iso-shadow-atlas=<px>. Re-applied every 60 frames
## because day/night lighting re-applies the quality features.
static var _iso_atlas_applied := -1
var _iso_written := false


static func iso_args() -> Dictionary:
	var out := {}
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--gate-iso-"):
			var kv := String(a).trim_prefix("--gate-iso-").split("=")
			if kv.size() == 2:
				out[kv[0]] = int(kv[1])
	return out


static func apply_iso_overrides(g: Node) -> void:
	if g == null:
		return
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--gate-render-scale="):
			g.get_viewport().scaling_3d_scale = float(String(a).trim_prefix("--gate-render-scale="))
	var iso := iso_args()
	if iso.is_empty():
		return
	var env: Environment = g.environment_resource
	if env != null:
		if iso.has("ssao"):
			env.ssao_enabled = iso["ssao"] != 0
		if iso.has("glow"):
			env.glow_enabled = iso["glow"] != 0
		if iso.has("ssr"):
			env.ssr_enabled = iso["ssr"] != 0
	if iso.has("msaa"):
		var m: int = iso["msaa"]
		g.get_viewport().msaa_3d = Viewport.MSAA_4X if m >= 4 else (Viewport.MSAA_2X if m == 2 else Viewport.MSAA_DISABLED)
	var sun: DirectionalLight3D = g.sun_light
	if sun != null and iso.has("splits"):
		var sp: int = iso["splits"]
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS if sp >= 4 else (DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if sp == 2 else DirectionalLight3D.SHADOW_ORTHOGONAL)
	if iso.has("shadow-atlas") and _iso_atlas_applied != int(iso["shadow-atlas"]):
		_iso_atlas_applied = int(iso["shadow-atlas"])
		RenderingServer.directional_shadow_atlas_set_size(_iso_atlas_applied, true)


static func iso_state(g: Node) -> String:
	var env: Environment = g.environment_resource
	var sun: DirectionalLight3D = g.sun_light
	return "profile=%s scale=%.2f msaa=%d ssao=%s glow=%s ssr=%s shadows=%s split_mode=%d atlas=%s iso=%s" % [String(g.quality_profile.get("name", "?")), g.get_viewport().scaling_3d_scale, int(g.get_viewport().msaa_3d), str(env.ssao_enabled), str(env.glow_enabled), str(env.ssr_enabled), str(sun.shadow_enabled if sun else false), int(sun.directional_shadow_mode) if sun else -1, "profile-default" if _iso_atlas_applied < 0 else str(_iso_atlas_applied), str(iso_args())]


## Beta perf A/B (harness only): `--gate-loadtest=<seconds>` loads the autosave
## instead of starting a new realm and measures for that many seconds.
static func _loadtest_seconds() -> float:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--gate-loadtest="):
			return float(String(a).trim_prefix("--gate-loadtest="))
	return 0.0


## R32 shading isolation (gate flags only; shipped defaults untouched).
## Candidates: --gate-r32-fog-lite (lossless), --gate-r32-ground-hash (visible:
## different noise pattern). Existing: --gate-diag-cheap-ground / -foliage.
## Diagnostic only (removes things, obviously visible):
## --gate-r32-hide=fog,ground,foliage,water,smoke,mist,characters,buildings
var _r32_noted := false
var _r33_noted := false


func _apply_r32_flags(wv, args: PackedStringArray) -> void:
	# R33: fog-lite is the default; --gate-r32-fog-full restores the old path for A/B.
	if "--gate-r32-fog-full" in args and wv.fog_screen_material != null:
		wv.fog_screen_material.set_shader_parameter("lite", 0.0)
	var hide: PackedStringArray = []
	for a in args:
		if String(a).begins_with("--gate-r32-hide="):
			hide = String(a).trim_prefix("--gate-r32-hide=").split(",")
	var ground_hash := "--gate-r32-ground-hash" in args
	var ground_lite := "--gate-r33-ground-lite" in args
	var ground_full := "--gate-r33-ground-full" in args
	if not _r32_noted and (not hide.is_empty() or ground_hash or "--gate-r32-fog-lite" in args):
		_r32_noted = true
		_note("r32 flags applied t=%.0f hide=%s ground_hash=%s fog_lite=%s" % [t, str(hide), str(ground_hash), str("--gate-r32-fog-lite" in args)])
	if not _r33_noted and (ground_lite or ground_full):
		_r33_noted = true
		_note("r33 flags applied t=%.0f ground_lite=%s ground_full=%s" % [t, str(ground_lite), str(ground_full)])
	if hide.is_empty() and not ground_hash and not ground_lite and not ground_full:
		return
	if "fog" in hide:
		wv.gate_hide_fog = true
		if wv.fog_screen != null:
			wv.fog_screen.visible = false
	if "ui" in hide and game.ui_layer != null:
		game.ui_layer.visible = false
	var env: Environment = null
	var we: Array = game.find_children("*", "WorldEnvironment", true, false)
	if not we.is_empty():
		env = (we[0] as WorldEnvironment).environment
	if "post" in hide and env != null:
		env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
		env.adjustment_enabled = false
		env.glow_enabled = false
		env.ssao_enabled = false
	if "lights" in hide:
		for l in game.find_children("*", "Light3D", true, false):
			if not (l is DirectionalLight3D):
				(l as Light3D).visible = false
	if "matfeat" in hide and wv.buildings_root != null:
		_r33_flatten_building_materials(wv.buildings_root)
	if "water" in hide and wv.water_mesh_instance != null:
		wv.water_mesh_instance.visible = false
	if "characters" in hide and wv.characters_root != null:
		wv.characters_root.visible = false
	if "buildings" in hide and wv.buildings_root != null:
		wv.buildings_root.visible = false
	for node in wv.find_children("*", "GeometryInstance3D", true, false):
		var gi := node as GeometryInstance3D
		var mat := gi.material_override
		var shader_path := ""
		if mat is ShaderMaterial and (mat as ShaderMaterial).shader != null:
			shader_path = (mat as ShaderMaterial).shader.resource_path
		if shader_path.ends_with("settlement_ground.gdshader"):
			if ground_hash:
				(mat as ShaderMaterial).set_shader_parameter("fast_hash", 1.0)
			if ground_lite:
				(mat as ShaderMaterial).set_shader_parameter("ground_lite", 1.0)
			if ground_full:
				(mat as ShaderMaterial).set_shader_parameter("lod_cheap", 0.0)
			if "ground" in hide:
				gi.visible = false
		elif "fog" in hide and shader_path.ends_with("production_fog_of_war.gdshader"):
			gi.visible = false
		elif "foliage" in hide and shader_path.ends_with("settlement_foliage.gdshader"):
			gi.visible = false
		elif "mist" in hide and shader_path.ends_with("production_boundary_mist.gdshader"):
			gi.visible = false
		elif "smoke" in hide and gi is CPUParticles3D:
			gi.visible = false
		elif "mist" in hide and gi is CPUParticles3D and String(gi.name).to_lower().contains("mist"):
			gi.visible = false


var _r33_mat_cache := {}


## Isolation only: building surfaces keep their colour/texture but drop normal
## maps, AO, rim, clearcoat, detail, heightmap and use per-vertex shading.
func _r33_flatten_building_materials(root: Node) -> void:
	for n in root.find_children("*", "GeometryInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi == null or mi.mesh == null or mi.has_meta("r33_flat"):
			continue
		mi.set_meta("r33_flat", true)
		for i in mi.mesh.get_surface_count():
			var m: Material = mi.get_active_material(i)
			if not (m is BaseMaterial3D):
				continue
			if not _r33_mat_cache.has(m):
				var d := (m as BaseMaterial3D).duplicate() as BaseMaterial3D
				d.normal_enabled = false
				d.ao_enabled = false
				d.rim_enabled = false
				d.clearcoat_enabled = false
				d.detail_enabled = false
				d.heightmap_enabled = false
				d.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
				_r33_mat_cache[m] = d
			mi.set_surface_override_material(i, _r33_mat_cache[m])


## R31 diagnostic: which nodes the camera actually draws. Counts visible
## MeshInstance3D / MultiMeshInstance3D surfaces by top-level owner category.
func _draw_census() -> void:
	var cam: Camera3D = game.get_viewport().get_camera_3d()
	var counts := {}
	var surfaces := {}
	var detail := {}
	for n in game.world_view.find_children("*", "GeometryInstance3D", true, false):
		var gi := n as GeometryInstance3D
		if gi == null or not gi.is_visible_in_tree():
			continue
		var aabb: AABB = gi.get_aabb()
		var center: Vector3 = gi.global_transform * aabb.get_center()
		if cam != null and (cam.is_position_behind(center) or not game.get_viewport().get_visible_rect().grow(200).has_point(cam.unproject_position(center))):
			continue
		var cat := "?"
		var p: Node = gi
		while p != null and p != game.world_view:
			cat = String(p.name).split("_")[0].rstrip("0123456789@")
			p = p.get_parent()
		var surf := 1
		if gi is MeshInstance3D and (gi as MeshInstance3D).mesh != null:
			surf = (gi as MeshInstance3D).mesh.get_surface_count()
		elif gi is MultiMeshInstance3D and (gi as MultiMeshInstance3D).multimesh != null and (gi as MultiMeshInstance3D).multimesh.mesh != null:
			surf = (gi as MultiMeshInstance3D).multimesh.mesh.get_surface_count()
		if cat in ["Buildings", "Roads", "MapMarkers", "Characters"]:
			var mk := "?"
			if gi is MeshInstance3D and (gi as MeshInstance3D).mesh != null:
				var m: Mesh = (gi as MeshInstance3D).mesh
				mk = m.resource_path.get_file() if m.resource_path != "" else "%s:%s" % [m.get_class(), String(gi.name)]
			var dk := cat + "|" + mk
			detail[dk] = int(detail.get(dk, 0)) + surf
		counts[cat] = int(counts.get(cat, 0)) + 1
		surfaces[cat] = int(surfaces.get(cat, 0)) + surf
	var keys: Array = surfaces.keys()
	keys.sort_custom(func(a, b) -> bool: return int(surfaces[a]) > int(surfaces[b]))
	var parts := []
	for k in keys:
		parts.append("%s=%d/%d" % [k, int(counts[k]), int(surfaces[k])])
	var dkeys: Array = detail.keys()
	dkeys.sort_custom(func(a, b) -> bool: return int(detail[a]) > int(detail[b]))
	for dk in dkeys.slice(0, 40):
		_note("census_detail %s %d" % [dk, int(detail[dk])])
	_note("census t=%.0f draw_calls=%d instances/surfaces %s" % [t, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), " ".join(parts)])


## R29 probe: C&C group selection. 4 soldiers; box-select, Ctrl toggle,
## plain click, group move and group attack, with shots.
func _group_probe(tree: SceneTree) -> void:
	var sim = game.simulation_host.simulation
	sim.soldiers_total += 4
	sim._sync_production_workers()
	var origin: Vector2i = sim._town_hall_entrance_tile()
	var ids: Array = []
	var k := 0
	for w in sim.workers:
		if String(w.get("type", "")) == "guard" and int(w.get("building_id", 0)) == 0:
			w["position"] = origin + Vector2i(k % 2, 1 + k / 2)
			w["path"] = []
			ids.append(int(w.id))
			k += 1
	game.camera_rig.focus_world(game.world_view.tile_to_world(Vector2(origin) + Vector2(0.5, 3.0)))
	await tree.create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	var checks := []
	var vp: Rect2 = game.get_viewport().get_visible_rect()
	# 1) box-drag over the whole world view selects all soldiers
	var n: int = game.box_select_from_rect(Rect2(Vector2(0, 60), Vector2(vp.size.x, vp.size.y * 0.7)), false)
	checks.append(["box_select", n == ids.size(), "selected %d of %d" % [n, ids.size()]])
	game._update_box_select_rect(Vector2(vp.size.x * 0.2, 90), Vector2(vp.size.x * 0.8, vp.size.y * 0.65))
	await tree.create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png(dir.path_join("group_select.png"))
	game.box_select_rect.visible = false
	var panel_text: String = game.inspector_label.text
	checks.append(["panel", panel_text.contains("%d Soldiers selected" % ids.size()), panel_text.split("\n")[0].left(90)])
	# 2) Ctrl+click toggles one out and back in
	game.toggle_unit(int(ids[0]))
	var after_out: int = game._group_ids().size()
	game.toggle_unit(int(ids[0]))
	checks.append(["ctrl_toggle", after_out == ids.size() - 1 and game._group_ids().size() == ids.size(), "%d -> %d -> %d" % [ids.size(), after_out, game._group_ids().size()]])
	# 3) plain click selects only that unit
	game.select_worker(int(ids[1]))
	checks.append(["plain_click", game._group_ids().size() == 1, "group=%d" % game._group_ids().size()])
	game.box_select_from_rect(Rect2(Vector2(0, 60), Vector2(vp.size.x, vp.size.y * 0.7)), false)
	# 4) group move
	var dest := origin + Vector2i(5, 4)
	for r in range(4, 9):
		var t := origin + Vector2i(r, r)
		if sim.is_revealed(t) and String(sim.get_tile(t)) == "GRASS" and not sim.is_tile_occupied(t):
			dest = t
			break
	var res: Dictionary = game.order_group(game._group_ids(), dest, "auto")
	var moving := 0
	for id in ids:
		var w: Dictionary = sim._find_worker_by_id(int(id))
		if String(w.get("state", "")) == "Moving by order":
			moving += 1
	checks.append(["group_move", moving == ids.size(), "%s moving=%d" % [String(res.get("message", "")), moving]])
	await tree.create_timer(6.0).timeout
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png(dir.path_join("group_order_move.png"))
	var spread := {}
	for id in ids:
		spread[str(sim._find_worker_by_id(int(id)).get("position"))] = true
	checks.append(["no_stacking", spread.size() >= mini(ids.size(), 3), "%d distinct tiles" % spread.size()])
	# 5) group attack on a raider holding position
	var spot := dest + Vector2i(4, 0)
	sim._spawn_enemy(spot, 80, 1, 0.0)
	var enemy: Dictionary = sim.enemies[sim.enemies.size() - 1]
	enemy["speed_multiplier"] = 100000.0
	var hp0 := int(enemy.hp)
	res = game.order_group(game._group_ids(), spot, "attack")
	var waited := 0.0
	while waited < 20.0 and int(enemy.hp) > hp0 - 8 and sim.enemies.has(enemy):
		await tree.create_timer(0.5).timeout
		waited += 0.5
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png(dir.path_join("group_order_attack.png"))
	var fighters := 0
	for id in ids:
		if int(sim._find_worker_by_id(int(id)).get("manual_attack_id", 0)) == int(enemy.id) or String(sim._find_worker_by_id(int(id)).get("state", "")) == "Fighting":
			fighters += 1
	checks.append(["group_attack", int(enemy.hp) < hp0 and fighters >= 2, "%s hp %d->%d in %.1fs, %d engaged" % [String(res.get("message", "")), hp0, int(enemy.hp), waited, fighters]])
	var all_ok := true
	for c in checks:
		all_ok = all_ok and bool(c[1])
		_note("group_probe %s %s %s" % [String(c[0]), "PASS" if bool(c[1]) else "FAIL", String(c[2])])
	_note("group_probe RESULT %s" % ("PASS" if all_ok else "FAIL"))


## R28 probe: a patrol soldier + a raider holding position; the soldier is
## selected and the unit panel captured at UI 100/125/150 %, with every
## visible command button checked to lie fully inside the window.
func _unit_probe(tree: SceneTree) -> void:
	var sim = game.simulation_host.simulation
	sim.soldiers_total += 1
	sim._sync_production_workers()
	var guard: Dictionary = {}
	for w in sim.workers:
		if String(w.get("type", "")) == "guard" and int(w.get("building_id", 0)) == 0:
			guard = w
	if guard.is_empty():
		_note("unit_probe FAIL no soldier")
		return
	var origin: Vector2i = sim._town_hall_entrance_tile()
	guard["position"] = origin
	guard["path"] = []
	var spot := Vector2i(-1, -1)
	for r in range(6, 12):
		for dx in range(-r, r + 1):
			var t := origin + Vector2i(dx, r)
			if spot.x < 0 and sim.is_inside_map(t) and sim.is_revealed(t) and String(sim.get_tile(t)) == "GRASS" and not sim.is_tile_occupied(t):
				spot = t
	game.select_worker(int(guard.id))
	game.selected_entity_kind = "worker"
	game.camera_rig.focus_world(game.world_view.tile_to_world(Vector2(origin) + Vector2(0.5, 3.0)))
	var all_ok := true
	# Late-run state: every build plan unlocked (the widest build strip).
	game.debug_unlock_all = true
	game._refresh_build_strip_state()
	for f in [1.0, 1.25, 1.5]:
		game._apply_ui_scale(f)
		await tree.process_frame
		game._layout_hud_console()
		await tree.create_timer(1.0).timeout
		await RenderingServer.frame_post_draw
		var vp: Rect2 = game.get_viewport().get_visible_rect()
		var report := []
		var ok := true
		for b in [game.move_button, game.attack_button, game.scout_button, game.inspector_panel, game.selection_host]:
			if b == null or not b.is_visible_in_tree():
				continue
			var r: Rect2 = b.get_global_rect()
			var inside := vp.grow(0.5).encloses(r)
			ok = ok and inside
			report.append("%s=%s%s" % [b.name, str(r), "" if inside else "!OUT"])
		all_ok = all_ok and ok and game.move_button.is_visible_in_tree() and game.attack_button.is_visible_in_tree()
		_note("unit_probe scale=%.2f vp=%s ok=%s %s" % [f, str(vp.size), str(ok), " ".join(report)])
		game.get_viewport().get_texture().get_image().save_png(dir.path_join("unit_panel_%d.png" % int(round(f * 100.0))))
	game._apply_ui_scale(1.25)
	sim._spawn_enemy(spot, 60, 1, 0.0)
	var enemy: Dictionary = sim.enemies[sim.enemies.size() - 1]
	enemy["speed_multiplier"] = 100000.0
	var hp0 := int(enemy.hp)
	var waited := 0.0
	while waited < 20.0 and int(enemy.hp) >= hp0:
		await tree.create_timer(0.5).timeout
		waited += 0.5
	await tree.create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png(dir.path_join("raid_engage.png"))
	var engaged := int(enemy.hp) < hp0
	_note("raid_probe engaged=%s hp %d->%d after %.1fs guard=%s" % [str(engaged), hp0, int(enemy.hp), waited, String(guard.get("state", ""))])
	_note("unit_probe RESULT %s" % ("PASS" if all_ok and engaged else "FAIL"))


## Diagnostic only: re-shoot the start view with one world layer hidden at a
## time to identify which node draws a given shape.
func _diag_layer_shots(tree: SceneTree) -> void:
	var wv: Node = game.world_view
	var groups := {}
	for n in wv.find_children("*", "GeometryInstance3D", true, false):
		var key := String(n.name).split("_")[0]
		var parent_key := String(n.get_parent().name).split("_")[0]
		var k := parent_key + "." + key
		if not groups.has(k):
			groups[k] = []
		groups[k].append(n)
	_note("diag groups %s" % [str(groups.keys())])
	for k in groups:
		for n in groups[k]:
			n.visible = false
		await tree.process_frame
		await RenderingServer.frame_post_draw
		game.get_viewport().get_texture().get_image().save_png(dir.path_join("diag_%s.png" % String(k).replace("/", "_")))
		for n in groups[k]:
			n.visible = true


## R36: Town Hall inspector at 100/125/150 % UI scale: the text box must lie
## inside the visible console and its content must fit (or be scrollable).
func _inspector_probe(tree: SceneTree) -> void:
	game._select_town_hall()
	for f in [1.0, 1.25, 1.5]:
		game._apply_ui_scale(f)
		for i in 30:
			await tree.process_frame
		await RenderingServer.frame_post_draw
		var vp: Rect2 = game.get_viewport().get_visible_rect()
		var lab: RichTextLabel = game.inspector_label
		var host: Control = game.selection_host
		var lr := lab.get_global_rect()
		var hr := host.get_global_rect()
		var inside := vp.grow(0.5).encloses(lr) and hr.grow(0.5).encloses(lr)
		var fits := float(lab.get_content_height()) <= lr.size.y + 1.0
		_note("inspector_probe scale=%.2f vp=%s label=%s host=%s content_h=%d inside=%s fits=%s scroll=%s" % [f, str(vp.size), str(lr), str(hr), lab.get_content_height(), str(inside), str(fits), str(lab.get_v_scroll_bar().visible)])
		var chain := []
		var n: Node = lab
		while n != null and n != game.hud_console.get_parent():
			if n is Control:
				chain.append("%s:%s/min%s" % [n.name, str((n as Control).size), str((n as Control).get_combined_minimum_size())])
			n = n.get_parent()
		_note("inspector_chain " + " < ".join(chain) + " text_len=%d lines=%d" % [lab.get_parsed_text().length(), lab.get_line_count()])
		game.get_viewport().get_texture().get_image().save_png(dir.path_join("inspector_%d.png" % int(round(f * 100.0))))


## R37 diag: what is the bright surface at the (captured) rival outpost?
## Lists meshes near every outpost view with their material colour, then a shot.
func _outpost_diag(tree: SceneTree) -> void:
	var wv = game.world_view
	var views: Array = []
	for v in wv.find_children("*", "Node3D", true, false):
		if v is ProductionBuildingView3D and "OUTPOST" in String((v as ProductionBuildingView3D).building_type):
			views.append(v)
	_note("outpost_diag views=%d" % views.size())
	for v in views:
		var bv: ProductionBuildingView3D = v
		var c: Vector3 = bv.global_position
		_note("outpost view type=%s faction=%s pos=%s parent=%s" % [bv.building_type, bv.faction, str(c), bv.get_parent().name])
		for m in wv.find_children("*", "MeshInstance3D", true, false):
			var mi: MeshInstance3D = m
			if not mi.is_visible_in_tree() or mi.global_position.distance_to(c) > 7.0:
				continue
			var mat: Material = mi.material_override
			if mat == null and mi.mesh != null and mi.mesh.get_surface_count() > 0:
				mat = mi.get_active_material(0)
			var col := "?"
			if mat is BaseMaterial3D:
				col = "%s tex=%s unshaded=%s" % [(mat as BaseMaterial3D).albedo_color.to_html(false), str((mat as BaseMaterial3D).albedo_texture != null), str((mat as BaseMaterial3D).shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED)]
			elif mat is ShaderMaterial:
				col = "shader:" + String((mat as ShaderMaterial).shader.resource_path)
			_note("  mesh %s aabb=%s col=%s" % [str(mi.get_path()).replace(str(wv.get_path()), ""), str(mi.get_aabb().size * mi.global_transform.basis.get_scale()), col])
		game.camera_rig.focus_world(c)
		for i in 20:
			await tree.process_frame
		await RenderingServer.frame_post_draw
		game.get_viewport().get_texture().get_image().save_png(dir.path_join("outpost_%s.png" % bv.building_type))


## R37 diag: visible meshes whose screen position falls in a viewport-fraction rect.
func _pick_diag(frac: Rect2) -> void:
	var cam: Camera3D = game.get_viewport().get_camera_3d()
	var vs: Vector2 = game.get_viewport().get_visible_rect().size
	var rect := Rect2(frac.position * vs, frac.size * vs)
	var n := 0
	for m in game.world_view.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = m
		if not mi.is_visible_in_tree() or mi.mesh == null:
			continue
		var centre: Vector3 = mi.global_transform * mi.get_aabb().get_center()
		if cam.is_position_behind(centre) or not rect.has_point(cam.unproject_position(centre)):
			continue
		var mat: Material = mi.material_override if mi.material_override != null else mi.get_active_material(0)
		var col := "?"
		if mat is BaseMaterial3D:
			col = "%s tex=%s emis=%s" % [(mat as BaseMaterial3D).albedo_color.to_html(false), str((mat as BaseMaterial3D).albedo_texture != null), str((mat as BaseMaterial3D).emission_enabled)]
		elif mat is ShaderMaterial:
			col = "shader:" + String((mat as ShaderMaterial).shader.resource_path).get_file()
		_note("pick %s size=%s col=%s" % [str(mi.get_path()).get_slice("WorldView", 1), str((mi.get_aabb().size * mi.global_transform.basis.get_scale()).snapped(Vector3.ONE * 0.01)), col])
		n += 1
		if n > 80:
			break
	game.get_viewport().get_texture().get_image().save_png(dir.path_join("pick_diag.png"))


## R37: Goals opens on the active objective; History is collapsed and the
## scroll is back at the top every time it opens.
func _goals_probe(tree: SceneTree) -> void:
	game._set_build_palette_visible(false)
	game._show_objective_detail(true)
	for i in 10:
		await tree.process_frame
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png(dir.path_join("goals_open.png"))
	_note("goals_probe open: first_line=%s history_visible=%s history_btn=%s" % [game.objective_detail_body.text.get_slice("\n", 0), str(game.objective_history_label.visible), game.objective_history_button.text])
	game.objective_history_button.emit_signal("pressed")
	# R37b: let the expanded History lay out first, then scroll (a scroll set
	# before layout is clamped to the old, shorter content).
	for i in 10:
		await tree.process_frame
	var hl: Label = game.objective_history_label
	var sc: ScrollContainer = game.objective_goals_scroll
	var entries := hl.text.split("\n", false).size()
	for i in 5:
		await tree.process_frame
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png(dir.path_join("goals_history.png"))
	var vmax := int(sc.get_v_scroll_bar().max_value - sc.get_v_scroll_bar().page)
	_note("goals_probe expanded: history_visible=%s entries=%d label_h=%.0f lines=%d scroll=%d vmax=%d" % [str(hl.visible), entries, hl.size.y, hl.get_line_count(), sc.scroll_vertical, vmax])
	sc.scroll_vertical = vmax
	for i in 5:
		await tree.process_frame
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png(dir.path_join("goals_history_end.png"))
	_note("goals_probe history_end: scroll=%d vmax=%d SCROLL=%s" % [sc.scroll_vertical, vmax, "PASS" if vmax > 0 and sc.scroll_vertical >= vmax - 2 else "CHECK"])
	_note("goals_history " + hl.text.replace("\n", " | "))
	game._show_objective_detail(false)
	game._show_objective_detail(true)
	for i in 10:
		await tree.process_frame
	_note("goals_probe reopened: history_visible=%s scroll=%d RESET=%s" % [str(game.objective_history_label.visible), game.objective_goals_scroll.scroll_vertical, "PASS" if not game.objective_history_label.visible and game.objective_goals_scroll.scroll_vertical == 0 else "FAIL"])
	_note("goals_body " + game.objective_detail_body.text.replace("\n", " | "))
