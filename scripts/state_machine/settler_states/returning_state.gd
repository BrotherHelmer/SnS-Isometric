## Settler Returning State — carrying gathered resources back to the home hut.
extends State

var stockpile_position: Vector2 = Vector2.ZERO
var _nav_agent: NavigationAgent2D = null

const ARRIVE_THRESHOLD := 8.0


func enter() -> void:
	_nav_agent = unit.get_node_or_null("NavigationAgent2D")
	if unit.home_hut and is_instance_valid(unit.home_hut):
		stockpile_position = unit.home_hut.global_position
	if _nav_agent:
		_nav_agent.target_position = stockpile_position


func physics_update(delta: float) -> void:
	if not _nav_agent or _nav_agent.is_navigation_finished():
		_deposit_resources()
		return

	var next_pos := _nav_agent.get_next_path_position()
	var direction := (next_pos - unit.global_position).normalized()
	unit.velocity = direction * unit.move_speed
	unit.move_and_slide()


func _deposit_resources() -> void:
	unit.deposit_inventory()
