extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")

const BASE_SAVE := "res://artifacts/phase3/persistence/real_game_playthrough.json"
const OUTPUT_DIR := "res://artifacts/phase3_2/screenshots"
const RELOAD_FIXTURE := "res://artifacts/phase3_2/capture_reload.json"
const CAPTURE_SIZE := Vector2i(1920, 1080)
const CAPTURES := [
	{"stage": "day", "file": "01_daytime_new_settlement.png"},
	{"stage": "fog_close", "file": "02_aligned_fow_edge.png"},
	{"stage": "fog_strategic", "file": "03_strategic_fow_view.png"},
	{"stage": "town_hall", "file": "04_town_hall_beside_houses.png"},
	{"stage": "roads", "file": "05_roads_tight_to_buildings.png"},
	{"stage": "forest", "file": "06_freshly_cleared_forest.png"},
	{"stage": "stone", "file": "07_partially_depleted_stone.png"},
	{"stage": "lumber_work", "file": "08_worker_at_lumber_camp.png"},
	{"stage": "production_work", "file": "09_worker_at_production_yard.png"},
	{"stage": "dusk", "file": "10_dusk_transition.png"},
	{"stage": "night", "file": "11_night_lit_settlement.png"},
	{"stage": "night_guards", "file": "12_night_guards.png"},
	{"stage": "melee", "file": "13_soldier_vs_raider.png"},
	{"stage": "tower", "file": "14_tower_engagement.png"},
	{"stage": "reloaded", "file": "15_post_harvest_reloaded.png"},
]


func _init() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Phase 3.2 captures require a readable Forward+ framebuffer.")
		quit(1)
		return
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	call_deferred("_run")


func _run() -> void:
	root.size = CAPTURE_SIZE
	DisplayServer.window_set_size(CAPTURE_SIZE)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	if not FileAccess.file_exists(BASE_SAVE):
		push_error("Run the real Phase 3 playthrough before Phase 3.2 capture.")
		quit(1)
		return
	for capture_value in CAPTURES:
		var capture: Dictionary = capture_value
		var game := Scene.instantiate()
		root.add_child(game)
		await process_frame
		await process_frame
		if String(capture.stage) == "day":
			game.start_new_3d(game.DEFAULT_SEED)
		else:
			if not game.simulation_host.load_from_path(BASE_SAVE):
				push_error("Unable to load Phase 3.2 capture base.")
				quit(1)
				return
			game._hide_start_menu()
			game._initialize_presentation()
		game.simulation_host.paused = true
		game.world_view.set_presentation_paused(true)
		game.ui_layer.visible = true
		_configure_stage(game, String(capture.stage))
		game._sync_presentation()
		game._update_ui()
		game._update_day_night_lighting()
		for _frame in 24:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var path := "%s/%s" % [OUTPUT_DIR, String(capture.file)]
		var absolute_path := ProjectSettings.globalize_path(path)
		var result := image.save_png(absolute_path)
		if result != OK or image.get_width() != 1920 or image.get_height() != 1080:
			push_error("Capture failed or wrong size: %s (%dx%d)" % [absolute_path, image.get_width(), image.get_height()])
			quit(1)
			return
		print("PHASE3_2_CAPTURE_PASS stage=%s path=%s size=%dx%d" % [
			capture.stage, absolute_path, image.get_width(), image.get_height(),
		])
		root.remove_child(game)
		game.free()
		await process_frame
		await RenderingServer.frame_post_draw
	print("PHASE3_2_CAPTURE_SUITE PASS count=%d" % CAPTURES.size())
	quit(0)


func _configure_stage(game, stage: String) -> void:
	var simulation = game.simulation_host.simulation
	game._set_build_palette_visible(false)
	game.cancel_placement()
	game.selected_building_id = 0
	game.selected_worker_id = 0
	game.selected_entity_kind = ""
	game.world_view.set_selection(0, 0)
	if stage not in ["dusk", "night", "night_guards", "melee", "tower"]:
		if simulation.is_night:
			simulation._end_night()
		simulation.is_night = false
		simulation.phase_time = 140.0
	var town_hall: Dictionary = simulation._find_town_hall()
	var town_center: Vector2 = simulation.get_building_center(town_hall)
	match stage:
		"day":
			game.camera_rig.compose_view(game.world_view.tile_to_world(town_center), 34.0)
		"fog_close":
			var boundary := _find_reveal_boundary(simulation)
			game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(boundary)), 22.0)
		"fog_strategic":
			var boundary := _find_reveal_boundary(simulation)
			game.camera_rig.compose_view(game.world_view.tile_to_world((Vector2(boundary) + town_center) * 0.5), 54.0)
		"town_hall":
			game.camera_rig.compose_view(game.world_view.tile_to_world(town_center), 24.0)
		"roads":
			game.camera_rig.compose_view(game.world_view.tile_to_world(town_center + Vector2(3.0, 2.0)), 28.0)
		"forest":
			var focus := _make_forest_clearing(simulation)
			game.world_view._sync_nature(true)
			game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(focus)), 18.0)
		"stone":
			var focus := _make_stone_clearing(simulation)
			game.world_view._sync_nature(true)
			game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(focus)), 22.0)
		"lumber_work":
			var focus := _pose_worker_at_building(simulation, [Defs.BUILDING_LUMBER_CAMP, Defs.BUILDING_SAWMILL], "Working")
			game.camera_rig.compose_view(game.world_view.tile_to_world(focus), 20.0)
		"production_work":
			var focus := _pose_worker_at_building(simulation, [Defs.BUILDING_FARM, Defs.BUILDING_BAKERY, Defs.BUILDING_QUARRY], "Working")
			game.camera_rig.compose_view(game.world_view.tile_to_world(focus), 20.0)
		"dusk":
			if simulation.is_night:
				simulation._end_night()
			simulation.is_night = false
			simulation.phase_time = simulation.DAY_LENGTH_SECONDS - 12.0
			game.camera_rig.compose_view(game.world_view.tile_to_world(town_center), 30.0)
		"night":
			_make_night(simulation)
			game.camera_rig.compose_view(game.world_view.tile_to_world(town_center), 29.0)
		"night_guards":
			_make_night(simulation)
			var focus := _pose_night_guard(simulation)
			game.camera_rig.compose_view(game.world_view.tile_to_world(focus), 20.0)
		"melee":
			_make_night(simulation)
			var focus := _pose_melee_exchange(simulation)
			game.camera_rig.compose_view(game.world_view.tile_to_world(focus), 18.0)
		"tower":
			_make_night(simulation)
			var focus := _pose_tower_engagement(simulation)
			game.camera_rig.compose_view(game.world_view.tile_to_world(focus), 21.0)
		"reloaded":
			var focus := _make_forest_clearing(simulation)
			_make_stone_clearing(simulation)
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RELOAD_FIXTURE.get_base_dir()))
			if not simulation.save_to_path(RELOAD_FIXTURE) or not game.simulation_host.load_from_path(RELOAD_FIXTURE):
				push_error("Phase 3.2 capture reload fixture failed.")
				return
			game._initialize_presentation()
			game.simulation_host.paused = true
			game.world_view.set_presentation_paused(true)
			game.world_view._sync_nature(true)
			game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(focus)), 29.0)


func _make_night(simulation) -> void:
	simulation.is_night = true
	simulation.phase_time = 75.0
	for worker_value in simulation.workers:
		var worker: Dictionary = worker_value
		if String(worker.get("type", "")) == "guard":
			worker["state"] = "Night Watch"
			worker["path"] = []


func _make_forest_clearing(simulation) -> Vector2i:
	var town := Vector2(simulation.town_hall_position)
	var focus := Vector2i(simulation.town_hall_position) + Vector2i(2, 2)
	var best_score := 1000000.0
	for key_value in simulation.tree_deposits.keys():
		var tile: Vector2i = simulation._tile_from_key(String(key_value))
		if not simulation.is_revealed(tile):
			continue
		var score := Vector2(tile).distance_to(town)
		if score < best_score:
			best_score = score
			focus = tile
	var harvested := 0
	for key_value in simulation.tree_deposits.keys():
		var tile: Vector2i = simulation._tile_from_key(String(key_value))
		if Vector2(tile).distance_to(Vector2(focus)) <= 5.0:
			simulation._consume_deposit(tile, int(simulation.tree_deposits.get(String(key_value), 0)))
			simulation._reveal_radius(tile, 3)
			harvested += 1
			if harvested >= 16:
				break
	return focus


func _make_stone_clearing(simulation) -> Vector2i:
	var town := Vector2(simulation.town_hall_position)
	var focus := Vector2i(simulation.town_hall_position) + Vector2i(2, 2)
	var best_score := 1000000.0
	for key_value in simulation.rock_deposits.keys():
		var tile: Vector2i = simulation._tile_from_key(String(key_value))
		if not simulation.is_revealed(tile):
			continue
		var score := Vector2(tile).distance_to(town)
		if score < best_score:
			best_score = score
			focus = tile
	var changed := 0
	for key_value in simulation.rock_deposits.keys():
		var tile: Vector2i = simulation._tile_from_key(String(key_value))
		if Vector2(tile).distance_to(Vector2(focus)) > 4.0:
			continue
		var available := int(simulation.rock_deposits.get(String(key_value), 0))
		var amount := available if changed > 0 else maxi(1, available - 6)
		simulation._consume_deposit(tile, amount)
		simulation._reveal_radius(tile, 3)
		changed += 1
		if changed >= 4:
			break
	return focus


func _pose_worker_at_building(simulation, building_types: Array, state: String) -> Vector2:
	var building := {}
	for type_name in building_types:
		building = _find_building(simulation, String(type_name))
		if not building.is_empty():
			break
	if building.is_empty():
		return simulation.get_building_center(simulation._find_town_hall())
	var worker := _first_visible_worker(simulation)
	if worker.is_empty():
		return simulation.get_building_center(building)
	var access: Array[Vector2i] = simulation.get_building_road_access_candidates(building)
	worker["building_id"] = int(building.get("id", 0))
	worker["position"] = access[0] if not access.is_empty() else Vector2i(building.get("position", Vector2i.ZERO))
	worker["path"] = []
	worker["state"] = state
	worker["slot"] = 1
	return simulation.get_building_center(building)


func _pose_night_guard(simulation) -> Vector2:
	var tower := _find_building(simulation, Defs.BUILDING_WATCHTOWER)
	var guard := {}
	for worker_value in simulation.workers:
		if String(Dictionary(worker_value).get("type", "")) == "guard":
			guard = worker_value
			break
	if guard.is_empty() or tower.is_empty():
		return simulation.get_building_center(simulation._find_town_hall())
	guard["building_id"] = int(tower.get("id", 0))
	guard["state"] = "Night Watch"
	guard["path"] = []
	guard["slot"] = 0
	return simulation.get_building_center(tower)


func _pose_melee_exchange(simulation) -> Vector2:
	var guard := {}
	for worker_value in simulation.workers:
		if String(Dictionary(worker_value).get("type", "")) == "guard":
			guard = worker_value
			break
	var town_center: Vector2 = simulation.get_building_center(simulation._find_town_hall())
	var origin := _find_hostile_origin(simulation, Vector2i(town_center), 5)
	simulation._prepare_test_tile(origin, Defs.TILE_GRASS)
	simulation._spawn_enemy(origin, 18, 5, 0.0, 0, simulation.ENEMY_RAIDER)
	var enemy: Dictionary = simulation.enemies.back()
	enemy["hit_until"] = simulation.elapsed_seconds + 0.35
	if not guard.is_empty():
		guard["position"] = origin + Vector2i.LEFT
		guard["path"] = []
		guard["state"] = "Fighting"
		guard["attack_flash"] = simulation.GUARD_ATTACK_ANIMATION_SECONDS
	simulation._reveal_radius(origin, 5)
	return (Vector2(origin) + Vector2(origin + Vector2i.LEFT)) * 0.5


func _pose_tower_engagement(simulation) -> Vector2:
	var tower := _find_building(simulation, Defs.BUILDING_WATCHTOWER)
	if tower.is_empty():
		return simulation.get_building_center(simulation._find_town_hall())
	tower["soldiers_assigned"] = maxi(1, int(tower.get("soldiers_assigned", 0)))
	tower["attack_cooldown"] = 0.0
	var center := Vector2i(simulation.get_building_center(tower))
	var origin := center + Vector2i(6, 0)
	simulation._prepare_test_tile(origin, Defs.TILE_GRASS)
	simulation._spawn_enemy(origin, 18, 5, 0.0, 0, simulation.ENEMY_RAIDER)
	simulation._reveal_radius(origin, 5)
	simulation._update_towers(0.2)
	return (Vector2(center) + Vector2(origin)) * 0.5


func _find_reveal_boundary(simulation) -> Vector2i:
	for y in range(2, simulation.map_size.y - 2):
		for x in range(2, simulation.map_size.x - 2):
			var tile := Vector2i(x, y)
			if not simulation.is_revealed(tile):
				continue
			for neighbor in simulation._neighbors(tile):
				if simulation.is_inside_map(neighbor) and not simulation.is_revealed(neighbor):
					return tile
	return simulation.town_hall_position


func _find_hostile_origin(simulation, center: Vector2i, preferred_distance: int) -> Vector2i:
	for radius in range(preferred_distance, preferred_distance + 8):
		for offset in [Vector2i(radius, 0), Vector2i(-radius, 0), Vector2i(0, radius), Vector2i(0, -radius)]:
			var candidate: Vector2i = center + offset
			if simulation.is_inside_map(candidate) and simulation.get_building_at_tile(candidate).is_empty():
				return candidate
	return center + Vector2i(preferred_distance, 0)


func _first_visible_worker(simulation) -> Dictionary:
	for worker_value in simulation.workers:
		var worker: Dictionary = worker_value
		if not bool(worker.get("sheltered", false)):
			return worker
	return simulation.workers[0] if not simulation.workers.is_empty() else {}


func _find_building(simulation, building_type: String) -> Dictionary:
	for building_value in simulation.buildings:
		var building: Dictionary = building_value
		if String(building.get("type", "")) == building_type and not bool(building.get("construction", false)):
			return building
	return {}
