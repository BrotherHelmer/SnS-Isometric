class_name ProductionAudioDirector3D
extends Node

## State-driven mix for Day / Dusk / Night / Raid / Reckoning / Victory / Defeat.
## Music stems crossfade. Work SFX are distance-limited.

const Identity = preload("res://src/GodotClient3D/Scripts/production_identity.gd")

const STEM_PATHS := {
	"day": "res://assets/settlement/audio/presentation/bgm_settlement_loop.ogg",
	"activity": "res://assets/settlement/audio/presentation/score_settlement_activity.wav",
	"dusk": "res://assets/settlement/audio/presentation/score_dusk_tension.wav",
	"night": "res://assets/settlement/audio/presentation/score_night_percussion.wav",
	"raid": "res://assets/settlement/audio/presentation/score_metal_combat.wav",
	"ambience": "res://assets/settlement/audio/presentation/ambient_world.wav",
	"wyrd": "res://assets/settlement/audio/presentation/wyrd_drone.wav",
	"lumen": "res://assets/settlement/audio/presentation/lumen_hum.wav"
}

const CUE_PATHS := {
	"click": "res://assets/settlement/audio/presentation/ui_click.wav",
	"nightfall": "res://assets/settlement/audio/presentation/nightfall_sting.wav",
	"dawn": "res://assets/settlement/audio/presentation/dawn_release.wav",
	"victory": "res://assets/settlement/audio/presentation/victory_motif.wav",
	"defeat": "res://assets/settlement/audio/presentation/defeat_motif.wav",
	"reckoning": "res://assets/settlement/audio/presentation/reckoning_pulse.wav",
	"scream": "res://assets/settlement/audio/presentation/night_scream.wav",
	"enemy": "res://assets/settlement/audio/enemy.wav",
	"night_event": "res://assets/settlement/audio/night.wav",
	"attack": "res://assets/settlement/audio/attack.wav",
	"tower": "res://assets/settlement/audio/tower.wav",
	"build_start": "res://assets/settlement/audio/build_start.wav",
	"build_complete": "res://assets/settlement/audio/build_complete.wav",
	"soldier": "res://assets/settlement/audio/soldier.wav",
	"farm_complete": "res://assets/settlement/audio/farm_animal.wav",
	"farm_ambient": "res://assets/settlement/audio/farm_ambient.wav",
	"barracks_complete": "res://assets/settlement/audio/barracks_ready.wav",
	"settler_spawn_worker": "res://assets/settlement/audio/settler_arrive_worker.wav",
	"settler_spawn_soldier": "res://assets/settlement/audio/settler_arrive_soldier.wav",
	"settler_spawn_generic": "res://assets/settlement/audio/settler_arrive_generic.wav",
	"combat_win": "res://assets/settlement/audio/presentation/victory_motif.wav",
	"soldier_death": "res://assets/settlement/audio/presentation/defeat_motif.wav",
	"delivery": "res://assets/settlement/audio/delivery.wav",
	"monster_kill_cheer": "res://assets/settlement/audio/monster_kill_cheer.wav"
}

## Playtest.31: log-facing names for music states ("raid" is the night combat bed).
const STATE_LABELS := {
	"raid": "night_combat"
}
const CHEER_MIN_INTERVAL_SECONDS := 0.8
const AUDIBLE_STEM_DB := -40.0

var settings: Dictionary = {}
var current_state := "day"
var last_raid := false
var last_night := false
var stem_players: Dictionary = {}
var cue_players: Dictionary = {}
var stem_targets: Dictionary = {}
var work_pool: Array[AudioStreamPlayer3D] = []
var work_index := 0
var camera: Camera3D
var last_listen_log: Array[String] = []
var scream_cooldown := 4.0
var paused := false
var audio_clock := 0.0
var last_cheer_clock := -1000.0
var cheers_played := 0
var cheers_throttled := 0
var audible_stems: Dictionary = {}
var stem_restarts: Dictionary = {}
var transition_log: Array[String] = []
var verbose_log := true
## Evidence tooling (debug-only; every field stays inert without the CLI flags).
## --audio-master=<0..1>          in-memory master override, never persisted
## --no-persist-settings          never write user://one_shard_audio.json
## --evidence-audio-record=<wav>  AudioEffectRecord on Master (+ Music/SFX stems)
var persist_settings := true
var master_override := -1.0
var record_path := ""
var record_effects: Dictionary = {}
var record_clock: AudioEffectCapture
var record_frames := 0
var record_active := false
var record_snapshot_next := 0.0
var stem_last_positions: Dictionary = {}
var loop_wraps := 0


func _exit_tree() -> void:
	if record_active:
		finish_recording()
	for player in stem_players.values() + cue_players.values() + work_pool:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	stem_players.clear()
	cue_players.clear()
	work_pool.clear()


func setup(host: Node, camera_value: Camera3D) -> void:
	camera = camera_value
	_ensure_buses()
	_parse_evidence_flags()
	settings = Identity.load_audio_settings()
	if master_override >= 0.0 or not persist_settings:
		_audio_log("AUDIO_SETTINGS file_master=%.3f file_music=%.3f file_sfx=%.3f master_override=%s persist=%s" % [
			float(settings.get("master", 1.0)), float(settings.get("music", 0.72)), float(settings.get("sfx", 0.85)),
			("%.3f" % master_override) if master_override >= 0.0 else "none", str(persist_settings)
		])
	apply_settings(settings)
	for stem_name in STEM_PATHS:
		var player := AudioStreamPlayer.new()
		player.name = "Stem_%s" % stem_name
		player.bus = "Music" if stem_name in ["day", "activity", "dusk", "night", "raid"] else "Ambience"
		var stream = _load_stream(String(STEM_PATHS[stem_name]))
		if stream != null:
			player.stream = stream
			if stream is AudioStreamWAV:
				var wav := stream as AudioStreamWAV
				wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
				# Imported stems carry loop_end=-1/0; without a real loop end the
				# player stops at the end and tick() restarted it from 0 (stem
				# desync / audible restart). Loop over the whole sample instead.
				if wav.loop_end <= wav.loop_begin:
					wav.loop_begin = 0
					wav.loop_end = int(round(wav.get_length() * float(wav.mix_rate)))
			elif stream is AudioStreamOggVorbis:
				(stream as AudioStreamOggVorbis).loop = true
		player.volume_db = -80.0
		host.add_child(player)
		stem_players[stem_name] = player
		stem_targets[stem_name] = -80.0
		player.play()
	for cue_name in CUE_PATHS:
		var cue := AudioStreamPlayer.new()
		cue.name = "Cue_%s" % cue_name
		cue.bus = "SFX"
		cue.stream = _load_stream(String(CUE_PATHS[cue_name]))
		host.add_child(cue)
		cue_players[cue_name] = cue
	for index in 6:
		var spatial := AudioStreamPlayer3D.new()
		spatial.name = "WorkEmitter_%d" % index
		spatial.bus = "SFX"
		spatial.unit_size = 8.0
		spatial.max_distance = 42.0
		spatial.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		host.add_child(spatial)
		work_pool.append(spatial)
	if record_path != "":
		_start_recording()


func apply_settings(next: Dictionary) -> void:
	settings = next
	var master_linear := float(settings.get("master", 1.0))
	if master_override >= 0.0:
		master_linear = master_override
	_set_bus_volume("Master", master_linear)
	_set_bus_volume("Music", float(settings.get("music", 0.72)))
	_set_bus_volume("SFX", float(settings.get("sfx", 0.85)))
	_set_bus_volume("Ambience", float(settings.get("sfx", 0.85)) * 0.9)
	if persist_settings:
		Identity.save_audio_settings(settings)


func tick(simulation, delta: float, menu_visible: bool, result_visible: bool, paused_value := false) -> void:
	paused = paused_value
	audio_clock += delta
	var next_state := _resolve_state(simulation, menu_visible, result_visible)
	if next_state != current_state:
		_on_state_entered(next_state, current_state, simulation)
		current_state = next_state
	_update_stem_targets(simulation, menu_visible)
	var duck := 4.0 if paused and not menu_visible else 0.0
	for stem_name in stem_players:
		var player: AudioStreamPlayer = stem_players[stem_name]
		var target := float(stem_targets.get(stem_name, -80.0)) - duck
		player.volume_db = move_toward(player.volume_db, target, delta * 28.0)
		if not player.playing and player.stream != null:
			player.play()
			var restarts := int(stem_restarts.get(stem_name, 0)) + 1
			stem_restarts[stem_name] = restarts
			if restarts <= 3:
				_audio_log("AUDIO_STEM_RESTART name=%s count=%d" % [stem_name, restarts])
	_log_stem_audibility()
	if record_active:
		_tick_recording()
	_tick_night_screams(delta)
	if simulation != null:
		last_night = bool(simulation.is_night)
		last_raid = bool(simulation.is_night) and simulation.enemies.size() > 0


func play_cue(cue_name: String) -> void:
	if not cue_players.has(cue_name):
		return
	var player: AudioStreamPlayer = cue_players[cue_name]
	if player.stream != null:
		player.play()
		last_listen_log.append("%s cue %s" % [Time.get_time_string_from_system(), cue_name])
		if last_listen_log.size() > 24:
			last_listen_log.pop_front()


## Short cheer when a soldier or soldier-staffed tower fells a monster. Throttled
## so a multi-kill in one volley produces one cheer, not a spam burst.
func play_monster_kill_cheer() -> bool:
	if audio_clock - last_cheer_clock < CHEER_MIN_INTERVAL_SECONDS:
		cheers_throttled += 1
		_audio_log("AUDIO_CHEER_THROTTLED t=%.2f since_last=%.2f throttled=%d" % [audio_clock, audio_clock - last_cheer_clock, cheers_throttled])
		return false
	last_cheer_clock = audio_clock
	cheers_played += 1
	var path := String(CUE_PATHS.get("monster_kill_cheer", ""))
	var cue: AudioStreamPlayer = cue_players.get("monster_kill_cheer", null)
	var loaded := cue != null and cue.stream != null
	play_cue("monster_kill_cheer")
	_audio_log("AUDIO_CHEER t=%.2f path=%s loaded=%s bus=%s sfx_linear=%.3f played=%d" % [
		audio_clock, path, str(loaded), String(cue.bus) if cue != null else "-",
		db_to_linear(AudioServer.get_bus_volume_db(_bus_index("SFX"))), cheers_played
	])
	return true


func play_ui_click() -> void:
	play_cue("click")


func play_work_at(world_position: Vector3, kind: String) -> void:
	if work_pool.is_empty():
		return
	if camera != null and camera.global_position.distance_to(world_position) > 36.0:
		return
	var playing := 0
	for emitter in work_pool:
		if emitter.playing:
			playing += 1
	if playing >= 3:
		return
	var player: AudioStreamPlayer3D = work_pool[work_index % work_pool.size()]
	work_index += 1
	var path := ""
	match kind:
		"chop":
			path = "res://assets/settlement/audio/presentation/work_chop.wav"
		"saw":
			path = "res://assets/settlement/audio/saw.wav"
		_:
			path = "res://assets/settlement/audio/presentation/work_hammer.wav"
	player.stream = _load_stream(path)
	player.global_position = world_position
	player.volume_db = -10.0
	player.play()


func handle_sim_event(event_name: String) -> void:
	match event_name:
		"enemy":
			play_cue("enemy")
		"night":
			play_cue("night_event")
		"attack":
			play_cue("attack")
		"tower":
			play_cue("tower")
		"build_start":
			play_cue("build_start")
		"build_complete":
			play_cue("build_complete")
		"soldier":
			play_cue("soldier")
		"farm_complete":
			play_cue("farm_complete")
		"farm_ambient":
			play_cue("farm_ambient")
		"barracks_complete":
			play_cue("barracks_complete")
		"settler_spawn_worker":
			play_cue("settler_spawn_worker")
		"settler_spawn_soldier":
			play_cue("settler_spawn_soldier")
		"settler_spawn_generic":
			play_cue("settler_spawn_generic")
		"soldier_death":
			play_cue("soldier_death")
		"delivery":
			play_cue("delivery")
		"monster_kill":
			play_monster_kill_cheer()
		_:
			pass


func evidence_snapshot() -> Dictionary:
	var active: Array[String] = []
	for stem_name in stem_players:
		if float(stem_targets.get(stem_name, -80.0)) > -40.0:
			active.append(String(stem_name))
	return {
		"state": current_state,
		"stems": active,
		"buses": {
			"master": db_to_linear(AudioServer.get_bus_volume_db(_bus_index("Master"))),
			"music": db_to_linear(AudioServer.get_bus_volume_db(_bus_index("Music"))),
			"sfx": db_to_linear(AudioServer.get_bus_volume_db(_bus_index("SFX")))
		},
		"log": last_listen_log.duplicate(),
		"transitions": transition_log.duplicate(),
		"cheers_played": cheers_played,
		"cheers_throttled": cheers_throttled
	}


static func state_label(state_name: String) -> String:
	return String(STATE_LABELS.get(state_name, state_name))


func _audio_log(line: String) -> void:
	if verbose_log:
		if record_active:
			print("[%s] t_wav=%.3f %s" % [Time.get_datetime_string_from_system(), wav_time(), line])
		else:
			print("[%s] %s" % [Time.get_datetime_string_from_system(), line])


func _parse_evidence_flags() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--audio-master="):
			master_override = clampf(float(argument.trim_prefix("--audio-master=")), 0.0, 1.0)
			persist_settings = false
		elif argument == "--no-persist-settings" or argument.begins_with("--evidence-") or argument.begins_with("--debug-"):
			persist_settings = false
		if argument.begins_with("--evidence-audio-record="):
			record_path = argument.trim_prefix("--evidence-audio-record=")


## Seconds of mixed audio since recording started: frames that passed the Master
## bus effect chain (same chain as the AudioEffectRecord), so log and WAV share
## one time base.
func wav_time() -> float:
	if record_clock == null:
		return -1.0
	var pending := record_clock.get_frames_available()
	return float(record_frames + pending) / maxf(1.0, AudioServer.get_mix_rate())


func _start_recording() -> void:
	var master_index := _bus_index("Master")
	for bus_name in ["Master", "Music", "SFX"]:
		var record := AudioEffectRecord.new()
		record.format = AudioStreamWAV.FORMAT_16_BITS
		AudioServer.add_bus_effect(_bus_index(bus_name), record)
		record_effects[bus_name] = record
	record_clock = AudioEffectCapture.new()
	record_clock.buffer_length = 5.0
	AudioServer.add_bus_effect(master_index, record_clock)
	for bus_name in record_effects:
		(record_effects[bus_name] as AudioEffectRecord).set_recording_active(true)
	record_active = true
	record_frames = 0
	_audio_log("AUDIO_RECORD_START path=%s mix_rate=%d args=%s" % [record_path, int(AudioServer.get_mix_rate()), " ".join(OS.get_cmdline_args())])


func _tick_recording() -> void:
	var available := record_clock.get_frames_available()
	if available > 0:
		record_clock.get_buffer(available)
		record_frames += available
	for stem_name in stem_players:
		var player: AudioStreamPlayer = stem_players[stem_name]
		if not player.playing:
			continue
		var position: float = player.get_playback_position()
		var last := float(stem_last_positions.get(stem_name, -1.0))
		if last >= 0.0 and position + 0.25 < last:
			loop_wraps += 1
			_audio_log("AUDIO_LOOP_WRAP name=%s from=%.3f to=%.3f length=%.3f volume_db=%.1f restarts=%d" % [
				stem_name, last, position, player.stream.get_length() if player.stream != null else 0.0,
				player.volume_db, int(stem_restarts.get(stem_name, 0))
			])
		stem_last_positions[stem_name] = position
	var now := wav_time()
	if now >= record_snapshot_next:
		record_snapshot_next = now + 0.5
		var parts: Array[String] = []
		for stem_name in stem_players:
			var player: AudioStreamPlayer = stem_players[stem_name]
			parts.append("%s=%.1f%s" % [stem_name, player.volume_db, "" if player.playing else "(stopped)"])
		var cues: Array[String] = []
		for cue_name in cue_players:
			if (cue_players[cue_name] as AudioStreamPlayer).playing:
				cues.append(String(cue_name))
		_audio_log("AUDIO_STEMS state=%s %s cues=%s" % [state_label(current_state), " ".join(parts), ",".join(cues)])


## Stops the evidence recording and writes Master (record_path) plus Music/SFX
## stems next to it. Returns the Master path, or "" if nothing was recording.
func finish_recording() -> String:
	if not record_active:
		return ""
	_tick_recording()
	var final_time := wav_time()
	record_active = false
	for bus_name in record_effects:
		var record: AudioEffectRecord = record_effects[bus_name]
		record.set_recording_active(false)
		var wav: AudioStreamWAV = record.get_recording()
		var path := record_path if bus_name == "Master" else "%s_%s.wav" % [record_path.get_basename(), String(bus_name).to_lower()]
		var err: int = int(wav.save_to_wav(path)) if wav != null else int(ERR_UNAVAILABLE)
		print("[%s] t_wav=%.3f AUDIO_RECORD_SAVED bus=%s path=%s err=%d length=%.3f mix_rate=%d stereo=%s" % [
			Time.get_datetime_string_from_system(), final_time, bus_name, path, err,
			wav.get_length() if wav != null else 0.0, wav.mix_rate if wav != null else 0, str(wav.stereo if wav != null else false)
		])
	print("[%s] t_wav=%.3f AUDIO_RECORD_DONE frames=%d loop_wraps=%d restarts=%s cheers=%d throttled=%d" % [
		Time.get_datetime_string_from_system(), final_time, record_frames, loop_wraps, JSON.stringify(stem_restarts), cheers_played, cheers_throttled
	])
	return record_path


func _log_stem_audibility() -> void:
	for stem_name in stem_players:
		var player: AudioStreamPlayer = stem_players[stem_name]
		var audible := player.volume_db > AUDIBLE_STEM_DB
		if bool(audible_stems.get(stem_name, false)) == audible:
			continue
		audible_stems[stem_name] = audible
		_audio_log("AUDIO_STEM %s name=%s path=%s volume_db=%.1f target_db=%.1f bus=%s state=%s" % [
			"ON" if audible else "OFF", stem_name, String(STEM_PATHS.get(stem_name, "")),
			player.volume_db, float(stem_targets.get(stem_name, -80.0)), player.bus, state_label(current_state)
		])


func _resolve_state(simulation, menu_visible: bool, result_visible: bool) -> String:
	if result_visible and simulation != null:
		return "victory" if bool(simulation.victory) else "defeat"
	if menu_visible:
		return "menu"
	if simulation == null:
		return "day"
	if bool(simulation.reckoning_active):
		return "reckoning"
	if bool(simulation.is_night) and _combat_active(simulation):
		return "raid"
	if bool(simulation.is_night):
		return "night"
	var remaining: float = float(simulation.DAY_LENGTH_SECONDS) - float(simulation.phase_time)
	if remaining <= 60.0:
		return "dusk"
	return "day"


## Root cause fix (playtest.31): the old test was "night and any enemy exists".
## Waves spawn inside _start_night(), so "raid" began at the nightfall frame and
## persisted all night; actual fighting never changed the mix. Now the combat bed
## follows real engagement reported by the simulation.
func _combat_active(simulation) -> bool:
	if simulation == null:
		return false
	if simulation.has_method("is_combat_active"):
		return bool(simulation.is_combat_active())
	return simulation.enemies.size() > 0


func _living_hostiles(simulation) -> int:
	if simulation == null:
		return 0
	if simulation.has_method("living_hostile_count"):
		return int(simulation.living_hostile_count())
	return simulation.enemies.size()


func _on_state_entered(next_state: String, previous: String, simulation) -> void:
	match next_state:
		"dusk":
			if previous == "day":
				play_cue("nightfall")
		"raid":
			if previous != "raid":
				play_cue("enemy")
				scream_cooldown = 1.6
		"night":
			if previous == "raid" and _living_hostiles(simulation) == 0:
				play_cue("combat_win")
			if previous in ["dusk", "day"]:
				scream_cooldown = 3.2
		"reckoning":
			play_cue("reckoning")
		"victory":
			play_cue("victory")
		"defeat":
			play_cue("defeat")
		"day":
			if previous in ["night", "raid", "dusk"] and simulation != null and int(simulation.day_count) > 1:
				play_cue("dawn")
	last_listen_log.append("state %s -> %s" % [previous, next_state])
	var line := "%s->%s" % [state_label(previous), state_label(next_state)]
	transition_log.append(line)
	if transition_log.size() > 48:
		transition_log.pop_front()
	_audio_log("AUDIO_MUSIC_STATE t=%.2f from=%s to=%s night=%s combat=%s hostiles=%d day=%d music_bus=%.3f master_bus=%.3f" % [
		audio_clock, state_label(previous), state_label(next_state),
		str(bool(simulation.is_night)) if simulation != null else "-",
		str(_combat_active(simulation)) if simulation != null else "-",
		_living_hostiles(simulation),
		int(simulation.day_count) if simulation != null else 0,
		db_to_linear(AudioServer.get_bus_volume_db(_bus_index("Music"))),
		db_to_linear(AudioServer.get_bus_volume_db(_bus_index("Master")))
	])


func _update_stem_targets(simulation, menu_visible: bool) -> void:
	for stem_name in stem_targets:
		stem_targets[stem_name] = -80.0
	stem_targets["ambience"] = -16.0
	var pop := 3
	if simulation != null:
		pop = int(simulation.population_current)
	var activity_db := lerpf(-26.0, -8.0, clampf(float(pop) / 10.0, 0.0, 1.0))
	match current_state:
		"menu":
			stem_targets["day"] = -16.0
			stem_targets["ambience"] = -14.0
			stem_targets["wyrd"] = -34.0
		"day":
			stem_targets["day"] = -8.0
			stem_targets["activity"] = activity_db
			stem_targets["ambience"] = -11.0
			stem_targets["lumen"] = -30.0
		"dusk":
			stem_targets["day"] = -20.0
			stem_targets["activity"] = -32.0
			stem_targets["dusk"] = -10.0
			stem_targets["ambience"] = -18.0
			stem_targets["wyrd"] = -20.0
			stem_targets["lumen"] = -26.0
		"night":
			stem_targets["dusk"] = -22.0
			stem_targets["night"] = -9.0
			stem_targets["ambience"] = -28.0
			stem_targets["wyrd"] = -16.0
			stem_targets["lumen"] = -18.0
		"raid":
			# Night combat: the calm night percussion bed is faded out completely and
			# the danger/combat score takes over (was night -12 dB under raid -7 dB).
			stem_targets["raid"] = -6.0
			stem_targets["ambience"] = -32.0
			stem_targets["wyrd"] = -18.0
		"reckoning":
			stem_targets["raid"] = -8.0
			stem_targets["night"] = -14.0
			stem_targets["wyrd"] = -8.0
			stem_targets["ambience"] = -30.0
			stem_targets["lumen"] = -22.0
		"victory":
			stem_targets["day"] = -14.0
			stem_targets["activity"] = -22.0
			stem_targets["ambience"] = -14.0
			stem_targets["lumen"] = -22.0
		"defeat":
			stem_targets["dusk"] = -16.0
			stem_targets["ambience"] = -22.0
			stem_targets["wyrd"] = -24.0
	if simulation != null and simulation.has_method("get_wyrd_pressure"):
		var band := String(simulation.get_wyrd_pressure().get("band", "QUIET"))
		if band in ["DANGEROUS", "SEVERE", "CRITICAL"] and current_state in ["day", "dusk"]:
			stem_targets["wyrd"] = maxf(float(stem_targets["wyrd"]), -22.0)
	if menu_visible:
		stem_targets["activity"] = -80.0
		stem_targets["raid"] = -80.0
		stem_targets["night"] = -80.0


func _tick_night_screams(delta: float) -> void:
	if current_state not in ["night", "raid", "reckoning"]:
		return
	scream_cooldown -= delta
	if scream_cooldown > 0.0:
		return
	play_cue("scream")
	scream_cooldown = 5.5 if current_state == "raid" or current_state == "reckoning" else 10.0


func _ensure_buses() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_ensure_bus("Ambience")


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")


func _bus_index(bus_name: String) -> int:
	return maxi(0, AudioServer.get_bus_index(bus_name))


func _set_bus_volume(bus_name: String, linear: float) -> void:
	AudioServer.set_bus_volume_db(_bus_index(bus_name), linear_to_db(clampf(linear, 0.0001, 1.0)))


func _load_stream(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path)
	return null
