extends SceneTree

## GFX-F light gate, widened for GFX-G: Filmic 0.78, yellow-olive meadow,
## opening dress, opaque fog shroud, readable night.

const Catalog = preload("res://src/GodotClient3D/Scripts/production_asset_catalog.gd")
const QualityProfile = preload("res://src/GodotClient3D/Scripts/production_quality_profile.gd")
const Identity = preload("res://src/GodotClient3D/Scripts/production_identity.gd")
const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Showcase = preload("res://src/GodotClient3D/Scripts/production_gfx_d_showcase.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	_check_grade()
	_check_shadows()
	await _check_live_scene()
	print("T_GFX_F %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check_grade() -> void:
	var day_p := Identity.lighting_palette("day")
	var night_p := Identity.lighting_palette("night")
	_check(float(day_p["saturation"]) >= 1.08 and float(day_p["saturation"]) <= 1.18, "day sat is 1.08–1.16")
	_check(float(day_p["exposure"]) >= 0.74 and float(day_p["exposure"]) <= 0.90, "day exposure is Filmic 0.78–0.86")
	_check(float(day_p["tonemap_white"]) >= 5.5 and float(day_p["tonemap_white"]) <= 6.5, "Filmic white is 6")
	_check(float(day_p["sun_energy"]) >= 1.15 and float(day_p["sun_energy"]) <= 1.28, "day sun is 1.20–1.24")
	_check(float(day_p["ambient"]) >= 0.18 and float(day_p["ambient"]) <= 0.30, "day ambient stays low")
	_check(float(day_p["contrast"]) >= 1.06 and float(day_p["contrast"]) <= 1.16, "day contrast is 1.08–1.14")
	var sun: Color = day_p["sun_color"]
	_check(sun.is_equal_approx(Color("#FFF0DE")), "day key is #FFF0DE")
	_check(Identity.PALETTE_MEADOW.g > Identity.PALETTE_MEADOW.r and Identity.PALETTE_MEADOW.r > Identity.PALETTE_MEADOW.b, "meadow is yellow-olive")
	_check(Identity.PALETTE_SUNLIT_GRASS.g > Identity.PALETTE_SUNLIT_GRASS.r, "sunlit meadow stays green")
	_check(Identity.PALETTE_WINDOW.is_equal_approx(Color("#F5B36B")), "window emission is #F5B36B")
	_check(float(night_p["sun_energy"]) >= 0.40 and float(night_p["sun_energy"]) <= 0.55, "night moon is a readable moonlight")
	_check(float(night_p["ambient"]) >= 0.28 and float(night_p["ambient"]) <= 0.42, "night ambient is lifted")
	_check(float(night_p["exposure"]) >= 0.84 and float(night_p["exposure"]) <= 0.96, "night exposure is lifted")
	var moon: Color = night_p["sun_color"]
	_check(moon.b > moon.r, "night key stays cool, not cyan-bright")


func _check_shadows() -> void:
	var rec := QualityProfile.get_profile("recommended")
	_check(int(rec.get("shadow_splits", 2)) == 4, "recommended uses 4 shadow splits")
	_check(float(rec.get("shadow_blur", 1.6)) <= 0.85, "recommended shadow blur is 0.8")
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
	_check(game.sun_light.shadow_opacity >= 0.98, "day shadows are opacity 1")
	_check(game.sun_light.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS, "day uses 4 PSSM splits")
	_check(game.environment_resource.ambient_light_energy <= 0.30, "live ambient is the low day fill")
	_check(game.environment_resource.ssao_intensity >= 1.45, "SSAO intensity is 1.50")
	_check(game.world_view.has_method("_rebuild_opening_dressing"), "opening dress exists")
	var dress: Node = game.world_view.resource_visuals_root.get_node_or_null("OpeningDress")
	_check(dress != null and dress.get_child_count() > 0, "opening has a wilderness frame")
	if game.world_view.terrain_mesh_instance != null and game.world_view.terrain_mesh_instance.material_override is ShaderMaterial:
		var ground := game.world_view.terrain_mesh_instance.material_override as ShaderMaterial
		var lush: Vector3 = ground.get_shader_parameter("meadow_lush")
		_check(lush.y > lush.x and lush.x < 0.50, "meadow_lush is yellow-olive")
		_check(float(ground.get_shader_parameter("dirt_amount")) >= 0.42, "worn earth reads at gameplay zoom")
	var fog := FileAccess.get_file_as_string("res://src/GodotClient3D/Shaders/production_fog_of_war.gdshader")
	_check(fog.contains("mix(unknown_opacity, unknown * unknown_opacity, inside)"), "fog shroud is opaque off-map")
	var ground_src := FileAccess.get_file_as_string("res://src/GodotClient3D/Shaders/settlement_ground.gdshader")
	_check(ground_src.contains("0.090, 0.149, 0.165") or ground_src.contains("#17262A"), "shore dissolves into the wilderness shroud")
	var wheat := FileAccess.get_file_as_string("res://src/GodotClient3D/Scripts/production_building_view_3d.gd")
	_check(wheat.contains("_tint_wheat") and wheat.contains("#C9A24A"), "wheat crops force ripe gold")
	var showcase := Showcase.apply(game.simulation_host.simulation)
	_check(bool(showcase.get("ok", false)), "showcase still stamps")
	game._sync_presentation()
	sim_night_check(game)
	game.queue_free()
	await process_frame


func sim_night_check(game) -> void:
	var sim = game.simulation_host.simulation
	sim.is_night = true
	sim.phase_time = 20.0
	game._update_day_night_lighting()
	_check(game.sun_light.light_energy >= 0.40 and game.sun_light.light_energy <= 0.55, "live night moon is readable")
	_check(game.environment_resource.ambient_light_energy >= 0.28 and game.environment_resource.ambient_light_energy <= 0.42, "live night ambient is lifted")


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
