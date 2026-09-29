extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Tuning = preload("res://src/GodotClient/Scripts/one_shard_rivalry_tuning.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Wyrdfall = preload("res://src/GodotClient/Scripts/one_shard_wyrdfall.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var failures: Array[String] = []
	if game.audio_director == null:
		failures.append("audio director missing")
	else:
		game._show_start_menu()
		game._tick_audio(0.4)
		_expect_state(game, "menu", failures)
		game.start_new_3d(game.DEFAULT_SEED)
		var simulation = game.simulation_host.simulation
		simulation.phase_time = 40.0
		simulation.is_night = false
		game._tick_audio(0.4)
		_expect_state(game, "day", failures)
		simulation.phase_time = simulation.DAY_LENGTH_SECONDS - 20.0
		game._tick_audio(0.4)
		_expect_state(game, "dusk", failures)
		simulation.is_night = true
		simulation.phase_time = 20.0
		game._tick_audio(0.4)
		_expect_state(game, "night", failures)
		simulation.enemies.clear()
		simulation.day_count = 4
		simulation._spawn_wave()
		simulation._note_combat()
		game._tick_audio(0.4)
		_expect_state(game, "raid", failures)
		_configure_ready_claim(simulation, simulation.rivalry, Tuning.PLAYER_REALM)
		simulation.request_begin_binding()
		game._tick_audio(0.4)
		_expect_state(game, "reckoning", failures)
		simulation._finish_run(true, "SHARD BOUND")
		game._show_result_screen()
		game._tick_audio(0.4)
		_expect_state(game, "victory", failures)
		game.result_overlay.visible = false
		game.start_new_3d(game.DEFAULT_SEED)
		simulation = game.simulation_host.simulation
		simulation._finish_run(false, "The rival bound the Shard first.")
		game._show_result_screen()
		game._tick_audio(0.4)
		_expect_state(game, "defeat", failures)
		var snapshot: Dictionary = game.audio_director.evidence_snapshot()
		print("PHASE41_AUDIO_EVIDENCE %s" % JSON.stringify(snapshot))
	if failures.is_empty():
		print("PHASE41_AUDIO_EVIDENCE PASS")
		quit(0)
	else:
		push_error("PHASE41_AUDIO_EVIDENCE FAIL %s" % "; ".join(failures))
		quit(1)


func _expect_state(game, expected: String, failures: Array[String]) -> void:
	var actual := String(game.audio_director.current_state)
	if actual != expected:
		failures.append("expected %s got %s" % [expected, actual])
	print("PHASE41_AUDIO_STATE %s stems=%s" % [actual, ",".join(game.audio_director.evidence_snapshot().get("stems", []))])


func _configure_ready_claim(simulation, rivalry, realm_id: String) -> void:
	var realm: Dictionary = rivalry.realms[realm_id]
	var entrance: Vector2i = realm["entrance"]
	var outpost_anchor: Vector2i = simulation.shard_position + Vector2i(-4, 0)
	var road_target: Vector2i = outpost_anchor + Vector2i.LEFT
	var current := entrance
	while current.x != road_target.x:
		current += Vector2i(1 if road_target.x > current.x else -1, 0)
		realm["roads"][rivalry._key(current)] = true
	while current.y != road_target.y:
		current += Vector2i(0, 1 if road_target.y > current.y else -1)
		realm["roads"][rivalry._key(current)] = true
	var home_center: Vector2 = rivalry._home_center(realm_id)
	for fraction in [0.18, 0.36, 0.54, 0.72, 0.88]:
		var pillar_position: Vector2i = Vector2i(home_center.lerp(Vector2(simulation.shard_position), float(fraction)))
		var pillar: Dictionary = {
			"id": rivalry.next_structure_id,
			"realm_id": realm_id,
			"type": Tuning.STRUCTURE_LUMEN_PILLAR,
			"position": pillar_position,
			"footprint": Vector2i.ONE,
			"hp": 90,
			"max_hp": 90,
			"active": true,
			"connected": true,
			"damage_flash": 0.0
		}
		rivalry.next_structure_id += 1
		rivalry.structures.append(pillar)
		realm["structures"].append(pillar["id"])
	var outpost: Dictionary = {
		"id": rivalry.next_structure_id,
		"realm_id": realm_id,
		"type": Tuning.STRUCTURE_CLAIMANT_OUTPOST,
		"position": outpost_anchor,
		"footprint": Vector2i(2, 2),
		"hp": 220,
		"max_hp": 220,
		"active": true,
		"connected": true,
		"damage_flash": 0.0
	}
	rivalry.next_structure_id += 1
	rivalry.structures.append(outpost)
	realm["structures"].append(outpost["id"])
	realm["claim"]["outpost_id"] = outpost["id"]
	rivalry.get_resources(realm_id)[Defs.RESOURCE_WYRD] = 100
	simulation._reveal_radius(outpost_anchor, 6)
