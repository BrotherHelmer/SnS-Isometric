extends SceneTree
## Milestone 4 acceptance test (check 2 of the M1/M2 pattern, adapted to
## the M4 scope in GAMEPLAY_PLAN.md section 4): Sovereign / wyrd / rival
## presentation on the diorama base (Lumen Pillar, Claimant Outpost, Wyrd
## Harvester, Wyrd Refiner views), objectives polish (every chain
## objective carries a why-line), and the sovereign fixture stage placing
## the pillar / outpost / refiner through authoritative validation on a
## full-size realm. Release-pipeline and fixed-seed gate evidence live in
## MILESTONE4_ASSESSMENT.md, not here.
## Run: godot --headless --path . --script res://tests/godot_diorama_milestone4.gd

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Tuning = preload("res://src/GodotClient/Scripts/one_shard_rivalry_tuning.gd")
const BuildingView = preload("res://src/GodotClient3D/Scripts/production_building_view_3d.gd")
const DioramaBuildings = preload("res://src/GodotClient3D/Scripts/production_diorama_buildings.gd")
const Fixture = preload("res://src/GodotClient3D/Scripts/production_demo_fixture.gd")
const GameRoot = preload("res://src/GodotClient3D/Scripts/production_3d_game_root.gd")

var failures: Array[String] = []


func _check(cond: bool, label: String) -> void:
	if cond:
		print("PASS ", label)
	else:
		failures.append(label)
		print("FAIL ", label)


func _mesh_stats(root_node: Node) -> Array:
	var instances := 0
	var textured := false
	var emissive := false
	for child in root_node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi.mesh == null:
			continue
		instances += 1
		if mi.material_override is StandardMaterial3D:
			var override_mat := mi.material_override as StandardMaterial3D
			if override_mat.albedo_texture != null:
				textured = true
			if override_mat.emission_enabled:
				emissive = true
		for s in range(mi.mesh.get_surface_count()):
			var mat := mi.mesh.surface_get_material(s)
			if mat is StandardMaterial3D:
				var surface_mat := mat as StandardMaterial3D
				if surface_mat.albedo_texture != null:
					textured = true
				if surface_mat.emission_enabled:
					emissive = true
	return [instances, textured, emissive]


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


func _objective_flag(sim, objective_id: String) -> bool:
	for objective_value in sim.get_objectives():
		var objective: Dictionary = objective_value
		if String(objective.get("id", "")) == objective_id:
			return bool(objective.get("complete", false))
	return false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# --- Objectives: the 11-step chain and its why-lines -----------------
	var sim = Simulation.new(70, 70, 424242, false, false)
	var chain_ids: Array = []
	for objective_value in sim.get_objectives():
		var objective: Dictionary = objective_value
		chain_ids.append(String(objective.get("id", "")))
	_check(chain_ids == ["found", "road", "house", "lumber", "farm", "storehouse", "watchtower", "wyrd", "lumen", "outpost", "claim"], "objective chain lists the 11 steps in order (%s)" % str(chain_ids))
	var root = GameRoot.new()
	for objective_value in sim.get_objectives():
		var objective: Dictionary = objective_value
		var text := String(objective.get("text", "")).to_lower()
		_check(String(root._objective_why(text)) != "", "objective '%s' carries a why-line" % String(objective.get("id", "")))
	_check("Refiner" in String(root._objective_why("harvest a wyrd node with an outpost")), "wyrd objective why names the Refiner, not the rival")
	_check("Storehouse" in String(root._objective_why("build a storehouse when storage fills up")), "storehouse objective why is about storage")
	_check(String(root._objective_why("build an outpost toward the shard")) != String(root._objective_why("the rival outpost pressures your border")), "player Outpost and rival Outpost whys differ")
	root.free()

	# --- Founding completes the first objective ---------------------------
	var th_tile := _find_valid(sim, Defs.BUILDING_TOWN_HALL, Vector2i(35, 35), 30)
	_check(th_tile.x != -9999, "found a valid Town Hall tile")
	var res: Dictionary = sim.request_build(Defs.BUILDING_TOWN_HALL, th_tile, 0)
	_check(bool(res.get("success", false)), "Town Hall founding request accepted")
	var ticks := 0
	while not sim.is_town_hall_founded() and ticks < 6000:
		sim.advance_tick()
		ticks += 1
	_check(sim.is_town_hall_founded(), "Town Hall founded (ticks=%d)" % ticks)
	_check(_objective_flag(sim, "found"), "'found' objective completes on founding")

	# --- Sovereign / wyrd / rival views ------------------------------------
	var emissive_types := [Defs.BUILDING_LUMEN_PILLAR, Defs.BUILDING_WYRD_HARVESTER, Defs.BUILDING_WYRD_REFINER]
	for building_type in emissive_types + [Defs.BUILDING_OUTPOST]:
		var view = BuildingView.new()
		get_root().add_child(view)
		view.configure({"id": 11, "type": building_type, "footprint": Defs.building_footprint(building_type), "construction": false, "rotation": 0})
		var stats := _mesh_stats(view)
		_check(view.model_root != null and int(stats[0]) >= 1, "%s view builds a diorama model (%d mesh instances)" % [building_type, int(stats[0])])
		if building_type in emissive_types:
			_check(bool(stats[2]), "%s model carries an emissive crystal material" % building_type)
		view.queue_free()
	# Shared geometry extends to the new types (M3 perf pattern).
	var pillar_a := DioramaBuildings.build(Defs.BUILDING_LUMEN_PILLAR, 3)
	var pillar_b := DioramaBuildings.build(Defs.BUILDING_LUMEN_PILLAR, 4)
	var shared := pillar_a.get_child_count() > 0 and pillar_a.get_child_count() == pillar_b.get_child_count()
	if shared:
		for i in range(pillar_a.get_child_count()):
			if (pillar_a.get_child(i) as MeshInstance3D).mesh != (pillar_b.get_child(i) as MeshInstance3D).mesh:
				shared = false
	_check(shared, "two Lumen Pillars share their merged meshes")
	pillar_a.free()
	pillar_b.free()

	# --- Sovereign fixture stage on a full-size realm -----------------------
	var realm = Simulation.new(320, 320, 424242, false, true)
	var fixture = Fixture.new()
	fixture.apply(realm, "sovereign")
	for building_type in [Defs.BUILDING_LUMEN_PILLAR, Defs.BUILDING_OUTPOST, Defs.BUILDING_WYRD_REFINER]:
		_check(int(fixture.building_ids.get(building_type, 0)) > 0, "sovereign fixture places %s" % building_type)
	var structure_types: Array = []
	for structure_value in realm.rivalry.get_structures(Tuning.PLAYER_REALM):
		var structure: Dictionary = structure_value
		structure_types.append(String(structure.get("type", "")))
	_check(Tuning.STRUCTURE_LUMEN_PILLAR in structure_types, "player realm holds a Lumen Pillar structure")
	_check(Tuning.STRUCTURE_CLAIMANT_OUTPOST in structure_types, "player realm holds a Claimant Outpost structure")
	var refiner_done := false
	for building_value in realm.buildings:
		var building: Dictionary = building_value
		if String(building.get("type", "")) == Defs.BUILDING_WYRD_REFINER and not bool(building.get("construction", false)):
			refiner_done = true
	_check(refiner_done, "sovereign fixture completes a Wyrd Refiner")
	_check(_objective_flag(realm, "outpost"), "'outpost' objective completes from the fixture Outpost")
	_check(_objective_flag(realm, "lumen"), "'lumen' objective completes from the fixture Pillar")
	var site_failures := 0
	for line in fixture.report:
		if "No valid Lumen Pillar site" in line or "No valid Outpost site" in line:
			site_failures += 1
	_check(site_failures == 0, "sovereign fixture reports no site failures")

	print("MILESTONE4_TEST %s (%d failures)" % ["PASS" if failures.is_empty() else "FAIL", failures.size()])
	quit(0 if failures.is_empty() else 1)
