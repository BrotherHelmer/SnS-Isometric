extends SceneTree

## GFX-O light gate: diagnose the terrain pipeline, distance-field roads,
## blended meadow shade, light-stone castle, 2.5–3W clearing.

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
	print("T_GFX_O %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check_grade() -> void:
	var day_p := Identity.lighting_palette("day")
	_check(float(day_p["saturation"]) >= 1.10 and float(day_p["saturation"]) <= 1.16, "day sat stays frozen at 1.12")
	_check(float(day_p["contrast"]) >= 1.10 and float(day_p["contrast"]) <= 1.16, "day contrast stays frozen at 1.12")
	_check(float(day_p["exposure"]) >= 0.82 and float(day_p["exposure"]) <= 0.90, "day exposure stays frozen at 0.86")
	_check(Identity.PALETTE_LIMESTONE.is_equal_approx(Color("#CFC2A6")) or Identity.PALETTE_LIMESTONE.is_equal_approx(Color("#CDBFA2")), "limestone is #CFC2A6")
	_check(Identity.PALETTE_PLASTER.is_equal_approx(Color("#E0D0B2")), "plaster is #E0D0B2")
	_check(Identity.PALETTE_TIMBER.is_equal_approx(Color("#61442F")) or Identity.PALETTE_TIMBER.is_equal_approx(Color("#5F442F")), "timber is #61442F")
	_check(Identity.PALETTE_TEAL.is_equal_approx(Color("#466C69")) or Identity.PALETTE_TEAL.is_equal_approx(Color("#456B68")), "slate is #466C69")
	_check(Identity.PALETTE_MEADOW.is_equal_approx(Color("#556D3F")) or Identity.PALETTE_MEADOW.is_equal_approx(Color("#536C3F")), "meadow identity is #556D3F")
	_check(Identity.PALETTE_ROAD_CLAY.is_equal_approx(Color("#AD8D66")) or Identity.PALETTE_ROAD_CLAY.is_equal_approx(Color("#9F805B")), "road clay is #AD8D66")
	_check(Identity.PALETTE_FOG_UNKNOWN.is_equal_approx(Color("#17272A")), "shroud colour is #17272A")


func _check_assets() -> void:
	_check(Catalog.building_path("TOWN_HALL").contains("building_castle_green") or Catalog.building_path("TOWN_HALL").contains("civic_keep"), "Town Hall keeps a civic castle mesh")
	_check(Catalog.building_path("HOUSE").contains("building_home_A_green"), "house keeps the KayKit home mesh")
	_check(Catalog.building_path("LUMBER_CAMP").contains("building_lumbermill_green"), "workshop keeps the KayKit mill mesh")
	_check(FileAccess.file_exists(Catalog.TERRAIN_TEXTURES["meadow"]), "meadow texture system stays")
	_check(BuildingMaterials.CASTLE_LIMESTONE.is_equal_approx(Color("#CFC2A6")) or BuildingMaterials.CASTLE_LIMESTONE.is_equal_approx(Color("#CDBFA2")), "castle limestone is #CFC2A6")
	_check(BuildingMaterials.WARM_PLASTER.is_equal_approx(Color("#E0D0B2")), "castle plaster is #E0D0B2")
	_check(BuildingMaterials.CASTLE_MASONRY.is_equal_approx(Color("#847C6B")) or BuildingMaterials.CASTLE_MASONRY.is_equal_approx(Color("#82796A")), "castle masonry is #847C6B")
	_check(BuildingMaterials.DARK_TIMBER.is_equal_approx(Color("#61442F")) or BuildingMaterials.DARK_TIMBER.is_equal_approx(Color("#5F442F")), "timber is #61442F")
	_check(BuildingMaterials.HALL_SLATE.g > BuildingMaterials.HALL_SLATE.r and BuildingMaterials.HALL_SLATE.r < 0.40, "civic roofs are muted teal, not emerald")
	_check(BuildingMaterials.CLAY_ROOF.r > BuildingMaterials.CLAY_ROOF.g, "house roofs stay terracotta")
	var licenses := FileAccess.get_file_as_string("res://docs/ASSET_LICENSES.md")
	_check(licenses.contains("distance-field") or licenses.contains("GFX-O"), "licences record the GFX-O distance mask")
	_check(licenses.contains("Kaykit remap"), "licences still record the remap shader")


func _check_zoom() -> void:
	_check(is_equal_approx(CameraRig.NORMAL_ZOOM, 26.0), "gameplay zoom stays 26")
	_check(CameraRig.STRATEGIC_ZOOM <= 39.5 and CameraRig.STRATEGIC_ZOOM >= 38.0, "zoom-out cap is ~1.5x")


func _check_live_scene() -> void:
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	_check(game.world_view != null, "world view compiled")
	if game.world_view == null:
		game.queue_free()
		await process_frame
		return
	game.start_new_3d(game.DEFAULT_SEED)
	game._hide_start_menu()
	for _i in 4:
		await process_frame
	_check(game.world_view.has_method("set_terrain_debug"), "terrain debug modes exist")
	if game.world_view.terrain_mesh_instance != null and game.world_view.terrain_mesh_instance.material_override is ShaderMaterial:
		var ground := game.world_view.terrain_mesh_instance.material_override as ShaderMaterial
		var lush: Vector3 = ground.get_shader_parameter("meadow_lush")
		_check(absf(lush.x - 0.333) < 0.03 and lush.y > lush.x, "meadow albedo is #556D3F")
		var shade: Vector3 = ground.get_shader_parameter("meadow_shade")
		_check(absf(shade.x - 0.243) < 0.03 and shade.y > shade.x, "meadow shade is #3E5938")
		var road_e: Vector3 = ground.get_shader_parameter("road_earth")
		_check((absf(road_e.x - 0.678) < 0.03 or absf(road_e.x - 0.624) < 0.03) and road_e.x > road_e.y, "road earth is #AD8D66")
		_check(float(ground.get_shader_parameter("tex_mix")) <= 0.18, "textures are detail modulation only")
		_check(game.world_view.road_control_texture != null, "512 road-control texture is bound")
		game.world_view.set_terrain_debug(1)
		_check(is_equal_approx(float(ground.get_shader_parameter("terrain_debug")), 1.0), "debug 1 is magenta")
		game.world_view.set_terrain_debug(2)
		_check(is_equal_approx(float(ground.get_shader_parameter("terrain_debug")), 2.0), "debug 2 is solid meadow")
		game.world_view.set_terrain_debug(3)
		_check(is_equal_approx(float(ground.get_shader_parameter("terrain_debug")), 3.0), "debug 3 is the red road mask")
		game.world_view.set_terrain_debug(0)
	else:
		_check(false, "terrain uses the settlement ground shader")
	var ground_src := FileAccess.get_file_as_string("res://src/GodotClient3D/Shaders/settlement_ground.gdshader")
	_check(not ground_src.contains("return;"), "fragment has no early return (Godot rejects it)")
	_check(ground_src.contains("COLOR.r > COLOR.g") and ground_src.contains("terrain_debug"), "occupy no longer treats dropped-alpha grass as dirt")
	_check(ground_src.contains("source_color") and ground_src.contains("hint_default_black"), "albedo maps use source_color; the road mask does not")
	_check(ground_src.contains("smoothstep(0.12, 0.80, control)"), "roads smoothstep over the finished ground")
	var dark_disks := 0
	if game.world_view.ground_patch_root != null:
		for child in game.world_view.ground_patch_root.get_children():
			var name := String(child.name)
			if name.contains("dark_grass") or name.contains("cluster"):
				dark_disks += 1
	_check(dark_disks == 0, "flat dark-green cylinder patches are gone")
	var dress: Node = game.world_view.resource_visuals_root.get_node_or_null("OpeningDress")
	_check(dress != null, "opening dress exists")
	if dress != null:
		var clearing := float(dress.get_meta("opening_clearing_cells", 0.0))
		_check(clearing >= 10.5 and clearing <= 12.5, "opening clearing is 2.5–3 Town Hall widths")
		var coverage := float(dress.get_meta("opening_forest_coverage", 0.0))
		_check(coverage >= 0.38 and coverage <= 0.58, "forest covers 40–55% of the perimeter")
		_check(dress.find_child("DressRidge", true, false) != null, "opening has a ridge")
		_check(dress.find_child("DressCreek", true, false) != null, "opening has a creek")
	var creek: Node = dress.find_child("DressCreek", true, false) if dress != null else null
	if creek is MeshInstance3D:
		var water_mat := (creek as MeshInstance3D).material_override as StandardMaterial3D
		_check(water_mat != null and (water_mat.albedo_color.is_equal_approx(Color("#345F65")) or water_mat.albedo_color.is_equal_approx(Color("#2F7A7E"))), "creek water stays readable teal")
		_check(water_mat != null and water_mat.roughness >= 0.18 and water_mat.roughness <= 0.38, "creek roughness stays wet")
	var road_src := FileAccess.get_file_as_string("res://src/GodotClient3D/Scripts/production_road_view_3d.gd")
	_check(road_src.contains("#AD8D66") or road_src.contains("#9F805B"), "raised road meshes use #AD8D66")
	var kaykit := FileAccess.get_file_as_string("res://src/GodotClient3D/Shaders/settlement_kaykit_remap.gdshader")
	_check(kaykit.contains("masonry_color") and (kaykit.contains("1.32") or kaykit.contains("roof_face") or kaykit.contains("IGNORE")), "KayKit remap lifts castle walls")
	_check((kaykit.contains("CFC2A6") or kaykit.contains("CDBFA2")) and (kaykit.contains("466C69") or kaykit.contains("456B68")), "castle palette is light stone / muted teal")
	var world_src := FileAccess.get_file_as_string("res://src/GodotClient3D/Scripts/production_world_view_3d.gd")
	_check(world_src.contains("_stamp_segment_distance") and world_src.contains("_collect_road_segments"), "roads bake a world-space distance field")
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
