extends SceneTree

## Playtest.31 (T-SNS-009): proves the monster-kill cheer fires on a real player
## unit kill (with 0.8 s throttle) and that the music state machine walks
## day -> night -> night_combat -> night -> day, with the calm night bed muted
## during combat and stopped at dawn.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	if game.audio_director == null:
		failures.append("audio director missing")
		_finish(game)
		return
	var director = game.audio_director
	game.start_new_3d(game.DEFAULT_SEED)
	var sim = game.simulation_host.simulation
	sim.day_count = 2
	sim.is_night = false
	sim.phase_time = 40.0
	sim.enemies.clear()
	_ticks(game, 3)
	_expect_state(director, "day")
	_check(director.evidence_snapshot().get("stems", []).has("day"), "day bed audible in day")

	# Night with no engagement: calm night bed.
	sim.is_night = true
	sim.phase_time = 20.0
	sim._reveal_radius(sim.town_hall_position, 20)
	sim._spawn_enemy(Vector2i(1, 1), 30, 1, 0.0, 0, sim.ENEMY_RAIDER)
	sim.last_combat_elapsed = -1000.0
	_ticks(game, 8)
	_expect_state(director, "night")
	_check(not sim.is_combat_active(), "a distant, idle hostile is not combat")
	_check(director.evidence_snapshot().get("stems", []).has("night"), "calm night bed audible at night")

	# Real engagement: patrol soldier strikes an adjacent raider (hp = one strike).
	var guard: Dictionary = sim._create_patrol_worker(0, "pt31")
	guard["position"] = sim.town_hall_position + Vector2i(3, 0)
	sim.workers.append(guard)
	sim._spawn_enemy(guard["position"] + Vector2i(1, 0), sim.GUARD_DAMAGE, 1, 0.0, 0, sim.ENEMY_RAIDER)
	var kills_before := int(sim.player_monster_kills)
	sim._update_patrol_combat(1.6)
	sim._update_patrol_combat(0.5)
	_check(int(sim.player_monster_kills) == kills_before + 1, "soldier strike credits exactly one monster kill")
	_check(String(sim.last_player_kill.get("source", "")) == "soldier", "kill source recorded as soldier")
	var events: Array = sim.consume_audio_events()
	_check(events.has("monster_kill"), "simulation emits monster_kill audio event on player kill")
	for event_name in events:
		director.handle_sim_event(String(event_name))
	_check(int(director.cheers_played) == 1, "cheer played on first kill")
	print("PT31_CHEER path=%s loaded=%s" % [String(director.CUE_PATHS["monster_kill_cheer"]), str(director.cue_players["monster_kill_cheer"].stream != null)])
	_check(director.cue_players["monster_kill_cheer"].stream != null, "cheer asset loads")
	# Multi-kill inside the throttle window -> one cheer.
	director.handle_sim_event("monster_kill")
	_check(int(director.cheers_played) == 1 and int(director.cheers_throttled) == 1, "second kill within 0.8 s is throttled")
	_ticks(game, 8)
	_expect_state(director, "raid")
	var combat_stems: Array = director.evidence_snapshot().get("stems", [])
	_check(combat_stems.has("raid"), "combat/danger bed audible in night_combat")
	_check(not combat_stems.has("night"), "calm night bed muted in night_combat")
	_ticks(game, 2)
	director.handle_sim_event("monster_kill")
	_check(int(director.cheers_played) == 2, "cheer plays again once throttle window passed")

	# Tower kill path also credits a player kill.
	var tower_kills := int(sim.player_monster_kills)
	sim._spawn_enemy(sim.town_hall_position + Vector2i(-3, 0), 1, 1, 0.0, 0, sim.ENEMY_RAIDER)
	var tower_target: Dictionary = sim.enemies[sim.enemies.size() - 1]
	sim.projectiles.append({"from": sim._vector_to_data(sim.town_hall_position), "to": sim._vector_to_data(tower_target["position"]), "life": 0.01, "total": 0.65, "target_enemy_id": int(tower_target["id"]), "damage": sim.TOWER_DAMAGE, "damage_applied": false})
	sim._update_projectiles(0.1)
	_check(int(sim.player_monster_kills) == tower_kills + 1, "watchtower bolt kill is credited as a player kill")

	# Engagement ends (linger elapsed, remaining hostile idle far away) -> back to night.
	sim._update_enemies(0.0)
	sim.elapsed_seconds += sim.COMBAT_LINGER_SECONDS + 1.0
	for enemy in sim.enemies:
		enemy["position"] = Vector2i(1, 1)
	_ticks(game, 3)
	_expect_state(director, "night")
	# All hostiles gone -> combat_win cue on the next combat end.
	sim._note_combat()
	_ticks(game, 1)
	_expect_state(director, "raid")
	sim.enemies.clear()
	_ticks(game, 1)
	_expect_state(director, "night")
	var cue_log: Array = director.evidence_snapshot().get("log", [])
	_check(" ".join(cue_log).contains("cue combat_win"), "combat_win cue when the last hostile falls")

	# Dawn -> day: night bed must actually fade out.
	sim.is_night = false
	sim.day_count = 3
	sim.phase_time = 5.0
	_ticks(game, 12)
	_expect_state(director, "day")
	var night_player: AudioStreamPlayer = director.stem_players["night"]
	var raid_player: AudioStreamPlayer = director.stem_players["raid"]
	print("PT31_DAWN night_db=%.1f raid_db=%.1f day_db=%.1f" % [night_player.volume_db, raid_player.volume_db, director.stem_players["day"].volume_db])
	_check(night_player.volume_db <= -60.0, "night bed faded out at dawn")
	_check(raid_player.volume_db <= -60.0, "combat bed faded out at dawn")
	var transitions: Array = director.evidence_snapshot().get("transitions", [])
	print("PT31_TRANSITIONS %s" % ",".join(transitions))
	var joined := ",".join(transitions)
	_check(joined.contains("day->night") or joined.contains("dusk->night"), "transition into night logged")
	_check(joined.contains("night->night_combat"), "night->night_combat logged")
	_check(joined.contains("night_combat->night"), "night_combat->night logged")
	_check(joined.contains("night->day"), "night->day logged")
	_finish(game)


func _ticks(game, count: int) -> void:
	for _i in count:
		game._tick_audio(0.4)


func _expect_state(director, expected: String) -> void:
	var actual := String(director.current_state)
	_check(actual == expected, "state %s (got %s)" % [expected, actual])


func _check(ok: bool, label: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		failures.append(label)


func _finish(game) -> void:
	game.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	if failures.is_empty():
		print("PT31_AUDIO PASS")
		quit(0)
	else:
		print("PT31_AUDIO FAIL %d" % failures.size())
		quit(1)
