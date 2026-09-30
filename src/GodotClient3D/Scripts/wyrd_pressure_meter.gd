class_name WyrdPressureMeter
extends Control

const Identity = preload("res://src/GodotClient3D/Scripts/production_identity.gd")
const HudSkin = preload("res://src/GodotClient3D/Scripts/production_hud_skin.gd")

var band := "QUIET"
var value := 0.0
var pulse := 0.0
## Playtest.31: the meter reflects night/raid instead of reading QUIET mid-raid.
var is_night := false
var hostiles := 0
const COLOR_RAID := Color("#c8402f")
const COLOR_NIGHT := Color("#4a5d8f")
## T-SNS-UI leftovers: stone-and-gold badge frame shared with the rest of the HUD.
const FRAME_INSET := 4.0
const ICON_SIZE := 18.0

var _frame_normal: StyleBoxTexture
var _frame_raid: StyleBoxTexture


func _ready() -> void:
	custom_minimum_size = Vector2(196, 30)
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "Wyrd Pressure"
	_ensure_frames()


func _ensure_frames() -> void:
	if _frame_normal != null:
		return
	_frame_normal = HudSkin.frame("slot", 0.0)
	_frame_raid = HudSkin.frame("slot", 0.0)
	# Same stone frame, blood-red cast: RAID reads as an alarm at a glance.
	_frame_raid.modulate_color = Color(1.0, 0.46, 0.40)


func set_pressure(snapshot: Dictionary) -> void:
	band = String(snapshot.get("band", "QUIET"))
	value = clampf(float(snapshot.get("value", 0.0)), 0.0, 100.0)
	queue_redraw()


func set_threat(night: bool, hostile_count: int) -> void:
	if night == is_night and hostile_count == hostiles:
		return
	is_night = night
	hostiles = maxi(0, hostile_count)
	queue_redraw()


func is_raid() -> bool:
	return is_night and hostiles > 0


func display_text() -> String:
	if is_night and hostiles > 0:
		return "RAID · %d HOSTILE%s" % [hostiles, "" if hostiles == 1 else "S"]
	if is_night:
		return "NIGHT · %s" % band
	return "PRESSURE  %s" % band


func state_color() -> Color:
	if is_raid():
		return COLOR_RAID
	if is_night:
		return COLOR_NIGHT
	return Identity.PRESSURE_BAND_COLORS.get(band, Identity.COLOR_WYRD)


func _process(delta: float) -> void:
	if band == "CRITICAL" or is_raid():
		pulse = fmod(pulse + delta * 4.2, TAU)
		queue_redraw()
	elif band == "QUIET":
		pulse = 0.0


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var raid := is_raid()
	var color := state_color()
	_ensure_frames()
	# Pulsing red halo behind the frame while a raid is on.
	if raid:
		var glow := 0.35 + 0.25 * sin(pulse)
		draw_rect(rect.grow(2.0), Color(0.86, 0.16, 0.10, glow), false, 3.0)
	draw_style_box(_frame_raid if raid else _frame_normal, rect)
	var inner := rect.grow(-FRAME_INSET)
	# Body: deep state colour (RAID = solid dark red, never a pale text field).
	var body := color.darkened(0.55) if raid else color.darkened(0.7).lerp(Color(0.04, 0.06, 0.07), 0.35)
	draw_rect(inner, body, true)
	var fraction := value / 100.0
	if raid:
		fraction = 0.72 + 0.12 * sin(pulse)
	var jitter := 0.0 if band != "CRITICAL" else sin(pulse) * 0.35
	var fill := Rect2(inner.position + Vector2(0.0, 2.0 + jitter), Vector2(maxf(2.0, inner.size.x * fraction), inner.size.y - 4.0))
	draw_rect(fill, color if not raid else color.lightened(0.08), true)
	# Top sheen so the fill reads as a lit gem strip rather than a flat bar.
	draw_rect(Rect2(fill.position, Vector2(fill.size.x, 2.0)), Color(1, 1, 1, 0.16), true)
	for notch in 4:
		var x := inner.position.x + inner.size.x * float(notch + 1) / 5.0
		draw_line(Vector2(x, inner.position.y + 1.0), Vector2(x, inner.end.y - 1.0), Color(0.02, 0.04, 0.05, 0.5), 1.0)
	# Gold hairline inside the stone frame (red-gold while raiding).
	draw_rect(inner, Color("#ff8a6a") if raid else HudSkin.COLOR_GOLD_DIM, false, 1.0)
	var icon_key := "moon" if is_night else "wyrd"
	var icon_tex := HudSkin.icon(icon_key)
	var text_x := inner.position.x + 5.0
	if icon_tex != null:
		var icon_rect := Rect2(Vector2(inner.position.x + 3.0, (size.y - ICON_SIZE) * 0.5), Vector2(ICON_SIZE, ICON_SIZE))
		draw_texture_rect(icon_tex, icon_rect, false, Color(1.0, 0.72, 0.66) if raid else Color.WHITE)
		text_x = icon_rect.end.x + 4.0
	var label := display_text()
	var baseline := Vector2(text_x, size.y * 0.5 + 5.0)
	var font_size := 13
	var text_color := Color("#fff1e6") if raid else HudSkin.COLOR_GOLD
	# Look lift: drawn in the HUD's Source Sans 3 (semibold) like the rest of the bar.
	var font: Font = HudSkin.ui_font(700)
	draw_string_outline(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, Color(0.01, 0.02, 0.03, 1.0))
	draw_string(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
