extends SceneTree

func _init() -> void:
	var scripts := [
		"res://src/GodotClient3D/Scripts/production_identity.gd",
		"res://src/GodotClient3D/Scripts/production_audio_director.gd",
		"res://src/GodotClient3D/Scripts/wyrd_pressure_meter.gd",
		"res://src/GodotClient3D/Scripts/production_3d_game_root.gd",
		"res://src/GodotClient3D/Scripts/production_world_view_3d.gd",
		"res://src/GodotClient3D/Scripts/production_building_view_3d.gd",
		"res://src/GodotClient3D/Scripts/production_character_view_3d.gd",
		"res://src/GodotClient3D/Scripts/production_presentation_adapter.gd",
		"res://src/GodotClient3D/Scripts/production_demo_fixture.gd"
	]
	for path in scripts:
		var loaded = load(path)
		if loaded == null:
			push_error("PHASE41_PARSE FAIL %s" % path)
			quit(1)
			return
	print("PHASE41_PARSE PASS")
	quit(0)
