extends SceneTree

## GFX-H light gate: textured ground, readable roads/crops, hidden
## island edge, crisp shadows, moonlit-blue night. Day grade stays
## the GFX-G opening numbers.

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
	print("T_GFX_H %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check_grade() -> void:
	var day_p := Identity.lighting_palette("day")
	var night_p := Identity.lighting_palette("night")
	_check(float(day_p["saturation"]) >= 1.10 and float(day_p["saturation"]) <= 1.16, "day sat stays 1.12")
	_check(float(day_p["contrast"]) >= 1.10 and float(day_p["contrast"]) <= 1.16, "day contrast stays 1.12")
	_check(float(day_p["exposure"]) >= 0.82 and float(day_p["exposure"]) <= 0.90, "day exposure stays 0.86")
	_check(float(day_p["sun_energy"]) >= 1.18 and float(day_p["sun_energy"]) <= 1.28, "day sun stays ~1.24")
	_check(float(day_p["sun_pitch"]) <= -26.0 and float(day_p["sun_pitch"]) >= -32.0, "day sun pitch still lengthens shadows")
	_check(Identity.PALETTE_MEADOW.is_equal_approx(Color("#68743A")), "meadow stays yellow-olive #68743A")
	_check(Identity.PALETTE_SUNLIT_GRASS.is_equal_approx(Color("#8A9848")), "sunlit grass stays #8A9848")
	_check(Identity.PALETTE_WINDOW.is_equal_approx(Color("#F5B36B")), "window emission stays #F5B36B")
	_check(float(night_p["sun_energy"]) >= 0.38 and float(night_p["sun_energy"]) <= 0.48, "night moon energy stays 0.42")
	_check(float(night_p["ambient"]) >= 0.26 and float(night_p["ambient"]) <= 0.34, "night ambient energy stays 0.30")
	_check(float(night_p["exposure"]) >= 0.80 and float(night_p["exposure"]) <= 0.88, "night exposure stays 0.84")
	_check(float(night_p["torch_range"]) >= 7.0, "night window pools still reach the yard")
	var moon: Color = night_p["sun_color"]
	_check(moon.b > moon.g and moon.b > moon.r, "night key is moonlit blue, not green")
	var ambient: Color = night_p["ambient_color"]
	_check(ambient.b > ambient.g, "night ambient is blue, not olive")
	var tint: Color = night_p["ground_tint"]
	_check(tint.b > tint.g, "night ground tint cools the meadow")
	var fill: Color = night_p["fill_color"]
	_check(fill.b > fill.r, "night fill stays cool moonlight")


func _check_shadows() -> void:
	var rec := QualityProfile.get_profile("recommended")
	_check(int(rec.get("shadow_splits", 2)) == 4, "recommended uses 4 shadow splits")
	_check(float(rec.get("shadow_blur", 1.6)) <= 0.40, "recommended shadow blur is crisp")
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
	_check(game.sun_light.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS, "day uses 4 PSSM splits")
	_check(game.environment_resource.ssao_radius <= 0.50, "SSAO radius is tight enough to kill the smear")
	_check(game.environment_resource.ssao_intensity >= 1.40, "SSAO intensity stays at the GFX-F floor")
	_check(game.world_view.has_method("_farm_field_tiles"), "farm field splat exists")
	_check(game.world_view.has_method("_append_rim_woodland"), "rim woodland hides the island cut")
	_check(game.world_view.has_method("_spawn_dress_pond"), "opening pond exists")
	var dress: Node = game.world_view.resource_visuals_root.get_node_or_null("OpeningDress")
	_check(dress != null and dress.get_child_count() > 0, "opening has dress children")
	_check(int(dress.get_meta("hamlet_cottages", 0)) >= 3, "opening still dresses at least three cottages")
	_check(dress.find_child("DressPond", true, false) != null, "opening has a millpond")
	_check(dress.find_child("DressWheat_0_0", true, false) != null, "opening has crop rows")
	_check(dress.find_child("DressWellBarrel", true, false) != null, "opening still has a well")
	if game.world_view.terrain_mesh_instance != null and game.world_view.terrain_mesh_instance.material_override is ShaderMaterial:
		var ground := game.world_view.terrain_mesh_instance.material_override as ShaderMaterial
		var lush: Vector3 = ground.get_shader_parameter("meadow_lush")
		_check(lush.y > lush.x and lush.x >= 0.36 and lush.x < 0.50, "meadow_lush is still the yellow-olive")
		_check(float(ground.get_shader_parameter("dirt_amount")) >= 0.52, "dirt amount is 0.56")
		_check(float(ground.get_shader_parameter("crop_amount")) >= 0.90, "crop rows are enabled")
		_check(float(ground.get_shader_parameter("stone_amount")) >= 0.28, "pebbles are enabled")
		var beach: Vector3 = ground.get_shader_parameter("beach_color")
		_check(beach.x < 0.14 and beach.z >= beach.y - 0.02, "beach still matches the wilderness shroud")
	var ground_src := FileAccess.get_file_as_string("res://src/GodotClient3D/Shaders/settlement_ground.gdshader")
	_check(ground_src.contains("wheat_gold") and ground_src.contains("furrow"), "ground shader paints crop furrows")
	var road := FileAccess.get_file_as_string("res://src/GodotClient3D/Scripts/production_road_view_3d.gd")
	_check(road.contains("0.088") and road.contains("#C8A064"), "road meshes are raised packed clay")
	var fog := FileAccess.get_file_as_string("res://src/GodotClient3D/Shaders/production_fog_of_war.gdshader")
	_check(fog.contains("edge_veil * 0.78"), "fog rim tints the island cut")
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
	_check(game.environment_resource.ambient_light_energy >= 0.26, "live night ambient is 0.30")
	_check(game.environment_resource.tonemap_exposure >= 0.80, "live night exposure is 0.84")
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
