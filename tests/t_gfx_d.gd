extends SceneTree

## GFX-D light gate: closer camera, golden-hour grade, designed ground,
## three building archetypes, showcase village, composition near the hall.

const Catalog = preload("res://src/GodotClient3D/Scripts/production_asset_catalog.gd")
const Profile = preload("res://src/GodotClient3D/Scripts/production_scale_profile.gd")
const QualityProfile = preload("res://src/GodotClient3D/Scripts/production_quality_profile.gd")
const BuildingMaterials = preload("res://src/GodotClient3D/Scripts/production_building_materials.gd")
const Identity = preload("res://src/GodotClient3D/Scripts/production_identity.gd")
const Showcase = preload("res://src/GodotClient3D/Scripts/production_gfx_d_showcase.gd")
const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const CameraRig = preload("res://src/GodotClient3D/Scripts/production_isometric_camera_rig.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	_check(is_equal_approx(CameraRig.NORMAL_ZOOM, 26.0), "default camera is 26 (32% closer than GFX-C 38)")
	_check(CameraRig.NORMAL_ZOOM <= 38.0 * 0.76, "default zoom is at least 25% closer")
	_check(CameraRig.NORMAL_ZOOM >= 38.0 * 0.58, "default zoom is at most 42% closer")

	var day_p := Identity.lighting_palette("day")
	_check(float(day_p["saturation"]) >= 1.04 and float(day_p["saturation"]) <= 1.16, "day saturation is GFX-F 1.04–1.16")
	_check(float(day_p["contrast"]) >= 1.04 and float(day_p["contrast"]) <= 1.12, "day contrast is 1.04–1.12")
	var sun: Color = day_p["sun_color"]
	_check(sun.r > sun.b + 0.12 and sun.g > 0.70, "day key stays warm")
	_check(float(day_p["sun_energy"]) >= 1.10 and float(day_p["sun_energy"]) <= 1.30, "day sun energy is 1.10–1.30")
	_check(float(day_p["sun_pitch"]) <= -30.0 and float(day_p["sun_pitch"]) >= -40.0, "day sun sits 30–40° above the horizon")
	var fill: Color = day_p["fill_color"]
	_check(fill.b > fill.r, "cool fill against the warm key")

	var rec := QualityProfile.get_profile("recommended")
	var high := QualityProfile.get_profile("high")
	_check(bool(rec.get("glow", true)) == false, "recommended keeps glow off")
	_check(int(rec.get("shadow_splits", 2)) == 4, "recommended uses 4 shadow splits")
	_check(bool(high.get("glow", false)) == true, "high quality enables subtle glow")
	_check(int(high.get("shadow_splits", 2)) == 4, "high quality may use 4 shadow splits")
	_check(float(rec.get("grass_density", 0.0)) >= 0.99, "recommended grass density is full")
	_check(float(QualityProfile.get_profile("scalable_low").get("grass_density", 1.0)) <= 0.60, "low grass density is 40–60%")

	for kind in ["TOWN_HALL", "HOUSE", "FARM"]:
		var packed := load(Catalog.building_path(kind)) as PackedScene
		_check(packed != null, "%s scene loads" % kind)
		if packed == null:
			continue
		var model := packed.instantiate()
		var mesh: Mesh = model.get_node("Model").mesh
		_check(mesh.get_aabb().size.is_equal_approx(Profile.BUILDING_UNIT_SIZE[kind]), "%s footprint AABB unchanged" % kind)
		model.free()

	var house_roof := BuildingMaterials.remap_albedo("teal_roof", Color("#304d44"), "HOUSE")
	var hall_roof := BuildingMaterials.remap_albedo("teal_roof", Color("#304d44"), "TOWN_HALL")
	var farm_roof := BuildingMaterials.remap_albedo("roof", Color("#304d44"), "FARM")
	_check(house_roof.r > house_roof.b + 0.08, "house roofs stay terracotta")
	_check(farm_roof.r > farm_roof.b + 0.05, "farm roofs stay terracotta")
	_check(hall_roof.g > hall_roof.r and hall_roof.b > hall_roof.r, "town hall roofs stay teal / slate")
	_check(ResourceLoader.exists(String(Catalog.FLOWERS[0])), "flower scatter mesh exists")

	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.start_new_3d(game.DEFAULT_SEED)
	game._hide_start_menu()
	for _i in 4:
		await process_frame
	_check(game.environment_resource.tonemap_mode == Environment.TONE_MAPPER_FILMIC, "tonemap is Filmic")
	_check(is_equal_approx(game.camera_rig.target_zoom, CameraRig.NORMAL_ZOOM), "new game opens at the closer default zoom")
	_check(game.sun_light.shadow_opacity >= 0.84, "day shadows are strong")
	_check(game.environment_resource.ssao_intensity >= 1.2, "SSAO intensity is at the golden-hour preset")
	if game.world_view.terrain_mesh_instance != null and game.world_view.terrain_mesh_instance.material_override is ShaderMaterial:
		var ground := game.world_view.terrain_mesh_instance.material_override as ShaderMaterial
		_check(float(ground.get_shader_parameter("flower_amount")) >= 0.15, "ground shader has flower tint")
		_check(float(ground.get_shader_parameter("macro_amount")) >= 0.10, "macro breakup stays on")
	else:
		_check(false, "terrain uses the settlement ground shader")

	var sim = game.simulation_host.simulation
	var hall: Vector2i = sim.town_hall_position
	var nearby_trees := 0
	var nearby_rocks := 0
	for oy in range(-10, 11):
		for ox in range(-10, 11):
			var tile := hall + Vector2i(ox, oy)
			if not sim.is_inside_map(tile):
				continue
			var kind := String(sim.get_tile(tile))
			if kind == Defs.TILE_TREE:
				nearby_trees += 1
			elif kind == Defs.TILE_ROCK:
				nearby_rocks += 1
	print("GFX_D founding trees=%d rocks=%d" % [nearby_trees, nearby_rocks])
	_check(nearby_trees >= 8, "founding meadow has a forest edge in camera range")
	_check(nearby_rocks >= 1, "founding meadow has a rock cluster")

	var showcase := Showcase.apply(sim)
	print("GFX_D showcase=%s" % str(showcase))
	_check(bool(showcase.get("ok", false)), "showcase stamps a 15-building village")
	_check(int(showcase.get("buildings", 0)) >= 12, "showcase has at least 12 non-road buildings")
	_check(int(showcase.get("roads", 0)) >= 8, "showcase has a road network")
	game._update_day_night_lighting()
	game._sync_presentation()
	game.apply_quality_profile("high")
	_check(game.environment_resource.glow_enabled, "high profile still opt-in for glow")
	_check(game.sun_light.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS, "high profile uses 4 shadow splits")
	game.apply_quality_profile("recommended")
	_check(not game.environment_resource.glow_enabled, "recommended turns glow back off")
	_check(game.sun_light.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS, "recommended keeps 4 shadow splits")
	game.queue_free()
	await process_frame
	print("T_GFX_D %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
