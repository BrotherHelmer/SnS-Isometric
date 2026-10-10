extends SceneTree

## GFX-P light gate: hide the creek wedge, wear the roads, force civic
## limestone on camera, meadow richness, back-ridge composition.

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
	print("T_GFX_P %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check_grade() -> void:
	var day_p := Identity.lighting_palette("day")
	_check(float(day_p["saturation"]) >= 1.10 and float(day_p["saturation"]) <= 1.16, "day sat stays frozen at 1.12")
	_check(float(day_p["contrast"]) >= 1.10 and float(day_p["contrast"]) <= 1.16, "day contrast stays frozen at 1.12")
	_check(float(day_p["exposure"]) >= 0.82 and float(day_p["exposure"]) <= 0.90, "day exposure stays frozen at 0.86")
	_check(Identity.PALETTE_LIMESTONE.is_equal_approx(Color("#CDBFA2")), "limestone is #CDBFA2")
	_check(Identity.PALETTE_PLASTER.is_equal_approx(Color("#E0D0B2")), "plaster is #E0D0B2")
	_check(Identity.PALETTE_TIMBER.is_equal_approx(Color("#5F442F")), "timber is #5F442F")
	_check(Identity.PALETTE_TEAL.is_equal_approx(Color("#456B68")), "slate is #456B68")
	_check(Identity.PALETTE_MEADOW.is_equal_approx(Color("#536C3F")), "meadow identity is #536C3F")
	_check(Identity.PALETTE_ROAD_CLAY.is_equal_approx(Color("#9F805B")), "road clay is #9F805B")
	_check(Identity.PALETTE_FOG_UNKNOWN.is_equal_approx(Color("#17272A")), "shroud colour is #17272A")


func _check_assets() -> void:
	_check(Catalog.building_path("TOWN_HALL").contains("building_castle_green") or Catalog.building_path("TOWN_HALL").contains("civic_keep"), "Town Hall keeps a civic castle mesh")
	_check(Catalog.building_path("HOUSE").contains("building_home_A_green"), "house keeps the KayKit home mesh")
	_check(Catalog.building_path("LUMBER_CAMP").contains("building_lumbermill_green"), "workshop keeps the KayKit mill mesh")
	_check(FileAccess.file_exists(Catalog.TERRAIN_TEXTURES["meadow"]), "meadow texture system stays")
	_check(BuildingMaterials.CASTLE_LIMESTONE.is_equal_approx(Color("#CDBFA2")), "castle limestone is #CDBFA2")
	_check(BuildingMaterials.WARM_PLASTER.is_equal_approx(Color("#E0D0B2")), "castle plaster is #E0D0B2")
	_check(BuildingMaterials.CASTLE_MASONRY.is_equal_approx(Color("#82796A")), "castle masonry is #82796A")
	_check(BuildingMaterials.DARK_TIMBER.is_equal_approx(Color("#5F442F")), "timber is #5F442F")
	_check(BuildingMaterials.HALL_SLATE.g > BuildingMaterials.HALL_SLATE.r and BuildingMaterials.HALL_SLATE.r < 0.40, "civic roofs are muted teal, not emerald")
	_check(BuildingMaterials.CLAY_ROOF.r > BuildingMaterials.CLAY_ROOF.g, "house roofs stay terracotta")
	var licenses := FileAccess.get_file_as_string("res://docs/ASSET_LICENSES.md")
	_check(licenses.contains("GFX-P") or licenses.contains("worn path"), "licences record the GFX-P worn-path / civic remap")
	_check(licenses.contains("distance-field") or licenses.contains("GFX-O"), "licences still record the distance mask")
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
		_check(absf(lush.x - 0.325) < 0.02 and lush.y > lush.x, "meadow albedo is #536C3F")
		var shade: Vector3 = ground.get_shader_parameter("meadow_shade")
		_check(absf(shade.x - 0.251) < 0.02 and shade.y > shade.x, "meadow shade is #405A36")
		var road_e: Vector3 = ground.get_shader_parameter("road_earth")
		_check(absf(road_e.x - 0.624) < 0.03 and road_e.x > road_e.y, "road earth is #9F805B")
		_check(float(ground.get_shader_parameter("tex_mix")) >= 0.12 and float(ground.get_shader_parameter("tex_mix")) <= 0.18, "tex_mix stays 0.12–0.18")
		_check(game.world_view.road_control_texture != null, "512 road-control texture is bound")
		game.world_view.set_terrain_debug(1)
		_check(is_equal_approx(float(ground.get_shader_parameter("terrain_debug")), 1.0), "debug 1 is magenta")
		game.world_view.set_terrain_debug(0)
	else:
		_check(false, "terrain uses the settlement ground shader")
	var ground_src := FileAccess.get_file_as_string("res://src/GodotClient3D/Shaders/settlement_ground.gdshader")
	_check(not ground_src.contains("return;"), "fragment has no early return (Godot rejects it)")
	_check(ground_src.contains("COLOR.r > COLOR.g") and ground_src.contains("terrain_debug"), "occupy no longer treats dropped-alpha grass as dirt")
	_check(ground_src.contains("source_color") and ground_src.contains("hint_default_black"), "albedo maps use source_color; the road mask does not")
	_check(ground_src.contains("smoothstep(0.12, 0.80, worn)") or ground_src.contains("edge_noise"), "roads wear the distance-field edge")
	_check(ground_src.contains("9F805B") or ground_src.contains("0.624, 0.502, 0.357"), "worn centre is #9F805B")
	var dark_disks := 0
	if game.world_view.ground_patch_root != null:
		for child in game.world_view.ground_patch_root.get_children():
			var name := String(child.name)
			if name.contains("dark_grass") or name.contains("cluster"):
				dark_disks += 1
	_check(dark_disks == 0, "flat dark-green cylinder patches stay gone")
	var dress: Node = game.world_view.resource_visuals_root.get_node_or_null("OpeningDress")
	_check(dress != null, "opening dress exists")
	if dress != null:
		var clearing := float(dress.get_meta("opening_clearing_cells", 0.0))
		_check(clearing >= 10.5 and clearing <= 12.5, "opening clearing stays 2.5–3 Town Hall widths")
		var coverage := float(dress.get_meta("opening_forest_coverage", 0.0))
		_check(coverage >= 0.38 and coverage <= 0.58, "forest covers 40–55% of the perimeter")
		_check(dress.find_child("DressRidge", true, false) != null, "opening has a ridge")
		_check(dress.find_child("DressCreek", true, false) != null, "opening has a creek")
		_check(dress.find_child("RidgeFormation", true, false) != null, "opening has one back rock formation")
	var creek: Node = dress.find_child("DressCreek", true, false) if dress != null else null
	if creek is MeshInstance3D:
		var water_mat := (creek as MeshInstance3D).material_override as StandardMaterial3D
		_check(water_mat != null and (water_mat.albedo_color.is_equal_approx(Color("#345F65")) or water_mat.albedo_color.is_equal_approx(Color("#2F7A7E"))), "creek water stays readable teal")
		_check(water_mat != null and water_mat.roughness >= 0.18 and water_mat.roughness <= 0.38, "creek roughness stays wet")
		_check(water_mat != null and not water_mat.emission_enabled, "creek has no turquoise emission wedge")
		_check(not ((creek as MeshInstance3D).mesh is PlaneMesh), "creek is a sampled ribbon, not a plane")
		var creek_aabb: AABB = (creek as MeshInstance3D).get_aabb()
		_check(creek_aabb.size.x < ScaleProfile.TOWN_HALL_WIDTH_METRES * 2.4, "creek is not a village-wide wedge")
	var formation: MeshInstance3D = dress.find_child("RidgeFormation", true, false) as MeshInstance3D if dress != null else null
	if formation != null and formation.mesh != null:
		var form_aabb: AABB = formation.mesh.get_aabb()
		var b := ScaleProfile.TOWN_HALL_WIDTH_METRES
		_check(form_aabb.size.x >= b * 1.40 and form_aabb.size.x <= b * 2.20, "back formation is 1.5–2.0B wide")
		_check(form_aabb.size.y >= b * 0.36 and form_aabb.size.y <= b * 0.75, "back formation is 0.4–0.7B tall")
	var road_src := FileAccess.get_file_as_string("res://src/GodotClient3D/Scripts/production_road_view_3d.gd")
	_check(road_src.contains("#9F805B"), "raised road meshes use #9F805B")
	var kaykit := FileAccess.get_file_as_string("res://src/GodotClient3D/Shaders/settlement_kaykit_remap.gdshader")
	_check(kaykit.contains("IGNORE") and kaykit.contains("CDBFA2"), "civic remap ignores the green atlas")
	_check(kaykit.contains("456B68") and kaykit.contains("5F442F"), "civic roof / timber match the P palette")
	var world_src := FileAccess.get_file_as_string("res://src/GodotClient3D/Scripts/production_world_view_3d.gd")
	_check(world_src.contains("_stamp_segment_distance") and world_src.contains("_collect_road_segments"), "roads keep the world-space distance field")
	_check(world_src.contains("(-5, -2)") or world_src.contains("Vector2i(-5, -2)"), "creek starts west of the hamlet, not across the village")
	var showcase := Showcase.apply(game.simulation_host.simulation)
	_check(bool(showcase.get("ok", false)), "showcase still stamps")
	_check(int(showcase.get("roads", 0)) >= 12, "showcase stamps a connected road network")
	game._sync_presentation()
	_check(game.world_view.road_control_texture != null, "road control rebakes after showcase")
	await _check_castle_on_camera(game)
	game.queue_free()
	await process_frame


func _check_castle_on_camera(game: Node) -> void:
	var sim = game.simulation_host.simulation
	sim.is_night = false
	sim.phase_time = 80.0
	game._update_day_night_lighting()
	game._sync_presentation()
	var home: Vector3 = game.world_view.tile_to_world(Vector2(sim.town_hall_position) + Vector2(1.5, 1.5))
	game.camera_rig.compose_view(home, 34.0)
	for _i in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_viewport().get_texture().get_image()
	_check(image != null and not image.is_empty(), "gameplay-camera castle frame exists")
	if image == null or image.is_empty():
		return
	var ratio := _light_wall_ratio(image)
	print("GFX_P castle_light_wall_ratio=%.3f" % ratio)
	_check(ratio >= 0.50, "castle light wall area is at least 50%% on the gameplay camera (%.0f%%)" % (ratio * 100.0))


func _light_wall_ratio(image: Image) -> float:
	# Centre-upper band where the KayKit castle sits at zoom 34.
	var w := image.get_width()
	var h := image.get_height()
	var x0 := int(float(w) * 0.34)
	var x1 := int(float(w) * 0.66)
	var y0 := int(float(h) * 0.18)
	var y1 := int(float(h) * 0.58)
	var wall := 0
	var light := 0
	var y := y0
	while y < y1:
		var x := x0
		while x < x1:
			var c := image.get_pixel(x, y)
			var luma := c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
			var green := c.g > c.r + 0.04 and c.g > c.b
			var teal_roof := c.b > c.r + 0.02 and c.g > c.r and luma < 0.48
			var olive_roof := c.g >= c.r - 0.03 and c.g > c.b * 0.82 and luma < 0.52
			var meadow := c.b < 0.24 and c.r < 0.62 and luma < 0.50
			var sky := luma > 0.82 and c.b > c.r
			if not green and not teal_roof and not olive_roof and not meadow and not sky and luma > 0.16:
				wall += 1
				# Pale limestone / plaster under lavapipe lighting.
				if luma >= 0.46 and c.r >= 0.42 and c.g / maxf(c.r, 0.001) < 1.12:
					light += 1
			x += 2
		y += 2
	if wall < 40:
		return 0.0
	return float(light) / float(wall)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
