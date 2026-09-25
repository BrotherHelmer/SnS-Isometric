extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Fixture = preload("res://src/GodotClient3D/Scripts/production_demo_fixture.gd")

const SAVE_PATH := "res://artifacts/phase2/persistence/demo_playthrough.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/phase2/persistence"))
	var failures: Array[String] = []
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	var simulation = game.simulation_host.simulation
	print("DEMO_STEP 01 launch production 3D seed=%d" % simulation.rng_seed)
	var fixture := Fixture.new()
	var early: Dictionary = fixture.apply(simulation, "early")
	_check(failures, bool(early.get("success", false)), "start deterministic real-settlement fixture")
	game._initialize_presentation()
	print("DEMO_STEP 02 pan/focus fixed production camera")
	var town_id := 0
	for building in simulation.get_buildings():
		if String(building.get("type", "")) == Defs.BUILDING_TOWN_HALL:
			town_id = int(building.get("id", 0))
			break
	game.select_building(town_id)
	game.camera_rig.focus_world(game.world_view.focus_for_building(town_id))
	_check(failures, game.selected_building_id == town_id, "select and inspect real Town Hall")
	print("DEMO_STEP 03 select Town Hall id=%d" % town_id)
	var lumber_tile: Vector2i = Dictionary(early.get("placement_candidates", {})).get(Defs.BUILDING_LUMBER_CAMP, Vector2i(-1, -1))
	game.preview_placement_at(Defs.BUILDING_LUMBER_CAMP, lumber_tile)
	_check(failures, bool(game.placement_validation.get("success", false)), "preview Lumber Camp with authoritative validation")
	print("DEMO_STEP 04 placement ghost anchor=%s valid=%s" % [lumber_tile, game.placement_validation.get("success", false)])
	var build_result: Dictionary = simulation.request_build(Defs.BUILDING_LUMBER_CAMP, lumber_tile)
	_check(failures, bool(build_result.get("success", false)), "place Lumber Camp through request_build")
	var lumber_id := int(Dictionary(build_result.get("building", {})).get("id", 0))
	fixture._advance_until_construction_activity(simulation, lumber_id, 600)
	var active_site: Dictionary = simulation.get_building_by_id(lumber_id)
	_check(failures, bool(active_site.get("construction", false)), "observe active real construction site")
	print("DEMO_STEP 05 construction site id=%d delivered=%s" % [lumber_id, active_site.get("materials_delivered", {})])
	fixture._advance_until_complete(simulation, lumber_id, 1200)
	fixture._advance_until_cargo_or_output(simulation, Defs.RESOURCE_WOOD, lumber_id, 1400)
	var wood_cargo_seen := _has_cargo(simulation, Defs.RESOURCE_WOOD)
	var lumber_building: Dictionary = simulation.get_building_by_id(lumber_id)
	var lumber_output := int(lumber_building.get("local_inventory", {}).get(Defs.RESOURCE_WOOD, 0))
	_check(failures, wood_cargo_seen or lumber_output > 0, "observe real lumber output and carrier logistics")
	print("DEMO_STEP 06 lumber output=%d physical_cargo=%s resources=%s" % [lumber_output, wood_cargo_seen, simulation.get_resources()])
	var road_count := _completed_count(simulation, Defs.BUILDING_ROAD)
	_check(failures, road_count >= 6, "inspect synchronized road network")
	print("DEMO_STEP 07 road graph completed_cells=%d" % road_count)
	var farm_tile: Vector2i = fixture._ensure_site(simulation, Defs.BUILDING_FARM, simulation.town_hall_position + Vector2i(7, 9))
	var farm_id := fixture._request_and_complete(simulation, Defs.BUILDING_FARM, farm_tile)
	fixture._advance_until_cargo_or_output(simulation, Defs.RESOURCE_WHEAT, farm_id, 1800)
	var farm: Dictionary = simulation.get_building_by_id(farm_id)
	var wheat_output := int(farm.get("local_inventory", {}).get(Defs.RESOURCE_WHEAT, 0))
	_check(failures, farm_id > 0 and (_has_cargo(simulation, Defs.RESOURCE_WHEAT) or wheat_output > 0), "observe second real farm production chain")
	print("DEMO_STEP 08 farm id=%d wheat=%d" % [farm_id, wheat_output])
	var before_save_buildings: int = simulation.get_buildings().size()
	var before_save_resources: Dictionary = simulation.get_resources()
	var saved: bool = game.simulation_host.save_to_path(SAVE_PATH)
	_check(failures, saved, "save changed production settlement")
	print("DEMO_STEP 09 save path=%s" % SAVE_PATH)
	game.simulation_host.start_new(77, true)
	var loaded: bool = game.simulation_host.load_from_path(SAVE_PATH)
	_check(failures, loaded, "exit/reload through production persistence path")
	game._initialize_presentation()
	await process_frame
	var reloaded_simulation = game.simulation_host.simulation
	_check(failures, reloaded_simulation.get_buildings().size() == before_save_buildings, "reloaded building authority matches saved settlement")
	_check(failures, reloaded_simulation.get_resources() == before_save_resources, "reloaded inventories match saved settlement")
	var expected_views := _expected_view_count(reloaded_simulation)
	_check(failures, game.world_view.building_views.size() + game.world_view.road_views.size() == expected_views, "3D entity views reconstruct after reload")
	print("DEMO_STEP 10 reload buildings=%d workers=%d view_entities=%d" % [
		reloaded_simulation.get_buildings().size(),
		reloaded_simulation.get_workers().size(),
		game.world_view.building_views.size() + game.world_view.road_views.size(),
	])
	game.queue_free()
	await process_frame
	_finish(failures)


func _has_cargo(simulation, resource_type: String) -> bool:
	for worker in simulation.get_workers():
		if String(worker.get("carried_resource", "")) == resource_type and int(worker.get("carried_amount", 0)) > 0:
			return true
	return false


func _completed_count(simulation, building_type: String) -> int:
	var count := 0
	for building in simulation.get_buildings():
		if String(building.get("type", "")) == building_type and not bool(building.get("construction", false)):
			count += 1
	return count


func _expected_view_count(simulation) -> int:
	var non_road := 0
	var road_tiles: Dictionary = {}
	for building in simulation.get_buildings():
		var type_name := String(building.get("planned_type", "")) if bool(building.get("construction", false)) else String(building.get("type", ""))
		if type_name == Defs.BUILDING_ROAD:
			var tile: Vector2i = building.get("position", Vector2i.ZERO)
			road_tiles["%d,%d" % [tile.x, tile.y]] = true
		else:
			non_road += 1
	return non_road + road_tiles.size()


func _check(failures: Array[String], condition: bool, label: String) -> void:
	print("%s %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		failures.append(label)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("PHASE2_DEMO_PLAYTHROUGH PASS")
		quit(0)
	else:
		print("PHASE2_DEMO_PLAYTHROUGH FAIL count=%d" % failures.size())
		quit(1)
