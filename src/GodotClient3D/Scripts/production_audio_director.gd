class_name ProductionAudioDirector3D
extends Node

## State-driven mix for Day / Dusk / Night / Raid / Reckoning / Victory / Defeat.
## Music stems crossfade. Work SFX are distance-limited.

const Identity = preload("res://src/GodotClient3D/Scripts/production_identity.gd")

const STEM_PATHS := {
	"day": "res://assets/settlement/audio/presentation/score_pastoral_foundation.wav",
	"activity": "res://assets/settlement/audio/presentation/score_settlement_activity.wav",
	"dusk": "res://assets/settlement/audio/presentation/score_dusk_tension.wav",
	"night": "res://assets/settlement/audio/presentation/score_night_percussion.wav",
	"raid": "res://assets/settlement/audio/presentation/score_metal_combat.wav",
	"ambience": "res://assets/settlement/audio/presentation/settlement_wind_birds.wav",
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
	"settler_spawn_generic": "res://assets/settlement/audio/settler_arrive_generic.wav"
}

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


func _exit_tree() -> void:
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
	settings = Identity.load_audio_settings()
	apply_settings(settings)
	for stem_name in STEM_PATHS:
		var player := AudioStreamPlayer.new()
		player.name = "Stem_%s" % stem_name
		player.bus = "Music" if stem_name in ["day", "activity", "dusk", "night", "raid"] else "Ambience"
		var stream = _load_stream(String(STEM_PATHS[stem_name]))
		if stream != null:
			player.stream = stream
			if stream is AudioStreamWAV:
				(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
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


func apply_settings(next: Dictionary) -> void:
	settings = next
	_set_bus_volume("Master", float(settings.get("master", 1.0)))
	_set_bus_volume("Music", float(settings.get("music", 0.85)))
	_set_bus_volume("SFX", float(settings.get("sfx", 1.0)))
	_set_bus_volume("Ambience", float(settings.get("sfx", 1.0)) * 0.9)
	Identity.save_audio_settings(settings)


func tick(simulation, delta: float, menu_visible: bool, result_visible: bool, paused_value := false) -> void:
	paused = paused_value
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
		"log": last_listen_log.duplicate()
	}


func _resolve_state(simulation, menu_visible: bool, result_visible: bool) -> String:
	if result_visible and simulation != null:
		return "victory" if bool(simulation.victory) else "defeat"
	if menu_visible:
		return "menu"
	if simulation == null:
		return "day"
	if bool(simulation.reckoning_active):
		return "reckoning"
	if bool(simulation.is_night) and simulation.enemies.size() > 0:
		return "raid"
	if bool(simulation.is_night):
		return "night"
	var remaining: float = float(simulation.DAY_LENGTH_SECONDS) - float(simulation.phase_time)
	if remaining <= 60.0:
		return "dusk"
	return "day"


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
			stem_targets["night"] = -12.0
			stem_targets["raid"] = -7.0
			stem_targets["dusk"] = -28.0
			stem_targets["ambience"] = -32.0
			stem_targets["wyrd"] = -12.0
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
