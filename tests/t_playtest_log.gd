extends SceneTree

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const PlaytestLog = preload("res://src/GodotClient/Scripts/one_shard_playtest_log.gd")

var failures: Array[String] = []


func _init() -> void:
	_run()
	for line in failures:
		print("FAIL %s" % line)
	print("T_PLAYTEST_LOG %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _run() -> void:
	var quiet := Simulation.new(8, 8, 1, false)
	quiet.start_new_run(8, 8, 1, true)
	quiet.playtest_log.configure(false, "")
	quiet.note_player_command("player_command", "should_not_write")
	_check(quiet.playtest_log.path == "" or not FileAccess.file_exists(quiet.playtest_log.path) or quiet.playtest_log.enabled == false, "logger stays off by default")

	var path := "user://playtest/t_dpm_test.csv"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var sim := Simulation.new(8, 8, 2, false)
	sim.start_new_run(8, 8, 2, true)
	sim.playtest_log.configure(true, path)
	sim.note_player_command("build_placed", "HOUSE")
	sim.elapsed_seconds = 40.0
	sim.playtest_log.note(sim, "night_started", "Night 1")
	_check(FileAccess.file_exists(path), "enabled logger writes a CSV under user://")
	var text := FileAccess.get_file_as_string(path)
	_check(text.contains("elapsed,day,night,event"), "CSV has a header")
	_check(text.contains("build_placed"), "player commands are recorded")
	_check(text.contains("night_started"), "night events are recorded")
	_check(text.contains(",1\n") or text.contains("\"night_started\""), "idle-gap flag is present after a 30s watch")
	var idle_line := ""
	for line in text.split("\n"):
		if line.contains("night_started"):
			idle_line = line
	_check(idle_line.ends_with(",1") or idle_line.ends_with(",1\r"), "a 40s gap is flagged as idle")


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
