extends SceneTree

## Helmer 8/10: raiders inside crop fields must stay readable at night.
## Crops skip depth writes; hostiles keep a through-occluder ring + silhouette.

const BuildingView = preload("res://src/GodotClient3D/Scripts/production_building_view_3d.gd")
const CharacterView = preload("res://src/GodotClient3D/Scripts/production_character_view_3d.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_hostile_highlight()
	await _test_farm_crops_do_not_occlude()
	for line in failures:
		print("FAIL %s" % line)
	print("T_HOSTILE_READABILITY %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_hostile_highlight() -> void:
	var view := CharacterView.new()
	view.configure(77, "enemy_raider")
	root.add_child(view)
	await process_frame
	view.set_faction("hostile")
	view.set_damage_state(22, 22)
	await process_frame
	_check(view.is_hostile_readable(), "a hostile under a crop field has a through-occluder ring and silhouette")
	var ring := view.get_node_or_null("ContextDamageRing") as MeshInstance3D
	var silhouette := view.get_node_or_null("HostileSilhouette") as MeshInstance3D
	_check(ring != null and ring.visible, "hostile ground ring is present")
	_check(silhouette != null and silhouette.visible, "hostile red silhouette is present")
	var ring_material := ring.material_override as StandardMaterial3D if ring != null else null
	var body_material := silhouette.material_override as StandardMaterial3D if silhouette != null else null
	_check(ring_material != null and ring_material.no_depth_test, "hostile ground ring draws through occluders")
	_check(body_material != null and body_material.no_depth_test, "hostile silhouette draws through wheat and houses")
	view.queue_free()
	await process_frame


func _test_farm_crops_do_not_occlude() -> void:
	var farm := BuildingView.new()
	farm.configure({
		"id": 9,
		"type": "FARM",
		"footprint": Vector2i(4, 3),
		"construction": false,
		"construction_fraction": 1.0,
		"hp": 100,
		"max_hp": 100
	})
	root.add_child(farm)
	await process_frame
	var wheat := _find_named(farm, "WheatCrop")
	_check(wheat != null, "farm workyard still plants wheat")
	_check(BuildingView.crops_do_not_occlude(wheat), "farm wheat does not occlude units")
	farm.queue_free()
	await process_frame


func _find_named(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found := _find_named(child, node_name)
		if found != null:
			return found
	return null


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
