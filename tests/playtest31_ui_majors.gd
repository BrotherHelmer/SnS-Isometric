extends SceneTree

## Playtest.31 (T-SNS-009) CoS UI MAJOR items 1-5 as layout/state assertions.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.start_new_3d(game.DEFAULT_SEED)
	for _i in 4:
		await process_frame
	var sim = game.simulation_host.simulation
	game._tick_minimap(0.2)
	game._update_ui()
	await process_frame

	# 2) Build strip is not covered by the minimap; last button (Clear) fully visible.
	var strip_rect: Rect2 = game.build_strip.get_global_rect()
	var minimap_rect: Rect2 = game.minimap.get_global_rect()
	print("PT31_UI strip=%s minimap=%s" % [str(strip_rect), str(minimap_rect)])
	_check(not strip_rect.intersects(minimap_rect), "minimap does not overlap the build strip")
	_check(strip_rect.end.y <= 720.0 - 8.0, "build strip keeps its bottom margin")
	var hint_rect: Rect2 = game.placement_panel.get_global_rect()
	_check(not hint_rect.intersects(strip_rect), "placement hint sits above the build strip")
	var last_btn: Button = game.build_strip_buttons[game.build_strip_buttons.size() - 1]
	var last_rect: Rect2 = last_btn.get_global_rect()
	print("PT31_UI last_button=%s type=%s" % [str(last_rect), String(game.build_strip_types[game.build_strip_types.size() - 1])])
	_check(last_rect.end.x <= strip_rect.end.x + 0.5 and not last_rect.intersects(minimap_rect), "last strip button (Clear) is fully visible")

	# 3) Cost on every button; unaffordable dimmed + red cost; missing chip flashes.
	_check(game.build_strip_cost_labels.size() == game.build_strip_buttons.size(), "every strip button carries a cost label")
	var first_cost: Label = game.build_strip_cost_labels[1]
	var first_btn_rect: Rect2 = (game.build_strip_buttons[1] as Button).get_global_rect()
	var cost_rect: Rect2 = first_cost.get_global_rect()
	print("PT31_UI cost_label=%s button=%s strip=%s" % [str(cost_rect), str(first_btn_rect), str(strip_rect)])
	_check(cost_rect.end.y <= first_btn_rect.end.y + 1.0 and cost_rect.end.y <= strip_rect.end.y, "cost label is drawn inside its button (not clipped)")
	for key in sim.central_inventory.keys():
		sim.central_inventory[key] = 0
	sim.central_inventory[Defs.RESOURCE_PLANKS] = 8
	game._update_ui()
	var barracks_index: int = game.build_strip_types.find(Defs.BUILDING_BARRACKS)
	_check(barracks_index >= 0, "barracks on strip")
	if barracks_index >= 0:
		var container: Control = game.build_strip_containers[barracks_index]
		var cost_label: Label = game.build_strip_cost_labels[barracks_index]
		print("PT31_UI barracks_cost='%s' modulate=%s" % [cost_label.text, str(container.modulate)])
		_check(cost_label.text != "", "barracks shows its cost on the button")
		_check(container.modulate.a < 0.9, "unaffordable barracks is dimmed")

	# 5) One action -> one message: placing Bakery then clicking unaffordable Barracks.
	sim.central_inventory[Defs.RESOURCE_WOOD] = 200
	sim.central_inventory[Defs.RESOURCE_STONE] = 200
	sim.central_inventory[Defs.RESOURCE_PLANKS] = 200
	game.begin_placement(Defs.BUILDING_HOUSE)
	_check(game.placement_panel.visible, "placement hint visible while placing")
	# 1) Tooltips suppressed during placement.
	game._update_ui()
	var any_tip := false
	for btn in game.build_strip_buttons:
		if String((btn as Button).tooltip_text) != "":
			any_tip = true
	_check(not any_tip, "strip tooltips suppressed while placement hint is shown")
	sim.central_inventory[Defs.RESOURCE_PLANKS] = 0
	sim.central_inventory[Defs.RESOURCE_WOOD] = 0
	game.begin_placement(Defs.BUILDING_BARRACKS)
	print("PT31_UI unafford placement='%s' panel=%s toast=%s body='%s'" % [game.placement_type, str(game.placement_panel.visible), str(game.alert_panel.visible), game.toast_body.text])
	_check(not game.placement_panel.visible, "stale INVALID/placement hint hidden on unaffordable click")
	_check(game.alert_panel.visible and game.toast_body.text.contains("Barracks"), "single toast names the building and missing resource")
	_check(game.resource_chip_flash_until.size() > 0, "missing resource chip flashes in the top bar")
	game._update_ui()
	var tip_back := false
	for btn in game.build_strip_buttons:
		if String((btn as Button).tooltip_text) != "":
			tip_back = true
	_check(tip_back, "strip tooltips return when not placing")

	# 4) Pressure indicator reflects night/raid.
	sim.is_night = true
	sim.phase_time = 10.0
	sim._spawn_enemy(Vector2i(1, 1), 30, 1, 0.0, 0, sim.ENEMY_RAIDER)
	game._update_ui()
	var text: String = game.pressure_meter.display_text()
	print("PT31_UI pressure_text='%s' band=%s" % [text, game.pressure_meter.band])
	_check(text.begins_with("RAID"), "pressure badge reads RAID during a night raid")
	sim.enemies.clear()
	game._update_ui()
	_check(String(game.pressure_meter.display_text()).begins_with("NIGHT"), "pressure badge reads NIGHT at night without hostiles")
	sim.is_night = false
	game._update_ui()
	_check(String(game.pressure_meter.display_text()).begins_with("PRESSURE"), "pressure badge reads PRESSURE by day")

	game.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	if failures.is_empty():
		print("PT31_UI PASS")
		quit(0)
	else:
		print("PT31_UI FAIL %d" % failures.size())
		quit(1)


func _check(ok: bool, label: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		failures.append(label)
