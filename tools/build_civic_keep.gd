extends SceneTree

## The Director: GFX-Q. Purpose-built limestone keep as live Town Hall
## / Castle. Authored at world metres, origin on the ground centre,
## door facing +Z (gameplay camera). Exports modular glTF with named
## CivicWall / CivicRoof / CivicTimber / CivicCrenel / CivicDoor /
## CivicPlinth meshes so the architecture shader can bind by name.

const OUT_DIR := "res://assets/settlement3d/runtime/buildings"

var _mats: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_export_keep(false)
	_export_keep(true)
	quit(0)


func _export_keep(castle: bool) -> void:
	var keep := Node3D.new()
	keep.name = "CivicCastle" if castle else "CivicKeep"
	root.add_child(keep)
	_build_keep(keep, castle)
	var aabb := _measure(keep)
	print("GFX_Q keep castle=%s aabb=%s" % [str(castle), str(aabb.size)])
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var err := document.append_from_scene(keep, state)
	if err != OK:
		push_error("GLTF append failed: %s" % err)
	var filename := "civic_castle.gltf" if castle else "civic_keep.gltf"
	var path := OUT_DIR.path_join(filename)
	err = document.write_to_filesystem(state, path)
	if err != OK:
		push_error("GLTF write failed: %s" % err)
	else:
		print("GFX_Q wrote %s" % path)
	keep.queue_free()


func _build_keep(root: Node3D, castle: bool) -> void:
	# 4x4 Town Hall pad is 10 m. Keep sits inside it with a yard.
	_box(root, "CivicPlinth", Vector3(0.0, 0.17, 0.0), Vector3(7.20, 0.34, 6.20), "stone")
	_box(root, "CivicWall_Keep", Vector3(0.0, 2.12, -0.10), Vector3(5.60, 3.55, 4.80), "stone")
	_box(root, "CivicPlaster_Upper", Vector3(0.0, 4.82, -0.12), Vector3(4.40, 2.00, 3.70), "plaster")
	# Hip / gable slate as geometry, not an atlas classify.
	_prism(root, "CivicRoof_Hall", Vector3(0.0, 6.72, -0.12), Vector3(4.90, 1.72, 4.00), "slate")
	_box(root, "CivicRoof_RidgeCap", Vector3(0.0, 7.52, -0.12), Vector3(0.22, 0.10, 3.70), "slate")
	# Front towers. Camera looks from +Z.
	_tower(root, "FL", Vector3(-2.90, 0.0, 2.48), castle)
	_tower(root, "FR", Vector3(2.90, 0.0, 2.48), castle)
	if castle:
		_tower(root, "BL", Vector3(-2.90, 0.0, -2.38), true)
		_tower(root, "BR", Vector3(2.90, 0.0, -2.38), true)
	_crenel_row(root, "Front", Vector3(0.0, 3.95, 2.28), 5.10, 0.0, 7)
	_crenel_row(root, "Back", Vector3(0.0, 3.95, -2.48), 5.10, 0.0, 7)
	_crenel_row(root, "West", Vector3(-2.78, 3.95, -0.10), 4.40, 90.0, 5)
	_crenel_row(root, "East", Vector3(2.78, 3.95, -0.10), 4.40, 90.0, 5)
	_door(root)
	_windows(root, castle)
	_timber(root)
	# Front stair / landing so the door reads from the gameplay camera.
	_box(root, "CivicPlinth_Stair", Vector3(0.0, 0.10, 3.05), Vector3(2.20, 0.20, 0.95), "stone")
	_box(root, "CivicPlinth_Step", Vector3(0.0, 0.22, 3.38), Vector3(1.70, 0.16, 0.42), "stone")


func _tower(root: Node3D, tag: String, origin: Vector3, tall: bool) -> void:
	var h := 5.55 if tall else 5.20
	_cyl(root, "CivicWall_Tower%s" % tag, origin + Vector3(0.0, h * 0.5, 0.0), 0.86, 0.80, h, "stone")
	_cyl(root, "CivicWall_Tower%sRing" % tag, origin + Vector3(0.0, h + 0.10, 0.0), 0.94, 0.94, 0.20, "stone")
	for i in 6:
		var a := float(i) * TAU / 6.0
		_box(root, "CivicCrenel_Tower%s_%d" % [tag, i],
			origin + Vector3(cos(a) * 0.82, h + 0.36, sin(a) * 0.82),
			Vector3(0.34, 0.38, 0.22), "stone")
	_cone(root, "CivicRoof_Cone%s" % tag, origin + Vector3(0.0, h + 1.05, 0.0), 0.92, 1.70, "slate")
	_box(root, "CivicTimber_Finial%s" % tag, origin + Vector3(0.0, h + 2.02, 0.0), Vector3(0.07, 0.42, 0.07), "timber")
	# Slit windows around the drum.
	for i in 3:
		var a := float(i) * TAU / 3.0 + 0.4
		_box(root, "CivicWindow_Tower%s_%d" % [tag, i],
			origin + Vector3(cos(a) * 0.82, 2.35 + float(i) * 0.85, sin(a) * 0.82),
			Vector3(0.18, 0.62, 0.10), "timber")


func _door(root: Node3D) -> void:
	_box(root, "CivicTimber_Lintel", Vector3(0.0, 2.28, 2.38), Vector3(1.55, 0.22, 0.22), "timber")
	_box(root, "CivicDoor", Vector3(0.0, 1.18, 2.42), Vector3(1.18, 1.95, 0.12), "timber")
	for i in 4:
		_box(root, "CivicDoor_Plank_%d" % i, Vector3(-0.42 + float(i) * 0.28, 1.18, 2.50), Vector3(0.16, 1.82, 0.05), "timber")
	_box(root, "CivicTimber_DoorFrameL", Vector3(-0.68, 1.22, 2.40), Vector3(0.16, 2.05, 0.16), "timber")
	_box(root, "CivicTimber_DoorFrameR", Vector3(0.68, 1.22, 2.40), Vector3(0.16, 2.05, 0.16), "timber")


func _windows(root: Node3D, castle: bool) -> void:
	var slits := [
		Vector3(-1.55, 2.55, 2.32), Vector3(1.55, 2.55, 2.32),
		Vector3(-1.55, 3.55, 2.32), Vector3(1.55, 3.55, 2.32),
		Vector3(-2.82, 2.40, 0.55), Vector3(-2.82, 3.35, -0.55),
		Vector3(2.82, 2.40, 0.55), Vector3(2.82, 3.35, -0.55),
		Vector3(-1.10, 5.15, 1.72), Vector3(1.10, 5.15, 1.72),
	]
	if castle:
		slits.append(Vector3(0.0, 2.70, -2.48))
		slits.append(Vector3(-1.40, 3.50, -2.48))
		slits.append(Vector3(1.40, 3.50, -2.48))
	var i := 0
	for p in slits:
		_box(root, "CivicWindow_%d" % i, p, Vector3(0.28, 0.72, 0.10), "timber")
		i += 1


func _timber(root: Node3D) -> void:
	for i in 4:
		var sx := -1.0 if i < 2 else 1.0
		var sz := -1.0 if i % 2 == 0 else 1.0
		_box(root, "CivicTimber_Corner_%d" % i,
			Vector3(sx * 2.72, 2.10, sz * 2.22),
			Vector3(0.18, 3.50, 0.18), "timber")
	_box(root, "CivicTimber_Plate", Vector3(0.0, 3.55, 2.34), Vector3(5.30, 0.12, 0.14), "timber")
	_box(root, "CivicTimber_Fascia", Vector3(0.0, 5.78, 1.78), Vector3(4.70, 0.14, 0.16), "timber")


func _crenel_row(root: Node3D, tag: String, center: Vector3, length: float, yaw_deg: float, count: int) -> void:
	for i in count:
		var t := (float(i) / float(maxi(count - 1, 1))) - 0.5
		var local := Vector3(t * length, 0.0, 0.0)
		if absf(yaw_deg) > 1.0:
			local = Vector3(0.0, 0.0, t * length)
		_box(root, "CivicCrenel_%s_%d" % [tag, i], center + local, Vector3(0.36, 0.42, 0.28), "stone")


func _box(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, kind: String) -> void:
	var inst := MeshInstance3D.new()
	inst.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	inst.mesh = mesh
	inst.position = pos
	inst.material_override = _mat(kind)
	parent.add_child(inst)


func _cyl(parent: Node3D, node_name: String, pos: Vector3, bottom_r: float, top_r: float, height: float, kind: String) -> void:
	var inst := MeshInstance3D.new()
	inst.name = node_name
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom_r
	mesh.top_radius = top_r
	mesh.height = height
	mesh.radial_segments = 14
	mesh.rings = 1
	inst.mesh = mesh
	inst.position = pos
	inst.material_override = _mat(kind)
	parent.add_child(inst)


func _cone(parent: Node3D, node_name: String, pos: Vector3, radius: float, height: float, kind: String) -> void:
	_cyl(parent, node_name, pos, radius, 0.02, height, kind)


func _prism(parent: Node3D, node_name: String, pos: Vector3, size: Vector3, kind: String) -> void:
	var inst := MeshInstance3D.new()
	inst.name = node_name
	var mesh := PrismMesh.new()
	mesh.size = size
	inst.mesh = mesh
	inst.position = pos
	inst.material_override = _mat(kind)
	parent.add_child(inst)


func _mat(kind: String) -> StandardMaterial3D:
	if _mats.has(kind):
		return _mats[kind]
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.roughness = 0.90
	material.metallic = 0.0
	match kind:
		"slate":
			material.albedo_color = Color("#456B68")
		"timber":
			material.albedo_color = Color("#5F442F")
		"plaster":
			material.albedo_color = Color("#E0D0B2")
		_:
			material.albedo_color = Color("#CDBFA2")
	_mats[kind] = material
	return material


func _measure(root: Node3D) -> AABB:
	var aabb := AABB()
	var first := true
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var inst := node as MeshInstance3D
		if inst == null or inst.mesh == null:
			continue
		var local: AABB = inst.transform * inst.mesh.get_aabb()
		if first:
			aabb = local
			first = false
		else:
			aabb = aabb.merge(local)
	return aabb
