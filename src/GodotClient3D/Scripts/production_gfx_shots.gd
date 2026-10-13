extends Node

## GPU shot harness for a normal Windows export.
## Active only when SNS_GFX_SHOTS=<dir> is set or --gfx-shots[=]<dir>
## is passed after `--`. Renders the GFX-D comparison cameras at 1920x1080,
## writes PNGs, and quits. Pauses the sim. Fog-edge is daytime.
## Parks the window off-screen from _init (before the first paint).
## Isolate user:// with APPDATA/LOCALAPPDATA (Windows) or XDG_DATA_HOME
## (Linux) — Godot ignores --user-data-dir. See docs/gfx/GPU_SHOTS.md.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Showcase = preload("res://src/GodotClient3D/Scripts/production_gfx_d_showcase.gd")
const CameraRig = preload("res://src/GodotClient3D/Scripts/production_isometric_camera_rig.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")

var dest := ""


func _init() -> void:
	# Window exists here, but the first frame has not painted. Park it
	# before the export flashes on the 4070 desktop. Also honour
	# --position if the user already shoved us off-screen.
	if _resolve_dest() == "" and OS.get_environment("SNS_GFX_OFFSCREEN") == "":
		return
	_park_window_offscreen()


func _ready() -> void:
	dest = _resolve_dest()
	if dest == "":
		set_process(false)
		return
	DirAccess.make_dir_recursive_absolute(dest)
	_park_window_offscreen()
	print("GPU_SHOTS ready pos=%s screens=%d" % [str(DisplayServer.window_get_position(0)), DisplayServer.get_screen_count()])
	_run.call_deferred()


func _park_window_offscreen() -> void:
	if DisplayServer.get_name() == "headless":
		return
	# --position is applied by the engine before scripts; keep it if the
	# window is already off the primary desktop. Otherwise park it.
	var existing := DisplayServer.window_get_position(0)
	if existing.x > -1000 or existing.y > -1000:
		DisplayServer.window_set_position(Vector2i(-10000, -10000), 0)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true, 0)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true, 0)
	var win := get_window()
	if win != null:
		win.borderless = true
		win.unresizable = true
		win.position = Vector2i(-10000, -10000)
		win.size = Vector2i(1920, 1080)


func _greybox_dest() -> String:
	for argument in OS.get_cmdline_user_args():
		if String(argument).begins_with("--greybox-shots="):
			return String(argument).trim_prefix("--greybox-shots=")
	return ""


func _resolve_dest() -> String:
	if _greybox_dest() != "":
		return _greybox_dest()
	var env := OS.get_environment("SNS_GFX_SHOTS")
	if env != "":
		return env
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		var argument := String(args[i])
		if argument.begins_with("--gfx-shots="):
			return argument.trim_prefix("--gfx-shots=")
		if argument == "--gfx-shots" and i + 1 < args.size():
			return String(args[i + 1])
	return ""


func _run() -> void:
	if _greybox_dest() != "":
		await _run_greybox()
		return
	var win := get_window()
	win.size = Vector2i(1920, 1080)
	if DisplayServer.get_name() != "headless":
		win.position = Vector2i(-10000, -10000)
	print("GPU_SHOTS adapter=%s | %s | api=%s" % [RenderingServer.get_video_adapter_vendor(), RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_api_version()])
	print("GPU_SHOTS method=%s window=%s pos=%s dest=%s" % [str(ProjectSettings.get_setting("rendering/renderer/rendering_method")), str(win.size), str(win.position), dest])
	for _i in 5:
		await get_tree().process_frame
	var game: Node = get_tree().current_scene
	if game == null or not game.has_method("start_new_3d"):
		print("GPU_SHOTS FAIL no game scene")
		get_tree().quit(2)
		return

	var shot_seed := _resolve_seed(game)
	print("GPU_SHOTS seed=%d" % shot_seed)
	game.start_new_3d(shot_seed)
	game._hide_start_menu()
	game.simulation_host.paused = true
	var sim = game.simulation_host.simulation
	var showcase := Showcase.apply(sim)
	print("GPU_SHOTS showcase=%s" % str(showcase))
	sim.is_night = false
	sim.phase_time = 80.0
	game._update_day_night_lighting()
	game._sync_presentation()
	var home: Vector3 = game.world_view.tile_to_world(Vector2(sim.town_hall_position) + Vector2(1.5, 1.5))
	game.camera_rig.compose_view(home, CameraRig.NORMAL_ZOOM)
	await _capture("showcase_day.png")
	if game.camera_rig.camera != null:
		game.camera_rig.target_zoom = 42.0
		game.camera_rig.camera.size = 42.0
	await _capture("showcase_wide.png")

	# Fresh opening day on the same seed (no showcase).
	var tree := get_tree()
	tree.current_scene = null
	game.queue_free()
	await tree.process_frame
	game = Scene.instantiate()
	tree.root.add_child(game)
	tree.current_scene = game
	await tree.process_frame
	await tree.process_frame
	game.start_new_3d(shot_seed)
	game._hide_start_menu()
	game.simulation_host.paused = true
	sim = game.simulation_host.simulation
	sim.is_night = false
	sim.phase_time = 80.0
	game._update_day_night_lighting()
	game._sync_presentation()
	home = game.world_view.tile_to_world(Vector2(sim.town_hall_position) + Vector2(1.5, 1.5))
	game.camera_rig.compose_view(home, CameraRig.NORMAL_ZOOM)
	await _capture("opening_day.png")
	game.camera_rig.compose_view(home, 34.0)
	await _capture("after_day_close.png")

	# Scout (Y) toward the west fog.
	var guard := _ensure_patrol_guard(sim)
	var origin: Vector2i = guard.get("position", sim.town_hall_position)
	var fog_tile := Vector2i(1, clampi(origin.y, 1, sim.map_size.y - 2))
	if not sim.is_inside_map(fog_tile):
		fog_tile = Vector2i(2, 2)
	var scout_result: Dictionary = sim.request_scout_direction(int(guard.get("id", 0)), fog_tile)
	print("GPU_SHOTS scout=%s" % str(scout_result))
	game._sync_presentation()
	if game.has_method("_update_ui"):
		game._update_ui()
	game.camera_rig.compose_view(home, CameraRig.NORMAL_ZOOM)
	await _capture("scout_day.png")

	# Night raid.
	game.camera_rig.compose_view(home, CameraRig.NORMAL_ZOOM)
	sim.is_night = true
	sim.phase_time = 20.0
	if sim.enemies == null or sim.enemies.is_empty():
		if sim.has_method("_spawn_enemy"):
			sim._spawn_enemy(sim.town_hall_position + Vector2i(-18, 2), 30, 1, 0.0, 0, sim.ENEMY_RAIDER)
			sim._spawn_enemy(sim.town_hall_position + Vector2i(-20, 4), 30, 1, 0.0, 0, sim.ENEMY_RAIDER)
	game._update_day_night_lighting()
	game._sync_presentation()
	if game.has_method("_update_ui"):
		game._update_ui()
	await _capture("night_raid.png")

	# Fog edge — daytime, zoom 68. GFX-D left this at night.
	sim.is_night = false
	sim.phase_time = 80.0
	game._update_day_night_lighting()
	game._sync_presentation()
	game.camera_rig.compose_view(home, 68.0)
	await _capture("fog_edge.png")

	print("GPU_SHOTS PASS dir=%s" % dest)
	tree.quit(0)


func _resolve_seed(game: Node) -> int:
	var env := OS.get_environment("SNS_GFX_SEED")
	if env != "":
		return int(env)
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		var argument := String(args[i])
		if argument.begins_with("--gfx-seed="):
			return int(argument.trim_prefix("--gfx-seed="))
		if argument == "--gfx-seed" and i + 1 < args.size():
			return int(args[i + 1])
	return int(game.DEFAULT_SEED)


func _ensure_patrol_guard(sim) -> Dictionary:
	for worker_value in sim.workers:
		var worker: Dictionary = worker_value
		if sim.has_method("is_patrol_scout") and sim.is_patrol_scout(worker):
			return worker
	var spawned: Dictionary = sim._create_patrol_worker(0, "gfx_shots_guard")
	sim.workers.append(spawned)
	sim.soldiers_total = maxi(int(sim.soldiers_total), 1)
	return spawned


func _capture(filename: String) -> void:
	for _i in 12:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	if image != null and not image.is_empty():
		var path := dest.path_join(filename)
		var err := image.save_png(path)
		print("GPU_SHOTS wrote %s size=%s err=%d" % [path, str(image.get_size()), err])
	else:
		print("GPU_SHOTS empty image %s" % filename)


## Visual Reset S1 greybox matrix: 1920x1200, per seed: opening / close /
## dusk / night on the real opening (real fog), plus crater + overview with
## the map revealed (landform review only). Sim paused; no gameplay change.
func _run_greybox() -> void:
	var win := get_window()
	win.size = Vector2i(1920, 1200)
	get_viewport().size = Vector2i(1920, 1200)
	for _i in 5:
		await get_tree().process_frame
	var game: Node = get_tree().current_scene
	var shot_seed := _resolve_seed(game)
	print("GREYBOX_SHOTS seed=%d adapter=%s" % [shot_seed, RenderingServer.get_video_adapter_name()])
	game.start_new_3d(shot_seed)
	game._hide_start_menu()
	game.simulation_host.paused = true
	var sim = game.simulation_host.simulation
	var wv = game.world_view
	var home: Vector3 = wv.tile_to_world(Vector2(sim.town_hall_position) + Vector2(1.5, 1.5))
	var notes := FileAccess.open(dest.path_join("greybox_notes.txt"), FileAccess.WRITE)
	notes.store_line("seed=%d hall=%s shard=%s pit=%.1f landform_ms=%.0f" % [shot_seed, str(sim.town_hall_position), str(sim.shard_position), float(sim.crater_pit_radius), float(wv.landform.build_ms) if wv.landform != null else -1.0])
	var plan := [["opening_day", false, 80.0, CameraRig.NORMAL_ZOOM], ["close_day", false, 80.0, 14.0], ["dusk", false, float(sim.DAY_LENGTH_SECONDS) - 6.0, CameraRig.NORMAL_ZOOM], ["night", true, 30.0, CameraRig.NORMAL_ZOOM]]
	for item in plan:
		sim.is_night = bool(item[1])
		sim.phase_time = float(item[2])
		game._update_day_night_lighting()
		game._sync_presentation()
		game.camera_rig.compose_view(home, float(item[3]))
		_drain_streaming(wv)
		await _capture("%s.png" % item[0])
		notes.store_line("%s draw_calls=%d prims=%d" % [item[0], int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))])
	# Landform review: reveal everything, day light.
	for y in sim.map_size.y:
		for x in sim.map_size.x:
			sim.revealed_tiles["%d,%d" % [x, y]] = true
	sim.is_night = false
	sim.phase_time = 80.0
	game._update_day_night_lighting()
	game._sync_presentation()
	# Landform review only: no fog-of-war mist over the revealed map.
	if wv.fog_root != null:
		wv.fog_root.visible = false
	if wv.fog_screen != null:
		wv.fog_screen.visible = false
	var crater: Vector3 = wv.tile_to_world(Vector2(sim.shard_position))
	# Rebuild every chunk after the reveal so nature/forest exists map-wide.
	var span: Vector2i = wv._chunk_span()
	var focus_tile := Vector2i((Vector2(sim.town_hall_position) + Vector2(sim.shard_position)) * 0.5)
	var focus_chunk: Vector2i = wv.chunk_of_tile(focus_tile)
	for cy in span.y:
		for cx in span.x:
			var cc := Vector2i(cx, cy)
			var near: bool = absi(cc.x - focus_chunk.x) <= 1 and absi(cc.y - focus_chunk.y) <= 1
			wv._rebuild_chunk(cc, wv.CHUNK_LOD_NEAR if near else wv.CHUNK_LOD_FAR, false)
	wv.chunk_queue.clear()
	game.camera_rig.compose_view(home.lerp(crater, 0.55), 72.0)
	_drain_streaming(wv)
	for _k in 3:
		game._sync_presentation()
		await get_tree().process_frame
	await _capture("crater_frontier_day.png")
	game.camera_rig.compose_view(home.lerp(crater, 0.5), 150.0)
	_drain_streaming(wv)
	await _capture("overview_day.png")
	notes.close()
	print("GREYBOX_SHOTS PASS dir=%s" % dest)
	get_tree().quit(0)


func _drain_streaming(wv) -> void:
	if wv == null or not wv.has_method("stream_chunks"):
		return
	for _i in 400:
		wv.stream_chunks(100000000)
		if wv.chunk_queue.is_empty():
			break
