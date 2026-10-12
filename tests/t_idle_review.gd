extends SceneTree

## The Director: TEST #21 review shots — idle crew overview, jump
## shortcut, Channel HP feedback, 2 s fissure hold, victory overlay.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const CraterWar = preload("res://src/GodotClient/Scripts/one_shard_crater_war.gd")

const DEST := "res://artifacts/demo_playthrough_v9/shots_for_review"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var dest := ProjectSettings.globalize_path(DEST)
	DirAccess.make_dir_recursive_absolute(dest)
	var game = Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.start_new_3d(260821)
	game._hide_start_menu()
	game.simulation_host.paused = true
	var sim = game.simulation_host.simulation
	sim.central_inventory[Defs.RESOURCE_STABILIZED_WYRD] = 6
	sim.central_inventory[Defs.RESOURCE_PLANKS] = 0
	sim.housing_capacity = 16
	sim.population_current = 16
	var hall: Vector2i = sim.town_hall_position
	var house: Dictionary = sim._create_building(Defs.BUILDING_CONSTRUCTION_SITE, hall + Vector2i(3, 2))
	house["planned_type"] = Defs.BUILDING_HOUSE
	house["construction"] = true
	house["connected"] = true
	house["materials_needed"] = {Defs.RESOURCE_PLANKS: 6, Defs.RESOURCE_WOOD: 4}
	house["materials_delivered"] = Defs.empty_inventory()
	house["materials_in_transit"] = Defs.empty_inventory()
	sim.buildings.append(house)
	game.play_has_begun = true
	game._update_ui()
	if game.has_method("_on_idle_workers_pressed"):
		game._on_idle_workers_pressed()
	game._update_ui()
	await _shot(game, sim, dest.path_join("idle_overview.png"), hall, 36.0)
	if game.idle_jump_button != null:
		game.idle_jump_button.emit_signal("pressed")
	game._update_ui()
	await _shot(game, sim, dest.path_join("idle_jump.png"), Vector2i(house.get("position", hall)), 32.0)
	if game.has_method("_show_idle_crew"):
		game._show_idle_crew(false)

	_ready_ceremony(sim)
	sim.request_midgame_choice("shelter")
	sim.request_begin_seal()
	sim.crater_war.ritual_progress = CraterWar.SEAL_CHOICE_AT + 0.5
	sim.crater_war._maybe_offer_seal_choice()
	sim.request_seal_choice("wall")
	var wall: Dictionary = sim._create_building(Defs.BUILDING_WALL, sim.crater_war.primary_fissure + Vector2i(2, 1))
	wall["construction"] = false
	wall["completed"] = true
	wall["hp"] = 40
	wall["max_hp"] = Defs.building_hp(Defs.BUILDING_WALL)
	sim.buildings.append(wall)
	sim.request_channel_wyrd()
	sim.is_night = false
	game._update_ui()
	await _shot(game, sim, dest.path_join("channel_feedback.png"), sim.crater_war.last_channel_tile, 48.0)

	sim.crater_war.ritual_progress = CraterWar.RITUAL_SECONDS
	sim.victory = true
	sim.game_finished = true
	sim.is_night = false
	sim.defeat_reason = "THE FISSURE IS SEALED — the ceremony held."
	sim.crater_war.channel_uses = maxi(1, sim.crater_war.channel_uses)
	sim.crater_war.victory_ceremony = true
	sim.crater_war.wyrd_choice = CraterWar.PATH_REFINE
	sim.crater_war.seal_choice = CraterWar.PATH_WALL
	sim.crater_war.midgame_choice = CraterWar.PATH_SHELTER
	sim.elapsed_seconds = 50.0 * 60.0 + 35.0
	if game.result_overlay != null:
		game.result_overlay.visible = false
	if game.has_method("_set_play_chrome_visible"):
		game._set_play_chrome_visible(true)
	if game.has_method("_frame_victory_fissure"):
		game._frame_victory_fissure()
	await _shot(game, sim, dest.path_join("fissure_calm.png"), sim.crater_war.primary_fissure, 42.0)
	if game.has_method("_show_result_screen"):
		game._show_result_screen()
	await _shot(game, sim, dest.path_join("victory_overlay.png"), sim.crater_war.primary_fissure, 42.0)
	print("T_IDLE_REVIEW written to %s" % dest)
	game.queue_free()
	await process_frame
	quit(0)


func _ready_ceremony(sim) -> void:
	sim.elapsed_seconds = Simulation.DEMO_FRONTIER_SECONDS
	sim._update_demo_beats()
	sim.elapsed_seconds = sim.crater_war.rival_reveal_seconds()
	sim._update_demo_beats()
	var store: Dictionary = sim._create_building(Defs.BUILDING_STOREHOUSE, sim.town_hall_position + Vector2i(4, 10))
	store["construction"] = false
	store["completed"] = true
	sim.buildings.append(store)
	var harvest: Dictionary = sim._create_building(Defs.BUILDING_WYRD_HARVESTER, sim.crater_war.primary_fissure)
	harvest["construction"] = false
	harvest["completed"] = true
	sim.buildings.append(harvest)
	var refine: Dictionary = sim._create_building(Defs.BUILDING_WYRD_REFINER, sim.town_hall_position + Vector2i(9, 4))
	refine["construction"] = false
	refine["completed"] = true
	sim.buildings.append(refine)
	sim.central_inventory[Defs.RESOURCE_STABILIZED_WYRD] = 12
	sim.central_inventory[Defs.RESOURCE_WOOD] = 12
	for structure in sim.rivalry.get_structures("rival"):
		if String(structure.get("type", "")) == Defs.BUILDING_OUTPOST:
			sim.crater_war.capture_outpost(structure)
			break
	sim.elapsed_seconds = maxf(float(sim.elapsed_seconds), sim.crater_war.midgame_seconds())
	sim.crater_war._maybe_offer_midgame()


func _shot(game, sim, path: String, tile: Vector2i, zoom: float) -> void:
	if tile.x >= 0:
		sim._reveal_radius(tile, 8)
	if game.world_view != null:
		game.world_view.last_revealed_count = -1
		game.camera_rig.configure_for_map(sim.map_size)
		var focus: Vector3 = game.world_view.tile_to_world(Vector2(tile if tile.x >= 0 else sim.town_hall_position))
		game.camera_rig.compose_view(focus, zoom)
		game.world_view.note_camera(game.camera_rig.target_position, zoom)
	game._sync_presentation()
	if game.has_method("_update_ui"):
		game._update_ui()
	for _i in 20:
		await process_frame
		if game.world_view != null:
			game.world_view.stream_chunks(16000)
			if game.world_view.has_method("_update_seal_ceremony"):
				game.world_view._update_seal_ceremony(sim.get_wyrdfall_presentation())
			if game.world_view.has_method("_update_channel_flash"):
				game.world_view._update_channel_flash(sim.get_wyrdfall_presentation())
			if game.world_view.has_method("_sync_map_markers"):
				game.world_view._sync_map_markers()
	await RenderingServer.frame_post_draw
	var image: Image = root.get_viewport().get_texture().get_image()
	image.save_png(path)
	print("T_IDLE_REVIEW shot %s" % path)
