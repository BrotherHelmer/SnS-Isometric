extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Fixture = preload("res://src/GodotClient3D/Scripts/production_demo_fixture.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var overlay: Control = game.startup_overlay
	_check(failures, overlay != null and overlay.visible and game.simulation_host.paused, "normal launch opens a paused start menu")
	var new_button: Button = overlay.find_child("NewReviewSeed", true, false)
	var load_button: Button = overlay.find_child("LoadSettlement", true, false)
	var quit_button: Button = overlay.find_child("QuitGame", true, false)
	_check(failures, new_button != null and load_button != null and quit_button != null, "start menu exposes New, Load, and Quit actions")
	new_button.pressed.emit()
	await process_frame
	_check(failures, not overlay.visible and not game.simulation_host.paused and game.simulation_host.simulation.rng_seed == game.DEFAULT_SEED, "New Settlement button begins the recommended deterministic seed")
	var fixture := Fixture.new()
	var fixture_result: Dictionary = fixture.apply(game.simulation_host.simulation, "early")
	_check(failures, bool(fixture_result.get("success", false)), "authoritative early settlement is ready for UI construction")
	game._initialize_presentation()
	var simulation = game.simulation_host.simulation
	for resource_type in [Defs.RESOURCE_WOOD, Defs.RESOURCE_PLANKS, Defs.RESOURCE_STONE]:
		simulation.central_inventory[resource_type] = maxi(50, int(simulation.central_inventory.get(resource_type, 0)))
	var build_button: Button = game.build_buttons.get(Defs.BUILDING_LUMBER_CAMP)
	_check(failures, build_button != null and String(build_button.tooltip_text).contains("Cost"), "build palette button carries cost and purpose guidance")
	build_button.pressed.emit()
	_check(failures, game.placement_type == Defs.BUILDING_LUMBER_CAMP and game.placement_ghost.visible, "build button enters readable placement mode")
	var site: Vector2i = fixture._ensure_site(simulation, Defs.BUILDING_LUMBER_CAMP, simulation.town_hall_position + Vector2i(10, 7))
	game.preview_placement_at(Defs.BUILDING_LUMBER_CAMP, site)
	_check(failures, bool(game.placement_validation.get("success", false)), "placement preview reports a valid authoritative site")
	var buildings_before: int = simulation.buildings.size()
	game._commit_placement()
	_check(failures, simulation.buildings.size() == buildings_before + 1 and game.placement_type == "", "placement click creates a real construction site and exits placement mode")
	var placed: Dictionary = simulation.buildings.back()
	game.select_building(int(placed.get("id", 0)))
	_check(failures, game.selected_entity_kind == "building" and game.inspector_label.text.contains("Lumber"), "selection opens a useful building inspector")
	var pause: Button = game.pause_button
	pause.pressed.emit()
	_check(failures, simulation != null and game.simulation_host.paused and game.world_view.presentation_paused and pause.button_pressed and pause.tooltip_text.begins_with("Resume"), "Pause stops authoritative and presentation motion")
	pause.pressed.emit()
	_check(failures, not game.simulation_host.paused and not game.world_view.presentation_paused and not pause.button_pressed and pause.tooltip_text.begins_with("Pause"), "Resume restores authoritative and presentation motion")
	var saved: bool = game.save_game()
	print("SAVE_EVIDENCE saved=%s message=%s" % [saved, simulation.last_message])
	var tick_before_load: int = simulation.get_tick_number()
	for _tick in 4:
		simulation.advance_tick()
	var loaded: bool = game.load_game()
	print("SAVE_EVIDENCE loaded=%s message=%s" % [loaded, simulation.last_message])
	_check(failures, saved and loaded and game.simulation_host.simulation.get_tick_number() == tick_before_load, "Save and Load round-trip the live settlement from the production UI")
	game._show_start_menu()
	_check(failures, overlay.visible and game.simulation_host.paused and game.world_view.presentation_paused, "Main Menu safely pauses the active settlement")
	game.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	_finish(failures)


func _check(failures: Array[String], condition: bool, label: String) -> void:
	print("%s %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		failures.append(label)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("PHASE3_UI_INTERACTION_SMOKE PASS")
		quit(0)
	else:
		print("PHASE3_UI_INTERACTION_SMOKE FAIL count=%d" % failures.size())
		quit(1)
