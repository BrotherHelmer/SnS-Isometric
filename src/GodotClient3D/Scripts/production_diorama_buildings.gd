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
		"HOUSE":
			return _build_house(seed_id)
		"LUMBER_CAMP":
			return _build_lumber_camp()
	return Node3D.new()


static func _tex_mat(key: String, tint: Color, uv: float) -> StandardMaterial3D:
	var cache_key := "tex:" + key
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
