extends SceneTree

## GFX-G light gate: readable night, yellow-olive meadow, hamlet dress,
## dirt/paths, fog-dissolved island edge.

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
	print("T_GFX_G %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check_grade() -> void:
	var day_p := Identity.lighting_palette("day")
	var night_p := Identity.lighting_palette("night")
	_check(float(day_p["saturation"]) >= 1.10 and float(day_p["saturation"]) <= 1.16, "day sat is 1.12")
	_check(float(day_p["contrast"]) >= 1.10 and float(day_p["contrast"]) <= 1.16, "day contrast is 1.12")
	_check(float(day_p["exposure"]) >= 0.82 and float(day_p["exposure"]) <= 0.90, "day exposure is 0.86")
	_check(float(day_p["sun_energy"]) >= 1.05 and float(day_p["sun_energy"]) <= 1.28, "day sun is 1.10–1.24")
	_check(float(day_p["sun_pitch"]) <= -26.0 and float(day_p["sun_pitch"]) >= -40.0, "day sun pitch lengthens shadows")
	_check(float(day_p["ambient"]) >= 0.22 and float(day_p["ambient"]) <= 0.42, "day ambient stays in the late-afternoon band")
	var sun: Color = day_p["sun_color"]
	_check(sun.is_equal_approx(Color("#FFE8CE")) or sun.is_equal_approx(Color("#FFF0DE")) or sun.is_equal_approx(Color("#FFD2A0")), "day key stays warm cream")
	_check(Identity.PALETTE_MEADOW.is_equal_approx(Color("#68743A")) or Identity.PALETTE_MEADOW.is_equal_approx(Color("#556D3F")) or Identity.PALETTE_MEADOW.is_equal_approx(Color("#536C3F")), "meadow is yellow-olive #68743A")
	_check(Identity.PALETTE_SUNLIT_GRASS.is_equal_approx(Color("#8A9848")), "sunlit grass is #8A9848")
	_check(Identity.PALETTE_FOREST.r > Identity.PALETTE_FOREST.b, "forest is olive, not teal")
	_check(Identity.PALETTE_WINDOW.is_equal_approx(Color("#F5B36B")), "window emission is #F5B36B")
	_check(float(night_p["sun_energy"]) >= 0.38 and float(night_p["sun_energy"]) <= 0.48, "night moon is 0.42")
	_check(float(night_p["ambient"]) >= 0.26 and float(night_p["ambient"]) <= 0.34, "night ambient is 0.30")
	_check(float(night_p["exposure"]) >= 0.80 and float(night_p["exposure"]) <= 0.88, "night exposure is 0.84")
	_check(float(night_p["atmosphere_scale"]) >= 0.55, "night atmosphere is lifted")
	_check(float(night_p["torch_range"]) >= 7.0, "night window pools reach the yard")
	var moon: Color = night_p["sun_color"]
	_check(moon.b > moon.r, "night key stays cool moonlight")
	var fill: Color = day_p["fill_color"]
	_check(fill.b > fill.r, "cool fill against the warm key")


func _check_shadows() -> void:
	var rec := QualityProfile.get_profile("recommended")
	_check(int(rec.get("shadow_splits", 2)) == 4, "recommended uses 4 shadow splits")
	_check(float(rec.get("shadow_blur", 1.6)) <= 1.10, "recommended shadow blur stays in the GFX-I band")
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
	_check(game.world_view.has_method("_rebuild_opening_dressing"), "opening dress exists")
	_check(game.world_view.has_method("_spawn_opening_hamlet"), "opening hamlet spawn exists")
	var dress: Node = game.world_view.resource_visuals_root.get_node_or_null("OpeningDress")
	_check(dress != null and dress.get_child_count() > 0, "opening has dress children")
	var cottages := 0
	if dress != null:
		cottages = int(dress.get_meta("hamlet_cottages", 0))
		for child in dress.get_children():
			if String(child.name).begins_with("Dress_HOUSE") or String(child.name).begins_with("Dress_BAKERY"):
				cottages = maxi(cottages, 1)
	_check(int(dress.get_meta("hamlet_cottages", 0)) >= 3, "opening dresses at least three cottages")
	_check(dress.find_child("DressWellBarrel", true, false) != null, "opening has a well")
	_check(dress.find_child("DressCart", true, false) != null, "opening has a cart")
	_check(dress.find_child("DressWoodNorth", true, false) != null or dress.find_child("DressWoodSouth", true, false) != null, "opening has stacked wood")
	if game.world_view.terrain_mesh_instance != null and game.world_view.terrain_mesh_instance.material_override is ShaderMaterial:
		var ground := game.world_view.terrain_mesh_instance.material_override as ShaderMaterial
		var lush: Vector3 = ground.get_shader_parameter("meadow_lush")
		_check(lush.y > lush.x and lush.x >= 0.18 and lush.x < 0.50, "meadow_lush is the GFX-G yellow-olive")
		_check(float(ground.get_shader_parameter("dirt_amount")) >= 0.44, "dirt amount is 0.48")
		var beach: Vector3 = ground.get_shader_parameter("beach_color")
		_check(beach.x < 0.14 and beach.z >= beach.y - 0.02, "beach matches the wilderness shroud")
	var foliage := FileAccess.get_file_as_string("res://src/GodotClient3D/Scripts/production_world_view_3d.gd")
	_check(not foliage.contains("Color(\"#15281E\")"), "conifer tint is no longer teal-black")
	var building := FileAccess.get_file_as_string("res://src/GodotClient3D/Scripts/production_building_view_3d.gd")
	_check(building.contains("clampf(torch_range, 3.2, 9.0)"), "window pools are unclamped to 9 m")
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
	var dress: Node = game.world_view.resource_visuals_root.get_node_or_null("OpeningDress")
	if dress != null:
		var window: OmniLight3D = dress.find_child("DressWindow", true, false) as OmniLight3D
		_check(window != null and window.visible, "hamlet windows glow at night")


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
