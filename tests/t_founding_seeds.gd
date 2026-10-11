extends SceneTree

## 100-seed founding-site gate. Every new game must have one real Town Hall,
## no fake buildings, an irregular clearing, reachable wood/stone/food,
## bridges that cross the creek, and a Lumber Camp quest. Lore: the start
## sits inside the harvest radius on stable ground outside the pit, with
## water/trees/stone/food within FOUNDING_RESOURCE_NEAR tiles and a visible
## wyrd/crater marker. ChatGPT #11: 360° orbit, distance band, layout variety.

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")

const SEED_COUNT := 100
const BASE_SEED := 260821
const SECTOR_MIN := 6
const SECTOR_MAX_SHARE := 0.25
const UNIQUE_LAYOUT_MIN := 12

var failures: Array[String] = []
var rows: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var dest := ProjectSettings.globalize_path("res://artifacts/first_screen")
	DirAccess.make_dir_recursive_absolute(dest)
	var t0 := Time.get_ticks_msec()
	var passed := 0
	var sectors: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0]
	var water_seen: Dictionary = {}
	var signatures: Dictionary = {}
	var compass_names := ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
	for i in SEED_COUNT:
		var seed_value := BASE_SEED + i * 97
		var sim = Simulation.new()
		sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, seed_value, true)
		var audit: Dictionary = sim.founding_audit()
		var ok := _check_audit(audit, seed_value)
		if ok:
			passed += 1
		var sector := clampi(int(audit.get("orbit_sector", 0)), 0, 7)
		sectors[sector] += 1
		water_seen[String(audit.get("water_type", ""))] = true
		signatures[String(audit.get("layout_signature", ""))] = true
		var row := "%d\t%d\t%d\t%d\t%.1f\t%.1f" % [
			seed_value,
			int(audit.get("functional_buildings", -1)),
			int(audit.get("fake_buildings", -1)),
			int(audit.get("clearing_trees", -1)),
			float(audit.get("clearing_rx", 0.0)),
			float(audit.get("clearing_ry", 0.0)),
		]
		row += "\t%s\t%s\t%s\t%s\t%s\t%s" % [
			str(audit.get("tree_reachable", false)),
			str(audit.get("rock_reachable", false)),
			str(audit.get("food_reachable", false)),
			str(audit.get("bridges_cross", false)),
			str(audit.get("quest_target", false)),
			str(audit.get("inside_crater", false)),
		]
		row += "\t%.1f\t%.1f\t%s\t%s\t%s\t%s\t%s\t%s\t%.1f\t%d\t%s\t%s\t%s\t%s" % [
			float(audit.get("crater_dist", -1.0)),
			float(audit.get("slope", -1.0)),
			str(audit.get("water_near", false)),
			str(audit.get("tree_near", false)),
			str(audit.get("rock_near", false)),
			str(audit.get("food_near", false)),
			str(audit.get("wyrd_marker", false)),
			String(audit.get("crater_compass", "")),
			float(audit.get("orbit_deg", -1.0)),
			sector,
			String(audit.get("water_type", "")),
			String(audit.get("layout_signature", "")),
			str(audit.get("distance_band", false)),
			"PASS" if ok else "FAIL",
		]
		rows.append(row)
	var sim_ms := float(Time.get_ticks_msec() - t0)
	print("T_FOUNDING_SEEDS sim_pass=%d/%d sim_ms=%.0f" % [passed, SEED_COUNT, sim_ms])

	var hist_lines: Array[String] = []
	hist_lines.append("sector\tlabel\tcount\tpct")
	var max_share := 0.0
	for sector_i in 8:
		var count := sectors[sector_i]
		var pct := float(count) / float(SEED_COUNT)
		max_share = maxf(max_share, pct)
		hist_lines.append("%d\t%s\t%d\t%.1f" % [sector_i, compass_names[sector_i], count, pct * 100.0])
		_check(count >= SECTOR_MIN, "orbit sector %s has at least %d seeds (got %d)" % [compass_names[sector_i], SECTOR_MIN, count])
	_check(max_share <= SECTOR_MAX_SHARE + 0.001, "no orbit sector exceeds 25%% (max %.1f%%)" % (max_share * 100.0))
	_check(water_seen.size() >= 3, "at least 3 water types across 100 seeds (got %s)" % str(water_seen.keys()))
	_check(signatures.size() >= UNIQUE_LAYOUT_MIN, "at least %d unique layout signatures (got %d)" % [UNIQUE_LAYOUT_MIN, signatures.size()])
	var water_names: PackedStringArray = []
	for water_key in water_seen.keys():
		water_names.append(String(water_key))
	hist_lines.append("unique_layouts=%d" % signatures.size())
	hist_lines.append("water_types=%s" % ",".join(water_names))
	hist_lines.append("max_sector_share=%.3f" % max_share)
	print("T_FOUNDING_SEEDS sectors=%s unique_layouts=%d waters=%s" % [str(sectors), signatures.size(), str(water_seen.keys())])

	var mesh_seeds := [BASE_SEED, BASE_SEED + 97, BASE_SEED + 194]
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var render_pass := 0
	var render_fail := 0
	for i in SEED_COUNT:
		var seed_value := BASE_SEED + i * 97
		var t1 := Time.get_ticks_msec()
		game.start_new_3d(int(seed_value))
		game._hide_start_menu()
		game.simulation_host.paused = true
		if game.has_method("_update_ui"):
			game._update_ui()
		game.world_view.note_camera(game.world_view.opening_camera_focus(), 32.0)
		for _i in 3:
			await process_frame
			game.world_view.stream_chunks(7000)
		await RenderingServer.frame_post_draw
		var start_ms := float(Time.get_ticks_msec() - t1)
		var view: Dictionary = game.world_view.opening_view_audit(game.camera_rig.camera)
		var image: Image = root.get_viewport().get_texture().get_image()
		var land := _three_d_land_ratio(image)
		var ok_view := int(view.get("near_built", 0)) >= 1 and int(view.get("near_visible", 0)) >= 1
		var ok_hall := bool(view.get("hall_in_view", false))
		var ok_land := land >= 0.60
		if ok_view and ok_hall and ok_land:
			render_pass += 1
		else:
			render_fail += 1
		_check(ok_view, "seed %d opening near chunks are built and visible (built=%d visible=%d missing=%s)" % [
			seed_value, int(view.get("near_built", 0)), int(view.get("near_visible", 0)), str(view.get("missing", []))
		])
		_check(ok_hall, "seed %d hall mesh is in the opening camera" % seed_value)
		_check(ok_land, "seed %d first frame has >=60%% land in the 3D area (%.1f%%)" % [seed_value, land * 100.0])
		if seed_value in mesh_seeds or not (ok_view and ok_hall and ok_land):
			print("T_FOUNDING_SEEDS render_seed=%d land=%.3f near=%d/%d hall=%s start_ms=%.0f" % [
				seed_value, land, int(view.get("near_visible", 0)), int(view.get("near_built", 0)),
				str(ok_hall), start_ms
			])
		if seed_value in mesh_seeds:
			var fake: Array[String] = game.world_view.non_inspectable_building_meshes(-1.0)
			print("T_FOUNDING_SEEDS mesh_seed=%d fake=%s start_ms=%.0f" % [seed_value, str(fake), start_ms])
			_check(fake.is_empty(), "seed %d has 0 fake building meshes" % seed_value)
			var sim = game.simulation_host.simulation
			var audit: Dictionary = sim.founding_audit()
			_check(int(audit.get("functional_buildings", 0)) == 1, "seed %d 3D has one Town Hall" % seed_value)
			_check(game.objective_button != null and String(game.objective_button.text).contains("Lumber Camp"), "seed %d HUD quest says Lumber Camp" % seed_value)
			_check(bool(audit.get("inside_crater", false)), "seed %d start is inside the crater" % seed_value)
			_check(bool(audit.get("distance_band", false)), "seed %d Town Hall is in the harvest distance band" % seed_value)
			var dress: Node = game.world_view.resource_visuals_root.get_node_or_null("OpeningDress")
			var traces: Node = dress.find_child("DressWyrdTrace_0", true, false) if dress != null else null
			var beacon: Node = game.world_view.shard_beacon
			_check(traces != null, "seed %d has a DressWyrdTrace visible from the start" % seed_value)
			_check(beacon != null, "seed %d still has the ShardBeacon toward the crater" % seed_value)
			_check(dress == null or dress.find_child("DressWyrdGlow", true, false) == null, "seed %d has no DressWyrdGlow" % seed_value)
			print("T_FOUNDING_SEEDS crater_seed=%d compass=%s dist=%.1f hall=%s shard=%s dir=%s orbit=%.1f water=%s layout=%s" % [
				seed_value, String(audit.get("crater_compass", "")), float(audit.get("crater_dist", -1.0)),
				str(audit.get("hall", Vector2i.ZERO)), str(audit.get("shard", Vector2i.ZERO)),
				str(audit.get("crater_dir", Vector2.ZERO)), float(audit.get("orbit_deg", -1.0)),
				String(audit.get("water_type", "")), String(audit.get("layout_signature", ""))
			])
	print("T_FOUNDING_SEEDS render_pass=%d/%d render_fail=%d" % [render_pass, SEED_COUNT, render_fail])
	_check(render_pass == SEED_COUNT, "every seed opening frame shows built chunks, the hall, and >=60%% land")

	var report := dest.path_join("founding_seeds.txt")
	var file := FileAccess.open(report, FileAccess.WRITE)
	if file != null:
		file.store_line("seed\tfunctional\tfake\tclearing_trees\trx\try\ttree\trock\tfood\tbridges\tquest\tcrater\tdist\tslope\twater\ttree_n\trock_n\tfood_n\twyrd\tcompass\torbit\tsector\twater_type\tlayout\tband\tresult")
		for row in rows:
			file.store_line(row)
		file.store_line("sim_pass=%d/%d sim_ms=%.0f unique_layouts=%d" % [passed, SEED_COUNT, sim_ms, signatures.size()])
		file.close()
	var hist_path := dest.path_join("founding_angle_histogram.txt")
	var hist := FileAccess.open(hist_path, FileAccess.WRITE)
	if hist != null:
		for line in hist_lines:
			hist.store_line(line)
		hist.close()
	print("T_FOUNDING_SEEDS report=%s histogram=%s" % [report, hist_path])
	print("T_FOUNDING_SEEDS %s" % ("PASS" if failures.is_empty() else "FAIL"))
	for failure in failures:
		print("  FAIL %s" % failure)
	if game != null:
		game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)


func _check_audit(audit: Dictionary, seed_value: int) -> bool:
	var ok := true
	ok = _check(int(audit.get("functional_buildings", 0)) == 1, "seed %d exactly 1 functional building" % seed_value) and ok
	ok = _check(int(audit.get("fake_buildings", 1)) == 0, "seed %d 0 fake buildings" % seed_value) and ok
	ok = _check(int(audit.get("clearing_trees", 1)) == 0, "seed %d clearing has no trees" % seed_value) and ok
	ok = _check(int(audit.get("clearing_rocks", 1)) == 0, "seed %d clearing has no rocks" % seed_value) and ok
	ok = _check(float(audit.get("clearing_rx", 0.0)) >= 7.0 and float(audit.get("clearing_rx", 0.0)) <= 10.0, "seed %d clearing rx in range" % seed_value) and ok
	ok = _check(float(audit.get("clearing_ry", 0.0)) >= 6.0 and float(audit.get("clearing_ry", 0.0)) <= 10.0, "seed %d clearing ry in range" % seed_value) and ok
	ok = _check(bool(audit.get("tree_reachable", false)), "seed %d wood reachable" % seed_value) and ok
	ok = _check(bool(audit.get("rock_reachable", false)), "seed %d stone reachable" % seed_value) and ok
	ok = _check(bool(audit.get("food_reachable", false)), "seed %d food reachable" % seed_value) and ok
	ok = _check(bool(audit.get("creek_continuous", false)), "seed %d creek is continuous" % seed_value) and ok
	ok = _check(bool(audit.get("bridges_cross", false)), "seed %d bridges cross water" % seed_value) and ok
	ok = _check(bool(audit.get("quest_target", false)), "seed %d quest targets Lumber Camp" % seed_value) and ok
	ok = _check(bool(audit.get("inside_crater", false)), "seed %d start is inside the crater radius" % seed_value) and ok
	ok = _check(bool(audit.get("slope_ok", false)), "seed %d slope is below the founding threshold" % seed_value) and ok
	ok = _check(bool(audit.get("water_near", false)), "seed %d water is within %d tiles" % [seed_value, Simulation.FOUNDING_RESOURCE_NEAR]) and ok
	ok = _check(bool(audit.get("tree_near", false)), "seed %d trees are within %d tiles" % [seed_value, Simulation.FOUNDING_RESOURCE_NEAR]) and ok
	ok = _check(bool(audit.get("rock_near", false)), "seed %d stone is within %d tiles" % [seed_value, Simulation.FOUNDING_RESOURCE_NEAR]) and ok
	ok = _check(bool(audit.get("food_near", false)), "seed %d food is within %d tiles" % [seed_value, Simulation.FOUNDING_RESOURCE_NEAR]) and ok
	ok = _check(bool(audit.get("wyrd_marker", false)), "seed %d has a wyrd/crater marker toward the start" % seed_value) and ok
	ok = _check(bool(audit.get("distance_band", false)), "seed %d Town Hall is in the 0.65–0.85 R band" % seed_value) and ok
	ok = _check(bool(audit.get("footprint_stable", false)), "seed %d Town Hall footprint is stable outside the pit" % seed_value) and ok
	var pit := float(audit.get("pit_radius", 0.0))
	ok = _check(pit >= Simulation.CRATER_RADIUS * Simulation.CRATER_PIT_RADIUS_MIN - 0.05 and pit <= Simulation.CRATER_RADIUS * Simulation.CRATER_PIT_RADIUS_MAX + 0.05, "seed %d pit radius is 0.30–0.45 R" % seed_value) and ok
	ok = _check(int(audit.get("rival_count", 0)) >= Simulation.RIVAL_SEAT_MIN and int(audit.get("rival_count", 0)) <= Simulation.RIVAL_SEAT_MAX, "seed %d has 3–4 rival seats" % seed_value) and ok
	var spread: Dictionary = audit.get("resource_spread", {})
	ok = _check(int(spread.get("filled_quadrants", 0)) >= 3, "seed %d resources reach at least 3 quadrants" % seed_value) and ok
	ok = _check(int(spread.get("trees", 0)) >= 80, "seed %d has distributed timber" % seed_value) and ok
	ok = _check(int(spread.get("water", 0)) >= 5, "seed %d has province water" % seed_value) and ok
	var map_size: Vector2i = audit.get("map_size", Vector2i.ZERO)
	ok = _check(map_size.x == Simulation.MAP_WIDTH and map_size.y == Simulation.MAP_HEIGHT, "seed %d is the 320 province" % seed_value) and ok
	return ok


func _three_d_land_ratio(image: Image) -> float:
	if image == null or image.is_empty():
		return 0.0
	var width := image.get_width()
	var height := image.get_height()
	var y0 := clampi(int(round(float(height) * 0.09)), 0, height - 1)
	var y1 := clampi(int(round(float(height) * 0.86)), y0 + 1, height)
	var void_c := Color("#17272A")
	var land := 0
	var total := 0
	var step := 3
	for y in range(y0, y1, step):
		for x in range(0, width, step):
			var pixel: Color = image.get_pixel(x, y)
			total += 1
			var dist := absf(pixel.r - void_c.r) + absf(pixel.g - void_c.g) + absf(pixel.b - void_c.b)
			var luma := pixel.r * 0.22 + pixel.g * 0.72 + pixel.b * 0.06
			if dist > 0.10 and luma > 0.12:
				land += 1
	return float(land) / float(maxi(total, 1))


func _check(condition: bool, label: String) -> bool:
	if not condition:
		failures.append(label)
		return false
	return true
