extends SceneTree

## Combat events must land in the existing Log (notice_log): aggregated hits,
## kills / losses, and a RAID OVER summary. No HUD layout changes.

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const RaidTuning = preload("res://src/GodotClient/Scripts/one_shard_raid_tuning.gd")

var failures: Array[String] = []


func _init() -> void:
	_test_building_hits_and_summary()
	_test_aggregation()
	_test_troop_hits_and_kills()
	print("T_RAID_COMBAT_LOG %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_building_hits_and_summary() -> void:
	var sim: Simulation = Simulation.new(70, 70, 260821, false, true)
	sim.day_count = 2
	sim.is_night = true
	sim.central_inventory[Defs.RESOURCE_BREAD] = 30
	sim._reveal_radius(sim.town_hall_position, 16)
	sim._send_workers_to_shelter()
	var tile := sim.town_hall_position + Vector2i(3, 0)
	sim._prepare_test_tile(tile, Defs.TILE_GRASS)
	var store := sim._add_completed_building(Defs.BUILDING_STOREHOUSE, tile)
	store["connected"] = true
	sim._reveal_radius(tile, 6)
	sim._spawn_enemy(tile + Vector2i(1, 0), RaidTuning.NIGHT2_HP, RaidTuning.NIGHT2_DAMAGE, 0.0, 0, sim.ENEMY_RAIDER, RaidTuning.NIGHT2_ARMOR)
	sim._begin_raid(RaidTuning.NIGHT2_STEAL)
	sim._simulate_seconds_for_test(5.0)
	var hit_line := _first_notice_containing(sim, "Raiders hit")
	print("RAID_LOG hit='%s'" % hit_line)
	_check(hit_line.contains("Storehouse") or hit_line.contains("Town Hall"), "combat log names the building that was hit")
	_check("(-" in hit_line and "HP)" in hit_line, "combat log reports aggregated HP lost")
	_kill_remaining(sim)
	sim._maybe_finish_raid()
	var summary := sim.get_raid_summary()
	var body := String(summary.get("body", ""))
	print("RAID_LOG summary='%s'" % body)
	_check(body.begins_with("RAID OVER"), "raid end writes a RAID OVER summary")
	_check("enemies killed" in body and "lost" in body, "summary lists kills and our losses")
	_check("buildings damaged" in body, "summary lists buildings damaged")
	_check("resources lost" in body, "summary lists resources lost")
	_check(int(summary.get("duration", 0)) >= 1, "summary records a positive duration")
	_check(_notice_count(sim, "RAID OVER") >= 1, "summary is in the existing Log panel")


func _test_aggregation() -> void:
	var sim: Simulation = Simulation.new(70, 70, 260821, false, true)
	sim.is_night = true
	var hall := sim._find_town_hall()
	sim._damage_building(hall, 4)
	sim._damage_building(hall, 5)
	_check(_notice_count(sim, "Raiders hit") == 0, "hits inside the window stay unpublished")
	sim.elapsed_seconds += RaidTuning.COMBAT_LOG_WINDOW_SECONDS + 0.05
	sim._flush_combat_log(false)
	var line := _first_notice_containing(sim, "Raiders hit")
	print("RAID_LOG aggregated='%s'" % line)
	_check(line.contains("Town Hall") and line.contains("-9 HP"), "two hits 4+5 combine into one -9 HP line")
	_check(_notice_count(sim, "Raiders hit") == 1, "one aggregated line per building per window")


func _test_troop_hits_and_kills() -> void:
	var sim: Simulation = Simulation.new(70, 70, 260821, false, true)
	sim.is_night = true
	sim._reveal_radius(sim.town_hall_position, 12)
	var guard: Dictionary = sim._create_patrol_worker(0, "log_guard")
	guard["position"] = sim.town_hall_position + Vector2i(2, 0)
	sim.workers.append(guard)
	sim._spawn_enemy(guard["position"] + Vector2i(1, 0), 6, 1, 0.0, 0, sim.ENEMY_RAIDER, 0)
	sim._begin_raid(1)
	var elapsed := 0.0
	while sim.living_hostile_count() > 0 and elapsed < 8.0:
		sim.advance_tick()
		elapsed += Simulation.TICK_SECONDS
	sim._flush_combat_log(true)
	sim._maybe_finish_raid()
	var troop_line := _first_notice_containing(sim, "Soldiers hit")
	print("RAID_LOG troop='%s'" % troop_line)
	_check(troop_line.contains("Raider") and "HP)" in troop_line, "Log records what our troops did to the enemy")
	_check(_notice_count(sim, "was slain") >= 1, "Log records the enemy kill")
	_check(_notice_count(sim, "RAID OVER") >= 1, "killing the last raider writes the summary")


func _kill_remaining(sim: Simulation) -> void:
	for enemy in sim.enemies:
		enemy["hp"] = 0
	sim._update_enemies(Simulation.TICK_SECONDS)


func _first_notice_containing(sim: Simulation, needle: String) -> String:
	for notice in sim.get_notice_log():
		var body := String(notice.get("body", ""))
		if needle in body:
			return body
	return ""


func _notice_count(sim: Simulation, needle: String) -> int:
	var count := 0
	for notice in sim.get_notice_log():
		if needle in String(notice.get("body", "")) or needle in String(notice.get("title", "")):
			count += 1
	return count


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
