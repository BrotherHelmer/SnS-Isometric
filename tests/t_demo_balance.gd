extends SceneTree

## Fast gates for the demo-balance round: nearby quarry stone, tower unlock,
## construction-before-roads, raid warning + size cap.

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const RaidIntents = preload("res://src/GodotClient/Scripts/one_shard_raid_intents.gd")
const RaidTuning = preload("res://src/GodotClient/Scripts/one_shard_raid_tuning.gd")
const Wyrdfall = preload("res://src/GodotClient/Scripts/one_shard_wyrdfall.gd")

const SEEDS := [260821, 261306, 261597, 260918]

var failures: Array[String] = []


func _init() -> void:
	_run()
	for line in failures:
		print("FAIL %s" % line)
	print("T_DEMO_BALANCE %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _run() -> void:
	for seed_value in SEEDS:
		var sim: Simulation = Simulation.new()
		sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, seed_value, true)
		var audit: Dictionary = sim.founding_audit()
		_check(bool(audit.get("quarry_stone_band", false)), "seed %d quarry stone is 5–8 tiles (dist=%.1f tile=%s)" % [
			seed_value, float(audit.get("quarry_stone_dist", -1.0)), str(audit.get("quarry_stone", Vector2i.ZERO))
		])
		_check(not sim.is_military_unlocked(), "seed %d watchtower is locked at founding" % seed_value)
		sim.elapsed_seconds = 119.0
		_check(not sim.is_military_unlocked(), "seed %d watchtower still locked at 119s" % seed_value)
		sim.elapsed_seconds = 120.0
		_check(sim.is_military_unlocked(), "seed %d watchtower unlocks at 120s" % seed_value)
		_check(sim._capped_raid_size(RaidTuning.NIGHT2_SIZE) == RaidTuning.NIGHT1_SIZE, "seed %d caps 5 raiders to 2 before barracks" % seed_value)
		var barracks := sim._create_building(Defs.BUILDING_BARRACKS, sim.town_hall_position + Vector2i(6, 2))
		barracks["construction"] = false
		barracks["completed"] = true
		sim.buildings.append(barracks)
		_check(sim._capped_raid_size(RaidTuning.NIGHT2_SIZE) == RaidTuning.NIGHT2_SIZE, "seed %d allows Night 2 size after barracks" % seed_value)
		sim.buildings.erase(barracks)
	var warning: Simulation = Simulation.new()
	warning.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 260821, true)
	warning.dusk_warning_sent = true
	warning.night_warning_sent = true
	warning.phase_time = Simulation.DAY_LENGTH_SECONDS - RaidIntents.RAID_WARNING_SECONDS - 0.05
	warning._update_time(0.2)
	_check(warning.horn_warning_sent, "raid warning flag at 60s")
	var copy_ok := String(warning.last_message).contains("RAID IN")
	for entry in warning.log_entries:
		if String(entry).contains("RAID IN"):
			copy_ok = true
	_check(copy_ok, "raid warning copy (last='%s')" % String(warning.last_message))
	var pinged := false
	for marker in warning.get_map_markers():
		if String(marker.get("kind", "")) == "raid":
			pinged = true
	_check(pinged, "raid warning map ping")
	var plan := Wyrdfall.wave_plan(8.0, 2, false, false)
	_check(int(plan.get("size", 0)) == RaidTuning.NIGHT2_SIZE, "wave_plan still reports Night 2 as 5")
	_check(RaidIntents.RAID_WARNING_SECONDS == 60.0, "raid warning is 60 seconds")
	_check_construction_beats_roads()
	var frontier: Simulation = Simulation.new()
	frontier.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 260821, true)
	frontier.elapsed_seconds = Simulation.DEMO_FRONTIER_SECONDS
	frontier._update_demo_beats()
	_check(frontier.demo_frontier_revealed, "frontier reveal plants the marker")
	_check(frontier._has_frontier_outpost(), "frontier reveal plants a hold-victory outpost ≥16 tiles out")
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
	_check(not frontier.victory, "THE REALM HOLDS is no longer a victory")
	_check(frontier.crater_war != null and frontier.crater_war.hold_milestone_shown, "THE REALM HOLDS is a milestone toast")
	var copy_sim: Simulation = Simulation.new()
	copy_sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 260821, true)
	var store_copy := String(copy_sim._storehouse_blocker_copy())
	_check(store_copy.contains("Storehouse") or store_copy.contains("Place a Storehouse"), "storage notice names the Storehouse (%s)" % store_copy)
	_check(String(copy_sim._demo_defeat_hint()).contains("Watchtower"), "defeat hint names the unfinished Watchtower")


func _check_construction_beats_roads() -> void:
	var sim: Simulation = Simulation.new()
	sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 260821, true)
	var hall: Vector2i = sim.town_hall_position
	var barracks := sim._create_building(Defs.BUILDING_BARRACKS, hall + Vector2i(6, 2))
	barracks["construction"] = true
	barracks["planned_type"] = Defs.BUILDING_BARRACKS
	barracks["connected"] = true
	barracks["materials_needed"] = {Defs.RESOURCE_PLANKS: 10, Defs.RESOURCE_STONE: 8}
	barracks["materials_delivered"] = Defs.empty_inventory()
	barracks["materials_in_transit"] = Defs.empty_inventory()
	sim.buildings.append(barracks)
	sim.central_inventory[Defs.RESOURCE_PLANKS] = 14
	sim.central_inventory[Defs.RESOURCE_STONE] = 10
	_check(sim._construction_waiting_for_materials(), "connected barracks with stock waits for deliveries")
	sim._ensure_carriers()
	var assigned := false
	for worker in sim.workers:
		if String(worker.get("type", "")) != "carrier":
			continue
		worker["state"] = "Idle"
		worker["task"] = {}
		worker["carried_amount"] = 0
		if sim._assign_carrier_task(worker):
			assigned = assigned or String(worker.get("task", {}).get("purpose", "")) == "construction"
	_check(assigned, "idle carrier takes construction before a road job")


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
