extends RefCounted

## The Director: five discovery kinds under the fog. Reveal is the reward beat.

const KIND_DEPOSIT := "resource_deposit"
const KIND_CART := "abandoned_cart"
const KIND_RUINS := "ruins"
const KIND_TRACES := "enemy_traces"
const KIND_LANDMARK := "landmark"

const LORE := [
	"The Broken March",
	"Ash on the North Wind",
	"The Quiet Road",
	"Those Who Held the Ridge"
]


static func title_for(kind: String) -> String:
	match kind:
		KIND_DEPOSIT, "rich_forest", "stone_region":
			return "Rich deposit"
		KIND_CART:
			return "Abandoned supplies"
		KIND_RUINS, "ruined_cache":
			return "Old watchpost discovered"
		KIND_TRACES:
			return "Tracks in the mud"
		KIND_LANDMARK:
			return "Strange landmark"
		"enemy_camp":
			return "Raider camp discovered"
		_:
			return "Something in the fog"


static func apply(sim, feature: Dictionary) -> Dictionary:
	var kind := String(feature.get("kind", ""))
	var loot: Dictionary = Dictionary(feature.get("loot", {})).duplicate(true)
	if loot.is_empty():
		loot = default_loot(kind, int(sim.rng_seed) + int(feature.get("position", Vector2i.ZERO).x))
	for resource in loot.keys():
		var amount := int(loot[resource])
		if amount <= 0:
			continue
		sim.central_inventory[resource] = int(sim.central_inventory.get(resource, 0)) + amount
	var lore := String(feature.get("lore", ""))
	if lore == "" and kind in [KIND_RUINS, "ruined_cache"]:
		lore = LORE[posmod(int(sim.rng_seed) + int(feature.get("position", Vector2i.ZERO).y), LORE.size())]
	if kind in [KIND_DEPOSIT, "stone_region"]:
		sim.intention_flags["stone_deposit_found"] = true
	var title := title_for(kind)
	var body := String(feature.get("message", ""))
	if lore != "":
		body = "%s\nLore discovered: %s" % [body, lore]
	var loot_line := _loot_line(loot)
	if loot_line != "":
		body = "%s\n%s" % [body, loot_line]
	return {"title": title, "body": body, "loot": loot, "lore": lore}


static func default_loot(kind: String, salt: int) -> Dictionary:
	match kind:
		KIND_CART:
			return {"wood": 4 + posmod(salt, 4), "bread": 3 + posmod(salt, 3)}
		KIND_RUINS, "ruined_cache":
			return {"stone": 6 + posmod(salt, 5)}
		KIND_DEPOSIT, "stone_region":
			return {}
		_:
			return {}


static func _loot_line(loot: Dictionary) -> String:
	var parts: Array[String] = []
	for resource in loot.keys():
		var amount := int(loot[resource])
		if amount > 0:
			parts.append("+%d %s" % [amount, String(resource).capitalize()])
	return "  ".join(parts)
