extends SceneTree

## GFX-R comparison cameras. Same gameplay cameras as GFX-P.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Showcase = preload("res://src/GodotClient3D/Scripts/production_gfx_d_showcase.gd")
const CameraRig = preload("res://src/GodotClient3D/Scripts/production_isometric_camera_rig.gd")

var out_dir := "res://artifacts/gfx_r/after"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	if OS.get_environment("GFX_R_SHOTS_OUT") != "":
		out_dir = OS.get_environment("GFX_R_SHOTS_OUT")
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
	var opening: Vector3 = game.world_view.opening_camera_focus()

	sim.is_night = false
	sim.phase_time = 80.0
	game._update_day_night_lighting()
	game._sync_presentation()
	game.camera_rig.compose_view(opening, CameraRig.NORMAL_ZOOM)
	await _capture(dest, "opening_day.png")
	await _capture(dest, "pkg1_creek.png")
	await _capture(dest, "pkg4_meadow.png")
	await _capture(dest, "pkg5_composition.png")
	await _capture(dest, "pkg5_ridge.png")

	game.camera_rig.compose_view(home, 34.0)
	await _capture(dest, "after_day_close.png")
	await _capture(dest, "pkg3_castle.png")
	game.camera_rig.compose_view(home, CameraRig.STRATEGIC_ZOOM)
	await _capture(dest, "after_day_far.png")
	game.camera_rig.compose_view(home, CameraRig.STRATEGIC_ZOOM)
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
	if sim.enemies != null:
		sim.enemies.clear()
	game.raid_banner_dismissed = true
	game.raid_banner_active = false
	if game.alert_panel != null:
		game.alert_panel.visible = false
	var showcase := Showcase.apply(sim)
	print("GFX_R_SHOTS showcase=%s" % str(showcase))
	game._update_day_night_lighting()
	game._sync_presentation()
	if game.has_method("_update_ui"):
		game._update_ui()
	if game.world_view.road_control_texture != null:
		var control_img: Image = game.world_view.road_control_texture.get_image()
		if control_img != null:
			control_img.save_png(dest.path_join("pkg2_road_control.png"))
	game.camera_rig.compose_view(home, CameraRig.NORMAL_ZOOM)
	await _capture(dest, "showcase_day.png")
	await _capture(dest, "pkg2_roads.png")
	game.world_view.set_terrain_debug(3)
	for _dbg in 8:
		await process_frame
	await _capture(dest, "pkg2_road_mask_showcase.png")
	game.world_view.set_terrain_debug(0)
	game.camera_rig.compose_view(home, 34.0)
	await _capture(dest, "pkg3_architecture.png")
	game.camera_rig.compose_view(home, 39.0)
	await _capture(dest, "showcase_wide.png")

	print("GFX_R_SHOTS PASS dir=%s" % dest)
	game.queue_free()
	await process_frame
	quit(0)


func _capture(dest: String, filename: String) -> void:
	for _i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_viewport().get_texture().get_image()
	if image != null and not image.is_empty():
		image.save_png(dest.path_join(filename))
		print("GFX_R_SHOTS wrote %s" % dest.path_join(filename))
