extends SceneTree
# Beta perf bench (dev only, not exported): time presentation capture pieces on a saved late game.
const Sim = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Adapter = preload("res://src/GodotClient3D/Scripts/production_presentation_adapter.gd")
func _init():
	var path := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--save="): path = a.trim_prefix("--save=")
	var sim = Sim.new()
	print("load ", sim.load_from_path(path), " bld=", sim.buildings.size(), " workers=", sim.workers.size())
	var ad = Adapter.new()
	var N := 30
	var t := Time.get_ticks_usec()
	for i in N: ad.capture_frame(sim, 0.0)
	print("capture_frame us ", (Time.get_ticks_usec()-t)/N)
	t = Time.get_ticks_usec()
	for i in N:
		for b in sim.buildings: ad.building_descriptor(b, sim, false)
	print("building_descriptors us ", (Time.get_ticks_usec()-t)/N)
	t = Time.get_ticks_usec()
	for i in N:
		for b in sim.buildings: sim.diagnose_building_dict(b)
	print("diagnose us ", (Time.get_ticks_usec()-t)/N)
	t = Time.get_ticks_usec()
	for i in N:
		for w in sim.workers: ad.worker_descriptor(w, sim, 0.0)
	print("workers us ", (Time.get_ticks_usec()-t)/N)
	t = Time.get_ticks_usec()
	for i in N:
		for b in sim.buildings: sim.get_building_center(b); ad._sheltered_occupants(b, sim)
	print("center+sheltered us ", (Time.get_ticks_usec()-t)/N)
	t = Time.get_ticks_usec()
	for i in N:
		for b in sim.buildings: ad._settlement_lights_on(sim)
	print("lights_on us ", (Time.get_ticks_usec()-t)/N)
	t = Time.get_ticks_usec()
	for i in N: sim._simulate_seconds_for_test(0.1)
	print("sim tick us ", (Time.get_ticks_usec()-t)/N)
	var probes := {
		"settlement": func(): ad.settlement_descriptor(sim),
		"projectiles": func(): ad.projectile_descriptors(sim),
		"decor": func(): for p in sim.get_decorative_props(): Dictionary(p).duplicate(true),
		"wyrdfall": func(): sim.get_wyrdfall_presentation(),
		"markers": func(): sim.get_map_markers(),
		"wyrd_sites": func(): ad._wyrd_site_snapshots(sim),
		"rival_home": func(): ad._rival_home_descriptor(sim),
		"resources": func(): sim.get_resources(); sim.get_reserved_resources(),
		"time_label": func(): sim.get_time_label(),
		"objective": func(): sim.get_macro_objective(),
		"forecast": func(): sim.get_night_forecast(),
		"wyrd_pressure": func(): sim.get_wyrd_pressure(),
		"claim_label": func(): sim.get_claim_label(),
		"hungry": func(): sim.get_hungry_population(); sim.get_food_units(); sim.get_next_food_demand(),
		"shelter": func(): sim.get_sheltered_worker_count(); sim.get_shelterable_worker_count(),
		"has_barracks": func(): ad._settlement_has_barracks(sim),
	}
	for k in probes:
		t = Time.get_ticks_usec()
		for i in N: probes[k].call()
		print(k, " us ", (Time.get_ticks_usec()-t)/N)
	quit()
