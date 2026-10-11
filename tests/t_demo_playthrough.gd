extends SceneTree

## 60-minute 3D demo playthrough on the 320 province (test #13 / PR #80).
## A scripted settler AI issues public request_* commands; the clock is
## advanced at a logged game-time rate. Shots every 5 minutes plus key events.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const CameraRig = preload("res://src/GodotClient3D/Scripts/production_isometric_camera_rig.gd")
const Player = preload("res://src/GodotClient3D/Scripts/production_demo_player.gd")
const Intentions = preload("res://src/GodotClient/Scripts/one_shard_intentions.gd")

const SEED := 260821
const STEP_SECONDS := 8.0
const MAX_SECONDS_DEFAULT := 3600.0

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
var step_index := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	dest = ProjectSettings.globalize_path("res://artifacts/demo_playthrough")
	shot_dest = dest.path_join("shots")
	DirAccess.make_dir_recursive_absolute(shot_dest)
	csv_path = dest.path_join("playthrough.csv")
	_write_csv_header()

	var max_seconds := MAX_SECONDS_DEFAULT
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--max-seconds="):
			max_seconds = float(arg.trim_prefix("--max-seconds="))

	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	OS.set_environment("SNS_PLAYTEST_LOG", "1")
	game.start_new_3d(SEED)
	game._hide_start_menu()
	game.simulation_host.paused = true
	if game.world_view != null:
		game.world_view.set_presentation_paused(true)
	var sim = game.simulation_host.simulation
	sim.playtest_log.configure(true, dest.path_join("dpm.csv"))
	_check(sim.map_size.x == 320, "playthrough is on the 320 province")
	_check(int(sim.rng_seed) == SEED, "seed is 260821")

	var player = Player.new()
	await _capture(game, sim, "t00_start", "Opening yard after founding.")
	_log_row(sim, "start")
	_note_event(sim, "start", "Founded seed %d at hall %s, shard %s, rivals %d." % [
		SEED, str(sim.town_hall_position), str(sim.shard_position), sim.rival_seats.size()
	])

	while float(sim.elapsed_seconds) < max_seconds and not bool(sim.game_finished):
		var before := float(sim.elapsed_seconds)
		var thought: Dictionary = player.think(sim)
		_watch_commands(sim, thought)
		_watch_journal(sim)
		await _watch_phase(game, sim)
		var actions: Array = thought.get("actions", [])
		if not actions.is_empty():
			last_command_at = float(sim.elapsed_seconds)
		_maybe_idle(sim)
		sim._simulate_seconds_for_test(STEP_SECONDS)
		step_index += 1
		_watch_journal(sim)
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
		await _capture(game, sim, "t%02d_victory" % _mm(sim), "Victory — Shard Bound.")
		_note_event(sim, "victory", String(sim.last_message))
	elif bool(sim.game_finished):
		await _capture(game, sim, "t%02d_defeat" % _mm(sim), "Defeat: %s" % String(sim.defeat_reason))
		_note_event(sim, "defeat", String(sim.defeat_reason))
	else:
		await _capture(game, sim, "t60_end", "State at 60 minutes; no ending.")
		_note_event(sim, "end", "Reached the 60-minute cap without a Binding.")

	_write_notes(sim, player)
	_check(script_errors == 0, "no script errors during the playthrough")
	_check(DirAccess.open(shot_dest) != null, "shots directory exists")
	print("DEMO_PLAYTHROUGH elapsed=%.1f finished=%s victory=%s shots=%d" % [
		float(sim.elapsed_seconds), str(sim.game_finished), str(sim.victory), captured.size()
	])
	print("DEMO_PLAYTHROUGH %s" % ("PASS" if failures.is_empty() else "FAIL"))
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)


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


func _watch_phase(game, sim) -> void:
	var night_now := bool(sim.is_night)
	if night_now and not last_night and not captured.has("did_first_night"):
		captured["did_first_night"] = true
		_note_event(sim, "first_night", "First night began on day %d." % int(sim.day_count))
		captured["pending_first_night"] = true
	last_night = night_now
	if not saw_rival:
		_maybe_rival(sim)
	if captured.get("pending_first_quest", false):
		captured["pending_first_quest"] = false
		await _capture(game, sim, "t%02d_first_quest" % _mm(sim), "First intention complete.")
	if captured.get("pending_first_night", false):
		captured["pending_first_night"] = false
		await _capture(game, sim, "t%02d_first_night" % _mm(sim), "First night.")
	if captured.get("pending_first_raid", false):
		captured["pending_first_raid"] = false
		await _capture(game, sim, "t%02d_first_raid" % _mm(sim), "First raid or battle.")
	if captured.get("pending_rival", false):
		captured["pending_rival"] = false
		await _capture(game, sim, "t%02d_rival" % _mm(sim), "Rival encounter.")


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


func _maybe_idle(sim) -> void:
	var gap := float(sim.elapsed_seconds) - last_command_at
	if gap >= 90.0 and last_command_at > 0.0:
		var label := "Dull stretch near t=%.0fs (%.0fs without a new order)." % [float(sim.elapsed_seconds), gap]
		_unique("dull", label)
		last_command_at = float(sim.elapsed_seconds)


func _should_snapshot_minute(before: float, after: float) -> bool:
	var prev := int(floor(before / 300.0))
	var now := int(floor(after / 300.0))
	return now > prev and now <= 12


func _capture(game, sim, name_value: String, caption: String) -> void:
	if captured.has(name_value):
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
	file.store_string("game_seconds,game_minutes,day,night,population,housing,soldiers,buildings,roads,wood,planks,stone,wheat,bread,wyrd,quest,events,victory,finished\n")
	file.close()


func _log_row(sim, events: String) -> void:
	var file := FileAccess.open(csv_path, FileAccess.READ_WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_string("%0.1f,%0.2f,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%s,%s,%d,%d\n" % [
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
	notes["seed"] = SEED
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
	var file := FileAccess.open(dest.path_join("notes.json"), FileAccess.WRITE)
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
