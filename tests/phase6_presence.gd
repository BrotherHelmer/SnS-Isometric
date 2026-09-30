extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var failures: Array[String] = []
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.start_new_3d(game.DEFAULT_SEED)
	await process_frame
	await process_frame
	_check(failures, game.minimap != null, "province minimap exists")
	game._tick_minimap(0.2)
	_check(failures, game.minimap.visible, "minimap is visible during play")
	game._tick_audio(0.5)
	var stems: Array = game.audio_director.evidence_snapshot().get("stems", [])
	_check(failures, stems.has("day"), "day mix includes the pastoral score stem")
	var grass_in_trees := 0
	for key_value in game.world_view.nature_views:
		if String(game.world_view.nature_views[key_value]) == Defs.TILE_GRASS:
			grass_in_trees += 1
	_check(failures, grass_in_trees == 0, "grass is not rebuilt with every tree mesh")
	_check(failures, game.world_view.grass_root != null and game.world_view.grass_root.get_child_count() > 0, "revealed yards have a dedicated grass layer")
	var fog: Dictionary = game.world_view.fog_configuration()
	_check(failures, bool(fog.get("volume_mesh", false)), "fog of war is a covering volume")
	_check(failures, game.world_view.fog_plane != null and game.world_view.fog_skirts.size() >= 4, "fog sheet and skirts cover the island edge")
	# T-SNS-UI Look lift: the pressure chip is wired from minute zero but hidden
	# while the realm is QUIET by day; it appears at night, in a raid or above QUIET.
	_check(failures, game.pressure_meter != null and not game.pressure_meter.visible and "QUIET" in game.pressure_meter.band, "Wyrd Pressure chip is wired from minute zero and hidden while QUIET")
	_check(failures, game.pressure_meter != null and game._pressure_chip_should_show("RISING", false, 0) and game._pressure_chip_should_show("QUIET", true, 0), "Wyrd Pressure chip appears above QUIET or at night")
	var rival_line := String(game.simulation_host.simulation.get_wyrdfall_presentation().get("rival_line", ""))
	_check(failures, rival_line != "", "rival threat is named from the opening")
	game._update_shard_compass()
	_check(failures, game.shard_compass != null, "shard compass exists for off-screen guidance")
	game.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	if failures.is_empty():
		print("PHASE6_PRESENCE PASS")
		quit(0)
	else:
		for line in failures:
			print("FAIL %s" % line)
		print("PHASE6_PRESENCE FAIL %d" % failures.size())
		quit(1)


func _check(failures: Array[String], ok: bool, label: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		failures.append(label)
