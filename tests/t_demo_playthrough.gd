extends SceneTree

## 60-minute 3D demo playthrough on the 320 province (test #13 / PR #80).
## A scripted settler AI issues public request_* commands; the clock is
## advanced at a logged game-time rate. Shots every 5 minutes plus key events.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const CameraRig = preload("res://src/GodotClient3D/Scripts/production_isometric_camera_rig.gd")
const Player = preload("res://src/GodotClient3D/Scripts/production_demo_player.gd")
const Intentions = preload("res://src/GodotClient/Scripts/one_shard_intentions.gd")

const SEED_DEFAULT := 260821
const STEP_SECONDS := 8.0
const MAX_SECONDS_DEFAULT := 3600.0
const DEST_DEFAULT := "res://artifacts/demo_playthrough_v3"

var failures: Array[String] = []
var script_errors := 0
var dest := ""
var shot_dest := ""
var csv_path := ""
var notes: Dictionary = {
	"events": [],
	"blockers": [],
	"dull": [],
	"unclear": [],
	"bugs": [],
	"balance": [],
	"timeline": []
}
var captured: Dictionary = {}
var last_command_at := 0.0
var last_night := false
var journal_cursor := 0
var first_quest_done := false
var saw_rival := false
var saw_shard := false
var saw_storehouse := false
var saw_capture := false
var saw_ritual := false
var first_12_at := -1.0
var last_meaningful_at := 0.0
var longest_idle := 0.0
var idle_gaps: Array = []
var last_raid_active := false
var step_index := 0
var headless := false
var accept := false
var seed_value := SEED_DEFAULT


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var max_seconds := MAX_SECONDS_DEFAULT
	var dest_res := DEST_DEFAULT
	seed_value = SEED_DEFAULT
	headless = false
	accept = false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--max-seconds="):
			max_seconds = float(arg.trim_prefix("--max-seconds="))
		elif arg.begins_with("--seed="):
			seed_value = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--dest="):
			dest_res = arg.trim_prefix("--dest=")
		elif arg == "--headless" or arg == "--headless=1":
			headless = true
		elif arg == "--accept" or arg == "--accept=1":
			accept = true
	dest = ProjectSettings.globalize_path(dest_res)
	shot_dest = dest.path_join("shots")
	DirAccess.make_dir_recursive_absolute(shot_dest)
	csv_path = dest.path_join("playthrough_%d.csv" % seed_value)
	if seed_value == SEED_DEFAULT:
		csv_path = dest.path_join("playthrough.csv")
	_write_csv_header()

	var game = null
	var sim = null
	if headless:
		sim = _make_sim(seed_value)
	if not headless:
		game = Scene.instantiate()
		root.add_child(game)
		await process_frame
		await process_frame
		OS.set_environment("SNS_PLAYTEST_LOG", "1")
		game.start_new_3d(seed_value)
		game._hide_start_menu()
		game.simulation_host.paused = true
		if game.world_view != null:
			game.world_view.set_presentation_paused(true)
		sim = game.simulation_host.simulation
	if sim.playtest_log != null:
		sim.playtest_log.configure(true, dest.path_join("dpm_%d.csv" % seed_value))
	_check(sim.map_size.x == 320, "playthrough is on the 320 province")
	_check(int(sim.rng_seed) == seed_value, "seed is %d" % seed_value)

	var player = Player.new()
	await _capture(game, sim, "t00_start", "Opening yard after founding.")
	_log_row(sim, "start")
	_note_event(sim, "start", "Founded seed %d at hall %s, shard %s, rivals %d." % [
		seed_value, str(sim.town_hall_position), str(sim.shard_position), sim.rival_seats.size()
	])

	while float(sim.elapsed_seconds) < max_seconds and not bool(sim.game_finished):
		var before := float(sim.elapsed_seconds)
		var thought: Dictionary = player.think(sim)
		_watch_commands(sim, thought)
		_watch_journal(sim)
		_watch_crater_state(sim)
		await _watch_phase(game, sim)
		var actions: Array = thought.get("actions", [])
		if not actions.is_empty():
			last_command_at = float(sim.elapsed_seconds)
		_watch_meaningful(sim, thought)
		_maybe_idle(sim)
		sim._simulate_seconds_for_test(STEP_SECONDS)
		step_index += 1
		_watch_journal(sim)
		_watch_crater_state(sim)
		await _watch_phase(game, sim)
		_log_row(sim, _event_tag(sim, thought))
		if _should_snapshot_minute(before, float(sim.elapsed_seconds)):
			var minute := int(floor(float(sim.elapsed_seconds) / 300.0)) * 5
			await _capture(game, sim, "t%02d_play" % minute, "Minute %d yard." % minute)
		if step_index % 8 == 0:
			print("DEMO_PLAYTHROUGH t=%.0f pop=%d bld=%d wood=%d stone=%d quest=%s idle=%s" % [
				float(sim.elapsed_seconds), int(sim.population_current),
				_building_count(sim), _stock(sim, Defs.RESOURCE_WOOD),
				_stock(sim, Defs.RESOURCE_STONE), _quest_label(sim),
				String(thought.get("idle", ""))
			])

	if bool(sim.victory):
		await _capture(game, sim, "t%02d_victory" % _mm(sim), "Victory.")
		_note_event(sim, "victory", String(sim.last_message))
	elif bool(sim.game_finished):
		await _capture(game, sim, "t%02d_defeat" % _mm(sim), "Defeat: %s" % String(sim.defeat_reason))
		_note_event(sim, "defeat", String(sim.defeat_reason))
	else:
		await _capture(game, sim, "t60_end", "State at 60 minutes; no ending.")
		_note_event(sim, "end", "Reached the 60-minute cap without a victory.")

	if sim.is_revealed(sim.shard_position):
		saw_shard = true
	_write_notes(sim, player)
	_check(script_errors == 0, "no script errors during the playthrough")
	if not headless:
		_check(DirAccess.open(shot_dest) != null, "shots directory exists")
	if accept:
		_check(float(sim.elapsed_seconds) >= 1500.0 or bool(sim.victory), "survived to minute 25 or later")
		_check(saw_shard or sim.is_revealed(sim.shard_position), "found the Shard")
		_check(saw_rival, "saw a rival")
		_check(saw_storehouse or (sim.crater_war != null and sim.crater_war.storehouse_completed_at >= 0.0), "finished the Storehouse")
		_check(saw_capture or (sim.crater_war != null and sim.crater_war.rival_resolution != ""), "interacted with the rival / captured the Outpost")
		_check(saw_ritual or (sim.crater_war != null and sim.crater_war.ritual_started_at >= 0.0), "defended the Binding ritual")
		_check(bool(sim.victory), "reached a Binding victory")
		_check(String(sim.defeat_reason).contains("BOUND"), "victory is Binding, not THE REALM HOLDS")
		_check(float(sim.elapsed_seconds) <= 3600.0, "Binding landed inside the 60-minute hour (t=%.1f)" % float(sim.elapsed_seconds))
		if first_12_at >= 0.0:
			_check(first_12_at + 0.05 >= 40.0 * 60.0 - STEP_SECONDS, "12 Stabilized is not earlier than ~40:00 (t=%.1f)" % first_12_at)
			_check(first_12_at <= 52.0 * 60.0 + STEP_SECONDS, "12 Stabilized is not later than ~52:00 (t=%.1f)" % first_12_at)
		else:
			_check(false, "store reached 12 Stabilized")
		if sim.crater_war != null and sim.crater_war.ritual_started_at >= 0.0:
			_check(sim.crater_war.ritual_started_at + 0.05 >= 40.0 * 60.0 - STEP_SECONDS, "ritual starts with the store, not on a clock (t=%.1f)" % sim.crater_war.ritual_started_at)
		_check(float(sim.elapsed_seconds) + 0.05 >= 42.0 * 60.0 - STEP_SECONDS, "Binding is not earlier than ~42:00 (t=%.1f)" % float(sim.elapsed_seconds))
		_check(float(sim.elapsed_seconds) <= 55.0 * 60.0 + STEP_SECONDS, "Binding is not later than ~55:00 (t=%.1f)" % float(sim.elapsed_seconds))
		_check(longest_idle <= 180.0 + STEP_SECONDS, "no idle stretch longer than 3 minutes (longest=%.1fs)" % longest_idle)
		if sim.crater_war != null and sim.crater_war.storehouse_completed_at >= 0.0:
			_check(sim.crater_war.storehouse_completed_at <= 18.0 * 60.0 + 1.0, "Storehouse completed by minute 18 (t=%.1f)" % sim.crater_war.storehouse_completed_at)
		if sim.crater_war != null:
			_check(sim.crater_war.second_push_at >= 0.0 or sim.crater_war.contest_count > 0, "rival second-pushed the fissure")
			_check(sim.crater_war.harvester_raid_at >= 0.0, "rival raided the harvester")
	print("DEMO_PLAYTHROUGH seed=%d elapsed=%.1f finished=%s victory=%s shots=%d" % [
		seed_value, float(sim.elapsed_seconds), str(sim.game_finished), str(sim.victory), captured.size()
	])
	print("DEMO_PLAYTHROUGH %s" % ("PASS" if failures.is_empty() else "FAIL"))
	if game != null:
		game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)


func _make_sim(seed_for_run: int):
	var sim = Simulation.new()
	sim.start_new_run(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, seed_for_run, true)
	return sim


func _watch_commands(sim, thought: Dictionary) -> void:
	for action_value in thought.get("actions", []):
		notes["timeline"].append({"t": float(sim.elapsed_seconds), "action": String(action_value)})
	for fail_value in thought.get("failures", []):
		var fail := String(fail_value)
		if fail.contains("no site") or fail.contains("no valid"):
			_unique("bugs", "Placement failed: %s" % fail)


func _watch_journal(sim) -> void:
	while journal_cursor < sim.run_journal.size():
		var event: Dictionary = sim.run_journal[journal_cursor]
		journal_cursor += 1
		var kind := String(event.get("event", ""))
		var message := String(event.get("message", ""))
		if kind == "intention_complete" and not first_quest_done:
			first_quest_done = true
			_note_event(sim, "first_quest", message)
			captured["pending_first_quest"] = true
		if kind in ["raid_started", "raid_wave"] and not captured.has("did_first_raid"):
			captured["did_first_raid"] = true
			_note_event(sim, "first_raid", message)
			captured["pending_first_raid"] = true
		if kind == "discovery" and message.to_lower().contains("rival") and not saw_rival:
			saw_rival = true
			_note_event(sim, "rival", message)
			captured["pending_rival"] = true
		if kind == "frontier_revealed" and not captured.has("did_frontier"):
			captured["did_frontier"] = true
			saw_shard = true
			_note_event(sim, "frontier", message)
			captured["pending_frontier"] = true
		if kind == "rival_encounter" and not saw_rival:
			saw_rival = true
			_note_event(sim, "rival", message)
			captured["pending_rival"] = true
		if kind == "storehouse_complete" and not saw_storehouse:
			saw_storehouse = true
			_note_event(sim, "storehouse", message)
			captured["pending_storehouse"] = true
		if kind == "outpost_captured" and not saw_capture:
			saw_capture = true
			_note_event(sim, "capture", message)
			captured["pending_capture"] = true
		if kind == "passage_deal" or kind == "rival_relocated":
			saw_rival = true
			_note_event(sim, kind, message)
		if kind == "binding_started" and not saw_ritual:
			saw_ritual = true
			_note_event(sim, "ritual", message)
			captured["pending_ritual"] = true
		if kind in ["rival_second_push", "rival_contest", "harvester_raid", "harvester_raid_spawn", "exposure_choice", "exposure_burn"]:
			_note_event(sim, kind, message)
			_touch_play(float(event.get("elapsed_seconds", sim.elapsed_seconds)))
			if kind in ["rival_second_push", "harvester_raid", "harvester_raid_spawn"] and not captured.has("pending_%s" % kind):
				captured["pending_%s" % kind] = true


func _watch_phase(game, sim) -> void:
	var night_now := bool(sim.is_night)
	if night_now and not last_night and not captured.has("did_first_night"):
		captured["did_first_night"] = true
		_note_event(sim, "first_night", "First night began on day %d." % int(sim.day_count))
		captured["pending_first_night"] = true
	if bool(sim.raid_active) and not captured.has("did_first_raid"):
		captured["did_first_raid"] = true
		_note_event(sim, "first_raid", "Raid active with %d enemies." % int(sim.enemies.size()))
		captured["pending_first_raid"] = true
	last_night = night_now
	if not saw_rival:
		_maybe_rival(sim)
	if not saw_shard and sim.is_revealed(sim.shard_position):
		saw_shard = true
	if captured.get("pending_first_quest", false):
		captured["pending_first_quest"] = false
		await _capture(game, sim, "t%02d_first_quest" % _mm(sim), "First intention complete.")
	if captured.get("pending_first_night", false):
		captured["pending_first_night"] = false
		await _capture(game, sim, "t%02d_first_night" % _mm(sim), "First night.")
	if captured.get("pending_first_raid", false):
		captured["pending_first_raid"] = false
		await _capture(game, sim, "t%02d_first_raid" % _mm(sim), "First raid or battle.")
	if captured.get("pending_frontier", false):
		captured["pending_frontier"] = false
		await _capture(game, sim, "t%02d_frontier" % _mm(sim), "Frontier marker and Shard direction.")
	if captured.get("pending_rival", false):
		captured["pending_rival"] = false
		await _capture(game, sim, "t%02d_rival" % _mm(sim), "Rival encounter.")
	if captured.get("pending_storehouse", false):
		captured["pending_storehouse"] = false
		await _capture(game, sim, "t%02d_storehouse" % _mm(sim), "Storehouse completed.")
	if captured.get("pending_capture", false):
		captured["pending_capture"] = false
		await _capture(game, sim, "t%02d_capture" % _mm(sim), "Claimant Outpost captured.")
	if captured.get("pending_ritual", false):
		captured["pending_ritual"] = false
		await _capture(game, sim, "t%02d_ritual" % _mm(sim), "Binding ritual begun.")
	if captured.get("pending_rival_second_push", false):
		captured["pending_rival_second_push"] = false
		await _capture(game, sim, "t%02d_second_push" % _mm(sim), "Rival second push on the fissure.")
	if captured.get("pending_harvester_raid", false) or captured.get("pending_harvester_raid_spawn", false):
		captured["pending_harvester_raid"] = false
		captured["pending_harvester_raid_spawn"] = false
		await _capture(game, sim, "t%02d_harvester_raid" % _mm(sim), "Raid on the Wyrd Harvester.")


func _watch_crater_state(sim) -> void:
	if sim.crater_war == null:
		return
	if not saw_storehouse and sim.crater_war.storehouse_completed_at >= 0.0:
		saw_storehouse = true
		_note_event(sim, "storehouse", "Storehouse completed.")
		captured["pending_storehouse"] = true
	if not saw_capture and sim.crater_war.capture_at >= 0.0:
		saw_capture = true
		_note_event(sim, "capture", String(sim.last_message) if String(sim.last_message).contains("CAPTURED") else "CLAIMANT OUTPOST CAPTURED — the fissure is yours.")
		captured["pending_capture"] = true
	elif not saw_capture and sim.crater_war.rival_resolution != "":
		saw_capture = true
		_note_event(sim, sim.crater_war.rival_resolution, "Rival resolved: %s." % sim.crater_war.rival_resolution)
	if first_12_at < 0.0 and sim.crater_war.stabilized_stock() >= 12:
		first_12_at = float(sim.elapsed_seconds)
		_note_event(sim, "stabilized_12", "Store reached 12 Stabilized Wyrd.")
	if not saw_ritual and sim.crater_war.ritual_started_at >= 0.0:
		saw_ritual = true
		_note_event(sim, "ritual", "BINDING BEGUN — defend the fissure ritual for 120 seconds.")
		captured["pending_ritual"] = true


func _maybe_rival(sim) -> void:
	if sim.rivalry == null:
		return
	var line := String(sim.rivalry.get_rival_status_line())
	if float(sim.elapsed_seconds) >= 600.0 and (line.contains("Outpost") or line.contains("Binding")):
		saw_rival = true
		_note_event(sim, "rival", line)
		captured["pending_rival"] = true
		return
	for structure in sim.rivalry.get_structures("rival"):
		var pos := Vector2i(structure.get("position", Vector2i.ZERO))
		if sim.is_revealed(pos):
			saw_rival = true
			_note_event(sim, "rival", "Revealed rival %s at %s." % [String(structure.get("type", "")), str(pos)])
			captured["pending_rival"] = true
			return


func _watch_meaningful(sim, thought: Dictionary) -> void:
	var now := float(sim.elapsed_seconds)
	var meaningful := false
	for action_value in thought.get("actions", []):
		var kind := String(action_value).get_slice(" ", 0)
		if kind != "" and kind != Defs.BUILDING_ROAD and kind != "ROAD":
			meaningful = true
			break
	if bool(sim.raid_active) or bool(sim.is_night):
		meaningful = true
	if sim.crater_war != null and bool(sim.crater_war.ritual_active):
		meaningful = true
	if sim.crater_war != null and sim.crater_war._rival_outpost_alive():
		meaningful = true
	for worker in sim.workers:
		if int(worker.get("assault_target_id", 0)) > 0:
			meaningful = true
			break
	for building in sim.get_buildings():
		if not bool(building.get("construction", false)):
			continue
		if String(building.get("planned_type", building.get("type", ""))) == Defs.BUILDING_ROAD:
			continue
		meaningful = true
		break
	last_raid_active = bool(sim.raid_active)
	if meaningful:
		_touch_play(now)


func _touch_play(at_seconds: float) -> void:
	if last_meaningful_at > 0.0:
		var gap := at_seconds - last_meaningful_at
		if gap > longest_idle:
			longest_idle = gap
		if gap >= 90.0:
			idle_gaps.append({"from": last_meaningful_at, "to": at_seconds, "seconds": gap})
	elif last_meaningful_at == 0.0:
		last_meaningful_at = at_seconds
		return
	last_meaningful_at = at_seconds


func _maybe_idle(sim) -> void:
	var now := float(sim.elapsed_seconds)
	if last_meaningful_at > 0.0:
		longest_idle = maxf(longest_idle, now - last_meaningful_at)
	var gap := now - last_command_at
	if gap >= 90.0 and last_command_at > 0.0:
		var label := "Dull stretch near t=%.0fs (%.0fs without a new order)." % [now, gap]
		_unique("dull", label)
		last_command_at = now


func _should_snapshot_minute(before: float, after: float) -> bool:
	var prev := int(floor(before / 300.0))
	var now := int(floor(after / 300.0))
	return now > prev and now <= 12


func _capture(game, sim, name_value: String, caption: String) -> void:
	if captured.has(name_value):
		return
	if headless or game == null:
		captured[name_value] = "headless"
		notes["timeline"].append({"t": float(sim.elapsed_seconds), "shot": name_value, "caption": caption})
		return
	_frame_camera(game, sim, name_value)
	game._sync_presentation()
	if game.has_method("_update_ui"):
		game._update_ui()
	for _i in 8:
		await process_frame
		if game.world_view != null:
			game.world_view.stream_chunks(12000)
	await RenderingServer.frame_post_draw
	var image: Image = root.get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		failures.append("empty shot %s" % name_value)
		return
	var path := shot_dest.path_join("%s.png" % name_value)
	image.save_png(path)
	captured[name_value] = path
	print("DEMO_PLAYTHROUGH shot %s %dx%d t=%.1f %s" % [
		name_value, image.get_width(), image.get_height(), float(sim.elapsed_seconds), caption
	])
	notes["timeline"].append({"t": float(sim.elapsed_seconds), "shot": name_value, "caption": caption})


func _frame_camera(game, sim, name_value: String) -> void:
	var zoom := CameraRig.OPENING_ZOOM
	var focus: Vector3 = game.world_view.opening_camera_focus()
	if name_value.contains("night") or name_value.contains("raid"):
		zoom = 40.0
	elif name_value.contains("frontier"):
		var marker: Variant = sim.founding_site.get("frontier_marker", sim.shard_position)
		focus = game.world_view.tile_to_world(Vector2(marker))
		zoom = 48.0
	elif name_value.contains("rival"):
		focus = _rival_focus(game, sim)
		zoom = 48.0
	elif name_value.contains("victory") or name_value.contains("end"):
		focus = game.world_view.tile_to_world(Vector2(sim.shard_position))
		zoom = 56.0
	game.camera_rig.configure_for_map(sim.map_size)
	game.camera_rig.compose_view(focus, zoom)
	game.world_view.note_camera(game.camera_rig.target_position, zoom)


func _rival_focus(game, sim) -> Vector3:
	if sim.rivalry != null:
		for structure in sim.rivalry.get_structures("rival"):
			var pos := Vector2i(structure.get("position", Vector2i.ZERO))
			if sim.is_revealed(pos):
				return game.world_view.tile_to_world(Vector2(pos))
	if not sim.rival_seats.is_empty():
		return game.world_view.tile_to_world(Vector2(Vector2i(sim.rival_seats[0])))
	return game.world_view.opening_camera_focus()


func _write_csv_header() -> void:
	var file := FileAccess.open(csv_path, FileAccess.WRITE)
	file.store_string("game_seconds,game_minutes,day,night,population,housing,soldiers,buildings,roads,wood,planks,stone,wheat,bread,wyrd,stabilized,exposure,quest,events,victory,finished\n")
	file.close()


func _log_row(sim, events: String) -> void:
	var file := FileAccess.open(csv_path, FileAccess.READ_WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_string("%0.1f,%0.2f,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%0.2f,%s,%s,%d,%d\n" % [
		float(sim.elapsed_seconds),
		float(sim.elapsed_seconds) / 60.0,
		int(sim.day_count),
		1 if bool(sim.is_night) else 0,
		int(sim.population_current),
		int(sim.housing_capacity),
		int(sim.soldiers_total),
		_building_count(sim),
		_road_count(sim),
		_stock(sim, Defs.RESOURCE_WOOD),
		_stock(sim, Defs.RESOURCE_PLANKS),
		_stock(sim, Defs.RESOURCE_STONE),
		_stock(sim, Defs.RESOURCE_WHEAT),
		_stock(sim, Defs.RESOURCE_BREAD),
		_stock(sim, Defs.RESOURCE_WYRD),
		_stock(sim, Defs.RESOURCE_STABILIZED_WYRD),
		float(sim.crater_war.exposure) if sim.crater_war != null else 0.0,
		_csv(_quest_label(sim)),
		_csv(events),
		1 if bool(sim.victory) else 0,
		1 if bool(sim.game_finished) else 0
	])
	file.close()


func _write_notes(sim, player) -> void:
	if float(sim.elapsed_seconds) >= 3300.0 and not bool(sim.victory):
		_unique("balance", "Binding was not reached in 60 minutes on the 320 map (hall %s, shard %s, crater R=110)." % [str(sim.town_hall_position), str(sim.shard_position)])
	if not first_quest_done:
		_unique("blockers", "First intention (Lumber Camp + Quarry) never completed.")
	if not captured.has("t00_start") and not captured.has("pending_first_night"):
		pass
	if int(sim.soldiers_total) == 0 and float(sim.elapsed_seconds) > 900.0:
		_unique("balance", "No soldiers after 15 minutes — barracks / food / unlock pacing is tight.")
	if not saw_rival:
		_unique("unclear", "No rival encounter in 60 minutes. Scout depth is 14 tiles; rival seats sit across a 320 map.")
	notes["seed"] = seed_value
	notes["elapsed"] = float(sim.elapsed_seconds)
	notes["victory"] = bool(sim.victory)
	notes["finished"] = bool(sim.game_finished)
	notes["defeat_reason"] = String(sim.defeat_reason)
	notes["hall"] = str(sim.town_hall_position)
	notes["shard"] = str(sim.shard_position)
	notes["orders"] = player.orders
	notes["shots"] = captured.keys()
	if sim.rivalry != null:
		notes["claim"] = sim.rivalry.claim_requirements("player")
		notes["rival_line"] = String(sim.rivalry.get_rival_status_line())
	if sim.crater_war != null:
		notes["crater_war"] = {
			"storehouse_at": sim.crater_war.storehouse_completed_at,
			"capture_at": sim.crater_war.capture_at,
			"resolution": sim.crater_war.rival_resolution,
			"ritual_at": sim.crater_war.ritual_started_at,
			"surveyed": sim.crater_war.geologist_surveyed,
			"fissure": str(sim.crater_war.primary_fissure),
			"secondary": str(sim.crater_war.secondary_fissure),
			"exposure": sim.crater_war.exposure,
			"stabilized": sim.crater_war.stabilized_stock(),
			"interacted": sim.crater_war.rival_interacted,
			"first_12_at": first_12_at,
			"second_push_at": sim.crater_war.second_push_at,
			"harvester_raid_at": sim.crater_war.harvester_raid_at,
			"contest_count": sim.crater_war.contest_count
		}
	notes["longest_idle"] = longest_idle
	notes["idle_gaps"] = idle_gaps
	print("DEMO_IDLE seed=%d longest=%.1fs gaps=%d first_12=%.1f ritual=%.1f bind=%.1f" % [
		seed_value, longest_idle, idle_gaps.size(), first_12_at,
		sim.crater_war.ritual_started_at if sim.crater_war != null else -1.0,
		float(sim.elapsed_seconds)
	])
	var notes_name := "notes.json" if seed_value == SEED_DEFAULT else "notes_%d.json" % seed_value
	var file := FileAccess.open(dest.path_join(notes_name), FileAccess.WRITE)
	file.store_string(JSON.stringify(notes, "\t"))
	file.close()


func _quest_label(sim) -> String:
	var intention: Dictionary = Intentions.current(sim)
	if intention.is_empty():
		for objective in sim.get_objectives():
			if not bool(objective.get("complete", false)):
				return String(objective.get("text", ""))
		return "none"
	return String(intention.get("title", ""))


func _event_tag(sim, thought: Dictionary) -> String:
	var bits: Array[String] = []
	if bool(sim.is_night):
		bits.append("night")
	if bool(sim.raid_active):
		bits.append("raid")
	for action_value in thought.get("actions", []):
		bits.append(String(action_value).get_slice(" ", 0))
	if bits.is_empty():
		bits.append(String(thought.get("idle", "idle")))
	return " ".join(bits)


func _building_count(sim) -> int:
	var total := 0
	for building in sim.get_buildings():
		var kind := String(building.get("type", ""))
		if kind == Defs.BUILDING_ROAD or String(building.get("planned_type", "")) == Defs.BUILDING_ROAD:
			continue
		if kind == Defs.BUILDING_CONSTRUCTION_SITE:
			continue
		total += 1
	return total


func _road_count(sim) -> int:
	var total := 0
	for building in sim.get_buildings():
		if String(building.get("type", "")) == Defs.BUILDING_ROAD and not bool(building.get("construction", false)):
			total += 1
	return total


func _stock(sim, resource_type: String) -> int:
	return int(sim.central_inventory.get(resource_type, 0))


func _mm(sim) -> int:
	return clampi(int(floor(float(sim.elapsed_seconds) / 60.0)), 0, 60)


func _note_event(sim, kind: String, detail: String) -> void:
	notes["events"].append({"t": float(sim.elapsed_seconds), "kind": kind, "detail": detail})
	print("DEMO_EVENT t=%.1f %s %s" % [float(sim.elapsed_seconds), kind, detail])


func _unique(bucket: String, text: String) -> void:
	var rows: Array = notes[bucket]
	if text in rows:
		return
	rows.append(text)


func _csv(text: String) -> String:
	return "\"%s\"" % text.replace("\"", "'")


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
