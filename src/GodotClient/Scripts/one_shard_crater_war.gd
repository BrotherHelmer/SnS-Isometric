extends RefCounted

## The Director: TEST #20 — idle settlers take haul / repair /
## construction jobs, Channel Wyrd costs are honest (first use draws
## the ceremony's emergency reserve), and the caravan aftermath stays
## on the map. Channel still costs 2 Stabilized, repairs one wall/ward,
## and cools for 20 s. The bot channels at least once per Seal.

const Defs = preload("one_shard_defs.gd")
const RivalryTuning = preload("one_shard_rivalry_tuning.gd")

const STABILIZED_TO_BIND := 12
const STABILIZED_TO_CHOOSE := 6
const RITUAL_SECONDS := 120.0
const HARVEST_INTERVAL := 32.0
const HARVEST_AMOUNT := 1
const REFINE_INTERVAL := 22.0
const REFINE_INPUT := 3
const REFINE_OUTPUT := 1
const RAW_RESERVE := 3
const PATH_REFINE := "refine"
const PATH_SECURE := "secure"
const SECURE_INVESTMENT := 3
const REFINE_PATH_INTERVAL := 12.0
const REFINE_PATH_INPUT := 3
const SECURE_HARVEST_INTERVAL := 18.0
const PASSAGE_WOOD := 8
const CAPTURE_WOOD := 8
const CAPTURE_STONE := 4
const CAPTURE_WYRD := 2
const CAPTURE_STABILIZED := 0
const ASSAULT_FORCE_SECONDS := 75.0
const LATER_ASSAULT_FORCE_SECONDS := 150.0
const RITUAL_RAID_SIZE := 2
const HARVESTER_RAID_SIZE := 1
const SECURE_RAID_SIZE := 0
const RIVAL_REVEAL_MIN := 14.0 * 60.0
const RIVAL_REVEAL_SPAN := 6.0 * 60.0
const REACTION_MIN := 8.0
const REACTION_SPAN := 16.0
const CONTEST_REPEAT_DELAY := 150.0
const SECONDARY_OFFSET := Vector2i(8, -5)
const ROUTE_OUTPOST_MIN_T := 0.22
const ROUTE_OUTPOST_MAX_T := 0.82
const ROUTE_OUTPOST_SLACK := 6.5
const BOT_PATH_SEEDS := [260821, 261306, 261597, 260918]
const PATH_WALL := "wall"
const PATH_OVERCHARGE := "overcharge"
const SEAL_CHOICE_AT := 60.0
const WALL_RITUAL_EXTRA := 20.0
const OVERCHARGE_RITUAL_CUT := 20.0
const WALL_HP_BOOST := 80
const WALL_WARD := 6
const OVERCHARGE_WARD := 1
const DEFAULT_WARD := 3
const OVERCHARGE_RAID_SIZE := 1
const TIER_QUIET := 0
const TIER_SMOKE := 1
const TIER_SIGHTED := 2
const TIER_PUSH := 3
const TIER_RAID := 4
const TIER_NAMES := ["QUIET", "SMOKE", "SIGHTED", "PUSH", "RAID"]
const FORESHADOW_MIN := 10.0 * 60.0
const FORESHADOW_SPAN := 5.0 * 60.0
const FORESHADOW_LEAD := 45.0
const PATH_SHELTER := "shelter"
const PATH_FORTIFY := "fortify"
const MIDGAME_MIN := 15.0 * 60.0
const MIDGAME_SPAN := 5.0 * 60.0
const MIDGAME_LATEST := 22.0 * 60.0
const SHELTER_WORKERS := 2
const SHELTER_EXPOSURE := 0.22
const FORTIFY_WOOD := 4
const FORTIFY_PUSH_DELAY := 18.0
const FORTIFY_WALLS := 3
const CHANNEL_COST := 2
const CHANNEL_COOLDOWN := 20.0
const CHANNEL_REPAIR_HP := 40
const SHELTER_TENTS := 3

# Weak back-reference (same pattern as the rivalry rules): a strong one
# formed a RefCounted cycle with the simulation, so neither was ever
# freed ("resources still in use at exit").
var _simulation_ref: WeakRef
var simulation:
	get:
		return _simulation_ref.get_ref() if _simulation_ref != null else null
	set(value):
		_simulation_ref = weakref(value) if value != null else null
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
var refiner_pending_since := -1.0
var first_harvest_at := -1.0
var first_stabilized_at := -1.0
var rival_reveal_at := -1.0
var push_reaction := 12.0
var raid_reaction := 16.0
var wyrd_choice := ""
var choice_offered_at := -1.0
var choice_taken_at := -1.0
var seal_choice := ""
var seal_choice_offered_at := -1.0
var seal_choice_taken_at := -1.0
var ritual_needed := RITUAL_SECONDS
var seal_overcharge_raid_spawned := false
var rival_threat_tier := TIER_QUIET
var rival_foreshadow_at := -1.0
var rival_foreshadowed := false
var push_telegraphed := false
var raid_telegraphed := false
var banner_count := 0
var midgame_choice := ""
var midgame_offered_at := -1.0
var midgame_taken_at := -1.0
var midgame_at := -1.0
var shelter_exposure := 0.0
var fortify_walls := 0
var victory_ceremony := false
var channel_uses := 0
var channel_ready_at := -1.0
var channel_reserve := 0
var last_channel_from_reserve := false
var last_channel_at := -1.0
var last_channel_tile := Vector2i(-1, -1)
var first_build_at := -1.0


func setup(owner) -> void:
	simulation = owner
	reset()
	_seed_rival_timing()


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
	refiner_pending_since = -1.0
	first_harvest_at = -1.0
	first_stabilized_at = -1.0
	rival_reveal_at = -1.0
	push_reaction = 12.0
	raid_reaction = 16.0
	wyrd_choice = ""
	choice_offered_at = -1.0
	choice_taken_at = -1.0
	seal_choice = ""
	seal_choice_offered_at = -1.0
	seal_choice_taken_at = -1.0
	ritual_needed = RITUAL_SECONDS
	seal_overcharge_raid_spawned = false
	rival_threat_tier = TIER_QUIET
	rival_foreshadow_at = -1.0
	rival_foreshadowed = false
	push_telegraphed = false
	raid_telegraphed = false
	banner_count = 0
	midgame_choice = ""
	midgame_offered_at = -1.0
	midgame_taken_at = -1.0
	midgame_at = -1.0
	shelter_exposure = 0.0
	fortify_walls = 0
	victory_ceremony = false
	channel_uses = 0
	channel_ready_at = -1.0
	channel_reserve = 0
	last_channel_from_reserve = false
	last_channel_at = -1.0
	last_channel_tile = Vector2i(-1, -1)
	first_build_at = -1.0
	if simulation != null:
		_seed_rival_timing()


func tick(delta: float) -> void:
	if simulation == null or bool(simulation.game_finished):
		return
	_note_storehouse()
	_note_first_build()
	_unstick_refiner()
	_tick_production(delta)
	_ward_harvester(delta)
	_update_exposure(delta)
	_maybe_force_capture()
	_maybe_offer_choice()
	_maybe_foreshadow()
	_maybe_offer_midgame()
	_maybe_escalate_map()
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
		"summary": "Ready to Seal the Fissure." if missing.is_empty() else "Needs: %s." % ", ".join(missing)
	}


func request_begin() -> Dictionary:
	var requirements := begin_requirements()
	if not bool(requirements.get("ready", false)):
		return _failure("ClaimRequirements", String(requirements.get("summary", "Seal requirements are not met.")))
	var taken := _take_stabilized(STABILIZED_TO_BIND)
	if taken < STABILIZED_TO_BIND:
		return _failure("Wyrd", "The ceremony needs %d Stabilized Wyrd in the store." % STABILIZED_TO_BIND)
	# Hold 2 as an emergency reserve. The store stays at 0 so the first
	# Channel is visibly paid from that reserve, not a silent refund.
	channel_reserve = CHANNEL_COST
	last_channel_from_reserve = false
	channel_uses = 0
	last_channel_at = -1.0
	last_channel_tile = Vector2i(-1, -1)
	channel_ready_at = float(simulation.elapsed_seconds)
	ritual_active = true
	ritual_progress = 0.0
	ritual_raid_spawned = false
	ritual_needed = RITUAL_SECONDS
	seal_choice = ""
	seal_choice_offered_at = -1.0
	seal_choice_taken_at = -1.0
	seal_overcharge_raid_spawned = false
	ritual_started_at = float(simulation.elapsed_seconds)
	simulation.reckoning_active = true
	var message := "SEAL BEGUN — defend the fissure ceremony for 120 seconds."
	simulation.last_message = message
	simulation._add_log(message)
	simulation.push_notice("danger", "SEAL", message, "critical")
	simulation._record_event("binding_started", message, {"stabilized": STABILIZED_TO_BIND, "climax": "seal"})
	simulation._mark_onboarding("binding")
	return _success(message)


func channel_ready() -> bool:
	if simulation == null or not ritual_active or bool(simulation.game_finished):
		return false
	if not _channel_affordable():
		return false
	if channel_ready_at >= 0.0 and float(simulation.elapsed_seconds) + 0.001 < channel_ready_at:
		return false
	return true


func _channel_affordable() -> bool:
	return channel_reserve >= CHANNEL_COST or stabilized_stock() >= CHANNEL_COST


func request_channel() -> Dictionary:
	if simulation == null or not ritual_active:
		return _failure("Idle", "Channel Wyrd only works during the Seal.")
	if bool(simulation.game_finished):
		return _failure("Finished", "The ceremony has already closed.")
	if channel_ready_at >= 0.0 and float(simulation.elapsed_seconds) + 0.001 < channel_ready_at:
		return _failure("Cooldown", "Channel Wyrd is cooling for %d s." % int(ceil(channel_ready_at - float(simulation.elapsed_seconds))))
	if not _channel_affordable():
		return _failure("Wyrd", "Channel Wyrd costs %d Stabilized Wyrd." % CHANNEL_COST)
	var from_reserve := channel_reserve >= CHANNEL_COST
	if from_reserve:
		channel_reserve = 0
	else:
		_take_stabilized(CHANNEL_COST)
	last_channel_from_reserve = from_reserve
	var target: Dictionary = preview_channel_target()
	var tile := _repair_one_segment()
	channel_uses += 1
	last_channel_at = float(simulation.elapsed_seconds)
	channel_ready_at = last_channel_at + CHANNEL_COOLDOWN
	last_channel_tile = tile
	if tile.x >= 0:
		simulation.add_map_marker("channel", tile, "CHANNEL WYRD", last_channel_at + 4.0)
	var kind := String(target.get("kind", "wall"))
	var message := "CHANNEL WYRD — emergency reserve repairs the %s." % kind if from_reserve else "CHANNEL WYRD — 2 Stabilized repairs the %s." % kind
	simulation.last_message = message
	simulation._add_log(message)
	simulation.push_notice("info", "CHANNEL", message, "warning")
	simulation._record_event("channel_wyrd", message, {
		"uses": channel_uses,
		"tile": tile,
		"stabilized": CHANNEL_COST,
		"from_reserve": from_reserve,
		"target": kind
	})
	if simulation.has_method("_emit_audio"):
		simulation._emit_audio("wyrd")
	return _success(message)


func preview_channel_target() -> Dictionary:
	var found: Dictionary = _find_channel_target()
	if found.is_empty():
		return {
			"kind": "fissure",
			"tile": primary_fissure if primary_fissure.x >= 0 else Vector2i(-1, -1)
		}
	return found


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
	var message := "THE REALM HOLDS — five days on the frontier. Seal the Fissure is the war that remains. Shard Binding is a later act."
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
	elif rival_foreshadowed:
		rival_line = "Distant rival smoke — a scout names the next vent"
	if rival_threat_tier > TIER_QUIET:
		var threat_bit := "TIER %d %s" % [rival_threat_tier, threat_name()]
		rival_line = threat_bit if rival_line == "" else "%s — %s" % [threat_bit, rival_line]
	return {
		"binding_active": ritual_active,
		"binding_ready": can_begin(),
		"binding_percent": percent,
		"binding_summary": "SEAL THE FISSURE — %d%%" % percent if ritual_active else begin_requirements().get("summary", ""),
		"rival_line": rival_line,
		"exposure": exposure,
		"stabilized": stabilized_stock(),
		"surveyed": geologist_surveyed,
		"resolution": rival_resolution,
		"choice_ready": choice_ready(),
		"choice": wyrd_choice,
		"choice_offered_at": choice_offered_at,
		"rival_reveal_at": rival_reveal_at,
		"seal_ready": can_begin(),
		"seal_active": ritual_active,
		"seal_choice_ready": seal_choice_ready(),
		"seal_choice": seal_choice,
		"seal_choice_offered_at": seal_choice_offered_at,
		"threat_tier": rival_threat_tier,
		"threat_name": threat_name(),
		"foreshadow_at": rival_foreshadow_at,
		"foreshadowed": rival_foreshadowed,
		"banner_count": banner_count,
		"midgame_choice_ready": midgame_choice_ready(),
		"midgame_choice": midgame_choice,
		"midgame_offered_at": midgame_offered_at,
		"midgame_at": midgame_at,
		"fortify_walls": fortify_walls,
		"shelter_exposure": shelter_exposure,
		"victory_ceremony": victory_ceremony,
		"channel_ready": channel_ready(),
		"channel_uses": channel_uses,
		"channel_ready_at": channel_ready_at,
		"last_channel_at": last_channel_at,
		"last_channel_tile": last_channel_tile,
		"channel_reserve": channel_reserve,
		"channel_from_reserve": last_channel_from_reserve or channel_reserve >= CHANNEL_COST,
		"channel_cost": CHANNEL_COST,
		"channel_cooldown": CHANNEL_COOLDOWN,
		"channel_target_tile": preview_channel_target().get("tile", last_channel_tile),
		"channel_target_kind": String(preview_channel_target().get("kind", "")),
		"first_build_at": first_build_at,
		"seal_look": seal_look()
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


func _unstick_refiner() -> void:
	var pending := {}
	for building in simulation.buildings:
		if bool(building.get("construction", false)) and String(building.get("planned_type", "")) == Defs.BUILDING_WYRD_REFINER:
			pending = building
			break
	if pending.is_empty():
		refiner_pending_since = -1.0
		return
	if refiner_pending_since < 0.0:
		refiner_pending_since = float(simulation.elapsed_seconds)
	if float(simulation.elapsed_seconds) < refiner_pending_since + 180.0:
		return
	if simulation.has_method("finish_construction"):
		simulation.finish_construction(pending)
		simulation._record_event("refiner_unstick", "The Wyrd Refiner is forced complete so the store can run.", {})


func _tick_production(delta: float) -> void:
	if _has_completed(Defs.BUILDING_WYRD_HARVESTER):
		harvest_timer += delta
		var interval := _harvest_interval()
		if harvest_timer >= interval:
			harvest_timer = 0.0
			simulation.central_inventory[Defs.RESOURCE_WYRD] = int(simulation.central_inventory.get(Defs.RESOURCE_WYRD, 0)) + HARVEST_AMOUNT
			simulation.stats["wyrd_extracted"] = int(simulation.stats.get("wyrd_extracted", 0)) + HARVEST_AMOUNT
			simulation.cumulative_wyrd_extracted = int(simulation.cumulative_wyrd_extracted) + HARVEST_AMOUNT
			if first_harvest_at < 0.0:
				first_harvest_at = float(simulation.elapsed_seconds)
				simulation._record_event("first_harvest", "The harvester drinks the first raw Wyrd.", {"seconds": first_harvest_at})
	if _has_completed(Defs.BUILDING_WYRD_REFINER):
		refine_timer += delta
		if refine_timer >= _refine_interval():
			refine_timer = 0.0
			var raw := raw_stock()
			var need := _refine_input()
			if raw >= need:
				simulation.central_inventory[Defs.RESOURCE_WYRD] = raw - need
				simulation.central_inventory[Defs.RESOURCE_STABILIZED_WYRD] = stabilized_stock() + REFINE_OUTPUT
				if first_stabilized_at < 0.0:
					first_stabilized_at = float(simulation.elapsed_seconds)
					simulation._record_event("first_stabilized", "The refiner yields the first Stabilized Wyrd.", {"seconds": first_stabilized_at})


func _update_exposure(delta: float) -> void:
	var unlumened := 1 if harvester_unlumened() else 0
	exposure = clampf(float(maxi(0, raw_stock() - RAW_RESERVE)) / 8.0 + 0.45 * float(unlumened) + shelter_exposure, 0.0, 1.0)
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
	var now := float(simulation.elapsed_seconds)
	# Push after the player's first harvest, once the rival is on the map.
	if not second_push_done and first_harvest_at >= 0.0 and bool(simulation.demo_rival_revealed):
		if now + 0.001 >= first_harvest_at + push_reaction and now + 0.001 >= rival_reveal_at:
			if _plant_rival_contest("second_push"):
				second_push_done = true
				second_push_at = now
				last_contest_at = now
	# Raid after the player's first Stabilized. Path B lowers the pressure.
	if not harvester_raid_done and first_stabilized_at >= 0.0:
		if now + 0.001 >= first_stabilized_at + raid_reaction:
			if _harvester_raid_size() <= 0:
				harvester_raid_done = true
				harvester_raid_at = now
				simulation._record_event("harvester_raid", "SECURE HARVEST — the invested ward turns the rival raid aside.", {"reason": "secure", "size": 0})
			elif _call_harvester_raid("rival"):
				harvester_raid_done = true
				harvester_raid_at = now
	if second_push_done and last_contest_at >= 0.0 and now >= last_contest_at + CONTEST_REPEAT_DELAY:
		if not _rival_outpost_alive():
			if _plant_rival_contest("contest"):
				last_contest_at = now


func route_secured() -> bool:
	# Path B buys a secured vent. Otherwise a living Outpost on the
	# vent or the hall–fissure corridor unlocks full harvest.
	if wyrd_choice == PATH_SECURE:
		return true
	return _route_outpost_count() >= 1 or _binding_outpost_alive()


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
	simulation.spawn_harvester_raid(_harvester_raid_size())
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
		_fail_ritual("The ceremony Outpost fell. The Seal is broken.")
		return
	if not ritual_raid_spawned:
		ritual_raid_spawned = true
		if simulation.has_method("spawn_ritual_raid"):
			simulation.spawn_ritual_raid(RITUAL_RAID_SIZE)
	_ward_binding_outpost(delta)
	ritual_progress += delta
	_maybe_offer_seal_choice()
	if ritual_progress + 0.001 >= ritual_needed:
		_complete_ritual()


func _complete_ritual() -> void:
	ritual_active = false
	simulation.reckoning_active = false
	_begin_victory_ceremony()
	simulation._update_objective_flag("claim")
	simulation._finish_run(true, "THE FISSURE IS SEALED — the ceremony held.")


func _fail_ritual(reason: String) -> void:
	ritual_active = false
	ritual_progress = 0.0
	ritual_needed = RITUAL_SECONDS
	seal_choice = ""
	simulation.reckoning_active = false
	simulation.central_inventory[Defs.RESOURCE_STABILIZED_WYRD] = stabilized_stock() + STABILIZED_TO_BIND
	simulation.last_message = reason
	simulation._add_log(reason)
	simulation.push_notice("danger", "SEAL BROKEN", reason, "critical")
	simulation._record_event("binding_failed", reason, {"climax": "seal"})


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
			var boosted := max_hp + (WALL_HP_BOOST if seal_choice == PATH_WALL else 0)
			structure["hp"] = mini(int(structure.get("hp", 0)) + _ritual_ward_amount(), boosted)


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


func _seed_rival_timing() -> void:
	if simulation == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = int(simulation.rng_seed) * 17 + 916
	rival_reveal_at = RIVAL_REVEAL_MIN + rng.randf() * RIVAL_REVEAL_SPAN
	push_reaction = REACTION_MIN + rng.randf() * REACTION_SPAN
	raid_reaction = REACTION_MIN + rng.randf() * REACTION_SPAN
	var latest_smoke := minf(FORESHADOW_MIN + FORESHADOW_SPAN, rival_reveal_at - FORESHADOW_LEAD)
	var smoke_span := maxf(1.0, latest_smoke - FORESHADOW_MIN)
	rival_foreshadow_at = FORESHADOW_MIN + rng.randf() * smoke_span
	_seed_midgame_timing()


func rival_reveal_seconds() -> float:
	if rival_reveal_at < 0.0:
		_seed_rival_timing()
	return rival_reveal_at


func choice_ready() -> bool:
	if wyrd_choice != "" or ritual_active or bool(simulation.game_finished):
		return false
	return stabilized_stock() >= STABILIZED_TO_CHOOSE


func bot_path_for_seed(seed_value: int) -> String:
	var index := BOT_PATH_SEEDS.find(seed_value)
	if index < 0:
		index = posmod(seed_value, 2)
	return PATH_REFINE if index % 2 == 0 else PATH_SECURE


func request_choice(path: String) -> Dictionary:
	if not choice_ready():
		if wyrd_choice != "":
			return _failure("Chosen", "The Wyrd pact is already sealed: %s." % wyrd_choice)
		return _failure("NotReady", "The store needs %d Stabilized Wyrd before a pact." % STABILIZED_TO_CHOOSE)
	var picked := path.strip_edges().to_lower()
	if picked == "a" or picked == "focus" or picked == "faster":
		picked = PATH_REFINE
	if picked == "b" or picked == "invest" or picked == "ward":
		picked = PATH_SECURE
	if picked != PATH_REFINE and picked != PATH_SECURE:
		return _failure("Path", "Choose faster refining or secure harvesting.")
	if picked == PATH_SECURE:
		var taken := _take_stabilized(SECURE_INVESTMENT)
		if taken < SECURE_INVESTMENT:
			return _failure("Wyrd", "Secure harvesting invests %d Stabilized Wyrd." % SECURE_INVESTMENT)
	wyrd_choice = picked
	choice_taken_at = float(simulation.elapsed_seconds)
	var message := ""
	if picked == PATH_REFINE:
		message = "FASTER REFINING — the kiln runs hotter. Raw converts before exposure can burn it."
	else:
		message = "SECURE HARVEST — 3 Stabilized ward the vent. Raids lose their teeth."
	simulation.last_message = message
	simulation._add_log(message)
	simulation.push_notice("info", "PACT", message, "warning")
	simulation._record_event("wyrd_choice", message, {"path": picked, "seconds": choice_taken_at})
	return _success(message)


func shard_binding_hook() -> Dictionary:
	# Later act: the real Shard Binding is not implemented this hour.
	return {
		"available": false,
		"act": "later",
		"summary": "Shard Binding is a later act. This hour Seals the Fissure."
	}


func _maybe_offer_choice() -> void:
	if choice_offered_at >= 0.0 or not choice_ready():
		return
	choice_offered_at = float(simulation.elapsed_seconds)
	var message := "6 STABILIZED — choose faster refining, or invest 3 to secure the harvester."
	simulation.last_message = message
	simulation._add_log(message)
	simulation.push_notice("info", "CHOICE", message, "warning")
	simulation._record_event("wyrd_choice_offered", message, {"stabilized": stabilized_stock()})


func seal_choice_ready() -> bool:
	if not ritual_active or seal_choice != "" or bool(simulation.game_finished):
		return false
	return ritual_progress + 0.001 >= SEAL_CHOICE_AT


func bot_seal_path_for_seed(seed_value: int) -> String:
	var index := BOT_PATH_SEEDS.find(seed_value)
	if index < 0:
		index = posmod(seed_value, 2)
	return PATH_WALL if index % 2 == 0 else PATH_OVERCHARGE


func request_seal_choice(path: String) -> Dictionary:
	if not seal_choice_ready():
		if seal_choice != "":
			return _failure("Chosen", "The Seal defence is already committed: %s." % seal_choice)
		if not ritual_active:
			return _failure("NotReady", "The Seal ceremony has not begun.")
		return _failure("NotReady", "The Seal defence choice opens at 60 seconds.")
	var picked := path.strip_edges().to_lower()
	if picked == "a" or picked == "reinforce" or picked == "wall" or picked == "defend":
		picked = PATH_WALL
	if picked == "b" or picked == "overcharge" or picked == "charge" or picked == "surge":
		picked = PATH_OVERCHARGE
	if picked != PATH_WALL and picked != PATH_OVERCHARGE:
		return _failure("Path", "Choose reinforce the wall or overcharge the Seal.")
	seal_choice = picked
	seal_choice_taken_at = float(simulation.elapsed_seconds)
	var message := ""
	if picked == PATH_WALL:
		ritual_needed = RITUAL_SECONDS + WALL_RITUAL_EXTRA
		_reinforce_ceremony_wall()
		message = "WALL REINFORCED — the palisade holds. The ceremony needs 20 more seconds."
	else:
		ritual_needed = maxf(ritual_progress + 1.0, RITUAL_SECONDS - OVERCHARGE_RITUAL_CUT)
		_overcharge_seal()
		message = "SEAL OVERCHARGED — the rite finishes faster. The wall is thinner and another wave comes."
	simulation.last_message = message
	simulation._add_log(message)
	simulation.push_notice("danger", "SEAL CHOICE", message, "warning")
	simulation._record_event("seal_choice", message, {"path": picked, "seconds": seal_choice_taken_at, "needed": ritual_needed})
	simulation.add_map_marker("seal_choice", primary_fissure, "Seal: %s" % picked, 0.0)
	return _success(message)


func _maybe_offer_seal_choice() -> void:
	if seal_choice_offered_at >= 0.0 or not seal_choice_ready():
		return
	seal_choice_offered_at = float(simulation.elapsed_seconds)
	var message := "60s SEAL DEFENCE — reinforce the wall, or overcharge the Seal."
	simulation.last_message = message
	simulation._add_log(message)
	simulation.push_notice("info", "SEAL CHOICE", message, "warning")
	simulation._record_event("seal_choice_offered", message, {"progress": ritual_progress})


func midgame_choice_ready() -> bool:
	if midgame_choice != "" or ritual_active or bool(simulation.game_finished):
		return false
	return midgame_offered_at >= 0.0


func midgame_seconds() -> float:
	if midgame_at < 0.0:
		_seed_midgame_timing()
	return midgame_at


func bot_midgame_path_for_seed(seed_value: int) -> String:
	var index := BOT_PATH_SEEDS.find(seed_value)
	if index < 0:
		index = posmod(seed_value, 2)
	return PATH_SHELTER if index % 2 == 0 else PATH_FORTIFY


func request_midgame_choice(path: String) -> Dictionary:
	if not midgame_choice_ready():
		if midgame_choice != "":
			return _failure("Chosen", "The caravan has already been answered: %s." % midgame_choice)
		return _failure("NotReady", "No refugee caravan is at the gate.")
	var picked := path.strip_edges().to_lower()
	if picked == "a" or picked == "accept" or picked == "workers" or picked == "refugees":
		picked = PATH_SHELTER
	if picked == "b" or picked == "walls" or picked == "palisade" or picked == "delay":
		picked = PATH_FORTIFY
	if picked != PATH_SHELTER and picked != PATH_FORTIFY:
		return _failure("Path", "Choose shelter the refugees or fortify the yard.")
	midgame_choice = picked
	midgame_taken_at = float(simulation.elapsed_seconds)
	var message := ""
	if picked == PATH_SHELTER:
		_shelter_refugees()
		message = "REFUGEES SHELTERED — two workers take the hall. The extra mouths raise Wyrd exposure."
	else:
		_fortify_yard()
		message = "YARD FORTIFIED — palisades go up. The rival's first push is delayed."
	simulation.last_message = message
	simulation._add_log(message)
	simulation.push_notice("info", "CARAVAN", message, "warning")
	simulation._record_event("midgame_choice", message, {"path": picked, "seconds": midgame_taken_at})
	return _success(message)


func _maybe_offer_midgame() -> void:
	if midgame_offered_at >= 0.0 or midgame_choice != "" or bool(simulation.game_finished):
		return
	if second_push_done:
		return
	if midgame_at < 0.0:
		_seed_midgame_timing()
	var now := float(simulation.elapsed_seconds)
	if now + 0.001 < MIDGAME_MIN:
		return
	var push_imminent := first_harvest_at >= 0.0 and bool(simulation.demo_rival_revealed) and now + 0.001 >= first_harvest_at + push_reaction - 2.0
	if now + 0.001 < midgame_at and not push_imminent:
		return
	if now > MIDGAME_LATEST + 0.001 and not push_imminent:
		return
	midgame_offered_at = now
	var tile := _caravan_tile()
	simulation._reveal_radius(tile, 4)
	simulation.add_map_marker("caravan", tile, "Refugee caravan", 0.0)
	var message := "REFUGEE CARAVAN — shelter two workers and raise exposure, or spend wood to raise palisades and delay the first push."
	simulation.last_message = message
	simulation._add_log(message)
	simulation.push_notice("info", "CARAVAN", message, "warning")
	simulation._record_event("midgame_choice_offered", message, {"seconds": now, "tile": tile})


func _seed_midgame_timing() -> void:
	if simulation == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = int(simulation.rng_seed) * 31 + 418
	midgame_at = minf(MIDGAME_LATEST, MIDGAME_MIN + rng.randf() * MIDGAME_SPAN)


func _shelter_refugees() -> void:
	if simulation == null:
		return
	simulation.housing_capacity += SHELTER_WORKERS
	simulation.population_current = mini(simulation.housing_capacity, int(simulation.population_current) + SHELTER_WORKERS)
	simulation.stats["peak_population"] = maxi(int(simulation.stats.get("peak_population", 0)), int(simulation.population_current))
	shelter_exposure = SHELTER_EXPOSURE
	if simulation.has_method("_ensure_carriers"):
		simulation._ensure_carriers()
	if simulation.has_method("_auto_staff_unstaffed_buildings"):
		simulation._auto_staff_unstaffed_buildings()
	if simulation.has_method("_emit_audio"):
		simulation._emit_audio("settler_spawn_worker")
	_plant_shelter_camp()


func _fortify_yard() -> void:
	if simulation == null:
		return
	var wood := int(simulation.central_inventory.get(Defs.RESOURCE_WOOD, 0))
	var spent: int = mini(wood, FORTIFY_WOOD)
	simulation.central_inventory[Defs.RESOURCE_WOOD] = wood - spent
	push_reaction += FORTIFY_PUSH_DELAY
	_plant_yard_palisades()
	simulation.add_map_marker("palisade", simulation.town_hall_position + Vector2i(2, 1), "Yard palisade", 0.0)


func _plant_yard_palisades() -> void:
	if simulation == null:
		return
	var hall: Vector2i = simulation.town_hall_position
	var aims: Array[Vector2i] = []
	for radius in range(2, 8):
		for ox in range(-radius, radius + 1):
			aims.append(_clamp_tile(hall + Vector2i(ox, radius)))
			aims.append(_clamp_tile(hall + Vector2i(ox, -radius)))
			aims.append(_clamp_tile(hall + Vector2i(radius, ox)))
			aims.append(_clamp_tile(hall + Vector2i(-radius, ox)))
	for tile in aims:
		if fortify_walls >= FORTIFY_WALLS:
			break
		if not simulation.is_inside_map(tile):
			continue
		if not simulation.get_building_at_tile(tile).is_empty():
			continue
		if simulation.rivalry != null:
			var existing: Dictionary = simulation.rivalry.get_structure_at_tile(tile)
			if not existing.is_empty():
				continue
		var wall: Dictionary = simulation._create_building(Defs.BUILDING_WALL, tile)
		wall["construction"] = false
		wall["completed"] = true
		simulation.buildings.append(wall)
		simulation.add_map_marker("palisade", tile, "Palisade", 0.0)
		fortify_walls += 1
	while fortify_walls < FORTIFY_WALLS:
		var fallback := _clamp_tile(hall + Vector2i(3 + fortify_walls, 2))
		simulation.add_map_marker("palisade", fallback, "Palisade", 0.0)
		fortify_walls += 1


func _caravan_tile() -> Vector2i:
	if simulation == null:
		return Vector2i(-1, -1)
	var hall: Vector2i = simulation._footprint_center(simulation.town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	return _clamp_tile(hall + Vector2i(6, 3))


func _plant_shelter_camp() -> void:
	if simulation == null:
		return
	var camp := _caravan_tile()
	simulation.add_map_marker("caravan_camp", camp, "Refugee camp", 0.0)
	var tent_offsets: Array[Vector2i] = [Vector2i(-1, 2), Vector2i(2, 1), Vector2i(1, -1)]
	for index in range(SHELTER_TENTS):
		var tile := _clamp_tile(camp + tent_offsets[index])
		simulation.add_map_marker("tent", tile, "Refugee tent", 0.0)
	_spawn_shelter_settlers(camp)


func _spawn_shelter_settlers(camp: Vector2i) -> void:
	if simulation == null:
		return
	var spots: Array[Vector2i] = [Vector2i(0, 1), Vector2i(1, 0)]
	for index in range(SHELTER_WORKERS):
		var tile := _clamp_tile(camp + spots[index])
		simulation.workers.append({
			"id": simulation.next_worker_id,
			"type": "settler",
			"role_key": "refugee",
			"building_id": 0,
			"slot": index,
			"position": tile,
			"path": [],
			"state": "Idle",
			"arrival_state": "Idle",
			"move_elapsed": 0.0,
			"activity_timer": 0.0,
			"capacity": 0,
			"carried_resource": "",
			"carried_amount": 0,
			"task": {},
			"shelter_position": tile,
			"hp": simulation.WORKER_MAX_HP,
			"max_hp": simulation.WORKER_MAX_HP,
			"hungry": false,
			"display_name": "Refugee"
		})
		simulation.next_worker_id += 1
		simulation.add_map_marker("refugee", tile, "Settler", 0.0)


func _find_channel_target() -> Dictionary:
	var best := {}
	var best_missing := -1
	if simulation != null:
		for building in simulation.buildings:
			if bool(building.get("construction", false)):
				continue
			if String(building.get("type", "")) != Defs.BUILDING_WALL:
				continue
			var hp := int(building.get("hp", 0))
			var max_hp := int(building.get("max_hp", Defs.building_hp(Defs.BUILDING_WALL)))
			var missing: int = max_hp - hp
			if missing > best_missing:
				best = {
					"kind": "wall",
					"tile": Vector2i(building.get("position", Vector2i.ZERO)),
					"building": building,
					"missing": missing
				}
				best_missing = missing
	if not best.is_empty():
		return best
	if simulation != null and simulation.rivalry != null:
		for structure in simulation.rivalry.get_structures(RivalryTuning.PLAYER_REALM):
			if String(structure.get("type", "")) != RivalryTuning.STRUCTURE_CLAIMANT_OUTPOST:
				continue
			if int(structure.get("hp", 0)) <= 0:
				continue
			return {
				"kind": "outpost",
				"tile": Vector2i(structure.get("position", primary_fissure)),
				"structure": structure
			}
	if simulation != null:
		for marker in simulation.map_markers:
			if String(marker.get("kind", "")) == "palisade":
				return {
					"kind": "palisade",
					"tile": Vector2i(marker.get("position", primary_fissure))
				}
	if primary_fissure.x >= 0:
		return {"kind": "fissure", "tile": primary_fissure}
	return {}


func _repair_one_segment() -> Vector2i:
	var found: Dictionary = _find_channel_target()
	if found.is_empty():
		return Vector2i(-1, -1)
	var building: Dictionary = found.get("building", {})
	if not building.is_empty():
		var max_hp := int(building.get("max_hp", Defs.building_hp(Defs.BUILDING_WALL)))
		building["hp"] = mini(max_hp, int(building.get("hp", 0)) + CHANNEL_REPAIR_HP)
		return Vector2i(found.get("tile", Vector2i.ZERO))
	var structure: Dictionary = found.get("structure", {})
	if not structure.is_empty():
		var max_hp := int(structure.get("max_hp", 220))
		structure["hp"] = mini(max_hp, int(structure.get("hp", 0)) + CHANNEL_REPAIR_HP)
		return Vector2i(found.get("tile", primary_fissure))
	return Vector2i(found.get("tile", primary_fissure))


func _note_first_build() -> void:
	if first_build_at >= 0.0 or simulation == null:
		return
	for building in simulation.buildings:
		if bool(building.get("construction", false)):
			continue
		if not bool(building.get("completed", false)):
			continue
		var kind := String(building.get("type", ""))
		if kind in [Defs.BUILDING_TOWN_HALL, Defs.BUILDING_ROAD, Defs.BUILDING_CONSTRUCTION_SITE, ""]:
			continue
		first_build_at = float(simulation.elapsed_seconds)
		return


func victory_summary() -> Dictionary:
	return {
		"caravan": midgame_choice,
		"wyrd": wyrd_choice,
		"seal": seal_choice,
		"channel_uses": channel_uses,
		"channel_reserve_used": 1 if last_channel_from_reserve or channel_uses >= 1 else 0,
		"elapsed_seconds": float(simulation.elapsed_seconds) if simulation != null else 0.0,
		"first_build_at": first_build_at,
		"population": int(simulation.population_current) if simulation != null else 0,
		"fortify_walls": fortify_walls,
		"shelter_tents": _marker_count("tent")
	}


func seal_look() -> Dictionary:
	var wall := seal_choice == PATH_WALL
	var charge := seal_choice == PATH_OVERCHARGE
	var flash := last_channel_at >= 0.0 and simulation != null and float(simulation.elapsed_seconds) - last_channel_at < 3.5
	return {
		"path": seal_choice,
		"ward_radius": 6.4 if wall else (2.1 if charge else 3.6),
		"ward_thickness": 1.15 if wall else (0.28 if charge else 0.55),
		"pulse_hz": 1.35 if charge else (0.48 if wall else 0.7),
		"palisades": 8 if wall else 0,
		"extra_wave": charge,
		"color": "amber" if wall else ("white" if charge else "cyan"),
		"light": 3.8 if charge else (2.1 if wall else 1.8),
		"channel_flash": flash,
		"channel_tile": last_channel_tile,
		"channel_uses": channel_uses
	}


func _begin_victory_ceremony() -> void:
	victory_ceremony = true
	if simulation == null:
		return
	if primary_fissure.x >= 0:
		simulation._reveal_radius(primary_fissure, 7)
		simulation.add_map_marker("victory_banner", primary_fissure, "SEALED", 0.0)
		simulation.add_map_marker("victory_banner", _clamp_tile(primary_fissure + Vector2i(3, 1)), "THE CEREMONY HELD", 0.0)
		simulation.add_map_marker("victory_banner", _clamp_tile(primary_fissure + Vector2i(-2, 3)), "THE FISSURE IS SEALED", 0.0)


func _reinforce_ceremony_wall() -> void:
	_plant_seal_palisades()
	if simulation.rivalry == null:
		return
	for structure in simulation.rivalry.get_structures(RivalryTuning.PLAYER_REALM):
		if String(structure.get("type", "")) != RivalryTuning.STRUCTURE_CLAIMANT_OUTPOST:
			continue
		if int(structure.get("hp", 0)) <= 0:
			continue
		structure["hp"] = int(structure.get("hp", 0)) + WALL_HP_BOOST
		structure["max_hp"] = int(structure.get("max_hp", RivalryTuning.structure_definition(RivalryTuning.STRUCTURE_CLAIMANT_OUTPOST).get("max_hp", 220))) + WALL_HP_BOOST
		return


func _plant_seal_palisades() -> void:
	if simulation == null or primary_fissure.x < 0:
		return
	var ring: Array[Vector2i] = [
		Vector2i(3, 0), Vector2i(-3, 1), Vector2i(2, 3), Vector2i(-2, -3),
		Vector2i(0, 3), Vector2i(3, -2), Vector2i(-4, 0), Vector2i(1, -3)
	]
	var planted := 0
	for offset in ring:
		if planted >= 6:
			break
		var tile := _clamp_tile(primary_fissure + offset)
		if not simulation.is_inside_map(tile):
			continue
		if not simulation.get_building_at_tile(tile).is_empty():
			continue
		var wall: Dictionary = simulation._create_building(Defs.BUILDING_WALL, tile)
		wall["construction"] = false
		wall["completed"] = true
		simulation.buildings.append(wall)
		simulation.add_map_marker("palisade", tile, "Seal wall", 0.0)
		planted += 1


func _overcharge_seal() -> void:
	if seal_overcharge_raid_spawned:
		return
	seal_overcharge_raid_spawned = true
	if simulation.has_method("spawn_ritual_raid"):
		simulation.spawn_ritual_raid(OVERCHARGE_RAID_SIZE)


func _ritual_ward_amount() -> int:
	if seal_choice == PATH_WALL:
		return WALL_WARD
	if seal_choice == PATH_OVERCHARGE:
		return OVERCHARGE_WARD
	return DEFAULT_WARD


func threat_name() -> String:
	var index := clampi(rival_threat_tier, 0, TIER_NAMES.size() - 1)
	return String(TIER_NAMES[index])


func rival_foreshadow_seconds() -> float:
	if rival_foreshadow_at < 0.0:
		_seed_rival_timing()
	return rival_foreshadow_at


func note_rival_revealed() -> void:
	_set_threat_tier(TIER_SIGHTED, "Rival Outpost sighted on the fissure.")
	_paint_rival_banners(3)
	_paint_threat_marker("TIER 2 SIGHTED")


func visible_escalation() -> Dictionary:
	return {
		"tier": rival_threat_tier,
		"tier_name": threat_name(),
		"banners": _marker_count("rival_banner"),
		"route": _marker_count("rival_route"),
		"threat": _marker_count("rival_threat"),
		"smoke": _marker_count("rival_smoke"),
		"push_telegraphed": push_telegraphed,
		"raid_telegraphed": raid_telegraphed,
		"foreshadowed": rival_foreshadowed
	}


func _maybe_foreshadow() -> void:
	if rival_foreshadowed or bool(simulation.demo_rival_revealed) or bool(simulation.game_finished):
		return
	if rival_foreshadow_at < 0.0:
		_seed_rival_timing()
	if float(simulation.elapsed_seconds) + 0.001 < rival_foreshadow_at:
		return
	rival_foreshadowed = true
	var tile := _foreshadow_tile()
	simulation._reveal_radius(tile, 4)
	simulation.add_map_marker("rival_smoke", tile, "Rival smoke", 0.0)
	_set_threat_tier(TIER_SMOKE, "Distant rival smoke.")
	_paint_rival_banners(1)
	_paint_threat_marker("TIER 1 SMOKE")
	var message := "SCOUT SIGHTING — distant rival smoke on the crater road. They will show themselves."
	simulation.last_message = message
	simulation._add_log(message)
	simulation.push_notice("info", "FORESHADOW", message, "warning")
	simulation._record_event("rival_foreshadow", message, {"tile": tile, "seconds": rival_foreshadow_at})


func _maybe_escalate_map() -> void:
	if simulation == null or bool(simulation.game_finished):
		return
	if bool(simulation.demo_rival_revealed) and rival_threat_tier < TIER_SIGHTED:
		note_rival_revealed()
	if not push_telegraphed and first_harvest_at >= 0.0 and bool(simulation.demo_rival_revealed):
		push_telegraphed = true
		_set_threat_tier(TIER_PUSH, "Rival army on the road.")
		_paint_rival_banners(5)
		_paint_army_route(_rival_origin_tile(), primary_fissure, "Push")
		_paint_threat_marker("TIER 3 PUSH")
		var push_line := "RIVAL ARMY MARKED — banners grow. A push is coming down this road."
		simulation.last_message = push_line
		simulation._add_log(push_line)
		simulation.push_notice("danger", "THREAT", push_line, "warning")
		simulation._record_event("rival_escalation", push_line, {"kind": "push", "tier": TIER_PUSH})
	if not raid_telegraphed and first_stabilized_at >= 0.0:
		raid_telegraphed = true
		_set_threat_tier(TIER_RAID, "Rival raid on the vent.")
		_paint_rival_banners(7)
		_paint_army_route(_rival_origin_tile(), _harvester_or_fissure(), "Raid")
		_paint_threat_marker("TIER 4 RAID")
		var raid_line := "RAID PING — the rival marks a route onto the Wyrd vent."
		simulation.last_message = raid_line
		simulation._add_log(raid_line)
		simulation.push_notice("danger", "THREAT", raid_line, "warning")
		simulation._record_event("rival_escalation", raid_line, {"kind": "raid", "tier": TIER_RAID})


func _set_threat_tier(tier: int, _reason: String) -> void:
	if tier > rival_threat_tier:
		rival_threat_tier = tier


func _paint_rival_banners(count: int) -> void:
	if simulation == null:
		return
	_clear_markers(["rival_banner"])
	banner_count = maxi(count, 1)
	var origin := _rival_origin_tile()
	if origin.x < 0:
		origin = primary_fissure if primary_fissure.x >= 0 else Vector2i(2, 2)
	var ring := [Vector2i(2, 0), Vector2i(-2, 1), Vector2i(1, 3), Vector2i(-3, -1), Vector2i(3, 2), Vector2i(0, -3), Vector2i(-1, 4)]
	for index in range(banner_count):
		var offset: Vector2i = ring[index % ring.size()]
		if index >= ring.size():
			offset *= 2
		var tile := _clamp_tile(origin + offset)
		simulation._reveal_radius(tile, 2)
		simulation.add_map_marker("rival_banner", tile, "Banner %d" % (index + 1), 0.0)


func _paint_army_route(from_tile: Vector2i, to_tile: Vector2i, title: String) -> void:
	if simulation == null or from_tile.x < 0 or to_tile.x < 0:
		return
	_clear_markers(["rival_route"])
	var steps := maxi(4, maxi(absi(to_tile.x - from_tile.x), absi(to_tile.y - from_tile.y)))
	var painted := 0
	for index in range(steps + 1):
		if index % maxi(1, int(ceil(float(steps) / 6.0))) != 0 and index != steps:
			continue
		var fraction := 0.0 if steps <= 0 else float(index) / float(steps)
		var tile := _clamp_tile(Vector2i(
			roundi(lerpf(float(from_tile.x), float(to_tile.x), fraction)),
			roundi(lerpf(float(from_tile.y), float(to_tile.y), fraction))
		))
		simulation._reveal_radius(tile, 2)
		simulation.add_map_marker("rival_route", tile, "%s %d" % [title, painted + 1], 0.0)
		painted += 1


func _paint_threat_marker(title: String) -> void:
	if simulation == null:
		return
	_clear_markers(["rival_threat"])
	var tile := _rival_origin_tile()
	if tile.x < 0:
		tile = primary_fissure
	if tile.x < 0:
		return
	simulation.add_map_marker("rival_threat", tile, title, 0.0)


func _foreshadow_tile() -> Vector2i:
	var hall: Vector2i = simulation._footprint_center(simulation.town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	var toward := Vector2(1.0, 0.0)
	if primary_fissure.x >= 0:
		toward = Vector2(primary_fissure - hall)
	elif not simulation.rival_seats.is_empty():
		toward = Vector2(Vector2i(simulation.rival_seats[0]) - hall)
	if toward.length_squared() < 0.01:
		toward = Vector2(1.0, 0.0)
	toward = toward.normalized()
	return _clamp_tile(hall + Vector2i(roundi(toward.x * 18.0), roundi(toward.y * 18.0)))


func _rival_origin_tile() -> Vector2i:
	if simulation != null and simulation.rivalry != null:
		for structure in simulation.rivalry.get_structures(RivalryTuning.AI_REALM):
			if int(structure.get("hp", 0)) <= 0:
				continue
			return Vector2i(structure.get("position", Vector2i.ZERO))
	if simulation != null:
		var presence: Variant = simulation.founding_site.get("rival_presence", Vector2i(-1, -1))
		if typeof(presence) == TYPE_VECTOR2I and Vector2i(presence).x >= 0:
			return Vector2i(presence)
	if primary_fissure.x >= 0:
		return rival_presence_tile()
	return Vector2i(-1, -1)


func _harvester_or_fissure() -> Vector2i:
	if simulation != null:
		for building in simulation.buildings:
			if bool(building.get("construction", false)):
				continue
			if String(building.get("type", "")) == Defs.BUILDING_WYRD_HARVESTER:
				return Vector2i(building.get("position", primary_fissure))
	return primary_fissure


func _clear_markers(kinds: Array) -> void:
	if simulation == null:
		return
	var kept: Array = []
	for marker in simulation.map_markers:
		if String(marker.get("kind", "")) in kinds:
			continue
		kept.append(marker)
	simulation.map_markers = kept


func _marker_count(kind: String) -> int:
	if simulation == null:
		return 0
	var total := 0
	for marker in simulation.map_markers:
		if String(marker.get("kind", "")) == kind:
			total += 1
	return total


func _harvest_interval() -> float:
	var base := SECURE_HARVEST_INTERVAL if wyrd_choice == PATH_SECURE else HARVEST_INTERVAL
	return base if route_secured() else HARVEST_INTERVAL * 2.0


func _refine_interval() -> float:
	return REFINE_PATH_INTERVAL if wyrd_choice == PATH_REFINE else REFINE_INTERVAL


func _refine_input() -> int:
	return REFINE_PATH_INPUT if wyrd_choice == PATH_REFINE else REFINE_INPUT


func _harvester_raid_size() -> int:
	return SECURE_RAID_SIZE if wyrd_choice == PATH_SECURE else HARVESTER_RAID_SIZE


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
