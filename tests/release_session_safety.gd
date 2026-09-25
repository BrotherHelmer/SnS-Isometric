extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Store = preload("res://src/GodotClient/Scripts/one_shard_save_store.gd")
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = Scene.instantiate()
	root.add_child(game)
	await process_frame
	game._start_review_seed()
	game.set_process(false)
	var host = game.simulation_host
	host.autosave_elapsed = host.AUTOSAVE_SECONDS - 0.01
	host.paused = true
	host.advance(0.02)
	check(host.autosave_elapsed > 119.0, "pause suspends autosave clock")
	host.paused = false
	host.advance(0.02)
	check(host.autosave_elapsed == 0.0 and Store.read_save(Simulation.AUTOSAVE_PATH).success, "active play writes rolling autosave")
	check(game.save_game(), "manual save")
	check(host.simulation.continue_save_path() == Simulation.SAVE_PATH, "new manual save wins even within the same filesystem second")
	var prior_seed: int = host.simulation.rng_seed
	game._start_menu_seed(717171)
	check(int(Store.read_save(game.PREVIOUS_REALM_PATH).data.rng_seed) == prior_seed, "new realm preserves the previous run")
	check(host.simulation.continue_save_path() == Simulation.AUTOSAVE_PATH, "new realm autosave wins over an earlier manual save")
	host.start_new(123)
	check(host.load_existing() and host.simulation.rng_seed == 717171, "Continue restores the newest realm")
	host.autosave_elapsed = 119.0
	check(host.load_from_path(Simulation.AUTOSAVE_PATH) and host.autosave_elapsed == 0.0, "load resets autosave interval")
	game.quality_select.select(1)
	game.fullscreen_check.set_pressed_no_signal(false)
	game._save_display_settings()
	game.quality_select.select(0)
	game._restore_display_settings()
	check(game.quality_select.selected == 1, "display quality persists")
	game.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	print("RELEASE_SESSION_SAFETY %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)

func check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
