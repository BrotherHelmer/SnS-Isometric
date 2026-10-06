extends SceneTree

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Discoveries = preload("res://src/GodotClient/Scripts/one_shard_discoveries.gd")

var failures: Array[String] = []


func _init() -> void:
	_run()
	for line in failures:
		print("FAIL %s" % line)
	print("T_FOG_DISCOVERIES %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _run() -> void:
	var sim: Simulation = Simulation.new(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 616161, false)
	sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, 616161, true)
	var kinds := {}
	for feature in sim.world_features:
		kinds[String(feature.get("kind", ""))] = true
	_check(kinds.has(Discoveries.KIND_CART), "abandoned cart is placed under the fog")
	_check(kinds.has(Discoveries.KIND_RUINS), "ruins are placed under the fog")
	_check(kinds.has(Discoveries.KIND_TRACES), "enemy traces are placed under the fog")
	_check(kinds.has(Discoveries.KIND_LANDMARK), "a landmark is placed under the fog")
	_check(kinds.has("stone_region") or kinds.has("rich_forest"), "resource deposits still exist")
	var cart := _feature(sim, Discoveries.KIND_CART)
	_check(not cart.is_empty(), "found the cart feature")
	_check(not sim.is_revealed(cart.get("position", Vector2i.ZERO)), "the cart starts unrevealed")
	var wood_before := int(sim.central_inventory.get("wood", 0))
	var bread_before := int(sim.central_inventory.get("bread", 0))
	sim._reveal_radius(cart["position"], 1)
	sim._notice_discoveries()
	_check(bool(cart.get("revealed", false)), "revealing the tile discovers the cart")
	_check(int(sim.central_inventory.get("wood", 0)) > wood_before, "abandoned supplies grant wood")
	_check(int(sim.central_inventory.get("bread", 0)) > bread_before, "abandoned supplies grant food")
	_check(String(sim.last_message).to_lower().contains("cart") or String(sim.last_message).to_lower().contains("supplies") or String(sim.last_message).contains("+"), "discovery posts a message")
	_check(sim.get_map_markers().size() >= 1, "discovery leaves a map marker")
	var ruins := _feature(sim, Discoveries.KIND_RUINS)
	if not ruins.is_empty():
		sim._reveal_radius(ruins["position"], 1)
		sim._notice_discoveries()
		_check(String(sim.last_message).contains("Lore") or String(sim.last_message).contains("ridge"), "ruins can grant a lore line")
	var stone := _feature(sim, "stone_region")
	if not stone.is_empty():
		sim._reveal_radius(stone["position"], 1)
		sim._notice_discoveries()
		_check(bool(sim.intention_flags.get("stone_deposit_found", false)), "a stone deposit flags the shortage intention")


func _feature(sim: Simulation, kind: String) -> Dictionary:
	for feature in sim.world_features:
		if String(feature.get("kind", "")) == kind:
			return feature
	return {}


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
