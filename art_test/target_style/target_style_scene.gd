extends Node3D
## Phase2 target-style test. NOT gameplay. Merged-by-colour low-poly, ortho iso camera.
var surf := {}
var round_no := 1
var out_path := "/home/box/cos/evidence/2026-10-18-sns-visual-target/phase2/round1.png"
var tri_total := 0
func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--round="): round_no = int(a.trim_prefix("--round="))
		if a.begins_with("--out="): out_path = a.trim_prefix("--out=")
	_setup()
	await get_tree().process_frame; await get_tree().create_timer(0.9).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_path)
	var draws := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var prims := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	print("TARGETSTYLE round=", round_no, " draws=", draws, " prims=", prims, " authored_tris~=", tri_total, " out=", out_path)
	get_tree().quit()
var surf_tex := {}
const TEX := {"meadow":"res://assets/settlement3d/runtime/gfx/terrain/meadow_diff.jpg","dirt":"res://assets/settlement3d/runtime/gfx/terrain/dirt_diff.jpg","stone":"res://assets/settlement3d/runtime/gfx/architecture/stone_diff.jpg","plaster":"res://assets/settlement3d/runtime/gfx/architecture/plaster_diff.jpg","timber":"res://assets/settlement3d/runtime/gfx/architecture/timber_diff.jpg","slate":"res://assets/settlement3d/runtime/gfx/architecture/slate_diff.jpg","rock":"res://assets/settlement3d/runtime/gfx/terrain/rock_diff.jpg"}
func mat_col(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = c; m.roughness = 0.92; return m
func mat_for(key: String, c: Color) -> StandardMaterial3D:
	var m := mat_col(c); var tx: String = surf_tex.get(key, "")
	if tx != "" and TEX.has(tx):
		m.albedo_texture = load(TEX[tx]); m.uv1_scale = Vector3(18,18,1) if tx=="meadow" else Vector3(2,2,1); m.albedo_color = Color(1,1,1).lerp(c, 0.25)
		if tx == "meadow": m.albedo_color = Color("93dc62")
		if tx == "plaster" or tx == "stone": m.albedo_color = Color("f5efe2")
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if c.a < 0.99: m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m
func add_mesh(mesh: Mesh, xf: Transform3D, c: Color, tx := "") -> void:
	var key := c.to_html() + "|" + tx
	if not surf.has(key): var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES); surf[key] = st; surf_tex[key] = tx
	(surf[key] as SurfaceTool).append_from(mesh, 0, xf)
func box(p: Vector3, s: Vector3, c: Color, ry := 0.0, rz := 0.0, rx := 0.0, tx := "") -> void:
	var m := BoxMesh.new(); m.size = s; tri_total += 12
	add_mesh(m, Transform3D(Basis.from_euler(Vector3(rx, ry, rz)), p), c, tx)
func cyl(p: Vector3, br: float, tr: float, h: float, c: Color, sides := 10) -> void:
	var m := CylinderMesh.new(); m.bottom_radius = br; m.top_radius = tr; m.height = h; m.radial_segments = sides; m.rings = 1; tri_total += sides * 4
	add_mesh(m, Transform3D(Basis.IDENTITY, p), c)
func blob(p: Vector3, s: Vector3, c: Color, tx := "") -> void:
	var m := SphereMesh.new(); m.radial_segments = 8; m.rings = 4; m.radius = 1.0; m.height = 2.0; tri_total += 64
	add_mesh(m, Transform3D(Basis.IDENTITY.scaled(s), p), c, tx)
func roof2(p: Vector3, w: float, d: float, h: float, thick: float, c: Color) -> void:
	# two slanted slabs
	var len := sqrt((w/2.0)*(w/2.0) + h*h)
	var ang := atan2(h, w/2.0)
	box(p + Vector3(-w/4.0, h/2.0, 0), Vector3(len, thick, d), c, 0, ang)
	box(p + Vector3(w/4.0, h/2.0, 0), Vector3(len, thick, d), c, 0, -ang)
func flat_mesh(mesh: Mesh) -> ArrayMesh:
	var mdt := MeshDataTool.new(); mdt.create_from_surface(mesh, 0)
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in mdt.get_face_count():
		var n := mdt.get_face_normal(i)
		for j in 3:
			st.set_normal(n); st.add_vertex(mdt.get_vertex(mdt.get_face_vertex(i, j)))
	return st.commit()
func _h(x: float, z: float) -> float:
	var d := Vector2(x, z).length()
	var mask := clampf((d - 10.0) / 13.0, 0.0, 1.0); mask = mask * mask
	var roll := 0.55 * sin(x * 0.23) * cos(z * 0.19) + 0.35 * sin(x * 0.09 + 1.7) * sin(z * 0.13)
	var back := clampf((-z - 6.0) / 13.0, 0.0, 1.0); back = back * back
	var hill := back * 9.0 * clampf(1.3 - absf(x - 10.0) / 20.0, 0.0, 1.0)
	var left := clampf(( -x - 14.0) / 16.0, 0.0, 1.0)
	var jag := mask * (0.22*sin(x*1.9+z*0.7) + 0.14*sin(x*3.7-z*2.3)) * clampf(back*2.0,0.0,1.0)
	return mask * roll + hill + left * left * 1.6 * mask + jag
var _flat_sphere: ArrayMesh = null
func flat_sphere() -> ArrayMesh:
	if _flat_sphere != null: return _flat_sphere
	var sm := SphereMesh.new(); sm.radial_segments = 8; sm.rings = 4; sm.radius = 1.0; sm.height = 2.0
	var arrays: Array = sm.get_mesh_arrays(); var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]; var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	if idx.size() == 0:
		for i in range(0, verts.size()-2, 3): idx.append_array([i, i+1, i+2])
	for f in range(0, idx.size(), 3):
		var a: Vector3 = verts[idx[f]]; var b: Vector3 = verts[idx[f+1]]; var c2: Vector3 = verts[idx[f+2]]
		var n := (b-a).cross(c2-a).normalized()
		for vtx in [a,b,c2]: st.set_normal(n); st.set_uv(Vector2(vtx.x*0.5+0.5, vtx.y*0.5+0.5)); st.add_vertex(vtx)
	_flat_sphere = st.commit(); return _flat_sphere
func _build_terrain() -> void:
	var size := 64.0; var steps := 56; var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var g1 := Color("2f6b1f"); var g2 := Color("478c2e"); var dirt := Color("9c7f52"); var rock := Color("8a8175"); var snow := Color("f4f6f2")
	for iz in steps:
		for ix in steps:
			var x0 := -size/2 + size*float(ix)/steps; var x1 := -size/2 + size*float(ix+1)/steps
			var z0 := -size/2 + size*float(iz)/steps; var z1 := -size/2 + size*float(iz+1)/steps
			var quad := [Vector2(x0,z0), Vector2(x1,z0), Vector2(x1,z1), Vector2(x0,z0), Vector2(x1,z1), Vector2(x0,z1)]
			for v in quad:
				var h := _h(v.x, v.y); var slope := absf(_h(v.x+0.8, v.y)-h) + absf(_h(v.x, v.y+0.8)-h)
				var n := 0.5 + 0.28*sin(v.x*1.31 + sin(v.y*1.73)*2.1) + 0.22*sin(v.x*3.7 - v.y*2.9)
				var c: Color = g1.lerp(g2, n)
				if slope > 0.32: c = dirt.lerp(rock, clampf((slope-0.32)*1.4,0,1))
				if slope > 0.32 and int(h*3.0) % 2 == 0: c = c.darkened(0.13)
				if h > 4.2: c = c.lerp(snow, clampf((h-4.2)*1.4,0,1))
				st.set_color(c); st.set_uv(v*0.14); st.add_vertex(Vector3(v.x, h, v.y))
	st.generate_normals()
	var mi := MeshInstance3D.new(); mi.mesh = st.commit(); var m := StandardMaterial3D.new(); m.vertex_color_use_as_albedo = true; m.albedo_texture = load(TEX["meadow"]); m.roughness = 0.95; mi.material_override = m; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(mi)
	# outer trees sit on terrain
func _setup() -> void:
	# round presets: 1 pipeline, 2 softer/yellower, 3 tuned toward target mean colour
	var grass := Color("6fbf3f"); var grass2 := Color("8fd14f"); var stone := Color("b8b4a8"); var roof := Color("c23b2a"); var dirt := Color("c9a86a"); var leaf := Color("4e9b35"); var leaf2 := Color("77c04a"); var light_e := 1.0; var amb := 0.55
	if round_no == 2:
		grass = Color("69bd45"); grass2 = Color("86cc58"); stone = Color("c4bda9"); roof = Color("c2442c"); leaf = Color("4fae38"); leaf2 = Color("7cc24e"); light_e = 1.05; amb = 0.45
	if round_no >= 3:
		grass = Color("406e26"); grass2 = Color("4f7f2e"); stone = Color("9d9584"); roof = Color("bf3f27"); dirt = Color("cda96e"); leaf = Color("3a7326"); leaf2 = Color("527f33"); light_e = 0.95; amb = 0.42
	# environment + light + camera (game iso: ortho, pitch -38, yaw -45)
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color("bfe3ef")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(1,0.98,0.92); env.ambient_light_energy = amb
	env.fog_enabled = true; env.fog_light_color = Color("dfeef2"); env.fog_density = 0.0015; env.tonemap_mode = Environment.TONE_MAPPER_LINEAR; env.adjustment_enabled = true; env.adjustment_saturation = 1.12; env.adjustment_brightness = 1.0
	we.environment = env; add_child(we)
	var fill := DirectionalLight3D.new(); fill.rotation_degrees = Vector3(-38, 125, 0); fill.light_energy = 0.20; fill.light_color = Color("cfe6ff"); fill.shadow_enabled = false; add_child(fill)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-52, -38, 0); sun.light_energy = light_e; sun.light_color = Color(1,0.96,0.88); sun.shadow_enabled = true; sun.shadow_opacity = 0.46; sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS; sun.shadow_blur = 2.5 if round_no>=2 else 1.0; add_child(sun)
	var cam := Camera3D.new(); cam.projection = Camera3D.PROJECTION_ORTHOGONAL; cam.size = 21.0 if round_no>=10 else 19.0; cam.look_at_from_position(Vector3(11,11,11), Vector3(0,0.4,0), Vector3.UP); cam.current = true; add_child(cam)	# ground grass: big plane + lighter patches
	_build_terrain()
	for k in 26:
		var px := -13.0 + fmod(float(k)*3.71, 26.0); var pz := -11.0 + fmod(float(k)*5.13, 22.0)
		cyl(Vector3(px,0.012,pz), 0.55,0.55,0.015, grass2 if k%2==0 else grass.darkened(0.15), 8)
	# dirt path winding: flat discs/boxes along curve
	var path_pts := [Vector2(-11,6),Vector2(-7,4),Vector2(-4,2.5),Vector2(-1,1.5),Vector2(2,2.5),Vector2(5,4),Vector2(8,6),Vector2(3,-1),Vector2(2,-4),Vector2(1,-8)]
	for i in path_pts.size()-1:
		var a: Vector2 = path_pts[i]; var b: Vector2 = path_pts[i+1]
		if i == 6: continue
		var mid := (a+b)*0.5; var dir := b-a; var ang := atan2(dir.x, dir.y)
		box(Vector3(mid.x,0.03,mid.y), Vector3(1.5,0.04,dir.length()+1.2), dirt, ang, 0,0, "dirt")
	for pt in path_pts: cyl(Vector3(pt.x,0.035,pt.y), 0.78,0.78,0.04, dirt, 10)
	# LANDSCAPE: rolling plateau back, cliff rocks, distant hills, mist bands


	for mi in 3:
		box(Vector3(-8.0+float(mi)*8.0, 1.6+float(mi)*0.5, -14.5), Vector3(13,0.9,1.6), Color(1,1,1,0.05))
	for bi in 12:
		var bx := -10.0+fmod(float(bi)*4.37,22.0); var bz := -12.0+fmod(float(bi)*3.13,10.0)
		add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(0,float(bi),0)).scaled(Vector3(0.7,0.5,0.6)), Vector3(bx, _h(bx,bz)+0.15, bz)), Color("6f675c"), "rock"); tri_total += 128
	for ei in 10:
		var ex := -11.0+fmod(float(ei)*4.91,23.0); var ez := -6.0+fmod(float(ei)*5.37,17.0)
		cyl(Vector3(ex,0.03,ez), 0.62,0.62,0.025, Color("9a7c4e") if ei%2==0 else Color("bfae6a"), 8)
	for fi in 36:
		var fx2 := -12.0+fmod(float(fi)*3.97,25.0); var fz := -9.0+fmod(float(fi)*4.53,20.0)
		if Vector2(fx2,fz).length() < 11.0: cyl(Vector3(fx2,0.04,fz), 0.13,0.13,0.03, [Color("ffffff"),Color("ffd94a"),Color("ff9db0")][fi%3], 6)
	# branch paths connecting buildings
	for seg in [[Vector2(3.2,-1.2),Vector2(7.2,-3.8)],[Vector2(-3.4,4.6),Vector2(-8.6,4.8)],[Vector2(3.2,-1.2),Vector2(6.2,4.2)],[Vector2(-1.5,-3.5),Vector2(-5.6,3.4)]]:
		var a2: Vector2 = seg[0]; var b2: Vector2 = seg[1]; var mid2 := (a2+b2)*0.5; var dir2 := b2-a2
		box(Vector3(mid2.x,0.028,mid2.y), Vector3(1.25,0.035,dir2.length()+0.8), Color("c9ab72"), atan2(dir2.x,dir2.y), 0,0, "dirt")
	# castle centre-back
	_build_castle(Vector3(-1.5,0,-3.5), stone, roof)
	_build_house(Vector3(3.2,0,-1.2), roof, stone)
	_build_hut(Vector3(6.2,0,4.2), stone)
	_build_house(Vector3(-3.4,0,4.6), roof, stone)
	_build_house(Vector3(7.2,0,-3.8), roof, stone)
	_build_hut(Vector3(-8.2,0,-2.6), stone)
	# props: barrels, crates, fence, rocks
	for bp in [Vector3(5.4,0,-0.2), Vector3(-6.2,0,0.8), Vector3(1.8,0,-5.6)]:
		cyl(bp+Vector3(0,0.45,0), 0.38,0.42,0.9, Color("8a5f36"), 9); box(bp+Vector3(0.8,0.35,0.2), Vector3(0.7,0.7,0.7), Color("a67c4e"), 0.4)
	for fx in 4: box(Vector3(-6.0+float(fx)*0.65,0.45,6.6), Vector3(0.14,0.9,0.14), Color("6b4423"))
	box(Vector3(-4.7,0.75,6.6), Vector3(3.4,0.13,0.13), Color("7a5230"))
	for fp in [Vector3(-1.5,0,-3.5), Vector3(3.2,0,-1.2)]:
		box(fp+Vector3(0,4.6,0), Vector3(0.07,1.4,0.07), Color("4a3421")); box(fp+Vector3(0.4,5.1,0), Vector3(0.75,0.42,0.04), Color("d43a2a"))
	# trees
	for p in [Vector3(-8,-0,-6),Vector3(6,0,-6),Vector3(8,0,1),Vector3(-9,0,3),Vector3(5.5,0,6.5),Vector3(-6.5,0,-4),Vector3(1.5,0,-7.5)]:
		_build_tree(p, leaf, leaf2)
	_build_house(Vector3(-8.6,0,4.8), roof, stone)
	_build_house(Vector3(9.6,0,1.8), roof, stone)
	for tp in [Vector3(-14,0,-8),Vector3(-15,0,2),Vector3(-13,0,9),Vector3(13,0,10),Vector3(15,0,-4),Vector3(11,0,-12),Vector3(-11,0,-11),Vector3(4,0,11),Vector3(-4,0,12),Vector3(14,0,5)]:
		_build_tree(tp, leaf, leaf2)
	for bs in [Vector3(-5,0,-7),Vector3(6,0,8),Vector3(-10,0,-3),Vector3(9,0,-8)]:
		blob(bs+Vector3(0,0.5,0), Vector3(0.9,0.6,0.9), leaf, "forest")
	# stones
	for p in [Vector3(4.8,0.25,-4),Vector3(-7.5,0.2,6),Vector3(7,0.2,-2)]: blob(p, Vector3(0.5,0.35,0.45), Color("9a968c"))
	for ap in [Vector3(-1.5,0,-3.5), Vector3(3.2,0,-1.2), Vector3(-3.4,0,4.6), Vector3(6.2,0,4.2), Vector3(7.2,0,-3.8)]:
		cyl(ap+Vector3(0,0.018,0), 2.6,2.6,0.015, Color(0.12,0.18,0.06,0.28), 14)
	# commit merged meshes
	for key in surf:
		var st: SurfaceTool = surf[key]; var mesh := st.commit()
		var mi := MeshInstance3D.new(); mi.mesh = mesh; mi.material_override = mat_for(key, Color.html(key.split("|")[0])); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON; add_child(mi)
	_spawn_carriers()
func _spawn_carriers() -> void:
	var ps: PackedScene = load("res://assets/settlement3d/runtime/characters/Farmer_B.glb")
	for cp in [Vector3(0.6,0.05,2.8), Vector3(-2.6,0.05,0.8), Vector3(5.2,0.05,1.6), Vector3(-6.4,0.05,-1.4)]:
		if ps == null: _build_carrier(cp); continue
		var ch := ps.instantiate() as Node3D; ch.position = cp; ch.rotation.y = -0.7; ch.scale = Vector3.ONE * 0.92; add_child(ch)
		var ap := AnimationPlayer.new(); ap.root_node = NodePath(".."); ch.add_child(ap)
		for libname in ["MovementBasic", "General", "Tools"]:
			var lp: PackedScene = load("res://assets/settlement3d/runtime/animations/Rig_Medium/Rig_Medium_" + libname + ".glb")
			if lp == null: continue
			var inst := lp.instantiate(); var src := inst.find_children("*", "AnimationPlayer", true, false)
			if src.size() > 0:
				for ln in (src[0] as AnimationPlayer).get_animation_library_list(): ap.add_animation_library(libname + "_" + String(ln), (src[0] as AnimationPlayer).get_animation_library(ln))
			inst.queue_free()
		print("CARRIER libs=", ap.get_animation_library_list())
		for cand in ["MovementBasic_/Walking_A", "MovementBasic/Walking_A"]:
			if ap.has_animation(cand): ap.play(cand); print("CARRIER playing ", cand); break
		ap.advance(0.65)
		var logm := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.bottom_radius=0.09; cm.top_radius=0.09; cm.height=1.0; cm.radial_segments=8; logm.mesh=cm; logm.rotation.z=PI/2.0; logm.position=cp+Vector3(0,1.5,0.12); logm.material_override=mat_col(Color("8a5f36")); add_child(logm)
func _build_castle(p: Vector3, stone: Color, roof: Color) -> void:
	box(p+Vector3(0,1.1,0), Vector3(5.4,2.2,4.1), stone, 0,0,0, "stone")
	for cy in [0.55, 1.05, 1.55]: box(p+Vector3(0,cy,1.82), Vector3(4.6,0.07,0.05), stone.darkened(0.25))
	box(p+Vector3(0,2.15,0), Vector3(2.2,2.3,2.2), stone)
	cyl(p+Vector3(0,4.35,0), 1.15,0.05,1.6, roof, 10)
	for off in [Vector2(-2.1,-1.6),Vector2(2.1,-1.6),Vector2(-2.1,1.6),Vector2(2.1,1.6)]:
		cyl(p+Vector3(off.x,1.4,off.y), 0.62,0.62,2.8, stone, 10)
		cyl(p+Vector3(off.x,3.55,off.y), 0.85,0.02,1.5, roof, 10)
	for cx in [-1.9,-1.15,-0.4,0.4,1.15,1.9]: box(p+Vector3(cx,2.15,1.82), Vector3(0.42,0.35,0.18), stone)
	for bx in [-0.9,-0.45,0.0,0.45,0.9]: box(p+Vector3(bx,3.42,1.12), Vector3(0.3,0.3,0.16), stone.darkened(0.12))
	for si2 in 6: box(p+Vector3(-1.8+fmod(float(si2)*0.73,3.6), 0.45+fmod(float(si2)*0.47,1.4), 1.84), Vector3(0.5,0.28,0.06), stone.darkened(0.18) if si2%2==0 else stone.lightened(0.1))
	for wx in [-1.4,1.4]: box(p+Vector3(wx,1.25,1.83), Vector3(0.34,0.55,0.08), Color("3a2e22"))
	box(p+Vector3(0,0.18,1.84), Vector3(4.7,0.36,0.12), Color("8f887a"))
	box(p+Vector3(-1.6,1.7,2.08), Vector3(0.55,1.15,0.07), Color("c22e22")); box(p+Vector3(1.6,1.7,2.08), Vector3(0.55,1.15,0.07), Color("c22e22"))
	box(p+Vector3(0,0.7,2.08), Vector3(0.95,1.4,0.15), Color("4a3421"))
	box(p+Vector3(0.0,3.9,0), Vector3(0.08,1.2,0.08), Color("6b4423")); box(p+Vector3(0.45,4.3,0), Vector3(0.8,0.45,0.05), Color("d43a2a"))
func _build_house(p: Vector3, roof: Color, stone: Color) -> void:
	box(p+Vector3(0,0.15,0), Vector3(2.5,0.3,2.0), Color("9a968c"))
	box(p+Vector3(0,1.0,0), Vector3(2.3,1.7,1.9), Color("e8d9b8"))
	# timber
	for x in [-1.1,-0.4,0.4,1.1]: box(p+Vector3(x,1.0,0.97), Vector3(0.14,1.7,0.06), Color("6b4423"))
	box(p+Vector3(0,1.55,0.97), Vector3(2.3,0.14,0.06), Color("6b4423"))
	box(p+Vector3(0,0.8,0.98), Vector3(0.7,1.3,0.08), Color("5d3d24"))
	box(p+Vector3(-0.65,1.15,0.98), Vector3(0.45,0.5,0.06), Color("ffd98a"))
	roof2(p+Vector3(0,1.85,0), 3.0, 2.5, 1.15, 0.18, roof)
	for si in 3:
		var sy := 2.05 + float(si)*0.32
		box(p+Vector3(-0.62, sy, 0), Vector3(1.35,0.06,2.55), roof.darkened(0.18), 0, 0.66)
		box(p+Vector3(0.62, sy, 0), Vector3(1.35,0.06,2.55), roof.darkened(0.18), 0, -0.66)
	box(p+Vector3(0.8,2.6,-0.3), Vector3(0.45,1.0,0.45), stone)
func _build_hut(p: Vector3, stone: Color) -> void:
	box(p+Vector3(0,0.7,0), Vector3(2.0,1.4,1.8), Color("cbb489"))
	box(p+Vector3(0,0.65,0.92), Vector3(0.65,1.1,0.08), Color("3d2b18"))
	cyl(p+Vector3(0,2.05,0), 1.75,0.25,1.5, Color("b98a35"), 10)
	for ri in 3: cyl(p+Vector3(0,1.55+float(ri)*0.38,0), 1.55-float(ri)*0.38, 1.45-float(ri)*0.38, 0.12, Color("8f6a2a"), 10)
func _build_tree(p: Vector3, a: Color, b: Color) -> void:
	var vi := absi(int(p.x*3.0 + p.z*7.0)) % 3
	if vi == 1: a = Color("35702a"); b = Color("679c3a")
	elif vi == 2: a = Color("4d8a2f"); b = Color("93b84e")
	if Vector2(p.x,p.z).length() > 11.0: p.y = _h(p.x, p.z) - 0.1
	cyl(p+Vector3(0,0.9,0), 0.22,0.32,1.8, Color("6b4423"), 7)
	for ci in 5:
		var off: Vector3 = [Vector3(0,2.6,0), Vector3(0.85,2.05,0.3), Vector3(-0.85,2.15,-0.25), Vector3(0.1,3.25,-0.1), Vector3(-0.2,1.9,0.7)][ci]
		var sc: float = [1.25,0.9,0.85,0.9,0.75][ci]
		add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(0, float(ci)*0.62, 0)).scaled(Vector3(sc*1.15, sc*0.95, sc*1.15)), p+off), a if ci==0 else b, "forest"); tri_total += 128
func _build_carrier(p: Vector3) -> void:
	box(p+Vector3(-0.16,0.35,0), Vector3(0.2,0.7,0.22), Color("4a3421")); box(p+Vector3(0.16,0.35,0), Vector3(0.2,0.7,0.22), Color("4a3421"))
	box(p+Vector3(0,0.95,0), Vector3(0.62,0.65,0.4), Color("2f62b8"))
	blob(p+Vector3(0,1.55,0), Vector3(0.28,0.3,0.28), Color("e8b88a"))
	var logm := CylinderMesh.new(); logm.bottom_radius=0.11; logm.top_radius=0.11; logm.height=1.05; logm.radial_segments=8; tri_total+=32
	add_mesh(logm, Transform3D(Basis.from_euler(Vector3(0,0,PI/2.0)), p+Vector3(0,1.62,0)), Color("8a5f36"))
	box(p+Vector3(0.35,1.25,0), Vector3(0.55,0.16,0.16), Color("e8b88a"))
