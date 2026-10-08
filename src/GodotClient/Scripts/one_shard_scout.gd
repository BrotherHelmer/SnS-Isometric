extends RefCounted

## The Director: Scout. Y / SCOUT sends a free patrol soldier into the nearest
## fog; a map click can still pick a bearing. He reveals on tile change, can
## be ambushed, and comes home on his own.

const NAMES := ["Erik", "Sigrid", "Astrid", "Bjorn", "Ingrid", "Leif", "Tove", "Gunnar", "Kari", "Nils"]
const DEPTH_LIMIT := 14
const LEG_LENGTH := 5
const FOOD_COST := 1
const RETURN_HP_RATIO := 0.5
const DUSK_RETURN_SECONDS := 60.0

const REASON_DEPTH := "depth"
const REASON_HEALTH := "health"
const REASON_ENEMY := "enemy"
const REASON_FOOD := "food"
const REASON_DUSK := "dusk"
const REASON_DONE := "done"


static func display_name(worker: Dictionary, seed_value: int) -> String:
	var existing := String(worker.get("display_name", ""))
	if existing != "":
		return existing
	var index := posmod(int(worker.get("id", seed_value)), NAMES.size())
	return NAMES[index]


static func score_waypoint(unexplored: int, toward_dir: float, from_home: float, enemy_risk: float) -> float:
	return float(unexplored) * 5.0 + toward_dir * 2.0 - from_home * 0.5 - enemy_risk * 8.0


static func return_message(reason: String, name_text: String) -> String:
	match reason:
		REASON_HEALTH:
			return "%s is wounded and turns back." % name_text
		REASON_ENEMY:
			return "Scout reports enemies!"
		REASON_FOOD:
			return "%s is out of rations and returns." % name_text
		REASON_DUSK:
			return "%s hurries home before nightfall." % name_text
		REASON_DEPTH, REASON_DONE:
			return "%s has scouted far enough and returns." % name_text
		_:
			return "%s is returning to town." % name_text
