extends RefCounted

## The Director: five-second dawn chapter. Nights close with a score, then fade.

const Defs = preload("one_shard_defs.gd")

const HIGHLIGHT_SECONDS := 5.0
const DISPLAY_SECONDS := 5.0


static func compose(sim) -> Dictionary:
	var defeated := maxi(0, int(sim.stats.get("enemies_defeated", 0)) - int(sim.night_enemies_defeated_at_dusk))
	var lost := int(sim.night_casualties)
	var damaged := int(sim.night_buildings_damaged)
	if damaged <= 0:
		damaged = sim.raid_buildings_damaged_ids.size()
	var wounded := _soldiers_wounded(sim)
	if int(sim.night_enemies_spawned) <= 0 and defeated <= 0 and lost <= 0 and damaged <= 0 and wounded <= 0:
		return {}
	var night := maxi(1, int(sim.day_count) - 1)
	var lost_stock: Dictionary = Dictionary(sim.raid_resources_lost).duplicate(true)
	var recovered := _recover_supplies(sim, defeated)
	var highlight_ids: Array[int] = []
	for building_id in sim.raid_buildings_damaged_ids.keys():
		highlight_ids.append(int(building_id))
		var building: Dictionary = sim._find_building_by_id(int(building_id))
		if not building.is_empty():
			building["dawn_highlight_until"] = float(sim.elapsed_seconds) + HIGHLIGHT_SECONDS
	var lines: Array[String] = [
		"DAWN — Night %d survived" % night,
		"%d raiders killed" % defeated,
	]
	if wounded > 0:
		lines.append("%d soldier%s wounded" % [wounded, "" if wounded == 1 else "s"])
	if lost > 0:
		lines.append("%d settler%s lost" % [lost, "" if lost == 1 else "s"])
	if damaged > 0:
		lines.append("%d building%s damaged" % [damaged, "" if damaged == 1 else "s"])
	var stock_line := _stock_line(lost_stock, "lost")
	if stock_line != "":
		lines.append(stock_line)
	var recovered_line := _stock_line(recovered, "recovered")
	if recovered_line != "":
		lines.append(recovered_line)
	return {
		"title": "DAWN — Night %d survived" % night,
		"survived": true,
		"night": night,
		"enemies_defeated": defeated,
		"settlers_lost": lost,
		"soldiers_wounded": wounded,
		"buildings_damaged": damaged,
		"resources_lost": lost_stock,
		"supplies_recovered": recovered,
		"highlight_ids": highlight_ids,
		"lines": lines,
		"body": "\n".join(lines)
	}


static func _soldiers_wounded(sim) -> int:
	var wounded := 0
	for worker in sim.workers:
		if String(worker.get("type", "")) != "guard":
			continue
		if int(worker.get("hp", 0)) <= 0:
			continue
		if int(worker.get("hp", 0)) < int(worker.get("max_hp", sim.WORKER_MAX_HP)):
			wounded += 1
	return wounded


static func _recover_supplies(sim, defeated: int) -> Dictionary:
	var bread := maxi(0, int(floor(float(defeated) / 2.0)))
	if bread <= 0:
		return {}
	sim.central_inventory[Defs.RESOURCE_BREAD] = int(sim.central_inventory.get(Defs.RESOURCE_BREAD, 0)) + bread
	return {Defs.RESOURCE_BREAD: bread}


static func _stock_line(stock: Dictionary, verb: String) -> String:
	var parts: Array[String] = []
	for resource in stock.keys():
		var amount := int(stock[resource])
		if amount > 0:
			parts.append("%d %s" % [amount, Defs.resource_name(String(resource))])
	if parts.is_empty():
		return ""
	return "%s %s" % ["  ".join(parts), verb]
