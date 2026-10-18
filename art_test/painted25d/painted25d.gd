extends Node3D
# Painted 2.5D prototype P2 (hero house + mountain backdrop, palette calibrated down): painted sprites on a smooth painted ground slope.
# R68 low-poly scene untouched; fixed iso camera identical to R68; no post/FX.
func gy(x: float, z: float) -> float:
	var e: float = clampf((x - 4.0) / 18.0, 0.0, 1.0)
	return 1.15 * e * e * (3.0 - 2.0 * e) + 0.16 * sin(x * 0.32 + 1.0) * cos(z * 0.27)

func _ready() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.65, 0.72)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.92, 0.95, 1.0)
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -38, 0)
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	add_child(sun)
	_build_ground()
	_sprite("mountain.png", Vector3(13.5, 0, -13), 12.0, 920.0, 950.0, false, Color.WHITE) # painted landform backdrop, behind/right
	# --- painted sprites: tex, ground pos, world height, contact row px, canvas h, flip, tint ---
	_sprite("castle.png", Vector3(0, 0, -5.5), 8.6, 780.0, 820.0, false, Color.WHITE)
	_sprite("house.png", Vector3(-5.5, 0, 1.8), 4.0, 520.0, 560.0, false, Color.WHITE)
	_sprite("house.png", Vector3(5.0, 0, 2.8), 3.8, 520.0, 560.0, true, Color(0.94, 0.97, 1.02))
	_sprite("house.png", Vector3(-0.8, 0, 5.6), 3.4, 520.0, 560.0, false, Color(1.03, 0.98, 0.92))
	_sprite("pine.png", Vector3(-8.5, 0, -3.5), 4.6, 650.0, 680.0, false, Color.WHITE)
	_sprite("pine.png", Vector3(6.5, 0, -4.2), 5.0, 650.0, 680.0, true, Color.WHITE)
	_sprite("pine.png", Vector3(9.5, 0, 0.6), 3.8, 650.0, 680.0, false, Color(0.95, 1.0, 0.95))
	_sprite("pine.png", Vector3(-3.8, 0, -7.8), 5.4, 650.0, 680.0, false, Color.WHITE)
	_sprite("pine.png", Vector3(12.5, 0, -5.5), 4.4, 650.0, 680.0, true, Color.WHITE)
	_sprite("pine.png", Vector3(-2.9, 0, 4.4), 3.1, 650.0, 680.0, false, Color.WHITE) # foreground overlap test vs carrier
	_sprite("house.png", Vector3(3.4, 0, -1.6), 3.0, 520.0, 560.0, true, Color(0.97, 0.94, 0.90))
	_sprite("house.png", Vector3(-8.2, 0, 5.4), 3.1, 520.0, 560.0, false, Color(1.0, 1.0, 1.0))
	_sprite("pine.png", Vector3(-6.8, 0, -6.2), 4.8, 650.0, 680.0, true, Color.WHITE)
	_sprite("pine.png", Vector3(8.8, 0, 5.8), 4.2, 650.0, 680.0, false, Color.WHITE)
	_sprite("pine.png", Vector3(-11.5, 0, 0.5), 5.2, 650.0, 680.0, false, Color.WHITE)
	_sprite("boulder.png", Vector3(10.5, 0, -2.0), 1.15, 235.0, 260.0, false, Color.WHITE)
	_sprite("boulder.png", Vector3(13.5, 0, 1.8), 0.95, 235.0, 260.0, true, Color.WHITE)
	_standin(Vector3(-5.5, 0, 1.8), Vector3(3.2, 2.4, 2.2))
	_standin(Vector3(5.0, 0, 2.8), Vector3(3.2, 2.4, 2.2))
	_standin(Vector3(0, 0, -5.5), Vector3(5.6, 4.5, 3.0))
	_carrier(Vector3(-1.9, 0, 2.5))
	var args := OS.get_cmdline_user_args()
	var out := "/tmp/painted25d.png"; var close := false
	for a in args:
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
		if a == "--close": close = true
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	add_child(cam)
	if close:
		cam.size = 7.5
		cam.look_at_from_position(Vector3(-11.5, 6.5, 10.5), Vector3(-3.4, 1.2, 2.6), Vector3.UP)
	else:
		cam.size = 24.5
		cam.look_at_from_position(Vector3(13.5, 11, 11.6), Vector3(3.4, 0.6, -2.4), Vector3.UP)
	cam.far = 220.0
	cam.current = true
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out)
	print("PAINTED25D draws=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		" prims=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME), " out=", out)
	get_tree().quit()

func _build_ground() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	var nx := 64; var nz := 40
	var x0 := -70.0; var x1 := 78.0; var z0 := -48.0; var z1 := 44.0
	var pt := func(i: int, j: int) -> Vector3:
		var x: float = x0 + (x1 - x0) * float(i) / float(nx)
		var z: float = z0 + (z1 - z0) * float(j) / float(nz)
		return Vector3(x, gy(x, z), z)
	for j in nz:
		for i in nx:
			var a: Vector3 = pt.call(i, j); var b: Vector3 = pt.call(i + 1, j)
			var c: Vector3 = pt.call(i, j + 1); var dd: Vector3 = pt.call(i + 1, j + 1)
			var ua: float = float(i) / nx; var ub: float = float(i + 1) / nx
			var va: float = 1.0 - float(j) / nz; var vb: float = 1.0 - float(j + 1) / nz
			st.set_uv(Vector2(ua, va)); st.add_vertex(a)
			st.set_uv(Vector2(ub, va)); st.add_vertex(b)
			st.set_uv(Vector2(ua, vb)); st.add_vertex(c)
			st.set_uv(Vector2(ub, va)); st.add_vertex(b)
			st.set_uv(Vector2(ub, vb)); st.add_vertex(dd)
			st.set_uv(Vector2(ua, vb)); st.add_vertex(c)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load("res://art_test/painted25d/assets/terrain.png")
	mat.roughness = 1.0
	mat.albedo_color = Color(0.60, 0.64, 0.55) # compensate sun+ambient so painted colours land muted
	mi.material_override = mat
	add_child(mi)
	var far := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(420, 420)
	far.mesh = pm; far.position = Vector3(4, -0.45, -2)
	var fm := StandardMaterial3D.new(); fm.albedo_color = Color(0.30, 0.46, 0.22); fm.roughness = 1.0
	far.material_override = fm
	add_child(far)

func _sprite(texname: String, gp: Vector3, height: float, contact: float, canvas_h: float, flip: bool, tint: Color) -> void:
	var s := Sprite3D.new()
	s.texture = load("res://art_test/painted25d/assets/" + texname)
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.shaded = false
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	s.pixel_size = height / canvas_h
	s.flip_h = flip
	s.modulate = tint
	s.position = Vector3(gp.x, gy(gp.x, gp.z) + (contact - canvas_h * 0.5) * s.pixel_size, gp.z)
	add_child(s)

func _standin(gp: Vector3, size: Vector3) -> void: # invisible collision stand-in only
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new(); box.size = size
	cs.shape = box
	body.position = Vector3(gp.x, gy(gp.x, gp.z) + size.y * 0.5, gp.z)
	body.add_child(cs)
	add_child(body)

func _carrier(gp: Vector3) -> void:
	var ps: PackedScene = load("res://assets/settlement3d/runtime/characters/Farmer_B.glb")
	if ps == null: return
	var ch := ps.instantiate() as Node3D
	ch.position = Vector3(gp.x, gy(gp.x, gp.z) + 0.03, gp.z)
	ch.rotation.y = -0.9
	ch.scale = Vector3.ONE * 0.62
	add_child(ch)
	var ap := AnimationPlayer.new(); ap.root_node = NodePath(".."); ch.add_child(ap)
	for libname in ["MovementBasic", "General", "Tools"]:
		var lp: PackedScene = load("res://assets/settlement3d/runtime/animations/Rig_Medium/Rig_Medium_" + libname + ".glb")
		if lp == null: continue
		var inst := lp.instantiate(); var src := inst.find_children("*", "AnimationPlayer", true, false)
		if src.size() > 0:
			for ln in (src[0] as AnimationPlayer).get_animation_library_list():
				ap.add_animation_library(libname + "_" + String(ln), (src[0] as AnimationPlayer).get_animation_library(ln))
		inst.queue_free()
	if ap.has_animation("MovementBasic_/Walking_A"):
		ap.play("MovementBasic_/Walking_A")
		ap.advance(0.65)
