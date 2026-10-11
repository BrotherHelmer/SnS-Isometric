extends SceneTree

## Capture 20 opening frames, then leave the PNGs for the contact sheet.
const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const BASE_SEED := 260821
const SEED_COUNT := 20


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var dest := ProjectSettings.globalize_path("res://artifacts/first_screen")
	DirAccess.make_dir_recursive_absolute(dest)
	var notes := FileAccess.open(dest.path_join("visual_seeds.txt"), FileAccess.WRITE)
	if notes != null:
		notes.store_line("seed\torbit\tsector\tcompass\twater\tlayout\tdist\tpit")
	for i in SEED_COUNT:
		var seed_value := BASE_SEED + i * 97
		var t0 := Time.get_ticks_msec()
		var game := Scene.instantiate()
		root.add_child(game)
		await process_frame
		await process_frame
		game.start_new_3d(seed_value)
		game._hide_start_menu()
		game.simulation_host.paused = true
		if game.has_method("_update_ui"):
			game._update_ui()
		for _f in 10:
			await process_frame
		await RenderingServer.frame_post_draw
		var image: Image = root.get_viewport().get_texture().get_image()
		var name := "review_seed_%d.png" % seed_value
		if image != null and not image.is_empty():
			image.save_png(dest.path_join(name))
		var audit: Dictionary = game.simulation_host.simulation.founding_audit()
		var line := "%d\t%.1f\t%d\t%s\t%s\t%s\t%.1f\t%.1f\t%.0f" % [
			seed_value,
			float(audit.get("orbit_deg", -1.0)),
			int(audit.get("orbit_sector", -1)),
			String(audit.get("orbit_compass", "")),
			String(audit.get("water_type", "")),
			String(audit.get("layout_signature", "")),
			float(audit.get("crater_dist", -1.0)),
			float(audit.get("pit_radius", -1.0)),
			float(Time.get_ticks_msec() - t0),
		]
		print("VISUAL_SEED %s wrote=%s" % [line, name])
		if notes != null:
			notes.store_line(line)
		game.queue_free()
		await process_frame
		await process_frame
	if notes != null:
		notes.close()
	print("VISUAL_SEEDS PASS count=%d dest=%s" % [SEED_COUNT, dest])
	quit(0)
