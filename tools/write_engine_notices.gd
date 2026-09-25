extends SceneTree

func _init() -> void:
	var file := FileAccess.open("res://artifacts/release_candidate/GODOT_COPYRIGHT.txt", FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_string("Godot Engine " + Engine.get_version_info().string + "\nhttps://godotengine.org/license/\n\n")
	file.store_string(Engine.get_license_text())
	file.store_string("\n\nBundled third-party components\n\n")
	file.store_string(JSON.stringify(Engine.get_copyright_info(), "\t"))
	file.store_string("\n\nLicense texts\n\n")
	for name in Engine.get_license_info():
		file.store_string(name + "\n" + Engine.get_license_info()[name] + "\n\n")
	file.close()
	print("ENGINE_NOTICES PASS")
	quit()
