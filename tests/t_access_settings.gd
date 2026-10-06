extends SceneTree

## Access-1: settings persist to user://settings.cfg and apply at boot.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const UserSettings = preload("res://src/GodotClient3D/Scripts/production_user_settings.gd")
const QualityProfile = preload("res://src/GodotClient3D/Scripts/production_quality_profile.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var defaults := UserSettings.defaults()
	_check(is_equal_approx(float(defaults.get("master", -1.0)), 1.0), "default master volume stays 1.0")
	_check(String(defaults.get("graphics_preset", "")) == "high", "default graphics preset is High")
	_check(QualityProfile.resolve_name("recommended") == "high", "recommended maps to High")
	_check(QualityProfile.resolve_name("scalable_low") == "low", "scalable_low maps to Low")

	var payload := UserSettings.defaults()
	payload["display_mode"] = "borderless"
	payload["width"] = 1920
	payload["height"] = 1080
	payload["vsync"] = false
	payload["ui_scale"] = 1.25
	payload["graphics_preset"] = "medium"
	payload["master"] = 1.0
	payload["music"] = 0.40
	payload["sfx"] = 0.55
	payload["edge_pan"] = false
	payload["camera_speed"] = 1.70
	payload["tutorial_enabled"] = false
	_check(UserSettings.save_settings(payload), "settings.cfg writes")
	var loaded := UserSettings.load_settings()
	_check(String(loaded.get("display_mode", "")) == "borderless", "display mode persists")
	_check(int(loaded.get("width", 0)) == 1920 and int(loaded.get("height", 0)) == 1080, "resolution persists")
	_check(bool(loaded.get("vsync", true)) == false, "vsync persist")
	_check(is_equal_approx(float(loaded.get("ui_scale", 0.0)), 1.25), "UI scale persists")
	_check(String(loaded.get("graphics_preset", "")) == "medium", "preset persists as medium")
	_check(is_equal_approx(float(loaded.get("master", 0.0)), 1.0), "master volume is unchanged from the shipped default")
	_check(is_equal_approx(float(loaded.get("music", 0.0)), 0.40), "music volume persists")
	_check(not bool(loaded.get("edge_pan", true)), "edge-pan persists off")
	_check(is_equal_approx(float(loaded.get("camera_speed", 0.0)), 1.70), "camera speed persists")
	_check(not bool(loaded.get("tutorial_enabled", true)), "tutorial flag persists")

	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	_check(game.startup_overlay != null and game.startup_overlay.visible, "title menu still opens")
	_check(game.continue_button != null and game.load_button != null, "Continue and Load exist")
	_check(game.menu_card.find_child("NewSettlement", true, false) != null, "New Game keeps the NewSettlement node")
	_check(game.menu_card.find_child("OpenSettings", true, false) != null, "Options keeps the OpenSettings node")
	_check(String((game.menu_card.find_child("NewSettlement", true, false) as Button).text) == "NEW GAME", "title offers New Game")
	_check(String((game.menu_card.find_child("OpenSettings", true, false) as Button).text) == "OPTIONS", "title offers Options")
	game.apply_quality_profile("high")
	_check(game.environment_resource.ssao_enabled, "High keeps daytime SSAO")
	_check(game.sun_light.shadow_enabled, "High keeps shadows")
	_check(is_equal_approx(game.get_viewport().scaling_3d_scale, 1.0), "High render scale is 1.0")
	_check(game.get_viewport().msaa_3d == Viewport.MSAA_2X, "High uses MSAA 2x")
	game.apply_quality_profile("medium")
	_check(game.get_viewport().screen_space_aa == Viewport.SCREEN_SPACE_AA_FXAA, "Medium uses FXAA")
	_check(game.get_viewport().scaling_3d_scale < 0.95, "Medium lowers render scale")
	game.apply_quality_profile("low")
	_check(not game.environment_resource.ssao_enabled, "Low turns SSAO off")
	_check(not game.sun_light.shadow_enabled, "Low turns shadows off")
	_check(game.get_viewport().msaa_3d == Viewport.MSAA_DISABLED, "Low disables MSAA")
	_check(game.get_viewport().scaling_3d_scale <= 0.75, "Low render scale is clearly cheaper")
	_check(float(game.quality_profile.get("foliage_density", 1.0)) < 0.50, "Low cuts ground detail")
	game.apply_quality_profile("recommended")
	_check(game.sun_light.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS, "recommended High still uses PSSM 2-split")
	game.user_settings["ui_scale"] = 1.20
	game._apply_hud_font_scale()
	_check(game.hud_root.theme.default_font_size >= 16, "HUD font respects UI scale")
	var strip: Button = game.build_strip_buttons[0]
	_check(String(strip.tooltip_text).contains("Cost") and String(strip.tooltip_text).contains("Connects"), "build bar tooltip has name, cost, and purpose")
	game.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	print("T_ACCESS_SETTINGS %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
