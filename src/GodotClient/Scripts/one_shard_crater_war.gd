extends RefCounted

## The Director: The Crater War vertical slice.
## Binding is at the frontier fissure — 12 Stabilized Wyrd plus a 120 s
## ritual that must be defended. The player starts it when the store is
## ready; there is no clock unlock. Survival (THE REALM HOLDS) is a
## milestone, not a win. One rival contests the same fissure; capture, a
## passage deal, or the rival taking another vent all count as a resolution.

const Defs = preload("one_shard_defs.gd")
const RivalryTuning = preload("one_shard_rivalry_tuning.gd")

const STABILIZED_TO_BIND := 12
const RITUAL_SECONDS := 120.0
const HARVEST_INTERVAL := 16.0
const HARVEST_AMOUNT := 1
const REFINE_INTERVAL := 10.0
const REFINE_INPUT := 2
const REFINE_OUTPUT := 1
const RAW_RESERVE := 4
const PASSAGE_WOOD := 8
const CAPTURE_WOOD := 8
const CAPTURE_STONE := 4
const CAPTURE_WYRD := 2
const CAPTURE_STABILIZED := 2
const ASSAULT_FORCE_SECONDS := 75.0
const RITUAL_RAID_SIZE := 2
const SECONDARY_OFFSET := Vector2i(8, -5)

var simulation
var fissure_tiles: Array = []
var primary_fissure := Vector2i(-1, -1)
var secondary_fissure := Vector2i(-1, -1)
var geologist_surveyed := false
var rival_resolution := ""
var captured_outpost_id := 0
var ritual_active := false
var ritual_progress := 0.0
var ritual_raid_spawned := false
var hold_milestone_shown := false
var harvest_timer := 0.0
var refine_timer := 0.0
var exposure := 0.0
var rival_relocated := false
var assault_started_at := -1.0
var assault_target_id := 0
var storehouse_completed_at := -1.0
var capture_at := -1.0
var rival_interacted := false
var ritual_started_at := -1.0
var last_exposure_band := ""


func setup(owner) -> void:
	simulation = owner
	reset()


func reset() -> void:
	fissure_tiles.clear()
	primary_fissure = Vector2i(-1, -1)
	secondary_fissure = Vector2i(-1, -1)
	geologist_surveyed = false
	rival_resolution = ""
	captured_outpost_id = 0
	ritual_active = false
	ritual_progress = 0.0
	ritual_raid_spawned = false
	hold_milestone_shown = false
	harvest_timer = 0.0
	refine_timer = 0.0
	exposure = 0.0
	rival_relocated = false
	assault_started_at = -1.0
	assault_target_id = 0
	storehouse_completed_at = -1.0
	capture_at = -1.0
	rival_interacted = false
	ritual_started_at = -1.0
	last_exposure_band = ""


func tick(delta: float) -> void:
	if simulation == null or bool(simulation.game_finished):
		return
	_note_storehouse()
	_tick_production(delta)
	_update_exposure()
	_maybe_force_capture()
	_maybe_rival_takes_other()
	_tick_ritual(delta)


func plant_fissures(marker: Vector2i) -> void:
	primary_fissure = _clamp_tile(marker)
	secondary_fissure = _clamp_tile(marker + SECONDARY_OFFSET)
	fissure_tiles.clear()
	for origin in [primary_fissure, secondary_fissure]:
		for oy in range(-2, 3):
			for ox in range(-2, 3):
				if absi(ox) + absi(oy) > 2:
					continue
				var tile := _clamp_tile(origin + Vector2i(ox, oy))
				if not simulation.is_inside_map(tile) or tile == simulation.shard_position:
					continue
				if String(simulation.get_tile(tile)) in [Defs.TILE_TREE, Defs.TILE_ROCK]:
					simulation._set_tile(tile, Defs.TILE_GRASS)
					simulation.tree_deposits.erase(simulation._tile_key(tile))
					simulation.rock_deposits.erase(simulation._tile_key(tile))
				if not is_fissure_tile(tile):
					fissure_tiles.append(tile)
	if not fissure_tiles.is_empty() and primary_fissure.x < 0:
		primary_fissure = fissure_tiles[0]


func survey_fissures(reason: String = "The geologist marks a Wyrd fissure on the crater road.") -> Dictionary:
	if primary_fissure.x < 0:
		return _failure("NoFissure", "No fissure has been planted yet.")
	geologist_surveyed = true
	simulation.add_map_marker("fissure", primary_fissure, "Fissure", 0.0)
	if secondary_fissure.x >= 0:
		simulation.add_map_marker("fissure", secondary_fissure, "Second vent", 0.0)
	simulation._reveal_radius(primary_fissure, 6)
	simulation.last_message = reason
	simulation._add_log(reason)
	simulation.push_notice("info", "GEOLOGIST", reason, "warning")
	simulation._record_event("geologist_survey", reason, {"tile": primary_fissure})
	simulation.intention_flags["surveyed_fissure"] = true
	return _success(reason)


func rival_presence_tile() -> Vector2i:
	if primary_fissure.x < 0:
		return Vector2i(-1, -1)
	var hall: Vector2i = simulation._footprint_center(simulation.town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	var away := Vector2(primary_fissure - hall)
	if away.length_squared() < 0.01:
		away = Vector2(1.0, 0.0)
	away = away.normalized()
	var perp := Vector2(-away.y, away.x)
	var tile := primary_fissure + Vector2i(roundi(perp.x * 4.0), roundi(perp.y * 4.0))
	return _clamp_tile(tile)


func is_fissure_tile(tile: Vector2i) -> bool:
	for fissure in fissure_tiles:
		if Vector2i(fissure) == tile:
			return true
	return false


func harvester_can_sit(tile: Vector2i) -> bool:
	var footprint: Vector2i = Defs.building_footprint(Defs.BUILDING_WYRD_HARVESTER)
	for occupied in simulation._footprint_tiles(tile, footprint):
		for neighbor in simulation._neighbors(occupied):
			if is_fissure_tile(neighbor) or is_fissure_tile(occupied):
				return true
	return false


func can_begin() -> bool:
	if ritual_active or bool(simulation.game_finished):
		return false
	if stabilized_stock() < STABILIZED_TO_BIND:
		return false
	if not simulation._player_has_completed_building(Defs.BUILDING_STOREHOUSE):
		return false
	if not simulation._player_has_completed_building(Defs.BUILDING_WYRD_HARVESTER):
		return false
	if not simulation._player_has_completed_building(Defs.BUILDING_WYRD_REFINER):
		return false
	if rival_resolution == "" and captured_outpost_id <= 0:
		return false
	if not _binding_outpost_alive():
		return false
	return true


func begin_requirements() -> Dictionary:
	var missing := PackedStringArray()
	if stabilized_stock() < STABILIZED_TO_BIND:
		missing.append("%d Stabilized Wyrd" % STABILIZED_TO_BIND)
	if not simulation._player_has_completed_building(Defs.BUILDING_STOREHOUSE):
		missing.append("a completed Storehouse")
	if not simulation._player_has_completed_building(Defs.BUILDING_WYRD_HARVESTER):
		missing.append("a Wyrd Harvester on the fissure")
	if not simulation._player_has_completed_building(Defs.BUILDING_WYRD_REFINER):
		missing.append("a Wyrd Refiner")
	if rival_resolution == "" and captured_outpost_id <= 0:
		missing.append("the rival at this fissure resolved")
	if not _binding_outpost_alive():
		missing.append("an Outpost holding the fissure")
	return {
		"ready": missing.is_empty(),
		"missing": missing,
		"summary": "Ready to Bind the fissure." if missing.is_empty() else "Needs: %s." % ", ".join(missing)
	}


func request_begin() -> Dictionary:
	var requirements := begin_requirements()
	if not bool(requirements.get("ready", false)):
		return _failure("ClaimRequirements", String(requirements.get("summary", "Binding requirements are not met.")))
	var taken := _take_stabilized(STABILIZED_TO_BIND)
	if taken < STABILIZED_TO_BIND:
		return _failure("Wyrd", "The ritual needs %d Stabilized Wyrd in the store." % STABILIZED_TO_BIND)
	ritual_active = true
	ritual_progress = 0.0
	ritual_raid_spawned = false
	ritual_started_at = float(simulation.elapsed_seconds)
	simulation.reckoning_active = true
	var message := "BINDING BEGUN — defend the fissure ritual for 120 seconds."
	simulation.last_message = message
	simulation._add_log(message)
	simulation.push_notice("danger", "BINDING", message, "critical")
	simulation._record_event("binding_started", message, {"stabilized": STABILIZED_TO_BIND})
	simulation._mark_onboarding("binding")
	return _success(message)


func note_assault(structure_id: int) -> void:
	assault_target_id = structure_id
	if assault_started_at < 0.0:
		assault_started_at = float(simulation.elapsed_seconds)
	rival_interacted = true


func capture_outpost(structure: Dictionary) -> void:
	if structure.is_empty():
		return
	var rivalry = simulation.rivalry
	if rivalry != null and rivalry.has_method("capture_structure"):
		rivalry.capture_structure(int(structure.get("id", 0)), RivalryTuning.PLAYER_REALM)
	captured_outpost_id = int(structure.get("id", 0))
	rival_resolution = "capture"
	capture_at = float(simulation.elapsed_seconds)
	rival_interacted = true
	simulation.central_inventory[Defs.RESOURCE_WOOD] = int(simulation.central_inventory.get(Defs.RESOURCE_WOOD, 0)) + CAPTURE_WOOD
	simulation.central_inventory[Defs.RESOURCE_STONE] = int(simulation.central_inventory.get(Defs.RESOURCE_STONE, 0)) + CAPTURE_STONE
	simulation.central_inventory[Defs.RESOURCE_WYRD] = int(simulation.central_inventory.get(Defs.RESOURCE_WYRD, 0)) + CAPTURE_WYRD
	simulation.central_inventory[Defs.RESOURCE_STABILIZED_WYRD] = int(simulation.central_inventory.get(Defs.RESOURCE_STABILIZED_WYRD, 0)) + CAPTURE_STABILIZED
	var message := "CLAIMANT OUTPOST CAPTURED — their stores are yours. +%d Wood, +%d Stone, +%d Wyrd, +%d Stabilized. The fissure is yours." % [
		CAPTURE_WOOD, CAPTURE_STONE, CAPTURE_WYRD, CAPTURE_STABILIZED
	]
	simulation.last_message = message
	simulation._add_log(message)
	simulation.push_notice("info", "CAPTURE", message, "warning")
	simulation._record_event("outpost_captured", message, {"structure_id": captured_outpost_id, "reward": {
		"wood": CAPTURE_WOOD, "stone": CAPTURE_STONE, "wyrd": CAPTURE_WYRD, "stabilized": CAPTURE_STABILIZED
	}})
	simulation.intention_flags["captured_outpost"] = true
	if not geologist_surveyed:
		survey_fissures("The captured Outpost's geologist marks the fissure under the palisade.")


func request_passage_deal() -> Dictionary:
	if rival_resolution != "":
		return _failure("Resolved", "The rival at this fissure is already resolved.")
	if not bool(simulation.demo_rival_revealed):
		return _failure("Fog", "No rival has been sighted at this fissure.")
	var rival_here := false
	if simulation.rivalry != null:
		for structure in simulation.rivalry.get_structures(RivalryTuning.AI_REALM):
			if String(structure.get("type", "")) == RivalryTuning.STRUCTURE_CLAIMANT_OUTPOST and int(structure.get("hp", 0)) > 0:
				rival_here = true
				break
	if not rival_here:
		return _failure("Target", "No rival Outpost contests this fissure.")
	if int(simulation.get_available_resource(Defs.RESOURCE_WOOD)) < PASSAGE_WOOD:
		return _failure("Resources", "A passage deal costs %d Wood." % PASSAGE_WOOD)
	simulation.central_inventory[Defs.RESOURCE_WOOD] = int(simulation.central_inventory.get(Defs.RESOURCE_WOOD, 0)) - PASSAGE_WOOD
	_relocate_rival_to_secondary("passage")
	var message := "PASSAGE STRUCK — %d Wood buys the rival another vent. This fissure is yours." % PASSAGE_WOOD
	simulation.last_message = message
	simulation._add_log(message)
	simulation.push_notice("info", "PASSAGE", message, "warning")
	simulation._record_event("passage_deal", message, {"wood": PASSAGE_WOOD})
	rival_interacted = true
	return _success(message)


func show_hold_milestone() -> void:
	if hold_milestone_shown:
		return
	hold_milestone_shown = true
	var message := "THE REALM HOLDS — five days on the frontier. Binding the fissure is the war that remains."
	simulation.last_message = message
	simulation._add_log(message)
	simulation.push_notice("info", "MILESTONE", message, "warning")
	simulation._record_event("hold_milestone", message, {})


func stabilized_stock() -> int:
	return int(simulation.central_inventory.get(Defs.RESOURCE_STABILIZED_WYRD, 0))


func raw_stock() -> int:
	return int(simulation.central_inventory.get(Defs.RESOURCE_WYRD, 0))


func presentation() -> Dictionary:
	var percent := int(round(clampf(ritual_progress / RITUAL_SECONDS, 0.0, 1.0) * 100.0))
	var rival_line := ""
	if rival_resolution == "capture":
		rival_line = "Rival Outpost captured — fissure claimed"
	elif rival_resolution == "passage":
		rival_line = "Passage deal — rival took another vent"
	elif rival_resolution == "relocated":
		rival_line = "Rival abandoned this fissure for another vent"
	elif simulation.demo_rival_revealed:
		rival_line = "Rival contests this fissure"
	return {
		"binding_active": ritual_active,
		"binding_ready": can_begin(),
		"binding_percent": percent,
		"binding_summary": "SHARD BINDING — %d%%" % percent if ritual_active else begin_requirements().get("summary", ""),
		"rival_line": rival_line,
		"exposure": exposure,
		"stabilized": stabilized_stock(),
		"surveyed": geologist_surveyed,
		"resolution": rival_resolution
	}


func _tick_production(delta: float) -> void:
	if _has_completed(Defs.BUILDING_WYRD_HARVESTER):
		harvest_timer += delta
		if harvest_timer >= HARVEST_INTERVAL:
			harvest_timer = 0.0
			simulation.central_inventory[Defs.RESOURCE_WYRD] = int(simulation.central_inventory.get(Defs.RESOURCE_WYRD, 0)) + HARVEST_AMOUNT
			simulation.stats["wyrd_extracted"] = int(simulation.stats.get("wyrd_extracted", 0)) + HARVEST_AMOUNT
			simulation.cumulative_wyrd_extracted = int(simulation.cumulative_wyrd_extracted) + HARVEST_AMOUNT
	if _has_completed(Defs.BUILDING_WYRD_REFINER):
		refine_timer += delta
		if refine_timer >= REFINE_INTERVAL:
			refine_timer = 0.0
			var raw := raw_stock()
			if raw >= REFINE_INPUT:
				simulation.central_inventory[Defs.RESOURCE_WYRD] = raw - REFINE_INPUT
				simulation.central_inventory[Defs.RESOURCE_STABILIZED_WYRD] = stabilized_stock() + REFINE_OUTPUT


func _update_exposure() -> void:
	var unlumened := 0
	for building in simulation.buildings:
		if bool(building.get("construction", false)):
			continue
		if String(building.get("type", "")) != Defs.BUILDING_WYRD_HARVESTER:
			continue
		var center: Vector2 = Vector2(simulation._footprint_center(building.get("position", Vector2i.ZERO), Defs.building_footprint(Defs.BUILDING_WYRD_HARVESTER)))
		if simulation.rivalry != null and not simulation.rivalry.is_lumen_connected_at(RivalryTuning.PLAYER_REALM, center):
			unlumened += 1
	exposure = clampf(float(raw_stock()) / 16.0 + 0.3 * float(unlumened), 0.0, 1.0)
	var band := "STABLE"
	if exposure >= 0.75:
		band = "CRITICAL"
	elif exposure >= 0.4:
		band = "RISING"
	if band != last_exposure_band and geologist_surveyed:
		last_exposure_band = band
		if band != "STABLE":
			simulation.push_notice("danger", "EXPOSURE", "Raw Wyrd exposure is %s. Refine it before the night feeds." % band.to_lower(), "warning")


func _maybe_force_capture() -> void:
	if rival_resolution != "" or assault_target_id <= 0 or assault_started_at < 0.0:
		return
	if float(simulation.elapsed_seconds) < assault_started_at + ASSAULT_FORCE_SECONDS:
		return
	var rivalry = simulation.rivalry
	if rivalry == null:
		return
	var target: Dictionary = rivalry._structure_by_id(assault_target_id)
	if target.is_empty() or int(target.get("hp", 0)) <= 0:
		return
	capture_outpost(target)


func _maybe_rival_takes_other() -> void:
	if rival_relocated or secondary_fissure.x < 0:
		return
	if rival_resolution == "capture" and float(simulation.elapsed_seconds) >= capture_at + 20.0:
		_relocate_rival_to_secondary("relocated")
		var message := "The rival abandons this vent and stakes another fissure further along the crater."
		simulation.last_message = message
		simulation._add_log(message)
		simulation._record_event("rival_relocated", message, {"tile": secondary_fissure})


func _relocate_rival_to_secondary(kind: String) -> void:
	var rivalry = simulation.rivalry
	if rivalry == null:
		return
	for structure in rivalry.get_structures(RivalryTuning.AI_REALM):
		if String(structure.get("type", "")) != RivalryTuning.STRUCTURE_CLAIMANT_OUTPOST:
			continue
		if int(structure.get("hp", 0)) <= 0:
			continue
		if rivalry.has_method("_destroy_structure"):
			rivalry._destroy_structure(int(structure.get("id", 0)))
	if rivalry.has_method("force_place_structure"):
		rivalry.force_place_structure(RivalryTuning.AI_REALM, RivalryTuning.STRUCTURE_CLAIMANT_OUTPOST, secondary_fissure)
	simulation._reveal_radius(secondary_fissure, 5)
	simulation.add_map_marker("rival", secondary_fissure, "Rival", 0.0)
	if rival_resolution == "":
		rival_resolution = kind
	rival_relocated = true
	rival_interacted = true


func _tick_ritual(delta: float) -> void:
	if not ritual_active or bool(simulation.game_finished):
		return
	if not _binding_outpost_alive():
		_fail_ritual("The ritual Outpost fell. Binding is broken.")
		return
	if not ritual_raid_spawned:
		ritual_raid_spawned = true
		if simulation.has_method("spawn_ritual_raid"):
			simulation.spawn_ritual_raid(RITUAL_RAID_SIZE)
	_ward_binding_outpost(delta)
	ritual_progress += delta
	if ritual_progress + 0.001 >= RITUAL_SECONDS:
		_complete_ritual()


func _complete_ritual() -> void:
	ritual_active = false
	simulation.reckoning_active = false
	simulation._update_objective_flag("claim")
	simulation._finish_run(true, "THE FISSURE IS BOUND — the ritual held.")


func _fail_ritual(reason: String) -> void:
	ritual_active = false
	ritual_progress = 0.0
	simulation.reckoning_active = false
	simulation.central_inventory[Defs.RESOURCE_STABILIZED_WYRD] = stabilized_stock() + STABILIZED_TO_BIND
	simulation.last_message = reason
	simulation._add_log(reason)
	simulation.push_notice("danger", "BINDING BROKEN", reason, "critical")
	simulation._record_event("binding_failed", reason, {})


func _ward_binding_outpost(delta: float) -> void:
	if simulation.rivalry == null:
		return
	for structure in simulation.rivalry.get_structures(RivalryTuning.PLAYER_REALM):
		if String(structure.get("type", "")) != RivalryTuning.STRUCTURE_CLAIMANT_OUTPOST:
			continue
		if int(structure.get("hp", 0)) <= 0:
			continue
		var max_hp := int(RivalryTuning.structure_definition(RivalryTuning.STRUCTURE_CLAIMANT_OUTPOST).get("max_hp", 220))
		if int(floor(ritual_progress)) != int(floor(ritual_progress - delta)):
			structure["hp"] = mini(int(structure.get("hp", 0)) + 3, max_hp)


func _binding_outpost_alive() -> bool:
	if simulation.rivalry == null:
		return false
	for structure in simulation.rivalry.get_structures(RivalryTuning.PLAYER_REALM):
		if String(structure.get("type", "")) != RivalryTuning.STRUCTURE_CLAIMANT_OUTPOST:
			continue
		if int(structure.get("hp", 0)) <= 0:
			continue
		return true
	return simulation._has_frontier_outpost()


func _has_completed(building_type: String) -> bool:
	return simulation._player_has_completed_building(building_type)


func _note_storehouse() -> void:
	if storehouse_completed_at >= 0.0:
		return
	if simulation._player_has_completed_building(Defs.BUILDING_STOREHOUSE):
		storehouse_completed_at = float(simulation.elapsed_seconds)
		simulation._record_event("storehouse_complete", "Storehouse completed.", {"seconds": storehouse_completed_at})


func _take_stabilized(amount: int) -> int:
	var have := stabilized_stock()
	var taken: int = mini(have, amount)
	simulation.central_inventory[Defs.RESOURCE_STABILIZED_WYRD] = have - taken
	return taken


func _clamp_tile(tile: Vector2i) -> Vector2i:
	return Vector2i(
		clampi(tile.x, 2, simulation.map_size.x - 3),
		clampi(tile.y, 2, simulation.map_size.y - 3)
	)


func _success(message: String) -> Dictionary:
	return {"success": true, "message": message}


func _failure(reason: String, message: String) -> Dictionary:
	return {"success": false, "reason": reason, "message": message}
