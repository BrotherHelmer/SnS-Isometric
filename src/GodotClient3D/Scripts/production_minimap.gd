class_name ProductionMinimap3D
extends PanelContainer

## Top-down province map: fog, roads, the Shard, rival approach, and click-to-pan.

const Identity = preload("res://src/GodotClient3D/Scripts/production_identity.gd")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const ScaleProfile = preload("res://src/GodotClient3D/Scripts/production_scale_profile.gd")
const RivalryTuning = preload("res://src/GodotClient/Scripts/one_shard_rivalry_tuning.gd")

signal focus_requested(world_position: Vector3)

const INNER := 168

var map_image: TextureRect
var simulation
var world_view
var camera_rig
var texture: ImageTexture
var last_signature := ""
var refresh_elapsed := 0.0
var overview_mode := false


func _ready() -> void:
	name = "ProvinceMinimap"
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(INNER + 18, INNER + 36)
	add_theme_stylebox_override("panel", Identity.panel_style(Color(0.04, 0.05, 0.055, 0.92), Color("#efcf8a")))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	add_child(box)
	var title := Label.new()
	title.text = "PROVINCE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Identity.apply_label(title, "caption")
	title.add_theme_font_size_override("font_size", 11)  # Look lift type floor: nothing under 11 px
	title.add_theme_color_override("font_color", Identity.COLOR_LUMEN)
	box.add_child(title)
	map_image = TextureRect.new()
	map_image.name = "MapImage"
	map_image.custom_minimum_size = Vector2(INNER, INNER)
	map_image.stretch_mode = TextureRect.STRETCH_SCALE
	map_image.mouse_filter = Control.MOUSE_FILTER_STOP
	map_image.gui_input.connect(_on_map_gui_input)
	box.add_child(map_image)


## T-SNS-UI: compact framed variant for the bottom console.
func apply_console_layout(inner: float, style: StyleBox) -> void:
	custom_minimum_size = Vector2(inner + 12.0, inner + 28.0)
	if map_image != null:
		# Beta: without IGNORE_SIZE the texture's own pixel size (256+) became
		# the minimum and the console grew to ~280 px.
		map_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		map_image.custom_minimum_size = Vector2(inner, inner)
	add_theme_stylebox_override("panel", style)


func bind(simulation_value, world_view_value, camera_rig_value) -> void:
	simulation = simulation_value
	world_view = world_view_value
	camera_rig = camera_rig_value
	last_signature = ""


func tick(delta: float, frame_snapshot: Dictionary) -> void:
	refresh_elapsed += delta
	if refresh_elapsed < 0.16:
		return
	refresh_elapsed = 0.0
	redraw(frame_snapshot)


func redraw(frame_snapshot: Dictionary) -> void:
	if simulation == null or map_image == null:
		return
	var map_size: Vector2i = simulation.map_size
	if map_size.x <= 0:
		return
	var signature := "%d:%d:%d:%d" % [
		int(simulation.revealed_tiles.size()),
		int(frame_snapshot.get("buildings", []).size()),
		int(frame_snapshot.get("rival_roads", []).size()),
		int(camera_rig.target_zoom) if camera_rig != null else 0
	]
	# Always redraw moving units; signature still skips a full fog rebuild when quiet.
	_paint(map_size, frame_snapshot)
	last_signature = signature


## Beta r19: terrain layer is cached and only rebuilt when the revealed
## set changes (was a 25k-cell GDScript loop every 0.16 s). The visible
## rect is cropped to the explored area so the expanded map is not 90 %
## black.
var _base_image: Image
var _base_sig := ""
var _view_rect := Rect2i()


func _render_map(map_size: Vector2i, frame_snapshot: Dictionary) -> Image:
	var sig := "%d:%d:%d:%s:%d" % [map_size.x, map_size.y, int(simulation.revealed_tiles.size()), str(overview_mode), int(simulation.buildings.size())]
	if _base_image == null or sig != _base_sig:
		_base_image = _render_terrain(map_size)
		_base_sig = sig
	var image: Image = _base_image.duplicate()
	return _render_overlays(image, map_size, frame_snapshot)


## M3: ground currently inside a completed building's vision, painted the
## same way the world view paints its fog mask (building vision radii from
## the sim; workers' moving vision stays a world-only state).
func _building_vision_lattice(map_size: Vector2i) -> PackedByteArray:
	var lattice := PackedByteArray()
	lattice.resize(map_size.x * map_size.y)
	if not simulation.is_town_hall_founded():
		return lattice
	var centers: Array = []
	centers.append([simulation._footprint_center(simulation.town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL)), int(simulation.building_vision_radius(Defs.BUILDING_TOWN_HALL))])
	for b_value in simulation.buildings:
		var b: Dictionary = b_value
		if bool(b.get("construction", false)):
			continue
		var t := String(b.get("type", ""))
		if t == Defs.BUILDING_TOWN_HALL or t == Defs.BUILDING_ROAD:
			continue
		centers.append([simulation._footprint_center(Vector2i(b.get("position", Vector2i.ZERO)), Defs.building_footprint(t)), int(simulation.building_vision_radius(t))])
	for c in centers:
		var center: Vector2i = c[0]
		var radius := int(c[1])
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if dx * dx + dy * dy > radius * radius:
					continue
				var t := center + Vector2i(dx, dy)
				if t.x >= 0 and t.y >= 0 and t.x < map_size.x and t.y < map_size.y:
					lattice[t.y * map_size.x + t.x] = 1
	return lattice


func _render_terrain(map_size: Vector2i) -> Image:
	var image := Image.create(map_size.x, map_size.y, false, Image.FORMAT_RGB8)
	image.fill(Color("#0a1210"))
	var vision := _building_vision_lattice(map_size)
	var lo := Vector2i(map_size.x, map_size.y)
	var hi := Vector2i(-1, -1)
	var step := 1 if map_size.x <= 120 or overview_mode else 2
	for y in range(0, map_size.y, step):
		for x in range(0, map_size.x, step):
			var tile := Vector2i(x, y)
			var seen: bool = simulation.is_revealed(tile)
			if seen:
				lo = Vector2i(mini(lo.x, x), mini(lo.y, y))
				hi = Vector2i(maxi(hi.x, x), maxi(hi.y, y))
			var tile_type := String(simulation.get_tile(tile))
			var color := Color("#4d8a3e")
			var is_water: bool = simulation.has_method("is_water_tile") and simulation.is_water_tile(tile)
			if is_water:
				color = Color("#3a8a96")
			elif tile_type == Defs.TILE_TREE:
				color = Color("#1c4a22")
			elif tile_type == Defs.TILE_ROCK:
				color = Color("#8a8678")
			elif tile_type == Defs.TILE_SHARD:
				color = Color("#6bcfe0")
			if not is_water:
				# M3: relief shading from the sim's own height levels, so
				# the province map reads as the same heightfield the world
				# renders (gentle NW light; hue families unchanged).
				var h := float(simulation.get_height(tile))
				var hx := float(simulation.get_height(Vector2i(mini(tile.x + 1, map_size.x - 1), tile.y)))
				var hz := float(simulation.get_height(Vector2i(tile.x, mini(tile.y + 1, map_size.y - 1))))
				var shade := clampf(0.80 + h * 0.030 + (h - hx) * 0.05 + (h - hz) * 0.05, 0.62, 1.30)
				color = Color(color.r * shade, color.g * shade, color.b * shade)
			if seen and vision[tile.y * map_size.x + tile.x] != 0:
				color = color.lightened(0.22)
			if not seen:
				# Beta r23: unexplored land as a dim silhouette, not black,
				# so the province reads as a map (5.5 review: "sparse").
				color = color.darkened(0.22 if overview_mode else 0.62)
			if step == 1:
				image.set_pixel(x, y, color)
			else:
				for oy in range(step):
					for ox in range(step):
						if x + ox < map_size.x and y + oy < map_size.y:
							image.set_pixel(x + ox, y + oy, color)
	for keep_value in [simulation.shard_position, simulation.town_hall_position]:
		var keep := Vector2i(keep_value)
		if keep.x >= 0 and hi.x >= 0:
			lo = Vector2i(mini(lo.x, keep.x), mini(lo.y, keep.y))
			hi = Vector2i(maxi(hi.x, keep.x), maxi(hi.y, keep.y))
	if overview_mode or hi.x < 0:
		_view_rect = Rect2i(Vector2i.ZERO, map_size)
	else:
		var center := (lo + hi) / 2
		var side := clampi(maxi(hi.x - lo.x, hi.y - lo.y) + 24, 56, mini(map_size.x, map_size.y))
		var origin := Vector2i(clampi(center.x - side / 2, 0, map_size.x - side), clampi(center.y - side / 2, 0, map_size.y - side))
		_view_rect = Rect2i(origin, Vector2i(side, side))
	return image


func _render_overlays(image: Image, map_size: Vector2i, frame_snapshot: Dictionary) -> Image:
	for road_value in frame_snapshot.get("roads", []):
		var road: Dictionary = road_value
		var anchor := Vector2i(road.get("anchor", Vector2i.ZERO))
		_dot(image, map_size, anchor, Color("#6b4a2a"))
	for rival_value in frame_snapshot.get("rival_roads", []):
		var rival: Dictionary = rival_value
		if String(rival.get("realm", "")) == RivalryTuning.PLAYER_REALM:
			continue
		_dot(image, map_size, Vector2i(rival.get("anchor", Vector2i.ZERO)), Color("#9b3943"))
	for building_value in frame_snapshot.get("buildings", []):
		var building: Dictionary = building_value
		_dot(image, map_size, Vector2i(building.get("anchor", Vector2i.ZERO)), Color("#efcf8a"))
	for structure_value in frame_snapshot.get("rivalry_structures", []):
		var structure: Dictionary = structure_value
		if not bool(structure.get("visible", true)):
			continue
		var color := Color("#c45c3a") if String(structure.get("realm", "")) != RivalryTuning.PLAYER_REALM else Color("#7ec8d4")
		_dot(image, map_size, Vector2i(structure.get("anchor", Vector2i.ZERO)), color)
	for site_value in frame_snapshot.get("wyrd_sites", []):
		var site: Dictionary = site_value
		if bool(site.get("visible", false)):
			_dot(image, map_size, Vector2i(site.get("position", Vector2i.ZERO)), Color("#7a6bb8"))
	for worker_value in frame_snapshot.get("workers", []):
		var worker: Dictionary = worker_value
		if not bool(worker.get("visible", true)):
			continue
		var cargo := String(worker.get("cargo", "")) != ""
		_dot(image, map_size, Vector2i(worker.get("logical_tile", Vector2i.ZERO)), Color("#ffe08a") if cargo else Color("#d5ddd0"))
	for combatant_value in frame_snapshot.get("combatants", []):
		var combatant: Dictionary = combatant_value
		if not bool(combatant.get("visible", false)):
			continue
		var hostile := String(combatant.get("faction", "")) in ["hostile", "rival"]
		_dot(image, map_size, Vector2i(combatant.get("logical_tile", Vector2i.ZERO)), Color("#e37b6a") if hostile else Color("#9b3943"))
	_stamp_crater_ring(image, map_size)
	_stamp_landmark(image, map_size, Vector2i(simulation.shard_position), Color("#6bcfe0"), 5)
	if simulation.get("rival_seats"):
		for seat_value in simulation.rival_seats:
			_stamp_landmark(image, map_size, Vector2i(seat_value), Color("#c45c3a"), 4)
	else:
		_stamp_landmark(image, map_size, Vector2i(simulation.rival_town_hall_position), Color("#c45c3a"), 4)
	if simulation.is_town_hall_founded():
		_stamp_landmark(image, map_size, Vector2i(simulation.town_hall_position), Color("#efcf8a"), 4)
	var markers: Array = frame_snapshot.get("map_markers", [])
	if markers.is_empty() and simulation.has_method("get_map_markers"):
		markers = simulation.get_map_markers()
	for marker_value in markers:
		var marker: Dictionary = marker_value
		var kind := String(marker.get("kind", ""))
		var tile := Vector2i(marker.get("position", Vector2i.ZERO))
		if kind == "rival_banner":
			_stamp_landmark(image, map_size, tile, Color("#c84a4a"), 2)
		elif kind == "rival_route":
			_dot(image, map_size, tile, Color("#f0a06e"), overview_mode)
		elif kind == "rival_threat":
			_stamp_landmark(image, map_size, tile, Color("#f05a4a"), 3)
		elif kind == "rival_smoke":
			_stamp_landmark(image, map_size, tile, Color("#8a7a6a"), 3)
		elif kind == "seal_choice":
			_stamp_landmark(image, map_size, tile, Color("#7ec8d4"), 2)
		elif kind in ["caravan", "caravan_camp"]:
			_stamp_landmark(image, map_size, tile, Color("#efcf8a"), 2)
		elif kind == "palisade":
			_stamp_landmark(image, map_size, tile, Color("#d4782a"), 1)
		elif kind == "victory_banner":
			_stamp_landmark(image, map_size, tile, Color("#f0c44a"), 2)
	_paint_camera(image, map_size)
	return image


func _paint(map_size: Vector2i, frame_snapshot: Dictionary) -> void:
	var image := _render_map(map_size, frame_snapshot)
	if _view_rect.size.x > 0 and _view_rect.size != map_size:
		image = image.get_region(_view_rect)
	if texture == null:
		texture = ImageTexture.create_from_image(image)
	else:
		if texture.get_width() != image.get_width() or texture.get_height() != image.get_height():
			texture = ImageTexture.create_from_image(image)
		else:
			texture.update(image)
	map_image.texture = texture


func _dot(image: Image, map_size: Vector2i, tile: Vector2i, color: Color, camera_outline := false) -> void:
	if tile.x < 0 or tile.y < 0 or tile.x >= map_size.x or tile.y >= map_size.y:
		return
	# Every world marker obeys discovery, even when a snapshot contains hidden
	# authority data. The player's camera outline is not a world observation.
	# Overview mode is the province atlas for the big-map shot.
	if not camera_outline and not overview_mode and not simulation.is_revealed(tile):
		return
	image.set_pixel(tile.x, tile.y, color)


func _stamp_landmark(image: Image, map_size: Vector2i, tile: Vector2i, color: Color, radius: int) -> void:
	for oy in range(-radius, radius + 1):
		for ox in range(-radius, radius + 1):
			if ox * ox + oy * oy > radius * radius:
				continue
			_dot(image, map_size, tile + Vector2i(ox, oy), color, overview_mode)


func _stamp_crater_ring(image: Image, map_size: Vector2i) -> void:
	if simulation == null:
		return
	var center: Vector2i = simulation.shard_position
	var radius := int(round(float(simulation.CRATER_RADIUS)))
	var pit := int(round(float(simulation.crater_pit_radius)))
	for angle in range(0, 360, 3):
		var rad := deg_to_rad(float(angle))
		var rim := center + Vector2i(roundi(cos(rad) * float(radius)), roundi(sin(rad) * float(radius)))
		_dot(image, map_size, rim, Color("#5a6a4a"), overview_mode)
		var pit_tile := center + Vector2i(roundi(cos(rad) * float(pit)), roundi(sin(rad) * float(pit)))
		_dot(image, map_size, pit_tile, Color("#2a3a38"), overview_mode)


func _paint_camera(image: Image, map_size: Vector2i) -> void:
	if camera_rig == null or world_view == null:
		return
	var focus: Vector2i = world_view.world_to_tile(camera_rig.position)
	var half := maxi(3, int(round(camera_rig.target_zoom / ScaleProfile.LOGICAL_CELL_METRES * 0.55)))
	var color := Color("#f4d27a")
	for x in range(focus.x - half, focus.x + half + 1):
		_dot(image, map_size, Vector2i(x, focus.y - half), color, true)
		_dot(image, map_size, Vector2i(x, focus.y + half), color, true)
	for y in range(focus.y - half, focus.y + half + 1):
		_dot(image, map_size, Vector2i(focus.x - half, y), color, true)
		_dot(image, map_size, Vector2i(focus.x + half, y), color, true)


func _on_map_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if simulation == null or world_view == null or map_image == null:
		return
	var map_size: Vector2i = simulation.map_size
	var local: Vector2 = event.position
	if map_image.size.x < 1.0 or map_image.size.y < 1.0:
		return
	var rect := _view_rect if _view_rect.size.x > 0 else Rect2i(Vector2i.ZERO, map_size)
	var tile := Vector2i(
		clampi(rect.position.x + int(local.x / map_image.size.x * float(rect.size.x)), 0, map_size.x - 1),
		clampi(rect.position.y + int(local.y / map_image.size.y * float(rect.size.y)), 0, map_size.y - 1)
	)
	focus_requested.emit(world_view.tile_to_world(Vector2(tile)))
	accept_event()
