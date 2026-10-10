extends SceneTree

## GFX-T light gate: lush terrain, supporting-building charm,
## scenic creek, layered forest edge, lived-in hamlet, warmer day
## light. Night and grade knobs stay frozen. Only 1280×720 counts.

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
	print("T_GFX_T %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check_grade() -> void:
	var day_p := Identity.lighting_palette("day")
	_check(float(day_p["saturation"]) >= 1.10 and float(day_p["saturation"]) <= 1.16, "day sat stays frozen at 1.12")
	_check(float(day_p["contrast"]) >= 1.10 and float(day_p["contrast"]) <= 1.16, "day contrast stays frozen at 1.12")
	_check(float(day_p["exposure"]) >= 0.82 and float(day_p["exposure"]) <= 0.90, "day exposure stays frozen at 0.86")
	_check(float(day_p["sun_energy"]) >= 1.05 and float(day_p["sun_energy"]) <= 1.12, "day sun is late-afternoon 1.10")
	_check(float(day_p["sun_pitch"]) >= -32.0 and float(day_p["sun_pitch"]) <= -28.0, "day sun pitch is -30")
	_check(day_p["sun_color"].is_equal_approx(Color("#FFD2A0")), "day key stays #FFD2A0")
	_check(day_p["ambient_color"].is_equal_approx(Color("#A8A088")), "day ambient is warmer #A8A088")
	_check(day_p["fill_color"].is_equal_approx(Color("#C8B488")), "day fill is #C8B488")
	_check(day_p["sky_horizon"].is_equal_approx(Color("#C8B8A0")), "day horizon is #C8B8A0")
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
	_check(not BuildingMaterials._is_kaykit_hexagon("TOWN_HALL"), "civic hall is not on the KayKit remap")
	_check(BuildingMaterials._is_civic_keep("TOWN_HALL") and BuildingMaterials._is_civic_keep("CASTLE"), "civic keep classifier covers hall and castle")
	_check(is_equal_approx(ScaleProfile.building_scale("TOWN_HALL"), 1.0), "authored keep is world-metre scale 1.0")
	_check(BuildingMaterials.CLAY_ROOF.r > BuildingMaterials.CLAY_ROOF.g, "house roofs stay terracotta")
	var licenses := FileAccess.get_file_as_string("res://docs/ASSET_LICENSES.md")
	_check(licenses.contains("GFX-T") and licenses.contains("GFX-S"), "licences record T on top of S")
	_check(licenses.contains("civic_keep"), "licences still record the articulated keep")
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
	game.simulation_host.paused = true
	for _i in 4:
		await process_frame
	var master_idx := AudioServer.get_bus_index("Master")
	var master_lin := db_to_linear(AudioServer.get_bus_volume_db(master_idx))
	print("GFX_T master_linear=%.3f" % master_lin)
	_check(master_lin >= 0.995 and master_lin <= 1.005, "Master volume is 1.0")
	if game.world_view.terrain_mesh_instance != null and game.world_view.terrain_mesh_instance.material_override is ShaderMaterial:
		var ground := game.world_view.terrain_mesh_instance.material_override as ShaderMaterial
		var lush: Vector3 = ground.get_shader_parameter("meadow_lush")
		_check(absf(lush.x - 0.325) < 0.02 and lush.y > lush.x, "meadow albedo is #536C3F")
		var sunlit: Vector3 = ground.get_shader_parameter("grass_sunlit")
		_check(sunlit.y > sunlit.x and sunlit.z > 0.32, "sunlit grass stays cooler than yellow-olive")
		_check(float(ground.get_shader_parameter("tex_mix")) >= 0.12 and float(ground.get_shader_parameter("tex_mix")) <= 0.18, "tex_mix stays 0.12–0.18")
	else:
		_check(false, "terrain uses the settlement ground shader")
	var ground_src := FileAccess.get_file_as_string("res://src/GodotClient3D/Shaders/settlement_ground.gdshader")
	_check(not ground_src.contains("return;"), "fragment has no early return (Godot rejects it)")
	_check(ground_src.contains("weed_n") and ground_src.contains("lush_n"), "meadow adds weed and lush reward patches")
	_check(ground_src.contains("edge_noise"), "roads wear the distance-field edge")
	_check(ground_src.contains("road_w * mix(0.62, 1.0, center_w)"), "grass eats the road shoulder")
	var dress: Node = game.world_view.resource_visuals_root.get_node_or_null("OpeningDress")
	_check(dress != null, "opening dress exists")
	if dress != null:
		var clearing := float(dress.get_meta("opening_clearing_cells", 0.0))
		_check(clearing >= 10.5 and clearing <= 12.5, "opening clearing stays 2.5–3 Town Hall widths")
		var coverage := float(dress.get_meta("opening_forest_coverage", 0.0))
		_check(coverage >= 0.38 and coverage <= 0.58, "forest covers 40–55% of the perimeter")
		_check(dress.find_child("DressCreek", true, false) != null, "opening has a creek")
		_check(dress.find_child("DressCreekDeep", true, false) != null, "creek has a deeper run")
		_check(dress.find_child("CreekBridge", true, false) != null, "creek has a timber footbridge")
		_check(dress.find_child("DressGardenA", true, false) != null, "hamlet has a garden")
		_check(dress.find_child("DressWash", true, false) != null, "hamlet has a wash line")
		_check(dress.find_child("DressFarmFork", true, false) != null, "hamlet shows farm activity")
		_check(dress.find_child("DressTrimPorch", true, false) != null, "cottages gained a porch")
		_check(dress.find_child("DressTrimDoor", true, false) != null, "cottages gained a readable door")
	var creek: Node = dress.find_child("DressCreek", true, false) if dress != null else null
	if creek is MeshInstance3D:
		var water_mat := (creek as MeshInstance3D).material_override as StandardMaterial3D
		_check(water_mat != null and water_mat.albedo_color.is_equal_approx(Color("#2F7A7E")), "creek water is readable blue-green")
		_check(water_mat != null and water_mat.roughness <= 0.28, "creek is specular enough to read as water")
		_check(dress.find_child("CreekStone_0", true, false) != null, "creek has shoreline stones")
		_check(dress.find_child("CreekReed_0", true, false) != null, "creek has reeds")
	var hall_view = null
	for view in game.world_view.building_views.values():
		if String(view.building_type) == "TOWN_HALL" or String(view.building_type) == "CASTLE":
			hall_view = view
			break
	_check(hall_view != null, "Town Hall view exists")
	if hall_view != null:
		_check(hall_view.find_child("CivicGate_Arch", true, false) != null, "keep has a gate arch")
		_check(hall_view.find_child("CivicButtress_L", true, false) != null, "gatehouse has a left buttress")
		_check(hall_view.find_child("CivicHerald", true, false) != null, "gatehouse flies a herald")
		_check(hall_view.find_child("TrimPlinth", true, false) != null, "principal trim names stay")
	var world_src := FileAccess.get_file_as_string("res://src/GodotClient3D/Scripts/production_world_view_3d.gd")
	_check(world_src.contains("road_width_metres() * 0.72"), "visual road width is 0.72 of authored")
	_check(world_src.contains("_stamp_building_aprons"), "building aprons are stamped as worn earth")
	_check(world_src.contains("_tuft_transform") and world_src.contains("zone == \"settlement\""), "vegetation uses three MultiMesh zones")
	_check(world_src.contains("in_clump") and world_src.contains("3.0"), "ground patches plant in 3x3 clumps")
	_check(world_src.contains("\"weeds\""), "ground patches plant weed clusters")
	_check(world_src.contains("planted_tiles") and world_src.contains("understory and saplings"), "opening forest adds understory without changing coverage")
	_check(world_src.contains("_spawn_wash_line") and world_src.contains("CreekBridge"), "T adds wash-line and creek-bridge dressing")
	_check(game.world_view.ground_patch_root != null and game.world_view.ground_patch_root.get_child_count() >= 3, "ground patches instanced several MultiMeshes")
	var showcase := Showcase.apply(game.simulation_host.simulation)
	_check(bool(showcase.get("ok", false)), "showcase still stamps")
	_check(int(showcase.get("roads", 0)) >= 12, "showcase stamps a connected road network")
	_check(int(showcase.get("population", 0)) >= 12, "showcase population is a working hamlet, not 2/5")
	_check(int(showcase.get("housing", 0)) >= 15, "showcase housing follows the stamped houses")
	_check(int(showcase.get("workers", 0)) >= 8, "showcase has visible settlers")
	_check(int(showcase.get("buildings", 0)) < 40, "showcase building count excludes the road lattice")
	game._sync_presentation()
	var house_view = null
	for view in game.world_view.building_views.values():
		if String(view.building_type) == "HOUSE":
			house_view = view
			break
	if house_view != null:
		_check(house_view.find_child("TrimPorch", true, false) != null, "live houses gained a porch")
		_check(house_view.find_child("HouseGarden", true, false) != null, "live houses gained a garden")
	var smoke_on := 0
	for view in game.world_view.building_views.values():
		var chimney: Node = view.find_child("ChimneySmoke", true, false)
		if chimney is CPUParticles3D and (chimney as CPUParticles3D).emitting:
			smoke_on += 1
	_check(smoke_on >= 2, "chimney smoke is emitting on inhabited buildings")
	game.queue_free()
	await process_frame


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
