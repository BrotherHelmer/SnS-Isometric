extends SceneTree

const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")

var view
var scenario := "opening"
var frames := 0
var total_frames := 210
var frame_rate := 24.0
var reel_units: Array = []
var frame_dir := ""
var capture_stride := 3


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		scenario = String(args[0])
	frame_dir = "res://artifacts/presentation_pass/motion/frames_%s" % scenario
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(frame_dir))
	call_deferred("_run")


func _run() -> void:
	_write_progress("loading scene")
	var packed: PackedScene = load("res://src/GodotClient/Scenes/main.tscn")
	view = packed.instantiate()
	view.visible = false
	_write_progress("adding scene")
	root.add_child(view)
	_write_progress("awaiting first frame")
	await process_frame
	_write_progress("starting demo")
	# The scene already owns a fully authored presentation run from _ready().
	# Reusing it avoids regenerating the 70x70 terrain while the movie capture
	# viewport is synchronously reading frames.
	_write_progress("resetting selection")
	view.selected_tile = Vector2i(-1, -1)
	view.selected_building_id = 0
	view.selected_worker_id = 0
	_write_progress("resetting opening state")
	view.opening_worker_id = view.simulation.get_presentation_worker_id()
	view.opening_intro_active = true
	view.opening_intro_stage = 0
	view.opening_intro_timer = 0.0
	view.opening_door_open = 0.0
	view.objective_intro_visible = false
	_write_progress("setting mode")
	view._set_mode(view.MODE_SELECT)
	_write_progress("resetting camera")
	view._reset_camera()
	_write_progress("hiding menu")
	view.main_menu_root.visible = false
	view.game_started = true
	view.visible = true
	if scenario == "opening":
		total_frames = 215
		view.paused = false
	elif scenario == "characters":
		total_frames = 240
		_prepare_character_reel()
	else:
		total_frames = 240
		_prepare_transition()
	_write_progress("entering frame loop")
	while frames < total_frames:
		if frames % 24 == 0:
			_write_progress("%d/%d" % [frames, total_frames])
		if scenario == "characters":
			_update_character_reel(1.0 / frame_rate)
		elif scenario == "transition":
			_update_transition(1.0 / frame_rate)
		view.queue_redraw()
		view.static_world.queue_redraw()
		await process_frame
		if frames % capture_stride == 0:
			var texture := root.get_texture()
			if texture != null:
				var image := texture.get_image()
				if image != null:
					image.save_png("%s/frame_%04d.png" % [frame_dir, int(frames / capture_stride)])
		frames += 1
	var report := FileAccess.open("%s/complete.txt" % frame_dir, FileAccess.WRITE)
	if report != null:
		report.store_string("%s %d frames at %.1f fps source cadence\n" % [scenario, int(ceil(float(total_frames) / float(capture_stride))), frame_rate])
	view.queue_free()
	await process_frame
	quit(0)


func _write_progress(text_value: String) -> void:
	var progress := FileAccess.open("%s/progress.txt" % frame_dir, FileAccess.WRITE)
	if progress != null:
		progress.store_string(text_value + "\n")


func _prepare_character_reel() -> void:
	var simulation = view.simulation
	simulation.start_new_run(70, 70, 808080, true)
	simulation.elapsed_seconds = 90.0
	simulation.presentation_worker_id = 0
	var center: Vector2i = simulation._footprint_center(simulation.town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL)) + Vector2i(3, 3)
	simulation._clear_area(center, 15)
	simulation._flatten_area(center, 15)
	simulation._reveal_radius(center, 19)
	simulation.workers.clear()
	for index in range(2):
		var start := center + Vector2i(-4, index * 3)
		var worker := {
			"id": 9100 + index,
			"type": "guard" if index == 1 else "carrier",
			"building_id": 0,
			"position": start,
			"path": [start + Vector2i(4, 0)],
			"state": "Patrolling" if index == 1 else "Carrying to Town Hall",
			"arrival_state": "Patrolling",
			"move_elapsed": 0.0,
			"attack_flash": 0.0,
			"carried_resource": Defs.RESOURCE_WOOD if index == 0 else "",
			"carried_amount": 3 if index == 0 else 0,
			"hp": 40 if index == 1 else 30,
			"max_hp": 40 if index == 1 else 30,
			"task": {},
			"hungry": false
		}
		simulation.workers.append(worker)
		reel_units.append(worker)
	simulation.enemies.clear()
	var roles := [
		simulation.ENEMY_RAIDER,
		simulation.ENEMY_SKITTERER,
		simulation.ENEMY_BRUTE,
		simulation.ENEMY_HEXER
	]
	for index in range(4):
		var start := center + Vector2i(3, -5 + index * 3)
		var enemy := {
			"id": 9200 + index,
			"enemy_type": roles[index],
			"position": start,
			"path": [start + Vector2i(3, 0)],
			"move_elapsed": 0.0,
			"speed_multiplier": 1.0,
			"attack_flash": 0.0,
			"hit_until": 0.0,
			"hit_direction": {},
			"target_position": simulation._vector_to_data(start + Vector2i(-1, 0)),
			"hp": 40 + index * 14,
			"max_hp": 40 + index * 14,
			"damage": 3,
			"camp_id": 0
		}
		simulation.enemies.append(enemy)
		reel_units.append(enemy)
	var sovereign: Dictionary = simulation.rivalry.get_sovereign("player")
	sovereign["position"] = Vector2(center + Vector2i(-2, -4))
	sovereign["previous_position"] = sovereign["position"]
	sovereign["move_target"] = sovereign["position"]
	view.paused = true
	view.objective_intro_visible = false
	view.objective_panel.visible = false
	view.command_dock_collapsed = true
	view.command_dock_body.visible = false
	view.command_dock.offset_right = 58.0
	view.camera.position = view.tile_to_world(center) + Vector2(10, 10)
	view.camera.zoom = Vector2(1.72, 1.72)
	view.pre_shard_zoom = 1.72
	view._invalidate_revealed_tile_cache()
	view._refresh_static_world_if_needed(true)


func _update_character_reel(delta: float) -> void:
	var simulation = view.simulation
	simulation.elapsed_seconds += delta
	var cycle: float = fmod(float(frames) / frame_rate, 2.4)
	for index in range(reel_units.size()):
		var unit: Dictionary = reel_units[index]
		var path: Array = unit.get("path", [])
		if path.is_empty():
			continue
		var step: float = float(simulation.get_worker_step_seconds(unit) if index < 2 else simulation.get_enemy_step_seconds(unit))
		unit["move_elapsed"] = fmod(float(unit.get("move_elapsed", 0.0)) + delta, step)
		if index == 1:
			unit["attack_flash"] = 0.46 * sin(clampf((cycle - 1.3) / 0.8, 0.0, 1.0) * PI) if cycle > 1.3 else 0.0
		elif index >= 2:
			unit["attack_flash"] = 0.56 * sin(clampf((cycle - 1.2) / 0.9, 0.0, 1.0) * PI) if cycle > 1.2 else 0.0
	var sovereign: Dictionary = simulation.rivalry.get_sovereign("player")
	var base: Vector2 = Vector2(simulation._footprint_center(simulation.town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL)) + Vector2i(1, -1))
	sovereign["previous_position"] = sovereign["position"]
	sovereign["position"] = base + Vector2(sin(simulation.elapsed_seconds * 1.25) * 2.3, 0.0)
	sovereign["move_input"] = Vector2(cos(simulation.elapsed_seconds * 1.25), 0.0)
	sovereign["attack_cooldown"] = 0.8 * sin(clampf((cycle - 1.4) / 0.8, 0.0, 1.0) * PI) if cycle > 1.4 else 0.0


func _prepare_transition() -> void:
	var simulation = view.simulation
	simulation.start_new_run(70, 70, 606060, true)
	simulation.population_current = 8
	simulation.housing_capacity = 10
	var center: Vector2i = simulation._footprint_center(simulation.town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	simulation._clear_area(center, 13)
	simulation._reveal_radius(center, 18)
	simulation.phase_time = simulation.DAY_LENGTH_SECONDS - 8.0
	view.paused = true
	view.objective_intro_visible = false
	view.objective_panel.visible = false
	view.command_dock_collapsed = true
	view.command_dock_body.visible = false
	view.command_dock.offset_right = 58.0
	view.camera.position = view.tile_to_world(center) + Vector2(26, 18)
	view.camera.zoom = Vector2(1.52, 1.52)
	view.pre_shard_zoom = 1.52
	view._invalidate_revealed_tile_cache()
	view._refresh_static_world_if_needed(true)


func _update_transition(delta: float) -> void:
	var simulation = view.simulation
	simulation.elapsed_seconds += delta
	var seconds: float = float(frames) / frame_rate
	if seconds < 4.2:
		simulation.is_night = false
		simulation.phase_time = simulation.DAY_LENGTH_SECONDS - lerpf(45.0, 2.0, seconds / 4.2)
	else:
		simulation.is_night = true
		simulation.phase_time = seconds - 4.2
		if simulation.enemies.is_empty():
			for index in range(5):
				simulation._spawn_enemy(
					simulation.town_hall_position + Vector2i(9 + index, -4 + index),
					28,
					3,
					0.0,
					0,
					[simulation.ENEMY_RAIDER, simulation.ENEMY_SKITTERER, simulation.ENEMY_BRUTE, simulation.ENEMY_HEXER][index % 4]
				)
	view._update_visual_modes(delta * 4.0)
	view._update_adaptive_music(delta)
	view._update_ui()
