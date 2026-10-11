extends SceneTree

## 1920×1080 big-map deliverables: six first screens whose halls face
## six different crater headings (including the -Z blocker 261306), a
## composite, a zoomed-out overview, and a province minimap.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const CameraRig = preload("res://src/GodotClient3D/Scripts/production_isometric_camera_rig.gd")

const SHOT_SEEDS := [
	{"seed": 261403, "dir": "N"},
	{"seed": 260918, "dir": "NE"},
	{"seed": 262761, "dir": "E"},
	{"seed": 261500, "dir": "S"},
	{"seed": 261015, "dir": "SW"},
	{"seed": 261306, "dir": "W"},
]

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var dest := ProjectSettings.globalize_path("res://artifacts/bigmap")
	DirAccess.make_dir_recursive_absolute(dest)
	var cells: Array[Image] = []
	for spec in SHOT_SEEDS:
		var seed_value: int = int(spec["seed"])
		var game := Scene.instantiate()
		root.add_child(game)
		await process_frame
		await process_frame
		game.start_new_3d(seed_value)
		game._hide_start_menu()
		game.simulation_host.paused = true
		if game.has_method("_update_ui"):
			game._update_ui()
		game.world_view.note_camera(game.world_view.opening_camera_focus(), CameraRig.OPENING_ZOOM)
		for _i in 10:
			await process_frame
			game.world_view.stream_chunks(20000)
		await RenderingServer.frame_post_draw
		var shot: Image = _save(dest, "first_%d.png" % seed_value)
		_save(dest, "first_%d_%s.png" % [seed_value, String(spec["dir"])])
		if shot != null:
			cells.append(shot)
		var view: Dictionary = game.world_view.opening_view_audit(game.camera_rig.camera)
		var land := _three_d_land_ratio(shot)
		print("T_BIGMAP_SHOTS seed=%d dir=%s land=%.3f near=%d hall=%s" % [
			seed_value, String(spec["dir"]), land,
			int(view.get("near_visible", 0)), str(view.get("hall_in_view", false))
		])
		_check(int(view.get("near_built", 0)) >= 1, "seed %d near chunks built" % seed_value)
		_check(bool(view.get("hall_in_view", false)), "seed %d hall in view" % seed_value)
		_check(land >= 0.60, "seed %d first screen is >=60%% land (%.1f%%)" % [seed_value, land * 100.0])
		if seed_value == 260918:
			game.camera_rig.configure_for_map(game.simulation_host.simulation.map_size)
			game.camera_rig.compose_view(game.world_view.opening_camera_focus(), CameraRig.PROVINCE_ZOOM)
			game.world_view.note_camera(game.camera_rig.target_position, CameraRig.PROVINCE_ZOOM)
			for _j in 12:
				await process_frame
				game.world_view.stream_chunks(20000)
			await RenderingServer.frame_post_draw
			_save(dest, "overview.png")
			if game.minimap != null:
				game.minimap.overview_mode = true
				game.minimap.redraw(game.current_frame_snapshot)
				var atlas: Image = game.minimap._render_map(game.simulation_host.simulation.map_size, game.current_frame_snapshot)
				if atlas != null:
					atlas.resize(1080, 1080, Image.INTERPOLATE_NEAREST)
					atlas.save_png(dest.path_join("minimap_atlas.png"))
					var board := Image.create(1920, 1080, false, Image.FORMAT_RGB8)
					board.fill(Color("#0a1210"))
					var left := (1920 - 1080) / 2
					board.blit_rect(atlas, Rect2i(0, 0, 1080, 1080), Vector2i(left, 0))
					board.save_png(dest.path_join("minimap.png"))
					print("T_BIGMAP_SHOTS wrote minimap.png 1920x1080")
		game.queue_free()
		await process_frame
	if cells.size() == SHOT_SEEDS.size():
		_write_composite(dest, cells)
	print("T_BIGMAP_SHOTS dest=%s" % dest)
	print("T_BIGMAP_SHOTS %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _write_composite(dest: String, cells: Array[Image]) -> void:
	var board := Image.create(1920, 1080, false, Image.FORMAT_RGB8)
	board.fill(Color("#0a1210"))
	var cell_w := 640
	var cell_h := 540
	for index in cells.size():
		var src: Image = cells[index].duplicate()
		src.resize(cell_w, cell_h, Image.INTERPOLATE_BILINEAR)
		var col := index % 3
		var row := index / 3
		board.blit_rect(src, Rect2i(0, 0, cell_w, cell_h), Vector2i(col * cell_w, row * cell_h))
	board.save_png(dest.path_join("six_directions_composite.png"))
	print("T_BIGMAP_SHOTS wrote six_directions_composite.png 1920x1080")


func _three_d_land_ratio(image: Image) -> float:
	if image == null or image.is_empty():
		return 0.0
	var width := image.get_width()
	var height := image.get_height()
	var y0 := clampi(int(round(float(height) * 0.09)), 0, height - 1)
	var y1 := clampi(int(round(float(height) * 0.86)), y0 + 1, height)
	var void_c := Color("#17272A")
	var land := 0
	var total := 0
	var step := 3
	for y in range(y0, y1, step):
		for x in range(0, width, step):
			var pixel: Color = image.get_pixel(x, y)
			total += 1
			var dist := absf(pixel.r - void_c.r) + absf(pixel.g - void_c.g) + absf(pixel.b - void_c.b)
			var luma := pixel.r * 0.22 + pixel.g * 0.72 + pixel.b * 0.06
			if dist > 0.10 and luma > 0.12:
				land += 1
	return float(land) / float(maxi(total, 1))


func _save(dest: String, name_value: String) -> Image:
	var image: Image = root.get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		failures.append("empty shot %s" % name_value)
		return null
	image.save_png(dest.path_join(name_value))
	print("T_BIGMAP_SHOTS wrote %s %dx%d" % [name_value, image.get_width(), image.get_height()])
	return image


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
