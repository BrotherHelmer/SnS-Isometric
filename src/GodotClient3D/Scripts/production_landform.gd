extends RefCounted

## Visual Reset S1 greybox: seeded LandformGraph. Presentation only.
## The simulation (tiles, heights, water, pathing, placement) is untouched;
## this adds a render relief (metres) per tile on top of the sim height:
## hills/massifs, a Wyrd impact crater (bowl + rim + ejecta), a creek valley
## that descends monotonically along the sim water tiles, a settlement
## plateau around each seat, and a graded trail from the hall to the crater.

const PLATEAU_INNER := 9.0
const PLATEAU_OUTER := 22.0
const EDGE_FADE := 14.0

var size := Vector2i.ZERO
var relief := PackedFloat32Array()   # metres, per tile
var water_level := PackedFloat32Array()  # metres (relief space) for water tiles, else NAN
var crater_center := Vector2.ZERO    # tiles
var crater_rim_tiles := 0.0
var trail: PackedVector2Array = PackedVector2Array()  # tiles, hall -> crater
var build_ms := 0.0


func sample_tiles(p: Vector2) -> float:
	if size == Vector2i.ZERO:
		return 0.0
	var x := clampf(p.x, 0.0, float(size.x - 1))
	var y := clampf(p.y, 0.0, float(size.y - 1))
	var x0 := int(floor(x))
	var y0 := int(floor(y))
	var x1 := mini(x0 + 1, size.x - 1)
	var y1 := mini(y0 + 1, size.y - 1)
	var fx := x - float(x0)
	var fy := y - float(y0)
	var a := relief[y0 * size.x + x0]
	var b := relief[y0 * size.x + x1]
	var c := relief[y1 * size.x + x0]
	var d := relief[y1 * size.x + x1]
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fy)


func at_tile(t: Vector2i) -> float:
	var x := clampi(t.x, 0, size.x - 1)
	var y := clampi(t.y, 0, size.y - 1)
	return relief[y * size.x + x]


func build(sim, seed_value: int) -> void:
	var started := Time.get_ticks_usec()
	size = sim.map_size
	var n := size.x * size.y
	relief.resize(n)
	var hills := FastNoiseLite.new()
	hills.seed = seed_value * 7 + 11
	hills.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	hills.frequency = 1.0 / 95.0
	hills.fractal_type = FastNoiseLite.FRACTAL_FBM
	hills.fractal_octaves = 4
	hills.domain_warp_enabled = true
	hills.domain_warp_amplitude = 28.0
	hills.domain_warp_frequency = 1.0 / 140.0
	var ridges := FastNoiseLite.new()
	ridges.seed = seed_value * 13 + 5
	ridges.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	ridges.frequency = 1.0 / 70.0
	ridges.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	ridges.fractal_octaves = 3
	var detail := FastNoiseLite.new()
	detail.seed = seed_value * 3 + 1
	detail.frequency = 1.0 / 18.0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 31 + 17

	var hall := Vector2(sim.town_hall_position) + Vector2(2.0, 2.0)
	var seats: Array = [hall]
	for seat_value in sim.rival_seats:
		seats.append(Vector2(Vector2i(seat_value)) + Vector2(2.0, 2.0))
	crater_center = Vector2(sim.shard_position)
	var pit := maxf(float(sim.crater_pit_radius), 10.0)
	crater_rim_tiles = pit

	# Two or three massifs, seeded, kept away from the seats and the crater.
	var massifs: Array = []
	for i in 8:
		if massifs.size() >= 3:
			break
		var p := Vector2(rng.randf_range(30.0, float(size.x) - 30.0), rng.randf_range(30.0, float(size.y) - 30.0))
		var ok := p.distance_to(crater_center) > pit + 40.0
		for s in seats:
			if p.distance_to(Vector2(s)) < 55.0:
				ok = false
		if ok:
			massifs.append([p, rng.randf_range(26.0, 42.0), rng.randf_range(10.0, 18.0)])

	for y in size.y:
		for x in size.x:
			var p := Vector2(x, y)
			var h := hills.get_noise_2d(x, y) * 7.5
			var r := ridges.get_noise_2d(x, y) * 0.5 + 0.5
			h += pow(r, 2.2) * 7.0
			for m in massifs:
				var mp: Vector2 = m[0]
				var rad: float = m[1]
				h += float(m[2]) * exp(-p.distance_squared_to(mp) / (rad * rad))
			h += detail.get_noise_2d(x, y) * 0.6
			# Wyrd impact: bowl, raised irregular rim, ejecta apron.
			var dc := p.distance_to(crater_center)
			var ang := atan2(p.y - crater_center.y, p.x - crater_center.x)
			var jag := pit * (1.0 + 0.07 * sin(ang * 5.0 + float(seed_value % 17)) + 0.04 * sin(ang * 11.0))
			if dc < jag:
				var t := dc / jag
				h = lerpf(h * 0.25, h, smoothstep(0.75, 1.0, t)) - 13.0 * (1.0 - t * t)
			var rim := exp(-pow((dc - jag) / 5.5, 2.0)) * 5.5
			var ejecta := exp(-maxf(dc - jag, 0.0) / 22.0) * 2.0 * (1.0 if dc >= jag else 0.0)
			h += rim + ejecta * (0.6 + 0.4 * detail.get_noise_2d(x * 2.0, y * 2.0))
			relief[y * size.x + x] = h

	# Settlement plateaus: flat ground under every seat.
	for s in seats:
		var c := Vector2(s)
		var level := _avg_around(c, 4)
		var reach := int(PLATEAU_OUTER) + 1
		for y in range(maxi(0, int(c.y) - reach), mini(size.y, int(c.y) + reach + 1)):
			for x in range(maxi(0, int(c.x) - reach), mini(size.x, int(c.x) + reach + 1)):
				var d := Vector2(x, y).distance_to(c)
				var w := 1.0 - smoothstep(PLATEAU_INNER, PLATEAU_OUTER, d)
				var i := y * size.x + x
				relief[i] = lerpf(relief[i], level, w)

	_carve_creek(sim)
	_grade_trail(sim, hall)

	# Inland uplift keeps the crater floor and valleys above the sea plane;
	# the map edge fades back to the old shoreline level.
	var lo := INF
	for v in relief:
		lo = minf(lo, v)
	var lift := maxf(0.0, 1.2 - lo)
	for y in size.y:
		for x in size.x:
			var e := float(mini(mini(x, y), mini(size.x - 1 - x, size.y - 1 - y)))
			var i := y * size.x + x
			relief[i] += lift
			if e < EDGE_FADE:
				relief[i] *= smoothstep(0.0, EDGE_FADE, e)
			if not is_nan(water_level[i]):
				water_level[i] += lift * (smoothstep(0.0, EDGE_FADE, e) if e < EDGE_FADE else 1.0)
	build_ms = float(Time.get_ticks_usec() - started) / 1000.0


func _avg_around(c: Vector2, r: int) -> float:
	var acc := 0.0
	var cnt := 0
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var t := Vector2i(int(c.x) + dx, int(c.y) + dy)
			if t.x >= 0 and t.y >= 0 and t.x < size.x and t.y < size.y:
				acc += relief[t.y * size.x + t.x]
				cnt += 1
	return acc / maxf(1.0, float(cnt))


## Water follows terrain: order the sim water tiles from their highest
## relief, push a non-increasing water level through them (8-neighbour BFS),
## then cut a valley whose banks rise from that level.
func _carve_creek(sim) -> void:
	water_level.resize(size.x * size.y)
	water_level.fill(NAN)
	var waters: Dictionary = sim.water_tiles if sim.get("water_tiles") else {}
	if waters.is_empty():
		return
	var tiles: Array[Vector2i] = []
	for key in waters.keys():
		var parts := String(key).split(",")
		if parts.size() == 2:
			tiles.append(Vector2i(int(parts[0]), int(parts[1])))
	var is_water := {}
	for t in tiles:
		is_water[t] = true
	var visited := {}
	# Each connected water body: start at its highest tile.
	for seed_tile in tiles:
		if visited.has(seed_tile):
			continue
		var comp: Array[Vector2i] = []
		var q: Array[Vector2i] = [seed_tile]
		visited[seed_tile] = true
		while not q.is_empty():
			var t: Vector2i = q.pop_back()
			comp.append(t)
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var nb := t + Vector2i(dx, dy)
					if is_water.has(nb) and not visited.has(nb):
						visited[nb] = true
						q.append(nb)
		var top := comp[0]
		for t in comp:
			if at_tile(t) > at_tile(top):
				top = t
		var lvl := {}
		lvl[top] = at_tile(top) - 0.9
		var bq: Array[Vector2i] = [top]
		var head := 0
		while head < bq.size():
			var t: Vector2i = bq[head]
			head += 1
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var nb := t + Vector2i(dx, dy)
					if is_water.has(nb) and not lvl.has(nb):
						lvl[nb] = minf(float(lvl[t]) - 0.02, at_tile(nb) - 0.9)
						bq.append(nb)
		for t in comp:
			water_level[t.y * size.x + t.x] = float(lvl[t])
	# Valley: multi-source nearest-water field up to 7 tiles.
	var reach := 7
	var best_d := PackedFloat32Array()
	best_d.resize(size.x * size.y)
	best_d.fill(INF)
	var best_l := PackedFloat32Array()
	best_l.resize(size.x * size.y)
	for t in tiles:
		var wl := water_level[t.y * size.x + t.x]
		for dy in range(-reach, reach + 1):
			for dx in range(-reach, reach + 1):
				var x := t.x + dx
				var y := t.y + dy
				if x < 0 or y < 0 or x >= size.x or y >= size.y:
					continue
				var d := sqrt(float(dx * dx + dy * dy))
				var i := y * size.x + x
				if d < best_d[i]:
					best_d[i] = d
					best_l[i] = wl
	for i in size.x * size.y:
		if best_d[i] == INF:
			continue
		var d := best_d[i]
		var bed := best_l[i] - 0.25
		var bank := bed + 0.35 + pow(maxf(d - 0.6, 0.0), 1.5) * 0.55
		relief[i] = minf(relief[i], bank)


## Graded trail from the hall entrance to the crater claim pad (the sim
## already clears this corridor). Smooth the profile along it and blend.
func _grade_trail(sim, hall: Vector2) -> void:
	var finish := crater_center + Vector2(-5.0, 0.0)
	var steps := int(hall.distance_to(finish))
	if steps < 4:
		return
	trail = PackedVector2Array()
	var prof := PackedFloat32Array()
	for i in steps + 1:
		var p := hall.lerp(finish, float(i) / float(steps))
		trail.append(p)
		prof.append(sample_tiles(p))
	var smooth := PackedFloat32Array()
	smooth.resize(prof.size())
	for i in prof.size():
		var acc := 0.0
		var c := 0
		for k in range(maxi(0, i - 8), mini(prof.size(), i + 9)):
			acc += prof[k]
			c += 1
		smooth[i] = acc / float(c)
	for i in trail.size():
		var p := trail[i]
		for dy in range(-4, 5):
			for dx in range(-4, 5):
				var x := int(p.x) + dx
				var y := int(p.y) + dy
				if x < 0 or y < 0 or x >= size.x or y >= size.y:
					continue
				var d := Vector2(x, y).distance_to(p)
				var w := 1.0 - smoothstep(1.5, 4.5, d)
				var idx := y * size.x + x
				if not is_nan(water_level[idx]):
					continue
				relief[idx] = lerpf(relief[idx], smooth[i], w)
