extends RefCounted

## Central presentation identity for Shards & Sovereign.
## Lumen = warm civilisation. Wyrd = cyan/violet temptation. UI supports the world.

const HudSkin = preload("res://src/GodotClient3D/Scripts/production_hud_skin.gd")

const COLOR_LUMEN := Color("#efcf8a")
const COLOR_LUMEN_WARM := Color("#ffc879")
const COLOR_LUMEN_FIRE := Color("#ff9a52")
const COLOR_WYRD := Color("#6bcfe0")
const COLOR_WYRD_DEEP := Color("#3b6d8a")
const COLOR_WYRD_VIOLET := Color("#7a6bb8")
const COLOR_WARNING := Color("#e0a15c")
const COLOR_DANGER := Color("#e37b6a")
const COLOR_NEUTRAL := Color("#e3e1cd")
const COLOR_MUTED := Color("#9fb7b0")
const COLOR_RIVAL := Color("#9b3943")
const COLOR_RIVAL_CLOTH := Color("#6e2430")
const COLOR_PLAYER_BANNER := Color("#3f7380")
const COLOR_DISABLED := Color("#5a6460")
const COLOR_PANEL := Color(0.045, 0.055, 0.057, 0.86)
const COLOR_PANEL_BORDER := Color("#526f6c")
const COLOR_MENU_PANEL := Color(0.035, 0.045, 0.052, 0.88)

const SIZE_TITLE := 34
const SIZE_HEADING := 20
const SIZE_BODY := 14
const SIZE_NUMERIC := 13
const SIZE_CAPTION := 11
const SIZE_WARNING := 16

const AUDIO_SETTINGS_PATH := "user://one_shard_audio.json"

# The Director: GFX-1 direction B. Sun orbit is degrees around from the camera
# view direction: 120 keeps day/dusk light entering upper-left (shadows
# lower-right) and the 3D sun/camera angle ≥ 90°. Night uses 300 so the moon
# sits on the opposite side without lerping through the camera during dawn.
const LIGHTING := {
	"day": {
		"ambient": 0.58,
		"ambient_color": Color("#718FA3"),
		"fog_density": 0.0004,
		"fog_color": Color("#607681"),
		"fog_energy": 0.55,
		"fog_begin": 28.0,
		"fog_end": 65.0,
		"fog_aerial": 0.55,
		"fog_sun_scatter": 0.25,
		"saturation": 0.52,
		"contrast": 1.52,
		"exposure": 1.06,
		"brightness": 1.08,
		"tonemap_white": 6.5,
		"sun_energy": 1.45,
		"sun_color": Color("#FFC888"),
		"sun_pitch": -25.0,
		"sun_orbit": 120.0,
		"fill_energy": 0.18,
		"fill_color": Color("#7A93A6"),
		"sky_top": Color("#3E5A68"),
		"sky_horizon": Color("#C4A882"),
		"ground_bottom": Color("#14241E"),
		"ground_horizon": Color("#2E4036"),
		"ground_tint": Color(1.02, 1.04, 0.98),
		"window_color": Color("#FFB347"),
		"torch_color": Color("#FFB347"),
		"torch_range": 5.5,
		"road_lift": 0.04,
		"atmosphere_scale": 1.0
	},
	"dusk": {
		"ambient": 0.80,
		"ambient_color": Color("#A87848"),
		"fog_density": 0.00045,
		"fog_color": Color("#C89058"),
		"fog_energy": 0.64,
		"fog_begin": 24.0,
		"fog_end": 58.0,
		"fog_aerial": 0.48,
		"fog_sun_scatter": 0.38,
		"saturation": 0.48,
		"contrast": 1.12,
		"exposure": 1.22,
		"brightness": 1.14,
		"tonemap_white": 6.2,
		"sun_energy": 1.10,
		"sun_color": Color("#FFC080"),
		"sun_pitch": -11.0,
		"sun_orbit": 120.0,
		"fill_energy": 0.28,
		"fill_color": Color("#B88850"),
		"sky_top": Color("#3A3A62"),
		"sky_horizon": Color("#E09058"),
		"ground_bottom": Color("#2A1810"),
		"ground_horizon": Color("#6A4830"),
		"ground_tint": Color(1.22, 0.92, 0.60),
		"window_color": Color("#FFB347"),
		"torch_color": Color("#FFB347"),
		"torch_range": 5.8,
		"road_lift": 0.05,
		"atmosphere_scale": 0.55
	},
	"night": {
		"ambient": 0.70,
		"ambient_color": Color("#3A5580"),
		"fog_density": 0.0007,
		"fog_color": Color("#2A4060"),
		"fog_energy": 0.42,
		"fog_begin": 20.0,
		"fog_end": 52.0,
		"fog_aerial": 0.36,
		"fog_sun_scatter": 0.10,
		"saturation": 0.45,
		"contrast": 1.06,
		"exposure": 1.14,
		"brightness": 1.10,
		"tonemap_white": 5.8,
		"sun_energy": 0.52,
		"sun_color": Color("#91B8FF"),
		"sun_pitch": -48.0,
		"sun_orbit": 300.0,
		"fill_energy": 0.28,
		"fill_color": Color("#4A6588"),
		"sky_top": Color("#07101F"),
		"sky_horizon": Color("#1F3044"),
		"ground_bottom": Color("#050910"),
		"ground_horizon": Color("#162333"),
		"ground_tint": Color(0.88, 0.94, 1.10),
		"window_color": Color("#FFB347"),
		"torch_color": Color("#FFC36B"),
		"torch_range": 6.2,
		"road_lift": 0.38,
		"atmosphere_scale": 0.35
	},
	"reckoning": {
		"ambient": 0.42,
		"ambient_color": Color("#1A2040"),
		"fog_density": 0.0012,
		"fog_color": Color("#243458"),
		"fog_energy": 0.52,
		"fog_begin": 16.0,
		"fog_end": 46.0,
		"fog_aerial": 0.36,
		"fog_sun_scatter": 0.10,
		"saturation": 0.56,
		"contrast": 1.14,
		"exposure": 0.90,
		"brightness": 1.0,
		"tonemap_white": 5.4,
		"sun_energy": 0.28,
		"sun_color": Color("#7A9AD0"),
		"sun_pitch": -42.0,
		"sun_orbit": 300.0,
		"fill_energy": 0.20,
		"fill_color": Color("#4A5A98"),
		"sky_top": Color("#0A1028"),
		"sky_horizon": Color("#3A4A78"),
		"ground_bottom": Color("#080C14"),
		"ground_horizon": Color("#1A2838"),
		"ground_tint": Color(0.70, 0.78, 1.05),
		"window_color": Color("#FFB347"),
		"torch_color": Color("#FFC36B"),
		"torch_range": 6.5,
		"road_lift": 0.32,
		"atmosphere_scale": 0.28
	}
}

const PRESSURE_BAND_COLORS := {
	"QUIET": Color("#9fd4dd"),
	"STIRRING": Color("#7ec8d4"),
	"DANGEROUS": Color("#d6bd7c"),
	"SEVERE": Color("#e0a15c"),
	"CRITICAL": Color("#e37b6a")
}

const RESOURCE_CHIP_COLORS := {
	"wood": Color("#c4a06a"),
	"planks": Color("#d8c49a"),
	"stone": Color("#a8a89c"),
	"wheat": Color("#e2c86a"),
	"bread": Color("#e0a06a"),
	"wyrd": Color("#6bcfe0")
}


static func panel_style(background: Color = COLOR_PANEL, border: Color = COLOR_PANEL_BORDER, radius := 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


static func button_style(kind: String = "normal") -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	match kind:
		"hover":
			style.bg_color = Color(0.12, 0.16, 0.16, 0.96)
			style.border_color = COLOR_LUMEN
		"pressed":
			style.bg_color = Color(0.08, 0.10, 0.11, 0.98)
			style.border_color = COLOR_WYRD
		"disabled":
			style.bg_color = Color(0.06, 0.07, 0.07, 0.70)
			style.border_color = COLOR_DISABLED
		"confirm":
			style.bg_color = Color(0.14, 0.10, 0.08, 0.96)
			style.border_color = COLOR_WARNING
		_:
			style.bg_color = Color(0.07, 0.09, 0.10, 0.94)
			style.border_color = COLOR_PANEL_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


static func apply_button(button: Button, confirm := false) -> void:
	# T-SNS-UI: stone-and-gold buttons everywhere (menu and HUD alike).
	HudSkin.apply_button(button)
	if confirm:
		button.add_theme_stylebox_override("normal", HudSkin.button_box("active"))
	button.add_theme_font_size_override("font_size", SIZE_BODY)
	button.add_theme_color_override("font_hover_color", COLOR_LUMEN)


static func apply_label(label: Label, role: String) -> void:
	var size := SIZE_BODY
	var color := COLOR_NEUTRAL
	match role:
		"title":
			size = SIZE_TITLE
			color = COLOR_LUMEN
		"heading":
			size = SIZE_HEADING
			color = COLOR_LUMEN
		"caption":
			size = SIZE_CAPTION
			color = COLOR_MUTED
		"numeric":
			size = SIZE_NUMERIC
			color = COLOR_NEUTRAL
		"warning":
			size = SIZE_WARNING
			color = COLOR_WARNING
		"wyrd":
			size = SIZE_BODY
			color = COLOR_WYRD
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)


static func lighting_palette(state: String) -> Dictionary:
	return Dictionary(LIGHTING.get(state, LIGHTING["day"])).duplicate(true)


static func mix_lighting(from_state: String, to_state: String, weight: float) -> Dictionary:
	var from_palette := lighting_palette(from_state)
	var to_palette := lighting_palette(to_state)
	var mixed := {}
	for key in from_palette:
		var from_value = from_palette[key]
		var to_value = to_palette[key]
		if typeof(from_value) == TYPE_COLOR:
			mixed[key] = (from_value as Color).lerp(to_value as Color, weight)
		else:
			mixed[key] = lerpf(float(from_value), float(to_value), weight)
	return mixed


# Same blend the production root uses so tests and the game stay aligned.
static func palette_for_cycle(simulation, menu_visible := false) -> Dictionary:
	if menu_visible:
		return lighting_palette("dusk")
	if simulation == null:
		return lighting_palette("day")
	if bool(simulation.reckoning_active):
		return mix_lighting("night", "reckoning", 0.85)
	if simulation.is_night:
		return lighting_palette("night")
	var remaining: float = float(simulation.DAY_LENGTH_SECONDS) - float(simulation.phase_time)
	if remaining < 60.0:
		return mix_lighting("day", "dusk", 1.0 - pow(clampf(remaining / 60.0, 0.0, 1.0), 1.35))
	if simulation.day_count > 1 and simulation.phase_time < 40.0:
		return mix_lighting("night", "day", pow(clampf(simulation.phase_time / 40.0, 0.0, 1.0), 1.2))
	return lighting_palette("day")


static func cycle_period_name(simulation, menu_visible := false) -> String:
	if menu_visible:
		return "dusk"
	if simulation == null:
		return "day"
	if bool(simulation.reckoning_active):
		return "reckoning"
	if simulation.is_night:
		return "night"
	var remaining: float = float(simulation.DAY_LENGTH_SECONDS) - float(simulation.phase_time)
	if remaining < 60.0:
		return "dusk" if remaining < 20.0 else "day"
	return "day"


# Mild S-curve plus teal shadows / warm highlights. 256x1 RGB LUT.
static func build_grade_lut() -> ImageTexture:
	var image := Image.create(256, 1, false, Image.FORMAT_RGB8)
	for index in 256:
		var t := float(index) / 255.0
		var y := _grade_curve(t)
		var color := Color(y, y, y)
		if t < 0.38:
			var shadow_w := (0.38 - t) / 0.38 * 0.14
			color = color.lerp(Color(0.10, 0.18, 0.24), shadow_w)
		elif t > 0.62:
			var highlight_w := (t - 0.62) / 0.38 * 0.12
			color = color.lerp(Color(1.0, 0.90, 0.76), highlight_w)
		image.set_pixel(index, 0, color)
	return ImageTexture.create_from_image(image)


static func _grade_curve(t: float) -> float:
	# Authored: 0→0, 0.18→0.11, 0.45→0.48, 0.72→0.86, 1→0.96
	var knots := [
		Vector2(0.0, 0.0),
		Vector2(0.18, 0.11),
		Vector2(0.45, 0.48),
		Vector2(0.72, 0.86),
		Vector2(1.0, 0.96)
	]
	for index in range(1, knots.size()):
		var a: Vector2 = knots[index - 1]
		var b: Vector2 = knots[index]
		if t <= b.x:
			var w := 0.0 if is_equal_approx(b.x, a.x) else (t - a.x) / (b.x - a.x)
			return lerpf(a.y, b.y, w)
	return 0.96


static func load_audio_settings() -> Dictionary:
	var defaults := {"master": 1.0, "music": 0.72, "sfx": 0.85}
	if not FileAccess.file_exists(AUDIO_SETTINGS_PATH):
		return defaults
	var file := FileAccess.open(AUDIO_SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return defaults
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return defaults
	for key in defaults:
		defaults[key] = clampf(float(parsed.get(key, defaults[key])), 0.0, 1.0)
	return defaults


static func save_audio_settings(settings: Dictionary) -> void:
	var file := FileAccess.open(AUDIO_SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(settings, "\t"))
