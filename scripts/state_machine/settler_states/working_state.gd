## Settler Working State — harvesting a resource node (Wood / Stone).
## Plays a chopping bob animation for visual feedback.
extends State

## Seconds between each harvest tick.
@export var work_interval: float = 1.0
## Amount gathered per tick.
@export var gather_amount: int = 1

var _timer: float = 0.0
var _bob_timer: float = 0.0

const _BOB_SPEED := 12.0
const _BOB_AMPLITUDE := 1.5
const _BASE_SPRITE_OFFSET := Vector2(0, -16)


func enter() -> void:
	_timer = 0.0
	_bob_timer = 0.0


func update(delta: float) -> void:
	_bob_timer += delta * _BOB_SPEED
	var sprite: Node2D = unit.get_node_or_null("Sprite2D")
	if sprite:
		sprite.offset = _BASE_SPRITE_OFFSET + Vector2(0, absf(sin(_bob_timer)) * _BOB_AMPLITUDE)

	_timer += delta
	if _timer >= work_interval:
		_timer = 0.0
		_harvest_tick()


func exit() -> void:
	var sprite: Node2D = unit.get_node_or_null("Sprite2D")
	if sprite:
		sprite.offset = _BASE_SPRITE_OFFSET


func _harvest_tick() -> void:
	var target = unit.target_resource
	if target == null or not is_instance_valid(target):
		unit.target_resource = null
		get_parent().transition_to("IdleState")
		return

	var actual: int = target.harvest(gather_amount)
	if actual > 0:
		unit.add_to_inventory("wood", actual)

	if target == null or not is_instance_valid(target) or target.is_depleted:
		unit.target_resource = null
		if unit.carried_amount > 0:
			get_parent().transition_to("ReturningState")
		else:
			get_parent().transition_to("IdleState")
