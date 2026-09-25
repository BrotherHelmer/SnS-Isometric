extends SceneTree

func _init() -> void:
	var scripts := [
		"res://src/GodotClient/Scripts/one_shard_defs.gd",
		"res://src/GodotClient/Scripts/one_shard_wyrdfall.gd",
		"res://src/GodotClient/Scripts/one_shard_simulation.gd",
		"res://src/GodotClient3D/Scripts/production_identity.gd",
		"res://src/GodotClient3D/Scripts/production_audio_director.gd",
		"res://src/GodotClient3D/Scripts/production_3d_game_root.gd",
		"res://src/GodotClient3D/Scripts/production_world_view_3d.gd",
		"res://src/GodotClient3D/Scripts/production_building_view_3d.gd",
		"res://src/GodotClient3D/Scripts/production_character_view_3d.gd",
		"res://src/GodotClient3D/Scripts/production_presentation_adapter.gd",
		"res://src/GodotClient3D/Scripts/production_minimap.gd"
	]
	for path in scripts:
		var loaded = load(path)
		if loaded == null or not (loaded is Script) or not (loaded as Script).can_instantiate():
			push_error("PHASE42_PARSE FAIL %s" % path)
			quit(1)
			return
	print("PHASE42_PARSE PASS")
	quit(0)
