extends SceneTree
## M1 diorama-world capture harness (checks 5+6): boots the real
## production_3d scene with the game's own launch options
## (--autostart --fixture=<stage> --seed=<n>), waits for the world to
## stream, captures an unmodified 1280x720 frame, then toggles the sun's
## shadow_enabled off (same-code A/B) and captures again.
## Run: godot --resolution 1280x720 --path . --script res://tests/godot_diorama_capture.gd -- --autostart --fixture=lumber --seed=424242 --dio-game-shot <on.png> --dio-game-shot-off <off.png>

var shot_on := ""
var shot_off := ""
var wide := false


func _init() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("diorama capture requires a readable framebuffer")
		quit(1)
		return
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var args := OS.get_cmdline_user_args()
	for i in range(args.size()):
		if args[i] == "--dio-game-shot" and i + 1 < args.size():
			shot_on = args[i + 1]
		if args[i] == "--dio-game-shot-off" and i + 1 < args.size():
			shot_off = args[i + 1]
		if args[i] == "--dio-wide":
			wide = true
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://src/GodotClient3D/Scenes/production_3d.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	await create_timer(30.0).timeout
	var sim = game.simulation_host.simulation
	# Frame the founding settlement (midpoint of Town Hall and Lumber Camp)
	# at midday, the same presentation state the built-in evidence capture
	# uses when it pins the clock for its shots.
	sim.is_night = false
	sim.phase_time = 60.0
	var th_id := -1
	var camp_id := -1
	for b in sim.buildings:
		if String(b.get("type", "")) == "TOWN_HALL":
			th_id = int(b.get("id", -1))
		if String(b.get("type", "")) == "LUMBER_CAMP":
			camp_id = int(b.get("id", -1))
	if th_id >= 0 and camp_id >= 0:
		var mid: Vector3 = (game.world_view.focus_for_building(th_id) + game.world_view.focus_for_building(camp_id)) * 0.5
		game.get_node("IsometricCameraRig").focus_world(mid)
	elif th_id >= 0:
		# M2: developed-stage raids can raze the camp before the shot;
		# fall back to the Town Hall so the settlement is still framed.
		game.get_node("IsometricCameraRig").focus_world(game.world_view.focus_for_building(th_id))
	if wide:
		# M2 evidence: pull to the rig's strategic zoom for a family view.
		game.get_node("IsometricCameraRig").set_zoom_preset("strategic")
	await create_timer(4.0).timeout
	print("CAPTURE founded=", sim.is_town_hall_founded(), " buildings=", sim.buildings.size(), " workers=", sim.workers.size())
	print("CAPTURE counts TH=", _count(sim, "TOWN_HALL"), " HOUSE=", _count(sim, "HOUSE"), " LUMBER=", _count(sim, "LUMBER_CAMP"))
	print("CAPTURE family SAWMILL=", _count(sim, "SAWMILL"), " FARM=", _count(sim, "FARM"), " BAKERY=", _count(sim, "BAKERY"), " STOREHOUSE=", _count(sim, "STOREHOUSE"), " QUARRY=", _count(sim, "QUARRY"), " WATCHTOWER=", _count(sim, "WATCHTOWER"), " BARRACKS=", _count(sim, "BARRACKS"), " ROAD=", _count(sim, "ROAD"))
	print("CAPTURE sun shadow_enabled=", game.sun_light.shadow_enabled, " shadow_mode=", game.sun_light.directional_shadow_mode, " (0=ORTHOGONAL 1=PSSM2 2=PSSM4)")
	await _snap(shot_on)
	if shot_off != "":
		game.sun_light.shadow_enabled = false
		await create_timer(3.0).timeout
		await _snap(shot_off)
		game.sun_light.shadow_enabled = true
	print("CAPTURE done")
	quit(0)


func _count(sim, building_type: String) -> int:
	var n := 0
	for b in sim.buildings:
		if String(b.get("type", "")) == building_type:
			n += 1
	return n


func _snap(path: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	img.save_png(path)
	print("CAPTURE draws=", int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), " prims=", int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)), " shot=", path)
