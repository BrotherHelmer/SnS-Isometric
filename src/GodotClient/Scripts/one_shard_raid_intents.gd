extends RefCounted

## The Director: cheap raid variety by intent, not extra AI. Night 1 stays a probe.

const INTENT_ECONOMY := "raid_economy"
const INTENT_CENTER := "raid_center"
const INTENT_PROBE := "raid_probe"
const INTENT_RITUAL := "raid_ritual"
const INTENT_HARVESTER := "raid_harvester"

const BEARINGS := [
	"the north",
	"the north-east",
	"the east",
	"the south-east",
	"the south",
	"the south-west",
	"the west",
	"the north-west"
]

const TARGET_KINDS := [
	"TOWN_HALL",
	"STOREHOUSE",
	"BARRACKS",
	"SAWMILL",
	"CLAIMANT_OUTPOST",
	"WYRD_HARVESTER"
]

const PROBE_RETREAT_SECONDS := 48.0
const DUSK_WARNING_SECONDS := 90.0
const RAID_WARNING_SECONDS := 60.0
const HORN_WARNING_SECONDS := RAID_WARNING_SECONDS


static func choose(day_count: int, seed: int) -> String:
	if day_count <= 1:
		return INTENT_PROBE
	match posmod(day_count + seed, 3):
		0:
			return INTENT_CENTER
		1:
			return INTENT_ECONOMY
		_:
			return INTENT_PROBE


static func choose_bearing(day_count: int, seed: int) -> String:
	# Night 1 stays a probe from the crater road. Later nights walk the
	# compass so the final week is not the same column of fog every dusk.
	if day_count <= 1:
		return "the crater"
	return BEARINGS[posmod(day_count * 3 + seed, BEARINGS.size())]


static func choose_target_kind(day_count: int, seed: int) -> String:
	if day_count <= 1:
		return "TOWN_HALL"
	return TARGET_KINDS[posmod(day_count * 5 + seed, TARGET_KINDS.size())]


static func bearing_angle(bearing: String) -> float:
	match bearing:
		"the north":
			return -PI / 2.0
		"the north-east":
			return -PI / 4.0
		"the east":
			return 0.0
		"the south-east":
			return PI / 4.0
		"the south":
			return PI / 2.0
		"the south-west":
			return 3.0 * PI / 4.0
		"the west":
			return PI
		"the north-west":
			return -3.0 * PI / 4.0
		_:
			return -PI / 2.0


static func label_for(intent: String) -> String:
	match intent:
		INTENT_ECONOMY:
			return "raiders hunting the yards"
		INTENT_CENTER:
			return "a push on the settlement centre"
		INTENT_RITUAL:
			return "a strike on the Binding"
		INTENT_HARVESTER:
			return "a raid on the Wyrd Harvester"
		_:
			return "a probing raid"


static func dusk_message() -> String:
	return "Dusk approaches"


static func raid_warning_message(bearing: String, seconds: int = 60, target_name: String = "") -> String:
	var place := bearing
	if not place.begins_with("the "):
		place = "the %s" % place
	var line := "RAID IN %d SECONDS — hostiles from %s." % [seconds, place]
	if target_name != "":
		line += " They mean %s." % target_name
	return line


static func horn_message(bearing: String) -> String:
	var place := bearing
	if not place.begins_with("the "):
		place = "the %s" % place
	if "east" in place:
		return "Horns have been heard beyond the eastern woods."
	if "west" in place:
		return "Horns have been heard beyond the western woods."
	if "north" in place:
		return "Horns have been heard beyond the northern woods."
	if "south" in place:
		return "Horns have been heard beyond the southern woods."
	return "Horns have been heard beyond %s." % place
