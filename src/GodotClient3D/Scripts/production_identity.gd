extends RefCounted

## Central presentation identity for Shards & Sovereign.
## Lumen = warm civilisation. Wyrd = cyan/violet temptation. UI supports the world.

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

const LIGHTING := {
	"day": {
		"ambient": 0.42,
		"fog_density": 0.0024,
		"fog_color": Color("#1e322c"),
		"fog_energy": 0.38,
		"saturation": 0.93,
		"contrast": 1.07,
		"sun_energy": 1.12,
		"sun_color": Color("#ffe0ac"),
		"sun_pitch": -42.0,
		"fill_energy": 0.20,
		"fill_color": Color("#849aaf"),
		"sky_top": Color("#3a5460"),
		"sky_horizon": Color("#1e322c"),
		"ground_bottom": Color("#0c1614"),
		"ground_horizon": Color("#14221c")
	},
	"dusk": {
		"ambient": 0.28,
		"fog_density": 0.0028,
		"fog_color": Color("#536477"),
		"fog_energy": 0.48,
		"saturation": 0.96,
		"contrast": 1.10,
		"sun_energy": 0.55,
		"sun_color": Color("#ff9a62"),
		"sun_pitch": -12.0,
		"fill_energy": 0.22,
		"fill_color": Color("#6a7fa0"),
		"sky_top": Color("#2a3d62"),
		"sky_horizon": Color("#e09a62"),
		"ground_bottom": Color("#1a1c22"),
		"ground_horizon": Color("#5a4a3a")
	},
	"night": {
		"ambient": 0.38,
		"fog_density": 0.0060,
		"fog_color": Color("#1c2c40"),
		"fog_energy": 0.24,
		"saturation": 0.66,
		"contrast": 1.05,
		"sun_energy": 0.24,
		"sun_color": Color("#7891b2"),
		"sun_pitch": -34.0,
		"fill_energy": 0.24,
		"fill_color": Color("#4a6480"),
		"sky_top": Color("#07101f"),
		"sky_horizon": Color("#1f3044"),
		"ground_bottom": Color("#050910"),
		"ground_horizon": Color("#162333")
	},
	"reckoning": {
		"ambient": 0.14,
		"fog_density": 0.0110,
		"fog_color": Color("#2a3d58"),
		"fog_energy": 0.38,
		"saturation": 0.78,
		"contrast": 1.20,
		"sun_energy": 0.10,
		"sun_color": Color("#6a88b0"),
		"sun_pitch": -8.0,
		"fill_energy": 0.22,
		"fill_color": Color("#5a6aa8"),
		"sky_top": Color("#0a1028"),
		"sky_horizon": Color("#3a4a78"),
		"ground_bottom": Color("#080c14"),
		"ground_horizon": Color("#1a2838")
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
	button.add_theme_stylebox_override("normal", button_style("confirm" if confirm else "normal"))
	button.add_theme_stylebox_override("hover", button_style("hover"))
	button.add_theme_stylebox_override("pressed", button_style("pressed"))
	button.add_theme_stylebox_override("disabled", button_style("disabled"))
	button.add_theme_font_size_override("font_size", SIZE_BODY)
	button.add_theme_color_override("font_color", COLOR_NEUTRAL)
	button.add_theme_color_override("font_hover_color", COLOR_LUMEN)
	button.add_theme_color_override("font_disabled_color", COLOR_DISABLED)


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
