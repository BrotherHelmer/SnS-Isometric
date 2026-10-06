extends SceneTree

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Dawn = preload("res://src/GodotClient/Scripts/one_shard_dawn.gd")

var failures: Array[String] = []


func _init() -> void:
	_run()
	for line in failures:
		print("FAIL %s" % line)
	print("T_DAWN_AFTERMATH %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _run() -> void:
	var sim: Simulation = Simulation.new(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 1212, false)
	sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 1212, true)
	sim.day_count = 3
	sim.night_enemies_spawned = 4
	sim.night_enemies_defeated_at_dusk = 0
	sim.stats["enemies_defeated"] = 4
	sim.night_casualties = 1
	sim.night_buildings_damaged = 1
	sim.raid_resources_lost = {Defs.RESOURCE_WOOD: 6}
	var hall := sim._find_town_hall()
	hall["hp"] = int(hall.get("max_hp", 200)) - 20
	sim.raid_buildings_damaged_ids[int(hall.get("id", 0))] = "Town Hall"
	var guard := {
		"id": 88,
		"type": "guard",
		"hp": 12,
		"max_hp": Simulation.WORKER_MAX_HP,
		"position": hall["position"]
	}
	sim.workers.append(guard)
	var bread_before := int(sim.central_inventory.get(Defs.RESOURCE_BREAD, 0))
	sim._compose_dawn_summary()
	var summary: Dictionary = sim.dawn_summary
	_check(not summary.is_empty(), "a fought night produces a dawn summary")
	_check(String(summary.get("title", "")).contains("Night 2 survived"), "title names the night that just ended")
	_check(int(summary.get("enemies_defeated", 0)) == 4, "raiders killed are counted")
	_check(int(summary.get("settlers_lost", 0)) == 1, "settlers lost are counted")
	_check(int(summary.get("soldiers_wounded", 0)) == 1, "wounded soldiers are counted")
	_check(int(summary.get("buildings_damaged", 0)) == 1, "damaged buildings are counted")
	_check(int(Dictionary(summary.get("resources_lost", {})).get(Defs.RESOURCE_WOOD, 0)) == 6, "wood lost is listed")
	_check(int(Dictionary(summary.get("supplies_recovered", {})).get(Defs.RESOURCE_BREAD, 0)) == 2, "defeated raiders drop a little bread")
	_check(int(sim.central_inventory.get(Defs.RESOURCE_BREAD, 0)) == bread_before + 2, "recovered supplies enter the store")
	_check(String(summary.get("body", "")).contains("6 Wood lost"), "body lists wood lost")
	_check(float(hall.get("dawn_highlight_until", 0.0)) > sim.elapsed_seconds, "damaged buildings are highlighted")
	_check(Dawn.DISPLAY_SECONDS == 5.0, "the aftermath holds for five seconds")
	var consumed := sim.consume_dawn_summary()
	_check(not consumed.is_empty() and sim.dawn_summary.is_empty(), "HUD consume clears the dawn card")
	sim.night_enemies_spawned = 0
	sim.stats["enemies_defeated"] = 0
	sim.night_enemies_defeated_at_dusk = 0
	sim.night_casualties = 0
	sim.night_buildings_damaged = 0
	sim.raid_buildings_damaged_ids.clear()
	sim.raid_resources_lost.clear()
	sim.workers.clear()
	sim._compose_dawn_summary()
	_check(sim.dawn_summary.is_empty(), "a quiet night does not open an aftermath card")


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
