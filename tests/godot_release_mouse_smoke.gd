extends SceneTree

var failures: Array[String] = []
var view


func _init() -> void:
	if DisplayServer.get_name() == "headless":
		print("RELEASE_MOUSE_SMOKE SKIP: rendered GUI input is required.")
		quit(0)
		return
	call_deferred("_run")


func _run() -> void:
	var packed_scene: PackedScene = load("res://src/GodotClient/Scenes/main.tscn")
	view = packed_scene.instantiate()
	root.add_child(view)
	await process_frame
	await process_frame

	var how_button := _find_button(view.main_menu_root, "How to Play")
	_check(how_button != null, "How to Play button exists")
	if how_button != null:
		await _click_button(how_button)
	_check(view.how_to_card.visible and not view.main_menu_card.visible, "mouse click opens How to Play")

	var back_button := _find_visible_button(view.main_menu_root, "Back")
	_check(back_button != null, "How to Play Back button is reachable")
	if back_button != null:
		await _click_button(back_button)
	_check(view.main_menu_card.visible and not view.how_to_card.visible, "mouse click returns from How to Play")

	var settings_button := _find_button(view.main_menu_root, "Settings")
	_check(settings_button != null, "Settings button exists")
	if settings_button != null:
		await _click_button(settings_button)
	_check(view.settings_card.visible and not view.main_menu_card.visible, "mouse click opens Settings")

	back_button = _find_visible_button(view.main_menu_root, "Back")
	if back_button != null:
		await _click_button(back_button)
	var play_button := _find_button(view.main_menu_root, "Play Demo / New Game")
	_check(play_button != null, "Play Demo button exists")
	if play_button != null:
		await _click_button(play_button)
	_check(view.game_started and not view.main_menu_root.visible, "mouse click starts a new game")

	view._open_pause_menu()
	await process_frame
	var resume_button := _find_button(view.pause_menu_root, "Resume")
	_check(resume_button != null, "pause Resume button exists")
	if resume_button != null:
		await _click_button(resume_button)
	_check(not view.paused and not view.pause_menu_root.visible, "mouse click resumes from pause")

	if failures.is_empty():
		print("RELEASE_MOUSE_SMOKE PASS")
		quit(0)
	else:
		for failure in failures:
			print("FAIL: %s" % failure)
		print("RELEASE_MOUSE_SMOKE FAIL (%d)" % failures.size())
		quit(1)


func _click_button(button: Button) -> void:
	var center := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = center
	motion.global_position = center
	Input.parse_input_event(motion)
	await process_frame

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = center
	press.global_position = center
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = center
	release.global_position = center
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame


func _find_button(node: Node, text: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text == text:
			return child
		var nested := _find_button(child, text)
		if nested != null:
			return nested
	return null


func _find_visible_button(node: Node, text: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text == text and child.is_visible_in_tree():
			return child
		var nested := _find_visible_button(child, text)
		if nested != null:
			return nested
	return null


func _check(condition: bool, label: String) -> void:
	print("%s %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		failures.append(label)
