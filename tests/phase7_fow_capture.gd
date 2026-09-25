extends SceneTree

## Windowed captures of founding view and the fog edge after the volume fix.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")

const OUTPUT_DIR := "res://artifacts/phase7/screenshots"
const CAPTURE_SIZE := Vector2i(1600, 900)


func _init() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Phase 7 FOW captures require a windowed framebuffer.")
		quit(1)
		return
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	call_deferred("_run")


func _run() -> void:
	root.size = CAPTURE_SIZE
	DisplayServer.window_set_size(CAPTURE_SIZE)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.start_new_3d(260821)
	game._sync_presentation()
	game._update_ui()
	game._update_day_night_lighting()
	game._tick_minimap(0.2)
	game._update_shard_compass()
	for _frame in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	_save("01_founding_loop.png")

	var simulation = game.simulation_host.simulation
	var edge: Vector2i = simulation.town_hall_position + Vector2i(-8, 10)
	game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(edge)), 28.0)
	game._sync_presentation()
	game._update_ui()
	for _frame in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	_save("02_fog_edge.png")

	var corner: Vector2i = simulation.town_hall_position + Vector2i(-10, -10)
	corner.x = clampi(corner.x, 0, simulation.map_size.x - 1)
	corner.y = clampi(corner.y, 0, simulation.map_size.y - 1)
	game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(corner)), 22.0)
	game._sync_presentation()
	game._update_ui()
	for _frame in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	_save("03_corner_pan.png")

	print("PHASE7_FOW_CAPTURE PASS")
	quit(0)


func _save(file_name: String) -> void:
	var image := root.get_texture().get_image()
	var path := "%s/%s" % [OUTPUT_DIR, file_name]
	var absolute_path := ProjectSettings.globalize_path(path)
	var result := image.save_png(absolute_path)
	if result != OK:
		push_error("Capture failed: %s" % absolute_path)
		quit(1)
		return
	print("PHASE7_CAPTURE_PASS path=%s size=%dx%d" % [absolute_path, image.get_width(), image.get_height()])
