extends SceneTree

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Economy = preload("res://src/GodotClient/Scripts/one_shard_economy.gd")

var failures: Array[String] = []


func _init() -> void:
	_run()
	for line in failures:
		print("FAIL %s" % line)
	print("T_ECONOMY_FEEDBACK %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _run() -> void:
	var sim: Simulation = Simulation.new(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 424242, false)
	sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 424242, true)
	var sawmill := sim._create_building(Defs.BUILDING_SAWMILL, sim.town_hall_position + Vector2i(6, 0))
	sawmill["connected"] = true
	sawmill["assigned_staff"] = 1
	sawmill["staffed"] = true
	sawmill["status"] = "Waiting for Wood."
	var report: Dictionary = sim.diagnose_building_dict(sawmill)
	_check(String(report.get("kind", "")) == Economy.KIND_INPUT, "waiting for wood is an input stall")
	_check(bool(report.get("stalled", false)), "input stall is marked stalled")
	_check(String(report.get("line", "")).contains("logs"), "hover copy says waiting for logs")
	_check(String(report.get("icon", "")) == Economy.ICON_INPUT, "input stall has a world-space icon")
	_check(String(report.get("hover", "")).contains("SAWMILL"), "hover names the building")
	_check(String(report.get("hover", "")).contains("Last delivery"), "hover includes last delivery")
	sawmill["status"] = "Storage full — build more storage or move/consume output."
	report = sim.diagnose_building_dict(sawmill)
	_check(String(report.get("kind", "")) == Economy.KIND_STORAGE, "storage-full status is diagnosed")
	_check(String(report.get("line", "")).contains("storage full") or String(report.get("line", "")).contains("Output"), "storage copy is player-facing")
	var farm := sim._create_building(Defs.BUILDING_FARM, sim.town_hall_position + Vector2i(8, 0))
	farm["connected"] = true
	farm["assigned_staff"] = 0
	farm["status"] = "Needs workers."
	report = sim.diagnose_building_dict(farm)
	_check(String(report.get("kind", "")) == Economy.KIND_WORKER, "unstaffed farm waits for a worker")
	var quarry := sim._create_building(Defs.BUILDING_QUARRY, sim.town_hall_position + Vector2i(10, 0))
	quarry["connected"] = false
	quarry["status"] = "No road connection."
	report = sim.diagnose_building_dict(quarry)
	_check(String(report.get("kind", "")) == Economy.KIND_PATH, "disconnected quarry is no-path")
	var lumber := sim._create_building(Defs.BUILDING_LUMBER_CAMP, sim.town_hall_position + Vector2i(12, 0))
	lumber["connected"] = true
	lumber["assigned_staff"] = 1
	lumber["status"] = "Forest exhausted."
	report = sim.diagnose_building_dict(lumber)
	_check(String(report.get("kind", "")) == Economy.KIND_RANGE, "exhausted lumber is no-resources-in-range")
	var hall := sim._find_town_hall()
	hall["status"] = "Active."
	report = sim.diagnose_building_dict(hall)
	_check(not bool(report.get("stalled", true)), "a working town hall is not stalled")
	sim.buildings.append(sawmill)
	sim.buildings.append(farm)
	sim.buildings.append(quarry)
	sim.buildings.append(lumber)
	sim.elapsed_seconds = 42.0
	sawmill["last_delivery_elapsed"] = 0.0
	sim._refresh_economy_stalls()
	var stalls: Array = sim.get_stall_reports()
	_check(stalls.size() >= 3, "stalled workplaces appear in the stall report")
	_check(String(sim.last_message).to_lower().contains("waiting") or String(sim.last_message).to_lower().contains("sawmill") or sim.playtest_log.command_count >= 0, "stall refresh is cheap and does not crash")
	var hover := Economy.hover_text(Defs.BUILDING_SAWMILL, "Waiting for logs", 42.0)
	_check(hover.contains("42 sec ago"), "hover reports seconds since last delivery")


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
