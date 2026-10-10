class_name ProductionBuildingMaterials
extends RefCounted

## GFX-Q civic architecture. Town Hall / Castle use named-mesh glTF
## plus 1K CC0 maps under the P palettes. Houses / mill stay KayKit.
## Light stone #CDBFA2 / #E0D0B2 / #82796A, timber #5F442F, slate #456B68.

const BevelShader = preload("res://src/GodotClient3D/Shaders/settlement_bevel.gdshader")
const KaykitRemap = preload("res://src/GodotClient3D/Shaders/settlement_kaykit_remap.gdshader")
const ArchShader = preload("res://src/GodotClient3D/Shaders/settlement_architecture.gdshader")
const Catalog = preload("res://src/GodotClient3D/Scripts/production_asset_catalog.gd")

const ROUGHNESS := {
	"plaster": 0.95,
	"timber": 0.90,
	"roof": 0.88,
	"teal_roof": 0.83,
	"stone": 0.88,
	"metal": 0.34,
}

const CASTLE_LIMESTONE := Color("#CDBFA2")
const CASTLE_MASONRY := Color("#82796A")
const CASTLE_SLATE := Color("#456B68")
const HALL_MASONRY := Color("#CDBFA2")
const HALL_SLATE := Color("#456B68")
const CLAY_ROOF := Color("#A96343")
const KEEP_SLATE := Color("#304C49")
const WARM_PLASTER := Color("#E0D0B2")
const DARK_TIMBER := Color("#5F442F")
const WEATHERED_STONE := Color("#635B4C")
const FOUNDATION_FACE := Color("#A99D82")
const FOUNDATION_TOP := Color("#C1B394")
const FOUNDATION_EDGE := Color("#756C5B")
const HALL_LUMA_FLOOR := 0.42

static var _bevel_by_kind: Dictionary = {}


static func apply(root: Node, seed_id: int, building_type: String = "") -> void:
	if root == null:
		return
	if _is_civic_keep(building_type):
		_apply_civic_architecture(root, building_type)
		return
	if _is_kaykit_hexagon(building_type):
		_apply_kaykit_remap(root, building_type)
		return
	var shift := _instance_shift(seed_id)
	_walk(root, shift, building_type)
	if building_type == "TOWN_HALL" or building_type == "CASTLE":
		_lift_landmark_walls(root)


static func _is_civic_keep(building_type: String) -> bool:
	return building_type == "TOWN_HALL" or building_type == "CASTLE"


static func _is_kaykit_hexagon(building_type: String) -> bool:
	return building_type == "HOUSE" or building_type == "LUMBER_CAMP" or building_type == "SAWMILL"


static func _apply_civic_architecture(root: Node, building_type: String) -> void:
	# Bind by mesh name. Roof is geometry, not an atlas classify.
	var stone_tex: Texture2D = load(String(Catalog.ARCH_TEXTURES["stone"])) as Texture2D
	var plaster_tex: Texture2D = load(String(Catalog.ARCH_TEXTURES["plaster"])) as Texture2D
	var timber_tex: Texture2D = load(String(Catalog.ARCH_TEXTURES["timber"])) as Texture2D
	var slate_tex: Texture2D = load(String(Catalog.ARCH_TEXTURES["slate"])) as Texture2D
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var instance := node as MeshInstance3D
		if instance == null:
			continue
		var mesh_name := String(instance.name)
		var kind := "stone"
		var tint := Color("#CDBFA2")
		var tex: Texture2D = stone_tex
		var uv_scale := 2.8
		var emission := 0.08
		var mix_amt := 0.30
		var boost := 1.16
		var lift := 1.16
		if mesh_name.contains("Roof") or mesh_name.contains("Cone"):
			kind = "slate"
			tint = HALL_SLATE
			tex = slate_tex
			uv_scale = 3.2
			emission = 0.03
			mix_amt = 0.34
			boost = 1.08
			lift = 1.04
		elif mesh_name.contains("Plaster"):
			kind = "plaster"
			tint = WARM_PLASTER.lerp(CASTLE_LIMESTONE, 0.28)
			tex = plaster_tex
			uv_scale = 2.2
			emission = 0.04
			mix_amt = 0.34
			boost = 1.06
			lift = 1.08
		elif mesh_name.contains("Banner") or mesh_name.contains("Herald"):
			kind = "timber"
			tint = Color("#8B2E3A")
			tex = timber_tex
			uv_scale = 1.4
			emission = 0.12
			mix_amt = 0.18
			boost = 1.08
			lift = 1.04
		elif mesh_name.contains("Recess") or mesh_name.contains("Facade"):
			kind = "timber"
			tint = Color("#3A3228")
			tex = timber_tex
			uv_scale = 1.8
			emission = 0.0
			mix_amt = 0.22
			boost = 0.92
			lift = 0.88
		elif mesh_name.contains("Timber") or mesh_name.contains("Door") or mesh_name.contains("Window"):
			kind = "timber"
			tint = Color("#3A3228") if mesh_name.contains("Window") else DARK_TIMBER
			tex = timber_tex
			uv_scale = 2.0
			emission = 0.0
			mix_amt = 0.40
			boost = 1.0
			lift = 0.96
		elif mesh_name.contains("Buttress") or mesh_name.contains("String"):
			kind = "stone"
			tint = CASTLE_LIMESTONE.lerp(CASTLE_MASONRY, 0.48)
			tex = stone_tex
			uv_scale = 2.0
			emission = 0.03
			mix_amt = 0.40
			boost = 1.08
			lift = 1.08
		elif mesh_name.contains("Crenel") or mesh_name.contains("Plinth"):
			kind = "stone"
			tint = CASTLE_LIMESTONE.lerp(CASTLE_MASONRY, 0.34)
			tex = stone_tex
			uv_scale = 2.4
			emission = 0.04
			mix_amt = 0.36
			boost = 1.04
			lift = 1.06
		var material := ShaderMaterial.new()
		material.shader = ArchShader
		if tex != null:
			material.set_shader_parameter("albedo_tex", tex)
		material.set_shader_parameter("tint", tint)
		material.set_shader_parameter("tex_mix", mix_amt)
		material.set_shader_parameter("roughness", 0.90)
		material.set_shader_parameter("uv_scale", uv_scale)
		material.set_shader_parameter("luma_lift", lift)
		material.set_shader_parameter("emission_amt", emission)
		material.set_shader_parameter("value_boost", boost)
		instance.material_override = material
		instance.set_meta("civic_kind", kind)
		instance.set_meta("civic_building", building_type)


static func _apply_kaykit_remap(root: Node, building_type: String) -> void:
	# Per-surface override. Do not edit the imported atlas. Civic roofs
	# stay muted teal slate; houses / workshops roll terracotta. No emerald.
	var terracotta := building_type == "HOUSE" or building_type == "LUMBER_CAMP" or building_type == "SAWMILL" or building_type == "FARM" or building_type == "BAKERY" or building_type == "STOREHOUSE"
	var wall_lift := 1.50 if building_type == "TOWN_HALL" or building_type == "CASTLE" else 1.12
	var roughness := 0.86 if terracotta else 0.90
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var instance := node as MeshInstance3D
		if instance == null:
			continue
		var tex: Texture2D = _first_albedo_texture(instance)
		var material := ShaderMaterial.new()
		material.shader = KaykitRemap
		if tex != null:
			material.set_shader_parameter("albedo_tex", tex)
		material.set_shader_parameter("wall_color", CASTLE_LIMESTONE)
		material.set_shader_parameter("plaster_color", WARM_PLASTER)
		material.set_shader_parameter("masonry_color", CASTLE_MASONRY)
		material.set_shader_parameter("timber_color", DARK_TIMBER)
		material.set_shader_parameter("roof_color", HALL_SLATE)
		material.set_shader_parameter("roof_shadow", KEEP_SLATE)
		material.set_shader_parameter("terracotta", CLAY_ROOF)
		material.set_shader_parameter("use_terracotta", 1.0 if terracotta else 0.0)
		material.set_shader_parameter("wall_lift", wall_lift)
		material.set_shader_parameter("roughness", roughness)
		instance.material_override = material


static func _first_albedo_texture(instance: MeshInstance3D) -> Texture2D:
	if instance.material_override is StandardMaterial3D:
		var over := instance.material_override as StandardMaterial3D
		if over.albedo_texture != null:
			return over.albedo_texture
	if instance.mesh != null:
		for surface in instance.mesh.get_surface_count():
			var mat := instance.get_active_material(surface)
			if mat == null:
				mat = instance.mesh.surface_get_material(surface)
			if mat is StandardMaterial3D and (mat as StandardMaterial3D).albedo_texture != null:
				return (mat as StandardMaterial3D).albedo_texture
	return load("res://assets/settlement3d/runtime/buildings/hexagons_medieval.png") as Texture2D


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
	# KayKit hexagon atlas ships near-white albedo. Do not classify that as metal.
	if material.albedo_texture != null and kind == "metal":
		kind = "plaster" if building_type == "HOUSE" or building_type == "BAKERY" or building_type == "FARM" else "stone"
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
