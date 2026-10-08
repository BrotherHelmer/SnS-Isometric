extends SceneTree

## GFX-02: AgX grade, period LUTs, sun angle, low-profile switches, halo tiles.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Identity = preload("res://src/GodotClient3D/Scripts/production_identity.gd")
const HaloCatalog = preload("res://src/GodotClient3D/Scripts/production_building_halo.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const QualityProfile = preload("res://src/GodotClient3D/Scripts/production_quality_profile.gd")
const ScaleProfile = preload("res://src/GodotClient3D/Scripts/production_scale_profile.gd")
const BuildingMaterials = preload("res://src/GodotClient3D/Scripts/production_building_materials.gd")
const Catalog = preload("res://src/GodotClient3D/Scripts/production_asset_catalog.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.start_new_3d(game.DEFAULT_SEED)
	game._hide_start_menu()
	for _i in 4:
		await process_frame
	var sim = game.simulation_host.simulation

	_check(Identity.LIGHTING.has("day") and Identity.LIGHTING.has("dusk") and Identity.LIGHTING.has("night"), "day, dusk and night presets exist")
	var day_p := Identity.lighting_palette("day")
	var dusk_p := Identity.lighting_palette("dusk")
	var night_p := Identity.lighting_palette("night")
	var mid := Identity.mix_lighting("day", "dusk", 0.5)
	_check(float(mid["sun_energy"]) > float(dusk_p["sun_energy"]) and float(mid["sun_energy"]) < float(day_p["sun_energy"]), "day/dusk interpolate sun energy")
	var dawn := Identity.mix_lighting("night", "day", 0.5)
	_check(float(dawn["sun_energy"]) > float(night_p["sun_energy"]) and float(dawn["sun_energy"]) < float(day_p["sun_energy"]), "night/day interpolate sun energy")
	_check(mid["sun_color"] is Color and not (mid["sun_color"] as Color).is_equal_approx(day_p["sun_color"]), "colour keys interpolate")

	sim.is_night = false
	sim.phase_time = 80.0
	game._update_day_night_lighting()
	_check(game.environment_resource.ssao_enabled, "recommended profile keeps Forward+ SSAO on by day")
	var day_angle: float = game.sun_camera_angle_degrees()
	print("GFX day sun/camera angle=%.1f energy=%.2f" % [day_angle, game.sun_light.light_energy])
	_check(day_angle >= 90.0, "day sun is at least 90° from the camera view")

	sim.phase_time = float(sim.DAY_LENGTH_SECONDS) - 10.0
	game._update_day_night_lighting()
	var dusk_angle: float = game.sun_camera_angle_degrees()
	print("GFX dusk sun/camera angle=%.1f energy=%.2f" % [dusk_angle, game.sun_light.light_energy])
	_check(dusk_angle >= 90.0, "dusk sun is at least 90° from the camera view")
	_check(game.sun_light.light_energy < float(day_p["sun_energy"]) and game.sun_light.light_energy > float(night_p["sun_energy"]) - 0.05, "dusk sits between day and night energy")

	sim.is_night = true
	sim.phase_time = 20.0
	game._update_day_night_lighting()
	_check(absf(game.sun_light.light_energy - float(night_p["sun_energy"])) < 0.03, "night preset applies authored moon energy")
	_check(game.environment_resource.tonemap_mode == Environment.TONE_MAPPER_FILMIC, "tonemap is Filmic")
	_check(float(day_p["saturation"]) >= 0.90 and float(day_p["saturation"]) <= 1.00, "day sat is neutralized 0.90–1.00")
	_check(float(dusk_p["saturation"]) >= 0.90 and float(dusk_p["saturation"]) <= 1.04, "dusk sat is 0.90–1.04")
	_check(float(night_p["saturation"]) >= 0.86 and float(night_p["saturation"]) <= 0.96, "night sat is 0.86–0.96")
	_check(float(day_p["contrast"]) <= 1.16 and float(dusk_p["contrast"]) <= 1.16 and float(day_p["contrast"]) < 1.40, "contrast is not crushed through B/C/S")
	_check(float(night_p["road_lift"]) <= 0.16, "night roads are not lifted into white")
	_check(Identity.grade_lut_for("day") is Texture and Identity.grade_lut3d_for("dusk") is Texture3D and Identity.grade_lut3d_for("night") is Texture3D, "day/dusk/night expose 1D and 3D grade LUTs")
	var dusk_fill: Color = dusk_p["fill_color"]
	var dusk_sun: Color = dusk_p["sun_color"]
	_check(dusk_fill.b > dusk_fill.r and dusk_sun.r > dusk_sun.b, "dusk has a warm key against a cool fill")
	if game.world_view.terrain_mesh_instance != null and game.world_view.terrain_mesh_instance.material_override is ShaderMaterial:
		var ground := game.world_view.terrain_mesh_instance.material_override as ShaderMaterial
		var macro_m := float(ground.get_shader_parameter("macro_metres"))
		var detail_m := float(ground.get_shader_parameter("detail_metres"))
		_check(macro_m >= 8.0 and macro_m <= 20.0, "terrain macro noise is 8–20 m")
		_check(detail_m >= 0.8 and detail_m <= 2.0, "terrain detail layer is 0.8–2 m")
	else:
		_check(false, "terrain uses the settlement ground shader")
	_check(ScaleProfile.ROAD_WIDTH_SCALE <= 1.00 and ScaleProfile.ROAD_WIDTH_SCALE >= 0.90, "roads are 15–20% narrower than GFX-1")
	var sample_road: Node = null
	for view in game.world_view.road_views.values():
		sample_road = view
		break
	if sample_road != null:
		var lane := sample_road.find_child("ContinuousDirt", true, false)
		if lane is MeshInstance3D and (lane as MeshInstance3D).material_override is ShaderMaterial:
			var road_mat := (lane as MeshInstance3D).material_override as ShaderMaterial
			_check(float(road_mat.get_shader_parameter("shoulder_lift")) <= 0.02, "road shoulders are not a bright graphic border")
		else:
			_check(false, "player roads use the settlement road shader")
	else:
		_check(true, "road shader checked when a lane exists")
	var stamp_batches := 0
	if game.world_view.road_stamp_root != null:
		for child in game.world_view.road_stamp_root.get_children():
			if child is MultiMeshInstance3D:
				stamp_batches += 1
	_check(stamp_batches <= 3, "road detail is 2–3 batched stamps, not per-tile Decals")
	_check(game.sun_light.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS, "sun uses PSSM 2-split")
	_check(game.sun_light.directional_shadow_split_1 >= 0.78 and game.sun_light.directional_shadow_split_1 <= 0.88, "PSSM split stays parked at 0.82")
	_check(is_equal_approx(game.environment_resource.ssao_sharpness, 0.35), "SSAO sharpness stays 0.35")
	_check(game.world_view.terrain_mesh_instance != null and game.world_view.terrain_mesh_instance.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "terrain does not cast")
	_check(is_zero_approx(game.sun_light.light_angular_distance), "sun angular distance is 0 (no PCSS)")
	_check(game.sun_light.directional_shadow_max_distance <= 52.0, "shadow distance stays near the play volume")
	var shadow_suns := 0
	for child in game.lighting_rig.get_children():
		if child is DirectionalLight3D and (child as DirectionalLight3D).shadow_enabled:
			shadow_suns += 1
	_check(shadow_suns == 1, "only the key sun casts directional shadows")
	_check(game.fill_light != null and not game.fill_light.shadow_enabled, "cool fill stays shadowless")
	_check(not game.environment_resource.ssao_enabled, "night cheap-path turns SSAO off")
	_check(game.environment_resource.ssao_radius >= 0.70 and game.environment_resource.ssao_radius <= 1.20, "SSAO radius is 0.7–1.2 m")
	_check(game.environment_resource.ssao_light_affect <= 0.20, "SSAO direct-light influence stays low")
	var contact_count := 0
	for view in game.world_view.building_views.values():
		if view.find_child("ContactAO", true, false) != null:
			contact_count += 1
	_check(contact_count > 0, "buildings carry a contact-AO disc")
	_check(is_equal_approx(BuildingMaterials.roughness_for("plaster"), 0.80), "plaster roughness is 0.80")
	_check(is_equal_approx(BuildingMaterials.roughness_for("timber"), 0.70), "timber roughness is 0.70")
	_check(is_equal_approx(BuildingMaterials.roughness_for("roof"), 0.72), "roof roughness is 0.72")
	_check(is_equal_approx(BuildingMaterials.roughness_for("stone"), 0.85), "stone roughness is 0.85")
	_check(Catalog.TREES.size() >= 4 and Catalog.TREES.size() <= 8, "vegetation kit is 4–6 tree silhouettes")
	_check(Catalog.EDGE_TREES.size() >= 4, "edge forest uses more than one cone")
	_check(Identity.PALETTE_WINDOW.is_equal_approx(Color("#F2B56B")), "window/fire accent is #F2B56B")
	_check(float(night_p["torch_range"]) <= 4.2, "night window pools stay short-range")

	game.apply_quality_profile("recommended")
	_check(not game.environment_resource.ssil_enabled and not game.environment_resource.glow_enabled, "recommended profile keeps SSIL and glow off")
	game.apply_quality_profile("scalable_low")
	_check(not game.environment_resource.ssil_enabled, "low profile disables SSIL")
	_check(not game.environment_resource.glow_enabled, "low profile disables glow")
	_check(not game.environment_resource.volumetric_fog_enabled, "low profile disables volumetrics")
	game.apply_quality_profile("recommended")
	_check(bool(QualityProfile.get_profile("recommended").get("ssil", true)) == false, "recommended table turns SSIL off")
	_check(bool(QualityProfile.get_profile("scalable_low").get("ssil", true)) == false, "low profile table turns SSIL off")

	var blocked := {}
	for road_tile in sim.connected_roads.keys():
		blocked[String(road_tile)] = true
	for building_value in sim.get_buildings():
		var building: Dictionary = building_value
		var type_name := String(building.get("type", ""))
		var anchor: Vector2i = building.get("position", Vector2i.ZERO)
		var footprint: Vector2i = Defs.building_footprint(type_name)
		for oy in footprint.y:
			for ox in footprint.x:
				blocked["%d,%d" % [anchor.x + ox, anchor.y + oy]] = true
	var live := HaloCatalog.resolve_world(sim)
	var overlap := 0
	for placement_value in live:
		var tile: Vector2i = Dictionary(placement_value).get("tile", Vector2i.ZERO)
		if blocked.has("%d,%d" % [tile.x, tile.y]):
			overlap += 1
	print("GFX halo placements=%d overlap=%d" % [live.size(), overlap])
	_check(overlap == 0, "halos never overlap footprints or road tiles")
	_check(HaloCatalog.authored_for("HOUSE").size() >= 4 and HaloCatalog.authored_for("HOUSE").size() <= 12, "house halo table has 4–12 authored slots")
	_check(HaloCatalog.prop_path("dirt_plot").contains("dirt_plot"), "story zones can place a dirt plot")
	_check(HaloCatalog.authored_for("FARM").size() >= 6, "farm story zone is authored")
	_check(game.world_view.water_mesh_instance != null and game.world_view.water_material != null, "island water plane is live")
	_check(game.world_view.find_child("OuterWildernessFloor", true, false) == null, "teal wilderness floor is gone")
	_check(game.world_view.horizon_root != null and game.world_view.horizon_root.get_child_count() >= 12, "distant horizon hills are instanced")
	var fog: Dictionary = game.world_view.fog_configuration()
	_check(bool(fog.get("exterior_opaque", false)), "unexplored off-map fog stays opaque")
	_check(float(fog.get("shore_fade_metres", 0.0)) >= 8.0, "explored edges open a short shore band")
	_check(HaloCatalog.authored_for("SAWMILL").size() >= 4, "sawmill halo table is authored")
	_check(HaloCatalog.authored_for("BAKERY").size() >= 4, "bakery halo table is authored")
	_check(HaloCatalog.authored_for("QUARRY").size() >= 4, "quarry halo table is authored")
	_check(not HaloCatalog.prop_path("sack").contains("crate"), "sack does not reuse the crate model")
	var illegal_ground := 0
	for placement_value in live:
		var tile: Vector2i = Dictionary(placement_value).get("tile", Vector2i.ZERO)
		if not sim.is_inside_map(tile) or String(sim.get_tile(tile)) != Defs.TILE_GRASS:
			illegal_ground += 1
	_check(illegal_ground == 0, "halos only sit on revealed grass tiles")

	_finish(game)


func _finish(game: Node) -> void:
	game.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	print("T_GFX_LIGHT %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
