extends RefCounted

# Central tuning for the playable two-realm rivalry layer.

const PLAYER_REALM := "player"
const AI_REALM := "rival"

const MATCH_INITIALISING := "INITIALISING"
const MATCH_ACTIVE := "ACTIVE"
const MATCH_PLAYER_CLAIMING := "PLAYER_CLAIMING"
const MATCH_AI_CLAIMING := "AI_CLAIMING"
const MATCH_PLAYER_VICTORY := "PLAYER_VICTORY"
const MATCH_AI_VICTORY := "AI_VICTORY"
const MATCH_PLAYER_DEFEAT := "PLAYER_DEFEAT"
const MATCH_AI_DEFEAT := "AI_DEFEAT"

const STRUCTURE_LUMEN_PILLAR := "LUMEN_PILLAR"
const STRUCTURE_CLAIMANT_OUTPOST := "CLAIMANT_OUTPOST"

const STARTING_WYRD := 3
const STARTING_WORKERS := 1
const ROAD_WOOD_COST := 0
const ROAD_MOVEMENT_MULTIPLIER := 1.35

const BUILDING_DEFINITIONS := {
	STRUCTURE_LUMEN_PILLAR: {
		"name": "Lumen Pillar",
		"footprint": Vector2i(1, 1),
		"wood_cost": 8,
		"wyrd_cost": 3,
		"max_hp": 90,
		"lumen_radius": 10.0
	},
	STRUCTURE_CLAIMANT_OUTPOST: {
		"name": "Claimant Outpost",
		"footprint": Vector2i(2, 2),
		"wood_cost": 18,
		"wyrd_cost": 0,
		"max_hp": 220,
		"lumen_radius": 5.0
	}
}

const HOME_LUMEN_RADIUS := 8.0
const LUMEN_LINK_DISTANCE := 17.0
const LUMEN_NIGHTLY_UPKEEP := 1
const MAX_LUMEN_PILLARS_PER_REALM := 6

const SOVEREIGN_MAX_HP := 100
const SOVEREIGN_MOVE_SPEED := 2.8
const SOVEREIGN_ATTACK_RANGE := 1.8
const SOVEREIGN_ATTACK_DAMAGE := 18
const SOVEREIGN_ATTACK_COOLDOWN := 0.9
const PLAYER_SOVEREIGN_MAX_HP := 180
const PLAYER_SOVEREIGN_MOVE_SPEED := 3.1
const PLAYER_SOVEREIGN_ATTACK_DAMAGE := 30
const PLAYER_SOVEREIGN_ATTACK_COOLDOWN := 0.68
const SOVEREIGN_HIT_INVULNERABILITY := 0.25
const SOVEREIGN_RESPAWN_SECONDS := 14.0
const SOVEREIGN_PASSIVE_HEAL_PER_SECOND := 2.0
const SOVEREIGN_HOME_HEAL_RADIUS := 5.0

const WYRD_EXTRACTION_RANGE := 1.7
const WYRD_EXTRACTION_SECONDS := 2.8
const WYRD_EXTRACTION_YIELD := 5
const WYRD_SITE_COOLDOWN_SECONDS := 10.0
const DROPPED_WYRD_FRACTION := 0.5

const WORKER_MOVE_SPEED := 1.45
const WORKER_HARVEST_SECONDS := 5.0
const WORKER_WOOD_YIELD := 2
const WORKER_SEARCH_RADIUS := 16

const AI_PLANNING_FREQUENCY := 1.0
const AI_CLAIM_UNLOCK_SECONDS := 2280.0
const AI_OPENING_ROAD_LIMIT := 36
const AI_SIGHT_RADIUS := 10.0
const AI_MEMORY_SECONDS := 15.0
const AI_RETREAT_HEALTH_FRACTION := 0.32
const AI_DEFEND_RADIUS := 8.0
const AI_WYRD_RESERVE_NIGHTS := 1
const AI_PERSONALITY_WEIGHTS := {
	"heal_or_retreat": 1.35,
	"contest_claim": 1.25,
	"obtain_wyrd": 1.0,
	"extend_road": 0.95,
	"place_lumen": 0.92,
	"claim": 1.1,
	"defend": 0.88,
	"secure_wood": 0.72
}

const SHARD_CLAIM_RADIUS := 5.0
const SHARD_BUILD_RADIUS := 6.0
const CLAIM_CONTEST_RADIUS := 5.0
const CLAIM_REQUIRED_NIGHTS := 1
const BINDING_MIN_WYRD := 12
const BINDING_DURATION_SECONDS := 120.0

const DEBUG_ENABLED_DEFAULT := false


static func structure_definition(structure_type: String) -> Dictionary:
	return Dictionary(BUILDING_DEFINITIONS.get(structure_type, {})).duplicate(true)


static func structure_name(structure_type: String) -> String:
	return String(BUILDING_DEFINITIONS.get(structure_type, {}).get("name", structure_type.capitalize()))


static func structure_cost_text(structure_type: String) -> String:
	var definition := structure_definition(structure_type)
	return "%d Wood, %d Wyrd" % [
		int(definition.get("wood_cost", 0)),
		int(definition.get("wyrd_cost", 0))
	]
