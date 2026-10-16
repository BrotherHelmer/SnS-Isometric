extends SceneTree
# R36 dev test (not exported): stone objective is need-based and can complete.
const Sim = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Intent = preload("res://src/GodotClient/Scripts/one_shard_intentions.gd")
func _stone(sim) -> Dictionary:
	for a in Intent.evaluate(sim):
		if String(a["id"]) == Intent.ID_STONE: return a
	return {}
func _init():
	var sim = Sim.new()
	sim.load_from_path(OS.get_cmdline_user_args()[0])
	for id in [Intent.ID_ESTABLISH, Intent.ID_FEED, Intent.ID_NIGHTFALL, Intent.ID_SCOUT]: sim.intention_completed[id] = true
	sim.intention_completed.erase(Intent.ID_STONE)
	sim.intention_flags["stone_deposit_found"] = true
	var quarries: Array = []
	for b in sim.buildings:
		if String(b.get("type", "")) == "QUARRY": quarries.append(b)
	var keep: Array = []
	for b in sim.buildings:
		if String(b.get("type", "")) != "QUARRY": keep.append(b)
	sim.buildings = keep
	sim.intention_flags["stone_deposit_x"] = 0
	sim.intention_flags["stone_deposit_y"] = 0
	sim.central_inventory["stone"] = 55
	print("A stone=55 no quarry -> shown=", not _stone(sim).is_empty())
	sim.central_inventory["stone"] = 12
	var s := _stone(sim)
	print("B stone=12 no quarry -> shown=", not s.is_empty(), " title=", s.get("title", ""), " detail=", s.get("detail", ""), " crit=", s.get("criteria", []))
	var q: Dictionary = quarries[0].duplicate(true) if quarries.size() > 0 else {"type": "QUARRY"}
	q["construction"] = false
	q["position"] = Vector2i(40, 40)
	sim.buildings.append(q)
	print("C one quarry far -> shown=", not _stone(sim).is_empty(), " completed=", sim.intention_completed.get(Intent.ID_STONE, false))
	q["position"] = Vector2i(3, 4)
	print("D quarry within 10 of deposit -> shown=", not _stone(sim).is_empty(), " completed=", sim.intention_completed.get(Intent.ID_STONE, false))
	sim.intention_completed.erase(Intent.ID_STONE)
	q["position"] = Vector2i(40, 40)
	var q2 := q.duplicate(true); q2["position"] = Vector2i(44, 44); sim.buildings.append(q2)
	print("E two quarries far, stone=12 -> shown=", not _stone(sim).is_empty())
	# R37 boundaries: Stone 29 vs 30 (no quarry), quarries 1 vs 2 (Stone 12, none near deposit).
	var far_only: Array = []
	for b in sim.buildings:
		if String(b.get("type", "")) != "QUARRY": far_only.append(b)
	sim.buildings = far_only
	sim.intention_completed.erase(Intent.ID_STONE)
	sim.central_inventory["stone"] = 29
	var f := not _stone(sim).is_empty()
	sim.central_inventory["stone"] = 30
	var g := not _stone(sim).is_empty()
	print("F stone=29 -> shown=", f, " (want true)")
	print("G stone=30 -> shown=", g, " (want false)")
	sim.central_inventory["stone"] = 12
	var q1 := q.duplicate(true); q1["position"] = Vector2i(40, 40); sim.buildings.append(q1)
	var h := not _stone(sim).is_empty()
	var q3 := q.duplicate(true); q3["position"] = Vector2i(44, 44); sim.buildings.append(q3)
	var i2 := not _stone(sim).is_empty()
	print("H 1 quarry -> shown=", h, " (want true)")
	print("I 2 quarries -> shown=", i2, " (want false)")
	print("BOUNDARY ", "PASS" if f and not g and h and not i2 else "FAIL")
	quit()
