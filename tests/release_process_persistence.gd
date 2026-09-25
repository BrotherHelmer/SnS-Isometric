extends SceneTree

## Two invocations: prepare saves and uninterrupted references, then relaunch and
## compare the same 30 seconds of authority. Hunger is an explicit prepared case.
const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const ROOT := "res://artifacts/release_candidate/process_persistence"
const SOURCES := {
	"cargo": "res://artifacts/release_candidate/natural_260821.json",
	"raid": "res://artifacts/phase3_2/persistence/eighteen_step_playthrough.json",
	"binding": "res://artifacts/release_candidate/natural_binding_260821.json",
	"hunger": "res://artifacts/release_candidate/natural_260821.json",
}
var failures: Array[String] = []

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ROOT)
	var prepare := "--prepare" in OS.get_cmdline_user_args()
	for scenario in SOURCES:
		var sim = Simulation.new(70, 70, 1, false, true)
		var input: String = SOURCES[scenario] if prepare else ROOT + "/" + scenario + ".json"
		if not sim.load_from_path(input):
			_check(false, scenario + " input loads")
			continue
		if prepare:
			if scenario == "cargo":
				for tick in 3000:
					if _cargo_count(sim) > 0:
						break
					sim.advance_tick()
			elif scenario == "hunger":
				sim.hungry_population = 2
				sim.hunger_penalty_remaining = 120.0
				for index in mini(2, sim.workers.size()):
					sim.workers[index]["hungry"] = true
			_check(sim.save_to_path(ROOT + "/" + scenario + ".json"), scenario + " checkpoint written")
		match scenario:
			"cargo": _check(_cargo_count(sim) > 0, "live cargo present")
			"raid": _check(sim.is_night and not sim.enemies.is_empty(), "live night raid present")
			"binding": _check(float(sim.rivalry.get_claim_status("player").get("binding_progress", 0.0)) >= 30.0, "Binding progress present")
			"hunger": _check(sim.is_hunger_penalty_active() and sim.hungry_population == 2, "prepared hunger persists")
		for tick in 300:
			sim.advance_tick()
		var state: Dictionary = sim._serialize_state().duplicate(true)
		for key in ["log_entries", "notice_log", "run_journal", "last_message"]:
			state.erase(key)
		var output: String = ROOT + "/" + scenario + ("_expected.json" if prepare else "_actual.json")
		var file := FileAccess.open(output, FileAccess.WRITE)
		file.store_string(JSON.stringify(state, "\t"))
		file.close()
		if not prepare:
			var expected = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "/" + scenario + "_expected.json"))
			var actual = JSON.parse_string(FileAccess.get_file_as_string(output))
			_compare(expected, actual, scenario)
	print("RELEASE_PROCESS_PERSISTENCE %s mode=%s" % ["PASS" if failures.is_empty() else "FAIL", "prepare" if prepare else "relaunch"])
	quit(0 if failures.is_empty() else 1)

func _cargo_count(sim) -> int:
	var count := 0
	for worker in sim.workers:
		if int(worker.get("carried_amount", 0)) > 0:
			count += 1
	return count

func _compare(expected, actual, path: String) -> void:
	if typeof(expected) != typeof(actual):
		_check(false, path + " type matches")
	elif expected is Dictionary:
		_check(expected.size() == actual.size(), path + " field count")
		for key in expected:
			if not actual.has(key):
				_check(false, path + "." + key + " present")
			else:
				_compare(expected[key], actual[key], path + "." + key)
	elif expected is Array:
		_check(expected.size() == actual.size(), path + " item count")
		for index in mini(expected.size(), actual.size()):
			_compare(expected[index], actual[index], path + "[%d]" % index)
	elif expected is float:
		_check(absf(expected - actual) < 0.00001, path + " value matches")
	else:
		_check(expected == actual, path + " value matches")

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
		print("FAIL " + label)
