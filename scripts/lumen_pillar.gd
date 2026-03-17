## LumenPillar — a buildable defense structure that clears the Wyrd Fog.
## Consumes 1 Wyrd per night cycle to remain active.
extends StaticBody2D

@export var wyrd_cost_per_night: int = 1

var is_active: bool = true


func _ready() -> void:
	add_to_group("lumen_sources")
	Global.phase_changed.connect(_on_phase_changed)


func _on_phase_changed(new_phase: int) -> void:
	if new_phase == Global.Phase.NIGHT:
		if not Global.spend_resource("wyrd", wyrd_cost_per_night):
			_deactivate()


func _deactivate() -> void:
	is_active = false
	remove_from_group("lumen_sources")
	# Dim the light visually.
	var light := get_node_or_null("LumenLight") as PointLight2D
	if light:
		var tween := create_tween()
		tween.tween_property(light, "energy", 0.0, 1.5)
