extends Node

## Hotfix 5 gate harness. Only active with `-- --gate-autoplay=<abs dir>`.
## Starts NEW REALM -> BEGIN through the menu handlers, then a scripted
## settler (production_demo_player.gd) issues the same public build commands
## the HUD uses. Runs in real time at 1x, logs FPS each second, every frame
## >100 ms with context, and saves viewport screenshots (HUD + FPS overlay).

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
var jump_night := "--gate-jump-night" in OS.get_cmdline_user_args()


func setup(game_value, dir_value: String, duration_value: float) -> void:
	game = game_value
	dir = dir_value
	duration = duration_value
	DirAccess.make_dir_recursive_absolute(dir)
	fps_log = FileAccess.open(dir.path_join("fps.csv"), FileAccess.WRITE)
	fps_log.store_line("t_wall,game_s,fps,worst_ms,day,night,pop,buildings,rebake_queue")
	stall_log = FileAccess.open(dir.path_join("stalls.csv"), FileAccess.WRITE)
	stall_log.store_line("t_wall,frame_ms,game_s,rebake_queue,autosave_task,buildings,harness_think_ms,night")
	player = Player.new()
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
		[1190.0, "18_town_20min", "focus"],
	]


var _last_us := 0


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
	if delta > 0.1 and started:
		stall_log.store_line("%.1f,%.0f,%.1f,%d,%d,%d,%d,%d" % [t, delta * 1000.0, float(sim.elapsed_seconds), game.world_view._rebake_queue.size(), game.simulation_host._autosave_task, sim.buildings.size(), _think_ms_prev, int(bool(sim.is_night))])
		stall_log.flush()
	_think_ms_prev = 0
	sec_t += delta
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
	if started and not bool(sim.game_finished):
		think_t += delta
		if think_t >= think_every:
			think_t = 0.0
			var think_start := Time.get_ticks_usec()
			player.think(sim)
			_think_ms_prev = int((Time.get_ticks_usec() - think_start) / 1000)
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
	if shot_index < shots.size() and t >= float(shots[shot_index][0]) and not busy:
		var s: Array = shots[shot_index]
		shot_index += 1
		_run_shot(String(s[1]), String(s[2]))
	if t >= duration and not busy:
		_note("unfocused_frames=%d" % unfocused_frames)
		_note("gate end t=%.0f day=%d pop=%d buildings=%d finished=%s" % [t, int(sim.day_count), int(sim.population_current), sim.buildings.size(), str(sim.game_finished)])
		game.get_tree().quit()


func _hall_hp(sim) -> int:
	for b in sim.buildings:
		if String(b.get("type", "")) == "TOWN_HALL":
			return int(b.get("hp", -1))
	return -1


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
	game.get_viewport().get_texture().get_image().save_png(dir.path_join(name + ".png"))
	_note("shot %s t=%.0f" % [name, t])
	match action:
		"new_realm":
			game._start_from_menu()
			started = true
			_note("NEW REALM -> BEGIN seed=%d" % int(game.simulation_host.simulation.rng_seed))
		"log":
			game._toggle_event_log()
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
