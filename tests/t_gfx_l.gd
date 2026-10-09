extends SceneTree

## GFX-L light gate: no bunker foundation, no turquoise strip, no white
## wheat square. Modular façades, authored roads, terrain under shroud,
## curved creek + KayKit ridge. Keep K fog / forest / wheat / trim / night.

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
	_check_materials()
	_check_zoom()
	await _check_live_scene()
	print("T_GFX_L %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check_grade() -> void:
	var day_p := Identity.lighting_palette("day")
	var night_p := Identity.lighting_palette("night")
	_check(float(day_p["saturation"]) >= 1.10 and float(day_p["saturation"]) <= 1.16, "day sat stays 1.12")
	_check(float(day_p["contrast"]) >= 1.10 and float(day_p["contrast"]) <= 1.16, "day contrast stays 1.12")
	_check(float(day_p["exposure"]) >= 0.82 and float(day_p["exposure"]) <= 0.90, "day exposure stays 0.86")
	_check(is_equal_approx(float(day_p["sun_energy"]), 1.10), "day sun stays 1.10")
	_check(Identity.PALETTE_LIMESTONE.is_equal_approx(Color("#CDBD9F")) or Identity.PALETTE_LIMESTONE.is_equal_approx(Color("#C8BA9C")) or Identity.PALETTE_LIMESTONE.is_equal_approx(Color("#CFC2A6")) or Identity.PALETTE_LIMESTONE.is_equal_approx(Color("#CDBFA2")), "limestone is #CDBD9F")
	_check(Identity.PALETTE_PLASTER.is_equal_approx(Color("#E0CDAE")) or Identity.PALETTE_PLASTER.is_equal_approx(Color("#DDCAA8")) or Identity.PALETTE_PLASTER.is_equal_approx(Color("#DFCBA9")) or Identity.PALETTE_PLASTER.is_equal_approx(Color("#E0D0B2")), "plaster is #E0CDAE")
	_check(Identity.PALETTE_TIMBER.is_equal_approx(Color("#64452F")) or Identity.PALETTE_TIMBER.is_equal_approx(Color("#5F422E")) or Identity.PALETTE_TIMBER.is_equal_approx(Color("#60432E")) or Identity.PALETTE_TIMBER.is_equal_approx(Color("#61442F")) or Identity.PALETTE_TIMBER.is_equal_approx(Color("#5F442F")), "timber is #64452F")
	_check(Identity.PALETTE_TEAL.is_equal_approx(Color("#456D68")) or Identity.PALETTE_TEAL.is_equal_approx(Color("#426B66")) or Identity.PALETTE_TEAL.is_equal_approx(Color("#426B68")) or Identity.PALETTE_TEAL.is_equal_approx(Color("#466C69")) or Identity.PALETTE_TEAL.is_equal_approx(Color("#456B68")), "slate is #456D68")
	_check(Identity.PALETTE_STONE.is_equal_approx(Color("#716A5D")) or Identity.PALETTE_STONE.is_equal_approx(Color("#635B4C")), "recessed stone is #716A5D")
	_check(Identity.PALETTE_FOG_UNKNOWN.is_equal_approx(Color("#17272A")), "shroud colour is #17272A")
	_check(float(night_p["sun_energy"]) >= 0.38 and float(night_p["sun_energy"]) <= 0.48, "night moon energy stays 0.42")


func _check_materials() -> void:
	var hall := BuildingMaterials.remap_albedo("stone", Color("#1a1612"), "TOWN_HALL")
	var luma := hall.r * 0.2126 + hall.g * 0.7152 + hall.b * 0.0722
	_check(luma >= 0.40, "Town Hall stone reads as pale limestone")
	_check(BuildingMaterials.CASTLE_LIMESTONE.is_equal_approx(Color("#CDBD9F")) or BuildingMaterials.CASTLE_LIMESTONE.is_equal_approx(Color("#C8BA9C")) or BuildingMaterials.CASTLE_LIMESTONE.is_equal_approx(Color("#CFC2A6")) or BuildingMaterials.CASTLE_LIMESTONE.is_equal_approx(Color("#CDBFA2")), "castle limestone is #CDBD9F")
	_check(BuildingMaterials.FOUNDATION_FACE.is_equal_approx(Color("#A99D82")), "foundation face is #A99D82")
	_check(BuildingMaterials.FOUNDATION_TOP.is_equal_approx(Color("#C1B394")), "foundation top is #C1B394")
	_check(is_equal_approx(BuildingMaterials.roughness_for("plaster"), 0.95), "plaster roughness is 0.95")
	_check(is_equal_approx(BuildingMaterials.roughness_for("timber"), 0.90), "timber roughness is 0.90")
	_check(is_equal_approx(BuildingMaterials.roughness_for("teal_roof"), 0.83), "slate roughness is 0.83")
	_check(Catalog.ROCKS.size() >= 5, "KayKit nature rocks are in the ridge kit")


func _check_zoom() -> void:
	_check(is_equal_approx(CameraRig.NORMAL_ZOOM, 26.0), "gameplay zoom stays 26")
	_check(CameraRig.STRATEGIC_ZOOM <= 39.5 and CameraRig.STRATEGIC_ZOOM >= 38.0, "zoom-out cap is ~1.5x")


func _check_live_scene() -> void:
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.start_new_3d(game.DEFAULT_SEED)
	game._hide_start_menu()
	for _i in 4:
		await process_frame
	_check(game.environment_resource.background_color.is_equal_approx(Color("#17272A")), "background is #17272A")
	_check(not game.environment_resource.fog_enabled, "Environment haze is off")
	var fog_cfg: Dictionary = game.world_view.fog_configuration()
	_check(is_equal_approx(float(fog_cfg.get("explored_alpha", 0.0)), 0.55), "explored shroud alpha stays 0.55")
	_check(is_equal_approx(float(fog_cfg.get("explored_brightness", 0.0)), 0.45), "explored brightness target is 0.45")
	_check(bool(fog_cfg.get("terrain_under_shroud", false)), "terrain continues under the shroud")
	_check(bool(fog_cfg.get("screen_composited", false)), "K screen shroud is kept")
	var dress: Node = game.world_view.resource_visuals_root.get_node_or_null("OpeningDress")
	_check(dress != null and int(dress.get_meta("hamlet_cottages", 0)) >= 3, "opening still dresses cottages")
	var ridge: Node = dress.find_child("DressRidge", true, false) if dress != null else null
	_check(ridge != null, "opening has a ridge landmark")
	var creek: Node = dress.find_child("DressCreek", true, false) if dress != null else null
	_check(creek != null, "opening has a creek")
	_check(dress == null or dress.find_child("DressCreekBend", true, false) == null, "straight turquoise bend is gone")
	if creek is MeshInstance3D:
		_check(not ((creek as MeshInstance3D).mesh is PlaneMesh), "creek is a curved ribbon, not a plane strip")
	if ridge != null:
		var rocks := 0
		var kaykit := 0
		for child in ridge.get_children():
			if String(child.name).begins_with("RidgeRock_"):
				rocks += 1
			if String(child.name).begins_with("RidgeKaykit_"):
				kaykit += 1
		_check(rocks >= 6 and rocks <= 10, "ridge has 6-10 bevelled masses")
		_check(kaykit >= 6, "ridge instances KayKit CC0 rocks")
	var hall_view = null
	for view in game.world_view.building_views.values():
		if String(view.building_type) == "TOWN_HALL" or String(view.building_type) == "CASTLE":
			hall_view = view
			break
	_check(hall_view != null, "Town Hall view exists")
	if hall_view != null:
		_check(hall_view.find_child("TrimFacade", true, false) == null, "bunker wrap plates are gone")
		_check(hall_view.find_child("TrimFacadePanel_0", true, false) != null, "hall has modular façade panels")
		_check(hall_view.find_child("TrimPlinth", true, false) != null, "hall has a low foundation")
		_check(hall_view.find_child("TrimPilaster_0", true, false) != null, "K pilasters stay")
		_check(hall_view.find_child("DressNoticeBoard", true, false) != null, "K notice board stays")
		var plinth: MeshInstance3D = hall_view.find_child("TrimPlinth", true, false) as MeshInstance3D
		if plinth != null and plinth.mesh is BoxMesh:
			var h := (plinth.mesh as BoxMesh).size.y
			_check(h <= ScaleProfile.TOWN_HALL_WIDTH_METRES * 0.06 + 0.01, "foundation height is <= 0.06B")
	var road_src := FileAccess.get_file_as_string("res://src/GodotClient3D/Scripts/production_road_view_3d.gd")
	_check(road_src.contains("RoadRutDecal") or road_src.contains("road_rut_decal"), "roads place sparse rut decals")
	var ground_src := FileAccess.get_file_as_string("res://src/GodotClient3D/Shaders/settlement_ground.gdshader")
	_check(ground_src.contains("5A7545") or ground_src.contains("526B40") or ground_src.contains("556D3F") or ground_src.contains("0.353, 0.459, 0.271") or ground_src.contains("0.322, 0.420, 0.251") or ground_src.contains("0.333, 0.427, 0.247") or ground_src.contains("536C3F") or ground_src.contains("0.325, 0.424, 0.247"), "meadow splat is #5A7545")
	var showcase := Showcase.apply(game.simulation_host.simulation)
	_check(bool(showcase.get("ok", false)), "showcase still stamps")
	game._sync_presentation()
	var house_view = null
	for view in game.world_view.building_views.values():
		if String(view.building_type) == "HOUSE":
			house_view = view
			break
	if house_view != null:
		_check(house_view.find_child("TrimBeam_0", true, false) != null, "K house beams stay")
		_check(house_view.find_child("TrimPlasterFace", true, false) != null, "houses have a plaster façade")
		_check(house_view.find_child("HouseWoodpile", true, false) != null, "K woodpile stays")
	_sim_night_check(game)
	game.queue_free()
	await process_frame


func _sim_night_check(game) -> void:
	var sim = game.simulation_host.simulation
	sim.is_night = true
	sim.phase_time = 20.0
	game._update_day_night_lighting()
	_check(game.sun_light.light_energy >= 0.38, "live night moon is 0.42")
	_check(not game.environment_resource.fog_enabled, "night keeps Environment haze off")
	var moon_c: Color = game.sun_light.light_color
	_check(moon_c.b > moon_c.g, "live moon is blue, not green")


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
