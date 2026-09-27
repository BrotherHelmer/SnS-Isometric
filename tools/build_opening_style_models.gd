extends SceneTree
## Reproducible, authored geometry adapted from opening_style_v1 references.
## Meshes are merged by material and saved; no procedural cost during play.
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
	var palette := {"stone": "a99d81", "stone_light": "b4a88c", "stone_dark": "827e70", "plaster": "c3b591", "wood": "46362b", "plank": "76563e", "slate": "304d44", "slate_light": "3b564b", "slate_dark": "29443c", "iron": "30383a", "glass": "e4a34e", "pine": "254b40", "leaf": "626d3b", "leaf_light": "7a8044", "grain": "bd9855"}
	for key in palette:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(palette[key])
		mat.roughness = 0.88
		if key == "glass":
			mat.emission_enabled = true
			mat.emission = Color("e9a34b")
			mat.emission_energy_multiplier = 0.55
		materials[key] = mat
	for kind in ["TOWN_HALL", "CASTLE", "HOUSE", "STOREHOUSE", "LUMBER_CAMP", "BAKERY", "WATCHTOWER", "QUARRY", "BARRACKS", "LUMEN_PILLAR", "ENEMY_CAMP"]:
		surfaces.clear()
		rng.seed = 526
		if kind == "STOREHOUSE" or kind == "LUMBER_CAMP":
			shed(kind == "LUMBER_CAMP")
		elif kind == "WATCHTOWER":
			tower()
		elif kind == "CASTLE":
			castle()
		else:
			extended_building(kind)
		save_model(kind.to_lower(), Profile.BUILDING_UNIT_SIZE[kind])
	for kind in ["fir", "broadleaf", "rocks", "fence", "lantern", "cart", "grass", "bush", "wheat"]:
		surfaces.clear()
		rng.seed = 907
		match kind:
			"fir":
				cylinder(Vector3(0, 1.4, 0), 0.17, 0.12, 2.8, "wood")
				for i in 4:
					cylinder(Vector3(0, 1.7 + i * 0.72, 0), 1.22 - i * 0.23, 0.02, 1.85, "pine", 9)
			"broadleaf":
				cylinder(Vector3(0, 1.1, 0), 0.23, 0.12, 2.2, "wood")
				for i in 9:
					var angle := i * 2.4
					var p := Vector3(cos(angle) * 0.8, 2.5 + sin(i * 1.7) * 0.5, sin(angle) * 0.8)
					beam(Vector3(0, 1.1, 0), p, 0.16, "wood")
					blob(p, Vector3(1.0, 1.15, 0.95), "leaf" if i % 2 == 0 else "leaf_light")
			"rocks":
				for i in 5:
					blob(Vector3(rng.randf_range(-0.7, 0.7), 0.42, rng.randf_range(-0.5, 0.5)), Vector3(0.65, rng.randf_range(0.5, 1.1), 0.6), "stone_dark" if i % 2 == 0 else "stone")
			"fence": fence(Vector3.ZERO)
			"lantern": lantern()
			"cart": cart()
			"grass": grass()
			"bush": blob(Vector3(0, 0.45, 0), Vector3(0.65, 0.5, 0.6), "leaf")
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

func roof(center: Vector3, width: float, depth: float, rise: float, wood_roof := false) -> void:
	var half := width * 0.5
	var slope := atan2(rise, half)
	var length := sqrt(half * half + rise * rise)
	for side in [-1, 1]:
		box(center + Vector3(side * half * 0.5, rise * 0.5, 0), Vector3(length, 0.12, depth), "wood", Vector3(0, 0, -side * slope))
		for row in 6:
			var t := (row + 0.5) / 6.0
			for col in 9:
				var key: String = "plank" if wood_roof else ["slate", "slate_light", "slate_dark"][(row * 7 + col * 3 + col / 3) % 3]
				box(center + Vector3(side * half * t, rise * (1.0 - t) + 0.09 + float(6 - row) * 0.012, -depth * 0.5 + (col + 0.5) * depth / 9.0), Vector3(length / 6.0 + 0.045, 0.075, depth / 9.0 - 0.015), key, Vector3(0, 0, -side * slope))
		for z in [-depth * 0.5, depth * 0.5]:
			beam(center + Vector3(0, rise + 0.08, z), center + Vector3(side * half, 0.05, z), 0.13, "wood")
	box(center + Vector3(0, rise + 0.14, 0), Vector3(0.15, 0.14, depth + 0.12), "wood")

func window(p: Vector3) -> void:
	box(p, Vector3(0.55, 0.74, 0.10), "wood")
	box(p + Vector3(0, 0, 0.061), Vector3(0.42, 0.59, 0.03), "glass")
	box(p + Vector3(0, 0, 0.09), Vector3(0.045, 0.65, 0.04), "wood")
	box(p + Vector3(0, 0, 0.09), Vector3(0.48, 0.05, 0.04), "wood")
	box(p + Vector3(0, -0.40, 0.10), Vector3(0.7, 0.09, 0.26), "plank")

func cottage(kind: String) -> void:
	var w := 3.8 if kind == "TOWN_HALL" else 3.2
	var d := 2.8
	masonry(Vector3(0, 0.34, 0), Vector3(w, 0.68, d), 2)
	box(Vector3(0, 1.63, 0), Vector3(w - 0.1, 1.9, d - 0.1), "plaster")
	for x in [-w * 0.5 + 0.06, 0.0, w * 0.5 - 0.06]:
		for z in [-d * 0.5, d * 0.5]:
			box(Vector3(x, 1.6, z), Vector3(0.15, 2.0, 0.15), "wood")
	for y in [0.75, 2.5]:
		box(Vector3(0, y, 0), Vector3(w + 0.12, 0.16, d + 0.12), "wood")
	# Side elevations are visible when the player rotates a building.
	for side in [-1, 1]:
		for z in [-0.75, 0.75]:
			box(Vector3(side * w * 0.5, 1.62, z), Vector3(0.12, 1.7, 0.13), "wood")
			box(Vector3(side * (w * 0.5 + 0.035), 1.7, z + 0.28), Vector3(0.1, 0.68, 0.46), "wood")
			box(Vector3(side * (w * 0.5 + 0.095), 1.7, z + 0.28), Vector3(0.03, 0.54, 0.34), "glass")
			box(Vector3(side * (w * 0.5 + 0.12), 1.7, z + 0.28), Vector3(0.04, 0.60, 0.04), "wood")
			box(Vector3(side * (w * 0.5 + 0.12), 1.7, z + 0.28), Vector3(0.04, 0.04, 0.4), "wood")
	for x in [-1, 1]:
		beam(Vector3(x * (w * 0.5 - 0.1), 0.85, d * 0.5 + 0.05), Vector3(x * 0.55, 2.4, d * 0.5 + 0.05), 0.10, "wood")
		window(Vector3(x * w * 0.31, 1.65, d * 0.5 + 0.09))
	box(Vector3(0, 1.05, d * 0.5 + 0.10), Vector3(0.73, 1.43, 0.15), "wood")
	for i in 5:
		box(Vector3(-0.28 + i * 0.14, 1.04, d * 0.5 + 0.19), Vector3(0.12, 1.32, 0.06), "plank")
	for y in [0.68, 1.35]:
		box(Vector3(0, y, d * 0.5 + 0.24), Vector3(0.68, 0.055, 0.04), "iron")
	for i in 3:
		box(Vector3(0, 0.10 + i * 0.13, d * 0.5 + 0.62 - i * 0.17), Vector3(1.08, 0.2, 0.35), "stone")
	# Solid triangular gable under the shingle slopes.
	var prism := PrismMesh.new()
	prism.size = Vector3(w, 1.42, d)
	add(prism, Vector3(0, 3.21, 0), "plaster")
	roof(Vector3(0, 2.52, 0), w + 0.5, d + 0.5, 1.5)
	beam(Vector3(0, 2.55, d * 0.5 + 0.04), Vector3(0, 3.92, d * 0.5 + 0.04), 0.13, "wood")
	if kind == "TOWN_HALL":
		masonry(Vector3(0, 3.6, -0.65), Vector3(1.25, 2.7, 1.25), 7)
		window(Vector3(0, 4.4, 0.02))
		cylinder(Vector3(0, 5.65, -0.65), 1.15, 0.04, 1.65, "slate", 4, Vector3(0, PI / 4.0, 0))
		box(Vector3(0, 6.67, -0.65), Vector3(0.07, 0.6, 0.07), "wood")
		box(Vector3(0.32, 6.79, -0.65), Vector3(0.64, 0.35, 0.035), "slate_light")
	else:
		masonry(Vector3(1.05, 2.5, -0.5), Vector3(0.5, 4.3, 0.55), 12)
		box(Vector3(1.05, 4.68, -0.5), Vector3(0.67, 0.17, 0.7), "stone_dark")
		box(Vector3(1.05, 4.78, -0.5), Vector3(0.36, 0.03, 0.39), "iron")
	if kind == "BAKERY":
		masonry(Vector3(1.9, 0.65, 0.6), Vector3(1.1, 1.3, 1.15), 4)
		box(Vector3(1.9, 0.65, 1.21), Vector3(0.63, 0.66, 0.05), "iron")
		box(Vector3(1.9, 0.55, 1.25), Vector3(0.43, 0.38, 0.03), "glass")
		box(Vector3(-1.05, 0.85, 1.9), Vector3(1.15, 0.12, 0.52), "plank")
		for x in [-1.45, -0.65]:
			box(Vector3(x, 0.4, 1.9), Vector3(0.12, 0.8, 0.12), "wood")
		for i in 3:
			blob(Vector3(-1.4 + i * 0.3, 0.99, 1.9), Vector3(0.17, 0.10, 0.13), "glass")

func shed(lumber: bool) -> void:
	masonry(Vector3(0, 0.17, 0), Vector3(3.4, 0.34, 2.8), 1)
	for x in [-1.5, 1.5]:
		for z in [-1.2, 1.2]:
			box(Vector3(x, 1.35, z), Vector3(0.23, 2.4, 0.23), "wood")
			beam(Vector3(x, 1.55, z), Vector3(x * 0.62, 2.5, z), 0.14, "wood")
	for i in 13:
		box(Vector3(-1.5 + i * 0.25, 1.35, -1.25), Vector3(0.23, 2.1, 0.12), "plank")
	box(Vector3(0, 2.5, 0), Vector3(3.4, 0.18, 2.8), "wood")
	roof(Vector3(0, 2.52, 0), 3.9, 3.3, 1.25, true)
	if lumber:
		for i in 7:
			cylinder(Vector3(-0.9 + (i % 3) * 0.42, 0.48 + (i / 3) * 0.4, -0.35), 0.21, 0.21, 2.0, "plank", 8, Vector3(PI / 2.0, 0, 0))
		box(Vector3(0.8, 0.85, 0.65), Vector3(0.75, 0.12, 1.4), "plank")
		for z in [0.15, 1.15]:
			box(Vector3(0.8, 0.45, z), Vector3(0.55, 0.8, 0.15), "wood")
		cylinder(Vector3(0.8, 1.0, 0.55), 0.4, 0.4, 0.06, "iron", 20, Vector3(0, 0, PI / 2.0))
	else:
		for i in 6:
			box(Vector3(-0.85 + (i % 3) * 0.78, 0.65 + (i / 3) * 0.7, -0.3), Vector3(0.7, 0.65, 0.8), "plank")
			box(Vector3(-0.85 + (i % 3) * 0.78, 0.65 + (i / 3) * 0.7, 0.12), Vector3(0.07, 0.63, 0.07), "wood")

func tower() -> void:
	masonry(Vector3(0, 1.65, 0), Vector3(1.7, 3.3, 1.7), 9)
	box(Vector3(0, 3.4, 0), Vector3(2.5, 0.22, 2.5), "wood")
	for x in [-1, 1]:
		for z in [-1, 1]:
			box(Vector3(x, 4.1, z), Vector3(0.18, 1.6, 0.18), "wood")
		box(Vector3(0, 3.7, x * 1.1), Vector3(2.35, 0.45, 0.13), "plank")
		box(Vector3(x * 1.1, 3.7, 0), Vector3(0.13, 0.45, 2.35), "plank")
	roof(Vector3(0, 4.8, 0), 2.9, 2.9, 1.2)
	window(Vector3(0, 2.5, 0.91))
	box(Vector3(0, 0.7, 0.89), Vector3(0.65, 1.35, 0.1), "wood")

func castle() -> void:
	var base_h := 0.45
	masonry(Vector3(0, base_h * 0.5, 0), Vector3(5.8, base_h, 4.8), 1)
	for x in [-2.4, 2.4]:
		for z in [-1.9, 1.9]:
			masonry(Vector3(x, base_h + 0.08, z), Vector3(0.95, 0.16, 0.95), 1)
	var curtain_h := 1.85
	masonry(Vector3(0, base_h + curtain_h * 0.5, 0), Vector3(5.4, curtain_h, 0.24), 5)
	masonry(Vector3(0, base_h + curtain_h * 0.5, 1.9), Vector3(4.6, curtain_h, 0.24), 5)
	masonry(Vector3(0, base_h + curtain_h * 0.5, -1.9), Vector3(4.6, curtain_h, 0.24), 5)
	masonry(Vector3(-2.4, base_h + curtain_h * 0.5, 0), Vector3(0.24, curtain_h, 3.4), 5)
	masonry(Vector3(2.4, base_h + curtain_h * 0.5, 0), Vector3(0.24, curtain_h, 3.4), 5)
	for i in 12:
		var x := -2.3 + (i % 6) * 0.92
		box(Vector3(x, base_h + curtain_h + 0.18, 1.95), Vector3(0.32, 0.36, 0.32), "stone_light")
	for i in 12:
		var x := -2.3 + (i % 6) * 0.92
		box(Vector3(x, base_h + curtain_h + 0.18, -1.95), Vector3(0.32, 0.36, 0.32), "stone_light")
	var keep_pos := Vector3(0.1, 0, -0.4)
	cylinder(keep_pos + Vector3(0, base_h + 2.45, 0), 0.88, 0.82, 4.9, "stone", 12)
	for level in 3:
		window(keep_pos + Vector3(0, base_h + 1.3 + level * 0.95, 0.91))
	cylinder(keep_pos + Vector3(0, base_h + 5.1, 0), 0.96, 0.96, 0.18, "stone_dark")
	cylinder(keep_pos + Vector3(0, base_h + 6.15, 0), 0.86, 0.05, 2.2, "slate", 8)
	box(keep_pos + Vector3(0, base_h + 7.45, 0), Vector3(0.08, 0.7, 0.08), "wood")
	box(keep_pos + Vector3(0.4, base_h + 7.6, 0), Vector3(0.75, 0.42, 0.04), "slate_light")
	for i in 4:
		var angle := i * PI / 2.0
		var p := keep_pos + Vector3(cos(angle) * 0.82, base_h + 5.2, sin(angle) * 0.82)
		box(p, Vector3(0.28, 0.32, 0.28), "stone_light")
	var corners := [Vector3(-2.4, 0, 1.9), Vector3(2.4, 0, 1.9), Vector3(-2.4, 0, -1.9)]
	for corner in corners:
		cylinder(corner + Vector3(0, base_h + 1.85, 0), 0.75, 0.70, 3.7, "stone_light", 10)
		cylinder(corner + Vector3(0, base_h + 3.85, 0), 0.82, 0.82, 0.15, "stone_dark")
		cylinder(corner + Vector3(0, base_h + 4.75, 0), 0.74, 0.04, 1.85, "slate_dark", 6)
		box(corner + Vector3(0, base_h + 5.82, 0), Vector3(0.07, 0.55, 0.07), "wood")
		box(corner + Vector3(0.32, base_h + 5.92, 0), Vector3(0.62, 0.35, 0.035), "slate_light")
		for i in 3:
			var angle := i * TAU / 3.0
			var wp: Vector3 = corner + Vector3(cos(angle) * 0.65, base_h + 2.6, sin(angle) * 0.65)
			box(wp + Vector3(0, 0, cos(angle) * 0.08), Vector3(0.42, 0.58, 0.08), "wood")
			box(wp + Vector3(0, 0, cos(angle) * 0.13), Vector3(0.32, 0.44, 0.03), "glass")
	masonry(Vector3(0, base_h + 0.75, 1.95), Vector3(1.25, 1.5, 0.24), 4)
	box(Vector3(0, base_h + 0.75, 2.09), Vector3(0.68, 1.15, 0.08), "wood")
	for i in 5:
		box(Vector3(-0.26 + i * 0.13, base_h + 0.75, 2.15), Vector3(0.11, 1.05, 0.05), "plank")
	for y_val in [0.42, 1.0]:
		box(Vector3(0, base_h + y_val, 2.2), Vector3(0.62, 0.05, 0.035), "iron")

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

func extended_building(kind: String) -> void:
	match kind:
		"QUARRY":
			masonry(Vector3(0, 0.18, 0), Vector3(4.0, 0.36, 3.4), 1)
			for i in 6:
				blob(Vector3(-1.3 + (i % 3) * 0.7, 0.7, -0.6 + (i / 3) * 0.8), Vector3(0.6, 0.7, 0.6), "stone_dark")
			box(Vector3(1.0, 1.55, -0.8), Vector3(0.25, 3.0, 0.25), "wood")
			beam(Vector3(1.0, 2.85, -0.8), Vector3(-0.5, 2.85, 0.9), 0.18, "wood")
			beam(Vector3(1.0, 1.6, -0.8), Vector3(-0.35, 2.85, 0.7), 0.14, "wood")
			box(Vector3(-0.5, 1.9, 0.9), Vector3(0.035, 1.9, 0.035), "iron")
			box(Vector3(-0.5, 0.85, 0.9), Vector3(0.6, 0.4, 0.65), "stone_light")
		"BARRACKS":
			cottage("HOUSE")
			for side in [-1, 1]:
				box(Vector3(side * 1.9, 1.4, 1.6), Vector3(0.10, 2.8, 0.10), "wood")
				box(Vector3(side * 1.65, 2.3, 1.6), Vector3(0.5, 0.8, 0.06), "slate")
				box(Vector3(side * 1.65, 2.3, 1.65), Vector3(0.08, 0.55, 0.035), "grain")
			box(Vector3(0, 0.55, -1.8), Vector3(2.6, 0.10, 0.3), "wood")
			for i in 5:
				beam(Vector3(-1 + i * 0.5, 0.2, -1.8), Vector3(-1 + i * 0.5, 1.5, -1.8), 0.07, "iron")
		"LUMEN_PILLAR":
			cylinder(Vector3(0, 0.18, 0), 0.8, 0.75, 0.36, "stone_dark")
			cylinder(Vector3(0, 0.44, 0), 0.64, 0.56, 0.20, "stone")
			cylinder(Vector3(0, 1.12, 0), 0.36, 0.26, 1.2, "stone_light")
			cylinder(Vector3(0, 1.78, 0), 0.47, 0.47, 0.18, "iron")
			cylinder(Vector3(0, 2.05, 0), 0.28, 0.02, 0.6, "glass", 6)
			for i in 4:
				var angle := i * PI / 2.0
				beam(Vector3(cos(angle) * 0.38, 1.7, sin(angle) * 0.38), Vector3(cos(angle) * 0.25, 2.2, sin(angle) * 0.25), 0.06, "iron")
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