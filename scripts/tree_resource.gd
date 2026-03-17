## TreeResource — a harvestable tree that yields wood for settlers.
## Belongs to the "trees" group so IdleState can locate it.
extends StaticBody2D

signal depleted

@export var wood_amount: int = 10

var is_depleted: bool = false


func _ready() -> void:
	add_to_group("trees")


## Called by WorkingState each harvest tick.
## Returns the actual amount harvested (may be less than requested).
func harvest(amount: int) -> int:
	if is_depleted:
		return 0
	var actual := mini(amount, wood_amount)
	wood_amount -= actual
	if wood_amount <= 0:
		is_depleted = true
		depleted.emit()
		queue_free()
	return actual
