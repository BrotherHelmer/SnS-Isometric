## WoodcutterHut — spawns a Settler and acts as their home stockpile.
## Settlers deposit gathered wood here, which flows into Global resources.
extends StaticBody2D

const SETTLER_SCENE := preload("res://scenes/settler.tscn")


func _ready() -> void:
	add_to_group("stockpiles")
	call_deferred("_spawn_settler")


func _spawn_settler() -> void:
	var settler := SETTLER_SCENE.instantiate()
	settler.home_hut = self
	get_tree().current_scene.get_node("Entities").add_child(settler)
	settler.global_position = global_position + Vector2(0, 16)
