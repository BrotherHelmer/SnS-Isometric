extends SceneTree

## Focused prepared-state combat regression, not natural-match evidence.
const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var sim = Simulation.new(70, 70, 260821, false, true)
	var tile: Vector2i = sim._town_hall_entrance_tile() + Vector2i(8, -2)
	for y in range(tile.y - 2, tile.y + 4):
		for x in range(tile.x - 2, tile.x + 4):
			sim._prepare_test_tile(Vector2i(x, y), Defs.TILE_GRASS)
	var target: Dictionary = {"id": sim.rivalry.next_structure_id, "type": Defs.BUILDING_OUTPOST, "realm_id": "rival", "position": tile, "footprint": Vector2i(2, 2), "hp": 220, "max_hp": 220, "active": true, "connected": true}
	sim.rivalry.next_structure_id += 1
	sim.rivalry.structures.append(target)
	sim.rivalry.realms.rival.structures.append(target.id)
	sim.rivalry.realms.rival.claim.outpost_id = target.id
	check(not sim.request_outpost_assault(target.id).success, "assault needs trained patrol soldiers")
	sim.soldiers_total = 2
	sim._sync_production_workers()
	check(not sim.request_outpost_assault(99999).success, "unknown target rejected")
	target.realm_id = "player"
	check(not sim.request_outpost_assault(target.id).success, "friendly Outpost rejected")
	target.realm_id = "rival"
	sim.revealed_tiles.erase(sim._tile_key(tile))
	check(not sim.request_outpost_assault(target.id).success, "hidden Outpost rejected")
	sim._reveal_radius(tile, 3)
	check(sim.request_outpost_assault(target.id).success, "visible rival Outpost receives assault order")
	sim.advance_tick()
	check(target.hp == 220, "remote order does not apply instant damage")
	for tick in 1500:
		sim.advance_tick()
		if target.hp < 220:
			break
	check(target.hp > 0 and target.hp < 220, "soldiers travel and strike in range")
	var path := "user://assault_resume.json"
	check(sim.save_to_path(path), "save mid-assault")
	var loaded = Simulation.new(70, 70, 1, false, true)
	check(loaded.load_from_path(path), "reload mid-assault")
	var orders := 0
	for guard in loaded.workers:
		if int(guard.get("assault_target_id", 0)) == target.id:
			orders += 1
	check(orders == 2, "assault orders survive disk reload")
	loaded.recall_assault_soldiers()
	for guard in loaded.workers:
		check(int(guard.get("assault_target_id", 0)) == 0, "recall clears assault order")
	check(loaded.request_outpost_assault(target.id).success, "reissue assault after recall")
	for tick in 1500:
		loaded.advance_tick()
		if loaded.rivalry._structure_by_id(target.id).is_empty():
			break
	check(loaded.rivalry._structure_by_id(target.id).is_empty(), "sustained soldier strikes destroy rival Outpost")
	check(int(loaded.rivalry.realms.rival.claim.outpost_id) == 0, "destroyed Outpost releases rival claim")
	check(not loaded.request_outpost_assault(target.id).success, "destroyed target cannot be attacked again")
	var game = Scene.instantiate()
	root.add_child(game)
	await process_frame
	game._start_review_seed()
	game.simulation_host.simulation = sim
	sim.recall_assault_soldiers()
	game._initialize_presentation()
	for snapshot in game.current_frame_snapshot.rivalry_structures:
		if int(snapshot.get("authority_id", 0)) == target.id:
			game.select_semantic_entity("rivalry_structure", snapshot.id, true)
	await process_frame
	check(game.assault_button.visible, "selected rival Outpost exposes assault button")
	game.assault_button.pressed.emit()
	var commanded := 0
	for guard in sim.workers:
		if int(guard.get("assault_target_id", 0)) == target.id:
			commanded += 1
	check(commanded == 2, "UI maps presentation identifier to authoritative assault target")
	game.recall_button.pressed.emit()
	for guard in sim.workers:
		check(int(guard.get("assault_target_id", 0)) == 0, "UI recall clears assault")
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/release_candidate/assault_inspector.png")
	game.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	print("RELEASE_OUTPOST_ASSAULT %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)

func check(ok: bool, label: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		failures.append(label)
