extends SceneTree

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const RaidIntents = preload("res://src/GodotClient/Scripts/one_shard_raid_intents.gd")

var failures: Array[String] = []


func _init() -> void:
	_run()
	for line in failures:
		print("FAIL %s" % line)
	print("T_RAID_WARNINGS %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _run() -> void:
	_check(RaidIntents.choose(1, 0) == RaidIntents.INTENT_PROBE, "Night 1 is a probing raid")
	var intents := {}
	for day in range(2, 11):
		intents[RaidIntents.choose(day, 7)] = true
	_check(intents.has(RaidIntents.INTENT_ECONOMY), "later nights include an economy raid")
	_check(intents.has(RaidIntents.INTENT_CENTER), "later nights include a centre raid")
	_check(intents.has(RaidIntents.INTENT_PROBE), "later nights still include a probe")
	var sim: Simulation = Simulation.new(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 777, false)
	sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 777, true)
	sim.phase_time = Simulation.DAY_LENGTH_SECONDS - RaidIntents.DUSK_WARNING_SECONDS - 0.05
	sim._update_time(0.2)
	_check(sim.dusk_warning_sent, "dusk warning fires at 90 seconds")
	_check(String(sim.last_message).contains("Dusk approaches"), "dusk copy matches the spec")
	sim.enemy_camps = [{
		"id": 1,
		"position": sim.town_hall_position + Vector2i(18, 0),
		"destroyed": false,
		"active": true
	}]
	sim.night_warning_sent = true
	sim.phase_time = Simulation.DAY_LENGTH_SECONDS - RaidIntents.HORN_WARNING_SECONDS - 0.05
	sim._update_time(0.2)
	_check(sim.horn_warning_sent, "horn warning fires at 45 seconds when a camp is nearby")
	var horn_logged := String(sim.last_message).to_lower().contains("horns")
	for entry in sim.log_entries:
		if String(entry).to_lower().contains("horns"):
			horn_logged = true
	_check(horn_logged, "horn copy mentions horns")
	var quiet: Simulation = Simulation.new(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 778, false)
	quiet.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 778, true)
	quiet.enemy_camps.clear()
	quiet.hidden_threat_level = 0
	quiet.dusk_forecast = {"threat": "QUIET"}
	quiet.phase_time = Simulation.DAY_LENGTH_SECONDS - RaidIntents.HORN_WARNING_SECONDS - 0.05
	quiet.dusk_warning_sent = true
	quiet._update_time(0.2)
	_check(quiet.horn_warning_sent, "horn flag is spent at 45s even when the woods are quiet")
	_check(not String(quiet.last_message).to_lower().contains("horns"), "quiet woods do not invent horns")
	_check(_economy_skips_town_hall(), "an economy raid prefers an exposed yard over the Town Hall")


func _economy_skips_town_hall() -> bool:
	var sim: Simulation = Simulation.new(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 779, false)
	sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 779, true)
	var hall := sim._find_town_hall()
	var quarry := sim._create_building(Defs.BUILDING_QUARRY, hall["position"] + Vector2i(8, 0))
	quarry["construction"] = false
	quarry["completed"] = true
	quarry["connected"] = true
	sim.buildings.append(quarry)
	sim.raid_plan = {
		"intent": RaidIntents.INTENT_ECONOMY,
		"bearing": "the east",
		"target_id": int(quarry.get("id", 0))
	}
	var enemy := {
		"id": 99,
		"enemy_type": Simulation.ENEMY_RAIDER,
		"position": quarry["position"] + Vector2i(2, 0),
		"raid_intent": RaidIntents.INTENT_ECONOMY,
		"target_id": 0,
		"target_kind": "building"
	}
	var picked: Dictionary = sim._find_enemy_target_unprofiled(enemy)
	var entity: Dictionary = picked.get("entity", {})
	return String(entity.get("type", "")) == Defs.BUILDING_QUARRY


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
