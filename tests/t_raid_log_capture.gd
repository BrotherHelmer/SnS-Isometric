extends SceneTree

## Evidence shots of the existing Log panel during and after a raid.
## Run under Xvfb; writes PNGs to RAID_LOG_CAPTURE_OUT or docs/playtest.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const RaidTuning = preload("res://src/GodotClient/Scripts/one_shard_raid_tuning.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.start_new_3d(game.DEFAULT_SEED)
	game._hide_start_menu()
	game.play_has_begun = true
	for _i in 4:
		await process_frame
	var sim = game.simulation_host.simulation
	sim.day_count = 2
	sim.is_night = true
	sim.phase_time = 8.0
	sim.central_inventory[Defs.RESOURCE_BREAD] = 28
	sim._reveal_radius(sim.town_hall_position, 18)
	sim._send_workers_to_shelter()
	var tile: Vector2i = sim.town_hall_position + Vector2i(3, 0)
	sim._prepare_test_tile(tile, Defs.TILE_GRASS)
	var store: Dictionary = sim._add_completed_building(Defs.BUILDING_STOREHOUSE, tile)
	store["connected"] = true
	sim._spawn_enemy(tile + Vector2i(1, 0), RaidTuning.NIGHT2_HP, RaidTuning.NIGHT2_DAMAGE, 0.0, 0, sim.ENEMY_RAIDER, RaidTuning.NIGHT2_ARMOR)
	sim._spawn_enemy(tile + Vector2i(1, 1), RaidTuning.NIGHT2_HP, RaidTuning.NIGHT2_DAMAGE, 0.0, 0, sim.ENEMY_RAIDER, RaidTuning.NIGHT2_ARMOR)
	sim._begin_raid(RaidTuning.NIGHT2_STEAL)
	sim._simulate_seconds_for_test(4.5)
	sim._flush_combat_log(true)
	if game.event_log_panel != null and not game.event_log_panel.visible:
		game._toggle_event_log()
	game._update_ui()
	game._refresh_event_log()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	_shot(game, "raid_log_during.png")
	for enemy in sim.enemies:
		enemy["hp"] = 0
	sim._update_enemies(sim.TICK_SECONDS)
	sim._maybe_finish_raid()
	game._update_ui()
	game._refresh_event_log()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	_shot(game, "raid_log_after.png")
	print("RAID_LOG_CAPTURE PASS")
	game.queue_free()
	quit(0)


func _shot(game: Node, filename: String) -> void:
	var folder := String(OS.get_environment("RAID_LOG_CAPTURE_OUT"))
	if folder == "":
		folder = "res://docs/playtest"
	var image: Image = game.get_viewport().get_texture().get_image()
	var dest := folder.path_join(filename) if folder.begins_with("res://") or folder.begins_with("user://") else folder.path_join(filename)
	if not folder.begins_with("res://") and not folder.begins_with("user://"):
		DirAccess.make_dir_recursive_absolute(folder)
	var err := image.save_png(dest) if folder.begins_with("res://") or folder.begins_with("user://") else image.save_png(folder.path_join(filename))
	print("RAID_LOG_CAPTURE file=%s err=%d" % [filename, err])
