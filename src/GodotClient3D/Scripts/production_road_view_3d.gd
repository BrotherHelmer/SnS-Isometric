class_name ProductionRoadView3D
extends Node3D

const ScaleProfile = preload("res://src/GodotClient3D/Scripts/production_scale_profile.gd")

static var _materials: Dictionary = {}
static var _light_tint := Color.WHITE
static var _value_lift := 0.06

var tile := Vector2i.ZERO
var building_id := 0
var planned := false
var connection_mask := 0
var faction := "player"


func configure(id: int, tile_value: Vector2i, mask: int, is_planned: bool, faction_value := "player") -> void:
	building_id = id
	tile = tile_value
	connection_mask = mask
	planned = is_planned
	faction = faction_value
	name = "Road_%d_%d" % [tile.x, tile.y]
	_rebuild()


func signature() -> String:
	return "%d:%d:%d:%s" % [building_id, connection_mask, int(planned), faction]


func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var edge_color := Color(0.32, 0.28, 0.22, 0.42) if planned else Color(0.30, 0.28, 0.24, 0.50)
	var road_color := Color(0.62, 0.58, 0.50, 0.78) if planned else Color("#b8b2a6")
	if faction == "rival":
		edge_color = Color(0.28, 0.17, 0.18, 0.72)
		road_color = Color("#805d58")
	elif faction == "preview_valid":
		edge_color = Color(0.18, 0.50, 0.31, 0.34)
		road_color = Color(0.32, 0.82, 0.48, 0.54)
	elif faction == "preview_invalid":
		edge_color = Color(0.58, 0.16, 0.13, 0.38)
		road_color = Color(0.92, 0.26, 0.20, 0.58)
	var width_variation := 0.96 + float(absi(tile.x * 17 + tile.y * 31) % 7) * 0.012
	var road_width := 1.34 * ScaleProfile.ROAD_WIDTH_SCALE * width_variation
	_add_path_mesh(road_width * 1.32, 0.040, _road_material(edge_color), "FeatheredEdge")
	_add_path_mesh(road_width, 0.058, _road_material(road_color), "ContinuousDirt")
	if not planned and faction in ["player", "rival"]:
		_add_ruts(road_width)


func _add_path_mesh(width: float, height: float, material: Material, node_name: String) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half_cell := ScaleProfile.LOGICAL_CELL_METRES * 0.53
	var junction := width * 0.52
	# Shared a,d,c,b vertex order. Lighting uses a world-up normal in the
	# shader, so winding no longer decides which way the lane faces.
	var ja := Vector3(-junction, height, -junction)
	var jb := Vector3(junction, height, -junction)
	var jc := Vector3(junction, height, junction)
	var jd := Vector3(-junction, height, junction)
	var flat := Vector2(0.5, 0.5)
	_add_quad(surface, ja, jd, jc, jb, flat, flat, flat, flat)
	var directions := [Vector2(0.0, -1.0), Vector2(1.0, 0.0), Vector2(0.0, 1.0), Vector2(-1.0, 0.0)]
	for index in directions.size():
		if connection_mask & (1 << index) == 0:
			continue
		var direction: Vector2 = directions[index]
		var perpendicular := Vector2(-direction.y, direction.x)
		var half_width := width * 0.5
		var start := direction * junction * 0.38
		var finish := direction * half_cell
		var a := Vector3(start.x - perpendicular.x * half_width, height, start.y - perpendicular.y * half_width)
		var b := Vector3(start.x + perpendicular.x * half_width, height, start.y + perpendicular.y * half_width)
		var c := Vector3(finish.x + perpendicular.x * half_width, height, finish.y + perpendicular.y * half_width)
		var d := Vector3(finish.x - perpendicular.x * half_width, height, finish.y - perpendicular.y * half_width)
		_add_quad(surface, a, d, c, b, Vector2(0.0, 0.0), Vector2(0.0, 1.0), Vector2(1.0, 1.0), Vector2(1.0, 0.0))
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = surface.commit()
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.material_override = material
	add_child(instance)


func _add_ruts(road_width: float) -> void:
	var material := _road_material(Color(0.13, 0.09, 0.055, 0.07) if faction == "player" else Color(0.14, 0.07, 0.08, 0.08))
	var directions := [Vector2(0.0, -1.0), Vector2(1.0, 0.0), Vector2(0.0, 1.0), Vector2(-1.0, 0.0)]
	for index in directions.size():
		if connection_mask & (1 << index) == 0:
			continue
		var direction: Vector2 = directions[index]
		var perpendicular := Vector2(-direction.y, direction.x)
		for side in [-1.0, 1.0]:
			var rut := MeshInstance3D.new()
			rut.name = "WheelRut"
			var mesh := BoxMesh.new()
			mesh.size = Vector3(0.075, 0.012, ScaleProfile.LOGICAL_CELL_METRES * 0.58)
			rut.mesh = mesh
			var center: Vector2 = direction * ScaleProfile.LOGICAL_CELL_METRES * 0.27 + perpendicular * road_width * 0.24 * side
			rut.position = Vector3(center.x, 0.070, center.y)
			if direction.x != 0.0:
				rut.rotation.y = PI * 0.5
			rut.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			rut.material_override = material
			add_child(rut)


func _add_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ua: Vector2, ub: Vector2, uc: Vector2) -> void:
	var verts := [a, b, c]
	var uvs := [ua, ub, uc]
	for index in 3:
		surface.set_normal(Vector3.UP)
		surface.set_uv(uvs[index])
		surface.add_vertex(verts[index])


func _add_quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, ua := Vector2(0, 0), ub := Vector2(1, 0), uc := Vector2(1, 1), ud := Vector2(0, 1)) -> void:
	_add_triangle(surface, a, b, c, ua, ub, uc)
	_add_triangle(surface, a, c, d, ua, uc, ud)


func _road_material(color: Color) -> ShaderMaterial:
	var key := color.to_html()
	if not _materials.has(key):
		var material := ShaderMaterial.new()
		material.shader = preload("res://src/GodotClient3D/Shaders/settlement_road.gdshader")
		material.set_shader_parameter("road_color", color)
		material.set_shader_parameter("light_tint", _light_tint)
		material.set_shader_parameter("value_lift", _value_lift)
		material.render_priority = -1 if color.a < 1.0 else 0
		_materials[key] = material
	return _materials[key]


static func set_lighting(tint: Color, value_lift := 0.06) -> void:
	if _light_tint.is_equal_approx(tint) and is_equal_approx(_value_lift, value_lift):
		return
	_light_tint = tint
	_value_lift = value_lift
	for material in _materials.values():
		material.set_shader_parameter("light_tint", tint)
		material.set_shader_parameter("value_lift", value_lift)