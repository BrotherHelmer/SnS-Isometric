extends SceneTree

## r39 diagnosis probe (box only): real UI flow to build a House.
const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")

var out_dir := "/tmp/r39_probe"

func _init() -> void:
	call_deferred("_run")

func _shot(game, name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png(out_dir.path_join(name))
	print("R39 shot ", name)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	root.size = Vector2i(1280, 720)
	var game = Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game._start_menu_seed(1792061458)
	game._hide_start_menu()
	var sim = game.simulation_host.simulation
	print("R39 resources=", sim.get_resources())
	print("R39 inventory=", sim.central_inventory)
	print("R39 buildings=", sim.buildings.size(), " workers=", sim.workers.size(), " hall=", sim.town_hall_position)
	print("R39 unlocked_house=", game.is_build_unlocked(Defs.BUILDING_HOUSE), " missing=", game._missing_resources(Defs.BUILDING_HOUSE), " cost=", Defs.building_cost(Defs.BUILDING_HOUSE))
	# find a valid house tile near hall
	var valid := Vector2i(-1, -1)
	for r in range(3, 14):
		for y in range(sim.town_hall_position.y - r, sim.town_hall_position.y + r):
			for x in range(sim.town_hall_position.x - r, sim.town_hall_position.x + r):
				var v: Dictionary = sim.validate_placement(Defs.BUILDING_HOUSE, Vector2i(x, y), 0)
				if bool(v.get("success", false)):
					valid = Vector2i(x, y)
					break
			if valid.x >= 0: break
		if valid.x >= 0: break
	print("R39 valid_tile=", valid, " validate=", sim.validate_placement(Defs.BUILDING_HOUSE, valid, 0))
	var fp: Vector2i = Defs.building_footprint(Defs.BUILDING_HOUSE)
	var world: Vector3 = game.world_view.tile_to_world(Vector2(valid) + Vector2(fp - Vector2i.ONE) * 0.5)
	var screen: Vector2 = game.camera_rig.camera.unproject_position(world)
	print("R39 world=", world, " screen=", screen, " viewport=", game.get_viewport().get_visible_rect().size)
	# UI: press House button in build strip
	var btn = game._evidence_strip_button(Defs.BUILDING_HOUSE)
	print("R39 house_button=", btn, " rect=", btn.get_global_rect() if btn != null else "")
	btn.emit_signal("pressed")
	await process_frame
	await process_frame
	print("R39 after_button placement_type=", game.placement_type, " panel_visible=", game.placement_panel.visible)
	# move pointer over valid tile
	game.evidence_mouse_override = screen
	var motion := InputEventMouseMotion.new()
	motion.position = screen
	motion.global_position = screen
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	await process_frame
	game._update_placement_ghost(true)
	await process_frame
	print("R39 after_hover placement_tile=", game.placement_tile, " validation=", game.placement_validation, " label=", game.placement_label.text, " pointer_over_ui=", game._pointer_over_ui(), " hovered=", game.get_viewport().gui_get_hovered_control())
	await _shot(game, "01_ghost.png")
	# real click through _input
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = screen
	press.global_position = screen
	Input.parse_input_event(press)
	Input.flush_buffered_events()
	await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = screen
	release.global_position = screen
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	await process_frame
	await process_frame
	print("R39 after_click placement_type=", game.placement_type, " buildings=", sim.buildings.size(), " inventory=", sim.central_inventory)
	for b in sim.buildings:
		var bd: Dictionary = b
		print("R39 building type=", bd.get("type"), " planned=", bd.get("planned_type"), " pos=", bd.get("position"), " construction=", bd.get("construction"))
	await _shot(game, "02_after_click.png")
	# let the placed house actually build
	for chunk in 9:
		await create_timer(10.0).timeout
		var desc := []
		for b in sim.buildings:
			var bd: Dictionary = b
			if String(bd.get("planned_type", "")) == Defs.BUILDING_HOUSE or String(bd.get("type", "")) == Defs.BUILDING_HOUSE:
				desc.append("%s@%s conn=%s status=%s del=%s rem=%s" % [bd.get("type"), str(bd.get("position")), str(bd.get("connected")), String(bd.get("status", "")), str(bd.get("materials_delivered")), str(bd.get("construction_remaining"))])
		var states := []
		for w in sim.workers:
			var wd: Dictionary = w
			states.append("%d:%s/%s task=%s" % [int(wd.get("id", 0)), String(wd.get("type", "")), String(wd.get("state", "")), str(wd.get("task", {}).get("kind", wd.get("task", {}).get("type", "")))])
		print("R39 t+", (chunk + 1) * 10, " houses=", desc, " housing=", sim.housing_capacity, " pop=", sim.get_resources().get("population_used"), "/", sim.get_resources().get("population_max"), " workers=", states)
		if desc.has("HOUSE@%s conn=true status=Complete" % str(valid)):
			break
	await _shot(game, "03_after_sim.png")
	# direct sim control on a second tile
	var valid2 := Vector2i(-1, -1)
	for r in range(3, 16):
		for y in range(sim.town_hall_position.y - r, sim.town_hall_position.y + r):
			for x in range(sim.town_hall_position.x - r, sim.town_hall_position.x + r):
				if Vector2i(x, y) == valid: continue
				var v: Dictionary = sim.validate_placement(Defs.BUILDING_HOUSE, Vector2i(x, y), 0)
				if bool(v.get("success", false)):
					valid2 = Vector2i(x, y)
					break
			if valid2.x >= 0: break
		if valid2.x >= 0: break
	print("R39 direct_control tile=", valid2, " result=", sim.request_build(Defs.BUILDING_HOUSE, valid2, 0), " buildings=", sim.buildings.size())
	game.queue_free()
	await process_frame
	quit(0)
