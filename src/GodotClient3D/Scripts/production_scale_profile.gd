class_name ProductionScaleProfile3D
extends RefCounted

const METRES_PER_UNIT := 1.0
const LOGICAL_CELL_METRES := 2.50
const TERRAIN_ELEVATION_UNIT_METRES := 0.45
const CHARACTER_MODEL_SCALE := 0.88
const CHARACTER_PRESENTATION_HEIGHT_UNITS := 1.635
const CANONICAL_CHARACTER_HEIGHT_METRES := 1.80
const CHARACTER_GROUND_OFFSET := 0.03
const TOOL_MODEL_SCALE := 0.82
const CARGO_MODEL_SCALE := 1.08
# GFX-06: 18% narrower than GFX-1 (1.18 → 0.97) so lanes sit in the soil.
const ROAD_WIDTH_SCALE := 0.97
# GFX-K: W is the Town Hall's 4×4 world footprint. R is the rendered road.
const TOWN_HALL_WIDTH_METRES := 10.0


static func road_width_metres() -> float:
	return LOGICAL_CELL_METRES * ROAD_WIDTH_SCALE

# Phase 2.1 visual calibration. Characters remain the reference; these values
# change presentation mass only and never alter authoritative footprints.
const BUILDING_MODEL_SCALE := {
	"ENEMY_CAMP": 2.0,
	"TOWN_HALL": 1.0,
	"CASTLE": 1.0,
	"HOUSE": 4.40,
	"LUMBER_CAMP": 2.50,
	"SAWMILL": 2.60,
	"QUARRY": 3.25,
	"FARM": 4.60,
	"BAKERY": 4.60,
	"STOREHOUSE": 5.50,
	"WATCHTOWER": 3.50,
	"BARRACKS": 3.00,
	"WALL": 0.86,
	"LUMEN_PILLAR": 2.10,
	"CLAIMANT_OUTPOST": 3.25,
}

# Runtime model bounds at unit scale. They keep socket, focus, construction,
# and selection calibration derived from the same central presentation data.
const BUILDING_UNIT_SIZE := {
	"LUMEN_PILLAR": Vector3(0.8, 1.3, 0.8),
	"ENEMY_CAMP": Vector3(3.0, 3.7, 2.8),
	"TOWN_HALL": Vector3(8.24, 12.53, 6.88),
	"CASTLE": Vector3(8.24, 12.53, 7.13),
	"HOUSE": Vector3(0.7918, 0.9300, 0.8536),
	"LUMBER_CAMP": Vector3(1.3667, 1.7080, 1.1893),
	"SAWMILL": Vector3(1.3667, 1.7080, 1.1893),
	"QUARRY": Vector3(1.6056, 1.1367, 1.9200),
	"FARM": Vector3(0.7918, 0.9300, 0.8536),
	"BAKERY": Vector3(0.7918, 0.9300, 0.8536),
	"STOREHOUSE": Vector3(0.7918, 0.9300, 0.8536),
	"WATCHTOWER": Vector3(0.9933, 2.1920, 1.1533),
	"BARRACKS": Vector3(1.4400, 1.6401, 1.5661),
	"CLAIMANT_OUTPOST": Vector3(0.9933, 2.1920, 1.1533),
}

const WORLD_PROP_SCALE := {
	"wood_stack": 0.82,
	"plank_stack": 0.82,
	"stone_stack": 0.85,
	"barrel": 0.90,
	"crate": 0.90,
	"long_crate": 0.88,
	"wheelbarrow": 0.85,
	"dirt_plot": 0.90,
	"pitchfork": 0.90,
	"carrot": 0.90,
	"lettuce": 0.90,
	"work_axe": 0.90,
	"weaponrack": 0.95,
	"training_target": 1.05,
	"log": 0.90,
	"stump": 0.62,
	"sack": 0.95,
	"chopping_block": 0.78,
	"rocks": 0.85,
	"wheat_crop": 1.38,
	"lantern": 1.00,
	"fence": 1.00,
	"cart": 0.75,
}

# Only the three largest canopy models are reduced. Mature trees remain larger
# than houses while no longer routinely diminishing the civic silhouette.
const NATURE_MODEL_SCALE := {
	"Tree_1_A_Color1": 0.88,
	"Tree_1_C_Color1": 0.85,
	"Tree_2_A_Color1": 0.90,
	"Tree_2_B_Color1": 0.92,
	"Tree_2_C_Color1": 0.88,
	"Tree_3_A_Color1": 0.86,
	"Tree_4_A_Color1": 0.84,
}


static func tile_to_flat_world(tile_position: Vector2, map_size: Vector2i) -> Vector3:
	var half := Vector2(map_size - Vector2i.ONE) * 0.5
	return Vector3(
		(tile_position.x - half.x) * LOGICAL_CELL_METRES,
		0.0,
		(tile_position.y - half.y) * LOGICAL_CELL_METRES
	)


static func footprint_world_size(footprint: Vector2i) -> Vector2:
	return Vector2(footprint) * LOGICAL_CELL_METRES


static func building_scale(building_type: String) -> float:
	return float(BUILDING_MODEL_SCALE.get(building_type, 1.0))


static func building_visual_size(building_type: String, footprint := Vector2i.ONE) -> Vector3:
	if BUILDING_UNIT_SIZE.has(building_type):
		return Vector3(BUILDING_UNIT_SIZE[building_type]) * building_scale(building_type)
	var world_size := footprint_world_size(footprint)
	return Vector3(world_size.x * 0.82, 3.0, world_size.y * 0.82)


static func building_front_offset(building_type: String, footprint: Vector2i) -> float:
	var world_size := footprint_world_size(footprint)
	var visual_size := building_visual_size(building_type, footprint)
	return maxf(0.0, world_size.y * 0.5 - visual_size.z * 0.5 - 0.12)


static func world_prop_scale(prop_key: String) -> float:
	return float(WORLD_PROP_SCALE.get(prop_key, 1.0))


static func nature_model_scale(path_value: String) -> float:
	return float(NATURE_MODEL_SCALE.get(path_value.get_file().get_basename(), 1.0))
