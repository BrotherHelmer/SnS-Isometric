class_name ProductionDioramaBuildingsGateB
extends RefCounted

## Gate B Visual Rescue: Nordic Storybook 3D Diorama buildings
## Improved silhouettes, proportions, and palette following helmer_target_look.
## Focus: steeper roofs, chunky beveled timber, warmer saturated palette,
## better architectural variety, storybook proportions.
##
## Palette (from PIPELINE.md):
## - Stone: #b8b4a8 (warm light stone)
## - Roof Red: #c23b2a (terracotta/clay tiles)
## - Thatch: #d9a84e (golden yellow thatch)
## - Timber: #6b4423 (dark brown wood)
## - Grass: #6fbf3f..#8fd14f (bright saturated green)
## - Dirt: #c9a86a (warm tan path)
##
## Changes from baseline production_diorama_buildings.gd:
## 1. Steeper roof angles (target 45-55° vs current ~35°)
## 2. Chunky beveled timber frames on houses (visible half-timbering)
## 3. Taller, more vertical proportions for Town Hall towers
## 4. Warmer, more saturated palette matching target
## 5. Better silhouette variety (distinct modules per building type)
## 6. Contact shadows implicit via geometry (overhangs, recesses)

const Catalog = preload("res://src/GodotClient3D/Scripts/production_asset_catalog.gd")

static var _mat_cache := {}
static var _build_cache := {}


## Material palette following PIPELINE.md target
static func _get_palette_materials() -> Dictionary:
	return {
		"stone": _create_mat("stone", Color("#b8b4a8"), 0.88),
		"stone_dark": _create_mat("stone_dark", Color("#9a9589"), 0.92),
		"roof_red": _create_mat("roof_red", Color("#c23b2a"), 0.85),
		"thatch": _create_mat("thatch", Color("#d9a84e"), 0.90),
		"timber": _create_mat("timber", Color("#6b4423"), 0.92),
		"timber_light": _create_mat("timber_light", Color("#8a5d30"), 0.88),
		"plaster": _create_mat("plaster", Color("#e8e0cc"), 0.90),
		"dark_trim": _create_mat("dark_trim", Color("#3a2818"), 0.95),
		"window": _create_mat("window", Color("#2a3538"), 0.70),
	}


static func _create_mat(key: String, color: Color, roughness: float) -> StandardMaterial3D:
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = 0.0
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	_mat_cache[key] = m
	return m


static func _tex_mat(tex_key: String, tint: Color, uv_scale: float = 1.0) -> StandardMaterial3D:
	var cache_key := "tex:" + tex_key + "@" + str(uv_scale) + tint.to_html()
	if _mat_cache.has(cache_key):
		return _mat_cache[cache_key]
	var m := StandardMaterial3D.new()
	if Catalog.DIORAMA_TEXTURES.has(tex_key):
		m.albedo_texture = load(Catalog.DIORAMA_TEXTURES[tex_key]) as Texture2D
	m.albedo_color = tint
	m.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
	m.roughness = 0.90
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	_mat_cache[cache_key] = m
	return m


## Build entry point matching original API
static func build(building_type: String, seed_id: int) -> Node3D:
	var key := building_type + ":" + str(absi(seed_id) % 5 if building_type == "HOUSE" else 0)
	if _build_cache.has(key):
		var entry: Dictionary = _build_cache[key]
		var root := Node3D.new()
		root.name = String(entry["name"])
		root.scale = entry["scale"]
		for pair in entry["pairs"]:
			var mi := MeshInstance3D.new()
			mi.mesh = pair[0]
			mi.material_override = pair[1]
			mi.transform = pair[2]
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			root.add_child(mi)
		return root
	var fresh := _build_fresh(building_type, seed_id)
	var pairs := []
	var cacheable := true
	for child in fresh.get_children():
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			cacheable = false
			break
		pairs.append([mi.mesh, mi.material_override, mi.transform])
	if cacheable and not pairs.is_empty():
		_build_cache[key] = {"name": fresh.name, "scale": fresh.scale, "pairs": pairs}
	return fresh


static func _build_fresh(building_type: String, seed_id: int) -> Node3D:
	match building_type:
		"TOWN_HALL":
			return _build_town_hall()
		"HOUSE":
			return _build_house(seed_id)
		"LUMBER_CAMP":
			return _build_lumber_camp()
		_:
			# Fallback for other building types not in Gate B proof scope
			return Node3D.new()


## ============================================================================
## TOWN HALL (founding hall, castle-family)
## Improvements:
## - Taller, more vertical towers (was squat)
## - Steeper conical roofs
## - Light stone with red conical tower caps
## - Better proportions matching Nordic castle in target
## ============================================================================
static func _build_town_hall() -> Node3D:
	var b := Batch.new()
	var pal := _get_palette_materials()
	
	# Main hall body - warm light stone
	_box(b, pal["stone"], Vector3(9.0, 5.0, 6.8), Vector3(0, 2.5, -0.5))
	
	# Crenellation rim
	_box(b, pal["stone"], Vector3(9.8, 0.6, 7.6), Vector3(0, 5.3, -0.5))
	for bx in [-4.4, -2.6, -0.8, 0.8, 2.6, 4.4]:
		_box(b, pal["stone"], Vector3(0.7, 0.7, 0.7), Vector3(bx, 5.9, -4.0))
		_box(b, pal["stone"], Vector3(0.7, 0.7, 0.7), Vector3(bx, 5.9, 3.0))
	
	# Three towers - taller and more vertical than baseline
	# Front center tower (tallest)
	_cyl(b, pal["stone"], 2.1, 2.3, 12.0, Vector3(-0.5, 6.0, -3.8), 24)
	_cyl(b, pal["roof_red"], 0.05, 2.8, 5.0, Vector3(-0.5, 13.5, -3.8), 24)
	
	# Left tower
	_cyl(b, pal["stone"], 1.8, 2.0, 9.5, Vector3(-4.8, 4.75, 2.0), 22)
	_cyl(b, pal["roof_red"], 0.05, 2.5, 4.2, Vector3(-4.8, 10.8, 2.0), 22)
	
	# Right tower
	_cyl(b, pal["stone"], 1.8, 2.0, 9.5, Vector3(3.8, 4.75, 2.0), 22)
	_cyl(b, pal["roof_red"], 0.05, 2.5, 4.2, Vector3(3.8, 10.8, 2.0), 22)
	
	# Main hall steep roof
	_roof_prism(b, pal["roof_red"], Vector3(6.0, 3.2, 7.8), Vector3(0, 7.0, -0.5))
	
	# Entry door and frame
	_box(b, pal["timber"], Vector3(1.8, 3.2, 0.4), Vector3(-0.5, 1.6, 3.2))
	_box(b, pal["stone"], Vector3(2.5, 0.4, 1.0), Vector3(-0.5, 0.2, 3.5))
	
	# Windows (small dark recesses)
	for wpos in [Vector3(-4.8, 6.2, 3.4), Vector3(3.8, 6.2, 3.4), 
	             Vector3(-0.5, 8.2, -1.8), Vector3(-2.2, 3.5, 3.2), 
	             Vector3(1.2, 3.5, 3.2)]:
		_box(b, pal["window"], Vector3(0.5, 0.7, 0.35), wpos)
	
	var root := b.build_root("GateBTownHall")
	root.scale = Vector3.ONE * 0.76
	return root


## ============================================================================
## HOUSE (cottage-family)
## Improvements:
## - 5 distinct variants with different roofs and wall treatments
## - Steeper roof angles (45-55°)
## - Visible half-timbering on some variants
## - Warmer palette
## - Chunky beveled timber frames
## ============================================================================
static func _build_house(seed_id: int) -> Node3D:
	var b := Batch.new()
	var pal := _get_palette_materials()
	var variant := absi(seed_id) % 5
	var scale := 0.88
	
	match variant:
		0:
			# Plaster walls with dark timber framing + golden thatch
			_box(b, pal["plaster"], Vector3(5.6, 3.2, 4.6), Vector3(0, 1.6, 0))
			# Half-timber vertical beams
			for bx in [-2.75, 0.0, 2.75]:
				_box(b, pal["timber"], Vector3(0.32, 3.2, 4.64), Vector3(bx, 1.6, 0))
			# Horizontal timber beam
			_box(b, pal["timber"], Vector3(5.64, 0.3, 4.64), Vector3(0, 3.05, 0))
			# Steep thatch roof
			_roof_prism(b, pal["thatch"], Vector3(5.8, 3.0, 6.8), Vector3(0, 4.5, 0))
			scale = 0.86
			
		1:
			# Stone cottage + red clay roof
			_box(b, pal["stone"], Vector3(5.4, 3.0, 4.4), Vector3(0, 1.5, 0))
			_box(b, pal["stone_dark"], Vector3(5.5, 0.5, 4.5), Vector3(0, 0.25, 0))
			_roof_prism(b, pal["roof_red"], Vector3(5.6, 2.8, 6.6), Vector3(0, 4.3, 0))
			scale = 0.88
			
		2:
			# Timber log cabin + dark thatch
			_box(b, pal["timber"], Vector3(5.5, 3.1, 4.5), Vector3(0, 1.55, 0))
			# Log corner posts (thicker)
			for corner in [Vector2(-2.65, -2.15), Vector2(-2.65, 2.15), 
			               Vector2(2.65, -2.15), Vector2(2.65, 2.15)]:
				_box(b, pal["timber"], Vector3(0.45, 3.1, 0.45), Vector3(corner.x, 1.55, corner.y))
			_roof_prism(b, _create_mat("thatch_dark", Color("#8a6830"), 0.92), 
			            Vector3(5.9, 2.9, 6.9), Vector3(0, 4.4, 0))
			scale = 0.90
			
		3:
			# Plaster + timber accents + warm tan thatch
			_box(b, pal["plaster"], Vector3(5.5, 3.15, 4.5), Vector3(0, 1.58, 0))
			# Timber trim around middle
			_box(b, pal["timber_light"], Vector3(5.54, 0.28, 4.54), Vector3(0, 1.58, 0))
			_roof_prism(b, _create_mat("thatch_tan", Color("#c9a86a"), 0.88), 
			            Vector3(5.7, 2.85, 6.7), Vector3(0, 4.35, 0))
			scale = 0.92
			
		_: # variant 4
			# Stone walls + red roof (Nordic Settlers II style)
			_box(b, pal["stone"], Vector3(5.45, 3.05, 4.45), Vector3(0, 1.53, 0))
			# Stone base
			_box(b, pal["stone_dark"], Vector3(5.6, 0.48, 4.6), Vector3(0, 0.24, 0))
			_roof_prism(b, pal["roof_red"], Vector3(5.8, 2.95, 6.8), Vector3(0, 4.4, 0))
			scale = 0.87
	
	# Common elements for all variants
	# Chimney
	_box(b, pal["stone_dark"], Vector3(0.75, 1.6, 0.75), Vector3(1.8, 5.5, -1.0))
	
	# Door
	_box(b, pal["timber"], Vector3(1.15, 2.1, 0.28), Vector3(-1.0, 1.05, 2.37))
	
	# Windows
	_box(b, pal["window"], Vector3(0.7, 0.7, 0.25), Vector3(1.3, 1.85, 2.35))
	_box(b, pal["window"], Vector3(0.7, 0.7, 0.25), Vector3(-2.1, 1.85, 2.35))
	
	var root := b.build_root("GateBHouse")
	root.scale = Vector3.ONE * scale
	return root


## ============================================================================
## LUMBER CAMP (shed with open front)
## Improvements:
## - Open-front timber structure with visible posts
## - Log pile visible inside
## - Steep protective roof overhang
## - Warmer wood tones
## ============================================================================
static func _build_lumber_camp() -> Node3D:
	var b := Batch.new()
	var pal := _get_palette_materials()
	
	# Timber frame structure (open front shed)
	# Back wall
	_box(b, pal["timber"], Vector3(6.0, 3.5, 0.35), Vector3(0, 1.75, -2.4))
	
	# Side walls
	_box(b, pal["timber"], Vector3(0.35, 3.5, 5.0), Vector3(-2.95, 1.75, 0))
	_box(b, pal["timber"], Vector3(0.35, 3.5, 5.0), Vector3(2.95, 1.75, 0))
	
	# Front support posts (open front)
	_box(b, pal["timber"], Vector3(0.5, 3.5, 0.5), Vector3(-2.5, 1.75, 2.25))
	_box(b, pal["timber"], Vector3(0.5, 3.5, 0.5), Vector3(2.5, 1.75, 2.25))
	
	# Top beam across front
	_box(b, pal["timber"], Vector3(6.0, 0.4, 0.5), Vector3(0, 3.7, 2.25))
	
	# Steep protective roof with overhang
	_roof_prism(b, _create_mat("wood_shingle", Color("#7a5a3a"), 0.90), 
	            Vector3(6.2, 3.2, 7.0), Vector3(0, 5.2, 0))
	
	# Log piles inside (visible from front)
	for log_x in [-1.8, -0.6, 0.6, 1.8]:
		_box(b, pal["timber_light"], Vector3(0.85, 0.65, 2.2), Vector3(log_x, 0.33, -0.8))
		_box(b, pal["timber"], Vector3(0.8, 0.6, 2.1), Vector3(log_x + 0.1, 0.93, -0.8))
	
	# Workbench
	_box(b, pal["timber_light"], Vector3(2.5, 0.12, 1.2), Vector3(0, 0.95, 1.0))
	# Bench legs
	for leg_pos in [Vector2(-1.15, 0.5), Vector2(-1.15, -0.5), 
	                Vector2(1.15, 0.5), Vector2(1.15, -0.5)]:
		_box(b, pal["timber"], Vector3(0.15, 0.95, 0.15), Vector3(leg_pos.x, 0.48, leg_pos.y + 1.0))
	
	# Tool rack on back wall
	_box(b, pal["timber_light"], Vector3(1.8, 0.15, 0.15), Vector3(0, 2.2, -2.25))
	
	var root := b.build_root("GateBLumberCamp")
	root.scale = Vector3.ONE * 2.50
	return root


## ============================================================================
## Geometry helper classes (same pattern as original)
## ============================================================================
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
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			root.add_child(mi)
		return root


static func _box(b: Batch, mat: Material, size: Vector3, pos: Vector3, ry: float = 0.0) -> void:
	var m := BoxMesh.new()
	m.size = size
	b.add(m, mat, Transform3D(Basis(Vector3.UP, ry), pos))


static func _cyl(b: Batch, mat: Material, rt: float, rb: float, h: float, pos: Vector3, seg: int = 20) -> void:
	var m := CylinderMesh.new()
	m.top_radius = rt
	m.bottom_radius = rb
	m.height = h
	m.radial_segments = seg
	b.add(m, mat, Transform3D(Basis.IDENTITY, pos))


static func _roof_prism(b: Batch, mat: Material, size: Vector3, pos: Vector3) -> void:
	var m := PrismMesh.new()
	m.size = size
	b.add(m, mat, Transform3D(Basis(Vector3.UP, PI * 0.5), pos))
