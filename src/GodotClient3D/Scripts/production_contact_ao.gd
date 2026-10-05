class_name ProductionContactAO
extends RefCounted

## GFX-04: shared contact-AO disc. Buildings get one instance; trees/rocks
## share a MultiMesh so the forest does not become hundreds of Decal nodes.

const ContactShader = preload("res://src/GodotClient3D/Shaders/settlement_contact_ao.gdshader")

static var _material: ShaderMaterial
static var _mesh: PlaneMesh


static func shared_material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = ContactShader
		_material.render_priority = -2
	return _material


static func disc_mesh() -> PlaneMesh:
	if _mesh == null:
		_mesh = PlaneMesh.new()
		_mesh.size = Vector2(2.0, 2.0)
	return _mesh


static func make_instance(node_name: String, size: Vector2, intensity := 0.40) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = disc_mesh()
	instance.scale = Vector3(maxf(size.x, 0.4) * 0.5, 1.0, maxf(size.y, 0.4) * 0.5)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := shared_material().duplicate()
	material.set_shader_parameter("intensity", intensity)
	instance.material_override = material
	instance.position.y = 0.018
	return instance


static func flatten_transform(source: Transform3D, scale_mul := 1.35) -> Transform3D:
	var scale_xz := maxf(source.basis.get_scale().x, source.basis.get_scale().z) * scale_mul
	var origin := source.origin
	origin.y += 0.018
	return Transform3D(Basis().scaled(Vector3(maxf(scale_xz, 0.35), 1.0, maxf(scale_xz, 0.35))), origin)


static func spawn_multimesh(host: Node3D, transforms: Array, intensity := 0.32) -> MultiMeshInstance3D:
	if host == null or transforms.is_empty():
		return null
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = disc_mesh()
	multimesh.instance_count = transforms.size()
	for index in transforms.size():
		multimesh.set_instance_transform(index, transforms[index])
	var instance := MultiMeshInstance3D.new()
	instance.name = "ContactAOBatch"
	instance.multimesh = multimesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := shared_material().duplicate()
	material.set_shader_parameter("intensity", intensity)
	instance.material_override = material
	host.add_child(instance)
	return instance
