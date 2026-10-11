extends SceneTree

## The Director: 1080p HUD type must be a single stroke. Cinzel VF + outline_size
## reprinted last glyphs (HOLDSO / RAIDOID). This gate checks the theme and
## writes a 1920×1080 proof of the victory card and raid banner.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const HudSkin = preload("res://src/GodotClient3D/Scripts/production_hud_skin.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var theme: Theme = HudSkin.hud_theme()
	_check(theme.get_constant("outline_size", "Label") == 0, "HUD Label outline_size is 0")
	_check(theme.get_constant("outline_size", "Button") == 0, "HUD Button outline_size is 0")
	_check(theme.get_constant("outline_size", "RichTextLabel") == 0, "HUD RichTextLabel outline_size is 0")
	var title: Label = HudSkin.title_label("THE REALM HOLDS", HudSkin.SIZE_TITLE)
	_check(title.get_theme_constant("outline_size") == 0, "title_label outline_size is 0")
	title.free()

	if DisplayServer.get_name() == "headless":
		print("T_HUD_TYPE skip 3D shots (headless)")
		print("T_HUD_TYPE %s" % ("PASS" if failures.is_empty() else "FAIL"))
		for failure in failures:
			print("  FAIL %s" % failure)
		quit(0 if failures.is_empty() else 1)
		return

	var dest := ProjectSettings.globalize_path("res://artifacts/demo_playthrough_v2/shots")
	DirAccess.make_dir_recursive_absolute(dest)
	var game = Scene.instantiate()
	root.add_child(game)
	for _i in 4:
		await process_frame
	if game.has_method("start_new_3d"):
		game.start_new_3d(260821)
	if game.has_method("_hide_start_menu"):
		game._hide_start_menu()
	if game.simulation_host != null:
		game.simulation_host.paused = true
	if game.has_method("_update_ui"):
		game._update_ui()
	for _j in 4:
		await process_frame
		if game.world_view != null:
			game.world_view.stream_chunks(4000)
	await RenderingServer.frame_post_draw

	if game.result_title != null:
		game.result_title.text = "THE REALM HOLDS\nFIVE DAYS"
		HudSkin.apply_readable_type(game.result_title)
		_check(game.result_title.get_theme_constant("outline_size") == 0, "result title outline_size is 0")
	if game.result_body != null:
		game.result_body.text = "Days survived  4\nPopulation  10\nEnemies defeated  14"
	if game.result_overlay != null:
		game.result_overlay.visible = true
	if game.has_method("_set_play_chrome_visible"):
		game._set_play_chrome_visible(false)
	for _k in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	_write_shot(dest.path_join("hud_victory_type.png"))

	if game.result_overlay != null:
		game.result_overlay.visible = false
	if game.has_method("_set_play_chrome_visible"):
		game._set_play_chrome_visible(true)
	if game.toast_title != null:
		game.toast_title.text = "RAID"
		HudSkin.apply_readable_type(game.toast_title)
		_check(game.toast_title.get_theme_constant("outline_size") == 0, "raid banner outline_size is 0")
	if game.toast_body != null:
		game.toast_body.text = "2 hostiles are coming from the south."
	if game.alert_panel != null:
		game.alert_panel.visible = true
	for _m in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	_write_shot(dest.path_join("hud_raid_type.png"))

	print("T_HUD_TYPE %s" % ("PASS" if failures.is_empty() else "FAIL"))
	for failure in failures:
		print("  FAIL %s" % failure)
	if game != null:
		game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)


func _write_shot(path: String) -> void:
	var image: Image = root.get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		_check(false, "viewport image for %s" % path)
		return
	image.save_png(path)
	print("T_HUD_TYPE wrote %s" % path)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
