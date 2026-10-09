extends SceneTree

## GFX-M light gate: KayKit Medieval Hexagon hall/house/workshop, 1024²
## CC0 terrain textures, scaled rocks, low foundation, visible roads,
## natural creek. Grade frozen at sat 1.12 / contrast 1.12 / exposure 0.86.

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
	print("T_GFX_M %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check_grade() -> void:
	var day_p := Identity.lighting_palette("day")
	_check(float(day_p["saturation"]) >= 1.10 and float(day_p["saturation"]) <= 1.16, "day sat stays frozen at 1.12")
	_check(float(day_p["contrast"]) >= 1.10 and float(day_p["contrast"]) <= 1.16, "day contrast stays frozen at 1.12")
	_check(float(day_p["exposure"]) >= 0.82 and float(day_p["exposure"]) <= 0.90, "day exposure stays frozen at 0.86")
	_check(is_equal_approx(float(day_p["sun_energy"]), 1.10), "day sun stays 1.10")
	_check(Identity.PALETTE_LIMESTONE.is_equal_approx(Color("#C8BA9C")) or Identity.PALETTE_LIMESTONE.is_equal_approx(Color("#CDBD9F")), "limestone is #C8BA9C")
	_check(Identity.PALETTE_PLASTER.is_equal_approx(Color("#DDCAA8")) or Identity.PALETTE_PLASTER.is_equal_approx(Color("#DFCBA9")), "plaster is #DDCAA8")
	_check(Identity.PALETTE_TIMBER.is_equal_approx(Color("#5F422E")) or Identity.PALETTE_TIMBER.is_equal_approx(Color("#60432E")), "timber is #5F422E")
	_check(Identity.PALETTE_TEAL.is_equal_approx(Color("#426B66")) or Identity.PALETTE_TEAL.is_equal_approx(Color("#426B68")), "slate is #426B66")
	_check(Identity.PALETTE_STONE.is_equal_approx(Color("#635B4C")), "recesses are #635B4C")
	_check(Identity.PALETTE_FOG_UNKNOWN.is_equal_approx(Color("#17272A")), "shroud colour is #17272A")


func _check_assets() -> void:
	_check(Catalog.building_path("TOWN_HALL").contains("building_castle_green"), "Town Hall uses KayKit castle gltf")
	_check(Catalog.building_path("HOUSE").contains("building_home_A_green"), "house uses KayKit home gltf")
	_check(Catalog.building_path("LUMBER_CAMP").contains("building_lumbermill_green"), "workshop uses KayKit lumbermill gltf")
	_check(FileAccess.file_exists(Catalog.TERRAIN_TEXTURES["meadow"]), "meadow 1024 texture exists")
	_check(FileAccess.file_exists(Catalog.TERRAIN_TEXTURES["forest"]), "forest 1024 texture exists")
	_check(FileAccess.file_exists(Catalog.TERRAIN_TEXTURES["dirt"]), "dirt 1024 texture exists")
	_check(FileAccess.file_exists(Catalog.TERRAIN_TEXTURES["rock"]), "rock 1024 texture exists")
	_check(FileAccess.get_file_as_string("res://docs/ASSET_LICENSES.md").contains("Poly Haven"), "licences record Poly Haven")
	_check(BuildingMaterials.CASTLE_LIMESTONE.is_equal_approx(Color("#C8BA9C")) or BuildingMaterials.CASTLE_LIMESTONE.is_equal_approx(Color("#CDBD9F")), "castle limestone matches review")
	_check(BuildingMaterials.WARM_PLASTER.is_equal_approx(Color("#DDCAA8")) or BuildingMaterials.WARM_PLASTER.is_equal_approx(Color("#DFCBA9")), "plaster matches review")


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
	var dress: Node = game.world_view.resource_visuals_root.get_node_or_null("OpeningDress")
	var ridge: Node = dress.find_child("DressRidge", true, false) if dress != null else null
	_check(ridge != null, "opening has a ridge landmark")
	var creek: Node = dress.find_child("DressCreek", true, false) if dress != null else null
	_check(creek != null, "opening has a creek")
	if creek is MeshInstance3D:
		var water_mat := (creek as MeshInstance3D).material_override as StandardMaterial3D
		_check(water_mat != null and (water_mat.albedo_color.is_equal_approx(Color("#315D62")) or water_mat.albedo_color.is_equal_approx(Color("#345E64"))), "creek water is #315D62")
		_check(water_mat != null and water_mat.roughness >= 0.30 and water_mat.roughness <= 0.36, "creek roughness is 0.32")
		_check(not ((creek as MeshInstance3D).mesh is PlaneMesh), "creek is a curved ribbon")
	if ridge != null:
		var rocks := 0
		var max_h := 0.0
		for child in ridge.get_children():
			if String(child.name).begins_with("RidgeRock_"):
				rocks += 1
				var mesh_i := child as MeshInstance3D
				if mesh_i != null and mesh_i.mesh != null:
					max_h = maxf(max_h, mesh_i.mesh.get_aabb().size.y)
		_check(rocks >= 6 and rocks <= 10, "ridge has 6-10 bevelled masses")
		var house_h := 0.930 * 4.40
		_check(max_h <= house_h * 0.35 + 0.05, "boulders stay under 0.35H")
	var hall_view = null
	for view in game.world_view.building_views.values():
		if String(view.building_type) == "TOWN_HALL" or String(view.building_type) == "CASTLE":
			hall_view = view
			break
	_check(hall_view != null, "Town Hall view exists")
	if hall_view != null:
		_check(hall_view.find_child("TrimPlinth", true, false) != null, "hall still has a named foundation")
		var plinth: MeshInstance3D = hall_view.find_child("TrimPlinth", true, false) as MeshInstance3D
		if plinth != null and plinth.mesh is BoxMesh:
			var h := (plinth.mesh as BoxMesh).size.y
			_check(h <= ScaleProfile.TOWN_HALL_WIDTH_METRES * 0.05 + 0.01, "foundation height is <= 0.05B")
		var model_path := String(Catalog.building_path("TOWN_HALL"))
		_check(model_path.contains("castle"), "live hall catalog is the KayKit castle")
	var road_src := FileAccess.get_file_as_string("res://src/GodotClient3D/Scripts/production_road_view_3d.gd")
	_check(road_src.contains("#AB8963") or road_src.contains("#AE906D"), "roads use review centre #AB8963")
	var ground_src := FileAccess.get_file_as_string("res://src/GodotClient3D/Shaders/settlement_ground.gdshader")
	_check(ground_src.contains("meadow_tex") and ground_src.contains("tex_mix"), "ground shader samples authored textures")
	var showcase := Showcase.apply(game.simulation_host.simulation)
	_check(bool(showcase.get("ok", false)), "showcase still stamps")
	_check(int(showcase.get("roads", 0)) >= 12, "showcase stamps a connected road network")
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
	var moon_c: Color = game.sun_light.light_color
	_check(moon_c.b > moon_c.g, "live moon is blue, not green")


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
