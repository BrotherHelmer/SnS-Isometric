extends SceneTree

const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const RivalryTuning = preload("res://src/GodotClient/Scripts/one_shard_rivalry_tuning.gd")

var view
var output_dir := ""
var capture_failures: Array[String] = []


func _init() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Presentation capture requires a readable framebuffer.")
		quit(1)
		return
	call_deferred("_run")


func _run() -> void:
	var viewport_size := root.size
	output_dir = "res://artifacts/presentation_pass/%dx%d" % [int(viewport_size.x), int(viewport_size.y)]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	var packed: PackedScene = load("res://src/GodotClient/Scenes/main.tscn")
	view = packed.instantiate()
	root.add_child(view)
	await _settle(4)
	await _capture("01_main_menu.png")

	view._start_new_demo()
	view.paused = true
	await _settle(4)
	await _capture("02_town_hall_opening.png")

	view.paused = false
	view._update_opening_intro(1.25)
	for _tick in range(5):
		view.simulation.advance_tick()
	view.tick_accumulator = 0.38
	await _settle(3)
	await _capture("03_settler_walks_out.png")

	var worker_id: int = view.simulation.get_presentation_worker_id()
	var entrance: Vector2i = view.simulation._town_hall_entrance_tile()
	var worker := _worker_mutable(worker_id)
	worker["position"] = entrance + Vector2i(1, 2)
	worker["path"] = []
	worker["move_elapsed"] = 0.0
	view.simulation.set_worker_reaction(worker_id, "Confused", "?", 8.0)
	view.opening_intro_active = false
	view.objective_intro_visible = true
	view.paused = true
	view._update_ui()
	await _settle(3)
	await _capture("04_settler_confused_reaction.png")

	var town_center: Vector2i = view.simulation._footprint_center(view.simulation.town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	var gather_target := town_center + Vector2i(7, -6)
	view.selected_worker_id = worker_id
	view.selected_tile = worker["position"]
	view.paused = false
	view._issue_selected_worker_order(gather_target)
	view.paused = true
	await _settle(3)
	await _capture("05_first_player_order.png")

	view.paused = false
	for _tick in range(16):
		view.simulation.advance_tick()
	view.tick_accumulator = 0.34
	view.paused = true
	view._update_ui()
	await _settle(3)
	await _capture("06_settler_locomotion.png")

	worker = _worker_mutable(worker_id)
	worker["position"] = worker.get("work_position", worker["position"])
	worker["path"] = []
	worker["state"] = "Gathering"
	worker["arrival_state"] = "Gathering"
	worker["activity_timer"] = 2.4
	view.paused = true
	view._update_ui()
	await _settle(3)
	await _capture("07_settler_working.png")

	view._show_build_category("Resources")
	await _settle(3)
	await _capture("08_left_build_interface.png")

	view.simulation._update_objective_flag("first_order")
	view.simulation.presentation_opening_active = false
	view.current_mode = Defs.BUILDING_LUMBER_CAMP
	view._show_build_category("Resources")
	view._sync_mode_buttons()
	view.hovered_tile = town_center + Vector2i(4, 5)
	view._update_ui()
	await _settle(3)
	await _capture("09_building_thumbnail_selection.png")

	_prepare_developed_settlement()
	view._show_build_category("Settlement")
	view._update_ui()
	await _settle(4)
	await _capture("10_developed_day_settlement.png")

	view.simulation.is_night = false
	view.simulation.phase_time = view.simulation.DAY_LENGTH_SECONDS - 42.0
	view._update_visual_modes(4.0)
	view._update_ui()
	await _settle(4)
	await _capture("11_dusk_transition.png")

	view.simulation.is_night = true
	view.simulation.day_count = 2
	view.simulation.phase_time = 24.0
	for index in range(7):
		view.simulation._spawn_enemy(
			view.simulation.town_hall_position + Vector2i(11 + index % 3, -5 + index),
			22 + index * 2,
			2 + index % 2,
			-0.04 * float(index),
			0,
			[
				view.simulation.ENEMY_RAIDER,
				view.simulation.ENEMY_SKITTERER,
				view.simulation.ENEMY_BRUTE,
				view.simulation.ENEMY_HEXER
			][index % 4]
		)
	view._show_build_category("Defence")
	view._update_visual_modes(4.0)
	view._update_ui()
	await _settle(4)
	await _capture("12_night_raid.png")

	view._show_settings(false)
	await _settle(4)
	await _capture("13_audio_settings.png")

	_prepare_shard_claim()
	await _settle(4)
	await _capture("14_shard_claim.png")

	var report := "PRESENTATION_CAPTURE %s\n%s\n" % [
		"PASS" if capture_failures.is_empty() else "FAIL",
		"\n".join(capture_failures)
	]
	var report_file := FileAccess.open("%s/capture_report.txt" % output_dir, FileAccess.WRITE)
	if report_file != null:
		report_file.store_string(report)
	print(report)
	view.queue_free()
	await process_frame
	quit(0 if capture_failures.is_empty() else 1)


func _worker_mutable(worker_id: int) -> Dictionary:
	for worker in view.simulation.workers:
		if int(worker.get("id", 0)) == worker_id:
			return worker
	return {}


func _prepare_developed_settlement() -> void:
	var simulation = view.simulation
	simulation.start_new_run(70, 70, 707070, true)
	simulation.diagnostics_enabled = false
	simulation.population_current = 18
	simulation.housing_capacity = 25
	simulation.central_inventory[Defs.RESOURCE_WOOD] = 48
	simulation.central_inventory[Defs.RESOURCE_PLANKS] = 32
	simulation.central_inventory[Defs.RESOURCE_STONE] = 46
	simulation.central_inventory[Defs.RESOURCE_WHEAT] = 24
	simulation.central_inventory[Defs.RESOURCE_BREAD] = 24
	simulation.soldiers_total = 3
	var town: Vector2i = simulation.town_hall_position
	var center: Vector2i = simulation._footprint_center(town, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	simulation._clear_area(center, 17)
	simulation._flatten_area(center, 12)
	for x in range(town.x - 8, town.x + 15):
		_add_building(simulation, Defs.BUILDING_ROAD, Vector2i(x, town.y + 4))
	for y in range(town.y - 8, town.y + 14):
		_add_building(simulation, Defs.BUILDING_ROAD, Vector2i(town.x + 4, y))
	_add_building(simulation, Defs.BUILDING_HOUSE, town + Vector2i(-5, 0))
	_add_building(simulation, Defs.BUILDING_HOUSE, town + Vector2i(-5, 3))
	_add_building(simulation, Defs.BUILDING_STOREHOUSE, town + Vector2i(6, 0))
	_add_building(simulation, Defs.BUILDING_LUMBER_CAMP, town + Vector2i(-7, 6))
	_add_building(simulation, Defs.BUILDING_SAWMILL, town + Vector2i(-3, 6))
	_add_building(simulation, Defs.BUILDING_FARM, town + Vector2i(1, 6))
	_add_building(simulation, Defs.BUILDING_BARRACKS, town + Vector2i(6, 6))
	_add_building(simulation, Defs.BUILDING_BAKERY, town + Vector2i(6, -8))
	_add_building(simulation, Defs.BUILDING_QUARRY, town + Vector2i(1, -8))
	for x in range(town.x + 5, town.x + 14):
		_add_building(simulation, Defs.BUILDING_WATCHTOWER if x == town.x + 10 else Defs.BUILDING_WALL, Vector2i(x, town.y - 4))
	simulation._rebuild_occupied_tiles()
	simulation._recompute_road_network()
	for building in simulation.buildings:
		building["connected"] = true
	simulation._reveal_radius(center, 24)
	simulation._auto_staff_unstaffed_buildings()
	simulation._sync_production_workers()
	view.selected_worker_id = 0
	view.selected_tile = town + Vector2i(6, 0)
	view._update_selected_building_id()
	view.opening_intro_active = false
	view.objective_intro_visible = true
	view.current_mode = view.MODE_SELECT
	view.main_menu_root.visible = false
	view.game_started = true
	view.paused = true
	view.toast_timer = 0.0
	view.toast_panel.visible = false
	view._invalidate_revealed_tile_cache()
	view._refresh_static_world_if_needed(true)
	view.camera.position = view.tile_to_world(center) + Vector2(62, 28)
	view.camera.zoom = Vector2(1.35, 1.35)
	view.pre_shard_zoom = 1.35


func _prepare_shard_claim() -> void:
	var simulation = view.simulation
	simulation.start_new_run(70, 70, 919191, true)
	var shard: Vector2i = simulation.shard_position
	simulation._clear_area(shard, 10)
	simulation._set_tile(shard, Defs.TILE_SHARD)
	simulation._flatten_area(shard, 10)
	simulation._reveal_radius(shard, 17)
	var definition: Dictionary = RivalryTuning.structure_definition(RivalryTuning.STRUCTURE_CLAIMANT_OUTPOST)
	var outpost_position := shard + Vector2i(-4, 0)
	var structure := {
		"id": 7001,
		"realm_id": RivalryTuning.PLAYER_REALM,
		"type": RivalryTuning.STRUCTURE_CLAIMANT_OUTPOST,
		"position": outpost_position,
		"footprint": definition.get("footprint", Vector2i(2, 2)),
		"hp": int(definition.get("max_hp", 220)),
		"max_hp": int(definition.get("max_hp", 220)),
		"active": true,
		"connected": true,
		"damage_flash": 0.0
	}
	simulation.rivalry.structures.append(structure)
	simulation.rivalry.realms[RivalryTuning.PLAYER_REALM]["structures"].append(7001)
	var claim: Dictionary = simulation.rivalry.realms[RivalryTuning.PLAYER_REALM]["claim"]
	claim["active"] = true
	claim["outpost_id"] = 7001
	claim["night_progress"] = simulation.NIGHT_LENGTH_SECONDS * 0.58
	claim["status"] = "Claim holding — keep the Sovereign inside the ring."
	var sovereign: Dictionary = simulation.rivalry.get_sovereign(RivalryTuning.PLAYER_REALM)
	sovereign["position"] = Vector2(shard + Vector2i(-1, 1))
	sovereign["previous_position"] = sovereign["position"]
	sovereign["move_target"] = sovereign["position"]
	view.main_menu_root.visible = false
	view.settings_card.visible = false
	view.pause_menu_root.visible = false
	view.game_started = true
	view.paused = true
	view.selected_worker_id = 0
	view.selected_building_id = 0
	view.current_mode = view.MODE_SELECT
	view.objective_intro_visible = true
	view._show_build_category("Lumen")
	view._invalidate_revealed_tile_cache()
	view._refresh_static_world_if_needed(true)
	view.camera.position = view.tile_to_world(shard) + Vector2(48, 18)
	view.camera.zoom = Vector2(1.55, 1.55)
	view.pre_shard_zoom = 1.55
	view._update_ui()
	view.queue_redraw()


func _add_building(simulation, building_type: String, anchor: Vector2i) -> void:
	var footprint := Defs.building_footprint(building_type)
	var level: int = simulation.get_height(anchor)
	for y in range(footprint.y):
		for x in range(footprint.x):
			var tile := anchor + Vector2i(x, y)
			if not simulation.is_inside_map(tile):
				continue
			simulation._prepare_test_tile(tile, Defs.TILE_GRASS)
			simulation.height_map[tile.y][tile.x] = level
	if simulation.get_building_at_tile(anchor).is_empty():
		simulation._add_completed_building(building_type, anchor)


func _settle(frames: int) -> void:
	for _frame in range(frames):
		view.queue_redraw()
		if view.static_world != null:
			view.static_world.queue_redraw()
		await process_frame


func _capture(file_name: String) -> void:
	var texture := root.get_texture()
	if texture == null:
		capture_failures.append("%s: no viewport texture" % file_name)
		return
	var image := texture.get_image()
	if image == null:
		capture_failures.append("%s: no readable image" % file_name)
		return
	var error := image.save_png("%s/%s" % [output_dir, file_name])
	if error != OK:
		capture_failures.append("%s: save error %d" % [file_name, error])
