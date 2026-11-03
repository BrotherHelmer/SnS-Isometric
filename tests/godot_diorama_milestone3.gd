extends SceneTree
## Milestone 3 acceptance test (check 2 of the M1/M2 pattern, adapted to
## the M3 scope in GAMEPLAY_PLAN.md section 4): the province minimap is
## reconciled with the heightfield (relief shading from the sim height
## levels + a brighter visible-now state matching the world fog's
## building vision); diorama building geometry is shared per type; the
## per-building grounding discs are baked into one mesh. Fog and night /
## raid presentation are covered by the engine captures, not here.
## Run: godot --headless --path . --script res://tests/godot_diorama_milestone3.gd

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Minimap = preload("res://src/GodotClient3D/Scripts/production_minimap.gd")
const BuildingView = preload("res://src/GodotClient3D/Scripts/production_building_view_3d.gd")
const DioramaBuildings = preload("res://src/GodotClient3D/Scripts/production_diorama_buildings.gd")

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


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# --- Sim: founding --------------------------------------------------
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
	sim._reveal_radius(sim.town_hall_position, 40)

	# --- Minimap: relief shading + visible-now state --------------------
	var minimap = Minimap.new()
	minimap.bind(sim, null, null)
	var image: Image = minimap._render_terrain(sim.map_size)
	_check(image != null and image.get_width() == sim.map_size.x, "minimap renders a full-map terrain image")
	# Two revealed grass tiles at different heights must shade differently.
	var low_tile := Vector2i(-1, -1)
	var high_tile := Vector2i(-1, -1)
	var low_h := 999
	var high_h := -1
	for y in range(sim.map_size.y):
		for x in range(sim.map_size.x):
			var t := Vector2i(x, y)
			if not sim.is_revealed(t) or String(sim.get_tile(t)) != Defs.TILE_GRASS:
				continue
			if sim.has_method("is_water_tile") and sim.is_water_tile(t):
				continue
			var h := int(sim.get_height(t))
			if h < low_h:
				low_h = h
				low_tile = t
			if h > high_h:
				high_h = h
				high_tile = t
	_check(high_h - low_h >= 2, "revealed area spans relief (heights %d..%d)" % [low_h, high_h])
	if high_tile.x >= 0 and low_tile.x >= 0:
		var low_px := image.get_pixel(low_tile.x, low_tile.y)
		var high_px := image.get_pixel(high_tile.x, high_tile.y)
		var low_lum := low_px.r + low_px.g + low_px.b
		var high_lum := high_px.r + high_px.g + high_px.b
		_check(high_lum > low_lum + 0.05, "higher ground shades brighter on the minimap (%.2f vs %.2f)" % [high_lum, low_lum])
	# Town Hall centre sits inside building vision: expected pixel is the
	# relief-shaded grass lightened by the visible-now factor.
	var centre: Vector2i = sim._footprint_center(sim.town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	var ch := float(sim.get_height(centre))
	var chx := float(sim.get_height(Vector2i(mini(centre.x + 1, sim.map_size.x - 1), centre.y)))
	var chz := float(sim.get_height(Vector2i(centre.x, mini(centre.y + 1, sim.map_size.y - 1))))
	var shade := clampf(0.80 + ch * 0.030 + (ch - chx) * 0.05 + (ch - chz) * 0.05, 0.62, 1.30)
	var base := Color("#4d8a3e")
	var expected := Color(base.r * shade, base.g * shade, base.b * shade).lightened(0.22)
	var actual := image.get_pixel(centre.x, centre.y)
	_check(absf(actual.r - expected.r) < 0.03 and absf(actual.g - expected.g) < 0.03 and absf(actual.b - expected.b) < 0.03, "Town Hall tile shows shaded + visible-now tint (got %s want %s)" % [str(actual), str(expected)])
	minimap.free()

	# --- Perf: diorama geometry shared per type/variant ------------------
	var house_a := DioramaBuildings.build("HOUSE", 5)
	var house_b := DioramaBuildings.build("HOUSE", 5)
	var shared := house_a.get_child_count() > 0 and house_a.get_child_count() == house_b.get_child_count()
	if shared:
		for i in range(house_a.get_child_count()):
			if (house_a.get_child(i) as MeshInstance3D).mesh != (house_b.get_child(i) as MeshInstance3D).mesh:
				shared = false
	_check(shared, "two Houses of one variant share their merged meshes")
	var house_c := DioramaBuildings.build("HOUSE", 6)
	var differs := false
	for i in range(mini(house_a.get_child_count(), house_c.get_child_count())):
		if (house_a.get_child(i) as MeshInstance3D).mesh != (house_c.get_child(i) as MeshInstance3D).mesh:
			differs = true
	_check(differs, "a different House variant keeps its own meshes")
	var saw_a := DioramaBuildings.build("SAWMILL", 1)
	var saw_b := DioramaBuildings.build("SAWMILL", 99)
	var saw_shared := saw_a.get_child_count() == saw_b.get_child_count()
	if saw_shared:
		for i in range(saw_a.get_child_count()):
			if (saw_a.get_child(i) as MeshInstance3D).mesh != (saw_b.get_child(i) as MeshInstance3D).mesh:
				saw_shared = false
	_check(saw_shared, "Sawmills share meshes regardless of entity id")
	house_a.free()
	house_b.free()
	house_c.free()
	saw_a.free()
	saw_b.free()

	# --- Perf: grounding discs baked into one mesh ------------------------
	var view = BuildingView.new()
	get_root().add_child(view)
	view.configure({"id": 3, "type": "HOUSE", "footprint": Defs.building_footprint("HOUSE"), "construction": false, "rotation": 0})
	_check(view.find_child("WorkyardDirt", true, false) == null and view.find_child("WorkyardApron", true, false) == null and view.find_child("ContactAO", true, false) == null, "loose grounding discs are gone after the merge")
	var merged := view.find_child("GroundingMerged", true, false) as MeshInstance3D
	_check(merged != null and merged.mesh != null and merged.mesh.get_surface_count() == 3, "grounding discs baked into one 3-surface mesh")
	view.queue_free()

	# --- Verdict ----------------------------------------------------------
	if failures.is_empty():
		print("MILESTONE3 PASS")
		quit(0)
	else:
		print("MILESTONE3 FAIL (%d checks failed)" % failures.size())
		quit(1)
