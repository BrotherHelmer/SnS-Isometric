class_name ProductionIsometricCameraRig3D
extends Node3D

const ScaleProfile = preload("res://src/GodotClient3D/Scripts/production_scale_profile.gd")

const CLOSE_ZOOM := 18.0
const NORMAL_ZOOM := 38.0
const STRATEGIC_ZOOM := 68.0
const PREFERRED_YAW := -0.62

var camera: Camera3D
var target_position := Vector3.ZERO
var target_zoom := NORMAL_ZOOM
var pan_bounds := Rect2(-34.0, -34.0, 68.0, 68.0)
var dragging := false
var pan_drag_kind := "middle_drag"
var input_enabled := true
var pan_generation := 0
var last_pan_source := ""


func _ready() -> void:
	camera = Camera3D.new()
	camera.name = "IsometricCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = NORMAL_ZOOM
	camera.position = Vector3(0.0, 38.0, 38.0)
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	rotation.y = PREFERRED_YAW
	position = target_position


func _process(delta: float) -> void:
	if input_enabled:
		# Strategy camera input is independent of settlement-level commands.
		var input_vector := Vector2(
			float(Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)),
			float(Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W))
		)
		if input_vector != Vector2.ZERO:
			_pan(input_vector.normalized() * delta * target_zoom * 0.42, false, "keyboard")
	position = position.lerp(target_position, minf(1.0, delta * 9.0))
	camera.size = lerpf(camera.size, target_zoom, minf(1.0, delta * 10.0))


# Camera input must arrive before Control nodes consume it. The Phase 3 HUD
# covered most of the viewport and made _unhandled_input unreliable in the
# packaged build, especially for middle-button presses begun over a panel.
func _input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			target_zoom = clampf(target_zoom - 3.5, CLOSE_ZOOM, STRATEGIC_ZOOM)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			target_zoom = clampf(target_zoom + 3.5, CLOSE_ZOOM, STRATEGIC_ZOOM)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
			if event.pressed:
				pan_drag_kind = "middle_drag"
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and dragging:
		_pan(Vector2(-event.relative.x, -event.relative.y) * target_zoom * 0.0014, true, pan_drag_kind)
		get_viewport().set_input_as_handled()


func configure_for_map(map_size: Vector2i) -> void:
	var extent_x := maxf(5.0, float(map_size.x - 1) * ScaleProfile.LOGICAL_CELL_METRES * 0.5)
	var extent_z := maxf(5.0, float(map_size.y - 1) * ScaleProfile.LOGICAL_CELL_METRES * 0.5)
	configure_pan_bounds(Rect2(-extent_x, -extent_z, extent_x * 2.0, extent_z * 2.0))


func configure_pan_bounds(bounds: Rect2) -> void:
	if bounds.size.x < 4.0 or bounds.size.y < 4.0:
		return
	pan_bounds = bounds
	_clamp_target()
	position.x = clampf(position.x, pan_bounds.position.x, pan_bounds.end.x)
	position.z = clampf(position.z, pan_bounds.position.y, pan_bounds.end.y)


func focus_world(world_position: Vector3) -> void:
	target_position = Vector3(world_position.x, 0.0, world_position.z)
	_clamp_target()


func set_zoom_preset(preset: String) -> void:
	match preset.to_lower():
		"close": target_zoom = CLOSE_ZOOM
		"strategic": target_zoom = STRATEGIC_ZOOM
		_: target_zoom = NORMAL_ZOOM
	if camera != null:
		camera.size = target_zoom


func pan_from_mouse(relative: Vector2) -> void:
	_pan(Vector2(-relative.x, -relative.y) * target_zoom * 0.0014, true, "pointer_drag")


func pan_from_axes(amount: Vector2, source := "script") -> void:
	if amount == Vector2.ZERO:
		return
	_pan(amount, false, source)


func begin_pointer_pan() -> void:
	dragging = true
	pan_drag_kind = "pointer_drag"


func end_pointer_pan() -> void:
	dragging = false


func view_direction() -> Vector3:
	if camera == null:
		return Vector3(sin(rotation.y), -0.707, -cos(rotation.y)).normalized()
	return -camera.global_transform.basis.z.normalized()


func compose_view(world_position: Vector3, orthographic_size: float) -> void:
	target_position = Vector3(world_position.x, 0.0, world_position.z)
	target_zoom = clampf(orthographic_size, CLOSE_ZOOM, STRATEGIC_ZOOM)
	_clamp_target()
	position = target_position
	if camera != null:
		camera.size = target_zoom


func _pan(amount: Vector2, immediate := false, source := "script") -> void:
	var yaw := rotation.y
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	var forward := Vector3(sin(yaw), 0.0, cos(yaw))
	target_position += right * amount.x + forward * amount.y
	_clamp_target()
	if immediate:
		position = target_position
	pan_generation += 1
	last_pan_source = source


func _clamp_target() -> void:
	target_position.x = clampf(target_position.x, pan_bounds.position.x, pan_bounds.end.x)
	target_position.z = clampf(target_position.z, pan_bounds.position.y, pan_bounds.end.y)
