class_name ProductionBuildingView3D
extends Node3D

const Catalog = preload("res://src/GodotClient3D/Scripts/production_asset_catalog.gd")
const ScaleProfile = preload("res://src/GodotClient3D/Scripts/production_scale_profile.gd")
const ContactAO = preload("res://src/GodotClient3D/Scripts/production_contact_ao.gd")

var entity_id := 0
var building_type := ""
var footprint := Vector2i.ONE
var rotation_quarters := 0
var is_construction := false
var construction_fraction := 1.0
var model_root: Node3D
var construction_root: Node3D
var workyard_root: Node3D
var selection_ring: MeshInstance3D
var selection_area: Area3D
var progress_label: Label3D
var sockets: Dictionary = {}
var inventory_indicators: Array[Node3D] = []
var last_snapshot: Dictionary = {}
var faction := "player"
var selection_kind := "building"
var ownership_banner: MeshInstance3D
var damage_marker: MeshInstance3D
var window_light: OmniLight3D
var window_emission: MeshInstance3D
var work_smoke: CPUParticles3D
var lantern_light: OmniLight3D
var wall_signature := ""


func configure(snapshot: Dictionary) -> void:
	entity_id = int(snapshot.get("id", 0))
	building_type = String(snapshot.get("type", "HOUSE"))
	footprint = Vector2i(snapshot.get("footprint", Vector2i.ONE))
	rotation_quarters = int(snapshot.get("rotation", 0))
	is_construction = bool(snapshot.get("construction", false))
	construction_fraction = float(snapshot.get("construction_fraction", 1.0))
	faction = String(snapshot.get("faction", "player"))
	selection_kind = String(snapshot.get("selection_kind", "building"))
	last_snapshot = snapshot.duplicate(true)
	wall_signature = "%d:%d:%d" % [int(snapshot.get("wall_mask", 0)), int(bool(snapshot.get("gate_adjacent", false))), int(bool(snapshot.get("gate_closed", false)))]
	name = "%s_%d" % ["Construction" if is_construction else building_type, entity_id]
	rotation.y = -float(rotation_quarters) * PI * 0.5
	# Issue #5: Check if this is Town Hall and should upgrade to Castle
	var has_barracks := bool(snapshot.get("has_barracks", false))
	if building_type == "TOWN_HALL" and has_barracks:
		building_type = "CASTLE"
		# Update last_snapshot to reflect the castle upgrade so apply_snapshot
		# doesn't trigger another rebuild on every frame
		last_snapshot["has_barracks"] = true
	_rebuild()
	apply_snapshot(snapshot)


func apply_snapshot(snapshot: Dictionary) -> void:
	var next_type := String(snapshot.get("type", building_type))
	var next_construction := bool(snapshot.get("construction", false))
	var next_footprint := Vector2i(snapshot.get("footprint", footprint))
	var next_wall_signature := "%d:%d:%d" % [int(snapshot.get("wall_mask", 0)), int(bool(snapshot.get("gate_adjacent", false))), int(bool(snapshot.get("gate_closed", false)))]
	var next_has_barracks := bool(snapshot.get("has_barracks", false))
	var last_has_barracks := bool(last_snapshot.get("has_barracks", false))
	
	# Issue #5 / playtest.11 fix: Normalize type comparison for CASTLE upgrade.
	# Sim snapshot stays TOWN_HALL but view remaps to CASTLE when has_barracks.
	# Do NOT treat TOWN_HALL+barracks vs CASTLE as a type change (no per-frame rebuild).
	var normalized_next_type := next_type
	if next_type == "TOWN_HALL" and next_has_barracks:
		normalized_next_type = "CASTLE"
	
	if normalized_next_type != building_type or next_construction != is_construction or next_footprint != footprint or (next_type == "WALL" and next_wall_signature != wall_signature) or (next_type == "TOWN_HALL" and next_has_barracks != last_has_barracks):
		configure(snapshot)
		return
	last_snapshot = snapshot.duplicate(true)
	wall_signature = next_wall_signature
	construction_fraction = float(snapshot.get("construction_fraction", construction_fraction))
	_update_construction_visual()
	_update_inventory_indicators(Dictionary(snapshot.get("local_inventory", {})))
	if construction_root != null:
		construction_root.visible = not bool(snapshot.get("site_clearing", false))
	if progress_label != null:
		if bool(snapshot.get("site_clearing", false)):
			progress_label.text = "CLEARING SITE"
			progress_label.visible = true
		else:
			progress_label.text = "%s  %d%%" % [building_type.replace("_", " ").capitalize(), roundi(construction_fraction * 100.0)]
			progress_label.visible = is_construction
	_update_damage_visual(int(snapshot.get("hp", 1)), int(snapshot.get("max_hp", 1)))
	_update_night_presentation(bool(snapshot.get("night", false)), int(snapshot.get("sheltered_occupants", 0)))
	_update_activity_presentation(bool(snapshot.get("production_active", false)), bool(snapshot.get("night", false)))


func set_selected(value: bool) -> void:
	if selection_ring != null:
		selection_ring.visible = value


func stable_entity_id() -> int:
	return entity_id


func socket_world(socket_name: String) -> Vector3:
	if not sockets.has(socket_name):
		return global_position
	return (sockets[socket_name] as Marker3D).global_position


func camera_focus_position() -> Vector3:
	return socket_world("camera_focus")


func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	model_root = null
	construction_root = null
	workyard_root = null
	selection_ring = null
	ownership_banner = null
	damage_marker = null
	window_light = null
	window_emission = null
	work_smoke = null
	lantern_light = null
	selection_area = null
	progress_label = null
	ownership_banner = null
	damage_marker = null
	window_light = null
	window_emission = null
	work_smoke = null
	lantern_light = null
	sockets.clear()
	inventory_indicators.clear()
	_create_semantic_sockets()
	_create_selection_shape()
	if is_construction:
		_create_construction_visual()
	else:
		_create_completed_model()
		_create_workyard()
		_create_building_identity_markers()
	_create_ownership_banner()
	_create_contact_ao()


func _create_completed_model() -> void:
	if building_type == "WALL":
		_create_wall_model()
		return
	var packed := load(Catalog.building_path(building_type)) as PackedScene
	if packed == null:
		return
	model_root = packed.instantiate()
	model_root.name = "SemanticModel_%s" % building_type
	model_root.scale = Vector3.ONE * ScaleProfile.building_scale(building_type)
	model_root.position.z = _model_offset_z()
	add_child(model_root)


func _create_wall_model() -> void:
	model_root = Node3D.new()
	model_root.name = "ConnectionAwareWall"
	add_child(model_root)
	var mask := int(last_snapshot.get("wall_mask", 0))
	if mask == 0:
		mask = 5
	var stone := _material(Color("#a99d81"), 0.0)
	for index in 4:
		if mask & (1 << index) == 0:
			continue
		var segment := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.70, 1.95, 2.25)
		segment.mesh = mesh
		segment.position = Vector3(0.0, 0.98, -1.05).rotated(Vector3.UP, float(index) * PI * 0.5)
		segment.rotation.y = float(index) * PI * 0.5
		segment.material_override = stone
		model_root.add_child(segment)
		for merlon_index in 3:
			var merlon := MeshInstance3D.new()
			merlon.name = "Crenellation"
			var crown := BoxMesh.new()
			crown.size = Vector3(0.78, 0.42, 0.4)
			merlon.mesh = crown
			merlon.position = Vector3(0.0, 1.12, -0.86 + merlon_index * 0.86)
			merlon.material_override = stone
			segment.add_child(merlon)
	var post := MeshInstance3D.new()
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.92, 2.45, 0.92)
	post.mesh = post_mesh
	post.position.y = 1.22
	post.material_override = _material(Color("#827e70"), 0.0)
	model_root.add_child(post)
	if bool(last_snapshot.get("gate_adjacent", false)):
		var pennant := MeshInstance3D.new()
		var pennant_mesh := BoxMesh.new()
		pennant_mesh.size = Vector3(0.56, 0.34, 0.06)
		pennant.mesh = pennant_mesh
		pennant.position = Vector3(0.0, 2.45, 0.0)
		pennant.material_override = _material(Color("#b38a45"), 0.0)
		model_root.add_child(pennant)


func _create_semantic_sockets() -> void:
	var world_size := ScaleProfile.footprint_world_size(footprint)
	var visual_size := _visual_size()
	var model_offset_z := _model_offset_z()
	var visual_front := model_offset_z + visual_size.z * 0.5
	var lateral := minf(world_size.x * 0.38, maxf(0.78, visual_size.x * 0.30))
	var definitions := {
		"entrance": Vector3(0.0, 0.0, visual_front + 0.30),
		"carrier_pickup": Vector3(-lateral, 0.0, visual_front + 0.55),
		"carrier_dropoff": Vector3(lateral, 0.0, visual_front + 0.55),
		"worker_station": Vector3(-minf(world_size.x * 0.36, visual_size.x * 0.5 + 0.65), 0.0, model_offset_z - visual_size.z * 0.18),
		"construction_delivery": Vector3(lateral, 0.0, visual_front + 0.48),
		"workyard_left": Vector3(-minf(world_size.x * 0.42, visual_size.x * 0.5 + 0.82), 0.0, model_offset_z - visual_size.z * 0.20),
		"workyard_right": Vector3(minf(world_size.x * 0.42, visual_size.x * 0.5 + 0.82), 0.0, model_offset_z - visual_size.z * 0.20),
		"vfx": Vector3(visual_size.x * 0.20, maxf(1.6, visual_size.y * 0.72), model_offset_z - visual_size.z * 0.12),
		"camera_focus": Vector3(0.0, maxf(2.0, visual_size.y * 0.52), model_offset_z),
	}
	for socket_name in definitions:
		var marker := Marker3D.new()
		marker.name = String(socket_name).to_pascal_case()
		marker.position = definitions[socket_name]
		add_child(marker)
		sockets[socket_name] = marker


func _create_selection_shape() -> void:
	var world_size := ScaleProfile.footprint_world_size(footprint)
	var visual_size := _visual_size()
	var model_offset_z := _model_offset_z()
	var minimum_z := minf(-world_size.y * 0.5, model_offset_z - visual_size.z * 0.5 - 0.28)
	var maximum_z := maxf(world_size.y * 0.5, model_offset_z + visual_size.z * 0.5 + 0.28)
	var selection_depth := maximum_z - minimum_z
	var selection_center_z := (minimum_z + maximum_z) * 0.5
	var selection_width := maxf(world_size.x, visual_size.x + 0.56)
	var selection_height := maxf(4.5, visual_size.y + 0.75)
	selection_ring = MeshInstance3D.new()
	selection_ring.name = "SelectionRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 1.0
	torus.outer_radius = 1.08
	torus.rings = 40
	torus.ring_segments = 6
	selection_ring.mesh = torus
	selection_ring.scale = Vector3(maxf(1.0, selection_width * 0.48), 1.0, maxf(1.0, selection_depth * 0.48))
	selection_ring.position = Vector3(0.0, 0.055, selection_center_z)
	var ring_material := StandardMaterial3D.new()
	ring_material.albedo_color = Color(0.98, 0.76, 0.25, 0.78)
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	selection_ring.material_override = ring_material
	selection_ring.visible = false
	add_child(selection_ring)
	selection_area = Area3D.new()
	selection_area.name = "SelectionArea"
	selection_area.collision_layer = 2
	selection_area.collision_mask = 0
	selection_area.set_meta("selection_kind", selection_kind)
	selection_area.set_meta("entity_id", entity_id)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(selection_width, selection_height, selection_depth)
	collision.shape = shape
	collision.position = Vector3(0.0, selection_height * 0.5, selection_center_z)
	selection_area.add_child(collision)
	add_child(selection_area)


func _create_construction_visual() -> void:
	construction_root = Node3D.new()
	construction_root.name = "ConstructionPresentation"
	add_child(construction_root)
	var world_size := ScaleProfile.footprint_world_size(footprint)
	var visual_size := _visual_size()
	var model_offset_z := _model_offset_z()
	var foundation_size := Vector2(
		minf(world_size.x * 0.92, visual_size.x + 0.56),
		minf(world_size.y * 0.92, visual_size.z + 0.56)
	)
	var foundation := MeshInstance3D.new()
	foundation.name = "Foundation"
	var foundation_mesh := BoxMesh.new()
	foundation_mesh.size = Vector3(foundation_size.x, 0.20, foundation_size.y)
	foundation.mesh = foundation_mesh
	foundation.position = Vector3(0.0, 0.10, model_offset_z)
	foundation.material_override = _material(Color("#5c4030"), 0.0)
	construction_root.add_child(foundation)
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var post := MeshInstance3D.new()
		post.name = "ScaffoldPost"
		var post_mesh := BoxMesh.new()
		var post_height := maxf(2.4, visual_size.y * 0.72)
		post_mesh.size = Vector3(0.16, post_height, 0.16)
		post.mesh = post_mesh
		post.position = Vector3(corner.x * foundation_size.x * 0.42, post_height * 0.5, model_offset_z + corner.y * foundation_size.y * 0.42)
		post.material_override = _material(Color("#705033"), 0.0)
		construction_root.add_child(post)
	var beam_height := maxf(2.4, visual_size.y * 0.72)
	var hx := foundation_size.x * 0.42
	var hz := foundation_size.y * 0.42
	for z_side in [-1.0, 1.0]:
		var beam := MeshInstance3D.new()
		beam.name = "ScaffoldBeamX"
		var beam_mesh := BoxMesh.new()
		beam_mesh.size = Vector3(hx * 2.0 + 0.16, 0.12, 0.12)
		beam.mesh = beam_mesh
		beam.position = Vector3(0.0, beam_height - 0.10, model_offset_z + z_side * hz)
		beam.material_override = _material(Color("#8a6238"), 0.0)
		construction_root.add_child(beam)
	for x_side in [-1.0, 1.0]:
		var beam := MeshInstance3D.new()
		beam.name = "ScaffoldBeamZ"
		var beam_mesh := BoxMesh.new()
		beam_mesh.size = Vector3(0.12, 0.12, hz * 2.0 + 0.16)
		beam.mesh = beam_mesh
		beam.position = Vector3(x_side * hx, beam_height - 0.10, model_offset_z)
		beam.material_override = _material(Color("#8a6238"), 0.0)
		construction_root.add_child(beam)
	var packed := load(Catalog.building_path(building_type)) as PackedScene
	if packed != null:
		model_root = packed.instantiate()
		model_root.name = "EmergingStructure"
		model_root.position.z = model_offset_z
		construction_root.add_child(model_root)
	progress_label = Label3D.new()
	progress_label.name = "ConstructionProgress"
	progress_label.position = Vector3(0.0, maxf(3.8, visual_size.y + 0.8), model_offset_z)
	progress_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	progress_label.no_depth_test = true
	progress_label.font_size = 24
	progress_label.outline_size = 6
	progress_label.modulate = Color("#f0cf8a")
	add_child(progress_label)
	_update_construction_visual()


func _update_construction_visual() -> void:
	if not is_construction or model_root == null:
		return
	var stage := 0
	if construction_fraction >= 0.72:
		stage = 3
	elif construction_fraction >= 0.38:
		stage = 2
	elif construction_fraction >= 0.08:
		stage = 1
	model_root.visible = stage > 0
	if not model_root.visible:
		return
	var full_scale := ScaleProfile.building_scale(building_type)
	var revealed_height: float = [0.0, 0.46, 0.76, 1.0][stage]
	model_root.scale = Vector3(full_scale, full_scale * revealed_height, full_scale)


func _create_workyard() -> void:
	workyard_root = Node3D.new()
	workyard_root.name = "SemanticWorkyard"
	add_child(workyard_root)
	match building_type:
		"TOWN_HALL", "CASTLE":
			_add_prop("lantern", Vector3(2.15, 0.0, 1.65), Vector3.ONE, "FoundingLantern")
			_add_prop("fence", Vector3(-2.6, 0.0, -1.8), Vector3.ONE, "FoundingFence")
			_add_prop("cart", Vector3(2.55, 0.0, -0.8), Vector3.ONE * 0.7, "FoundingCart")
			# Existing civic supplies stay inside the hall's yard and do not add
			# occupancy, resources or new buildings to the simulation.
			_add_prop("barrel", Vector3(-2.15, 0.0, 2.5), Vector3.ONE * 3.5, "FoundingBarrel")
			_add_prop("crate", Vector3(-2.55, 0.0, 1.7), Vector3.ONE * 3.5, "FoundingCrate")
			_add_prop("wheelbarrow", Vector3(2.70, 0.0, 2.5), Vector3.ONE * 0.45, "FoundingWheelbarrow", "", Vector3(0.0, 25.0, 0.0))
			# Issue #5: Castle upgrade - add military features when barracks built
			if building_type == "CASTLE":
				# Add battlements/fortifications
				for side in [-1.0, 1.0]:
					var turret := MeshInstance3D.new()
					turret.name = "CastleTurret"
					var turret_mesh := CylinderMesh.new()
					turret_mesh.height = 3.2
					turret_mesh.top_radius = 0.65
					turret_mesh.bottom_radius = 0.75
					turret_mesh.radial_segments = 8
					turret.mesh = turret_mesh
					turret.position = Vector3(side * 3.5, 1.6, -1.2)
					turret.material_override = _material(Color("#6a6a5a"), 0.0)
					workyard_root.add_child(turret)
					# Add crenellations on turret
					for cren_i in 4:
						var merlon := MeshInstance3D.new()
						merlon.name = "TurretMerlon"
						var merlon_mesh := BoxMesh.new()
						merlon_mesh.size = Vector3(0.22, 0.35, 0.18)
						merlon.mesh = merlon_mesh
						var angle := float(cren_i) * 90.0
						merlon.position = Vector3(side * 3.5 + cos(deg_to_rad(angle)) * 0.65, 3.25, -1.2 + sin(deg_to_rad(angle)) * 0.65)
						merlon.material_override = _material(Color("#5a5a4a"), 0.0)
						workyard_root.add_child(merlon)
				# Add royal banner
				var keep_pole := MeshInstance3D.new()
				keep_pole.name = "KeepBannerPole"
				var pole_mesh := BoxMesh.new()
				pole_mesh.size = Vector3(0.14, 3.5, 0.14)
				keep_pole.mesh = pole_mesh
				keep_pole.position = Vector3(0.0, 5.25, -0.5)
				keep_pole.material_override = _material(Color("#3a2a1a"), 0.0)
				workyard_root.add_child(keep_pole)
				var royal_flag := MeshInstance3D.new()
				royal_flag.name = "RoyalBanner"
				var flag_mesh := BoxMesh.new()
				flag_mesh.size = Vector3(1.1, 0.75, 0.08)
				royal_flag.mesh = flag_mesh
				royal_flag.position = Vector3(-0.55, 6.5, -0.5)
				royal_flag.material_override = _material(Color("#7a4a3a"), 0.0)
				workyard_root.add_child(royal_flag)
		"LUMBER_CAMP":
			# Issue #2 fix: Lumber Camp - more rustic forest camp with stacks and tools
			_add_prop("wood_stack", Vector3(-2.75, 0.0, 0.55), Vector3.ONE * 1.2, "DecorativeLumber")
			_add_prop("wood_stack", Vector3(-0.45, 0.0, -1.65), Vector3.ONE * 0.85, "InventoryIndicatorWood", "wood")
			_add_prop("work_axe", Vector3(-2.00, 0.55, 1.35), Vector3.ONE * 1.15, "DecorativeWorkAxe", "", Vector3(0.0, 0.0, -24.0))
			_add_prop("wheelbarrow", Vector3(2.8, 0.0, 0.35), Vector3.ONE * 0.75, "CampWheelbarrow", "", Vector3(0.0, 45.0, 0.0))
			# Add a simple tent-like structure marker
			var tent := MeshInstance3D.new()
			tent.name = "CampTentMarker"
			var tent_mesh := BoxMesh.new()
			tent_mesh.size = Vector3(1.2, 1.4, 1.2)
			tent.mesh = tent_mesh
			tent.position = Vector3(-2.3, 0.7, -1.2)
			tent.rotation_degrees = Vector3(0.0, 25.0, 0.0)
			tent.material_override = _material(Color("#8b7355"), 0.0)
			workyard_root.add_child(tent)
		"SAWMILL":
			# Issue #2 fix: Sawmill - industrial with saw blade and organized planks
			_add_prop("plank_stack", Vector3(2.65, 0.0, 0.45), Vector3.ONE * 1.0, "InventoryIndicatorPlanks", "planks")
			_add_prop("wood_stack", Vector3(-2.55, 0.0, 0.25), Vector3.ONE * 0.85, "InventoryIndicatorWood", "wood")
			# Add a circular saw blade prop as visual marker
			var saw_blade := MeshInstance3D.new()
			saw_blade.name = "SawBladeMarker"
			var blade_mesh := CylinderMesh.new()
			blade_mesh.height = 0.08
			blade_mesh.top_radius = 0.85
			blade_mesh.bottom_radius = 0.85
			blade_mesh.radial_segments = 16
			saw_blade.mesh = blade_mesh
			saw_blade.position = Vector3(-2.7, 0.9, -1.5)
			saw_blade.rotation_degrees = Vector3(90.0, 0.0, 22.5)
			saw_blade.material_override = _material(Color("#5a5a5a"), 0.0)
			workyard_root.add_child(saw_blade)
			# Add teeth to saw
			for tooth_i in 8:
				var tooth := MeshInstance3D.new()
				tooth.name = "SawTooth"
				var tooth_mesh := BoxMesh.new()
				tooth_mesh.size = Vector3(0.12, 0.15, 0.06)
				tooth.mesh = tooth_mesh
				var angle := float(tooth_i) * 45.0
				var radius := 0.85
				tooth.position = Vector3(-2.7 + cos(deg_to_rad(angle)) * radius, 0.9, -1.5 + sin(deg_to_rad(angle)) * radius)
				tooth.rotation_degrees = Vector3(90.0, angle, 0.0)
				tooth.material_override = _material(Color("#4a4a4a"), 0.0)
				workyard_root.add_child(tooth)
		"QUARRY":
			_add_prop("stone_stack", Vector3(3.15, 0.0, 0.20), Vector3.ONE * 0.85, "InventoryIndicatorStone", "stone")
			_add_prop("wheelbarrow", Vector3(-3.10, 0.0, 0.35), Vector3.ONE * 0.8, "DecorativeWheelbarrow")
		"FARM":
			# Issue #3 fix: Farm must look like a farm - add crops, paddock, and sheep
			for x in range(-1, 3):
				for z in range(3):
					_add_prop("dirt_plot", Vector3(float(x) * 1.15, 0.0, -0.85 - float(z) * 0.95), Vector3.ONE * 0.72, "DecorativeFarmPlot")
					_add_prop("wheat_crop", Vector3(float(x) * 1.15, 0.08, -0.85 - float(z) * 0.95), Vector3.ONE * 1.72, "WheatCrop")
			_add_prop("wheelbarrow", Vector3(3.15, 0.0, -1.20), Vector3.ONE * 0.76, "InventoryIndicatorWheat", "wheat")
			# Add sheep paddock with fence
			var paddock := MeshInstance3D.new()
			paddock.name = "FarmPaddock"
			var paddock_mesh := BoxMesh.new()
			paddock_mesh.size = Vector3(3.2, 0.04, 2.4)
			paddock.mesh = paddock_mesh
			paddock.position = Vector3(-2.8, 0.02, 1.0)
			paddock.material_override = _material(Color("#7a8a5a"), 0.0)
			workyard_root.add_child(paddock)
			# Add simple fence posts
			for post_x in [-1.6, -2.4, -3.2, -4.0]:
				var fence_post := MeshInstance3D.new()
				fence_post.name = "FencePost"
				var post_mesh := BoxMesh.new()
				post_mesh.size = Vector3(0.08, 0.55, 0.08)
				fence_post.mesh = post_mesh
				fence_post.position = Vector3(post_x, 0.28, -0.2)
				fence_post.material_override = _material(Color("#5a4a3a"), 0.0)
				workyard_root.add_child(fence_post)
			# Add sheep (simple box representations)
			var sheep_positions := [Vector3(-2.5, 0.0, 0.8), Vector3(-3.2, 0.0, 1.4), Vector3(-2.8, 0.0, 1.8)]
			for sheep_pos in sheep_positions:
				var sheep := MeshInstance3D.new()
				sheep.name = "Sheep"
				var sheep_mesh := BoxMesh.new()
				sheep_mesh.size = Vector3(0.35, 0.32, 0.48)
				sheep.mesh = sheep_mesh
				sheep.position = sheep_pos + Vector3(0.0, 0.16, 0.0)
				sheep.rotation_degrees.y = randf_range(-30.0, 30.0)
				sheep.material_override = _material(Color("#e8e8d8"), 0.0)
				workyard_root.add_child(sheep)
				# Add simple head
				var head := MeshInstance3D.new()
				head.name = "SheepHead"
				var head_mesh := BoxMesh.new()
				head_mesh.size = Vector3(0.22, 0.22, 0.22)
				head.mesh = head_mesh
				head.position = Vector3(0.0, 0.05, 0.28)
				head.material_override = _material(Color("#2a2a2a"), 0.0)
				sheep.add_child(head)
		"STOREHOUSE":
			_add_prop("crate", Vector3(-2.85, 0.0, 0.55), Vector3.ONE, "DecorativeCrate")
			_add_prop("barrel", Vector3(2.85, 0.0, 0.55), Vector3.ONE, "DecorativeBarrel")
		"BAKERY":
			_add_prop("crate", Vector3(2.75, 0.0, 0.20), Vector3.ONE, "InventoryIndicatorBread", "bread")
		"BARRACKS":
			# Issue #4 fix: Barracks must look military - add more military features
			_add_prop("weaponrack", Vector3(-2.85, 0.0, 0.55), Vector3.ONE * 1.1, "BarracksWeaponRack", "", Vector3(0.0, 32.0, 0.0))
			_add_prop("weaponrack", Vector3(2.75, 0.0, 0.35), Vector3.ONE * 1.1, "BarracksWeaponRack", "", Vector3(0.0, -28.0, 0.0))
			_add_prop("training_target", Vector3(-2.10, 0.0, -2.15), Vector3.ONE * 1.15, "BarracksTrainingTarget", "", Vector3(0.0, 18.0, 0.0))
			# Add armor rack markers
			var armor_stand := MeshInstance3D.new()
			armor_stand.name = "ArmorStand"
			var armor_mesh := BoxMesh.new()
			armor_mesh.size = Vector3(0.45, 0.85, 0.25)
			armor_stand.mesh = armor_mesh
			armor_stand.position = Vector3(2.5, 0.55, -1.8)
			armor_stand.material_override = _material(Color("#5a5a5a"), 0.0)
			workyard_root.add_child(armor_stand)
			# Add military banner pole at entrance
			var entry_pole := MeshInstance3D.new()
			entry_pole.name = "EntryBannerPole"
			var pole_mesh := BoxMesh.new()
			pole_mesh.size = Vector3(0.12, 2.8, 0.12)
			entry_pole.mesh = pole_mesh
			entry_pole.position = Vector3(1.8, 1.4, 2.2)
			entry_pole.material_override = _material(Color("#4a3a2a"), 0.0)
			workyard_root.add_child(entry_pole)
			var entry_flag := MeshInstance3D.new()
			entry_flag.name = "EntryBanner"
			var flag_mesh := BoxMesh.new()
			flag_mesh.size = Vector3(0.85, 0.55, 0.06)
			entry_flag.mesh = flag_mesh
			entry_flag.position = Vector3(1.35, 2.35, 2.2)
			entry_flag.material_override = _material(Color("#8a3a3a") if faction == "rival" else Color("#4a5a6a"), 0.0)
			workyard_root.add_child(entry_flag)
	_create_semantic_identity_geometry()


func _create_semantic_identity_geometry() -> void:
	match building_type:
		"TOWN_HALL", "CASTLE":
			_create_town_hall_civic_mass()
		"FARM":
			var silo := MeshInstance3D.new()
			silo.name = "FarmSiloSilhouette"
			var silo_mesh := CylinderMesh.new()
			silo_mesh.top_radius = 0.65
			silo_mesh.bottom_radius = 0.78
			silo_mesh.height = 3.1
			silo_mesh.radial_segments = 10
			silo.mesh = silo_mesh
			silo.position = Vector3(-3.0, 1.55, -1.4)
			silo.material_override = _material(Color("#9a7a4d"), 0.0)
			workyard_root.add_child(silo)
		"BAKERY":
			var oven_glow := OmniLight3D.new()
			oven_glow.name = "OvenGlow"
			oven_glow.position = Vector3(1.7, 0.85, 1.7)
			oven_glow.light_color = Color("#ff9a52")
			oven_glow.light_energy = 1.0
			oven_glow.omni_range = 4.0
			workyard_root.add_child(oven_glow)
		"STOREHOUSE":
			_add_prop("long_crate", Vector3(-2.3, 0.0, -0.8), Vector3.ONE * 2.0, "StorehouseSupplies")
		"BARRACKS":
			var yard := MeshInstance3D.new()
			yard.name = "BarracksTrainingYard"
			var yard_mesh := BoxMesh.new()
			yard_mesh.size = Vector3(5.8, 0.06, 3.2)
			yard.mesh = yard_mesh
			yard.position = Vector3(0.0, 0.04, -2.0)
			yard.material_override = _material(Color("#776346"), 0.0)
			workyard_root.add_child(yard)
			for side in [-1.0, 1.0]:
				var post := MeshInstance3D.new()
				post.name = "MilitaryBannerPost"
				var post_mesh := BoxMesh.new()
				post_mesh.size = Vector3(0.15, 2.5, 0.15)
				post.mesh = post_mesh
				post.position = Vector3(side * 2.65, 1.25, -2.7)
				post.material_override = _material(Color("#5e4431"), 0.0)
				workyard_root.add_child(post)
				var flag := MeshInstance3D.new()
				flag.name = "MilitaryYardBanner"
				var flag_mesh := BoxMesh.new()
				flag_mesh.size = Vector3(0.72, 0.48, 0.06)
				flag.mesh = flag_mesh
				flag.position = Vector3(side * 2.38, 2.05, -2.7)
				flag.material_override = _material(Color("#6e2430") if faction == "rival" else Color("#355e6c"), 0.0)
				workyard_root.add_child(flag)


func _create_town_hall_civic_mass() -> void:
	# The KayKit castle is the keep. Extra timber boxes read as placeholder
	# warehouses glued to the walls, so the civic dressing stays a front stair.
	var stone := _material(Color("#777568"), 0.0)
	var plaza := MeshInstance3D.new()
	plaza.name = "CivicMeetingPlaza"
	var plaza_mesh := BoxMesh.new()
	plaza_mesh.size = Vector3(4.2, 0.08, 1.8)
	plaza.mesh = plaza_mesh
	plaza.position = Vector3(0.0, 0.04, 2.85)
	plaza.material_override = stone
	workyard_root.add_child(plaza)
	for step_index in 3:
		var step := MeshInstance3D.new()
		step.name = "TownHallFrontStep"
		var step_mesh := BoxMesh.new()
		step_mesh.size = Vector3(2.6 + float(step_index) * 0.35, 0.14, 0.42)
		step.mesh = step_mesh
		step.position = Vector3(0.0, 0.07 + float(step_index) * 0.11, 2.15 + float(step_index) * 0.32)
		step.material_override = stone
		workyard_root.add_child(step)


func _create_ownership_banner() -> void:
	if faction == "player" and selection_kind == "building":
		return
	ownership_banner = MeshInstance3D.new()
	ownership_banner.name = "OwnershipBanner"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.92, 0.58, 0.08)
	ownership_banner.mesh = mesh
	ownership_banner.position = sockets["vfx"].position + Vector3(0.0, 0.55, 0.0)
	var color := Color("#4d8c91") if faction == "player" else Color("#9b3943")
	ownership_banner.material_override = _material(color, 0.0)
	add_child(ownership_banner)
	if faction == "rival":
		var pole := MeshInstance3D.new()
		pole.name = "RivalBannerPole"
		var pole_mesh := BoxMesh.new()
		pole_mesh.size = Vector3(0.08, 1.35, 0.08)
		pole.mesh = pole_mesh
		pole.position = ownership_banner.position + Vector3(-0.42, -0.35, 0.0)
		pole.material_override = _material(Color("#4a3228"), 0.0)
		add_child(pole)
		var cloth := MeshInstance3D.new()
		cloth.name = "RivalCloth"
		var cloth_mesh := BoxMesh.new()
		cloth_mesh.size = Vector3(0.55, 0.82, 0.05)
		cloth.mesh = cloth_mesh
		cloth.position = ownership_banner.position + Vector3(-0.18, -0.15, 0.04)
		cloth.material_override = _material(Color("#6e2430"), 0.0)
		add_child(cloth)


func _update_damage_visual(hp: int, max_hp: int) -> void:
	if damage_marker == null:
		damage_marker = MeshInstance3D.new()
		damage_marker.name = "ContextDamageMarker"
		var mesh := TorusMesh.new()
		mesh.inner_radius = 1.15
		mesh.outer_radius = 1.26
		mesh.rings = 32
		mesh.ring_segments = 6
		damage_marker.mesh = mesh
		damage_marker.position.y = 0.08
		add_child(damage_marker)
	var fraction := clampf(float(hp) / float(maxi(1, max_hp)), 0.0, 1.0)
	damage_marker.material_override = _material(Color(0.92, 0.15, 0.08, 0.76).lerp(Color(0.93, 0.60, 0.14, 0.70), fraction), 0.25)
	damage_marker.visible = hp > 0 and hp < max_hp


func apply_light_palette(window_color: Color, torch_color: Color, torch_range: float) -> void:
	if window_light != null:
		window_light.light_color = window_color
		window_light.omni_range = torch_range
	if window_emission != null and window_emission.material_override is StandardMaterial3D:
		var glow_material := window_emission.material_override as StandardMaterial3D
		glow_material.emission = window_color
		glow_material.albedo_color = window_color
	if lantern_light != null:
		lantern_light.light_color = torch_color
		lantern_light.omni_range = clampf(torch_range, 4.0, 7.0)


func _update_night_presentation(night: bool, occupants: int) -> void:
	if building_type not in ["HOUSE", "TOWN_HALL", "BAKERY", "BARRACKS", "STOREHOUSE", "LUMBER_CAMP", "QUARRY", "SAWMILL", "FARM", "WATCHTOWER"]:
		return
	var inhabited := occupants > 0 if building_type == "HOUSE" else bool(last_snapshot.get("connected", false)) and (int(last_snapshot.get("assigned_staff", 0)) > 0 or int(last_snapshot.get("soldiers_assigned", 0)) > 0 or building_type in ["TOWN_HALL", "STOREHOUSE"])
	if window_light == null:
		window_light = OmniLight3D.new()
		window_light.name = "InhabitedWindowGlow"
		window_light.position = sockets["entrance"].position + Vector3(0.0, 1.25, -0.35)
		window_light.light_color = Color("#FFB347")
		window_light.light_energy = 1.05 if building_type != "TOWN_HALL" else 1.35
		window_light.omni_range = 5.5 if building_type != "TOWN_HALL" else 6.5
		window_light.shadow_enabled = false
		add_child(window_light)
		window_emission = MeshInstance3D.new()
		window_emission.name = "WarmWindowEmission"
		var glow_mesh := BoxMesh.new()
		glow_mesh.size = Vector3(0.72, 0.68, 0.08)
		window_emission.mesh = glow_mesh
		window_emission.position = sockets["entrance"].position + Vector3(0.0, 1.20, -0.12)
		var glow_material := _material(Color("#ffc06a"), 0.0)
		glow_material.emission_enabled = true
		glow_material.emission = Color("#FFB347")
		glow_material.emission_energy_multiplier = 2.1
		window_emission.material_override = glow_material
		add_child(window_emission)
	window_light.visible = night and inhabited
	if window_emission != null:
		window_emission.visible = night and inhabited
	
	if not night and inhabited and building_type not in ["TOWN_HALL", "STOREHOUSE"]:
		if window_emission != null:
			window_emission.visible = true
			var daytime_material := _material(Color("#9fc6a5"), 0.0)
			daytime_material.emission_enabled = true
			daytime_material.emission = Color("#7da88a")
			daytime_material.emission_energy_multiplier = 0.8
			window_emission.material_override = daytime_material


func _update_activity_presentation(active: bool, night: bool) -> void:
	if building_type in ["BAKERY", "LUMBER_CAMP", "SAWMILL", "HOUSE", "TOWN_HALL"] and work_smoke == null:
		work_smoke = CPUParticles3D.new()
		work_smoke.name = "ChimneySmoke"
		work_smoke.amount = 8
		work_smoke.lifetime = 3.2
		work_smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_POINT
		work_smoke.direction = Vector3.UP
		work_smoke.spread = 8.0
		work_smoke.gravity = Vector3(0.05, 0.35, 0.0)
		work_smoke.initial_velocity_min = 0.35
		work_smoke.initial_velocity_max = 0.85
		work_smoke.scale_amount_min = 0.18
		work_smoke.scale_amount_max = 0.42
		var smoke_material := StandardMaterial3D.new()
		smoke_material.albedo_color = Color(0.72, 0.72, 0.70, 0.28)
		smoke_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		smoke_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		work_smoke.mesh = SphereMesh.new()
		(work_smoke.mesh as SphereMesh).radius = 0.16
		(work_smoke.mesh as SphereMesh).height = 0.32
		work_smoke.material_override = smoke_material
		work_smoke.position = sockets["vfx"].position + Vector3(0.0, 0.85, 0.0)
		add_child(work_smoke)
	if work_smoke != null:
		work_smoke.emitting = active or (night and building_type in ["HOUSE", "TOWN_HALL", "BAKERY"])
	if building_type == "WATCHTOWER":
		if lantern_light == null:
			lantern_light = OmniLight3D.new()
			lantern_light.name = "WatchtowerLantern"
			lantern_light.light_color = Color("#FFC36B")
			lantern_light.light_energy = 0.85
			lantern_light.omni_range = 6.0
			lantern_light.shadow_enabled = false
			lantern_light.position = sockets["vfx"].position + Vector3(0.0, 0.4, 0.0)
			add_child(lantern_light)
		lantern_light.visible = night
	elif building_type == "OUTPOST":
		if lantern_light == null:
			lantern_light = OmniLight3D.new()
			lantern_light.name = "OutpostWyrdGlow"
			lantern_light.light_color = Color("#6bcfe0")
			lantern_light.light_energy = 0.45
			lantern_light.omni_range = 3.8
			lantern_light.shadow_enabled = false
			lantern_light.position = sockets["vfx"].position
			add_child(lantern_light)
		lantern_light.visible = active
		lantern_light.light_color = Color("#8a5a6a") if faction == "rival" else Color("#6bcfe0")


func _add_prop(prop_key: String, local_position: Vector3, prop_scale: Vector3, node_name: String, resource_type := "", rotation_degrees_value := Vector3.ZERO) -> void:
	if not Catalog.WORKYARD_PROPS.has(prop_key):
		return
	var packed := load(String(Catalog.WORKYARD_PROPS[prop_key])) as PackedScene
	if packed == null:
		return
	var prop := packed.instantiate()
	prop.name = node_name
	prop.position = local_position
	prop.scale = prop_scale * ScaleProfile.world_prop_scale(prop_key)
	prop.rotation_degrees = rotation_degrees_value
	workyard_root.add_child(prop)
	prop.set_meta("base_scale", prop.scale)
	if resource_type != "":
		prop.set_meta("inventory_resource", resource_type)
		inventory_indicators.append(prop)
	var prop_span := maxf(absf(prop.scale.x), absf(prop.scale.z)) * 0.95
	var prop_ao := ContactAO.make_instance("ContactAO", Vector2(prop_span, prop_span), 0.28)
	prop_ao.position = Vector3(local_position.x, 0.016, local_position.z)
	workyard_root.add_child(prop_ao)


func _update_inventory_indicators(inventory: Dictionary) -> void:
	for indicator in inventory_indicators:
		var resource_type := String(indicator.get_meta("inventory_resource", ""))
		var amount := int(inventory.get(resource_type, 0))
		indicator.visible = amount > 0
		var base_scale: Vector3 = indicator.get_meta("base_scale", indicator.scale)
		var pile := clampf(0.88 + float(mini(amount, 14)) * 0.045, 0.88, 1.42)
		indicator.scale = base_scale * pile


func _material(color: Color, transparency: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	if transparency > 0.0 or color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _create_building_identity_markers() -> void:
	if building_type == "CONSTRUCTION_SITE" or building_type == "ROAD" or building_type == "WALL":
		return
	
	var roof_pos: Vector3 = (sockets["vfx"] as Marker3D).position + Vector3(0.0, 1.2, 0.0)
	
	var identity_color := Color.WHITE
	var roof_marker: MeshInstance3D = null
	
	match building_type:
		"LUMBER_CAMP":
			identity_color = Color("#8b6f47")
			roof_marker = _create_roof_marker(roof_pos, Color("#6b4423"), Vector3(0.5, 0.3, 0.5))
		"SAWMILL":
			identity_color = Color("#5a4a3a")
			roof_marker = _create_roof_marker(roof_pos, Color("#4a3a2a"), Vector3(0.6, 0.4, 0.6))
		"QUARRY":
			identity_color = Color("#9a9588")
			roof_marker = _create_roof_marker(roof_pos, Color("#7a7568"), Vector3(0.5, 0.35, 0.5))
		"FARM":
			identity_color = Color("#d4b86a")
			roof_marker = _create_roof_marker(roof_pos, Color("#c4a850"), Vector3(0.5, 0.3, 0.5))
		"BAKERY":
			identity_color = Color("#c8524a")
			roof_marker = _create_roof_marker(roof_pos, Color("#a83830"), Vector3(0.5, 0.4, 0.5))
			_create_chimney_marker(roof_pos + Vector3(0.3, 0.5, 0.0))
		"BARRACKS":
			identity_color = Color("#6a4a4a")
			roof_marker = _create_roof_marker(roof_pos, Color("#5a3a3a"), Vector3(0.6, 0.35, 0.6))
			_create_military_banner(roof_pos + Vector3(0.0, 0.8, 0.0))
		"WATCHTOWER":
			_create_military_banner(roof_pos + Vector3(0.0, 1.5, 0.0))
		"STOREHOUSE":
			identity_color = Color("#8a7a5a")
	
	if roof_marker != null:
		add_child(roof_marker)


func _create_roof_marker(position: Vector3, color: Color, size: Vector3) -> MeshInstance3D:
	var marker := MeshInstance3D.new()
	marker.name = "RoofAccent"
	var box := BoxMesh.new()
	box.size = size
	marker.mesh = box
	marker.position = position
	marker.material_override = _material(color, 0.0)
	return marker


func _create_chimney_marker(position: Vector3) -> void:
	var chimney := MeshInstance3D.new()
	chimney.name = "Chimney"
	var cylinder := CylinderMesh.new()
	cylinder.height = 0.8
	cylinder.top_radius = 0.15
	cylinder.bottom_radius = 0.18
	chimney.mesh = cylinder
	chimney.position = position
	chimney.material_override = _material(Color("#3a2a2a"), 0.0)
	add_child(chimney)


func _create_military_banner(position: Vector3) -> void:
	var pole := MeshInstance3D.new()
	pole.name = "BannerPole"
	var pole_mesh := CylinderMesh.new()
	pole_mesh.height = 1.2
	pole_mesh.top_radius = 0.05
	pole_mesh.bottom_radius = 0.06
	pole.mesh = pole_mesh
	pole.position = position
	pole.material_override = _material(Color("#4a3a2a"), 0.0)
	add_child(pole)
	
	var flag := MeshInstance3D.new()
	flag.name = "Banner"
	var flag_mesh := BoxMesh.new()
	flag_mesh.size = Vector3(0.5, 0.35, 0.04)
	flag.mesh = flag_mesh
	flag.position = position + Vector3(0.25, 0.4, 0.0)
	
	var is_manned := int(last_snapshot.get("soldiers_assigned", 0)) > 0
	var flag_color := Color("#c84a4a") if is_manned else Color("#6a5a5a")
	var flag_mat := _material(flag_color, 0.0)
	flag_mat.emission_enabled = is_manned
	flag_mat.emission = Color("#d86a6a") if is_manned else Color.BLACK
	flag_mat.emission_energy_multiplier = 0.5
	flag.material_override = flag_mat
	add_child(flag)


func _create_contact_ao() -> void:
	if building_type == "ROAD":
		return
	var world_size := ScaleProfile.footprint_world_size(footprint)
	var visual := _visual_size()
	var width := maxf(world_size.x, visual.x) * 1.08
	var depth := maxf(world_size.y, visual.z) * 1.08
	var intensity := 0.28 if building_type == "WALL" else 0.42
	var disc := ContactAO.make_instance("ContactAO", Vector2(width, depth), intensity)
	disc.position = Vector3(0.0, 0.018, _model_offset_z())
	add_child(disc)


func _visual_size() -> Vector3:
	return ScaleProfile.building_visual_size(building_type, footprint)


func _model_offset_z() -> float:
	return ScaleProfile.building_front_offset(building_type, footprint)
