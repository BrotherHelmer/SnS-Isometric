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
	"TOWN_HALL": ROOT + "/opening_style/town_hall.tscn",
	"CASTLE": ROOT + "/opening_style/castle.tscn",
	"HOUSE": ROOT + "/opening_style/house.tscn",
	"LUMBER_CAMP": ROOT + "/opening_style/lumber_camp.tscn",
	"SAWMILL": ROOT + "/opening_style/lumber_camp.tscn",
	"QUARRY": ROOT + "/opening_style/quarry.tscn",
	"FARM": ROOT + "/opening_style/house.tscn",
	"BAKERY": ROOT + "/opening_style/bakery.tscn",
	"STOREHOUSE": ROOT + "/opening_style/storehouse.tscn",
	"WATCHTOWER": ROOT + "/opening_style/watchtower.tscn",
	"BARRACKS": ROOT + "/opening_style/barracks.tscn",
	"WALL": ROOT + "/buildings/building_bridge_A.gltf",
	"LUMEN_PILLAR": ROOT + "/opening_style/lumen_pillar.tscn",
	"CLAIMANT_OUTPOST": ROOT + "/opening_style/watchtower.tscn",
	"ENEMY_CAMP": ROOT + "/opening_style/enemy_camp.tscn",
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
	"wheat": ROOT + "/opening_style/wheat.tscn",
	"bread": ROOT + "/buildings/crate_A_small.gltf",
	"wyrd": ROOT + "/resources/Iron_Bar.gltf",
}

const WORKYARD_PROPS := {
	"wheat_crop": ROOT + "/opening_style/wheat.tscn",
	"lantern": ROOT + "/opening_style/lantern.tscn",
	"fence": ROOT + "/opening_style/fence.tscn",
	"cart": ROOT + "/opening_style/cart.tscn",
	"wood_stack": ROOT + "/resources/Wood_Log_Stack.gltf",
	"plank_stack": ROOT + "/resources/Wood_Planks_Stack_Small.gltf",
	"stone_stack": ROOT + "/resources/Stone_Bricks_Stack_Small.gltf",
	"barrel": ROOT + "/buildings/barrel.gltf",
	"crate": ROOT + "/buildings/crate_A_small.gltf",
	"long_crate": ROOT + "/buildings/crate_long_A.gltf",
	"pitchfork": ROOT + "/farm/pitchfork.gltf",
	"dirt_plot": ROOT + "/farm/dirt_plot.gltf",
	"carrot": ROOT + "/opening_style/wheat.tscn",
	"lettuce": ROOT + "/opening_style/wheat.tscn",
	"wheelbarrow": ROOT + "/farm/wheelbarrow.gltf",
	"work_axe": ROOT + "/tools/axe.gltf",
	"weaponrack": ROOT + "/buildings/weaponrack.gltf",
	"training_target": ROOT + "/buildings/target.gltf",
}

# The Director: GFX-08 — 6 tree silhouettes so the forest edge is not one cone.
const TREES := [
	ROOT + "/opening_style/fir.tscn",
	ROOT + "/opening_style/broadleaf.tscn",
	ROOT + "/nature/Tree_1_A_Color1.gltf",
	ROOT + "/nature/Tree_2_A_Color1.gltf",
	ROOT + "/nature/Tree_3_A_Color1.gltf",
	ROOT + "/nature/Tree_4_A_Color1.gltf",
]

const EDGE_TREES := [
	ROOT + "/opening_style/fir.tscn",
	ROOT + "/nature/Tree_1_A_Color1.gltf",
	ROOT + "/nature/Tree_2_A_Color1.gltf",
	ROOT + "/nature/Tree_3_A_Color1.gltf",
	ROOT + "/opening_style/broadleaf.tscn",
	ROOT + "/nature/Tree_4_A_Color1.gltf",
]

const ROCKS := [ROOT + "/opening_style/rocks.tscn"]

const HALO_PROPS := {
	"log": ROOT + "/resources/Wood_Log_A.gltf",
	"stump": ROOT + "/resources/Wood_Log_B.gltf",
	"cart": ROOT + "/opening_style/cart.tscn",
	"wood_stack": ROOT + "/resources/Wood_Log_Stack.gltf",
	"plank_stack": ROOT + "/resources/Wood_Planks_Stack_Small.gltf",
	"stone_stack": ROOT + "/resources/Stone_Bricks_Stack_Small.gltf",
	"rocks": ROOT + "/opening_style/rocks.tscn",
	"barrel": ROOT + "/buildings/barrel.gltf",
	"crate": ROOT + "/buildings/crate_A_small.gltf",
	"long_crate": ROOT + "/buildings/crate_long_A.gltf",
	"sack": ROOT + "/opening_style/wheat.tscn",
	"chopping_block": ROOT + "/resources/Wood_Log_A.gltf",
	"fence": ROOT + "/opening_style/fence.tscn",
	"lantern": ROOT + "/opening_style/lantern.tscn",
	"wheat_crop": ROOT + "/opening_style/wheat.tscn",
	"wheelbarrow": ROOT + "/farm/wheelbarrow.gltf",
	"work_axe": ROOT + "/tools/axe.gltf",
	"weaponrack": ROOT + "/buildings/weaponrack.gltf",
	"training_target": ROOT + "/buildings/target.gltf",
}

const UNDERSTORY := [ROOT + "/opening_style/bush.tscn", ROOT + "/opening_style/grass.tscn"]

const GRASS := [ROOT + "/opening_style/grass.tscn"]


static func building_path(building_type: String) -> String:
	return String(BUILDINGS.get(building_type, BUILDINGS["HOUSE"]))


static func character_path(worker_type: String) -> String:
	return String(CHARACTERS.get(worker_type, CHARACTERS["settler"]))


static func all_runtime_paths() -> Array[String]:
	var paths: Array[String] = []
	for group in [CHARACTERS, ANIMATION_LIBRARIES, BUILDINGS, TOOLS, CARGO, WORKYARD_PROPS, HALO_PROPS]:
		for path_value in group.values():
			if not paths.has(String(path_value)):
				paths.append(String(path_value))
	for path_value in TREES + EDGE_TREES + ROCKS + UNDERSTORY + GRASS:
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
