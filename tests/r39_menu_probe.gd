extends SceneTree
const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
var out_dir := "/tmp/r39_probe"
func _init() -> void:
	call_deferred("_run")
func _shot(game, name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png(out_dir.path_join(name))
	print("R39M shot ", name)
func _click(game, point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point; motion.global_position = point
	Input.parse_input_event(motion); Input.flush_buffered_events()
	await process_frame
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true; press.position = point; press.global_position = point
	Input.parse_input_event(press); Input.flush_buffered_events()
	await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT; release.pressed = false; release.position = point; release.global_position = point
	Input.parse_input_event(release); Input.flush_buffered_events()
	await process_frame; await process_frame
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	root.size = Vector2i(1280, 720)
	var game = Scene.instantiate()
	root.add_child(game)
	await process_frame; await process_frame; await process_frame
	print("R39M menu visible=", game.startup_overlay.visible)
	# menu flow: NEW REALM then BEGIN
	var new_btn = game.startup_overlay.find_child("NewSettlement", true, false)
	print("R39M new_btn=", new_btn)
	new_btn.emit_signal("pressed")
	await process_frame
	var begin_btn = game.startup_overlay.find_child("BeginRealm", true, false)
	print("R39M begin_btn=", begin_btn, " seed_text='", game.seed_edit.text, "'")
	begin_btn.emit_signal("pressed")
	await process_frame; await process_frame; await process_frame
	var sim = game.simulation_host.simulation
	print("R39M begun=", game.play_has_begun, " paused=", game.simulation_host.paused, " overlay=", game.startup_overlay.visible, " hall=", sim.town_hall_position, " seed=", game.last_run_seed)
	game._apply_ui_scale(1.5)
	await process_frame; await process_frame
	# open Build palette (top-right Build button) and click House card
	game._set_build_palette_visible(true)
	await process_frame; await process_frame
	var house_card = null
	for b in game.build_buttons.get(Defs.BUILDING_HOUSE, []):
		if b.is_visible_in_tree():
			house_card = b
	print("R39M house_card=", house_card, " disabled=", house_card.disabled if house_card else "?", " rect=", house_card.get_global_rect() if house_card else "")
	await _shot(game, "10_palette.png")
	house_card.emit_signal("pressed")
	await process_frame; await process_frame
	print("R39M after_card placement_type=", game.placement_type, " palette_visible=", game.build_panel.visible)
	# click first green pad tile
	var pads: Dictionary = sim.collect_build_pads(Defs.BUILDING_HOUSE, 0, 40)
	var valid: Array = pads.get("valid", [])
	print("R39M pads valid=", valid.size(), " clearing=", pads.get("clearing", []).size(), " first=", valid[0] if valid.size() else Vector2i(-1,-1))
	# r39: first try a pad hidden behind the placement hint panel itself
	var panel_tile := Vector2i(-1, -1)
	await process_frame
	var prect: Rect2 = game.placement_panel.get_global_rect()
	print("R39M placement_panel rect=", prect, " visible=", game.placement_panel.visible)
	for tv in valid:
		var t3: Vector2i = tv
		var fp3: Vector2i = Defs.building_footprint(Defs.BUILDING_HOUSE)
		var w3: Vector3 = game.world_view.tile_to_world(Vector2(t3) + Vector2(fp3 - Vector2i.ONE) * 0.5)
		var s3: Vector2 = game.camera_rig.camera.unproject_position(w3)
		if prect.has_point(s3):
			panel_tile = t3
			print("R39M pad_behind_hint tile=", t3, " screen=", s3)
			game.evidence_mouse_override = s3
			await _click(game, s3)
			print("R39M after_hint_click placement_type=", game.placement_type, " status=", game.status_label.text if game.status_label else "")
			break
	if panel_tile.x >= 0:
		# placement consumed; restart for the normal pad test
		if game.placement_type == "":
			game._evidence_strip_button(Defs.BUILDING_HOUSE).emit_signal("pressed")
			await process_frame; await process_frame
			print("R39M restarted placement_type=", game.placement_type)
	# try pads in order until one is not under a HUD control
	var chosen := Vector2i(-1, -1)
	for tv in valid:
		var t2: Vector2i = tv
		var fp2: Vector2i = Defs.building_footprint(Defs.BUILDING_HOUSE)
		var w2: Vector3 = game.world_view.tile_to_world(Vector2(t2) + Vector2(fp2 - Vector2i.ONE) * 0.5)
		var s2: Vector2 = game.camera_rig.camera.unproject_position(w2)
		game.evidence_mouse_override = s2
		var m2 := InputEventMouseMotion.new()
		m2.position = s2; m2.global_position = s2
		Input.parse_input_event(m2); Input.flush_buffered_events()
		await process_frame
		print("R39M pad_try tile=", t2, " screen=", s2, " over_ui=", game._pointer_over_ui())
		if not game._pointer_over_ui():
			chosen = t2
			break
	if chosen.x >= 0:
		var tile: Vector2i = chosen
		var fp: Vector2i = Defs.building_footprint(Defs.BUILDING_HOUSE)
		var world: Vector3 = game.world_view.tile_to_world(Vector2(tile) + Vector2(fp - Vector2i.ONE) * 0.5)
		var screen: Vector2 = game.camera_rig.camera.unproject_position(world)
		print("R39M pad tile=", tile, " screen=", screen)
		game.evidence_mouse_override = screen
		await _click(game, screen)
		print("R39M after_click placement_type=", game.placement_type, " pointer_over_ui=", game._pointer_over_ui(), " hovered=", game.get_viewport().gui_get_hovered_control(), " label=", game.placement_label.text)
		game._update_placement_ghost(true)
		await _shot(game, "11_after_click_150.png")
		var houses := []
		for b in sim.buildings:
			var bd: Dictionary = b
			if String(bd.get("planned_type", "")) == Defs.BUILDING_HOUSE or String(bd.get("type", "")) == Defs.BUILDING_HOUSE:
				houses.append("%s@%s" % [bd.get("type"), str(bd.get("position"))])
		print("R39M houses=", houses, " buildings=", sim.buildings.size())
	game.queue_free()
	await process_frame
	quit(0)
