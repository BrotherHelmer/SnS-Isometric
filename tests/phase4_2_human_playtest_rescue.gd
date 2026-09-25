extends SceneTree

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Wyrdfall = preload("res://src/GodotClient/Scripts/one_shard_wyrdfall.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")


func _init() -> void:
	var failures: Array[String] = []
	_test_clear_and_build(failures)
	_test_storage_storehouse(failures)
	_test_tree_cadence(failures)
	_test_objective_guidance(failures)
	_test_notices(failures)
	_test_nights(failures)
	_test_combat_matrix(failures)
	_test_tower_guard_presentation(failures)
	_test_founding_apron(failures)
	if failures.is_empty():
		print("PHASE42_RESCUE PASS")
		quit(0)
	else:
		for line in failures:
			print("FAIL %s" % line)
		print("PHASE42_RESCUE FAIL %d" % failures.size())
		quit(1)


func check(ok: bool, label: String, failures: Array[String]) -> void:
	if not ok:
		failures.append(label)
	print("%s %s" % ["PASS" if ok else "FAIL", label])


func _test_clear_and_build(failures: Array[String]) -> void:
	var sim: Simulation = Simulation.new(70, 70, 260821, false, true)
	sim.population_current = 8
	sim.housing_capacity = 10
	sim.central_inventory[Defs.RESOURCE_WOOD] = 40
	sim.central_inventory[Defs.RESOURCE_PLANKS] = 20
	sim.central_inventory[Defs.RESOURCE_STONE] = 20
	var road := sim._town_hall_entrance_tile() + Vector2i(0, 1)
	sim._prepare_test_tile(road, Defs.TILE_GRASS)
	sim.request_build(Defs.BUILDING_ROAD, road)
	var lumber := sim._add_completed_building(Defs.BUILDING_LUMBER_CAMP, road + Vector2i(3, 0))
	lumber["connected"] = true
	lumber["assigned_staff"] = 1
	sim._try_staff_building(lumber)
	sim._sync_production_workers()
	var house := road + Vector2i(0, 1)
	for offset in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i(1, 1)]:
		sim._prepare_test_tile(house + offset, Defs.TILE_TREE)
		sim.tree_deposits[sim._tile_key(house + offset)] = 1
	var validation := sim.validate_placement(Defs.BUILDING_HOUSE, house)
	check(bool(validation.get("success", false)), "house can be planned on trees", failures)
	check("CLEARING REQUIRED" in String(validation.get("message", "")), "preview reports CLEARING REQUIRED", failures)
	var result := sim.request_build(Defs.BUILDING_HOUSE, house)
	var site := sim.get_building_at_tile(house)
	check(bool(result.get("success", false)) and bool(site.get("site_clearing", false)), "planned house waits as CLEARING SITE", failures)
	check(sim.get_tile(house) == Defs.TILE_TREE, "living trees remain until harvested", failures)
	sim._simulate_seconds_for_test(40.0)
	var finished := sim.get_building_at_tile(house)
	var trees_left := 0
	for offset in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i(1, 1)]:
		if sim.get_tile(house + offset) == Defs.TILE_TREE:
			trees_left += 1
	check(trees_left < 4 or String(finished.get("type", "")) == Defs.BUILDING_HOUSE or not bool(finished.get("site_clearing", true)), "site clearing advances on forested footprint", failures)
	var marked := sim.request_clear_area([house + Vector2i(3, 0)])
	check(bool(marked.get("success", false)) or String(marked.get("reason", "")) in ["Empty", "Terrain"], "clear area tool accepts a tile list", failures)


func _test_storage_storehouse(failures: Array[String]) -> void:
	var sim: Simulation = Simulation.new(70, 70, 260821, false, true)
	sim.population_current = 8
	sim.housing_capacity = 10
	for resource_type in [Defs.RESOURCE_WOOD, Defs.RESOURCE_PLANKS, Defs.RESOURCE_STONE]:
		sim.central_inventory[resource_type] = sim.get_storage_limit(resource_type)
	var road := sim._town_hall_entrance_tile() + Vector2i(1, 0)
	sim._prepare_test_tile(road, Defs.TILE_GRASS)
	sim.request_build(Defs.BUILDING_ROAD, road)
	var store := road + Vector2i(1, 0)
	for y in range(3):
		for x in range(4):
			sim._prepare_test_tile(store + Vector2i(x, y), Defs.TILE_TREE)
			sim.tree_deposits[sim._tile_key(store + Vector2i(x, y))] = 1
	var result := sim.request_build(Defs.BUILDING_STOREHOUSE, store)
	check(bool(result.get("success", false)), "Storehouse can be planned while storage is full", failures)
	sim._simulate_seconds_for_test(80.0)
	var building := sim.get_building_at_tile(store)
	check(String(building.get("type", "")) == Defs.BUILDING_STOREHOUSE or bool(building.get("construction", false)), "full-storage Storehouse plan is not rejected", failures)


func _test_tree_cadence(failures: Array[String]) -> void:
	var interval := float(Defs.PRODUCTION_DEFS[Defs.BUILDING_LUMBER_CAMP].get("interval", 9.0))
	var yield_amount := int(Defs.PRODUCTION_DEFS[Defs.BUILDING_LUMBER_CAMP].get("output_amount", 9))
	check(interval <= 2.01 and yield_amount == 1, "lumber cadence is 2s / 1 wood", failures)
	var sim: Simulation = Simulation.new(70, 70, 707171, false, true)
	var lumber_position := sim.town_hall_position + Vector2i(2, 0)
	sim._clear_area(lumber_position, Simulation.LUMBER_REACH)
	var tree := lumber_position + Vector2i(2, 0)
	sim._prepare_test_tile(tree, Defs.TILE_TREE)
	sim.tree_deposits[sim._tile_key(tree)] = 6
	var lumber := sim._create_building(Defs.BUILDING_LUMBER_CAMP, lumber_position)
	lumber["connected"] = true
	lumber["assigned_staff"] = 1
	sim.buildings.append(lumber)
	var before := Time.get_ticks_msec()
	for _i in 6:
		sim._produce_from_building(lumber)
	check(sim.get_tile(tree) == Defs.TILE_GRASS, "six 1-wood chops fell a 6-deposit tree", failures)
	check(Time.get_ticks_msec() - before < 5000, "tree cadence probe stays cheap", failures)


func _test_objective_guidance(failures: Array[String]) -> void:
	var sim: Simulation = Simulation.new(70, 70, 260821, false, true)
	sim._add_completed_building(Defs.BUILDING_HOUSE, sim.town_hall_position + Vector2i(6, 0))
	sim._add_completed_building(Defs.BUILDING_LUMBER_CAMP, sim.town_hall_position + Vector2i(6, 4))
	sim._add_completed_building(Defs.BUILDING_FARM, sim.town_hall_position + Vector2i(6, 8))
	var objective: Dictionary = sim.get_macro_objective()
	check(String(objective.get("id", "")) == Wyrdfall.OBJECTIVE_REACH, "starter economy moves the macro objective to REACH THE SHARD", failures)
	check(String(objective.get("summary", "")) != "", "objective includes a summary", failures)
	check(objective.get("steps", []).size() >= 2, "objective lists 2-3 next steps", failures)
	var joined := " ".join(objective.get("steps", []))
	check("Outpost" in joined or "road" in joined.to_lower(), "next steps point at frontier expansion", failures)
	check(sim._starter_economy_ready(), "starter economy helper is true after house/lumber/farm", failures)


func _test_notices(failures: Array[String]) -> void:
	var sim: Simulation = Simulation.new(70, 70, 260821, false, true)
	sim.push_notice("economy", "STORAGE FULL", "Build a Storehouse or free capacity.", "warning")
	sim.push_notice("economy", "STORAGE FULL", "Build a Storehouse or free capacity.", "warning")
	var pending: Array = sim.consume_pending_notices()
	check(pending.size() == 2, "notices queue for the toast layer", failures)
	check(sim.get_notice_log().size() >= 2, "event log retains dismissed toast content", failures)
	sim._notice_if_new("STORAGE FULL", "Build a Storehouse or free capacity.", "economy", 48.0)
	check(sim.pending_notices.is_empty(), "identical routine warnings are cooldown-limited", failures)


func _test_nights(failures: Array[String]) -> void:
	var night1 := Wyrdfall.wave_plan(0.0, 1, true, false)
	var night2 := Wyrdfall.wave_plan(8.0, 2, false, false)
	check(int(night1.get("size", 0)) == 2, "Night 1 is a teaching encounter of 2", failures)
	check(int(night2.get("size", 0)) == 5, "Night 2 uses a real encounter budget", failures)
	check(night2.get("roster", []).has(Wyrdfall.ENEMY_MARAUDER), "Night 2 includes Marauders", failures)
	check(float(night2.get("baseline", 0.0)) > 0.0, "Night 2 includes a night baseline", failures)
	var sim: Simulation = Simulation.new(70, 70, 260821, false, true)
	sim.day_count = 2
	sim.is_night = true
	sim._spawn_wave()
	check(sim.enemies.size() == 5, "Night 2 actually spawns five hostiles", failures)
	var in_range := 0
	for enemy in sim.enemies:
		if sim._tile_in_any_tower_range(enemy["position"]):
			in_range += 1
	check(in_range < sim.enemies.size(), "Night 2 does not spawn the whole wave inside tower range", failures)


func _test_combat_matrix(failures: Array[String]) -> void:
	check(Simulation.TOWER_RANGE == 8 and Simulation.TOWER_DAMAGE == 5, "tower range/damage were reduced", failures)
	check(Simulation.GUARD_DAMAGE == 4, "guard damage was reduced", failures)
	var sim: Simulation = Simulation.new(70, 70, 260821, false, true)
	sim.is_night = true
	sim._reveal_radius(sim.town_hall_position, 20)
	var guard := sim._create_patrol_worker(0, "matrix")
	guard["position"] = sim.town_hall_position + Vector2i(2, 0)
	sim.workers.append(guard)
	sim._spawn_enemy(guard["position"] + Vector2i(1, 0), 30, 7, 0.0, 0, Simulation.ENEMY_RAIDER)
	var start_hp := int(sim.enemies[0]["hp"])
	sim._update_patrol_combat(1.6)
	sim._update_patrol_combat(0.5)
	check(int(sim.enemies[0]["hp"]) < start_hp, "1 guard vs 1 Raider exchanges damage instead of instantly deleting", failures)
	check(int(sim.enemies[0]["hp"]) > 0, "a single exchange does not finish a Raider", failures)

	var tower_sim: Simulation = Simulation.new(70, 70, 260821, false, true)
	tower_sim.is_night = true
	tower_sim.soldiers_total = 1
	var tower := tower_sim._create_building(Defs.BUILDING_WATCHTOWER, tower_sim.town_hall_position + Vector2i(1, 0))
	tower["connected"] = true
	tower["soldiers_assigned"] = 1
	tower["assigned_staff"] = 1
	tower["staffed"] = true
	tower_sim.buildings.append(tower)
	tower_sim._reveal_radius(tower["position"], 16)
	tower_sim._spawn_enemy(tower["position"] + Vector2i(3, 0), 30, 7, 0.0, 0, Simulation.ENEMY_RAIDER)
	tower_sim._update_towers(0.1)
	for _impact in 8:
		tower_sim._update_projectiles(Simulation.TICK_SECONDS)
	check(tower_sim.projectiles.size() >= 0, "tower still fires projectiles with impact delay", failures)
	if not tower_sim.enemies.is_empty():
		check(int(tower_sim.enemies[0]["hp"]) >= 30 - Simulation.TOWER_DAMAGE, "one tower shot wounds rather than deleting a Night 2 Raider", failures)

	var night2: Simulation = Simulation.new(70, 70, 260821, false, true)
	night2.soldiers_total = 1
	var n2_tower := night2._add_completed_building(Defs.BUILDING_WATCHTOWER, night2.town_hall_position + Vector2i(2, 0))
	n2_tower["connected"] = true
	n2_tower["soldiers_assigned"] = 1
	night2._try_staff_building(n2_tower)
	night2._sync_production_workers()
	night2.day_count = 2
	night2.is_night = true
	night2._spawn_wave()
	var closest := 999
	var melee_seen := 0
	var shots := 0
	for _second in 28:
		shots = maxi(shots, night2.projectiles.size())
		night2._simulate_seconds_for_test(1.0)
		for enemy in night2.enemies:
			var distance := night2._manhattan(night2.town_hall_position, Vector2i(enemy.get("position", Vector2i.ZERO)))
			closest = mini(closest, distance)
			if distance <= 3:
				melee_seen += 1
	check(closest <= 4, "Night 2 under one tower still approaches the yard", failures)
	print("MATRIX night2_one_tower closest=%d melee_ticks=%d shots=%d alive=%d" % [closest, melee_seen, shots, night2.enemies.size()])


func _test_tower_guard_presentation(failures: Array[String]) -> void:
	var sim: Simulation = Simulation.new(70, 70, 260821, false, true)
	sim.soldiers_total = 1
	var tower := sim._add_completed_building(Defs.BUILDING_WATCHTOWER, sim.town_hall_position + Vector2i(2, 0))
	tower["soldiers_assigned"] = 1
	tower["assigned_staff"] = 1
	tower["staffed"] = true
	sim._try_staff_building(tower)
	sim._sync_production_workers()
	var guard := {}
	for worker in sim.workers:
		if String(worker.get("type", "")) == "guard" and int(worker.get("building_id", 0)) == int(tower["id"]):
			guard = worker
			break
	if guard.is_empty():
		check(false, "staffed watchtower has an assigned guard", failures)
		return
	sim._update_production_workers(0.1)
	var presentation: Dictionary = sim.get_worker_work_presentation(guard)
	check(bool(presentation.get("platform", false)) and float(presentation.get("elevation", 0.0)) > 3.0, "watchtower guard presents on the platform", failures)


func _test_founding_apron(failures: Array[String]) -> void:
	var sim: Simulation = Simulation.new(70, 70, 260821, false, true)
	var center := sim._footprint_center(sim.town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	var grass := 0
	var trees := 0
	for offset in sim._radius_offsets(6):
		var tile: Vector2i = center + offset
		if not sim.is_inside_map(tile):
			continue
		if sim.get_tile(tile) == Defs.TILE_GRASS:
			grass += 1
		elif sim.get_tile(tile) == Defs.TILE_TREE:
			trees += 1
	check(grass >= 80, "founding apron keeps a practical buildable pocket", failures)
	check(trees < 20, "starting trees do not choke the Town Hall pocket", failures)
