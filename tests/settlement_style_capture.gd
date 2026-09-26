extends SceneTree
const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Identity = preload("res://src/GodotClient3D/Scripts/production_identity.gd")
const OUT := "res://artifacts/opening_style/rest"
var brightness: Dictionary = {}
func _init() -> void: call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var game = Scene.instantiate()
	root.add_child(game)
	await process_frame
	game._start_review_seed()
	game.simulation_host.paused = true
	game.set_process(false)
	assert(game.world_view.terrain_mesh_instance.material_override is ShaderMaterial)
	for character in game.world_view.character_views.values():
		assert(character.skeleton != null and character.playback.get_current_node() != "Start")
	if DisplayServer.get_name() != "headless":
		root.size = Vector2i(1600, 900)
		DisplayServer.window_set_size(root.size)
		var home: Vector3 = game.world_view.tile_to_world(Vector2(game.simulation_host.simulation.town_hall_position) + Vector2(1.5, 1.5))
		game.camera_rig.compose_view(home, 22.0)
		await capture("opening_day")
		assert(game.simulation_host.load_from_path("res://artifacts/phase3_2/persistence/eighteen_step_playthrough.json"))
		game._initialize_presentation()
		game.simulation_host.paused = true
		game._update_ui()
		game._tick_minimap(0.2)
		home = game.world_view.tile_to_world(Vector2(game.simulation_host.simulation.town_hall_position) + Vector2(1.5, 1.5))
		game.camera_rig.compose_view(home, 34.0)
		for period in ["day", "dusk", "night"]:
			game._apply_lighting_palette(Identity.lighting_palette(period))
			for view in game.world_view.building_views.values():
				view._update_night_presentation(period != "day", 0)
			await capture("settlement_" + period)
		assert(float(brightness["settlement_night"]) > 0.02, "night terrain remains readable")
		assert(float(brightness["settlement_night"]) < float(brightness["settlement_day"]) * 0.6, "night is visibly darker in rendered pixels")
		var report := FileAccess.open(OUT + "/brightness.json", FileAccess.WRITE)
		report.store_string(JSON.stringify(brightness, "\t"))
	game.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	print("SETTLEMENT_STYLE PASS")
	quit()
func capture(label: String) -> void:
	await create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(OUT + "/" + label + ".png")
	var total := 0.0
	var samples := 0
	# Same world rectangle, excluding HUD, minimap and the unknown-map margin.
	for y in range(220, 750, 8):
		for x in range(350, 1100, 8):
			total += image.get_pixel(x, y).get_luminance()
			samples += 1
	brightness[label] = total / samples
