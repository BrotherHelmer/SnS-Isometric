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
const BuildingMaterials = preload("res://src/GodotClient3D/Scripts/production_building_materials.gd")
const Identity = preload("res://src/GodotClient3D/Scripts/production_identity.gd")
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
const COAST_JUT_METRES := 14.0
const BEACH_APRON_PAD_METRES := 36.0
const SHORE_FADE_METRES := 4.0
const HORIZON_RADIUS_METRES := 420.0
const FOG_VOLUME_HEIGHT_METRES := 56.0
const FOG_VOLUME_CENTER_Y := 18.0
const FOG_DISPLAY_UPSAMPLE := 8
const FOG_UNKNOWN_BASE := Vector3(0.090, 0.153, 0.165) # #17272A
const FOG_MIST_BASE := Vector3(0.090, 0.153, 0.165) # #17272A
const FOG_VISIBLE := 0
const FOG_EXPLORED := 115
const FOG_UNEXPLORED := 255
const GROUND_PATCH_CHUNK_METRES := 40.0

var simulation
var map_size := Vector2i.ZERO
var visual_seed := 1
var foliage_density := 1.0
var grass_density := 1.0
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
var ground_patch_root: Node3D
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
var terrain_occupation_signature := 0
var real_worker_count := 0
var active_worker_count := 0
var animated_civilian_count := 0
var carriers_with_cargo := 0
var construction_activity_count := 0
var last_revealed_count := -1
var last_fog_signature := ""
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
var _terrain_road_cache: Dictionary = {}
var _terrain_farm_cache: Dictionary = {}
var _terrain_color_grid: PackedColorArray = PackedColorArray()
var _terrain_lookups_ready := false
var _atmosphere_scale := 1.0
var _ground_tint := Color(1.0, 1.0, 1.0)
var road_control_texture: ImageTexture
var road_debug_enabled := false
var terrain_debug_mode := 0
const ROAD_CONTROL_RES := 512


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
		ground_patch_root = null
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
		last_fog_signature = ""
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
		_terrain_yard_cache.clear()
		_terrain_occupied_cache.clear()
		_terrain_farm_cache.clear()
		_terrain_road_cache.clear()
		_terrain_color_grid = PackedColorArray()
		_terrain_lookups_ready = false
	simulation = simulation_value
	map_size = Vector2i(world_snapshot.get("map_size", Vector2i.ZERO))
	visual_seed = int(world_snapshot.get("seed", 1))
	foliage_density = clampf(float(quality.get("foliage_density", 1.0)), 0.25, 1.0)
	grass_density = clampf(float(quality.get("grass_density", quality.get("foliage_density", 1.0))), 0.25, 1.0)
	water_detail = clampf(float(quality.get("water_detail", 1.0)), 0.2, 1.0)
	civilian_animation_budget = maxi(12, roundi(32.0 * clampf(float(quality.get("animation_lod", 1.0)), 0.4, 1.0)))
	_create_roots()
	_rebuild_terrain()
	_rebuild_water()
	_rebuild_world_rim(true)
	_rebuild_horizon()
	_sync_nature(true)
	_sync_grass(true)
	_rebuild_ground_patches()
	_sync_fog(true)
	_rebuild_edge_forest(true)
	_rebuild_opening_dressing()
	_rebuild_building_halos(true)
	_create_shard_marker()


func bind_fog_overlay(_camera: Camera3D) -> void:
	fog_overlay_camera = _camera
	if fog_visibility_texture != null:
		_ensure_fog_screen()


func sync_frame(frame_snapshot: Dictionary) -> void:
	# One lookup pass per frame. GFX-E corner averaging used to call
	# _terrain_color ~16× per cell, and each call scanned every building
	# for roads — that is the 8 s new-game / 112 s showcase first-frame.
	_refresh_terrain_lookups()
	var next_height_signature := _calculate_height_signature()
	var next_occupation := _calculate_occupation_signature()
	if next_height_signature != terrain_height_signature:
		_rebuild_terrain()
	elif next_occupation != terrain_occupation_signature:
		_rebake_terrain_occupation()
	var revealed_count := int(frame_snapshot.get("revealed_count", simulation.revealed_tiles.size()))
	var reveal_changed := revealed_count != last_revealed_count
	# One nature rebuild even when both layout and FOW change (showcase).
	_sync_nature(reveal_changed)
	_sync_grass(false)
	_sync_fog(false)
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
	if reveal_changed:
		_rebuild_edge_forest(false)
		_rebuild_world_rim(false)
		_rebuild_ground_patches()


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
		"edge_feather_cells": 1.25,
		"noise_strength": 0.12,
		"unknown_opacity": 1.0,
		"visible_alpha": 0.0,
		"explored_alpha": 0.55,
		"explored_brightness": 0.45,
		"unexplored_alpha": 1.0,
		"terrain_under_shroud": beach_apron_instance != null,
		"unknown_color": FOG_UNKNOWN_BASE,
		"mist_color": FOG_MIST_BASE,
		"haze_reverted": true,
		"screen_composited": fog_screen != null and fog_screen.visible,
		"world_anchored": false,
		"zoom_cap": 1.5,
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
	# Texture stores shroud (0 visible / 0.45 explored / 1 unexplored).
	# Callers still want visibility, so invert.
	return 1.0 - float(fog_mask_bytes[mask_tile.y * fog_mask_size.x + mask_tile.x]) / 255.0


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
	ground_patch_root = _named_root("GroundPatches")
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


func _refresh_terrain_lookups() -> void:
	# O(buildings + roads) once. _is_road_tile used to walk every building
	# for every tile / corner sample.
	_terrain_yard_cache = _yard_tiles(3)
	_terrain_occupied_cache = _structure_tiles()
	_terrain_road_cache.clear()
	if simulation != null:
		if simulation.connected_roads != null:
			for key_value in simulation.connected_roads.keys():
				_terrain_road_cache[String(key_value)] = true
		for building_value in simulation.get_buildings():
			var building: Dictionary = building_value
			if String(building.get("type", "")) == Defs.BUILDING_ROAD:
				_terrain_road_cache[_tile_key(Vector2i(building.get("position", Vector2i.ZERO)))] = true
	_terrain_lookups_ready = true
	_terrain_farm_cache = _farm_field_tiles()


func _precompute_terrain_colors() -> void:
	var count := map_size.x * map_size.y
	_terrain_color_grid.resize(count)
	for y in range(map_size.y):
		for x in range(map_size.x):
			_terrain_color_grid[y * map_size.x + x] = _compute_terrain_color(Vector2i(x, y))


func _cached_terrain_color(tile: Vector2i) -> Color:
	if map_size.x <= 0 or _terrain_color_grid.size() != map_size.x * map_size.y:
		return _compute_terrain_color(tile)
	if tile.x < 0 or tile.y < 0 or tile.x >= map_size.x or tile.y >= map_size.y:
		return _compute_terrain_color(tile)
	return _terrain_color_grid[tile.y * map_size.x + tile.x]


func _rebuild_terrain() -> void:
	_refresh_terrain_lookups()
	_precompute_terrain_colors()
	_bake_road_control_texture()
	_commit_terrain_mesh(true)
	_rebuild_beach_apron()


func _rebake_terrain_occupation() -> void:
	# Heights unchanged: recolor the slab, keep the picker collision.
	# Showcase stamps 15 buildings + roads; a full remesh+concave rebuild
	# after each occupation signature used to stall the first frame.
	_refresh_terrain_lookups()
	_precompute_terrain_colors()
	_bake_road_control_texture()
	_commit_terrain_mesh(false)


func _commit_terrain_mesh(rebuild_collision: bool) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for y in range(map_size.y):
		for x in range(map_size.x):
			_add_terrain_cell(surface, Vector2i(x, y))
	var mesh := surface.commit()
	if terrain_mesh_instance == null or not is_instance_valid(terrain_mesh_instance):
		if terrain_mesh_instance != null:
			terrain_mesh_instance.queue_free()
		terrain_mesh_instance = MeshInstance3D.new()
		terrain_mesh_instance.name = "ContinuousTerrain"
		terrain_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_apply_ground_material(terrain_mesh_instance)
		terrain_root.add_child(terrain_mesh_instance)
	terrain_mesh_instance.mesh = mesh
	if rebuild_collision:
		_rebuild_terrain_collision(mesh)
	# G1: the teal OuterWildernessFloor was the box-like void. Water + rim
	# + horizon replace it. Unexplored still sits under #47 fog.
	boundary_mist_material = null
	terrain_height_signature = _calculate_height_signature()
	terrain_occupation_signature = _calculate_occupation_signature()


func _apply_ground_material(host: MeshInstance3D) -> void:
	var material := ShaderMaterial.new()
	material.shader = preload("res://src/GodotClient3D/Shaders/settlement_ground.gdshader")
	material.set_shader_parameter("light_tint", Vector3(_ground_tint.r, _ground_tint.g, _ground_tint.b))
	material.set_shader_parameter("tint_floor", 0.0)
	# The Director: GFX-K three-scale meadow. Broad 3.0R, medium 0.8R.
	# Stay olive-green; do not return to the yellow-lime GFX-D wash.
	var road_w := ScaleProfile.road_width_metres()
	_apply_meadow_palette(material)
	material.set_shader_parameter("macro_metres", maxf(8.0, 4.0 * road_w))
	material.set_shader_parameter("patch_metres", maxf(1.94, 0.8 * road_w))
	material.set_shader_parameter("detail_metres", 1.10)
	material.set_shader_parameter("macro_amount", 0.12)
	material.set_shader_parameter("detail_amount", 0.08)
	material.set_shader_parameter("dirt_amount", 0.56)
	material.set_shader_parameter("flower_amount", 0.22)
	material.set_shader_parameter("stone_amount", 0.28)
	material.set_shader_parameter("crop_amount", 1.0)
	_bind_terrain_textures(material)
	material.set_shader_parameter("wheat_gold", Vector3(0.788, 0.635, 0.290))
	material.set_shader_parameter("world_min_xz", _fog_world_min_xz())
	material.set_shader_parameter("world_size_xz", _fog_world_size_xz())
	material.set_shader_parameter("beach_color", Vector3(0.090, 0.153, 0.165))
	material.set_shader_parameter("rock_shore", Vector3(0.078, 0.125, 0.141))
	material.set_shader_parameter("wet_sand", Vector3(0.070, 0.110, 0.125))
	material.set_shader_parameter("beach_margin_metres", BEACH_MARGIN_METRES)
	material.set_shader_parameter("coast_jut_metres", COAST_JUT_METRES)
	material.set_shader_parameter("apron_mode", 0.0)
	host.material_override = material


func _bind_terrain_textures(material: ShaderMaterial) -> void:
	# GFX-M: 1024² CC0 splat maps. Tint in the shader so photoreal scans
	# stay in the Nordic KayKit family.
	var meadow := load(Catalog.TERRAIN_TEXTURES["meadow"])
	var forest := load(Catalog.TERRAIN_TEXTURES["forest"])
	var dirt := load(Catalog.TERRAIN_TEXTURES["dirt"])
	var rock := load(Catalog.TERRAIN_TEXTURES["rock"])
	if meadow != null:
		material.set_shader_parameter("meadow_tex", meadow)
	if forest != null:
		material.set_shader_parameter("forest_tex", forest)
	if dirt != null:
		material.set_shader_parameter("dirt_tex", dirt)
	if rock != null:
		material.set_shader_parameter("rock_tex", rock)
	material.set_shader_parameter("tex_mix", 0.16)
	material.set_shader_parameter("tex_repeat_meadow", 1.5 * ScaleProfile.road_width_metres())
	material.set_shader_parameter("tex_repeat_forest", 1.2 * ScaleProfile.road_width_metres())
	if road_control_texture != null:
		material.set_shader_parameter("road_control_tex", road_control_texture)
	material.set_shader_parameter("road_control_amount", 1.0)
	material.set_shader_parameter("road_debug", 1.0 if road_debug_enabled else 0.0)
	material.set_shader_parameter("terrain_debug", float(terrain_debug_mode))


func _apply_meadow_palette(material: ShaderMaterial) -> void:
	# GFX-P meadow richness on the O occupy / distance-field baseline.
	material.set_shader_parameter("grass_sunlit", Vector3(0.447, 0.533, 0.325))
	material.set_shader_parameter("grass_moss", Vector3(0.204, 0.294, 0.200))
	material.set_shader_parameter("meadow_lush", Vector3(0.325, 0.424, 0.247))
	material.set_shader_parameter("meadow_warm", Vector3(0.447, 0.533, 0.325))
	material.set_shader_parameter("meadow_shade", Vector3(0.251, 0.353, 0.212))
	material.set_shader_parameter("forest_floor", Vector3(0.204, 0.294, 0.200))
	material.set_shader_parameter("dirt_color", Vector3(0.545, 0.439, 0.314))
	material.set_shader_parameter("road_earth", Vector3(0.624, 0.502, 0.357))
	material.set_shader_parameter("road_compacted", Vector3(0.506, 0.388, 0.267))
	material.set_shader_parameter("road_shoulder", Vector3(0.467, 0.420, 0.306))
	material.set_shader_parameter("road_rut", Vector3(0.400, 0.314, 0.224))
	material.set_shader_parameter("gravel_color", Vector3(0.702, 0.627, 0.518))


func set_road_debug(enabled: bool) -> void:
	road_debug_enabled = enabled
	if enabled and terrain_debug_mode == 0:
		terrain_debug_mode = 3
	elif not enabled and terrain_debug_mode == 3:
		terrain_debug_mode = 0
	_bind_terrain_debug()


func set_terrain_debug(mode: int) -> void:
	terrain_debug_mode = clampi(mode, 0, 3)
	road_debug_enabled = terrain_debug_mode == 3
	_bind_terrain_debug()


func _bind_terrain_debug() -> void:
	_bind_road_debug(terrain_mesh_instance)
	_bind_road_debug(beach_apron_instance)
	if terrain_root != null:
		for node in terrain_root.find_children("*", "MeshInstance3D", true, false):
			_bind_road_debug(node as MeshInstance3D)


func _bind_road_debug(host: MeshInstance3D) -> void:
	if host == null or not is_instance_valid(host):
		return
	if not (host.material_override is ShaderMaterial):
		return
	var material := host.material_override as ShaderMaterial
	if material.shader == null:
		return
	material.set_shader_parameter("road_debug", 1.0 if road_debug_enabled else 0.0)
	material.set_shader_parameter("terrain_debug", float(terrain_debug_mode))
	material.set_shader_parameter("road_control_amount", 1.0)
	material.set_shader_parameter("world_min_xz", _fog_world_min_xz())
	material.set_shader_parameter("world_size_xz", _fog_world_size_xz())
	if road_control_texture != null:
		material.set_shader_parameter("road_control_tex", road_control_texture)


func _distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var length_sq := maxf(ab.length_squared(), 0.0001)
	var t := clampf((p - a).dot(ab) / length_sq, 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _world_to_control_px(world: Vector2, min_xz: Vector2, size_xz: Vector2) -> Vector2i:
	var uv := (world - min_xz) / size_xz
	return Vector2i(
		clampi(int(round(uv.x * float(ROAD_CONTROL_RES - 1))), 0, ROAD_CONTROL_RES - 1),
		clampi(int(round((1.0 - uv.y) * float(ROAD_CONTROL_RES - 1))), 0, ROAD_CONTROL_RES - 1)
	)


func _control_px_to_world(x: int, y: int, min_xz: Vector2, size_xz: Vector2) -> Vector2:
	var uv := Vector2((float(x) + 0.5) / float(ROAD_CONTROL_RES), 1.0 - (float(y) + 0.5) / float(ROAD_CONTROL_RES))
	return min_xz + uv * size_xz


func _bake_road_control_texture() -> void:
	# 512² world-space distance field. R = 1 - smoothstep(0.32w, 0.58w, d).
	var img := Image.create(ROAD_CONTROL_RES, ROAD_CONTROL_RES, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 1))
	if simulation != null and map_size.x > 0:
		var min_xz := _fog_world_min_xz()
		var size_xz := _fog_world_size_xz()
		var visual_w := ScaleProfile.road_width_metres() * 1.32
		var spoke_w := ScaleProfile.road_width_metres() * 0.58
		var segments: Array[Vector2] = _collect_road_segments()
		var i := 0
		while i + 1 < segments.size():
			_stamp_segment_distance(img, segments[i], segments[i + 1], min_xz, size_xz, visual_w)
			i += 2
		var spokes: Array[Vector2] = _collect_hamlet_spokes()
		i = 0
		while i + 1 < spokes.size():
			_stamp_segment_distance(img, spokes[i], spokes[i + 1], min_xz, size_xz, spoke_w)
			i += 2
	if road_control_texture == null:
		road_control_texture = ImageTexture.create_from_image(img)
	else:
		road_control_texture.update(img)
	_bind_terrain_debug()


func _collect_road_segments() -> Array[Vector2]:
	var segs: Array[Vector2] = []
	_refresh_terrain_lookups()
	var cell := ScaleProfile.LOGICAL_CELL_METRES
	var seen: Dictionary = {}
	for y in range(map_size.y):
		for x in range(map_size.x):
			var tile := Vector2i(x, y)
			if not _is_road_tile(tile) and _visual_path_weight(tile) < 0.70:
				continue
			var a := Vector2(tile_to_world(Vector2(tile)).x, tile_to_world(Vector2(tile)).z)
			var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1)]
			for dir in dirs:
				var other: Vector2i = tile + dir
				if not simulation.is_inside_map(other):
					continue
				var other_road := _is_road_tile(other) or _visual_path_weight(other) >= 0.55
				if not other_road:
					continue
				var b := Vector2(tile_to_world(Vector2(other)).x, tile_to_world(Vector2(other)).z)
				if a.distance_to(b) > cell * 1.6:
					continue
				var key := "%d,%d-%d,%d" % [tile.x, tile.y, other.x, other.y]
				if seen.has(key):
					continue
				seen[key] = true
				segs.append(a)
				segs.append(b)
	return segs


func _collect_hamlet_spokes() -> Array[Vector2]:
	# Thin hall→cottage traces. Fat spokes painted the opening lawn tan.
	var segs: Array[Vector2] = []
	if simulation == null or not simulation.is_town_hall_founded():
		return segs
	var hall: Vector2i = simulation.town_hall_position
	var center := Vector2(tile_to_world(Vector2(hall) + Vector2(1.5, 1.5)).x, tile_to_world(Vector2(hall) + Vector2(1.5, 1.5)).z)
	for spec_value in _opening_hamlet_spec():
		var spec: Dictionary = spec_value
		var dest_tile := hall + Vector2i(int(spec["ox"]), int(spec["oy"]))
		var dest := Vector2(tile_to_world(Vector2(dest_tile) + Vector2(float(spec["w"]) * 0.5, float(spec["h"]) * 0.5)).x, tile_to_world(Vector2(dest_tile) + Vector2(float(spec["w"]) * 0.5, float(spec["h"]) * 0.5)).z)
		segs.append(center)
		segs.append(dest)
	return segs


func _stamp_segment_distance(img: Image, a: Vector2, b: Vector2, min_xz: Vector2, size_xz: Vector2, visual_w: float) -> void:
	var pad := visual_w * 0.70
	var min_p := Vector2(minf(a.x, b.x) - pad, minf(a.y, b.y) - pad)
	var max_p := Vector2(maxf(a.x, b.x) + pad, maxf(a.y, b.y) + pad)
	var pa := _world_to_control_px(min_p, min_xz, size_xz)
	var pb := _world_to_control_px(max_p, min_xz, size_xz)
	var x0 := mini(pa.x, pb.x)
	var x1 := maxi(pa.x, pb.x)
	var y0 := mini(pa.y, pb.y)
	var y1 := maxi(pa.y, pb.y)
	var inner := visual_w * 0.32
	var outer := visual_w * 0.58
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var world := _control_px_to_world(x, y, min_xz, size_xz)
			var d := _distance_to_segment(world, a, b)
			var mask := 1.0 - smoothstep(inner, maxf(inner + 0.01, outer), d)
			if mask <= 0.02:
				continue
			var prev := img.get_pixel(x, y)
			if mask > prev.r:
				img.set_pixel(x, y, Color(mask, prev.g, prev.b, 1.0))


func _stamp_road_disk(img: Image, cx: int, cy: int, radius_px: int, road_r: float, px_per_m: float) -> void:
	var res := ROAD_CONTROL_RES
	var inner := (road_r * 0.65) * px_per_m
	var outer := (road_r + road_r * 0.12) * px_per_m
	for oy in range(-radius_px, radius_px + 1):
		for ox in range(-radius_px, radius_px + 1):
			var x := cx + ox
			var y := cy + oy
			if x < 0 or y < 0 or x >= res or y >= res:
				continue
			var dist := Vector2(float(ox), float(oy)).length()
			var mask := 1.0 - smoothstep(inner, maxf(inner + 0.5, outer), dist)
			if mask <= 0.02:
				continue
			var prev := img.get_pixel(x, y)
			if mask > prev.r:
				img.set_pixel(x, y, Color(mask, prev.g, prev.b, 1.0))


func _stamp_road_capsule(img: Image, a: Vector2, b: Vector2, min_xz: Vector2, size_xz: Vector2, half_w: float, px_per_m: float) -> void:
	var res := ROAD_CONTROL_RES
	var steps := maxi(2, int(ceili(a.distance_to(b) * px_per_m)))
	var radius_px := int(ceili(half_w * px_per_m)) + 1
	for i in steps + 1:
		var p := a.lerp(b, float(i) / float(steps))
		var uv := (p - min_xz) / size_xz
		var cx := int(round(uv.x * float(res - 1)))
		var cy := int(round(uv.y * float(res - 1)))
		_stamp_road_disk(img, cx, cy, radius_px, half_w * 2.0, px_per_m)


func _rebuild_terrain_collision(mesh: Mesh) -> void:
	if terrain_body != null and is_instance_valid(terrain_body):
		terrain_body.queue_free()
	terrain_body = StaticBody3D.new()
	terrain_body.name = "TerrainPicker"
	terrain_body.set_meta("selection_kind", "terrain")
	var collision := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(mesh.get_faces())
	collision.shape = shape
	terrain_body.add_child(collision)
	terrain_root.add_child(terrain_body)


func _add_terrain_cell(surface: SurfaceTool, tile: Vector2i) -> void:
	var center := ScaleProfile.tile_to_flat_world(Vector2(tile), map_size)
	var half := ScaleProfile.LOGICAL_CELL_METRES * 0.5
	var top_y := float(simulation.get_height(tile)) * ScaleProfile.TERRAIN_ELEVATION_UNIT_METRES
	var corners := [
		Vector3(center.x - half, top_y, center.z - half),
		Vector3(center.x + half, top_y, center.z - half),
		Vector3(center.x + half, top_y, center.z + half),
		Vector3(center.x - half, top_y, center.z + half),
	]
	# Shared-corner colours so adjacent tiles cannot print a diamond
	# checkerboard from the isometric camera.
	var corner_colors := [
		_corner_terrain_color(tile, Vector2i(0, 0)),
		_corner_terrain_color(tile, Vector2i(1, 0)),
		_corner_terrain_color(tile, Vector2i(1, 1)),
		_corner_terrain_color(tile, Vector2i(0, 1)),
	]
	_add_quad_colored(surface, corners[0], corners[1], corners[2], corners[3], Vector3.UP, corner_colors[0], corner_colors[1], corner_colors[2], corner_colors[3])
	var color := _cached_terrain_color(tile)
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
	_add_quad_colored(surface, a, b, c, d, normal, color, color, color, color)


func _add_quad_colored(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3, ca: Color, cb: Color, cc: Color, cd: Color) -> void:
	var verts := [a, b, c, a, c, d]
	var cols := [ca, cb, cc, ca, cc, cd]
	for i in verts.size():
		surface.set_normal(normal)
		surface.set_color((cols[i] as Color).srgb_to_linear())
		surface.add_vertex(verts[i])


func _corner_terrain_color(tile: Vector2i, corner: Vector2i) -> Color:
	var acc := Color(0, 0, 0, 0)
	var count := 0
	for oy in [corner.y - 1, corner.y]:
		for ox in [corner.x - 1, corner.x]:
			var sample := tile + Vector2i(ox, oy)
			if simulation != null and simulation.is_inside_map(sample):
				acc += _cached_terrain_color(sample)
				count += 1
	if count <= 0:
		return _cached_terrain_color(tile)
	return acc / float(count)


func _terrain_color(tile: Vector2i) -> Color:
	return _cached_terrain_color(tile)


func _compute_terrain_color(tile: Vector2i) -> Color:
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
	# Occupation only. Meadow hue lives in the world-space shader so a
	# per-tile hash cannot reprint diagonal squares.
	var base := Color(0.408, 0.455, 0.227, 0.0)
	var litter := clampf(float(tree_weight) / 16.0, 0.0, 0.70)
	if litter > 0.12:
		base = base.lerp(Color(0.220, 0.275, 0.145, 0.40), litter * 0.78)
	var scree := clampf(float(rock_weight) / 16.0, 0.0, 0.55)
	if scree > 0.12:
		base = base.lerp(Color(0.522, 0.514, 0.451, 0.32), scree * 0.50)
	var edge := mini(mini(tile.x, tile.y), mini(map_size.x - 1 - tile.x, map_size.y - 1 - tile.y))
	if edge <= 1:
		base = base.lerp(Color(0.090, 0.149, 0.165, 0.28) if rock_weight < 3 else Color(0.416, 0.376, 0.329, 0.24), 0.55)
	var path_w := maxf(_visual_path_weight(tile), _hamlet_path_weight(tile))
	if path_w > 0.08:
		base = base.lerp(Color(0.690, 0.520, 0.330, 0.88), clampf(path_w * 0.94, 0.0, 0.94))
	if _is_farm_field_tile(tile):
		base = Color(0.788, 0.635, 0.290, 0.94)
	if _is_road_tile(tile):
		base = Color(0.682, 0.565, 0.427, 0.98)
	elif _is_road_shoulder(tile):
		# 20–35% of the road width, not a hard beige stripe.
		var shoulder := 0.20 + float(_tile_hash(tile, 41) % 16) / 100.0
		base = base.lerp(Color(0.520, 0.410, 0.275, 0.55), clampf(shoulder, 0.20, 0.35))
	if _terrain_occupied_cache.has(_tile_key(tile)) and not _is_farm_field_tile(tile):
		base = base.lerp(Color(0.573, 0.443, 0.306, 0.62), 0.64)
	elif _terrain_yard_cache.has(_tile_key(tile)) and not _is_farm_field_tile(tile):
		base = base.lerp(Color(0.573, 0.443, 0.306, 0.34), 0.42)
	if String(simulation.get_tile(tile)) == Defs.TILE_SHARD:
		base = Color(0.275, 0.349, 0.388, 0.40)
	var impact := 0.0
	if simulation.has_method("impact_factor"):
		impact = float(simulation.impact_factor(tile))
	if impact > 0.0:
		base = base.lerp(Color("#2a3140"), clampf(impact * 0.78, 0.0, 0.78))
		base = base.lerp(Color("#3a5c66"), clampf(impact * 0.22, 0.0, 0.22))
		if impact > 0.55:
			base = base.lerp(Color("#4a6d78"), clampf((impact - 0.55) * 0.35, 0.0, 0.22))
	return base


func _meadow_weight(tile: Vector2i) -> float:
	if simulation == null or not simulation.is_town_hall_founded():
		return 0.35
	var hall: Vector2i = simulation.town_hall_position
	var dist := Vector2(tile - hall).length()
	return clampf(1.0 - absf(dist - 5.5) / 6.5, 0.0, 1.0) * (0.55 + float(_tile_hash(tile, 29) % 40) / 100.0)


func _visual_path_weight(tile: Vector2i) -> float:
	if simulation == null or not simulation.is_town_hall_founded():
		return 0.0
	var hall: Vector2i = simulation.town_hall_position + Vector2i(2, 2)
	var shard: Vector2i = simulation.shard_position
	var along := Vector2(shard - hall)
	if along.length_squared() < 4.0:
		return 0.0
	var span := along.length()
	var t := clampf(Vector2(tile - hall).dot(along.normalized()) / span, 0.0, 0.42)
	var closest := Vector2(hall) + along.normalized() * (t * span)
	var wobble := sin(t * 9.4 + float(visual_seed % 11) * 0.2) * 1.35
	var side := Vector2(-along.y, along.x).normalized()
	closest += side * wobble
	var dist := Vector2(tile).distance_to(closest)
	return clampf(1.0 - dist / 1.85, 0.0, 1.0)


func _is_road_tile(tile: Vector2i) -> bool:
	if _terrain_lookups_ready:
		return _terrain_road_cache.has(_tile_key(tile))
	if simulation == null:
		return false
	if simulation.connected_roads.has(_tile_key(tile)):
		return true
	for building_value in simulation.get_buildings():
		var building: Dictionary = building_value
		if String(building.get("type", "")) == Defs.BUILDING_ROAD and Vector2i(building.get("position", Vector2i.ZERO)) == tile:
			return true
	return false


func _is_road_shoulder(tile: Vector2i) -> bool:
	for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if _is_road_tile(tile + dir):
			return true
	return false


func _is_farm_field_tile(tile: Vector2i) -> bool:
	if _terrain_lookups_ready:
		return _terrain_farm_cache.has(_tile_key(tile))
	return _farm_field_tiles().has(_tile_key(tile))


func _farm_field_tiles() -> Dictionary:
	# Presentation crop rows around each farm. Does not consume TILE_GRASS
	# or change placement — occupation splat only, so the shader can paint
	# readable furrows at gameplay zoom.
	var fields: Dictionary = {}
	if simulation == null:
		return fields
	for building_value in simulation.get_buildings():
		var building: Dictionary = building_value
		var type_name := String(building.get("planned_type", "")) if bool(building.get("construction", false)) else String(building.get("type", ""))
		if type_name != Defs.BUILDING_FARM:
			continue
		var anchor: Vector2i = building.get("position", Vector2i.ZERO)
		var footprint := _building_footprint_for_visual(building, type_name)
		for oy in range(-1, footprint.y + 3):
			for ox in range(-3, footprint.x + 1):
				var sample := anchor + Vector2i(ox, oy)
				if simulation.is_inside_map(sample) and not _terrain_occupied_cache.has(_tile_key(sample)):
					if not _is_road_tile(sample):
						fields[_tile_key(sample)] = true
	return fields


func _calculate_height_signature() -> int:
	var value := 17
	for y in range(map_size.y):
		for x in range(map_size.x):
			value = int((value * 31 + simulation.get_height(Vector2i(x, y))) & 0x7fffffff)
	return value


func _calculate_occupation_signature() -> int:
	# The Director: roads and yards must rebake the ground splat even when
	# height stays flat, otherwise the showcase village sits on a lawn.
	var value := 19
	if simulation == null:
		return value
	if simulation.connected_roads != null:
		var road_keys: Array = simulation.connected_roads.keys()
		road_keys.sort()
		for key_value in road_keys:
			value = int((value * 31 + String(key_value).hash()) & 0x7fffffff)
	for building_value in simulation.get_buildings():
		var building: Dictionary = building_value
		var tile: Vector2i = building.get("position", Vector2i.ZERO)
		value = int((value * 31 + int(building.get("id", 0)) * 11 + tile.x * 13 + tile.y * 17 + int(bool(building.get("construction", false)))) & 0x7fffffff)
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
		if String(child.name) == "OpeningDress":
			continue
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
			var visual_count := 2 if stage >= 1 and neighbors >= 3 and foliage_density >= 0.75 and _tile_hash(tile, 19) % 3 != 0 else 1
			if foliage_density < 0.50 and _tile_hash(tile, 91) % 3 == 0:
				visual_count = 0
			for index in visual_count:
				var path_value := _tree_path_for_tile(tile, index, neighbors)
				var scales := _tree_scale_range(path_value, neighbors)
				_append_nature_transform(transforms_by_path, path_value, tile, index, 0.55, float(scales.x), float(scales.y))
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
	var tree_floors: Array = []
	for path_value in transforms_by_path:
		if not _is_tree_path(String(path_value)):
			continue
		var batch: Array = transforms_by_path[path_value]
		for index in batch.size():
			if index % 2 != 0:
				continue
			tree_floors.append(ContactAO.flatten_transform(batch[index], 1.7))
	ContactAO.spawn_multimesh(resource_visuals_root, tree_floors, 0.22)


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
	_refresh_terrain_lookups()
	for child in grass_root.get_children():
		grass_root.remove_child(child)
		child.free()
	var occupied := _structure_tiles()
	var yard := _yard_tiles(4)
	var transforms_by_path: Dictionary = {}
	var density := grass_density
	for y in range(map_size.y):
		for x in range(map_size.x):
			var tile := Vector2i(x, y)
			if String(simulation.get_tile(tile)) != Defs.TILE_GRASS:
				continue
			if occupied.has(_tile_key(tile)):
				continue
			if not simulation.is_revealed(tile):
				continue
			if _is_road_tile(tile) or _is_farm_field_tile(tile):
				continue
			if density < 0.55 and _tile_hash(tile, 11) % 3 == 0:
				continue
			var meadow := _meadow_weight(tile)
			var forest_edge := _same_type_neighbors(tile, Defs.TILE_TREE)
			var near_yard := yard.has(_tile_key(tile))
			var path_w := _visual_path_weight(tile)
			if path_w > 0.45:
				continue
			# GFX-N: cluster at forest edges and landmarks. Sparse meadow
			# center so construction stays readable.
			var patch := _tile_hash(tile, 19) % 5
			var tufts := 0
			if forest_edge >= 1:
				tufts = 5 if forest_edge >= 2 else 4
			elif near_yard and patch <= 3:
				tufts = 3
			elif meadow > 0.22 and patch == 0:
				tufts = 1
			if tufts == 0:
				if forest_edge >= 1 and _tile_hash(tile, 47) % 2 == 0 and Catalog.FLOWERS.size() > 0:
					var lone_flower := String(Catalog.FLOWERS[_tile_hash(tile, 61) % Catalog.FLOWERS.size()])
					_append_nature_transform(transforms_by_path, lone_flower, tile, 4, 0.70, 1.28, 0.50)
				continue
			for index in tufts:
				var grass_path := String(Catalog.GRASS[_tile_hash(tile, 83 + index) % Catalog.GRASS.size()])
				_append_nature_transform(transforms_by_path, grass_path, tile, index, 0.95, 1.48, 0.86)
			if (forest_edge >= 1 or near_yard) and _tile_hash(tile, 47) % 3 == 0 and Catalog.FLOWERS.size() > 0:
				var flower_path := String(Catalog.FLOWERS[_tile_hash(tile, 61) % Catalog.FLOWERS.size()])
				_append_nature_transform(transforms_by_path, flower_path, tile, 4, 0.60, 1.12, 0.46)
			if meadow > 0.20 and forest_edge == 0 and near_yard and _tile_hash(tile, 59) % 6 == 0 and Catalog.UNDERSTORY.size() > 0:
				var meadow_bush := String(Catalog.UNDERSTORY[_tile_hash(tile, 73) % Catalog.UNDERSTORY.size()])
				_append_nature_transform(transforms_by_path, meadow_bush, tile, 8, 0.55, 0.96, 0.30)
			if forest_edge >= 1 and forest_edge <= 3 and _tile_hash(tile, 53) % 2 == 0 and Catalog.UNDERSTORY.size() > 0:
				var bush_path := String(Catalog.UNDERSTORY[_tile_hash(tile, 71) % Catalog.UNDERSTORY.size()])
				_append_nature_transform(transforms_by_path, bush_path, tile, 6, 0.50, 0.35, 0.30)
			if forest_edge >= 1 and _tile_hash(tile, 101) % 4 == 0 and Catalog.ROCKS.size() > 0:
				var rock_path := String(Catalog.ROCKS[_tile_hash(tile, 109) % Catalog.ROCKS.size()])
				_append_nature_transform(transforms_by_path, rock_path, tile, 7, 0.58, 0.50, 0.20)
	_spawn_nature_multimeshes(grass_root, transforms_by_path)
	for child in grass_root.get_children():
		if child is GeometryInstance3D:
			(child as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rebuild_ground_patches()


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
		var foliage := _foliage_material(mesh, path_value)
		if foliage != null:
			instance.material_override = foliage
		host.add_child(instance)


func _rebuild_ground_patches() -> void:
	# GFX-I medium-scale meadow clumps. Darker grass / soil / flowers /
	# stones in 40 m MultiMesh chunks so instances frustum-cull. Not
	# another generic vegetation scatter — patch sizes track road width.
	if ground_patch_root == null or simulation == null:
		return
	_refresh_terrain_lookups()
	for child in ground_patch_root.get_children():
		ground_patch_root.remove_child(child)
		child.free()
	var occupied := _structure_tiles()
	var grass_path := String(Catalog.GRASS[0]) if Catalog.GRASS.size() > 0 else ""
	var flower_path := String(Catalog.FLOWERS[0]) if Catalog.FLOWERS.size() > 0 else ""
	var rock_path := String(Catalog.ROCKS[0]) if Catalog.ROCKS.size() > 0 else ""
	var chunk_buckets: Dictionary = {}
	for y in range(map_size.y):
		for x in range(map_size.x):
			var tile := Vector2i(x, y)
			if String(simulation.get_tile(tile)) != Defs.TILE_GRASS:
				continue
			if occupied.has(_tile_key(tile)) or _is_road_tile(tile) or _is_farm_field_tile(tile):
				continue
			if not simulation.is_revealed(tile):
				continue
			if _visual_path_weight(tile) > 0.40 or _hamlet_path_weight(tile) > 0.40:
				continue
			var world := tile_to_world(Vector2(tile))
			var chunk := Vector2i(int(floor(world.x / GROUND_PATCH_CHUNK_METRES)), int(floor(world.z / GROUND_PATCH_CHUNK_METRES)))
			var seed_h := _tile_hash(tile, 29)
			# GFX-O: no flat dark-grass / cluster cylinders. Shade lives
			# in the ground shader (#3E5938, max 0.35). Keep flowers and
			# stones as 3D props so the meadow is not a disk field.
			if seed_h % 8 == 0 and flower_path != "":
				_bucket_patch(chunk_buckets, chunk, "flowers", _nature_transform_at(tile, 6, flower_path, 0.55, 1.05, 0.55))
				if seed_h % 2 == 0:
					_bucket_patch(chunk_buckets, chunk, "flowers", _nature_transform_at(tile, 16, flower_path, 0.80, 0.90, 0.40))
			if seed_h % 10 == 0 and rock_path != "":
				_bucket_patch(chunk_buckets, chunk, "stones", _nature_transform_at(tile, 7, rock_path, 0.45, 0.48, 0.22))
	for chunk_key in chunk_buckets:
		var kinds: Dictionary = chunk_buckets[chunk_key]
		for kind in kinds:
			var transforms: Array = kinds[kind]
			if transforms.is_empty():
				continue
			var mesh := _ground_patch_mesh(String(kind), grass_path, flower_path, rock_path)
			if mesh == null:
				continue
			var multimesh := MultiMesh.new()
			multimesh.transform_format = MultiMesh.TRANSFORM_3D
			multimesh.mesh = mesh
			multimesh.instance_count = transforms.size()
			for index in transforms.size():
				multimesh.set_instance_transform(index, transforms[index])
			var instance := MultiMeshInstance3D.new()
			instance.name = "Patch_%s_%s" % [String(chunk_key), String(kind)]
			instance.multimesh = multimesh
			instance.material_override = _ground_patch_material(String(kind))
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			ground_patch_root.add_child(instance)


func _bucket_patch(buckets: Dictionary, chunk: Vector2i, kind: String, xf: Transform3D) -> void:
	var chunk_key := "%d_%d" % [chunk.x, chunk.y]
	if not buckets.has(chunk_key):
		buckets[chunk_key] = {}
	var kinds: Dictionary = buckets[chunk_key]
	if not kinds.has(kind):
		kinds[kind] = []
	(kinds[kind] as Array).append(xf)


func _patch_transform(tile: Vector2i, index: int, width: float, y: float) -> Transform3D:
	var world := tile_to_world(Vector2(tile))
	var jitter := _deterministic_offset(tile, index, 0.55)
	world += Vector3(jitter.x, y, jitter.y)
	var yaw := float(_tile_hash(tile, 53 + index) % 628) / 100.0
	var basis := Basis(Vector3.UP, yaw).scaled(Vector3(width, 1.0, width * 0.72))
	return Transform3D(basis, world)


func _nature_transform_at(tile: Vector2i, index: int, path_value: String, radius: float, base_scale: float, scale_range: float) -> Transform3D:
	var world := tile_to_world(Vector2(tile))
	var offset := _deterministic_offset(tile, index, radius)
	world += Vector3(offset.x, 0.0, offset.y)
	var scale_value := (base_scale + float(_tile_hash(tile, 41 + index) % 100) / 100.0 * scale_range) * ScaleProfile.nature_model_scale(path_value)
	var yaw := float(_tile_hash(tile, 53 + index) % 628) / 100.0
	return Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scale_value), world)


func _ground_patch_mesh(kind: String, grass_path: String, flower_path: String, rock_path: String) -> Mesh:
	if kind == "dark_grass" or kind == "soil" or kind == "cluster":
		var disk := CylinderMesh.new()
		disk.top_radius = 0.50
		disk.bottom_radius = 0.50
		disk.height = 0.04
		disk.radial_segments = 10
		disk.rings = 1
		return disk
	if kind == "flowers" and flower_path != "":
		return _mesh_for_nature_path(flower_path)
	if kind == "stones" and rock_path != "":
		return _mesh_for_nature_path(rock_path)
	if grass_path != "":
		return _mesh_for_nature_path(grass_path)
	return null


func _ground_patch_material(kind: String) -> Material:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.roughness = 0.94
	material.metallic = 0.0
	match kind:
		"dark_grass":
			material.albedo_color = Color("#405B39")
		"cluster":
			material.albedo_color = Color("#354A34")
		"soil":
			material.albedo_color = Color("#4A3C2E")
		"flowers":
			return null
		"stones":
			material.albedo_color = Color("#776F60")
		_:
			material.albedo_color = Color("#3E4E28")
	return material


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
	if path_value.get_file().get_basename() == "grass":
		var clump := _grass_clump_mesh()
		nature_mesh_cache[path_value] = clump
		return clump
	var packed := load(path_value) as PackedScene
	if packed == null:
		return null
	var instance := packed.instantiate()
	var mesh_instance := _find_mesh_instance(instance)
	var mesh: Mesh = mesh_instance.mesh if mesh_instance != null else null
	nature_mesh_cache[path_value] = mesh
	instance.free()
	return mesh


func _grass_clump_mesh() -> ArrayMesh:
	# GFX-E: 4 broad tapered leaves. Strategy-cam silhouette, not ant strokes.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var colors := [Color("#4A6A3C"), Color("#7A9658"), Color("#2E462C"), Color("#6A8A50")]
	for i in 4:
		var yaw := float(i) * 0.85 + 0.2
		var h := 0.42 + float(i % 3) * 0.10
		var w := 0.20 + float(i % 2) * 0.06
		var ox := cos(yaw) * 0.08
		var oz := sin(yaw) * 0.08
		var tip := Vector3(ox, h, oz)
		var left := Vector3(ox + cos(yaw + 1.2) * w, 0.0, oz + sin(yaw + 1.2) * w)
		var right := Vector3(ox + cos(yaw - 1.2) * w, 0.0, oz + sin(yaw - 1.2) * w)
		var normal := (right - left).cross(tip - left).normalized()
		st.set_color(colors[i])
		st.set_normal(normal)
		st.add_vertex(left)
		st.add_vertex(tip)
		st.add_vertex(right)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.92
	mat.metallic = 0.0
	st.set_material(mat)
	st.index()
	return st.commit()


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
	var fog_signature := _fog_vision_signature(revealed_count)
	if not force and fog_signature == last_fog_signature:
		return
	last_fog_signature = fog_signature
	last_revealed_count = revealed_count
	# Always keep the shroud. Fully-revealed maps still need the off-map
	# #17272A wall so zoom-out cannot read a diamond board.
	var visible_tiles := _paint_current_vision()
	var mask_size := Vector2i(ceili(float(map_size.x) / FOG_MASK_DIVISOR), ceili(float(map_size.y) / FOG_MASK_DIVISOR))
	var mask_bytes := PackedByteArray()
	mask_bytes.resize(mask_size.x * mask_size.y)
	for mask_y in mask_size.y:
		for mask_x in mask_size.x:
			var sample := Vector2i(mask_x * FOG_MASK_DIVISOR, mask_y * FOG_MASK_DIVISOR)
			var shroud := FOG_UNEXPLORED
			if simulation.is_inside_map(sample):
				if visible_tiles.has(_tile_key(sample)):
					shroud = FOG_VISIBLE
				elif simulation.is_revealed(sample):
					shroud = FOG_EXPLORED
			mask_bytes[mask_y * mask_size.x + mask_x] = shroud
	var display_size := mask_size * FOG_DISPLAY_UPSAMPLE
	# Cubic upsample plus shader jitter = irregular 1–2 cell feather.
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
	fog_material.set_shader_parameter("explored_opacity", 0.55)
	fog_material.set_shader_parameter("cell_metres", ScaleProfile.LOGICAL_CELL_METRES)
	fog_material.set_shader_parameter("feather_cells", 1.25)
	fog_material.set_shader_parameter("noise_strength", 0.12)
	fog_material.set_shader_parameter("shore_fade_metres", SHORE_FADE_METRES)
	if fog_screen_material != null:
		fog_screen_material.set_shader_parameter("unknown_opacity", 1.0)
		fog_screen_material.set_shader_parameter("explored_opacity", 0.55)
		fog_screen_material.set_shader_parameter("cell_metres", ScaleProfile.LOGICAL_CELL_METRES)
		fog_screen_material.set_shader_parameter("feather_cells", 1.25)
		fog_screen_material.set_shader_parameter("noise_strength", 0.12)
		fog_screen_material.set_shader_parameter("unknown_color", FOG_UNKNOWN_BASE)
		fog_screen_material.set_shader_parameter("mist_color", FOG_MIST_BASE)
		fog_screen_material.set_shader_parameter("world_min_xz", _fog_world_min_xz())
		fog_screen_material.set_shader_parameter("world_size_xz", _fog_world_size_xz())
	_ensure_fog_volume()


func _fog_vision_signature(revealed_count: int) -> String:
	var value := revealed_count * 31
	if simulation == null:
		return "0"
	if simulation.is_town_hall_founded():
		var hall: Vector2i = simulation.town_hall_position
		value = int((value + hall.x * 13 + hall.y * 17) & 0x7fffffff)
	for worker_value in simulation.workers:
		var worker: Dictionary = worker_value
		if int(worker.get("hp", 1)) <= 0:
			continue
		var tile: Vector2i = simulation._unit_tile(worker)
		value = int((value * 31 + tile.x * 13 + tile.y * 17 + int(worker.get("id", 0))) & 0x7fffffff)
	return "%d:%d" % [value, int(simulation.get_buildings().size())]


func _paint_current_vision() -> Dictionary:
	var visible: Dictionary = {}
	if simulation == null:
		return visible
	if simulation.is_town_hall_founded():
		var hall_fp := Defs.building_footprint(Defs.BUILDING_TOWN_HALL)
		var hall_center: Vector2i = simulation._footprint_center(simulation.town_hall_position, hall_fp)
		_paint_vision_disk(visible, hall_center, simulation.building_vision_radius(Defs.BUILDING_TOWN_HALL))
	for building_value in simulation.get_buildings():
		var building: Dictionary = building_value
		if bool(building.get("construction", false)):
			continue
		var building_type := String(building.get("type", ""))
		if building_type == Defs.BUILDING_TOWN_HALL:
			continue
		var center: Vector2i = building.get("position", Vector2i.ZERO)
		if building_type != Defs.BUILDING_ROAD:
			center = simulation._footprint_center(center, _building_footprint_for_visual(building, building_type))
		_paint_vision_disk(visible, center, simulation.building_vision_radius(building_type))
	for worker_value in simulation.workers:
		var worker: Dictionary = worker_value
		if int(worker.get("hp", 1)) <= 0:
			continue
		var tile: Vector2i = simulation._unit_tile(worker)
		_paint_vision_disk(visible, tile, simulation.unit_vision_radius(String(worker.get("type", ""))))
	return visible


func _paint_vision_disk(visible: Dictionary, center: Vector2i, radius: int) -> void:
	if radius <= 0:
		return
	for oy in range(-radius, radius + 1):
		for ox in range(-radius, radius + 1):
			if absi(ox) + absi(oy) > radius:
				continue
			var tile := center + Vector2i(ox, oy)
			if simulation != null and simulation.is_inside_map(tile):
				visible[_tile_key(tile)] = true


func _ensure_fog_volume() -> void:
	# World-anchored sheet over the map. Off-map pixels stay clear so a corner
	# pan cannot look through unknown padding onto the settlement. Camera pan is
	# clamped to revealed land so the isometric view cannot fill with fog.
	var map_span := Vector2(map_size) * ScaleProfile.LOGICAL_CELL_METRES
	var cover := Vector2(map_span.x + 720.0, map_span.y + 720.0)
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
	# GFX-J: the world sheet printed triangular AABB cuts. Keep the node
	# for old callers, but the live shroud is the screen overlay.
	fog_plane.visible = false
	_ensure_fog_skirts()
	for skirt_value in fog_skirts:
		if skirt_value is MeshInstance3D:
			(skirt_value as MeshInstance3D).visible = false
	_ensure_fog_screen()


func _ensure_fog_skirts() -> void:
	if fog_skirts.is_empty():
		for index in 4:
			var skirt := MeshInstance3D.new()
			skirt.name = "FogSkirt_%d" % index
			fog_root.add_child(skirt)
			fog_skirts.append(skirt)
	var skirt_material := StandardMaterial3D.new()
	skirt_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	skirt_material.albedo_color = Color("#17272A")
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
		skirt.visible = true


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
	if fog_overlay_camera == null:
		return
	if fog_screen_material == null:
		fog_screen_material = ShaderMaterial.new()
		fog_screen_material.shader = FogScreenShader
		fog_screen_material.render_priority = 80
	if fog_visibility_texture != null:
		fog_screen_material.set_shader_parameter("visibility_texture", fog_visibility_texture)
	fog_screen_material.set_shader_parameter("unknown_color", FOG_UNKNOWN_BASE)
	fog_screen_material.set_shader_parameter("mist_color", FOG_MIST_BASE)
	fog_screen_material.set_shader_parameter("world_min_xz", _fog_world_min_xz())
	fog_screen_material.set_shader_parameter("world_size_xz", _fog_world_size_xz())
	fog_screen_material.set_shader_parameter("unknown_opacity", 1.0)
	fog_screen_material.set_shader_parameter("explored_opacity", 0.55)
	fog_screen_material.set_shader_parameter("cell_metres", ScaleProfile.LOGICAL_CELL_METRES)
	fog_screen_material.set_shader_parameter("feather_cells", 1.25)
	fog_screen_material.set_shader_parameter("noise_strength", 0.12)
	if fog_screen == null or not is_instance_valid(fog_screen):
		fog_screen = MeshInstance3D.new()
		fog_screen.name = "ScreenFogOverlay"
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		tool.add_vertex(Vector3(-1.0, -1.0, 0.0))
		tool.add_vertex(Vector3(3.0, -1.0, 0.0))
		tool.add_vertex(Vector3(-1.0, 3.0, 0.0))
		fog_screen.mesh = tool.commit()
		fog_screen.material_override = fog_screen_material
		fog_screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		fog_screen.extra_cull_margin = 16384.0
		fog_overlay_camera.add_child(fog_screen)
	else:
		fog_screen.material_override = fog_screen_material
	fog_screen.visible = true


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
	var next_foliage := clampf(float(quality.get("foliage_density", foliage_density)), 0.25, 1.0)
	var next_grass := clampf(float(quality.get("grass_density", quality.get("foliage_density", grass_density))), 0.25, 1.0)
	var next_water := clampf(float(quality.get("water_detail", water_detail)), 0.2, 1.0)
	var density_changed := not is_equal_approx(next_foliage, foliage_density) or not is_equal_approx(next_grass, grass_density)
	foliage_density = next_foliage
	grass_density = next_grass
	water_detail = next_water
	if water_material != null:
		water_material.set_shader_parameter("wave", 0.055 * water_detail)
	if simulation == null or not density_changed:
		return
	# Recommended and High share 1.0 foliage. Rebuilding the edge forest
	# and every grass clump on a no-op density change hung lavapipe after
	# the showcase village (~5 min, never finished).
	_rebuild_edge_forest(true)
	_rebuild_grass_multimeshes()


func apply_light_palette(palette: Dictionary) -> void:
	var window_color: Color = palette.get("window_color", Color("#FFB347"))
	var torch_color: Color = palette.get("torch_color", Color("#FFC36B"))
	var torch_range := float(palette.get("torch_range", 5.5))
	var atmosphere := clampf(float(palette.get("atmosphere_scale", 1.0)), 0.15, 1.0)
	_atmosphere_scale = atmosphere
	if fog_material != null:
		fog_material.set_shader_parameter("unknown_color", FOG_UNKNOWN_BASE)
		fog_material.set_shader_parameter("mist_color", FOG_MIST_BASE)
	if fog_screen_material != null:
		fog_screen_material.set_shader_parameter("unknown_color", FOG_UNKNOWN_BASE)
		fog_screen_material.set_shader_parameter("mist_color", FOG_MIST_BASE)
	if boundary_mist_material != null:
		boundary_mist_material.set_shader_parameter("color_scale", atmosphere)
	if water_material != null:
		water_material.set_shader_parameter("atmosphere", atmosphere)
		water_material.set_shader_parameter("lod_cheap", float(palette.get("terrain_lod_cheap", 0.0)))
		water_material.set_shader_parameter("wave", 0.055 * water_detail * (0.0 if float(palette.get("terrain_lod_cheap", 0.0)) > 0.5 else 1.0))
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
					(mat as StandardMaterial3D).albedo_color = Color("#2a4a34") * atmosphere
	for view in building_views.values():
		if view.has_method("apply_light_palette"):
			view.apply_light_palette(window_color, torch_color, torch_range)
	for view in rivalry_structure_views.values():
		if view.has_method("apply_light_palette"):
			view.apply_light_palette(window_color, torch_color, torch_range)
	_apply_dress_lights(window_color, torch_color, torch_range, float(palette.get("terrain_lod_cheap", 0.0)) > 0.5)


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
	water_material.set_shader_parameter("wave", 0.055 * water_detail)
	water_material.set_shader_parameter("foam_metres", 6.2)
	water_material.set_shader_parameter("beach_margin_metres", BEACH_MARGIN_METRES)
	water_material.set_shader_parameter("coast_jut_metres", COAST_JUT_METRES)
	water_material.set_shader_parameter("fade_start", 36.0)
	water_material.set_shader_parameter("fade_end", 220.0)
	water_material.set_shader_parameter("horizon_color", Vector3(0.090, 0.149, 0.165))
	water_material.set_shader_parameter("deep_color", Vector3(0.090, 0.149, 0.165))
	water_material.set_shader_parameter("shallow_color", Vector3(0.090, 0.149, 0.165))
	water_material.set_shader_parameter("foam_color", Vector3(0.110, 0.165, 0.176))
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
	material.set_shader_parameter("macro_metres", 18.0)
	material.set_shader_parameter("patch_metres", 8.0)
	material.set_shader_parameter("detail_metres", 0.85)
	material.set_shader_parameter("macro_amount", 0.12)
	material.set_shader_parameter("detail_amount", 0.045)
	material.set_shader_parameter("dirt_amount", 0.18)
	# Terrain continues under the shroud — meadow language, not a teal void.
	_apply_meadow_palette(material)
	_bind_terrain_textures(material)
	material.set_shader_parameter("beach_color", Vector3(0.090, 0.153, 0.165))
	material.set_shader_parameter("rock_shore", Vector3(0.078, 0.125, 0.141))
	material.set_shader_parameter("wet_sand", Vector3(0.070, 0.110, 0.125))
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
			var tone := Color("#17262A") if hill_index % 3 != 0 else Color("#1A2A2E")
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
	# GFX-H: seven irregular rings plus an on-map rim belt so zoom
	# 42/68 cannot read a diamond map cut or a grey void.
	for ring in range(1, 8):
		for x in range(-ring, map_size.x + ring, step):
			if _tile_hash(Vector2i(x, -ring), 13 + ring) % 11 != 0:
				_append_edge_tree(transforms_by_path, _edge_tree_path(x, -ring, ring), Vector2(float(x), float(-ring)), ring)
			if _tile_hash(Vector2i(x, map_size.y - 1 + ring), 17 + ring) % 11 != 0:
				_append_edge_tree(transforms_by_path, _edge_tree_path(x, map_size.y - 1 + ring, ring), Vector2(float(x), float(map_size.y - 1 + ring)), ring)
		for y in range(-ring + 1, map_size.y + ring - 1, step):
			if _tile_hash(Vector2i(-ring, y), 19 + ring) % 11 != 0:
				_append_edge_tree(transforms_by_path, _edge_tree_path(-ring, y, ring), Vector2(float(-ring), float(y)), ring)
			if _tile_hash(Vector2i(map_size.x - 1 + ring, y), 23 + ring) % 11 != 0:
				_append_edge_tree(transforms_by_path, _edge_tree_path(map_size.x - 1 + ring, y, ring), Vector2(float(map_size.x - 1 + ring), float(y)), ring)
	_append_rim_woodland(transforms_by_path)
	_spawn_nature_multimeshes(edge_forest_root, transforms_by_path)
	# Trees keep directional shadows. Grass/flowers stay shadowless.
	# Darker forest floor under every fourth canopy. One MultiMesh, not Decals.
	for path_value in transforms_by_path:
		var batch: Array = transforms_by_path[path_value]
		for index in batch.size():
			if index % 4 != 0:
				continue
			floors.append(ContactAO.flatten_transform(batch[index], 2.1))
	ContactAO.spawn_multimesh(edge_forest_root, floors, 0.22)


func _append_rim_woodland(groups: Dictionary) -> void:
	# Trees and rocks on the last two revealed map tiles so the playable
	# AABB does not print as a hard island against the shroud.
	if simulation == null:
		return
	for y in range(map_size.y):
		for x in range(map_size.x):
			var tile := Vector2i(x, y)
			var edge := mini(mini(tile.x, tile.y), mini(map_size.x - 1 - tile.x, map_size.y - 1 - tile.y))
			if edge > 1:
				continue
			if not simulation.is_revealed(tile):
				continue
			if _terrain_occupied_cache.has(_tile_key(tile)) or _is_road_tile(tile):
				continue
			var tile_type := String(simulation.get_tile(tile))
			if tile_type != Defs.TILE_GRASS and tile_type != Defs.TILE_TREE and tile_type != Defs.TILE_ROCK:
				continue
			if _tile_hash(tile, 29) % 5 == 0:
				continue
			if Catalog.ROCKS.size() > 0 and (_tile_hash(tile, 41) % 4 == 0 or tile_type == Defs.TILE_ROCK):
				_append_nature_transform(groups, String(Catalog.ROCKS[_tile_hash(tile, 43) % Catalog.ROCKS.size()]), tile, 3, 0.70, 0.72, 0.28)
			else:
				_append_edge_tree(groups, _edge_tree_path(x, y, 0), Vector2(float(x), float(y)), 0)


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
	var jitter := _deterministic_offset(key_tile, 80 + ring + index, 1.15)
	world_position += Vector3(jitter.x, 0.0, jitter.y)
	# Scale so canopies break the iso-square silhouette at far zoom.
	var scale_value := (2.15 + float(_tile_hash(key_tile, 90 + ring + index) % 80) / 100.0 + float(ring) * 0.22) * ScaleProfile.nature_model_scale(path_value)
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


func _rebuild_opening_dressing() -> void:
	# Presentation-only opening hamlet. Cottages, fences, a well, carts
	# and stacked wood are camera dressing — they do not consume
	# TILE_GRASS or change simulation placement / economy.
	if simulation == null or resource_visuals_root == null:
		return
	if not simulation.is_town_hall_founded():
		return
	var leftover := resource_visuals_root.get_node_or_null("OpeningDress")
	if leftover != null:
		leftover.queue_free()
	var host := Node3D.new()
	host.name = "OpeningDress"
	resource_visuals_root.add_child(host)
	var hall: Vector2i = simulation.town_hall_position
	var reserved := _opening_hamlet_tiles(hall)
	_spawn_opening_hamlet(host, hall, reserved)
	var transforms_by_path: Dictionary = {}
	var inner := 11.0
	var outer := 16.5
	var candidates: Array[Vector2i] = []
	for oy in range(-17, 18):
		for ox in range(-17, 18):
			var tile := hall + Vector2i(ox, oy)
			if reserved.has(_tile_key(tile)):
				continue
			if not simulation.is_inside_map(tile):
				continue
			if String(simulation.get_tile(tile)) != Defs.TILE_GRASS:
				continue
			if _terrain_occupied_cache.has(_tile_key(tile)) or _is_road_tile(tile):
				continue
			if _visual_path_weight(tile) > 0.28 or _hamlet_path_weight(tile) > 0.28:
				continue
			var dist := Vector2(float(ox), float(oy)).length()
			if dist < inner or dist > outer:
				continue
			candidates.append(tile)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _opening_forest_score(a, hall) > _opening_forest_score(b, hall)
	)
	var target := clampi(int(round(float(candidates.size()) * 0.48)), 1, maxi(candidates.size(), 1))
	var planted := 0
	for tile in candidates:
		if planted >= target:
			break
		if _tile_hash(tile, 77) % 11 == 0:
			continue
		# GFX-O: 2.5–3W clearing. Forest on ~48% of the perimeter arc,
		# back and west so the gameplay camera sees meadow + ridge.
		_append_nature_transform(transforms_by_path, _tree_path_for_tile(tile, 0, 3), tile, 0, 0.70, 1.05, 0.42)
		planted += 1
	_spawn_nature_multimeshes(host, transforms_by_path)
	var coverage := 0.0 if candidates.is_empty() else float(planted) / float(candidates.size())
	host.set_meta("opening_clearing_cells", inner)
	host.set_meta("opening_forest_coverage", coverage)
	host.set_meta("opening_forest_count", planted)
	host.set_meta("opening_perimeter_count", candidates.size())


func _opening_hamlet_spec() -> Array:
	# Four cottages + one shed. Anchors sit outside the hall's 4×4.
	return [
		{"kind": "HOUSE", "ox": -3, "oy": 0, "yaw": 90.0, "w": 2, "h": 2},
		{"kind": "HOUSE", "ox": 5, "oy": 1, "yaw": 0.0, "w": 2, "h": 2},
		{"kind": "HOUSE", "ox": 1, "oy": -3, "yaw": 180.0, "w": 2, "h": 2},
		{"kind": "HOUSE", "ox": -2, "oy": 5, "yaw": 0.0, "w": 2, "h": 2},
		{"kind": "BAKERY", "ox": 5, "oy": 4, "yaw": -15.0, "w": 3, "h": 3},
	]


func _opening_hamlet_tiles(hall: Vector2i) -> Dictionary:
	var reserved: Dictionary = {}
	for spec_value in _opening_hamlet_spec():
		var spec: Dictionary = spec_value
		for oy in range(int(spec["h"])):
			for ox in range(int(spec["w"])):
				reserved[_tile_key(hall + Vector2i(int(spec["ox"]) + ox, int(spec["oy"]) + oy))] = true
	for pad in [Vector2i(-1, -2), Vector2i(4, -1), Vector2i(-1, 4), Vector2i(2, 5)]:
		reserved[_tile_key(hall + pad)] = true
	for spec_value in _opening_ridge_tiles(hall):
		reserved[_tile_key(spec_value)] = true
	return reserved


func _hamlet_path_weight(tile: Vector2i) -> float:
	if simulation == null or not simulation.is_town_hall_founded():
		return 0.0
	var hall: Vector2i = simulation.town_hall_position
	var center := Vector2(hall) + Vector2(1.5, 1.5)
	var best := 0.0
	for spec_value in _opening_hamlet_spec():
		var spec: Dictionary = spec_value
		var dest := Vector2(hall) + Vector2(float(spec["ox"]) + float(spec["w"]) * 0.5, float(spec["oy"]) + float(spec["h"]) * 0.5)
		var along := dest - center
		if along.length_squared() < 1.0:
			continue
		var span := along.length()
		var t := clampf((Vector2(tile) - center).dot(along.normalized()) / span, 0.0, 1.0)
		var closest := center + along.normalized() * (t * span)
		var dist := Vector2(tile).distance_to(closest)
		best = maxf(best, clampf(1.0 - dist / 1.35, 0.0, 1.0))
	return best


func _spawn_opening_hamlet(host: Node3D, hall: Vector2i, reserved: Dictionary) -> void:
	var cottages := 0
	for spec_value in _opening_hamlet_spec():
		var spec: Dictionary = spec_value
		var tile := hall + Vector2i(int(spec["ox"]), int(spec["oy"]))
		if not _dress_footprint_free(tile, int(spec["w"]), int(spec["h"])):
			continue
		if _spawn_dress_cottage(host, String(spec["kind"]), tile, int(spec["w"]), int(spec["h"]), float(spec["yaw"])):
			cottages += 1
	# Well from barrel + stone + fence. No authored well mesh.
	_spawn_dress_prop(host, "barrel", hall + Vector2i(-1, -2), 0.0, 1.05, "DressWellBarrel")
	_spawn_dress_prop(host, "stone_stack", hall + Vector2i(-1, -2), 40.0, 0.72, "DressWellStone", Vector3(-0.55, 0.0, 0.35))
	_spawn_dress_prop(host, "fence", hall + Vector2i(-1, -2), 0.0, 0.85, "DressWellFence", Vector3(0.9, 0.0, 0.0))
	_spawn_dress_prop(host, "cart", hall + Vector2i(4, -1), -18.0, 0.78, "DressCart")
	_spawn_dress_prop(host, "wood_stack", hall + Vector2i(2, 5), 12.0, 1.05, "DressWoodNorth")
	_spawn_dress_prop(host, "wood_stack", hall + Vector2i(1, -3), -8.0, 0.92, "DressWoodSouth", Vector3(1.4, 0.0, -0.6))
	_spawn_dress_prop(host, "fence", hall + Vector2i(-3, -1), 90.0, 1.0, "DressFenceWestA")
	_spawn_dress_prop(host, "fence", hall + Vector2i(-3, 1), 90.0, 1.0, "DressFenceWestB")
	_spawn_dress_prop(host, "fence", hall + Vector2i(5, 0), 0.0, 1.0, "DressFenceEast")
	_spawn_dress_prop(host, "fence", hall + Vector2i(-4, 3), 90.0, 1.0, "DressFenceWestC")
	_spawn_dress_prop(host, "fence", hall + Vector2i(6, 3), 0.0, 1.0, "DressFenceEastB")
	_spawn_dress_prop(host, "barrel", hall + Vector2i(5, 1), 25.0, 0.88, "DressBarrelEast", Vector3(-0.8, 0.0, 1.1))
	_spawn_dress_prop(host, "stone_stack", hall + Vector2i(4, 3), 12.0, 0.55, "DressCrossroadsStone")
	_spawn_dress_prop(host, "crate", hall + Vector2i(4, 2), -8.0, 0.72, "DressSignCrate", Vector3(0.4, 0.0, 0.2))
	_spawn_opening_crops(host, hall + Vector2i(3, -4))
	_spawn_dress_pond(host, hall + Vector2i(-5, -3), Vector2(5.4, 3.6), "DressPond")
	_spawn_dress_prop(host, "stone_stack", hall + Vector2i(-5, -2), 22.0, 0.70, "DressPondStoneA", Vector3(1.6, 0.0, 0.8))
	_spawn_dress_prop(host, "fence", hall + Vector2i(-6, -4), 0.0, 0.92, "DressPondFence")
	_spawn_opening_ridge(host, hall)
	host.set_meta("hamlet_cottages", cottages)
	host.set_meta("hamlet_reserved", reserved.size())
	host.set_meta("hamlet_pond", 1)
	host.set_meta("hamlet_ridge", 1)


func _opening_forest_score(tile: Vector2i, hall: Vector2i) -> float:
	# Camera looks from +Y. Prefer the back (-Y) and west (-X) so the
	# opening meadow stays readable and the forest frames 40–55%.
	var d := tile - hall
	return -float(d.y) * 1.35 - float(d.x) * 0.40 + float(_tile_hash(tile, 3) % 7) * 0.08


func _opening_ridge_tiles(hall: Vector2i) -> Array[Vector2i]:
	# GFX-P: one back/upper formation. No large foreground rocks.
	# Camera looks from +tile.y, so back is -Y.
	return [
		hall + Vector2i(4, -3),
		hall + Vector2i(5, -4),
		hall + Vector2i(6, -3),
		hall + Vector2i(7, -4),
		hall + Vector2i(5, -2),
		hall + Vector2i(3, -4),
		hall + Vector2i(6, -5),
		hall + Vector2i(4, -5),
	]


func opening_camera_focus() -> Vector3:
	# Town Hall at about 53% across, 56% down in the opening viewport.
	if simulation == null or not simulation.is_town_hall_founded():
		return Vector3.ZERO
	var hall: Vector2i = simulation.town_hall_position
	var center := tile_to_world(Vector2(hall) + Vector2(1.5, 1.5))
	var w := ScaleProfile.TOWN_HALL_WIDTH_METRES
	return center + Vector3(-0.12 * w, 0.0, 0.18 * w)


func _spawn_opening_ridge(host: Node3D, hall: Vector2i) -> void:
	# GFX-P: one back/upper rock formation 1.5–2.0B × 0.4–0.7B plus
	# a west-forest creek ribbon. Cosmetic only. No foreground rocks.
	var ridge := Node3D.new()
	ridge.name = "DressRidge"
	ridge.set_meta("cosmetic_only", true)
	host.add_child(ridge)
	var highlight := _ridge_material(Color("#B9AC92"), 0.92)
	var midtone := _ridge_material(Color("#918C79"), 0.92)
	var shade := _ridge_material(Color("#61675B"), 0.92)
	var b := ScaleProfile.TOWN_HALL_WIDTH_METRES
	var r := ScaleProfile.road_width_metres()
	var house_h := 0.930 * 4.40
	var tiles := _opening_ridge_tiles(hall)
	var index := 0
	for tile in tiles:
		if not simulation.is_inside_map(tile):
			continue
		var block := MeshInstance3D.new()
		block.name = "RidgeRock_%d" % index
		var wide := b * (0.14 + float(index % 5) * 0.03)
		wide = clampf(wide, b * 0.12, b * 0.28)
		var tall := minf(house_h * 0.35, b * 0.16)
		block.mesh = _bevelled_ridge_mesh(index, wide, tall)
		var world := tile_to_world(Vector2(tile))
		block.position = world + Vector3(float(index % 2) * 0.28, 0.0, float((index + 1) % 2) * -0.22)
		block.rotation.y = float(index) * 0.47
		if index % 3 == 0:
			block.material_override = highlight
		elif index % 3 == 1:
			block.material_override = midtone
		else:
			block.material_override = shade
		ridge.add_child(block)
		if Catalog.ROCKS.size() > 1:
			_spawn_kaykit_ridge_rock(ridge, tile, index, 0.70 + float(index % 4) * 0.08)
		index += 1
	var formation := MeshInstance3D.new()
	formation.name = "RidgeFormation"
	formation.mesh = _back_ridge_formation_mesh(b * 1.72, b * 0.52)
	var anchor := tiles[2] if tiles.size() > 2 else hall + Vector2i(0, -7)
	formation.position = tile_to_world(Vector2(anchor)) + Vector3(0.0, 0.0, -0.8)
	formation.rotation.y = 0.18
	formation.material_override = midtone
	ridge.add_child(formation)
	var formation_hi := MeshInstance3D.new()
	formation_hi.name = "RidgeFormationCap"
	formation_hi.mesh = _back_ridge_formation_mesh(b * 0.95, b * 0.38)
	formation_hi.position = formation.position + Vector3(-1.6, 0.0, -1.1)
	formation_hi.rotation.y = -0.31
	formation_hi.material_override = highlight
	ridge.add_child(formation_hi)
	var formation_shade := MeshInstance3D.new()
	formation_shade.name = "RidgeFormationShade"
	formation_shade.mesh = _back_ridge_formation_mesh(b * 0.82, b * 0.34)
	formation_shade.position = formation.position + Vector3(2.1, 0.0, -0.6)
	formation_shade.rotation.y = 0.52
	formation_shade.material_override = shade
	ridge.add_child(formation_shade)
	_spawn_meandering_creek(ridge, hall, r)


func _spawn_kaykit_ridge_rock(ridge: Node3D, tile: Vector2i, index: int, scale_mul: float) -> void:
	var path := String(Catalog.ROCKS[1 + (index % (Catalog.ROCKS.size() - 1))])
	var packed := load(path) as PackedScene
	if packed == null:
		return
	var prop := packed.instantiate()
	prop.name = "RidgeKaykit_%d" % index
	prop.position = tile_to_world(Vector2(tile)) + Vector3(0.55, 0.0, -0.40)
	prop.rotation.y = float(index) * 0.73
	prop.scale = Vector3.ONE * clampf(scale_mul, 0.55, 1.15)
	var tint := Color("#918C79") if index % 3 != 0 else Color("#B9AC92")
	if index % 3 == 2:
		tint = Color("#61675B")
	for child in prop.find_children("*", "MeshInstance3D", true, false):
		var mesh_i := child as MeshInstance3D
		var mat := StandardMaterial3D.new()
		mat.albedo_color = tint
		mat.roughness = 0.92
		mat.metallic = 0.0
		mesh_i.material_override = mat
	ridge.add_child(prop)


func _spawn_meandering_creek(ridge: Node3D, hall: Vector2i, road_w: float) -> void:
	# GFX-P: west-forest ribbon. Continues under the trees. Not a
	# diagonal wedge across the village. Width 0.55–0.75R ±12%.
	var tiles: Array[Vector2i] = [
		hall + Vector2i(-5, -2),
		hall + Vector2i(-6, 1),
		hall + Vector2i(-6, 4),
		hall + Vector2i(-5, 7),
		hall + Vector2i(-7, 10),
		hall + Vector2i(-8, 13),
		hall + Vector2i(-9, 16),
	]
	var points: Array[Vector3] = []
	for tile in tiles:
		if simulation != null and simulation.is_inside_map(tile):
			points.append(tile_to_world(Vector2(tile)) + Vector3(0.0, 0.04, 0.0))
	if points.size() < 5:
		return
	var width := clampf(road_w * 0.65, road_w * 0.55, road_w * 0.75)
	var bank := _ridge_material(Color("#786C50"), 0.92)
	var shallow := _ridge_material(Color("#668F89"), 0.42)
	var water := StandardMaterial3D.new()
	water.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	water.albedo_color = Color("#345F65")
	water.roughness = 0.35
	water.metallic = 0.0
	var mud := MeshInstance3D.new()
	mud.name = "DressCreekBank"
	mud.mesh = _creek_ribbon_mesh(points, width + road_w * 0.40, road_w)
	mud.material_override = bank
	mud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ridge.add_child(mud)
	var shallows := MeshInstance3D.new()
	shallows.name = "DressCreekShallow"
	shallows.mesh = _creek_ribbon_mesh(points, width * 1.18, road_w)
	shallows.position.y = 0.012
	shallows.material_override = shallow
	shallows.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ridge.add_child(shallows)
	var creek := MeshInstance3D.new()
	creek.name = "DressCreek"
	creek.mesh = _creek_ribbon_mesh(points, width, road_w)
	creek.position.y = 0.022
	creek.material_override = water
	creek.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ridge.add_child(creek)


func _creek_ribbon_mesh(points: Array[Vector3], width: float, road_w: float = 2.425) -> ArrayMesh:
	# Sampled Curve3D. Full width at the ends — no triangular cap.
	# bake 0.15R, sample 0.20R, width wobble ±12%.
	var curve := Curve3D.new()
	for point in points:
		curve.add_point(point)
	curve.bake_interval = maxf(0.12, 0.15 * road_w)
	var length := maxf(curve.get_baked_length(), 1.0)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := maxf(0.16, 0.20 * road_w)
	var samples := maxi(24, int(ceil(length / step)))
	var prev_left := Vector3.ZERO
	var prev_right := Vector3.ZERO
	for i in samples + 1:
		var offset := length * float(i) / float(samples)
		var pos := curve.sample_baked(offset)
		var ahead := curve.sample_baked(minf(length, offset + step))
		var tangent := ahead - pos
		tangent.y = 0.0
		if tangent.length() < 0.001:
			tangent = Vector3(0.0, 0.0, 1.0)
		var wobble := 1.0 + sin(float(i) * 0.61 + width) * 0.12
		var side := Vector3(-tangent.z, 0.0, tangent.x).normalized() * (width * 0.5 * wobble)
		var left := pos + side
		var right := pos - side
		if i > 0:
			_ridge_tri(tool, prev_left, prev_right, right)
			_ridge_tri(tool, prev_left, right, left)
		prev_left = left
		prev_right = right
	tool.generate_normals()
	return tool.commit()


func _back_ridge_formation_mesh(width: float, height: float) -> ArrayMesh:
	# One mass 1.5–2.0B wide, 0.4–0.7B tall. Irregular bevel, not a box.
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := 11
	var top: Array[Vector3] = []
	var bottom: Array[Vector3] = []
	for i in count:
		var ang := TAU * float(i) / float(count)
		var radial := 0.78 + float((i * 7) % 5) * 0.05
		var rx := width * 0.50 * radial
		var rz := width * 0.28 * (0.82 + float((i * 3) % 4) * 0.06)
		top.append(Vector3(cos(ang) * rx, height * (0.72 + float(i % 3) * 0.08), sin(ang) * rz))
		bottom.append(Vector3(cos(ang) * rx * 1.08, 0.0, sin(ang) * rz * 1.10))
	var apex := Vector3(0.15 * width, height * 1.04, -0.06 * width)
	for i in count:
		var n := (i + 1) % count
		_ridge_tri(tool, apex, bottom[i], bottom[n])
		_ridge_tri(tool, top[i], top[n], apex)
		_ridge_tri(tool, bottom[i], top[i], top[n])
		_ridge_tri(tool, bottom[i], top[n], bottom[n])
	tool.generate_normals()
	return tool.commit()


func _ridge_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = 0.0
	return material


func _bevelled_ridge_mesh(seed_id: int, width: float, height: float) -> ArrayMesh:
	# Low-poly bevelled rock: irregular top ring, darker implicit sides.
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := 8 + (absi(seed_id) % 5)
	var top: Array[Vector3] = []
	var bottom: Array[Vector3] = []
	for i in count:
		var ang := TAU * float(i) / float(count)
		var jitter := 0.72 + float((absi(seed_id * 17 + i * 13) % 40)) / 100.0
		var r := width * 0.48 * jitter
		top.append(Vector3(cos(ang) * r, height, sin(ang) * r * 0.78))
		bottom.append(Vector3(cos(ang) * r * 1.08, 0.0, sin(ang) * r * 0.86))
	var apex := Vector3(0.0, height * 0.18, 0.0)
	for i in count:
		var n := (i + 1) % count
		_ridge_tri(tool, apex, bottom[i], bottom[n])
		_ridge_tri(tool, top[i], top[n], Vector3(0.0, height * 1.02, 0.0))
		_ridge_tri(tool, bottom[i], top[i], top[n])
		_ridge_tri(tool, bottom[i], top[n], bottom[n])
	tool.generate_normals()
	return tool.commit()


func _ridge_tri(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	tool.set_normal(Vector3.UP)
	tool.add_vertex(a)
	tool.set_normal(Vector3.UP)
	tool.add_vertex(b)
	tool.set_normal(Vector3.UP)
	tool.add_vertex(c)


func _spawn_opening_crops(host: Node3D, origin: Vector2i) -> void:
	# Presentation crop rows. Dirt plots + wheat so the opening and
	# showcase cameras read fields, not a lawn. No TILE_GRASS consume.
	var row := 0
	while row < 4:
		var col := 0
		while col < 5:
			var tile := origin + Vector2i(col, 0)
			var nudge := Vector3(float(col) * 0.15, 0.0, -float(row) * 0.85)
			_spawn_dress_prop(host, "dirt_plot", tile, 6.0, 0.78, "DressPlot_%d_%d" % [row, col], nudge)
			_spawn_dress_prop(host, "wheat_crop", tile, 4.0, 1.18, "DressWheat_%d_%d" % [row, col], nudge + Vector3(0.0, 0.04, 0.0))
			col += 1
		row += 1
	_spawn_dress_prop(host, "fence", origin + Vector2i(-1, 0), 90.0, 0.95, "DressCropFenceA")
	_spawn_dress_prop(host, "fence", origin + Vector2i(4, 0), 90.0, 0.95, "DressCropFenceB")


func _spawn_dress_pond(host: Node3D, tile: Vector2i, size: Vector2, node_name: String) -> void:
	var pond := MeshInstance3D.new()
	pond.name = node_name
	var mesh := PlaneMesh.new()
	mesh.size = size
	pond.mesh = mesh
	pond.position = tile_to_world(Vector2(tile)) + Vector3(0.0, 0.045, 0.0)
	var water := StandardMaterial3D.new()
	water.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	water.albedo_color = Color(0.16, 0.30, 0.34, 0.90)
	water.roughness = 0.10
	water.metallic = 0.28
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.emission_enabled = true
	water.emission = Color(0.08, 0.16, 0.20)
	water.emission_energy_multiplier = 0.18
	pond.material_override = water
	pond.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	host.add_child(pond)


func _dress_footprint_free(tile: Vector2i, width: int, height: int) -> bool:
	for oy in range(height):
		for ox in range(width):
			var sample := tile + Vector2i(ox, oy)
			if simulation == null or not simulation.is_inside_map(sample):
				return false
			if String(simulation.get_tile(sample)) != Defs.TILE_GRASS:
				return false
			if _terrain_occupied_cache.has(_tile_key(sample)) or _is_road_tile(sample):
				return false
	return true


func _spawn_dress_cottage(host: Node3D, kind: String, tile: Vector2i, width: int, height: int, yaw_deg: float) -> bool:
	var packed := load(Catalog.building_path(kind)) as PackedScene
	if packed == null:
		return false
	var wrap := Node3D.new()
	wrap.name = "Dress_%s_%d_%d" % [kind, tile.x, tile.y]
	var center := Vector2(tile) + Vector2(float(width - 1), float(height - 1)) * 0.5
	wrap.position = tile_to_world(center)
	wrap.rotation.y = deg_to_rad(yaw_deg)
	var model := packed.instantiate()
	model.name = "Model"
	model.scale = Vector3.ONE * ScaleProfile.building_scale(kind)
	wrap.add_child(model)
	BuildingMaterials.apply(model, tile.x * 31 + tile.y, kind)
	_force_cast_shadows(model)
	_dress_cottage_trim(wrap, kind, width, height)
	var footprint := Vector2i(width, height)
	var world_size := ScaleProfile.footprint_world_size(footprint)
	var disc := ContactAO.make_instance("ContactAO", Vector2(world_size.x * 1.08, world_size.y * 1.08), 0.24)
	disc.position = Vector3(0.0, 0.018, 0.0)
	wrap.add_child(disc)
	var light := OmniLight3D.new()
	light.name = "DressWindow"
	light.light_color = Identity.PALETTE_WINDOW
	light.light_energy = 1.25
	light.omni_range = 7.4
	light.shadow_enabled = false
	light.position = Vector3(0.0, 1.15, 0.15)
	light.visible = false
	wrap.add_child(light)
	var pane := MeshInstance3D.new()
	pane.name = "DressWindowPane"
	var pane_mesh := BoxMesh.new()
	pane_mesh.size = Vector3(0.55, 0.42, 0.06)
	pane.mesh = pane_mesh
	pane.position = Vector3(0.0, 1.22, 0.42)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Identity.PALETTE_WINDOW
	glow.emission_enabled = true
	glow.emission = Identity.PALETTE_WINDOW
	glow.emission_energy_multiplier = 2.40
	pane.material_override = glow
	pane.visible = false
	wrap.add_child(pane)
	host.add_child(wrap)
	return true


func _dress_cottage_trim(wrap: Node3D, kind: String, width: int, height: int) -> void:
	var plaster := StandardMaterial3D.new()
	plaster.albedo_color = BuildingMaterials.WARM_PLASTER
	plaster.roughness = 0.95
	var timber := StandardMaterial3D.new()
	timber.albedo_color = BuildingMaterials.DARK_TIMBER
	timber.roughness = 0.92
	var stone := StandardMaterial3D.new()
	stone.albedo_color = BuildingMaterials.WEATHERED_STONE
	stone.roughness = 0.85
	var w := float(width) * ScaleProfile.LOGICAL_CELL_METRES * 0.42
	var d := float(height) * ScaleProfile.LOGICAL_CELL_METRES * 0.42
	var plinth := MeshInstance3D.new()
	plinth.name = "DressTrimPlinth"
	var plinth_mesh := BoxMesh.new()
	plinth_mesh.size = Vector3(w * 2.05, 0.28, d * 2.05)
	plinth.mesh = plinth_mesh
	plinth.position = Vector3(0.0, 0.14, 0.0)
	plinth.material_override = stone
	wrap.add_child(plinth)
	for index in 4:
		var post := MeshInstance3D.new()
		post.name = "DressTrimTimber_%d" % index
		var post_mesh := BoxMesh.new()
		post_mesh.size = Vector3(0.12, 1.35, 0.12)
		post.mesh = post_mesh
		var sx := -1.0 if index < 2 else 1.0
		var sz := -1.0 if index % 2 == 0 else 1.0
		post.position = Vector3(sx * w * 0.92, 0.78, sz * d * 0.88)
		post.material_override = timber
		wrap.add_child(post)
	if kind == "HOUSE" or kind == "BAKERY":
		var awning := MeshInstance3D.new()
		awning.name = "DressTrimAwning"
		var awning_mesh := BoxMesh.new()
		awning_mesh.size = Vector3(w * 0.9, 0.06, 0.42)
		awning.mesh = awning_mesh
		awning.position = Vector3(0.0, 1.15, d * 1.05)
		awning.rotation.x = -0.26
		awning.material_override = timber
		wrap.add_child(awning)
	var band := MeshInstance3D.new()
	band.name = "DressTrimPlaster"
	var band_mesh := BoxMesh.new()
	band_mesh.size = Vector3(w * 1.6, 0.22, 0.07)
	band.mesh = band_mesh
	band.position = Vector3(0.0, 0.72, d * 0.98)
	band.material_override = plaster
	wrap.add_child(band)


func _spawn_dress_prop(host: Node3D, prop_key: String, tile: Vector2i, yaw_deg: float, scale_mul: float, node_name: String, nudge := Vector3.ZERO) -> void:
	if not Catalog.WORKYARD_PROPS.has(prop_key):
		return
	if simulation == null or not simulation.is_inside_map(tile):
		return
	var packed := load(String(Catalog.WORKYARD_PROPS[prop_key])) as PackedScene
	if packed == null:
		return
	var prop := packed.instantiate()
	prop.name = node_name
	prop.position = tile_to_world(Vector2(tile)) + nudge
	prop.rotation.y = deg_to_rad(yaw_deg)
	prop.scale = Vector3.ONE * ScaleProfile.world_prop_scale(prop_key) * scale_mul
	_force_cast_shadows(prop)
	if prop_key == "wheat_crop" or prop_key == "dirt_plot":
		var fill := Color("#C9A24A") if prop_key == "wheat_crop" else Color("#886C49")
		for child in prop.find_children("*", "MeshInstance3D", true, false):
			var mesh_i := child as MeshInstance3D
			var mat := StandardMaterial3D.new()
			mat.albedo_color = fill
			mat.roughness = 0.78 if prop_key == "wheat_crop" else 0.92
			mat.metallic = 0.0
			mat.vertex_color_use_as_albedo = false
			mesh_i.material_override = mat
	if prop_key == "wood_stack":
		var fire := OmniLight3D.new()
		fire.name = "DressFire"
		fire.light_color = Identity.PALETTE_TORCH
		fire.light_energy = 1.35
		fire.omni_range = 6.4
		fire.shadow_enabled = false
		fire.position = Vector3(0.0, 0.55, 0.0)
		fire.visible = false
		prop.add_child(fire)
	host.add_child(prop)


func _apply_dress_lights(window_color: Color, torch_color: Color, torch_range: float, night: bool) -> void:
	if resource_visuals_root == null:
		return
	var dress := resource_visuals_root.get_node_or_null("OpeningDress")
	if dress == null:
		return
	for child in dress.get_children():
		var window: OmniLight3D = child.find_child("DressWindow", true, false) as OmniLight3D
		if window != null:
			window.light_color = window_color
			window.omni_range = clampf(torch_range, 3.2, 9.0)
			window.light_energy = 1.25
			window.visible = night
		var pane: MeshInstance3D = child.find_child("DressWindowPane", true, false) as MeshInstance3D
		if pane != null:
			pane.visible = night
			if pane.material_override is StandardMaterial3D:
				var glow := pane.material_override as StandardMaterial3D
				glow.emission = window_color
				glow.albedo_color = window_color
		var fire: OmniLight3D = child.find_child("DressFire", true, false) as OmniLight3D
		if fire != null:
			fire.light_color = torch_color
			fire.omni_range = clampf(torch_range, 3.2, 8.0)
			fire.light_energy = 1.35
			fire.visible = night


func _force_cast_shadows(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for child in node.get_children():
		_force_cast_shadows(child)


func _tree_path_for_tile(tile: Vector2i, index: int, neighbors: int) -> String:
	# GFX-K woodland: 55% conifer / 25% broadleaf / 20% understory at the edge.
	var roll := _tile_hash(tile, 17 + index) % 100
	if neighbors <= 1:
		if roll < 55 and Catalog.CONIFERS.size() > 0:
			return String(Catalog.CONIFERS[_tile_hash(tile, 31 + index) % Catalog.CONIFERS.size()])
		if roll < 80 and Catalog.DECIDUOUS.size() > 0:
			return String(Catalog.DECIDUOUS[_tile_hash(tile, 41 + index) % Catalog.DECIDUOUS.size()])
		if Catalog.UNDERSTORY.size() > 0:
			return String(Catalog.UNDERSTORY[_tile_hash(tile, 51 + index) % Catalog.UNDERSTORY.size()])
	if neighbors >= 2:
		if roll < 55 and Catalog.CONIFERS.size() > 0:
			return String(Catalog.CONIFERS[_tile_hash(tile, 31 + index) % Catalog.CONIFERS.size()])
		if roll < 80 and Catalog.DECIDUOUS.size() > 0:
			return String(Catalog.DECIDUOUS[_tile_hash(tile, 41 + index) % Catalog.DECIDUOUS.size()])
		if Catalog.EDGE_TREES.size() > 0:
			return String(Catalog.EDGE_TREES[_tile_hash(tile, 51 + index) % Catalog.EDGE_TREES.size()])
	return String(Catalog.TREES[_tile_hash(tile, 17 + index) % Catalog.TREES.size()])


func _tree_scale_range(path_value: String, neighbors: int) -> Vector2:
	# Height bands from the GFX-K woodland table.
	if String(path_value).contains("fir_tall") or String(path_value).contains("spruce"):
		return Vector2(0.85, 0.50)
	if String(path_value).contains("fir"):
		return Vector2(0.70, 0.40)
	if String(path_value).contains("broadleaf") or String(path_value).contains("oak") or String(path_value).contains("birch"):
		return Vector2(0.80, 0.45)
	if String(path_value).contains("bush") or String(path_value).contains("under"):
		return Vector2(0.35, 0.30)
	if neighbors <= 1:
		return Vector2(0.70, 0.40)
	return Vector2(0.82, 0.40)


func _is_tree_path(path_value: String) -> bool:
	var name := path_value.get_file().get_basename()
	return name in ["fir", "fir_tall", "spruce", "broadleaf", "oak", "birch", "fir_lod", "broadleaf_lod"]


func _is_scatter_path(path_value: String) -> bool:
	var name := path_value.get_file().get_basename()
	return name in ["grass", "flowers", "bush"]


func _foliage_material(mesh: Mesh, path_value: String) -> Material:
	if String(path_value).contains("wheat"):
		var gold := StandardMaterial3D.new()
		gold.albedo_color = Identity.PALETTE_WHEAT
		gold.roughness = 0.78
		gold.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		return gold
	if _is_scatter_path(path_value) and not String(path_value).contains("bush"):
		# Keep authored tuft / blossom colours. The tree shader paints short
		# blades as trunk-brown, which is the black-ant read.
		return null
	var material := ShaderMaterial.new()
	material.shader = FoliageShader
	var tint := Color("#4B6841")
	var lift := 1.08
	if String(path_value).contains("spruce") or String(path_value).contains("fir_tall"):
		tint = Color("#284735")
		lift = 1.12
	elif String(path_value).contains("fir"):
		tint = Color("#34543B")
		lift = 1.10
	elif String(path_value).contains("birch"):
		tint = Color("#82945D")
		lift = 1.16
	elif String(path_value).contains("broadleaf") or String(path_value).contains("oak"):
		tint = Color("#4B6841")
		lift = 1.14
	elif String(path_value).contains("bush") or String(path_value).contains("under"):
		tint = Color("#314A32")
		lift = 1.08
	material.set_shader_parameter("albedo_color", Vector3(tint.r, tint.g, tint.b))
	material.set_shader_parameter("trunk_color", Vector3(0.28, 0.20, 0.14))
	material.set_shader_parameter("canopy_lift", lift)
	material.set_shader_parameter("atmosphere", _atmosphere_scale)
	material.set_shader_parameter("wind", 0.08)
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
	material.albedo_color = Color("#2A4024") * _atmosphere_scale
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
