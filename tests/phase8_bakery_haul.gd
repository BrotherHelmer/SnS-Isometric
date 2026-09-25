extends SceneTree

const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")


func _init() -> void:
	var simulation: Simulation = Simulation.new(70, 70, 797979, false, true)
	var report: Array[String] = []
	var passed := simulation._record_bakery_farm_haul_smoke(report)
	if passed:
		print("PHASE8_BAKERY_HAUL PASS")
		quit(0)
		return
	for line in report:
		print(line)
	print("PHASE8_BAKERY_HAUL FAIL")
	quit(1)
