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
	var guard := _ensure_patrol(simulation, Vector2i(simulation.town_hall_position) + Vector2i(3, 2))
	game.select_worker(int(guard.get("id", 0)))
	if not game._order_selected_scout():
		simulation.request_scout_auto(int(guard.get("id", 0)))
	simulation._simulate_seconds_for_test(18.0)
	guard = simulation.get_worker_by_id(int(guard.get("id", 0)))
	game.select_worker(int(guard.get("id", 0)))
	game.simulation_host.paused = true
	game._update_day_night_lighting()
	game._sync_presentation()
	game._update_ui()
	var guard_tile: Vector2i = Vector2i(guard.get("position", simulation.town_hall_position))
	var focus: Vector3 = game.world_view.tile_to_world(Vector2(guard_tile) + Vector2(0.4, 0.4))
	game.camera_rig.compose_view(focus, 34.0)
	print("PT0810_SCOUT state=%s tile=%s mission=%s" % [
		String(guard.get("state", "")), str(guard_tile), str(guard.has("scout_mission"))
	])
	await _capture(dest_root, "after_day_scout.png")
	game.simulation_host.paused = false


func _shot_night_raid(game, dest_root: String) -> void:
	var simulation = game.simulation_host.simulation
	simulation.is_night = true
	simulation.phase_time = 18.0
	if not simulation.workers.is_empty():
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
	var crop_tile: Vector2i = farm_tile + Vector2i(1, 1)
	var guard := _ensure_patrol(simulation, farm_tile + Vector2i(3, 2))
	guard["path"] = []
	guard["state"] = "Night Patrol"
	guard["arrival_state"] = "Night Watch"
	simulation._reveal_radius(farm_tile, 8)
	simulation._reveal_radius(guard["position"], 6)
	simulation._prepare_test_tile(crop_tile, Defs.TILE_GRASS)
	simulation._reveal_radius(crop_tile, 3)
	if simulation.enemies.is_empty():
		simulation._spawn_enemy(crop_tile, 28, 4, 0.0, 0, simulation.ENEMY_RAIDER, 0)
	else:
		simulation.enemies[0]["position"] = crop_tile
		simulation.enemies[0]["hp"] = maxi(12, int(simulation.enemies[0].get("hp", 20)))
		simulation.enemies[0]["target_kind"] = "building"
		simulation.enemies[0]["target_id"] = int(farm.get("id", 0))
	simulation._begin_raid(1)
	simulation._simulate_seconds_for_test(2.8)
	guard = simulation.get_worker_by_id(int(guard.get("id", 0)))
	game.select_worker(int(guard.get("id", 0)))
	game.simulation_host.paused = true
	game._update_day_night_lighting()
	game._sync_presentation()
	game._update_ui()
	var focus: Vector3 = game.world_view.tile_to_world(Vector2(farm_tile) + Vector2(1.4, 1.1))
	game.camera_rig.compose_view(focus, 34.0)
	print("PT0810_NIGHT guard=%s raider=%s farm=%s" % [
		String(guard.get("state", "")),
		str(simulation.enemies[0].get("position", Vector2i.ZERO) if not simulation.enemies.is_empty() else Vector2i.ZERO),
		str(farm_tile)
	])
	await _capture(dest_root, "after_night_raid.png")


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
