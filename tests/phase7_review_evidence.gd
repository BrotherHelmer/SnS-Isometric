extends SceneTree

## Evidence pack for the independent review: FOW cover, opening loop, Night 2.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Wyrdfall = preload("res://src/GodotClient/Scripts/one_shard_wyrdfall.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var failures: Array[String] = []
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.start_new_3d(260821)
	await process_frame
	await process_frame
	game._update_ui()
	game._tick_minimap(0.2)

	var fog: Dictionary = game.world_view.fog_configuration()
	_check(failures, bool(fog.get("volume_mesh", false)) and bool(fog.get("exterior_opaque", false)), "FOW volume covers off-map samples")
	_check(failures, game.world_view.fog_plane != null and game.world_view.fog_skirts.size() >= 4, "FOW skirts seal the slab")
	# T-SNS-UI Look lift: the chip exists at founding but only shows when not QUIET / at night / in a raid.
	_check(failures, game.pressure_meter != null and not game.pressure_meter.visible, "pressure chip is wired at founding and hidden while QUIET")
	_check(failures, "QUIET" in game.pressure_meter.band, "opening pressure band is QUIET")
	var presentation: Dictionary = game.simulation_host.simulation.get_wyrdfall_presentation()
	_check(failures, String(presentation.get("rival_line", "")) != "", "rival line is present at t=0")
	var steps: Array = presentation.get("objective", {}).get("steps", [])
	_check(failures, "Lumber Camp" in " ".join(steps), "opening step names a Lumber Camp")
	_check(failures, game.minimap.visible, "province minimap is on")

	var sim: Simulation = Simulation.new(70, 70, 260821, false, true)
	_check(failures, sim.rivalry.get_rival_status_line() != "", "rival status is never blank")
	sim.day_count = 2
	sim.is_night = true
	sim.enemies.clear()
	sim._spawn_wave()
	_check(failures, sim.enemies.size() == 5, "Night 2 still spawns five hostiles")
	_check(failures, "from the" in String(sim.last_message), "raid names the approach bearing")
	var closest := 999
	var damaged := false
	var hp_before := _building_hp_sum(sim)
	for _second in 28:
		sim._simulate_seconds_for_test(1.0)
		for enemy in sim.enemies:
			closest = mini(closest, sim._manhattan(sim.town_hall_position, Vector2i(enemy.get("position", Vector2i.ZERO))))
		if _building_hp_sum(sim) < hp_before or _any_worker_hurt(sim):
			damaged = true
	print("EVIDENCE night2_closest=%d damaged=%s alive=%d message=%s" % [closest, str(damaged), sim.enemies.size(), sim.last_message])
	_check(failures, closest <= 4 or damaged, "Night 2 reaches or damages the yard")
	_check(failures, not sim.game_finished, "Night 2 is survivable")

	sim.phase_time = sim.DAY_LENGTH_SECONDS - 45.0
	sim.is_night = false
	sim.day_count = 1
	var dusk: Dictionary = sim.get_night_forecast()
	_check(failures, String(dusk.get("threat", "")) != "", "dusk forecast has a threat band")
	print("EVIDENCE pressure=%s rival=%s objective=%s dusk=%s fog_volume=%s screen=%s" % [
		String(presentation.get("pressure", {}).get("band", "")),
		String(presentation.get("rival_line", "")),
		String(presentation.get("objective", {}).get("title", "")),
		String(dusk.get("threat", "")),
		str(fog.get("volume_mesh", false)),
		str(game.world_view.fog_plane != null)
	])

	game.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	if failures.is_empty():
		print("PHASE7_REVIEW_EVIDENCE PASS")
		quit(0)
	else:
		for line in failures:
			print("FAIL %s" % line)
		print("PHASE7_REVIEW_EVIDENCE FAIL %d" % failures.size())
		quit(1)


func _check(failures: Array[String], ok: bool, label: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		failures.append(label)


func _building_hp_sum(sim: Simulation) -> int:
	var total := 0
	for building in sim.buildings:
		total += int(building.get("hp", 0))
	return total


func _any_worker_hurt(sim: Simulation) -> bool:
	for worker in sim.workers:
		if int(worker.get("hp", 20)) < 20:
			return true
	return false
