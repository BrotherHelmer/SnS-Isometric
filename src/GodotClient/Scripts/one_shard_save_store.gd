extends RefCounted

## Validate disk data before touching a running realm. Keep the previous valid
## file until the replacement has been written, closed and read back.
const MIN_VERSION := 6
const MAX_VERSION := 8
const MAX_BYTES := 32 * 1024 * 1024
const Defs = preload("one_shard_defs.gd")

static func read_save(path: String, recover := true) -> Dictionary:
	var result := _read_one(path)
	# A newer save is deliberate, not corruption. Never silently roll it back.
	if result.get("success", false) or result.get("unsupported", false) or not recover:
		return result
	var backup := _read_one(path + ".bak")
	if backup.get("success", false):
		backup["recovered"] = true
		return backup
	return result

static func _read_one(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"success": false, "message": "No readable save at %s." % path.get_file()}
	if file.get_length() > MAX_BYTES:
		return {"success": false, "message": "Save exceeds the supported size."}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or not json.data is Dictionary:
		return {"success": false, "message": "Save is incomplete or invalid JSON."}
	var data: Dictionary = json.data
	if not _integer(data.get("version")):
		return {"success": false, "message": "Save has no valid version."}
	var version := int(data.version)
	if version < MIN_VERSION or version > MAX_VERSION:
		return {"success": false, "unsupported": true, "message": "Unsupported save version %d. This build supports versions %d–%d. Your file has not been changed." % [version, MIN_VERSION, MAX_VERSION]}
	var problem := validate(data)
	if problem != "":
		return {"success": false, "message": "Invalid save: %s. Your current realm is unchanged." % problem}
	return {"success": true, "data": data, "recovered": false}

static func write_save(path: String, data: Dictionary) -> Dictionary:
	var problem := validate(data)
	if problem != "":
		return {"success": false, "message": "Cannot save: %s." % problem}
	data = data.duplicate(false)
	data["saved_at_usec"] = int(Time.get_unix_time_from_system() * 1000000.0)
	var temporary := path + ".tmp"
	var backup := path + ".bak"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return {"success": false, "message": "Cannot create save. Check available space and folder permissions."}
	file.store_string(JSON.stringify(data))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or not _read_one(temporary).get("success", false):
		return {"success": false, "message": "Save verification failed. The previous save is intact."}
	# Copy only a valid primary over the recovery file. A corrupt primary must
	# never erase the backup from which the user just recovered.
	if _read_one(path).get("success", false):
		error = DirAccess.copy_absolute(path, backup)
		if error != OK:
			return {"success": false, "message": "Could not preserve the previous save. Save cancelled."}
	# Seed a recovery file on the very first write as well.
	elif not _read_one(backup).get("success", false):
		error = DirAccess.copy_absolute(temporary, backup)
		if error != OK:
			return {"success": false, "message": "Could not create a recovery save. Save cancelled."}
	error = DirAccess.rename_absolute(temporary, path)
	if error != OK:
		return {"success": false, "message": "Could not replace the save. Your recovery copy is intact."}
	return {"success": true, "message": "Realm saved."}

static func saved_time_usec(path: String) -> int:
	var fallback := int(FileAccess.get_modified_time(path)) * 1000000
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > MAX_BYTES:
		return fallback
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary and _integer(parsed.get("saved_at_usec")):
		return int(parsed.saved_at_usec)
	return fallback

static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func _integer(value: Variant) -> bool:
	return _number(value) and float(value) == floor(float(value))

static func _point(value: Variant) -> bool:
	return value is Dictionary and _integer(value.get("x")) and _integer(value.get("y"))

static func _inside(value: Variant, width: int, height: int) -> bool:
	return _point(value) and value.x >= 0 and value.y >= 0 and value.x < width and value.y < height

static func _ledger(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	for amount in value.values():
		if not _integer(amount) or amount < 0:
			return false
	return true

static func _records(value: Variant) -> bool:
	if not value is Array:
		return false
	for entry in value:
		if not entry is Dictionary:
			return false
	return true

static func validate(data: Dictionary) -> String:
	if not _integer(data.get("version")) or int(data.version) < MIN_VERSION or int(data.version) > MAX_VERSION:
		return "unsupported version"
	if not _point(data.get("map_size")):
		return "missing map dimensions"
	var width := int(data.map_size.x)
	var height := int(data.map_size.y)
	if width < 8 or height < 8 or width > 256 or height > 256:
		return "unsupported map dimensions"
	for field in ["map_tiles", "height_map"]:
		if not data.get(field) is Array or data[field].size() != height:
			return "invalid %s rows" % field
		for row in data[field]:
			if not row is Array or row.size() != width:
				return "invalid %s columns" % field
			for cell in row:
				if field == "height_map" and (not _number(cell) or absf(float(cell)) > 64.0):
					return "invalid elevation"
				if field == "map_tiles" and cell not in [Defs.TILE_GRASS, Defs.TILE_TREE, Defs.TILE_ROCK, Defs.TILE_SHARD]:
					return "unknown terrain"
	for field in ["town_hall_position", "shard_position"]:
		if not _inside(data.get(field), width, height):
			return "invalid %s" % field
	for field in ["central_inventory", "reserved_inventory", "stats", "revealed_tiles", "tree_deposits", "rock_deposits"]:
		if not data.get(field) is Dictionary:
			return "missing %s" % field
	for field in ["central_inventory", "reserved_inventory"]:
		for amount in data[field].values():
			if not _integer(amount) or amount < 0:
				return "invalid resource count"
	for field in ["tick_number", "rng_seed", "population_current", "housing_capacity", "next_building_id", "next_worker_id", "next_enemy_id", "day_count"]:
		if not _integer(data.get(field)) or data[field] < 0:
			return "invalid %s" % field
	for group in ["buildings", "workers", "enemies", "enemy_camps"]:
		if not data.get(group) is Array or data[group].size() > 20000:
			return "invalid %s list" % group
		var ids := {}
		for entity in data[group]:
			if not entity is Dictionary or not _integer(entity.get("id")) or int(entity.id) <= 0 or ids.has(int(entity.id)):
				return "invalid or duplicate %s identifier" % group
			ids[int(entity.id)] = true
			if not _inside(entity.get("position"), width, height):
				return "invalid %s position" % group
			if group == "buildings" and String(entity.get("type", "")) not in Defs.BUILDING_NAMES and String(entity.get("type", "")) != "CONSTRUCTION_SITE":
				return "unknown building type"
			for field in ["path", "clear_tiles"]:
				if entity.has(field):
					if not entity[field] is Array:
						return "invalid entity path"
					for point in entity[field]:
						if field == "clear_tiles" and point is String:
							var parts: PackedStringArray = point.split(",")
							if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
								return "invalid clearing tile"
							point = {"x": int(parts[0]), "y": int(parts[1])}
						if not _inside(point, width, height):
							return "out-of-bounds entity path"
			for field in ["local_inventory", "materials_needed", "materials_delivered", "materials_in_transit", "build_cost", "task"]:
				if entity.has(field) and not entity[field] is Dictionary:
					return "invalid %s" % field
				if field != "task" and entity.has(field) and not _ledger(entity[field]):
					return "invalid %s quantities" % field
			if entity.has("footprint") and (not _point(entity.footprint) or entity.footprint.x < 1 or entity.footprint.y < 1):
				return "invalid building footprint"
		var counter: String = {"buildings": "next_building_id", "workers": "next_worker_id", "enemies": "next_enemy_id", "enemy_camps": "next_camp_id"}[group]
		if data.has(counter):
			if not _integer(data[counter]):
				return "invalid identifier counter"
			for id in ids:
				if data[counter] <= id:
					return "identifier counter would reuse an existing entity"
	for worker in data.workers:
		var task: Dictionary = worker.get("task", {})
		for field in ["source", "destination"]:
			var id_value: Variant = task.get(field, 0)
			if id_value is String and id_value == "central":
				continue
			if not _integer(id_value):
				return "invalid delivery reference"
			# Destroyed destinations can remain until the next tick cancels a task.
			# Permit stale references; the simulation re-plans them after load.
	for field in ["projectiles", "log_entries", "objectives"]:
		if not data.get(field) is Array:
			return "invalid %s" % field
	for field in ["tree_regrowth", "priority_clear_tiles", "dusk_forecast", "dawn_summary", "rivalry_state"]:
		if data.has(field) and not data[field] is Dictionary:
			return "invalid %s" % field
	for field in ["world_features", "notice_log", "run_journal"]:
		if data.has(field) and not data[field] is Array:
			return "invalid %s" % field
	for field in ["projectiles", "objectives", "world_features", "notice_log", "run_journal"]:
		if data.has(field) and not _records(data[field]):
			return "invalid %s entry" % field
	var rivalry: Dictionary = data.get("rivalry_state", {})
	if not rivalry.is_empty():
		if not rivalry.get("realms") is Dictionary:
			return "invalid rivalry realms"
		for field in ["structures", "wyrd_sites", "dropped_wyrd"]:
			if not _records(rivalry.get(field, [])):
				return "invalid rivalry %s" % field
		for realm in rivalry.realms.values():
			if not realm is Dictionary:
				return "invalid realm"
			for field in ["claim", "sovereign", "roads", "resources"]:
				if not realm.get(field) is Dictionary:
					return "invalid realm %s" % field
			if not _ledger(realm.resources) or not _records(realm.get("workers", [])):
				return "invalid realm resources or workers"
	for field in ["elapsed_seconds", "phase_time"]:
		if not _number(data.get(field)) or data[field] < 0:
			return "invalid clock"
	return ""
