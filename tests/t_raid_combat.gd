extends SceneTree

## Headless raid balance: an undefended yard takes real building / stock
## losses; a Watchtower plus Barracks patrol wins without a building falling.

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const RaidTuning = preload("res://src/GodotClient/Scripts/one_shard_raid_tuning.gd")

var failures: Array[String] = []


func _init() -> void:
	_test_undefended()
	_test_defended()
	print("T_RAID_COMBAT %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_undefended() -> void:
	var sim: Simulation = _yard(false)
	var store := _storehouse(sim)
	var hp_before := int(store.get("hp", 0))
	var bread_before := int(sim.central_inventory.get(Defs.RESOURCE_BREAD, 0))
	var wood_before := int(sim.central_inventory.get(Defs.RESOURCE_WOOD, 0))
	_spawn_raiders(sim, store["position"], 3)
	sim._simulate_seconds_for_test(RaidTuning.UNDEFENDED_SIM_SECONDS)
	var store_after := sim._find_building_by_id(int(store.get("id", 0)))
	var hp_after := 0 if store_after.is_empty() else int(store_after.get("hp", 0))
	var bread_after := int(sim.central_inventory.get(Defs.RESOURCE_BREAD, 0))
	var wood_after := int(sim.central_inventory.get(Defs.RESOURCE_WOOD, 0))
	var stolen: int = (bread_before - bread_after) + (wood_before - wood_after)
	var damaged := hp_after < hp_before or store_after.is_empty()
	print("RAID_UNDEFENDED hp %d->%d stolen=%d destroyed=%s hostiles=%d" % [
		hp_before, hp_after, stolen, str(store_after.is_empty()), sim.living_hostile_count()
	])
	_check(damaged, "undefended raid damages the Storehouse")
	_check(stolen > 0 or store_after.is_empty(), "undefended raid steals stock or destroys storage")
	_check(not sim.game_finished, "undefended Night-2-sized raid does not instantly end the run")


func _test_defended() -> void:
	var sim: Simulation = _yard(true)
	var store := _storehouse(sim)
	var buildings_before := {}
	for building in sim.buildings:
		if String(building.get("type", "")) == Defs.BUILDING_ROAD:
			continue
		buildings_before[int(building["id"])] = int(building.get("hp", 0))
	var origin: Vector2i = store["position"] + Vector2i(2, 0)
	_spawn_raiders(sim, origin, RaidTuning.DEFENDED_RAIDER_COUNT)
	var elapsed := 0.0
	while sim.living_hostile_count() > 0 and elapsed < RaidTuning.DEFENDED_MAX_SECONDS:
		sim.advance_tick()
		elapsed += Simulation.TICK_SECONDS
	print("RAID_DEFENDED elapsed=%.1f hostiles=%d destroyed=%d" % [
		elapsed, sim.living_hostile_count(), int(sim.stats.get("buildings_destroyed", 0))
	])
	_check(sim.living_hostile_count() == 0, "defended raid kills every raider")
	_check(elapsed >= RaidTuning.DEFENDED_MIN_SECONDS, "defended raid lasts long enough to read as a fight")
	_check(elapsed <= RaidTuning.DEFENDED_MAX_SECONDS, "defended raid ends inside the published time bound")
	var destroyed := 0
	for building in sim.buildings:
		if String(building.get("type", "")) == Defs.BUILDING_ROAD:
			continue
		if not buildings_before.has(int(building["id"])):
			continue
		if int(building.get("hp", 0)) <= 0:
			destroyed += 1
	_check(destroyed == 0 and int(sim.stats.get("buildings_destroyed", 0)) == 0, "defended raid destroys no building")
	_check(sim._find_building_by_id(int(store.get("id", 0))).size() > 0, "Storehouse still stands after a defended raid")


func _yard(defended: bool) -> Simulation:
	var sim: Simulation = Simulation.new(70, 70, 260821, false, true)
	sim.day_count = 2
	sim.is_night = true
	sim.phase_time = 4.0
	sim.central_inventory[Defs.RESOURCE_BREAD] = 40
	sim.central_inventory[Defs.RESOURCE_WOOD] = 40
	sim._reveal_radius(sim.town_hall_position, 24)
	sim._send_workers_to_shelter()
	if defended:
		sim.soldiers_total = 3
		var tower := sim._add_completed_building(Defs.BUILDING_WATCHTOWER, sim.town_hall_position + Vector2i(2, 0))
		tower["connected"] = true
		tower["soldiers_assigned"] = 1
		tower["staffed"] = true
		var tower_center: Vector2i = sim._footprint_center(tower["position"], sim._building_footprint(tower))
		sim._reveal_radius(tower_center, 12)
		for slot in 2:
			var guard: Dictionary = sim._create_patrol_worker(slot, "raid_test_%d" % slot)
			guard["position"] = sim.town_hall_position + Vector2i(3, slot)
			sim.workers.append(guard)
			sim._reveal_radius(guard["position"], 6)
	return sim


func _storehouse(sim: Simulation) -> Dictionary:
	var tile := sim.town_hall_position + Vector2i(4, 1)
	sim._prepare_test_tile(tile, Defs.TILE_GRASS)
	var store := sim._add_completed_building(Defs.BUILDING_STOREHOUSE, tile)
	store["connected"] = true
	sim._reveal_radius(tile, 8)
	return store


func _spawn_raiders(sim: Simulation, origin: Vector2i, count: int) -> void:
	for index in range(count):
		var tile: Vector2i = origin + Vector2i(1, index)
		sim._prepare_test_tile(tile, Defs.TILE_GRASS)
		sim._reveal_radius(tile, 4)
		sim._spawn_enemy(
			tile,
			RaidTuning.NIGHT2_HP,
			RaidTuning.NIGHT2_DAMAGE,
			0.0,
			0,
			sim.ENEMY_RAIDER,
			RaidTuning.NIGHT2_ARMOR
		)
	sim._begin_raid(RaidTuning.NIGHT2_STEAL)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
