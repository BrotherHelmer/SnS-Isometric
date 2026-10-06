extends SceneTree

## Headless-safe Access-1 benchmark: writes a CSV even when GPU timers are zero.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const AccessBenchmark = preload("res://src/GodotClient3D/Scripts/production_benchmark.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	OS.set_environment("SNS_BENCHMARK_FRAMES", "2")
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var runner := AccessBenchmark.new()
	var path: String = await runner.run(game, false, 1, 2)
	_check(path != "" and FileAccess.file_exists(path), "benchmark writes user://benchmark CSV")
	if path != "":
		var text := FileAccess.get_file_as_string(path)
		_check(text.contains("preset,period,frames,wall_avg_ms"), "CSV has the wall-clock header")
		_check(text.contains("process_avg_ms"), "CSV still records TIME_PROCESS for continuity")
		_check(text.contains("gpu_avg_ms"), "CSV records GPU measure columns")
		_check(text.contains("low,day,") and text.contains("medium,dusk,") and text.contains("high,night,"), "CSV samples Low/Medium/High across day/dusk/night")
		print("ACCESS_BENCHMARK_TEST csv=\n%s" % text)
	game.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	print("T_ACCESS_BENCHMARK %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
