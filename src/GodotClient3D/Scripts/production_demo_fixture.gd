class_name ProductionDemoFixture3D
extends RefCounted

const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")

const STAGES := ["fresh", "early", "placement", "construction", "lumber", "second_chain", "developed", "reloaded"]

var road_ids: Array[int] = []
var building_ids: Dictionary = {}
var placement_candidates: Dictionary = {}
var report: Array[String] = []


func apply(simulation, stage: String) -> Dictionary:
	if stage not in STAGES:
		stage = "developed"
	report.clear()
	road_ids.clear()
	building_ids.clear()
	placement_candidates.clear()
	if stage == "fresh":
		return _result(simulation, stage)
	_build_road_spine(simulation, 9)
	var house_site := _find_best_site(simulation, Defs.BUILDING_HOUSE, simulation.town_hall_position + Vector2i(5, 5))
	if house_site.x >= 0:
		building_ids[Defs.BUILDING_HOUSE] = _request_and_complete(simulation, Defs.BUILDING_HOUSE, house_site)
	_advance_ticks(simulation, 520)
	var lumber_site := _ensure_site(simulation, Defs.BUILDING_LUMBER_CAMP, simulation.town_hall_position + Vector2i(9, 6))
	placement_candidates[Defs.BUILDING_LUMBER_CAMP] = lumber_site
	if stage in ["early", "placement"]:
		return _result(simulation, stage)
	var lumber_result: Dictionary = simulation.request_build(Defs.BUILDING_LUMBER_CAMP, lumber_site)
	if not bool(lumber_result.get("success", false)):
		report.append("Lumber request failed: %s" % String(lumber_result.get("message", "")))
		return _result(simulation, stage)
	var lumber_id := int(Dictionary(lumber_result.get("building", {})).get("id", 0))
	building_ids[Defs.BUILDING_LUMBER_CAMP] = lumber_id
	if stage == "construction":
		_advance_until_construction_activity(simulation, lumber_id, 600)
		return _result(simulation, stage)
	_advance_until_complete(simulation, lumber_id, 1200)
	_advance_until_cargo_or_output(simulation, Defs.RESOURCE_WOOD, lumber_id, 1200)
	if stage == "lumber":
		return _result(simulation, stage)
	_advance_ticks(simulation, 850)
	var farm_site := _ensure_site(simulation, Defs.BUILDING_FARM, simulation.town_hall_position + Vector2i(7, 9))
	placement_candidates[Defs.BUILDING_FARM] = farm_site
	if farm_site.x >= 0:
		building_ids[Defs.BUILDING_FARM] = _request_and_complete(simulation, Defs.BUILDING_FARM, farm_site)
		_advance_until_cargo_or_output(simulation, Defs.RESOURCE_WHEAT, int(building_ids.get(Defs.BUILDING_FARM, 0)), 1800)
	if stage == "second_chain":
		return _result(simulation, stage)
	var storehouse_site := _ensure_site(simulation, Defs.BUILDING_STOREHOUSE, simulation.town_hall_position + Vector2i(5, 10))
	if storehouse_site.x >= 0:
		building_ids[Defs.BUILDING_STOREHOUSE] = _request_and_complete(simulation, Defs.BUILDING_STOREHOUSE, storehouse_site)
	var sawmill_site := _ensure_site(simulation, Defs.BUILDING_SAWMILL, simulation.town_hall_position + Vector2i(10, 8))
	if sawmill_site.x >= 0:
		building_ids[Defs.BUILDING_SAWMILL] = _request_and_complete(simulation, Defs.BUILDING_SAWMILL, sawmill_site)
	_advance_ticks(simulation, 900)
	if stage != "developed":
		return _result(simulation, stage)
	_advance_until_stock(simulation, Defs.RESOURCE_STONE, 6, 900)
	_advance_until_stock(simulation, Defs.RESOURCE_PLANKS, 8, 900)
	var quarry_site := _ensure_site(simulation, Defs.BUILDING_QUARRY, simulation.town_hall_position + Vector2i(12, 5))
	if quarry_site.x >= 0:
		building_ids[Defs.BUILDING_QUARRY] = _request_and_complete(simulation, Defs.BUILDING_QUARRY, quarry_site)
	_advance_until_stock(simulation, Defs.RESOURCE_STONE, 8, 800)
	_advance_until_stock(simulation, Defs.RESOURCE_PLANKS, 8, 800)
	var house_two := _ensure_site(simulation, Defs.BUILDING_HOUSE, simulation.town_hall_position + Vector2i(4, 7))
	if house_two.x >= 0:
		building_ids["HOUSE_2"] = _request_and_complete(simulation, Defs.BUILDING_HOUSE, house_two)
	var bakery_site := _ensure_site(simulation, Defs.BUILDING_BAKERY, simulation.town_hall_position + Vector2i(8, 11))
	if bakery_site.x >= 0:
		building_ids[Defs.BUILDING_BAKERY] = _request_and_complete(simulation, Defs.BUILDING_BAKERY, bakery_site)
	var barracks_site := _ensure_site(simulation, Defs.BUILDING_BARRACKS, simulation.town_hall_position + Vector2i(6, 3))
	if barracks_site.x >= 0:
		building_ids[Defs.BUILDING_BARRACKS] = _request_and_complete(simulation, Defs.BUILDING_BARRACKS, barracks_site)
	var tower_site := _ensure_site(simulation, Defs.BUILDING_WATCHTOWER, simulation.town_hall_position + Vector2i(3, 2))
	if tower_site.x >= 0:
		building_ids[Defs.BUILDING_WATCHTOWER] = _request_and_complete(simulation, Defs.BUILDING_WATCHTOWER, tower_site)
	_advance_ticks(simulation, 700)
	simulation.is_night = false
	simulation.phase_time = 95.0
	simulation.enemies.clear()
	simulation.dawn_summary = {}
	return _result(simulation, stage)


func _build_road_spine(simulation, count: int) -> void:
	var target: Vector2i = simulation.town_hall_position + Vector2i(11, 7)
	for index in count:
		var candidate: Vector2i = _best_road_extension(simulation, target + Vector2i(index / 5, index % 3))
		if candidate.x < 0:
			report.append("Road spine stopped after %d extensions." % index)
			return
		var result: Dictionary = simulation.request_build(Defs.BUILDING_ROAD, candidate)
		if not bool(result.get("success", false)):
			report.append("Road request rejected: %s" % String(result.get("message", "")))
			return
		var id := int(Dictionary(result.get("building", {})).get("id", 0))
		road_ids.append(id)
		_advance_until_complete(simulation, id, 500)


func _best_road_extension(simulation, target: Vector2i) -> Vector2i:
	var candidates: Dictionary = {}
	for building_value in simulation.get_buildings():
		var building: Dictionary = building_value
		if String(building.get("type", "")) != Defs.BUILDING_ROAD or bool(building.get("construction", false)):
			continue
		var origin: Vector2i = building.get("position", Vector2i.ZERO)
		for direction: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var tile: Vector2i = origin + direction
			var key := "%d,%d" % [tile.x, tile.y]
			if candidates.has(key):
				continue
			var validation: Dictionary = simulation.validate_placement(Defs.BUILDING_ROAD, tile)
			if bool(validation.get("success", false)):
				candidates[key] = tile
	var best := Vector2i(-1, -1)
	var best_score := 1000000
	for key_value in candidates:
		var tile: Vector2i = candidates[key_value]
		var score := absi(tile.x - target.x) + absi(tile.y - target.y)
		if score < best_score or (score == best_score and (tile.y < best.y or (tile.y == best.y and tile.x < best.x))):
			best = tile
			best_score = score
	return best


func _ensure_site(simulation, building_type: String, target: Vector2i) -> Vector2i:
	var site := _find_best_site(simulation, building_type, target)
	var extensions := 0
	while site.x < 0 and extensions < 10:
		var road_tile := _best_road_extension(simulation, target)
		if road_tile.x < 0:
			break
		var result: Dictionary = simulation.request_build(Defs.BUILDING_ROAD, road_tile)
		if not bool(result.get("success", false)):
			break
		var id := int(Dictionary(result.get("building", {})).get("id", 0))
		road_ids.append(id)
		_advance_until_complete(simulation, id, 500)
		extensions += 1
		site = _find_best_site(simulation, building_type, target)
	if site.x < 0:
		report.append("No valid %s site found through authoritative validation." % Defs.building_name(building_type))
	return site


func _find_best_site(simulation, building_type: String, target: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_score := 1000000
	for y in range(simulation.map_size.y):
		for x in range(simulation.map_size.x):
			var tile := Vector2i(x, y)
			var validation: Dictionary = simulation.validate_placement(building_type, tile)
			if not bool(validation.get("success", false)):
				continue
			var score := absi(tile.x - target.x) + absi(tile.y - target.y)
			if score < best_score:
				best = tile
				best_score = score
	return best


func _request_and_complete(simulation, building_type: String, tile: Vector2i) -> int:
	var result: Dictionary = simulation.request_build(building_type, tile)
	if not bool(result.get("success", false)):
		report.append("%s request failed: %s" % [Defs.building_name(building_type), String(result.get("message", ""))])
		return 0
	var id := int(Dictionary(result.get("building", {})).get("id", 0))
	_advance_until_complete(simulation, id, 1600)
	return id


func _advance_until_complete(simulation, building_id: int, max_ticks: int) -> bool:
	for index in max_ticks:
		var building: Dictionary = simulation.get_building_by_id(building_id)
		if not building.is_empty() and not bool(building.get("construction", false)):
			return true
		simulation.advance_tick()
	report.append("Construction %d did not complete within %d ticks." % [building_id, max_ticks])
	return false


func _advance_until_construction_activity(simulation, building_id: int, max_ticks: int) -> bool:
	for index in max_ticks:
		var building: Dictionary = simulation.get_building_by_id(building_id)
		if building.is_empty() or not bool(building.get("construction", false)):
			return false
		var total := maxf(0.001, float(building.get("construction_total", 1.0)))
		var fraction := 1.0 - float(building.get("construction_remaining", total)) / total
		var has_builder := false
		for worker in simulation.get_workers():
			if String(worker.get("state", "")) == "Building":
				has_builder = true
				break
		if has_builder or (fraction >= 0.12 and fraction <= 0.85):
			return true
		simulation.advance_tick()
	return false


func _advance_until_cargo_or_output(simulation, resource_type: String, building_id: int, max_ticks: int) -> bool:
	for index in max_ticks:
		for worker in simulation.get_workers():
			if String(worker.get("carried_resource", "")) == resource_type and int(worker.get("carried_amount", 0)) > 0:
				return true
		simulation.advance_tick()
	var building: Dictionary = simulation.get_building_by_id(building_id)
	return not building.is_empty() and int(building.get("local_inventory", {}).get(resource_type, 0)) > 0


func _advance_ticks(simulation, count: int) -> void:
	for index in count:
		simulation.advance_tick()


func _advance_until_stock(simulation, resource_type: String, amount: int, max_ticks: int) -> bool:
	for index in max_ticks:
		if int(simulation.central_inventory.get(resource_type, 0)) >= amount:
			return true
		simulation.advance_tick()
	report.append("Stock wait for %s x%d timed out." % [resource_type, amount])
	return false


func _result(simulation, stage: String) -> Dictionary:
	return {
		"success": report.is_empty(),
		"stage": stage,
		"report": report.duplicate(),
		"road_ids": road_ids.duplicate(),
		"building_ids": building_ids.duplicate(true),
		"placement_candidates": placement_candidates.duplicate(true),
		"tick": simulation.get_tick_number(),
		"resources": simulation.get_resources(),
	}
