## Settler — an autonomous NPC that gathers resources for the colony.
## Does NOT take direct orders from the player.
## Behaviour is driven entirely by its child StateMachine.
extends BaseUnit

@export var carry_capacity: int = 5

var carried_resource_type: String = ""
var carried_amount: int = 0

@onready var state_machine: StateMachine = $StateMachine


func _ready() -> void:
	super._ready()
	add_to_group("settlers")


## Called by WorkingState when the settler harvests one tick.
func add_to_inventory(type: String, amount: int) -> void:
	carried_resource_type = type
	carried_amount += amount
	if carried_amount >= carry_capacity:
		state_machine.transition_to("ReturningState")


## Called by ReturningState when the settler reaches the stockpile.
func deposit_inventory() -> void:
	if carried_amount > 0:
		Global.add_resource(carried_resource_type, carried_amount)
		carried_amount = 0
		carried_resource_type = ""
	state_machine.transition_to("IdleState")
