## Sovereign — the player-controlled hero.
## Moves via WASD (isometric) or click-to-move. Carries the Lumen light.
## Can extract Wyrd from crystal nodes in the Crater.
## 8-directional facing via AnimatedSprite2D with walk-bob animation.
extends BaseUnit

@export var lumen_radius: float = 128.0

## Extraction state
var is_extracting: bool = false
var _active_wyrd_node: Node = null

## Walk bob state
var _bob_timer: float = 0.0
const _BASE_SPRITE_OFFSET := Vector2(0, -24)
const _BOB_SPEED := 14.0
const _BOB_AMPLITUDE := 1.5

## LumenOrigin base X offset (before flip_h mirroring)
var _lumen_origin_base_x: float = 8.0

## Last facing direction (persists when stopping)
var _last_anim: String = "idle_se"
var _last_flip: bool = false

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var lumen_light: PointLight2D = $LumenLight
@onready var camera: Camera2D = $Camera2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var lumen_origin: Marker2D = $LumenOrigin


func _ready() -> void:
	super._ready()
	add_to_group("lumen_sources")
	camera.make_current()
	move_speed = 120.0
	_lumen_origin_base_x = abs(lumen_origin.position.x)


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
	_update_facing()
	_update_walk_bob(delta)


## Convert WASD to isometric world direction.
func _get_wasd_input() -> Vector2:
	var raw := Vector2.ZERO
	raw.x = Input.get_axis("move_left", "move_right")
	raw.y = Input.get_axis("move_up", "move_down")
	if raw == Vector2.ZERO:
		return Vector2.ZERO
	var iso := Vector2(raw.x - raw.y, (raw.x + raw.y) / 2.0)
	return iso.normalized()


## Map velocity angle to one of 8 compass directions -> animation + flip_h.
func _update_facing() -> void:
	if velocity.length() < 0.1:
		sprite.animation = _last_anim
		sprite.flip_h = _last_flip
		return

	var angle := velocity.angle()
	var anim_name: String
	var flip: bool = false

	# 8 sectors of PI/4 each, centered on cardinal/diagonal angles
	if angle >= -PI / 8.0 and angle < PI / 8.0:
		anim_name = "idle_e"
	elif angle >= PI / 8.0 and angle < 3.0 * PI / 8.0:
		anim_name = "idle_se"
	elif angle >= 3.0 * PI / 8.0 and angle < 5.0 * PI / 8.0:
		anim_name = "idle_s"
	elif angle >= 5.0 * PI / 8.0 and angle < 7.0 * PI / 8.0:
		anim_name = "idle_se"
		flip = true
	elif angle >= 7.0 * PI / 8.0 or angle < -7.0 * PI / 8.0:
		anim_name = "idle_e"
		flip = true
	elif angle >= -7.0 * PI / 8.0 and angle < -5.0 * PI / 8.0:
		anim_name = "idle_ne"
		flip = true
	elif angle >= -5.0 * PI / 8.0 and angle < -3.0 * PI / 8.0:
		anim_name = "idle_n"
	else:
		anim_name = "idle_ne"

	sprite.animation = anim_name
	sprite.flip_h = flip
	_last_anim = anim_name
	_last_flip = flip

	# Mirror the LumenOrigin marker when sprite is flipped
	lumen_origin.position.x = _lumen_origin_base_x * (-1.0 if flip else 1.0)


## Grounded walk bob — only dips DOWN from base, never floats above.
## Uses abs(sin()) so the sprite stomps toward the feet on each step.
func _update_walk_bob(delta: float) -> void:
	if velocity.length() > 0.1:
		_bob_timer += delta * _BOB_SPEED
		var stomp: float = absf(sin(_bob_timer)) * _BOB_AMPLITUDE
		sprite.offset = _BASE_SPRITE_OFFSET + Vector2(0, stomp)
	else:
		_bob_timer = 0.0
		sprite.offset = _BASE_SPRITE_OFFSET


## Returns the world position of the staff crystal for fog clearing.
func get_lumen_position() -> Vector2:
	return lumen_origin.global_position


# --- Wyrd Extraction -------------------------------------------------------

var _click_target: Vector2 = Vector2.ZERO
var _using_click_move: bool = false

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
