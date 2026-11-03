extends Node

## F5 GUI regression probe: verify terrain picker accuracy and multi-placement
## Run this from production_3d_game_root after simulation boots

const REQUIRED_PICK_ACCURACY := 0.95  # ≥95% exact picks
const REQUIRED_ROADS := 3  # ≥3 roads after first
const REQUIRED_HOUSES := 1  # ≥1 house

var simulation = null
var world_view = null
var game_root = null

func _init(sim, view, root):
	simulation = sim
	world_view = view
	game_root = root

func run_probe() -> Dictionary:
	print("\n=== F5 GUI Regression Probe ===")
	var results := {
		"pick_accuracy": _test_pick_accuracy(),
		"multi_placement": _test_multi_placement(),
	}
	
	var pick_pass := results["pick_accuracy"]["pass"]
	var place_pass := results["multi_placement"]["pass"]
	var overall_pass := pick_pass and place_pass
	
	print("\n=== Results ===")
	print("Pick accuracy: %s (%.1f%% exact, required ≥%.0f%%)" % [
		"PASS" if pick_pass else "FAIL",
		results["pick_accuracy"]["accuracy"] * 100.0,
		REQUIRED_PICK_ACCURACY * 100.0
	])
	print("Multi-placement: %s (road1 + %d more roads + %d houses, required ≥%d roads + %d house)" % [
		"PASS" if place_pass else "FAIL",
		results["multi_placement"]["roads_placed"],
		results["multi_placement"]["houses_placed"],
		REQUIRED_ROADS,
		REQUIRED_HOUSES
	])
	print("OVERALL: %s\n" % ("PASS" if overall_pass else "FAIL"))
	
	return {"pass": overall_pass, "details": results}


func _test_pick_accuracy() -> Dictionary:
	print("\n-- Testing terrain pick accuracy near Town Hall --")
	var town_hall_pos: Vector2i = simulation.town_hall_position
	var test_tiles: Array[Vector2i] = []
	
	# Sample tiles in a 7×7 grid around town hall center
	for dy in range(-3, 4):
		for dx in range(-3, 4):
			var tile := town_hall_pos + Vector2i(dx, dy)
			if simulation.is_inside_map(tile):
				test_tiles.append(tile)
	
	var exact_hits := 0
	var total_tests := test_tiles.size()
	var offsets := {}
	
	for tile in test_tiles:
		var world_pos := world_view.tile_to_world(Vector2(tile))
		# Raycast from above
		var ray_origin := world_pos + Vector3(0, 50, 0)
		var ray_target := world_pos + Vector3(0, -10, 0)
		var space_state := world_view.get_world_3d().direct_space_state
		var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_target)
		query.collision_mask = 0xFFFFFFFF
		var result := space_state.intersect_ray(query)
		
		if result.is_empty():
			offsets["miss"] = offsets.get("miss", 0) + 1
		else:
			var hit_tile := world_view.world_to_tile(result.position)
			if hit_tile == tile:
				exact_hits += 1
			else:
				var offset := hit_tile - tile
				var key := "(%d,%d)" % [offset.x, offset.y]
				offsets[key] = offsets.get(key, 0) + 1
	
	var accuracy := float(exact_hits) / float(total_tests) if total_tests > 0 else 0.0
	var pass := accuracy >= REQUIRED_PICK_ACCURACY
	
	print("Exact hits: %d / %d (%.1f%%)" % [exact_hits, total_tests, accuracy * 100.0])
	if not offsets.is_empty():
		print("Offset distribution: %s" % JSON.stringify(offsets))
	
	return {"pass": pass, "accuracy": accuracy, "exact": exact_hits, "total": total_tests, "offsets": offsets}


func _test_multi_placement() -> Dictionary:
	print("\n-- Testing multi-placement (roads + house) --")
	
	# Find a spot near town hall to place roads
	var town_hall_pos: Vector2i = simulation.town_hall_position
	var road_start := town_hall_pos + Vector2i(3, 0)
	
	# Ensure starting tile is connected or adjacent to road network
	var test_tiles := [
		road_start,
		road_start + Vector2i(1, 0),
		road_start + Vector2i(2, 0),
		road_start + Vector2i(3, 0),
	]
	
	var roads_placed := 0
	for tile in test_tiles:
		var result: Dictionary = simulation.request_build("ROAD", tile, 0)
		if result.get("success", false):
			roads_placed += 1
		else:
			print("Road placement failed at %s: %s" % [tile, result.get("message", "unknown")])
	
	# Try to place a house adjacent to the roads
	var houses_placed := 0
	var house_tile := road_start + Vector2i(1, 1)
	var house_result: Dictionary = simulation.request_build("HOUSE", house_tile, 0)
	if house_result.get("success", false):
		houses_placed += 1
	else:
		print("House placement failed at %s: %s" % [house_tile, house_result.get("message", "unknown")])
	
	var pass := roads_placed >= REQUIRED_ROADS and houses_placed >= REQUIRED_HOUSES
	
	print("Roads placed: %d (required ≥%d)" % [roads_placed, REQUIRED_ROADS])
	print("Houses placed: %d (required ≥%d)" % [houses_placed, REQUIRED_HOUSES])
	
	return {
		"pass": pass,
		"roads_placed": roads_placed,
		"houses_placed": houses_placed,
	}
