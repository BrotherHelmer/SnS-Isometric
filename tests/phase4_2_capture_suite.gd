extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const DemoFixture = preload("res://src/GodotClient3D/Scripts/production_demo_fixture.gd")

const OUTPUT_DIR := "res://artifacts/phase4_2/screenshots"
const CAPTURE_SIZE := Vector2i(1920, 1080)
const CAPTURES := [
	{"stage": "starting_clearing", "file": "01_starting_clearing.png"},
	{"stage": "preview_trees", "file": "02_preview_clearing_required.png"},
	{"stage": "site_clearing", "file": "03_site_being_cleared.png"},
	{"stage": "cleared_complete", "file": "04_completed_on_forest.png"},
	{"stage": "storage_storehouse", "file": "05_full_storage_storehouse.png"},
	{"stage": "objective_reach", "file": "06_objective_reach_the_shard.png"},
	{"stage": "frontier", "file": "07_outpost_frontier.png"},
	{"stage": "tower_guard", "file": "08_watchtower_guard.png"},
	{"stage": "night2_approach", "file": "09_night2_raid_approach.png"},
	{"stage": "night2_contact", "file": "10_night2_contact.png"},
	{"stage": "melee", "file": "11_small_melee.png"},
	{"stage": "post_raid", "file": "12_post_raid_settlement.png"}
]


func _init() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Phase 4.2 captures require a windowed framebuffer.")
		quit(1)
		return
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	call_deferred("_run")


func _run() -> void:
	root.size = CAPTURE_SIZE
	DisplayServer.window_set_size(CAPTURE_SIZE)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for capture_value in CAPTURES:
		var capture: Dictionary = capture_value
		var game := Scene.instantiate()
		root.add_child(game)
		await process_frame
		await process_frame
		_configure_stage(game, String(capture.stage))
		game._sync_presentation()
		game._update_ui()
		game._update_day_night_lighting()
		for _frame in 16:
			await process_frame
		await RenderingServer.frame_post_draw
		_save_capture(String(capture.stage), String(capture.file), Engine.get_frames_per_second())
		game.queue_free()
		await process_frame
	print("PHASE42_CAPTURE_SUITE PASS count=12")
	quit(0)


func _save_capture(stage: String, file_name: String, fps: float) -> void:
	var image := root.get_texture().get_image()
	var path := "%s/%s" % [OUTPUT_DIR, file_name]
	var absolute_path := ProjectSettings.globalize_path(path)
	var result := image.save_png(absolute_path)
	if result != OK or image.get_width() != 1920 or image.get_height() != 1080:
		push_error("Capture failed: %s (%dx%d)" % [absolute_path, image.get_width(), image.get_height()])
		quit(1)
		return
	print("PHASE42_CAPTURE_PASS stage=%s fps=%.1f path=%s" % [stage, fps, absolute_path])


func _configure_stage(game, stage: String) -> void:
	game.start_new_3d(game.DEFAULT_SEED)
	var simulation = game.simulation_host.simulation
	game.simulation_host.paused = true
	game.world_view.set_presentation_paused(true)
	match stage:
		"starting_clearing":
			_focus_town(game, 32.0)
		"preview_trees":
			var house: Vector2i = _forested_house_tile(simulation)
			_paint_trees(simulation, house, Vector2i(2, 2))
			simulation.validate_placement(Defs.BUILDING_HOUSE, house)
			game.placement_type = Defs.BUILDING_HOUSE
			game.placement_tile = house
			game.placement_validation = simulation.validate_placement(Defs.BUILDING_HOUSE, house)
			if game.placement_label != null:
				game.placement_label.text = "CLEARING REQUIRED · %s" % String(game.placement_validation.get("message", ""))
			if game.placement_ghost != null:
				game.placement_ghost.visible = true
				game.placement_ghost.position = game.world_view.tile_to_world(Vector2(house)) + Vector3.UP * 0.08
			game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(house)), 26.0)
		"site_clearing":
			var house: Vector2i = _forested_house_tile(simulation)
			_paint_trees(simulation, house, Vector2i(2, 2), 1)
			_ensure_road(simulation, house + Vector2i(0, -1))
			simulation.request_build(Defs.BUILDING_HOUSE, house)
			game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(house)), 26.0)
		"cleared_complete":
			DemoFixture.new().apply(simulation, "developed")
			game._initialize_presentation()
			_focus_building(game, Defs.BUILDING_HOUSE, 26.0)
		"storage_storehouse":
			for resource_type in [Defs.RESOURCE_WOOD, Defs.RESOURCE_PLANKS, Defs.RESOURCE_STONE]:
				simulation.central_inventory[resource_type] = simulation.get_storage_limit(resource_type)
			var store: Vector2i = simulation._town_hall_entrance_tile() + Vector2i(2, 2)
			_paint_trees(simulation, store, Vector2i(4, 3), 1)
			_ensure_road(simulation, store + Vector2i(0, -1))
			simulation.request_build(Defs.BUILDING_STOREHOUSE, store)
			simulation.push_notice("economy", "STORAGE FULL", "Build a Storehouse or free capacity.", "warning")
			game._ingest_simulation_notices()
			game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(store)), 28.0)
		"objective_reach":
			_starter_economy(simulation)
			if game.objective_detail_panel != null:
				game._toggle_objective_detail()
			_focus_town(game, 34.0)
		"frontier":
			_starter_economy(simulation)
			game._set_build_palette_visible(true)
			game._set_build_category(0)
			if game.build_category_select != null:
				for index in game.build_category_select.item_count:
					if String(game.build_category_select.get_item_metadata(index)) == "SPECIAL":
						game._set_build_category(index)
						break
			_focus_town(game, 32.0)
		"tower_guard":
			simulation.soldiers_total = 1
			var tower: Dictionary = simulation._add_completed_building(Defs.BUILDING_WATCHTOWER, simulation.town_hall_position + Vector2i(6, 2))
			tower["connected"] = true
			tower["soldiers_assigned"] = 1
			simulation._try_staff_building(tower)
			simulation._sync_production_workers()
			simulation._update_production_workers(0.2)
			game._initialize_presentation()
			game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(simulation.get_building_center(tower))), 22.0)
		"night2_approach":
			_prepare_night2(simulation, game)
			if simulation.enemies.size() > 0:
				game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(simulation.enemies[0].get("position", simulation.town_hall_position))), 30.0)
			else:
				_focus_town(game, 32.0)
		"night2_contact":
			_prepare_night2(simulation, game)
			simulation._simulate_seconds_for_test(8.0)
			_focus_town(game, 30.0)
		"melee":
			simulation.is_night = true
			simulation._reveal_radius(simulation.town_hall_position, 12)
			var guard: Dictionary = simulation._create_patrol_worker(0, "melee")
			guard["position"] = simulation.town_hall_position + Vector2i(2, 0)
			simulation.workers.append(guard)
			simulation._spawn_enemy(guard["position"] + Vector2i(1, 0), 30, 7, 0.0, 0, simulation.ENEMY_RAIDER)
			simulation._update_patrol_combat(1.2)
			game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(guard["position"])), 20.0)
		"post_raid":
			DemoFixture.new().apply(simulation, "developed")
			simulation.is_night = false
			simulation.day_count = 3
			simulation.phase_time = 20.0
			game._initialize_presentation()
			_focus_town(game, 32.0)


func _starter_economy(simulation) -> void:
	simulation._add_completed_building(Defs.BUILDING_HOUSE, simulation.town_hall_position + Vector2i(6, 0))
	simulation._add_completed_building(Defs.BUILDING_LUMBER_CAMP, simulation.town_hall_position + Vector2i(6, 4))
	simulation._add_completed_building(Defs.BUILDING_FARM, simulation.town_hall_position + Vector2i(6, 8))


func _prepare_night2(simulation, game) -> void:
	simulation.soldiers_total = 1
	var tower: Dictionary = simulation._add_completed_building(Defs.BUILDING_WATCHTOWER, simulation.town_hall_position + Vector2i(6, 2))
	tower["connected"] = true
	tower["soldiers_assigned"] = 1
	simulation._try_staff_building(tower)
	simulation._sync_production_workers()
	simulation.day_count = 2
	simulation.is_night = true
	simulation.phase_time = 12.0
	simulation._spawn_wave()
	game._initialize_presentation()


func _forested_house_tile(simulation) -> Vector2i:
	var entrance: Vector2i = simulation._town_hall_entrance_tile()
	return entrance + Vector2i(0, 2)


func _paint_trees(simulation, anchor: Vector2i, footprint: Vector2i, remaining: int = 6) -> void:
	for y in range(footprint.y):
		for x in range(footprint.x):
			var tile := anchor + Vector2i(x, y)
			simulation._prepare_test_tile(tile, Defs.TILE_TREE)
			simulation.tree_deposits[simulation._tile_key(tile)] = remaining


func _ensure_road(simulation, tile: Vector2i) -> void:
	simulation._prepare_test_tile(tile, Defs.TILE_GRASS)
	simulation.request_build(Defs.BUILDING_ROAD, tile)


func _focus_town(game, zoom: float) -> void:
	var simulation = game.simulation_host.simulation
	var town_center := Vector2(simulation.town_hall_position) + Vector2(1.5, 1.5)
	game.camera_rig.compose_view(game.world_view.tile_to_world(town_center), zoom)


func _focus_building(game, building_type: String, zoom: float) -> void:
	var simulation = game.simulation_host.simulation
	for building_value in simulation.get_buildings():
		var building: Dictionary = building_value
		if String(building.get("type", "")) == building_type and not bool(building.get("construction", false)):
			game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(simulation.get_building_center(building))), zoom)
			return
	_focus_town(game, zoom)
