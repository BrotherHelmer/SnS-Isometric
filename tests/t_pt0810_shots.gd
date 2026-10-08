extends SceneTree

## Playtest 8/10 after-fix shots: a scout walking into fog, and a night raid
## where the guard fights and the raider stays readable over the farm crops.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Fixture = preload("res://src/GodotClient3D/Scripts/production_demo_fixture.gd")

var out_dir := "res://artifacts/pt0810"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	if OS.get_environment("PT0810_OUT") != "":
		out_dir = OS.get_environment("PT0810_OUT")
	var dest_root := ProjectSettings.globalize_path(out_dir) if out_dir.begins_with("res://") else out_dir
	DirAccess.make_dir_recursive_absolute(dest_root)
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.start_new_3d(game.DEFAULT_SEED)
	game._hide_start_menu()
	var simulation = game.simulation_host.simulation
	var fixture := Fixture.new()
	fixture.apply(simulation, "developed")
	simulation.central_inventory[Defs.RESOURCE_BREAD] = maxi(12, int(simulation.central_inventory.get(Defs.RESOURCE_BREAD, 0)))
	simulation.soldiers_total = maxi(1, simulation.soldiers_total)
	simulation._sync_production_workers()
	game._initialize_presentation()
	game.simulation_host.paused = false
	game._skip_access_tutorial()
	if game.tutorial_overlay != null:
		game.tutorial_overlay.visible = false
	var method := String(RenderingServer.get_current_rendering_method())
	print("PT0810_RENDERER method=%s" % method)
	if method != "forward_plus":
		push_error("PT0810_SHOTS requires Forward+/Vulkan (got %s)" % method)
		quit(1)
		return
	await _shot_scout(game, dest_root)
	await _shot_night_raid(game, dest_root)
	print("PT0810_SHOTS PASS dir=%s" % dest_root)
	game.queue_free()
	quit(0)


func _shot_scout(game, dest_root: String) -> void:
	var simulation = game.simulation_host.simulation
	simulation.is_night = false
	simulation.phase_time = 80.0
	simulation.raid_active = false
	simulation.enemies.clear()
	simulation.dusk_forecast.clear()
	var hall: Vector2i = Vector2i(simulation.town_hall_position)
	var fog_tile: Vector2i = _carve_scout_frontier(simulation, hall)
	var staging: Vector2i = fog_tile + Vector2i(-7, 0)
	if not simulation.is_inside_map(staging):
		staging = hall + Vector2i(4, 1)
	var guard := _ensure_patrol(simulation, staging)
	simulation.central_inventory[Defs.RESOURCE_BREAD] = maxi(8, int(simulation.central_inventory.get(Defs.RESOURCE_BREAD, 0)))
	game.select_worker(int(guard.get("id", 0)))
	var ordered := game._order_selected_scout()
	var result: Dictionary = {}
	if not ordered:
		result = simulation.request_scout_auto(int(guard.get("id", 0)))
	print("PT0810_SCOUT_ORDER ui=%s auto=%s msg=%s fog=%s" % [
		str(ordered), str(bool(result.get("success", ordered))),
		String(simulation.last_message), str(fog_tile)
	])
	simulation._simulate_seconds_for_test(14.0)
	guard = simulation.get_worker_by_id(int(guard.get("id", 0)))
	game.select_worker(int(guard.get("id", 0)))
	game.simulation_host.paused = true
	game._update_day_night_lighting()
	game._sync_presentation()
	game._update_ui()
	if game.tutorial_overlay != null:
		game.tutorial_overlay.visible = false
	if game.alert_panel != null:
		game.alert_panel.visible = false
	var guard_tile: Vector2i = Vector2i(guard.get("position", staging))
	var focus: Vector3 = game.world_view.tile_to_world(Vector2(guard_tile) + Vector2(1.2, 0.4))
	game.camera_rig.compose_view(focus, 26.0)
	print("PT0810_SCOUT state=%s tile=%s mission=%s" % [
		String(guard.get("state", "")), str(guard_tile), str(guard.has("scout_mission"))
	])
	await _capture(dest_root, "after_day_scout.png")
	game.simulation_host.paused = false


func _shot_night_raid(game, dest_root: String) -> void:
	var simulation = game.simulation_host.simulation
	simulation.is_night = true
	simulation.phase_time = 18.0
	var live_scout: Dictionary = _first_patrol(simulation)
	if not live_scout.is_empty() and live_scout.has("scout_mission"):
		simulation._finish_scout(live_scout)
	simulation._send_workers_to_shelter()
	var farm := {}
	for building in simulation.buildings:
		if String(building.get("type", "")) == Defs.BUILDING_FARM:
			farm = building
			break
	if farm.is_empty():
		var tile: Vector2i = Vector2i(simulation.town_hall_position) + Vector2i(8, 6)
		simulation._prepare_test_tile(tile, Defs.TILE_GRASS)
		farm = simulation._add_completed_building(Defs.BUILDING_FARM, tile)
		farm["connected"] = true
	var farm_tile: Vector2i = Vector2i(farm.get("position", simulation.town_hall_position))
	var crop_tile: Vector2i = farm_tile + Vector2i(1, 0)
	var guard := _ensure_patrol(simulation, farm_tile + Vector2i(3, 1))
	guard["path"] = []
	guard["state"] = "Night Patrol"
	guard["arrival_state"] = "Night Watch"
	simulation._reveal_radius(farm_tile, 8)
	simulation._reveal_radius(Vector2i(guard["position"]), 6)
	simulation._prepare_test_tile(crop_tile, Defs.TILE_GRASS)
	simulation._reveal_radius(crop_tile, 3)
	simulation.enemies.clear()
	simulation._spawn_enemy(crop_tile, 28, 4, 0.0, 0, simulation.ENEMY_RAIDER, 0)
	simulation.enemies[0]["target_kind"] = "building"
	simulation.enemies[0]["target_id"] = int(farm.get("id", 0))
	if not simulation.raid_active:
		simulation._begin_raid(1)
	simulation._simulate_seconds_for_test(2.4)
	guard = simulation.get_worker_by_id(int(guard.get("id", 0)))
	game.select_worker(int(guard.get("id", 0)))
	game.simulation_host.paused = true
	game._update_day_night_lighting()
	game._sync_presentation()
	game._update_ui()
	if game.tutorial_overlay != null:
		game.tutorial_overlay.visible = false
	var focus: Vector3 = _farm_wheat_focus(game, farm_tile)
	game.camera_rig.compose_view(focus, 22.0)
	print("PT0810_NIGHT guard=%s raider=%s farm=%s" % [
		String(guard.get("state", "")),
		str(simulation.enemies[0].get("position", Vector2i.ZERO) if not simulation.enemies.is_empty() else Vector2i.ZERO),
		str(farm_tile)
	])
	await _capture(dest_root, "after_night_raid.png")


func _carve_scout_frontier(simulation, origin: Vector2i) -> Vector2i:
	var patch: Vector2i = origin + Vector2i(20, 2)
	if not simulation.is_inside_map(patch + Vector2i(6, 6)):
		patch = origin + Vector2i(2, 20)
	if not simulation.is_inside_map(patch):
		patch = Vector2i(mini(simulation.map_size.x - 8, origin.x + 16), origin.y)
	for y in range(patch.y - 1, patch.y + 9):
		for x in range(patch.x - 1, patch.x + 9):
			var tile := Vector2i(x, y)
			if not simulation.is_inside_map(tile):
				continue
			simulation.revealed_tiles.erase(simulation._tile_key(tile))
			simulation._set_tile(tile, Defs.TILE_GRASS)
	return patch


func _farm_wheat_focus(game, farm_tile: Vector2i) -> Vector3:
	var wheat := _find_named(game, "WheatCrop")
	if wheat is Node3D:
		return (wheat as Node3D).global_position
	return game.world_view.tile_to_world(Vector2(farm_tile) + Vector2(1.1, -0.8))


func _ensure_patrol(simulation, tile: Vector2i) -> Dictionary:
	var guard := _first_patrol(simulation)
	if guard.is_empty():
		simulation.soldiers_total = maxi(1, simulation.soldiers_total)
		guard = simulation._create_patrol_worker(0, "patrol:0")
		simulation.workers.append(guard)
	guard["position"] = tile
	guard["path"] = []
	return guard


func _first_patrol(simulation) -> Dictionary:
	for worker in simulation.workers:
		if simulation.is_patrol_scout(worker):
			return worker
	return {}


func _find_named(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found := _find_named(child, node_name)
		if found != null:
			return found
	return null


func _capture(dest_root: String, filename: String) -> void:
	for _i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	var viewport_texture: ViewportTexture = root.get_viewport().get_texture()
	var image: Image = viewport_texture.get_image() if viewport_texture != null else null
	var dest := dest_root.path_join(filename)
	if image != null and not image.is_empty():
		image.save_png(dest)
		print("PT0810_SHOT wrote %s" % dest)
	else:
		push_error("PT0810_SHOT empty %s" % dest)
