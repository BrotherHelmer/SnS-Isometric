extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Tutorial = preload("res://src/GodotClient3D/Scripts/production_access_tutorial.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Intentions = preload("res://src/GodotClient/Scripts/one_shard_intentions.gd")
const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var guide := Tutorial.new()
	var sim: Simulation = Simulation.new(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 808080, false)
	sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 808080, true)
	guide.begin_for_sim(sim)
	var first: Dictionary = guide.evaluate(sim)
	_check(String(first.get("id", "")) == Tutorial.STEP_CAMERA, "tutorial starts with the camera look")
	_check(bool(first.get("visible", false)), "tutorial is visible on a new realm")
	guide.note_camera("pan")
	guide.note_camera("zoom")
	_check(String(guide.evaluate(sim).get("id", "")) == Tutorial.STEP_CAMERA, "camera step waits for rotate too")
	guide.note_camera("rotate")
	_check(String(guide.evaluate(sim).get("id", "")) == Tutorial.STEP_ROAD, "camera look advances to a road")

	var road_tile := sim.town_hall_position + Vector2i(4, 2)
	if sim.has_method("request_build"):
		sim.request_build(Defs.BUILDING_ROAD, road_tile)
	if sim.connected_roads.size() <= guide.road_baseline:
		sim.connected_roads["%d,%d" % [road_tile.x, road_tile.y]] = true
	_check(String(guide.evaluate(sim).get("id", "")) == Tutorial.STEP_LUMBER, "a new road advances to Lumber")
	_complete_building(sim, Defs.BUILDING_LUMBER_CAMP)
	_check(String(guide.evaluate(sim).get("id", "")) == Tutorial.STEP_QUARRY, "lumber advances to Quarry")
	_complete_building(sim, Defs.BUILDING_QUARRY)
	for building in sim.buildings:
		if String(building.get("type", "")) in [Defs.BUILDING_LUMBER_CAMP, Defs.BUILDING_QUARRY]:
			building["connected"] = true
	var after_connect: Dictionary = guide.evaluate(sim)
	var after_id := String(after_connect.get("id", ""))
	_check(after_id in [Tutorial.STEP_CARRIERS, Tutorial.STEP_FOOD], "linked yards advance to carriers or food")
	if after_id == Tutorial.STEP_CARRIERS:
		_add_carrier(sim)
	_check(String(guide.evaluate(sim).get("id", "")) == Tutorial.STEP_FOOD, "a carrier advances to food")
	_complete_building(sim, Defs.BUILDING_FARM)
	_check(String(guide.evaluate(sim).get("id", "")) == Tutorial.STEP_WATCHTOWER, "a farm advances to the watchtower")
	_complete_building(sim, Defs.BUILDING_WATCHTOWER)
	var done: Dictionary = guide.evaluate(sim)
	_check(bool(done.get("done", false)) or String(done.get("id", "")) == "done", "watchtower completes the morning guide")

	var skipped := Tutorial.new()
	skipped.begin_for_sim(sim)
	skipped.skip()
	_check(not bool(skipped.evaluate(sim).get("visible", true)), "skip hides the guide")
	skipped.reopen()
	_check(bool(skipped.evaluate(sim).get("visible", false)) or skipped.enabled, "reopen turns the guide back on")

	root.size = Vector2i(1280, 720)
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.start_new_3d(game.DEFAULT_SEED)
	game._hide_start_menu()
	await process_frame
	_check(game.tutorial_overlay != null, "in-game tutorial overlay exists")
	game._skip_access_tutorial()
	_check(not game.tutorial_overlay.visible, "Skip hides the overlay")
	game._reopen_tutorial()
	game._hide_start_menu()
	game._refresh_tutorial_overlay()
	_check(game.access_tutorial.enabled, "pause menu can reopen the tutorial")
	game.queue_free()
	await process_frame
	_finish()


func _complete_building(sim, building_type: String) -> void:
	var tile: Vector2i = sim.town_hall_position + Vector2i(8, 4)
	if building_type == Defs.BUILDING_QUARRY:
		tile += Vector2i(2, 0)
		sim._set_tile(tile, Defs.TILE_ROCK)
	elif building_type == Defs.BUILDING_FARM:
		tile += Vector2i(0, 3)
	elif building_type == Defs.BUILDING_WATCHTOWER:
		tile += Vector2i(3, 3)
	var building: Dictionary = sim._create_building(building_type, tile)
	building["construction"] = false
	sim.buildings.append(building)
	Intentions.evaluate(sim)


func _add_carrier(sim) -> void:
	if sim.workers.is_empty():
		return
	var worker: Dictionary = sim.workers[0]
	worker["type"] = "carrier"
	sim.workers[0] = worker


func _finish() -> void:
	print("T_ACCESS_TUTORIAL %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
