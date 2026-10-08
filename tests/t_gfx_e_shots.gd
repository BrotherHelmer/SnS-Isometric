extends SceneTree

## GFX-E comparison cameras: opening day, showcase, night, fog (day).
## Same framings as t_gfx_d_shots so GFX-D vs GFX-E sides stay honest.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Showcase = preload("res://src/GodotClient3D/Scripts/production_gfx_d_showcase.gd")
const CameraRig = preload("res://src/GodotClient3D/Scripts/production_isometric_camera_rig.gd")

var out_dir := "res://artifacts/gfx_e/after"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	if OS.get_environment("GFX_E_SHOTS_OUT") != "":
		out_dir = OS.get_environment("GFX_E_SHOTS_OUT")
	var dest := ProjectSettings.globalize_path(out_dir) if out_dir.begins_with("res://") else out_dir
	DirAccess.make_dir_recursive_absolute(dest)

	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.start_new_3d(game.DEFAULT_SEED)
	game._hide_start_menu()
	game.simulation_host.paused = true
	var sim = game.simulation_host.simulation
	var home: Vector3 = game.world_view.tile_to_world(Vector2(sim.town_hall_position) + Vector2(1.5, 1.5))

	sim.is_night = false
	sim.phase_time = 80.0
	game._update_day_night_lighting()
	game._sync_presentation()
	game.camera_rig.compose_view(home, CameraRig.NORMAL_ZOOM)
	await _capture(dest, "opening_day.png")
	game.camera_rig.compose_view(home, 34.0)
	await _capture(dest, "after_day_close.png")
	_compose_far(game, home, 130.0)
	await _capture(dest, "after_day_far.png")
	game.camera_rig.compose_view(home, 68.0)
	await _capture(dest, "after_fog_edge.png")

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
	await _capture(dest, "after_night_raid.png")

	sim.is_night = false
	sim.phase_time = 80.0
	var showcase := Showcase.apply(sim)
	print("GFX_E_SHOTS showcase=%s" % str(showcase))
	game._update_day_night_lighting()
	game._sync_presentation()
	game.camera_rig.compose_view(home, CameraRig.NORMAL_ZOOM)
	await _capture(dest, "showcase_day.png")
	game.camera_rig.compose_view(home, 42.0)
	await _capture(dest, "showcase_wide.png")

	print("GFX_E_SHOTS PASS dir=%s" % dest)
	game.queue_free()
	await process_frame
	quit(0)


func _compose_far(game: Node, home: Vector3, size: float) -> void:
	if game.camera_rig.camera == null:
		return
	game.camera_rig.target_zoom = size
	game.camera_rig.camera.size = size
	game.camera_rig.position = Vector3(home.x, 0.0, home.z)
	game.camera_rig.target_position = Vector3(home.x, 0.0, home.z)


func _capture(dest: String, filename: String) -> void:
	for _i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_viewport().get_texture().get_image()
	if image != null and not image.is_empty():
		image.save_png(dest.path_join(filename))
		print("GFX_E_SHOTS wrote %s" % dest.path_join(filename))
