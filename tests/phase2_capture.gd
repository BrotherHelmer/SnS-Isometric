extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")

var stage := "fresh"
var output_path := "res://artifacts/phase2/screenshots/01_fresh_generated_map.png"
var capture_size := Vector2i(1920, 1080)


func _init() -> void:
	if DisplayServer.get_name() == "headless":
		print("PHASE2_CAPTURE SKIP: headless display has no readable framebuffer.")
		quit(0)
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--stage="):
			stage = argument.trim_prefix("--stage=")
		elif argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")
	call_deferred("_run")


func _run() -> void:
	root.size = capture_size
	DisplayServer.window_set_size(capture_size)
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	if stage != "fresh":
		game.fixture_stage = stage
		game._apply_requested_fixture()
	game.simulation_host.paused = true
	game._sync_presentation()
	await process_frame
	_configure_view(game)
	game._update_ui()
	# Allow font atlases, imported models, animations, and the resized 1080p
	# viewport to settle before the evidence frame is read back.
	for frame in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var absolute_path := ProjectSettings.globalize_path(output_path)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var result := image.save_png(absolute_path)
	if result != OK:
		push_error("Phase 2 screenshot failed: %s" % absolute_path)
		quit(1)
		return
	var metrics: Dictionary = game.world_view.presentation_metrics()
	print("PHASE2_CAPTURE_PASS stage=%s path=%s size=%dx%d workers=%d roads=%d buildings=%d" % [
		stage,
		absolute_path,
		image.get_width(), image.get_height(),
		int(metrics.get("real_workers", 0)),
		int(metrics.get("road_views", 0)),
		int(metrics.get("building_views", 0)),
	])
	game.queue_free()
	await process_frame
	quit(0)


func _configure_view(game) -> void:
	game.ui_layer.visible = stage in ["placement", "construction", "lumber", "second_chain", "reloaded"]
	var ids: Dictionary = game.fixture_result.get("building_ids", {})
	match stage:
		"fresh":
			var town_center := Vector2(game.simulation_host.simulation.town_hall_position) + Vector2(1.5, 1.5)
			game.camera_rig.compose_view(game.world_view.tile_to_world(town_center), 50.0)
		"early":
			_focus_type(game, ids, Defs.BUILDING_HOUSE, 34.0)
		"placement":
			var candidates: Dictionary = game.fixture_result.get("placement_candidates", {})
			if candidates.has(Defs.BUILDING_LUMBER_CAMP):
				game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(candidates[Defs.BUILDING_LUMBER_CAMP])), 28.0)
		"construction":
			_focus_type(game, ids, Defs.BUILDING_LUMBER_CAMP, 24.0)
			if ids.has(Defs.BUILDING_LUMBER_CAMP):
				game.select_building(int(ids[Defs.BUILDING_LUMBER_CAMP]))
		"lumber":
			_focus_type(game, ids, Defs.BUILDING_LUMBER_CAMP, 25.0)
			_select_cargo_worker(game, Defs.RESOURCE_WOOD)
		"second_chain":
			_focus_type(game, ids, Defs.BUILDING_FARM, 26.0)
			_select_cargo_worker(game, Defs.RESOURCE_WHEAT)
		"developed":
			var town_center := Vector2(game.simulation_host.simulation.town_hall_position) + Vector2(1.5, 1.5)
			game.camera_rig.compose_view(game.world_view.tile_to_world(town_center), 42.0)
		"reloaded":
			var town_center := Vector2(game.simulation_host.simulation.town_hall_position) + Vector2(1.5, 1.5)
			game.camera_rig.compose_view(game.world_view.tile_to_world(town_center), 36.0)


func _focus_type(game, ids: Dictionary, building_type: String, zoom: float) -> void:
	if ids.has(building_type):
		game.camera_rig.compose_view(game.world_view.focus_for_building(int(ids[building_type])), zoom)


func _select_cargo_worker(game, resource_type: String) -> void:
	for worker_value in game.simulation_host.simulation.get_workers():
		var worker: Dictionary = worker_value
		if String(worker.get("carried_resource", "")) == resource_type and int(worker.get("carried_amount", 0)) > 0:
			game.select_worker(int(worker.get("id", 0)))
			return
