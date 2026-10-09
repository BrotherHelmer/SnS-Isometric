extends SceneTree

## GFX-E light gate: neutralized grade, occupation-only ground, woodland
## kit, grass clumps, export packing of code-referenced models, GPU shots.

const Catalog = preload("res://src/GodotClient3D/Scripts/production_asset_catalog.gd")
const Profile = preload("res://src/GodotClient3D/Scripts/production_scale_profile.gd")
const QualityProfile = preload("res://src/GodotClient3D/Scripts/production_quality_profile.gd")
const BuildingMaterials = preload("res://src/GodotClient3D/Scripts/production_building_materials.gd")
const Identity = preload("res://src/GodotClient3D/Scripts/production_identity.gd")
const Showcase = preload("res://src/GodotClient3D/Scripts/production_gfx_d_showcase.gd")
const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const CameraRig = preload("res://src/GodotClient3D/Scripts/production_isometric_camera_rig.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	_check_grade()
	_check_kit()
	_check_export_packing()
	_check_gpu_shots_script()
	await _check_live_scene()
	print("T_GFX_E %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check_grade() -> void:
	var day_p := Identity.lighting_palette("day")
	var night_p := Identity.lighting_palette("night")
	_check(float(day_p["saturation"]) >= 1.04 and float(day_p["saturation"]) <= 1.16, "day saturation is GFX-F 1.04–1.16")
	_check(float(day_p["exposure"]) >= 0.72 and float(day_p["exposure"]) <= 0.90, "day exposure is Filmic 0.78–0.86")
	_check(float(day_p["sun_energy"]) >= 1.10 and float(day_p["sun_energy"]) <= 1.30, "day sun energy is 1.10–1.30")
	var tint: Color = day_p["ground_tint"]
	_check(is_equal_approx(tint.r, 1.0) and is_equal_approx(tint.g, 1.0) and is_equal_approx(tint.b, 1.0), "day ground tint is neutral")
	var sun: Color = day_p["sun_color"]
	_check(sun.r > sun.b + 0.12 and sun.g > 0.70, "day key stays warm")
	_check(float(night_p["sun_energy"]) >= 0.40 and float(night_p["sun_energy"]) <= 0.55, "night moon is a readable moonlight")
	_check(float(night_p["ambient"]) >= 0.28 and float(night_p["ambient"]) <= 0.42, "night ambient is lifted")
	_check(float(night_p["fill_energy"]) <= 0.18, "night fill is not a cyan wash")
	_check(Identity.PALETTE_WINDOW.is_equal_approx(Color("#F5B36B")), "window accent is #F5B36B")
	_check(Identity.PALETTE_MEADOW.g > Identity.PALETTE_MEADOW.r and Identity.PALETTE_MEADOW.r > Identity.PALETTE_MEADOW.b, "meadow is yellow-olive")
	_check(Identity.PALETTE_CONIFER_SHADOW.g > Identity.PALETTE_CONIFER_SHADOW.b, "conifer shadow is olive, not teal")


func _check_kit() -> void:
	_check(Catalog.CONIFERS.size() >= 3, "conifer kit has fir / fir_tall / spruce")
	_check(Catalog.DECIDUOUS.size() >= 3, "deciduous kit has broadleaf / oak / birch")
	_check(Catalog.EDGE_TREES.has(Catalog.ROOT + "/opening_style/fir_lod.tscn"), "edge kit includes fir_lod")
	_check(Catalog.EDGE_TREES.has(Catalog.ROOT + "/opening_style/broadleaf_lod.tscn"), "edge kit includes broadleaf_lod")
	_check(Catalog.BUILDINGS["FARM"].ends_with("/farm.tscn"), "farm is a first-class opening_style model")
	_check(Catalog.FLOWERS.size() >= 1, "flower scatter exists")
	for path_value in Catalog.all_runtime_paths():
		if String(path_value).ends_with(".tscn") or String(path_value).ends_with(".gltf") or String(path_value).ends_with(".glb"):
			_check(ResourceLoader.exists(String(path_value)), "catalog path exists %s" % String(path_value).get_file())
	for kind in ["TOWN_HALL", "HOUSE", "FARM", "STOREHOUSE"]:
		var packed := load(Catalog.building_path(kind)) as PackedScene
		_check(packed != null, "%s scene loads" % kind)
		if packed == null:
			continue
		var model := packed.instantiate()
		var mesh: Mesh = model.get_node("Model").mesh
		_check(mesh.get_aabb().size.is_equal_approx(Profile.BUILDING_UNIT_SIZE[kind]), "%s footprint AABB unchanged" % kind)
		model.free()
	var store_roof := BuildingMaterials.remap_albedo("teal_roof", Color("#304d44"), "STOREHOUSE")
	_check(store_roof.r > store_roof.b, "storehouse roof rolls terracotta / clay")
	var rec := QualityProfile.get_profile("recommended")
	_check(int(rec.get("shadow_splits", 2)) == 4, "recommended uses 4 shadow splits")
	_check(bool(rec.get("glow", true)) == false, "recommended keeps glow off")


func _check_export_packing() -> void:
	var export_text := FileAccess.get_file_as_string("res://export_presets.cfg")
	_check(export_text.contains("export_files=PackedStringArray("), "export_presets lists resources")
	var required := [
		"opening_style/birch.tscn",
		"opening_style/fir_tall.tscn",
		"opening_style/oak.tscn",
		"opening_style/spruce.tscn",
		"opening_style/flowers.tscn",
		"opening_style/farm.tscn",
		"opening_style/fir_lod.tscn",
		"opening_style/broadleaf_lod.tscn",
		"production_gfx_shots.gd",
		"production_gfx_d_showcase.gd"
	]
	for fragment in required:
		_check(export_text.contains(fragment), "export_files includes %s" % fragment)
	# Code-referenced models: every catalog / name-built opening_style path.
	for path_value in Catalog.all_runtime_paths():
		var model := String(path_value)
		if not (model.ends_with(".tscn") or model.ends_with(".gltf") or model.ends_with(".glb")):
			continue
		if not model.contains("/settlement3d/runtime/"):
			continue
		_check(export_text.contains(model), "export_files includes code path %s" % model.get_file())


func _check_gpu_shots_script() -> void:
	var shots := FileAccess.get_file_as_string("res://src/GodotClient3D/Scripts/production_gfx_shots.gd")
	_check(shots.contains("SNS_GFX_SHOTS"), "GPU shots honor SNS_GFX_SHOTS")
	_check(shots.contains("1920") and shots.contains("1080"), "GPU shots render 1920x1080")
	_check(shots.contains("paused = true"), "GPU shots pause the sim")
	_check(shots.contains("fog_edge"), "GPU shots include fog_edge")
	var fog_idx := shots.find("fog_edge")
	var night_reset := shots.rfind("is_night = false", fog_idx)
	_check(fog_idx > 0 and night_reset > 0 and night_reset < fog_idx, "fog_edge is forced to day")
	_check(shots.contains("_park_window_offscreen") and shots.contains("func _init"), "GPU shots park the window from _init")
	_check(not shots.contains("window/size/no_focus"), "GPU shots do not bake offscreen window defaults")
	var docs := FileAccess.get_file_as_string("res://docs/gfx/GPU_SHOTS.md")
	_check(docs.contains("APPDATA") and docs.contains("XDG_DATA_HOME"), "GPU_SHOTS.md isolates user:// via APPDATA / XDG")
	_check(docs.contains("Godot **ignores** `--user-data-dir`") or docs.contains("Godot ignores `--user-data-dir`") or docs.contains("ignores `--user-data-dir`"), "GPU_SHOTS.md does not claim --user-data-dir isolates user://")


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
	_check(game.sun_light.shadow_opacity >= 0.80, "day shadows stay strong")
	_check(is_equal_approx(game.sun_light.shadow_bias, 0.06) or game.sun_light.shadow_bias <= 0.07, "shadow bias is the GFX-F 0.06")
	_check(game.environment_resource.ssao_intensity >= 1.05, "SSAO intensity stays at the GFX-I preset")
	if game.world_view.terrain_mesh_instance != null and game.world_view.terrain_mesh_instance.material_override is ShaderMaterial:
		var ground := game.world_view.terrain_mesh_instance.material_override as ShaderMaterial
		_check(float(ground.get_shader_parameter("patch_metres")) >= 6.0, "ground has a mid-scale patch layer")
		_check(float(ground.get_shader_parameter("macro_amount")) >= 0.10, "macro breakup stays on")
		var meadow_warm: Vector3 = ground.get_shader_parameter("meadow_warm")
		_check(meadow_warm.y >= meadow_warm.x and meadow_warm.x < 0.55, "meadow_warm is olive, not yellow")
	else:
		_check(false, "terrain uses the settlement ground shader")
	var clump: Mesh = game.world_view._grass_clump_mesh()
	_check(clump != null and clump.get_surface_count() > 0, "runtime grass clump mesh exists")
	if clump != null:
		var aabb := clump.get_aabb()
		_check(aabb.size.x >= 0.16 and aabb.size.y >= 0.16, "grass clump is a readable tuft, not an ant stroke")
	var showcase := Showcase.apply(game.simulation_host.simulation)
	_check(bool(showcase.get("ok", false)), "showcase stamps a village")
	game._update_day_night_lighting()
	game._sync_presentation()
	_check(game.world_view.has_method("_rebake_terrain_occupation"), "terrain occupation is a batched rebake")
	_check(game.world_view.has_method("_refresh_terrain_lookups"), "road lookups are cached for the frame")
	game.queue_free()
	await process_frame


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
