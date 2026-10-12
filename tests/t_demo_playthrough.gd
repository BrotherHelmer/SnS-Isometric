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
const DEST_DEFAULT := "res://artifacts/demo_playthrough_v10"

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
	if not headless and game != null:
		if game.has_method("_on_idle_workers_pressed"):
			game._on_idle_workers_pressed()
			await _capture(game, sim, "t00_idle_overview", "Crew overview from the idle status.")
			if game.idle_jump_button != null:
				game.idle_jump_button.emit_signal("pressed")
				await _capture(game, sim, "t00_idle_jump", "Idle shortcut jumps the camera.")
			if game.has_method("_show_idle_crew"):
				game._show_idle_crew(false)
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
		await _capture(game, sim, "t%02d_fissure_calm" % _mm(sim), "Stabilized fissure before the victory overlay.")
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
		_check(saw_ritual or (sim.crater_war != null and sim.crater_war.ritual_started_at >= 0.0), "defended the Seal ceremony")
		_check(bool(sim.victory), "reached a Seal victory")
		_check(String(sim.defeat_reason).contains("SEALED"), "victory is Seal the Fissure, not THE REALM HOLDS")
		_check(float(sim.elapsed_seconds) <= 3600.0, "Seal landed inside the 60-minute hour (t=%.1f)" % float(sim.elapsed_seconds))
		if first_12_at >= 0.0:
			_check(first_12_at + 0.05 >= 40.0 * 60.0 - STEP_SECONDS, "12 Stabilized is not earlier than ~40:00 (t=%.1f)" % first_12_at)
			_check(first_12_at <= 53.0 * 60.0 + STEP_SECONDS, "12 Stabilized is not later than ~53:00 (t=%.1f)" % first_12_at)
		else:
			_check(false, "store reached 12 Stabilized")
		if sim.crater_war != null and sim.crater_war.ritual_started_at >= 0.0:
			_check(sim.crater_war.ritual_started_at + 0.05 >= 40.0 * 60.0 - STEP_SECONDS, "Seal starts with the store, not on a clock (t=%.1f)" % sim.crater_war.ritual_started_at)
		_check(float(sim.elapsed_seconds) + 0.05 >= 42.0 * 60.0 - STEP_SECONDS, "Seal is not earlier than ~42:00 (t=%.1f)" % float(sim.elapsed_seconds))
		_check(float(sim.elapsed_seconds) <= 55.0 * 60.0 + STEP_SECONDS, "Seal is not later than ~55:00 (t=%.1f)" % float(sim.elapsed_seconds))
		_check(longest_idle <= 90.0 + STEP_SECONDS, "no idle stretch longer than 90 s (longest=%.1fs)" % longest_idle)
		if sim.crater_war != null and sim.crater_war.storehouse_completed_at >= 0.0:
			_check(sim.crater_war.storehouse_completed_at <= 18.0 * 60.0 + 1.0, "Storehouse completed by minute 18 (t=%.1f)" % sim.crater_war.storehouse_completed_at)
		if sim.crater_war != null:
			_check(sim.crater_war.wyrd_choice in ["refine", "secure"], "player chose a Wyrd pact at 6 Stabilized")
			_check(sim.crater_war.seal_choice in ["wall", "overcharge"], "player chose during the Seal defence")
			_check(sim.crater_war.midgame_choice in ["shelter", "fortify"], "player answered the 15–22 caravan")
			_check(sim.crater_war.channel_uses >= 1, "bot Channels Wyrd at least once per Seal")
			_check(sim.crater_war.midgame_offered_at + 0.05 >= 15.0 * 60.0 - STEP_SECONDS, "caravan is not before 15:00 (t=%.1f)" % sim.crater_war.midgame_offered_at)
			_check(sim.crater_war.midgame_offered_at <= 22.0 * 60.0 + STEP_SECONDS, "caravan is not after 22:00 (t=%.1f)" % sim.crater_war.midgame_offered_at)
			if sim.crater_war.second_push_at >= 0.0:
				_check(sim.crater_war.midgame_taken_at + 0.05 <= sim.crater_war.second_push_at + STEP_SECONDS, "caravan is answered before the first push")
			_check(sim.crater_war.second_push_at >= 0.0 or sim.crater_war.contest_count > 0, "rival pushed after the first harvest")
			_check(sim.crater_war.harvester_raid_at >= 0.0 or sim.crater_war.wyrd_choice == "secure", "rival raided after the first Stabilized (or path B warded it)")
			var reveal_at: float = sim.crater_war.rival_reveal_seconds()
			_check(reveal_at >= 14.0 * 60.0 and reveal_at < 20.0 * 60.0 + 0.001, "rival reveal is seeded between 14:00 and 20:00 (t=%.1f)" % reveal_at)
			var smoke_at: float = sim.crater_war.rival_foreshadow_seconds()
			_check(smoke_at >= 10.0 * 60.0 and smoke_at < 15.0 * 60.0 + 0.001, "foreshadow is seeded between 10:00 and 15:00 (t=%.1f)" % smoke_at)
			_check(sim.crater_war.rival_foreshadowed, "foreshadow landed before the reveal")
			_check(sim.crater_war.push_telegraphed, "rival push was marked on the map first")
			_check(sim.crater_war.banner_count >= 5, "rival banners grew before the push")
			_check(sim.crater_war.rival_threat_tier >= 3, "threat tier is visible before the push")
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
		if kind in ["wyrd_choice", "wyrd_choice_offered"] and not captured.has("did_choice"):
			captured["did_choice"] = true
			_note_event(sim, kind, message)
			captured["pending_choice"] = true
		if kind in ["seal_choice", "seal_choice_offered"] and not captured.has("did_seal_choice"):
			captured["did_seal_choice"] = true
			_note_event(sim, kind, message)
			captured["pending_seal_choice"] = true
		if kind in ["midgame_choice", "midgame_choice_offered"] and not captured.has("did_midgame"):
			captured["did_midgame"] = true
			_note_event(sim, kind, message)
			captured["pending_midgame"] = true
		if kind == "channel_wyrd" and not captured.has("did_channel"):
			captured["did_channel"] = true
			_note_event(sim, kind, message)
			captured["pending_channel"] = true
		if kind == "rival_foreshadow" and not captured.has("did_foreshadow"):
			captured["did_foreshadow"] = true
			_note_event(sim, kind, message)
			captured["pending_foreshadow"] = true
		if kind == "rival_escalation" and not captured.has("did_escalation"):
			captured["did_escalation"] = true
			_note_event(sim, kind, message)
			captured["pending_escalation"] = true
		if kind in ["rival_second_push", "rival_contest", "harvester_raid", "harvester_raid_spawn", "exposure_choice", "exposure_burn", "wyrd_choice", "wyrd_choice_offered", "first_harvest", "first_stabilized", "seal_choice", "seal_choice_offered", "rival_foreshadow", "rival_escalation", "midgame_choice", "midgame_choice_offered", "channel_wyrd"]:
			if not captured.has("did_%s" % kind):
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
	if captured.get("pending_choice", false):
		captured["pending_choice"] = false
		await _capture(game, sim, "t%02d_choice" % _mm(sim), "Wyrd pact at 6 Stabilized.")
	if captured.get("pending_ritual", false):
		captured["pending_ritual"] = false
		await _capture(game, sim, "t%02d_seal" % _mm(sim), "Seal the Fissure begun.")
	if captured.get("pending_midgame", false):
		captured["pending_midgame"] = false
		await _capture(game, sim, "t%02d_caravan" % _mm(sim), "Refugee caravan: shelter workers or raise palisades.")
	if captured.get("pending_channel", false):
		captured["pending_channel"] = false
		await _capture(game, sim, "t%02d_channel" % _mm(sim), "Channel Wyrd repairs a wall segment.")
	if captured.get("pending_camp", false):
		captured["pending_camp"] = false
		var camp_path := String(sim.crater_war.midgame_choice) if sim.crater_war != null else "camp"
		await _capture(game, sim, "t%02d_camp_%s" % [_mm(sim), camp_path], "Caravan aftermath still on the map.")
	if captured.get("pending_seal_choice", false):
		captured["pending_seal_choice"] = false
		var seal_path := String(sim.crater_war.seal_choice) if sim.crater_war != null else ""
		if seal_path == "" and sim.crater_war != null and sim.crater_war.seal_choice_ready():
			sim.request_seal_choice(sim.crater_war.bot_seal_path_for_seed(seed_value))
			seal_path = String(sim.crater_war.seal_choice)
		if seal_path == "":
			seal_path = "choice"
		await _capture(game, sim, "t%02d_seal_%s" % [_mm(sim), seal_path], "Seal defence: %s." % seal_path)
		if not headless and game != null and sim.crater_war != null and seal_path in ["wall", "overcharge"]:
			await _capture_other_seal(game, sim, seal_path)
	if captured.get("pending_foreshadow", false):
		captured["pending_foreshadow"] = false
		await _capture(game, sim, "t%02d_foreshadow" % _mm(sim), "Distant rival smoke before the reveal.")
	if captured.get("pending_escalation", false):
		captured["pending_escalation"] = false
		await _capture(game, sim, "t%02d_escalation" % _mm(sim), "Rival banners, army route, and threat tier on the map.")
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
		_note_event(sim, "ritual", "SEAL BEGUN — defend the fissure ceremony for 120 seconds.")
		captured["pending_ritual"] = true
	if sim.crater_war.rival_foreshadowed and not captured.has("did_foreshadow"):
		captured["did_foreshadow"] = true
		_note_event(sim, "rival_foreshadow", String(sim.last_message))
		captured["pending_foreshadow"] = true
	if sim.crater_war.push_telegraphed and not captured.has("did_escalation"):
		captured["did_escalation"] = true
		_note_event(sim, "rival_escalation", String(sim.last_message))
		captured["pending_escalation"] = true
	if sim.crater_war.seal_choice != "" and not captured.has("did_seal_choice"):
		captured["did_seal_choice"] = true
		_note_event(sim, "seal_choice", String(sim.last_message))
		captured["pending_seal_choice"] = true
	elif sim.crater_war.seal_choice_ready() and not captured.has("did_seal_choice"):
		captured["did_seal_choice"] = true
		_note_event(sim, "seal_choice_offered", "60s SEAL DEFENCE — reinforce the wall, or overcharge the Seal.")
		captured["pending_seal_choice"] = true
	if sim.crater_war.midgame_choice != "" and not captured.has("did_midgame"):
		captured["did_midgame"] = true
		_note_event(sim, "midgame_choice", String(sim.last_message))
		captured["pending_midgame"] = true
	elif sim.crater_war.midgame_choice_ready() and not captured.has("did_midgame"):
		captured["did_midgame"] = true
		_note_event(sim, "midgame_choice_offered", "REFUGEE CARAVAN — shelter two workers or raise palisades.")
		captured["pending_midgame"] = true
	if sim.crater_war.channel_uses >= 1 and not captured.has("did_channel"):
		captured["did_channel"] = true
		_note_event(sim, "channel_wyrd", String(sim.last_message))
		captured["pending_channel"] = true
	if sim.crater_war.midgame_choice != "" and float(sim.elapsed_seconds) >= 24.0 * 60.0 and not captured.has("did_camp"):
		captured["did_camp"] = true
		captured["pending_camp"] = true


func _maybe_rival(sim) -> void:
	if sim.rivalry == null:
		return
	var line := String(sim.rivalry.get_rival_status_line())
	if float(sim.elapsed_seconds) >= 600.0 and (line.contains("Outpost") or line.contains("Binding") or line.contains("Seal")):
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
	if sim.crater_war != null and sim.crater_war.choice_ready():
		meaningful = true
	if sim.crater_war != null and sim.crater_war.seal_choice_ready():
		meaningful = true
	if sim.crater_war != null and sim.crater_war.midgame_choice_ready():
		meaningful = true
	if sim.crater_war != null and sim.crater_war.can_begin():
		meaningful = true
	if sim.crater_war != null and sim.crater_war.channel_ready():
		meaningful = true
	if not bool(sim.is_night):
		var dusk_left := float(Simulation.DAY_LENGTH_SECONDS) - float(sim.phase_time)
		if dusk_left <= 90.0:
			meaningful = true
	# Founding through the crater march (first 12 min) is the opening
	# job — house, plank loop, night 1, road to the shard. Optional
	# paving later is still ignored; this stretch is not a lull.
	if now <= 12.0 * 60.0 + STEP_SECONDS:
		meaningful = true
	if sim.crater_war != null and sim.crater_war._has_completed(Defs.BUILDING_WYRD_HARVESTER) and sim.crater_war._has_completed(Defs.BUILDING_WYRD_REFINER) and sim.crater_war.stabilized_stock() < 12 and not bool(sim.game_finished):
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


func _capture_other_seal(game, sim, real_path: String) -> void:
	var other := "overcharge" if real_path == "wall" else "wall"
	var saved := String(sim.crater_war.seal_choice)
	sim.crater_war.seal_choice = other
	if game.world_view != null:
		game.world_view.seal_look_key = ""
	await _capture(game, sim, "t%02d_seal_%s" % [_mm(sim), other], "Staged Seal look: %s." % other)
	sim.crater_war.seal_choice = saved
	if game.world_view != null:
		game.world_view.seal_look_key = ""


func _capture(game, sim, name_value: String, caption: String) -> void:
	if captured.has(name_value):
		return
	if headless or game == null:
		captured[name_value] = "headless"
		notes["timeline"].append({"t": float(sim.elapsed_seconds), "shot": name_value, "caption": caption})
		return
	_frame_camera(game, sim, name_value)
	game._sync_presentation()
	if name_value.contains("victory") and game.has_method("_show_result_screen"):
		game._show_result_screen()
	if game.has_method("_update_ui"):
		game._update_ui()
	for _i in 16:
		await process_frame
		if game.world_view != null:
			game.world_view.stream_chunks(16000)
			if game.world_view.has_method("_sync_map_markers"):
				game.world_view._sync_map_markers()
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
	elif name_value.contains("escalat") or name_value.contains("foreshadow") or name_value.contains("rival"):
		focus = _rival_focus(game, sim)
		if name_value.contains("foreshadow"):
			focus = _smoke_focus(game, sim)
		zoom = 62.0
	elif name_value.contains("caravan") or name_value.contains("midgame") or name_value.contains("camp"):
		focus = game.world_view.tile_to_world(Vector2(sim.town_hall_position + Vector2i(6, 3)))
		if sim.crater_war != null:
			focus = game.world_view.tile_to_world(Vector2(sim.crater_war._caravan_tile()))
		zoom = 36.0
	elif name_value.contains("channel"):
		var channel_tile: Vector2i = sim.crater_war.last_channel_tile if sim.crater_war != null else Vector2i(-1, -1)
		if channel_tile.x < 0 and sim.crater_war != null:
			channel_tile = sim.crater_war.primary_fissure
		if channel_tile.x >= 0:
			focus = game.world_view.tile_to_world(Vector2(channel_tile))
		zoom = 48.0
	elif name_value.contains("seal") or name_value.contains("choice") or name_value.contains("ritual"):
		if sim.crater_war != null and sim.crater_war.primary_fissure.x >= 0:
			focus = game.world_view.tile_to_world(Vector2(sim.crater_war.primary_fissure))
		zoom = 58.0
	elif name_value.contains("victory") or name_value.contains("end") or name_value.contains("fissure_calm"):
		if sim.crater_war != null and sim.crater_war.primary_fissure.x >= 0:
			focus = game.world_view.tile_to_world(Vector2(sim.crater_war.primary_fissure))
		else:
			focus = game.world_view.tile_to_world(Vector2(sim.shard_position))
		zoom = 42.0
	game.camera_rig.configure_for_map(sim.map_size)
	game.camera_rig.compose_view(focus, zoom)
	game.world_view.note_camera(game.camera_rig.target_position, zoom)


func _rival_focus(game, sim) -> Vector3:
	if sim.crater_war != null:
		for marker in sim.map_markers:
			var kind := String(marker.get("kind", ""))
			if kind in ["rival_threat", "rival_route", "rival_banner", "rival"]:
				return game.world_view.tile_to_world(Vector2(Vector2i(marker.get("position", Vector2i.ZERO))))
	if sim.rivalry != null:
		for structure in sim.rivalry.get_structures("rival"):
			var pos := Vector2i(structure.get("position", Vector2i.ZERO))
			if sim.is_revealed(pos):
				return game.world_view.tile_to_world(Vector2(pos))
	if not sim.rival_seats.is_empty():
		return game.world_view.tile_to_world(Vector2(Vector2i(sim.rival_seats[0])))
	return game.world_view.opening_camera_focus()


func _smoke_focus(game, sim) -> Vector3:
	for marker in sim.map_markers:
		if String(marker.get("kind", "")) == "rival_smoke":
			return game.world_view.tile_to_world(Vector2(Vector2i(marker.get("position", Vector2i.ZERO))))
	return _rival_focus(game, sim)


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
		_unique("balance", "Seal the Fissure was not reached in 60 minutes on the 320 map (hall %s, shard %s, crater R=110)." % [str(sim.town_hall_position), str(sim.shard_position)])
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
			"contest_count": sim.crater_war.contest_count,
			"choice": sim.crater_war.wyrd_choice,
			"choice_offered_at": sim.crater_war.choice_offered_at,
			"choice_taken_at": sim.crater_war.choice_taken_at,
			"rival_reveal_at": sim.crater_war.rival_reveal_at,
			"first_harvest_at": sim.crater_war.first_harvest_at,
			"first_stabilized_at": sim.crater_war.first_stabilized_at,
			"seal_choice": sim.crater_war.seal_choice,
			"seal_choice_offered_at": sim.crater_war.seal_choice_offered_at,
			"seal_choice_taken_at": sim.crater_war.seal_choice_taken_at,
			"foreshadow_at": sim.crater_war.rival_foreshadow_at,
			"foreshadowed": sim.crater_war.rival_foreshadowed,
			"threat_tier": sim.crater_war.rival_threat_tier,
			"banner_count": sim.crater_war.banner_count,
			"push_telegraphed": sim.crater_war.push_telegraphed,
			"midgame_choice": sim.crater_war.midgame_choice,
			"midgame_offered_at": sim.crater_war.midgame_offered_at,
			"midgame_taken_at": sim.crater_war.midgame_taken_at,
			"midgame_at": sim.crater_war.midgame_at,
			"fortify_walls": sim.crater_war.fortify_walls,
			"victory_ceremony": sim.crater_war.victory_ceremony,
			"channel_uses": sim.crater_war.channel_uses,
			"first_build_at": sim.crater_war.first_build_at
		}
	notes["longest_idle"] = longest_idle
	notes["idle_gaps"] = idle_gaps
	notes["idle_settler_seconds"] = float(sim.idle_settler_seconds)
	notes["idle_settler_seconds_before"] = float(sim.idle_settler_seconds_before)
	notes["idle_bottleneck"] = String(sim.last_idle_bottleneck)
	print("DEMO_IDLE_SETTLERS seed=%d before=%.0f after=%.0f bottleneck=%s" % [
		seed_value, float(sim.idle_settler_seconds_before), float(sim.idle_settler_seconds), String(sim.last_idle_bottleneck)
	])
	print("DEMO_IDLE seed=%d longest=%.1fs gaps=%d first_12=%.1f first_build=%.1f seal=%.1f win=%.1f choice=%s seal_choice=%s midgame=%s channel=%d mid_at=%.1f reveal=%.1f smoke=%.1f" % [
		seed_value, longest_idle, idle_gaps.size(), first_12_at,
		sim.crater_war.first_build_at if sim.crater_war != null else -1.0,
		sim.crater_war.ritual_started_at if sim.crater_war != null else -1.0,
		float(sim.elapsed_seconds),
		sim.crater_war.wyrd_choice if sim.crater_war != null else "",
		sim.crater_war.seal_choice if sim.crater_war != null else "",
		sim.crater_war.midgame_choice if sim.crater_war != null else "",
		sim.crater_war.channel_uses if sim.crater_war != null else 0,
		sim.crater_war.midgame_taken_at if sim.crater_war != null else -1.0,
		sim.crater_war.rival_reveal_at if sim.crater_war != null else -1.0,
		sim.crater_war.rival_foreshadow_at if sim.crater_war != null else -1.0
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
