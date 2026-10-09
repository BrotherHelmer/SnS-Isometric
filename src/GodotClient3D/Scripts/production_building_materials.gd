class_name ProductionBuildingMaterials
extends RefCounted

## GFX-07 roughness + GFX-B material remap.
## Walks imported meshes. Does not remodel. Castle lifts toward pale
## masonry and blue-grey slate; houses trade teal slate for terracotta.

const BevelShader = preload("res://src/GodotClient3D/Shaders/settlement_bevel.gdshader")

const ROUGHNESS := {
	"plaster": 0.80,
	"timber": 0.70,
	"roof": 0.72,
	"teal_roof": 0.68,
	"stone": 0.85,
	"metal": 0.34,
}

const CASTLE_MASONRY := Color("#D9C49B")
const CASTLE_SLATE := Color("#426F6A")
const HALL_MASONRY := Color("#E2D0A8")
const HALL_SLATE := Color("#426F6A")
const CLAY_ROOF := Color("#A75D39")
const KEEP_SLATE := Color("#4A5A4C")
const WARM_PLASTER := Color("#D9C49B")
const DARK_TIMBER := Color("#57402B")
const WEATHERED_STONE := Color("#888779")

static var _bevel_by_kind: Dictionary = {}


static func apply(root: Node, seed_id: int, building_type: String = "") -> void:
	if root == null:
		return
	var shift := _instance_shift(seed_id)
	_walk(root, shift, building_type)


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
				next = color.lerp(CASTLE_MASONRY, 0.72)
			elif kind == "stone":
				next = color.lerp(WEATHERED_STONE, 0.45).lerp(CASTLE_MASONRY, 0.28)
			elif kind == "teal_roof" or kind == "roof":
				next = color.lerp(CASTLE_SLATE, 0.82)
			elif kind == "timber":
				next = color.lerp(DARK_TIMBER, 0.55)
		"TOWN_HALL":
			if kind == "plaster":
				next = color.lerp(HALL_MASONRY, 0.68)
			elif kind == "stone":
				next = color.lerp(WEATHERED_STONE, 0.40).lerp(HALL_MASONRY, 0.25)
			elif kind == "teal_roof" or kind == "roof":
				next = color.lerp(HALL_SLATE, 0.78)
			elif kind == "timber":
				next = color.lerp(DARK_TIMBER, 0.60)
		"HOUSE", "FARM", "BAKERY", "STOREHOUSE":
			if kind == "teal_roof" or kind == "roof":
				next = color.lerp(CLAY_ROOF, 0.70)
			elif kind == "plaster":
				next = color.lerp(WARM_PLASTER, 0.55)
			elif kind == "timber":
				next = color.lerp(DARK_TIMBER, 0.50)
			elif kind == "stone":
				next = color.lerp(WEATHERED_STONE, 0.35)
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


static func _instance_shift(seed_id: int) -> Vector3:
	# ±5–8% value, slight hue lean. Deterministic per building id.
	var h := absi(seed_id) * 1103515245 + 12345
	var a := float((h >> 8) % 100) / 100.0
	var b := float((h >> 16) % 100) / 100.0
	var c := float((h >> 24) % 100) / 100.0
	return Vector3((a - 0.5) * 0.12, (b - 0.5) * 0.10, (c - 0.5) * 0.08)
