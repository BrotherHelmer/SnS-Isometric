extends RefCounted

## All raid combat numbers live here. The simulation and Wyrdfall wave planner
## read these constants; do not sprinkle raw raid HP / damage / armour in callers.
## Director: this is the single balance table for night raids. Change numbers
## here, then update docs/BALANCE_RAIDS.md and the headless raid tests.

const Defs = preload("one_shard_defs.gd")

## Combat-log aggregation window. Hits against the same named target are
## combined into one Log line so a five-raider volley does not flood the panel.
const COMBAT_LOG_WINDOW_SECONDS := 2.0
const NOTICE_LOG_LIMIT := 80

## Incoming damage is reduced by armour, then floored so a hit always lands.
const MIN_DAMAGE_AFTER_ARMOR := 1

## Night 1 is a teaching raid: two raiders, they retreat after this window.
const NIGHT1_SIZE := 2
const NIGHT1_HP := 40
const NIGHT1_DAMAGE := 4
const NIGHT1_ARMOR := 1
const NIGHT1_STEAL := 1
const NIGHT1_RETREAT_SECONDS := 72.0

## Night 2 is the first "real" raid the playtest is judged against.
## HP 24 + armour 1: a Watchtower bolt deals 4, a soldier 3. Five of them
## last ~21 s against a staffed tower plus two patrol soldiers — a fight,
## not a delete — while three raiders need ~24 s to raze a Storehouse.
const NIGHT2_SIZE := 5
const NIGHT2_HP := 24
const NIGHT2_DAMAGE := 5
const NIGHT2_ARMOR := 1
const NIGHT2_STEAL := 2

## Later nights scale from the Night 2 baseline.
const LATER_HP_PER_DAY := 4
const LATER_DAMAGE_STEP_DAYS := 3
const LATER_DAMAGE_STEP := 2
const SEVERE_HP_BONUS := 4
const CRITICAL_HP_BONUS := 8
const SEVERE_ARMOR_BONUS := 0
const CRITICAL_ARMOR_BONUS := 1

## Stock stolen from the realm store (central inventory) each time a raider
## strikes a storage building. Stealing available stock — not reserved cargo —
## is the raid's economic wound.
const STORAGE_BUILDING_TYPES := [
	Defs.BUILDING_TOWN_HALL,
	Defs.BUILDING_STOREHOUSE
]
const LOOT_BUILDING_TYPES := [
	Defs.BUILDING_STOREHOUSE,
	Defs.BUILDING_BAKERY,
	Defs.BUILDING_LUMBER_CAMP,
	Defs.BUILDING_FARM,
	Defs.BUILDING_SAWMILL,
	Defs.BUILDING_QUARRY
]
const STEAL_RESOURCE_ORDER := [
	Defs.RESOURCE_BREAD,
	Defs.RESOURCE_WOOD,
	Defs.RESOURCE_WHEAT,
	Defs.RESOURCE_PLANKS,
	Defs.RESOURCE_STONE,
	Defs.RESOURCE_WYRD
]

## Headless scenario bounds used by tests/t_raid_combat.gd.
const UNDEFENDED_SIM_SECONDS := 28.0
const DEFENDED_MAX_SECONDS := 90.0
const DEFENDED_MIN_SECONDS := 8.0
const DEFENDED_RAIDER_COUNT := 5


static func later_hp(day_count: int, band: String, reckoning: bool) -> int:
	var hp := NIGHT2_HP + maxi(0, day_count - 2) * LATER_HP_PER_DAY
	if band == "SEVERE":
		hp += SEVERE_HP_BONUS
	elif band == "CRITICAL" or reckoning:
		hp += CRITICAL_HP_BONUS
	return hp


static func later_damage(day_count: int, reckoning: bool) -> int:
	var damage := NIGHT2_DAMAGE + int(maxi(0, day_count - 1) / LATER_DAMAGE_STEP_DAYS) * LATER_DAMAGE_STEP
	if reckoning:
		damage += 1
	return damage


static func later_armor(band: String, reckoning: bool) -> int:
	var armor := NIGHT2_ARMOR
	if band == "SEVERE":
		armor += SEVERE_ARMOR_BONUS
	elif band == "CRITICAL" or reckoning:
		armor += CRITICAL_ARMOR_BONUS
	return armor


static func steal_for_night(day_count: int, is_first_night: bool) -> int:
	if is_first_night or day_count <= 1:
		return NIGHT1_STEAL
	return NIGHT2_STEAL


static func apply_armor(raw_damage: int, armor: int) -> int:
	return maxi(MIN_DAMAGE_AFTER_ARMOR, raw_damage - maxi(0, armor))


## Time-to-kill seconds for a focus-fired target. First strike uses the
## animation remaining window; later strikes use the published interval.
static func ttk_seconds(hp: int, damage_per_hit: int, interval: float, first_delay: float = 0.0) -> float:
	var hits := int(ceil(float(maxi(1, hp)) / float(maxi(1, damage_per_hit))))
	if hits <= 0:
		return 0.0
	return first_delay + float(hits - 1) * interval
