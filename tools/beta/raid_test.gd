extends SceneTree
# R28 raid scenario: soldiers must engage raiders on their own, and obey
# manual move / attack orders. Prints RAID_TEST PASS|FAIL lines; exit 0/1.
const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
var fails := 0


func _tile_at_distance(sim, origin: Vector2i, want: int) -> Vector2i:
	for r in range(want, want + 6):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var t := origin + Vector2i(dx, dy)
				if sim.is_inside_map(t) and sim.is_revealed(t) and String(sim.get_tile(t)) == "GRASS" and not sim.is_tile_occupied(t) and not sim._find_worker_path(origin, t).is_empty():
					return t
	return Vector2i(-1, -1)


func _check(name: String, ok: bool, detail: String) -> void:
	print("RAID_TEST %s %s  %s" % ["PASS" if ok else "FAIL", name, detail])
	if not ok:
		fails += 1


func _fresh(seed_value: int):
	var sim = Simulation.new(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, seed_value, true, true)
	sim._simulate_seconds_for_test(25.0)
	sim.enemies.clear()
	# A real patrol soldier: raise the soldier count and let worker sync create him.
	sim.soldiers_total += 1
	sim._sync_production_workers()
	var guard: Dictionary = {}
	for w in sim.workers:
		if String(w.get("type", "")) == "guard" and int(w.get("building_id", 0)) == 0:
			guard = w
	guard["position"] = sim._town_hall_entrance_tile()
	guard["path"] = []
	return [sim, guard]


func _run_until(sim, secs: float, done: Callable) -> float:
	var t := 0.0
	while t < secs:
		sim._simulate_seconds_for_test(0.2)
		t += 0.2
		if done.call():
			return t
	return -1.0


func _init() -> void:
	for seed_value in [11, 4242, 1792050449]:
		# A) auto-engage a raider 6 tiles away
		var pair = _fresh(seed_value)
		var sim = pair[0]
		var guard: Dictionary = pair[1]
		var spot := _tile_at_distance(sim, guard.position, 6)
		sim._spawn_enemy(spot, 40, 1, 0.0)
		var enemy: Dictionary = sim.enemies[0]
		enemy["speed_multiplier"] = 100000.0  # holds position, like a raider besieging a building
		var hp0 := int(enemy.hp)
		var took := _run_until(sim, 25.0, func() -> bool: return int(enemy.hp) < hp0 or not sim.enemies.has(enemy))
		_check("auto_engage seed=%d" % seed_value, took >= 0.0, "raider at %s dist6, hp %d->%d in %.1fs, guard=%s" % [spot, hp0, int(enemy.hp), took, String(guard.get("state", ""))])
		# B) manual move
		pair = _fresh(seed_value)
		sim = pair[0]
		guard = pair[1]
		var dest := _tile_at_distance(sim, guard.position, 5)
		var res: Dictionary = sim.request_worker_order(int(guard.id), dest)
		took = _run_until(sim, 20.0, func() -> bool: return Vector2i(guard.position) == dest)
		_check("manual_move seed=%d" % seed_value, bool(res.get("success", res.get("ok", false))) and took >= 0.0, "to %s res=%s arrived=%.1fs" % [dest, str(res.get("message", "")), took])
		# C) manual attack beyond the defence radius
		pair = _fresh(seed_value)
		sim = pair[0]
		guard = pair[1]
		spot = _tile_at_distance(sim, guard.position, 13)
		sim._spawn_enemy(spot, 40, 1, 0.0)
		enemy = sim.enemies[0]
		enemy["speed_multiplier"] = 100000.0
		hp0 = int(enemy.hp)
		res = sim.request_attack_order(int(guard.id), int(enemy.id))
		took = _run_until(sim, 40.0, func() -> bool: return int(enemy.hp) < hp0 or not sim.enemies.has(enemy))
		_check("manual_attack seed=%d" % seed_value, took >= 0.0, "raider at %s dist13, res=%s hp %d->%d in %.1fs" % [spot, str(res.get("message", "")), hp0, int(enemy.hp), took])
	print("RAID_TEST %s fails=%d" % ["ALL PASS" if fails == 0 else "FAILED", fails])
	quit(0 if fails == 0 else 1)
