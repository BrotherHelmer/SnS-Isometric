extends SceneTree

## GFX-J light gate: screen shroud, limestone landmarks, organic meadow,
## unmistakable ridge/creek. Global grade stays GFX-I.

const Catalog = preload("res://src/GodotClient3D/Scripts/production_asset_catalog.gd")
const QualityProfile = preload("res://src/GodotClient3D/Scripts/production_quality_profile.gd")
const Identity = preload("res://src/GodotClient3D/Scripts/production_identity.gd")
const BuildingMaterials = preload("res://src/GodotClient3D/Scripts/production_building_materials.gd")
const CameraRig = preload("res://src/GodotClient3D/Scripts/production_isometric_camera_rig.gd")
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
	print("T_GFX_J %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check_grade() -> void:
	var day_p := Identity.lighting_palette("day")
	var night_p := Identity.lighting_palette("night")
	_check(float(day_p["saturation"]) >= 1.10 and float(day_p["saturation"]) <= 1.16, "day sat stays 1.12")
	_check(float(day_p["contrast"]) >= 1.10 and float(day_p["contrast"]) <= 1.16, "day contrast stays 1.12")
	_check(float(day_p["exposure"]) >= 0.82 and float(day_p["exposure"]) <= 0.90, "day exposure stays 0.86")
	_check(is_equal_approx(float(day_p["sun_energy"]), 1.10), "day sun is 1.10")
	_check(is_equal_approx(float(day_p["sun_pitch"]), -38.0), "day sun elevation is 38°")
	_check(day_p["sun_color"].is_equal_approx(Color("#FFE8CE")), "day key is #FFE8CE")
	_check(is_equal_approx(float(day_p["ambient"]), 0.32), "day ambient energy is 0.32")
	_check(day_p["ambient_color"].is_equal_approx(Color("#91A29A")), "day ambient is #91A29A")
	_check(is_equal_approx(float(day_p["fog_density"]), 0.0), "day environment haze density is 0")
	_check(Identity.PALETTE_LIMESTONE.is_equal_approx(Color("#C5B69B")) or Identity.PALETTE_LIMESTONE.is_equal_approx(Color("#CBBCA0")) or Identity.PALETTE_LIMESTONE.is_equal_approx(Color("#CDBD9F")), "limestone stays pale")
	_check(Identity.PALETTE_PLASTER.is_equal_approx(Color("#D8C7A8")) or Identity.PALETTE_PLASTER.is_equal_approx(Color("#E0CDA9")) or Identity.PALETTE_PLASTER.is_equal_approx(Color("#E0CDAE")), "plaster is warm")
	_check(Identity.PALETTE_TIMBER.is_equal_approx(Color("#59402B")) or Identity.PALETTE_TIMBER.is_equal_approx(Color("#62432F")) or Identity.PALETTE_TIMBER.is_equal_approx(Color("#64452F")), "timber is dark")
	_check(Identity.PALETTE_TEAL.is_equal_approx(Color("#456966")) or Identity.PALETTE_TEAL.is_equal_approx(Color("#426C67")) or Identity.PALETTE_TEAL.is_equal_approx(Color("#456D68")), "slate is teal")
	_check(Identity.PALETTE_STONE.is_equal_approx(Color("#776F60")) or Identity.PALETTE_STONE.is_equal_approx(Color("#817968")) or Identity.PALETTE_STONE.is_equal_approx(Color("#716A5D")), "stone accent is weathered")
	_check(Identity.PALETTE_FOG_UNKNOWN.is_equal_approx(Color("#17272A")), "shroud colour is #17272A")
	_check(float(night_p["sun_energy"]) >= 0.38 and float(night_p["sun_energy"]) <= 0.48, "night moon energy stays 0.42")
	var moon: Color = night_p["sun_color"]
	_check(moon.b > moon.g and moon.b > moon.r, "night key is moonlit blue, not green")


func _check_materials() -> void:
	var hall := BuildingMaterials.remap_albedo("stone", Color("#1a1612"), "TOWN_HALL")
	var luma := hall.r * 0.2126 + hall.g * 0.7152 + hall.b * 0.0722
	_check(luma >= 0.40, "Town Hall stone reads as pale limestone")
	_check(BuildingMaterials.CASTLE_LIMESTONE.is_equal_approx(Color("#C5B69B")) or BuildingMaterials.CASTLE_LIMESTONE.is_equal_approx(Color("#CBBCA0")) or BuildingMaterials.CASTLE_LIMESTONE.is_equal_approx(Color("#CDBD9F")), "castle limestone is pale")
	_check(BuildingMaterials.WARM_PLASTER.is_equal_approx(Color("#D8C7A8")) or BuildingMaterials.WARM_PLASTER.is_equal_approx(Color("#E0CDA9")) or BuildingMaterials.WARM_PLASTER.is_equal_approx(Color("#E0CDAE")), "shared plaster is warm")
	_check(BuildingMaterials.DARK_TIMBER.is_equal_approx(Color("#59402B")) or BuildingMaterials.DARK_TIMBER.is_equal_approx(Color("#62432F")) or BuildingMaterials.DARK_TIMBER.is_equal_approx(Color("#64452F")), "shared timber is dark")
	_check(BuildingMaterials.HALL_SLATE.is_equal_approx(Color("#456966")) or BuildingMaterials.HALL_SLATE.is_equal_approx(Color("#426C67")) or BuildingMaterials.HALL_SLATE.is_equal_approx(Color("#456D68")), "hall roof is teal slate")
	_check(BuildingMaterials.WEATHERED_STONE.is_equal_approx(Color("#776F60")) or BuildingMaterials.WEATHERED_STONE.is_equal_approx(Color("#817968")) or BuildingMaterials.WEATHERED_STONE.is_equal_approx(Color("#716A5D")), "shared stone is weathered")
	_check(BuildingMaterials.roughness_for("plaster") >= 0.79 and BuildingMaterials.roughness_for("plaster") <= 0.96, "plaster roughness is matte")
	_check(BuildingMaterials.roughness_for("stone") >= 0.84 and BuildingMaterials.roughness_for("stone") <= 0.90, "stone roughness is matte")


func _check_zoom() -> void:
	_check(is_equal_approx(CameraRig.NORMAL_ZOOM, 26.0), "gameplay zoom stays 26")
	_check(CameraRig.STRATEGIC_ZOOM <= 39.5 and CameraRig.STRATEGIC_ZOOM >= 38.0, "zoom-out cap is ~1.5×")
	_check(is_equal_approx(CameraRig.PLAY_ZOOM_CAP, 1.5), "play zoom cap is 1.5")


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
	_check(not game.environment_resource.volumetric_fog_enabled, "volumetric fog stays off")
	_check(game.world_view.has_method("_ensure_fog_screen"), "screen shroud exists")
	_check(game.world_view.has_method("_spawn_opening_ridge"), "opening ridge exists")
	var fog_cfg: Dictionary = game.world_view.fog_configuration()
	_check(is_equal_approx(float(fog_cfg.get("visible_alpha", 1.0)), 0.0), "visible shroud alpha is 0")
	_check(is_equal_approx(float(fog_cfg.get("explored_alpha", 0.0)), 0.45) or is_equal_approx(float(fog_cfg.get("explored_alpha", 0.0)), 0.55), "explored shroud alpha is 0.45-0.55")
	_check(is_equal_approx(float(fog_cfg.get("unexplored_alpha", 0.0)), 1.0), "unexplored shroud alpha is 1")
	_check(float(fog_cfg.get("edge_feather_cells", 0.0)) <= 1.5 and float(fog_cfg.get("edge_feather_cells", 0.0)) >= 1.0, "feather is 1-1.5 cells")
	_check(bool(fog_cfg.get("screen_composited", false)), "shroud is screen-composited")
	_check(bool(fog_cfg.get("haze_reverted", false)), "GFX-H haze stays reverted")
	var screen_src := FileAccess.get_file_as_string("res://src/GodotClient3D/Shaders/production_fog_screen.gdshader")
	_check(screen_src.contains("skip_vertex_transform"), "screen shroud is a clip-space overlay")
	_check(screen_src.contains("1.0 - inside"), "off-map screen pixels stay opaque")
	_check(not screen_src.contains("float edge_veil"), "screen shroud has no island haze veil")
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
		_check(rocks >= 8, "ridge occupies 1.5-2 Town Hall widths")
	var hall_view = null
	for view in game.world_view.building_views.values():
		if String(view.building_type) == "TOWN_HALL" or String(view.building_type) == "CASTLE":
			hall_view = view
			break
	_check(hall_view != null, "Town Hall view exists")
	if hall_view != null:
		_check(hall_view.find_child("TrimPlinth", true, false) != null, "Town Hall has a stone plinth")
		_check(hall_view.find_child("TrimQuoin_0", true, false) != null, "Town Hall has limestone quoins")
		_check(hall_view.find_child("TrimEntrance", true, false) != null, "Town Hall has an entrance surround")
	var patches: Node = game.world_view.ground_patch_root
	_check(patches != null and patches.get_child_count() > 0, "ground patches spawned MultiMesh chunks")
	game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(game.simulation_host.simulation.town_hall_position)), 80.0)
	_check(game.camera_rig.target_zoom <= CameraRig.STRATEGIC_ZOOM + 0.01, "compose_view respects the 1.5× zoom cap")
	var showcase := Showcase.apply(game.simulation_host.simulation)
	_check(bool(showcase.get("ok", false)), "showcase still stamps")
	game._sync_presentation()
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
	_check(game.environment_resource.background_mode == Environment.BG_COLOR, "night background stays a colour")
	var moon_c: Color = game.sun_light.light_color
	_check(moon_c.b > moon_c.g, "live moon is blue, not green")


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
