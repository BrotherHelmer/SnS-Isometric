extends RefCounted

## Access-1: player settings persisted to user://settings.cfg and applied at boot.
## The Director: keep the default master volume exactly as shipped (1.0).

const PATH := "user://settings.cfg"
const LEGACY_DISPLAY_PATH := "user://display_settings.cfg"
const QualityProfile = preload("res://src/GodotClient3D/Scripts/production_quality_profile.gd")
const Identity = preload("res://src/GodotClient3D/Scripts/production_identity.gd")

const DISPLAY_MODES := ["windowed", "fullscreen", "borderless"]
const RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]
const KEY_BINDINGS := [
	{"action": "Pan camera", "keys": "W A S D  ·  arrow keys  ·  middle-drag  ·  edge of screen"},
	{"action": "Zoom", "keys": "Mouse wheel"},
	{"action": "Rotate view", "keys": "Q  ·  E"},
	{"action": "Pause / resume", "keys": "Space  ·  Esc"},
	{"action": "Build palette", "keys": "B"},
	{"action": "Place / confirm", "keys": "Left click"},
	{"action": "Cancel placement", "keys": "Right click  ·  Esc"},
	{"action": "Rotate building", "keys": "R"},
	{"action": "Build hotkeys", "keys": "1–0  ·  Z X C V"},
	{"action": "Town Hall", "keys": "H"},
	{"action": "Event log", "keys": "L"},
	{"action": "Scout aim", "keys": "Y"},
]


static func defaults() -> Dictionary:
	return {
		"display_mode": "windowed",
		"width": 1280,
		"height": 720,
		"vsync": true,
		"ui_scale": 1.0,
		"graphics_preset": "high",
		"master": 1.0,
		"music": 0.72,
		"sfx": 0.85,
		"edge_pan": true,
		"camera_speed": 1.0,
		"tutorial_enabled": true,
	}


static func normalize_preset(name: String) -> String:
	return QualityProfile.resolve_name(name)


static func load_settings() -> Dictionary:
	var settings := defaults()
	_merge_legacy(settings)
	var file := ConfigFile.new()
	if file.load(PATH) != OK:
		return settings
	settings["display_mode"] = _normalize_mode(String(file.get_value("display", "mode", settings["display_mode"])))
	settings["width"] = int(file.get_value("display", "width", settings["width"]))
	settings["height"] = int(file.get_value("display", "height", settings["height"]))
	settings["vsync"] = bool(file.get_value("display", "vsync", settings["vsync"]))
	settings["ui_scale"] = clampf(float(file.get_value("display", "ui_scale", settings["ui_scale"])), 0.80, 1.50)
	settings["graphics_preset"] = normalize_preset(String(file.get_value("graphics", "preset", settings["graphics_preset"])))
	# Never invent a quieter default: only replace master when the file has a value.
	if file.has_section_key("audio", "master"):
		settings["master"] = clampf(float(file.get_value("audio", "master", 1.0)), 0.0, 1.0)
	settings["music"] = clampf(float(file.get_value("audio", "music", settings["music"])), 0.0, 1.0)
	settings["sfx"] = clampf(float(file.get_value("audio", "sfx", settings["sfx"])), 0.0, 1.0)
	settings["edge_pan"] = bool(file.get_value("camera", "edge_pan", settings["edge_pan"]))
	settings["camera_speed"] = clampf(float(file.get_value("camera", "speed", settings["camera_speed"])), 0.40, 2.50)
	settings["tutorial_enabled"] = bool(file.get_value("tutorial", "enabled", settings["tutorial_enabled"]))
	return settings


static func save_settings(settings: Dictionary) -> bool:
	var file := ConfigFile.new()
	var merged := defaults()
	merged.merge(settings, true)
	merged["display_mode"] = _normalize_mode(String(merged.get("display_mode", "windowed")))
	merged["ui_scale"] = clampf(float(merged.get("ui_scale", 1.0)), 0.80, 1.50)
	merged["graphics_preset"] = normalize_preset(String(merged.get("graphics_preset", "high")))
	merged["master"] = clampf(float(merged.get("master", 1.0)), 0.0, 1.0)
	merged["music"] = clampf(float(merged.get("music", 0.72)), 0.0, 1.0)
	merged["sfx"] = clampf(float(merged.get("sfx", 0.85)), 0.0, 1.0)
	merged["camera_speed"] = clampf(float(merged.get("camera_speed", 1.0)), 0.40, 2.50)
	file.set_value("display", "mode", merged["display_mode"])
	file.set_value("display", "width", int(merged["width"]))
	file.set_value("display", "height", int(merged["height"]))
	file.set_value("display", "vsync", bool(merged["vsync"]))
	file.set_value("display", "ui_scale", float(merged["ui_scale"]))
	file.set_value("graphics", "preset", merged["graphics_preset"])
	file.set_value("audio", "master", float(merged["master"]))
	file.set_value("audio", "music", float(merged["music"]))
	file.set_value("audio", "sfx", float(merged["sfx"]))
	file.set_value("camera", "edge_pan", bool(merged["edge_pan"]))
	file.set_value("camera", "speed", float(merged["camera_speed"]))
	file.set_value("tutorial", "enabled", bool(merged["tutorial_enabled"]))
	return file.save(PATH) == OK


static func apply_display(settings: Dictionary) -> void:
	var mode := _normalize_mode(String(settings.get("display_mode", "windowed")))
	match mode:
		"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		"borderless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			var size := Vector2i(int(settings.get("width", 1280)), int(settings.get("height", 720)))
			if size.x >= 640 and size.y >= 360:
				DisplayServer.window_set_size(size)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if bool(settings.get("vsync", true)) else DisplayServer.VSYNC_DISABLED
	)
	_apply_ui_scale(float(settings.get("ui_scale", 1.0)))


static func apply_audio(settings: Dictionary, audio_director) -> void:
	var payload := {
		"master": clampf(float(settings.get("master", 1.0)), 0.0, 1.0),
		"music": clampf(float(settings.get("music", 0.72)), 0.0, 1.0),
		"sfx": clampf(float(settings.get("sfx", 0.85)), 0.0, 1.0),
	}
	if audio_director != null and audio_director.has_method("apply_settings"):
		audio_director.apply_settings(payload)
	else:
		Identity.save_audio_settings(payload)


static func apply_camera(settings: Dictionary, camera_rig) -> void:
	if camera_rig == null:
		return
	if camera_rig.has_method("set_access_controls"):
		camera_rig.set_access_controls(
			clampf(float(settings.get("camera_speed", 1.0)), 0.40, 2.50),
			bool(settings.get("edge_pan", true))
		)
	else:
		camera_rig.set("move_speed_scale", clampf(float(settings.get("camera_speed", 1.0)), 0.40, 2.50))
		camera_rig.set("edge_pan_enabled", bool(settings.get("edge_pan", true)))


static func window_mode_name() -> String:
	match DisplayServer.window_get_mode():
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			return "fullscreen"
		DisplayServer.WINDOW_MODE_FULLSCREEN:
			return "borderless"
		_:
			return "windowed"


static func _apply_ui_scale(scale: float) -> void:
	var window := Engine.get_main_loop()
	if window is SceneTree and (window as SceneTree).root != null:
		(window as SceneTree).root.content_scale_factor = clampf(scale, 0.80, 1.50)


static func _normalize_mode(mode: String) -> String:
	var key := mode.strip_edges().to_lower()
	if key in DISPLAY_MODES:
		return key
	if key == "exclusive" or key == "exclusive_fullscreen":
		return "fullscreen"
	return "windowed"


static func _merge_legacy(settings: Dictionary) -> void:
	var display := ConfigFile.new()
	if display.load(LEGACY_DISPLAY_PATH) == OK:
		if bool(display.get_value("display", "fullscreen", false)):
			settings["display_mode"] = "fullscreen"
		settings["graphics_preset"] = normalize_preset(String(display.get_value("display", "quality", settings["graphics_preset"])))
	var audio := Identity.load_audio_settings()
	settings["master"] = float(audio.get("master", settings["master"]))
	settings["music"] = float(audio.get("music", settings["music"]))
	settings["sfx"] = float(audio.get("sfx", settings["sfx"]))
