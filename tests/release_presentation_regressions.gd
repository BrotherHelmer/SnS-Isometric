extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = Scene.instantiate()
	root.add_child(game)
	await process_frame
	_check(game.menu_backdrop.texture != null and game.menu_backdrop.visible, "title artwork loads at launch")
	game._start_review_seed()
	await create_timer(0.5).timeout
	var view = game.world_view.character_views.values()[0]
	_check_pose(view, "new realm")
	for cycle in 3:
		game._show_start_menu()
		await process_frame
		_check_pose(view, "paused menu")
		game._resume_from_menu()
		await create_timer(0.2).timeout
		_check_pose(view, "resumed realm")
	view.set_animation_lod_enabled(false)
	_check_pose(view, "animation budget suspended")
	view.set_animation_lod_enabled(true)
	view._update_manual_animation(0.3)
	_check_pose(view, "animation budget restored")
	var sim = game.simulation_host.simulation
	game.set_process(false)
	game.simulation_host.paused = true
	var minimap = game.minimap
	# Omit the camera overlay so the assertion checks world markers only.
	minimap.camera_rig = null
	var shard: Vector2i = sim.shard_position
	var rival: Vector2i = sim.rival_town_hall_position
	_check(not sim.is_revealed(shard) and not sim.is_revealed(rival), "fresh realm has undiscovered opponents and Shard")
	var snapshot: Dictionary = game.current_frame_snapshot.duplicate(true)
	# Even malformed visibility flags must not leak authoritative hidden data.
	snapshot.rival_roads = [{"anchor": rival, "realm": "rival"}]
	snapshot.rivalry_structures = [{"anchor": rival, "realm": "rival", "visible": true}]
	snapshot.wyrd_sites = [{"position": shard, "visible": false}]
	var image: Image = minimap._render_map(sim.map_size, snapshot)
	_check(image.get_pixelv(shard).is_equal_approx(Color("#0a1210")), "Shard remains fogged on minimap")
	_check(image.get_pixelv(rival).is_equal_approx(Color("#0a1210")), "rival roads and structures remain fogged")
	sim._reveal_radius(shard, 1)
	sim._reveal_radius(rival, 1)
	image = minimap._render_map(sim.map_size, snapshot)
	_check(image.get_pixelv(shard).is_equal_approx(Color("#6bcfe0")), "explored Shard appears")
	_check(image.get_pixelv(rival).is_equal_approx(Color("#7a2c36")), "explored rival Town Hall appears")
	game.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	print("RELEASE_PRESENTATION_REGRESSIONS %s" % ["PASS" if failures.is_empty() else "FAIL"])
	quit(0 if failures.is_empty() else 1)

func _check_pose(view, label: String) -> void:
	_check(view.playback.get_current_node() != "Start", label + " has a running animation state")
	var hand: int = view.skeleton.find_bone("handslot.l")
	var rest: Vector3 = view.skeleton.get_bone_global_rest(hand).origin
	var pose: Vector3 = view.skeleton.get_bone_global_pose(hand).origin
	_check(rest.distance_to(pose) > 0.1, label + " uses animated bones instead of T-pose")

func _check(ok: bool, label: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		failures.append(label)
