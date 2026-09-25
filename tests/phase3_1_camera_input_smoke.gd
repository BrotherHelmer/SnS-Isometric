extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Fixture = preload("res://src/GodotClient3D/Scripts/production_demo_fixture.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")

const VIEWPORT_SIZE := Vector2i(1920, 1080)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = VIEWPORT_SIZE
	var failures: Array[String] = []
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var new_button := game.startup_overlay.find_child("NewReviewSeed", true, false) as Button
	new_button.pressed.emit()
	await process_frame
	await process_frame
	_check(failures, not game.startup_overlay.visible and game.camera_rig.input_enabled, "New Settlement transition enables camera input")

	game.selected_building_id = 0
	game.selected_worker_id = 0
	game.selected_entity_kind = ""
	game._update_inspector()
	var first_position: Vector3 = game.camera_rig.position
	var first_generation: int = game.camera_rig.pan_generation
	await _middle_drag(Vector2(940, 510), Vector2(820, 575))
	_check(failures, game.camera_rig.pan_generation > first_generation and game.camera_rig.last_pan_source == "middle_drag", "actual middle-button drag reaches the camera after New Settlement")
	_check(failures, game.camera_rig.position.distance_to(first_position) > 0.05, "middle drag changes the actual viewport camera position immediately")

	var left_start: Vector3 = game.camera_rig.position
	var left_generation: int = game.camera_rig.pan_generation
	await _left_drag(game, Vector2(940, 510), Vector2(800, 590))
	_check(failures, game.camera_rig.pan_generation > left_generation and game.camera_rig.last_pan_source == "pointer_drag", "hold-and-drag left mouse pans the map")
	_check(failures, game.camera_rig.position.distance_to(left_start) > 0.05, "left-mouse drag changes the viewport camera position")

	var arrow_start: Vector3 = game.camera_rig.target_position
	var key_down := InputEventKey.new()
	key_down.keycode = KEY_RIGHT
	key_down.physical_keycode = KEY_RIGHT
	key_down.pressed = true
	Input.parse_input_event(key_down)
	for _frame in 6:
		await process_frame
	var key_up := InputEventKey.new()
	key_up.keycode = KEY_RIGHT
	key_up.physical_keycode = KEY_RIGHT
	key_up.pressed = false
	Input.parse_input_event(key_up)
	await process_frame
	_check(failures, game.camera_rig.last_pan_source == "keyboard" and game.camera_rig.target_position.distance_to(arrow_start) > 0.01, "actual arrow-key state pans the map independently of Sovereign WASD")

	var fixture := Fixture.new()
	var developed: Dictionary = fixture.apply(game.simulation_host.simulation, "developed")
	_check(failures, bool(developed.get("success", false)), "building-selected camera input test has a developed settlement")
	game._initialize_presentation()
	var selected := _first_completed_non_road(game.simulation_host.simulation)
	game.select_building(int(selected.get("id", 0)))
	await process_frame
	_check(failures, game.inspector_panel.visible, "building selection opens the compact inspector")
	var inspector_pan_start: Vector3 = game.camera_rig.position
	await _middle_drag(Vector2(1740, 210), Vector2(1665, 265))
	_check(failures, game.camera_rig.position.distance_to(inspector_pan_start) > 0.05 and game.inspector_panel.visible, "middle drag pans even when begun over an open inspector")

	game._set_build_palette_visible(true)
	game.begin_placement(Defs.BUILDING_HOUSE)
	var build_pan_start: Vector3 = game.camera_rig.position
	await _middle_drag(Vector2(185, 310), Vector2(245, 365))
	_check(failures, game.camera_rig.position.distance_to(build_pan_start) > 0.05 and game.placement_type == Defs.BUILDING_HOUSE, "camera middle drag remains available while the build palette and placement tool are open")
	game.cancel_placement()
	game._set_build_palette_visible(false)
	var return_pan_start: Vector3 = game.camera_rig.position
	await _middle_drag(Vector2(1020, 600), Vector2(1095, 540))
	_check(failures, game.camera_rig.position.distance_to(return_pan_start) > 0.05 and game.placement_type == "", "camera remains draggable after returning from build mode")

	var zoom_before: float = game.camera_rig.target_zoom
	var wheel := InputEventMouseButton.new()
	wheel.position = Vector2(1000, 550)
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	Input.parse_input_event(wheel)
	await process_frame
	_check(failures, game.camera_rig.target_zoom > zoom_before, "mouse-wheel zoom still works after multiple pan interactions")

	game.queue_free()
	await process_frame
	_finish(failures)


func _left_drag(game, from: Vector2, to: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.position = from
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	game._unhandled_input(press)
	await process_frame
	var motion := InputEventMouseMotion.new()
	motion.position = to
	motion.relative = to - from
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	game._unhandled_input(motion)
	await process_frame
	var release := InputEventMouseButton.new()
	release.position = to
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	game._unhandled_input(release)
	await process_frame


func _middle_drag(from: Vector2, to: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.position = from
	press.button_index = MOUSE_BUTTON_MIDDLE
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var motion := InputEventMouseMotion.new()
	motion.position = to
	motion.relative = to - from
	motion.button_mask = MOUSE_BUTTON_MASK_MIDDLE
	Input.parse_input_event(motion)
	await process_frame
	var release := InputEventMouseButton.new()
	release.position = to
	release.button_index = MOUSE_BUTTON_MIDDLE
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame


func _first_completed_non_road(simulation) -> Dictionary:
	for building_value in simulation.buildings:
		var building: Dictionary = building_value
		if not bool(building.get("construction", false)) and String(building.get("type", "")) != Defs.BUILDING_ROAD:
			return building
	return {}


func _check(failures: Array[String], condition: bool, label: String) -> void:
	print("%s %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		failures.append(label)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("PHASE3_1_CAMERA_INPUT_SMOKE PASS")
		quit(0)
	else:
		print("PHASE3_1_CAMERA_INPUT_SMOKE FAIL count=%d" % failures.size())
		quit(1)
