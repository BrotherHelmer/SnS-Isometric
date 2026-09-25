extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Tuning = preload("res://src/GodotClient/Scripts/one_shard_rivalry_tuning.gd")
const Wyrdfall = preload("res://src/GodotClient/Scripts/one_shard_wyrdfall.gd")

const OUTPUT_DIR := "res://artifacts/phase4/screenshots"
const CAPTURE_SIZE := Vector2i(1920, 1080)
const FIRST15 := [
	{"stage": "title", "file": "01_title_screen.png"},
	{"stage": "settlement", "file": "02_initial_settlement.png"},
	{"stage": "workers", "file": "03_first_workers.png"},
	{"stage": "fow", "file": "04_first_fow_reveal.png"},
	{"stage": "wyrd", "file": "05_wyrd_opportunity.png"},
	{"stage": "dusk", "file": "06_dusk.png"},
	{"stage": "night", "file": "07_first_night.png"},
	{"stage": "dawn", "file": "08_dawn.png"},
	{"stage": "promise", "file": "09_shard_promise.png"},
]
const FULL := [
	{"stage": "opening", "file": "10_opening_settlement.png"},
	{"stage": "day_work", "file": "11_productive_day.png"},
	{"stage": "outpost", "file": "12_outpost_expansion.png"},
	{"stage": "danger_night", "file": "13_dangerous_night.png"},
	{"stage": "dawn_after", "file": "14_dawn_aftermath.png"},
	{"stage": "rival", "file": "15_rival_realm.png"},
	{"stage": "impact", "file": "16_shard_impact_zone.png"},
	{"stage": "contested", "file": "17_contested_shard.png"},
	{"stage": "binding", "file": "18_binding_start.png"},
	{"stage": "reckoning", "file": "19_reckoning.png"},
	{"stage": "victory", "file": "20_victory_screen.png"},
	{"stage": "defeat", "file": "21_defeat_screen.png"},
]


func _init() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Phase 4 captures require a windowed framebuffer.")
		quit(1)
		return
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	call_deferred("_run")


func _run() -> void:
	root.size = CAPTURE_SIZE
	DisplayServer.window_set_size(CAPTURE_SIZE)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var captures := FIRST15.duplicate()
	captures.append_array(FULL)
	for capture_value in captures:
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
		var image := root.get_texture().get_image()
		var path := "%s/%s" % [OUTPUT_DIR, String(capture.file)]
		var absolute_path := ProjectSettings.globalize_path(path)
		var result := image.save_png(absolute_path)
		if result != OK or image.get_width() != 1920 or image.get_height() != 1080:
			push_error("Capture failed: %s (%dx%d)" % [absolute_path, image.get_width(), image.get_height()])
			quit(1)
			return
		print("PHASE4_CAPTURE_PASS stage=%s path=%s" % [String(capture.stage), absolute_path])
		game.queue_free()
		await process_frame
	print("PHASE4_CAPTURE_SUITE PASS count=%d" % captures.size())
	quit(0)


func _configure_stage(game, stage: String) -> void:
	var simulation = game.simulation_host.simulation
	match stage:
		"title":
			game._show_start_menu()
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
	match stage:
		"settlement", "opening":
			_focus_town(game)
		"workers", "day_work":
			_focus_town(game)
		"fow":
			game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(simulation.town_hall_position) + Vector2(8, -6)), 48.0)
		"wyrd":
			if simulation.rivalry != null:
				for site in simulation.rivalry.get_wyrd_sites():
					simulation._reveal_radius(Vector2i(site.get("position", Vector2i.ZERO)), 3)
					game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(site.get("position", Vector2i.ZERO))), 36.0)
					break
		"dusk":
			simulation.phase_time = simulation.DAY_LENGTH_SECONDS - 25.0
			simulation.night_warning_sent = true
			_focus_town(game)
		"night", "danger_night":
			simulation.is_night = true
			simulation.phase_time = 20.0
			if stage != "night":
				simulation.day_count = 4
				simulation.cumulative_wyrd_extracted = 18
			simulation.enemies.clear()
			simulation._spawn_wave()
			_focus_town(game)
		"dawn", "dawn_after":
			simulation.is_night = false
			simulation.phase_time = 8.0
			simulation.dawn_summary = {
				"title": "DAWN",
				"survived": true,
				"enemies_defeated": 3,
				"settlers_lost": 1,
				"buildings_damaged": 1
			}
			_focus_town(game)
		"promise", "impact":
			simulation._reveal_radius(simulation.shard_position, 8)
			game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(simulation.shard_position)), 42.0)
		"outpost", "contested", "binding", "reckoning":
			_configure_ready_claim(simulation, simulation.rivalry, Tuning.PLAYER_REALM)
			simulation._reveal_radius(simulation.shard_position, 10)
			if stage == "binding" or stage == "reckoning":
				simulation.day_count = 4
				simulation.request_begin_binding()
				if stage == "reckoning":
					simulation.is_night = true
					simulation.phase_time = 20.0
			game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(simulation.shard_position)), 40.0)
		"rival":
			simulation._reveal_radius(simulation.rival_town_hall_position, 10)
			game.camera_rig.compose_view(game.world_view.tile_to_world(Vector2(simulation.rival_town_hall_position)), 38.0)


func _focus_town(game) -> void:
	var simulation = game.simulation_host.simulation
	var town_center := Vector2(simulation.town_hall_position) + Vector2(1.5, 1.5)
	game.camera_rig.compose_view(game.world_view.tile_to_world(town_center), 32.0)


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
