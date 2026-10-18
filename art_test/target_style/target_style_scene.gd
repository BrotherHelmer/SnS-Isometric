extends Node3D
## Phase2 target-style test. NOT gameplay. Merged-by-colour low-poly, ortho iso camera.
var surf := {}
var house_xf := Transform3D.IDENTITY
var roof_tilt := 0.0
var house_mode := false
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
		var o := OmniLight3D.new(); o.position = pp; o.light_color = Color("ffcf96"); o.light_energy = 0.55; o.omni_range = 9.0; o.shadow_enabled = false; add_child(o)
	await get_tree().process_frame; await get_tree().create_timer(0.9).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_path)
	var draws := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var prims := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	print("TARGETSTYLE round=", round_no, " draws=", draws, " prims=", prims, " authored_tris~=", tri_total, " out=", out_path)
	get_tree().quit()
var surf_tex := {}
const PT := "res://art_test/target_style/textures_painted/"
const TEX := {"meadow":PT+"grass_painted.png","dirt":PT+"dirt_painted.png","stone":PT+"stone_painted.png","plaster":PT+"plaster_painted.png","timber":PT+"wood_painted.png","slate":PT+"roof_painted.png","rock":PT+"rock_painted.png","thatch":PT+"thatch_painted.png","leafp":PT+"foliage_painted.png","roofp":PT+"roof_painted.png"}
func mat_col(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = c; m.roughness = 1.0; m.albedo_texture = load(PT + "grain_painted.png"); m.uv1_scale = Vector3(3,3,1); return m
func mat_for(key: String, c: Color) -> StandardMaterial3D:
	var m := mat_col(c); var tx: String = surf_tex.get(key, "")
	if tx != "" and TEX.has(tx):
		m.albedo_texture = load(TEX[tx]); m.uv1_scale = Vector3(18,18,1) if tx=="meadow" else (Vector3(1,1,1) if tx in ["roofp","stone","plaster","thatch","rock"] else Vector3(6,6,1)); m.albedo_color = Color(0.88,0.87,0.85)
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
	var xf := Transform3D(Basis.from_euler(Vector3(rx, ry, rz)), p)
	if house_mode: xf = house_xf * xf
	add_mesh(m, xf, c, tx)
func cyl(p: Vector3, br: float, tr: float, h: float, c: Color, sides := 10, tx := "") -> void:
	var m := CylinderMesh.new(); m.bottom_radius = br; m.top_radius = tr; m.height = h; m.radial_segments = sides; m.rings = 1; tri_total += sides * 4
	var xf2 := Transform3D(Basis.IDENTITY, p)
	if house_mode: xf2 = house_xf * xf2
	add_mesh(m, xf2, c, tx)
func blob(p: Vector3, s: Vector3, c: Color, tx := "") -> void:
	var m := SphereMesh.new(); m.radial_segments = 8; m.rings = 4; m.radius = 1.0; m.height = 2.0; tri_total += 64
	var xf3 := Transform3D(Basis.IDENTITY.scaled(s), p)
	if house_mode: xf3 = house_xf * xf3
	add_mesh(m, xf3, c, tx)
func roof2(p: Vector3, w: float, d: float, h: float, thick: float, c: Color) -> void:
	# DEFORMED prism: sagged ridge, uneven eaves/ridge ends, slight twist. v: 0 eave -> 1 ridge
	var hw := w/2.0
	var org := house_xf.origin if house_mode else p
	var seedv := org.x*1.71 + org.z*2.37
	var e1 := sin(seedv*1.7)*0.12; var e2 := cos(seedv*1.31)*0.12; var tw := sin(seedv*0.9)*0.10
	var ec0 := sin(seedv)*0.08; var ec1 := cos(seedv*2.1)*0.08; var ec2 := sin(seedv*1.2+2.0)*0.08; var ec3 := cos(seedv*0.7+1.0)*0.08
	var A := Vector3(-hw,ec0,-d/2); var B := Vector3(-hw,ec3,d/2); var E := Vector3(hw,ec1,-d/2); var F := Vector3(hw,ec2,d/2)
	var C := Vector3(tw,h+e1,-d/2); var D := Vector3(-tw,h+e2,d/2); var M := Vector3(0,h+(e1+e2)*0.5-0.13,0)
	var Am := Vector3(-hw,(ec0+ec3)*0.5,0); var Em := Vector3(hw,(ec1+ec2)*0.5,0)
	var verts := PackedVector3Array(); var norms := PackedVector3Array(); var uvs := PackedVector2Array(); var cols := PackedColorArray()
	var quads := [[A,C,M,Am,0.0],[Am,M,D,B,1.0],[F,D,M,Em,0.0],[Em,M,C,E,1.0]]
	for q in quads:
		var n: Vector3 = (q[1]-q[0]).cross(q[3]-q[0]).normalized(); if n.y < 0: n = -n
		var u0: float = q[4]
		var uvq := [Vector2(u0,0), Vector2(u0,1), Vector2(u0+1.0,1), Vector2(u0+1.0,0)]
		for idx in [0,1,2,0,2,3]: verts.append(q[idx]); norms.append(n); uvs.append(uvq[idx]); cols.append(Color.WHITE)
	var arrays := []; arrays.resize(Mesh.ARRAY_MAX); arrays[Mesh.ARRAY_VERTEX]=verts; arrays[Mesh.ARRAY_NORMAL]=norms; arrays[Mesh.ARRAY_TEX_UV]=uvs; arrays[Mesh.ARRAY_COLOR]=cols
	var prism := ArrayMesh.new(); prism.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	roof_instances.append([prism, house_xf * Transform3D(Basis.from_euler(Vector3(0, 0, roof_tilt)), p) if house_mode else Transform3D(Basis.IDENTITY, p)]); tri_total += 8
	var gs := SurfaceTool.new(); gs.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tri in [[A,E,C],[B,D,F]]:
		var n2: Vector3 = (tri[1]-tri[0]).cross(tri[2]-tri[0]).normalized()
		for idx in 3: gs.set_normal(n2); gs.set_uv(Vector2(0.5,0.5)); gs.add_vertex(tri[idx])
	add_mesh(gs.commit(), house_xf * Transform3D(Basis.IDENTITY, p) if house_mode else Transform3D(Basis.IDENTITY, p), Color("e8d9b8"), "plaster"); tri_total += 2
	# eave shadow line
	box(p+Vector3(0,0.02,0), Vector3(w+0.18,0.17,d+0.18), c.darkened(0.35))
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
	var back := clampf((-z - 6.0) / 7.0, 0.0, 1.0); back = back * back
	var hill := back * 15.0 * clampf(1.35 - absf(x - 15.0) / 20.0, 0.0, 1.0) * (0.80 + 0.40 * (0.5 + 0.5*sin(-z*1.05 + x*0.25)))
	var left := clampf(( -x - 14.0) / 16.0, 0.0, 1.0)
	var jag := mask * (0.22*sin(x*1.9+z*0.7) + 0.14*sin(x*3.7-z*2.3)) * clampf(back*2.0,0.0,1.0)
	var crag := back * (0.85*sin(x*4.1+z*2.7) + 0.55*sin(x*7.3-z*4.9) + 0.35*sin(x*12.0+z*9.0) + 0.22*sin(x*19.0-z*15.0)) * clampf(hill/4.0, 0.0, 1.0)
	var sd := Vector2(x-9.0, z+8.8).length(); var shoulder := clampf(1.0 - sd/3.6, 0.0, 1.0); shoulder = shoulder * shoulder
	var east := clampf((x - 12.0) / 9.0, 0.0, 1.0)
	var lobe := east * east * clampf(1.0 - absf(z + 6.0) / 13.0, 0.0, 1.0) * 5.2 * (0.75 + 0.45 * (0.5 + 0.5*sin(-z*0.9 + x*0.3)))
	return mask * roll + hill + lobe + left * left * 1.6 * mask + jag + crag * (1.0 - shoulder*0.85) + shoulder * 1.15
var _canopy_sphere: ArrayMesh = null
func canopy_sphere() -> ArrayMesh:
	if _canopy_sphere != null: return _canopy_sphere
	var sm := SphereMesh.new(); sm.radial_segments = 9; sm.rings = 5; sm.radius = 1.0; sm.height = 2.0
	var arrays: Array = sm.get_mesh_arrays(); var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]; var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var disp2 := {}
	for dvi in verts.size():
		var dv := verts[dvi]; var dk := str(dv)
		if not disp2.has(dk):
			var dn := dv.normalized()
			var ds := 1.0 + 0.20*sin(dn.x*5.1+dn.y*3.3) + 0.16*sin(dn.y*7.2+dn.z*4.4) + 0.10*sin(dn.z*9.0-dn.x*5.0)
			disp2[dk] = dv * ds
		verts[dvi] = disp2[dk]
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	if idx.size() == 0:
		for i in range(0, verts.size()-2, 3): idx.append_array([i, i+1, i+2])
	for f in range(0, idx.size(), 3):
		var a: Vector3 = verts[idx[f]]; var b: Vector3 = verts[idx[f+1]]; var c2: Vector3 = verts[idx[f+2]]
		var n := (b-a).cross(c2-a).normalized()
		for vtx in [a,b,c2]: st.set_normal(n); st.set_uv(Vector2(vtx.x*0.7+0.5, vtx.y*0.7+0.5)); st.add_vertex(vtx)
	_canopy_sphere = st.commit(); return _canopy_sphere
var canopy_st: SurfaceTool = null
var card_st: SurfaceTool = null
func add_foliage_card(xf: Transform3D, c: Color) -> void:
	if card_st == null: card_st = SurfaceTool.new(); card_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for rot in [0.0, PI/2.0]:
		var b := Basis.from_euler(Vector3(0, rot, 0))
		var q := [Vector3(-1,-0.8,0), Vector3(1,-0.8,0), Vector3(1,0.9,0), Vector3(-1,0.9,0)]
		var uvq := [Vector2(0,1), Vector2(1,1), Vector2(1,0), Vector2(0,0)]
		var fn := xf.basis * (b * Vector3(0,0,1))
		for idx2 in [0,1,2,0,2,3]:
			card_st.set_normal(fn); card_st.set_color(c); card_st.set_uv(uvq[idx2]); card_st.add_vertex(xf * (b * q[idx2]))
	tri_total += 4
func add_canopy(xf: Transform3D, c: Color) -> void:
	if canopy_st == null: canopy_st = SurfaceTool.new(); canopy_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var arrays: Array = canopy_sphere().surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]; var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var seedv := xf.origin.x * 12.9898 + xf.origin.z * 78.233
	for f in range(0, verts.size() - 2, 3):
		var tv := [xf * verts[f], xf * verts[f+1], xf * verts[f+2]]
		var fn: Vector3 = (tv[1]-tv[0]).cross(tv[2]-tv[0]).normalized()
		var vary := 0.70 + 0.62 * (0.5 + 0.5 * sin(seedv + float(f) * 2.39))
		var cc := Color(clampf(c.r*vary,0,1), clampf(c.g*vary,0,1), clampf(c.b*vary,0,1))
		if fn.y > 0.45: cc = cc.lightened(0.26)
		if fn.y < 0.1: cc = cc.darkened(0.28)
		var clus := sin(seedv*0.7 + float(f) * 1.37)
		if clus > 0.45: cc = cc.darkened(0.30)
		elif clus < -0.55: cc = cc.lightened(0.18)
		for j in 3:
			var sn2: Vector3 = (tv[j] - xf.origin).normalized()
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
	# WELDED smooth-shaded heightfield: shared grid vertices, smooth normals,
	# continuous (not per-cell) colour functions so facets stop reading.
	var size := 64.0; var steps := 144
	var g1 := Color("27631d"); var g2 := Color("3f842c"); var dirt := Color("9c7f52"); var rock := Color("8f7a5f"); var snow := Color("f4f6f2")
	var n1 := steps + 1
	var verts := PackedVector3Array(); var cols := PackedColorArray(); var uvs := PackedVector2Array(); var norms := PackedVector3Array()
	verts.resize(n1*n1); cols.resize(n1*n1); uvs.resize(n1*n1); norms.resize(n1*n1)
	for iz in n1:
		for ix in n1:
			var vi := iz*n1 + ix
			var v := Vector2(-size/2 + size*float(ix)/steps, -size/2 + size*float(iz)/steps)
			var h := _h(v.x, v.y); var slope := absf(_h(v.x+0.8, v.y)-h) + absf(_h(v.x, v.y+0.8)-h)
			var chunk := 0.5 + 0.5*sin(v.x*1.9 + v.y*1.3) * sin(v.x*0.7 - v.y*1.1)
			var n := 0.5 + 0.28*sin(v.x*1.31 + sin(v.y*1.73)*2.1) + 0.22*sin(v.x*3.7 - v.y*2.9)
			var patch := 0.5 + 0.5*sin(v.x*0.31+2.0) * sin(v.y*0.27-1.1)
			var c: Color = g1.lerp(g2, n).lerp(Color("69a83a"), patch * 0.42)
			if patch > 0.70: c = c.lerp(Color("b08d55"), (patch-0.70) * 1.3)
			if patch < 0.26: c = c.lerp(Color("7fae4a"), (0.26-patch) * 1.2)
			var sunface := clampf(0.5 - ((_h(v.x+0.8, v.y)-_h(v.x-0.8, v.y)) * 0.9 + (_h(v.x, v.y+0.8)-_h(v.x, v.y-0.8)) * 0.6) * 0.5, 0.0, 1.0)
			c = c.darkened(sunface * 0.16)
			var gshade := 0.5 + 0.5*sin(v.x*0.53-1.0) * sin(v.y*0.47+0.6)
			var gsf := 0.74 + 0.40 * gshade
			c = Color(c.r*gsf, c.g*gsf, c.b*gsf)
			if slope > 0.30: c = dirt.lerp(rock, clampf((slope-0.30)*1.3,0,1))
			if slope > 0.55:
				c = rock.lerp(Color("5f4c38"), clampf((slope-0.55)*0.9,0,1))
				if int(floor(h*1.6)) % 2 == 0: c = c.darkened(0.28)
				var crev := 0.5 + 0.5*sin(v.x*7.3 - v.y*4.9) * sin(v.x*4.1 + v.y*2.7)
				c = c.darkened(crev * 0.45)
				var mot := 0.5 + 0.5*sin(v.x*23.7) * sin(v.y*19.3)
				c = c.lerp(Color("c9bda6"), mot * 0.30)
				var band := 0.5 + 0.5*sin(h*1.35 + v.x*0.32 - v.y*0.48)
				if band > 0.55: c = c.lerp(Color("bfb096"), (band-0.55) * 0.55)
				else: c = c.darkened((0.55-band) * 0.22)
				var cf := 0.82 + 0.36 * chunk
				c = Color(clampf(c.r*cf,0,1), clampf(c.g*cf,0,1), clampf(c.b*cf,0,1))
				var crack := clampf(1.0 - absf(sin(v.x*5.3 + v.y*3.9 + sin(v.y*7.0))) / 0.22, 0.0, 1.0)
				c = c.darkened(crack * 0.30)
				var lich := 0.5 + 0.5*sin(v.x*1.4-0.5) * sin(v.y*1.1+2.1)
				if lich > 0.52: c = c.lerp(Color("5f8140"), clampf((lich-0.52)*1.8,0,0.85))
			for feat in [Vector2(10.5,-8.5), Vector2(14.2,-6.9), Vector2(9.0,-8.8)]:
				var fd := Vector2(v.x-feat.x, v.y-feat.y).length()
				if fd < 4.4: c = c.lerp(dirt, (1.0-fd/4.4) * 0.50)
			var snowpatch := 0.5 + 0.5*sin(v.x*1.9+1.3) * sin(v.y*1.4-0.7)
			if h > 2.7 and slope <= 0.90:
				var sf := clampf((snowpatch-0.34)*4.0, 0.0, 1.0) * clampf((h-2.7)*2.5, 0.0, 1.0)
				c = c.lerp(Color("9fb2c2"), sf)
			verts[vi] = Vector3(v.x, h, v.y); cols[vi] = c
			uvs[vi] = Vector2(v.x*0.15, h*0.15) if slope > 0.55 else v*0.07
	var idx := PackedInt32Array()
	for iz2 in steps:
		for ix2 in steps:
			var a := iz2*n1 + ix2; var b := a + 1; var c2 := a + n1; var d := c2 + 1
			idx.append_array([a, b, d, a, d, c2])
	for ti in range(0, idx.size(), 3):
		var fn := (verts[idx[ti+1]]-verts[idx[ti]]).cross(verts[idx[ti+2]]-verts[idx[ti]])
		for j in 3: norms[idx[ti+j]] = norms[idx[ti+j]] + fn
	for ni in norms.size(): norms[ni] = -norms[ni].normalized()
	var arrays := []; arrays.resize(Mesh.ARRAY_MAX); arrays[Mesh.ARRAY_VERTEX]=verts; arrays[Mesh.ARRAY_NORMAL]=norms; arrays[Mesh.ARRAY_TEX_UV]=uvs; arrays[Mesh.ARRAY_COLOR]=cols; arrays[Mesh.ARRAY_INDEX]=idx
	var tmesh := ArrayMesh.new(); tmesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new(); mi.mesh = tmesh; var m := StandardMaterial3D.new(); m.vertex_color_use_as_albedo = true; m.albedo_texture = load(PT + "detail_noise.png"); m.albedo_color = Color(0.55,0.63,0.49); m.roughness = 1.0; mi.material_override = m; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(mi)
	# outer trees sit on terrain
func _setup() -> void:
	get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	# round presets: 1 pipeline, 2 softer/yellower, 3 tuned toward target mean colour
	var grass := Color("6fbf3f"); var grass2 := Color("8fd14f"); var stone := Color("b8b4a8"); var roof := Color("c23b2a"); var dirt := Color("c9a86a"); var leaf := Color("4e9b35"); var leaf2 := Color("77c04a"); var light_e := 1.0; var amb := 0.55
	if round_no == 2:
		grass = Color("69bd45"); grass2 = Color("86cc58"); stone = Color("c4bda9"); roof = Color("c2442c"); leaf = Color("4fae38"); leaf2 = Color("7cc24e"); light_e = 1.05; amb = 0.45
	if round_no >= 3:
		grass = Color("406e26"); grass2 = Color("4f7f2e"); stone = Color("9d9584"); roof = Color("bf3f27"); dirt = Color("cda96e"); leaf = Color("4e8f33"); leaf2 = Color("7cb54f"); light_e = 0.88; amb = 0.50
	# environment + light + camera (game iso: ortho, pitch -38, yaw -45)
	var we := WorldEnvironment.new(); var env := Environment.new()
	var sky := Sky.new(); var smat := ProceduralSkyMaterial.new(); smat.sky_top_color = Color("8fc3e8"); smat.sky_horizon_color = Color("f2e3c2"); smat.ground_bottom_color = Color("5d6b46"); smat.ground_horizon_color = Color("d9c9a4"); sky.sky_material = smat; env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY; env.ambient_light_energy = amb * 0.55; env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.fog_enabled = true; env.fog_light_color = Color("f2e3c2"); env.fog_density = 0.0015; env.tonemap_mode = Environment.TONE_MAPPER_ACES; env.adjustment_enabled = true; env.adjustment_saturation = 1.10; env.adjustment_contrast = 1.02; env.adjustment_brightness = 1.02; env.glow_enabled = false; env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT;
	we.environment = env; add_child(we)
	var pool := OmniLight3D.new(); pool.position = Vector3(0,4.5,1); pool.light_color = Color("ffd9a0"); pool.light_energy = 0.6; pool.omni_range = 14.0; pool.shadow_enabled = false; add_child(pool)
	var fill := DirectionalLight3D.new(); fill.rotation_degrees = Vector3(-38, 125, 0); fill.light_energy = 0.20; fill.light_color = Color("cfe6ff"); fill.shadow_enabled = false; add_child(fill)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-52, -38, 0); sun.light_energy = light_e; sun.light_color = Color(1,0.96,0.88); sun.shadow_enabled = true; sun.shadow_opacity = 0.40; sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS; sun.shadow_blur = 7.0; add_child(sun)
	var cam := Camera3D.new(); cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	if OS.get_cmdline_user_args().has("--hill"):
		cam.size = 12.0; cam.look_at_from_position(Vector3(24,12,8), Vector3(12,3,-12), Vector3.UP)
	elif OS.get_cmdline_user_args().has("--close"):
		cam.size = 6.5; cam.look_at_from_position(Vector3(9.5,8,7.5), Vector3(2.6,0.6,-0.8), Vector3.UP)
	else:
		cam.size = 24.5 if round_no>=10 else 19.0; cam.look_at_from_position(Vector3(13.5,11,11.6), Vector3(3.4,0.6,-2.4), Vector3.UP)
	cam.current = true; add_child(cam)	# ground grass: big plane + lighter patches
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
		add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(0,float(bi),0)).scaled(Vector3(0.7,0.5,0.6)), Vector3(bx, _h(bx,bz)+0.15, bz)), Color("8a867e")); tri_total += 128
	for si9 in 15:
		var sx9 := 8.5 + fmod(float(si9)*3.17, 12.5); var sz9 := -8.0 - fmod(float(si9)*2.43, 7.5)
		var ss9 := 1.1 + fmod(float(si9)*0.41, 1.1)
		add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(0.3,float(si9)*1.7,0.15)).scaled(Vector3(ss9,ss9*0.72,ss9*0.85)), Vector3(sx9, _h(sx9,sz9)+ss9*0.22, sz9)), Color("6e6355") if si9%2==0 else Color("a89a80")); tri_total += 128
	for ti9 in 13:
		var tx9 := 6.5 + fmod(float(ti9)*2.61, 14.5); var tz9 := -6.2 - fmod(float(ti9)*1.37, 3.2)
		var ts9 := 0.55 + fmod(float(ti9)*0.39, 0.6)
		add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(0.2,float(ti9)*2.1,0.1)).scaled(Vector3(ts9,ts9*0.62,ts9*0.8)), Vector3(tx9, _h(tx9,tz9)+ts9*0.18, tz9)), Color("6e6355") if ti9%3==0 else (Color("a89a80") if ti9%3==1 else Color("a89a80"))); tri_total += 128
	for ei in 10:
		var ex := -11.0+fmod(float(ei)*4.91,23.0); var ez := -6.0+fmod(float(ei)*5.37,17.0)
		cyl(Vector3(ex,0.03,ez), 0.62,0.62,0.025, Color("9a7c4e") if ei%2==0 else Color("b08d55"), 8)
	for fi in 36:
		var fx2 := -12.0+fmod(float(fi)*3.97,25.0); var fz := -9.0+fmod(float(fi)*4.53,20.0)
		if Vector2(fx2,fz).length() < 11.0:
			for fo in 3: cyl(Vector3(fx2+float(fo)*0.09-0.09,0.04,fz+fmod(float(fo)*0.07,0.12)), 0.045,0.045,0.03, [Color("ffffff"),Color("ffd94a"),Color("ff9db0")][fi%3], 5)
	# branch paths connecting buildings
	for seg in [[Vector2(3.2,-1.2),Vector2(7.2,-3.8)],[Vector2(-3.4,4.6),Vector2(-8.6,4.8)],[Vector2(3.2,-1.2),Vector2(6.2,4.2)],[Vector2(-1.5,-3.5),Vector2(-5.6,3.4)],[Vector2(-1,2),Vector2(-5,9.5)],[Vector2(6,3),Vector2(12.5,4.5)],[Vector2(-4,5),Vector2(-8,8)]]:
		var a2: Vector2 = seg[0]; var b2: Vector2 = seg[1]; var mid2 := (a2+b2)*0.5; var dir2 := b2-a2
		box(Vector3(mid2.x,0.028,mid2.y), Vector3(1.25,0.035,dir2.length()+0.8), Color("c9ab72"), atan2(dir2.x,dir2.y), 0,0, "dirt")
	for li2 in 5:
		var lx2 := 10.0+fmod(float(li2)*2.3,6.0); var lz2 := -8.0-fmod(float(li2)*1.1,4.0)
		add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(0.2,float(li2),0.1)).scaled(Vector3(1.1,0.65,0.9)), Vector3(lx2,_h(lx2,lz2)+0.3,lz2)), Color("6e665c"), "rock"); tri_total+=128
	_hill_content(); _hill_props(); _hill_fields(); _summit(); _upper_fill(); _fill_more(); _top_band(); _aprons(); _props2()
	for uw in [[Vector3(-4.2,0,7.6), Color("d43a2a")], [Vector3(2.8,0,8.8), Color("2f62b8")], [Vector3(-9.8,0,5.6), Color("2f62b8")], [Vector3(4.4,_h(4.4,-6.2),-6.2), Color("d43a2a")], [Vector3(13.2,_h(13.2,-12.4),-12.4), Color("2f62b8")], [Vector3(-13.2,0,9.2), Color("d43a2a")], [Vector3(5.0,_h(5.0,-6.4),-6.4), Color("2f62b8")], [Vector3(8.2,_h(8.2,-10.1),-10.1), Color("d43a2a")], [Vector3(11.5,_h(11.5,-11.2),-11.2), Color("2f62b8")], [Vector3(15.0,_h(15.0,-13.6),-13.6), Color("d43a2a")], [Vector3(6.8,_h(6.8,-13.4),-13.4), Color("2f62b8")]]:
		_mini(uw[0], uw[1])
	for gp in [Vector3(-3.6,0,6.2), Vector3(3.4,0,-3.4), Vector3(8.8,0,5.2), Vector3(-7.4,0,-1.6)]:
		blob(gp+Vector3(0,0.24,0), Vector3(0.3,0.26,0.3), Color("a67c4e")); blob(gp+Vector3(0.28,0.18,0.14), Vector3(0.24,0.2,0.24), Color("a67c4e")); cyl(gp+Vector3(-0.3,0.34,0.1), 0.24,0.27,0.68, Color("8a5f36"), 8)
	for up2 in [Vector3(6.2,_h(6.2,-9.8),-9.8), Vector3(12.8,_h(12.8,-12.6),-12.6), Vector3(17.5,_h(17.5,-11.0),-11.0)]:
		cyl(up2+Vector3(0,0.4,0), 0.3,0.34,0.8, Color("8a5f36"), 8); box(up2+Vector3(0.55,0.3,0.3), Vector3(0.55,0.55,0.55), Color("a67c4e"), 0.3)
	for mw in [[Vector3(5.2,_h(5.2,-6.3),-6.3), Color("2f62b8")], [Vector3(7.2,_h(7.2,-7.0),-7.0), Color("d43a2a")], [Vector3(8.6,_h(8.6,-6.4),-6.4), Color("3f7d3a")], [Vector3(-2.2,0,8.6), Color("d43a2a")], [Vector3(11.2,0,6.4), Color("2f62b8")], [Vector3(-9.2,0,-4.2), Color("2f62b8")]]: _mini(mw[0], mw[1])
	for mw2 in [[Vector3(1.8,0,6.8), Color("3f7d3a")], [Vector3(-6.8,0,8.4), Color("2f62b8")], [Vector3(10.4,0,-1.8), Color("d43a2a")], [Vector3(-11.8,0,3.4), Color("3f7d3a")], [Vector3(4.8,0,9.6), Color("2f62b8")], [Vector3(12.6,_h(12.6,-9.6),-9.6), Color("d43a2a")], [Vector3(7.6,_h(7.6,-11.8),-11.8), Color("3f7d3a")], [Vector3(-4.8,0,-6.6), Color("2f62b8")]]: _mini(mw2[0], mw2[1])
	for sp9 in [Vector3(2.2,0,4.4), Vector3(-7.8,0,7.2), Vector3(9.2,0,3.2), Vector3(-2.8,0,-1.8), Vector3(6.6,0,7.8), Vector3(-10.6,0,-5.2), Vector3(13.8,0,7.2), Vector3(0.4,0,11.6)]:
		box(sp9+Vector3(0,0.16,0), Vector3(0.36,0.32,0.36), Color("a67c4e"), 0.3); cyl(sp9+Vector3(0.42,0.20,0.18), 0.17,0.19,0.4, Color("8a5f36"), 7)
	# market stall: posts, striped canopy, crates
	for mp in [Vector3(-4.6,0,5.9), Vector3(-3.4,0,5.9), Vector3(-4.6,0,7.0), Vector3(-3.4,0,7.0)]: box(mp+Vector3(0,0.75,0), Vector3(0.13,1.5,0.13), Color("6b4423"))
	roof2(Vector3(-4.0,1.52,6.45), 2.3, 2.1, 0.55, 0.14, Color("d43a2a"))
	box(Vector3(-4.0,0.55,6.45), Vector3(1.6,0.5,1.2), Color("a67c4e"), 0,0,0, "timber")
	for fp2 in [Vector3(7.5,0,5.5), Vector3(-10.0,0,-3.5), Vector3(9.0,0,-4.5)]:
		box(fp2+Vector3(0,2.2,0), Vector3(0.06,1.3,0.06), Color("4a3421")); box(fp2+Vector3(0.35,2.6,0), Vector3(0.65,0.38,0.04), Color("2f62b8") if fp2.x>0 else Color("d43a2a"))
	for wpath in [[Vector2(-10.5,5.5),Vector2(-4.5,6.0),Vector2(0,3.2),Vector2(7.5,5.5),Vector2(12.0,2.5),Vector2(15.0,5.5)],[Vector2(-10.0,-3.5),Vector2(-5.0,-1.2),Vector2(-1.5,-3.3),Vector2(3.2,-1.2),Vector2(9.0,-4.5),Vector2(11.5,-6.2),Vector2(13.5,-7.5)],[Vector2(-1.5,-3.3),Vector2(1.5,-6.0),Vector2(5.0,-7.5),Vector2(9.0,-8.8)],[Vector2(-7.0,11.5),Vector2(-4.5,8.5),Vector2(-4.5,6.0)],[Vector2(7.5,5.5),Vector2(9.5,8.5),Vector2(14.0,12.0)]]:
		for wi2 in wpath.size()-1:
			var wa: Vector2 = wpath[wi2]; var wb: Vector2 = wpath[wi2+1]; var wlen := wa.distance_to(wb); var wsteps := int(wlen / 0.65)
			for ws in wsteps+1:
				var wt := float(ws)/float(maxi(wsteps,1)); var wp := wa.lerp(wb, wt)
				var wdir := (wb-wa).normalized(); var wperp := Vector2(-wdir.y, wdir.x)
				wp += wperp * sin(wt*5.0 + float(wi2)*1.7) * 0.35
				var wy: float = 0.032 + (_h(wp.x,wp.y) if Vector2(wp.x,wp.y).length() > 11.0 else 0.0)
				cyl(Vector3(wp.x, wy, wp.y), 0.82,0.82,0.035, dirt, 9)
	# castle centre-back
	_build_castle(Vector3(-1.5,0,-3.5), stone, roof)
	_build_octstore(Vector3(3.2,0,-1.2), stone)
	_build_hut(Vector3(7.5,0,5.5), stone)
	_build_aframe(Vector3(-4.5,0,6.0), roof, stone)
	_build_roundhouse(Vector3(9.0,0,-4.5), roof)
	_build_hut(Vector3(-10.0,0,-3.5), stone)
	# props: barrels, crates, fence, rocks
	for bp in [Vector3(5.4,0,-0.2), Vector3(-6.2,0,0.8), Vector3(1.8,0,-5.6)]:
		cyl(bp+Vector3(0,0.45,0), 0.38,0.42,0.9, Color("8a5f36"), 9); box(bp+Vector3(0.8,0.35,0.2), Vector3(0.7,0.7,0.7), Color("a67c4e"), 0.4)
	for fx in 4: box(Vector3(-6.0+float(fx)*0.65,0.45,6.6), Vector3(0.14,0.9,0.14), Color("6b4423"))
	box(Vector3(-4.7,0.75,6.6), Vector3(3.4,0.13,0.13), Color("7a5a36"))
	for fp in [Vector3(-1.5,0,-3.5), Vector3(3.2,0,-1.2)]:
		box(fp+Vector3(0,4.6,0), Vector3(0.07,1.4,0.07), Color("4a3421")); box(fp+Vector3(0.4,5.1,0), Vector3(0.75,0.42,0.04), Color("d43a2a"))
	# trees
	for p in [Vector3(-8,-0,-6),Vector3(6,0,-6),Vector3(8,0,1),Vector3(-9,0,3),Vector3(5.5,0,6.5),Vector3(-6.5,0,-4),Vector3(1.5,0,-7.5)]:
		_build_tree(p, leaf, leaf2)
	_build_roundbarn(Vector3(-10.5,0,5.5), roof)
	_build_roundhouse(Vector3(12.0,0,2.5), roof)
	_build_aframe(Vector3(-6.5,0,-10.0), roof, stone)
	_build_octstore(Vector3(14.0,0,12.5), stone)
	_build_house(Vector3(-7.0,0,12.0), roof, stone)
	_build_house(Vector3(15.0,0,5.5), roof, stone)
	_build_hut(Vector3(17.5,_h(17.5,1.0),1.0), stone)
	for tp in [Vector3(-14,0,-8),Vector3(-15,0,2),Vector3(-13,0,9),Vector3(13,0,10),Vector3(19,0,-7),Vector3(8,0,-15),Vector3(-11,0,-11),Vector3(4,0,11),Vector3(-4,0,12),Vector3(14,0,5)]:
		_build_tree(tp, leaf, leaf2)
	for bs2 in [Vector3(-2,0,9.5),Vector3(10,0,9),Vector3(-13,0,-1),Vector3(4,0,-9),Vector3(12,0,-3),Vector3(-8,0,-9)]:
		add_canopy(Transform3D(Basis.IDENTITY.scaled(Vector3(0.8,0.55,0.8)), bs2+Vector3(0,0.45,0)), leaf)
	for bs in [Vector3(-5,0,-7),Vector3(6,0,8),Vector3(-10,0,-3),Vector3(9,0,-8)]:
		add_canopy(Transform3D(Basis.IDENTITY.scaled(Vector3(0.9,0.6,0.9)), bs+Vector3(0,0.5,0)), leaf)
	# stones
	for p in [Vector3(4.8,0.25,-4),Vector3(-7.5,0.2,6),Vector3(7,0.2,-2)]: blob(p, Vector3(0.5,0.35,0.45), Color("9a968c"))
	for ap in [Vector3(-1.5,0,-3.5), Vector3(3.2,0,-1.2), Vector3(-4.5,0,6.0), Vector3(7.5,0,5.5), Vector3(9.0,0,-4.5)]:
		cyl(ap+Vector3(0,0.018,0), 2.6,2.6,0.015, Color(0.10,0.16,0.05,0.45), 14)
	# coloured flower patches merged into existing colour meshes (blooms survive, no dots/instances)
	var bloom_cols := [Color("e2543e"), Color("ffd94a"), Color("ff9db0"), Color("e2543e"), Color("ffd94a"), Color("f2f0e6")]
	for bc in 6:
		var zone: Vector2 = [Vector2(-10,6.5), Vector2(0.5,10.5), Vector2(11,9.5), Vector2(-12.5,-3.5), Vector2(4,-10.5), Vector2(-6,-11)][bc]
		blob(Vector3(zone.x,0.045,zone.y), Vector3(1.7,0.05,1.25), Color("7fae4a"))
		for bb in 30:
			var bpx := zone.x + fmod(float(bb)*0.61,3.0)-1.5; var bpz := zone.y + fmod(float(bb)*0.83,2.2)-1.1
			blob(Vector3(bpx,0.09,bpz), Vector3(0.25,0.08,0.25), bloom_cols[(bc+bb)%6])
	for cp2 in [Vector3(0.6,0,2.8), Vector3(-2.6,0,0.8), Vector3(5.2,0,1.6), Vector3(-6.4,0,-1.4), Vector3(-8.8,0,5.6), Vector3(8.6,0,4.6), Vector3(3.8,0,-4.2), Vector3(-9.5,0,1.5)]:
		var lm2 := CylinderMesh.new(); lm2.bottom_radius=0.09; lm2.top_radius=0.09; lm2.height=1.0; lm2.radial_segments=8
		add_mesh(lm2, Transform3D(Basis.from_euler(Vector3(0,0,PI/2.0)), cp2+Vector3(0,1.28,0.12)), Color("8a5f36")); tri_total += 32
	for wi in 18:
		var wx := -14.0+fmod(float(wi)*3.13,28.0); var wz := -11.0+fmod(float(wi)*4.71,22.0)
		cyl(Vector3(wx,0.025,wz), 0.85+fmod(float(wi)*0.21,0.7), 0.85+fmod(float(wi)*0.21,0.7), 0.02, Color("b89a68") if wi%2==0 else Color("a8895a"), 9)
	for plot in [Vector3(-12,0,10.5), Vector3(8,0,10.8), Vector3(-14,0,-7.5)]:
		box(plot+Vector3(0,0.05,0), Vector3(2.7,0.07,1.9), Color("8a6c42"), 0.2)
		for pr in 4: box(plot+Vector3(-0.95+float(pr)*0.62,0.13,0), Vector3(0.4,0.1,1.6), Color("5da038"), 0.2)
	# commit merged meshes
	for key in surf:
		var st: SurfaceTool = surf[key]; var mesh := st.commit()
		var mi := MeshInstance3D.new(); mi.mesh = mesh; mi.material_override = mat_for(key, Color.html(key.split("|")[0])); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON; add_child(mi)
	var roof_groups := {}
	for ri2 in roof_instances:
		var rv := absi(int(ri2[1].origin.x*5.0 + ri2[1].origin.z*3.0)) % 3
		if not roof_groups.has(rv): roof_groups[rv] = SurfaceTool.new(); (roof_groups[rv] as SurfaceTool).begin(Mesh.PRIMITIVE_TRIANGLES)
		(roof_groups[rv] as SurfaceTool).append_from(ri2[0], 0, ri2[1])
	for rv2 in roof_groups:
		var rmi := MeshInstance3D.new(); rmi.mesh = (roof_groups[rv2] as SurfaceTool).commit(); var rmat := StandardMaterial3D.new(); rmat.albedo_texture = load(TEX["roofp"]); rmat.albedo_color = [Color(0.88,0.88,0.88), Color(0.80,0.74,0.70), Color(0.92,0.84,0.74)][rv2]; rmat.roughness = 0.92; rmat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS; rmi.material_override = rmat; rmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON; add_child(rmi)
	if canopy_st != null:
		var cmi := MeshInstance3D.new(); cmi.mesh = canopy_st.commit(); var cm := StandardMaterial3D.new(); cm.albedo_texture = load(TEX["leafp"]); cm.vertex_color_use_as_albedo = true; cm.albedo_color = Color(0.88,0.92,0.84); cm.roughness = 1.0; cm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS; cmi.material_override = cm; cmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON; add_child(cmi)
	if card_st != null:
		var kmi := MeshInstance3D.new(); kmi.mesh = card_st.commit(); var km := StandardMaterial3D.new(); km.albedo_texture = load(PT + "foliage_card.png"); km.vertex_color_use_as_albedo = true; km.albedo_color = Color(1,1,1); km.roughness = 1.0; km.alpha_scissor_threshold = 0.45; km.cull_mode = BaseMaterial3D.CULL_DISABLED; km.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS; kmi.material_override = km; kmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(kmi)
	_spawn_tufts()
	_spawn_carriers(); _spawn_statics()
func _spawn_carriers() -> void:
	var chars := ["Farmer_B", "Farmer_A", "Rogue_Hooded", "Rogue"]
	var cps := [Vector3(0.6,0.05,2.8), Vector3(-2.6,0.05,0.8), Vector3(5.2,0.05,1.6), Vector3(-6.4,0.05,-1.4), Vector3(-8.8,0.05,5.6), Vector3(8.6,0.05,4.6), Vector3(3.8,0.05,-4.2), Vector3(-9.5,0.05,1.5)]
	for ci2 in cps.size():
		var cp: Vector3 = cps[ci2]; var ps: PackedScene = load("res://assets/settlement3d/runtime/characters/" + chars[ci2 % chars.size()] + ".glb")
		if ps == null: _build_carrier(cp); continue
		var ch := ps.instantiate() as Node3D; ch.position = cp; ch.rotation.y = -0.7; ch.scale = Vector3.ONE * 0.62; add_child(ch)
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
		# carrier log merged pre-commit in _setup (saves a draw per carrier)
func _spawn_statics() -> void:
	var defs := [["Farmer_A", Vector3(-7.6,0.05,3.2), "Tools_/Chopping"], ["Knight", Vector3(2.2,0.05,-5.4), "General_/Idle_A"], ["Farmer_B", Vector3(-4.0,0.05,5.2), "Tools_/Hammering"], ["Farmer_A", Vector3(9.6,_h(9.6,-7.0)+0.05,-7.0), "Tools_/Hammering"], ["Rogue_Hooded", Vector3(-5.0,0.05,4.4), "General_/Idle_A"], ["Farmer_A", Vector3(6.0,_h(6.0,-6.8)+0.05,-6.8), "Tools_/Chopping"], ["Farmer_B", Vector3(11.0,_h(11.0,-11.0)+0.05,-11.0), "Tools_/Hammering"]]
	for df in defs:
		var ps2: PackedScene = load("res://assets/settlement3d/runtime/characters/" + String(df[0]) + ".glb")
		if ps2 == null: continue
		var ch2 := ps2.instantiate() as Node3D; ch2.position = df[1]; ch2.rotation.y = 0.8; ch2.scale = Vector3.ONE * 0.62; add_child(ch2)
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
func _build_mine(mp: Vector3) -> void:
	box(mp+Vector3(0,0.75,-0.15), Vector3(1.5,1.5,0.18), Color("17110b"))
	box(mp+Vector3(-0.82,0.85,0), Vector3(0.2,1.9,0.24), Color("6b4a2c")); box(mp+Vector3(0.82,0.85,0), Vector3(0.2,1.9,0.24), Color("6b4a2c"))
	box(mp+Vector3(0,1.85,0), Vector3(1.95,0.24,0.26), Color("7a5a36"))
	box(mp+Vector3(-0.45,0.45,0), Vector3(0.14,1.1,0.14), Color("54381f"))
	for rz in 2: box(mp+Vector3(-0.32+float(rz)*0.64, -0.55, 1.5), Vector3(0.09,0.06,2.6), Color("4c4c50"))
	for sl in 4: box(mp+Vector3(0, -0.62, 0.55+float(sl)*0.62), Vector3(0.95,0.07,0.16), Color("6b4a2c"))
	box(mp+Vector3(0,-0.25,2.1), Vector3(0.78,0.42,1.0), Color("54381f")); box(mp+Vector3(0,0.02,2.1), Vector3(0.66,0.2,0.84), Color("4c4c50"))
func _build_watchtower(tp: Vector3) -> void:
	for lx in [-0.55, 0.55]:
		for lz in [-0.55, 0.55]: box(tp+Vector3(lx,2.1,lz), Vector3(0.17,4.2,0.17), Color("6b4a2c"))
	box(tp+Vector3(0,2.2,0.62), Vector3(1.35,0.12,0.12), Color("54381f"), 0, 0, 0.5); box(tp+Vector3(0,2.2,-0.62), Vector3(1.35,0.12,0.12), Color("54381f"), 0, 0, -0.5)
	box(tp+Vector3(0,4.3,0), Vector3(1.8,0.18,1.8), Color("7a5a36"))
	box(tp+Vector3(0,5.05,0), Vector3(1.45,1.35,1.45), Color("a8875e"), 0,0,0, "timber")
	box(tp+Vector3(0,5.15,0.75), Vector3(0.44,0.5,0.06), Color("ffd98a"))
	cyl(tp+Vector3(0,6.25,0), 1.35,0.04,1.15, Color("9c4a34"), 8, "roofp")
func _hill_content() -> void:
	_build_mine(Vector3(10.5, _h(10.5,-8.5)+0.55, -8.5))
	_build_watchtower(Vector3(14.2, _h(14.2,-6.9)-0.15, -6.9))
	var sw := [Vector2(2,-4.5), Vector2(6,-5.2), Vector2(5.2,-6.8), Vector2(8.6,-7.2), Vector2(10.2,-8.0)]
	for si in sw.size()-1:
		var a3: Vector2 = sw[si]; var b3: Vector2 = sw[si+1]; var mid3 := (a3+b3)*0.5; var dir3 := b3-a3
		box(Vector3(mid3.x, _h(mid3.x,mid3.y)+0.06, mid3.y), Vector3(1.15,0.07,dir3.length()+0.7), Color("c9ab72"), atan2(dir3.x,dir3.y), 0,0, "dirt")
	for ti in 6:
		var tx2 := 4.2+float(ti)*2.0; var tz2 := -6.2-float(ti)*0.6
		var ty2 := _h(tx2,tz2)+0.05
		box(Vector3(tx2, ty2, tz2), Vector3(4.4,0.16,1.5), Color("86b83e") if ti%2==0 else Color("b08d55"), 0.15, 0, 0, "dirt" if ti%2==1 else "")
		box(Vector3(tx2, ty2-0.06, tz2+0.82), Vector3(4.5,0.22,0.18), Color("8a7a5c"), 0.15)
		for cr in 5: box(Vector3(tx2-1.5+float(cr)*0.75, ty2+0.10, tz2), Vector3(0.5,0.09,1.25), Color("3f7020") if ti%2==0 else Color("96683c"), 0.15)
	for stp in [Vector3(8,0,-9.5), Vector3(16.5,0,-12.5), Vector3(22,0,-11), Vector3(15,0,-13.5)]:
		_build_tree(stp, Color("79c24d"), Color("a9dd77"))
func _hill_props() -> void:
	cyl(Vector3(9.0,_h(9.0,-7.4)+0.4,-7.4), 0.3,0.34,0.8, Color("8a5f36"), 8)
	box(Vector3(11.9,_h(11.9,-7.8)+0.3,-7.8), Vector3(0.6,0.6,0.6), Color("a67c4e"), 0.4)
	for fp3 in [Vector3(4.2,_h(4.2,-5.6),-5.6), Vector3(6.8,_h(6.8,-6.6),-6.6), Vector3(9.2,_h(9.2,-7.4),-7.4)]:
		box(fp3+Vector3(0.7,0.9,0.5), Vector3(0.09,1.1,0.09), Color("6b4a2c")); box(fp3+Vector3(0.7,1.45,0.5), Vector3(0.55,0.3,0.04), Color("d43a2a"))
func _hill_fields() -> void:
	for fi2 in 2:
		var fx5 := 3.4+float(fi2)*3.4; var fz5 := -5.6-float(fi2)*0.4; var fy5 := _h(fx5,fz5)+0.05
		box(Vector3(fx5, fy5, fz5), Vector3(4.6,0.15,1.7), Color("86b83e") if fi2%2==0 else Color("b08d55"), 0.12, 0, 0, "" if fi2%2==0 else "dirt")
		for cr2 in 5: box(Vector3(fx5-1.6+float(cr2)*0.8, fy5+0.1, fz5), Vector3(0.5,0.09,1.45), Color("3f7020") if fi2%2==0 else Color("96683c"), 0.12)
		for fp4 in 4: box(Vector3(fx5-2.1+float(fp4)*1.4, fy5+0.35, fz5+0.95), Vector3(0.09,0.7,0.09), Color("6b4a2c"))
	for fi3 in 6:
		var fx6 := 2.2+float(fi3)*1.9; var fz6 := -5.0 - float(fi3%3)*0.95; var fy6 := _h(fx6,fz6)+0.05
		box(Vector3(fx6, fy6, fz6), Vector3(4.8,0.15,1.6), Color("7fae4a") if fi3%2==0 else Color("a67c4e"), 0.1, 0, 0, "" if fi3%2==0 else "dirt")
		for cr3 in 5: box(Vector3(fx6-1.6+float(cr3)*0.8, fy6+0.1, fz6), Vector3(0.5,0.09,1.4), Color("4e7d26") if fi3%2==0 else Color("96683c"), 0.1)
	for tp3 in [Vector3(4.5,0,-11.5), Vector3(11,0,-12.5), Vector3(20,0,-9.5), Vector3(7.5,0,-13), Vector3(17,0,-13.5)]:
		_build_tree(tp3, Color("79c24d"), Color("a9dd77"))
	_build_hut(Vector3(8.2, _h(8.2,-11.2)-0.1, -11.2), Color("9d9584"))
	var sh := Vector3(12.5, _h(12.5,-9.8), -9.8)
	box(sh+Vector3(0,0.65,0), Vector3(1.7,1.3,1.5), Color("cbb489"))
	cyl(sh+Vector3(0,1.75,0), 1.45,0.2,1.2, Color("b98a35"), 8, "thatch")
	_build_tree(Vector3(6.5,0,-10.5), Color("79c24d"), Color("a9dd77")); _build_tree(Vector3(23,0,-5.0), Color("79c24d"), Color("a9dd77"))
func _summit() -> void:
	var base := Vector3(9.0, _h(9.0,-8.8), -8.8)
	cyl(base+Vector3(0,0.05,0), 2.8,2.8,0.07, Color("c9ab72"), 14, "dirt")
	cyl(base+Vector3(0,0.09,0), 1.5,1.5,0.08, Color("9a958a"), 12)
	for ri4 in 7:
		var ra := float(ri4) * TAU / 7.0
		blob(base+Vector3(sin(ra)*2.45, 0.18, cos(ra)*2.45), Vector3(0.32,0.22,0.32), Color("8a867e"))
	for si4 in 5:
		var sa := float(si4) * TAU / 5.0
		var sty := 3.1+fmod(float(si4)*0.3,0.7)
		box(base+Vector3(sin(sa)*1.3, sty/2.0, cos(sa)*1.3), Vector3(0.62,sty,0.4), Color("59564f"), sa, 0.12, 0)
		box(base+Vector3(sin(sa)*1.3, sty+0.12, cos(sa)*1.3), Vector3(0.5,0.24,0.32), Color("eef2f4"), sa, 0.12, 0)
		box(base+Vector3(sin(sa)*2.35, 0.28, cos(sa)*2.35), Vector3(0.55,0.55,0.4), Color("8a867e"), sa, 0, 0)
	box(base+Vector3(0,1.7,0), Vector3(0.7,3.4,0.48), Color("59564f"), 0.3, 0.08, 0)
	box(base+Vector3(0,3.55,0), Vector3(0.55,0.3,0.36), Color("eef2f4"), 0.3, 0.08, 0)
	box(base+Vector3(0,2.6,0.35), Vector3(0.08,2.2,0.08), Color("6b4a2c")); box(base+Vector3(0.38,3.35,0.35), Vector3(0.68,0.4,0.04), Color("d43a2a"))
	var up := [Vector2(11.5,-7.6), Vector2(10.4,-8.2), Vector2(9.6,-8.6), Vector2(9.0,-8.8)]
	for ui in up.size()-1:
		var a4: Vector2 = up[ui]; var b4: Vector2 = up[ui+1]; var mid4 := (a4+b4)*0.5; var dir4 := b4-a4
		box(Vector3(mid4.x, _h(mid4.x,mid4.y)+0.06, mid4.y), Vector3(1.05,0.07,dir4.length()+0.6), Color("c9ab72"), atan2(dir4.x,dir4.y), 0,0, "dirt")
	for tp4 in [Vector3(7.5,0,-16), Vector3(20.5,0,-15), Vector3(17,0,-16.5), Vector3(24,0,-12.5)]:
		_build_tree(tp4, Color("79c24d"), Color("a9dd77"))
	for rf in 3:
		var rx4 := 9.0+float(rf)*4.2; var rz4 := -13.5-float(rf)*0.8
		box(Vector3(rx4, _h(rx4,rz4)+0.05, rz4), Vector3(3.6,0.13,1.4), Color("8d8172"), 0.2, 0, 0, "rock")
		for sb in 4: blob(Vector3(rx4-1.2+float(sb)*0.8, _h(rx4,rz4)+0.16, rz4), Vector3(0.3,0.2,0.3), Color("a89a80"))
	for sd in 4:
		var sx5 := 9.5+float(sd)*2.0; var sz5 := -14.5-fmod(float(sd)*1.1,2.0)
		blob(Vector3(sx5, _h(sx5,sz5)+0.08, sz5), Vector3(0.85,0.22,0.7), Color("eef2f4"))
func _upper_fill() -> void:
	for mf in 4:
		var mx := 7.0+float(mf)*3.6; var mz := -10.8 - float(mf%2)*1.6; var my := _h(mx,mz)+0.05
		box(Vector3(mx, my, mz), Vector3(4.2,0.14,1.5), Color("86b83e") if mf%2==0 else Color("a89a80"), 0.18)
		for cr4 in 4: box(Vector3(mx-1.4+float(cr4)*0.9, my+0.1, mz), Vector3(0.5,0.09,1.3), Color("4e7d26") if mf%2==0 else Color("7e7668"), 0.18)
	for tp5 in [Vector3(8.5,0,-12), Vector3(13,0,-11), Vector3(19.5,0,-12.8), Vector3(11.5,0,-14.5), Vector3(22,0,-9)]:
		_build_tree(tp5, Color("79c24d"), Color("a9dd77"))
	_build_hut(Vector3(22.0, _h(22.0,-13.8)-0.1, -13.8), Color("9d9584"))
	var net := [Vector2(10.5,-8.5), Vector2(12.5,-9.8), Vector2(14.2,-8.2), Vector2(15.0,-11.0), Vector2(19.0,-11.6)]
	for ni in net.size()-1:
		var a5: Vector2 = net[ni]; var b5: Vector2 = net[ni+1]; var mid5 := (a5+b5)*0.5; var dir5 := b5-a5
		box(Vector3(mid5.x, _h(mid5.x,mid5.y)+0.06, mid5.y), Vector3(1.0,0.07,dir5.length()+0.6), Color("c9ab72"), atan2(dir5.x,dir5.y), 0,0, "dirt")
	for fp5 in 5:
		var fx7 := 8.0+float(fp5)*2.6; var fz7 := -10.2-fmod(float(fp5)*0.7,1.8)
		box(Vector3(fx7, _h(fx7,fz7)+0.4, fz7), Vector3(0.09,0.8,0.09), Color("6b4a2c"))
func _fill_more() -> void:
	for tp6 in [Vector3(9.5,0,-13.5), Vector3(15.5,0,-14.0), Vector3(20.5,0,-8.5), Vector3(6.5,0,-14.5), Vector3(16.5,0,-15.5), Vector3(23.5,0,-13)]:
		_build_tree(tp6, Color("79c24d"), Color("a9dd77"))
	for cf in 3:
		var cx6 := 8.5+float(cf)*5.0; var cz6 := -12.8-float(cf)*0.5
		box(Vector3(cx6, _h(cx6,cz6)+0.05, cz6), Vector3(5.6,0.15,1.8), Color("b08d55") if cf%2==0 else Color("86b83e"), 0.15)
		for oc in 3: blob(Vector3(cx6-1.6+float(oc)*1.5, _h(cx6,cz6)+0.2, cz6+0.6), Vector3(0.5,0.35,0.5), Color("a89a80"))
	for cf2 in 3:
		var cx7 := 7.5+float(cf2)*5.2; var cz7 := -9.9-float(cf2)*0.3
		box(Vector3(cx7, _h(cx7,cz7)+0.05, cz7), Vector3(5.8,0.15,1.7), Color("86b83e") if cf2%2==0 else Color("b08d55"), 0.12)
		for cr6 in 5: box(Vector3(cx7-1.9+float(cr6)*0.95, _h(cx7,cz7)+0.15, cz7), Vector3(0.55,0.09,1.5), Color("3f7020") if cf2%2==0 else Color("96683c"), 0.12)
	for tp7 in [Vector3(6.5,0,-10.5), Vector3(17.5,0,-10.2), Vector3(5.5,0,-12.8), Vector3(21.5,0,-14.5)]:
		_build_tree(tp7, Color("79c24d"), Color("a9dd77"))
	for cf3 in 2:
		var cx8 := 5.5+float(cf3)*7.5; var cz8 := -11.6
		box(Vector3(cx8, _h(cx8,cz8)+0.05, cz8), Vector3(5.4,0.14,1.6), Color("b08d55") if cf3%2==0 else Color("86b83e"), 0.14)
		for fp6 in 4: box(Vector3(cx8-2.2+float(fp6)*1.45, _h(cx8,cz8)+0.45, cz8+0.9), Vector3(0.09,0.75,0.09), Color("6b4a2c"))
	# lower-left farm: fields + trees + fence (fills reframed meadow)
	for lf in 2:
		var lx6 := -13.5+float(lf)*0.4; var lz6 := 8.5+float(lf)*2.2
		box(Vector3(lx6, 0.05, lz6), Vector3(5.2,0.12,2.0), Color("86b83e") if lf%2==0 else Color("b08d55"), 0.3)
		for cr5 in 5: box(Vector3(lx6-1.9+float(cr5)*0.95, 0.14, lz6), Vector3(0.55,0.09,1.7), Color("3f7020") if lf%2==0 else Color("96683c"), 0.3)
	_build_tree(Vector3(-15.5,0,4.5), Color("79c24d"), Color("a9dd77")); _build_tree(Vector3(-11,0,12), Color("79c24d"), Color("a9dd77"))
func _top_band() -> void:
	for tp8 in [Vector3(10,0,-16), Vector3(14,0,-17), Vector3(18,0,-16), Vector3(21.5,0,-14.5), Vector3(8,0,-11.8), Vector3(15,0,-13.8), Vector3(19,0,-11)]:
		_build_tree(tp8, Color("79c24d"), Color("a9dd77"))
	for sd2 in 5:
		var sx9 := 10.0+float(sd2)*2.6; var sz9 := -15.8+fmod(float(sd2)*0.9,1.6)
		blob(Vector3(sx9, _h(sx9,sz9)+0.08, sz9), Vector3(0.95,0.24,0.75), Color("eef2f4"))
		blob(Vector3(sx9+1.1, _h(sx9+1.1,sz9)+0.14, sz9), Vector3(0.5,0.36,0.5), Color("a89a80"))
	box(Vector3(15.5, _h(15.5,-15.2)+0.05, -15.2), Vector3(5.2,0.14,1.6), Color("a89a80"), 0.15)
	for cf4 in 2:
		var cx9 := 6.5+float(cf4)*7.0; var cz9 := -13.6
		box(Vector3(cx9, _h(cx9,cz9)+0.05, cz9), Vector3(5.2,0.14,1.6), Color("86b83e") if cf4%2==0 else Color("b08d55"), 0.14)
func _aprons() -> void:
	for ap2 in [Vector3(10.5,_h(10.5,-8.5),-8.5), Vector3(14.2,_h(14.2,-6.9),-6.9), Vector3(19.0,_h(19.0,-13.8),-13.8)]:
		blob(ap2+Vector3(0,0.03,0), Vector3(3.1,0.055,2.5), Color("8a6c42"))
		blob(ap2+Vector3(1.3,0.035,0.7), Vector3(2.0,0.05,1.6), Color("a8895a"))
		blob(ap2+Vector3(-1.5,0.03,-0.6), Vector3(1.8,0.05,1.5), Color("8a6c42"))
		blob(ap2+Vector3(2.3,0.025, -0.9), Vector3(1.3,0.045,1.1), Color("7fae4a"))
		blob(ap2+Vector3(-2.4,0.025,1.0), Vector3(1.2,0.045,1.0), Color("7fae4a"))
		for sti in 6:
			var soff := Vector3(sin(float(sti)*2.4+ap2.x)*1.9, 0.07, cos(float(sti)*1.9+ap2.z)*1.4)
			blob(ap2+soff, Vector3(0.22,0.10,0.20), Color("9a968c"))
		for dsi in 4:
			box(ap2+Vector3(sin(float(dsi)*1.8+ap2.z)*1.6, 0.05, cos(float(dsi)*2.2)*1.1), Vector3(0.85,0.03,0.20), Color("6e5638"), float(dsi)*0.7)
		for lbi in 7:
			var lang: float = float(lbi)*0.91 + float(ap2.x)
			var loff := Vector3(sin(lang)*3.15, 0.022, cos(lang*1.3)*2.45)
			blob(ap2+loff, Vector3(1.05,0.04,0.85), Color("7fae4a") if lbi%2==0 else Color("a8895a"))
func _props2() -> void:
	# log piles
	for lp in [Vector3(-6.8,0,7.6), Vector3(8.8,0,6.2), Vector3(1.2,0,7.8)]:
		for li in 5:
			var lm := CylinderMesh.new(); lm.bottom_radius=0.14; lm.top_radius=0.14; lm.height=1.15; lm.radial_segments=7
			add_mesh(lm, Transform3D(Basis.from_euler(Vector3(0,0,PI/2.0)), lp+Vector3(0,0.15+0.27*float(li%3),-0.3+0.3*float(li/3))), Color("8a6742")); tri_total += 28
	# cart
	var cp := Vector3(4.6,0,5.6)
	box(cp+Vector3(0,0.62,0), Vector3(1.5,0.14,0.95), Color("8a6742")); box(cp+Vector3(0,0.85,0.44), Vector3(1.5,0.4,0.08), Color("7a5a36")); box(cp+Vector3(0,0.85,-0.44), Vector3(1.5,0.4,0.08), Color("7a5a36"))
	for wx in [-0.62, 0.62]:
		var wm := CylinderMesh.new(); wm.bottom_radius=0.46; wm.top_radius=0.46; wm.height=0.1; wm.radial_segments=10
		add_mesh(wm, Transform3D(Basis.from_euler(Vector3(PI/2.0,0,0)), cp+Vector3(wx,0.46,0.52)), Color("54381f")); tri_total += 40
	# well
	var wp := Vector3(-5.6,0,-4.6)
	cyl(wp+Vector3(0,0.42,0), 0.62,0.68,0.85, Color("9a968c"), 9, "stone")
	box(wp+Vector3(-0.62,1.25,0), Vector3(0.13,1.7,0.13), Color("6b4a2c")); box(wp+Vector3(0.62,1.25,0), Vector3(0.13,1.7,0.13), Color("6b4a2c"))
	box(wp+Vector3(-0.35,2.32,0), Vector3(0.95,0.09,0.8), Color("9c4a34"), 0, 0.42, 0); box(wp+Vector3(0.35,2.32,0), Vector3(0.95,0.09,0.8), Color("9c4a34"), 0, -0.42, 0)
	# sacks + crates near houses/market
	for sp in [Vector3(-3.2,0,6.9), Vector3(2.6,0,0.6), Vector3(6.8,0,-2.4), Vector3(-7.8,0,3.6)]:
		blob(sp+Vector3(0,0.28,0), Vector3(0.34,0.3,0.34), Color("a67c4e")); blob(sp+Vector3(0.3,0.2,0.15), Vector3(0.26,0.22,0.26), Color("a67c4e"))
		box(sp+Vector3(-0.45,0.3,-0.2), Vector3(0.55,0.55,0.55), Color("a67c4e"), 0.3)
	# fence lines
	for fx in 6: box(Vector3(-9.5+float(fx)*0.85,0.4,8.6), Vector3(0.12,0.8,0.12), Color("7a5a36"))
	box(Vector3(-7.4,0.62,8.6), Vector3(4.6,0.1,0.1), Color("8a6742"))
	# gardens + door stone paths at houses, laundry lines, scattered barrels/crates
	var houses := [Vector3(3.2,0,-1.2), Vector3(-3.4,0,4.6), Vector3(7.2,0,-3.8), Vector3(-8.6,0,4.8), Vector3(9.6,0,1.8), Vector3(-6.5,0,-10.0), Vector3(12.5,0,11.0), Vector3(-5.5,0,10.8), Vector3(13.5,0,4.5)]
	for hp in houses:
		cyl(hp+Vector3(0,0.018,0), 2.7,2.7,0.015, Color(0.10,0.16,0.05,0.45), 14)
		var hang2: float = [0.0, PI/2.0, PI, -PI/2.0][absi(int(hp.x*7.0 + hp.z*13.0)) % 4]
		var hb := Basis.from_euler(Vector3(0, hang2, 0))
		for gx in 3:
			for gz in 2: blob(hp + hb * Vector3(2.1+float(gx)*0.42,0.22,0.9+float(gz)*0.42), Vector3(0.2,0.18,0.2), Color("5da038") if (gx+gz)%2==0 else Color("7fae4a"))
		cyl(hp + hb * Vector3(0,0.03,2.3), 0.5,0.5,0.03, Color("c9bda6"), 8); cyl(hp + hb * Vector3(0.25,0.03,3.3), 0.45,0.45,0.03, Color("c9bda6"), 8)
		cyl(hp + hb * Vector3(1.9,0.4,0.4), 0.3,0.34,0.8, Color("8a5f36"), 8)
	for lp2 in [Vector3(-1.8,0,7.9), Vector3(8.9,0,3.4)]:
		box(lp2+Vector3(-0.8,0.85,0), Vector3(0.09,1.7,0.09), Color("7a5a36")); box(lp2+Vector3(0.8,0.85,0), Vector3(0.09,1.7,0.09), Color("7a5a36"))
		box(lp2+Vector3(0,1.68,0), Vector3(1.7,0.05,0.05), Color("8a6742"))
		box(lp2+Vector3(-0.38,1.38,0), Vector3(0.5,0.55,0.04), Color("f2f0e6")); box(lp2+Vector3(0.35,1.34,0), Vector3(0.45,0.62,0.04), Color("c23b2a"))
	for si in 18:
		var sx3 := -12.0+fmod(float(si)*3.71,25.0); var sz3 := -9.0+fmod(float(si)*4.37,19.0)
		if si%2==0: cyl(Vector3(sx3,0.38,sz3), 0.3,0.34,0.75, Color("8a5f36"), 8)
		else: box(Vector3(sx3,0.24,sz3), Vector3(0.46,0.46,0.46), Color("a67c4e"), float(si)*0.4)
func _spawn_tufts() -> void:
	var verts := PackedVector3Array(); var norms := PackedVector3Array(); var uvs := PackedVector2Array()
	for rot in [0.0, PI/2.0]:
		var bx := Vector3(cos(rot),0,-sin(rot)); var base := verts.size()
		var cs := [Vector3(-0.24,0,0), Vector3(0.24,0,0), Vector3(0.17,0.52,0), Vector3(-0.17,0.52,0)]
		for cv in cs: verts.append(Vector3(cv.x*bx.x, cv.y, cv.x*bx.z))
		var nn := Vector3(bx.z,0,bx.x)
		for j in 4: norms.append(nn); uvs.append(Vector2(0.5,0.5))
		verts.append_array([]) # noop keep arrays aligned
	var idx := PackedInt32Array([0,1,2, 0,2,3, 4,5,6, 4,6,7])
	var arrays := []; arrays.resize(Mesh.ARRAY_MAX); arrays[Mesh.ARRAY_VERTEX]=verts; arrays[Mesh.ARRAY_NORMAL]=norms; arrays[Mesh.ARRAY_TEX_UV]=uvs; arrays[Mesh.ARRAY_INDEX]=idx
	var tm := ArrayMesh.new(); tm.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.use_colors = true; mm.mesh = tm; mm.instance_count = 1000
	var rng := RandomNumberGenerator.new(); rng.seed = 99
	for i in 1000:
		var gx := rng.randf_range(-17.0, 20.0); var gz := rng.randf_range(-14.0, 13.0)
		var ts9 := rng.randf_range(0.6,1.05); var xf := Transform3D(Basis.from_euler(Vector3(0, rng.randf()*PI, 0)).scaled(Vector3(ts9, ts9 * rng.randf_range(0.55,1.35), ts9)), Vector3(gx, _h(gx,gz)+0.02, gz))
		mm.set_instance_transform(i, xf); mm.set_instance_color(i, Color("2c5e17").lerp(Color("5b963a"), rng.randf()))
	var mmi := MultiMeshInstance3D.new(); mmi.multimesh = mm; var mt := StandardMaterial3D.new(); mt.albedo_color = Color(1,1,1); mt.vertex_color_use_as_albedo = true; mt.cull_mode = BaseMaterial3D.CULL_DISABLED; mt.roughness = 1.0; mmi.material_override = mt; mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(mmi)
	# flowers/stones now painted into terrain texture (R27), no dot instances
	tri_total += 1000 * 4
func _mini(mp: Vector3, tc: Color) -> void:
	box(mp+Vector3(-0.09,0.22,0), Vector3(0.13,0.44,0.15), Color("4a3421")); box(mp+Vector3(0.09,0.22,0), Vector3(0.13,0.44,0.15), Color("4a3421"))
	box(mp+Vector3(0,0.62,0), Vector3(0.42,0.42,0.26), tc)
	blob(mp+Vector3(0,1.02,0), Vector3(0.17,0.18,0.17), Color("e8b88a"))
	cyl(mp+Vector3(0,1.16,0), 0.24,0.26,0.07, Color("c9a86a"), 8)
	box(mp+Vector3(0.30,0.66,0.08), Vector3(0.08,0.52,0.08), Color("6b4a2c"), 0, 0.5, 0)
func _build_castle(p: Vector3, stone: Color, roof: Color) -> void:
	add_mesh(noised_box(4.7,2.4,3.6,0.07,4.2), Transform3D(Basis.IDENTITY, p+Vector3(0,1.2,0)), stone, "stone"); tri_total += 108
	for cy in [0.55, 1.05, 1.55]: box(p+Vector3(0,cy,1.82), Vector3(4.6,0.07,0.05), stone.darkened(0.12))
	add_mesh(noised_box(1.9,2.7,1.9,0.06,7.9), Transform3D(Basis.IDENTITY, p+Vector3(0,2.35,0)), stone, "stone"); tri_total += 108
	# stepped side wing + deformed prism roof over rear keep: uneven central roofline
	box(p+Vector3(2.95,0.85,0.55), Vector3(1.35,1.7,2.3), stone, 0,0,0, "stone")
	cyl(p+Vector3(2.95,2.15,0.55), 0.98,0.08,0.9, roof, 9, "roofp")
	roof2(p+Vector3(-0.6,2.38,-0.85), 3.6, 1.7, 0.95, 0.18, roof)
	cyl(p+Vector3(0,4.6,0), 1.05,0.05,1.9, roof, 10, "roofp")
	var ths := [3.3, 3.75, 3.05, 3.5]
	for oi2 in 4:
		var off: Vector2 = [Vector2(-1.85,-1.45),Vector2(1.85,-1.45),Vector2(-1.85,1.45),Vector2(1.85,1.45)][oi2]
		cyl(p+Vector3(off.x,ths[oi2]/2.0,off.y), 0.58,0.45,ths[oi2], stone, 8, "stone")
		cyl(p+Vector3(off.x,3.95,off.y), 0.72,0.02,1.7, roof, 10, "roofp")
		cyl(p+Vector3(off.x,3.25,off.y), 0.88,0.72,0.14, roof.darkened(0.22), 10); cyl(p+Vector3(off.x,3.62,off.y), 0.62,0.46,0.14, roof.darkened(0.22), 10)
		for ts in 3: box(p+Vector3(off.x+0.63,1.0+float(ts)*0.8,off.y), Vector3(0.1,0.65,0.34), stone.darkened(0.12))
	var mhs := [0.35,0.52,0.27,0.46,0.30,0.49]
	for mi in 6: box(p+Vector3([-1.9,-1.15,-0.4,0.4,1.15,1.9][mi],2.02+mhs[mi]/2.0,1.82), Vector3(0.42,mhs[mi],0.18), stone)
	for bx in [-0.9,-0.45,0.0,0.45,0.9]: box(p+Vector3(bx,3.42,1.12), Vector3(0.3,0.3,0.16), stone.darkened(0.12))
	for si2 in 6: box(p+Vector3(-1.8+fmod(float(si2)*0.73,3.6), 0.45+fmod(float(si2)*0.47,1.4), 1.84), Vector3(0.5,0.28,0.06), stone.darkened(0.12) if si2%2==0 else stone.lightened(0.1))
	for wx in [-1.4,1.4]: box(p+Vector3(wx,1.25,1.83), Vector3(0.34,0.55,0.08), Color("3a2e22"))
	box(p+Vector3(0,0.18,1.84), Vector3(4.7,0.36,0.12), Color("8a867e"))
	for ccx2 in [-2.32, 2.32]:
		for ccz2 in [-1.78, 1.78]: cyl(p+Vector3(ccx2, 1.2, ccz2), 0.20, 0.20, 2.4, stone, 8, "stone")
	# modelled stonework relief: extruded blocks, 2 tints (front + right faces)
	for ry2 in 4:
		for cx2 in 7:
			if (cx2 + ry2) % 3 == 0: continue
			box(p+Vector3(-1.86+float(cx2)*0.62, 0.48+float(ry2)*0.42, 1.83), Vector3(0.5,0.3,0.07), stone.darkened(0.12) if (cx2*ry2)%2==0 else stone.lightened(0.07), 0,0,0, "stone")
	for ry3 in 3:
		for cz3 in 5:
			if (cz3 + ry3) % 2 == 0: continue
			box(p+Vector3(2.36, 0.55+float(ry3)*0.5, -1.2+float(cz3)*0.6), Vector3(0.07,0.34,0.46), stone.darkened(0.12), 0,0,0, "stone")
	# battlements along side top edges + centre tower roof ring
	for bz2 in [-1.2,-0.4,0.4,1.2]:
		box(p+Vector3(2.32,2.52,bz2), Vector3(0.16,0.3,0.34), stone); box(p+Vector3(-2.32,2.52,bz2), Vector3(0.16,0.3,0.34), stone)
	cyl(p+Vector3(0,3.62,0), 1.0,0.86,0.15, roof.darkened(0.22), 10)
	for sp3 in [Vector2(-1.85,-1.45), Vector2(1.85,1.45)]:
		cyl(p+Vector3(sp3.x,5.85,sp3.y), 0.10,0.13,0.8, stone, 6, "stone"); cyl(p+Vector3(sp3.x,6.45,sp3.y), 0.22,0.02,0.5, roof, 7, "roofp")
	cyl(p+Vector3(1.7,3.3,-1.0), 0.42,0.46,1.6, stone, 8, "stone"); cyl(p+Vector3(1.7,4.45,-1.0), 0.55,0.02,0.8, roof, 8, "roofp")
	box(p+Vector3(-1.6,1.7,2.08), Vector3(0.55,1.15,0.07), Color("c22e22")); box(p+Vector3(1.6,1.7,2.08), Vector3(0.55,1.15,0.07), Color("c22e22"))
	for bt in [Vector2(-2.55,-1.95),Vector2(2.55,-1.95),Vector2(-2.55,1.95),Vector2(2.55,1.95)]: box(p+Vector3(bt.x,0.55,bt.y), Vector3(0.55,1.1,0.55), stone.darkened(0.14), 0.4, 0, 0, "stone")
	for wf in [Vector2(-1.9,1.35),Vector2(1.9,1.35),Vector2(0,2.6)]:
		box(p+Vector3(wf.x,wf.y,2.07), Vector3(0.52,0.68,0.08), Color("e8c87a")); box(p+Vector3(wf.x,wf.y,2.11), Vector3(0.36,0.5,0.05), Color("3a2c1c"))
	box(p+Vector3(0,0.7,2.08), Vector3(0.95,1.4,0.15), Color("4a3421"))
	var gm := CylinderMesh.new(); gm.bottom_radius=0.48; gm.top_radius=0.48; gm.height=0.16; gm.radial_segments=10
	add_mesh(gm, Transform3D(Basis.from_euler(Vector3(PI/2.0,0,0)), p+Vector3(0,1.42,2.09)), Color("4a3421")); tri_total += 40
	# gatehouse protrusion + annex tower (silhouette complexity)
	box(p+Vector3(0,0.85,2.45), Vector3(1.7,1.7,0.85), stone, 0,0,0, "stone")
	cyl(p+Vector3(0,2.15,2.45), 1.15,0.35,0.85, roof, 8, "roofp")
	cyl(p+Vector3(-3.35,1.7,0.3), 0.82,0.82,3.4, stone, 8, "stone")
	cyl(p+Vector3(-3.35,4.15,0.3), 1.05,0.03,1.35, roof, 9, "roofp")
	for bx2 in [-1.2,-0.6,0.0,0.6,1.2]: box(p+Vector3(bx2,2.42,-1.82), Vector3(0.34,0.32,0.16), stone.darkened(0.1))
	box(p+Vector3(0.0,3.9,0), Vector3(0.08,1.2,0.08), Color("6b4423")); box(p+Vector3(0.45,4.3,0), Vector3(0.8,0.45,0.05), Color("d43a2a"))
func noised_box(w: float, h: float, d: float, amt: float, seedv: float) -> ArrayMesh:
	var bm := BoxMesh.new(); bm.size = Vector3(w,h,d)
	var arrays: Array = bm.get_mesh_arrays(); var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]; var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]; var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	if idx.size() == 0:
		for i in range(0, verts.size()-2, 3): idx.append_array([i, i+1, i+2])
	var disp := {}
	var leanx := sin(seedv*1.31) * 0.55; var leanz := cos(seedv*0.93) * 0.30
	var topofs := [-0.14, 0.10, 0.17, -0.06]
	for vi3 in verts.size():
		var v1 := verts[vi3]; var key := str(v1)
		if not disp.has(key):
			var t01 := clampf((v1.y + h*0.5) / h, 0.0, 1.0)
			var nv := v1
			nv.x += leanx * t01 * t01 * h * 0.42; nv.z += leanz * t01 * t01 * h * 0.32
			nv.x *= 1.0 - 0.19 * t01; nv.z *= 1.0 - 0.09 * t01
			nv += v1.normalized() * sin(t01 * PI) * amt
			if t01 > 0.98: nv.y += topofs[(1 if v1.x > 0.0 else 0) + (2 if v1.z > 0.0 else 0)] * (1.05 + 0.45*sin(seedv))
			disp[key] = nv
		verts[vi3] = disp[key]
	for f in range(0, idx.size(), 3):
		var a: Vector3 = verts[idx[f]]; var b: Vector3 = verts[idx[f+1]]; var c2: Vector3 = verts[idx[f+2]]
		var n := (b-a).cross(c2-a).normalized()
		for j in 3: st.set_normal(n); st.set_uv(uvs[idx[f+j]]); st.add_vertex(verts[idx[f+j]])
	return st.commit()
func _build_house(p: Vector3, roof: Color, stone: Color) -> void:
	var vi := absi(int(p.x*5.0 + p.z*3.0)) % 3
	var wf: float = [1.0, 0.84, 1.18][vi]
	var wh: float = 2.45 if vi == 2 else 1.7
	var cy := 0.15 + wh/2.0; var top := 0.15 + wh
	var lean := 1.0 if vi == 1 else -1.0
	var wj := sin(p.x*3.1 + p.z*1.7) * 0.13
	wf *= 0.84; wh *= 0.94
	var hang: float = [0.0, PI/2.0, PI, -PI/2.0][absi(int(p.x*7.0 + p.z*13.0)) % 4]
	house_xf = Transform3D(Basis.from_euler(Vector3(0, hang, 0)), p); house_mode = true; roof_tilt = sin(float(vi)*2.1 + p.x) * 0.035
	box(Vector3(0,0.15,0), Vector3(2.5*wf,0.3,2.0), Color("9a968c"))
	if vi == 1:
		var wm := CylinderMesh.new(); wm.bottom_radius = 1.0; wm.top_radius = 0.90; wm.height = wh; wm.radial_segments = 4; wm.rings = 1
		add_mesh(wm, house_xf * Transform3D(Basis(Vector3(1,0,0), Vector3(0.22,1,0), Vector3(0,0,1)) * Basis.from_euler(Vector3(0,PI/4.0,0)).scaled(Vector3(1.15,1,1.34)), Vector3(0,cy,0)), [Color("e8d9b8"), Color("f0e2c4"), Color("e0cfa8")][vi], "plaster"); tri_total += 32
	else:
		add_mesh(noised_box(2.3*wf, wh, 1.9, 0.11, float(vi+1)*3.7), house_xf * Transform3D(Basis.IDENTITY, Vector3(0,cy,0)), [Color("e8d9b8"), Color("f0e2c4"), Color("e0cfa8")][vi], "plaster"); tri_total += 108
	for sx in [-1.09, 1.09]:
		box(Vector3(sx*wf,cy,0.96), Vector3(0.25,wh+0.05,0.11), Color("54381f"), 0,0,0, "timber")
		box(Vector3(sx*wf,cy,-0.96), Vector3(0.25,wh+0.05,0.11), Color("54381f"), 0,0,0, "timber")
	box(Vector3(0,top-0.05,0.97), Vector3(2.32*wf,0.21,0.08), Color("54381f"), 0,0,0, "timber"); box(Vector3(0,0.24,0.97), Vector3(2.32*wf,0.21,0.08), Color("54381f"), 0,0,0, "timber")
	box(Vector3(1.16*wf,cy,0), Vector3(0.07,wh+0.05,0.17), Color("54381f"), 0,0,0, "timber"); box(Vector3(-1.16*wf,cy,0), Vector3(0.07,wh+0.05,0.17), Color("54381f"), 0,0,0, "timber")
	box(Vector3(0,0.82,0.99), Vector3(0.78,1.42,0.06), Color("8a6742"))
	box(Vector3(wj*0.7,0.80,1.01), Vector3(0.54,1.28,0.06), Color("6e4a2c"))
	box(Vector3(-0.68*wf+wj,1.22+wj*0.4,0.98), Vector3(0.52,0.60,0.06), Color("ffd98a")); box(Vector3(0.68*wf+wj,1.22-wj*0.3,0.98), Vector3(0.52,0.60,0.06), Color("ffd98a"))
	box(Vector3(-1.02*wf,1.22,0.97), Vector3(0.15,0.60,0.05), Color("5d7a34")); box(Vector3(-0.34*wf,1.22,0.97), Vector3(0.15,0.60,0.05), Color("5d7a34")); box(Vector3(0.34*wf,1.22,0.97), Vector3(0.15,0.60,0.05), Color("5d7a34")); box(Vector3(1.02*wf,1.22,0.97), Vector3(0.15,0.60,0.05), Color("5d7a34"))
	if vi == 2:
		box(Vector3(-0.68*wf,2.05,0.98), Vector3(0.48,0.54,0.06), Color("ffd98a")); box(Vector3(0.68*wf,2.05,0.98), Vector3(0.48,0.54,0.06), Color("ffd98a"))
	box(Vector3(-0.68*wf,0.90,1.0), Vector3(0.56,0.12,0.10), Color("5d7a34"))
	for fx3 in 3: blob(Vector3(-0.82*wf+float(fx3)*0.14,0.99,1.02), Vector3(0.07,0.06,0.07), Color("e2543e") if fx3%2==0 else Color("f2f0e6"))
	box(Vector3(1.18*wf,1.22,0.25), Vector3(0.06,0.5,0.44), Color("ffd98a"))
	# porch
	box(Vector3(-0.55,0.75,1.32), Vector3(0.12,1.5,0.12), Color("54381f"), 0,0,0, "timber"); box(Vector3(0.55,0.75,1.32), Vector3(0.12,1.5,0.12), Color("54381f"), 0,0,0, "timber")
	box(Vector3(0,1.58,1.22), Vector3(1.5,0.09,0.95), Color("8a6742"), 0, 0, 0.22)
	# lean-to (side alternates by variant; vi==1 also reads L-shaped)
	box(Vector3(lean*(1.16*wf+0.42),0.55,0), Vector3(0.95,1.1,1.6), Color("e0cfa8"), 0,0,0, "plaster")
	box(Vector3(lean*(1.16*wf+0.42),1.2,0), Vector3(1.15,0.09,1.85), Color("9c4a34"), 0, lean*0.20, 0)
	var pitch2: float = [1.32, 1.10, 1.55][vi]
	roof2(Vector3(0,top,0), 3.35*wf, 2.8, pitch2, 0.18, roof)
	box(Vector3(0,top+pitch2+0.03,-0.7), Vector3(0.15,0.1,1.1), roof.darkened(0.15)); box(Vector3(0,top+pitch2+0.07,0.45), Vector3(0.15,0.1,1.2), roof.darkened(0.15))
	box(Vector3(0,top+pitch2+0.13,0), Vector3(0.09,0.05,2.62), roof.lightened(0.15))
	# modelled shingle rows: thin offset slabs following both slopes
	var hw2 := 1.5*wf; var sang := atan2(pitch2, hw2)
	for side2 in [-1.0, 1.0]:
		var nrm2 := Vector3(side2*pitch2, hw2, 0).normalized()
		for rw in 6:
			var tt := (float(rw)+0.5)/6.0
			var sp2 := Vector3(side2*hw2*(1.0-tt), top+pitch2*tt, 0)
			box(sp2 + nrm2*0.012, Vector3(0.52,0.045,2.80), roof.darkened(0.46), 0, -side2*sang, 0)
			for sg2 in 3:
				box(sp2 + nrm2*0.048 + Vector3(0,0,-0.93+float(sg2)*0.93), Vector3(0.46,0.06,0.86), roof.darkened(0.22) if (rw+sg2)%2==0 else roof.lightened(0.15), 0, -side2*sang, 0)
	for ccx in [-1.15, 1.15]:
		for ccz in [-0.95, 0.95]: cyl(Vector3(ccx*wf, cy, ccz), 0.13, 0.13, wh, Color("e8d9b8"), 8, "plaster")
	box(Vector3(0,0.44,1.02), Vector3(2.42*wf,0.28,0.16), stone, 0, 0, 0.30, "stone")
	box(Vector3(0,top-0.10,0), Vector3(2.36*wf,0.13,1.96), Color("f0e2c4"), 0,0,0, "plaster")
	box(Vector3(-0.62*wf,cy,0.99), Vector3(0.72,wh*0.62,0.045), Color("e0cfa8"), 0,0,0, "plaster"); box(Vector3(0.62*wf,cy,0.99), Vector3(0.72,wh*0.62,0.045), Color("e0cfa8"), 0,0,0, "plaster")
	# stone foundation skirt
	box(Vector3(0,0.40,0), Vector3(2.40*wf,0.58,2.0), stone, 0,0,0, "stone")
	box(Vector3(-0.62*wf,top+0.67,0.68), Vector3(0.52,0.52,0.42), Color("e8d9b8"), 0,0,0, "plaster")
	box(Vector3(-0.62*wf,top+0.77,0.90), Vector3(0.34,0.3,0.05), Color("ffd98a"))
	box(Vector3(-0.62*wf,top+1.01,0.68), Vector3(0.68,0.1,0.56), roof)
	box(Vector3(0.8,top+0.84,-0.3), Vector3(0.37,1.18,0.37), stone, 0,0,0, "stone")
	if vi != 1: box(Vector3(-0.78,top+0.6,-0.25), Vector3(0.34,0.75,0.34), stone)
	blob(Vector3(0.8,top+1.5,-0.3), Vector3(0.22,0.18,0.22), Color(1,1,1,0.35)); blob(Vector3(0.95,top+1.75,-0.3), Vector3(0.32,0.24,0.32), Color(1,1,1,0.22))
	# massing variety: genuinely different silhouettes per variant
	if vi == 0:
		# long low barn extension behind (long footprint reads from iso)
		box(Vector3(0,0.58,-1.55), Vector3(2.5,1.15,1.05), [Color("e8d9b8"), Color("f0e2c4"), Color("e0cfa8")][vi], 0,0,0, "plaster")
		box(Vector3(0,1.28,-1.55), Vector3(2.7,0.1,1.3), Color("9c4a34"), 0, 0, 0.16)
	elif vi == 1:
		# deep side wing: footprint reads L-shaped in plan
		box(Vector3(lean*(1.16*wf+0.42),1.62,0), Vector3(1.0,1.05,2.35), [Color("e8d9b8"), Color("f0e2c4"), Color("e0cfa8")][vi], 0,0,0, "plaster")
		box(Vector3(lean*(1.16*wf+0.42),2.22,0), Vector3(1.15,0.1,2.5), roof.darkened(0.12))
	else:
		# tall tower wing with cone
		box(Vector3(lean*(1.16*wf+0.40), (wh+1.1)/2.0, -0.25), Vector3(0.95,wh+1.1,0.95), [Color("e8d9b8"), Color("f0e2c4"), Color("e0cfa8")][vi], 0,0,0, "plaster")
		cyl(Vector3(lean*(1.16*wf+0.40), wh+1.55, -0.25), 0.72,0.03,0.95, roof, 8, "roofp")
	house_mode = false
func _build_roundhouse(p: Vector3, roof: Color) -> void:
	cyl(p+Vector3(0,0.3,0), 1.28,1.34,0.6, Color("9a968c"), 12, "stone")
	cyl(p+Vector3(0,1.45,0), 1.18,1.10,1.75, Color("e8d9b8"), 12, "plaster")
	for pa in 6:
		var aa := float(pa) * TAU / 6.0
		box(p+Vector3(sin(aa)*1.16,1.45,cos(aa)*1.16), Vector3(0.15,1.8,0.15), Color("54381f"), aa, 0, 0, "timber")
	box(p+Vector3(0,2.42,0), Vector3(2.5,0.16,2.5), Color("54381f"))
	var cone1 := CylinderMesh.new(); cone1.bottom_radius=1.62; cone1.top_radius=0.12; cone1.height=1.55; cone1.radial_segments=12
	add_mesh(cone1, Transform3D(Basis.from_euler(Vector3(sin(p.x*1.3)*0.07,0,cos(p.z*1.7)*0.07)), p+Vector3(sin(p.z)*0.08,3.25,cos(p.x)*0.06)), roof, "roofp"); tri_total += 96
	box(p+Vector3(0,0.95,1.2), Vector3(0.62,1.5,0.1), Color("6e4a2c"))
	box(p+Vector3(0.85,1.6,0.95), Vector3(0.42,0.5,0.08), Color("ffd98a"))
	cyl(p+Vector3(0.55,3.3,-0.4), 0.2,0.24,0.9, Color("9a968c"), 8, "stone")
func _build_roundbarn(p: Vector3, roof: Color) -> void:
	cyl(p+Vector3(0,0.25,0), 1.62,1.68,0.5, Color("9a968c"), 14, "stone")
	cyl(p+Vector3(0,1.25,0), 1.52,1.44,1.55, Color("a8875e"), 14, "timber")
	box(p+Vector3(0,2.12,0), Vector3(3.2,0.15,3.2), Color("54381f"))
	var cone2 := CylinderMesh.new(); cone2.bottom_radius=1.78; cone2.top_radius=0.14; cone2.height=1.55; cone2.radial_segments=14
	add_mesh(cone2, Transform3D(Basis.from_euler(Vector3(cos(p.x)*0.05,0,sin(p.z*1.4)*0.05)), p+Vector3(cos(p.z)*0.07,2.95,sin(p.x)*0.05)), roof, "roofp"); tri_total += 112
	box(p+Vector3(0,0.95,1.5), Vector3(0.95,1.55,0.1), Color("54381f"))
	box(p+Vector3(0.75,1.55,1.42), Vector3(0.4,0.42,0.08), Color("ffd98a"))
	cyl(p+Vector3(-0.8,2.6,-0.5), 0.18,0.22,0.8, Color("9a968c"), 8, "stone")
func _build_octstore(p: Vector3, stone: Color) -> void:
	cyl(p+Vector3(0,0.3,0), 1.45,1.5,0.6, stone, 8, "stone")
	cyl(p+Vector3(0,1.55,0), 1.32,1.26,1.95, stone, 8, "stone")
	var cone3 := CylinderMesh.new(); cone3.bottom_radius=1.58; cone3.top_radius=0.95; cone3.height=0.75; cone3.radial_segments=8
	add_mesh(cone3, Transform3D(Basis.from_euler(Vector3(sin(p.x*0.9)*0.06,0,cos(p.z)*0.06)), p+Vector3(0,2.72,0)), Color("9c4a34"), "roofp"); tri_total += 64
	cyl(p+Vector3(0,3.25,0), 0.4,0.46,0.5, stone, 8, "stone")
	box(p+Vector3(0,1.0,1.34), Vector3(0.8,1.7,0.1), Color("54381f"))
	box(p+Vector3(1.75,0.35,0.6), Vector3(0.6,0.6,0.6), Color("a67c4e"), 0.4); cyl(p+Vector3(1.7,0.42,-0.35), 0.3,0.34,0.85, Color("8a5f36"), 8)
func _build_aframe(p: Vector3, roof: Color, stone: Color) -> void:
	box(p+Vector3(0,0.15,0), Vector3(2.6,0.3,2.2), stone, 0,0,0, "stone")
	box(p+Vector3(0,0.55,0), Vector3(2.3,0.85,1.9), Color("e8d9b8"), 0,0,0, "plaster")
	roof2(p+Vector3(0,0.92,0), 3.3, 2.6, 2.15, 0.18, roof)
	box(p+Vector3(0,0.75,1.02), Vector3(0.66,1.25,0.08), Color("6e4a2c"))
	box(p+Vector3(0.62,2.9,-0.3), Vector3(0.36,0.9,0.36), stone, 0,0,0, "stone")
func _build_hut(p: Vector3, stone: Color) -> void:
	add_mesh(noised_box(2.0,1.4,1.8,0.09,p.x*1.3+p.z), Transform3D(Basis.IDENTITY, p+Vector3(0,0.7,0)), Color("cbb489")); tri_total += 108
	box(p+Vector3(0,0.65,0.92), Vector3(0.65,1.1,0.08), Color("3d2b18"))
	var cone4 := CylinderMesh.new(); cone4.bottom_radius=1.75; cone4.top_radius=0.25; cone4.height=1.5; cone4.radial_segments=10
	add_mesh(cone4, Transform3D(Basis.from_euler(Vector3(sin(p.x)*0.06,0,cos(p.z*1.2)*0.06)), p+Vector3(sin(p.z)*0.06,2.05,0)), Color("b98a35"), "thatch"); tri_total += 80
	for ri in 3: cyl(p+Vector3(0,1.55+float(ri)*0.38,0), 1.55-float(ri)*0.38, 1.45-float(ri)*0.38, 0.12, Color("8f6a2a"), 10)
	cyl(p+Vector3(0,1.38,0), 1.82,1.88,0.2, Color("7d5c26"), 10)
	for bi2 in 8:
		var ba := float(bi2) * PI / 4.0
		box(p+Vector3(sin(ba)*1.58, 1.78, cos(ba)*1.58), Vector3(0.22,0.95,0.12), Color("a87c34") if bi2%2==0 else Color("c49a48"), ba, 0, 0)
	cyl(p+Vector3(0,2.92,0), 0.3,0.36,0.22, Color("8f6a2a"), 8)
func _build_tree(p: Vector3, a: Color, b: Color) -> void:
	var tsc := (0.85 + 0.45 * (0.5 + 0.5*sin(p.x*2.7 + p.z*1.9))) * 0.80
	var vi := absi(int(p.x*3.0 + p.z*7.0)) % 7
	if vi == 5: a = Color("c07a2e"); b = Color("e0a44a")
	vi = vi % 3
	if vi == 1: a = Color("4c8a38"); b = Color("82b85e")
	elif vi == 2: a = Color("558f3d"); b = Color("93c46e")
	if Vector2(p.x,p.z).length() > 11.0: p.y = _h(p.x, p.z) - 0.1
	cyl(p+Vector3(0,0.035,0), 1.7,1.7,0.02, Color(0.09,0.15,0.04,0.32), 12)
	cyl(p+Vector3(0,0.9*tsc,0), 0.22,0.32,1.8*tsc, Color("6b4423"), 7)
	for bang in [0.7, -0.65]:
		var bm := CylinderMesh.new(); bm.bottom_radius=0.07; bm.top_radius=0.13; bm.height=1.05; bm.radial_segments=6
		add_mesh(bm, Transform3D(Basis.from_euler(Vector3(0,0,bang)), p+Vector3(bang*0.45,1.55,0)), Color("6b4423")); tri_total += 24
	if vi == 1:
		for pi in 4:
			add_canopy(Transform3D(Basis.from_euler(Vector3(0,float(pi)*0.8,0)).scaled(Vector3(0.85,1.05,0.85)), p+Vector3(0,1.9+float(pi)*0.62,0)), a if pi%2==0 else b)
		return
	for ci in 14:
		var off: Vector3 = [Vector3(0,2.6,0), Vector3(0.85,2.05,0.3), Vector3(-0.85,2.15,-0.25), Vector3(0.1,3.25,-0.1), Vector3(-0.2,1.9,0.7), Vector3(1.15,2.7,-0.5), Vector3(-1.1,2.8,0.45), Vector3(1.3,2.2,0.6), Vector3(-1.3,2.3,-0.6), Vector3(0.5,3.6,0.5), Vector3(1.5,2.5,0.1), Vector3(-1.5,2.6,-0.2), Vector3(0.3,2.0,1.05), Vector3(-0.4,3.05,0.95)][ci]
		var sc: float = [1.05,0.78,0.74,0.78,0.66,0.55,0.53,0.45,0.43,0.46,0.40,0.38,0.36,0.34][ci] * (0.88 + 0.24 * (0.5 + 0.5*sin(float(ci)*2.3)))
		var cc2: Color = a.lerp(b, clampf(float(ci)/7.0, 0.0, 1.0))
		if ci % 3 == 2: cc2 = cc2.lightened(0.13)
		add_canopy(Transform3D(Basis.from_euler(Vector3(0, float(ci)*0.62, 0)).scaled(Vector3(sc*1.15*tsc, sc*0.95*tsc, sc*1.15*tsc)), p+off*Vector3(1,tsc,1)), cc2)
func _build_carrier(p: Vector3) -> void:
	box(p+Vector3(-0.16,0.35,0), Vector3(0.2,0.7,0.22), Color("4a3421")); box(p+Vector3(0.16,0.35,0), Vector3(0.2,0.7,0.22), Color("4a3421"))
	box(p+Vector3(0,0.95,0), Vector3(0.62,0.65,0.4), Color("2f62b8"))
	blob(p+Vector3(0,1.55,0), Vector3(0.28,0.3,0.28), Color("e8b88a"))
	var logm := CylinderMesh.new(); logm.bottom_radius=0.11; logm.top_radius=0.11; logm.height=1.05; logm.radial_segments=8; tri_total+=32
	add_mesh(logm, Transform3D(Basis.from_euler(Vector3(0,0,PI/2.0)), p+Vector3(0,1.62,0)), Color("8a5f36"))
	box(p+Vector3(0.35,1.25,0), Vector3(0.55,0.16,0.16), Color("e8b88a"))
