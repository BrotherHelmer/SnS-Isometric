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
	# TODO: Query The Director for the nearest available resource node.
	# For now, transition to Moving with a placeholder target.
	pass
