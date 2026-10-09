extends SceneTree

## GFX-K light gate: screen shroud 0.55, limestone hierarchy, opening
## landmark, worn roads, three-scale meadow, woodland edge, dressing.
## Global grade stays GFX-I/J. Item 8 lighting A/B is rolled back.

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
	print("T_GFX_K %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check_grade() -> void:
	var day_p := Identity.lighting_palette("day")
	var night_p := Identity.lighting_palette("night")
	_check(float(day_p["saturation"]) >= 1.10 and float(day_p["saturation"]) <= 1.16, "day sat stays 1.12")
	_check(float(day_p["contrast"]) >= 1.10 and float(day_p["contrast"]) <= 1.16, "day contrast stays 1.12")
	_check(float(day_p["exposure"]) >= 0.82 and float(day_p["exposure"]) <= 0.90, "day exposure stays 0.86")
	_check(is_equal_approx(float(day_p["sun_energy"]), 1.10), "day sun stays 1.10 (item 8 rolled back)")
	_check(day_p["sun_color"].is_equal_approx(Color("#FFE8CE")), "day key stays #FFE8CE")
	_check(is_equal_approx(float(day_p["ambient"]), 0.32), "day ambient stays 0.32")
	_check(Identity.PALETTE_LIMESTONE.is_equal_approx(Color("#CBBCA0")) or Identity.PALETTE_LIMESTONE.is_equal_approx(Color("#CDBD9F")), "limestone is pale")
	_check(Identity.PALETTE_PLASTER.is_equal_approx(Color("#E0CDA9")) or Identity.PALETTE_PLASTER.is_equal_approx(Color("#E0CDAE")), "plaster is warm")
	_check(Identity.PALETTE_TIMBER.is_equal_approx(Color("#62432F")) or Identity.PALETTE_TIMBER.is_equal_approx(Color("#64452F")), "timber is dark")
	_check(Identity.PALETTE_TEAL.is_equal_approx(Color("#426C67")) or Identity.PALETTE_TEAL.is_equal_approx(Color("#456D68")), "slate is teal")
	_check(Identity.PALETTE_STONE.is_equal_approx(Color("#817968")) or Identity.PALETTE_STONE.is_equal_approx(Color("#716A5D")), "recessed stone is dark")
	_check(Identity.PALETTE_FOG_UNKNOWN.is_equal_approx(Color("#17272A")), "shroud colour is #17272A")
	_check(is_equal_approx(ScaleProfile.TOWN_HALL_WIDTH_METRES, 10.0), "W is the 4x4 Town Hall")
	_check(float(night_p["sun_energy"]) >= 0.38 and float(night_p["sun_energy"]) <= 0.48, "night moon energy stays 0.42")


func _check_materials() -> void:
	var hall := BuildingMaterials.remap_albedo("stone", Color("#1a1612"), "TOWN_HALL")
	var luma := hall.r * 0.2126 + hall.g * 0.7152 + hall.b * 0.0722
	_check(luma >= 0.40, "Town Hall stone reads as pale limestone")
	_check(BuildingMaterials.CASTLE_LIMESTONE.is_equal_approx(Color("#CBBCA0")) or BuildingMaterials.CASTLE_LIMESTONE.is_equal_approx(Color("#CDBD9F")), "castle limestone is pale")
	_check(BuildingMaterials.WARM_PLASTER.is_equal_approx(Color("#E0CDA9")) or BuildingMaterials.WARM_PLASTER.is_equal_approx(Color("#E0CDAE")), "shared plaster is warm")
	_check(BuildingMaterials.DARK_TIMBER.is_equal_approx(Color("#62432F")) or BuildingMaterials.DARK_TIMBER.is_equal_approx(Color("#64452F")), "shared timber is dark")
	_check(BuildingMaterials.HALL_SLATE.is_equal_approx(Color("#426C67")) or BuildingMaterials.HALL_SLATE.is_equal_approx(Color("#456D68")), "hall roof is teal slate")
	_check(BuildingMaterials.WEATHERED_STONE.is_equal_approx(Color("#817968")) or BuildingMaterials.WEATHERED_STONE.is_equal_approx(Color("#716A5D")), "shared stone is weathered")
	_check(is_equal_approx(BuildingMaterials.roughness_for("plaster"), 0.95), "plaster roughness is 0.95")
	_check(is_equal_approx(BuildingMaterials.roughness_for("stone"), 0.88), "stone roughness is 0.88")
	_check(BuildingMaterials.roughness_for("timber") >= 0.90 and BuildingMaterials.roughness_for("timber") <= 0.92, "timber roughness is 0.90-0.92")
	_check(BuildingMaterials.roughness_for("roof") >= 0.82 and BuildingMaterials.roughness_for("roof") <= 0.88, "roof roughness is 0.82-0.88")


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
	_check(game.environment_resource.background_mode == Environment.BG_COLOR, "environment background is a colour")
	_check(game.environment_resource.background_color.is_equal_approx(Color("#17272A")), "background is #17272A")
	_check(not game.environment_resource.fog_enabled, "Environment haze is off")
	_check(game.world_view.has_method("opening_camera_focus"), "opening camera composition exists")
	_check(game.world_view.has_method("_bevelled_ridge_mesh"), "ridge uses bevelled rocks")
	var fog_cfg: Dictionary = game.world_view.fog_configuration()
	_check(is_equal_approx(float(fog_cfg.get("visible_alpha", 1.0)), 0.0), "visible shroud alpha is 0")
	_check(is_equal_approx(float(fog_cfg.get("explored_alpha", 0.0)), 0.55), "explored shroud alpha is 0.55")
	_check(is_equal_approx(float(fog_cfg.get("unexplored_alpha", 0.0)), 1.0), "unexplored shroud alpha is 1")
	_check(is_equal_approx(float(fog_cfg.get("noise_strength", 1.0)), 0.12), "frontier noise is 0.15 cells")
	_check(bool(fog_cfg.get("screen_composited", false)), "shroud is screen-composited")
	var screen_src := FileAccess.get_file_as_string("res://src/GodotClient3D/Shaders/production_fog_screen.gdshader")
	_check(screen_src.contains("textureSize"), "missing mask samples as unexplored")
	_check(screen_src.contains("1.0 - inside"), "off-map screen pixels stay opaque")
	var dress: Node = game.world_view.resource_visuals_root.get_node_or_null("OpeningDress")
	_check(dress != null and dress.get_child_count() > 0, "opening has dress children")
	_check(int(dress.get_meta("hamlet_cottages", 0)) >= 3, "opening still dresses at least three cottages")
	var ridge: Node = dress.find_child("DressRidge", true, false)
	_check(ridge != null, "opening has a ridge landmark")
	_check(dress.find_child("DressCreek", true, false) != null, "opening ridge includes a creek")
	if ridge != null:
		var rocks := 0
		for child in ridge.get_children():
			if String(child.name).begins_with("RidgeRock_"):
				rocks += 1
		_check(rocks >= 6 and rocks <= 10, "ridge has 6-10 bevelled rocks")
	var hall_view = null
	for view in game.world_view.building_views.values():
		if String(view.building_type) == "TOWN_HALL" or String(view.building_type) == "CASTLE":
			hall_view = view
			break
	_check(hall_view != null, "Town Hall view exists")
	if hall_view != null:
		_check(hall_view.find_child("TrimPilaster_0", true, false) != null, "Town Hall has limestone pilasters")
		_check(hall_view.find_child("TrimHallBandUpper", true, false) != null, "Town Hall has two stone bands")
		_check(hall_view.find_child("DressNoticeBoard", true, false) != null, "Town Hall front has a notice board")
		_check(hall_view.find_child("DressCivicFlag", true, false) != null, "Town Hall front has a flag")
	var road_src := FileAccess.get_file_as_string("res://src/GodotClient3D/Shaders/settlement_road.gdshader")
	_check(road_src.contains("9F8260") or road_src.contains("B0926C") or road_src.contains("0.690, 0.573, 0.424"), "roads use compacted earth")
	_check(road_src.contains("rut"), "roads have cart ruts")
	var ground_src := FileAccess.get_file_as_string("res://src/GodotClient3D/Shaders/settlement_ground.gdshader")
	_check(ground_src.contains("60764A") or ground_src.contains("5A7545") or ground_src.contains("0.353, 0.459, 0.271"), "meadow base is olive")
	_check(game.world_view.ground_patch_root != null and game.world_view.ground_patch_root.get_child_count() > 0, "ground patches spawned")
	var showcase := Showcase.apply(game.simulation_host.simulation)
	_check(bool(showcase.get("ok", false)), "showcase still stamps")
	game._sync_presentation()
	var house_view = null
	for view in game.world_view.building_views.values():
		if String(view.building_type) == "HOUSE":
			house_view = view
			break
	_check(house_view != null, "showcase has a house view")
	if house_view != null:
		_check(house_view.find_child("TrimBeam_0", true, false) != null, "houses have projecting timber beams")
		_check(house_view.find_child("HouseWoodpile", true, false) != null, "houses have a woodpile")
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
