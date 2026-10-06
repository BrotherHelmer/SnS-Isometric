extends SceneTree

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Frontier = preload("res://src/GodotClient/Scripts/one_shard_frontier.gd")
const RaidIntents = preload("res://src/GodotClient/Scripts/one_shard_raid_intents.gd")

var failures: Array[String] = []


func _init() -> void:
	_run()
	for line in failures:
		print("FAIL %s" % line)
	print("T_FRONTIER_DANGER %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _run() -> void:
	var sim: Simulation = Simulation.new(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 333, false)
	sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 333, true)
	var hall := sim._find_town_hall()
	var home_farm := sim._create_building(Defs.BUILDING_FARM, hall["position"] + Vector2i(2, 0))
	home_farm["construction"] = false
	home_farm["completed"] = true
	sim.buildings.append(home_farm)
	var home: Dictionary = sim.evaluate_frontier(home_farm)
	_check(not bool(home.get("exposed", true)), "a yard beside the Town Hall stays sheltered")
	_check(String(home.get("label", "")) == "Sheltered", "compact geography is labeled Sheltered")
	var far_tile: Vector2i = hall["position"] + Vector2i(16, 0)
	if far_tile.x >= sim.map_size.x - 3:
		far_tile = hall["position"] + Vector2i(0, 16)
	var quarry := sim._create_building(Defs.BUILDING_QUARRY, far_tile)
	quarry["construction"] = false
	quarry["completed"] = true
	sim.buildings.append(quarry)
	var far: Dictionary = sim.evaluate_frontier(quarry)
	_check(bool(far.get("exposed", false)), "a quarry far from town is exposed")
	_check(float(far.get("score", 0.0)) > float(home.get("score", 1.0)), "distance alone raises exposure")
	var tower := sim._create_building(Defs.BUILDING_WATCHTOWER, far_tile + Vector2i(1, 1))
	tower["construction"] = false
	tower["completed"] = true
	sim.buildings.append(tower)
	var covered: Dictionary = sim.evaluate_frontier(quarry)
	_check(not bool(covered.get("exposed", true)), "a Watchtower on the ridge shelters the quarry")
	sim.buildings.erase(tower)
	var near_store := sim._create_building(Defs.BUILDING_STOREHOUSE, hall["position"] + Vector2i(0, 2))
	near_store["construction"] = false
	near_store["completed"] = true
	sim.buildings.append(near_store)
	var enemy := {
		"id": 7,
		"enemy_type": Simulation.ENEMY_RAIDER,
		"position": far_tile + Vector2i(3, 0),
		"raid_intent": RaidIntents.INTENT_ECONOMY,
		"target_id": 0,
		"target_kind": "building"
	}
	var picked: Dictionary = sim._find_enemy_target_unprofiled(enemy)
	var entity: Dictionary = picked.get("entity", {})
	_check(int(entity.get("id", 0)) == int(quarry.get("id", 0)), "an economy raid prefers the exposed quarry over the home store")


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
