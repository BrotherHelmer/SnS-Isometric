extends SceneTree

## Rendered review evidence; human inspection of these images is required.
const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const OUTPUT := "res://artifacts/release_candidate/visual"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Visual capture needs a rendered window.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var game = Scene.instantiate()
	root.add_child(game)
	await process_frame
	game._start_review_seed()
	game.simulation_host.paused = true
	await create_timer(0.5).timeout
	game._update_ui()
	game._tick_minimap(0.2)
	game.set_process(false)
	var home: Vector3 = game.world_view.tile_to_world(Vector2(game.simulation_host.simulation.town_hall_position))
	for resolution in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		DisplayServer.window_set_size(resolution)
		game.pressure_meter.set_pressure({"band": "QUIET", "value": 0.0})
		for zoom in [18.0, 22.0, 58.0]:
			game.camera_rig.compose_view(home, zoom)
			await _capture("opening_%d_%d_zoom%d" % [resolution.x, resolution.y, int(zoom)])
		for band in ["QUIET", "STIRRING", "DANGEROUS", "SEVERE", "CRITICAL"]:
			game.pressure_meter.set_pressure({"band": band, "value": 0.0 if band == "QUIET" else 100.0})
			await _capture("pressure_%d_%s" % [resolution.x, band.to_lower()])
	game.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	print("RELEASE_VISUAL_CAPTURE PASS images require visual review")
	quit()

func _capture(label: String) -> void:
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + "/" + label + ".png")
