extends SceneTree

## Fast gates for TEST #19: Channel Wyrd during the Seal, plus a
## caravan aftermath that stays on the map. Survival is not a win.

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const RaidIntents = preload("res://src/GodotClient/Scripts/one_shard_raid_intents.gd")
const CraterWar = preload("res://src/GodotClient/Scripts/one_shard_crater_war.gd")

const SEEDS := [260821, 261306, 261597, 260918]

var failures: Array[String] = []


func _init() -> void:
	_run()
	for line in failures:
		print("FAIL %s" % line)
	print("T_CRATER_WAR %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _run() -> void:
	_check(Defs.RESOURCE_TYPES.has(Defs.RESOURCE_STABILIZED_WYRD), "stabilized wyrd is a resource")
	_check(Defs.is_buildable(Defs.BUILDING_WYRD_HARVESTER), "harvester is buildable")
	_check(Defs.is_buildable(Defs.BUILDING_WYRD_REFINER), "refiner is buildable")
	_check(CraterWar.STABILIZED_TO_BIND == 12, "Seal costs 12 stabilized")
	_check(CraterWar.RITUAL_SECONDS == 120.0, "ceremony lasts 120 seconds")
	_check(CraterWar.HARVEST_INTERVAL >= 28.0, "harvest is paced for a 45-minute hour")
	_check(CraterWar.REFINE_INPUT >= 3, "base refine spends 3 raw per Stabilized")
	_check(CraterWar.CAPTURE_STABILIZED == 0, "capture does not dump Stabilized")
	_check_varying_nights()
	for seed_value in SEEDS:
		_check_seed_slice(seed_value)
	_check_hold_is_milestone()
	_check_seal_ceremony()
	_check_wyrd_choice()
	_check_seal_defence_choice()
	_check_midgame_caravan()
	_check_channel_wyrd()
	_check_reactive_rival()
	_check_visible_escalation()
	_check_foreshadow()
	_check_exposure_reserve()


func _check_varying_nights() -> void:
	var bearings: Dictionary = {}
	var targets: Dictionary = {}
	for day in range(2, 8):
		bearings[RaidIntents.choose_bearing(day, 260821)] = true
		targets[RaidIntents.choose_target_kind(day, 260821)] = true
	_check(bearings.size() >= 3, "later nights vary bearing (got %s)" % str(bearings.keys()))
	_check(targets.size() >= 3, "later nights vary target (got %s)" % str(targets.keys()))
	_check(RaidIntents.choose(1, 260821) == RaidIntents.INTENT_PROBE, "night 1 stays a probe")
	var warning := RaidIntents.raid_warning_message("the north", 60, "the Storehouse")
	_check(warning.contains("RAID IN") and warning.contains("Storehouse"), "warning names direction and target")


func _check_seed_slice(seed_value: int) -> void:
	var sim: Simulation = Simulation.new()
	sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, seed_value, true)
	_check(sim.crater_war != null, "seed %d attaches crater war" % seed_value)
	var reveal_at: float = sim.crater_war.rival_reveal_seconds()
	_check(reveal_at + 0.001 >= CraterWar.RIVAL_REVEAL_MIN, "seed %d reveal is after 14:00 (t=%.1f)" % [seed_value, reveal_at])
	_check(reveal_at < CraterWar.RIVAL_REVEAL_MIN + CraterWar.RIVAL_REVEAL_SPAN + 0.001, "seed %d reveal is before 20:00 (t=%.1f)" % [seed_value, reveal_at])
	sim.elapsed_seconds = Simulation.DEMO_FRONTIER_SECONDS
	sim._update_demo_beats()
	_check(sim.demo_frontier_revealed, "seed %d frontier reveal" % seed_value)
	_check(sim.crater_war.geologist_surveyed, "seed %d geologist marks a fissure" % seed_value)
	_check(sim.crater_war.primary_fissure.x >= 0, "seed %d plants a primary fissure" % seed_value)
	var early_deal: Dictionary = sim.request_passage_deal()
	_check(not bool(early_deal.get("success", false)), "seed %d passage deal waits for the rival" % seed_value)
	sim.elapsed_seconds = reveal_at
	sim._update_demo_beats()
	_check(sim.demo_rival_revealed, "seed %d rival reveal at seeded time" % seed_value)
	var rival_here := false
	if sim.rivalry != null:
		for structure in sim.rivalry.get_structures("rival"):
			if String(structure.get("type", "")) == Defs.BUILDING_OUTPOST and int(structure.get("hp", 0)) > 0:
				rival_here = true
				var d := sim._manhattan(Vector2i(structure.get("position", Vector2i.ZERO)), sim.crater_war.primary_fissure)
				_check(d <= 8, "seed %d rival sits on the same fissure (d=%d)" % [seed_value, d])
	_check(rival_here, "seed %d plants a rival outpost on the fissure" % seed_value)
	var path: String = sim.crater_war.bot_path_for_seed(seed_value)
	var expected := CraterWar.PATH_REFINE if SEEDS.find(seed_value) % 2 == 0 else CraterWar.PATH_SECURE
	_check(path == expected, "seed %d bot path is %s" % [seed_value, expected])
	var seal_path: String = sim.crater_war.bot_seal_path_for_seed(seed_value)
	var expected_seal := CraterWar.PATH_WALL if SEEDS.find(seed_value) % 2 == 0 else CraterWar.PATH_OVERCHARGE
	_check(seal_path == expected_seal, "seed %d seal defence path is %s" % [seed_value, expected_seal])
	var mid_path: String = sim.crater_war.bot_midgame_path_for_seed(seed_value)
	var expected_mid := CraterWar.PATH_SHELTER if SEEDS.find(seed_value) % 2 == 0 else CraterWar.PATH_FORTIFY
	_check(mid_path == expected_mid, "seed %d midgame path is %s" % [seed_value, expected_mid])
	var mid_at: float = sim.crater_war.midgame_seconds()
	_check(mid_at + 0.001 >= CraterWar.MIDGAME_MIN, "seed %d caravan is after 15:00 (t=%.1f)" % [seed_value, mid_at])
	_check(mid_at <= CraterWar.MIDGAME_LATEST + 0.001, "seed %d caravan is before 22:00 (t=%.1f)" % [seed_value, mid_at])
	var smoke_at: float = sim.crater_war.rival_foreshadow_seconds()
	_check(smoke_at + 0.001 >= CraterWar.FORESHADOW_MIN, "seed %d foreshadow is after 10:00 (t=%.1f)" % [seed_value, smoke_at])
	_check(smoke_at < CraterWar.FORESHADOW_MIN + CraterWar.FORESHADOW_SPAN + 0.001, "seed %d foreshadow is before 15:00 (t=%.1f)" % [seed_value, smoke_at])
	_check(smoke_at + 0.001 < reveal_at, "seed %d foreshadow is before the reveal (%.1f < %.1f)" % [seed_value, smoke_at, reveal_at])
	var hook: Dictionary = sim.crater_war.shard_binding_hook()
	_check(not bool(hook.get("available", true)), "seed %d leaves Shard Binding as a later act" % seed_value)


func _check_hold_is_milestone() -> void:
	var frontier: Simulation = Simulation.new()
	frontier.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 260821, true)
	frontier.elapsed_seconds = Simulation.DEMO_FRONTIER_SECONDS
	frontier._update_demo_beats()
	var tower := frontier._create_building(Defs.BUILDING_WATCHTOWER, frontier.town_hall_position + Vector2i(1, 1))
	tower["construction"] = false
	tower["completed"] = true
	frontier.buildings.append(tower)
	var hold_yard := frontier._create_building(Defs.BUILDING_BARRACKS, frontier.town_hall_position + Vector2i(6, 2))
	hold_yard["construction"] = false
	hold_yard["completed"] = true
	frontier.buildings.append(hold_yard)
	frontier.stats["days_survived"] = 4
	frontier.elapsed_seconds = Simulation.DEMO_VICTORY_SECONDS
	frontier._update_demo_beats()
	_check(not frontier.victory, "THE REALM HOLDS is not a victory")
	_check(frontier.crater_war.hold_milestone_shown, "THE REALM HOLDS is a visible milestone")
	_check(String(frontier.last_message).contains("HOLDS"), "milestone copy names THE REALM HOLDS")
	_check(String(frontier.last_message).contains("later act") or String(frontier.last_message).contains("Seal"), "milestone leaves Shard Binding as a later act")


func _ready_fissure(sim: Simulation) -> Dictionary:
	sim.elapsed_seconds = Simulation.DEMO_FRONTIER_SECONDS
	sim._update_demo_beats()
	sim.elapsed_seconds = sim.crater_war.rival_reveal_seconds()
	sim._update_demo_beats()
	var store := sim._create_building(Defs.BUILDING_STOREHOUSE, sim.town_hall_position + Vector2i(4, 10))
	store["construction"] = false
	store["completed"] = true
	sim.buildings.append(store)
	var harvest := sim._create_building(Defs.BUILDING_WYRD_HARVESTER, sim.crater_war.primary_fissure)
	harvest["construction"] = false
	harvest["completed"] = true
	sim.buildings.append(harvest)
	var refine := sim._create_building(Defs.BUILDING_WYRD_REFINER, sim.town_hall_position + Vector2i(9, 4))
	refine["construction"] = false
	refine["completed"] = true
	sim.buildings.append(refine)
	var rival_structure := {}
	for structure in sim.rivalry.get_structures("rival"):
		if String(structure.get("type", "")) == Defs.BUILDING_OUTPOST:
			rival_structure = structure
			break
	return rival_structure


func _check_seal_ceremony() -> void:
	var sim: Simulation = Simulation.new()
	sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 260821, true)
	var rival_structure: Dictionary = _ready_fissure(sim)
	_check(not rival_structure.is_empty(), "seal setup has a rival outpost")
	sim.central_inventory[Defs.RESOURCE_STABILIZED_WYRD] = 12
	var stab_before := int(sim.central_inventory.get(Defs.RESOURCE_STABILIZED_WYRD, 0))
	sim.crater_war.capture_outpost(rival_structure)
	_check(sim.crater_war.rival_resolution == "capture", "capture flips the outpost and pays a reward")
	_check(int(sim.central_inventory.get(Defs.RESOURCE_WOOD, 0)) >= 8, "capture grants wood")
	_check(int(sim.central_inventory.get(Defs.RESOURCE_STABILIZED_WYRD, 0)) == stab_before, "capture does not grant Stabilized")
	_check(sim.crater_war.can_begin(), "Seal is ready once 12 Stabilized is in the store")
	sim.central_inventory[Defs.RESOURCE_STABILIZED_WYRD] = 11
	_check(not sim.crater_war.can_begin(), "Seal stays locked below 12 Stabilized")
	sim.central_inventory[Defs.RESOURCE_STABILIZED_WYRD] = 12
	var begin: Dictionary = sim.request_begin_seal()
	_check(bool(begin.get("success", false)), "request_begin_seal starts the ceremony (%s)" % String(begin.get("message", "")))
	_check(String(begin.get("message", "")).contains("SEAL"), "ceremony copy names the Seal")
	_check(sim.crater_war.ritual_active, "ceremony is active")
	_check(sim.crater_war.stabilized_stock() == CraterWar.CHANNEL_COST, "Seal refunds 2 Stabilized for Channel Wyrd")
	_check(sim.crater_war.channel_ready(), "Channel Wyrd is ready as the Seal starts")
	sim._simulate_seconds_for_test(CraterWar.RITUAL_SECONDS + 0.2)
	_check(sim.victory, "defended ceremony wins the Seal")
	_check(String(sim.defeat_reason).contains("SEALED"), "victory copy is Seal, not THE REALM HOLDS")
	_check(not String(sim.defeat_reason).contains("BOUND"), "victory no longer says BOUND")


func _check_wyrd_choice() -> void:
	var refine_sim: Simulation = Simulation.new()
	refine_sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 260821, true)
	_ready_fissure(refine_sim)
	refine_sim.central_inventory[Defs.RESOURCE_STABILIZED_WYRD] = 6
	refine_sim.crater_war._maybe_offer_choice()
	_check(refine_sim.crater_war.choice_ready(), "choice opens at 6 Stabilized")
	var early: Dictionary = refine_sim.request_wyrd_choice("refine")
	_check(bool(early.get("success", false)), "path A faster refining is accepted")
	_check(refine_sim.crater_war.wyrd_choice == CraterWar.PATH_REFINE, "path A is stored")
	_check(refine_sim.crater_war._refine_input() == CraterWar.REFINE_INPUT, "path A still spends 3 raw so harvest paces the hour")
	_check(refine_sim.crater_war._refine_interval() == CraterWar.REFINE_PATH_INTERVAL, "path A refines faster")
	_check(int(refine_sim.central_inventory.get(Defs.RESOURCE_STABILIZED_WYRD, 0)) == 6, "path A spends no Stabilized")

	var secure_sim: Simulation = Simulation.new()
	secure_sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 261306, true)
	_ready_fissure(secure_sim)
	secure_sim.central_inventory[Defs.RESOURCE_STABILIZED_WYRD] = 6
	var invest: Dictionary = secure_sim.request_wyrd_choice("secure")
	_check(bool(invest.get("success", false)), "path B secure harvest is accepted")
	_check(int(secure_sim.central_inventory.get(Defs.RESOURCE_STABILIZED_WYRD, 0)) == 3, "path B invests 3 Stabilized")
	_check(secure_sim.crater_war.route_secured(), "path B secures the harvest corridor")
	_check(secure_sim.crater_war._harvester_raid_size() == 0, "path B lowers harvester raid pressure")
	_check(secure_sim.crater_war.bot_path_for_seed(260821) == CraterWar.PATH_REFINE, "260821 alternates to A")
	_check(secure_sim.crater_war.bot_path_for_seed(261306) == CraterWar.PATH_SECURE, "261306 alternates to B")
	_check(secure_sim.crater_war.bot_seal_path_for_seed(260821) == CraterWar.PATH_WALL, "260821 seal path is wall")
	_check(secure_sim.crater_war.bot_seal_path_for_seed(261306) == CraterWar.PATH_OVERCHARGE, "261306 seal path is overcharge")


func _check_seal_defence_choice() -> void:
	var wall_sim: Simulation = Simulation.new()
	wall_sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 260821, true)
	var wall_rival: Dictionary = _ready_fissure(wall_sim)
	wall_sim.central_inventory[Defs.RESOURCE_STABILIZED_WYRD] = 12
	wall_sim.crater_war.capture_outpost(wall_rival)
	var wall_begin: Dictionary = wall_sim.request_begin_seal()
	_check(bool(wall_begin.get("success", false)), "wall setup starts the Seal")
	_check(not wall_sim.crater_war.seal_choice_ready(), "seal choice stays closed before 60 s")
	wall_sim.crater_war.ritual_progress = CraterWar.SEAL_CHOICE_AT + 0.5
	wall_sim.crater_war._maybe_offer_seal_choice()
	_check(wall_sim.crater_war.seal_choice_ready(), "seal choice opens at 60 s")
	var wall_hp_before := 0
	for structure in wall_sim.rivalry.get_structures("player"):
		if String(structure.get("type", "")) == Defs.BUILDING_OUTPOST:
			wall_hp_before = int(structure.get("hp", 0))
			break
	var wall_pick: Dictionary = wall_sim.request_seal_choice("wall")
	_check(bool(wall_pick.get("success", false)), "reinforce wall is accepted")
	_check(wall_sim.crater_war.seal_choice == CraterWar.PATH_WALL, "wall path is stored")
	_check(wall_sim.crater_war.ritual_needed == CraterWar.RITUAL_SECONDS + CraterWar.WALL_RITUAL_EXTRA, "wall makes the ceremony last 20 s longer")
	_check(wall_sim.crater_war._ritual_ward_amount() == CraterWar.WALL_WARD, "wall raises the ceremony ward")
	var wall_hp_after := wall_hp_before
	for structure in wall_sim.rivalry.get_structures("player"):
		if String(structure.get("type", "")) == Defs.BUILDING_OUTPOST:
			wall_hp_after = int(structure.get("hp", 0))
			break
	_check(wall_hp_after >= wall_hp_before + CraterWar.WALL_HP_BOOST, "wall boosts the ceremony Outpost HP")
	var wall_look: Dictionary = wall_sim.crater_war.seal_look()
	_check(float(wall_look.get("ward_radius", 0.0)) >= 5.0, "wall look has a thick ward ring")
	_check(int(wall_look.get("palisades", 0)) >= 6, "wall look plants palisade segments")
	_check(not bool(wall_look.get("extra_wave", true)), "wall look has no extra wave")
	_check(String(wall_look.get("color", "")) == "amber", "wall look is amber")
	var wall_markers := 0
	for marker in wall_sim.map_markers:
		if String(marker.get("kind", "")) == "palisade":
			wall_markers += 1
	_check(wall_markers >= 3, "wall choice plants visible palisade markers")

	var charge_sim: Simulation = Simulation.new()
	charge_sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 261306, true)
	var charge_rival: Dictionary = _ready_fissure(charge_sim)
	charge_sim.central_inventory[Defs.RESOURCE_STABILIZED_WYRD] = 12
	charge_sim.crater_war.capture_outpost(charge_rival)
	charge_sim.request_begin_seal()
	charge_sim.crater_war.ritual_progress = CraterWar.SEAL_CHOICE_AT + 0.5
	var enemies_before := charge_sim.enemies.size()
	var charge_pick: Dictionary = charge_sim.request_seal_choice("overcharge")
	_check(bool(charge_pick.get("success", false)), "overcharge is accepted")
	_check(charge_sim.crater_war.seal_choice == CraterWar.PATH_OVERCHARGE, "overcharge path is stored")
	_check(charge_sim.crater_war.ritual_needed <= CraterWar.RITUAL_SECONDS - CraterWar.OVERCHARGE_RITUAL_CUT + 0.001, "overcharge shortens the remaining rite")
	_check(charge_sim.crater_war._ritual_ward_amount() == CraterWar.OVERCHARGE_WARD, "overcharge thins the ceremony ward")
	_check(charge_sim.enemies.size() > enemies_before, "overcharge calls another ritual wave")
	var charge_look: Dictionary = charge_sim.crater_war.seal_look()
	_check(float(charge_look.get("ward_radius", 9.0)) <= 2.5, "overcharge look has a thinner ward ring")
	_check(int(charge_look.get("palisades", 9)) == 0, "overcharge look plants no palisade segments")
	_check(bool(charge_look.get("extra_wave", false)), "overcharge look shows an extra wave")
	_check(float(charge_look.get("pulse_hz", 0.0)) > float(wall_look.get("pulse_hz", 0.0)), "overcharge pulses faster than the wall")
	_check(not charge_sim.request_seal_choice("wall").get("success", true), "seal choice cannot be taken twice")


func _check_midgame_caravan() -> void:
	var shelter_sim: Simulation = Simulation.new()
	shelter_sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 260821, true)
	_ready_fissure(shelter_sim)
	shelter_sim.elapsed_seconds = shelter_sim.crater_war.midgame_seconds()
	shelter_sim.crater_war._maybe_offer_midgame()
	_check(shelter_sim.crater_war.midgame_choice_ready(), "caravan opens in the 15–22 window")
	_check(shelter_sim.crater_war.midgame_offered_at + 0.001 >= CraterWar.MIDGAME_MIN, "caravan is not before 15:00")
	_check(shelter_sim.crater_war.midgame_offered_at <= CraterWar.MIDGAME_LATEST + 0.001, "caravan is not after 22:00")
	_check(not shelter_sim.crater_war.second_push_done, "caravan is offered before the first push")
	var pop_before := int(shelter_sim.population_current)
	var house_before := int(shelter_sim.housing_capacity)
	var shelter_pick: Dictionary = shelter_sim.request_midgame_choice("shelter")
	_check(bool(shelter_pick.get("success", false)), "shelter is accepted")
	_check(shelter_sim.crater_war.midgame_choice == CraterWar.PATH_SHELTER, "shelter path is stored")
	_check(int(shelter_sim.population_current) >= pop_before + CraterWar.SHELTER_WORKERS, "shelter adds two workers")
	_check(int(shelter_sim.housing_capacity) >= house_before + CraterWar.SHELTER_WORKERS, "shelter adds housing")
	_check(shelter_sim.crater_war.shelter_exposure >= CraterWar.SHELTER_EXPOSURE - 0.001, "shelter raises exposure")
	var tents := 0
	var refugees := 0
	for marker in shelter_sim.map_markers:
		if String(marker.get("kind", "")) in ["tent", "caravan_camp"]:
			tents += 1
		if String(marker.get("kind", "")) == "refugee":
			refugees += 1
	_check(tents >= 2, "shelter plants persistent tents near town")
	var refugee_workers := 0
	for worker in shelter_sim.workers:
		if String(worker.get("role_key", "")) == "refugee":
			refugee_workers += 1
	_check(refugee_workers >= CraterWar.SHELTER_WORKERS, "shelter adds visible settlers")
	_check(refugees >= 1, "shelter marks extra settlers on the map")
	shelter_sim.crater_war._update_exposure(0.0)
	_check(shelter_sim.crater_war.exposure + 0.001 >= CraterWar.SHELTER_EXPOSURE, "shelter exposure is visible on the meter")
	_check(not shelter_sim.request_midgame_choice("fortify").get("success", true), "caravan cannot be answered twice")

	var fort_sim: Simulation = Simulation.new()
	fort_sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 261306, true)
	_ready_fissure(fort_sim)
	fort_sim.central_inventory[Defs.RESOURCE_WOOD] = 12
	fort_sim.elapsed_seconds = fort_sim.crater_war.midgame_seconds()
	fort_sim.crater_war._maybe_offer_midgame()
	var reaction_before := float(fort_sim.crater_war.push_reaction)
	var wood_before := int(fort_sim.central_inventory.get(Defs.RESOURCE_WOOD, 0))
	var fort_pick: Dictionary = fort_sim.request_midgame_choice("fortify")
	_check(bool(fort_pick.get("success", false)), "fortify is accepted")
	_check(fort_sim.crater_war.midgame_choice == CraterWar.PATH_FORTIFY, "fortify path is stored")
	_check(int(fort_sim.central_inventory.get(Defs.RESOURCE_WOOD, 0)) <= wood_before - 1, "fortify spends wood")
	_check(fort_sim.crater_war.fortify_walls >= CraterWar.FORTIFY_WALLS, "fortify plants palisade segments")
	_check(fort_sim.crater_war.push_reaction >= reaction_before + CraterWar.FORTIFY_PUSH_DELAY - 0.001, "fortify delays the first push")
	_check(fort_sim.crater_war.bot_midgame_path_for_seed(260821) == CraterWar.PATH_SHELTER, "260821 caravan path is shelter")
	_check(fort_sim.crater_war.bot_midgame_path_for_seed(261306) == CraterWar.PATH_FORTIFY, "261306 caravan path is fortify")
	var shown := 0
	for marker in fort_sim.map_markers:
		if String(marker.get("kind", "")) in ["caravan", "palisade"]:
			shown += 1
	_check(shown >= 1, "caravan / palisade is marked on the map")
	var palisades := 0
	for marker in fort_sim.map_markers:
		if String(marker.get("kind", "")) == "palisade":
			palisades += 1
	_check(palisades >= CraterWar.FORTIFY_WALLS, "fortify keeps palisade segments on the map")


func _check_channel_wyrd() -> void:
	var sim: Simulation = Simulation.new()
	sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 260821, true)
	var rival_structure: Dictionary = _ready_fissure(sim)
	sim.central_inventory[Defs.RESOURCE_STABILIZED_WYRD] = 12
	sim.crater_war.capture_outpost(rival_structure)
	var early: Dictionary = sim.request_channel_wyrd()
	_check(not bool(early.get("success", false)), "Channel Wyrd stays closed before the Seal")
	var begin: Dictionary = sim.request_begin_seal()
	_check(bool(begin.get("success", false)), "channel setup starts the Seal")
	_check(sim.crater_war.channel_ready(), "Channel Wyrd is offered during the Seal")
	var wall: Dictionary = sim._create_building(Defs.BUILDING_WALL, sim.town_hall_position + Vector2i(2, 2))
	wall["construction"] = false
	wall["completed"] = true
	wall["hp"] = 40
	wall["max_hp"] = Defs.building_hp(Defs.BUILDING_WALL)
	sim.buildings.append(wall)
	var hp_before := int(wall.get("hp", 0))
	var pick: Dictionary = sim.request_channel_wyrd()
	_check(bool(pick.get("success", false)), "Channel Wyrd is accepted (%s)" % String(pick.get("message", "")))
	_check(sim.crater_war.channel_uses == 1, "Channel Wyrd records a use")
	_check(int(wall.get("hp", 0)) >= hp_before + 1, "Channel Wyrd repairs a wall segment")
	_check(sim.crater_war.last_channel_tile.x >= 0, "Channel Wyrd records a repair tile")
	_check(not sim.crater_war.channel_ready(), "Channel Wyrd cools for 20 s")
	var again: Dictionary = sim.request_channel_wyrd()
	_check(not bool(again.get("success", false)), "Channel Wyrd rejects during cooldown")
	sim.elapsed_seconds += CraterWar.CHANNEL_COOLDOWN + 0.2
	sim.central_inventory[Defs.RESOURCE_STABILIZED_WYRD] = CraterWar.CHANNEL_COST
	_check(sim.crater_war.channel_ready(), "Channel Wyrd returns after 20 s")
	var summary: Dictionary = sim.crater_war.victory_summary()
	_check(int(summary.get("channel_uses", 0)) == 1, "victory summary lists Channel uses")
	var house: Dictionary = sim._create_building(Defs.BUILDING_HOUSE, sim.town_hall_position + Vector2i(5, 4))
	house["construction"] = false
	house["completed"] = true
	sim.buildings.append(house)
	sim.crater_war._note_first_build()
	_check(sim.crater_war.first_build_at >= 0.0, "first meaningful build is tracked")


func _check_visible_escalation() -> void:
	var sim: Simulation = Simulation.new()
	sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 260821, true)
	var rival_structure: Dictionary = _ready_fissure(sim)
	sim.crater_war.note_rival_revealed()
	var sighted: Dictionary = sim.crater_war.visible_escalation()
	_check(int(sighted.get("tier", 0)) >= CraterWar.TIER_SIGHTED, "reveal raises the threat tier")
	_check(int(sighted.get("banners", 0)) >= 3, "reveal plants growing rival banners")
	_check(int(sighted.get("threat", 0)) >= 1, "reveal plants a threat marker")
	sim.crater_war.capture_outpost(rival_structure)
	sim.crater_war.first_harvest_at = float(sim.elapsed_seconds)
	sim.crater_war._maybe_escalate_map()
	var before_push: Dictionary = sim.crater_war.visible_escalation()
	_check(bool(before_push.get("push_telegraphed", false)), "push is telegraphed before it lands")
	_check(int(before_push.get("tier", 0)) >= CraterWar.TIER_PUSH, "push telegraph is TIER PUSH")
	_check(int(before_push.get("route", 0)) >= 3, "push paints a marked army route")
	_check(int(before_push.get("banners", 0)) >= 5, "push grows the banner ring")
	_check(not sim.crater_war.second_push_done, "the army route is visible before the Outpost lands")
	sim.elapsed_seconds = sim.crater_war.first_harvest_at + sim.crater_war.push_reaction + 1.0
	sim.crater_war._maybe_rival_contest()
	_check(sim.crater_war.second_push_done, "the harvest push still lands after the telegraph")
	sim.crater_war.first_stabilized_at = float(sim.elapsed_seconds)
	sim.crater_war._maybe_escalate_map()
	var before_raid: Dictionary = sim.crater_war.visible_escalation()
	_check(bool(before_raid.get("raid_telegraphed", false)), "raid is telegraphed before it lands")
	_check(int(before_raid.get("tier", 0)) >= CraterWar.TIER_RAID, "raid telegraph is TIER RAID")
	_check(int(before_raid.get("route", 0)) >= 3, "raid paints a marked army route")
	_check(int(before_raid.get("banners", 0)) >= 7, "raid grows banners again")


func _check_foreshadow() -> void:
	var sim: Simulation = Simulation.new()
	sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 260821, true)
	var smoke_at: float = sim.crater_war.rival_foreshadow_seconds()
	sim.elapsed_seconds = smoke_at
	sim.crater_war._maybe_foreshadow()
	_check(sim.crater_war.rival_foreshadowed, "foreshadow fires at the seeded 10–15 beat")
	_check(not sim.demo_rival_revealed, "foreshadow is not the reveal")
	var seen: Dictionary = sim.crater_war.visible_escalation()
	_check(int(seen.get("smoke", 0)) >= 1, "foreshadow plants distant rival smoke on the map")
	_check(int(seen.get("tier", 0)) >= CraterWar.TIER_SMOKE, "foreshadow is TIER SMOKE")
	_check(String(sim.last_message).contains("smoke") or String(sim.last_message).contains("SCOUT"), "foreshadow copy is a scout or smoke beat")


func _check_reactive_rival() -> void:
	var sim: Simulation = Simulation.new()
	sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 260821, true)
	var rival_structure: Dictionary = _ready_fissure(sim)
	sim.crater_war.capture_outpost(rival_structure)
	_check(not sim.crater_war.second_push_done, "rival does not push on a +180 clock")
	sim.crater_war.first_harvest_at = float(sim.elapsed_seconds)
	sim.elapsed_seconds = sim.crater_war.first_harvest_at + sim.crater_war.push_reaction + 1.0
	sim.crater_war._maybe_rival_contest()
	_check(sim.crater_war.second_push_done, "rival pushes after the first harvest")
	_check(sim.crater_war._rival_outpost_alive(), "the harvest push is a living rival Outpost")
	_check(not sim.crater_war.harvester_raid_done, "rival does not raid on a +360 clock")
	sim.crater_war.first_stabilized_at = float(sim.elapsed_seconds)
	sim.elapsed_seconds = sim.crater_war.first_stabilized_at + sim.crater_war.raid_reaction + 1.0
	sim.crater_war._maybe_rival_contest()
	_check(sim.crater_war.harvester_raid_done, "rival raids after the first Stabilized")
	var raids_before := 1 if sim.crater_war.harvester_raid_done else 0
	sim.crater_war.last_exposure_band = "CRITICAL"
	sim.crater_war._maybe_rival_contest()
	_check(sim.crater_war.harvester_raid_done == bool(raids_before), "exposure does not stack a second harvester raid")


func _check_exposure_reserve() -> void:
	var sim: Simulation = Simulation.new()
	sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 260821, true)
	sim.elapsed_seconds = Simulation.DEMO_FRONTIER_SECONDS
	sim._update_demo_beats()
	var harvest := sim._create_building(Defs.BUILDING_WYRD_HARVESTER, sim.crater_war.primary_fissure)
	harvest["construction"] = false
	harvest["completed"] = true
	sim.buildings.append(harvest)
	sim.central_inventory[Defs.RESOURCE_WYRD] = 12
	sim.crater_war._update_exposure(1.0)
	_check(sim.crater_war.exposure > 0.3, "unlumened surplus raw raises exposure")
	var before := int(sim.central_inventory.get(Defs.RESOURCE_WYRD, 0))
	sim.crater_war.exposure_burn_timer = 50.0
	sim.crater_war._update_exposure(1.0)
	_check(int(sim.central_inventory.get(Defs.RESOURCE_WYRD, 0)) < before, "exposure burns raw above the reserve")
	_check(int(sim.central_inventory.get(Defs.RESOURCE_WYRD, 0)) >= CraterWar.RAW_RESERVE + CraterWar.REFINE_INPUT, "exposure keeps the refine reserve")


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
