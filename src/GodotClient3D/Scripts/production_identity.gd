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

# The Director: GFX-02 AgX grade. Contrast lives in AgX + lifted 3D LUTs,
# not crushed B/C/S. Gold/orange stays scarce. Sun orbit is degrees around
# the camera view: 120 keeps day/dusk light upper-left (shadows lower-right)
# and the 3D sun/camera angle ≥ 90°. Night uses 300 so the moon sits opposite
# without lerping through the camera at dawn.
const PALETTE_NAVY := Color("#101A22")
const PALETTE_NIGHT_TERRAIN := Color("#24383A")
const PALETTE_FOREST := Color("#26372C")
const PALETTE_MOSS := Color("#3A6840")
const PALETTE_SUNLIT_GRASS := Color("#5A8B44")
const PALETTE_ROAD_CLAY := Color("#A88962")
const PALETTE_DRY_EARTH := Color("#806347")
const PALETTE_PLASTER := Color("#D6C6A4")
const PALETTE_TIMBER := Color("#50382D")
const PALETTE_RUST := Color("#99513B")
const PALETTE_TEAL := Color("#365B59")
const PALETTE_GOLD := Color("#D2A64C")
const PALETTE_WINDOW := Color("#F2B56B")
const PALETTE_MOON := Color("#7892AC")

const LIGHTING := {
	"day": {
		"ambient": 0.42,
		"ambient_color": PALETTE_MOON,
		"fog_density": 0.00035,
		"fog_color": Color("#6A7A78"),
		"fog_energy": 0.48,
		"fog_begin": 28.0,
		"fog_end": 65.0,
		"fog_aerial": 0.50,
		"fog_sun_scatter": 0.18,
		"saturation": 0.94,
		"contrast": 1.12,
		"exposure": 1.02,
		"brightness": 1.0,
		"tonemap_white": 7.2,
		"sun_energy": 1.50,
		"sun_color": Color("#F4CC90"),
		"sun_pitch": -25.0,
		"sun_orbit": 120.0,
		"fill_energy": 0.16,
		"fill_color": PALETTE_MOON,
		"sky_top": Color("#3E5A68"),
		"sky_horizon": Color("#C4B090"),
		"ground_bottom": Color("#2A464A"),
		"ground_horizon": Color("#4A6860"),
		"ground_tint": Color(1.04, 1.03, 0.96),
		"ground_tint_floor": 0.06,
		"ground_wash_lo": 0.70,
		"ground_wash_hi": 0.94,
		"window_color": PALETTE_WINDOW,
		"torch_color": PALETTE_WINDOW,
		"torch_range": 3.2,
		"road_lift": 0.03,
		"atmosphere_scale": 1.0,
		"terrain_lod_cheap": 0.0
	},
	"dusk": {
		"ambient": 0.58,
		"ambient_color": Color("#7A8890"),
		"fog_density": 0.0004,
		"fog_color": Color("#9A8870"),
		"fog_energy": 0.50,
		"fog_begin": 24.0,
		"fog_end": 58.0,
		"fog_aerial": 0.42,
		"fog_sun_scatter": 0.26,
		"saturation": 0.93,
		"contrast": 1.06,
		"exposure": 1.06,
		"brightness": 1.0,
		"tonemap_white": 7.0,
		"sun_energy": 1.16,
		"sun_color": Color("#F0A868"),
		"sun_pitch": -11.0,
		"sun_orbit": 120.0,
		"fill_energy": 0.30,
		"fill_color": Color("#6A88A0"),
		"sky_top": Color("#2E3A58"),
		"sky_horizon": Color("#D09060"),
		"ground_bottom": Color("#243038"),
		"ground_horizon": Color("#5A4A40"),
		"ground_tint": Color(1.26, 0.88, 0.52),
		"ground_tint_floor": 0.0,
		"ground_wash_lo": 0.42,
		"ground_wash_hi": 0.78,
		"window_color": PALETTE_WINDOW,
		"torch_color": PALETTE_WINDOW,
		"torch_range": 3.6,
		"road_lift": 0.04,
		"atmosphere_scale": 0.55,
		"terrain_lod_cheap": 0.0
	},
	"night": {
		"ambient": 0.74,
		"ambient_color": PALETTE_NIGHT_TERRAIN,
		"fog_density": 0.0006,
		"fog_color": Color("#1C3034"),
		"fog_energy": 0.38,
		"fog_begin": 20.0,
		"fog_end": 52.0,
		"fog_aerial": 0.32,
		"fog_sun_scatter": 0.08,
		"saturation": 0.92,
		"contrast": 1.0,
		"exposure": 1.0,
		"brightness": 1.0,
		"tonemap_white": 7.0,
		"sun_energy": 0.56,
		"sun_color": PALETTE_MOON,
		"sun_pitch": -48.0,
		"sun_orbit": 300.0,
		"fill_energy": 0.32,
		"fill_color": Color("#3A5058"),
		"sky_top": PALETTE_NAVY,
		"sky_horizon": PALETTE_NIGHT_TERRAIN,
		"ground_bottom": PALETTE_NAVY,
		"ground_horizon": PALETTE_NIGHT_TERRAIN,
		"ground_tint": Color(1.05, 1.10, 1.16),
		"ground_tint_floor": 0.16,
		"ground_wash_lo": 0.70,
		"ground_wash_hi": 0.94,
		"window_color": PALETTE_WINDOW,
		"torch_color": PALETTE_WINDOW,
		"torch_range": 3.8,
		"road_lift": 0.12,
		"atmosphere_scale": 0.35,
		"terrain_lod_cheap": 1.0
	},
	"reckoning": {
		"ambient": 0.44,
		"ambient_color": Color("#1A2438"),
		"fog_density": 0.0010,
		"fog_color": Color("#243458"),
		"fog_energy": 0.48,
		"fog_begin": 16.0,
		"fog_end": 46.0,
		"fog_aerial": 0.32,
		"fog_sun_scatter": 0.08,
		"saturation": 0.92,
		"contrast": 1.0,
		"exposure": 0.92,
		"brightness": 1.0,
		"tonemap_white": 6.8,
		"sun_energy": 0.28,
		"sun_color": Color("#7A9AD0"),
		"sun_pitch": -42.0,
		"sun_orbit": 300.0,
		"fill_energy": 0.20,
		"fill_color": Color("#4A5A98"),
		"sky_top": PALETTE_NAVY,
		"sky_horizon": Color("#3A4A78"),
		"ground_bottom": PALETTE_NAVY,
		"ground_horizon": Color("#1A2838"),
		"ground_tint": Color(0.78, 0.84, 1.02),
		"ground_tint_floor": 0.08,
		"ground_wash_lo": 0.70,
		"ground_wash_hi": 0.94,
		"window_color": PALETTE_WINDOW,
		"torch_color": PALETTE_WINDOW,
		"torch_range": 4.0,
		"road_lift": 0.10,
		"atmosphere_scale": 0.28,
		"terrain_lod_cheap": 1.0
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
	var palette := Dictionary(LIGHTING.get(state, LIGHTING["day"])).duplicate(true)
	palette["grade"] = state
	return palette


static func mix_lighting(from_state: String, to_state: String, weight: float) -> Dictionary:
	var from_palette := lighting_palette(from_state)
	var to_palette := lighting_palette(to_state)
	var mixed := {}
	for key in from_palette:
		var from_value = from_palette[key]
		var to_value = to_palette[key]
		if typeof(from_value) == TYPE_COLOR:
			mixed[key] = (from_value as Color).lerp(to_value as Color, weight)
		elif typeof(from_value) == TYPE_STRING:
			mixed[key] = String(to_value) if weight >= 0.5 else String(from_value)
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


# The Director: per-period 17³ LUTs. Shadows are lifted (no 0.18→0.11 crush).
# Chroma is held so AgX + sat 0.92–0.96 cannot overshoot the GFX-1 pixel-sat caps.
const LUT_SIZE := 17
static var _lut_cache: Dictionary = {}

const GRADE := {
	"day": {
		"knots": [Vector2(0.0, 0.04), Vector2(0.18, 0.14), Vector2(0.45, 0.47), Vector2(0.72, 0.86), Vector2(1.0, 0.97)],
		"shadow": Color("#2A3A38"),
		"highlight": Color("#F2D8B0"),
		"shadow_w": 0.10,
		"highlight_w": 0.08,
		"chroma": 0.92
	},
	"dusk": {
		"knots": [Vector2(0.0, 0.05), Vector2(0.18, 0.16), Vector2(0.45, 0.48), Vector2(0.72, 0.82), Vector2(1.0, 0.96)],
		"shadow": Color("#3A4A58"),
		"highlight": Color("#F2C090"),
		"shadow_w": 0.12,
		"highlight_w": 0.10,
		"chroma": 0.90
	},
	"night": {
		"knots": [Vector2(0.0, 0.05), Vector2(0.18, 0.16), Vector2(0.45, 0.46), Vector2(0.72, 0.74), Vector2(1.0, 0.90)],
		"shadow": PALETTE_NIGHT_TERRAIN,
		"highlight": PALETTE_MOON,
		"shadow_w": 0.12,
		"highlight_w": 0.05,
		"chroma": 0.78
	},
	"reckoning": {
		"knots": [Vector2(0.0, 0.05), Vector2(0.18, 0.18), Vector2(0.45, 0.44), Vector2(0.72, 0.70), Vector2(1.0, 0.88)],
		"shadow": Color("#1A2438"),
		"highlight": Color("#7A9AD0"),
		"shadow_w": 0.12,
		"highlight_w": 0.06,
		"chroma": 0.68
	}
}


static func grade_lut_for(period: String) -> Texture:
	var key := "1d:%s" % (period if GRADE.has(period) else "day")
	if _lut_cache.has(key):
		return _lut_cache[key]
	var tex := _build_grade_lut1d(key.substr(3))
	_lut_cache[key] = tex
	return tex


static func grade_lut3d_for(period: String) -> Texture3D:
	var key := "3d:%s" % (period if GRADE.has(period) else "day")
	if _lut_cache.has(key):
		return _lut_cache[key]
	var tex := _build_grade_lut3d(key.substr(3))
	_lut_cache[key] = tex
	return tex


static func build_grade_lut() -> Texture:
	return grade_lut_for("day")


static func _build_grade_lut1d(period: String) -> ImageTexture:
	var image := Image.create(256, 1, false, Image.FORMAT_RGB8)
	for index in 256:
		var t := float(index) / 255.0
		image.set_pixel(index, 0, _grade_sample(Color(t, t, t), period))
	return ImageTexture.create_from_image(image)


static func _build_grade_lut3d(period: String) -> ImageTexture3D:
	var size := LUT_SIZE
	var images: Array[Image] = []
	for z in size:
		var image := Image.create(size, size, false, Image.FORMAT_RGB8)
		for y in size:
			for x in size:
				var sample := Color(float(x) / float(size - 1), float(y) / float(size - 1), float(z) / float(size - 1))
				image.set_pixel(x, y, _grade_sample(sample, period))
		images.append(image)
	var tex := ImageTexture3D.new()
	tex.create(Image.FORMAT_RGB8, size, size, size, false, images)
	return tex


static func _grade_sample(color: Color, period: String) -> Color:
	var spec: Dictionary = GRADE.get(period, GRADE["day"])
	var luma := color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
	var lifted := _grade_curve(luma, spec["knots"])
	var graded := Color(lifted, lifted, lifted)
	if luma > 0.0008:
		var gain := lifted / luma
		graded = Color(color.r * gain, color.g * gain, color.b * gain)
	var chroma := float(spec.get("chroma", 0.78))
	graded = Color(lifted, lifted, lifted).lerp(graded, chroma)
	if lifted < 0.38:
		var shadow_w := (0.38 - lifted) / 0.38 * float(spec.get("shadow_w", 0.10))
		graded = graded.lerp(spec["shadow"], shadow_w)
	elif lifted > 0.62:
		var highlight_w := (lifted - 0.62) / 0.38 * float(spec.get("highlight_w", 0.07))
		graded = graded.lerp(spec["highlight"], highlight_w)
	if period == "dusk":
		graded = graded.lerp(Color("#E8B070"), 0.02)
	return Color(clampf(graded.r, 0.0, 1.0), clampf(graded.g, 0.0, 1.0), clampf(graded.b, 0.0, 1.0))


static func _grade_curve(t: float, knots: Array) -> float:
	for index in range(1, knots.size()):
		var a: Vector2 = knots[index - 1]
		var b: Vector2 = knots[index]
		if t <= b.x:
			var w := 0.0 if is_equal_approx(b.x, a.x) else (t - a.x) / (b.x - a.x)
			return lerpf(a.y, b.y, w)
	return (knots[knots.size() - 1] as Vector2).y


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
