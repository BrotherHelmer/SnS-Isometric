extends RefCounted

## Phase 4 Wyrdfall loop helpers.
## Pressure, night forecast, Binding requirements, and macro objectives stay
## deterministic and free of presentation math.

const BAND_QUIET := "QUIET"
const BAND_STIRRING := "STIRRING"
const BAND_DANGEROUS := "DANGEROUS"
const BAND_SEVERE := "SEVERE"
const BAND_CRITICAL := "CRITICAL"

const OBJECTIVE_SURVIVE := "survive"
const OBJECTIVE_REACH := "reach"
const OBJECTIVE_SECURE := "secure"
const OBJECTIVE_BIND := "bind"

const BINDING_MIN_WYRD := 12
const BINDING_DURATION_SECONDS := 120.0
const PRESSURE_FEEDBACK_SECONDS := 22.0
const ONBOARDING_PATH := "user://one_shard_onboarding.json"

const BAND_THRESHOLDS := {
	BAND_QUIET: 0.0,
	BAND_STIRRING: 20.0,
	BAND_DANGEROUS: 40.0,
	BAND_SEVERE: 60.0,
	BAND_CRITICAL: 80.0
}

const ACTIVITY_BY_BAND := {
	BAND_QUIET: "Light",
	BAND_STIRRING: "Moderate",
	BAND_DANGEROUS: "Heavy",
	BAND_SEVERE: "Severe",
	BAND_CRITICAL: "Extreme"
}

const RaidTuning = preload("one_shard_raid_tuning.gd")

const ENEMY_RAIDER := "raider"
const ENEMY_MARAUDER := "skitterer"
const ENEMY_BRUTE := "brute"

const OBJECTIVE_COPY := {
	OBJECTIVE_SURVIVE: {
		"title": "FEED THE SETTLEMENT",
		"detail": "Build a House, a Lumber Camp, and a Farm.",
		"summary": "Feed and shelter the settlement. Then expand toward the Shard."
	},
	OBJECTIVE_REACH: {
		"title": "REACH THE SHARD",
		"detail": "Extend your realm toward the beacon.",
		"summary": "Build roads and Outposts toward the beacon."
	},
	OBJECTIVE_SECURE: {
		"title": "SECURE THE SHARD",
		"detail": "Establish an Outpost near the Shard. Gather 12 Wyrd. Connect Lumen.",
		"summary": "Establish an Outpost near the Shard. Gather 12 Wyrd. Connect Lumen."
	},
	OBJECTIVE_BIND: {
		"title": "BIND THE SHARD",
		"detail": "Shard secured. Begin Binding when your settlement is prepared.",
		"summary": "Shard secured. Begin Binding when your settlement is prepared."
	}
}


static func band_for_pressure(value: float) -> String:
	if value >= 80.0:
		return BAND_CRITICAL
	if value >= 60.0:
		return BAND_SEVERE
	if value >= 40.0:
		return BAND_DANGEROUS
	if value >= 20.0:
		return BAND_STIRRING
	return BAND_QUIET


static func compute_pressure(inputs: Dictionary) -> Dictionary:
	var extracted := maxf(0.0, float(inputs.get("cumulative_wyrd_extracted", 0.0)))
	var wyrd_outposts := maxi(0, int(inputs.get("active_wyrd_outposts", 0)))
	var shard_control := clampf(float(inputs.get("shard_control", 0.0)), 0.0, 1.0)
	var binding_progress := clampf(float(inputs.get("binding_progress", 0.0)), 0.0, 1.0)
	var player_binding := bool(inputs.get("player_binding", false))
	var day_count := maxi(1, int(inputs.get("day_count", 1)))
	var extraction_term := minf(32.0, extracted * 1.75)
	var outpost_term := float(wyrd_outposts) * 12.0
	var shard_term := shard_control * 20.0
	var binding_term := 0.0
	if player_binding:
		binding_term = 42.0 + binding_progress * 8.0
	var day_term := minf(10.0, float(maxi(0, day_count - 1)) * 1.6)
	var value := clampf(extraction_term + outpost_term + shard_term + binding_term + day_term, 0.0, 100.0)
	var band := band_for_pressure(value)
	return {
		"value": snappedf(value, 0.1),
		"band": band,
		"contributors": {
			"extraction": snappedf(extraction_term, 0.1),
			"outposts": snappedf(outpost_term, 0.1),
			"shard": snappedf(shard_term, 0.1),
			"binding": snappedf(binding_term, 0.1),
			"time": snappedf(day_term, 0.1)
		}
	}


static func night_forecast(pressure_value: float, is_first_night: bool = false) -> Dictionary:
	var band := BAND_QUIET if is_first_night and pressure_value < 40.0 else band_for_pressure(pressure_value)
	return {
		"threat": band,
		"activity": String(ACTIVITY_BY_BAND.get(band, "Moderate")),
		"pressure": snappedf(pressure_value, 0.1)
	}


static func night_baseline(day_count: int, is_first_night: bool) -> float:
	if is_first_night:
		return 0.0
	if day_count <= 2:
		return 16.0
	return minf(24.0, 10.0 + float(day_count - 2) * 4.0)


static func wave_plan(pressure_value: float, day_count: int, is_first_night: bool, reckoning: bool) -> Dictionary:
	if is_first_night and not reckoning:
		return {
			"size": RaidTuning.NIGHT1_SIZE,
			"roster": [ENEMY_RAIDER],
			"hp": RaidTuning.NIGHT1_HP,
			"damage": RaidTuning.NIGHT1_DAMAGE,
			"armor": RaidTuning.NIGHT1_ARMOR,
			"steal": RaidTuning.NIGHT1_STEAL,
			"band": BAND_QUIET,
			"baseline": 0.0,
			"effective": snappedf(pressure_value, 0.1)
		}
	var baseline := night_baseline(day_count, false)
	var effective := pressure_value + baseline
	var band := band_for_pressure(effective)
	var size := 3
	var roster: Array[String] = [ENEMY_RAIDER]
	if day_count == 2 and not reckoning:
		return {
			"size": RaidTuning.NIGHT2_SIZE,
			"roster": [ENEMY_RAIDER, ENEMY_MARAUDER, ENEMY_RAIDER, ENEMY_MARAUDER, ENEMY_RAIDER],
			"hp": RaidTuning.NIGHT2_HP,
			"damage": RaidTuning.NIGHT2_DAMAGE,
			"armor": RaidTuning.NIGHT2_ARMOR,
			"steal": RaidTuning.NIGHT2_STEAL,
			"band": band,
			"baseline": snappedf(baseline, 0.1),
			"effective": snappedf(effective, 0.1)
		}
	match band:
		BAND_QUIET:
			size = 3
			roster = [ENEMY_RAIDER]
		BAND_STIRRING:
			size = 5
			roster = [ENEMY_RAIDER, ENEMY_MARAUDER, ENEMY_RAIDER, ENEMY_MARAUDER]
		BAND_DANGEROUS:
			size = 6
			roster = [ENEMY_RAIDER, ENEMY_MARAUDER, ENEMY_BRUTE, ENEMY_RAIDER]
		BAND_SEVERE:
			size = 8
			roster = [ENEMY_MARAUDER, ENEMY_RAIDER, ENEMY_BRUTE, ENEMY_MARAUDER]
		_:
			size = 10
			roster = [ENEMY_BRUTE, ENEMY_MARAUDER, ENEMY_RAIDER, ENEMY_BRUTE, ENEMY_MARAUDER]
	if reckoning:
		size = maxi(size, 8)
		if not roster.has(ENEMY_BRUTE):
			roster.append(ENEMY_BRUTE)
	return {
		"size": size,
		"roster": roster,
		"hp": RaidTuning.later_hp(day_count, band, reckoning),
		"damage": RaidTuning.later_damage(day_count, reckoning),
		"armor": RaidTuning.later_armor(band, reckoning),
		"steal": RaidTuning.steal_for_night(day_count, false),
		"band": band,
		"baseline": snappedf(baseline, 0.1),
		"effective": snappedf(effective, 0.1)
	}


static func macro_objective(state: Dictionary) -> Dictionary:
	var objective_id := OBJECTIVE_SURVIVE
	if bool(state.get("binding_active", false)) or bool(state.get("binding_ready", false)):
		objective_id = OBJECTIVE_BIND
	elif float(state.get("shard_control", 0.0)) > 0.0 or bool(state.get("shard_revealed", false)):
		objective_id = OBJECTIVE_SECURE
	elif bool(state.get("has_lumber", false)) or int(state.get("connected_roads", 0)) > 8:
		objective_id = OBJECTIVE_REACH
	var copy: Dictionary = OBJECTIVE_COPY[objective_id]
	var summary := String(copy.get("summary", copy.get("detail", "")))
	if objective_id == OBJECTIVE_SURVIVE and bool(state.get("starter_ready", false)):
		summary = "Food and shelter are stable. Prepare to expand."
	return {
		"id": objective_id,
		"title": String(copy["title"]),
		"detail": String(copy["detail"]),
		"summary": summary,
		"steps": objective_steps(objective_id, state)
	}


static func objective_steps(objective_id: String, state: Dictionary) -> Array[String]:
	var steps: Array[String] = []
	match objective_id:
		OBJECTIVE_SURVIVE:
			if not bool(state.get("has_house", false)):
				steps.append("Build a House so the settlement can grow.")
			if not bool(state.get("has_lumber", false)):
				steps.append("Build a Lumber Camp and clear nearby forest.")
			if not bool(state.get("has_farm", false)):
				steps.append("Build a Farm so food stays stable.")
			if not bool(state.get("has_watchtower", false)):
				steps.append("Build a Watchtower to defend against night raids.")
			if steps.is_empty():
				steps.append("Extend a road toward the Shard.")
				steps.append("Build a Claimant Outpost on the frontier.")
		OBJECTIVE_REACH:
			if not bool(state.get("has_road_toward_shard", false)):
				steps.append("Extend a connected road toward the Shard.")
			if not bool(state.get("has_outpost", false)):
				steps.append("Build a Claimant Outpost on the frontier.")
			steps.append("Keep the Outpost connected to Lumen.")
		OBJECTIVE_SECURE:
			if not bool(state.get("has_outpost", false)):
				steps.append("Establish an Outpost near the Shard.")
			if int(state.get("wyrd_total", 0)) < 12:
				steps.append("Gather 12 Wyrd.")
			steps.append("Keep Lumen connected along the approach.")
		OBJECTIVE_BIND:
			steps.append("Begin Binding when the settlement is prepared.")
			steps.append("Hold the Shard Outpost through the Reckoning.")
	while steps.size() > 3:
		steps.pop_back()
	return steps


static func enemy_role_name(enemy_type: String) -> String:
	match enemy_type:
		ENEMY_MARAUDER, "marauder", "runner":
			return "Marauder"
		ENEMY_BRUTE:
			return "Brute"
		"hexer":
			return "Hexer"
		_:
			return "Raider"


static func load_onboarding() -> Dictionary:
	if not FileAccess.file_exists(ONBOARDING_PATH):
		return {}
	var file := FileAccess.open(ONBOARDING_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


static func save_onboarding(shown: Dictionary) -> void:
	var file := FileAccess.open(ONBOARDING_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(shown, "\t"))


static func pressure_tooltip(snapshot: Dictionary) -> String:
	var contributors: Dictionary = snapshot.get("contributors", {})
	var lines: Array[String] = [
		"Wyrd Pressure %s — harvesting Wyrd and planting Outposts make the nights worse." % String(snapshot.get("band", BAND_QUIET)),
		"Extraction %d" % int(round(float(contributors.get("extraction", 0.0)))),
		"Outposts %d" % int(round(float(contributors.get("outposts", 0.0)))),
		"Shard approach %d" % int(round(float(contributors.get("shard", 0.0)))),
		"Binding %d" % int(round(float(contributors.get("binding", 0.0)))),
		"Passing nights %d" % int(round(float(contributors.get("time", 0.0))))
	]
	return "\n".join(lines)
