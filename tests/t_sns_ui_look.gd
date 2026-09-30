extends SceneTree

## T-SNS-UI Look lift: top bar fits 1280 px, no clipped labels, 11 px type
## floor, building thumbnails present (grid + portrait), top-right RAID banner
## with count/direction/ETA and no centre pop-ups, pressure-chip rule, clock
## countdown, icon speed controls.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const HudSkin = preload("res://src/GodotClient3D/Scripts/production_hud_skin.gd")
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
	game._hide_start_menu()
	for _i in 4:
		await process_frame
	var sim = game.simulation_host.simulation
	game._update_ui()
	await process_frame

	# 1) Pressure-chip rule (Q6): hidden while QUIET by day, shown at night/raid/above QUIET.
	sim.is_night = false
	sim.enemies.clear()
	game._update_ui()
	print("LOOK band=%s visible=%s" % [game.pressure_meter.band, str(game.pressure_meter.visible)])
	_check("QUIET" in String(game.pressure_meter.band) and not game.pressure_meter.visible, "pressure chip hidden while QUIET by day")
	_check(game._pressure_chip_should_show("RISING", false, 0) and game._pressure_chip_should_show("HIGH", false, 0), "pressure chip rule shows any band above QUIET")
	_check(game.day_icon.get_parent().get_parent().tooltip_text.contains("Wyrd Pressure"), "QUIET state is in the clock tooltip while the chip is hidden")
	sim.is_night = true
	sim.phase_time = 5.0
	game._update_ui()
	_check(game.pressure_meter.visible, "pressure chip shown at night")

	# 2) Clock countdown instead of a season.
	var countdown: String = game.phase_label.text
	var clock_re := RegEx.new()
	clock_re.compile("^(Night|Dawn) in \\d+:\\d\\d$")
	print("LOOK clock='%s' / '%s'" % [game.time_label.text, countdown])
	_check(clock_re.search(countdown) != null and countdown.begins_with("Dawn"), "clock shows 'Dawn in m:ss' at night")
	sim.is_night = false
	game._update_ui()
	_check(String(game.phase_label.text).begins_with("Night in"), "clock shows 'Night in m:ss' by day")

	# 3) RAID banner: top-right, count + direction + numeric ETA; no centre pop-up.
	sim.is_night = true
	sim.phase_time = 5.0
	var town: Vector2i = sim.town_hall_position
	sim._spawn_enemy(town + Vector2i(-22, 1), 30, 1, 0.0, 0, sim.ENEMY_RAIDER)
	sim._spawn_enemy(town + Vector2i(-24, 3), 30, 1, 0.0, 0, sim.ENEMY_RAIDER)
	game._update_ui()
	await process_frame
	var banner: Control = game.alert_panel
	var banner_rect: Rect2 = banner.get_global_rect()
	var eta_text: String = game.raid_eta_label.text
	print("LOOK banner=%s rect=%s eta='%s' status=%s" % [str(banner.visible), str(banner_rect), eta_text, str(game.raid_status())])
	_check(banner.visible and game.pressure_meter.visible, "raid shows the banner and the pressure chip")
	_check(banner_rect.end.x >= 1280.0 - 12.0 and banner_rect.position.x > 640.0 and banner_rect.position.y < 150.0, "banner sits top-right, not centred")
	var eta_re := RegEx.new()
	eta_re.compile("^2 raiders  ·  from the [a-z-]+  ·  ETA ~\\d+:\\d\\d$")
	_check(eta_re.search(eta_text) != null, "banner line has count, direction and numeric ETA")
	_check(int(game.raid_status().get("eta_seconds", 0)) > 0, "ETA is a positive number of seconds")
	_check(String(game.toast_title.text) == "RAID", "banner title is RAID")
	game._dismiss_toast()
	game._update_ui()
	_check(not banner.visible, "dismissed banner stays hidden for this raid")
	var feed_before: int = game.notice_feed_entries.size()
	game._show_toast("Insufficient Resources", "Barracks needs Planks", "warning", 3.5)
	_check(not banner.visible and game.notice_feed_entries.size() == feed_before + 1, "non-critical toast goes to the left feed, not a pop-up")
	sim.enemies.clear()
	game._update_ui()
	sim._spawn_enemy(town + Vector2i(-20, 0), 30, 1, 0.0, 0, sim.ENEMY_RAIDER)
	game._update_ui()
	_check(banner.visible and String(game.raid_eta_label.text).begins_with("1 raider  ·"), "a new raid re-opens the banner")
	sim.enemies.clear()
	sim.is_night = false
	game._update_ui()

	# 4) Thumbnails: every plan in the grid + Town Hall/Castle, and the portrait.
	var missing: Array[String] = []
	for building_type in game.BUILD_PALETTE + [Defs.BUILDING_TOWN_HALL, "CASTLE"]:
		if HudSkin.thumbnail(String(building_type)) == null:
			missing.append(String(building_type))
	var strip_thumbs := 0
	for btn in game.build_strip_buttons:
		var thumb := (btn as Node).find_child("Thumbnail", true, false) as TextureRect
		if thumb != null and thumb.texture != null and thumb.size.x <= game.BUILD_SLOT_SIZE.x and thumb.size.y <= 40.0 and (btn as Control).get_global_rect().grow(4.0).encloses(thumb.get_global_rect()):
			strip_thumbs += 1
		elif thumb != null:
			print("LOOK thumb %s rect=%s slot=%s" % [thumb.name, str(thumb.get_global_rect()), str((btn as Control).get_global_rect())])
	print("LOOK thumbs missing=%s strip=%d/%d" % [str(missing), strip_thumbs, game.build_strip_buttons.size()])
	_check(missing.is_empty(), "all 14 plans + Town Hall + Castle have a thumbnail")
	_check(strip_thumbs == game.build_strip_buttons.size() and strip_thumbs == 14, "every 7x2 grid slot shows its thumbnail, sized to fit inside the slot")
	var hall: Dictionary = {}
	for building_value in sim.buildings:
		if String(Dictionary(building_value).get("type", "")) == Defs.BUILDING_TOWN_HALL:
			hall = building_value
	game.select_building(int(hall.get("id", 0)))
	game._update_ui()
	await process_frame
	var portrait := game.portrait_host.find_child("PortraitThumbnail", true, false) as TextureRect
	_check(portrait != null and portrait.texture == HudSkin.thumbnail(Defs.BUILDING_TOWN_HALL) and portrait.size == Vector2(96, 72), "Town Hall portrait uses its thumbnail at portrait size")
	_check(String(game.inspector_label.text).contains("[img=16x16]") and String(game.inspector_label.text).contains("icon_shield"), "selection stats carry icons")
	_check(game.portrait_hp_label != null and String(game.portrait_hp_label.text).contains("/"), "HP bar shows its value")

	# 5) Worst-case top bar at 1280 px: raid chip + 4x speed + idle label.
	sim.is_night = true
	sim._spawn_enemy(town + Vector2i(-22, 1), 30, 1, 0.0, 0, sim.ENEMY_RAIDER)
	game._cycle_speed()
	game._cycle_speed()
	game._update_ui()
	await process_frame
	await process_frame
	var bar: Control = game.hud_root.find_child("TopBar", false, false)
	var row: Control = bar.get_child(0)
	var need: float = row.get_combined_minimum_size().x
	print("LOOK topbar need=%.0f bar=%s speed='%s'" % [need, str(bar.get_global_rect()), game.speed_button.text])
	_check(need <= 1280.0 - 12.0, "top bar fits 1280 px with the RAID chip and 4x speed shown")
	_check(game.speed_button.button_pressed and not game.play_button.button_pressed and game.speed_button.text == "4x", "fast-forward shows the active 4x state")
	game._play_normal_speed()
	_check(game.play_button.button_pressed and is_equal_approx(game.simulation_host.speed_multiplier, 1.0), "play returns to 1x")

	# 6) No clipped labels and the 11 px floor across the HUD chrome.
	var clipped: Array[String] = []
	var small: Array[String] = []
	var scopes: Array = [bar, game.hud_root.find_child("LoopBar", false, false), banner, game.selection_host, game.build_strip]
	for scope in scopes:
		for node in (scope as Node).find_children("*", "Control", true, false):
			var control := node as Control
			if not control.is_visible_in_tree():
				continue
			if control is Label or control is Button:
				var size_px: int = control.get_theme_font_size("font_size")
				if size_px < HudSkin.SIZE_MIN:
					small.append("%s=%d" % [control.get_path(), size_px])
				var text := String(control.text)
				if text == "" or (control is Label and (control as Label).autowrap_mode != TextServer.AUTOWRAP_OFF):
					continue
				if control is Button and (control as Button).clip_text:
					continue  # objective text clips by design (full text in the goal list)
				var font: Font = control.get_theme_font("font")
				var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
				var avail := control.size.x
				if control is Button:
					var box: StyleBox = control.get_theme_stylebox("normal")
					avail -= box.get_margin(SIDE_LEFT) + box.get_margin(SIDE_RIGHT)
					if (control as Button).icon != null:
						avail -= 18.0
				if width > avail + 1.0:
					clipped.append("%s '%s' %.0f>%.0f" % [control.name, text, width, avail])
			elif control is RichTextLabel:
				if int(control.get_theme_font_size("normal_font_size")) < HudSkin.SIZE_MIN:
					small.append("%s=%d" % [control.get_path(), int(control.get_theme_font_size("normal_font_size"))])
	print("LOOK clipped=%s" % str(clipped))
	print("LOOK small=%s" % str(small))
	_check(clipped.is_empty(), "no clipped labels in the top bar, loop bar, banner, selection panel or build grid")
	_check(small.is_empty(), "no HUD text under 11 px")
	_finish(game)


func _finish(game: Node) -> void:
	game.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	print("T_SNS_UI_LOOK %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
