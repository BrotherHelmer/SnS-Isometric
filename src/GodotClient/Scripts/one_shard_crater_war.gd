extends RefCounted

## The Director: The Crater War vertical slice.
## Binding is at the frontier fissure — 12 Stabilized Wyrd plus a 120 s
## ritual that must be defended. The player starts it when the store is
## ready; there is no clock unlock. Survival (THE REALM HOLDS) is a
## milestone, not a win. One rival keeps contesting the same fissure.
## Economy pacing (not a timer) lands 12 Stabilized around minute 40–52.

const Defs = preload("one_shard_defs.gd")
const RivalryTuning = preload("one_shard_rivalry_tuning.gd")

const STABILIZED_TO_BIND := 12
const RITUAL_SECONDS := 120.0
const HARVEST_INTERVAL := 32.0
const HARVEST_AMOUNT := 1
const REFINE_INTERVAL := 22.0
const REFINE_INPUT := 3
const REFINE_OUTPUT := 1
const RAW_RESERVE := 3
const PASSAGE_WOOD := 8
const CAPTURE_WOOD := 8
const CAPTURE_STONE := 4
const CAPTURE_WYRD := 2
const CAPTURE_STABILIZED := 0
const ASSAULT_FORCE_SECONDS := 75.0
const LATER_ASSAULT_FORCE_SECONDS := 150.0
const RITUAL_RAID_SIZE := 2
const HARVESTER_RAID_SIZE := 1
const SECOND_PUSH_DELAY := 180.0
const HARVESTER_RAID_DELAY := 360.0
const CONTEST_REPEAT_DELAY := 150.0
const SECONDARY_OFFSET := Vector2i(8, -5)
const ROUTE_OUTPOST_MIN_T := 0.22
const ROUTE_OUTPOST_MAX_T := 0.82
const ROUTE_OUTPOST_SLACK := 6.5

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
var exposure_burn_timer := 0.0
var second_push_done := false
var second_push_at := -1.0
var harvester_raid_done := false
var harvester_raid_at := -1.0
var last_contest_at := -1.0
var contest_count := 0
var last_exposure_raid_band := ""
var first_12_at := -1.0


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
	exposure_burn_timer = 0.0
	second_push_done = false
	second_push_at = -1.0
	harvester_raid_done = false
	harvester_raid_at = -1.0
	last_contest_at = -1.0
	contest_count = 0
	last_exposure_raid_band = ""
	first_12_at = -1.0


func tick(delta: float) -> void:
	if simulation == null or bool(simulation.game_finished):
		return
	_note_storehouse()
	_tick_production(delta)
	_ward_harvester(delta)
	_update_exposure(delta)
	_maybe_force_capture()
	_maybe_rival_contest()
	_note_twelve()
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
	if capture_at < 0.0:
		capture_at = float(simulation.elapsed_seconds)
	rival_interacted = true
	simulation.central_inventory[Defs.RESOURCE_WOOD] = int(simulation.central_inventory.get(Defs.RESOURCE_WOOD, 0)) + CAPTURE_WOOD
	simulation.central_inventory[Defs.RESOURCE_STONE] = int(simulation.central_inventory.get(Defs.RESOURCE_STONE, 0)) + CAPTURE_STONE
	simulation.central_inventory[Defs.RESOURCE_WYRD] = int(simulation.central_inventory.get(Defs.RESOURCE_WYRD, 0)) + CAPTURE_WYRD
	if CAPTURE_STABILIZED > 0:
		simulation.central_inventory[Defs.RESOURCE_STABILIZED_WYRD] = int(simulation.central_inventory.get(Defs.RESOURCE_STABILIZED_WYRD, 0)) + CAPTURE_STABILIZED
	var message := "CLAIMANT OUTPOST CAPTURED — their stores are yours. +%d Wood, +%d Stone, +%d Wyrd. Hold the corridor; the rival will return." % [
		CAPTURE_WOOD, CAPTURE_STONE, CAPTURE_WYRD
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
	elif second_push_done:
		rival_line = "Rival second push — they still want this fissure"
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


func _ward_harvester(delta: float) -> void:
	if simulation == null or not bool(simulation.raid_active):
		return
	for building in simulation.buildings:
		if bool(building.get("construction", false)):
			continue
		if String(building.get("type", "")) != Defs.BUILDING_WYRD_HARVESTER:
			continue
		var max_hp := Defs.building_hp(Defs.BUILDING_WYRD_HARVESTER)
		if int(floor(float(simulation.elapsed_seconds))) != int(floor(float(simulation.elapsed_seconds) - delta)):
			building["hp"] = mini(int(building.get("hp", 0)) + 4, max_hp)


func _tick_production(delta: float) -> void:
	if _has_completed(Defs.BUILDING_WYRD_HARVESTER):
		harvest_timer += delta
		var interval := HARVEST_INTERVAL if route_secured() else HARVEST_INTERVAL * 2.0
		if harvest_timer >= interval:
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


func _update_exposure(delta: float) -> void:
	var unlumened := 1 if harvester_unlumened() else 0
	exposure = clampf(float(maxi(0, raw_stock() - RAW_RESERVE)) / 8.0 + 0.45 * float(unlumened), 0.0, 1.0)
	var band := "STABLE"
	if exposure >= 0.75:
		band = "CRITICAL"
	elif exposure >= 0.35:
		band = "RISING"
	if band != last_exposure_band and geologist_surveyed:
		last_exposure_band = band
		if band != "STABLE":
			var line := "Raw Wyrd exposure is %s. Raise a Lumen on the harvester or refine the surplus." % band.to_lower()
			simulation.push_notice("danger", "EXPOSURE", line, "warning")
			simulation._record_event("exposure_choice", line, {"band": band, "raw": raw_stock()})
	exposure_burn_timer += delta
	var burn_every := lerpf(48.0, 14.0, exposure)
	if exposure_burn_timer >= burn_every:
		exposure_burn_timer = 0.0
		if raw_stock() > RAW_RESERVE + REFINE_INPUT:
			simulation.central_inventory[Defs.RESOURCE_WYRD] = raw_stock() - 1
			if geologist_surveyed and band != "STABLE":
				simulation._record_event("exposure_burn", "Exposure burns a raw Wyrd above the reserve.", {"raw": raw_stock(), "band": band})


func _maybe_force_capture() -> void:
	if assault_target_id <= 0 or assault_started_at < 0.0:
		return
	var wait := LATER_ASSAULT_FORCE_SECONDS if second_push_done else ASSAULT_FORCE_SECONDS
	if float(simulation.elapsed_seconds) < assault_started_at + wait:
		return
	var rivalry = simulation.rivalry
	if rivalry == null:
		return
	var target: Dictionary = rivalry._structure_by_id(assault_target_id)
	if target.is_empty() or int(target.get("hp", 0)) <= 0:
		assault_target_id = 0
		assault_started_at = -1.0
		return
	assault_target_id = 0
	assault_started_at = -1.0
	capture_outpost(target)


func _maybe_rival_contest() -> void:
	if ritual_active or bool(simulation.game_finished):
		return
	if capture_at < 0.0 and rival_resolution == "":
		return
	var now := float(simulation.elapsed_seconds)
	var origin := capture_at if capture_at >= 0.0 else now
	if not second_push_done and now >= origin + SECOND_PUSH_DELAY:
		if _plant_rival_contest("second_push"):
			second_push_done = true
			second_push_at = now
			last_contest_at = now
	if not harvester_raid_done and now >= origin + HARVESTER_RAID_DELAY:
		if _call_harvester_raid("rival"):
			harvester_raid_done = true
			harvester_raid_at = now
	if second_push_done and last_contest_at >= 0.0 and now >= last_contest_at + CONTEST_REPEAT_DELAY:
		if not _rival_outpost_alive():
			if _plant_rival_contest("contest"):
				last_contest_at = now
	if last_exposure_band == "CRITICAL" and capture_at >= 0.0 and last_exposure_raid_band != "CRITICAL":
		last_exposure_raid_band = "CRITICAL"
		_call_harvester_raid("exposure")


func route_secured() -> bool:
	return _route_outpost_count() >= 1


func waypoint_tile() -> Vector2i:
	if primary_fissure.x < 0 or simulation == null:
		return Vector2i(-1, -1)
	var hall: Vector2i = simulation._footprint_center(simulation.town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	return _clamp_tile(Vector2i(
		int(round(float(hall.x) + float(primary_fissure.x - hall.x) * 0.48)),
		int(round(float(hall.y) + float(primary_fissure.y - hall.y) * 0.48))
	))


func harvester_unlumened() -> bool:
	if simulation == null or not _has_completed(Defs.BUILDING_WYRD_HARVESTER):
		return false
	for building in simulation.buildings:
		if bool(building.get("construction", false)):
			continue
		if String(building.get("type", "")) != Defs.BUILDING_WYRD_HARVESTER:
			continue
		var center: Vector2 = Vector2(simulation._footprint_center(building.get("position", Vector2i.ZERO), Defs.building_footprint(Defs.BUILDING_WYRD_HARVESTER)))
		if not _local_lumen_at(center):
			return true
	return false


func _local_lumen_at(point: Vector2) -> bool:
	var hall: Vector2i = simulation._footprint_center(simulation.town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	if point.distance_to(Vector2(hall)) <= RivalryTuning.HOME_LUMEN_RADIUS:
		return true
	if simulation.rivalry != null:
		for structure in simulation.rivalry.get_structures(RivalryTuning.PLAYER_REALM):
			if int(structure.get("hp", 0)) <= 0:
				continue
			if String(structure.get("type", "")) != RivalryTuning.STRUCTURE_LUMEN_PILLAR:
				continue
			var radius := float(RivalryTuning.structure_definition(RivalryTuning.STRUCTURE_LUMEN_PILLAR).get("lumen_radius", 10.0))
			var footprint: Vector2i = structure.get("footprint", Vector2i.ONE)
			var center := Vector2(structure.get("position", Vector2i.ZERO)) + Vector2(float(footprint.x - 1) * 0.5, float(footprint.y - 1) * 0.5)
			if point.distance_to(center) <= radius:
				return true
	for building in simulation.buildings:
		if bool(building.get("construction", false)):
			continue
		if String(building.get("type", "")) != Defs.BUILDING_LUMEN_PILLAR:
			continue
		var center: Vector2 = Vector2(simulation._footprint_center(building.get("position", Vector2i.ZERO), Defs.building_footprint(Defs.BUILDING_LUMEN_PILLAR)))
		if point.distance_to(center) <= 10.0:
			return true
	return false


func _route_outpost_count() -> int:
	if simulation == null or simulation.rivalry == null or primary_fissure.x < 0:
		return 0
	var hall: Vector2 = Vector2(simulation._footprint_center(simulation.town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL)))
	var fissure := Vector2(primary_fissure)
	var span := fissure - hall
	var length := span.length()
	if length < 1.0:
		return 0
	var count := 0
	for structure in simulation.rivalry.get_structures(RivalryTuning.PLAYER_REALM):
		if String(structure.get("type", "")) != RivalryTuning.STRUCTURE_CLAIMANT_OUTPOST:
			continue
		if int(structure.get("hp", 0)) <= 0:
			continue
		var footprint: Vector2i = structure.get("footprint", Vector2i(2, 2))
		var center := Vector2(structure.get("position", Vector2i.ZERO)) + Vector2(float(footprint.x - 1) * 0.5, float(footprint.y - 1) * 0.5)
		var along := (center - hall).dot(span) / (length * length)
		if along < ROUTE_OUTPOST_MIN_T or along > ROUTE_OUTPOST_MAX_T:
			continue
		var closest := hall + span * along
		if center.distance_to(closest) <= ROUTE_OUTPOST_SLACK:
			count += 1
	return count


func _plant_rival_contest(kind: String) -> bool:
	var rivalry = simulation.rivalry
	if rivalry == null or primary_fissure.x < 0:
		return false
	var tile := _contest_tile()
	if tile.x < 0:
		return false
	if not rivalry.has_method("force_place_structure"):
		return false
	var placed: Dictionary = rivalry.force_place_structure(RivalryTuning.AI_REALM, RivalryTuning.STRUCTURE_CLAIMANT_OUTPOST, tile)
	if not bool(placed.get("success", false)):
		return false
	contest_count += 1
	simulation._reveal_radius(tile, 5)
	simulation.add_map_marker("rival", tile, "Rival", 0.0)
	var message := "RIVAL PUSH — they raise another Outpost on the fissure." if kind == "second_push" else "The rival contests the fissure again."
	simulation.last_message = message
	simulation._add_log(message)
	simulation.push_notice("danger", "RIVAL", message, "warning")
	simulation._record_event("rival_second_push" if kind == "second_push" else "rival_contest", message, {"tile": tile, "kind": kind})
	rival_interacted = true
	return true


func _contest_tile() -> Vector2i:
	if primary_fissure.x < 0:
		return Vector2i(-1, -1)
	var hall: Vector2i = simulation._footprint_center(simulation.town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	var away := Vector2(primary_fissure - hall)
	if away.length_squared() < 0.01:
		away = Vector2(1.0, 0.0)
	away = away.normalized()
	var perp := Vector2(-away.y, away.x)
	var sign := 1.0 if contest_count % 2 == 0 else -1.0
	var aims: Array[Vector2i] = []
	for radius in range(3, 8):
		var along := primary_fissure + Vector2i(roundi(away.x * float(radius) * 0.4), roundi(away.y * float(radius) * 0.4))
		var side := primary_fissure + Vector2i(roundi(perp.x * float(radius) * sign), roundi(perp.y * float(radius) * sign))
		aims.append(_clamp_tile(side))
		aims.append(_clamp_tile(along))
		aims.append(_clamp_tile(primary_fissure + Vector2i(radius, 0) * int(sign)))
		aims.append(_clamp_tile(primary_fissure + Vector2i(0, radius) * int(sign)))
	for aim in aims:
		if not simulation.is_inside_map(aim):
			continue
		if simulation.rivalry != null:
			var existing: Dictionary = simulation.rivalry.get_structure_at_tile(aim)
			if not existing.is_empty():
				continue
		if not simulation.get_building_at_tile(aim).is_empty():
			continue
		return aim
	return _clamp_tile(primary_fissure + SECONDARY_OFFSET)


func _call_harvester_raid(reason: String) -> bool:
	if ritual_active or bool(simulation.game_finished):
		return false
	if not _has_completed(Defs.BUILDING_WYRD_HARVESTER):
		return false
	if not simulation.has_method("spawn_harvester_raid"):
		return false
	simulation.spawn_harvester_raid(HARVESTER_RAID_SIZE)
	var message := "HARVESTER RAID — the rival strikes the Wyrd vent." if reason == "rival" else "EXPOSURE RAID — raw Wyrd draws hostiles to the harvester."
	simulation.last_message = message
	simulation._add_log(message)
	simulation.push_notice("danger", "RAID", message, "critical")
	simulation._record_event("harvester_raid", message, {"reason": reason})
	return true


func _rival_outpost_alive() -> bool:
	if simulation.rivalry == null:
		return false
	for structure in simulation.rivalry.get_structures(RivalryTuning.AI_REALM):
		if String(structure.get("type", "")) != RivalryTuning.STRUCTURE_CLAIMANT_OUTPOST:
			continue
		if int(structure.get("hp", 0)) > 0:
			return true
	return false


func _note_twelve() -> void:
	if first_12_at >= 0.0:
		return
	if stabilized_stock() >= STABILIZED_TO_BIND:
		first_12_at = float(simulation.elapsed_seconds)
		simulation._record_event("stabilized_12", "Store reached 12 Stabilized Wyrd.", {"seconds": first_12_at})


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
