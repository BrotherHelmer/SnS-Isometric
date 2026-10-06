extends SceneTree

## G1: every playable tile and every placed building, road, field or halo
## sits on land with a 2-tile beach. Shore is derived from the playable AABB
## and must never cut through the 18-step save or a fresh new game.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const HaloCatalog = preload("res://src/GodotClient3D/Scripts/production_building_halo.gd")
const ScaleProfile = preload("res://src/GodotClient3D/Scripts/production_scale_profile.gd")
const SAVE_PATH := "res://artifacts/phase3_2/persistence/eighteen_step_playthrough.json"

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	if not FileAccess.file_exists(SAVE_PATH):
		_check(false, "eighteen_step_playthrough.json is present")
		_finish(game)
		return
	if not game.simulation_host.load_from_path(SAVE_PATH):
		_check(false, "18-step save loads")
		_finish(game)
		return
	game._initialize_presentation()
	game._hide_start_menu()
	game.simulation_host.paused = true
	game.set_process(false)
	for _i in 4:
		await process_frame
	_assert_settlement_on_land(game, "18-step")

	game.start_new_3d(game.DEFAULT_SEED)
	game.simulation_host.paused = true
	game.set_process(false)
	for _i in 4:
		await process_frame
	_assert_settlement_on_land(game, "new-game")
	_finish(game)


func _assert_settlement_on_land(game, label: String) -> void:
	var world = game.world_view
	var sim = game.simulation_host.simulation
	_check(world != null and sim != null, "%s world and simulation exist" % label)
	if world == null or sim == null:
		return
	var map_size: Vector2i = sim.map_size
	_check(map_size.x > 0 and map_size.y > 0, "%s map is non-empty" % label)
	var off_mask := 0
	var thin_beach := 0
	for y in range(map_size.y):
		for x in range(map_size.x):
			var tile := Vector2i(x, y)
			if not world.playable_tile_is_on_land(tile):
				off_mask += 1
			if _tile_min_land(world, tile) < world.BEACH_MARGIN_METRES:
				thin_beach += 1
	print("T_G1_COAST %s map=%dx%d off_mask=%d thin_beach=%d" % [label, map_size.x, map_size.y, off_mask, thin_beach])
	_check(off_mask == 0, "%s every playable tile is on the land mask" % label)
	_check(thin_beach == 0, "%s every playable tile keeps a 2-tile beach" % label)

	var entity_off := 0
	var entity_count := 0
	for tile in _placed_entity_tiles(sim, world):
		entity_count += 1
		if not world.playable_tile_is_on_land(tile) or _tile_min_land(world, tile) < world.BEACH_MARGIN_METRES:
			entity_off += 1
			if entity_off <= 8:
				print("T_G1_COAST %s entity off-land %s land=%.2f" % [label, tile, _tile_min_land(world, tile)])
	print("T_G1_COAST %s entities=%d off_land=%d" % [label, entity_count, entity_off])
	_check(entity_count > 0, "%s found placed buildings/roads/fields" % label)
	_check(entity_off == 0, "%s every placed building, road, field and halo is on land" % label)

	var min_xz: Vector2 = world._fog_world_min_xz()
	var size_xz: Vector2 = world._fog_world_size_xz()
	var inside_corner := min_xz + Vector2(0.05, 0.05)
	var outside_mid := Vector2(min_xz.x - 20.0, min_xz.y + size_xz.y * 0.5)
	_check(world.island_land_metres(inside_corner) >= world.BEACH_MARGIN_METRES, "%s AABB corner stays inland of the 2-tile beach" % label)
	_check(world.island_land_metres(outside_mid) < 0.0, "%s shore sits outside the playable AABB" % label)


func _placed_entity_tiles(sim, world) -> Array[Vector2i]:
	var tiles: Dictionary = {}
	for building_value in sim.get_buildings():
		var building: Dictionary = building_value
		var type_name := String(building.get("planned_type", "")) if bool(building.get("construction", false)) else String(building.get("type", ""))
		var anchor: Vector2i = building.get("position", Vector2i.ZERO)
		var footprint: Vector2i = building.get("footprint", Defs.building_footprint(type_name))
		if footprint == Vector2i.ZERO:
			footprint = Defs.building_footprint(type_name)
		for oy in range(footprint.y):
			for ox in range(footprint.x):
				tiles[Vector2i(anchor.x + ox, anchor.y + oy)] = true
	for key_value in sim.connected_roads.keys():
		tiles[sim._tile_from_key(String(key_value))] = true
	for tile in world.halo_tiles():
		tiles[tile] = true
	for placement_value in HaloCatalog.resolve_world(sim):
		var placement: Dictionary = placement_value
		tiles[Vector2i(placement.get("tile", Vector2i.ZERO))] = true
	var result: Array[Vector2i] = []
	for tile_value in tiles.keys():
		result.append(tile_value)
	return result


func _tile_min_land(world, tile: Vector2i) -> float:
	var center: Vector3 = ScaleProfile.tile_to_flat_world(Vector2(tile), world.map_size)
	var half := ScaleProfile.LOGICAL_CELL_METRES * 0.5
	var samples := [
		Vector2(center.x, center.z),
		Vector2(center.x - half, center.z - half),
		Vector2(center.x + half, center.z - half),
		Vector2(center.x + half, center.z + half),
		Vector2(center.x - half, center.z + half),
	]
	var lowest := INF
	for sample in samples:
		lowest = minf(lowest, world.island_land_metres(sample))
	return lowest


func _finish(game: Node) -> void:
	if game != null:
		game.queue_free()
	await process_frame
	print("T_G1_COAST_LAND %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
