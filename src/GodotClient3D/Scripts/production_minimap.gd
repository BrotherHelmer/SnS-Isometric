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
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Identity.COLOR_LUMEN)
	box.add_child(title)
	map_image = TextureRect.new()
	map_image.name = "MapImage"
	map_image.custom_minimum_size = Vector2(INNER, INNER)
	map_image.stretch_mode = TextureRect.STRETCH_SCALE
	map_image.mouse_filter = Control.MOUSE_FILTER_STOP
	map_image.gui_input.connect(_on_map_gui_input)
	box.add_child(map_image)


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


func _paint(map_size: Vector2i, frame_snapshot: Dictionary) -> void:
	var image := Image.create(map_size.x, map_size.y, false, Image.FORMAT_RGB8)
	image.fill(Color("#0a1210"))
	for y in range(map_size.y):
		for x in range(map_size.x):
			var tile := Vector2i(x, y)
			if not simulation.is_revealed(tile):
				continue
			var tile_type := String(simulation.get_tile(tile))
			var color := Color("#3a6a34")
			if tile_type == Defs.TILE_TREE:
				color = Color("#1f3d24")
			elif tile_type == Defs.TILE_ROCK:
				color = Color("#6a6a62")
			elif tile_type == Defs.TILE_SHARD:
				color = Color("#6bcfe0")
			image.set_pixel(x, y, color)
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
		var site_color := Color("#7a6bb8") if bool(site.get("visible", false)) else Color("#5a4a88")
		_dot(image, map_size, Vector2i(site.get("position", Vector2i.ZERO)), site_color)
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
	_dot(image, map_size, Vector2i(simulation.shard_position), Color("#6bcfe0"))
	_dot(image, map_size, Vector2i(simulation.rival_town_hall_position), Color("#7a2c36"))
	_paint_camera(image, map_size)
	if texture == null:
		texture = ImageTexture.create_from_image(image)
	else:
		if texture.get_width() != map_size.x or texture.get_height() != map_size.y:
			texture = ImageTexture.create_from_image(image)
		else:
			texture.update(image)
	map_image.texture = texture


func _dot(image: Image, map_size: Vector2i, tile: Vector2i, color: Color) -> void:
	if tile.x < 0 or tile.y < 0 or tile.x >= map_size.x or tile.y >= map_size.y:
		return
	image.set_pixel(tile.x, tile.y, color)


func _paint_camera(image: Image, map_size: Vector2i) -> void:
	if camera_rig == null or world_view == null:
		return
	var focus: Vector2i = world_view.world_to_tile(camera_rig.position)
	var half := maxi(3, int(round(camera_rig.target_zoom / ScaleProfile.LOGICAL_CELL_METRES * 0.55)))
	var color := Color("#f4d27a")
	for x in range(focus.x - half, focus.x + half + 1):
		_dot(image, map_size, Vector2i(x, focus.y - half), color)
		_dot(image, map_size, Vector2i(x, focus.y + half), color)
	for y in range(focus.y - half, focus.y + half + 1):
		_dot(image, map_size, Vector2i(focus.x - half, y), color)
		_dot(image, map_size, Vector2i(focus.x + half, y), color)


func _on_map_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if simulation == null or world_view == null or map_image == null:
		return
	var map_size: Vector2i = simulation.map_size
	var local: Vector2 = event.position
	if map_image.size.x < 1.0 or map_image.size.y < 1.0:
		return
	var tile := Vector2i(
		clampi(int(local.x / map_image.size.x * float(map_size.x)), 0, map_size.x - 1),
		clampi(int(local.y / map_image.size.y * float(map_size.y)), 0, map_size.y - 1)
	)
	focus_requested.emit(world_view.tile_to_world(Vector2(tile)))
	accept_event()
