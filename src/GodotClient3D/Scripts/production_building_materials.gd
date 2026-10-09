class_name ProductionBuildingMaterials
extends RefCounted

## GFX-K landmark remap. Walks imported meshes. Does not remodel.
## Limestone #CBBCA0, plaster #E0CDA9, timber #62432F, slate #426C67,
## recessed stone #817968. Stone 0.88 / plaster 0.95 / timber 0.92 / roof 0.82.

const BevelShader = preload("res://src/GodotClient3D/Shaders/settlement_bevel.gdshader")

const ROUGHNESS := {
	"plaster": 0.95,
	"timber": 0.92,
	"roof": 0.82,
	"teal_roof": 0.82,
	"stone": 0.88,
	"metal": 0.34,
}

const CASTLE_LIMESTONE := Color("#CBBCA0")
const CASTLE_MASONRY := Color("#CBBCA0")
const CASTLE_SLATE := Color("#426C67")
const HALL_MASONRY := Color("#CBBCA0")
const HALL_SLATE := Color("#426C67")
const CLAY_ROOF := Color("#A95F3F")
const KEEP_SLATE := Color("#314B49")
const WARM_PLASTER := Color("#E0CDA9")
const DARK_TIMBER := Color("#62432F")
const WEATHERED_STONE := Color("#817968")
const HALL_LUMA_FLOOR := 0.42

static var _bevel_by_kind: Dictionary = {}


static func apply(root: Node, seed_id: int, building_type: String = "") -> void:
	if root == null:
		return
	var shift := _instance_shift(seed_id)
	_walk(root, shift, building_type)
	if building_type == "TOWN_HALL" or building_type == "CASTLE":
		_lift_landmark_walls(root)


static func classify(albedo: Color) -> String:
	var mx := maxf(albedo.r, maxf(albedo.g, albedo.b))
	var mn := minf(albedo.r, minf(albedo.g, albedo.b))
	var sat := 0.0 if mx <= 0.001 else (mx - mn) / mx
	if sat < 0.12 and mx > 0.55:
		return "metal" if mx > 0.72 else "plaster"
	if sat < 0.16:
		return "stone" if mx < 0.62 else "plaster"
	if albedo.b > albedo.r + 0.05 and albedo.g > albedo.r:
		return "teal_roof"
	if albedo.r > albedo.g + 0.05 and albedo.r > albedo.b + 0.08 and mx > 0.22:
		return "roof"
	if mx < 0.42 and albedo.r > albedo.b:
		return "timber"
	if albedo.r > 0.40 and albedo.g > 0.32 and albedo.b < albedo.r * 0.88:
		return "plaster"
	return "stone"


static func roughness_for(kind: String) -> float:
	return float(ROUGHNESS.get(kind, 0.80))


# The Director: GFX-B cheap material north-star. Hue only — silhouettes stay.
static func remap_albedo(kind: String, color: Color, building_type: String) -> Color:
	var next := color
	match building_type:
		"CASTLE":
			if kind == "plaster":
				next = color.lerp(CASTLE_LIMESTONE, 0.92)
			elif kind == "stone":
				next = color.lerp(WEATHERED_STONE, 0.28).lerp(CASTLE_LIMESTONE, 0.78)
			elif kind == "teal_roof" or kind == "roof":
				next = color.lerp(CASTLE_SLATE, 0.88)
			elif kind == "timber":
				next = color.lerp(DARK_TIMBER, 0.70)
			if kind == "plaster" or kind == "stone":
				next = _lift_hall_luma(next)
		"TOWN_HALL":
			if kind == "plaster":
				next = color.lerp(CASTLE_LIMESTONE, 0.94)
			elif kind == "stone":
				next = color.lerp(WEATHERED_STONE, 0.22).lerp(CASTLE_LIMESTONE, 0.82)
			elif kind == "teal_roof" or kind == "roof":
				next = color.lerp(HALL_SLATE, 0.90)
			elif kind == "timber":
				next = color.lerp(DARK_TIMBER, 0.78)
			if kind == "plaster" or kind == "stone":
				next = _lift_hall_luma(next)
		"HOUSE", "FARM", "BAKERY", "STOREHOUSE":
			if kind == "teal_roof" or kind == "roof":
				# House / bakery keep clay so t_gfx_d terracotta still holds.
				# Workshop timber/plaster still take the trim sheet.
				next = color.lerp(CLAY_ROOF, 0.70)
			elif kind == "plaster":
				next = color.lerp(WARM_PLASTER, 0.78)
			elif kind == "timber":
				next = color.lerp(DARK_TIMBER, 0.72)
			elif kind == "stone":
				next = color.lerp(WEATHERED_STONE, 0.62)
		"LUMBER_CAMP", "SAWMILL":
			if kind == "teal_roof" or kind == "roof":
				next = color.lerp(CLAY_ROOF, 0.45)
			elif kind == "plaster":
				next = color.lerp(WARM_PLASTER, 0.40)
			elif kind == "timber":
				next = color.lerp(DARK_TIMBER, 0.55)
			elif kind == "stone":
				next = color.lerp(WEATHERED_STONE, 0.30)
		"QUARRY":
			if kind == "stone" or kind == "plaster":
				next = color.lerp(WEATHERED_STONE, 0.50).lerp(CASTLE_MASONRY, 0.22)
			elif kind == "teal_roof" or kind == "roof":
				next = color.lerp(CLAY_ROOF, 0.40)
		"WATCHTOWER", "BARRACKS":
			if kind == "teal_roof" or kind == "roof":
				next = color.lerp(KEEP_SLATE, 0.55)
			elif kind == "plaster" or kind == "stone":
				next = color.lerp(CASTLE_MASONRY, 0.28)
	return next


static func _walk(node: Node, shift: Vector3, building_type: String) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		if instance.mesh != null:
			for surface in instance.mesh.get_surface_count():
				var original := instance.get_active_material(surface)
				if original == null:
					original = instance.mesh.surface_get_material(surface)
				if original is StandardMaterial3D:
					instance.set_surface_override_material(surface, _tune(original as StandardMaterial3D, shift, building_type))
		if instance.material_override is StandardMaterial3D:
			instance.material_override = _tune(instance.material_override as StandardMaterial3D, shift, building_type)
	for child in node.get_children():
		_walk(child, shift, building_type)


static func _tune(source: StandardMaterial3D, shift: Vector3, building_type: String) -> StandardMaterial3D:
	var material := source.duplicate() as StandardMaterial3D
	var kind := classify(material.albedo_color)
	material.roughness = roughness_for(kind)
	material.metallic = 0.42 if kind == "metal" else 0.0
	var color := remap_albedo(kind, material.albedo_color, building_type)
	material.albedo_color = Color(
		clampf(color.r * (1.0 + shift.x), 0.0, 1.0),
		clampf(color.g * (1.0 + shift.y), 0.0, 1.0),
		clampf(color.b * (1.0 + shift.z), 0.0, 1.0),
		color.a
	)
	material.next_pass = _bevel_material(kind)
	return material


static func _bevel_material(kind: String) -> ShaderMaterial:
	if _bevel_by_kind.has(kind):
		return _bevel_by_kind[kind]
	var material := ShaderMaterial.new()
	material.shader = BevelShader
	var color := Color("#D6C6A4")
	var amount := 0.18
	match kind:
		"roof":
			color = Color("#F0C090")
			amount = 0.16
		"teal_roof":
			color = Color("#C4A080")
			amount = 0.16
		"timber":
			color = Color("#C4A070")
			amount = 0.14
		"stone":
			color = Color("#D8D0C0")
			amount = 0.13
		"metal":
			color = Color("#F2E6C8")
			amount = 0.24
		_:
			color = Color("#F0E2C4")
			amount = 0.20
	material.set_shader_parameter("bevel_color", Vector3(color.r, color.g, color.b))
	material.set_shader_parameter("bevel_amount", amount)
	_bevel_by_kind[kind] = material
	return material


static func _lift_landmark_walls(node: Node) -> void:
	# KayKit halls paint walls the same dark teal as the roof. Remap
	# those dark faces to limestone so the landmark reads pale stone.
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		if instance.material_override is StandardMaterial3D:
			instance.material_override = _limestone_if_dark_teal(instance.material_override as StandardMaterial3D)
		if instance.mesh != null:
			for surface in instance.mesh.get_surface_count():
				var mat := instance.get_active_material(surface)
				if mat is StandardMaterial3D:
					instance.set_surface_override_material(surface, _limestone_if_dark_teal(mat as StandardMaterial3D))
	for child in node.get_children():
		_lift_landmark_walls(child)


static func _limestone_if_dark_teal(source: StandardMaterial3D) -> StandardMaterial3D:
	var color := source.albedo_color
	var luma := color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
	if not (color.b > color.r + 0.02 and color.g > color.r and luma < 0.30):
		return source
	var material := source.duplicate() as StandardMaterial3D
	material.albedo_color = CASTLE_LIMESTONE
	material.roughness = 0.88
	material.metallic = 0.0
	return material


static func _lift_hall_luma(color: Color) -> Color:
	# Town Hall must not read near-black at the default camera.
	var luma := color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
	if luma >= HALL_LUMA_FLOOR:
		return color
	var lift := (HALL_LUMA_FLOOR - luma) / maxf(HALL_LUMA_FLOOR, 0.001)
	return color.lerp(HALL_MASONRY, clampf(0.55 + lift, 0.55, 0.92))


static func _instance_shift(seed_id: int) -> Vector3:
	# ±5–8% value, slight hue lean. Deterministic per building id.
	var h := absi(seed_id) * 1103515245 + 12345
	var a := float((h >> 8) % 100) / 100.0
	var b := float((h >> 16) % 100) / 100.0
	var c := float((h >> 24) % 100) / 100.0
	return Vector3((a - 0.5) * 0.12, (b - 0.5) * 0.10, (c - 0.5) * 0.08)
