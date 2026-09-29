class_name WyrdPressureMeter
extends Control

const Identity = preload("res://src/GodotClient3D/Scripts/production_identity.gd")

var band := "QUIET"
var value := 0.0
var pulse := 0.0
## Playtest.31: the meter reflects night/raid instead of reading QUIET mid-raid.
var is_night := false
var hostiles := 0
const COLOR_RAID := Color("#c8402f")
const COLOR_NIGHT := Color("#4a5d8f")


func _ready() -> void:
	custom_minimum_size = Vector2(176, 28)
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "Wyrd Pressure"


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


func display_text() -> String:
	if is_night and hostiles > 0:
		return "RAID · %d HOSTILE%s" % [hostiles, "" if hostiles == 1 else "S"]
	if is_night:
		return "NIGHT · %s" % band
	return "PRESSURE  %s" % band


func _process(delta: float) -> void:
	if band == "CRITICAL" or (is_night and hostiles > 0):
		pulse = fmod(pulse + delta * 4.2, TAU)
		queue_redraw()
	elif band == "QUIET":
		pulse = 0.0


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var color: Color = Identity.PRESSURE_BAND_COLORS.get(band, Identity.COLOR_WYRD)
	var raid := is_night and hostiles > 0
	if raid:
		color = COLOR_RAID
	elif is_night:
		color = COLOR_NIGHT
	# Badge look: tinted body in the state colour (no longer reads as an empty text field).
	draw_rect(rect, color.darkened(0.62).lerp(Color(0.04, 0.06, 0.07), 0.25), true)
	var fill_width := rect.size.x * (value / 100.0)
	if raid:
		fill_width = rect.size.x * (0.72 + 0.12 * sin(pulse))
	var jitter := 0.0 if band != "CRITICAL" else sin(pulse) * 2.4
	var fill := Rect2(1.0, 4.0 + jitter * 0.15, maxf(2.0, fill_width - 2.0), rect.size.y - 8.0)
	draw_rect(fill, color, true)
	for notch in 4:
		var x := rect.size.x * float(notch + 1) / 5.0
		draw_line(Vector2(x, 3.0), Vector2(x, rect.size.y - 3.0), Color(0.02, 0.04, 0.05, 0.55), 1.0)
	draw_rect(rect, color.lightened(0.1), false, 2.0)
	var label := display_text()
	# Stronger outline and brighter text ensures readability at 720p/1080p independent of meter fill.
	draw_string_outline(ThemeDB.fallback_font, Vector2(8.0, rect.size.y * 0.72), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 5, Color(0.01, 0.02, 0.03, 1.0))
	draw_string(ThemeDB.fallback_font, Vector2(8.0, rect.size.y * 0.72), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#f5e8d0"))
