extends RefCounted

const BUILDING_TYPE_WAREHOUSE := "Warehouse"
const BUILDING_TYPE_WOODCUTTER := "Woodcutter"
const WORKER_TYPE_CARRIER := "Carrier"
const WORKER_STATE_IDLE := "Idle"
const WORKER_STATE_MOVING := "Moving"
const WORKER_STATE_BLOCKED := "Blocked"
const WORKER_STATE_MOVING_TO_PICKUP := "MovingToPickup"
const WORKER_STATE_PICKING_UP := "PickingUp"
const WORKER_STATE_MOVING_TO_DROPOFF := "MovingToDropoff"
const WORKER_STATE_DROPPING_OFF := "DroppingOff"
const RESOURCE_WOOD := "Wood"
const SAVE_PATH := "user://one_shard_save.json"
const FAILURE_NONE := "None"
const FAILURE_OUTSIDE_MAP := "OutsideMap"
const FAILURE_OVERLAP := "OverlapsExistingBuilding"
const FAILURE_UNSUPPORTED := "UnsupportedBuildingType"
const FAILURE_DESTINATION_BLOCKED := "DestinationBlocked"
const FAILURE_UNREACHABLE := "Unreachable"

var map_size := Vector2i.ZERO
var next_building_id := 1
var buildings: Array[Dictionary] = []
var occupied_tiles: Dictionary = {}
var tick_number := 0
var last_message := "No action yet."
var worker := {
	"id": 1,
	"type": WORKER_TYPE_CARRIER,
	"position": Vector2i(0, 0),
	"state": WORKER_STATE_IDLE,
	"path": [],
	"carry_capacity": 5,
	"carried_type": "",
	"carried_amount": 0,
	"source_id": 0,
	"destination_id": 0
}


func _init(width: int, height: int) -> void:
	map_size = Vector2i(width, height)


func place_building(building_type: String, position: Vector2i) -> Dictionary:
	var validation := validate_placement(building_type, position)
	if not validation["success"]:
		last_message = validation["message"]
		return validation

	var footprint := get_footprint(building_type)
	var building := {
		"id": next_building_id,
		"type": building_type,
		"position": position,
		"footprint": footprint,
		"inventory": 0,
		"storage_capacity": 100,
		"output": 0,
		"output_capacity": 10,
		"production_interval": 3,
		"ticks_until_production": 3
	}
	next_building_id += 1
	buildings.append(building)

	for tile in get_footprint_tiles(position, footprint):
		occupied_tiles[_tile_key(tile)] = building["id"]

	last_message = "%s placed." % building_type
	return {
		"success": true,
		"reason": FAILURE_NONE,
		"message": last_message,
		"building": building
	}


func validate_placement(building_type: String, position: Vector2i) -> Dictionary:
	if not is_supported_building_type(building_type):
		return _failure(FAILURE_UNSUPPORTED, "Unsupported building type.")

	var footprint := get_footprint(building_type)
	if not is_footprint_inside_map(position, footprint):
		return _failure(FAILURE_OUTSIDE_MAP, "%s does not fit inside the map." % building_type)

	for tile in get_footprint_tiles(position, footprint):
		if occupied_tiles.has(_tile_key(tile)):
			return _failure(FAILURE_OVERLAP, "%s overlaps an existing building." % building_type)

	return {
		"success": true,
		"reason": FAILURE_NONE,
		"message": "%s can be placed." % building_type
	}


func get_buildings() -> Array[Dictionary]:
	return buildings.duplicate(true)


func get_building_count() -> int:
	return buildings.size()


func move_worker_to(destination: Vector2i) -> Dictionary:
	var result := find_path(worker["position"], destination)
	if not result["success"]:
		worker["path"] = []
		worker["state"] = WORKER_STATE_BLOCKED
		last_message = result["message"]
		return result

	worker["path"] = result["path"]
	worker["state"] = WORKER_STATE_IDLE if worker["path"].is_empty() else WORKER_STATE_MOVING
	last_message = result["message"]
	return result


func advance_tick() -> void:
	tick_number += 1

	_tick_production()
	_advance_worker_movement()
	_process_carrier_hauling()


func get_worker() -> Dictionary:
	return worker.duplicate(true)


func get_worker_path() -> Array:
	return worker["path"].duplicate()


func get_tick_number() -> int:
	return tick_number


func get_last_message() -> String:
	return last_message


func save_to_file() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		last_message = "Save failed: %s." % error_string(FileAccess.get_open_error())
		return false

	file.store_string(JSON.stringify(_serialize_state(), "\t"))
	last_message = "Saved world."
	return true


func load_from_file() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		last_message = "No save file found."
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		last_message = "Load failed: %s." % error_string(FileAccess.get_open_error())
		return false

	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		last_message = "Load failed: save file is invalid."
		return false

	if typeof(json.data) != TYPE_DICTIONARY:
		last_message = "Load failed: save file has no world data."
		return false

	_restore_state(json.data)
	last_message = "Loaded world. Worker paths reset."
	return true


func get_total_woodcutter_output() -> int:
	var total := 0
	for building in buildings:
		if building["type"] == BUILDING_TYPE_WOODCUTTER:
			total += building["output"]
	return total


func get_total_warehouse_wood() -> int:
	var total := 0
	for building in buildings:
		if building["type"] == BUILDING_TYPE_WAREHOUSE:
			total += building["inventory"]
	return total


func _serialize_state() -> Dictionary:
	return {
		"version": 1,
		"map_size": _vector_to_data(map_size),
		"next_building_id": next_building_id,
		"tick_number": tick_number,
		"buildings": _serialize_buildings(),
		"workers": [_worker_to_data(worker)]
	}


func _restore_state(data: Dictionary) -> void:
	map_size = _vector_from_data(data.get("map_size", _vector_to_data(map_size)), map_size)
	next_building_id = int(data.get("next_building_id", 1))
	tick_number = int(data.get("tick_number", 0))

	buildings.clear()
	var saved_buildings: Array = data.get("buildings", [])
	for building_data in saved_buildings:
		if typeof(building_data) == TYPE_DICTIONARY:
			buildings.append(_building_from_data(building_data))
	_restore_occupied_tiles()

	var saved_workers: Array = data.get("workers", [])
	if not saved_workers.is_empty() and typeof(saved_workers[0]) == TYPE_DICTIONARY:
		worker = _worker_from_data(saved_workers[0])
	else:
		worker = _worker_from_data({})


func _serialize_buildings() -> Array:
	var saved_buildings: Array = []
	for building in buildings:
		saved_buildings.append(_building_to_data(building))
	return saved_buildings


func _building_to_data(building: Dictionary) -> Dictionary:
	return {
		"id": building["id"],
		"type": building["type"],
		"position": _vector_to_data(building["position"]),
		"footprint": _vector_to_data(building["footprint"]),
		"inventory": building["inventory"],
		"storage_capacity": building["storage_capacity"],
		"output": building["output"],
		"output_capacity": building["output_capacity"],
		"production_interval": building["production_interval"],
		"ticks_until_production": building["ticks_until_production"]
	}


func _building_from_data(data: Dictionary) -> Dictionary:
	var building_type := String(data.get("type", BUILDING_TYPE_WAREHOUSE))
	var footprint := _vector_from_data(data.get("footprint", _vector_to_data(get_footprint(building_type))), get_footprint(building_type))
	return {
		"id": int(data.get("id", next_building_id)),
		"type": building_type,
		"position": _vector_from_data(data.get("position", _vector_to_data(Vector2i.ZERO)), Vector2i.ZERO),
		"footprint": footprint,
		"inventory": int(data.get("inventory", 0)),
		"storage_capacity": int(data.get("storage_capacity", 100)),
		"output": int(data.get("output", 0)),
		"output_capacity": int(data.get("output_capacity", 10)),
		"production_interval": int(data.get("production_interval", 3)),
		"ticks_until_production": int(data.get("ticks_until_production", 3))
	}


func _worker_to_data(worker_data: Dictionary) -> Dictionary:
	return {
		"id": worker_data["id"],
		"type": worker_data["type"],
		"position": _vector_to_data(worker_data["position"]),
		"carry_capacity": worker_data["carry_capacity"],
		"carried_type": worker_data["carried_type"],
		"carried_amount": worker_data["carried_amount"],
		"source_id": worker_data["source_id"],
		"destination_id": worker_data["destination_id"]
	}


func _worker_from_data(data: Dictionary) -> Dictionary:
	return {
		"id": int(data.get("id", 1)),
		"type": String(data.get("type", WORKER_TYPE_CARRIER)),
		"position": _vector_from_data(data.get("position", _vector_to_data(Vector2i.ZERO)), Vector2i.ZERO),
		"state": WORKER_STATE_IDLE,
		"path": [],
		"carry_capacity": int(data.get("carry_capacity", 5)),
		"carried_type": String(data.get("carried_type", "")),
		"carried_amount": int(data.get("carried_amount", 0)),
		"source_id": int(data.get("source_id", 0)),
		"destination_id": int(data.get("destination_id", 0))
	}


func _restore_occupied_tiles() -> void:
	occupied_tiles.clear()
	for building in buildings:
		for tile in get_footprint_tiles(building["position"], building["footprint"]):
			if is_tile_inside_map(tile):
				occupied_tiles[_tile_key(tile)] = building["id"]


func _vector_to_data(vector: Vector2i) -> Dictionary:
	return {
		"x": vector.x,
		"y": vector.y
	}


func _vector_from_data(data, fallback: Vector2i) -> Vector2i:
	if typeof(data) != TYPE_DICTIONARY:
		return fallback

	return Vector2i(int(data.get("x", fallback.x)), int(data.get("y", fallback.y)))


func _advance_worker_movement() -> void:
	if worker["path"].is_empty():
		if worker["state"] == WORKER_STATE_MOVING:
			worker["state"] = WORKER_STATE_IDLE
		return

	worker["position"] = worker["path"].pop_front()
	if not worker["path"].is_empty():
		return

	if worker["state"] == WORKER_STATE_MOVING_TO_PICKUP:
		worker["state"] = WORKER_STATE_PICKING_UP
	elif worker["state"] == WORKER_STATE_MOVING_TO_DROPOFF:
		worker["state"] = WORKER_STATE_DROPPING_OFF
	elif worker["state"] == WORKER_STATE_MOVING:
		worker["state"] = WORKER_STATE_IDLE

func find_path(start: Vector2i, destination: Vector2i) -> Dictionary:
	if not is_tile_inside_map(start):
		return _failure(FAILURE_OUTSIDE_MAP, "Start is outside the map.")

	if not is_tile_inside_map(destination):
		return _failure(FAILURE_OUTSIDE_MAP, "Destination is outside the map.")

	if is_tile_occupied(destination):
		return _failure(FAILURE_DESTINATION_BLOCKED, "Destination is blocked.")

	if start == destination:
		return {
			"success": true,
			"reason": FAILURE_NONE,
			"message": "Worker is already there.",
			"path": []
		}

	var open_tiles: Array[Vector2i] = [start]
	var came_from: Dictionary = {}
	var cost_so_far: Dictionary = {}
	cost_so_far[_tile_key(start)] = 0

	while not open_tiles.is_empty():
		var current_index: int = _lowest_priority_index(open_tiles, cost_so_far, destination)
		var current: Vector2i = open_tiles[current_index]
		open_tiles.remove_at(current_index)

		if current == destination:
			var path := _reconstruct_path(start, destination, came_from)
			return {
				"success": true,
				"reason": FAILURE_NONE,
				"message": "Path found.",
				"path": path
			}

		for next in _neighbors(current):
			if is_tile_blocked(next):
				continue

			var current_key := _tile_key(current)
			var next_key := _tile_key(next)
			var new_cost: int = cost_so_far[current_key] + 1
			if cost_so_far.has(next_key) and new_cost >= cost_so_far[next_key]:
				continue

			cost_so_far[next_key] = new_cost
			came_from[next_key] = current
			if not open_tiles.has(next):
				open_tiles.append(next)

	return _failure(FAILURE_UNREACHABLE, "Destination is unreachable.")


func _tick_production() -> void:
	for building in buildings:
		if building["type"] != BUILDING_TYPE_WOODCUTTER:
			continue

		if building["output"] >= building["output_capacity"]:
			continue

		building["ticks_until_production"] -= 1
		if building["ticks_until_production"] > 0:
			continue

		building["output"] += 1
		building["ticks_until_production"] = building["production_interval"]


func _process_carrier_hauling() -> void:
	if worker["type"] != WORKER_TYPE_CARRIER:
		return

	if worker["state"] == WORKER_STATE_IDLE:
		if worker["carried_amount"] > 0:
			_assign_dropoff()
		else:
			_assign_pickup()
		return

	if worker["state"] == WORKER_STATE_PICKING_UP:
		_pick_up_and_assign_dropoff()
		return

	if worker["state"] == WORKER_STATE_DROPPING_OFF:
		_deposit_carried_wood()


func _assign_pickup() -> bool:
	for woodcutter in buildings:
		if woodcutter["type"] != BUILDING_TYPE_WOODCUTTER or woodcutter["output"] <= 0:
			continue

		for warehouse in buildings:
			if warehouse["type"] != BUILDING_TYPE_WAREHOUSE:
				continue
			if warehouse["inventory"] >= warehouse["storage_capacity"]:
				continue

			var path_result := _find_path_to_building(worker["position"], woodcutter)
			if not path_result["success"]:
				continue

			worker["source_id"] = woodcutter["id"]
			worker["destination_id"] = warehouse["id"]
			_assign_worker_path(path_result["path"], WORKER_STATE_MOVING_TO_PICKUP, WORKER_STATE_PICKING_UP)
			last_message = "Carrier moving to Woodcutter."
			return true

	return false


func _pick_up_and_assign_dropoff() -> bool:
	var woodcutter := _find_building_by_id(worker["source_id"])
	var warehouse := _find_building_by_id(worker["destination_id"])
	if woodcutter.is_empty() or warehouse.is_empty():
		worker["state"] = WORKER_STATE_BLOCKED
		last_message = "Carrier task target is missing."
		return false

	var amount: int = min(worker["carry_capacity"], min(woodcutter["output"], warehouse["storage_capacity"] - warehouse["inventory"]))
	if amount <= 0:
		_clear_worker_task()
		return false

	var path_result := _find_path_to_building(worker["position"], warehouse)
	if not path_result["success"]:
		worker["state"] = WORKER_STATE_BLOCKED
		last_message = path_result["message"]
		return false

	woodcutter["output"] -= amount
	worker["carried_type"] = RESOURCE_WOOD
	worker["carried_amount"] = amount
	_assign_worker_path(path_result["path"], WORKER_STATE_MOVING_TO_DROPOFF, WORKER_STATE_DROPPING_OFF)
	last_message = "Carrier picked up %d Wood." % amount
	return true


func _assign_dropoff() -> bool:
	var warehouse := _find_building_by_id(worker["destination_id"])
	if warehouse.is_empty():
		worker["state"] = WORKER_STATE_BLOCKED
		last_message = "Carrier destination is missing."
		return false

	var path_result := _find_path_to_building(worker["position"], warehouse)
	if not path_result["success"]:
		worker["state"] = WORKER_STATE_BLOCKED
		last_message = path_result["message"]
		return false

	_assign_worker_path(path_result["path"], WORKER_STATE_MOVING_TO_DROPOFF, WORKER_STATE_DROPPING_OFF)
	last_message = "Carrier moving to Warehouse."
	return true


func _deposit_carried_wood() -> bool:
	var warehouse := _find_building_by_id(worker["destination_id"])
	if warehouse.is_empty() or worker["carried_type"] != RESOURCE_WOOD or worker["carried_amount"] <= 0:
		worker["state"] = WORKER_STATE_BLOCKED
		last_message = "Carrier cannot deposit."
		return false

	if warehouse["inventory"] + worker["carried_amount"] > warehouse["storage_capacity"]:
		worker["state"] = WORKER_STATE_BLOCKED
		last_message = "Warehouse is full."
		return false

	warehouse["inventory"] += worker["carried_amount"]
	last_message = "Carrier delivered %d Wood." % worker["carried_amount"]
	_clear_worker_task()
	return true


func _assign_worker_path(path: Array, moving_state: String, arrived_state: String) -> void:
	worker["path"] = path
	worker["state"] = arrived_state if worker["path"].is_empty() else moving_state


func _clear_worker_task() -> void:
	worker["path"] = []
	worker["carried_type"] = ""
	worker["carried_amount"] = 0
	worker["source_id"] = 0
	worker["destination_id"] = 0
	worker["state"] = WORKER_STATE_IDLE


func _find_path_to_building(start: Vector2i, building: Dictionary) -> Dictionary:
	var best_result := {}

	for tile in _interaction_tiles(building):
		var path_result := find_path(start, tile)
		if not path_result["success"]:
			continue

		if best_result.is_empty() or path_result["path"].size() < best_result["path"].size():
			best_result = path_result

	if best_result.is_empty():
		return _failure(FAILURE_UNREACHABLE, "No reachable interaction tile.")

	return best_result


func _interaction_tiles(building: Dictionary) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var seen: Dictionary = {}

	for occupied_tile in get_footprint_tiles(building["position"], building["footprint"]):
		for neighbor in _neighbors(occupied_tile):
			var key := _tile_key(neighbor)
			if not is_tile_inside_map(neighbor) or is_tile_occupied(neighbor) or seen.has(key):
				continue

			seen[key] = true
			tiles.append(neighbor)

	return tiles


func _find_building_by_id(id: int) -> Dictionary:
	for building in buildings:
		if building["id"] == id:
			return building

	return {}


func get_footprint(building_type: String) -> Vector2i:
	if building_type == BUILDING_TYPE_WAREHOUSE:
		return Vector2i(2, 2)

	if building_type == BUILDING_TYPE_WOODCUTTER:
		return Vector2i(2, 2)

	return Vector2i.ZERO


func get_footprint_tiles(position: Vector2i, footprint: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []

	for y in range(footprint.y):
		for x in range(footprint.x):
			tiles.append(Vector2i(position.x + x, position.y + y))

	return tiles


func is_supported_building_type(building_type: String) -> bool:
	return building_type == BUILDING_TYPE_WAREHOUSE or building_type == BUILDING_TYPE_WOODCUTTER


func is_footprint_inside_map(position: Vector2i, footprint: Vector2i) -> bool:
	return position.x >= 0 \
		and position.y >= 0 \
		and position.x + footprint.x <= map_size.x \
		and position.y + footprint.y <= map_size.y


func is_tile_inside_map(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < map_size.x and tile.y < map_size.y


func is_tile_occupied(tile: Vector2i) -> bool:
	return occupied_tiles.has(_tile_key(tile))


func is_tile_blocked(tile: Vector2i) -> bool:
	return not is_tile_inside_map(tile) or is_tile_occupied(tile)


func _failure(reason: String, message: String) -> Dictionary:
	return {
		"success": false,
		"reason": reason,
		"message": message
	}


func _lowest_priority_index(open_tiles: Array[Vector2i], cost_so_far: Dictionary, destination: Vector2i) -> int:
	var best_index := 0
	var best_priority := _priority(open_tiles[0], cost_so_far, destination)

	for index in range(1, open_tiles.size()):
		var priority := _priority(open_tiles[index], cost_so_far, destination)
		if priority < best_priority:
			best_priority = priority
			best_index = index

	return best_index


func _priority(tile: Vector2i, cost_so_far: Dictionary, destination: Vector2i) -> int:
	return cost_so_far[_tile_key(tile)] + _manhattan_distance(tile, destination)


func _manhattan_distance(first: Vector2i, second: Vector2i) -> int:
	return abs(first.x - second.x) + abs(first.y - second.y)


func _neighbors(tile: Vector2i) -> Array[Vector2i]:
	return [
		Vector2i(tile.x + 1, tile.y),
		Vector2i(tile.x - 1, tile.y),
		Vector2i(tile.x, tile.y + 1),
		Vector2i(tile.x, tile.y - 1)
	]


func _reconstruct_path(start: Vector2i, destination: Vector2i, came_from: Dictionary) -> Array:
	var path: Array = []
	var current := destination

	while current != start:
		path.append(current)
		current = came_from[_tile_key(current)]

	path.reverse()
	return path


func _tile_key(tile: Vector2i) -> String:
	return "%d,%d" % [tile.x, tile.y]
