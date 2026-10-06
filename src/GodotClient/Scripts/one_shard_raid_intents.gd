extends RefCounted

## The Director: cheap raid variety by intent, not extra AI. Night 1 stays a probe.

const INTENT_ECONOMY := "raid_economy"
const INTENT_CENTER := "raid_center"
const INTENT_PROBE := "raid_probe"

const PROBE_RETREAT_SECONDS := 48.0
const DUSK_WARNING_SECONDS := 90.0
const HORN_WARNING_SECONDS := 45.0


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


static func label_for(intent: String) -> String:
	match intent:
		INTENT_ECONOMY:
			return "raiders hunting the yards"
		INTENT_CENTER:
			return "a push on the settlement centre"
		_:
			return "a probing raid"


static func dusk_message() -> String:
	return "Dusk approaches"


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
