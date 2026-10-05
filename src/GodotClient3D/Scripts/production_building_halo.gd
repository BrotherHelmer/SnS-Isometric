class_name ProductionBuildingHalo3D
extends RefCounted

## Authored context props around completed buildings. Purely visual: no
## collision, occupancy or pathing. Offsets are tiles relative to the anchor
## at rotation 0 and sit outside the gameplay footprint.
## The Director: each completed building gets a small, deterministic yard of
## existing props so the settlement reads as inhabited without touching sim.

const Catalog = preload("res://src/GodotClient3D/Scripts/production_asset_catalog.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")

# 4–12 authored slots per type. Extra candidates let the resolver drop any
# tile that would land on a footprint, road or door.
const TABLE := {
	"LUMBER_CAMP": [
		{"prop": "log", "dx": -1, "dy": 1, "yaw": 18.0, "scale": 0.95},
		{"prop": "log", "dx": -1, "dy": 2, "yaw": -12.0, "scale": 0.85},
		{"prop": "stump", "dx": 3, "dy": 1, "yaw": 40.0, "scale": 0.70},
		{"prop": "cart", "dx": 3, "dy": 2, "yaw": -8.0, "scale": 0.72},
		{"prop": "wood_stack", "dx": 1, "dy": -1, "yaw": 6.0, "scale": 0.90},
		{"prop": "work_axe", "dx": 0, "dy": -1, "yaw": 70.0, "scale": 0.85},
	],
	"SAWMILL": [
		{"prop": "log", "dx": -1, "dy": 1, "yaw": 12.0, "scale": 0.90},
		{"prop": "log", "dx": -1, "dy": 2, "yaw": -20.0, "scale": 0.80},
		{"prop": "stump", "dx": 3, "dy": 0, "yaw": 25.0, "scale": 0.68},
		{"prop": "cart", "dx": 3, "dy": 2, "yaw": 14.0, "scale": 0.70},
		{"prop": "plank_stack", "dx": 1, "dy": -1, "yaw": 4.0, "scale": 0.88},
		{"prop": "wood_stack", "dx": 2, "dy": -1, "yaw": -10.0, "scale": 0.82},
	],
	"BAKERY": [
		{"prop": "sack", "dx": -1, "dy": 1, "yaw": 8.0, "scale": 1.05},
		{"prop": "sack", "dx": -1, "dy": 2, "yaw": -16.0, "scale": 0.95},
		{"prop": "barrel", "dx": 3, "dy": 1, "yaw": 0.0, "scale": 1.10},
		{"prop": "barrel", "dx": 3, "dy": 2, "yaw": 20.0, "scale": 1.00},
		{"prop": "crate", "dx": 1, "dy": -1, "yaw": 6.0, "scale": 0.95},
		{"prop": "long_crate", "dx": 2, "dy": -1, "yaw": 90.0, "scale": 0.85},
	],
	"HOUSE": [
		{"prop": "fence", "dx": -1, "dy": 0, "yaw": 90.0, "scale": 1.0},
		{"prop": "fence", "dx": -1, "dy": 1, "yaw": 90.0, "scale": 1.0},
		{"prop": "barrel", "dx": 2, "dy": -1, "yaw": 12.0, "scale": 1.05},
		{"prop": "chopping_block", "dx": 2, "dy": 2, "yaw": -18.0, "scale": 0.85},
		{"prop": "work_axe", "dx": 2, "dy": 2, "yaw": 55.0, "scale": 0.70},
		{"prop": "crate", "dx": -1, "dy": 2, "yaw": 8.0, "scale": 0.90},
	],
	"QUARRY": [
		{"prop": "stone_stack", "dx": -1, "dy": 1, "yaw": 10.0, "scale": 0.90},
		{"prop": "stone_stack", "dx": 3, "dy": 1, "yaw": -14.0, "scale": 0.80},
		{"prop": "rocks", "dx": -1, "dy": 2, "yaw": 30.0, "scale": 0.85},
		{"prop": "rocks", "dx": 3, "dy": 2, "yaw": -22.0, "scale": 0.75},
		{"prop": "rocks", "dx": 1, "dy": -1, "yaw": 6.0, "scale": 0.80},
		{"prop": "wheelbarrow", "dx": 2, "dy": -1, "yaw": 18.0, "scale": 0.75},
	],
	"FARM": [
		{"prop": "wheat_field", "dx": -2, "dy": 0, "yaw": 0.0, "scale": 1.15, "span": Vector2i(2, 2)},
		{"prop": "wheat_crop", "dx": 4, "dy": 0, "yaw": 8.0, "scale": 1.20},
		{"prop": "wheat_crop", "dx": 4, "dy": 1, "yaw": -6.0, "scale": 1.10},
		{"prop": "fence", "dx": -1, "dy": -1, "yaw": 0.0, "scale": 1.0},
		{"prop": "fence", "dx": 0, "dy": -1, "yaw": 0.0, "scale": 1.0},
		{"prop": "barrel", "dx": 4, "dy": 2, "yaw": 14.0, "scale": 1.00},
		{"prop": "wheelbarrow", "dx": 4, "dy": 3, "yaw": -20.0, "scale": 0.72},
	],
	"TOWN_HALL": [
		{"prop": "cart", "dx": -1, "dy": 2, "yaw": 12.0, "scale": 0.78},
		{"prop": "barrel", "dx": 4, "dy": 1, "yaw": 0.0, "scale": 1.15},
		{"prop": "barrel", "dx": 4, "dy": 2, "yaw": 16.0, "scale": 1.05},
		{"prop": "crate", "dx": -1, "dy": 1, "yaw": 8.0, "scale": 1.00},
		{"prop": "lantern", "dx": 1, "dy": -1, "yaw": 0.0, "scale": 1.00},
		{"prop": "fence", "dx": 2, "dy": -1, "yaw": 0.0, "scale": 1.00},
	],
	"CASTLE": [
		{"prop": "weaponrack", "dx": -1, "dy": 1, "yaw": 90.0, "scale": 0.95},
		{"prop": "barrel", "dx": 4, "dy": 1, "yaw": 0.0, "scale": 1.10},
		{"prop": "crate", "dx": 4, "dy": 2, "yaw": 10.0, "scale": 1.00},
		{"prop": "lantern", "dx": 1, "dy": -1, "yaw": 0.0, "scale": 1.00},
		{"prop": "cart", "dx": -1, "dy": 3, "yaw": -8.0, "scale": 0.70},
	],
	"STOREHOUSE": [
		{"prop": "crate", "dx": -1, "dy": 1, "yaw": 6.0, "scale": 1.05},
		{"prop": "crate", "dx": -1, "dy": 2, "yaw": -10.0, "scale": 0.95},
		{"prop": "barrel", "dx": 4, "dy": 1, "yaw": 0.0, "scale": 1.10},
		{"prop": "long_crate", "dx": 4, "dy": 2, "yaw": 90.0, "scale": 0.90},
		{"prop": "sack", "dx": 1, "dy": -1, "yaw": 14.0, "scale": 1.00},
		{"prop": "sack", "dx": 2, "dy": -1, "yaw": -8.0, "scale": 0.95},
	],
	"BARRACKS": [
		{"prop": "weaponrack", "dx": -1, "dy": 1, "yaw": 90.0, "scale": 1.00},
		{"prop": "weaponrack", "dx": 4, "dy": 1, "yaw": -90.0, "scale": 1.00},
		{"prop": "training_target", "dx": 4, "dy": 2, "yaw": 18.0, "scale": 1.05},
		{"prop": "barrel", "dx": -1, "dy": 2, "yaw": 0.0, "scale": 1.00},
		{"prop": "crate", "dx": 1, "dy": -1, "yaw": 8.0, "scale": 0.95},
		{"prop": "lantern", "dx": 2, "dy": -1, "yaw": 0.0, "scale": 1.00},
	],
	"WATCHTOWER": [
		{"prop": "lantern", "dx": 1, "dy": 0, "yaw": 0.0, "scale": 1.00},
		{"prop": "barrel", "dx": -1, "dy": 0, "yaw": 8.0, "scale": 0.95},
		{"prop": "crate", "dx": 0, "dy": -1, "yaw": 12.0, "scale": 0.90},
		{"prop": "weaponrack", "dx": 1, "dy": 1, "yaw": -20.0, "scale": 0.85},
	],
	"CLAIMANT_OUTPOST": [
		{"prop": "lantern", "dx": 2, "dy": 0, "yaw": 0.0, "scale": 1.00},
		{"prop": "barrel", "dx": -1, "dy": 0, "yaw": 10.0, "scale": 0.95},
		{"prop": "crate", "dx": 0, "dy": -1, "yaw": 6.0, "scale": 0.90},
		{"prop": "fence", "dx": -1, "dy": 1, "yaw": 90.0, "scale": 1.00},
	],
}


static func authored_for(building_type: String) -> Array:
	var key := building_type
	if key == "TOWN_HALL" and not TABLE.has(key):
		key = "CASTLE"
	return TABLE.get(key, [])


static func prop_path(prop_name: String) -> String:
	return String(Catalog.HALO_PROPS.get(prop_name, ""))


static func resolve(building: Dictionary, blocked: Dictionary) -> Array:
	var type_name := String(building.get("type", ""))
	if bool(building.get("construction", false)):
		return []
	if type_name in [Defs.BUILDING_ROAD, Defs.BUILDING_WALL, Defs.BUILDING_CONSTRUCTION_SITE, ""]:
		return []
	if type_name == Defs.BUILDING_TOWN_HALL and bool(building.get("has_barracks", false)):
		type_name = "CASTLE"
	var anchor := Vector2i(building.get("position", Vector2i.ZERO))
	var footprint := _footprint(building, type_name)
	var rotation := posmod(int(building.get("rotation", 0)), 4)
	var reserved := blocked.duplicate()
	_mark_footprint(reserved, anchor, footprint)
	var placements: Array = []
	for slot_value in authored_for(type_name):
		var slot: Dictionary = slot_value
		var span := Vector2i(slot.get("span", Vector2i.ONE))
		var local := Vector2i(int(slot.get("dx", 0)), int(slot.get("dy", 0)))
		var world_tile := anchor + _rotate_offset(local, footprint, rotation)
		var world_span := span if rotation % 2 == 0 else Vector2i(span.y, span.x)
		if not _span_clear(world_tile, world_span, reserved):
			continue
		_mark_span(reserved, world_tile, world_span)
		if String(slot.get("prop", "")) == "wheat_field":
			for oy in world_span.y:
				for ox in world_span.x:
					placements.append({
						"prop": "wheat_crop",
						"tile": world_tile + Vector2i(ox, oy),
						"yaw": float(slot.get("yaw", 0.0)) + float((ox * 17 + oy * 11) % 24) - 12.0,
						"scale": float(slot.get("scale", 1.0)),
						"building_id": int(building.get("id", 0)),
						"building_type": type_name,
					})
			continue
		placements.append({
			"prop": String(slot.get("prop", "")),
			"tile": world_tile,
			"yaw": float(slot.get("yaw", 0.0)) + float(rotation) * 90.0,
			"scale": float(slot.get("scale", 1.0)),
			"building_id": int(building.get("id", 0)),
			"building_type": type_name,
		})
	return placements


static func resolve_world(simulation) -> Array:
	var blocked := {}
	if simulation == null:
		return []
	for key in simulation.connected_roads.keys():
		blocked[String(key)] = true
	for building_value in simulation.get_buildings():
		var building: Dictionary = building_value
		var type_name := String(building.get("planned_type", "")) if bool(building.get("construction", false)) else String(building.get("type", ""))
		if type_name == Defs.BUILDING_ROAD:
			blocked[_tile_key(Vector2i(building.get("position", Vector2i.ZERO)))] = true
		var access = simulation.get_building_road_access_candidates(building) if simulation.has_method("get_building_road_access_candidates") else []
		for tile_value in access:
			blocked[_tile_key(Vector2i(tile_value))] = true
		_mark_footprint(blocked, Vector2i(building.get("position", Vector2i.ZERO)), _footprint(building, type_name))
	var placements: Array = []
	for building_value in simulation.get_buildings():
		placements.append_array(resolve(building_value, blocked))
	return placements


static func _footprint(building: Dictionary, type_name: String) -> Vector2i:
	var stored = building.get("footprint", null)
	if typeof(stored) == TYPE_VECTOR2I:
		return stored
	return Defs.building_footprint(type_name)


static func _rotate_offset(offset: Vector2i, footprint: Vector2i, quarters: int) -> Vector2i:
	var p := offset
	var fp := footprint
	for _step in posmod(quarters, 4):
		var next := Vector2i(fp.y - 1 - p.y, p.x)
		p = next
		fp = Vector2i(fp.y, fp.x)
	return p


static func _span_clear(origin: Vector2i, span: Vector2i, blocked: Dictionary) -> bool:
	for oy in span.y:
		for ox in span.x:
			if blocked.has(_tile_key(origin + Vector2i(ox, oy))):
				return false
	return true


static func _mark_span(blocked: Dictionary, origin: Vector2i, span: Vector2i) -> void:
	for oy in span.y:
		for ox in span.x:
			blocked[_tile_key(origin + Vector2i(ox, oy))] = true


static func _mark_footprint(blocked: Dictionary, anchor: Vector2i, footprint: Vector2i) -> void:
	_mark_span(blocked, anchor, footprint)


static func _tile_key(tile: Vector2i) -> String:
	return "%d,%d" % [tile.x, tile.y]
