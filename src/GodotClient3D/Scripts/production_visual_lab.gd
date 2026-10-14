extends RefCounted
## VisualLab (lab harness only, never shipped): builds candidate building models
## for the A/B/C comparison on identical greybox terrain.
##   A = current game buildings (no factory, normal path)
##   B = Quaternius Medieval Village MegaKit (Standard, CC0), Nordic-adapted:
##       falu-red plaster + dark timber, steep own-geometry shingle roofs, stone plinth
##   C = original Nordic kit: Kenney Fantasy Town (CC0) plank walls + KayKit/Kenney props
##       + own geometry (steep turf roofs, log plinth, corner posts)
## Town Hall, Wyrd crater and Lumen are never replaced.
## Assets come from tools/visuallab/fetch_assets.sh (gitignored, excluded from export).

const TILE := 2.5
const QM := "res://assets/visuallab/quaternius_mvm/"
const KN := "res://assets/visuallab/kenney_ftk/"
const KEEP_OURS := ["TOWN_HALL", "CASTLE", "WALL", "LUMEN_PILLAR", "CLAIMANT_OUTPOST", "WYRD_HARVESTER", "WYRD_REFINER", "CONSTRUCTION_SITE", "ROAD"]

static var _cache := {}
static var _mats := {}


static func candidate() -> String:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--lab-candidate="):
			return String(a).trim_prefix("--lab-candidate=").to_upper()
	return ""


static func build(kit: String, building_type: String, footprint: Vector2i, entity_id: int) -> Node3D:
	if kit != "B" and kit != "C":
		return null
	if building_type in KEEP_OURS:
		return null
	var root := Node3D.new()
	root.name = "Lab%s_%s" % [kit, building_type]
	var bw := float(footprint.x) * TILE
	var bd := float(footprint.y) * TILE
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s%d" % [building_type, entity_id])
	match building_type:
		"HOUSE":
			_house(root, kit, bw - 0.9, bd - 1.1, 1, true, rng)
		"BAKERY":
			_house(root, kit, bw - 2.2, bd - 2.6, 1, true, rng)
			_chimney(root, kit, Vector3((bw - 2.2) * 0.25, 0, 0), 4.6)
		"STOREHOUSE", "BARRACKS":
			_house(root, kit, bw - 1.2, bd - 2.4, 1, false, rng)
		"LUMBER_CAMP", "SAWMILL", "QUARRY":
			_shed(root, kit, bw - 3.0, bd - 3.4, rng)
		"FARM":
			var barn := Node3D.new()
			barn.position = Vector3(-bw * 0.25, 0, -bd * 0.18)
			root.add_child(barn)
			_house(barn, kit, bw * 0.42, bd * 0.5, 1, false, rng)
		"WATCHTOWER":
			_tower(root, kit)
		_:
			_house(root, kit, maxf(2.0, bw - 1.2), maxf(2.0, bd - 1.2), 1, false, rng)
	return root


# ---------------------------------------------------------------- archetypes

static func _house(root: Node3D, kit: String, w: float, d: float, floors: int, chimney: bool, rng: RandomNumberGenerator) -> void:
	var wall_h := 2.5 * floors
	_plinth(root, kit, w + 0.3, d + 0.3)
	_walls(root, kit, w, d, wall_h, rng)
	_roof(root, kit, w, d, wall_h + 0.35, 0.55)
	if chimney:
		_chimney(root, kit, Vector3(-w * 0.28, 0, -d * 0.1), wall_h + 2.6)


static func _shed(root: Node3D, kit: String, w: float, d: float, rng: RandomNumberGenerator) -> void:
	# Open-fronted work shed: posts, back wall, roof.
	var h := 2.6
	_plinth(root, kit, w + 0.3, d + 0.3)
	for p in [Vector3(-w / 2, 0, -d / 2), Vector3(w / 2, 0, -d / 2), Vector3(-w / 2, 0, d / 2), Vector3(w / 2, 0, d / 2), Vector3(0, 0, d / 2)]:
		_post(root, kit, p, h)
	_wall_run(root, kit, Vector3(0, 0, -d / 2), Vector3(0, 0, -1), w, h, "solid", rng)
	_roof(root, kit, w, d, h + 0.3, 0.6)


static func _tower(root: Node3D, kit: String) -> void:
	var s := 1.9
	var h := 6.5
	for p in [Vector3(-s / 2, 0, -s / 2), Vector3(s / 2, 0, -s / 2), Vector3(-s / 2, 0, s / 2), Vector3(s / 2, 0, s / 2)]:
		_post(root, kit, p, h)
	var deck := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(s + 0.7, 0.18, s + 0.7)
	deck.mesh = bm
	deck.position.y = h - 1.3
	deck.material_override = _wood_mat(kit)
	root.add_child(deck)
	_roof(root, kit, s + 0.2, s + 0.2, h, 0.45)


# ---------------------------------------------------------------- pieces

static func _plinth(root: Node3D, kit: String, w: float, d: float) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(w, 0.45, d)
	m.mesh = bm
	m.position.y = 0.1
	m.material_override = _stone_mat() if kit == "B" else _log_mat()
	root.add_child(m)


static func _walls(root: Node3D, kit: String, w: float, d: float, h: float, rng: RandomNumberGenerator) -> void:
	_wall_run(root, kit, Vector3(0, 0, d / 2), Vector3(0, 0, 1), w, h, "front", rng)
	_wall_run(root, kit, Vector3(0, 0, -d / 2), Vector3(0, 0, -1), w, h, "window", rng)
	_wall_run(root, kit, Vector3(w / 2, 0, 0), Vector3(1, 0, 0), d, h, "window", rng)
	_wall_run(root, kit, Vector3(-w / 2, 0, 0), Vector3(-1, 0, 0), d, h, "solid", rng)
	for p in [Vector3(-w / 2, 0, -d / 2), Vector3(w / 2, 0, -d / 2), Vector3(-w / 2, 0, d / 2), Vector3(w / 2, 0, d / 2)]:
		_post(root, kit, p, h)


## A straight wall of kit modules centred on `centre`, facing outward `n`, `length` long.
static func _wall_run(root: Node3D, kit: String, centre: Vector3, n: Vector3, length: float, h: float, role: String, rng: RandomNumberGenerator) -> void:
	var count := maxi(1, int(round(length / (2.4 if kit == "B" else 2.2))))
	var mw := length / count
	var along := Vector3(-n.z, 0, n.x)
	for i in count:
		var off := (float(i) + 0.5 - float(count) / 2.0) * mw
		var piece := ""
		var mid := i == count / 2
		if kit == "B":
			piece = "Wall_Plaster_WoodGrid.gltf"
			if role == "front" and mid:
				piece = "Wall_Plaster_Door_Flat.gltf"
			elif role != "solid" and (i % 2 == 1 or count == 1):
				piece = "Wall_Plaster_Window_Wide_Flat.gltf"
		else:
			piece = "wall-wood.glb"
			if role == "front" and mid:
				piece = "wall-wood-door.glb"
			elif role != "solid" and (i % 2 == 1 or count == 1):
				piece = "wall-wood-window-shutters.glb"
		var node := _instance((QM if kit == "B" else KN) + piece)
		if node == null:
			continue
		var pos := centre + along * off
		if kit == "B":
			# Quaternius walls: 2 m along X, 3.12 m tall, face +Z.
			node.basis = Basis(Vector3.UP, atan2(n.x, n.z)).scaled(Vector3(mw / 2.0, h / 3.12, 1.0))
			node.position = pos
			_tint(node, kit)
		else:
			# Kenney walls: 1 m cell, panel on the cell's +X edge.
			node.basis = Basis(Vector3.UP, atan2(-n.z, n.x)).scaled(Vector3(mw, h, mw))
			node.position = pos - n * (mw * 0.45)
			_tint(node, kit)
		root.add_child(node)


static func _post(root: Node3D, kit: String, p: Vector3, h: float) -> void:
	var node := _instance(QM + "Corner_Exterior_Wood.gltf") if kit == "B" else _instance(KN + "pillar-wood.glb")
	if node == null:
		return
	if kit == "B":
		node.basis = Basis().scaled(Vector3(1.2, h / 3.0, 1.2))
	else:
		node.basis = Basis().scaled(Vector3(1.6, h, 1.6))
	node.position = p
	_tint(node, kit)
	root.add_child(node)


static func _chimney(root: Node3D, kit: String, p: Vector3, h: float) -> void:
	var node := _instance(QM + "Prop_Chimney.gltf") if kit == "B" else _instance(KN + "chimney.glb")
	if node == null:
		return
	if kit == "B":
		node.basis = Basis().scaled(Vector3(0.7, h / 3.18, 0.7))
	else:
		node.basis = Basis().scaled(Vector3(2.2, h, 2.2))
	node.position = p
	root.add_child(node)


## Own geometry: steep Nordic gable roof, ridge along the longer side.
static func _roof(root: Node3D, kit: String, w: float, d: float, eave_y: float, overhang: float) -> void:
	var along_x := w >= d
	var span := (d if along_x else w) + overhang * 2.0
	var length := (w if along_x else d) + overhang * 2.0
	var pitch := deg_to_rad(52.0 if kit == "C" else 48.0)
	var rise := span * 0.5 * tan(pitch)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hl := length / 2.0
	var hs := span / 2.0
	var thick := 0.22 if kit == "C" else 0.12
	# Two slopes (top faces + undersides), local frame: X = ridge, Z = across.
	for side in [-1.0, 1.0]:
		var e0 := Vector3(-hl, 0, hs * side)
		var e1 := Vector3(hl, 0, hs * side)
		var r0 := Vector3(-hl, rise, 0)
		var r1 := Vector3(hl, rise, 0)
		var up := Vector3(0, thick, 0)
		_quad(st, e0 + up, e1 + up, r1 + up, r0 + up, side > 0, length, span)
		_quad(st, e0, e1, r1, r0, side < 0, length, span)
	var roof_mesh := st.commit()
	var gst := SurfaceTool.new()
	gst.begin(Mesh.PRIMITIVE_TRIANGLES)
	for endx in [-(length / 2.0 - overhang), length / 2.0 - overhang]:
		var a := Vector3(endx, -0.4, -(span / 2.0 - overhang))
		var b := Vector3(endx, -0.4, span / 2.0 - overhang)
		var c := Vector3(endx, rise - overhang * tan(pitch) * 0.0 - 0.05, 0)
		gst.set_normal(Vector3(signf(endx), 0, 0))
		for v in ([a, b, c] if endx > 0 else [a, c, b]):
			gst.set_uv(Vector2(v.z, v.y) * 0.5)
			gst.add_vertex(v)
	var gable_mesh := gst.commit()
	var holder := Node3D.new()
	holder.name = "Roof"
	holder.position.y = eave_y
	if not along_x:
		holder.rotation.y = PI / 2.0
	var rm := MeshInstance3D.new()
	rm.mesh = roof_mesh
	rm.material_override = _roof_mat(kit)
	holder.add_child(rm)
	var gm := MeshInstance3D.new()
	gm.mesh = gable_mesh
	gm.material_override = _gable_mat(kit)
	holder.add_child(gm)
	if kit == "C":
		# Ridge log + crossed gable boards (Nordic "vindskier").
		var ridge := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.16
		cm.bottom_radius = 0.16
		cm.height = length
		ridge.mesh = cm
		ridge.rotation.z = PI / 2.0
		ridge.position.y = rise + thick + 0.06
		ridge.material_override = _log_mat()
		holder.add_child(ridge)
	root.add_child(holder)


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, flip: bool, length: float, span: float) -> void:
	var nrm := (b - a).cross(d - a).normalized()
	if flip:
		nrm = -nrm
	var verts := [a, b, c, a, c, d] if not flip else [a, c, b, a, d, c]
	for v in verts:
		st.set_normal(nrm)
		st.set_uv(Vector2(v.x, v.y * 1.6 + absf(v.z)) * 0.6)
		st.add_vertex(v)


# ---------------------------------------------------------------- materials

static func _instance(path: String) -> Node3D:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	var ps: PackedScene = _cache[path]
	return ps.instantiate() as Node3D if ps != null else null


## Nordic adaptation of kit materials (keeps kit textures, shifts the palette).
static func _tint(node: Node, kit: String) -> void:
	for m in node.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var base := mi.mesh.surface_get_material(s)
			if not (base is StandardMaterial3D):
				continue
			var key := "%s|%s" % [kit, str(base.get_instance_id())]
			if not _mats.has(key):
				var mat := (base as StandardMaterial3D).duplicate() as StandardMaterial3D
				var nm := String(base.resource_name).to_lower()
				if kit == "B":
					if nm.contains("plaster"):
						mat.albedo_color = Color(0.62, 0.22, 0.17)  # falu red
					elif nm.contains("wood") or nm.contains("trim"):
						mat.albedo_color = Color(0.42, 0.33, 0.27)  # tarred timber
					elif nm.contains("brick") or nm.contains("rock"):
						mat.albedo_color = Color(0.72, 0.72, 0.74)
				else:
					mat.albedo_color = Color(0.80, 0.70, 0.60)  # weathered plank, darker
					mat.roughness = 0.92
				_mats[key] = mat
			mi.set_surface_override_material(s, _mats[key])


static func _roof_mat(kit: String) -> Material:
	var key := "roof" + kit
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		if kit == "B":
			var tex := load(QM + "T_RoundTiles_BaseColor.png") as Texture2D
			m.albedo_texture = tex
			m.albedo_color = Color(0.38, 0.30, 0.26)  # dark shingle / tar
			m.uv1_scale = Vector3(0.7, 0.7, 1)
			m.roughness = 0.85
		else:
			var nt := NoiseTexture2D.new()
			var fn := FastNoiseLite.new()
			fn.frequency = 0.08
			nt.noise = fn
			nt.seamless = true
			var grad := Gradient.new()
			grad.set_color(0, Color(0.20, 0.27, 0.12))
			grad.set_color(1, Color(0.42, 0.45, 0.20))
			nt.color_ramp = grad
			m.albedo_texture = nt
			m.uv1_scale = Vector3(0.5, 0.5, 1)
			m.roughness = 1.0
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mats[key] = m
	return _mats[key]


static func _gable_mat(kit: String) -> Material:
	var key := "gable" + kit
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.55, 0.20, 0.16) if kit == "B" else Color(0.36, 0.27, 0.20)
		m.roughness = 0.9
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mats[key] = m
	return _mats[key]


static func _wood_mat(kit: String) -> Material:
	var key := "wood" + kit
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.33, 0.25, 0.19)
		m.roughness = 0.9
		_mats[key] = m
	return _mats[key]


static func _log_mat() -> Material:
	if not _mats.has("log"):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.30, 0.23, 0.17)
		m.roughness = 0.95
		_mats["log"] = m
	return _mats["log"]


static func _stone_mat() -> Material:
	if not _mats.has("stone"):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.46, 0.46, 0.47)
		m.roughness = 0.95
		_mats["stone"] = m
	return _mats["stone"]
