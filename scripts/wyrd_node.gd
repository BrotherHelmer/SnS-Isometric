## WyrdNode — a harvestable crystal that spawns inside the Crater.
## Only the Sovereign can extract Wyrd from these.
extends StaticBody2D

signal wyrd_extracted(amount: int)
signal node_depleted

@export var wyrd_amount: int = 10
@export var extract_rate: float = 2.0
@export var wyrd_per_tick: int = 1

var is_depleted: bool = false
var _extracting: bool = false
var _timer: float = 0.0


func _ready() -> void:
	add_to_group("wyrd_nodes")


func _process(delta: float) -> void:
	if not _extracting or is_depleted:
		return

	_timer += delta
	if _timer >= extract_rate:
		_timer -= extract_rate
		_harvest_tick()


func start_extraction() -> void:
	if is_depleted:
		return
	_extracting = true
	_timer = 0.0


func stop_extraction() -> void:
	_extracting = false
	_timer = 0.0


func _harvest_tick() -> void:
	var amount := mini(wyrd_per_tick, wyrd_amount)
	wyrd_amount -= amount
	Global.add_resource("wyrd", amount)
	wyrd_extracted.emit(amount)

	if wyrd_amount <= 0:
		is_depleted = true
		_extracting = false
		node_depleted.emit()
		# Visual feedback — fade out (placeholder).
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.3, 0.6)
