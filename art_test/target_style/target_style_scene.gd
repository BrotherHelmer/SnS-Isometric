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
	# R69: vignette overlay removed (soft/blurred edges - Black #2)
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
func _is_roof_tone(c: Color) -> bool: # R123: exact roof-derived relief tones (roof roots and their darkened/lightened variants only)
	for base in [Color("a8664e"), Color("a05a44")]:
		if c == base: return true
		for f in [0.12, 0.15, 0.22, 0.28, 0.35, 0.46]:
			if c == base.darkened(f): return true
		for f2 in [0.15, 0.30]:
			if c == base.lightened(f2): return true
	var dk: Color = Color("a8664e").darkened(0.46); var dg := (dk.r + dk.g + dk.b) / 3.0
	if c == dk.lerp(Color(dg, dg, dg), 0.35): return true
	return false
func mat_col(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = c; m.roughness = 1.0; m.albedo_texture = load(PT + "grain_painted.png"); m.uv1_scale = Vector3(1.5,1.5,1); return m
func mat_for(key: String, c: Color) -> Material:
	var tx0: String = surf_tex.get(key, "")
	if tx0 == "stone": # R90 per-face warmth at material root (world-normal warm/cool, no overlay slabs)
		var sm := ShaderMaterial.new(); var sh := Shader.new()
		sh.code = "shader_type spatial;\nuniform sampler2D tex : source_color, repeat_enable, filter_linear_mipmap;\nuniform vec4 tint : source_color;\nvarying vec3 wn;\nvoid vertex() { wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz); }\nvoid fragment() { float lf = clamp(dot(normalize(wn), normalize(vec3(-0.45, 0.75, 0.50))) * 0.5 + 0.5, 0.0, 1.0); vec3 warm = mix(vec3(0.90, 0.96, 1.05), vec3(1.10, 1.01, 0.86), lf); ALBEDO = texture(tex, UV * 0.55).rgb * tint.rgb * warm; ROUGHNESS = 0.95; }"
		sm.shader = sh; sm.set_shader_parameter("tex", load(TEX["stone"])); sm.set_shader_parameter("tint", Color(1.06,0.99,0.88).lerp(c, 0.45))
		return sm
	var tx: String = surf_tex.get(key, "")
	if tx == "roofp": # R123 face-aware roof shader (R90 spirit): lit faces = R122 calibration, shaded faces desaturated+deepened
		var rm := ShaderMaterial.new(); var rsh := Shader.new()
		rsh.code = "shader_type spatial;\nuniform sampler2D tex : source_color, repeat_enable, filter_linear_mipmap;\nuniform vec4 tint : source_color;\nvarying vec3 wn;\nvoid vertex() { wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz); }\nvoid fragment() { vec3 alb = texture(tex, UV).rgb * tint.rgb; float lf = clamp(dot(normalize(wn), normalize(vec3(-0.45, 0.75, 0.50))) * 0.5 + 0.5, 0.0, 1.0); float sh = 1.0 - smoothstep(0.50, 0.88, lf); float grey = dot(alb, vec3(0.333)); vec3 shaded = mix(alb, vec3(grey), 0.52) * vec3(0.55, 0.57, 0.63); ALBEDO = mix(alb, shaded, sh * 0.97); ROUGHNESS = 0.93; }"
		rm.shader = rsh; rm.set_shader_parameter("tex", load(TEX["roofp"])); rm.set_shader_parameter("tint", Color(0.93,0.84,0.75).lerp(c, 0.24))
		return rm
	if tx == "" and _is_roof_tone(c): # R123 face-aware shader on roof relief tones (grain base, same shading law)
		var gm := ShaderMaterial.new(); var gsh := Shader.new()
		gsh.code = "shader_type spatial;\nuniform sampler2D tex : source_color, repeat_enable, filter_linear_mipmap;\nuniform vec4 tint : source_color;\nvarying vec3 wn;\nvoid vertex() { wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz); }\nvoid fragment() { vec3 alb = texture(tex, UV).rgb * tint.rgb; float lf = clamp(dot(normalize(wn), normalize(vec3(-0.45, 0.75, 0.50))) * 0.5 + 0.5, 0.0, 1.0); float sh = 1.0 - smoothstep(0.50, 0.88, lf); float grey = dot(alb, vec3(0.333)); vec3 shaded = mix(alb, vec3(grey), 0.52) * vec3(0.55, 0.57, 0.63); ALBEDO = mix(alb, shaded, sh * 0.97); ROUGHNESS = 0.93; }"
		gm.shader = gsh; gm.set_shader_parameter("tex", load(PT + "grain_painted.png")); gm.set_shader_parameter("tint", c)
		return gm
	var m := mat_col(c)
	if tx != "" and TEX.has(tx):
		m.albedo_texture = load(TEX[tx]); m.uv1_scale = Vector3(3,3,1) if tx=="meadow" else (Vector3(0.55,0.55,1) if tx in ["stone","plaster"] else (Vector3(1,1,1) if tx in ["roofp","thatch","rock"] else Vector3(1.5,1.5,1))) # R77 larger face features; m.albedo_color = Color(0.88,0.87,0.85)
		if tx == "rock": m.albedo_color = Color(1.06,0.97,0.87).lerp(c, 0.50) # R73: warm rock, tint was being overridden grey
		if tx == "stone": m.albedo_color = Color(1.06,0.99,0.88).lerp(c, 0.45) # R89 warmer stone tint-through base
		if tx == "roofp": m.albedo_color = Color(0.93,0.84,0.75).lerp(c, 0.24) # R78 muted terracotta tint-through
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
func roof2(p: Vector3, w: float, d: float, h: float, thick: float, c: Color, v121 := 0.0) -> void:
	# DEFORMED prism: sagged ridge, uneven eaves/ridge ends, slight twist. v: 0 eave -> 1 ridge
	var hw := w/2.0
	var org := house_xf.origin if house_mode else p
	var seedv := org.x*1.71 + org.z*2.37
	var e1 := sin(seedv*1.7)*0.12; var e2 := cos(seedv*1.31)*0.12; var tw := sin(seedv*0.9)*0.10
	var ec0 := sin(seedv)*0.08; var ec1 := cos(seedv*2.1)*0.08; var ec2 := sin(seedv*1.2+2.0)*0.08; var ec3 := cos(seedv*0.7+1.0)*0.08
	var rng121 := RandomNumberGenerator.new(); rng121.seed = 12100 + absi(int(org.x*41.0 + org.z*67.0)) # R121 seeded roof-form variety
	var sag121 := 0.13
	if v121 > 0.0:
		sag121 = rng121.randf_range(0.06, 0.24); tw *= rng121.randf_range(0.7, 1.9)
		ec0 *= rng121.randf_range(0.8, 2.1); ec1 *= rng121.randf_range(0.8, 2.1); ec2 *= rng121.randf_range(0.8, 2.1); ec3 *= rng121.randf_range(0.8, 2.1)
	var A := Vector3(-hw,ec0,-d/2); var B := Vector3(-hw,ec3,d/2); var E := Vector3(hw,ec1,-d/2); var F := Vector3(hw,ec2,d/2)
	var C := Vector3(tw,h+e1,-d/2); var D := Vector3(-tw,h+e2,d/2); var M := Vector3(0,h+(e1+e2)*0.5-sag121,0)
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
	if v121 > 0.0: # R121 gable timber (king post + seeded brace) on the plaster gable ends
		for gz in [-d/2.0, d/2.0]:
			box(p+Vector3(tw*0.5, h*0.40, gz), Vector3(0.10, h*0.76, 0.08), Color("54381f"), 0, 0, 0, "timber")
			if rng121.randf() > 0.35: box(p+Vector3(tw*0.5, h*0.58, gz), Vector3(0.09, h*0.52, 0.07), Color("54381f"), 0, rng121.randf_range(0.45, 0.7) * (1.0 if gz > 0.0 else -1.0), 0, "timber")
	if v121 > 1.5: # R121 segmented ridge cap following the sag (aframes had none)
		for rz2 in [-0.30, 0.02, 0.32]:
			var t01: float = rz2 + 0.5
			var ry121: float = lerpf(h + e1, h + e2, t01) - sag121 * sin(PI * t01) * 0.7
			box(p+Vector3(tw*(t01-0.5), ry121 + 0.07, rz2*d), Vector3(0.17, 0.09, d*0.30), c.darkened(0.35))
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
	var hill := back * 14.0 * clampf(1.25 - absf(x - 19.5) / 15.0, 0.0, 1.0) * (0.80 + 0.40 * (0.5 + 0.5*sin(-z*1.05 + x*0.25))) # R70: mass shifted to NE corner
	var left := clampf(( -x - 14.0) / 16.0, 0.0, 1.0)
	var jag := mask * (0.22*sin(x*1.9+z*0.7) + 0.14*sin(x*3.7-z*2.3)) * clampf(back*2.0,0.0,1.0)
	var crag := back * (0.85*sin(x*4.1+z*2.7) + 0.55*sin(x*7.3-z*4.9) + 0.35*sin(x*12.0+z*9.0) + 0.22*sin(x*19.0-z*15.0)) * clampf(hill/4.0, 0.0, 1.0)
	var sd := Vector2(x-9.0, z+8.8).length(); var shoulder := clampf(1.0 - sd/3.6, 0.0, 1.0); shoulder = shoulder * shoulder
	var east := clampf((x - 20.0) / 4.5, 0.0, 1.0)
	var lobe := pow(east, 2.0) * clampf(1.0 - absf(z + 10.0) / 11.0, 0.0, 1.0) * 3.2 * (0.75 + 0.45 * (0.5 + 0.5*sin(-z*0.9 + x*0.3))) # R70: former frame-cutting wall demoted to NE foothill
	var ne := clampf((x - 10.5) / 9.5, 0.0, 1.0); var nf := clampf((-z - 6.0) / 10.0, 0.0, 1.0)
	var nemass := pow(ne, 2.0) * pow(nf, 1.8) * 13.5 * (0.80 + 0.40 * (0.5 + 0.5*sin(x*0.4 - z*0.3))) # R70: one corner slope, peak receding NE
	var rzm := clampf((hill + nemass) / 7.0, 0.0, 1.0) * clampf((x + 2.0) / 6.0, 0.0, 1.0) # R101 rock-zone only (fades at grass boundary/settlement/left green hills)
	var rdsp: float = 0.38*sin(x*2.9 + z*2.2) + 0.24*sin(x*5.7 - z*4.3) + 0.14*sin(x*7.3 + z*6.7) + 0.20*(abs(sin(x*1.7 - z*2.6)) - 0.5)
	rdsp = lerpf(rdsp, floor(rdsp*2.8)/2.8, 0.65) # stepped ledges dominate over smooth displacement
	return mask * roll + hill + lobe + nemass + left * left * 1.6 * mask + jag + crag * (1.0 - shoulder*0.85) + shoulder * 1.15 + rzm * rdsp * 1.15
var _canopy_sphere: ArrayMesh = null
func canopy_sphere() -> ArrayMesh:
	if _canopy_sphere != null: return _canopy_sphere
	var sm := SphereMesh.new(); sm.radial_segments = 13; sm.rings = 7; sm.radius = 1.0; sm.height = 2.0 # R98 denser canopy
	var arrays: Array = sm.get_mesh_arrays(); var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]; var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var disp2 := {}
	for dvi in verts.size():
		var dv := verts[dvi]; var dk := str(dv)
		if not disp2.has(dk):
			var dn := dv.normalized()
			var scp := sin(dn.x*16.0+dn.y*9.0) * sin(dn.y*14.0-dn.z*12.0) * sin(dn.z*18.0+dn.x*7.0)
			var ds := 1.0 + 0.34*sin(dn.x*5.1+dn.y*3.3) + 0.26*sin(dn.y*7.2+dn.z*4.4) + 0.19*sin(dn.z*9.0-dn.x*5.0) + 0.13*sin(dn.x*13.7-dn.y*11.3) + scp*0.17 # R99 scalloped lobes
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
		var vary: float = 0.84 + 0.12 * floor((0.5 + 0.5 * sin(seedv + float(f) * 2.39)) * 3.99) # R114 quantized cluster-cell tones (4 steps)
		var cc := Color(clampf(c.r*vary,0,1), clampf(c.g*vary,0,1), clampf(c.b*vary,0,1))
		if fn.y > 0.45: cc = cc.lightened(0.22)
		if fn.y < 0.1: cc = cc.darkened(0.16)
		var clus := sin(seedv*0.7 + float(f) * 1.37)
		if clus > 0.45: cc = cc.darkened(0.10)
		elif clus < -0.55: cc = cc.lightened(0.18)
		var sunf := clampf(fn.dot(Vector3(-0.45, 0.75, 0.50)) * 0.5 + 0.5, 0.0, 1.0) # R98 warm sunlit / cool shaded clusters
		cc = Color(clampf(cc.r*(0.90+0.28*sunf),0,1), clampf(cc.g*(0.95+0.12*sunf),0,1), clampf(cc.b*(1.06-0.26*sunf),0,1))
		cc = Color(clampf(cc.r*2.1,0.0,1.1), clampf(cc.g*2.0,0.0,1.1), clampf(cc.b*2.1,0.0,1.1)) # R69: undo texture*vertex double-green
		for j in 3:
			canopy_st.set_normal(fn); canopy_st.set_color(cc); canopy_st.set_uv(uvs[f+j]); canopy_st.add_vertex(tv[j]) # R114 flat cluster-cell normals (was smooth radial = lump)
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
	var size := 120.0; var steps := 230
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
			var gsf := 0.66 + 0.54 * gshade
			c = Color(c.r*gsf, c.g*gsf, c.b*gsf)
			if slope <= 0.30: # R97 mid-frame meadow: medium patch scale + worn tones, flat areas only
				var mp97 := 0.5 + 0.5*sin(v.x*0.83+0.7) * sin(v.y*0.71-2.2) * sin((v.x-v.y)*0.37+1.0)
				c = c.lerp(Color("69a83a"), mp97 * 0.30)
				if mp97 > 0.72: c = c.lerp(Color("b8a05e"), (mp97-0.72) * 0.85)
				var lift97 := clampf(1.0 - Vector2(v.x, v.y).length() / 13.0, 0.0, 1.0)
				c = c.lerp(c.lightened(0.20), lift97 * 0.45)
			if slope > 0.30: c = dirt.lerp(rock, clampf((slope-0.30)*1.3,0,1))
			if v.x > 18.0 and slope > 0.16:
				c = c.lerp(rock, clampf((slope-0.16)*1.6, 0.0, 0.85))
				var band2 := 0.5 + 0.5*sin(h*1.35 + v.x*0.32 - v.y*0.48)
				if band2 > 0.55: c = c.lerp(Color("bfb096"), (band2-0.55) * 0.5)
				else: c = c.darkened((0.55-band2) * 0.25)
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
			for feat in [Vector2(14.5,-11.5), Vector2(17.0,-10.2), Vector2(13.0,-11.8)]:
				var fd := Vector2(v.x-feat.x, v.y-feat.y).length()
				if fd < 4.4: c = c.lerp(dirt, (1.0-fd/4.4) * 0.50)
			var snowpatch := 0.5 + 0.5*sin(v.x*1.9+1.3) * sin(v.y*1.4-0.7)
			if h > 4.6 and v.y < -7.0 and slope <= 0.50: # R70: pale slab was snow lerp on low SE plateau tops
				var sf := clampf((snowpatch-0.34)*4.0, 0.0, 1.0) * clampf((h-3.4)*1.6, 0.0, 1.0)
				c = c.lerp(Color("eef1ea"), sf * 0.85)
			if v.x > 20.5 and h > 5.0: c = c.lerp(rock, 0.62)
			var sz120 := clampf((v.x - 7.0) / 9.0, 0.0, 1.0) * clampf((-v.y - 3.0) / 5.0, 0.0, 1.0) * clampf((h - 0.8) / 3.5, 0.0, 1.0) # R120 slope-only zone mask
			if sz120 > 0.01:
				var gully120 := 0.5 + 0.5 * sin(v.x*0.63 - v.y*0.91 + 1.4) * sin(v.x*0.21 + v.y*0.47 - 0.6)
				var expose120 := 0.5 + 0.5 * sin(v.x*0.43 + v.y*0.78 - 1.1) * sin(v.x*1.13 - v.y*0.57 + 2.0)
				if slope > 0.18: c = c.lerp(Color("8a6c42"), sz120 * clampf((slope - 0.18) * 1.25, 0.0, 0.80) * (0.35 + 0.65 * expose120)) # worn brown between grass and rock
				if slope <= 0.42 and gully120 > 0.58: c = c.lerp(Color("5f8140"), sz120 * clampf((gully120 - 0.58) * 1.35, 0.0, 0.62)) # vegetation held in sheltered gullies
				if h > 3.2 and slope <= 0.50 and expose120 > 0.68: c = c.lerp(Color("a89a80"), sz120 * clampf((expose120 - 0.68) * 0.90, 0.0, 0.30)) # pale scree wash below snow, not snow itself
			var lum2 := (c.r + c.g + c.b) / 3.0 # R70 muted painted palette
			c = Color(lerpf(c.r, lum2, 0.10), lerpf(c.g, lum2, 0.10), lerpf(c.b, lum2, 0.10))
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
	var up2 := MeshInstance3D.new(); var bm3 := BoxMesh.new(); bm3.size = Vector3(400, 0.1, 400); up2.mesh = bm3; up2.position = Vector3(0, -0.60, 0); var um2 := StandardMaterial3D.new(); um2.albedo_texture = load(PT + "detail_noise.png"); um2.set("texture_repeat", 1); um2.uv1_scale = Vector3(120,120,1); um2.albedo_color = Color(0.40,0.42,0.25); um2.roughness = 1.0; up2.material_override = um2; up2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(up2)
	var mi := MeshInstance3D.new(); mi.mesh = tmesh
	var tsh := Shader.new(); tsh.code = "shader_type spatial;\nrender_mode cull_disabled;\nuniform sampler2D meadow_tex : source_color, repeat_enable;\nuniform sampler2D rock_tex : source_color, repeat_enable;\nvarying vec3 v_c;\nvarying vec3 v_wp;\nvarying vec3 v_wn;\nvoid vertex() { v_c = COLOR.rgb; v_wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; v_wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz); }\nvoid fragment() { float steep = smoothstep(0.74, 0.54, v_wn.y); vec3 md = texture(meadow_tex, v_wp.xz * 0.07).rgb; md = mix(md, texture(meadow_tex, v_wp.xz * 0.29 + 0.37).rgb, 0.32); vec2 ruv = abs(v_wn.x) > abs(v_wn.z) ? vec2(v_wp.z * 0.13, v_wp.y * 0.13) : vec2(v_wp.x * 0.13, v_wp.y * 0.13); vec3 rk = texture(rock_tex, ruv).rgb; vec3 mdx = clamp((md - 0.80) * 1.5 + 0.80, 0.50, 1.30); vec3 grass_c = v_c * mdx * vec3(1.13, 0.93, 0.76) * 0.85; vec3 rock_c = rk * vec3(1.06, 0.88, 0.66) * (0.30 + 0.50 * v_c) * mix(0.68, 1.0, clamp(v_wp.y / 8.0, 0.0, 1.0)); ALBEDO = mix(grass_c, rock_c, steep); float snp = 0.5 + 0.5*sin(v_wp.x*1.9+1.3)*sin(v_wp.z*1.4-0.7); float snw = smoothstep(2.8, 5.0, v_wp.y) * smoothstep(0.30, 0.58, v_wn.y) * smoothstep(0.32, 0.58, snp); ALBEDO = mix(ALBEDO, vec3(0.93,0.94,0.92), snw * 0.92); float asp = dot(normalize(v_wn.xz + vec2(0.001, 0.0)), normalize(vec2(0.62, 0.72))); float snp2 = 0.5 + 0.5*sin(v_wp.x*2.7-0.6)*sin(v_wp.z*2.2+1.9); float snw2 = smoothstep(2.6, 4.8, v_wp.y) * smoothstep(0.10, 0.55, asp) * smoothstep(0.30, 0.60, v_wn.y) * smoothstep(0.38, 0.62, snp2); ALBEDO = mix(ALBEDO, vec3(0.94,0.95,0.93), snw2 * 0.85); float zn1 = sin(v_wp.x*0.83+1.7) * sin(v_wp.z*0.61-0.4); float zn2 = sin(v_wp.x*1.93-0.6) * sin(v_wp.z*1.47+2.1); float zn3 = sin(v_wp.x*3.71+4.2) * sin(v_wp.z*2.93-1.3); float zn4 = sin(v_wp.x*0.80 + v_wp.z*0.91 + 0.9); float hzn = clamp(0.5 + 0.28*zn1 + 0.20*zn2 + 0.14*zn3 + 0.10*zn4, 0.0, 1.0); float hz = (smoothstep(10.0, 30.0, length(v_wp.xz)) * 0.38 + smoothstep(3.5, 9.0, v_wp.y) * 0.22) * mix(0.40, 1.25, hzn); ALBEDO = mix(ALBEDO, mix(vec3(0.70,0.76,0.74), vec3(0.78,0.82,0.79), hzn), clamp(hz, 0.0, 0.58)); ROUGHNESS = 1.0; }"
	var m := ShaderMaterial.new(); m.shader = tsh; m.set_shader_parameter("meadow_tex", load(PT + "detail_noise.png")); m.set_shader_parameter("rock_tex", load(PT + "rock_painted.png")); mi.material_override = m; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(mi)
	# outer trees sit on terrain
func _setup() -> void:
	get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED; get_viewport().msaa_3d = Viewport.MSAA_4X # R69 crisp
	# round presets: 1 pipeline, 2 softer/yellower, 3 tuned toward target mean colour
	var grass := Color("6fbf3f"); var grass2 := Color("8fd14f"); var stone := Color("b8b4a8"); var roof := Color("b06a4a"); var dirt := Color("c9a86a"); var leaf := Color("4e9b35"); var leaf2 := Color("77c04a"); var light_e := 1.0; var amb := 0.55
	if round_no == 2:
		grass = Color("69bd45"); grass2 = Color("86cc58"); stone = Color("c4bda9"); roof = Color("a85f43"); leaf = Color("4fae38"); leaf2 = Color("7cc24e"); light_e = 1.05; amb = 0.45
	if round_no >= 3:
		grass = Color("406e26"); grass2 = Color("4f7f2e"); stone = Color("a5917a"); roof = Color("a8664e"); # R122 roof desat toward target (measured sat .79 vs .41, hue/value already matched) dirt = Color("cda96e"); leaf = Color("407828"); leaf2 = Color("5e9638"); light_e = 1.16; amb = 0.37 # R107 warmer sun, deeper leaf family
	# environment + light + camera (game iso: ortho, pitch -38, yaw -45)
	var we := WorldEnvironment.new(); var env := Environment.new()
	var sky := Sky.new(); var smat := ProceduralSkyMaterial.new(); smat.sky_top_color = Color("8fc3e8"); smat.sky_horizon_color = Color("f2e3c2"); smat.ground_bottom_color = Color("5d6b46"); smat.ground_horizon_color = Color("d9c9a4"); sky.sky_material = smat; env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY; env.ambient_light_energy = amb * 0.25; env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.fog_enabled = true; env.fog_light_color = Color("f2e3c2"); env.fog_density = 0.0005; env.tonemap_mode = Environment.TONE_MAPPER_ACES; env.tonemap_exposure = 0.84; env.adjustment_enabled = true; env.adjustment_saturation = 1.15; env.adjustment_contrast = 1.10; env.adjustment_brightness = 1.00 # R70 muted toward target; env.glow_enabled = false; env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT;
	we.environment = env; add_child(we)
	var pool := OmniLight3D.new(); pool.position = Vector3(0,4.5,1); pool.light_color = Color("ffd9a0"); pool.light_energy = 0.12; pool.omni_range = 14.0; pool.shadow_enabled = false; add_child(pool)
	var pool2 := OmniLight3D.new(); pool2.position = Vector3(17,8,-5); pool2.light_color = Color("ffd9a0"); pool2.light_energy = 0.10; pool2.omni_range = 13.0; pool2.shadow_enabled = false; add_child(pool2)
	var fill := DirectionalLight3D.new(); fill.rotation_degrees = Vector3(-38, 125, 0); fill.light_energy = 0.04; fill.light_color = Color("dfe9f5"); fill.shadow_enabled = false; add_child(fill)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-52, -38, 0); sun.light_energy = 0.18; sun.light_color = Color(1,0.90,0.74); sun.shadow_enabled = true; sun.shadow_opacity = 0.70; sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS; sun.shadow_blur = 1.4; add_child(sun) # R108 sun experiment: actually enabled (add_child was comment-swallowed in baseline)
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
	var rng117 := RandomNumberGenerator.new(); rng117.seed = 11701 # R117 per-segment worn variation
	for i in path_pts.size()-1:
		var a: Vector2 = path_pts[i]; var b: Vector2 = path_pts[i+1]
		if i == 6: continue
		var mid := (a+b)*0.5; var dir := b-a; var ang := atan2(dir.x, dir.y)
		var w117 := rng117.randf_range(1.25, 1.55)
		box(Vector3(mid.x,0.015,mid.y), Vector3(w117+1.18+rng117.randf_range(-0.15,0.25),0.025,dir.length()+1.5), Color("7fae4a") if i%2==0 else Color("6f9a42"), ang) # R118 outer fringe (grass transition, existing patch keys)
		box(Vector3(mid.x,0.022,mid.y), Vector3(w117+0.60,0.03,dir.length()+1.35), Color("a8895a"), ang) # worn mid-step
		box(Vector3(mid.x,0.038,mid.y), Vector3(w117,0.04,dir.length()+1.2), dirt, ang, 0,0, "dirt")
		for fb118 in 2: # irregular fringe blobs breaking the ring line (seeded interval/side)
			var ft118 := rng117.randf_range(0.15, 0.85); var fs118 := 1.0 if fb118==0 else -1.0
			var fp118 := a.lerp(b, ft118)
			blob(Vector3(fp118.x + cos(ang)*fs118*(w117*0.5+0.38), 0.028, fp118.y - sin(ang)*fs118*(w117*0.5+0.38)), Vector3(rng117.randf_range(0.4,0.62),0.035,rng117.randf_range(0.3,0.45)), Color("7fae4a") if (i+fb118)%2==0 else Color("a8895a"))
		if rng117.randf() > 0.35: # cart ruts on most segments (existing worn key)
			for r117 in [-0.34, 0.34]:
				box(Vector3(mid.x + cos(ang)*r117, 0.046, mid.y - sin(ang)*r117), Vector3(0.15,0.045,dir.length()*0.92), Color("8a6c42"), ang)
		for cj117 in [0.33, 0.66]: # worn light centres
			var cp117 := a.lerp(b, cj117); cyl(Vector3(cp117.x,0.045,cp117.y), 0.30,0.30,0.03, Color("d9ba7c"), 9)
	for pt in path_pts:
		cyl(Vector3(pt.x,0.014,pt.y), 1.28,1.28,0.025, Color("7fae4a"), 10) # R118 junction fringe
		cyl(Vector3(pt.x,0.024,pt.y), 0.98,0.98,0.03, Color("a8895a"), 10)
		cyl(Vector3(pt.x,0.040,pt.y), 0.80,0.80,0.04, dirt, 10)
	# LANDSCAPE: rolling plateau back, cliff rocks, distant hills, mist bands


	for mi in 3:
		box(Vector3(-8.0+float(mi)*8.0, 1.6+float(mi)*0.5, -14.5), Vector3(13,0.9,1.6), Color(1,1,1,0.05))
	for bi in 12:
		var bx := -10.0+fmod(float(bi)*4.37,22.0); var bz := -12.0+fmod(float(bi)*3.13,10.0)
		add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(0,float(bi),0)).scaled(Vector3(0.7,0.5,0.6)), Vector3(bx, _h(bx,bz)+0.15, bz)), Color("8a867e")); tri_total += 128
	for si9 in 15:
		var sx9 := 8.5 + fmod(float(si9)*3.17, 12.5); var sz9 := -8.0 - fmod(float(si9)*2.43, 7.5)
		var ss9 := 1.1 + fmod(float(si9)*0.41, 1.1)
		add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(0.3,float(si9)*1.7,0.15)).scaled(Vector3(ss9*1.12,ss9*0.46,ss9*0.95)), Vector3(sx9, _h(sx9,sz9)+ss9*0.02, sz9)), Color("87704f") if si9%2==0 else Color("a89a80")) # R74 sunk/flattened; tri_total += 128
	for ti9 in 13:
		var tx9 := 6.5 + fmod(float(ti9)*2.61, 14.5); var tz9 := -6.2 - fmod(float(ti9)*1.37, 3.2)
		var ts9 := 0.55 + fmod(float(ti9)*0.39, 0.6)
		add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(0.2,float(ti9)*2.1,0.1)).scaled(Vector3(ts9*1.12,ts9*0.40,ts9*0.9)), Vector3(tx9, _h(tx9,tz9)+ts9*0.02, tz9)), Color("87704f") if ti9%3==0 else (Color("a89a80") if ti9%3==1 else Color("a89a80"))) # R74 sunk/flattened; tri_total += 128
	for ei in 10:
		var ex := -11.0+fmod(float(ei)*4.91,23.0); var ez := -6.0+fmod(float(ei)*5.37,17.0)
		cyl(Vector3(ex,0.03,ez), 0.62,0.62,0.025, Color("9a7c4e") if ei%2==0 else Color("b08d55"), 8)
	for fi in 36:
		var fx2 := -12.0+fmod(float(fi)*3.97,25.0); var fz := -9.0+fmod(float(fi)*4.53,20.0)
		if Vector2(fx2,fz).length() < 11.0:
			for fo in 3: cyl(Vector3(fx2+float(fo)*0.09-0.09,0.04,fz+fmod(float(fo)*0.07,0.12)), 0.045,0.045,0.03, [Color("ffffff"),Color("ffd94a"),Color("ff9db0")][fi%3], 5)
	# branch paths connecting buildings
	for seg in [[Vector2(5.4,-0.4),Vector2(7.2,-3.8)],[Vector2(-3.4,4.6),Vector2(-8.6,4.8)],[Vector2(5.4,-0.4),Vector2(6.2,4.2)],[Vector2(-1.5,-3.5),Vector2(-5.6,3.4)],[Vector2(-1,2),Vector2(-5,9.5)],[Vector2(6,3),Vector2(12.5,4.5)],[Vector2(-4,5),Vector2(-8,8)]]:
		var a2: Vector2 = seg[0]; var b2: Vector2 = seg[1]; var mid2 := (a2+b2)*0.5; var dir2 := b2-a2
		box(Vector3(mid2.x,0.028,mid2.y), Vector3(0.95,0.035,dir2.length()+0.8), Color("d6b878"), atan2(dir2.x,dir2.y), 0,0, "dirt")
	for li2 in 5:
		var lx2 := 10.0+fmod(float(li2)*2.3,6.0); var lz2 := -8.0-fmod(float(li2)*1.1,4.0)
		add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(0.2,float(li2),0.1)).scaled(Vector3(1.25,0.42,1.0)), Vector3(lx2,_h(lx2,lz2)+0.08,lz2)), Color("8f7355"), "rock"); tri_total+=128 # R74 sunk/flattened
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
	for mp in [Vector3(-3.0,0,5.9), Vector3(-1.8,0,5.9), Vector3(-3.0,0,7.0), Vector3(-1.8,0,7.0)]: box(mp+Vector3(0,0.75,0), Vector3(0.13,1.5,0.13), Color("6b4423"))
	roof2(Vector3(-2.4,1.52,6.45), 2.3, 2.1, 0.55, 0.14, Color("a05a44")) # R78 roof eave muted (was flag-red)
	box(Vector3(-2.4,0.55,6.45), Vector3(1.6,0.5,1.2), Color("a67c4e"), 0,0,0, "timber")
	for pp2 in [Vector3(0.9,0,3.1), Vector3(-4.2,0,6.3), Vector3(3.5,0,-0.9), Vector3(7.8,0,5.2), Vector3(-9.7,0,-3.2), Vector3(9.3,0,-4.2), Vector3(-1.6,0,-3.0)]: # R69 territory pennants (Black #7)
		box(pp2+Vector3(0,1.05,0), Vector3(0.06,2.1,0.06), Color("4a3421")); box(pp2+Vector3(0.32,1.85,0), Vector3(0.6,0.34,0.04), Color("2f62b8") if int(pp2.x) % 2 == 0 else Color("d43a2a"))
	for sp8 in [Vector3(1.2,0,1.8), Vector3(6.2,0,3.2), Vector3(-7.2,0,4.4), Vector3(4.2,0,-3.6), Vector3(-3.2,0,-0.6)]: _mini(sp8, Color("2f62b8") if int(sp8.x) % 2 == 0 else Color("d43a2a")) # settlers on paths
	for fp2 in [Vector3(8.2,0,6.8), Vector3(-10.0,0,-3.5), Vector3(10.2,0,-3.8)]:
		box(fp2+Vector3(0,2.2,0), Vector3(0.06,1.3,0.06), Color("4a3421")); box(fp2+Vector3(0.35,2.6,0), Vector3(0.65,0.38,0.04), Color("2f62b8") if fp2.x>0 else Color("d43a2a"))
	for wpath in [[Vector2(-10.5,5.5),Vector2(-5.6,7.6),Vector2(0,3.2),Vector2(8.2,6.8),Vector2(12.0,2.5),Vector2(16.8,7.8)],[Vector2(-10.0,-3.5),Vector2(-5.0,-1.2),Vector2(-1.5,-3.3),Vector2(5.4,-0.4),Vector2(10.2,-3.8),Vector2(11.5,-6.2),Vector2(13.5,-7.5)],[Vector2(-1.5,-3.3),Vector2(1.5,-6.0),Vector2(5.0,-7.5),Vector2(9.0,-8.8)],[Vector2(-7.0,11.5),Vector2(-4.5,8.5),Vector2(-5.6,7.6)],[Vector2(8.2,6.8),Vector2(9.5,8.5),Vector2(13.0,13.6)]]:
		for wi2 in wpath.size()-1:
			var wa: Vector2 = wpath[wi2]; var wb: Vector2 = wpath[wi2+1]; var wlen := wa.distance_to(wb); var wsteps := int(wlen / 0.65)
			for ws in wsteps+1:
				var wt := float(ws)/float(maxi(wsteps,1)); var wp := wa.lerp(wb, wt)
				var wdir := (wb-wa).normalized(); var wperp := Vector2(-wdir.y, wdir.x)
				wp += wperp * sin(wt*5.0 + float(wi2)*1.7) * 0.35
				var wy: float = 0.032 + (_h(wp.x,wp.y) if Vector2(wp.x,wp.y).length() > 11.0 else 0.0)
				var wr117 := 0.56 + 0.17 * (0.5 + 0.5 * sin(float(ws)*1.7 + float(wi2)*2.3)) # R117 worn width variation along branch
				cyl(Vector3(wp.x, wy-0.013, wp.y), wr117+0.60, wr117+0.60, 0.022, Color("7fae4a") if wi2%2==0 else Color("6f9a42"), 9) # R118 outer fringe
				cyl(Vector3(wp.x, wy-0.006, wp.y), wr117+0.30, wr117+0.30, 0.03, Color("a8895a"), 9) # worn mid-step
				cyl(Vector3(wp.x, wy, wp.y), wr117, wr117, 0.035, Color("d9ba7c"), 9)
				if ws % 2 == 0: # R69 stone edging (Black #3)
					blob(Vector3(wp.x+wperp.x*0.68, wy+0.01, wp.y+wperp.y*0.68), Vector3(0.13,0.09,0.13), Color("9a968c"))
					blob(Vector3(wp.x-wperp.x*0.68, wy+0.01, wp.y-wperp.y*0.68), Vector3(0.13,0.09,0.13), Color("9a968c"))
	for bp9 in [Vector2(5.4,-0.4), Vector2(8.2,6.8), Vector2(-5.6,7.6), Vector2(10.2,-3.8), Vector2(-10.0,-3.5), Vector2(-10.5,5.5), Vector2(12.0,2.5), Vector2(12.8,14.2), Vector2(-7.0,12.0), Vector2(16.8,7.8), Vector2(-6.5,-10.0), Vector2(19.2,2.8)]:
		var by9: float = _h(bp9.x,bp9.y) if bp9.length() > 11.0 else 0.0
		_ground_patch(bp9.x, bp9.y, 1.65, int(700.0 + bp9.x*7.0), Color("a8895a"), Color("8a6c42")) # R76 worn yard
		blob(Vector3(bp9.x, by9+0.045, bp9.y), Vector3(1.8,0.045,1.5), Color(0.10,0.16,0.05,0.42))
		for wt in 4:
			var wang: float = float(wt)*1.7 + float(bp9.x)
			blob(Vector3(bp9.x+sin(wang)*1.55, by9+0.07, bp9.y+cos(wang)*1.25), Vector3(0.34,0.16,0.3), Color("5b963a"))
	_ground_patch(-1.5, -3.5, 1.85, 777, Color("a8895a"), Color("8a6c42")) # R76 castle worn yard
	blob(Vector3(-1.5,0.045,-3.5), Vector3(2.8,0.05,2.3), Color(0.10,0.16,0.05,0.42))
	# castle centre-back
	_build_castle(Vector3(-1.5,0,-3.5), stone, roof)
	_build_octstore(Vector3(5.4,0,-0.4), stone)
	_build_hut(Vector3(8.2,0,6.8), stone)
	_build_aframe(Vector3(-5.6,0,7.6), roof, stone)
	_build_roundhouse(Vector3(10.2,0,-3.8), roof)
	_build_hut(Vector3(-10.0,0,-3.5), stone)
	# props: barrels, crates, fence, rocks
	for bp in [Vector3(5.4,0,-0.2), Vector3(-6.2,0,0.8)]:
		cyl(bp+Vector3(0,0.45,0), 0.38,0.42,0.9, Color("8a5f36"), 9); box(bp+Vector3(0.8,0.35,0.2), Vector3(0.7,0.7,0.7), Color("a67c4e"), 0.4)
	for fp in [Vector3(-1.5,0,-3.5), Vector3(5.4,0,-0.4)]:
		box(fp+Vector3(0,4.6,0), Vector3(0.07,1.4,0.07), Color("4a3421")); box(fp+Vector3(0.4,5.1,0), Vector3(0.75,0.42,0.04), Color("d43a2a"))
	# trees
	for p in [Vector3(-8,-0,-6),Vector3(8,0,1),Vector3(-9,0,3),Vector3(5.5,0,6.5),Vector3(-6.5,0,-4)]:
		_build_tree(p, leaf, leaf2)
	_build_roundbarn(Vector3(-10.5,0,5.5), roof)
	_build_roundhouse(Vector3(12.0,0,2.5), roof)
	_build_aframe(Vector3(-6.5,0,-10.0), roof, stone)
	_build_octstore(Vector3(12.8,0,14.2), stone)
	_build_house(Vector3(-7.0,0,12.0), roof, stone)
	_build_house(Vector3(16.8,0,7.8), roof, stone)
	_build_hut(Vector3(19.2,_h(19.2,2.8),2.8), stone)
	for tp in [Vector3(-14,0,-8),Vector3(-15,0,2),Vector3(-13,0,9),Vector3(19,0,-7),Vector3(8,0,-15),Vector3(-11,0,-11),Vector3(4,0,11),Vector3(-4,0,12),Vector3(14,0,5)]:
		_build_tree(tp, leaf, leaf2)
	# R124 forest framing (existing _build_tree language; positions screened in-frame, cull-passing, clear of buildings/paths/apron)
	for ftp in [Vector3(-0.5,0,18), Vector3(0.8,0,17.2), Vector3(4,0,15.5), Vector3(8,0,18.5), Vector3(13,0,18), Vector3(20,0,9.5), Vector3(21.5,0,14), Vector3(20.3,0,13.2)]: # foreground bottom band + corner clusters
		_build_tree(ftp, leaf, leaf2)
	for ftp2 in [Vector3(-18,0,-4), Vector3(-19,0,-6.5), Vector3(-13,0,-15), Vector3(-8.5,0,-14.5), Vector3(-4,0,-14.5), Vector3(5,0,-13.5)]: # left margin + background behind castle
		_build_tree(ftp2, leaf, leaf2)
	for ftp3 in [Vector3(14,0,-3), Vector3(18.5,0,-4), Vector3(21.5,0,-0.5)]: # village->hill transition (seated on _h by _build_tree)
		_build_tree(ftp3, leaf, leaf2)
	for bs2 in [Vector3(-13,0,-1),Vector3(4,0,-9),Vector3(12,0,-3),Vector3(-8,0,-9)]:
		add_canopy(Transform3D(Basis.IDENTITY.scaled(Vector3(0.55,0.4,0.55)), bs2+Vector3(0,0.45,0)), leaf)
	for bs in [Vector3(6,0,8),Vector3(-10,0,-3),Vector3(9,0,-8)]:
		add_canopy(Transform3D(Basis.IDENTITY.scaled(Vector3(0.6,0.42,0.6)), bs+Vector3(0,0.5,0)), leaf)
	# stones
	for p in [Vector3(4.8,0.25,-4),Vector3(-7.5,0.2,6),Vector3(7,0.2,-2)]: blob(p, Vector3(0.5,0.35,0.45), Color("9a968c"))
	for ap in [Vector3(-1.5,0,-3.5), Vector3(5.4,0,-0.4), Vector3(-5.6,0,7.6), Vector3(8.2,0,6.8), Vector3(10.2,0,-3.8)]:
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
	_detail_pass()
	# commit merged meshes
	for key in surf:
		var st: SurfaceTool = surf[key]; var mesh := st.commit()
		var mi := MeshInstance3D.new(); mi.mesh = mesh; mi.material_override = mat_for(key, Color.html(key.split("|")[0])); mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(mi) # R108 sun experiment: merged surf bodies do not cast (draw budget); canopy/roofs/cliffs cast
	var roof_groups := {}
	for ri2 in roof_instances:
		var rv := absi(int(ri2[1].origin.x*5.0 + ri2[1].origin.z*3.0)) % 3
		if not roof_groups.has(rv): roof_groups[rv] = SurfaceTool.new(); (roof_groups[rv] as SurfaceTool).begin(Mesh.PRIMITIVE_TRIANGLES)
		(roof_groups[rv] as SurfaceTool).append_from(ri2[0], 0, ri2[1])
	var rsh2 := Shader.new(); rsh2.code = "shader_type spatial;\nuniform sampler2D tex : source_color, repeat_enable, filter_linear_mipmap;\nuniform vec4 tint : source_color;\nvarying vec3 wn;\nvoid vertex() { wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz); }\nvoid fragment() { vec3 alb = texture(tex, UV).rgb * tint.rgb; float lf = clamp(dot(normalize(wn), normalize(vec3(-0.45, 0.75, 0.50))) * 0.5 + 0.5, 0.0, 1.0); float sh = 1.0 - smoothstep(0.50, 0.88, lf); float grey = dot(alb, vec3(0.333)); vec3 shaded = mix(alb, vec3(grey), 0.52) * vec3(0.55, 0.57, 0.63); ALBEDO = mix(alb, shaded, sh * 0.97); ROUGHNESS = 0.93; }" # R123 shared face-aware roof shader
	for rv2 in roof_groups:
		var rmi := MeshInstance3D.new(); rmi.mesh = (roof_groups[rv2] as SurfaceTool).commit(); var rmat := ShaderMaterial.new(); rmat.shader = rsh2; rmat.set_shader_parameter("tex", load(TEX["roofp"])); rmat.set_shader_parameter("tint", [Color(0.94,0.80,0.68), Color(0.82,0.66,0.55), Color(0.74,0.63,0.55)][rv2]) # R122 per-building spread as shader tint; rmi.material_override = rmat; rmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON; add_child(rmi)
	if canopy_st != null:
		var cmi := MeshInstance3D.new(); cmi.mesh = canopy_st.commit(); var cm := StandardMaterial3D.new(); cm.albedo_texture = load(TEX["leafp"]); cm.vertex_color_use_as_albedo = true; cm.albedo_color = Color(1.03,0.96,0.85); cm.roughness = 1.0; cm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS; cmi.material_override = cm; cmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON; add_child(cmi)
	if card_st != null:
		var kmi := MeshInstance3D.new(); kmi.mesh = card_st.commit(); var km := StandardMaterial3D.new(); km.albedo_texture = load(PT + "foliage_card.png"); km.vertex_color_use_as_albedo = true; km.albedo_color = Color(1,1,1); km.roughness = 1.0; km.alpha_scissor_threshold = 0.45; km.cull_mode = BaseMaterial3D.CULL_DISABLED; km.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS; kmi.material_override = km; kmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(kmi)
	_spawn_tufts()
	_spawn_carriers(); _spawn_statics()
func _detail_pass() -> void:
	# R75 scene-wide richness: per-building unique detail + patch-scale terrain detail (all seated, merged)
	var homes := [Vector3(-1.5,0,-3.5), Vector3(5.4,0,-0.4), Vector3(8.2,0,6.8), Vector3(-5.6,0,7.6), Vector3(10.2,0,-3.8), Vector3(-10.0,0,-3.5), Vector3(-10.5,0,5.5), Vector3(12.0,0,2.5), Vector3(-6.5,0,-10.0), Vector3(12.8,0,14.2), Vector3(-7.0,0,12.0), Vector3(16.8,0,7.8), Vector3(19.2,0,2.8)]
	for hi in homes.size():
		var hp: Vector3 = homes[hi]
		if Vector2(hp.x, hp.z).length() > 11.0: hp.y = _h(hp.x, hp.z)
		var ang := float(hi) * 1.37; var side := Vector3(cos(ang), 0, sin(ang)); var fwd := Vector3(-sin(ang), 0, cos(ang))
		match (hi % 4) if not (hi in [0, 1, 2, 6, 9, 11]) else -1: # R110 thinned clutter on 3 homes
			0: # woodpile: stacked logs against wall
				for li in 6:
					var lm := CylinderMesh.new(); lm.bottom_radius=0.13; lm.top_radius=0.13; lm.height=1.05; lm.radial_segments=7
					add_mesh(lm, Transform3D(Basis.from_euler(Vector3(0, ang, PI/2.0)), hp + side*2.3 + fwd*(float(li%3)*0.3-0.3) + Vector3(0, 0.16+0.26*float(li/3), 0)), Color("8a6742")); tri_total += 28
			1: # lean-to: sloped roof on posts + barrel under
				box(hp + side*2.0 + Vector3(0, 1.05, 0), Vector3(1.7, 0.10, 1.4), Color("a05a44"), ang, 0, 0.30)
				box(hp + side*2.55 + Vector3(0, 0.5, 0) + fwd*0.55, Vector3(0.11, 1.0, 0.11), Color("54381f")); box(hp + side*2.55 + Vector3(0, 0.5, 0) - fwd*0.55, Vector3(0.11, 1.0, 0.11), Color("54381f"))
				cyl(hp + side*2.0 + Vector3(0, 0.38, 0), 0.32, 0.36, 0.76, Color("8a5f36"), 8)
			2: # crates + sacks + barrel cluster
				box(hp + side*2.2 + Vector3(0, 0.32, 0), Vector3(0.64, 0.64, 0.64), Color("a67c4e"), ang*0.7)
				box(hp + side*2.2 + fwd*0.7 + Vector3(0, 0.26, 0), Vector3(0.52, 0.52, 0.52), Color("8a6742"), ang)
				blob(hp + side*2.3 - fwd*0.6 + Vector3(0, 0.24, 0), Vector3(0.32, 0.28, 0.32), Color("c9b18a"))
				cyl(hp + side*1.7 + fwd*1.1 + Vector3(0, 0.36, 0), 0.30, 0.34, 0.72, Color("7a5a36"), 8)
			3: # dormer window on the roof + window box flowers
				box(hp + Vector3(0, 2.55, 0) + fwd*0.55, Vector3(0.62, 0.62, 0.5), Color("e8d9b8"), 0, 0, 0, "plaster")
				box(hp + Vector3(0, 2.98, 0) + fwd*0.55, Vector3(0.78, 0.12, 0.66), Color("a05a44"))
				box(hp + Vector3(0, 2.5, 0) + fwd*0.86, Vector3(0.34, 0.4, 0.06), Color("ffd98a"))
		# door-side lantern + step stones at every home
		box(hp + fwd*1.6 + side*0.8 + Vector3(0, 0.95, 0), Vector3(0.07, 0.9, 0.07), Color("4a3421")); box(hp + fwd*1.6 + side*0.8 + Vector3(0, 1.32, 0), Vector3(0.17, 0.2, 0.17), Color("ffd98a"))
		blob(hp + fwd*1.9 + Vector3(0, 0.03, 0), Vector3(0.5, 0.05, 0.4), Color("9a968c"))
	# second market stall: striped canopy (reads at full frame), goods crates
	var ms := Vector3(4.2, 0, 9.0)
	for mp2 in [Vector3(-0.9,0,-0.7), Vector3(0.9,0,-0.7), Vector3(-0.9,0,0.7), Vector3(0.9,0,0.7)]: box(ms+mp2+Vector3(0,0.8,0), Vector3(0.12,1.6,0.12), Color("6b4423"))
	for sti in 5: box(ms+Vector3(-0.85+float(sti)*0.43, 1.72, 0), Vector3(0.4, 0.09, 1.9), Color("d43a2a") if sti%2==0 else Color("f2ead8"), 0, 0, 0.10)
	box(ms+Vector3(0,0.55,0), Vector3(1.5,0.45,1.1), Color("a67c4e"), 0, 0, 0, "timber")
	for gi in 6: blob(ms+Vector3(-0.55+fmod(float(gi)*0.4,1.1), 0.86, -0.35+fmod(float(gi)*0.33,0.7)), Vector3(0.17,0.13,0.17), [Color("e2543e"), Color("ffd94a"), Color("7fae4a")][gi%3])
	# fence lines along two meadow edges (posts + double rail, seated)
	for fl in [[Vector3(-12.5,0,1.5), Vector3(-12.0,0,7.5)], [Vector3(10.5,0,8.0), Vector3(15.5,0,9.5)], [Vector3(-3.0,0,10.8), Vector3(2.5,0,11.4)]]:
		var fa: Vector3 = fl[0]; var fb: Vector3 = fl[1]; var flen := fa.distance_to(fb); var fsteps := int(flen/1.1)
		for fs in fsteps+1:
			var fp9 := fa.lerp(fb, float(fs)/float(maxi(fsteps,1))); fp9.y = _h(fp9.x, fp9.z) if Vector2(fp9.x,fp9.z).length() > 11.0 else 0.0
			box(fp9+Vector3(0,0.42,0), Vector3(0.11,0.84,0.11), Color("6b4423"))
		var fmid := (fa+fb)*0.5; fmid.y = _h(fmid.x, fmid.z) if Vector2(fmid.x,fmid.z).length() > 11.0 else 0.0
		box(fmid+Vector3(0,0.68,0), Vector3(0.09,0.09,flen), Color("7a5a36"), atan2(fb.x-fa.x, fb.z-fa.z))
		box(fmid+Vector3(0,0.34,0), Vector3(0.09,0.09,flen), Color("7a5a36"), atan2(fb.x-fa.x, fb.z-fa.z))
	# terrain patch detail (40-90px faces: patch scale, flat on ground, no floating specks)
	var patch_cols := [Color("6f9a42"), Color("4e7d26"), Color("a8895a"), Color("7fae4a"), Color("8a6c42")]
	for pi2 in 22:
		var px2 := -17.0 + fmod(float(pi2)*5.83, 36.0); var pz2 := -12.0 + fmod(float(pi2)*4.37, 25.0)
		if Vector2(px2, pz2).length() < 6.0: continue
		var py2: float = _h(px2, pz2) if Vector2(px2, pz2).length() > 11.0 else 0.0
		var pr := 1.9 + fmod(float(pi2)*0.71, 1.8)
		_ground_patch(px2, pz2, pr, 400 + pi2*13, patch_cols[pi2 % 5], patch_cols[(pi2+2) % 5])
	# R97: worn/meadow patches on open centre grass (positions avoid buildings/paths; same keys as outer patches)
	for cp97 in [[0.8, 4.6, 1.9], [-5.8, 1.2, 2.1], [5.8, -1.8, 1.7], [-8.2, -6.2, 2.0], [10.8, 8.2, 1.8], [-1.2, 9.8, 2.2], [13.5, 0.8, 1.6]]:
		_ground_patch(cp97[0], cp97[1], cp97[2], int(600.0 + cp97[0]*9.0), patch_cols[int(cp97[0]) % 5 if cp97[0] >= 0.0 else 1], Color("a8895a"))
	for ri2 in 10: # scattered boulders with contact shadow discs
		var rx2 := -15.0 + fmod(float(ri2)*6.31, 33.0); var rz2 := -11.0 + fmod(float(ri2)*5.17, 23.0)
		var ry2: float = _h(rx2, rz2) if Vector2(rx2, rz2).length() > 11.0 else 0.0
		cyl(Vector3(rx2, ry2+0.015, rz2), 0.85, 0.85, 0.015, Color(0.09,0.15,0.04,0.35), 10)
		add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(0.2, float(ri2)*1.9, 0.1)).scaled(Vector3(0.55,0.4,0.5)), Vector3(rx2, ry2+0.12, rz2)), Color("8f7355"), "rock"); tri_total += 128
	for li3 in 5: # fallen logs
		var lx3 := -13.0 + fmod(float(li3)*7.13, 28.0); var lz3 := -9.0 + fmod(float(li3)*6.03, 19.0)
		var ly3: float = _h(lx3, lz3) if Vector2(lx3, lz3).length() > 11.0 else 0.0
		var lg := CylinderMesh.new(); lg.bottom_radius=0.17; lg.top_radius=0.19; lg.height=1.7; lg.radial_segments=7
		add_mesh(lg, Transform3D(Basis.from_euler(Vector3(0, float(li3)*0.9, PI/2.0)), Vector3(lx3, ly3+0.16, lz3)), Color("7a5a36")); tri_total += 28
	for bu in [Vector3(-12.5,0,-6.5), Vector3(6.8,0,9.8), Vector3(16.5,0,-3.5), Vector3(-15.5,0,6.0), Vector3(4.2,0,12.8), Vector3(-8.5,0,-12.5), Vector3(19.5,0,4.5), Vector3(0.5,0,-13.5)]:
		var bp9: Vector3 = bu; if Vector2(bu.x, bu.z).length() > 11.0: bp9.y = _h(bu.x, bu.z)
		add_canopy(Transform3D(Basis.IDENTITY.scaled(Vector3(0.62,0.45,0.62)), bp9+Vector3(0,0.42,0)), Color("4e8f33"))
	# R119 merged carriers on main/branch path routes (existing keys, varied loads/clothing)
	_build_carrier(Vector3(4.0,0,3.4), Color("d43a2a"), 1)
	_build_carrier(Vector3(-5.5,0,3.2), Color("3f7d3a"), 0)
	_build_carrier(Vector3(3.2,0,-6.7), Color("2f62b8"), 2)
	for gi119 in 8: # shoulder goods at the GLB carrier positions (spawned later in _spawn_carriers)
		var gp119: Vector3 = [Vector3(0.6,0.05,2.8), Vector3(-2.6,0.05,0.8), Vector3(5.2,0.05,1.6), Vector3(-6.4,0.05,-1.4), Vector3(-8.8,0.05,5.6), Vector3(8.6,0.05,4.6), Vector3(3.8,0.05,-4.2), Vector3(-9.5,0.05,1.5)][gi119]
		var gl119 := CylinderMesh.new(); gl119.bottom_radius=0.09; gl119.top_radius=0.09; gl119.height=0.95; gl119.radial_segments=7
		add_mesh(gl119, Transform3D(Basis.from_euler(Vector3(0,-0.7,PI/2.0)), gp119+Vector3(0,1.18,0)), Color("8a5f36")); tri_total += 28
		if gi119 % 2 == 0: blob(gp119+Vector3(-0.32,0.86,0.1), Vector3(0.20,0.26,0.20), Color("c9b18a"))
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
			add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(0,float(si3),0)).scaled(Vector3(0.6,0.42,0.55)), Vector3(bp.x, _h(bp.x,bp.z)+0.12, bp.z)), Color("8f7355"), "rock"); tri_total += 128
func _build_mine(mp: Vector3) -> void:
	# R72: enlarged timber headframe (was 1.9 tall, drowned by crest rocks) - warm timber, dark iron
	box(mp+Vector3(0,0.10,0.6), Vector3(3.4,0.22,2.6), Color("6e4a28")) # timber platform
	box(mp+Vector3(0,0.95,-0.25), Vector3(1.9,1.9,0.22), Color("17110b")) # entrance
	for lx in [-1.15, 1.15]:
		box(mp+Vector3(lx,1.65,0), Vector3(0.30,3.3,0.34), Color("7c4c22"))
		box(mp+Vector3(lx,1.65,0.85), Vector3(0.26,3.3,0.30), Color("6e421f"))
	box(mp+Vector3(0,3.38,0.4), Vector3(3.0,0.34,0.36), Color("8a5f30"))
	box(mp+Vector3(0,2.45,0.42), Vector3(2.7,0.24,0.26), Color("7c4c22"))
	box(mp+Vector3(0,2.0,0.45), Vector3(2.9,0.20,0.20), Color("5d3a1e"), 0, 0, 0.62); box(mp+Vector3(0,2.0,0.45), Vector3(2.9,0.20,0.20), Color("5d3a1e"), 0, 0, -0.62)
	box(mp+Vector3(0,1.05,0.45), Vector3(2.9,0.18,0.18), Color("5d3a1e"), 0, 0, 0.9); box(mp+Vector3(0,1.05,0.45), Vector3(2.9,0.18,0.18), Color("5d3a1e"), 0, 0, -0.9)
	var wm := CylinderMesh.new(); wm.bottom_radius=0.88; wm.top_radius=0.88; wm.height=0.14; wm.radial_segments=14; add_mesh(wm, Transform3D(Basis.from_euler(Vector3(PI/2.0,0,0)), mp+Vector3(0,3.42,0.55)), Color("2f2d2d")); tri_total += 56
	var hub := CylinderMesh.new(); hub.bottom_radius=0.30; hub.top_radius=0.30; hub.height=0.20; hub.radial_segments=10; add_mesh(hub, Transform3D(Basis.from_euler(Vector3(PI/2.0,0,0)), mp+Vector3(0,3.42,0.55)), Color("8a5f30")); tri_total += 40
	box(mp+Vector3(1.42,2.5,0.6), Vector3(0.22,0.28,0.08), Color("ffd98a")) # lantern
	box(mp+Vector3(0,4.05,0.4), Vector3(0.07,1.0,0.07), Color("4a3421")); box(mp+Vector3(0.38,4.32,0.4), Vector3(0.72,0.4,0.04), Color("d43a2a")) # pennant
	for rz in 2: box(mp+Vector3(-0.38+float(rz)*0.76, -0.42, 1.9), Vector3(0.11,0.07,3.4), Color("3a3632"))
	for sl in 5: box(mp+Vector3(0, -0.50, 0.8+float(sl)*0.72), Vector3(1.15,0.08,0.18), Color("6b4a2c"))
	box(mp+Vector3(0,-0.12,2.7), Vector3(0.95,0.52,1.2), Color("6b4423")); box(mp+Vector3(0,0.24,2.7), Vector3(0.80,0.24,1.0), Color("2f2d2d"))
	box(mp+Vector3(-1.9,0.55,1.4), Vector3(0.85,1.1,0.85), Color("8a5f36")); box(mp+Vector3(2.0,0.45,1.0), Vector3(0.7,0.9,0.7), Color("a67c4e"), 0.4) # ore crates
func _build_watchtower(tp: Vector3) -> void:
	for lx in [-0.55, 0.55]:
		for lz in [-0.55, 0.55]: box(tp+Vector3(lx,2.1,lz), Vector3(0.17,4.2,0.17), Color("6b4a2c"))
	box(tp+Vector3(0,2.2,0.62), Vector3(1.35,0.12,0.12), Color("54381f"), 0, 0, 0.5); box(tp+Vector3(0,2.2,-0.62), Vector3(1.35,0.12,0.12), Color("54381f"), 0, 0, -0.5)
	box(tp+Vector3(0,4.3,0), Vector3(1.8,0.18,1.8), Color("7a5a36"))
	box(tp+Vector3(0,5.05,0), Vector3(1.45,1.35,1.45), Color("a8875e"), 0,0,0, "timber")
	box(tp+Vector3(0,5.15,0.75), Vector3(0.44,0.5,0.06), Color("ffd98a"))
	cyl(tp+Vector3(0,6.25,0), 1.35,0.04,1.15, Color("a05a44"), 8, "roofp")
func _terrace(cx: float, cz: float, w: float, d: float, c: Color, tx: String) -> void:
	# R71: 4 stepped segments conforming to _h, retaining skirt where slope falls (+z edge + ends)
	var segs := 4
	for s in segs:
		var sx := cx - w/2.0 + w*(float(s)+0.5)/float(segs)
		var sy := _h(sx, cz) + 0.05
		box(Vector3(sx, sy, cz), Vector3(w/float(segs)+0.07, 0.16, d), c, 0, 0, 0, tx)
		var ey := _h(sx, cz + d/2.0 + 0.25)
		box(Vector3(sx, (sy+ey)*0.5 - 0.12, cz + d/2.0), Vector3(w/float(segs)+0.05, absf(sy-ey)+0.42, 0.18), Color("7a6a50"))
		var xy := _h(cx - w/2.0 - 0.25, cz) if s == 0 else _h(cx + w/2.0 + 0.25, cz)
		if s == 0 or s == segs-1:
			var ex := cx - w/2.0 if s == 0 else cx + w/2.0
			box(Vector3(ex, (sy+xy)*0.5 - 0.12, cz), Vector3(0.18, absf(sy-xy)+0.42, d), Color("7a6a50"))
func _hill_content() -> void:
	_build_mine(Vector3(14.5, _h(14.5,-11.5)+0.55, -11.5)) # R70 mine on corner slope
	_build_watchtower(Vector3(14.2, _h(14.2,-6.9)-0.15, -6.9))
	var sw := [Vector2(2,-4.5), Vector2(6,-5.2), Vector2(5.2,-6.8), Vector2(8.6,-7.6), Vector2(11.5,-9.3), Vector2(13.8,-11.0)] # R70 stone road to mine
	for si in sw.size()-1:
		var a3: Vector2 = sw[si]; var b3: Vector2 = sw[si+1]; var mid3 := (a3+b3)*0.5; var dir3 := b3-a3
		box(Vector3(mid3.x, _h(mid3.x,mid3.y)+0.06, mid3.y), Vector3(1.15,0.07,dir3.length()+0.7), Color("c9ab72"), atan2(dir3.x,dir3.y), 0,0, "dirt")
	for ti in 6:
		var tx2 := 4.2+float(ti)*2.0; var tz2 := -6.2-float(ti)*0.6
		var ty2 := _h(tx2,tz2)+0.05
		_terrace(tx2, tz2, 4.4, 1.5, Color("86b83e") if ti%2==0 else Color("b08d55"), "dirt" if ti%2==1 else "")
		for cr in 5: box(Vector3(tx2-1.5+float(cr)*0.75, _h(tx2-1.5+float(cr)*0.75, tz2)+0.16, tz2), Vector3(0.5,0.09,1.25), Color("3f7020") if ti%2==0 else Color("96683c"), 0.15)
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
		_terrace(fx5, fz5, 4.6, 1.7, Color("86b83e") if fi2%2==0 else Color("b08d55"), "" if fi2%2==0 else "dirt")
		for cr2 in 5: box(Vector3(fx5-1.6+float(cr2)*0.8, _h(fx5-1.6+float(cr2)*0.8, fz5)+0.16, fz5), Vector3(0.5,0.09,1.45), Color("3f7020") if fi2%2==0 else Color("96683c"), 0.12)
		for fp4 in 4: box(Vector3(fx5-2.1+float(fp4)*1.4, _h(fx5-2.1+float(fp4)*1.4, fz5+0.95)+0.35, fz5+0.95), Vector3(0.09,0.7,0.09), Color("6b4a2c"))
	for fi3 in 6:
		var fx6 := 2.2+float(fi3)*1.9; var fz6 := -5.0 - float(fi3%3)*0.95; var fy6 := _h(fx6,fz6)+0.05
		_terrace(fx6, fz6, 4.8, 1.6, Color("7fae4a") if fi3%2==0 else Color("a67c4e"), "" if fi3%2==0 else "dirt")
		for cr3 in 5: box(Vector3(fx6-1.6+float(cr3)*0.8, _h(fx6-1.6+float(cr3)*0.8, fz6)+0.16, fz6), Vector3(0.5,0.09,1.4), Color("4e7d26") if fi3%2==0 else Color("96683c"), 0.1)
	for tp3 in [Vector3(4.5,0,-11.5), Vector3(11,0,-12.5), Vector3(20,0,-9.5), Vector3(7.5,0,-13), Vector3(17,0,-13.5)]:
		_build_tree(tp3, Color("79c24d"), Color("a9dd77"))
	_build_hut(Vector3(8.2, _h(8.2,-11.2)-0.1, -11.2), Color("a5917a"))
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
	for si4 in 5: # R74: summit standing stones lowered/sunk into slope (were 3.1-3.8 dark pillars competing with mine)
		var sa := float(si4) * TAU / 5.0
		var sty := 1.15+fmod(float(si4)*0.22,0.5)
		box(base+Vector3(sin(sa)*1.3, sty/2.0-0.38, cos(sa)*1.3), Vector3(0.78,sty,0.52), Color("7d6a52"), sa, 0.12, 0)
		box(base+Vector3(sin(sa)*1.3, sty-0.26, cos(sa)*1.3), Vector3(0.6,0.2,0.4), Color("d8cbb2"), sa, 0.12, 0)
		box(base+Vector3(sin(sa)*2.35, 0.28, cos(sa)*2.35), Vector3(0.55,0.55,0.4), Color("8a867e"), sa, 0, 0)
	box(base+Vector3(0,0.62,0), Vector3(0.85,1.7,0.6), Color("7d6a52"), 0.3, 0.08, 0) # centre stone lowered likewise
	box(base+Vector3(0,1.55,0), Vector3(0.62,0.24,0.44), Color("d8cbb2"), 0.3, 0.08, 0)
	box(base+Vector3(0,1.35,0.35), Vector3(0.08,1.5,0.08), Color("6b4a2c")); box(base+Vector3(0.38,1.95,0.35), Vector3(0.68,0.4,0.04), Color("d43a2a"))
	var up := [Vector2(11.5,-7.6), Vector2(10.4,-8.2), Vector2(9.6,-8.6), Vector2(9.0,-8.8)]
	for ui in up.size()-1:
		var a4: Vector2 = up[ui]; var b4: Vector2 = up[ui+1]; var mid4 := (a4+b4)*0.5; var dir4 := b4-a4
		box(Vector3(mid4.x, _h(mid4.x,mid4.y)+0.06, mid4.y), Vector3(1.05,0.07,dir4.length()+0.6), Color("c9ab72"), atan2(dir4.x,dir4.y), 0,0, "dirt")
	for tp4 in [Vector3(7.5,0,-16), Vector3(20.5,0,-15), Vector3(17,0,-16.5), Vector3(24,0,-12.5)]:
		_build_tree(tp4, Color("79c24d"), Color("a9dd77"))
	for rf in 3:
		var rx4 := 9.0+float(rf)*4.2; var rz4 := -13.5-float(rf)*0.8
		_terrace(rx4, rz4, 3.6, 1.4, Color("8d8172"), "rock")
		for sb in 4: blob(Vector3(rx4-1.2+float(sb)*0.8, _h(rx4,rz4)+0.16, rz4), Vector3(0.3,0.2,0.3), Color("a89a80"))
	for sd in 4:
		var sx5 := 9.5+float(sd)*2.0; var sz5 := -14.5-fmod(float(sd)*1.1,2.0)
		blob(Vector3(sx5, _h(sx5,sz5)+0.08, sz5), Vector3(0.85,0.22,0.7), Color("eef2f4"))
func _upper_fill() -> void:
	for mf in 4:
		var mx := 7.0+float(mf)*3.6; var mz := -10.8 - float(mf%2)*1.6; var my := _h(mx,mz)+0.05
		if Vector2(mx,mz).distance_to(Vector2(14.5,-11.5)) < 4.5: continue # R75: calm near mine
		_terrace(mx, mz, 4.2, 1.5, Color("86b83e") if mf%2==0 else Color("b08d55"), "")
		for cr4 in 4: box(Vector3(mx-1.4+float(cr4)*0.9, _h(mx-1.4+float(cr4)*0.9, mz)+0.16, mz), Vector3(0.5,0.09,1.3), Color("4e7d26") if mf%2==0 else Color("96683c"), 0.18)
	for tp5 in [Vector3(8.5,0,-12), Vector3(13,0,-11), Vector3(24,0,-12), Vector3(11.5,0,-14.5), Vector3(22,0,-9)]:
		_build_tree(tp5, Color("79c24d"), Color("a9dd77"))
	_build_hut(Vector3(18.5, _h(18.5,-8.0)-0.1, -8.0), Color("a5917a"))
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
		if Vector2(cx6,cz6).distance_to(Vector2(14.5,-11.5)) < 4.5: continue # R75
		_terrace(cx6, cz6, 5.6, 1.8, Color("b08d55") if cf%2==0 else Color("86b83e"), "")
		for oc in 3: blob(Vector3(cx6-1.6+float(oc)*1.5, _h(cx6-1.6+float(oc)*1.5,cz6+0.6)+0.2, cz6+0.6), Vector3(0.5,0.35,0.5), Color("a89a80"))
	for cf2 in 3:
		var cx7 := 7.5+float(cf2)*5.2; var cz7 := -9.9-float(cf2)*0.3
		if Vector2(cx7,cz7).distance_to(Vector2(14.5,-11.5)) < 4.5: continue # R75
		_terrace(cx7, cz7, 5.8, 1.7, Color("86b83e") if cf2%2==0 else Color("b08d55"), "")
		for cr6 in 5: box(Vector3(cx7-1.9+float(cr6)*0.95, _h(cx7-1.9+float(cr6)*0.95, cz7)+0.16, cz7), Vector3(0.55,0.09,1.5), Color("3f7020") if cf2%2==0 else Color("96683c"), 0.12)
	for tp7 in [Vector3(6.5,0,-10.5), Vector3(17.5,0,-10.2), Vector3(5.5,0,-12.8), Vector3(21.5,0,-14.5)]:
		_build_tree(tp7, Color("79c24d"), Color("a9dd77"))
	for cf3 in 2:
		var cx8 := 5.5+float(cf3)*7.5; var cz8 := -11.6
		if Vector2(cx8,cz8).distance_to(Vector2(14.5,-11.5)) < 4.5: continue # R75
		_terrace(cx8, cz8, 5.4, 1.6, Color("b08d55") if cf3%2==0 else Color("86b83e"), "")
		for fp6 in 4: box(Vector3(cx8-2.2+float(fp6)*1.45, _h(cx8-2.2+float(fp6)*1.45, cz8+0.9)+0.38, cz8+0.9), Vector3(0.09,0.75,0.09), Color("6b4a2c"))
	# lower-left farm: fields + trees + fence (fills reframed meadow)
	for lf in 2:
		var lx6 := -13.5+float(lf)*0.4; var lz6 := 8.5+float(lf)*2.2
		_terrace(lx6, lz6, 5.2, 2.0, Color("86b83e") if lf%2==0 else Color("b08d55"), "")
		for cr5 in 5: box(Vector3(lx6-1.9+float(cr5)*0.95, 0.14, lz6), Vector3(0.55,0.09,1.7), Color("3f7020") if lf%2==0 else Color("96683c"), 0.3)
	_build_tree(Vector3(-15.5,0,4.5), Color("79c24d"), Color("a9dd77")); _build_tree(Vector3(-11,0,12), Color("79c24d"), Color("a9dd77"))
func _snow_patch(cx: float, cz: float, r: float, seedv: int, c: Color) -> void:
	# R73: jagged star patch, elongated along downhill (fall line from _h gradient), seated per-vertex
	var rng := RandomNumberGenerator.new(); rng.seed = seedv
	var grad := Vector2(_h(cx+0.7,cz)-_h(cx-0.7,cz), _h(cx,cz+0.7)-_h(cx,cz-0.7))
	var fall := -grad.normalized() if grad.length() > 0.01 else Vector2(0.6, 0.8)
	var side := Vector2(-fall.y, fall.x)
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 11; var pts: Array = []
	for i in n:
		var a := TAU * float(i) / float(n)
		var rr := r * rng.randf_range(0.42, 1.28)
		var dir := side * (cos(a) * rr) + fall * (sin(a) * rr * 1.9)
		pts.append(Vector3(cx + dir.x, _h(cx + dir.x, cz + dir.y) + 0.07, cz + dir.y))
	var c0 := Vector3(cx, _h(cx, cz) + 0.09, cz)
	for i in n:
		var p1: Vector3 = pts[i]; var p2: Vector3 = pts[(i+1) % n]
		var fn := (p1-c0).cross(p2-c0).normalized(); if fn.y < 0.0: fn = -fn
		for v in [c0, p1, p2]: st.set_normal(fn); st.set_uv(Vector2(0.5,0.5)); st.add_vertex(v)
	add_mesh(st.commit(), Transform3D.IDENTITY, c); tri_total += n
func _ground_patch(cx: float, cz: float, r: float, seedv: int, cbase: Color, csub: Color) -> void:
	# R76: worked-earth patch - jagged fan outline seated per-vertex on _h, internal variation at frame scale
	var rng := RandomNumberGenerator.new(); rng.seed = seedv
	var ang0 := rng.randf() * TAU
	var dir := Vector2(cos(ang0), sin(ang0)); var perp := Vector2(-dir.y, dir.x)
	var layers := [[r, cbase, Vector2.ZERO], [r*0.58, cbase.darkened(0.28), dir*r*0.10], [r*0.42, csub.lightened(0.10), perp*r*0.34 + dir*r*0.12]]
	for li in layers.size():
		var lr: float = layers[li][0]; var lc: Color = layers[li][1]; var off: Vector2 = layers[li][2]
		var ccx := cx + off.x; var ccz := cz + off.y
		var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var n := 11; var pts: Array = []
		for i in n:
			var a := TAU * float(i) / float(n)
			var rr := lr * rng.randf_range(0.45, 1.25)
			var dd := Vector2(cos(a), sin(a))
			var ex := ccx + dd.x * rr * (1.0 + 0.35*absf(dd.dot(dir))); var ez := ccz + dd.y * rr * (1.0 + 0.35*absf(dd.dot(dir)))
			pts.append(Vector3(ex, _h(ex, ez) + 0.030 + float(li)*0.006, ez))
		var c0 := Vector3(ccx, _h(ccx, ccz) + 0.034 + float(li)*0.006, ccz)
		for i in n:
			var p1: Vector3 = pts[i]; var p2: Vector3 = pts[(i+1) % n]
			var fn := (p1-c0).cross(p2-c0).normalized(); if fn.y < 0.0: fn = -fn
			for v in [c0, p1, p2]: st.set_normal(fn); st.set_uv(Vector2(0.5,0.5)); st.add_vertex(v)
		add_mesh(st.commit(), Transform3D.IDENTITY, lc); tri_total += n
	for fi in 3: # furrow/wear strips following patch direction (thin seated boxes, not specks)
		var foff := perp * (float(fi-1) * r * 0.38)
		var fx := cx + foff.x; var fz := cz + foff.y
		box(Vector3(fx, _h(fx, fz) + 0.048, fz), Vector3(0.14, 0.03, r*1.45), cbase.darkened(0.38), ang0)
	for si in 2: # small seated stones/clumps inside patch
		var soff := dir * rng.randf_range(-r*0.5, r*0.5) + perp * rng.randf_range(-r*0.4, r*0.4)
		blob(Vector3(cx+soff.x, _h(cx+soff.x, cz+soff.y) + 0.05, cz+soff.y), Vector3(0.20, 0.10, 0.18), Color("8f7355"))
func _slope_fan(cx: float, cz: float, r: float, seedv: int, c: Color, elong := 1.8, lift := 0.0, clasts := false, tx := "") -> void:
	# R120: large soft slope zone - jagged four-ring fan elongated down the local fall line.
	# Every ring vertex is seated on displaced _h (R101); the rings keep the sheet following
	# the slope instead of chord-cutting it (v1 single-ring fans buried on convex ground).
	var rng := RandomNumberGenerator.new(); rng.seed = seedv
	var grad := Vector2(_h(cx+0.7,cz)-_h(cx-0.7,cz), _h(cx,cz+0.7)-_h(cx,cz-0.7))
	var fall := -grad.normalized() if grad.length() > 0.01 else Vector2(-0.35, 0.94)
	var side := Vector2(-fall.y, fall.x)
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 18; var rings: Array = []
	for ri in 4:
		var rf: float = [0.30, 0.58, 0.82, 1.0][ri]
		var ring: Array = []
		for i in n:
			var a := TAU * float(i) / float(n)
			var jr := rng.randf_range(0.68, 1.16) if ri == 3 else rng.randf_range(0.86, 1.08)
			var dir: Vector2 = (side * (cos(a) * r * 0.86) + fall * (sin(a) * r * elong)) * rf * jr
			ring.append(Vector3(cx + dir.x, _h(cx + dir.x, cz + dir.y) + float([0.100, 0.088, 0.076, 0.064][ri]) + lift, cz + dir.y))
		rings.append(ring)
	var c0 := Vector3(cx, _h(cx, cz) + 0.112 + lift, cz)
	for i in n:
		var i2 := (i + 1) % n
		var tris: Array = [[c0, rings[0][i2], rings[0][i]]]
		for ri in 3:
			tris.append([rings[ri][i], rings[ri+1][i2], rings[ri+1][i]])
			tris.append([rings[ri][i], rings[ri][i2], rings[ri+1][i2]])
		for tri in tris:
			var fn: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0]).normalized()
			if fn.y < 0.0: fn = -fn
			for v in tri: st.set_normal(fn); st.set_uv(Vector2(0.5, 0.5)); st.add_vertex(v)
	add_mesh(st.commit(), Transform3D.IDENTITY, c, tx); tri_total += n * 7
	if clasts:
		for ci in 3:
			var coff := fall * rng.randf_range(-r * 0.9, r * 1.15) + side * rng.randf_range(-r * 0.45, r * 0.45)
			blob(Vector3(cx + coff.x, _h(cx + coff.x, cz + coff.y) + 0.07, cz + coff.y), Vector3(rng.randf_range(0.18, 0.34), 0.10, rng.randf_range(0.16, 0.30)), Color("8f7355") if ci % 2 == 0 else Color("9a968c"))
func _face_patch(o: Vector3, right: Vector3, up: Vector3, w: float, h: float, seedv: int, cbase: Color, tx := "", pattern := 0) -> void:
	# R78: painted face patch - jagged multi-layer fan (irregular stepped edge, internal sub-tones), UV-mapped so stone/plaster texture shows inside
	var rng := RandomNumberGenerator.new(); rng.seed = seedv
	var nrm := right.cross(up).normalized()
	var layers := [[1.0, cbase, Vector2.ZERO], [0.60, cbase.darkened(0.25), Vector2(0.10, -0.08)], [0.38, cbase.lightened(0.14), Vector2(-0.20, 0.16)], [0.20, cbase.darkened(0.25), Vector2(0.28, 0.22)], [0.16, cbase.lightened(0.14), Vector2(-0.34, -0.24)]]
	for li in layers.size():
		var sc: float = layers[li][0]; var lc: Color = layers[li][1]; var off: Vector2 = layers[li][2]
		var cen := o + right * (off.x * w) + up * (off.y * h) + nrm * (0.045 + float(li) * 0.009)
		var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var n := 10; var pts: Array = []
		for i in n:
			var a := TAU * float(i) / float(n)
			var rr := rng.randf_range(0.55, 1.15)
			var lx := cos(a) * w * 0.5 * sc * rr; var ly := sin(a) * h * 0.5 * sc * rr
			pts.append(cen + right * lx + up * ly)
		for i in n:
			var p1: Vector3 = pts[i]; var p2: Vector3 = pts[(i + 1) % n]
			var fn := (p1 - cen).cross(p2 - cen)
			var order := [cen, p1, p2] if fn.dot(nrm) > 0.0 else [cen, p2, p1]
			for v in order:
				st.set_normal(nrm); st.set_uv(Vector2(0.5 + (v - cen).dot(right) / maxf(w, 0.01), 0.5 + (v - cen).dot(up) / maxf(h, 0.01))); st.add_vertex(v)
		add_mesh(st.commit(), house_xf if house_mode else Transform3D.IDENTITY, lc, tx); tri_total += n
	if pattern > 0: # R79: per-stone / pattern variation inside the panel (mortar = panel base showing in gaps)
		var tones := [cbase, cbase.darkened(0.25), cbase.lightened(0.14)]
		var rows := 4 if pattern == 3 else 3
		var cols := 3
		for rw2 in rows:
			for cl2 in (cols if pattern != 2 else 2):
				if pattern == 2 and rw2 > 2: break
				var fx := (float(cl2) - float(cols - 1) * 0.5) * w * (0.30 if pattern != 2 else 0.34) + (w * 0.07 if rw2 % 2 == 1 and pattern != 2 else 0.0)
				var fy := (float(rw2) - float(rows - 1) * 0.5) * h * (0.24 if pattern == 3 else 0.28)
				if pattern == 2: fx = rng.randf_range(-w * 0.28, w * 0.28); fy = rng.randf_range(-h * 0.26, h * 0.26)
				var scx := o + right * fx + up * fy + nrm * 0.098
				var hw3 := w * (0.17 if pattern == 3 else (0.15 if pattern == 1 else 0.20)); var hh3 := h * (0.10 if pattern == 3 else (0.13 if pattern == 1 else 0.20))
				var sst := SurfaceTool.new(); sst.begin(Mesh.PRIMITIVE_TRIANGLES)
				var sn := 6; var spts: Array = []
				var u0 := rng.randf(); var v0 := rng.randf()
				for i in sn:
					var a2 := TAU * float(i) / float(sn)
					var rr2 := rng.randf_range(0.78, 1.08)
					spts.append(scx + right * (cos(a2) * hw3 * rr2) + up * (sin(a2) * hh3 * rr2))
				for i in sn:
					var q1: Vector3 = spts[i]; var q2: Vector3 = spts[(i + 1) % sn]
					var fn2 := (q1 - scx).cross(q2 - scx)
					var ord2 := [scx, q1, q2] if fn2.dot(nrm) > 0.0 else [scx, q2, q1]
					for v2 in ord2:
						sst.set_normal(nrm); sst.set_uv(Vector2(u0 + (v2 - scx).dot(right) / maxf(w, 0.01), v0 + (v2 - scx).dot(up) / maxf(h, 0.01))); sst.add_vertex(v2)
				add_mesh(sst.commit(), house_xf if house_mode else Transform3D.IDENTITY, tones[(rw2 * 3 + cl2 + int(rng.randf() * 2.0)) % 3], tx); tri_total += sn
func _rock_prism(rw: float, rd: float, h: float, sd: float) -> ArrayMesh:
	# R103 irregular rock fragment: jittered hexagonal footprint, chamfered top inset,
	# per-corner thickness variation - non-parallel edges, broken corners, flat shaded.
	var verts := PackedVector3Array(); var norms := PackedVector3Array(); var uvs := PackedVector2Array(); var cols := PackedColorArray()
	var bc: Array = []; var tc: Array = []
	for i in 6:
		var a := float(i) * TAU / 6.0 + 0.35 * sin(sd * 3.7 + float(i) * 2.3)
		var jx := 0.95 + 0.20 * sin(sd * 5.1 + float(i) * 4.7)
		var jz := 0.95 + 0.20 * cos(sd * 4.3 + float(i) * 3.9)
		bc.append(Vector3(cos(a) * rw * jx, -h * 0.5, sin(a) * rd * jz))
		var ins := 0.82 + 0.10 * sin(sd * 2.9 + float(i) * 3.1)
		tc.append(Vector3(cos(a) * rw * jx * ins, h * 0.5 + h * 0.22 * sin(sd * 6.1 + float(i) * 5.3), sin(a) * rd * jz * ins))
	var cen := Vector3(0, h * 0.55, 0)
	for i in 6:
		var i2 := (i + 1) % 6
		for tri in [[bc[i], tc[i], tc[i2]], [bc[i], tc[i2], bc[i2]], [cen, tc[i2], tc[i]]]:
			var n: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0]).normalized()
			for v in tri: verts.append(v); norms.append(n); uvs.append(Vector2(0.5, 0.5)); cols.append(Color.WHITE)
	var arrays := []; arrays.resize(Mesh.ARRAY_MAX); arrays[Mesh.ARRAY_VERTEX] = verts; arrays[Mesh.ARRAY_NORMAL] = norms; arrays[Mesh.ARRAY_TEX_UV] = uvs; arrays[Mesh.ARRAY_COLOR] = cols
	var m := ArrayMesh.new(); m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays); return m

func _top_band() -> void:
	# R80 layer separators: dark valley band + treeline at mountain foot, pale crest edge (existing keys/canopy mesh)
	for vb in [Vector2(12.5,-0.5), Vector2(14.5,-3.5), Vector2(16,-6.5), Vector2(17,-9.5), Vector2(18.5,-12.5)]:
		blob(Vector3(vb.x, _h(vb.x, vb.y)+0.05, vb.y), Vector3(2.7, 0.07, 1.9), Color(0.10,0.16,0.05,0.42))
		box(Vector3(vb.x, _h(vb.x, vb.y)+0.55, vb.y), Vector3(0.16, 1.1, 0.16), Color("6b4a2c"))
		add_canopy(Transform3D(Basis.IDENTITY.scaled(Vector3(1.25, 0.85, 1.25)), Vector3(vb.x, _h(vb.x, vb.y)+1.45, vb.y)), Color("3d5c2a")) # R81 calmer mid-tone
		add_canopy(Transform3D(Basis.IDENTITY.scaled(Vector3(0.9, 0.65, 0.9)), Vector3(vb.x+0.9, _h(vb.x+0.9, vb.y)+1.05, vb.y+0.4)), Color("466636")) # R81 calmer mid-tone
	for ce in [Vector2(18,-15.5), Vector2(21,-16.5), Vector2(24,-15), Vector2(27,-13)]:
		blob(Vector3(ce.x, _h(ce.x, ce.y)+0.16, ce.y), Vector3(1.7, 0.20, 0.85), Color("e4e9ec"))
	# R81: passages where the wash thins - exposed warm rock + snow seated on the crest
	for rp81 in [[20.0,-14.5,2.9], [24.0,-13.0,1.1], [17.0,-15.0,2.0], [26.5,-15.5,0.85], [15.0,-13.0,1.5]]:
		_ground_patch(rp81[0], rp81[1], rp81[2], int(900.0 + rp81[0]*11.0), Color("8f7355"), Color("6e5638"))
	for sp81 in [[21.0,-15.5,1.30], [25.0,-12.0,0.55], [19.0,-13.0,0.90], [27.0,-14.0,1.60], [16.0,-16.0,0.65]]:
		_snow_patch(sp81[0], sp81[1], sp81[2], int(sp81[0]*17.0 + sp81[1]*31.0), Color("e4e9ec"))
	for tp8 in [Vector3(10,0,-16), Vector3(18,0,-16), Vector3(8,0,-11.8)]:
		_build_tree(tp8, Color("79c24d"), Color("a9dd77"))
	for sd2 in 3:
		var sx9 := 11.0+float(sd2)*3.4; var sz9 := -15.8+fmod(float(sd2)*0.9,1.6)
		blob(Vector3(sx9, _h(sx9,sz9)+0.08, sz9), Vector3(0.55,0.16,0.45), Color("eef2f4"))
		blob(Vector3(sx9+1.1, _h(sx9+1.1,sz9)+0.14, sz9), Vector3(0.5,0.36,0.5), Color("8f7a5f"))
	box(Vector3(15.5, _h(15.5,-15.2)+0.05, -15.2), Vector3(5.2,0.14,1.6), Color("8f7a5f"), 0.15)
	# worked terraces on the east mass face
	for tfi in 7:
		var tfx: float = [16.5, 17.5, 18.0, 16.0, 18.5, 15.5, 19.0][tfi]; var tfz: float = [-3.0, -7.0, -10.5, -1.5, -11.0, -6.0, -4.0][tfi]; var tfy := _h(tfx,tfz)+0.06
		_terrace(tfx, tfz, 3.6, 1.35, Color("86b83e") if tfi%2==0 else Color("b08d55"), "dirt" if tfi%2==1 else "")
		for cr2 in 4: box(Vector3(tfx-1.2+float(cr2)*0.8, _h(tfx-1.2+float(cr2)*0.8, tfz)+0.15, tfz), Vector3(0.45,0.08,1.1), Color("3f7020") if tfi%2==0 else Color("96683c"), 0.15)
	for etp in [Vector3(20.5,0,-5.5), Vector3(22.5,0,-9.5)]:
		_build_tree(etp, Color("79c24d"), Color("a9dd77"))
	for epp in [Vector3(19.5,_h(19.5,-4.2),-4.2), Vector3(21.8,_h(21.8,-8.2),-8.2)]:
		box(epp+Vector3(0,0.25,0), Vector3(0.5,0.5,0.5), Color("a67c4e"), 0.4); cyl(epp+Vector3(0.6,0.28,0.3), 0.22,0.25,0.55, Color("8a5f36"), 7)
	# painted cliff ledges: geometry bands across east face
	for ldi in 4:
		var ldx: float = [18.5, 19.5, 19.0, 20.5][ldi]; var ldz: float = [-4.5, -7.5, -10.0, -12.0][ldi]
		_terrace(ldx, ldz, 4.6, 0.85, Color("8f7355"), "rock")
		_terrace(ldx+0.4, ldz-1.1, 3.4, 0.7, Color("8f7355"), "rock")
	# jagged crest silhouette on NE ridge, snow only in crevices
	for cri in 7:
		var crx := 15.5 + float(cri)*1.35; var crz := -14.8 - fmod(float(cri)*0.8, 1.8); var cry := _h(crx,crz)
		add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(0.3,float(cri)*1.3,0.2)).scaled(Vector3(1.75,0.55,1.55)), Vector3(crx, cry-0.15, crz)), Color("96795c"), "rock") # R74: lowered/sunk crest humps, mine stays sole high point; tri_total += 128
		if cri % 2 == 0: blob(Vector3(crx+0.55, cry+0.40, crz+0.3), Vector3(0.34,0.13,0.3), Color("eef2f4")) # R74 reseated on lowered rock tops
	# R77: large rock-tone variation fans on the face + baked haze fans on the far crest
	for rfp in [Vector2(19,-6), Vector2(22,-9), Vector2(20.5,-12), Vector2(23.5,-6.5), Vector2(18,-10), Vector2(25,-10)]:
		_ground_patch(rfp.x, rfp.y, 1.4 + fmod(absf(rfp.x*0.41 + rfp.y*0.29), 1.8), int(900.0 + rfp.x*11.0), Color("8f7355"), Color("6e5638")) # R82 varied sizes
	for hfp in [Vector2(20,-15), Vector2(24,-14), Vector2(17,-16.5), Vector2(27,-12.5), Vector2(16,-14), Vector2(19,-17), Vector2(23,-16), Vector2(26,-14), Vector2(21,-13.5), Vector2(28,-11)]:
		_ground_patch(hfp.x, hfp.y, 1.9 + fmod(absf(hfp.x*0.37 + hfp.y*0.53), 1.7), int(950.0 + hfp.x*7.0), Color(0.72, 0.78, 0.76, 0.32), Color(0.78, 0.83, 0.80, 0.30)) # R82 varied sizes
	# R73: irregular gully snow on the camera-facing (SE) face (replaces R72 ovals, same areas)
	for snp3 in [Vector2(18,-4), Vector2(20,-6), Vector2(22,-5), Vector2(19,-8), Vector2(21,-9), Vector2(23,-8), Vector2(18.5,-11), Vector2(21,-12), Vector2(24,-11), Vector2(20,-3), Vector2(23,-13), Vector2(17,-6.5), Vector2(22,-2.5), Vector2(25,-7), Vector2(19.5,-13.5), Vector2(24.5,-4)]:
		var ssx: float = snp3.x; var ssz: float = snp3.y
		var sss := 0.95 + fmod(absf(ssx*1.37 + ssz*2.11), 0.9)
		_snow_patch(ssx, ssz, sss, int(ssx*17.0 + ssz*31.0), Color("eef2f4"))
		_snow_patch(ssx+0.8, ssz+0.6, sss*0.55, int(ssx*23.0 - ssz*13.0), Color("e4e9ec"))
	# R103 shattered rock ledges (de-rectangularised R102 slabs): each ledge is 2-3 irregular
	# prism fragments (jittered hex footprint, chamfered tops, varied thickness) split by shadow
	# gaps and offset - no two read as cut boxes. R102 footprint scale kept (judge-scale break),
	# flat slope-matching grey-tan family kept. Kept clear of mine/watchtower/switchback.
	for li in 14:
		var lx: float = [18.0,21.5,25.0,17.0,20.5,24.0,17.5,21.0,25.5,9.0,11.0,27.0,19.0,23.0][li]
		var lz: float = [-6.5,-7.5,-8.5,-9.0,-10.0,-11.0,-12.5,-13.0,-13.5,-8.0,-13.5,-10.5,-14.5,-15.0][li]
		var lw: float = [4.2,3.4,4.6,2.8,5.0,3.2,3.8,4.4,2.6,3.0,4.0,3.6,3.0,4.2][li]
		var lh: float = 0.7 + 0.45*fmod(float(li)*0.61, 1.0)
		var lc: Color = [Color("9a8a76"), Color("8a7a66"), Color("a89478")][li%3]
		var lsd := float(li) * 7.13 + 3.7
		var yaw := 0.30*sin(float(li)*2.1)
		var fpos := [Vector3(lx - lw*0.20, _h(lx - lw*0.20, lz) + lh*0.16, lz), Vector3(lx + lw*0.30, _h(lx + lw*0.30, lz + 0.2) + lh*0.10, lz + 0.2)]
		add_mesh(_rock_prism(lw*0.30, 0.85 + 0.35*fmod(lsd*0.47,1.0), lh, lsd), Transform3D(Basis.from_euler(Vector3(0.09*cos(lsd*1.4), yaw, 0.10*sin(lsd*1.9))), fpos[0]), lc); tri_total += 18
		add_mesh(_rock_prism(lw*0.19, 0.70 + 0.30*fmod(lsd*0.71,1.0), lh*0.78, lsd + 11.3), Transform3D(Basis.from_euler(Vector3(0.07*sin(lsd*2.2), yaw + 0.22, 0.12*cos(lsd*1.1))), fpos[1]), lc); tri_total += 18
		if li % 3 == 0: # stacked shattered fragment on the main piece, same colour key
			add_mesh(_rock_prism(lw*0.20, 0.62, lh*0.55, lsd + 23.9), Transform3D(Basis.from_euler(Vector3(0.10, yaw + 0.35, 0.08)), fpos[0] + Vector3(0.3*sin(lsd*3.1), lh*0.72, 0.25*cos(lsd*2.7))), lc); tri_total += 18
	# R100: broken outcrop relief on the face (existing rock keys, seated, away from mine focal area)
	for oc in [[17.2,-3.2,2.2],[19.8,-5.6,1.7],[21.5,-8.4,2.4],[18.6,-10.8,1.6],[23.8,-11.5,1.9],[16.4,-7.6,1.5],[22.8,-3.8,1.4],[20.4,-13.2,2.0]]:
		add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(0.25, oc[0]*1.37, 0.18)).scaled(Vector3(oc[2], oc[2]*0.42, oc[2]*0.66)), Vector3(oc[0], _h(oc[0], oc[1])-0.18, oc[1])), Color("8f7355") if int(oc[0]) % 2 == 0 else Color("96795c"), "rock"); tri_total += 128
	# talus cones + outcrops breaking the wall plane (merged rock key)
	for tli in 6:
		var tlx: float = [16.8, 17.5, 16.5, 18.0, 17.0, 18.5][tli]; var tlz: float = [-2.0, -5.0, -8.0, -10.0, -12.0, -3.5][tli]
		var tls: float = [1.5, 2.1, 1.7, 2.2, 1.6, 1.9][tli]
		add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(0.2, float(tli)*1.1, 0.15)).scaled(Vector3(tls, tls*0.48, tls*0.8)), Vector3(tlx, _h(tlx,tlz)+0.12, tlz)), Color("8f7355"), "rock"); tri_total += 128
	for ldi2 in 3:
		var ldx2: float = [20.0, 20.5, 19.8][ldi2]; var ldz2: float = [-6.0, -9.0, -12.0][ldi2]
		_terrace(ldx2, ldz2, 3.8, 1.1, Color("8f7355"), "rock")
	# BIG ribs: stepped large rocks base->mid->upper at 3 face lines + big talus fan
	for rbi in 3:
		var rbz: float = [-5.0, -8.5, -12.0][rbi]
		for rst in 3:
			var rbx: float = [18.3, 19.4, 20.2][rst]; var rbs: float = [2.1, 1.8, 1.5][rst]
			add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(0.25, float(rbi)*1.4+float(rst), -0.2)).scaled(Vector3(rbs, rbs*0.85, rbs*0.95)), Vector3(rbx, _h(rbx,rbz)+0.15, rbz + float(rst)*0.35)), Color("8f7355"), "rock"); tri_total += 128
	for tfi2 in 3:
		var tfx2: float = [16.8, 17.6, 16.5][tfi2]; var tfz2: float = [-6.0, -8.5, -10.5][tfi2]
		add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(0.15, float(tfi2)*1.9, 0.1)).scaled(Vector3(3.1, 1.35, 2.5)), Vector3(tfx2, _h(tfx2,tfz2)+0.1, tfz2)), Color("8f7355"), "rock"); tri_total += 128
	for ldi3 in 2:
		var ldx3: float = [19.5, 20.0][ldi3]; var ldz3: float = [-7.0, -11.0][ldi3]
		_terrace(ldx3, ldz3, 5.6, 1.8, Color("8f7355"), "rock")
	# CAMERA-FACING south-east plane breaks (the wall filling frame right edge)
	for sri in 3:
		var srx: float = [23.0, 25.5, 28.0][sri]
		for sst in 3:
			var srz: float = [-2.0, 1.0, 4.0][sst]; var srs: float = [2.0, 1.7, 1.4][sst]
			add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(-0.3, float(sri)*1.6+float(sst)*0.8, 0.25)).scaled(Vector3(srs, srs*0.85, srs)), Vector3(srx, _h(srx,srz)+0.15, srz)), Color("8f7355"), "rock"); tri_total += 128
	for sli in 2:
		var slx: float = [24.0, 26.0][sli]; var slz: float = [2.0, -1.5][sli]
		_terrace(slx, slz, 5.2, 1.7, Color("8f7355"), "rock")
	for stf in 3:
		var stx: float = [23.0, 26.0, 21.0][stf]; var stz: float = [8.0, 6.0, 10.0][stf]
		add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(0.2, float(stf)*2.2, 0.1)).scaled(Vector3(2.9, 1.25, 2.3)), Vector3(stx, _h(stx,stz)+0.1, stz)), Color("8f7355"), "rock"); tri_total += 128
	# switchback shelf on the south-east face, retaining edge toward camera (+z)
	var ssp := [Vector2(20.0,4.5), Vector2(23.0,1.5), Vector2(21.5,-1.5), Vector2(24.5,-4.5)]
	for ssi in ssp.size()-1:
		var ssa: Vector2 = ssp[ssi]; var ssb: Vector2 = ssp[ssi+1]; var ssmid := (ssa+ssb)*0.5; var ssdir := ssb-ssa
		var ssy: float = (_h(ssa.x,ssa.y) + _h(ssb.x,ssb.y))*0.5 + 0.22
		var ssperp := Vector2(-ssdir.normalized().y, ssdir.normalized().x)
		if ssperp.y < 0.0: ssperp = -ssperp
		box(Vector3(ssmid.x, ssy, ssmid.y), Vector3(1.9,0.22,ssdir.length()+0.7), Color("b99a68"), atan2(ssdir.x, ssdir.y), 0, 0, "dirt")
		box(Vector3(ssmid.x+ssperp.x*0.95, ssy-0.28, ssmid.y+ssperp.y*0.95), Vector3(0.32,0.55,ssdir.length()+0.6), Color("8f7355"), atan2(ssdir.x, ssdir.y), 0, 0, "rock")
	for smw in [[Vector3(22.0,0,2.0), Color("d43a2a")], [Vector3(24.0,0,-3.0), Color("2f62b8")]]:
		var smp: Vector3 = smw[0]; smp.y = _h(smp.x, smp.z) + 0.25; _mini(smp, smw[1])
	# UPPER third breaks: plateau-edge ribs/ledges (z<-4)
	for uri in 3:
		var urx: float = [23.0, 25.5, 24.0][uri]; var urz: float = [-7.0, -10.0, -13.0][uri]
		for ust in 2:
			var urs: float = [1.9, 1.5][ust]
			add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(-0.25, float(uri)*1.8+float(ust), 0.3)).scaled(Vector3(urs, urs*0.85, urs)), Vector3(urx+float(ust)*1.2, _h(urx+float(ust)*1.2,urz)+0.15, urz)), Color("8f7355"), "rock"); tri_total += 128
	for uli in 2:
		var ulx: float = [24.0, 26.0][uli]; var ulz: float = [-8.0, -12.0][uli]
		_terrace(ulx, ulz, 5.0, 1.7, Color("8f7355"), "rock")
	# wall-foot blend: climbing fields + base trees between village and wall
	for bfi in 3:
		var bfx: float = [15.0, 16.0, 14.0][bfi]; var bfz: float = [-1.0, 2.0, 4.0][bfi]; var bfy := _h(bfx,bfz)+0.06
		_terrace(bfx, bfz, 3.4, 1.3, Color("86b83e") if bfi%2==0 else Color("b08d55"), "dirt" if bfi%2==1 else "")
		for bcr in 4: box(Vector3(bfx-1.15+float(bcr)*0.75, _h(bfx-1.15+float(bcr)*0.75, bfz)+0.15, bfz), Vector3(0.42,0.08,1.05), Color("3f7020") if bfi%2==0 else Color("96683c"), 0.18)
	for btp in [Vector3(16.5,0,-3.5), Vector3(18.0,0,0.5)]:
		_build_tree(btp, Color("79c24d"), Color("a9dd77"))
	# switchback path ON the face + workers
	var swp := [Vector2(15.5,-0.5), Vector2(18.0,-2.8), Vector2(16.2,-5.2), Vector2(19.0,-7.2), Vector2(17.2,-9.8), Vector2(19.8,-12.0)]
	for swi in swp.size()-1:
		var sa: Vector2 = swp[swi]; var sb: Vector2 = swp[swi+1]; var smid := (sa+sb)*0.5; var sdir := sb-sa
		var sy: float = (_h(sa.x,sa.y) + _h(sb.x,sb.y))*0.5 + 0.22
		var sang := atan2(sdir.x, sdir.y)
		box(Vector3(smid.x, sy, smid.y), Vector3(1.9,0.22,sdir.length()+0.7), Color("b99a68"), sang, 0, 0, "dirt")
		var sperp2 := Vector2(-sdir.normalized().y, sdir.normalized().x)
		box(Vector3(smid.x+sperp2.x*0.95, sy-0.28, smid.y+sperp2.y*0.95), Vector3(0.32,0.55,sdir.length()+0.6), Color("8f7355"), sang, 0, 0, "rock")
		blob(Vector3(sa.x, _h(sa.x,sa.y)+0.3, sa.y), Vector3(0.2,0.13,0.17), Color("9a968c")); blob(Vector3(sb.x, _h(sb.x,sb.y)+0.3, sb.y), Vector3(0.2,0.13,0.17), Color("9a968c"))
	for fmw in [[Vector3(17.6,0,-4.0), Color("d43a2a")], [Vector3(18.8,0,-8.0), Color("2f62b8")], [Vector3(17.8,0,-11.0), Color("3f7d3a")], [Vector3(16.4,0,-2.0), Color("2f62b8")], [Vector3(19.4,0,-12.6), Color("d43a2a")]]:
		var fmp: Vector3 = fmw[0]; fmp.y = _h(fmp.x, fmp.z) + 0.05; _mini(fmp, fmw[1])
	# corner rock mass covering far-plane transition bottom-right
	add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(0.3,0.7,0.2)).scaled(Vector3(1.9,1.05,1.6)), Vector3(26, _h(26,-1)+0.25, -1)), Color("8f7355"), "rock"); tri_total += 128
	add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(-0.2,1.9,0.4)).scaled(Vector3(1.35,0.75,1.1)), Vector3(23.5, _h(23.5,3)+0.2, 3)), Color("8f7355"), "rock"); tri_total += 128
	add_mesh(flat_sphere(), Transform3D(Basis.from_euler(Vector3(0.5,2.8,-0.3)).scaled(Vector3(1.5,0.85,1.25)), Vector3(28, _h(28,-4)+0.2, -4)), Color("8f7355"), "rock"); tri_total += 128
	for cf4 in 2:
		var cx9 := 6.5+float(cf4)*7.0; var cz9 := -13.6
		_terrace(cx9, cz9, 5.2, 1.6, Color("86b83e") if cf4%2==0 else Color("b08d55"), "")
	_slope_zones() # R120: scree/exposure/grass/snow-approach/mine-apron zones seated over this slope content
func _slope_zones() -> void:
	# R120 slope surface zones (all seated on _h, merged into existing keys, no building/tree moves)
	# Exposed-rock washes following the fall line between ledge clusters.
	for rp120 in [Vector3(19.2,-5.7,2.4), Vector3(22.7,-7.2,2.8), Vector3(18.3,-11.8,2.5), Vector3(24.6,-12.8,2.9), Vector3(16.2,-8.6,2.1), Vector3(26.8,-9.2,2.4)]:
		_slope_fan(rp120.x, rp120.y, rp120.z, int(12100.0 + rp120.x * 13.0 - rp120.y * 7.0), Color("8f7355"), 1.9, 0.0, true, "rock")
		_slope_fan(rp120.x, rp120.y, rp120.z * 0.56, int(12200.0 + rp120.x * 17.0), Color("6e5638"), 1.7, 0.018, false)
	# Scree fans directly downhill of the R102/R103 shattered ledges (same centres, offset down-slope).
	for li120 in [Vector3(18.0,-6.5,1.9), Vector3(21.5,-7.5,1.7), Vector3(25.0,-8.5,2.1), Vector3(17.0,-9.0,1.6), Vector3(20.5,-10.0,2.2), Vector3(24.0,-11.0,1.8), Vector3(17.5,-12.5,1.9), Vector3(21.0,-13.0,2.0), Vector3(25.5,-13.5,1.6), Vector3(9.0,-8.0,1.6), Vector3(11.0,-13.5,2.0), Vector3(27.0,-10.5,1.9), Vector3(19.0,-14.5,1.7), Vector3(23.0,-15.0,2.0)]:
		var scc: Color = [Color("a89a80"), Color("9a8a76"), Color("8a7a66")][int(absf(li120.x + li120.y)) % 3]
		_slope_fan(li120.x - 0.4, li120.y + 0.95, li120.z, int(12300.0 + li120.x * 19.0 - li120.y * 11.0), Color("c9b18a"), 1.65, 0.006, true)
		_slope_fan(li120.x - 0.4, li120.y + 0.95, li120.z * 0.55, int(12350.0 + li120.x * 19.0 - li120.y * 11.0), scc, 1.55, 0.024, false)
	# Grass encroachment tongues climbing gullies from the slope foot (kept off the mine itself).
	for gt120 in [Vector3(15.6,-3.8,1.25), Vector3(20.2,-9.2,1.45), Vector3(23.2,-11.8,1.35), Vector3(14.8,-14.2,1.20), Vector3(25.9,-6.8,1.30), Vector3(12.8,-6.2,1.10)]:
		_slope_fan(gt120.x, gt120.y, gt120.z, int(12400.0 + gt120.x * 23.0 - gt120.y * 13.0), Color("7fae4a"), 2.15, 0.010, false)
		_slope_fan(gt120.x, gt120.y, gt120.z * 0.55, int(12500.0 + gt120.x * 29.0), Color("4e7d26"), 1.95, 0.026, false)
	# Pale scree approach below the crest snow (rock wash, snow geometry untouched).
	for sn120 in [Vector3(20.5,-14.8,1.45), Vector3(25.2,-13.8,1.30), Vector3(17.8,-15.4,1.20), Vector3(27.5,-12.0,1.35)]:
		_slope_fan(sn120.x, sn120.y, sn120.z, int(12600.0 + sn120.x * 31.0 - sn120.y * 17.0), Color("a89a80"), 1.55, 0.012, true)
		_slope_fan(sn120.x, sn120.y, sn120.z * 0.52, int(12700.0 + sn120.x * 37.0), Color("9a968c"), 1.45, 0.028, false)
	# Camera-facing southwest face: talus below the cliff planes + scree on the open face band.
	for tf120 in [Vector3(9.0,-9.6,1.8), Vector3(14.0,-10.6,2.0), Vector3(6.0,-8.8,1.5), Vector3(16.8,-4.6,1.7), Vector3(19.2,-8.9,1.9), Vector3(17.0,-11.6,1.8)]:
		_slope_fan(tf120.x, tf120.y, tf120.z, int(12900.0 + tf120.x * 41.0 - tf120.y * 19.0), Color("c9b18a"), 1.70, 0.008, true)
		_slope_fan(tf120.x, tf120.y, tf120.z * 0.55, int(12950.0 + tf120.x * 43.0), Color("9a8a76"), 1.60, 0.026, false)
	_slope_fan(13.4, -4.6, 1.20, 12980, Color("7fae4a"), 2.05, 0.010, false) # grass tongue on the open face
	# Worn mine apron downhill of the entrance/cart, tying mine to the stone road.
	_slope_fan(14.3, -10.1, 2.05, 12801, Color("8a6c42"), 1.75, 0.014, true)
	_slope_fan(14.3, -10.1, 1.15, 12802, Color("a8895a"), 1.60, 0.030, false)
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
	box(wp+Vector3(-0.35,2.32,0), Vector3(0.95,0.09,0.8), Color("a05a44"), 0, 0.42, 0); box(wp+Vector3(0.35,2.32,0), Vector3(0.95,0.09,0.8), Color("a05a44"), 0, -0.42, 0)
	# sacks + crates near houses/market
	for sp in [Vector3(-1.5,0,7.1), Vector3(2.6,0,0.6), Vector3(6.8,0,-2.4), Vector3(-7.8,0,3.6)]:
		blob(sp+Vector3(0,0.28,0), Vector3(0.34,0.3,0.34), Color("a67c4e")); blob(sp+Vector3(0.3,0.2,0.15), Vector3(0.26,0.22,0.26), Color("a67c4e"))
		box(sp+Vector3(-0.45,0.3,-0.2), Vector3(0.55,0.55,0.55), Color("a67c4e"), 0.3)
	# fence lines
	for fx in 6: box(Vector3(-9.5+float(fx)*0.85,0.4,8.6), Vector3(0.12,0.8,0.12), Color("7a5a36"))
	box(Vector3(-7.4,0.62,8.6), Vector3(4.6,0.1,0.1), Color("8a6742"))
	# gardens + door stone paths at houses, laundry lines, scattered barrels/crates
	var houses := [Vector3(5.4,0,-0.4), Vector3(-3.4,0,4.6), Vector3(7.2,0,-3.8), Vector3(-8.6,0,4.8), Vector3(9.6,0,1.8), Vector3(-6.5,0,-10.0), Vector3(12.5,0,11.0), Vector3(-5.5,0,10.8), Vector3(13.5,0,4.5)]
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
	return # R69: 1000 grass tufts removed - floating green specks (Black #4)
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
	cyl(mp+Vector3(0,0.02,0), 0.36,0.36,0.02, Color(0.09,0.15,0.04,0.32), 10) # R119 contact disc (existing key)
	box(mp+Vector3(-0.11,0.27,0), Vector3(0.16,0.54,0.18), Color("4a3421")); box(mp+Vector3(0.11,0.27,0), Vector3(0.16,0.54,0.18), Color("4a3421"))
	box(mp+Vector3(0,0.76,0), Vector3(0.50,0.50,0.30), tc)
	blob(mp+Vector3(0,1.24,0), Vector3(0.21,0.22,0.21), Color("e8b88a"))
	cyl(mp+Vector3(0,1.41,0), 0.29,0.31,0.08, Color("c9a86a"), 8)
	box(mp+Vector3(0.36,0.80,0.10), Vector3(0.09,0.62,0.09), Color("6b4a2c"), 0, 0.5, 0)
	var g119 := absi(int(mp.x*7.0 + mp.z*13.0)) % 3 # R119 seeded carried goods (existing keys)
	if g119 == 0: blob(mp+Vector3(-0.36,0.74,0.05), Vector3(0.20,0.25,0.20), Color("c9b18a"))
	elif g119 == 1: box(mp+Vector3(0,0.80,-0.25), Vector3(0.38,0.38,0.18), Color("a67c4e"))
func _cone_relief(cc: Vector3, h: float, rb: float, rt: float, roofc: Color, seedv: int, tiles: bool) -> void:
	# R95: rings broken into staggered gapped tile segments (no continuous bands) + denser irregular tiles (existing keys)
	var rng := RandomNumberGenerator.new(); rng.seed = seedv
	var tones := [roofc.darkened(0.22), roofc.lightened(0.15), roofc.darkened(0.46).lerp(Color((roofc.darkened(0.46).r+roofc.darkened(0.46).g+roofc.darkened(0.46).b)/3.0, (roofc.darkened(0.46).r+roofc.darkened(0.46).g+roofc.darkened(0.46).b)/3.0, (roofc.darkened(0.46).r+roofc.darkened(0.46).g+roofc.darkened(0.46).b)/3.0), 0.35), roofc] # R123 darkest relief tone desaturated toward its grey
	var slope := atan2(rb - rt, h)
	for t in [0.16, 0.36, 0.56, 0.76, 0.90]:
		var ry: float = cc.y + (t - 0.5) * h; var rr: float = lerpf(rb, rt, t)
		var nseg := clampi(int(6.283 * rr / 0.30), 5, 10)
		var off95 := rng.randf() * TAU
		for k in nseg:
			if rng.randf() < 0.14: continue # gap where individual tiles take over
			var th := off95 + TAU * float(k) / float(nseg) + rng.randf_range(-0.05, 0.05)
			var tp := Vector3(cc.x + sin(th) * (rr + 0.028), ry + rng.randf_range(-0.035, 0.035), cc.z + cos(th) * (rr + 0.028))
			box(tp, Vector3(TAU * rr / float(nseg) * rng.randf_range(0.72, 1.0), 0.055, rng.randf_range(0.13, 0.19)), tones[(k + int(t * 10.0)) % 4], th, rng.randf_range(-0.05, 0.05), -slope)
	if tiles:
		for t in [0.24, 0.44, 0.64, 0.84]:
			var ty: float = cc.y + (t - 0.5) * h; var tr2: float = lerpf(rb, rt, t)
			for k in 7:
				if rng.randf() < 0.10: continue
				var th := -1.25 + float(k) * 0.47 + rng.randf_range(-0.07, 0.07)
				var tp := Vector3(cc.x + sin(th) * (tr2 + 0.045), ty + rng.randf_range(-0.03, 0.03), cc.z + cos(th) * (tr2 + 0.045))
				box(tp, Vector3(rng.randf_range(0.17, 0.28), 0.06, rng.randf_range(0.13, 0.21)), tones[(k + int(t * 10.0) + 1) % 4], th, rng.randf_range(-0.06, 0.06), -slope)
func _build_castle(p: Vector3, stone: Color, roof: Color) -> void:
	add_mesh(noised_box(4.7,2.4,3.6,0.07,4.2), Transform3D(Basis.IDENTITY, p+Vector3(0,1.2,0)), stone, "stone"); tri_total += 108
	for cy in [0.55, 1.05, 1.55]: box(p+Vector3(0,cy,1.82), Vector3(4.6,0.07,0.05), stone.darkened(0.12))
	add_mesh(noised_box(1.9,2.7,1.9,0.06,7.9), Transform3D(Basis.IDENTITY, p+Vector3(-0.25,2.35,-0.15)), stone.lightened(0.06), "stone"); tri_total += 108 # R90 keep warmer family; R116 keep offset in plan
	var toff := [Vector2(-2.05,-1.60), Vector2(1.70,-1.30), Vector2(-1.65,1.55), Vector2(2.10,1.35)] # R116 irregular tower plan (was identical +/-1.85,+/-1.45)
	var trad := [0.64, 0.54, 0.50, 0.68] # R116 varied tower footprints
	# stepped side wing + deformed prism roof over rear keep: uneven central roofline
	box(p+Vector3(2.95,0.85,0.55), Vector3(1.35,1.7,2.3), stone, 0,0,0, "stone")
	cyl(p+Vector3(2.95,2.15,0.55), 0.98,0.08,0.9, roof, 9, "roofp"); _cone_relief(p+Vector3(2.95,2.15,0.55), 0.9, 0.98, 0.08, roof, 9460, false)
	roof2(p+Vector3(-0.6,2.38,-0.85), 3.6, 1.7, 0.95, 0.18, roof)
	cyl(p+Vector3(-0.25,4.85,-0.15), 1.05,0.05,2.4, roof, 10, "roofp"); _cone_relief(p+Vector3(-0.25,4.85,-0.15), 2.4, 1.05, 0.05, roof, 9450, true)
	var ths := [3.15, 3.95, 2.85, 4.05] # R115 varied tower heights (was 3.05-3.75 near-uniform)
	var cnh := [1.50, 1.90, 1.30, 2.00] # R115 varied cone heights/pitches, seated on each tower top
	var cnr := [0.70, 0.76, 0.66, 0.80]
	for oi2 in 4:
		var off: Vector2 = toff[oi2]
		cyl(p+Vector3(off.x,ths[oi2]/2.0,off.y), trad[oi2],trad[oi2]*0.78,ths[oi2], stone.darkened(0.07), 8, "stone") # R90 towers cooler family
		cyl(p+Vector3(off.x,ths[oi2]+cnh[oi2]*0.5-0.12,off.y), cnr[oi2],0.02,cnh[oi2], roof, 10, "roofp"); _cone_relief(p+Vector3(off.x,ths[oi2]+cnh[oi2]*0.5-0.12,off.y), cnh[oi2], cnr[oi2], 0.02, roof, 9400+oi2, true)
		cyl(p+Vector3(off.x,ths[oi2]-0.35,off.y), trad[oi2]*1.45,trad[oi2]*1.18,0.14, roof.darkened(0.22), 10); cyl(p+Vector3(off.x,ths[oi2]-0.02,off.y), trad[oi2]*1.02,trad[oi2]*0.80,0.14, roof.darkened(0.22), 10)
		for ts in 3: box(p+Vector3(off.x+trad[oi2]+0.05,1.0+float(ts)*0.8,off.y), Vector3(0.1,0.65,0.34), stone.darkened(0.12))
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
	# R83: modelled stone relief - keep front blocks + tower front stones (real shadow gaps, existing keys)
	var rng85 := RandomNumberGenerator.new(); rng85.seed = 8501 # R85 irregular hand-laid relief
	for ry83 in 5:
		for cx83 in 4:
			if (cx83 + ry83) % 4 == 2: continue
			var sw85 := rng85.randf_range(0.30, 0.52); var sh85 := rng85.randf_range(0.22, 0.36); var st85 := rng85.randf_range(0.05, 0.11)
			var tilt85 := rng85.randf_range(-0.05, 0.05) if rng85.randf() > 0.18 else rng85.randf_range(-0.16, 0.16)
			box(p+Vector3(-0.70+float(cx83)*0.47 + (0.10 if ry83%2==1 else 0.0) + rng85.randf_range(-0.035, 0.035), 1.70+float(ry83)*0.38 + rng85.randf_range(-0.03, 0.03), 0.92+st85*0.5), Vector3(sw85, sh85, st85), stone.darkened(0.12) if (cx83+ry83)%2==0 else stone.lightened(0.07), 0, tilt85, 0, "stone")
	for oi83 in 4:
		var off83: Vector2 = toff[oi83]
		for sy83 in 5:
			box(p+Vector3(off83.x + (float(sy83%2)*0.24-0.12) + rng85.randf_range(-0.03, 0.03), 0.65+float(sy83)*0.55 + rng85.randf_range(-0.03, 0.03), off83.y+trad[oi83]+0.04), Vector3(rng85.randf_range(0.26, 0.44), rng85.randf_range(0.20, 0.34), rng85.randf_range(0.05, 0.11)), stone.darkened(0.12) if sy83%2==0 else stone.lightened(0.07), 0, rng85.randf_range(-0.05, 0.05), 0, "stone")
			box(p+Vector3(off83.x - (float(sy83%2)*0.24-0.12) + rng85.randf_range(-0.03, 0.03), 0.92+float(sy83)*0.55 + rng85.randf_range(-0.03, 0.03), off83.y+trad[oi83]+0.04), Vector3(rng85.randf_range(0.24, 0.40), rng85.randf_range(0.20, 0.32), rng85.randf_range(0.05, 0.11)), stone.lightened(0.07) if sy83%2==0 else stone.darkened(0.12), 0, rng85.randf_range(-0.05, 0.05), 0, "stone")
	# R78: castle patches as jagged textured fans (R77 flat rectangles replaced); tower shadow strips with internal stone insets
	for pp7 in [[-1.45, 0.95, 1.35, 0.90, 101], [0.55, 1.35, 1.10, 0.75, 113], [1.55, 0.62, 0.90, 0.60, 127], [-0.35, 0.55, 1.00, 0.55, 139]]:
		_face_patch(p+Vector3(pp7[0], pp7[1], 1.845), Vector3(1,0,0), Vector3(0,1,0), pp7[2], pp7[3], int(pp7[4]), stone.darkened(0.17), "stone", 1)
	for pp8 in [[-0.80, 2.75, 0.85, 0.70, 151], [0.20, 3.05, 0.75, 0.60, 163]]:
		_face_patch(p+Vector3(pp8[0], pp8[1], 0.815), Vector3(1,0,0), Vector3(0,1,0), pp8[2], pp8[3], int(pp8[4]), stone.darkened(0.17), "stone", 1)
	for oi3 in 4:
		var off3: Vector2 = toff[oi3]
		box(p+Vector3(off3.x+trad[oi3]*0.72, ths[oi3]*0.48, off3.y), Vector3(0.20, ths[oi3]*0.92, 0.80), stone.darkened(0.30), 0, 0, 0, "stone")
		for ts8 in 5:
			box(p+Vector3(off3.x+trad[oi3]*0.88, 0.62+float(ts8)*0.58, off3.y-0.19+float(ts8%2)*0.20), Vector3(0.03, 0.26, 0.32), stone.darkened(0.12) if ts8%2==0 else stone.lightened(0.07), 0, 0, 0, "stone")
	# battlements along side top edges + centre tower roof ring
	for bz2 in [-1.2,-0.4,0.4,1.2]:
		box(p+Vector3(2.32,2.52,bz2), Vector3(0.16,0.3,0.34), stone); box(p+Vector3(-2.32,2.52,bz2), Vector3(0.16,0.3,0.34), stone)
	cyl(p+Vector3(-0.25,3.62,-0.15), 1.0,0.86,0.15, roof.darkened(0.22), 10)
	var tops115 := [4.53, 5.73, 4.03, 5.93] # cone apex per tower (ths + cone - overlap)
	for sp3i in 2:
		var sp3: Vector2 = [toff[0], toff[3]][sp3i]; var sty: float = tops115[[0, 3][sp3i]]
		cyl(p+Vector3(sp3.x,sty+0.28,sp3.y), 0.10,0.13,0.8, stone, 6, "stone"); cyl(p+Vector3(sp3.x,sty+0.88,sp3.y), 0.22,0.02,0.5, roof, 7, "roofp")
	for pn3i in 2: # R115 pennants on the remaining two cone tops (existing pole/pennant keys)
		var pn3: Vector2 = [toff[1], toff[2]][pn3i]; var pty: float = tops115[[1, 2][pn3i]]
		box(p+Vector3(pn3.x,pty+0.30,pn3.y), Vector3(0.06,0.72,0.06), Color("6b4423")); box(p+Vector3(pn3.x+0.30,pty+0.52,pn3.y), Vector3(0.55,0.32,0.04), Color("d43a2a"))
	# R115 front-tower hanging banners (existing banner key, varied height/size) + keep-roof dormer turret
	box(p+Vector3(toff[2].x,2.30,toff[2].y+trad[2]+0.06), Vector3(0.50,1.05,0.06), Color("c22e22")); box(p+Vector3(toff[3].x,1.95,toff[3].y+trad[3]+0.06), Vector3(0.44,0.85,0.06), Color("c22e22"))
	cyl(p+Vector3(-1.05,3.02,1.50), 0.30,0.26,1.15, stone, 8, "stone"); cyl(p+Vector3(-1.05,3.95,1.50), 0.44,0.02,0.80, roof, 8, "roofp")
	cyl(p+Vector3(1.7,3.3,-1.0), 0.42,0.46,1.6, stone, 8, "stone"); cyl(p+Vector3(1.7,4.45,-1.0), 0.55,0.02,0.8, roof, 8, "roofp"); _cone_relief(p+Vector3(1.7,4.45,-1.0), 0.8, 0.55, 0.02, roof, 9470, false)
	box(p+Vector3(-1.6,1.7,2.08), Vector3(0.55,1.15,0.07), Color("c22e22")); box(p+Vector3(1.6,1.7,2.08), Vector3(0.55,1.15,0.07), Color("c22e22"))
	for bt in [Vector2(-2.55,-1.95),Vector2(2.55,-1.95),Vector2(-2.55,1.95),Vector2(2.55,1.95)]: box(p+Vector3(bt.x,0.55,bt.y), Vector3(0.55,1.1,0.55), stone.darkened(0.14), 0.4, 0, 0, "stone")
	for wf in [Vector2(-1.9,1.35),Vector2(1.9,1.35),Vector2(0,2.6)]:
		box(p+Vector3(wf.x,wf.y,2.07), Vector3(0.52,0.68,0.08), Color("e8c87a")); box(p+Vector3(wf.x,wf.y,2.11), Vector3(0.36,0.5,0.05), Color("3a2c1c"))
	box(p+Vector3(0.35,0.7,2.08), Vector3(0.95,1.4,0.15), Color("4a3421"))
	var gm := CylinderMesh.new(); gm.bottom_radius=0.48; gm.top_radius=0.48; gm.height=0.16; gm.radial_segments=10
	add_mesh(gm, Transform3D(Basis.from_euler(Vector3(PI/2.0,0,0)), p+Vector3(0.35,1.42,2.09)), Color("4a3421")); tri_total += 40
	# gatehouse protrusion + annex tower (silhouette complexity)
	box(p+Vector3(0.35,0.85,2.45), Vector3(1.7,1.7,0.85), stone, 0,0,0, "stone")
	cyl(p+Vector3(0.35,2.15,2.45), 1.15,0.35,0.85, roof, 8, "roofp")
	cyl(p+Vector3(-3.35,1.7,0.3), 0.82,0.82,3.4, stone, 8, "stone")
	cyl(p+Vector3(-3.35,4.15,0.3), 1.05,0.03,1.35, roof, 9, "roofp")
	for bx2 in [-1.2,-0.6,0.0,0.6,1.2]: box(p+Vector3(bx2,2.42,-1.82), Vector3(0.34,0.32,0.16), stone.darkened(0.1))
	box(p+Vector3(-0.25,3.9,-0.15), Vector3(0.08,1.2,0.08), Color("6b4423")); box(p+Vector3(0.20,4.3,-0.15), Vector3(0.8,0.45,0.05), Color("d43a2a"))
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
	var rng105 := RandomNumberGenerator.new(); rng105.seed = 10500 + absi(int(p.x*37.0 + p.z*53.0)) # R105 per-house hand-made irregularity
	var dense105 := rng105.randf() # framing density varies per house (sparse <-> dense)
	box(Vector3(0,0.15,0), Vector3(2.5*wf,0.3,2.0), Color("9a968c"))
	if vi == 1:
		var wm := CylinderMesh.new(); wm.bottom_radius = 1.0; wm.top_radius = 0.90; wm.height = wh; wm.radial_segments = 4; wm.rings = 1
		add_mesh(wm, house_xf * Transform3D(Basis(Vector3(1,0,0), Vector3(0.22,1,0), Vector3(0,0,1)) * Basis.from_euler(Vector3(0,PI/4.0,0)).scaled(Vector3(1.15,1,1.34)), Vector3(0,cy,0)), [Color("e8d9b8"), Color("f0e2c4"), Color("e0cfa8")][vi], "plaster"); tri_total += 32
	else:
		add_mesh(noised_box(2.3*wf, wh, 1.9, 0.11, float(vi+1)*3.7), house_xf * Transform3D(Basis.IDENTITY, Vector3(0,cy,0)), [Color("e8d9b8"), Color("f0e2c4"), Color("e0cfa8")][vi], "plaster"); tri_total += 108
	for sx in [-1.09, 1.09]:
		var pw105 := rng105.randf_range(0.22, 0.38)
		box(Vector3(sx*wf + rng105.randf_range(-0.04, 0.04), cy, 0.96), Vector3(pw105, wh+0.05, 0.12), Color("54381f"), 0, rng105.randf_range(-0.03, 0.03), 0, "timber")
		box(Vector3(sx*wf + rng105.randf_range(-0.04, 0.04), cy, -0.96), Vector3(pw105*0.92, wh+0.05, 0.12), Color("54381f"), 0, rng105.randf_range(-0.03, 0.03), 0, "timber")
	# R104/R105 timber framing, per-house irregular: rail heights/widths jittered, elements
	# dropped on sparse houses, extra stud on dense ones (existing timber key, shadow-gapped)
	box(Vector3(0, 0.98 + rng105.randf_range(-0.24, 0.24), 0.97), Vector3(2.32*wf, rng105.randf_range(0.14, 0.21), 0.09), Color("54381f"), 0, rng105.randf_range(-0.02, 0.02), 0, "timber")
	if dense105 > 0.28: box(Vector3(0, 0.98 + rng105.randf_range(-0.26, 0.20), -0.97), Vector3(2.32*wf, rng105.randf_range(0.14, 0.20), 0.09), Color("54381f"), 0, 0, 0, "timber")
	if dense105 > 0.15:
		box(Vector3(1.16*wf, 0.98 + rng105.randf_range(-0.20, 0.20), 0), Vector3(0.08, rng105.randf_range(0.14, 0.20), 1.92), Color("54381f"), 0,0,0, "timber")
		box(Vector3(-1.16*wf, 0.98 + rng105.randf_range(-0.20, 0.20), 0), Vector3(0.08, rng105.randf_range(0.14, 0.20), 1.92), Color("54381f"), 0,0,0, "timber")
	if dense105 > 0.38: box(Vector3(1.17*wf, 1.08 + rng105.randf_range(-0.08, 0.08), rng105.randf_range(-0.2, 0.2)), Vector3(0.07, rng105.randf_range(0.8, 1.05), 0.14), Color("54381f"), 0, 0, rng105.randf_range(0.48, 0.74), "timber")
	if dense105 > 0.55: box(Vector3(-1.17*wf, 1.08 + rng105.randf_range(-0.08, 0.08), rng105.randf_range(-0.2, 0.2)), Vector3(0.07, rng105.randf_range(0.8, 1.05), 0.14), Color("54381f"), 0, 0, -rng105.randf_range(0.48, 0.74), "timber")
	if dense105 > 0.62: box(Vector3(rng105.randf_range(-0.15, 0.15)*wf, cy, 1.01), Vector3(rng105.randf_range(0.10, 0.15), wh*0.9, 0.06), Color("54381f"), 0, rng105.randf_range(-0.02, 0.02), 0, "timber")
	box(Vector3(0,top-0.05,0.97), Vector3(2.32*wf,0.21,0.08), Color("54381f"), 0,0,0, "timber"); box(Vector3(0,0.24,0.97), Vector3(2.32*wf,0.21,0.08), Color("54381f"), 0,0,0, "timber")
	box(Vector3(1.16*wf,cy,0), Vector3(0.07,wh+0.05,0.17), Color("54381f"), 0,0,0, "timber"); box(Vector3(-1.16*wf,cy,0), Vector3(0.07,wh+0.05,0.17), Color("54381f"), 0,0,0, "timber")
	box(Vector3(0,0.82,0.99), Vector3(0.78,1.42,0.06), Color("8a6742"))
	box(Vector3(wj*0.7,0.80,1.01), Vector3(0.54,1.28,0.06), Color("6e4a2c"))
	box(Vector3(-0.68*wf+wj,1.22+wj*0.4,0.965), Vector3(0.64,0.72,0.05), Color("54381f"), 0,0,0, "timber"); box(Vector3(0.68*wf+wj,1.22-wj*0.3,0.965), Vector3(0.64,0.72,0.05), Color("54381f"), 0,0,0, "timber") # R106 window frames
	box(Vector3(-0.68*wf+wj,1.22+wj*0.4,0.98), Vector3(0.52,0.60,0.06), Color("ffd98a") if rng105.randf() > 0.22 else Color("3d2b18")); box(Vector3(0.68*wf+wj,1.22-wj*0.3,0.98), Vector3(0.52,0.60,0.06), Color("ffd98a") if rng105.randf() > 0.22 else Color("3d2b18"))
	box(Vector3(0,1.60,1.0), Vector3(0.98,0.15,0.11), Color("54381f"), 0,0,0, "timber"); box(Vector3(0,0.10,1.12), Vector3(0.95,0.11,0.38), stone, 0,0,0, "stone") # R106 door lintel + step
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
	box(Vector3(lean*(1.16*wf+0.42),1.2,0), Vector3(1.15,0.09,1.85), Color("a05a44"), 0, lean*0.20, 0)
	var pitch2: float = [1.32, 1.10, 1.55][vi] * rng105.randf_range(0.92, 1.08) # R121 per-house pitch
	var rw121 := 3.62*wf * rng105.randf_range(0.94, 1.08); var rd121 := 2.8 * rng105.randf_range(0.95, 1.06) # R121 overhang/plan variety
	roof2(Vector3(0,top,0), rw121, rd121, pitch2, 0.18, roof, 1.0)
	box(Vector3(0,top+pitch2+0.03,-0.7 + rng105.randf_range(-0.25, 0.25)), Vector3(0.15,0.1,rng105.randf_range(0.8, 1.4)), roof.darkened(0.15)); box(Vector3(0,top+pitch2+0.07,0.45 + rng105.randf_range(-0.25, 0.25)), Vector3(0.15,0.1,rng105.randf_range(0.8, 1.4)), roof.darkened(0.15))
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
				box(sp2 + nrm2*0.048 + Vector3(0,0,-0.93+float(sg2)*0.93), Vector3(0.48,0.085,0.88), roof.darkened(0.22) if (rw+sg2)%2==0 else roof.lightened(0.15), 0, -side2*sang, 0) # R83 chunkier shingle relief
	# R94: irregular proud tiles on the +x slope (existing shingle keys, seeded per house)
	var rng94 := RandomNumberGenerator.new(); rng94.seed = 9400 + vi*31 + absi(int(p.x*13.0 + p.z*7.0))
	var tones94 := [roof.darkened(0.22), roof.lightened(0.15), roof.darkened(0.46), roof]
	for rw94 in [0.22, 0.48, 0.74]:
		var sp94 := Vector3(hw2*(1.0-rw94), top+pitch2*rw94, 0); var nm94 := Vector3(pitch2, hw2, 0).normalized()
		for tz94 in 4:
			box(sp94 + nm94*0.075 + Vector3(0, 0, -1.05+float(tz94)*0.70 + rng94.randf_range(-0.05, 0.05)), Vector3(rng94.randf_range(0.30, 0.42), 0.07, rng94.randf_range(0.48, 0.62)), tones94[(tz94 + int(rw94*10.0)) % 4], 0, -sang, 0)
	# R78: roof wear as jagged slope fans (R77 flat boxes replaced, same base keys)
	var hs78 := 200 + vi*17 + absi(int(p.x*3.0 + p.z))
	var wp_tt := 0.48; var wp_nrm := Vector3(pitch2, hw2, 0).normalized()
	var up_p := Vector3(-hw2, pitch2, 0).normalized(); var up_m := Vector3(hw2, pitch2, 0).normalized()
	_face_patch(Vector3(hw2*(1.0-wp_tt), top+pitch2*wp_tt, 0) + wp_nrm*0.05, Vector3(0,0,-1), up_p, 1.65, 0.85, hs78+21, roof.lightened(0.30), "", 3)
	_face_patch(Vector3(-hw2*(1.0-0.30), top+pitch2*0.30, 0) + Vector3(-pitch2, hw2, 0).normalized()*0.05, Vector3(0,0,1), up_m, 1.40, 0.80, hs78+29, roof.darkened(0.28), "", 3)
	for ccx in [-1.15, 1.15]:
		for ccz in [-0.95, 0.95]: cyl(Vector3(ccx*wf, cy, ccz), 0.13, 0.13, wh, Color("e8d9b8"), 8, "plaster")
	box(Vector3(0,0.44,1.02), Vector3(2.42*wf,0.28,0.16), stone, 0, 0, 0.30, "stone")
	box(Vector3(0,top-0.10,0), Vector3(2.36*wf,0.13,1.96), Color("f0e2c4"), 0,0,0, "plaster")
	box(Vector3(-0.62*wf,cy,0.99), Vector3(0.72,wh*0.62,0.045), Color("e0cfa8"), 0,0,0, "plaster"); box(Vector3(0.62*wf,cy,0.99), Vector3(0.72,wh*0.62,0.045), Color("e0cfa8"), 0,0,0, "plaster")
	# R78: plaster value modelling as jagged textured fans (R77 flat boxes replaced, same base keys)
	var pal105 := [Color("f5ecd2"), Color("d3bd96"), Color("d8c49c"), Color("bfa87e")] # existing keys only
	_face_patch(Vector3(-0.58*wf + rng105.randf_range(-0.28, 0.28)*wf, top-0.38 + rng105.randf_range(-0.16, 0.16), 0.99), Vector3(1,0,0), Vector3(0,1,0), 1.05*rng105.randf_range(0.80, 1.50), 0.58*rng105.randf_range(0.80, 1.40), hs78, pal105[rng105.randi_range(0, 3)], "plaster", 2)
	_face_patch(Vector3(0.66*wf + rng105.randf_range(-0.24, 0.24)*wf, 0.72 + rng105.randf_range(-0.18, 0.20), 0.99), Vector3(1,0,0), Vector3(0,1,0), 0.90*rng105.randf_range(0.80, 1.50), 0.60*rng105.randf_range(0.80, 1.40), hs78+7, pal105[rng105.randi_range(0, 3)], "plaster", 2)
	_face_patch(Vector3(1.14*wf, cy + rng105.randf_range(-0.14, 0.14), rng105.randf_range(-0.45, 0.45)), Vector3(0,0,-1), Vector3(0,1,0), 1.80*rng105.randf_range(0.82, 1.38), wh*0.88*rng105.randf_range(0.85, 1.18), hs78+13, pal105[rng105.randi_range(0, 2)], "plaster", 2) # sun side: light half of palette
	_face_patch(Vector3(-1.14*wf, cy + rng105.randf_range(-0.14, 0.14), rng105.randf_range(-0.45, 0.45)), Vector3(0,0,1), Vector3(0,1,0), 1.85*rng105.randf_range(0.82, 1.38), wh*0.90*rng105.randf_range(0.85, 1.18), hs78+41, pal105[1 + rng105.randi_range(0, 2)], "plaster", 2) # R104/R105 shade side: darker half, irregular
	# stone foundation skirt
	box(Vector3(0,0.40,0), Vector3(2.40*wf,0.58,2.0), stone, 0,0,0, "stone")
	# R83 relief: foundation stone blocks + diagonal timber braces (existing keys)
	var rng85 := RandomNumberGenerator.new(); rng85.seed = hs78*3 + 8500
	for fb83 in 4:
		box(Vector3(-0.84*wf+float(fb83)*0.56*wf + rng85.randf_range(-0.03, 0.03), 0.40 + rng85.randf_range(-0.03, 0.03), 1.03), Vector3(rng85.randf_range(0.34, 0.52), rng85.randf_range(0.22, 0.36), rng85.randf_range(0.05, 0.10)), stone.darkened(0.12) if fb83%2==0 else stone.lightened(0.07), 0, rng85.randf_range(-0.04, 0.04), 0, "stone")
	box(Vector3(-0.88*wf + rng105.randf_range(-0.06, 0.06), 1.05 + rng105.randf_range(-0.07, 0.07), 1.01), Vector3(rng105.randf_range(0.11, 0.16), rng105.randf_range(0.52, 0.92), 0.06), Color("54381f"), 0, rng105.randf_range(0.34, 0.80), 0, "timber")
	if dense105 > 0.22: box(Vector3(0.88*wf + rng105.randf_range(-0.06, 0.06), 1.05 + rng105.randf_range(-0.07, 0.07), 1.01), Vector3(rng105.randf_range(0.11, 0.16), rng105.randf_range(0.52, 0.92), 0.06), Color("54381f"), 0, -rng105.randf_range(0.34, 0.80), 0, "timber")
	# R84 relief density: side foundation stones, centre timber posts, eave trim
	for fb84 in 3:
		box(Vector3(1.21*wf, 0.40 + rng85.randf_range(-0.03, 0.03), -0.55+float(fb84)*0.55), Vector3(rng85.randf_range(0.05, 0.10), rng85.randf_range(0.22, 0.36), rng85.randf_range(0.34, 0.50)), stone.darkened(0.12) if fb84%2==0 else stone.lightened(0.07), 0,0,0, "stone")
		box(Vector3(-1.21*wf, 0.40 + rng85.randf_range(-0.03, 0.03), -0.55+float(fb84)*0.55), Vector3(rng85.randf_range(0.05, 0.10), rng85.randf_range(0.22, 0.36), rng85.randf_range(0.34, 0.50)), stone.lightened(0.07) if fb84%2==0 else stone.darkened(0.12), 0,0,0, "stone")
	box(Vector3(-(0.16 + rng105.randf_range(0.0, 0.34))*wf, cy, 1.01), Vector3(rng105.randf_range(0.11, 0.16), wh*0.92, 0.06), Color("54381f"), 0, rng105.randf_range(-0.025, 0.025), 0, "timber")
	if dense105 > 0.18: box(Vector3((0.16 + rng105.randf_range(0.0, 0.34))*wf, cy, 1.01), Vector3(rng105.randf_range(0.11, 0.16), wh*0.92, 0.06), Color("54381f"), 0, rng105.randf_range(-0.025, 0.025), 0, "timber")
	box(Vector3(0, top+0.02, rd121/2.0 + 0.03), Vector3(rw121*0.84, 0.10, 0.13), roof.darkened(0.35)) # R121 eave trim follows varied plan
	box(Vector3(-0.62*wf,top+0.67,0.68), Vector3(0.52,0.52,0.42), Color("e8d9b8"), 0,0,0, "plaster")
	box(Vector3(-0.62*wf,top+0.77,0.90), Vector3(0.34,0.3,0.05), Color("ffd98a"))
	box(Vector3(-0.62*wf,top+1.01,0.68), Vector3(0.68,0.1,0.56), roof)
	box(Vector3(0.8,top+0.84,-0.3), Vector3(0.47,1.25,0.47), stone, 0,0,0, "stone")
	if vi != 1: box(Vector3(-0.78,top+0.6,-0.25), Vector3(0.34,0.75,0.34), stone)
	blob(Vector3(0.8,top+1.5,-0.3), Vector3(0.22,0.18,0.22), Color(1,1,1,0.35)); blob(Vector3(0.95,top+1.75,-0.3), Vector3(0.32,0.24,0.32), Color(1,1,1,0.22))
	# massing variety: genuinely different silhouettes per variant
	if vi == 0:
		# long low barn extension behind (long footprint reads from iso)
		box(Vector3(0,0.58,-1.55), Vector3(2.5,1.15,1.05), [Color("e8d9b8"), Color("f0e2c4"), Color("e0cfa8")][vi], 0,0,0, "plaster")
		box(Vector3(0,1.28,-1.55), Vector3(2.7,0.1,1.3), Color("a05a44"), 0, 0, 0.16)
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
	var rng105r := RandomNumberGenerator.new(); rng105r.seed = 10550 + absi(int(p.x*31.0 + p.z*47.0)) # R105 irregular roundhouse framing
	for pa in 6:
		var aa := float(pa) * TAU / 6.0 + rng105r.randf_range(-0.07, 0.07)
		var rr105 := rng105r.randf_range(1.12, 1.20)
		box(p+Vector3(sin(aa)*rr105, 1.45 + rng105r.randf_range(-0.04, 0.04), cos(aa)*rr105), Vector3(rng105r.randf_range(0.12, 0.19), rng105r.randf_range(1.65, 1.95), 0.15), Color("54381f"), aa, rng105r.randf_range(-0.03, 0.03), 0, "timber")
	if rng105r.randf() > 0.35: cyl(p+Vector3(0, 1.48 + rng105r.randf_range(-0.1, 0.1), 0), 1.21, 1.21, 0.13, Color("54381f"), 12, "timber")
	box(p+Vector3(0,2.42,0), Vector3(2.5,0.16,2.5), Color("54381f"))
	var cone1 := CylinderMesh.new(); cone1.bottom_radius=1.62; cone1.top_radius=0.12; cone1.height=1.55 + 0.38*sin(p.x*1.9); cone1.radial_segments=12
	add_mesh(cone1, Transform3D(Basis.from_euler(Vector3(sin(p.x*1.3)*0.07,0,cos(p.z*1.7)*0.07)), p+Vector3(sin(p.z)*0.08,3.25 + 0.19*sin(p.x*1.9),cos(p.x)*0.06)), roof, "roofp"); tri_total += 96
	_cone_relief(p+Vector3(sin(p.z)*0.08, 3.25 + 0.19*sin(p.x*1.9), cos(p.x)*0.06), cone1.height, 1.62, 0.12, roof, 12100 + absi(int(p.x*7.0 + p.z*3.0)), false) # R121 village cone tile rings
	box(p+Vector3(0,0.95,1.2), Vector3(0.62,1.5,0.1), Color("6e4a2c"))
	box(p+Vector3(0,1.78,1.22), Vector3(0.78,0.14,0.11), Color("54381f"), 0,0,0, "timber") # R106 door lintel
	box(p+Vector3(0.85,1.6,0.95), Vector3(0.54,0.62,0.06), Color("54381f"), 0.62, 0, 0, "timber"); box(p+Vector3(0.85,1.6,0.99), Vector3(0.42,0.5,0.08), Color("ffd98a"), 0.62)
	box(p+Vector3(-0.82,1.52,0.90), Vector3(0.54,0.62,0.06), Color("54381f"), -0.65, 0, 0, "timber"); box(p+Vector3(-0.86,1.52,0.94), Vector3(0.42,0.5,0.08), Color("ffd98a") if rng105r.randf() > 0.25 else Color("3d2b18"), -0.65) # R106 second window
	# R79: facade pattern on roundhouse front (stone base + plaster drum)
	_face_patch(p+Vector3(0,0.32,1.30), Vector3(1,0,0), Vector3(0,1,0), 0.95, 0.42, 301+absi(int(p.x)), Color("9a968c"), "stone", 1)
	_face_patch(p+Vector3(0,1.55,1.20), Vector3(1,0,0), Vector3(0,1,0), 0.85, 0.95, 317+absi(int(p.x)), Color("e8d9b8"), "plaster", 2)
	# R83 relief: foundation arc stones (existing castle relief keys)
	for rb83 in 5:
		var aa83 := -0.6 + float(rb83)*0.3 + fmod(float(rb83)*0.17, 0.08) - 0.04
		box(p+Vector3(sin(aa83)*1.31, 0.32 + fmod(float(rb83)*0.11, 0.06) - 0.03, cos(aa83)*1.31), Vector3(0.30 + fmod(float(rb83)*0.13, 0.20), 0.20 + fmod(float(rb83)*0.09, 0.14), 0.06 + fmod(float(rb83)*0.05, 0.05)), Color("a5917a").darkened(0.12) if rb83%2==0 else Color("a5917a").lightened(0.07), aa83, 0, 0, "stone")
	# R84: second staggered course + timber ring relief on the drum
	for rb84 in 5:
		var aa84 := -0.45 + float(rb84)*0.3 + fmod(float(rb84)*0.13, 0.08) - 0.04
		box(p+Vector3(sin(aa84)*1.33, 0.58 + fmod(float(rb84)*0.07, 0.05) - 0.02, cos(aa84)*1.33), Vector3(0.26 + fmod(float(rb84)*0.11, 0.18), 0.14 + fmod(float(rb84)*0.07, 0.10), 0.06 + fmod(float(rb84)*0.04, 0.05)), Color("a5917a").lightened(0.07) if rb84%2==0 else Color("a5917a").darkened(0.12), aa84, 0, 0, "stone")
	cyl(p+Vector3(0,1.45,0), 1.21, 1.21, 0.11, Color("54381f"), 12, "timber")
	cyl(p+Vector3(0.55,3.3,-0.4), 0.2,0.24,0.9, Color("9a968c"), 8, "stone")
func _build_roundbarn(p: Vector3, roof: Color) -> void:
	cyl(p+Vector3(0,0.25,0), 1.62,1.68,0.5, Color("9a968c"), 14, "stone")
	cyl(p+Vector3(0,1.25,0), 1.52,1.44,1.55, Color("a8875e"), 14, "timber")
	box(p+Vector3(0,2.12,0), Vector3(3.2,0.15,3.2), Color("54381f"))
	var cone2 := CylinderMesh.new(); cone2.bottom_radius=1.78; cone2.top_radius=0.14; cone2.height=1.55 + 0.30*sin(p.x*1.7 + p.z*0.9); cone2.radial_segments=14 # R121 barn cone height variety
	add_mesh(cone2, Transform3D(Basis.from_euler(Vector3(cos(p.x)*0.05,0,sin(p.z*1.4)*0.05)), p+Vector3(cos(p.z)*0.07,2.95 + (cone2.height-1.55)*0.5,sin(p.x)*0.05)), roof, "roofp"); tri_total += 112
	_cone_relief(p+Vector3(cos(p.z)*0.07, 2.95 + (cone2.height-1.55)*0.5, sin(p.x)*0.05), cone2.height, 1.78, 0.14, roof, 12130 + absi(int(p.x*7.0 + p.z*3.0)), false) # R121
	box(p+Vector3(0,0.95,1.5), Vector3(0.95,1.55,0.1), Color("54381f"))
	box(p+Vector3(0.75,1.55,1.42), Vector3(0.52,0.54,0.06), Color("54381f"), 0.55, 0, 0, "timber"); box(p+Vector3(0.78,1.55,1.45), Vector3(0.4,0.42,0.08), Color("ffd98a"), 0.55)
	box(p+Vector3(-0.75,1.55,1.42), Vector3(0.52,0.54,0.06), Color("54381f"), -0.55, 0, 0, "timber"); box(p+Vector3(-0.78,1.55,1.45), Vector3(0.4,0.42,0.08), Color("ffd98a"), -0.55) # R106 second window
	cyl(p+Vector3(-0.8,2.6,-0.5), 0.18,0.22,0.8, Color("9a968c"), 8, "stone"); cyl(p+Vector3(-0.8,3.06,-0.5), 0.30,0.26,0.14, Color("9a968c"), 8, "stone") # R106 chimney cap
func _build_octstore(p: Vector3, stone: Color) -> void:
	cyl(p+Vector3(0,0.3,0), 1.45,1.5,0.6, stone, 8, "stone")
	cyl(p+Vector3(0,1.55,0), 1.32,1.26,1.95, stone, 8, "stone")
	var cone3 := CylinderMesh.new(); cone3.bottom_radius=1.58; cone3.top_radius=0.95; cone3.height=0.75 + 0.18*sin(p.x*2.3 + p.z); cone3.radial_segments=8 # R121 store cap height variety
	var cy121 := 2.72 + (cone3.height-0.75)*0.5
	add_mesh(cone3, Transform3D(Basis.from_euler(Vector3(sin(p.x*0.9)*0.06,0,cos(p.z)*0.06)), p+Vector3(0,cy121,0)), Color("a05a44"), "roofp"); tri_total += 64
	_cone_relief(p+Vector3(0,cy121,0), cone3.height, 1.58, 0.95, Color("a8664e"), 12150 + absi(int(p.x*7.0 + p.z*3.0)), false) # R121 relief in existing roof-tone keys
	cyl(p+Vector3(0,cy121 + cone3.height/2.0 + 0.16,0), 0.4,0.46,0.5, stone, 8, "stone") # R121 cap reseated on varied cone
	box(p+Vector3(0,1.0,1.34), Vector3(0.8,1.7,0.1), Color("54381f"))
	box(p+Vector3(0,1.95,1.36), Vector3(0.95,0.15,0.11), Color("54381f"), 0,0,0, "timber") # R106 door lintel
	for ow106 in [-0.72, 0.72]:
		box(p+Vector3(sin(ow106)*1.31, 1.72, cos(ow106)*1.31), Vector3(0.5,0.6,0.07), Color("54381f"), ow106, 0, 0, "timber")
		box(p+Vector3(sin(ow106)*1.34, 1.72, cos(ow106)*1.34), Vector3(0.38,0.48,0.08), Color("ffd98a"), ow106) # R106 drum windows
	box(p+Vector3(1.75,0.35,0.6), Vector3(0.6,0.6,0.6), Color("a67c4e"), 0.4); cyl(p+Vector3(1.7,0.42,-0.35), 0.3,0.34,0.85, Color("8a5f36"), 8)
func _build_aframe(p: Vector3, roof: Color, stone: Color) -> void:
	box(p+Vector3(0,0.15,0), Vector3(2.6,0.3,2.2), stone, 0,0,0, "stone")
	box(p+Vector3(0,0.55,0), Vector3(2.3,0.85,1.9), Color("e8d9b8"), 0,0,0, "plaster")
	var rng105a := RandomNumberGenerator.new(); rng105a.seed = 10610 + absi(int(p.x*29.0 + p.z*43.0)) # R105 irregular aframe framing
	for ax105 in [-1.06, 1.06]:
		box(p+Vector3(ax105 + rng105a.randf_range(-0.04, 0.04), 0.60, 0.93), Vector3(rng105a.randf_range(0.20, 0.30), 1.18, 0.11), Color("54381f"), 0, rng105a.randf_range(-0.03, 0.03), 0, "timber")
	box(p+Vector3(0, 0.62 + rng105a.randf_range(-0.14, 0.14), 0.94), Vector3(2.24, rng105a.randf_range(0.13, 0.20), 0.09), Color("54381f"), 0, rng105a.randf_range(-0.02, 0.02), 0, "timber")
	_face_patch(p+Vector3(rng105a.randf_range(-0.3, 0.3), 0.58 + rng105a.randf_range(-0.08, 0.08), 0.97), Vector3(1,0,0), Vector3(0,1,0), rng105a.randf_range(1.3, 2.0), rng105a.randf_range(0.55, 0.8), 10700 + absi(int(p.x)), [Color("f5ecd2"), Color("d3bd96"), Color("d8c49c"), Color("bfa87e")][rng105a.randi_range(0, 3)], "plaster", 2)
	roof2(p+Vector3(0,0.92,0), 3.3, 2.6, 2.15, 0.18, roof, 2.0)
	var sang121 := atan2(2.15, 1.65); var tones121 := [roof.darkened(0.22), roof.lightened(0.15), roof.darkened(0.46), roof]
	for side121 in [-1.0, 1.0]: # R121 shingle rows following the aframe slopes (existing house keys)
		var nrm121 := Vector3(side121*2.15, 1.65, 0).normalized()
		for rw121 in 3:
			var tt121: float = [0.25, 0.52, 0.78][rw121]
			var sp121 := p + Vector3(side121*1.65*(1.0-tt121), 0.92 + 2.15*tt121, 0) + nrm121*0.035
			for sg121 in [-0.62, 0.62]:
				box(sp121 + Vector3(0, 0, sg121), Vector3(0.52, 0.05, 1.12), tones121[(rw121*2 + (1 if sg121 > 0.0 else 0) + int(rng105a.randf()*2.0)) % 4], 0, -side121*sang121, 0)
	box(p+Vector3(0,0.75,1.02), Vector3(0.66,1.25,0.08), Color("6e4a2c"))
	box(p+Vector3(0,1.44,1.03), Vector3(0.82,0.14,0.10), Color("54381f"), 0,0,0, "timber") # R106 door lintel
	for aw106 in [-0.74, 0.74]:
		box(p+Vector3(aw106, 0.66, 0.97), Vector3(0.56,0.64,0.06), Color("54381f"), 0,0,0, "timber")
		box(p+Vector3(aw106, 0.66, 1.00), Vector3(0.44,0.52,0.07), Color("ffd98a") if rng105a.randf() > 0.22 else Color("3d2b18")) # R106 windows
	box(p+Vector3(0.62,2.9,-0.3), Vector3(0.36,0.9,0.36), stone, 0,0,0, "stone"); box(p+Vector3(0.62,3.40,-0.3), Vector3(0.52,0.13,0.52), stone.darkened(0.15), 0,0,0, "stone") # R106 chimney cap
func _build_hut(p: Vector3, stone: Color) -> void:
	add_mesh(noised_box(2.0,1.4,1.8,0.09,p.x*1.3+p.z), Transform3D(Basis.IDENTITY, p+Vector3(0,0.7,0)), Color("cbb489")); tri_total += 108
	var rng105h := RandomNumberGenerator.new(); rng105h.seed = 10670 + absi(int(p.x*23.0 + p.z*41.0)) # R105 irregular hut framing
	for hx105 in [-0.93, 0.93]:
		for hz105 in [-0.83, 0.83]:
			box(p+Vector3(hx105 + rng105h.randf_range(-0.03, 0.03), 0.70, hz105 + rng105h.randf_range(-0.03, 0.03)), Vector3(rng105h.randf_range(0.16, 0.26), rng105h.randf_range(1.25, 1.5), rng105h.randf_range(0.16, 0.26)), Color("54381f"), rng105h.randf_range(-0.05, 0.05), rng105h.randf_range(-0.03, 0.03), 0, "timber")
	if rng105h.randf() > 0.3: box(p+Vector3(0, 0.72 + rng105h.randf_range(-0.16, 0.16), 0.86), Vector3(1.86, rng105h.randf_range(0.12, 0.19), 0.09), Color("54381f"), 0, rng105h.randf_range(-0.02, 0.02), 0, "timber")
	_face_patch(p+Vector3(rng105h.randf_range(-0.28, 0.28), 0.72 + rng105h.randf_range(-0.1, 0.1), 0.92), Vector3(1,0,0), Vector3(0,1,0), rng105h.randf_range(1.1, 1.7), rng105h.randf_range(0.6, 0.95), 10750 + absi(int(p.x)), [Color("f5ecd2"), Color("d3bd96"), Color("d8c49c"), Color("bfa87e")][rng105h.randi_range(0, 3)], "plaster", 2)
	box(p+Vector3(0,0.65,0.92), Vector3(0.65,1.1,0.08), Color("3d2b18"))
	box(p+Vector3(0,1.26,0.93), Vector3(0.80,0.13,0.10), Color("54381f"), 0,0,0, "timber") # R106 door lintel
	for hw106 in [-0.64, 0.64]:
		box(p+Vector3(hw106, 0.88, 0.90), Vector3(0.52,0.60,0.06), Color("54381f"), 0,0,0, "timber")
		box(p+Vector3(hw106, 0.88, 0.93), Vector3(0.40,0.48,0.07), Color("ffd98a") if rng105h.randf() > 0.22 else Color("3d2b18")) # R106 windows (hut was door-only)
		box(p+Vector3(hw106 + (0.32 if hw106 > 0.0 else -0.32), 0.88, 0.91), Vector3(0.13,0.52,0.05), Color("5d7a34")) # shutter
	if rng105h.randf() > 0.4: # R106 seeded stone chimney with cap through the thatch
		box(p+Vector3(0.55,2.25,-0.35), Vector3(0.36,0.95,0.36), stone, 0,0,0, "stone"); box(p+Vector3(0.55,2.78,-0.35), Vector3(0.50,0.12,0.50), stone.darkened(0.15), 0,0,0, "stone")
	var th121 := 1.5 * rng105h.randf_range(0.88, 1.18); var cy121h := 2.05 + (th121-1.5)*0.5 # R121 per-hut thatch height
	var cone4 := CylinderMesh.new(); cone4.bottom_radius=1.75; cone4.top_radius=0.25; cone4.height=th121; cone4.radial_segments=10
	add_mesh(cone4, Transform3D(Basis.from_euler(Vector3(sin(p.x)*0.06,0,cos(p.z*1.2)*0.06)), p+Vector3(sin(p.z)*0.06,cy121h,0)), Color("b98a35"), "thatch"); tri_total += 80
	for ri in 3: # R121 thatch rings follow the varied cone (fraction heights/radii)
		var t121h: float = [0.16, 0.45, 0.72][ri]; var rr121h := lerpf(1.75, 0.25, t121h) + 0.04
		cyl(p+Vector3(0, cy121h - th121*0.5 + th121*t121h, 0), rr121h, rr121h-0.10, 0.12, Color("8f6a2a"), 10)
	cyl(p+Vector3(0,cy121h - th121*0.5 + 0.08,0), 1.82,1.88,0.2, Color("7d5c26"), 10)
	var bo121 := rng105h.randf() * TAU # R121 battens: seeded rotation, one sometimes missing
	for bi2 in 8:
		if bi2 == 3 and rng105h.randf() < 0.5: continue
		var ba := bo121 + float(bi2) * PI / 4.0
		box(p+Vector3(sin(ba)*1.58, cy121h - th121*0.5 + 0.48, cos(ba)*1.58), Vector3(0.22,0.95,0.12), Color("a87c34") if bi2%2==0 else Color("c49a48"), ba, 0, 0)
	cyl(p+Vector3(0,cy121h + th121*0.5 + 0.12,0), 0.3,0.36,0.22, Color("8f6a2a"), 8) # R121 cap reseated
func _build_tree(p: Vector3, a: Color, b: Color) -> void:
	if absi(int(p.x*7.31 + p.z*13.17)) % 10 >= 5: return # R69: ~half the trees culled (Black #1)
	var tsc := (0.85 + 0.45 * (0.5 + 0.5*sin(p.x*2.7 + p.z*1.9))) * 0.64
	var vi := absi(int(p.x*3.0 + p.z*7.0)) % 7
	if vi == 5: a = Color("c07a2e"); b = Color("e0a44a")
	vi = vi % 3
	if vi == 1: a = Color("4c8a38"); b = Color("82b85e")
	elif vi == 2: a = Color("558f3d"); b = Color("93c46e")
	# R80: distance-graded baked haze on far trees (stronger than R77 hint)
	var hd80 := Vector2(p.x, p.z).length()
	if p.z < -10.0 or hd80 > 15.0:
		var hf80: float = clampf(0.42 + maxf(hd80 - 15.0, 0.0) * 0.015, 0.42, 0.58)
		a = a.lerp(Color("b9c9ae"), hf80); b = b.lerp(Color("ccd9b8"), hf80)
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
		if ci % 4 == 1: cc2 = cc2.darkened(0.32) # R99/R107 deeper shade sub-masses
		add_canopy(Transform3D(Basis.from_euler(Vector3(0, float(ci)*0.62, 0)).scaled(Vector3(sc*1.15*tsc, sc*0.95*tsc, sc*1.15*tsc)), p+off*Vector3(1.28,tsc,1.28)), cc2)
	# R99: mini lobes on crown perimeter (leaf-cluster bumps, varied tone)
	for li99 in 7:
		var la := float(li99) * 0.92 + float(vi) * 1.3
		var loff := Vector3(cos(la) * (1.35 + 0.30*sin(float(li99)*2.1)), 2.15 + 0.55*sin(float(li99)*1.7 + 1.0), sin(la) * (1.35 + 0.30*cos(float(li99)*1.9)))
		var lsc := (0.30 + 0.13 * (0.5 + 0.5*sin(float(li99)*3.3))) * tsc
		var lc99: Color = b.lightened(0.10) if li99 % 3 == 0 else (a.darkened(0.16) if li99 % 3 == 1 else a.lerp(b, 0.5))
		add_canopy(Transform3D(Basis.from_euler(Vector3(0, la, 0)).scaled(Vector3(lsc, lsc*0.82, lsc)), p + loff * Vector3(1.28, tsc, 1.28)), lc99)
func _build_carrier(p: Vector3, tc := Color("2f62b8"), kind := 0) -> void:
	cyl(p+Vector3(0,0.02,0), 0.44,0.44,0.02, Color(0.09,0.15,0.04,0.32), 10) # R119 contact disc
	box(p+Vector3(-0.16,0.35,0), Vector3(0.2,0.7,0.22), Color("4a3421")); box(p+Vector3(0.16,0.35,0), Vector3(0.2,0.7,0.22), Color("4a3421"))
	box(p+Vector3(0,0.95,0), Vector3(0.62,0.65,0.4), tc)
	blob(p+Vector3(0,1.55,0), Vector3(0.28,0.3,0.28), Color("e8b88a"))
	if kind == 0:
		var logm := CylinderMesh.new(); logm.bottom_radius=0.11; logm.top_radius=0.11; logm.height=1.05; logm.radial_segments=8; tri_total+=32
		add_mesh(logm, Transform3D(Basis.from_euler(Vector3(0,0,PI/2.0)), p+Vector3(0,1.62,0)), Color("8a5f36"))
	elif kind == 1:
		box(p+Vector3(0,1.02,-0.33), Vector3(0.54,0.54,0.26), Color("a67c4e")); box(p+Vector3(0,1.02,-0.20), Vector3(0.58,0.10,0.05), Color("6b4423"))
	else:
		blob(p+Vector3(-0.34,0.88,-0.08), Vector3(0.24,0.30,0.24), Color("c9b18a")); blob(p+Vector3(0.34,0.88,-0.08), Vector3(0.24,0.30,0.24), Color("c9b18a"))
	box(p+Vector3(0.35,1.25,0), Vector3(0.55,0.16,0.16), Color("e8b88a"))
