extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Adapter = preload("res://src/GodotClient3D/Scripts/production_presentation_adapter.gd")
const Fixture = preload("res://src/GodotClient3D/Scripts/production_demo_fixture.gd")
const RivalryTuning = preload("res://src/GodotClient/Scripts/one_shard_rivalry_tuning.gd")
const Identity = preload("res://src/GodotClient3D/Scripts/production_identity.gd")

const SAVE_PATH := "res://artifacts/phase3_2/persistence/resource_visual_round_trip.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game._hide_start_menu()
	game.simulation_host.paused = true
	var simulation = game.simulation_host.simulation
	var fixture_result: Dictionary = Fixture.new().apply(simulation, "developed")
	_check(failures, bool(fixture_result.get("success", false)), "developed settlement fixture is healthy")
	game._initialize_presentation()
	await process_frame

	_check_fog_alignment(failures, game)
	_check_fog_hiding(failures, game)
	_check_road_contract(failures, simulation)
	_check_work_sockets(failures, simulation)
	_check_resource_visuals(failures, game)
	_check_world_mood(failures, game)
	_check_sovereign_removal(failures, game)
	_check_combat_cadence(failures)
	_check_tower_cadence(failures)

	game.queue_free()
	await process_frame
	_finish(failures)


func _check_fog_alignment(failures: Array[String], game) -> void:
	var simulation = game.simulation_host.simulation
	var samples: Array[Vector2i] = [
		Vector2i.ZERO,
		Vector2i(simulation.map_size.x - 1, 0),
		Vector2i(0, simulation.map_size.y - 1),
		simulation.map_size - Vector2i.ONE,
		Vector2i(simulation.map_size.x / 2, simulation.map_size.y / 2),
	]
	var elevated := samples[4]
	for y in simulation.map_size.y:
		for x in simulation.map_size.x:
			var candidate := Vector2i(x, y)
			if simulation.get_height(candidate) > simulation.get_height(elevated):
				elevated = candidate
	samples.append(elevated)
	simulation.revealed_tiles.clear()
	for tile in samples:
		simulation.revealed_tiles[simulation._tile_key(tile)] = true
	game.world_view._sync_fog(true)
	var aligned := true
	for tile in samples:
		var uv: Vector2 = game.world_view.fog_uv_for_tile(tile)
		var expected := (Vector2(tile) + Vector2(0.5, 0.5)) / Vector2(simulation.map_size)
		if uv.distance_to(expected) >= 0.0001 or game.world_view.fog_mask_sample_for_tile(tile) <= 0.99:
			print("FOW DIAGNOSTIC tile=%s uv=%s expected=%s mask=%.3f height=%d" % [tile, uv, expected, game.world_view.fog_mask_sample_for_tile(tile), simulation.get_height(tile)])
		aligned = aligned and uv.distance_to(expected) < 0.0001 and game.world_view.fog_mask_sample_for_tile(tile) > 0.99
	var unknown := Vector2i(1, 1)
	while samples.has(unknown):
		unknown += Vector2i.ONE
	aligned = aligned and game.world_view.fog_mask_sample_for_tile(unknown) < 0.01
	_check(failures, aligned, "FOW mask aligns at center, corners, edges, and elevated cells")
	var fog_transform: Transform3D = game.world_view.fog_plane.global_transform
	var fog_uv: Vector2 = game.world_view.fog_uv_for_tile(elevated)
	game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(unknown)), game.camera_rig.STRATEGIC_ZOOM)
	_check(failures, game.world_view.fog_plane.global_transform.is_equal_approx(fog_transform) and game.world_view.fog_uv_for_tile(elevated).is_equal_approx(fog_uv), "camera pan and zoom do not move FOW relative to terrain")


func _check_fog_hiding(failures: Array[String], game) -> void:
	var fog: Dictionary = game.world_view.fog_configuration()
	var simulation = game.simulation_host.simulation
	var unknown := Vector2i(1, 1)
	var enemy := {"id": 99001, "enemy_type": simulation.ENEMY_RAIDER, "position": unknown, "hp": 18, "max_hp": 18, "path": [], "hit_until": 0.0, "attack_flash": 0.0}
	var worker := {"id": 99002, "type": "settler", "position": unknown, "previous_position": unknown, "state": "Idle", "path": [], "hp": 20, "max_hp": 20}
	var adapter := Adapter.new()
	var hidden_enemy: Dictionary = adapter.enemy_descriptor(enemy, simulation)
	var hidden_worker: Dictionary = adapter.worker_descriptor(worker, simulation)
	_check(failures, bool(fog.get("world_anchored", false)) and float(fog.get("unknown_opacity", 0.0)) >= 0.995, "unknown territory uses an effectively opaque world-space atmosphere")
	_check(failures, bool(fog.get("volume_mesh", false)) and bool(fog.get("exterior_opaque", false)), "fog is a volume and off-map samples stay unknown")
	var sheet := game.world_view.fog_plane.mesh as PlaneMesh
	var map_span := float(simulation.map_size.x) * 2.5
	_check(failures, sheet != null and sheet.size.x >= map_span + 80.0, "fog sheet extends past the terrain slab")
	_check(failures, game.world_view.fog_plane != null and game.world_view.fog_skirts.size() >= 4, "fog skirts seal the isometric island edge")
	var world_min: Vector2 = fog.get("world_min_xz", Vector2.ZERO)
	var outside_uv: Vector2 = game.world_view.fog_world_to_uv(Vector3(world_min.x - 40.0, 0.0, world_min.y - 40.0))
	_check(failures, outside_uv.x < 0.0 or outside_uv.y < 0.0, "positions beyond the map sit outside the visibility mask")
	_check(failures, not bool(hidden_enemy.get("visible", true)) and not bool(hidden_worker.get("visible", true)), "unrevealed friendly and hostile units never enter visible presentation")


func _check_road_contract(failures: Array[String], simulation) -> void:
	simulation.revealed_tiles[simulation._tile_key(simulation.town_hall_position)] = true
	var types := [Defs.BUILDING_TOWN_HALL, Defs.BUILDING_HOUSE, Defs.BUILDING_LUMBER_CAMP, Defs.BUILDING_QUARRY, Defs.BUILDING_SAWMILL, Defs.BUILDING_FARM, Defs.BUILDING_BAKERY, Defs.BUILDING_BARRACKS, Defs.BUILDING_STOREHOUSE]
	var all_valid := true
	for index in types.size():
		var type_name: String = types[index]
		var footprint := Defs.building_footprint(type_name)
		var building := {"type": type_name, "position": Vector2i(10 + index * 4, 10), "footprint": footprint, "rotation": 0}
		var access: Array[Vector2i] = simulation.get_building_road_access_candidates(building)
		all_valid = all_valid and not access.is_empty()
		for tile in access:
			all_valid = all_valid and not simulation._footprint_tiles(building.position, footprint).has(tile) and simulation._footprint_perimeter(building.position, footprint).has(tile)
	_check(failures, all_valid, "every core road-dependent building exposes explicit adjacent road access cells")
	_check(failures, simulation._has_building_clearance(Vector2i.ZERO, Vector2i(9, 9)), "presentation overhang never expands authoritative road exclusion")
	var route_result: Dictionary = simulation.validate_road_route([simulation.town_hall_position])
	if String(route_result.get("message", "")) != "Building occupies this tile":
		print("ROAD DIAGNOSTIC result=%s tile=%s terrain=%s revealed=%s building=%s rivalry=%s" % [route_result, simulation.town_hall_position, simulation.get_tile(simulation.town_hall_position), simulation.is_revealed(simulation.town_hall_position), simulation.get_building_at_tile(simulation.town_hall_position), simulation.rivalry.is_rivalry_occupied(simulation.town_hall_position)])
	_check(failures, not bool(route_result.get("success", true)) and String(route_result.get("message", "")) == "Building occupies this tile", "road preview reports the actual local building-footprint reason")


func _check_work_sockets(failures: Array[String], simulation) -> void:
	var sockets: Dictionary = {}
	var moved_off_access := false
	for worker_value in simulation.workers:
		var worker: Dictionary = worker_value
		if int(worker.get("building_id", 0)) <= 0:
			continue
		worker["path"] = []
		worker["state"] = "Working"
		var presentation: Dictionary = simulation.get_worker_work_presentation(worker)
		if presentation.is_empty():
			continue
		var key := "%d:%d" % [int(worker.get("building_id", 0)), int(presentation.get("socket_index", -1))]
		sockets[key] = Vector2(presentation.get("position", Vector2.ZERO))
		moved_off_access = moved_off_access or Vector2(presentation.get("position", Vector2.ZERO)).distance_to(Vector2(worker.get("position", Vector2i.ZERO))) > 0.25
	_check(failures, moved_off_access, "working characters use a local building or yard socket instead of the road access tile")
	var distinct := true
	var positions := sockets.values()
	for first in positions.size():
		for second in range(first + 1, positions.size()):
			if Vector2(positions[first]).is_equal_approx(Vector2(positions[second])):
				distinct = false
	_check(failures, distinct, "deterministic worker sockets do not stack visible workers")


func _check_resource_visuals(failures: Array[String], game) -> void:
	var simulation = game.simulation_host.simulation
	var tree := _first_deposit_tile(simulation.tree_deposits)
	_check(failures, tree.x >= 0, "fixture contains an authoritative tree resource")
	if tree.x < 0:
		return
	game.world_view._sync_nature(true)
	var key: String = simulation._tile_key(tree)
	var initial_stage := int(game.world_view.nature_stages.get(key, -1))
	var initial_amount := int(simulation.tree_deposits.get(key, 0))
	simulation._consume_deposit(tree, maxi(1, initial_amount - 6))
	game.world_view._sync_nature(false)
	var reduced_stage := int(game.world_view.nature_stages.get(key, -1))
	simulation._consume_deposit(tree, 999)
	game.world_view._sync_nature(false)
	_check(failures, reduced_stage < initial_stage and String(game.world_view.nature_views.get(key, "")) == "STUMP", "tree visuals reduce with authority and end as a deterministic stump marker")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_PATH.get_base_dir()))
	var saved: bool = simulation.save_to_path(SAVE_PATH)
	var restored = Simulation.new(simulation.map_size.x, simulation.map_size.y, 321321, false, true)
	var loaded := restored.load_from_path(SAVE_PATH)
	_check(failures, saved and loaded and restored.get_tile(tree) == Defs.TILE_GRASS and float(restored.tree_regrowth.get(key, 1.0)) <= 0.0, "save/load reconstructs the same cleared tree presentation state")


func _check_world_mood(failures: Array[String], game) -> void:
	var simulation = game.simulation_host.simulation
	simulation.is_night = false
	simulation.phase_time = 100.0
	game._update_day_night_lighting()
	var day_energy: float = game.sun_light.light_energy
	var day_saturation: float = game.environment_resource.adjustment_saturation
	simulation.is_night = true
	simulation.phase_time = 30.0
	game._update_day_night_lighting()
	var night_energy: float = game.sun_light.light_energy
	var night_threshold: float = float(Identity.LIGHTING["night"]["sun_energy"]) + 0.04
	_check(failures, day_energy >= 1.0 and night_energy <= night_threshold and night_energy < day_energy and game.environment_resource.adjustment_saturation < day_saturation, "day is warm and bright while night is cool, dark, and desaturated")
	var town_hall: Dictionary = simulation._find_town_hall()
	var town_view = game.world_view.building_views.get(int(town_hall.get("id", 0)))
	_check(failures, town_view != null and town_view.find_child("CivicMeetingPlaza", true, false) != null and town_view.find_child("CivicTimberWing", true, false) == null, "Town Hall keeps the castle silhouette without placeholder timber wings")


func _check_sovereign_removal(failures: Array[String], game) -> void:
	var combatants: Array = game.presentation_adapter.capture_frame(game.simulation_host.simulation).get("combatants", [])
	var visible_sovereign := false
	for value in combatants:
		visible_sovereign = visible_sovereign or "sovereign" in String(Dictionary(value).get("worker_type", ""))
	var move_result: Dictionary = game.simulation_host.simulation.set_player_sovereign_target(Vector2i.ZERO)
	var claim_requirements: Dictionary = game.simulation_host.simulation.rivalry.claim_requirements(RivalryTuning.PLAYER_REALM)
	_check(failures, game.ui_layer.find_child("SovereignFocus", true, false) == null and not visible_sovereign and not bool(move_result.get("success", false)), "Sovereign HUD, selection, rendering, and direct movement are removed")
	_check(failures, bool(claim_requirements.get("sovereign", false)) and not "Sovereign" in String(claim_requirements.get("summary", "")), "player claim authority now belongs to the settlement Outpost network")


func _check_combat_cadence(failures: Array[String]) -> void:
	var simulation = Simulation.new(70, 70, 778811, false, true)
	var guard: Dictionary = simulation._create_patrol_worker(0, "phase32_guard")
	guard["position"] = simulation._town_hall_entrance_tile()
	simulation.workers.append(guard)
	var enemy_position: Vector2i = guard.position + Vector2i.RIGHT
	simulation._prepare_test_tile(enemy_position, Defs.TILE_GRASS)
	simulation._reveal_radius(enemy_position, 2)
	simulation._spawn_enemy(enemy_position, 18, 10, 0.0, 0, simulation.ENEMY_RAIDER)
	var enemy: Dictionary = simulation.enemies[0]
	var hits := 0
	var previous_hp := int(enemy.hp)
	var elapsed := 0.0
	while int(enemy.hp) > 0 and elapsed < 10.0:
		simulation.elapsed_seconds += simulation.TICK_SECONDS
		simulation._update_patrol_combat(simulation.TICK_SECONDS)
		elapsed += simulation.TICK_SECONDS
		if int(enemy.hp) < previous_hp:
			hits += 1
			previous_hp = int(enemy.hp)
	_check(failures, hits >= 3 and elapsed >= 3.0 and elapsed <= 7.0, "basic soldier versus basic Raider produces at least three readable hits over roughly 3–7 seconds")


func _check_tower_cadence(failures: Array[String]) -> void:
	var simulation = Simulation.new(70, 70, 778812, false, true)
	var tower := simulation._create_building(Defs.BUILDING_WATCHTOWER, simulation.town_hall_position + Vector2i(5, 0))
	tower["connected"] = true
	tower["soldiers_assigned"] = 1
	tower["staffed"] = true
	simulation.buildings.append(tower)
	var enemy_position: Vector2i = tower.position + Vector2i(3, 0)
	simulation._prepare_test_tile(enemy_position, Defs.TILE_GRASS)
	simulation._reveal_radius(enemy_position, 2)
	simulation._spawn_enemy(enemy_position, 18, 3, 0.0, 0, simulation.ENEMY_RAIDER)
	var enemy: Dictionary = simulation.enemies[0]
	simulation._update_towers(simulation.TICK_SECONDS)
	var delayed: bool = int(enemy.hp) == 18 and simulation.projectiles.size() == 1
	var shots := 1
	var elapsed := 0.0
	while int(enemy.hp) > 0 and elapsed < 10.0:
		var before: int = simulation.projectiles.size()
		simulation.elapsed_seconds += simulation.TICK_SECONDS
		simulation._update_towers(simulation.TICK_SECONDS)
		if simulation.projectiles.size() > before:
			shots += 1
		simulation._update_projectiles(simulation.TICK_SECONDS)
		elapsed += simulation.TICK_SECONDS
	_check(failures, delayed and shots >= 3 and elapsed >= 3.0, "Watchtower damage lands on projectile impact and a basic Raider survives multiple visible shots")


func _first_deposit_tile(deposits: Dictionary) -> Vector2i:
	for key in deposits:
		var parts := String(key).split(",")
		return Vector2i(int(parts[0]), int(parts[1]))
	return Vector2i(-1, -1)


func _check(failures: Array[String], condition: bool, label: String) -> void:
	print("%s %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		failures.append(label)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("PHASE3_2_WORLD_FEEL_SMOKE PASS")
		quit(0)
	else:
		print("PHASE3_2_WORLD_FEEL_SMOKE FAIL count=%d" % failures.size())
		quit(1)
