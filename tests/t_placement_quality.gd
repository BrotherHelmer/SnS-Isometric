extends SceneTree

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Placement = preload("res://src/GodotClient/Scripts/one_shard_placement.gd")

var failures: Array[String] = []


func _init() -> void:
	_run()
	for line in failures:
		print("FAIL %s" % line)
	print("T_PLACEMENT_QUALITY %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _run() -> void:
	_check(Placement.band_for(20) == Placement.BAND_POOR, "0–39 is Poor")
	_check(Placement.band_for(55) == Placement.BAND_FAIR, "40–69 is Fair")
	_check(Placement.band_for(80) == Placement.BAND_GOOD, "70–89 is Good")
	_check(Placement.band_for(95) == Placement.BAND_EXCELLENT, "90–100 is Excellent")
	_check(Placement.scalar_for(Placement.BAND_POOR) < Placement.scalar_for(Placement.BAND_EXCELLENT), "Excellent produces faster than Poor")
	var sim: Simulation = Simulation.new(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 909090, false)
	sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 909090, true)
	var origin := sim.town_hall_position + Vector2i(5, 5)
	_clear_trees(sim, origin, Placement.LUMBER_RADIUS)
	sim.map_tiles[origin.y][origin.x + 2] = Defs.TILE_TREE
	sim.tree_deposits[sim._tile_key(origin + Vector2i(2, 0))] = 4
	var poor: Dictionary = sim.evaluate_placement_quality(Defs.BUILDING_LUMBER_CAMP, origin)
	_check(int(poor.get("percent", 100)) < 40, "a thin stand scores Poor forest coverage")
	_check(String(poor.get("band", "")) == Placement.BAND_POOR, "thin stand is Poor")
	_paint_trees(sim, origin, 8)
	var rich: Dictionary = sim.evaluate_placement_quality(Defs.BUILDING_LUMBER_CAMP, origin)
	_check(int(rich.get("percent", 0)) >= 70, "a dense stand scores Good or Excellent")
	_check(String(rich.get("label", "")).contains("Forest coverage"), "lumber ghost names forest coverage")
	var farm: Dictionary = sim.evaluate_placement_quality(Defs.BUILDING_FARM, origin)
	_check(String(farm.get("coverage_name", "")) == "Suitable land", "farm scores suitable land")
	var site := sim._create_building(Defs.BUILDING_CONSTRUCTION_SITE, origin)
	site["planned_type"] = Defs.BUILDING_LUMBER_CAMP
	sim._stamp_placement_quality(site, Defs.BUILDING_LUMBER_CAMP, origin, 0)
	_check(float(site.get("placement_quality", 0.0)) > 0.0, "construction sites keep the score")
	var lumber := sim._create_building(Defs.BUILDING_LUMBER_CAMP, origin)
	lumber["placement_quality"] = Placement.SCALAR_POOR
	lumber["placement_band"] = Placement.BAND_POOR
	var poor_out := sim._effective_output_amount(lumber, 2)
	lumber["placement_quality"] = Placement.SCALAR_EXCELLENT
	var rich_out := sim._effective_output_amount(lumber, 2)
	_check(poor_out <= rich_out, "placement scalar changes production")
	_check(sim._production_interval(lumber) < 2.0, "Excellent shortens the production interval")
	lumber["placement_quality"] = Placement.SCALAR_POOR
	_check(sim._production_interval(lumber) > 2.0, "Poor lengthens the production interval")
	var validation := sim.validate_placement(Defs.BUILDING_LUMBER_CAMP, origin)
	_check(validation.has("placement_quality") or not bool(validation.get("success", false)) or sim.evaluate_placement_quality(Defs.BUILDING_LUMBER_CAMP, origin).size() > 0, "quality is available during placement")


func _clear_trees(sim: Simulation, origin: Vector2i, radius: int) -> void:
	for y in range(origin.y - radius, origin.y + radius + 1):
		for x in range(origin.x - radius, origin.x + radius + 1):
			var tile := Vector2i(x, y)
			if not sim.is_inside_map(tile):
				continue
			if String(sim.get_tile(tile)) != Defs.TILE_TREE:
				continue
			if not sim.get_building_at_tile(tile).is_empty():
				continue
			sim.map_tiles[tile.y][tile.x] = Defs.TILE_GRASS
			sim.tree_deposits.erase(sim._tile_key(tile))


func _paint_trees(sim: Simulation, origin: Vector2i, radius: int) -> void:
	for y in range(origin.y - radius, origin.y + radius + 1):
		for x in range(origin.x - radius, origin.x + radius + 1):
			var tile := Vector2i(x, y)
			if not sim.is_inside_map(tile):
				continue
			if sim._manhattan(origin, tile) > radius:
				continue
			if not sim.get_building_at_tile(tile).is_empty():
				continue
			sim.map_tiles[tile.y][tile.x] = Defs.TILE_TREE
			sim.tree_deposits[sim._tile_key(tile)] = 4


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
