extends SceneTree

const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")

var checks: Array[String] = []
var passed := true


func _init() -> void:
	call_deferred("_run")


func _check(label: String, condition: bool) -> void:
	checks.append("%s %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		passed = false


func _run() -> void:
	var packed: PackedScene = load("res://src/GodotClient/Scenes/main.tscn")
	var view = packed.instantiate()
	root.add_child(view)
	await process_frame
	_check("smoke harness is responsive", true)
	var score_nodes := [
		view.get_node_or_null("Score_Pastoral"),
		view.get_node_or_null("Score_Activity"),
		view.get_node_or_null("Score_Dusk"),
		view.get_node_or_null("Score_Night"),
		view.get_node_or_null("Score_Metal")
	]
	_check("main menu starts five synchronized original music layers", score_nodes.all(func(player): return player != null))
	var loaded_layers := 0
	for player in score_nodes:
		if player != null and player.stream != null:
			loaded_layers += 1
	_check("all adaptive layers are loaded into one synchronized mix", loaded_layers == 5)
	_check("audio settings expose master music effects ambience and mute", view.master_volume_slider != null and view.music_volume_slider != null and view.effects_volume_slider != null and view.ambience_volume_slider != null and view.music_mute_button != null)

	view._start_new_demo()
	await process_frame
	var simulation = view.simulation
	_check("New Game starts with completed Town Hall", simulation.is_town_hall_founded())
	_check("opening starts with exactly one visible settler", simulation.get_workers().size() == 1)
	_check("opening does not enter Town Hall placement mode", view.current_mode == view.MODE_SELECT)
	_check("left command dock exists", view.command_dock != null and view.command_dock.name == "LeftCommandDock")
	_check("legacy permanent terrain inspector is not created", view.info_panel == null)
	_check("desktop camera arrow pad is not created", view.canvas_layer.find_child("CameraControls", true, false) == null)
	var thumbnail_count := 0
	for mode in view.mode_buttons.keys():
		if view.BUILD_MODES.has(String(mode)) and String(mode) != Defs.BUILDING_TOWN_HALL:
			var button: Button = view.mode_buttons[mode]
			if button.icon != null:
				thumbnail_count += 1
	_check("all thirteen available buildables have image thumbnails", thumbnail_count == view.BUILD_MODES.size() - 1)
	_check("objective is a single untruncated sentence", view._active_objective_text() == "Give your settler their first order.")

	var worker_id: int = simulation.get_presentation_worker_id()
	simulation.set_worker_reaction(worker_id, "Awaiting order", "", 0.0)
	var town_center: Vector2i = simulation._footprint_center(simulation.town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	var target := town_center + Vector2i(7, -6)
	var wood_before := int(simulation.central_inventory.get(Defs.RESOURCE_WOOD, 0))
	var order: Dictionary = simulation.request_worker_order(worker_id, target)
	_check("first gather order is accepted", bool(order.get("success", false)))
	_check("settler begins a real path-driven walking state", not simulation.get_worker_by_id(worker_id).get("path", []).is_empty())
	for _tick in range(520):
		simulation.advance_tick()
		if simulation.first_player_order_complete:
			break
	_check("first order visibly gathers and delivers a resource", int(simulation.central_inventory.get(Defs.RESOURCE_WOOD, 0)) > wood_before)
	_check("first-order objective completes after delivery", simulation.first_player_order_complete and bool(simulation.get_objectives()[0].get("complete", false)))
	_check("manual settler returns to logistics without duplicating", simulation.get_workers().size() == 1 and String(simulation.get_worker_by_id(worker_id).get("type", "")) == "carrier")

	view.current_mode = view.MODE_SELECT
	view.selected_building_id = 0
	_check("ordinary play hides precise Lumen geometry", view.current_mode != Defs.BUILDING_LUMEN_PILLAR and view.selected_building_id == 0)
	view._set_music_muted(true)
	_check("music mute applies without unloading synchronized layers", view.music_muted and score_nodes.all(func(player): return player != null and player.stream != null))
	view._set_music_muted(false)
	view._set_music_volume(0.65)
	view.music_volume = 0.10
	view._load_settings()
	_check("music volume persists through settings reload", is_equal_approx(view.music_volume, 0.65))
	view._set_music_volume(view.DEFAULT_MUSIC_VOLUME)

	var report := "\n".join(checks) + "\nPRESENTATION_SMOKE %s\n" % ("PASS" if passed else "FAIL")
	var file := FileAccess.open("res://artifacts/presentation_smoke_report.txt", FileAccess.WRITE)
	if file != null:
		file.store_string(report)
	print(report)
	view.queue_free()
	await process_frame
	quit(0 if passed else 1)
