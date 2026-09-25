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
		if autosave_elapsed >= AUTOSAVE_SECONDS:
			autosave_elapsed = 0.0
			var success: bool = simulation.save_to_path(Simulation.AUTOSAVE_PATH)
			autosave_finished.emit(success, simulation.get_last_message())
	tick_accumulator += delta * speed_multiplier
	var ticks := 0
	while tick_accumulator >= Simulation.TICK_SECONDS and ticks < MAX_TICKS_PER_RENDER_FRAME:
		tick_accumulator -= Simulation.TICK_SECONDS
		simulation.advance_tick()
		ticks += 1
	# A rendered client must not enter an unbounded catch-up spiral after a slow
	# frame. The simulation's fixed tick remains unchanged; only stale wall-clock
	# backlog beyond this frame budget is discarded.
	if tick_accumulator >= Simulation.TICK_SECONDS:
		tick_accumulator = fmod(tick_accumulator, Simulation.TICK_SECONDS)
		dropped_backlog_frames += 1
	return ticks


func render_lead_seconds() -> float:
	return tick_accumulator
