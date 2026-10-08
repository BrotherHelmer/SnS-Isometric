extends SceneTree

## GFX-B before/after shots from fixed cameras.
## Day close-up, far island, night raid, fog edge.
## Presentation only — no gameplay, no outline edits.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const SAVE_PATH := "res://artifacts/phase3_2/persistence/eighteen_step_playthrough.json"

var out_dir := "res://artifacts/gfx_b"
var label := "after"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	if OS.get_environment("GFX_B_OUT") != "":
		out_dir = OS.get_environment("GFX_B_OUT")
	if OS.get_environment("GFX_B_LABEL") != "":
		label = OS.get_environment("GFX_B_LABEL")
	var dest_root := ProjectSettings.globalize_path(out_dir) if out_dir.begins_with("res://") else out_dir
	DirAccess.make_dir_recursive_absolute(dest_root)
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var used_save := false
	if FileAccess.file_exists(SAVE_PATH):
		used_save = game.simulation_host.load_from_path(SAVE_PATH)
	if used_save:
		game._initialize_presentation()
	else:
		game.start_new_3d(game.DEFAULT_SEED)
	game._hide_start_menu()
	game.simulation_host.paused = true
	game.set_process(false)
	var sim = game.simulation_host.simulation
	var home: Vector3 = game.world_view.tile_to_world(Vector2(sim.town_hall_position) + Vector2(1.5, 1.5))
	print("GFX_B_SHOTS label=%s save=%s night=%s day=%d" % [label, str(used_save), str(sim.is_night), int(sim.day_count)])

	# Day close-up — castle, crops, roads.
	sim.is_night = false
	sim.phase_time = 80.0
	game._update_day_night_lighting()
	game._sync_presentation()
	game.camera_rig.compose_view(home, 34.0)
	await _capture(dest_root, "%s_day_close.png" % label)

	# Far view — whole island in the sea.
	_compose_far(game, home, 130.0)
	await _capture(dest_root, "%s_day_far.png" % label)

	# Fog edge — strategic zoom so unknown interior is in frame.
	game.camera_rig.compose_view(home, 68.0)
	await _capture(dest_root, "%s_fog_edge.png" % label)

	# Night raid — same close camera. Spawn raiders for the banner; do not
	# touch outline / scout / night-guard presentation.
	game.camera_rig.compose_view(home, 34.0)
	sim.is_night = true
	sim.phase_time = 20.0
	var town: Vector2i = sim.town_hall_position
	if sim.enemies == null or sim.enemies.is_empty():
		if sim.has_method("_spawn_enemy"):
			sim._spawn_enemy(town + Vector2i(-18, 2), 30, 1, 0.0, 0, sim.ENEMY_RAIDER)
			sim._spawn_enemy(town + Vector2i(-20, 4), 30, 1, 0.0, 0, sim.ENEMY_RAIDER)
	game._update_day_night_lighting()
	game._sync_presentation()
	if game.has_method("_update_ui"):
		game._update_ui()
	await _capture(dest_root, "%s_night_raid.png" % label)

	print("GFX_B_SHOTS PASS dir=%s" % dest_root)
	game.queue_free()
	await process_frame
	quit(0)


func _compose_far(game, home: Vector3, size: float) -> void:
	if game.camera_rig.camera != null:
		game.camera_rig.target_zoom = size
		game.camera_rig.camera.size = size
		game.camera_rig.position = Vector3(home.x, 0.0, home.z)
		game.camera_rig.target_position = Vector3(home.x, 0.0, home.z)


func _capture(dest_root: String, filename: String) -> void:
	for _i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	var viewport_texture: ViewportTexture = root.get_viewport().get_texture()
	var image: Image = viewport_texture.get_image() if viewport_texture != null else null
	var dest := dest_root.path_join(filename)
	if image != null and not image.is_empty():
		image.save_png(dest)
		print("GFX_B_SHOT wrote %s" % dest)
	else:
		push_error("GFX_B_SHOT empty %s" % dest)
