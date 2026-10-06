extends RefCounted

## The Director: local DPM / idle-gap CSV. Off unless playtest-flagged.
## Writes under user:// (ShardAndSovereign/Playtest) — never the real home dir
## when CI isolates XDG.

const ENV_FLAG := "SNS_PLAYTEST_LOG"
const ARG_FLAG := "--playtest-log"
const IDLE_GAP_SECONDS := 30.0
const LOG_DIR := "user://playtest"

var enabled := false
var path := ""
var last_command_elapsed := 0.0
var command_count := 0
var opened := false


static func should_enable() -> bool:
	if OS.get_environment(ENV_FLAG) == "1":
		return true
	for argument in OS.get_cmdline_user_args():
		if String(argument) == ARG_FLAG:
			return true
	return false


func configure(force_enabled: bool = false, custom_path: String = "") -> void:
	enabled = force_enabled or should_enable()
	path = custom_path
	opened = false
	last_command_elapsed = 0.0
	command_count = 0
	if enabled:
		if path == "":
			path = "%s/dpm.csv" % LOG_DIR
		var parent := path.get_base_dir()
		if parent != "":
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(parent) if parent.begins_with("user://") or parent.begins_with("res://") else parent)


func note(sim, event_type: String, detail: String = "", is_command: bool = false) -> void:
	if not enabled:
		return
	var elapsed := float(sim.elapsed_seconds)
	var since := maxf(0.0, elapsed - last_command_elapsed)
	if is_command:
		command_count += 1
		last_command_elapsed = elapsed
		since = 0.0
	_append(sim, event_type, detail, since, since >= IDLE_GAP_SECONDS and not is_command and command_count > 0)


func note_command(sim, event_type: String, detail: String = "") -> void:
	note(sim, event_type, detail, true)


func _append(sim, event_type: String, detail: String, since: float, idle_gap: bool) -> void:
	if path == "":
		return
	if not opened:
		_write_header()
		opened = true
	var line := "%0.1f,%d,%s,%s,%s,%0.1f,%s\n" % [
		float(sim.elapsed_seconds),
		int(sim.day_count),
		"1" if bool(sim.is_night) else "0",
		_csv(event_type),
		_csv(detail),
		since,
		"1" if idle_gap else "0"
	]
	var file := FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_string(line)
	file.close()


func _write_header() -> void:
	if path == "" or FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string("elapsed,day,night,event,detail,seconds_since_command,idle_gap\n")
	file.close()


static func _csv(value: String) -> String:
	var text := value.replace("\"", "'").replace(",", ";").replace("\n", " ")
	return "\"%s\"" % text
