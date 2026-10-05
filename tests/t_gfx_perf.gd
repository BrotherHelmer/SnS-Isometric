extends SceneTree

## Lavapipe frame-time sample for day / dusk / night / first-view.
## Uses the 18-step save when present so GFX-1 and GFX-02 share a camera.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const SAVE_PATH := "res://artifacts/phase3_2/persistence/eighteen_step_playthrough.json"

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		game.simulation_host.load_from_path(SAVE_PATH)
		game._initialize_presentation()
	else:
		game.start_new_3d(game.DEFAULT_SEED)
	game._hide_start_menu()
	game.simulation_host.paused = true
	game.set_process(false)
	var sim = game.simulation_host.simulation
	var home: Vector3 = game.world_view.tile_to_world(Vector2(sim.town_hall_position) + Vector2(1.5, 1.5))
	game.camera_rig.compose_view(home, 34.0)
	sim.is_night = false
	sim.phase_time = 80.0
	game._update_day_night_lighting()
	game._sync_presentation()
	await _sample("day", game)
	sim.phase_time = float(sim.DAY_LENGTH_SECONDS) - 6.0
	game._update_day_night_lighting()
	game._sync_presentation()
	await _sample("dusk", game)
	sim.is_night = true
	sim.phase_time = 20.0
	game._update_day_night_lighting()
	game._sync_presentation()
	await _sample("night", game)
	if game.has_method("_author_title_composition"):
		game._author_title_composition()
		game._update_day_night_lighting()
	await _sample("first-view", game)
	print("GFX_PERF_DONE")
	game.queue_free()
	quit(0)


func _sample(label: String, _game) -> void:
	for _warm in 8:
		await process_frame
	var acc := 0.0
	var frames := 45
	for _i in frames:
		await process_frame
		acc += float(Performance.get_monitor(Performance.TIME_PROCESS))
	print("GFX_PERF %s frame_ms=%.3f frames=%d" % [label, (acc / float(frames)) * 1000.0, frames])
