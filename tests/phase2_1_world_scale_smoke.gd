extends SceneTree

const Catalog = preload("res://src/GodotClient3D/Scripts/production_asset_catalog.gd")
const ScaleProfile = preload("res://src/GodotClient3D/Scripts/production_scale_profile.gd")
const BuildingView = preload("res://src/GodotClient3D/Scripts/production_building_view_3d.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_check(failures, is_equal_approx(ScaleProfile.CHARACTER_MODEL_SCALE, 0.75), "character reference scale remains unchanged")
	_check(failures, is_equal_approx(ScaleProfile.ROAD_WIDTH_SCALE, 0.80), "road presentation width is reduced by 20 percent")
	_check(failures, is_equal_approx(ScaleProfile.TOOL_MODEL_SCALE, 0.82) and is_equal_approx(ScaleProfile.CARGO_MODEL_SCALE, 0.72), "character-attached tools and cargo retain their calibrated scales")
	_check(failures, ScaleProfile.WORLD_PROP_SCALE.size() >= 12 and is_equal_approx(ScaleProfile.world_prop_scale("work_axe"), 0.90), "world and work-yard props use a separate central scale profile")
	_check(failures, ScaleProfile.NATURE_MODEL_SCALE.size() == 3 and _nature_reductions_are_selective(), "only the three largest canopy variants are selectively reduced")

	var house_heights := _character_heights(Defs.BUILDING_HOUSE)
	var lumber_heights := _character_heights(Defs.BUILDING_LUMBER_CAMP)
	var farm_heights := _character_heights(Defs.BUILDING_FARM)
	var storehouse_heights := _character_heights(Defs.BUILDING_STOREHOUSE)
	var town_hall_heights := _character_heights(Defs.BUILDING_TOWN_HALL)
	var watchtower_heights := _character_heights(Defs.BUILDING_WATCHTOWER)
	_check(failures, house_heights >= 2.0 and house_heights <= 2.55, "House roof ridge remains approximately 2-2.5 human heights")
	_check(failures, lumber_heights >= 2.5 and lumber_heights <= 3.0 and farm_heights >= 2.5 and farm_heights <= 3.0, "ordinary production structures read at 2.5-3 human heights")
	_check(failures, storehouse_heights >= 3.0 and storehouse_heights <= 4.0, "Storehouse occupies the storage/industry hierarchy")
	_check(failures, town_hall_heights >= 4.0 and town_hall_heights <= 6.0 and town_hall_heights > house_heights * 1.75, "Town Hall is visibly dominant over a House")
	_check(failures, watchtower_heights >= 4.0 and watchtower_heights > house_heights * 1.70, "Watchtower remains defensive and elevated")

	var house := BuildingView.new()
	root.add_child(house)
	house.configure(_snapshot(901, Defs.BUILDING_HOUSE, false, 1.0))
	_check(failures, _required_sockets_exist(house), "completed wrapper exposes every recalibrated semantic socket")
	_check(failures, _entrance_is_at_visual_front(house), "entrance socket follows the enlarged visible door face")
	_check(failures, _selection_contains_visual(house), "selection bounds and ring contain enlarged model mass")
	_check(failures, _presentation_does_not_mutate_footprint(house), "visual scaling preserves the authoritative logical footprint")
	house.queue_free()
	await process_frame

	var construction := BuildingView.new()
	root.add_child(construction)
	construction.configure(_snapshot(902, Defs.BUILDING_HOUSE, true, 0.10))
	var stage_one_scale := construction.model_root.scale.y
	var stage_one_ok := is_equal_approx(stage_one_scale, ScaleProfile.building_scale(Defs.BUILDING_HOUSE) * 0.46)
	construction.apply_snapshot(_snapshot(902, Defs.BUILDING_HOUSE, true, 0.40))
	var stage_two_scale := construction.model_root.scale.y
	var stage_two_ok := is_equal_approx(stage_two_scale, ScaleProfile.building_scale(Defs.BUILDING_HOUSE) * 0.76)
	construction.apply_snapshot(_snapshot(902, Defs.BUILDING_HOUSE, true, 0.80))
	var near_complete_scale := construction.model_root.scale
	var stage_three_ok := is_equal_approx(near_complete_scale.y, ScaleProfile.building_scale(Defs.BUILDING_HOUSE))
	print("CONSTRUCTION_SCALES stage_one=%.4f stage_two=%.4f stage_three=%.4f full=%.4f" % [stage_one_scale, stage_two_scale, near_complete_scale.y, ScaleProfile.building_scale(Defs.BUILDING_HOUSE)])
	var foundation_ok := _foundation_matches_final_mass(construction)
	construction.apply_snapshot(_snapshot(902, Defs.BUILDING_HOUSE, false, 1.0))
	var completed_scale := construction.model_root.scale
	_check(failures, stage_one_ok and stage_two_ok and stage_three_ok, "construction stages rise through calibrated partial massing")
	_check(failures, foundation_ok, "construction foundation corresponds to the final visual footprint")
	_check(failures, near_complete_scale.is_equal_approx(completed_scale), "near-complete structure does not pop in scale on completion")
	construction.queue_free()
	await process_frame
	_finish(failures)


func _snapshot(id_value: int, type_name: String, constructing: bool, fraction: float) -> Dictionary:
	return {
		"id": id_value,
		"type": type_name,
		"planned_type": type_name,
		"footprint": Defs.building_footprint(type_name),
		"rotation": 0,
		"construction": constructing,
		"construction_fraction": fraction,
		"local_inventory": {},
	}


func _character_heights(type_name: String) -> float:
	return ScaleProfile.building_visual_size(type_name, Defs.building_footprint(type_name)).y / ScaleProfile.CHARACTER_PRESENTATION_HEIGHT_UNITS


func _nature_reductions_are_selective() -> bool:
	for value in ScaleProfile.NATURE_MODEL_SCALE.values():
		var scale_value := float(value)
		if scale_value < 0.80 or scale_value >= 1.0:
			return false
	return true


func _required_sockets_exist(view: ProductionBuildingView3D) -> bool:
	for socket_name in ["entrance", "carrier_pickup", "carrier_dropoff", "worker_station", "construction_delivery", "workyard_left", "workyard_right", "vfx", "camera_focus"]:
		if not view.sockets.has(socket_name):
			return false
	return true


func _entrance_is_at_visual_front(view: ProductionBuildingView3D) -> bool:
	var visual_size := ScaleProfile.building_visual_size(view.building_type, view.footprint)
	var model_front := ScaleProfile.building_front_offset(view.building_type, view.footprint) + visual_size.z * 0.5
	var entrance_z := (view.sockets["entrance"] as Marker3D).position.z
	var footprint_front := ScaleProfile.footprint_world_size(view.footprint).y * 0.5
	return entrance_z >= model_front + 0.25 and entrance_z <= footprint_front + 0.75


func _selection_contains_visual(view: ProductionBuildingView3D) -> bool:
	if view.selection_area == null or view.selection_area.get_child_count() == 0:
		return false
	var collision := view.selection_area.get_child(0) as CollisionShape3D
	if collision == null or not collision.shape is BoxShape3D:
		return false
	var shape := collision.shape as BoxShape3D
	var visual_size := ScaleProfile.building_visual_size(view.building_type, view.footprint)
	return shape.size.x >= visual_size.x and shape.size.z >= visual_size.z and shape.size.y >= visual_size.y


func _presentation_does_not_mutate_footprint(view: ProductionBuildingView3D) -> bool:
	return view.footprint == Defs.building_footprint(view.building_type) and ScaleProfile.footprint_world_size(view.footprint).is_equal_approx(Vector2(view.footprint) * ScaleProfile.LOGICAL_CELL_METRES)


func _foundation_matches_final_mass(view: ProductionBuildingView3D) -> bool:
	var foundation := view.construction_root.get_node_or_null("Foundation") as MeshInstance3D
	if foundation == null or not foundation.mesh is BoxMesh:
		return false
	var size := (foundation.mesh as BoxMesh).size
	var visual_size := ScaleProfile.building_visual_size(view.building_type, view.footprint)
	return size.x >= visual_size.x and size.z >= visual_size.z


func _check(failures: Array[String], condition: bool, label: String) -> void:
	print("%s %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		failures.append(label)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("PHASE2_1_WORLD_SCALE_SMOKE PASS")
		quit(0)
	else:
		print("PHASE2_1_WORLD_SCALE_SMOKE FAIL count=%d" % failures.size())
		quit(1)
