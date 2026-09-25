extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Tuning = preload("res://src/GodotClient/Scripts/one_shard_rivalry_tuning.gd")
const DemoFixture = preload("res://src/GodotClient3D/Scripts/production_demo_fixture.gd")
const Wyrdfall = preload("res://src/GodotClient/Scripts/one_shard_wyrdfall.gd")

const OUTPUT_DIR := "res://artifacts/phase4_1/screenshots"
const CAPTURE_SIZE := Vector2i(1920, 1080)
const CAPTURES := [
	{"stage": "title", "file": "01_title_screen.png"},
	{"stage": "new_realm", "file": "02_new_realm.png"},
	{"stage": "settings", "file": "03_settings.png"},
	{"stage": "opening", "file": "04_opening_settlement.png"},
	{"stage": "busy", "file": "05_busy_developed_settlement.png"},
	{"stage": "outpost", "file": "08_outpost_expansion.png"},
	{"stage": "spring", "file": "09_wyrd_spring.png"},
	{"stage": "late_day", "file": "10_late_day.png"},
	{"stage": "dusk", "file": "11_dusk.png"},
	{"stage": "first_lights", "file": "12_first_lights.png"},
	{"stage": "night_safe", "file": "13_night_settlement.png"},
	{"stage": "night_guards", "file": "14_night_guards.png"},
	{"stage": "raid_approach", "file": "15_raider_approach.png"},
	{"stage": "combat", "file": "16_active_combat.png"},
	{"stage": "shard_distant", "file": "17_distant_shard.png"},
	{"stage": "impact", "file": "18_shard_impact_zone.png"},
	{"stage": "contested", "file": "19_contested_shard.png"},
	{"stage": "bind_confirm", "file": "20_binding_confirmation.png"},
	{"stage": "reckoning", "file": "21_reckoning.png"},
	{"stage": "late_binding", "file": "22_late_binding.png"},
	{"stage": "victory", "file": "23_victory.png"},
	{"stage": "defeat", "file": "24_defeat.png"},
]


func _init() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Phase 4.1 captures require a windowed framebuffer.")
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
		for _frame in 18:
			await process_frame
		await RenderingServer.frame_post_draw
		_save_capture(String(capture.stage), String(capture.file), Engine.get_frames_per_second())
		if String(capture.stage) == "busy":
			_focus_building(game, Defs.BUILDING_LUMBER_CAMP, 26.0)
			game._sync_presentation()
			game._update_ui()
			game._update_day_night_lighting()
			for _frame in 10:
				await process_frame
			await RenderingServer.frame_post_draw
			_save_capture("lumber", "06_lumber_industrial.png", Engine.get_frames_per_second())
			_focus_building(game, Defs.BUILDING_FARM, 26.0)
			game._sync_presentation()
			game._update_ui()
			game._update_day_night_lighting()
			for _frame in 10:
				await process_frame
			await RenderingServer.frame_post_draw
			_save_capture("farm", "07_farm_bakery.png", Engine.get_frames_per_second())
		game.queue_free()
		await process_frame
	print("PHASE41_CAPTURE_SUITE PASS count=24")
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
	print("PHASE41_CAPTURE_PASS stage=%s fps=%.1f path=%s" % [stage, fps, absolute_path])


func _configure_stage(game, stage: String) -> void:
	var simulation = game.simulation_host.simulation
	match stage:
		"title":
			game._show_start_menu()
			return
		"new_realm":
			game._show_start_menu()
			game._show_new_realm_card()
			return
		"settings":
			game._show_start_menu()
			game._show_settings_card()
			return
		"victory":
			game.start_new_3d(game.DEFAULT_SEED)
			simulation = game.simulation_host.simulation
			simulation._finish_run(true, "SHARD BOUND")
			game._show_result_screen()
			return
		"defeat":
			game.start_new_3d(game.DEFAULT_SEED)
			simulation = game.simulation_host.simulation
			simulation._finish_run(false, "The rival bound the Shard first.")
			game._show_result_screen()
			return
	game.start_new_3d(game.DEFAULT_SEED)
	simulation = game.simulation_host.simulation
	game.simulation_host.paused = true
	game.world_view.set_presentation_paused(true)
	game.status_message_text = ""
	game.status_message_until = 0.0
	if game.status_label != null:
		game.status_label.text = ""
	if game.alert_panel != null:
		game.alert_panel.visible = false
	match stage:
		"opening":
			_focus_town(game, 32.0)
		"busy", "lumber", "farm":
			DemoFixture.new().apply(simulation, "developed")
			game._initialize_presentation()
			if stage == "lumber":
				_focus_building(game, Defs.BUILDING_LUMBER_CAMP, 26.0)
			elif stage == "farm":
				_focus_building(game, Defs.BUILDING_FARM, 26.0)
			else:
				_focus_town(game, 34.0)
		"outpost":
			_configure_ready_claim(simulation, simulation.rivalry, Tuning.PLAYER_REALM)
			simulation._reveal_radius(simulation.shard_position, 8)
			game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(simulation.shard_position) + Vector2(-6, 0)), 40.0)
		"spring":
			if simulation.rivalry != null:
				for site in simulation.rivalry.get_wyrd_sites():
					simulation._reveal_radius(Vector2i(site.get("position", Vector2i.ZERO)), 4)
					game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(site.get("position", Vector2i.ZERO))), 28.0)
					break
		"late_day":
			simulation.phase_time = simulation.DAY_LENGTH_SECONDS - 90.0
			_focus_town(game, 32.0)
		"dusk", "first_lights":
			simulation.phase_time = simulation.DAY_LENGTH_SECONDS - 22.0
			simulation.night_warning_sent = true
			_focus_town(game, 32.0)
		"night_safe", "night_guards":
			simulation.is_night = true
			simulation.phase_time = 18.0
			_focus_town(game, 30.0)
		"raid_approach", "combat":
			simulation.is_night = true
			simulation.phase_time = 24.0
			simulation.day_count = 4
			simulation.cumulative_wyrd_extracted = 16
			simulation.enemies.clear()
			simulation._spawn_wave()
			if simulation.enemies.size() > 0:
				var enemy: Dictionary = simulation.enemies[0]
				game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(enemy.get("position", simulation.town_hall_position))), 28.0)
			else:
				_focus_town(game, 30.0)
		"shard_distant":
			simulation._reveal_radius(simulation.shard_position, 4)
			var town: Vector3 = game.world_view.tile_to_world(Vector2(simulation.town_hall_position) + Vector2(1.5, 1.5))
			var shard: Vector3 = game.world_view.tile_to_world(Vector2(simulation.shard_position))
			game.camera_rig.compose_view(town.lerp(shard, 0.42), 58.0)
		"impact":
			simulation._reveal_radius(simulation.shard_position, 8)
			game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(simulation.shard_position)), 32.0)
		"contested", "bind_confirm", "reckoning", "late_binding":
			_configure_ready_claim(simulation, simulation.rivalry, Tuning.PLAYER_REALM)
			simulation._reveal_radius(simulation.shard_position, 10)
			if stage != "contested":
				simulation.day_count = 4
				simulation.request_begin_binding()
				if stage == "late_binding":
					simulation.rivalry.realms[Tuning.PLAYER_REALM]["claim"]["binding_progress"] = Wyrdfall.BINDING_DURATION_SECONDS * 0.78
				if stage in ["reckoning", "late_binding"]:
					simulation.is_night = true
					simulation.phase_time = 20.0
			if stage == "bind_confirm":
				game._prompt_binding()
			game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(simulation.shard_position)), 38.0)


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


func _configure_ready_claim(simulation, rivalry, realm_id: String) -> void:
	if rivalry == null:
		return
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
	simulation._reveal_radius(outpost_anchor, 6)
