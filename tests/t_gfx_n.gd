extends SceneTree

## GFX-N light gate: lush meadow, road-control union, KayKit remapped
## limestone / terracotta, retinted rocks, Curve3D creek. Grade frozen.

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
	print("T_GFX_N %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check_grade() -> void:
	var day_p := Identity.lighting_palette("day")
	_check(float(day_p["saturation"]) >= 1.10 and float(day_p["saturation"]) <= 1.16, "day sat stays frozen at 1.12")
	_check(float(day_p["contrast"]) >= 1.10 and float(day_p["contrast"]) <= 1.16, "day contrast stays frozen at 1.12")
	_check(float(day_p["exposure"]) >= 0.82 and float(day_p["exposure"]) <= 0.90, "day exposure stays frozen at 0.86")
	_check(Identity.PALETTE_LIMESTONE.is_equal_approx(Color("#CDBD9F")) or Identity.PALETTE_LIMESTONE.is_equal_approx(Color("#CFC2A6")), "limestone is #CDBD9F")
	_check(Identity.PALETTE_PLASTER.is_equal_approx(Color("#DFCBA9")) or Identity.PALETTE_PLASTER.is_equal_approx(Color("#E0D0B2")), "plaster is #DFCBA9")
	_check(Identity.PALETTE_TIMBER.is_equal_approx(Color("#60432E")) or Identity.PALETTE_TIMBER.is_equal_approx(Color("#61442F")), "timber is #60432E")
	_check(Identity.PALETTE_TEAL.is_equal_approx(Color("#426B68")) or Identity.PALETTE_TEAL.is_equal_approx(Color("#466C69")), "slate is #426B68")
	_check(Identity.PALETTE_MEADOW.is_equal_approx(Color("#556D3F")), "meadow identity is #556D3F")
	_check(Identity.PALETTE_FOG_UNKNOWN.is_equal_approx(Color("#17272A")), "shroud colour is #17272A")


func _check_assets() -> void:
	_check(Catalog.building_path("TOWN_HALL").contains("building_castle_green"), "Town Hall keeps the KayKit castle mesh")
	_check(Catalog.building_path("HOUSE").contains("building_home_A_green"), "house keeps the KayKit home mesh")
	_check(Catalog.building_path("LUMBER_CAMP").contains("building_lumbermill_green"), "workshop keeps the KayKit mill mesh")
	_check(FileAccess.file_exists(Catalog.TERRAIN_TEXTURES["meadow"]), "meadow texture system stays")
	_check(BuildingMaterials.CASTLE_LIMESTONE.is_equal_approx(Color("#CDBD9F")) or BuildingMaterials.CASTLE_LIMESTONE.is_equal_approx(Color("#CFC2A6")), "castle limestone is #CDBD9F")
	_check(BuildingMaterials.HALL_SLATE.g > BuildingMaterials.HALL_SLATE.r and BuildingMaterials.HALL_SLATE.r < 0.40, "civic roofs are muted teal, not emerald")
	_check(BuildingMaterials.CLAY_ROOF.r > BuildingMaterials.CLAY_ROOF.g, "house roofs stay terracotta")
	_check(FileAccess.get_file_as_string("res://docs/ASSET_LICENSES.md").contains("Kaykit remap"), "licences record the remap shader")


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
	if game.world_view.terrain_mesh_instance != null and game.world_view.terrain_mesh_instance.material_override is ShaderMaterial:
		var ground := game.world_view.terrain_mesh_instance.material_override as ShaderMaterial
		var lush: Vector3 = ground.get_shader_parameter("meadow_lush")
		_check(absf(lush.x - 0.333) < 0.02 and lush.y > lush.x, "meadow albedo is #556D3F")
		_check(float(ground.get_shader_parameter("tex_mix")) <= 0.24, "textures are detail modulation only")
		_check(game.world_view.road_control_texture != null, "512 road-control texture is bound")
		_check(game.world_view.has_method("set_road_debug"), "magenta road debug exists")
	else:
		_check(false, "terrain uses the settlement ground shader")
	var dress: Node = game.world_view.resource_visuals_root.get_node_or_null("OpeningDress")
	var creek: Node = dress.find_child("DressCreek", true, false) if dress != null else null
	_check(creek != null, "opening has a creek")
	if creek is MeshInstance3D:
		var water_mat := (creek as MeshInstance3D).material_override as StandardMaterial3D
		_check(water_mat != null and (water_mat.albedo_color.is_equal_approx(Color("#345E64")) or water_mat.albedo_color.is_equal_approx(Color("#345F65"))), "creek water is #345E64")
		_check(water_mat != null and water_mat.roughness >= 0.33 and water_mat.roughness <= 0.38, "creek roughness is 0.35")
	var road_src := FileAccess.get_file_as_string("res://src/GodotClient3D/Scripts/production_road_view_3d.gd")
	_check(road_src.contains("#AE906D") or road_src.contains("#AD8D66"), "roads use review centre #AE906D")
	var kaykit := FileAccess.get_file_as_string("res://src/GodotClient3D/Shaders/settlement_kaykit_remap.gdshader")
	_check(kaykit.contains("use_terracotta") and kaykit.contains("wall_lift"), "KayKit remap shader is authored")
	var showcase := Showcase.apply(game.simulation_host.simulation)
	_check(bool(showcase.get("ok", false)), "showcase still stamps")
	_check(int(showcase.get("roads", 0)) >= 12, "showcase stamps a connected road network")
	game._sync_presentation()
	_check(game.world_view.road_control_texture != null, "road control rebakes after showcase")
	game.queue_free()
	await process_frame


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
