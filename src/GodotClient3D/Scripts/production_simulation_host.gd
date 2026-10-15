class_name ProductionSimulationHost3D
extends Node

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const MAX_TICKS_PER_RENDER_FRAME := 4
const AUTOSAVE_SECONDS := 120.0
signal autosave_finished(success: bool, message: String)

var simulation
var tick_accumulator := 0.0
var speed_multiplier := 1.0
var paused := false
var dropped_backlog_frames := 0
## R34 (gate harness): called after every fixed sim tick, so a test bot can
## act at deterministic game ticks regardless of frame rate.
var tick_hook: Callable
var autosave_elapsed := 0.0


func start_new(seed_value: int, begin_founded := true) -> void:
	simulation = Simulation.new(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, seed_value, true, begin_founded)
	tick_accumulator = 0.0
	dropped_backlog_frames = 0
	autosave_elapsed = 0.0


func load_existing() -> bool:
	if simulation == null:
		simulation = Simulation.new(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 1, true, true)
	var path: String = simulation.continue_save_path()
	var loaded: bool = simulation.load_from_path(path) if path != "" else false
	if loaded:
		tick_accumulator = 0.0
		dropped_backlog_frames = 0
		autosave_elapsed = 0.0
	return loaded


func save_current() -> bool:
	return simulation != null and simulation.save_to_file()


func save_to_path(path: String) -> bool:
	return simulation != null and simulation.save_to_path(path)


func load_from_path(path: String) -> bool:
	if simulation == null:
		simulation = Simulation.new(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 1, true, true)
	var loaded: bool = simulation.load_from_path(path)
	if loaded:
		tick_accumulator = 0.0
		dropped_backlog_frames = 0
		autosave_elapsed = 0.0
	return loaded


func advance(delta: float) -> int:
	if simulation == null or paused or speed_multiplier <= 0.0:
		return 0
	if not simulation.game_finished:
		autosave_elapsed += delta
		if autosave_elapsed >= AUTOSAVE_SECONDS and _autosave_task < 0:
			autosave_elapsed = 0.0
			_start_async_autosave()
	_poll_async_autosave()
	tick_accumulator += delta * speed_multiplier
	var ticks := 0
	while tick_accumulator >= Simulation.TICK_SECONDS and ticks < MAX_TICKS_PER_RENDER_FRAME:
		tick_accumulator -= Simulation.TICK_SECONDS
		simulation.advance_tick()
		ticks += 1
		if tick_hook.is_valid():
			tick_hook.call()
	# A rendered client must not enter an unbounded catch-up spiral after a slow
	# frame. The simulation's fixed tick remains unchanged; only stale wall-clock
	# backlog beyond this frame budget is discarded.
	if tick_accumulator >= Simulation.TICK_SECONDS:
		tick_accumulator = fmod(tick_accumulator, Simulation.TICK_SECONDS)
		dropped_backlog_frames += 1
	return ticks


## Hotfix 5: autosave snapshot is taken on the main thread (~2 ms); JSON,
## write, verify and backup rotation (~200 ms) run on a worker thread.
const SaveStore = preload("res://src/GodotClient/Scripts/one_shard_save_store.gd")
var _autosave_task := -1
var _autosave_result: Dictionary = {}


func _start_async_autosave() -> void:
	var data: Dictionary = simulation._serialize_state().duplicate(true)
	var path: String = Simulation.AUTOSAVE_PATH
	_autosave_result = {}
	_autosave_task = WorkerThreadPool.add_task(func() -> void:
		_autosave_result = SaveStore.write_save(path, data)
	)


func _poll_async_autosave() -> void:
	if _autosave_task < 0 or not WorkerThreadPool.is_task_completed(_autosave_task):
		return
	WorkerThreadPool.wait_for_task_completion(_autosave_task)
	_autosave_task = -1
	var success := bool(_autosave_result.get("success", false))
	if success:
		simulation._add_log("Run saved.")
	autosave_finished.emit(success, String(_autosave_result.get("message", "Save failed.")))


func render_lead_seconds() -> float:
	return tick_accumulator
