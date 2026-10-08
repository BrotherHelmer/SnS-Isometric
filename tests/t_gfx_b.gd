extends SceneTree

## GFX-B light gate: shaders load, fog is cool slate, castle/roof remaps,
## grass hue shifted, night lifted. Presentation only.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Identity = preload("res://src/GodotClient3D/Scripts/production_identity.gd")
const BuildingMaterials = preload("res://src/GodotClient3D/Scripts/production_building_materials.gd")
const QualityProfile = preload("res://src/GodotClient3D/Scripts/production_quality_profile.gd")
const FogShader = preload("res://src/GodotClient3D/Shaders/production_fog_of_war.gdshader")
const GroundShader = preload("res://src/GodotClient3D/Shaders/settlement_ground.gdshader")
const WaterShader = preload("res://src/GodotClient3D/Shaders/settlement_water.gdshader")
const FoliageShader = preload("res://src/GodotClient3D/Shaders/settlement_foliage.gdshader")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	_check(FogShader != null, "fog-of-war shader loads")
	_check(GroundShader != null, "ground shader loads")
	_check(WaterShader != null, "water shader loads")
	_check(FoliageShader != null, "foliage shader loads")

	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.start_new_3d(game.DEFAULT_SEED)
	game._hide_start_menu()
	for _i in 4:
		await process_frame

	var fog: Dictionary = game.world_view.fog_configuration()
	var unknown: Vector3 = fog.get("unknown_color", Vector3.ZERO)
	var mist: Vector3 = fog.get("mist_color", Vector3.ZERO)
	print("GFX_B fog unknown=%.3f,%.3f,%.3f mist=%.3f,%.3f,%.3f" % [unknown.x, unknown.y, unknown.z, mist.x, mist.y, mist.z])
	_check(unknown.z >= unknown.y - 0.005, "fog unknown is cool slate, not olive")
	_check(unknown.y >= unknown.x, "fog unknown is not brown")
	_check(mist.z >= mist.y - 0.02, "fog mist stays cool")
	_check(bool(fog.get("exterior_opaque", false)), "unexplored off-map fog stays opaque")
	_check(float(fog.get("unknown_opacity", 0.0)) >= 0.99, "on-map unknown stays covering")

	if game.world_view.terrain_mesh_instance != null and game.world_view.terrain_mesh_instance.material_override is ShaderMaterial:
		var ground := game.world_view.terrain_mesh_instance.material_override as ShaderMaterial
		var sunlit_value = ground.get_shader_parameter("grass_sunlit")
		var moss_value = ground.get_shader_parameter("grass_moss")
		var sunlit := Vector3(Identity.PALETTE_SUNLIT_GRASS.r, Identity.PALETTE_SUNLIT_GRASS.g, Identity.PALETTE_SUNLIT_GRASS.b)
		var moss := Vector3(Identity.PALETTE_MOSS.r, Identity.PALETTE_MOSS.g, Identity.PALETTE_MOSS.b)
		if typeof(sunlit_value) == TYPE_VECTOR3:
			sunlit = sunlit_value
		if typeof(moss_value) == TYPE_VECTOR3:
			moss = moss_value
		print("GFX_B grass sunlit=%.3f,%.3f,%.3f moss=%.3f,%.3f,%.3f" % [sunlit.x, sunlit.y, sunlit.z, moss.x, moss.y, moss.z])
		_check(sunlit.y > sunlit.x + 0.04, "sunlit grass is green, not khaki")
		_check(moss.y > moss.x, "moss is green")
		_check(float(ground.get_shader_parameter("macro_amount")) >= 0.10, "macro breakup is at least 0.10")
	else:
		_check(false, "terrain uses the settlement ground shader")

	if game.world_view.water_material != null:
		var deep_value = game.world_view.water_material.get_shader_parameter("deep_color")
		var deep := Vector3(0.12, 0.28, 0.30)
		if typeof(deep_value) == TYPE_VECTOR3:
			deep = deep_value
		_check(deep.y > deep.x + 0.08, "sea is teal-green, not pewter")
	else:
		_check(false, "island water material is live")

	_check(Identity.PALETTE_SUNLIT_GRASS.g > Identity.PALETTE_SUNLIT_GRASS.r, "identity sunlit grass is green")
	var night_p := Identity.lighting_palette("night")
	_check(float(night_p["sun_energy"]) >= 0.52, "night moon is lifted for readability")
	_check(float(night_p["ambient"]) >= 0.70, "night ambient is lifted")
	_check(float(night_p["fill_energy"]) >= 0.28, "night fill is lifted")
	_check(float(night_p["road_lift"]) <= 0.16, "night roads are not lifted into white")

	var slate := Color("#304d44")
	var castle_roof := BuildingMaterials.remap_albedo("teal_roof", slate, "CASTLE")
	var house_roof := BuildingMaterials.remap_albedo("teal_roof", slate, "HOUSE")
	var stone := Color("#a99d81")
	var castle_stone := BuildingMaterials.remap_albedo("plaster", stone, "CASTLE")
	print("GFX_B castle_roof=%s house_roof=%s castle_stone=%s" % [str(castle_roof), str(house_roof), str(castle_stone)])
	_check(castle_roof.b > castle_roof.r, "castle roofs remap toward blue-grey slate")
	_check(house_roof.r > house_roof.b + 0.05, "house roofs remap toward terracotta")
	_check(castle_stone.r > stone.r, "castle plaster lifts toward pale masonry")
	_check(is_equal_approx(BuildingMaterials.roughness_for("stone"), 0.85), "stone roughness stays 0.85")
	_check(is_equal_approx(BuildingMaterials.roughness_for("plaster"), 0.80), "plaster roughness stays 0.80")

	var rec := QualityProfile.get_profile("recommended")
	_check(bool(rec.get("glow", true)) == false, "recommended keeps glow off")
	_check(bool(rec.get("volumetric_fog", true)) == false, "recommended keeps volumetrics off")
	_check(bool(rec.get("ssil", true)) == false, "recommended keeps SSIL off")

	game.queue_free()
	await process_frame
	print("T_GFX_B %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
