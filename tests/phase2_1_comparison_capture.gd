extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")

var profile := "current"
var output_path := "res://artifacts/phase2_1/comparison/01_current_production_scale.png"
var capture_size := Vector2i(1920, 1080)


func _init() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--profile="):
			profile = argument.trim_prefix("--profile=")
		elif argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")
	call_deferred("_run")


func _run() -> void:
	root.size = capture_size
	DisplayServer.window_set_size(capture_size)
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	game.fixture_stage = "developed"
	game._apply_requested_fixture()
	game.simulation_host.paused = true
	game._sync_presentation()
	game.ui_layer.visible = false
	var multiplier := _candidate_multiplier(profile)
	if multiplier > 1.0:
		_apply_candidate_multiplier(game, multiplier)
	_stage_reference_workers(game)
	var center := Vector2(game.simulation_host.simulation.town_hall_position) + Vector2(6.5, 6.0)
	game.camera_rig.compose_view(game.world_view.tile_to_world(center), 34.0)
	_add_label(game, _profile_label(profile, multiplier))
	for frame in 24:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var absolute_path := ProjectSettings.globalize_path(output_path)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	if image.save_png(absolute_path) != OK:
		push_error("Phase 2.1 comparison capture failed: %s" % absolute_path)
		quit(1)
		return
	print("PHASE2_1_COMPARISON_PASS profile=%s multiplier=%.2f path=%s size=%dx%d" % [profile, multiplier, absolute_path, image.get_width(), image.get_height()])
	game.queue_free()
	await process_frame
	quit(0)


func _candidate_multiplier(profile_name: String) -> float:
	match profile_name:
		"candidate_a": return 1.35
		"candidate_b": return 1.50
		"candidate_c": return 1.65
	return 1.0


func _profile_label(profile_name: String, multiplier: float) -> String:
	match profile_name:
		"candidate_a": return "SCALE CALIBRATION — CANDIDATE A (1.35× current building models)"
		"candidate_b": return "SCALE CALIBRATION — CANDIDATE B (1.50× current building models)"
		"candidate_c": return "SCALE CALIBRATION — CANDIDATE C (1.65× current building models)"
		"final": return "SCALE CALIBRATION — FINAL SELECTED PROFILE"
	return "SCALE CALIBRATION — CURRENT PHASE 2 PRODUCTION SCALE"


func _apply_candidate_multiplier(game, multiplier: float) -> void:
	for view_value in game.world_view.building_views.values():
		var view: ProductionBuildingView3D = view_value
		if view.model_root != null:
			view.model_root.scale *= multiplier


func _stage_reference_workers(game) -> void:
	var types := [Defs.BUILDING_TOWN_HALL, Defs.BUILDING_HOUSE, Defs.BUILDING_LUMBER_CAMP, Defs.BUILDING_FARM]
	var views: Array = game.world_view.character_views.values()
	var worker_index := 0
	for type_name in types:
		var building_view := _find_building_view(game, type_name)
		if building_view == null or worker_index >= views.size():
			continue
		var worker: ProductionCharacterView3D = views[worker_index]
		var entrance := building_view.socket_world("entrance")
		worker.has_target = false
		worker.global_position = entrance + Vector3(0.72, 0.0, 0.35)
		worker.rotation.y = building_view.rotation.y + PI
		worker_index += 1


func _find_building_view(game, type_name: String) -> ProductionBuildingView3D:
	for view_value in game.world_view.building_views.values():
		var view: ProductionBuildingView3D = view_value
		if view.building_type == type_name and not view.is_construction:
			return view
	return null


func _add_label(game, value: String) -> void:
	var label := Label.new()
	label.position = Vector2(36, 28)
	label.text = value
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("#f2d692"))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	game.ui_layer.add_child(label)
