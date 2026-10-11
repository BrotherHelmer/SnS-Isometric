extends SceneTree

## Fast gates for TEST #15: plank loop, capture reward, varying nights,
## Wyrd economy, rival resolution, Binding ritual. Survival is not a win.

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
	_check(CraterWar.STABILIZED_TO_BIND == 12, "Binding costs 12 stabilized")
	_check(CraterWar.RITUAL_SECONDS == 120.0, "ritual lasts 120 seconds")
	_check_varying_nights()
	for seed_value in SEEDS:
		_check_seed_slice(seed_value)
	_check_hold_is_milestone()
	_check_binding_ritual()


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
	sim.elapsed_seconds = Simulation.DEMO_FRONTIER_SECONDS
	sim._update_demo_beats()
	_check(sim.demo_frontier_revealed, "seed %d frontier reveal" % seed_value)
	_check(sim.crater_war.geologist_surveyed, "seed %d geologist marks a fissure" % seed_value)
	_check(sim.crater_war.primary_fissure.x >= 0, "seed %d plants a primary fissure" % seed_value)
	sim.elapsed_seconds = Simulation.DEMO_RIVAL_SECONDS
	sim._update_demo_beats()
	_check(sim.demo_rival_revealed, "seed %d rival reveal" % seed_value)
	var rival_here := false
	if sim.rivalry != null:
		for structure in sim.rivalry.get_structures("rival"):
			if String(structure.get("type", "")) == Defs.BUILDING_OUTPOST and int(structure.get("hp", 0)) > 0:
				rival_here = true
				var d := sim._manhattan(Vector2i(structure.get("position", Vector2i.ZERO)), sim.crater_war.primary_fissure)
				_check(d <= 8, "seed %d rival sits on the same fissure (d=%d)" % [seed_value, d])
	_check(rival_here, "seed %d plants a rival outpost on the fissure" % seed_value)


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


func _check_binding_ritual() -> void:
	var sim: Simulation = Simulation.new()
	sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 260821, true)
	sim.elapsed_seconds = Simulation.DEMO_FRONTIER_SECONDS
	sim._update_demo_beats()
	sim.elapsed_seconds = Simulation.DEMO_RIVAL_SECONDS
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
	sim.central_inventory[Defs.RESOURCE_STABILIZED_WYRD] = 12
	var rival_structure := {}
	for structure in sim.rivalry.get_structures("rival"):
		if String(structure.get("type", "")) == Defs.BUILDING_OUTPOST:
			rival_structure = structure
			break
	_check(not rival_structure.is_empty(), "binding setup has a rival outpost")
	sim.crater_war.capture_outpost(rival_structure)
	_check(sim.crater_war.rival_resolution == "capture", "capture flips the outpost and pays a reward")
	_check(int(sim.central_inventory.get(Defs.RESOURCE_WOOD, 0)) >= 8, "capture grants wood")
	_check(String(sim.last_message).contains("CAPTURED"), "capture copy is visible")
	sim.elapsed_seconds = CraterWar.RITUAL_EARLIEST_SECONDS
	_check(sim.crater_war.can_begin(), "Binding is ready at 45:00 with 12 stabilized")
	var begin: Dictionary = sim.request_begin_binding()
	_check(bool(begin.get("success", false)), "request_begin_binding starts the crater ritual (%s)" % String(begin.get("message", "")))
	_check(sim.crater_war.ritual_active, "ritual is active")
	sim._simulate_seconds_for_test(CraterWar.RITUAL_SECONDS + 0.2)
	_check(sim.victory, "defended ritual wins Binding")
	_check(String(sim.defeat_reason).contains("BOUND"), "victory copy is Binding, not THE REALM HOLDS")


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
