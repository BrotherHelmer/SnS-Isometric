class_name ProductionWorldView3D
extends Node3D

const FrameProfiler = preload("res://src/GodotClient3D/Scripts/production_frame_profiler.gd")

const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Catalog = preload("res://src/GodotClient3D/Scripts/production_asset_catalog.gd")
const ScaleProfile = preload("res://src/GodotClient3D/Scripts/production_scale_profile.gd")
const BuildingView = preload("res://src/GodotClient3D/Scripts/production_building_view_3d.gd")
const WarmupCatalog = preload("res://src/GodotClient3D/Scripts/production_asset_catalog.gd")
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
const FOG_MASK_DIVISOR := 2
const FOG_VOLUME_PAD_METRES := 0.35
const WATER_Y := -0.22
const WATER_PAD_METRES := 2400.0
const BEACH_MARGIN_TILES := 2
const BEACH_MARGIN_METRES := 5.0
const COAST_JUT_METRES := 14.0
const BEACH_APRON_PAD_METRES := 36.0
const SHORE_FADE_METRES := 4.0
const HORIZON_RADIUS_METRES := 920.0
const FOG_VOLUME_HEIGHT_METRES := 56.0
const FOG_VOLUME_CENTER_Y := 18.0
const FOG_DISPLAY_UPSAMPLE := 8
const FOG_UNKNOWN_BASE := Vector3(0.090, 0.153, 0.165) # #17272A
const FOG_MIST_BASE := Vector3(0.090, 0.153, 0.165) # #17272A
const FOG_VISIBLE := 0
const FOG_EXPLORED := 115
const FOG_UNEXPLORED := 255
const GROUND_PATCH_CHUNK_METRES := 40.0
const CHUNK_TILES := 32
const CHUNK_LOD_NONE := 0
const CHUNK_LOD_FAR := 1
const CHUNK_LOD_NEAR := 2
const STREAM_BUDGET_USEC := 7000
const STREAM_NEAR_CHUNKS := 1
const STREAM_FAR_CHUNKS := 3
const STREAM_OPENING_MAX := 9
const DRESS_BUILDING_KINDS := [
	"HOUSE", "BAKERY", "FARM", "LUMBER_CAMP", "SAWMILL", "QUARRY",
	"STOREHOUSE", "WATCHTOWER", "BARRACKS", "TOWN_HALL", "CASTLE",
	"WALL", "LUMEN_PILLAR", "CLAIMANT_OUTPOST", "WYRD_HARVESTER", "WYRD_REFINER", "ENEMY_CAMP"
]

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
var seal_beacon: Node3D
var seal_beacon_light: OmniLight3D
var seal_beacon_column: MeshInstance3D
var seal_ward_ring: MeshInstance3D
var seal_wave: MeshInstance3D
var seal_palisade_root: Node3D
var seal_look_key := ""
var channel_flash: Node3D
var channel_flash_ring: MeshInstance3D
var channel_flash_light: OmniLight3D
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
# Hotfix 6: explored lattice cache, filled incrementally from the
# insertion-ordered revealed_tiles dict (rebuilt on clear/load).
var _explored_lattice := PackedByteArray()
var _explored_lattice_size := Vector2i.ZERO
var _explored_lattice_dict: Dictionary = {}
var _explored_lattice_count := 0
var _inside_lattice := PackedByteArray()
var _inside_lattice_size := Vector2i.ZERO
var _inside_lattice_sim: Object = null
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
var chunk_root: Node3D
var chunk_nodes: Dictionary = {}
var chunk_lod: Dictionary = {}
var chunk_queue: Array[Vector2i] = []
var chunks_near := 0
var chunks_far := 0
var last_stream_ms := 0.0
var last_stream_hitches := 0
var camera_world := Vector3.ZERO
var camera_zoom := 32.0
var stream_enabled := true


func setup(simulation_value, world_snapshot: Dictionary, quality: Dictionary = {}) -> void:
	# The screen fog quad is parented to the camera, not to this node, so the
	# child wipe below never freed it. A new realm with another seed kept the
	# old quad and its stale fog mask, which covered the whole new map.
	_free_camera_fog_screens()
	ProductionBuildingView3D.vfx_density = float(quality.get("vfx_density", 1.0))
	if get_child_count() > 0:
		for child in get_children():
			remove_child(child)
			child.free()
		terrain_root = null
		chunk_root = null
		chunk_nodes.clear()
		chunk_lod.clear()
		chunk_queue.clear()
		chunks_near = 0
		chunks_far = 0
		last_stream_hitches = 0
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
		_building_snapshot_hashes.clear()
		character_views.clear()
		road_views.clear()
		_road_merged.clear()
		_road_merge_dirty.clear()
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
	_rebake_queue.clear()
	_rebake_job = {}
	_stream_job = {}
	_chunk_occupation_hashes.clear()
	simulation = simulation_value
	map_size = Vector2i(world_snapshot.get("map_size", Vector2i.ZERO))
	visual_seed = int(world_snapshot.get("seed", 1))
	foliage_density = clampf(float(quality.get("foliage_density", 1.0)), 0.25, 1.0)
	grass_density = clampf(float(quality.get("grass_density", quality.get("foliage_density", 1.0))), 0.25, 1.0)
	water_detail = clampf(float(quality.get("water_detail", 1.0)), 0.2, 1.0)
	civilian_animation_budget = maxi(12, roundi(32.0 * clampf(float(quality.get("animation_lod", 1.0)), 0.4, 1.0)))
	_create_roots()
	_init_chunk_streaming()
	_rebuild_water()
	_rebuild_world_rim(true)
	_rebuild_horizon()
	_sync_fog(true)
	_rebuild_opening_dressing()
	_rebuild_building_halos(true)
	_create_shard_marker()
	_stream_opening_chunks()
	# The first sync_frame used to remesh every opening chunk because
	# these signatures stayed 0. That doubled start_new_3d past 2 s.
	terrain_height_signature = _calculate_height_signature()
	terrain_occupation_signature = _calculate_occupation_signature()
	_chunk_occupation_hashes = _calculate_chunk_occupation_hashes()


func bind_fog_overlay(_camera: Camera3D) -> void:
	fog_overlay_camera = _camera
	if fog_visibility_texture != null:
		_ensure_fog_screen()


var _terrain_lookup_sig := -1


## Every input of _refresh_terrain_lookups: road keys and, per building,
## id / position / construction / type / planned_type / footprint.
func _terrain_lookup_signature() -> int:
	if simulation == null:
		return 0
	var parts: Array = [simulation.connected_roads.hash() if simulation.connected_roads != null else 0, map_size]
	for building_value in simulation.buildings:
		var b: Dictionary = building_value
		parts.append([b.get("id", 0), b.get("position", Vector2i.ZERO), b.get("construction", false), b.get("type", ""), b.get("planned_type", ""), b.get("footprint", null)])
	return parts.hash()


func sync_frame(frame_snapshot: Dictionary) -> void:
	# One lookup pass per frame. GFX-E corner averaging used to call
	# _terrain_color ~16× per cell, and each call scanned every building
	# for roads — that is the 8 s new-game / 112 s showcase first-frame.
	var _pf1 := FrameProfiler.t0()
	# Hotfix 7: rebuild the lookups only when one of their inputs changed.
	var lookup_sig := _terrain_lookup_signature()
	if lookup_sig != _terrain_lookup_sig or not _terrain_lookups_ready:
		_refresh_terrain_lookups()
		_terrain_lookup_sig = lookup_sig
	FrameProfiler.add("wv._refresh_terrain_lookups", _pf1)
	var _pf_sig := FrameProfiler.t0()
	var next_height_signature := _calculate_height_signature()
	var next_occupation := _calculate_occupation_signature()
	FrameProfiler.add("wv.signatures", _pf_sig)
	if next_height_signature != terrain_height_signature:
		var _pf_rt := FrameProfiler.t0()
		_rebuild_terrain()
		FrameProfiler.add("wv._rebuild_terrain", _pf_rt)
	elif next_occupation != terrain_occupation_signature:
		var _pf_ro := FrameProfiler.t0()
		_rebake_occupied_chunks()
		FrameProfiler.add("wv._rebake_occupied_chunks", _pf_ro)
		# Hotfix 3: the rebake never stored the new signature, so after the
		# first road or building every frame rebaked every chunk (~260 ms).
		terrain_occupation_signature = next_occupation
	var revealed_count := int(frame_snapshot.get("revealed_count", simulation.revealed_tiles.size()))
	var reveal_changed := revealed_count != last_revealed_count
	if reveal_changed:
		_enqueue_revealed_chunks()
	var _pf2 := FrameProfiler.t0()
	_sync_fog(false)
	FrameProfiler.add("wv._sync_fog", _pf2)
	var _pf3 := FrameProfiler.t0()
	_sync_roads(frame_snapshot.get("roads", []))
	FrameProfiler.add("wv._sync_roads", _pf3)
	var _pf4 := FrameProfiler.t0()
	_sync_buildings(frame_snapshot.get("buildings", []))
	FrameProfiler.add("wv._sync_buildings", _pf4)
	var _pf5 := FrameProfiler.t0()
	_rebuild_building_halos(false)
	FrameProfiler.add("wv._rebuild_building_halos", _pf5)
	var _pf6 := FrameProfiler.t0()
	_sync_characters(frame_snapshot.get("workers", []))
	FrameProfiler.add("wv._sync_characters", _pf6)
	var _pf7 := FrameProfiler.t0()
	_sync_gates(frame_snapshot.get("roads", []))
	FrameProfiler.add("wv._sync_gates", _pf7)
	var _pf8 := FrameProfiler.t0()
	_sync_rival_roads(frame_snapshot.get("rival_roads", []))
	FrameProfiler.add("wv._sync_rival_roads", _pf8)
	var _pf9 := FrameProfiler.t0()
	_sync_rivalry_structures(frame_snapshot.get("rivalry_structures", []))
	FrameProfiler.add("wv._sync_rivalry_structures", _pf9)
	var _pf10 := FrameProfiler.t0()
	_sync_combatants(frame_snapshot.get("combatants", []))
	FrameProfiler.add("wv._sync_combatants", _pf10)
	var _pf11 := FrameProfiler.t0()
	_sync_projectiles(frame_snapshot.get("projectiles", []))
	FrameProfiler.add("wv._sync_projectiles", _pf11)
	var _pf12 := FrameProfiler.t0()
	_sync_decorative_props(frame_snapshot.get("decorative_props", []))
	FrameProfiler.add("wv._sync_decorative_props", _pf12)
	var _pf13 := FrameProfiler.t0()
	_sync_claim_overlays(frame_snapshot.get("lumen_sources", []), frame_snapshot.get("claims", {}))
	FrameProfiler.add("wv._sync_claim_overlays", _pf13)
	var _pf14 := FrameProfiler.t0()
	_update_shard_beacon(frame_snapshot.get("wyrdfall", {}))
	FrameProfiler.add("wv._update_shard_beacon", _pf14)
	var _pf15 := FrameProfiler.t0()
	_update_seal_ceremony(frame_snapshot.get("wyrdfall", {}))
	FrameProfiler.add("wv._update_seal_ceremony", _pf15)
	var _pf16 := FrameProfiler.t0()
	_update_channel_flash(frame_snapshot.get("wyrdfall", {}))
	FrameProfiler.add("wv._update_channel_flash", _pf16)
	var _pf17 := FrameProfiler.t0()
	_sync_wyrd_springs(frame_snapshot.get("wyrd_sites", []))
	FrameProfiler.add("wv._sync_wyrd_springs", _pf17)
	var _pf18 := FrameProfiler.t0()
	_sync_map_markers()
	FrameProfiler.add("wv._sync_map_markers", _pf18)
	if reveal_changed:
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
	var sim_y := float(simulation.get_height(tile)) * ScaleProfile.TERRAIN_ELEVATION_UNIT_METRES
	var flat := ScaleProfile.tile_to_flat_world(tile_position, map_size)
	return sim_y + _visual_relief_y(Vector2(flat.x, flat.z))


func focus_for_building(id: int) -> Vector3:
	if building_views.has(id):
		return (building_views[id] as ProductionBuildingView3D).camera_focus_position()
	return Vector3.ZERO


## R29: C&C group selection; every id in here shows the selection ring too.
var group_worker_ids: Array = []


func set_group_selection(ids: Array) -> void:
	group_worker_ids = ids.duplicate()
	set_selection(selected_building_id, selected_worker_id)


func set_selection(building_id: int, worker_id: int) -> void:
	selected_building_id = building_id
	selected_worker_id = worker_id
	for id_value in building_views:
		(building_views[id_value] as ProductionBuildingView3D).set_selected(int(id_value) == building_id)
	for id_value in character_views:
		(character_views[id_value] as ProductionCharacterView3D).set_selected(int(id_value) == worker_id or group_worker_ids.has(int(id_value)))
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
		"chunks_near": chunks_near,
		"chunks_far": chunks_far,
		"chunks_built": chunk_nodes.size(),
		"chunks_queued": chunk_queue.size(),
		"chunk_span": _chunk_span(),
		"stream_ms": last_stream_ms,
		"stream_hitches": last_stream_hitches,
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
	chunk_root = _named_root("TerrainChunks")
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


func _process(_delta: float) -> void:
	if _warmup_frames > 0:
		_warmup_frames -= 1
		if _warmup_frames == 0 and _warmup_root != null:
			_warmup_root.queue_free()
			_warmup_root = null
	var _pf19 := FrameProfiler.t0()
	_drain_rebake_queue()
	FrameProfiler.add("wv._drain_rebake_queue", _pf19)
	if stream_enabled and simulation != null and map_size.x > 0:
		stream_chunks(STREAM_BUDGET_USEC)


func note_camera(world_position: Vector3, zoom: float) -> void:
	camera_world = world_position
	camera_zoom = zoom
	_sync_fog_screen_camera()


func _init_chunk_streaming() -> void:
	chunk_nodes.clear()
	chunk_lod.clear()
	chunk_queue.clear()
	chunks_near = 0
	chunks_far = 0
	if chunk_root != null:
		for child in chunk_root.get_children():
			chunk_root.remove_child(child)
			child.free()


func _chunk_span() -> Vector2i:
	if CHUNK_TILES <= 0:
		return Vector2i.ONE
	return Vector2i(ceili(float(map_size.x) / float(CHUNK_TILES)), ceili(float(map_size.y) / float(CHUNK_TILES)))


func chunk_of_tile(tile: Vector2i) -> Vector2i:
	# Floor, not truncating toward zero. Negative tiles must not share
	# chunk (0,0) with the origin or -Z halls drop out of the stream.
	return Vector2i(
		int(floor(float(tile.x) / float(CHUNK_TILES))),
		int(floor(float(tile.y) / float(CHUNK_TILES)))
	)


func _chunk_key(coord: Vector2i) -> String:
	return "%d:%d" % [coord.x, coord.y]


func _chunk_from_key(key_value: String) -> Vector2i:
	var parts := key_value.split(":")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))


func _chunk_origin(coord: Vector2i) -> Vector2i:
	return Vector2i(coord.x * CHUNK_TILES, coord.y * CHUNK_TILES)


func _camera_chunk() -> Vector2i:
	if simulation == null:
		return Vector2i.ZERO
	var tile := world_to_tile(camera_world)
	if not simulation.is_inside_map(tile) and simulation.is_town_hall_founded():
		tile = simulation.town_hall_position
	return chunk_of_tile(tile)


func _hall_chunk() -> Vector2i:
	if simulation == null or not simulation.is_town_hall_founded():
		return _camera_chunk()
	return chunk_of_tile(simulation.town_hall_position)


func _stream_reach() -> int:
	return STREAM_FAR_CHUNKS + maxi(0, int(round((camera_zoom - 32.0) / 24.0)))


func _stream_opening_chunks() -> void:
	# The Director: the first frame must show the hall, not the water pad.
	# Always stream from the hall chunk so a -Z / west seat cannot miss
	# the start while the boom is still catching up.
	if simulation != null and simulation.is_town_hall_founded():
		camera_world = opening_camera_focus()
		camera_zoom = maxf(camera_zoom, 32.0)
	_refresh_terrain_lookups()
	_bake_road_control_texture()
	var hall := _hall_chunk()
	var focus := _camera_chunk()
	var built_open := 0
	for oy in range(-1, 2):
		for ox in range(-1, 2):
			var coord := hall + Vector2i(ox, oy)
			if not _chunk_has_tiles(coord):
				continue
			var lod := CHUNK_LOD_NEAR if ox == 0 and oy == 0 else CHUNK_LOD_FAR
			_rebuild_chunk(coord, lod, true)
			built_open += 1
	var reach := mini(_stream_reach(), STREAM_FAR_CHUNKS)
	for oy in range(-reach, reach + 1):
		for ox in range(-reach, reach + 1):
			var coord := focus + Vector2i(ox, oy)
			if built_open >= STREAM_OPENING_MAX:
				break
			if not _chunk_has_tiles(coord) or not _chunk_is_wanted(coord):
				continue
			if int(chunk_lod.get(_chunk_key(coord), CHUNK_LOD_NONE)) != CHUNK_LOD_NONE:
				continue
			_rebuild_chunk(coord, _desired_lod(coord), true)
			built_open += 1
		if built_open >= STREAM_OPENING_MAX:
			break
	_enqueue_desired_chunks()


func stream_chunks(budget_usec: int = STREAM_BUDGET_USEC) -> void:
	if simulation == null or map_size.x <= 0:
		return
	var t0 := Time.get_ticks_usec()
	_enqueue_desired_chunks()
	# Hotfix 7: a chunk load is a time-budgeted job (same builders as the
	# rebake job), shown when complete. Unloads stay immediate.
	if not _stream_job.is_empty():
		while Time.get_ticks_usec() - t0 < REBAKE_BUDGET_USEC:
			if _rebake_job_step(_stream_job, t0):
				_stream_job = {}
				break
		last_stream_ms = float(Time.get_ticks_usec() - t0) / 1000.0
		return
	var built := 0
	while not chunk_queue.is_empty():
		if built > 0 and Time.get_ticks_usec() - t0 >= budget_usec:
			break
		if built >= 1:
			break
		var coord: Vector2i = chunk_queue.pop_front()
		var wanted := _desired_lod(coord)
		var current := int(chunk_lod.get(_chunk_key(coord), CHUNK_LOD_NONE))
		if wanted == CHUNK_LOD_NONE:
			_unload_chunk(coord)
			continue
		if wanted != current:
			_stream_job = _rebake_job_new(_chunk_key(coord), wanted)
			_stream_job["collision"] = true
			_stream_job["stream"] = true
			if _rebake_job_step(_stream_job, t0):
				_stream_job = {}
			built += 1
	last_stream_ms = float(Time.get_ticks_usec() - t0) / 1000.0
	if last_stream_ms > 100.0:
		last_stream_hitches += 1


func _enqueue_desired_chunks() -> void:
	var seen: Dictionary = {}
	for existing in chunk_queue:
		seen[_chunk_key(existing)] = true
	var focus := _camera_chunk()
	var span := _chunk_span()
	var reach := _stream_reach()
	for oy in range(-reach, reach + 1):
		for ox in range(-reach, reach + 1):
			var coord := focus + Vector2i(ox, oy)
			if coord.x < 0 or coord.y < 0 or coord.x >= span.x or coord.y >= span.y:
				continue
			if not _chunk_is_wanted(coord):
				continue
			var key := _chunk_key(coord)
			var wanted := _desired_lod(coord)
			if int(chunk_lod.get(key, CHUNK_LOD_NONE)) == wanted:
				continue
			if seen.has(key):
				continue
			chunk_queue.append(coord)
			seen[key] = true
	_enqueue_revealed_chunks()


func _enqueue_revealed_chunks() -> void:
	if simulation == null:
		return
	var seen: Dictionary = {}
	for existing in chunk_queue:
		seen[_chunk_key(existing)] = true
	var focus := _camera_chunk()
	for key_value in simulation.revealed_tiles.keys():
		var tile: Vector2i = simulation._tile_from_key(String(key_value))
		var coord := chunk_of_tile(tile)
		if absi(coord.x - focus.x) > _stream_reach() + 1 or absi(coord.y - focus.y) > _stream_reach() + 1:
			continue
		var key := _chunk_key(coord)
		if int(chunk_lod.get(key, CHUNK_LOD_NONE)) != CHUNK_LOD_NONE:
			continue
		if seen.has(key):
			continue
		chunk_queue.append(coord)
		seen[key] = true


func _chunk_has_tiles(coord: Vector2i) -> bool:
	var origin := _chunk_origin(coord)
	return origin.x < map_size.x and origin.y < map_size.y and origin.x + CHUNK_TILES > 0 and origin.y + CHUNK_TILES > 0


func _chunk_is_wanted(coord: Vector2i) -> bool:
	return _desired_lod(coord) != CHUNK_LOD_NONE


func _desired_lod(coord: Vector2i) -> int:
	if simulation == null or not _chunk_has_tiles(coord):
		return CHUNK_LOD_NONE
	if not _chunk_explored_or_visible(coord):
		return CHUNK_LOD_NONE
	var hall := _hall_chunk()
	var hall_cheb := maxi(absi(coord.x - hall.x), absi(coord.y - hall.y))
	if hall_cheb <= STREAM_NEAR_CHUNKS:
		return CHUNK_LOD_NEAR
	var focus := _camera_chunk()
	var cheb := maxi(absi(coord.x - focus.x), absi(coord.y - focus.y))
	if cheb <= STREAM_NEAR_CHUNKS:
		return CHUNK_LOD_NEAR
	if cheb <= _stream_reach() or hall_cheb <= _stream_reach():
		return CHUNK_LOD_FAR
	return CHUNK_LOD_NONE


func _chunk_explored_or_visible(coord: Vector2i) -> bool:
	# Five corner samples miss a 5-tile crater corridor inside a 32
	# chunk. Step the chunk so any revealed sliver counts.
	if simulation != null and simulation.is_town_hall_founded():
		var hall_cheb := maxi(absi(coord.x - _hall_chunk().x), absi(coord.y - _hall_chunk().y))
		if hall_cheb <= 1:
			return true
	var origin := _chunk_origin(coord)
	for y in range(origin.y, origin.y + CHUNK_TILES, 4):
		for x in range(origin.x, origin.x + CHUNK_TILES, 4):
			var tile := Vector2i(x, y)
			if simulation.is_inside_map(tile) and simulation.is_revealed(tile):
				return true
	return false


func _rebuild_all_built_chunks() -> void:
	var keys: Array = chunk_nodes.keys()
	for key_value in keys:
		var coord := _chunk_from_key(String(key_value))
		var lod := int(chunk_lod.get(key_value, CHUNK_LOD_NEAR))
		_rebuild_chunk(coord, lod, true)


func _rebuild_chunk(coord: Vector2i, lod: int, rebuild_collision: bool) -> void:
	if chunk_root == null:
		return
	_unload_chunk(coord)
	if lod == CHUNK_LOD_NONE:
		return
	var host := Node3D.new()
	host.name = "Chunk_%d_%d" % [coord.x, coord.y]
	host.visible = true
	chunk_root.add_child(host)
	var _pc := FrameProfiler.t0()
	_build_chunk_terrain(host, coord, lod, rebuild_collision)
	FrameProfiler.add("chunk.terrain", _pc)
	_pc = FrameProfiler.t0()
	_build_chunk_water(host, coord, lod)
	FrameProfiler.add("chunk.water", _pc)
	_pc = FrameProfiler.t0()
	_build_chunk_nature(host, coord, lod)
	FrameProfiler.add("chunk.nature", _pc)
	_pc = FrameProfiler.t0()
	if lod == CHUNK_LOD_NEAR:
		_build_chunk_grass(host, coord)
	FrameProfiler.add("chunk.grass", _pc)
	_pc = FrameProfiler.t0()
	_build_chunk_rival_seat(host, coord, lod)
	FrameProfiler.add("chunk.rival", _pc)
	chunk_nodes[_chunk_key(coord)] = host
	chunk_lod[_chunk_key(coord)] = lod
	_recount_chunks()


func _unload_chunk(coord: Vector2i) -> void:
	var key := _chunk_key(coord)
	if chunk_nodes.has(key):
		var node: Node = chunk_nodes[key]
		if node != null and is_instance_valid(node):
			node.queue_free()
		chunk_nodes.erase(key)
	chunk_lod.erase(key)
	_recount_chunks()


func _recount_chunks() -> void:
	chunks_near = 0
	chunks_far = 0
	for key_value in chunk_lod.keys():
		var lod := int(chunk_lod[key_value])
		if lod == CHUNK_LOD_NEAR:
			chunks_near += 1
		elif lod == CHUNK_LOD_FAR:
			chunks_far += 1


func _build_chunk_terrain(host: Node3D, coord: Vector2i, lod: int, rebuild_collision: bool) -> void:
	# Heightfield, not 1024 voxel cells. The old per-tile path called
	# _compute_terrain_color 25× and relief 8× per cell — one chunk
	# hitch was 300–500 ms on lavapipe.
	var origin := _chunk_origin(coord)
	var verts := CHUNK_TILES + 1
	var heights := PackedFloat32Array()
	var colors := PackedColorArray()
	heights.resize(verts * verts)
	colors.resize(verts * verts)
	var half := ScaleProfile.LOGICAL_CELL_METRES * 0.5
	for j in verts:
		for i in verts:
			var tile := Vector2i(
				clampi(origin.x + i, 0, map_size.x - 1),
				clampi(origin.y + j, 0, map_size.y - 1)
			)
			var world := ScaleProfile.tile_to_flat_world(Vector2(tile), map_size)
			var sim_y := float(simulation.get_height(tile)) * ScaleProfile.TERRAIN_ELEVATION_UNIT_METRES
			heights[j * verts + i] = sim_y + _visual_relief_y(Vector2(world.x, world.z))
			colors[j * verts + i] = _fast_chunk_color(tile)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in CHUNK_TILES:
		for i in CHUNK_TILES:
			var tile := Vector2i(origin.x + i, origin.y + j)
			if not simulation.is_inside_map(tile):
				continue
			var c00 := ScaleProfile.tile_to_flat_world(Vector2(tile), map_size)
			var p00 := Vector3(c00.x - half, heights[j * verts + i], c00.z - half)
			var p10 := Vector3(c00.x + half, heights[j * verts + i + 1], c00.z - half)
			var p11 := Vector3(c00.x + half, heights[(j + 1) * verts + i + 1], c00.z + half)
			var p01 := Vector3(c00.x - half, heights[(j + 1) * verts + i], c00.z + half)
			_add_quad_colored(surface, p00, p10, p11, p01, Vector3.UP, colors[j * verts + i], colors[j * verts + i + 1], colors[(j + 1) * verts + i + 1], colors[(j + 1) * verts + i])
	var mesh := surface.commit()
	if mesh == null:
		return
	var instance := MeshInstance3D.new()
	instance.name = "Terrain"
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.mesh = mesh
	_apply_ground_material(instance)
	host.add_child(instance)
	if rebuild_collision and lod == CHUNK_LOD_NEAR:
		var body := StaticBody3D.new()
		body.name = "TerrainPicker"
		body.set_meta("selection_kind", "terrain")
		var collision := CollisionShape3D.new()
		var box := BoxShape3D.new()
		var cell := ScaleProfile.LOGICAL_CELL_METRES
		box.size = Vector3(cell * float(CHUNK_TILES), 4.0, cell * float(CHUNK_TILES))
		collision.shape = box
		var mid := _chunk_origin(coord) + Vector2i(CHUNK_TILES / 2, CHUNK_TILES / 2)
		body.position = tile_to_world(Vector2(mid))
		body.add_child(collision)
		host.add_child(body)


func _fast_chunk_color(tile: Vector2i) -> Color:
	if simulation.is_water_tile(tile):
		return Color(0.204, 0.369, 0.392, 0.55)
	if _is_road_tile(tile):
		return Color(0.682, 0.565, 0.427, 0.98)
	var tile_type := String(simulation.get_tile(tile))
	if tile_type == Defs.TILE_TREE:
		return Color(0.320, 0.360, 0.195, 0.30)
	if tile_type == Defs.TILE_ROCK:
		return Color(0.522, 0.514, 0.451, 0.32)
	if tile_type == Defs.TILE_SHARD:
		return Color(0.275, 0.349, 0.388, 0.40)
	return Color(0.408, 0.455, 0.227, 0.0)


func _build_chunk_water(host: Node3D, coord: Vector2i, lod: int) -> void:
	if simulation == null or not simulation.get("water_tiles"):
		return
	var waters: Dictionary = simulation.water_tiles
	if waters.is_empty():
		return
	var origin := _chunk_origin(coord)
	var points: Array[Vector3] = []
	var step := 1 if lod == CHUNK_LOD_NEAR else 2
	for y in range(origin.y, origin.y + CHUNK_TILES, step):
		for x in range(origin.x, origin.x + CHUNK_TILES, step):
			var tile := Vector2i(x, y)
			if not simulation.is_inside_map(tile):
				continue
			if not waters.has("%d,%d" % [tile.x, tile.y]):
				continue
			points.append(tile_to_world(Vector2(tile)))
	if points.is_empty():
		return
	var mesh := BoxMesh.new()
	mesh.size = Vector3(ScaleProfile.LOGICAL_CELL_METRES * float(step) * 0.92, 0.08, ScaleProfile.LOGICAL_CELL_METRES * float(step) * 0.92)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#345E64")
	mat.roughness = 0.18
	mat.metallic = 0.08
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = points.size()
	for i in points.size():
		var xf := Transform3D()
		xf.origin = Vector3(points[i].x, WATER_Y, points[i].z)
		batch.set_instance_transform(i, xf)
	var instance := MultiMeshInstance3D.new()
	instance.name = "ChunkWater"
	instance.multimesh = batch
	instance.material_override = mat
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	host.add_child(instance)


func _build_chunk_nature(host: Node3D, coord: Vector2i, lod: int) -> void:
	if simulation == null:
		return
	var origin := _chunk_origin(coord)
	var transforms_by_path: Dictionary = {}
	var step := 1 if lod == CHUNK_LOD_NEAR else 2
	for y in range(origin.y, origin.y + CHUNK_TILES, step):
		for x in range(origin.x, origin.x + CHUNK_TILES, step):
			var tile := Vector2i(x, y)
			if not simulation.is_inside_map(tile) or not simulation.is_revealed(tile):
				continue
			var tile_type := String(simulation.get_tile(tile))
			if tile_type == Defs.TILE_TREE:
				if _nature_suppressed_near_activity(tile):
					continue
				if _same_type_neighbors(tile, Defs.TILE_TREE) <= 1 and _near_founding_meadow(tile):
					continue
				if lod == CHUNK_LOD_FAR:
					_append_nature_transform(transforms_by_path, _tree_path_for_tile(tile, 0, 2), tile, 0, 0.45, 0.85, 0.12)
				else:
					var neighbors := _same_type_neighbors(tile, Defs.TILE_TREE)
					var path_value := _tree_path_for_tile(tile, 0, neighbors)
					var scales := _tree_scale_range(path_value, neighbors)
					_append_nature_transform(transforms_by_path, path_value, tile, 0, 0.55, float(scales.x), float(scales.y))
			elif tile_type == Defs.TILE_ROCK and lod == CHUNK_LOD_NEAR:
				if _nature_suppressed_near_activity(tile):
					continue
				var rock_path := String(Catalog.ROCKS[_tile_hash(tile, 101) % Catalog.ROCKS.size()]) if Catalog.ROCKS.size() > 0 else ""
				if rock_path != "":
					_append_nature_transform(transforms_by_path, rock_path, tile, 0, 0.66, 0.70, 0.18)
	_spawn_nature_multimeshes(host, transforms_by_path, true)


func _build_chunk_grass(host: Node3D, coord: Vector2i) -> void:
	if simulation == null or Catalog.GRASS.is_empty():
		return
	var origin := _chunk_origin(coord)
	var transforms_by_path: Dictionary = {}
	var occupied := _terrain_occupied_cache if _terrain_lookups_ready else _structure_tiles()
	for y in range(origin.y, origin.y + CHUNK_TILES):
		for x in range(origin.x, origin.x + CHUNK_TILES):
			var tile := Vector2i(x, y)
			if not simulation.is_inside_map(tile) or not simulation.is_revealed(tile):
				continue
			if String(simulation.get_tile(tile)) != Defs.TILE_GRASS:
				continue
			if occupied.has(_tile_key(tile)) or _is_road_tile(tile):
				continue
			if _in_founding_yard(tile):
				continue
			var forest_edge := _same_type_neighbors(tile, Defs.TILE_TREE)
			# Beta world pass: organic 3x3 clumps (tufts + flowers + a stone or
			# shrub) so the open meadow is not one bare colour field. Chunked
			# MultiMesh like the rest, built once per chunk.
			var clump_cell := Vector2i(int(floor(float(tile.x) / 3.0)), int(floor(float(tile.y) / 3.0)))
			var in_clump := _tile_hash(clump_cell, 17) % 3 == 0 and _tile_hash(tile, 23) % 4 != 0
			if in_clump:
				var clump_h := _tile_hash(tile, 31)
				_append_nature_transform(transforms_by_path, String(Catalog.GRASS[_tile_hash(tile, 83) % Catalog.GRASS.size()]), tile, 1, 0.95, 1.20, 0.60)
				if Catalog.FLOWERS.size() > 0 and clump_h % 3 == 0:
					_append_nature_transform(transforms_by_path, String(Catalog.FLOWERS[clump_h % Catalog.FLOWERS.size()]), tile, 2, 0.70, 1.10, 0.45)
				if Catalog.ROCKS.size() > 0 and clump_h % 4 == 0:
					_append_nature_transform(transforms_by_path, String(Catalog.ROCKS[clump_h % Catalog.ROCKS.size()]), tile, 3, 0.55, 0.42, 0.25)
				elif Catalog.UNDERSTORY.size() > 0 and clump_h % 5 == 0:
					_append_nature_transform(transforms_by_path, String(Catalog.UNDERSTORY[clump_h % Catalog.UNDERSTORY.size()]), tile, 4, 0.55, 0.62, 0.30)
				continue
			if forest_edge < 1 and _tile_hash(tile, 19) % 7 != 0:
				continue
			var grass_path := String(Catalog.GRASS[_tile_hash(tile, 83) % Catalog.GRASS.size()])
			_append_nature_transform(transforms_by_path, grass_path, tile, 0, 0.95, 1.32, 0.70)
	_spawn_nature_multimeshes(host, transforms_by_path, true)


func _build_chunk_rival_seat(host: Node3D, coord: Vector2i, lod: int) -> void:
	if simulation == null or not simulation.get("rival_seats"):
		return
	var origin := _chunk_origin(coord)
	var box := Rect2i(origin, Vector2i(CHUNK_TILES, CHUNK_TILES))
	for seat_value in simulation.rival_seats:
		var seat := Vector2i(seat_value)
		if not box.has_point(seat):
			continue
		var keep := MeshInstance3D.new()
		keep.name = "RivalSeat_%d_%d" % [seat.x, seat.y]
		var mesh := BoxMesh.new()
		# Beta: the rival seat was one 7 m saturated red box (read as a flat
		# red slab at the screen edge). Smaller stone keep + dark red roof.
		var keep_h := 3.0 if lod == CHUNK_LOD_NEAR else 2.4
		mesh.size = Vector3(4.6, keep_h, 4.6)
		keep.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("#5B504A") * _atmosphere_scale
		mat.roughness = 0.9
		keep.material_override = mat
		keep.position = tile_to_world(Vector2(seat) + Vector2(1.5, 1.5)) + Vector3(0.0, keep_h * 0.5, 0.0)
		host.add_child(keep)
		var roof := MeshInstance3D.new()
		roof.name = "RivalSeatRoof"
		var roof_mesh := PrismMesh.new()
		roof_mesh.size = Vector3(5.2, 1.8, 5.2)
		roof.mesh = roof_mesh
		var roof_mat := StandardMaterial3D.new()
		roof_mat.albedo_color = Color("#5E2A30") * _atmosphere_scale
		roof_mat.roughness = 0.88
		roof.material_override = roof_mat
		roof.position = keep.position + Vector3(0.0, keep_h * 0.5 + 0.9, 0.0)
		host.add_child(roof)


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
		for building_value in simulation.buildings:
			var building: Dictionary = building_value
			if String(building.get("type", "")) == Defs.BUILDING_ROAD:
				_terrain_road_cache[_tile_key(Vector2i(building.get("position", Vector2i.ZERO)))] = true
	_terrain_lookups_ready = true
	_terrain_farm_cache = _farm_field_tiles()


func _precompute_terrain_colors() -> void:
	# Full-map colour bake is only cheap on the old 70×70 slab. The 320
	# province computes colours per streamed chunk instead.
	if map_size.x * map_size.y > 90 * 90:
		_terrain_color_grid = PackedColorArray()
		return
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
	if map_size.x <= 80:
		_commit_terrain_mesh(true)
	else:
		_rebuild_all_built_chunks()
	_rebuild_beach_apron()
	terrain_height_signature = _calculate_height_signature()
	terrain_occupation_signature = _calculate_occupation_signature()


func _rebake_terrain_occupation() -> void:
	# Heights unchanged: recolor the slab, keep the picker collision.
	# Showcase stamps 15 buildings + roads; a full remesh+concave rebuild
	# after each occupation signature used to stall the first frame.
	_refresh_terrain_lookups()
	_precompute_terrain_colors()
	_bake_road_control_texture()
	if map_size.x <= 80:
		_commit_terrain_mesh(false)
	else:
		_rebake_occupied_chunks()
	terrain_occupation_signature = _calculate_occupation_signature()


var _chunk_occupation_hashes: Dictionary = {}


## Hotfix 3b: per-chunk occupation hash, so a new road tile or a construction
## state change rebakes only the chunks it touches (not all ~13 at ~260 ms).
func _calculate_chunk_occupation_hashes() -> Dictionary:
	var hashes := {}
	if simulation == null:
		return hashes
	var margin := 4
	var items: Array = []
	if simulation.connected_roads != null:
		for key_value in simulation.connected_roads.keys():
			var parts := String(key_value).split(",")
			if parts.size() == 2:
				items.append([Vector2i(int(parts[0]), int(parts[1])), Vector2i.ONE, String(key_value).hash()])
	for building_value in simulation.buildings:
		var building: Dictionary = building_value
		var tile: Vector2i = building.get("position", Vector2i.ZERO)
		var fp: Vector2i = simulation._building_footprint(building)
		items.append([tile, fp, int(building.get("id", 0)) * 11 + tile.x * 13 + tile.y * 17 + int(bool(building.get("construction", false))) * 7 + 3])
	for item in items:
		var lo := chunk_of_tile(Vector2i(item[0]) - Vector2i(margin, margin))
		var hi := chunk_of_tile(Vector2i(item[0]) + Vector2i(item[1]) + Vector2i(margin, margin))
		for cy in range(lo.y, hi.y + 1):
			for cx in range(lo.x, hi.x + 1):
				var key := _chunk_key(Vector2i(cx, cy))
				hashes[key] = int((int(hashes.get(key, 19)) * 31 + int(item[2])) & 0x7fffffff)
	return hashes


func _rebake_occupied_chunks() -> void:
	var next := _calculate_chunk_occupation_hashes()
	var full := _chunk_occupation_hashes.is_empty()
	var keys: Array = chunk_nodes.keys()
	for key_value in keys:
		var lod := int(chunk_lod.get(key_value, CHUNK_LOD_NONE))
		if lod == CHUNK_LOD_NONE:
			continue
		if not full and int(next.get(key_value, 19)) == int(_chunk_occupation_hashes.get(key_value, 19)):
			continue
		if not _rebake_queue.has(String(key_value)):
			_rebake_queue.append(String(key_value))
	_chunk_occupation_hashes = next


## Hotfix 5: dirty chunks rebake one per frame (~20 ms each) instead of all
## in the frame that changed (60–260 ms hitch).
var _rebake_queue: Array[String] = []


## Hotfix 6: a dirty chunk is rebuilt as a time-budgeted job (rows per
## frame, ~2.5 ms) into a detached host, then swapped in one frame. Visual
## only: the sim already committed; same builders' maths, same result.
const REBAKE_BUDGET_USEC := 2500
var _rebake_job: Dictionary = {}
var _stream_job: Dictionary = {}


func _drain_rebake_queue() -> void:
	var started := Time.get_ticks_usec()
	while Time.get_ticks_usec() - started < REBAKE_BUDGET_USEC:
		if _rebake_job.is_empty():
			if _rebake_queue.is_empty():
				return
			var key: String = _rebake_queue.pop_front()
			var lod := int(chunk_lod.get(key, CHUNK_LOD_NONE))
			if lod == CHUNK_LOD_NONE or chunk_root == null or simulation == null:
				continue
			_rebake_job = _rebake_job_new(key, lod)
		if _rebake_job_step(_rebake_job, started):
			_rebake_job = {}


func _rebake_job_new(key: String, lod: int) -> Dictionary:
	var verts := CHUNK_TILES + 1
	var heights := PackedFloat32Array()
	var colors := PackedColorArray()
	heights.resize(verts * verts)
	colors.resize(verts * verts)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	return {
		"key": key, "coord": _chunk_from_key(key), "lod": lod,
		"old": chunk_nodes.get(key, null), "stage": 0, "row": 0,
		"heights": heights, "colors": colors, "surface": surface,
		"mesh": null, "nature": {}, "grass": {}, "collision": false, "stream": false,
	}


func _rebake_job_step(job: Dictionary, started: int) -> bool:
	var coord: Vector2i = job["coord"]
	var lod: int = job["lod"]
	var origin := _chunk_origin(coord)
	var verts := CHUNK_TILES + 1
	var stage: int = job["stage"]
	if stage == 0:
		var heights: PackedFloat32Array = job["heights"]
		var colors: PackedColorArray = job["colors"]
		var j: int = job["row"]
		while j < verts:
			for i in verts:
				var tile := Vector2i(
					clampi(origin.x + i, 0, map_size.x - 1),
					clampi(origin.y + j, 0, map_size.y - 1)
				)
				var world := ScaleProfile.tile_to_flat_world(Vector2(tile), map_size)
				var sim_y := float(simulation.get_height(tile)) * ScaleProfile.TERRAIN_ELEVATION_UNIT_METRES
				heights[j * verts + i] = sim_y + _visual_relief_y(Vector2(world.x, world.z))
				colors[j * verts + i] = _fast_chunk_color(tile)
			j += 1
			if Time.get_ticks_usec() - started >= REBAKE_BUDGET_USEC:
				break
		job["heights"] = heights
		job["colors"] = colors
		job["row"] = j
		if j >= verts:
			job["stage"] = 1
			job["row"] = 0
	elif stage == 1:
		var heights: PackedFloat32Array = job["heights"]
		var colors: PackedColorArray = job["colors"]
		var surface: SurfaceTool = job["surface"]
		var half := ScaleProfile.LOGICAL_CELL_METRES * 0.5
		var j: int = job["row"]
		while j < CHUNK_TILES:
			for i in CHUNK_TILES:
				var tile := Vector2i(origin.x + i, origin.y + j)
				if not simulation.is_inside_map(tile):
					continue
				var c00 := ScaleProfile.tile_to_flat_world(Vector2(tile), map_size)
				var p00 := Vector3(c00.x - half, heights[j * verts + i], c00.z - half)
				var p10 := Vector3(c00.x + half, heights[j * verts + i + 1], c00.z - half)
				var p11 := Vector3(c00.x + half, heights[(j + 1) * verts + i + 1], c00.z + half)
				var p01 := Vector3(c00.x - half, heights[(j + 1) * verts + i], c00.z + half)
				_add_quad_colored(surface, p00, p10, p11, p01, Vector3.UP, colors[j * verts + i], colors[j * verts + i + 1], colors[(j + 1) * verts + i + 1], colors[(j + 1) * verts + i])
			j += 1
			if Time.get_ticks_usec() - started >= REBAKE_BUDGET_USEC:
				break
		job["row"] = j
		if j >= CHUNK_TILES:
			job["mesh"] = surface.commit()
			job["stage"] = 2
			job["row"] = origin.y
	elif stage == 2:
		var step := 1 if lod == CHUNK_LOD_NEAR else 2
		var y: int = job["row"]
		while y < origin.y + CHUNK_TILES:
			_rebake_nature_row(job["nature"], origin, y, step, lod)
			y += step
			if Time.get_ticks_usec() - started >= REBAKE_BUDGET_USEC:
				break
		job["row"] = y
		if y >= origin.y + CHUNK_TILES:
			job["stage"] = 3 if lod == CHUNK_LOD_NEAR and not Catalog.GRASS.is_empty() else 4
			job["row"] = origin.y
	elif stage == 3:
		var occupied := _terrain_occupied_cache if _terrain_lookups_ready else _structure_tiles()
		var y: int = job["row"]
		while y < origin.y + CHUNK_TILES:
			_rebake_grass_row(job["grass"], origin, y, occupied)
			y += 1
			if Time.get_ticks_usec() - started >= REBAKE_BUDGET_USEC:
				break
		job["row"] = y
		if y >= origin.y + CHUNK_TILES:
			job["stage"] = 4
	else:
		var _pfj := FrameProfiler.t0()
		_rebake_job_finish(job)
		FrameProfiler.add("rebake.finish", _pfj)
		return true
	return false


func _rebake_nature_row(transforms_by_path: Dictionary, origin: Vector2i, y: int, step: int, lod: int) -> void:
	# Same body as _build_chunk_nature, one row.
	for x in range(origin.x, origin.x + CHUNK_TILES, step):
		var tile := Vector2i(x, y)
		if not simulation.is_inside_map(tile) or not simulation.is_revealed(tile):
			continue
		var tile_type := String(simulation.get_tile(tile))
		if tile_type == Defs.TILE_TREE:
			if _nature_suppressed_near_activity(tile):
				continue
			if _same_type_neighbors(tile, Defs.TILE_TREE) <= 1 and _near_founding_meadow(tile):
				continue
			if lod == CHUNK_LOD_FAR:
				_append_nature_transform(transforms_by_path, _tree_path_for_tile(tile, 0, 2), tile, 0, 0.45, 0.85, 0.12)
			else:
				var neighbors := _same_type_neighbors(tile, Defs.TILE_TREE)
				var path_value := _tree_path_for_tile(tile, 0, neighbors)
				var scales := _tree_scale_range(path_value, neighbors)
				_append_nature_transform(transforms_by_path, path_value, tile, 0, 0.55, float(scales.x), float(scales.y))
		elif tile_type == Defs.TILE_ROCK and lod == CHUNK_LOD_NEAR:
			if _nature_suppressed_near_activity(tile):
				continue
			var rock_path := String(Catalog.ROCKS[_tile_hash(tile, 101) % Catalog.ROCKS.size()]) if Catalog.ROCKS.size() > 0 else ""
			if rock_path != "":
				_append_nature_transform(transforms_by_path, rock_path, tile, 0, 0.66, 0.70, 0.18)


func _rebake_grass_row(transforms_by_path: Dictionary, origin: Vector2i, y: int, occupied: Dictionary) -> void:
	# Same body as _build_chunk_grass, one row.
	for x in range(origin.x, origin.x + CHUNK_TILES):
		var tile := Vector2i(x, y)
		if not simulation.is_inside_map(tile) or not simulation.is_revealed(tile):
			continue
		if String(simulation.get_tile(tile)) != Defs.TILE_GRASS:
			continue
		if occupied.has(_tile_key(tile)) or _is_road_tile(tile):
			continue
		if _in_founding_yard(tile):
			continue
		var forest_edge := _same_type_neighbors(tile, Defs.TILE_TREE)
		if forest_edge < 1 and _tile_hash(tile, 19) % 7 != 0:
			continue
		var grass_path := String(Catalog.GRASS[_tile_hash(tile, 83) % Catalog.GRASS.size()])
		_append_nature_transform(transforms_by_path, grass_path, tile, 0, 0.95, 1.32, 0.70)


func _rebake_job_finish(job: Dictionary) -> void:
	var key: String = job["key"]
	var coord: Vector2i = job["coord"]
	var lod: int = job["lod"]
	# Streaming rebuilt or unloaded the chunk meanwhile: drop the job.
	if chunk_nodes.get(key, null) != job["old"]:
		if not bool(job["stream"]) and not _rebake_queue.has(key):
			_rebake_queue.append(key)
		return
	if bool(job["stream"]):
		if _desired_lod(coord) != lod:
			return
	elif int(chunk_lod.get(key, CHUNK_LOD_NONE)) != lod:
		return
	_unload_chunk(coord)
	var host := Node3D.new()
	host.name = "Chunk_%d_%d" % [coord.x, coord.y]
	host.visible = true
	chunk_root.add_child(host)
	var mesh: Mesh = job["mesh"]
	if mesh != null:
		var instance := MeshInstance3D.new()
		instance.name = "Terrain"
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instance.mesh = mesh
		_apply_ground_material(instance)
		host.add_child(instance)
	if bool(job["collision"]) and lod == CHUNK_LOD_NEAR:
		var body := StaticBody3D.new()
		body.name = "TerrainPicker"
		body.set_meta("selection_kind", "terrain")
		var collision := CollisionShape3D.new()
		var box := BoxShape3D.new()
		var cell := ScaleProfile.LOGICAL_CELL_METRES
		box.size = Vector3(cell * float(CHUNK_TILES), 4.0, cell * float(CHUNK_TILES))
		collision.shape = box
		var mid := _chunk_origin(coord) + Vector2i(CHUNK_TILES / 2, CHUNK_TILES / 2)
		body.position = tile_to_world(Vector2(mid))
		body.add_child(collision)
		host.add_child(body)
	_build_chunk_water(host, coord, lod)
	_spawn_nature_multimeshes(host, job["nature"], true)
	if lod == CHUNK_LOD_NEAR and not Catalog.GRASS.is_empty() and simulation != null:
		_spawn_nature_multimeshes(host, job["grass"], true)
	_build_chunk_rival_seat(host, coord, lod)
	chunk_nodes[key] = host
	chunk_lod[key] = lod
	_recount_chunks()


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
	material.set_shader_parameter("macro_amount", 0.20)
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
	material.set_shader_parameter("tex_mix", 0.24)
	material.set_shader_parameter("tex_repeat_meadow", 1.5 * ScaleProfile.road_width_metres())
	material.set_shader_parameter("tex_repeat_forest", 1.2 * ScaleProfile.road_width_metres())
	if road_control_texture != null:
		material.set_shader_parameter("road_control_tex", road_control_texture)
	material.set_shader_parameter("road_control_amount", 1.0)
	material.set_shader_parameter("road_debug", 1.0 if road_debug_enabled else 0.0)
	material.set_shader_parameter("terrain_debug", float(terrain_debug_mode))


func _apply_meadow_palette(material: ShaderMaterial) -> void:
	# GFX-P meadow richness on the O occupy / distance-field baseline.
	# GFX-S: cooler sunlit / warm grass so the meadow is not one
	# yellow-olive wash. Identity lush #536C3F and shade stay.
	material.set_shader_parameter("grass_sunlit", Vector3(0.392, 0.518, 0.345))
	material.set_shader_parameter("grass_moss", Vector3(0.204, 0.294, 0.200))
	material.set_shader_parameter("meadow_lush", Vector3(0.325, 0.424, 0.247))
	material.set_shader_parameter("meadow_warm", Vector3(0.400, 0.502, 0.349))
	material.set_shader_parameter("meadow_shade", Vector3(0.251, 0.353, 0.212))
	material.set_shader_parameter("forest_floor", Vector3(0.204, 0.294, 0.200))
	material.set_shader_parameter("dirt_color", Vector3(0.557, 0.412, 0.282))
	material.set_shader_parameter("road_earth", Vector3(0.624, 0.502, 0.357))
	material.set_shader_parameter("road_compacted", Vector3(0.506, 0.388, 0.267))
	material.set_shader_parameter("road_shoulder", Vector3(0.435, 0.408, 0.322))
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
		var visual_w := ScaleProfile.road_width_metres() * 0.72
		var spoke_w := ScaleProfile.road_width_metres() * 0.30
		var segments: Array[Vector2] = _collect_road_segments()
		var i := 0
		while i + 1 < segments.size():
			var wobble := 0.70 + float((i * 13) % 9) * 0.045
			_stamp_segment_distance(img, segments[i], segments[i + 1], min_xz, size_xz, visual_w * wobble)
			i += 2
		var spokes: Array[Vector2] = _collect_hamlet_spokes()
		i = 0
		while i + 1 < spokes.size():
			_stamp_segment_distance(img, spokes[i], spokes[i + 1], min_xz, size_xz, spoke_w)
			i += 2
		_stamp_road_junctions(img, min_xz, size_xz, visual_w)
		_stamp_building_aprons(img, min_xz, size_xz, visual_w)
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
	var tiles: Array[Vector2i] = []
	if simulation != null and simulation.connected_roads != null:
		for key_value in simulation.connected_roads.keys():
			tiles.append(simulation._tile_from_key(String(key_value)))
	if tiles.is_empty() and map_size.x <= 80:
		for y in range(map_size.y):
			for x in range(map_size.x):
				tiles.append(Vector2i(x, y))
	for tile in tiles:
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
	var inner := visual_w * 0.26
	var outer := visual_w * 0.50
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


func _stamp_road_junctions(img: Image, min_xz: Vector2, size_xz: Vector2, visual_w: float) -> void:
	# Circular worn pads replace square plus-junctions.
	if simulation == null:
		return
	var tiles: Array[Vector2i] = []
	if simulation.connected_roads != null:
		for key_value in simulation.connected_roads.keys():
			tiles.append(simulation._tile_from_key(String(key_value)))
	for tile in tiles:
		if not _is_road_tile(tile):
			continue
		var n := 0
		for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if _is_road_tile(tile + dir):
				n += 1
		if n < 2:
			continue
		var world := tile_to_world(Vector2(tile))
		var px := _world_to_control_px(Vector2(world.x, world.z), min_xz, size_xz)
		var radius := visual_w * (0.32 + float(n) * 0.06 + float((tile.x * 7 + tile.y * 11) % 5) * 0.04)
		_stamp_soft_disk(img, px.x, px.y, radius, min_xz, size_xz)


func _stamp_building_aprons(img: Image, min_xz: Vector2, size_xz: Vector2, visual_w: float) -> void:
	# Irregular worn earth around buildings so footprints are not boxes.
	if simulation == null:
		return
	for building_value in simulation.buildings:
		var building: Dictionary = building_value
		if String(building.get("type", "")) == Defs.BUILDING_ROAD:
			continue
		var tile: Vector2i = building.get("tile", Vector2i.ZERO)
		var world := tile_to_world(Vector2(tile) + Vector2(0.8, 0.8))
		var px := _world_to_control_px(Vector2(world.x, world.z), min_xz, size_xz)
		var radius := visual_w * (0.62 + float(absi(tile.x * 3 + tile.y * 5) % 6) * 0.07)
		_stamp_soft_disk(img, px.x, px.y, radius, min_xz, size_xz)
		var jx := px.x + int((tile.x % 3) - 1) * 4
		var jy := px.y + int((tile.y % 3) - 1) * 4
		_stamp_soft_disk(img, jx, jy, radius * 0.42, min_xz, size_xz)


func _stamp_soft_disk(img: Image, cx: int, cy: int, radius_m: float, min_xz: Vector2, size_xz: Vector2) -> void:
	var res := ROAD_CONTROL_RES
	var px_per_m := float(res) / maxf(size_xz.x, 1.0)
	var radius_px := maxi(2, int(ceil(radius_m * px_per_m)))
	for y in range(cy - radius_px, cy + radius_px + 1):
		if y < 0 or y >= res:
			continue
		for x in range(cx - radius_px, cx + radius_px + 1):
			if x < 0 or x >= res:
				continue
			var world := _control_px_to_world(x, y, min_xz, size_xz)
			var d := Vector2(world.x - _control_px_to_world(cx, cy, min_xz, size_xz).x, world.y - _control_px_to_world(cx, cy, min_xz, size_xz).y).length()
			var n := (sin(world.x * 1.3 + world.y * 0.9) * 0.12)
			var mask := 1.0 - smoothstep(radius_m * 0.45, radius_m * (0.92 + n), d)
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
	var sim_y := float(simulation.get_height(tile)) * ScaleProfile.TERRAIN_ELEVATION_UNIT_METRES
	var corners := [
		Vector3(center.x - half, sim_y + _visual_relief_y(Vector2(center.x - half, center.z - half)), center.z - half),
		Vector3(center.x + half, sim_y + _visual_relief_y(Vector2(center.x + half, center.z - half)), center.z - half),
		Vector3(center.x + half, sim_y + _visual_relief_y(Vector2(center.x + half, center.z + half)), center.z + half),
		Vector3(center.x - half, sim_y + _visual_relief_y(Vector2(center.x - half, center.z + half)), center.z + half),
	]
	var top_y: float = (corners[0].y + corners[1].y + corners[2].y + corners[3].y) * 0.25
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
		var neighbor_sim := float(simulation.get_height(neighbor)) * ScaleProfile.TERRAIN_ELEVATION_UNIT_METRES
		if neighbor_sim >= sim_y - 0.001:
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
		var down_a := Vector3(a.x, neighbor_sim + _visual_relief_y(Vector2(a.x, a.z)), a.z)
		var down_b := Vector3(b.x, neighbor_sim + _visual_relief_y(Vector2(b.x, b.z)), b.z)
		var normal := Vector3(float(directions[direction_index].x), 0.0, float(directions[direction_index].y))
		_add_quad(surface, a, b, down_b, down_a, normal, color.darkened(0.24))


func _visual_relief_y(xz: Vector2) -> float:
	# Presentation only. Village stays flat. The pit sinks around the
	# Shard; displaced earth rises at the excavation rim.
	if simulation == null or map_size == Vector2i.ZERO:
		return 0.0
	var b := ScaleProfile.TOWN_HALL_WIDTH_METRES
	var hall := Vector2i.ZERO
	if simulation.is_town_hall_founded():
		hall = simulation.town_hall_position + Vector2i(2, 2)
	var hall_world := ScaleProfile.tile_to_flat_world(Vector2(hall), map_size)
	var dx := xz.x - hall_world.x
	var dz := xz.y - hall_world.z
	var dist := Vector2(dx, dz).length()
	var village := 1.0 - smoothstep(6.5, 12.0, dist)
	var shard_world := ScaleProfile.tile_to_flat_world(Vector2(simulation.shard_position), map_size)
	var from_shard := Vector2(xz.x - shard_world.x, xz.y - shard_world.z).length()
	var pit_m := maxf(float(simulation.crater_pit_radius) * ScaleProfile.LOGICAL_CELL_METRES, 14.0)
	var pit := 0.0
	if from_shard < pit_m:
		pit = -0.42 * (1.0 - from_shard / pit_m)
	elif from_shard < pit_m + 7.0:
		var rim_t := 1.0 - absf(from_shard - pit_m) / 7.0
		pit = 0.16 * b * rim_t * (0.85 + 0.15 * sin(xz.x * 0.21 + xz.y * 0.17))
	var crater_dir := Vector2(0.0, -1.0)
	if simulation.founding_site is Dictionary:
		crater_dir = Vector2(simulation.founding_site.get("crater_dir", crater_dir))
	if crater_dir.length_squared() < 0.01:
		crater_dir = Vector2(0.0, -1.0)
	var toward := Vector2(dx, dz).dot(crater_dir.normalized())
	var back := smoothstep(2.0, 16.0, toward)
	var ridge_h := lerpf(0.08 * b, 0.18 * b, clampf((toward - 4.0) / 18.0, 0.0, 1.0))
	var noise := 0.82 + 0.18 * sin(xz.x * 0.11 + xz.y * 0.07)
	var ridge := back * ridge_h * noise * (1.0 - village)
	var peri := smoothstep(22.0, 48.0, dist) * 0.07 * b * (1.0 - village)
	return ridge + peri + pit * (1.0 - village) + _creek_cut_at(xz) + _road_dip_at(xz)


func _creek_cut_at(xz: Vector2) -> float:
	if simulation == null or not simulation.is_town_hall_founded():
		return 0.0
	var best := 999.0
	var tiles: Array = simulation.founding_site.get("creek_tiles", []) if simulation.founding_site is Dictionary else []
	if tiles.is_empty():
		var hall: Vector2i = simulation.town_hall_position
		tiles = [hall + Vector2i(-7, -2), hall + Vector2i(-6, 2), hall + Vector2i(-6, 6), hall + Vector2i(-7, 10)]
	for tile_value in tiles:
		var p := ScaleProfile.tile_to_flat_world(Vector2(Vector2i(tile_value)), map_size)
		best = minf(best, Vector2(xz.x - p.x, xz.y - p.z).length())
	var bank := ScaleProfile.road_width_metres() * 0.85
	if best > bank + 1.6:
		return 0.0
	return -0.12 * (1.0 - smoothstep(0.35, bank + 1.2, best))


func _road_dip_at(xz: Vector2) -> float:
	var tile := world_to_tile(Vector3(xz.x, 0.0, xz.y))
	if _is_road_tile(tile):
		return -0.045
	if _is_road_shoulder(tile):
		return -0.022
	return 0.0


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
		# Beta world pass: forest floor was a 78 % blend to near-black green,
		# which printed as a flat dark mass wherever trees were thinned
		# (LOD, near buildings, fog edge). Moss/needle tone, lighter blend,
		# per-tile variation so the edge breaks up.
		var moss := Color(0.300, 0.350, 0.190, 0.30).lerp(Color(0.380, 0.330, 0.200, 0.30), float(_tile_hash(tile, 61) % 100) / 100.0)
		base = base.lerp(moss, litter * 0.50)
	var scree := clampf(float(rock_weight) / 16.0, 0.0, 0.55)
	if scree > 0.12:
		base = base.lerp(Color(0.522, 0.514, 0.451, 0.32), scree * 0.50)
	var edge := mini(mini(tile.x, tile.y), mini(map_size.x - 1 - tile.x, map_size.y - 1 - tile.y))
	if edge <= 1:
		base = base.lerp(Color(0.090, 0.149, 0.165, 0.28) if rock_weight < 3 else Color(0.416, 0.376, 0.329, 0.24), 0.55)
	var path_w := maxf(_visual_path_weight(tile), _hamlet_path_weight(tile))
	path_w = maxf(path_w, _forecourt_weight(tile))
	if path_w > 0.08:
		base = base.lerp(Color(0.690, 0.520, 0.330, 0.88), clampf(path_w * 0.94, 0.0, 0.94))
	if _is_farm_field_tile(tile):
		base = Color(0.788, 0.635, 0.290, 0.94)
	if _is_road_tile(tile):
		# Beta: packed earth that keeps a trace of the ground under it and
		# varies per tile, so roads read worn-in instead of pasted beige strips.
		var wear := float(_tile_hash(tile, 57) % 9) / 100.0
		base = base.lerp(Color(0.640 - wear, 0.525 - wear, 0.395 - wear * 0.6, 0.96), 0.86)
	elif _is_road_shoulder(tile):
		var shoulder := 0.30 + float(_tile_hash(tile, 41) % 16) / 100.0
		base = base.lerp(Color(0.540, 0.430, 0.290, 0.60), clampf(shoulder, 0.30, 0.45))
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


func _forecourt_weight(tile: Vector2i) -> float:
	if simulation == null or not simulation.is_town_hall_founded():
		return 0.0
	var entrance: Vector2i = simulation._town_hall_entrance_tile()
	var d := Vector2(tile).distance_to(Vector2(entrance) + Vector2(0.0, 0.8))
	return clampf(1.0 - d / 3.45, 0.0, 1.0) * 0.98


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
	for building_value in simulation.buildings:
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
	for building_value in simulation.buildings:
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
	# Heights are authored at generate-time. A full 320² scan every frame
	# is the first-frame hitch. Hash seed + size + hall instead.
	var value := 17 + visual_seed * 31 + map_size.x * 13 + map_size.y * 17
	if simulation != null and simulation.is_town_hall_founded():
		var hall: Vector2i = simulation.town_hall_position
		value = int((value + hall.x * 7 + hall.y * 11 + int(simulation.crater_pit_radius * 10.0)) & 0x7fffffff)
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
	for building_value in simulation.buildings:
		var building: Dictionary = building_value
		var tile: Vector2i = building.get("position", Vector2i.ZERO)
		value = int((value * 31 + int(building.get("id", 0)) * 11 + tile.x * 13 + tile.y * 17 + int(bool(building.get("construction", false)))) & 0x7fffffff)
	return value


func _sync_nature(force: bool) -> void:
	if map_size.x > 80:
		if force:
			_rebuild_all_built_chunks()
		return
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
	for building_value in simulation.buildings:
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
			# Isolated meadow trees read as saplings beside the hall.
			if neighbors <= 1 and _near_founding_meadow(tile):
				continue
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
			tree_floors.append(ContactAO.flatten_transform(batch[index], 1.05))
	ContactAO.spawn_multimesh(resource_visuals_root, tree_floors, 0.18)


func _sync_grass(force: bool) -> void:
	if simulation == null or grass_root == null:
		return
	if map_size.x > 80:
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
			if _in_founding_yard(tile) or _forecourt_weight(tile) > 0.12:
				continue
			if density < 0.55 and _tile_hash(tile, 11) % 3 == 0:
				continue
			var meadow := _meadow_weight(tile)
			var forest_edge := _same_type_neighbors(tile, Defs.TILE_TREE)
			var near_yard := yard.has(_tile_key(tile))
			var path_w := _visual_path_weight(tile)
			if path_w > 0.45:
				continue
			if _near_founding_meadow(tile) and forest_edge == 0:
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
			if meadow > 0.20 and forest_edge == 0 and near_yard and _tile_hash(tile, 59) % 6 == 0 and Catalog.UNDERSTORY.size() > 0 and not _in_founding_yard(tile, 8.5) and not _near_founding_meadow(tile):
				var meadow_bush := String(Catalog.UNDERSTORY[_tile_hash(tile, 73) % Catalog.UNDERSTORY.size()])
				_append_nature_transform(transforms_by_path, meadow_bush, tile, 8, 0.55, 0.96, 0.30)
			if forest_edge >= 1 and forest_edge <= 3 and _tile_hash(tile, 53) % 2 == 0 and Catalog.UNDERSTORY.size() > 0 and not _in_founding_yard(tile, 8.5):
				var bush_path := String(Catalog.UNDERSTORY[_tile_hash(tile, 71) % Catalog.UNDERSTORY.size()])
				_append_nature_transform(transforms_by_path, bush_path, tile, 6, 0.50, 0.55, 0.30)
			if forest_edge >= 1 and _tile_hash(tile, 101) % 4 == 0 and Catalog.ROCKS.size() > 0 and not _in_founding_yard(tile, 8.5):
				var rock_path := String(Catalog.ROCKS[_tile_hash(tile, 109) % Catalog.ROCKS.size()])
				_append_nature_transform(transforms_by_path, rock_path, tile, 7, 0.58, 0.50, 0.20)
	_spawn_nature_multimeshes(grass_root, transforms_by_path)
	for child in grass_root.get_children():
		if child is GeometryInstance3D:
			(child as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rebuild_ground_patches()


func _structure_tiles() -> Dictionary:
	var occupied: Dictionary = {}
	for building_value in simulation.buildings:
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
	for building_value in simulation.buildings:
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


func _spawn_nature_multimeshes(host: Node3D, transforms_by_path: Dictionary, share_materials: bool = false) -> void:
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
		var foliage := _shared_foliage_material(mesh, String(path_value)) if share_materials else _foliage_material(mesh, path_value)
		if foliage != null:
			instance.material_override = foliage
		host.add_child(instance)


func _rebuild_ground_patches() -> void:
	# GFX-S: 3×3 clump seeds so tufts / flowers / stones read as
	# patches at 720p instead of an even lawn grid. Zones stay
	# settlement / meadow / forest. MultiMesh only.
	if ground_patch_root == null or simulation == null:
		return
	if map_size.x > 80:
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
			if _in_founding_yard(tile) or _forecourt_weight(tile) > 0.12:
				continue
			if _visual_path_weight(tile) > 0.40 or _hamlet_path_weight(tile) > 0.40:
				continue
			var world := tile_to_world(Vector2(tile))
			var chunk := Vector2i(int(floor(world.x / GROUND_PATCH_CHUNK_METRES)), int(floor(world.z / GROUND_PATCH_CHUNK_METRES)))
			var seed_h := _tile_hash(tile, 29)
			var hall: Vector2i = simulation.town_hall_position if simulation.is_town_hall_founded() else Vector2i.ZERO
			var dist := Vector2(float(tile.x - hall.x), float(tile.y - hall.y)).length()
			# Three zones, readable at 720p. MultiMesh only.
			var zone := "forest"
			if dist < 12.0:
				zone = "settlement"
			elif dist < 22.0:
				zone = "meadow"
			var cell := Vector2i(int(floor(float(tile.x) / 3.0)), int(floor(float(tile.y) / 3.0)))
			var in_clump := _tile_hash(cell, 17) % 4 == 0
			var core := in_clump and seed_h % 5 != 4
			if zone == "settlement":
				if core:
					_bucket_patch(chunk_buckets, chunk, "tufts", _tuft_transform(tile, 2, 0.95))
					if seed_h % 2 == 0:
						_bucket_patch(chunk_buckets, chunk, "tufts", _tuft_transform(tile, 12, 0.70))
					if flower_path != "" and seed_h % 3 == 0:
						_bucket_patch(chunk_buckets, chunk, "flowers", _nature_transform_at(tile, 6, flower_path, 0.55, 1.35, 0.55))
					if rock_path != "" and seed_h % 5 == 0:
						_bucket_patch(chunk_buckets, chunk, "stones", _nature_transform_at(tile, 7, rock_path, 0.45, 0.62, 0.28))
				elif seed_h % 13 == 0:
					_bucket_patch(chunk_buckets, chunk, "tufts", _tuft_transform(tile, 2, 0.78))
			elif zone == "meadow":
				if core:
					_bucket_patch(chunk_buckets, chunk, "tufts", _tuft_transform(tile, 3, 1.12))
					_bucket_patch(chunk_buckets, chunk, "tufts", _tuft_transform(tile, 4, 0.82))
					if flower_path != "" and seed_h % 3 == 0:
						_bucket_patch(chunk_buckets, chunk, "flowers", _nature_transform_at(tile, 6, flower_path, 0.70, 1.45, 0.50))
						_bucket_patch(chunk_buckets, chunk, "flowers", _nature_transform_at(tile, 8, flower_path, 0.55, 1.10, 0.40))
					if rock_path != "" and seed_h % 5 == 0:
						_bucket_patch(chunk_buckets, chunk, "stones", _nature_transform_at(tile, 7, rock_path, 0.50, 0.58, 0.30))
				elif seed_h % 11 == 0:
					_bucket_patch(chunk_buckets, chunk, "tufts", _tuft_transform(tile, 3, 0.88))
			else:
				if core:
					_bucket_patch(chunk_buckets, chunk, "tufts", _tuft_transform(tile, 5, 1.20))
					if Catalog.UNDERSTORY.size() > 0 and seed_h % 2 == 0:
						_bucket_patch(chunk_buckets, chunk, "shrubs", _nature_transform_at(tile, 9, String(Catalog.UNDERSTORY[0]), 0.60, 1.15, 0.45))
					if rock_path != "" and seed_h % 4 == 0:
						_bucket_patch(chunk_buckets, chunk, "stones", _nature_transform_at(tile, 7, rock_path, 0.50, 0.70, 0.32))
				elif seed_h % 9 == 0:
					_bucket_patch(chunk_buckets, chunk, "tufts", _tuft_transform(tile, 5, 0.92))
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


func _tuft_transform(tile: Vector2i, index: int, scale_mul: float) -> Transform3D:
	var world := tile_to_world(Vector2(tile))
	var jitter := _deterministic_offset(tile, index, 0.70)
	world += Vector3(jitter.x, 0.22, jitter.y)
	var yaw := float(_tile_hash(tile, 61 + index) % 628) / 100.0
	var s := scale_mul * (0.85 + float(_tile_hash(tile, 71 + index) % 40) / 100.0)
	return Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s)), world)


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
	if kind == "tufts":
		var blade := PrismMesh.new()
		blade.size = Vector3(0.42, 0.70, 0.16)
		return blade
	if kind == "shrubs" and Catalog.UNDERSTORY.size() > 0:
		return _mesh_for_nature_path(String(Catalog.UNDERSTORY[0]))
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
		"tufts":
			material.albedo_color = Color("#527038")
		"flowers":
			return null
		"shrubs":
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
	for building_value in simulation.buildings:
		var building: Dictionary = building_value
		var type_name := String(building.get("planned_type", "")) if bool(building.get("construction", false)) else String(building.get("type", ""))
		var anchor: Vector2i = building.get("position", Vector2i.ZERO)
		var footprint := _building_footprint_for_visual(building, type_name)
		if _tile_inside_visual_footprint(tile, anchor, footprint):
			return true
	return false


func _in_founding_yard(tile: Vector2i, radius := 8.0) -> bool:
	if simulation == null or not simulation.is_town_hall_founded():
		return false
	if simulation.has_method("_in_founding_clearing"):
		return bool(simulation._in_founding_clearing(tile))
	var hall: Vector2i = simulation.town_hall_position
	var footprint := Defs.building_footprint(Defs.BUILDING_TOWN_HALL)
	var center := Vector2(hall) + Vector2(footprint - Vector2i.ONE) * 0.5
	return Vector2(tile).distance_to(center) < radius


func _near_founding_meadow(tile: Vector2i) -> bool:
	if simulation == null or not simulation.is_town_hall_founded():
		return false
	var hall: Vector2i = simulation.town_hall_position
	var footprint := Defs.building_footprint(Defs.BUILDING_TOWN_HALL)
	var center := Vector2(hall) + Vector2(footprint - Vector2i.ONE) * 0.5
	return Vector2(tile).distance_to(center) < 12.5


func founding_yard_blockers(radius := 8.0) -> Dictionary:
	# Presentation + sim blockers inside the opening yard. Uses the
	# seeded ellipse when the simulation has a founding site.
	var trees := 0
	var rocks := 0
	var tree_tiles: Array[Vector2i] = []
	if simulation == null or not simulation.is_town_hall_founded():
		return {"trees": 0, "rocks": 0, "radius": radius, "tree_tiles": tree_tiles}
	var hall: Vector2i = simulation.town_hall_position
	var footprint := Defs.building_footprint(Defs.BUILDING_TOWN_HALL)
	var center := Vector2(hall) + Vector2(footprint - Vector2i.ONE) * 0.5
	var rx := radius
	var ry := radius
	if simulation.founding_site is Dictionary and not simulation.founding_site.is_empty():
		rx = float(simulation.founding_site.get("rx", radius))
		ry = float(simulation.founding_site.get("ry", radius))
	var reach := int(ceil(maxf(rx, ry)))
	var origin := Vector2i(int(round(center.x)), int(round(center.y)))
	for oy in range(-reach, reach + 1):
		for ox in range(-reach, reach + 1):
			var tile := origin + Vector2i(ox, oy)
			if not simulation.is_inside_map(tile):
				continue
			if simulation.has_method("_in_founding_clearing"):
				if not bool(simulation._in_founding_clearing(tile)):
					continue
			elif Vector2(tile).distance_to(center) >= radius:
				continue
			var kind := String(simulation.get_tile(tile))
			if kind == Defs.TILE_TREE:
				trees += 1
				tree_tiles.append(tile)
			elif kind == Defs.TILE_ROCK:
				rocks += 1
	return {"trees": trees, "rocks": rocks, "radius": maxf(rx, ry), "tree_tiles": tree_tiles}


func non_inspectable_building_meshes(radius_tiles := 16.0) -> Array[String]:
	# Dress cottage / fake-building meshes that are not BuildingView
	# nodes. radius_tiles < 0 scans the whole map.
	var names: Array[String] = []
	if resource_visuals_root == null:
		return names
	var hall := Vector2i.ZERO
	var has_hall := false
	if simulation != null and bool(simulation.is_town_hall_founded()):
		has_hall = true
		hall = Vector2i(simulation.town_hall_position)
	_collect_non_inspectable_buildings(resource_visuals_root, hall, radius_tiles, has_hall, names)
	return names


func _is_dress_building_name(label: String) -> bool:
	for kind in DRESS_BUILDING_KINDS:
		if label.begins_with("Dress_%s" % kind):
			return true
	return false


func _collect_non_inspectable_buildings(node: Node, hall: Vector2i, radius_tiles: float, has_hall: bool, names: Array[String]) -> void:
	var label := String(node.name)
	if _is_dress_building_name(label):
		var include := radius_tiles < 0.0 or not has_hall
		if not include and node is Node3D:
			var tile := world_to_tile((node as Node3D).global_position)
			include = Vector2(tile).distance_to(Vector2(hall)) <= radius_tiles
		if include:
			names.append(label)
	for child in node.get_children():
		_collect_non_inspectable_buildings(child, hall, radius_tiles, has_hall, names)


func _nature_suppressed_near_activity(tile: Vector2i) -> bool:
	if _in_founding_yard(tile, 8.0):
		return true
	for building_value in simulation.buildings:
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
	var pit_r := 7.4
	if simulation.get("crater_pit_radius") != null:
		pit_r = maxf(float(simulation.crater_pit_radius) * ScaleProfile.LOGICAL_CELL_METRES * 0.42, 6.2)

	# Irregular excavated bowl — never a flattened sphere (those read as
	# a dark oval pad) and never a glowing column.
	var pit := MeshInstance3D.new()
	pit.name = "ImpactPit"
	pit.mesh = _impact_bowl_mesh(pit_r * 0.92, 1.15)
	pit.position = Vector3(0.10, 0.02, -0.08)
	var pit_mat := StandardMaterial3D.new()
	pit_mat.albedo_color = Color("#2C2A26")
	pit_mat.roughness = 0.96
	pit.material_override = pit_mat
	pit.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shard_beacon.add_child(pit)

	var earth := StandardMaterial3D.new()
	earth.albedo_color = Color("#4A4338")
	earth.roughness = 0.94
	var cracked := StandardMaterial3D.new()
	cracked.albedo_color = Color("#3A3834")
	cracked.roughness = 0.90
	var spoil := [
		{"pos": Vector3(3.6, 0.0, 1.8), "wide": 2.6, "tall": 0.72, "rot": 0.4},
		{"pos": Vector3(-3.9, 0.0, -1.4), "wide": 2.2, "tall": 0.58, "rot": -0.7},
		{"pos": Vector3(1.8, 0.0, -3.6), "wide": 2.4, "tall": 0.64, "rot": 1.1},
		{"pos": Vector3(-2.6, 0.0, 3.2), "wide": 2.0, "tall": 0.50, "rot": 2.2},
		{"pos": Vector3(4.2, 0.0, -2.4), "wide": 1.8, "tall": 0.46, "rot": -1.4}
	]
	for i in spoil.size():
		var mound := MeshInstance3D.new()
		mound.name = "ImpactSpoil_%d" % i
		mound.mesh = _bevelled_ridge_mesh(11 + i * 7, float(spoil[i]["wide"]), float(spoil[i]["tall"]))
		mound.position = spoil[i]["pos"]
		mound.rotation = Vector3(0.0, float(spoil[i]["rot"]), 0.0)
		mound.material_override = earth if i % 2 == 0 else cracked
		mound.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shard_beacon.add_child(mound)

	shard_crystal_material = StandardMaterial3D.new()
	shard_crystal_material.albedo_color = Color(0.38, 0.50, 0.54, 0.90)
	shard_crystal_material.emission_enabled = true
	shard_crystal_material.emission = Color("#3f9fb8")
	shard_crystal_material.emission_energy_multiplier = 0.9
	shard_crystal_material.roughness = 0.48
	shard_crystal_material.metallic = 0.14
	var crystal_specs := [
		{"size": Vector3(1.05, 1.55, 0.72), "pos": Vector3(0.28, 0.22, 0.16), "rot": Vector3(28.0, 18.0, 102.0)},
		{"size": Vector3(0.68, 1.05, 0.48), "pos": Vector3(-0.82, 0.08, 0.70), "rot": Vector3(-18.0, 48.0, 88.0)},
		{"size": Vector3(0.55, 0.82, 0.38), "pos": Vector3(0.95, 0.04, -0.58), "rot": Vector3(34.0, -36.0, 112.0)}
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
	# Beta world pass: the Shard is the realm's focal point. Taller crystal
	# cluster and one cool glow light so it reads from the strategy camera.
	for index in shard_beacon.get_child_count():
		var c := shard_beacon.get_child(index)
		if c is MeshInstance3D and String(c.name).begins_with("ShardCrystal_"):
			(c as Node3D).scale = Vector3(1.9, 2.4, 1.9)
			(c as Node3D).position *= 1.7
	var shard_glow := OmniLight3D.new()
	shard_glow.name = "ShardGlow"
	shard_glow.light_color = Color("#7fd6ea")
	shard_glow.light_energy = 1.1
	shard_glow.omni_range = 10.0
	shard_glow.shadow_enabled = false
	shard_glow.position = Vector3(0.0, 2.6, 0.0)
	shard_beacon.add_child(shard_glow)

	shard_beacon_column = MeshInstance3D.new()
	shard_beacon_column.name = "ShardColumn"
	var vein := BoxMesh.new()
	vein.size = Vector3(0.18, 0.08, 2.4)
	shard_beacon_column.mesh = vein
	shard_beacon_column.position = Vector3(0.4, 0.06, -0.2)
	shard_beacon_column.rotation_degrees = Vector3(0.0, 28.0, 0.0)
	var vein_mat := StandardMaterial3D.new()
	vein_mat.albedo_color = Color(0.30, 0.44, 0.48, 0.62)
	vein_mat.emission_enabled = true
	vein_mat.emission = Color("#244850")
	vein_mat.emission_energy_multiplier = 0.22
	vein_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shard_beacon_column.material_override = vein_mat
	shard_beacon_column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shard_beacon.add_child(shard_beacon_column)

	shard_beacon_light = OmniLight3D.new()
	shard_beacon_light.name = "ShardLight"
	shard_beacon_light.light_color = Color("#5a848c")
	shard_beacon_light.light_energy = 0.32
	shard_beacon_light.omni_range = 5.5
	shard_beacon_light.shadow_enabled = false
	shard_beacon_light.position = Vector3(0.0, 1.1, 0.0)
	shard_beacon.add_child(shard_beacon_light)

	var debris_offsets := [
		Vector3(2.4, 0.18, 1.0), Vector3(-1.8, 0.12, 2.1), Vector3(3.1, 0.20, -1.4),
		Vector3(-2.8, 0.10, -0.8), Vector3(1.1, 0.22, -2.6), Vector3(-0.4, 0.28, 2.8),
		Vector3(3.6, 0.14, 0.5), Vector3(-3.2, 0.16, 1.4), Vector3(1.8, 0.24, 2.4),
		Vector3(-1.5, 0.10, -2.9)
	]
	for fragment_index in debris_offsets.size():
		var fragment := MeshInstance3D.new()
		fragment.name = "ImpactRock_%d" % fragment_index
		var rock := PrismMesh.new()
		rock.size = Vector3(0.55 + float(fragment_index % 4) * 0.18, 0.32 + float(fragment_index % 3) * 0.14, 0.40)
		fragment.mesh = rock
		fragment.position = debris_offsets[fragment_index]
		fragment.rotation = Vector3(0.31 * fragment_index, 0.7 * fragment_index, 0.22 * fragment_index)
		var rock_material := StandardMaterial3D.new()
		rock_material.albedo_color = Color("#3d4650").lerp(Color("#5a5348"), float(fragment_index % 3) / 3.0)
		fragment.material_override = rock_material
		fragment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shard_beacon.add_child(fragment)


func _update_shard_beacon(wyrdfall: Dictionary) -> void:
	if shard_beacon_light == null:
		return
	var binding := bool(wyrdfall.get("binding_active", false)) or bool(wyrdfall.get("reckoning", false))
	var progress := clampf(float(wyrdfall.get("binding_percent", 0.0)) / 100.0, 0.0, 1.0)
	var pulse := 1.0 + (0.10 + 0.16 * progress if binding else 0.03) * (0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 280.0))
	shard_beacon_light.light_energy = (0.85 if binding else 0.32) * pulse
	shard_beacon_light.light_color = Color("#5a848c").lerp(Color("#7a6a98"), progress if binding else 0.0)
	if shard_beacon_column != null:
		var material := shard_beacon_column.material_override as StandardMaterial3D
		if material != null:
			material.emission_energy_multiplier = (0.55 if binding else 0.22) * pulse
	if shard_crystal_material != null:
		shard_crystal_material.emission_energy_multiplier = (1.6 if binding else 0.9) * pulse


func _update_seal_ceremony(wyrdfall: Dictionary) -> void:
	var sealing := bool(wyrdfall.get("binding_active", false)) or bool(wyrdfall.get("seal_active", false))
	var celebrating := bool(wyrdfall.get("victory_ceremony", false))
	if simulation != null and bool(simulation.victory):
		celebrating = true
	var fissure := Vector2i(-1, -1)
	if simulation != null and simulation.crater_war != null:
		fissure = simulation.crater_war.primary_fissure
	if (not sealing and not celebrating) or fissure.x < 0:
		if seal_beacon != null:
			seal_beacon.visible = false
		return
	if seal_beacon == null:
		seal_beacon = Node3D.new()
		seal_beacon.name = "SealCeremony"
		if vfx_root != null:
			vfx_root.add_child(seal_beacon)
		else:
			add_child(seal_beacon)
		seal_beacon_column = MeshInstance3D.new()
		var column := CylinderMesh.new()
		column.top_radius = 0.22
		column.bottom_radius = 0.55
		column.height = 7.2
		seal_beacon_column.mesh = column
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.35, 0.82, 0.88, 0.55)
		material.emission_enabled = true
		material.emission = Color(0.45, 0.95, 1.0, 1)
		material.emission_energy_multiplier = 1.6
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		seal_beacon_column.material_override = material
		seal_beacon_column.position = Vector3(0.0, 3.6, 0.0)
		seal_beacon.add_child(seal_beacon_column)
		seal_beacon_light = OmniLight3D.new()
		seal_beacon_light.light_color = Color("#8ef6ff")
		seal_beacon_light.omni_range = 18.0
		seal_beacon_light.light_energy = 2.4
		seal_beacon_light.position = Vector3(0.0, 4.2, 0.0)
		seal_beacon.add_child(seal_beacon_light)
		seal_ward_ring = MeshInstance3D.new()
		seal_ward_ring.name = "SealWard"
		var torus := TorusMesh.new()
		torus.inner_radius = 3.2
		torus.outer_radius = 3.75
		seal_ward_ring.mesh = torus
		var ring_mat := StandardMaterial3D.new()
		ring_mat.albedo_color = Color(0.4, 0.85, 0.95, 0.42)
		ring_mat.emission_enabled = true
		ring_mat.emission = Color(0.45, 0.95, 1.0)
		ring_mat.emission_energy_multiplier = 1.1
		ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		seal_ward_ring.material_override = ring_mat
		seal_ward_ring.position = Vector3(0.0, 0.35, 0.0)
		seal_beacon.add_child(seal_ward_ring)
		seal_wave = MeshInstance3D.new()
		seal_wave.name = "SealWave"
		var disc := CylinderMesh.new()
		disc.top_radius = 1.0
		disc.bottom_radius = 1.0
		disc.height = 0.14
		seal_wave.mesh = disc
		var wave_mat := StandardMaterial3D.new()
		wave_mat.albedo_color = Color(0.85, 0.95, 1.0, 0.35)
		wave_mat.emission_enabled = true
		wave_mat.emission = Color(0.75, 0.95, 1.0)
		wave_mat.emission_energy_multiplier = 2.2
		wave_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		seal_wave.material_override = wave_mat
		seal_wave.position = Vector3(0.0, 0.55, 0.0)
		seal_wave.visible = false
		seal_beacon.add_child(seal_wave)
		seal_palisade_root = Node3D.new()
		seal_palisade_root.name = "SealPalisades"
		seal_beacon.add_child(seal_palisade_root)
	seal_beacon.visible = true
	seal_beacon.global_position = tile_to_world(Vector2(fissure))
	var look: Dictionary = wyrdfall.get("seal_look", {})
	if look.is_empty() and simulation != null and simulation.crater_war != null:
		look = simulation.crater_war.seal_look()
	var path := String(look.get("path", ""))
	if celebrating:
		path = "victory"
	if path != seal_look_key:
		seal_look_key = path
		_apply_seal_look(look, celebrating)
	var progress := clampf(float(wyrdfall.get("binding_percent", 0.0)) / 100.0, 0.0, 1.0)
	var hz := float(look.get("pulse_hz", 0.7))
	if celebrating:
		hz = 0.9
	var pulse := 1.15 + 0.55 * progress + 0.28 * sin(float(Time.get_ticks_msec()) * 0.001 * TAU * hz)
	if path == "overcharge":
		pulse = 1.55 + 0.85 * progress + 0.55 * sin(float(Time.get_ticks_msec()) * 0.001 * TAU * hz)
	elif path == "wall":
		pulse = 1.05 + 0.35 * progress + 0.16 * sin(float(Time.get_ticks_msec()) * 0.001 * TAU * hz)
	elif celebrating:
		# The Director: TEST #20 — the fissure calms: a slow sink, cool light.
		pulse = 0.72 + 0.12 * sin(float(Time.get_ticks_msec()) / 420.0)
	if seal_beacon_light != null:
		seal_beacon_light.light_energy = float(look.get("light", 1.8)) * pulse
		if celebrating:
			seal_beacon_light.light_energy = 1.15 * pulse
			seal_beacon_light.light_color = Color("#9fd4c8")
	if seal_beacon_column != null:
		var column_mat := seal_beacon_column.material_override as StandardMaterial3D
		if column_mat != null:
			column_mat.emission_energy_multiplier = (0.55 if celebrating else (2.4 if path == "overcharge" else 1.2)) * pulse
		var fat := 1.22 if path == "overcharge" else 1.0
		var calm := 0.55 if celebrating else 1.0
		seal_beacon_column.scale = Vector3((1.0 + 0.18 * progress) * fat * calm, (1.0 + 0.35 * progress) * (0.42 if celebrating else 1.0), (1.0 + 0.18 * progress) * fat * calm)
	if seal_ward_ring != null:
		var ring_mat := seal_ward_ring.material_override as StandardMaterial3D
		if ring_mat != null:
			ring_mat.emission_energy_multiplier = 0.9 * pulse
		seal_ward_ring.rotation.y += 0.008 if path != "overcharge" else 0.03
	if seal_wave != null:
		seal_wave.visible = path == "overcharge" or celebrating
		if seal_wave.visible:
			var swell := 3.6 + 4.2 * (0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 70.0))
			seal_wave.scale = Vector3(swell, 1.4, swell)
			var wave_mat := seal_wave.material_override as StandardMaterial3D
			if wave_mat != null:
				wave_mat.emission_energy_multiplier = 3.4
				wave_mat.albedo_color = Color(0.92, 0.98, 1.0, 0.55)


func _apply_seal_look(look: Dictionary, celebrating: bool) -> void:
	var path := String(look.get("path", ""))
	var wall := path == "wall"
	var charge := path == "overcharge"
	var amber := Color(0.92, 0.62, 0.22, 0.7)
	var cyan := Color(0.35, 0.82, 0.88, 0.55)
	var white := Color(0.82, 0.95, 1.0, 0.72)
	var gold := Color(0.95, 0.78, 0.28, 0.8)
	var calm := Color(0.55, 0.82, 0.74, 0.55)
	var column_color := calm if celebrating else (amber if wall else (white if charge else cyan))
	if seal_beacon_column != null:
		var column_mat := seal_beacon_column.material_override as StandardMaterial3D
		if column_mat != null:
			column_mat.albedo_color = column_color
			column_mat.emission = column_color.lightened(0.15)
	if seal_beacon_light != null:
		seal_beacon_light.light_color = Color("#9fd4c8") if celebrating else (Color("#f0a24a") if wall else Color("#b8f6ff"))
		seal_beacon_light.omni_range = 14.0 if celebrating else (22.0 if charge else 16.0)
	if seal_ward_ring != null:
		var torus := TorusMesh.new()
		var radius := 6.4 if wall else (2.1 if charge else 3.6)
		var thick := 1.15 if wall else (0.28 if charge else 0.55)
		if celebrating:
			radius = 4.2
			thick = 0.7
		torus.inner_radius = maxf(0.2, radius - thick)
		torus.outer_radius = radius
		seal_ward_ring.mesh = torus
		var ring_mat := seal_ward_ring.material_override as StandardMaterial3D
		if ring_mat != null:
			ring_mat.albedo_color = Color(column_color, 0.45 if charge else 0.62)
			ring_mat.emission = column_color
	if seal_palisade_root != null:
		for child in seal_palisade_root.get_children():
			child.queue_free()
		if wall or celebrating:
			var posts := 8 if wall else 4
			for index in range(posts):
				var angle := float(index) * TAU / float(posts)
				var post := MeshInstance3D.new()
				var box := BoxMesh.new()
				box.size = Vector3(0.85, 3.6, 0.55)
				post.mesh = box
				post.position = Vector3(cos(angle) * 5.8, 1.8, sin(angle) * 5.8)
				post.rotation.y = -angle
				var post_mat := StandardMaterial3D.new()
				post_mat.albedo_color = Color("#8a4a18") if wall else Color("#c9a24a")
				post_mat.emission_enabled = true
				post_mat.emission = Color("#ff8a2a") if wall else Color("#f0c44a")
				post_mat.emission_energy_multiplier = 1.8
				post.material_override = post_mat
				seal_palisade_root.add_child(post)
				var plank := MeshInstance3D.new()
				var plank_mesh := BoxMesh.new()
				plank_mesh.size = Vector3(2.4, 0.35, 0.22)
				plank.mesh = plank_mesh
				plank.position = Vector3(cos(angle) * 5.8, 2.4, sin(angle) * 5.8)
				plank.rotation.y = -angle + PI * 0.5
				plank.material_override = post_mat
				seal_palisade_root.add_child(plank)


func _update_channel_flash(wyrdfall: Dictionary) -> void:
	var look: Dictionary = wyrdfall.get("seal_look", {})
	var flash := bool(look.get("channel_flash", false)) or bool(wyrdfall.get("channel_ready", false)) and int(wyrdfall.get("channel_uses", 0)) > 0
	var last_at := float(wyrdfall.get("last_channel_at", -1.0))
	if simulation != null:
		flash = last_at >= 0.0 and float(simulation.elapsed_seconds) - last_at < 3.5
	var tile: Vector2i = wyrdfall.get("last_channel_tile", Vector2i(-1, -1))
	if look.has("channel_tile"):
		tile = look.get("channel_tile", tile)
	if not flash or tile.x < 0:
		if channel_flash != null:
			channel_flash.visible = false
		return
	if channel_flash == null:
		channel_flash = Node3D.new()
		channel_flash.name = "ChannelFlash"
		if vfx_root != null:
			vfx_root.add_child(channel_flash)
		else:
			add_child(channel_flash)
		channel_flash_ring = MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.85
		torus.outer_radius = 1.55
		channel_flash_ring.mesh = torus
		var ring_mat := StandardMaterial3D.new()
		ring_mat.albedo_color = Color(0.45, 0.95, 0.85, 0.7)
		ring_mat.emission_enabled = true
		ring_mat.emission = Color(0.55, 1.0, 0.88)
		ring_mat.emission_energy_multiplier = 3.2
		ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		channel_flash_ring.material_override = ring_mat
		channel_flash_ring.position = Vector3(0.0, 0.55, 0.0)
		channel_flash.add_child(channel_flash_ring)
		channel_flash_light = OmniLight3D.new()
		channel_flash_light.light_color = Color("#7ee0d4")
		channel_flash_light.omni_range = 10.0
		channel_flash_light.light_energy = 4.2
		channel_flash_light.position = Vector3(0.0, 2.4, 0.0)
		channel_flash.add_child(channel_flash_light)
		var column := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.12
		cyl.bottom_radius = 0.35
		cyl.height = 4.8
		column.mesh = cyl
		var col_mat := StandardMaterial3D.new()
		col_mat.albedo_color = Color(0.55, 0.95, 0.9, 0.55)
		col_mat.emission_enabled = true
		col_mat.emission = Color(0.65, 1.0, 0.92)
		col_mat.emission_energy_multiplier = 2.8
		col_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		column.material_override = col_mat
		column.position = Vector3(0.0, 2.4, 0.0)
		channel_flash.add_child(column)
	channel_flash.visible = true
	channel_flash.global_position = tile_to_world(Vector2(tile))
	var age := 0.0
	if simulation != null:
		age = float(simulation.elapsed_seconds) - last_at
	var swell := 1.15 + 0.85 * (1.0 - clampf(age / 3.5, 0.0, 1.0)) + 0.18 * sin(float(Time.get_ticks_msec()) / 70.0)
	if channel_flash_ring != null:
		channel_flash_ring.scale = Vector3(swell, 1.0, swell)
		channel_flash_ring.rotation.y += 0.06
	if channel_flash_light != null:
		channel_flash_light.light_energy = 4.8 * (1.0 - clampf(age / 3.5, 0.0, 1.0))


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
		_road_merge_dirty[_road_chunk((road_views[key_value] as ProductionRoadView3D).tile)] = true
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
			_road_merge_dirty[_road_chunk(tile)] = true
		elif String(road_signatures.get(key_value, "")) != next_signature:
			(road_views[key_value] as ProductionRoadView3D).configure(int(snapshot.get("id", 0)), tile, mask, planned)
			road_signatures[key_value] = next_signature
			_road_merge_dirty[_road_chunk(tile)] = true
	_merge_dirty_road_chunks()
	_rebuild_road_stamps(desired)


## R31 draw calls: each road tile used to be two MeshInstance3Ds (edge + dirt),
## i.e. two draw calls per tile. Static batching: per 16-tile chunk, the tile
## meshes are baked into one mesh per shared material and the per-tile meshes
## are hidden (their decals stay). Same vertices, same materials, same
## transforms, so the picture is unchanged; only the draw count drops.
const ROAD_MERGE_CHUNK := 16
var _road_merge_dirty: Dictionary = {}
var _road_merged: Dictionary = {}


func _road_chunk(t: Vector2i) -> Vector2i:
	return Vector2i(int(floor(float(t.x) / ROAD_MERGE_CHUNK)), int(floor(float(t.y) / ROAD_MERGE_CHUNK)))


func _merge_dirty_road_chunks() -> void:
	if _road_merge_dirty.is_empty() or roads_root == null:
		return
	var dirty := _road_merge_dirty
	_road_merge_dirty = {}
	var tools := {}
	var mats := {}
	for view_value in road_views.values():
		var view := view_value as ProductionRoadView3D
		if view == null or not is_instance_valid(view) or view.is_queued_for_deletion():
			continue
		var chunk := _road_chunk(view.tile)
		if not dirty.has(chunk):
			continue
		for child in view.get_children():
			var mi := child as MeshInstance3D
			if mi == null or mi.mesh == null or mi.is_queued_for_deletion():
				continue
			var mat: Material = mi.material_override
			var key := "%d,%d|%d" % [chunk.x, chunk.y, mat.get_instance_id() if mat != null else 0]
			if not tools.has(key):
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				tools[key] = st
				mats[key] = mat
			(tools[key] as SurfaceTool).append_from(mi.mesh, 0, view.transform * mi.transform)
			mi.visible = false
	for chunk in dirty:
		var old: Array = _road_merged.get(chunk, [])
		for n in old:
			if is_instance_valid(n):
				(n as Node).queue_free()
		_road_merged.erase(chunk)
	for key in tools:
		var chunk_key := String(key).split("|")[0].split(",")
		var chunk := Vector2i(int(chunk_key[0]), int(chunk_key[1]))
		var inst := MeshInstance3D.new()
		inst.name = "RoadMerged_%d_%d" % [chunk.x, chunk.y]
		inst.mesh = (tools[key] as SurfaceTool).commit()
		inst.material_override = mats[key]
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		roads_root.add_child(inst)
		if not _road_merged.has(chunk):
			_road_merged[chunk] = []
		(_road_merged[chunk] as Array).append(inst)


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


var _building_snapshot_hashes: Dictionary = {}


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
			# Hotfix 7: apply_snapshot is a pure function of the snapshot;
			# skip it (and the position write) when nothing changed.
			var snap_hash := snapshot.hash()
			if int(_building_snapshot_hashes.get(id, -1)) == snap_hash:
				continue
			_building_snapshot_hashes[id] = snap_hash
			var view: ProductionBuildingView3D = building_views[id]
			view.position = tile_to_world(Vector2(snapshot.get("center", Vector2.ZERO)))
			view.apply_snapshot(snapshot)
	for id_value in building_views.keys():
		if desired.has(id_value):
			continue
		(building_views[id_value] as Node).queue_free()
		building_views.erase(id_value)
		_building_snapshot_hashes.erase(id_value)
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
	var mask_size := Vector2i(ceili(float(map_size.x) / FOG_MASK_DIVISOR), ceili(float(map_size.y) / FOG_MASK_DIVISOR))
	# Hotfix 6: paint vision straight onto the mask lattice (no per-tile
	# string-keyed Dictionary; was ~45 ms per fog change on Shard).
	var visible_mask := _paint_current_vision_mask(mask_size)
	var explored := _explored_lattice_for(mask_size)
	if _inside_lattice_size != mask_size or _inside_lattice_sim != simulation:
		_inside_lattice = PackedByteArray()
		_inside_lattice.resize(mask_size.x * mask_size.y)
		for iy in mask_size.y:
			for ix in mask_size.x:
				if simulation.is_inside_map(Vector2i(ix * FOG_MASK_DIVISOR, iy * FOG_MASK_DIVISOR)):
					_inside_lattice[iy * mask_size.x + ix] = 1
		_inside_lattice_size = mask_size
		_inside_lattice_sim = simulation
	var mask_bytes := PackedByteArray()
	var cells := mask_size.x * mask_size.y
	mask_bytes.resize(cells)
	for i in cells:
		var shroud := FOG_UNEXPLORED
		if _inside_lattice[i] != 0:
			if visible_mask[i] != 0:
				shroud = FOG_VISIBLE
			elif explored[i] != 0:
				shroud = FOG_EXPLORED
		mask_bytes[i] = shroud
	var upsample := FOG_DISPLAY_UPSAMPLE if map_size.x <= 80 else 2
	# 320² at divisor 1 was ~400 ms of the 2242 ms start. 2×2 cells still
	# feather inside the 1.25-cell shader.
	var display_size := mask_size * upsample
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
			_sync_fog_screen_camera()
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
	fog_material.set_shader_parameter("explored_opacity", 0.38)
	fog_material.set_shader_parameter("cell_metres", ScaleProfile.LOGICAL_CELL_METRES)
	fog_material.set_shader_parameter("feather_cells", 1.25)
	fog_material.set_shader_parameter("noise_strength", 0.12)
	fog_material.set_shader_parameter("shore_fade_metres", SHORE_FADE_METRES)
	if fog_screen_material != null:
		fog_screen_material.set_shader_parameter("unknown_opacity", 1.0)
		fog_screen_material.set_shader_parameter("explored_opacity", 0.38)
		fog_screen_material.set_shader_parameter("cell_metres", ScaleProfile.LOGICAL_CELL_METRES)
		fog_screen_material.set_shader_parameter("feather_cells", 1.25)
		fog_screen_material.set_shader_parameter("noise_strength", 0.12)
		fog_screen_material.set_shader_parameter("unknown_color", FOG_UNKNOWN_BASE)
		fog_screen_material.set_shader_parameter("mist_color", FOG_MIST_BASE)
		fog_screen_material.set_shader_parameter("world_min_xz", _fog_world_min_xz())
		fog_screen_material.set_shader_parameter("world_size_xz", _fog_world_size_xz())
	_ensure_fog_volume()


func _explored_lattice_for(mask_size: Vector2i) -> PackedByteArray:
	var revealed: Dictionary = simulation.revealed_tiles
	var count := revealed.size()
	var start := _explored_lattice_count
	if not is_same(revealed, _explored_lattice_dict) or mask_size != _explored_lattice_size or count < start:
		_explored_lattice = PackedByteArray()
		_explored_lattice.resize(mask_size.x * mask_size.y)
		_explored_lattice_size = mask_size
		_explored_lattice_dict = revealed
		start = 0
	if count > start:
		var keys := revealed.keys()
		for i in range(start, count):
			var parts := String(keys[i]).split(",")
			if parts.size() != 2:
				continue
			var x := int(parts[0])
			var y := int(parts[1])
			if x < 0 or y < 0 or x % FOG_MASK_DIVISOR != 0 or y % FOG_MASK_DIVISOR != 0:
				continue
			var mx := x / FOG_MASK_DIVISOR
			var my := y / FOG_MASK_DIVISOR
			if mx < mask_size.x and my < mask_size.y:
				_explored_lattice[my * mask_size.x + mx] = 1
	_explored_lattice_count = count
	return _explored_lattice


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
	return "%d:%d" % [value, int(simulation.buildings.size())]


func _paint_current_vision() -> Dictionary:
	var visible: Dictionary = {}
	if simulation == null:
		return visible
	if simulation.is_town_hall_founded():
		var hall_fp := Defs.building_footprint(Defs.BUILDING_TOWN_HALL)
		var hall_center: Vector2i = simulation._footprint_center(simulation.town_hall_position, hall_fp)
		_paint_vision_disk(visible, hall_center, simulation.building_vision_radius(Defs.BUILDING_TOWN_HALL))
	for building_value in simulation.buildings:
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


func _sync_fog_screen_camera() -> void:
	if fog_screen_material == null:
		return
	var cam := fog_overlay_camera
	if cam == null or not is_instance_valid(cam):
		return
	fog_screen_material.set_shader_parameter("camera_world_position", cam.global_position)
	fog_screen_material.set_shader_parameter("camera_near", cam.near)


func _free_camera_fog_screens() -> void:
	if fog_screen != null and is_instance_valid(fog_screen):
		if fog_screen.get_parent() != null:
			fog_screen.get_parent().remove_child(fog_screen)
		fog_screen.free()
	fog_screen = null
	if fog_overlay_camera != null and is_instance_valid(fog_overlay_camera):
		for child in fog_overlay_camera.get_children():
			if String(child.name).begins_with("ScreenFogOverlay"):
				fog_overlay_camera.remove_child(child)
				child.free()


## Gate isolation only (--gate-r32-hide=fog): keep the screen fog hidden even
## when a fog update re-shows it.
var gate_hide_fog := false
const R33_GROUND_CHEAP := 1.0


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
	fog_screen_material.set_shader_parameter("explored_opacity", 0.38)
	fog_screen_material.set_shader_parameter("cell_metres", ScaleProfile.LOGICAL_CELL_METRES)
	fog_screen_material.set_shader_parameter("feather_cells", 1.25)
	fog_screen_material.set_shader_parameter("noise_strength", 0.12)
	_sync_fog_screen_camera()
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
	fog_screen.visible = not gate_hide_fog


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
		fog_screen_material.set_shader_parameter("haze_light", atmosphere)
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
		# R33 test build: cheap ground shading is the default (Helmer 19:30).
		# Roads, water and lights keep following the palette.
		ground_mat.set_shader_parameter("lod_cheap", maxf(float(palette.get("terrain_lod_cheap", 0.0)), R33_GROUND_CHEAP))
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
	var sim_y := float(simulation.get_height(tile)) * ScaleProfile.TERRAIN_ELEVATION_UNIT_METRES
	var corners := [
		Vector3(center.x - half, sim_y + _visual_relief_y(Vector2(center.x - half, center.z - half)), center.z - half),
		Vector3(center.x + half, sim_y + _visual_relief_y(Vector2(center.x + half, center.z - half)), center.z - half),
		Vector3(center.x + half, sim_y + _visual_relief_y(Vector2(center.x + half, center.z + half)), center.z + half),
		Vector3(center.x - half, sim_y + _visual_relief_y(Vector2(center.x - half, center.z + half)), center.z + half),
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
	# The 320 province keeps the rim in fog. Off-map rings around a
	# 800 m island are VRAM we do not have on Shard.
	if map_size.x > 80:
		_append_rim_woodland(transforms_by_path)
		_spawn_nature_multimeshes(edge_forest_root, transforms_by_path)
		return
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
	ContactAO.spawn_multimesh(edge_forest_root, floors, 0.34)


func _append_rim_woodland(groups: Dictionary) -> void:
	# Trees and rocks on the last two revealed map tiles so the playable
	# AABB does not print as a hard island against the shroud.
	if simulation == null:
		return
	if map_size.x > 80:
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
	# Opening landscape only: forest frame, ridge, creek and coast.
	# No dress cottages or building-like props. Anything that looks
	# like a building must be a real, inspectable sim building.
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
	var creek_worlds: Array[Vector2] = []
	var creek_tiles: Array = simulation.founding_site.get("creek_tiles", []) if simulation.founding_site is Dictionary else []
	for tile_value in creek_tiles:
		var p := ScaleProfile.tile_to_flat_world(Vector2(Vector2i(tile_value)), map_size)
		creek_worlds.append(Vector2(p.x, p.z))
	var open_dir := Vector2(0.2, 1.0)
	var crater_dir := Vector2(0.0, -1.0)
	if simulation.founding_site is Dictionary:
		open_dir = Vector2(simulation.founding_site.get("open_dir", open_dir))
		crater_dir = Vector2(simulation.founding_site.get("crater_dir", crater_dir))
	if open_dir.length_squared() > 0.01:
		open_dir = open_dir.normalized()
	if crater_dir.length_squared() > 0.01:
		crater_dir = crater_dir.normalized()
	var bank := ScaleProfile.road_width_metres() * 0.85 + 1.6
	for oy in range(-17, 18):
		for ox in range(-17, 18):
			var dist := Vector2(float(ox), float(oy)).length()
			if dist < inner or dist > outer:
				continue
			var tile := hall + Vector2i(ox, oy)
			if reserved.has(_tile_key(tile)):
				continue
			if not simulation.is_inside_map(tile):
				continue
			if String(simulation.get_tile(tile)) != Defs.TILE_GRASS:
				continue
			if _terrain_occupied_cache.has(_tile_key(tile)) or _is_road_tile(tile):
				continue
			var world := ScaleProfile.tile_to_flat_world(Vector2(tile), map_size)
			var creek_hit := false
			for creek_xz in creek_worlds:
				if Vector2(world.x - creek_xz.x, world.z - creek_xz.y).length() < bank:
					creek_hit = true
					break
			if creek_hit:
				continue
			if _visual_path_weight(tile) > 0.28:
				continue
			if _in_founding_yard(tile):
				continue
			var dir := Vector2(float(ox), float(oy))
			if dir.length_squared() > 0.01:
				var nd := dir.normalized()
				if nd.dot(open_dir) > 0.28 or nd.dot(crater_dir) > 0.32:
					continue
			candidates.append(tile)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _opening_forest_score(a, hall) > _opening_forest_score(b, hall)
	)
	var target := clampi(int(round(float(candidates.size()) * 0.48)), 1, maxi(candidates.size(), 1))
	var planted := 0
	var planted_tiles: Array[Vector2i] = []
	for tile in candidates:
		if planted >= target:
			break
		if _tile_hash(tile, 77) % 11 == 0:
			continue
		# GFX-O: 2.5–3W clearing. Forest on ~48% of the perimeter arc,
		# back and west so the gameplay camera sees meadow + ridge.
		_append_nature_transform(transforms_by_path, _tree_path_for_tile(tile, 0, 3), tile, 0, 0.70, 1.05, 0.42)
		planted += 1
		planted_tiles.append(tile)
	# Mature edge only. No saplings or understory in the founding yard.
	for tile in planted_tiles:
		if _in_founding_yard(tile):
			continue
		if Catalog.UNDERSTORY.size() > 0 and _tile_hash(tile, 83) % 3 == 0:
			_append_nature_transform(transforms_by_path, String(Catalog.UNDERSTORY[_tile_hash(tile, 71) % Catalog.UNDERSTORY.size()]), tile, 6, 0.80, 0.72, 0.28)
	for tile in candidates:
		if _in_founding_yard(tile):
			continue
		var fringe := Vector2(float(tile.x - hall.x), float(tile.y - hall.y)).length()
		if fringe > inner + 1.35 or fringe < inner:
			continue
		if _opening_faces_build_sector(tile, hall):
			continue
		if _opening_faces_crater(tile, hall):
			continue
		if _tile_hash(tile, 103) % 5 != 0:
			continue
		if Catalog.UNDERSTORY.size() > 0:
			_append_nature_transform(transforms_by_path, String(Catalog.UNDERSTORY[0]), tile, 9, 0.70, 0.58, 0.22)
	_spawn_nature_multimeshes(host, transforms_by_path)
	var coverage := 0.0 if candidates.is_empty() else float(planted) / float(candidates.size())
	host.set_meta("opening_clearing_cells", inner)
	var yard_r := 8.0
	if simulation.founding_site is Dictionary:
		yard_r = maxf(float(simulation.founding_site.get("rx", 8.0)), float(simulation.founding_site.get("ry", 7.0)))
	host.set_meta("opening_yard_cells", yard_r)
	host.set_meta("opening_forest_coverage", coverage)
	host.set_meta("opening_forest_count", planted)
	host.set_meta("opening_perimeter_count", candidates.size())


func _opening_hamlet_spec() -> Array:
	# Empty on purpose. Dress cottages read as real buildings while
	# HUD Buildings stays 1. Showcase stamps inspectable houses instead.
	return []


func _opening_hamlet_tiles(hall: Vector2i) -> Dictionary:
	var reserved: Dictionary = {}
	for spec_value in _opening_hamlet_spec():
		var spec: Dictionary = spec_value
		for oy in range(int(spec["h"])):
			for ox in range(int(spec["w"])):
				reserved[_tile_key(hall + Vector2i(int(spec["ox"]) + ox, int(spec["oy"]) + oy))] = true
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
	# Terrain dressing only. Cottages, fences, stacks and carts used
	# to read as a hamlet the player could not inspect or own.
	_spawn_dress_coast(host, hall)
	_spawn_opening_ridge(host, hall)
	host.set_meta("hamlet_cottages", 0)
	host.set_meta("hamlet_reserved", reserved.size())
	host.set_meta("hamlet_pond", 1)
	host.set_meta("hamlet_ridge", 1)


func _opening_faces_build_sector(tile: Vector2i, hall: Vector2i) -> bool:
	if simulation == null or not (simulation.founding_site is Dictionary):
		return false
	var open_dir := Vector2(simulation.founding_site.get("open_dir", Vector2(0.2, 1.0)))
	if open_dir.length_squared() < 0.01:
		return false
	var dir := Vector2(tile - hall)
	if dir.length_squared() < 0.01:
		return false
	return dir.normalized().dot(open_dir.normalized()) > 0.28


func _opening_faces_crater(tile: Vector2i, hall: Vector2i) -> bool:
	# Leave a sight-line toward the Shard so the opening camera sees
	# wyrd crystals, scorched ground, and the crater rim.
	if simulation == null or not (simulation.founding_site is Dictionary):
		return false
	var crater_dir := Vector2(simulation.founding_site.get("crater_dir", Vector2(0.0, -1.0)))
	if crater_dir.length_squared() < 0.01:
		crater_dir = Vector2(0.0, -1.0)
	var dir := Vector2(tile - hall)
	if dir.length_squared() < 0.01:
		return false
	return dir.normalized().dot(crater_dir.normalized()) > 0.32


func _opening_forest_score(tile: Vector2i, hall: Vector2i) -> float:
	var forest_dir := Vector2(-0.8, -0.4)
	if simulation != null and simulation.founding_site is Dictionary:
		forest_dir = Vector2(simulation.founding_site.get("forest_dir", forest_dir))
	if forest_dir.length_squared() < 0.01:
		forest_dir = Vector2(-0.8, -0.4)
	var d := Vector2(tile - hall)
	var score := d.normalized().dot(forest_dir.normalized()) * 3.2 + float(_tile_hash(tile, 3) % 7) * 0.08
	if _opening_faces_build_sector(tile, hall):
		score -= 6.0
	if _opening_faces_crater(tile, hall):
		score -= 8.0
	return score


func _opening_ridge_tiles(hall: Vector2i) -> Array[Vector2i]:
	# Rim sits toward the crater so the opening reads as a meteor bowl.
	var toward := Vector2(0.0, -1.0)
	if simulation != null and simulation.founding_site is Dictionary:
		toward = Vector2(simulation.founding_site.get("crater_dir", toward))
	if toward.length_squared() < 0.01:
		toward = Vector2(0.0, -1.0)
	toward = toward.normalized()
	var ridge_side := 0.0
	if simulation != null and simulation.founding_site is Dictionary:
		ridge_side = float(simulation.founding_site.get("ridge_side", 0))
	var side := Vector2(-toward.y, toward.x)
	toward = (toward + side * ridge_side * 0.22).normalized()
	side = Vector2(-toward.y, toward.x)
	var tiles: Array[Vector2i] = []
	for spec in [
		{"along": 8.0, "side": 0.0}, {"along": 9.0, "side": 1.2}, {"along": 8.0, "side": -1.4},
		{"along": 10.0, "side": 0.6}, {"along": 7.0, "side": 1.8}, {"along": 9.0, "side": -2.0},
		{"along": 10.0, "side": -0.8}, {"along": 8.0, "side": 2.4}
	]:
		tiles.append(hall + Vector2i(
			roundi(toward.x * float(spec["along"]) + side.x * float(spec["side"])),
			roundi(toward.y * float(spec["along"]) + side.y * float(spec["side"]))
		))
	return tiles


func opening_camera_yaw() -> float:
	# Keep the classic isometric boom. Orbiting yaw by the crater heading
	# swings the 32 m offset over the 2400 m ocean pad, so south/west
	# seeds render as a teal void. Hall placement still walks 360°.
	return ProductionIsometricCameraRig3D.PREFERRED_YAW


func opening_camera_focus() -> Vector3:
	# Hall in the lower-middle; crater rim in the upper third.
	# Pull toward the crater, never toward world origin. Origin-pull on a
	# west / -Z hall used to slide the 32 m boom onto the water pad.
	if simulation == null or not simulation.is_town_hall_founded():
		return Vector3.ZERO
	var hall: Vector2i = simulation.town_hall_position
	var center := tile_to_world(Vector2(hall) + Vector2(1.5, 1.5))
	var shard := tile_to_world(Vector2(simulation.shard_position))
	var toward_crater := Vector3(shard.x - center.x, 0.0, shard.z - center.z)
	if toward_crater.length_squared() < 0.01:
		toward_crater = Vector3(0.0, 0.0, -1.0)
	return center + toward_crater.normalized() * 6.0


func opening_view_audit(camera: Camera3D = null) -> Dictionary:
	var hall_tile := Vector2i.ZERO
	if simulation != null and simulation.is_town_hall_founded():
		hall_tile = simulation.town_hall_position
	var hall_chunk := chunk_of_tile(hall_tile)
	var hall_world := tile_to_world(Vector2(hall_tile) + Vector2(1.5, 1.5))
	var near_built := 0
	var near_visible := 0
	var missing: Array[String] = []
	for oy in range(-1, 2):
		for ox in range(-1, 2):
			var coord := hall_chunk + Vector2i(ox, oy)
			if not _chunk_has_tiles(coord):
				continue
			var key := _chunk_key(coord)
			var node: Node = chunk_nodes.get(key, null)
			if node != null and is_instance_valid(node):
				near_built += 1
				if (node as Node3D).visible:
					near_visible += 1
			else:
				missing.append(key)
	var hall_in_view := false
	var cam := camera
	if cam == null:
		cam = fog_overlay_camera
	if cam != null and is_instance_valid(cam):
		hall_in_view = cam.is_position_in_frustum(hall_world)
		var hall_view: Node3D = null
		for view_value in building_views.values():
			var view: Node3D = view_value
			var kind := String(view.building_type)
			if kind == Defs.BUILDING_TOWN_HALL or kind == "CASTLE":
				hall_view = view
				break
		if hall_view != null:
			hall_in_view = hall_in_view or cam.is_position_in_frustum(hall_view.global_position)
	return {
		"hall_tile": hall_tile,
		"hall_chunk": hall_chunk,
		"hall_world": hall_world,
		"near_built": near_built,
		"near_visible": near_visible,
		"missing": missing,
		"hall_in_view": hall_in_view,
		"chunks_built": chunk_nodes.size(),
	}


func _spawn_opening_ridge(host: Node3D, hall: Vector2i) -> void:
	# GFX-R: grassy hillside, rock outcrops, layered ledges, trees at
	# the base. Not a tan sand mound. Cosmetic only.
	var ridge := Node3D.new()
	ridge.name = "DressRidge"
	ridge.set_meta("cosmetic_only", true)
	host.add_child(ridge)
	var grass_a := _ridge_material(Color("#536C3F"), 0.96)
	var grass_b := _ridge_material(Color("#405A36"), 0.96)
	var grass_c := _ridge_material(Color("#344B33"), 0.96)
	var rock_hi := _ridge_material(Color("#6E6A5C"), 0.92)
	var rock_lo := _ridge_material(Color("#4E5348"), 0.92)
	var b := ScaleProfile.TOWN_HALL_WIDTH_METRES
	var r := ScaleProfile.road_width_metres()
	var tiles := _opening_ridge_tiles(hall)
	var index := 0
	for tile in tiles:
		if not simulation.is_inside_map(tile):
			continue
		var slope := MeshInstance3D.new()
		slope.name = "RidgeRock_%d" % index
		var wide := b * (0.22 + float(index % 5) * 0.05)
		wide = clampf(wide, b * 0.18, b * 0.36)
		var tall := b * (0.10 + float(index % 3) * 0.04)
		slope.mesh = _bevelled_ridge_mesh(index, wide, tall)
		var world := tile_to_world(Vector2(tile))
		slope.position = world + Vector3(float(index % 2) * 0.35, 0.0, float((index + 1) % 2) * -0.28)
		slope.rotation.y = float(index) * 0.41
		slope.material_override = grass_a if index % 3 == 0 else (grass_b if index % 3 == 1 else grass_c)
		ridge.add_child(slope)
		var slope_alias := Node3D.new()
		slope_alias.name = "RidgeSlope_%d" % index
		slope.add_child(slope_alias)
		# KayKit rock loads were ~1 s of start_new_3d on the 320 map.
		# Bevelled RidgeRock_ still satisfies the 6–10 rock gate.
		if map_size.x <= 80 and Catalog.ROCKS.size() > 1:
			_spawn_kaykit_ridge_rock(ridge, tile, index, 0.55 + float(index % 4) * 0.10)
		index += 1
	var crater_dir := Vector2(0.0, -1.0)
	if simulation != null and simulation.founding_site is Dictionary:
		crater_dir = Vector2(simulation.founding_site.get("crater_dir", crater_dir))
	if crater_dir.length_squared() < 0.01:
		crater_dir = Vector2(0.0, -1.0)
	crater_dir = crater_dir.normalized()
	var crater_side := Vector2(-crater_dir.y, crater_dir.x)
	var crater_yaw := atan2(crater_dir.x, -crater_dir.y)
	# Beta r23: the crater rim was three huge formation meshes plus box
	# ledges (read as one angular slab, r22 review 6.3). Now an irregular
	# continuous arc of low weathered lumps with slope, rubble and scrub,
	# held back 10-13 tiles toward the crater so it frames the settlement
	# instead of sitting in it. Cosmetic only (no collision, no sim tiles).
	var formation := Node3D.new()
	formation.name = "RidgeFormation"
	ridge.add_child(formation)
	var lump_mesh := SphereMesh.new()
	lump_mesh.radial_segments = 9
	lump_mesh.rings = 5
	lump_mesh.radius = 1.0
	lump_mesh.height = 2.0
	var stone_tones: Array = [
		_ridge_material(Color("#6b675a"), 0.95),
		_ridge_material(Color("#5c5a4f"), 0.95),
		_ridge_material(Color("#76705f"), 0.95),
	]
	var moss_tones: Array = [
		_ridge_material(Color("#45532f"), 0.97),
		_ridge_material(Color("#4d5934"), 0.97),
	]
	var scrub_tones: Array = [
		_ridge_material(Color("#3f5a32"), 0.96),
		_ridge_material(Color("#4c6a36"), 0.96),
	]
	var cell := ScaleProfile.LOGICAL_CELL_METRES
	var seed_i := absi(hall.x * 73856093 ^ hall.y * 19349663)
	var count := 0
	var step := -9.0
	while step <= 9.0:
		var h := float((seed_i + count * 2654435761) % 1000) / 1000.0
		var h2 := float((seed_i / 7 + count * 40503) % 1000) / 1000.0
		var bulge := 12.0 + sin(step * 0.45 + h * 2.0) * 1.4 + (h2 - 0.5) * 1.2 + absf(step) * 0.12
		var tile_f := Vector2(hall) + crater_dir * bulge + crater_side * step
		var tile := Vector2i(roundi(tile_f.x), roundi(tile_f.y))
		step += 0.9 + h * 0.6
		count += 1
		if not simulation.is_inside_map(tile) or _in_founding_yard(tile) or _is_road_tile(tile):
			continue
		if simulation.occupied_tiles.has(_tile_key(tile)):
			continue
		var base := tile_to_world(tile_f)
		# Core lump: wide, low, sunk into the ground.
		var lump := MeshInstance3D.new()
		lump.name = "RimLump_%d" % count
		lump.mesh = lump_mesh
		var wide := cell * (0.85 + h * 0.65)
		var tall := cell * (0.55 + h2 * 0.6)
		lump.scale = Vector3(wide, tall, cell * (0.7 + h2 * 0.5))
		lump.position = base + Vector3(0.0, -tall * 0.35, 0.0)
		lump.rotation.y = crater_yaw + (h - 0.5) * 1.2
		lump.material_override = stone_tones[count % stone_tones.size()]
		formation.add_child(lump)
		# Settlement-side slope: a lower, mossy apron.
		var apron := MeshInstance3D.new()
		apron.name = "RimSlope_%d" % count
		apron.mesh = lump_mesh
		apron.scale = Vector3(wide * 1.25, tall * 0.42, cell * 1.1)
		apron.position = base - Vector3(crater_dir.x, 0.0, crater_dir.y) * cell * 1.1 + Vector3(0.0, -tall * 0.18, 0.0)
		apron.rotation.y = lump.rotation.y
		apron.material_override = moss_tones[count % moss_tones.size()]
		apron.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		formation.add_child(apron)
		# Rubble at the foot and scrub on the crest.
		for k in 2:
			var rub := MeshInstance3D.new()
			rub.mesh = lump_mesh
			var rs := cell * (0.14 + float((count + k) % 4) * 0.05)
			rub.scale = Vector3(rs * 1.3, rs * 0.8, rs)
			rub.position = base - Vector3(crater_dir.x, 0.0, crater_dir.y) * cell * (1.9 + float(k) * 0.5) + Vector3(crater_side.x, 0.0, crater_side.y) * cell * (float(k) - 0.5) * 0.9
			rub.material_override = stone_tones[(count + k + 1) % stone_tones.size()]
			rub.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			formation.add_child(rub)
		if h > 0.35:
			var scrub := MeshInstance3D.new()
			scrub.mesh = lump_mesh
			var ss := cell * (0.30 + h2 * 0.22)
			scrub.scale = Vector3(ss * 1.2, ss * 0.85, ss)
			scrub.position = base + Vector3(crater_side.x, 0.0, crater_side.y) * cell * (h - 0.5) + Vector3(0.0, tall * 0.55, 0.0)
			scrub.material_override = scrub_tones[count % scrub_tones.size()]
			formation.add_child(scrub)
	var trees: Dictionary = {}
	var forest_dir := Vector2(-0.8, -0.4)
	if simulation != null and simulation.founding_site is Dictionary:
		forest_dir = Vector2(simulation.founding_site.get("forest_dir", forest_dir))
	if forest_dir.length_squared() < 0.01:
		forest_dir = Vector2(-0.8, -0.4)
	forest_dir = forest_dir.normalized()
	var forest_side := Vector2(-forest_dir.y, forest_dir.x)
	for tree_i in 7:
		var tree_tile: Vector2i = hall + Vector2i(
			roundi(forest_dir.x * (6.0 + float(tree_i % 3)) + forest_side.x * float(tree_i - 3) * 0.8),
			roundi(forest_dir.y * (6.0 + float(tree_i % 3)) + forest_side.y * float(tree_i - 3) * 0.8)
		)
		if _in_founding_yard(tree_tile) or _opening_faces_crater(tree_tile, hall):
			continue
		if simulation.is_inside_map(tree_tile):
			_append_nature_transform(trees, _tree_path_for_tile(tree_tile, 0, 3), tree_tile, tree_i, 0.70, 1.00, 0.38)
	if not trees.is_empty():
		_spawn_nature_multimeshes(ridge, trees)
	_spawn_meandering_creek(ridge, hall, r)
	_spawn_founding_crater_traces(ridge, hall)


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
	var tint := Color("#6E6A5C") if index % 3 != 0 else Color("#8A8270")
	if index % 3 == 2:
		tint = Color("#4E5348")
	for child in prop.find_children("*", "MeshInstance3D", true, false):
		var mesh_i := child as MeshInstance3D
		var mat := StandardMaterial3D.new()
		mat.albedo_color = tint
		mat.roughness = 0.92
		mat.metallic = 0.0
		mesh_i.material_override = mat
	ridge.add_child(prop)


func _spawn_founding_crater_traces(ridge: Node3D, hall: Vector2i) -> void:
	# Small embedded fragments and cracked earth toward the pit.
	# No glowing columns and no oval pads — those read as VFX, not impact.
	if simulation == null or not (simulation.founding_site is Dictionary):
		return
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.40, 0.54, 0.58, 0.88)
	glass.emission_enabled = true
	glass.emission = Color("#2a5460")
	glass.emission_energy_multiplier = 0.26
	glass.roughness = 0.38
	glass.metallic = 0.16
	var cracked := _ridge_material(Color("#3A3834"), 0.94)
	var crater_dir := Vector2(simulation.founding_site.get("crater_dir", Vector2(0.0, -1.0)))
	if crater_dir.length_squared() < 0.01:
		crater_dir = Vector2(0.0, -1.0)
	var index := 0
	for tile_value in simulation.founding_site.get("wyrd_tiles", []):
		var tile := Vector2i(tile_value)
		if not simulation.is_inside_map(tile):
			continue
		var origin := tile_to_world(Vector2(tile))
		var shard := MeshInstance3D.new()
		shard.name = "DressWyrdTrace_%d" % index
		var prism := PrismMesh.new()
		prism.size = Vector3(0.42 + float(index % 3) * 0.10, 0.85 + float(index) * 0.12, 0.34)
		shard.mesh = prism
		shard.position = origin + Vector3(0.0, 0.18, 0.0)
		shard.rotation_degrees = Vector3(22.0, float(index) * 31.0, 98.0)
		shard.material_override = glass
		ridge.add_child(shard)
		var spoil := MeshInstance3D.new()
		spoil.name = "DressWyrdTrail_%d" % index
		var box := BoxMesh.new()
		box.size = Vector3(1.15, 0.16, 0.72)
		spoil.mesh = box
		spoil.position = origin + Vector3(0.12, 0.04, -0.08)
		spoil.rotation.y = atan2(crater_dir.x, crater_dir.y) + float(index) * 0.28
		spoil.material_override = cracked
		spoil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ridge.add_child(spoil)
		index += 1
	ridge.set_meta("wyrd_traces", index)


func _spawn_meandering_creek(ridge: Node3D, hall: Vector2i, road_w: float) -> void:
	# Seeded creek from the founding site. Falls back to a west ribbon.
	var tiles: Array[Vector2i] = []
	if simulation != null and simulation.founding_site is Dictionary:
		for tile_value in simulation.founding_site.get("creek_tiles", []):
			tiles.append(Vector2i(tile_value))
	if tiles.size() < 5:
		tiles = [
			hall + Vector2i(-7, -2),
			hall + Vector2i(-6, 1),
			hall + Vector2i(-6, 4),
			hall + Vector2i(-5, 7),
			hall + Vector2i(-6, 10),
			hall + Vector2i(-8, 13),
			hall + Vector2i(-9, 16),
		]
	var points: Array[Vector3] = []
	for tile in tiles:
		if simulation != null and simulation.is_inside_map(tile):
			points.append(tile_to_world(Vector2(tile)) + Vector3(0.0, 0.04, 0.0))
	if points.size() < 5:
		return
	var water_type := "river"
	if simulation != null and simulation.founding_site is Dictionary:
		water_type = String(simulation.founding_site.get("water_type", "river"))
	var width_mul := 1.18
	if water_type == "lake":
		width_mul = 2.25
	elif water_type == "pond":
		width_mul = 1.55
	var width := clampf(road_w * width_mul, road_w * 1.00, road_w * 2.40)
	if water_type == "pond" or water_type == "lake":
		var mid := points[int(points.size() / 2)]
		_spawn_dress_pond(ridge, simulation.town_hall_position if simulation != null else Vector2i.ZERO, Vector2(6.8 if water_type == "lake" else 4.2, 4.8 if water_type == "lake" else 3.1), "DressPond")
		var pond: MeshInstance3D = ridge.get_node_or_null("DressPond")
		if pond != null:
			pond.position = mid + Vector3(0.0, 0.02, 0.0)
	# Beta r23: the creek read as bright turquoise patches. Muted peat
	# water, mossy-mud banks that fade into the meadow.
	var bank := _ridge_material(Color("#5f5a42"), 0.94)
	var wet := _ridge_material(Color("#37443a"), 0.6)
	var shallow := _ridge_material(Color("#3e5c55"), 0.35)
	var water := StandardMaterial3D.new()
	water.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	water.albedo_color = Color("#284a4a")
	water.roughness = 0.22
	water.metallic = 0.08
	water.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	var mud := MeshInstance3D.new()
	mud.name = "DressCreekBank"
	mud.mesh = _creek_ribbon_mesh(points, width + road_w * 0.52, road_w)
	mud.material_override = bank
	mud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ridge.add_child(mud)
	var wet_edge := MeshInstance3D.new()
	wet_edge.name = "DressCreekShore"
	wet_edge.mesh = _creek_ribbon_mesh(points, width + road_w * 0.22, road_w)
	wet_edge.position.y = 0.008
	wet_edge.material_override = wet
	wet_edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ridge.add_child(wet_edge)
	var shallows := MeshInstance3D.new()
	shallows.name = "DressCreekShallow"
	shallows.mesh = _creek_ribbon_mesh(points, width * 1.18, road_w)
	shallows.position.y = 0.014
	shallows.material_override = shallow
	shallows.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ridge.add_child(shallows)
	var creek := MeshInstance3D.new()
	creek.name = "DressCreek"
	creek.mesh = _creek_ribbon_mesh(points, width, road_w)
	creek.position.y = 0.024
	creek.material_override = water
	creek.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ridge.add_child(creek)
	_dress_creek_shoreline(ridge, points)
	_spawn_founding_bridges(ridge, width)


func _spawn_founding_bridges(ridge: Node3D, width: float) -> void:
	if simulation == null or not (simulation.founding_site is Dictionary):
		return
	var wood := _ridge_material(Color("#6B4E32"), 0.86)
	var rail := _ridge_material(Color("#4A3826"), 0.90)
	var index := 0
	for tile_value in simulation.founding_site.get("bridge_tiles", []):
		var tile := Vector2i(tile_value)
		if simulation.has_method("is_founding_creek_tile") and not bool(simulation.is_founding_creek_tile(tile)):
			continue
		var deck := MeshInstance3D.new()
		deck.name = "DressBridge_%d" % index
		var deck_mesh := BoxMesh.new()
		deck_mesh.size = Vector3(maxf(width + 0.70, 3.1), 0.16, maxf(width * 0.42, 1.25))
		deck.mesh = deck_mesh
		deck.position = tile_to_world(Vector2(tile)) + Vector3(0.0, 0.14, 0.0)
		deck.material_override = wood
		ridge.add_child(deck)
		for side in [-1.0, 1.0]:
			var post := MeshInstance3D.new()
			post.name = "DressBridgeRail_%d_%d" % [index, int(side)]
			var post_mesh := BoxMesh.new()
			post_mesh.size = Vector3(0.10, 0.52, maxf(width * 0.38, 1.15))
			post.mesh = post_mesh
			post.position = deck.position + Vector3(side * (width * 0.42 + 0.22), 0.30, 0.0)
			post.material_override = rail
			ridge.add_child(post)
		index += 1


func _dress_creek_shoreline(ridge: Node3D, points: Array[Vector3]) -> void:
	# Irregular stones and reeds so the channel reads as a shoreline.
	var stone := _ridge_material(Color("#6E6A5C"), 0.94)
	var reed := _ridge_material(Color("#4A6A3C"), 0.88)
	for i in points.size():
		var p: Vector3 = points[i]
		var side := 1.0 if i % 2 == 0 else -1.0
		var rock := MeshInstance3D.new()
		rock.name = "CreekStone_%d" % i
		var mesh := SphereMesh.new()
		mesh.radius = 0.22 + float(i % 3) * 0.06
		mesh.height = mesh.radius * 1.35
		rock.mesh = mesh
		rock.position = p + Vector3(side * (0.85 + float(i % 3) * 0.18), 0.08, float((i * 3) % 5) * 0.08)
		rock.scale = Vector3(1.15, 0.62, 0.90)
		rock.material_override = stone
		ridge.add_child(rock)
		if i % 2 == 0:
			var blade := MeshInstance3D.new()
			blade.name = "CreekReed_%d" % i
			var reed_mesh := BoxMesh.new()
			reed_mesh.size = Vector3(0.06, 0.55 + float(i % 3) * 0.12, 0.06)
			blade.mesh = reed_mesh
			blade.position = p + Vector3(-side * 0.72, 0.28, 0.10)
			blade.material_override = reed
			ridge.add_child(blade)


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
	return tool.commit()


func _ridge_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = 0.0
	return material


func _impact_bowl_mesh(radius: float, depth: float) -> ArrayMesh:
	# Jagged excavation, not a disc. Rim stays at grade; the floor sinks.
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := 13
	var rim: Array[Vector3] = []
	var mid: Array[Vector3] = []
	for i in count:
		var ang := TAU * float(i) / float(count)
		var jag := 0.72 + float((i * 5) % 7) * 0.055
		var rx := radius * jag
		var rz := radius * jag * 0.84
		rim.append(Vector3(cos(ang) * rx, 0.04, sin(ang) * rz))
		mid.append(Vector3(cos(ang) * rx * 0.52, -depth * 0.42, sin(ang) * rz * 0.52))
	var floor := Vector3(0.10, -depth, -0.06)
	for i in count:
		var n := (i + 1) % count
		_ridge_tri(tool, rim[i], rim[n], mid[n])
		_ridge_tri(tool, rim[i], mid[n], mid[i])
		_ridge_tri(tool, mid[i], mid[n], floor)
	tool.generate_normals()
	return tool.commit()


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


func _spawn_dress_coast(host: Node3D, hall: Vector2i) -> void:
	# Sit the coast plane on the seeded water so it does not read as a
	# floating green slab on the meadow.
	var coast_dir := Vector2(-1.0, 0.15)
	if simulation != null and simulation.founding_site is Dictionary:
		coast_dir = Vector2(simulation.founding_site.get("coast_dir", coast_dir))
	if coast_dir.length_squared() < 0.01:
		coast_dir = Vector2(-1.0, 0.15)
	coast_dir = coast_dir.normalized()
	var anchor := hall + Vector2i(roundi(coast_dir.x * 7.0), roundi(coast_dir.y * 6.0))
	if simulation != null and simulation.founding_site is Dictionary:
		var creek: Array = simulation.founding_site.get("creek_tiles", [])
		if not creek.is_empty():
			anchor = Vector2i(creek[int(creek.size() / 2)])
	var edge := MeshInstance3D.new()
	edge.name = "DressCoastEdge"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(1.8, 2.2)
	edge.mesh = mesh
	edge.position = tile_to_world(Vector2(anchor)) + Vector3(0.0, 0.02, 0.0)
	edge.rotation.y = atan2(coast_dir.x, coast_dir.y)
	var water := StandardMaterial3D.new()
	water.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	water.albedo_color = Color("#345F65")
	water.roughness = 0.35
	water.metallic = 0.0
	edge.material_override = water
	edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	host.add_child(edge)
	var bank := MeshInstance3D.new()
	bank.name = "DressCoastBank"
	var bank_mesh := BoxMesh.new()
	bank_mesh.size = Vector3(3.2, 0.12, 0.42)
	bank.mesh = bank_mesh
	bank.position = edge.position + Vector3(-coast_dir.x * 0.9, 0.02, -coast_dir.y * 0.9)
	bank.rotation.y = atan2(coast_dir.x, coast_dir.y)
	var mud := StandardMaterial3D.new()
	mud.albedo_color = Color("#786C50")
	mud.roughness = 0.92
	bank.material_override = mud
	bank.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	host.add_child(bank)
	host.set_meta("hamlet_coast", 1)


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


## Hotfix 6: chunks share one foliage material per (path, mesh,
## atmosphere) instead of a fresh ShaderMaterial per MultiMesh per rebake.
## Same inputs -> same parameters, so the look is identical.
var _foliage_material_cache: Dictionary = {}


func _shared_foliage_material(mesh: Mesh, path_value: String) -> Material:
	var key := "%s|%d|%s" % [path_value, mesh.get_instance_id() if mesh != null else 0, var_to_str(_atmosphere_scale)]
	if _foliage_material_cache.has(key):
		return _foliage_material_cache[key]
	if _foliage_material_cache.size() > 256:
		_foliage_material_cache.clear()
	var material := _foliage_material(mesh, path_value)
	_foliage_material_cache[key] = material
	return material


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
	material.albedo_color = Color("#3B5A33") * _atmosphere_scale
	material.roughness = 0.94
	material.metallic = 0.0
	material.emission_enabled = false
	return material


func _rebuild_building_halos(force: bool) -> void:
	if simulation == null or halo_root == null:
		return
	var signature := "r%d" % int(simulation.connected_roads.size())
	for building_value in simulation.buildings:
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


var _map_marker_sig := -1


func _sync_map_markers() -> void:
	var host := get_node_or_null("MapMarkers")
	if host == null:
		host = Node3D.new()
		host.name = "MapMarkers"
		add_child(host)
	# Beta: markers were freed and rebuilt (Label3D + meshes) on every sim
	# tick; rebuild only when the marker list actually changed.
	var markers: Array = simulation.get_map_markers() if simulation != null and simulation.has_method("get_map_markers") else []
	var marker_sig := hash(var_to_str(markers))
	if marker_sig == _map_marker_sig and host.get_child_count() == markers.size():
		return
	_map_marker_sig = marker_sig
	for child in host.get_children():
		child.queue_free()
	for marker_value in markers:
		var marker: Dictionary = marker_value
		var tile: Vector2i = marker.get("position", Vector2i.ZERO)
		var kind := String(marker.get("kind", ""))
		var title := String(marker.get("title", "?"))
		var world := tile_to_world(Vector2(tile))
		var root := Node3D.new()
		root.position = world
		host.add_child(root)
		var label := Label3D.new()
		label.text = title
		label.font_size = 54 if kind in ["rival_threat", "seal_choice", "caravan", "victory_banner"] else 42
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.outline_size = 10
		label.outline_modulate = Color(0.05, 0.03, 0.02, 1.0)
		label.position = Vector3.UP * (5.4 if kind == "rival_banner" else 3.6)
		if kind == "raid":
			label.modulate = Color("#f05a4a")
		elif kind in ["rival", "rival_banner", "rival_threat"]:
			label.modulate = Color("#d46a3a")
		elif kind == "rival_route":
			label.modulate = Color("#f0a06e")
		elif kind == "rival_smoke":
			label.modulate = Color("#9a8a7a")
		elif kind == "seal_choice":
			label.modulate = Color("#7ec8d4")
		elif kind in ["caravan", "caravan_camp"]:
			label.modulate = Color("#efcf8a")
		elif kind in ["tent", "refugee"]:
			label.modulate = Color("#efcf8a")
		elif kind == "channel":
			label.modulate = Color("#7ee0d4")
		elif kind == "palisade":
			label.modulate = Color("#d4782a")
		elif kind == "victory_banner":
			label.modulate = Color("#f0c44a")
		elif kind == "skull":
			label.modulate = Color("#f0a06e")
		else:
			label.modulate = Color("#efcf8a")
		root.add_child(label)
		if kind == "rival_banner":
			root.add_child(_banner_mesh(Color("#c84a4a")))
		elif kind == "rival_route":
			root.add_child(_ping_mesh(Color("#f0a06e")))
		elif kind == "rival_smoke":
			root.add_child(_smoke_mesh())
		elif kind == "rival_threat":
			root.add_child(_ping_mesh(Color("#f05a4a"), 0.55))
		elif kind == "seal_choice":
			root.add_child(_ping_mesh(Color("#7ec8d4"), 0.42))
		elif kind == "caravan":
			root.add_child(_caravan_mesh())
		elif kind in ["tent", "caravan_camp"]:
			root.add_child(_tent_mesh())
		elif kind == "refugee":
			root.add_child(_settler_mesh())
		elif kind == "channel":
			root.add_child(_channel_flash_mesh())
		elif kind == "palisade":
			root.add_child(_palisade_mesh())
		elif kind == "victory_banner":
			root.add_child(_banner_mesh(Color("#f0c44a")))


func _banner_mesh(color: Color) -> Node3D:
	var group := Node3D.new()
	var pole := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.09
	cyl.bottom_radius = 0.12
	cyl.height = 6.4
	pole.mesh = cyl
	pole.position = Vector3.UP * 3.2
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color("#3a2a22")
	pole.material_override = pole_mat
	group.add_child(pole)
	var flag := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2.4, 1.35, 0.08)
	flag.mesh = box
	flag.position = Vector3(1.15, 5.4, 0.0)
	var flag_mat := StandardMaterial3D.new()
	flag_mat.albedo_color = color
	flag_mat.emission_enabled = true
	flag_mat.emission = color
	flag_mat.emission_energy_multiplier = 1.1
	flag.material_override = flag_mat
	group.add_child(flag)
	return group


func _ping_mesh(color: Color, radius: float = 0.85) -> MeshInstance3D:
	var ping := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	ping.mesh = sphere
	ping.position = Vector3.UP * 0.9
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color, 0.78)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.4
	ping.material_override = mat
	return ping


func _smoke_mesh() -> MeshInstance3D:
	var puff := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 2.1
	sphere.height = 4.4
	puff.mesh = sphere
	puff.position = Vector3.UP * 2.4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.32, 0.3, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color("#6a5a4a")
	mat.emission_energy_multiplier = 0.45
	puff.material_override = mat
	return puff


func _caravan_mesh() -> Node3D:
	var group := Node3D.new()
	var wagon := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2.6, 1.1, 1.4)
	wagon.mesh = box
	wagon.position = Vector3(0.0, 0.85, 0.0)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("#7a4a28")
	wood.emission_enabled = true
	wood.emission = Color("#c48a4a")
	wood.emission_energy_multiplier = 0.55
	wagon.material_override = wood
	group.add_child(wagon)
	var canvas := MeshInstance3D.new()
	var cloth := BoxMesh.new()
	cloth.size = Vector3(2.1, 0.85, 1.15)
	canvas.mesh = cloth
	canvas.position = Vector3(0.0, 1.7, 0.0)
	var cloth_mat := StandardMaterial3D.new()
	cloth_mat.albedo_color = Color("#d8c48a")
	cloth_mat.emission_enabled = true
	cloth_mat.emission = Color("#efcf8a")
	cloth_mat.emission_energy_multiplier = 0.7
	canvas.material_override = cloth_mat
	group.add_child(canvas)
	return group


func _palisade_mesh() -> Node3D:
	var group := Node3D.new()
	for index in range(3):
		var post := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.32, 2.2, 0.28)
		post.mesh = box
		post.position = Vector3(float(index - 1) * 0.55, 1.1, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("#6a3e22")
		mat.emission_enabled = true
		mat.emission = Color("#d4782a")
		mat.emission_energy_multiplier = 0.8
		post.material_override = mat
		group.add_child(post)
	return group


func _tent_mesh() -> Node3D:
	var group := Node3D.new()
	var cloth := StandardMaterial3D.new()
	# Beta r23: the self-lit cream canvas was the brightest thing at night.
	# Weathered canvas, lit only by the scene (moonlight / campfire).
	cloth.albedo_color = Color("#9c8a68")
	cloth.roughness = 0.95
	var canvas := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(2.4, 1.6, 2.1)
	canvas.mesh = prism
	canvas.position = Vector3(0.0, 0.85, 0.0)
	canvas.material_override = cloth
	group.add_child(canvas)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("#5a3a22")
	for pole_off in [Vector3(-0.85, 0.7, -0.7), Vector3(0.85, 0.7, -0.7), Vector3(0.0, 0.95, 0.15)]:
		var pole := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.05
		cyl.bottom_radius = 0.07
		cyl.height = 1.55 if pole_off.y < 0.9 else 1.9
		pole.mesh = cyl
		pole.position = pole_off
		pole.material_override = wood
		group.add_child(pole)
	for flap_x in [-1.15, 1.15]:
		var flap := MeshInstance3D.new()
		var flap_mesh := BoxMesh.new()
		flap_mesh.size = Vector3(0.08, 1.05, 1.15)
		flap.mesh = flap_mesh
		flap.position = Vector3(flap_x, 0.62, 0.15)
		flap.rotation.z = 0.22 if flap_x < 0.0 else -0.22
		flap.material_override = cloth
		group.add_child(flap)
	group.add_child(_campfire_mesh(Vector3(1.55, 0.0, 1.15)))
	return group


func _campfire_mesh(offset: Vector3) -> Node3D:
	var fire := Node3D.new()
	fire.position = offset
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.18
	torus.outer_radius = 0.42
	ring.mesh = torus
	ring.position = Vector3(0.0, 0.08, 0.0)
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("#4a4036")
	ring.material_override = stone
	fire.add_child(ring)
	var flame := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.02
	cone.bottom_radius = 0.16
	cone.height = 0.55
	flame.mesh = cone
	flame.position = Vector3(0.0, 0.32, 0.0)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(1.0, 0.45, 0.12, 0.9)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.55, 0.15)
	glow.emission_energy_multiplier = 3.2
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flame.material_override = glow
	fire.add_child(flame)
	var light := OmniLight3D.new()
	light.light_color = Color("#ff8a3a")
	light.light_energy = 1.4
	light.omni_range = 4.5
	light.position = Vector3(0.0, 0.55, 0.0)
	fire.add_child(light)
	return fire


func _settler_mesh() -> Node3D:
	var group := Node3D.new()
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.28
	capsule.height = 1.35
	body.mesh = capsule
	body.position = Vector3(0.0, 0.72, 0.0)
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = Color("#8a6a3a")
	cloth.emission_enabled = true
	cloth.emission = Color("#d4a85a")
	cloth.emission_energy_multiplier = 0.4
	body.material_override = cloth
	group.add_child(body)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	head.mesh = sphere
	head.position = Vector3(0.0, 1.55, 0.0)
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color("#d8b48a")
	head.material_override = skin
	group.add_child(head)
	return group


func _channel_flash_mesh() -> Node3D:
	var group := Node3D.new()
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.55
	torus.outer_radius = 1.15
	ring.mesh = torus
	ring.position = Vector3(0.0, 0.45, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.95, 0.85, 0.65)
	mat.emission_enabled = true
	mat.emission = Color(0.55, 1.0, 0.88)
	mat.emission_energy_multiplier = 2.6
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = mat
	group.add_child(ring)
	return group



## Hotfix 6: compile every building pipeline (finished + construction
## variants, colour + shadow pass) while the title menu is up, so the first
## House is not a cold-cache 3 s hitch. Instances sit just past the near
## plane at sub-pixel scale for a few frames, then are freed.
var _warmup_root: Node3D
var _warmup_frames := 0


func warm_up_pipelines(camera: Camera3D) -> void:
	if camera == null or _warmup_root != null:
		return
	_warmup_root = Node3D.new()
	_warmup_root.name = "PipelineWarmup"
	add_child(_warmup_root)
	var index := 0
	for type_value in WarmupCatalog.BUILDINGS.keys():
		for construction in [false, true]:
			var view := BuildingView.new()
			view.configure({"id": -90000 - index, "type": String(type_value), "construction": construction, "construction_fraction": 0.5, "rotation": 0, "faction": "player"})
			_warmup_root.add_child(view)
			index += 1
	_warmup_root.global_transform = camera.global_transform.translated_local(Vector3(0.0, 0.0, -maxf(camera.near, 0.05) * 3.0))
	_warmup_root.scale = Vector3.ONE * 0.001
	_warmup_frames = 6



## Hotfix 6: same disks as _paint_current_vision(), but only the tiles the
## fog mask samples (multiples of FOG_MASK_DIVISOR) are written, as bytes.
func _paint_current_vision_mask(mask_size: Vector2i) -> PackedByteArray:
	var mask := PackedByteArray()
	mask.resize(mask_size.x * mask_size.y)
	if simulation == null:
		return mask
	if simulation.is_town_hall_founded():
		var hall_fp := Defs.building_footprint(Defs.BUILDING_TOWN_HALL)
		var hall_center: Vector2i = simulation._footprint_center(simulation.town_hall_position, hall_fp)
		_paint_vision_disk_mask(mask, mask_size, hall_center, simulation.building_vision_radius(Defs.BUILDING_TOWN_HALL))
	for building_value in simulation.buildings:
		var building: Dictionary = building_value
		if bool(building.get("construction", false)):
			continue
		var building_type := String(building.get("type", ""))
		if building_type == Defs.BUILDING_TOWN_HALL:
			continue
		var center: Vector2i = building.get("position", Vector2i.ZERO)
		if building_type != Defs.BUILDING_ROAD:
			center = simulation._footprint_center(center, _building_footprint_for_visual(building, building_type))
		_paint_vision_disk_mask(mask, mask_size, center, simulation.building_vision_radius(building_type))
	for worker_value in simulation.workers:
		var worker: Dictionary = worker_value
		if int(worker.get("hp", 1)) <= 0:
			continue
		var tile: Vector2i = simulation._unit_tile(worker)
		_paint_vision_disk_mask(mask, mask_size, tile, simulation.unit_vision_radius(String(worker.get("type", ""))))
	return mask


func _paint_vision_disk_mask(mask: PackedByteArray, mask_size: Vector2i, center: Vector2i, radius: int) -> void:
	if radius <= 0:
		return
	var y0 := maxi(0, center.y - radius)
	var y1 := mini(map_size.y - 1, center.y + radius)
	var start_y := ((y0 + FOG_MASK_DIVISOR - 1) / FOG_MASK_DIVISOR) * FOG_MASK_DIVISOR
	for y in range(start_y, y1 + 1, FOG_MASK_DIVISOR):
		var span := radius - absi(y - center.y)
		var x0 := maxi(0, center.x - span)
		var x1 := mini(map_size.x - 1, center.x + span)
		var start_x := ((x0 + FOG_MASK_DIVISOR - 1) / FOG_MASK_DIVISOR) * FOG_MASK_DIVISOR
		var row := (y / FOG_MASK_DIVISOR) * mask_size.x
		for x in range(start_x, x1 + 1, FOG_MASK_DIVISOR):
			mask[row + x / FOG_MASK_DIVISOR] = 1
