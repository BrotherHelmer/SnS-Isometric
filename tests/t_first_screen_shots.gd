extends SceneTree

## First-screen 1920×1080 capture. Same start every time: DEFAULT_SEED,
## new game, no input. Used for BEFORE (GFX-S) and AFTER (this branch).

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")

var out_dir := "res://artifacts/first_screen"
var shot_name := "after_first_screen.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	if OS.get_environment("FIRST_SCREEN_OUT") != "":
		out_dir = OS.get_environment("FIRST_SCREEN_OUT")
	if OS.get_environment("FIRST_SCREEN_NAME") != "":
		shot_name = OS.get_environment("FIRST_SCREEN_NAME")
	var dest := ProjectSettings.globalize_path(out_dir) if out_dir.begins_with("res://") else out_dir
	DirAccess.make_dir_recursive_absolute(dest)

	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var t0 := Time.get_ticks_msec()
	game.start_new_3d(game.DEFAULT_SEED)
	var start_ms := float(Time.get_ticks_msec() - t0)
	game._hide_start_menu()
	game.simulation_host.paused = true
	if game.has_method("_update_ui"):
		game._update_ui()
	# Exact same start: new game, default seed, no input. Opening camera as
	# the game itself composed it — do not override zoom here.
	for _i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_viewport().get_texture().get_image()
	if image != null and not image.is_empty():
		image.save_png(dest.path_join(shot_name))
		print("FIRST_SCREEN wrote %s size=%dx%d start_ms=%.1f zoom=%.1f" % [
			dest.path_join(shot_name), image.get_width(), image.get_height(),
			start_ms, game.camera_rig.target_zoom if game.camera_rig != null else -1.0
		])
	else:
		print("FIRST_SCREEN FAIL empty viewport")
		game.queue_free()
		quit(1)
		return
	print("FIRST_SCREEN placement='%s' panel=%s toast=%s rival=%s console_h=%.0f" % [
		game.placement_type,
		str(game.placement_panel.visible) if game.placement_panel != null else "nil",
		str(game.alert_panel.visible) if game.alert_panel != null else "nil",
		str(game.status_plate.visible) if game.status_plate != null else "nil",
		game.CONSOLE_HEIGHT
	])
	game.queue_free()
	await process_frame
	print("FIRST_SCREEN PASS")
	quit(0)
