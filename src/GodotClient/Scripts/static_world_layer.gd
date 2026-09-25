extends Node2D

const Defs = preload("one_shard_defs.gd")
const RivalryTuning = preload("one_shard_rivalry_tuning.gd")
const TREE_TEXTURE: Texture2D = preload("res://assets/settlement/tree_painterly.png")
const ROCK_A_TEXTURE: Texture2D = preload("res://assets/settlement/rock_a.png")
const ROCK_B_TEXTURE: Texture2D = preload("res://assets/settlement/rock_b.png")
const SHARD_TEXTURE: Texture2D = preload("res://assets/settlement/threats/shard.png")

const TILE_WIDTH := 48.0
const TILE_HEIGHT := 24.0
const HEIGHT_STEP := 8.0

var view


func _draw() -> void:
	if view == null or view.simulation == null:
		return
	_draw_map_background()
	_draw_tiles()
	_draw_roads()
	_draw_rivalry_territory()


func _draw_map_background() -> void:
	var bounds: Rect2 = view._map_bounds()
	draw_rect(bounds.grow(maxf(TILE_WIDTH, TILE_HEIGHT) * 2.2), Color(0.025, 0.060, 0.046, 1.0), true)


func _draw_tiles() -> void:
	for y in range(view.simulation.map_size.y):
		for x in range(view.simulation.map_size.x):
			var tile := Vector2i(x, y)
			var center: Vector2 = view.tile_to_world(tile)
			if not view._is_world_visible(center, 140.0):
				continue
			var revealed: bool = view.simulation.is_revealed(tile)
			# Unscouted ground is represented by the contiguous dark-green map
			# backing. Avoiding thousands of individual fog diamonds preserves
			# the full-landmass silhouette and substantially cuts draw calls.
			if not revealed:
				continue
			var top_color: Color = view._terrain_color(tile, true)
			_draw_terrain_cliffs(tile, top_color)
			var polygon := _tile_polygon(tile)
			draw_colored_polygon(polygon, top_color)
			_draw_polygon_outline(polygon, Color(0.02, 0.06, 0.025, 0.25), 0.65)
			_draw_ground_details(tile, center)
			_draw_terrain_feature(tile)


func _draw_terrain_cliffs(tile: Vector2i, top_color: Color) -> void:
	var simulation = view.simulation
	var polygon := _tile_polygon(tile)
	var current_height: int = simulation.get_height(tile)
	var east := tile + Vector2i.RIGHT
	var south := tile + Vector2i.DOWN
	var east_height: int = simulation.get_height(east) if simulation.is_inside_map(east) else 0
	var south_height: int = simulation.get_height(south) if simulation.is_inside_map(south) else 0
	if current_height > east_height:
		var down := Vector2(0, float(current_height - east_height) * HEIGHT_STEP)
		var east_face := PackedVector2Array([polygon[1], polygon[2], polygon[2] + down, polygon[1] + down])
		draw_colored_polygon(east_face, top_color.darkened(0.34))
		_draw_polygon_outline(east_face, Color(0.03, 0.04, 0.025, 0.42), 0.8)
	if current_height > south_height:
		var down := Vector2(0, float(current_height - south_height) * HEIGHT_STEP)
		var south_face := PackedVector2Array([polygon[2], polygon[3], polygon[3] + down, polygon[2] + down])
		draw_colored_polygon(south_face, top_color.darkened(0.23))
		_draw_polygon_outline(south_face, Color(0.03, 0.04, 0.025, 0.40), 0.8)


func _draw_ground_details(tile: Vector2i, center: Vector2) -> void:
	var simulation = view.simulation
	if simulation.get_tile(tile) != Defs.TILE_GRASS or simulation.is_tile_occupied(tile):
		return
	var pattern := absi(tile.x * 37 + tile.y * 61 + tile.x * tile.y * 7)
	if pattern % 5 == 0:
		var tuft := center + Vector2(float((pattern % 17) - 8), float((pattern % 9) - 4))
		draw_line(tuft, tuft + Vector2(-2, -4), Color(0.24, 0.42, 0.2, 0.72), 1.0)
		draw_line(tuft, tuft + Vector2(2, -3), Color(0.34, 0.52, 0.24, 0.72), 1.0)
	if pattern % 23 == 0:
		var flower := center + Vector2(float((pattern % 13) - 6), float((pattern % 7) - 3))
		draw_circle(flower, 1.2, Color(0.92, 0.78, 0.38, 0.82))


func _draw_terrain_feature(tile: Vector2i) -> void:
	var simulation = view.simulation
	var terrain: String = simulation.get_tile(tile)
	var center: Vector2 = view.tile_to_object_base(tile)
	if terrain == Defs.TILE_TREE:
		var variant := absi(tile.x * 19 + tile.y * 31) % 7
		var size := Vector2(66, 78)
		if variant in [0, 4]:
			size *= 1.12
		elif variant in [2, 6]:
			size *= 0.88
		var tint := Color(0.82, 0.96, 0.78, 1.0) if variant % 3 == 0 else Color.WHITE
		draw_texture_rect(TREE_TEXTURE, Rect2(center - Vector2(size.x * 0.5, size.y), size), false, tint)
	elif terrain == Defs.TILE_ROCK:
		var texture := ROCK_A_TEXTURE if absi(tile.x + tile.y) % 2 == 0 else ROCK_B_TEXTURE
		draw_texture(texture, center - Vector2(texture.get_width() * 0.5, texture.get_height()))
	elif terrain == Defs.TILE_SHARD:
		draw_circle(center + Vector2(0, -42), 48, Color(0.18, 0.58, 1.0, 0.12))
		draw_arc(center, RivalryTuning.SHARD_CLAIM_RADIUS * TILE_WIDTH * 0.52, 0.0, TAU, 48, Color(0.32, 0.78, 1.0, 0.32), 2.0)
		draw_texture(SHARD_TEXTURE, center - Vector2(SHARD_TEXTURE.get_width() * 0.5, SHARD_TEXTURE.get_height() - 7.0))


func _draw_roads() -> void:
	var simulation = view.simulation
	for building in simulation.get_buildings():
		if String(building.get("type", "")) != Defs.BUILDING_ROAD:
			continue
		var tile: Vector2i = building["position"]
		if not simulation.is_revealed(tile) or not view._is_world_visible(view.tile_to_world(tile), 120.0):
			continue
		_draw_road(tile, bool(building.get("connected", false)))


func _draw_road(tile: Vector2i, connected: bool) -> void:
	var simulation = view.simulation
	var center: Vector2 = view.tile_to_world(tile)
	var base_color: Color = Color(0.76, 0.61, 0.34, 1.0) if connected else Color(0.40, 0.34, 0.24, 1.0)
	var light_color := Color(0.86, 0.72, 0.43, 0.82)
	var rut_color := Color(0.48, 0.36, 0.22, 0.34)
	var road_neighbor_count := 0
	for neighbor in view._road_visual_neighbor_tiles(tile):
		var neighbor_building: Dictionary = simulation.get_building_at_tile(neighbor)
		var neighbor_is_road := not neighbor_building.is_empty() and String(neighbor_building.get("type", "")) == Defs.BUILDING_ROAD
		if not neighbor_is_road:
			continue
		road_neighbor_count += 1
		if tile.x > neighbor.x or (tile.x == neighbor.x and tile.y > neighbor.y):
			continue
		var finish: Vector2 = view.tile_to_world(neighbor)
		var direction := (finish - center).normalized()
		var normal := Vector2(-direction.y, direction.x)
		var midpoint := center.lerp(finish, 0.5) + normal * (-1.4 if absi(tile.x * 41 + tile.y * 67) % 2 == 0 else 1.4)
		var points := PackedVector2Array([center, midpoint, finish])
		draw_polyline(points, base_color, 18.0, true)
		draw_polyline(points, light_color, 13.5, true)
		var rut_offset := normal * 3.1
		draw_polyline(PackedVector2Array([center + rut_offset, midpoint + rut_offset, finish + rut_offset]), rut_color, 1.0, true)
		draw_polyline(PackedVector2Array([center - rut_offset, midpoint - rut_offset, finish - rut_offset]), rut_color, 1.0, true)
	if road_neighbor_count >= 3:
		draw_circle(center, 11.0, base_color)
		draw_circle(center, 8.0, light_color)
	if simulation.is_gate_tile(tile):
		_draw_gate(tile, simulation.is_gate_closed())


func _draw_gate(tile: Vector2i, closed: bool) -> void:
	var base: Vector2 = view.tile_to_object_base(tile)
	var timber := Color(0.30, 0.17, 0.075, 1)
	var iron := Color(0.13, 0.12, 0.10, 1)
	draw_line(base + Vector2(-15, -3), base + Vector2(-15, -35), timber, 7.0)
	draw_line(base + Vector2(15, -3), base + Vector2(15, -35), timber, 7.0)
	draw_line(base + Vector2(-18, -35), base + Vector2(18, -35), timber, 8.0)
	if closed:
		for offset in [-10.0, -5.0, 0.0, 5.0, 10.0]:
			draw_line(base + Vector2(offset, -4), base + Vector2(offset, -31), iron, 2.4)
	else:
		draw_line(base + Vector2(-14, -4), base + Vector2(-14, -29), iron, 3.0)
		draw_line(base + Vector2(14, -4), base + Vector2(14, -29), iron, 3.0)


func _draw_rivalry_territory() -> void:
	var simulation = view.simulation
	if simulation.rivalry == null:
		return
	for realm_id in [RivalryTuning.PLAYER_REALM, RivalryTuning.AI_REALM]:
		var selected: Dictionary = view.simulation.get_building_by_id(view.selected_building_id)
		var show_precise: bool = view.current_mode == Defs.BUILDING_LUMEN_PILLAR or String(selected.get("type", "")) == Defs.BUILDING_LUMEN_PILLAR or view.rivalry_debug_visible
		if not show_precise:
			continue
		var realm_color := Color(0.24, 0.62, 1.0, 0.040) if realm_id == RivalryTuning.PLAYER_REALM else Color(0.95, 0.26, 0.18, 0.040)
		for source in simulation.rivalry.get_lumen_sources(realm_id):
			if realm_id == RivalryTuning.PLAYER_REALM and bool(source.get("home", false)):
				continue
			var source_center: Vector2 = source.get("center", Vector2.ZERO)
			var source_tile := Vector2i(roundi(source_center.x), roundi(source_center.y))
			if realm_id == RivalryTuning.AI_REALM and not simulation.is_revealed(source_tile):
				continue
			var world_center: Vector2 = view.tile_position_to_world(source_center, source_tile)
			var radius := float(source.get("radius", 0.0)) * TILE_WIDTH * 0.52
			draw_circle(world_center, radius, realm_color)
			draw_arc(world_center, radius, 0.0, TAU, 48, Color(realm_color.r, realm_color.g, realm_color.b, 0.17), 1.3)
	for tile in simulation.rivalry.get_roads(RivalryTuning.AI_REALM):
		if not simulation.is_revealed(tile) or not view._is_world_visible(view.tile_to_world(tile), 100.0):
			continue
		_draw_rival_road(tile)


func _draw_rival_road(tile: Vector2i) -> void:
	var center: Vector2 = view.tile_to_world(tile)
	var base_color := Color(0.35, 0.20, 0.15, 0.94)
	var light_color := Color(0.62, 0.38, 0.25, 0.92)
	var neighbors: Array = []
	for neighbor in [tile + Vector2i.LEFT, tile + Vector2i.RIGHT, tile + Vector2i.UP, tile + Vector2i.DOWN]:
		if view.simulation.rivalry.owns_road(RivalryTuning.AI_REALM, neighbor):
			neighbors.append(neighbor)
	for neighbor in neighbors:
		if tile.x > neighbor.x or (tile.x == neighbor.x and tile.y > neighbor.y):
			continue
		var finish: Vector2 = view.tile_to_world(neighbor)
		draw_line(center, finish, base_color, 17.0, true)
		draw_line(center, finish, light_color, 12.0, true)
	if neighbors.is_empty():
		draw_circle(center, 10.5, base_color)
		draw_circle(center, 7.5, light_color)


func _tile_polygon(tile: Vector2i) -> PackedVector2Array:
	return _diamond_polygon(view.tile_to_world(tile), TILE_WIDTH, TILE_HEIGHT)


func _diamond_polygon(center: Vector2, width: float, height: float) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(0.0, -height * 0.5),
		center + Vector2(width * 0.5, 0.0),
		center + Vector2(0.0, height * 0.5),
		center + Vector2(-width * 0.5, 0.0)
	])


func _draw_polygon_outline(polygon: PackedVector2Array, color: Color, width: float) -> void:
	if polygon.is_empty():
		return
	var outline := PackedVector2Array(polygon)
	outline.append(polygon[0])
	draw_polyline(outline, color, width, true)
