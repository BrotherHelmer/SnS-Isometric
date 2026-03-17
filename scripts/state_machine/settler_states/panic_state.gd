## Settler Panic State — triggered when the settler enters the Wyrd Fog.
## The settler flees toward the nearest safe zone and takes damage over time.
extends State

## Damage per second while panicking inside the fog.
@export var fog_damage_rate: float = 5.0
## Movement speed multiplier while fleeing.
@export var panic_speed_mult: float = 1.4

var _safe_target: Vector2 = Vector2.ZERO
var _nav_agent: NavigationAgent2D = null


func enter() -> void:
	_nav_agent = unit.get_node_or_null("NavigationAgent2D")
	_safe_target = _find_nearest_safe_position()
	if _nav_agent:
		_nav_agent.target_position = _safe_target


func physics_update(delta: float) -> void:
	# Apply fog damage every frame.
	if unit.has_method("take_damage"):
		unit.take_damage(fog_damage_rate * delta)

	if not _nav_agent or _nav_agent.is_navigation_finished():
		_reached_safety()
		return

	var next_pos := _nav_agent.get_next_path_position()
	var direction := (next_pos - unit.global_position).normalized()
	var base_speed: float = unit.get("move_speed")
	unit.velocity = direction * base_speed * panic_speed_mult
	unit.move_and_slide()


func _reached_safety() -> void:
	# Transition back to Idle once outside the fog.
	get_parent().transition_to("IdleState")


func _find_nearest_safe_position() -> Vector2:
	# TODO: Query lumen sources group for nearest cleared area.
	return Vector2.ZERO
