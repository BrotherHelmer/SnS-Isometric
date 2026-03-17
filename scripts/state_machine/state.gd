## Abstract base class for a single FSM state.
## Extend this and override the virtual methods.
class_name State
extends Node

## Set by the StateMachine on _ready(). Points to the CharacterBody2D owner.
var unit: CharacterBody2D


## Called when this state becomes the active state.
func enter() -> void:
	pass


## Called when this state is being replaced by another.
func exit() -> void:
	pass


## Called every frame while this state is active (mirrors _process).
func update(delta: float) -> void:
	pass


## Called every physics frame while this state is active (mirrors _physics_process).
func physics_update(delta: float) -> void:
	pass
