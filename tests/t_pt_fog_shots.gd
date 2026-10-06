extends SceneTree

## After-fix shots: gate camera, whole-map edge fog, and two pan poses.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const SAVE_PATH := "res://artifacts/phase3_2/persistence/eighteen_step_playthrough.json"

var out_dir := "res://artifacts/pt_fog"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	if OS.get_environment("PT_FOG_OUT") != "":
		out_dir = OS.get_environment("PT_FOG_OUT")
	var dest_root := ProjectSettings.globalize_path(out_dir) if out_dir.begins_with("res://") else out_dir
	DirAccess.make_dir_recursive_absolute(dest_root)
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		game.simulation_host.load_from_path(SAVE_PATH)
		game._initialize_presentation()
	else:
		game.start_new_3d(game.DEFAULT_SEED)
	game._hide_start_menu()
	game.simulation_host.paused = true
	game.set_process(false)
	var sim = game.simulation_host.simulation
	var home: Vector3 = game.world_view.tile_to_world(Vector2(sim.town_hall_position) + Vector2(1.5, 1.5))
	for period in [
		{"name": "day", "night": false, "phase": 80.0},
		{"name": "dusk", "night": false, "phase": float(sim.DAY_LENGTH_SECONDS) - 6.0},
		{"name": "night", "night": true, "phase": 20.0}
	]:
		sim.is_night = bool(period["night"])
		sim.phase_time = float(period["phase"])
		game._update_day_night_lighting()
		game._sync_presentation()
		game.camera_rig.compose_view(home, 34.0)
		await _capture(dest_root, "after_gate_%s.png" % period["name"])
		game.camera_rig.compose_view(home, 68.0)
		await _capture(dest_root, "after_edge_%s.png" % period["name"])
		game.camera_rig.compose_view(home, 18.0)
		await _capture(dest_root, "after_pan_a_%s.png" % period["name"])
		game.camera_rig.compose_view(home + Vector3(8.0, 0.0, -6.0), 18.0)
		await _capture(dest_root, "after_pan_b_%s.png" % period["name"])
	print("PT_FOG_SHOTS PASS dir=%s" % dest_root)
	game.queue_free()
	quit(0)


func _capture(dest_root: String, filename: String) -> void:
	for _i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var viewport_texture: ViewportTexture = root.get_viewport().get_texture()
	var image: Image = viewport_texture.get_image() if viewport_texture != null else null
	var dest := dest_root.path_join(filename)
	if image != null and not image.is_empty():
		image.save_png(dest)
		print("PT_FOG_SHOT wrote %s" % dest)
	else:
		push_error("PT_FOG_SHOT empty %s" % dest)
