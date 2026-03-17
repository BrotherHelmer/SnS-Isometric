## Global Singleton — The Director's Ledger
## Manages the Day/Night cycle and the colony's resource economy.
## Autoloaded as "Global" in project.godot.
extends Node

# --- Day / Night Cycle ---------------------------------------------------

enum Phase { DAY, NIGHT }

signal phase_changed(new_phase: Phase)

## Duration of a full day period in seconds.
@export var day_duration: float = 120.0
## Duration of a full night period in seconds.
@export var night_duration: float = 60.0

var current_phase: Phase = Phase.DAY
var time_remaining: float = 0.0
var day_count: int = 1

# --- Resource Ledger ------------------------------------------------------

signal resource_changed(type: String, new_amount: int)

var resources: Dictionary = {
	"wood": 0,
	"stone": 0,
	"wyrd": 0,
}


func _ready() -> void:
	time_remaining = day_duration


func _process(delta: float) -> void:
	_tick_cycle(delta)


func _tick_cycle(delta: float) -> void:
	time_remaining -= delta
	if time_remaining <= 0.0:
		match current_phase:
			Phase.DAY:
				current_phase = Phase.NIGHT
				time_remaining = night_duration
			Phase.NIGHT:
				current_phase = Phase.DAY
				time_remaining = day_duration
				day_count += 1
		phase_changed.emit(current_phase)


## Add a positive amount of a resource to the ledger.
func add_resource(type: String, amount: int) -> void:
	if not resources.has(type):
		push_warning("Global: unknown resource type '%s'" % type)
		return
	resources[type] += amount
	resource_changed.emit(type, resources[type])


## Attempt to spend resources. Returns true on success, false if insufficient.
func spend_resource(type: String, amount: int) -> bool:
	if not resources.has(type):
		push_warning("Global: unknown resource type '%s'" % type)
		return false
	if resources[type] < amount:
		return false
	resources[type] -= amount
	resource_changed.emit(type, resources[type])
	return true


## Convenience getter for HUD / UI.
func get_resource(type: String) -> int:
	return resources.get(type, 0)
