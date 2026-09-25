extends SceneTree

## Accelerated command-only player. Reads world state to choose placements;
## changes gameplay exclusively through public requests and advance_tick.
## No terrain edits, supplied resources, clock jumps or fabricated victories.
const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Tuning = preload("res://src/GodotClient/Scripts/one_shard_rivalry_tuning.gd")
const Fixture = preload("res://src/GodotClient3D/Scripts/production_demo_fixture.gd")
const SEEDS = [260821, 424242, 717171]
var reports: Array = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var selected_seeds: Array = SEEDS.duplicate()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			selected_seeds = [int(arg.trim_prefix("--seed="))]
	for seed_value in selected_seeds:
		_run_seed(seed_value)
	var file := FileAccess.open("res://artifacts/release_candidate/natural_match.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(reports, "\t"))
	file.close()
	var wins := 0
	for report in reports:
		if report.victory:
			wins += 1
	print("RELEASE_NATURAL_MATCH %s wins=%d/%d" % ["PASS" if wins == selected_seeds.size() else "FAIL", wins, selected_seeds.size()])
	quit(0 if wins == selected_seeds.size() else 1)

func _run_seed(seed_value: int) -> void:
	var sim = Simulation.new(70, 70, seed_value, false, true)
	var chooser = Fixture.new()
	var queue = [Defs.BUILDING_HOUSE, Defs.BUILDING_LUMBER_CAMP, Defs.BUILDING_FARM, Defs.BUILDING_BAKERY, Defs.BUILDING_QUARRY, Defs.BUILDING_SAWMILL, Defs.BUILDING_HOUSE, Defs.BUILDING_BARRACKS, Defs.BUILDING_WATCHTOWER, Defs.BUILDING_WATCHTOWER]
	var stage := 0
	var pending := 0
	var orders: Array = []
	var restart_checked := false
	var binding_reload := false
	for tick in 42000:
		if sim.game_finished:
			break
		if tick % 50 == 0:
			var building: Dictionary = sim.get_building_by_id(pending)
			if pending > 0 and not building.is_empty() and bool(building.get("construction", false)):
				sim.advance_tick()
				continue
			pending = 0
			if stage < queue.size():
				var type: String = queue[stage]
				var aim: Vector2i = sim.town_hall_position + (Vector2i(1, 1) if type == Defs.BUILDING_WATCHTOWER else Vector2i(7, 6))
				var site: Vector2i = chooser._find_best_site(sim, type, aim)
				if site.x >= 0:
					var result: Dictionary = sim.request_build(type, site)
					if result.get("success", false):
						pending = int(result.building.id)
						stage += 1
						orders.append({"seconds": sim.elapsed_seconds, "type": type, "tile": str(site)})
						print("NATURAL seed=%d time=%.1f built=%s" % [seed_value, sim.elapsed_seconds, type])
				elif _can_afford(sim, type):
					pending = _road(sim, chooser, sim.town_hall_position + Vector2i(11, 7))
			else:
				for target in sim.rivalry.get_structures("rival"):
					if target.type != Defs.BUILDING_OUTPOST:
						continue
					var already_ordered := false
					for guard in sim.workers:
						already_ordered = already_ordered or int(guard.get("assault_target_id", 0)) == target.id
					if not already_ordered:
						sim.request_outpost_assault(target.id)
				var ready: Dictionary = sim.rivalry.claim_requirements("player")
				if ready.get("ready", false):
					sim.request_begin_binding()
				else:
					_expand(sim, chooser, orders)
					_road(sim, chooser, sim.shard_position)
			if sim.elapsed_seconds > 700 and not restart_checked:
				var path := "res://artifacts/release_candidate/natural_%d.json" % seed_value
				if sim.save_to_path(path):
					var continued = Simulation.new(70, 70, 1, false, true)
					if continued.load_from_path(path):
						sim = continued
						restart_checked = true
			var claim: Dictionary = sim.rivalry.get_claim_status("player")
			if float(claim.get("binding_progress", 0.0)) > 30.0 and not binding_reload:
				var path := "res://artifacts/release_candidate/natural_binding_%d.json" % seed_value
				if sim.save_to_path(path):
					var continued = Simulation.new(70, 70, 1, false, true)
					if continued.load_from_path(path) and float(continued.rivalry.get_claim_status("player").get("binding_progress", 0.0)) >= 30.0:
						sim = continued
						binding_reload = true
		if tick % 6000 == 0:
			print("NATURAL progress seed=%d time=%.1f stage=%d population=%d claim=%s" % [seed_value, sim.elapsed_seconds, stage, sim.population_current, sim.rivalry.claim_requirements("player").summary])
			if tick == 18000:
				sim.save_to_path("res://artifacts/release_candidate/natural_mid_%d.json" % seed_value)
		sim.advance_tick()
	var report := {"seed": seed_value, "victory": sim.victory, "finished": sim.game_finished, "seconds": sim.elapsed_seconds, "stage": stage, "reload": restart_checked, "binding_reload": binding_reload, "reason": sim.defeat_reason, "orders": orders, "claim": sim.rivalry.claim_requirements("player"), "resources": sim.central_inventory}
	reports.append(report)
	sim.save_to_path("res://artifacts/release_candidate/natural_final_%d.json" % seed_value)
	print("NATURAL result=" + JSON.stringify(report))

func _can_afford(sim, type: String) -> bool:
	for resource in Defs.building_cost(type):
		if sim.get_available_resource(resource) < Defs.building_cost(type)[resource]:
			return false
	return true

func _road(sim, chooser, target: Vector2i) -> int:
	var plans := 0
	var tile := Vector2i(-1, -1)
	var score := INF
	for building in sim.get_buildings():
		if building.type != Defs.BUILDING_ROAD and String(building.get("planned_type", "")) != Defs.BUILDING_ROAD:
			continue
		if building.get("construction", false):
			plans += 1
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var candidate: Vector2i = building.position + direction
			var distance := float(absi(candidate.x - target.x) + absi(candidate.y - target.y))
			if distance < score and sim.validate_placement(Defs.BUILDING_ROAD, candidate).get("success", false):
				tile = candidate
				score = distance
	if plans >= 8:
		return 0
	if tile.x < 0:
		return 0
	var result: Dictionary = sim.request_build(Defs.BUILDING_ROAD, tile)
	return int(result.get("building", {}).get("id", 0))

func _expand(sim, _chooser, orders: Array) -> void:
	var requirements: Dictionary = sim.rivalry.claim_requirements("player")
	var has_claim: bool = requirements.outpost
	var wyrd_sites: Array = sim.rivalry.get_wyrd_sites()
	var structures: Array = sim.rivalry.get_structures("player")
	var lumen_sources: Array = sim.rivalry.get_lumen_sources("player")
	var closest_lumen := INF
	var harvest_outposts := 0
	for source in lumen_sources:
		closest_lumen = minf(closest_lumen, Vector2(source.center).distance_to(Vector2(sim.shard_position)))
	for structure in structures:
		if structure.type == Defs.BUILDING_OUTPOST and sim.outpost_has_wyrd_node(structure):
			harvest_outposts += 1
	for type in [Defs.BUILDING_OUTPOST, Defs.BUILDING_LUMEN_PILLAR]:
		if type == Defs.BUILDING_LUMEN_PILLAR and requirements.lumen:
			continue
		var site := Vector2i(-1, -1)
		var best := INF
		var detour_site := Vector2i(-1, -1)
		var detour_score := INF
		for key in sim.revealed_tiles:
			var parts = String(key).split(",")
			var candidate := Vector2i(int(parts[0]), int(parts[1]))
			var score := Vector2(candidate).distance_to(Vector2(sim.shard_position))
			if score >= best:
				continue
			var useful := false
			if type == Defs.BUILDING_OUTPOST:
				var center := Vector2(candidate) + Vector2(0.5, 0.5)
				for node in wyrd_sites:
					useful = useful or (harvest_outposts < 2 and center.distance_to(Vector2(node.position)) <= sim.WYRD_OUTPOST_HARVEST_RADIUS)
				var claim_site := not has_claim and center.distance_to(Vector2(sim.shard_position)) <= Tuning.SHARD_BUILD_RADIUS
				useful = useful or claim_site
				for outpost in structures:
					if not claim_site and outpost.type == type and center.distance_to(Vector2(outpost.position) + Vector2(0.5, 0.5)) < 5.0:
						useful = false
			else:
				useful = score < closest_lumen - 1.0
				var spaced := true
				for source in lumen_sources:
					if Vector2(candidate).distance_to(Vector2(source.center)) < 4.0:
						useful = false
						spaced = false
				# Roads may initially leave home on the side away from the Shard.
				# A valid detour Pillar can carry Lumen around the occupied yard.
				if spaced and score < detour_score and sim.validate_placement(type, candidate).get("success", false):
					detour_site = candidate
					detour_score = score
			if useful and sim.validate_placement(type, candidate).get("success", false):
				site = candidate
				best = score
		if site.x < 0 and type == Defs.BUILDING_LUMEN_PILLAR:
			# Clear a useful forward site before spending Wyrd on a detour.
			if _can_afford(sim, type) and _clear_lumen_site(sim, lumen_sources, closest_lumen, orders):
				continue
			site = detour_site
		if site.x >= 0:
			var result: Dictionary = sim.request_build(type, site)
			if result.get("success", false):
				orders.append({"seconds": sim.elapsed_seconds, "type": type, "tile": str(site)})
				print("NATURAL seed=%d time=%.1f built=%s tile=%s" % [sim.rng_seed, sim.elapsed_seconds, type, site])

func _clear_lumen_site(sim, sources: Array, closest_lumen: float, orders: Array) -> bool:
	var best := INF
	var candidate := Vector2i(-1, -1)
	for road in sim.rivalry.get_roads("player"):
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var tile: Vector2i = road + direction
			var distance := Vector2(tile).distance_to(Vector2(sim.shard_position))
			if distance >= closest_lumen - 1.0 or distance >= best or sim.get_tile(tile) not in [Defs.TILE_TREE, Defs.TILE_ROCK]:
				continue
			var covered := false
			var spaced := true
			for source in sources:
				covered = covered or Vector2(tile).distance_to(Vector2(source.center)) <= source.radius
				spaced = spaced and Vector2(tile).distance_to(Vector2(source.center)) >= 4.0
			if not spaced:
				continue
			if covered:
				for worker in sim.workers:
					if worker.get("clear_target", Vector2i(-1, -1)) == tile:
						return true
			if covered and sim.validate_clear(tile).get("success", false):
				candidate = tile
				best = distance
	if candidate.x >= 0 and sim.request_clear(candidate).get("success", false):
		orders.append({"seconds": sim.elapsed_seconds, "type": "CLEAR_FOR_LUMEN", "tile": str(candidate)})
		return true
	return false
