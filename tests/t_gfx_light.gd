extends SceneTree

## GFX-1: lighting angle, preset interpolation, low-profile switches, halo tiles.

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Identity = preload("res://src/GodotClient3D/Scripts/production_identity.gd")
const HaloCatalog = preload("res://src/GodotClient3D/Scripts/production_building_halo.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const QualityProfile = preload("res://src/GodotClient3D/Scripts/production_quality_profile.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.start_new_3d(game.DEFAULT_SEED)
	game._hide_start_menu()
	for _i in 4:
		await process_frame
	var sim = game.simulation_host.simulation

	_check(Identity.LIGHTING.has("day") and Identity.LIGHTING.has("dusk") and Identity.LIGHTING.has("night"), "day, dusk and night presets exist")
	var day_p := Identity.lighting_palette("day")
	var dusk_p := Identity.lighting_palette("dusk")
	var night_p := Identity.lighting_palette("night")
	var mid := Identity.mix_lighting("day", "dusk", 0.5)
	_check(float(mid["sun_energy"]) > float(dusk_p["sun_energy"]) and float(mid["sun_energy"]) < float(day_p["sun_energy"]), "day/dusk interpolate sun energy")
	var dawn := Identity.mix_lighting("night", "day", 0.5)
	_check(float(dawn["sun_energy"]) > float(night_p["sun_energy"]) and float(dawn["sun_energy"]) < float(day_p["sun_energy"]), "night/day interpolate sun energy")
	_check(mid["sun_color"] is Color and not (mid["sun_color"] as Color).is_equal_approx(day_p["sun_color"]), "colour keys interpolate")

	sim.is_night = false
	sim.phase_time = 80.0
	game._update_day_night_lighting()
	var day_angle: float = game.sun_camera_angle_degrees()
	print("GFX day sun/camera angle=%.1f energy=%.2f" % [day_angle, game.sun_light.light_energy])
	_check(day_angle >= 90.0, "day sun is at least 90° from the camera view")

	sim.phase_time = float(sim.DAY_LENGTH_SECONDS) - 10.0
	game._update_day_night_lighting()
	var dusk_angle: float = game.sun_camera_angle_degrees()
	print("GFX dusk sun/camera angle=%.1f energy=%.2f" % [dusk_angle, game.sun_light.light_energy])
	_check(dusk_angle >= 90.0, "dusk sun is at least 90° from the camera view")
	_check(game.sun_light.light_energy < float(day_p["sun_energy"]) and game.sun_light.light_energy > float(night_p["sun_energy"]) - 0.05, "dusk sits between day and night energy")

	sim.is_night = true
	sim.phase_time = 20.0
	game._update_day_night_lighting()
	_check(absf(game.sun_light.light_energy - float(night_p["sun_energy"])) < 0.03, "night preset applies authored moon energy")
	_check(game.environment_resource.tonemap_mode == Environment.TONE_MAPPER_ACES, "tonemap stays ACES")

	game.apply_quality_profile("recommended")
	_check(game.environment_resource.ssil_enabled and game.environment_resource.glow_enabled, "recommended profile keeps SSIL and glow")
	game.apply_quality_profile("scalable_low")
	_check(not game.environment_resource.ssil_enabled, "low profile disables SSIL")
	_check(not game.environment_resource.glow_enabled, "low profile disables glow")
	_check(not game.environment_resource.volumetric_fog_enabled, "low profile disables volumetrics")
	game.apply_quality_profile("recommended")
	_check(bool(QualityProfile.get_profile("scalable_low").get("ssil", true)) == false, "low profile table turns SSIL off")

	var blocked := {}
	for road_tile in sim.connected_roads.keys():
		blocked[String(road_tile)] = true
	for building_value in sim.get_buildings():
		var building: Dictionary = building_value
		var type_name := String(building.get("type", ""))
		var anchor: Vector2i = building.get("position", Vector2i.ZERO)
		var footprint: Vector2i = Defs.building_footprint(type_name)
		for oy in footprint.y:
			for ox in footprint.x:
				blocked["%d,%d" % [anchor.x + ox, anchor.y + oy]] = true
	var live := HaloCatalog.resolve_world(sim)
	var overlap := 0
	for placement_value in live:
		var tile: Vector2i = Dictionary(placement_value).get("tile", Vector2i.ZERO)
		if blocked.has("%d,%d" % [tile.x, tile.y]):
			overlap += 1
	print("GFX halo placements=%d overlap=%d" % [live.size(), overlap])
	_check(overlap == 0, "halos never overlap footprints or road tiles")
	_check(HaloCatalog.authored_for("HOUSE").size() >= 4 and HaloCatalog.authored_for("HOUSE").size() <= 12, "house halo table has 4–12 authored slots")
	_check(HaloCatalog.authored_for("SAWMILL").size() >= 4, "sawmill halo table is authored")
	_check(HaloCatalog.authored_for("BAKERY").size() >= 4, "bakery halo table is authored")
	_check(HaloCatalog.authored_for("QUARRY").size() >= 4, "quarry halo table is authored")

	_finish(game)


func _finish(game: Node) -> void:
	game.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	print("T_GFX_LIGHT %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		failures.append(message)
