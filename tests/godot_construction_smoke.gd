extends SceneTree

const OneShardSimulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const MainView = preload("res://src/GodotClient/Scripts/main.gd")


func _init() -> void:
	var report: Array[String] = []
	var view = MainView.new()
	var tile := Vector2i(10, 10)
	var center: Vector2 = view.tile_to_world(tile)
	var edge: Vector2 = view._road_edge_point(center, tile, tile + Vector2i(1, 0))
	var expected_edge := center + Vector2(MainView.TILE_WIDTH * 0.25, MainView.TILE_HEIGHT * 0.25)
	var connector: PackedVector2Array = view._road_connector_polygon(center, edge, MainView.TILE_HEIGHT * 0.52)
	var passed := true
	passed = _record(report, "road geometry follows the 48x24 microtile diamond", edge.distance_to(expected_edge) < 0.01) and passed
	passed = _record(report, "road connector helper returns a valid strip", connector.size() == 4) and passed

	view.simulation = OneShardSimulation.new(70, 70, 919191, false, true)
	var hidden_enemy := {"position": view.simulation.shard_position}
	passed = _record(report, "night raiders do not reveal the hidden Shard", not view._is_enemy_visible(hidden_enemy)) and passed
	view.simulation._reveal_radius(view.simulation.shard_position, 0)
	passed = _record(report, "scouting reveals enemies for rendering and towers", view._is_enemy_visible(hidden_enemy)) and passed
	passed = _record(report, "walk cycles advance through four movement frames", view._movement_frame([tile], 0.05, 1.0) == 0 and view._movement_frame([tile], 0.55, 1.0) == 2 and view._movement_frame([tile], 0.95, 1.0) == 3) and passed
	passed = _record(report, "idle workers hold a grounded idle frame", view._movement_frame([], 0.95, 1.0) == 1) and passed
	view.simulation.rivalry.realms["rival"]["claim"]["active"] = true
	view.simulation.rivalry.realms["rival"]["claim"]["night_progress"] = OneShardSimulation.NIGHT_LENGTH_SECONDS * 0.5
	passed = _record(report, "an active rival claim overrides routine HUD messages with a danger warning", view._current_banner_text().begins_with("DANGER")) and passed

	view.camera = Camera2D.new()
	view.camera.zoom = Vector2.ONE
	view.camera.position = view.tile_to_world(view.simulation.town_hall_position)
	view.add_child(view.camera)
	var camera_before: Vector2 = view.camera.position
	view._pan_camera(Vector2.RIGHT)
	passed = _record(report, "camera controls move across the larger province", view.camera.position.x > camera_before.x) and passed
	view.free()

	for line in report:
		print(line)
	print("CONSTRUCTION_SMOKE %s" % ("PASS" if passed else "FAIL"))
	quit(0 if passed else 1)


func _record(report: Array[String], label: String, condition: bool) -> bool:
	report.append("%s %s" % ["PASS" if condition else "FAIL", label])
	return condition
