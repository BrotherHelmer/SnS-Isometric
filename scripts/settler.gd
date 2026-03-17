## Settler — an autonomous NPC that gathers resources for the colony.
## Does NOT take direct orders from the player.
## Behaviour is driven entirely by its child StateMachine.
extends BaseUnit

@export var carry_capacity: int = 5

var carried_resource_type: String = ""
var carried_amount: int = 0
var home_hut: Node2D = null
var target_resource: Node2D = null

@onready var state_machine: StateMachine = $StateMachine


var _fog_check_interval: float = 0.25
var _fog_check_timer: float = 0.0


func _ready() -> void:
	super._ready()
	add_to_group("settlers")


func _physics_process(delta: float) -> void:
	_fog_check_timer += delta
	if _fog_check_timer < _fog_check_interval:
		return
	_fog_check_timer = 0.0
	_check_fog()


func _check_fog() -> void:
	var fog_mgr := get_tree().current_scene.get_node_or_null("FogManager")
	if fog_mgr == null:
		return

	var vp: SubViewport = fog_mgr.get_node_or_null("SubViewport")
	if vp == null:
		return

	var vp_texture := vp.get_texture()
	if vp_texture == null:
		return
	var image := vp_texture.get_image()
	if image == null:
		return

	var canvas_xform := get_viewport().get_canvas_transform()
	var screen_pos: Vector2 = canvas_xform * global_position
	var px := clampi(int(screen_pos.x), 0, image.get_width() - 1)
	var py := clampi(int(screen_pos.y), 0, image.get_height() - 1)
	var fog_value := image.get_pixel(px, py).r

	if fog_value > 0.7 and not is_in_fog:
		is_in_fog = true
		state_machine.transition_to("PanicState")
	elif fog_value <= 0.3:
		is_in_fog = false


## Called by WorkingState when the settler harvests one tick.
func add_to_inventory(type: String, amount: int) -> void:
	carried_resource_type = type
	carried_amount += amount
	if carried_amount >= carry_capacity:
		state_machine.transition_to("ReturningState")


## Called by ReturningState when the settler reaches the stockpile.
func deposit_inventory() -> void:
	if carried_amount > 0:
		Global.add_resource(carried_resource_type, carried_amount)
		carried_amount = 0
		carried_resource_type = ""
	state_machine.transition_to("IdleState")
