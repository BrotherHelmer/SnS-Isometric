extends Node3D
## ART-03 visual reset showcase. Painted billboard masters in the game iso camera.
## Composition: castle hero + clearing, 3 cottages, one Nordic forest family,
## painted ground plate with narrow dirt paths, mountain/mine, moving villagers.

const A := "res://art_test/art03_reset/assets/"
var tex := {}
var villagers := []
var shot_path := ""
var frames_dir := ""
var frames_target := 0
var frames_saved := 0
var frame_count := 0
var capturing := false

func _ready() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	_load_textures()
	_build_environment()
	_build_ground()
	_build_castle_and_cottages()
	_build_forest()
	_build_mountain()
	_build_villagers()
	_parse_capture_args()

func _load_textures() -> void:
	tex["castle"] = load(A + "cut_castle.png")
	tex["thatch"] = load(A + "cut_cottage_thatch.png")
	tex["stone"] = load(A + "cut_cottage_stone.png")
	tex["conifer"] = load(A + "cut_conifer.png")
	tex["broad"] = load(A + "cut_broadleaf_iso.png")
	tex["mountain"] = load(A + "cut_mountain_mine.png")
	tex["shadow"] = load(A + "shadow_blob.png")
	tex["ground"] = load(A + "ground_plate.png")
	tex["villagers"] = [load(A + "villager_red.png"), load(A + "villager_blue.png"), load(A + "villager_mustard.png"), load(A + "villager_green.png")]

func _build_environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.66, 0.76, 0.68)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 1.0
	we.environment = env
	add_child(we)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 46.0
	var target := Vector3(0, 0, -2)
	var dir := Vector3(0.557, 0.616, 0.557).normalized()
	cam.look_at_from_position(target + dir * 60.0, target, Vector3.UP)
	cam.current = true
	add_child(cam)

func _build_ground() -> void:
	var under := MeshInstance3D.new()
	var up := PlaneMesh.new()
	up.size = Vector2(420, 420)
	under.mesh = up
	var um := StandardMaterial3D.new()
	um.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	um.albedo_color = Color(0.38, 0.55, 0.24)
	under.material_override = um
	under.position = Vector3(0, -0.08, 0)
	add_child(under)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(128, 96)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.albedo_texture = tex["ground"]
	gm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	ground.material_override = gm
	add_child(ground)

func _add_shadow(x: float, z: float, w: float, d: float, strength: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(w, d)
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = tex["shadow"]
	m.albedo_color = Color(1, 1, 1, strength)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.render_priority = 1
	mi.material_override = m
	mi.rotation_degrees = Vector3(-90, 0, 0)
	mi.position = Vector3(x, 0.02, z)
	add_child(mi)
	return mi

func _add_sprite(texture: Texture2D, x: float, z: float, width: float, flip: bool, tint: Color, shadow_w: float) -> Sprite3D:
	_add_shadow(x, z + width * 0.04, shadow_w, shadow_w * 0.42, 0.9)
	var s := Sprite3D.new()
	s.texture = texture
	s.pixel_size = width / float(texture.get_width())
	var h := float(texture.get_height()) * s.pixel_size
	s.position = Vector3(x, h * 0.5 - 0.04, z)
	s.flip_h = flip
	s.modulate = tint
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.alpha_scissor_threshold = 0.40
	s.shaded = false
	add_child(s)
	return s

func _build_castle_and_cottages() -> void:
	_add_sprite(tex["castle"], -4.0, -7.0, 14.5, false, Color(1, 1, 1), 14.0)
	_add_sprite(tex["thatch"], -19.0, 7.0, 8.6, false, Color(1, 1, 1), 8.4)
	_add_sprite(tex["stone"], 6.0, 11.0, 8.0, false, Color(1, 1, 1), 7.8)
	_add_sprite(tex["thatch"], 19.0, 4.0, 7.4, true, Color(0.93, 0.96, 1.0), 7.2)

func _build_mountain() -> void:
	_add_sprite(tex["mountain"], 25.0, -11.0, 19.0, false, Color(1, 1, 1), 21.0)

func _build_forest() -> void:
	var white := Color(1, 1, 1)
	var conifers := [
		[-30.0, -19.0, 6.5, false, white], [-24.5, -20.0, 7.5, true, Color(0.94, 1.0, 0.96)],
		[-18.0, -18.5, 6.0, false, Color(1.02, 1.0, 0.94)], [-11.0, -20.0, 7.8, true, white],
		[-1.0, -20.5, 6.8, false, Color(0.95, 0.99, 1.0)], [7.0, -19.5, 7.4, true, white],
		[14.0, -20.0, 6.2, false, Color(1.0, 0.98, 0.92)], [21.0, -19.0, 7.6, false, white],
		[-30.0, -9.0, 7.0, true, white], [-28.5, 1.0, 6.2, false, Color(0.94, 1.0, 0.96)],
		[-29.0, 12.0, 7.4, false, white], [31.0, 3.0, 6.8, true, Color(0.96, 1.0, 0.97)],
		[29.0, 13.0, 6.0, false, white], [-27.0, 18.0, 6.4, true, white],
		[-19.0, 19.5, 5.6, false, Color(0.95, 1.0, 0.95)], [24.0, 18.0, 6.2, false, white],
		[-31.0, 20.0, 6.8, false, white], [32.0, 20.5, 6.4, true, Color(0.95, 1.0, 0.96)], [12.0, 20.0, 6.0, true, white],
		[31.0, 17.0, 5.4, true, Color(1.0, 0.99, 0.94)],
	]
	for c in conifers:
		_add_sprite(tex["conifer"], c[0], c[1], c[2], c[3], c[4], c[2] * 0.8)
	var broads := [
		[-14.0, -2.0, 7.0, false, white], [12.0, -7.0, 6.6, true, Color(0.95, 1.0, 0.96)],
		[-25.0, -3.0, 6.4, true, white], [16.0, 13.0, 6.8, false, Color(1.0, 0.99, 0.93)],
		[-24.0, 12.0, 6.6, true, white], [28.0, 9.0, 6.2, false, Color(0.97, 1.0, 0.96)],
		[-9.0, 15.5, 6.2, false, white], [22.0, -4.5, 6.0, true, Color(0.96, 1.0, 0.97)],
	]
	for b in broads:
		_add_sprite(tex["broad"], b[0], b[1], b[2], b[3], b[4], b[2] * 0.95)

func _build_villagers() -> void:
	var routes := [
		[Vector2(-4, -0.5), Vector2(-11, 3), Vector2(-17.5, 6.5)],
		[Vector2(-4, -0.5), Vector2(1, 4.5), Vector2(5.5, 9.5)],
		[Vector2(18.5, 3.5), Vector2(22, -1), Vector2(25, -7.5)],
		[Vector2(-17.5, 6.5), Vector2(-8, 10), Vector2(5.5, 9.5)],
	]
	var speeds := [1.5, 1.25, 1.4, 1.1]
	for i in range(4):
		var texture: Texture2D = tex["villagers"][i]
		var vshadow := _add_shadow(0, 0, 1.1, 0.5, 0.85)
		var s := Sprite3D.new()
		s.texture = texture
		s.pixel_size = 1.85 / float(texture.get_height())
		s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		s.alpha_scissor_threshold = 0.40
		s.shaded = false
		add_child(s)
		var route: Array = routes[i]
		var total := 0.0
		for k in range(route.size() - 1):
			total += route[k].distance_to(route[k + 1])
		villagers.append({"node": s, "shadow": vshadow, "route": route, "total": total, "dist": total * 0.25 * float(i), "speed": speeds[i], "dir": 1.0, "phase": float(i) * 1.7})

func _process(delta: float) -> void:
	var time := Time.get_ticks_msec() / 1000.0
	for v in villagers:
		v["dist"] += v["speed"] * v["dir"] * delta
		if v["dist"] >= v["total"]:
			v["dist"] = v["total"]
			v["dir"] = -1.0
		if v["dist"] <= 0.0:
			v["dist"] = 0.0
			v["dir"] = 1.0
		var route: Array = v["route"]
		var remaining: float = v["dist"]
		var pos: Vector2 = route[route.size() - 1]
		var facing := 1.0
		for k in range(route.size() - 1):
			var seg_len: float = route[k].distance_to(route[k + 1])
			if remaining <= seg_len:
				var f := 0.0
				if seg_len > 0.0:
					f = remaining / seg_len
				pos = route[k].lerp(route[k + 1], f)
				if route[k + 1].x < route[k].x:
					facing = -1.0
				break
			remaining -= seg_len
		var node: Sprite3D = v["node"]
		var bob: float = abs(sin(time * 9.0 + v["phase"])) * 0.07
		node.position = Vector3(pos.x, 0.925 + bob, pos.y)
		node.flip_h = (facing * v["dir"]) < 0.0
		var vsh: MeshInstance3D = v["shadow"]
		vsh.position = Vector3(pos.x, 0.025, pos.y + 0.1)
	_capture_logic()

func _parse_capture_args() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		if args[i] == "--art03-shot" and i + 1 < args.size():
			shot_path = args[i + 1]
		if args[i] == "--art03-frames" and i + 2 < args.size():
			frames_dir = args[i + 1]
			frames_target = int(args[i + 2]) * 30
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
		print("ART03 draws=", int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), " prims=", int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)), " shot=", path)
		get_tree().quit()
		return
	frames_saved += 1
	capturing = false
	if frames_saved >= frames_target:
		print("ART03 draws=", int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), " prims=", int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)), " frames done=", frames_saved)
		get_tree().quit()
