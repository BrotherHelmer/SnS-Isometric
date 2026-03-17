## FogManager — drives the Wyrd Fog mask via a SubViewport.
## Each lumen source (Sovereign, Lumen Pillars) stamps a radial gradient
## onto the SubViewport to carve holes in the fog.
##
## The SubViewport background is white (full fog). Stamps use SUB blend
## to carve black circles. The shader reads white = fog, black = clear.
extends Node2D

@export var lumen_stamp_texture: Texture2D
@export var stamp_scale: float = 4.0

@onready var sub_viewport: SubViewport = $SubViewport
@onready var fog_rect: ColorRect = $FogOverlay/FogRect

var _stamps: Dictionary = {}


func _ready() -> void:
	var mat := fog_rect.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("fog_mask", sub_viewport.get_texture())


func _process(_delta: float) -> void:
	_sync_stamps()


func _sync_stamps() -> void:
	var sources := get_tree().get_nodes_in_group("lumen_sources")
	var active_ids: Array = []

	# The main viewport's canvas transform maps world coords -> screen pixels.
	var canvas_xform := get_viewport().get_canvas_transform()

	for source in sources:
		var id := source.get_instance_id()
		active_ids.append(id)

		if not _stamps.has(id):
			_create_stamp(id)

		# Use the staff crystal position if available, otherwise body center.
		var world_pos: Vector2
		if source.has_method("get_lumen_position"):
			world_pos = source.get_lumen_position()
		else:
			world_pos = source.global_position

		var stamp: Sprite2D = _stamps[id]
		stamp.position = canvas_xform * world_pos

	for id in _stamps.keys():
		if id not in active_ids:
			_stamps[id].queue_free()
			_stamps.erase(id)


func _create_stamp(id: int) -> Sprite2D:
	var stamp := Sprite2D.new()
	stamp.texture = lumen_stamp_texture
	stamp.scale = Vector2.ONE * stamp_scale

	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_SUB
	stamp.material = mat

	sub_viewport.add_child(stamp)
	_stamps[id] = stamp
	return stamp
