## FogManager — drives the Wyrd Fog mask via a SubViewport.
## Each lumen source (Sovereign, Lumen Pillars) stamps a radial gradient
## onto the SubViewport to carve holes in the fog.
extends Node2D

@export var lumen_stamp_texture: Texture2D
@export var stamp_scale: float = 4.0

@onready var sub_viewport: SubViewport = $SubViewport
@onready var fog_rect: ColorRect = $FogRect

var _stamps: Dictionary = {}


func _ready() -> void:
	# Wire the SubViewport's texture into the fog shader.
	var mat := fog_rect.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("fog_mask", sub_viewport.get_texture())


func _process(_delta: float) -> void:
	_sync_stamps()


func _sync_stamps() -> void:
	var sources := get_tree().get_nodes_in_group("lumen_sources")
	var active_ids: Array = []

	for source in sources:
		var id := source.get_instance_id()
		active_ids.append(id)

		if not _stamps.has(id):
			_create_stamp(id)

		# Position stamp in SubViewport space.
		var stamp: Sprite2D = _stamps[id]
		stamp.global_position = source.global_position

	# Remove stamps for sources that no longer exist.
	for id in _stamps.keys():
		if id not in active_ids:
			_stamps[id].queue_free()
			_stamps.erase(id)


func _create_stamp(id: int) -> Sprite2D:
	var stamp := Sprite2D.new()
	stamp.texture = lumen_stamp_texture
	stamp.scale = Vector2.ONE * stamp_scale

	# Subtractive blend: carves darkness out of the white fog mask.
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_SUB
	stamp.material = mat

	sub_viewport.add_child(stamp)
	_stamps[id] = stamp
	return stamp
