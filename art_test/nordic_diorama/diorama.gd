extends Node3D
## Nordic Storybook 3D Diorama. Real sculpted 3D, one sun, engine shadows.
## All geometry procedural at build; soft smooth-shaded forms only.

const A := "res://art_test/nordic_diorama/assets/"
var mats := {}
var noise := FastNoiseLite.new()
var plots := []
var plot_h := []
var routes := []
var route_samples := []
var villagers := []
var sun: DirectionalLight3D
var shot_path := ""
var frames_dir := ""
var frames_target := 0
var frames_saved := 0
var frame_count := 0
var capturing := false
var no_shadow := false

func _ready() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	_parse_args()
	noise.seed = 12345
	noise.frequency = 0.16
	_define_routes()
	_define_plots()
	_make_materials()
	_build_environment()
	_build_terrain()
	_build_paths()
	_build_castle()
	_build_cottages()
	_build_mountain_mine()
	_build_forest()
	_build_villagers()

func _define_routes() -> void:
	routes = [
		[Vector2(-4, -1), Vector2(-11, 3), Vector2(-18, 6.2)],
		[Vector2(-4, -1), Vector2(1, 4.5), Vector2(5, 9.8)],
		[Vector2(-4, -1), Vector2(6, 0), Vector2(15, 2.5), Vector2(18, 3.2)],
		[Vector2(18, 3.2), Vector2(22, -1), Vector2(24.5, -6)],
		[Vector2(-18, 6.2), Vector2(-8, 10), Vector2(5, 9.8)],
	]
	for r in routes:
		route_samples.append(_sample_route(r))

func _sample_route(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(pts.size() - 1):
		var p0: Vector2 = pts[max(i - 1, 0)]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[i + 1]
		var p3: Vector2 = pts[min(i + 2, pts.size() - 1)]
		for s in range(14):
			var t := float(s) / 14.0
			var q: Vector2 = 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t)
			out.append(q)
	out.append(pts[pts.size() - 1])
	return out

func _define_plots() -> void:
	plots = [
		[Vector2(-4, -8), 13.0],
		[Vector2(-20, 7), 7.5],
		[Vector2(6, 11), 7.5],
		[Vector2(19, 4), 7.5],
		[Vector2(24, -8), 9.5],
	]
	for p in plots:
		plot_h.append(_base_h(p[0].x, p[0].y))

func _sstep(a: float, b: float, x: float) -> float:
	var t := clampf((x - a) / (b - a), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func _base_h(x: float, z: float) -> float:
	var h := 1.1 * sin(x * 0.045 + 1.7) * cos(z * 0.05)
	h += 0.9 * sin(x * 0.021 - 0.6) * sin(z * 0.033 + 1.2)
	h += 0.45 * sin((x + z) * 0.08)
	h += 5.5 * exp(-((x - 36.0) * (x - 36.0) + (z + 20.0) * (z + 20.0)) / (2.0 * 16.0 * 16.0))
	h += 2.6 * exp(-((x + 42.0) * (x + 42.0) + (z + 26.0) * (z + 26.0)) / (2.0 * 14.0 * 14.0))
	h += 2.2 * exp(-((x - 30.0) * (x - 30.0) + (z - 26.0) * (z - 26.0)) / (2.0 * 15.0 * 15.0))
	h += 1.8 * exp(-((x + 38.0) * (x + 38.0) + (z - 24.0) * (z - 24.0)) / (2.0 * 13.0 * 13.0))
	return h

func _path_dist(x: float, z: float) -> float:
	var best := 1e9
	var p := Vector2(x, z)
	for r in routes:
		for i in range(r.size() - 1):
			var a: Vector2 = r[i]
			var b: Vector2 = r[i + 1]
			var ab := b - a
			var t := 0.0
			if ab.length() > 0.001:
				t = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
			best = min(best, p.distance_to(a + ab * t))
	return best

func _h(x: float, z: float) -> float:
	var h := _base_h(x, z)
	for i in range(plots.size()):
		var c: Vector2 = plots[i][0]
		var r: float = plots[i][1]
		var d := Vector2(x, z).distance_to(c)
		var w := 1.0 - _sstep(r * 0.55, r, d)
		h = lerpf(h, plot_h[i], w * 0.92)
	var pd := _path_dist(x, z)
	h -= 0.17 * (1.0 - _sstep(1.0, 2.6, pd))
	return h

func _normal(x: float, z: float) -> Vector3:
	var e := 0.4
	var dx := _h(x + e, z) - _h(x - e, z)
	var dz := _h(x, z + e) - _h(x, z - e)
	return Vector3(-dx, 2.0 * e, -dz).normalized()

func _make_materials() -> void:
	mats["grass"] = _mat("grass.png", Color(0.58, 0.68, 0.52))
	mats["dirt"] = _mat("dirt.png", Color(0.88, 0.82, 0.72))
	mats["stone"] = _mat("stone.png", Color(0.92, 0.92, 0.90))
	mats["rock"] = _mat("rock.png", Color(0.88, 0.86, 0.82))
	mats["wood"] = _mat("wood.png", Color(1, 1, 1))
	mats["wood_dark"] = _mat("wood.png", Color(0.55, 0.42, 0.32))
	mats["plaster"] = _mat("plaster.png", Color(1, 1, 1))
	mats["thatch"] = _mat("thatch.png", Color(1, 1, 1))
	mats["slate"] = _mat("slate.png", Color(1, 1, 1))
	mats["terra"] = _mat("shingle.png", Color(0.82, 0.48, 0.36))
	mats["dark"] = _plain(Color(0.16, 0.12, 0.10))
	mats["skin"] = _plain(Color(0.93, 0.78, 0.62))
	mats["trunk"] = _mat("wood.png", Color(0.5, 0.38, 0.28))
	mats["pine0"] = _mat("grass.png", Color(0.36, 0.56, 0.32))
	mats["pine1"] = _mat("grass.png", Color(0.42, 0.62, 0.37))
	mats["pine2"] = _mat("grass.png", Color(0.32, 0.50, 0.29))
	mats["leaf0"] = _mat("grass.png", Color(0.44, 0.63, 0.31))
	mats["leaf1"] = _mat("grass.png", Color(0.40, 0.58, 0.28))
	mats["leaf2"] = _mat("grass.png", Color(0.49, 0.67, 0.34))
	mats["bush"] = _mat("grass.png", Color(0.48, 0.68, 0.36))

func _mat(texfile: String, tint: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(A + texfile)
	m.albedo_color = tint
	m.roughness = 0.95
	m.set("texture_repeat", 1)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m

func _plain(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	return m

func _build_environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.36, 0.56, 0.76)
	sm.sky_horizon_color = Color(0.78, 0.84, 0.80)
	sm.ground_bottom_color = Color(0.42, 0.48, 0.36)
	sm.ground_horizon_color = Color(0.72, 0.78, 0.70)
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.30
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.95, 0.86)
	sun.light_energy = 0.55
	sun.shadow_enabled = not no_shadow
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 0.5
	sun.directional_shadow_max_distance = 220.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	add_child(sun)
	sun.look_at_from_position(Vector3(-38, 46, -20), Vector3(4, 0, 2), Vector3.UP)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 50.0
	var target := Vector3(2, 1.0, -3)
	var dir := Vector3(0.557, 0.616, 0.557).normalized()
	cam.look_at_from_position(target + dir * 80.0, target, Vector3.UP)
	cam.current = true
	add_child(cam)

func _build_terrain() -> void:
	var seg_x := 272
	var seg_z := 200
	var size_x := 136.0
	var size_z := 100.0
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	for j in range(seg_z + 1):
		for i in range(seg_x + 1):
			var x := -size_x * 0.5 + size_x * float(i) / seg_x
			var z := -size_z * 0.5 + size_z * float(j) / seg_z
			verts.append(Vector3(x, _h(x, z), z))
			normals.append(_normal(x, z))
			uvs.append(Vector2((x + 68.0) / 13.0, (z + 50.0) / 13.0))
	for j in range(seg_z):
		for i in range(seg_x):
			var a := j * (seg_x + 1) + i
			var b := a + 1
			var c := a + seg_x + 1
			var d := c + 1
			idx.append_array([a, b, c, b, d, c])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mats["grass"]
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)

func _build_paths() -> void:
	for samples in route_samples:
		var verts := PackedVector3Array()
		var normals := PackedVector3Array()
		var uvs := PackedVector2Array()
		var idx := PackedInt32Array()
		var dist_acc := 0.0
		for i in range(samples.size()):
			var p: Vector2 = samples[i]
			var tangent := Vector2(1, 0)
			if i < samples.size() - 1:
				tangent = (samples[i + 1] - p)
			elif i > 0:
				tangent = (p - samples[i - 1])
			tangent = tangent.normalized()
			var perp := Vector2(-tangent.y, tangent.x)
			if i > 0:
				dist_acc += p.distance_to(samples[i - 1])
			for side in [-0.85, 0.85]:
				var q: Vector2 = p + perp * side
				verts.append(Vector3(q.x, _h(q.x, q.y) + 0.05, q.y))
				normals.append(_normal(q.x, q.y))
				uvs.append(Vector2((side + 0.85) / 1.7, dist_acc / 2.2))
			if i > 0:
				var a := (i - 1) * 2
				idx.append_array([a, a + 2, a + 1, a + 1, a + 2, a + 3])
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_INDEX] = idx
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mats["dirt"]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)

func _put(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, ry: float = 0.0, sc: Vector3 = Vector3.ONE, rx: float = 0.0, rz: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	if mat != null:
		mi.material_override = mat
	mi.position = pos
	mi.rotation = Vector3(rx, ry, rz)
	mi.scale = sc
	parent.add_child(mi)
	return mi

func _box(sx: float, sy: float, sz: float) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(sx, sy, sz)
	return m

func _cyl(rt: float, rb: float, h: float, seg: int = 20) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = rt
	m.bottom_radius = rb
	m.height = h
	m.radial_segments = seg
	return m

func _sph(r: float, seg: int = 20, rings: int = 14) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = seg
	m.rings = rings
	return m

func _cone(r: float, h: float, seg: int = 20) -> CylinderMesh:
	return _cyl(0.02, r, h, seg)

func _displaced_sphere(radius: float, seed_off: Vector3, amp: float, freq: float, seg: int = 22, rings: int = 16) -> ArrayMesh:
	var sm := _sph(radius, seg, rings)
	var arrays := sm.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var n2 := FastNoiseLite.new()
	n2.seed = int(seed_off.x * 100.0) + 7
	n2.frequency = freq
	for i in range(verts.size()):
		var v := verts[i]
		var pp := v * 2.2 + seed_off
		var swell := n2.get_noise_3dv(pp * 0.55)
		var ridge: float = 1.0 - absf(n2.get_noise_3dv(pp * 1.9 + Vector3(11.0, 5.0, 7.0)))
		var detail := n2.get_noise_3dv(pp * 3.1 + Vector3(3.0, 9.0, 1.0))
		var d: float = amp * (swell * 0.55 + (ridge - 0.58) * 0.85 + detail * 0.30)
		verts[i] = v + norms[i] * d
	var acc := []
	acc.resize(verts.size())
	for i in range(verts.size()):
		acc[i] = Vector3.ZERO
	for f in range(0, idx.size(), 3):
		var a := idx[f]
		var b := idx[f + 1]
		var c := idx[f + 2]
		var fn := (verts[b] - verts[a]).cross(verts[c] - verts[a])
		acc[a] += fn
		acc[b] += fn
		acc[c] += fn
	for i in range(verts.size()):
		norms[i] = acc[i].normalized()
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _ground_group(x: float, z: float, sink: float = 0.12) -> Node3D:
	var g := Node3D.new()
	g.position = Vector3(x, _h(x, z) - sink, z)
	add_child(g)
	return g

func _build_castle() -> void:
	var g := _ground_group(-4.0, -8.0, 0.15)
	_put(g, _box(8.6, 4.6, 6.4), mats["stone"], Vector3(0, 2.3, -0.6))
	_put(g, _box(9.4, 0.7, 7.2), mats["stone"], Vector3(0, 4.85, -0.6))
	for bx in [-4.2, -2.5, -0.8, 0.8, 2.5, 4.2]:
		_put(g, _box(0.85, 0.85, 0.85), mats["stone"], Vector3(bx, 5.6, -3.6))
		_put(g, _box(0.85, 0.85, 0.85), mats["stone"], Vector3(bx, 5.6, 2.4))
	_put(g, _cyl(1.75, 1.95, 8.6, 22), mats["stone"], Vector3(-4.6, 4.3, 1.8))
	_put(g, _cyl(1.75, 1.95, 8.6, 22), mats["stone"], Vector3(3.4, 4.3, 1.8))
	_put(g, _cyl(2.05, 2.25, 10.6, 22), mats["stone"], Vector3(-0.6, 5.3, -3.4))
	_put(g, _cone(2.6, 3.6, 22), mats["terra"], Vector3(-4.6, 10.4, 1.8))
	_put(g, _cone(2.6, 3.6, 22), mats["terra"], Vector3(3.4, 10.4, 1.8))
	_put(g, _cone(3.1, 4.4, 22), mats["terra"], Vector3(-0.6, 12.8, -3.4))
	var roof := PrismMesh.new()
	roof.size = Vector3(5.4, 2.6, 7.4)
	_put(g, roof, mats["terra"], Vector3(0, 6.5, -0.6), PI * 0.5)
	_put(g, _box(1.7, 2.9, 0.35), mats["wood_dark"], Vector3(-0.6, 1.45, 2.65))
	_put(g, _box(2.3, 0.35, 0.9), mats["stone"], Vector3(-0.6, 0.18, 3.1))
	for tpos in [Vector3(-4.6, 5.6, 3.15), Vector3(3.4, 5.6, 3.15), Vector3(-0.6, 7.6, -1.35), Vector3(-1.9, 3.2, 2.65), Vector3(1.6, 3.2, 2.65)]:
		_put(g, _box(0.42, 0.62, 0.3), mats["dark"], tpos)

func _cottage(x: float, z: float, ry: float, wall_mat: Material, roof_mat: Material, kind: int) -> void:
	var g := _ground_group(x, z, 0.12)
	g.rotation.y = ry
	_put(g, _box(5.4, 2.9, 4.4), wall_mat, Vector3(0, 1.45, 0))
	if kind == 0:
		for bx in [-2.68, 2.68]:
			_put(g, _box(0.28, 2.9, 4.44), mats["wood_dark"], Vector3(bx, 1.45, 0))
		_put(g, _box(5.44, 0.26, 4.44), mats["wood_dark"], Vector3(0, 2.85, 0))
	var roof := PrismMesh.new()
	roof.size = Vector3(5.3, 2.5, 6.3)
	_put(g, roof, roof_mat, Vector3(0, 4.05, 0), PI * 0.5)
	_put(g, _box(0.7, 1.5, 0.7), mats["stone"], Vector3(1.7, 5.3, -0.9))
	_put(g, _box(1.1, 2.0, 0.25), mats["wood_dark"], Vector3(-0.9, 1.0, 2.24))
	_put(g, _box(0.62, 0.62, 0.2), mats["dark"], Vector3(1.2, 1.7, 2.24))
	_put(g, _box(0.62, 0.62, 0.2), mats["dark"], Vector3(-2.0, 1.7, 2.24))
	if kind == 2:
		_put(g, _box(5.5, 0.5, 4.5), mats["stone"], Vector3(0, 0.25, 0))

func _build_cottages() -> void:
	_cottage(-20.0, 7.0, 0.5, mats["plaster"], mats["thatch"], 0)
	_cottage(6.0, 11.0, -0.35, mats["stone"], mats["slate"], 2)
	_cottage(19.0, 4.0, -0.9, mats["wood"], mats["terra"], 1)

func _build_mountain_mine() -> void:
	var rock_mesh := _displaced_sphere(11.0, Vector3(3, 1, 2), 3.8, 0.35, 48, 32)
	var mg := _ground_group(34.0, -19.0, 1.4)
	_put(mg, rock_mesh, mats["rock"], Vector3(0, 3.4, 0), 0.7, Vector3(1.35, 0.88, 1.08))
	_put(mg, rock_mesh, mats["rock"], Vector3(-9.5, 1.2, 4.5), 2.4, Vector3(0.8, 0.5, 0.7))
	_put(mg, rock_mesh, mats["rock"], Vector3(8.5, 0.8, 5.5), 4.2, Vector3(0.65, 0.42, 0.6))
	var eg := Node3D.new()
	eg.position = Vector3(24.2, _h(24.2, -8.2) - 0.1, -8.2)
	eg.rotation.y = 0.785
	add_child(eg)
	_put(eg, _box(3.0, 3.1, 0.6), mats["dark"], Vector3(0, 1.55, 0))
	_put(eg, _box(0.32, 3.5, 0.32), mats["wood_dark"], Vector3(-1.55, 1.75, 0.25))
	_put(eg, _box(0.32, 3.5, 0.32), mats["wood_dark"], Vector3(1.55, 1.75, 0.25))
	_put(eg, _box(3.6, 0.34, 0.36), mats["wood_dark"], Vector3(0, 3.55, 0.25))
	_put(eg, _box(3.8, 0.3, 0.5), mats["wood"], Vector3(0, 3.95, 0.1), 0.0, Vector3.ONE, -0.18)
	_put(eg, _box(0.16, 0.1, 5.6), mats["dark"], Vector3(-0.55, 0.3, 2.9), 0.0, Vector3.ONE, 0.05)
	_put(eg, _box(0.16, 0.1, 5.6), mats["dark"], Vector3(0.55, 0.3, 2.9), 0.0, Vector3.ONE, 0.05)
	for i in range(7):
		var t := float(i)
		_put(eg, _box(1.6, 0.09, 0.3), mats["wood_dark"], Vector3(0, 0.24 - t * 0.018, 0.7 + t * 0.72))
	var rock_small := _displaced_sphere(1.0, Vector3(9, 2, 5), 0.22, 0.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	for i in range(14):
		var ang := rng.randf_range(2.6, 4.4)
		var rad := rng.randf_range(7.0, 12.5)
		var px := 30.0 + cos(ang) * rad
		var pz := -14.0 + sin(ang) * rad * 0.8
		var sg := _ground_group(px, pz, 0.25)
		var s := rng.randf_range(0.5, 1.6)
		_put(sg, rock_small, mats["rock"], Vector3(0, 0.25, 0), rng.randf_range(0, 3.0), Vector3(s, s * 0.75, s))

func _build_forest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var cone_meshes := [_cone(1.5, 2.6, 18), _cone(1.15, 2.2, 18), _cone(0.75, 1.9, 18)]
	var trunk_c := _cyl(0.15, 0.23, 1.3, 10)
	var trunk_b := _cyl(0.17, 0.26, 1.7, 10)
	var canopy_a := _displaced_sphere(1.55, Vector3(5, 3, 1), 0.20, 0.55)
	var canopy_b := _displaced_sphere(1.1, Vector3(8, 1, 4), 0.16, 0.6)
	var pine_mats := [mats["pine0"], mats["pine1"], mats["pine2"]]
	var leaf_mats := [mats["leaf0"], mats["leaf1"], mats["leaf2"]]
	var clusters := [
		[Vector2(-38, -24), 5], [Vector2(-14, -26), 5], [Vector2(8, -26), 4], [Vector2(19, -25), 4],
		[Vector2(-41, -6), 4], [Vector2(-38, 14), 4], [Vector2(-16, 25), 4], [Vector2(8, 26), 4],
		[Vector2(30, 23), 3], [Vector2(43, -4), 3], [Vector2(-30, -15), 3], [Vector2(44, 12), 2],
	]
	for cl in clusters:
		var centre: Vector2 = cl[0]
		var count: int = cl[1]
		for k in range(count):
			var placed := false
			for attempt in range(12):
				var px := centre.x + rng.randf_range(-5.5, 5.5)
				var pz := centre.y + rng.randf_range(-4.5, 4.5)
				if abs(px) > 62.0 or abs(pz) > 45.0:
					continue
				if Vector2(px, pz).distance_to(Vector2(-4, -8)) < 14.5:
					continue
				if Vector2(px, pz).distance_to(Vector2(34, -19)) < 13.5:
					continue
				var near_plot := false
				for p in plots:
					if Vector2(px, pz).distance_to(p[0]) < p[1] * 0.85:
						near_plot = true
				if near_plot:
					continue
				if _path_dist(px, pz) < 2.7:
					continue
				placed = true
				var is_conifer := rng.randf() < 0.65
				var sc := rng.randf_range(0.85, 1.35)
				var g := _ground_group(px, pz, 0.1)
				var n := _normal(px, pz)
				g.rotation = Vector3(n.z * 0.35, rng.randf_range(0, 6.28), -n.x * 0.35)
				if is_conifer:
					var pm: Material = pine_mats[rng.randi_range(0, 2)]
					_put(g, trunk_c, mats["trunk"], Vector3(0, 0.6, 0))
					_put(g, cone_meshes[0], pm, Vector3(0, 2.3, 0))
					_put(g, cone_meshes[1], pm, Vector3(0.08, 3.7, 0.05))
					_put(g, cone_meshes[2], pm, Vector3(-0.05, 5.0, -0.04))
				else:
					var lm: Material = leaf_mats[rng.randi_range(0, 2)]
					_put(g, trunk_b, mats["trunk"], Vector3(0, 0.8, 0))
					_put(g, canopy_a, lm, Vector3(0, 2.75, 0), rng.randf_range(0, 3.0), Vector3(1.25, 1.05, 1.25))
					_put(g, canopy_b, lm, Vector3(0.8, 3.6, 0.3), rng.randf_range(0, 3.0), Vector3(1.15, 1.0, 1.15))
				g.scale = Vector3.ONE * sc
				break
			if not placed:
				pass
	var bush_spots := [Vector2(-13, 12), Vector2(13, 16), Vector2(-26, -1), Vector2(11, -13), Vector2(-9, 20), Vector2(24, 14), Vector2(-33, 6), Vector2(3, -17)]
	for bp in bush_spots:
		if _path_dist(bp.x, bp.y) < 2.4:
			continue
		var bg := _ground_group(bp.x, bp.y, 0.08)
		var bs := rng.randf_range(0.55, 0.95)
		_put(bg, canopy_b, mats["bush"], Vector3(0, 0.68, 0), rng.randf_range(0, 3.0), Vector3(bs * 1.25, bs * 0.95, bs * 1.25))

func _build_villagers() -> void:
	var shirt_cols := [Color(0.65, 0.25, 0.2), Color(0.25, 0.4, 0.65), Color(0.75, 0.58, 0.25), Color(0.35, 0.5, 0.3)]
	var speeds := [1.35, 1.15, 1.25, 1.0]
	for i in range(4):
		var g := Node3D.new()
		add_child(g)
		var sm := _plain(shirt_cols[i])
		var body := CapsuleMesh.new()
		body.radius = 0.17
		body.height = 0.82
		_put(g, body, sm, Vector3(0, 0.62, 0))
		_put(g, _sph(0.15, 14, 10), mats["skin"], Vector3(0, 1.2, 0))
		_put(g, _sph(0.16, 14, 10), mats["wood_dark"], Vector3(0, 1.31, 0), 0.0, Vector3(1, 0.55, 1))
		var route_idx: int = [0, 1, 3, 4][i]
		villagers.append({"node": g, "samples": route_samples[route_idx], "u": 0.22 * float(i) + 0.08, "speed": speeds[i] / 30.0, "dir": 1.0, "phase": float(i) * 1.9})

func _process(delta: float) -> void:
	var time := Time.get_ticks_msec() / 1000.0
	for v in villagers:
		var samples: PackedVector2Array = v["samples"]
		var n := samples.size()
		v["u"] += v["speed"] * v["dir"] * delta * 10.0
		if v["u"] >= 1.0:
			v["u"] = 1.0
			v["dir"] = -1.0
		if v["u"] <= 0.0:
			v["u"] = 0.0
			v["dir"] = 1.0
		var fidx: float = float(v["u"]) * float(n - 1)
		var i0 := int(floor(fidx))
		var i1 := mini(i0 + 1, n - 1)
		var frac: float = fidx - float(i0)
		var pos := samples[i0].lerp(samples[i1], frac)
		var node: Node3D = v["node"]
		var bob: float = abs(sin(time * 8.0 + v["phase"])) * 0.045
		node.position = Vector3(pos.x, _h(pos.x, pos.y) + 0.06 + bob, pos.y)
		node.rotation.z = sin(time * 8.0 + v["phase"]) * 0.045
	_capture_logic()

func _parse_args() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		if args[i] == "--dio-shot" and i + 1 < args.size():
			shot_path = args[i + 1]
		if args[i] == "--dio-frames" and i + 2 < args.size():
			frames_dir = args[i + 1]
			frames_target = int(args[i + 2]) * 30
		if args[i] == "--dio-noshadow":
			no_shadow = true
		i += 1

func _capture_logic() -> void:
	if capturing:
		return
	frame_count += 1
	if shot_path != "" and frame_count == 25:
		capturing = true
		_do_capture(shot_path)
	elif frames_dir != "" and frame_count > 15 and frames_saved < frames_target and frame_count % 2 == 0:
		capturing = true
		_do_capture(frames_dir + "/frame_%04d.png" % frames_saved)

func _do_capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	if shot_path != "" and frames_dir == "":
		print("DIORAMA draws=", int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), " prims=", int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)), " shot=", path)
		get_tree().quit()
		return
	frames_saved += 1
	capturing = false
	if frames_saved >= frames_target:
		print("DIORAMA draws=", int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), " prims=", int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)), " frames done=", frames_saved)
		get_tree().quit()
