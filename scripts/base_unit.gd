## BaseUnit — abstract ancestor for any living entity on the grid.
## Provides health, movement speed, and fog-awareness.
class_name BaseUnit
extends CharacterBody2D

signal died

@export var max_health: float = 100.0
@export var move_speed: float = 80.0

var health: float = max_health
var is_in_fog: bool = false


func _ready() -> void:
	health = max_health


func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		health = 0.0
		_die()


func heal(amount: float) -> void:
	health = min(health + amount, max_health)


func _die() -> void:
	died.emit()
	queue_free()
