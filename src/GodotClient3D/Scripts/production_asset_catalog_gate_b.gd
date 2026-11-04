class_name ProductionAssetCatalogGateB
extends RefCounted

## Gate B Visual Rescue: Nordic storybook kit integration
## Provides fallback-enabled catalog that switches between Gate B Nordic kit
## and baseline production assets based on USE_GATE_B_KIT flag.
##
## Usage:
##   var catalog = ProductionAssetCatalogGateB.new()
##   catalog.use_gate_b = true  # Enable Gate B models
##   var path = catalog.get_building_path("TOWN_HALL")
##
## Models are from tools/blender/gate-b-kit (CC0 procedural, 0 DKK)
## - sns_town_hall.glb (846 tri): light stone + 4 towers + red cones
## - sns_house.glb (472 tri): steep red gable, timber/stone
## - sns_lumber_camp.glb (484 tri): open thatch shed + logs
## - sns_tree_pine.glb (62 tri): mid-green pine
## - sns_tree_round.glb (80 tri): deciduous broadleaf
## - sns_path_strip.glb (32 tri): dirt path tile

const BaselineCatalog = preload("res://src/GodotClient3D/Scripts/production_asset_catalog.gd")
const GATE_B_ROOT := "res://assets/settlement3d/runtime/gate_b_nordic"

## Set to true to use Gate B Nordic kit, false for baseline
var use_gate_b := false

## Gate B proof scope: Town Hall, House, Lumber Camp only
## Other buildings fall back to baseline
const GATE_B_BUILDINGS := {
	"TOWN_HALL": GATE_B_ROOT + "/sns_town_hall.glb",
	"HOUSE": GATE_B_ROOT + "/sns_house.glb",
	"LUMBER_CAMP": GATE_B_ROOT + "/sns_lumber_camp.glb",
}

## Gate B tree models (for vegetation improvement)
const GATE_B_TREES := {
	"pine": GATE_B_ROOT + "/sns_tree_pine.glb",
	"broadleaf": GATE_B_ROOT + "/sns_tree_round.glb",
	"fir": GATE_B_ROOT + "/sns_tree_pine.glb",  # Reuse pine for fir
	"oak": GATE_B_ROOT + "/sns_tree_round.glb",  # Reuse round for oak
}

## Gate B path model
const GATE_B_PATH := GATE_B_ROOT + "/sns_path_strip.glb"


func get_building_path(building_type: String) -> String:
	if use_gate_b and GATE_B_BUILDINGS.has(building_type):
		return GATE_B_BUILDINGS[building_type]
	# Fallback to baseline catalog
	if BaselineCatalog.BUILDINGS.has(building_type):
		return BaselineCatalog.BUILDINGS[building_type]
	return ""


func get_tree_path(tree_type: String) -> String:
	if use_gate_b and GATE_B_TREES.has(tree_type):
		return GATE_B_TREES[tree_type]
	# Fallback to baseline - check nature catalog
	var baseline_key := tree_type
	if BaselineCatalog.NATURE.has(baseline_key):
		return BaselineCatalog.NATURE[baseline_key]
	return ""


func get_path_model() -> String:
	if use_gate_b:
		return GATE_B_PATH
	# Baseline uses procedural road, no model
	return ""


func get_character_path(character_type: String) -> String:
	# Characters not in Gate B scope, always use baseline
	if BaselineCatalog.CHARACTERS.has(character_type):
		return BaselineCatalog.CHARACTERS[character_type]
	return ""


func get_animation_library_path(library_name: String) -> String:
	# Animations not in Gate B scope, always use baseline
	if BaselineCatalog.ANIMATION_LIBRARIES.has(library_name):
		return BaselineCatalog.ANIMATION_LIBRARIES[library_name]
	return ""


## Helper: check if Gate B assets are available
static func gate_b_assets_available() -> bool:
	return FileAccess.file_exists(GATE_B_ROOT + "/sns_town_hall.glb")


## Helper: get Gate B kit info for logging
static func get_gate_b_info() -> Dictionary:
	return {
		"available": gate_b_assets_available(),
		"root": GATE_B_ROOT,
		"buildings": GATE_B_BUILDINGS.keys(),
		"tree_count": GATE_B_TREES.size(),
		"total_tris": {
			"town_hall": 846,
			"house": 472,
			"lumber_camp": 484,
			"tree_pine": 62,
			"tree_round": 80,
			"path_strip": 32,
		}
	}
