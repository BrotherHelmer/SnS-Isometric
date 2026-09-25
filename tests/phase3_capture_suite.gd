extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Fixture = preload("res://src/GodotClient3D/Scripts/production_demo_fixture.gd")

const BASE_SAVE := "res://artifacts/phase3/persistence/real_game_playthrough.json"
const OUTPUT_DIR := "res://artifacts/phase3/screenshots"
const CAPTURE_SIZE := Vector2i(1920, 1080)

const CAPTURES := [
	{"stage": "day", "file": "01_developed_daytime_settlement.png"},
	{"stage": "night", "file": "02_night_shelter.png"},
	{"stage": "food", "file": "03_food_housing_economy.png"},
	{"stage": "rival", "file": "04_rival_territory_scouting.png"},
	{"stage": "defense", "file": "05_defensive_settlement.png"},
	{"stage": "raid", "file": "06_raid_approaching.png"},
	{"stage": "combat", "file": "07_active_melee_ranged_combat.png"},
	{"stage": "tower", "file": "08_tower_projectile_engagement.png"},
	{"stage": "post_raid", "file": "09_post_raid_settlement.png"},
	{"stage": "ui", "file": "10_playtest_ui_build_menu.png"},
	{"stage": "reload", "file": "11_save_load_reconstructed.png"},
	{"stage": "stress", "file": "12_stress_200_inhabitants.png"},
]


func _init() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Phase 3 captures require a readable Forward+ framebuffer.")
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
		push_error("Run phase3_real_game_playthrough.gd before capture; real-game save is missing.")
		quit(1)
		return
	for capture_value in CAPTURES:
		var capture: Dictionary = capture_value
		var game := Scene.instantiate()
		root.add_child(game)
		await process_frame
		await process_frame
		if not game.simulation_host.load_from_path(BASE_SAVE):
			push_error("Unable to load real-game capture base: %s" % BASE_SAVE)
			quit(1)
			return
		game._hide_start_menu()
		game.simulation_host.paused = true
		game._initialize_presentation()
		_configure_stage(game, String(capture["stage"]))
		game._hide_start_menu()
		game._sync_presentation()
		game._update_ui()
		game._update_day_night_lighting()
		for _frame in 18:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var path := "%s/%s" % [OUTPUT_DIR, String(capture["file"])]
		var absolute_path := ProjectSettings.globalize_path(path)
		var result := image.save_png(absolute_path)
		if result != OK or image.get_width() != 1920 or image.get_height() != 1080:
			push_error("Capture failed or wrong size: %s (%dx%d)" % [absolute_path, image.get_width(), image.get_height()])
			quit(1)
			return
		var metrics: Dictionary = game.world_view.presentation_metrics()
		print("PHASE3_CAPTURE_PASS stage=%s path=%s size=%dx%d workers=%d combatants=%d buildings=%d" % [
			capture["stage"], absolute_path, image.get_width(), image.get_height(),
			int(metrics.get("real_workers", 0)), int(metrics.get("combatant_views", 0)), int(metrics.get("building_views", 0)),
		])
		game.queue_free()
		await process_frame
	print("PHASE3_CAPTURE_SUITE PASS count=%d" % CAPTURES.size())
	quit(0)


func _configure_stage(game, stage: String) -> void:
	var simulation = game.simulation_host.simulation
	if simulation.is_night:
		simulation._end_night()
	game.ui_layer.visible = stage in ["food", "defense", "raid", "combat", "tower", "post_raid", "ui", "reload"]
	var town_focus: Vector3 = game.world_view.tile_to_world(Vector2(simulation.town_hall_position) + Vector2(1.5, 1.5))
	match stage:
		"day":
			game.camera_rig.compose_view(town_focus, 42.0)
		"night":
			simulation._start_night()
			for _tick in 260:
				simulation.advance_tick()
			game.camera_rig.compose_view(town_focus, 38.0)
		"food":
			var bakery := _find_building(simulation, Defs.BUILDING_BAKERY)
			game.select_building(int(bakery.get("id", 0)))
			game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(bakery.get("position", simulation.town_hall_position))), 29.0)
		"rival":
			simulation._reveal_radius(simulation.rival_town_hall_position, 14)
			game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(simulation.rival_town_hall_position) + Vector2(1.5, 1.5)), 34.0)
		"defense":
			_create_gate_and_walls(simulation)
			var tower := _find_building(simulation, Defs.BUILDING_WATCHTOWER)
			game.select_building(int(tower.get("id", 0)))
			game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(tower.get("position", simulation.town_hall_position))), 29.0)
		"raid":
			simulation._start_night()
			if simulation.enemies.is_empty():
				simulation._spawn_wave()
			var raid_focus: Vector3 = town_focus
			if not simulation.enemies.is_empty():
				var enemy: Dictionary = simulation.enemies[0]
				simulation._reveal_radius(Vector2i(enemy.get("position", simulation.town_hall_position)), 5)
				raid_focus = game.world_view.tile_to_world((Vector2(enemy.get("position", simulation.town_hall_position)) + Vector2(simulation.town_hall_position)) * 0.5)
			game.camera_rig.compose_view(raid_focus, 38.0)
		"combat":
			var tower := _find_building(simulation, Defs.BUILDING_WATCHTOWER)
			var tower_tile: Vector2i = tower.get("position", simulation.town_hall_position)
			_spawn_combat_group(simulation, tower_tile + Vector2i(5, 0))
			for _tick in 14:
				simulation.advance_tick()
			game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(tower_tile + Vector2i(2, 0))), 25.0)
		"tower":
			var tower := _find_building(simulation, Defs.BUILDING_WATCHTOWER)
			var tower_tile: Vector2i = tower.get("position", simulation.town_hall_position)
			_spawn_combat_group(simulation, tower_tile + Vector2i(5, 0))
			tower["attack_cooldown"] = 0.0
			simulation._update_towers(0.2)
			game.select_building(int(tower.get("id", 0)))
			game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(tower_tile + Vector2i(2, 0))), 23.0)
		"post_raid":
			game.camera_rig.compose_view(town_focus, 39.0)
		"ui":
			var fixture := Fixture.new()
			var candidate: Vector2i = fixture._ensure_site(simulation, Defs.BUILDING_HOUSE, simulation.town_hall_position + Vector2i(14, 11))
			game.preview_placement_at(Defs.BUILDING_HOUSE, candidate)
			game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(candidate)), 31.0)
		"reload":
			var storehouse := _find_building(simulation, Defs.BUILDING_STOREHOUSE)
			var selected := storehouse if not storehouse.is_empty() else _find_building(simulation, Defs.BUILDING_TOWN_HALL)
			game.select_building(int(selected.get("id", 0)))
			game._show_status("Settlement loaded · Save schema v7", 20.0)
			game.camera_rig.compose_view(town_focus, 36.0)
		"stress":
			_scale_population(simulation, 200)
			game.camera_rig.compose_view(town_focus, 48.0)


func _find_building(simulation, building_type: String) -> Dictionary:
	for building_value in simulation.buildings:
		var building: Dictionary = building_value
		if String(building.get("type", "")) == building_type and not bool(building.get("construction", false)):
			return building
	return {}


func _spawn_combat_group(simulation, origin: Vector2i) -> void:
	for index in 4:
		var tile := origin + Vector2i(index % 2, index / 2)
		simulation._prepare_test_tile(tile, Defs.TILE_GRASS)
		simulation._spawn_enemy(tile, 55 + index * 8, 7, -0.03 * index, 0, simulation.ENEMY_HEXER if index == 0 else simulation.ENEMY_RAIDER)
		simulation._reveal_radius(tile, 5)
	var enemy: Dictionary = simulation.enemies.back()
	enemy["attack_flash"] = simulation.ENEMY_ATTACK_ANIMATION_SECONDS
	enemy["hit_until"] = simulation.elapsed_seconds + 0.5


func _create_gate_and_walls(simulation) -> void:
	for road_value in simulation.buildings:
		var road: Dictionary = road_value
		if String(road.get("type", "")) != Defs.BUILDING_ROAD or bool(road.get("construction", false)):
			continue
		var tile: Vector2i = road.get("position", Vector2i.ZERO)
		for pair in [[Vector2i.LEFT, Vector2i.RIGHT], [Vector2i.UP, Vector2i.DOWN]]:
			var first: Vector2i = tile + pair[0]
			var second: Vector2i = tile + pair[1]
			if not simulation.is_inside_map(first) or not simulation.is_inside_map(second):
				continue
			if not simulation.get_building_at_tile(first).is_empty() or not simulation.get_building_at_tile(second).is_empty():
				continue
			simulation._prepare_test_tile(first, Defs.TILE_GRASS)
			simulation._prepare_test_tile(second, Defs.TILE_GRASS)
			simulation._add_completed_building(Defs.BUILDING_WALL, first)
			simulation._add_completed_building(Defs.BUILDING_WALL, second)
			simulation._rebuild_occupied_tiles()
			simulation._recompute_road_network()
			return


func _scale_population(simulation, target: int) -> void:
	var templates: Array[Dictionary] = []
	for worker_value in simulation.workers:
		var worker: Dictionary = worker_value
		if String(worker.get("type", "")) != "carrier":
			templates.append(worker.duplicate(true))
	if templates.is_empty():
		return
	simulation.population_current = target
	simulation.housing_capacity = target
	simulation._ensure_carriers()
	var center := Vector2i(simulation.town_hall_position) + Vector2i(1, 1)
	while simulation.workers.size() < target:
		var index: int = simulation.workers.size()
		var worker: Dictionary = templates[index % templates.size()].duplicate(true)
		worker["id"] = simulation.next_worker_id
		worker["position"] = Vector2i(clampi(center.x + index % 20 - 10, 1, simulation.map_size.x - 2), clampi(center.y + (index / 20) % 12 - 6, 1, simulation.map_size.y - 2))
		worker["path"] = []
		worker["state"] = ["Working", "Hauling", "Patrolling", "Walking"][index % 4]
		worker["move_elapsed"] = 0.0
		worker["carried_resource"] = ""
		worker["carried_amount"] = 0
		simulation.workers.append(worker)
		simulation.next_worker_id += 1
