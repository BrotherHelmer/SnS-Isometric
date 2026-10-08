extends SceneTree

## GFX-C light gate: remeshed buildings load at the same unit AABB,
## new tree kit is present, high-quality glow is opt-in only.

const Catalog = preload("res://src/GodotClient3D/Scripts/production_asset_catalog.gd")
const Profile = preload("res://src/GodotClient3D/Scripts/production_scale_profile.gd")
const QualityProfile = preload("res://src/GodotClient3D/Scripts/production_quality_profile.gd")
const BuildingMaterials = preload("res://src/GodotClient3D/Scripts/production_building_materials.gd")
const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	for kind in ["TOWN_HALL", "CASTLE", "HOUSE", "FARM", "STOREHOUSE", "BAKERY", "WATCHTOWER", "BARRACKS", "LUMBER_CAMP"]:
		var packed := load(Catalog.building_path(kind)) as PackedScene
		_check(packed != null, "%s scene loads" % kind)
		if packed == null:
			continue
		var model := packed.instantiate()
		var mesh: Mesh = model.get_node("Model").mesh
		_check(mesh.get_aabb().size.is_equal_approx(Profile.BUILDING_UNIT_SIZE[kind]), "%s footprint AABB unchanged" % kind)
		_check(absf(mesh.get_aabb().position.y) < 0.001, "%s stays grounded" % kind)
		model.free()

	_check(Catalog.TREES.size() >= 4 and Catalog.TREES.size() <= 8, "tree kit stays 4–8 silhouettes")
	for path_value in Catalog.TREES + Catalog.EDGE_TREES:
		_check(ResourceLoader.exists(String(path_value)), "tree exists %s" % String(path_value).get_file())
		_check(not String(path_value).contains("/nature/Tree_"), "KayKit tree cones are out of the live kit")

	var rec := QualityProfile.get_profile("recommended")
	var high := QualityProfile.get_profile("high")
	var low := QualityProfile.get_profile("scalable_low")
	_check(bool(rec.get("glow", true)) == false, "recommended keeps glow off")
	_check(bool(high.get("glow", false)) == true, "high quality enables subtle glow")
	_check(bool(low.get("glow", true)) == false, "low keeps glow off")
	_check(float(high.get("shadow_blur", 1.0)) > 1.0, "high softens shadow blur")

	var house_roof := BuildingMaterials.remap_albedo("teal_roof", Color("#304d44"), "HOUSE")
	var castle_roof := BuildingMaterials.remap_albedo("teal_roof", Color("#304d44"), "CASTLE")
	_check(house_roof.r > house_roof.b + 0.05, "house roofs stay terracotta")
	_check(castle_roof.b > castle_roof.r, "castle roofs stay blue-grey slate")

	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.start_new_3d(game.DEFAULT_SEED)
	game._hide_start_menu()
	for _i in 3:
		await process_frame
	game.apply_quality_profile("high")
	_check(game.environment_resource.glow_enabled, "high profile turns glow on")
	game.apply_quality_profile("recommended")
	_check(not game.environment_resource.glow_enabled, "recommended turns glow back off")
	game.queue_free()
	await process_frame
	print("T_GFX_C %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
