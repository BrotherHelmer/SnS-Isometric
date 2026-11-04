class_name GateBConfig
extends RefCounted

## Gate B Visual Rescue configuration utility
## Controls whether Gate B Nordic kit models are used in presentation.
##
## Set via command line: --gate-b-enable
##
## When enabled, presentation layer uses Gate B GLBs for Town Hall, House,
## and Lumber Camp with fallback to baseline production_diorama_buildings.

## Enable Gate B Nordic kit (checked from command line)
static var _enabled_cached := -1  # -1 = not yet checked, 0 = false, 1 = true

## Gate B asset paths
const GATE_B_ROOT := "res://assets/settlement3d/runtime/gate_b_nordic"

const GATE_B_MODELS := {
	"TOWN_HALL": GATE_B_ROOT + "/sns_town_hall.glb",
	"HOUSE": GATE_B_ROOT + "/sns_house.glb",
	"LUMBER_CAMP": GATE_B_ROOT + "/sns_lumber_camp.glb",
}

const GATE_B_TREES := {
	"pine": GATE_B_ROOT + "/sns_tree_pine.glb",
	"broadleaf": GATE_B_ROOT + "/sns_tree_round.glb",
	"fir": GATE_B_ROOT + "/sns_tree_pine.glb",
	"oak": GATE_B_ROOT + "/sns_tree_round.glb",
}


static func _check_enabled() -> bool:
	if _enabled_cached >= 0:
		return _enabled_cached == 1
	# Check command line args
	var args := OS.get_cmdline_user_args()
	for arg in args:
		if arg == "--gate-b-enable":
			_enabled_cached = 1
			print("GATE_B enabled via command line")
			return true
	_enabled_cached = 0
	return false


## Get Gate B model path if enabled and available, otherwise empty string
static func get_building_model(building_type: String) -> String:
	if not _check_enabled():
		return ""
	if not GATE_B_MODELS.has(building_type):
		return ""
	var path: String = GATE_B_MODELS[building_type]
	if not FileAccess.file_exists(path):
		push_warning("Gate B model missing: %s" % path)
		return ""
	return path


static func get_tree_model(tree_type: String) -> String:
	if not _check_enabled():
		return ""
	if not GATE_B_TREES.has(tree_type):
		return ""
	var path: String = GATE_B_TREES[tree_type]
	if not FileAccess.file_exists(path):
		return ""
	return path


## Check if Gate B assets are installed
static func assets_available() -> bool:
	return FileAccess.file_exists(GATE_B_ROOT + "/sns_town_hall.glb")


## Get Gate B kit info for logging
static func get_info() -> Dictionary:
	return {
		"enabled": _check_enabled(),
		"available": assets_available(),
		"root": GATE_B_ROOT,
		"buildings": GATE_B_MODELS.keys(),
		"trees": GATE_B_TREES.keys(),
	}
