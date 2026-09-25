extends RefCounted

const Defs = preload("one_shard_defs.gd")
const Tuning = preload("one_shard_rivalry_tuning.gd")
const SOVEREIGN_STUCK_SECONDS := 2.5

var _simulation_ref: WeakRef
var simulation:
	get:
		return _simulation_ref.get_ref() if _simulation_ref != null else null
	set(value):
		_simulation_ref = weakref(value) if value != null else null
var realms: Dictionary = {}
var structures: Array = []
var wyrd_sites: Array = []
var dropped_wyrd: Array = []
var combat_events: Array = []
var event_log: Array[String] = []

var match_state := Tuning.MATCH_INITIALISING
var ai_current_goal := "Establishing the rival realm"
var ai_goal_target := Vector2i(-1, -1)
var ai_plan_timer := 0.0
var next_structure_id := 1
var next_worker_id := 1
var elapsed_seconds := 0.0
var was_night := false
var debug_enabled := Tuning.DEBUG_ENABLED_DEFAULT
var navigation_failures: Array[String] = []
var rng := RandomNumberGenerator.new()
var player_has_seen_rival_sovereign := false
var player_observed_rival_structures: Dictionary = {}


func setup(owner_simulation, seed_value: int) -> void:
	simulation = owner_simulation
	rng.seed = seed_value + 8191
	structures.clear()
	wyrd_sites.clear()
	dropped_wyrd.clear()
	combat_events.clear()
	event_log.clear()
	navigation_failures.clear()
	player_observed_rival_structures.clear()
	player_has_seen_rival_sovereign = false
	next_structure_id = 1
	next_worker_id = 1
	elapsed_seconds = 0.0
	ai_plan_timer = 0.0
	was_night = false
	match_state = Tuning.MATCH_ACTIVE

	if not simulation.central_inventory.has(Defs.RESOURCE_WYRD):
		simulation.central_inventory[Defs.RESOURCE_WYRD] = Tuning.STARTING_WYRD
	var player_resources: Dictionary = simulation.central_inventory
	var ai_resources := Defs.empty_inventory()
	ai_resources[Defs.RESOURCE_WOOD] = int(simulation.central_inventory.get(Defs.RESOURCE_WOOD, 0))
	ai_resources[Defs.RESOURCE_WYRD] = Tuning.STARTING_WYRD

	realms = {
		Tuning.PLAYER_REALM: _create_realm(
			Tuning.PLAYER_REALM,
			player_resources,
			simulation.town_hall_position,
			simulation._town_hall_entrance_tile()
		),
		Tuning.AI_REALM: _create_realm(
			Tuning.AI_REALM,
			ai_resources,
			simulation.rival_town_hall_position,
			simulation._rival_town_hall_entrance_tile()
		)
	}
	_create_wyrd_sites()
	_log_event("Two realms rise on opposite sides of the Shard.")


func _create_realm(realm_id: String, resources: Dictionary, home: Vector2i, entrance: Vector2i) -> Dictionary:
	var roads := {_key(entrance): true}
	var realm := {
		"id": realm_id,
		"resources": resources,
		"home": home,
		"entrance": entrance,
		"roads": roads,
		"structures": [],
		"workers": [],
		"claim": {
			"active": false,
			"outpost_id": 0,
			"status": "No Claimant Outpost",
			"night_progress": 0.0,
			"binding_progress": 0.0,
			"night_started_valid": false,
			"night_broken": false,
			"nights_held": 0,
			"last_pause_reason": "",
			"warning_stage": 0
		},
		"sovereign": _create_sovereign(realm_id, entrance),
		"knowledge": {
			"player_position": Vector2(-999.0, -999.0),
			"player_position_age": 9999.0,
			"known_player_roads": {},
			"known_player_structures": {},
			"known_player_lumen": {},
			"recent_hostile_activity": Vector2(-999.0, -999.0),
			"hostile_activity_age": 9999.0
		}
	}
	if realm_id == Tuning.AI_REALM:
		for index in range(Tuning.STARTING_WORKERS):
			realm["workers"].append(_create_worker(realm_id, index, entrance))
	return realm


func _create_sovereign(realm_id: String, entrance: Vector2i) -> Dictionary:
	var is_player := realm_id == Tuning.PLAYER_REALM
	var max_hp := Tuning.PLAYER_SOVEREIGN_MAX_HP if is_player else Tuning.SOVEREIGN_MAX_HP
	return {
		"realm_id": realm_id,
		"position": Vector2(entrance),
		"previous_position": Vector2(entrance),
		"move_target": Vector2(entrance),
		"move_input": Vector2.ZERO,
		"move_path": [],
		"stuck_seconds": 0.0,
		"recovery_count": 0,
		"max_hp": max_hp,
		"hp": max_hp,
		"move_speed": Tuning.PLAYER_SOVEREIGN_MOVE_SPEED if is_player else Tuning.SOVEREIGN_MOVE_SPEED,
		"attack_damage": Tuning.PLAYER_SOVEREIGN_ATTACK_DAMAGE if is_player else Tuning.SOVEREIGN_ATTACK_DAMAGE,
		"attack_cooldown_seconds": Tuning.PLAYER_SOVEREIGN_ATTACK_COOLDOWN if is_player else Tuning.SOVEREIGN_ATTACK_COOLDOWN,
		"alive": true,
		"respawn_remaining": 0.0,
		"attack_cooldown": 0.0,
		"invulnerability": 0.0,
		"extracting": false,
		"extraction_progress": 0.0,
		"extraction_site": -1,
		"damage_flash": 0.0,
		"last_hit_from": ""
	}


func _create_worker(realm_id: String, index: int, entrance: Vector2i) -> Dictionary:
	var worker := {
		"id": next_worker_id,
		"realm_id": realm_id,
		"position": Vector2(entrance) + Vector2(float(index) * 0.45, float(index) * 0.25),
		"home_position": entrance,
		"target": Vector2i(-1, -1),
		"work_position": Vector2i(-1, -1),
		"path": [],
		"state": "Seeking trees",
		"harvest_progress": 0.0
	}
	next_worker_id += 1
	return worker


func _create_wyrd_sites() -> void:
	var offsets := [
		Vector2i(-5, -1),
		Vector2i(5, 1),
		Vector2i(-1, 5),
		Vector2i(1, -5)
	]
	for offset in offsets:
		var position: Vector2i = simulation.shard_position + offset
		if not simulation.is_inside_map(position):
			continue
		var founding_center: Vector2i = simulation._footprint_center(simulation.town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
		if simulation.is_revealed(position) or simulation._tile_distance(position, founding_center) <= float(simulation.INITIAL_REVEAL_RADIUS + 2):
			continue
		simulation._clear_area(position, 0)
		wyrd_sites.append({
			"position": position,
			"cooldown": 0.0,
			"pulse": rng.randf_range(0.0, TAU)
		})


func advance(delta: float, is_night: bool, phase_time: float, phase_length: float) -> void:
	elapsed_seconds += delta
	_update_site_cooldowns(delta)
	_update_workers(delta, is_night or simulation.is_gate_closed())
	_update_sovereigns(delta)
	_update_dropped_wyrd()
	_update_ai_knowledge(delta)
	_update_player_observations()
	_update_ai(delta)
	_update_claims(delta, is_night, phase_time, phase_length)
	_update_combat_events(delta)
	if is_night and not was_night:
		_on_night_started()
	elif not is_night and was_night:
		_on_dawn(phase_length)
	was_night = is_night


func get_realm(realm_id: String) -> Dictionary:
	return realms.get(realm_id, {})


func get_resources(realm_id: String) -> Dictionary:
	var realm := get_realm(realm_id)
	return realm.get("resources", {}) if not realm.is_empty() else {}


func get_resource(realm_id: String, resource_type: String) -> int:
	return int(get_resources(realm_id).get(resource_type, 0))


func add_resource(realm_id: String, resource_type: String, amount: int) -> void:
	var resources := get_resources(realm_id)
	if resources.is_empty():
		return
	resources[resource_type] = max(0, int(resources.get(resource_type, 0)) + amount)


func can_spend(realm_id: String, cost: Dictionary) -> bool:
	var resources := get_resources(realm_id)
	for resource_type in cost:
		if int(resources.get(resource_type, 0)) < int(cost[resource_type]):
			return false
	return true


func spend(realm_id: String, cost: Dictionary) -> bool:
	if not can_spend(realm_id, cost):
		return false
	var resources := get_resources(realm_id)
	for resource_type in cost:
		resources[resource_type] = int(resources.get(resource_type, 0)) - int(cost[resource_type])
	return true


func validate_road(realm_id: String, tile: Vector2i) -> Dictionary:
	if match_state not in [
		Tuning.MATCH_ACTIVE,
		Tuning.MATCH_PLAYER_CLAIMING,
		Tuning.MATCH_AI_CLAIMING
	]:
		return _failure("MatchFinished", "The match has ended.")
	if not realms.has(realm_id):
		return _failure("Realm", "Unknown realm.")
	if not simulation.is_inside_map(tile):
		return _failure("OutsideMap", "Road is outside the province.")
	if realm_id == Tuning.PLAYER_REALM and not simulation.is_revealed(tile):
		return _failure("Fog", "Scout this tile before laying a road.")
	if simulation.get_tile(tile) != Defs.TILE_GRASS:
		return _failure("Terrain", "Clear trees and rocks before laying a road.")
	if _is_rivalry_occupied(tile):
		return _failure("Occupied", "That tile is occupied.")
	var existing: Dictionary = simulation.get_building_at_tile(tile)
	if not existing.is_empty():
		return _failure("Occupied", "That tile already contains a structure.")
	var roads: Dictionary = realms[realm_id]["roads"]
	if roads.has(_key(tile)):
		return _failure("Occupied", "A road already occupies that tile.")
	var connected := false
	for neighbor in _neighbors(tile):
		if roads.has(_key(neighbor)):
			connected = true
			break
	if not connected:
		return _failure("RoadConnection", "Roads must extend from your Town Hall network.")
	if not _road_grade_valid(tile, roads):
		return _failure("Slope", "Roads can climb at most two height steps.")
	if get_resource(realm_id, Defs.RESOURCE_WOOD) < Tuning.ROAD_WOOD_COST:
		return _failure("Resources", "Road needs %d Wood." % Tuning.ROAD_WOOD_COST)
	return _success("Road can be built.")


func request_road(realm_id: String, tile: Vector2i) -> Dictionary:
	var validation := validate_road(realm_id, tile)
	if not bool(validation.get("success", false)):
		return validation
	if not spend(realm_id, {Defs.RESOURCE_WOOD: Tuning.ROAD_WOOD_COST}):
		return _failure("Resources", "Not enough Wood.")
	realms[realm_id]["roads"][_key(tile)] = true
	if realm_id == Tuning.PLAYER_REALM and simulation.has_method("_commit_player_rivalry_road"):
		simulation._commit_player_rivalry_road(tile)
	if realm_id == Tuning.PLAYER_REALM and simulation.has_method("_reveal_radius"):
		simulation._reveal_radius(tile, 2)
	_log_event("%s laid a road at %s." % [_realm_name(realm_id), _format_tile(tile)])
	return {"success": true, "message": "Road built.", "tile": tile}


func complete_player_road(tile: Vector2i) -> void:
	if not realms.has(Tuning.PLAYER_REALM):
		return
	realms[Tuning.PLAYER_REALM]["roads"][_key(tile)] = true
	if simulation != null and simulation.has_method("_reveal_radius"):
		simulation._reveal_radius(tile, 2)
	_log_event("Player peasant completed a road at %s." % _format_tile(tile))


func validate_structure(realm_id: String, structure_type: String, tile: Vector2i) -> Dictionary:
	var definition := Tuning.structure_definition(structure_type)
	if definition.is_empty():
		return _failure("Unsupported", "That rivalry structure is unavailable.")
	if not realms.has(realm_id):
		return _failure("Realm", "Unknown realm.")
	var footprint: Vector2i = definition.get("footprint", Vector2i.ONE)
	var tiles := _footprint_tiles(tile, footprint)
	if tiles.is_empty():
		return _failure("OutsideMap", "The footprint extends outside the province.")
	for footprint_tile in tiles:
		if not simulation.is_inside_map(footprint_tile):
			return _failure("OutsideMap", "The footprint extends outside the province.")
		if realm_id == Tuning.PLAYER_REALM and not simulation.is_revealed(footprint_tile):
			return _failure("Fog", "Scout the whole building site first.")
		if simulation.get_tile(footprint_tile) != Defs.TILE_GRASS:
			return _failure("Terrain", "Clear trees and rocks from the footprint first.")
		if _is_rivalry_occupied(footprint_tile) or not simulation.get_building_at_tile(footprint_tile).is_empty():
			return _failure("Occupied", "The footprint overlaps another structure.")
	if not _footprint_flat_enough(tiles):
		return _failure("Slope", "Choose a flatter building site.")

	var cost := {
		Defs.RESOURCE_WOOD: int(definition.get("wood_cost", 0)),
		Defs.RESOURCE_WYRD: int(definition.get("wyrd_cost", 0))
	}
	if not can_spend(realm_id, cost):
		return _failure("Resources", "%s needs %s." % [
			Tuning.structure_name(structure_type),
			Tuning.structure_cost_text(structure_type)
		])

	var center := _footprint_center(tile, footprint)
	if structure_type == Tuning.STRUCTURE_LUMEN_PILLAR:
		if not is_lumen_connected_at(realm_id, center):
			return _failure("LumenConnection", "Place the Pillar inside your connected Lumen territory.")
		if not _footprint_touches_owned_road(realm_id, tiles):
			return _failure("RoadConnection", "Lumen Pillars must touch your connected road.")
	elif structure_type == Tuning.STRUCTURE_CLAIMANT_OUTPOST:
		if not _footprint_touches_owned_road(realm_id, tiles):
			return _failure("RoadConnection", "The Outpost needs a continuous owned road to its Town Hall.")
	if structure_type == Tuning.STRUCTURE_LUMEN_PILLAR:
		return _success("Lumen Pillar extends your connected claim-power network toward the Shard.")
	return _success("%s can be built." % Tuning.structure_name(structure_type))


func request_structure(realm_id: String, structure_type: String, tile: Vector2i) -> Dictionary:
	var validation := validate_structure(realm_id, structure_type, tile)
	if not bool(validation.get("success", false)):
		return validation
	var definition := Tuning.structure_definition(structure_type)
	var cost := {
		Defs.RESOURCE_WOOD: int(definition.get("wood_cost", 0)),
		Defs.RESOURCE_WYRD: int(definition.get("wyrd_cost", 0))
	}
	if not spend(realm_id, cost):
		return _failure("Resources", "The realm can no longer afford that structure.")
	var structure := {
		"id": next_structure_id,
		"realm_id": realm_id,
		"type": structure_type,
		"position": tile,
		"footprint": definition.get("footprint", Vector2i.ONE),
		"hp": int(definition.get("max_hp", 100)),
		"max_hp": int(definition.get("max_hp", 100)),
		"active": true,
		"connected": true,
		"damage_flash": 0.0
	}
	next_structure_id += 1
	structures.append(structure)
	realms[realm_id]["structures"].append(structure["id"])
	if structure_type == Tuning.STRUCTURE_CLAIMANT_OUTPOST:
		var structure_center := _structure_center(structure)
		if structure_center.distance_to(Vector2(simulation.shard_position)) <= Tuning.SHARD_BUILD_RADIUS:
			realms[realm_id]["claim"]["outpost_id"] = structure["id"]
			realms[realm_id]["claim"]["status"] = "Claim Outpost ready; connect its road and Lumen network."
	_log_event("%s built %s." % [_realm_name(realm_id), Tuning.structure_name(structure_type)])
	return {"success": true, "message": "%s built." % Tuning.structure_name(structure_type), "structure": structure}


func get_roads(realm_id: String) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not realms.has(realm_id):
		return result
	for key in realms[realm_id]["roads"]:
		result.append(_tile_from_key(String(key)))
	return result


func owns_road(realm_id: String, tile: Vector2i) -> bool:
	return realms.has(realm_id) and realms[realm_id]["roads"].has(_key(tile))


func road_connected_to_home(realm_id: String, tile: Vector2i) -> bool:
	if not owns_road(realm_id, tile):
		return false
	var entrance: Vector2i = realms[realm_id]["entrance"]
	var frontier: Array[Vector2i] = [entrance]
	var visited := {_key(entrance): true}
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		if current == tile:
			return true
		for neighbor in _neighbors(current):
			var key := _key(neighbor)
			if not visited.has(key) and owns_road(realm_id, neighbor):
				visited[key] = true
				frontier.append(neighbor)
	return false


func get_structures(realm_id: String = "") -> Array:
	if realm_id == "":
		return structures
	var result := []
	for structure in structures:
		if String(structure.get("realm_id", "")) == realm_id:
			result.append(structure)
	return result


func get_structure_at_tile(tile: Vector2i) -> Dictionary:
	for structure in structures:
		for footprint_tile in _footprint_tiles(structure["position"], structure.get("footprint", Vector2i.ONE)):
			if footprint_tile == tile:
				return structure
	return {}


func get_wyrd_sites() -> Array:
	return wyrd_sites


func get_dropped_wyrd() -> Array:
	return dropped_wyrd


func get_sovereign(realm_id: String) -> Dictionary:
	if not realms.has(realm_id):
		return {}
	return realms[realm_id]["sovereign"]


func get_workers(realm_id: String = "") -> Array:
	var result := []
	for id in realms:
		if realm_id != "" and id != realm_id:
			continue
		result.append_array(realms[id]["workers"])
	return result


func set_player_move_input(direction: Vector2) -> void:
	var sovereign := get_sovereign(Tuning.PLAYER_REALM)
	if sovereign.is_empty() or not bool(sovereign.get("alive", false)):
		return
	sovereign["move_input"] = direction.limit_length(1.0)
	if direction != Vector2.ZERO:
		sovereign["extracting"] = false
		sovereign["move_path"] = []
		sovereign["move_target"] = sovereign["position"]


func set_player_move_target(tile: Vector2i) -> Dictionary:
	if not simulation.is_inside_map(tile):
		return _failure("OutsideMap", "Choose a tile inside the province.")
	var sovereign := get_sovereign(Tuning.PLAYER_REALM)
	if sovereign.is_empty() or not bool(sovereign.get("alive", false)):
		return _failure("Incapacitated", "Your Sovereign is incapacitated.")
	if not simulation.is_sovereign_walkable(tile):
		return _failure("Blocked", "The Sovereign cannot enter buildings, trees, rocks, or closed gates.")
	var start := Vector2i(roundi(Vector2(sovereign["position"]).x), roundi(Vector2(sovereign["position"]).y))
	var path: Array = simulation.find_sovereign_path(start, tile)
	if start != tile and path.is_empty():
		return _failure("Unreachable", "No safe route reaches that destination.")
	sovereign["move_target"] = Vector2(tile)
	sovereign["move_path"] = path
	sovereign["move_input"] = Vector2.ZERO
	sovereign["extracting"] = false
	sovereign["stuck_seconds"] = 0.0
	return _success("Sovereign moving.")


func request_extract_wyrd(realm_id: String) -> Dictionary:
	var sovereign := get_sovereign(realm_id)
	if sovereign.is_empty() or not bool(sovereign.get("alive", false)):
		return _failure("Incapacitated", "The Sovereign is unavailable.")
	var site_index := _nearest_ready_wyrd_site(Vector2(sovereign["position"]))
	if site_index < 0:
		var drop_index := _nearest_wyrd_drop(Vector2(sovereign["position"]))
		if drop_index >= 0:
			var amount := int(dropped_wyrd[drop_index].get("amount", 0))
			add_resource(realm_id, Defs.RESOURCE_WYRD, amount)
			dropped_wyrd.remove_at(drop_index)
			_log_event("%s recovered %d dropped Wyrd." % [_realm_name(realm_id), amount])
			return _success("Recovered %d Wyrd." % amount)
		return _failure("Range", "Move beside a glowing Wyrd spring before extracting.")
	sovereign["extracting"] = true
	sovereign["extraction_progress"] = 0.0
	sovereign["extraction_site"] = site_index
	sovereign["move_input"] = Vector2.ZERO
	sovereign["move_target"] = sovereign["position"]
	return _success("Extracting Wyrd. Taking damage interrupts it.")


func request_attack(realm_id: String) -> Dictionary:
	var attacker := get_sovereign(realm_id)
	if attacker.is_empty() or not bool(attacker.get("alive", false)):
		return _failure("Incapacitated", "The Sovereign is unavailable.")
	if float(attacker.get("attack_cooldown", 0.0)) > 0.0:
		return _failure("Cooldown", "Attack is recharging.")
	var enemy_realm := _opponent(realm_id)
	var enemy := get_sovereign(enemy_realm)
	var attacker_position: Vector2 = attacker["position"]
	var attack_damage := int(attacker.get("attack_damage", Tuning.SOVEREIGN_ATTACK_DAMAGE))
	var attack_cooldown := float(attacker.get("attack_cooldown_seconds", Tuning.SOVEREIGN_ATTACK_COOLDOWN))
	if not enemy.is_empty() and bool(enemy.get("alive", false)):
		if attacker_position.distance_to(Vector2(enemy["position"])) <= Tuning.SOVEREIGN_ATTACK_RANGE:
			attacker["attack_cooldown"] = attack_cooldown
			_damage_sovereign(enemy_realm, attack_damage, realm_id)
			_add_combat_event(attacker_position, Vector2(enemy["position"]), realm_id)
			return _success("Enemy Sovereign struck.")
	var target := _nearest_enemy_structure(realm_id, attacker_position, Tuning.SOVEREIGN_ATTACK_RANGE)
	if not target.is_empty():
		attacker["attack_cooldown"] = attack_cooldown
		_damage_structure(int(target["id"]), attack_damage, realm_id)
		_add_combat_event(attacker_position, _structure_center(target), realm_id)
		return _success("%s damaged." % Tuning.structure_name(String(target["type"])))
	return _failure("Range", "No enemy Sovereign or claim structure is in attack range.")


func request_begin_claim(realm_id: String) -> Dictionary:
	if realm_id == Tuning.AI_REALM and elapsed_seconds < Tuning.AI_CLAIM_UNLOCK_SECONDS:
		var remaining := ceili(Tuning.AI_CLAIM_UNLOCK_SECONDS - elapsed_seconds)
		return _failure("OpeningTruce", "The rival cannot begin Binding for another %d seconds." % remaining)
	var requirements := claim_requirements(realm_id)
	if not bool(requirements.get("ready", false)):
		return _failure("ClaimRequirements", String(requirements.get("summary", "Binding requirements are not met.")))
	var claim: Dictionary = realms[realm_id]["claim"]
	if not bool(claim.get("active", false)):
		claim["active"] = true
		claim["status"] = "Binding begun. The Wyrd will react violently."
		claim["night_progress"] = 0.0
		claim["binding_progress"] = float(claim.get("binding_progress", 0.0))
		claim["night_started_valid"] = false
		claim["night_broken"] = false
		claim["last_pause_reason"] = ""
		claim["warning_stage"] = 0
		if realm_id == Tuning.AI_REALM:
			_log_event("RIVAL BINDING STARTED — contest the Shard before they finish.")
			simulation._emit_audio("enemy")
		else:
			_log_event("Shard Binding begun. Survive the Reckoning.")
		if simulation.has_method("_on_binding_started"):
			simulation._on_binding_started(realm_id)
	_update_match_state()
	return _success(String(claim["status"]))


func claim_requirements(realm_id: String) -> Dictionary:
	if not realms.has(realm_id):
		return {"ready": false, "summary": "Unknown realm."}
	var claim: Dictionary = realms[realm_id]["claim"]
	var outpost := _structure_by_id(int(claim.get("outpost_id", 0)))
	var outpost_ok := not outpost.is_empty() and int(outpost.get("hp", 0)) > 0
	var sovereign := get_sovereign(realm_id)
	var sovereign_alive := not sovereign.is_empty() and bool(sovereign.get("alive", false))
	# Player claims are settlement-level Outpost actions. The rival keeps its
	# internal Sovereign condition until its planner is migrated separately.
	var sovereign_inside := true if realm_id == Tuning.PLAYER_REALM else sovereign_alive and Vector2(sovereign["position"]).distance_to(Vector2(simulation.shard_position)) <= Tuning.SHARD_CLAIM_RADIUS
	var road_ok := outpost_ok and _structure_has_road_connection(realm_id, outpost)
	var lumen_ok := outpost_ok and _structure_has_lumen_connection(realm_id, outpost)
	var contested := _opposing_outpost_contests(realm_id)
	var wyrd_ok := get_resource(realm_id, Defs.RESOURCE_WYRD) >= Tuning.BINDING_MIN_WYRD
	var ready := outpost_ok and sovereign_inside and road_ok and lumen_ok and not contested and wyrd_ok
	var missing := PackedStringArray()
	if not outpost_ok:
		missing.append("operational Outpost beside the Shard")
	if realm_id != Tuning.PLAYER_REALM and not sovereign_inside:
		missing.append("Sovereign inside the claim ring")
	if not road_ok:
		missing.append("connected owned road")
	if not lumen_ok:
		missing.append("connected active Lumen")
	if not wyrd_ok:
		missing.append("%d accumulated Wyrd" % Tuning.BINDING_MIN_WYRD)
	if contested:
		missing.append("enemy contesting Outpost must be removed")
	return {
		"ready": ready,
		"outpost": outpost_ok,
		"sovereign": sovereign_inside,
		"road": road_ok,
		"lumen": lumen_ok,
		"wyrd": wyrd_ok,
		"contested": contested,
		"summary": "Ready to Bind the Shard." if ready else "Needs: %s." % ", ".join(missing)
	}


func _opposing_outpost_contests(realm_id: String) -> bool:
	for structure in structures:
		if String(structure.get("realm_id", "")) == realm_id \
			or String(structure.get("type", "")) != Tuning.STRUCTURE_CLAIMANT_OUTPOST \
			or int(structure.get("hp", 0)) <= 0:
			continue
		if _structure_center(structure).distance_to(Vector2(simulation.shard_position)) <= Tuning.CLAIM_CONTEST_RADIUS:
			return true
	return false


func get_claim_status(realm_id: String) -> Dictionary:
	if not realms.has(realm_id):
		return {}
	var claim: Dictionary = realms[realm_id]["claim"]
	var result := claim.duplicate(true)
	result["requirements"] = claim_requirements(realm_id)
	result["binding_percent"] = int(round(clampf(float(claim.get("binding_progress", 0.0)) / Tuning.BINDING_DURATION_SECONDS, 0.0, 1.0) * 100.0))
	return result


func get_rival_status_line() -> String:
	var claim: Dictionary = get_claim_status(Tuning.AI_REALM)
	if bool(claim.get("active", false)):
		return "Rival Binding %d%%" % int(claim.get("binding_percent", 0))
	var roads := get_roads(Tuning.AI_REALM).size()
	if int(claim.get("outpost_id", 0)) > 0:
		return "Rival Outpost at the Shard"
	if roads >= 12:
		return "Rival roads pushing toward the Shard"
	return "Another realm seeks the Shard"


func is_lumen_connected_at(realm_id: String, point: Vector2) -> bool:
	if not realms.has(realm_id):
		return false
	var connected_sources := _connected_lumen_sources(realm_id)
	for source in connected_sources:
		if point.distance_to(Vector2(source["center"])) <= float(source["radius"]):
			return true
	return false


func get_lumen_sources(realm_id: String) -> Array:
	return _connected_lumen_sources(realm_id)


func _connected_lumen_sources(realm_id: String) -> Array:
	var result := [{
		"id": 0,
		"center": _home_center(realm_id),
		"radius": Tuning.HOME_LUMEN_RADIUS,
		"active": true,
		"home": true
	}]
	var remaining := []
	for structure in structures:
		if String(structure.get("realm_id", "")) != realm_id:
			continue
		if String(structure.get("type", "")) != Tuning.STRUCTURE_LUMEN_PILLAR:
			continue
		if not bool(structure.get("active", false)):
			continue
		remaining.append(structure)
	var changed := true
	while changed:
		changed = false
		for index in range(remaining.size() - 1, -1, -1):
			var pillar: Dictionary = remaining[index]
			var pillar_center := _structure_center(pillar)
			var linked := false
			for source in result:
				if pillar_center.distance_to(Vector2(source["center"])) <= Tuning.LUMEN_LINK_DISTANCE:
					linked = true
					break
			if linked:
				result.append({
					"id": int(pillar["id"]),
					"center": pillar_center,
					"radius": float(Tuning.structure_definition(Tuning.STRUCTURE_LUMEN_PILLAR).get("lumen_radius", 9.0)),
					"active": true,
					"home": false
				})
				pillar["connected"] = true
				remaining.remove_at(index)
				changed = true
	for pillar in remaining:
		pillar["connected"] = false
	return result


func _update_workers(delta: float, recall_home: bool) -> void:
	var claimed_targets := {}
	for realm_id in realms:
		for worker in realms[realm_id]["workers"]:
			var target: Vector2i = worker.get("target", Vector2i(-1, -1))
			if target.x >= 0:
				claimed_targets[_key(target)] = true
	for realm_id in realms:
		for worker in realms[realm_id]["workers"]:
			_update_worker(worker, delta, claimed_targets, recall_home)


func _update_worker(worker: Dictionary, delta: float, claimed_targets: Dictionary, recall_home: bool) -> void:
	if recall_home:
		_update_worker_return_home(worker, delta)
		return
	if String(worker.get("state", "")) == "Sheltered":
		worker["state"] = "Seeking trees"
		worker["target"] = Vector2i(-1, -1)
		worker["work_position"] = Vector2i(-1, -1)
		worker["path"] = []
	var target: Vector2i = worker.get("target", Vector2i(-1, -1))
	if target.x < 0 or simulation.get_tile(target) != Defs.TILE_TREE:
		target = _nearest_tree_for_worker(worker, claimed_targets)
		worker["target"] = target
		worker["harvest_progress"] = 0.0
		worker["path"] = []
		if target.x < 0:
			worker["state"] = "No nearby trees"
			return
		var home: Vector2i = worker.get("home_position", Vector2i(worker["position"]))
		var work_position: Vector2i = simulation._nearest_tree_work_tile(home, target)
		if work_position.x < 0:
			worker["target"] = Vector2i(-1, -1)
			worker["state"] = "No route to forest"
			return
		worker["work_position"] = work_position
		var start := Vector2i(roundi(Vector2(worker["position"]).x), roundi(Vector2(worker["position"]).y))
		worker["path"] = simulation._find_worker_path(start, work_position)
		claimed_targets[_key(target)] = true
	var position: Vector2 = worker["position"]
	var path: Array = worker.get("path", [])
	if not path.is_empty():
		var next_tile: Vector2i = path[0]
		var speed := Tuning.WORKER_MOVE_SPEED
		if _realm_road_near(String(worker["realm_id"]), position):
			speed *= Tuning.ROAD_MOVEMENT_MULTIPLIER
		worker["position"] = position.move_toward(Vector2(next_tile), speed * delta)
		if Vector2(worker["position"]).distance_to(Vector2(next_tile)) <= 0.02:
			worker["position"] = Vector2(next_tile)
			path.pop_front()
			worker["path"] = path
		worker["state"] = "Walking to forest"
		return
	var work_position: Vector2i = worker.get("work_position", target)
	if position.distance_to(Vector2(work_position)) > 0.08:
		worker["position"] = position.move_toward(Vector2(work_position), Tuning.WORKER_MOVE_SPEED * delta)
		worker["state"] = "Walking to forest"
		return
	worker["state"] = "Chopping"
	worker["harvest_progress"] = float(worker.get("harvest_progress", 0.0)) + delta
	if float(worker["harvest_progress"]) < Tuning.WORKER_HARVEST_SECONDS:
		return
	worker["harvest_progress"] = 0.0
	add_resource(String(worker["realm_id"]), Defs.RESOURCE_WOOD, Tuning.WORKER_WOOD_YIELD)
	simulation._consume_deposit(target, 1)
	if simulation.get_tile(target) != Defs.TILE_TREE:
		worker["target"] = Vector2i(-1, -1)
		worker["work_position"] = Vector2i(-1, -1)
		worker["path"] = []
	worker["state"] = "+%d Wood" % Tuning.WORKER_WOOD_YIELD


func _update_worker_return_home(worker: Dictionary, delta: float) -> void:
	var home: Vector2i = worker.get("home_position", Vector2i.ZERO)
	worker["target"] = Vector2i(-1, -1)
	worker["work_position"] = Vector2i(-1, -1)
	worker["harvest_progress"] = 0.0
	var position: Vector2 = worker.get("position", Vector2(home))
	if position.distance_to(Vector2(home)) <= 0.05:
		worker["position"] = Vector2(home)
		worker["path"] = []
		worker["state"] = "Sheltered"
		return
	var path: Array = worker.get("path", [])
	if path.is_empty():
		var start := Vector2i(roundi(position.x), roundi(position.y))
		path = simulation._find_worker_path(start, home)
		worker["path"] = path
	if path.is_empty():
		worker["position"] = position.move_toward(Vector2(home), Tuning.WORKER_MOVE_SPEED * delta)
	else:
		var next_tile: Vector2i = path[0]
		worker["position"] = position.move_toward(Vector2(next_tile), Tuning.WORKER_MOVE_SPEED * delta)
		if Vector2(worker["position"]).distance_to(Vector2(next_tile)) <= 0.02:
			worker["position"] = Vector2(next_tile)
			path.pop_front()
			worker["path"] = path
	worker["state"] = "Returning home"


func _nearest_tree_for_worker(worker: Dictionary, claimed_targets: Dictionary) -> Vector2i:
	var position: Vector2 = worker["position"]
	var home: Vector2 = Vector2(worker.get("home_position", Vector2i(position)))
	var best := Vector2i(-1, -1)
	var best_home_distance := INF
	var best_worker_distance := INF
	for key in simulation.tree_deposits:
		if claimed_targets.has(String(key)):
			continue
		var tile := _tile_from_key(String(key))
		var home_distance := home.distance_to(Vector2(tile))
		if home_distance > Tuning.WORKER_SEARCH_RADIUS:
			continue
		var worker_distance := position.distance_to(Vector2(tile))
		if home_distance < best_home_distance or (is_equal_approx(home_distance, best_home_distance) and worker_distance < best_worker_distance):
			best = tile
			best_home_distance = home_distance
			best_worker_distance = worker_distance
	return best


func _update_sovereigns(delta: float) -> void:
	for realm_id in realms:
		var sovereign: Dictionary = realms[realm_id]["sovereign"]
		# Phase 3.2 removes the player hero. Keep only a stationary compatibility
		# record until the rivalry save schema can drop this field entirely.
		if realm_id == Tuning.PLAYER_REALM:
			var entrance := Vector2(realms[realm_id]["entrance"])
			sovereign["position"] = entrance
			sovereign["previous_position"] = entrance
			sovereign["move_target"] = entrance
			sovereign["move_input"] = Vector2.ZERO
			sovereign["move_path"] = []
			sovereign["extracting"] = false
			sovereign["alive"] = true
			sovereign["hp"] = sovereign.get("max_hp", Tuning.PLAYER_SOVEREIGN_MAX_HP)
			continue
		sovereign["damage_flash"] = max(0.0, float(sovereign.get("damage_flash", 0.0)) - delta)
		sovereign["attack_cooldown"] = max(0.0, float(sovereign.get("attack_cooldown", 0.0)) - delta)
		sovereign["invulnerability"] = max(0.0, float(sovereign.get("invulnerability", 0.0)) - delta)
		if not bool(sovereign.get("alive", false)):
			if realm_id == Tuning.PLAYER_REALM:
				continue
			sovereign["respawn_remaining"] = max(0.0, float(sovereign.get("respawn_remaining", 0.0)) - delta)
			if float(sovereign["respawn_remaining"]) <= 0.0:
				_respawn_sovereign(realm_id)
			continue
		sovereign["previous_position"] = Vector2(sovereign.get("position", Vector2.ZERO))
		_update_sovereign_extraction(sovereign, delta)
		_move_sovereign(sovereign, delta)
		if realm_id == Tuning.PLAYER_REALM:
			simulation._reveal_radius(Vector2i(roundi(Vector2(sovereign["position"]).x), roundi(Vector2(sovereign["position"]).y)), 5)
		var home_center := _home_center(realm_id)
		if Vector2(sovereign["position"]).distance_to(home_center) <= Tuning.SOVEREIGN_HOME_HEAL_RADIUS:
			sovereign["hp"] = min(
				int(sovereign["max_hp"]),
				float(sovereign["hp"]) + Tuning.SOVEREIGN_PASSIVE_HEAL_PER_SECOND * delta
			)


func _move_sovereign(sovereign: Dictionary, delta: float) -> void:
	if bool(sovereign.get("extracting", false)):
		return
	var current := Vector2(sovereign.get("position", Vector2.ZERO))
	var current_tile := Vector2i(roundi(current.x), roundi(current.y))
	if not simulation.is_sovereign_walkable(current_tile):
		_recover_sovereign(sovereign, "occupied_position")
		return
	var direction: Vector2 = sovereign.get("move_input", Vector2.ZERO)
	var manual := direction != Vector2.ZERO
	var speed := float(sovereign.get("move_speed", Tuning.SOVEREIGN_MOVE_SPEED))
	if _realm_road_near(String(sovereign["realm_id"]), current):
		speed *= Tuning.ROAD_MOVEMENT_MULTIPLIER
	var travel := speed * delta
	if manual:
		var next_position := _clamped_world_position(current + direction.normalized() * travel)
		var next_tile := Vector2i(roundi(next_position.x), roundi(next_position.y))
		if not simulation.is_sovereign_walkable(next_tile):
			var x_only := _clamped_world_position(Vector2(next_position.x, current.y))
			var y_only := _clamped_world_position(Vector2(current.x, next_position.y))
			if simulation.is_sovereign_walkable(Vector2i(roundi(x_only.x), roundi(x_only.y))):
				next_position = x_only
			elif simulation.is_sovereign_walkable(Vector2i(roundi(y_only.x), roundi(y_only.y))):
				next_position = y_only
			else:
				_update_sovereign_stuck(sovereign, delta, true)
				return
		sovereign["position"] = next_position
		_update_sovereign_stuck(sovereign, delta, current.distance_to(next_position) < 0.015)
		return
	var target: Vector2 = sovereign.get("move_target", sovereign["position"])
	if current.distance_to(target) <= 0.05:
		sovereign["move_path"] = []
		sovereign["stuck_seconds"] = 0.0
		return
	var path: Array = sovereign.get("move_path", [])
	if path.is_empty():
		path = simulation.find_sovereign_path(current_tile, Vector2i(roundi(target.x), roundi(target.y)))
		sovereign["move_path"] = path
	if path.is_empty():
		_update_sovereign_stuck(sovereign, delta, true)
		return
	var remaining := travel
	var start_position := current
	while remaining > 0.001 and not path.is_empty():
		var waypoint := Vector2(path[0])
		var distance := current.distance_to(waypoint)
		if distance <= 0.001:
			path.pop_front()
			continue
		if remaining >= distance:
			var waypoint_tile := Vector2i(roundi(waypoint.x), roundi(waypoint.y))
			if not simulation.is_sovereign_walkable(waypoint_tile):
				sovereign["move_path"] = []
				_update_sovereign_stuck(sovereign, delta, true)
				return
			current = waypoint
			remaining -= distance
			path.pop_front()
			continue
		var next_position := current.move_toward(waypoint, remaining)
		var next_tile := Vector2i(roundi(next_position.x), roundi(next_position.y))
		if not simulation.is_sovereign_walkable(next_tile):
			sovereign["move_path"] = []
			_update_sovereign_stuck(sovereign, delta, true)
			return
		current = next_position
		remaining = 0.0
	if path.is_empty() and current.distance_to(target) <= 0.12:
		current = target
	sovereign["move_path"] = path
	sovereign["position"] = _clamped_world_position(current)
	_update_sovereign_stuck(sovereign, delta, start_position.distance_to(sovereign["position"]) < 0.015)


func _clamped_world_position(position: Vector2) -> Vector2:
	return Vector2(
		clampf(position.x, 0.0, float(simulation.map_size.x - 1)),
		clampf(position.y, 0.0, float(simulation.map_size.y - 1))
	)


func _update_sovereign_stuck(sovereign: Dictionary, delta: float, blocked: bool) -> void:
	sovereign["stuck_seconds"] = float(sovereign.get("stuck_seconds", 0.0)) + delta if blocked else 0.0
	if float(sovereign["stuck_seconds"]) < SOVEREIGN_STUCK_SECONDS:
		return
	var current := Vector2(sovereign.get("position", Vector2.ZERO))
	var start := Vector2i(roundi(current.x), roundi(current.y))
	var target_position := Vector2(sovereign.get("move_target", current))
	var target := Vector2i(roundi(target_position.x), roundi(target_position.y))
	var retry: Array = simulation.find_sovereign_path(start, target) if simulation.is_sovereign_walkable(target) else []
	if not retry.is_empty():
		sovereign["move_path"] = retry
		sovereign["stuck_seconds"] = 0.0
		return
	_recover_sovereign(sovereign, "route_stalled")


func _recover_sovereign(sovereign: Dictionary, reason: String) -> void:
	var current := Vector2(sovereign.get("position", Vector2.ZERO))
	var origin := Vector2i(roundi(current.x), roundi(current.y))
	var recovered: Vector2i = simulation.nearest_sovereign_walkable(origin)
	if recovered.x < 0:
		return
	sovereign["position"] = Vector2(recovered)
	sovereign["previous_position"] = Vector2(recovered)
	sovereign["move_target"] = Vector2(recovered)
	sovereign["move_path"] = []
	sovereign["move_input"] = Vector2.ZERO
	sovereign["stuck_seconds"] = 0.0
	sovereign["recovery_count"] = int(sovereign.get("recovery_count", 0)) + 1
	simulation._record_event("sovereign_recovered", "The Sovereign was returned to safe ground.", {
		"realm": String(sovereign.get("realm_id", "")),
		"reason": reason,
		"from": simulation._vector_to_data(origin),
		"to": simulation._vector_to_data(recovered),
	})


func _update_sovereign_extraction(sovereign: Dictionary, delta: float) -> void:
	if not bool(sovereign.get("extracting", false)):
		return
	var site_index := int(sovereign.get("extraction_site", -1))
	if site_index < 0 or site_index >= wyrd_sites.size():
		sovereign["extracting"] = false
		return
	var site: Dictionary = wyrd_sites[site_index]
	if float(site.get("cooldown", 0.0)) > 0.0:
		sovereign["extracting"] = false
		return
	if Vector2(sovereign["position"]).distance_to(Vector2(site["position"])) > Tuning.WYRD_EXTRACTION_RANGE:
		sovereign["extracting"] = false
		return
	sovereign["extraction_progress"] = float(sovereign.get("extraction_progress", 0.0)) + delta
	if float(sovereign["extraction_progress"]) < Tuning.WYRD_EXTRACTION_SECONDS:
		return
	sovereign["extracting"] = false
	sovereign["extraction_progress"] = 0.0
	site["cooldown"] = Tuning.WYRD_SITE_COOLDOWN_SECONDS
	var realm_id := String(sovereign["realm_id"])
	add_resource(realm_id, Defs.RESOURCE_WYRD, Tuning.WYRD_EXTRACTION_YIELD)
	_log_event("%s extracted %d Wyrd." % [_realm_name(realm_id), Tuning.WYRD_EXTRACTION_YIELD])


func _update_site_cooldowns(delta: float) -> void:
	for site in wyrd_sites:
		site["cooldown"] = max(0.0, float(site.get("cooldown", 0.0)) - delta)
		site["pulse"] = float(site.get("pulse", 0.0)) + delta


func _update_dropped_wyrd() -> void:
	for realm_id in realms:
		var sovereign := get_sovereign(realm_id)
		if sovereign.is_empty() or not bool(sovereign.get("alive", false)):
			continue
		var drop_index := _nearest_wyrd_drop(Vector2(sovereign["position"]))
		if drop_index < 0:
			continue
		var amount := int(dropped_wyrd[drop_index].get("amount", 0))
		add_resource(realm_id, Defs.RESOURCE_WYRD, amount)
		dropped_wyrd.remove_at(drop_index)
		_log_event("%s recovered %d dropped Wyrd." % [_realm_name(realm_id), amount])


func _update_ai_knowledge(delta: float) -> void:
	var ai_realm: Dictionary = realms[Tuning.AI_REALM]
	var knowledge: Dictionary = ai_realm["knowledge"]
	knowledge["player_position_age"] = float(knowledge.get("player_position_age", 9999.0)) + delta
	knowledge["hostile_activity_age"] = float(knowledge.get("hostile_activity_age", 9999.0)) + delta
	var ai_sovereign := get_sovereign(Tuning.AI_REALM)
	for tile in get_roads(Tuning.PLAYER_REALM):
		if Vector2(ai_sovereign.get("position", Vector2.ZERO)).distance_to(Vector2(tile)) <= Tuning.AI_SIGHT_RADIUS:
			knowledge["known_player_roads"][_key(tile)] = elapsed_seconds
	for structure in get_structures(Tuning.PLAYER_REALM):
		if Vector2(ai_sovereign.get("position", Vector2.ZERO)).distance_to(_structure_center(structure)) <= Tuning.AI_SIGHT_RADIUS:
			knowledge["known_player_structures"][int(structure["id"])] = {
				"type": String(structure["type"]),
				"position": structure["position"],
				"seen_at": elapsed_seconds
			}
			if String(structure.get("type", "")) == Tuning.STRUCTURE_LUMEN_PILLAR:
				if bool(structure.get("active", false)):
					knowledge["known_player_lumen"][int(structure["id"])] = {
						"position": structure["position"],
						"seen_at": elapsed_seconds
					}
				else:
					knowledge["known_player_lumen"].erase(int(structure["id"]))


func _update_player_observations() -> void:
	for structure in get_structures(Tuning.AI_REALM):
		var structure_id := int(structure.get("id", 0))
		var structure_tile: Vector2i = structure.get("position", Vector2i.ZERO)
		if simulation.is_revealed(structure_tile) and not player_observed_rival_structures.has(structure_id):
			player_observed_rival_structures[structure_id] = true
			_log_event("Enemy construction observed: %s." % Tuning.structure_name(String(structure.get("type", ""))))


func _update_ai(delta: float) -> void:
	var sovereign := get_sovereign(Tuning.AI_REALM)
	if sovereign.is_empty() or not bool(sovereign.get("alive", false)):
		ai_current_goal = "Respawning at the rival Town Hall"
		return
	ai_plan_timer -= delta
	if ai_plan_timer <= 0.0:
		ai_plan_timer = Tuning.AI_PLANNING_FREQUENCY
		_plan_ai_goal()
	_execute_ai_goal()
	_ai_tactical_combat()


func _plan_ai_goal() -> void:
	var sovereign := get_sovereign(Tuning.AI_REALM)
	var health_fraction := float(sovereign.get("hp", 0)) / float(max(1, int(sovereign.get("max_hp", 1))))
	var scores := {
		"heal_or_retreat": (1.0 - health_fraction) * 150.0,
		"contest_claim": 0.0,
		"obtain_wyrd": max(0.0, 14.0 - float(get_resource(Tuning.AI_REALM, Defs.RESOURCE_WYRD))) * 5.0,
		"extend_road": 42.0,
		"place_lumen": 0.0,
		"claim": 0.0,
		"defend": 0.0,
		"secure_wood": max(0.0, 16.0 - float(get_resource(Tuning.AI_REALM, Defs.RESOURCE_WOOD))) * 3.0
	}
	if health_fraction <= Tuning.AI_RETREAT_HEALTH_FRACTION:
		scores["heal_or_retreat"] = 180.0
	var player_claim: Dictionary = realms[Tuning.PLAYER_REALM]["claim"]
	if bool(player_claim.get("active", false)):
		scores["contest_claim"] = 165.0
	var ai_claim: Dictionary = realms[Tuning.AI_REALM]["claim"]
	var rival_claim_unlocked := elapsed_seconds >= Tuning.AI_CLAIM_UNLOCK_SECONDS
	if not rival_claim_unlocked and get_roads(Tuning.AI_REALM).size() >= Tuning.AI_OPENING_ROAD_LIMIT:
		scores["extend_road"] = 4.0
		scores["defend"] = 90.0
	if rival_claim_unlocked:
		if int(ai_claim.get("outpost_id", 0)) > 0:
			scores["claim"] = 120.0
		elif _ai_can_prepare_outpost():
			scores["claim"] = 105.0
	if _ai_needs_lumen_extension():
		scores["place_lumen"] = 76.0
	var inactive_pillars := _count_inactive_pillars(Tuning.AI_REALM)
	var holding_valid_night := bool(ai_claim.get("active", false))
	if holding_valid_night and rival_claim_unlocked:
		scores["claim"] = 250.0
	elif rival_claim_unlocked and int(ai_claim.get("outpost_id", 0)) > 0:
		var total_pillars := _count_structures(Tuning.AI_REALM, Tuning.STRUCTURE_LUMEN_PILLAR)
		var upkeep_reserve := total_pillars * Tuning.LUMEN_NIGHTLY_UPKEEP * Tuning.AI_WYRD_RESERVE_NIGHTS
		var restoration_reserve := inactive_pillars * Tuning.LUMEN_NIGHTLY_UPKEEP
		if get_resource(Tuning.AI_REALM, Defs.RESOURCE_WYRD) < upkeep_reserve + restoration_reserve:
			scores["obtain_wyrd"] = 190.0
		elif inactive_pillars > 0:
			scores["place_lumen"] = 185.0
	if rival_claim_unlocked and int(ai_claim.get("outpost_id", 0)) > 0 and get_resource(Tuning.AI_REALM, Defs.RESOURCE_WYRD) < Tuning.BINDING_MIN_WYRD:
		scores["obtain_wyrd"] = 260.0
	var knowledge: Dictionary = realms[Tuning.AI_REALM]["knowledge"]
	if float(knowledge.get("hostile_activity_age", 9999.0)) <= Tuning.AI_MEMORY_SECONDS:
		scores["defend"] = 95.0
	for action in scores:
		scores[action] = float(scores[action]) * float(Tuning.AI_PERSONALITY_WEIGHTS.get(action, 1.0))
	var ordered := [
		"heal_or_retreat",
		"contest_claim",
		"claim",
		"place_lumen",
		"obtain_wyrd",
		"extend_road",
		"defend",
		"secure_wood"
	]
	var best_action: String = ordered[0]
	var best_score := -INF
	for action in ordered:
		var score := float(scores.get(action, 0.0))
		if score > best_score:
			best_score = score
			best_action = action
	ai_current_goal = best_action


func _execute_ai_goal() -> void:
	var sovereign := get_sovereign(Tuning.AI_REALM)
	match ai_current_goal:
		"heal_or_retreat":
			_set_ai_target(Vector2i(_home_center(Tuning.AI_REALM)))
		"contest_claim":
			_set_ai_target(_walkable_tile_in_claim_ring())
		"obtain_wyrd":
			_ai_obtain_wyrd(sovereign)
		"extend_road":
			_ai_extend_road()
		"place_lumen":
			_ai_place_lumen()
		"claim":
			_ai_claim()
		"defend":
			var hostile: Vector2 = realms[Tuning.AI_REALM]["knowledge"].get("recent_hostile_activity", _home_center(Tuning.AI_REALM))
			_set_ai_target(Vector2i(hostile))
		"secure_wood":
			_set_ai_target(Vector2i(_home_center(Tuning.AI_REALM)))


func _ai_obtain_wyrd(sovereign: Dictionary) -> void:
	if bool(sovereign.get("extracting", false)):
		return
	var site_index := _nearest_ready_wyrd_site(Vector2(sovereign["position"]), false)
	if site_index < 0:
		return
	var target: Vector2i = wyrd_sites[site_index]["position"]
	if Vector2(sovereign["position"]).distance_to(Vector2(target)) <= Tuning.WYRD_EXTRACTION_RANGE:
		request_extract_wyrd(Tuning.AI_REALM)
	else:
		_set_ai_target(target)


func _ai_extend_road() -> void:
	var tile := _best_road_extension(Tuning.AI_REALM, simulation.shard_position)
	if tile.x < 0:
		_record_navigation_failure("Rival road planner found no valid extension.")
		return
	var result := request_road(Tuning.AI_REALM, tile)
	if not bool(result.get("success", false)):
		_record_navigation_failure("Rival road placement failed: %s" % String(result.get("message", "")))
	else:
		ai_goal_target = tile


func _ai_place_lumen() -> void:
	var inactive_pillar := _first_inactive_pillar(Tuning.AI_REALM)
	if not inactive_pillar.is_empty():
		if get_resource(Tuning.AI_REALM, Defs.RESOURCE_WYRD) < Tuning.LUMEN_NIGHTLY_UPKEEP:
			ai_current_goal = "obtain_wyrd"
			_ai_obtain_wyrd(get_sovereign(Tuning.AI_REALM))
			return
		spend(Tuning.AI_REALM, {Defs.RESOURCE_WYRD: Tuning.LUMEN_NIGHTLY_UPKEEP})
		inactive_pillar["active"] = true
		_log_event("The rival realm restored a Lumen Pillar.")
		return
	var pillar_definition := Tuning.structure_definition(Tuning.STRUCTURE_LUMEN_PILLAR)
	if get_resource(Tuning.AI_REALM, Defs.RESOURCE_WYRD) < int(pillar_definition.get("wyrd_cost", 0)):
		ai_current_goal = "obtain_wyrd"
		_ai_obtain_wyrd(get_sovereign(Tuning.AI_REALM))
		return
	if get_resource(Tuning.AI_REALM, Defs.RESOURCE_WOOD) < int(pillar_definition.get("wood_cost", 0)):
		ai_current_goal = "secure_wood"
		_set_ai_target(Vector2i(_home_center(Tuning.AI_REALM)))
		return
	if _count_structures(Tuning.AI_REALM, Tuning.STRUCTURE_LUMEN_PILLAR) >= Tuning.MAX_LUMEN_PILLARS_PER_REALM:
		_record_navigation_failure("Rival Lumen network reached its Pillar cap without reaching the Shard.")
		return
	var tile := _best_lumen_site(Tuning.AI_REALM)
	var replaced_road := false
	if tile.x < 0:
		tile = _best_replaceable_lumen_road(Tuning.AI_REALM)
		if tile.x < 0:
			_record_navigation_failure("Rival Lumen planner found no buildable road edge.")
			return
		realms[Tuning.AI_REALM]["roads"].erase(_key(tile))
		replaced_road = true
	var result := request_structure(Tuning.AI_REALM, Tuning.STRUCTURE_LUMEN_PILLAR, tile)
	if not bool(result.get("success", false)):
		if replaced_road:
			realms[Tuning.AI_REALM]["roads"][_key(tile)] = true
		_record_navigation_failure("Rival Lumen placement failed: %s" % String(result.get("message", "")))


func _ai_claim() -> void:
	var outpost := _qualifying_claim_outpost(Tuning.AI_REALM)
	if not outpost.is_empty() and int(realms[Tuning.AI_REALM]["claim"].get("outpost_id", 0)) <= 0:
		realms[Tuning.AI_REALM]["claim"]["outpost_id"] = int(outpost.get("id", 0))
		realms[Tuning.AI_REALM]["claim"]["status"] = "Claim Outpost ready; connect its road and Lumen network."
	if outpost.is_empty():
		var outpost_definition := Tuning.structure_definition(Tuning.STRUCTURE_CLAIMANT_OUTPOST)
		if get_resource(Tuning.AI_REALM, Defs.RESOURCE_WYRD) < int(outpost_definition.get("wyrd_cost", 0)):
			ai_current_goal = "obtain_wyrd"
			_ai_obtain_wyrd(get_sovereign(Tuning.AI_REALM))
			return
		if get_resource(Tuning.AI_REALM, Defs.RESOURCE_WOOD) < int(outpost_definition.get("wood_cost", 0)):
			ai_current_goal = "secure_wood"
			_set_ai_target(Vector2i(_home_center(Tuning.AI_REALM)))
			return
		var site := _best_outpost_site(Tuning.AI_REALM)
		if site.x < 0:
			if _ai_needs_lumen_extension():
				ai_current_goal = "place_lumen"
				_ai_place_lumen()
			else:
				ai_current_goal = "extend_road"
				_ai_extend_road()
			return
		request_structure(Tuning.AI_REALM, Tuning.STRUCTURE_CLAIMANT_OUTPOST, site)
		return
	if get_resource(Tuning.AI_REALM, Defs.RESOURCE_WYRD) < Tuning.BINDING_MIN_WYRD:
		ai_current_goal = "obtain_wyrd"
		_ai_obtain_wyrd(get_sovereign(Tuning.AI_REALM))
		return
	_set_ai_target(_walkable_tile_in_claim_ring())
	if Vector2(get_sovereign(Tuning.AI_REALM)["position"]).distance_to(Vector2(simulation.shard_position)) <= Tuning.SHARD_CLAIM_RADIUS:
		request_begin_claim(Tuning.AI_REALM)


func _ai_tactical_combat() -> void:
	# Direct hero-to-hero combat was removed with the player hero. Rival claim
	# pressure continues through roads, Lumen, Outposts, and autonomous raids.
	pass


func _update_claims(delta: float, is_night: bool, _phase_time: float, phase_length: float) -> void:
	for realm_id in realms:
		var claim: Dictionary = realms[realm_id]["claim"]
		if not bool(claim.get("active", false)):
			continue
		var requirements := claim_requirements(realm_id)
		if not bool(requirements.get("outpost", false)):
			_reset_claim(realm_id, "Binding interrupted — the Shard Outpost was destroyed.")
			if simulation.has_method("_on_binding_interrupted"):
				simulation._on_binding_interrupted(realm_id, "Binding interrupted — the Shard Outpost was destroyed.")
			continue
		if bool(requirements.get("ready", false)):
			claim["binding_progress"] = minf(
				Tuning.BINDING_DURATION_SECONDS,
				float(claim.get("binding_progress", 0.0)) + delta
			)
			if is_night:
				claim["night_progress"] = min(phase_length, float(claim.get("night_progress", 0.0)) + delta)
			var percent := int(round(clampf(float(claim["binding_progress"]) / Tuning.BINDING_DURATION_SECONDS, 0.0, 1.0) * 100.0))
			claim["status"] = "SHARD BINDING — %d%%" % percent
			claim["last_pause_reason"] = ""
			if realm_id == Tuning.AI_REALM:
				_update_rival_claim_warning(claim, Tuning.BINDING_DURATION_SECONDS)
			if float(claim["binding_progress"]) >= Tuning.BINDING_DURATION_SECONDS - 0.001:
				_declare_victory(realm_id)
				return
		else:
			claim["night_broken"] = is_night
			claim["status"] = "Binding paused — %s" % String(requirements.get("summary", "requirements lost"))
			_log_claim_pause_if_changed(realm_id, claim, requirements)
	_update_match_state()


func _update_rival_claim_warning(claim: Dictionary, phase_length: float) -> void:
	var fraction := float(claim.get("binding_progress", 0.0)) / maxf(1.0, phase_length)
	var next_stage := 0
	if fraction >= 0.75:
		next_stage = 3
	elif fraction >= 0.50:
		next_stage = 2
	elif fraction >= 0.25:
		next_stage = 1
	if next_stage <= int(claim.get("warning_stage", 0)):
		return
	claim["warning_stage"] = next_stage
	var remaining_seconds := ceili(maxf(0.0, phase_length - float(claim.get("binding_progress", 0.0))))
	_log_event("RIVAL BINDING %d%% — contest the Shard now; about %d seconds remain." % [
		int(round(fraction * 100.0)),
		remaining_seconds
	])
	simulation._emit_audio("enemy")


func _log_claim_pause_if_changed(realm_id: String, claim: Dictionary, requirements: Dictionary) -> void:
	var reason := "requirements"
	var message := "%s Binding paused." % _realm_name(realm_id)
	if bool(requirements.get("contested", false)):
		reason = "contested"
		message = "%s Binding contested by an enemy Outpost." % _realm_name(realm_id)
	elif not bool(requirements.get("road", false)) or not bool(requirements.get("lumen", false)):
		reason = "connection"
		message = "%s Binding connection broken." % _realm_name(realm_id)
	elif not bool(requirements.get("wyrd", true)):
		reason = "wyrd"
		message = "%s Binding paused: not enough Wyrd." % _realm_name(realm_id)
	elif not bool(requirements.get("sovereign", false)):
		reason = "claim_presence"
		message = "%s Binding paused: its rival claimant presence left the ring." % _realm_name(realm_id)
	if String(claim.get("last_pause_reason", "")) == reason:
		return
	claim["last_pause_reason"] = reason
	_log_event(message)


func _on_night_started() -> void:
	for realm_id in realms:
		_pay_lumen_upkeep(realm_id)
	for realm_id in realms:
		var claim: Dictionary = realms[realm_id]["claim"]
		if not bool(claim.get("active", false)):
			continue
		var ready := bool(claim_requirements(realm_id).get("ready", false))
		claim["night_started_valid"] = ready
		claim["night_broken"] = not ready
		claim["night_progress"] = 0.0
		claim["warning_stage"] = 0
		if ready:
			if realm_id == Tuning.AI_REALM:
				_log_event("DANGER — the rival entered night while Binding the Shard.")
				simulation._emit_audio("enemy")
			else:
				_log_event("The Reckoning continues through the night.")


func _on_dawn(night_length: float) -> void:
	for realm_id in realms:
		var claim: Dictionary = realms[realm_id]["claim"]
		if not bool(claim.get("active", false)):
			continue
		if bool(claim.get("night_started_valid", false)) and not bool(claim.get("night_broken", false)) and float(claim.get("night_progress", 0.0)) >= night_length - 1.0:
			claim["nights_held"] = int(claim.get("nights_held", 0)) + 1
		claim["night_started_valid"] = false
		claim["night_broken"] = false
		claim["night_progress"] = 0.0
		claim["warning_stage"] = 0


func _pay_lumen_upkeep(realm_id: String) -> void:
	var pillars := []
	for structure in structures:
		if String(structure.get("realm_id", "")) == realm_id and String(structure.get("type", "")) == Tuning.STRUCTURE_LUMEN_PILLAR:
			pillars.append(structure)
	for pillar in pillars:
		if spend(realm_id, {Defs.RESOURCE_WYRD: Tuning.LUMEN_NIGHTLY_UPKEEP}):
			var was_inactive := not bool(pillar.get("active", false))
			pillar["active"] = true
			if was_inactive:
				_log_event("%s restored a Lumen Pillar." % _realm_name(realm_id))
		else:
			pillar["active"] = false
			pillar["connected"] = false
			_log_event("%s Lumen Pillar deactivated: no Wyrd for upkeep." % _realm_name(realm_id))


func _damage_sovereign(realm_id: String, amount: int, attacker_realm: String) -> void:
	if realm_id == Tuning.PLAYER_REALM:
		return
	var sovereign := get_sovereign(realm_id)
	if sovereign.is_empty() or not bool(sovereign.get("alive", false)):
		return
	if float(sovereign.get("invulnerability", 0.0)) > 0.0:
		return
	sovereign["hp"] = max(0, int(sovereign.get("hp", 0)) - amount)
	sovereign["invulnerability"] = Tuning.SOVEREIGN_HIT_INVULNERABILITY
	sovereign["damage_flash"] = 0.28
	sovereign["extracting"] = false
	sovereign["extraction_progress"] = 0.0
	sovereign["last_hit_from"] = attacker_realm
	if realm_id == Tuning.AI_REALM:
		var knowledge: Dictionary = realms[Tuning.AI_REALM]["knowledge"]
		knowledge["recent_hostile_activity"] = Vector2(sovereign["position"])
		knowledge["hostile_activity_age"] = 0.0
	if int(sovereign["hp"]) <= 0:
		_incapacitate_sovereign(realm_id)


func _incapacitate_sovereign(realm_id: String) -> void:
	var sovereign := get_sovereign(realm_id)
	if sovereign.is_empty():
		return
	sovereign["alive"] = false
	sovereign["hp"] = 0
	sovereign["extracting"] = false
	if realm_id == Tuning.PLAYER_REALM:
		sovereign["respawn_remaining"] = 0.0
		match_state = Tuning.MATCH_PLAYER_DEFEAT
		_log_event("Your Sovereign has fallen. The realm is lost.")
		if simulation.has_method("_finish_run"):
			simulation._finish_run(false, "Your Sovereign has fallen.")
		return
	sovereign["respawn_remaining"] = Tuning.SOVEREIGN_RESPAWN_SECONDS
	var wyrd := get_resource(realm_id, Defs.RESOURCE_WYRD)
	var dropped := int(floor(float(wyrd) * Tuning.DROPPED_WYRD_FRACTION))
	if dropped > 0:
		spend(realm_id, {Defs.RESOURCE_WYRD: dropped})
		dropped_wyrd.append({
			"position": Vector2(sovereign["position"]),
			"amount": dropped,
			"realm_id": realm_id
		})
	_log_event("%s Sovereign incapacitated; respawning in %.0f seconds." % [
		_realm_name(realm_id),
		Tuning.SOVEREIGN_RESPAWN_SECONDS
	])


func _respawn_sovereign(realm_id: String) -> void:
	var sovereign := get_sovereign(realm_id)
	var entrance: Vector2i = realms[realm_id]["entrance"]
	sovereign["position"] = Vector2(entrance)
	sovereign["move_target"] = Vector2(entrance)
	sovereign["move_input"] = Vector2.ZERO
	sovereign["hp"] = sovereign["max_hp"]
	sovereign["alive"] = true
	sovereign["invulnerability"] = 1.0
	sovereign["respawn_remaining"] = 0.0
	_log_event("%s Sovereign returned at the Town Hall." % _realm_name(realm_id))


func _damage_structure(structure_id: int, amount: int, attacker_realm: String) -> void:
	var structure := _structure_by_id(structure_id)
	if structure.is_empty() or String(structure.get("realm_id", "")) == attacker_realm:
		return
	structure["hp"] = max(0, int(structure.get("hp", 0)) - amount)
	structure["damage_flash"] = 0.3
	if String(structure.get("realm_id", "")) == Tuning.AI_REALM:
		var knowledge: Dictionary = realms[Tuning.AI_REALM]["knowledge"]
		knowledge["recent_hostile_activity"] = _structure_center(structure)
		knowledge["hostile_activity_age"] = 0.0
	if int(structure["hp"]) <= 0:
		_destroy_structure(structure_id)


func _destroy_structure(structure_id: int) -> void:
	var structure := _structure_by_id(structure_id)
	if structure.is_empty():
		return
	var realm_id := String(structure["realm_id"])
	var structure_type := String(structure["type"])
	realms[realm_id]["structures"].erase(structure_id)
	for index in range(structures.size() - 1, -1, -1):
		if int(structures[index].get("id", 0)) == structure_id:
			structures.remove_at(index)
			break
	_log_event("%s %s was destroyed." % [_realm_name(realm_id), Tuning.structure_name(structure_type)])
	if structure_type == Tuning.STRUCTURE_CLAIMANT_OUTPOST:
		realms[realm_id]["claim"]["outpost_id"] = 0
		_reset_claim(realm_id, "Binding interrupted — the Shard Outpost was destroyed.")


func _reset_claim(realm_id: String, reason: String) -> void:
	var claim: Dictionary = realms[realm_id]["claim"]
	var was_active := bool(claim.get("active", false))
	claim["active"] = false
	claim["status"] = reason
	claim["night_progress"] = 0.0
	claim["night_started_valid"] = false
	claim["night_broken"] = false
	claim["nights_held"] = 0
	claim["binding_progress"] = 0.0
	claim["last_pause_reason"] = ""
	claim["warning_stage"] = 0
	if was_active:
		_log_event(reason)
	_update_match_state()


func _declare_victory(realm_id: String) -> void:
	if realm_id == Tuning.PLAYER_REALM:
		match_state = Tuning.MATCH_PLAYER_VICTORY
		_log_event("Victory: the Shard is Bound. The realm is secured.")
	else:
		match_state = Tuning.MATCH_AI_VICTORY
		_log_event("Defeat: the rival bound the Shard first.")
	if simulation.has_method("_finish_rivalry_match"):
		simulation._finish_rivalry_match(realm_id == Tuning.PLAYER_REALM)


func _update_match_state() -> void:
	if match_state in [Tuning.MATCH_PLAYER_VICTORY, Tuning.MATCH_AI_VICTORY, Tuning.MATCH_PLAYER_DEFEAT, Tuning.MATCH_AI_DEFEAT]:
		return
	var player_claiming := bool(realms[Tuning.PLAYER_REALM]["claim"].get("active", false))
	var ai_claiming := bool(realms[Tuning.AI_REALM]["claim"].get("active", false))
	if player_claiming:
		match_state = Tuning.MATCH_PLAYER_CLAIMING
	elif ai_claiming:
		match_state = Tuning.MATCH_AI_CLAIMING
	else:
		match_state = Tuning.MATCH_ACTIVE


func _ai_can_prepare_outpost() -> bool:
	var frontier := _road_frontier(Tuning.AI_REALM)
	if Vector2(frontier).distance_to(Vector2(simulation.shard_position)) > Tuning.SHARD_BUILD_RADIUS + 5.0:
		return false
	if not is_lumen_connected_at(Tuning.AI_REALM, Vector2(simulation.shard_position)):
		return false
	return true


func _ai_needs_lumen_extension() -> bool:
	var frontier := _road_frontier(Tuning.AI_REALM)
	if Vector2(frontier).distance_to(Vector2(simulation.shard_position)) <= Tuning.SHARD_BUILD_RADIUS + 5.0:
		if not is_lumen_connected_at(Tuning.AI_REALM, Vector2(simulation.shard_position)):
			return true
	return not is_lumen_connected_at(Tuning.AI_REALM, Vector2(frontier))


func _best_road_extension(realm_id: String, target: Vector2i) -> Vector2i:
	var roads := get_roads(realm_id)
	var best := Vector2i(-1, -1)
	var best_score := INF
	for road in roads:
		for neighbor in _neighbors(road):
			var validation := validate_road(realm_id, neighbor)
			if not bool(validation.get("success", false)):
				continue
			var score := Vector2(neighbor).distance_to(Vector2(target))
			score += float(simulation.get_height(neighbor)) * 0.15
			if score < best_score:
				best_score = score
				best = neighbor
	return best


func _best_lumen_site(realm_id: String) -> Vector2i:
	var roads := get_roads(realm_id)
	var current_best_distance := _closest_connected_lumen_distance_to_shard(realm_id)
	roads.sort_custom(func(first: Vector2i, second: Vector2i) -> bool:
		return Vector2(first).distance_to(Vector2(simulation.shard_position)) < Vector2(second).distance_to(Vector2(simulation.shard_position))
	)
	for road in roads:
		if not is_lumen_connected_at(realm_id, Vector2(road)):
			continue
		for neighbor in _neighbors(road):
			if Vector2(neighbor).distance_to(Vector2(simulation.shard_position)) > current_best_distance - 0.4:
				continue
			if _qualifying_claim_outpost(realm_id).is_empty() and Vector2(neighbor).distance_to(Vector2(simulation.shard_position)) < 3.5:
				continue
			if bool(validate_structure(realm_id, Tuning.STRUCTURE_LUMEN_PILLAR, neighbor).get("success", false)):
				return neighbor
	return Vector2i(-1, -1)


func _best_replaceable_lumen_road(realm_id: String) -> Vector2i:
	var roads := get_roads(realm_id)
	var current_best_distance := _closest_connected_lumen_distance_to_shard(realm_id)
	roads.sort_custom(func(first: Vector2i, second: Vector2i) -> bool:
		return Vector2(first).distance_to(Vector2(simulation.shard_position)) < Vector2(second).distance_to(Vector2(simulation.shard_position))
	)
	var entrance: Vector2i = realms[realm_id]["entrance"]
	for road in roads:
		if road == entrance or not is_lumen_connected_at(realm_id, Vector2(road)):
			continue
		if Vector2(road).distance_to(Vector2(simulation.shard_position)) > current_best_distance - 0.4:
			continue
		var adjacent_roads := 0
		for neighbor in _neighbors(road):
			if owns_road(realm_id, neighbor):
				adjacent_roads += 1
		if adjacent_roads >= 2:
			return road
	return Vector2i(-1, -1)


func _closest_connected_lumen_distance_to_shard(realm_id: String) -> float:
	var best_distance := INF
	for source in _connected_lumen_sources(realm_id):
		best_distance = min(
			best_distance,
			Vector2(source.get("center", Vector2.ZERO)).distance_to(Vector2(simulation.shard_position))
		)
	return best_distance


func _first_inactive_pillar(realm_id: String) -> Dictionary:
	for structure in structures:
		if String(structure.get("realm_id", "")) != realm_id:
			continue
		if String(structure.get("type", "")) != Tuning.STRUCTURE_LUMEN_PILLAR:
			continue
		if bool(structure.get("active", false)):
			continue
		return structure
	return {}


func _count_structures(realm_id: String, structure_type: String) -> int:
	var count := 0
	for structure in structures:
		if String(structure.get("realm_id", "")) == realm_id and String(structure.get("type", "")) == structure_type:
			count += 1
	return count


func _count_inactive_pillars(realm_id: String) -> int:
	var count := 0
	for structure in structures:
		if String(structure.get("realm_id", "")) != realm_id:
			continue
		if String(structure.get("type", "")) != Tuning.STRUCTURE_LUMEN_PILLAR:
			continue
		if not bool(structure.get("active", false)):
			count += 1
	return count


func _best_outpost_site(realm_id: String) -> Vector2i:
	var candidates: Array[Vector2i] = []
	var footprint: Vector2i = Tuning.structure_definition(Tuning.STRUCTURE_CLAIMANT_OUTPOST).get("footprint", Vector2i(2, 2))
	for offset_y in range(-6, 7):
		for offset_x in range(-6, 7):
			var tile: Vector2i = simulation.shard_position + Vector2i(offset_x, offset_y)
			if _footprint_center(tile, footprint).distance_to(Vector2(simulation.shard_position)) > Tuning.SHARD_BUILD_RADIUS:
				continue
			candidates.append(tile)
	candidates.sort_custom(func(first: Vector2i, second: Vector2i) -> bool:
		return Vector2(first).distance_to(Vector2(simulation.shard_position)) < Vector2(second).distance_to(Vector2(simulation.shard_position))
	)
	for tile in candidates:
		if bool(validate_structure(realm_id, Tuning.STRUCTURE_CLAIMANT_OUTPOST, tile).get("success", false)):
			return tile
	return Vector2i(-1, -1)


func _qualifying_claim_outpost(realm_id: String) -> Dictionary:
	for structure in structures:
		if String(structure.get("realm_id", "")) != realm_id:
			continue
		if String(structure.get("type", "")) != Tuning.STRUCTURE_CLAIMANT_OUTPOST:
			continue
		if int(structure.get("hp", 0)) <= 0:
			continue
		if _structure_center(structure).distance_to(Vector2(simulation.shard_position)) <= Tuning.SHARD_BUILD_RADIUS:
			return structure
	return {}


func _set_ai_target(tile: Vector2i) -> void:
	if not simulation.is_inside_map(tile):
		_record_navigation_failure("Rival Sovereign received an invalid destination.")
		return
	if not simulation.is_sovereign_walkable(tile):
		tile = simulation.nearest_sovereign_walkable(tile)
		if tile.x < 0:
			_record_navigation_failure("Rival Sovereign received an invalid destination.")
			return
	var sovereign := get_sovereign(Tuning.AI_REALM)
	if Vector2(sovereign.get("move_target", Vector2.ZERO)).distance_to(Vector2(tile)) > 0.25:
		sovereign["move_path"] = []
	sovereign["move_target"] = Vector2(tile)
	sovereign["move_input"] = Vector2.ZERO
	sovereign["extracting"] = false
	ai_goal_target = tile


func _walkable_tile_in_claim_ring() -> Vector2i:
	var shard: Vector2i = simulation.shard_position
	var sovereign := get_sovereign(Tuning.AI_REALM)
	var from := Vector2(sovereign.get("position", Vector2(shard)))
	var best := Vector2i(-1, -1)
	var best_score := INF
	var radius := int(ceil(Tuning.SHARD_CLAIM_RADIUS))
	for offset_y in range(-radius, radius + 1):
		for offset_x in range(-radius, radius + 1):
			var tile := shard + Vector2i(offset_x, offset_y)
			if Vector2(tile).distance_to(Vector2(shard)) > Tuning.SHARD_CLAIM_RADIUS:
				continue
			if not simulation.is_sovereign_walkable(tile):
				continue
			var score := from.distance_to(Vector2(tile))
			if score < best_score:
				best_score = score
				best = tile
	if best.x >= 0:
		return best
	return simulation.nearest_sovereign_walkable(shard)


func _road_frontier(realm_id: String) -> Vector2i:
	var result: Vector2i = realms[realm_id]["entrance"]
	var best_distance := INF
	for road in get_roads(realm_id):
		var distance := Vector2(road).distance_to(Vector2(simulation.shard_position))
		if distance < best_distance:
			best_distance = distance
			result = road
	return result


func _footprint_touches_owned_road(realm_id: String, footprint_tiles: Array) -> bool:
	for footprint_tile in footprint_tiles:
		for neighbor in _neighbors(footprint_tile):
			if owns_road(realm_id, neighbor) and road_connected_to_home(realm_id, neighbor):
				return true
	return false


func _structure_has_road_connection(realm_id: String, structure: Dictionary) -> bool:
	return _footprint_touches_owned_road(
		realm_id,
		_footprint_tiles(structure["position"], structure.get("footprint", Vector2i.ONE))
	)


func _structure_has_lumen_connection(realm_id: String, structure: Dictionary) -> bool:
	return is_lumen_connected_at(realm_id, _structure_center(structure))


func _is_rivalry_occupied(tile: Vector2i) -> bool:
	for realm_id in realms:
		var home: Vector2i = realms[realm_id]["home"]
		for home_tile in _footprint_tiles(home, Defs.building_footprint(Defs.BUILDING_TOWN_HALL)):
			if home_tile == tile:
				return true
	for structure in structures:
		for footprint_tile in _footprint_tiles(structure["position"], structure.get("footprint", Vector2i.ONE)):
			if footprint_tile == tile:
				return true
	for realm_id in realms:
		if realms[realm_id]["roads"].has(_key(tile)):
			return true
	return false


func is_rivalry_occupied(tile: Vector2i) -> bool:
	return _is_rivalry_occupied(tile)


func is_sovereign_blocked(tile: Vector2i) -> bool:
	# Realm roads are deliberately walkable. The older all-purpose occupancy
	# query also includes roads, which caused the rival planner to abandon every
	# route as soon as it stepped onto its own opening road.
	for realm_id in realms:
		var home: Vector2i = realms[realm_id]["home"]
		for home_tile in _footprint_tiles(home, Defs.building_footprint(Defs.BUILDING_TOWN_HALL)):
			if home_tile == tile:
				return true
	for structure in structures:
		for footprint_tile in _footprint_tiles(structure["position"], structure.get("footprint", Vector2i.ONE)):
			if footprint_tile == tile:
				return true
	return false


func _footprint_flat_enough(tiles: Array) -> bool:
	var low := 999
	var high := -999
	for tile in tiles:
		low = min(low, simulation.get_height(tile))
		high = max(high, simulation.get_height(tile))
	return high - low <= 1


func _road_grade_valid(tile: Vector2i, roads: Dictionary) -> bool:
	for neighbor in _neighbors(tile):
		if roads.has(_key(neighbor)) and abs(simulation.get_height(tile) - simulation.get_height(neighbor)) <= 2:
			return true
	return false


func _realm_road_near(realm_id: String, position: Vector2) -> bool:
	var tile := Vector2i(roundi(position.x), roundi(position.y))
	return owns_road(realm_id, tile)


func _nearest_ready_wyrd_site(position: Vector2, require_in_range: bool = true) -> int:
	var best_index := -1
	var best_distance := INF
	for index in range(wyrd_sites.size()):
		var site: Dictionary = wyrd_sites[index]
		if float(site.get("cooldown", 0.0)) > 0.0:
			continue
		var distance := position.distance_to(Vector2(site["position"]))
		if require_in_range and distance > Tuning.WYRD_EXTRACTION_RANGE:
			continue
		if distance < best_distance:
			best_distance = distance
			best_index = index
	return best_index


func _nearest_wyrd_drop(position: Vector2) -> int:
	var best_index := -1
	var best_distance := INF
	for index in range(dropped_wyrd.size()):
		var distance := position.distance_to(Vector2(dropped_wyrd[index]["position"]))
		if distance <= Tuning.WYRD_EXTRACTION_RANGE and distance < best_distance:
			best_distance = distance
			best_index = index
	return best_index


func _nearest_enemy_structure(realm_id: String, position: Vector2, max_distance: float) -> Dictionary:
	var best := {}
	var best_distance := max_distance + 0.001
	for structure in structures:
		if String(structure.get("realm_id", "")) == realm_id:
			continue
		var distance := position.distance_to(_structure_center(structure))
		if distance <= best_distance:
			best_distance = distance
			best = structure
	return best


func _find_structure(realm_id: String, structure_type: String) -> Dictionary:
	for structure in structures:
		if String(structure.get("realm_id", "")) == realm_id and String(structure.get("type", "")) == structure_type:
			return structure
	return {}


func _structure_by_id(structure_id: int) -> Dictionary:
	for structure in structures:
		if int(structure.get("id", 0)) == structure_id:
			return structure
	return {}


func _structure_center(structure: Dictionary) -> Vector2:
	var footprint: Vector2i = structure.get("footprint", Vector2i.ONE)
	return _footprint_center(structure["position"], footprint)


func _home_center(realm_id: String) -> Vector2:
	var home: Vector2i = realms[realm_id]["home"]
	var footprint := Defs.building_footprint(Defs.BUILDING_TOWN_HALL)
	return Vector2(home) + Vector2(float(footprint.x - 1) * 0.5, float(footprint.y - 1) * 0.5)


func _footprint_tiles(anchor: Vector2i, footprint: Vector2i) -> Array:
	var result := []
	for offset_y in range(footprint.y):
		for offset_x in range(footprint.x):
			result.append(anchor + Vector2i(offset_x, offset_y))
	return result


func _footprint_center(anchor: Vector2i, footprint: Vector2i) -> Vector2:
	return Vector2(anchor) + Vector2(float(footprint.x - 1) * 0.5, float(footprint.y - 1) * 0.5)


func _neighbors(tile: Vector2i) -> Array[Vector2i]:
	return [
		tile + Vector2i.LEFT,
		tile + Vector2i.RIGHT,
		tile + Vector2i.UP,
		tile + Vector2i.DOWN
	]


func _opponent(realm_id: String) -> String:
	return Tuning.AI_REALM if realm_id == Tuning.PLAYER_REALM else Tuning.PLAYER_REALM


func _realm_name(realm_id: String) -> String:
	return "Your realm" if realm_id == Tuning.PLAYER_REALM else "The rival realm"


func _key(tile: Vector2i) -> String:
	return "%d,%d" % [tile.x, tile.y]


func _tile_from_key(key: String) -> Vector2i:
	var parts := key.split(",")
	if parts.size() != 2:
		return Vector2i(-1, -1)
	return Vector2i(int(parts[0]), int(parts[1]))


func _format_tile(tile: Vector2i) -> String:
	return "(%d, %d)" % [tile.x, tile.y]


func _add_combat_event(from: Vector2, to: Vector2, realm_id: String) -> void:
	combat_events.append({
		"from": from,
		"to": to,
		"realm_id": realm_id,
		"remaining": 0.22
	})


func _update_combat_events(delta: float) -> void:
	for structure in structures:
		structure["damage_flash"] = max(0.0, float(structure.get("damage_flash", 0.0)) - delta)
	for index in range(combat_events.size() - 1, -1, -1):
		combat_events[index]["remaining"] = float(combat_events[index].get("remaining", 0.0)) - delta
		if float(combat_events[index]["remaining"]) <= 0.0:
			combat_events.remove_at(index)


func _record_navigation_failure(message: String) -> void:
	if navigation_failures.size() >= 12:
		navigation_failures.pop_front()
	navigation_failures.append(message)
	if debug_enabled:
		_log_event("DEBUG: %s" % message)


func _log_event(message: String) -> void:
	event_log.append(message)
	if event_log.size() > 80:
		event_log.pop_front()
	if simulation != null and simulation.has_method("_rivalry_log"):
		simulation._rivalry_log(message)


func set_debug_enabled(enabled: bool) -> void:
	debug_enabled = enabled


func get_debug_snapshot() -> Dictionary:
	var knowledge: Dictionary = realms.get(Tuning.AI_REALM, {}).get("knowledge", {})
	var ai_frontier := _road_frontier(Tuning.AI_REALM)
	return {
		"match_state": match_state,
		"ai_goal": ai_current_goal,
		"ai_goal_target": ai_goal_target,
		"ai_known_player_position": knowledge.get("player_position", Vector2(-999, -999)),
		"ai_known_player_position_age": float(knowledge.get("player_position_age", 9999.0)),
		"player_roads": get_roads(Tuning.PLAYER_REALM).size(),
		"ai_roads": get_roads(Tuning.AI_REALM).size(),
		"ai_road_frontier": ai_frontier,
		"ai_frontier_shard_distance": Vector2(ai_frontier).distance_to(Vector2(simulation.shard_position)),
		"player_lumen_sources": get_lumen_sources(Tuning.PLAYER_REALM).size(),
		"ai_lumen_sources": get_lumen_sources(Tuning.AI_REALM).size(),
		"ai_shard_lumen_connected": is_lumen_connected_at(Tuning.AI_REALM, Vector2(simulation.shard_position)),
		"rivalry_structures": structures.duplicate(true),
		"player_claim": get_claim_status(Tuning.PLAYER_REALM),
		"ai_claim": get_claim_status(Tuning.AI_REALM),
		"player_resources": get_resources(Tuning.PLAYER_REALM).duplicate(true),
		"ai_resources": get_resources(Tuning.AI_REALM).duplicate(true),
		"navigation_failures": navigation_failures.duplicate()
	}


func serialize_state() -> Dictionary:
	return _encode_variant({
		"realms": realms,
		"structures": structures,
		"wyrd_sites": wyrd_sites,
		"dropped_wyrd": dropped_wyrd,
		"event_log": event_log,
		"match_state": match_state,
		"ai_current_goal": ai_current_goal,
		"ai_goal_target": ai_goal_target,
		"ai_plan_timer": ai_plan_timer,
		"next_structure_id": next_structure_id,
		"next_worker_id": next_worker_id,
		"elapsed_seconds": elapsed_seconds,
		"was_night": was_night,
		"navigation_failures": navigation_failures,
		"rng_state": str(rng.state),
		"player_has_seen_rival_sovereign": player_has_seen_rival_sovereign,
		"player_observed_rival_structures": player_observed_rival_structures
	})


func restore_state(saved_state: Dictionary) -> void:
	var restored: Dictionary = _decode_variant(saved_state)
	realms = restored.get("realms", realms)
	structures = restored.get("structures", [])
	wyrd_sites = restored.get("wyrd_sites", [])
	dropped_wyrd = restored.get("dropped_wyrd", [])
	match_state = String(restored.get("match_state", Tuning.MATCH_ACTIVE))
	ai_current_goal = String(restored.get("ai_current_goal", "Establishing the rival realm"))
	ai_goal_target = restored.get("ai_goal_target", Vector2i(-1, -1))
	ai_plan_timer = float(restored.get("ai_plan_timer", 0.0))
	next_structure_id = int(restored.get("next_structure_id", 1))
	next_worker_id = int(restored.get("next_worker_id", 1))
	elapsed_seconds = float(restored.get("elapsed_seconds", 0.0))
	was_night = bool(restored.get("was_night", false))
	player_has_seen_rival_sovereign = bool(restored.get("player_has_seen_rival_sovereign", false))
	player_observed_rival_structures = restored.get("player_observed_rival_structures", {})
	event_log.clear()
	for entry in restored.get("event_log", []):
		event_log.append(String(entry))
	navigation_failures.clear()
	for failure in restored.get("navigation_failures", []):
		navigation_failures.append(String(failure))
	rng.state = int(restored.get("rng_state", rng.state))
	if realms.has(Tuning.PLAYER_REALM):
		# Keep the player's rivalry ledger and the settlement HUD on the same
		# inventory object after decoding the save.
		realms[Tuning.PLAYER_REALM]["resources"] = simulation.central_inventory
		_upgrade_sovereign_stats(Tuning.PLAYER_REALM)
	if realms.has(Tuning.AI_REALM):
		_upgrade_sovereign_stats(Tuning.AI_REALM)
	for realm_id in realms:
		var claim: Dictionary = realms[realm_id].get("claim", {})
		if not claim.has("binding_progress"):
			claim["binding_progress"] = 0.0
			realms[realm_id]["claim"] = claim


func _upgrade_sovereign_stats(realm_id: String) -> void:
	var sovereign: Dictionary = get_sovereign(realm_id)
	if sovereign.is_empty():
		return
	var is_player := realm_id == Tuning.PLAYER_REALM
	var old_max := maxi(1, int(sovereign.get("max_hp", Tuning.SOVEREIGN_MAX_HP)))
	var health_fraction := clampf(float(sovereign.get("hp", old_max)) / float(old_max), 0.0, 1.0)
	var new_max := Tuning.PLAYER_SOVEREIGN_MAX_HP if is_player else Tuning.SOVEREIGN_MAX_HP
	sovereign["max_hp"] = new_max
	sovereign["hp"] = roundi(health_fraction * float(new_max)) if bool(sovereign.get("alive", true)) else 0
	sovereign["move_speed"] = Tuning.PLAYER_SOVEREIGN_MOVE_SPEED if is_player else Tuning.SOVEREIGN_MOVE_SPEED
	sovereign["attack_damage"] = Tuning.PLAYER_SOVEREIGN_ATTACK_DAMAGE if is_player else Tuning.SOVEREIGN_ATTACK_DAMAGE
	sovereign["attack_cooldown_seconds"] = Tuning.PLAYER_SOVEREIGN_ATTACK_COOLDOWN if is_player else Tuning.SOVEREIGN_ATTACK_COOLDOWN
	if not sovereign.has("move_path"):
		sovereign["move_path"] = []
	if not sovereign.has("stuck_seconds"):
		sovereign["stuck_seconds"] = 0.0
	if not sovereign.has("recovery_count"):
		sovereign["recovery_count"] = 0


func _encode_variant(value):
	match typeof(value):
		TYPE_VECTOR2:
			return {"__rivalry_type": "Vector2", "x": value.x, "y": value.y}
		TYPE_VECTOR2I:
			return {"__rivalry_type": "Vector2i", "x": value.x, "y": value.y}
		TYPE_ARRAY:
			var encoded_array := []
			for item in value:
				encoded_array.append(_encode_variant(item))
			return encoded_array
		TYPE_DICTIONARY:
			var encoded_dictionary := {}
			for key in value.keys():
				encoded_dictionary[str(key)] = _encode_variant(value[key])
			return encoded_dictionary
		_:
			return value


func _decode_variant(value):
	if typeof(value) == TYPE_ARRAY:
		var decoded_array := []
		for item in value:
			decoded_array.append(_decode_variant(item))
		return decoded_array
	if typeof(value) != TYPE_DICTIONARY:
		return value
	var encoded: Dictionary = value
	var encoded_type := String(encoded.get("__rivalry_type", ""))
	if encoded_type == "Vector2":
		return Vector2(float(encoded.get("x", 0.0)), float(encoded.get("y", 0.0)))
	if encoded_type == "Vector2i":
		return Vector2i(int(encoded.get("x", 0)), int(encoded.get("y", 0)))
	var decoded_dictionary := {}
	for key in encoded.keys():
		decoded_dictionary[String(key)] = _decode_variant(encoded[key])
	return decoded_dictionary


func _success(message: String) -> Dictionary:
	return {"success": true, "message": message}


func _failure(reason: String, message: String) -> Dictionary:
	return {"success": false, "reason": reason, "message": message}
