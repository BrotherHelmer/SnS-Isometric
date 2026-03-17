## World — root scene controller.
## Generates the Crater-rim world layout inspired by the concept art:
##   - Center (radius 0-3): barren crater, WyrdNode lives here.
##   - Inner ring (3-6): rocky transitional terrain, sparse vegetation.
##   - Outer rim (6-12): dense forest, the colony settlement, harvestable trees.
## The Sovereign spawns at the colony edge; settlers stay in cleared zones.
extends Node2D

const TREE_SCENE := preload("res://scenes/tree_resource.tscn")
const ROCK_SCENE := preload("res://scenes/rock_deco.tscn")
const HUT_SCENE  := preload("res://scenes/woodcutter_hut.tscn")

const TILE_W := 64
const TILE_H := 32

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var entities: Node2D = $Entities


func _ready() -> void:
	_paint_ground()
	_spawn_environment()


func _paint_ground() -> void:
	var grass_source := 0
	var grass_coord := Vector2i(0, 0)
	for x in range(-14, 14):
		for y in range(-14, 14):
			var dist := Vector2(x, y).length()
			if dist < 14:
				ground_layer.set_cell(Vector2i(x, y), grass_source, grass_coord)


func _spawn_environment() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	# Inner ring rocks (radius 3-6 tiles) — barren rim of the crater
	for i in range(12):
		var angle := rng.randf() * TAU
		var dist := rng.randf_range(3.0, 6.0)
		var tile_x := dist * cos(angle)
		var tile_y := dist * sin(angle)
		var world_pos := _tile_to_world(tile_x, tile_y)
		var rock := ROCK_SCENE.instantiate()
		rock.position = world_pos
		entities.add_child(rock)

	# Outer rim trees (radius 6-12) — harvestable forest
	for i in range(14):
		var angle := rng.randf() * TAU
		var dist := rng.randf_range(6.5, 11.0)
		var tile_x := dist * cos(angle)
		var tile_y := dist * sin(angle)
		var world_pos := _tile_to_world(tile_x, tile_y)
		var tree := TREE_SCENE.instantiate()
		tree.position = world_pos
		entities.add_child(tree)

	# More rocks scattered in outer area for visual depth
	for i in range(8):
		var angle := rng.randf() * TAU
		var dist := rng.randf_range(7.0, 12.0)
		var tile_x := dist * cos(angle)
		var tile_y := dist * sin(angle)
		var world_pos := _tile_to_world(tile_x, tile_y)
		var rock := ROCK_SCENE.instantiate()
		rock.position = world_pos
		entities.add_child(rock)

	# Colony: Woodcutter Hut on the southern rim
	var hut_pos := _tile_to_world(7.0, 5.0)
	var hut := HUT_SCENE.instantiate()
	hut.position = hut_pos
	entities.add_child(hut)


## Convert fractional tile coordinates to isometric world position.
func _tile_to_world(tx: float, ty: float) -> Vector2:
	return Vector2(
		(tx - ty) * TILE_W * 0.5,
		(tx + ty) * TILE_H * 0.5
	)
