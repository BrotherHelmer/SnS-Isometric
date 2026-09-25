class_name ProductionProjectileView3D
extends Node3D

var projectile_id := ""
var orb: MeshInstance3D
var trail: MeshInstance3D


func configure(snapshot: Dictionary, from_world: Vector3, to_world: Vector3) -> void:
	projectile_id = String(snapshot.get("id", ""))
	name = "Projectile_%s" % projectile_id.replace(":", "_")
	_create_visual(String(snapshot.get("kind", "arrow")), String(snapshot.get("faction", "player_military")))
	apply_snapshot(snapshot, from_world, to_world)


func apply_snapshot(snapshot: Dictionary, from_world: Vector3, to_world: Vector3) -> void:
	var total := maxf(0.001, float(snapshot.get("total", 0.65)))
	var fraction := clampf(1.0 - float(snapshot.get("life", 0.0)) / total, 0.0, 1.0)
	var arc := sin(fraction * PI) * maxf(0.65, from_world.distance_to(to_world) * 0.08)
	position = from_world.lerp(to_world, fraction) + Vector3.UP * (0.9 + arc)
	if trail != null:
		var difference := to_world - from_world
		trail.scale.z = maxf(0.15, difference.length() * 0.08)
		if difference.length_squared() > 0.001:
			trail.look_at_from_position(trail.position, trail.position + difference.normalized(), Vector3.UP)


func _create_visual(kind: String, faction: String) -> void:
	orb = MeshInstance3D.new()
	orb.name = "AuthoritativeProjectile"
	var sphere := SphereMesh.new()
	sphere.radius = 0.14 if kind != "hex" else 0.24
	sphere.height = sphere.radius * 2.0
	orb.mesh = sphere
	var color := Color("#ffd36b")
	if faction == "rival" or faction == "hostile":
		color = Color("#e74b62") if kind != "hex" else Color("#bd64dc")
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.2
	orb.material_override = material
	add_child(orb)
	trail = MeshInstance3D.new()
	trail.name = "AttackTrail"
	var trail_mesh := BoxMesh.new()
	trail_mesh.size = Vector3(0.035, 0.035, 1.0)
	trail.mesh = trail_mesh
	trail.material_override = material
	trail.position.z = 0.18
	add_child(trail)
