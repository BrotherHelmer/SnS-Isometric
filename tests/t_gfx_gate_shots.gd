extends SceneTree

## Capture day / dusk / night frames plus road-tile masks for gfx_pixel_gates.py.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")

var out_dir := "res://artifacts/gfx1_gates"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	if OS.get_environment("GFX_GATE_OUT") != "":
		out_dir = OS.get_environment("GFX_GATE_OUT")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir) if out_dir.begins_with("res://") else out_dir)
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.start_new_3d(game.DEFAULT_SEED)
	game._hide_start_menu()
	for _i in 8:
		await process_frame
	var sim = game.simulation_host.simulation
	await _capture(game, sim, "day", false, 80.0, "gfx_day.png")
	await _capture(game, sim, "dusk", false, float(sim.DAY_LENGTH_SECONDS) - 6.0, "gfx_dusk.png")
	await _capture(game, sim, "night", true, 20.0, "gfx_night.png")
	game.queue_free()
	await process_frame
	print("GFX_GATE_SHOTS PASS dir=%s" % out_dir)
	quit(0)


func _capture(game, sim, _label: String, is_night: bool, phase: float, filename: String) -> void:
	sim.is_night = is_night
	sim.phase_time = phase
	game._update_day_night_lighting()
	for _i in 6:
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
