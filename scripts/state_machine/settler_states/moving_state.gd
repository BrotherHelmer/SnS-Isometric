## Settler Moving State — navigating toward a target position on the grid.
extends State

var target_position: Vector2 = Vector2.ZERO
var _nav_agent: NavigationAgent2D = null

const ARRIVE_THRESHOLD := 8.0


func enter() -> void:
	_nav_agent = unit.get_node_or_null("NavigationAgent2D")
	if _nav_agent:
		_nav_agent.target_position = target_position


func physics_update(delta: float) -> void:
	if not _nav_agent or _nav_agent.is_navigation_finished():
		_on_arrived()
		return

	var next_pos := _nav_agent.get_next_path_position()
	var direction := (next_pos - unit.global_position).normalized()
	unit.velocity = direction * unit.move_speed
	unit.move_and_slide()


func _on_arrived() -> void:
	if unit.target_resource != null and is_instance_valid(unit.target_resource):
		get_parent().transition_to("WorkingState")
	else:
		unit.target_resource = null
		get_parent().transition_to("IdleState")
