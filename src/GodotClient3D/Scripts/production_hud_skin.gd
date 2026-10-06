extends RefCounted

## T-SNS-UI: themed HUD skin (self-made art, tools/generate_ui_art.py).
## Frames are 9-slice StyleBoxTextures so panels scale to any size without blur.
## T-SNS-UI Look lift: navy panels with a gold double hairline, two SIL-OFL
## fonts (Cinzel for display, Source Sans 3 for UI text; see
## docs/art/ASSET_LEDGER.md) and a type scale where nothing is under 11 px.

const UI_DIR := "res://assets/settlement3d/runtime/interface/ui/"
const TEX_PANEL := preload("res://assets/settlement3d/runtime/interface/ui/frame_panel.png")
const TEX_CONSOLE := preload("res://assets/settlement3d/runtime/interface/ui/frame_console.png")
const TEX_BAR := preload("res://assets/settlement3d/runtime/interface/ui/frame_bar.png")
const TEX_SLOT := preload("res://assets/settlement3d/runtime/interface/ui/frame_slot.png")
const TEX_TOAST := preload("res://assets/settlement3d/runtime/interface/ui/frame_toast.png")
const TEX_BTN_NORMAL := preload("res://assets/settlement3d/runtime/interface/ui/btn_normal.png")
const TEX_BTN_HOVER := preload("res://assets/settlement3d/runtime/interface/ui/btn_hover.png")
const TEX_BTN_PRESSED := preload("res://assets/settlement3d/runtime/interface/ui/btn_pressed.png")
const TEX_BTN_DISABLED := preload("res://assets/settlement3d/runtime/interface/ui/btn_disabled.png")
const TEX_BTN_TAB_ACTIVE := preload("res://assets/settlement3d/runtime/interface/ui/btn_tab_active.png")
const TEX_CAPSULE := preload("res://assets/settlement3d/runtime/interface/ui/frame_capsule.png")
const TEX_ALERT := preload("res://assets/settlement3d/runtime/interface/ui/frame_alert.png")
const FONT_UI_FILE := preload("res://assets/settlement3d/runtime/interface/fonts/SourceSans3-VF.ttf")
## Cinzel Bold as a resource so RichTextLabel [font=...] tags can use it.
const FONT_DISPLAY_BOLD_RES := preload("res://assets/settlement3d/runtime/interface/fonts/cinzel_bold.tres")
const FONT_DISPLAY_FILE := preload("res://assets/settlement3d/runtime/interface/fonts/Cinzel-VF.ttf")

## Type scale (px). MIN is a hard floor enforced by tests/t_sns_ui_look.gd.
const SIZE_MIN := 11
const SIZE_BADGE := 11
const SIZE_CAPTION := 13
const SIZE_BODY := 15
const SIZE_VALUE := 16
const SIZE_TITLE := 19
const SIZE_HEAD := 22
const ICONS := {
	"wood": preload("res://assets/settlement3d/runtime/interface/ui/icon_wood.png"),
	"planks": preload("res://assets/settlement3d/runtime/interface/ui/icon_planks.png"),
	"stone": preload("res://assets/settlement3d/runtime/interface/ui/icon_stone.png"),
	"wheat": preload("res://assets/settlement3d/runtime/interface/ui/icon_wheat.png"),
	"bread": preload("res://assets/settlement3d/runtime/interface/ui/icon_bread.png"),
	"wyrd": preload("res://assets/settlement3d/runtime/interface/ui/icon_wyrd.png"),
	"pop": preload("res://assets/settlement3d/runtime/interface/ui/icon_pop.png"),
	"sun": preload("res://assets/settlement3d/runtime/interface/ui/icon_sun.png"),
	"moon": preload("res://assets/settlement3d/runtime/interface/ui/icon_moon.png"),
	"soldier": preload("res://assets/settlement3d/runtime/interface/ui/icon_soldier.png"),
	"pause": preload("res://assets/settlement3d/runtime/interface/ui/icon_pause.png"),
	"play": preload("res://assets/settlement3d/runtime/interface/ui/icon_play.png"),
	"fast": preload("res://assets/settlement3d/runtime/interface/ui/icon_fast.png"),
	"menu": preload("res://assets/settlement3d/runtime/interface/ui/icon_menu.png"),
	"hammer": preload("res://assets/settlement3d/runtime/interface/ui/icon_hammer.png"),
	"hourglass": preload("res://assets/settlement3d/runtime/interface/ui/icon_hourglass.png"),
	"swords": preload("res://assets/settlement3d/runtime/interface/ui/icon_swords.png"),
	"quest": preload("res://assets/settlement3d/runtime/interface/ui/icon_quest.png"),
	"house": preload("res://assets/settlement3d/runtime/interface/ui/icon_house.png"),
	"worker": preload("res://assets/settlement3d/runtime/interface/ui/icon_worker.png"),
	"hunger": preload("res://assets/settlement3d/runtime/interface/ui/icon_hunger.png"),
	"shield": preload("res://assets/settlement3d/runtime/interface/ui/icon_shield.png"),
	"road": preload("res://assets/settlement3d/runtime/interface/ui/icon_road.png"),
}

## Building thumbnails rendered offline by tools/render_building_thumbnails.gd
## from the game's own building views (see thumbs/MANIFEST.txt).
const THUMBS := {
	"ROAD": preload("res://assets/settlement3d/runtime/interface/thumbs/ROAD.png"),
	"HOUSE": preload("res://assets/settlement3d/runtime/interface/thumbs/HOUSE.png"),
	"LUMBER_CAMP": preload("res://assets/settlement3d/runtime/interface/thumbs/LUMBER_CAMP.png"),
	"QUARRY": preload("res://assets/settlement3d/runtime/interface/thumbs/QUARRY.png"),
	"FARM": preload("res://assets/settlement3d/runtime/interface/thumbs/FARM.png"),
	"SAWMILL": preload("res://assets/settlement3d/runtime/interface/thumbs/SAWMILL.png"),
	"BAKERY": preload("res://assets/settlement3d/runtime/interface/thumbs/BAKERY.png"),
	"STOREHOUSE": preload("res://assets/settlement3d/runtime/interface/thumbs/STOREHOUSE.png"),
	"WALL": preload("res://assets/settlement3d/runtime/interface/thumbs/WALL.png"),
	"WATCHTOWER": preload("res://assets/settlement3d/runtime/interface/thumbs/WATCHTOWER.png"),
	"BARRACKS": preload("res://assets/settlement3d/runtime/interface/thumbs/BARRACKS.png"),
	"LUMEN_PILLAR": preload("res://assets/settlement3d/runtime/interface/thumbs/LUMEN_PILLAR.png"),
	"CLAIMANT_OUTPOST": preload("res://assets/settlement3d/runtime/interface/thumbs/CLAIMANT_OUTPOST.png"),
	"CLEAR_AREA": preload("res://assets/settlement3d/runtime/interface/thumbs/CLEAR_AREA.png"),
	"TOWN_HALL": preload("res://assets/settlement3d/runtime/interface/thumbs/TOWN_HALL.png"),
	"CASTLE": preload("res://assets/settlement3d/runtime/interface/thumbs/CASTLE.png"),
}

const COLOR_TEXT := Color("#ece4cc")
const COLOR_GOLD := Color("#f0c880")
const COLOR_GOLD_DIM := Color("#c49654")
const COLOR_CAPTION := Color("#b9ab86")
const COLOR_GAIN := Color("#8fe08a")
const COLOR_LOSS := Color("#ff8a78")
const COLOR_OUTLINE := Color(0.0, 0.0, 0.0, 0.85)

const COLOR_HAIRLINE := Color("#ba9066")
const COLOR_BADGE := Color("#8f8468")

static var _theme: Theme
static var _fonts := {}


## OpenType axis tag for weight. NB: a plain "wght" string key is ignored by
## FontVariation (Godot 4.7) and the VF then renders at its 200 default; the
## numeric tag (or the "weight" alias) is required.
static func _wght_tag() -> int:
	return TextServerManager.get_primary_interface().name_to_tag("wght")


## Source Sans 3 (variable) at a given weight: 400 regular, 600 semibold, 700 bold.
static func ui_font(weight: int = 400) -> Font:
	var key := "ui%d" % weight
	if not _fonts.has(key):
		var variation := FontVariation.new()
		variation.base_font = FONT_UI_FILE
		variation.variation_opentype = {_wght_tag(): weight}
		_fonts[key] = variation
	return _fonts[key]


## Cinzel (variable) for titles and banners.
static func display_font(weight: int = 700) -> Font:
	var key := "display%d" % weight
	if not _fonts.has(key):
		var variation := FontVariation.new()
		variation.base_font = FONT_DISPLAY_FILE
		variation.variation_opentype = {_wght_tag(): weight}
		variation.fallbacks = [ui_font(600)]
		_fonts[key] = variation
	return _fonts[key]


static func set_font(control: Control, font: Font, size: int, color = null) -> void:
	var font_key := "normal_font" if control is RichTextLabel else "font"
	var size_key := "normal_font_size" if control is RichTextLabel else "font_size"
	control.add_theme_font_override(font_key, font)
	control.add_theme_font_size_override(size_key, maxi(size, SIZE_MIN))
	if color != null:
		control.add_theme_color_override("default_color" if control is RichTextLabel else "font_color", color)


static func title_label(text: String, size: int = SIZE_TITLE, color: Color = COLOR_GOLD) -> Label:
	var label := Label.new()
	label.text = text
	set_font(label, display_font(700), size, color)
	label.add_theme_color_override("font_outline_color", COLOR_OUTLINE)
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## Small dim hotkey badge ("B", "Space"). Never below the 11 px floor.
static func hotkey_badge(text: String) -> Label:
	var label := Label.new()
	label.name = "HotkeyBadge"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	set_font(label, ui_font(600), SIZE_BADGE, COLOR_BADGE)
	label.add_theme_color_override("font_outline_color", COLOR_OUTLINE)
	label.add_theme_constant_override("outline_size", 2)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.02, 0.04, 0.05, 0.78)
	box.border_color = Color(0.73, 0.56, 0.4, 0.45)
	box.set_border_width_all(1)
	box.set_corner_radius_all(3)
	box.content_margin_left = 3.0
	box.content_margin_right = 3.0
	box.content_margin_top = 0.0
	box.content_margin_bottom = 0.0
	label.add_theme_stylebox_override("normal", box)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## Square icon-only button (speed controls, menu). Hotkey lives in the tooltip.
static func icon_button(key: String, tooltip: String, side: float = 30.0) -> Button:
	var button := Button.new()
	button.icon = icon(key)
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.custom_minimum_size = Vector2(side, side)
	button.tooltip_text = tooltip
	apply_button(button)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var box: StyleBoxTexture = button.get_theme_stylebox(state)
		box.content_margin_left = 6.0
		box.content_margin_right = 6.0
		box.content_margin_top = 6.0
		box.content_margin_bottom = 6.0
	return button


static func frame(kind: String = "panel", content: float = -1.0) -> StyleBoxTexture:
	var tex: Texture2D = TEX_PANEL
	var margin := 12.0
	var pad := 10.0
	match kind:
		"console":
			tex = TEX_CONSOLE
			margin = 18.0
			pad = 12.0
		"bar":
			tex = TEX_BAR
			margin = 12.0
			pad = 8.0
		"slot":
			tex = TEX_SLOT
			margin = 10.0
			pad = 6.0
		"toast":
			tex = TEX_TOAST
			margin = 12.0
			pad = 10.0
		"capsule":
			tex = TEX_CAPSULE
			margin = 8.0
			pad = 6.0
		"alert":
			tex = TEX_ALERT
			margin = 14.0
			pad = 10.0
	var style := StyleBoxTexture.new()
	style.texture = tex
	style.texture_margin_left = margin
	style.texture_margin_top = margin
	style.texture_margin_right = margin
	style.texture_margin_bottom = margin
	var p := pad if content < 0.0 else content
	style.content_margin_left = p
	style.content_margin_top = p
	style.content_margin_right = p
	style.content_margin_bottom = p
	return style


static func button_box(state: String = "normal") -> StyleBoxTexture:
	var tex: Texture2D = TEX_BTN_NORMAL
	match state:
		"hover":
			tex = TEX_BTN_HOVER
		"pressed":
			tex = TEX_BTN_PRESSED
		"disabled":
			tex = TEX_BTN_DISABLED
		"active":
			tex = TEX_BTN_TAB_ACTIVE
	var style := StyleBoxTexture.new()
	style.texture = tex
	style.texture_margin_left = 9.0
	style.texture_margin_top = 9.0
	style.texture_margin_right = 9.0
	style.texture_margin_bottom = 9.0
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	return style


static func icon(key: String) -> Texture2D:
	return ICONS.get(key, null)


static func thumbnail(building_type: String) -> Texture2D:
	return THUMBS.get(building_type, null)


static func thumbnail_rect(building_type: String, size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.name = "Thumb_%s" % building_type
	# Order matters: with the default EXPAND_KEEP_SIZE the texture's 160x120
	# becomes the minimum size and `size` would be clamped up to it.
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture = thumbnail(building_type)
	rect.custom_minimum_size = size
	rect.size = size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


static func icon_rect(key: String, size: float = 24.0) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = icon(key)
	rect.custom_minimum_size = Vector2(size, size)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


static func apply_button(button: Button, active_toggle := false) -> void:
	button.add_theme_stylebox_override("normal", button_box("normal"))
	button.add_theme_stylebox_override("hover", button_box("hover"))
	button.add_theme_stylebox_override("pressed", button_box("active" if active_toggle else "pressed"))
	button.add_theme_stylebox_override("hover_pressed", button_box("active" if active_toggle else "pressed"))
	button.add_theme_stylebox_override("disabled", button_box("disabled"))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", Color("#fff3d2"))
	button.add_theme_color_override("font_pressed_color", COLOR_GOLD)
	button.add_theme_color_override("font_hover_pressed_color", COLOR_GOLD)
	button.add_theme_color_override("font_disabled_color", Color("#8a8474"))
	button.add_theme_color_override("font_outline_color", COLOR_OUTLINE)
	button.add_theme_constant_override("outline_size", 3)


static func caption(text: String, size: int = SIZE_CAPTION) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", ui_font(600))
	label.add_theme_font_size_override("font_size", maxi(size, SIZE_MIN))
	label.add_theme_color_override("font_color", COLOR_GOLD_DIM)
	label.add_theme_color_override("font_outline_color", COLOR_OUTLINE)
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## Shared HUD theme: readable outlined text, stone buttons and framed tooltips.
static func hud_theme() -> Theme:
	if _theme != null:
		return _theme
	var theme := Theme.new()
	theme.default_font = ui_font(400)
	theme.default_font_size = 16
	theme.set_font("font", "Button", ui_font(600))
	theme.set_font("font", "OptionButton", ui_font(600))
	theme.set_font("bold_font", "RichTextLabel", ui_font(700))
	theme.set_font("normal_font", "RichTextLabel", ui_font(400))
	for state in ["normal", "hover", "pressed", "disabled"]:
		theme.set_stylebox(state, "Button", button_box(state))
		theme.set_stylebox(state, "OptionButton", button_box(state))
	theme.set_stylebox("hover_pressed", "Button", button_box("pressed"))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_stylebox("focus", "OptionButton", StyleBoxEmpty.new())
	theme.set_color("font_color", "Button", COLOR_TEXT)
	theme.set_color("font_hover_color", "Button", Color("#fff3d2"))
	theme.set_color("font_pressed_color", "Button", COLOR_GOLD)
	theme.set_color("font_disabled_color", "Button", Color("#8a8474"))
	theme.set_color("font_outline_color", "Button", COLOR_OUTLINE)
	theme.set_constant("outline_size", "Button", 3)
	theme.set_color("font_color", "OptionButton", COLOR_TEXT)
	theme.set_color("font_color", "Label", COLOR_TEXT)
	theme.set_color("font_outline_color", "Label", COLOR_OUTLINE)
	theme.set_constant("outline_size", "Label", 3)
	theme.set_color("default_color", "RichTextLabel", COLOR_TEXT)
	theme.set_color("font_outline_color", "RichTextLabel", COLOR_OUTLINE)
	theme.set_constant("outline_size", "RichTextLabel", 2)
	theme.set_stylebox("panel", "PanelContainer", frame("panel"))
	theme.set_stylebox("panel", "TooltipPanel", frame("panel", 9.0))
	theme.set_color("font_color", "TooltipLabel", COLOR_TEXT)
	theme.set_color("font_outline_color", "TooltipLabel", COLOR_OUTLINE)
	theme.set_constant("outline_size", "TooltipLabel", 2)
	theme.set_font_size("font_size", "TooltipLabel", 15)
	theme.set_stylebox("panel", "PopupMenu", frame("panel", 6.0))
	theme.set_color("font_color", "PopupMenu", COLOR_TEXT)
	theme.set_color("font_hover_color", "PopupMenu", COLOR_GOLD)
	_theme = theme
	return theme
