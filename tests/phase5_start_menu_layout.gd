extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	await process_frame
	var overlay: Control = game.startup_overlay
	_check(failures, overlay != null and overlay.visible, "launch shows the start overlay")
	var panel: Control = overlay.find_child("StartPanel", true, false)
	var new_realm: Button = overlay.find_child("NewSettlement", true, false)
	var continue_button: Button = overlay.find_child("LoadSettlement", true, false)
	var settings: Button = overlay.find_child("OpenSettings", true, false)
	var quit_button: Button = overlay.find_child("QuitGame", true, false)
	_check(failures, panel != null and new_realm != null and continue_button != null and settings != null and quit_button != null, "start menu has New Realm, Continue, Settings, and Quit")
	_check(failures, game.resume_button == null or not game.resume_button.visible, "Resume stays hidden before a run has begun")
	if panel != null and new_realm != null:
		var viewport := game.get_viewport().get_visible_rect()
		var panel_rect := panel.get_global_rect()
		var new_rect := new_realm.get_global_rect()
		print("PHASE5_MENU panel=%s new_realm=%s viewport=%s" % [panel_rect, new_rect, viewport])
		_check(failures, viewport.encloses(panel_rect), "start panel stays fully on screen")
		_check(failures, viewport.encloses(new_rect) and new_rect.size.y >= 24.0, "NEW REALM is on screen and clickable")
		new_realm.pressed.emit()
		await process_frame
		var begin_button: Button = overlay.find_child("BeginRealm", true, false)
		_check(failures, game.new_realm_card != null and game.new_realm_card.visible and begin_button != null, "NEW REALM opens the begin card")
		if begin_button != null:
			_check(failures, viewport.encloses(begin_button.get_global_rect()), "BEGIN stays on screen")
	game.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	if failures.is_empty():
		print("PHASE5_START_MENU PASS")
		quit(0)
	else:
		for line in failures:
			print("FAIL %s" % line)
		print("PHASE5_START_MENU FAIL %d" % failures.size())
		quit(1)


func _check(failures: Array[String], condition: bool, label: String) -> void:
	print("%s %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		failures.append(label)
