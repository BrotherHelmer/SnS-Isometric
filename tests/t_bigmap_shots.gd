extends SceneTree

## 1920×1080 big-map deliverables: three first screens, a zoomed-out
## overview, and a province minimap that shows crater, rivals and resources.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const CameraRig = preload("res://src/GodotClient3D/Scripts/production_isometric_camera_rig.gd")

const SHOT_SEEDS := [260821, 261306, 261597]

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var dest := ProjectSettings.globalize_path("res://artifacts/bigmap")
	DirAccess.make_dir_recursive_absolute(dest)
	for seed_value in SHOT_SEEDS:
		var game := Scene.instantiate()
		root.add_child(game)
		await process_frame
		await process_frame
		game.start_new_3d(int(seed_value))
		game._hide_start_menu()
		game.simulation_host.paused = true
		if game.has_method("_update_ui"):
			game._update_ui()
		for _i in 6:
			await process_frame
			game.world_view.stream_chunks(12000)
		await RenderingServer.frame_post_draw
		_save(dest, "first_%d.png" % seed_value)
		if seed_value == SHOT_SEEDS[0]:
			game.camera_rig.configure_for_map(game.simulation_host.simulation.map_size)
			game.camera_rig.compose_view(game.world_view.opening_camera_focus(), CameraRig.PROVINCE_ZOOM)
			game.world_view.note_camera(game.camera_rig.target_position, CameraRig.PROVINCE_ZOOM)
			for _j in 8:
				await process_frame
				game.world_view.stream_chunks(12000)
			await RenderingServer.frame_post_draw
			_save(dest, "overview.png")
			if game.minimap != null:
				game.minimap.overview_mode = true
				game.minimap_expanded = true
				game.minimap.visible = true
				game.minimap.custom_minimum_size = Vector2(720, 720)
				if game.minimap.map_image != null:
					game.minimap.map_image.custom_minimum_size = Vector2(680, 680)
				game.minimap.redraw(game.current_frame_snapshot)
				await process_frame
				await RenderingServer.frame_post_draw
				_save(dest, "minimap.png")
				var atlas := game.minimap._render_map(game.simulation_host.simulation.map_size, game.current_frame_snapshot)
				if atlas != null:
					atlas.resize(1080, 1080, Image.INTERPOLATE_NEAREST)
					atlas.save_png(dest.path_join("minimap_atlas.png"))
		game.queue_free()
		await process_frame
	print("T_BIGMAP_SHOTS dest=%s" % dest)
	print("T_BIGMAP_SHOTS %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _save(dest: String, name_value: String) -> void:
	var image: Image = root.get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		failures.append("empty shot %s" % name_value)
		return
	image.save_png(dest.path_join(name_value))
	print("T_BIGMAP_SHOTS wrote %s %dx%d" % [name_value, image.get_width(), image.get_height()])
