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
	if unit.has_method("take_damage"):
		unit.take_damage(fog_damage_rate * delta)

	if not _nav_agent or _nav_agent.is_navigation_finished():
		_reached_safety()
		return

	var next_pos := _nav_agent.get_next_path_position()
	var direction := (next_pos - unit.global_position).normalized()
	var base_speed: float = unit.move_speed
	unit.velocity = direction * base_speed * panic_speed_mult
	unit.move_and_slide()


func _reached_safety() -> void:
	unit.is_in_fog = false
	get_parent().transition_to("IdleState")


func _find_nearest_safe_position() -> Vector2:
	# Prefer the nearest lumen source (Sovereign, Lumen Pillars).
	var sources := get_tree().get_nodes_in_group("lumen_sources")
	var best_pos := Vector2.ZERO
	var best_dist := INF

	for source in sources:
		var d := unit.global_position.distance_to(source.global_position)
		if d < best_dist:
			best_dist = d
			best_pos = source.global_position

	# Fallback: run home.
	if best_dist == INF and unit.home_hut and is_instance_valid(unit.home_hut):
		best_pos = unit.home_hut.global_position

	return best_pos
