extends SceneTree

const Catalog = preload("res://src/GodotClient3D/Scripts/production_asset_catalog.gd")
const ScaleProfile = preload("res://src/GodotClient3D/Scripts/production_scale_profile.gd")

const BUILDING_TYPES := [
	"TOWN_HALL", "HOUSE", "LUMBER_CAMP", "SAWMILL", "QUARRY", "FARM",
	"BAKERY", "STOREHOUSE", "WATCHTOWER", "BARRACKS",
]

var output_path := "res://artifacts/phase2_1/measurements/final_bounds.json"


func _init() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")
	call_deferred("_run")


func _run() -> void:
	var character_bounds := _measure_scene(Catalog.character_path("settler"), ScaleProfile.CHARACTER_MODEL_SCALE)
	var measured_character_height := float(character_bounds.get("height", 0.0))
	var normalization := 1.80 / maxf(measured_character_height, 0.001)
	var buildings := {}
	for building_type in BUILDING_TYPES:
		var scale_value := ScaleProfile.building_scale(building_type)
		var bounds := _measure_scene(Catalog.building_path(building_type), scale_value)
		bounds["catalog_scale"] = scale_value
		bounds["normalized_visual_height_m"] = snappedf(float(bounds.get("height", 0.0)) * normalization, 0.001)
		bounds["character_heights"] = snappedf(float(bounds.get("height", 0.0)) / maxf(measured_character_height, 0.001), 0.001)
		buildings[building_type] = bounds
	var trees := {}
	for tree_path in Catalog.TREES:
		var tree_bounds := _measure_scene(tree_path, 1.0)
		trees[String(tree_path).get_file().get_basename()] = tree_bounds
	var result := {
		"method": "Recursive imported-mesh AABB; current Rig_Medium presentation height normalized to the Phase 2.1 canonical 1.80 m visual humanoid.",
		"character": character_bounds,
		"character_catalog_scale": ScaleProfile.CHARACTER_MODEL_SCALE,
		"character_normalized_height_m": 1.80,
		"buildings": buildings,
		"tree_models_at_unit_scale": trees,
	}
	var output := ProjectSettings.globalize_path(output_path)
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Unable to write Phase 2.1 measurements")
		quit(1)
		return
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("PHASE2_1_MEASURE_PASS character_raw_height=%.3f normalization=%.3f output=%s" % [measured_character_height, normalization, output])
	for building_type in BUILDING_TYPES:
		var bounds: Dictionary = buildings[building_type]
		print("MEASURE %s scale=%.3f size=(%.3f,%.3f,%.3f) character_heights=%.3f normalized_m=%.3f" % [
			building_type,
			float(bounds.get("catalog_scale", 0.0)),
			float(bounds.get("width", 0.0)), float(bounds.get("height", 0.0)), float(bounds.get("depth", 0.0)),
			float(bounds.get("character_heights", 0.0)), float(bounds.get("normalized_visual_height_m", 0.0)),
		])
	for tree_name in trees:
		var tree_bounds: Dictionary = trees[tree_name]
		print("TREE %s size=(%.3f,%.3f,%.3f)" % [tree_name, float(tree_bounds.get("width", 0.0)), float(tree_bounds.get("height", 0.0)), float(tree_bounds.get("depth", 0.0))])
	quit(0)


func _measure_scene(path: String, scale_value: float) -> Dictionary:
	var packed := load(path) as PackedScene
	if packed == null:
		return {}
	var instance := packed.instantiate() as Node3D
	instance.scale = Vector3.ONE * scale_value
	var bounds := _collect_bounds(instance, Transform3D.IDENTITY, false, AABB())
	instance.free()
	var aabb: AABB = bounds.get("aabb", AABB())
	return {
		"minimum": aabb.position,
		"maximum": aabb.end,
		"width": snappedf(aabb.size.x, 0.001),
		"height": snappedf(aabb.size.y, 0.001),
		"depth": snappedf(aabb.size.z, 0.001),
	}


func _collect_bounds(node: Node, parent_transform: Transform3D, has_bounds: bool, current: AABB) -> Dictionary:
	var transform := parent_transform
	if node is Node3D:
		transform = parent_transform * (node as Node3D).transform
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var transformed: AABB = transform * (node as MeshInstance3D).get_aabb()
		current = current.merge(transformed) if has_bounds else transformed
		has_bounds = true
	for child in node.get_children():
		var result := _collect_bounds(child, transform, has_bounds, current)
		has_bounds = bool(result.get("has_bounds", has_bounds))
		current = result.get("aabb", current)
	return {"has_bounds": has_bounds, "aabb": current}
