class_name ProductionAssetCatalog3D
extends RefCounted

# Gameplay code addresses only these semantic keys. Vendor provenance is kept
# in the runtime manifest and sync tool, never in controllers or save data.
const ROOT := "res://assets/settlement3d/runtime"

const CHARACTERS := {
	"settler": ROOT + "/characters/Rogue.glb",
	"founder": ROOT + "/characters/Farmer_B.glb",
	"carrier": ROOT + "/characters/Rogue_Hooded.glb",
	"woodcutter": ROOT + "/characters/Farmer_A.glb",
	"miner": ROOT + "/characters/Barbarian.glb",
	"farmer": ROOT + "/characters/Farmer_B.glb",
	"sawyer": ROOT + "/characters/Farmer_A.glb",
	"baker": ROOT + "/characters/Farmer_B.glb",
	"clearer": ROOT + "/characters/Farmer_A.glb",
	"guard": ROOT + "/characters/Knight.glb",
	"ranger": ROOT + "/characters/Ranger.glb",
	"enemy_raider": ROOT + "/characters/Barbarian.glb",
	"enemy_skitterer": ROOT + "/characters/Rogue_Hooded.glb",
	"enemy_brute": ROOT + "/characters/Barbarian.glb",
	"enemy_hexer": ROOT + "/characters/Mage.glb",
	"rival_worker": ROOT + "/characters/Farmer_A.glb",
}

const ANIMATION_LIBRARIES := {
	"CombatMelee": ROOT + "/animations/Rig_Medium/Rig_Medium_CombatMelee.glb",
	"CombatRanged": ROOT + "/animations/Rig_Medium/Rig_Medium_CombatRanged.glb",
	"General": ROOT + "/animations/Rig_Medium/Rig_Medium_General.glb",
	"MovementAdvanced": ROOT + "/animations/Rig_Medium/Rig_Medium_MovementAdvanced.glb",
	"MovementBasic": ROOT + "/animations/Rig_Medium/Rig_Medium_MovementBasic.glb",
	"Simulation": ROOT + "/animations/Rig_Medium/Rig_Medium_Simulation.glb",
	"Special": ROOT + "/animations/Rig_Medium/Rig_Medium_Special.glb",
	"Tools": ROOT + "/animations/Rig_Medium/Rig_Medium_Tools.glb",
}

const BUILDINGS := {
	"TOWN_HALL": ROOT + "/buildings/building_castle_green.gltf",
	"HOUSE": ROOT + "/buildings/building_home_A_green.gltf",
	"LUMBER_CAMP": ROOT + "/buildings/building_lumbermill_green.gltf",
	"SAWMILL": ROOT + "/buildings/building_lumbermill_green.gltf",
	"QUARRY": ROOT + "/buildings/building_mine_green.gltf",
	"FARM": ROOT + "/buildings/building_home_A_green.gltf",
	"BAKERY": ROOT + "/buildings/building_home_A_green.gltf",
	"STOREHOUSE": ROOT + "/buildings/building_home_A_green.gltf",
	"WATCHTOWER": ROOT + "/buildings/building_tower_A_green.gltf",
	"BARRACKS": ROOT + "/buildings/building_barracks_green.gltf",
	"WALL": ROOT + "/buildings/building_bridge_A.gltf",
	"LUMEN_PILLAR": ROOT + "/resources/Iron_Bar.gltf",
	"CLAIMANT_OUTPOST": ROOT + "/buildings/building_tower_A_green.gltf",
	"ENEMY_CAMP": ROOT + "/buildings/building_castle_green.gltf",
}

const TOOLS := {
	"axe": ROOT + "/tools/axe.gltf",
	"pickaxe": ROOT + "/tools/pickaxe.gltf",
	"hammer": ROOT + "/tools/hammer.gltf",
	"saw": ROOT + "/tools/saw.gltf",
	"shovel": ROOT + "/tools/shovel.gltf",
}

const CARGO := {
	"wood": ROOT + "/resources/Wood_Log_A.gltf",
	"planks": ROOT + "/resources/Wood_Plank_A.gltf",
	"stone": ROOT + "/resources/Stone_Chunks_Small.gltf",
	"wheat": ROOT + "/farm/carrot.gltf",
	"bread": ROOT + "/buildings/crate_A_small.gltf",
	"wyrd": ROOT + "/resources/Iron_Bar.gltf",
}

const WORKYARD_PROPS := {
	"wood_stack": ROOT + "/resources/Wood_Log_Stack.gltf",
	"plank_stack": ROOT + "/resources/Wood_Planks_Stack_Small.gltf",
	"stone_stack": ROOT + "/resources/Stone_Bricks_Stack_Small.gltf",
	"barrel": ROOT + "/buildings/barrel.gltf",
	"crate": ROOT + "/buildings/crate_A_small.gltf",
	"long_crate": ROOT + "/buildings/crate_long_A.gltf",
	"pitchfork": ROOT + "/farm/pitchfork.gltf",
	"dirt_plot": ROOT + "/farm/dirt_plot.gltf",
	"carrot": ROOT + "/farm/carrot.gltf",
	"lettuce": ROOT + "/farm/lettuce.gltf",
	"wheelbarrow": ROOT + "/farm/wheelbarrow.gltf",
	"work_axe": ROOT + "/tools/axe.gltf",
	"weaponrack": ROOT + "/buildings/weaponrack.gltf",
	"training_target": ROOT + "/buildings/target.gltf",
}

const TREES := [
	ROOT + "/nature/Tree_1_A_Color1.gltf",
	ROOT + "/nature/Tree_1_B_Color1.gltf",
	ROOT + "/nature/Tree_1_C_Color1.gltf",
	ROOT + "/nature/Tree_2_A_Color1.gltf",
	ROOT + "/nature/Tree_2_B_Color1.gltf",
	ROOT + "/nature/Tree_2_C_Color1.gltf",
	ROOT + "/nature/Tree_3_A_Color1.gltf",
	ROOT + "/nature/Tree_3_B_Color1.gltf",
]

const ROCKS := [
	ROOT + "/nature/Rock_1_A_Color1.gltf",
	ROOT + "/nature/Rock_1_B_Color1.gltf",
	ROOT + "/nature/Rock_2_A_Color1.gltf",
	ROOT + "/nature/Rock_2_B_Color1.gltf",
]

const UNDERSTORY := [
	ROOT + "/nature/Bush_1_A_Color1.gltf",
	ROOT + "/nature/Bush_1_B_Color1.gltf",
	ROOT + "/nature/Grass_1_A_Color1.gltf",
	ROOT + "/nature/Grass_2_B_Color1.gltf",
]

const GRASS := [
	ROOT + "/nature/Grass_1_A_Color1.gltf",
	ROOT + "/nature/Grass_2_B_Color1.gltf",
]


static func building_path(building_type: String) -> String:
	return String(BUILDINGS.get(building_type, BUILDINGS["HOUSE"]))


static func character_path(worker_type: String) -> String:
	return String(CHARACTERS.get(worker_type, CHARACTERS["settler"]))


static func all_runtime_paths() -> Array[String]:
	var paths: Array[String] = []
	for group in [CHARACTERS, ANIMATION_LIBRARIES, BUILDINGS, TOOLS, CARGO, WORKYARD_PROPS]:
		for path_value in group.values():
			if not paths.has(String(path_value)):
				paths.append(String(path_value))
	for path_value in TREES + ROCKS + UNDERSTORY + GRASS:
		if not paths.has(String(path_value)):
			paths.append(String(path_value))
	return paths


static func integrity_report() -> Dictionary:
	var missing: Array[String] = []
	var raw_vendor_references: Array[String] = []
	for path_value in all_runtime_paths():
		if not ResourceLoader.exists(path_value):
			missing.append(path_value)
		if not path_value.begins_with(ROOT + "/"):
			raw_vendor_references.append(path_value)
	return {
		"success": missing.is_empty() and raw_vendor_references.is_empty(),
		"missing": missing,
		"raw_vendor_references": raw_vendor_references,
		"path_count": all_runtime_paths().size(),
	}
