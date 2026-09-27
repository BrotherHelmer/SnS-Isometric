class_name ProductionPresentationAdapter3D
extends RefCounted

const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const RivalryTuning = preload("res://src/GodotClient/Scripts/one_shard_rivalry_tuning.gd")

const ENEMY_ID_OFFSET := 1000000
const RIVAL_WORKER_ID_OFFSET := 2000000
const RIVALRY_STRUCTURE_ID_OFFSET := 4000000

const IDLE := "Idle"
const WALK := "Walk"
const RUN := "Run"
const CARRY := "Carry"
const WORK_GENERIC := "WorkGeneric"
const CHOP := "Chop"
const MINE := "Mine"
const FARM := "Farm"
const HAMMER := "Hammer"
const SAW := "Saw"
const SLEEP := "Sleep"
const FLEE := "Flee"
const MELEE := "Melee"
const RANGED := "Ranged"
const HIT := "Hit"
const DIE := "Die"

const ALL_STATES := [
	IDLE, WALK, RUN, CARRY, WORK_GENERIC, CHOP, MINE, FARM,
	HAMMER, SAW, SLEEP, FLEE, MELEE, RANGED, HIT, DIE,
]


func capture_world(simulation) -> Dictionary:
	return {
		"seed": int(simulation.rng_seed),
		"map_size": simulation.map_size,
		"town_hall_position": simulation.town_hall_position,
		"shard_position": simulation.shard_position,
		"tiles": simulation.map_tiles.duplicate(true),
		"heights": simulation.height_map.duplicate(true),
	}


func capture_frame(simulation, render_lead_seconds := 0.0) -> Dictionary:
	var building_snapshots: Array[Dictionary] = []
	var roads_by_tile: Dictionary = {}
	for building_value in simulation.get_buildings():
		var building: Dictionary = building_value
		var descriptor := building_descriptor(building, simulation)
		if bool(descriptor.get("is_road", false)):
			var anchor: Vector2i = descriptor.get("anchor", Vector2i.ZERO)
			var road_key := "%d,%d" % [anchor.x, anchor.y]
			if not roads_by_tile.has(road_key) or (bool(roads_by_tile[road_key].get("construction", false)) and not bool(descriptor.get("construction", false))):
				roads_by_tile[road_key] = descriptor
		else:
			building_snapshots.append(descriptor)
	var road_snapshots: Array[Dictionary] = []
	for road_key in roads_by_tile:
		road_snapshots.append(roads_by_tile[road_key])
	var worker_snapshots: Array[Dictionary] = []
	for worker_value in simulation.get_workers():
		worker_snapshots.append(worker_descriptor(worker_value, simulation, render_lead_seconds))
	var combatant_snapshots: Array[Dictionary] = []
	for enemy_value in simulation.get_enemies():
		combatant_snapshots.append(enemy_descriptor(enemy_value, simulation, render_lead_seconds))
	var rivalry_structure_snapshots: Array[Dictionary] = []
	var rival_road_snapshots: Array[Dictionary] = []
	var claim_snapshot: Dictionary = {}
	var lumen_sources: Array[Dictionary] = []
	if simulation.rivalry != null:
		var rival_home := _rival_home_descriptor(simulation)
		if bool(rival_home.get("visible", false)):
			rivalry_structure_snapshots.append(rival_home)
		for realm_id in [RivalryTuning.PLAYER_REALM, RivalryTuning.AI_REALM]:
			for structure_value in simulation.rivalry.get_structures(realm_id):
				var structure: Dictionary = structure_value
				var descriptor := rivalry_structure_descriptor(structure, simulation)
				if bool(descriptor.get("visible", true)):
					rivalry_structure_snapshots.append(descriptor)
			for road_tile in simulation.rivalry.get_roads(realm_id):
				if realm_id == RivalryTuning.PLAYER_REALM or simulation.is_revealed(road_tile):
					rival_road_snapshots.append({"anchor": road_tile, "realm": realm_id})
			for source_value in simulation.rivalry.get_lumen_sources(realm_id):
				var source: Dictionary = source_value
				lumen_sources.append({
					"id": int(source.get("id", 0)),
					"center": Vector2(source.get("center", Vector2.ZERO)),
					"radius": float(source.get("radius", 0.0)),
					"realm": realm_id,
				})
		for worker_value in simulation.rivalry.get_workers(RivalryTuning.AI_REALM):
			var rival_worker := rivalry_worker_descriptor(worker_value, simulation)
			if bool(rival_worker.get("visible", false)):
				combatant_snapshots.append(rival_worker)
		claim_snapshot = {
			"player": simulation.rivalry.get_claim_status(RivalryTuning.PLAYER_REALM),
			"rival": simulation.rivalry.get_claim_status(RivalryTuning.AI_REALM),
			"match_state": simulation.rivalry.match_state,
		}
	for camp_value in simulation.get_enemy_camps():
		var camp: Dictionary = camp_value
		var camp_tile := Vector2i(camp.get("position", Vector2i.ZERO))
		if simulation.is_revealed(camp_tile) and not bool(camp.get("destroyed", false)):
			rivalry_structure_snapshots.append({
				"id": RIVALRY_STRUCTURE_ID_OFFSET + 500000 + int(camp.get("id", 0)),
				"authority_id": int(camp.get("id", 0)),
				"type": "ENEMY_CAMP",
				"anchor": camp_tile - Vector2i.ONE,
				"center": Vector2(camp_tile),
				"rotation": 0,
				"footprint": Vector2i(3, 3),
				"construction": false,
				"construction_fraction": 1.0,
				"connected": bool(camp.get("active", false)),
				"completed": true,
				"status": "Mobilized" if bool(camp.get("active", false)) else "Dormant",
				"assigned_staff": 0,
				"required_staff": 0,
				"local_inventory": {},
				"hp": 1,
				"max_hp": 1,
				"faction": "hostile",
				"realm": "hostile",
				"selection_kind": "rivalry_structure",
				"visible": true,
			})
	var projectile_snapshots := projectile_descriptors(simulation)
	var decorative_prop_snapshots: Array[Dictionary] = []
	if simulation.has_method("get_decorative_props"):
		for prop_value in simulation.get_decorative_props():
			decorative_prop_snapshots.append(Dictionary(prop_value).duplicate(true))
	return {
		"tick": simulation.get_tick_number(),
		"time": simulation.get_time_label(),
		"resources": simulation.get_resources(),
		"reserved": simulation.get_reserved_resources(),
		"buildings": building_snapshots,
		"roads": road_snapshots,
		"workers": worker_snapshots,
		"combatants": combatant_snapshots,
		"rivalry_structures": rivalry_structure_snapshots,
		"rival_roads": rival_road_snapshots,
		"projectiles": projectile_snapshots,
		"decorative_props": decorative_prop_snapshots,
		"lumen_sources": lumen_sources,
		"claims": claim_snapshot,
		"wyrdfall": simulation.get_wyrdfall_presentation() if simulation.has_method("get_wyrdfall_presentation") else {},
		"wyrd_sites": _wyrd_site_snapshots(simulation),
		"revealed_count": simulation.revealed_tiles.size(),
		"settlement": settlement_descriptor(simulation),
		"last_message": simulation.get_last_message(),
	}


func building_descriptor(building: Dictionary, simulation) -> Dictionary:
	var is_construction := bool(building.get("construction", false))
	var type_name := String(building.get("planned_type", "")) if is_construction else String(building.get("type", ""))
	var footprint := _footprint_from(building, type_name)
	var construction_fraction := 1.0
	if is_construction:
		var total := maxf(0.001, float(building.get("construction_total", Defs.build_time(type_name))))
		construction_fraction = clampf(1.0 - float(building.get("construction_remaining", total)) / total, 0.0, 1.0)
	var type_definition: Dictionary = Defs.PRODUCTION_DEFS.get(type_name, {})
	var input_resource := String(type_definition.get("input", ""))
	var output_resource := String(type_definition.get("output", ""))
	# Issue #5: Check if settlement has barracks for Town Hall → Castle upgrade
	var has_barracks := _settlement_has_barracks(simulation)
	return {
		"id": int(building.get("id", 0)),
		"type": type_name,
		"anchor": Vector2i(building.get("position", Vector2i.ZERO)),
		"center": simulation.get_building_center(building),
		"rotation": int(building.get("rotation", 0)),
		"footprint": footprint,
		"construction": is_construction,
		"construction_fraction": construction_fraction,
		"materials_needed": Dictionary(building.get("materials_needed", {})).duplicate(true),
		"materials_delivered": Dictionary(building.get("materials_delivered", {})).duplicate(true),
		"connected": bool(building.get("connected", false)),
		"completed": bool(building.get("completed", false)),
		"status": String(building.get("status", "")),
		"assigned_staff": int(building.get("assigned_staff", 0)),
		"required_staff": Defs.building_staff(type_name),
		"staffing_enabled": bool(building.get("staffing_enabled", true)),
		"storage_paused": bool(building.get("storage_paused", false)),
		"local_inventory": Dictionary(building.get("local_inventory", {})).duplicate(true),
		"input_resource": input_resource,
		"output_resource": output_resource,
		"production_active": not is_construction and bool(building.get("staffed", true)) and String(building.get("status", "")) in ["Active.", "Working.", "Producing.", "Watching.", "Firing."],
		"hp": int(building.get("hp", 0)),
		"max_hp": int(building.get("max_hp", 1)),
		"sheltered_occupants": _sheltered_occupants(building, simulation),
		"night": bool(simulation.is_night) or _settlement_lights_on(simulation),
		"wall_mask": _wall_connection_mask(building, simulation) if type_name == Defs.BUILDING_WALL else 0,
		"gate_adjacent": _wall_touches_gate(building, simulation) if type_name == Defs.BUILDING_WALL else false,
		"gate_closed": bool(simulation.is_gate_closed()),
		"faction": "player",
		"selection_kind": "building",
		"is_road": type_name == Defs.BUILDING_ROAD,
		"site_clearing": is_construction and bool(building.get("site_clearing", false)),
		"has_barracks": has_barracks,
	}


func worker_descriptor(worker: Dictionary, simulation, render_lead_seconds := 0.0) -> Dictionary:
	var path: Array = worker.get("path", [])
	var logical_position := Vector2(worker.get("position", Vector2i.ZERO))
	var logical_tile := Vector2i(worker.get("position", Vector2i.ZERO))
	var facing := Vector2.DOWN
	if not path.is_empty():
		var next_position := Vector2(path[0])
		var step_seconds: float = maxf(0.01, simulation.get_worker_step_seconds(worker))
		var fraction := clampf((float(worker.get("move_elapsed", 0.0)) + render_lead_seconds) / step_seconds, 0.0, 1.0)
		logical_position = logical_position.lerp(next_position, fraction)
		facing = (next_position - Vector2(worker.get("position", Vector2i.ZERO))).normalized()
	else:
		var work_presentation: Dictionary = simulation.get_worker_work_presentation(worker)
		if not work_presentation.is_empty():
			logical_position = Vector2(work_presentation.get("position", logical_position))
			facing = Vector2(work_presentation.get("facing", facing))
	var worker_type := String(worker.get("type", "settler"))
	var elevation := 0.0
	if path.is_empty():
		var platform_presentation: Dictionary = simulation.get_worker_work_presentation(worker)
		if bool(platform_presentation.get("platform", false)):
			worker_type = "ranger"
			elevation = float(platform_presentation.get("elevation", 4.85))
	var presented_worker := worker.duplicate(true)
	presented_worker["type"] = worker_type
	var semantic := semantic_worker_state(presented_worker)
	if worker_type == "ranger" and float(worker.get("attack_flash", 0.0)) > 0.0:
		semantic = RANGED
		var combat_target := _vector2_from_data(worker.get("combat_target_position", {}))
		facing = logical_position.direction_to(combat_target)
	elif String(worker.get("type", "")) == "guard" and float(worker.get("attack_flash", 0.0)) > 0.0:
		var melee_target := _vector2_from_data(worker.get("combat_target_position", {}))
		facing = logical_position.direction_to(melee_target)
	return {
		"id": int(worker.get("id", 0)),
		"worker_type": worker_type,
		"profession": profession_name(worker_type),
		"logical_position": logical_position,
		"logical_tile": logical_tile,
		"facing": facing,
		"state": semantic,
		"simulation_state": String(worker.get("state", "Idle")),
		"tool": "" if worker_type == "ranger" else ("axe" if String(worker.get("type", "")) == "guard" else tool_for_worker(worker, semantic)),
		"cargo": String(worker.get("carried_resource", "")) if int(worker.get("carried_amount", 0)) > 0 else "",
		"cargo_amount": int(worker.get("carried_amount", 0)),
		"building_id": int(worker.get("building_id", 0)),
		"visible": String(worker.get("state", "")) != "Sheltered" and simulation.is_revealed(logical_tile),
		"hp": int(worker.get("hp", 1)),
		"max_hp": int(worker.get("max_hp", 1)),
		"hungry": bool(worker.get("hungry", false)),
		"faction": "player_military" if String(worker.get("type", "")) == "guard" else "player",
		"alert": bool(simulation.is_night) and String(worker.get("type", "")) == "guard",
		"selection_kind": "worker",
		"selected": false,
		"elevation": elevation,
		"work_socket_index": int(simulation.get_worker_work_presentation(worker).get("socket_index", -1)) if path.is_empty() else -1,
	}


func settlement_descriptor(simulation) -> Dictionary:
	var housed := mini(int(simulation.population_current), int(simulation.housing_capacity))
	return {
		"population": int(simulation.population_current),
		"housing_capacity": int(simulation.housing_capacity),
		"housed": housed,
		"homeless": maxi(0, int(simulation.population_current) - int(simulation.housing_capacity)),
		"workers_assigned": int(simulation.workers_assigned),
		"workers_free": int(simulation.workers_free()),
		"hungry": int(simulation.get_hungry_population()),
		"food": int(simulation.get_food_units()),
		"next_food_demand": int(simulation.get_next_food_demand()),
		"sheltered": int(simulation.get_sheltered_worker_count()),
		"shelterable": int(simulation.get_shelterable_worker_count()),
		"day": int(simulation.day_count),
		"is_night": bool(simulation.is_night),
		"phase_time": float(simulation.phase_time),
		"phase_length": float(simulation.NIGHT_LENGTH_SECONDS if simulation.is_night else simulation.DAY_LENGTH_SECONDS),
		"enemies": simulation.enemies.size(),
		"soldiers": int(simulation.soldiers_total),
		"claim": simulation.get_claim_label(),
		"wyrd_pressure": simulation.get_wyrd_pressure() if simulation.has_method("get_wyrd_pressure") else {},
		"objective": simulation.get_macro_objective() if simulation.has_method("get_macro_objective") else {},
		"forecast": simulation.get_night_forecast() if simulation.has_method("get_night_forecast") else {},
	}


func enemy_descriptor(enemy: Dictionary, simulation, render_lead_seconds := 0.0) -> Dictionary:
	var path: Array = enemy.get("path", [])
	var logical_position := Vector2(enemy.get("position", Vector2i.ZERO))
	var facing := Vector2.DOWN
	if not path.is_empty():
		var next_position := Vector2(path[0])
		var step_seconds: float = maxf(0.01, simulation.get_enemy_step_seconds(enemy))
		var fraction := clampf((float(enemy.get("move_elapsed", 0.0)) + render_lead_seconds) / step_seconds, 0.0, 1.0)
		logical_position = logical_position.lerp(next_position, fraction)
		facing = (next_position - Vector2(enemy.get("position", Vector2i.ZERO))).normalized()
	var enemy_type := String(enemy.get("enemy_type", "raider"))
	var role := "Raider"
	var model_scale := 1.12
	if enemy_type in ["skitterer", "marauder"]:
		role = "Marauder"
		model_scale = 1.02
	elif enemy_type == "brute":
		role = "Brute"
		model_scale = 1.28
	elif enemy_type == "hexer":
		role = "Hexer"
		model_scale = 1.12
	var semantic := IDLE
	if int(enemy.get("hp", 0)) <= 0:
		semantic = DIE
	elif float(enemy.get("hit_until", 0.0)) > float(simulation.elapsed_seconds):
		semantic = HIT
	elif float(enemy.get("attack_flash", 0.0)) > 0.0:
		semantic = RANGED if enemy_type == "hexer" else MELEE
		facing = logical_position.direction_to(_vector2_from_data(enemy.get("target_position", {})))
	elif bool(enemy.get("retreating", false)):
		semantic = FLEE
	elif not path.is_empty():
		semantic = RUN
	var tile := Vector2i(enemy.get("position", Vector2i.ZERO))
	var formation_index := int(enemy.get("id", 0)) % 5
	var formation_offset: Vector2 = [Vector2(-0.13, -0.08), Vector2(0.13, -0.08), Vector2(-0.18, 0.10), Vector2(0.18, 0.10), Vector2.ZERO][formation_index]
	return {
		"id": ENEMY_ID_OFFSET + int(enemy.get("id", 0)),
		"authority_id": int(enemy.get("id", 0)),
		"worker_type": "enemy_%s" % enemy_type,
		"profession": role,
		"model_scale": model_scale,
		"logical_position": logical_position,
		"presentation_offset": formation_offset,
		"logical_tile": tile,
		"facing": facing,
		"state": semantic,
		"simulation_state": "Retreating" if bool(enemy.get("retreating", false)) else "Raiding",
		"tool": "axe" if enemy_type in ["raider", "brute"] else "",
		"cargo": "",
		"cargo_amount": 0,
		"visible": _tile_visible_or_adjacent(simulation, tile),
		"hp": int(enemy.get("hp", 0)),
		"max_hp": int(enemy.get("max_hp", 1)),
		"faction": "hostile",
		"selection_kind": "enemy",
		"selected": false,
	}


func rivalry_worker_descriptor(worker: Dictionary, simulation) -> Dictionary:
	var position := Vector2(worker.get("position", Vector2.ZERO))
	var state_text := String(worker.get("state", ""))
	var semantic := IDLE
	if "Sheltered" in state_text:
		semantic = SLEEP
	elif "Walking" in state_text or "Returning" in state_text:
		semantic = WALK
	elif "Chopping" in state_text or "Wood" in state_text:
		semantic = CHOP
	var tile := Vector2i(roundi(position.x), roundi(position.y))
	return {
		"id": RIVAL_WORKER_ID_OFFSET + int(worker.get("id", 0)),
		"authority_id": int(worker.get("id", 0)),
		"worker_type": "rival_worker",
		"profession": "Rival worker",
		"logical_position": position,
		"logical_tile": tile,
		"facing": Vector2.DOWN,
		"state": semantic,
		"simulation_state": state_text,
		"tool": "axe" if semantic == CHOP else "",
		"cargo": "",
		"cargo_amount": 0,
		"visible": simulation.is_revealed(tile),
		"hp": 1,
		"max_hp": 1,
		"faction": "rival",
		"selection_kind": "rival_worker",
		"selected": false,
	}


func _wyrd_site_snapshots(simulation) -> Array[Dictionary]:
	var sites: Array[Dictionary] = []
	if simulation.rivalry == null or not simulation.rivalry.has_method("get_wyrd_sites"):
		return sites
	for site_value in simulation.rivalry.get_wyrd_sites():
		var site: Dictionary = site_value
		var tile := Vector2i(site.get("position", Vector2i.ZERO))
		sites.append({
			"position": tile,
			"visible": simulation.is_revealed(tile) or _touches_revealed(simulation, tile),
			"richness": float(site.get("richness", 1.0))
		})
	return sites


func _touches_revealed(simulation, tile: Vector2i) -> bool:
	for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if simulation.is_revealed(tile + offset):
			return true
	return false


func rivalry_structure_descriptor(structure: Dictionary, simulation) -> Dictionary:
	var realm := String(structure.get("realm_id", ""))
	var anchor := Vector2i(structure.get("position", Vector2i.ZERO))
	var footprint := Vector2i(structure.get("footprint", Vector2i.ONE))
	var player_owned := realm == RivalryTuning.PLAYER_REALM
	return {
		"id": RIVALRY_STRUCTURE_ID_OFFSET + int(structure.get("id", 0)),
		"authority_id": int(structure.get("id", 0)),
		"type": String(structure.get("type", "")),
		"anchor": anchor,
		"center": Vector2(anchor) + Vector2(footprint - Vector2i.ONE) * 0.5,
		"rotation": 0,
		"footprint": footprint,
		"construction": false,
		"construction_fraction": 1.0,
		"connected": bool(structure.get("connected", false)),
		"completed": true,
		"status": "Active" if bool(structure.get("active", false)) else "Inactive — no Lumen",
		"assigned_staff": 0,
		"required_staff": 0,
		"local_inventory": {},
		"hp": int(structure.get("hp", 0)),
		"max_hp": int(structure.get("max_hp", 1)),
		"faction": "player" if player_owned else "rival",
		"realm": realm,
		"selection_kind": "rivalry_structure",
		"visible": player_owned or simulation.is_revealed(anchor),
		"night": bool(simulation.is_night) or _settlement_lights_on(simulation),
		"production_active": bool(structure.get("active", false)),
	}


func _rival_home_descriptor(simulation) -> Dictionary:
	var footprint := Defs.building_footprint(Defs.BUILDING_TOWN_HALL)
	var anchor: Vector2i = simulation.rival_town_hall_position
	return {
		"id": RIVALRY_STRUCTURE_ID_OFFSET + 900000,
		"authority_id": 0,
		"type": Defs.BUILDING_TOWN_HALL,
		"anchor": anchor,
		"center": Vector2(anchor) + Vector2(footprint - Vector2i.ONE) * 0.5,
		"rotation": 0,
		"footprint": footprint,
		"construction": false,
		"construction_fraction": 1.0,
		"connected": true,
		"completed": true,
		"status": "Rival seat of power",
		"assigned_staff": simulation.rivalry.get_workers(RivalryTuning.AI_REALM).size(),
		"required_staff": 0,
		"local_inventory": simulation.rivalry.get_resources(RivalryTuning.AI_REALM).duplicate(true),
		"hp": 1,
		"max_hp": 1,
		"faction": "rival",
		"realm": RivalryTuning.AI_REALM,
		"selection_kind": "rivalry_structure",
		"visible": simulation.is_revealed(anchor),
		"night": bool(simulation.is_night) or _settlement_lights_on(simulation),
	}


func projectile_descriptors(simulation) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var index := 0
	for projectile_value in simulation.get_projectiles():
		var projectile: Dictionary = projectile_value
		var from := _vector2_from_data(projectile.get("from", {}))
		var to := _vector2_from_data(projectile.get("to", {}))
		result.append({
			"id": "sim:%d:%d:%d:%d" % [roundi(from.x * 10.0), roundi(from.y * 10.0), roundi(to.x * 10.0), index],
			"from": from,
			"to": to,
			"life": float(projectile.get("life", 0.0)),
			"total": float(projectile.get("total", 0.65)),
			"kind": String(projectile.get("kind", "arrow")),
			"faction": "hostile" if String(projectile.get("kind", "")) == "hex" else "player_military",
		})
		index += 1
	if simulation.rivalry != null:
		for event_value in simulation.rivalry.combat_events:
			var event: Dictionary = event_value
			var from := Vector2(event.get("from", Vector2.ZERO))
			var to := Vector2(event.get("to", Vector2.ZERO))
			result.append({
				"id": "rivalry:%d:%d:%d" % [roundi(from.x * 10.0), roundi(to.x * 10.0), index],
				"from": from,
				"to": to,
				"life": float(event.get("remaining", 0.0)),
				"total": 0.22,
				"kind": "rivalry",
				"faction": "player_military" if String(event.get("realm_id", "")) == RivalryTuning.PLAYER_REALM else "rival",
			})
			index += 1
	return result


func _settlement_lights_on(simulation) -> bool:
	if bool(simulation.is_night):
		return true
	var remaining: float = float(simulation.DAY_LENGTH_SECONDS) - float(simulation.phase_time)
	return remaining <= 60.0


func _sheltered_occupants(building: Dictionary, simulation) -> int:
	if String(building.get("type", "")) not in [Defs.BUILDING_HOUSE, Defs.BUILDING_TOWN_HALL]:
		return 0
	var access: Array = simulation._building_access_tiles(building)
	var count := 0
	for worker_value in simulation.workers:
		var worker: Dictionary = worker_value
		if String(worker.get("state", "")) == "Sheltered" and access.has(Vector2i(worker.get("shelter_position", Vector2i(-1, -1)))):
			count += 1
	return count


func _vector2_from_data(value) -> Vector2:
	if typeof(value) == TYPE_VECTOR2:
		return value
	if typeof(value) == TYPE_VECTOR2I:
		return Vector2(value)
	if typeof(value) == TYPE_DICTIONARY:
		return Vector2(float(value.get("x", 0.0)), float(value.get("y", 0.0)))
	return Vector2.ZERO


func _wall_connection_mask(building: Dictionary, simulation) -> int:
	var tile := Vector2i(building.get("position", Vector2i.ZERO))
	var mask := 0
	var directions := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	for index in directions.size():
		var neighbor: Dictionary = simulation.get_building_at_tile(tile + directions[index])
		if not neighbor.is_empty() and String(neighbor.get("type", "")) in [Defs.BUILDING_WALL, Defs.BUILDING_WATCHTOWER]:
			mask |= 1 << index
	return mask


func _wall_touches_gate(building: Dictionary, simulation) -> bool:
	var tile := Vector2i(building.get("position", Vector2i.ZERO))
	for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		if simulation.is_gate_tile(tile + direction):
			return true
	return false


func semantic_worker_state(worker: Dictionary) -> String:
	var worker_type := String(worker.get("type", "settler"))
	var worker_state := String(worker.get("state", "Idle")).to_lower()
	var carried_amount := int(worker.get("carried_amount", 0))
	var path: Array = worker.get("path", [])
	if int(worker.get("hp", 1)) <= 0 or "dead" in worker_state:
		return DIE
	if "hit" in worker_state or "hurt" in worker_state:
		return HIT
	if "attack" in worker_state or "fight" in worker_state:
		return RANGED if worker_type in ["ranger", "archer"] else MELEE
	if carried_amount > 0:
		return CARRY
	if not path.is_empty():
		return FLEE if "flee" in worker_state else WALK
	if "building" in worker_state or "road" in worker_state:
		return HAMMER
	if "sleep" in worker_state or "shelter" in worker_state:
		return SLEEP
	if worker_type in ["woodcutter", "clearer"] and ("work" in worker_state or "gather" in worker_state or "clear" in worker_state):
		return CHOP
	if worker_type == "miner" and "work" in worker_state:
		return MINE
	if worker_type == "farmer" and "work" in worker_state:
		return FARM
	if worker_type == "sawyer" and "work" in worker_state:
		return SAW
	if worker_type == "baker" and "work" in worker_state:
		return WORK_GENERIC
	if "work" in worker_state or "gather" in worker_state:
		return WORK_GENERIC
	return IDLE


func tool_for_worker(worker: Dictionary, semantic_state: String) -> String:
	if semantic_state == HAMMER:
		return "hammer"
	match String(worker.get("type", "")):
		"woodcutter", "clearer": return "axe"
		"miner": return "pickaxe"
		"sawyer": return "saw"
		"farmer": return "shovel"
	return ""


func profession_name(worker_type: String) -> String:
	match worker_type:
		"carrier": return "Carrier"
		"woodcutter": return "Woodcutter"
		"miner": return "Quarry Worker"
		"farmer": return "Farmer"
		"sawyer": return "Sawyer"
		"baker": return "Baker"
		"clearer": return "Peasant"
		"guard": return "Guard"
		"ranger": return "Tower Guard"
		"founder": return "Founder"
	return "Settler"


func _tile_visible_or_adjacent(simulation, tile: Vector2i) -> bool:
	if simulation.is_revealed(tile):
		return true
	for y in range(-1, 2):
		for x in range(-1, 2):
			if x == 0 and y == 0:
				continue
			if simulation.is_revealed(tile + Vector2i(x, y)):
				return true
	return false


func _footprint_from(building: Dictionary, type_name: String) -> Vector2i:
	var stored = building.get("footprint", null)
	if typeof(stored) == TYPE_VECTOR2I:
		return stored
	if typeof(stored) == TYPE_DICTIONARY:
		return Vector2i(int(stored.get("x", 1)), int(stored.get("y", 1)))
	return Defs.building_footprint(type_name)


func _settlement_has_barracks(simulation) -> bool:
	for building_value in simulation.get_buildings():
		var building: Dictionary = building_value
		if String(building.get("type", "")) == "BARRACKS" and not bool(building.get("construction", false)) and bool(building.get("completed", false)):
			return true
	return false
