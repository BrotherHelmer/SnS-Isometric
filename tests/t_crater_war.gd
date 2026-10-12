extends SceneTree

## Fast gates for TEST #16: Seal the Fissure, 6-stab choice, reactive rival.
## Survival is not a win. Shard Binding is a later-act hook.

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
	_check_reactive_rival()
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
	_check(refine_sim.crater_war._refine_input() == CraterWar.REFINE_PATH_INPUT, "path A refines 2 raw")
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
