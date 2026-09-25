extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Fixture = preload("res://src/GodotClient3D/Scripts/production_demo_fixture.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	_check(failures, game.has_node("SimulationHost"), "production GameRoot owns SimulationHost")
	_check(failures, game.has_node("PresentationAdapter"), "production GameRoot owns PresentationAdapter")
	_check(failures, game.has_node("WorldView3D/Terrain"), "real generated terrain root is present")
	_check(failures, game.has_node("WorldView3D/Roads"), "authoritative road presentation root is present")
	_check(failures, game.has_node("WorldView3D/Buildings"), "semantic building presentation root is present")
	_check(failures, game.has_node("WorldView3D/Characters"), "real worker presentation root is present")
	var simulation = game.simulation_host.simulation
	var fixture_result: Dictionary = Fixture.new().apply(simulation, "early")
	game._initialize_presentation()
	await process_frame
	var metrics: Dictionary = game.world_view.presentation_metrics()
	_check(failures, bool(fixture_result.get("success", false)), "real early-settlement fixture integrates into the scene")
	_check(failures, int(metrics.get("road_views", 0)) >= 6, "road graph creates synchronized 3D road views")
	_check(failures, int(metrics.get("building_views", 0)) >= 2, "production buildings create synchronized 3D wrappers")
	_check(failures, int(metrics.get("real_workers", 0)) == simulation.get_workers().size(), "displayed worker count comes from real simulation actors")
	var candidates: Dictionary = fixture_result.get("placement_candidates", {})
	if candidates.has(Defs.BUILDING_LUMBER_CAMP):
		var tile: Vector2i = candidates[Defs.BUILDING_LUMBER_CAMP]
		game.preview_placement_at(Defs.BUILDING_LUMBER_CAMP, tile)
		_check(failures, game.placement_ghost.visible and bool(game.placement_validation.get("success", false)), "3D placement ghost maps to authoritative valid anchor")
		var build_result: Dictionary = simulation.request_build(Defs.BUILDING_LUMBER_CAMP, tile)
		var site_id := int(Dictionary(build_result.get("building", {})).get("id", 0))
		Fixture.new()._advance_until_construction_activity(simulation, site_id, 600)
		game._sync_presentation()
		var site_view: ProductionBuildingView3D = game.world_view.building_views.get(site_id)
		_check(failures, site_view != null and site_view.is_construction, "construction state synchronizes into staged 3D wrapper")
		Fixture.new()._advance_until_complete(simulation, site_id, 1200)
		game._sync_presentation()
		site_view = game.world_view.building_views.get(site_id)
		_check(failures, site_view != null and not site_view.is_construction and site_view.building_type == Defs.BUILDING_LUMBER_CAMP, "completed construction reuses stable entity wrapper ID")
	else:
		_check(failures, false, "3D placement ghost maps to authoritative valid anchor")
	var worker_frame: Dictionary = game.presentation_adapter.capture_frame(simulation)
	var original_worker_count: int = worker_frame.get("workers", []).size()
	if not game.world_view.character_views.is_empty():
		var first_worker_id: int = int(game.world_view.character_views.keys()[0])
		var character: ProductionCharacterView3D = game.world_view.character_views[first_worker_id]
		character.set_cargo(Defs.RESOURCE_WOOD, 2)
		_check(failures, character.carried_prop != null and character.current_cargo_amount == 2, "authoritative cargo mapping attaches physical resource prop")
		character.set_cargo("", 0)
		_check(failures, character.carried_prop == null and character.current_cargo_amount == 0, "authoritative cargo removal detaches physical resource prop")
	game.world_view._sync_characters([])
	_check(failures, game.world_view.character_views.is_empty(), "entity removal snapshot removes stale character views")
	game.world_view._sync_characters(worker_frame.get("workers", []))
	_check(failures, game.world_view.character_views.size() == original_worker_count, "entity creation snapshot recreates character views by stable ID")
	game.queue_free()
	await process_frame
	_finish(failures)


func _check(failures: Array[String], condition: bool, label: String) -> void:
	print("%s %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		failures.append(label)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("PHASE2_PRODUCTION_3D_SMOKE PASS")
		quit(0)
	else:
		print("PHASE2_PRODUCTION_3D_SMOKE FAIL count=%d" % failures.size())
		quit(1)
