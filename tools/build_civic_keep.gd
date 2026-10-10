extends SceneTree

## The Director: GFX-S. Purpose-built limestone keep as live Town Hall
## / Castle. Gatehouse is articulated: buttresses, recesses, arch,
## string courses, slit windows, timber trim, herald. Authored at
## world metres, origin on the ground centre, door facing +Z.

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
	print("GFX_S keep castle=%s aabb=%s" % [str(castle), str(aabb.size)])
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
		print("GFX_S wrote %s" % path)
	keep.queue_free()


func _build_keep(root: Node3D, castle: bool) -> void:
	# GFX-U: front wall is three sections, not one flat slab. Camera +Z.
	# CivicWall_Keep stays as the body. Front L / C / R read at 720p.
	_box(root, "CivicPlinth", Vector3(0.0, 0.18, 0.05), Vector3(7.35, 0.36, 6.35), "stone")
	_box(root, "CivicWall_Keep", Vector3(-0.15, 2.18, -0.42), Vector3(5.85, 3.85, 4.35), "stone")
	_box(root, "CivicWall_FrontL", Vector3(-1.95, 2.05, 2.42), Vector3(1.95, 3.65, 0.85), "stone")
	_box(root, "CivicWall_FrontC", Vector3(0.0, 3.22, 2.52), Vector3(2.15, 1.55, 0.72), "stone")
	_box(root, "CivicWall_FrontR", Vector3(1.75, 2.05, 2.42), Vector3(1.95, 3.65, 0.85), "stone")
	_box(root, "CivicGate", Vector3(0.0, 1.95, 2.78), Vector3(2.35, 3.55, 1.85), "stone")
	_box(root, "CivicGate_Arch", Vector3(0.0, 3.72, 3.28), Vector3(2.15, 0.78, 1.15), "stone")
	_box(root, "CivicRecess_Gate", Vector3(0.0, 1.52, 3.52), Vector3(1.58, 2.72, 0.92), "recess")
	_facade(root)
	_door(root)
	# Level 2 — hall wing (west) and chapel wing (east). Two roof masses.
	_box(root, "CivicWall_Wing", Vector3(-1.55, 4.55, 0.20), Vector3(3.35, 2.15, 3.45), "plaster")
	_prism(root, "CivicRoof_Hall", Vector3(-1.50, 6.28, 0.20), Vector3(3.85, 1.38, 3.85), "slate")
	_box(root, "CivicRoof_RidgeHall", Vector3(-1.50, 6.98, 0.20), Vector3(0.18, 0.10, 3.55), "slate")
	_box(root, "CivicWall_Chapel", Vector3(1.55, 4.35, 0.35), Vector3(2.35, 1.75, 2.55), "stone")
	_prism(root, "CivicRoof_Wing", Vector3(1.55, 5.85, 0.35), Vector3(2.65, 1.18, 2.85), "slate")
	# Level 3 — raised keep sits above both wings.
	_box(root, "CivicWall_KeepRaised", Vector3(0.05, 6.55, -0.85), Vector3(3.25, 3.05, 3.15), "stone")
	_box(root, "CivicPlaster_Upper", Vector3(0.05, 7.55, -0.85), Vector3(2.85, 1.35, 2.75), "plaster")
	_prism(root, "CivicRoof_Keep", Vector3(0.05, 8.85, -0.85), Vector3(3.55, 1.58, 3.35), "slate")
	_box(root, "CivicRoof_RidgeCap", Vector3(0.05, 9.64, -0.85), Vector3(0.20, 0.10, 3.05), "slate")
	_crenel_row(root, "Keep", Vector3(0.05, 8.02, 0.68), 3.05, 0.0, 5)
	# Battlements on the curtain, readable at 720p.
	_crenel_row(root, "Front", Vector3(0.0, 4.18, 2.42), 5.35, 0.0, 7)
	_crenel_row(root, "Back", Vector3(0.0, 4.18, -2.52), 5.35, 0.0, 7)
	_crenel_row(root, "West", Vector3(-2.95, 4.18, -0.05), 4.55, 90.0, 5)
	_crenel_row(root, "East", Vector3(2.65, 4.18, -0.05), 4.55, 90.0, 5)
	# Short front-left turret. Tall asymmetric tower on the camera-right.
	_tower(root, "FL", Vector3(-2.95, 0.0, 2.42), false)
	_tall_tower(root, Vector3(2.88, 0.0, 1.42))
	if castle:
		_tower(root, "BL", Vector3(-2.85, 0.0, -2.42), true)
		_tower(root, "BR", Vector3(2.55, 0.0, -2.42), true)
	_windows(root, castle)
	_timber(root)
	_box(root, "CivicPlinth_Stair", Vector3(0.0, 0.12, 3.18), Vector3(2.35, 0.22, 1.05), "stone")
	_box(root, "CivicPlinth_Step", Vector3(0.0, 0.24, 3.52), Vector3(1.85, 0.16, 0.46), "stone")
	_box(root, "CivicPlinth_Base", Vector3(0.0, 0.28, 2.72), Vector3(6.15, 0.52, 0.55), "stone")


func _tower(root: Node3D, tag: String, origin: Vector3, tall: bool) -> void:
	var h := 6.15 if tall else 5.35
	_cyl(root, "CivicWall_Tower%s" % tag, origin + Vector3(0.0, h * 0.5, 0.0), 0.88, 0.80, h, "stone")
	_cyl(root, "CivicWall_Tower%sRing" % tag, origin + Vector3(0.0, h + 0.10, 0.0), 0.96, 0.96, 0.20, "stone")
	for i in 6:
		var a := float(i) * TAU / 6.0
		_box(root, "CivicCrenel_Tower%s_%d" % [tag, i],
			origin + Vector3(cos(a) * 0.84, h + 0.36, sin(a) * 0.84),
			Vector3(0.34, 0.40, 0.22), "stone")
	_cone(root, "CivicRoof_Cone%s" % tag, origin + Vector3(0.0, h + 1.05, 0.0), 0.94, 1.70, "slate")
	_box(root, "CivicTimber_Finial%s" % tag, origin + Vector3(0.0, h + 2.02, 0.0), Vector3(0.07, 0.42, 0.07), "timber")
	for i in 3:
		var a := float(i) * TAU / 3.0 + 0.4
		_box(root, "CivicWindow_Tower%s_%d" % [tag, i],
			origin + Vector3(cos(a) * 0.84, 2.35 + float(i) * 0.85, sin(a) * 0.84),
			Vector3(0.20, 0.68, 0.12), "recess")


func _tall_tower(root: Node3D, origin: Vector3) -> void:
	# Asymmetric landmark. Three storeys above the curtain, banner on top.
	var h := 9.55
	_cyl(root, "CivicWall_TowerTall", origin + Vector3(0.0, h * 0.5, 0.0), 1.08, 0.96, h, "stone")
	_cyl(root, "CivicWall_TowerTallRing", origin + Vector3(0.0, h + 0.12, 0.0), 1.16, 1.16, 0.24, "stone")
	for i in 7:
		var a := float(i) * TAU / 7.0
		_box(root, "CivicCrenel_TowerTall_%d" % i,
			origin + Vector3(cos(a) * 1.02, h + 0.42, sin(a) * 1.02),
			Vector3(0.38, 0.46, 0.24), "stone")
	_cone(root, "CivicRoof_ConeTall", origin + Vector3(0.0, h + 1.28, 0.0), 1.12, 2.15, "slate")
	_box(root, "CivicTimber_FinialTall", origin + Vector3(0.0, h + 2.48, 0.0), Vector3(0.08, 0.55, 0.08), "timber")
	_box(root, "CivicBanner_Pole", origin + Vector3(0.42, h + 2.05, 0.18), Vector3(0.07, 1.85, 0.07), "timber")
	_box(root, "CivicBanner", origin + Vector3(1.12, h + 2.28, 0.18), Vector3(1.42, 0.98, 0.07), "banner")
	for i in 4:
		var a := float(i) * TAU / 4.0 + 0.55
		_box(root, "CivicWindow_TowerTall_%d" % i,
			origin + Vector3(cos(a) * 1.02, 2.55 + float(i) * 1.45, sin(a) * 1.02),
			Vector3(0.24, 0.82, 0.14), "recess")


func _facade(root: Node3D) -> void:
	# GFX-U: recessed panels and projecting supports on the three
	# front sections. Deep portal. Large herald on the gatehouse.
	_box(root, "CivicButtress_L", Vector3(-1.05, 2.05, 2.95), Vector3(0.52, 3.85, 0.78), "stone")
	_box(root, "CivicButtress_R", Vector3(1.05, 2.05, 2.95), Vector3(0.52, 3.85, 0.78), "stone")
	_box(root, "CivicButtress_FarL", Vector3(-2.72, 1.85, 2.72), Vector3(0.42, 3.45, 0.58), "stone")
	_box(root, "CivicButtress_FarR", Vector3(2.55, 1.85, 2.72), Vector3(0.42, 3.45, 0.58), "stone")
	_box(root, "CivicFacade_Recess_L", Vector3(-1.95, 2.35, 2.88), Vector3(1.35, 2.15, 0.42), "recess")
	_box(root, "CivicFacade_Recess_R", Vector3(1.75, 2.35, 2.88), Vector3(1.35, 2.15, 0.42), "recess")
	_box(root, "CivicString_Course", Vector3(0.0, 3.95, 2.82), Vector3(5.55, 0.16, 0.28), "stone")
	_box(root, "CivicString_Low", Vector3(0.0, 1.15, 2.82), Vector3(5.35, 0.14, 0.24), "stone")
	_box(root, "CivicWindow_Gate_L", Vector3(-0.95, 2.85, 3.28), Vector3(0.28, 0.95, 0.18), "recess")
	_box(root, "CivicWindow_Gate_R", Vector3(0.95, 2.85, 3.28), Vector3(0.28, 0.95, 0.18), "recess")
	_box(root, "CivicHerald_Pole", Vector3(-0.95, 4.85, 3.12), Vector3(0.08, 1.35, 0.08), "timber")
	_box(root, "CivicHerald", Vector3(0.18, 4.95, 3.18), Vector3(1.85, 1.28, 0.08), "banner")
	_box(root, "CivicTimber_GateTrimL", Vector3(-0.95, 1.55, 3.58), Vector3(0.16, 2.65, 0.16), "timber")
	_box(root, "CivicTimber_GateTrimR", Vector3(0.95, 1.55, 3.58), Vector3(0.16, 2.65, 0.16), "timber")


func _door(root: Node3D) -> void:
	_box(root, "CivicTimber_Lintel", Vector3(0.0, 2.48, 3.62), Vector3(1.68, 0.26, 0.28), "timber")
	_box(root, "CivicDoor", Vector3(0.0, 1.22, 3.68), Vector3(1.22, 2.05, 0.14), "timber")
	for i in 4:
		_box(root, "CivicDoor_Plank_%d" % i, Vector3(-0.44 + float(i) * 0.29, 1.22, 3.76), Vector3(0.16, 1.92, 0.05), "timber")
	_box(root, "CivicTimber_DoorFrameL", Vector3(-0.72, 1.28, 3.66), Vector3(0.16, 2.15, 0.16), "timber")
	_box(root, "CivicTimber_DoorFrameR", Vector3(0.72, 1.28, 3.66), Vector3(0.16, 2.15, 0.16), "timber")


func _windows(root: Node3D, castle: bool) -> void:
	# Dark recesses, not flush limestone. Must read at 1280×720.
	var slits := [
		Vector3(-1.15, 2.55, 2.48), Vector3(1.15, 2.55, 2.48),
		Vector3(-1.15, 3.55, 2.48), Vector3(1.15, 3.55, 2.48),
		Vector3(-3.05, 2.45, 0.55), Vector3(-3.05, 3.40, -0.55),
		Vector3(2.75, 2.45, -0.35), Vector3(-1.05, 6.85, 0.68),
		Vector3(1.15, 6.85, 0.68), Vector3(0.05, 7.55, 0.70),
	]
	if castle:
		slits.append(Vector3(0.0, 2.70, -2.55))
		slits.append(Vector3(-1.40, 3.50, -2.55))
		slits.append(Vector3(1.40, 3.50, -2.55))
	var i := 0
	for p in slits:
		_box(root, "CivicWindow_%d" % i, p, Vector3(0.36, 0.82, 0.14), "recess")
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
		"recess":
			material.albedo_color = Color("#3A3228")
		"banner":
			material.albedo_color = Color("#8B2E3A")
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
