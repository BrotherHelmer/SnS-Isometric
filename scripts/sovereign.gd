## Sovereign — the player-controlled hero.
## Moves via WASD (isometric) or click-to-move. Carries the Lumen light.
## Can extract Wyrd from crystal nodes in the Crater.
extends BaseUnit

@export var lumen_radius: float = 128.0

## Extraction state
var is_extracting: bool = false
var _active_wyrd_node: Node = null

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var lumen_light: PointLight2D = $LumenLight
@onready var camera: Camera2D = $Camera2D

var _click_target: Vector2 = Vector2.ZERO
var _using_click_move: bool = false


func _ready() -> void:
	super._ready()
	add_to_group("lumen_sources")
	move_speed = 120.0


func _unhandled_input(event: InputEvent) -> void:
	if is_extracting:
		if event.is_action_released("interact"):
			_stop_extracting()
		return

	if event.is_action_pressed("click"):
		_click_target = get_global_mouse_position()
		nav_agent.target_position = _click_target
		_using_click_move = true

	if event.is_action_pressed("interact"):
		_try_start_extracting()


func _physics_process(delta: float) -> void:
	if is_extracting:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_dir := _get_wasd_input()

	if input_dir != Vector2.ZERO:
		_using_click_move = false
		velocity = input_dir * move_speed
	elif _using_click_move and not nav_agent.is_navigation_finished():
		var next_pos := nav_agent.get_next_path_position()
		var direction := (next_pos - global_position).normalized()
		velocity = direction * move_speed
	else:
		_using_click_move = false
		velocity = Vector2.ZERO

	move_and_slide()


## Convert WASD to isometric world direction.
func _get_wasd_input() -> Vector2:
	var raw := Vector2.ZERO
	raw.x = Input.get_axis("move_left", "move_right")
	raw.y = Input.get_axis("move_up", "move_down")
	if raw == Vector2.ZERO:
		return Vector2.ZERO
	# Cartesian -> Isometric transform
	var iso := Vector2(raw.x - raw.y, (raw.x + raw.y) / 2.0)
	return iso.normalized()


# --- Wyrd Extraction -------------------------------------------------------

func _try_start_extracting() -> void:
	var overlapping := _get_nearby_wyrd_nodes()
	if overlapping.is_empty():
		return
	_active_wyrd_node = overlapping[0]
	if _active_wyrd_node.has_method("start_extraction"):
		is_extracting = true
		_active_wyrd_node.start_extraction()


func _stop_extracting() -> void:
	if _active_wyrd_node and _active_wyrd_node.has_method("stop_extraction"):
		_active_wyrd_node.stop_extraction()
	_active_wyrd_node = null
	is_extracting = false


func _get_nearby_wyrd_nodes() -> Array:
	var nodes: Array = []
	for node in get_tree().get_nodes_in_group("wyrd_nodes"):
		var zone: Area2D = node.get_node_or_null("InteractionZone")
		if zone and zone.get_overlapping_bodies().has(self):
			nodes.append(node)
	return nodes


## Override: getting hit interrupts extraction.
func take_damage(amount: float) -> void:
	if is_extracting:
		_stop_extracting()
	super.take_damage(amount)
