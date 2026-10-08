class_name ProductionWorldView3D
extends Node3D

const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Catalog = preload("res://src/GodotClient3D/Scripts/production_asset_catalog.gd")
const ScaleProfile = preload("res://src/GodotClient3D/Scripts/production_scale_profile.gd")
const BuildingView = preload("res://src/GodotClient3D/Scripts/production_building_view_3d.gd")
const CharacterView = preload("res://src/GodotClient3D/Scripts/production_character_view_3d.gd")
const RoadView = preload("res://src/GodotClient3D/Scripts/production_road_view_3d.gd")
const HaloCatalog = preload("res://src/GodotClient3D/Scripts/production_building_halo.gd")
const ProjectileView = preload("res://src/GodotClient3D/Scripts/production_projectile_view_3d.gd")
const FogShader = preload("res://src/GodotClient3D/Shaders/production_fog_of_war.gdshader")
const FogScreenShader = preload("res://src/GodotClient3D/Shaders/production_fog_screen.gdshader")
const BoundaryMistShader = preload("res://src/GodotClient3D/Shaders/production_boundary_mist.gdshader")
const ContactAO = preload("res://src/GodotClient3D/Scripts/production_contact_ao.gd")
const RoadStampShader = preload("res://src/GodotClient3D/Shaders/settlement_road_stamp.gdshader")
const FoliageShader = preload("res://src/GodotClient3D/Shaders/settlement_foliage.gdshader")
const WaterShader = preload("res://src/GodotClient3D/Shaders/settlement_water.gdshader")
const HorizonShader = preload("res://src/GodotClient3D/Shaders/settlement_horizon.gdshader")
const FOG_MASK_DIVISOR := 1
const FOG_VOLUME_PAD_METRES := 0.35
const WATER_Y := -0.22
const WATER_PAD_METRES := 2400.0
const BEACH_MARGIN_TILES := 2
const BEACH_MARGIN_METRES := 5.0
const COAST_JUT_METRES := 12.0
const BEACH_APRON_PAD_METRES := 20.0
const SHORE_FADE_METRES := 16.0
const HORIZON_RADIUS_METRES := 420.0
const FOG_VOLUME_HEIGHT_METRES := 56.0
const FOG_VOLUME_CENTER_Y := 18.0
const FOG_DISPLAY_UPSAMPLE := 8
const FOG_UNKNOWN_BASE := Vector3(0.10, 0.13, 0.16)
const FOG_MIST_BASE := Vector3(0.16, 0.19, 0.22)

var simulation
var map_size := Vector2i.ZERO
var visual_seed := 1
var foliage_density := 1.0
var civilian_animation_budget := 32
var terrain_root: Node3D
var water_root: Node3D
var roads_root: Node3D
var road_preview_root: Node3D
var road_stamp_root: Node3D
var buildings_root: Node3D
var characters_root: Node3D
var resource_visuals_root: Node3D
var grass_root: Node3D
var edge_forest_root: Node3D
var halo_root: Node3D
var environment_root: Node3D
var vfx_root: Node3D
var navigation_presentation_root: Node3D
var fog_root: Node3D
var rival_roads_root: Node3D
var rivalry_structures_root: Node3D
var combatants_root: Node3D
var gates_root: Node3D
var claims_root: Node3D
var pad_root: Node3D
var shard_beacon: Node3D
var shard_beacon_light: OmniLight3D
var shard_beacon_column: MeshInstance3D
var shard_crystal_material: StandardMaterial3D
var wyrd_spring_views: Dictionary = {}
var terrain_body: StaticBody3D
var terrain_mesh_instance: MeshInstance3D
var building_views: Dictionary = {}
var character_views: Dictionary = {}
var road_views: Dictionary = {}
var road_signatures: Dictionary = {}
var road_stamp_signature := ""
var rival_road_views: Dictionary = {}
var rival_road_signatures: Dictionary = {}
var rivalry_structure_views: Dictionary = {}
var combatant_views: Dictionary = {}
var projectile_views: Dictionary = {}
var decorative_prop_views: Dictionary = {}
var gate_views: Dictionary = {}
var gate_signatures: Dictionary = {}
var nature_views: Dictionary = {}
var nature_types: Dictionary = {}
var nature_stages: Dictionary = {}
var packed_cache: Dictionary = {}
var nature_mesh_cache: Dictionary = {}
var nature_layout_signature := 0
var grass_layout_signature := 0
var grass_revealed_count := -1
var edge_forest_signature := ""
var halo_signature := ""
var halo_placements: Array = []
var selected_building_id := 0
var selected_worker_id := 0
var terrain_height_signature := 0
var real_worker_count := 0
var active_worker_count := 0
var animated_civilian_count := 0
var carriers_with_cargo := 0
var construction_activity_count := 0
var last_revealed_count := -1
var fog_visibility_texture: ImageTexture
var fog_mask_bytes := PackedByteArray()
var fog_mask_size := Vector2i.ZERO
var fog_material: ShaderMaterial
var fog_plane: MeshInstance3D
var boundary_mist_material: ShaderMaterial
var water_mesh_instance: MeshInstance3D
var water_material: ShaderMaterial
var beach_apron_instance: MeshInstance3D
var rim_mesh_instance: MeshInstance3D
var horizon_root: Node3D
var rim_signature := ""
var water_detail := 1.0
var fog_screen: MeshInstance3D
var fog_screen_material: ShaderMaterial
var fog_overlay_camera: Camera3D
var fog_skirts: Array[MeshInstance3D] = []
var claim_overlay_forced := false
var claim_overlay_signature := ""
var tower_overlay_visible := false
var tower_overlay_center := Vector2.ZERO
var tower_overlay_radius := 0.0
var hostile_count := 0
var rival_activity_count := 0
var presentation_paused := false
var _terrain_yard_cache: Dictionary = {}
var _terrain_occupied_cache: Dictionary = {}
var _atmosphere_scale := 1.0
var _ground_tint := Color(1.0, 1.0, 1.0)


func setup(simulation_value, world_snapshot: Dictionary, quality: Dictionary = {}) -> void:
	if get_child_count() > 0:
		for child in get_children():
			remove_child(child)
			child.free()
		terrain_root = null
		water_root = null
		water_mesh_instance = null
		water_material = null
		beach_apron_instance = null
		rim_mesh_instance = null
		horizon_root = null
		rim_signature = ""
		roads_root = null
		road_preview_root = null
		road_stamp_root = null
		buildings_root = null
		characters_root = null
		resource_visuals_root = null
		grass_root = null
		edge_forest_root = null
		halo_root = null
		environment_root = null
		vfx_root = null
		navigation_presentation_root = null
		fog_root = null
		fog_plane = null
		fog_screen = null
		fog_screen_material = null
		fog_skirts.clear()
		fog_visibility_texture = null
		fog_mask_bytes.clear()
		fog_mask_size = Vector2i.ZERO
		fog_material = null
		rival_roads_root = null
		rivalry_structures_root = null
		combatants_root = null
		gates_root = null
		claims_root = null
		pad_root = null
		shard_beacon = null
		shard_beacon_light = null
		shard_beacon_column = null
		shard_crystal_material = null
		wyrd_spring_views.clear()
		terrain_body = null
		terrain_mesh_instance = null
		building_views.clear()
		character_views.clear()
		road_views.clear()
		road_signatures.clear()
		road_stamp_signature = ""
		rival_road_views.clear()
		rival_road_signatures.clear()
		rivalry_structure_views.clear()
		combatant_views.clear()
		projectile_views.clear()
		decorative_prop_views.clear()
		gate_views.clear()
		gate_signatures.clear()
		nature_views.clear()
		nature_types.clear()
		nature_stages.clear()
		nature_layout_signature = 0
		grass_layout_signature = 0
		grass_revealed_count = -1
		edge_forest_signature = ""
		halo_signature = ""
		halo_placements.clear()
		last_revealed_count = -1
		claim_overlay_signature = ""
	simulation = simulation_value
	map_size = Vector2i(world_snapshot.get("map_size", Vector2i.ZERO))
	visual_seed = int(world_snapshot.get("seed", 1))
	foliage_density = clampf(float(quality.get("foliage_density", 1.0)), 0.25, 1.0)
	water_detail = clampf(float(quality.get("water_detail", 1.0)), 0.2, 1.0)
	civilian_animation_budget = maxi(12, roundi(32.0 * clampf(float(quality.get("animation_lod", 1.0)), 0.4, 1.0)))
	_create_roots()
	_rebuild_terrain()
	_rebuild_water()
	_rebuild_world_rim(true)
	_rebuild_horizon()
	_sync_nature(true)
	_sync_grass(true)
	_sync_fog(true)
	_rebuild_edge_forest(true)
	_rebuild_building_halos(true)
	_create_shard_marker()


func bind_fog_overlay(_camera: Camera3D) -> void:
	fog_overlay_camera = _camera
	_hide_fog_screen()


func sync_frame(frame_snapshot: Dictionary) -> void:
	var next_height_signature := _calculate_height_signature()
	if next_height_signature != terrain_height_signature:
		_rebuild_terrain()
	_sync_nature(false)
	_sync_grass(false)
	_sync_roads(frame_snapshot.get("roads", []))
	_sync_buildings(frame_snapshot.get("buildings", []))
	_rebuild_building_halos(false)
	_sync_characters(frame_snapshot.get("workers", []))
	_sync_gates(frame_snapshot.get("roads", []))
	_sync_rival_roads(frame_snapshot.get("rival_roads", []))
	_sync_rivalry_structures(frame_snapshot.get("rivalry_structures", []))
	_sync_combatants(frame_snapshot.get("combatants", []))
	_sync_projectiles(frame_snapshot.get("projectiles", []))
	_sync_decorative_props(frame_snapshot.get("decorative_props", []))
	_sync_claim_overlays(frame_snapshot.get("lumen_sources", []), frame_snapshot.get("claims", {}))
	_update_shard_beacon(frame_snapshot.get("wyrdfall", {}))
	_sync_wyrd_springs(frame_snapshot.get("wyrd_sites", []))
	_sync_map_markers()
	var revealed_count := int(frame_snapshot.get("revealed_count", simulation.revealed_tiles.size()))
	if revealed_count != last_revealed_count:
		_sync_fog(false)
		_sync_nature(true)
		_rebuild_edge_forest(false)
		_rebuild_world_rim(false)


func tile_to_world(tile_position: Vector2) -> Vector3:
	var flat := ScaleProfile.tile_to_flat_world(tile_position, map_size)
	flat.y = height_at_logical(tile_position) + 0.04
	return flat


func world_to_tile(world_position: Vector3) -> Vector2i:
	var half := Vector2(map_size - Vector2i.ONE) * 0.5
	return Vector2i(
		roundi(world_position.x / ScaleProfile.LOGICAL_CELL_METRES + half.x),
		roundi(world_position.z / ScaleProfile.LOGICAL_CELL_METRES + half.y)
	)


func height_at_logical(tile_position: Vector2) -> float:
	if simulation == null or map_size == Vector2i.ZERO:
		return 0.0
	var tile := Vector2i(clampi(roundi(tile_position.x), 0, map_size.x - 1), clampi(roundi(tile_position.y), 0, map_size.y - 1))
	return float(simulation.get_height(tile)) * ScaleProfile.TERRAIN_ELEVATION_UNIT_METRES


func focus_for_building(id: int) -> Vector3:
	if building_views.has(id):
		return (building_views[id] as ProductionBuildingView3D).camera_focus_position()
	return Vector3.ZERO


func set_selection(building_id: int, worker_id: int) -> void:
	selected_building_id = building_id
	selected_worker_id = worker_id
	for id_value in building_views:
		(building_views[id_value] as ProductionBuildingView3D).set_selected(int(id_value) == building_id)
	for id_value in character_views:
		(character_views[id_value] as ProductionCharacterView3D).set_selected(int(id_value) == worker_id)
	for id_value in rivalry_structure_views:
		(rivalry_structure_views[id_value] as ProductionBuildingView3D).set_selected(int(id_value) == building_id)
	for id_value in combatant_views:
		(combatant_views[id_value] as ProductionCharacterView3D).set_selected(int(id_value) == worker_id)


func set_claim_overlay_visible(value: bool) -> void:
	if claim_overlay_forced == value:
		return
	claim_overlay_forced = value
	claim_overlay_signature = ""


func set_watchtower_overlay(center: Vector2, radius_cells: float, value: bool) -> void:
	tower_overlay_center = center
	tower_overlay_radius = radius_cells
	tower_overlay_visible = value
	claim_overlay_signature = ""


func show_road_preview(segments: Array) -> void:
	clear_road_preview()
	if road_preview_root == null:
		return
	var lookup: Dictionary = {}
	for segment_value in segments:
		var segment: Dictionary = segment_value
		lookup[_tile_key(Vector2i(segment.get("tile", Vector2i.ZERO)))] = segment
	var directions := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	for key_value in lookup:
		var segment: Dictionary = lookup[key_value]
		var tile := Vector2i(segment.get("tile", Vector2i.ZERO))
		var mask := 0
		for index in directions.size():
			var neighbor: Vector2i = tile + directions[index]
			if lookup.has(_tile_key(neighbor)) or simulation._is_road_tile(neighbor):
				mask |= 1 << index
		var view := RoadView.new()
		view.configure(0, tile, mask, true, "preview_valid" if bool(segment.get("valid", false)) else "preview_invalid")
		view.position = tile_to_world(Vector2(tile)) + Vector3.UP * 0.10
		road_preview_root.add_child(view)


func clear_road_preview() -> void:
	if road_preview_root == null:
		return
	for child in road_preview_root.get_children():
		child.queue_free()


func show_build_pads(valid: Array, clearing: Array) -> void:
	clear_build_pads()
	if pad_root == null:
		return
	for tile_value in valid:
		_add_pad_marker(Vector2i(tile_value), Color(0.22, 0.78, 0.42, 0.30))
	for tile_value in clearing:
		_add_pad_marker(Vector2i(tile_value), Color(0.95, 0.68, 0.18, 0.38))


func clear_build_pads() -> void:
	if pad_root == null:
		return
	for child in pad_root.get_children():
		child.queue_free()


func _add_pad_marker(tile: Vector2i, color: Color) -> void:
	var marker := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(ScaleProfile.LOGICAL_CELL_METRES * 0.90, 0.08, ScaleProfile.LOGICAL_CELL_METRES * 0.90)
	marker.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker.material_override = material
	marker.position = tile_to_world(Vector2(tile)) + Vector3.UP * 0.07
	pad_root.add_child(marker)


func set_presentation_paused(value: bool) -> void:
	presentation_paused = value
	for view_value in character_views.values() + combatant_views.values():
		(view_value as ProductionCharacterView3D).set_presentation_paused(value)


func presentation_metrics() -> Dictionary:
	return {
		"real_workers": real_worker_count,
		"active_job_workers": active_worker_count,
		"animated_civilians": animated_civilian_count,
		"carriers_with_cargo": carriers_with_cargo,
		"construction_activity": construction_activity_count,
		"building_views": building_views.size(),
		"road_views": road_views.size(),
		"nature_regions": nature_views.size(),
		"hostile_views": hostile_count,
		"rival_activity_views": rival_activity_count,
		"projectile_views": projectile_views.size(),
		"fog_unknown_tiles": map_size.x * map_size.y - maxi(0, last_revealed_count),
	}


func fog_configuration() -> Dictionary:
	return {
		"uses_smoothed_texture": fog_visibility_texture != null,
		"filter_linear": true,
		"edge_feather_cells": 4,
		"noise_strength": 0.22,
		"unknown_opacity": 1.0,
		"unknown_color": FOG_UNKNOWN_BASE,
		"mist_color": FOG_MIST_BASE,
		"world_anchored": true,
		"volume_mesh": fog_plane != null,
		"exterior_opaque": true,
		"shore_fade_metres": SHORE_FADE_METRES,
		"island_water": water_mesh_instance != null,
		"world_min_xz": _fog_world_min_xz(),
		"world_size_xz": _fog_world_size_xz(),
		"mask_size": Vector2i(fog_visibility_texture.get_width(), fog_visibility_texture.get_height()) if fog_visibility_texture != null else Vector2i.ZERO,
		"mesh_count": fog_root.get_child_count() if fog_root != null else 0,
	}


func fog_world_to_uv(world_position: Vector3) -> Vector2:
	var minimum := _fog_world_min_xz()
	var size := _fog_world_size_xz()
	return Vector2(
		(world_position.x - minimum.x) / maxf(0.001, size.x),
		(world_position.z - minimum.y) / maxf(0.001, size.y)
	)


func fog_uv_for_tile(tile: Vector2i) -> Vector2:
	return fog_world_to_uv(tile_to_world(Vector2(tile)))


func revealed_camera_bounds(zoom: float, extra_pad: float = 12.0) -> Rect2:
	if simulation == null or simulation.revealed_tiles.is_empty():
		return Rect2()
	var min_tile := Vector2i(simulation.map_size)
	var max_tile := Vector2i(-1, -1)
	for key in simulation.revealed_tiles.keys():
		var tile: Vector2i = simulation._tile_from_key(String(key))
		min_tile.x = mini(min_tile.x, tile.x)
		min_tile.y = mini(min_tile.y, tile.y)
		max_tile.x = maxi(max_tile.x, tile.x)
		max_tile.y = maxi(max_tile.y, tile.y)
	var min_world := ScaleProfile.tile_to_flat_world(Vector2(min_tile), map_size)
	var max_world := ScaleProfile.tile_to_flat_world(Vector2(max_tile), map_size)
	var half := ScaleProfile.LOGICAL_CELL_METRES * 0.5
	var pad := extra_pad + zoom * 0.62
	var min_x := minf(min_world.x, max_world.x) - half - pad
	var max_x := maxf(min_world.x, max_world.x) + half + pad
	var min_z := minf(min_world.z, max_world.z) - half - pad
	var max_z := maxf(min_world.z, max_world.z) + half + pad
	return Rect2(min_x, min_z, maxf(8.0, max_x - min_x), maxf(8.0, max_z - min_z))


func fog_mask_sample_for_tile(tile: Vector2i) -> float:
	if fog_mask_bytes.is_empty() or not simulation.is_inside_map(tile):
		return 0.0
	var mask_tile := Vector2i(tile.x / FOG_MASK_DIVISOR, tile.y / FOG_MASK_DIVISOR)
	if mask_tile.x < 0 or mask_tile.y < 0 or mask_tile.x >= fog_mask_size.x or mask_tile.y >= fog_mask_size.y:
		return 0.0
	return float(fog_mask_bytes[mask_tile.y * fog_mask_size.x + mask_tile.x]) / 255.0


func _fog_world_min_xz() -> Vector2:
	var first_center := ScaleProfile.tile_to_flat_world(Vector2.ZERO, map_size)
	var half_cell := ScaleProfile.LOGICAL_CELL_METRES * 0.5
	return Vector2(first_center.x - half_cell, first_center.z - half_cell)


func _fog_world_size_xz() -> Vector2:
	return Vector2(map_size) * ScaleProfile.LOGICAL_CELL_METRES


func _create_roots() -> void:
	if terrain_root != null:
		return
	terrain_root = _named_root("Terrain")
	water_root = _named_root("Water")
	roads_root = _named_root("Roads")
	road_preview_root = _named_root("RoadPreview")
	road_stamp_root = _named_root("RoadStamps")
	buildings_root = _named_root("Buildings")
	characters_root = _named_root("Characters")
	resource_visuals_root = _named_root("ResourceVisuals")
	grass_root = _named_root("GrassCover")
	edge_forest_root = _named_root("EdgeForest")
	horizon_root = _named_root("Horizon")
	halo_root = _named_root("BuildingHalos")
	environment_root = _named_root("Environment")
	vfx_root = _named_root("VFX")
	navigation_presentation_root = _named_root("NavigationPresentation")
	fog_root = _named_root("FogOfWar")
	rival_roads_root = _named_root("RivalRoads")
	rivalry_structures_root = _named_root("RivalryStructures")
	combatants_root = _named_root("Combatants")
	gates_root = _named_root("Gates")
	claims_root = _named_root("ClaimOverlays")
	pad_root = _named_root("BuildPads")
	_create_shard_marker()


func _named_root(root_name: String) -> Node3D:
	var root := Node3D.new()
	root.name = root_name
	add_child(root)
	return root


func _rebuild_terrain() -> void:
	if terrain_mesh_instance != null:
		terrain_mesh_instance.queue_free()
	if terrain_body != null:
		terrain_body.queue_free()
	_terrain_yard_cache = _yard_tiles(3)
	_terrain_occupied_cache = _structure_tiles()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for y in range(map_size.y):
		for x in range(map_size.x):
			_add_terrain_cell(surface, Vector2i(x, y))
	var mesh := surface.commit()
	terrain_mesh_instance = MeshInstance3D.new()
	terrain_mesh_instance.name = "ContinuousTerrain"
	terrain_mesh_instance.mesh = mesh
	var material := ShaderMaterial.new()
	material.shader = preload("res://src/GodotClient3D/Shaders/settlement_ground.gdshader")
	material.set_shader_parameter("light_tint", Vector3(_ground_tint.r, _ground_tint.g, _ground_tint.b))
	material.set_shader_parameter("tint_floor", 0.0)
	# The Director: GFX-03 two-scale terrain + GFX-B meadow amount.
	material.set_shader_parameter("grass_sunlit", Vector3(0.416, 0.510, 0.306))
	material.set_shader_parameter("grass_moss", Vector3(0.271, 0.376, 0.220))
	material.set_shader_parameter("macro_metres", 14.0)
	material.set_shader_parameter("detail_metres", 1.2)
	material.set_shader_parameter("macro_amount", 0.12)
	material.set_shader_parameter("detail_amount", 0.052)
	material.set_shader_parameter("dirt_amount", 0.36)
	material.set_shader_parameter("world_min_xz", _fog_world_min_xz())
	material.set_shader_parameter("world_size_xz", _fog_world_size_xz())
	material.set_shader_parameter("beach_margin_metres", BEACH_MARGIN_METRES)
	material.set_shader_parameter("coast_jut_metres", COAST_JUT_METRES)
	material.set_shader_parameter("apron_mode", 0.0)
	terrain_mesh_instance.material_override = material
	# Self-shadow on the playable slab plus PSSM 2-split painted a moving
	# diagonal seam. Buildings still cast onto the ground.
	terrain_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	terrain_root.add_child(terrain_mesh_instance)
	terrain_body = StaticBody3D.new()
	terrain_body.name = "TerrainPicker"
	terrain_body.set_meta("selection_kind", "terrain")
	var collision := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(mesh.get_faces())
	collision.shape = shape
	terrain_body.add_child(collision)
	terrain_root.add_child(terrain_body)
	# G1: the teal OuterWildernessFloor was the box-like void. Water + rim
	# + horizon replace it. Unexplored still sits under #47 fog.
	boundary_mist_material = null
	terrain_height_signature = _calculate_height_signature()
	_rebuild_beach_apron()


func _add_terrain_cell(surface: SurfaceTool, tile: Vector2i) -> void:
	var center := ScaleProfile.tile_to_flat_world(Vector2(tile), map_size)
	var half := ScaleProfile.LOGICAL_CELL_METRES * 0.5
	var top_y := float(simulation.get_height(tile)) * ScaleProfile.TERRAIN_ELEVATION_UNIT_METRES
	var color := _terrain_color(tile)
	var corners := [
		Vector3(center.x - half, top_y, center.z - half),
		Vector3(center.x + half, top_y, center.z - half),
		Vector3(center.x + half, top_y, center.z + half),
		Vector3(center.x - half, top_y, center.z + half),
	]
	_add_quad(surface, corners[0], corners[1], corners[2], corners[3], Vector3.UP, color)
	var directions: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	for direction_index in directions.size():
		var neighbor: Vector2i = tile + directions[direction_index]
		if not simulation.is_inside_map(neighbor):
			continue
		var neighbor_y := float(simulation.get_height(neighbor)) * ScaleProfile.TERRAIN_ELEVATION_UNIT_METRES
		if neighbor_y >= top_y - 0.001:
			continue
		var a: Vector3
		var b: Vector3
		match direction_index:
			0:
				a = corners[1]; b = corners[0]
			1:
				a = corners[2]; b = corners[1]
			2:
				a = corners[3]; b = corners[2]
			_:
				a = corners[0]; b = corners[3]
		var down_a := Vector3(a.x, neighbor_y, a.z)
		var down_b := Vector3(b.x, neighbor_y, b.z)
		var normal := Vector3(float(directions[direction_index].x), 0.0, float(directions[direction_index].y))
		_add_quad(surface, a, b, down_b, down_a, normal, color.darkened(0.24))


func _add_quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3, color: Color) -> void:
	for vertex in [a, b, c, a, c, d]:
		surface.set_normal(normal)
		surface.set_color(color.srgb_to_linear())
		surface.add_vertex(vertex)


func _terrain_color(tile: Vector2i) -> Color:
	var tree_weight := 0
	var rock_weight := 0
	for oy in range(-2, 3):
		for ox in range(-2, 3):
			var sample := tile + Vector2i(ox, oy)
			if not simulation.is_inside_map(sample):
				continue
			var tile_type := String(simulation.get_tile(sample))
			if tile_type == Defs.TILE_TREE: tree_weight += 1
			if tile_type == Defs.TILE_ROCK: rock_weight += 1
	var hash_a := float(_tile_hash(tile, 7) % 100) / 100.0
	var hash_b := float(_tile_hash(tile, 13) % 100) / 100.0
	var base := Color("#4A6840")
	base = base.lerp(Color("#567848"), hash_a * 0.04)
	base = base.lerp(Color("#3A5840"), hash_b * 0.03)
	base = base.lerp(Color("#2a4438"), clampf(float(tree_weight) / 28.0, 0.0, 0.22))
	base = base.lerp(Color("#55574d"), clampf(float(rock_weight) / 32.0, 0.0, 0.18))
	var edge := mini(mini(tile.x, tile.y), mini(map_size.x - 1 - tile.x, map_size.y - 1 - tile.y))
	if edge <= 1:
		base = base.lerp(Color("#C4A878") if rock_weight < 3 else Color("#6A6054"), 0.18)
	if _terrain_yard_cache.has(_tile_key(tile)):
		base = base.lerp(Color("#7a6a40"), 0.08)
	if String(simulation.get_tile(tile)) == Defs.TILE_SHARD:
		base = Color("#465963")
	var impact := 0.0
	if simulation.has_method("impact_factor"):
		impact = float(simulation.impact_factor(tile))
	if impact > 0.0:
		base = base.lerp(Color("#2a3140"), clampf(impact * 0.78, 0.0, 0.78))
		base = base.lerp(Color("#3a5c66"), clampf(impact * 0.22, 0.0, 0.22))
		if impact > 0.55:
			base = base.lerp(Color("#4a6d78"), clampf((impact - 0.55) * 0.35, 0.0, 0.22))
	return base


func _calculate_height_signature() -> int:
	var value := 17
	for y in range(map_size.y):
		for x in range(map_size.x):
			value = int((value * 31 + simulation.get_height(Vector2i(x, y))) & 0x7fffffff)
	return value


func _sync_nature(force: bool) -> void:
	var changed := force
	var next_layout_signature := _calculate_nature_layout_signature()
	if next_layout_signature != nature_layout_signature:
		changed = true
		nature_layout_signature = next_layout_signature
	for y in range(map_size.y):
		for x in range(map_size.x):
			var tile := Vector2i(x, y)
			var key := _tile_key(tile)
			var tile_type := String(simulation.get_tile(tile))
			var visual_type := tile_type
			if tile_type == Defs.TILE_GRASS and float(simulation.tree_regrowth.get(key, 1.0)) <= 0.0:
				visual_type = "STUMP"
			var stage := _nature_resource_stage(tile, tile_type)
			var state_signature := "%s:%d" % [visual_type, stage]
			if not force and String(nature_types.get(key, "")) == state_signature:
				continue
			changed = true
			nature_types[key] = state_signature
			nature_stages[key] = stage
			if visual_type == Defs.TILE_TREE:
				nature_views[key] = Defs.TILE_TREE
			elif visual_type == Defs.TILE_ROCK:
				nature_views[key] = Defs.TILE_ROCK
			elif visual_type == "STUMP":
				nature_views[key] = "STUMP"
			else:
				nature_views.erase(key)
				nature_stages.erase(key)
	if changed:
		_rebuild_nature_multimeshes()


func _calculate_nature_layout_signature() -> int:
	var value := 23
	for building_value in simulation.get_buildings():
		var building: Dictionary = building_value
		var tile: Vector2i = building.get("position", Vector2i.ZERO)
		value = int((value * 31 + int(building.get("id", 0)) * 7 + tile.x * 13 + tile.y * 17 + int(bool(building.get("construction", false)))) & 0x7fffffff)
	return value


func _rebuild_nature_multimeshes() -> void:
	for child in resource_visuals_root.get_children():
		resource_visuals_root.remove_child(child)
		child.free()
	var transforms_by_path: Dictionary = {}
	for key_value in nature_views:
		var tile := _tile_from_key(String(key_value))
		if not simulation.is_revealed(tile):
			continue
		var tile_type := String(nature_views[key_value])
		var stage := int(nature_stages.get(key_value, 0))
		if tile_type == Defs.TILE_TREE:
			if _nature_suppressed_near_activity(tile):
				continue
			var neighbors := _same_type_neighbors(tile, Defs.TILE_TREE)
			var visual_count := 2 if stage >= 2 and neighbors >= 6 and foliage_density >= 0.75 and _tile_hash(tile, 19) % 2 == 0 else 1
			if foliage_density < 0.50 and _tile_hash(tile, 91) % 3 == 0:
				visual_count = 0
			for index in visual_count:
				var path_value := String(Catalog.TREES[_tile_hash(tile, 17 + index) % Catalog.TREES.size()])
				_append_nature_transform(transforms_by_path, path_value, tile, index, 0.72, 0.58 + float(stage) * 0.10, 0.24)
			if stage >= 2 and neighbors >= 3 and foliage_density >= 0.75:
				var understory_path := String(Catalog.UNDERSTORY[_tile_hash(tile, 71) % Catalog.UNDERSTORY.size()])
				_append_nature_transform(transforms_by_path, understory_path, tile, 5, 0.84, 0.66, 0.18)
		elif tile_type == Defs.TILE_ROCK:
			if _nature_suppressed_near_activity(tile):
				continue
			var rock_count := 2 if stage >= 2 and _same_type_neighbors(tile, Defs.TILE_ROCK) >= 3 else 1
			for index in rock_count:
				var rock_path := String(Catalog.ROCKS[_tile_hash(tile, 101 + index) % Catalog.ROCKS.size()])
				_append_nature_transform(transforms_by_path, rock_path, tile, index, 0.66, 0.46 + float(stage) * 0.28, 0.18)
		elif tile_type == "STUMP":
			if _nature_suppressed_near_activity(tile):
				continue
			_append_nature_transform(transforms_by_path, String(Catalog.CARGO["wood"]), tile, 0, 0.18, 0.42, 0.06)
	# Off-map decorative trees used to poke under the old FOW sheet. The fog
	# volume now owns the exterior, so extra silhouettes are not needed.
	_spawn_nature_multimeshes(resource_visuals_root, transforms_by_path)


func _sync_grass(force: bool) -> void:
	if simulation == null or grass_root == null:
		return
	var layout := _calculate_nature_layout_signature()
	var revealed := int(simulation.revealed_tiles.size())
	if not force and layout == grass_layout_signature and revealed == grass_revealed_count:
		return
	grass_layout_signature = layout
	grass_revealed_count = revealed
	_rebuild_grass_multimeshes()


func _rebuild_grass_multimeshes() -> void:
	if grass_root == null or simulation == null:
		return
	for child in grass_root.get_children():
		grass_root.remove_child(child)
		child.free()
	var occupied := _structure_tiles()
	var yard := _yard_tiles(6)
	var transforms_by_path: Dictionary = {}
	for y in range(map_size.y):
		for x in range(map_size.x):
			var tile := Vector2i(x, y)
			if String(simulation.get_tile(tile)) != Defs.TILE_GRASS:
				continue
			if occupied.has(_tile_key(tile)):
				continue
			if not simulation.is_revealed(tile):
				continue
				continue
			var near_yard := yard.has(_tile_key(tile))
			if near_yard:
				if foliage_density < 0.5 and _tile_hash(tile, 11) % 4 == 0:
					continue
				var tufts := 3 if _tile_hash(tile, 19) % 3 != 0 else 2
				for index in tufts:
					var grass_path := String(Catalog.GRASS[_tile_hash(tile, 83 + index) % Catalog.GRASS.size()])
					_append_nature_transform(transforms_by_path, grass_path, tile, index, 0.95, 0.92, 0.28)
			else:
				if _tile_hash(tile, 23) % 2 != 0:
					continue
				var sparse_path := String(Catalog.GRASS[_tile_hash(tile, 83) % Catalog.GRASS.size()])
				_append_nature_transform(transforms_by_path, sparse_path, tile, 0, 0.88, 0.82, 0.22)
	_spawn_nature_multimeshes(grass_root, transforms_by_path)


func _structure_tiles() -> Dictionary:
	var occupied: Dictionary = {}
	for building_value in simulation.get_buildings():
		var building: Dictionary = building_value
		var type_name := String(building.get("planned_type", "")) if bool(building.get("construction", false)) else String(building.get("type", ""))
		var anchor: Vector2i = building.get("position", Vector2i.ZERO)
		var footprint := _building_footprint_for_visual(building, type_name)
		for oy in range(footprint.y):
			for ox in range(footprint.x):
				occupied[_tile_key(anchor + Vector2i(ox, oy))] = true
	return occupied


func _yard_tiles(radius: int) -> Dictionary:
	var yard: Dictionary = {}
	for building_value in simulation.get_buildings():
		var building: Dictionary = building_value
		var type_name := String(building.get("planned_type", "")) if bool(building.get("construction", false)) else String(building.get("type", ""))
		if type_name == Defs.BUILDING_ROAD:
			continue
		var anchor: Vector2i = building.get("position", Vector2i.ZERO)
		var footprint := _building_footprint_for_visual(building, type_name)
		var center := Vector2i(anchor.x + int(footprint.x / 2), anchor.y + int(footprint.y / 2))
		for oy in range(-radius, radius + 1):
			for ox in range(-radius, radius + 1):
				var tile := center + Vector2i(ox, oy)
				if simulation.is_inside_map(tile):
					yard[_tile_key(tile)] = true
	return yard


func _spawn_nature_contact_ao(host: Node3D, transforms_by_path: Dictionary, intensity := 0.30) -> void:
	var contacts: Array = []
	for path_value in transforms_by_path:
		for xf_value in transforms_by_path[path_value]:
			contacts.append(ContactAO.flatten_transform(xf_value, 1.4))
	ContactAO.spawn_multimesh(host, contacts, intensity)


func _spawn_nature_multimeshes(host: Node3D, transforms_by_path: Dictionary) -> void:
	for path_value in transforms_by_path:
		var mesh := _mesh_for_nature_path(String(path_value))
		if mesh == null:
			continue
		var transforms: Array = transforms_by_path[path_value]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = mesh
		multimesh.instance_count = transforms.size()
		for index in transforms.size():
			multimesh.set_instance_transform(index, transforms[index])
		var instance := MultiMeshInstance3D.new()
		instance.name = "Composed_%s" % String(path_value).get_file().get_basename()
		instance.multimesh = multimesh
		instance.material_override = _foliage_material(mesh, path_value)
		host.add_child(instance)


func _append_nature_transform(groups: Dictionary, path_value: String, tile: Vector2i, index: int, radius: float, base_scale: float, scale_range: float, y_override := NAN) -> void:
	if not groups.has(path_value):
		groups[path_value] = []
	var world_position := tile_to_world(Vector2(tile))
	var offset := _deterministic_offset(tile, index, radius)
	world_position += Vector3(offset.x, 0.0, offset.y)
	if not is_nan(y_override):
		world_position.y = y_override
	var scale_value := (base_scale + float(_tile_hash(tile, 41 + index) % 100) / 100.0 * scale_range) * ScaleProfile.nature_model_scale(path_value)
	var yaw := float(_tile_hash(tile, 53 + index) % 628) / 100.0
	var basis := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scale_value)
	(groups[path_value] as Array).append(Transform3D(basis, world_position))


func _append_boundary_wilderness(groups: Dictionary) -> void:
	for index in range(0, map_size.x, 2):
		_append_boundary_instance(groups, Vector2(float(index), -1.15), index, 0)
		_append_boundary_instance(groups, Vector2(float(index), float(map_size.y) + 0.15), index, 1)
	for index in range(1, map_size.y - 1, 2):
		_append_boundary_instance(groups, Vector2(-1.15, float(index)), index, 2)
		_append_boundary_instance(groups, Vector2(float(map_size.x) + 0.15, float(index)), index, 3)


func _tile_occupied_by_structure(tile: Vector2i) -> bool:
	for building_value in simulation.get_buildings():
		var building: Dictionary = building_value
		var type_name := String(building.get("planned_type", "")) if bool(building.get("construction", false)) else String(building.get("type", ""))
		var anchor: Vector2i = building.get("position", Vector2i.ZERO)
		var footprint := _building_footprint_for_visual(building, type_name)
		if _tile_inside_visual_footprint(tile, anchor, footprint):
			return true
	return false


func _nature_suppressed_near_activity(tile: Vector2i) -> bool:
	for building_value in simulation.get_buildings():
		var building: Dictionary = building_value
		var type_name := String(building.get("planned_type", "")) if bool(building.get("construction", false)) else String(building.get("type", ""))
		var anchor: Vector2i = building.get("position", Vector2i.ZERO)
		if type_name == Defs.BUILDING_ROAD:
			if absi(tile.x - anchor.x) + absi(tile.y - anchor.y) <= 1:
				return true
			continue
		var footprint := _building_footprint_for_visual(building, type_name)
		if type_name == Defs.BUILDING_QUARRY and _tile_inside_visual_footprint(tile, anchor, footprint) and String(simulation.get_tile(tile)) == Defs.TILE_ROCK:
			continue
		var center := Vector2(anchor) + Vector2(footprint - Vector2i.ONE) * 0.5
		var visual_size := ScaleProfile.building_visual_size(type_name, footprint)
		var visual_half_tiles := Vector2(visual_size.x, visual_size.z) / (ScaleProfile.LOGICAL_CELL_METRES * 2.0)
		var clearance_x := maxf(float(footprint.x) * 0.5, visual_half_tiles.x) + 1.35
		var clearance_y := maxf(float(footprint.y) * 0.5, visual_half_tiles.y) + 1.35
		if absf(float(tile.x) - center.x) <= clearance_x and absf(float(tile.y) - center.y) <= clearance_y:
			return true
	return false


func _tile_inside_visual_footprint(tile: Vector2i, anchor: Vector2i, footprint: Vector2i) -> bool:
	return tile.x >= anchor.x and tile.y >= anchor.y and tile.x < anchor.x + footprint.x and tile.y < anchor.y + footprint.y


func _nature_resource_stage(tile: Vector2i, tile_type: String) -> int:
	var remaining := 0
	if tile_type == Defs.TILE_TREE:
		remaining = int(simulation.tree_deposits.get(_tile_key(tile), 0))
	elif tile_type == Defs.TILE_ROCK:
		remaining = int(simulation.rock_deposits.get(_tile_key(tile), 0))
	else:
		return 0
	if remaining > 16:
		return 2
	if remaining > 8:
		return 1
	return 0


func _building_footprint_for_visual(building: Dictionary, type_name: String) -> Vector2i:
	var stored = building.get("footprint", null)
	if typeof(stored) == TYPE_VECTOR2I:
		return stored
	if typeof(stored) == TYPE_DICTIONARY:
		return Vector2i(int(stored.get("x", 1)), int(stored.get("y", 1)))
	return Defs.building_footprint(type_name)


func _append_boundary_instance(groups: Dictionary, logical_position: Vector2, index: int, side: int) -> void:
	var key_tile := Vector2i(roundi(logical_position.x), roundi(logical_position.y))
	var path_value := String(Catalog.TREES[_tile_hash(key_tile, 300 + side) % Catalog.TREES.size()])
	if not groups.has(path_value):
		groups[path_value] = []
	var clamped_tile := Vector2(clampf(logical_position.x, 0.0, float(map_size.x - 1)), clampf(logical_position.y, 0.0, float(map_size.y - 1)))
	var world_position := ScaleProfile.tile_to_flat_world(logical_position, map_size)
	world_position.y = height_at_logical(clamped_tile)
	var scale_value := (1.05 + float(_tile_hash(key_tile, 330 + side) % 35) / 100.0) * ScaleProfile.nature_model_scale(path_value)
	var basis := Basis(Vector3.UP, float(_tile_hash(key_tile, 360 + side) % 628) / 100.0).scaled(Vector3.ONE * scale_value)
	(groups[path_value] as Array).append(Transform3D(basis, world_position))


func _mesh_for_nature_path(path_value: String) -> Mesh:
	if nature_mesh_cache.has(path_value):
		return nature_mesh_cache[path_value]
	var packed := load(path_value) as PackedScene
	if packed == null:
		return null
	var instance := packed.instantiate()
	var mesh_instance := _find_mesh_instance(instance)
	var mesh: Mesh = mesh_instance.mesh if mesh_instance != null else null
	nature_mesh_cache[path_value] = mesh
	instance.free()
	return mesh


func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found := _find_mesh_instance(child)
		if found != null:
			return found
	return null


func _create_forest_region(tile: Vector2i) -> Node3D:
	var root := Node3D.new()
	root.name = "ForestRegion_%d_%d" % [tile.x, tile.y]
	root.position = tile_to_world(Vector2(tile))
	resource_visuals_root.add_child(root)
	var neighbors := _same_type_neighbors(tile, Defs.TILE_TREE)
	var visual_count := 2 if neighbors >= 4 and foliage_density >= 0.55 else 1
	if foliage_density < 0.50 and _tile_hash(tile, 91) % 3 == 0:
		visual_count = 0
	for index in visual_count:
		var path_value := String(Catalog.TREES[_tile_hash(tile, 17 + index) % Catalog.TREES.size()])
		var instance := _instantiate_cached(path_value)
		if instance == null:
			continue
		instance.name = "TreeComposition_%d" % index
		var offset := _deterministic_offset(tile, index, 0.72)
		instance.position = Vector3(offset.x, 0.0, offset.y)
		var scale_value := 0.78 + float(_tile_hash(tile, 41 + index) % 39) / 100.0
		if simulation.has_method("impact_factor"):
			var impact := float(simulation.impact_factor(tile))
			scale_value *= lerpf(1.0, 0.52, impact)
			instance.rotation.z = lerpf(0.0, 0.72, impact)
			instance.rotation.x = lerpf(0.0, 0.28, impact) * (1.0 if index % 2 == 0 else -1.0)
		instance.scale = Vector3.ONE * scale_value
		instance.rotation.y = float(_tile_hash(tile, 53 + index) % 628) / 100.0
		root.add_child(instance)
	if neighbors >= 3 and foliage_density >= 0.75:
		var understory_path := String(Catalog.UNDERSTORY[_tile_hash(tile, 71) % Catalog.UNDERSTORY.size()])
		var understory := _instantiate_cached(understory_path)
		if understory != null:
			understory.name = "Understory"
			var offset := _deterministic_offset(tile, 5, 0.84)
			understory.position = Vector3(offset.x, 0.0, offset.y)
			understory.scale = Vector3.ONE * 0.72
			root.add_child(understory)
	return root


func _create_rock_region(tile: Vector2i) -> Node3D:
	var root := Node3D.new()
	root.name = "RockRegion_%d_%d" % [tile.x, tile.y]
	root.position = tile_to_world(Vector2(tile))
	resource_visuals_root.add_child(root)
	var count := 2 if _same_type_neighbors(tile, Defs.TILE_ROCK) >= 3 else 1
	for index in count:
		var path_value := String(Catalog.ROCKS[_tile_hash(tile, 101 + index) % Catalog.ROCKS.size()])
		var instance := _instantiate_cached(path_value)
		if instance == null:
			continue
		instance.name = "RockComposition_%d" % index
		var offset := _deterministic_offset(tile, index, 0.66)
		instance.position = Vector3(offset.x, 0.0, offset.y)
		instance.scale = Vector3.ONE * (0.75 + float(_tile_hash(tile, 121 + index) % 34) / 100.0)
		instance.rotation.y = float(_tile_hash(tile, 131 + index) % 628) / 100.0
		root.add_child(instance)
	return root


func _create_shard_marker() -> void:
	if simulation == null or environment_root == null:
		return
	if shard_beacon != null:
		shard_beacon.queue_free()
		shard_beacon = null
	shard_beacon = Node3D.new()
	shard_beacon.name = "ShardBeacon"
	var origin := tile_to_world(Vector2(simulation.shard_position))
	shard_beacon.position = Vector3(origin.x, 0.0, origin.z)
	environment_root.add_child(shard_beacon)

	var scar := MeshInstance3D.new()
	scar.name = "ImpactScar"
	var scar_mesh := CylinderMesh.new()
	scar_mesh.top_radius = 6.4
	scar_mesh.bottom_radius = 7.2
	scar_mesh.height = 0.16
	scar.mesh = scar_mesh
	scar.position = Vector3(0.35, 0.04, -0.55)
	var scar_material := StandardMaterial3D.new()
	scar_material.albedo_color = Color("#2a3644")
	scar_material.roughness = 0.92
	scar.material_override = scar_material
	shard_beacon.add_child(scar)

	shard_crystal_material = StandardMaterial3D.new()
	shard_crystal_material.albedo_color = Color(0.38, 0.78, 0.88, 0.88)
	shard_crystal_material.emission_enabled = true
	shard_crystal_material.emission = Color("#3b8fbd")
	shard_crystal_material.emission_energy_multiplier = 2.8
	shard_crystal_material.roughness = 0.18
	shard_crystal_material.metallic = 0.12
	shard_crystal_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var crystal_specs := [
		{"size": Vector3(1.55, 6.4, 1.22), "pos": Vector3(0.0, 3.2, 0.0), "rot": Vector3(8.0, 18.0, 184.0)},
		{"size": Vector3(0.85, 3.6, 0.72), "pos": Vector3(0.95, 2.1, 0.55), "rot": Vector3(16.0, 48.0, 162.0)},
		{"size": Vector3(0.62, 2.4, 0.55), "pos": Vector3(-0.82, 1.55, -0.70), "rot": Vector3(-12.0, -32.0, 198.0)},
		{"size": Vector3(0.38, 1.45, 0.32), "pos": Vector3(0.35, 1.05, 1.25), "rot": Vector3(28.0, 80.0, 140.0)}
	]
	for index in crystal_specs.size():
		var spec: Dictionary = crystal_specs[index]
		var crystal := MeshInstance3D.new()
		crystal.name = "ShardCrystal_%d" % index
		var prism := PrismMesh.new()
		prism.size = spec["size"]
		crystal.mesh = prism
		crystal.position = spec["pos"]
		crystal.rotation_degrees = spec["rot"]
		crystal.material_override = shard_crystal_material
		shard_beacon.add_child(crystal)

	shard_beacon_column = MeshInstance3D.new()
	shard_beacon_column.name = "ShardColumn"
	var column := CylinderMesh.new()
	column.top_radius = 0.12
	column.bottom_radius = 0.72
	column.height = 32.0
	shard_beacon_column.mesh = column
	shard_beacon_column.position = Vector3(0.0, 18.0, 0.0)
	var column_material := StandardMaterial3D.new()
	column_material.albedo_color = Color(0.35, 0.78, 0.92, 0.16)
	column_material.emission_enabled = true
	column_material.emission = Color("#5ec8e0")
	column_material.emission_energy_multiplier = 1.8
	column_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	column_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shard_beacon_column.material_override = column_material
	shard_beacon.add_child(shard_beacon_column)

	shard_beacon_light = OmniLight3D.new()
	shard_beacon_light.name = "ShardLight"
	shard_beacon_light.light_color = Color("#7ad7ea")
	shard_beacon_light.light_energy = 2.8
	shard_beacon_light.omni_range = 20.0
	shard_beacon_light.shadow_enabled = false
	shard_beacon_light.position = Vector3(0.0, 5.4, 0.0)
	shard_beacon.add_child(shard_beacon_light)

	var mist := CPUParticles3D.new()
	mist.name = "ShardMist"
	mist.emitting = true
	mist.amount = 36
	mist.lifetime = 5.2
	mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	mist.emission_sphere_radius = 3.2
	mist.direction = Vector3.UP
	mist.spread = 24.0
	mist.gravity = Vector3(0.0, 0.22, 0.0)
	mist.initial_velocity_min = 0.25
	mist.initial_velocity_max = 1.05
	mist.scale_amount_min = 0.22
	mist.scale_amount_max = 0.58
	var mist_material := StandardMaterial3D.new()
	mist_material.albedo_color = Color(0.55, 0.82, 0.95, 0.18)
	mist_material.emission_enabled = true
	mist_material.emission = Color("#6bcfe0")
	mist_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mist_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mist.mesh = SphereMesh.new()
	(mist.mesh as SphereMesh).radius = 0.28
	(mist.mesh as SphereMesh).height = 0.56
	mist.material_override = mist_material
	mist.position = Vector3(0.2, 1.1, -0.15)
	shard_beacon.add_child(mist)

	var motes := CPUParticles3D.new()
	motes.name = "ShardMotes"
	motes.emitting = true
	motes.amount = 18
	motes.lifetime = 2.8
	motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	motes.emission_sphere_radius = 1.6
	motes.direction = Vector3.UP
	motes.gravity = Vector3(0.0, 0.55, 0.0)
	motes.initial_velocity_min = 0.4
	motes.initial_velocity_max = 1.6
	motes.scale_amount_min = 0.06
	motes.scale_amount_max = 0.14
	var mote_material := StandardMaterial3D.new()
	mote_material.albedo_color = Color(0.72, 0.88, 1.0, 0.55)
	mote_material.emission_enabled = true
	mote_material.emission = Color("#9ae8f2")
	mote_material.emission_energy_multiplier = 2.2
	mote_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	motes.mesh = SphereMesh.new()
	(motes.mesh as SphereMesh).radius = 0.08
	(motes.mesh as SphereMesh).height = 0.16
	motes.material_override = mote_material
	motes.position = Vector3(0.0, 2.8, 0.0)
	shard_beacon.add_child(motes)

	var debris_offsets := [
		Vector3(2.8, 0.22, 1.1), Vector3(-2.1, 0.18, 2.4), Vector3(3.6, 0.28, -1.8),
		Vector3(-3.4, 0.16, -0.9), Vector3(1.2, 0.32, -3.3), Vector3(-0.6, 0.42, 3.6),
		Vector3(4.4, 0.2, 0.6), Vector3(-4.1, 0.24, 1.8), Vector3(2.2, 0.36, 3.1),
		Vector3(-1.8, 0.14, -3.8), Vector3(5.1, 0.18, -2.4)
	]
	for fragment_index in debris_offsets.size():
		var fragment := MeshInstance3D.new()
		fragment.name = "ImpactRock_%d" % fragment_index
		var rock := PrismMesh.new()
		rock.size = Vector3(0.42 + float(fragment_index % 4) * 0.22, 0.28 + float(fragment_index % 3) * 0.16, 0.34)
		fragment.mesh = rock
		fragment.position = debris_offsets[fragment_index]
		fragment.rotation = Vector3(0.31 * fragment_index, 0.7 * fragment_index, 0.22 * fragment_index)
		var rock_material := StandardMaterial3D.new()
		rock_material.albedo_color = Color("#3d4650").lerp(Color("#4a6270"), float(fragment_index % 3) / 3.0)
		fragment.material_override = rock_material
		shard_beacon.add_child(fragment)


func _update_shard_beacon(wyrdfall: Dictionary) -> void:
	if shard_beacon_light == null or shard_beacon_column == null:
		return
	var binding := bool(wyrdfall.get("binding_active", false)) or bool(wyrdfall.get("reckoning", false))
	var progress := clampf(float(wyrdfall.get("binding_percent", 0.0)) / 100.0, 0.0, 1.0)
	var pulse := 1.0 + (0.18 + 0.28 * progress if binding else 0.05) * (0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 280.0))
	shard_beacon_light.light_energy = (3.4 if binding else 2.8) * pulse
	shard_beacon_light.light_color = Color("#7ad7ea").lerp(Color("#a48cff"), progress if binding else 0.0)
	var material := shard_beacon_column.material_override as StandardMaterial3D
	if material != null:
		material.emission_energy_multiplier = (3.2 if binding else 1.8) * pulse
		material.albedo_color.a = 0.32 if binding else 0.16
	if shard_crystal_material != null:
		shard_crystal_material.emission_energy_multiplier = (3.6 if binding else 2.8) * pulse
	if shard_beacon != null:
		var motes := shard_beacon.get_node_or_null("ShardMotes") as CPUParticles3D
		if motes != null:
			motes.speed_scale = 1.35 if binding else 1.0


func _sync_wyrd_springs(sites: Array) -> void:
	var desired: Dictionary = {}
	for site_value in sites:
		var site: Dictionary = site_value
		if not bool(site.get("visible", false)):
			continue
		var tile := Vector2i(site.get("position", Vector2i.ZERO))
		var key := _tile_key(tile)
		desired[key] = site
		if not wyrd_spring_views.has(key):
			wyrd_spring_views[key] = _create_wyrd_spring(tile)
	for key_value in wyrd_spring_views.keys():
		if desired.has(key_value):
			continue
		(wyrd_spring_views[key_value] as Node).queue_free()
		wyrd_spring_views.erase(key_value)


func _create_wyrd_spring(tile: Vector2i) -> Node3D:
	var root := Node3D.new()
	root.name = "WyrdSpring_%d_%d" % [tile.x, tile.y]
	root.position = tile_to_world(Vector2(tile))
	environment_root.add_child(root)
	var basin := MeshInstance3D.new()
	basin.name = "SpringBasin"
	var basin_mesh := CylinderMesh.new()
	basin_mesh.top_radius = 1.15
	basin_mesh.bottom_radius = 1.45
	basin_mesh.height = 0.12
	basin.mesh = basin_mesh
	basin.position.y = 0.05
	var basin_material := StandardMaterial3D.new()
	basin_material.albedo_color = Color("#2c4452")
	basin.material_override = basin_material
	root.add_child(basin)
	for index in 4:
		var mineral := MeshInstance3D.new()
		mineral.name = "SpringMineral_%d" % index
		var mineral_mesh := PrismMesh.new()
		mineral_mesh.size = Vector3(0.22 + float(index) * 0.05, 0.48 + float(index % 2) * 0.22, 0.18)
		mineral.mesh = mineral_mesh
		var angle := float(index) * TAU / 4.0 + 0.35
		mineral.position = Vector3(cos(angle) * 0.55, 0.28, sin(angle) * 0.48)
		mineral.rotation_degrees = Vector3(12.0 * index, 40.0 * index, 18.0)
		var mineral_material := StandardMaterial3D.new()
		mineral_material.albedo_color = Color(0.42, 0.72, 0.82, 0.86)
		mineral_material.emission_enabled = true
		mineral_material.emission = Color("#5aa8c8")
		mineral_material.emission_energy_multiplier = 1.1
		mineral_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mineral.material_override = mineral_material
		root.add_child(mineral)
	var mist := CPUParticles3D.new()
	mist.name = "SpringMist"
	mist.emitting = true
	mist.amount = 10
	mist.lifetime = 3.4
	mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	mist.emission_sphere_radius = 0.7
	mist.direction = Vector3.UP
	mist.gravity = Vector3(0.0, 0.18, 0.0)
	mist.initial_velocity_min = 0.12
	mist.initial_velocity_max = 0.4
	mist.scale_amount_min = 0.12
	mist.scale_amount_max = 0.28
	var mist_material := StandardMaterial3D.new()
	mist_material.albedo_color = Color(0.55, 0.78, 0.88, 0.22)
	mist_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mist_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mist.mesh = SphereMesh.new()
	(mist.mesh as SphereMesh).radius = 0.14
	(mist.mesh as SphereMesh).height = 0.28
	mist.material_override = mist_material
	mist.position.y = 0.35
	root.add_child(mist)
	var light := OmniLight3D.new()
	light.name = "SpringLight"
	light.light_color = Color("#6eb8c8")
	light.light_energy = 0.55
	light.omni_range = 4.2
	light.shadow_enabled = false
	light.position = Vector3(0.0, 0.85, 0.0)
	root.add_child(light)
	var fragment := MeshInstance3D.new()
	fragment.name = "FloatingFragment"
	var fragment_mesh := PrismMesh.new()
	fragment_mesh.size = Vector3(0.16, 0.28, 0.12)
	fragment.mesh = fragment_mesh
	fragment.position = Vector3(0.15, 1.05, -0.1)
	var fragment_material := StandardMaterial3D.new()
	fragment_material.albedo_color = Color(0.55, 0.82, 0.90, 0.7)
	fragment_material.emission_enabled = true
	fragment_material.emission = Color("#7ad0e0")
	fragment_material.emission_energy_multiplier = 0.9
	fragment_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fragment.material_override = fragment_material
	root.add_child(fragment)
	return root


func _sync_roads(road_snapshots: Array) -> void:
	var desired: Dictionary = {}
	for snapshot_value in road_snapshots:
		var snapshot: Dictionary = snapshot_value
		var tile := Vector2i(snapshot.get("anchor", Vector2i.ZERO))
		desired[_tile_key(tile)] = snapshot
	for key_value in road_views.keys():
		if desired.has(key_value):
			continue
		(road_views[key_value] as Node).queue_free()
		road_views.erase(key_value)
		road_signatures.erase(key_value)
	for key_value in desired:
		var snapshot: Dictionary = desired[key_value]
		var tile := Vector2i(snapshot.get("anchor", Vector2i.ZERO))
		var mask := 0
		var directions := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
		for index in directions.size():
			if desired.has(_tile_key(tile + directions[index])):
				mask |= 1 << index
		var planned := bool(snapshot.get("construction", false))
		var next_signature := "%d:%d:%d" % [int(snapshot.get("id", 0)), mask, int(planned)]
		if not road_views.has(key_value):
			var view := RoadView.new()
			view.configure(int(snapshot.get("id", 0)), tile, mask, planned)
			view.position = tile_to_world(Vector2(tile))
			roads_root.add_child(view)
			road_views[key_value] = view
			road_signatures[key_value] = next_signature
		elif String(road_signatures.get(key_value, "")) != next_signature:
			(road_views[key_value] as ProductionRoadView3D).configure(int(snapshot.get("id", 0)), tile, mask, planned)
			road_signatures[key_value] = next_signature
	_rebuild_road_stamps(desired)


func _rebuild_road_stamps(desired: Dictionary) -> void:
	if road_stamp_root == null:
		return
	var keys := desired.keys()
	keys.sort()
	var signature := ""
	for key_value in keys:
		var snapshot: Dictionary = desired[key_value]
		signature += "%s:%d;" % [String(key_value), int(bool(snapshot.get("construction", false)))]
	if signature == road_stamp_signature and road_stamp_root.get_child_count() > 0:
		return
	road_stamp_signature = signature
	for child in road_stamp_root.get_children():
		road_stamp_root.remove_child(child)
		child.free()
	var tracks: Array = []
	var muds: Array = []
	var dirs := [Vector2(0.0, -1.0), Vector2(1.0, 0.0), Vector2(0.0, 1.0), Vector2(-1.0, 0.0)]
	for key_value in desired:
		var snapshot: Dictionary = desired[key_value]
		if bool(snapshot.get("construction", false)):
			continue
		var tile := Vector2i(snapshot.get("anchor", Vector2i.ZERO))
		var mask := 0
		var tile_dirs := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
		for index in tile_dirs.size():
			if desired.has(_tile_key(tile + tile_dirs[index])):
				mask |= 1 << index
		var world := tile_to_world(Vector2(tile))
		var connections := 0
		for index in dirs.size():
			if mask & (1 << index) == 0:
				continue
			connections += 1
			var direction: Vector2 = dirs[index]
			var yaw := atan2(direction.x, direction.y)
			if index == 0 or (mask & (1 << 0) == 0 and index == 1):
				var mid := world + Vector3(direction.x * 0.55, 0.032, direction.y * 0.55)
				tracks.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(0.16, 1.0, 0.62)), mid))
		if connections >= 3:
			muds.append(Transform3D(Basis().scaled(Vector3(0.58, 1.0, 0.58)), world + Vector3(0.0, 0.026, 0.0)))
	# The Director: two stamp batches only. Edge-breaks were a third
	# MultiMesh for almost no camera-readable gain on lavapipe.
	_spawn_road_stamp_multimesh("RoadTracks", tracks, Color(0.43, 0.33, 0.25, 0.50))
	_spawn_road_stamp_multimesh("RoadMud", muds, Color(0.502, 0.388, 0.278, 0.42))


func _spawn_road_stamp_multimesh(node_name: String, transforms: Array, color: Color) -> void:
	if road_stamp_root == null or transforms.is_empty():
		return
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(2.0, 2.0)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index in transforms.size():
		multimesh.set_instance_transform(index, transforms[index])
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = RoadStampShader
	material.set_shader_parameter("stamp_color", color)
	material.render_priority = -1
	instance.material_override = material
	road_stamp_root.add_child(instance)


func _sync_buildings(building_snapshots: Array) -> void:
	var desired: Dictionary = {}
	construction_activity_count = 0
	for snapshot_value in building_snapshots:
		var snapshot: Dictionary = snapshot_value
		var id := int(snapshot.get("id", 0))
		desired[id] = snapshot
		if bool(snapshot.get("construction", false)):
			construction_activity_count += 1
		if not building_views.has(id):
			var view := BuildingView.new()
			view.configure(snapshot)
			view.position = tile_to_world(Vector2(snapshot.get("center", Vector2.ZERO)))
			buildings_root.add_child(view)
			building_views[id] = view
		else:
			var view: ProductionBuildingView3D = building_views[id]
			view.position = tile_to_world(Vector2(snapshot.get("center", Vector2.ZERO)))
			view.apply_snapshot(snapshot)
	for id_value in building_views.keys():
		if desired.has(id_value):
			continue
		(building_views[id_value] as Node).queue_free()
		building_views.erase(id_value)
	set_selection(selected_building_id, selected_worker_id)


func _sync_characters(worker_snapshots: Array) -> void:
	var desired: Dictionary = {}
	var animated_ids: Dictionary = {}
	if selected_worker_id > 0:
		animated_ids[selected_worker_id] = true
	for snapshot_value in worker_snapshots:
		if animated_ids.size() >= civilian_animation_budget:
			break
		var candidate: Dictionary = snapshot_value
		if String(candidate.get("state", "Idle")) not in ["Idle", "Sleep"]:
			animated_ids[int(candidate.get("id", 0))] = true
	for snapshot_value in worker_snapshots:
		if animated_ids.size() >= civilian_animation_budget:
			break
		var candidate: Dictionary = snapshot_value
		animated_ids[int(candidate.get("id", 0))] = true
	real_worker_count = worker_snapshots.size()
	active_worker_count = 0
	animated_civilian_count = animated_ids.size()
	carriers_with_cargo = 0
	for snapshot_value in worker_snapshots:
		var snapshot: Dictionary = snapshot_value
		var id := int(snapshot.get("id", 0))
		desired[id] = snapshot
		if String(snapshot.get("state", "Idle")) not in ["Idle", "Sleep"]:
			active_worker_count += 1
		if String(snapshot.get("worker_type", "")) == "carrier" and int(snapshot.get("cargo_amount", 0)) > 0:
			carriers_with_cargo += 1
		if not character_views.has(id):
			var view := CharacterView.new()
			view.configure(id, String(snapshot.get("worker_type", "settler")), String(snapshot.get("state", "Idle")))
			characters_root.add_child(view)
			character_views[id] = view
		var character: ProductionCharacterView3D = character_views[id]
		snapshot["selected"] = id == selected_worker_id
		character.apply_snapshot(snapshot, tile_to_world(Vector2(snapshot.get("logical_position", Vector2.ZERO))) + Vector3(0.0, float(snapshot.get("elevation", 0.0)), 0.0), not character.has_target)
		character.set_animation_lod_enabled(animated_ids.has(id))
		character.set_presentation_paused(presentation_paused)
	for id_value in character_views.keys():
		if desired.has(id_value):
			continue
		(character_views[id_value] as Node).queue_free()
		character_views.erase(id_value)


func _sync_combatants(snapshots: Array) -> void:
	var desired: Dictionary = {}
	hostile_count = 0
	rival_activity_count = 0
	for snapshot_value in snapshots:
		var snapshot: Dictionary = snapshot_value
		if not bool(snapshot.get("visible", true)):
			continue
		var id := int(snapshot.get("id", 0))
		desired[id] = snapshot
		var faction := String(snapshot.get("faction", ""))
		if faction == "hostile":
			hostile_count += 1
		elif faction == "rival":
			rival_activity_count += 1
		if not combatant_views.has(id):
			var view := CharacterView.new()
			view.configure(id, String(snapshot.get("worker_type", "settler")), String(snapshot.get("state", "Idle")))
			combatants_root.add_child(view)
			combatant_views[id] = view
		var character: ProductionCharacterView3D = combatant_views[id]
		snapshot["selected"] = id == selected_worker_id
		var offset := Vector2(snapshot.get("presentation_offset", Vector2.ZERO))
		character.apply_snapshot(snapshot, tile_to_world(Vector2(snapshot.get("logical_position", Vector2.ZERO)) + offset), not character.has_target)
		character.set_presentation_paused(presentation_paused)
	for id_value in combatant_views.keys():
		if desired.has(id_value):
			continue
		var stale: ProductionCharacterView3D = combatant_views[id_value]
		combatant_views.erase(id_value)
		stale.retire()


func _sync_rivalry_structures(snapshots: Array) -> void:
	var desired: Dictionary = {}
	for snapshot_value in snapshots:
		var snapshot: Dictionary = snapshot_value
		if not bool(snapshot.get("visible", true)):
			continue
		var id := int(snapshot.get("id", 0))
		desired[id] = snapshot
		if not rivalry_structure_views.has(id):
			var view := BuildingView.new()
			view.configure(snapshot)
			view.position = tile_to_world(Vector2(snapshot.get("center", Vector2.ZERO)))
			rivalry_structures_root.add_child(view)
			rivalry_structure_views[id] = view
		else:
			var view: ProductionBuildingView3D = rivalry_structure_views[id]
			view.position = tile_to_world(Vector2(snapshot.get("center", Vector2.ZERO)))
			view.apply_snapshot(snapshot)
	for id_value in rivalry_structure_views.keys():
		if desired.has(id_value):
			continue
		(rivalry_structure_views[id_value] as Node).queue_free()
		rivalry_structure_views.erase(id_value)


func _sync_rival_roads(snapshots: Array) -> void:
	var desired: Dictionary = {}
	for snapshot_value in snapshots:
		var snapshot: Dictionary = snapshot_value
		if String(snapshot.get("realm", "")) != "rival":
			continue
		var tile := Vector2i(snapshot.get("anchor", Vector2i.ZERO))
		desired[_tile_key(tile)] = snapshot
	for key_value in rival_road_views.keys():
		if desired.has(key_value):
			continue
		(rival_road_views[key_value] as Node).queue_free()
		rival_road_views.erase(key_value)
		rival_road_signatures.erase(key_value)
	for key_value in desired:
		var tile := Vector2i(Dictionary(desired[key_value]).get("anchor", Vector2i.ZERO))
		var mask := 0
		var directions := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
		for index in directions.size():
			if desired.has(_tile_key(tile + directions[index])):
				mask |= 1 << index
		var signature := "%d" % mask
		if not rival_road_views.has(key_value):
			var view := RoadView.new()
			view.configure(0, tile, mask, false, "rival")
			view.position = tile_to_world(Vector2(tile)) + Vector3.UP * 0.015
			rival_roads_root.add_child(view)
			rival_road_views[key_value] = view
			rival_road_signatures[key_value] = signature
		elif String(rival_road_signatures.get(key_value, "")) != signature:
			(rival_road_views[key_value] as ProductionRoadView3D).configure(0, tile, mask, false, "rival")
			rival_road_signatures[key_value] = signature


func _sync_projectiles(snapshots: Array) -> void:
	var desired: Dictionary = {}
	for snapshot_value in snapshots:
		var snapshot: Dictionary = snapshot_value
		var id := String(snapshot.get("id", ""))
		desired[id] = true
		var from_world := tile_to_world(Vector2(snapshot.get("from", Vector2.ZERO)))
		var to_world := tile_to_world(Vector2(snapshot.get("to", Vector2.ZERO)))
		if not projectile_views.has(id):
			var view := ProjectileView.new()
			view.configure(snapshot, from_world, to_world)
			vfx_root.add_child(view)
			projectile_views[id] = view
		else:
			var projectile_view = projectile_views[id]
			projectile_view.apply_snapshot(snapshot, from_world, to_world)
	for id_value in projectile_views.keys():
		if desired.has(id_value):
			continue
		(projectile_views[id_value] as Node).queue_free()
		projectile_views.erase(id_value)


func _sync_decorative_props(prop_snapshots: Array) -> void:
	var desired: Dictionary = {}
	for snapshot_value in prop_snapshots:
		var snapshot: Dictionary = snapshot_value
		var id := int(snapshot.get("id", 0))
		desired[id] = snapshot
		if not decorative_prop_views.has(id):
			var prop_type := String(snapshot.get("type", ""))
			if not Catalog.WORKYARD_PROPS.has(prop_type):
				continue
			var packed := load(String(Catalog.WORKYARD_PROPS[prop_type])) as PackedScene
			if packed == null:
				continue
			var prop := packed.instantiate()
			prop.name = "DecorativeProp_%d_%s" % [id, prop_type]
			var tile := Vector2i(snapshot.get("position", Vector2i.ZERO))
			prop.position = tile_to_world(Vector2(tile))
			prop.rotation.y = deg_to_rad(float(snapshot.get("rotation", 0.0)))
			prop.scale = Vector3.ONE * float(snapshot.get("scale", 1.0)) * ScaleProfile.world_prop_scale(prop_type)
			resource_visuals_root.add_child(prop)
			decorative_prop_views[id] = prop
	for id_value in decorative_prop_views.keys():
		if desired.has(id_value):
			continue
		(decorative_prop_views[id_value] as Node).queue_free()
		decorative_prop_views.erase(id_value)


func _sync_gates(road_snapshots: Array) -> void:
	var desired: Dictionary = {}
	for snapshot_value in road_snapshots:
		var tile := Vector2i(Dictionary(snapshot_value).get("anchor", Vector2i.ZERO))
		if simulation.is_gate_tile(tile):
			desired[_tile_key(tile)] = tile
	for key_value in gate_views.keys():
		if desired.has(key_value):
			continue
		(gate_views[key_value] as Node).queue_free()
		gate_views.erase(key_value)
		gate_signatures.erase(key_value)
	for key_value in desired:
		var tile: Vector2i = desired[key_value]
		var horizontal: bool = bool(simulation._is_wall_tile(tile + Vector2i.LEFT)) and bool(simulation._is_wall_tile(tile + Vector2i.RIGHT))
		var signature := "%d:%d" % [int(horizontal), int(simulation.is_gate_closed())]
		if not gate_views.has(key_value) or String(gate_signatures.get(key_value, "")) != signature:
			if gate_views.has(key_value):
				(gate_views[key_value] as Node).queue_free()
			var gate := _create_gate_view(simulation.is_gate_closed())
			gate.name = "Gate_%s" % String(key_value).replace(",", "_")
			gate.position = tile_to_world(Vector2(tile))
			gate.rotation.y = PI * 0.5 if horizontal else 0.0
			gates_root.add_child(gate)
			gate_views[key_value] = gate
			gate_signatures[key_value] = signature


func _create_gate_view(closed: bool) -> Node3D:
	var root := Node3D.new()
	var stone := _simple_material(Color("#717468"), false)
	var wood := _simple_material(Color("#76503a"), false)
	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var post_mesh := BoxMesh.new()
		post_mesh.size = Vector3(0.72, 3.3, 0.72)
		post.mesh = post_mesh
		post.position = Vector3(side * 1.75, 1.65, 0.0)
		post.material_override = stone
		root.add_child(post)
	var beam := MeshInstance3D.new()
	var beam_mesh := BoxMesh.new()
	beam_mesh.size = Vector3(4.2, 0.58, 0.72)
	beam.mesh = beam_mesh
	beam.position = Vector3(0.0, 3.0, 0.0)
	beam.material_override = stone
	root.add_child(beam)
	for side in [-1.0, 1.0]:
		var door := MeshInstance3D.new()
		var door_mesh := BoxMesh.new()
		door_mesh.size = Vector3(1.55, 2.45, 0.20)
		door.mesh = door_mesh
		door.position = Vector3(side * (0.78 if closed else 1.42), 1.25, 0.0)
		door.rotation.y = 0.0 if closed else side * 1.05
		door.material_override = wood
		root.add_child(door)
	return root


func _sync_fog(force: bool) -> void:
	if simulation == null or fog_root == null:
		return
	var revealed_count: int = int(simulation.revealed_tiles.size())
	if not force and revealed_count == last_revealed_count:
		return
	last_revealed_count = revealed_count
	if revealed_count >= map_size.x * map_size.y:
		if fog_plane != null:
			fog_plane.visible = false
		if fog_screen != null:
			fog_screen.visible = false
		if fog_root != null:
			var under: Node = fog_root.get_node_or_null("FogUnderSheet")
			if under != null:
				under.visible = false
		for skirt in fog_skirts:
			if skirt != null:
				skirt.visible = false
		return
	# One texel owns one authoritative tile. A display copy is upsampled and
	# feathered so the isometric edge reads as mist instead of a sawtooth.
	var mask_size := Vector2i(ceili(float(map_size.x) / FOG_MASK_DIVISOR), ceili(float(map_size.y) / FOG_MASK_DIVISOR))
	var mask_bytes := PackedByteArray()
	mask_bytes.resize(mask_size.x * mask_size.y)
	for mask_y in mask_size.y:
		for mask_x in mask_size.x:
			var revealed_samples := 0
			var valid_samples := 0
			for offset_y in FOG_MASK_DIVISOR:
				for offset_x in FOG_MASK_DIVISOR:
					var sample := Vector2i(mask_x * FOG_MASK_DIVISOR + offset_x, mask_y * FOG_MASK_DIVISOR + offset_y)
					if simulation.is_inside_map(sample):
						valid_samples += 1
						if simulation.is_revealed(sample):
							revealed_samples += 1
			mask_bytes[mask_y * mask_size.x + mask_x] = roundi(255.0 * float(revealed_samples) / maxf(1.0, float(valid_samples)))
	var display_size := mask_size * FOG_DISPLAY_UPSAMPLE
	# Cubic reconstruction softens diagonal tile steps without expanding the
	# authoritative reveal set. Nature/entities still use simulation visibility.
	var mask := Image.create_from_data(mask_size.x, mask_size.y, false, Image.FORMAT_L8, mask_bytes)
	mask.resize(display_size.x, display_size.y, Image.INTERPOLATE_CUBIC)
	fog_mask_bytes = mask_bytes
	fog_mask_size = mask_size
	if fog_visibility_texture == null or fog_visibility_texture.get_width() != display_size.x or fog_visibility_texture.get_height() != display_size.y:
		fog_visibility_texture = ImageTexture.create_from_image(mask)
		if fog_material != null:
			fog_material.set_shader_parameter("visibility_texture", fog_visibility_texture)
		if fog_screen_material != null:
			fog_screen_material.set_shader_parameter("visibility_texture", fog_visibility_texture)
	else:
		fog_visibility_texture.update(mask)
	if fog_material == null:
		fog_material = ShaderMaterial.new()
		fog_material.shader = FogShader
		fog_material.set_shader_parameter("visibility_texture", fog_visibility_texture)
		fog_material.set_shader_parameter("unknown_color", FOG_UNKNOWN_BASE)
		fog_material.set_shader_parameter("mist_color", FOG_MIST_BASE)
		fog_material.set_shader_parameter("world_min_xz", _fog_world_min_xz())
		fog_material.set_shader_parameter("world_size_xz", _fog_world_size_xz())
		fog_material.render_priority = 20
	fog_material.set_shader_parameter("unknown_opacity", 1.0)
	fog_material.set_shader_parameter("edge_softness", 0.48)
	fog_material.set_shader_parameter("noise_strength", 0.22)
	fog_material.set_shader_parameter("shore_fade_metres", SHORE_FADE_METRES)
	_ensure_fog_volume()


func _ensure_fog_volume() -> void:
	# World-anchored sheet over the map. Off-map pixels stay clear so a corner
	# pan cannot look through unknown padding onto the settlement. Camera pan is
	# clamped to revealed land so the isometric view cannot fill with fog.
	var map_span := Vector2(map_size) * ScaleProfile.LOGICAL_CELL_METRES
	var cover := Vector2(map_span.x + 160.0, map_span.y + 160.0)
	var center := ScaleProfile.tile_to_flat_world(Vector2(map_size - Vector2i.ONE) * 0.5, map_size)
	if fog_plane == null:
		fog_plane = MeshInstance3D.new()
		fog_plane.name = "SmoothedAtmosphericUnknownMask"
		fog_root.add_child(fog_plane)
	var sheet := PlaneMesh.new()
	sheet.size = cover
	sheet.subdivide_width = 16
	sheet.subdivide_depth = 16
	fog_plane.mesh = sheet
	fog_plane.position = Vector3(center.x, 0.06, center.z)
	fog_plane.material_override = fog_material
	fog_plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fog_plane.extra_cull_margin = 96.0
	fog_plane.visible = true
	_ensure_fog_skirts()
	_hide_fog_screen()


func _ensure_fog_skirts() -> void:
	if fog_skirts.is_empty():
		for index in 4:
			var skirt := MeshInstance3D.new()
			skirt.name = "FogSkirt_%d" % index
			fog_root.add_child(skirt)
			fog_skirts.append(skirt)
	var skirt_material := StandardMaterial3D.new()
	skirt_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	skirt_material.albedo_color = Color("#1a3330")
	skirt_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var min_xz := _fog_world_min_xz()
	var size_xz := _fog_world_size_xz()
	var mid_x := min_xz.x + size_xz.x * 0.5
	var mid_z := min_xz.y + size_xz.y * 0.5
	var thickness := 8.0
	var outset := 6.0
	var layouts: Array[Dictionary] = [
		{"pos": Vector3(mid_x, FOG_VOLUME_CENTER_Y, min_xz.y - outset), "size": Vector3(size_xz.x + thickness * 2.0, FOG_VOLUME_HEIGHT_METRES, thickness)},
		{"pos": Vector3(mid_x, FOG_VOLUME_CENTER_Y, min_xz.y + size_xz.y + outset), "size": Vector3(size_xz.x + thickness * 2.0, FOG_VOLUME_HEIGHT_METRES, thickness)},
		{"pos": Vector3(min_xz.x - outset, FOG_VOLUME_CENTER_Y, mid_z), "size": Vector3(thickness, FOG_VOLUME_HEIGHT_METRES, size_xz.y + thickness * 2.0)},
		{"pos": Vector3(min_xz.x + size_xz.x + outset, FOG_VOLUME_CENTER_Y, mid_z), "size": Vector3(thickness, FOG_VOLUME_HEIGHT_METRES, size_xz.y + thickness * 2.0)},
	]
	for index in fog_skirts.size():
		var skirt: MeshInstance3D = fog_skirts[index]
		var wall := BoxMesh.new()
		wall.size = layouts[index]["size"]
		skirt.mesh = wall
		skirt.position = layouts[index]["pos"]
		skirt.material_override = skirt_material
		skirt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		skirt.extra_cull_margin = 24.0
		skirt.visible = false


func _hide_fog_screen() -> void:
	if fog_screen != null and is_instance_valid(fog_screen):
		fog_screen.visible = false
		fog_screen.queue_free()
	fog_screen = null
	if fog_overlay_camera != null:
		var leftover := fog_overlay_camera.get_node_or_null("ScreenFogOverlay")
		if leftover != null:
			leftover.queue_free()


func _ensure_fog_screen() -> void:
	_hide_fog_screen()


func _upsample_fog_mask(source: PackedByteArray, size: Vector2i, scale: int) -> PackedByteArray:
	var wide := size.x * scale
	var high := size.y * scale
	var scaled := PackedByteArray()
	scaled.resize(wide * high)
	for y in size.y:
		for x in size.x:
			var value: int = source[y * size.x + x]
			for offset_y in scale:
				for offset_x in scale:
					scaled[(y * scale + offset_y) * wide + (x * scale + offset_x)] = value
	return scaled


func _feather_fog_mask(source: PackedByteArray, size: Vector2i) -> PackedByteArray:
	var current := source.duplicate()
	var paints: Array[int] = [188, 128, 72, 36]
	var neighbor_floors: Array[int] = [210, 150, 90, 50]
	for pass_index in paints.size():
		var paint: int = paints[pass_index]
		var neighbor_floor: int = neighbor_floors[pass_index]
		var next := current.duplicate()
		for y in size.y:
			for x in size.x:
				var index := y * size.x + x
				if current[index] > 0:
					continue
				var adjacent := false
				for offset_y in range(-1, 2):
					for offset_x in range(-1, 2):
						if offset_x == 0 and offset_y == 0:
							continue
						var nx := x + offset_x
						var ny := y + offset_y
						if nx < 0 or ny < 0 or nx >= size.x or ny >= size.y:
							continue
						if current[ny * size.x + nx] >= neighbor_floor:
							adjacent = true
							break
					if adjacent:
						break
				if adjacent:
					next[index] = paint
		current = next
	return current


func _sync_claim_overlays(sources: Array, claims: Dictionary) -> void:
	var player_claim: Dictionary = claims.get("player", {})
	var rival_claim: Dictionary = claims.get("rival", {})
	var claim_relevant := claim_overlay_forced
	var contextual_relevant := claim_relevant or tower_overlay_visible
	var signature := "%d:%d:%d:%d:%d:%.2f:%.2f" % [int(claim_relevant), int(tower_overlay_visible), sources.size(), int(bool(player_claim.get("active", false))), int(bool(rival_claim.get("active", false))), tower_overlay_center.x, tower_overlay_center.y]
	if signature == claim_overlay_signature:
		return
	claim_overlay_signature = signature
	for child in claims_root.get_children():
		child.queue_free()
	if not contextual_relevant:
		return
	if tower_overlay_visible:
		var tower_ring := _create_world_ring(tower_overlay_radius * ScaleProfile.LOGICAL_CELL_METRES, Color(0.92, 0.64, 0.22, 0.22))
		tower_ring.name = "SelectedWatchtowerRange"
		tower_ring.position = tile_to_world(tower_overlay_center) + Vector3.UP * 0.10
		claims_root.add_child(tower_ring)
	if not claim_relevant:
		return
	for source_value in sources:
		var source: Dictionary = source_value
		var ring := _create_world_ring(float(source.get("radius", 0.0)) * ScaleProfile.LOGICAL_CELL_METRES, Color(0.25, 0.72, 0.78, 0.24) if String(source.get("realm", "")) == "player" else Color(0.72, 0.20, 0.28, 0.24))
		ring.position = tile_to_world(Vector2(source.get("center", Vector2.ZERO))) + Vector3.UP * 0.12
		claims_root.add_child(ring)
	var contested := bool(Dictionary(player_claim.get("requirements", {})).get("contested", false)) or bool(Dictionary(rival_claim.get("requirements", {})).get("contested", false))
	var claim_color := Color(0.94, 0.72, 0.22, 0.58) if not contested else Color(0.96, 0.18, 0.15, 0.72)
	var claim_ring := _create_world_ring(5.0 * ScaleProfile.LOGICAL_CELL_METRES, claim_color)
	claim_ring.position = tile_to_world(Vector2(simulation.shard_position)) + Vector3.UP * 0.18
	claims_root.add_child(claim_ring)


func _create_world_ring(radius: float, color: Color) -> MeshInstance3D:
	var ring := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = maxf(0.1, radius - 0.10)
	mesh.outer_radius = radius + 0.10
	mesh.rings = 64
	mesh.ring_segments = 6
	ring.mesh = mesh
	ring.material_override = _simple_material(color, true)
	return ring


func _simple_material(color: Color, unshaded: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _same_type_neighbors(tile: Vector2i, tile_type: String) -> int:
	var count := 0
	for oy in range(-1, 2):
		for ox in range(-1, 2):
			if ox == 0 and oy == 0:
				continue
			var sample := tile + Vector2i(ox, oy)
			if simulation.is_inside_map(sample) and String(simulation.get_tile(sample)) == tile_type:
				count += 1
	return count


func apply_quality_profile(quality: Dictionary) -> void:
	foliage_density = clampf(float(quality.get("foliage_density", foliage_density)), 0.25, 1.0)
	water_detail = clampf(float(quality.get("water_detail", water_detail)), 0.2, 1.0)
	if water_material != null:
		water_material.set_shader_parameter("wave", 0.035 * water_detail)
	if simulation == null:
		return
	_rebuild_edge_forest(true)
	_rebuild_grass_multimeshes()


func apply_light_palette(palette: Dictionary) -> void:
	var window_color: Color = palette.get("window_color", Color("#FFB347"))
	var torch_color: Color = palette.get("torch_color", Color("#FFC36B"))
	var torch_range := float(palette.get("torch_range", 5.5))
	var atmosphere := clampf(float(palette.get("atmosphere_scale", 1.0)), 0.15, 1.0)
	_atmosphere_scale = atmosphere
	if fog_material != null:
		fog_material.set_shader_parameter("unknown_color", FOG_UNKNOWN_BASE * atmosphere)
		fog_material.set_shader_parameter("mist_color", FOG_MIST_BASE * atmosphere)
	if fog_screen_material != null:
		fog_screen_material.set_shader_parameter("unknown_color", FOG_UNKNOWN_BASE * atmosphere)
		fog_screen_material.set_shader_parameter("mist_color", FOG_MIST_BASE * atmosphere)
	if boundary_mist_material != null:
		boundary_mist_material.set_shader_parameter("color_scale", atmosphere)
	if water_material != null:
		water_material.set_shader_parameter("atmosphere", atmosphere)
		water_material.set_shader_parameter("lod_cheap", float(palette.get("terrain_lod_cheap", 0.0)))
		water_material.set_shader_parameter("wave", 0.035 * water_detail * (0.0 if float(palette.get("terrain_lod_cheap", 0.0)) > 0.5 else 1.0))
		var horizon: Color = palette.get("ground_bottom", Color("#2A464A"))
		water_material.set_shader_parameter("horizon_color", Vector3(horizon.r, horizon.g, horizon.b))
	if horizon_root != null:
		for child in horizon_root.get_children():
			if child is MeshInstance3D:
				var hill_mat := (child as MeshInstance3D).material_override
				if hill_mat is ShaderMaterial:
					(hill_mat as ShaderMaterial).set_shader_parameter("atmosphere", atmosphere)
				elif hill_mat is StandardMaterial3D:
					var base := Color("#243028")
					(hill_mat as StandardMaterial3D).albedo_color = base * clampf(atmosphere, 0.35, 1.0)
	_ground_tint = palette.get("ground_tint", Color(1.0, 1.0, 1.0))
	if terrain_mesh_instance != null and terrain_mesh_instance.material_override is ShaderMaterial:
		var ground_mat := terrain_mesh_instance.material_override as ShaderMaterial
		ground_mat.set_shader_parameter("light_tint", Vector3(_ground_tint.r, _ground_tint.g, _ground_tint.b))
		ground_mat.set_shader_parameter("tint_floor", float(palette.get("ground_tint_floor", 0.0)))
		ground_mat.set_shader_parameter("tint_wash_lo", float(palette.get("ground_wash_lo", 0.70)))
		ground_mat.set_shader_parameter("tint_wash_hi", float(palette.get("ground_wash_hi", 0.94)))
		ground_mat.set_shader_parameter("lod_cheap", float(palette.get("terrain_lod_cheap", 0.0)))
	# Night/reckoning: hide road stamps. Clay reads as terrain at night
	# and the extra MultiMeshes are wasted fill-rate on lavapipe.
	if road_stamp_root != null:
		road_stamp_root.visible = float(palette.get("terrain_lod_cheap", 0.0)) < 0.5
	if edge_forest_root != null:
		for child in edge_forest_root.get_children():
			if child is MultiMeshInstance3D:
				var mat := (child as MultiMeshInstance3D).material_override
				if mat is ShaderMaterial:
					(mat as ShaderMaterial).set_shader_parameter("atmosphere", atmosphere)
				elif mat is StandardMaterial3D:
					# Palette scale: day 1.0, dusk 0.55, night 0.35. Lit, not a cut-out.
					(mat as StandardMaterial3D).albedo_color = Color("#1c332c") * atmosphere
	for view in building_views.values():
		if view.has_method("apply_light_palette"):
			view.apply_light_palette(window_color, torch_color, torch_range)
	for view in rivalry_structure_views.values():
		if view.has_method("apply_light_palette"):
			view.apply_light_palette(window_color, torch_color, torch_range)


func _rebuild_water() -> void:
	# The Director: G1 sea. A huge unshaded plane so max zoom never sees
	# a disk or diamond rim. Colour fades into the sky-ground.
	if water_root == null or map_size == Vector2i.ZERO:
		return
	if water_mesh_instance != null:
		water_mesh_instance.queue_free()
		water_mesh_instance = null
	var existing := water_root.get_node_or_null("ShoreBand")
	if existing != null:
		existing.queue_free()
	var plane := PlaneMesh.new()
	plane.size = Vector2(WATER_PAD_METRES * 2.0, WATER_PAD_METRES * 2.0)
	plane.subdivide_width = 12 if water_detail >= 0.7 else 6
	plane.subdivide_depth = 12 if water_detail >= 0.7 else 6
	water_mesh_instance = MeshInstance3D.new()
	water_mesh_instance.name = "IslandWater"
	water_mesh_instance.mesh = plane
	var center := ScaleProfile.tile_to_flat_world(Vector2(map_size - Vector2i.ONE) * 0.5, map_size)
	water_mesh_instance.position = Vector3(center.x, WATER_Y, center.z)
	water_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water_mesh_instance.extra_cull_margin = 800.0
	water_material = ShaderMaterial.new()
	water_material.shader = WaterShader
	water_material.set_shader_parameter("world_min_xz", _fog_world_min_xz())
	water_material.set_shader_parameter("world_size_xz", _fog_world_size_xz())
	water_material.set_shader_parameter("atmosphere", _atmosphere_scale)
	water_material.set_shader_parameter("wave", 0.035 * water_detail)
	water_material.set_shader_parameter("foam_metres", 4.8)
	water_material.set_shader_parameter("beach_margin_metres", BEACH_MARGIN_METRES)
	water_material.set_shader_parameter("coast_jut_metres", COAST_JUT_METRES)
	water_material.set_shader_parameter("fade_start", 70.0)
	water_material.set_shader_parameter("fade_end", 380.0)
	water_material.set_shader_parameter("horizon_color", Vector3(0.145, 0.240, 0.255))
	water_material.set_shader_parameter("deep_color", Vector3(0.12, 0.28, 0.30))
	water_material.set_shader_parameter("shallow_color", Vector3(0.18, 0.38, 0.36))
	water_mesh_instance.material_override = water_material
	water_root.add_child(water_mesh_instance)


func _rebuild_world_rim(force: bool) -> void:
	# No continuous wall. A strip along the AABB reads as a tan plate at
	# far zoom. The shader iso-line outside the playable AABB is the coast.
	if rim_mesh_instance != null:
		rim_mesh_instance.queue_free()
		rim_mesh_instance = null
	if force:
		rim_signature = ""


func _coast_noise(world_xz: Vector2) -> float:
	return sin(world_xz.x * 0.048 + world_xz.y * 0.037 + 0.41) * 0.42 \
		+ sin(world_xz.x * 0.11 + world_xz.y * 0.07 + 1.27) * 0.32 \
		+ sin(world_xz.x * 0.031 - world_xz.y * 0.045 + 2.19) * 0.18 \
		+ sin((world_xz.x + world_xz.y) * 0.019) * 0.08


func _world_inward_metres(world_xz: Vector2) -> float:
	var minimum := _fog_world_min_xz()
	var size := _fog_world_size_xz()
	return minf(
		minf(world_xz.x - minimum.x, minimum.x + size.x - world_xz.x),
		minf(world_xz.y - minimum.y, minimum.y + size.y - world_xz.y)
	)


func island_land_metres(world_xz: Vector2) -> float:
	# Shore sits outside the playable AABB as a rounded rectangle: straight
	# edges keep a 2-tile beach, corners are quarter-circles of that radius.
	# Jut only grows the beach seaward. Must match the water/ground shaders.
	var minimum := _fog_world_min_xz()
	var size := _fog_world_size_xz()
	var center := minimum + size * 0.5
	var half := size * 0.5
	var q := Vector2(absf(world_xz.x - center.x) - half.x, absf(world_xz.y - center.y) - half.y)
	var sd := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - BEACH_MARGIN_METRES
	var jut := maxf(0.0, _coast_noise(world_xz)) * COAST_JUT_METRES
	return -sd + jut


func playable_tile_is_on_land(tile: Vector2i) -> bool:
	if map_size == Vector2i.ZERO or simulation == null or not simulation.is_inside_map(tile):
		return false
	var center := ScaleProfile.tile_to_flat_world(Vector2(tile), map_size)
	return island_land_metres(Vector2(center.x, center.z)) >= BEACH_MARGIN_METRES


func _island_land(world_xz: Vector2) -> float:
	return island_land_metres(world_xz)


func _is_coastal_water_tile(tile: Vector2i) -> bool:
	if map_size == Vector2i.ZERO:
		return false
	var center := ScaleProfile.tile_to_flat_world(Vector2(tile), map_size)
	return island_land_metres(Vector2(center.x, center.z)) <= 0.0


func _rebuild_beach_apron() -> void:
	# High-segment ring outside the playable slab. The shader iso-line is
	# the shore — not a saw of 2.5 m tiles.
	if terrain_root == null or map_size == Vector2i.ZERO:
		return
	if beach_apron_instance != null:
		beach_apron_instance.queue_free()
		beach_apron_instance = null
	var leftover := terrain_root.get_node_or_null("BeachApron")
	if leftover != null:
		leftover.queue_free()
	var size_xz := _fog_world_size_xz()
	var plane := PlaneMesh.new()
	plane.size = size_xz + Vector2(BEACH_APRON_PAD_METRES * 2.0, BEACH_APRON_PAD_METRES * 2.0)
	plane.subdivide_width = 96
	plane.subdivide_depth = 96
	beach_apron_instance = MeshInstance3D.new()
	beach_apron_instance.name = "BeachApron"
	beach_apron_instance.mesh = plane
	var center := ScaleProfile.tile_to_flat_world(Vector2(map_size - Vector2i.ONE) * 0.5, map_size)
	beach_apron_instance.position = Vector3(center.x, 0.0, center.z)
	beach_apron_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beach_apron_instance.extra_cull_margin = 48.0
	var material := ShaderMaterial.new()
	material.shader = preload("res://src/GodotClient3D/Shaders/settlement_ground.gdshader")
	material.set_shader_parameter("light_tint", Vector3(_ground_tint.r, _ground_tint.g, _ground_tint.b))
	material.set_shader_parameter("tint_floor", 0.0)
	material.set_shader_parameter("macro_metres", 14.0)
	material.set_shader_parameter("detail_metres", 1.2)
	material.set_shader_parameter("macro_amount", 0.12)
	material.set_shader_parameter("detail_amount", 0.052)
	material.set_shader_parameter("dirt_amount", 0.22)
	material.set_shader_parameter("world_min_xz", _fog_world_min_xz())
	material.set_shader_parameter("world_size_xz", size_xz)
	material.set_shader_parameter("beach_margin_metres", BEACH_MARGIN_METRES)
	material.set_shader_parameter("coast_jut_metres", COAST_JUT_METRES)
	material.set_shader_parameter("apron_mode", 1.0)
	beach_apron_instance.material_override = material
	terrain_root.add_child(beach_apron_instance)


func _neighbor_is_open_water(neighbor: Vector2i) -> bool:
	if not simulation.is_inside_map(neighbor):
		return true
	return _is_coastal_water_tile(neighbor) and not _terrain_occupied_cache.has(_tile_key(neighbor))


func _borders_open_water(tile: Vector2i) -> bool:
	for direction in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
		if _neighbor_is_open_water(tile + direction):
			return true
	return false


func _add_rim_face(surface: SurfaceTool, tile: Vector2i, outward: Vector2i) -> int:
	# The Director: the slab edge is world geography, not a discovery.
	# Fog still covers unrevealed coast tiles; the rim is there so far
	# zoom reads as an island instead of a paper cut-out.
	if simulation == null or not simulation.is_inside_map(tile):
		return 0
	var center := ScaleProfile.tile_to_flat_world(Vector2(tile), map_size)
	var half := ScaleProfile.LOGICAL_CELL_METRES * 0.5
	var top_y := float(simulation.get_height(tile)) * ScaleProfile.TERRAIN_ELEVATION_UNIT_METRES
	var corners := [
		Vector3(center.x - half, top_y, center.z - half),
		Vector3(center.x + half, top_y, center.z - half),
		Vector3(center.x + half, top_y, center.z + half),
		Vector3(center.x - half, top_y, center.z + half),
	]
	var a: Vector3
	var b: Vector3
	if outward.y < 0:
		a = corners[1]
		b = corners[0]
	elif outward.x > 0:
		a = corners[2]
		b = corners[1]
	elif outward.y > 0:
		a = corners[3]
		b = corners[2]
	else:
		a = corners[0]
		b = corners[3]
	var outward_dir := Vector2(float(outward.x), float(outward.y))
	var tangent := Vector2(float(-outward.y), float(outward.x))
	var jut_a := _coast_offset(Vector2(a.x, a.z), outward_dir, tangent)
	var jut_b := _coast_offset(Vector2(b.x, b.z), outward_dir, tangent)
	var down_a := Vector3(a.x, WATER_Y - 0.04, a.z) + jut_a
	var down_b := Vector3(b.x, WATER_Y - 0.04, b.z) + jut_b
	var lip_a := a + jut_a * 0.22
	var lip_b := b + jut_b * 0.22
	var rock_weight := 0
	for oy in range(-2, 3):
		for ox in range(-2, 3):
			var sample := tile + Vector2i(ox, oy)
			if simulation.is_inside_map(sample) and String(simulation.get_tile(sample)) == Defs.TILE_ROCK:
				rock_weight += 1
	var height_units := int(simulation.get_height(tile))
	var jut_len := jut_a.length()
	var cliff: bool = rock_weight >= 3 or height_units >= 2 or jut_len >= 14.0
	var color := Color("#4A4840") if cliff else Color("#6A5E4C")
	color = color.darkened(0.04 + float(_tile_hash(tile, 33) % 14) / 130.0)
	var normal := Vector3(float(outward.x), 0.16 if cliff else 0.42, float(outward.y)).normalized()
	_add_quad(surface, lip_a, lip_b, down_b, down_a, normal, color)
	if cliff:
		_add_quad(surface, a, b, lip_b, lip_a, Vector3.UP, Color("#3E4038").darkened(0.08))
	return 1


func _coast_offset(world_xz: Vector2, outward: Vector2, tangent: Vector2) -> Vector3:
	# Shared by neighbouring rim faces so the shore is one irregular line.
	var seed := float(visual_seed % 97) * 0.13
	var n1 := sin(world_xz.x * 0.11 + world_xz.y * 0.07 + seed)
	var n2 := sin(world_xz.x * 0.031 - world_xz.y * 0.045 + seed * 1.7)
	var n3 := sin((world_xz.x + world_xz.y) * 0.019 + seed * 0.4)
	var jut := clampf(6.0 + n1 * 8.0 + n2 * 10.0 + n3 * 7.0, 1.2, 28.0)
	var wobble := sin(world_xz.x * 0.21 + world_xz.y * 0.17 + seed) * 2.4
	return Vector3(outward.x, 0.0, outward.y) * jut + Vector3(tangent.x, 0.0, tangent.y) * wobble


func _rebuild_horizon() -> void:
	# Low-detail hills just past the fog pad so far zoom is sea + sky, not void.
	if horizon_root == null or map_size == Vector2i.ZERO:
		return
	for child in horizon_root.get_children():
		horizon_root.remove_child(child)
		child.free()
	var center := ScaleProfile.tile_to_flat_world(Vector2(map_size - Vector2i.ONE) * 0.5, map_size)
	var rings := [
		{"count": 10, "radius": HORIZON_RADIUS_METRES, "h": 8.0, "w": 40.0},
		{"count": 8, "radius": HORIZON_RADIUS_METRES + 110.0, "h": 11.0, "w": 54.0},
	]
	var hill_index := 0
	for ring_value in rings:
		var ring: Dictionary = ring_value
		var count := int(ring["count"])
		for index in count:
			var angle := TAU * float(index) / float(count) + float((visual_seed + hill_index) % 17) * 0.03
			var radius := float(ring["radius"]) + float((visual_seed + hill_index * 13) % 16)
			var hill := MeshInstance3D.new()
			hill.name = "HorizonHill_%d" % hill_index
			var mesh := SphereMesh.new()
			var width := float(ring["w"]) + float((index * 7 + visual_seed) % 10)
			var height := float(ring["h"]) + float((index * 11 + visual_seed) % 5)
			mesh.radius = width * 0.62
			mesh.height = height
			mesh.radial_segments = 16
			mesh.rings = 8
			hill.mesh = mesh
			hill.position = Vector3(center.x + cos(angle) * radius, WATER_Y + height * 0.22, center.z + sin(angle) * radius)
			hill.scale = Vector3(1.55, 0.34, 1.20)
			hill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			hill.extra_cull_margin = 180.0
			var material := StandardMaterial3D.new()
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			var tone := Color("#3A4A42") if hill_index % 3 != 0 else Color("#354048")
			material.albedo_color = tone * clampf(_atmosphere_scale, 0.45, 1.0)
			hill.material_override = material
			horizon_root.add_child(hill)
			hill_index += 1


# The Director: a dark teal conifer mass outside the playable map only.
# Never spawn on unrevealed interior tiles — those pop when revealed.
func _rebuild_edge_forest(force: bool) -> void:
	if simulation == null or edge_forest_root == null:
		return
	var signature := "%d:%d:%.2f" % [int(simulation.revealed_tiles.size()), map_size.x * map_size.y, foliage_density]
	if not force and signature == edge_forest_signature:
		return
	edge_forest_signature = signature
	for child in edge_forest_root.get_children():
		edge_forest_root.remove_child(child)
		child.free()
	var transforms_by_path: Dictionary = {}
	var floors: Array = []
	var step := 1 if foliage_density >= 0.75 else 2
	for ring in range(1, 4):
		for x in range(-ring, map_size.x + ring, step):
			_append_edge_tree(transforms_by_path, _edge_tree_path(x, -ring, ring), Vector2(float(x), float(-ring)), ring)
			_append_edge_tree(transforms_by_path, _edge_tree_path(x, map_size.y - 1 + ring, ring), Vector2(float(x), float(map_size.y - 1 + ring)), ring)
		for y in range(-ring + 1, map_size.y + ring - 1, step):
			_append_edge_tree(transforms_by_path, _edge_tree_path(-ring, y, ring), Vector2(float(-ring), float(y)), ring)
			_append_edge_tree(transforms_by_path, _edge_tree_path(map_size.x - 1 + ring, y, ring), Vector2(float(map_size.x - 1 + ring), float(y)), ring)
	_spawn_nature_multimeshes(edge_forest_root, transforms_by_path)
	for child in edge_forest_root.get_children():
		if child is MultiMeshInstance3D:
			(child as MultiMeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Darker forest floor under every fourth canopy. One MultiMesh, not Decals.
	for path_value in transforms_by_path:
		var batch: Array = transforms_by_path[path_value]
		for index in batch.size():
			if index % 4 != 0:
				continue
			floors.append(ContactAO.flatten_transform(batch[index], 2.1))
	ContactAO.spawn_multimesh(edge_forest_root, floors, 0.20)


func _append_edge_tree(groups: Dictionary, path_value: String, logical: Vector2, ring: int, index := 0) -> void:
	var key_tile := Vector2i(roundi(logical.x), roundi(logical.y))
	var clamped := Vector2(clampf(logical.x, 0.0, float(maxi(0, map_size.x - 1))), clampf(logical.y, 0.0, float(maxi(0, map_size.y - 1))))
	var edge_tile := Vector2i(roundi(clamped.x), roundi(clamped.y))
	if simulation == null or not simulation.is_revealed(edge_tile):
		return
	if not groups.has(path_value):
		groups[path_value] = []
	var world_position := ScaleProfile.tile_to_flat_world(logical, map_size)
	var xz := Vector2(world_position.x, world_position.z)
	if _island_land(xz) <= 0.0:
		return
	world_position.y = height_at_logical(clamped)
	var jitter := _deterministic_offset(key_tile, 80 + ring + index, 0.55)
	world_position += Vector3(jitter.x, 0.0, jitter.y)
	# Scale so canopies clear the y=2.0 boundary-mist plane.
	var scale_value := (2.05 + float(_tile_hash(key_tile, 90 + ring + index) % 55) / 100.0 + float(ring) * 0.18) * ScaleProfile.nature_model_scale(path_value)
	var yaw := float(_tile_hash(key_tile, 110 + ring + index) % 628) / 100.0
	var basis := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scale_value)
	(groups[path_value] as Array).append(Transform3D(basis, world_position))


func _unrevealed_touches_revealed(tile: Vector2i) -> bool:
	for oy in range(-1, 2):
		for ox in range(-1, 2):
			if ox == 0 and oy == 0:
				continue
			var sample := tile + Vector2i(ox, oy)
			if simulation.is_inside_map(sample) and simulation.is_revealed(sample):
				return true
	return false


func _edge_tree_path(x: int, y: int, ring: int) -> String:
	var n := Catalog.EDGE_TREES.size()
	if n <= 0:
		return String(Catalog.TREES[0])
	return String(Catalog.EDGE_TREES[_tile_hash(Vector2i(x, y), 17 + ring) % n])


func _foliage_material(mesh: Mesh, path_value: String) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = FoliageShader
	var tint := Color("#355544")
	if String(path_value).contains("broadleaf") or String(path_value).contains("Tree_3"):
		tint = Color("#4A5A30")
	elif String(path_value).contains("Tree_4"):
		tint = Color("#3A4A2C")
	elif String(path_value).contains("Tree_2"):
		tint = Color("#2E4A38")
	material.set_shader_parameter("albedo_color", Vector3(tint.r, tint.g, tint.b))
	material.set_shader_parameter("atmosphere", _atmosphere_scale)
	material.set_shader_parameter("wind", 0.07)
	if mesh != null and mesh.get_surface_count() > 0:
		var source := mesh.surface_get_material(0)
		if source is StandardMaterial3D and (source as StandardMaterial3D).albedo_texture != null:
			material.set_shader_parameter("has_texture", 1.0)
			material.set_shader_parameter("albedo_tex", (source as StandardMaterial3D).albedo_texture)
	return material


func _edge_forest_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	# The Director: firs take scene light and the period scale (1.0 / 0.55 / 0.35).
	material.albedo_color = Color("#1c332c") * _atmosphere_scale
	material.roughness = 0.94
	material.metallic = 0.0
	material.emission_enabled = false
	return material


func _rebuild_building_halos(force: bool) -> void:
	if simulation == null or halo_root == null:
		return
	var signature := "r%d" % int(simulation.connected_roads.size())
	for building_value in simulation.get_buildings():
		var building: Dictionary = building_value
		signature += ":%d:%s:%d:%d" % [
			int(building.get("id", 0)),
			String(building.get("type", "")),
			int(bool(building.get("construction", false))),
			int(building.get("rotation", 0))
		]
	if not force and signature == halo_signature:
		return
	halo_signature = signature
	var next := HaloCatalog.resolve_world(simulation)
	halo_placements = next
	for child in halo_root.get_children():
		halo_root.remove_child(child)
		child.free()
	var transforms_by_path: Dictionary = {}
	for placement_value in halo_placements:
		var placement: Dictionary = placement_value
		var path_value := HaloCatalog.prop_path(String(placement.get("prop", "")))
		if path_value == "":
			continue
		if not transforms_by_path.has(path_value):
			transforms_by_path[path_value] = []
		var tile: Vector2i = placement.get("tile", Vector2i.ZERO)
		var world_position := tile_to_world(Vector2(tile))
		var nudge: Vector2 = placement.get("nudge", Vector2.ZERO)
		world_position += Vector3(nudge.x, 0.0, nudge.y)
		var scale_value := float(placement.get("scale", 1.0)) * ScaleProfile.world_prop_scale(String(placement.get("prop", "")))
		var basis := Basis(Vector3.UP, deg_to_rad(float(placement.get("yaw", 0.0)))).scaled(Vector3.ONE * scale_value)
		(transforms_by_path[path_value] as Array).append(Transform3D(basis, world_position))
	_spawn_nature_multimeshes(halo_root, transforms_by_path)


func halo_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for placement_value in halo_placements:
		tiles.append(Vector2i(Dictionary(placement_value).get("tile", Vector2i.ZERO)))
	return tiles


func _deterministic_offset(tile: Vector2i, index: int, radius: float) -> Vector2:
	var angle := float(_tile_hash(tile, index * 37 + 7) % 628) / 100.0
	var distance := radius * (0.35 + float(_tile_hash(tile, index * 53 + 11) % 66) / 100.0)
	return Vector2(cos(angle), sin(angle)) * distance


func _tile_hash(tile: Vector2i, salt: int) -> int:
	var value := int(visual_seed) ^ (tile.x * 73856093) ^ (tile.y * 19349663) ^ (salt * 83492791)
	value = int((value ^ (value >> 13)) * 1274126177)
	return absi(value)


func _tile_key(tile: Vector2i) -> String:
	return "%d,%d" % [tile.x, tile.y]


func _tile_from_key(key: String) -> Vector2i:
	var parts := key.split(",")
	return Vector2i(int(parts[0]), int(parts[1])) if parts.size() == 2 else Vector2i.ZERO


func _instantiate_cached(path_value: String) -> Node3D:
	if not packed_cache.has(path_value):
		packed_cache[path_value] = load(path_value) as PackedScene
	var packed: PackedScene = packed_cache[path_value]
	return packed.instantiate() as Node3D if packed != null else null


func _sync_map_markers() -> void:
	var host := get_node_or_null("MapMarkers")
	if host == null:
		host = Node3D.new()
		host.name = "MapMarkers"
		add_child(host)
	for child in host.get_children():
		child.queue_free()
	if simulation == null or not simulation.has_method("get_map_markers"):
		return
	for marker_value in simulation.get_map_markers():
		var marker: Dictionary = marker_value
		var tile: Vector2i = marker.get("position", Vector2i.ZERO)
		var label := Label3D.new()
		label.text = String(marker.get("title", "?"))
		label.font_size = 28
		label.modulate = Color("#efcf8a") if String(marker.get("kind", "")) != "skull" else Color("#f0a06e")
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.position = tile_to_world(Vector2(tile)) + Vector3.UP * 2.4
		host.add_child(label)
