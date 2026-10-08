extends RefCounted

const Defs = preload("one_shard_defs.gd")
const RivalryRules = preload("one_shard_rivalry.gd")
const RivalryTuning = preload("one_shard_rivalry_tuning.gd")
const Wyrdfall = preload("one_shard_wyrdfall.gd")
const RaidTuning = preload("res://src/GodotClient/Scripts/one_shard_raid_tuning.gd")
const SaveStore = preload("one_shard_save_store.gd")
const Intentions = preload("one_shard_intentions.gd")
const PlaytestLog = preload("one_shard_playtest_log.gd")
const Scout = preload("one_shard_scout.gd")
const Discoveries = preload("one_shard_discoveries.gd")
const Economy = preload("one_shard_economy.gd")
const RaidIntents = preload("one_shard_raid_intents.gd")
const Placement = preload("one_shard_placement.gd")
const Frontier = preload("one_shard_frontier.gd")
const Dawn = preload("one_shard_dawn.gd")

const SAVE_PATH := "user://one_shard_save.json"
const AUTOSAVE_PATH := "user://one_shard_autosave.json"
const BEST_SCORE_PATH := "user://one_shard_best_score.json"
const RUN_JOURNAL_PATH := "user://one_shard_run_journal.jsonl"
const LAST_RUN_PATH := "user://one_shard_last_run.json"
const SAVE_VERSION := 8
const MAP_WIDTH := 70
const MAP_HEIGHT := 70
const TICK_SECONDS := 0.10
const CARRIER_STEP_SECONDS := 0.78
const LABORER_STEP_SECONDS := 0.95
const ENEMY_STEP_SECONDS := 0.72
const ENEMY_RAIDER := "raider"
const ENEMY_SKITTERER := "skitterer"
const ENEMY_BRUTE := "brute"
const ENEMY_HEXER := "hexer"
const ENEMY_TARGET_REFRESH_SECONDS := 0.55
const ROAD_MOVE_MULTIPLIER := 0.78
const LUMBER_REACH := 16
const TREE_REGROWTH_SECONDS := 150.0
const DAY_LENGTH_SECONDS := 420.0
const NIGHT_LENGTH_SECONDS := 180.0
const NIGHT_WARNING_SECONDS := 60.0
const NIGHT_FINAL_WARNING_SECONDS := 30.0
const STARTING_POPULATION := 2
const STARTING_HOUSING_CAPACITY := 5
const POP_GROWTH_INTERVAL := 45.0
const FOUNDING_POP_GROWTH_INTERVAL := 30.0
const POP_GROWTH_FOOD_COST := 1
const SAWMILL_WOOD_RESERVE := 4
const TOWER_RANGE := 8
const TOWER_DAMAGE := 5
const TOWER_COOLDOWN_SECONDS := 2.2
const ENEMY_ATTACK_INTERVAL_SECONDS := 1.6
const ENEMY_ATTACK_ANIMATION_SECONDS := 0.56
const ENEMY_ATTACK_STRIKE_REMAINING := 0.28
const GUARD_ATTACK_ANIMATION_SECONDS := 0.48
const GUARD_ATTACK_STRIKE_REMAINING := 0.24
const GUARD_DAMAGE := 4
const TOWN_HALL_OVERFLOW := 20
const AUTO_SPUR_MAX_STEPS := 2
const NOTICE_LOG_LIMIT := 80
const BARRACKS_TRAIN_SECONDS := 18.0
const BARRACKS_SOLDIER_CAPACITY := 4
const SOLDIER_BREAD_COST := 2
# Compatibility constant for legacy callers. Planks are a construction cost,
# not a recurring soldier-training input.
const SOLDIER_PLANK_COST := 0
const WORKER_MAX_HP := 30
const HUNGER_RECOVERY_FRACTION := 0.25
const HUNGER_OUTPUT_MULTIPLIER := 0.5
const STAFF_PRIORITY_LOW := 0
const STAFF_PRIORITY_NORMAL := 1
const STAFF_PRIORITY_HIGH := 2
const CITY_PATROL_RADIUS := 12
const CARRIER_BUILD_ACTION_SECONDS := 0.9
const ROAD_BUILD_SECONDS := 1.6
const INITIAL_REVEAL_RADIUS := 12
# The Director: building/unit vision. Watchtower is the large scouting
# ring, Outpost is medium-large, Lumen and other workplaces stay small.
# Units reveal on tile change so a later scout order can just walk.
const VISION_TOWN_HALL := 14
const VISION_WATCHTOWER := 16
const VISION_OUTPOST := 12
const VISION_LUMEN := 10
const VISION_BUILDING := 5
const VISION_ROAD := 3
const VISION_WORKER := 4
const VISION_SOLDIER := 8
# The Director: patrol soldiers leave the road to intercept hostiles and
# defend yards under attack, then resume Night Patrol / Patrolling.
const PATROL_AGGRO_RADIUS := 10
const PATROL_DEFEND_RADIUS := 12
const PATROL_MELEE_RADIUS := 2
const TOWN_HALL_PROTECTION_RADIUS := 8.0
const OUTPOST_PROTECTION_RADIUS := 5.0
const TOWER_PROTECTION_RADIUS := 3.0
const WYRD_BASE_UPKEEP_PER_MINUTE := 0.75
const WYRD_OUTPOST_UPKEEP_PER_MINUTE := 0.35
const WYRD_TOWER_UPKEEP_PER_MINUTE := 0.20
const WYRD_OUTPOST_HARVEST_RADIUS := 3.0
const WYRD_OUTPOST_HARVEST_SECONDS := 30.0
const WORKER_SYNC_INTERVAL_SECONDS := 0.5

var map_size := Vector2i(MAP_WIDTH, MAP_HEIGHT)
var map_tiles: Array = []
var height_map: Array = []
var revealed_tiles: Dictionary = {}
var tree_deposits: Dictionary = {}
var rock_deposits: Dictionary = {}
var tree_regrowth: Dictionary = {}
var town_hall_position := Vector2i.ZERO
var rival_town_hall_position := Vector2i.ZERO
var shard_position := Vector2i.ZERO
var enemy_camps: Array = []

var central_inventory: Dictionary = {}
var reserved_inventory: Dictionary = {}
var buildings: Array = []
var occupied_tiles: Dictionary = {}
var connected_roads: Dictionary = {}
var connected_walls: Dictionary = {}
var workers: Array = []
var enemies: Array = []
var projectiles: Array = []
var decorative_props: Array = []
var path_grid: AStarGrid2D
var hostile_path_grid: AStarGrid2D
var path_grid_dirty := true
var log_entries: Array[String] = []
var run_journal: Array = []
var _pending_diagnostic_lines: Array[String] = []
var objectives: Array = []
var intention_completed: Dictionary = {}
var intention_flags: Dictionary = {}
var playtest_log := PlaytestLog.new()
var map_markers: Array = []
var stats: Dictionary = {}
var diagnostics_enabled := true

var rng := RandomNumberGenerator.new()
var rng_seed := 0
var next_building_id := 1
var next_worker_id := 1
var next_enemy_id := 1
var tick_number := 0
var elapsed_seconds := 0.0
## Playtest.31: real engagement clock for adaptive music (not just "enemies exist").
const COMBAT_LINGER_SECONDS := 6.0
var last_combat_elapsed := -1000.0
var player_monster_kills := 0
var last_player_kill: Dictionary = {}
var phase_time := 0.0
var pop_growth_timer := 0.0
var hunger_penalty_remaining := 0.0
var hungry_population := 0
var diagnostic_snapshot_elapsed := 0.0
var population_current := STARTING_POPULATION
var housing_capacity := STARTING_HOUSING_CAPACITY
var workers_assigned := 0
var soldiers_total := 0
var hidden_threat_level := 0
var day_count := 1
var is_night := false
var night_warning_sent := false
var night_final_warning_sent := false
var dusk_warning_sent := false
var horn_warning_sent := false
var raid_plan: Dictionary = {}
var last_message := "Extend the road from the waiting carrier."
var game_finished := false
var victory := false
var defeat_reason := ""
var claim_active := false
var claim_outpost_id := 0
var claim_nights_survived := 0
var best_score := 0
var next_camp_id := 1
var audio_events: Array[String] = []
var wyrd_upkeep_progress := 0.0
var protection_powered := false
var worker_sync_elapsed := 0.0
var path_query_count := 0
var path_grid_rebuild_count := 0
var presentation_opening_active := false
var first_player_order_complete := false
var presentation_worker_id := 0
var rivalry
var world_features: Array = []
var cumulative_wyrd_extracted := 0
var peak_wyrd_pressure := 0.0
var last_pressure_band := Wyrdfall.BAND_QUIET
var last_pressure_value := 0.0
var pressure_feedback_cooldown := 0.0
var pending_pressure_reason := ""
var reckoning_active := false
var reckoning_waves_spawned := 0
var dusk_forecast: Dictionary = {}
var dawn_summary: Dictionary = {}
var night_casualties := 0
var night_buildings_damaged := 0
var night_enemies_spawned := 0
var night_enemies_defeated_at_dusk := 0
## Director: live raid bookkeeping for the Log panel. Reset each wave / dawn.
var raid_active := false
var raid_started_elapsed := 0.0
var raid_steal_per_hit := 0
var raid_enemies_killed := 0
var raid_our_losses := 0
var raid_buildings_damaged_ids: Dictionary = {}
var raid_buildings_destroyed: Array[String] = []
var raid_resources_lost: Dictionary = {}
var raid_last_summary: Dictionary = {}
var _combat_log_buckets: Dictionary = {}
var shard_contacted := false
var onboarding_shown: Dictionary = {}
var priority_clear_tiles: Dictionary = {}
var notice_log: Array = []
var pending_notices: Array = []
var next_notice_id := 1
var pending_onboarding: Dictionary = {}
var binding_confirm_required := true

# Phase 3 profiling is opt-in so the production simulation pays no timing or
# sample-allocation cost during ordinary play. The profiler observes the
# existing authority; it does not change tick cadence or game outcomes.
var performance_profile_enabled := false
var _profile_tick_started_usec := 0
var _profile_system_usec: Dictionary = {}
var _profile_system_calls: Dictionary = {}
var _profile_tick_records: Array[Dictionary] = []
var _profile_scan_items: Dictionary = {}
var _profile_start_path_queries := 0
var _profile_start_path_rebuilds := 0

# Aggregate reservations mirror the existing worker task dictionaries. They
# make carrier discovery O(workers + buildings) per tick instead of repeatedly
# scanning every worker for every resource/building/candidate carrier.
var _task_indexes_valid := false
var _task_incoming_by_destination: Dictionary = {}
var _task_outgoing_by_source: Dictionary = {}
var _task_incoming_to_central: Dictionary = {}


func _init(width: int = MAP_WIDTH, height: int = MAP_HEIGHT, seed_value: int = 0, enable_diagnostics: bool = true, begin_founded: bool = false) -> void:
	diagnostics_enabled = enable_diagnostics
	start_new_run(width, height, seed_value, begin_founded)


func start_new_run(width: int = MAP_WIDTH, height: int = MAP_HEIGHT, seed_value: int = 0, begin_founded: bool = false) -> void:
	map_size = Vector2i(width, height)
	rng_seed = seed_value
	if rng_seed == 0:
		rng_seed = int(Time.get_unix_time_from_system()) % 2147483647
	rng.seed = rng_seed

	map_tiles.clear()
	height_map.clear()
	revealed_tiles.clear()
	tree_deposits.clear()
	rock_deposits.clear()
	tree_regrowth.clear()
	enemy_camps.clear()
	world_features.clear()
	buildings.clear()
	occupied_tiles.clear()
	connected_roads.clear()
	connected_walls.clear()
	workers.clear()
	enemies.clear()
	projectiles.clear()
	audio_events.clear()
	last_combat_elapsed = -1000.0
	player_monster_kills = 0
	last_player_kill = {}
	path_grid = null
	hostile_path_grid = null
	path_grid_dirty = true
	log_entries.clear()
	run_journal.clear()
	_pending_diagnostic_lines.clear()
	if diagnostics_enabled:
		if FileAccess.file_exists(RUN_JOURNAL_PATH) and FileAccess.get_file_as_string(RUN_JOURNAL_PATH).length() > 0:
			DirAccess.copy_absolute(RUN_JOURNAL_PATH, RUN_JOURNAL_PATH + ".previous")
		var journal_file := FileAccess.open(RUN_JOURNAL_PATH, FileAccess.WRITE)
		if journal_file != null:
			journal_file.store_string("")

	central_inventory = Defs.STARTING_RESOURCES.duplicate(true)
	reserved_inventory = Defs.empty_inventory()
	stats = {
		"buildings_completed": 0,
		"enemies_defeated": 0,
		"buildings_abandoned": 0,
		"buildings_destroyed": 0,
		"days_survived": 0,
		"shard_claimed": false,
		"workers_lost": 0,
		"hungry_nights": 0,
		"wood_produced": 0,
		"stone_produced": 0,
		"wheat_produced": 0,
		"bread_produced": 0,
		"wyrd_extracted": 0,
		"peak_population": STARTING_POPULATION,
		"peak_wyrd_pressure": 0.0,
		"territory_revealed": 0
	}
	intention_completed = {}
	intention_flags = {}
	map_markers = []
	playtest_log.configure()
	objectives = [
		{"id": "found", "text": "Choose a clear site and build the Town Hall", "complete": false},
		{"id": "road", "text": "Extend the Road from the Town Hall", "complete": false},
		{"id": "house", "text": "Build a House to shelter your settlers", "complete": false},
		{"id": "lumber", "text": "Build a Lumber Camp near trees", "complete": false},
		{"id": "farm", "text": "Build a Farm to produce Wheat for Bread", "complete": false},
		{"id": "storehouse", "text": "Build a Storehouse when storage fills up", "complete": false},
		{"id": "watchtower", "text": "Build a Watchtower before night", "complete": false},
		{"id": "wyrd", "text": "Harvest a Wyrd node with an Outpost", "complete": false},
		{"id": "lumen", "text": "Extend connected Lumen toward the Shard", "complete": false},
		{"id": "outpost", "text": "Build an Outpost toward the Shard", "complete": false},
		{"id": "claim", "text": "Bind the Shard and survive the Reckoning", "complete": false}
	]

	next_building_id = 1
	next_worker_id = 1
	next_enemy_id = 1
	tick_number = 0
	elapsed_seconds = 0.0
	phase_time = 0.0
	pop_growth_timer = 0.0
	hunger_penalty_remaining = 0.0
	hungry_population = 0
	diagnostic_snapshot_elapsed = 0.0
	population_current = STARTING_POPULATION
	housing_capacity = STARTING_HOUSING_CAPACITY
	workers_assigned = 0
	soldiers_total = 0
	hidden_threat_level = 0
	day_count = 1
	is_night = false
	night_warning_sent = false
	night_final_warning_sent = false
	dusk_warning_sent = false
	horn_warning_sent = false
	raid_plan = {}
	last_message = "Choose any clear, visible 4x4 site for the Town Hall."
	game_finished = false
	victory = false
	defeat_reason = ""
	claim_active = false
	claim_outpost_id = 0
	claim_nights_survived = 0
	next_camp_id = 1
	wyrd_upkeep_progress = 0.0
	protection_powered = false
	worker_sync_elapsed = 0.0
	path_query_count = 0
	path_grid_rebuild_count = 0
	_task_indexes_valid = false
	_task_incoming_by_destination.clear()
	_task_outgoing_by_source.clear()
	_task_incoming_to_central.clear()
	set_performance_profiling(false, true)
	presentation_opening_active = false
	first_player_order_complete = false
	presentation_worker_id = 0
	world_features.clear()
	cumulative_wyrd_extracted = 0
	peak_wyrd_pressure = 0.0
	last_pressure_band = Wyrdfall.BAND_QUIET
	last_pressure_value = 0.0
	pressure_feedback_cooldown = 0.0
	pending_pressure_reason = ""
	reckoning_active = false
	reckoning_waves_spawned = 0
	dusk_forecast = {}
	dawn_summary = {}
	night_casualties = 0
	night_buildings_damaged = 0
	night_enemies_spawned = 0
	night_enemies_defeated_at_dusk = 0
	_reset_raid_bookkeeping()
	shard_contacted = false
	onboarding_shown = Wyrdfall.load_onboarding()
	pending_onboarding = {}
	binding_confirm_required = true
	best_score = _load_best_score()

	_generate_map()
	rivalry = null
	if begin_founded:
		_complete_founding_immediately()
	else:
		_create_founding_party()
	_reveal_from_world()
	if begin_founded:
		_add_log("Town Hall founded. A carrier waits on the entrance road.")
		_record_event("run_started", "New realm founded.", {"seed": rng_seed})
	else:
		_add_log("Two confused settlers have arrived with a donkey and the supplies for a Town Hall.")
		_record_event("founding_party_arrived", "A founding party arrived.", {"seed": rng_seed})


func start_presentation_run(seed_value: int = 0) -> void:
	start_new_run(MAP_WIDTH, MAP_HEIGHT, seed_value, true)
	presentation_opening_active = true
	first_player_order_complete = false
	population_current = 1
	housing_capacity = STARTING_HOUSING_CAPACITY
	pop_growth_timer = -120.0
	workers_assigned = 0
	soldiers_total = 0
	central_inventory = Defs.empty_inventory()
	central_inventory[Defs.RESOURCE_WOOD] = 14
	central_inventory[Defs.RESOURCE_PLANKS] = 4
	central_inventory[Defs.RESOURCE_STONE] = 6
	central_inventory[Defs.RESOURCE_BREAD] = 6
	central_inventory[Defs.RESOURCE_WYRD] = 3
	reserved_inventory = Defs.empty_inventory()
	workers.clear()
	var entrance := _town_hall_entrance_tile()
	workers.append({
		"id": next_worker_id,
		"type": "carrier",
		"building_id": 0,
		"role_key": "presentation_settler",
		"position": entrance,
		"path": [],
		"state": "Inside Town Hall",
		"arrival_state": "Inside Town Hall",
		"move_elapsed": 0.0,
		"activity_timer": 0.0,
		"capacity": 5,
		"carried_resource": "",
		"carried_amount": 0,
		"task": {},
		"shelter_position": Vector2i(-1, -1),
		"hp": WORKER_MAX_HP,
		"max_hp": WORKER_MAX_HP,
		"hungry": false,
		"reaction": "",
		"reaction_until": 0.0,
		"manual_order": true
	})
	presentation_worker_id = next_worker_id
	next_worker_id += 1
	objectives = [
		{"id": "found", "text": "Choose a clear site and build the Town Hall", "complete": true},
		{"id": "first_order", "text": "Give your settler their first order.", "complete": false},
		{"id": "road", "text": "Extend the entrance road.", "complete": false},
		{"id": "house", "text": "Build a House for shelter and growth.", "complete": false},
		{"id": "lumber", "text": "Build a Lumber Camp near the trees.", "complete": false},
		{"id": "farm", "text": "Build a Farm to produce Wheat.", "complete": false},
		{"id": "wyrd", "text": "Harvest a Wyrd spring with an Outpost.", "complete": false},
		{"id": "lumen", "text": "Extend connected Lumen toward the Shard.", "complete": false},
		{"id": "outpost", "text": "Build a Claimant Outpost beside the Shard.", "complete": false},
		{"id": "claim", "text": "Hold the Shard through one complete night.", "complete": false}
	]
	var town_center: Vector2i = _footprint_center(town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	_clear_area(town_center, 10)
	_flatten_area(town_center, 10)
	_spawn_founding_yard_props(entrance)
	for offset in [
		Vector2i(-8, -5), Vector2i(-9, -3), Vector2i(-8, 1), Vector2i(-7, 5),
		Vector2i(7, -6), Vector2i(9, -3), Vector2i(9, 2), Vector2i(7, 6)
	]:
		var tree_tile: Vector2i = town_center + Vector2i(offset)
		_set_tile(tree_tile, Defs.TILE_TREE)
		tree_deposits[_tile_key(tree_tile)] = 18
	for offset in [Vector2i(-9, 4), Vector2i(10, 4), Vector2i(6, -9)]:
		var rock_tile: Vector2i = town_center + Vector2i(offset)
		_set_tile(rock_tile, Defs.TILE_ROCK)
		rock_deposits[_tile_key(rock_tile)] = 20
	for road_offset in [Vector2i(0, 1), Vector2i(0, 2)]:
		var road_tile: Vector2i = entrance + Vector2i(road_offset)
		if get_building_at_tile(road_tile).is_empty():
			_add_completed_building(Defs.BUILDING_ROAD, road_tile)
	_rebuild_occupied_tiles()
	_recompute_road_network()
	_reveal_radius(town_center, 19)
	last_message = "A quiet clearing. One settler is waiting inside the Town Hall."
	log_entries.clear()
	_add_log("The new realm begins with one Town Hall and one uncertain settler.")
	_record_event("presentation_run_started", "Authored opening started.", {"seed": rng_seed})


func get_presentation_worker_id() -> int:
	return presentation_worker_id


func get_worker_by_id(worker_id: int) -> Dictionary:
	for worker in workers:
		if int(worker.get("id", 0)) == worker_id:
			return worker.duplicate(true)
	return {}


func set_presentation_worker_departure(path: Array) -> void:
	for worker in workers:
		if int(worker.get("id", 0)) != presentation_worker_id:
			continue
		worker["path"] = path.duplicate()
		worker["state"] = "Leaving Town Hall"
		worker["arrival_state"] = "Looking around"
		worker["move_elapsed"] = 0.0
		return


func set_worker_reaction(worker_id: int, state: String, reaction: String, duration: float) -> void:
	for worker in workers:
		if int(worker.get("id", 0)) != worker_id:
			continue
		worker["state"] = state
		worker["arrival_state"] = state
		worker["reaction"] = reaction
		worker["reaction_until"] = elapsed_seconds + duration
		return


func is_town_hall_founded() -> bool:
	return not _find_town_hall().is_empty()


func _create_founding_party() -> void:
	var entrance := _town_hall_entrance_tile()
	var founder_positions := [
		entrance + Vector2i(-1, 1),
		entrance + Vector2i(1, 2)
	]
	for index in range(2):
		workers.append({
			"id": next_worker_id,
			"type": "founder",
			"building_id": 0,
			"position": founder_positions[index],
			"path": [],
			"state": "Confused",
			"arrival_state": "Confused",
			"move_elapsed": 0.0,
			"activity_timer": 0.0,
			"capacity": 0,
			"carried_resource": "",
			"carried_amount": 0,
			"task": {},
			"shelter_position": Vector2i(-1, -1),
			"hp": WORKER_MAX_HP,
			"max_hp": WORKER_MAX_HP,
			"hungry": false
		})
		next_worker_id += 1


func _complete_founding_immediately() -> void:
	workers.clear()
	_add_completed_building(Defs.BUILDING_TOWN_HALL, town_hall_position)
	_add_completed_building(Defs.BUILDING_ROAD, _town_hall_entrance_tile())
	_finish_founding_setup()


func _finish_founding_setup() -> void:
	for index in range(workers.size() - 1, -1, -1):
		if String(workers[index].get("type", "")) == "founder":
			workers.remove_at(index)
	if get_building_at_tile(_town_hall_entrance_tile()).is_empty():
		_add_completed_building(Defs.BUILDING_ROAD, _town_hall_entrance_tile())
	_rebuild_occupied_tiles()
	_recompute_road_network()
	if rivalry == null:
		rivalry = RivalryRules.new()
		rivalry.setup(self, rng_seed)
	_register_wyrd_features()
	protection_powered = int(central_inventory.get(Defs.RESOURCE_WYRD, 0)) > 0
	_update_objective_flag("found")
	_ensure_carriers()
	_reveal_from_world()
	_spawn_founding_yard_props(_town_hall_entrance_tile())


func _spawn_founding_yard_props(entrance: Vector2i) -> void:
	decorative_props.clear()
	var next_prop_id := 1
	var prop_placements := [
		{"type": "wood_stack", "offset": Vector2i(-2, -1), "rotation": 0.0, "scale": 1.1},
		{"type": "wood_stack", "offset": Vector2i(2, -1), "rotation": 45.0, "scale": 0.9},
		{"type": "wood_stack", "offset": Vector2i(-1, 2), "rotation": -30.0, "scale": 1.0},
		{"type": "wood_stack", "offset": Vector2i(1, -2), "rotation": 60.0, "scale": 0.95},
		{"type": "stone_stack", "offset": Vector2i(-3, 0), "rotation": 0.0, "scale": 1.0},
		{"type": "stone_stack", "offset": Vector2i(3, 0), "rotation": 30.0, "scale": 0.85},
		{"type": "stone_stack", "offset": Vector2i(1, 3), "rotation": -15.0, "scale": 0.95},
		{"type": "barrel", "offset": Vector2i(-2, 1), "rotation": 0.0, "scale": 1.0},
		{"type": "crate", "offset": Vector2i(2, 1), "rotation": 15.0, "scale": 1.0},
		{"type": "barrel", "offset": Vector2i(-3, 3), "rotation": 0.0, "scale": 1.0},
		{"type": "crate", "offset": Vector2i(3, 3), "rotation": -20.0, "scale": 0.95},
		{"type": "crate", "offset": Vector2i(-1, -1), "rotation": 45.0, "scale": 0.9},
		{"type": "barrel", "offset": Vector2i(0, 2), "rotation": 0.0, "scale": 1.05},
		{"type": "long_crate", "offset": Vector2i(-3, -2), "rotation": -45.0, "scale": 0.9},
		{"type": "crate", "offset": Vector2i(2, 3), "rotation": 30.0, "scale": 0.85},
	]
	for placement in prop_placements:
		var prop_tile: Vector2i = entrance + Vector2i(placement["offset"])
		if is_inside_map(prop_tile) and String(get_tile(prop_tile)) == Defs.TILE_GRASS and get_building_at_tile(prop_tile).is_empty():
			decorative_props.append({
				"id": next_prop_id,
				"type": String(placement["type"]),
				"position": prop_tile,
				"rotation": float(placement["rotation"]),
				"scale": float(placement["scale"])
			})
			next_prop_id += 1


func advance_tick() -> void:
	_profile_tick_begin()
	if game_finished:
		var projectile_stamp := _profile_stamp()
		_update_projectiles(TICK_SECONDS)
		_profile_finish("projectiles", projectile_stamp)
		var diagnostic_stamp := _profile_stamp()
		_flush_diagnostic_events()
		_profile_finish("diagnostic_event_flush", diagnostic_stamp)
		_profile_tick_end()
		return

	tick_number += 1
	elapsed_seconds += TICK_SECONDS
	if not is_town_hall_founded():
		var founding_stamp := _profile_stamp()
		_update_construction(TICK_SECONDS)
		_profile_finish("construction_logistics", founding_stamp)
		var diagnostic_stamp := _profile_stamp()
		_flush_diagnostic_events()
		_profile_finish("diagnostic_event_flush", diagnostic_stamp)
		_profile_tick_end()
		return
	var stamp := _profile_stamp()
	_update_time(TICK_SECONDS)
	_profile_finish("time_day_night", stamp)
	if rivalry != null:
		stamp = _profile_stamp()
		rivalry.advance(
			TICK_SECONDS,
			is_night,
			phase_time,
			NIGHT_LENGTH_SECONDS
		)
		_profile_finish("rivalry_updates", stamp)
	stamp = _profile_stamp()
	_update_wyrd_network(TICK_SECONDS)
	_profile_finish("lumen_claim_updates", stamp)
	stamp = _profile_stamp()
	_update_wyrdfall(TICK_SECONDS)
	_profile_finish("wyrdfall_updates", stamp)
	stamp = _profile_stamp()
	_update_hunger_recovery(TICK_SECONDS)
	_update_population_growth(TICK_SECONDS)
	_profile_finish("hunger_housing_checks", stamp)
	stamp = _profile_stamp()
	_update_tree_regrowth(TICK_SECONDS)
	_profile_finish("resource_regrowth", stamp)
	stamp = _profile_stamp()
	_update_construction(TICK_SECONDS)
	_profile_finish("construction_logistics", stamp)
	var worker_stamp := _profile_stamp()
	stamp = _profile_stamp()
	_update_clear_workers(TICK_SECONDS)
	_profile_finish("clearer_updates", stamp)
	worker_sync_elapsed += TICK_SECONDS
	if worker_sync_elapsed >= WORKER_SYNC_INTERVAL_SECONDS:
		worker_sync_elapsed = 0.0
		stamp = _profile_stamp()
		_sync_production_workers()
		_profile_finish("job_assignment", stamp)
	stamp = _profile_stamp()
	_update_production_workers(TICK_SECONDS)
	_profile_finish("production_worker_updates", stamp)
	stamp = _profile_stamp()
	_update_production(TICK_SECONDS)
	_refresh_economy_stalls()
	_emit_routine_notices()
	_profile_finish("building_production_updates", stamp)
	stamp = _profile_stamp()
	_update_barracks(TICK_SECONDS)
	_profile_finish("barracks_updates", stamp)
	stamp = _profile_stamp()
	_process_carriers(TICK_SECONDS)
	_profile_finish("carrier_updates", stamp)
	stamp = _profile_stamp()
	_update_unit_vision()
	_profile_finish("unit_vision", stamp)
	_profile_finish("worker_update_total", worker_stamp)
	stamp = _profile_stamp()
	_activate_revealed_enemy_camps()
	_profile_finish("scouting_camp_updates", stamp)
	stamp = _profile_stamp()
	var combat_stamp := stamp
	_update_enemies(TICK_SECONDS)
	_profile_finish("enemy_updates", stamp)
	stamp = _profile_stamp()
	_update_patrol_combat(TICK_SECONDS)
	_profile_finish("patrol_combat", stamp)
	stamp = _profile_stamp()
	_update_towers(TICK_SECONDS)
	_profile_finish("tower_updates", stamp)
	_profile_finish("combat_updates", combat_stamp)
	stamp = _profile_stamp()
	_update_projectiles(TICK_SECONDS)
	_profile_finish("projectiles", stamp)
	_flush_combat_log(false)
	_maybe_finish_raid()
	stamp = _profile_stamp()
	_update_objectives()
	Intentions.evaluate(self)
	_profile_finish("objective_updates", stamp)
	stamp = _profile_stamp()
	_update_diagnostic_snapshot(TICK_SECONDS)
	_profile_finish("diagnostic_snapshot", stamp)
	stamp = _profile_stamp()
	_flush_diagnostic_events()
	_profile_finish("diagnostic_event_flush", stamp)
	_profile_tick_end()


func set_performance_profiling(enabled: bool, reset_samples: bool = true) -> void:
	performance_profile_enabled = enabled
	if not reset_samples:
		return
	_profile_tick_started_usec = 0
	_profile_system_usec.clear()
	_profile_system_calls.clear()
	_profile_tick_records.clear()
	_profile_scan_items.clear()
	_profile_start_path_queries = path_query_count
	_profile_start_path_rebuilds = path_grid_rebuild_count


func get_performance_profile() -> Dictionary:
	var tick_values: Array[float] = []
	var system_samples: Dictionary = {}
	var system_calls: Dictionary = {}
	for record_value in _profile_tick_records:
		var record: Dictionary = record_value
		tick_values.append(float(record.get("tick_usec", 0.0)) / 1000.0)
		var timings: Dictionary = record.get("systems_usec", {})
		var calls: Dictionary = record.get("system_calls", {})
		for system_name in timings:
			if not system_samples.has(system_name):
				system_samples[system_name] = []
			(system_samples[system_name] as Array).append(float(timings[system_name]) / 1000.0)
		for system_name in calls:
			system_calls[system_name] = int(system_calls.get(system_name, 0)) + int(calls[system_name])
	var systems: Dictionary = {}
	for system_name in system_samples:
		var samples: Array = system_samples[system_name]
		var calls := int(system_calls.get(system_name, 0))
		systems[system_name] = {
			"average_ms_per_tick": snappedf(_profile_mean(samples), 0.0001),
			"p95_ms_per_tick": snappedf(_profile_percentile(samples, 0.95), 0.0001),
			"calls_per_tick": snappedf(float(calls) / maxf(1.0, float(_profile_tick_records.size())), 0.001),
			"average_usec_per_call": snappedf(_profile_mean(samples) * 1000.0 * float(_profile_tick_records.size()) / maxf(1.0, float(calls)), 0.01),
		}
	return {
		"ticks": _profile_tick_records.size(),
		"inhabitants": population_current,
		"live_workers": workers.size(),
		"buildings": buildings.size(),
		"tick_average_ms": snappedf(_profile_mean(tick_values), 0.0001),
		"tick_p95_ms": snappedf(_profile_percentile(tick_values, 0.95), 0.0001),
		"tick_p99_ms": snappedf(_profile_percentile(tick_values, 0.99), 0.0001),
		"tick_max_ms": snappedf(_profile_max(tick_values), 0.0001),
		"systems": systems,
		"dictionary_entity_scan_items": _profile_scan_items.duplicate(true),
		"path_requests": path_query_count - _profile_start_path_queries,
		"path_cache_rebuilds": path_grid_rebuild_count - _profile_start_path_rebuilds,
		"allocation_measurement": "GDScript does not expose per-call allocation counts; profile reports scan work and static-memory deltas in the harness.",
	}


func _profile_tick_begin() -> void:
	if not performance_profile_enabled:
		return
	_profile_tick_started_usec = Time.get_ticks_usec()
	_profile_system_usec = {}
	_profile_system_calls = {}


func _profile_tick_end() -> void:
	if not performance_profile_enabled or _profile_tick_started_usec <= 0:
		return
	_profile_tick_records.append({
		"tick_usec": Time.get_ticks_usec() - _profile_tick_started_usec,
		"systems_usec": _profile_system_usec.duplicate(true),
		"system_calls": _profile_system_calls.duplicate(true),
	})
	_profile_tick_started_usec = 0


func _profile_stamp() -> int:
	return Time.get_ticks_usec() if performance_profile_enabled else 0


func _profile_finish(system_name: String, started_usec: int, calls: int = 1) -> void:
	if not performance_profile_enabled or started_usec <= 0:
		return
	_profile_system_usec[system_name] = int(_profile_system_usec.get(system_name, 0)) + Time.get_ticks_usec() - started_usec
	_profile_system_calls[system_name] = int(_profile_system_calls.get(system_name, 0)) + calls


func _profile_scan(scan_name: String, items: int) -> void:
	if performance_profile_enabled:
		_profile_scan_items[scan_name] = int(_profile_scan_items.get(scan_name, 0)) + maxi(0, items)


func _profile_mean(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += float(value)
	return total / float(values.size())


func _profile_percentile(values: Array, ratio: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	return float(sorted[clampi(ceili(float(sorted.size()) * ratio) - 1, 0, sorted.size() - 1)])


func _profile_max(values: Array) -> float:
	var maximum := 0.0
	for value in values:
		maximum = maxf(maximum, float(value))
	return maximum


func validate_placement(building_type: String, tile: Vector2i, rotation: int = 0) -> Dictionary:
	if game_finished:
		return _failure("RunFinished", "The run has ended.")
	if not Defs.is_buildable(building_type):
		return _failure("Unsupported", "That building is not available.")
	if not is_town_hall_founded():
		if building_type != Defs.BUILDING_TOWN_HALL:
			return _failure("FoundTown", "Build the Town Hall before planning the settlement.")
		return _validate_founding_town_hall(tile)
	if building_type == Defs.BUILDING_TOWN_HALL:
		return _failure("AlreadyFounded", "Your Town Hall is already built.")
	if rivalry != null:
		if building_type == Defs.BUILDING_ROAD:
			return _validate_player_road_plan(tile)
		if building_type == Defs.BUILDING_LUMEN_PILLAR:
			return rivalry.validate_structure(RivalryTuning.PLAYER_REALM, RivalryTuning.STRUCTURE_LUMEN_PILLAR, tile)
		if building_type == Defs.BUILDING_OUTPOST:
			return rivalry.validate_structure(RivalryTuning.PLAYER_REALM, RivalryTuning.STRUCTURE_CLAIMANT_OUTPOST, tile)
	var footprint := _oriented_footprint(building_type, rotation)
	var footprint_tiles := _footprint_tiles(tile, footprint)
	if footprint_tiles.is_empty() or not _footprint_inside_map(tile, footprint):
		return _failure("OutsideMap", "That footprint extends outside the province.")
	for footprint_tile in footprint_tiles:
		if not is_revealed(footprint_tile):
			return _failure("Fog", "Unrevealed terrain. Build closer to existing structures to scout ahead, or wait for workers/soldiers to explore nearby.")
		if _enemy_camp_at_tile(footprint_tile):
			return _failure("EnemyCamp", "Clear the enemy camp before building here.")
		# Playtest.31 (T-SNS-009): check the player's own buildings first so
		# hovering your Town Hall (which is also a rivalry realm home) names it
		# instead of blaming a road or rival structure.
		var existing := get_building_at_tile(footprint_tile)
		if not existing.is_empty():
			return _failure("Occupied", "Footprint overlaps your %s. Move the ghost to an empty area." % Defs.building_name(String(existing.get("type", ""))))
		if rivalry != null and rivalry.is_rivalry_occupied(footprint_tile):
			if rivalry.owns_road(RivalryTuning.PLAYER_REALM, footprint_tile):
				return _failure("Occupied", "Footprint crosses your road. Try rotating (R) or move the ghost off the road.")
			return _failure("Occupied", "Footprint blocked by a rival road or structure. Try rotating (R) or move away from rival territory.")

	if building_type == Defs.BUILDING_QUARRY:
		if not _footprint_has_terrain(tile, footprint, Defs.TILE_ROCK):
			return _failure("Terrain", "A Quarry footprint must cover a Rock Deposit.")
	else:
		for footprint_tile in footprint_tiles:
			if not _tile_allows_clear_and_build(footprint_tile, building_type):
				return _failure("Terrain", "That footprint covers stone, the Shard, or another protected feature.")
	var trees_to_clear := _footprint_tree_tiles(tile, footprint)
	if not trees_to_clear.is_empty() and building_type == Defs.BUILDING_QUARRY:
		return _failure("Terrain", "A Quarry cannot be planned over trees.")
	if building_type not in [Defs.BUILDING_ROAD, Defs.BUILDING_WALL, Defs.BUILDING_WATCHTOWER] and _footprint_height_range(tile, footprint) > 1:
		return _failure("Slope", "This site is too steep to level. Choose a gentler terrace.")

	if building_type == Defs.BUILDING_ROAD:
		if not _has_adjacent_planned_or_connected_road(tile):
			return _failure("RoadConnection", "Roads must connect. Extend from existing road network starting at Town Hall.")
		if not _road_grade_is_valid(tile):
			return _failure("Slope", "Road too steep. Roads can climb at most 2 height steps at once.")
		if not trees_to_clear.is_empty():
			return _success("CLEARING REQUIRED — woodcutters will clear the site first.")
		return _success("Road can be planned. A free peasant will build it when time is running.")
	if building_type == Defs.BUILDING_WALL:
		if not _has_adjacent_wall_support(tile):
			return _failure("TowerFoundation", "Walls need a Watchtower anchor. Build Watchtower first, then drag walls from it.")

	var cost := Defs.building_cost(building_type)
	for resource_type in cost.keys():
		if get_available_resource(resource_type) < int(cost[resource_type]):
			return _failure(
				"Resources",
				"%s needs %s." % [Defs.building_name(building_type), Defs.formatted_cost(building_type)])
	if building_type not in [Defs.BUILDING_WALL, Defs.BUILDING_WATCHTOWER] and not _has_building_clearance(tile, footprint):
		return _failure("BuildingClearance", "Leave one clear tile between buildings for paths and work yards.")
	if building_type == Defs.BUILDING_LUMBER_CAMP and _find_nearby_deposit(_footprint_center(tile, footprint), Defs.TILE_TREE, LUMBER_REACH).x < 0:
		return _failure("NoTrees", "Lumber Camp needs trees within %d tiles." % LUMBER_REACH)

	var success_message := "%s can be built." % Defs.building_name(building_type)
	if not trees_to_clear.is_empty():
		success_message = "CLEARING REQUIRED — woodcutters will clear the site first."
	if building_type == Defs.BUILDING_WALL:
		return _success(success_message)
	if _footprint_touches_planned_or_connected_road(tile, footprint):
		return _with_placement_quality(_success(success_message), building_type, tile, rotation)
	var spur := _auto_spur_tiles(tile, footprint)
	if not spur.is_empty():
		if not trees_to_clear.is_empty():
			return _with_placement_quality(_success("CLEARING REQUIRED — a short road will also be extended."), building_type, tile, rotation)
		return _with_placement_quality(_success("Will extend a short road to this site."), building_type, tile, rotation)

	return _failure("RoadConnection", "No road access. Extend roads from Town Hall first, then place buildings beside connected roads.")


func validate_road_route(route: Array) -> Dictionary:
	var virtual_roads: Dictionary = {}
	var segments: Array[Dictionary] = []
	var first_failure := ""
	var first_failed_tile := Vector2i(-1, -1)
	for tile_value in route:
		var tile := Vector2i(tile_value)
		var key := _tile_key(tile)
		var existing := get_building_at_tile(tile)
		var existing_road := not existing.is_empty() and (
			String(existing.get("type", "")) == Defs.BUILDING_ROAD
			or (bool(existing.get("construction", false)) and String(existing.get("planned_type", "")) == Defs.BUILDING_ROAD)
		)
		if existing_road:
			virtual_roads[key] = true
			segments.append({"tile": tile, "valid": true, "reuse": true, "message": "Existing road"})
			continue
		var failure := ""
		if not is_inside_map(tile):
			failure = "Outside the province"
		elif not is_revealed(tile):
			failure = "Outside revealed territory"
		elif not _tile_allows_clear_and_build(tile, Defs.BUILDING_ROAD):
			failure = "Tree resource occupies this tile" if get_tile(tile) == Defs.TILE_TREE else "Stone deposit occupies this tile"
		elif _enemy_camp_at_tile(tile):
			failure = "Enemy camp occupies this tile"
		elif not existing.is_empty():
			failure = "Building occupies this tile"
		elif rivalry != null and rivalry.is_rivalry_occupied(tile):
			failure = "Realm structure occupies this tile"
		var connected := _has_adjacent_planned_or_connected_road(tile)
		var grade_ok := _road_grade_is_valid(tile)
		for neighbor in _neighbors(tile):
			if virtual_roads.has(_tile_key(neighbor)):
				connected = true
				if absi(get_height(tile) - get_height(neighbor)) <= 2:
					grade_ok = true
		if failure == "" and not connected:
			failure = "Disconnected from road network"
		elif failure == "" and not grade_ok:
			failure = "Too steep"
		var valid := failure == ""
		segments.append({"tile": tile, "valid": valid, "reuse": false, "message": failure})
		if not valid:
			if first_failure == "":
				first_failure = failure
				first_failed_tile = tile
			continue
		virtual_roads[key] = true
	if first_failure != "":
		return {"success": false, "segments": segments, "message": first_failure, "failed_tile": first_failed_tile}
	return {"success": not segments.is_empty(), "segments": segments, "message": "Release to plan %d road sections" % segments.size()}


func request_build(building_type: String, tile: Vector2i, rotation: int = 0) -> Dictionary:
	if building_type == Defs.BUILDING_TOWN_HALL:
		return _request_founding_town_hall(tile)
	if not is_town_hall_founded():
		var founding_failure := _failure("FoundTown", "Build the Town Hall before planning the settlement.")
		last_message = String(founding_failure["message"])
		return founding_failure
	if building_type == Defs.BUILDING_ROAD:
		var road_validation := _validate_player_road_plan(tile)
		if not bool(road_validation.get("success", false)):
			last_message = String(road_validation.get("message", "Road cannot be planned."))
			return road_validation
		return _create_player_road_plan(tile)
	if rivalry != null:
		var rivalry_result := {}
		if building_type == Defs.BUILDING_LUMEN_PILLAR:
			rivalry_result = rivalry.request_structure(RivalryTuning.PLAYER_REALM, RivalryTuning.STRUCTURE_LUMEN_PILLAR, tile)
		elif building_type == Defs.BUILDING_OUTPOST:
			rivalry_result = rivalry.request_structure(RivalryTuning.PLAYER_REALM, RivalryTuning.STRUCTURE_CLAIMANT_OUTPOST, tile)
		if not rivalry_result.is_empty():
			last_message = String(rivalry_result.get("message", ""))
		if bool(rivalry_result.get("success", false)):
			if building_type == Defs.BUILDING_OUTPOST:
				_update_objective_flag("outpost")
			if building_type == Defs.BUILDING_ROAD:
				_emit_audio("road")
			elif building_type == Defs.BUILDING_FARM:
				_emit_audio("farm_complete")
			elif building_type == Defs.BUILDING_BARRACKS:
				_emit_audio("barracks_complete")
			else:
				_emit_audio("build_complete")
			return rivalry_result
	var validation := validate_placement(building_type, tile, rotation)
	if not bool(validation["success"]):
		last_message = String(validation["message"])
		return validation

	var cost := Defs.building_cost(building_type)
	_consolidate_cost_to_central(cost)
	_reserve_cost(cost)
	var oriented := _oriented_footprint(building_type, rotation)
	if building_type not in [Defs.BUILDING_ROAD, Defs.BUILDING_WALL]:
		for spur_tile in _auto_spur_tiles(tile, oriented):
			if get_building_at_tile(spur_tile).is_empty():
				_create_player_road_plan(spur_tile)
		_level_building_site(tile, oriented)
	var site := _create_building(Defs.BUILDING_CONSTRUCTION_SITE, tile)
	site["footprint"] = _vector_to_data(_oriented_footprint(building_type, rotation))
	site["rotation"] = posmod(rotation, 4)
	var build_time := Defs.build_time(building_type)
	site["planned_type"] = building_type
	site["build_cost"] = cost
	site["construction_total"] = build_time
	site["construction_remaining"] = build_time
	site["materials_needed"] = cost.duplicate(true)
	site["materials_delivered"] = Defs.empty_inventory()
	site["materials_in_transit"] = Defs.empty_inventory()
	if building_type == Defs.BUILDING_QUARRY:
		site["deposit_remaining"] = _quarry_deposit_for_footprint(tile, _oriented_footprint(building_type, rotation))
	_mark_site_clearing(site)
	site["status"] = "CLEARING SITE" if bool(site.get("site_clearing", false)) else "Building."
	_stamp_placement_quality(site, building_type, tile, rotation)
	buildings.append(site)
	_rebuild_occupied_tiles()
	_recompute_road_network()
	_reveal_from_world()
	_add_log("Construction started: %s." % Defs.building_name(building_type))
	_record_event("construction_started", "Construction started.", {
		"building_id": int(site["id"]),
		"building_type": building_type,
		"position": _vector_to_data(tile),
		"cost": cost
	})
	_emit_audio("build_start")
	last_message = "Construction started: %s." % Defs.building_name(building_type)
	return {"success": true, "message": last_message, "building": site}


func _validate_founding_town_hall(tile: Vector2i) -> Dictionary:
	for building in buildings:
		if bool(building.get("construction", false)) and String(building.get("planned_type", "")) == Defs.BUILDING_TOWN_HALL:
			return _failure("AlreadyPlanned", "The Town Hall is already being built.")
	var footprint := Defs.building_footprint(Defs.BUILDING_TOWN_HALL)
	if not _footprint_inside_map(tile, footprint):
		return _failure("OutsideMap", "The Town Hall footprint extends outside the province.")
	for footprint_tile in _footprint_tiles(tile, footprint):
		if not is_revealed(footprint_tile):
			return _failure("Fog", "The whole Town Hall site must be visible.")
		if get_tile(footprint_tile) != Defs.TILE_GRASS or not get_building_at_tile(footprint_tile).is_empty():
			return _failure("Terrain", "Choose a clear grassland site for the Town Hall.")
	if _footprint_height_range(tile, footprint) > 1:
		return _failure("Slope", "The founding site is too steep.")
	for resource_type in Defs.building_cost(Defs.BUILDING_TOWN_HALL).keys():
		if get_available_resource(resource_type) < int(Defs.building_cost(Defs.BUILDING_TOWN_HALL)[resource_type]):
			return _failure("Resources", "The founding supplies are incomplete.")
	return _success("Build the Town Hall here. The Sovereign and both settlers will found the realm.")


func _request_founding_town_hall(tile: Vector2i) -> Dictionary:
	var validation := validate_placement(Defs.BUILDING_TOWN_HALL, tile)
	if not bool(validation.get("success", false)):
		last_message = String(validation.get("message", "Town Hall cannot be built here."))
		return validation
	var cost := Defs.building_cost(Defs.BUILDING_TOWN_HALL)
	_deduct_cost(cost)
	town_hall_position = tile
	var site := _create_building(Defs.BUILDING_CONSTRUCTION_SITE, tile)
	site["footprint"] = _vector_to_data(Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	site["planned_type"] = Defs.BUILDING_TOWN_HALL
	site["build_cost"] = cost.duplicate(true)
	site["construction_total"] = Defs.build_time(Defs.BUILDING_TOWN_HALL)
	site["construction_remaining"] = site["construction_total"]
	site["materials_needed"] = cost.duplicate(true)
	site["materials_delivered"] = cost.duplicate(true)
	site["materials_in_transit"] = Defs.empty_inventory()
	site["connected"] = true
	site["status"] = "The founding settlers are building."
	buildings.append(site)
	for worker in workers:
		if String(worker.get("type", "")) != "founder":
			continue
		worker["building_id"] = int(site["id"])
		worker["state"] = "Building"
		worker["position"] = _town_hall_entrance_tile() + (Vector2i.LEFT if int(worker["id"]) % 2 == 0 else Vector2i.RIGHT)
	_rebuild_occupied_tiles()
	last_message = "The founding settlers are raising the Town Hall."
	_add_log("Town Hall construction has begun from the founding supplies.")
	_emit_audio("build_start")
	return {"success": true, "message": last_message, "building": site}


func _validate_player_road_plan(tile: Vector2i) -> Dictionary:
	if game_finished:
		return _failure("RunFinished", "The run has ended.")
	if not is_inside_map(tile):
		return _failure("OutsideMap", "Road is outside the province.")
	if not is_revealed(tile):
		return _failure("Fog", "Scout this tile before planning a road.")
	if not _tile_allows_clear_and_build(tile, Defs.BUILDING_ROAD):
		return _failure("Terrain", "Roads cannot cover stone, the Shard, or protected features.")
	if _enemy_camp_at_tile(tile):
		return _failure("EnemyCamp", "Clear the enemy camp before planning a road here.")
	if rivalry != null and rivalry.is_rivalry_occupied(tile):
		return _failure("Occupied", "That tile is occupied by a realm structure.")
	if not get_building_at_tile(tile).is_empty():
		return _failure("Occupied", "That tile already contains a structure or plan.")
	if not _has_adjacent_planned_or_connected_road(tile):
		return _failure("RoadConnection", "Road plans must extend from the Town Hall road network.")
	if not _road_grade_is_valid(tile):
		return _failure("Slope", "Roads can climb at most two height steps.")
	return _success("Road can be planned. A free peasant will build it when time is running.")


func _create_player_road_plan(tile: Vector2i) -> Dictionary:
	var site := _create_building(Defs.BUILDING_CONSTRUCTION_SITE, tile)
	site["footprint"] = _vector_to_data(Vector2i.ONE)
	site["planned_type"] = Defs.BUILDING_ROAD
	site["build_cost"] = {}
	site["construction_total"] = ROAD_BUILD_SECONDS
	site["construction_remaining"] = ROAD_BUILD_SECONDS
	site["materials_needed"] = {}
	site["materials_delivered"] = Defs.empty_inventory()
	site["materials_in_transit"] = Defs.empty_inventory()
	site["builder_worker_id"] = 0
	_mark_site_clearing(site)
	site["status"] = "CLEARING SITE" if bool(site.get("site_clearing", false)) else "Planned — waiting for a free peasant."
	buildings.append(site)
	_rebuild_occupied_tiles()
	_recompute_road_network()
	_add_log("Road planned at %s." % format_tile(tile))
	_record_event("road_planned", "Road construction planned.", {
		"building_id": int(site["id"]),
		"position": _vector_to_data(tile)
	})
	last_message = "Road planned. Resume time so a free peasant can build it."
	return {"success": true, "message": last_message, "building": site}


func _commit_player_rivalry_road(tile: Vector2i) -> void:
	var existing := get_building_at_tile(tile)
	if not existing.is_empty():
		return
	_add_completed_building(Defs.BUILDING_ROAD, tile)
	_rebuild_occupied_tiles()
	_recompute_road_network()
	_reveal_from_world()
	_update_objectives()
	_ensure_carriers()
	path_grid_dirty = true


func _rivalry_log(message: String) -> void:
	_add_log(message)
	last_message = message


func _finish_rivalry_match(player_won: bool) -> void:
	if player_won:
		_finish_run(true, "SHARD BOUND")
	else:
		_finish_run(false, "The rival bound the Shard first.")


func set_player_sovereign_input(direction: Vector2) -> void:
	# Compatibility no-op: direct hero control was removed in Phase 3.2.
	pass


func set_player_sovereign_target(tile: Vector2i) -> Dictionary:
	return _failure("Removed", "Direct hero control is no longer part of settlement play.")


func request_player_wyrd_extraction() -> Dictionary:
	return _failure("Removed", "Outposts now harvest nearby Wyrd for the settlement.")


func request_player_sovereign_attack() -> Dictionary:
	return _failure("Removed", "Settlement guards and towers handle combat autonomously.")


func request_player_claim() -> Dictionary:
	return request_begin_binding()


func request_begin_binding() -> Dictionary:
	if rivalry == null:
		return _failure("Unavailable", "Binding is not ready.")
	var result: Dictionary = rivalry.request_begin_claim(RivalryTuning.PLAYER_REALM)
	last_message = String(result.get("message", ""))
	if bool(result.get("success", false)):
		_mark_onboarding("binding")
	return result


func has_save_file() -> bool:
	return continue_save_path() != ""


func continue_save_path() -> String:
	var selected := ""
	var newest := -1
	for path in [SAVE_PATH, AUTOSAVE_PATH]:
		for candidate in [path, path + ".bak"]:
			if FileAccess.file_exists(candidate):
				var modified := SaveStore.saved_time_usec(candidate)
				if modified > newest:
					newest = modified
					selected = path
	return selected


func get_rivalry_state() -> Dictionary:
	if rivalry == null:
		return {}
	return {
		"match_state": rivalry.match_state,
		"ai_goal": rivalry.ai_current_goal,
		"player_resources": rivalry.get_resources(RivalryTuning.PLAYER_REALM),
		"ai_resources": rivalry.get_resources(RivalryTuning.AI_REALM),
		"player_claim": rivalry.get_claim_status(RivalryTuning.PLAYER_REALM),
		"ai_claim": rivalry.get_claim_status(RivalryTuning.AI_REALM)
	}


func get_pressure_inputs() -> Dictionary:
	var wyrd_outposts := 0
	var shard_control := 0.0
	var player_binding := false
	var binding_progress := 0.0
	if rivalry != null:
		for structure in rivalry.get_structures(RivalryTuning.PLAYER_REALM):
			if String(structure.get("type", "")) != RivalryTuning.STRUCTURE_CLAIMANT_OUTPOST or int(structure.get("hp", 0)) <= 0:
				continue
			if outpost_has_wyrd_node(structure):
				wyrd_outposts += 1
			var center := Vector2(structure.get("position", Vector2i.ZERO))
			var distance := center.distance_to(Vector2(shard_position))
			if distance <= RivalryTuning.SHARD_CLAIM_RADIUS:
				shard_control = maxf(shard_control, 1.0)
			elif distance <= RivalryTuning.SHARD_BUILD_RADIUS + 4.0:
				shard_control = maxf(shard_control, 0.55)
		var claim: Dictionary = rivalry.get_claim_status(RivalryTuning.PLAYER_REALM)
		player_binding = bool(claim.get("active", false))
		binding_progress = clampf(float(claim.get("binding_progress", 0.0)) / Wyrdfall.BINDING_DURATION_SECONDS, 0.0, 1.0)
	return {
		"cumulative_wyrd_extracted": cumulative_wyrd_extracted,
		"active_wyrd_outposts": wyrd_outposts,
		"shard_control": shard_control,
		"binding_progress": binding_progress,
		"player_binding": player_binding,
		"day_count": day_count
	}


func get_wyrd_pressure() -> Dictionary:
	return Wyrdfall.compute_pressure(get_pressure_inputs())


func get_night_forecast() -> Dictionary:
	if not dusk_forecast.is_empty():
		return dusk_forecast.duplicate(true)
	return Wyrdfall.night_forecast(float(get_wyrd_pressure().get("value", 0.0)), day_count <= 1)


func get_macro_objective() -> Dictionary:
	var has_lumber := false
	var has_house := false
	var has_farm := false
	var has_watchtower := false
	var has_outpost := false
	for building in buildings:
		if bool(building.get("construction", false)):
			continue
		match String(building.get("type", "")):
			Defs.BUILDING_LUMBER_CAMP:
				has_lumber = true
			Defs.BUILDING_HOUSE:
				has_house = true
			Defs.BUILDING_FARM:
				has_farm = true
			Defs.BUILDING_WATCHTOWER:
				has_watchtower = true
			Defs.BUILDING_OUTPOST:
				has_outpost = true
	if rivalry != null:
		for structure in rivalry.get_structures(RivalryTuning.PLAYER_REALM):
			if String(structure.get("type", "")) == RivalryTuning.STRUCTURE_CLAIMANT_OUTPOST:
				has_outpost = true
	var binding_ready := false
	var binding_active := false
	if rivalry != null:
		var claim: Dictionary = rivalry.get_claim_status(RivalryTuning.PLAYER_REALM)
		binding_active = bool(claim.get("active", false))
		binding_ready = bool(Dictionary(claim.get("requirements", {})).get("ready", false))
	return Wyrdfall.macro_objective({
		"binding_active": binding_active,
		"binding_ready": binding_ready,
		"shard_control": float(get_pressure_inputs().get("shard_control", 0.0)),
		"shard_revealed": is_revealed(shard_position) or shard_contacted,
		"has_lumber": has_lumber,
		"has_house": has_house,
		"has_farm": has_farm,
		"has_watchtower": has_watchtower,
		"has_outpost": has_outpost,
		"starter_ready": has_house and has_lumber and has_farm,
		"has_road_toward_shard": _has_road_toward_shard(),
		"wyrd_total": int(central_inventory.get(Defs.RESOURCE_WYRD, 0)),
		"connected_roads": connected_roads.size()
	})


func get_wyrdfall_presentation() -> Dictionary:
	var pressure := get_wyrd_pressure()
	var player_claim := {}
	var rival_claim := {}
	var rival_line := ""
	if rivalry != null:
		player_claim = rivalry.get_claim_status(RivalryTuning.PLAYER_REALM)
		rival_claim = rivalry.get_claim_status(RivalryTuning.AI_REALM)
		rival_line = rivalry.get_rival_status_line()
	var binding_percent := int(round(clampf(float(player_claim.get("binding_progress", 0.0)) / Wyrdfall.BINDING_DURATION_SECONDS, 0.0, 1.0) * 100.0))
	var rival_percent := int(round(clampf(float(rival_claim.get("binding_progress", 0.0)) / Wyrdfall.BINDING_DURATION_SECONDS, 0.0, 1.0) * 100.0))
	return {
		"pressure": pressure,
		"pressure_tooltip": Wyrdfall.pressure_tooltip(pressure),
		"forecast": get_night_forecast(),
		"objective": get_macro_objective(),
		"binding_ready": bool(Dictionary(player_claim.get("requirements", {})).get("ready", false)) and not bool(player_claim.get("active", false)),
		"binding_active": bool(player_claim.get("active", false)),
		"binding_percent": binding_percent,
		"binding_summary": String(player_claim.get("status", "")),
		"rival_binding_active": bool(rival_claim.get("active", false)),
		"rival_binding_percent": rival_percent,
		"rival_line": rival_line,
		"reckoning": reckoning_active,
		"dawn_summary": dawn_summary.duplicate(true),
		"onboarding": _pending_onboarding_hint()
	}


func get_run_statistics() -> Dictionary:
	var summary := get_summary()
	summary["elapsed_seconds"] = elapsed_seconds
	summary["seed"] = rng_seed
	summary["population"] = population_current
	summary["peak_population"] = int(stats.get("peak_population", population_current))
	summary["wood_produced"] = int(stats.get("wood_produced", 0))
	summary["stone_produced"] = int(stats.get("stone_produced", 0))
	summary["wheat_produced"] = int(stats.get("wheat_produced", 0))
	summary["bread_produced"] = int(stats.get("bread_produced", 0))
	summary["wyrd_extracted"] = int(stats.get("wyrd_extracted", cumulative_wyrd_extracted))
	summary["peak_wyrd_pressure"] = float(stats.get("peak_wyrd_pressure", peak_wyrd_pressure))
	summary["territory_revealed"] = int(stats.get("territory_revealed", revealed_tiles.size()))
	summary["pressure_band"] = Wyrdfall.band_for_pressure(float(summary["peak_wyrd_pressure"]))
	return summary


func impact_factor(tile: Vector2i) -> float:
	var distance := _tile_distance(tile, shard_position)
	if distance <= 3.0:
		return 1.0
	if distance >= 12.0:
		return 0.0
	return clampf(1.0 - (distance - 3.0) / 9.0, 0.0, 1.0)


func get_world_features() -> Array:
	return world_features.duplicate(true)


func mark_onboarding_dismissed(hint_id: String) -> void:
	_mark_onboarding(hint_id)


func consume_dawn_summary() -> Dictionary:
	var summary := dawn_summary.duplicate(true)
	dawn_summary = {}
	return summary


func validate_clear(tile: Vector2i) -> Dictionary:
	if not is_inside_map(tile) or not is_revealed(tile):
		return _failure("Fog", "Scout this tile before clearing it.")
	if not _tile_is_clearable_tree(tile) and String(get_tile(tile)) != Defs.TILE_ROCK:
		return _failure("Terrain", "Select a tree or rock deposit to clear.")
	if is_tile_occupied(tile) and not _site_requires_tree(tile):
		return _failure("Occupied", "A structure already occupies this tile.")
	if workers_free() <= _clearer_count():
		return _failure("Workers", "No free worker. Build a House and keep food available so population can grow, or lower another workplace's priority.")
	for worker in workers:
		if String(worker.get("type", "")) == "clearer" and worker.get("clear_target", Vector2i(-1, -1)) == tile:
			return _failure("Ordered", "A worker is already clearing this tile.")
	return _success("Send a worker to clear this tile.")


func request_outpost_assault(structure_id: int) -> Dictionary:
	if game_finished:
		return _failure("RunFinished", "The run has ended.")
	var target := _assault_outpost(structure_id)
	if target.is_empty():
		return _failure("Target", "Choose a visible rival Outpost.")
	var sent := 0
	for worker in workers:
		if String(worker.get("type", "")) != "guard" or int(worker.get("building_id", 0)) != 0 or int(worker.get("hp", 0)) <= 0:
			continue
		var route := _outpost_assault_route(worker, target)
		if not bool(route.get("success", false)):
			continue
		worker["assault_target_id"] = structure_id
		worker["path"] = route.path
		worker["state"] = "Marching to rival Outpost"
		worker["arrival_state"] = "Assaulting Outpost"
		worker["manual_order"] = false
		sent += 1
	if sent == 0:
		return _failure("Soldiers", "Train free patrol soldiers at a Barracks and open a route to this Outpost. Tower sentries stay at their posts.")
	last_message = "%d patrol soldiers ordered to assault the rival Outpost. They remain vulnerable while away." % sent
	_record_event("outpost_assault_order", last_message, {"structure_id": structure_id, "soldiers": sent})
	return _success(last_message)


func recall_assault_soldiers() -> Dictionary:
	var recalled := 0
	for worker in workers:
		if int(worker.get("assault_target_id", 0)) <= 0:
			continue
		worker.erase("assault_target_id")
		worker["combat_target_structure_id"] = 0
		worker["attack_flash"] = 0.0
		worker["attack_damage_applied"] = true
		worker["path"] = _find_worker_path(worker.position, _town_hall_entrance_tile())
		worker["state"] = "Returning to town"
		worker["arrival_state"] = "Patrolling"
		recalled += 1
	return _success("%d soldiers recalled to the settlement." % recalled)


func _assault_outpost(structure_id: int) -> Dictionary:
	if rivalry == null:
		return {}
	var target: Dictionary = rivalry._structure_by_id(structure_id)
	if target.is_empty() or String(target.get("realm_id", "")) != RivalryTuning.AI_REALM or String(target.get("type", "")) != Defs.BUILDING_OUTPOST or int(target.get("hp", 0)) <= 0:
		return {}
	if not is_revealed(target.position):
		return {}
	return target


func _outpost_distance(tile: Vector2i, target: Dictionary) -> int:
	var closest := 9999
	for occupied in _footprint_tiles(target.position, target.get("footprint", Vector2i(2, 2))):
		closest = mini(closest, _manhattan(tile, occupied))
	return closest


func _outpost_assault_route(worker: Dictionary, target: Dictionary) -> Dictionary:
	if _outpost_distance(worker.position, target) <= 1:
		return {"success": true, "path": []}
	var best: Array = []
	for occupied in _footprint_tiles(target.position, target.get("footprint", Vector2i(2, 2))):
		for tile in _neighbors(occupied):
			if not is_revealed(tile) or not _is_worker_walkable(tile) or rivalry.is_rivalry_occupied(tile):
				continue
			var path := _find_worker_path(worker.position, tile)
			if not path.is_empty() and (best.is_empty() or path.size() < best.size()):
				best = path
	return {"success": not best.is_empty(), "path": best}


func request_worker_order(worker_id: int, tile: Vector2i) -> Dictionary:
	if not is_inside_map(tile) or not is_revealed(tile):
		return _failure("Fog", "That destination has not been scouted.")
	var worker: Dictionary = _find_worker_by_id(worker_id)
	if worker.is_empty():
		return _failure("Worker", "That settler is no longer available.")
	if String(worker.get("state", "")) == "Inside Town Hall":
		return _failure("Intro", "Wait for the settler to step into the clearing.")
	if int(worker.get("carried_amount", 0)) > 0:
		return _failure("Delivery", "Let this settler deliver the carried goods before giving another order.")
	if String(worker.get("type", "")) == "clearer" and String(worker.get("return_type", "")) == "retire":
		return _failure("Clearing", "This clearing crew is already assigned. Cancel its current order before issuing a new clearing request.")
	var terrain: String = String(get_tile(tile))
	if terrain in [Defs.TILE_TREE, Defs.TILE_ROCK]:
		if is_tile_occupied(tile) and not _site_requires_tree(tile):
			return _failure("Occupied", "A structure blocks that resource.")
		var worker_position := Vector2i(worker.get("position", tile))
		var work_tile: Vector2i = _nearest_tree_work_tile(worker_position, tile)
		if work_tile.x < 0:
			return _failure("Path", "No walkable position reaches that resource.")
		var path: Array = _find_worker_path(worker_position, work_tile)
		if worker_position != work_tile and path.is_empty():
			return _failure("Path", "No walkable route reaches that resource.")
		_clear_worker(worker)
		if String(worker.get("type", "")) != "clearer":
			worker["return_type"] = String(worker.get("type", "carrier"))
			worker["return_capacity"] = int(worker.get("capacity", 5))
		worker["type"] = "clearer"
		worker["clear_target"] = tile
		worker["work_position"] = work_tile
		worker["path"] = path
		worker["state"] = "Walking to gather"
		worker["arrival_state"] = "Gathering"
		worker["activity_timer"] = 3.2
		worker["manual_order"] = true
		worker["reaction"] = "!"
		worker["reaction_until"] = elapsed_seconds + 0.8
		last_message = "Order accepted: gather %s." % ("wood" if terrain == Defs.TILE_TREE else "stone")
		_add_log(last_message)
		_emit_audio("soldier")
		return _success(last_message)
	if terrain == Defs.TILE_GRASS and not is_tile_occupied(tile):
		var move_worker_position := Vector2i(worker.get("position", tile))
		var move_path: Array = _find_worker_path(move_worker_position, tile)
		if move_worker_position != tile and move_path.is_empty():
			return _failure("Path", "No walkable route reaches that position.")
		# Clear a previous delivery reservation only after the new order is valid.
		_clear_worker(worker)
		if String(worker.get("type", "")) == "clearer":
			worker["type"] = String(worker.get("return_type", "carrier"))
			worker["capacity"] = int(worker.get("return_capacity", 5))
			worker.erase("clear_target")
			worker.erase("work_position")
		worker["path"] = move_path
		worker["state"] = "Moving by order"
		worker["arrival_state"] = "Awaiting order"
		worker["manual_order"] = true
		worker["reaction"] = "!"
		worker["reaction_until"] = elapsed_seconds + 0.8
		last_message = "Order accepted: move there."
		return _success(last_message)
	return _failure("Order", "Choose open ground, a tree, or a stone deposit.")


func is_patrol_scout(worker: Dictionary) -> bool:
	return String(worker.get("type", "")) == "guard" and int(worker.get("building_id", 0)) == 0 and int(worker.get("hp", 0)) > 0


func request_scout_direction(worker_id: int, target_tile: Vector2i) -> Dictionary:
	var worker: Dictionary = _find_worker_by_id(worker_id)
	if worker.is_empty() or not is_patrol_scout(worker):
		return _failure("Scout", "Select a free patrol soldier to scout.")
	if int(worker.get("assault_target_id", 0)) > 0:
		return _failure("Scout", "That soldier is already on an assault.")
	if worker.has("scout_mission"):
		return _failure("Scout", "%s is already scouting." % Scout.display_name(worker, rng_seed))
	if not is_inside_map(target_tile):
		return _failure("Scout", "Click a direction on the map.")
	if int(central_inventory.get(Defs.RESOURCE_BREAD, 0)) < Scout.FOOD_COST:
		return _failure("Food", "Scouting costs %d Bread. Bake or store food first." % Scout.FOOD_COST)
	central_inventory[Defs.RESOURCE_BREAD] = int(central_inventory.get(Defs.RESOURCE_BREAD, 0)) - Scout.FOOD_COST
	var home: Vector2i = _town_hall_entrance_tile()
	var origin: Vector2i = worker["position"]
	var bearing := Vector2(target_tile - origin)
	if bearing.length_squared() < 0.01:
		bearing = Vector2(target_tile - home)
	if bearing.length_squared() < 0.01:
		bearing = Vector2.RIGHT
	bearing = bearing.normalized()
	worker["display_name"] = Scout.display_name(worker, rng_seed)
	worker["scout_mission"] = {
		"home": home,
		"target": target_tile,
		"direction": {"x": bearing.x, "y": bearing.y},
		"depth_limit": Scout.DEPTH_LIMIT,
		"returning": false,
		"return_reason": "",
		"tiles_at_start": revealed_tiles.size()
	}
	worker["manual_order"] = true
	worker["state"] = "Scouting"
	worker["arrival_state"] = "Scouting"
	_assign_scout_leg(worker)
	last_message = "%s scouts toward the fog." % String(worker["display_name"])
	_add_log(last_message)
	_record_event("scout_order", last_message, {"worker_id": worker_id, "target": _vector_to_data(target_tile)})
	return _success(last_message)


func request_scout_auto(worker_id: int) -> Dictionary:
	# The Director: Y and SCOUT send the selected free guard into the nearest
	# unexplored fog. No second click. He reveals as he walks and can be killed.
	var worker: Dictionary = _find_worker_by_id(worker_id)
	if worker.is_empty() or not is_patrol_scout(worker):
		return _failure("Scout", "Select a free patrol soldier to scout.")
	if int(worker.get("assault_target_id", 0)) > 0:
		return _failure("Scout", "That soldier is already on an assault.")
	if worker.has("scout_mission"):
		return _failure("Scout", "%s is already scouting." % Scout.display_name(worker, rng_seed))
	var target := _nearest_scout_fog_tile(worker.get("position", _town_hall_entrance_tile()))
	if not is_inside_map(target) or is_revealed(target):
		return _failure("Scout", "No unexplored fog nearby.")
	return request_scout_direction(worker_id, target)


func _nearest_scout_fog_tile(origin: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_distance := 1000000
	for y in range(map_size.y):
		for x in range(map_size.x):
			var tile := Vector2i(x, y)
			if is_revealed(tile):
				continue
			var distance := _manhattan(origin, tile)
			if distance <= 0 or distance >= best_distance:
				continue
			best = tile
			best_distance = distance
	return best


func get_map_markers() -> Array:
	return map_markers.duplicate(true)


func add_map_marker(kind: String, tile: Vector2i, title: String, until_elapsed: float = 0.0) -> void:
	map_markers.append({
		"kind": kind,
		"position": tile,
		"title": title,
		"until": until_elapsed
	})


func cancel_worker_order(worker_id: int) -> Dictionary:
	var worker: Dictionary = _find_worker_by_id(worker_id)
	if worker.is_empty():
		return _failure("Worker", "That settler is no longer available.")
	if int(worker.get("carried_amount", 0)) > 0:
		return _failure("Delivery", "Let this settler deliver the carried goods before cancelling the order.")
	_clear_worker(worker)
	if String(worker.get("type", "")) == "clearer":
		var return_type := String(worker.get("return_type", "carrier"))
		if return_type == "retire":
			workers.erase(worker)
		else:
			worker["type"] = return_type
			worker["capacity"] = int(worker.get("return_capacity", 5))
	worker["manual_order"] = false
	worker.erase("clear_target")
	worker.erase("work_position")
	worker.erase("scout_mission")
	last_message = "Order cancelled."
	return _success(last_message)


func _find_worker_by_id(worker_id: int) -> Dictionary:
	for worker in workers:
		if int(worker.get("id", 0)) == worker_id:
			return worker
	return {}


func _clearer_count() -> int:
	var count := 0
	for worker in workers:
		if String(worker.get("type", "")) == "clearer":
			count += 1
	return count


func request_clear(tile: Vector2i) -> Dictionary:
	var validation := validate_clear(tile)
	if not bool(validation.get("success", false)):
		last_message = String(validation.get("message", "Cannot clear this tile."))
		return validation
	var spawn := _first_connected_road_tile()
	if not is_inside_map(spawn):
		spawn = _town_hall_entrance_tile()
	var path := _find_worker_path(spawn, tile)
	if spawn != tile and path.is_empty():
		last_message = "No walkable route reaches this tile."
		return _failure("Path", last_message)
	workers.append({
		"id": next_worker_id,
		"type": "clearer",
		"building_id": 0,
		"role_key": "clear:%s" % _tile_key(tile),
		"return_type": "retire",
		"position": spawn,
		"path": path,
		"state": "Walking to clear land",
		"arrival_state": "Clearing land",
		"move_elapsed": 0.0,
		"activity_timer": 2.5,
		"clear_target": tile,
		"capacity": 0,
		"carried_resource": "",
		"carried_amount": 0,
		"task": {},
		"shelter_position": Vector2i(-1, -1),
		"hp": WORKER_MAX_HP,
		"max_hp": WORKER_MAX_HP,
		"hungry": false
	})
	next_worker_id += 1
	last_message = "Worker sent to clear %s." % format_tile(tile)
	_add_log(last_message)
	return _success(last_message)


func request_clear_area(tiles: Array) -> Dictionary:
	var marked := 0
	for tile_value in tiles:
		var tile := Vector2i(tile_value)
		if not _tile_is_clearable_tree(tile):
			continue
		if is_tile_occupied(tile) and not _site_requires_tree(tile):
			continue
		priority_clear_tiles[_tile_key(tile)] = 8
		marked += 1
	if marked <= 0:
		last_message = "No harvestable trees in that area."
		return _failure("Empty", last_message)
	_assign_idle_workers_to_priority_clears()
	last_message = "Clearing %d trees." % marked
	_add_log(last_message)
	push_notice("construction", "CLEARING", "Woodcutters will clear the marked trees.", "info")
	return _success(last_message)


func push_notice(category: String, title: String, body: String, severity: String = "info") -> Dictionary:
	var notice := {
		"id": next_notice_id,
		"category": category,
		"title": title,
		"body": body,
		"severity": severity,
		"time": elapsed_seconds,
		"day": day_count
	}
	next_notice_id += 1
	pending_notices.append(notice)
	notice_log.append(notice)
	while notice_log.size() > NOTICE_LOG_LIMIT:
		notice_log.pop_front()
	return notice


func consume_pending_notices() -> Array:
	var notices := pending_notices.duplicate(true)
	pending_notices.clear()
	return notices


func get_notice_log() -> Array:
	return notice_log.duplicate(true)


func _notice_if_new(title: String, body: String, category: String, cooldown_seconds: float, severity: String = "warning") -> void:
	for notice in notice_log:
		if String(notice.get("title", "")) == title and elapsed_seconds - float(notice.get("time", -999.0)) < cooldown_seconds:
			return
	push_notice(category, title, body, severity)


func _emit_routine_notices() -> void:
	for building in buildings:
		var status := String(building.get("status", "")).to_lower()
		if "storage full" in status:
			_notice_if_new("STORAGE FULL", "Build a Storehouse or free capacity.", "economy", 48.0)
			_offer_onboarding("storehouse_needed", "STOREHOUSE ADDS STORAGE. Build one to expand capacity for all resources. Farm→Bakery produces Bread to feed the settlement.")
		if String(building.get("type", "")) == Defs.BUILDING_BAKERY and "waiting for wheat" in status:
			var wheat_elsewhere := get_available_resource(Defs.RESOURCE_WHEAT) > int(building.get("local_inventory", {}).get(Defs.RESOURCE_WHEAT, 0))
			_notice_if_new("BAKERY STALLED", "Wheat is at the Farm — carriers will haul it." if wheat_elsewhere else "Needs Wheat.", "economy", 48.0)
		if bool(building.get("construction", false)) and "clearing site" in status:
			_notice_if_new("CLEARING SITE", "Woodcutters are opening the building footprint.", "construction", 20.0, "info")
	if int(get_building_at_tile(town_hall_position).get("hp", 1)) < int(get_building_at_tile(town_hall_position).get("max_hp", 1)):
		_notice_if_new("TOWN HALL UNDER ATTACK", "Defenders to the Town Hall.", "danger", 24.0, "critical")


func _tile_allows_clear_and_build(tile: Vector2i, building_type: String) -> bool:
	var terrain := String(get_tile(tile))
	if terrain == Defs.TILE_GRASS:
		return true
	if terrain == Defs.TILE_TREE:
		return building_type != Defs.BUILDING_QUARRY
	return false


func _tile_is_clearable_tree(tile: Vector2i) -> bool:
	return String(get_tile(tile)) == Defs.TILE_TREE


func _footprint_tree_tiles(anchor: Vector2i, footprint: Vector2i) -> Array[Vector2i]:
	var trees: Array[Vector2i] = []
	for footprint_tile in _footprint_tiles(anchor, footprint):
		if _tile_is_clearable_tree(footprint_tile):
			trees.append(footprint_tile)
	return trees


func _mark_site_clearing(site: Dictionary) -> void:
	_sync_site_clearing(site, true)


func _sync_site_clearing(site: Dictionary, auto_assign: bool = true) -> bool:
	var old_keys: Array = site.get("clear_tiles", [])
	var trees := _footprint_tree_tiles(Vector2i(site.get("position", Vector2i.ZERO)), _building_footprint(site))
	var keys: Array[String] = []
	for tree in trees:
		var key := _tile_key(tree)
		keys.append(key)
		priority_clear_tiles[key] = maxi(int(priority_clear_tiles.get(key, 0)), 10)
	site["clear_tiles"] = keys
	site["site_clearing"] = not keys.is_empty()
	if bool(site["site_clearing"]):
		site["status"] = "CLEARING SITE"
		if auto_assign:
			_assign_idle_workers_to_priority_clears()
		return true
	for old_key in old_keys:
		var key := String(old_key)
		if keys.has(key):
			continue
		if int(priority_clear_tiles.get(key, 0)) == 10:
			priority_clear_tiles.erase(key)
	return false


func _site_requires_tree(tile: Vector2i) -> bool:
	var building := get_building_at_tile(tile)
	if building.is_empty() or not bool(building.get("construction", false)):
		return false
	return _tile_is_clearable_tree(tile)


func _assign_idle_workers_to_priority_clears() -> void:
	var targets := _priority_clear_targets()
	if targets.is_empty():
		return
	for worker in workers:
		if targets.is_empty():
			return
		if String(worker.get("type", "")) in ["carrier", "clearer", "guard"]:
			continue
		if int(worker.get("building_id", 0)) != 0:
			continue
		if String(worker.get("state", "")) not in ["Idle", "Awaiting order", "Waiting", ""]:
			continue
		var target: Vector2i = targets.pop_front()
		var work_tile := _nearest_tree_work_tile(Vector2i(worker.get("position", target)), target)
		if work_tile.x < 0:
			work_tile = target
		var path := _find_worker_path(Vector2i(worker.get("position", target)), work_tile)
		if Vector2i(worker.get("position", target)) != work_tile and path.is_empty():
			continue
		worker["return_type"] = String(worker.get("type", "carrier"))
		worker["return_capacity"] = int(worker.get("capacity", 0))
		worker["type"] = "clearer"
		worker["clear_target"] = target
		worker["work_position"] = work_tile
		worker["path"] = path
		worker["state"] = "Walking to gather"
		worker["arrival_state"] = "Gathering"
		worker["activity_timer"] = 2.4
		worker["manual_order"] = false
	while not targets.is_empty() and workers_free() > 0 and _clearer_count() < 6:
		var spawned := request_clear(targets.pop_front())
		if not bool(spawned.get("success", false)):
			break


func _priority_clear_targets() -> Array[Vector2i]:
	var assigned: Dictionary = {}
	for worker in workers:
		if String(worker.get("type", "")) == "clearer":
			assigned[_tile_key(Vector2i(worker.get("clear_target", Vector2i(-1, -1))))] = true
	var ranked: Array[Dictionary] = []
	for key_value in priority_clear_tiles.keys():
		var key := String(key_value)
		if assigned.has(key):
			continue
		var tile := _tile_from_key(key)
		if not _tile_is_clearable_tree(tile):
			priority_clear_tiles.erase(key)
			continue
		ranked.append({"tile": tile, "priority": int(priority_clear_tiles.get(key, 0))})
	ranked.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return int(left.get("priority", 0)) > int(right.get("priority", 0))
	)
	var tiles: Array[Vector2i] = []
	for item in ranked:
		tiles.append(item["tile"])
	return tiles


func _priority_tree_in_lumber_reach(building: Dictionary) -> bool:
	var tile := _find_nearby_deposit(_footprint_center(building["position"], _building_footprint(building)), Defs.TILE_TREE, LUMBER_REACH)
	return tile.x >= 0 and int(priority_clear_tiles.get(_tile_key(tile), 0)) > 0


func _starter_economy_ready() -> bool:
	var has_house := false
	var has_lumber := false
	var has_farm := false
	for building in buildings:
		if bool(building.get("construction", false)):
			continue
		match String(building.get("type", "")):
			Defs.BUILDING_HOUSE:
				has_house = true
			Defs.BUILDING_LUMBER_CAMP:
				has_lumber = true
			Defs.BUILDING_FARM:
				has_farm = true
	return has_house and has_lumber and has_farm


func _has_road_toward_shard() -> bool:
	if connected_roads.size() < 6:
		return false
	var town := _footprint_center(town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	var best := 100000
	for key_value in connected_roads.keys():
		var tile := _tile_from_key(String(key_value))
		best = mini(best, _manhattan(tile, shard_position))
	return best < _manhattan(town, shard_position) - 3


func request_demolish(tile: Vector2i) -> Dictionary:
	var building := get_building_at_tile(tile)
	if building.is_empty():
		last_message = "Nothing to demolish here."
		return _failure("Empty", last_message)
	if building["type"] == Defs.BUILDING_TOWN_HALL:
		last_message = "The Town Hall cannot be demolished."
		return _failure("TownHall", last_message)

	_destroy_building_by_id(int(building["id"]), "demolished", false)
	last_message = "Demolished %s." % _display_building_name(building)
	return _success(last_message)


func restaff_building(building_id: int) -> Dictionary:
	var building := _find_building_by_id(building_id)
	if building.is_empty():
		return _failure("Missing", "That building no longer exists.")
	if String(building.get("type", "")) == Defs.BUILDING_WATCHTOWER:
		if int(building.get("soldiers_assigned", 0)) >= 1:
			return _failure("Staffed", "That tower already has a soldier.")
		if soldiers_available() <= 0:
			last_message = "Train a soldier at a Barracks before restaffing this tower."
			return _failure("Soldiers", last_message)
		building["soldiers_assigned"] = 1
		building["staffed"] = true
		building["status"] = "Watching."
		_sync_production_workers()
		_add_log("A trained soldier has taken watch in the tower.")
		last_message = "Watchtower restaffed."
		return _success(last_message)
	var staff_needed := Defs.building_staff(String(building["type"]))
	if staff_needed <= 0:
		return _failure("NoStaff", "That building does not need workers.")
	if int(building.get("assigned_staff", 0)) >= staff_needed:
		return _failure("Staffed", "That building is already staffed.")
	if workers_free() < staff_needed - int(building.get("assigned_staff", 0)):
		last_message = "Not enough free population to restaff."
		return _failure("Population", last_message)

	building["staffing_enabled"] = true
	_try_staff_building(building)
	_sync_production_workers()
	_add_log("%s restaffed." % _display_building_name(building))
	last_message = "%s restaffed." % _display_building_name(building)
	return _success(last_message)


func cycle_staff_priority(building_id: int) -> Dictionary:
	var building := _find_building_by_id(building_id)
	if building.is_empty() or Defs.building_staff(String(building.get("type", ""))) <= 0:
		return _failure("NoStaff", "That building has no staffing priority.")
	var priority := (int(building.get("staff_priority", STAFF_PRIORITY_NORMAL)) + 1) % 3
	building["staff_priority"] = priority
	_rebalance_staffing()
	var label := staff_priority_name(priority)
	last_message = "%s priority set to %s." % [_display_building_name(building), label]
	_record_event("staff_priority", last_message, {"building_id": building_id, "priority": priority})
	return _success(last_message)


func staff_priority_name(priority: int) -> String:
	if priority >= STAFF_PRIORITY_HIGH:
		return "High"
	if priority <= STAFF_PRIORITY_LOW:
		return "Low"
	return "Normal"


func save_to_file() -> bool:
	return save_to_path(SAVE_PATH)


func save_to_path(path: String) -> bool:
	var result := SaveStore.write_save(path, _serialize_state())
	last_message = String(result.get("message", "Save failed."))
	if bool(result.get("success", false)):
		_add_log("Run saved.")
	return bool(result.get("success", false))


func load_from_file() -> bool:
	return load_from_path(SAVE_PATH)


func load_from_path(path: String) -> bool:
	var result := SaveStore.read_save(path)
	if not bool(result.get("success", false)):
		last_message = String(result.get("message", "Load failed."))
		return false
	_restore_state(result.data)
	last_message = "Recovered the previous valid save." if result.get("recovered", false) else "Run loaded."
	_add_log("Run loaded.")
	return true


func get_resources() -> Dictionary:
	var resources := central_inventory.duplicate(true)
	for building in buildings:
		if bool(building.get("construction", false)):
			continue
		var local_inventory: Dictionary = building.get("local_inventory", {})
		for resource_type in Defs.RESOURCE_TYPES:
			resources[resource_type] = int(resources.get(resource_type, 0)) + int(local_inventory.get(resource_type, 0))
	for worker in workers:
		var carried_resource := String(worker.get("carried_resource", ""))
		if carried_resource in Defs.RESOURCE_TYPES:
			resources[carried_resource] = int(resources.get(carried_resource, 0)) + int(worker.get("carried_amount", 0))
	resources[Defs.RESOURCE_POPULATION_USED] = population_current
	resources[Defs.RESOURCE_POPULATION_MAX] = housing_capacity
	resources[Defs.RESOURCE_WORKERS_FREE] = workers_free()
	resources[Defs.RESOURCE_WORKERS_ASSIGNED] = workers_assigned
	resources["soldiers"] = soldiers_total
	return resources


func get_storage_limit(resource_type: String) -> int:
	var limit := int(Defs.BASE_STORAGE_LIMITS.get(resource_type, 0))
	for building in buildings:
		if String(building.get("type", "")) == Defs.BUILDING_STOREHOUSE and not bool(building.get("construction", false)):
			limit += int(Defs.STOREHOUSE_BONUS.get(resource_type, 0))
	if resource_type != Defs.RESOURCE_WYRD:
		limit += TOWN_HALL_OVERFLOW
	return limit


func get_storage_limits() -> Dictionary:
	var limits := {}
	for resource_type in Defs.RESOURCE_TYPES:
		var local_output_capacity := 0
		for building in buildings:
			if bool(building.get("construction", false)):
				continue
			var building_type := String(building.get("type", ""))
			if not Defs.PRODUCTION_DEFS.has(building_type):
				continue
			var definition: Dictionary = Defs.PRODUCTION_DEFS[building_type]
			if String(definition.get("output", "")) == resource_type:
				local_output_capacity += int(building.get("local_capacity", 0))
		var total_on_hand := int(get_resources().get(resource_type, 0))
		var storehouse_bonus := get_storage_limit(resource_type) - int(Defs.BASE_STORAGE_LIMITS.get(resource_type, 0))
		var displayed_capacity := local_output_capacity + storehouse_bonus if local_output_capacity > 0 else get_storage_limit(resource_type)
		limits[resource_type] = maxi(total_on_hand, displayed_capacity)
	return limits


func get_storage_room(resource_type: String) -> int:
	return maxi(0, get_storage_limit(resource_type) - int(central_inventory.get(resource_type, 0)) - _incoming_to_central(resource_type))


func get_protection_sources() -> Array:
	var sources: Array = []
	if is_town_hall_founded():
		sources.append({
			"kind": "Town Hall",
			"center": Vector2(_footprint_center(town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))),
			"radius": TOWN_HALL_PROTECTION_RADIUS,
			"powered": protection_powered
		})
	for building in buildings:
		if bool(building.get("construction", false)) or String(building.get("type", "")) != Defs.BUILDING_WATCHTOWER:
			continue
		if int(building.get("hp", 0)) <= 0 or not bool(building.get("connected", false)):
			continue
		sources.append({
			"kind": "Watchtower",
			"center": Vector2(_footprint_center(building["position"], _building_footprint(building))),
			"radius": TOWER_PROTECTION_RADIUS,
			"powered": protection_powered
		})
	if rivalry != null:
		for structure in rivalry.get_structures():
			if String(structure.get("realm_id", "")) != RivalryTuning.PLAYER_REALM \
				or String(structure.get("type", "")) != RivalryTuning.STRUCTURE_CLAIMANT_OUTPOST \
				or int(structure.get("hp", 0)) <= 0:
				continue
			var footprint: Vector2i = structure.get("footprint", Vector2i(2, 2))
			var center := Vector2(structure.get("position", Vector2i.ZERO)) + Vector2(float(footprint.x - 1) * 0.5, float(footprint.y - 1) * 0.5)
			sources.append({
				"kind": "Outpost",
				"center": center,
				"radius": OUTPOST_PROTECTION_RADIUS,
				"powered": protection_powered
			})
	return sources


func is_tile_protected(tile: Vector2i) -> bool:
	if not protection_powered:
		return false
	for source in get_protection_sources():
		if Vector2(tile).distance_to(Vector2(source.get("center", Vector2.ZERO))) <= float(source.get("radius", 0.0)):
			return true
	return false


func get_wyrd_upkeep_per_minute() -> float:
	if not is_town_hall_founded():
		return 0.0
	var upkeep := WYRD_BASE_UPKEEP_PER_MINUTE
	for source in get_protection_sources():
		match String(source.get("kind", "")):
			"Outpost":
				upkeep += WYRD_OUTPOST_UPKEEP_PER_MINUTE
			"Watchtower":
				upkeep += WYRD_TOWER_UPKEEP_PER_MINUTE
	return upkeep


func outpost_has_wyrd_node(structure: Dictionary) -> bool:
	if rivalry == null:
		return false
	var footprint: Vector2i = structure.get("footprint", Vector2i(2, 2))
	var center := Vector2(structure.get("position", Vector2i.ZERO)) + Vector2(float(footprint.x - 1) * 0.5, float(footprint.y - 1) * 0.5)
	for site in rivalry.get_wyrd_sites():
		if center.distance_to(Vector2(site.get("position", Vector2i.ZERO))) <= WYRD_OUTPOST_HARVEST_RADIUS:
			return true
	return false


func _update_wyrd_network(delta: float) -> void:
	if rivalry == null or not is_town_hall_founded():
		protection_powered = false
		return
	_update_outpost_wyrd_harvest(delta)
	_update_player_settlement_claim()
	var was_powered := protection_powered
	protection_powered = int(central_inventory.get(Defs.RESOURCE_WYRD, 0)) > 0
	if is_night and protection_powered:
		wyrd_upkeep_progress += get_wyrd_upkeep_per_minute() * delta / 60.0
		while wyrd_upkeep_progress >= 1.0 and int(central_inventory.get(Defs.RESOURCE_WYRD, 0)) > 0:
			central_inventory[Defs.RESOURCE_WYRD] = int(central_inventory.get(Defs.RESOURCE_WYRD, 0)) - 1
			wyrd_upkeep_progress -= 1.0
		protection_powered = int(central_inventory.get(Defs.RESOURCE_WYRD, 0)) > 0
	elif not is_night:
		wyrd_upkeep_progress = 0.0
	if was_powered and not protection_powered:
		_add_log("The Wyrd reserve is empty. Every protection bubble has collapsed.")
		last_message = "DANGER - the Wyrd protection bubbles are down."
	elif not was_powered and protection_powered:
		_add_log("Wyrd power returns. The protection bubbles reform.")


func _update_player_settlement_claim() -> void:
	if rivalry == null:
		return
	var status: Dictionary = rivalry.get_claim_status(RivalryTuning.PLAYER_REALM)
	if bool(status.get("active", false)):
		return
	var requirements: Dictionary = status.get("requirements", {})
	if bool(requirements.get("ready", false)):
		_offer_onboarding("binding", "The Shard can be Bound. This will wake a violent Reckoning.")
		if last_message.find("Begin Shard Binding") < 0:
			last_message = "The Shard is ready. Begin Shard Binding when the realm can hold."


func _update_outpost_wyrd_harvest(delta: float) -> void:
	for structure in rivalry.get_structures():
		if String(structure.get("realm_id", "")) != RivalryTuning.PLAYER_REALM \
			or String(structure.get("type", "")) != RivalryTuning.STRUCTURE_CLAIMANT_OUTPOST \
			or int(structure.get("hp", 0)) <= 0:
			continue
		if not outpost_has_wyrd_node(structure):
			structure["wyrd_harvest_progress"] = 0.0
			continue
		structure["wyrd_harvest_progress"] = float(structure.get("wyrd_harvest_progress", 0.0)) + delta
		while float(structure["wyrd_harvest_progress"]) >= WYRD_OUTPOST_HARVEST_SECONDS:
			structure["wyrd_harvest_progress"] = float(structure["wyrd_harvest_progress"]) - WYRD_OUTPOST_HARVEST_SECONDS
			rivalry.add_resource(RivalryTuning.PLAYER_REALM, Defs.RESOURCE_WYRD, 1)
			_note_wyrd_extracted(1, "extraction")
			_update_objective_flag("wyrd")
			_add_log("An Outpost harvested 1 Wyrd from a nearby node.")


func get_height(tile: Vector2i) -> int:
	if not is_inside_map(tile) or height_map.is_empty():
		return 0
	return int(height_map[tile.y][tile.x])


func get_enemy_camps() -> Array:
	return enemy_camps.duplicate(true)


func get_hidden_threat_level() -> int:
	return hidden_threat_level


func soldiers_assigned() -> int:
	var total := 0
	for building in buildings:
		total += int(building.get("soldiers_assigned", 0))
	return total


func soldiers_available() -> int:
	return maxi(0, soldiers_total - soldiers_assigned())


func consume_audio_events() -> Array[String]:
	var events := audio_events.duplicate()
	audio_events.clear()
	return events


func get_reserved_resources() -> Dictionary:
	return reserved_inventory.duplicate(true)


func get_buildings() -> Array:
	return buildings.duplicate(true)


func get_workers() -> Array:
	return workers.duplicate(true)


func get_decorative_props() -> Array:
	return decorative_props.duplicate(true)


func get_sheltered_worker_count() -> int:
	var count := 0
	for worker in workers:
		if String(worker.get("state", "")) == "Sheltered":
			count += 1
	return count


func get_shelterable_worker_count() -> int:
	var count := 0
	for worker in workers:
		if String(worker.get("type", "")) != "guard":
			count += 1
	return count


func get_hungry_population() -> int:
	return hungry_population


func is_hunger_penalty_active() -> bool:
	return hunger_penalty_remaining > 0.0 and hungry_population > 0


func get_hunger_recovery_fraction() -> float:
	if not is_hunger_penalty_active():
		return 0.0
	return clampf(hunger_penalty_remaining / (DAY_LENGTH_SECONDS * HUNGER_RECOVERY_FRACTION), 0.0, 1.0)


func get_food_units() -> int:
	return int(central_inventory.get(Defs.RESOURCE_BREAD, 0)) + int(floor(float(central_inventory.get(Defs.RESOURCE_WHEAT, 0)) / 2.0))


func get_next_food_demand() -> int:
	return population_current


func get_worker_step_seconds(worker: Dictionary) -> float:
	if worker.get("path", []).is_empty():
		return CARRIER_STEP_SECONDS if String(worker.get("type", "")) == "carrier" else LABORER_STEP_SECONDS
	return _worker_step_seconds(worker, worker["path"][0])


func get_enemy_step_seconds(enemy: Dictionary) -> float:
	if enemy.get("path", []).is_empty():
		return ENEMY_STEP_SECONDS * float(enemy.get("speed_multiplier", 1.0))
	return _enemy_step_seconds(
		enemy["position"],
		enemy["path"][0],
		float(enemy.get("speed_multiplier", 1.0))
	)


func get_enemies() -> Array:
	return enemies.duplicate(true)


func get_projectiles() -> Array:
	return projectiles.duplicate(true)


func get_objectives() -> Array:
	return objectives.duplicate(true)


func get_settlement_intentions() -> Array:
	return Intentions.evaluate(self)


func get_current_intention() -> Dictionary:
	return Intentions.current(self)


func evaluate_placement_quality(building_type: String, tile: Vector2i, rotation: int = 0) -> Dictionary:
	return Placement.score(self, building_type, tile, rotation)


func evaluate_frontier(building: Dictionary) -> Dictionary:
	return Frontier.evaluate(self, building)


func _stamp_placement_quality(building: Dictionary, building_type: String, tile: Vector2i, rotation: int = 0) -> void:
	var score: Dictionary = Placement.score(self, building_type, tile, rotation)
	if score.is_empty():
		return
	building["placement_quality"] = float(score.get("scalar", 1.0))
	building["placement_percent"] = int(score.get("percent", 100))
	building["placement_band"] = String(score.get("band", Placement.BAND_GOOD))


func _production_interval(building: Dictionary) -> float:
	var building_type := String(building.get("type", ""))
	var interval := 2.0
	if Defs.PRODUCTION_DEFS.has(building_type):
		interval = float(Defs.PRODUCTION_DEFS[building_type].get("interval", 5.0))
	var quality := float(building.get("placement_quality", 1.0))
	if quality > 0.01:
		interval = interval / quality
	return interval


func diagnose_building_dict(building: Dictionary) -> Dictionary:
	return Economy.diagnose(building, elapsed_seconds)


func diagnose_building(building_id: int) -> Dictionary:
	return diagnose_building_dict(_find_building_by_id(building_id))


func get_stall_reports() -> Array:
	var reports: Array = []
	for building in buildings:
		var report := Economy.diagnose(building, elapsed_seconds)
		if bool(report.get("stalled", false)):
			report["id"] = int(building.get("id", 0))
			report["position"] = building.get("position", Vector2i.ZERO)
			reports.append(report)
	return reports


func _refresh_economy_stalls() -> void:
	for building in buildings:
		var report := Economy.diagnose(building, elapsed_seconds)
		var kind := String(report.get("kind", Economy.KIND_OK))
		var previous := String(building.get("last_stall_kind", ""))
		if kind == previous:
			continue
		building["last_stall_kind"] = kind
		if not bool(report.get("stalled", false)):
			continue
		var detail := "%s: %s" % [String(report.get("title", "")), String(report.get("line", ""))]
		playtest_log.note(self, "resource_blocked", detail)
		last_message = "%s — %s." % [String(report.get("title", "BUILDING")).capitalize(), String(report.get("line", "stalled"))]


func note_player_command(event_type: String, detail: String = "") -> void:
	playtest_log.note_command(self, event_type, detail)


func get_log_entries() -> Array[String]:
	return log_entries.duplicate()


func get_tick_number() -> int:
	return tick_number


func get_last_message() -> String:
	return last_message


func get_time_label() -> String:
	var remaining := 0.0
	if is_night:
		remaining = max(0.0, NIGHT_LENGTH_SECONDS - phase_time)
		return "Night %d  %02d:%02d" % [day_count, int(remaining) / 60, int(remaining) % 60]
	remaining = max(0.0, DAY_LENGTH_SECONDS - phase_time)
	return "Day %d  %02d:%02d" % [day_count, int(remaining) / 60, int(remaining) % 60]


func get_claim_label() -> String:
	if rivalry != null:
		var presentation := get_wyrdfall_presentation()
		if bool(presentation.get("binding_active", false)):
			return "SHARD BINDING — %d%%" % int(presentation.get("binding_percent", 0))
		if bool(presentation.get("binding_ready", false)):
			return "Ready to Bind the Shard"
		return String(get_macro_objective().get("title", "SURVIVE"))
	if not claim_active:
		return "No Shard claim"
	return "Shard Claim: Survived %d/2 nights" % claim_nights_survived


func get_summary() -> Dictionary:
	var score := get_score()
	return {
		"victory": victory,
		"defeat_reason": defeat_reason,
		"score": score,
		"best_score": max(score, best_score),
		"days_survived": int(stats.get("days_survived", 0)),
		"buildings_completed": int(stats.get("buildings_completed", 0)),
		"enemies_defeated": int(stats.get("enemies_defeated", 0)),
		"buildings_abandoned": int(stats.get("buildings_abandoned", 0)),
		"buildings_destroyed": int(stats.get("buildings_destroyed", 0)),
		"workers_lost": int(stats.get("workers_lost", 0)),
		"hungry_nights": int(stats.get("hungry_nights", 0)),
		"shard_claimed": bool(stats.get("shard_claimed", false))
	}


func get_score() -> int:
	var score := int(stats.get("days_survived", 0)) * 100
	score += int(stats.get("buildings_completed", 0)) * 20
	score += int(stats.get("enemies_defeated", 0)) * 12
	score -= int(stats.get("buildings_destroyed", 0)) * 25
	score -= int(stats.get("buildings_abandoned", 0)) * 10
	if bool(stats.get("shard_claimed", false)):
		score += 500
	return max(0, score)


func is_inside_map(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < map_size.x and tile.y < map_size.y


func get_tile(tile: Vector2i) -> String:
	if not is_inside_map(tile):
		return Defs.TILE_GRASS
	return String(map_tiles[tile.y][tile.x])


func get_deposit_remaining(tile: Vector2i) -> int:
	var key := _tile_key(tile)
	if String(get_tile(tile)) == Defs.TILE_TREE:
		return int(tree_deposits.get(key, 0))
	if String(get_tile(tile)) == Defs.TILE_ROCK:
		return int(rock_deposits.get(key, 0))
	return 0


func is_revealed(tile: Vector2i) -> bool:
	return revealed_tiles.has(_tile_key(tile))


func is_tile_occupied(tile: Vector2i) -> bool:
	return occupied_tiles.has(_tile_key(tile))


func get_building_at_tile(tile: Vector2i) -> Dictionary:
	var key := _tile_key(tile)
	if not occupied_tiles.has(key):
		return {}
	return _find_building_by_id(int(occupied_tiles[key]))


func get_building_by_id(building_id: int) -> Dictionary:
	return _find_building_by_id(building_id).duplicate(true)


func get_road_connection_tiles(tile: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for neighbor in _neighbors(tile):
		if not is_inside_map(neighbor):
			continue
		if neighbor == town_hall_position:
			tiles.append(neighbor)
			continue
		var building: Dictionary = get_building_at_tile(neighbor)
		if not building.is_empty() and String(building.get("type", "")) == Defs.BUILDING_ROAD:
			tiles.append(neighbor)
	return tiles


func get_available_resource(resource_type: String) -> int:
	var accessible := int(central_inventory.get(resource_type, 0))
	for building in buildings:
		if bool(building.get("construction", false)):
			continue
		accessible += int(building.get("local_inventory", {}).get(resource_type, 0))
	return max(0, accessible - int(reserved_inventory.get(resource_type, 0)))


func _consolidate_cost_to_central(cost: Dictionary) -> void:
	# Producer inventories are part of the resource total shown to the player.
	# Move only the amount needed for a new reservation into the shared delivery
	# pool so a full Quarry or Sawmill can never deadlock progression.
	for resource_type in cost.keys():
		var required_central := int(reserved_inventory.get(resource_type, 0)) + int(cost[resource_type])
		var missing := maxi(0, required_central - int(central_inventory.get(resource_type, 0)))
		if missing <= 0:
			continue
		for building in buildings:
			if bool(building.get("construction", false)):
				continue
			var local_inventory: Dictionary = building.get("local_inventory", {})
			var available := int(local_inventory.get(resource_type, 0))
			if available <= 0:
				continue
			var moved := mini(missing, available)
			local_inventory[resource_type] = available - moved
			building["local_inventory"] = local_inventory
			central_inventory[resource_type] = int(central_inventory.get(resource_type, 0)) + moved
			missing -= moved
			if missing <= 0:
				break


func get_population_max() -> int:
	return housing_capacity


func get_population_used() -> int:
	return population_current


func get_available_population() -> int:
	return workers_free()


func workers_free() -> int:
	return max(0, population_current - workers_assigned - soldiers_total - _active_road_builder_count())


func _active_road_builder_count() -> int:
	var count := 0
	for worker in workers:
		var task: Dictionary = worker.get("task", {})
		if String(task.get("purpose", "")) == "road_build":
			count += 1
	return count


func format_tile(tile: Vector2i) -> String:
	return "(%d, %d)" % [tile.x, tile.y]


func run_construction_smoke_test() -> Dictionary:
	var report: Array[String] = []
	var passed := true

	start_new_run(MAP_WIDTH, MAP_HEIGHT, 424242, true)
	central_inventory[Defs.RESOURCE_STONE] = 20
	central_inventory[Defs.RESOURCE_PLANKS] = 20
	var road_tile := town_hall_position + Vector2i(0, 1)
	var house_tile := town_hall_position + Vector2i(0, 2)
	_prepare_test_tile(road_tile, Defs.TILE_GRASS)
	_prepare_test_tile(house_tile, Defs.TILE_GRASS)
	var starting_wood := int(central_inventory[Defs.RESOURCE_WOOD])
	var road_result: Dictionary = request_build(Defs.BUILDING_ROAD, road_tile)
	var house_result: Dictionary = request_build(Defs.BUILDING_HOUSE, house_tile)
	var house_cost := int(Defs.building_cost(Defs.BUILDING_HOUSE).get(Defs.RESOURCE_WOOD, 0))
	passed = _record_smoke(report, "road and house site can be placed", bool(road_result.get("success", false)) and bool(house_result.get("success", false))) and passed
	passed = _record_smoke(report, "house materials reserve without teleporting", int(central_inventory[Defs.RESOURCE_WOOD]) == starting_wood - 1 and int(reserved_inventory[Defs.RESOURCE_WOOD]) == house_cost) and passed
	_simulate_seconds_for_test(0.75)
	var site: Dictionary = get_building_at_tile(house_tile)
	passed = _record_smoke(report, "carrier physically delivers house materials", int(site.get("materials_delivered", {}).get(Defs.RESOURCE_WOOD, 0)) == house_cost and int(reserved_inventory[Defs.RESOURCE_WOOD]) == 0) and passed
	passed = _record_smoke(report, "construction waits for delivery before building", bool(site.get("construction", false)) and float(site.get("construction_remaining", 0.0)) >= Defs.build_time(Defs.BUILDING_HOUSE) - 0.01) and passed
	_simulate_seconds_for_test(2.25)
	var house: Dictionary = get_building_at_tile(house_tile)
	passed = _record_smoke(report, "delivered house completes and raises capacity", String(house.get("type", "")) == Defs.BUILDING_HOUSE and housing_capacity == 10) and passed
	passed = _record_smoke(report, "construction spends its delivered cost exactly once", int(central_inventory[Defs.RESOURCE_WOOD]) == starting_wood - 1 - house_cost) and passed
	passed = _record_smoke(report, "logistics creates visible carriers", _count_worker_type("carrier") >= 1) and passed

	start_new_run(MAP_WIDTH, MAP_HEIGHT, 515151, true)
	road_tile = town_hall_position + Vector2i(0, 1)
	house_tile = town_hall_position + Vector2i(0, 2)
	_prepare_test_tile(road_tile, Defs.TILE_GRASS)
	_prepare_test_tile(house_tile, Defs.TILE_GRASS)
	request_build(Defs.BUILDING_ROAD, road_tile)
	request_build(Defs.BUILDING_HOUSE, house_tile)
	_simulate_seconds_for_test(1.0)
	var saved_state: Dictionary = _serialize_state().duplicate(true)
	_restore_state(saved_state)
	passed = _record_smoke(report, "save/load preserves delivered construction", bool(get_building_at_tile(house_tile).get("construction", false))) and passed
	_simulate_seconds_for_test(2.25)
	passed = _record_smoke(report, "loaded construction resumes and completes", String(get_building_at_tile(house_tile).get("type", "")) == Defs.BUILDING_HOUSE) and passed

	start_new_run(MAP_WIDTH, MAP_HEIGHT, 525252, true)
	road_tile = town_hall_position + Vector2i(0, 1)
	house_tile = town_hall_position + Vector2i(0, 2)
	_prepare_test_tile(road_tile, Defs.TILE_GRASS)
	_prepare_test_tile(house_tile, Defs.TILE_GRASS)
	request_build(Defs.BUILDING_ROAD, road_tile)
	var wood_before_cancel := int(central_inventory[Defs.RESOURCE_WOOD])
	request_build(Defs.BUILDING_HOUSE, house_tile)
	request_demolish(house_tile)
	passed = _record_smoke(report, "cancelling a site releases every reserved material", int(central_inventory[Defs.RESOURCE_WOOD]) == wood_before_cancel and int(reserved_inventory[Defs.RESOURCE_WOOD]) == 0) and passed

	return {"success": passed, "log": report}


func run_economy_smoke_test() -> Dictionary:
	var report: Array[String] = []
	var passed := true

	start_new_run(MAP_WIDTH, MAP_HEIGHT, 616161, true)
	population_current = 10
	housing_capacity = 10
	central_inventory[Defs.RESOURCE_WOOD] = 40
	central_inventory[Defs.RESOURCE_PLANKS] = 10
	var road_tile := town_hall_position + Vector2i(0, 1)
	var quarry_tile := town_hall_position + Vector2i(0, 2)
	_prepare_test_tile(road_tile, Defs.TILE_GRASS)
	_prepare_test_tile(quarry_tile, Defs.TILE_ROCK)
	rock_deposits[_tile_key(quarry_tile)] = 24
	request_build(Defs.BUILDING_ROAD, road_tile)
	request_build(Defs.BUILDING_QUARRY, quarry_tile)
	_simulate_seconds_for_test(4.0)
	var quarry: Dictionary = get_building_at_tile(quarry_tile)
	passed = _record_smoke(report, "quarry completes with a 24 Stone deposit", String(quarry.get("type", "")) == Defs.BUILDING_QUARRY and int(quarry.get("deposit_remaining", 0)) == 24) and passed
	passed = _record_smoke(report, "staffed quarry has a visible miner", _count_worker_type("miner") == 1) and passed
	var stone_before := int(central_inventory[Defs.RESOURCE_STONE])
	_simulate_seconds_for_test(6.5)
	quarry = get_building_at_tile(quarry_tile)
	passed = _record_smoke(report, "quarry output travels home by carrier", int(central_inventory[Defs.RESOURCE_STONE]) >= stone_before + 2 and int(quarry.get("deposit_remaining", 0)) <= 22) and passed
	passed = _record_smoke(report, "production and delivery enter the run journal", _journal_has_event("production") and _journal_has_event("delivery")) and passed
	_simulate_seconds_for_test(6.0)
	var bakery_road := town_hall_position + Vector2i(1, 0)
	var bakery_tile := town_hall_position + Vector2i(2, 0)
	_prepare_test_tile(bakery_road, Defs.TILE_GRASS)
	_prepare_test_tile(bakery_tile, Defs.TILE_GRASS)
	request_build(Defs.BUILDING_ROAD, bakery_road)
	var bakery_result: Dictionary = request_build(Defs.BUILDING_BAKERY, bakery_tile)
	passed = _record_smoke(report, "one healthy quarry unlocks a Bakery without a Stone deadlock", int(central_inventory[Defs.RESOURCE_STONE]) >= 4 and bool(bakery_result.get("success", false))) and passed

	start_new_run(MAP_WIDTH, MAP_HEIGHT, 626262, true)
	housing_capacity = 10
	population_current = 5
	central_inventory[Defs.RESOURCE_BREAD] = 0
	central_inventory[Defs.RESOURCE_WHEAT] = 12
	_simulate_seconds_for_test(10.25)
	passed = _record_smoke(report, "population grows from Wheat while preserving the nightly meal", population_current == 6 and int(central_inventory[Defs.RESOURCE_WHEAT]) == 10) and passed

	start_new_run(MAP_WIDTH, MAP_HEIGHT, 636363, true)
	population_current = 1
	housing_capacity = 5
	var lumber := _create_building(Defs.BUILDING_LUMBER_CAMP, town_hall_position + Vector2i(3, 0))
	var priority_quarry := _create_building(Defs.BUILDING_QUARRY, town_hall_position + Vector2i(4, 0))
	buildings.append(lumber)
	buildings.append(priority_quarry)
	_try_staff_building(lumber)
	cycle_staff_priority(int(priority_quarry["id"]))
	cycle_staff_priority(int(priority_quarry["id"]))
	passed = _record_smoke(report, "high-priority work reassigns the available settler", int(priority_quarry.get("assigned_staff", 0)) == 1 and int(lumber.get("assigned_staff", 0)) == 0) and passed

	start_new_run(MAP_WIDTH, MAP_HEIGHT, 646464, true)
	population_current = 5
	housing_capacity = 5
	var shelter_road := town_hall_position + Vector2i(0, 1)
	_prepare_test_tile(shelter_road, Defs.TILE_GRASS)
	request_build(Defs.BUILDING_ROAD, shelter_road)
	var shelter_quarry := _create_building(Defs.BUILDING_QUARRY, town_hall_position + Vector2i(0, 2))
	shelter_quarry["connected"] = true
	buildings.append(shelter_quarry)
	_try_staff_building(shelter_quarry)
	soldiers_total = 1
	var night_tower := _create_building(Defs.BUILDING_WATCHTOWER, town_hall_position + Vector2i(1, 1))
	night_tower["connected"] = true
	buildings.append(night_tower)
	_try_staff_building(night_tower)
	_ensure_carriers()
	_sync_production_workers()
	_start_night()
	_simulate_seconds_for_test(3.0)
	passed = _record_smoke(report, "civilians and carriers physically enter shelter at night", get_sheltered_worker_count() == get_shelterable_worker_count() and get_sheltered_worker_count() > 0) and passed
	passed = _record_smoke(report, "tower guards remain visibly on duty at night", _all_workers_of_type_in_state("guard", "Night Watch")) and passed
	_end_night()
	passed = _record_smoke(report, "sheltered workers return at dawn", get_sheltered_worker_count() == 0) and passed

	start_new_run(MAP_WIDTH, MAP_HEIGHT, 656565, true)
	population_current = 5
	soldiers_total = 1
	var firing_tower := _create_building(Defs.BUILDING_WATCHTOWER, town_hall_position + Vector2i(1, 0))
	firing_tower["connected"] = true
	buildings.append(firing_tower)
	_try_staff_building(firing_tower)
	var target_enemy := {
		"id": next_enemy_id,
		"position": firing_tower["position"] + Vector2i(3, 0),
		"hp": 55,
		"max_hp": 55,
		"damage": 2,
		"target_id": 0,
		"path": [],
		"move_elapsed": 0.0,
		"attack_timer": 0.0
	}
	next_enemy_id += 1
	enemies.append(target_enemy)
	_update_towers(TICK_SECONDS)
	passed = _record_smoke(report, "tower fire remains visible and enters the run journal", projectiles.size() == 1 and _journal_has_event("tower_attack")) and passed
	for _impact_tick in 7:
		_update_projectiles(TICK_SECONDS)
	passed = _record_smoke(report, "a staffed tower applies damage when its projectile arrives", int(target_enemy["hp"]) == 50) and passed

	start_new_run(MAP_WIDTH, MAP_HEIGHT, 666666, true)
	central_inventory[Defs.RESOURCE_BREAD] = 999
	is_night = true
	phase_time = 0.0
	_spawn_wave()
	_simulate_seconds_for_test(NIGHT_LENGTH_SECONDS + 0.25)
	var town_hall := _find_town_hall()
	passed = _record_smoke(report, "an undefended realm survives the first night", not game_finished and day_count == 2 and not town_hall.is_empty() and int(town_hall.get("hp", 0)) > 0) and passed

	passed = _run_requested_system_smoke_tests(report) and passed

	return {"success": passed, "log": report}


func _count_worker_type(worker_type: String) -> int:
	var count := 0
	for worker in workers:
		if String(worker.get("type", "")) == worker_type:
			count += 1
	return count


func _all_workers_of_type_in_state(worker_type: String, state: String) -> bool:
	var found := false
	for worker in workers:
		if String(worker.get("type", "")) != worker_type:
			continue
		found = true
		if String(worker.get("state", "")) != state:
			return false
	return found


func _run_requested_system_smoke_tests(report: Array[String]) -> bool:
	var passed := true

	start_new_run(MAP_WIDTH, MAP_HEIGHT, 676767, true)
	var route_start := Vector2i(9, 10)
	var route_end := Vector2i(16, 10)
	_prepare_test_tile(route_start, Defs.TILE_GRASS)
	_prepare_test_tile(route_end, Defs.TILE_GRASS)
	for x in range(route_start.x, route_end.x + 1):
		var road_tile := Vector2i(x, 11)
		_prepare_test_tile(road_tile, Defs.TILE_GRASS)
		_add_completed_building(Defs.BUILDING_ROAD, road_tile)
	_rebuild_occupied_tiles()
	_recompute_road_network()
	var preferred_path := _find_worker_path(route_start, route_end)
	var uses_road := false
	for tile in preferred_path:
		if _is_road_tile(tile):
			uses_road = true
			break
	var movement_probe := {"type": "miner", "position": route_start, "path": [Vector2i(route_start.x, 11)]}
	var field_probe := {"type": "miner", "position": route_start, "path": [route_start + Vector2i(-1, 0)]}
	passed = _record_smoke(report, "workers prefer a sensible road detour", uses_road) and passed
	passed = _record_smoke(report, "roads accelerate settlers and night enemies", get_worker_step_seconds(movement_probe) < get_worker_step_seconds(field_probe) and _enemy_step_seconds(route_start, Vector2i(route_start.x, 11)) < _enemy_step_seconds(route_start, route_start + Vector2i(-1, 0))) and passed
	passed = _record_smoke(report, "building yards keep one tile of landscape between structures", not _has_building_clearance(town_hall_position + Vector2i(1, 1), Vector2i.ONE) and _has_building_clearance(town_hall_position + Vector2i(6, 0), Vector2i.ONE)) and passed

	start_new_run(MAP_WIDTH, MAP_HEIGHT, 686868, true)
	population_current = 5
	housing_capacity = 5
	central_inventory[Defs.RESOURCE_BREAD] = 2
	central_inventory[Defs.RESOURCE_WHEAT] = 0
	var hungry_farm := _create_building(Defs.BUILDING_FARM, town_hall_position + Vector2i(2, 0))
	hungry_farm["connected"] = true
	buildings.append(hungry_farm)
	_try_staff_building(hungry_farm)
	_sync_production_workers()
	_start_night()
	passed = _record_smoke(report, "one nightly meal records the unfed population without abandonment", hungry_population == 3 and int(stats.get("buildings_abandoned", 0)) == 0) and passed
	_end_night()
	_produce_from_building(hungry_farm)
	passed = _record_smoke(report, "hungry workplaces produce half output during the first quarter-day", is_hunger_penalty_active() and int(hungry_farm["local_inventory"].get(Defs.RESOURCE_WHEAT, 0)) == 1) and passed
	var hunger_save := _serialize_state().duplicate(true)
	_restore_state(hunger_save)
	passed = _record_smoke(report, "save/load preserves hunger and morning recovery", is_hunger_penalty_active() and hungry_population == 3) and passed
	_update_hunger_recovery(DAY_LENGTH_SECONDS * HUNGER_RECOVERY_FRACTION + TICK_SECONDS)
	passed = _record_smoke(report, "hunger markers clear after the first quarter-day", not is_hunger_penalty_active() and hungry_population == 0) and passed

	start_new_run(MAP_WIDTH, MAP_HEIGHT, 696969, true)
	var tree_tile := town_hall_position + Vector2i(5, 0)
	_prepare_test_tile(tree_tile, Defs.TILE_TREE)
	tree_deposits[_tile_key(tree_tile)] = 6
	_consume_deposit(tree_tile, 2)
	passed = _record_smoke(report, "two Wood consumes exactly two units from a tree node", int(tree_deposits.get(_tile_key(tree_tile), 0)) == 4) and passed
	_set_tile(tree_tile, Defs.TILE_ROCK)
	rock_deposits[_tile_key(tree_tile)] = 24
	passed = _record_smoke(report, "rock placement removes any hidden tree deposit", not tree_deposits.has(_tile_key(tree_tile)) and rock_deposits.has(_tile_key(tree_tile))) and passed
	_set_tile(tree_tile, Defs.TILE_TREE)
	tree_deposits[_tile_key(tree_tile)] = 6
	passed = _record_smoke(report, "tree placement removes any hidden rock deposit", not rock_deposits.has(_tile_key(tree_tile)) and tree_deposits.has(_tile_key(tree_tile))) and passed

	start_new_run(MAP_WIDTH, MAP_HEIGHT, 706969, true)
	var lumber_position := town_hall_position + Vector2i(2, 0)
	_clear_area(lumber_position, LUMBER_REACH)
	var first_tree := lumber_position + Vector2i(2, 0)
	var second_tree := lumber_position + Vector2i(6, 0)
	_prepare_test_tile(first_tree, Defs.TILE_TREE)
	_prepare_test_tile(second_tree, Defs.TILE_TREE)
	tree_deposits[_tile_key(first_tree)] = 1
	tree_deposits[_tile_key(second_tree)] = 1
	var retargeting_lumber := _create_building(Defs.BUILDING_LUMBER_CAMP, lumber_position)
	retargeting_lumber["connected"] = true
	retargeting_lumber["assigned_staff"] = 1
	buildings.append(retargeting_lumber)
	_produce_from_building(retargeting_lumber)
	_produce_from_building(retargeting_lumber)
	passed = _record_smoke(report, "lumber workers move to the next tree stand when one disappears", int(retargeting_lumber["local_inventory"].get(Defs.RESOURCE_WOOD, 0)) == 2 and get_tile(first_tree) == Defs.TILE_GRASS and get_tile(second_tree) == Defs.TILE_GRASS and _journal_has_event("lumber_retargeted")) and passed

	start_new_run(MAP_WIDTH, MAP_HEIGHT, 707171, true)
	var exposed_worker := {
		"id": next_worker_id,
		"type": "carrier",
		"position": shard_position + Vector2i(1, 0),
		"path": [],
		"state": "Idle",
		"arrival_state": "Idle",
		"move_elapsed": 0.0,
		"capacity": 5,
		"carried_resource": "",
		"carried_amount": 0,
		"task": {},
		"shelter_position": Vector2i(-1, -1),
		"hp": WORKER_MAX_HP,
		"max_hp": WORKER_MAX_HP,
		"hungry": false
	}
	next_worker_id += 1
	workers.append(exposed_worker)
	var hunter := {
		"id": next_enemy_id,
		"position": shard_position,
		"hp": 50,
		"max_hp": 50,
		"damage": 40,
		"target_id": 0,
		"target_kind": "building",
		"target_position": _vector_to_data(shard_position),
		"path": [],
		"move_elapsed": 0.0,
		"attack_timer": 0.0
	}
	_update_enemy(hunter, TICK_SECONDS)
	passed = _record_smoke(report, "night enemies actively target and can kill exposed workers", workers.is_empty() and String(hunter.get("target_kind", "")) == "worker" and _journal_has_event("worker_lost")) and passed
	_add_log("Diagnostic test event.")
	passed = _record_smoke(report, "the visible realm log keeps timestamped diagnostic events", not log_entries.is_empty() and String(log_entries[-1]).contains("Diagnostic test event")) and passed

	return passed


func _journal_has_event(event_type: String) -> bool:
	for event in run_journal:
		if String(event.get("event", "")) == event_type:
			return true
	return false


func _run_legacy_construction_smoke_test() -> Dictionary:
	var report: Array[String] = []
	var passed := true

	start_new_run(MAP_WIDTH, MAP_HEIGHT, 424242, true)
	central_inventory[Defs.RESOURCE_STONE] = 20
	central_inventory[Defs.RESOURCE_PLANKS] = 20
	var road_tile := town_hall_position + Vector2i(0, 1)
	var house_tile := town_hall_position + Vector2i(0, 2)
	var lumber_road_tile := town_hall_position + Vector2i(1, 0)
	var lumber_tile := town_hall_position + Vector2i(2, 0)
	var nearby_tree := lumber_tile + Vector2i(1, 0)
	_prepare_test_tile(road_tile, Defs.TILE_GRASS)
	_prepare_test_tile(house_tile, Defs.TILE_GRASS)
	_prepare_test_tile(lumber_road_tile, Defs.TILE_GRASS)
	_prepare_test_tile(lumber_tile, Defs.TILE_GRASS)
	_prepare_test_tile(nearby_tree, Defs.TILE_TREE)
	tree_deposits[_tile_key(nearby_tree)] = 6

	var starting_wood := int(central_inventory[Defs.RESOURCE_WOOD])
	var road_result: Dictionary = request_build(Defs.BUILDING_ROAD, road_tile)
	passed = _record_smoke(report, "road placement succeeds", bool(road_result.get("success", false))) and passed
	passed = _record_smoke(report, "road costs exactly 1 Wood", int(central_inventory[Defs.RESOURCE_WOOD]) == starting_wood - 1) and passed
	passed = _record_smoke(report, "road connects to Town Hall", get_road_connection_tiles(road_tile).has(town_hall_position)) and passed
	passed = _record_smoke(report, "road objective completes", _objective_complete("road")) and passed

	var house_wood_before := int(central_inventory[Defs.RESOURCE_WOOD])
	var house_result: Dictionary = request_build(Defs.BUILDING_HOUSE, house_tile)
	passed = _record_smoke(report, "house construction site starts", bool(house_result.get("success", false)) and bool(get_building_at_tile(house_tile).get("construction", false))) and passed
	passed = _record_smoke(report, "house cost deducted once up front", int(central_inventory[Defs.RESOURCE_WOOD]) == house_wood_before - int(Defs.building_cost(Defs.BUILDING_HOUSE)[Defs.RESOURCE_WOOD])) and passed
	_simulate_seconds_for_test(3.0)
	var house: Dictionary = get_building_at_tile(house_tile)
	passed = _record_smoke(report, "house finishes after timer", String(house.get("type", "")) == Defs.BUILDING_HOUSE and not bool(house.get("construction", false))) and passed
	passed = _record_smoke(report, "house raises housing capacity", get_population_max() > 5) and passed
	passed = _record_smoke(report, "house objective completes", _objective_complete("house")) and passed
	passed = _record_smoke(report, "house cost is not deducted again on completion", int(central_inventory[Defs.RESOURCE_WOOD]) == house_wood_before - int(Defs.building_cost(Defs.BUILDING_HOUSE)[Defs.RESOURCE_WOOD])) and passed

	var invalid_wood_before := int(central_inventory[Defs.RESOURCE_WOOD])
	var invalid_result: Dictionary = request_build(Defs.BUILDING_HOUSE, town_hall_position)
	passed = _record_smoke(report, "invalid occupied placement fails", not bool(invalid_result.get("success", false))) and passed
	passed = _record_smoke(report, "invalid placement does not deduct Wood", int(central_inventory[Defs.RESOURCE_WOOD]) == invalid_wood_before) and passed

	request_build(Defs.BUILDING_ROAD, lumber_road_tile)
	var lumber_wood_before := int(central_inventory[Defs.RESOURCE_WOOD])
	var lumber_result: Dictionary = request_build(Defs.BUILDING_LUMBER_CAMP, lumber_tile)
	passed = _record_smoke(report, "lumber camp construction site starts", bool(lumber_result.get("success", false)) and bool(get_building_at_tile(lumber_tile).get("construction", false))) and passed
	_simulate_seconds_for_test(3.0)
	var lumber: Dictionary = get_building_at_tile(lumber_tile)
	passed = _record_smoke(report, "lumber camp finishes after timer", String(lumber.get("type", "")) == Defs.BUILDING_LUMBER_CAMP and not bool(lumber.get("construction", false))) and passed
	passed = _record_smoke(report, "lumber camp is staffed", bool(lumber.get("staffed", false))) and passed
	passed = _record_smoke(report, "lumber objective completes", _objective_complete("lumber")) and passed
	passed = _record_smoke(report, "lumber cost is deducted once", int(central_inventory[Defs.RESOURCE_WOOD]) == lumber_wood_before - int(Defs.building_cost(Defs.BUILDING_LUMBER_CAMP)[Defs.RESOURCE_WOOD])) and passed

	start_new_run(MAP_WIDTH, MAP_HEIGHT, 515151, true)
	var save_road_tile := town_hall_position + Vector2i(0, 1)
	var save_house_tile := town_hall_position + Vector2i(0, 2)
	_prepare_test_tile(save_road_tile, Defs.TILE_GRASS)
	_prepare_test_tile(save_house_tile, Defs.TILE_GRASS)
	request_build(Defs.BUILDING_ROAD, save_road_tile)
	request_build(Defs.BUILDING_HOUSE, save_house_tile)
	_simulate_seconds_for_test(1.0)
	var saved_state: Dictionary = _serialize_state().duplicate(true)
	_restore_state(saved_state)
	passed = _record_smoke(report, "save/load keeps construction site in progress", bool(get_building_at_tile(save_house_tile).get("construction", false))) and passed
	_simulate_seconds_for_test(2.5)
	var loaded_house: Dictionary = get_building_at_tile(save_house_tile)
	passed = _record_smoke(report, "loaded construction resumes and completes", String(loaded_house.get("type", "")) == Defs.BUILDING_HOUSE and not bool(loaded_house.get("construction", false))) and passed

	return {"success": passed, "log": report}


func _run_legacy_economy_smoke_test() -> Dictionary:
	var report: Array[String] = []
	var passed := true

	start_new_run(MAP_WIDTH, MAP_HEIGHT, 616161, true)
	var house_road := town_hall_position + Vector2i(0, 1)
	var house_tile := town_hall_position + Vector2i(0, 2)
	_prepare_test_tile(house_road, Defs.TILE_GRASS)
	_prepare_test_tile(house_tile, Defs.TILE_GRASS)
	request_build(Defs.BUILDING_ROAD, house_road)
	request_build(Defs.BUILDING_HOUSE, house_tile)
	_simulate_seconds_for_test(3.0)
	passed = _record_smoke(report, "house increases housing capacity to 10", housing_capacity == 10 and population_current == 5) and passed
	var bread_before_growth := int(central_inventory[Defs.RESOURCE_BREAD])
	_simulate_seconds_for_test(10.0)
	passed = _record_smoke(report, "population grows from housing plus Bread", population_current == 6 and int(central_inventory[Defs.RESOURCE_BREAD]) == bread_before_growth - POP_GROWTH_FOOD_COST) and passed
	population_current = housing_capacity
	var full_population := population_current
	_simulate_seconds_for_test(11.0)
	passed = _record_smoke(report, "population stops at housing capacity", population_current == full_population) and passed

	passed = _record_production_smoke(report, Defs.BUILDING_LUMBER_CAMP, Defs.RESOURCE_WOOD, 1, false) and passed
	passed = _record_production_smoke(report, Defs.BUILDING_QUARRY, Defs.RESOURCE_STONE, 2, false) and passed
	passed = _record_production_smoke(report, Defs.BUILDING_FARM, Defs.RESOURCE_WHEAT, 2, false) and passed
	passed = _record_production_smoke(report, Defs.BUILDING_SAWMILL, Defs.RESOURCE_PLANKS, 2, true) and passed
	passed = _record_production_smoke(report, Defs.BUILDING_BAKERY, Defs.RESOURCE_BREAD, 2, true) and passed
	passed = _record_bakery_farm_haul_smoke(report) and passed
	passed = _record_production_requires_road_smoke(report) and passed
	passed = _record_sawmill_wood_reserve_smoke(report) and passed
	passed = _record_staff_shortage_smoke(report) and passed
	passed = _record_economy_save_load_smoke(report) and passed

	return {"success": passed, "log": report}


func _record_production_smoke(report: Array[String], building_type: String, output_resource: String, expected_gain: int, checks_input: bool) -> bool:
	start_new_run(MAP_WIDTH, MAP_HEIGHT, 700000 + Defs.BUILDABLE_TYPES.find(building_type), true)
	population_current = 10
	housing_capacity = 10
	central_inventory[Defs.RESOURCE_WOOD] = 40
	central_inventory[Defs.RESOURCE_STONE] = 40
	central_inventory[Defs.RESOURCE_PLANKS] = 40
	central_inventory[Defs.RESOURCE_WHEAT] = 40
	central_inventory[Defs.RESOURCE_BREAD] = 40
	var road_tile := town_hall_position + Vector2i(0, 1)
	var building_tile := town_hall_position + Vector2i(0, 2)
	_prepare_test_tile(road_tile, Defs.TILE_GRASS)
	_prepare_test_tile(building_tile, Defs.TILE_ROCK if building_type == Defs.BUILDING_QUARRY else Defs.TILE_GRASS)
	if building_type == Defs.BUILDING_LUMBER_CAMP:
		var tree_tile := building_tile + Vector2i(1, 0)
		_prepare_test_tile(tree_tile, Defs.TILE_TREE)
		tree_deposits[_tile_key(tree_tile)] = 6
	if building_type == Defs.BUILDING_QUARRY:
		rock_deposits[_tile_key(building_tile)] = 8
	request_build(Defs.BUILDING_ROAD, road_tile)
	var build_result: Dictionary = request_build(building_type, building_tile)
	_simulate_seconds_for_test(Defs.build_time(building_type) + 0.5)
	var building: Dictionary = get_building_at_tile(building_tile)
	var staffed := int(building.get("assigned_staff", 0)) >= Defs.building_staff(building_type)
	var output_before := int(central_inventory.get(output_resource, 0))
	var input_before := 0
	if checks_input:
		var definition: Dictionary = Defs.PRODUCTION_DEFS[building_type]
		input_before = int(central_inventory.get(String(definition["input"]), 0))
	_simulate_seconds_for_test(float(Defs.PRODUCTION_DEFS[building_type].get("interval", 5.0)) + 0.5)
	var output_after := int(central_inventory.get(output_resource, 0))
	var label := "%s produces %s globally" % [Defs.building_name(building_type), Defs.resource_name(output_resource)]
	var produced := bool(build_result.get("success", false)) and staffed and output_after >= output_before + expected_gain
	if checks_input:
		var definition_after: Dictionary = Defs.PRODUCTION_DEFS[building_type]
		var input_after := int(central_inventory.get(String(definition_after["input"]), 0))
		produced = produced and input_after <= input_before - int(definition_after.get("input_amount", 0))
	if building_type == Defs.BUILDING_QUARRY:
		produced = produced and int(building.get("deposit_remaining", 0)) < 8
	return _record_smoke(report, label, produced)


func _record_production_requires_road_smoke(report: Array[String]) -> bool:
	start_new_run(MAP_WIDTH, MAP_HEIGHT, 777777, true)
	population_current = 10
	housing_capacity = 10
	var road_tile := town_hall_position + Vector2i(0, 1)
	var lumber_tile := town_hall_position + Vector2i(0, 2)
	var tree_tile := lumber_tile + Vector2i(1, 0)
	_prepare_test_tile(road_tile, Defs.TILE_GRASS)
	_prepare_test_tile(lumber_tile, Defs.TILE_GRASS)
	_prepare_test_tile(tree_tile, Defs.TILE_TREE)
	tree_deposits[_tile_key(tree_tile)] = 6
	request_build(Defs.BUILDING_ROAD, road_tile)
	request_build(Defs.BUILDING_LUMBER_CAMP, lumber_tile)
	_simulate_seconds_for_test(Defs.build_time(Defs.BUILDING_LUMBER_CAMP) + 0.5)
	request_demolish(road_tile)
	var wood_before := int(central_inventory[Defs.RESOURCE_WOOD])
	_simulate_seconds_for_test(float(Defs.PRODUCTION_DEFS[Defs.BUILDING_LUMBER_CAMP].get("interval", 4.0)) + 0.5)
	var lumber: Dictionary = get_building_at_tile(lumber_tile)
	return _record_smoke(report, "production stops without road connection", int(central_inventory[Defs.RESOURCE_WOOD]) == wood_before and String(lumber.get("status", "")) == "No road connection.")


func _record_sawmill_wood_reserve_smoke(report: Array[String]) -> bool:
	start_new_run(MAP_WIDTH, MAP_HEIGHT, 787878, true)
	population_current = 10
	housing_capacity = 10
	central_inventory[Defs.RESOURCE_WOOD] = 40
	central_inventory[Defs.RESOURCE_STONE] = 40
	central_inventory[Defs.RESOURCE_PLANKS] = 0
	var road_tile := town_hall_position + Vector2i(0, 1)
	var sawmill_tile := town_hall_position + Vector2i(0, 2)
	_prepare_test_tile(road_tile, Defs.TILE_GRASS)
	_prepare_test_tile(sawmill_tile, Defs.TILE_GRASS)
	request_build(Defs.BUILDING_ROAD, road_tile)
	request_build(Defs.BUILDING_SAWMILL, sawmill_tile)
	_simulate_seconds_for_test(Defs.build_time(Defs.BUILDING_SAWMILL) + 0.5)
	var sawmill: Dictionary = get_building_at_tile(sawmill_tile)
	central_inventory[Defs.RESOURCE_WOOD] = SAWMILL_WOOD_RESERVE + 1
	central_inventory[Defs.RESOURCE_PLANKS] = 0
	sawmill["production_timer"] = 0.0
	_simulate_seconds_for_test(float(Defs.PRODUCTION_DEFS[Defs.BUILDING_SAWMILL].get("interval", 5.0)) + 0.5)
	var protected_reserve := int(central_inventory[Defs.RESOURCE_WOOD]) == SAWMILL_WOOD_RESERVE + 1 and int(central_inventory[Defs.RESOURCE_PLANKS]) == 0 and String(sawmill.get("status", "")) == "Saving Wood for construction."
	central_inventory[Defs.RESOURCE_WOOD] = SAWMILL_WOOD_RESERVE + 2
	sawmill["production_timer"] = 0.0
	_simulate_seconds_for_test(float(Defs.PRODUCTION_DEFS[Defs.BUILDING_SAWMILL].get("interval", 5.0)) + 0.5)
	var spends_only_surplus := int(central_inventory[Defs.RESOURCE_WOOD]) == SAWMILL_WOOD_RESERVE and int(central_inventory[Defs.RESOURCE_PLANKS]) == 2
	return _record_smoke(report, "sawmill preserves Wood construction reserve", protected_reserve and spends_only_surplus)


func _record_bakery_farm_haul_smoke(report: Array[String]) -> bool:
	start_new_run(MAP_WIDTH, MAP_HEIGHT, 797979, true)
	population_current = 10
	housing_capacity = 10
	central_inventory[Defs.RESOURCE_WOOD] = 40
	central_inventory[Defs.RESOURCE_STONE] = 40
	central_inventory[Defs.RESOURCE_PLANKS] = 40
	central_inventory[Defs.RESOURCE_WHEAT] = 0
	central_inventory[Defs.RESOURCE_BREAD] = 20
	var th := town_hall_position
	var hall := Defs.building_footprint(Defs.BUILDING_TOWN_HALL)
	var road_y := th.y + hall.y
	var farm_tile := th + Vector2i(0, hall.y + 1)
	var bakery_tile := th + Vector2i(hall.x + 2, hall.y + 1)
	var yard_height := get_height(th)
	for y in range(th.y, th.y + hall.y + 6):
		for x in range(th.x - 1, bakery_tile.x + 4):
			var pad_tile := Vector2i(x, y)
			if not is_inside_map(pad_tile):
				continue
			_prepare_test_tile(pad_tile, Defs.TILE_GRASS)
			height_map[pad_tile.y][pad_tile.x] = yard_height
	for x in range(th.x, bakery_tile.x + 3):
		var road_tile := Vector2i(x, road_y)
		if get_building_at_tile(road_tile).is_empty():
			_add_completed_building(Defs.BUILDING_ROAD, road_tile)
	var farm: Dictionary = _add_completed_building(Defs.BUILDING_FARM, farm_tile)
	var bakery: Dictionary = _add_completed_building(Defs.BUILDING_BAKERY, bakery_tile)
	_rebuild_occupied_tiles()
	_recompute_road_network()
	_try_staff_building(farm)
	_try_staff_building(bakery)
	_ensure_carriers()
	if farm.is_empty() or bakery.is_empty() or not bool(farm.get("connected", false)) or not bool(bakery.get("connected", false)):
		return _record_smoke(report, "bakery hauls Wheat from a full Farm", false)
	farm["local_inventory"][Defs.RESOURCE_WHEAT] = 8
	farm["assigned_staff"] = 0
	bakery["local_inventory"][Defs.RESOURCE_WHEAT] = 0
	bakery["local_inventory"][Defs.RESOURCE_BREAD] = 0
	bakery["production_timer"] = 0.0
	for worker in workers:
		if String(worker.get("type", "")) == "carrier" and String(worker.get("state", "")) == "Idle":
			_assign_carrier_task(worker)
	_simulate_seconds_for_test(0.5)
	var access := _building_access_tiles(bakery)
	var assigned_from_farm := false
	var dropped := 0
	for worker in workers:
		if String(worker.get("type", "")) != "carrier":
			continue
		var task: Dictionary = worker.get("task", {})
		if String(task.get("purpose", "")) != "processor" or String(task.get("resource", "")) != Defs.RESOURCE_WHEAT:
			continue
		if int(task.get("source", 0)) != int(farm.get("id", 0)):
			continue
		assigned_from_farm = true
		if int(worker.get("carried_amount", 0)) <= 0:
			_carrier_pickup(worker)
		if access.is_empty() or int(worker.get("carried_amount", 0)) <= 0:
			continue
		worker["position"] = access[0]
		worker["path"] = []
		worker["state"] = "Dropoff"
		worker["arrival_state"] = "Dropoff"
		if _carrier_dropoff(worker):
			dropped += 1
	_simulate_seconds_for_test(8.0)
	farm = get_building_at_tile(farm_tile)
	bakery = get_building_at_tile(bakery_tile)
	var bakery_wheat := int(bakery.get("local_inventory", {}).get(Defs.RESOURCE_WHEAT, 0))
	var bakery_bread := int(bakery.get("local_inventory", {}).get(Defs.RESOURCE_BREAD, 0))
	var totals := get_resources()
	var delivered := assigned_from_farm and dropped > 0 and (bakery_wheat > 0 or bakery_bread > 0 or int(totals.get(Defs.RESOURCE_BREAD, 0)) > 20)
	return _record_smoke(report, "bakery hauls Wheat from a full Farm", delivered)


func _record_staff_shortage_smoke(report: Array[String]) -> bool:
	start_new_run(MAP_WIDTH, MAP_HEIGHT, 818181, true)
	population_current = 1
	housing_capacity = 3
	central_inventory[Defs.RESOURCE_WOOD] = 30
	central_inventory[Defs.RESOURCE_BREAD] = 30
	var road_tile := town_hall_position + Vector2i(0, 1)
	var farm_tile := town_hall_position + Vector2i(0, 2)
	_prepare_test_tile(road_tile, Defs.TILE_GRASS)
	_prepare_test_tile(farm_tile, Defs.TILE_GRASS)
	request_build(Defs.BUILDING_ROAD, road_tile)
	request_build(Defs.BUILDING_FARM, farm_tile)
	_simulate_seconds_for_test(Defs.build_time(Defs.BUILDING_FARM) + 0.5)
	var farm: Dictionary = get_building_at_tile(farm_tile)
	var shortage := String(farm.get("status", "")) == "Needs workers." and int(farm.get("assigned_staff", 0)) == 0
	_simulate_seconds_for_test(10.0)
	farm = get_building_at_tile(farm_tile)
	var auto_staffed := int(farm.get("assigned_staff", 0)) == Defs.building_staff(Defs.BUILDING_FARM)
	return _record_smoke(report, "staff shortage auto-staffs after population growth", shortage and auto_staffed)


func _record_economy_save_load_smoke(report: Array[String]) -> bool:
	start_new_run(MAP_WIDTH, MAP_HEIGHT, 919191, true)
	population_current = 6
	housing_capacity = 10
	pop_growth_timer = 4.0
	var road_tile := town_hall_position + Vector2i(0, 1)
	var lumber_tile := town_hall_position + Vector2i(0, 2)
	var tree_tile := lumber_tile + Vector2i(1, 0)
	_prepare_test_tile(road_tile, Defs.TILE_GRASS)
	_prepare_test_tile(lumber_tile, Defs.TILE_GRASS)
	_prepare_test_tile(tree_tile, Defs.TILE_TREE)
	tree_deposits[_tile_key(tree_tile)] = 6
	request_build(Defs.BUILDING_ROAD, road_tile)
	request_build(Defs.BUILDING_LUMBER_CAMP, lumber_tile)
	_simulate_seconds_for_test(Defs.build_time(Defs.BUILDING_LUMBER_CAMP) + 0.5)
	var lumber: Dictionary = get_building_at_tile(lumber_tile)
	lumber["production_timer"] = 3.0
	var saved_state: Dictionary = _serialize_state().duplicate(true)
	_restore_state(saved_state)
	lumber = get_building_at_tile(lumber_tile)
	var preserved := population_current == 6 and housing_capacity == 10 and int(lumber.get("assigned_staff", 0)) == 1 and float(lumber.get("production_timer", 0.0)) >= 3.0
	var wood_before := int(central_inventory[Defs.RESOURCE_WOOD])
	_simulate_seconds_for_test(1.5)
	var resumed := int(central_inventory[Defs.RESOURCE_WOOD]) >= wood_before + 2
	return _record_smoke(report, "save/load preserves economy state and production timers", preserved and resumed)


func _prepare_test_tile(tile: Vector2i, tile_type: String) -> void:
	_set_tile(tile, tile_type)
	revealed_tiles[_tile_key(tile)] = true
	if tile_type != Defs.TILE_TREE:
		tree_deposits.erase(_tile_key(tile))
	if tile_type != Defs.TILE_ROCK:
		rock_deposits.erase(_tile_key(tile))
	if is_inside_map(tile) and not height_map.is_empty():
		var level := get_height(town_hall_position) if is_town_hall_founded() else get_height(tile)
		height_map[tile.y][tile.x] = level


func _simulate_seconds_for_test(seconds: float) -> void:
	var ticks := int(ceil(seconds / TICK_SECONDS))
	for _tick in range(ticks):
		advance_tick()


func _objective_complete(objective_id: String) -> bool:
	for objective in objectives:
		if String(objective.get("id", "")) == objective_id:
			return bool(objective.get("complete", false))
	return false


func _record_smoke(report: Array[String], label: String, condition: bool) -> bool:
	report.append("%s %s" % ["PASS" if condition else "FAIL", label])
	return condition


func _generate_map() -> void:
	for y in range(map_size.y):
		var row := []
		var height_row := []
		for x in range(map_size.x):
			row.append(Defs.TILE_GRASS)
			height_row.append(0)
		map_tiles.append(row)
		height_map.append(height_row)

	_generate_height_map()
	town_hall_position = Vector2i(
		clampi(roundi(float(map_size.x) * 0.18), 1, maxi(1, map_size.x - 6)),
		clampi(roundi(float(map_size.y) * 0.71), 1, maxi(1, map_size.y - 6))
	)
	rival_town_hall_position = Vector2i(
		clampi(roundi(float(map_size.x) * 0.77), 1, maxi(1, map_size.x - 6)),
		clampi(roundi(float(map_size.y) * 0.17), 1, maxi(1, map_size.y - 6))
	)
	shard_position = Vector2i(
		clampi(int(map_size.x / 2) + rng.randi_range(-4, 4), 12, map_size.x - 13),
		clampi(int(map_size.y / 2) + rng.randi_range(-4, 4), 12, map_size.y - 13)
	)
	_flatten_area(_footprint_center(town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL)), 8)
	_flatten_area(_footprint_center(rival_town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL)), 8)
	_shape_impact_crater()

	_place_random_resources()
	var town_center := _footprint_center(town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	var rival_center := _footprint_center(rival_town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	_clear_area(town_center, 8)
	_clear_area(rival_center, 8)
	_place_resource_cluster(town_center + Vector2i(-11, -10), Defs.TILE_TREE, 40, 4)
	_place_resource_cluster(town_center + Vector2i(12, 9), Defs.TILE_TREE, 34, 6)
	_place_resource_cluster(town_center + Vector2i(13, 2), Defs.TILE_ROCK, 25, 32)
	_place_resource_cluster(town_center + Vector2i(5, -14), Defs.TILE_ROCK, 20, 32)
	_place_resource_cluster(rival_center + Vector2i(11, 10), Defs.TILE_TREE, 40, 4)
	_place_resource_cluster(rival_center + Vector2i(-12, -9), Defs.TILE_TREE, 34, 6)
	_place_resource_cluster(rival_center + Vector2i(-13, -2), Defs.TILE_ROCK, 25, 32)
	_place_resource_cluster(rival_center + Vector2i(-5, 14), Defs.TILE_ROCK, 20, 32)
	_ensure_founding_apron(town_center)
	_ensure_founding_apron(rival_center)

	_set_tile(shard_position, Defs.TILE_SHARD)
	for offset in _radius_offsets(4):
		var tile: Vector2i = shard_position + offset
		if not is_inside_map(tile) or tile == shard_position:
			continue
		var distance := _tile_distance(tile, shard_position)
		if distance <= 2.2:
			_set_tile(tile, Defs.TILE_GRASS)
			tree_deposits.erase(_tile_key(tile))
			if rng.randf() < 0.55:
				_set_tile(tile, Defs.TILE_ROCK)
				rock_deposits[_tile_key(tile)] = 18
		elif rng.randf() < 0.72:
			_set_tile(tile, Defs.TILE_ROCK)
			rock_deposits[_tile_key(tile)] = 28
	for claim_pad in [
		shard_position + Vector2i(-5, 0),
		shard_position + Vector2i(4, -1)
	]:
		_clear_area(claim_pad, 2)
		_flatten_area(claim_pad, 2)
	_clear_corridor(_town_hall_entrance_tile(), shard_position + Vector2i(-5, 0), 1)
	_clear_corridor(_rival_town_hall_entrance_tile(), shard_position + Vector2i(4, -1), 1)
	_place_wilderness_opportunities()
	_place_enemy_camps()
	_register_world_features()


func _generate_height_map() -> void:
	var phase_x := rng.randf_range(-PI, PI)
	var phase_y := rng.randf_range(-PI, PI)
	var hill_a := Vector2(map_size) * Vector2(0.24, 0.28)
	var hill_b := Vector2(map_size) * Vector2(0.76, 0.69)
	var valley := Vector2(map_size) * Vector2(0.54, 0.47)
	for y in range(map_size.y):
		for x in range(map_size.x):
			var point := Vector2(x, y)
			var broad_waves := sin(float(x) * 0.115 + phase_x) * 0.46 + cos(float(y) * 0.105 + phase_y) * 0.42
			var cross_wave := sin(float(x + y) * 0.062 + phase_x - phase_y) * 0.28
			var hills := 1.18 * exp(-point.distance_squared_to(hill_a) / 420.0)
			hills += 1.05 * exp(-point.distance_squared_to(hill_b) / 520.0)
			var valley_cut := 0.82 * exp(-point.distance_squared_to(valley) / 390.0)
			var elevation := 1.15 + broad_waves + cross_wave + hills - valley_cut
			height_map[y][x] = clampi(floori(elevation), 0, 3)


func _flatten_area(center: Vector2i, radius: int) -> void:
	var level := get_height(center)
	for offset in _radius_offsets(radius):
		var tile := center + offset
		if is_inside_map(tile):
			height_map[tile.y][tile.x] = level


func _shape_impact_crater() -> void:
	var crater_floor := maxi(0, get_height(shard_position) - 1)
	var rim_height := mini(3, crater_floor + 2)
	for offset in _radius_offsets(6):
		var tile: Vector2i = shard_position + offset
		if not is_inside_map(tile):
			continue
		var distance := _tile_distance(tile, shard_position)
		if distance <= 2.4:
			height_map[tile.y][tile.x] = crater_floor if rng.randf() > 0.16 else mini(crater_floor + 1, rim_height)
		elif distance <= 4.2:
			var bulge := 1 if rng.randf() < 0.22 and (offset.x + offset.y) % 2 == 0 else 0
			height_map[tile.y][tile.x] = mini(3, rim_height + bulge)
		elif distance <= 6.0 and rng.randf() < 0.38:
			height_map[tile.y][tile.x] = mini(3, get_height(tile) + 1)


func _place_wilderness_opportunities() -> void:
	var town_center := _footprint_center(town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	var toward_shard := Vector2(shard_position - town_center).normalized()
	var forest_center := Vector2i(town_center + Vector2i(roundi(toward_shard.x * 14.0), roundi(toward_shard.y * 10.0)) + Vector2i(rng.randi_range(-3, 3), rng.randi_range(-2, 2)))
	var stone_center := Vector2i(town_center + Vector2i(roundi(toward_shard.x * 18.0 + toward_shard.y * 6.0), roundi(toward_shard.y * 16.0 - toward_shard.x * 5.0)))
	var cache_center := Vector2i(town_center + Vector2i(roundi(toward_shard.x * 22.0), roundi(toward_shard.y * 18.0)) + Vector2i(rng.randi_range(-4, 4), rng.randi_range(-3, 3)))
	_place_resource_cluster(forest_center, Defs.TILE_TREE, 36, 6)
	_place_resource_cluster(stone_center, Defs.TILE_ROCK, 22, 36)
	_clear_area(cache_center, 1)
	_place_resource_cluster(cache_center, Defs.TILE_ROCK, 8, 20)
	_register_feature("rich_forest", forest_center, "A dense stand of timber waits beyond the first hills.")
	_register_feature("stone_region", stone_center, "Broken stone ridges hold a rich quarry.")
	_register_feature("ruined_cache", cache_center, "Someone defended this ridge before you.")
	_place_fog_discoveries(town_center, toward_shard)


func _place_fog_discoveries(town_center: Vector2i, toward_shard: Vector2) -> void:
	var side := Vector2(-toward_shard.y, toward_shard.x)
	var cart := town_center + Vector2i(roundi(side.x * 18.0 + toward_shard.x * 10.0), roundi(side.y * 18.0 + toward_shard.y * 10.0))
	var ruins := town_center + Vector2i(roundi(-side.x * 19.0 + toward_shard.x * 12.0), roundi(-side.y * 19.0 + toward_shard.y * 11.0))
	var traces := town_center + Vector2i(roundi(toward_shard.x * 20.0), roundi(toward_shard.y * 18.0))
	var landmark := town_center + Vector2i(roundi(-toward_shard.x * 17.0 + side.x * 10.0), roundi(-toward_shard.y * 16.0 + side.y * 10.0))
	cart = _clamp_discovery_tile(cart)
	ruins = _clamp_discovery_tile(ruins)
	traces = _clamp_discovery_tile(traces)
	landmark = _clamp_discovery_tile(landmark)
	_clear_area(cart, 1)
	_register_feature(Discoveries.KIND_CART, cart, "An overturned cart, still packed.")
	_register_feature(Discoveries.KIND_RUINS, ruins, "Someone defended this ridge before you.")
	_register_feature(Discoveries.KIND_TRACES, traces, "Tracks lead into the fog.")
	_register_feature(Discoveries.KIND_LANDMARK, landmark, "A standing stone older than the crater.")


func _clamp_discovery_tile(tile: Vector2i) -> Vector2i:
	return Vector2i(clampi(tile.x, 3, map_size.x - 4), clampi(tile.y, 3, map_size.y - 4))


func _register_world_features() -> void:
	_register_feature("shard", shard_position, "The Shard still burns in the impact crater.")
	_register_feature("rival", rival_town_hall_position, "Another realm is pushing toward the same Shard.")
	for camp in enemy_camps:
		_register_feature("enemy_camp", Vector2i(camp.get("position", Vector2i.ZERO)), "A hostile camp waits in the fog.")


func _register_feature(kind: String, position: Vector2i, message: String) -> void:
	if not is_inside_map(position):
		return
	world_features.append({
		"id": "%s_%d_%d" % [kind, position.x, position.y],
		"kind": kind,
		"position": position,
		"message": message,
		"revealed": false
	})


func _place_enemy_camps() -> void:
	var candidates := [
		Vector2i(9, 10),
		Vector2i(map_size.x - 13, map_size.y - 14),
		Vector2i(10, map_size.y - 15),
		Vector2i(map_size.x - 17, int(map_size.y / 2) + 8)
	]
	for position_value in candidates:
		var position: Vector2i = position_value
		if _tile_distance(position, town_hall_position) < 18.0 or _tile_distance(position, rival_town_hall_position) < 18.0 or _tile_distance(position, shard_position) < 8.0:
			continue
		_clear_area(position, 2)
		_flatten_area(position, 2)
		enemy_camps.append({
			"id": next_camp_id,
			"position": position,
			"active": false,
			"defenders_spawned": false,
			"destroyed": false
		})
		next_camp_id += 1


func _place_random_resources() -> void:
	var town_center := _footprint_center(town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	for i in range(680):
		var tile := Vector2i(rng.randi_range(1, map_size.x - 2), rng.randi_range(1, map_size.y - 2))
		if _tile_distance(tile, town_hall_position) < 8.0 or _tile_distance(tile, rival_town_hall_position) < 8.0:
			continue
		var toward_shard := _tile_distance(tile, shard_position)
		var toward_home := _tile_distance(tile, town_center)
		var tree_chance := 0.74 if toward_home < 16.0 else (0.48 if toward_shard < 12.0 else 0.62)
		if rng.randf() < tree_chance:
			_set_tile(tile, Defs.TILE_TREE)
			tree_deposits[_tile_key(tile)] = 6 if toward_shard > 10.0 else 4
	for i in range(240):
		var tile := Vector2i(rng.randi_range(1, map_size.x - 2), rng.randi_range(1, map_size.y - 2))
		if _tile_distance(tile, town_hall_position) < 6.0 or _tile_distance(tile, rival_town_hall_position) < 6.0:
			continue
		if get_tile(tile) != Defs.TILE_GRASS:
			continue
		var rock_chance := 0.42 if _tile_distance(tile, shard_position) < 14.0 else 0.18
		if rng.randf() > rock_chance:
			continue
		_set_tile(tile, Defs.TILE_ROCK)
		rock_deposits[_tile_key(tile)] = 24


func _place_resource_cluster(center: Vector2i, tile_type: String, count: int, deposit_amount: int) -> void:
	var placed := 0
	var attempts := 0
	while placed < count and attempts < count * 8:
		attempts += 1
		var tile := center + Vector2i(rng.randi_range(-3, 3), rng.randi_range(-3, 3))
		if not is_inside_map(tile):
			continue
		if _tile_distance(tile, town_hall_position) < 8.0:
			continue
		if get_tile(tile) != Defs.TILE_GRASS:
			continue
		_set_tile(tile, tile_type)
		if tile_type == Defs.TILE_TREE:
			tree_deposits[_tile_key(tile)] = deposit_amount
			rock_deposits.erase(_tile_key(tile))
		elif tile_type == Defs.TILE_ROCK:
			rock_deposits[_tile_key(tile)] = deposit_amount
			tree_deposits.erase(_tile_key(tile))
		placed += 1


func _clear_area(center: Vector2i, radius: int) -> void:
	for offset in _radius_offsets(radius):
		var tile: Vector2i = center + offset
		if not is_inside_map(tile):
			continue
		_set_tile(tile, Defs.TILE_GRASS)
		tree_deposits.erase(_tile_key(tile))
		rock_deposits.erase(_tile_key(tile))


func _ensure_founding_apron(center: Vector2i) -> void:
	_clear_area(center, 8)
	_flatten_area(center, 8)
	var toward := Vector2(shard_position - center)
	var side := Vector2i(1 if toward.x <= 0.0 else -1, 0)
	_clear_area(center + side * 5, 3)
	_clear_area(center + Vector2i(0, 4), 3)


func _clear_corridor(start: Vector2i, finish: Vector2i, half_width: int) -> void:
	var steps := maxi(absi(finish.x - start.x), absi(finish.y - start.y))
	if steps <= 0:
		return
	for index in range(steps + 1):
		var fraction := float(index) / float(steps)
		var center := Vector2i(
			roundi(lerpf(float(start.x), float(finish.x), fraction)),
			roundi(lerpf(float(start.y), float(finish.y), fraction))
		)
		_clear_area(center, half_width)


func _set_tile(tile: Vector2i, tile_type: String) -> void:
	if not is_inside_map(tile):
		return
	var key := _tile_key(tile)
	if tile_type == Defs.TILE_TREE:
		rock_deposits.erase(key)
	elif tile_type == Defs.TILE_ROCK:
		tree_deposits.erase(key)
	else:
		tree_deposits.erase(key)
		rock_deposits.erase(key)
	map_tiles[tile.y][tile.x] = tile_type
	path_grid_dirty = true


func _sanitize_resource_deposits() -> void:
	for key in tree_deposits.keys():
		var tile := _tile_from_key(String(key))
		if not is_inside_map(tile) or String(get_tile(tile)) != Defs.TILE_TREE:
			tree_deposits.erase(key)
	for key in rock_deposits.keys():
		var tile := _tile_from_key(String(key))
		if not is_inside_map(tile) or String(get_tile(tile)) != Defs.TILE_ROCK:
			rock_deposits.erase(key)


func _add_completed_building(building_type: String, tile: Vector2i) -> Dictionary:
	var building := _create_building(building_type, tile)
	building["construction"] = false
	building["completed"] = true
	buildings.append(building)
	_try_staff_building(building)
	if building_type != Defs.BUILDING_TOWN_HALL and building_type != Defs.BUILDING_ROAD:
		stats["buildings_completed"] = int(stats.get("buildings_completed", 0)) + 1
	return building


func _create_building(building_type: String, tile: Vector2i) -> Dictionary:
	var building_id := next_building_id
	next_building_id += 1
	var inventory := Defs.empty_inventory()
	return {
		"id": building_id,
		"type": building_type,
		"planned_type": "",
		"position": tile,
		"rotation": 0,
		"footprint": _vector_to_data(Defs.building_footprint(building_type)),
		"hp": Defs.building_hp(building_type),
		"max_hp": Defs.building_hp(building_type),
		"local_inventory": inventory,
		"local_capacity": Defs.local_capacity(building_type),
		"construction": building_type == Defs.BUILDING_CONSTRUCTION_SITE,
		"completed": building_type != Defs.BUILDING_CONSTRUCTION_SITE,
		"materials_needed": {},
		"materials_delivered": Defs.empty_inventory(),
		"materials_in_transit": Defs.empty_inventory(),
		"build_cost": {},
		"construction_total": 0.0,
		"construction_remaining": 0.0,
		"assigned_staff": 0,
		"soldiers_assigned": 0,
		"training_progress": 0.0,
		"staff_priority": _default_staff_priority(building_type),
		"staffing_enabled": true,
		"production_timer": 0.0,
		"storage_paused": false,
		"deposit_remaining": 0,
		"connected": false,
		"staffed": Defs.building_staff(building_type) == 0 and building_type != Defs.BUILDING_WATCHTOWER,
		"abandoned": false,
		"work_timer": _initial_work_timer(building_type),
		"attack_cooldown": 0.0,
		"damage_flash": 0.0,
		"status": "Ready.",
		"site_clearing": false,
		"clear_tiles": [],
		"last_delivery_elapsed": -1.0,
		"last_production_elapsed": -1.0,
		"last_stall_kind": "",
		"placement_quality": 1.0,
		"placement_percent": 100,
		"placement_band": Placement.BAND_GOOD
	}


func _default_staff_priority(building_type: String) -> int:
	if building_type in [Defs.BUILDING_FARM, Defs.BUILDING_BAKERY, Defs.BUILDING_BARRACKS]:
		return STAFF_PRIORITY_HIGH
	if building_type in [Defs.BUILDING_QUARRY, Defs.BUILDING_SAWMILL]:
		return STAFF_PRIORITY_LOW
	return STAFF_PRIORITY_NORMAL


func _initial_work_timer(building_type: String) -> float:
	if Defs.PRODUCTION_DEFS.has(building_type):
		return float(Defs.PRODUCTION_DEFS[building_type].get("interval", 5.0))
	return 0.0


func _deduct_cost(cost: Dictionary) -> void:
	for resource_type in cost.keys():
		central_inventory[resource_type] = int(central_inventory.get(resource_type, 0)) - int(cost[resource_type])


func _reserve_cost(cost: Dictionary) -> void:
	for resource_type in cost.keys():
		reserved_inventory[resource_type] = int(reserved_inventory.get(resource_type, 0)) + int(cost[resource_type])


func _release_reserved_cost(cost: Dictionary) -> void:
	for resource_type in cost.keys():
		reserved_inventory[resource_type] = max(0, int(reserved_inventory.get(resource_type, 0)) - int(cost[resource_type]))


func _release_reserved_resource(resource_type: String, amount: int) -> void:
	reserved_inventory[resource_type] = max(0, int(reserved_inventory.get(resource_type, 0)) - amount)


func _try_staff_building(building: Dictionary) -> bool:
	if building.is_empty() or bool(building.get("construction", false)):
		return false
	if not bool(building.get("staffing_enabled", true)):
		return false
	if String(building.get("type", "")) == Defs.BUILDING_WATCHTOWER:
		if int(building.get("soldiers_assigned", 0)) >= 1:
			building["staffed"] = true
			building["status"] = "Watching."
			return true
		if soldiers_available() > 0:
			building["soldiers_assigned"] = 1
			building["staffed"] = true
			building["status"] = "Watching."
			return true
		building["staffed"] = false
		building["status"] = "Needs a trained soldier."
		return false
	var required := Defs.building_staff(String(building["type"]))
	if required <= 0:
		building["assigned_staff"] = 0
		building["staffed"] = true
		building["abandoned"] = false
		_recalculate_workers_assigned()
		return true

	var current := clampi(int(building.get("assigned_staff", 0)), 0, required)
	building["assigned_staff"] = current
	_recalculate_workers_assigned()
	var missing := required - current
	if missing <= 0:
		building["staffed"] = true
		building["abandoned"] = false
		if String(building.get("status", "")) == "Needs workers.":
			building["status"] = "Active."
		return true
	if workers_free() >= missing:
		building["assigned_staff"] = required
		building["staffed"] = true
		building["abandoned"] = false
		building["status"] = "Active."
		_recalculate_workers_assigned()
		return true

	building["staffed"] = false
	building["abandoned"] = false
	building["status"] = "Needs workers."
	return false


func _release_staff(building: Dictionary) -> void:
	if building.is_empty():
		return
	if String(building.get("type", "")) == Defs.BUILDING_WATCHTOWER:
		building["soldiers_assigned"] = 0
		building["staffed"] = false
		building["status"] = "Needs a trained soldier."
		_sync_production_workers()
		return
	var required := Defs.building_staff(String(building.get("type", "")))
	building["assigned_staff"] = 0
	building["staffed"] = required <= 0
	if required > 0 and not bool(building.get("construction", false)):
		building["status"] = "Needs workers."
	_recalculate_workers_assigned()


func _recalculate_workers_assigned() -> void:
	var total := 0
	for building in buildings:
		if bool(building.get("construction", false)) or bool(building.get("abandoned", false)):
			building["assigned_staff"] = 0
			continue
		var required := Defs.building_staff(String(building["type"]))
		var assigned := clampi(int(building.get("assigned_staff", 0)), 0, required)
		building["assigned_staff"] = assigned
		if required > 0:
			building["staffed"] = assigned >= required
		total += assigned
	workers_assigned = total


func _auto_staff_unstaffed_buildings() -> void:
	_recalculate_workers_assigned()
	var candidates: Array = []
	for building in buildings:
		if bool(building.get("construction", false)) or bool(building.get("abandoned", false)):
			continue
		if bool(building.get("storage_paused", false)):
			continue
		if not bool(building.get("staffing_enabled", true)):
			continue
		if Defs.building_staff(String(building["type"])) <= 0:
			continue
		candidates.append(building)
	candidates.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		var first_priority := int(first.get("staff_priority", STAFF_PRIORITY_NORMAL))
		var second_priority := int(second.get("staff_priority", STAFF_PRIORITY_NORMAL))
		if first_priority == second_priority:
			return int(first.get("id", 0)) < int(second.get("id", 0))
		return first_priority > second_priority
	)
	for building in candidates:
		if int(building.get("assigned_staff", 0)) < Defs.building_staff(String(building["type"])):
			_try_staff_building(building)
	_auto_staff_towers()
	_sync_production_workers()


func _auto_staff_towers() -> void:
	for building in buildings:
		if String(building.get("type", "")) != Defs.BUILDING_WATCHTOWER or bool(building.get("construction", false)):
			continue
		if int(building.get("soldiers_assigned", 0)) <= 0 and soldiers_available() > 0:
			building["soldiers_assigned"] = 1
			building["staffed"] = true
			building["status"] = "Watching."


func _rebalance_staffing() -> void:
	for building in buildings:
		if bool(building.get("construction", false)) or bool(building.get("abandoned", false)):
			continue
		if Defs.building_staff(String(building.get("type", ""))) <= 0:
			continue
		building["assigned_staff"] = 0
		building["staffed"] = false
	_recalculate_workers_assigned()
	_auto_staff_unstaffed_buildings()


func _enforce_worker_limit() -> void:
	_recalculate_workers_assigned()
	if workers_assigned + soldiers_total <= population_current:
		return
	for index in range(buildings.size() - 1, -1, -1):
		var building: Dictionary = buildings[index]
		if int(building.get("assigned_staff", 0)) <= 0:
			continue
		_release_staff(building)
		if workers_assigned + soldiers_total <= population_current:
			return
	while soldiers_total > 0 and workers_assigned + soldiers_total > population_current:
		soldiers_total -= 1
	var soldiers_to_assign := soldiers_total
	for building in buildings:
		if String(building.get("type", "")) != Defs.BUILDING_WATCHTOWER:
			continue
		if int(building.get("soldiers_assigned", 0)) > 0 and soldiers_to_assign > 0:
			soldiers_to_assign -= 1
		else:
			building["soldiers_assigned"] = 0
			building["staffed"] = false


func _rebuild_occupied_tiles() -> void:
	occupied_tiles.clear()
	for building in buildings:
		for footprint_tile in get_building_footprint_tiles(building):
			occupied_tiles[_tile_key(footprint_tile)] = int(building["id"])
	path_grid_dirty = true


func _recompute_road_network() -> void:
	connected_roads.clear()
	var queue: Array = []
	for building in buildings:
		if String(building["type"]) != Defs.BUILDING_ROAD:
			continue
		var tile: Vector2i = building["position"]
		if _is_adjacent_to_town_hall(tile):
			connected_roads[_tile_key(tile)] = true
			queue.append(tile)

	var index := 0
	while index < queue.size():
		var current: Vector2i = queue[index]
		index += 1
		for neighbor in _neighbors(current):
			var building := get_building_at_tile(neighbor)
			if building.is_empty() or String(building["type"]) != Defs.BUILDING_ROAD:
				continue
			if absi(get_height(current) - get_height(neighbor)) > 2:
				continue
			var key := _tile_key(neighbor)
			if connected_roads.has(key):
				continue
			connected_roads[key] = true
			queue.append(neighbor)

	connected_walls.clear()
	var wall_queue: Array[Vector2i] = []
	for building in buildings:
		if not _is_wall_network_building(building):
			continue
		var wall_tile: Vector2i = building["position"]
		var wall_type := String(building.get("planned_type", "")) if bool(building.get("construction", false)) else String(building.get("type", ""))
		if wall_type == Defs.BUILDING_WATCHTOWER and _has_adjacent_connected_road(wall_tile):
			connected_walls[_tile_key(wall_tile)] = true
			wall_queue.append(wall_tile)
	index = 0
	while index < wall_queue.size():
		var current_wall: Vector2i = wall_queue[index]
		index += 1
		for neighbor in _neighbors(current_wall):
			var neighbor_building := get_building_at_tile(neighbor)
			if neighbor_building.is_empty() or not _is_wall_network_building(neighbor_building):
				continue
			var key := _tile_key(neighbor)
			if connected_walls.has(key):
				continue
			connected_walls[key] = true
			wall_queue.append(neighbor)

	for building in buildings:
		var building_type := String(building["type"])
		if building_type == Defs.BUILDING_TOWN_HALL \
			or (bool(building.get("construction", false)) and String(building.get("planned_type", "")) == Defs.BUILDING_TOWN_HALL):
			building["connected"] = true
		elif building_type == Defs.BUILDING_ROAD:
			building["connected"] = connected_roads.has(_tile_key(building["position"]))
		elif _is_wall_network_building(building):
			building["connected"] = connected_walls.has(_tile_key(building["position"]))
		else:
			building["connected"] = _footprint_touches_connected_road(building["position"], _building_footprint(building))
			if bool(building.get("construction", false)) and not bool(building["connected"]):
				if String(building.get("planned_type", "")) == Defs.BUILDING_ROAD:
					building["status"] = "Planned — waiting for earlier road segments."
				elif _footprint_touches_planned_or_connected_road(building["position"], _building_footprint(building)):
					building["status"] = "Planned — waiting for its road connection."
				else:
					building["status"] = "No road connection."
	path_grid_dirty = true


func building_vision_radius(building_type: String) -> int:
	match building_type:
		Defs.BUILDING_TOWN_HALL:
			return VISION_TOWN_HALL
		Defs.BUILDING_WATCHTOWER:
			return VISION_WATCHTOWER
		Defs.BUILDING_OUTPOST:
			return VISION_OUTPOST
		Defs.BUILDING_LUMEN_PILLAR:
			return VISION_LUMEN
		Defs.BUILDING_ROAD:
			return VISION_ROAD
		_:
			return VISION_BUILDING


func unit_vision_radius(unit_type: String) -> int:
	if unit_type == "guard":
		return VISION_SOLDIER
	return VISION_WORKER


func _reveal_from_world() -> void:
	var town_center := _footprint_center(town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	if not is_town_hall_founded():
		_reveal_radius(town_center, INITIAL_REVEAL_RADIUS)
		return
	_reveal_radius(town_center, building_vision_radius(Defs.BUILDING_TOWN_HALL))
	for building in buildings:
		if bool(building.get("construction", false)):
			continue
		var building_type := String(building["type"])
		if building_type == Defs.BUILDING_TOWN_HALL:
			continue
		var center: Vector2i = building["position"]
		if building_type != Defs.BUILDING_ROAD:
			center = _footprint_center(building["position"], _building_footprint(building))
		_reveal_radius(center, building_vision_radius(building_type))


func _unit_tile(unit: Dictionary) -> Vector2i:
	var position_value: Variant = unit.get("position", Vector2i.ZERO)
	if typeof(position_value) == TYPE_VECTOR2I:
		return position_value
	if typeof(position_value) == TYPE_VECTOR2:
		return Vector2i(roundi(position_value.x), roundi(position_value.y))
	return _vector_from_data(position_value, Vector2i.ZERO)


func _cached_vision_tile(unit: Dictionary) -> Vector2i:
	var raw: Variant = unit.get("last_vision_tile", null)
	if raw == null:
		return Vector2i(99999, 99999)
	if typeof(raw) == TYPE_VECTOR2I:
		return raw
	if typeof(raw) == TYPE_VECTOR2:
		return Vector2i(roundi(raw.x), roundi(raw.y))
	if typeof(raw) == TYPE_STRING:
		var parts: PackedStringArray = String(raw).trim_prefix("(").trim_suffix(")").split(",")
		if parts.size() == 2:
			return Vector2i(int(parts[0]), int(parts[1]))
		return Vector2i(99999, 99999)
	return _vector_from_data(raw, Vector2i(99999, 99999))


func _update_unit_vision() -> void:
	# Tile-change only. A future scout/explore command just paths a unit;
	# fog already follows the walker. last_vision_tile is a runtime cache;
	# JSON saves used to stringify Vector2i and crash the typed read.
	for worker in workers:
		if int(worker.get("hp", WORKER_MAX_HP)) <= 0:
			continue
		var tile := _unit_tile(worker)
		var last_tile := _cached_vision_tile(worker)
		if tile == last_tile:
			continue
		worker["last_vision_tile"] = tile
		_reveal_radius(tile, unit_vision_radius(String(worker.get("type", ""))))


func _is_wall_network_building(building: Dictionary) -> bool:
	var building_type := String(building.get("type", ""))
	if building_type in [Defs.BUILDING_WALL, Defs.BUILDING_WATCHTOWER]:
		return true
	return bool(building.get("construction", false)) and String(building.get("planned_type", "")) in [Defs.BUILDING_WALL, Defs.BUILDING_WATCHTOWER]


func _reveal_radius(center: Vector2i, radius: int) -> void:
	for offset in _radius_offsets(radius):
		var tile: Vector2i = center + offset
		if is_inside_map(tile) and _manhattan(center, tile) <= radius:
			revealed_tiles[_tile_key(tile)] = true
	_notice_discoveries()


func _process_carriers(delta: float) -> void:
	if is_gate_closed():
		for worker in workers:
			if String(worker.get("type", "")) != "carrier" or String(worker.get("state", "")) == "Sheltered":
				continue
			if worker["path"].is_empty():
				# Drop night-paused hauls so reserved construction does not
				# stay marked in-transit until a dawn resume can reassign.
				if not Dictionary(worker.get("task", {})).is_empty() or int(worker.get("carried_amount", 0)) > 0:
					_clear_worker(worker)
				_send_worker_to_shelter(worker)
			else:
				_advance_carrier(worker, delta)
		return
	_ensure_carriers()
	_rebuild_task_indexes()
	for worker in workers:
		if String(worker.get("type", "")) != "carrier":
			continue
		_advance_carrier(worker, delta)
		if String(worker.get("state", "")) == "Moving" and Array(worker.get("path", [])).is_empty():
			worker["state"] = String(worker.get("arrival_state", "Idle"))
	for worker in workers:
		if String(worker.get("type", "")) != "carrier":
			continue
		if String(worker["state"]) == "Idle":
			_assign_carrier_task(worker)
		elif String(worker["state"]) == "Building":
			var task: Dictionary = worker.get("task", {})
			if String(task.get("purpose", "")) == "road_build":
				var road_site := _find_building_by_id(int(task.get("destination", 0)))
				if road_site.is_empty() or not bool(road_site.get("construction", false)):
					_clear_worker(worker)
				else:
					road_site["status"] = "Building road."
			else:
				worker["action_timer"] = maxf(0.0, float(worker.get("action_timer", 0.0)) - delta)
				if float(worker["action_timer"]) <= 0.0:
					_clear_worker(worker, false)
		elif String(worker["state"]) == "Pickup":
			_carrier_pickup(worker)
		elif String(worker["state"]) == "Dropoff":
			_carrier_dropoff(worker)
		elif String(worker["state"]) == "Blocked":
			_retry_blocked_carrier(worker)


func _ensure_carriers() -> void:
	if presentation_opening_active:
		return
	if connected_roads.is_empty():
		return
	var target: int = max(1, int(floor(float(housing_capacity) / 5.0)))
	while _carrier_count() < target:
		var spawn_tile := _first_connected_road_tile()
		if not is_inside_map(spawn_tile):
			return
		workers.append({
			"id": next_worker_id,
			"type": "carrier",
			"position": spawn_tile,
			"path": [],
			"state": "Idle",
			"arrival_state": "Idle",
			"move_elapsed": 0.0,
			"capacity": 5,
			"carried_resource": "",
			"carried_amount": 0,
			"task": {},
			"shelter_position": Vector2i(-1, -1),
			"hp": WORKER_MAX_HP,
			"max_hp": WORKER_MAX_HP,
			"hungry": false
		})
		next_worker_id += 1
	_refresh_worker_hunger_flags()


func _carrier_count() -> int:
	var count := 0
	for worker in workers:
		if String(worker.get("type", "")) == "carrier":
			count += 1
	return count


func _sync_production_workers() -> void:
	var desired: Dictionary = {}
	for building in buildings:
		if bool(building.get("construction", false)) or bool(building.get("abandoned", false)):
			continue
		var assigned := int(building.get("assigned_staff", 0))
		for slot in range(assigned):
			var role_key := "%d:%d" % [int(building["id"]), slot]
			desired[role_key] = true
			if _find_production_worker(role_key).is_empty():
				workers.append(_create_production_worker(building, slot, role_key))
		if String(building.get("type", "")) == Defs.BUILDING_WATCHTOWER:
			for slot in range(int(building.get("soldiers_assigned", 0))):
				var guard_key := "tower:%d:%d" % [int(building["id"]), slot]
				desired[guard_key] = true
				if _find_production_worker(guard_key).is_empty():
					workers.append(_create_production_worker(building, slot, guard_key))
	for slot in range(soldiers_available()):
		var patrol_key := "patrol:%d" % slot
		desired[patrol_key] = true
		if _find_production_worker(patrol_key).is_empty():
			workers.append(_create_patrol_worker(slot, patrol_key))

	for index in range(workers.size() - 1, -1, -1):
		var worker: Dictionary = workers[index]
		if String(worker.get("type", "")) in ["carrier", "clearer"]:
			continue
		if not desired.has(String(worker.get("role_key", ""))):
			workers.remove_at(index)
	_refresh_worker_hunger_flags()


func _find_production_worker(role_key: String) -> Dictionary:
	var scanned := 0
	for worker in workers:
		scanned += 1
		if String(worker.get("role_key", "")) == role_key:
			_profile_scan("production_worker_lookup", scanned)
			return worker
	_profile_scan("production_worker_lookup", scanned)
	return {}


func _create_production_worker(building: Dictionary, slot: int, role_key: String) -> Dictionary:
	var destination := _footprint_center(building["position"], _building_footprint(building)) if String(building.get("type", "")) == Defs.BUILDING_WATCHTOWER else _worker_home_tile(building)
	var worker_position := _town_hall_entrance_tile()
	var initial_path := _find_worker_path(worker_position, destination)
	if worker_position != destination and initial_path.is_empty():
		worker_position = destination
	var indoor_state := "Working" if String(building.get("type", "")) == Defs.BUILDING_LUMBER_CAMP else "Working indoors"
	var worker := {
		"id": next_worker_id,
		"type": _worker_type_for_building(String(building["type"])),
		"building_id": int(building["id"]),
		"slot": slot,
		"role_key": role_key,
		"position": worker_position,
		"path": initial_path,
		"state": indoor_state if initial_path.is_empty() else "Leaving Town Hall",
		"arrival_state": indoor_state,
		"move_elapsed": 0.0,
		"activity_timer": 0.6 + float(slot) * 0.35,
		"capacity": 0,
		"carried_resource": "",
		"carried_amount": 0,
		"task": {},
		"shelter_position": Vector2i(-1, -1),
		"hp": WORKER_MAX_HP,
		"max_hp": WORKER_MAX_HP,
		"hungry": false
	}
	next_worker_id += 1
	return worker


func _create_patrol_worker(slot: int, role_key: String) -> Dictionary:
	var spawn := _first_connected_road_tile()
	if not is_inside_map(spawn):
		spawn = _footprint_center(town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	var worker := {
		"id": next_worker_id,
		"type": "guard",
		"building_id": 0,
		"slot": slot,
		"role_key": role_key,
		"position": spawn,
		"path": [],
		"state": "Patrolling",
		"arrival_state": "Patrolling",
		"move_elapsed": 0.0,
		"activity_timer": 0.0,
		"attack_timer": 0.0,
		"capacity": 0,
		"carried_resource": "",
		"carried_amount": 0,
		"task": {},
		"shelter_position": Vector2i(-1, -1),
		"hp": WORKER_MAX_HP + 10,
		"max_hp": WORKER_MAX_HP + 10,
		"hungry": false,
		"display_name": Scout.display_name({"id": next_worker_id}, rng_seed)
	}
	next_worker_id += 1
	return worker


func _worker_type_for_building(building_type: String) -> String:
	if building_type == Defs.BUILDING_LUMBER_CAMP:
		return "woodcutter"
	if building_type == Defs.BUILDING_QUARRY:
		return "miner"
	if building_type == Defs.BUILDING_FARM:
		return "farmer"
	if building_type == Defs.BUILDING_SAWMILL:
		return "sawyer"
	if building_type == Defs.BUILDING_BAKERY:
		return "baker"
	if building_type == Defs.BUILDING_WATCHTOWER:
		return "guard"
	return "settler"


func _update_production_workers(delta: float) -> void:
	for worker in workers:
		if String(worker.get("type", "")) in ["carrier", "clearer"]:
			continue
		var building := _find_building_by_id(int(worker.get("building_id", 0)))
		if String(worker.get("type", "")) == "guard":
			if building.is_empty():
				_update_patrol_worker(worker, delta)
			else:
				worker["path"] = []
				worker["position"] = _footprint_center(building["position"], _building_footprint(building))
				var target_id := int(building.get("combat_target_id", 0))
				if target_id > 0:
					worker["combat_target_id"] = target_id
					worker["combat_target_position"] = building.get("combat_target_position", _vector_to_data(worker["position"]))
					if String(building.get("status", "")) == "Firing.":
						worker["attack_flash"] = maxf(float(worker.get("attack_flash", 0.0)), 0.42)
						worker["state"] = "Fighting"
					else:
						worker["state"] = "Night Watch" if is_night else "Guarding"
				else:
					worker["combat_target_id"] = 0
					worker["state"] = "Night Watch" if is_night else "Guarding"
			continue
		if building.is_empty():
			continue
		if is_gate_closed():
			if String(worker.get("type", "")) == "guard":
				worker["state"] = "Guarding"
				worker["path"] = []
				worker["position"] = building["position"]
			elif String(worker.get("state", "")) != "Sheltered":
				if worker["path"].is_empty():
					_send_worker_to_shelter(worker)
				else:
					_advance_production_worker(worker, delta)
			continue
		if not _building_can_work(building):
			worker["state"] = "Waiting" if String(building.get("type", "")) == Defs.BUILDING_LUMBER_CAMP else "Waiting indoors"
			worker["path"] = []
			worker["position"] = _worker_home_tile(building)
			continue
		if not worker["path"].is_empty():
			_advance_production_worker(worker, delta)
			continue
		if String(building.get("type", "")) != Defs.BUILDING_LUMBER_CAMP:
			worker["state"] = "Working indoors"
			worker["arrival_state"] = "Working indoors"
			worker["path"] = []
			continue
		worker["activity_timer"] = float(worker.get("activity_timer", 0.0)) - delta
		if float(worker["activity_timer"]) > 0.0:
			worker["state"] = "Working"
			continue
		var home := _worker_home_tile(building)
		var target := home if worker["position"] != home else _laborer_job_tile(building, int(worker.get("slot", 0)))
		worker["path"] = _find_worker_path(worker["position"], target)
		worker["state"] = "Returning" if target == home else "Walking to work"
		worker["activity_timer"] = 1.0 + float(int(worker.get("slot", 0))) * 0.25


func _update_clear_workers(delta: float) -> void:
	for index in range(workers.size() - 1, -1, -1):
		var worker: Dictionary = workers[index]
		if String(worker.get("type", "")) != "clearer":
			continue
		if is_gate_closed():
			if String(worker.get("state", "")) == "Sheltered":
				continue
			if worker["path"].is_empty():
				_send_worker_to_shelter(worker)
			else:
				_advance_production_worker(worker, delta)
			continue
		if not worker["path"].is_empty():
			_advance_production_worker(worker, delta)
			continue
		var target: Vector2i = worker.get("clear_target", worker["position"])
		var work_position: Vector2i = worker.get("work_position", target)
		# Night recall or another worker can invalidate the original gather state.
		# Deliver cargo before considering another harvest; never overwrite it.
		if int(worker.get("carried_amount", 0)) > 0 and String(worker.get("state", "")) != "Delivering":
			worker["path"] = _find_worker_path(worker.position, _town_hall_entrance_tile())
			worker["arrival_state"] = "Delivering"
			worker["state"] = "Delivering" if worker.position == _town_hall_entrance_tile() else "Carrying to Town Hall"
			continue
		if String(worker.get("state", "")) == "Delivering" and worker["position"] == _town_hall_entrance_tile():
			var delivered_resource := String(worker.get("carried_resource", ""))
			var delivered_amount := int(worker.get("carried_amount", 0))
			if delivered_resource != "" and delivered_amount > 0:
				central_inventory[delivered_resource] = int(central_inventory.get(delivered_resource, 0)) + delivered_amount
				_emit_audio("delivery")
				last_message = "%d %s delivered to the Town Hall." % [delivered_amount, Defs.resource_name(delivered_resource)]
				_add_log(last_message)
			worker["carried_resource"] = ""
			worker["carried_amount"] = 0
			_restore_clear_worker_role(worker, index)
			worker["reaction"] = "+"
			worker["reaction_until"] = elapsed_seconds + 1.2
			worker.erase("clear_target")
			worker.erase("work_position")
			if not first_player_order_complete:
				first_player_order_complete = true
				presentation_opening_active = false
				_update_objective_flag("first_order")
			continue
		if get_tile(target) not in [Defs.TILE_TREE, Defs.TILE_ROCK]:
			# Lumber production or another clearer finished this tile first.
			_restore_clear_worker_role(worker, index)
			continue
		if worker["position"] != work_position:
			worker["path"] = _find_worker_path(worker["position"], work_position)
			if worker["path"].is_empty():
				_restore_clear_worker_role(worker, index)
			continue
		worker["state"] = "Gathering"
		worker["activity_timer"] = float(worker.get("activity_timer", 2.5)) - delta
		if float(worker["activity_timer"]) > 0.0:
			continue
		var target_terrain := String(get_tile(target))
		if target_terrain in [Defs.TILE_TREE, Defs.TILE_ROCK]:
			var gathered_resource := Defs.RESOURCE_WOOD if target_terrain == Defs.TILE_TREE else Defs.RESOURCE_STONE
			var gathered_amount := 2 if target_terrain == Defs.TILE_TREE else 2
			_set_tile(target, Defs.TILE_GRASS)
			if target_terrain == Defs.TILE_TREE:
				tree_deposits.erase(_tile_key(target))
				priority_clear_tiles.erase(_tile_key(target))
				tree_regrowth[_tile_key(target)] = -1.0
			else:
				rock_deposits.erase(_tile_key(target))
			worker["carried_resource"] = gathered_resource
			worker["carried_amount"] = gathered_amount
			worker["path"] = _find_worker_path(worker["position"], _town_hall_entrance_tile())
			worker["state"] = "Carrying to Town Hall"
			worker["arrival_state"] = "Delivering"
			_add_log("%s gathered at %s." % [Defs.resource_name(gathered_resource), format_tile(target)])
			last_message = "Resource gathered. The settler is carrying it home."
			_emit_audio("build_complete")
			if worker["position"] == _town_hall_entrance_tile():
				worker["state"] = "Delivering"


func _restore_clear_worker_role(worker: Dictionary, index: int) -> void:
	var return_type := String(worker.get("return_type", "carrier" if bool(worker.get("manual_order", false)) else "retire"))
	if return_type == "retire":
		workers.remove_at(index)
		return
	worker["type"] = return_type
	worker["capacity"] = int(worker.get("return_capacity", 5 if return_type == "carrier" else 0))
	worker["state"] = "Idle"
	worker["arrival_state"] = "Idle"
	worker["manual_order"] = false
	worker["path"] = []
	worker.erase("clear_target")
	worker.erase("work_position")


func _advance_production_worker(worker: Dictionary, delta: float) -> void:
	worker["move_elapsed"] = float(worker.get("move_elapsed", 0.0)) + delta
	var step_seconds := _worker_step_seconds(worker, worker["path"][0])
	if float(worker["move_elapsed"]) < step_seconds:
		return
	worker["move_elapsed"] = 0.0
	worker["position"] = worker["path"].pop_front()
	if worker["path"].is_empty():
		worker["state"] = String(worker.get("arrival_state", "Working"))


func _laborer_job_tile(building: Dictionary, slot: int) -> Vector2i:
	var building_type := String(building["type"])
	var center := _footprint_center(building["position"], _building_footprint(building))
	if building_type == Defs.BUILDING_LUMBER_CAMP:
		var tree := _find_nearby_deposit(center, Defs.TILE_TREE, LUMBER_REACH)
		if tree.x >= 0:
			var work_tile := _nearest_tree_work_tile(_worker_home_tile(building), tree)
			if work_tile.x >= 0:
				return work_tile
	var candidates := _footprint_perimeter(building["position"], _building_footprint(building))
	var valid: Array[Vector2i] = []
	for tile in candidates:
		if is_inside_map(tile) and String(get_tile(tile)) != Defs.TILE_SHARD:
			valid.append(tile)
	if valid.is_empty():
		return center
	return valid[slot % valid.size()]


func _nearest_tree_work_tile(origin: Vector2i, tree: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_path_size := 1000000
	for candidate in _neighbors(tree):
		if not is_inside_map(candidate):
			continue
		var occupying_building := get_building_at_tile(candidate)
		if not occupying_building.is_empty() and String(occupying_building.get("type", "")) != Defs.BUILDING_ROAD and not bool(occupying_building.get("construction", false)):
			continue
		if String(get_tile(candidate)) not in [Defs.TILE_GRASS, Defs.TILE_TREE]:
			continue
		var path := _find_worker_path(origin, candidate)
		if origin != candidate and path.is_empty():
			continue
		if path.size() < best_path_size:
			best = candidate
			best_path_size = path.size()
	return best


func _worker_home_tile(building: Dictionary) -> Vector2i:
	var access := _building_access_tiles(building)
	if not access.is_empty():
		return access[0]
	var perimeter := _footprint_perimeter(building["position"], _building_footprint(building))
	if not perimeter.is_empty():
		return perimeter[0]
	return building["position"]


func _update_patrol_worker(worker: Dictionary, delta: float) -> void:
	if worker.has("scout_mission"):
		_update_scout_worker(worker, delta)
		return
	# Do not walk away during a committed strike, against a raider or Outpost.
	if float(worker.get("attack_flash", 0.0)) > 0.0:
		return
	if int(worker.get("assault_target_id", 0)) > 0:
		var target := _assault_outpost(int(worker.assault_target_id))
		if target.is_empty():
			worker.erase("assault_target_id")
			worker["combat_target_structure_id"] = 0
			worker["path"] = _find_worker_path(worker.position, _town_hall_entrance_tile())
			worker["state"] = "Returning to town"
			worker["arrival_state"] = "Patrolling"
		elif not _find_enemy_for_guard(worker, PATROL_MELEE_RADIUS).is_empty() or _outpost_distance(worker.position, target) <= 1:
			return
		elif worker["path"].is_empty():
			worker["activity_timer"] = float(worker.get("activity_timer", 0.0)) - delta
			if float(worker.activity_timer) > 0.0:
				return
			var route := _outpost_assault_route(worker, target)
			worker["path"] = route.path
			worker["activity_timer"] = 2.0
			worker["state"] = "Marching to rival Outpost" if route.success else "Assault blocked — open a route"
			worker["arrival_state"] = "Assaulting Outpost"
			return
	# The Director: Night Patrol must not override combat. Leave the road
	# for any hostile in aggro range or a yard under attack, then resume.
	if _pursue_patrol_threat(worker, delta):
		return
	if not worker["path"].is_empty():
		_advance_production_worker(worker, delta)
		return
	worker["activity_timer"] = float(worker.get("activity_timer", 0.0)) - delta
	if float(worker["activity_timer"]) > 0.0:
		return
	var patrol_tiles: Array = connected_walls.keys() if _wall_perimeter_is_closed() else _city_patrol_tiles()
	if patrol_tiles.is_empty():
		worker["state"] = "Night Watch" if is_night else "Guarding"
		worker["activity_timer"] = 2.0
		return
	for attempt in range(mini(10, patrol_tiles.size())):
		var target := _tile_from_key(String(patrol_tiles[rng.randi_range(0, patrol_tiles.size() - 1)]))
		var path := _find_road_path(worker["position"], [target])
		if not path.is_empty():
			worker["path"] = path
			worker["state"] = "Night Patrol" if is_night else "Patrolling"
			worker["arrival_state"] = "Night Watch" if is_night else "Patrolling"
			worker["activity_timer"] = 1.2
			return
	worker["activity_timer"] = 1.0


func _pursue_patrol_threat(worker: Dictionary, delta: float) -> bool:
	var threat := _find_patrol_threat(worker)
	if threat.is_empty():
		return false
	var dest: Vector2i = threat.get("position", worker.get("position", Vector2i.ZERO))
	var close_enough := 1 if String(threat.get("kind", "")) == "enemy" else 2
	if _manhattan(worker["position"], dest) <= close_enough:
		worker["path"] = []
		worker["state"] = "Fighting"
		worker["arrival_state"] = "Fighting"
		return true
	if not worker["path"].is_empty():
		var path_end: Vector2i = worker["path"][worker["path"].size() - 1]
		if _manhattan(path_end, dest) <= 1:
			_advance_production_worker(worker, delta)
			worker["state"] = "Fighting"
			worker["arrival_state"] = "Fighting"
			return true
	var path := _find_worker_path(worker["position"], dest)
	if path.is_empty():
		for neighbor in _neighbors(dest):
			path = _find_worker_path(worker["position"], neighbor)
			if not path.is_empty():
				break
	if path.is_empty():
		return false
	worker["path"] = path
	worker["state"] = "Fighting"
	worker["arrival_state"] = "Fighting"
	_advance_production_worker(worker, delta)
	return true


func _find_patrol_threat(guard: Dictionary) -> Dictionary:
	var enemy := _find_enemy_for_guard(guard, PATROL_AGGRO_RADIUS)
	if not enemy.is_empty():
		return {"kind": "enemy", "entity": enemy, "position": enemy.get("position", Vector2i.ZERO)}
	var attacked_ids: Dictionary = {}
	for hostile in enemies:
		if int(hostile.get("hp", 0)) <= 0:
			continue
		if String(hostile.get("target_kind", "")) == "building" and int(hostile.get("target_id", 0)) > 0:
			attacked_ids[int(hostile.get("target_id", 0))] = true
	var best := {}
	var best_distance := PATROL_DEFEND_RADIUS + 1
	for building in buildings:
		if bool(building.get("construction", false)):
			continue
		if String(building.get("type", "")) == Defs.BUILDING_ROAD:
			continue
		var building_id := int(building.get("id", 0))
		var under_attack := float(building.get("damage_flash", 0.0)) > 0.0 or attacked_ids.has(building_id)
		if not under_attack:
			continue
		var center: Vector2i = _footprint_center(building.get("position", Vector2i.ZERO), _building_footprint(building))
		var distance := _tile_distance(guard.get("position", Vector2i.ZERO), center)
		if distance > PATROL_DEFEND_RADIUS or distance >= best_distance:
			continue
		best_distance = distance
		var dest := center
		var access := _building_access_tiles(building)
		if not access.is_empty():
			dest = access[0]
		else:
			var perimeter := _footprint_perimeter(building.get("position", Vector2i.ZERO), _building_footprint(building))
			if not perimeter.is_empty():
				dest = perimeter[0]
		best = {"kind": "building", "entity": building, "position": dest}
	return best


func _update_scout_worker(worker: Dictionary, delta: float) -> void:
	_expire_map_markers()
	var reason := _scout_return_reason(worker)
	if reason != "" and not bool(worker["scout_mission"].get("returning", false)):
		_begin_scout_return(worker, reason)
	if not worker["path"].is_empty():
		_advance_production_worker(worker, delta)
		return
	var mission: Dictionary = worker.get("scout_mission", {})
	if bool(mission.get("returning", false)):
		var home: Vector2i = mission.get("home", _town_hall_entrance_tile())
		if worker["position"] == home or _manhattan(worker["position"], home) <= 1:
			_finish_scout(worker)
			return
		worker["path"] = _find_worker_path(worker["position"], home)
		if worker["path"].is_empty():
			_finish_scout(worker)
		return
	_assign_scout_leg(worker)


func _scout_return_reason(worker: Dictionary) -> String:
	var mission: Dictionary = worker.get("scout_mission", {})
	var home: Vector2i = mission.get("home", _town_hall_entrance_tile())
	var hp := int(worker.get("hp", 1))
	var max_hp := maxi(1, int(worker.get("max_hp", hp)))
	if float(hp) / float(max_hp) <= Scout.RETURN_HP_RATIO:
		return Scout.REASON_HEALTH
	if _scout_sees_danger(worker):
		return Scout.REASON_ENEMY
	if int(central_inventory.get(Defs.RESOURCE_BREAD, 0)) <= 0:
		return Scout.REASON_FOOD
	# Dusk recall only. An explicit night scout (Y / SCOUT) stays out and
	# can be ambushed; _send_workers_to_shelter still brings day scouts home.
	if not is_night and float(DAY_LENGTH_SECONDS) - float(phase_time) <= Scout.DUSK_RETURN_SECONDS:
		return Scout.REASON_DUSK
	if _manhattan(worker["position"], home) >= int(mission.get("depth_limit", Scout.DEPTH_LIMIT)):
		return Scout.REASON_DEPTH
	return ""


func _scout_sees_danger(worker: Dictionary) -> bool:
	var origin: Vector2i = worker["position"]
	var seen := 0
	for enemy in enemies:
		if int(enemy.get("hp", 0)) <= 0:
			continue
		if _manhattan(origin, enemy["position"]) <= VISION_SOLDIER:
			seen += 1
			worker["scout_last_enemy"] = enemy["position"]
	for camp in enemy_camps:
		if bool(camp.get("destroyed", false)):
			continue
		var camp_tile: Vector2i = camp.get("position", Vector2i.ZERO)
		if _manhattan(origin, camp_tile) <= VISION_SOLDIER:
			worker["scout_last_enemy"] = camp_tile
			return true
	return seen >= 1


func _assign_scout_leg(worker: Dictionary) -> void:
	var waypoint := _pick_scout_waypoint(worker)
	if waypoint.x < 0:
		_begin_scout_return(worker, Scout.REASON_DONE)
		return
	var path := _find_worker_path(worker["position"], waypoint)
	if path.is_empty():
		_begin_scout_return(worker, Scout.REASON_DONE)
		return
	worker["path"] = path
	worker["state"] = "Scouting"
	worker["arrival_state"] = "Scouting"
	worker["activity_timer"] = 0.4


func _pick_scout_waypoint(worker: Dictionary) -> Vector2i:
	var mission: Dictionary = worker.get("scout_mission", {})
	var home: Vector2i = mission.get("home", _town_hall_entrance_tile())
	var dir_data: Dictionary = mission.get("direction", {"x": 1.0, "y": 0.0})
	var direction := Vector2(float(dir_data.get("x", 1.0)), float(dir_data.get("y", 0.0)))
	var origin: Vector2i = worker["position"]
	var best := Vector2i(-1, -1)
	var best_score := -INF
	for sample in range(18):
		var step := Scout.LEG_LENGTH + (sample % 3) - 1
		var angle := float(sample - 9) * 0.18
		var rotated := direction.rotated(angle)
		var candidate := origin + Vector2i(roundi(rotated.x * float(step)), roundi(rotated.y * float(step)))
		if not is_inside_map(candidate) or candidate == origin:
			continue
		if not get_building_at_tile(candidate).is_empty() and String(get_building_at_tile(candidate).get("type", "")) != Defs.BUILDING_ROAD:
			continue
		var unexplored := 0
		for offset in _radius_offsets(VISION_SOLDIER):
			var tile: Vector2i = candidate + offset
			if is_inside_map(tile) and not is_revealed(tile):
				unexplored += 1
		var toward := Vector2(candidate - origin).normalized().dot(direction)
		var risk := 0.0
		for enemy in enemies:
			if int(enemy.get("hp", 0)) > 0 and _manhattan(candidate, enemy["position"]) <= 4:
				risk += 1.0
		var score := Scout.score_waypoint(unexplored, toward, float(_manhattan(candidate, home)), risk)
		if score > best_score:
			best_score = score
			best = candidate
	return best


func _begin_scout_return(worker: Dictionary, reason: String) -> void:
	if not worker.has("scout_mission"):
		return
	var mission: Dictionary = worker["scout_mission"]
	if bool(mission.get("returning", false)) and String(mission.get("return_reason", "")) != "":
		return
	mission["returning"] = true
	mission["return_reason"] = reason
	worker["scout_mission"] = mission
	var name_text := Scout.display_name(worker, rng_seed)
	last_message = Scout.return_message(reason, name_text)
	if reason == Scout.REASON_ENEMY:
		var seen: Vector2i = worker.get("scout_last_enemy", worker["position"])
		add_map_marker("enemy", seen, "Enemy last seen", elapsed_seconds + 120.0)
		_add_log(last_message)
	worker["path"] = _find_worker_path(worker["position"], mission.get("home", _town_hall_entrance_tile()))
	worker["state"] = "Returning from scout"
	worker["arrival_state"] = "Patrolling"


func _finish_scout(worker: Dictionary) -> void:
	var mission: Dictionary = worker.get("scout_mission", {})
	var gained := revealed_tiles.size() - int(mission.get("tiles_at_start", revealed_tiles.size()))
	if gained >= 8:
		intention_flags["scouted_frontier"] = true
	worker.erase("scout_mission")
	worker["manual_order"] = false
	worker["path"] = []
	worker["state"] = "Patrolling"
	worker["arrival_state"] = "Patrolling"
	if last_message == "" or String(last_message).begins_with(Scout.display_name(worker, rng_seed)):
		last_message = "%s has returned to town." % Scout.display_name(worker, rng_seed)


func _mark_scout_lost(worker: Dictionary) -> void:
	var name_text := Scout.display_name(worker, rng_seed)
	var tile: Vector2i = worker.get("position", _town_hall_entrance_tile())
	add_map_marker("skull", tile, "Scout lost", elapsed_seconds + 240.0)
	last_message = "SCOUT LOST — %s did not return from the woods." % name_text
	_add_log(last_message)
	_record_event("scout_lost", last_message, {"worker_id": int(worker.get("id", 0)), "tile": _vector_to_data(tile)})
	if revealed_tiles.size() - int(Dictionary(worker.get("scout_mission", {})).get("tiles_at_start", 0)) >= 8:
		intention_flags["scouted_frontier"] = true


func _expire_map_markers() -> void:
	var kept: Array = []
	for marker in map_markers:
		var until := float(marker.get("until", 0.0))
		if until <= 0.0 or until > elapsed_seconds:
			kept.append(marker)
	map_markers = kept


func _wall_perimeter_is_closed() -> bool:
	if connected_walls.size() < 8:
		return false
	for key_value in connected_walls.keys():
		var tile := _tile_from_key(String(key_value))
		var links := 0
		for neighbor in _neighbors(tile):
			if connected_walls.has(_tile_key(neighbor)) or is_gate_tile(neighbor):
				links += 1
		if links < 2:
			return false
	return true


func _city_patrol_tiles() -> Array:
	var result: Array = []
	var town_center := _footprint_center(town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	for key_value in connected_roads.keys():
		var tile := _tile_from_key(String(key_value))
		if _manhattan(town_center, tile) <= CITY_PATROL_RADIUS:
			result.append(String(key_value))
	return result if not result.is_empty() else connected_roads.keys()


func _find_worker_path(start: Vector2i, destination: Vector2i) -> Array:
	return _find_weighted_path(start, [destination], false)


func _send_workers_to_shelter() -> void:
	var sent := 0
	for worker in workers:
		if String(worker.get("type", "")) == "guard":
			if worker.has("scout_mission"):
				_begin_scout_return(worker, Scout.REASON_DUSK)
				continue
			worker["state"] = "Guarding"
			worker["path"] = []
			continue
		if String(worker.get("type", "")) == "carrier":
			_clear_worker(worker)
		_send_worker_to_shelter(worker)
		if String(worker.get("state", "")) in ["Going to shelter", "Sheltered"]:
			sent += 1
	_record_event("shelter_called", "%d workers head for shelter." % sent, {"workers": sent})


func _send_worker_to_shelter(worker: Dictionary) -> void:
	var best_path: Array = []
	var best_entrance := Vector2i(-1, -1)
	var found := false
	var start: Vector2i = worker["position"]
	var is_carrier := String(worker.get("type", "")) == "carrier"
	for entrance in _shelter_entries():
		var candidate: Array = _find_road_path(start, [entrance]) if is_carrier else _find_worker_path(start, entrance)
		if start != entrance and candidate.is_empty():
			continue
		if not found or candidate.size() < best_path.size():
			found = true
			best_path = candidate
			best_entrance = entrance
	if not found:
		worker["state"] = "No shelter"
		return
	worker["shelter_position"] = best_entrance
	worker["path"] = best_path
	worker["arrival_state"] = "Sheltered"
	worker["move_elapsed"] = 0.0
	worker["state"] = "Sheltered" if best_path.is_empty() else "Going to shelter"


func _shelter_entries() -> Array:
	var house_entries: Array = []
	var town_hall_entries: Array = []
	for building in buildings:
		if bool(building.get("construction", false)):
			continue
		var building_type := String(building.get("type", ""))
		if building_type not in [Defs.BUILDING_TOWN_HALL, Defs.BUILDING_HOUSE]:
			continue
		var access_tiles := _building_access_tiles(building)
		if access_tiles.is_empty() and building_type == Defs.BUILDING_TOWN_HALL:
			town_hall_entries.append(building["position"])
		elif building_type == Defs.BUILDING_HOUSE:
			house_entries.append_array(access_tiles)
		else:
			town_hall_entries.append_array(access_tiles)
	return house_entries if not house_entries.is_empty() else town_hall_entries


func _wake_workers_at_dawn() -> void:
	for worker in workers:
		worker["shelter_position"] = Vector2i(-1, -1)
		var worker_type := String(worker.get("type", ""))
		if worker_type == "guard":
			if worker.has("scout_mission"):
				_begin_scout_return(worker, Scout.REASON_DUSK)
				continue
			worker["state"] = "Patrolling" if int(worker.get("building_id", 0)) == 0 else "Guarding"
			worker["path"] = []
			continue
		if worker_type == "carrier":
			worker["path"] = []
			worker["state"] = "Idle"
			worker["arrival_state"] = "Idle"
			continue
		var building := _find_building_by_id(int(worker.get("building_id", 0)))
		if building.is_empty():
			# Free peasants, clearers, and "No shelter" leftovers used to
			# stay Sheltered after dawn, so night-placed jobs never resumed.
			if String(worker.get("state", "")) in ["Sheltered", "Going to shelter", "No shelter"]:
				worker["path"] = []
				worker["state"] = "Idle"
				worker["arrival_state"] = "Idle"
			continue
		var destination := _worker_home_tile(building)
		worker["path"] = _find_worker_path(worker["position"], destination)
		worker["arrival_state"] = "Working"
		worker["move_elapsed"] = 0.0
		worker["state"] = "Working" if worker["path"].is_empty() else "Returning to work"
	_resume_daytime_jobs()


func _resume_daytime_jobs() -> void:
	_ensure_carriers()
	_assign_idle_workers_to_priority_clears()
	for site in buildings:
		if bool(site.get("construction", false)):
			_sync_site_clearing(site, true)


func _advance_carrier(worker: Dictionary, delta: float) -> void:
	if worker["path"].is_empty():
		return
	worker["move_elapsed"] = float(worker.get("move_elapsed", 0.0)) + delta
	var step_seconds := _worker_step_seconds(worker, worker["path"][0])
	if float(worker["move_elapsed"]) < step_seconds:
		return
	worker["move_elapsed"] = 0.0

	var next_tile: Vector2i = worker["path"].pop_front()
	if not _is_walkable_road(next_tile):
		worker["path"] = []
		worker["state"] = "Blocked"
		last_message = "A broken road blocked a carrier."
		return
	worker["position"] = next_tile
	if worker["path"].is_empty():
		worker["state"] = String(worker.get("arrival_state", "Idle"))


func _assign_carrier_task(worker: Dictionary) -> bool:
	var stamp := _profile_stamp()
	var result := _assign_carrier_task_unprofiled(worker)
	_profile_finish("carrier_task_discovery", stamp)
	return result


func _assign_carrier_task_unprofiled(worker: Dictionary) -> bool:
	if int(worker.get("carried_amount", 0)) > 0:
		return _assign_dropoff_for_carried(worker)
	if _assign_road_build(worker):
		return true
	if _assign_construction_supply(worker):
		return true
	if _assign_processor_supply(worker):
		return true
	return _assign_output_fetch(worker)


func _assign_road_build(worker: Dictionary) -> bool:
	if workers_free() <= 0:
		return false
	for site in buildings:
		if int(site.get("builder_worker_id", 0)) > 0 and not _road_builder_claim_exists(site):
			site["builder_worker_id"] = 0
		if not bool(site.get("construction", false)) \
			or String(site.get("planned_type", "")) != Defs.BUILDING_ROAD \
			or not bool(site.get("connected", false)) \
			or int(site.get("builder_worker_id", 0)) > 0:
			continue
		var access := _building_access_tiles(site)
		if access.is_empty():
			continue
		var path := _find_road_path(worker["position"], access)
		if path.is_empty() and not access.has(worker["position"]):
			continue
		site["builder_worker_id"] = int(worker["id"])
		site["status"] = "Peasant walking to road site."
		worker["task"] = {
			"purpose": "road_build",
			"destination": int(site["id"])
		}
		worker["path"] = path
		worker["arrival_state"] = "Building"
		worker["state"] = "Building" if path.is_empty() else "Moving"
		worker["move_elapsed"] = 0.0
		return true
	return false


func _road_builder_claim_exists(site: Dictionary) -> bool:
	var builder_id := int(site.get("builder_worker_id", 0))
	for worker in workers:
		if int(worker.get("id", 0)) != builder_id:
			continue
		var task: Dictionary = worker.get("task", {})
		return String(task.get("purpose", "")) == "road_build" \
			and int(task.get("destination", 0)) == int(site.get("id", 0))
	return false


func _assign_construction_supply(worker: Dictionary) -> bool:
	var stamp := _profile_stamp()
	var result := _assign_construction_supply_unprofiled(worker)
	_profile_finish("construction_task_discovery", stamp)
	return result


func _assign_construction_supply_unprofiled(worker: Dictionary) -> bool:
	for site in buildings:
		if not bool(site.get("construction", false)) or not bool(site.get("connected", false)):
			continue
		var needed: Dictionary = site.get("materials_needed", {})
		var delivered: Dictionary = site.get("materials_delivered", {})
		var in_transit: Dictionary = site.get("materials_in_transit", Defs.empty_inventory())
		site["materials_in_transit"] = in_transit
		for resource_type in needed.keys():
			var outstanding := int(needed.get(resource_type, 0)) - int(delivered.get(resource_type, 0)) - int(in_transit.get(resource_type, 0))
			if outstanding <= 0 or int(central_inventory.get(resource_type, 0)) <= 0:
				continue
			var amount: int = min(int(worker["capacity"]), min(outstanding, int(central_inventory.get(resource_type, 0))))
			if _assign_from_central(worker, site, String(resource_type), amount, "construction"):
				in_transit[resource_type] = int(in_transit.get(resource_type, 0)) + amount
				site["status"] = "Materials en route."
				return true
	return false


func _assign_processor_supply(worker: Dictionary) -> bool:
	var stamp := _profile_stamp()
	var result := _assign_processor_supply_unprofiled(worker)
	_profile_finish("production_worker_task_discovery", stamp)
	return result


func _assign_processor_supply_unprofiled(worker: Dictionary) -> bool:
	for building in buildings:
		var building_type := String(building["type"])
		if not Defs.PROCESSOR_INPUTS.has(building_type):
			continue
		if not _building_can_work(building):
			continue
		var resource_type := String(Defs.PROCESSOR_INPUTS[building_type])
		var incoming := _incoming_amount(int(building["id"]), resource_type)
		var room := int(building["local_capacity"]) - _inventory_total(building["local_inventory"]) - incoming
		if room <= 0:
			continue
		var amount_cap: int = mini(int(worker["capacity"]), room)
		if _assign_processor_from_producers(worker, building, resource_type, amount_cap):
			return true
		var central_available := int(central_inventory.get(resource_type, 0))
		if building_type == Defs.BUILDING_SAWMILL and resource_type == Defs.RESOURCE_WOOD:
			central_available = maxi(0, central_available - SAWMILL_WOOD_RESERVE)
		if central_available <= 0:
			continue
		var amount: int = mini(amount_cap, central_available)
		if _assign_from_central(worker, building, resource_type, amount, "processor"):
			return true
	return false


func _assign_processor_from_producers(worker: Dictionary, destination: Dictionary, resource_type: String, amount_cap: int) -> bool:
	if amount_cap <= 0:
		return false
	for source in buildings:
		if int(source.get("id", 0)) == int(destination.get("id", 0)):
			continue
		if bool(source.get("construction", false)) or not bool(source.get("connected", false)):
			continue
		var definition: Dictionary = Defs.PRODUCTION_DEFS.get(String(source.get("type", "")), {})
		if String(definition.get("output", "")) != resource_type:
			continue
		var available := int(source["local_inventory"].get(resource_type, 0)) - _outgoing_amount(int(source["id"]), resource_type)
		if available <= 0:
			continue
		var amount: int = mini(amount_cap, available)
		if _assign_building_to_building(worker, source, destination, resource_type, amount, "processor"):
			return true
	return false


func _assign_output_fetch(worker: Dictionary) -> bool:
	var stamp := _profile_stamp()
	var result := _assign_output_fetch_unprofiled(worker)
	_profile_finish("output_task_discovery", stamp)
	return result


func _assign_output_fetch_unprofiled(worker: Dictionary) -> bool:
	for building in buildings:
		if not bool(building.get("connected", false)):
			continue
		if bool(building.get("construction", false)):
			continue
		if not Defs.OUTPUT_BUILDINGS.has(String(building["type"])):
			continue
		var produced := String(Defs.PRODUCTION_DEFS.get(String(building["type"]), {}).get("output", ""))
		for resource_type in Defs.RESOURCE_TYPES:
			if produced != "" and resource_type != produced:
				continue
			var amount_available := int(building["local_inventory"].get(resource_type, 0)) - _outgoing_amount(int(building["id"]), resource_type)
			var central_room := get_storage_room(resource_type)
			if amount_available <= 0 or central_room <= 0:
				if amount_available > 0:
					building["status"] = "Central storage full — build a Storehouse."
				continue
			var amount: int = min(int(worker["capacity"]), min(amount_available, central_room))
			if _assign_from_building(worker, building, resource_type, amount, "output"):
				return true
	return false


func _assign_from_central(worker: Dictionary, destination: Dictionary, resource_type: String, amount: int, purpose: String) -> bool:
	if amount <= 0:
		return false
	var start_access := _town_hall_access_tiles()
	if start_access.is_empty():
		return false
	var path := _find_road_path(worker["position"], start_access)
	if path.is_empty() and not start_access.has(worker["position"]):
		return false
	worker["task"] = {
		"purpose": purpose,
		"source": "central",
		"destination": int(destination["id"]),
		"resource": resource_type,
		"amount": amount
	}
	_task_index_add(worker)
	worker["path"] = path
	worker["arrival_state"] = "Pickup"
	worker["state"] = "Pickup" if path.is_empty() else "Moving"
	return true


func _assign_from_building(worker: Dictionary, source: Dictionary, resource_type: String, amount: int, purpose: String) -> bool:
	return _assign_building_to_marker(worker, source, "central", resource_type, amount, purpose)


func _assign_building_to_building(worker: Dictionary, source: Dictionary, destination: Dictionary, resource_type: String, amount: int, purpose: String) -> bool:
	return _assign_building_to_marker(worker, source, int(destination["id"]), resource_type, amount, purpose)


func _assign_building_to_marker(worker: Dictionary, source: Dictionary, destination_marker: Variant, resource_type: String, amount: int, purpose: String) -> bool:
	if amount <= 0:
		return false
	var access := _building_access_tiles(source)
	if access.is_empty():
		return false
	var path := _find_road_path(worker["position"], access)
	if path.is_empty() and not access.has(worker["position"]):
		return false
	worker["task"] = {
		"purpose": purpose,
		"source": int(source["id"]),
		"destination": destination_marker,
		"resource": resource_type,
		"amount": amount
	}
	_task_index_add(worker)
	worker["path"] = path
	worker["arrival_state"] = "Pickup"
	worker["state"] = "Pickup" if path.is_empty() else "Moving"
	return true


func _carrier_pickup(worker: Dictionary) -> bool:
	var task: Dictionary = worker.get("task", {})
	if task.is_empty():
		_clear_worker(worker)
		return false
	var resource_type := String(task.get("resource", ""))
	var amount := int(task.get("amount", 0))

	var source_marker: Variant = task.get("source", null)
	if typeof(source_marker) == TYPE_STRING and source_marker == "central":
		amount = mini(amount, int(central_inventory.get(resource_type, 0)))
		if amount <= 0:
			_clear_worker(worker)
			return false
		central_inventory[resource_type] = int(central_inventory.get(resource_type, 0)) - amount
		if String(task.get("purpose", "")) == "construction":
			var originally_claimed := int(task.get("amount", amount))
			if amount < originally_claimed:
				_reduce_construction_transit(int(task.get("destination", 0)), resource_type, originally_claimed - amount)
			_release_reserved_resource(resource_type, amount)
	else:
		var source := _find_building_by_id(int(task.get("source", 0)))
		if source.is_empty():
			_clear_worker(worker)
			return false
		amount = min(amount, int(source["local_inventory"].get(resource_type, 0)))
		if amount <= 0:
			_clear_worker(worker)
			return false
		source["local_inventory"][resource_type] = int(source["local_inventory"][resource_type]) - amount

	_task_index_remove(worker)
	worker["carried_resource"] = resource_type
	worker["carried_amount"] = amount
	task["amount"] = amount
	worker["task"] = task
	_task_index_add(worker)
	return _assign_dropoff_for_carried(worker)


func _assign_dropoff_for_carried(worker: Dictionary) -> bool:
	var task: Dictionary = worker.get("task", {})
	if task.is_empty():
		_clear_worker(worker)
		return false

	var access: Array = []
	var destination_marker: Variant = task.get("destination", null)
	if typeof(destination_marker) == TYPE_STRING and destination_marker == "central":
		access = _town_hall_access_tiles()
	else:
		var destination := _find_building_by_id(int(task.get("destination", 0)))
		if destination.is_empty():
			_clear_worker(worker)
			return false
		access = _building_access_tiles(destination)

	if access.is_empty():
		worker["state"] = "Blocked"
		return false

	var path := _find_road_path(worker["position"], access)
	if path.is_empty() and not access.has(worker["position"]):
		worker["state"] = "Blocked"
		return false

	worker["path"] = path
	worker["arrival_state"] = "Dropoff"
	worker["state"] = "Dropoff" if path.is_empty() else "Moving"
	return true


func _carrier_dropoff(worker: Dictionary) -> bool:
	var task: Dictionary = worker.get("task", {})
	if task.is_empty():
		_clear_worker(worker)
		return false
	var resource_type := String(worker.get("carried_resource", ""))
	var amount := int(worker.get("carried_amount", 0))
	if amount <= 0 or resource_type == "":
		_clear_worker(worker)
		return false

	var purpose := String(task.get("purpose", ""))
	var destination_marker: Variant = task.get("destination", null)
	if typeof(destination_marker) == TYPE_STRING and destination_marker == "central":
		var room := maxi(0, get_storage_limit(resource_type) - int(central_inventory.get(resource_type, 0)))
		var accepted := mini(room, amount)
		central_inventory[resource_type] = int(central_inventory.get(resource_type, 0)) + accepted
		var overflow := amount - accepted
		if overflow > 0:
			var source := _find_building_by_id(int(task.get("source", 0)))
			if not source.is_empty():
				source["local_inventory"][resource_type] = int(source["local_inventory"].get(resource_type, 0)) + overflow
				source["status"] = "%s storage full." % Defs.resource_name(resource_type)
		if purpose == "output":
			_update_objective_flag("lumber")
			_emit_audio("delivery")
	else:
		var destination := _find_building_by_id(int(task.get("destination", 0)))
		if destination.is_empty():
			_clear_worker(worker)
			return false
		if purpose == "construction":
			destination["materials_delivered"][resource_type] = int(destination["materials_delivered"].get(resource_type, 0)) + amount
			_reduce_construction_transit(int(destination["id"]), resource_type, amount)
			destination["status"] = "Materials delivered."
			destination["last_delivery_elapsed"] = elapsed_seconds
			_record_event("delivery", "Construction materials delivered.", {
				"building_id": int(destination["id"]),
				"resource": resource_type,
				"amount": amount
			})
		else:
			destination["local_inventory"][resource_type] = int(destination["local_inventory"].get(resource_type, 0)) + amount
			destination["status"] = "Inputs delivered."
			destination["last_delivery_elapsed"] = elapsed_seconds
			_record_event("delivery", "Processor input delivered.", {
				"building_id": int(destination["id"]),
				"resource": resource_type,
				"amount": amount
			})

	_clear_worker(worker, false)
	if purpose == "construction":
		worker["state"] = "Building"
		worker["action_timer"] = CARRIER_BUILD_ACTION_SECONDS
	return true


func _retry_blocked_carrier(worker: Dictionary) -> void:
	if int(worker.get("carried_amount", 0)) > 0:
		_assign_dropoff_for_carried(worker)
	else:
		_clear_worker(worker)


func _clear_worker(worker: Dictionary, cancel_task: bool = true) -> void:
	worker.erase("assault_target_id")
	worker["combat_target_structure_id"] = 0
	worker["attack_flash"] = 0.0
	worker["attack_damage_applied"] = true
	if cancel_task:
		_release_worker_claim(worker)
	else:
		_task_index_remove(worker)
	worker["path"] = []
	worker["state"] = "Idle"
	worker["arrival_state"] = "Idle"
	worker["carried_resource"] = ""
	worker["carried_amount"] = 0
	worker["task"] = {}


func _release_worker_claim(worker: Dictionary) -> void:
	_task_index_remove(worker)
	var task: Dictionary = worker.get("task", {})
	if String(task.get("purpose", "")) == "road_build":
		var road_site := _find_building_by_id(int(task.get("destination", 0)))
		if not road_site.is_empty() and int(road_site.get("builder_worker_id", 0)) == int(worker.get("id", 0)):
			road_site["builder_worker_id"] = 0
			if bool(road_site.get("construction", false)):
				road_site["status"] = "Planned — waiting for a free peasant."
		return
	var resource_type := String(worker.get("carried_resource", ""))
	if resource_type == "":
		resource_type = String(task.get("resource", ""))
	var carried := int(worker.get("carried_amount", 0))
	if String(task.get("purpose", "")) == "construction":
		var destination_id := int(task.get("destination", 0))
		_reduce_construction_transit(destination_id, resource_type, int(task.get("amount", 0)))
		if carried > 0:
			central_inventory[resource_type] = int(central_inventory.get(resource_type, 0)) + carried
			if not _find_building_by_id(destination_id).is_empty():
				reserved_inventory[resource_type] = int(reserved_inventory.get(resource_type, 0)) + carried
	elif carried > 0 and resource_type != "":
		central_inventory[resource_type] = int(central_inventory.get(resource_type, 0)) + carried


func _reduce_construction_transit(building_id: int, resource_type: String, amount: int) -> void:
	var destination := _find_building_by_id(building_id)
	if destination.is_empty() or amount <= 0:
		return
	var in_transit: Dictionary = destination.get("materials_in_transit", Defs.empty_inventory())
	in_transit[resource_type] = max(0, int(in_transit.get(resource_type, 0)) - amount)
	destination["materials_in_transit"] = in_transit


func _incoming_amount(building_id: int, resource_type: String) -> int:
	var stamp := _profile_stamp()
	_ensure_task_indexes()
	var total := int(_task_incoming_by_destination.get(_task_index_key(building_id, resource_type), 0))
	_profile_finish("inventory_source_destination_searches", stamp)
	return total


func _incoming_to_central(resource_type: String) -> int:
	var stamp := _profile_stamp()
	_ensure_task_indexes()
	var total := int(_task_incoming_to_central.get(resource_type, 0))
	_profile_finish("inventory_source_destination_searches", stamp)
	return total


func _outgoing_amount(building_id: int, resource_type: String) -> int:
	var stamp := _profile_stamp()
	_ensure_task_indexes()
	var total := int(_task_outgoing_by_source.get(_task_index_key(building_id, resource_type), 0))
	_profile_finish("inventory_source_destination_searches", stamp)
	return total


func _ensure_task_indexes() -> void:
	if not _task_indexes_valid:
		_rebuild_task_indexes()


func _rebuild_task_indexes() -> void:
	var stamp := _profile_stamp()
	_task_incoming_by_destination.clear()
	_task_outgoing_by_source.clear()
	_task_incoming_to_central.clear()
	_task_indexes_valid = true
	for worker_value in workers:
		_task_index_add(worker_value)
	_profile_scan("task_index_rebuild_worker_scan", workers.size())
	_profile_finish("task_index_rebuild", stamp)


func _task_index_add(worker: Dictionary) -> void:
	if not _task_indexes_valid:
		return
	var task: Dictionary = worker.get("task", {})
	var resource_type := String(task.get("resource", ""))
	var amount := int(task.get("amount", 0))
	if resource_type == "" or amount <= 0:
		return
	var destination = task.get("destination", null)
	if typeof(destination) in [TYPE_INT, TYPE_FLOAT]:
		_task_index_increment(_task_incoming_by_destination, _task_index_key(int(destination), resource_type), amount)
	elif typeof(destination) == TYPE_STRING and String(destination) == "central":
		_task_index_increment(_task_incoming_to_central, resource_type, amount)
	var source = task.get("source", null)
	if typeof(source) in [TYPE_INT, TYPE_FLOAT]:
		_task_index_increment(_task_outgoing_by_source, _task_index_key(int(source), resource_type), amount)


func _task_index_remove(worker: Dictionary) -> void:
	if not _task_indexes_valid:
		return
	var task: Dictionary = worker.get("task", {})
	var resource_type := String(task.get("resource", ""))
	var amount := int(task.get("amount", 0))
	if resource_type == "" or amount <= 0:
		return
	var destination = task.get("destination", null)
	if typeof(destination) in [TYPE_INT, TYPE_FLOAT]:
		_task_index_increment(_task_incoming_by_destination, _task_index_key(int(destination), resource_type), -amount)
	elif typeof(destination) == TYPE_STRING and String(destination) == "central":
		_task_index_increment(_task_incoming_to_central, resource_type, -amount)
	var source = task.get("source", null)
	if typeof(source) in [TYPE_INT, TYPE_FLOAT]:
		_task_index_increment(_task_outgoing_by_source, _task_index_key(int(source), resource_type), -amount)


func _task_index_increment(index: Dictionary, key: String, delta: int) -> void:
	var next_amount := maxi(0, int(index.get(key, 0)) + delta)
	if next_amount == 0:
		index.erase(key)
	else:
		index[key] = next_amount


func _task_index_key(building_id: int, resource_type: String) -> String:
	return "%d:%s" % [building_id, resource_type]


func _update_construction(delta: float) -> void:
	for building in buildings:
		if not bool(building.get("construction", false)):
			continue
		if not bool(building.get("connected", false)):
			if String(building.get("planned_type", "")) == Defs.BUILDING_ROAD:
				building["status"] = "Planned — waiting for earlier road segments."
			else:
				building["status"] = "Planned — waiting for its road connection."
			continue
		if _sync_site_clearing(building):
			continue
		if String(building.get("planned_type", "")) == Defs.BUILDING_ROAD and not _road_builder_is_working(building):
			building["status"] = "Planned — waiting for a free peasant."
			continue
		if not _construction_materials_ready(building):
			building["status"] = "Waiting for deliveries."
			continue
		var planned_type := String(building.get("planned_type", ""))
		var total_time := float(building.get("construction_total", 0.0))
		if total_time <= 0.0:
			total_time = Defs.build_time(planned_type)
			building["construction_total"] = total_time
			building["construction_remaining"] = total_time
		building["construction_remaining"] = max(0.0, float(building.get("construction_remaining", total_time)) - delta)
		building["status"] = "Building."
		if float(building["construction_remaining"]) <= 0.0:
			finish_construction(building)


func _road_builder_is_working(site: Dictionary) -> bool:
	var builder_id := int(site.get("builder_worker_id", 0))
	if builder_id <= 0:
		return false
	for worker in workers:
		if int(worker.get("id", 0)) != builder_id:
			continue
		var task: Dictionary = worker.get("task", {})
		return String(worker.get("state", "")) == "Building" \
			and String(task.get("purpose", "")) == "road_build" \
			and int(task.get("destination", 0)) == int(site.get("id", 0))
	return false


func _construction_materials_ready(site: Dictionary) -> bool:
	var needed: Dictionary = site.get("materials_needed", {})
	var delivered: Dictionary = site.get("materials_delivered", {})
	for resource_type in needed.keys():
		if int(delivered.get(resource_type, 0)) < int(needed.get(resource_type, 0)):
			return false
	return true


func finish_construction(site: Dictionary) -> bool:
	if not bool(site.get("construction", false)):
		return false

	var planned_type := String(site.get("planned_type", ""))
	if planned_type == "":
		return false
	site["type"] = planned_type
	site["construction"] = false
	site["completed"] = true
	site["planned_type"] = ""
	site["construction_remaining"] = 0.0
	site["hp"] = Defs.building_hp(planned_type)
	site["max_hp"] = Defs.building_hp(planned_type)
	site["local_capacity"] = Defs.local_capacity(planned_type)
	site["work_timer"] = _initial_work_timer(planned_type)
	site["production_timer"] = 0.0
	site["storage_paused"] = false
	site["staff_priority"] = _default_staff_priority(planned_type)
	site["materials_needed"] = {}
	site["materials_delivered"] = Defs.empty_inventory()
	site["materials_in_transit"] = Defs.empty_inventory()
	site["status"] = "Complete."
	if planned_type == Defs.BUILDING_STOREHOUSE:
		site["status"] = "Storage capacity expanded."
	if planned_type == Defs.BUILDING_ROAD and rivalry != null:
		rivalry.complete_player_road(site["position"])
	if planned_type == Defs.BUILDING_QUARRY and int(site.get("deposit_remaining", 0)) <= 0:
		site["deposit_remaining"] = _quarry_deposit_for_footprint(site["position"], _building_footprint(site))
	var housing_added := Defs.adds_population(planned_type)
	if housing_added > 0:
		housing_capacity += housing_added
		_add_log("%s completed. Housing capacity increased." % Defs.building_name(planned_type))
	_try_staff_building(site)
	if planned_type == Defs.BUILDING_TOWN_HALL:
		_finish_founding_setup()
		_add_log("The protection bubble awakens with %d Wyrd in reserve." % int(central_inventory.get(Defs.RESOURCE_WYRD, 0)))

	stats["buildings_completed"] = int(stats.get("buildings_completed", 0)) + 1
	_recompute_road_network()
	_reveal_from_world()
	path_grid_dirty = true
	if housing_added <= 0:
		_add_log("%s completed." % Defs.building_name(planned_type))
	_record_event("construction_completed", "Construction completed.", {
		"building_id": int(site["id"]),
		"building_type": planned_type,
		"position": _vector_to_data(site["position"])
	})
	last_message = "%s completed." % Defs.building_name(planned_type)
	if planned_type == Defs.BUILDING_ROAD:
		_emit_audio("road")
	elif planned_type == Defs.BUILDING_FARM:
		_emit_audio("farm_complete")
	elif planned_type == Defs.BUILDING_BARRACKS:
		_emit_audio("barracks_complete")
	else:
		_emit_audio("build_complete")
	if planned_type == Defs.BUILDING_OUTPOST and _footprint_touches_tile(site["position"], _building_footprint(site), shard_position):
		_start_claim(site)
	_update_objectives()
	_ensure_carriers()
	_sync_production_workers()
	return true


func _update_production(delta: float) -> void:
	for building in buildings:
		if float(building.get("damage_flash", 0.0)) > 0.0:
			building["damage_flash"] = max(0.0, float(building["damage_flash"]) - delta)
		var building_type := String(building["type"])
		if not Defs.PRODUCTION_DEFS.has(building_type):
			continue
		if building_type == Defs.BUILDING_QUARRY:
			if bool(building.get("storage_paused", false)):
				building["production_timer"] = 0.0
				if _quarry_output_is_full(building):
					building["status"] = "Storage full - worker released until Stone is moved."
					continue
				if not bool(building.get("staffing_enabled", true)):
					building["status"] = "Paused - staffing disabled."
					continue
				if not _try_staff_building(building):
					building["status"] = "Storage available - waiting for a free worker."
					continue
				building["storage_paused"] = false
				building["status"] = "Worker returning."
			elif _quarry_output_is_full(building):
				_pause_quarry_for_storage(building)
				continue
		if not _building_can_work(building):
			continue
		if is_night:
			building["status"] = "Closed for the night."
			continue

		var definition: Dictionary = Defs.PRODUCTION_DEFS[building_type]
		building["production_timer"] = float(building.get("production_timer", 0.0)) + delta
		var interval := _production_interval(building)
		if float(building["production_timer"]) < interval:
			if not _holds_production_status(String(building.get("status", ""))):
				building["status"] = "Active."
			continue
		_produce_from_building(building)
		building["production_timer"] = 0.0


func _quarry_output_is_full(building: Dictionary) -> bool:
	return _inventory_total(building.get("local_inventory", {})) >= int(building.get("local_capacity", 0))


func _pause_quarry_for_storage(building: Dictionary) -> void:
	building["storage_paused"] = true
	building["production_timer"] = 0.0
	building["assigned_staff"] = 0
	building["staffed"] = false
	building["status"] = "Storage full - worker released until Stone is moved."
	_recalculate_workers_assigned()


func _holds_production_status(status: String) -> bool:
	return status.begins_with("Waiting for ") \
		or status == "Saving Wood for construction." \
		or status == "Depleted." \
		or status == "Forest exhausted." \
		or status.begins_with("Storage full") \
		or status.begins_with("Central storage full")


func _building_can_work(building: Dictionary) -> bool:
	if bool(building.get("construction", false)):
		return false
	if bool(building.get("storage_paused", false)):
		return false
	if String(building.get("type", "")) == Defs.BUILDING_QUARRY and int(building.get("deposit_remaining", 0)) <= 0:
		_mark_quarry_depleted(building)
		return false
	if bool(building.get("abandoned", false)):
		building["status"] = "Abandoned."
		return false
	if not bool(building.get("connected", false)):
		building["status"] = "No road connection."
		return false
	if String(building.get("type", "")) == Defs.BUILDING_WATCHTOWER and int(building.get("soldiers_assigned", 0)) <= 0:
		building["staffed"] = false
		building["status"] = "Needs a trained soldier."
		return false
	var required := Defs.building_staff(String(building["type"]))
	if required > 0 and int(building.get("assigned_staff", 0)) < required:
		building["staffed"] = false
		building["status"] = "Needs workers."
		return false
	return true


func _produce_from_building(building: Dictionary) -> bool:
	var building_type := String(building["type"])
	var definition: Dictionary = Defs.PRODUCTION_DEFS[building_type]
	var output := String(definition.get("output", ""))
	var normal_output_amount := int(definition.get("output_amount", 1))
	var output_amount := _effective_output_amount(building, normal_output_amount)
	var local_inventory: Dictionary = building["local_inventory"]
	if not definition.has("input") and _inventory_total(local_inventory) >= int(building.get("local_capacity", 0)):
		if not (building_type == Defs.BUILDING_LUMBER_CAMP and _priority_tree_in_lumber_reach(building)):
			building["status"] = "Storage full — build more storage or move/consume output."
			return false
	if definition.has("nearby_tile"):
		if building_type != Defs.BUILDING_LUMBER_CAMP and _inventory_total(local_inventory) + output_amount > int(building.get("local_capacity", 0)):
			building["status"] = "Storage full — build more storage or move/consume output."
			return false
		if building_type == Defs.BUILDING_QUARRY:
			var remaining := int(building.get("deposit_remaining", 0))
			if remaining <= 0:
				_mark_quarry_depleted(building)
				return false
			var requested: int = min(output_amount, remaining)
			var produced := _consume_quarry_deposit(building, requested)
			if produced <= 0:
				building["deposit_remaining"] = 0
				_mark_quarry_depleted(building)
				return false
			building["deposit_remaining"] = max(0, remaining - produced)
			local_inventory[output] = int(local_inventory.get(output, 0)) + produced
			if int(building["deposit_remaining"]) <= 0:
				_mark_quarry_depleted(building)
			else:
				building["status"] = "+%d %s." % [produced, Defs.resource_name(output)]
			_record_production(building, output, produced)
			return true
		var deposit_tile := _find_nearby_deposit(_footprint_center(building["position"], _building_footprint(building)), String(definition["nearby_tile"]), LUMBER_REACH)
		if deposit_tile.x < 0:
			if String(building.get("status", "")) != "Forest exhausted.":
				_add_log("%s has exhausted every tree stand in walking range." % _display_building_name(building))
				_record_event("lumber_exhausted", "A Lumber Camp exhausted its nearby forest.", {
					"building_id": int(building.get("id", 0)),
					"reach": LUMBER_REACH
				})
			building["status"] = "Forest exhausted."
			return false
		var deposit_key := _tile_key(deposit_tile)
		if String(building.get("active_deposit", "")) != deposit_key:
			building["active_deposit"] = deposit_key
			_record_event("lumber_retargeted", "A Lumber Camp moved to a fresh tree stand.", {
				"building_id": int(building.get("id", 0)),
				"position": _vector_to_data(deposit_tile)
			})
		var available_deposit := int(tree_deposits.get(_tile_key(deposit_tile), 0))
		var produced: int = mini(output_amount, available_deposit)
		var room := maxi(0, int(building.get("local_capacity", 0)) - _inventory_total(local_inventory))
		var stored := mini(produced, room)
		if stored > 0:
			local_inventory[output] = int(local_inventory.get(output, 0)) + stored
		var leftover := produced - stored
		if leftover > 0:
			var central_room := get_storage_room(output)
			var overflow := mini(leftover, central_room)
			if overflow > 0:
				central_inventory[output] = int(central_inventory.get(output, 0)) + overflow
		_consume_deposit(deposit_tile, produced)
		building["status"] = "+%d %s." % [produced, Defs.resource_name(output)] if stored > 0 else "CLEARING SITE"
		_record_production(building, output, maxi(stored, 0))
		return true

	if definition.has("input"):
		var input_resource := String(definition["input"])
		var input_amount := int(definition.get("input_amount", 1))
		var available_input := int(local_inventory.get(input_resource, 0))
		if available_input < input_amount:
			building["status"] = "Waiting for %s." % Defs.resource_name(input_resource)
			return false
		var projected_total := _inventory_total(local_inventory) - input_amount + output_amount
		if projected_total > int(building.get("local_capacity", 0)):
			building["status"] = "Storage full — build more storage or move/consume output."
			return false
		local_inventory[input_resource] = available_input - input_amount
		local_inventory[output] = int(local_inventory.get(output, 0)) + output_amount
		building["status"] = "-%d %s, +%d %s." % [input_amount, Defs.resource_name(input_resource), output_amount, Defs.resource_name(output)]
		_record_production(building, output, output_amount, input_resource, input_amount)
		return true

	if _inventory_total(local_inventory) + output_amount > int(building.get("local_capacity", 0)):
		building["status"] = "Storage full — build more storage or move/consume output."
		return false
	local_inventory[output] = int(local_inventory.get(output, 0)) + output_amount
	building["status"] = "+%d %s." % [output_amount, Defs.resource_name(output)]
	_record_production(building, output, output_amount)
	return true


func _effective_output_amount(building: Dictionary, normal_amount: int) -> int:
	var amount := normal_amount
	if is_hunger_penalty_active():
		for worker in workers:
			if int(worker.get("building_id", 0)) == int(building.get("id", 0)) and bool(worker.get("hungry", false)):
				amount = maxi(1, int(floor(float(normal_amount) * HUNGER_OUTPUT_MULTIPLIER)))
				break
	var quality := float(building.get("placement_quality", 1.0))
	if quality > 0.0 and absf(quality - 1.0) > 0.001:
		amount = maxi(1, int(round(float(amount) * quality)))
	return amount


func _record_production(building: Dictionary, output: String, output_amount: int, input_resource: String = "", input_amount: int = 0) -> void:
	var details := {
		"building_id": int(building.get("id", 0)),
		"building_type": String(building.get("type", "")),
		"output": output,
		"output_amount": output_amount,
		"local_inventory": building.get("local_inventory", {}).duplicate(true)
	}
	if input_resource != "":
		details["input"] = input_resource
		details["input_amount"] = input_amount
	building["last_production_elapsed"] = elapsed_seconds
	_record_event("production", "Local production completed.", details)
	match output:
		Defs.RESOURCE_WOOD:
			stats["wood_produced"] = int(stats.get("wood_produced", 0)) + output_amount
		Defs.RESOURCE_STONE:
			stats["stone_produced"] = int(stats.get("stone_produced", 0)) + output_amount
		Defs.RESOURCE_WHEAT:
			stats["wheat_produced"] = int(stats.get("wheat_produced", 0)) + output_amount
		Defs.RESOURCE_BREAD:
			stats["bread_produced"] = int(stats.get("bread_produced", 0)) + output_amount
		Defs.RESOURCE_WYRD:
			stats["wyrd_extracted"] = int(stats.get("wyrd_extracted", 0)) + output_amount


func _find_nearby_deposit(origin: Vector2i, tile_type: String, radius: int) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_distance := 1000000
	var best_town_distance := 1000000
	var town_center := _footprint_center(town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	for offset in _radius_offsets(radius):
		var tile: Vector2i = origin + offset
		if not is_inside_map(tile):
			continue
		if get_tile(tile) != tile_type:
			continue
		var key := _tile_key(tile)
		if tile_type == Defs.TILE_TREE and int(tree_deposits.get(key, 0)) <= 0:
			continue
		if tile_type == Defs.TILE_ROCK and int(rock_deposits.get(key, 0)) <= 0:
			continue
		var distance := _manhattan(origin, tile)
		var town_distance := _manhattan(town_center, tile)
		var priority := int(priority_clear_tiles.get(key, 0)) if tile_type == Defs.TILE_TREE else 0
		if tile_type == Defs.TILE_TREE and priority > 0:
			distance -= priority * 20
			town_distance -= priority * 20
		var is_better := town_distance < best_town_distance if tile_type == Defs.TILE_TREE else distance < best_distance
		if tile_type == Defs.TILE_TREE and town_distance == best_town_distance:
			is_better = distance < best_distance
		if is_better:
			best = tile
			best_distance = distance
			best_town_distance = town_distance
	return best


func _mark_quarry_depleted(building: Dictionary) -> void:
	if bool(building.get("depleted", false)):
		building["status"] = "Depleted — stone exhausted. This quarry is now a husk."
		return
	building["depleted"] = true
	building["deposit_remaining"] = 0
	building["staffing_enabled"] = false
	building["assigned_staff"] = 0
	building["staffed"] = false
	building["status"] = "Depleted — stone exhausted. This quarry is now a husk."
	_recalculate_workers_assigned()
	_add_log("A Quarry is depleted. Its worker is free and the empty site remains as a husk.")
	_record_event("quarry_depleted", "A Quarry exhausted its stone deposit.", {
		"building_id": int(building.get("id", 0)),
		"position": _vector_to_data(building.get("position", Vector2i.ZERO))
	})


func _consume_deposit(tile: Vector2i, amount: int) -> void:
	var key := _tile_key(tile)
	var resource_type := ""
	var remaining := 0
	if get_tile(tile) == Defs.TILE_TREE:
		resource_type = Defs.RESOURCE_WOOD
		tree_deposits[key] = max(0, int(tree_deposits.get(key, 0)) - amount)
		remaining = int(tree_deposits[key])
		if int(tree_deposits[key]) <= 0:
			tree_deposits.erase(key)
			_set_tile(tile, Defs.TILE_GRASS)
			# Retain a cheap deterministic stump marker. Forest regeneration is no
			# longer automatic because cleared land must remain readable after load.
			tree_regrowth[key] = -1.0
	elif get_tile(tile) == Defs.TILE_ROCK:
		resource_type = Defs.RESOURCE_STONE
		rock_deposits[key] = max(0, int(rock_deposits.get(key, 0)) - amount)
		remaining = int(rock_deposits[key])
		if int(rock_deposits[key]) <= 0:
			rock_deposits.erase(key)
			_set_tile(tile, Defs.TILE_GRASS)
	if resource_type != "":
		_record_event("deposit_harvested", "%s deposit harvested." % Defs.resource_name(resource_type), {
			"resource": resource_type,
			"amount": amount,
			"remaining": remaining,
			"position": _vector_to_data(tile)
		})


func _consume_quarry_deposit(building: Dictionary, amount: int) -> int:
	var remaining_amount := amount
	var consumed := 0
	for tile in get_building_footprint_tiles(building):
		if remaining_amount <= 0:
			break
		var available := int(rock_deposits.get(_tile_key(tile), 0))
		if available <= 0:
			continue
		var take := mini(available, remaining_amount)
		_consume_deposit(tile, take)
		remaining_amount -= take
		consumed += take
	return consumed


func _update_tree_regrowth(delta: float) -> void:
	for key_value in tree_regrowth.keys():
		var key := String(key_value)
		if float(tree_regrowth.get(key, -1.0)) <= 0.0:
			continue
		var remaining := float(tree_regrowth.get(key, 0.0)) - delta
		if remaining > 0.0:
			tree_regrowth[key] = remaining
			continue
		var tile := _tile_from_key(key)
		if not is_inside_map(tile) or is_tile_occupied(tile) or get_tile(tile) != Defs.TILE_GRASS:
			tree_regrowth[key] = 20.0
			continue
		_set_tile(tile, Defs.TILE_TREE)
		tree_deposits[key] = 18
		tree_regrowth.erase(key)
		_record_event("tree_regrown", "A harvested tree stand has regrown.", {"position": _vector_to_data(tile)})


func _update_barracks(delta: float) -> void:
	var soldier_capacity := 0
	for building in buildings:
		if String(building.get("type", "")) == Defs.BUILDING_BARRACKS and not bool(building.get("construction", false)):
			soldier_capacity += BARRACKS_SOLDIER_CAPACITY
	if soldiers_total >= soldier_capacity:
		return
	for barracks in buildings:
		if String(barracks.get("type", "")) != Defs.BUILDING_BARRACKS or not _building_can_work(barracks) or is_night:
			continue
		if workers_free() <= 0:
			barracks["status"] = "No free recruit."
			continue
		if int(central_inventory.get(Defs.RESOURCE_BREAD, 0)) < SOLDIER_BREAD_COST:
			barracks["status"] = "Needs %d Bread to train a soldier." % SOLDIER_BREAD_COST
			continue
		barracks["training_progress"] = float(barracks.get("training_progress", 0.0)) + delta
		barracks["status"] = "Training Soldier"
		if float(barracks["training_progress"]) < BARRACKS_TRAIN_SECONDS:
			continue
		barracks["training_progress"] = 0.0
		central_inventory[Defs.RESOURCE_BREAD] = int(central_inventory.get(Defs.RESOURCE_BREAD, 0)) - SOLDIER_BREAD_COST
		soldiers_total += 1
		_add_log("A soldier completed training at the Barracks.")
		_emit_audio("settler_spawn_soldier")
		_auto_staff_towers()
		_sync_production_workers()
		_record_event("soldier_trained", "A soldier completed training.", {"soldiers": soldiers_total})
		if soldiers_total >= soldier_capacity:
			return


func _activate_revealed_enemy_camps() -> void:
	for camp in enemy_camps:
		if bool(camp.get("active", false)) or bool(camp.get("destroyed", false)):
			continue
		var camp_position: Vector2i = camp["position"]
		var road_discovered := false
		for offset in _radius_offsets(3):
			if connected_roads.has(_tile_key(camp_position + offset)):
				road_discovered = true
				break
		if not road_discovered:
			continue
		camp["active"] = true
		camp["defenders_spawned"] = true
		var count := 4 + day_count
		for index in range(count):
			_spawn_enemy(camp_position, 16 + day_count * 2, 1 + int(day_count / 4), -0.10 * float(index), int(camp.get("id", 0)))
		_add_log("A road patrol has disturbed an enemy camp. %d raiders mobilize." % count)
		_emit_audio("enemy")
		_record_event("enemy_camp_activated", "A road discovered an enemy camp.", {"camp_id": int(camp.get("id", 0)), "enemies": count})


func _enemy_camp_at_tile(tile: Vector2i) -> bool:
	for camp in enemy_camps:
		if bool(camp.get("destroyed", false)):
			continue
		if _manhattan(tile, camp["position"]) <= 2:
			return true
	return false


func _note_combat() -> void:
	last_combat_elapsed = elapsed_seconds


## Credits a monster kill to a player unit exactly once (soldier strike or
## soldier-staffed tower bolt) and raises the "monster_kill" audio cue.
func _credit_player_kill(enemy: Dictionary, source: String, unit_id: int) -> void:
	if int(enemy.get("hp", 0)) > 0 or bool(enemy.get("kill_credited", false)):
		return
	enemy["kill_credited"] = true
	player_monster_kills += 1
	last_player_kill = {
		"enemy_id": int(enemy.get("id", 0)),
		"enemy_type": String(enemy.get("enemy_type", ENEMY_RAIDER)),
		"source": source,
		"unit_id": unit_id,
		"elapsed": elapsed_seconds,
		"kills": player_monster_kills
	}
	_record_event("monster_killed_by_player", "A defender felled a monster.", last_player_kill.duplicate())
	_emit_audio("monster_kill")


func living_hostile_count() -> int:
	var count := 0
	for enemy in enemies:
		if int(enemy.get("hp", 0)) > 0 and not bool(enemy.get("retreating", false)):
			count += 1
	return count


## True while defenders and monsters are actually engaged (enemy strike,
## soldier strike, tower fire or bolt impact within COMBAT_LINGER_SECONDS) and a
## living hostile remains. Proximity alone is not combat: early waves spawn close
## to the Town Hall, which made nightfall itself read as combat.
func is_combat_active() -> bool:
	if living_hostile_count() <= 0:
		return false
	return elapsed_seconds - last_combat_elapsed <= COMBAT_LINGER_SECONDS


func _emit_audio(event_name: String) -> void:
	if not audio_events.has(event_name):
		audio_events.append(event_name)


func _update_hunger_recovery(delta: float) -> void:
	if not is_hunger_penalty_active() or is_night:
		return
	hunger_penalty_remaining = max(0.0, hunger_penalty_remaining - delta)
	if hunger_penalty_remaining > 0.0:
		return
	var recovered := hungry_population
	hungry_population = 0
	_refresh_worker_hunger_flags()
	_add_log("%d hungry settlers have recovered." % recovered)
	_record_event("hunger_recovered", "The settlement recovered from hunger.", {"workers": recovered})


func _serve_night_meal() -> void:
	var demand := population_current
	var remaining := demand
	var bread_used: int = min(remaining, int(central_inventory.get(Defs.RESOURCE_BREAD, 0)))
	central_inventory[Defs.RESOURCE_BREAD] = int(central_inventory.get(Defs.RESOURCE_BREAD, 0)) - bread_used
	remaining -= bread_used
	var wheat_used := 0
	if remaining > 0:
		var wheat_available := int(central_inventory.get(Defs.RESOURCE_WHEAT, 0))
		var wheat_meals: int = min(remaining, int(floor(float(wheat_available) / 2.0)))
		wheat_used = wheat_meals * 2
		central_inventory[Defs.RESOURCE_WHEAT] = wheat_available - wheat_used
		remaining -= wheat_meals
	hungry_population = remaining
	hunger_penalty_remaining = 0.0
	_refresh_worker_hunger_flags()
	if hungry_population > 0:
		stats["hungry_nights"] = int(stats.get("hungry_nights", 0)) + 1
		_add_log("Night meal short: %d of %d settlers go hungry." % [hungry_population, demand])
		last_message = "%d settlers did not receive a meal." % hungry_population
	else:
		_add_log("Night meal served to all %d settlers." % demand)
	_record_event("night_meal", "Night meal served.", {
		"demand": demand,
		"fed": demand - remaining,
		"hungry": remaining,
		"bread_used": bread_used,
		"wheat_used": wheat_used
	})


func _refresh_worker_hunger_flags() -> void:
	var hungry_visible := 0
	if hungry_population > 0 and population_current > 0:
		hungry_visible = mini(workers.size(), int(ceil(float(workers.size() * hungry_population) / float(population_current))))
	for index in range(workers.size()):
		workers[index]["hungry"] = index < hungry_visible


func _update_population_growth(delta: float) -> void:
	pop_growth_timer += delta
	var early_arrival := population_current < STARTING_HOUSING_CAPACITY
	var growth_interval := FOUNDING_POP_GROWTH_INTERVAL if early_arrival else POP_GROWTH_INTERVAL
	if pop_growth_timer < growth_interval:
		return
	pop_growth_timer = 0.0
	if is_night or population_current >= housing_capacity:
		return
	if early_arrival:
		population_current = min(housing_capacity, population_current + 1)
		stats["peak_population"] = maxi(int(stats.get("peak_population", 0)), population_current)
		_add_log("A founding settler leaves the Town Hall. Population %d/%d." % [population_current, housing_capacity])
		last_message = "A new founding settler has arrived. Population %d/%d." % [population_current, housing_capacity]
		_auto_staff_unstaffed_buildings()
		_record_event("population_growth", last_message, {"population": population_current, "housing": housing_capacity, "founding_arrival": true})
		_emit_audio("settler_spawn_worker")
		return
	var reserve_needed := get_next_food_demand()
	if get_food_units() < reserve_needed + POP_GROWTH_FOOD_COST:
		return
	var bread_available := int(central_inventory.get(Defs.RESOURCE_BREAD, 0))
	var wheat_available := int(central_inventory.get(Defs.RESOURCE_WHEAT, 0))
	if bread_available >= POP_GROWTH_FOOD_COST:
		central_inventory[Defs.RESOURCE_BREAD] = bread_available - POP_GROWTH_FOOD_COST
	elif wheat_available >= POP_GROWTH_FOOD_COST * 2:
		central_inventory[Defs.RESOURCE_WHEAT] = wheat_available - POP_GROWTH_FOOD_COST * 2
	else:
		return
	population_current = min(housing_capacity, population_current + 1)
	stats["peak_population"] = maxi(int(stats.get("peak_population", 0)), population_current)
	_add_log("A new settler leaves the Town Hall. Population %d/%d." % [population_current, housing_capacity])
	last_message = "A new settler is ready at the Town Hall. Population %d/%d." % [population_current, housing_capacity]
	_auto_staff_unstaffed_buildings()
	_record_event("population_growth", last_message, {"population": population_current, "housing": housing_capacity})
	_emit_audio("settler_spawn_worker")


func _update_time(delta: float) -> void:
	phase_time += delta
	var remaining := DAY_LENGTH_SECONDS - phase_time
	if not is_night and not dusk_warning_sent and remaining <= RaidIntents.DUSK_WARNING_SECONDS:
		dusk_warning_sent = true
		if dusk_forecast.is_empty():
			dusk_forecast = Wyrdfall.night_forecast(float(get_wyrd_pressure().get("value", 0.0)), day_count <= 1)
		_prepare_raid_plan()
		last_message = RaidIntents.dusk_message()
		_add_log("Dusk approaches.")
		playtest_log.note(self, "dusk_warning", last_message)
	if not is_night and not horn_warning_sent and remaining <= RaidIntents.HORN_WARNING_SECONDS:
		horn_warning_sent = true
		if _hostile_forces_nearby():
			if raid_plan.is_empty():
				_prepare_raid_plan()
			last_message = RaidIntents.horn_message(String(raid_plan.get("bearing", "the woods")))
			_add_log(last_message)
			playtest_log.note(self, "horn_warning", last_message)
	if not is_night and not night_warning_sent and remaining <= NIGHT_WARNING_SECONDS:
		night_warning_sent = true
		path_grid_dirty = true
		dusk_forecast = Wyrdfall.night_forecast(float(get_wyrd_pressure().get("value", 0.0)), day_count <= 1)
		if day_count == 1:
			var has_tower := false
			for building in buildings:
				if String(building.get("type", "")) == Defs.BUILDING_WATCHTOWER and not bool(building.get("construction", false)):
					has_tower = true
					break
			if not has_tower:
				_offer_onboarding("first_night", "NIGHT BRINGS RAIDERS. Build a Watchtower and train a soldier at the Barracks to defend against attacks. Houses shelter workers at night.")
			else:
				_offer_onboarding("dusk", "Night tests what you built. Wyrd Pressure sets how hard it hits.")
		else:
			_offer_onboarding("dusk", "Night tests what you built. Wyrd Pressure sets how hard it hits.")
		_add_log("NIGHTFALL. Threat: %s. Likely activity: %s." % [
			String(dusk_forecast.get("threat", "QUIET")),
			String(dusk_forecast.get("activity", "Light"))
		])
		last_message = "NIGHTFALL — Threat: %s. Likely activity: %s." % [
			String(dusk_forecast.get("threat", "QUIET")),
			String(dusk_forecast.get("activity", "Light"))
		]
	if not is_night and not night_final_warning_sent and remaining <= NIGHT_FINAL_WARNING_SECONDS:
		night_final_warning_sent = true
		path_grid_dirty = true
		_send_workers_to_shelter()
		_add_log("Final warning: night falls in 30 seconds. Civilians are returning home and gates are closing.")
		last_message = "NIGHT IN 30 SECONDS — civilians are returning home."
		_emit_audio("night")

	if not is_night and phase_time >= DAY_LENGTH_SECONDS:
		_start_night()
	elif is_night and phase_time >= NIGHT_LENGTH_SECONDS:
		_end_night()


func _start_night() -> void:
	is_night = true
	phase_time = 0.0
	night_warning_sent = false
	night_final_warning_sent = false
	dusk_warning_sent = false
	horn_warning_sent = false
	path_grid_dirty = true
	night_casualties = 0
	night_buildings_damaged = 0
	night_enemies_spawned = 0
	night_enemies_defeated_at_dusk = int(stats.get("enemies_defeated", 0))
	var pressure := get_wyrd_pressure()
	_add_log("Night %d begins. Wyrd Pressure is %s." % [day_count, String(pressure.get("band", Wyrdfall.BAND_QUIET))])
	last_message = "Night %d begins." % day_count
	if not is_revealed(shard_position):
		hidden_threat_level += 1
	_serve_night_meal()
	_send_workers_to_shelter()
	_spawn_wave()
	_emit_audio("night")
	playtest_log.note(self, "night_started", "Night %d" % day_count)


func _end_night() -> void:
	_finish_raid("dawn")
	is_night = false
	phase_time = 0.0
	night_warning_sent = false
	night_final_warning_sent = false
	dusk_warning_sent = false
	horn_warning_sent = false
	day_count += 1
	path_grid_dirty = true
	_retreat_enemies_at_dawn()
	if hungry_population > 0:
		hunger_penalty_remaining = DAY_LENGTH_SECONDS * HUNGER_RECOVERY_FRACTION
		_add_log("Hungry workers produce at half output until mid-morning.")
		_record_event("hunger_penalty_started", "Hungry workers begin a slow morning.", {
			"hungry": hungry_population,
			"duration": hunger_penalty_remaining
		})
	_wake_workers_at_dawn()
	stats["days_survived"] = max(int(stats.get("days_survived", 0)), day_count - 1)
	intention_flags["first_dawn"] = true
	_add_log("Dawn breaks. Day %d begins." % day_count)
	playtest_log.note(self, "dawn", "Day %d" % day_count)
	last_message = "Hungry workers are recovering." if hungry_population > 0 else "Dawn breaks."
	_compose_dawn_summary()
	if rivalry != null:
		return
	if claim_active:
		var outpost := _find_building_by_id(claim_outpost_id)
		if outpost.is_empty():
			_cancel_claim("Claim failed: the Outpost is gone.")
		else:
			claim_nights_survived += 1
			_add_log("Shard claim held through the night: %d/2." % claim_nights_survived)
			if claim_nights_survived >= 2:
				_finish_run(true, "SHARD BOUND")


func _spawn_wave() -> void:
	var pressure := get_wyrd_pressure()
	var plan := Wyrdfall.wave_plan(float(pressure.get("value", 0.0)), day_count, day_count <= 1, reckoning_active)
	var wave_size := int(plan.get("size", 0))
	var hp := int(plan.get("hp", RaidTuning.NIGHT1_HP))
	var damage := int(plan.get("damage", RaidTuning.NIGHT1_DAMAGE))
	var armor := int(plan.get("armor", RaidTuning.NIGHT1_ARMOR))
	var roster: Array = plan.get("roster", [ENEMY_RAIDER])
	if wave_size <= 0:
		_add_log("The first night remains quiet. No raiders emerge.")
		last_message = "QUIET NIGHT - no raiders emerged from the fog."
		return
	if raid_plan.is_empty():
		_prepare_raid_plan()
	var spawn_origins := _night_spawn_origins()
	for i in range(wave_size):
		var origin: Vector2i = shard_position if spawn_origins.is_empty() else spawn_origins[i % spawn_origins.size()]
		if is_tile_protected(origin) and not spawn_origins.is_empty():
			origin = spawn_origins[i % spawn_origins.size()]
		_spawn_enemy(origin, hp, damage, -0.08 * float(i), 0, String(roster[i % roster.size()]), armor)
	night_enemies_spawned += wave_size
	_begin_raid(int(plan.get("steal", RaidTuning.steal_for_night(day_count, day_count <= 1))))
	playtest_log.note(self, "raid_started", "wave=%d intent=%s" % [wave_size, String(raid_plan.get("intent", ""))])
	if reckoning_active:
		reckoning_waves_spawned += 1
	var bearing := "the wilds"
	if not spawn_origins.is_empty():
		bearing = _bearing_from_town(spawn_origins[0])
	_add_log("%d hostiles emerge from %s (%s)." % [wave_size, bearing, String(plan.get("band", pressure.get("band", "")))])
	last_message = "NIGHT RAID — %d hostiles from %s." % [wave_size, bearing]
	push_notice("danger", "RAID", "%d hostiles are coming from %s." % [wave_size, bearing], "critical")
	_emit_audio("enemy")


func _night_spawn_origins() -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	var town_center := _footprint_center(town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	for y in range(map_size.y):
		for x in range(map_size.x):
			var tile := Vector2i(x, y)
			if is_revealed(tile) or is_tile_occupied(tile) or String(get_tile(tile)) != Defs.TILE_GRASS:
				continue
			if _manhattan(town_center, tile) < 11 or _manhattan(town_center, tile) > 16:
				continue
			if is_tile_protected(tile) or _tile_in_any_tower_range(tile):
				continue
			var touches_revealed := false
			for neighbor in _neighbors(tile):
				if is_revealed(neighbor):
					touches_revealed = true
					break
			if touches_revealed:
				candidates.append(tile)
	candidates.sort_custom(func(first: Vector2i, second: Vector2i) -> bool:
		var first_distance := _manhattan(town_center, first)
		var second_distance := _manhattan(town_center, second)
		if first_distance == second_distance:
			return _tile_key(first) < _tile_key(second)
		return first_distance < second_distance
	)
	if candidates.is_empty():
		for y in range(map_size.y):
			for x in range(map_size.x):
				var tile := Vector2i(x, y)
				if is_revealed(tile) or is_tile_occupied(tile) or String(get_tile(tile)) != Defs.TILE_GRASS:
					continue
				if _manhattan(town_center, tile) < 10 or _manhattan(town_center, tile) > 18:
					continue
				candidates.append(tile)
		candidates.sort_custom(func(first: Vector2i, second: Vector2i) -> bool:
			return _manhattan(town_center, first) > _manhattan(town_center, second)
		)
	return candidates.slice(0, mini(8, candidates.size()))


func _prepare_raid_plan() -> Dictionary:
	var intent := RaidIntents.choose(day_count, rng_seed)
	var bearing_tile := shard_position
	for camp in enemy_camps:
		if bool(camp.get("destroyed", false)):
			continue
		bearing_tile = Vector2i(camp.get("position", shard_position))
		break
	if bearing_tile == shard_position:
		var origins := _night_spawn_origins()
		if not origins.is_empty():
			bearing_tile = origins[0]
	var target := {}
	if intent != RaidIntents.INTENT_CENTER:
		var yards := _raid_economy_candidates()
		if not yards.is_empty():
			target = yards[0]
	if target.is_empty():
		target = _find_town_hall()
	if dusk_forecast.is_empty() or String(dusk_forecast.get("threat", "")) == "":
		dusk_forecast = Wyrdfall.night_forecast(float(get_wyrd_pressure().get("value", 0.0)), day_count <= 1)
	raid_plan = {
		"intent": intent,
		"bearing": _bearing_from_town(bearing_tile),
		"target_id": int(target.get("id", 0)),
		"target_name": _display_building_name(target) if not target.is_empty() else "the settlement"
	}
	dusk_forecast["raid_intent"] = intent
	dusk_forecast["bearing"] = raid_plan["bearing"]
	return raid_plan


func _raid_economy_candidates() -> Array:
	var yards: Array = []
	for building in buildings:
		var building_type := String(building.get("type", ""))
		if bool(building.get("construction", false)):
			continue
		if building_type == Defs.BUILDING_TOWN_HALL or building_type == Defs.BUILDING_ROAD:
			continue
		if building_type in RaidTuning.LOOT_BUILDING_TYPES:
			yards.append(building)
	return yards


func _hostile_forces_nearby() -> bool:
	for camp in enemy_camps:
		if not bool(camp.get("destroyed", false)):
			return true
	for feature in world_features:
		if String(feature.get("kind", "")) == Discoveries.KIND_TRACES and bool(feature.get("revealed", false)):
			return true
	if hidden_threat_level > 0:
		return true
	var threat := String(dusk_forecast.get("threat", "QUIET"))
	return threat != "" and threat != Wyrdfall.BAND_QUIET


func _bearing_from_town(origin: Vector2i) -> String:
	var town := _footprint_center(town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	var delta := origin - town
	var abs_x := absi(delta.x)
	var abs_y := absi(delta.y)
	if abs_x > abs_y * 2:
		return "the east" if delta.x > 0 else "the west"
	if abs_y > abs_x * 2:
		return "the south" if delta.y > 0 else "the north"
	if delta.y <= 0 and delta.x >= 0:
		return "the north-east"
	if delta.y <= 0 and delta.x < 0:
		return "the north-west"
	if delta.y > 0 and delta.x >= 0:
		return "the south-east"
	return "the south-west"


func _tile_in_any_tower_range(tile: Vector2i) -> bool:
	for building in buildings:
		if String(building.get("type", "")) != Defs.BUILDING_WATCHTOWER or bool(building.get("construction", false)):
			continue
		var center := _footprint_center(building["position"], _building_footprint(building))
		if _manhattan(center, tile) <= TOWER_RANGE:
			return true
	return false


func _spawn_enemy(
	origin: Vector2i,
	hp: int,
	damage: int,
	movement_delay: float = 0.0,
	camp_id: int = 0,
	enemy_type: String = ENEMY_RAIDER,
	armor: int = 0
) -> void:
	var tuning := _enemy_archetype(enemy_type)
	var tuned_hp := maxi(1, roundi(float(hp) * float(tuning.get("hp", 1.0))))
	var tuned_damage := maxi(1, roundi(float(damage) * float(tuning.get("damage", 1.0))))
	var tuned_armor := maxi(0, armor + int(tuning.get("armor", 0)))
	enemies.append({
		"id": next_enemy_id,
		"enemy_type": enemy_type,
		"position": origin,
		"hp": tuned_hp,
		"max_hp": tuned_hp,
		"damage": tuned_damage,
		"armor": tuned_armor,
		"speed_multiplier": float(tuning.get("speed", 1.0)),
		"attack_range": int(tuning.get("range", 1)),
		"attack_interval": float(tuning.get("interval", ENEMY_ATTACK_INTERVAL_SECONDS)),
		"camp_id": camp_id,
		"target_id": 0,
		"target_kind": "building",
		"target_position": _vector_to_data(origin),
		"path": [],
		"move_elapsed": movement_delay,
		"attack_timer": 0.0,
		"attack_flash": 0.0,
		"attack_damage_applied": true,
		"hit_until": 0.0,
		"hit_direction": _vector_to_data(Vector2i.ZERO),
		"retreating": false,
		"retreat_target": _vector_to_data(origin),
		"target_refresh_timer": 0.0,
		"raid_intent": String(raid_plan.get("intent", ""))
	})
	next_enemy_id += 1


func _enemy_archetype(enemy_type: String) -> Dictionary:
	if enemy_type == ENEMY_SKITTERER:
		return {"hp": 0.58, "damage": 0.70, "speed": 0.52, "range": 1, "interval": 1.25, "armor": 0}
	if enemy_type == ENEMY_BRUTE:
		return {"hp": 2.35, "damage": 1.75, "speed": 1.48, "range": 1, "interval": 2.25, "armor": 1}
	if enemy_type == ENEMY_HEXER:
		return {"hp": 0.82, "damage": 0.75, "speed": 1.08, "range": 4, "interval": 3.2, "armor": 0}
	return {"hp": 1.0, "damage": 1.0, "speed": 1.0, "range": 1, "interval": ENEMY_ATTACK_INTERVAL_SECONDS, "armor": 0}


func _update_enemies(delta: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[i]
		if int(enemy["hp"]) <= 0:
			_note_raid_enemy_killed(enemy)
			enemies.remove_at(i)
			stats["enemies_defeated"] = int(stats.get("enemies_defeated", 0)) + 1
			continue
		if bool(enemy.get("retreating", false)) and not is_revealed(enemy["position"]):
			enemies.remove_at(i)
			continue
		_update_enemy(enemy, delta)


func _update_enemy(enemy: Dictionary, delta: float) -> void:
	if day_count <= 1 and is_night and phase_time >= RaidTuning.NIGHT1_RETREAT_SECONDS and not bool(enemy.get("retreating", false)):
		enemy["retreating"] = true
		enemy["path"] = []
	elif day_count > 1 and String(enemy.get("raid_intent", "")) == RaidIntents.INTENT_PROBE and is_night and phase_time >= RaidIntents.PROBE_RETREAT_SECONDS and not bool(enemy.get("retreating", false)):
		enemy["retreating"] = true
		enemy["path"] = []
	if bool(enemy.get("retreating", false)):
		_update_retreating_enemy(enemy, delta)
		return
	enemy["target_refresh_timer"] = maxf(0.0, float(enemy.get("target_refresh_timer", 0.0)) - delta)
	var target: Dictionary = _cached_enemy_target(enemy)
	var target_kind := String(enemy.get("target_kind", "building"))
	var target_id := int(enemy.get("target_id", 0))
	var refresh_target := target.is_empty() or float(enemy["target_refresh_timer"]) <= 0.0
	if refresh_target:
		var target_info := _find_enemy_target(enemy)
		if target_info.is_empty():
			return
		target = target_info["entity"]
		target_kind = String(target_info["kind"])
		target_id = int(target["id"])
		var refreshed_position := _enemy_target_position(enemy["position"], target, target_kind)
		var previous_position := _vector_from_data(enemy.get("target_position", _vector_to_data(refreshed_position)), refreshed_position)
		var changed_target := String(enemy.get("target_kind", "")) != target_kind or int(enemy.get("target_id", 0)) != target_id
		if changed_target or previous_position != refreshed_position:
			enemy["path"] = []
		if target_kind == "worker" and changed_target:
			_record_event("enemy_target_worker", "An enemy targets an exposed worker.", {
				"enemy_id": int(enemy["id"]),
				"worker_id": target_id,
				"worker_type": String(target.get("type", "settler"))
			})
		enemy["target_id"] = target_id
		enemy["target_kind"] = target_kind
		enemy["target_position"] = _vector_to_data(refreshed_position)
		# Preserve the original refresh window while spreading deterministic
		# retarget work across seven buckets instead of three large bursts.
		enemy["target_refresh_timer"] = ENEMY_TARGET_REFRESH_SECONDS + float(int(enemy["id"]) % 7) * 0.027
	var target_position := _enemy_target_position(enemy["position"], target, target_kind)
	var attack_range := int(enemy.get("attack_range", 1))
	var is_hexer := String(enemy.get("enemy_type", ENEMY_RAIDER)) == ENEMY_HEXER
	if _manhattan(enemy["position"], target_position) <= attack_range:
		var target_is_protected := is_tile_protected(target_position)
		var attack_remaining := float(enemy.get("attack_flash", 0.0))
		if attack_remaining > 0.0:
			attack_remaining = maxf(0.0, attack_remaining - delta)
			enemy["attack_flash"] = attack_remaining
			if not bool(enemy.get("attack_damage_applied", true)) and attack_remaining <= ENEMY_ATTACK_STRIKE_REMAINING:
				enemy["attack_damage_applied"] = true
				if is_hexer and target_is_protected:
					central_inventory[Defs.RESOURCE_WYRD] = maxi(0, int(central_inventory.get(Defs.RESOURCE_WYRD, 0)) - 1)
					protection_powered = int(central_inventory.get(Defs.RESOURCE_WYRD, 0)) > 0
					last_message = "A Wyrd Hexer is draining Lumen — intercept it outside the boundary."
					projectiles.append({
						"kind": "hex",
						"from": _vector_to_data(enemy["position"]),
						"to": _vector_to_data(target_position),
						"life": 0.55,
						"total": 0.55
					})
				elif target_kind == "worker":
					_damage_worker(target_id, int(enemy["damage"]), enemy["position"])
				else:
					_damage_building(target, int(enemy["damage"]))
				_note_combat()
				_emit_audio("attack")
			return
		enemy["attack_timer"] = float(enemy.get("attack_timer", 0.0)) - delta
		if float(enemy["attack_timer"]) <= 0.0:
			enemy["attack_timer"] = float(enemy.get("attack_interval", ENEMY_ATTACK_INTERVAL_SECONDS))
			enemy["attack_flash"] = ENEMY_ATTACK_ANIMATION_SECONDS
			enemy["attack_damage_applied"] = false
		return

	enemy["attack_flash"] = 0.0
	enemy["attack_damage_applied"] = true
	enemy["move_elapsed"] = float(enemy.get("move_elapsed", 0.0)) + delta
	if enemy["path"].is_empty():
		enemy["path"] = _find_enemy_path(enemy["position"], target_position)
	if enemy["path"].is_empty():
		return
	var step_seconds := _enemy_step_seconds(enemy["position"], enemy["path"][0], float(enemy.get("speed_multiplier", 1.0)))
	if float(enemy["move_elapsed"]) < step_seconds:
		return
	enemy["move_elapsed"] = 0.0
	enemy["position"] = enemy["path"].pop_front()


func _cached_enemy_target(enemy: Dictionary) -> Dictionary:
	var target_id := int(enemy.get("target_id", 0))
	if target_id <= 0:
		return {}
	if String(enemy.get("target_kind", "")) == "worker":
		for worker in workers:
			if int(worker.get("id", 0)) == target_id and int(worker.get("hp", WORKER_MAX_HP)) > 0 and String(worker.get("state", "")) != "Sheltered":
				return worker
		return {}
	return _find_building_by_id(target_id)


func _retreat_enemies_at_dawn() -> void:
	for enemy in enemies:
		var target := _nearest_unrevealed_tile(enemy["position"])
		enemy["retreating"] = true
		enemy["retreat_target"] = _vector_to_data(target)
		enemy["target_kind"] = "retreat"
		enemy["target_id"] = 0
		enemy["path"] = _find_weighted_path(enemy["position"], [target], true)
		enemy["move_elapsed"] = 0.0
		enemy["attack_flash"] = 0.0
	if not enemies.is_empty():
		_add_log("Dawn scatters the raiders back into the fog.")


func _nearest_unrevealed_tile(origin: Vector2i) -> Vector2i:
	var best := shard_position
	var best_distance := 1000000
	for y in range(map_size.y):
		for x in range(map_size.x):
			var tile := Vector2i(x, y)
			if is_revealed(tile):
				continue
			var distance := _manhattan(origin, tile)
			if distance < best_distance:
				best = tile
				best_distance = distance
	return best


func _update_retreating_enemy(enemy: Dictionary, delta: float) -> void:
	if enemy["path"].is_empty():
		var target := _vector_from_data(enemy.get("retreat_target", _vector_to_data(shard_position)), shard_position)
		enemy["path"] = _find_weighted_path(enemy["position"], [target], true)
		if enemy["path"].is_empty():
			return
	enemy["move_elapsed"] = float(enemy.get("move_elapsed", 0.0)) + delta
	var step_seconds := _enemy_step_seconds(
		enemy["position"],
		enemy["path"][0],
		float(enemy.get("speed_multiplier", 1.0))
	) * 0.72
	if float(enemy["move_elapsed"]) < step_seconds:
		return
	enemy["move_elapsed"] = 0.0
	enemy["position"] = enemy["path"].pop_front()


func _find_enemy_target(enemy: Dictionary) -> Dictionary:
	var stamp := _profile_stamp()
	var result := _find_enemy_target_unprofiled(enemy)
	_profile_finish("target_selection", stamp)
	return result


func _find_enemy_target_unprofiled(enemy: Dictionary) -> Dictionary:
	if String(enemy.get("enemy_type", ENEMY_RAIDER)) == ENEMY_SKITTERER:
		var exposed_workers: Array = []
		for worker in workers:
			if String(worker.get("state", "")) == "Sheltered" or int(worker.get("hp", WORKER_MAX_HP)) <= 0:
				continue
			if String(worker.get("type", "")) != "guard":
				exposed_workers.append(worker)
		var exposed_target := _best_enemy_target(enemy, exposed_workers, "worker", false)
		if not exposed_target.is_empty():
			return exposed_target
	# Night 1 keeps classic siege targeting so the teaching raid still
	# walks the yard and the Watchtower can fire. Variety starts Night 2:
	# economy raids peel to yards; centre raids keep the defended route.
	if day_count > 1:
		var raid_intent := String(enemy.get("raid_intent", raid_plan.get("intent", "")))
		if raid_intent == RaidIntents.INTENT_ECONOMY:
			var economy := _raid_economy_candidates()
			var economy_hit := _best_enemy_target(enemy, economy, "building", false)
			if not economy_hit.is_empty():
				return economy_hit
		elif raid_intent == RaidIntents.INTENT_PROBE:
			var exposed_probe: Array = []
			for yard in _raid_economy_candidates():
				if Frontier.is_exposed(self, yard):
					exposed_probe.append(yard)
			var probe_hit := _best_enemy_target(enemy, exposed_probe, "building", false)
			if not probe_hit.is_empty():
				return probe_hit
	var is_brute := String(enemy.get("enemy_type", ENEMY_RAIDER)) == ENEMY_BRUTE
	if is_brute:
		var structure_targets: Array = []
		for building in buildings:
			var building_type := String(building["type"])
			if building_type == Defs.BUILDING_ROAD or bool(building.get("construction", false)):
				continue
			if building_type in [Defs.BUILDING_WATCHTOWER, Defs.BUILDING_WALL, Defs.BUILDING_OUTPOST, Defs.BUILDING_BARRACKS]:
				structure_targets.append(building)
		var brute_result := _best_enemy_target(enemy, structure_targets, "building", false)
		if not brute_result.is_empty():
			return brute_result
	var towers: Array = []
	var gateways: Array = []
	var occupied_buildings: Array = []
	for building in buildings:
		var building_type := String(building["type"])
		if building_type == Defs.BUILDING_ROAD or bool(building.get("construction", false)):
			continue
		if building_type == Defs.BUILDING_TOWN_HALL:
			occupied_buildings.append(building)
		elif building_type == Defs.BUILDING_WATCHTOWER:
			if int(building.get("soldiers_assigned", 0)) > 0:
				towers.append(building)
			else:
				occupied_buildings.append(building)
		elif building_type == Defs.BUILDING_WALL and (is_brute or _wall_guards_gate(building)):
			gateways.append(building)
		elif int(building.get("assigned_staff", 0)) > 0 or building_type == Defs.BUILDING_HOUSE or int(building.get("id", 0)) == claim_outpost_id:
			occupied_buildings.append(building)

	var result := _best_enemy_target(enemy, towers, "building", false)
	if not result.is_empty():
		return result
	result = _best_enemy_target(enemy, gateways, "building", false)
	if not result.is_empty():
		return result

	var soldiers: Array = []
	var settlers: Array = []
	for worker in workers:
		if String(worker.get("state", "")) == "Sheltered" or int(worker.get("hp", WORKER_MAX_HP)) <= 0:
			continue
		if String(worker.get("type", "")) == "guard":
			soldiers.append(worker)
		else:
			settlers.append(worker)
	# Director: raiders siege stock and yards first. Fighting soldiers first
	# melted the defence and never touched storage. Skitterers still hunt
	# workers (handled above); raiders loot, then fight whoever is left.
	var loot_buildings: Array = []
	for building in buildings:
		var loot_type := String(building["type"])
		if bool(building.get("construction", false)):
			continue
		if loot_type in RaidTuning.LOOT_BUILDING_TYPES or loot_type in RaidTuning.STORAGE_BUILDING_TYPES:
			if loot_type != Defs.BUILDING_TOWN_HALL:
				loot_buildings.append(building)
	result = _best_enemy_target(enemy, loot_buildings, "building", false)
	if not result.is_empty():
		return result
	result = _best_enemy_target(enemy, soldiers, "worker", true)
	if not result.is_empty():
		return result
	result = _best_enemy_target(enemy, settlers, "worker", false)
	if not result.is_empty():
		return result
	result = _best_enemy_target(enemy, occupied_buildings, "building", false)
	if not result.is_empty():
		return result
	var town_hall := _find_town_hall()
	return {} if town_hall.is_empty() else {"kind": "building", "entity": town_hall}


func _best_enemy_target(enemy: Dictionary, candidates: Array, kind: String, require_reachable: bool) -> Dictionary:
	var ranked: Array[Dictionary] = []
	var order := 0
	for candidate in candidates:
		var target_position := _enemy_target_position(enemy["position"], candidate, kind)
		var load := _enemy_target_load(kind, int(candidate.get("id", 0)))
		if load >= 3:
			order += 1
			continue
		var score := _manhattan(enemy["position"], target_position) + load * 10
		if kind == "building" and String(enemy.get("raid_intent", raid_plan.get("intent", ""))) == RaidIntents.INTENT_ECONOMY:
			score -= int(round(Frontier.exposure_score(self, candidate) * 20.0))
		ranked.append({"entity": candidate, "position": target_position, "score": score, "order": order})
		order += 1
	ranked.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		if int(first["score"]) == int(second["score"]):
			return int(first["order"]) < int(second["order"])
		return int(first["score"]) < int(second["score"])
	)
	for entry in ranked:
		if require_reachable \
			and _manhattan(enemy["position"], entry["position"]) > 1 \
			and _find_enemy_path(enemy["position"], entry["position"]).is_empty():
			continue
		return {"kind": kind, "entity": entry["entity"]}
	return {}


func _enemy_target_load(kind: String, target_id: int) -> int:
	var load := 0
	for other in enemies:
		if String(other.get("target_kind", "")) == kind and int(other.get("target_id", 0)) == target_id:
			load += 1
	return load


func _wall_guards_gate(wall: Dictionary) -> bool:
	var position: Vector2i = wall["position"]
	for neighbor in _neighbors(position):
		if _is_gate_tile(neighbor):
			return true
	return false


func _enemy_target_position(origin: Vector2i, target: Dictionary, target_kind: String) -> Vector2i:
	if target_kind == "worker":
		return target["position"]
	var best: Vector2i = target["position"]
	var best_distance := 1000000
	for tile in get_building_footprint_tiles(target):
		var distance := _manhattan(origin, tile)
		if distance < best_distance:
			best = tile
			best_distance = distance
	return best


func _find_exposed_worker_target(origin: Vector2i) -> Dictionary:
	var best := {}
	var best_distance := 1000000
	for worker in workers:
		if String(worker.get("state", "")) == "Sheltered" or int(worker.get("hp", WORKER_MAX_HP)) <= 0:
			continue
		var distance := _manhattan(origin, worker["position"])
		if distance < best_distance:
			best = worker
			best_distance = distance
	return best


func _damage_worker(worker_id: int, amount: int, attacker_position: Vector2i = Vector2i(-1, -1)) -> void:
	for index in range(workers.size()):
		var worker: Dictionary = workers[index]
		if int(worker.get("id", 0)) != worker_id:
			continue
		worker["hp"] = int(worker.get("hp", WORKER_MAX_HP)) - amount
		worker["hit_until"] = elapsed_seconds + 0.26
		worker["hit_direction"] = _vector_to_data(attacker_position)
		_record_event("worker_attacked", "An exposed worker was attacked.", {
			"worker_id": worker_id,
			"worker_type": String(worker.get("type", "settler")),
			"damage": amount,
			"hp": int(worker["hp"])
		})
		_combat_log_hit("raiders", _worker_log_name(worker), amount, "unit")
		if int(worker["hp"]) > 0:
			last_message = "%s is under attack." % String(worker.get("type", "Settler")).capitalize()
			return
		var worker_type := String(worker.get("type", "settler"))
		if worker.has("scout_mission"):
			_mark_scout_lost(worker)
		if worker_type == "carrier":
			_release_worker_claim(worker)
		elif worker_type == "guard":
			soldiers_total = maxi(0, soldiers_total - 1)
			var tower := _find_building_by_id(int(worker.get("building_id", 0)))
			if not tower.is_empty():
				tower["soldiers_assigned"] = maxi(0, int(tower.get("soldiers_assigned", 0)) - 1)
				tower["staffed"] = false
				tower["status"] = "Soldier lost in the night."
			population_current = max(0, population_current - 1)
			_emit_audio("soldier_death")
		else:
			var building := _find_building_by_id(int(worker.get("building_id", 0)))
			if not building.is_empty():
				building["assigned_staff"] = max(0, int(building.get("assigned_staff", 0)) - 1)
				building["staffed"] = false
				building["status"] = "Worker lost in the night."
			population_current = max(0, population_current - 1)
			hungry_population = mini(hungry_population, population_current)
		workers.remove_at(index)
		stats["workers_lost"] = int(stats.get("workers_lost", 0)) + 1
		_recalculate_workers_assigned()
		_refresh_worker_hunger_flags()
		_add_log("A %s was lost outside shelter." % worker_type)
		_record_event("worker_lost", "An exposed worker was lost.", {"worker_id": worker_id, "worker_type": worker_type})
		night_casualties += 1
		_note_raid_our_loss(worker_type)
		_check_population_defeat()
		return


func _damage_building(building: Dictionary, amount: int) -> void:
	building["hp"] = int(building["hp"]) - amount
	building["damage_flash"] = 0.45
	last_message = "%s is under attack." % _display_building_name(building)
	_record_event("building_attacked", last_message, {
		"building_id": int(building["id"]),
		"building_type": String(building["type"]),
		"damage": amount,
		"hp": int(building["hp"])
	})
	_combat_log_hit("raiders", _display_building_name(building), amount, "building")
	_note_raid_building_hit(building)
	if String(building.get("type", "")) in RaidTuning.STORAGE_BUILDING_TYPES:
		_raid_steal_stock(raid_steal_per_hit if raid_steal_per_hit > 0 else RaidTuning.steal_for_night(day_count, day_count <= 1))
	if int(building["hp"]) > 0:
		if is_night:
			night_buildings_damaged += 1
		return
	_note_raid_building_destroyed(building)
	_destroy_building_by_id(int(building["id"]), "destroyed", true)


func _destroy_building_by_id(building_id: int, reason: String, count_stats: bool) -> void:
	var index := -1
	var destroyed := {}
	for i in range(buildings.size()):
		if int(buildings[i]["id"]) == building_id:
			index = i
			destroyed = buildings[i]
			break
	if index < 0:
		return

	var building_type := String(destroyed["type"])
	_cancel_building_logistics(destroyed)
	var housing_lost := 0
	if not bool(destroyed.get("construction", false)):
		housing_lost = Defs.adds_population(building_type)
	buildings.remove_at(index)
	if housing_lost > 0:
		housing_capacity = max(STARTING_HOUSING_CAPACITY, housing_capacity - housing_lost)
		population_current = min(population_current, housing_capacity)
		_enforce_worker_limit()
	else:
		_recalculate_workers_assigned()
	if count_stats:
		stats["buildings_destroyed"] = int(stats.get("buildings_destroyed", 0)) + 1
		_emit_audio("destroyed")
	_add_log("%s %s." % [_display_building_name(destroyed), reason])

	if building_type == Defs.BUILDING_TOWN_HALL:
		_finish_run(false, "The Town Hall fell.")
	if building_id == claim_outpost_id:
		_cancel_claim("Shard claim cancelled: the Outpost fell.")

	_rebuild_occupied_tiles()
	_recompute_road_network()
	_reveal_from_world()
	_sync_production_workers()
	for worker in workers:
		if not _is_walkable_road(worker["position"]):
			var spawn := _first_connected_road_tile()
			if is_inside_map(spawn):
				worker["position"] = spawn
				_clear_worker(worker)


func _cancel_building_logistics(building: Dictionary) -> void:
	var building_id := int(building.get("id", 0))
	for worker in workers:
		if String(worker.get("type", "")) != "carrier":
			continue
		var task: Dictionary = worker.get("task", {})
		var source = task.get("source", 0)
		var destination = task.get("destination", 0)
		var matches_source := typeof(source) in [TYPE_INT, TYPE_FLOAT] and int(source) == building_id
		var matches_destination := typeof(destination) in [TYPE_INT, TYPE_FLOAT] and int(destination) == building_id
		if not matches_source and not matches_destination:
			continue
		var carried_resource := String(worker.get("carried_resource", ""))
		var carried_amount := int(worker.get("carried_amount", 0))
		if carried_resource != "" and carried_amount > 0:
			central_inventory[carried_resource] = int(central_inventory.get(carried_resource, 0)) + carried_amount
		_clear_worker(worker, false)

	if bool(building.get("construction", false)):
		var needed: Dictionary = building.get("materials_needed", {})
		var delivered: Dictionary = building.get("materials_delivered", {})
		for resource_type in needed.keys():
			var delivered_amount := int(delivered.get(resource_type, 0))
			var outstanding: int = maxi(0, int(needed.get(resource_type, 0)) - delivered_amount)
			_release_reserved_resource(String(resource_type), outstanding)
			if delivered_amount > 0:
				central_inventory[resource_type] = int(central_inventory.get(resource_type, 0)) + delivered_amount
	else:
		var local_inventory: Dictionary = building.get("local_inventory", {})
		for resource_type in Defs.RESOURCE_TYPES:
			var stored := int(local_inventory.get(resource_type, 0))
			if stored <= 0:
				continue
			# Director: a raid that razes a building destroys the stock inside.
			# Daytime teardown still returns cargo to the hall.
			if raid_active:
				_record_raid_resource_loss(String(resource_type), stored)
			else:
				central_inventory[resource_type] = int(central_inventory.get(resource_type, 0)) + stored


func _update_towers(delta: float) -> void:
	for tower in buildings:
		if String(tower["type"]) != Defs.BUILDING_WATCHTOWER:
			continue
		if not _building_can_work(tower):
			continue
		tower["attack_cooldown"] = max(0.0, float(tower.get("attack_cooldown", 0.0)) - delta)
		if float(tower["attack_cooldown"]) > 0.0:
			continue
		var tower_center := _footprint_center(tower["position"], _building_footprint(tower))
		var enemy := _find_enemy_in_range(tower_center, TOWER_RANGE)
		if enemy.is_empty():
			tower["status"] = "Watching."
			tower["combat_target_id"] = 0
			continue
		tower["attack_cooldown"] = TOWER_COOLDOWN_SECONDS
		tower["status"] = "Firing."
		tower["combat_target_id"] = int(enemy["id"])
		tower["combat_target_position"] = _vector_to_data(enemy["position"])
		projectiles.append({
			"from": _vector_to_data(tower_center),
			"to": _vector_to_data(enemy["position"]),
			"life": 0.65,
			"total": 0.65,
			"target_enemy_id": int(enemy["id"]),
			"damage": TOWER_DAMAGE,
			"damage_applied": false
		})
		_record_event("tower_attack", "Watchtower fired.", {
			"tower_id": int(tower["id"]),
			"enemy_id": int(enemy["id"]),
			"damage": TOWER_DAMAGE,
			"enemy_hp_before_impact": int(enemy["hp"]),
			"distance": _tile_distance(tower_center, enemy["position"])
		})
		_note_combat()
		_emit_audio("tower")


func _find_enemy_in_range(origin: Vector2i, radius: int) -> Dictionary:
	var stamp := _profile_stamp()
	var best := {}
	var best_distance := 1000000.0
	for enemy in enemies:
		if not is_revealed(enemy["position"]):
			continue
		var distance := _tile_distance(origin, enemy["position"])
		if distance <= radius and distance < best_distance and int(enemy["hp"]) > 0:
			best = enemy
			best_distance = distance
	_profile_scan("combat_enemy_scan", enemies.size())
	_profile_finish("target_selection", stamp)
	return best


func _update_patrol_combat(delta: float) -> void:
	for guard in workers:
		if String(guard.get("type", "")) != "guard" or int(guard.get("building_id", 0)) != 0:
			continue
		guard["attack_timer"] = maxf(0.0, float(guard.get("attack_timer", 0.0)) - delta)
		var attack_remaining := float(guard.get("attack_flash", 0.0))
		if attack_remaining > 0.0:
			attack_remaining = maxf(0.0, attack_remaining - delta)
			guard["attack_flash"] = attack_remaining
			if not bool(guard.get("attack_damage_applied", true)) and attack_remaining <= GUARD_ATTACK_STRIKE_REMAINING:
				guard["attack_damage_applied"] = true
				var target_outpost := _assault_outpost(int(guard.get("combat_target_structure_id", 0)))
				if not target_outpost.is_empty() and _outpost_distance(guard.position, target_outpost) <= 1:
					rivalry._damage_structure(int(target_outpost.id), GUARD_DAMAGE, RivalryTuning.PLAYER_REALM)
					_emit_audio("attack")
					_record_event("outpost_assault_hit", "A soldier struck the rival Outpost.", {"soldier_id": guard.id, "structure_id": target_outpost.id, "damage": GUARD_DAMAGE})
				var target_enemy := _find_enemy_by_id(int(guard.get("combat_target_id", 0)))
				if not target_enemy.is_empty() and _manhattan(guard["position"], target_enemy["position"]) <= PATROL_MELEE_RADIUS:
					var dealt := _apply_enemy_incoming_damage(target_enemy, GUARD_DAMAGE)
					target_enemy["hit_until"] = elapsed_seconds + 0.26
					target_enemy["hit_direction"] = _vector_to_data(guard["position"])
					_note_combat()
					_credit_player_kill(target_enemy, "soldier", int(guard.get("id", 0)))
					_emit_audio("attack")
					_combat_log_hit("soldiers", Wyrdfall.enemy_role_name(String(target_enemy.get("enemy_type", ENEMY_RAIDER))), dealt, "enemy")
					_record_event("patrol_attack", "A patrol soldier engaged a raider.", {
						"soldier_id": int(guard.get("id", 0)),
						"enemy_id": int(target_enemy.get("id", 0)),
						"damage": dealt
					})
			continue
		if float(guard["attack_timer"]) > 0.0:
			continue
		var enemy := _find_enemy_for_guard(guard, PATROL_MELEE_RADIUS)
		if enemy.is_empty():
			var outpost := _assault_outpost(int(guard.get("assault_target_id", 0)))
			if not outpost.is_empty() and _outpost_distance(guard.position, outpost) <= 1:
				guard["attack_timer"] = 1.55
				guard["attack_flash"] = GUARD_ATTACK_ANIMATION_SECONDS
				guard["attack_damage_applied"] = false
				guard["combat_target_id"] = 0
				guard["combat_target_structure_id"] = int(outpost.id)
				guard["combat_target_position"] = _vector_to_data(outpost.position)
				guard["state"] = "Fighting"
				continue
			if String(guard.get("state", "")) == "Fighting" and _find_patrol_threat(guard).is_empty():
				guard["state"] = "Night Watch" if is_night else "Patrolling"
			continue
		guard["attack_timer"] = 1.55
		guard["attack_flash"] = GUARD_ATTACK_ANIMATION_SECONDS
		guard["attack_damage_applied"] = false
		guard["combat_target_id"] = int(enemy.get("id", 0))
		guard["combat_target_structure_id"] = 0
		guard["combat_target_position"] = _vector_to_data(enemy["position"])
		guard["state"] = "Fighting"


func _find_enemy_by_id(enemy_id: int) -> Dictionary:
	for enemy in enemies:
		if int(enemy.get("id", 0)) == enemy_id and int(enemy.get("hp", 0)) > 0:
			return enemy
	return {}


func _enemy_is_observable(tile: Vector2i) -> bool:
	if is_revealed(tile):
		return true
	for y in range(-1, 2):
		for x in range(-1, 2):
			if x == 0 and y == 0:
				continue
			if is_revealed(tile + Vector2i(x, y)):
				return true
	return false


func _find_enemy_for_guard(guard: Dictionary, radius: int) -> Dictionary:
	var best := {}
	var best_score := INF
	for enemy in enemies:
		if int(enemy.get("hp", 0)) <= 0 or not _enemy_is_observable(enemy.get("position", Vector2i.ZERO)):
			continue
		var distance := _tile_distance(guard.get("position", Vector2i.ZERO), enemy.get("position", Vector2i.ZERO))
		if distance > radius:
			continue
		var committed := 0
		for other_guard in workers:
			if int(other_guard.get("id", 0)) != int(guard.get("id", 0)) \
				and int(other_guard.get("combat_target_id", 0)) == int(enemy.get("id", 0)) \
				and (float(other_guard.get("attack_flash", 0.0)) > 0.0 or String(other_guard.get("state", "")) == "Fighting"):
				committed += 1
		if committed >= 2:
			continue
		var score := distance + float(committed) * 3.0
		if score < best_score:
			best_score = score
			best = enemy
	return best


func _update_projectiles(delta: float) -> void:
	for i in range(projectiles.size() - 1, -1, -1):
		projectiles[i]["life"] = float(projectiles[i].get("life", 0.0)) - delta
		if float(projectiles[i]["life"]) <= 0.0:
			if not bool(projectiles[i].get("damage_applied", true)):
				var target := _find_enemy_by_id(int(projectiles[i].get("target_enemy_id", 0)))
				if not target.is_empty():
					var bolt := int(projectiles[i].get("damage", 0))
					var dealt := _apply_enemy_incoming_damage(target, bolt)
					target["hit_until"] = elapsed_seconds + 0.26
					target["hit_direction"] = projectiles[i].get("from", _vector_to_data(Vector2i.ZERO))
					_note_combat()
					_credit_player_kill(target, "tower", 0)
					_combat_log_hit("watchtower", Wyrdfall.enemy_role_name(String(target.get("enemy_type", ENEMY_RAIDER))), dealt, "enemy")
				projectiles[i]["damage_applied"] = true
			projectiles.remove_at(i)


func _start_claim(outpost: Dictionary) -> void:
	shard_contacted = true
	_offer_onboarding("shard", "Reach, secure, then Bind the Shard. The Wyrd will react violently.")
	if rivalry != null:
		_update_objective_flag("outpost")
		last_message = "The Shard is within reach. Secure it, then Bind it."
		return
	claim_active = true
	claim_outpost_id = int(outpost["id"])
	claim_nights_survived = 0
	stats["shard_claimed"] = false
	_add_log("Shard claim started. Hold the Outpost through two nights.")
	last_message = "Shard claim started: survive 0/2 nights."
	_update_objective_flag("outpost")


func _cancel_claim(message: String) -> void:
	if not claim_active:
		return
	claim_active = false
	claim_outpost_id = 0
	claim_nights_survived = 0
	_add_log(message)
	last_message = message


func _finish_run(won: bool, reason: String) -> void:
	if game_finished:
		return
	game_finished = true
	victory = won
	defeat_reason = reason
	if rivalry != null and rivalry.match_state not in [
		RivalryTuning.MATCH_PLAYER_VICTORY,
		RivalryTuning.MATCH_AI_VICTORY
	]:
		rivalry.match_state = RivalryTuning.MATCH_PLAYER_VICTORY if won else RivalryTuning.MATCH_PLAYER_DEFEAT
	if won:
		stats["shard_claimed"] = true
		_update_objective_flag("outpost")
		_update_objective_flag("claim")
		_add_log("SHARD BOUND. The realm is secured.")
	else:
		_add_log("The Realm Has Fallen.")
	last_message = reason
	var score := get_score()
	if score > best_score:
		best_score = score
		_save_best_score(score)
	_record_event("run_finished", reason, {"victory": won, "score": score, "summary": get_summary()})
	_write_last_run_snapshot()


func _update_objectives() -> void:
	if _count_connected_roads() > 1:
		_update_objective_flag("road")
		_offer_onboarding("road", "ROADS CONNECT BUILDINGS. Extend roads from the Town Hall, then place buildings beside them. Roads are free but need worker construction.")
	for building in buildings:
		if String(building["type"]) == Defs.BUILDING_HOUSE and not bool(building.get("construction", false)):
			_update_objective_flag("house")
		if String(building["type"]) == Defs.BUILDING_LUMBER_CAMP and not bool(building.get("construction", false)):
			_update_objective_flag("lumber")
			_offer_onboarding("production", "Workers harvest, carriers haul. Production needs access and storage.")
		if String(building["type"]) == Defs.BUILDING_FARM and not bool(building.get("construction", false)):
			_update_objective_flag("farm")
			_offer_onboarding("food", "FOOD SUSTAINS SETTLERS. Farms produce Wheat. Bakeries turn Wheat into Bread. Without Bread, population starves and output falls.")
		if String(building["type"]) == Defs.BUILDING_STOREHOUSE and not bool(building.get("construction", false)):
			_update_objective_flag("storehouse")
			_offer_onboarding("storage", "BUILD STALLS when storage fills. Workers stop delivering when the Town Hall and production sites reach capacity.")
		if String(building["type"]) == Defs.BUILDING_WATCHTOWER and not bool(building.get("construction", false)):
			_update_objective_flag("watchtower")
		if String(building["type"]) == Defs.BUILDING_OUTPOST and not bool(building.get("construction", false)) and _footprint_touches_tile(building["position"], _building_footprint(building), shard_position):
			_update_objective_flag("outpost")
	if rivalry != null:
		if rivalry.get_resource(RivalryTuning.PLAYER_REALM, Defs.RESOURCE_WYRD) > 0:
			_update_objective_flag("wyrd")
		for structure in rivalry.get_structures(RivalryTuning.PLAYER_REALM):
			if String(structure.get("type", "")) == RivalryTuning.STRUCTURE_LUMEN_PILLAR:
				_update_objective_flag("lumen")
			elif String(structure.get("type", "")) == RivalryTuning.STRUCTURE_CLAIMANT_OUTPOST:
				_update_objective_flag("outpost")
				_offer_onboarding("outpost", "Outposts extend Lumen and can harvest Wyrd. They also raise Pressure.")
		if rivalry.match_state == RivalryTuning.MATCH_PLAYER_VICTORY:
			_update_objective_flag("claim")
	if _starter_economy_ready():
		var has_outpost := false
		for building in buildings:
			if String(building.get("type", "")) == Defs.BUILDING_OUTPOST and not bool(building.get("construction", false)):
				has_outpost = true
		if rivalry != null:
			for structure in rivalry.get_structures(RivalryTuning.PLAYER_REALM):
				if String(structure.get("type", "")) == RivalryTuning.STRUCTURE_CLAIMANT_OUTPOST:
					has_outpost = true
		if not has_outpost:
			_offer_onboarding("outpost_expand", "OUTPOSTS EXTEND YOUR REALM. Connect one by road and Lumen to push toward the Shard.")


func _update_objective_flag(objective_id: String) -> void:
	for objective in objectives:
		if String(objective["id"]) == objective_id and not bool(objective["complete"]):
			objective["complete"] = true
			_add_log("Objective complete: %s." % String(objective["text"]))


func _add_log(message: String) -> void:
	log_entries.append("%s | %s" % [get_time_label(), message])
	while log_entries.size() > 60:
		log_entries.pop_front()
	_record_event("realm_log", message)


func _apply_enemy_incoming_damage(enemy: Dictionary, raw_damage: int) -> int:
	var dealt := RaidTuning.apply_armor(raw_damage, int(enemy.get("armor", 0)))
	enemy["hp"] = int(enemy.get("hp", 0)) - dealt
	if int(enemy["hp"]) <= 0:
		_note_raid_enemy_killed(enemy)
	return dealt


func _begin_raid(steal_per_hit: int) -> void:
	if raid_active:
		raid_steal_per_hit = steal_per_hit
		return
	raid_active = true
	raid_started_elapsed = elapsed_seconds
	raid_steal_per_hit = steal_per_hit
	raid_enemies_killed = 0
	raid_our_losses = 0
	raid_buildings_damaged_ids.clear()
	raid_buildings_destroyed.clear()
	raid_resources_lost.clear()
	raid_last_summary.clear()
	_combat_log_buckets.clear()


func _reset_raid_bookkeeping() -> void:
	raid_active = false
	raid_started_elapsed = 0.0
	raid_steal_per_hit = 0
	raid_enemies_killed = 0
	raid_our_losses = 0
	raid_buildings_damaged_ids.clear()
	raid_buildings_destroyed.clear()
	raid_resources_lost.clear()
	raid_last_summary.clear()
	_combat_log_buckets.clear()


func _maybe_finish_raid() -> void:
	if not raid_active:
		return
	if living_hostile_count() > 0:
		return
	_finish_raid("cleared")


func _finish_raid(reason: String) -> void:
	if not raid_active:
		return
	_flush_combat_log(true)
	var duration := maxf(0.0, elapsed_seconds - raid_started_elapsed)
	var lost_bits: Array[String] = []
	for resource_type in RaidTuning.STEAL_RESOURCE_ORDER:
		var taken := int(raid_resources_lost.get(resource_type, 0))
		if taken > 0:
			lost_bits.append("%d %s" % [taken, Defs.resource_name(resource_type)])
	var resources_line := ", ".join(lost_bits) if not lost_bits.is_empty() else "none"
	var destroyed_line := ", ".join(raid_buildings_destroyed) if not raid_buildings_destroyed.is_empty() else "none"
	var body := "RAID OVER — %ds, %d enemies killed, %d lost, %d buildings damaged, %d destroyed (%s), resources lost: %s." % [
		int(round(duration)),
		raid_enemies_killed,
		raid_our_losses,
		raid_buildings_damaged_ids.size(),
		raid_buildings_destroyed.size(),
		destroyed_line,
		resources_line
	]
	if reason == "dawn":
		body = "RAID OVER at dawn — %ds, %d enemies killed, %d lost, %d buildings damaged, %d destroyed (%s), resources lost: %s." % [
			int(round(duration)),
			raid_enemies_killed,
			raid_our_losses,
			raid_buildings_damaged_ids.size(),
			raid_buildings_destroyed.size(),
			destroyed_line,
			resources_line
		]
	raid_last_summary = {
		"reason": reason,
		"duration": snappedf(duration, 0.1),
		"enemies_killed": raid_enemies_killed,
		"our_losses": raid_our_losses,
		"buildings_damaged": raid_buildings_damaged_ids.size(),
		"buildings_destroyed": raid_buildings_destroyed.duplicate(),
		"resources_lost": raid_resources_lost.duplicate(true),
		"body": body
	}
	push_notice("danger", "RAID OVER", body, "warning")
	_add_log(body)
	_record_event("raid_summary", body, raid_last_summary.duplicate(true))
	raid_active = false


func _combat_log_hit(side: String, target_name: String, damage: int, kind: String) -> void:
	if damage <= 0:
		return
	_begin_raid(raid_steal_per_hit if raid_steal_per_hit > 0 else RaidTuning.steal_for_night(day_count, day_count <= 1))
	var key := "%s|%s|%s" % [side, kind, target_name]
	var bucket: Dictionary = _combat_log_buckets.get(key, {})
	if bucket.is_empty():
		bucket = {
			"side": side,
			"kind": kind,
			"target": target_name,
			"damage": damage,
			"hits": 1,
			"started": elapsed_seconds
		}
	else:
		bucket["damage"] = int(bucket.get("damage", 0)) + damage
		bucket["hits"] = int(bucket.get("hits", 0)) + 1
	_combat_log_buckets[key] = bucket
	_flush_combat_log(false)


func _flush_combat_log(force: bool) -> void:
	var done: Array[String] = []
	for key in _combat_log_buckets.keys():
		var bucket: Dictionary = _combat_log_buckets[key]
		if not force and elapsed_seconds - float(bucket.get("started", 0.0)) < RaidTuning.COMBAT_LOG_WINDOW_SECONDS:
			continue
		var side := String(bucket.get("side", "raiders"))
		var target := String(bucket.get("target", "the camp"))
		var damage := int(bucket.get("damage", 0))
		var kind := String(bucket.get("kind", "building"))
		var body := ""
		if side == "raiders" and kind == "building":
			body = "Raiders hit %s (-%d HP)" % [target, damage]
		elif side == "raiders":
			body = "Raiders hit %s (-%d HP)" % [target, damage]
		elif side == "watchtower":
			body = "Watchtower hit a %s (-%d HP)" % [target, damage]
		else:
			body = "Soldiers hit a %s (-%d HP)" % [target, damage]
		push_notice("danger", "COMBAT", body, "warning")
		_record_event("combat_log", body, bucket.duplicate(true))
		done.append(String(key))
	for key in done:
		_combat_log_buckets.erase(key)


func _note_raid_enemy_killed(enemy: Dictionary) -> void:
	if bool(enemy.get("raid_kill_noted", false)):
		return
	enemy["raid_kill_noted"] = true
	if raid_active or is_night:
		_begin_raid(raid_steal_per_hit if raid_steal_per_hit > 0 else RaidTuning.steal_for_night(day_count, day_count <= 1))
		raid_enemies_killed += 1
	var role := Wyrdfall.enemy_role_name(String(enemy.get("enemy_type", ENEMY_RAIDER)))
	push_notice("danger", "COMBAT", "A %s was slain." % role, "info")
	_record_event("raid_enemy_killed", "A %s was slain." % role, {"enemy_id": int(enemy.get("id", 0))})


func _note_raid_our_loss(worker_type: String) -> void:
	if raid_active or is_night:
		_begin_raid(raid_steal_per_hit if raid_steal_per_hit > 0 else RaidTuning.steal_for_night(day_count, day_count <= 1))
		raid_our_losses += 1
	var label := "soldier" if worker_type == "guard" else worker_type
	push_notice("danger", "COMBAT", "A %s was lost." % label, "critical")


func _note_raid_building_hit(building: Dictionary) -> void:
	if not raid_active and not is_night:
		return
	raid_buildings_damaged_ids[int(building.get("id", 0))] = _display_building_name(building)


func _note_raid_building_destroyed(building: Dictionary) -> void:
	var name := _display_building_name(building)
	_note_raid_building_hit(building)
	raid_buildings_destroyed.append(name)
	push_notice("danger", "COMBAT", "%s was destroyed." % name, "critical")


func _raid_steal_stock(amount: int) -> void:
	if amount <= 0:
		return
	var remaining := amount
	for resource_type in RaidTuning.STEAL_RESOURCE_ORDER:
		if remaining <= 0:
			break
		var available := get_available_resource(resource_type)
		if available <= 0:
			continue
		var taken: int = mini(remaining, available)
		central_inventory[resource_type] = int(central_inventory.get(resource_type, 0)) - taken
		_record_raid_resource_loss(resource_type, taken)
		remaining -= taken


func _record_raid_resource_loss(resource_type: String, amount: int) -> void:
	if amount <= 0:
		return
	raid_resources_lost[resource_type] = int(raid_resources_lost.get(resource_type, 0)) + amount


func _worker_log_name(worker: Dictionary) -> String:
	var worker_type := String(worker.get("type", "settler"))
	if worker_type == "guard":
		return "a Soldier"
	return "a %s" % worker_type.capitalize()


func get_raid_summary() -> Dictionary:
	return raid_last_summary.duplicate(true)


func _update_diagnostic_snapshot(delta: float) -> void:
	if not diagnostics_enabled:
		return
	diagnostic_snapshot_elapsed += delta
	if diagnostic_snapshot_elapsed < 10.0:
		return
	diagnostic_snapshot_elapsed = 0.0
	var worker_states := {}
	var exposed_workers := 0
	for worker in workers:
		var state := String(worker.get("state", "Unknown"))
		worker_states[state] = int(worker_states.get(state, 0)) + 1
		if state != "Sheltered":
			exposed_workers += 1
	var building_states := []
	for building in buildings:
		if String(building.get("type", "")) == Defs.BUILDING_ROAD:
			continue
		building_states.append({
			"id": int(building["id"]),
			"type": String(building["type"]),
			"position": _vector_to_data(building["position"]),
			"staff": int(building.get("assigned_staff", 0)),
			"status": String(building.get("status", "")),
			"hp": int(building.get("hp", 0)),
			"inventory": building.get("local_inventory", {}).duplicate(true)
		})
	var enemy_states := []
	for enemy in enemies:
		enemy_states.append({
			"id": int(enemy["id"]),
			"position": _vector_to_data(enemy["position"]),
			"hp": int(enemy["hp"]),
			"target_kind": String(enemy.get("target_kind", "")),
			"target_id": int(enemy.get("target_id", 0))
		})
	_record_event("state_snapshot", "Periodic simulation snapshot.", {
		"worker_states": worker_states,
		"exposed_workers": exposed_workers,
		"hungry_population": hungry_population,
		"hunger_penalty_remaining": snappedf(hunger_penalty_remaining, 0.1),
		"buildings": building_states,
		"enemies": enemy_states
	})


func _record_event(event_type: String, message: String, details: Dictionary = {}) -> void:
	var event := {
		"event": event_type,
		"message": message,
		"tick": tick_number,
		"elapsed_seconds": snappedf(elapsed_seconds, 0.1),
		"day": day_count,
		"night": is_night,
		"resources": central_inventory.duplicate(true),
		"reserved": reserved_inventory.duplicate(true),
		"population": population_current,
		"housing": housing_capacity,
		"workers_assigned": workers_assigned,
		"details": details.duplicate(true)
	}
	run_journal.append(event)
	while run_journal.size() > 1000:
		run_journal.pop_front()
	_mirror_playtest_event(event_type, message)
	if not diagnostics_enabled:
		return
	_pending_diagnostic_lines.append(JSON.stringify(event))


func _mirror_playtest_event(event_type: String, message: String) -> void:
	match event_type:
		"construction_started":
			playtest_log.note_command(self, "build_placed", message)
		"raid_started", "raid_wave":
			playtest_log.note(self, "raid_started", message)
		"building_attacked":
			playtest_log.note(self, "building_damaged", message)
		"discovery", "intention_complete":
			playtest_log.note(self, event_type, message)
		"scout_order":
			playtest_log.note_command(self, "scout_order", message)


func _flush_diagnostic_events() -> void:
	if not diagnostics_enabled or _pending_diagnostic_lines.is_empty():
		return
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(RUN_JOURNAL_PATH) else FileAccess.WRITE
	var file := FileAccess.open(RUN_JOURNAL_PATH, mode)
	if file == null:
		return
	file.seek_end()
	for line in _pending_diagnostic_lines:
		file.store_line(line)
	file.close()
	_pending_diagnostic_lines.clear()


func _write_last_run_snapshot() -> void:
	if not diagnostics_enabled:
		return
	_flush_diagnostic_events()
	var file := FileAccess.open(LAST_RUN_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"version": 1,
		"summary": get_summary(),
		"journal": run_journal,
		"state": _serialize_state()
	}, "  "))


func _find_road_path(start: Vector2i, goals: Array) -> Array:
	var stamp := _profile_stamp()
	var result := _find_road_path_unprofiled(start, goals)
	_profile_finish("road_path_requests", stamp)
	return result


func _find_road_path_unprofiled(start: Vector2i, goals: Array) -> Array:
	path_query_count += 1
	if goals.is_empty():
		return []
	for goal in goals:
		if start == goal:
			return []

	var frontier: Array = [start]
	var came_from := {}
	var seen := {}
	seen[_tile_key(start)] = true
	var goal_lookup := {}
	for goal in goals:
		goal_lookup[_tile_key(goal)] = true

	var index := 0
	while index < frontier.size():
		var current: Vector2i = frontier[index]
		index += 1
		for neighbor in _neighbors(current):
			var key := _tile_key(neighbor)
			if seen.has(key):
				continue
			if not _is_walkable_road(neighbor):
				continue
			seen[key] = true
			came_from[key] = current
			if goal_lookup.has(key):
				return _reconstruct_path(start, neighbor, came_from)
			frontier.append(neighbor)
	return []


func _find_enemy_path(start: Vector2i, target: Vector2i) -> Array:
	var goals := []
	for neighbor in _neighbors(target):
		if is_inside_map(neighbor) and _is_enemy_walkable(neighbor):
			goals.append(neighbor)
	return _find_weighted_path(start, goals, true)


func _find_weighted_path(start: Vector2i, goals: Array, for_enemy: bool) -> Array:
	var stamp := _profile_stamp()
	var result := _find_weighted_path_unprofiled(start, goals, for_enemy)
	_profile_finish("astar_path_generation", stamp)
	return result


func _find_weighted_path_unprofiled(start: Vector2i, goals: Array, for_enemy: bool) -> Array:
	path_query_count += 1
	if goals.is_empty() or not is_inside_map(start):
		return []
	_ensure_path_grid()
	var active_grid: AStarGrid2D = hostile_path_grid if for_enemy else path_grid
	var start_was_solid := active_grid.is_point_solid(start)
	active_grid.set_point_solid(start, false)
	var best_path: Array = []
	var best_cost := INF
	for goal_value in goals:
		var goal: Vector2i = goal_value
		if not is_inside_map(goal):
			continue
		if start == goal:
			active_grid.set_point_solid(start, start_was_solid)
			return []
		var goal_was_solid := active_grid.is_point_solid(goal)
		active_grid.set_point_solid(goal, false)
		var raw_path = active_grid.get_id_path(start, goal)
		active_grid.set_point_solid(goal, goal_was_solid)
		if raw_path.size() <= 1:
			continue
		var candidate: Array = []
		var candidate_cost := 0.0
		for index in range(1, raw_path.size()):
			var point := Vector2i(int(raw_path[index].x), int(raw_path[index].y))
			candidate.append(point)
			candidate_cost += ROAD_MOVE_MULTIPLIER if _is_road_tile(point) else 1.0
		if candidate_cost < best_cost:
			best_cost = candidate_cost
			best_path = candidate
	active_grid.set_point_solid(start, start_was_solid)
	return best_path


func _ensure_path_grid() -> void:
	if path_grid != null and hostile_path_grid != null and not path_grid_dirty:
		return
	var stamp := _profile_stamp()
	_ensure_path_grid_unprofiled()
	_profile_finish("path_cache_rebuilds", stamp)


func _ensure_path_grid_unprofiled() -> void:
	if path_grid != null and hostile_path_grid != null and not path_grid_dirty:
		return
	path_grid_rebuild_count += 1
	path_grid = AStarGrid2D.new()
	path_grid.region = Rect2i(Vector2i.ZERO, map_size)
	path_grid.cell_size = Vector2.ONE
	path_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	path_grid.update()
	hostile_path_grid = AStarGrid2D.new()
	hostile_path_grid.region = Rect2i(Vector2i.ZERO, map_size)
	hostile_path_grid.cell_size = Vector2.ONE
	hostile_path_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	hostile_path_grid.update()
	# Build this lookup once. Calling get_building_at_tile() for every cell used
	# to turn a cache rebuild into thousands of profiled linear ID scans.
	var building_types_by_id: Dictionary = {}
	for building_value in buildings:
		var indexed_building: Dictionary = building_value
		building_types_by_id[int(indexed_building.get("id", 0))] = String(indexed_building.get("type", ""))
	for y in range(map_size.y):
		for x in range(map_size.x):
			var tile := Vector2i(x, y)
			var tile_key := _tile_key(tile)
			var building_type := String(building_types_by_id.get(int(occupied_tiles.get(tile_key, 0)), ""))
			var terrain := String(get_tile(tile))
			var blocked := terrain == Defs.TILE_SHARD or (_is_gate_tile(tile) and is_gate_closed())
			var hostile_blocked := terrain in [Defs.TILE_SHARD, Defs.TILE_TREE, Defs.TILE_ROCK] or (_is_gate_tile(tile) and is_gate_closed())
			if building_type != "" and building_type != Defs.BUILDING_ROAD:
				blocked = true
				hostile_blocked = true
			var move_weight := 1.0 if connected_walls.has(tile_key) or building_type == Defs.BUILDING_ROAD else 1.0 / ROAD_MOVE_MULTIPLIER
			path_grid.set_point_solid(tile, blocked)
			path_grid.set_point_weight_scale(tile, move_weight)
			hostile_path_grid.set_point_solid(tile, hostile_blocked)
			hostile_path_grid.set_point_weight_scale(tile, move_weight)
	path_grid_dirty = false


func _reconstruct_path(start: Vector2i, destination: Vector2i, came_from: Dictionary) -> Array:
	var path := []
	var current := destination
	while current != start:
		path.append(current)
		current = came_from[_tile_key(current)]
	path.reverse()
	return path


func _town_hall_access_tiles() -> Array:
	var tiles := []
	var town_hall := _find_town_hall()
	if town_hall.is_empty():
		return tiles
	var entrance := _town_hall_entrance_tile()
	if connected_roads.has(_tile_key(entrance)):
		tiles.append(entrance)
	return tiles


func _building_access_tiles(building: Dictionary) -> Array:
	var tiles := []
	for preferred in get_building_road_access_candidates(building):
		if connected_roads.has(_tile_key(preferred)) or connected_walls.has(_tile_key(preferred)):
			tiles.append(preferred)
	for neighbor in _footprint_perimeter(building["position"], _building_footprint(building)):
		if (connected_roads.has(_tile_key(neighbor)) or connected_walls.has(_tile_key(neighbor))) and not tiles.has(neighbor):
			tiles.append(neighbor)
	return tiles


func get_building_road_access_candidates(building: Dictionary) -> Array[Vector2i]:
	var anchor := Vector2i(building.get("position", Vector2i.ZERO))
	var footprint := _building_footprint(building)
	var rotation := posmod(int(building.get("rotation", 0)), 4)
	var candidates: Array[Vector2i] = []
	if rotation == 0:
		var left := maxi(0, (footprint.x - 1) / 2)
		candidates.append(anchor + Vector2i(left, footprint.y))
		if footprint.x >= 4:
			candidates.append(anchor + Vector2i(left + 1, footprint.y))
	elif rotation == 1:
		var top := maxi(0, (footprint.y - 1) / 2)
		candidates.append(anchor + Vector2i(-1, top))
		if footprint.y >= 4:
			candidates.append(anchor + Vector2i(-1, top + 1))
	elif rotation == 2:
		var left := maxi(0, (footprint.x - 1) / 2)
		candidates.append(anchor + Vector2i(left, -1))
		if footprint.x >= 4:
			candidates.append(anchor + Vector2i(left + 1, -1))
	else:
		var top := maxi(0, (footprint.y - 1) / 2)
		candidates.append(anchor + Vector2i(footprint.x, top))
		if footprint.y >= 4:
			candidates.append(anchor + Vector2i(footprint.x, top + 1))
	var valid: Array[Vector2i] = []
	for candidate in candidates:
		if is_inside_map(candidate) and not valid.has(candidate):
			valid.append(candidate)
	return valid


func get_worker_work_presentation(worker: Dictionary) -> Dictionary:
	var building := _find_building_by_id(int(worker.get("building_id", 0)))
	if building.is_empty() or not worker.get("path", []).is_empty():
		return {}
	var state := String(worker.get("state", "")).to_lower()
	if not ("work" in state or "guard" in state or "watch" in state or "fight" in state or "train" in state):
		return {}
	var type_name := String(building.get("type", ""))
	var center := get_building_center(building)
	var slot := posmod(int(worker.get("slot", 0)), 3)
	var offsets: Array[Vector2] = [Vector2.ZERO]
	match type_name:
		Defs.BUILDING_LUMBER_CAMP, Defs.BUILDING_SAWMILL:
			offsets = [Vector2(-1.25, -0.15), Vector2(1.20, -0.15), Vector2(-0.15, -1.05)]
		Defs.BUILDING_QUARRY:
			offsets = [Vector2(-0.95, 0.10), Vector2(0.80, -0.55), Vector2(0.85, 0.65)]
		Defs.BUILDING_FARM:
			offsets = [Vector2(-0.85, -0.65), Vector2(0.0, -0.65), Vector2(0.85, -0.65)]
		Defs.BUILDING_BAKERY:
			offsets = [Vector2(0.65, 0.60), Vector2(-0.55, 0.55), Vector2(0.0, -0.55)]
		Defs.BUILDING_BARRACKS:
			offsets = [Vector2(-0.85, -0.80), Vector2(0.0, -0.80), Vector2(0.85, -0.80)]
		Defs.BUILDING_WATCHTOWER:
			offsets = [Vector2(0.04, -0.02)]
		_:
			offsets = [Vector2(-0.55, 0.45), Vector2(0.55, 0.45), Vector2(0.0, -0.55)]
	var position: Vector2 = center + offsets[mini(slot, offsets.size() - 1)]
	var facing := position.direction_to(center)
	if type_name == Defs.BUILDING_WATCHTOWER:
		var target := _vector_from_data(building.get("combat_target_position", {}), Vector2i(building.get("position", Vector2i.ZERO)))
		if int(building.get("combat_target_id", 0)) > 0:
			facing = Vector2(position).direction_to(Vector2(target))
	var presentation := {
		"position": position,
		"facing": facing,
		"socket_index": slot,
		"authority_position": Vector2(worker.get("position", Vector2i.ZERO)),
	}
	if type_name == Defs.BUILDING_WATCHTOWER:
		presentation["elevation"] = 4.85
		presentation["platform"] = true
	return presentation


func _first_connected_road_tile() -> Vector2i:
	for key in connected_roads.keys():
		return _tile_from_key(key)
	return Vector2i(-1, -1)


func _is_walkable_road(tile: Vector2i) -> bool:
	return (connected_roads.has(_tile_key(tile)) or connected_walls.has(_tile_key(tile))) and not (_is_gate_tile(tile) and is_gate_closed())


func _is_road_tile(tile: Vector2i) -> bool:
	if connected_walls.has(_tile_key(tile)):
		return true
	var building := get_building_at_tile(tile)
	return not building.is_empty() and String(building.get("type", "")) == Defs.BUILDING_ROAD


func _is_worker_walkable(tile: Vector2i, is_goal: bool = false) -> bool:
	if not is_inside_map(tile):
		return false
	var terrain := String(get_tile(tile))
	if terrain == Defs.TILE_SHARD:
		return false
	if _is_gate_tile(tile) and is_gate_closed() and not is_goal:
		return false
	var building := get_building_at_tile(tile)
	return building.is_empty() or String(building.get("type", "")) == Defs.BUILDING_ROAD or is_goal


func _worker_step_seconds(worker: Dictionary, next_tile: Vector2i) -> float:
	var base := CARRIER_STEP_SECONDS if String(worker.get("type", "")) == "carrier" else LABORER_STEP_SECONDS
	if _is_road_tile(worker["position"]) or _is_road_tile(next_tile):
		return base * ROAD_MOVE_MULTIPLIER
	return base


func _enemy_step_seconds(current: Vector2i, next_tile: Vector2i, speed_multiplier: float = 1.0) -> float:
	if _is_road_tile(current) or _is_road_tile(next_tile):
		return ENEMY_STEP_SECONDS * ROAD_MOVE_MULTIPLIER * speed_multiplier
	return ENEMY_STEP_SECONDS * speed_multiplier


func _is_enemy_walkable(tile: Vector2i) -> bool:
	if not is_inside_map(tile):
		return false
	if String(get_tile(tile)) in [Defs.TILE_TREE, Defs.TILE_ROCK, Defs.TILE_SHARD]:
		return false
	if _is_gate_tile(tile) and is_gate_closed():
		return false
	var building := get_building_at_tile(tile)
	if building.is_empty():
		return true
	return String(building["type"]) == Defs.BUILDING_ROAD


func is_sovereign_walkable(tile: Vector2i) -> bool:
	if not _is_enemy_walkable(tile):
		return false
	return rivalry == null or not rivalry.is_sovereign_blocked(tile)


func find_sovereign_path(start: Vector2i, destination: Vector2i) -> Array:
	if not is_sovereign_walkable(destination):
		return []
	return _find_weighted_path(start, [destination], true)


func nearest_sovereign_walkable(origin: Vector2i, max_radius := 8) -> Vector2i:
	if is_sovereign_walkable(origin):
		return origin
	for radius in range(1, max_radius + 1):
		var candidates: Array[Vector2i] = []
		for y in range(origin.y - radius, origin.y + radius + 1):
			for x in range(origin.x - radius, origin.x + radius + 1):
				if maxi(absi(x - origin.x), absi(y - origin.y)) != radius:
					continue
				var tile := Vector2i(x, y)
				if is_sovereign_walkable(tile):
					candidates.append(tile)
		candidates.sort_custom(func(first: Vector2i, second: Vector2i) -> bool:
			var first_distance := _manhattan(origin, first)
			var second_distance := _manhattan(origin, second)
			return _tile_key(first) < _tile_key(second) if first_distance == second_distance else first_distance < second_distance
		)
		if not candidates.is_empty():
			return candidates[0]
	return Vector2i(-1, -1)


func is_gate_tile(tile: Vector2i) -> bool:
	return _is_gate_tile(tile)


func is_gate_closed() -> bool:
	return is_night or (not is_night and DAY_LENGTH_SECONDS - phase_time <= 30.0)


func _is_gate_tile(tile: Vector2i) -> bool:
	var road := get_building_at_tile(tile)
	if road.is_empty() or String(road.get("type", "")) != Defs.BUILDING_ROAD:
		return false
	return (_is_wall_tile(tile + Vector2i.LEFT) and _is_wall_tile(tile + Vector2i.RIGHT)) or (_is_wall_tile(tile + Vector2i.UP) and _is_wall_tile(tile + Vector2i.DOWN))


func _is_wall_tile(tile: Vector2i) -> bool:
	var building := get_building_at_tile(tile)
	return not building.is_empty() and String(building.get("type", "")) in [Defs.BUILDING_WALL, Defs.BUILDING_WATCHTOWER]


func _is_adjacent_to_town_hall(tile: Vector2i) -> bool:
	var town_hall := _find_town_hall()
	if town_hall.is_empty():
		return false
	return tile == _town_hall_entrance_tile()


func _town_hall_entrance_tile() -> Vector2i:
	var footprint := Defs.building_footprint(Defs.BUILDING_TOWN_HALL)
	return town_hall_position + Vector2i(footprint.x - 3, footprint.y)


func _rival_town_hall_entrance_tile() -> Vector2i:
	var footprint := Defs.building_footprint(Defs.BUILDING_TOWN_HALL)
	return rival_town_hall_position + Vector2i(footprint.x - 3, footprint.y)


func _has_adjacent_connected_road(tile: Vector2i) -> bool:
	for neighbor in _neighbors(tile):
		if connected_roads.has(_tile_key(neighbor)):
			return true
	return false


func _is_planned_road_tile(tile: Vector2i) -> bool:
	var building := get_building_at_tile(tile)
	return not building.is_empty() \
		and bool(building.get("construction", false)) \
		and String(building.get("planned_type", "")) == Defs.BUILDING_ROAD


func _has_adjacent_planned_or_connected_road(tile: Vector2i) -> bool:
	for neighbor in _neighbors(tile):
		if connected_roads.has(_tile_key(neighbor)) or _is_planned_road_tile(neighbor):
			return true
	return false


func _has_adjacent_connected_wall(tile: Vector2i) -> bool:
	return _has_adjacent_wall_support(tile)


func _has_adjacent_wall_support(tile: Vector2i) -> bool:
	if _has_adjacent_completed_watchtower(tile):
		return true
	for neighbor in _neighbors(tile):
		if connected_walls.has(_tile_key(neighbor)):
			return true
		var existing := get_building_at_tile(neighbor)
		if existing.is_empty():
			continue
		var kind := String(existing.get("planned_type", "")) if bool(existing.get("construction", false)) else String(existing.get("type", ""))
		if kind == Defs.BUILDING_WALL:
			return true
	return false


func _has_adjacent_completed_watchtower(tile: Vector2i) -> bool:
	for neighbor in _neighbors(tile):
		var building := get_building_at_tile(neighbor)
		if building.is_empty() or bool(building.get("construction", false)):
			continue
		if String(building.get("type", "")) == Defs.BUILDING_WATCHTOWER:
			return true
	return false


func _has_building_clearance(tile: Vector2i, footprint: Vector2i) -> bool:
	return true


func _oriented_footprint(building_type: String, rotation: int) -> Vector2i:
	var footprint := Defs.building_footprint(building_type)
	return Vector2i(footprint.y, footprint.x) if posmod(rotation, 2) == 1 else footprint


func _building_footprint(building: Dictionary) -> Vector2i:
	var stored = building.get("footprint", null)
	if typeof(stored) == TYPE_VECTOR2I:
		return stored
	if typeof(stored) == TYPE_DICTIONARY:
		return _vector_from_data(stored, Vector2i.ONE)
	var building_type := String(building.get("planned_type", "")) if bool(building.get("construction", false)) else String(building.get("type", ""))
	return Defs.building_footprint(building_type)


func get_building_footprint_tiles(building: Dictionary) -> Array[Vector2i]:
	return _footprint_tiles(building["position"], _building_footprint(building))


func get_building_center(building: Dictionary) -> Vector2:
	var footprint := _building_footprint(building)
	return Vector2(building["position"]) + Vector2(footprint - Vector2i.ONE) * 0.5


func _footprint_tiles(anchor: Vector2i, footprint: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for y in range(footprint.y):
		for x in range(footprint.x):
			tiles.append(anchor + Vector2i(x, y))
	return tiles


func _footprint_perimeter(anchor: Vector2i, footprint: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for x in range(footprint.x):
		tiles.append(anchor + Vector2i(x, -1))
		tiles.append(anchor + Vector2i(x, footprint.y))
	for y in range(footprint.y):
		tiles.append(anchor + Vector2i(-1, y))
		tiles.append(anchor + Vector2i(footprint.x, y))
	var inside: Array[Vector2i] = []
	for candidate in tiles:
		if is_inside_map(candidate) and not inside.has(candidate):
			inside.append(candidate)
	return inside


func _footprint_center(anchor: Vector2i, footprint: Vector2i) -> Vector2i:
	return anchor + Vector2i(footprint.x / 2, footprint.y / 2)


func _footprint_inside_map(anchor: Vector2i, footprint: Vector2i) -> bool:
	return is_inside_map(anchor) and is_inside_map(anchor + footprint - Vector2i.ONE)


func _footprint_is_flat(anchor: Vector2i, footprint: Vector2i) -> bool:
	var base_height := get_height(anchor)
	for footprint_tile in _footprint_tiles(anchor, footprint):
		if get_height(footprint_tile) != base_height:
			return false
	return true


func _footprint_height_range(anchor: Vector2i, footprint: Vector2i) -> int:
	var minimum := 1000000
	var maximum := -1000000
	for footprint_tile in _footprint_tiles(anchor, footprint):
		var elevation := get_height(footprint_tile)
		minimum = mini(minimum, elevation)
		maximum = maxi(maximum, elevation)
	return maximum - minimum


func _level_building_site(anchor: Vector2i, footprint: Vector2i) -> void:
	var target_height := get_height(_footprint_center(anchor, footprint))
	for footprint_tile in _footprint_tiles(anchor, footprint):
		height_map[footprint_tile.y][footprint_tile.x] = target_height


func _footprint_has_terrain(anchor: Vector2i, footprint: Vector2i, terrain: String) -> bool:
	for footprint_tile in _footprint_tiles(anchor, footprint):
		if get_tile(footprint_tile) == terrain:
			return true
	return false


func _footprint_touches_connected_road(anchor: Vector2i, footprint: Vector2i) -> bool:
	for perimeter_tile in _footprint_perimeter(anchor, footprint):
		if connected_roads.has(_tile_key(perimeter_tile)):
			return true
	return false


func _footprint_touches_planned_or_connected_road(anchor: Vector2i, footprint: Vector2i) -> bool:
	for perimeter_tile in _footprint_perimeter(anchor, footprint):
		if connected_roads.has(_tile_key(perimeter_tile)) or _is_planned_road_tile(perimeter_tile):
			return true
	return false


func _auto_spur_tiles(anchor: Vector2i, footprint: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	if _footprint_touches_planned_or_connected_road(anchor, footprint):
		return tiles
	var perimeter := _footprint_perimeter(anchor, footprint)
	var perimeter_keys: Dictionary = {}
	for perimeter_tile in perimeter:
		perimeter_keys[_tile_key(perimeter_tile)] = true
	var queue: Array[Dictionary] = []
	var visited: Dictionary = {}
	var came_from: Dictionary = {}
	for road_key in connected_roads.keys():
		var road_tile := _tile_from_key(String(road_key))
		for neighbor in _neighbors(road_tile):
			if not _is_auto_spur_candidate(neighbor) or visited.has(_tile_key(neighbor)):
				continue
			visited[_tile_key(neighbor)] = true
			came_from[_tile_key(neighbor)] = road_tile
			queue.append({"tile": neighbor, "depth": 1})
	for building in buildings:
		if not (bool(building.get("construction", false)) and String(building.get("planned_type", "")) == Defs.BUILDING_ROAD):
			continue
		var planned_tile := Vector2i(building.get("position", Vector2i.ZERO))
		for neighbor in _neighbors(planned_tile):
			if not _is_auto_spur_candidate(neighbor) or visited.has(_tile_key(neighbor)):
				continue
			visited[_tile_key(neighbor)] = true
			came_from[_tile_key(neighbor)] = planned_tile
			queue.append({"tile": neighbor, "depth": 1})
	var goal := Vector2i(-1, -1)
	while not queue.is_empty():
		var node: Dictionary = queue.pop_front()
		var current: Vector2i = node["tile"]
		if perimeter_keys.has(_tile_key(current)):
			goal = current
			break
		if int(node["depth"]) >= AUTO_SPUR_MAX_STEPS:
			continue
		for neighbor in _neighbors(current):
			if not _is_auto_spur_candidate(neighbor) or visited.has(_tile_key(neighbor)):
				continue
			visited[_tile_key(neighbor)] = true
			came_from[_tile_key(neighbor)] = current
			queue.append({"tile": neighbor, "depth": int(node["depth"]) + 1})
	if goal.x < 0:
		return tiles
	var walk := goal
	while _is_auto_spur_candidate(walk):
		tiles.insert(0, walk)
		var parent: Vector2i = came_from.get(_tile_key(walk), Vector2i(-1, -1))
		if parent.x < 0 or parent == walk:
			break
		walk = parent
	return tiles


func _is_auto_spur_candidate(tile: Vector2i) -> bool:
	if not is_inside_map(tile) or not is_revealed(tile):
		return false
	if not _tile_allows_clear_and_build(tile, Defs.BUILDING_ROAD):
		return false
	var existing := get_building_at_tile(tile)
	if existing.is_empty():
		return true
	return bool(existing.get("construction", false)) and String(existing.get("planned_type", "")) == Defs.BUILDING_ROAD


func collect_build_pads(building_type: String, rotation: int = 0, limit: int = 40) -> Dictionary:
	var valid: Array[Vector2i] = []
	var clearing: Array[Vector2i] = []
	if not Defs.is_buildable(building_type) or building_type == Defs.BUILDING_ROAD:
		return {"valid": valid, "clearing": clearing}
	var seen: Dictionary = {}
	var search_radius := 8
	for road_key in connected_roads.keys():
		var road_tile := _tile_from_key(String(road_key))
		for y in range(-search_radius, search_radius + 1):
			for x in range(-search_radius, search_radius + 1):
				var origin := road_tile + Vector2i(x, y)
				var key := _tile_key(origin)
				if seen.has(key) or not is_inside_map(origin) or not is_revealed(origin):
					continue
				seen[key] = true
				var result := validate_placement(building_type, origin, rotation)
				if not bool(result.get("success", false)):
					continue
				if "CLEARING REQUIRED" in String(result.get("message", "")):
					clearing.append(origin)
				else:
					valid.append(origin)
				if valid.size() + clearing.size() >= limit:
					return {"valid": valid, "clearing": clearing}
	return {"valid": valid, "clearing": clearing}


func _footprint_touches_tile(anchor: Vector2i, footprint: Vector2i, target: Vector2i) -> bool:
	return _footprint_tiles(anchor, footprint).has(target) or _footprint_perimeter(anchor, footprint).has(target)


func _road_grade_is_valid(tile: Vector2i) -> bool:
	if _is_adjacent_to_town_hall(tile):
		return absi(get_height(tile) - get_height(_footprint_center(town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL)))) <= 2
	for neighbor in _neighbors(tile):
		if connected_roads.has(_tile_key(neighbor)) or _is_planned_road_tile(neighbor):
			if absi(get_height(tile) - get_height(neighbor)) <= 2:
				return true
	return false


func _quarry_deposit_for_footprint(anchor: Vector2i, footprint: Vector2i) -> int:
	var total := 0
	for footprint_tile in _footprint_tiles(anchor, footprint):
		total += int(rock_deposits.get(_tile_key(footprint_tile), 0))
	return total


func _remove_wall_foundation(tile: Vector2i) -> void:
	var wall := get_building_at_tile(tile)
	if wall.is_empty() or String(wall.get("type", "")) != Defs.BUILDING_WALL:
		return
	for index in range(buildings.size() - 1, -1, -1):
		if int(buildings[index].get("id", 0)) == int(wall.get("id", 0)):
			buildings.remove_at(index)
			break
	_rebuild_occupied_tiles()
	_recompute_road_network()


func _count_connected_roads() -> int:
	return connected_roads.size()


func _find_town_hall() -> Dictionary:
	for building in buildings:
		if String(building["type"]) == Defs.BUILDING_TOWN_HALL:
			return building
	return {}


func _find_building_by_id(building_id: int) -> Dictionary:
	var stamp := _profile_stamp()
	var scanned := 0
	for building in buildings:
		scanned += 1
		if int(building["id"]) == building_id:
			_profile_scan("building_id_lookup", scanned)
			_profile_finish("dictionary_entity_scans", stamp)
			return building
	_profile_scan("building_id_lookup", scanned)
	_profile_finish("dictionary_entity_scans", stamp)
	return {}


func _display_building_name(building: Dictionary) -> String:
	if bool(building.get("construction", false)):
		return "%s Site" % Defs.building_name(String(building.get("planned_type", "")))
	return Defs.building_name(String(building["type"]))


func _inventory_total(inventory: Dictionary) -> int:
	var total := 0
	for resource_type in Defs.RESOURCE_TYPES:
		total += int(inventory.get(resource_type, 0))
	return total


func _calculate_housing_capacity_from_buildings() -> int:
	var total := STARTING_HOUSING_CAPACITY
	for building in buildings:
		if bool(building.get("construction", false)):
			continue
		total += Defs.adds_population(String(building.get("type", "")))
	return total


func _neighbors(tile: Vector2i) -> Array[Vector2i]:
	return [
		Vector2i(tile.x + 1, tile.y),
		Vector2i(tile.x - 1, tile.y),
		Vector2i(tile.x, tile.y + 1),
		Vector2i(tile.x, tile.y - 1)
	]


func _radius_offsets(radius: int) -> Array[Vector2i]:
	var offsets: Array[Vector2i] = []
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			if abs(x) + abs(y) <= radius:
				offsets.append(Vector2i(x, y))
	return offsets


func _manhattan(first: Vector2i, second: Vector2i) -> int:
	return abs(first.x - second.x) + abs(first.y - second.y)


func _tile_distance(first: Vector2i, second: Vector2i) -> float:
	var dx := float(first.x - second.x)
	var dy := float(first.y - second.y)
	return sqrt(dx * dx + dy * dy)


func _tile_key(tile: Vector2i) -> String:
	return "%d,%d" % [tile.x, tile.y]


func _tile_from_key(key: String) -> Vector2i:
	var parts := key.split(",")
	if parts.size() != 2:
		return Vector2i(-1, -1)
	return Vector2i(int(parts[0]), int(parts[1]))


func _success(message: String) -> Dictionary:
	return {"success": true, "reason": "None", "message": message}


func _with_placement_quality(result: Dictionary, building_type: String, tile: Vector2i, rotation: int) -> Dictionary:
	var score: Dictionary = Placement.score(self, building_type, tile, rotation)
	if not score.is_empty():
		result["placement_quality"] = score
		if bool(result.get("success", false)):
			result["message"] = "%s  %s" % [String(result.get("message", "")), String(score.get("label", ""))]
	return result


func _failure(reason: String, message: String) -> Dictionary:
	return {"success": false, "reason": reason, "message": message}


func _update_wyrdfall(delta: float) -> void:
	pressure_feedback_cooldown = maxf(0.0, pressure_feedback_cooldown - delta)
	var snapshot := get_wyrd_pressure()
	var value := float(snapshot.get("value", 0.0))
	var band := String(snapshot.get("band", Wyrdfall.BAND_QUIET))
	peak_wyrd_pressure = maxf(peak_wyrd_pressure, value)
	stats["peak_wyrd_pressure"] = peak_wyrd_pressure
	stats["territory_revealed"] = revealed_tiles.size()
	if band != last_pressure_band:
		var rising := value > last_pressure_value
		if rising:
			_emit_pressure_feedback(_pressure_feedback_message(band, snapshot))
		last_pressure_band = band
	last_pressure_value = value
	if reckoning_active and rivalry != null:
		var claim: Dictionary = rivalry.get_claim_status(RivalryTuning.PLAYER_REALM)
		var progress := float(claim.get("binding_progress", 0.0))
		if reckoning_waves_spawned < 2 and progress >= Wyrdfall.BINDING_DURATION_SECONDS * 0.5:
			_spawn_wave()
	_notice_shard_contact()


func _on_binding_started(realm_id: String) -> void:
	if realm_id == RivalryTuning.PLAYER_REALM:
		reckoning_active = true
		reckoning_waves_spawned = 0
		_add_log("THE RECKONING begins. The Wyrd reacts violently.")
		last_message = "THE RECKONING — hold the Shard until Binding completes."
		_spawn_wave()
		_emit_audio("enemy")
	else:
		_add_log("The rival has begun Binding the Shard.")
		last_message = "RIVAL BINDING — contest the Shard before they finish."
		_emit_audio("enemy")


func _on_binding_interrupted(realm_id: String, reason: String) -> void:
	if realm_id == RivalryTuning.PLAYER_REALM:
		reckoning_active = false
		last_message = reason
		_add_log(reason)


func _note_wyrd_extracted(amount: int, reason: String) -> void:
	cumulative_wyrd_extracted += amount
	stats["wyrd_extracted"] = int(stats.get("wyrd_extracted", 0)) + amount
	if reason == "extraction":
		pending_pressure_reason = "extraction"
		_emit_pressure_feedback("Wyrd Pressure rises — extraction has disturbed the wilds.")


func _emit_pressure_feedback(message: String) -> void:
	if pressure_feedback_cooldown > 0.0:
		return
	pressure_feedback_cooldown = Wyrdfall.PRESSURE_FEEDBACK_SECONDS
	_add_log(message)
	last_message = message


func _pressure_feedback_message(band: String, snapshot: Dictionary) -> String:
	var contributors: Dictionary = snapshot.get("contributors", {})
	if float(contributors.get("outposts", 0.0)) >= float(contributors.get("extraction", 0.0)) and float(contributors.get("outposts", 0.0)) >= 12.0:
		return "New Outpost active — the Wyrd is stirring."
	if float(contributors.get("shard", 0.0)) >= 20.0:
		return "Wyrd Pressure rises — the Shard feels your approach."
	if float(contributors.get("binding", 0.0)) >= 40.0:
		return "Wyrd Pressure is CRITICAL — the Reckoning is upon the realm."
	return "Wyrd Pressure is now %s." % band


func _compose_dawn_summary() -> void:
	dawn_summary = Dawn.compose(self)
	if dawn_summary.is_empty():
		return
	last_message = String(dawn_summary.get("title", "DAWN"))
	_add_log(String(dawn_summary.get("body", last_message)).replace("\n", " · "))
	playtest_log.note(self, "dawn_aftermath", last_message)


func _notice_discoveries() -> void:
	for feature in world_features:
		if bool(feature.get("revealed", false)):
			continue
		var position := Vector2i(feature.get("position", Vector2i.ZERO))
		if not is_revealed(position):
			continue
		feature["revealed"] = true
		var kind := String(feature.get("kind", ""))
		var message := String(feature.get("message", ""))
		if kind == "shard":
			shard_contacted = true
			_offer_onboarding("shard", "The Shard still burns. Reach it. Bind it. Survive what wakes.")
		elif kind == "wyrd_spring":
			_offer_onboarding("outpost", "A Wyrd spring. An Outpost here yields power — and raises Pressure.")
		var report: Dictionary = Discoveries.apply(self, feature)
		message = String(report.get("body", message))
		add_map_marker(kind, position, String(report.get("title", Discoveries.title_for(kind))), 0.0)
		_add_log(message)
		last_message = message
		_record_event("discovery", message, {"kind": kind, "tile": _vector_to_data(position)})


func _notice_shard_contact() -> void:
	if shard_contacted or not is_revealed(shard_position):
		return
	shard_contacted = true
	_offer_onboarding("shard", "The Shard still burns. Reach it. Bind it. Survive what wakes.")


func _register_wyrd_features() -> void:
	if rivalry == null:
		return
	for site in rivalry.get_wyrd_sites():
		_register_feature("wyrd_spring", Vector2i(site.get("position", Vector2i.ZERO)), "A Wyrd spring pulses in the wilds.")


func _serialize_map_markers() -> Array:
	var saved := []
	for marker in map_markers:
		var item: Dictionary = marker.duplicate(true)
		item["position"] = _vector_to_data(marker.get("position", Vector2i.ZERO))
		saved.append(item)
	return saved


func _restore_map_markers(saved: Array) -> Array:
	var restored := []
	for item in saved:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var marker: Dictionary = Dictionary(item).duplicate(true)
		marker["position"] = _vector_from_data(marker.get("position", {}), Vector2i.ZERO)
		restored.append(marker)
	return restored


func _serialize_world_features() -> Array:
	var saved := []
	for feature in world_features:
		var item: Dictionary = feature.duplicate(true)
		item["position"] = _vector_to_data(feature.get("position", Vector2i.ZERO))
		saved.append(item)
	return saved


func _restore_world_features(saved: Array) -> Array:
	var restored := []
	for item in saved:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var feature: Dictionary = Dictionary(item).duplicate(true)
		feature["position"] = _vector_from_data(feature.get("position", _vector_to_data(Vector2i.ZERO)), Vector2i.ZERO)
		restored.append(feature)
	return restored


func _pending_onboarding_hint() -> Dictionary:
	return pending_onboarding.duplicate(true)


func consume_onboarding_hint() -> Dictionary:
	var hint := pending_onboarding.duplicate(true)
	pending_onboarding = {}
	return hint


func _offer_onboarding(hint_id: String, text: String) -> void:
	if bool(onboarding_shown.get(hint_id, false)):
		return
	onboarding_shown[hint_id] = true
	Wyrdfall.save_onboarding(onboarding_shown)
	pending_onboarding = {"id": hint_id, "text": text}
	last_message = text
	_add_log(text)


func _mark_onboarding(hint_id: String) -> void:
	if bool(onboarding_shown.get(hint_id, false)):
		return
	onboarding_shown[hint_id] = true
	Wyrdfall.save_onboarding(onboarding_shown)


func _check_population_defeat() -> void:
	if game_finished or not is_town_hall_founded():
		return
	if population_current <= 0:
		_finish_run(false, "The last settlers are gone.")


func _serialize_state() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"rng_seed": rng_seed,
		"rng_state": str(rng.state),
		"map_size": _vector_to_data(map_size),
		"map_tiles": map_tiles,
		"height_map": height_map,
		"revealed_tiles": revealed_tiles,
		"tree_deposits": tree_deposits,
		"rock_deposits": rock_deposits,
		"tree_regrowth": tree_regrowth,
		"priority_clear_tiles": priority_clear_tiles,
		"town_hall_position": _vector_to_data(town_hall_position),
		"shard_position": _vector_to_data(shard_position),
		"enemy_camps": _serialize_enemy_camps(),
		"central_inventory": central_inventory,
		"reserved_inventory": reserved_inventory,
		"population_current": population_current,
		"housing_capacity": housing_capacity,
		"workers_assigned": workers_assigned,
		"soldiers_total": soldiers_total,
		"hidden_threat_level": hidden_threat_level,
		"pop_growth_timer": pop_growth_timer,
		"hunger_penalty_remaining": hunger_penalty_remaining,
		"hungry_population": hungry_population,
		"buildings": _serialize_buildings(),
		"workers": _serialize_workers(),
		"enemies": _serialize_enemies(),
		"projectiles": projectiles,
		"log_entries": log_entries,
		"notice_log": notice_log,
		"run_journal": run_journal,
		"objectives": objectives,
		"intention_completed": intention_completed,
		"intention_flags": intention_flags,
		"map_markers": _serialize_map_markers(),
		"stats": stats,
		"next_building_id": next_building_id,
		"next_worker_id": next_worker_id,
		"next_enemy_id": next_enemy_id,
		"next_camp_id": next_camp_id,
		"tick_number": tick_number,
		"elapsed_seconds": elapsed_seconds,
		"phase_time": phase_time,
		"day_count": day_count,
		"is_night": is_night,
		"night_warning_sent": night_warning_sent,
		"night_final_warning_sent": night_final_warning_sent,
		"dusk_warning_sent": dusk_warning_sent,
		"horn_warning_sent": horn_warning_sent,
		"raid_plan": raid_plan,
		"last_message": last_message,
		"game_finished": game_finished,
		"victory": victory,
		"defeat_reason": defeat_reason,
		"claim_active": claim_active,
		"claim_outpost_id": claim_outpost_id,
		"claim_nights_survived": claim_nights_survived,
		"wyrd_upkeep_progress": wyrd_upkeep_progress,
		"protection_powered": protection_powered,
		"presentation_opening_active": presentation_opening_active,
		"first_player_order_complete": first_player_order_complete,
		"presentation_worker_id": presentation_worker_id,
		"world_features": _serialize_world_features(),
		"cumulative_wyrd_extracted": cumulative_wyrd_extracted,
		"peak_wyrd_pressure": peak_wyrd_pressure,
		"last_pressure_band": last_pressure_band,
		"last_pressure_value": last_pressure_value,
		"reckoning_active": reckoning_active,
		"reckoning_waves_spawned": reckoning_waves_spawned,
		"dusk_forecast": dusk_forecast,
		"dawn_summary": dawn_summary,
		"night_casualties": night_casualties,
		"night_buildings_damaged": night_buildings_damaged,
		"night_enemies_spawned": night_enemies_spawned,
		"night_enemies_defeated_at_dusk": night_enemies_defeated_at_dusk,
		"shard_contacted": shard_contacted,
		"rivalry_state": rivalry.serialize_state() if rivalry != null else {}
	}


func _restore_state(data: Dictionary) -> void:
	var save_version := int(data.get("version", 1))
	rng_seed = int(data.get("rng_seed", 1))
	rng.seed = rng_seed
	map_size = _vector_from_data(data.get("map_size", _vector_to_data(Vector2i(MAP_WIDTH, MAP_HEIGHT))), Vector2i(MAP_WIDTH, MAP_HEIGHT))
	map_tiles = data.get("map_tiles", [])
	height_map = data.get("height_map", [])
	revealed_tiles = data.get("revealed_tiles", {})
	tree_deposits = data.get("tree_deposits", {})
	rock_deposits = data.get("rock_deposits", {})
	tree_regrowth = data.get("tree_regrowth", {})
	priority_clear_tiles = data.get("priority_clear_tiles", {}).duplicate(true)
	town_hall_position = _vector_from_data(data.get("town_hall_position", _vector_to_data(Vector2i.ZERO)), Vector2i.ZERO)
	shard_position = _vector_from_data(data.get("shard_position", _vector_to_data(Vector2i.ZERO)), Vector2i.ZERO)
	enemy_camps = _restore_enemy_camps(data.get("enemy_camps", []))
	central_inventory = _restore_inventory(data.get("central_inventory", Defs.STARTING_RESOURCES))
	reserved_inventory = _restore_inventory(data.get("reserved_inventory", Defs.empty_inventory()))
	buildings = _restore_buildings(data.get("buildings", []), save_version)
	housing_capacity = int(data.get("housing_capacity", _calculate_housing_capacity_from_buildings()))
	population_current = clampi(int(data.get("population_current", STARTING_POPULATION)), 0, housing_capacity)
	soldiers_total = clampi(int(data.get("soldiers_total", 0)), 0, population_current)
	hidden_threat_level = maxi(0, int(data.get("hidden_threat_level", 0)))
	pop_growth_timer = float(data.get("pop_growth_timer", 0.0))
	hunger_penalty_remaining = float(data.get("hunger_penalty_remaining", 0.0))
	hungry_population = clampi(int(data.get("hungry_population", 0)), 0, population_current)
	workers = _restore_workers(data.get("workers", []))
	_task_indexes_valid = false
	_task_incoming_by_destination.clear()
	_task_outgoing_by_source.clear()
	_task_incoming_to_central.clear()
	enemies = _restore_enemies(data.get("enemies", []))
	projectiles = data.get("projectiles", [])
	log_entries.clear()
	for entry in data.get("log_entries", []):
		log_entries.append(String(entry))
	notice_log = data.get("notice_log", [])
	pending_notices.clear()
	run_journal = data.get("run_journal", [])
	objectives = data.get("objectives", objectives)
	intention_completed = data.get("intention_completed", {})
	intention_flags = data.get("intention_flags", {})
	map_markers = _restore_map_markers(data.get("map_markers", []))
	stats = data.get("stats", stats)
	if not stats.has("workers_lost"):
		stats["workers_lost"] = 0
	if not stats.has("hungry_nights"):
		stats["hungry_nights"] = 0
	if not stats.has("wood_produced"):
		stats["wood_produced"] = 0
	if not stats.has("peak_population"):
		stats["peak_population"] = population_current
	world_features = _restore_world_features(data.get("world_features", []))
	cumulative_wyrd_extracted = int(data.get("cumulative_wyrd_extracted", int(stats.get("wyrd_extracted", 0))))
	peak_wyrd_pressure = float(data.get("peak_wyrd_pressure", float(stats.get("peak_wyrd_pressure", 0.0))))
	last_pressure_band = String(data.get("last_pressure_band", Wyrdfall.BAND_QUIET))
	last_pressure_value = float(data.get("last_pressure_value", 0.0))
	reckoning_active = bool(data.get("reckoning_active", false))
	reckoning_waves_spawned = int(data.get("reckoning_waves_spawned", 0))
	dusk_forecast = data.get("dusk_forecast", {})
	dawn_summary = data.get("dawn_summary", {})
	night_casualties = int(data.get("night_casualties", 0))
	night_buildings_damaged = int(data.get("night_buildings_damaged", 0))
	night_enemies_spawned = int(data.get("night_enemies_spawned", 0))
	night_enemies_defeated_at_dusk = int(data.get("night_enemies_defeated_at_dusk", 0))
	shard_contacted = bool(data.get("shard_contacted", false))
	onboarding_shown = Wyrdfall.load_onboarding()
	next_building_id = int(data.get("next_building_id", 1))
	next_worker_id = int(data.get("next_worker_id", 1))
	next_enemy_id = int(data.get("next_enemy_id", 1))
	next_camp_id = int(data.get("next_camp_id", enemy_camps.size() + 1))
	tick_number = int(data.get("tick_number", 0))
	elapsed_seconds = float(data.get("elapsed_seconds", 0.0))
	phase_time = float(data.get("phase_time", 0.0))
	day_count = int(data.get("day_count", 1))
	is_night = bool(data.get("is_night", false))
	night_warning_sent = bool(data.get("night_warning_sent", false))
	night_final_warning_sent = bool(data.get("night_final_warning_sent", false))
	dusk_warning_sent = bool(data.get("dusk_warning_sent", false))
	horn_warning_sent = bool(data.get("horn_warning_sent", false))
	raid_plan = data.get("raid_plan", {})
	last_message = String(data.get("last_message", "Run loaded."))
	game_finished = bool(data.get("game_finished", false))
	victory = bool(data.get("victory", false))
	defeat_reason = String(data.get("defeat_reason", ""))
	claim_active = bool(data.get("claim_active", false))
	claim_outpost_id = int(data.get("claim_outpost_id", 0))
	claim_nights_survived = int(data.get("claim_nights_survived", 0))
	wyrd_upkeep_progress = float(data.get("wyrd_upkeep_progress", 0.0))
	protection_powered = bool(data.get("protection_powered", int(central_inventory.get(Defs.RESOURCE_WYRD, 0)) > 0))
	presentation_opening_active = bool(data.get("presentation_opening_active", false))
	first_player_order_complete = bool(data.get("first_player_order_complete", _objective_complete("first_order")))
	presentation_worker_id = int(data.get("presentation_worker_id", 0))
	diagnostic_snapshot_elapsed = 0.0
	best_score = _load_best_score()
	_sanitize_resource_deposits()
	_rebuild_occupied_tiles()
	_recompute_road_network()
	if save_version < 7:
		# Version 6 accidentally let rival roads reveal a long remote corridor.
		# Rebuild visibility from the player's persisted settlement so old saves
		# do not keep displaying AI construction as if the player scouted it.
		revealed_tiles.clear()
		_reveal_from_world()
	if save_version < 8:
		if world_features.is_empty():
			_register_world_features()
			_register_wyrd_features()
		peak_wyrd_pressure = maxf(peak_wyrd_pressure, float(stats.get("peak_wyrd_pressure", 0.0)))
	_recalculate_workers_assigned()
	_enforce_worker_limit()
	_auto_staff_unstaffed_buildings()
	_sync_production_workers()
	if is_town_hall_founded():
		rivalry = RivalryRules.new()
		rivalry.setup(self, rng_seed)
		var rivalry_state: Dictionary = data.get("rivalry_state", {})
		if not rivalry_state.is_empty():
			rivalry.restore_state(rivalry_state)
	elif not is_town_hall_founded():
		rivalry = null
	# Worker shelter routes/tasks are already serialized. Reissuing the dusk
	# command here cancels deliveries and alters a saved live night on load.
	# Restore after setup/migration so their random draws cannot shift the run.
	if data.has("rng_state"):
		rng.state = int(data["rng_state"])


func _serialize_buildings() -> Array:
	var saved := []
	for building in buildings:
		var item: Dictionary = building.duplicate(true)
		item["position"] = _vector_to_data(building["position"])
		saved.append(item)
	return saved


func _restore_buildings(saved: Array, save_version: int = 3) -> Array:
	var restored := []
	for item in saved:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var building: Dictionary = Dictionary(item).duplicate(true)
		building["position"] = _vector_from_data(building.get("position", _vector_to_data(Vector2i.ZERO)), Vector2i.ZERO)
		building["local_inventory"] = _restore_inventory(building.get("local_inventory", Defs.empty_inventory()))
		if String(building.get("type", "")) == Defs.BUILDING_TOWN_HALL:
			building["local_capacity"] = 0
			building["local_inventory"] = Defs.empty_inventory()
		building["materials_delivered"] = _restore_inventory(building.get("materials_delivered", Defs.empty_inventory()))
		building["materials_in_transit"] = _restore_inventory(building.get("materials_in_transit", Defs.empty_inventory()))
		if not building.has("staff_priority"):
			building["staff_priority"] = _default_staff_priority(String(building.get("type", "")))
		if not building.has("staffing_enabled"):
			building["staffing_enabled"] = true
		if not building.has("assigned_staff"):
			building["assigned_staff"] = Defs.building_staff(String(building.get("type", ""))) if bool(building.get("staffed", false)) else 0
		if not building.has("soldiers_assigned"):
			building["soldiers_assigned"] = 0
		if not building.has("training_progress"):
			building["training_progress"] = 0.0
		if not building.has("footprint"):
			var footprint_type := String(building.get("planned_type", "")) if bool(building.get("construction", false)) else String(building.get("type", ""))
			building["footprint"] = _vector_to_data(Defs.building_footprint(footprint_type))
		if not building.has("production_timer"):
			building["production_timer"] = 0.0
		if not building.has("storage_paused"):
			building["storage_paused"] = false
		if not building.has("deposit_remaining"):
			var building_type := String(building.get("type", ""))
			building["deposit_remaining"] = int(rock_deposits.get(_tile_key(building["position"]), 0)) if building_type == Defs.BUILDING_QUARRY else 0
		if not building.has("site_clearing"):
			building["site_clearing"] = false
			building["clear_tiles"] = []
		if bool(building.get("construction", false)):
			_sync_site_clearing(building, false)
		if bool(building.get("construction", false)):
			var planned_type := String(building.get("planned_type", ""))
			var total_time := float(building.get("construction_total", Defs.build_time(planned_type)))
			if total_time <= 0.0:
				total_time = Defs.build_time(planned_type)
			building["construction_total"] = total_time
			building["construction_remaining"] = clampf(float(building.get("construction_remaining", total_time)), 0.0, total_time)
			if not building.has("build_cost") or typeof(building["build_cost"]) != TYPE_DICTIONARY:
				building["build_cost"] = Defs.building_cost(planned_type)
			if save_version < 3:
				building["materials_needed"] = Dictionary(building["build_cost"]).duplicate(true)
				building["materials_delivered"] = _restore_inventory(building["build_cost"])
				building["materials_in_transit"] = Defs.empty_inventory()
			else:
				building["materials_needed"] = Dictionary(building.get("materials_needed", building["build_cost"])).duplicate(true)
			building["assigned_staff"] = 0
			building["status"] = "Building."
		restored.append(building)
	return restored


func _serialize_enemy_camps() -> Array:
	var saved := []
	for camp in enemy_camps:
		var item: Dictionary = camp.duplicate(true)
		item["position"] = _vector_to_data(camp["position"])
		saved.append(item)
	return saved


func _restore_enemy_camps(saved: Array) -> Array:
	var restored := []
	for item in saved:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var camp: Dictionary = Dictionary(item).duplicate(true)
		camp["position"] = _vector_from_data(camp.get("position", _vector_to_data(Vector2i.ZERO)), Vector2i.ZERO)
		restored.append(camp)
	return restored


func _serialize_workers() -> Array:
	var saved := []
	for worker in workers:
		var item: Dictionary = worker.duplicate(true)
		item["position"] = _vector_to_data(worker["position"])
		item["shelter_position"] = _vector_to_data(worker.get("shelter_position", Vector2i(-1, -1)))
		for field in ["clear_target", "work_position"]:
			if worker.has(field):
				item[field] = _vector_to_data(worker[field])
		var path := []
		for tile in worker.get("path", []):
			path.append(_vector_to_data(tile))
		item["path"] = path
		item.erase("last_vision_tile")
		if worker.has("scout_mission"):
			var mission: Dictionary = Dictionary(worker.get("scout_mission", {})).duplicate(true)
			mission["home"] = _vector_to_data(mission.get("home", Vector2i.ZERO))
			mission["target"] = _vector_to_data(mission.get("target", Vector2i.ZERO))
			item["scout_mission"] = mission
		if worker.has("scout_last_enemy"):
			item["scout_last_enemy"] = _vector_to_data(worker.get("scout_last_enemy", Vector2i.ZERO))
		saved.append(item)
	return saved


func _restore_workers(saved: Array) -> Array:
	var restored := []
	for item in saved:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var worker: Dictionary = Dictionary(item).duplicate(true)
		worker["position"] = _vector_from_data(worker.get("position", _vector_to_data(Vector2i.ZERO)), Vector2i.ZERO)
		worker["shelter_position"] = _vector_from_data(worker.get("shelter_position", _vector_to_data(Vector2i(-1, -1))), Vector2i(-1, -1))
		for field in ["clear_target", "work_position"]:
			if worker.has(field):
				var saved_point: Variant = worker[field]
				# Earlier v8 saves encoded these two Vector2i values as strings.
				if saved_point is String:
					var parts: PackedStringArray = saved_point.trim_prefix("(").trim_suffix(")").split(",")
					if parts.size() == 2:
						saved_point = {"x": int(parts[0]), "y": int(parts[1])}
				worker[field] = _vector_from_data(saved_point, worker["position"])
		if String(worker.get("type", "")) == "carrier" and int(worker.get("capacity", 0)) <= 0:
			# Retire legacy temporary clearers that were incorrectly made carriers.
			if String(worker.get("role_key", "")).begins_with("clear:"):
				continue
			worker["capacity"] = 5
		worker["hp"] = int(worker.get("hp", WORKER_MAX_HP))
		worker["max_hp"] = int(worker.get("max_hp", WORKER_MAX_HP))
		worker["hungry"] = bool(worker.get("hungry", false))
		var path := []
		for tile_data in worker.get("path", []):
			path.append(_vector_from_data(tile_data, Vector2i.ZERO))
		worker["path"] = path
		worker.erase("last_vision_tile")
		if worker.has("scout_mission"):
			var mission: Dictionary = Dictionary(worker.get("scout_mission", {})).duplicate(true)
			mission["home"] = _vector_from_data(mission.get("home", {}), Vector2i.ZERO)
			mission["target"] = _vector_from_data(mission.get("target", {}), Vector2i.ZERO)
			worker["scout_mission"] = mission
		if worker.has("scout_last_enemy"):
			worker["scout_last_enemy"] = _vector_from_data(worker.get("scout_last_enemy", {}), Vector2i.ZERO)
		restored.append(worker)
	return restored


func _serialize_enemies() -> Array:
	var saved := []
	for enemy in enemies:
		var item: Dictionary = enemy.duplicate(true)
		item["position"] = _vector_to_data(enemy["position"])
		var path := []
		for tile in enemy.get("path", []):
			path.append(_vector_to_data(tile))
		item["path"] = path
		saved.append(item)
	return saved


func _restore_enemies(saved: Array) -> Array:
	var restored := []
	for item in saved:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var enemy: Dictionary = Dictionary(item).duplicate(true)
		enemy["position"] = _vector_from_data(enemy.get("position", _vector_to_data(shard_position)), shard_position)
		var enemy_type := String(enemy.get("enemy_type", ENEMY_RAIDER))
		var tuning := _enemy_archetype(enemy_type)
		enemy["enemy_type"] = enemy_type
		enemy["speed_multiplier"] = float(enemy.get("speed_multiplier", tuning.get("speed", 1.0)))
		enemy["attack_range"] = int(enemy.get("attack_range", tuning.get("range", 1)))
		enemy["attack_interval"] = float(enemy.get("attack_interval", tuning.get("interval", ENEMY_ATTACK_INTERVAL_SECONDS)))
		enemy["target_refresh_timer"] = float(enemy.get("target_refresh_timer", 0.0))
		enemy["target_kind"] = String(enemy.get("target_kind", "building"))
		enemy["target_position"] = enemy.get("target_position", _vector_to_data(shard_position))
		enemy["attack_damage_applied"] = bool(enemy.get("attack_damage_applied", true))
		enemy["armor"] = int(enemy.get("armor", 0))
		enemy["hit_until"] = float(enemy.get("hit_until", 0.0))
		enemy["hit_direction"] = enemy.get("hit_direction", _vector_to_data(Vector2i.ZERO))
		var path := []
		for tile_data in enemy.get("path", []):
			path.append(_vector_from_data(tile_data, enemy["position"]))
		enemy["path"] = path
		restored.append(enemy)
	return restored


func _restore_inventory(data) -> Dictionary:
	var inventory := Defs.empty_inventory()
	if typeof(data) == TYPE_DICTIONARY:
		for resource_type in Defs.RESOURCE_TYPES:
			inventory[resource_type] = int(data.get(resource_type, 0))
	return inventory


func _vector_to_data(vector: Vector2i) -> Dictionary:
	return {"x": vector.x, "y": vector.y}


func _vector_from_data(data, fallback: Vector2i) -> Vector2i:
	if typeof(data) != TYPE_DICTIONARY:
		return fallback
	return Vector2i(int(data.get("x", fallback.x)), int(data.get("y", fallback.y)))


func _load_best_score() -> int:
	if not FileAccess.file_exists(BEST_SCORE_PATH):
		return 0
	var file := FileAccess.open(BEST_SCORE_PATH, FileAccess.READ)
	if file == null:
		return 0
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return 0
	return int(json.data.get("best_score", 0))


func _save_best_score(score: int) -> void:
	var file := FileAccess.open(BEST_SCORE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"best_score": score}, "\t"))
