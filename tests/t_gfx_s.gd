extends SceneTree

## GFX-S light gate: articulated gatehouse, clustered ground,
## blended roads, cooler day light, natural forest edges.
## Night and grade knobs stay frozen. Only 1280×720 counts.

const Catalog = preload("res://src/GodotClient3D/Scripts/production_asset_catalog.gd")
const Identity = preload("res://src/GodotClient3D/Scripts/production_identity.gd")
const BuildingMaterials = preload("res://src/GodotClient3D/Scripts/production_building_materials.gd")
const CameraRig = preload("res://src/GodotClient3D/Scripts/production_isometric_camera_rig.gd")
const ScaleProfile = preload("res://src/GodotClient3D/Scripts/production_scale_profile.gd")
const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Showcase = preload("res://src/GodotClient3D/Scripts/production_gfx_d_showcase.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	_check_grade()
	_check_assets()
	_check_zoom()
	await _check_live_scene()
	print("T_GFX_S %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check_grade() -> void:
	var day_p := Identity.lighting_palette("day")
	_check(float(day_p["saturation"]) >= 1.10 and float(day_p["saturation"]) <= 1.16, "day sat stays frozen at 1.12")
	_check(float(day_p["contrast"]) >= 1.10 and float(day_p["contrast"]) <= 1.16, "day contrast stays frozen at 1.12")
	_check(float(day_p["exposure"]) >= 0.82 and float(day_p["exposure"]) <= 0.90, "day exposure stays frozen at 0.86")
	_check(float(day_p["sun_energy"]) >= 1.05 and float(day_p["sun_energy"]) <= 1.12, "day sun is late-afternoon 1.10")
	_check(float(day_p["sun_pitch"]) >= -32.0 and float(day_p["sun_pitch"]) <= -28.0, "day sun pitch is -30")
	_check(day_p["sun_color"].is_equal_approx(Color("#FFD2A0")), "day key stays #FFD2A0")
	_check(day_p["ambient_color"].is_equal_approx(Color("#9A9A88")), "day ambient is cooler #9A9A88")
	_check(day_p["fill_color"].is_equal_approx(Color("#C4B088")), "day fill is #C4B088")
	_check(day_p["sky_horizon"].is_equal_approx(Color("#C4B8A4")), "day horizon is #C4B8A4")
	_check(float(day_p["ambient"]) >= 0.36, "day ambient fill stays soft")
	_check(float(day_p["fill_energy"]) >= 0.10, "day fill lifts near-black shadows")
	var night_p := Identity.lighting_palette("night")
	_check(float(night_p["sun_energy"]) >= 0.38 and float(night_p["sun_energy"]) <= 0.48, "night moon stays 0.42")
	_check(float(night_p["ambient"]) >= 0.26 and float(night_p["ambient"]) <= 0.34, "night ambient stays 0.30")
	_check(float(night_p["exposure"]) >= 0.80 and float(night_p["exposure"]) <= 0.88, "night exposure stays 0.84")
	_check(Identity.PALETTE_LIMESTONE.is_equal_approx(Color("#CDBFA2")), "limestone is #CDBFA2")
	_check(Identity.PALETTE_PLASTER.is_equal_approx(Color("#E0D0B2")), "plaster is #E0D0B2")
	_check(Identity.PALETTE_TIMBER.is_equal_approx(Color("#5F442F")), "timber is #5F442F")
	_check(Identity.PALETTE_TEAL.is_equal_approx(Color("#456B68")), "slate is #456B68")
	_check(Identity.PALETTE_MEADOW.is_equal_approx(Color("#536C3F")), "meadow identity is #536C3F")
	_check(Identity.PALETTE_ROAD_CLAY.is_equal_approx(Color("#9F805B")), "road clay is #9F805B")
	_check(Identity.PALETTE_FOG_UNKNOWN.is_equal_approx(Color("#17272A")), "shroud colour is #17272A")


func _check_assets() -> void:
	_check(Catalog.building_path("TOWN_HALL").contains("civic_keep"), "Town Hall is the authored civic keep")
	_check(Catalog.building_path("CASTLE").contains("civic_castle"), "Castle is the authored civic castle")
	_check(Catalog.building_path("HOUSE").contains("building_home_A_green"), "house keeps the KayKit home mesh")
	_check(Catalog.building_path("LUMBER_CAMP").contains("building_lumbermill_green"), "workshop keeps the KayKit mill mesh")
	_check(FileAccess.file_exists(Catalog.building_path("TOWN_HALL")), "civic_keep.gltf exists")
	_check(FileAccess.file_exists(Catalog.building_path("CASTLE")), "civic_castle.gltf exists")
	_check(FileAccess.file_exists(Catalog.ARCH_TEXTURES["stone"]), "stone 1K map exists")
	_check(FileAccess.file_exists(Catalog.ARCH_TEXTURES["plaster"]), "plaster 1K map exists")
	_check(FileAccess.file_exists(Catalog.ARCH_TEXTURES["timber"]), "timber 1K map exists")
	_check(FileAccess.file_exists(Catalog.ARCH_TEXTURES["slate"]), "slate 1K map exists")
	_check(FileAccess.file_exists("res://src/GodotClient3D/Shaders/settlement_architecture.gdshader"), "architecture shader exists")
	_check(not BuildingMaterials._is_kaykit_hexagon("TOWN_HALL"), "civic hall is not on the KayKit remap")
	_check(BuildingMaterials._is_civic_keep("TOWN_HALL") and BuildingMaterials._is_civic_keep("CASTLE"), "civic keep classifier covers hall and castle")
	_check(is_equal_approx(ScaleProfile.building_scale("TOWN_HALL"), 1.0), "authored keep is world-metre scale 1.0")
	_check(BuildingMaterials.CASTLE_LIMESTONE.is_equal_approx(Color("#CDBFA2")), "castle limestone is #CDBFA2")
	_check(BuildingMaterials.WARM_PLASTER.is_equal_approx(Color("#E0D0B2")), "castle plaster is #E0D0B2")
	_check(BuildingMaterials.CASTLE_MASONRY.is_equal_approx(Color("#82796A")), "castle masonry is #82796A")
	_check(BuildingMaterials.DARK_TIMBER.is_equal_approx(Color("#5F442F")), "timber is #5F442F")
	_check(BuildingMaterials.HALL_SLATE.g > BuildingMaterials.HALL_SLATE.r and BuildingMaterials.HALL_SLATE.r < 0.40, "civic roofs are muted teal, not emerald")
	_check(BuildingMaterials.CLAY_ROOF.r > BuildingMaterials.CLAY_ROOF.g, "house roofs stay terracotta")
	var licenses := FileAccess.get_file_as_string("res://docs/ASSET_LICENSES.md")
	_check(licenses.contains("GFX-S") and licenses.contains("civic_keep"), "licences record the articulated keep")
	_check(licenses.contains("brick_wall_02") and licenses.contains("plastered_stone_wall"), "licences record Poly Haven architecture maps")
	_check(licenses.contains("wood_planks") and licenses.contains("roof_07"), "licences record timber and slate maps")
	_check(licenses.contains("distance-field") or licenses.contains("GFX-O"), "licences still record the distance mask")
	_check(licenses.contains("Kaykit remap"), "licences still record the remap shader")


func _check_zoom() -> void:
	_check(is_equal_approx(CameraRig.NORMAL_ZOOM, 26.0), "gameplay zoom stays 26")
	_check(CameraRig.STRATEGIC_ZOOM <= 39.5 and CameraRig.STRATEGIC_ZOOM >= 38.0, "zoom-out cap is ~1.5x")


func _check_live_scene() -> void:
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	_check(game.world_view != null, "world view compiled")
	if game.world_view == null:
		game.queue_free()
		await process_frame
		return
	game.start_new_3d(game.DEFAULT_SEED)
	game._hide_start_menu()
	for _i in 4:
		await process_frame
	var master_idx := AudioServer.get_bus_index("Master")
	var master_lin := db_to_linear(AudioServer.get_bus_volume_db(master_idx))
	print("GFX_S master_linear=%.3f" % master_lin)
	_check(master_lin >= 0.995 and master_lin <= 1.005, "Master volume is 1.0")
	_check(game.world_view.has_method("_visual_relief_y"), "terrain relief helper exists")
	var hall_flat := ScaleProfile.tile_to_flat_world(Vector2(game.simulation_host.simulation.town_hall_position + Vector2i(2, 2)), game.world_view.map_size)
	var village_relief: float = game.world_view._visual_relief_y(Vector2(hall_flat.x, hall_flat.z))
	var back_relief: float = game.world_view._visual_relief_y(Vector2(hall_flat.x + 10.0, hall_flat.z - 20.0))
	var front_relief: float = game.world_view._visual_relief_y(Vector2(hall_flat.x, hall_flat.z + 16.0))
	print("GFX_S relief village=%.3f back=%.3f front=%.3f" % [village_relief, back_relief, front_relief])
	_check(absf(village_relief) <= 0.08, "village tiles stay nearly flat")
	_check(back_relief >= 0.70 and back_relief <= 2.10, "back ridge relief is 0.08–0.18B")
	_check(front_relief <= 0.35, "no camera-side cliff")
	if game.world_view.terrain_mesh_instance != null and game.world_view.terrain_mesh_instance.material_override is ShaderMaterial:
		var ground := game.world_view.terrain_mesh_instance.material_override as ShaderMaterial
		var lush: Vector3 = ground.get_shader_parameter("meadow_lush")
		_check(absf(lush.x - 0.325) < 0.02 and lush.y > lush.x, "meadow albedo is #536C3F")
		var shade: Vector3 = ground.get_shader_parameter("meadow_shade")
		_check(absf(shade.x - 0.251) < 0.02 and shade.y > shade.x, "meadow shade is #405A36")
		var road_e: Vector3 = ground.get_shader_parameter("road_earth")
		_check(absf(road_e.x - 0.624) < 0.03 and road_e.x > road_e.y, "road earth is #9F805B")
		var sunlit: Vector3 = ground.get_shader_parameter("grass_sunlit")
		_check(sunlit.y > sunlit.x and sunlit.z > 0.32, "sunlit grass is cooler than yellow-olive")
		_check(float(ground.get_shader_parameter("tex_mix")) >= 0.12 and float(ground.get_shader_parameter("tex_mix")) <= 0.18, "tex_mix stays 0.12–0.18")
		_check(game.world_view.road_control_texture != null, "512 road-control texture is bound")
	else:
		_check(false, "terrain uses the settlement ground shader")
	var ground_src := FileAccess.get_file_as_string("res://src/GodotClient3D/Shaders/settlement_ground.gdshader")
	_check(not ground_src.contains("return;"), "fragment has no early return (Godot rejects it)")
	_check(ground_src.contains("COLOR.r > COLOR.g") and ground_src.contains("terrain_debug"), "occupy no longer treats dropped-alpha grass as dirt")
	_check(ground_src.contains("dirt_tex") and ground_src.contains("rock_tex") and ground_src.contains("texture(dirt_tex"), "meadow samples dirt and rock maps")
	_check(ground_src.contains("dry_grass") or ground_src.contains("soil_n"), "meadow blends dry grass and soil")
	_check(ground_src.contains("rut_a") and ground_src.contains("sin(world_pos"), "road ruts are world-space, not a repeating lattice")
	_check(ground_src.contains("edge_noise"), "roads wear the distance-field edge")
	_check(ground_src.contains("road_w * mix(0.62, 1.0, center_w)"), "grass eats the road shoulder")
	var arch_src := FileAccess.get_file_as_string("res://src/GodotClient3D/Shaders/settlement_architecture.gdshader")
	_check(not arch_src.contains("return;"), "architecture fragment has no early return")
	_check(arch_src.contains("tex_mix") and arch_src.contains("CDBFA2"), "architecture shader tints limestone under the map")
	_check(arch_src.contains("value_boost"), "architecture shader can lift masonry without flattening the map")
	var dress: Node = game.world_view.resource_visuals_root.get_node_or_null("OpeningDress")
	_check(dress != null, "opening dress exists")
	if dress != null:
		var clearing := float(dress.get_meta("opening_clearing_cells", 0.0))
		_check(clearing >= 10.5 and clearing <= 12.5, "opening clearing stays 2.5–3 Town Hall widths")
		var coverage := float(dress.get_meta("opening_forest_coverage", 0.0))
		_check(coverage >= 0.38 and coverage <= 0.58, "forest covers 40–55% of the perimeter")
		_check(dress.find_child("DressRidge", true, false) != null, "opening has a ridge")
		_check(dress.find_child("DressCreek", true, false) != null, "opening has a creek")
		_check(dress.find_child("RidgeFormation", true, false) != null, "opening has one back rock formation")
		_check(dress.find_child("RidgeSlope_0", true, false) != null, "ridge has grassy slope masses")
		_check(dress.find_child("RidgeLedge_0", true, false) != null, "ridge has layered ledges")
		var formation: MeshInstance3D = dress.find_child("RidgeFormation", true, false) as MeshInstance3D
		if formation != null and formation.material_override is StandardMaterial3D:
			var ridge_col := (formation.material_override as StandardMaterial3D).albedo_color
			_check(ridge_col.g > ridge_col.r, "ridge formation is grassy, not tan sand")
		_check(dress.find_child("DressCoastEdge", true, false) != null, "opening has a west water edge")
		_check(dress.find_child("DressCartWest", true, false) != null, "opening gained a second cart")
		_check(dress.find_child("DressLongCrate", true, false) != null, "opening gained extra crates")
	var creek: Node = dress.find_child("DressCreek", true, false) if dress != null else null
	if creek is MeshInstance3D:
		var water_mat := (creek as MeshInstance3D).material_override as StandardMaterial3D
		_check(water_mat != null and water_mat.albedo_color.is_equal_approx(Color("#2F7A7E")), "creek water is readable blue-green")
		_check(water_mat != null and water_mat.roughness <= 0.28, "creek is specular enough to read as water")
		_check(water_mat != null and not water_mat.emission_enabled, "creek has no turquoise emission wedge")
		_check(dress.find_child("DressCreekShore", true, false) != null, "creek has a wet shoreline")
		_check(dress.find_child("CreekStone_0", true, false) != null, "creek has shoreline stones")
		_check(dress.find_child("CreekReed_0", true, false) != null, "creek has reeds")
	var hall_view = null
	for view in game.world_view.building_views.values():
		if String(view.building_type) == "TOWN_HALL" or String(view.building_type) == "CASTLE":
			hall_view = view
			break
	_check(hall_view != null, "Town Hall view exists")
	if hall_view != null:
		_check(hall_view.find_child("CivicWall_Keep", true, false) != null, "keep has named CivicWall geometry")
		_check(hall_view.find_child("CivicRoof_Hall", true, false) != null, "keep has named CivicRoof geometry")
		_check(hall_view.find_child("CivicDoor", true, false) != null, "keep has a timber door")
		_check(hall_view.find_child("CivicCrenel_Front_0", true, false) != null, "keep has crenellations")
		_check(hall_view.find_child("CivicGate", true, false) != null, "keep has a named gate")
		_check(hall_view.find_child("CivicGate_Arch", true, false) != null, "keep has a gate arch")
		_check(hall_view.find_child("CivicRecess_Gate", true, false) != null, "gatehouse has a recessed portal")
		_check(hall_view.find_child("CivicButtress_L", true, false) != null, "gatehouse has a left buttress")
		_check(hall_view.find_child("CivicButtress_R", true, false) != null, "gatehouse has a right buttress")
		_check(hall_view.find_child("CivicString_Course", true, false) != null, "facade has a string course")
		_check(hall_view.find_child("CivicHerald", true, false) != null, "gatehouse flies a herald")
		_check(hall_view.find_child("CivicWall_KeepRaised", true, false) != null, "central keep is raised above the hall")
		_check(hall_view.find_child("CivicRoof_Keep", true, false) != null, "keep roof is a second mass")
		_check(hall_view.find_child("CivicRoof_Wing", true, false) != null, "wing roof is a third mass")
		_check(hall_view.find_child("CivicWall_TowerTall", true, false) != null, "asymmetric tall tower exists")
		_check(hall_view.find_child("CivicBanner", true, false) != null, "keep flies a banner")
		_check(hall_view.find_child("TrimPlinth", true, false) != null, "principal trim names stay")
		var roof: MeshInstance3D = hall_view.find_child("CivicRoof_Hall", true, false) as MeshInstance3D
		_check(roof != null and roof.mesh != null, "slate roof is authored geometry, not an atlas classify")
		var tall: MeshInstance3D = hall_view.find_child("CivicWall_TowerTall", true, false) as MeshInstance3D
		if tall != null:
			var tall_top: float = tall.position.y
			if tall.mesh != null:
				tall_top += tall.mesh.get_aabb().size.y * 0.5
			print("GFX_S tall_tower_top=%.2f" % tall_top)
			_check(tall_top >= 8.5, "tall tower rises above the hall roofline")
	var world_src := FileAccess.get_file_as_string("res://src/GodotClient3D/Scripts/production_world_view_3d.gd")
	_check(world_src.contains("_stamp_segment_distance") and world_src.contains("_collect_road_segments"), "roads keep the world-space distance field")
	_check(world_src.contains("road_width_metres() * 0.72"), "visual road width is 0.72 of authored")
	_check(world_src.contains("(-5, -2)") or world_src.contains("Vector2i(-5, -2)"), "creek starts west of the hamlet")
	_check(world_src.contains("(-3, 6)") or world_src.contains("Vector2i(-3, 6)"), "creek swings into the visible meadow")
	_check(world_src.contains("_stamp_building_aprons"), "building aprons are stamped as worn earth")
	_check(world_src.contains("_tuft_transform") and world_src.contains("zone == \"settlement\""), "vegetation uses three MultiMesh zones")
	_check(world_src.contains("in_clump") and world_src.contains("3.0"), "ground patches plant in 3x3 clumps")
	_check(world_src.contains("planted_tiles") and world_src.contains("understory and saplings"), "opening forest adds understory without changing coverage")
	_check(game.world_view.ground_patch_root != null and game.world_view.ground_patch_root.get_child_count() >= 3, "ground patches instanced several MultiMeshes")
	var showcase := Showcase.apply(game.simulation_host.simulation)
	_check(bool(showcase.get("ok", false)), "showcase still stamps")
	_check(int(showcase.get("roads", 0)) >= 12, "showcase stamps a connected road network")
	_check(int(showcase.get("population", 0)) >= 12, "showcase population is a working hamlet, not 2/5")
	_check(int(showcase.get("housing", 0)) >= 15, "showcase housing follows the stamped houses")
	_check(int(showcase.get("workers", 0)) >= 8, "showcase has visible settlers")
	_check(int(showcase.get("buildings", 0)) < 40, "showcase building count excludes the road lattice")
	game._sync_presentation()
	if game.has_method("_update_ui"):
		game._update_ui()
	var pop_chip := String(game.population_label.text) if game.population_label != null else ""
	print("GFX_S pop_chip=%s buildings=%s workers=%s" % [pop_chip, str(showcase.get("buildings", 0)), str(showcase.get("workers", 0))])
	_check(not pop_chip.begins_with("2/"), "HUD population is not stuck at 2/5")
	var smoke_on := 0
	for view in game.world_view.building_views.values():
		var chimney: Node = view.find_child("ChimneySmoke", true, false)
		if chimney is CPUParticles3D and (chimney as CPUParticles3D).emitting:
			smoke_on += 1
		if view.find_child("ContactAO", true, false) != null:
			pass
	_check(smoke_on >= 2, "chimney smoke is emitting on inhabited buildings")
	await _check_castle_on_camera(game)
	game.queue_free()
	await process_frame


func _check_castle_on_camera(game: Node) -> void:
	var sim = game.simulation_host.simulation
	sim.is_night = false
	sim.phase_time = 80.0
	game._update_day_night_lighting()
	game._sync_presentation()
	var home: Vector3 = game.world_view.tile_to_world(Vector2(sim.town_hall_position) + Vector2(1.5, 1.5))
	game.camera_rig.compose_view(home, 34.0)
	for _i in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_viewport().get_texture().get_image()
	_check(image != null and not image.is_empty(), "gameplay-camera castle frame exists")
	if image == null or image.is_empty():
		return
	DirAccess.make_dir_recursive_absolute("res://artifacts/gfx_s/after")
	image.save_png("res://artifacts/gfx_s/after/pkg3_castle_gate.png")
	var ratio := _light_wall_ratio(image)
	print("GFX_S castle_light_wall_ratio=%.3f" % ratio)
	_check(ratio >= 0.50, "castle light wall area is at least 50%% on the gameplay camera (%.0f%%)" % (ratio * 100.0))


func _light_wall_ratio(image: Image) -> float:
	# Authored keep puts slate cones in this band. Lit teal must not
	# count as a dark wall — that was the 47% false fail.
	var w := image.get_width()
	var h := image.get_height()
	var x0 := int(float(w) * 0.34)
	var x1 := int(float(w) * 0.66)
	var y0 := int(float(h) * 0.18)
	var y1 := int(float(h) * 0.58)
	var wall := 0
	var light := 0
	var y := y0
	while y < y1:
		var x := x0
		while x < x1:
			var c := image.get_pixel(x, y)
			var luma := c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
			var green := c.g > c.r + 0.04 and c.g > c.b
			var teal_roof := c.b > c.r + 0.02 and c.g > c.r
			var olive_roof := c.g >= c.r - 0.03 and c.g > c.b * 0.82 and luma < 0.52
			var meadow := c.b < 0.24 and c.r < 0.62 and luma < 0.50
			var sky := luma > 0.82 and c.b > c.r
			if not green and not teal_roof and not olive_roof and not meadow and not sky and luma > 0.16:
				wall += 1
				if luma >= 0.46 and c.r >= 0.42 and c.g / maxf(c.r, 0.001) < 1.12:
					light += 1
			x += 2
		y += 2
	if wall < 40:
		return 0.0
	return float(light) / float(wall)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
