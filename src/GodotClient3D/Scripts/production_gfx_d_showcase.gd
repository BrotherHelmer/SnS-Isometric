class_name ProductionGfxDShowcase
extends RefCounted

## Deterministic GFX-D benchmark village. Presentation only — stamps
## completed buildings onto DEFAULT_SEED so concept comparisons share
## the same camera, lighting and landscape. Does not change campaign
## saves or gameplay rules.

const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")

const TARGET_BUILDINGS := 15


static func apply(simulation) -> Dictionary:
	var report := {
		"buildings": 0,
		"roads": 0,
		"ok": false,
	}
	if simulation == null or not simulation.is_town_hall_founded():
		return report
	var hall: Vector2i = simulation.town_hall_position
	var roads: Array[Vector2i] = _road_plan(hall)
	for tile in roads:
		if _stamp_road(simulation, tile):
			report["roads"] = int(report["roads"]) + 1
	var plan := [
		{"type": Defs.BUILDING_HOUSE, "tiles": [hall + Vector2i(-3, 1), hall + Vector2i(-3, 4), hall + Vector2i(5, -2)]},
		{"type": Defs.BUILDING_HOUSE, "tiles": [hall + Vector2i(5, 1), hall + Vector2i(6, 4), hall + Vector2i(-3, -2)]},
		{"type": Defs.BUILDING_HOUSE, "tiles": [hall + Vector2i(0, 8), hall + Vector2i(2, 8), hall + Vector2i(-2, 8)]},
		{"type": Defs.BUILDING_FARM, "tiles": [hall + Vector2i(5, 5), hall + Vector2i(8, 2), hall + Vector2i(-5, 5)]},
		{"type": Defs.BUILDING_BAKERY, "tiles": [hall + Vector2i(-4, 6), hall + Vector2i(8, 6), hall + Vector2i(4, 9)]},
		{"type": Defs.BUILDING_STOREHOUSE, "tiles": [hall + Vector2i(8, -1), hall + Vector2i(-5, -1), hall + Vector2i(9, 8)]},
		{"type": Defs.BUILDING_LUMBER_CAMP, "tiles": [hall + Vector2i(-6, 2), hall + Vector2i(-7, 6), hall + Vector2i(10, 4)]},
		{"type": Defs.BUILDING_WATCHTOWER, "tiles": [hall + Vector2i(4, -1), hall + Vector2i(-1, -1), hall + Vector2i(7, 0)]},
		{"type": Defs.BUILDING_BARRACKS, "tiles": [hall + Vector2i(0, -4), hall + Vector2i(5, -4), hall + Vector2i(-4, -4)]},
		{"type": Defs.BUILDING_QUARRY, "tiles": [hall + Vector2i(10, 0), hall + Vector2i(11, 5), hall + Vector2i(-8, 0)]},
		{"type": "HOUSE", "tiles": [hall + Vector2i(2, 11), hall + Vector2i(6, 10), hall + Vector2i(-3, 10)]},
		{"type": "HOUSE", "tiles": [hall + Vector2i(8, 10), hall + Vector2i(-6, 9), hall + Vector2i(10, 8)]},
		{"type": Defs.BUILDING_SAWMILL, "tiles": [hall + Vector2i(-7, -2), hall + Vector2i(12, 2), hall + Vector2i(-8, 4)]},
		{"type": "HOUSE", "tiles": [hall + Vector2i(4, 13), hall + Vector2i(-1, 13), hall + Vector2i(9, 12)]},
	]
	for entry_value in plan:
		var entry: Dictionary = entry_value
		var tiles: Array = entry.get("tiles", [])
		var typed_tiles: Array[Vector2i] = []
		for tile_value in tiles:
			typed_tiles.append(Vector2i(tile_value))
		if _stamp_building(simulation, String(entry.get("type", "")), typed_tiles):
			report["buildings"] = int(report["buildings"]) + 1
	if simulation.has_method("_rebuild_occupied_tiles"):
		simulation._rebuild_occupied_tiles()
	if simulation.has_method("_recompute_road_network"):
		simulation._recompute_road_network()
	if simulation.has_method("_reveal_from_world"):
		simulation._reveal_from_world()
	if simulation.has_method("_reveal_radius"):
		simulation._reveal_radius(hall + Vector2i(2, 2), 22)
	simulation.is_night = false
	simulation.phase_time = 80.0
	report["buildings"] = _count_non_road(simulation)
	report["ok"] = int(report["buildings"]) >= 12 and int(report["roads"]) >= 8
	return report


static func _road_plan(hall: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for i in 12:
		tiles.append(hall + Vector2i(1, 4 + i))
	for i in 10:
		tiles.append(hall + Vector2i(4 + i, 2))
	for i in 6:
		tiles.append(hall + Vector2i(-1 - i, 2))
	for i in 5:
		tiles.append(hall + Vector2i(1 + i, 7))
	for i in 4:
		tiles.append(hall + Vector2i(7, 3 + i))
	return tiles


static func _stamp_road(simulation, tile: Vector2i) -> bool:
	if not simulation.is_inside_map(tile):
		return false
	if not simulation.get_building_at_tile(tile).is_empty():
		return String(simulation.get_building_at_tile(tile).get("type", "")) == Defs.BUILDING_ROAD
	_prep_tile(simulation, tile)
	simulation._add_completed_building(Defs.BUILDING_ROAD, tile)
	return true


static func _stamp_building(simulation, type_name: String, candidates: Array[Vector2i]) -> bool:
	var footprint := Defs.building_footprint(type_name)
	for tile in candidates:
		if not _footprint_clear(simulation, tile, footprint):
			continue
		for oy in footprint.y:
			for ox in footprint.x:
				_prep_tile(simulation, tile + Vector2i(ox, oy))
		simulation._add_completed_building(type_name, tile)
		return true
	return false


static func _footprint_clear(simulation, tile: Vector2i, footprint: Vector2i) -> bool:
	for oy in footprint.y:
		for ox in footprint.x:
			var sample := tile + Vector2i(ox, oy)
			if not simulation.is_inside_map(sample):
				return false
			if not simulation.get_building_at_tile(sample).is_empty():
				return false
	return true


static func _prep_tile(simulation, tile: Vector2i) -> void:
	if not simulation.is_inside_map(tile):
		return
	simulation._set_tile(tile, Defs.TILE_GRASS)
	if simulation.has_method("_flatten_area"):
		simulation._flatten_area(tile, 1)
	if simulation.has_method("is_revealed") and simulation.has_method("_tile_key"):
		simulation.revealed_tiles[simulation._tile_key(tile)] = true


static func _count_non_road(simulation) -> int:
	var count := 0
	for building_value in simulation.get_buildings():
		var building: Dictionary = building_value
		if String(building.get("type", "")) == Defs.BUILDING_ROAD:
			continue
		count += 1
	return count
