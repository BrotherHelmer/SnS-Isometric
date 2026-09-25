extends SceneTree

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Tuning = preload("res://src/GodotClient/Scripts/one_shard_rivalry_tuning.gd")


func _init() -> void:
	var failures: Array[String] = []
	var simulation = Simulation.new(70, 70, 424242, false, true)
	var rivalry = simulation.rivalry

	var player_wood_before: int = rivalry.get_resource(Tuning.PLAYER_REALM, Defs.RESOURCE_WOOD)
	var ai_wood_before: int = rivalry.get_resource(Tuning.AI_REALM, Defs.RESOURCE_WOOD)
	check(rivalry.spend(Tuning.AI_REALM, {Defs.RESOURCE_WOOD: 2}), "rival realm can spend its own resource ledger", failures)
	check(
		rivalry.get_resource(Tuning.PLAYER_REALM, Defs.RESOURCE_WOOD) == player_wood_before
		and rivalry.get_resource(Tuning.AI_REALM, Defs.RESOURCE_WOOD) == ai_wood_before - 2,
		"player and rival resources remain isolated",
		failures
	)

	var player_entrance: Vector2i = simulation._town_hall_entrance_tile()
	var valid_road := player_entrance + Vector2i.LEFT
	_prepare_tile(simulation, valid_road, player_entrance)
	var road_wood_before: int = rivalry.get_resource(Tuning.PLAYER_REALM, Defs.RESOURCE_WOOD)
	var road_result: Dictionary = rivalry.request_road(Tuning.PLAYER_REALM, valid_road)
	check(bool(road_result.get("success", false)), "player can place a valid connected owned road", failures)
	check(
		rivalry.road_connected_to_home(Tuning.PLAYER_REALM, valid_road)
		and rivalry.get_resource(Tuning.PLAYER_REALM, Defs.RESOURCE_WOOD) == road_wood_before,
		"roads are free and expose continuous home connectivity",
		failures
	)
	var invalid_road: Vector2i = simulation.shard_position + Vector2i(9, 9)
	_prepare_tile(simulation, invalid_road, valid_road)
	check(
		not bool(rivalry.validate_road(Tuning.PLAYER_REALM, invalid_road).get("success", false)),
		"disconnected road placement is rejected",
		failures
	)

	var ai_entrance: Vector2i = simulation._rival_town_hall_entrance_tile()
	var ai_road := ai_entrance + Vector2i.RIGHT
	_prepare_tile(simulation, ai_road, ai_entrance)
	simulation.revealed_tiles.erase(simulation._tile_key(ai_road))
	var shared_api_result: Dictionary = rivalry.request_road(Tuning.AI_REALM, ai_road)
	check(
		bool(shared_api_result.get("success", false))
		and rivalry.owns_road(Tuning.AI_REALM, ai_road),
		"AI uses the same free road-placement API",
		failures
	)
	check(
		not simulation.is_revealed(ai_road),
		"rival construction does not reveal remote terrain to the player",
		failures
	)

	rivalry.add_resource(Tuning.PLAYER_REALM, Defs.RESOURCE_WOOD, 50)
	rivalry.add_resource(Tuning.PLAYER_REALM, Defs.RESOURCE_WYRD, 20)
	var pillar_tile := valid_road + Vector2i.DOWN
	_prepare_tile(simulation, pillar_tile, valid_road)
	var pillar_result: Dictionary = rivalry.request_structure(
		Tuning.PLAYER_REALM,
		Tuning.STRUCTURE_LUMEN_PILLAR,
		pillar_tile
	)
	check(bool(pillar_result.get("success", false)), "Lumen Pillar placement validates terrain, cost, road, and ownership", failures)
	var pillar: Dictionary = pillar_result.get("structure", {})
	check(
		String(pillar.get("realm_id", "")) == Tuning.PLAYER_REALM
		and rivalry.is_lumen_connected_at(Tuning.PLAYER_REALM, Vector2(pillar_tile)),
		"owned Lumen Pillar joins the connected Town Hall network",
		failures
	)
	rivalry.get_resources(Tuning.PLAYER_REALM)[Defs.RESOURCE_WYRD] = Tuning.LUMEN_NIGHTLY_UPKEEP
	rivalry._on_night_started()
	check(
		rivalry.get_resource(Tuning.PLAYER_REALM, Defs.RESOURCE_WYRD) == 0
		and bool(pillar.get("active", false)),
		"nightly Lumen upkeep consumes only the owning realm's Wyrd",
		failures
	)
	rivalry._on_night_started()
	check(not bool(pillar.get("active", true)), "Lumen deactivates when its realm cannot pay upkeep", failures)
	rivalry.add_resource(Tuning.PLAYER_REALM, Defs.RESOURCE_WYRD, 30)
	rivalry._on_night_started()
	check(bool(pillar.get("active", false)), "Lumen reactivates once upkeep can be paid", failures)

	rivalry.elapsed_seconds = 123.5
	var rivalry_saved_state: Dictionary = JSON.parse_string(JSON.stringify(simulation._serialize_state()))
	var restored_simulation = Simulation.new(70, 70, 999999, false)
	restored_simulation._restore_state(rivalry_saved_state)
	restored_simulation.central_inventory[Defs.RESOURCE_WOOD] = 777
	check(
		restored_simulation.rivalry.owns_road(Tuning.AI_REALM, ai_road)
		and restored_simulation.rivalry.get_structures(Tuning.PLAYER_REALM).size() == 1
		and is_equal_approx(restored_simulation.rivalry.elapsed_seconds, 123.5)
		and restored_simulation.rivalry.get_resource(Tuning.PLAYER_REALM, Defs.RESOURCE_WOOD) == 777,
		"save/load preserves rival roads, structures, timers, and the shared player ledger",
		failures
	)

	var player_sovereign: Dictionary = rivalry.get_sovereign(Tuning.PLAYER_REALM)
	var ai_sovereign: Dictionary = rivalry.get_sovereign(Tuning.AI_REALM)
	player_sovereign["position"] = Vector2(20, 20)
	ai_sovereign["position"] = Vector2(21, 20)
	for hit in range(6):
		player_sovereign["attack_cooldown"] = 0.0
		ai_sovereign["invulnerability"] = 0.0
		rivalry.request_attack(Tuning.PLAYER_REALM)
	check(not bool(ai_sovereign.get("alive", true)), "the stronger player Sovereign can defeat the rival Sovereign", failures)
	rivalry._update_sovereigns(Tuning.SOVEREIGN_RESPAWN_SECONDS + 0.1)
	check(
		bool(ai_sovereign.get("alive", false))
		and int(ai_sovereign.get("hp", 0)) == Tuning.SOVEREIGN_MAX_HP,
		"incapacitated Sovereign reliably respawns at its Town Hall",
		failures
	)
	var defeat_simulation = Simulation.new(70, 70, 424242, false, true)
	var defeat_rivalry = defeat_simulation.rivalry
	var doomed_sovereign: Dictionary = defeat_rivalry.get_sovereign(Tuning.PLAYER_REALM)
	doomed_sovereign["invulnerability"] = 0.0
	defeat_rivalry._damage_sovereign(Tuning.PLAYER_REALM, Tuning.PLAYER_SOVEREIGN_MAX_HP, Tuning.AI_REALM)
	check(
		not defeat_simulation.game_finished
		and bool(doomed_sovereign.get("alive", true))
		and int(doomed_sovereign.get("hp", 0)) == int(doomed_sovereign.get("max_hp", 0)),
		"the removed player Sovereign compatibility record cannot cause defeat",
		failures
	)

	var outpost := {
		"id": 9991,
		"realm_id": Tuning.PLAYER_REALM,
		"type": Tuning.STRUCTURE_CLAIMANT_OUTPOST,
		"position": simulation.shard_position + Vector2i(3, 0),
		"footprint": Vector2i(2, 2),
		"hp": 220,
		"max_hp": 220,
		"active": true,
		"connected": true,
		"damage_flash": 0.0
	}
	rivalry.structures.append(outpost)
	rivalry.realms[Tuning.PLAYER_REALM]["structures"].append(9991)
	rivalry.realms[Tuning.PLAYER_REALM]["claim"]["outpost_id"] = 9991
	rivalry.realms[Tuning.PLAYER_REALM]["claim"]["active"] = true
	rivalry._destroy_structure(9991)
	check(
		not bool(rivalry.realms[Tuning.PLAYER_REALM]["claim"].get("active", true))
		and int(rivalry.realms[Tuning.PLAYER_REALM]["claim"].get("outpost_id", -1)) == 0,
		"destroying the Claimant Outpost resets claim progress",
		failures
	)

	var player_match = Simulation.new(70, 70, 616161, false, true)
	var player_rivalry = player_match.rivalry
	_configure_ready_claim(player_match, player_rivalry, Tuning.PLAYER_REALM)
	var player_match_sovereign: Dictionary = player_rivalry.get_sovereign(Tuning.PLAYER_REALM)
	check(
		bool(player_rivalry.claim_requirements(Tuning.PLAYER_REALM).get("ready", false)),
		"settlement claim readiness no longer depends on a player Sovereign",
		failures
	)
	player_match_sovereign["position"] = Vector2(player_match.shard_position)
	check(
		bool(player_rivalry.request_begin_claim(Tuning.PLAYER_REALM).get("success", false)),
		"claim starts when Outpost, road, Lumen, Wyrd, and contest rules are satisfied",
		failures
	)
	player_rivalry._on_night_started()
	player_match_sovereign["position"] = Vector2(player_match.town_hall_position)
	player_rivalry._update_claims(4.0, true, 4.0, Simulation.NIGHT_LENGTH_SECONDS)
	var paused_claim: Dictionary = player_rivalry.get_claim_status(Tuning.PLAYER_REALM)
	check(
		String(paused_claim.get("status", "")).begins_with("SHARD BINDING"),
		"settlement Binding remains valid without hero positioning",
		failures
	)

	var player_victory_match = Simulation.new(70, 70, 717171, false, true)
	var player_victory_rivalry = player_victory_match.rivalry
	_configure_ready_claim(player_victory_match, player_victory_rivalry, Tuning.PLAYER_REALM)
	player_victory_rivalry.get_sovereign(Tuning.PLAYER_REALM)["position"] = Vector2(player_victory_match.shard_position)
	check(
		bool(player_victory_rivalry.request_begin_claim(Tuning.PLAYER_REALM).get("success", false)),
		"player can begin Binding",
		failures
	)
	player_victory_rivalry._update_claims(
		120.0,
		true,
		120.0,
		Simulation.NIGHT_LENGTH_SECONDS
	)
	check(
		player_victory_rivalry.match_state == Tuning.MATCH_PLAYER_VICTORY,
		"valid player Binding completes the run",
		failures
	)

	var ai_match = Simulation.new(70, 70, 515151, false, true)
	var ai_rivalry = ai_match.rivalry
	var phase_time := 0.0
	var is_night := false
	var ai_won := false
	var simulated_match_seconds := 0.0
	var strategic_step := 0.5
	var ai_start := Vector2(ai_rivalry.get_sovereign(Tuning.AI_REALM).get("position", Vector2.ZERO))
	var wyrd_before: int = ai_rivalry.get_resource(Tuning.AI_REALM, Defs.RESOURCE_WYRD)
	for _warmup in range(80):
		simulated_match_seconds += strategic_step
		phase_time += strategic_step
		if not is_night and phase_time >= Simulation.DAY_LENGTH_SECONDS:
			is_night = true
			phase_time = 0.0
		elif is_night and phase_time >= Simulation.NIGHT_LENGTH_SECONDS:
			is_night = false
			phase_time = 0.0
		ai_rivalry.advance(strategic_step, is_night, phase_time, Simulation.NIGHT_LENGTH_SECONDS)
	check(
		Vector2(ai_rivalry.get_sovereign(Tuning.AI_REALM).get("position", Vector2.ZERO)).distance_to(ai_start) > 3.0
		or ai_rivalry.get_resource(Tuning.AI_REALM, Defs.RESOURCE_WYRD) > wyrd_before,
		"rival Sovereign can leave the Town Hall entrance during 0.5s strategic ticks",
		failures
	)
	for _tick in range(5922):
		simulated_match_seconds += strategic_step
		phase_time += strategic_step
		if not is_night and phase_time >= Simulation.DAY_LENGTH_SECONDS:
			is_night = true
			phase_time = 0.0
		elif is_night and phase_time >= Simulation.NIGHT_LENGTH_SECONDS:
			is_night = false
			phase_time = 0.0
		ai_rivalry.advance(strategic_step, is_night, phase_time, Simulation.NIGHT_LENGTH_SECONDS)
		if ai_rivalry.match_state == Tuning.MATCH_AI_VICTORY:
			ai_won = true
			break
	if not ai_won:
		print("AI FINAL SNAPSHOT: %s" % str(ai_rivalry.get_debug_snapshot()))
		print("AI SOVEREIGN: %s" % str(ai_rivalry.get_sovereign(Tuning.AI_REALM)))
		var event_start: int = max(0, ai_rivalry.event_log.size() - 20)
		for event_index in range(event_start, ai_rivalry.event_log.size()):
			print("AI EVENT: %s" % String(ai_rivalry.event_log[event_index]))
	check(
		ai_won and simulated_match_seconds >= 2400.0 and simulated_match_seconds <= 3000.0,
		"deterministic rival AI cannot win before the 40-50 minute match window",
		failures
	)

	if failures.is_empty():
		print("RIVALRY_SMOKE PASS")
		quit(0)
	else:
		for failure in failures:
			print("FAIL: %s" % failure)
		print("RIVALRY_SMOKE FAIL (%d)" % failures.size())
		quit(1)


func _prepare_tile(simulation, tile: Vector2i, level_source: Vector2i) -> void:
	simulation._prepare_test_tile(tile, Defs.TILE_GRASS)
	simulation.height_map[tile.y][tile.x] = simulation.get_height(level_source)
	simulation._reveal_radius(tile, 0)


func _configure_ready_claim(simulation, rivalry, realm_id: String) -> void:
	var realm: Dictionary = rivalry.realms[realm_id]
	var entrance: Vector2i = realm["entrance"]
	var outpost_anchor: Vector2i = simulation.shard_position + (Vector2i(3, -1) if realm_id == Tuning.AI_REALM else Vector2i(-4, 0))
	var road_target: Vector2i = outpost_anchor + (Vector2i.RIGHT if realm_id == Tuning.AI_REALM else Vector2i.LEFT)
	var current := entrance
	while current.x != road_target.x:
		current += Vector2i(1 if road_target.x > current.x else -1, 0)
		realm["roads"][rivalry._key(current)] = true
	while current.y != road_target.y:
		current += Vector2i(0, 1 if road_target.y > current.y else -1)
		realm["roads"][rivalry._key(current)] = true
	var home_center: Vector2 = rivalry._home_center(realm_id)
	for fraction in [0.18, 0.36, 0.54, 0.72, 0.88]:
		var pillar_position: Vector2i = Vector2i(home_center.lerp(Vector2(simulation.shard_position), float(fraction)))
		var pillar: Dictionary = {
			"id": rivalry.next_structure_id,
			"realm_id": realm_id,
			"type": Tuning.STRUCTURE_LUMEN_PILLAR,
			"position": pillar_position,
			"footprint": Vector2i.ONE,
			"hp": 90,
			"max_hp": 90,
			"active": true,
			"connected": true,
			"damage_flash": 0.0
		}
		rivalry.next_structure_id += 1
		rivalry.structures.append(pillar)
		realm["structures"].append(pillar["id"])
	var outpost: Dictionary = {
		"id": rivalry.next_structure_id,
		"realm_id": realm_id,
		"type": Tuning.STRUCTURE_CLAIMANT_OUTPOST,
		"position": outpost_anchor,
		"footprint": Vector2i(2, 2),
		"hp": 220,
		"max_hp": 220,
		"active": true,
		"connected": true,
		"damage_flash": 0.0
	}
	rivalry.next_structure_id += 1
	rivalry.structures.append(outpost)
	realm["structures"].append(outpost["id"])
	realm["claim"]["outpost_id"] = outpost["id"]
	rivalry.get_resources(realm_id)[Defs.RESOURCE_WYRD] = 100
	if realm_id == Tuning.AI_REALM:
		var sovereign: Dictionary = rivalry.get_sovereign(realm_id)
		sovereign["position"] = Vector2(simulation.shard_position)


func check(condition: bool, label: String, failures: Array[String]) -> void:
	print("%s %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		failures.append(label)
