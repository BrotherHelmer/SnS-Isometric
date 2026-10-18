extends Node3D
## Phase2 target-style test. NOT gameplay. Merged-by-colour low-poly, ortho iso camera.
var surf := {}
var roof_instances := []
var round_no := 1
var out_path := "/home/box/cos/evidence/2026-10-18-sns-visual-target/phase2/round1.png"
var tri_total := 0
func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--round="): round_no = int(a.trim_prefix("--round="))
		if a.begins_with("--out="): out_path = a.trim_prefix("--out=")
	_setup()
	var cl := CanvasLayer.new(); add_child(cl); var vr := TextureRect.new(); vr.texture = load(PT + "vignette.png"); vr.set_anchors_preset(Control.PRESET_FULL_RECT); vr.mouse_filter = Control.MOUSE_FILTER_IGNORE; cl.add_child(vr)
	for pp in [Vector3(-4,3,3), Vector3(5,3,-2)]:
		var o := OmniLight3D.new(); o.position = pp; o.light_color = Color("ffcf96"); o.light_energy = 0.85; o.omni_range = 9.0; o.shadow_enabled = false; add_child(o)
	await get_tree().process_frame; await get_tree().create_timer(0.9).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_path)
	var draws := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var prims := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	print("TARGETSTYLE round=", round_no, " draws=", draws, " prims=", prims, " authored_tris~=", tri_total, " out=", out_path)
	get_tree().quit()
var surf_tex := {}
const PT := "res://art_test/target_style/textures_painted/"
const TEX := {"meadow":PT+"grass_painted.png","dirt":PT+"dirt_painted.png","stone":PT+"stone_painted.png","plaster":PT+"plaster_painted.png","timber":"res://assets/settlement3d/runtime/gfx/architecture/timber_diff.jpg","slate":PT+"roof_painted.png","rock":PT+"rock_painted.png","thatch":PT+"thatch_painted.png","leafp":PT+"foliage_painted.png","roofp":PT+"roof_painted.png"}
func mat_col(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = c; m.roughness = 1.0; return m
func mat_for(key: String, c: Color) -> StandardMaterial3D:
	var m := mat_col(c); var tx: String = surf_tex.get(key, "")
	if tx != "" and TEX.has(tx):
		m.albedo_texture = load(TEX[tx]); m.uv1_scale = Vector3(18,18,1) if tx=="meadow" else (Vector3(1,1,1) if tx=="roofp" else Vector3(6,6,1)); m.albedo_color = Color(0.88,0.88,0.88) if tx in ["roofp","stone","thatch","plaster","dirt","rock"] else Color(1,1,1).lerp(c, 0.25)
		m.albedo_color = Color(0.78,0.76,0.73)
		if tx == "forest": m.albedo_color = Color(1,1,1).lerp(c, 0.30)
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
func cyl(p: Vector3, br: float, tr: float, h: float, c: Color, sides := 10, tx := "") -> void:
	var m := CylinderMesh.new(); m.bottom_radius = br; m.top_radius = tr; m.height = h; m.radial_segments = sides; m.rings = 1; tri_total += sides * 4
	add_mesh(m, Transform3D(Basis.IDENTITY, p), c, tx)
func blob(p: Vector3, s: Vector3, c: Color, tx := "") -> void:
	var m := SphereMesh.new(); m.radial_segments = 8; m.rings = 4; m.radius = 1.0; m.height = 2.0; tri_total += 64
	add_mesh(m, Transform3D(Basis.IDENTITY.scaled(s), p), c, tx)
func roof2(p: Vector3, w: float, d: float, h: float, thick: float, c: Color) -> void:
	# STANDALONE ArrayMesh prism, explicit arrays. v: 0 at eave -> 1 at ridge (10 shingle rows in texture)
	var hw := w/2.0
	var A := Vector3(-hw,0,-d/2); var B := Vector3(-hw,0,d/2); var C := Vector3(0,h,-d/2); var D := Vector3(0,h,d/2)
	var E := Vector3(hw,0,-d/2); var F := Vector3(hw,0,d/2)
	var verts := PackedVector3Array(); var norms := PackedVector3Array(); var uvs := PackedVector2Array(); var cols := PackedColorArray()
	var slopes := [[A,C,D,B],[F,D,C,E]]
	for q in slopes:
		var n: Vector3 = (q[1]-q[0]).cross(q[3]-q[0]).normalized(); if n.y < 0: n = -n
		var uvq := [Vector2(0,0), Vector2(0,1), Vector2(2,1), Vector2(2,0)]
		for idx in [0,1,2,0,2,3]: verts.append(q[idx]); norms.append(n); uvs.append(uvq[idx]); cols.append(Color.WHITE)
	var arrays := []; arrays.resize(Mesh.ARRAY_MAX); arrays[Mesh.ARRAY_VERTEX]=verts; arrays[Mesh.ARRAY_NORMAL]=norms; arrays[Mesh.ARRAY_TEX_UV]=uvs; arrays[Mesh.ARRAY_COLOR]=cols
	var prism := ArrayMesh.new(); prism.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var chk: Array = prism.surface_get_arrays(0); var uvchk: PackedVector2Array = chk[Mesh.ARRAY_TEX_UV]
	assert(uvchk.size() == verts.size())
	roof_instances.append([prism, p]); tri_total += 4
	var gs := SurfaceTool.new(); gs.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tri in [[A,E,C],[B,D,F]]:
		var n2: Vector3 = (tri[1]-tri[0]).cross(tri[2]-tri[0]).normalized()
		for idx in 3: gs.set_normal(n2); gs.set_uv(Vector2(0.5,0.5)); gs.add_vertex(tri[idx])
	add_mesh(gs.commit(), Transform3D(Basis.IDENTITY, p), Color("e8d9b8"), "plaster"); tri_total += 2
	# eave shadow line
	box(p+Vector3(0,0.02,0), Vector3(w+0.15,0.09,d+0.15), c.darkened(0.35))
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
	var back := clampf((-z - 6.0) / 10.0, 0.0, 1.0); back = back * back
	var hill := back * 12.5 * clampf(1.35 - absf(x - 14.0) / 19.0, 0.0, 1.0)
	var left := clampf(( -x - 14.0) / 16.0, 0.0, 1.0)
	var jag := mask * (0.22*sin(x*1.9+z*0.7) + 0.14*sin(x*3.7-z*2.3)) * clampf(back*2.0,0.0,1.0)
	var crag := back * (0.85*sin(x*4.1+z*2.7) + 0.55*sin(x*7.3-z*4.9) + 0.35*sin(x*12.0+z*9.0) + 0.22*sin(x*19.0-z*15.0)) * clampf(hill/4.0, 0.0, 1.0)
	return mask * roll + hill + left * left * 1.6 * mask + jag + crag
var canopy_st: SurfaceTool = null
func add_canopy(xf: Transform3D, c: Color) -> void:
	if canopy_st == null: canopy_st = SurfaceTool.new(); canopy_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var arrays: Array = flat_sphere().surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]; var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var seedv := xf.origin.x * 12.9898 + xf.origin.z * 78.233
	for f in range(0, verts.size() - 2, 3):
		var tv := [xf * verts[f], xf * verts[f+1], xf * verts[f+2]]
		var fn: Vector3 = (tv[1]-tv[0]).cross(tv[2]-tv[0]).normalized()
		var vary := 0.80 + 0.45 * (0.5 + 0.5 * sin(seedv + float(f) * 2.39))
		var cc := Color(clampf(c.r*vary,0,1), clampf(c.g*vary,0,1), clampf(c.b*vary,0,1))
		if fn.y > 0.45: cc = cc.lightened(0.18)
		for j in 3:
			canopy_st.set_normal(fn); canopy_st.set_color(cc); canopy_st.set_uv(uvs[f+j]); canopy_st.add_vertex(tv[j])
	tri_total += 128
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
	var size := 64.0; var steps := 88; var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var g1 := Color("2f6b1f"); var g2 := Color("478c2e"); var dirt := Color("9c7f52"); var rock := Color("787c83"); var snow := Color("f4f6f2")
	for iz in steps:
		for ix in steps:
			var x0 := -size/2 + size*float(ix)/steps; var x1 := -size/2 + size*float(ix+1)/steps
			var z0 := -size/2 + size*float(iz)/steps; var z1 := -size/2 + size*float(iz+1)/steps
			var chunk := 0.5 + 0.5*sin(float(ix)*12.9898 + float(iz)*78.233) * sin(float(ix)*3.7 - float(iz)*5.3)
			var quad := [Vector2(x0,z0), Vector2(x1,z0), Vector2(x1,z1), Vector2(x0,z0), Vector2(x1,z1), Vector2(x0,z1)]
			for v in quad:
				var h := _h(v.x, v.y); var slope := absf(_h(v.x+0.8, v.y)-h) + absf(_h(v.x, v.y+0.8)-h)
				var n := 0.5 + 0.28*sin(v.x*1.31 + sin(v.y*1.73)*2.1) + 0.22*sin(v.x*3.7 - v.y*2.9)
				var c: Color = g1.lerp(g2, n)
				if slope > 0.30: c = dirt.lerp(rock, clampf((slope-0.30)*1.3,0,1))
				if slope > 0.55:
					c = rock.lerp(Color("565a61"), clampf((slope-0.55)*0.9,0,1))
					if int(floor(h*1.6)) % 2 == 0: c = c.darkened(0.28)
					var crev := 0.5 + 0.5*sin(v.x*7.3 - v.y*4.9) * sin(v.x*4.1 + v.y*2.7)
					c = c.darkened(crev * 0.45)
					var mot := 0.5 + 0.5*sin(v.x*23.7) * sin(v.y*19.3)
					c = c.lerp(Color("b2b5ba"), mot * 0.30)
					var cf := 0.74 + 0.56 * chunk
					c = Color(clampf(c.r*cf,0,1), clampf(c.g*cf,0,1), clampf(c.b*cf,0,1))
				var snowpatch := 0.5 + 0.5*sin(v.x*3.1+1.3) * sin(v.y*2.3-0.7)
				if h > 2.9 and slope <= 1.65:
					var sf := clampf((snowpatch-0.40)*8.0, 0.0, 1.0) * clampf((h-2.9)*3.0, 0.0, 1.0)
					c = c.lerp(Color("f8fafc"), sf)
				st.set_color(c); st.set_uv(v*0.5); st.add_vertex(Vector3(v.x, h, v.y))
	st.generate_normals()
	var mi := MeshInstance3D.new(); mi.mesh = st.commit(); var m := StandardMaterial3D.new(); m.vertex_color_use_as_albedo = true; m.albedo_texture = load(PT + "detail_noise.png"); m.roughness = 0.95; mi.material_override = m; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(mi)
	# outer trees sit on terrain
func _setup() -> void:
	# round presets: 1 pipeline, 2 softer/yellower, 3 tuned toward target mean colour
	var grass := Color("6fbf3f"); var grass2 := Color("8fd14f"); var stone := Color("b8b4a8"); var roof := Color("c23b2a"); var dirt := Color("c9a86a"); var leaf := Color("4e9b35"); var leaf2 := Color("77c04a"); var light_e := 1.0; var amb := 0.55
	if round_no == 2:
		grass = Color("69bd45"); grass2 = Color("86cc58"); stone = Color("c4bda9"); roof = Color("c2442c"); leaf = Color("4fae38"); leaf2 = Color("7cc24e"); light_e = 1.05; amb = 0.45
	if round_no >= 3:
		grass = Color("406e26"); grass2 = Color("4f7f2e"); stone = Color("9d9584"); roof = Color("bf3f27"); dirt = Color("cda96e"); leaf = Color("79c24d"); leaf2 = Color("a9dd77"); light_e = 0.95; amb = 0.42
	# environment + light + camera (game iso: ortho, pitch -38, yaw -45)
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color("bfe3ef")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(1,0.98,0.92); env.ambient_light_energy = amb
	env.fog_enabled = true; env.fog_light_color = Color("f2e3c2"); env.fog_density = 0.0028; env.tonemap_mode = Environment.TONE_MAPPER_LINEAR; env.adjustment_enabled = true; env.adjustment_saturation = 1.15; env.adjustment_contrast = 1.05; env.adjustment_brightness = 1.02; env.glow_enabled = false;
	we.environment = env; add_child(we)
	var pool := OmniLight3D.new(); pool.position = Vector3(0,4.5,1); pool.light_color = Color("ffd9a0"); pool.light_energy = 0.9; pool.omni_range = 14.0; pool.shadow_enabled = false; add_child(pool)
	var fill := DirectionalLight3D.new(); fill.rotation_degrees = Vector3(-38, 125, 0); fill.light_energy = 0.20; fill.light_color = Color("cfe6ff"); fill.shadow_enabled = false; add_child(fill)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-52, -38, 0); sun.light_energy = light_e; sun.light_color = Color(1,0.96,0.88); sun.shadow_enabled = true; sun.shadow_opacity = 0.45; sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS; sun.shadow_blur = 4.5; add_child(sun)
	var cam := Camera3D.new(); cam.projection = Camera3D.PROJECTION_ORTHOGONAL; cam.size = 6.5 if OS.get_cmdline_user_args().has("--close") else (21.0 if round_no>=10 else 19.0); cam.look_at_from_position(Vector3(9.5,8,7.5) if OS.get_cmdline_user_args().has("--close") else Vector3(11,11,11), Vector3(2.6,0.6,-0.8) if OS.get_cmdline_user_args().has("--close") else Vector3(1.3,0.5,-1.1), Vector3.UP); cam.current = true; add_child(cam)	# ground grass: big plane + lighter patches
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
		add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(0,float(bi),0)).scaled(Vector3(0.7,0.5,0.6)), Vector3(bx, _h(bx,bz)+0.15, bz)), Color("8a8175"), "rock"); tri_total += 128
	for si9 in 15:
		var sx9 := 8.5 + fmod(float(si9)*3.17, 12.5); var sz9 := -8.0 - fmod(float(si9)*2.43, 7.5)
		var ss9 := 0.7 + fmod(float(si9)*0.37, 0.9)
		add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(0.3,float(si9)*1.7,0.15)).scaled(Vector3(ss9,ss9*0.72,ss9*0.85)), Vector3(sx9, _h(sx9,sz9)+ss9*0.10, sz9)), Color("54575e") if si9%2==0 else Color("90949a"), "rock"); tri_total += 128
	for ei in 10:
		var ex := -11.0+fmod(float(ei)*4.91,23.0); var ez := -6.0+fmod(float(ei)*5.37,17.0)
		cyl(Vector3(ex,0.03,ez), 0.62,0.62,0.025, Color("9a7c4e") if ei%2==0 else Color("bfae6a"), 8)
	for fi in 36:
		var fx2 := -12.0+fmod(float(fi)*3.97,25.0); var fz := -9.0+fmod(float(fi)*4.53,20.0)
		if Vector2(fx2,fz).length() < 11.0:
			for fo in 3: cyl(Vector3(fx2+float(fo)*0.09-0.09,0.04,fz+fmod(float(fo)*0.07,0.12)), 0.045,0.045,0.03, [Color("ffffff"),Color("ffd94a"),Color("ff9db0")][fi%3], 5)
	# branch paths connecting buildings
	for seg in [[Vector2(3.2,-1.2),Vector2(7.2,-3.8)],[Vector2(-3.4,4.6),Vector2(-8.6,4.8)],[Vector2(3.2,-1.2),Vector2(6.2,4.2)],[Vector2(-1.5,-3.5),Vector2(-5.6,3.4)]]:
		var a2: Vector2 = seg[0]; var b2: Vector2 = seg[1]; var mid2 := (a2+b2)*0.5; var dir2 := b2-a2
		box(Vector3(mid2.x,0.028,mid2.y), Vector3(1.25,0.035,dir2.length()+0.8), Color("c9ab72"), atan2(dir2.x,dir2.y), 0,0, "dirt")
	for li2 in 5:
		var lx2 := 10.0+fmod(float(li2)*2.3,6.0); var lz2 := -8.0-fmod(float(li2)*1.1,4.0)
		add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(0.2,float(li2),0.1)).scaled(Vector3(1.1,0.65,0.9)), Vector3(lx2,_h(lx2,lz2)+0.3,lz2)), Color("6e665c"), "rock"); tri_total+=128
	# market stall: posts, striped canopy, crates
	for mp in [Vector3(-4.6,0,5.9), Vector3(-3.4,0,5.9), Vector3(-4.6,0,7.0), Vector3(-3.4,0,7.0)]: box(mp+Vector3(0,0.75,0), Vector3(0.13,1.5,0.13), Color("6b4423"))
	box(Vector3(-4.0,1.62,6.45), Vector3(1.9,0.14,1.9), Color("d43a2a")); box(Vector3(-4.0,1.58,6.45), Vector3(1.9,0.1,0.5), Color("f2ead8")); box(Vector3(-4.0,0.55,6.45), Vector3(1.6,0.5,1.2), Color("a67c4e"), 0,0,0, "timber")
	for fp2 in [Vector3(6.2,0,4.2), Vector3(-8.2,0,-2.6), Vector3(7.2,0,-3.8)]:
		box(fp2+Vector3(0,2.2,0), Vector3(0.06,1.3,0.06), Color("4a3421")); box(fp2+Vector3(0.35,2.6,0), Vector3(0.65,0.38,0.04), Color("2f62b8") if fp2.x>0 else Color("d43a2a"))
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
	_build_house(Vector3(-11.5,0,-6.5), roof, stone)
	_build_house(Vector3(11.8,0,7.5), roof, stone)
	for tp in [Vector3(-14,0,-8),Vector3(-15,0,2),Vector3(-13,0,9),Vector3(13,0,10),Vector3(15,0,-4),Vector3(11,0,-12),Vector3(-11,0,-11),Vector3(4,0,11),Vector3(-4,0,12),Vector3(14,0,5)]:
		_build_tree(tp, leaf, leaf2)
	for bs in [Vector3(-5,0,-7),Vector3(6,0,8),Vector3(-10,0,-3),Vector3(9,0,-8)]:
		add_canopy(Transform3D(Basis.IDENTITY.scaled(Vector3(0.9,0.6,0.9)), bs+Vector3(0,0.5,0)), leaf)
	# stones
	for p in [Vector3(4.8,0.25,-4),Vector3(-7.5,0.2,6),Vector3(7,0.2,-2)]: blob(p, Vector3(0.5,0.35,0.45), Color("9a968c"))
	for ap in [Vector3(-1.5,0,-3.5), Vector3(3.2,0,-1.2), Vector3(-3.4,0,4.6), Vector3(6.2,0,4.2), Vector3(7.2,0,-3.8)]:
		cyl(ap+Vector3(0,0.018,0), 2.6,2.6,0.015, Color(0.10,0.16,0.05,0.45), 14)
	# commit merged meshes
	for key in surf:
		var st: SurfaceTool = surf[key]; var mesh := st.commit()
		var mi := MeshInstance3D.new(); mi.mesh = mesh; mi.material_override = mat_for(key, Color.html(key.split("|")[0])); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON; add_child(mi)
	for ri2 in roof_instances:
		var rmi := MeshInstance3D.new(); rmi.mesh = ri2[0]; rmi.position = ri2[1]; var rmat := StandardMaterial3D.new(); rmat.albedo_texture = load(TEX["roofp"]); rmat.albedo_color = Color(0.88,0.88,0.88); rmat.roughness = 0.92; rmat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS; rmi.material_override = rmat; rmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON; add_child(rmi)
	if canopy_st != null:
		var cmi := MeshInstance3D.new(); cmi.mesh = canopy_st.commit(); var cm := StandardMaterial3D.new(); cm.albedo_texture = load(TEX["leafp"]); cm.vertex_color_use_as_albedo = true; cm.albedo_color = Color(1.15,1.15,1.1); cm.roughness = 1.0; cm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS; cmi.material_override = cm; cmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON; add_child(cmi)
	_spawn_carriers(); _spawn_statics()
func _spawn_carriers() -> void:
	var chars := ["Farmer_B", "Farmer_A", "Rogue_Hooded", "Rogue"]
	var cps := [Vector3(0.6,0.05,2.8), Vector3(-2.6,0.05,0.8), Vector3(5.2,0.05,1.6), Vector3(-6.4,0.05,-1.4), Vector3(-8.8,0.05,5.6), Vector3(8.6,0.05,4.6)]
	for ci2 in cps.size():
		var cp: Vector3 = cps[ci2]; var ps: PackedScene = load("res://assets/settlement3d/runtime/characters/" + chars[ci2 % chars.size()] + ".glb")
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
func _spawn_statics() -> void:
	var defs := [["Farmer_A", Vector3(-7.6,0.05,3.2), "Tools_/Chopping"], ["Knight", Vector3(2.2,0.05,-5.4), "General_/Idle_A"], ["Farmer_B", Vector3(-4.0,0.05,5.2), "Tools_/Hammering"]]
	for df in defs:
		var ps2: PackedScene = load("res://assets/settlement3d/runtime/characters/" + String(df[0]) + ".glb")
		if ps2 == null: continue
		var ch2 := ps2.instantiate() as Node3D; ch2.position = df[1]; ch2.rotation.y = 0.8; ch2.scale = Vector3.ONE * 0.92; add_child(ch2)
		var ap2 := AnimationPlayer.new(); ap2.root_node = NodePath(".."); ch2.add_child(ap2)
		for libname in ["MovementBasic", "General", "Tools"]:
			var lp2: PackedScene = load("res://assets/settlement3d/runtime/animations/Rig_Medium/Rig_Medium_" + libname + ".glb")
			if lp2 == null: continue
			var inst2 := lp2.instantiate(); var src2 := inst2.find_children("*", "AnimationPlayer", true, false)
			if src2.size() > 0:
				for ln2 in (src2[0] as AnimationPlayer).get_animation_library_list(): ap2.add_animation_library(libname + "_" + String(ln2), (src2[0] as AnimationPlayer).get_animation_library(ln2))
			inst2.queue_free()
		var clip := String(df[2])
		if ap2.has_animation(clip): ap2.play(clip); print("STATIC playing ", clip)
		elif ap2.has_animation("General_/Idle_A"): ap2.play("General_/Idle_A"); print("STATIC fallback Idle")
		ap2.advance(0.4)
func _cliff_mesh(w: float, h: float, seedv: int) -> ArrayMesh:
	var segx := 7; var segy := 5; var verts := PackedVector3Array(); var norms := PackedVector3Array(); var uvs := PackedVector2Array()
	var rng := RandomNumberGenerator.new(); rng.seed = seedv
	var grid := []
	for iy in segy+1:
		var row := []
		for ix in segx+1:
			var u := float(ix)/segx; var v := float(iy)/segy
			row.append(Vector3((u-0.5)*w, (v-0.5)*h, (sin(u*9.0+float(seedv)) + cos(v*7.0+u*4.0)) * 0.28 + rng.randf_range(-0.12,0.12)))
		grid.append(row)
	for iy in segy:
		for ix in segx:
			var quad := [grid[iy][ix], grid[iy][ix+1], grid[iy+1][ix+1], grid[iy+1][ix]]
			var n: Vector3 = (quad[1]-quad[0]).cross(quad[3]-quad[0]).normalized()
			var uvq := [Vector2(0,0), Vector2(1,0), Vector2(1,1), Vector2(0,1)]
			# map uv per grid position
			var guv := [Vector2(float(ix)/segx, float(iy)/segy), Vector2(float(ix+1)/segx, float(iy)/segy), Vector2(float(ix+1)/segx, float(iy+1)/segy), Vector2(float(ix)/segx, float(iy+1)/segy)]
			for idx in [0,1,2,0,2,3]: verts.append(quad[idx]); norms.append(n); uvs.append(guv[idx])
	var arrays := []; arrays.resize(Mesh.ARRAY_MAX); arrays[Mesh.ARRAY_VERTEX]=verts; arrays[Mesh.ARRAY_NORMAL]=norms; arrays[Mesh.ARRAY_TEX_UV]=uvs
	var m := ArrayMesh.new(); m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays); return m
func _spawn_cliffs() -> void:
	var rmat := StandardMaterial3D.new(); rmat.albedo_texture = load(TEX["rock"]); rmat.albedo_color = Color(1.3,1.28,1.22); rmat.roughness = 1.0; rmat.cull_mode = BaseMaterial3D.CULL_DISABLED; rmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	var defs := [[Vector3(9.0,0,-11.5), 0.5, 7.0, 4.5], [Vector3(14.0,0,-12.5), 0.9, 8.0, 5.5], [Vector3(5.5,0,-10.5), 0.25, 5.5, 3.8]]
	for i2 in defs.size():
		var df: Array = defs[i2]; var pos: Vector3 = df[0]; pos.y = _h(pos.x, pos.z) + float(df[3])*0.32
		var mi := MeshInstance3D.new(); mi.mesh = _cliff_mesh(float(df[2]), float(df[3]), 40+i2*7); mi.position = pos; mi.rotation = Vector3(-0.52, float(df[1]), 0.05); mi.material_override = rmat; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON; add_child(mi)
		for si3 in 3:
			var bp := pos + Vector3(float(si3)*1.3-1.3, -float(df[3])*0.3, 1.8)
			add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(0,float(si3),0)).scaled(Vector3(0.6,0.42,0.55)), Vector3(bp.x, _h(bp.x,bp.z)+0.12, bp.z)), Color("6e665c"), "rock"); tri_total += 128
func _build_castle(p: Vector3, stone: Color, roof: Color) -> void:
	box(p+Vector3(0,1.1,0), Vector3(5.4,2.2,4.1), stone, 0,0,0, "stone")
	for cy in [0.55, 1.05, 1.55]: box(p+Vector3(0,cy,1.82), Vector3(4.6,0.07,0.05), stone.darkened(0.25))
	box(p+Vector3(0,2.15,0), Vector3(2.2,2.3,2.2), stone)
	cyl(p+Vector3(0,4.35,0), 1.15,0.05,1.6, roof, 10, "roofp")
	for off in [Vector2(-2.1,-1.6),Vector2(2.1,-1.6),Vector2(-2.1,1.6),Vector2(2.1,1.6)]:
		cyl(p+Vector3(off.x,1.4,off.y), 0.62,0.62,2.8, stone, 8, "stone")
		cyl(p+Vector3(off.x,3.55,off.y), 0.85,0.02,1.5, roof, 10, "roofp")
		cyl(p+Vector3(off.x,3.25,off.y), 0.88,0.72,0.14, roof.darkened(0.22), 10); cyl(p+Vector3(off.x,3.62,off.y), 0.62,0.46,0.14, roof.darkened(0.22), 10)
		for ts in 3: box(p+Vector3(off.x+0.63,1.0+float(ts)*0.8,off.y), Vector3(0.1,0.65,0.34), stone.darkened(0.15))
	for cx in [-1.9,-1.15,-0.4,0.4,1.15,1.9]: box(p+Vector3(cx,2.15,1.82), Vector3(0.42,0.35,0.18), stone)
	for bx in [-0.9,-0.45,0.0,0.45,0.9]: box(p+Vector3(bx,3.42,1.12), Vector3(0.3,0.3,0.16), stone.darkened(0.12))
	for si2 in 6: box(p+Vector3(-1.8+fmod(float(si2)*0.73,3.6), 0.45+fmod(float(si2)*0.47,1.4), 1.84), Vector3(0.5,0.28,0.06), stone.darkened(0.18) if si2%2==0 else stone.lightened(0.1))
	for wx in [-1.4,1.4]: box(p+Vector3(wx,1.25,1.83), Vector3(0.34,0.55,0.08), Color("3a2e22"))
	box(p+Vector3(0,0.18,1.84), Vector3(4.7,0.36,0.12), Color("8f887a"))
	box(p+Vector3(-1.6,1.7,2.08), Vector3(0.55,1.15,0.07), Color("c22e22")); box(p+Vector3(1.6,1.7,2.08), Vector3(0.55,1.15,0.07), Color("c22e22"))
	for bt in [Vector2(-2.55,-1.95),Vector2(2.55,-1.95),Vector2(-2.55,1.95),Vector2(2.55,1.95)]: box(p+Vector3(bt.x,0.55,bt.y), Vector3(0.55,1.1,0.55), stone.darkened(0.14), 0.4, 0, 0, "stone")
	for wf in [Vector2(-1.9,1.35),Vector2(1.9,1.35),Vector2(0,2.6)]:
		box(p+Vector3(wf.x,wf.y,2.07), Vector3(0.52,0.68,0.08), Color("e8c87a")); box(p+Vector3(wf.x,wf.y,2.11), Vector3(0.36,0.5,0.05), Color("3a2c1c"))
	box(p+Vector3(0,0.7,2.08), Vector3(0.95,1.4,0.15), Color("4a3421"))
	box(p+Vector3(0.0,3.9,0), Vector3(0.08,1.2,0.08), Color("6b4423")); box(p+Vector3(0.45,4.3,0), Vector3(0.8,0.45,0.05), Color("d43a2a"))
func _build_house(p: Vector3, roof: Color, stone: Color) -> void:
	box(p+Vector3(0,0.15,0), Vector3(2.5,0.3,2.0), Color("9a968c"))
	box(p+Vector3(0,1.0,0), Vector3(2.3,1.7,1.9), Color("e8d9b8"), 0,0,0, "plaster")
	# timber
	for x in [-1.1,-0.4,0.4,1.1]: box(p+Vector3(x,1.0,0.97), Vector3(0.19,1.75,0.09), Color("54351d"))
	box(p+Vector3(1.16,1.0,0), Vector3(0.07,1.75,1.9), Color("54351d")); box(p+Vector3(-1.16,1.0,0), Vector3(0.07,1.75,1.9), Color("54351d"))
	box(p+Vector3(0,0.82,1.0), Vector3(0.86,1.5,0.07), Color("2e2015"))
	box(p+Vector3(0,1.55,0.97), Vector3(2.3,0.14,0.06), Color("6b4423"))
	box(p+Vector3(0,0.8,0.98), Vector3(0.7,1.3,0.08), Color("5d3d24"))
	box(p+Vector3(-0.65,1.15,0.98), Vector3(0.45,0.5,0.06), Color("ffd98a"))
	box(p+Vector3(-0.98,1.15,0.98), Vector3(0.16,0.5,0.05), Color("7a4a2a")); box(p+Vector3(-0.32,1.15,0.98), Vector3(0.16,0.5,0.05), Color("7a4a2a"))
	box(p+Vector3(0.65,1.15,0.98), Vector3(0.4,0.48,0.06), Color("ffd98a")); box(p+Vector3(0.92,1.15,0.98), Vector3(0.14,0.48,0.05), Color("7a4a2a"))
	roof2(p+Vector3(0,1.85,0), 3.0, 2.5, 1.15, 0.18, roof)
	box(p+Vector3(0.8,2.6,-0.3), Vector3(0.45,1.0,0.45), stone)
	blob(p+Vector3(0.8,3.35,-0.3), Vector3(0.22,0.18,0.22), Color(1,1,1,0.35)); blob(p+Vector3(0.95,3.6,-0.3), Vector3(0.32,0.24,0.32), Color(1,1,1,0.22))
func _build_hut(p: Vector3, stone: Color) -> void:
	box(p+Vector3(0,0.7,0), Vector3(2.0,1.4,1.8), Color("cbb489"))
	box(p+Vector3(0,0.65,0.92), Vector3(0.65,1.1,0.08), Color("3d2b18"))
	cyl(p+Vector3(0,2.05,0), 1.75,0.25,1.5, Color("b98a35"), 10, "thatch")
	for ri in 3: cyl(p+Vector3(0,1.55+float(ri)*0.38,0), 1.55-float(ri)*0.38, 1.45-float(ri)*0.38, 0.12, Color("8f6a2a"), 10)
func _build_tree(p: Vector3, a: Color, b: Color) -> void:
	var vi := absi(int(p.x*3.0 + p.z*7.0)) % 7
	if vi == 5: a = Color("c07a2e"); b = Color("e0a44a")
	vi = vi % 3
	if vi == 1: a = Color("65b04a"); b = Color("9bd06e")
	elif vi == 2: a = Color("74ba52"); b = Color("b5d878")
	if Vector2(p.x,p.z).length() > 11.0: p.y = _h(p.x, p.z) - 0.1
	cyl(p+Vector3(0,0.9,0), 0.22,0.32,1.8, Color("6b4423"), 7)
	if vi == 1:
		for pi in 4:
			add_canopy(Transform3D(Basis.from_euler(Vector3(0,float(pi)*0.8,0)).scaled(Vector3(0.85,1.05,0.85)), p+Vector3(0,1.9+float(pi)*0.62,0)), a if pi%2==0 else b)
		return
	for ci in 5:
		var off: Vector3 = [Vector3(0,2.6,0), Vector3(0.85,2.05,0.3), Vector3(-0.85,2.15,-0.25), Vector3(0.1,3.25,-0.1), Vector3(-0.2,1.9,0.7)][ci]
		var sc: float = [1.25,0.9,0.85,0.9,0.75][ci]
		add_canopy(Transform3D(Basis.from_euler(Vector3(0, float(ci)*0.62, 0)).scaled(Vector3(sc*1.15, sc*0.95, sc*1.15)), p+off), a if ci==0 else b)
func _build_carrier(p: Vector3) -> void:
	box(p+Vector3(-0.16,0.35,0), Vector3(0.2,0.7,0.22), Color("4a3421")); box(p+Vector3(0.16,0.35,0), Vector3(0.2,0.7,0.22), Color("4a3421"))
	box(p+Vector3(0,0.95,0), Vector3(0.62,0.65,0.4), Color("2f62b8"))
	blob(p+Vector3(0,1.55,0), Vector3(0.28,0.3,0.28), Color("e8b88a"))
	var logm := CylinderMesh.new(); logm.bottom_radius=0.11; logm.top_radius=0.11; logm.height=1.05; logm.radial_segments=8; tri_total+=32
	add_mesh(logm, Transform3D(Basis.from_euler(Vector3(0,0,PI/2.0)), p+Vector3(0,1.62,0)), Color("8a5f36"))
	box(p+Vector3(0.35,1.25,0), Vector3(0.55,0.16,0.16), Color("e8b88a"))
