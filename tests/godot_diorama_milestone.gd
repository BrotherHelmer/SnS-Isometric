extends SceneTree
## Milestone 1 acceptance test (checks 2+3 of GAMEPLAY_PLAN.md):
## found Town Hall -> place House + Lumber Camp + Roads -> 600 tick window ->
## wood stockpile grows AND >=1 completed carrier cycle; then save/load
## round-trip must restore identical buildings + inventory.
## Run: godot --headless --path . --script res://tests/godot_diorama_milestone.gd

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")

var failures: Array[String] = []


func _check(cond: bool, label: String) -> void:
	if cond:
		print("PASS ", label)
	else:
		failures.append(label)
		print("FAIL ", label)


func _find_valid(sim, building_type: String, near: Vector2i, max_r: int) -> Vector2i:
	for r in range(0, max_r + 1):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(abs(dx), abs(dy)) != r:
					continue
				var t := near + Vector2i(dx, dy)
				var v: Dictionary = sim.validate_placement(building_type, t, 0)
				if bool(v.get("success", false)):
					return t
	return Vector2i(-9999, -9999)


func _completed(sim, building_type: String) -> int:
	var n := 0
	for b in sim.buildings:
		if String(b.get("type", "")) == building_type:
			n += 1
	return n


func _place_roads(sim, near: Vector2i, count: int) -> int:
	var placed := 0
	for i in range(count * 6):
		if placed >= count:
			break
		var t := _find_valid(sim, Defs.BUILDING_ROAD, near, 12)
		if t.x == -9999:
			break
		var res: Dictionary = sim.request_build(Defs.BUILDING_ROAD, t, 0)
		if bool(res.get("success", false)):
			placed += 1
	return placed


func _building_signature(sim) -> Array:
	var sig: Array = []
	for b in sim.buildings:
		sig.append("%s@%s" % [String(b.get("type", "")), str(b.get("position", b.get("tile", "?")))])
	sig.sort()
	return sig


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var sim = Simulation.new(70, 70, 424242, false, false)
	# --- Founding -------------------------------------------------------
	var th_tile := _find_valid(sim, Defs.BUILDING_TOWN_HALL, Vector2i(35, 35), 30)
	_check(th_tile.x != -9999, "found a valid Town Hall tile")
	var res: Dictionary = sim.request_build(Defs.BUILDING_TOWN_HALL, th_tile, 0)
	_check(bool(res.get("success", false)), "Town Hall founding request accepted: " + String(res.get("message", "")))
	var ticks := 0
	while not sim.is_town_hall_founded() and ticks < 6000:
		sim.advance_tick()
		ticks += 1
	_check(sim.is_town_hall_founded(), "Town Hall founded (ticks=%d)" % ticks)
	# --- Roads + House + Lumber Camp ------------------------------------
	_place_roads(sim, th_tile, 10)
	var house_tile := _find_valid(sim, Defs.BUILDING_HOUSE, th_tile, 16)
	if house_tile.x == -9999:
		_place_roads(sim, th_tile, 10)
		house_tile = _find_valid(sim, Defs.BUILDING_HOUSE, th_tile, 16)
	_check(house_tile.x != -9999, "found a valid House tile")
	res = sim.request_build(Defs.BUILDING_HOUSE, house_tile, 0)
	_check(bool(res.get("success", false)), "House build requested: " + String(res.get("message", "")))
	var camp_tile := _find_valid(sim, Defs.BUILDING_LUMBER_CAMP, th_tile, 18)
	if camp_tile.x == -9999:
		_place_roads(sim, th_tile, 10)
		camp_tile = _find_valid(sim, Defs.BUILDING_LUMBER_CAMP, th_tile, 18)
	_check(camp_tile.x != -9999, "found a valid Lumber Camp tile")
	res = sim.request_build(Defs.BUILDING_LUMBER_CAMP, camp_tile, 0)
	_check(bool(res.get("success", false)), "Lumber Camp build requested: " + String(res.get("message", "")))
	_place_roads(sim, th_tile, 8)
	# --- Construction phase ----------------------------------------------
	ticks = 0
	while ticks < 12000:
		if _completed(sim, Defs.BUILDING_HOUSE) >= 1 and _completed(sim, Defs.BUILDING_LUMBER_CAMP) >= 1:
			break
		sim.advance_tick()
		ticks += 1
	_check(_completed(sim, Defs.BUILDING_HOUSE) >= 1, "House construction completed (ticks=%d)" % ticks)
	_check(_completed(sim, Defs.BUILDING_LUMBER_CAMP) >= 1, "Lumber Camp construction completed (ticks=%d)" % ticks)
	print("INFO last_message after construction: ", sim.last_message)
	# --- 600-tick production window ---------------------------------------
	var wood_before := int(sim.central_inventory.get(Defs.RESOURCE_WOOD, 0))
	var carrying_seen := {}
	var counted := {}
	var cycles := 0
	for i in range(600):
		sim.advance_tick()
		for w in sim.workers:
			var wid := int(w.get("id", -1))
			if int(w.get("carried_amount", 0)) > 0:
				carrying_seen[wid] = true
			elif bool(carrying_seen.get(wid, false)) and not bool(counted.get(wid, false)):
				counted[wid] = true
				cycles += 1
	var wood_after := int(sim.central_inventory.get(Defs.RESOURCE_WOOD, 0))
	print("INFO wood before=%d after=%d cycles=%d workers=%d" % [wood_before, wood_after, cycles, sim.workers.size()])
	print("INFO last_message after window: ", sim.last_message)
	_check(cycles >= 1, "at least one worker completed a carry cycle in 600 ticks")
	_check(wood_after > wood_before, "wood stockpile grew in 600 ticks (%d -> %d)" % [wood_before, wood_after])
	# --- Save / load round-trip -------------------------------------------
	var sig_before := _building_signature(sim)
	var inv_before: Dictionary = sim.central_inventory.duplicate(true)
	var save_path := "user://milestone1_test_save.json"
	_check(sim.save_to_path(save_path), "save_to_path succeeded")
	var sim2 = Simulation.new(70, 70, 999, false, false)
	_check(sim2.load_from_path(save_path), "load_from_path succeeded")
	var sig_after := _building_signature(sim2)
	_check(sig_before == sig_after, "building set identical after reload (%d buildings)" % sig_after.size())
	var inv_ok := true
	for key in inv_before.keys():
		if int(sim2.central_inventory.get(key, 0)) != int(inv_before[key]):
			inv_ok = false
	_check(inv_ok, "central inventory identical after reload")
	# --- Verdict ------------------------------------------------------------
	if failures.is_empty():
		print("MILESTONE PASS")
		quit(0)
	else:
		print("MILESTONE FAIL (%d checks failed)" % failures.size())
		quit(1)
