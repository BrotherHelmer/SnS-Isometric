extends SceneTree
const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
var failures: Array[String] = []

func _init() -> void:
	var sim = Simulation.new(70, 70, 260821, false, true)
	var site: Dictionary = sim._find_town_hall()
	site.materials_in_transit.planks = 5
	var carrier: Dictionary = sim.workers[0]
	carrier.task = {"purpose": "construction", "resource": "planks", "amount": 5, "source": "central", "destination": site.id}
	carrier.carried_resource = ""
	carrier.carried_amount = 0
	var resources: Dictionary = sim.central_inventory.duplicate()
	sim._clear_worker(carrier)
	check(site.materials_in_transit.planks == 0, "cancel before pickup releases the correct reservation")
	check(not site.materials_in_transit.has(""), "cancellation does not invent an empty resource key")
	check(sim.central_inventory == resources, "cancellation before pickup does not create resources")
	site.materials_in_transit.planks = 5
	carrier.task = {"purpose": "construction", "resource": "planks", "amount": 5, "source": "central", "destination": site.id}
	check(sim.cancel_worker_order(carrier.id).success and site.materials_in_transit.planks == 0, "public cancellation releases pending delivery")
	carrier.carried_resource = "wood"
	carrier.carried_amount = 2
	check(not sim.cancel_worker_order(carrier.id).success and carrier.carried_amount == 2, "cancel cannot discard carried goods")
	check(not sim.request_worker_order(carrier.id, sim.town_hall_position).success and carrier.carried_amount == 2, "replacement order cannot discard carried goods")
	carrier.carried_resource = ""
	carrier.carried_amount = 0
	var carriers: int = sim._carrier_count()
	for index in 3:
		var tile: Vector2i = sim._town_hall_entrance_tile() + Vector2i(4 + index, 3)
		sim._prepare_test_tile(tile, Defs.TILE_TREE)
		check(sim.request_clear(tile).get("success", false), "request temporary clearing worker")
		for tick in 1500:
			sim.advance_tick()
			if sim._clearer_count() == 0:
				break
		check(sim._clearer_count() == 0, "temporary clearer finishes and retires")
	check(sim._carrier_count() == carriers, "clearing does not accumulate zero-capacity carriers")
	var tile: Vector2i = sim._town_hall_entrance_tile() + Vector2i(7, 3)
	sim._prepare_test_tile(tile, Defs.TILE_TREE)
	sim.request_clear(tile)
	var directory := "user://logistics_safety_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory + "/realm.json"
	check(sim.save_to_path(path), "save active clearing")
	var loaded = Simulation.new(70, 70, 7, false, true)
	check(loaded.load_from_path(path), "load active clearing")
	for worker in loaded.workers:
		if worker.type == "clearer":
			check(worker.clear_target is Vector2i and worker.clear_target == tile, "clearing target survives JSON round trip")
	for tick in 1500:
		loaded.advance_tick()
		if loaded._clearer_count() == 0:
			break
	check(loaded._clearer_count() == 0, "loaded clearer continues to completion")
	var race_tile: Vector2i = loaded._town_hall_entrance_tile() + Vector2i(6, 3)
	loaded._prepare_test_tile(race_tile, Defs.TILE_TREE)
	check(loaded.request_clear(race_tile).success, "start clearing race with lumber production")
	loaded._set_tile(race_tile, Defs.TILE_GRASS)
	for tick in 1500:
		loaded.advance_tick()
		if loaded._clearer_count() == 0:
			break
	check(loaded._clearer_count() == 0, "already-harvested target releases clearing worker")
	loaded._prepare_test_tile(race_tile, Defs.TILE_TREE)
	loaded.request_clear(race_tile)
	var clear_worker: Dictionary = loaded.workers.back()
	clear_worker.carried_resource = "wood"
	clear_worker.carried_amount = 2
	clear_worker.path = []
	clear_worker.position = loaded._town_hall_entrance_tile()
	clear_worker.state = "Sheltered"
	loaded.is_night = false
	loaded.phase_time = 0.0
	loaded._update_clear_workers(0.1)
	loaded._update_clear_workers(0.1)
	check(loaded.get_tile(race_tile) == Defs.TILE_TREE and loaded._clearer_count() == 0, "resumed cargo is delivered without harvesting again")
	print("RELEASE_LOGISTICS_SAFETY %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)

func check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
