extends SceneTree
## GFX-C: concept-closer authored geometry. Pale masonry, steep roofs,
## half-timber, fuller tree crowns. AABB still normalized to BUILDING_UNIT_SIZE.
## The Director: silhouettes and materials only — footprints stay put.
const OUT := "res://assets/settlement3d/runtime/opening_style"
const Profile = preload("res://src/GodotClient3D/Scripts/production_scale_profile.gd")
var surfaces: Dictionary = {}
var materials: Dictionary = {}
var rng := RandomNumberGenerator.new()
var report: Dictionary = {}

func _init() -> void:
	call_deferred("build")

func build() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var palette := {
		"stone": "d2c4a8", "stone_light": "e4d6bc", "stone_dark": "9a8e78",
		"plaster": "efe0c4", "wood": "3a2820", "plank": "6b4a32",
		"slate": "5a6c7c", "slate_light": "6e8294", "slate_dark": "465868",
		"clay": "9a5840", "clay_light": "b46a4a", "clay_dark": "7a4030",
		"iron": "30383a", "glass": "e4a34e",
		"pine": "4a7a44", "pine_dark": "3a6238",
		"leaf": "6a8e3c", "leaf_light": "88a44c", "leaf_spring": "7a9848",
		"grain": "bd9855"
	}
	for key in palette:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(palette[key])
		mat.roughness = 0.88
		if key == "glass":
			mat.emission_enabled = true
			mat.emission = Color("e9a34b")
			mat.emission_energy_multiplier = 0.55
		materials[key] = mat
	for kind in ["TOWN_HALL", "CASTLE", "HOUSE", "STOREHOUSE", "LUMBER_CAMP", "BAKERY", "WATCHTOWER", "QUARRY", "BARRACKS", "LUMEN_PILLAR", "ENEMY_CAMP", "FARM"]:
		surfaces.clear()
		rng.seed = 526
		if kind == "STOREHOUSE" or kind == "LUMBER_CAMP":
			shed(kind == "LUMBER_CAMP")
		elif kind == "WATCHTOWER":
			tower()
		elif kind == "CASTLE":
			castle()
		elif kind == "FARM":
			farm()
		else:
			extended_building(kind)
		save_model(kind.to_lower(), Profile.BUILDING_UNIT_SIZE[kind])
	for kind in ["fir", "fir_tall", "spruce", "broadleaf", "oak", "birch", "fir_lod", "broadleaf_lod", "rocks", "fence", "lantern", "cart", "grass", "bush", "wheat"]:
		surfaces.clear()
		rng.seed = 907 + kind.hash()
		match kind:
			"fir":
				conifer(6, 1.0, "pine")
			"fir_tall":
				conifer(8, 1.18, "pine_dark")
			"spruce":
				conifer(7, 0.92, "pine_dark")
			"broadleaf":
				deciduous(14, 1.05, "leaf", "leaf_light")
			"oak":
				deciduous(18, 1.28, "leaf", "leaf_spring")
			"birch":
				deciduous(12, 0.88, "leaf_light", "leaf_spring")
			"fir_lod":
				conifer(4, 0.95, "pine")
			"broadleaf_lod":
				deciduous(7, 1.0, "leaf", "leaf_light")
			"rocks":
				for i in 7:
					blob(Vector3(rng.randf_range(-0.8, 0.8), 0.38, rng.randf_range(-0.6, 0.6)), Vector3(rng.randf_range(0.45, 0.85), rng.randf_range(0.4, 1.15), rng.randf_range(0.4, 0.75)), "stone_dark" if i % 2 == 0 else "stone")
			"fence": fence(Vector3.ZERO)
			"lantern": lantern()
			"cart": cart()
			"grass": grass()
			"bush":
				blob(Vector3(0, 0.42, 0), Vector3(0.72, 0.55, 0.68), "leaf")
				blob(Vector3(0.22, 0.38, 0.12), Vector3(0.42, 0.36, 0.4), "leaf_light")
			"wheat": wheat()
		save_model(kind)
	var file := FileAccess.open(OUT + "/model_manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("OPENING_MODELS PASS ", report.size(), " models")
	quit()

func add(mesh: Mesh, p: Vector3, key: String, rotation := Vector3.ZERO, scale_value := Vector3.ONE) -> void:
	if not surfaces.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		surfaces[key] = st
	var basis := Basis.from_euler(rotation).scaled(scale_value)
	(surfaces[key] as SurfaceTool).append_from(mesh, 0, Transform3D(basis, p))

func box(p: Vector3, size: Vector3, key: String, rotation := Vector3.ZERO) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	add(mesh, p, key, rotation)

func cylinder(p: Vector3, bottom: float, top: float, height: float, key: String, sides := 8, rotation := Vector3.ZERO) -> void:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 1
	add(flat_mesh(mesh), p, key, rotation)

func blob(p: Vector3, size: Vector3, key: String) -> void:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 7
	mesh.rings = 3
	mesh.radius = 1.0
	mesh.height = 2.0
	# Flat shading gives the angular reference silhouette.
	add(flat_mesh(mesh), p, key, Vector3(0, rng.randf() * TAU, 0), size)

func flat_mesh(mesh: Mesh) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, indices.size(), 3):
		var a := vertices[indices[i]]
		var b := vertices[indices[i + 1]]
		var c := vertices[indices[i + 2]]
		var normal := (b - a).cross(c - a).normalized()
		if normal.dot(normals[indices[i]]) < 0: normal = -normal
		for v in [a, b, c]:
			st.set_normal(normal)
			st.set_uv(Vector2.ZERO)
			st.add_vertex(v)
	st.index()
	return st.commit()

func beam(a: Vector3, b: Vector3, width: float, key: String) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, a.distance_to(b), width)
	var basis := Basis(Quaternion(Vector3.UP, (b - a).normalized()))
	if not surfaces.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		surfaces[key] = st
	(surfaces[key] as SurfaceTool).append_from(mesh, 0, Transform3D(basis, (a + b) * 0.5))

func masonry(center: Vector3, size: Vector3, courses: int) -> void:
	box(center, size, "stone_dark")
	var h := size.y / courses
	for row in courses:
		for side in [-1, 1]:
			for col in 7:
				var start := maxf(-size.x * 0.5, -size.x * 0.5 + (col - (row % 2) * 0.5) * size.x / 6.0)
				var end := minf(size.x * 0.5, -size.x * 0.5 + (col + 1 - (row % 2) * 0.5) * size.x / 6.0)
				if end - start < 0.03: continue
				box(center + Vector3((start + end) * 0.5, -size.y * 0.5 + (row + 0.5) * h, side * (size.z * 0.5 + 0.018)), Vector3(end - start - 0.025, h - 0.025, 0.09), "stone_light" if (row + col) % 4 == 0 else "stone")
			for col in 5:
				box(center + Vector3(side * (size.x * 0.5 + 0.018), -size.y * 0.5 + (row + 0.5) * h, -size.z * 0.5 + (col + 0.5) * size.z / 5.0), Vector3(0.09, h - 0.025, size.z / 5.0 - 0.025), "stone")

func roof(center: Vector3, width: float, depth: float, rise: float, wood_roof := false, clay_roof := false) -> void:
	var half := width * 0.5
	var slope := atan2(rise, half)
	var length := sqrt(half * half + rise * rise)
	var keys: Array = ["slate", "slate_light", "slate_dark"]
	if wood_roof:
		keys = ["plank", "plank", "wood"]
	elif clay_roof:
		keys = ["clay", "clay_light", "clay_dark"]
	for side in [-1, 1]:
		box(center + Vector3(side * half * 0.5, rise * 0.5, 0), Vector3(length, 0.12, depth), "wood", Vector3(0, 0, -side * slope))
		for row in 7:
			var t := (row + 0.5) / 7.0
			for col in 9:
				var key: String = String(keys[(row * 7 + col * 3 + col / 3) % 3])
				box(center + Vector3(side * half * t, rise * (1.0 - t) + 0.09 + float(7 - row) * 0.012, -depth * 0.5 + (col + 0.5) * depth / 9.0), Vector3(length / 7.0 + 0.05, 0.08, depth / 9.0 - 0.012), key, Vector3(0, 0, -side * slope))
		for z in [-depth * 0.5, depth * 0.5]:
			beam(center + Vector3(0, rise + 0.08, z), center + Vector3(side * half, 0.05, z), 0.14, "wood")
	box(center + Vector3(0, rise + 0.16, 0), Vector3(0.16, 0.16, depth + 0.14), "wood")

func window(p: Vector3) -> void:
	box(p, Vector3(0.55, 0.74, 0.10), "wood")
	box(p + Vector3(0, 0, 0.061), Vector3(0.42, 0.59, 0.03), "glass")
	box(p + Vector3(0, 0, 0.09), Vector3(0.045, 0.65, 0.04), "wood")
	box(p + Vector3(0, 0, 0.09), Vector3(0.48, 0.05, 0.04), "wood")
	box(p + Vector3(0, -0.40, 0.10), Vector3(0.7, 0.09, 0.26), "plank")

func cottage(kind: String) -> void:
	var civic := kind == "TOWN_HALL"
	var w := 4.4 if civic else 3.2
	var d := 3.15 if civic else 2.8
	var clay := not civic
	masonry(Vector3(0, 0.36, 0), Vector3(w, 0.72, d), 2)
	box(Vector3(0, 1.68, 0), Vector3(w - 0.08, 2.0, d - 0.08), "plaster")
	# The Director: thicker half-timber so frames read at isometric zoom.
	for x in [-w * 0.5 + 0.05, 0.0, w * 0.5 - 0.05]:
		for z in [-d * 0.5, d * 0.5]:
			box(Vector3(x, 1.66, z), Vector3(0.20, 2.15, 0.20), "wood")
	for y in [0.78, 2.62]:
		box(Vector3(0, y, 0), Vector3(w + 0.16, 0.18, d + 0.16), "wood")
	for side in [-1, 1]:
		for z in [-0.78, 0.78]:
			box(Vector3(side * w * 0.5, 1.66, z), Vector3(0.16, 1.85, 0.16), "wood")
			box(Vector3(side * (w * 0.5 + 0.04), 1.78, z + 0.28), Vector3(0.12, 0.72, 0.50), "wood")
			box(Vector3(side * (w * 0.5 + 0.10), 1.78, z + 0.28), Vector3(0.03, 0.56, 0.36), "glass")
			box(Vector3(side * (w * 0.5 + 0.13), 1.78, z + 0.28), Vector3(0.045, 0.64, 0.045), "wood")
			box(Vector3(side * (w * 0.5 + 0.13), 1.78, z + 0.28), Vector3(0.045, 0.045, 0.42), "wood")
	for x in [-1, 1]:
		beam(Vector3(x * (w * 0.5 - 0.08), 0.88, d * 0.5 + 0.05), Vector3(x * 0.5, 2.55, d * 0.5 + 0.05), 0.12, "wood")
		window(Vector3(x * w * 0.30, 1.70, d * 0.5 + 0.10))
	box(Vector3(0, 1.08, d * 0.5 + 0.11), Vector3(0.92, 1.72, 0.18), "wood")
	for i in 5:
		box(Vector3(-0.36 + i * 0.18, 1.08, d * 0.5 + 0.22), Vector3(0.15, 1.58, 0.07), "plank")
	for y in [0.70, 1.40]:
		box(Vector3(0, y, d * 0.5 + 0.26), Vector3(0.72, 0.06, 0.04), "iron")
	for i in 3:
		box(Vector3(0, 0.10 + i * 0.13, d * 0.5 + 0.64 - i * 0.17), Vector3(1.12, 0.2, 0.36), "stone")
	var rise := 2.05 if clay else 1.90
	var prism := PrismMesh.new()
	prism.size = Vector3(w, rise * 0.92, d)
	add(prism, Vector3(0, 2.68 + rise * 0.46, 0), "plaster")
	roof(Vector3(0, 2.58, 0), w + 0.55, d + 0.55, rise, false, clay)
	beam(Vector3(0, 2.60, d * 0.5 + 0.04), Vector3(0, 2.58 + rise, d * 0.5 + 0.04), 0.14, "wood")
	if civic:
		# Wide squat keep — a tall spike loses the hall after AABB normalize.
		masonry(Vector3(-0.85, 3.55, -0.35), Vector3(2.35, 2.85, 2.25), 8)
		window(Vector3(-0.85, 3.85, 0.80))
		window(Vector3(-0.85, 2.85, 0.80))
		roof(Vector3(-0.85, 4.85, -0.35), 2.75, 2.65, 1.35)
		box(Vector3(-0.85, 6.35, -0.35), Vector3(0.10, 0.72, 0.10), "wood")
		box(Vector3(-0.35, 6.52, -0.35), Vector3(0.82, 0.40, 0.05), "slate_light")
		for side in [-1, 1]:
			box(Vector3(-0.85 + side * 1.05, 3.4, 0.78), Vector3(0.10, 1.15, 0.10), "wood")
	else:
		chimney(Vector3(1.08, 2.55, -0.55))
	if kind == "BAKERY":
		masonry(Vector3(1.9, 0.65, 0.6), Vector3(1.1, 1.3, 1.15), 4)
		box(Vector3(1.9, 0.65, 1.21), Vector3(0.63, 0.66, 0.05), "iron")
		box(Vector3(1.9, 0.55, 1.25), Vector3(0.43, 0.38, 0.03), "glass")
		box(Vector3(-1.05, 0.85, 1.9), Vector3(1.15, 0.12, 0.52), "plank")
		for x in [-1.45, -0.65]:
			box(Vector3(x, 0.4, 1.9), Vector3(0.12, 0.8, 0.12), "wood")
		for i in 3:
			blob(Vector3(-1.4 + i * 0.3, 0.99, 1.9), Vector3(0.17, 0.10, 0.13), "glass")
		chimney(Vector3(-1.2, 3.2, -0.9))
		cylinder(Vector3(-1.2, 4.35, -0.9), 0.30, 0.30, 0.19, "iron")

func chimney(p: Vector3) -> void:
	masonry(p, Vector3(0.52, 3.4, 0.56), 10)
	box(p + Vector3(0, 1.78, 0), Vector3(0.70, 0.16, 0.74), "stone_dark")
	box(p + Vector3(0, 1.90, 0), Vector3(0.38, 0.04, 0.42), "iron")


func shed(lumber: bool) -> void:
	masonry(Vector3(0, 0.17, 0), Vector3(3.4, 0.34, 2.8), 1)
	for x in [-1.5, 1.5]:
		for z in [-1.2, 1.2]:
			box(Vector3(x, 1.35, z), Vector3(0.26, 2.4, 0.26), "wood")
			beam(Vector3(x, 1.55, z), Vector3(x * 0.62, 2.5, z), 0.15, "wood")
	for i in 13:
		box(Vector3(-1.5 + i * 0.25, 1.35, -1.25), Vector3(0.23, 2.1, 0.12), "plank")
	box(Vector3(0, 2.5, 0), Vector3(3.4, 0.18, 2.8), "wood")
	roof(Vector3(0, 2.52, 0), 3.9, 3.3, 1.45, true)
	if lumber:
		for i in 7:
			cylinder(Vector3(-0.9 + (i % 3) * 0.42, 0.48 + (i / 3) * 0.4, -0.35), 0.21, 0.21, 2.0, "plank", 8, Vector3(PI / 2.0, 0, 0))
		box(Vector3(0.8, 0.85, 0.65), Vector3(0.75, 0.12, 1.4), "plank")
		for z in [0.15, 1.15]:
			box(Vector3(0.8, 0.45, z), Vector3(0.55, 0.8, 0.15), "wood")
		cylinder(Vector3(0.8, 1.0, 0.55), 0.52, 0.52, 0.08, "iron", 24, Vector3(0, 0, PI / 2.0))
		for i in 12:
			var angle := i * TAU / 12.0
			box(Vector3(0.8, 1.0 + cos(angle) * 0.54, 0.55 + sin(angle) * 0.54), Vector3(0.08, 0.16, 0.12), "iron", Vector3(0, 0, angle))
	else:
		for i in 6:
			box(Vector3(-0.85 + (i % 3) * 0.78, 0.65 + (i / 3) * 0.7, -0.3), Vector3(0.7, 0.65, 0.8), "plank")
			box(Vector3(-0.85 + (i % 3) * 0.78, 0.65 + (i / 3) * 0.7, 0.12), Vector3(0.07, 0.63, 0.07), "wood")

func tower() -> void:
	masonry(Vector3(0, 1.85, 0), Vector3(1.85, 3.7, 1.85), 11)
	box(Vector3(0, 3.75, 0), Vector3(2.65, 0.24, 2.65), "stone_dark")
	for x in [-1.05, 1.05]:
		for z in [-1.05, 1.05]:
			box(Vector3(x, 4.45, z), Vector3(0.22, 1.7, 0.22), "wood")
		box(Vector3(0, 4.05, x * 1.18), Vector3(2.5, 0.48, 0.14), "plank")
		box(Vector3(x * 1.18, 4.05, 0), Vector3(0.14, 0.48, 2.5), "plank")
	roof(Vector3(0, 5.15, 0), 3.05, 3.05, 1.55)
	window(Vector3(0, 2.75, 0.98))
	window(Vector3(0, 1.55, 0.98))
	box(Vector3(0, 0.75, 0.96), Vector3(0.70, 1.45, 0.12), "wood")

func castle() -> void:
	var base_h := 0.42
	masonry(Vector3(0, base_h * 0.5, 0), Vector3(6.4, base_h, 5.2), 1)
	var curtain_h := 1.55
	masonry(Vector3(0, base_h + curtain_h * 0.5, 2.10), Vector3(5.2, curtain_h, 0.34), 5)
	masonry(Vector3(0, base_h + curtain_h * 0.5, -2.10), Vector3(5.2, curtain_h, 0.34), 5)
	masonry(Vector3(-2.7, base_h + curtain_h * 0.5, 0), Vector3(0.34, curtain_h, 3.8), 5)
	masonry(Vector3(2.7, base_h + curtain_h * 0.5, 0), Vector3(0.34, curtain_h, 3.8), 5)
	for i in 8:
		var x := -2.55 + i * 0.72
		box(Vector3(x, base_h + curtain_h + 0.22, 2.18), Vector3(0.38, 0.44, 0.38), "stone_light")
		box(Vector3(x, base_h + curtain_h + 0.22, -2.18), Vector3(0.38, 0.44, 0.38), "stone_light")
	var keep_pos := Vector3(0.0, 0, -0.15)
	cylinder(keep_pos + Vector3(0, base_h + 3.15, 0), 1.18, 1.08, 6.3, "stone", 16)
	for level in 5:
		window(keep_pos + Vector3(0, base_h + 1.15 + level * 0.95, 1.12))
	cylinder(keep_pos + Vector3(0, base_h + 6.45, 0), 1.28, 1.28, 0.24, "stone_dark")
	cylinder(keep_pos + Vector3(0, base_h + 7.85, 0), 1.12, 0.04, 2.85, "slate", 8)
	box(keep_pos + Vector3(0, base_h + 9.45, 0), Vector3(0.10, 0.95, 0.10), "wood")
	box(keep_pos + Vector3(0.52, base_h + 9.65, 0), Vector3(0.95, 0.52, 0.05), "slate_light")
	for i in 4:
		var angle := i * PI / 2.0
		var p := keep_pos + Vector3(cos(angle) * 1.12, base_h + 6.58, sin(angle) * 1.12)
		box(p, Vector3(0.36, 0.42, 0.36), "stone_light")
	var corners := [Vector3(-2.7, 0, 2.05), Vector3(2.7, 0, 2.05), Vector3(-2.7, 0, -2.05), Vector3(2.7, 0, -2.05)]
	for corner in corners:
		cylinder(corner + Vector3(0, base_h + 2.45, 0), 0.92, 0.84, 4.9, "stone_light", 12)
		cylinder(corner + Vector3(0, base_h + 5.05, 0), 1.00, 1.00, 0.20, "stone_dark")
		cylinder(corner + Vector3(0, base_h + 6.15, 0), 0.90, 0.04, 2.25, "slate", 8)
		box(corner + Vector3(0, base_h + 7.45, 0), Vector3(0.08, 0.72, 0.08), "wood")
		box(corner + Vector3(0.38, base_h + 7.60, 0), Vector3(0.72, 0.42, 0.04), "slate_light")
		for i in 4:
			var angle := i * TAU / 4.0
			var wp: Vector3 = corner + Vector3(cos(angle) * 0.80, base_h + 3.15, sin(angle) * 0.80)
			box(wp + Vector3(0, 0, cos(angle) * 0.09), Vector3(0.48, 0.66, 0.09), "wood")
			box(wp + Vector3(0, 0, cos(angle) * 0.14), Vector3(0.36, 0.50, 0.03), "glass")
	masonry(Vector3(0, base_h + 0.85, 2.18), Vector3(1.45, 1.7, 0.32), 5)
	box(Vector3(0, base_h + 0.85, 2.36), Vector3(0.76, 1.32, 0.10), "wood")
	for i in 5:
		box(Vector3(-0.30 + i * 0.15, base_h + 0.85, 2.44), Vector3(0.13, 1.22, 0.06), "plank")
	for y_val in [0.45, 1.10]:
		box(Vector3(0, base_h + y_val, 2.50), Vector3(0.68, 0.06, 0.04), "iron")

func farm() -> void:
	# Barn + cottage within the house AABB so the farm reads as a homestead.
	masonry(Vector3(-0.15, 0.32, 0.05), Vector3(3.6, 0.64, 2.7), 2)
	box(Vector3(-0.15, 1.55, 0.05), Vector3(3.45, 1.85, 2.55), "plank")
	for x in [-1.7, 1.4]:
		for z in [-1.2, 1.3]:
			box(Vector3(x, 1.55, z), Vector3(0.22, 2.0, 0.22), "wood")
	for y in [0.72, 2.40]:
		box(Vector3(-0.15, y, 0.05), Vector3(3.7, 0.16, 2.85), "wood")
	box(Vector3(0.05, 1.15, 1.42), Vector3(1.15, 1.85, 0.12), "wood")
	for i in 6:
		box(Vector3(-0.42 + i * 0.16, 1.12, 1.50), Vector3(0.13, 1.72, 0.06), "plank")
	var prism := PrismMesh.new()
	prism.size = Vector3(3.6, 1.85, 2.7)
	add(prism, Vector3(-0.15, 3.15, 0.05), "plank")
	roof(Vector3(-0.15, 2.42, 0.05), 4.15, 3.2, 1.85, false, true)
	chimney(Vector3(1.15, 2.15, -0.55))
	window(Vector3(-1.05, 1.55, 1.42))
	box(Vector3(-1.35, 0.55, 1.55), Vector3(0.85, 0.12, 0.55), "plank")

func fence(p: Vector3) -> void:
	for x in [-0.9, 0.9]:
		box(p + Vector3(x, 0.6, 0), Vector3(0.15, 1.2, 0.15), "wood")
	for y in [0.4, 0.85]:
		box(p + Vector3(0, y, 0), Vector3(1.9, 0.14, 0.1), "plank")

func lantern() -> void:
	masonry(Vector3(0, 0.25, 0), Vector3(0.4, 0.5, 0.4), 2)
	box(Vector3(0, 1.25, 0), Vector3(0.13, 2.0, 0.13), "wood")
	box(Vector3(0.3, 2.2, 0), Vector3(0.8, 0.12, 0.12), "wood")
	beam(Vector3(0, 1.7, 0), Vector3(0.5, 2.2, 0), 0.08, "wood")
	box(Vector3(0.57, 1.92, 0), Vector3(0.035, 0.45, 0.035), "iron")
	box(Vector3(0.57, 1.63, 0), Vector3(0.25, 0.34, 0.25), "glass")
	for y in [1.43, 1.83]:
		box(Vector3(0.57, y, 0), Vector3(0.34, 0.08, 0.34), "iron")
	for x in [-0.14, 0.14]:
		for z in [-0.14, 0.14]:
			box(Vector3(0.57 + x, 1.63, z), Vector3(0.03, 0.4, 0.03), "iron")

func cart() -> void:
	box(Vector3(0, 0.6, 0), Vector3(1.1, 0.13, 1.5), "wood")
	for i in 3:
		for x in [-0.55, 0.55]:
			box(Vector3(x, 0.78 + i * 0.16, 0), Vector3(0.1, 0.13, 1.5), "plank")
		box(Vector3(0, 0.78 + i * 0.16, -0.7), Vector3(1.1, 0.13, 0.1), "plank")
	for x in [-0.7, 0.7]:
		var torus := TorusMesh.new()
		torus.inner_radius = 0.32
		torus.outer_radius = 0.44
		torus.rings = 12
		torus.ring_segments = 6
		add(torus, Vector3(x, 0.44, 0), "iron", Vector3(0, 0, PI / 2.0))
		for i in 6:
			var a := i * PI / 3.0
			beam(Vector3(x, 0.44, 0), Vector3(x, 0.44 + cos(a) * 0.37, sin(a) * 0.37), 0.045, "wood")
		beam(Vector3(x * 0.65, 0.6, 0.5), Vector3(x * 0.65, 0.6, 2.0), 0.10, "wood")

func save_model(label: String, target := Vector3.ZERO) -> void:
	var mesh := ArrayMesh.new()
	for key in surfaces:
		var st: SurfaceTool = surfaces[key]
		st.set_material(materials[key])
		st.commit(mesh)
	var bounds := mesh.get_aabb()
	var scale_value := target / bounds.size if target != Vector3.ZERO else Vector3.ONE
	var offset := Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z)
	var final_mesh := ArrayMesh.new()
	var triangles := 0
	for i in mesh.get_surface_count():
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.append_from(mesh, i, Transform3D(Basis.from_scale(scale_value), offset * scale_value))
		st.set_material(mesh.surface_get_material(i))
		st.commit(final_mesh)
		triangles += (mesh.surface_get_array_index_len(i) if mesh.surface_get_array_index_len(i) > 0 else mesh.surface_get_array_len(i)) / 3
	var mesh_path := OUT + "/" + label + ".res"
	assert(ResourceSaver.save(final_mesh, mesh_path) == OK)
	var node := Node3D.new()
	node.name = label.to_pascal_case()
	var instance := MeshInstance3D.new()
	instance.name = "Model"
	instance.mesh = load(mesh_path)
	node.add_child(instance)
	instance.owner = node
	var scene := PackedScene.new()
	assert(scene.pack(node) == OK)
	assert(ResourceSaver.save(scene, OUT + "/" + label + ".tscn") == OK)
	report[label] = {"triangles": triangles, "surfaces": final_mesh.get_surface_count(), "size": str(final_mesh.get_aabb().size), "source": "Authored geometry adapted from opening_style_v1 image references"}
	node.free()

func barracks() -> void:
	var w := 3.6
	var d := 2.6
	masonry(Vector3(0, 0.40, 0), Vector3(w, 0.80, d), 2)
	box(Vector3(0, 1.75, 0), Vector3(w - 0.12, 2.1, d - 0.12), "stone_light")
	for x in [-w * 0.5 + 0.08, 0.0, w * 0.5 - 0.08]:
		for z in [-d * 0.5, d * 0.5]:
			box(Vector3(x, 1.72, z), Vector3(0.22, 2.2, 0.22), "stone")
	for y in [0.88, 2.80]:
		box(Vector3(0, y, 0), Vector3(w + 0.14, 0.18, d + 0.14), "stone_dark")
	for side in [-1, 1]:
		for z in [-0.65, 0.65]:
			box(Vector3(side * w * 0.5, 1.74, z), Vector3(0.13, 1.85, 0.14), "stone")
	for x in [-1, 1]:
		box(Vector3(x * w * 0.28, 1.78, d * 0.5 + 0.06), Vector3(0.42, 0.58, 0.10), "wood")
		box(Vector3(x * w * 0.28, 1.78, d * 0.5 + 0.12), Vector3(0.32, 0.44, 0.045), "iron")
	box(Vector3(0, 1.15, d * 0.5 + 0.11), Vector3(0.78, 1.55, 0.16), "wood")
	for i in 5:
		box(Vector3(-0.30 + i * 0.15, 1.14, d * 0.5 + 0.21), Vector3(0.13, 1.44, 0.06), "plank")
	for y in [0.76, 1.48]:
		box(Vector3(0, y, d * 0.5 + 0.26), Vector3(0.73, 0.06, 0.045), "iron")
	for i in 3:
		box(Vector3(0, 0.12 + i * 0.14, d * 0.5 + 0.68 - i * 0.18), Vector3(1.15, 0.22, 0.38), "stone")
	var prism := PrismMesh.new()
	prism.size = Vector3(w, 1.25, d)
	add(prism, Vector3(0, 3.43, 0), "stone_light")
	roof(Vector3(0, 2.82, 0), w + 0.5, d + 0.5, 1.25)
	masonry(Vector3(0.90, 2.88, -0.45), Vector3(0.75, 5.2, 0.75), 15)
	box(Vector3(0.90, 5.68, 0.05), Vector3(0.48, 0.68, 0.10), "wood")
	box(Vector3(0.90, 5.68, 0.12), Vector3(0.36, 0.52, 0.045), "iron")
	for i in 4:
		var angle := i * PI / 2.0
		box(Vector3(0.90 + cos(angle) * 0.42, 5.55, -0.45 + sin(angle) * 0.42), Vector3(0.28, 0.42, 0.22), "stone_dark")
	roof(Vector3(0.90, 5.52, -0.45), 1.1, 1.1, 0.85)
	box(Vector3(0.90, 6.48, -0.45), Vector3(0.09, 0.75, 0.09), "wood")
	box(Vector3(1.28, 6.68, -0.45), Vector3(0.72, 0.38, 0.04), "slate_light")
	for side in [-1, 1]:
		box(Vector3(side * 1.35, 1.52, 1.48), Vector3(0.14, 3.0, 0.14), "stone")
		box(Vector3(side * 1.10, 2.5, 1.48), Vector3(0.58, 0.92, 0.08), "iron")
		box(Vector3(side * 1.10, 2.5, 1.58), Vector3(0.45, 0.72, 0.05), "slate_dark")
		box(Vector3(side * 1.10, 2.12, 1.54), Vector3(0.08, 0.08, 0.06), "iron")
	box(Vector3(0, 0.62, -1.65), Vector3(2.8, 0.12, 0.35), "stone_dark")
	for i in 5:
		beam(Vector3(-1.1 + i * 0.55, 0.25, -1.65), Vector3(-1.1 + i * 0.55, 1.65, -1.65), 0.09, "iron")

func extended_building(kind: String) -> void:
	match kind:
		"QUARRY":
			masonry(Vector3(0, 0.18, 0), Vector3(4.0, 0.36, 3.4), 1)
			for i in 6:
				blob(Vector3(-1.3 + (i % 3) * 0.7, 0.7, -0.6 + (i / 3) * 0.8), Vector3(0.6, 0.7, 0.6), "stone_dark")
			box(Vector3(1.0, 1.75, -0.8), Vector3(0.28, 3.4, 0.28), "wood")
			beam(Vector3(1.0, 3.15, -0.8), Vector3(-0.5, 3.15, 0.9), 0.19, "wood")
			beam(Vector3(1.0, 1.8, -0.8), Vector3(-0.4, 3.15, 0.75), 0.15, "wood")
			box(Vector3(-0.5, 2.15, 0.9), Vector3(0.042, 2.1, 0.042), "iron")
			box(Vector3(-0.5, 1.0, 0.9), Vector3(0.68, 0.46, 0.72), "stone_light")
			for corner_x in [-0.82, -0.18]:
				for corner_z in [0.54, 1.26]:
					beam(Vector3(corner_x, 0.72, corner_z), Vector3(-0.5, 1.0, 0.9), 0.06, "iron")
		"BARRACKS":
			barracks()
		"LUMEN_PILLAR":
			cylinder(Vector3(0, 0.18, 0), 0.85, 0.80, 0.36, "stone_dark")
			cylinder(Vector3(0, 0.48, 0), 0.68, 0.60, 0.24, "stone")
			cylinder(Vector3(0, 1.20, 0), 0.40, 0.30, 1.4, "stone_light")
			cylinder(Vector3(0, 1.98, 0), 0.52, 0.52, 0.20, "iron")
			cylinder(Vector3(0, 2.28, 0), 0.35, 0.04, 0.8, "glass", 6)
			for i in 6:
				var angle := i * TAU / 6.0
				var base_pos := Vector3(cos(angle) * 0.42, 1.88, sin(angle) * 0.42)
				var tip_pos := Vector3(cos(angle) * 0.30, 2.52, sin(angle) * 0.30)
				beam(base_pos, tip_pos, 0.07, "iron")
				var crystal_pos := Vector3(cos(angle) * 0.32, 2.18, sin(angle) * 0.32)
				box(crystal_pos, Vector3(0.12, 0.24, 0.12), "glass", Vector3(0, angle, 0))
		"ENEMY_CAMP": cottage("TOWN_HALL")
		_: cottage(kind)

func grass() -> void:
	for i in 5:
		var blade := PrismMesh.new()
		var h := rng.randf_range(0.20, 0.42)
		blade.size = Vector3(0.055, h, 0.025)
		add(blade, Vector3(rng.randf_range(-0.12, 0.12), h * 0.5, rng.randf_range(-0.12, 0.12)), "leaf", Vector3(0, rng.randf() * TAU, rng.randf_range(-0.35, 0.35)))

func wheat() -> void:
	for i in 7:
		var p := Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.2, 0.2))
		var h := rng.randf_range(0.6, 0.85)
		beam(p, p + Vector3(0, h, 0), 0.018, "grain")
		blob(p + Vector3(0, h, 0), Vector3(0.055, 0.15, 0.045), "grain")

func conifer(layers: int, scale_value: float, pine_key: String) -> void:
	# The Director: layered living crowns, not one dark cone.
	cylinder(Vector3(0, 1.15 * scale_value, 0), 0.16 * scale_value, 0.11 * scale_value, 2.3 * scale_value, "wood", 8)
	for i in layers:
		var t := float(i) / float(maxi(layers - 1, 1))
		var y := (1.35 + i * 0.58) * scale_value
		var r := (1.35 - t * 0.95) * scale_value
		var h := (1.55 - t * 0.25) * scale_value
		var key := pine_key if i % 2 == 0 else "pine"
		cylinder(Vector3(0, y, 0), r, 0.04 * scale_value, h, key, 8)
		if i < layers - 1:
			var wobble := (0.28 + float(i % 3) * 0.06) * scale_value
			blob(Vector3(cos(i * 1.7) * r * 0.62, y + 0.12, sin(i * 1.3) * r * 0.62), Vector3(wobble, wobble * 0.75, wobble), "leaf" if i % 2 == 0 else "leaf_light")
			blob(Vector3(cos(i * 2.1 + 1.2) * r * 0.48, y + 0.22, sin(i * 1.9) * r * 0.48), Vector3(wobble * 0.85, wobble * 0.6, wobble * 0.85), key)

func deciduous(clusters: int, spread: float, leaf_a: String, leaf_b: String) -> void:
	cylinder(Vector3(0, 1.15 * spread, 0), 0.20 * spread, 0.12 * spread, 2.3 * spread, "wood", 8)
	for i in clusters:
		var angle := i * 2.15
		var lift := 2.15 + sin(i * 1.3) * 0.55
		var rad := (0.55 + float(i % 4) * 0.12) * spread
		var p := Vector3(cos(angle) * rad, lift * spread, sin(angle) * rad)
		beam(Vector3(0, 1.2 * spread, 0), p, 0.11 * spread, "wood")
		var s := (0.72 + float(i % 3) * 0.12) * spread
		blob(p, Vector3(s, s * 0.95, s * 0.9), leaf_a if i % 2 == 0 else leaf_b)
	blob(Vector3(0, 2.85 * spread, 0), Vector3(0.95 * spread, 0.85 * spread, 0.9 * spread), leaf_a)