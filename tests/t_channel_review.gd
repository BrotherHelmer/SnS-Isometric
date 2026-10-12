extends SceneTree

## The Director: staged Channel Wyrd, later-camp, and victory-summary
## shots for the TEST #19 review set.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const CameraRig = preload("res://src/GodotClient3D/Scripts/production_isometric_camera_rig.gd")
const CraterWar = preload("res://src/GodotClient/Scripts/one_shard_crater_war.gd")

const DEST := "res://artifacts/demo_playthrough_v9/shots"


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
	await _shot(game, sim, dest.path_join("t44_channel.png"), sim.crater_war.last_channel_tile, 48.0)
	game.start_new_3d(261306)
	game._hide_start_menu()
	game.simulation_host.paused = true
	sim = game.simulation_host.simulation
	_ready_ceremony(sim)
	sim.central_inventory[Defs.RESOURCE_WOOD] = 12
	sim.request_midgame_choice("fortify")
	sim.elapsed_seconds = 25.0 * 60.0
	var palisade_tile: Vector2i = sim.town_hall_position + Vector2i(3, 2)
	for marker in sim.map_markers:
		if String(marker.get("kind", "")) == "palisade":
			palisade_tile = Vector2i(marker.get("position", palisade_tile))
			break
	await _shot(game, sim, dest.path_join("t25_camp_fortify.png"), palisade_tile, 28.0)
	sim.request_begin_seal()
	sim.crater_war.ritual_progress = CraterWar.RITUAL_SECONDS
	sim.victory = true
	sim.game_finished = true
	sim.defeat_reason = "THE FISSURE IS SEALED — the ceremony held."
	sim.crater_war.channel_uses = 1
	sim.crater_war.wyrd_choice = CraterWar.PATH_SECURE
	sim.crater_war.seal_choice = CraterWar.PATH_OVERCHARGE
	sim.crater_war.midgame_choice = CraterWar.PATH_FORTIFY
	sim.elapsed_seconds = 42.0 * 60.0 + 4.0
	if game.has_method("_show_result_screen"):
		game._show_result_screen()
	await _shot(game, sim, dest.path_join("t46_victory.png"), sim.crater_war.primary_fissure, 42.0)
	print("T_CHANNEL_REVIEW written to %s" % dest)
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
	print("T_CHANNEL_REVIEW shot %s" % path)
