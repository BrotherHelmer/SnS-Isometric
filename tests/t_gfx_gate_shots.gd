extends SceneTree

## Capture Day 3 / dusk / real Night 2 from the 18-step playthrough save.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const SAVE_PATH := "res://artifacts/phase3_2/persistence/eighteen_step_playthrough.json"

var out_dir := "res://artifacts/gfx1_gates"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	if OS.get_environment("GFX_GATE_OUT") != "":
		out_dir = OS.get_environment("GFX_GATE_OUT")
	var dest_root := ProjectSettings.globalize_path(out_dir) if out_dir.begins_with("res://") else out_dir
	DirAccess.make_dir_recursive_absolute(dest_root)
	if not FileAccess.file_exists(SAVE_PATH):
		push_error("GFX_GATE_SHOTS missing %s — run phase3_2_real_playthrough first" % SAVE_PATH)
		quit(1)
		return
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var method := RenderingServer.get_current_rendering_method()
	print("GFX_GATE_RENDERER method=%s" % method)
	if method != "forward_plus":
		push_error("GFX_GATE_SHOTS requires Forward+/Vulkan (got %s)" % method)
		quit(1)
		return
	if not game.simulation_host.load_from_path(SAVE_PATH):
		push_error("GFX_GATE_SHOTS failed to load %s" % SAVE_PATH)
		quit(1)
		return
	game._initialize_presentation()
	game._hide_start_menu()
	game.simulation_host.paused = true
	game.set_process(false)
	var sim = game.simulation_host.simulation
	var home: Vector3 = game.world_view.tile_to_world(Vector2(sim.town_hall_position) + Vector2(1.5, 1.5))
	game.camera_rig.compose_view(home, 34.0)
	print("GFX_GATE_SAVE night=%s day=%d phase=%.1f enemies=%d roads=%d" % [
		str(sim.is_night), int(sim.day_count), float(sim.phase_time),
		sim.enemies.size() if sim.enemies != null else 0, int(sim.connected_roads.size())
	])
	# Real Night 2 from the save (live raid).
	game._update_day_night_lighting()
	game._sync_presentation()
	await _capture(game, "gfx_night.png")
	# Day 3 after the save's night ends.
	sim._end_night()
	sim.phase_time = 80.0
	game._update_day_night_lighting()
	game._sync_presentation()
	await _capture(game, "gfx_day.png")
	# Golden hour: about 6 s before nightfall on that Day 3.
	sim.is_night = false
	sim.phase_time = float(sim.DAY_LENGTH_SECONDS) - 6.0
	game._update_day_night_lighting()
	game._sync_presentation()
	await _capture(game, "gfx_dusk.png")
	# Far zoom: island edge must read as water/horizon, not a teal void.
	game.camera_rig.compose_view(home, 68.0)
	await _capture(game, "gfx_far.png")
	game.camera_rig.compose_view(home, 34.0)
	print("GFX dusk sun/camera angle=%.1f energy=%.2f" % [game.sun_camera_angle_degrees(), game.sun_light.light_energy])
	await _sample_perf(game, "dusk")
	sim.is_night = false
	sim.phase_time = 80.0
	game._update_day_night_lighting()
	game._sync_presentation()
	await _sample_perf(game, "day")
	sim.is_night = true
	sim.phase_time = 20.0
	game._update_day_night_lighting()
	game._sync_presentation()
	await _sample_perf(game, "night")
	game._show_start_menu()
	game._author_title_composition()
	game._update_day_night_lighting()
	await _sample_perf(game, "first-view")
	game.queue_free()
	await process_frame
	print("GFX_GATE_SHOTS PASS dir=%s" % dest_root)
	quit(0)


func _capture(game, filename: String) -> void:
	for _i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var viewport_texture: ViewportTexture = game.get_viewport().get_texture()
	var image: Image = viewport_texture.get_image() if viewport_texture != null else null
	var dest := out_dir.path_join(filename)
	if dest.begins_with("res://"):
		dest = ProjectSettings.globalize_path(dest)
	if image != null and not image.is_empty():
		image.save_png(dest)
		game.write_gfx_tile_mask_json(dest.get_basename() + ".roads.json")
		print("GFX_GATE_SHOT wrote %s" % dest)


func _sample_perf(game, label: String) -> void:
	for _warm in 8:
		await process_frame
	var acc := 0.0
	var frames := 45
	for _i in frames:
		await process_frame
		acc += float(Performance.get_monitor(Performance.TIME_PROCESS))
	var ms := (acc / float(frames)) * 1000.0
	print("GFX_PERF %s frame_ms=%.3f frames=%d" % [label, ms, frames])
