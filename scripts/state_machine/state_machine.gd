## Generic Finite State Machine.
## Add State-derived child nodes; the first child is the initial state.
class_name StateMachine
extends Node

## Emitted whenever the machine switches states.
signal state_changed(new_state_name: String)

var current_state: State = null
var _states: Dictionary = {}


func _ready() -> void:
	# The StateMachine must be a child of the unit (CharacterBody2D).
	var owner_unit := get_parent() as CharacterBody2D
	for child in get_children():
		if child is State:
			_states[child.name] = child
			child.unit = owner_unit
	# First child State becomes the initial state.
	if get_child_count() > 0 and get_child(0) is State:
		current_state = get_child(0) as State
		current_state.enter()


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


## Transition to a new state by node name.
func transition_to(state_name: String) -> void:
	if not _states.has(state_name):
		push_warning("StateMachine: no state named '%s'" % state_name)
		return
	if current_state:
		current_state.exit()
	current_state = _states[state_name]
	current_state.enter()
	state_changed.emit(state_name)
