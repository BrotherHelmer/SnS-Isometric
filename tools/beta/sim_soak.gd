extends SceneTree
# Headless sim + demo bot soak: prints any 3 s chunk slower than 150 ms.
const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Player = preload("res://src/GodotClient3D/Scripts/production_demo_player.gd")
func _init() -> void:
	var seed_value := 1792050449
	var secs := 1150.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="): seed_value = int(a.trim_prefix("--seed="))
		if a.begins_with("--secs="): secs = float(a.trim_prefix("--secs="))
	var sim = Simulation.new(Simulation.MAP_WIDTH, Simulation.MAP_HEIGHT, seed_value, true, true)
	var player = Player.new()
	var t := 0.0
	var worst := 0
	var think_t := 0.0
	var slow := 0
	while t < secs:
		var t0 := Time.get_ticks_msec()
		think_t += 0.2
		if think_t >= 3.0 or player.think_phase > 0:
			if player.think_phase == 0:
				think_t = 0.0
			player.think_step(sim)
		sim._simulate_seconds_for_test(0.2)
		var ms := Time.get_ticks_msec() - t0
		worst = maxi(worst, ms)
		if ms > 100:
			slow += 1
			if slow < 400:
				print("SLOW t=%.1f ms=%d night=%s" % [float(sim.elapsed_seconds), ms, str(sim.is_night)])
		t += 0.2
	print("SOAK done seed=%d t=%.0f worst=%d slow=%d buildings=%d" % [seed_value, float(sim.elapsed_seconds), worst, slow, sim.buildings.size()])
	quit()
