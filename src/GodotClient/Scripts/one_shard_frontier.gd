extends RefCounted

## The Director: expansion raises exposure by geography alone. No threat stat.
## Compact yards stay calm. A far quarry is something that must be defended.

const Defs = preload("one_shard_defs.gd")

const TOWN_SAFE_RADIUS := 8
const TOWER_COVER_RADIUS := 8
const EXPOSED_DISTANCE := 10
const EXPOSED_THRESHOLD := 0.55


static func evaluate(sim, building: Dictionary) -> Dictionary:
	var building_type := String(building.get("type", ""))
	if building_type in [Defs.BUILDING_ROAD, Defs.BUILDING_WALL, Defs.BUILDING_TOWN_HALL]:
		return {"score": 0.0, "exposed": false, "label": "Safe", "distance": 0}
	if bool(building.get("construction", false)):
		return {"score": 0.0, "exposed": false, "label": "Safe", "distance": 0}
	var town: Vector2i = sim._footprint_center(sim.town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	var center: Vector2i = sim._footprint_center(building.get("position", town), sim._building_footprint(building))
	var distance: int = sim._manhattan(town, center)
	var score := clampf(float(maxi(0, distance - TOWN_SAFE_RADIUS)) / 12.0, 0.0, 1.0)
	if _has_tower_cover(sim, center):
		score = maxf(0.0, score - 0.45)
	if building_type == Defs.BUILDING_OUTPOST:
		score = maxf(score, 0.6)
	var exposed: bool = score >= EXPOSED_THRESHOLD and distance >= EXPOSED_DISTANCE
	return {
		"score": snappedf(score, 0.01),
		"exposed": exposed,
		"label": "Exposed" if exposed else "Sheltered",
		"distance": distance
	}


static func exposure_score(sim, building: Dictionary) -> float:
	return float(evaluate(sim, building).get("score", 0.0))


static func is_exposed(sim, building: Dictionary) -> bool:
	return bool(evaluate(sim, building).get("exposed", false))


static func _has_tower_cover(sim, tile: Vector2i) -> bool:
	for building in sim.buildings:
		var building_type := String(building.get("type", ""))
		if bool(building.get("construction", false)):
			continue
		if building_type not in [Defs.BUILDING_WATCHTOWER, Defs.BUILDING_OUTPOST]:
			continue
		var center: Vector2i = sim._footprint_center(building.get("position", tile), sim._building_footprint(building))
		var cover := TOWER_COVER_RADIUS if building_type == Defs.BUILDING_WATCHTOWER else 5
		if sim._manhattan(center, tile) <= cover:
			return true
	return false
