## Settler Working State — harvesting a resource node (Wood / Stone).
extends State

## Seconds between each harvest tick.
@export var work_interval: float = 1.5
## Amount gathered per tick.
@export var gather_amount: int = 1

var _timer: float = 0.0


func enter() -> void:
	_timer = 0.0


func update(delta: float) -> void:
	_timer += delta
	if _timer >= work_interval:
		_timer = 0.0
		_harvest_tick()


func _harvest_tick() -> void:
	# TODO: Deduct from the resource node, add to settler's carrying amount.
	# When carrying capacity is full, the settler script transitions to Returning.
	pass
