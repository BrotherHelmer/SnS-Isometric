extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const RivalryTuning = preload("res://src/GodotClient/Scripts/one_shard_rivalry_tuning.gd")

const BASE_SAVE := "res://artifacts/phase3/persistence/real_game_playthrough.json"
const OUTPUT_DIR := "res://artifacts/phase3_1/screenshots"
const CAPTURE_SIZE := Vector2i(1920, 1080)
const CAPTURES := [
	{"stage": "new", "file": "01_new_settlement_default_ui.png"},
	{"stage": "palette", "file": "02_build_palette_open.png"},
	{"stage": "road_preview", "file": "03_road_drag_preview.png"},
	{"stage": "roads", "file": "04_completed_road_network.png"},
	{"stage": "fog_close", "file": "05_fow_boundary_close.png"},
	{"stage": "fog_strategic", "file": "06_fow_strategic.png"},
	{"stage": "worker", "file": "07_worker_inspector.png"},
	{"stage": "building", "file": "08_building_inspector.png"},
	{"stage": "barracks", "file": "09_barracks_and_town_hall.png"},
	{"stage": "raider", "file": "10_raider_approach.png"},
	{"stage": "raid", "file": "11_active_raid.png"},
	{"stage": "civic_center", "file": "12_civic_center_dense_buildings.png"},
]


func _init() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Phase 3.1 captures require a readable Forward+ framebuffer.")
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
		push_error("Run the real Phase 3 playthrough before Phase 3.1 capture.")
		quit(1)
		return
	for capture_value in CAPTURES:
		var capture: Dictionary = capture_value
		var game := Scene.instantiate()
		root.add_child(game)
		await process_frame
		await process_frame
		if String(capture.stage) == "new":
			game.start_new_3d(game.DEFAULT_SEED)
		else:
			if not game.simulation_host.load_from_path(BASE_SAVE):
				push_error("Unable to load Phase 3.1 capture base.")
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
		for _frame in 22:
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
		var metrics: Dictionary = game.world_view.presentation_metrics()
		print("PHASE3_1_CAPTURE_PASS stage=%s path=%s size=%dx%d workers=%d hostiles=%d roads=%d" % [
			capture.stage, absolute_path, image.get_width(), image.get_height(), int(metrics.get("real_workers", 0)),
			int(metrics.get("hostile_views", 0)), int(metrics.get("road_views", 0)),
		])
		root.remove_child(game)
		game.free()
		await process_frame
		await RenderingServer.frame_post_draw
	print("PHASE3_1_CAPTURE_SUITE PASS count=%d" % CAPTURES.size())
	quit(0)


func _configure_stage(game, stage: String) -> void:
	var simulation = game.simulation_host.simulation
	if simulation.is_night:
		simulation._end_night()
	game._set_build_palette_visible(false)
	game.cancel_placement()
	game.selected_building_id = 0
	game.selected_worker_id = 0
	game.selected_entity_kind = ""
	game.world_view.set_selection(0, 0)
	game.world_view.set_claim_overlay_visible(false)
	game.world_view.set_watchtower_overlay(Vector2.ZERO, 0.0, false)
	var town_center := Vector2(simulation.town_hall_position) + Vector2(1.5, 1.5)
	var town_world: Vector3 = game.world_view.tile_to_world(town_center)
	match stage:
		"new":
			game.camera_rig.compose_view(town_world, 34.0)
		"palette":
			game._set_build_palette_visible(true)
			game.camera_rig.compose_view(town_world, 36.0)
		"road_preview":
			var route := _find_valid_road_route(simulation)
			game.begin_placement(Defs.BUILDING_ROAD)
			game.road_dragging = true
			game.road_drag_start = route.front() if not route.is_empty() else simulation._town_hall_entrance_tile()
			game.road_preview_route = route
			game.road_preview_validation = simulation.validate_road_route(route)
			game.world_view.show_road_preview(game.road_preview_validation.get("segments", []))
			game.placement_label.text = "ROAD MODE  ·  Release to plan %d road sections" % route.size()
			var midpoint := (Vector2(route.front()) + Vector2(route.back())) * 0.5 if not route.is_empty() else town_center
			game.camera_rig.compose_view(game.world_view.tile_to_world(midpoint), 25.0)
		"roads":
			game.camera_rig.compose_view(town_world, 33.0)
		"fog_close":
			var boundary := _find_reveal_boundary(simulation)
			game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(boundary)), 23.0)
		"fog_strategic":
			var boundary := _find_reveal_boundary(simulation)
			game.camera_rig.compose_view(game.world_view.tile_to_world((Vector2(boundary) + town_center) * 0.5), 56.0)
		"worker":
			var worker := _first_visible_worker(simulation)
			game.select_worker(int(worker.get("id", 0)))
			game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(worker.get("position", simulation.town_hall_position))), 24.0)
		"building":
			var bakery := _find_building(simulation, Defs.BUILDING_BAKERY)
			game.select_building(int(bakery.get("id", 0)))
			game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(bakery.get("position", simulation.town_hall_position))), 25.0)
		"barracks":
			var barracks := _find_building(simulation, Defs.BUILDING_BARRACKS)
			var town_hall := _find_building(simulation, Defs.BUILDING_TOWN_HALL)
			game.select_building(int(barracks.get("id", 0)))
			var midpoint := (Vector2(barracks.get("position", simulation.town_hall_position)) + Vector2(town_hall.get("position", simulation.town_hall_position))) * 0.5
			game.camera_rig.compose_view(game.world_view.tile_to_world(midpoint), 38.0)
		"raider":
			var origin := _spawn_hostile_group(simulation, 6, 9)
			game.camera_rig.compose_view(game.world_view.tile_to_world((Vector2(origin) + town_center) * 0.5), 29.0)
		"raid":
			var origin := _spawn_hostile_group(simulation, 7, 5)
			if not simulation.enemies.is_empty():
				var enemy: Dictionary = simulation.enemies[0]
				enemy["attack_flash"] = simulation.ENEMY_ATTACK_ANIMATION_SECONDS
				enemy["hit_until"] = simulation.elapsed_seconds + 0.45
			var tower := _find_building(simulation, Defs.BUILDING_WATCHTOWER)
			if not tower.is_empty():
				tower["soldiers_assigned"] = 1
				tower["staffed"] = true
				tower["attack_cooldown"] = 0.0
				simulation._update_towers(0.2)
			game._show_status("Raiders have reached the settlement!", 20.0)
			game.camera_rig.compose_view(game.world_view.tile_to_world((Vector2(origin) + town_center) * 0.5), 25.0)
		"civic_center":
			game._sync_presentation()
			game.camera_rig.compose_view(game.world_view.tile_to_world(simulation.get_building_center(simulation._find_town_hall())), 23.0)


func _find_valid_road_route(simulation) -> Array[Vector2i]:
	for building_value in simulation.buildings:
		var building: Dictionary = building_value
		if String(building.get("type", "")) != Defs.BUILDING_ROAD or bool(building.get("construction", false)):
			continue
		var start := Vector2i(building.get("position", Vector2i.ZERO))
		for direction in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var route: Array[Vector2i] = [start]
			for distance in range(1, 7):
				route.append(start + direction * distance)
			var validation: Dictionary = simulation.validate_road_route(route)
			var new_count := 0
			for segment_value in validation.get("segments", []):
				if not bool(Dictionary(segment_value).get("reuse", false)):
					new_count += 1
			if bool(validation.get("success", false)) and new_count >= 3:
				return route
	return [simulation._town_hall_entrance_tile()]


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


func _spawn_hostile_group(simulation, count: int, distance: int) -> Vector2i:
	var center := Vector2i(simulation.town_hall_position) + Vector2i(2, 2)
	var origin := _find_hostile_origin(simulation, center, distance)
	for index in count:
		var tile := origin + Vector2i(index % 3, index / 3)
		simulation._prepare_test_tile(tile, Defs.TILE_GRASS)
		var enemy_type: String = simulation.ENEMY_RAIDER if index < count - 2 else (simulation.ENEMY_BRUTE if index == count - 2 else simulation.ENEMY_HEXER)
		simulation._spawn_enemy(tile, 80 + index * 8, 7, -0.03 * index, 0, enemy_type)
		var enemy: Dictionary = simulation.enemies.back()
		enemy["path"] = simulation._find_enemy_path(tile, center)
		simulation._reveal_radius(tile, 5)
	return origin


func _find_hostile_origin(simulation, center: Vector2i, preferred_distance: int) -> Vector2i:
	for radius in range(preferred_distance, preferred_distance + 8):
		for offset in [Vector2i(radius, 0), Vector2i(-radius, 0), Vector2i(0, radius), Vector2i(0, -radius)]:
			var candidate: Vector2i = center + offset
			var clear := true
			for y in range(0, 3):
				for x in range(0, 3):
					var tile: Vector2i = candidate + Vector2i(x, y)
					if not simulation.is_inside_map(tile) or not simulation.get_building_at_tile(tile).is_empty():
						clear = false
			if clear:
				return candidate
	return simulation.nearest_sovereign_walkable(center + Vector2i(preferred_distance, 0))


func _nearest_dense_safe_tile(simulation) -> Vector2i:
	var center := Vector2i(simulation.town_hall_position) + Vector2i(2, 2)
	for radius in range(1, 9):
		for y in range(center.y - radius, center.y + radius + 1):
			for x in range(center.x - radius, center.x + radius + 1):
				var tile := Vector2i(x, y)
				if simulation.is_sovereign_walkable(tile):
					return tile
	return simulation.nearest_sovereign_walkable(center)


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
