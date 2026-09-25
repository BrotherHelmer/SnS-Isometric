extends SceneTree

const Catalog = preload("res://src/GodotClient3D/Scripts/production_asset_catalog.gd")


func _init() -> void:
	var failures: Array[String] = []
	var report := Catalog.integrity_report()
	_check(failures, bool(report.get("success", false)), "semantic catalog resolves every promoted runtime asset")
	_check(failures, int(report.get("path_count", 0)) >= 40, "semantic catalog covers the production asset surface")
	var raw_references := _find_raw_vendor_references("res://src")
	_check(failures, raw_references.is_empty(), "gameplay/controller code has no raw vendor asset references")
	if not raw_references.is_empty():
		for item in raw_references:
			print("RAW_REFERENCE %s" % item)
	_finish(failures, "PHASE2_CATALOG_INTEGRITY")


func _find_raw_vendor_references(root_path: String) -> Array[String]:
	var findings: Array[String] = []
	_scan_directory(root_path, findings)
	return findings


func _scan_directory(path: String, findings: Array[String]) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = directory.get_next()
			continue
		var child := path.path_join(entry)
		if directory.current_is_dir():
			_scan_directory(child, findings)
		elif entry.ends_with(".gd"):
			var file := FileAccess.open(child, FileAccess.READ)
			if file != null:
				var text := file.get_as_text()
				var forbidden_root := "res://assets/" + "Kay" + "kit/"
				var forbidden_root_case := "res://assets/" + "Kay" + "Kit/"
				if forbidden_root in text or forbidden_root_case in text:
					findings.append(child)
		entry = directory.get_next()
	directory.list_dir_end()


func _check(failures: Array[String], condition: bool, label: String) -> void:
	print("%s %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		failures.append(label)


func _finish(failures: Array[String], suite: String) -> void:
	if failures.is_empty():
		print("%s PASS" % suite)
		quit(0)
	else:
		print("%s FAIL count=%d" % [suite, failures.size()])
		quit(1)
