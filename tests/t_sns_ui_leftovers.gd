extends SceneTree

## T-SNS-UI leftovers: stone-and-gold pressure badge (RAID red), idle-worker
## notice + idle-worker button. (UI-scale setting skipped: see PR notes.)

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")

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
	game.play_has_begun = true
	for _i in 4:
		await process_frame
	var sim = game.simulation_host.simulation
	game._update_ui()
	await process_frame

	# 1) Pressure badge: framed, RAID clearly red, texts unchanged.
	var meter: Control = game.pressure_meter
	_check(meter.custom_minimum_size.x >= 190.0, "badge keeps room for the framed RAID label")
	meter.set_threat(false, 0)
	_check(String(meter.display_text()).begins_with("PRESSURE"), "day badge reads PRESSURE")
	meter.set_threat(true, 2)
	_check(meter.is_raid() and String(meter.display_text()) == "RAID · 2 HOSTILES", "raid badge text")
	var raid_color: Color = meter.state_color()
	_check(raid_color.r > 0.7 and raid_color.g < 0.35 and raid_color.b < 0.3, "raid state colour is red")
	meter.set_threat(true, 0)
	_check(not meter.is_raid() and String(meter.display_text()).begins_with("NIGHT"), "night without hostiles is not RAID")
	meter.set_threat(false, 0)

	# 2) Idle workers: count, top-bar button, feed notice, rate limit, night gate.
	var idle: int = game.idle_worker_count()
	print("TSNSUI idle=%d free=%d" % [idle, int(sim.workers_free())])
	_check(idle > 0, "opening settlement has idle free workers")
	var button: Button = game.idle_workers_button
	_check(button != null and button.text == "%d idle" % idle, "idle button shows the idle count")
	_check(button.visible, "idle button is shown while settlers are idle")
	var idle_rect: Rect2 = button.get_global_rect()
	var console_rect: Rect2 = game.hud_console.get_global_rect()
	print("TSNSUI idle_button=%s console=%s" % [str(idle_rect), str(console_rect)])
	_check(Rect2(Vector2.ZERO, Vector2(1280, 720)).encloses(idle_rect), "idle button is on screen")
	_check(not idle_rect.intersects(console_rect) and idle_rect.end.y <= console_rect.position.y, "idle button sits just above the console")
	var bar_row: Control = game.hud_root.find_child("TopBar", false, false).get_child(0)
	_check(bar_row.get_combined_minimum_size().x <= 1280.0 - 12.0, "top bar still fits 1280 px with the framed badge")
	var before: int = game.notice_feed_entries.size()
	sim.is_night = false
	game.idle_workers_tracking = false
	game.idle_notice_last = -1000000.0
	game._update_idle_workers()
	_check(game.notice_feed_entries.size() == before, "no notice before the idle threshold")
	game.idle_workers_since = float(sim.elapsed_seconds) - game.IDLE_NOTICE_AFTER_SECONDS - 1.0
	game._update_idle_workers()
	_check(game.notice_feed_entries.size() == before + 1, "idle notice lands in the left feed")
	if game.notice_feed_entries.is_empty():
		_finish(game)
		return
	var node: Control = game.notice_feed_entries[0]["node"]
	var titles := []
	for label in node.find_children("*", "Label", true, false):
		titles.append((label as Label).text)
	_check("Idle workers" in titles, "feed entry is titled Idle workers")
	game.idle_workers_since = float(sim.elapsed_seconds) - game.IDLE_NOTICE_AFTER_SECONDS - 5.0
	game._update_idle_workers()
	_check(game.notice_feed_entries.size() == before + 1, "idle notice is rate-limited")
	sim.is_night = true
	game._update_idle_workers()
	_check(not game.idle_workers_tracking, "idle timer pauses at night")
	sim.is_night = false
	button.emit_signal("pressed")
	_check(game.build_panel.visible, "clicking the idle count opens BUILD")
	game._set_build_palette_visible(false)

	# 3) UI scale was skipped (top bar needs ~1223 px; 115%/130% leave 1113/985 px).
	#    Guard the reason: the 100% top bar must keep fitting 1280 px.
	_check(game.get_viewport().get_visible_rect().size.x >= bar_row.get_combined_minimum_size().x + 12.0, "top bar fits the 1280 px design width")

	_finish(game)


func _finish(game: Node) -> void:
	game.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	print("T_SNS_UI_LEFTOVERS %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
