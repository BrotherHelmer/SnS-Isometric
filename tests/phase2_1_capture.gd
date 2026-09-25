extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")

var shot := "house"
var output_path := "res://artifacts/phase2_1/screenshots/01_human_vs_house.png"
var capture_size := Vector2i(1920, 1080)


func _init() -> void:
	print("PHASE2_1_CAPTURE_START")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--shot="):
			shot = argument.trim_prefix("--shot=")
		elif argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")
	call_deferred("_run")


func _run() -> void:
	print("PHASE2_1_CAPTURE_INSTANTIATE")
	root.size = capture_size
	DisplayServer.window_set_size(capture_size)
	var game := Scene.instantiate()
	root.add_child(game)
	print("PHASE2_1_CAPTURE_FIXTURE")
	await process_frame
	game.fixture_stage = "construction" if shot == "construction" else "developed"
	game._apply_requested_fixture()
	game.simulation_host.paused = true
	game._sync_presentation()
	print("PHASE2_1_CAPTURE_CONFIGURE")
	game.ui_layer.visible = false
	_configure_shot(game)
	for frame in 24:
		await process_frame
	print("PHASE2_1_CAPTURE_READBACK")
	# Headless compatibility rendering does not always emit frame_post_draw.
	# Force the final frame before reading the viewport texture instead.
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	var absolute_path := ProjectSettings.globalize_path(output_path)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	if image.save_png(absolute_path) != OK:
		push_error("Phase 2.1 final capture failed: %s" % absolute_path)
		quit(1)
		return
	print("PHASE2_1_CAPTURE_PASS shot=%s path=%s size=%dx%d" % [shot, absolute_path, image.get_width(), image.get_height()])
	game.queue_free()
	await process_frame
	quit(0)


func _configure_shot(game) -> void:
	match shot:
		"house":
			var house := _find_building(game, Defs.BUILDING_HOUSE)
			_stage_worker(game, house, "entrance", 0, Vector3(0.78, 0.0, 0.18))
			_focus(game, house, 19.0, Vector3(0.0, 0.0, 0.55))
		"lumber":
			var lumber := _find_building(game, Defs.BUILDING_LUMBER_CAMP)
			_stage_worker_by_type(game, lumber, "woodcutter", "workyard_left", Vector3(0.45, 0.0, 0.15))
			_focus(game, lumber, 20.5, Vector3(0.0, 0.0, -0.45))
		"hierarchy":
			var town_hall := _find_building(game, Defs.BUILDING_TOWN_HALL)
			var house := _find_building(game, Defs.BUILDING_HOUSE)
			_stage_worker(game, town_hall, "entrance", 0, Vector3(0.76, 0.0, 0.18))
			_stage_worker(game, house, "entrance", 1, Vector3(0.76, 0.0, 0.18))
			var midpoint := (town_hall.global_position + house.global_position) * 0.5
			game.camera_rig.compose_view(midpoint, 27.0)
		"village":
			var center := Vector2(game.simulation_host.simulation.town_hall_position) + Vector2(6.0, 6.0)
			game.camera_rig.compose_view(game.world_view.tile_to_world(center), 30.0)
		"forest":
			var lumber := _find_building(game, Defs.BUILDING_LUMBER_CAMP)
			_stage_worker_by_type(game, lumber, "woodcutter", "entrance", Vector3(0.72, 0.0, 0.20))
			_focus(game, lumber, 26.0, Vector3(4.2, 0.0, 1.8))
		"construction":
			var site := _find_construction(game)
			var house := _find_building(game, Defs.BUILDING_HOUSE)
			_stage_worker(game, site, "construction_delivery", 0, Vector3(0.72, 0.0, 0.12))
			var midpoint := (site.global_position + house.global_position) * 0.5
			# Look back toward the forest edge so the site and delivery worker
			# remain readable without changing the deterministic fixture.
			game.camera_rig.rotation.y += PI
			game.camera_rig.compose_view(midpoint, 25.0)


func _find_building(game, type_name: String) -> ProductionBuildingView3D:
	for value in game.world_view.building_views.values():
		var view: ProductionBuildingView3D = value
		if view.building_type == type_name and not view.is_construction:
			return view
	return null


func _find_construction(game) -> ProductionBuildingView3D:
	for value in game.world_view.building_views.values():
		var view: ProductionBuildingView3D = value
		if view.is_construction:
			return view
	return null


func _stage_worker(game, building: ProductionBuildingView3D, socket_name: String, index: int, offset: Vector3) -> void:
	if building == null:
		return
	var views: Array = game.world_view.character_views.values()
	if index < 0 or index >= views.size():
		return
	_place_worker(views[index], building, socket_name, offset)


func _stage_worker_by_type(game, building: ProductionBuildingView3D, worker_type: String, socket_name: String, offset: Vector3) -> void:
	if building == null:
		return
	for value in game.world_view.character_views.values():
		var worker: ProductionCharacterView3D = value
		if worker.worker_type == worker_type:
			_place_worker(worker, building, socket_name, offset)
			return
	_stage_worker(game, building, socket_name, 0, offset)


func _place_worker(worker: ProductionCharacterView3D, building: ProductionBuildingView3D, socket_name: String, offset: Vector3) -> void:
	worker.has_target = false
	worker.global_position = building.socket_world(socket_name) + building.global_basis * offset
	worker.rotation.y = building.rotation.y + PI


func _focus(game, building: ProductionBuildingView3D, zoom: float, offset: Vector3) -> void:
	if building != null:
		game.camera_rig.compose_view(building.camera_focus_position() + offset, zoom)
