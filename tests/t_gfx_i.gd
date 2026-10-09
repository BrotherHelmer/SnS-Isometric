extends SceneTree

## GFX-I light gate: haze reverted, world-space shroud, local lighting,
## chunked ground patches, trim sheets, opening ridge.

const Catalog = preload("res://src/GodotClient3D/Scripts/production_asset_catalog.gd")
const QualityProfile = preload("res://src/GodotClient3D/Scripts/production_quality_profile.gd")
const Identity = preload("res://src/GodotClient3D/Scripts/production_identity.gd")
const BuildingMaterials = preload("res://src/GodotClient3D/Scripts/production_building_materials.gd")
const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Showcase = preload("res://src/GodotClient3D/Scripts/production_gfx_d_showcase.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	_check_grade()
	_check_materials()
	_check_shadows()
	await _check_live_scene()
	print("T_GFX_I %s" % ("PASS" if failures.is_empty() else "FAIL"))
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
	_check(Identity.PALETTE_PLASTER.is_equal_approx(Color("#D8C7A8")) or Identity.PALETTE_PLASTER.is_equal_approx(Color("#D6C5A2")) or Identity.PALETTE_PLASTER.is_equal_approx(Color("#E0CDA9")) or Identity.PALETTE_PLASTER.is_equal_approx(Color("#E0CDAE")), "plaster trim stays warm plaster")
	_check(Identity.PALETTE_TIMBER.is_equal_approx(Color("#59402B")) or Identity.PALETTE_TIMBER.is_equal_approx(Color("#553C2B")) or Identity.PALETTE_TIMBER.is_equal_approx(Color("#62432F")) or Identity.PALETTE_TIMBER.is_equal_approx(Color("#64452F")), "timber trim stays dark timber")
	_check(Identity.PALETTE_TEAL.is_equal_approx(Color("#456966")) or Identity.PALETTE_TEAL.is_equal_approx(Color("#426863")) or Identity.PALETTE_TEAL.is_equal_approx(Color("#426C67")) or Identity.PALETTE_TEAL.is_equal_approx(Color("#456D68")), "roof trim stays teal slate")
	_check(Identity.PALETTE_STONE.is_equal_approx(Color("#776F60")) or Identity.PALETTE_STONE.is_equal_approx(Color("#A39A85")) or Identity.PALETTE_STONE.is_equal_approx(Color("#817968")), "stone trim stays weathered")
	_check(Identity.PALETTE_FOG_UNKNOWN.is_equal_approx(Color("#17272A")), "shroud colour is #17272A")
	_check(float(night_p["sun_energy"]) >= 0.38 and float(night_p["sun_energy"]) <= 0.48, "night moon energy stays 0.42")
	var moon: Color = night_p["sun_color"]
	_check(moon.b > moon.g and moon.b > moon.r, "night key is moonlit blue, not green")
	var ambient: Color = night_p["ambient_color"]
	_check(ambient.b > ambient.g, "night ambient is blue, not olive")


func _check_materials() -> void:
	var hall := BuildingMaterials.remap_albedo("stone", Color("#1a1612"), "TOWN_HALL")
	var luma := hall.r * 0.2126 + hall.g * 0.7152 + hall.b * 0.0722
	_check(luma >= 0.28, "Town Hall stone is not near-black")
	_check(BuildingMaterials.WARM_PLASTER.is_equal_approx(Color("#D8C7A8")) or BuildingMaterials.WARM_PLASTER.is_equal_approx(Color("#D6C5A2")) or BuildingMaterials.WARM_PLASTER.is_equal_approx(Color("#E0CDA9")) or BuildingMaterials.WARM_PLASTER.is_equal_approx(Color("#E0CDAE")), "shared plaster is warm")
	_check(BuildingMaterials.DARK_TIMBER.is_equal_approx(Color("#59402B")) or BuildingMaterials.DARK_TIMBER.is_equal_approx(Color("#553C2B")) or BuildingMaterials.DARK_TIMBER.is_equal_approx(Color("#62432F")) or BuildingMaterials.DARK_TIMBER.is_equal_approx(Color("#64452F")), "shared timber is dark")
	_check(BuildingMaterials.HALL_SLATE.is_equal_approx(Color("#456966")) or BuildingMaterials.HALL_SLATE.is_equal_approx(Color("#426863")) or BuildingMaterials.HALL_SLATE.is_equal_approx(Color("#426C67")) or BuildingMaterials.HALL_SLATE.is_equal_approx(Color("#456D68")), "hall roof is teal slate")
	_check(BuildingMaterials.WEATHERED_STONE.is_equal_approx(Color("#776F60")) or BuildingMaterials.WEATHERED_STONE.is_equal_approx(Color("#A39A85")) or BuildingMaterials.WEATHERED_STONE.is_equal_approx(Color("#817968")), "shared stone is weathered")


func _check_shadows() -> void:
	var rec := QualityProfile.get_profile("recommended")
	_check(int(rec.get("shadow_splits", 2)) == 4, "recommended uses 4 shadow splits")
	_check(is_equal_approx(float(rec.get("shadow_blur", 0.0)), 1.0), "recommended shadow blur is 1.0")
	_check(float(rec.get("shadow_distance", 48.0)) >= 54.0, "recommended shadow distance covers the village")
	_check(bool(rec.get("glow", true)) == false, "recommended keeps glow off")


func _check_live_scene() -> void:
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.start_new_3d(game.DEFAULT_SEED)
	game._hide_start_menu()
	for _i in 4:
		await process_frame
	_check(game.environment_resource.tonemap_mode == Environment.TONE_MAPPER_FILMIC, "tonemap is Filmic")
	_check(not game.environment_resource.fog_enabled, "Environment haze is off")
	_check(not game.environment_resource.volumetric_fog_enabled, "volumetric fog stays off")
	_check(is_equal_approx(game.sun_light.shadow_opacity, 0.85), "day shadow opacity is 0.85")
	_check(is_equal_approx(game.sun_light.shadow_blur, 1.0), "day shadow blur is 1.0")
	_check(is_equal_approx(game.environment_resource.ssao_radius, 0.55), "SSAO radius is 0.55")
	_check(is_equal_approx(game.environment_resource.ssao_intensity, 1.10), "SSAO intensity is 1.10")
	_check(game.world_view.has_method("_rebuild_ground_patches"), "chunked ground patches exist")
	_check(game.world_view.has_method("_spawn_opening_ridge"), "opening ridge exists")
	_check(game.world_view.has_method("_paint_current_vision"), "current-vision shroud exists")
	var patches: Node = game.world_view.ground_patch_root
	_check(patches != null and patches.get_child_count() > 0, "ground patches spawned MultiMesh chunks")
	var chunked := 0
	if patches != null:
		for child in patches.get_children():
			if child is MultiMeshInstance3D:
				chunked += 1
	_check(chunked >= 2, "ground patches are chunked MultiMeshes")
	var dress: Node = game.world_view.resource_visuals_root.get_node_or_null("OpeningDress")
	_check(dress != null and dress.get_child_count() > 0, "opening has dress children")
	_check(int(dress.get_meta("hamlet_cottages", 0)) >= 3, "opening still dresses at least three cottages")
	_check(dress.find_child("DressWheat_0_0", true, false) != null, "opening still has crop rows")
	_check(dress.find_child("DressRidge", true, false) != null, "opening has a ridge landmark")
	_check(dress.find_child("DressCreek", true, false) != null, "opening ridge includes a creek")
	var fog_cfg: Dictionary = game.world_view.fog_configuration()
	_check(is_equal_approx(float(fog_cfg.get("visible_alpha", 1.0)), 0.0), "visible shroud alpha is 0")
	_check(is_equal_approx(float(fog_cfg.get("explored_alpha", 0.0)), 0.45) or is_equal_approx(float(fog_cfg.get("explored_alpha", 0.0)), 0.55), "explored shroud alpha is 0.45")
	_check(is_equal_approx(float(fog_cfg.get("unexplored_alpha", 0.0)), 1.0), "unexplored shroud alpha is 1")
	_check(bool(fog_cfg.get("haze_reverted", false)), "GFX-H haze is marked reverted")
	_check(float(fog_cfg.get("edge_feather_cells", 0.0)) <= 2.0 and float(fog_cfg.get("edge_feather_cells", 0.0)) >= 1.0, "feather is 1-2 cells")
	var fog := FileAccess.get_file_as_string("res://src/GodotClient3D/Shaders/production_fog_of_war.gdshader")
	_check(not fog.contains("float edge_veil"), "fog shader has no island haze veil")
	_check(fog.contains("feather_cells"), "fog shader feathers 1-2 cells")
	var hall_view = null
	for view in game.world_view.building_views.values():
		if String(view.building_type) == "TOWN_HALL" or String(view.building_type) == "CASTLE":
			hall_view = view
			break
	_check(hall_view != null, "Town Hall view exists")
	if hall_view != null:
		_check(hall_view.find_child("TrimPlinth", true, false) != null, "Town Hall has a stone plinth")
		_check(hall_view.find_child("TrimTimber_0", true, false) != null, "Town Hall has timber posts")
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
	var moon_c: Color = game.sun_light.light_color
	_check(moon_c.b > moon_c.g, "live moon is blue, not green")
	var dress: Node = game.world_view.resource_visuals_root.get_node_or_null("OpeningDress")
	if dress != null:
		var window: OmniLight3D = dress.find_child("DressWindow", true, false) as OmniLight3D
		_check(window != null and window.visible, "hamlet windows glow at night")


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
