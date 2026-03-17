## Settler Idle State — waiting for The Director to assign a task.
extends State

## How long (seconds) to wait before requesting a new task.
@export var idle_timeout: float = 2.0
var _timer: float = 0.0


func enter() -> void:
	_timer = 0.0


func update(delta: float) -> void:
	_timer += delta
	if _timer >= idle_timeout:
		_timer = 0.0
		_try_find_task()


func _try_find_task() -> void:
	var trees := get_tree().get_nodes_in_group("trees")
	if trees.is_empty():
		return

	var nearest: Node2D = null
	var best_dist := INF
	for tree in trees:
		var d := unit.global_position.distance_to(tree.global_position)
		if d < best_dist:
			best_dist = d
			nearest = tree
	if nearest == null:
		return

	unit.target_resource = nearest

	var moving_state: State = get_parent().get_node_or_null("MovingState")
	if moving_state:
		moving_state.target_position = nearest.global_position
	get_parent().transition_to("MovingState")
