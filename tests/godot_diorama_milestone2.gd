extends SceneTree
## Milestone 2 acceptance test (checks 2+3 of the M1 pattern, adapted to
## the M2 scope in GAMEPLAY_PLAN.md section 4): the sim accepts and
## completes the full M2 building family; every M2 type builds its
## diorama model in ProductionBuildingView3D (CASTLE keeps the legacy
## authored keep); sim-driven scatter keys resolve to diorama nature
## meshes carrying their own materials; road ribbons drape over a sloped
## height sampler and stay flat when no sampler is assigned.
## Run: godot --headless --path . --script res://tests/godot_diorama_milestone2.gd

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const BuildingView = preload("res://src/GodotClient3D/Scripts/production_building_view_3d.gd")
const WorldView = preload("res://src/GodotClient3D/Scripts/production_world_view_3d.gd")
const RoadView = preload("res://src/GodotClient3D/Scripts/production_road_view_3d.gd")
const DioramaBuildings = preload("res://src/GodotClient3D/Scripts/production_diorama_buildings.gd")

const FAMILY := ["HOUSE", "LUMBER_CAMP", "FARM", "STOREHOUSE", "SAWMILL", "QUARRY", "BAKERY", "BARRACKS", "WATCHTOWER", "WALL"]
const DIORAMA_TYPES := ["SAWMILL", "FARM", "BAKERY", "STOREHOUSE", "QUARRY", "WATCHTOWER", "BARRACKS"]

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


func _place_roads(sim, near: Vector2i, count: int) -> void:
	var placed := 0
	for i in range(count * 6):
		if placed >= count:
			return
		var t := _find_valid(sim, Defs.BUILDING_ROAD, near, 12)
		if t.x == -9999:
			return
		var res: Dictionary = sim.request_build(Defs.BUILDING_ROAD, t, 0)
		if bool(res.get("success", false)):
			placed += 1


func _advance_until_complete(sim, building_id: int, max_ticks: int) -> bool:
	for i in range(max_ticks):
		var done := true
		for b_value in sim.get_buildings():
			var b: Dictionary = b_value
			if int(b.get("id", 0)) == building_id:
				done = not bool(b.get("construction", false))
				break
		if done:
			return true
		sim.advance_tick()
	return false


func _advance_until_cargo(sim, resource_type: String, building_id: int, max_ticks: int) -> bool:
	for i in range(max_ticks):
		for w_value in sim.get_workers():
			var w: Dictionary = w_value
			if String(w.get("carried_resource", "")) == resource_type and int(w.get("carried_amount", 0)) > 0:
				return true
		sim.advance_tick()
	var building: Dictionary = sim.get_building_by_id(building_id)
	return not building.is_empty() and int(Dictionary(building.get("local_inventory", {})).get(resource_type, 0)) > 0


func _completed_count(sim, building_type: String) -> int:
	var n := 0
	for b_value in sim.get_buildings():
		var b: Dictionary = b_value
		if String(b.get("type", "")) == building_type and not bool(b.get("construction", false)):
			n += 1
	return n


func _slope_height(logical: Vector2) -> float:
	return logical.x * 0.45


func _mesh_stats(root_node: Node) -> Array:
	var instances := 0
	var textured := false
	for child in root_node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi.mesh == null:
			continue
		instances += 1
		if mi.material_override is StandardMaterial3D and (mi.material_override as StandardMaterial3D).albedo_texture != null:
			textured = true
		for s in range(mi.mesh.get_surface_count()):
			var mat := mi.mesh.surface_get_material(s)
			if mat is StandardMaterial3D and (mat as StandardMaterial3D).albedo_texture != null:
				textured = true
	return [instances, textured]


func _y_range(root_node: Node) -> Array:
	var lo := 1e9
	var hi := -1e9
	for child in root_node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in range(mi.mesh.get_surface_count()):
			var arrays := mi.mesh.surface_get_arrays(s)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			for v in verts:
				lo = minf(lo, v.y)
				hi = maxf(hi, v.y)
	return [lo, hi]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# --- Sim: founding + full M2 family --------------------------------
	var sim = Simulation.new(70, 70, 424242, false, false)
	var th_tile := _find_valid(sim, Defs.BUILDING_TOWN_HALL, Vector2i(35, 35), 30)
	_check(th_tile.x != -9999, "found a valid Town Hall tile")
	var res: Dictionary = sim.request_build(Defs.BUILDING_TOWN_HALL, th_tile, 0)
	_check(bool(res.get("success", false)), "Town Hall founding request accepted")
	var ticks := 0
	while not sim.is_town_hall_founded() and ticks < 6000:
		sim.advance_tick()
		ticks += 1
	_check(sim.is_town_hall_founded(), "Town Hall founded (ticks=%d)" % ticks)
	_place_roads(sim, th_tile, 10)
	var quarry_id := 0
	for building_type in FAMILY:
		if quarry_id > 0 and building_type in ["WATCHTOWER", "WALL"]:
			# Stone consumers wait for a fresh quarry haul, sequenced the
			# way the game fixture sequences its developed stage.
			_advance_until_cargo(sim, Defs.RESOURCE_STONE, quarry_id, 3600)
		var tile := _find_valid(sim, building_type, th_tile, 26)
		if tile.x == -9999:
			_place_roads(sim, th_tile, 8)
			tile = _find_valid(sim, building_type, th_tile, 26)
		_check(tile.x != -9999, "valid %s tile exists" % building_type)
		if tile.x == -9999:
			continue
		res = sim.request_build(building_type, tile, 0)
		_check(bool(res.get("success", false)), "%s build requested: %s" % [building_type, String(res.get("message", ""))])
		if not bool(res.get("success", false)):
			continue
		var bid := int(Dictionary(res.get("building", {})).get("id", 0))
		_check(_advance_until_complete(sim, bid, 2400), "%s construction completed" % building_type)
		if building_type == "QUARRY":
			quarry_id = bid
			_advance_until_cargo(sim, Defs.RESOURCE_STONE, bid, 3600)
		_place_roads(sim, th_tile, 4)
	for building_type in FAMILY:
		_check(_completed_count(sim, building_type) >= 1, "sim holds a completed %s" % building_type)
	print("INFO inventory: ", sim.central_inventory)

	# --- Views: diorama models for the M2 family ------------------------
	for building_type in DIORAMA_TYPES + ["TOWN_HALL", "HOUSE", "LUMBER_CAMP"]:
		var view = BuildingView.new()
		get_root().add_child(view)
		view.configure({"id": 7, "type": building_type, "footprint": Defs.building_footprint(building_type), "construction": false, "rotation": 0})
		var stats := _mesh_stats(view)
		_check(view.model_root != null and int(stats[0]) >= 1, "%s view builds a model (%d mesh instances)" % [building_type, int(stats[0])])
		_check(bool(stats[1]), "%s diorama model carries painted textures" % building_type)
		view.queue_free()
	# WALL: mask-connected segments keep their geometry, gain the diorama
	# stone and cap slabs.
	var wall = BuildingView.new()
	get_root().add_child(wall)
	wall.configure({"id": 8, "type": "WALL", "footprint": Vector2i.ONE, "construction": false, "rotation": 0, "wall_mask": 15})
	var wall_stats := _mesh_stats(wall)
	_check(wall.model_root != null and int(wall_stats[0]) >= 5, "WALL view builds connected segments + caps (%d mesh instances)" % int(wall_stats[0]))
	_check(bool(wall_stats[1]), "WALL segments carry the diorama stone texture")
	wall.queue_free()
	# CASTLE deliberately stays on the legacy authored keep.
	var castle = BuildingView.new()
	get_root().add_child(castle)
	castle.configure({"id": 9, "type": "CASTLE", "footprint": Defs.building_footprint("CASTLE"), "construction": false, "rotation": 0})
	_check(castle.model_root != null and int(_mesh_stats(castle)[0]) >= 1, "CASTLE view still builds the authored keep")
	castle.queue_free()

	# --- Scatter: sim-driven keys -> diorama nature meshes --------------
	var world = WorldView.new()
	var key := world._tree_path_for_tile(Vector2i(11, 23), 0, 3)
	_check(key.begins_with("diorama://"), "dense-forest tile picks a diorama tree key (%s)" % key)
	for nature_key in ["diorama://spruce_a", "diorama://spruce_b", "diorama://oak_a", "diorama://oak_b", "diorama://rock_a"]:
		var mesh := DioramaBuildings.nature_mesh(nature_key)
		var min_surfaces := 1 if nature_key.ends_with("rock_a") else 2
		_check(mesh != null and mesh.get_surface_count() >= min_surfaces, "%s resolves to a diorama mesh (%d surfaces)" % [nature_key, mesh.get_surface_count() if mesh != null else 0])
		_check(world._mesh_for_nature_path(nature_key) == mesh, "world view resolves %s" % nature_key)
		_check(world._foliage_material(mesh, nature_key) == null, "world view keeps diorama materials for %s" % nature_key)
	world.free()

	# --- Roads: drape over the sampler, flat without it ------------------
	RoadView.height_sampler = Callable(self, "_slope_height")
	var road = RoadView.new()
	get_root().add_child(road)
	road.configure(1, Vector2i(5, 5), 0b1111, false)
	var draped := _y_range(road)
	_check(float(draped[1]) - float(draped[0]) > 0.3, "road ribbon follows a sloped height sampler (dy=%.3f)" % (float(draped[1]) - float(draped[0])))
	road.queue_free()
	RoadView.height_sampler = Callable()
	var flat_road = RoadView.new()
	get_root().add_child(flat_road)
	flat_road.configure(2, Vector2i(5, 5), 0b1111, false)
	var flat_range := _y_range(flat_road)
	# Without a sampler the two road layers keep their flat lifts
	# (0.042 skirt / 0.062 dirt), so the y range is exactly that gap.
	_check(float(flat_range[1]) - float(flat_range[0]) < 0.021, "road ribbon stays flat without a sampler (dy=%.4f)" % (float(flat_range[1]) - float(flat_range[0])))
	flat_road.queue_free()

	# --- Verdict ----------------------------------------------------------
	if failures.is_empty():
		print("MILESTONE2 PASS")
		quit(0)
	else:
		print("MILESTONE2 FAIL (%d checks failed)" % failures.size())
		quit(1)
