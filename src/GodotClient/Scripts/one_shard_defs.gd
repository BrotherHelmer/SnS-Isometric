extends RefCounted

const TILE_GRASS := "GRASS"
const TILE_TREE := "TREE"
const TILE_ROCK := "ROCK"
const TILE_SHARD := "SHARD"

const BUILDING_NONE := "NONE"
const BUILDING_TOWN_HALL := "TOWN_HALL"
const BUILDING_ROAD := "ROAD"
const BUILDING_HOUSE := "HOUSE"
const BUILDING_LUMBER_CAMP := "LUMBER_CAMP"
const BUILDING_QUARRY := "QUARRY"
const BUILDING_SAWMILL := "SAWMILL"
const BUILDING_FARM := "FARM"
const BUILDING_BAKERY := "BAKERY"
const BUILDING_WALL := "WALL"
const BUILDING_WATCHTOWER := "WATCHTOWER"
const BUILDING_BARRACKS := "BARRACKS"
const BUILDING_STOREHOUSE := "STOREHOUSE"
const BUILDING_LUMEN_PILLAR := "LUMEN_PILLAR"
const BUILDING_OUTPOST := "CLAIMANT_OUTPOST"
const BUILDING_CONSTRUCTION_SITE := "CONSTRUCTION_SITE"
const TOOL_CLEAR_AREA := "CLEAR_AREA"

const RESOURCE_WOOD := "wood"
const RESOURCE_PLANKS := "planks"
const RESOURCE_STONE := "stone"
const RESOURCE_WHEAT := "wheat"
const RESOURCE_BREAD := "bread"
const RESOURCE_WYRD := "wyrd"
const RESOURCE_POPULATION_USED := "population_used"
const RESOURCE_POPULATION_MAX := "population_max"
const RESOURCE_WORKERS_FREE := "workers_free"
const RESOURCE_WORKERS_ASSIGNED := "workers_assigned"

const RESOURCE_TYPES := [
	RESOURCE_WOOD,
	RESOURCE_PLANKS,
	RESOURCE_STONE,
	RESOURCE_WHEAT,
	RESOURCE_BREAD,
	RESOURCE_WYRD
]

const STARTING_RESOURCES := {
	RESOURCE_WOOD: 50,
	RESOURCE_PLANKS: 18,
	RESOURCE_STONE: 18,
	RESOURCE_WHEAT: 0,
	RESOURCE_BREAD: 18,
	RESOURCE_WYRD: 3
}

const BUILDING_NAMES := {
	BUILDING_NONE: "None",
	BUILDING_TOWN_HALL: "Town Hall",
	BUILDING_ROAD: "Road",
	BUILDING_HOUSE: "House",
	BUILDING_LUMBER_CAMP: "Lumber Camp",
	BUILDING_QUARRY: "Quarry",
	BUILDING_SAWMILL: "Sawmill",
	BUILDING_FARM: "Farm",
	BUILDING_BAKERY: "Bakery",
	BUILDING_WALL: "Wall",
	BUILDING_WATCHTOWER: "Watchtower",
	BUILDING_BARRACKS: "Barracks",
	BUILDING_STOREHOUSE: "Storehouse",
	BUILDING_LUMEN_PILLAR: "Lumen Pillar",
	BUILDING_OUTPOST: "Outpost",
	BUILDING_CONSTRUCTION_SITE: "Construction Site",
	TOOL_CLEAR_AREA: "Clear"
}

const BUILDING_COSTS := {
	BUILDING_TOWN_HALL: { RESOURCE_WOOD: 20, RESOURCE_PLANKS: 8, RESOURCE_STONE: 8 },
	BUILDING_ROAD: {},
	BUILDING_HOUSE: { RESOURCE_WOOD: 4 },
	BUILDING_LUMBER_CAMP: { RESOURCE_WOOD: 2 },
	BUILDING_QUARRY: { RESOURCE_WOOD: 2 },
	BUILDING_SAWMILL: { RESOURCE_WOOD: 6 },
	BUILDING_FARM: { RESOURCE_WOOD: 4 },
	BUILDING_BAKERY: { RESOURCE_PLANKS: 4, RESOURCE_STONE: 4 },
	BUILDING_WALL: { RESOURCE_STONE: 2 },
	BUILDING_WATCHTOWER: { RESOURCE_STONE: 8, RESOURCE_PLANKS: 4 },
	BUILDING_BARRACKS: { RESOURCE_PLANKS: 10, RESOURCE_STONE: 8 },
	BUILDING_STOREHOUSE: { RESOURCE_PLANKS: 8, RESOURCE_STONE: 6 },
	BUILDING_LUMEN_PILLAR: { RESOURCE_WOOD: 8, RESOURCE_WYRD: 3 },
	BUILDING_OUTPOST: { RESOURCE_WOOD: 18 }
}

const BUILD_TIMES := {
	BUILDING_TOWN_HALL: 6.0,
	BUILDING_HOUSE: 2.0,
	BUILDING_LUMBER_CAMP: 2.5,
	BUILDING_QUARRY: 2.5,
	BUILDING_FARM: 3.0,
	BUILDING_SAWMILL: 4.0,
	BUILDING_BAKERY: 4.0,
	BUILDING_WALL: 1.5,
	BUILDING_WATCHTOWER: 8.0,
	BUILDING_BARRACKS: 7.0,
	BUILDING_STOREHOUSE: 6.0,
	BUILDING_LUMEN_PILLAR: 0.0,
	BUILDING_OUTPOST: 5.0
}

const BUILDING_STAFF := {
	BUILDING_TOWN_HALL: 0,
	BUILDING_ROAD: 0,
	BUILDING_HOUSE: 0,
	BUILDING_LUMBER_CAMP: 1,
	BUILDING_QUARRY: 1,
	BUILDING_SAWMILL: 1,
	BUILDING_FARM: 2,
	BUILDING_BAKERY: 1,
	BUILDING_WALL: 0,
	BUILDING_WATCHTOWER: 0,
	BUILDING_BARRACKS: 1,
	BUILDING_STOREHOUSE: 0,
	BUILDING_LUMEN_PILLAR: 0,
	BUILDING_OUTPOST: 0,
	BUILDING_CONSTRUCTION_SITE: 0
}

const BUILDING_HP := {
	BUILDING_TOWN_HALL: 500,
	BUILDING_ROAD: 20,
	BUILDING_HOUSE: 80,
	BUILDING_LUMBER_CAMP: 100,
	BUILDING_QUARRY: 150,
	BUILDING_SAWMILL: 150,
	BUILDING_FARM: 100,
	BUILDING_BAKERY: 150,
	BUILDING_WALL: 140,
	BUILDING_WATCHTOWER: 300,
	BUILDING_BARRACKS: 260,
	BUILDING_STOREHOUSE: 220,
	BUILDING_LUMEN_PILLAR: 90,
	BUILDING_OUTPOST: 220,
	BUILDING_CONSTRUCTION_SITE: 50
}

const BUILDING_LOCAL_CAPACITY := {
	BUILDING_TOWN_HALL: 0,
	BUILDING_ROAD: 0,
	BUILDING_HOUSE: 0,
	BUILDING_LUMBER_CAMP: 12,
	BUILDING_QUARRY: 12,
	BUILDING_SAWMILL: 12,
	BUILDING_FARM: 14,
	BUILDING_BAKERY: 12,
	BUILDING_WALL: 0,
	BUILDING_WATCHTOWER: 0,
	BUILDING_BARRACKS: 0,
	BUILDING_STOREHOUSE: 0,
	BUILDING_LUMEN_PILLAR: 0,
	BUILDING_OUTPOST: 0,
	BUILDING_CONSTRUCTION_SITE: 20
}

const PRODUCTION_DEFS := {
	BUILDING_LUMBER_CAMP: {
		"interval": 2.0,
		"output": RESOURCE_WOOD,
		"output_amount": 1,
		"nearby_tile": TILE_TREE,
		"deposit_resource": RESOURCE_WOOD
	},
	BUILDING_QUARRY: {
		"interval": 5.0,
		"output": RESOURCE_STONE,
		"output_amount": 2,
		"nearby_tile": TILE_ROCK,
		"deposit_resource": RESOURCE_STONE
	},
	BUILDING_FARM: {
		"interval": 6.0,
		"output": RESOURCE_WHEAT,
		"output_amount": 2
	},
	BUILDING_SAWMILL: {
		"interval": 5.0,
		"input": RESOURCE_WOOD,
		"input_amount": 2,
		"output": RESOURCE_PLANKS,
		"output_amount": 2
	},
	BUILDING_BAKERY: {
		"interval": 5.0,
		"input": RESOURCE_WHEAT,
		"input_amount": 2,
		"output": RESOURCE_BREAD,
		"output_amount": 2
	}
}

const BUILDABLE_TYPES := [
	BUILDING_TOWN_HALL,
	BUILDING_ROAD,
	BUILDING_HOUSE,
	BUILDING_LUMBER_CAMP,
	BUILDING_QUARRY,
	BUILDING_SAWMILL,
	BUILDING_FARM,
	BUILDING_BAKERY,
	BUILDING_STOREHOUSE,
	BUILDING_WALL,
	BUILDING_WATCHTOWER,
	BUILDING_BARRACKS,
	BUILDING_LUMEN_PILLAR,
	BUILDING_OUTPOST
]

const BUILDING_FOOTPRINTS := {
	BUILDING_TOWN_HALL: Vector2i(4, 4),
	BUILDING_ROAD: Vector2i(1, 1),
	BUILDING_HOUSE: Vector2i(2, 2),
	BUILDING_LUMBER_CAMP: Vector2i(3, 3),
	BUILDING_QUARRY: Vector2i(3, 3),
	BUILDING_SAWMILL: Vector2i(3, 3),
	BUILDING_FARM: Vector2i(4, 3),
	BUILDING_BAKERY: Vector2i(3, 3),
	BUILDING_WALL: Vector2i(1, 1),
	BUILDING_WATCHTOWER: Vector2i(1, 1),
	BUILDING_BARRACKS: Vector2i(4, 3),
	BUILDING_STOREHOUSE: Vector2i(4, 3),
	BUILDING_LUMEN_PILLAR: Vector2i(1, 1),
	BUILDING_OUTPOST: Vector2i(2, 2),
	BUILDING_CONSTRUCTION_SITE: Vector2i(1, 1)
}

const BASE_STORAGE_LIMITS := {
	RESOURCE_WOOD: 80,
	RESOURCE_PLANKS: 60,
	RESOURCE_STONE: 80,
	RESOURCE_WHEAT: 60,
	RESOURCE_BREAD: 60,
	RESOURCE_WYRD: 999
}

const STOREHOUSE_BONUS := {
	RESOURCE_WOOD: 80,
	RESOURCE_PLANKS: 60,
	RESOURCE_STONE: 80,
	RESOURCE_WHEAT: 60,
	RESOURCE_BREAD: 60,
	RESOURCE_WYRD: 0
}

const PROCESSOR_INPUTS := {
	BUILDING_SAWMILL: RESOURCE_WOOD,
	BUILDING_BAKERY: RESOURCE_WHEAT
}

const OUTPUT_BUILDINGS := [
	BUILDING_LUMBER_CAMP,
	BUILDING_QUARRY,
	BUILDING_FARM,
	BUILDING_SAWMILL,
	BUILDING_BAKERY
]


static func building_name(building_type: String) -> String:
	return String(BUILDING_NAMES.get(building_type, building_type.capitalize()))


static func resource_name(resource_type: String) -> String:
	return resource_type.replace("_", " ").capitalize()


static func building_cost(building_type: String) -> Dictionary:
	return Dictionary(BUILDING_COSTS.get(building_type, {})).duplicate(true)


static func build_time(building_type: String) -> float:
	return float(BUILD_TIMES.get(building_type, 2.0))


static func building_staff(building_type: String) -> int:
	return int(BUILDING_STAFF.get(building_type, 0))


static func building_hp(building_type: String) -> int:
	return int(BUILDING_HP.get(building_type, 50))


static func local_capacity(building_type: String) -> int:
	return int(BUILDING_LOCAL_CAPACITY.get(building_type, 0))


static func building_footprint(building_type: String) -> Vector2i:
	return BUILDING_FOOTPRINTS.get(building_type, Vector2i.ONE)


static func empty_inventory() -> Dictionary:
	var inventory := {}
	for resource_type in RESOURCE_TYPES:
		inventory[resource_type] = 0
	return inventory


static func formatted_cost(building_type: String) -> String:
	var cost := building_cost(building_type)
	if cost.is_empty():
		return "Free"

	var parts: Array[String] = []
	for resource_type in RESOURCE_TYPES:
		if cost.has(resource_type):
			parts.append("%d %s" % [int(cost[resource_type]), resource_name(resource_type)])
	return ", ".join(parts)


static func is_buildable(building_type: String) -> bool:
	return BUILDABLE_TYPES.has(building_type)


static func is_producer(building_type: String) -> bool:
	return PRODUCTION_DEFS.has(building_type)


static func is_processor(building_type: String) -> bool:
	return PROCESSOR_INPUTS.has(building_type)


static func adds_population(building_type: String) -> int:
	if building_type == BUILDING_HOUSE:
		return 5
	return 0
