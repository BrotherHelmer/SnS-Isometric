class_name ProductionCharacterView3D
extends Node3D

const Catalog = preload("res://src/GodotClient3D/Scripts/production_asset_catalog.gd")
const ScaleProfile = preload("res://src/GodotClient3D/Scripts/production_scale_profile.gd")
const Semantic = preload("res://src/GodotClient3D/Scripts/production_presentation_adapter.gd")

const CLIP_BY_STATE := {
	"Idle": "General/Idle_A",
	"Walk": "MovementBasic/Walking_A",
	"Run": "MovementBasic/Running_A",
	"Carry": "Tools/Holding_A",
	"WorkGeneric": "Tools/Working_A",
	"Chop": "Tools/Chopping",
	"Mine": "Tools/Pickaxing",
	"Farm": "Tools/Digging",
	"Hammer": "Tools/Hammering",
	"Saw": "Tools/Sawing",
	"Sleep": "Simulation/Lie_Idle",
	"Flee": "MovementBasic/Running_B",
	"Melee": "CombatMelee/Melee_1H_Attack_Chop",
	"Ranged": "CombatRanged/Ranged_Bow_Aiming_Idle",
	"Hit": "General/Hit_A",
	"Die": "General/Death_A",
}

static var _shared_libraries: Dictionary = {}
static var _libraries_ready := false
static var _cloth_materials: Dictionary = {}
static var _shared_state_machine: AnimationNodeStateMachine

var entity_id := 0
var worker_type := "settler"
var semantic_state := Semantic.IDLE
var character_model: Node3D
var skeleton: Skeleton3D
var animation_player: AnimationPlayer
var animation_tree: AnimationTree
var playback: AnimationNodeStateMachinePlayback
var right_hand_socket: BoneAttachment3D
var left_hand_socket: BoneAttachment3D
var equipped_tool: Node3D
var carried_prop: Node3D
var cargo_label: Label3D
var selection_ring: MeshInstance3D
var selection_area: Area3D
var faction_marker: MeshInstance3D
var damage_marker: MeshInstance3D
var alert_light: OmniLight3D
var target_position := Vector3.ZERO
var target_facing := Vector2.DOWN
var has_target := false
var current_tool := ""
var current_cargo := ""
var current_cargo_amount := 0
var current_faction := "player"
var current_selection_kind := "worker"
var presentation_paused := false
var animation_lod_enabled := true
var animation_elapsed := 0.0
var animation_update_interval := 1.0 / 12.0


func configure(id: int, type_name: String, initial_state := Semantic.IDLE) -> void:
	entity_id = id
	worker_type = type_name
	semantic_state = initial_state if initial_state in Semantic.ALL_STATES else Semantic.IDLE
	name = "Worker_%d_%s" % [entity_id, worker_type]
	if is_node_ready():
		_build_character()


func _ready() -> void:
	_build_character()
	_create_selection()


func _process(delta: float) -> void:
	_update_manual_animation(delta)
	if presentation_paused or not has_target:
		return
	var difference := target_position - global_position
	difference.y = 0.0
	if difference.length() > 0.01:
		var direction := difference.normalized()
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), minf(1.0, delta * 12.0))
		global_position = global_position.lerp(target_position, minf(1.0, delta * 14.0))
	else:
		global_position = target_position
		if target_facing.length_squared() > 0.001:
			rotation.y = lerp_angle(rotation.y, atan2(target_facing.x, target_facing.y), minf(1.0, delta * 10.0))


func apply_snapshot(snapshot: Dictionary, world_position: Vector3, snap := false) -> void:
	set_world_target(world_position, snap)
	target_facing = Vector2(snapshot.get("facing", Vector2.DOWN)).normalized()
	set_semantic_state(String(snapshot.get("state", Semantic.IDLE)))
	set_tool(String(snapshot.get("tool", "")))
	set_cargo(String(snapshot.get("cargo", "")), int(snapshot.get("cargo_amount", 0)))
	set_faction(String(snapshot.get("faction", "player")))
	set_selection_kind(String(snapshot.get("selection_kind", "worker")))
	set_damage_state(int(snapshot.get("hp", 1)), int(snapshot.get("max_hp", 1)))
	set_alert(bool(snapshot.get("alert", false)))
	visible = bool(snapshot.get("visible", true))
	set_selected(bool(snapshot.get("selected", false)))
	var model_scale := float(snapshot.get("model_scale", 1.0))
	if not is_equal_approx(model_scale, 1.0) and not is_equal_approx(scale.x, model_scale):
		scale = Vector3.ONE * model_scale


func set_world_target(next_position: Vector3, snap := false) -> void:
	target_position = next_position
	has_target = true
	if snap:
		global_position = next_position


func set_semantic_state(next_state: String) -> void:
	if next_state not in Semantic.ALL_STATES:
		next_state = Semantic.IDLE
	if semantic_state == next_state and playback != null and playback.is_playing():
		return
	semantic_state = next_state
	_refresh_animation_interval()
	if playback != null:
		playback.travel(next_state, true)


func set_tool(tool_key: String) -> void:
	if current_tool == tool_key:
		return
	current_tool = tool_key
	if equipped_tool != null:
		equipped_tool.queue_free()
		equipped_tool = null
	if tool_key == "" or not Catalog.TOOLS.has(tool_key) or right_hand_socket == null:
		return
	var packed := load(String(Catalog.TOOLS[tool_key])) as PackedScene
	if packed == null:
		return
	equipped_tool = packed.instantiate()
	equipped_tool.name = "SemanticTool_%s" % tool_key
	equipped_tool.scale = Vector3.ONE * ScaleProfile.TOOL_MODEL_SCALE
	right_hand_socket.add_child(equipped_tool)


func set_cargo(cargo_key: String, amount: int) -> void:
	if current_cargo == cargo_key and current_cargo_amount == amount:
		return
	current_cargo = cargo_key
	current_cargo_amount = amount
	if carried_prop != null:
		carried_prop.queue_free()
		carried_prop = null
	if cargo_label != null:
		cargo_label.queue_free()
		cargo_label = null
	if cargo_key == "" or amount <= 0 or not Catalog.CARGO.has(cargo_key) or right_hand_socket == null:
		return
	var packed := load(String(Catalog.CARGO[cargo_key])) as PackedScene
	if packed == null:
		return
	carried_prop = packed.instantiate()
	carried_prop.name = "AuthoritativeCargo_%s" % cargo_key
	carried_prop.scale = Vector3.ONE * ScaleProfile.CARGO_MODEL_SCALE
	carried_prop.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	right_hand_socket.add_child(carried_prop)
	cargo_label = Label3D.new()
	cargo_label.name = "CargoAmount"
	cargo_label.text = "%s x%d" % [cargo_key.capitalize(), amount]
	cargo_label.position = Vector3(0.0, 2.25, 0.0)
	cargo_label.font_size = 22
	cargo_label.outline_size = 5
	cargo_label.modulate = Color("#f2d18c")
	cargo_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	cargo_label.no_depth_test = true
	add_child(cargo_label)


func set_selected(value: bool) -> void:
	if selection_ring != null:
		selection_ring.visible = value


func set_presentation_paused(value: bool) -> void:
	presentation_paused = value
	# This tree advances manually. Deactivating it resets playback to Start on
	# resume, leaving the imported rest pose visible instead of an idle pose.


func set_animation_lod_enabled(value: bool) -> void:
	animation_lod_enabled = value


func retire(seconds := 1.15) -> void:
	has_target = false
	set_selected(false)
	set_semantic_state(Semantic.DIE)
	if selection_area != null:
		selection_area.collision_layer = 0
	var tween := create_tween()
	tween.tween_interval(maxf(0.25, seconds * 0.72))
	# A zero scale makes the skeleton/world transform singular before deletion.
	tween.tween_property(self, "scale", Vector3.ONE * 0.001, maxf(0.15, seconds * 0.28))
	tween.finished.connect(queue_free)


func set_selection_kind(kind: String) -> void:
	current_selection_kind = kind
	if selection_area != null:
		selection_area.set_meta("selection_kind", kind)


func set_faction(faction: String) -> void:
	if current_faction == faction and faction_marker != null:
		return
	current_faction = faction
	_refresh_animation_interval()
	if faction_marker == null:
		faction_marker = MeshInstance3D.new()
		faction_marker.name = "OwnershipBanner"
		var flag_mesh := BoxMesh.new()
		flag_mesh.size = Vector3(0.46, 0.24, 0.055)
		faction_marker.mesh = flag_mesh
		faction_marker.position = Vector3(0.0, 2.35, 0.0)
		add_child(faction_marker)
	var cloak := get_node_or_null("RivalShoulderCloth") as MeshInstance3D
	if cloak == null and faction == "rival":
		cloak = MeshInstance3D.new()
		cloak.name = "RivalShoulderCloth"
		var cloak_mesh := BoxMesh.new()
		cloak_mesh.size = Vector3(0.42, 0.55, 0.12)
		cloak.mesh = cloak_mesh
		cloak.position = Vector3(0.18, 1.35, -0.05)
		add_child(cloak)
	var color := Color(0.34, 0.65, 0.68, 0.88)
	match faction:
		"rival": color = Color(0.60, 0.20, 0.25, 0.92)
		"hostile": color = Color(0.83, 0.15, 0.10, 0.94)
		"player_military": color = Color(0.25, 0.58, 0.76, 0.90)
		"player": color = Color(0.28, 0.58, 0.50, 0.72)
	if faction == "hostile":
		var flag_mesh := faction_marker.mesh as BoxMesh
		flag_mesh.size = Vector3(0.72, 0.38, 0.08)
		faction_marker.position = Vector3(0.0, 2.55, 0.0)
	if faction == "rival":
		var flag_mesh := faction_marker.mesh as BoxMesh
		flag_mesh.size = Vector3(0.52, 0.32, 0.06)
		faction_marker.position = Vector3(0.22, 2.42, 0.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = faction == "hostile"
	material.emission = color.darkened(0.15)
	material.emission_energy_multiplier = 0.55
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	faction_marker.material_override = material
	faction_marker.visible = faction != "player"
	if cloak != null:
		cloak.visible = faction == "rival"
		cloak.material_override = material


func set_damage_state(hp: int, max_hp: int) -> void:
	if damage_marker == null:
		damage_marker = MeshInstance3D.new()
		damage_marker.name = "ContextDamageRing"
		var torus := TorusMesh.new()
		torus.inner_radius = 0.84
		torus.outer_radius = 0.91
		torus.rings = 28
		torus.ring_segments = 5
		damage_marker.mesh = torus
		damage_marker.position.y = 0.04
		add_child(damage_marker)
	var fraction := clampf(float(hp) / float(maxi(1, max_hp)), 0.0, 1.0)
	var material := StandardMaterial3D.new()
	if current_faction == "hostile":
		material.albedo_color = Color(0.82, 0.14, 0.10, 0.78).lerp(Color(0.96, 0.42, 0.16, 0.78), fraction)
	else:
		material.albedo_color = Color(0.95, 0.22, 0.12, 0.80).lerp(Color(0.96, 0.68, 0.18, 0.76), fraction)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	damage_marker.material_override = material
	damage_marker.visible = hp > 0 and (current_faction == "hostile" or hp < max_hp)


func set_alert(value: bool) -> void:
	if alert_light == null and value:
		alert_light = OmniLight3D.new()
		alert_light.name = "NightWatchLantern"
		alert_light.position = Vector3(0.45, 1.35, 0.20)
		alert_light.light_color = Color("#ffb55e")
		alert_light.light_energy = 0.55
		alert_light.omni_range = 3.2
		alert_light.shadow_enabled = false
		add_child(alert_light)
	if alert_light != null:
		alert_light.visible = value


func stable_entity_id() -> int:
	return entity_id


func _build_character() -> void:
	if character_model != null:
		character_model.queue_free()
	_ensure_shared_animation_resources()
	var packed := load(Catalog.character_path(worker_type)) as PackedScene
	if packed == null:
		push_error("Production character asset unavailable for %s" % worker_type)
		return
	character_model = packed.instantiate()
	_apply_settlement_materials(character_model)
	character_model.name = "CharacterModel"
	character_model.scale = Vector3.ONE * ScaleProfile.CHARACTER_MODEL_SCALE
	character_model.position.y = ScaleProfile.CHARACTER_GROUND_OFFSET
	add_child(character_model)
	skeleton = _find_skeleton(character_model)
	if skeleton == null:
		push_error("Rig_Medium skeleton missing for %s" % worker_type)
		return
	animation_player = AnimationPlayer.new()
	animation_player.name = "SemanticAnimationPlayer"
	animation_player.root_node = NodePath("..")
	character_model.add_child(animation_player)
	for library_name in _shared_libraries:
		animation_player.add_animation_library(StringName(library_name), _shared_libraries[library_name])
	animation_tree = AnimationTree.new()
	animation_tree.name = "SemanticAnimationTree"
	character_model.add_child(animation_tree)
	animation_tree.anim_player = animation_tree.get_path_to(animation_player)
	animation_tree.tree_root = _shared_state_machine
	animation_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	animation_tree.active = true
	playback = animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
	if playback != null:
		playback.start(semantic_state, true)
	_refresh_animation_interval()
	animation_elapsed = fmod(float(absi(entity_id)) * 0.0137, animation_update_interval)
	animation_tree.advance(0.0)
	_create_sockets()
	set_tool(current_tool)
	set_cargo(current_cargo, current_cargo_amount)


func _role_rim() -> Color:
	match worker_type:
		"guard", "ranger":
			return Color(0.48, 0.72, 0.94)
		"enemy_raider", "enemy_skitterer", "enemy_brute", "enemy_hexer":
			return Color(0.94, 0.32, 0.20)
		_:
			if current_faction == "hostile":
				return Color(0.94, 0.32, 0.20)
			if current_faction == "player_military":
				return Color(0.48, 0.72, 0.94)
			return Color(0.94, 0.84, 0.64)


func _apply_settlement_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		if instance.mesh == null:
			pass
		else:
			var rim := _role_rim()
			var rim_amount := 0.22 if current_faction == "hostile" or worker_type.begins_with("enemy") else 0.15
			for surface in instance.mesh.get_surface_count():
				var original := instance.get_active_material(surface) as StandardMaterial3D
				if original == null: continue
				var key := "%s:%s:%.2f" % [str(original.get_rid()), worker_type, rim_amount]
				if not _cloth_materials.has(key):
					var material := ShaderMaterial.new()
					material.shader = preload("res://src/GodotClient3D/Shaders/settlement_character.gdshader")
					material.set_shader_parameter("base_color", original.albedo_color)
					material.set_shader_parameter("has_texture", original.albedo_texture != null)
					material.set_shader_parameter("rim_color", Vector3(rim.r, rim.g, rim.b))
					material.set_shader_parameter("rim_amount", rim_amount)
					if original.albedo_texture != null:
						material.set_shader_parameter("palette_texture", original.albedo_texture)
					_cloth_materials[key] = material
				instance.set_surface_override_material(surface, _cloth_materials[key])
	for child in node.get_children():
		_apply_settlement_materials(child)



func _update_manual_animation(delta: float) -> void:
	if presentation_paused or not animation_lod_enabled or animation_tree == null or not animation_tree.active:
		return
	animation_elapsed += delta
	if animation_elapsed < animation_update_interval:
		return
	var advance_seconds := animation_elapsed
	animation_elapsed = fmod(animation_elapsed, animation_update_interval)
	animation_tree.advance(advance_seconds)


func _refresh_animation_interval() -> void:
	var updates_per_second := 12.0
	if current_faction == "hostile":
		updates_per_second = 24.0
	elif current_faction in ["rival", "player_military"]:
		updates_per_second = 20.0
	elif semantic_state in [Semantic.IDLE, Semantic.SLEEP]:
		updates_per_second = 6.0
	animation_update_interval = 1.0 / updates_per_second


func _create_selection() -> void:
	selection_ring = MeshInstance3D.new()
	selection_ring.name = "SelectionRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.72
	torus.outer_radius = 0.80
	torus.rings = 32
	torus.ring_segments = 6
	selection_ring.mesh = torus
	selection_ring.position.y = 0.035
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.98, 0.76, 0.25, 0.84)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	selection_ring.material_override = material
	selection_ring.visible = false
	add_child(selection_ring)
	selection_area = Area3D.new()
	selection_area.name = "SelectionArea"
	selection_area.collision_layer = 2
	selection_area.collision_mask = 0
	selection_area.set_meta("selection_kind", current_selection_kind)
	selection_area.set_meta("entity_id", entity_id)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.72
	capsule.height = 2.4
	collision.shape = capsule
	collision.position.y = 1.2
	selection_area.add_child(collision)
	add_child(selection_area)


func _create_sockets() -> void:
	var right_index := skeleton.find_bone("handslot.r")
	var left_index := skeleton.find_bone("handslot.l")
	if right_index >= 0:
		right_hand_socket = BoneAttachment3D.new()
		right_hand_socket.name = "RightHandSocket"
		right_hand_socket.bone_name = skeleton.get_bone_name(right_index)
		skeleton.add_child(right_hand_socket)
	if left_index >= 0:
		left_hand_socket = BoneAttachment3D.new()
		left_hand_socket.name = "LeftHandSocket"
		left_hand_socket.bone_name = skeleton.get_bone_name(left_index)
		skeleton.add_child(left_hand_socket)


static func _ensure_shared_animation_resources() -> void:
	if _libraries_ready:
		return
	for category in Catalog.ANIMATION_LIBRARIES:
		var packed := load(String(Catalog.ANIMATION_LIBRARIES[category])) as PackedScene
		if packed == null:
			continue
		var instance := packed.instantiate()
		var source_player := _find_animation_player_static(instance)
		if source_player != null:
			var library_names := source_player.get_animation_library_list()
			if not library_names.is_empty():
				var library := source_player.get_animation_library(library_names[0])
				_configure_looping(String(category), library)
				_shared_libraries[category] = library
		instance.free()
	_shared_state_machine = _build_state_machine()
	_libraries_ready = true


static func _configure_looping(category: String, library: AnimationLibrary) -> void:
	if library == null:
		return
	for animation_name in library.get_animation_list():
		var clip_name := String(animation_name)
		var should_loop := category in ["MovementBasic", "MovementAdvanced"] \
			or clip_name in ["Idle_A", "Idle_B", "Holding_A", "Holding_B", "Holding_C", "Working_A", "Working_B", "Working_C", "Chopping", "Digging", "Hammering", "Pickaxing", "Sawing", "Lie_Idle", "Melee_Unarmed_Idle", "Melee_2H_Idle", "Ranged_Bow_Aiming_Idle"]
		library.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR if should_loop else Animation.LOOP_NONE


static func _build_state_machine() -> AnimationNodeStateMachine:
	var machine := AnimationNodeStateMachine.new()
	var states: Array = Semantic.ALL_STATES
	for index in states.size():
		var state: String = states[index]
		var node := AnimationNodeAnimation.new()
		node.animation = StringName(CLIP_BY_STATE[state])
		var angle := TAU * float(index) / float(states.size())
		machine.add_node(StringName(state), node, Vector2(cos(angle), sin(angle)) * 360.0)
	for from_state in states:
		for to_state in states:
			if from_state == to_state:
				continue
			var transition := AnimationNodeStateMachineTransition.new()
			transition.xfade_time = 0.14
			machine.add_transition(StringName(from_state), StringName(to_state), transition)
	return machine


static func _find_animation_player_static(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_animation_player_static(child)
		if found != null:
			return found
	return null


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null
