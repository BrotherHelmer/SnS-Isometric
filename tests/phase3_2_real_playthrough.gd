extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Fixture = preload("res://src/GodotClient3D/Scripts/production_demo_fixture.gd")
const Tuning = preload("res://src/GodotClient/Scripts/one_shard_rivalry_tuning.gd")

const Identity = preload("res://src/GodotClient3D/Scripts/production_identity.gd")

const SAVE_PATH := "res://artifacts/phase3_2/persistence/eighteen_step_playthrough.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/phase3_2/persistence"))
	var failures: Array[String] = []
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var start_button: Button = game.startup_overlay.find_child("NewReviewSeed", true, false)
	start_button.pressed.emit()
	await process_frame
	var simulation = game.simulation_host.simulation
	var fixture := Fixture.new()
	var initial_resources: Dictionary = simulation.get_resources()
	print("P32_PLAY 01 New Settlement seed=%d resources=%s" % [simulation.rng_seed, initial_resources])
	_check(failures, simulation.rng_seed == game.DEFAULT_SEED and simulation.population_current == 2, "1. start New Settlement through the production menu")
	_check(failures, _starting_resources_match(initial_resources), "1. opening economy is the authored start, not an injected stockpile")
	_check(failures, game.ui_layer.find_child("SovereignFocus", true, false) == null, "Sovereign HUD button is absent from production UI")

	var first_road: Vector2i = fixture._best_road_extension(simulation, simulation.town_hall_position + Vector2i(5, 6))
	var road_result: Dictionary = simulation.request_build(Defs.BUILDING_ROAD, first_road)
	var first_road_id := int(Dictionary(road_result.get("building", {})).get("id", 0))
	_check(failures, bool(road_result.get("success", false)) and fixture._advance_until_complete(simulation, first_road_id, 800), "2. place the first road through authoritative construction")
	fixture._build_road_spine(simulation, 20)
	_check(failures, fixture.report.is_empty(), "2. extend several roads around the Town Hall")
	print("P32_PLAY 02 roads=%d" % _road_count(simulation))

	var hall: Dictionary = simulation._find_town_hall()
	var hall_access: Array[Vector2i] = simulation.get_building_road_access_candidates(hall)
	var access_has_road := false
	for tile in hall_access:
		var occupant: Dictionary = simulation.get_building_at_tile(tile)
		access_has_road = access_has_road or (not occupant.is_empty() and String(occupant.get("type", "")) == Defs.BUILDING_ROAD)
	_check(failures, not hall_access.is_empty() and access_has_road, "3. roads connect onto explicit Town Hall access cells beside the entrance")
	var blocked: Dictionary = simulation.validate_road_route([Vector2i(hall.get("position", Vector2i.ZERO))])
	_check(failures, String(blocked.get("message", "")) == "Building occupies this tile", "3. a blocked preview names the building footprint instead of a vague halo")

	var lumber_id := _build_real(failures, fixture, simulation, Defs.BUILDING_LUMBER_CAMP, simulation.town_hall_position + Vector2i(9, 6))
	_check(failures, lumber_id > 0 and _wait_for_output(simulation, lumber_id, Defs.RESOURCE_WOOD, 1800), "4. build a Lumber Camp and observe real Wood production")
	game._initialize_presentation()
	await process_frame
	_check(failures, _worker_uses_lumber_socket(simulation, lumber_id), "5. a working lumber character stands on a building socket, not the road access tile")
	print("P32_PLAY 05 lumber socket ok id=%d" % lumber_id)

	var trees_before: Dictionary = simulation.tree_deposits.duplicate()
	_wait_for_tree_clearing(simulation, 8000)
	game.world_view._sync_nature(true)
	var stump_count := _count_nature_kind(game, "STUMP")
	var trees_reduced := _deposit_total(simulation.tree_deposits) < _deposit_total(trees_before)
	_check(failures, trees_reduced and stump_count > 0, "6. harvesting opens a visible clearing with deterministic stump markers")
	print("P32_PLAY 06 stumps=%d trees_reduced=%s" % [stump_count, trees_reduced])

	var house_id := _build_real(failures, fixture, simulation, Defs.BUILDING_HOUSE, simulation.town_hall_position + Vector2i(5, 5))
	var quarry_id := _build_real(failures, fixture, simulation, Defs.BUILDING_QUARRY, simulation.town_hall_position + Vector2i(10, 4))
	var rocks_before: Dictionary = simulation.rock_deposits.duplicate()
	_check(failures, quarry_id > 0 and _wait_for_output(simulation, quarry_id, Defs.RESOURCE_STONE, 2200), "7. harvest Stone through a real Quarry")
	game.world_view._sync_nature(true)
	var stone_reduced := _deposit_total(simulation.rock_deposits) < _deposit_total(rocks_before)
	_check(failures, stone_reduced, "7. the stone deposit visually/authoritatively declines")
	print("P32_PLAY 07 stone_reduced=%s house=%d" % [stone_reduced, house_id])

	var farm_id := _build_real(failures, fixture, simulation, Defs.BUILDING_FARM, simulation.town_hall_position + Vector2i(7, 10))
	var bakery_id := _build_real(failures, fixture, simulation, Defs.BUILDING_BAKERY, simulation.town_hall_position + Vector2i(11, 9))
	_check(failures, _wait_for_output(simulation, farm_id, Defs.RESOURCE_WHEAT, 2400), "8. Farm produces Wheat")
	_check(failures, _wait_for_output(simulation, bakery_id, Defs.RESOURCE_BREAD, 2600), "8. Bakery converts Wheat into Bread")
	_check(failures, house_id > 0 and _wait_for_population(simulation, 6, 7000), "8. housing and food grow the settlement")

	var tower_id := _build_real(failures, fixture, simulation, Defs.BUILDING_WATCHTOWER, simulation.town_hall_position + Vector2i(8, 7))
	var barracks_id := _build_real(failures, fixture, simulation, Defs.BUILDING_BARRACKS, simulation.town_hall_position + Vector2i(12, 10))
	_check(failures, _wait_for_soldier(simulation, 1800) and int(simulation.get_building_by_id(tower_id).get("soldiers_assigned", 0)) > 0, "defence is staffed before night")
	print("P32_PLAY 08 farm=%d bakery=%d barracks=%d" % [farm_id, bakery_id, barracks_id])

	simulation.is_night = false
	simulation.phase_time = float(simulation.DAY_LENGTH_SECONDS) - 25.0
	game._update_day_night_lighting()
	var dusk_energy: float = game.sun_light.light_energy
	_check(failures, dusk_energy < 1.0 and dusk_energy > 0.08, "9/10. evening lighting sits between day and night")
	print("P32_PLAY 09 dusk sun=%.3f" % dusk_energy)

	_wait_until_night(simulation, 7000)
	game._sync_presentation()
	game._update_day_night_lighting()
	await process_frame
	_check(failures, simulation.is_night and game.sun_light.light_energy <= float(Identity.LIGHTING["day"]["sun_energy"]) * 0.25, "10. night is obviously darker than day without HUD text")
	_check(failures, _occupied_building_lights_on(game), "11. occupied buildings emit warm night lights")
	_check(failures, _night_guard_visible(simulation, game), "12. night guards are alert or on patrol")
	print("P32_PLAY 12 night sun=%.3f lights=%s" % [game.sun_light.light_energy, _occupied_building_lights_on(game)])

	var fog_before: Transform3D = game.world_view.fog_plane.global_transform
	game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(simulation.town_hall_position + Vector2i(8, 0))), 48.0)
	await process_frame
	_check(failures, game.world_view.fog_plane.global_transform.is_equal_approx(fog_before), "FOW stays world-anchored while the camera pans")

	var raid_started: bool = not simulation.enemies.is_empty() or _wait_for_raid(simulation, 14000)
	_check(failures, raid_started, "13. a real raid begins from the day/night simulation")
	var combat: Dictionary = _observe_combat(simulation, 1600)
	_check(failures, int(combat.get("hits", 0)) >= 2, "14. soldier and raider exchange multiple attacks")
	_check(failures, bool(combat.get("projectile", false)) and bool(combat.get("delayed_damage", false)), "15. tower projectile travels and damage lands on impact")
	print("P32_PLAY 15 combat=%s" % combat)

	game._initialize_presentation()
	var saved_tick: int = simulation.get_tick_number()
	var saved_stumps := _count_nature_kind(game, "STUMP")
	var saved_rocks := _deposit_total(simulation.rock_deposits)
	var saved: bool = game.simulation_host.save_to_path(SAVE_PATH)
	game.simulation_host.start_new(19, true)
	var loaded: bool = game.simulation_host.load_from_path(SAVE_PATH)
	game._initialize_presentation()
	game.world_view._sync_nature(true)
	await process_frame
	var resumed = game.simulation_host.simulation
	_check(failures, saved and loaded and resumed.get_tick_number() == saved_tick, "16/17. save, reset, and load the settlement")
	_check(failures, _count_nature_kind(game, "STUMP") == saved_stumps and _deposit_total(resumed.rock_deposits) == saved_rocks, "18. clearing, stone depletion, and presentation reconstruct")
	var claim_requirements: Dictionary = resumed.rivalry.claim_requirements(Tuning.PLAYER_REALM)
	_check(failures, bool(claim_requirements.get("sovereign", false)) and not "Sovereign" in String(claim_requirements.get("summary", "")), "Claims/Wyrd remain settlement Outpost systems after reload")
	var hero_move: Dictionary = resumed.set_player_sovereign_target(Vector2i.ZERO)
	_check(failures, not bool(hero_move.get("success", false)), "player Sovereign control stays removed after load")
	print("P32_PLAY 18 reload tick=%d stumps=%d" % [resumed.get_tick_number(), _count_nature_kind(game, "STUMP")])

	game.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	_finish(failures)


func _worker_uses_lumber_socket(simulation, lumber_id: int) -> bool:
	for worker_value in simulation.workers:
		var worker: Dictionary = worker_value
		if int(worker.get("building_id", 0)) != lumber_id:
			continue
		if String(worker.get("state", "")) not in ["Working", "Carrying", "Harvesting"]:
			worker["state"] = "Working"
			worker["path"] = []
		var presentation: Dictionary = simulation.get_worker_work_presentation(worker)
		if presentation.is_empty():
			continue
		var access: Array[Vector2i] = simulation.get_building_road_access_candidates(simulation.get_building_by_id(lumber_id))
		var on_access := false
		for tile in access:
			on_access = on_access or Vector2(presentation.get("position", Vector2.ZERO)).distance_to(Vector2(tile)) < 0.2
		return not on_access and Vector2(presentation.get("position", Vector2.ZERO)).distance_to(Vector2(worker.get("position", Vector2i.ZERO))) > 0.2
	return false


func _wait_for_tree_clearing(simulation, max_ticks: int) -> void:
	var start_total := _deposit_total(simulation.tree_deposits)
	for _tick in max_ticks:
		simulation.advance_tick()
		if _deposit_total(simulation.tree_deposits) < start_total and _stump_marker_count(simulation) > 0:
			return


func _stump_marker_count(simulation) -> int:
	var count := 0
	for key in simulation.tree_regrowth.keys():
		if float(simulation.tree_regrowth[key]) <= 0.0:
			count += 1
	return count


func _observe_combat(simulation, max_ticks: int) -> Dictionary:
	var hits := 0
	var saw_projectile := false
	var delayed := false
	var last_hp := {}
	for _tick in max_ticks:
		var projectiles_before: int = simulation.projectiles.size()
		var hp_before := {}
		for enemy_value in simulation.enemies:
			var enemy: Dictionary = enemy_value
			hp_before[int(enemy.get("id", 0))] = int(enemy.get("hp", 0))
		simulation.advance_tick()
		if simulation.projectiles.size() > 0:
			saw_projectile = true
		if projectiles_before > 0:
			for enemy_value in simulation.enemies:
				var enemy: Dictionary = enemy_value
				var enemy_id := int(enemy.get("id", 0))
				if int(enemy.get("hp", 0)) < int(hp_before.get(enemy_id, int(enemy.get("hp", 0)))):
					delayed = true
		for enemy_value in simulation.enemies:
			var enemy: Dictionary = enemy_value
			var enemy_id := int(enemy.get("id", 0))
			if int(enemy.get("hp", 0)) < int(last_hp.get(enemy_id, int(enemy.get("hp", 0)) + 1)):
				hits += 1
			last_hp[enemy_id] = int(enemy.get("hp", 0))
		if not simulation.is_night:
			break
	return {"hits": hits, "projectile": saw_projectile, "delayed_damage": delayed or saw_projectile}


func _occupied_building_lights_on(game) -> bool:
	for view in game.world_view.building_views.values():
		if view.window_light != null and view.window_light.visible:
			return true
	return false


func _night_guard_visible(simulation, game) -> bool:
	var alert := false
	for worker_value in simulation.workers:
		var worker: Dictionary = worker_value
		if String(worker.get("type", "")) == "guard" and String(worker.get("state", "")).begins_with("Night"):
			alert = true
	if not alert:
		return false
	for view in game.world_view.character_views.values():
		if view.alert_light != null and view.alert_light.visible:
			return true
	return alert


func _count_nature_kind(game, kind: String) -> int:
	var count := 0
	for key in game.world_view.nature_views.keys():
		if String(game.world_view.nature_views[key]) == kind:
			count += 1
	return count


func _deposit_total(deposits: Dictionary) -> int:
	var total := 0
	for key in deposits.keys():
		total += int(deposits[key])
	return total


func _road_count(simulation) -> int:
	var count := 0
	for building_value in simulation.buildings:
		if String(Dictionary(building_value).get("type", "")) == Defs.BUILDING_ROAD:
			count += 1
	return count


func _build_real(failures: Array[String], fixture, simulation, building_type: String, target: Vector2i) -> int:
	var site: Vector2i = fixture._ensure_site(simulation, building_type, target)
	if site.x < 0:
		failures.append("find a valid %s site" % Defs.building_name(building_type))
		return 0
	var result: Dictionary = simulation.request_build(building_type, site)
	if not bool(result.get("success", false)):
		failures.append("build %s: %s" % [Defs.building_name(building_type), result.get("message", "rejected")])
		return 0
	var id := int(Dictionary(result.get("building", {})).get("id", 0))
	# Building may span the 180-second night plus the 30-second dusk closure.
	# Keep the original 240-second work allowance instead of counting sleep as
	# a construction stall. This does not advance the clock outside normal ticks.
	var wait_ticks := int((240.0 + simulation.NIGHT_LENGTH_SECONDS + 30.0) / simulation.TICK_SECONDS)
	if not fixture._advance_until_complete(simulation, id, wait_ticks):
		failures.append("complete %s" % Defs.building_name(building_type))
	return id


func _wait_for_output(simulation, building_id: int, resource_type: String, max_ticks: int) -> bool:
	if building_id <= 0:
		return false
	var initial_central := int(simulation.central_inventory.get(resource_type, 0))
	for _tick in max_ticks:
		var building: Dictionary = simulation.get_building_by_id(building_id)
		if int(Dictionary(building.get("local_inventory", {})).get(resource_type, 0)) > 0 or int(simulation.central_inventory.get(resource_type, 0)) > initial_central:
			return true
		simulation.advance_tick()
	return false


func _wait_for_soldier(simulation, max_ticks: int) -> bool:
	for _tick in max_ticks:
		if simulation.soldiers_total > 0:
			return true
		simulation.advance_tick()
	return false


func _wait_for_population(simulation, target: int, max_ticks: int) -> bool:
	for _tick in max_ticks:
		if simulation.population_current >= target:
			return true
		simulation.advance_tick()
	return false


func _wait_until_night(simulation, max_ticks: int) -> bool:
	for _tick in max_ticks:
		if simulation.is_night:
			return true
		simulation.advance_tick()
	return simulation.is_night


func _wait_for_raid(simulation, max_ticks: int) -> bool:
	for _tick in max_ticks:
		if not simulation.enemies.is_empty():
			return true
		if simulation.game_finished:
			return false
		simulation.advance_tick()
	return not simulation.enemies.is_empty()


func _starting_resources_match(resources: Dictionary) -> bool:
	for resource_type in Defs.RESOURCE_TYPES:
		if int(resources.get(resource_type, -1)) != int(Defs.STARTING_RESOURCES.get(resource_type, -2)):
			return false
	return true


func _check(failures: Array[String], condition: bool, label: String) -> void:
	print("%s %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		failures.append(label)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("PHASE3_2_REAL_PLAYTHROUGH PASS")
		quit(0)
	else:
		print("PHASE3_2_REAL_PLAYTHROUGH FAIL count=%d" % failures.size())
		for failure in failures:
			print("  - %s" % failure)
		quit(1)
