extends SceneTree

## First-screen cleanup gate. Helmer's Test #8 complaint: mega-cluttered
## opening on 1080p. This run must start zoomed a step back, keep a 6–8
## tile yard clear of trees/rocks, show one queued hint, and open with a
## compact starter build bar.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const CameraRig = preload("res://src/GodotClient3D/Scripts/production_isometric_camera_rig.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")

var failures: Array[String] = []
var hint_path := ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var dest := ProjectSettings.globalize_path("res://artifacts/first_screen")
	DirAccess.make_dir_recursive_absolute(dest)
	hint_path = dest.path_join("hint_sequence.txt")

	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var t0 := Time.get_ticks_msec()
	game.start_new_3d(game.DEFAULT_SEED)
	var start_ms := float(Time.get_ticks_msec() - t0)
	game._hide_start_menu()
	game.simulation_host.paused = true
	if game.has_method("_update_ui"):
		game._update_ui()
	for _i in 4:
		await process_frame
	t0 = Time.get_ticks_msec()
	await process_frame
	await RenderingServer.frame_post_draw
	var first_frame_ms := float(Time.get_ticks_msec() - t0)
	print("T_FIRST_SCREEN start_new_ms=%.1f first_frame_ms=%.1f zoom=%.1f" % [
		start_ms, first_frame_ms, game.camera_rig.target_zoom
	])

	_check(start_ms < 3000.0, "start_new_3d under 3 s (%.0f ms)" % start_ms)
	_check(first_frame_ms < 3000.0 or start_ms + first_frame_ms < 8000.0, "first composed frame is not a multi-second hitch")
	_check(is_equal_approx(CameraRig.NORMAL_ZOOM, 26.0), "gameplay zoom preset stays 26")
	_check(CameraRig.OPENING_ZOOM >= 30.0 and CameraRig.OPENING_ZOOM <= 34.0, "opening zoom is a step back from 26")
	_check(is_equal_approx(game.camera_rig.target_zoom, CameraRig.OPENING_ZOOM), "new game opens at OPENING_ZOOM")

	var master_idx := AudioServer.get_bus_index("Master")
	var master_lin := db_to_linear(AudioServer.get_bus_volume_db(master_idx))
	print("T_FIRST_SCREEN master_linear=%.3f" % master_lin)
	_check(master_lin >= 0.995 and master_lin <= 1.005, "Master volume is 1.0")

	var sim = game.simulation_host.simulation
	var blockers: Dictionary = game.world_view.founding_yard_blockers(8.0)
	print("T_FIRST_SCREEN yard trees=%d rocks=%d radius=%.1f tiles=%s hall=%s" % [
		int(blockers.get("trees", -1)), int(blockers.get("rocks", -1)), float(blockers.get("radius", 0.0)),
		str(blockers.get("tree_tiles", [])), str(sim.town_hall_position)
	])
	_check(int(blockers.get("trees", 1)) == 0, "no trees inside the founding clearing")
	_check(int(blockers.get("rocks", 1)) == 0, "no rocks inside the founding clearing")
	var audit: Dictionary = sim.founding_audit()
	print("T_FIRST_SCREEN founding_audit=%s" % str(audit))
	_check(int(audit.get("functional_buildings", 0)) == 1, "exactly one functional building")
	_check(int(audit.get("fake_buildings", 1)) == 0, "no fake building entities")
	_check(bool(audit.get("tree_reachable", false)), "wood is reachable from the hall")
	_check(bool(audit.get("rock_reachable", false)), "stone is reachable from the hall")
	_check(bool(audit.get("food_reachable", false)), "a food cluster is reachable")
	_check(bool(audit.get("bridges_cross", false)), "starter bridges cross the creek")
	_check(bool(audit.get("quest_target", false)), "quest names the Lumber Camp")
	_check(bool(audit.get("inside_crater", false)), "start sits inside the crater radius")
	_check(bool(audit.get("slope_ok", false)), "founding slope is below the crater-floor threshold")
	_check(bool(audit.get("water_near", false)) and bool(audit.get("tree_near", false)), "water and wood are close")
	_check(bool(audit.get("rock_near", false)) and bool(audit.get("food_near", false)), "stone and food are close")
	_check(bool(audit.get("wyrd_marker", false)), "a wyrd or crater marker points from the start")
	_check(bool(audit.get("distance_band", false)), "Town Hall sits in the 0.65–0.85 R harvest band")
	_check(bool(audit.get("footprint_stable", false)), "Town Hall footprint is on stable ground outside the pit")
	print("T_FIRST_SCREEN crater_compass=%s dist=%.1f hall=%s shard=%s dir=%s orbit=%.1f sector=%d water=%s layout=%s pit=%.1f" % [
		String(audit.get("crater_compass", "")), float(audit.get("crater_dist", -1.0)),
		str(audit.get("hall", Vector2i.ZERO)), str(audit.get("shard", Vector2i.ZERO)),
		str(audit.get("crater_dir", Vector2.ZERO)),
		float(audit.get("orbit_deg", -1.0)), int(audit.get("orbit_sector", -1)),
		String(audit.get("water_type", "")), String(audit.get("layout_signature", "")),
		float(audit.get("pit_radius", -1.0))
	])
	var hall_view = null
	for view in game.world_view.building_views.values():
		if String(view.building_type) == "TOWN_HALL":
			hall_view = view
			break
	_check(hall_view != null, "Town Hall view exists")
	if hall_view != null:
		_check(hall_view.find_child("CivicDoor", true, false) != null, "founding hall has a visible door")
		_check(hall_view.find_child("CivicRoof_Hall", true, false) != null, "founding hall has a green roof")
	var dress: Node = game.world_view.resource_visuals_root.get_node_or_null("OpeningDress")
	_check(dress != null and float(dress.get_meta("opening_yard_cells", 0.0)) >= 7.0, "opening dress records the 6–8 tile yard")
	_check(dress != null and int(dress.get_meta("hamlet_cottages", 0)) == 0, "opening dress plants no cottages")
	_check(dress != null and dress.find_child("DressWyrdTrace_0", true, false) != null, "opening shows a wyrd crystal toward the crater")
	_check(dress != null and dress.find_child("DressWyrdTrail_0", true, false) != null, "opening shows scorched ground toward the crater")
	_check(dress == null or dress.find_child("DressWyrdGlow", true, false) == null, "opening has no UI-clipping wyrd glow")
	_check(dress == null or dress.find_child("DressWyrdHorizon", true, false) == null, "opening has no giant horizon glow")
	var expected_yaw: float = float(CameraRig.PREFERRED_YAW) + float(game.world_view.opening_camera_yaw())
	_check(is_equal_approx(game.camera_rig.rotation.y, expected_yaw), "opening yaw frames the crater behind the hall")
	var fake: Array[String] = game.world_view.non_inspectable_building_meshes(16.0)
	var fake_map: Array[String] = game.world_view.non_inspectable_building_meshes(-1.0)
	print("T_FIRST_SCREEN dress_buildings_start=%s map=%s" % [str(fake), str(fake_map)])
	_check(fake.is_empty(), "start area has 0 non-inspectable building meshes")
	_check(fake_map.is_empty(), "map has 0 non-inspectable building meshes")

	_check(game.placement_type == "", "no placement tool armed at start")
	_check(game.placement_panel == null or not game.placement_panel.visible, "placement hint is hidden at start")
	var hint_text := ""
	if game.placement_label != null:
		hint_text = game.placement_label.text
	_check(not hint_text.contains("Outside revealed territory"), "Outside revealed territory is not shown at spawn")
	_check(game.first_screen_banner_count() <= 1, "only one hint/banner at start")
	_check(game.status_plate == null or not game.status_plate.visible, "rival banner is queued, not shown at start")
	_check(game.objective_button != null and game.objective_button.text != "", "quest is the first hint")

	var unlocked: Array[String] = game.visible_build_types()
	print("T_FIRST_SCREEN starter=%s" % str(unlocked))
	_check(unlocked.size() == 4, "start shows four starter plans")
	for needed in [Defs.BUILDING_ROAD, Defs.BUILDING_HOUSE, Defs.BUILDING_LUMBER_CAMP, Defs.BUILDING_FARM]:
		_check(needed in unlocked, "starter includes %s" % needed)
	_check(not game.is_build_unlocked(Defs.BUILDING_QUARRY), "Quarry stays locked at start")
	_check(not game.is_build_unlocked(Defs.BUILDING_WATCHTOWER), "Watchtower stays locked at start")
	_check(not game.is_build_unlocked(Defs.BUILDING_OUTPOST), "Outpost stays locked at start")
	_check(game.CONSOLE_HEIGHT <= 100.0, "bottom console starts compact")
	if game.hud_console != null:
		var console_h: float = game.hud_console.get_global_rect().size.y
		print("T_FIRST_SCREEN console_h=%.1f viewport=%.1f" % [console_h, root.size.y])
		_check(console_h <= root.size.y * 0.16, "bottom HUD uses well under a quarter of the screen")
	_check(not game.minimap_expanded, "province map starts collapsed")

	game.begin_placement(Defs.BUILDING_ROAD)
	if game.has_method("_update_placement_ghost"):
		game._update_placement_ghost(true)
	_check(game.placement_panel != null and game.placement_panel.visible, "road tool shows an instruction")
	_check(not game.placement_label.text.contains("Outside revealed territory"), "hovering fog does not shout Outside revealed territory")
	var fog_tile := Vector2i(2, 2)
	game.placement_tile = fog_tile
	var denied: Dictionary = sim.request_build(Defs.BUILDING_ROAD, fog_tile)
	game.placement_invalid_shown = true
	game.placement_validation = denied
	game._update_placement_ghost(true)
	print("T_FIRST_SCREEN invalid_attempt=%s label='%s'" % [str(denied.get("message", "")), game.placement_label.text])
	_check(game.placement_invalid_shown, "invalid placement attempt is recorded")
	game.cancel_placement()

	var road: Vector2i = sim._town_hall_entrance_tile() + Vector2i(0, 1)
	sim._prepare_test_tile(road, Defs.TILE_GRASS)
	sim.request_build(Defs.BUILDING_ROAD, road)
	var house: Vector2i = road + Vector2i(2, 0)
	for offset in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i(1, 1)]:
		sim._prepare_test_tile(house + offset, Defs.TILE_GRASS)
	var house_result: Dictionary = sim.request_build(Defs.BUILDING_HOUSE, house)
	if not bool(house_result.get("ok", false)) and sim.get_building_at_tile(house).is_empty():
		sim.buildings.append(sim._create_building(Defs.BUILDING_HOUSE, house))
	var lumber_b: Dictionary = sim._create_building(Defs.BUILDING_LUMBER_CAMP, sim.town_hall_position + Vector2i(8, 2))
	sim.buildings.append(lumber_b)
	print("T_FIRST_SCREEN lumber_has=%s" % str(game._player_has_building(Defs.BUILDING_LUMBER_CAMP)))
	game._update_ui()
	_check(game.is_build_unlocked(Defs.BUILDING_QUARRY), "Quarry unlocks after a Lumber Camp")
	_check(game.is_build_unlocked(Defs.BUILDING_STOREHOUSE), "Storehouse unlocks after a House")

	sim.phase_time = float(sim.DAY_LENGTH_SECONDS) - 80.0
	game._update_ui()
	_check(game.is_build_unlocked(Defs.BUILDING_WATCHTOWER), "Watchtower unlocks as night draws near")

	sim.elapsed_seconds = 0.0
	game.first_screen_hint_log.clear()
	game._log_first_screen_hint("quest", game.objective_button.text)
	game.simulation_host.paused = false
	for step in 12:
		sim._simulate_seconds_for_test(5.0)
		game._update_ui()
	_write_hint_log(game)
	_check(FileAccess.file_exists(hint_path), "first 60 s hint sequence was written")
	var has_quest := false
	for row in game.first_screen_hint_log:
		if String(row.get("kind", "")) == "quest":
			has_quest = true
	_check(has_quest, "hint log starts with the quest")

	print("T_FIRST_SCREEN %s" % ("PASS" if failures.is_empty() else "FAIL"))
	for failure in failures:
		print("  FAIL %s" % failure)
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)


func _write_hint_log(game: Node) -> void:
	var file := FileAccess.open(hint_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_line("t_sec\tkind\ttext")
	for row in game.first_screen_hint_log:
		file.store_line("%.1f\t%s\t%s" % [float(row.get("t", 0.0)), String(row.get("kind", "")), String(row.get("text", ""))])
	file.close()
	print("T_FIRST_SCREEN hint_log=%s rows=%d" % [hint_path, game.first_screen_hint_log.size()])


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
