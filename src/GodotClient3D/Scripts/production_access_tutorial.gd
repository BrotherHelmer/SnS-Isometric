extends RefCounted

## Access-1: a calm first-five-minutes guide on top of settlement intentions.
## The Director: short text, skippable, never an RTS quest log.

const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Intentions = preload("res://src/GodotClient/Scripts/one_shard_intentions.gd")

const STEP_CAMERA := "camera"
const STEP_ROAD := "road"
const STEP_LUMBER := "lumber"
const STEP_QUARRY := "quarry"
const STEP_CONNECT := "connect"
const STEP_CARRIERS := "carriers"
const STEP_FOOD := "food"
const STEP_WATCHTOWER := "watchtower"

var enabled := true
var skipped := false
var completed := false
var current_id := STEP_CAMERA
var seen_pan := false
var seen_zoom := false
var seen_rotate := false
var road_baseline := 0
var completed_ids: Dictionary = {}


static func catalog() -> Array:
	return [
		{
			"id": STEP_CAMERA,
			"title": "Look around",
			"hint": "Pan with WASD or the edge of the screen. Scroll to zoom. Q and E turn the view.",
			"highlight": "",
		},
		{
			"id": STEP_ROAD,
			"title": "A path home",
			"hint": "Place a short road from the hall. Carriers use roads.",
			"highlight": "ROAD",
		},
		{
			"id": STEP_LUMBER,
			"title": "A Settlement Begins",
			"hint": "Raise a Lumber camp near trees.",
			"highlight": "LUMBER_CAMP",
		},
		{
			"id": STEP_QUARRY,
			"title": "Stone for the walls",
			"hint": "Place a Quarry on rock.",
			"highlight": "QUARRY",
		},
		{
			"id": STEP_CONNECT,
			"title": "Join the yards",
			"hint": "Connect Lumber and Quarry to the hall with roads.",
			"highlight": "ROAD",
		},
		{
			"id": STEP_CARRIERS,
			"title": "Let them haul",
			"hint": "Leave a free settler. Carriers appear when a yard is linked.",
			"highlight": "",
		},
		{
			"id": STEP_FOOD,
			"title": "Feed the Settlement",
			"hint": "Plant a Farm before dusk.",
			"highlight": "FARM",
		},
		{
			"id": STEP_WATCHTOWER,
			"title": "Prepare for Nightfall",
			"hint": "Raise a Watchtower before night.",
			"highlight": "WATCHTOWER",
		},
	]


func reset() -> void:
	skipped = false
	completed = false
	current_id = STEP_CAMERA
	seen_pan = false
	seen_zoom = false
	seen_rotate = false
	road_baseline = 0
	completed_ids.clear()


func skip() -> void:
	skipped = true
	enabled = false


func reopen() -> void:
	enabled = true
	skipped = false
	if completed:
		completed = false
		current_id = STEP_CAMERA
		completed_ids.clear()


func begin_for_sim(sim) -> void:
	reset()
	road_baseline = _player_road_count(sim)


func note_camera(kind: String) -> void:
	match kind:
		"pan":
			seen_pan = true
		"zoom":
			seen_zoom = true
		"rotate":
			seen_rotate = true


func evaluate(sim) -> Dictionary:
	if not enabled or skipped:
		return {
			"visible": false,
			"id": current_id,
			"title": "",
			"hint": "",
			"highlight": "",
			"step_index": 0,
			"step_count": catalog().size(),
			"done": completed,
		}
	_advance(sim)
	var spec := _spec(current_id)
	if spec.is_empty() and completed:
		return {
			"visible": false,
			"id": "done",
			"title": "You know the morning",
			"hint": "The settlement will tell you what matters next.",
			"highlight": "",
			"step_index": catalog().size(),
			"step_count": catalog().size(),
			"done": true,
		}
	return {
		"visible": true,
		"id": String(spec.get("id", current_id)),
		"title": String(spec.get("title", "")),
		"hint": String(spec.get("hint", "")),
		"highlight": String(spec.get("highlight", "")),
		"step_index": _index_of(current_id) + 1,
		"step_count": catalog().size(),
		"done": completed,
	}


func _advance(sim) -> void:
	for spec in catalog():
		var step_id := String(spec["id"])
		if bool(completed_ids.get(step_id, false)):
			continue
		if _step_done(sim, step_id):
			completed_ids[step_id] = true
			continue
		current_id = step_id
		return
	completed = true
	current_id = ""


func _step_done(sim, step_id: String) -> bool:
	match step_id:
		STEP_CAMERA:
			return seen_pan and seen_zoom and seen_rotate
		STEP_ROAD:
			return _player_road_count(sim) > road_baseline
		STEP_LUMBER:
			return _has_building(sim, Defs.BUILDING_LUMBER_CAMP)
		STEP_QUARRY:
			return _has_building(sim, Defs.BUILDING_QUARRY)
		STEP_CONNECT:
			return _building_connected(sim, Defs.BUILDING_LUMBER_CAMP) and _building_connected(sim, Defs.BUILDING_QUARRY)
		STEP_CARRIERS:
			return _count_type(sim, "carrier") >= 1
		STEP_FOOD:
			return _has_building(sim, Defs.BUILDING_FARM) or bool(sim.intention_completed.get(Intentions.ID_FEED, false))
		STEP_WATCHTOWER:
			return _has_building(sim, Defs.BUILDING_WATCHTOWER) or bool(sim.intention_completed.get(Intentions.ID_NIGHTFALL, false))
	return false


func _spec(step_id: String) -> Dictionary:
	for spec in catalog():
		if String(spec["id"]) == step_id:
			return spec
	return {}


func _index_of(step_id: String) -> int:
	var index := 0
	for spec in catalog():
		if String(spec["id"]) == step_id:
			return index
		index += 1
	return catalog().size()


func _has_building(sim, building_type: String) -> bool:
	if sim == null:
		return false
	for building in sim.buildings:
		if String(building.get("type", "")) == building_type:
			return true
	return false


func _building_connected(sim, building_type: String) -> bool:
	if sim == null:
		return false
	for building in sim.buildings:
		if String(building.get("type", "")) != building_type:
			continue
		if bool(building.get("connected", false)):
			return true
	return false


func _player_road_count(sim) -> int:
	if sim == null:
		return 0
	if sim.has_method("_count_connected_roads"):
		return int(sim._count_connected_roads())
	return int(sim.connected_roads.size()) if "connected_roads" in sim else 0


func _count_type(sim, worker_type: String) -> int:
	if sim == null:
		return 0
	var count := 0
	for worker in sim.get_workers():
		if String(worker.get("type", worker.get("worker_type", ""))) == worker_type:
			count += 1
	return count
