extends RefCounted

## The Director: short-term settlement intentions, not an RPG quest log.
## Always expose 1–2 next jobs so quiet simulation still has a purpose.

const Defs = preload("one_shard_defs.gd")

const ID_ESTABLISH := "establish"
const ID_FEED := "feed"
const ID_NIGHTFALL := "nightfall"
const ID_SCOUT := "scout_frontier"
const ID_STONE := "stone_shortage"

const FOOD_NIGHTFALL := 8
## R36: the stone objective is shown only when stone is actually short.
const STONE_LOW := 30
const STONE_QUARRIES_ENOUGH := 2
const DEPOSIT_QUARRY_RADIUS := 10


static func evaluate(sim) -> Array:
	var completed: Dictionary = sim.intention_completed
	var active: Array = []
	for spec in _catalog():
		var intention_id := String(spec["id"])
		if bool(completed.get(intention_id, false)):
			continue
		if not _unlocked(sim, spec):
			continue
		var criteria: Array = _evaluate_criteria(sim, spec)
		var done := true
		for row in criteria:
			if not bool(row.get("done", false)):
				done = false
				break
		if done:
			completed[intention_id] = true
			sim.intention_completed = completed
			sim._add_log("Intention complete: %s." % String(spec["title"]))
			sim._record_event("intention_complete", String(spec["title"]), {"id": intention_id})
			continue
		active.append({
			"id": intention_id,
			"title": String(spec["title"]),
			"detail": String(spec["detail"]) if not spec.has("detail_fmt") else String(spec["detail_fmt"]) % [int(sim.central_inventory.get("stone", 0)), _count_completed(sim, "QUARRY")],
			"criteria": criteria,
			"reward": String(spec.get("reward", ""))
		})
		if active.size() >= 2:
			break
	return active


static func current(sim) -> Dictionary:
	var active := evaluate(sim)
	if active.is_empty():
		return {}
	return active[0]


static func _unlocked(sim, spec: Dictionary) -> bool:
	for need in spec.get("requires", []):
		if not bool(sim.intention_completed.get(String(need), false)):
			return false
	var flag := String(spec.get("require_flag", ""))
	if flag != "" and not bool(sim.intention_flags.get(flag, false)):
		return false
	# R36: need-based objectives ("Stone Shortage" showed with 55 Stone stored).
	if String(spec.get("need", "")) == "stone":
		if int(sim.central_inventory.get("stone", 0)) >= STONE_LOW:
			return false
		if _count_completed(sim, "QUARRY") >= STONE_QUARRIES_ENOUGH:
			return false
	return true


static func _evaluate_criteria(sim, spec: Dictionary) -> Array:
	var rows: Array = []
	for criterion in spec.get("criteria", []):
		var kind := String(criterion.get("kind", ""))
		var done := false
		var label := String(criterion.get("label", ""))
		match kind:
			"building":
				done = _has_completed_building(sim, String(criterion.get("type", "")))
			"soldiers":
				done = int(sim.soldiers_total) >= int(criterion.get("count", 1))
			"food":
				done = int(sim.get_food_units()) >= int(criterion.get("count", FOOD_NIGHTFALL))
			"defense":
				done = _has_completed_building(sim, "WATCHTOWER") or _has_completed_building(sim, "WALL")
			"scout":
				done = bool(sim.intention_flags.get("scouted_frontier", false)) or _revealed_beyond(sim, int(criterion.get("radius", 16)))
			"flag":
				done = bool(sim.intention_flags.get(String(criterion.get("flag", "")), false))
			"quarry_near_deposit":
				done = _quarry_near_deposit(sim)
		rows.append({"label": label, "done": done})
	return rows


static func _has_completed_building(sim, building_type: String) -> bool:
	for building in sim.buildings:
		if bool(building.get("construction", false)):
			continue
		if String(building.get("type", "")) == building_type:
			return true
	return false


static func _count_completed(sim, building_type: String) -> int:
	var n := 0
	for building in sim.buildings:
		if not bool(building.get("construction", false)) and String(building.get("type", "")) == building_type:
			n += 1
	return n


static func _quarry_near_deposit(sim) -> bool:
	if not sim.intention_flags.has("stone_deposit_x"):
		return false
	var deposit := Vector2i(int(sim.intention_flags["stone_deposit_x"]), int(sim.intention_flags["stone_deposit_y"]))
	for building in sim.buildings:
		if bool(building.get("construction", false)) or String(building.get("type", "")) != "QUARRY":
			continue
		var pos: Vector2i = building.get("position", Vector2i.ZERO)
		if absi(pos.x - deposit.x) + absi(pos.y - deposit.y) <= DEPOSIT_QUARRY_RADIUS:
			return true
	return false


static func _revealed_beyond(sim, radius: int) -> bool:
	var origin: Vector2i = sim._footprint_center(sim.town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	var count := 0
	for key in sim.revealed_tiles.keys():
		var tile: Vector2i = sim._tile_from_key(String(key))
		if sim._manhattan(origin, tile) >= radius:
			count += 1
			if count >= 8:
				return true
	return false


static func _catalog() -> Array:
	return [
		{
			"id": ID_ESTABLISH,
			"title": "A Settlement Begins",
			"detail": "Establish lumber and stone production.",
			"reward": "The first bottleneck: free workers have a cost.",
			"criteria": [
				{"kind": "building", "type": "LUMBER_CAMP", "label": "Build a Lumber Camp"},
				{"kind": "building", "type": "QUARRY", "label": "Build a Quarry"}
			]
		},
		{
			"id": ID_FEED,
			"title": "Feed the Settlement",
			"detail": "Establish food production before dusk.",
			"requires": [ID_ESTABLISH],
			"criteria": [
				{"kind": "building", "type": "FARM", "label": "Build a Farm"}
			]
		},
		{
			"id": ID_NIGHTFALL,
			"title": "Prepare for Nightfall",
			"detail": "Defence costs workers you could have spent expanding.",
			"requires": [ID_FEED],
			"criteria": [
				{"kind": "defense", "label": "Have 1 defensive structure"},
				{"kind": "soldiers", "count": 1, "label": "Have 1 soldier"},
				{"kind": "food", "count": FOOD_NIGHTFALL, "label": "Store 8 food"}
			]
		},
		{
			"id": ID_SCOUT,
			"title": "Where Did They Come From?",
			"detail": "Scout a frontier. Fog hides opportunity and danger.",
			"requires": [ID_NIGHTFALL],
			"require_flag": "first_dawn",
			"criteria": [
				{"kind": "scout", "radius": 16, "label": "Reveal the frontier"}
			]
		},
		{
			"id": ID_STONE,
			"title": "Stone Running Low",
			"detail": "A richer stone deposit lies beyond the first hills.",
			"detail_fmt": "Only %d Stone stored and %d Quarry working. A Quarry at the richer deposit beyond the hills keeps walls and towers supplied.",
			"requires": [ID_ESTABLISH],
			"require_flag": "stone_deposit_found",
			"need": "stone",
			"criteria": [
				{"kind": "quarry_near_deposit", "label": "Build a Quarry within 10 tiles of the stone deposit"}
			]
		}
	]
