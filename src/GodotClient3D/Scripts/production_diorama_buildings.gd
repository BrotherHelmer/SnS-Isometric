class_name ProductionDioramaBuildings
extends RefCounted

## M1 diorama-world: approved Nordic diorama building family for the
## founding-loop types (TOWN_HALL castle-family, HOUSE + LUMBER_CAMP
## cottage-family), adapted from art_test/nordic_diorama. Smooth-shaded
## sculpted primitives with the painted diorama textures, merged into one
## mesh per material so each building costs a handful of draw calls.
## Authored in metres; the returned root is pre-scaled to the footprint.

const Catalog = preload("res://src/GodotClient3D/Scripts/production_asset_catalog.gd")

static var _mat_cache := {}


static func build(building_type: String, seed_id: int) -> Node3D:
	match building_type:
		"TOWN_HALL":
			return _build_town_hall()
		"CASTLE":
			return _build_castle()
		"HOUSE":
			return _build_house(seed_id)
		"LUMBER_CAMP":
			return _build_lumber_camp()
		"SAWMILL":
			return _build_sawmill()
		"FARM":
			return _build_farm()
		"BAKERY":
			return _build_bakery()
		"STOREHOUSE":
			return _build_storehouse()
		"QUARRY":
			return _build_quarry()
		"WATCHTOWER":
			return _build_watchtower()
		"BARRACKS":
			return _build_barracks()
	return Node3D.new()


static func _tex_mat(key: String, tint: Color, uv: float) -> StandardMaterial3D:
	var cache_key := "tex:" + key + "@" + str(uv) + tint.to_html()
	if _mat_cache.has(cache_key):
		return _mat_cache[cache_key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(Catalog.DIORAMA_TEXTURES[key]) as Texture2D
	m.albedo_color = tint
	m.uv1_scale = Vector3(uv, uv, uv)
	m.roughness = 0.95
	_mat_cache[cache_key] = m
	return m


static func _plain_mat(key: String, c: Color) -> StandardMaterial3D:
	var cache_key := "plain:" + key
	if _mat_cache.has(cache_key):
		return _mat_cache[cache_key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.95
	_mat_cache[cache_key] = m
	return m


static func _stone() -> StandardMaterial3D:
	return _tex_mat("stone", Color(0.95, 0.94, 0.90), 1.6)


static func _thatch() -> StandardMaterial3D:
	return _tex_mat("thatch", Color(1, 1, 1), 1.3)


class Batch:
	var data := {}

	func add(mesh: Mesh, mat: Material, tr: Transform3D) -> void:
		var arrays := mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if not data.has(mat):
			data[mat] = {
				"v": PackedVector3Array(),
				"n": PackedVector3Array(),
				"uv": PackedVector2Array(),
				"idx": PackedInt32Array(),
			}
		var d: Dictionary = data[mat]
		var bv: PackedVector3Array = d["v"]
		var bn: PackedVector3Array = d["n"]
		var buv: PackedVector2Array = d["uv"]
		var bi: PackedInt32Array = d["idx"]
		var base := bv.size()
		var nm := tr.basis.inverse().transposed()
		for i in range(verts.size()):
			bv.append(tr * verts[i])
			bn.append((nm * normals[i]).normalized())
			if i < uvs.size():
				buv.append(uvs[i])
			else:
				buv.append(Vector2.ZERO)
		for i in range(idx.size()):
			bi.append(base + idx[i])
		d["v"] = bv
		d["n"] = bn
		d["uv"] = buv
		d["idx"] = bi

	func build_mesh() -> ArrayMesh:
		var am := ArrayMesh.new()
		for mat in data.keys():
			var d: Dictionary = data[mat]
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = d["v"]
			arrays[Mesh.ARRAY_NORMAL] = d["n"]
			arrays[Mesh.ARRAY_TEX_UV] = d["uv"]
			arrays[Mesh.ARRAY_INDEX] = d["idx"]
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			am.surface_set_material(am.get_surface_count() - 1, mat)
		return am

	func build_root(root_name: String) -> Node3D:
		var root := Node3D.new()
		root.name = root_name
		for mat in data.keys():
			var d: Dictionary = data[mat]
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = d["v"]
			arrays[Mesh.ARRAY_NORMAL] = d["n"]
			arrays[Mesh.ARRAY_TEX_UV] = d["uv"]
			arrays[Mesh.ARRAY_INDEX] = d["idx"]
			var am := ArrayMesh.new()
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			var mi := MeshInstance3D.new()
			mi.mesh = am
			mi.material_override = mat
			root.add_child(mi)
		return root


static func _box(b: Batch, mat: Material, size: Vector3, pos: Vector3, ry: float = 0.0) -> void:
	var m := BoxMesh.new()
	m.size = size
	b.add(m, mat, Transform3D(Basis(Vector3.UP, ry), pos))


static func _cyl(b: Batch, mat: Material, rt: float, rb: float, h: float, pos: Vector3, seg: int = 20, tilt: Basis = Basis.IDENTITY) -> void:
	var m := CylinderMesh.new()
	m.top_radius = rt
	m.bottom_radius = rb
	m.height = h
	m.radial_segments = seg
	b.add(m, mat, Transform3D(tilt, pos))


static func _roof_prism(b: Batch, mat: Material, size: Vector3, pos: Vector3) -> void:
	var m := PrismMesh.new()
	m.size = size
	b.add(m, mat, Transform3D(Basis(Vector3.UP, PI * 0.5), pos))


static func _sculpted_rock(b: Batch, mat: Material, radius: float, seed_off: Vector3, pos: Vector3, scl: Vector3, amp: float = 0.16) -> void:
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 24
	sm.rings = 16
	var arrays := sm.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var nz := FastNoiseLite.new()
	nz.seed = 31
	nz.frequency = 0.35
	for i in range(verts.size()):
		var v := verts[i]
		var pp := v * 1.4 + seed_off
		var d: float = radius * amp * (nz.get_noise_3dv(pp * 0.5) * 0.75 + nz.get_noise_3dv(pp * 1.2 + Vector3(4, 2, 6)) * 0.25)
		verts[i] = v + norms[i] * d
	var acc := PackedVector3Array()
	acc.resize(verts.size())
	for f in range(0, idx.size(), 3):
		var ia := idx[f]
		var ib := idx[f + 1]
		var ic := idx[f + 2]
		var fn := (verts[ib] - verts[ia]).cross(verts[ic] - verts[ia])
		acc[ia] += fn
		acc[ib] += fn
		acc[ic] += fn
	for i in range(verts.size()):
		norms[i] = acc[i].normalized()
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	b.add(am, mat, Transform3D(Basis().scaled(scl), pos))


static func _ball(b: Batch, mat: Material, r: float, pos: Vector3, scl: Vector3) -> void:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 14
	sm.rings = 10
	b.add(sm, mat, Transform3D(Basis().scaled(scl), pos))


static func _rockface() -> StandardMaterial3D:
	return _tex_mat("stone", Color(0.80, 0.78, 0.74), 2.4)


static func _build_town_hall() -> Node3D:
	var b := Batch.new()
	var stone := _stone()
	var terra := _plain_mat("terra", Color(0.60, 0.31, 0.24))
	var wood_dark := _plain_mat("wood_dark", Color(0.38, 0.29, 0.21))
	var dark := _plain_mat("dark", Color(0.16, 0.12, 0.10))
	_box(b, stone, Vector3(8.6, 4.6, 6.4), Vector3(0, 2.3, -0.6))
	_box(b, stone, Vector3(9.4, 0.7, 7.2), Vector3(0, 4.85, -0.6))
	for bx in [-4.2, -2.5, -0.8, 0.8, 2.5, 4.2]:
		_box(b, stone, Vector3(0.85, 0.85, 0.85), Vector3(bx, 5.6, -3.6))
		_box(b, stone, Vector3(0.85, 0.85, 0.85), Vector3(bx, 5.6, 2.4))
	_cyl(b, stone, 1.75, 1.95, 8.6, Vector3(-4.6, 4.3, 1.8), 22)
	_cyl(b, stone, 1.75, 1.95, 8.6, Vector3(3.4, 4.3, 1.8), 22)
	_cyl(b, stone, 2.05, 2.25, 10.6, Vector3(-0.6, 5.3, -3.4), 22)
	_cyl(b, terra, 0.03, 2.6, 3.6, Vector3(-4.6, 10.4, 1.8), 22)
	_cyl(b, terra, 0.03, 2.6, 3.6, Vector3(3.4, 10.4, 1.8), 22)
	_cyl(b, terra, 0.03, 3.1, 4.4, Vector3(-0.6, 12.8, -3.4), 22)
	_roof_prism(b, terra, Vector3(5.4, 2.6, 7.4), Vector3(0, 6.5, -0.6))
	_box(b, wood_dark, Vector3(1.7, 2.9, 0.35), Vector3(-0.6, 1.45, 2.65))
	_box(b, stone, Vector3(2.3, 0.35, 0.9), Vector3(-0.6, 0.18, 3.1))
	for tpos in [Vector3(-4.6, 5.6, 3.15), Vector3(3.4, 5.6, 3.15), Vector3(-0.6, 7.6, -1.35), Vector3(-1.9, 3.2, 2.65), Vector3(1.6, 3.2, 2.65)]:
		_box(b, dark, Vector3(0.42, 0.62, 0.3), tpos)
	var root := b.build_root("DioramaTownHall")
	root.scale = Vector3.ONE * 0.76
	return root


static func _cottage(b: Batch, wall_mat: Material, roof_mat: Material, kind: int) -> void:
	var stone := _stone()
	var wood_dark := _plain_mat("wood_dark", Color(0.38, 0.29, 0.21))
	var dark := _plain_mat("dark", Color(0.16, 0.12, 0.10))
	_box(b, wall_mat, Vector3(5.4, 2.9, 4.4), Vector3(0, 1.45, 0))
	if kind == 0:
		for bx in [-2.68, 2.68]:
			_box(b, wood_dark, Vector3(0.28, 2.9, 4.44), Vector3(bx, 1.45, 0))
		_box(b, wood_dark, Vector3(5.44, 0.26, 4.44), Vector3(0, 2.85, 0))
	if kind == 2:
		_box(b, stone, Vector3(5.5, 0.5, 4.5), Vector3(0, 0.25, 0))
	_roof_prism(b, roof_mat, Vector3(5.3, 2.5, 6.3), Vector3(0, 4.05, 0))
	_box(b, stone, Vector3(0.7, 1.5, 0.7), Vector3(1.7, 5.3, -0.9))
	_box(b, wood_dark, Vector3(1.1, 2.0, 0.25), Vector3(-0.9, 1.0, 2.24))
	_box(b, dark, Vector3(0.62, 0.62, 0.2), Vector3(1.2, 1.7, 2.24))
	_box(b, dark, Vector3(0.62, 0.62, 0.2), Vector3(-2.0, 1.7, 2.24))


static func _build_house(seed_id: int) -> Node3D:
	var b := Batch.new()
	var variant := absi(seed_id) % 3
	if variant == 0:
		_cottage(b, _plain_mat("plaster", Color(0.90, 0.86, 0.78)), _thatch(), 0)
	elif variant == 1:
		_cottage(b, _stone(), _plain_mat("slate", Color(0.40, 0.46, 0.54)), 1)
	else:
		_cottage(b, _plain_mat("wood", Color(0.52, 0.40, 0.29)), _plain_mat("terra", Color(0.60, 0.31, 0.24)), 2)
	var root := b.build_root("DioramaHouse")
	root.scale = Vector3.ONE * 0.88
	return root


static func _build_lumber_camp() -> Node3D:
	var b := Batch.new()
	var wood := _plain_mat("wood", Color(0.52, 0.40, 0.29))
	var wood_dark := _plain_mat("wood_dark", Color(0.38, 0.29, 0.21))
	var log_mat := _plain_mat("log", Color(0.62, 0.50, 0.36))
	_cottage(b, wood, _plain_mat("terra", Color(0.60, 0.31, 0.24)), 2)
	var log_tilt := Basis(Vector3.FORWARD, PI * 0.5)
	_cyl(b, log_mat, 0.26, 0.26, 2.4, Vector3(2.6, 0.27, 1.5), 12, log_tilt)
	_cyl(b, log_mat, 0.26, 0.26, 2.4, Vector3(2.6, 0.27, 2.05), 12, log_tilt)
	_cyl(b, log_mat, 0.26, 0.26, 2.4, Vector3(2.6, 0.76, 1.78), 12, log_tilt)
	_cyl(b, wood_dark, 0.34, 0.38, 0.42, Vector3(-2.4, 0.21, 1.6), 12)
	_cyl(b, wood_dark, 0.30, 0.34, 0.36, Vector3(-1.7, 0.18, 2.1), 12)
	_box(b, log_mat, Vector3(1.9, 0.14, 0.55), Vector3(-2.2, 0.35, -1.4), 0.22)
	_box(b, log_mat, Vector3(1.9, 0.14, 0.55), Vector3(-2.2, 0.5, -1.4), 0.22)
	var root := b.build_root("DioramaLumberCamp")
	root.scale = Vector3.ONE * 1.02
	return root


static func _build_castle() -> Node3D:
	var root := _build_town_hall()
	root.name = "DioramaCastle"
	root.scale = Vector3.ONE * 0.95
	var terra := _plain_mat("terra", Color(0.60, 0.31, 0.24))
	var wood_dark := _plain_mat("wood_dark", Color(0.38, 0.29, 0.21))
	for px in [-4.6, 3.4]:
		var pole := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.05
		cm.bottom_radius = 0.05
		cm.height = 1.6
		cm.radial_segments = 8
		pole.mesh = cm
		pole.position = Vector3(px, 12.9, 1.8)
		pole.material_override = wood_dark
		root.add_child(pole)
		var flag := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.85, 0.42, 0.05)
		flag.mesh = bm
		flag.position = Vector3(px + 0.42, 13.5, 1.8)
		flag.material_override = terra
		root.add_child(flag)
	return root


static func _build_sawmill() -> Node3D:
	var b := Batch.new()
	var wood := _plain_mat("wood", Color(0.52, 0.40, 0.29))
	var log_mat := _plain_mat("log", Color(0.62, 0.50, 0.36))
	var dark := _plain_mat("dark", Color(0.16, 0.12, 0.10))
	_cottage(b, wood, _plain_mat("terra", Color(0.60, 0.31, 0.24)), 2)
	var disc_tilt := Basis(Vector3.RIGHT, PI * 0.5)
	_cyl(b, dark, 0.85, 0.85, 0.14, Vector3(1.9, 1.35, 2.55), 24, disc_tilt)
	_box(b, _plain_mat("wood_dark", Color(0.38, 0.29, 0.21)), Vector3(0.18, 1.5, 0.18), Vector3(1.35, 0.75, 2.5))
	_box(b, _plain_mat("wood_dark", Color(0.38, 0.29, 0.21)), Vector3(0.18, 1.5, 0.18), Vector3(2.45, 0.75, 2.5))
	var log_tilt := Basis(Vector3.FORWARD, PI * 0.5)
	_cyl(b, log_mat, 0.24, 0.24, 2.6, Vector3(-2.5, 0.25, 1.9), 12, log_tilt)
	_cyl(b, log_mat, 0.24, 0.24, 2.6, Vector3(-2.5, 0.25, 2.42), 12, log_tilt)
	_cyl(b, log_mat, 0.24, 0.24, 2.6, Vector3(-2.5, 0.68, 2.16), 12, log_tilt)
	var root := b.build_root("DioramaSawmill")
	root.scale = Vector3.ONE * 1.18
	return root


static func _build_farm() -> Node3D:
	var b := Batch.new()
	var stone := _stone()
	var wood := _plain_mat("wood", Color(0.52, 0.40, 0.29))
	var wood_dark := _plain_mat("wood_dark", Color(0.38, 0.29, 0.21))
	var terra := _plain_mat("terra", Color(0.60, 0.31, 0.24))
	var hay := _plain_mat("hay", Color(0.76, 0.64, 0.36))
	_box(b, stone, Vector3(7.6, 1.2, 5.2), Vector3(0, 0.6, 0))
	_box(b, wood, Vector3(7.6, 2.2, 5.2), Vector3(0, 2.3, 0))
	_roof_prism(b, terra, Vector3(6.2, 2.8, 8.4), Vector3(0, 4.7, 0))
	_box(b, wood_dark, Vector3(1.6, 2.2, 0.25), Vector3(-1.2, 1.1, 2.62))
	_cyl(b, stone, 0.95, 1.0, 5.2, Vector3(4.35, 2.6, -1.2), 18)
	_cyl(b, terra, 0.03, 1.2, 1.2, Vector3(4.35, 5.75, -1.2), 18)
	for fx in [-3.4, -1.8, 1.8, 3.4]:
		_box(b, wood_dark, Vector3(0.14, 0.95, 0.14), Vector3(fx, 0.48, 3.6))
	_box(b, wood_dark, Vector3(5.6, 0.1, 0.08), Vector3(-2.6, 0.62, 3.6))
	_box(b, wood_dark, Vector3(5.6, 0.1, 0.08), Vector3(2.6, 0.62, 3.6))
	_box(b, hay, Vector3(0.95, 0.62, 0.62), Vector3(2.9, 0.31, 2.6), 0.3)
	_box(b, hay, Vector3(0.95, 0.62, 0.62), Vector3(2.85, 0.92, 2.55), 0.15)
	var root := b.build_root("DioramaFarm")
	root.scale = Vector3.ONE * 0.92
	return root


static func _build_bakery() -> Node3D:
	var b := Batch.new()
	var plaster := _plain_mat("plaster", Color(0.90, 0.86, 0.78))
	_cottage(b, _stone(), _plain_mat("terra", Color(0.60, 0.31, 0.24)), 1)
	_box(b, _stone(), Vector3(0.62, 1.3, 0.62), Vector3(-1.7, 5.2, -0.9))
	_ball(b, plaster, 0.42, Vector3(2.35, 0.3, 2.3), Vector3(1, 0.72, 1))
	_ball(b, plaster, 0.38, Vector3(1.85, 0.27, 2.45), Vector3(1, 0.72, 1))
	_ball(b, plaster, 0.36, Vector3(2.1, 0.72, 2.35), Vector3(1, 0.72, 1))
	_box(b, _plain_mat("wood_dark", Color(0.38, 0.29, 0.21)), Vector3(2.3, 0.1, 1.05), Vector3(-0.9, 2.32, 2.6))
	var root := b.build_root("DioramaBakery")
	root.scale = Vector3.ONE * 1.18
	return root


static func _build_storehouse() -> Node3D:
	var b := Batch.new()
	var wood := _plain_mat("wood", Color(0.52, 0.40, 0.29))
	var wood_dark := _plain_mat("wood_dark", Color(0.38, 0.29, 0.21))
	var stone := _stone()
	_box(b, stone, Vector3(8.8, 0.55, 5.4), Vector3(0, 0.28, 0))
	_box(b, wood, Vector3(8.8, 2.9, 5.4), Vector3(0, 2.0, 0))
	_roof_prism(b, _plain_mat("slate", Color(0.40, 0.46, 0.54)), Vector3(6.4, 2.6, 9.6), Vector3(0, 4.6, 0))
	_box(b, wood_dark, Vector3(1.5, 2.3, 0.22), Vector3(-0.85, 1.15, 2.78))
	_box(b, wood_dark, Vector3(1.5, 2.3, 0.22), Vector3(0.85, 1.15, 2.78))
	_box(b, wood_dark, Vector3(0.85, 0.85, 0.85), Vector3(3.9, 0.43, 2.9))
	_box(b, wood_dark, Vector3(0.85, 0.85, 0.85), Vector3(3.9, 1.28, 2.9), 0.4)
	_cyl(b, wood_dark, 0.33, 0.36, 0.78, Vector3(-3.9, 0.39, 2.85), 12)
	_cyl(b, wood_dark, 0.33, 0.36, 0.78, Vector3(-3.25, 0.39, 2.95), 12)
	var root := b.build_root("DioramaStorehouse")
	return root


static func _build_quarry() -> Node3D:
	var b := Batch.new()
	var stone := _stone()
	var rockface := _rockface()
	var wood_dark := _plain_mat("wood_dark", Color(0.38, 0.29, 0.21))
	_sculpted_rock(b, rockface, 3.4, Vector3(3, 1, 2), Vector3(0, 0.4, -1.7), Vector3(1.15, 0.85, 0.8))
	_sculpted_rock(b, rockface, 2.1, Vector3(7, 3, 1), Vector3(-2.7, 0.2, -0.6), Vector3(1.05, 0.7, 0.95))
	_sculpted_rock(b, rockface, 1.05, Vector3(9, 2, 5), Vector3(2.5, 0.05, 0.7), Vector3(1.25, 0.55, 1.1))
	_box(b, stone, Vector3(0.88, 0.62, 0.62), Vector3(1.7, 0.31, 2.2))
	_box(b, stone, Vector3(0.88, 0.62, 0.62), Vector3(1.72, 0.93, 2.18), 0.2)
	_box(b, stone, Vector3(0.88, 0.62, 0.62), Vector3(2.65, 0.31, 2.3), 0.45)
	_box(b, wood_dark, Vector3(0.22, 2.7, 0.22), Vector3(-0.6, 1.35, 1.6))
	_box(b, wood_dark, Vector3(0.22, 2.7, 0.22), Vector3(1.5, 1.35, 1.6))
	_box(b, wood_dark, Vector3(2.6, 0.24, 0.24), Vector3(0.45, 2.75, 1.6))
	var root := b.build_root("DioramaQuarry")
	root.scale = Vector3.ONE * 0.95
	return root


static func _build_watchtower() -> Node3D:
	var b := Batch.new()
	var wood := _plain_mat("wood", Color(0.52, 0.40, 0.29))
	var wood_dark := _plain_mat("wood_dark", Color(0.38, 0.29, 0.21))
	var dark := _plain_mat("dark", Color(0.16, 0.12, 0.10))
	# Painted family materials: stone plinth under the timber legs and a
	# thatched cap, like the cottages (timber itself stays flat-toned).
	_box(b, _stone(), Vector3(2.5, 0.5, 2.5), Vector3(0, 0.25, 0))
	for lx in [-0.72, 0.72]:
		for lz in [-0.72, 0.72]:
			_box(b, wood_dark, Vector3(0.2, 4.4, 0.2), Vector3(lx, 2.2, lz))
	_box(b, wood_dark, Vector3(1.7, 0.14, 0.14), Vector3(0, 1.5, 0.72))
	_box(b, wood_dark, Vector3(1.7, 0.14, 0.14), Vector3(0, 3.1, -0.72))
	_box(b, wood, Vector3(2.35, 0.22, 2.35), Vector3(0, 4.5, 0))
	_box(b, wood, Vector3(1.95, 1.5, 1.95), Vector3(0, 5.35, 0))
	_box(b, dark, Vector3(0.55, 0.6, 0.15), Vector3(0, 5.4, 1.0))
	_cyl(b, _thatch(), 0.04, 1.8, 1.55, Vector3(0, 6.85, 0), 4, Basis(Vector3.UP, PI * 0.25))
	var root := b.build_root("DioramaWatchtower")
	return root


static func _build_barracks() -> Node3D:
	var b := Batch.new()
	var stone := _stone()
	var wood_dark := _plain_mat("wood_dark", Color(0.38, 0.29, 0.21))
	var dark := _plain_mat("dark", Color(0.16, 0.12, 0.10))
	var terra := _plain_mat("terra", Color(0.60, 0.31, 0.24))
	_box(b, stone, Vector3(8.8, 3.4, 5.0), Vector3(0, 1.7, 0))
	_roof_prism(b, terra, Vector3(6.2, 2.6, 9.6), Vector3(0, 4.6, 0))
	_box(b, wood_dark, Vector3(1.3, 2.4, 0.22), Vector3(-2.2, 1.2, 2.55))
	_box(b, wood_dark, Vector3(1.3, 2.4, 0.22), Vector3(2.2, 1.2, 2.55))
	for wx in [-3.6, 0.0, 3.6]:
		_box(b, dark, Vector3(0.6, 0.6, 0.15), Vector3(wx, 2.2, 2.55))
	_cyl(b, wood_dark, 0.05, 0.05, 3.6, Vector3(4.9, 1.8, 2.2), 8)
	_box(b, terra, Vector3(0.75, 0.42, 0.05), Vector3(5.28, 3.3, 2.2))
	var root := b.build_root("DioramaBarracks")
	return root


static var _nature_cache := {}


static func nature_mesh(key: String) -> Mesh:
	if _nature_cache.has(key):
		return _nature_cache[key]
	var b := Batch.new()
	match key:
		"diorama://spruce_a":
			_conifer(b, 0)
		"diorama://spruce_b":
			_conifer(b, 1)
		"diorama://oak_a":
			_broadleaf(b, 0)
		"diorama://oak_b":
			_broadleaf(b, 1)
		"diorama://rock_a":
			_sculpted_rock(b, _rockface(), 1.0, Vector3(9, 2, 5), Vector3(0, 0.3, 0), Vector3(1.2, 0.82, 1.05))
		_:
			_conifer(b, 0)
	var mesh := b.build_mesh()
	_nature_cache[key] = mesh
	return mesh


static func _conifer(b: Batch, variant: int) -> void:
	var trunk := _plain_mat("trunk", Color(0.42, 0.33, 0.24))
	var pine := _plain_mat("pine0", Color(0.27, 0.42, 0.24))
	var pine2 := _plain_mat("pine1", Color(0.33, 0.48, 0.28))
	var mat: Material = pine if variant == 0 else pine2
	var lift := 0.0 if variant == 0 else 0.35
	_cyl(b, trunk, 0.13, 0.2, 1.3, Vector3(0, 0.6, 0), 10)
	_cyl(b, mat, 0.03, 1.6, 2.7, Vector3(0, 2.2 + lift * 0.4, 0), 18)
	_cyl(b, mat, 0.03, 1.24, 2.3, Vector3(0.06, 3.6 + lift * 0.7, 0.04), 18)
	_cyl(b, mat, 0.03, 0.84, 2.0, Vector3(-0.04, 4.9 + lift, -0.03), 18)


static func _broadleaf(b: Batch, variant: int) -> void:
	var trunk := _plain_mat("trunk", Color(0.42, 0.33, 0.24))
	var leaf := _plain_mat("leaf0", Color(0.38, 0.55, 0.27))
	var leaf2 := _plain_mat("leaf1", Color(0.33, 0.49, 0.24))
	var mat: Material = leaf if variant == 0 else leaf2
	_cyl(b, trunk, 0.16, 0.25, 1.8, Vector3(0, 0.85, 0), 10)
	if variant == 0:
		_sculpted_rock(b, mat, 1.55, Vector3(5, 3, 1), Vector3(0, 3.3, 0), Vector3(1.42, 1.16, 1.42), 0.13)
		_sculpted_rock(b, mat, 1.1, Vector3(8, 1, 4), Vector3(0.85, 4.05, 0.3), Vector3(1.3, 1.05, 1.3), 0.13)
		_sculpted_rock(b, mat, 1.05, Vector3(2, 6, 3), Vector3(-0.75, 3.7, -0.25), Vector3(1.05, 0.9, 1.05), 0.13)
	else:
		_sculpted_rock(b, mat, 1.8, Vector3(6, 2, 2), Vector3(0, 3.5, 0), Vector3(1.3, 1.05, 1.3), 0.13)
		_sculpted_rock(b, mat, 1.15, Vector3(1, 4, 7), Vector3(-0.9, 4.2, 0.35), Vector3(1.1, 0.95, 1.1), 0.13)
