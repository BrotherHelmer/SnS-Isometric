class_name GateBConfig
extends RefCounted

## Gate B Visual Rescue RETRY configuration utility
##
## RETRY orders (binding):
## - Scope: Town Hall ONLY (no house/lumber until TH beats baseline)
## - PRIMARY: --gate-b-retry → Real Blender kitbash from KayKit civic_keep.gltf base
##   (awaiting Purple's sns-gate-b-retry.tgz with detailed mesh preserved + Nordic materials)
## - CHALLENGER: --gate-b-control → C-only material/lighting/palette remap on existing mesh
##   (same civic_keep geometry, no mesh replacement, Nordic palette only)
## - BASELINE: no flag → existing production_diorama_buildings.gd
##
## First procedural cube kit (sns_town_hall.glb from sns-gate-b-kit.tgz) is DISABLED.
## That was NOT approved A+C. Real kitbash incoming.

## Flag states (checked from command line)
static var _retry_cached := -1      # -1 = not checked, 0 = false, 1 = true (kitbash)
static var _control_cached := -1    # -1 = not checked, 0 = false, 1 = true (C-only)
static var _legacy_cached := -1     # Old --gate-b-enable flag (now disabled)

## Gate B RETRY asset paths
const RETRY_ROOT := "res://assets/settlement3d/runtime/gate_b_retry"

## RETRY kitbash models (awaiting Purple's tarball)
## Town Hall ONLY until it beats baseline
const RETRY_MODELS := {
	"TOWN_HALL": RETRY_ROOT + "/sns_townhall_kitbash.glb",
	# House, Lumber Camp deferred until TH proves out
}

## Legacy procedural kit (DISABLED, not approved A+C)
const LEGACY_ROOT := "res://assets/settlement3d/runtime/gate_b_nordic"
const LEGACY_DISABLED := true  # Do not use procedural cube kit


static func _check_retry() -> bool:
	if _retry_cached >= 0:
		return _retry_cached == 1
	var args := OS.get_cmdline_user_args()
	for arg in args:
		if arg == "--gate-b-retry":
			_retry_cached = 1
			print("GATE_B_RETRY enabled (kitbash path)")
			return true
	_retry_cached = 0
	return false


static func _check_control() -> bool:
	if _control_cached >= 0:
		return _control_cached == 1
	var args := OS.get_cmdline_user_args()
	for arg in args:
		if arg == "--gate-b-control":
			_control_cached = 1
			print("GATE_B_CONTROL enabled (C-only material remap)")
			return true
	_control_cached = 0
	return false


static func _check_legacy() -> bool:
	if LEGACY_DISABLED:
		return false  # Hard disabled regardless of flag
	if _legacy_cached >= 0:
		return _legacy_cached == 1
	var args := OS.get_cmdline_user_args()
	for arg in args:
		if arg == "--gate-b-enable":
			_legacy_cached = 1
			push_warning("--gate-b-enable (legacy procedural kit) is DISABLED. Use --gate-b-retry or --gate-b-control.")
			return false  # Flag present but disabled
	_legacy_cached = 0
	return false


## Get RETRY kitbash model path (Town Hall only, awaiting Purple's tarball)
static func get_retry_model(building_type: String) -> String:
	if not _check_retry():
		return ""
	if not RETRY_MODELS.has(building_type):
		return ""
	var path: String = RETRY_MODELS[building_type]
	if not FileAccess.file_exists(path):
		push_warning("Gate B RETRY kitbash missing (awaiting tarball): %s" % path)
		return ""
	return path


## Check if C-only control path is active (material remap only, no mesh swap)
static func is_control_active() -> bool:
	return _check_control()


## LEGACY: Old get_building_model (now disabled)
static func get_building_model(building_type: String) -> String:
	push_warning("get_building_model() is deprecated. Use get_retry_model() or is_control_active().")
	return ""


## Check if RETRY kitbash is available (Town Hall only)
static func retry_assets_available() -> bool:
	return FileAccess.file_exists(RETRY_ROOT + "/sns_townhall_kitbash.glb")


## Get Gate B RETRY info for logging
static func get_info() -> Dictionary:
	return {
		"retry_enabled": _check_retry(),
		"control_enabled": _check_control(),
		"legacy_disabled": LEGACY_DISABLED,
		"retry_available": retry_assets_available(),
		"retry_root": RETRY_ROOT,
		"retry_buildings": RETRY_MODELS.keys(),
		"scope": "Town Hall ONLY until it beats baseline",
	}
