extends RefCounted

## The Director: placement quality is a spatial puzzle, not a new subsystem.
## Coverage percent becomes a production scalar (Poor–Excellent).

const Defs = preload("one_shard_defs.gd")

const BAND_POOR := "Poor"
const BAND_FAIR := "Fair"
const BAND_GOOD := "Good"
const BAND_EXCELLENT := "Excellent"

const LUMBER_RADIUS := 8
const LUMBER_EXPECTED := 16
const QUARRY_RADIUS := 4
const QUARRY_EXPECTED := 5
const FARM_RADIUS := 3
const FARM_EXPECTED := 24

const SCALAR_POOR := 0.65
const SCALAR_FAIR := 0.85
const SCALAR_GOOD := 1.0
const SCALAR_EXCELLENT := 1.15


static func applies_to(building_type: String) -> bool:
	return building_type in [Defs.BUILDING_LUMBER_CAMP, Defs.BUILDING_QUARRY, Defs.BUILDING_FARM]


static func band_for(percent: int) -> String:
	if percent >= 90:
		return BAND_EXCELLENT
	if percent >= 70:
		return BAND_GOOD
	if percent >= 40:
		return BAND_FAIR
	return BAND_POOR


static func scalar_for(band: String) -> float:
	match band:
		BAND_EXCELLENT:
			return SCALAR_EXCELLENT
		BAND_FAIR:
			return SCALAR_FAIR
		BAND_POOR:
			return SCALAR_POOR
		_:
			return SCALAR_GOOD


static func coverage_name(building_type: String) -> String:
	match building_type:
		Defs.BUILDING_LUMBER_CAMP:
			return "Forest coverage"
		Defs.BUILDING_QUARRY:
			return "Stone access"
		Defs.BUILDING_FARM:
			return "Suitable land"
		_:
			return ""


static func score(sim, building_type: String, tile: Vector2i, rotation: int = 0) -> Dictionary:
	if not applies_to(building_type):
		return {}
	var footprint: Vector2i = sim._oriented_footprint(building_type, rotation)
	var origin: Vector2i = sim._footprint_center(tile, footprint)
	var found := 0
	var expected := 1
	var radius := 1
	match building_type:
		Defs.BUILDING_LUMBER_CAMP:
			radius = LUMBER_RADIUS
			expected = LUMBER_EXPECTED
			found = _count_resource_tiles(sim, origin, radius, Defs.TILE_TREE)
		Defs.BUILDING_QUARRY:
			radius = QUARRY_RADIUS
			expected = QUARRY_EXPECTED
			found = _count_resource_tiles(sim, origin, radius, Defs.TILE_ROCK)
		Defs.BUILDING_FARM:
			radius = FARM_RADIUS
			expected = FARM_EXPECTED
			found = _count_suitable_land(sim, origin, radius, tile, footprint)
	var percent := clampi(int(round(100.0 * float(found) / float(maxi(1, expected)))), 0, 100)
	var band := band_for(percent)
	return {
		"percent": percent,
		"band": band,
		"scalar": scalar_for(band),
		"coverage_name": coverage_name(building_type),
		"found": found,
		"expected": expected,
		"label": "%s: %d%% · %s" % [coverage_name(building_type), percent, band]
	}


static func _count_resource_tiles(sim, origin: Vector2i, radius: int, tile_type: String) -> int:
	var found := 0
	for y in range(origin.y - radius, origin.y + radius + 1):
		for x in range(origin.x - radius, origin.x + radius + 1):
			var tile := Vector2i(x, y)
			if not sim.is_inside_map(tile):
				continue
			if sim._manhattan(origin, tile) > radius:
				continue
			if String(sim.get_tile(tile)) != tile_type:
				continue
			if tile_type == Defs.TILE_TREE and int(sim.tree_deposits.get(sim._tile_key(tile), 0)) <= 0:
				continue
			if tile_type == Defs.TILE_ROCK and int(sim.rock_deposits.get(sim._tile_key(tile), 0)) <= 0:
				continue
			found += 1
	return found


static func _count_suitable_land(sim, origin: Vector2i, radius: int, site: Vector2i, footprint: Vector2i) -> int:
	var blocked: Dictionary = {}
	for occupied in sim._footprint_tiles(site, footprint):
		blocked[sim._tile_key(occupied)] = true
	var found := 0
	for y in range(origin.y - radius, origin.y + radius + 1):
		for x in range(origin.x - radius, origin.x + radius + 1):
			var tile := Vector2i(x, y)
			if not sim.is_inside_map(tile):
				continue
			if sim._manhattan(origin, tile) > radius:
				continue
			if blocked.has(sim._tile_key(tile)):
				continue
			if String(sim.get_tile(tile)) != Defs.TILE_GRASS:
				continue
			if sim.is_tile_occupied(tile):
				continue
			found += 1
	return found
