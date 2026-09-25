class_name WyrdPressureMeter
extends Control

const Identity = preload("res://src/GodotClient3D/Scripts/production_identity.gd")

var band := "QUIET"
var value := 0.0
var pulse := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(176, 28)
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "Wyrd Pressure"


func set_pressure(snapshot: Dictionary) -> void:
	band = String(snapshot.get("band", "QUIET"))
	value = clampf(float(snapshot.get("value", 0.0)), 0.0, 100.0)
	queue_redraw()


func _process(delta: float) -> void:
	if band == "CRITICAL":
		pulse = fmod(pulse + delta * 4.2, TAU)
		queue_redraw()
	elif band == "QUIET":
		pulse = 0.0


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var color: Color = Identity.PRESSURE_BAND_COLORS.get(band, Identity.COLOR_WYRD)
	draw_rect(rect, Color(0.04, 0.06, 0.07, 0.92), true)
	var fill_width := rect.size.x * (value / 100.0)
	var jitter := 0.0 if band != "CRITICAL" else sin(pulse) * 2.4
	var fill := Rect2(1.0, 4.0 + jitter * 0.15, maxf(2.0, fill_width - 2.0), rect.size.y - 8.0)
	draw_rect(fill, color, true)
	for notch in 4:
		var x := rect.size.x * float(notch + 1) / 5.0
		draw_line(Vector2(x, 3.0), Vector2(x, rect.size.y - 3.0), Color(0.02, 0.04, 0.05, 0.55), 1.0)
	draw_rect(rect, color.darkened(0.35), false, 1.0)
	var label := "PRESSURE  %s" % band
	# Text remains readable both over an empty meter and a bright filled band.
	draw_string_outline(ThemeDB.fallback_font, Vector2(8.0, rect.size.y * 0.72), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color(0.02, 0.03, 0.04, 1.0))
	draw_string(ThemeDB.fallback_font, Vector2(8.0, rect.size.y * 0.72), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Identity.COLOR_NEUTRAL)
