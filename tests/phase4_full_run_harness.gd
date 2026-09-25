extends SceneTree

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Wyrdfall = preload("res://src/GodotClient/Scripts/one_shard_wyrdfall.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Tuning = preload("res://src/GodotClient/Scripts/one_shard_rivalry_tuning.gd")

const SEEDS := [260821, 424242, 717171]


func _init() -> void:
	var failures: Array[String] = []
	for seed_value in SEEDS:
		_run_seed(int(seed_value), failures)
	if failures.is_empty():
		print("PHASE4_FULL_RUN_HARNESS PASS seeds=%s" % str(SEEDS))
		quit(0)
	else:
		for failure in failures:
			print("FAIL: %s" % failure)
		print("PHASE4_FULL_RUN_HARNESS FAIL (%d)" % failures.size())
		quit(1)


func _run_seed(seed_value: int, failures: Array[String]) -> void:
	var simulation = Simulation.new(70, 70, seed_value, false, true)
	check(failures, simulation.rivalry != null, "seed %d founds a live realm" % seed_value)
	check(failures, _count_tile(simulation, Defs.TILE_SHARD) == 1, "seed %d has one Shard" % seed_value)
	var wood_before := int(simulation.central_inventory.get(Defs.RESOURCE_WOOD, 0))
	var road := simulation._town_hall_entrance_tile() + Vector2i.LEFT
	simulation._prepare_test_tile(road, Defs.TILE_GRASS)
	check(failures, bool(simulation.request_build(Defs.BUILDING_ROAD, road).get("success", false)), "seed %d can plan a road" % seed_value)
	for _tick in range(80):
		simulation.advance_tick()
	check(failures, simulation.connected_roads.has(simulation._tile_key(road)), "seed %d physical road construction completes" % seed_value)
	check(failures, int(simulation.central_inventory.get(Defs.RESOURCE_WOOD, 0)) <= wood_before, "seed %d does not teleport wood for roads" % seed_value)

	simulation.day_count = 1
	simulation.phase_time = simulation.DAY_LENGTH_SECONDS
	simulation.night_warning_sent = true
	simulation.night_final_warning_sent = true
	simulation.advance_tick()
	check(failures, simulation.is_night and simulation.enemies.size() >= 2, "seed %d first night produces a real threat" % seed_value)
	var first_night_size: int = simulation.enemies.size()
	simulation.enemies.clear()
	simulation.is_night = false
	simulation.phase_time = 0.0
	simulation.cumulative_wyrd_extracted = 20
	simulation.day_count = 4
	simulation._spawn_wave()
	check(failures, simulation.enemies.size() > first_night_size, "seed %d later pressure produces a larger raid" % seed_value)

	_configure_ready_claim(simulation, simulation.rivalry, Tuning.PLAYER_REALM)
	check(failures, bool(simulation.rivalry.claim_requirements(Tuning.PLAYER_REALM).get("ready", false)), "seed %d can satisfy Binding requirements" % seed_value)
	check(failures, bool(simulation.request_begin_binding().get("success", false)), "seed %d can begin Binding" % seed_value)
	simulation.rivalry._update_claims(Wyrdfall.BINDING_DURATION_SECONDS, true, 0.0, Simulation.NIGHT_LENGTH_SECONDS)
	check(failures, simulation.victory, "seed %d Binding can succeed" % seed_value)

	var lose = Simulation.new(70, 70, seed_value + 11, false, true)
	_configure_ready_claim(lose, lose.rivalry, Tuning.AI_REALM)
	lose.rivalry.elapsed_seconds = Tuning.AI_CLAIM_UNLOCK_SECONDS + 1.0
	lose.rivalry.request_begin_claim(Tuning.AI_REALM)
	lose.rivalry._update_claims(Wyrdfall.BINDING_DURATION_SECONDS, false, 0.0, Simulation.DAY_LENGTH_SECONDS)
	check(failures, lose.game_finished and not lose.victory, "seed %d rival can win" % seed_value)

	var round_trip = Simulation.new(70, 70, seed_value, false, true)
	round_trip.cumulative_wyrd_extracted = 5
	var data: Dictionary = round_trip._serialize_state()
	var loaded = Simulation.new(70, 70, 1, false)
	loaded._restore_state(data)
	check(failures, loaded.rng_seed == seed_value and loaded.cumulative_wyrd_extracted == 5, "seed %d save/load remains valid" % seed_value)


func check(failures: Array[String], condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)


func _count_tile(simulation, tile_type: String) -> int:
	var count := 0
	for y in range(simulation.map_size.y):
		for x in range(simulation.map_size.x):
			if String(simulation.map_tiles[y][x]) == tile_type:
				count += 1
	return count


func _configure_ready_claim(simulation, rivalry, realm_id: String) -> void:
	var realm: Dictionary = rivalry.realms[realm_id]
	var entrance: Vector2i = realm["entrance"]
	var outpost_anchor: Vector2i = simulation.shard_position + (Vector2i(3, -1) if realm_id == Tuning.AI_REALM else Vector2i(-4, 0))
	var road_target: Vector2i = outpost_anchor + (Vector2i.RIGHT if realm_id == Tuning.AI_REALM else Vector2i.LEFT)
	var current := entrance
	while current.x != road_target.x:
		current += Vector2i(1 if road_target.x > current.x else -1, 0)
		realm["roads"][rivalry._key(current)] = true
	while current.y != road_target.y:
		current += Vector2i(0, 1 if road_target.y > current.y else -1)
		realm["roads"][rivalry._key(current)] = true
	var home_center: Vector2 = rivalry._home_center(realm_id)
	for fraction in [0.18, 0.36, 0.54, 0.72, 0.88]:
		var pillar_position: Vector2i = Vector2i(home_center.lerp(Vector2(simulation.shard_position), float(fraction)))
		var pillar: Dictionary = {
			"id": rivalry.next_structure_id,
			"realm_id": realm_id,
			"type": Tuning.STRUCTURE_LUMEN_PILLAR,
			"position": pillar_position,
			"footprint": Vector2i.ONE,
			"hp": 90,
			"max_hp": 90,
			"active": true,
			"connected": true,
			"damage_flash": 0.0
		}
		rivalry.next_structure_id += 1
		rivalry.structures.append(pillar)
		realm["structures"].append(pillar["id"])
	var outpost: Dictionary = {
		"id": rivalry.next_structure_id,
		"realm_id": realm_id,
		"type": Tuning.STRUCTURE_CLAIMANT_OUTPOST,
		"position": outpost_anchor,
		"footprint": Vector2i(2, 2),
		"hp": 220,
		"max_hp": 220,
		"active": true,
		"connected": true,
		"damage_flash": 0.0
	}
	rivalry.next_structure_id += 1
	rivalry.structures.append(outpost)
	realm["structures"].append(outpost["id"])
	realm["claim"]["outpost_id"] = outpost["id"]
	rivalry.get_resources(realm_id)[Defs.RESOURCE_WYRD] = 100
	if realm_id == Tuning.AI_REALM:
		rivalry.get_sovereign(realm_id)["position"] = Vector2(simulation.shard_position)
