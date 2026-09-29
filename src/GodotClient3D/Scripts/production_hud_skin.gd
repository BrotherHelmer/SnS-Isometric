extends RefCounted

## T-SNS-UI: themed stone-and-gold HUD skin (self-made art, tools/generate_ui_art.py).
## Frames are 9-slice StyleBoxTextures so panels scale to any size without blur.

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
}

const COLOR_TEXT := Color("#ece4cc")
const COLOR_GOLD := Color("#f0c880")
const COLOR_GOLD_DIM := Color("#c49654")
const COLOR_CAPTION := Color("#b9ab86")
const COLOR_GAIN := Color("#8fe08a")
const COLOR_LOSS := Color("#ff8a78")
const COLOR_OUTLINE := Color(0.0, 0.0, 0.0, 0.85)

static var _theme: Theme


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


static func caption(text: String, size: int = 11) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
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
	theme.default_font_size = 15
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
	theme.set_font_size("font_size", "TooltipLabel", 14)
	theme.set_stylebox("panel", "PopupMenu", frame("panel", 6.0))
	theme.set_color("font_color", "PopupMenu", COLOR_TEXT)
	theme.set_color("font_hover_color", "PopupMenu", COLOR_GOLD)
	_theme = theme
	return theme
