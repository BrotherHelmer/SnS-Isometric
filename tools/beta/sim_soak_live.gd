extends SceneTree
# Headless soak that steps like the live gate: 1/60 s frames, one think phase
# per frame, think cycle every 3 s. Prints buildings + bot failures every 100 s.
const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Player = preload("res://src/GodotClient3D/Scripts/production_demo_player.gd")
func _init() -> void:
	var seed_value := 4242
	var secs := 1300.0
	var dt := 1.0 / 60.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="): seed_value = int(a.trim_prefix("--seed="))
		if a.begins_with("--secs="): secs = float(a.trim_prefix("--secs="))
		if a.begins_with("--dt="): dt = float(a.trim_prefix("--dt="))
	var sim = Simulation.new(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, seed_value, true, true)
	var player = Player.new()
	var t := 0.0
	var think_t := 0.0
	var next_report := 100.0
	while t < secs:
		think_t += dt
		if think_t >= 3.0 or player.think_phase > 0:
			if player.think_phase == 0:
				think_t = 0.0
			player.think_step(sim)
		sim._simulate_seconds_for_test(dt)
		t += dt
		if t >= next_report:
			next_report += 100.0
			print("LIVE t=%.0f buildings=%d stock=%s fails=%s idle=%s" % [t, sim.buildings.size(), str(sim.stockpile) if "stockpile" in sim else "?", str(player.last_failures), player.last_idle_reason])
	print("LIVE done seed=%d buildings=%d" % [seed_value, sim.buildings.size()])
	quit()
