class_name ProductionDemoPlayer3D
extends RefCounted

## The Director: scripted settler AI for a 1-hour demo playthrough.
## Reads authoritative sim state and issues only public request_* commands.
## Build order a sensible player would use: roads, house, lumber, farm,
## then quarry / storehouse / bakery, watchtower and barracks before night,
## then scout, push roads and Lumen toward the Shard, contest rivals, Bind.

const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Tuning = preload("res://src/GodotClient/Scripts/one_shard_rivalry_tuning.gd")

const MAX_PENDING_ROADS := 2
const MAX_PENDING_SITES := 1
const SITE_RADIUS := 22
const ROAD_BURST := 2

var last_actions: Array[String] = []
var last_failures: Array[String] = []
var orders: Array[Dictionary] = []
var scouted := false
var last_scout_day := 0
var last_idle_reason := ""
var _waypoint_retry_at := 0.0


func think(sim) -> Dictionary:
	last_actions.clear()
	last_failures.clear()
	last_idle_reason = ""
	if sim == null or bool(sim.game_finished):
		last_idle_reason = "run finished"
		return _result()
	_defend(sim)
	_defend_night(sim)
	_pursue_economy(sim)
	_pursue_crater_war(sim)
	_try_wyrd_choice(sim)
	_try_midgame_choice(sim)
	_try_seal_choice(sim)
	_try_channel(sim)
	_scout(sim)
	_expand_toward_shard(sim)
	_contest_rivals(sim)
	_try_seal(sim)
	if last_actions.is_empty() and last_idle_reason == "":
		last_idle_reason = "waiting on workers, stock, or construction"
	return _result()


## Beta: frame-spread think. The harness calls think_step() once per frame;
## each call runs one phase so no single frame pays the whole decision pass.
const THINK_PHASES := 13
var think_phase := 0
var _phase_skip: Dictionary = {}

func think_step(sim) -> bool:
	if think_phase == 0:
		last_actions.clear()
		last_failures.clear()
		last_idle_reason = ""
	if sim == null or bool(sim.game_finished):
		think_phase = 0
		return true
	var phase_t0 := Time.get_ticks_usec()
	var actions_before := last_actions.size()
	var skip_left := int(_phase_skip.get(think_phase, 0))
	if skip_left > 0 and think_phase not in [0, 1, 12]:
		_phase_skip[think_phase] = skip_left - 1
		think_phase += 1
		if think_phase >= THINK_PHASES:
			think_phase = 0
			return true
		return false
	match think_phase:
		0: _defend(sim)
		1: _defend_night(sim)
		2: _pursue_economy(sim)
		3: _pursue_crater_war(sim)
		4: _try_wyrd_choice(sim)
		5: _try_midgame_choice(sim)
		6: _try_seal_choice(sim)
		7: _try_channel(sim)
		8: _scout(sim)
		9: _expand_toward_shard(sim)
		10: _contest_rivals(sim)
		11: _try_seal(sim)
		12:
			if last_actions.is_empty() and last_idle_reason == "":
				last_idle_reason = "waiting on workers, stock, or construction"
	# Harness budget: an expensive phase that changed nothing waits two
	# think cycles (~6 s game time) before scanning again.
	if Time.get_ticks_usec() - phase_t0 > 25000 and last_actions.size() == actions_before:
		_phase_skip[think_phase] = 2
	think_phase += 1
	if think_phase >= THINK_PHASES:
		think_phase = 0
		return true
	return false


func _result() -> Dictionary:
	return {
		"actions": last_actions.duplicate(),
		"failures": last_failures.duplicate(),
		"idle": last_idle_reason,
		"orders": orders.size()
	}


func _pursue_economy(sim) -> void:
	if _pending_buildings(sim) >= MAX_PENDING_SITES:
		last_idle_reason = "construction queue full"
		return
	# House first so the opening haul is not stolen by early roads.
	if _count(sim, Defs.BUILDING_HOUSE) < 1:
		_try_build(sim, Defs.BUILDING_HOUSE, sim.town_hall_position + Vector2i(5, 4))
		return
	if _has_completed(sim, Defs.BUILDING_LUMBER_CAMP):
		_extend_roads(sim, _early_road_target(sim), 1)
	if _has_completed(sim, Defs.BUILDING_STOREHOUSE) and _count(sim, Defs.BUILDING_HOUSE) < 2 and _stock(sim, Defs.RESOURCE_WOOD) >= 4:
		_try_build(sim, Defs.BUILDING_HOUSE, sim.town_hall_position + Vector2i(3, 6))
		return
	if _count(sim, Defs.BUILDING_LUMBER_CAMP) < 1:
		_try_build(sim, Defs.BUILDING_LUMBER_CAMP, _aim_resource(sim, Defs.TILE_TREE, Vector2i(9, 6)))
		return
	if _count(sim, Defs.BUILDING_FARM) < 1:
		_try_build(sim, Defs.BUILDING_FARM, _aim_food(sim, Vector2i(7, 9)))
		return
	if _count(sim, Defs.BUILDING_QUARRY) < 1:
		if _unlocked(sim, Defs.BUILDING_QUARRY):
			_try_quarry(sim)
		else:
			last_idle_reason = "waiting for Lumber Camp so Quarry unlocks"
		return
	if _unlocked(sim, Defs.BUILDING_SAWMILL) and _count(sim, Defs.BUILDING_SAWMILL) < 1:
		_try_build(sim, Defs.BUILDING_SAWMILL, sim.town_hall_position + Vector2i(10, 7))
		return
	if _unlocked(sim, Defs.BUILDING_STOREHOUSE) and _count(sim, Defs.BUILDING_STOREHOUSE) < 1:
		if _try_build(sim, Defs.BUILDING_STOREHOUSE, sim.town_hall_position + Vector2i(4, 10)):
			return
		last_idle_reason = "waiting on planks/stone for the Storehouse"
		return
	if _unlocked(sim, Defs.BUILDING_BAKERY) and _count(sim, Defs.BUILDING_BAKERY) < 1 and _stock(sim, Defs.RESOURCE_WHEAT) >= 4:
		_try_build(sim, Defs.BUILDING_BAKERY, sim.town_hall_position + Vector2i(8, 11))
		return
	if int(sim.population_current) >= int(sim.housing_capacity) and _count(sim, Defs.BUILDING_HOUSE) < 4:
		_try_build(sim, Defs.BUILDING_HOUSE, sim.town_hall_position + Vector2i(3, 7))
		return
	if _count(sim, Defs.BUILDING_LUMBER_CAMP) < 2 and _stock(sim, Defs.RESOURCE_WOOD) < 12 and int(sim.day_count) >= 2:
		_try_build(sim, Defs.BUILDING_LUMBER_CAMP, _aim_resource(sim, Defs.TILE_TREE, Vector2i(11, 3)))
		return
	if _count(sim, Defs.BUILDING_FARM) < 2 and _food(sim) < 10 and int(sim.day_count) >= 2:
		_try_build(sim, Defs.BUILDING_FARM, sim.town_hall_position + Vector2i(2, 11))


func _defend_night(sim) -> void:
	if not _unlocked(sim, Defs.BUILDING_WATCHTOWER):
		return
	if _count(sim, Defs.BUILDING_WATCHTOWER) < 1:
		var toward: Vector2i = (sim.shard_position - sim.town_hall_position).sign()
		_try_build(sim, Defs.BUILDING_WATCHTOWER, sim.town_hall_position + toward + Vector2i(1, 1))
		return
	if not _has_completed(sim, Defs.BUILDING_SAWMILL) and _count(sim, Defs.BUILDING_SAWMILL) < 1:
		return
	if not _has_completed(sim, Defs.BUILDING_STOREHOUSE) and _count(sim, Defs.BUILDING_STOREHOUSE) < 1:
		return
	if _unlocked(sim, Defs.BUILDING_BARRACKS) and _count(sim, Defs.BUILDING_BARRACKS) < 1:
		_try_build(sim, Defs.BUILDING_BARRACKS, sim.town_hall_position + Vector2i(6, 2))


func _defend(sim) -> void:
	if bool(sim.is_night) or bool(sim.raid_active):
		# Keep a road spur free so night repairs / towers stay connected.
		_extend_roads(sim, sim.town_hall_position + Vector2i(2, 2), 1)


func _scout(sim) -> void:
	if scouted and int(sim.day_count) <= last_scout_day:
		return
	if scouted and int(sim.day_count) >= 3:
		scouted = false
	if int(sim.soldiers_total) < 1:
		return
	if _food(sim) < 4:
		return
	var scout_id := _free_patrol(sim)
	if scout_id <= 0:
		return
	var target := _scout_target(sim)
	var result: Dictionary = sim.request_scout_direction(scout_id, target)
	if bool(result.get("success", false)):
		scouted = true
		last_scout_day = int(sim.day_count)
		_note(sim, "SCOUT", target, String(result.get("message", "")))
	else:
		last_failures.append("scout: %s" % String(result.get("message", "")))


func _expand_toward_shard(sim) -> void:
	if not _starter_ready(sim):
		return
	if not _has_completed(sim, Defs.BUILDING_BARRACKS):
		# The Director: keep carriers on the keep until the Barracks is up.
		# Frontier roads used to steal every haul and starve deliveries.
		return
	_extend_roads(sim, _frontier_target(sim), ROAD_BURST)
	if not _unlocked(sim, Defs.BUILDING_LUMEN_PILLAR):
		return
	var requirements: Dictionary = {}
	if sim.rivalry != null:
		requirements = sim.rivalry.claim_requirements("player")
	if not bool(requirements.get("lumen", false)):
		_place_forward_structure(sim, Defs.BUILDING_LUMEN_PILLAR)
	# The Director: a corridor Outpost unlocks full harvest. The frontier
	# stake is already on the vent; do not spam the distant Shard.
	if _stock(sim, Defs.RESOURCE_WOOD) >= 18 and sim.crater_war != null and not sim.crater_war.route_secured():
		_try_waypoint_outpost(sim)


func _pursue_crater_war(sim) -> void:
	if sim.crater_war == null:
		return
	if sim.crater_war.primary_fissure.x >= 0 and not sim.crater_war.geologist_surveyed:
		var survey: Dictionary = sim.request_survey()
		if bool(survey.get("success", false)):
			_note(sim, "SURVEY", sim.crater_war.primary_fissure, String(survey.get("message", "")))
	if sim.crater_war.geologist_surveyed:
		_extend_roads(sim, sim.crater_war.primary_fissure, 2)
	if sim.crater_war.geologist_surveyed and _unlocked(sim, Defs.BUILDING_WYRD_HARVESTER) and _count(sim, Defs.BUILDING_WYRD_HARVESTER) < 1:
		if _try_build(sim, Defs.BUILDING_WYRD_HARVESTER, sim.crater_war.primary_fissure):
			return
	# Corridor Outpost can start while the harvester team is still walking.
	if not sim.crater_war.route_secured() and _count(sim, Defs.BUILDING_WYRD_HARVESTER) >= 1:
		if _pending_buildings(sim) <= MAX_PENDING_SITES:
			if _try_waypoint_outpost(sim):
				return
	var need_refiner := _unlocked(sim, Defs.BUILDING_WYRD_REFINER) and _count(sim, Defs.BUILDING_WYRD_REFINER) < 1
	var late_refiner := need_refiner and float(sim.elapsed_seconds) >= 25.0 * 60.0 and _count(sim, Defs.BUILDING_WYRD_HARVESTER) >= 1
	if late_refiner:
		if _try_build(sim, Defs.BUILDING_WYRD_REFINER, sim.town_hall_position + Vector2i(9, 4)):
			return
	if _pending_buildings(sim) >= MAX_PENDING_SITES:
		return
	if need_refiner and _has_completed(sim, Defs.BUILDING_WYRD_HARVESTER):
		if _try_build(sim, Defs.BUILDING_WYRD_REFINER, sim.town_hall_position + Vector2i(9, 4)):
			return
	if not _has_completed(sim, Defs.BUILDING_WYRD_HARVESTER):
		return
	if not sim.crater_war.route_secured():
		if _try_waypoint_outpost(sim):
			return
	if _count(sim, Defs.BUILDING_OUTPOST) < 2:
		if _try_frontier_outpost(sim):
			return
	if sim.crater_war.harvester_unlumened() and _unlocked(sim, Defs.BUILDING_LUMEN_PILLAR) and _stock(sim, Defs.RESOURCE_WYRD) >= 3:
		if _try_build(sim, Defs.BUILDING_LUMEN_PILLAR, _harvester_tile(sim)):
			return
	if _unlocked(sim, Defs.BUILDING_WATCHTOWER) and _count(sim, Defs.BUILDING_WATCHTOWER) < 2:
		if _try_build(sim, Defs.BUILDING_WATCHTOWER, _harvester_tile(sim)):
			return
	var wall_target := 5 if String(sim.crater_war.midgame_choice) == "fortify" else 4
	if _unlocked(sim, Defs.BUILDING_WALL) and _count(sim, Defs.BUILDING_WALL) < wall_target:
		if _try_build(sim, Defs.BUILDING_WALL, _harvester_tile(sim)):
			return
	var house_target := 4 if String(sim.crater_war.midgame_choice) == "shelter" else 3
	if _count(sim, Defs.BUILDING_HOUSE) < house_target and _stock(sim, Defs.RESOURCE_WOOD) >= 4:
		_try_build(sim, Defs.BUILDING_HOUSE, sim.town_hall_position + Vector2i(2, 8))
		return
	if _count(sim, Defs.BUILDING_FARM) < 3 and _stock(sim, Defs.RESOURCE_WOOD) >= 4:
		_try_build(sim, Defs.BUILDING_FARM, sim.town_hall_position + Vector2i(1, 10))


func _contest_rivals(sim) -> void:
	if sim.rivalry == null:
		return
	if sim.crater_war != null and bool(sim.demo_rival_revealed) and String(sim.crater_war.rival_resolution) == "" and int(sim.soldiers_total) < 1 and float(sim.elapsed_seconds) >= 1200.0 and _stock(sim, Defs.RESOURCE_WOOD) >= 8:
		var deal: Dictionary = sim.request_passage_deal()
		if bool(deal.get("success", false)):
			_note(sim, "PASSAGE", sim.crater_war.primary_fissure, String(deal.get("message", "")))
			return
	if int(sim.soldiers_total) < 1:
		return
	for target in sim.rivalry.get_structures("rival"):
		if String(target.get("type", "")) != Defs.BUILDING_OUTPOST:
			continue
		if int(target.get("hp", 0)) <= 0:
			continue
		var already := false
		for guard in sim.workers:
			already = already or int(guard.get("assault_target_id", 0)) == int(target.get("id", 0))
		if already:
			continue
		var result: Dictionary = sim.request_outpost_assault(int(target.get("id", 0)))
		if bool(result.get("success", false)):
			_note(sim, "ASSAULT", Vector2i(target.get("position", Vector2i.ZERO)), String(result.get("message", "")))
		elif sim.crater_war != null and _stock(sim, Defs.RESOURCE_WOOD) >= 8:
			var fallback: Dictionary = sim.request_passage_deal()
			if bool(fallback.get("success", false)):
				_note(sim, "PASSAGE", sim.crater_war.primary_fissure, String(fallback.get("message", "")))


func _try_wyrd_choice(sim) -> void:
	if sim.crater_war == null or not sim.crater_war.choice_ready():
		return
	var path: String = sim.crater_war.bot_path_for_seed(int(sim.rng_seed))
	var result: Dictionary = sim.request_wyrd_choice(path)
	if bool(result.get("success", false)):
		_note(sim, "CHOICE", sim.crater_war.primary_fissure, String(result.get("message", "")))
	else:
		last_failures.append("choice: %s" % String(result.get("message", "")))


func _try_midgame_choice(sim) -> void:
	if sim.crater_war == null or not sim.crater_war.midgame_choice_ready():
		return
	var path: String = sim.crater_war.bot_midgame_path_for_seed(int(sim.rng_seed))
	var result: Dictionary = sim.request_midgame_choice(path)
	if bool(result.get("success", false)):
		_note(sim, "CARAVAN", sim.crater_war.primary_fissure, String(result.get("message", "")))
	else:
		last_failures.append("caravan: %s" % String(result.get("message", "")))


func _try_seal_choice(sim) -> void:
	if sim.crater_war == null or not sim.crater_war.seal_choice_ready():
		return
	var path: String = sim.crater_war.bot_seal_path_for_seed(int(sim.rng_seed))
	var result: Dictionary = sim.request_seal_choice(path)
	if bool(result.get("success", false)):
		_note(sim, "SEALCHOICE", sim.crater_war.primary_fissure, String(result.get("message", "")))
	else:
		last_failures.append("seal choice: %s" % String(result.get("message", "")))


func _try_channel(sim) -> void:
	if sim.crater_war == null or not sim.crater_war.ritual_active:
		return
	if sim.crater_war.channel_uses >= 1:
		return
	if not sim.crater_war.channel_ready():
		return
	if sim.crater_war.ritual_started_at >= 0.0 and float(sim.elapsed_seconds) < sim.crater_war.ritual_started_at + 8.0:
		return
	var result: Dictionary = sim.request_channel_wyrd()
	if bool(result.get("success", false)):
		_note(sim, "CHANNEL", sim.crater_war.last_channel_tile, String(result.get("message", "")))
	else:
		last_failures.append("channel: %s" % String(result.get("message", "")))


func _try_seal(sim) -> void:
	if sim.crater_war != null and sim.crater_war.can_begin():
		# Hold so the fastest path (overcharge, ~100 s) still closes at 42:00.
		if float(sim.elapsed_seconds) + 100.0 < 42.0 * 60.0:
			last_idle_reason = "holding the Seal until the hour can close"
			return
		var crater_seal: Dictionary = sim.request_begin_seal()
		if bool(crater_seal.get("success", false)):
			_note(sim, "SEAL", sim.crater_war.primary_fissure, String(crater_seal.get("message", "")))
		else:
			last_failures.append("seal: %s" % String(crater_seal.get("message", "")))
		return
	# Later-act hook: do not start Shard Binding this hour.


func _try_waypoint_outpost(sim) -> bool:
	if not _can_afford(sim, Defs.BUILDING_OUTPOST):
		last_idle_reason = "cannot afford the corridor Outpost"
		return false
	var marker := Vector2i(-1, -1)
	if sim.crater_war != null:
		marker = sim.crater_war.waypoint_tile()
	if marker.x < 0:
		marker = _midpoint(sim.town_hall_position, _frontier_target(sim))
	var hall: Vector2i = sim.town_hall_position
	# Gate harness perf: each aim runs _best_site (radius 22) twice, so the old
	# 121-aim ring cost ~6.5 s per think() once the Lumen Pillar stood and froze
	# the whole frame. _best_site already covers the ring; probe the marker only
	# and back off 30 s between failed attempts.
	if float(sim.elapsed_seconds) < _waypoint_retry_at:
		return false
	var aims: Array[Vector2i] = [marker]
	for aim_value in aims:
		var aim: Vector2i = aim_value
		if absi(aim.x - hall.x) + absi(aim.y - hall.y) < 8:
			continue
		if _try_build(sim, Defs.BUILDING_OUTPOST, aim):
			return true
	_waypoint_retry_at = float(sim.elapsed_seconds) + 30.0
	_extend_roads(sim, marker, 2)
	return false


func _harvester_tile(sim) -> Vector2i:
	for building in sim.get_buildings():
		if bool(building.get("construction", false)):
			continue
		if String(building.get("type", "")) == Defs.BUILDING_WYRD_HARVESTER:
			return Vector2i(building.get("position", Vector2i.ZERO))
	if sim.crater_war != null and sim.crater_war.primary_fissure.x >= 0:
		return sim.crater_war.primary_fissure
	return _frontier_target(sim)


func _midpoint(a: Vector2i, b: Vector2i) -> Vector2i:
	return Vector2i(int(round((a.x + b.x) * 0.5)), int(round((a.y + b.y) * 0.5)))


func _try_frontier_outpost(sim) -> bool:
	var hall: Vector2i = sim.town_hall_position
	var marker := _frontier_target(sim)
	if sim.crater_war != null and sim.crater_war.primary_fissure.x >= 0:
		marker = sim.crater_war.primary_fissure
	var aims: Array[Vector2i] = [marker]
	for radius in range(1, 5):
		for ox in range(-radius, radius + 1):
			aims.append(marker + Vector2i(ox, -radius))
			aims.append(marker + Vector2i(ox, radius))
			aims.append(marker + Vector2i(-radius, ox))
			aims.append(marker + Vector2i(radius, ox))
	var _aim_t0 := Time.get_ticks_msec()
	for aim_value in aims:
		var aim: Vector2i = aim_value
		if absi(aim.x - hall.x) + absi(aim.y - hall.y) < 16:
			continue
		# Gate-only: cap the outpost aim scan at 150 ms per think (was up to 6 s).
		if _gate_quarry_backoff and Time.get_ticks_msec() - _aim_t0 > 150:
			break
		if _try_build(sim, Defs.BUILDING_OUTPOST, aim):
			return true
	_waypoint_retry_at = float(sim.elapsed_seconds) + 30.0
	_extend_roads(sim, marker, 2)
	return false


func _try_build(sim, building_type: String, aim: Vector2i) -> bool:
	if not _can_afford(sim, building_type):
		last_idle_reason = "cannot afford %s" % Defs.building_name(building_type)
		return false
	if _count_pending(sim, building_type) > 0:
		return false
	# R29 harness: a failed site search scans ~2000 tiles twice (~600 ms);
	# r28a repeated it every 3 s. Gate-only: back off that type for 20 s.
	if _gate_quarry_backoff and Time.get_ticks_msec() < int(_site_fail_until.get(building_type, 0)):
		last_idle_reason = "no site for %s yet (retrying)" % Defs.building_name(building_type)
		return false
	var site := _best_site(sim, building_type, aim)
	if site.x < 0:
		_extend_roads(sim, aim, 2)
		site = _best_site(sim, building_type, aim)
	if site.x < 0:
		last_failures.append("%s: no site near %s" % [building_type, str(aim)])
		_site_fail_until[building_type] = Time.get_ticks_msec() + 20000
		return false
	var result: Dictionary = sim.request_build(building_type, site)
	if bool(result.get("success", false)):
		_note(sim, building_type, site, String(result.get("message", "")))
		return true
	last_failures.append("%s@%s: %s" % [building_type, str(site), String(result.get("message", ""))])
	return false


## Gate-only (measurement harness): after a failed Quarry search, back off 20 s
## and scan only the 12 nearest rocks, so the bot's 360-540 ms search does not
## pollute frame metrics. Off unless `--gate-bot-quarry-backoff`.
var _gate_quarry_backoff := "--gate-bot-quarry-backoff" in OS.get_cmdline_user_args()
var _quarry_retry_at_ms := 0
var _site_fail_until := {}


func _try_quarry(sim) -> bool:
	if not _can_afford(sim, Defs.BUILDING_QUARRY):
		last_idle_reason = "cannot afford Quarry"
		return false
	if _gate_quarry_backoff and Time.get_ticks_msec() < _quarry_retry_at_ms:
		last_idle_reason = "quarry backoff (gate)"
		return false
	var rocks := _revealed_kind(sim, sim.town_hall_position, Defs.TILE_ROCK, 32)
	var preferred: Variant = sim.founding_site.get("quarry_stone", Vector2i(-1, -1))
	if preferred is Vector2i and preferred.x >= 0:
		rocks.erase(preferred)
		rocks.insert(0, preferred)
	if _gate_quarry_backoff and rocks.size() > 12:
		rocks.resize(12)
	if rocks.is_empty():
		last_failures.append("QUARRY: no revealed rock")
		_extend_roads(sim, _aim_resource(sim, Defs.TILE_ROCK, Vector2i(8, 2)), 2)
		return false
	var footprint: Vector2i = Defs.building_footprint(Defs.BUILDING_QUARRY)
	var road_aim := Vector2i(rocks[0])
	var road_aim_score := 100000
	var reasons: Dictionary = {}
	for rock_value in rocks:
		var rock: Vector2i = rock_value
		for oy in range(-(footprint.y - 1), 1):
			for ox in range(-(footprint.x - 1), 1):
				var origin := rock + Vector2i(ox, oy)
				var validation: Dictionary = sim.validate_placement(Defs.BUILDING_QUARRY, origin)
				if bool(validation.get("success", false)):
					var result: Dictionary = sim.request_build(Defs.BUILDING_QUARRY, origin)
					if bool(result.get("success", false)):
						_note(sim, Defs.BUILDING_QUARRY, origin, String(result.get("message", "")))
						return true
				else:
					var reason := String(validation.get("reason", String(validation.get("message", "unknown"))))
					reasons[reason] = int(reasons.get(reason, 0)) + 1
					if reason == "RoadConnection" or String(validation.get("message", "")).contains("road"):
						var score := absi(rock.x - sim.town_hall_position.x) + absi(rock.y - sim.town_hall_position.y)
						if score < road_aim_score:
							road_aim = rock
							road_aim_score = score
	_extend_roads(sim, road_aim, 2)
	last_failures.append("QUARRY: %d rocks visible, none placeable yet %s" % [rocks.size(), str(reasons)])
	if _gate_quarry_backoff:
		_quarry_retry_at_ms = Time.get_ticks_msec() + 20000
	print("DEMO_AI quarry_fail rocks=%d reasons=%s aim=%s" % [rocks.size(), str(reasons), str(road_aim)])
	return false


func _place_forward_structure(sim, building_type: String) -> bool:
	if not _can_afford(sim, building_type):
		return false
	if _count(sim, building_type) >= (2 if building_type == Defs.BUILDING_OUTPOST else 4):
		return false
	if building_type == Defs.BUILDING_OUTPOST:
		if _try_frontier_outpost(sim):
			return true
		return false
	var site := _forward_site(sim, building_type)
	if site.x < 0:
		return false
	var result: Dictionary = sim.request_build(building_type, site)
	if bool(result.get("success", false)):
		_note(sim, building_type, site, String(result.get("message", "")))
		return true
	last_failures.append("%s forward: %s" % [building_type, String(result.get("message", ""))])
	return false


func _forward_site(sim, building_type: String) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_score := 100000.0
	var lumen_sources: Array = []
	if sim.rivalry != null:
		lumen_sources = sim.rivalry.get_lumen_sources("player")
	var wyrd_sites: Array = []
	if sim.rivalry != null:
		wyrd_sites = sim.rivalry.get_wyrd_sites()
	var harvest_outposts := 0
	if sim.rivalry != null:
		for structure in sim.rivalry.get_structures("player"):
			if String(structure.get("type", "")) == Defs.BUILDING_OUTPOST and sim.outpost_has_wyrd_node(structure):
				harvest_outposts += 1
	var closest_lumen := 100000.0
	for source in lumen_sources:
		closest_lumen = minf(closest_lumen, Vector2(source.center).distance_to(Vector2(sim.shard_position)))
	var examined := 0
	for key_value in sim.revealed_tiles.keys():
		examined += 1
		if examined > 2400:
			break
		var tile: Vector2i = sim._tile_from_key(String(key_value))
		var to_shard := Vector2(tile).distance_to(Vector2(sim.shard_position))
		var useful := false
		if building_type == Defs.BUILDING_OUTPOST:
			var center := Vector2(tile) + Vector2(0.5, 0.5)
			var marker := _frontier_target(sim)
			if marker != sim.shard_position and center.distance_to(Vector2(marker)) <= 3.0:
				useful = true
			for node in wyrd_sites:
				if harvest_outposts < 2 and center.distance_to(Vector2(node.position)) <= sim.WYRD_OUTPOST_HARVEST_RADIUS:
					useful = true
			if center.distance_to(Vector2(sim.shard_position)) <= Tuning.SHARD_BUILD_RADIUS:
				useful = true
		else:
			useful = to_shard < closest_lumen - 1.0
			for source in lumen_sources:
				if Vector2(tile).distance_to(Vector2(source.center)) < 4.0:
					useful = false
		if not useful:
			continue
		if not bool(sim.validate_placement(building_type, tile).get("success", false)):
			continue
		if to_shard < best_score:
			best = tile
			best_score = to_shard
	return best


func _extend_roads(sim, target: Vector2i, count: int) -> void:
	for _i in count:
		if _pending_roads(sim) >= MAX_PENDING_ROADS:
			return
		var tile := _best_road_step(sim, target)
		if tile.x < 0:
			return
		var result: Dictionary = sim.request_build(Defs.BUILDING_ROAD, tile)
		if bool(result.get("success", false)):
			_note(sim, Defs.BUILDING_ROAD, tile, String(result.get("message", "")))
		else:
			last_failures.append("ROAD@%s: %s" % [str(tile), String(result.get("message", ""))])
			return


func _best_road_step(sim, target: Vector2i) -> Vector2i:
	# R29 harness: r28a spent ~600 ms every 3 s here validating every road
	# neighbour. Collect candidates, sort by distance, validate until the
	# first legal one (same choice as before: the nearest legal tile).
	var candidates: Array = []
	var seen := {}
	for building_value in sim.get_buildings():
		var building: Dictionary = building_value
		var kind := String(building.get("type", ""))
		var planned := String(building.get("planned_type", ""))
		if kind != Defs.BUILDING_ROAD and planned != Defs.BUILDING_ROAD:
			continue
		var origin: Vector2i = building.get("position", Vector2i.ZERO)
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var tile: Vector2i = origin + direction
			if seen.has(tile) or not sim.is_inside_map(tile):
				continue
			seen[tile] = true
			candidates.append([absi(tile.x - target.x) + absi(tile.y - target.y), tile])
	candidates.sort_custom(func(x, y) -> bool: return int(x[0]) < int(y[0]))
	for c in candidates:
		if bool(sim.validate_placement(Defs.BUILDING_ROAD, c[1]).get("success", false)):
			return c[1]
	return Vector2i(-1, -1)


func _best_site(sim, building_type: String, target: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_score := 100000
	for radius in range(0, SITE_RADIUS + 1):
		for ox in range(-radius, radius + 1):
			for oy in range(-radius, radius + 1):
				if maxi(absi(ox), absi(oy)) != radius:
					continue
				var tile := target + Vector2i(ox, oy)
				if not sim.is_inside_map(tile):
					continue
				var validation: Dictionary = sim.validate_placement(building_type, tile)
				if not bool(validation.get("success", false)):
					continue
				var score := absi(tile.x - target.x) + absi(tile.y - target.y)
				if building_type != Defs.BUILDING_QUARRY and String(validation.get("message", "")).contains("CLEARING"):
					score += 8
				if score < best_score:
					best = tile
					best_score = score
		if best.x >= 0:
			return best
	return best


func _early_road_target(sim) -> Vector2i:
	if _count(sim, Defs.BUILDING_LUMBER_CAMP) < 1:
		return _aim_resource(sim, Defs.TILE_TREE, Vector2i(9, 6))
	if _count(sim, Defs.BUILDING_FARM) < 1:
		return _aim_food(sim, Vector2i(7, 9))
	if _count(sim, Defs.BUILDING_QUARRY) < 1:
		var preferred: Variant = sim.founding_site.get("quarry_stone", Vector2i(-1, -1))
		if preferred is Vector2i and preferred.x >= 0:
			return preferred
		var rock := _nearest_kind(sim, sim.town_hall_position, Defs.TILE_ROCK, 22)
		if rock.x >= 0:
			return rock
	return _frontier_target(sim)


func _frontier_target(sim) -> Vector2i:
	if sim.crater_war != null and sim.crater_war.primary_fissure.x >= 0:
		return sim.crater_war.primary_fissure
	var marker: Variant = sim.founding_site.get("frontier_marker", Vector2i(-1, -1))
	if marker is Vector2i and marker.x >= 0:
		return marker
	return sim.shard_position


func _aim_resource(sim, kind: String, fallback_offset: Vector2i) -> Vector2i:
	var found := _nearest_kind(sim, sim.town_hall_position, kind, 20)
	if found.x >= 0:
		return found
	return sim.town_hall_position + fallback_offset


func _aim_food(sim, fallback_offset: Vector2i) -> Vector2i:
	for food in sim.founding_site.get("food_tiles", []):
		return Vector2i(food)
	return sim.town_hall_position + fallback_offset


func _nearest_kind(sim, origin: Vector2i, kind: String, max_dist: int) -> Vector2i:
	var found := _revealed_kind(sim, origin, kind, max_dist)
	if found.is_empty():
		return Vector2i(-1, -1)
	return found[0]


func _revealed_kind(sim, origin: Vector2i, kind: String, max_dist: int) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for y in range(maxi(0, origin.y - max_dist), mini(sim.map_size.y, origin.y + max_dist + 1)):
		for x in range(maxi(0, origin.x - max_dist), mini(sim.map_size.x, origin.x + max_dist + 1)):
			var tile := Vector2i(x, y)
			if String(sim.get_tile(tile)) != kind:
				continue
			if not sim.is_revealed(tile):
				continue
			found.append(tile)
	found.sort_custom(func(a, b): return absi(a.x - origin.x) + absi(a.y - origin.y) < absi(b.x - origin.x) + absi(b.y - origin.y))
	return found


func _scout_target(sim) -> Vector2i:
	var home: Vector2i = sim.town_hall_position
	if not sim.rival_seats.is_empty():
		var nearest: Vector2i = sim.rival_seats[0]
		var best := 100000
		for seat_value in sim.rival_seats:
			var seat := Vector2i(seat_value)
			var d := absi(seat.x - home.x) + absi(seat.y - home.y)
			if d < best:
				best = d
				nearest = seat
		var toward := (nearest - home)
		if toward != Vector2i.ZERO:
			return home + toward.sign() * 12
	return home + (sim.shard_position - home).sign() * 12


func _free_patrol(sim) -> int:
	for worker in sim.workers:
		if not sim.is_patrol_scout(worker):
			continue
		if worker.has("scout_mission"):
			continue
		if int(worker.get("assault_target_id", 0)) > 0:
			continue
		return int(worker.get("id", 0))
	return 0


func _unlocked(sim, building_type: String) -> bool:
	var has_lumber := _has_completed(sim, Defs.BUILDING_LUMBER_CAMP)
	var has_farm := _has_completed(sim, Defs.BUILDING_FARM)
	var has_house := _has_completed(sim, Defs.BUILDING_HOUSE)
	var has_tower := _has_completed(sim, Defs.BUILDING_WATCHTOWER)
	var wheat := _stock(sim, Defs.RESOURCE_WHEAT)
	match building_type:
		Defs.BUILDING_ROAD, Defs.BUILDING_HOUSE, Defs.BUILDING_LUMBER_CAMP, Defs.BUILDING_FARM:
			return true
		Defs.BUILDING_QUARRY, Defs.BUILDING_SAWMILL:
			return has_lumber or int(sim.day_count) >= 2
		Defs.BUILDING_BAKERY:
			return has_farm or wheat >= 4
		Defs.BUILDING_STOREHOUSE:
			return has_house
		Defs.BUILDING_WATCHTOWER, Defs.BUILDING_WALL, Defs.BUILDING_BARRACKS:
			return sim.is_military_unlocked() or has_tower
		Defs.BUILDING_LUMEN_PILLAR, Defs.BUILDING_OUTPOST:
			return has_tower or (has_lumber and has_house and int(sim.day_count) >= 2)
		Defs.BUILDING_WYRD_HARVESTER, Defs.BUILDING_WYRD_REFINER:
			return sim.crater_war != null and bool(sim.crater_war.geologist_surveyed)
		_:
			return true


func _can_afford(sim, building_type: String) -> bool:
	var cost: Dictionary = Defs.building_cost(building_type)
	for resource_type in cost.keys():
		if int(sim.get_available_resource(resource_type)) < int(cost[resource_type]):
			return false
	return true


func _count(sim, building_type: String) -> int:
	var total := 0
	for building in sim.get_buildings():
		if bool(building.get("construction", false)):
			if String(building.get("planned_type", "")) == building_type:
				total += 1
		elif String(building.get("type", "")) == building_type:
			total += 1
	if sim.rivalry != null and building_type in [Defs.BUILDING_LUMEN_PILLAR, Defs.BUILDING_OUTPOST]:
		for structure in sim.rivalry.get_structures("player"):
			var kind := String(structure.get("type", ""))
			if kind == building_type or (building_type == Defs.BUILDING_OUTPOST and kind == Tuning.STRUCTURE_CLAIMANT_OUTPOST):
				total += 1
	return total


func _count_pending(sim, building_type: String) -> int:
	var total := 0
	for building in sim.get_buildings():
		if bool(building.get("construction", false)) and String(building.get("planned_type", "")) == building_type:
			total += 1
	return total


func _pending_sites(sim) -> int:
	return _pending_buildings(sim) + _pending_roads(sim)


func _pending_buildings(sim) -> int:
	var total := 0
	for building in sim.get_buildings():
		if not bool(building.get("construction", false)):
			continue
		if String(building.get("planned_type", "")) == Defs.BUILDING_ROAD:
			continue
		total += 1
	return total


func _pending_roads(sim) -> int:
	return _count_pending(sim, Defs.BUILDING_ROAD)


func _has_completed(sim, building_type: String) -> bool:
	for building in sim.get_buildings():
		if bool(building.get("construction", false)):
			continue
		if String(building.get("type", "")) == building_type:
			return true
	return false


func _starter_ready(sim) -> bool:
	return _has_completed(sim, Defs.BUILDING_HOUSE) and _has_completed(sim, Defs.BUILDING_LUMBER_CAMP) and _has_completed(sim, Defs.BUILDING_FARM)


func _need_storage(sim) -> bool:
	return _stock(sim, Defs.RESOURCE_WOOD) >= 24 or _stock(sim, Defs.RESOURCE_STONE) >= 24 or _stock(sim, Defs.RESOURCE_WHEAT) >= 16


func _stock(sim, resource_type: String) -> int:
	return int(sim.central_inventory.get(resource_type, 0))


func _food(sim) -> int:
	return int(sim.get_food_units())


func _note(sim, kind: String, tile: Vector2i, message: String) -> void:
	var line := "%s @%s t=%.0f" % [kind, str(tile), float(sim.elapsed_seconds)]
	last_actions.append(line)
	orders.append({
		"seconds": float(sim.elapsed_seconds),
		"type": kind,
		"tile": "%d,%d" % [tile.x, tile.y],
		"message": message
	})
	print("DEMO_AI t=%.1f %s %s" % [float(sim.elapsed_seconds), kind, message])
