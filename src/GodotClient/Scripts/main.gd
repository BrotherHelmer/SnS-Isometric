extends Node2D

const OneShardSimulation = preload("one_shard_simulation.gd")
const Defs = preload("one_shard_defs.gd")
const RivalryTuning = preload("one_shard_rivalry_tuning.gd")
const StaticWorldLayer = preload("static_world_layer.gd")
const TREE_TEXTURE: Texture2D = preload("res://assets/settlement/tree.png")
const TREE_B_TEXTURE: Texture2D = preload("res://assets/settlement/tree_b.png")
const TREE_LARGE_TEXTURE: Texture2D = preload("res://assets/settlement/tree_large.png")
const TREE_PAINTERLY_TEXTURE: Texture2D = preload("res://assets/settlement/tree_painterly.png")
const ROAD_TEXTURE: Texture2D = preload("res://assets/settlement/tiles_path.png")
const ROCK_A_TEXTURE: Texture2D = preload("res://assets/settlement/rock_a.png")
const ROCK_B_TEXTURE: Texture2D = preload("res://assets/settlement/rock_b.png")
const SETTLER_WALK_TEXTURE: Texture2D = preload("res://assets/settlement/settler_walk_v2.png")
const CRATES_TEXTURE: Texture2D = preload("res://assets/settlement/crates.png")
const PACK_MULE_TEXTURE: Texture2D = preload("res://assets/settlement/founding/pack_mule.png")
const FOUNDING_SUPPLIES_TEXTURE: Texture2D = preload("res://assets/settlement/founding/founding_supplies.png")
const LUMEN_PILLAR_TEXTURE: Texture2D = preload("res://assets/settlement/rivalry/lumen_pillar.png")
const SOVEREIGN_HERO_TEXTURE: Texture2D = preload("res://assets/settlement/rivalry/sovereign_hero.png")
const SOVEREIGN_WALK_TEXTURE: Texture2D = preload("res://assets/settlement/rivalry/sovereign_walk_v3.png")
const TOWN_HALL_TEXTURE: Texture2D = preload("res://assets/settlement/buildings/town_hall.png")
const HOUSE_TEXTURE: Texture2D = preload("res://assets/settlement/buildings/house.png")
const LUMBER_CAMP_TEXTURE: Texture2D = preload("res://assets/settlement/buildings/lumber_camp.png")
const QUARRY_TEXTURE: Texture2D = preload("res://assets/settlement/buildings/quarry.png")
const SAWMILL_TEXTURE: Texture2D = preload("res://assets/settlement/buildings/sawmill.png")
const FARM_TEXTURE: Texture2D = preload("res://assets/settlement/buildings/farm.png")
const BAKERY_TEXTURE: Texture2D = preload("res://assets/settlement/buildings/bakery.png")
const WATCHTOWER_TEXTURE: Texture2D = preload("res://assets/settlement/buildings/watchtower.png")
const BARRACKS_TEXTURE: Texture2D = preload("res://assets/settlement/buildings/barracks.png")
const STOREHOUSE_TEXTURE: Texture2D = preload("res://assets/settlement/buildings/storehouse.png")
const OUTPOST_TEXTURE: Texture2D = preload("res://assets/settlement/buildings/outpost.png")
const SHARD_TEXTURE: Texture2D = preload("res://assets/settlement/threats/shard.png")
const ENEMY_CAMP_TEXTURE: Texture2D = preload("res://assets/settlement/threats/enemy_camp.png")
const NIGHT_RAIDER_WALK_TEXTURE: Texture2D = preload("res://assets/settlement/threats/night_raider_walk_v2.png")
const AMBIENCE_SOUND: AudioStreamWAV = preload("res://assets/settlement/audio/ambience.wav")
const MUSIC_SOUND: AudioStreamWAV = preload("res://assets/settlement/audio/music.wav")
const MUSIC_STEMS := {
	"pastoral": preload("res://assets/settlement/audio/presentation/score_pastoral_foundation.wav"),
	"activity": preload("res://assets/settlement/audio/presentation/score_settlement_activity.wav"),
	"dusk": preload("res://assets/settlement/audio/presentation/score_dusk_tension.wav"),
	"night": preload("res://assets/settlement/audio/presentation/score_night_percussion.wav"),
	"metal": preload("res://assets/settlement/audio/presentation/score_metal_combat.wav")
}
const AMBIENT_STREAMS := {
	"wind": preload("res://assets/settlement/audio/presentation/settlement_wind_birds.wav"),
	"chop": preload("res://assets/settlement/audio/presentation/work_chop.wav"),
	"hammer": preload("res://assets/settlement/audio/presentation/work_hammer.wav"),
	"footstep": preload("res://assets/settlement/audio/presentation/footstep.wav"),
	"lumen": preload("res://assets/settlement/audio/presentation/lumen_hum.wav")
}
const SFX_STREAMS := {
	"road": preload("res://assets/settlement/audio/road.wav"),
	"build_start": preload("res://assets/settlement/audio/build_start.wav"),
	"build_complete": preload("res://assets/settlement/audio/build_complete.wav"),
	"delivery": preload("res://assets/settlement/audio/delivery.wav"),
	"tower": preload("res://assets/settlement/audio/tower.wav"),
	"night": preload("res://assets/settlement/audio/night.wav"),
	"enemy": preload("res://assets/settlement/audio/enemy.wav"),
	"soldier": preload("res://assets/settlement/audio/soldier.wav"),
	"attack": preload("res://assets/settlement/audio/attack.wav"),
	"destroyed": preload("res://assets/settlement/audio/destroyed.wav")
}

const TILE_WIDTH := 48.0
const TILE_HEIGHT := 24.0
const HEIGHT_STEP := 8.0
const MIN_ZOOM := 0.58
const MAX_ZOOM := 2.8
const DEFAULT_ZOOM := 1.52
const CAMERA_PAN_SPEED := 520.0
const CAMERA_BUTTON_STEP := 180.0
const SETTLER_FRAME_SIZE := Vector2(28.0, 42.0)
const RAIDER_FRAME_SIZE := Vector2(38.0, 46.0)
const SETTLER_DRAW_SIZE := Vector2(20.0, 30.0)
const RAIDER_DRAW_SIZE := Vector2(26.0, 32.0)
const ENEMY_ATTACK_ANIMATION_SECONDS := 0.56
const GUARD_ATTACK_ANIMATION_SECONDS := 0.48
const MODE_SELECT := "SELECT"
const MODE_DEMOLISH := "DEMOLISH"
const MODE_CLEAR := "CLEAR"
const DEMO_VERSION := "0.1.0-demo"
const VISUAL_REFRESH_SECONDS := 1.0 / 30.0
const UI_REFRESH_SECONDS := 0.25
const SETTINGS_PATH := "user://presentation_settings.json"
const DEFAULT_MASTER_VOLUME := 0.80
const DEFAULT_MUSIC_VOLUME := 0.70
const DEFAULT_EFFECTS_VOLUME := 0.80
const DEFAULT_AMBIENCE_VOLUME := 0.65
const SOVEREIGN_FRAME_SIZE := Vector2(48.0, 72.0)
const SOVEREIGN_DRAW_SIZE := Vector2(25.0, 37.5)

const BUILD_MODES := [
	Defs.BUILDING_TOWN_HALL,
	Defs.BUILDING_ROAD,
	Defs.BUILDING_HOUSE,
	Defs.BUILDING_LUMBER_CAMP,
	Defs.BUILDING_QUARRY,
	Defs.BUILDING_SAWMILL,
	Defs.BUILDING_FARM,
	Defs.BUILDING_BAKERY,
	Defs.BUILDING_STOREHOUSE,
	Defs.BUILDING_WALL,
	Defs.BUILDING_WATCHTOWER,
	Defs.BUILDING_BARRACKS,
	Defs.BUILDING_LUMEN_PILLAR,
	Defs.BUILDING_OUTPOST
]

const GOLD := Color(0.86, 0.7, 0.24, 1.0)
const PANEL_BG := Color(0.12, 0.105, 0.08, 0.95)
const PANEL_BORDER := Color(0.4, 0.32, 0.2, 0.96)
const TEXT_LIGHT := Color(0.95, 0.91, 0.8, 1.0)
const TEXT_MUTED := Color(0.72, 0.66, 0.55, 1.0)
const VALID_GREEN := Color(0.28, 0.86, 0.48, 0.34)
const INVALID_RED := Color(0.95, 0.18, 0.14, 0.34)

var simulation
var static_world
var camera: Camera2D
var canvas_layer: CanvasLayer
var resources_label: Label
var message_label: Label
var objectives_label: Label
var log_label: Label
var info_panel: PanelContainer
var info_label: Label
var validation_label: Label
var restaff_button: Button
var priority_button: Button
var speed_button: Button
var summary_panel: PanelContainer
var summary_label: Label
var event_log_panel: PanelContainer
var event_log_text: RichTextLabel
var night_overlay: ColorRect
var shard_overlay: ColorRect
var mode_buttons: Dictionary = {}
var debug_panel: PanelContainer
var debug_label: Label
var rivalry_debug_visible := false
var shard_proximity_active := false
var pre_shard_zoom := DEFAULT_ZOOM
var main_menu_root: Control
var main_menu_card: PanelContainer
var how_to_card: PanelContainer
var settings_card: PanelContainer
var pause_menu_root: Control
var continue_button: Button
var objective_button: Button
var tutorial_skip_button: Button
var master_volume_slider: HSlider
var music_volume_slider: HSlider
var effects_volume_slider: HSlider
var ambience_volume_slider: HSlider
var window_mode_button: OptionButton
var music_mute_button: CheckButton
var game_started := false
var tutorial_enabled := true
var modal_returns_to_pause := false
var master_volume := DEFAULT_MASTER_VOLUME
var effects_volume := DEFAULT_EFFECTS_VOLUME
var music_volume := DEFAULT_MUSIC_VOLUME
var ambience_volume := DEFAULT_AMBIENCE_VOLUME
var music_muted := false
var window_mode_setting := 0

var hovered_tile := Vector2i(-1, -1)
var selected_tile := Vector2i(-1, -1)
var selected_building_id := 0
var selected_worker_id := 0
var current_mode := MODE_SELECT
var tick_accumulator := 0.0
var ui_refresh_accumulator := 0.0
var visual_refresh_accumulator := 0.0
var paused := false
var simulation_speed := 1.0
var is_dragging_camera := false
var camera_drag_button := 0
var last_mouse_position := Vector2.ZERO
var placement_rotation := 0
var validation_panel: PanelContainer
var objective_panel: PanelContainer
var objectives_expanded := false
var cached_map_bounds := Rect2()
var sfx_players: Array[AudioStreamPlayer] = []
var ambience_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var music_players: Dictionary = {}
var ambient_players: Array[AudioStreamPlayer2D] = []
var ambient_timer := 2.0
var ambient_sequence := 0
var command_dock: PanelContainer
var command_dock_content: VBoxContainer
var command_dock_collapsed := false
var command_dock_body: Control
var selection_portrait: TextureRect
var selection_name_label: Label
var selection_state_label: Label
var selection_task_label: Label
var build_category_sections: Dictionary = {}
var build_category_buttons: Dictionary = {}
var active_build_category := "Settlement"
var toast_panel: PanelContainer
var toast_timer := 0.0
var last_toast_text := ""
var objective_intro_visible := false
var opening_intro_active := false
var opening_intro_stage := 0
var opening_intro_timer := 0.0
var opening_door_open := 0.0
var opening_worker_id := 0
var right_click_start := Vector2.ZERO
var right_click_pending_order := false
var volume_value_labels: Dictionary = {}
var cached_revealed_tiles: Array[Vector2i] = []
var cached_revealed_count := -1
var active_chop_tiles: Dictionary = {}
var last_mode_button_signature := ""
var static_world_signature := ""
var render_pass_count := 0
var ui_update_count := 0


func _ready() -> void:
	if simulation == null:
		simulation = OneShardSimulation.new(
			OneShardSimulation.MAP_WIDTH,
			OneShardSimulation.MAP_HEIGHT,
			0,
			OS.is_debug_build()
		)
		simulation.start_presentation_run(431211)
	static_world = StaticWorldLayer.new()
	static_world.name = "StaticWorld"
	static_world.view = self
	static_world.z_index = -20
	add_child(static_world)
	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.position = tile_to_world(simulation.town_hall_position)
	camera.zoom = Vector2(DEFAULT_ZOOM, DEFAULT_ZOOM)
	camera.enabled = true
	add_child(camera)
	_reset_camera()

	_load_settings()
	_setup_audio()
	_create_ui()
	_create_release_shell()
	_apply_settings_to_controls()
	_clamp_camera()
	_update_hovered_tile()
	_update_ui()
	_refresh_static_world_if_needed(true)
	queue_redraw()


func _process(delta: float) -> void:
	_update_adaptive_music(delta)
	if toast_timer > 0.0:
		toast_timer = maxf(0.0, toast_timer - delta)
		if toast_timer <= 0.0 and toast_panel != null:
			toast_panel.visible = false
	if not game_started:
		_play_pending_audio()
		return
	_update_opening_intro(delta)
	_update_player_sovereign_controls()
	_update_camera_controls(delta)
	_refresh_static_world_if_needed()
	_update_visual_modes(delta)
	_update_settlement_soundscape(delta)
	var previous_hover := hovered_tile
	_update_hovered_tile()
	var simulation_advanced := false
	if previous_hover != hovered_tile:
		queue_redraw()

	if not paused:
		tick_accumulator += delta * simulation_speed
		while tick_accumulator >= OneShardSimulation.TICK_SECONDS:
			simulation.advance_tick()
			tick_accumulator -= OneShardSimulation.TICK_SECONDS
			simulation_advanced = true
	ui_refresh_accumulator += delta
	if previous_hover != hovered_tile or ui_refresh_accumulator >= UI_REFRESH_SECONDS:
		ui_refresh_accumulator = 0.0
		_update_ui()
	_update_cursor_feedback()
	visual_refresh_accumulator += delta
	if simulation_advanced or previous_hover != hovered_tile or visual_refresh_accumulator >= VISUAL_REFRESH_SECONDS:
		visual_refresh_accumulator = 0.0
		queue_redraw()
	_play_pending_audio()


func _setup_audio() -> void:
	for index in range(6):
		var player := AudioStreamPlayer.new()
		player.name = "Sfx%d" % index
		player.volume_db = -7.0
		add_child(player)
		sfx_players.append(player)
	ambience_player = AudioStreamPlayer.new()
	ambience_player.name = "VillageAmbience"
	var ambience: AudioStreamWAV = AMBIENT_STREAMS["wind"].duplicate()
	ambience.loop_mode = AudioStreamWAV.LOOP_FORWARD
	ambience_player.stream = ambience
	ambience_player.volume_db = -25.0
	add_child(ambience_player)
	ambience_player.play()
	for stem_name in ["pastoral", "activity", "dusk", "night", "metal"]:
		var layer := AudioStreamPlayer.new()
		layer.name = "Score_%s" % String(stem_name).capitalize()
		var stem: AudioStreamWAV = MUSIC_STEMS[stem_name].duplicate()
		stem.loop_mode = AudioStreamWAV.LOOP_FORWARD
		layer.stream = stem
		layer.volume_db = -80.0
		add_child(layer)
		music_players[stem_name] = layer
	for stem_name in music_players.keys():
		music_players[stem_name].play(0.0)
	for index in range(6):
		var ambient_player := AudioStreamPlayer2D.new()
		ambient_player.name = "WorldAmbience%d" % index
		ambient_player.max_distance = 760.0
		ambient_player.attenuation = 1.3
		ambient_player.volume_db = -13.0
		add_child(ambient_player)
		ambient_players.append(ambient_player)
	_apply_audio_levels()


func _update_adaptive_music(delta: float) -> void:
	if music_players.is_empty():
		return
	var master_music_db := -80.0 if music_muted or music_volume <= 0.001 else linear_to_db(music_volume)
	var targets := {
		"pastoral": -13.0,
		"activity": -38.0,
		"dusk": -52.0,
		"night": -60.0,
		"metal": -64.0
	}
	if game_started:
		var day_remaining: float = OneShardSimulation.DAY_LENGTH_SECONDS - float(simulation.phase_time)
		var settlement_energy := clampf(float(simulation.get_population_used() - 1) / 5.0, 0.0, 1.0)
		targets["activity"] = lerpf(-34.0, -19.0, settlement_energy)
		if not simulation.is_night and day_remaining <= 90.0:
			var dusk_weight := clampf((90.0 - day_remaining) / 90.0, 0.0, 1.0)
			targets["dusk"] = lerpf(-52.0, -15.0, dusk_weight)
			targets["activity"] = lerpf(float(targets["activity"]), -31.0, dusk_weight)
		if simulation.is_night:
			var threat := clampf(float(simulation.enemies.size()) / 8.0, 0.0, 1.0)
			targets["pastoral"] = -30.0
			targets["activity"] = -46.0
			targets["dusk"] = -18.0
			targets["night"] = -14.0
			targets["metal"] = lerpf(-23.0, -11.0, threat)
			if simulation.claim_active:
				targets["metal"] = -8.0
	if paused and game_started:
		for key in targets.keys():
			targets[key] = float(targets[key]) - 4.0
	for stem_name in music_players.keys():
		var target_db := -80.0 if master_music_db <= -79.0 else float(targets.get(stem_name, -80.0)) + master_music_db
		var layer: AudioStreamPlayer = music_players[stem_name]
		layer.volume_db = move_toward(layer.volume_db, target_db, delta * 8.0)


func _update_settlement_soundscape(delta: float) -> void:
	ambient_timer -= delta * simulation_speed
	if ambient_timer > 0.0 or ambient_players.is_empty() or paused:
		return
	var candidates: Array = []
	for worker in simulation.get_workers():
		if not worker.get("path", []).is_empty():
			candidates.append(["footstep", worker.get("position", simulation.town_hall_position)])
		var state := String(worker.get("state", "")).to_lower()
		if "gather" in state or "clear" in state or String(worker.get("type", "")) == "woodcutter":
			candidates.append(["chop", worker.get("position", simulation.town_hall_position)])
		elif "build" in state:
			candidates.append(["hammer", worker.get("position", simulation.town_hall_position)])
	if simulation.is_night:
		candidates.append(["lumen", simulation.town_hall_position])
	if candidates.is_empty():
		ambient_timer = 2.8
		return
	var choice: Array = candidates[ambient_sequence % candidates.size()]
	ambient_sequence += 1
	var player := _available_ambient_player()
	player.position = tile_to_object_base(choice[1])
	player.stream = AMBIENT_STREAMS[String(choice[0])]
	player.volume_db = (-17.0 if String(choice[0]) == "footstep" else -12.0) + linear_to_db(maxf(ambience_volume, 0.001))
	player.play()
	ambient_timer = 0.55 if String(choice[0]) == "footstep" else (1.6 + float(ambient_sequence % 4) * 0.45)


func _available_ambient_player() -> AudioStreamPlayer2D:
	for player in ambient_players:
		if not player.playing:
			return player
	return ambient_players[0]


func _play_pending_audio() -> void:
	for event_name in simulation.consume_audio_events():
		if not SFX_STREAMS.has(event_name):
			continue
		if effects_volume <= 0.001:
			continue
		var player := _available_sfx_player()
		var base_volume := -18.0 if event_name == "delivery" else (-13.0 if event_name in ["road", "build_start", "build_complete", "soldier"] else -7.0)
		player.volume_db = base_volume + linear_to_db(effects_volume)
		player.stream = SFX_STREAMS[event_name]
		player.play()


func _available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	return sfx_players[0]


func _update_opening_intro(delta: float) -> void:
	if not opening_intro_active or paused:
		return
	opening_intro_timer += delta
	if opening_intro_stage == 0:
		opening_door_open = clampf((opening_intro_timer - 0.55) / 0.65, 0.0, 1.0)
		if opening_intro_timer >= 1.2:
			var entrance: Vector2i = simulation._town_hall_entrance_tile()
			simulation.set_presentation_worker_departure([
				entrance + Vector2i(0, 1),
				entrance + Vector2i(1, 1),
				entrance + Vector2i(1, 2)
			])
			opening_intro_stage = 1
			opening_intro_timer = 0.0
			queue_redraw()
	elif opening_intro_stage == 1:
		var worker: Dictionary = simulation.get_worker_by_id(opening_worker_id)
		if worker.get("path", []).is_empty() and String(worker.get("state", "")) == "Looking around":
			simulation.set_worker_reaction(opening_worker_id, "Confused", "?", 2.1)
			opening_intro_stage = 2
			opening_intro_timer = 0.0
			queue_redraw()
	elif opening_intro_stage == 2 and opening_intro_timer >= 2.15:
		simulation.set_worker_reaction(opening_worker_id, "Awaiting order", "", 0.0)
		objective_intro_visible = true
		opening_intro_active = false
		_show_toast("?", "Select the settler, then right-click a nearby tree or stone.")
		_update_ui()
		queue_redraw()


func _show_toast(icon_text: String, text_value: String) -> void:
	if toast_panel == null or message_label == null:
		return
	message_label.text = "%s  %s" % [icon_text, text_value]
	last_toast_text = text_value
	toast_timer = 4.2
	toast_panel.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if not game_started:
			if (how_to_card != null and how_to_card.visible) or (settings_card != null and settings_card.visible):
				_close_release_modal()
			return
		if pause_menu_root != null and pause_menu_root.visible:
			_resume_game()
			return
	if not game_started or (pause_menu_root != null and pause_menu_root.visible):
		return
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	elif event is InputEventKey and event.pressed:
		_handle_key(event)


func _draw() -> void:
	render_pass_count += 1
	_draw_guidance_overlays()
	_draw_build_preview()
	_draw_tile_highlight(selected_tile, Color(0.98, 0.79, 0.25, 1.0), 3.0)
	_draw_tile_highlight(hovered_tile, Color(1.0, 1.0, 1.0, 0.9), 2.0)
	_draw_protection_bubbles()
	_draw_founding_camp()
	_draw_world_entities()
	_draw_opening_door()
	_draw_rivalry_entities()
	_draw_projectiles()


func _refresh_static_world_if_needed(force: bool = false) -> void:
	if static_world == null or camera == null or simulation == null:
		return
	var road_count := 0
	var construction_count := 0
	for building in simulation.buildings:
		if String(building.get("type", "")) == Defs.BUILDING_ROAD:
			road_count += 1
		elif bool(building.get("construction", false)):
			construction_count += 1
	var rival_roads := 0
	var rival_structures := 0
	if simulation.rivalry != null:
		rival_roads = simulation.rivalry.get_roads(RivalryTuning.AI_REALM).size()
		rival_structures = simulation.rivalry.structures.size()
	var camera_bucket := Vector2i(
		floori(camera.position.x / 240.0),
		floori(camera.position.y / 160.0)
	)
	var zoom_bucket := roundi(camera.zoom.x * 8.0)
	var signature := "%d|%d|%d|%d|%d|%d|%d|%s|%d|%s" % [
		simulation.revealed_tiles.size(),
		simulation.tree_deposits.size(),
		simulation.rock_deposits.size(),
		road_count,
		construction_count,
		rival_roads,
		rival_structures,
		str(simulation.is_gate_closed()),
		zoom_bucket,
		str(camera_bucket)
	]
	if not force and signature == static_world_signature:
		return
	static_world_signature = signature
	static_world.queue_redraw()


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	var ending_camera_drag := event.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE] and not event.pressed and is_dragging_camera
	if _pointer_over_ui() and not ending_camera_drag:
		return
	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and selected_worker_id > 0 and current_mode == MODE_SELECT:
		_issue_selected_worker_order(hovered_tile)
		return
	if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
		is_dragging_camera = event.pressed
		camera_drag_button = event.button_index if event.pressed else 0
		last_mouse_position = event.position
		return

	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_apply_zoom(1.1)
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_apply_zoom(0.9)
		return

	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	if not simulation.is_inside_map(hovered_tile):
		return

	selected_tile = hovered_tile
	var building: Dictionary = simulation.get_building_at_tile(selected_tile)
	var worker: Dictionary = _worker_at_tile(selected_tile)
	if not worker.is_empty():
		selected_worker_id = int(worker.get("id", 0))
		selected_building_id = 0
		_set_mode(MODE_SELECT)
		simulation.set_worker_reaction(selected_worker_id, String(worker.get("state", "Selected")), "!", 0.55)
		_update_ui()
		queue_redraw()
		return
	selected_worker_id = 0
	selected_building_id = int(building.get("id", 0)) if not building.is_empty() else 0

	if current_mode == MODE_SELECT:
		if building.is_empty():
			simulation.set_player_sovereign_target(selected_tile)
		_update_ui()
		queue_redraw()
		return
	if current_mode == MODE_DEMOLISH:
		simulation.request_demolish(selected_tile)
		_update_selected_building_id()
		_update_ui()
		queue_redraw()
		return
	if current_mode == MODE_CLEAR:
		simulation.request_clear(selected_tile)
		_update_ui()
		queue_redraw()
		return

	if BUILD_MODES.has(current_mode):
		var result: Dictionary = simulation.request_build(current_mode, selected_tile, placement_rotation)
		if bool(result.get("success", false)):
			var placed: Dictionary = result.get("building", result.get("structure", {}))
			selected_building_id = int(placed.get("id", selected_building_id))
		_update_ui()
		queue_redraw()


func _worker_at_tile(tile: Vector2i) -> Dictionary:
	for worker in simulation.get_workers():
		if Vector2i(worker.get("position", Vector2i(-1, -1))) == tile and String(worker.get("state", "")) != "Inside Town Hall":
			return worker
	return {}


func _issue_selected_worker_order(tile: Vector2i) -> void:
	if selected_worker_id <= 0 or not simulation.is_inside_map(tile):
		return
	var result: Dictionary = simulation.request_worker_order(selected_worker_id, tile)
	if bool(result.get("success", false)):
		_show_toast("!", String(result.get("message", "Order accepted.")))
	else:
		_show_toast("×", String(result.get("message", "That order cannot be completed.")))
	_update_ui()
	queue_redraw()


func _cancel_selected_worker_order() -> void:
	if selected_worker_id <= 0:
		return
	var result: Dictionary = simulation.cancel_worker_order(selected_worker_id)
	_show_toast("×", String(result.get("message", "Order cancelled.")))
	_update_ui()
	queue_redraw()


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if not is_dragging_camera:
		return
	var screen_delta := event.position - last_mouse_position
	camera.position -= Vector2(screen_delta.x / camera.zoom.x, screen_delta.y / camera.zoom.y)
	_clamp_camera()
	last_mouse_position = event.position


func _handle_key(event: InputEventKey) -> void:
	if event.keycode == KEY_ESCAPE:
		if event_log_panel != null and event_log_panel.visible:
			event_log_panel.visible = false
			return
		if current_mode == MODE_SELECT:
			_open_pause_menu()
		else:
			_set_mode(MODE_SELECT)
	elif event.keycode == KEY_SPACE:
		_toggle_pause()
	elif event.keycode == KEY_L:
		_toggle_event_log()
	elif event.keycode == KEY_HOME:
		_reset_camera()
	elif event.keycode == KEY_F:
		_focus_player_sovereign()
	elif event.keycode == KEY_E:
		simulation.request_player_wyrd_extraction()
		_update_ui()
		queue_redraw()
	elif event.keycode == KEY_Q:
		simulation.request_player_sovereign_attack()
		_update_ui()
		queue_redraw()
	elif event.keycode == KEY_C:
		simulation.request_player_claim()
		_update_ui()
		queue_redraw()
	elif event.keycode == KEY_F3:
		_toggle_rivalry_debug()
	elif event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
		_apply_zoom(1.1)
	elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
		_apply_zoom(0.9)
	elif event.keycode == KEY_R and BUILD_MODES.has(current_mode) and current_mode != Defs.BUILDING_ROAD:
		placement_rotation = posmod(placement_rotation + 1, 4)
		_update_ui()
		queue_redraw()


func _apply_zoom(factor: float) -> void:
	var next_zoom := clampf(camera.zoom.x * factor, MIN_ZOOM, MAX_ZOOM)
	camera.zoom = Vector2(next_zoom, next_zoom)
	pre_shard_zoom = next_zoom / 1.10 if shard_proximity_active else next_zoom
	_clamp_camera()


func _reset_camera() -> void:
	var town_center: Vector2 = simulation.get_building_center({"position": simulation.town_hall_position, "footprint": {"x": 4, "y": 4}})
	var town_tile := Vector2i(roundi(town_center.x), roundi(town_center.y))
	camera.position = tile_position_to_world(town_center, town_tile) + Vector2(86.0, 22.0)
	camera.zoom = Vector2(DEFAULT_ZOOM, DEFAULT_ZOOM)
	pre_shard_zoom = DEFAULT_ZOOM
	shard_proximity_active = false
	_clamp_camera()


func _focus_player_sovereign() -> void:
	if simulation.rivalry == null:
		camera.position = tile_to_world(simulation._town_hall_entrance_tile() + Vector2i(0, 1))
		_clamp_camera()
		return
	var sovereign: Dictionary = simulation.rivalry.get_sovereign(RivalryTuning.PLAYER_REALM)
	if sovereign.is_empty():
		return
	var position: Vector2 = sovereign.get("position", Vector2(simulation.town_hall_position))
	var elevation_tile := Vector2i(roundi(position.x), roundi(position.y))
	camera.position = tile_position_to_world(position, elevation_tile)
	_clamp_camera()


func _update_player_sovereign_controls() -> void:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		direction.y += 1.0
	simulation.set_player_sovereign_input(direction.normalized())


func _update_camera_controls(delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	if direction == Vector2.ZERO:
		return
	camera.position += direction.normalized() * CAMERA_PAN_SPEED * delta / camera.zoom.x
	_clamp_camera()


func _pan_camera(direction: Vector2) -> void:
	camera.position += direction * CAMERA_BUTTON_STEP / camera.zoom.x
	_clamp_camera()


func _create_ui() -> void:
	canvas_layer = CanvasLayer.new()
	canvas_layer.name = "UIRoot"
	add_child(canvas_layer)

	var top_panel := _create_panel(Vector2(12, 10), Vector2(1256, 42), Color(0.085, 0.07, 0.048, 0.98), Color(0.48, 0.35, 0.17, 0.98), 6)
	top_panel.name = "CompactStatusBar"
	top_panel.anchor_right = 1.0
	top_panel.offset_left = 12.0
	top_panel.offset_right = -12.0
	top_panel.offset_top = 10.0
	top_panel.offset_bottom = 52.0
	canvas_layer.add_child(top_panel)
	var top_margin := _create_margin(top_panel, 9, 5)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 5)
	top_margin.add_child(top_row)
	resources_label = Label.new()
	resources_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resources_label.add_theme_color_override("font_color", TEXT_LIGHT)
	resources_label.add_theme_font_size_override("font_size", 12)
	resources_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_row.add_child(resources_label)
	speed_button = _create_action_button("1×", _cycle_speed)
	speed_button.tooltip_text = "Simulation speed: 1×, 2×, or 4×"
	top_row.add_child(speed_button)
	var pause_button := _create_action_button("Ⅱ", _toggle_pause)
	pause_button.tooltip_text = "Pause or resume (Space)"
	top_row.add_child(pause_button)
	var centre_button := _create_action_button("Town Hall", _reset_camera)
	centre_button.tooltip_text = "Centre the camera on the settlement (Home)"
	top_row.add_child(centre_button)
	top_row.add_child(_create_action_button("Menu", _open_pause_menu))

	command_dock = _create_panel(Vector2(12, 60), Vector2(282, 648), Color(0.10, 0.075, 0.047, 0.985), Color(0.50, 0.35, 0.16, 0.98), 7)
	command_dock.name = "LeftCommandDock"
	command_dock.anchor_bottom = 1.0
	command_dock.offset_left = 12.0
	command_dock.offset_top = 60.0
	command_dock.offset_right = 294.0
	command_dock.offset_bottom = -12.0
	canvas_layer.add_child(command_dock)
	var dock_margin := _create_margin(command_dock, 9, 8)
	command_dock_content = VBoxContainer.new()
	command_dock_content.add_theme_constant_override("separation", 6)
	dock_margin.add_child(command_dock_content)
	var dock_header := HBoxContainer.new()
	dock_header.add_theme_constant_override("separation", 4)
	command_dock_content.add_child(dock_header)
	var dock_title := Label.new()
	dock_title.name = "DockTitle"
	dock_title.text = "REALM COMMAND"
	dock_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dock_title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.40, 1.0))
	dock_title.add_theme_font_size_override("font_size", 14)
	dock_header.add_child(dock_title)
	var collapse := _create_action_button("‹", _toggle_command_dock)
	collapse.name = "DockCollapse"
	collapse.custom_minimum_size = Vector2(32, 28)
	collapse.tooltip_text = "Collapse or expand the command dock"
	dock_header.add_child(collapse)
	command_dock_body = VBoxContainer.new()
	command_dock_body.name = "DockBody"
	command_dock_body.add_theme_constant_override("separation", 6)
	command_dock_content.add_child(command_dock_body)

	var selection_panel := PanelContainer.new()
	selection_panel.add_theme_stylebox_override("panel", _create_panel_style(Color(0.16, 0.12, 0.075, 0.98), Color(0.35, 0.25, 0.13, 0.95), 5))
	command_dock_body.add_child(selection_panel)
	var selection_margin := _create_margin(selection_panel, 7, 6)
	var selection_row := HBoxContainer.new()
	selection_row.add_theme_constant_override("separation", 8)
	selection_margin.add_child(selection_row)
	selection_portrait = TextureRect.new()
	selection_portrait.custom_minimum_size = Vector2(52, 58)
	selection_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	selection_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	selection_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	selection_row.add_child(selection_portrait)
	var selection_copy := VBoxContainer.new()
	selection_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selection_copy.add_theme_constant_override("separation", 1)
	selection_row.add_child(selection_copy)
	selection_name_label = Label.new()
	selection_name_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.58, 1.0))
	selection_name_label.add_theme_font_size_override("font_size", 13)
	selection_copy.add_child(selection_name_label)
	selection_state_label = Label.new()
	selection_state_label.add_theme_color_override("font_color", TEXT_LIGHT)
	selection_state_label.add_theme_font_size_override("font_size", 11)
	selection_state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selection_copy.add_child(selection_state_label)
	selection_task_label = Label.new()
	selection_task_label.add_theme_color_override("font_color", TEXT_MUTED)
	selection_task_label.add_theme_font_size_override("font_size", 10)
	selection_task_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selection_copy.add_child(selection_task_label)

	var command_row := HBoxContainer.new()
	command_row.add_theme_constant_override("separation", 4)
	command_dock_body.add_child(command_row)
	var move_command := _create_action_button("Move", _begin_worker_move)
	move_command.tooltip_text = "Select a settler, then right-click open ground."
	command_row.add_child(move_command)
	var gather_command := _create_action_button("Gather", _begin_worker_gather)
	gather_command.tooltip_text = "Select a settler, then right-click a tree or stone deposit."
	command_row.add_child(gather_command)
	var cancel_command := _create_action_button("Cancel", _cancel_selected_worker_order)
	cancel_command.tooltip_text = "Cancel the selected settler's current order."
	command_row.add_child(cancel_command)

	var divider := HSeparator.new()
	divider.add_theme_color_override("separator", Color(0.43, 0.30, 0.14, 0.9))
	command_dock_body.add_child(divider)
	var category_grid := GridContainer.new()
	category_grid.columns = 2
	category_grid.add_theme_constant_override("h_separation", 4)
	category_grid.add_theme_constant_override("v_separation", 4)
	command_dock_body.add_child(category_grid)
	var categories := [
		["Settlement", "⌂"], ["Resources", "♣"], ["Production", "⚙"], ["Food", "◆"],
		["Defence", "⚔"], ["Lumen", "✦"], ["Tools", "⌁"]
	]
	for category in categories:
		var category_name := String(category[0])
		var category_button := _create_action_button("%s %s" % [String(category[1]), category_name], _show_build_category.bind(category_name))
		category_button.custom_minimum_size = Vector2(124, 30)
		category_button.tooltip_text = "%s commands" % category_name
		category_grid.add_child(category_button)
		build_category_buttons[category_name] = category_button

	var build_scroll := ScrollContainer.new()
	build_scroll.name = "VisualBuildList"
	build_scroll.custom_minimum_size = Vector2(0, 312)
	build_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	build_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	command_dock_body.add_child(build_scroll)
	var section_host := VBoxContainer.new()
	section_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build_scroll.add_child(section_host)
	var category_defs := {
		"Settlement": [Defs.BUILDING_ROAD, Defs.BUILDING_HOUSE, Defs.BUILDING_STOREHOUSE],
		"Resources": [Defs.BUILDING_LUMBER_CAMP, Defs.BUILDING_QUARRY],
		"Production": [Defs.BUILDING_SAWMILL],
		"Food": [Defs.BUILDING_FARM, Defs.BUILDING_BAKERY],
		"Defence": [Defs.BUILDING_WALL, Defs.BUILDING_WATCHTOWER, Defs.BUILDING_BARRACKS],
		"Lumen": [Defs.BUILDING_LUMEN_PILLAR, Defs.BUILDING_OUTPOST],
		"Tools": []
	}
	for category_name in category_defs.keys():
		var section := VBoxContainer.new()
		section.name = "%sBuildEntries" % category_name
		section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		section.add_theme_constant_override("separation", 5)
		section_host.add_child(section)
		build_category_sections[category_name] = section
		for building_type in category_defs[category_name]:
			section.add_child(_create_build_entry(String(building_type)))
	var tools_section: VBoxContainer = build_category_sections["Tools"]
	for tool in [
		["Select", MODE_SELECT, "Inspect settlers, structures, and terrain."],
		["Clear", MODE_CLEAR, "Clear a resource with a free settler."],
		["Demolish", MODE_DEMOLISH, "Remove a non-Town Hall structure."]
	]:
		var tool_button := _create_mode_button(String(tool[0]), String(tool[1]))
		tool_button.custom_minimum_size = Vector2(246, 38)
		tool_button.tooltip_text = String(tool[2])
		tools_section.add_child(tool_button)
		mode_buttons[String(tool[1])] = tool_button
	tools_section.add_child(_create_action_button("Realm Chronicle", _toggle_event_log))

	restaff_button = _create_action_button("Restaff selected workplace", _restaff_selected)
	restaff_button.visible = false
	command_dock_body.add_child(restaff_button)
	priority_button = _create_action_button("Priority: Normal", _cycle_priority_selected)
	priority_button.visible = false
	command_dock_body.add_child(priority_button)
	_show_build_category("Settlement")

	objective_panel = _create_panel(Vector2(306, 60), Vector2(610, 40), Color(0.10, 0.075, 0.047, 0.96), Color(0.45, 0.31, 0.14, 0.95), 6)
	objective_panel.name = "ObjectiveStrip"
	objective_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	canvas_layer.add_child(objective_panel)
	var objective_margin := _create_margin(objective_panel, 8, 5)
	var objective_content := VBoxContainer.new()
	objective_content.add_theme_constant_override("separation", 4)
	objective_margin.add_child(objective_content)
	objective_button = _create_action_button("Objective", _toggle_objectives)
	objective_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	objective_button.custom_minimum_size = Vector2(590, 28)
	objective_content.add_child(objective_button)
	objectives_label = Label.new()
	objectives_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objectives_label.add_theme_color_override("font_color", TEXT_LIGHT)
	objectives_label.add_theme_font_size_override("font_size", 12)
	objectives_label.visible = false
	objective_content.add_child(objectives_label)
	tutorial_skip_button = _create_action_button("Hide objectives", _skip_tutorial)
	tutorial_skip_button.visible = false
	objective_content.add_child(tutorial_skip_button)

	toast_panel = _create_panel(Vector2(928, 60), Vector2(338, 40), Color(0.09, 0.075, 0.05, 0.97), GOLD, 6)
	toast_panel.name = "TransientToast"
	toast_panel.anchor_left = 1.0
	toast_panel.anchor_right = 1.0
	toast_panel.offset_left = -352.0
	toast_panel.offset_right = -14.0
	toast_panel.offset_top = 60.0
	toast_panel.offset_bottom = 100.0
	toast_panel.visible = false
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child(toast_panel)
	var toast_margin := _create_margin(toast_panel, 10, 6)
	message_label = Label.new()
	message_label.add_theme_color_override("font_color", Color(1.0, 0.91, 0.67, 1.0))
	message_label.add_theme_font_size_override("font_size", 12)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_margin.add_child(message_label)

	validation_panel = _create_panel(Vector2(450, 580), Vector2(340, 38), Color(0.075, 0.07, 0.052, 0.96), PANEL_BORDER, 5)
	canvas_layer.add_child(validation_panel)
	var validation_margin := _create_margin(validation_panel, 10, 5)
	validation_label = Label.new()
	validation_label.add_theme_color_override("font_color", TEXT_LIGHT)
	validation_label.add_theme_font_size_override("font_size", 11)
	validation_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	validation_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	validation_margin.add_child(validation_label)
	validation_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	validation_panel.visible = false

	log_label = Label.new()
	info_label = Label.new()
	night_overlay = ColorRect.new()
	night_overlay.name = "NightOverlay"
	night_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	night_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	night_overlay.color = Color(0.02, 0.03, 0.08, 0.0)
	canvas_layer.add_child(night_overlay)
	canvas_layer.move_child(night_overlay, 0)
	shard_overlay = ColorRect.new()
	shard_overlay.name = "ShardProximityOverlay"
	shard_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shard_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shard_overlay.color = Color(0.08, 0.03, 0.16, 0.0)
	canvas_layer.add_child(shard_overlay)
	canvas_layer.move_child(shard_overlay, 0)
	debug_panel = _create_panel(Vector2(900, 116), Vector2(366, 252), Color(0.045, 0.055, 0.07, 0.96), Color(0.25, 0.65, 0.82, 0.9), 5)
	debug_panel.visible = false
	canvas_layer.add_child(debug_panel)
	var debug_margin := _create_margin(debug_panel, 9, 7)
	debug_label = Label.new()
	debug_label.add_theme_color_override("font_color", Color(0.78, 0.92, 1.0, 1.0))
	debug_label.add_theme_font_size_override("font_size", 10)
	debug_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	debug_margin.add_child(debug_label)
	_create_summary_panel()
	_create_event_log_panel()
	_sync_mode_buttons()


func _create_build_entry(building_type: String) -> Button:
	var button := _create_mode_button("%s\n%s" % [Defs.building_name(building_type), Defs.formatted_cost(building_type)], building_type)
	button.name = "%sThumbnailButton" % building_type
	button.custom_minimum_size = Vector2(246, 58)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.icon = _building_thumbnail(building_type)
	button.add_theme_constant_override("icon_max_width", 48)
	button.expand_icon = true
	button.add_theme_font_size_override("font_size", 11)
	button.tooltip_text = _building_tooltip(building_type)
	mode_buttons[building_type] = button
	return button


func _building_thumbnail(building_type: String) -> Texture2D:
	var texture := _building_texture(building_type)
	if texture != null:
		return texture
	if building_type == Defs.BUILDING_ROAD:
		return ROAD_TEXTURE
	if building_type == Defs.BUILDING_LUMEN_PILLAR:
		return LUMEN_PILLAR_TEXTURE
	if building_type == Defs.BUILDING_WALL:
		return WATCHTOWER_TEXTURE
	return TOWN_HALL_TEXTURE


func _building_tooltip(building_type: String) -> String:
	var purpose: String = String({
		Defs.BUILDING_ROAD: "Connects work sites and speeds deliveries.",
		Defs.BUILDING_HOUSE: "Adds room for five settlers.",
		Defs.BUILDING_LUMBER_CAMP: "Harvests nearby trees into Wood.",
		Defs.BUILDING_QUARRY: "Extracts Stone from a rock deposit.",
		Defs.BUILDING_SAWMILL: "Turns 2 Wood into 2 Planks.",
		Defs.BUILDING_FARM: "Produces Wheat for settlement food.",
		Defs.BUILDING_BAKERY: "Turns 2 Wheat into 2 Bread.",
		Defs.BUILDING_STOREHOUSE: "Expands settlement storage.",
		Defs.BUILDING_WALL: "Slows hostile units; begins at a tower.",
		Defs.BUILDING_WATCHTOWER: "Protects roads and supports one soldier.",
		Defs.BUILDING_BARRACKS: "Trains settlement soldiers.",
		Defs.BUILDING_LUMEN_PILLAR: "Extends road-connected protected ground.",
		Defs.BUILDING_OUTPOST: "Establishes a claim beside the Shard."
	}.get(building_type, "Settlement structure."))
	var requirements := "Road: required" if building_type not in [Defs.BUILDING_WALL, Defs.BUILDING_WATCHTOWER] else "Road or defence network required"
	var staff := Defs.building_staff(building_type)
	return "%s\nCost: %s\nWorkers: %d\n%s" % [String(purpose), Defs.formatted_cost(building_type), staff, requirements]


func _show_build_category(category_name: String) -> void:
	active_build_category = category_name
	for key in build_category_sections.keys():
		build_category_sections[key].visible = String(key) == category_name
	for key in build_category_buttons.keys():
		_style_button(build_category_buttons[key], String(key) == category_name)


func _toggle_command_dock() -> void:
	command_dock_collapsed = not command_dock_collapsed
	command_dock_body.visible = not command_dock_collapsed
	var title := command_dock_content.find_child("DockTitle", true, false) as Label
	if title != null:
		title.visible = not command_dock_collapsed
	command_dock.custom_minimum_size = Vector2(46 if command_dock_collapsed else 282, 648)
	command_dock.offset_right = 58.0 if command_dock_collapsed else 294.0
	var collapse := command_dock_content.find_child("DockCollapse", true, false) as Button
	if collapse != null:
		collapse.text = "›" if command_dock_collapsed else "‹"


func _begin_worker_move() -> void:
	_set_mode(MODE_SELECT)
	_show_toast("→", "Select a settler, then right-click open ground.")


func _begin_worker_gather() -> void:
	_set_mode(MODE_SELECT)
	_show_toast("♣", "Select a settler, then right-click a tree or stone deposit.")


func _create_legacy_ui_unused() -> void:
	canvas_layer = CanvasLayer.new()
	canvas_layer.name = "UIRoot"
	add_child(canvas_layer)

	var top_panel := _create_panel(Vector2(14, 10), Vector2(864, 38), PANEL_BG, PANEL_BORDER, 5)
	canvas_layer.add_child(top_panel)
	var top_margin := _create_margin(top_panel, 10, 5)
	resources_label = Label.new()
	resources_label.add_theme_color_override("font_color", TEXT_LIGHT)
	resources_label.add_theme_font_size_override("font_size", 11)
	top_margin.add_child(resources_label)

	var utility_panel := _create_panel(Vector2(888, 10), Vector2(378, 38), PANEL_BG, PANEL_BORDER, 5)
	canvas_layer.add_child(utility_panel)
	var utility_margin := _create_margin(utility_panel, 6, 4)
	var utility_row := HBoxContainer.new()
	utility_row.add_theme_constant_override("separation", 5)
	utility_margin.add_child(utility_row)
	speed_button = _create_action_button("1x", _cycle_speed)
	speed_button.tooltip_text = "Game speed: 1x, 2x, or 4x."
	utility_row.add_child(speed_button)
	utility_row.add_child(_create_action_button("Pause", _toggle_pause))
	utility_row.add_child(_create_action_button("Save", _save_run))
	utility_row.add_child(_create_action_button("Home", _reset_camera))
	utility_row.add_child(_create_action_button("Menu", _open_pause_menu))

	var message_panel := _create_panel(Vector2(338, 58), Vector2(604, 34), Color(0.16, 0.15, 0.12, 0.92), GOLD, 5)
	canvas_layer.add_child(message_panel)
	var message_margin := _create_margin(message_panel, 10, 4)
	message_label = Label.new()
	message_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.66, 1.0))
	message_label.add_theme_font_size_override("font_size", 13)
	message_margin.add_child(message_label)

	objective_panel = _create_panel(Vector2(14, 58), Vector2(310, 34), PANEL_BG, PANEL_BORDER, 5)
	canvas_layer.add_child(objective_panel)
	var objective_margin := _create_margin(objective_panel, 8, 6)
	var objective_content := VBoxContainer.new()
	objective_content.add_theme_constant_override("separation", 5)
	objective_margin.add_child(objective_content)
	var objective_button := _create_action_button("Objectives ▸", _toggle_objectives)
	objective_content.add_child(objective_button)
	self.objective_button = objective_button
	objectives_label = Label.new()
	objectives_label.add_theme_color_override("font_color", TEXT_LIGHT)
	objectives_label.add_theme_font_size_override("font_size", 12)
	objectives_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objectives_label.visible = false
	objective_content.add_child(objectives_label)
	tutorial_skip_button = _create_action_button("Skip tutorial", _skip_tutorial)
	tutorial_skip_button.visible = false
	objective_content.add_child(tutorial_skip_button)

	var log_panel := _create_panel(Vector2(14, 190), Vector2(316, 116), PANEL_BG, PANEL_BORDER, 5)
	log_panel.visible = false
	canvas_layer.add_child(log_panel)
	var log_margin := _create_margin(log_panel, 8, 6)
	log_label = Label.new()
	log_label.add_theme_color_override("font_color", TEXT_MUTED)
	log_label.add_theme_font_size_override("font_size", 11)
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_margin.add_child(log_label)

	info_panel = _create_panel(Vector2(982, 58), Vector2(284, 244), PANEL_BG, PANEL_BORDER, 5)
	info_panel.visible = false
	canvas_layer.add_child(info_panel)
	var info_margin := _create_margin(info_panel, 10, 8)
	var info_content := VBoxContainer.new()
	info_content.add_theme_constant_override("separation", 6)
	info_margin.add_child(info_content)
	info_label = Label.new()
	info_label.add_theme_color_override("font_color", TEXT_LIGHT)
	info_label.add_theme_font_size_override("font_size", 12)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_content.add_child(info_label)
	restaff_button = _create_action_button("Restaff", _restaff_selected)
	info_content.add_child(restaff_button)
	priority_button = _create_action_button("Priority: Normal", _cycle_priority_selected)
	priority_button.tooltip_text = "Cycle which workplaces receive settlers first."
	info_content.add_child(priority_button)

	var bottom_panel := _create_panel(Vector2(250, 632), Vector2(780, 78), PANEL_BG, PANEL_BORDER, 5)
	canvas_layer.add_child(bottom_panel)
	var bottom_margin := _create_margin(bottom_panel, 7, 5)
	var build_row := GridContainer.new()
	build_row.columns = 10
	build_row.add_theme_constant_override("h_separation", 4)
	build_row.add_theme_constant_override("v_separation", 4)
	bottom_margin.add_child(build_row)
	var select_button := _create_mode_button("Select", MODE_SELECT)
	build_row.add_child(select_button)
	mode_buttons[MODE_SELECT] = select_button
	for building_type in BUILD_MODES:
		var button := _create_mode_button(_short_build_name(building_type), building_type)
		button.tooltip_text = "%s — Cost: %s." % [Defs.building_name(building_type), Defs.formatted_cost(building_type)]
		if building_type == Defs.BUILDING_LUMEN_PILLAR:
			button.tooltip_text = "Lumen Pillar — extend protected claim power. Cost: 8 Wood, 3 Wyrd."
		build_row.add_child(button)
		mode_buttons[building_type] = button
	var demolish_button := _create_mode_button("Demolish", MODE_DEMOLISH)
	build_row.add_child(demolish_button)
	mode_buttons[MODE_DEMOLISH] = demolish_button
	var clear_button := _create_mode_button("Clear", MODE_CLEAR)
	clear_button.tooltip_text = "Clear a tree or rock with one free settler."
	build_row.add_child(clear_button)
	mode_buttons[MODE_CLEAR] = clear_button
	var event_log_button := _create_action_button("Log", _toggle_event_log)
	event_log_button.tooltip_text = "Open the full realm event log"
	build_row.add_child(event_log_button)
	var claim_button := _create_action_button("Sovereign", _focus_player_sovereign)
	claim_button.tooltip_text = "Center on your Sovereign (F)."
	build_row.add_child(claim_button)

	validation_panel = _create_panel(Vector2(394, 588), Vector2(330, 34), Color(0.09, 0.11, 0.1, 0.94), PANEL_BORDER, 5)
	canvas_layer.add_child(validation_panel)
	var validation_margin := _create_margin(validation_panel, 10, 4)
	validation_label = Label.new()
	validation_label.add_theme_color_override("font_color", TEXT_LIGHT)
	validation_label.add_theme_font_size_override("font_size", 12)
	validation_margin.add_child(validation_label)
	validation_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	validation_panel.visible = false

	night_overlay = ColorRect.new()
	night_overlay.name = "NightOverlay"
	night_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	night_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	night_overlay.color = Color(0.02, 0.03, 0.08, 0.0)
	canvas_layer.add_child(night_overlay)
	canvas_layer.move_child(night_overlay, 0)

	shard_overlay = ColorRect.new()
	shard_overlay.name = "ShardProximityOverlay"
	shard_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shard_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shard_overlay.color = Color(0.08, 0.03, 0.16, 0.0)
	canvas_layer.add_child(shard_overlay)
	canvas_layer.move_child(shard_overlay, 0)

	debug_panel = _create_panel(Vector2(906, 290), Vector2(360, 252), Color(0.045, 0.055, 0.07, 0.96), Color(0.25, 0.65, 0.82, 0.9), 5)
	debug_panel.visible = false
	canvas_layer.add_child(debug_panel)
	var debug_margin := _create_margin(debug_panel, 9, 7)
	debug_label = Label.new()
	debug_label.add_theme_color_override("font_color", Color(0.78, 0.92, 1.0, 1.0))
	debug_label.add_theme_font_size_override("font_size", 10)
	debug_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	debug_margin.add_child(debug_label)

	_create_summary_panel()
	_create_event_log_panel()
	_create_camera_controls()
	_sync_mode_buttons()


func _create_release_shell() -> void:
	main_menu_root = Control.new()
	main_menu_root.name = "ReleaseMenu"
	main_menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_menu_root.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas_layer.add_child(main_menu_root)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.018, 0.035, 0.04, 0.82)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	main_menu_root.add_child(backdrop)

	var menu_center := CenterContainer.new()
	menu_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_menu_root.add_child(menu_center)
	main_menu_card = _create_panel(Vector2.ZERO, Vector2(650, 620), Color(0.075, 0.07, 0.052, 0.99), GOLD, 9)
	menu_center.add_child(main_menu_card)
	var menu_margin := _create_margin(main_menu_card, 36, 28)
	var menu_content := VBoxContainer.new()
	menu_content.add_theme_constant_override("separation", 12)
	menu_margin.add_child(menu_content)

	var title := Label.new()
	title.text = "SHARD & SOVEREIGN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.42, 1.0))
	title.add_theme_font_size_override("font_size", 34)
	menu_content.add_child(title)
	var tagline := Label.new()
	tagline.text = "Build by day. Survive the night. Claim the Shard."
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_color_override("font_color", TEXT_LIGHT)
	tagline.add_theme_font_size_override("font_size", 18)
	menu_content.add_child(tagline)
	var divider := HSeparator.new()
	divider.add_theme_color_override("separator", PANEL_BORDER)
	menu_content.add_child(divider)
	var premise := Label.new()
	premise.text = "You are a Sovereign leading a small band of settlers into a fractured province. Build a living settlement, protect it with Lumen, survive what comes after sunset, and claim the central Shard before your rival."
	premise.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	premise.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	premise.add_theme_color_override("font_color", TEXT_MUTED)
	premise.add_theme_font_size_override("font_size", 14)
	premise.custom_minimum_size = Vector2(540, 76)
	menu_content.add_child(premise)

	var play_button := _create_action_button("Play Demo / New Game", _start_new_demo)
	play_button.custom_minimum_size = Vector2(0, 42)
	menu_content.add_child(play_button)
	continue_button = _create_action_button("Continue", _continue_demo)
	continue_button.custom_minimum_size = Vector2(0, 38)
	continue_button.disabled = not _has_valid_save()
	continue_button.tooltip_text = "Continue the most recent valid local save."
	menu_content.add_child(continue_button)
	var how_button := _create_action_button("How to Play", _show_how_to_play)
	how_button.custom_minimum_size = Vector2(0, 38)
	menu_content.add_child(how_button)
	var settings_button := _create_action_button("Settings", _show_settings.bind(false))
	settings_button.custom_minimum_size = Vector2(0, 38)
	menu_content.add_child(settings_button)
	var quit_button := _create_action_button("Quit", _quit_game)
	quit_button.custom_minimum_size = Vector2(0, 38)
	menu_content.add_child(quit_button)
	var version := Label.new()
	version.text = DEMO_VERSION
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.add_theme_color_override("font_color", TEXT_MUTED)
	version.add_theme_font_size_override("font_size", 11)
	menu_content.add_child(version)

	how_to_card = _create_info_modal(
		"How to Play",
		"CAMERA\nArrow keys pan. Drag with the middle mouse button, or right-drag when no settler is selected. Mouse wheel or +/- zooms. Home centres the Town Hall; F centres the Sovereign.\n\n"
		+ "FIRST ORDER\nSelect the settler, then right-click open ground to move or a nearby tree or stone deposit to gather. The settler walks, works, and delivers the result to the Town Hall.\n\n"
		+ "SETTLEMENT\nChoose a visual build category in the left command dock, then click valid ground; R rotates and Escape cancels. Roads connect work sites to the Town Hall and make travel faster. Materials remain physical: carriers must collect and deliver them.\n\n"
		+ "PRODUCTION\nLumber makes Wood. Quarries make Stone. Sawmills turn Wood into Planks. Farms make Wheat; Bakeries turn Wheat into Bread. Houses add room for settlers. Select a building to see exactly why it is idle.\n\n"
		+ "SOVEREIGN & NIGHT\nWASD moves your Sovereign. E extracts nearby Wyrd; Q attacks. Civilians seek shelter at dusk. Lumen marks protected ground, while soldiers, walls, and towers hold raiders outside it.\n\n"
		+ "CLAIM\nExtend connected roads and Lumen to the central Shard, build a Claimant Outpost, bring the Sovereign into its ring, and press C. Hold every requirement through the claim night.\n\n"
		+ "Space pauses. The speed control cycles 1x, 2x, and 4x. L opens the Realm Chronicle."
	)
	settings_card = _create_settings_modal()

	pause_menu_root = Control.new()
	pause_menu_root.name = "PauseMenu"
	pause_menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_menu_root.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_menu_root.visible = false
	canvas_layer.add_child(pause_menu_root)
	var pause_backdrop := ColorRect.new()
	pause_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_backdrop.color = Color(0.01, 0.02, 0.025, 0.72)
	pause_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_menu_root.add_child(pause_backdrop)
	var pause_center := CenterContainer.new()
	pause_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_menu_root.add_child(pause_center)
	var pause_card := _create_panel(Vector2.ZERO, Vector2(390, 430), PANEL_BG, GOLD, 8)
	pause_center.add_child(pause_card)
	var pause_margin := _create_margin(pause_card, 28, 24)
	var pause_content := VBoxContainer.new()
	pause_content.add_theme_constant_override("separation", 12)
	pause_margin.add_child(pause_content)
	var pause_title := Label.new()
	pause_title.text = "Realm Paused"
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.42, 1.0))
	pause_title.add_theme_font_size_override("font_size", 26)
	pause_content.add_child(pause_title)
	for entry in [
		["Resume", Callable(self, "_resume_game")],
		["Save", Callable(self, "_save_run")],
		["Restart Scenario", Callable(self, "_restart_from_pause")],
		["Settings", Callable(self, "_show_pause_settings")],
		["Return to Main Menu", Callable(self, "_return_to_main_menu")],
		["Quit", Callable(self, "_quit_game")]
	]:
		var button := _create_action_button(String(entry[0]), entry[1])
		button.custom_minimum_size = Vector2(0, 40)
		pause_content.add_child(button)


func _create_info_modal(title_text: String, body_text: String) -> PanelContainer:
	var card := _create_panel(Vector2.ZERO, Vector2(760, 650), Color(0.065, 0.064, 0.055, 0.995), GOLD, 8)
	card.visible = false
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Hidden modal cards keep their full-screen CenterContainer alive. If the
	# container stops mouse input, it sits above the main card and makes every
	# visible menu button look enabled while swallowing all clicks.
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_menu_root.add_child(center)
	center.add_child(card)
	var margin := _create_margin(card, 28, 24)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.42, 1.0))
	title.add_theme_font_size_override("font_size", 26)
	content.add_child(title)
	var body := Label.new()
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", TEXT_LIGHT)
	body.add_theme_font_size_override("font_size", 14)
	body.custom_minimum_size = Vector2(690, 510)
	content.add_child(body)
	var close_button := _create_action_button("Back", _close_release_modal)
	close_button.custom_minimum_size = Vector2(0, 38)
	content.add_child(close_button)
	return card


func _create_settings_modal() -> PanelContainer:
	var card := _create_panel(Vector2.ZERO, Vector2(620, 590), Color(0.065, 0.064, 0.055, 0.995), GOLD, 8)
	card.visible = false
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_menu_root.add_child(center)
	center.add_child(card)
	var margin := _create_margin(card, 32, 28)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	margin.add_child(content)
	var title := Label.new()
	title.text = "Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.42, 1.0))
	title.add_theme_font_size_override("font_size", 26)
	content.add_child(title)
	master_volume_slider = _add_volume_setting(content, "Master volume", "master", master_volume, _set_master_volume)
	music_volume_slider = _add_volume_setting(content, "Music volume", "music", music_volume, _set_music_volume)
	effects_volume_slider = _add_volume_setting(content, "Effects volume", "effects", effects_volume, _set_effects_volume)
	ambience_volume_slider = _add_volume_setting(content, "Ambience", "ambience", ambience_volume, _set_ambience_volume)
	music_mute_button = CheckButton.new()
	music_mute_button.text = "Mute music"
	music_mute_button.button_pressed = music_muted
	music_mute_button.add_theme_color_override("font_color", TEXT_LIGHT)
	music_mute_button.toggled.connect(_set_music_muted)
	content.add_child(music_mute_button)
	var window_row := HBoxContainer.new()
	window_row.add_theme_constant_override("separation", 12)
	content.add_child(window_row)
	var window_label := Label.new()
	window_label.text = "Display"
	window_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	window_label.add_theme_color_override("font_color", TEXT_LIGHT)
	window_row.add_child(window_label)
	window_mode_button = OptionButton.new()
	window_mode_button.add_item("Windowed")
	window_mode_button.add_item("Borderless Fullscreen")
	window_mode_button.selected = window_mode_setting
	window_mode_button.custom_minimum_size = Vector2(220, 36)
	window_mode_button.item_selected.connect(_set_window_mode)
	_style_button(window_mode_button, false)
	window_row.add_child(window_mode_button)
	var note := Label.new()
	note.text = "Changes apply immediately and persist between sessions. Music continues in sync while its mix changes."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", TEXT_MUTED)
	content.add_child(note)
	content.add_child(_create_action_button("Restore audio defaults", _restore_audio_defaults))
	var close_button := _create_action_button("Back", _close_release_modal)
	close_button.custom_minimum_size = Vector2(0, 38)
	content.add_child(close_button)
	return card


func _add_volume_setting(parent: VBoxContainer, label_text: String, setting_key: String, initial_value: float, callback: Callable) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(150, 32)
	label.add_theme_color_override("font_color", TEXT_LIGHT)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = initial_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(callback)
	row.add_child(slider)
	var value_label := Label.new()
	value_label.text = "%d%%" % int(round(initial_value * 100.0))
	value_label.custom_minimum_size = Vector2(48, 32)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.46, 1.0))
	row.add_child(value_label)
	volume_value_labels[setting_key] = value_label
	return slider


func _start_new_demo() -> void:
	game_started = true
	tutorial_enabled = true
	main_menu_root.visible = false
	pause_menu_root.visible = false
	_new_run()


func _continue_demo() -> void:
	if not _has_valid_save():
		continue_button.disabled = true
		return
	if not simulation.load_from_file():
		continue_button.disabled = true
		return
	game_started = true
	tutorial_enabled = true
	main_menu_root.visible = false
	pause_menu_root.visible = false
	paused = false
	opening_intro_active = false
	objective_intro_visible = true
	_invalidate_revealed_tile_cache()
	_reset_camera()
	_set_mode(MODE_SELECT if simulation.is_town_hall_founded() else Defs.BUILDING_TOWN_HALL)


func _show_how_to_play() -> void:
	modal_returns_to_pause = false
	main_menu_card.visible = false
	settings_card.visible = false
	how_to_card.visible = true


func _show_settings(return_to_pause: bool = false) -> void:
	modal_returns_to_pause = return_to_pause
	main_menu_root.visible = true
	main_menu_card.visible = false
	how_to_card.visible = false
	settings_card.visible = true
	if pause_menu_root != null:
		pause_menu_root.visible = false


func _show_pause_settings() -> void:
	_show_settings(true)


func _close_release_modal() -> void:
	how_to_card.visible = false
	settings_card.visible = false
	if modal_returns_to_pause and game_started:
		main_menu_root.visible = false
		pause_menu_root.visible = true
	else:
		main_menu_card.visible = true


func _open_pause_menu() -> void:
	if not game_started:
		return
	paused = true
	event_log_panel.visible = false
	pause_menu_root.visible = true
	_update_ui()


func _resume_game() -> void:
	paused = false
	pause_menu_root.visible = false
	_update_ui()


func _restart_from_pause() -> void:
	pause_menu_root.visible = false
	_start_new_demo()


func _return_to_main_menu() -> void:
	game_started = false
	paused = true
	pause_menu_root.visible = false
	main_menu_root.visible = true
	main_menu_card.visible = true
	how_to_card.visible = false
	settings_card.visible = false
	continue_button.disabled = not _has_valid_save()


func _has_valid_save() -> bool:
	if not FileAccess.file_exists(OneShardSimulation.SAVE_PATH):
		return false
	var file := FileAccess.open(OneShardSimulation.SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return false
	return int(json.data.get("version", 1)) >= 6


func _quit_game() -> void:
	get_tree().quit()


func _skip_tutorial() -> void:
	tutorial_enabled = false
	objectives_expanded = false
	objective_panel.visible = false


func _set_master_volume(value: float) -> void:
	master_volume = value
	_update_volume_label("master", value)
	_apply_audio_levels()
	_save_settings()


func _set_music_volume(value: float) -> void:
	music_volume = value
	_update_volume_label("music", value)
	_save_settings()


func _set_effects_volume(value: float) -> void:
	effects_volume = value
	_update_volume_label("effects", value)
	_save_settings()


func _set_ambience_volume(value: float) -> void:
	ambience_volume = value
	_update_volume_label("ambience", value)
	_apply_audio_levels()
	_save_settings()


func _set_music_muted(value: bool) -> void:
	music_muted = value
	_save_settings()


func _restore_audio_defaults() -> void:
	master_volume = DEFAULT_MASTER_VOLUME
	music_volume = DEFAULT_MUSIC_VOLUME
	effects_volume = DEFAULT_EFFECTS_VOLUME
	ambience_volume = DEFAULT_AMBIENCE_VOLUME
	music_muted = false
	_apply_settings_to_controls()
	_apply_audio_levels()
	_save_settings()


func _update_volume_label(setting_key: String, value: float) -> void:
	if volume_value_labels.has(setting_key):
		volume_value_labels[setting_key].text = "%d%%" % int(round(value * 100.0))


func _apply_audio_levels() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.001)))
	AudioServer.set_bus_mute(0, master_volume <= 0.001)
	if ambience_player != null:
		ambience_player.volume_db = -24.0 + linear_to_db(maxf(ambience_volume, 0.001))


func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	master_volume = clampf(float(parsed.get("master", DEFAULT_MASTER_VOLUME)), 0.0, 1.0)
	music_volume = clampf(float(parsed.get("music", DEFAULT_MUSIC_VOLUME)), 0.0, 1.0)
	effects_volume = clampf(float(parsed.get("effects", DEFAULT_EFFECTS_VOLUME)), 0.0, 1.0)
	ambience_volume = clampf(float(parsed.get("ambience", DEFAULT_AMBIENCE_VOLUME)), 0.0, 1.0)
	music_muted = bool(parsed.get("music_muted", false))
	window_mode_setting = clampi(int(parsed.get("window_mode", 0)), 0, 1)
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if window_mode_setting == 1 else DisplayServer.WINDOW_MODE_WINDOWED
	)


func _save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"version": 1,
		"master": master_volume,
		"music": music_volume,
		"effects": effects_volume,
		"ambience": ambience_volume,
		"music_muted": music_muted,
		"window_mode": window_mode_button.selected if window_mode_button != null else window_mode_setting
	}))


func _apply_settings_to_controls() -> void:
	if master_volume_slider != null:
		master_volume_slider.set_value_no_signal(master_volume)
	if music_volume_slider != null:
		music_volume_slider.set_value_no_signal(music_volume)
	if effects_volume_slider != null:
		effects_volume_slider.set_value_no_signal(effects_volume)
	if ambience_volume_slider != null:
		ambience_volume_slider.set_value_no_signal(ambience_volume)
	if music_mute_button != null:
		music_mute_button.set_pressed_no_signal(music_muted)
	if window_mode_button != null:
		window_mode_button.select(window_mode_setting)
	_update_volume_label("master", master_volume)
	_update_volume_label("music", music_volume)
	_update_volume_label("effects", effects_volume)
	_update_volume_label("ambience", ambience_volume)


func _set_window_mode(index: int) -> void:
	window_mode_setting = clampi(index, 0, 1)
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if window_mode_setting == 1 else DisplayServer.WINDOW_MODE_WINDOWED
	)
	_save_settings()


func _toggle_objectives() -> void:
	objectives_expanded = not objectives_expanded
	objectives_label.visible = objectives_expanded
	tutorial_skip_button.visible = objectives_expanded
	objective_panel.custom_minimum_size = Vector2(610, 198) if objectives_expanded else Vector2(610, 40)


func _update_cursor_feedback() -> void:
	if validation_panel == null:
		return
	validation_panel.custom_minimum_size = Vector2(340, 38)
	validation_panel.size = Vector2(340, 38)
	var active := BUILD_MODES.has(current_mode) or current_mode in [MODE_DEMOLISH, MODE_CLEAR]
	validation_panel.visible = active and not _pointer_over_ui()
	if not active:
		return
	if _pointer_over_ui():
		return
	var mouse := get_viewport().get_mouse_position()
	var panel_size := validation_panel.size
	var viewport_size := get_viewport_rect().size
	validation_panel.position = Vector2(
		clampf(mouse.x + 18.0, 6.0, viewport_size.x - panel_size.x - 6.0),
		clampf(mouse.y + 20.0, 6.0, viewport_size.y - panel_size.y - 6.0)
	)


func _create_summary_panel() -> void:
	summary_panel = _create_panel(Vector2(410, 150), Vector2(460, 360), Color(0.09, 0.1, 0.09, 0.97), GOLD, 7)
	summary_panel.visible = false
	canvas_layer.add_child(summary_panel)
	var margin := _create_margin(summary_panel, 18, 16)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	summary_label = Label.new()
	summary_label.add_theme_color_override("font_color", TEXT_LIGHT)
	summary_label.add_theme_font_size_override("font_size", 16)
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(summary_label)
	content.add_child(_create_action_button("New Run", _new_run))


func _create_event_log_panel() -> void:
	event_log_panel = _create_panel(Vector2(330, 116), Vector2(620, 470), Color(0.075, 0.07, 0.055, 0.985), GOLD, 6)
	event_log_panel.visible = false
	canvas_layer.add_child(event_log_panel)
	var margin := _create_margin(event_log_panel, 14, 12)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	var title := Label.new()
	title.text = "Realm Chronicle"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.42, 1.0))
	title.add_theme_font_size_override("font_size", 17)
	header.add_child(title)
	header.add_child(_create_action_button("Close", _toggle_event_log))
	event_log_text = RichTextLabel.new()
	event_log_text.custom_minimum_size = Vector2(0, 398)
	event_log_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	event_log_text.scroll_active = true
	event_log_text.scroll_following = true
	event_log_text.add_theme_color_override("default_color", TEXT_LIGHT)
	event_log_text.add_theme_font_size_override("normal_font_size", 12)
	content.add_child(event_log_text)


func _create_camera_controls() -> void:
	var panel := _create_panel(Vector2(1162, 552), Vector2(104, 98), PANEL_BG, PANEL_BORDER, 5)
	panel.anchor_left = 1.0
	panel.anchor_top = 1.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -118.0
	panel.offset_top = -240.0
	panel.offset_right = -14.0
	panel.offset_bottom = -142.0
	canvas_layer.add_child(panel)
	var margin := _create_margin(panel, 5, 5)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	margin.add_child(grid)
	var controls := [
		["", Vector2.ZERO], ["\u2191", Vector2.UP], ["", Vector2.ZERO],
		["\u2190", Vector2.LEFT], ["\u25ce", Vector2.ZERO], ["\u2192", Vector2.RIGHT],
		["", Vector2.ZERO], ["\u2193", Vector2.DOWN], ["", Vector2.ZERO]
	]
	for control in controls:
		var label := String(control[0])
		if label == "":
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(28, 25)
			grid.add_child(spacer)
			continue
		var direction: Vector2 = control[1]
		var button := _create_action_button(label, _reset_camera if direction == Vector2.ZERO else _pan_camera.bind(direction))
		button.custom_minimum_size = Vector2(28, 25)
		button.tooltip_text = "Center on Town Hall" if direction == Vector2.ZERO else "Move camera"
		grid.add_child(button)


func _create_panel(position: Vector2, size: Vector2, bg: Color, border: Color, radius: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position
	panel.custom_minimum_size = size
	panel.add_theme_stylebox_override("panel", _create_panel_style(bg, border, radius))
	return panel


func _create_margin(parent: Control, horizontal: int, vertical: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", horizontal)
	margin.add_theme_constant_override("margin_right", horizontal)
	margin.add_theme_constant_override("margin_top", vertical)
	margin.add_theme_constant_override("margin_bottom", vertical)
	parent.add_child(margin)
	return margin


func _create_panel_style(bg_color: Color, border_color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style


func _create_mode_button(label: String, mode: String) -> Button:
	var button := Button.new()
	button.text = label
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(64, 30)
	button.pressed.connect(_set_mode.bind(mode))
	_style_button(button, false)
	return button


func _create_action_button(label: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(62, 28)
	button.pressed.connect(action)
	_style_button(button, false)
	return button


func _style_button(button: Button, active: bool) -> void:
	var bg := Color(0.17, 0.125, 0.075, 0.99)
	var border := Color(0.40, 0.29, 0.15, 0.98)
	var font := TEXT_LIGHT
	if active:
		bg = Color(0.34, 0.255, 0.11, 1.0)
		border = GOLD
		font = Color(1.0, 0.92, 0.63, 1.0)
	button.add_theme_stylebox_override("normal", _create_panel_style(bg, border, 5))
	button.add_theme_stylebox_override("hover", _create_panel_style(bg.lightened(0.08), border, 5))
	button.add_theme_stylebox_override("pressed", _create_panel_style(bg.darkened(0.08), GOLD, 5))
	button.add_theme_stylebox_override("focus", _create_panel_style(bg, GOLD, 5))
	button.add_theme_color_override("font_color", font)
	button.add_theme_color_override("font_hover_color", font)
	button.add_theme_color_override("font_pressed_color", font)
	button.add_theme_font_size_override("font_size", 11)


func _set_mode(mode: String) -> void:
	current_mode = mode
	_sync_mode_buttons()
	_update_ui()
	queue_redraw()


func _sync_mode_buttons() -> void:
	var founding: bool = not simulation.is_town_hall_founded()
	var resources: Dictionary = simulation.get_resources()
	var reserved: Dictionary = simulation.get_reserved_resources()
	var signature := "%s|%s|%s|%d|%s|%s" % [
		current_mode,
		str(founding),
		_active_objective_id(),
		simulation.day_count,
		str(resources),
		str(reserved)
	]
	if signature == last_mode_button_signature:
		return
	last_mode_button_signature = signature
	for mode in mode_buttons.keys():
		var button: Button = mode_buttons[mode]
		if String(mode) == MODE_SELECT:
			button.visible = true
		elif BUILD_MODES.has(String(mode)):
			button.visible = String(mode) != Defs.BUILDING_TOWN_HALL and not founding
			button.disabled = not _build_mode_unlocked(String(mode))
			if button.disabled:
				button.tooltip_text = "%s\nLocked until earlier settlement goals are complete." % _building_tooltip(String(mode))
		else:
			button.visible = not founding
			button.disabled = false
		var active := String(mode) == current_mode
		button.set_pressed_no_signal(active)
		_style_button(button, active)
		button.modulate = Color(1, 1, 1, 0.46) if button.disabled or (BUILD_MODES.has(String(mode)) and not _can_afford_build_mode(String(mode))) else Color.WHITE


func _build_mode_unlocked(building_type: String) -> bool:
	if building_type == Defs.BUILDING_TOWN_HALL:
		return false
	if building_type in [
		Defs.BUILDING_ROAD,
		Defs.BUILDING_HOUSE,
		Defs.BUILDING_LUMBER_CAMP,
		Defs.BUILDING_QUARRY,
		Defs.BUILDING_SAWMILL,
		Defs.BUILDING_STOREHOUSE
	]:
		return true
	if building_type in [Defs.BUILDING_FARM, Defs.BUILDING_BAKERY, Defs.BUILDING_BARRACKS, Defs.BUILDING_WATCHTOWER]:
		return _has_completed_building(Defs.BUILDING_HOUSE) or simulation.day_count >= 2
	if building_type == Defs.BUILDING_WALL:
		return _has_completed_building(Defs.BUILDING_WATCHTOWER)
	if building_type == Defs.BUILDING_LUMEN_PILLAR:
		return _active_objective_id() in ["lumen", "outpost", "claim"] or simulation.day_count >= 2
	if building_type == Defs.BUILDING_OUTPOST:
		return _active_objective_id() in ["outpost", "claim"] or _has_completed_building(Defs.BUILDING_LUMEN_PILLAR)
	return true


func _has_completed_building(building_type: String) -> bool:
	for building in simulation.get_buildings():
		if String(building.get("type", "")) == building_type and not bool(building.get("construction", false)):
			return true
	return false


func _can_afford_build_mode(building_type: String) -> bool:
	var resources: Dictionary = simulation.get_resources()
	var reserved: Dictionary = simulation.get_reserved_resources()
	var cost: Dictionary = Defs.building_cost(building_type)
	for resource_type in cost.keys():
		if int(resources.get(resource_type, 0)) - int(reserved.get(resource_type, 0)) < int(cost[resource_type]):
			return false
	return true


func _save_run() -> void:
	simulation.save_to_file()
	if continue_button != null:
		continue_button.disabled = not _has_valid_save()
	_update_ui()


func _load_run() -> void:
	simulation.load_from_file()
	_invalidate_revealed_tile_cache()
	_reset_camera()
	_update_selected_building_id()
	_update_ui()
	queue_redraw()


func _new_run() -> void:
	# The presentation opening is authored around this deterministic clearing.
	# Keeping New Game on the same seed also guarantees readable resource targets
	# for the first manual order.
	simulation.start_presentation_run(431211)
	_invalidate_revealed_tile_cache()
	selected_tile = Vector2i(-1, -1)
	selected_building_id = 0
	selected_worker_id = 0
	opening_worker_id = simulation.get_presentation_worker_id()
	opening_intro_active = true
	opening_intro_stage = 0
	opening_intro_timer = 0.0
	opening_door_open = 0.0
	objective_intro_visible = false
	_reset_camera()
	paused = false
	summary_panel.visible = false
	event_log_panel.visible = false
	_set_mode(MODE_SELECT)
	_refresh_static_world_if_needed(true)


func _toggle_pause() -> void:
	paused = not paused
	if pause_menu_root != null:
		pause_menu_root.visible = paused
	_update_ui()


func _toggle_event_log() -> void:
	event_log_panel.visible = not event_log_panel.visible
	if event_log_panel.visible:
		_update_event_log()


func _request_claim() -> void:
	simulation.request_player_claim()
	_update_ui()
	queue_redraw()


func _toggle_rivalry_debug() -> void:
	rivalry_debug_visible = not rivalry_debug_visible
	debug_panel.visible = rivalry_debug_visible
	if simulation.rivalry != null:
		simulation.rivalry.set_debug_enabled(rivalry_debug_visible)
	_update_ui()


func _update_visual_modes(delta: float) -> void:
	if night_overlay == null or shard_overlay == null or simulation.rivalry == null:
		return
	var night_target := 0.58 if simulation.is_night else 0.0
	var day_remaining: float = OneShardSimulation.DAY_LENGTH_SECONDS - float(simulation.phase_time)
	if not simulation.is_night and day_remaining <= OneShardSimulation.NIGHT_WARNING_SECONDS:
		night_target = 0.16
	var night_alpha := move_toward(night_overlay.color.a, night_target, delta * 0.55)
	night_overlay.color = Color(0.018, 0.035, 0.10, night_alpha)
	if ambience_player != null:
		var ambience_target := (-19.0 if simulation.is_night else -24.0) + linear_to_db(maxf(ambience_volume, 0.001))
		ambience_player.volume_db = move_toward(ambience_player.volume_db, ambience_target, delta * 4.0)
	var sovereign: Dictionary = simulation.rivalry.get_sovereign(RivalryTuning.PLAYER_REALM)
	if sovereign.is_empty():
		return
	var distance := Vector2(sovereign.get("position", Vector2.ZERO)).distance_to(Vector2(simulation.shard_position))
	var now_near := distance <= 11.0
	var shard_target := 0.15 if now_near else 0.0
	var shard_alpha := move_toward(shard_overlay.color.a, shard_target, delta * 0.24)
	shard_overlay.color = Color(0.11, 0.025, 0.19, shard_alpha)
	if now_near and not shard_proximity_active:
		pre_shard_zoom = camera.zoom.x
		shard_proximity_active = true
	elif not now_near and shard_proximity_active:
		shard_proximity_active = false
	var target_zoom := clampf(pre_shard_zoom * 1.10, MIN_ZOOM, MAX_ZOOM) if shard_proximity_active else pre_shard_zoom
	var next_zoom := lerpf(camera.zoom.x, target_zoom, clampf(delta * 1.7, 0.0, 1.0))
	camera.zoom = Vector2(next_zoom, next_zoom)


func _update_rivalry_debug_text() -> void:
	if debug_label == null or not rivalry_debug_visible or simulation.rivalry == null:
		return
	var snapshot: Dictionary = simulation.rivalry.get_debug_snapshot()
	var knowledge_position: Vector2 = snapshot.get("ai_known_player_position", Vector2(-999, -999))
	var player_claim: Dictionary = snapshot.get("player_claim", {})
	var ai_claim: Dictionary = snapshot.get("ai_claim", {})
	var player_requirements: Dictionary = player_claim.get("requirements", {})
	var ai_requirements: Dictionary = ai_claim.get("requirements", {})
	var failures: Array = snapshot.get("navigation_failures", [])
	var last_failure := "None" if failures.is_empty() else String(failures.back())
	debug_label.text = "\n".join(PackedStringArray([
		"RIVALRY DEBUG  [F3]",
		"State: %s" % String(snapshot.get("match_state", "")),
		"AI goal: %s -> %s" % [String(snapshot.get("ai_goal", "")), str(snapshot.get("ai_goal_target", Vector2i(-1, -1)))],
		"Known player: %s  age %.1fs" % [str(knowledge_position), float(snapshot.get("ai_known_player_position_age", 0.0))],
		"Roads: player %d | rival %d" % [int(snapshot.get("player_roads", 0)), int(snapshot.get("ai_roads", 0))],
		"Lumen: player %d | rival %d" % [int(snapshot.get("player_lumen_sources", 0)), int(snapshot.get("ai_lumen_sources", 0))],
		"Player claim: %s" % String(player_requirements.get("summary", "No outpost")),
		"Rival claim: %s" % String(ai_requirements.get("summary", "No outpost")),
		"Player realm: %s" % str(snapshot.get("player_resources", {})),
		"Rival realm: %s" % str(snapshot.get("ai_resources", {})),
		"Phase timer: %.1f" % simulation.phase_time,
		"Navigation: %s" % last_failure
	]))


func _cycle_speed() -> void:
	if simulation_speed < 1.5:
		simulation_speed = 2.0
	elif simulation_speed < 3.0:
		simulation_speed = 4.0
	else:
		simulation_speed = 1.0
	_update_ui()


func _restaff_selected() -> void:
	if selected_building_id > 0:
		simulation.restaff_building(selected_building_id)
	_update_ui()
	queue_redraw()


func _cycle_priority_selected() -> void:
	if selected_building_id > 0:
		simulation.cycle_staff_priority(selected_building_id)
	_update_ui()
	queue_redraw()


func _update_selected_building_id() -> void:
	var building: Dictionary = simulation.get_building_at_tile(selected_tile)
	selected_building_id = int(building.get("id", 0)) if not building.is_empty() else 0


func _update_ui() -> void:
	ui_update_count += 1
	if simulation.is_town_hall_founded() and current_mode == Defs.BUILDING_TOWN_HALL:
		current_mode = MODE_SELECT
	var resources: Dictionary = simulation.get_resources()
	var raider_text := "  ⚔ %d" % simulation.enemies.size() if simulation.is_night or not simulation.enemies.is_empty() else ""
	var lumen_text := "✦ Stable" if simulation.protection_powered else "✦ Fading"
	resources_label.text = "%s%s    ♣ %d    ◇ %d    ▰ %d    ◆ %d    ☻ %d/%d    ✧ %d    %s" % [
		simulation.get_time_label(),
		raider_text,
		int(resources.get(Defs.RESOURCE_WOOD, 0)),
		int(resources.get(Defs.RESOURCE_STONE, 0)),
		int(resources.get(Defs.RESOURCE_PLANKS, 0)),
		simulation.get_food_units(),
		int(resources.get(Defs.RESOURCE_POPULATION_USED, 0)),
		int(resources.get(Defs.RESOURCE_POPULATION_MAX, 0)),
		int(resources.get(Defs.RESOURCE_WYRD, 0)),
		lumen_text
	]
	objectives_label.text = _format_objectives()
	if objective_button != null:
		objective_button.text = "◆  %s  %s" % [_active_objective_text(), "▾" if objectives_expanded else "▸"]
	objective_panel.visible = game_started and tutorial_enabled and (objective_intro_visible or not opening_intro_active)
	log_label.text = _format_log()
	_update_event_log()

	var selected_worker: Dictionary = simulation.get_worker_by_id(selected_worker_id)
	var selected_building: Dictionary = simulation.get_building_by_id(selected_building_id)
	if selected_worker_id > 0 and selected_worker.is_empty():
		selected_worker_id = 0
	if not selected_worker.is_empty():
		selection_portrait.texture = _settler_portrait_texture()
		selection_name_label.text = "Settler"
		selection_state_label.text = String(selected_worker.get("state", "Awaiting order"))
		var carried := int(selected_worker.get("carried_amount", 0))
		selection_task_label.text = (
			"Carrying %d %s" % [carried, Defs.resource_name(String(selected_worker.get("carried_resource", "")))]
			if carried > 0
			else "Right-click ground to move; a resource to gather."
		)
	elif not selected_building.is_empty():
		var building_type := String(selected_building.get("planned_type", selected_building.get("type", "")))
		if building_type == "":
			building_type = String(selected_building.get("type", ""))
		selection_portrait.texture = _building_thumbnail(building_type)
		selection_name_label.text = Defs.building_name(building_type)
		selection_state_label.text = String(selected_building.get("status", "Ready."))
		selection_task_label.text = _building_tooltip(building_type).replace("\n", " • ")
	else:
		selection_portrait.texture = TOWN_HALL_TEXTURE
		selection_name_label.text = "The New Realm"
		selection_state_label.text = "One Town Hall. One settler."
		selection_task_label.text = "Select a settler or structure for commands."

	restaff_button.visible = _selected_building_needs_restaff()
	priority_button.visible = not selected_building.is_empty() and not bool(selected_building.get("construction", false)) and Defs.building_staff(String(selected_building.get("type", ""))) > 0
	if priority_button.visible:
		priority_button.text = "Priority: %s" % simulation.staff_priority_name(int(selected_building.get("staff_priority", OneShardSimulation.STAFF_PRIORITY_NORMAL)))
	speed_button.text = "%d×" % int(simulation_speed)
	validation_label.text = _format_validation()
	_update_rivalry_debug_text()
	_sync_mode_buttons()
	_update_summary_panel()


func _settler_portrait_texture() -> Texture2D:
	var portrait := AtlasTexture.new()
	portrait.atlas = SETTLER_WALK_TEXTURE
	portrait.region = Rect2(Vector2(SETTLER_FRAME_SIZE.x, 0.0), SETTLER_FRAME_SIZE)
	return portrait


func _active_objective_text() -> String:
	for objective in simulation.get_objectives():
		if not bool(objective.get("complete", false)):
			return String(objective.get("text", "Build your settlement."))
	return "Claim the Shard before your rival."


func _compact_claim_label() -> String:
	var meal_text := "Meals %d/%d" % [simulation.get_food_units(), simulation.get_next_food_demand()]
	if simulation.rivalry == null:
		return meal_text
	var player_claim: Dictionary = simulation.rivalry.get_claim_status(RivalryTuning.PLAYER_REALM)
	var rival_claim: Dictionary = simulation.rivalry.get_claim_status(RivalryTuning.AI_REALM)
	var parts: Array[String] = [meal_text]
	if bool(player_claim.get("active", false)):
		var progress := float(player_claim.get("night_progress", 0.0)) / OneShardSimulation.NIGHT_LENGTH_SECONDS
		parts.append("Your claim %d%%" % int(round(progress * 100.0)))
	else:
		parts.append("Your claim: not begun")
	if bool(rival_claim.get("active", false)):
		var rival_progress := float(rival_claim.get("night_progress", 0.0)) / OneShardSimulation.NIGHT_LENGTH_SECONDS
		parts.append("RIVAL CLAIM %d%%" % int(round(rival_progress * 100.0)))
	return " | ".join(parts)


func _rival_claim_is_dangerous() -> bool:
	if simulation.rivalry == null:
		return false
	var rival_claim: Dictionary = simulation.rivalry.get_claim_status(RivalryTuning.AI_REALM)
	return bool(rival_claim.get("active", false))


func _update_event_log() -> void:
	if event_log_text == null:
		return
	var entries: Array[String] = simulation.get_log_entries()
	event_log_text.text = "No events recorded yet." if entries.is_empty() else "\n\n".join(entries)


func _current_banner_text() -> String:
	if BUILD_MODES.has(current_mode):
		return "%s: %s" % [Defs.building_name(current_mode), _format_validation()]
	if current_mode == MODE_DEMOLISH:
		return "Demolish: click a non-Town Hall building."
	if current_mode == MODE_CLEAR:
		return "Clear land: %s" % _format_validation()
	if simulation.rivalry != null:
		var rival_claim: Dictionary = simulation.rivalry.get_claim_status(RivalryTuning.AI_REALM)
		if bool(rival_claim.get("active", false)):
			var rival_progress := float(rival_claim.get("night_progress", 0.0)) / OneShardSimulation.NIGHT_LENGTH_SECONDS
			return "DANGER — RIVAL CLAIM %d%%. Move to the Shard and contest its Sovereign before dawn." % int(round(rival_progress * 100.0))
		var sovereign: Dictionary = simulation.rivalry.get_sovereign(RivalryTuning.PLAYER_REALM)
		if not bool(sovereign.get("alive", true)):
			return "Sovereign incapacitated — returns at the Town Hall in %.0f seconds." % float(sovereign.get("respawn_remaining", 0.0))
		if bool(sovereign.get("extracting", false)):
			var extraction_fraction := float(sovereign.get("extraction_progress", 0.0)) / RivalryTuning.WYRD_EXTRACTION_SECONDS
			return "Extracting Wyrd: %d%%. Taking damage interrupts it." % int(round(extraction_fraction * 100.0))
		var shard_distance := Vector2(sovereign.get("position", Vector2.ZERO)).distance_to(Vector2(simulation.shard_position))
		if shard_distance <= 11.0:
			var claim: Dictionary = simulation.rivalry.get_claim_status(RivalryTuning.PLAYER_REALM)
			return "Inside the Shard region • E extract • Q attack • C claim • %s" % String(claim.get("status", "Build your Claimant Outpost."))
	if simulation.is_night:
		return "NIGHT RAID — %d raiders are attacking. Civilians shelter while guards defend the settlement." % simulation.enemies.size()
	var day_remaining: float = OneShardSimulation.DAY_LENGTH_SECONDS - float(simulation.phase_time)
	if day_remaining <= OneShardSimulation.NIGHT_FINAL_WARNING_SECONDS:
		return "NIGHTFALL IMMINENT — civilians are returning home. Prepare your defenses."
	if day_remaining <= OneShardSimulation.NIGHT_WARNING_SECONDS:
		return "DUSK — night falls in %d seconds. Workers will soon return home." % int(ceil(day_remaining))
	if simulation.is_hunger_penalty_active():
		return "%d hungry settlers: affected workplaces produce half output." % simulation.get_hungry_population()
	var last_message: String = simulation.get_last_message()
	if not last_message.begins_with("Extend the road"):
		return last_message
	var active_objective := _active_objective_id()
	if active_objective == "road":
		return "Extend the entrance Road where the waiting carrier is standing."
	if active_objective == "lumber":
		return "Build a Lumber Camp near trees and connect it by road."
	if active_objective == "wyrd":
		return "Move your Sovereign to a blue Wyrd spring and press E to extract."
	if active_objective == "lumen":
		return "Build paid, road-connected Lumen Pillars toward the central Shard."
	if active_objective == "outpost":
		return "Connect road and active Lumen, then build a Claimant Outpost in the Shard ring."
	if active_objective == "claim":
		return "Bring your Sovereign into the Shard ring, press C, and hold every condition through the night."
	return last_message


func _active_objective_id() -> String:
	for objective in simulation.get_objectives():
		if not bool(objective["complete"]):
			return String(objective["id"])
	return ""


func _has_selected_tile() -> bool:
	return simulation.is_inside_map(selected_tile)


func _format_objectives() -> String:
	var lines := PackedStringArray(["Objectives"])
	var active_id: String = _active_objective_id()
	for objective in simulation.get_objectives():
		var mark := "[x]" if bool(objective["complete"]) else "[ ]"
		var prefix := "> " if String(objective["id"]) == active_id else "  "
		lines.append("%s%s %s" % [prefix, mark, String(objective["text"])])
	return "\n".join(lines)


func _format_log() -> String:
	var lines := PackedStringArray(["Realm Log"])
	var entries: Array[String] = simulation.get_log_entries()
	var start_index: int = max(0, entries.size() - 4)
	for index in range(start_index, entries.size()):
		var entry: String = entries[index]
		lines.append("- %s" % entry)
	return "\n".join(lines)


func _format_info_panel() -> String:
	var lines := PackedStringArray()
	if not simulation.is_inside_map(selected_tile):
		return ""

	if not simulation.is_revealed(selected_tile):
		lines.append("Unscouted land")
		lines.append("Extend a road or protected structure nearby to reveal it.")
		return "\n".join(lines)

	var building: Dictionary = simulation.get_building_at_tile(selected_tile)
	if building.is_empty():
		if simulation.rivalry != null:
			var rivalry_structure: Dictionary = simulation.rivalry.get_structure_at_tile(selected_tile)
			if not rivalry_structure.is_empty():
				var realm_name := "Your realm" if String(rivalry_structure.get("realm_id", "")) == RivalryTuning.PLAYER_REALM else "Rival realm"
				lines.append(RivalryTuning.structure_name(String(rivalry_structure.get("type", ""))))
				lines.append("Owner: %s" % realm_name)
				lines.append("HP: %d/%d" % [int(rivalry_structure.get("hp", 0)), int(rivalry_structure.get("max_hp", 0))])
				if String(rivalry_structure.get("type", "")) == RivalryTuning.STRUCTURE_LUMEN_PILLAR:
					lines.append("Purpose: extends your claim-power network.")
					lines.append("Connect Pillars toward the Shard Outpost.")
					lines.append("Lumen: %s" % ("Active and connected" if bool(rivalry_structure.get("active", false)) and bool(rivalry_structure.get("connected", false)) else "Inactive or disconnected"))
					lines.append("Upkeep: %d Wyrd each night" % RivalryTuning.LUMEN_NIGHTLY_UPKEEP)
					lines.append("Does not block raiders.")
				else:
					lines.append("Protection bubble: %d tiles" % int(OneShardSimulation.OUTPOST_PROTECTION_RADIUS))
					lines.append("Wyrd node: %s" % ("Harvesting 1 Wyrd every %ds" % int(OneShardSimulation.WYRD_OUTPOST_HARVEST_SECONDS) if simulation.outpost_has_wyrd_node(rivalry_structure) else "None within 3 tiles"))
					var claim_status: Dictionary = simulation.rivalry.get_claim_status(String(rivalry_structure.get("realm_id", "")))
					lines.append("Claim: %s" % String(claim_status.get("status", "Not begun")))
				return "\n".join(lines)
		lines.append(_terrain_label(String(simulation.get_tile(selected_tile))))
		if simulation.get_tile(selected_tile) == Defs.TILE_TREE:
			lines.append("Harvestable by a nearby Lumber Camp.")
			lines.append("Wood remaining: %d" % simulation.get_deposit_remaining(selected_tile))
		elif simulation.get_tile(selected_tile) == Defs.TILE_ROCK:
			lines.append("Quarry deposits can produce Stone.")
			lines.append("Stone remaining: %d" % simulation.get_deposit_remaining(selected_tile))
		elif simulation.get_tile(selected_tile) == Defs.TILE_GRASS:
			lines.append("Clear land for roads and buildings.")
		return "\n".join(lines)

	var building_type := String(building["type"])
	if bool(building.get("construction", false)):
		lines.append("%s Site" % Defs.building_name(String(building["planned_type"])))
		lines.append("Road: %s" % ("Connected" if bool(building["connected"]) else "Not connected"))
		lines.append("HP: %d/%d" % [int(building["hp"]), int(building["max_hp"])])
		lines.append("Materials: %s" % _format_material_delivery(building))
		lines.append("Progress: %d%%" % int(round(_construction_fraction(building) * 100.0)))
	else:
		lines.append(Defs.building_name(building_type))
		lines.append("Purpose: %s" % _building_purpose(building_type))
		lines.append("Built for: %s" % Defs.formatted_cost(building_type))
		lines.append("Road: %s" % ("Connected" if bool(building["connected"]) else "Not connected"))
		if building_type not in [Defs.BUILDING_ROAD, Defs.BUILDING_WALL]:
			lines.append("Night safety: %s" % ("Inside Lumen" if simulation.is_tile_protected(building["position"]) else "Exposed — workers flee at dusk"))
		if Defs.building_staff(building_type) > 0:
			lines.append("Staff: %d/%d" % [_staff_count(building), Defs.building_staff(building_type)])
			lines.append("Priority: %s" % simulation.staff_priority_name(int(building.get("staff_priority", OneShardSimulation.STAFF_PRIORITY_NORMAL))))
		if Defs.adds_population(building_type) > 0:
			lines.append("Housing: +%d capacity" % Defs.adds_population(building_type))
			lines.append("Arrival: 1 Bread or 2 Wheat every 10s")
		var production_text := _production_summary(building_type)
		if production_text != "":
			lines.append("Production: %s" % production_text)
		if building_type == Defs.BUILDING_WATCHTOWER:
			lines.append("Soldier: %d/1" % int(building.get("soldiers_assigned", 0)))
			lines.append("Defense: %d damage, %d tile range" % [OneShardSimulation.TOWER_DAMAGE, OneShardSimulation.TOWER_RANGE])
			lines.append("Protection bubble: %d tiles" % int(OneShardSimulation.TOWER_PROTECTION_RADIUS))
		if building_type == Defs.BUILDING_TOWN_HALL:
			lines.append("Protection bubble: %d tiles" % int(OneShardSimulation.TOWN_HALL_PROTECTION_RADIUS))
			lines.append("Wyrd drain at night: %.2f per minute" % simulation.get_wyrd_upkeep_per_minute())
		if building_type == Defs.BUILDING_STOREHOUSE:
			var bonuses := PackedStringArray()
			for resource_type in Defs.RESOURCE_TYPES:
				var bonus := int(Defs.STOREHOUSE_BONUS.get(resource_type, 0))
				if bonus > 0:
					bonuses.append("+%d %s" % [bonus, Defs.resource_name(resource_type)])
			lines.append("Capacity added: %s." % ", ".join(bonuses))
		if building_type == Defs.BUILDING_BARRACKS:
			lines.append("Training: one free recruit and %d Bread per soldier." % OneShardSimulation.SOLDIER_BREAD_COST)
		if building_type == Defs.BUILDING_QUARRY:
			lines.append("Deposit: %d Stone remaining" % int(building.get("deposit_remaining", 0)))
		if building_type == Defs.BUILDING_ROAD:
			lines.append("Travel: workers and enemies move %d%% faster" % int(round((1.0 / OneShardSimulation.ROAD_MOVE_MULTIPLIER - 1.0) * 100.0)))
		var local_inventory: Dictionary = building.get("local_inventory", {})
		if int(building.get("local_capacity", 0)) > 0:
			lines.append("Stored here: %s (%d/%d)" % [_format_inventory(local_inventory), _inventory_total(local_inventory), int(building.get("local_capacity", 0))])
		lines.append("HP: %d/%d" % [int(building["hp"]), int(building["max_hp"])])
	lines.append("Status: %s" % _actionable_building_status(building))
	return "\n".join(lines)


func _format_material_delivery(building: Dictionary) -> String:
	var needed: Dictionary = building.get("materials_needed", {})
	var delivered: Dictionary = building.get("materials_delivered", {})
	var parts := PackedStringArray()
	for resource_type in needed.keys():
		parts.append("%s %d/%d" % [Defs.resource_name(String(resource_type)), int(delivered.get(resource_type, 0)), int(needed.get(resource_type, 0))])
	return ", ".join(parts) if not parts.is_empty() else "Ready"


func _format_inventory(inventory: Dictionary) -> String:
	var parts := PackedStringArray()
	for resource_type in Defs.RESOURCE_TYPES:
		var amount := int(inventory.get(resource_type, 0))
		if amount > 0:
			parts.append("%s %d" % [Defs.resource_name(resource_type), amount])
	return ", ".join(parts) if not parts.is_empty() else "Empty"


func _inventory_total(inventory: Dictionary) -> int:
	var total := 0
	for resource_type in Defs.RESOURCE_TYPES:
		total += int(inventory.get(resource_type, 0))
	return total


func _terrain_label(tile_type: String) -> String:
	if tile_type == Defs.TILE_TREE:
		return "Forest"
	if tile_type == Defs.TILE_ROCK:
		return "Rock Deposit"
	if tile_type == Defs.TILE_SHARD:
		return "The Shard"
	return "Grassland"


func _format_validation() -> String:
	if current_mode == MODE_SELECT:
		return "Select a tile to inspect roads, staff, inventory, and damage."
	if current_mode == MODE_DEMOLISH:
		return "Demolish mode: click a non-Town Hall building."
	if current_mode == MODE_CLEAR:
		if not simulation.is_inside_map(hovered_tile):
			return "Clear: choose a tree or rock tile."
		return String(simulation.validate_clear(hovered_tile).get("message", ""))
	if not BUILD_MODES.has(current_mode):
		return ""
	if not simulation.is_inside_map(hovered_tile):
		return "%s: choose a tile." % Defs.building_name(current_mode)
	var validation: Dictionary = simulation.validate_placement(current_mode, hovered_tile, placement_rotation)
	return String(validation["message"]) if current_mode == Defs.BUILDING_ROAD else "%s  •  R rotates" % String(validation["message"])


func _production_summary(building_type: String) -> String:
	if not Defs.PRODUCTION_DEFS.has(building_type):
		return ""
	var definition: Dictionary = Defs.PRODUCTION_DEFS[building_type]
	var interval := float(definition.get("interval", 0.0))
	var output := String(definition.get("output", ""))
	var output_amount := int(definition.get("output_amount", 0))
	if definition.has("input"):
		return "-%d %s, +%d %s / %.0fs" % [
			int(definition.get("input_amount", 0)),
			Defs.resource_name(String(definition.get("input", ""))),
			output_amount,
			Defs.resource_name(output),
			interval
		]
	return "+%d %s / %.0fs" % [output_amount, Defs.resource_name(output), interval]


func _building_purpose(building_type: String) -> String:
	var purposes := {
		Defs.BUILDING_TOWN_HALL: "Founding hub, central storage and Lumen shelter.",
		Defs.BUILDING_ROAD: "Connects logistics and speeds all travel.",
		Defs.BUILDING_HOUSE: "Adds five beds and shelters civilians at night.",
		Defs.BUILDING_LUMBER_CAMP: "Harvests nearby trees into local Wood.",
		Defs.BUILDING_QUARRY: "Extracts Stone from its rock deposit.",
		Defs.BUILDING_SAWMILL: "Turns delivered Wood into Planks.",
		Defs.BUILDING_FARM: "Grows Wheat for food production.",
		Defs.BUILDING_BAKERY: "Turns delivered Wheat into Bread.",
		Defs.BUILDING_STOREHOUSE: "Expands central resource capacity.",
		Defs.BUILDING_WALL: "Blocks raiders and anchors a defensive gate.",
		Defs.BUILDING_WATCHTOWER: "Soldier-manned ranged defense and Lumen shelter.",
		Defs.BUILDING_BARRACKS: "Trains settlers into soldiers.",
		Defs.BUILDING_LUMEN_PILLAR: "Extends protected claim power toward the Shard.",
		Defs.BUILDING_OUTPOST: "Anchors the final Shard claim."
	}
	return String(purposes.get(building_type, "Supports the settlement."))


func _actionable_building_status(building: Dictionary) -> String:
	var building_type := String(building.get("type", ""))
	if bool(building.get("construction", false)):
		if not bool(building.get("connected", false)):
			return "Waiting — connect this site to the Town Hall road."
		return String(building.get("status", "Waiting for carrier deliveries."))
	if building_type != Defs.BUILDING_TOWN_HALL and not bool(building.get("connected", false)):
		return "Stopped — connect it to the Town Hall road network."
	if bool(building.get("abandoned", false)) or (
		Defs.building_staff(building_type) > 0
		and int(building.get("assigned_staff", 0)) < Defs.building_staff(building_type)
	):
		return "Stopped — build housing or use Restaff when a settler is free."
	if bool(building.get("storage_paused", false)):
		return "Stopped — storage is full; add a Storehouse or free capacity."
	if Defs.PROCESSOR_INPUTS.has(building_type):
		var input_resource := String(Defs.PROCESSOR_INPUTS[building_type])
		var inventory: Dictionary = building.get("local_inventory", {})
		if int(inventory.get(input_resource, 0)) <= 0:
			return "Stopped — no %s delivered; check its producer and road." % Defs.resource_name(input_resource)
	return String(building.get("status", "Ready."))


func _staff_state(building: Dictionary) -> String:
	if bool(building.get("abandoned", false)):
		return "Abandoned"
	if int(building.get("assigned_staff", 0)) >= Defs.building_staff(String(building["type"])):
		return "Staffed"
	return "Needs workers"


func _staff_count(building: Dictionary) -> int:
	if bool(building.get("abandoned", false)):
		return 0
	return int(building.get("assigned_staff", 0))


func _selected_building_needs_restaff() -> bool:
	if selected_building_id <= 0:
		return false
	var building: Dictionary = simulation.get_building_by_id(selected_building_id)
	if building.is_empty():
		return false
	if String(building.get("type", "")) == Defs.BUILDING_WATCHTOWER:
		return int(building.get("soldiers_assigned", 0)) <= 0
	return Defs.building_staff(String(building.get("type", ""))) > int(building.get("assigned_staff", 0))


func _update_summary_panel() -> void:
	if not simulation.game_finished:
		summary_panel.visible = false
		return
	var summary: Dictionary = simulation.get_summary()
	var title := "Sovereignty Claimed!" if bool(summary["victory"]) else "The Realm Has Fallen."
	var lines := PackedStringArray([
		title,
		String(summary.get("defeat_reason", "")),
		"",
		"Score: %d" % int(summary["score"]),
		"Best: %d" % int(summary["best_score"]),
		"Days survived: %d" % int(summary["days_survived"]),
		"Buildings completed: %d" % int(summary["buildings_completed"]),
		"Enemies defeated: %d" % int(summary["enemies_defeated"]),
		"Workers lost: %d" % int(summary.get("workers_lost", 0)),
		"Hungry nights: %d" % int(summary.get("hungry_nights", 0)),
		"Buildings abandoned: %d" % int(summary["buildings_abandoned"]),
		"Buildings destroyed: %d" % int(summary["buildings_destroyed"]),
		"Shard claimed: %s" % ("Yes" if bool(summary["shard_claimed"]) else "No")
	])
	summary_label.text = "\n".join(lines)
	summary_panel.visible = true


func _draw_map_background() -> void:
	var bounds := _map_bounds()
	draw_rect(bounds.grow(max(TILE_WIDTH, TILE_HEIGHT) * 2.2), Color(0.025, 0.055, 0.045, 1.0), true)


func _draw_tiles() -> void:
	_refresh_revealed_tile_cache()
	_refresh_active_chop_tiles()
	for tile in cached_revealed_tiles:
		if not _is_world_visible(tile_to_world(tile), 120.0):
			continue
		var top_color := _terrain_color(tile, true)
		var center := tile_to_world(tile)
		_draw_terrain_cliffs(tile, true, top_color)
		var polygon := _tile_polygon(tile)
		draw_colored_polygon(polygon, top_color)
		_draw_polygon_outline(polygon, Color(0.02, 0.06, 0.025, 0.22), 0.65)
		_draw_ground_details(tile, center)
		_draw_terrain_feature(tile)


func _refresh_revealed_tile_cache() -> void:
	var revealed_count: int = simulation.revealed_tiles.size()
	if cached_revealed_count == revealed_count:
		return
	cached_revealed_tiles.clear()
	for key in simulation.revealed_tiles.keys():
		cached_revealed_tiles.append(simulation._tile_from_key(String(key)))
	cached_revealed_tiles.sort_custom(_tile_draw_order)
	cached_revealed_count = revealed_count


func _refresh_active_chop_tiles() -> void:
	active_chop_tiles.clear()
	for worker in simulation.get_workers():
		if String(worker.get("type", "")) not in ["woodcutter", "clearer"]:
			continue
		var position: Vector2i = worker.get("position", Vector2i(-1, -1))
		for offset in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			active_chop_tiles[simulation._tile_key(position + offset)] = true


func _invalidate_revealed_tile_cache() -> void:
	cached_revealed_tiles.clear()
	cached_revealed_count = -1
	static_world_signature = ""
	if static_world != null:
		static_world.queue_redraw()


func _tile_draw_order(first: Vector2i, second: Vector2i) -> bool:
	return first.y < second.y or (first.y == second.y and first.x < second.x)


func _draw_terrain_cliffs(tile: Vector2i, revealed: bool, top_color: Color) -> void:
	var polygon := _tile_polygon(tile)
	var current_height: int = simulation.get_height(tile)
	var east := tile + Vector2i.RIGHT
	var south := tile + Vector2i.DOWN
	var east_height: int = simulation.get_height(east) if simulation.is_inside_map(east) else 0
	var south_height: int = simulation.get_height(south) if simulation.is_inside_map(south) else 0
	if current_height > east_height:
		var down := Vector2(0, float(current_height - east_height) * HEIGHT_STEP)
		var face := PackedVector2Array([polygon[1], polygon[2], polygon[2] + down, polygon[1] + down])
		draw_colored_polygon(face, top_color.darkened(0.34 if revealed else 0.5))
		_draw_polygon_outline(face, Color(0.03, 0.04, 0.025, 0.42), 0.8)
	if current_height > south_height:
		var down := Vector2(0, float(current_height - south_height) * HEIGHT_STEP)
		var face := PackedVector2Array([polygon[2], polygon[3], polygon[3] + down, polygon[2] + down])
		draw_colored_polygon(face, top_color.darkened(0.23 if revealed else 0.45))
		_draw_polygon_outline(face, Color(0.03, 0.04, 0.025, 0.4), 0.8)


func _draw_ground_details(tile: Vector2i, center: Vector2) -> void:
	if simulation.get_tile(tile) != Defs.TILE_GRASS or simulation.is_tile_occupied(tile):
		return
	var pattern := absi(tile.x * 37 + tile.y * 61 + tile.x * tile.y * 7)
	if pattern % 5 == 0:
		var tuft := center + Vector2(float((pattern % 17) - 8), float((pattern % 9) - 4))
		draw_line(tuft, tuft + Vector2(-2, -4), Color(0.24, 0.42, 0.2, 0.72), 1.0)
		draw_line(tuft, tuft + Vector2(2, -3), Color(0.34, 0.52, 0.24, 0.72), 1.0)
	if pattern % 8 == 0:
		var blades := center + Vector2(float((pattern % 21) - 10), float((pattern % 11) - 5))
		draw_circle(blades, 1.0, Color(0.1, 0.24, 0.1, 0.55))
	if pattern % 23 == 0:
		var flower := center + Vector2(float((pattern % 13) - 6), float((pattern % 7) - 3))
		draw_circle(flower, 1.2, Color(0.92, 0.78, 0.38, 0.82))


func _draw_guidance_overlays() -> void:
	pass


func _draw_terrain_feature(tile: Vector2i) -> void:
	var terrain: String = simulation.get_tile(tile)
	if terrain == Defs.TILE_TREE:
		_draw_tree(tile, tile_to_object_base(tile))
	elif terrain == Defs.TILE_ROCK:
		_draw_rock(tile_to_object_base(tile))
	elif terrain == Defs.TILE_SHARD:
		_draw_shard(tile_to_object_base(tile))


func _draw_build_preview() -> void:
	if not BUILD_MODES.has(current_mode) or not simulation.is_inside_map(hovered_tile):
		return
	var validation: Dictionary = simulation.validate_placement(current_mode, hovered_tile, placement_rotation)
	var color := VALID_GREEN if bool(validation["success"]) else INVALID_RED
	var footprint: Vector2i = simulation._oriented_footprint(current_mode, placement_rotation)
	for y in range(footprint.y):
		for x in range(footprint.x):
			var tile := hovered_tile + Vector2i(x, y)
			if not simulation.is_inside_map(tile):
				continue
			draw_colored_polygon(_tile_polygon(tile), color)
			_draw_polygon_outline(_tile_polygon(tile), Color(color.r, color.g, color.b, 1.0), 1.5)
	if bool(validation["success"]) and current_mode == Defs.BUILDING_ROAD:
		_draw_road(hovered_tile, true, 0.58)
	elif current_mode == Defs.BUILDING_TOWN_HALL and bool(validation["success"]):
		var town_footprint := Defs.building_footprint(Defs.BUILDING_TOWN_HALL)
		var town_center_tile := Vector2(hovered_tile) + Vector2(float(town_footprint.x - 1) * 0.5, float(town_footprint.y - 1) * 0.5)
		var town_center := tile_position_to_world(town_center_tile, Vector2i(roundi(town_center_tile.x), roundi(town_center_tile.y))) + Vector2(0, TILE_HEIGHT * 0.58)
		draw_texture(TOWN_HALL_TEXTURE, town_center - Vector2(TOWN_HALL_TEXTURE.get_width() * 0.5, TOWN_HALL_TEXTURE.get_height() - 6.0), Color(0.65, 0.9, 1.0, 0.58))
	elif current_mode == Defs.BUILDING_LUMEN_PILLAR:
		var pillar_base := tile_to_object_base(hovered_tile)
		draw_texture(
			LUMEN_PILLAR_TEXTURE,
			pillar_base - Vector2(LUMEN_PILLAR_TEXTURE.get_width() * 0.5, LUMEN_PILLAR_TEXTURE.get_height() - 5.0),
			Color(0.64, 0.9, 1.0, 0.72 if bool(validation["success"]) else 0.34)
		)
	elif current_mode == Defs.BUILDING_OUTPOST:
		var outpost_footprint := Defs.building_footprint(Defs.BUILDING_OUTPOST)
		var center_tile := Vector2(hovered_tile) + Vector2(float(outpost_footprint.x - 1) * 0.5, float(outpost_footprint.y - 1) * 0.5)
		var center_world := tile_position_to_world(center_tile, Vector2i(roundi(center_tile.x), roundi(center_tile.y))) + Vector2(0, TILE_HEIGHT * 0.58)
		draw_texture(
			OUTPOST_TEXTURE,
			center_world - Vector2(OUTPOST_TEXTURE.get_width() * 0.5, OUTPOST_TEXTURE.get_height() - 6.0),
			Color(0.58, 0.92, 1.0, 0.65 if bool(validation["success"]) else 0.32)
		)


func _draw_roads() -> void:
	for building in simulation.get_buildings():
		if String(building.get("type", "")) != Defs.BUILDING_ROAD:
			continue
		var tile: Vector2i = building["position"]
		if not simulation.is_revealed(tile) or not _is_world_visible(tile_to_world(tile), 120.0):
			continue
		_draw_building(building)


func _draw_protection_bubbles() -> void:
	var selected_building: Dictionary = simulation.get_building_by_id(selected_building_id)
	var selected_type: String = String(selected_building.get("type", ""))
	var show_precise: bool = current_mode == Defs.BUILDING_LUMEN_PILLAR or selected_type == Defs.BUILDING_LUMEN_PILLAR or rivalry_debug_visible
	for source in simulation.get_protection_sources():
		var center_tile: Vector2 = source.get("center", Vector2.ZERO)
		var center_elevation_tile := Vector2i(roundi(center_tile.x), roundi(center_tile.y))
		var radius := float(source.get("radius", 0.0))
		var powered := bool(source.get("powered", false))
		var points := PackedVector2Array()
		var shimmer := 0.0
		if powered and simulation.is_night:
			shimmer = sin(simulation.elapsed_seconds * 2.2 + center_tile.x * 0.31) * 0.12
		for index in range(72):
			var angle := TAU * float(index) / 72.0
			var edge_radius := radius + shimmer * sin(angle * 5.0 + simulation.elapsed_seconds * 3.1)
			var edge_tile := center_tile + Vector2(cos(angle), sin(angle)) * edge_radius
			points.append(tile_position_to_world(edge_tile, center_elevation_tile))
		if show_precise:
			var fill_alpha := 0.07 if powered else 0.018
			var edge_alpha := 0.62 if powered else 0.18
			var bubble_color := Color(0.42, 0.82, 1.0, fill_alpha) if powered else Color(0.42, 0.46, 0.5, fill_alpha)
			draw_colored_polygon(points, bubble_color)
			points.append(points[0])
			draw_polyline(points, Color(bubble_color.r, bubble_color.g, bubble_color.b, edge_alpha), 1.7, true)
		elif powered and simulation.is_night:
			for particle_index in range(10):
				var angle: float = TAU * float(particle_index) / 10.0 + float(simulation.elapsed_seconds) * 0.08
				var sparse_radius: float = radius * (0.86 + 0.06 * sin(float(particle_index) * 2.7 + float(simulation.elapsed_seconds)))
				var particle_tile: Vector2 = center_tile + Vector2(cos(angle), sin(angle)) * sparse_radius
				var particle: Vector2 = tile_position_to_world(particle_tile, center_elevation_tile)
				draw_circle(particle, 1.2 + 0.5 * sin(simulation.elapsed_seconds * 2.0 + particle_index), Color(1.0, 0.78, 0.32, 0.34))


func _draw_founding_camp() -> void:
	if simulation.is_town_hall_founded():
		return
	var entrance: Vector2i = simulation._town_hall_entrance_tile()
	var donkey_center := tile_to_object_base(entrance + Vector2i(-3, 1)) + Vector2(0, 5)
	var supplies_center := tile_to_object_base(entrance + Vector2i(3, 2))
	var mule_size := Vector2(49, 45)
	var supplies_size := Vector2(86, 66)
	var sovereign_center := tile_to_object_base(entrance + Vector2i(-1, 2))
	draw_texture_rect(
		PACK_MULE_TEXTURE,
		Rect2(donkey_center - Vector2(mule_size.x * 0.5, mule_size.y - 4.0), mule_size),
		false
	)
	draw_texture_rect(
		FOUNDING_SUPPLIES_TEXTURE,
		Rect2(supplies_center - Vector2(supplies_size.x * 0.5, supplies_size.y - 4.0), supplies_size),
		false
	)
	draw_texture_rect(
		SOVEREIGN_HERO_TEXTURE,
		Rect2(sovereign_center + Vector2(-11.5, -35), Vector2(23, 35)),
		false
	)


func _draw_rivalry_territory() -> void:
	if simulation.rivalry == null:
		return
	for realm_id in [RivalryTuning.PLAYER_REALM, RivalryTuning.AI_REALM]:
		var realm_color := Color(0.24, 0.62, 1.0, 0.045) if realm_id == RivalryTuning.PLAYER_REALM else Color(0.95, 0.26, 0.18, 0.045)
		for source in simulation.rivalry.get_lumen_sources(realm_id):
			if realm_id == RivalryTuning.PLAYER_REALM and bool(source.get("home", false)):
				continue
			var source_center: Vector2 = source.get("center", Vector2.ZERO)
			var source_tile := Vector2i(roundi(source_center.x), roundi(source_center.y))
			if realm_id == RivalryTuning.AI_REALM and not simulation.is_revealed(source_tile):
				continue
			var world_center := tile_position_to_world(source_center, source_tile)
			var radius := float(source.get("radius", 0.0)) * TILE_WIDTH * 0.52
			draw_circle(world_center, radius, realm_color)
			draw_arc(world_center, radius, 0.0, TAU, 64, Color(realm_color.r, realm_color.g, realm_color.b, 0.18), 1.3)
	for tile in simulation.rivalry.get_roads(RivalryTuning.AI_REALM):
		if not simulation.is_revealed(tile) or not _is_world_visible(tile_to_world(tile), 100.0):
			continue
		_draw_rival_road(tile)


func _draw_rival_road(tile: Vector2i) -> void:
	var center := tile_to_world(tile)
	var base_color := Color(0.35, 0.20, 0.15, 0.94)
	var light_color := Color(0.62, 0.38, 0.25, 0.92)
	var connected_neighbors := []
	for neighbor in [
		tile + Vector2i.LEFT,
		tile + Vector2i.RIGHT,
		tile + Vector2i.UP,
		tile + Vector2i.DOWN
	]:
		if simulation.rivalry.owns_road(RivalryTuning.AI_REALM, neighbor):
			connected_neighbors.append(neighbor)
	for neighbor in connected_neighbors:
		var finish := tile_to_world(neighbor)
		var midpoint := center.lerp(finish, 0.52)
		draw_polyline(PackedVector2Array([center, midpoint, finish]), base_color, 17.0, true)
		draw_polyline(PackedVector2Array([center, midpoint, finish]), light_color, 12.0, true)
	if connected_neighbors.is_empty():
		draw_circle(center, 10.5, base_color)
		draw_circle(center, 7.5, light_color)


func _draw_rivalry_entities() -> void:
	if simulation.rivalry == null:
		return
	_draw_rival_town_hall()
	_draw_wyrd_sites()
	for structure in simulation.rivalry.get_structures():
		var center_tile := Vector2i(structure.get("position", Vector2i.ZERO))
		if String(structure.get("realm_id", "")) == RivalryTuning.AI_REALM and not simulation.is_revealed(center_tile):
			continue
		_draw_rivalry_structure(structure)
	for worker in simulation.rivalry.get_workers():
		if String(worker.get("state", "")) == "Sheltered":
			continue
		var position: Vector2 = worker.get("position", Vector2.ZERO)
		var tile := Vector2i(roundi(position.x), roundi(position.y))
		if String(worker.get("realm_id", "")) == RivalryTuning.AI_REALM and not simulation.is_revealed(tile):
			continue
		_draw_realm_worker(worker)
	var presentation_hides_sovereign: bool = simulation.presentation_worker_id > 0 and (
		not simulation.first_player_order_complete or simulation.elapsed_seconds < 75.0
	)
	if not presentation_hides_sovereign:
		_draw_sovereign(simulation.rivalry.get_sovereign(RivalryTuning.PLAYER_REALM))
	var rival_sovereign: Dictionary = simulation.rivalry.get_sovereign(RivalryTuning.AI_REALM)
	var rival_position: Vector2 = rival_sovereign.get("position", Vector2.ZERO)
	var rival_tile := Vector2i(roundi(rival_position.x), roundi(rival_position.y))
	if simulation.is_revealed(rival_tile):
		_draw_sovereign(rival_sovereign)
	for drop in simulation.rivalry.get_dropped_wyrd():
		var drop_position: Vector2 = drop.get("position", Vector2.ZERO)
		var drop_tile := Vector2i(roundi(drop_position.x), roundi(drop_position.y))
		if simulation.is_revealed(drop_tile):
			var drop_world := tile_position_to_world(drop_position, drop_tile)
			draw_circle(drop_world + Vector2(0, -10), 8.0, Color(0.25, 0.82, 1.0, 0.34))
			draw_circle(drop_world + Vector2(0, -10), 3.0, Color(0.55, 0.95, 1.0, 0.95))
	for event in simulation.rivalry.combat_events:
		var from_position: Vector2 = event.get("from", Vector2.ZERO)
		var to_position: Vector2 = event.get("to", Vector2.ZERO)
		var from_tile := Vector2i(roundi(from_position.x), roundi(from_position.y))
		var to_tile := Vector2i(roundi(to_position.x), roundi(to_position.y))
		var alpha := clampf(float(event.get("remaining", 0.0)) / 0.22, 0.0, 1.0)
		var color := Color(0.35, 0.72, 1.0, alpha) if String(event.get("realm_id", "")) == RivalryTuning.PLAYER_REALM else Color(1.0, 0.3, 0.18, alpha)
		draw_line(
			tile_position_to_world(from_position, from_tile) + Vector2(0, -23),
			tile_position_to_world(to_position, to_tile) + Vector2(0, -22),
			color,
			4.0
		)


func _draw_rival_town_hall() -> void:
	var tile: Vector2i = simulation.rival_town_hall_position
	if not simulation.is_revealed(tile):
		return
	var footprint := Defs.building_footprint(Defs.BUILDING_TOWN_HALL)
	var center_tile := Vector2(tile) + Vector2(float(footprint.x - 1) * 0.5, float(footprint.y - 1) * 0.5)
	var elevation_tile := Vector2i(roundi(center_tile.x), roundi(center_tile.y))
	var center := tile_position_to_world(center_tile, elevation_tile) + Vector2(0, TILE_HEIGHT * 0.58)
	for y in range(footprint.y):
		for x in range(footprint.x):
			var foundation_tile := tile + Vector2i(x, y)
			draw_colored_polygon(_tile_polygon(foundation_tile), Color(0.36, 0.15, 0.12, 0.42))
	draw_texture(
		TOWN_HALL_TEXTURE,
		center - Vector2(TOWN_HALL_TEXTURE.get_width() * 0.5, TOWN_HALL_TEXTURE.get_height() - 6.0),
		Color(1.0, 0.62, 0.58, 1.0)
	)
	draw_string(ThemeDB.fallback_font, center + Vector2(-38, 18), "RIVAL REALM", HORIZONTAL_ALIGNMENT_CENTER, 76, 10, Color(1.0, 0.62, 0.56, 0.95))


func _draw_wyrd_sites() -> void:
	for site in simulation.rivalry.get_wyrd_sites():
		var tile: Vector2i = site.get("position", Vector2i.ZERO)
		if not simulation.is_revealed(tile):
			continue
		var center := tile_to_object_base(tile)
		var pulse := 0.5 + 0.5 * sin(float(site.get("pulse", 0.0)) * 2.2)
		var available := float(site.get("cooldown", 0.0)) <= 0.0
		var color := Color(0.34, 0.86, 1.0, 0.8 if available else 0.28)
		draw_circle(center + Vector2(0, -12), 14.0 + pulse * 4.0, Color(color.r, color.g, color.b, 0.08))
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(0, -28),
			center + Vector2(7, -10),
			center + Vector2(0, -4),
			center + Vector2(-7, -10)
		]), color)


func _draw_rivalry_structure(structure: Dictionary) -> void:
	var position: Vector2i = structure.get("position", Vector2i.ZERO)
	var footprint: Vector2i = structure.get("footprint", Vector2i.ONE)
	var center_tile := Vector2(position) + Vector2(float(footprint.x - 1) * 0.5, float(footprint.y - 1) * 0.5)
	var elevation_tile := Vector2i(roundi(center_tile.x), roundi(center_tile.y))
	var center := tile_position_to_world(center_tile, elevation_tile) + Vector2(0, TILE_HEIGHT * 0.58)
	var realm_id := String(structure.get("realm_id", ""))
	var realm_color := Color(0.32, 0.72, 1.0, 1.0) if realm_id == RivalryTuning.PLAYER_REALM else Color(1.0, 0.34, 0.24, 1.0)
	var flash := float(structure.get("damage_flash", 0.0)) > 0.0
	if flash:
		realm_color = Color.WHITE
	for y in range(footprint.y):
		for x in range(footprint.x):
			draw_colored_polygon(_tile_polygon(position + Vector2i(x, y)), Color(realm_color.r, realm_color.g, realm_color.b, 0.18))
	if String(structure.get("type", "")) == RivalryTuning.STRUCTURE_LUMEN_PILLAR:
		var active := bool(structure.get("active", false))
		if active:
			draw_circle(center + Vector2(0, -48), 23.0, Color(realm_color.r, realm_color.g, realm_color.b, 0.12))
		draw_texture(
			LUMEN_PILLAR_TEXTURE,
			center - Vector2(LUMEN_PILLAR_TEXTURE.get_width() * 0.5, LUMEN_PILLAR_TEXTURE.get_height() - 5.0),
			Color(0.76, 0.88, 1.0, 1.0) if active else Color(0.42, 0.43, 0.45, 0.9)
		)
		if realm_id == RivalryTuning.AI_REALM:
			var flag_top := center + Vector2(-24, -80)
			draw_line(flag_top, flag_top + Vector2(0, 35), Color(0.18, 0.12, 0.09, 1.0), 2.5)
			draw_colored_polygon(PackedVector2Array([
				flag_top,
				flag_top + Vector2(20, 7),
				flag_top + Vector2(0, 15)
			]), Color(0.9, 0.12, 0.08, 1.0))
	else:
		draw_texture(
			OUTPOST_TEXTURE,
			center - Vector2(OUTPOST_TEXTURE.get_width() * 0.5, OUTPOST_TEXTURE.get_height() - 6.0),
			Color(0.74, 0.88, 1.0, 1.0) if realm_id == RivalryTuning.PLAYER_REALM else Color(1.0, 0.67, 0.60, 1.0)
		)
	var hp_fraction := float(structure.get("hp", 0)) / float(max(1, int(structure.get("max_hp", 1))))
	if hp_fraction < 1.0:
		_draw_progress_bar(center + Vector2(0, -70), hp_fraction, realm_color, 44)


func _draw_realm_worker(worker: Dictionary) -> void:
	var position: Vector2 = worker.get("position", Vector2.ZERO)
	var tile := Vector2i(roundi(position.x), roundi(position.y))
	var center := _continuous_tile_to_world(position) + Vector2(0, TILE_HEIGHT * 0.58)
	var realm_id := String(worker.get("realm_id", ""))
	var realm_color := Color(0.30, 0.68, 1.0, 1.0) if realm_id == RivalryTuning.PLAYER_REALM else Color(1.0, 0.38, 0.25, 1.0)
	var state := String(worker.get("state", ""))
	var moving := state in ["Walking to forest", "Returning home"]
	var frame := int(floor(simulation.elapsed_seconds * 5.0 + float(worker.get("id", 0)))) % 4 if moving else 1
	draw_texture_rect_region(
		SETTLER_WALK_TEXTURE,
		Rect2(center + Vector2(-SETTLER_DRAW_SIZE.x * 0.5, -SETTLER_DRAW_SIZE.y), SETTLER_DRAW_SIZE),
		Rect2(Vector2(float(frame) * SETTLER_FRAME_SIZE.x, 0.0), SETTLER_FRAME_SIZE)
	)
	if state == "Chopping":
		_draw_axe_swing(center, float(worker.get("harvest_progress", 0.0)) / RivalryTuning.WORKER_HARVEST_SECONDS)
		var progress := float(worker.get("harvest_progress", 0.0)) / RivalryTuning.WORKER_HARVEST_SECONDS
		_draw_progress_bar(center + Vector2(0, -35), progress, realm_color, 22)


func _draw_sovereign(sovereign: Dictionary) -> void:
	if sovereign.is_empty() or not bool(sovereign.get("alive", false)):
		return
	var current_position: Vector2 = sovereign.get("position", Vector2.ZERO)
	var previous_position: Vector2 = sovereign.get("previous_position", current_position)
	var render_fraction := clampf(tick_accumulator / OneShardSimulation.TICK_SECONDS, 0.0, 1.0)
	var position := previous_position.lerp(current_position, render_fraction)
	var tile := Vector2i(roundi(position.x), roundi(position.y))
	var center := _continuous_tile_to_world(position) + Vector2(0, TILE_HEIGHT * 0.58)
	var realm_id := String(sovereign.get("realm_id", ""))
	var realm_color := Color(0.24, 0.68, 1.0, 1.0) if realm_id == RivalryTuning.PLAYER_REALM else Color(1.0, 0.27, 0.18, 1.0)
	if float(sovereign.get("damage_flash", 0.0)) > 0.0:
		realm_color = Color.WHITE
	var move_direction: Vector2 = sovereign.get("move_input", Vector2.ZERO)
	if move_direction == Vector2.ZERO:
		var move_target: Vector2 = sovereign.get("move_target", position)
		if position.distance_to(move_target) > 0.08:
			move_direction = position.direction_to(move_target)
	var moving := move_direction != Vector2.ZERO
	var walk_frame := int(floor(simulation.elapsed_seconds * 8.0 + (0.0 if realm_id == RivalryTuning.PLAYER_REALM else 1.7))) % 4 if moving else 1
	var attack_cooldown := float(sovereign.get("attack_cooldown", 0.0))
	var attack_total := maxf(0.01, float(sovereign.get("attack_cooldown_seconds", RivalryTuning.SOVEREIGN_ATTACK_COOLDOWN)))
	var attack_pose := clampf(attack_cooldown / attack_total, 0.0, 1.0)
	var lean := 0.0
	if attack_pose > 0.65:
		lean += (0.10 if move_direction.x >= 0.0 else -0.10) * smoothstep(0.65, 1.0, attack_pose)
	draw_circle(center + Vector2(0, -1), 9.0, Color(0.0, 0.0, 0.0, 0.34))
	var hero_tint := Color.WHITE if realm_id == RivalryTuning.PLAYER_REALM else Color(1.0, 0.54, 0.48, 1.0)
	if float(sovereign.get("damage_flash", 0.0)) > 0.0:
		hero_tint = Color.WHITE
	var flip := -1.0 if move_direction.x > 0.05 else 1.0
	draw_set_transform(center, lean, Vector2(flip, 1.0))
	draw_texture_rect_region(
		SOVEREIGN_WALK_TEXTURE,
		Rect2(Vector2(-SOVEREIGN_DRAW_SIZE.x * 0.5, -SOVEREIGN_DRAW_SIZE.y), SOVEREIGN_DRAW_SIZE),
		Rect2(Vector2(float(walk_frame) * SOVEREIGN_FRAME_SIZE.x, 0.0), SOVEREIGN_FRAME_SIZE),
		hero_tint
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var hp_fraction := float(sovereign.get("hp", 0)) / float(max(1, int(sovereign.get("max_hp", 1))))
	if hp_fraction < 0.999 or attack_pose > 0.0:
		_draw_progress_bar(center + Vector2(0, -42), hp_fraction, realm_color, 26)
	if bool(sovereign.get("extracting", false)):
		var extraction := float(sovereign.get("extraction_progress", 0.0)) / RivalryTuning.WYRD_EXTRACTION_SECONDS
		_draw_progress_bar(center + Vector2(0, -45), extraction, Color(0.35, 0.9, 1.0, 1.0), 26)


func _draw_world_entities() -> void:
	var entities := []
	for building in simulation.get_buildings():
		if String(building.get("type", "")) == Defs.BUILDING_ROAD or not simulation.is_revealed(building["position"]):
			continue
		if not _is_world_visible(_building_world_base(building), 180.0):
			continue
		entities.append({
			"kind": "building",
			"depth": _building_world_base(building).y,
			"value": building
		})
	for camp in simulation.get_enemy_camps():
		if bool(camp.get("destroyed", false)) or not simulation.is_revealed(camp["position"]):
			continue
		if not _is_world_visible(tile_to_world(camp["position"]), 160.0):
			continue
		entities.append({"kind": "camp", "depth": tile_to_object_base(camp["position"]).y, "value": camp})
	for worker in simulation.get_workers():
		if String(worker.get("state", "")) in ["Sheltered", "Inside Town Hall"] or not simulation.is_revealed(worker["position"]):
			continue
		if not _is_world_visible(tile_to_world(worker["position"]), 80.0):
			continue
		entities.append({
			"kind": "worker",
			"depth": _interpolated_worker_position(worker).y + TILE_HEIGHT * 0.58,
			"value": worker
		})
	for enemy in simulation.get_enemies():
		if not _is_enemy_visible(enemy):
			continue
		if not _is_world_visible(tile_to_world(enemy["position"]), 80.0):
			continue
		entities.append({
			"kind": "enemy",
			"depth": _interpolated_enemy_position(enemy).y + 6.0,
			"value": enemy
		})
	entities.sort_custom(func(first, second): return float(first["depth"]) < float(second["depth"]))
	for entity in entities:
		if String(entity["kind"]) == "building":
			_draw_building(entity["value"])
		elif String(entity["kind"]) == "camp":
			_draw_enemy_camp(entity["value"])
		elif String(entity["kind"]) == "enemy":
			_draw_enemy(entity["value"])
		else:
			_draw_worker(entity["value"])


func _draw_opening_door() -> void:
	if not simulation.is_town_hall_founded():
		return
	var town_hall: Dictionary = simulation.get_building_at_tile(simulation.town_hall_position)
	if town_hall.is_empty():
		return
	var base: Vector2 = _building_world_base(town_hall)
	for supply_offset in [Vector2(34, -8), Vector2(47, -3), Vector2(39, 2)]:
		draw_texture_rect(CRATES_TEXTURE, Rect2(base + supply_offset - Vector2(9, 7), Vector2(18, 9)), false, Color(1.0, 0.94, 0.82, 0.96))
	if opening_door_open <= 0.001:
		return
	var doorway: Vector2 = base + Vector2(-30, -17)
	draw_rect(Rect2(doorway + Vector2(-7, -18), Vector2(14, 20)), Color(0.055, 0.035, 0.018, 0.98), true)
	draw_circle(doorway + Vector2(0, -10), 13.0, Color(1.0, 0.55, 0.16, 0.07 * opening_door_open))
	var panel_width := 6.0
	var slide := opening_door_open * 6.5
	draw_rect(Rect2(doorway + Vector2(-7 - slide, -18), Vector2(panel_width, 20)), Color(0.28, 0.14, 0.055, 1.0), true)
	draw_rect(Rect2(doorway + Vector2(1 + slide, -18), Vector2(panel_width, 20)), Color(0.28, 0.14, 0.055, 1.0), true)


func _draw_building(building: Dictionary) -> void:
	var tile: Vector2i = building["position"]
	var base := _building_world_base(building)
	var building_type := String(building["type"])
	if building_type != Defs.BUILDING_ROAD:
		_draw_foundation(building)
	if building_type == Defs.BUILDING_CONSTRUCTION_SITE:
		if String(building.get("planned_type", "")) == Defs.BUILDING_ROAD:
			_draw_planned_road(tile, building)
		else:
			_draw_construction_site(base, building)
	elif building_type == Defs.BUILDING_ROAD:
		_draw_road(tile, bool(building.get("connected", false)))
	elif building_type == Defs.BUILDING_WALL:
		_draw_wall(tile)
	else:
		if building_type == Defs.BUILDING_WATCHTOWER:
			_draw_wall(tile)
		var depleted_quarry := building_type == Defs.BUILDING_QUARRY and (
			String(building.get("status", "")).begins_with("Depleted")
			or int(building.get("deposit_remaining", 1)) <= 0
		)
		if depleted_quarry:
			_draw_quarry_husk(base)
		else:
			_draw_building_sprite(base, building_type, int(building.get("rotation", 0)))
		if building_type == Defs.BUILDING_QUARRY and not depleted_quarry:
			_draw_quarry_activity(base, building)
		_draw_local_inventory(base, building)
	_draw_building_overlays(base, building)


func _draw_quarry_activity(center: Vector2, building: Dictionary) -> void:
	if String(building.get("status", "")).begins_with("Depleted") or int(building.get("assigned_staff", 0)) <= 0:
		return
	var pulse := fmod(simulation.elapsed_seconds * 2.5, 1.0)
	for index in range(4):
		var phase := fmod(pulse + float(index) * 0.23, 1.0)
		var dust := center + Vector2(-18.0 + float(index) * 12.0, -14.0 - phase * 13.0)
		draw_circle(dust, 2.8 + phase * 2.0, Color(0.62, 0.56, 0.46, 0.34 * (1.0 - phase)))
	var hammer_y := sin(simulation.elapsed_seconds * 9.0) * 5.0
	draw_line(center + Vector2(10, -31), center + Vector2(17, -43 + hammer_y), Color(0.30, 0.20, 0.12, 1), 2.5)
	draw_line(center + Vector2(13, -44 + hammer_y), center + Vector2(22, -41 + hammer_y), Color(0.42, 0.43, 0.42, 1), 3.0)


func _draw_quarry_husk(center: Vector2) -> void:
	# An empty, visibly abandoned excavation: no intact stone pile remains.
	var pit_center := center + Vector2(0, -8)
	draw_colored_polygon(_diamond_polygon(pit_center, 64, 26), Color(0.17, 0.15, 0.13, 1.0))
	draw_colored_polygon(_diamond_polygon(pit_center + Vector2(0, 2), 49, 18), Color(0.075, 0.07, 0.065, 1.0))
	_draw_polygon_outline(_diamond_polygon(pit_center, 64, 26), Color(0.34, 0.30, 0.25, 1.0), 3.0)
	for offset in [Vector2(-23, -20), Vector2(21, -18)]:
		draw_line(center + offset, center + offset + Vector2(0, -28), Color(0.31, 0.20, 0.11, 1.0), 4.0)
	draw_line(center + Vector2(-23, -46), center + Vector2(18, -42), Color(0.36, 0.23, 0.12, 1.0), 4.0)
	draw_line(center + Vector2(18, -42), center + Vector2(28, -28), Color(0.24, 0.17, 0.11, 1.0), 3.0)
	draw_circle(center + Vector2(-17, -6), 3.0, Color(0.26, 0.24, 0.22, 1.0))
	draw_circle(center + Vector2(19, -4), 2.5, Color(0.28, 0.26, 0.23, 1.0))
	draw_string(ThemeDB.fallback_font, center + Vector2(-24, 15), "EMPTY", HORIZONTAL_ALIGNMENT_CENTER, 48, 8, Color(0.72, 0.65, 0.55, 0.9))


func _building_texture(building_type: String) -> Texture2D:
	if building_type == Defs.BUILDING_TOWN_HALL:
		return TOWN_HALL_TEXTURE
	if building_type == Defs.BUILDING_HOUSE:
		return HOUSE_TEXTURE
	if building_type == Defs.BUILDING_LUMBER_CAMP:
		return LUMBER_CAMP_TEXTURE
	if building_type == Defs.BUILDING_QUARRY:
		return QUARRY_TEXTURE
	if building_type == Defs.BUILDING_SAWMILL:
		return SAWMILL_TEXTURE
	if building_type == Defs.BUILDING_FARM:
		return FARM_TEXTURE
	if building_type == Defs.BUILDING_BAKERY:
		return BAKERY_TEXTURE
	if building_type == Defs.BUILDING_STOREHOUSE:
		return STOREHOUSE_TEXTURE
	if building_type == Defs.BUILDING_WATCHTOWER:
		return WATCHTOWER_TEXTURE
	if building_type == Defs.BUILDING_BARRACKS:
		return BARRACKS_TEXTURE
	if building_type == Defs.BUILDING_OUTPOST:
		return OUTPOST_TEXTURE
	return null


func _draw_building_sprite(center: Vector2, building_type: String, rotation: int = 0) -> void:
	var texture := _building_texture(building_type)
	if texture == null:
		return
	var mirrored := posmod(rotation, 4) in [1, 2]
	var art_scale := 1.0
	draw_set_transform(center, 0.0, Vector2((-art_scale if mirrored else art_scale), art_scale))
	draw_texture(texture, Vector2(-texture.get_width() * 0.5, -(texture.get_height() - 6.0)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if building_type in [Defs.BUILDING_TOWN_HALL, Defs.BUILDING_HOUSE, Defs.BUILDING_BAKERY]:
		_draw_chimney_smoke(center, building_type)
	if simulation.is_night and building_type in [Defs.BUILDING_TOWN_HALL, Defs.BUILDING_HOUSE]:
		var light_y := -36.0 if building_type == Defs.BUILDING_HOUSE else -44.0
		for offset_x in [-20.0, 0.0, 20.0]:
			draw_circle(center + Vector2(offset_x, light_y), 3.0, Color(1.0, 0.68, 0.18, 0.82))
			draw_circle(center + Vector2(offset_x, light_y), 8.0, Color(1.0, 0.46, 0.08, 0.08))


func _draw_chimney_smoke(center: Vector2, building_type: String) -> void:
	var chimney := center + Vector2(19, -74)
	if building_type == Defs.BUILDING_TOWN_HALL:
		chimney = center + Vector2(24, -104)
	elif building_type == Defs.BUILDING_BAKERY:
		chimney = center + Vector2(16, -70)
	for index in range(3):
		var phase := fmod(simulation.elapsed_seconds * 0.24 + float(index) * 0.31 + center.x * 0.0007, 1.0)
		var drift := Vector2(phase * 10.0, -phase * 28.0)
		var smoke_color := Color(0.58, 0.62, 0.65, (0.22 if simulation.is_night else 0.30) * (1.0 - phase))
		draw_circle(chimney + drift, 2.5 + phase * 4.0, smoke_color)


func _draw_local_inventory(center: Vector2, building: Dictionary) -> void:
	var inventory: Dictionary = building.get("local_inventory", {})
	var shown := 0
	for resource_type in Defs.RESOURCE_TYPES:
		var amount := int(inventory.get(resource_type, 0))
		if amount <= 0:
			continue
		var marker := center + Vector2(35 + shown * 8, -4 - shown * 3)
		draw_circle(marker, 5.0, Color(0.06, 0.05, 0.035, 0.82))
		draw_circle(marker, 3.5, _resource_color(resource_type))
		shown += 1
		if shown >= 3:
			break


func _building_world_base(building: Dictionary) -> Vector2:
	var center: Vector2 = simulation.get_building_center(building)
	return tile_position_to_world(center, building["position"]) + Vector2(0.0, TILE_HEIGHT * 0.58)


func _draw_foundation(building: Dictionary) -> void:
	for tile in simulation.get_building_footprint_tiles(building):
		draw_colored_polygon(_diamond_polygon(tile_to_world(tile) + Vector2(0.0, -0.5), TILE_WIDTH * 0.88, TILE_HEIGHT * 0.88), Color(0.28, 0.25, 0.18, 0.54))


func _draw_wall(tile: Vector2i) -> void:
	var base := tile_to_object_base(tile)
	var stone_top := Color(0.62, 0.53, 0.39, 1)
	var stone_dark := Color(0.30, 0.235, 0.17, 1)
	var timber := Color(0.27, 0.14, 0.065, 1)
	_draw_grounded_iso_block(base, 34, 13, 13, stone_top, stone_dark, Color(0.42, 0.39, 0.33, 1))
	for neighbor in _road_visual_neighbor_tiles(tile):
		var building: Dictionary = simulation.get_building_at_tile(neighbor)
		if building.is_empty() or String(building.get("type", "")) not in [Defs.BUILDING_WALL, Defs.BUILDING_WATCHTOWER]:
			continue
		var finish := tile_to_object_base(neighbor)
		draw_line(base + Vector2(0, -13), finish + Vector2(0, -13), stone_dark, 15.0, true)
		draw_line(base + Vector2(0, -17), finish + Vector2(0, -17), stone_top, 9.0, true)
		draw_line(base + Vector2(0, -20), finish + Vector2(0, -20), timber, 3.0, true)
	for offset in [-11.0, 0.0, 11.0]:
		draw_rect(Rect2(base + Vector2(offset - 3.0, -31.0), Vector2(6.0, 9.0)), stone_top, true)
		draw_line(base + Vector2(offset - 3.0, -22.0), base + Vector2(offset + 3.0, -22.0), stone_dark, 1.0)
	draw_line(base + Vector2(-15, -22), base + Vector2(15, -22), timber, 3.0)


func _draw_enemy_camp(camp: Dictionary) -> void:
	var base := tile_to_object_base(camp["position"])
	var position := base - Vector2(ENEMY_CAMP_TEXTURE.get_width() * 0.5, ENEMY_CAMP_TEXTURE.get_height() - 6.0)
	draw_texture(ENEMY_CAMP_TEXTURE, position, Color(1.0, 0.78, 0.72, 1.0) if bool(camp.get("active", false)) else Color.WHITE)


func _draw_road(tile: Vector2i, connected: bool, alpha: float = 1.0) -> void:
	var center: Vector2 = tile_to_world(tile)
	var base_color: Color = Color(0.76, 0.61, 0.34, alpha) if connected else Color(0.40, 0.34, 0.24, alpha)
	var light_color := Color(0.86, 0.72, 0.43, alpha * 0.82)
	var rut_color := Color(0.48, 0.36, 0.22, alpha * 0.34)
	var neighbors := _road_visual_neighbor_tiles(tile)
	var road_neighbor_count := 0
	for neighbor in neighbors:
		var neighbor_building: Dictionary = simulation.get_building_at_tile(neighbor)
		var neighbor_is_road := not neighbor_building.is_empty() and String(neighbor_building.get("type", "")) == Defs.BUILDING_ROAD
		if neighbor_is_road:
			road_neighbor_count += 1
			if tile.x > neighbor.x or (tile.x == neighbor.x and tile.y > neighbor.y):
				continue
		var finish := tile_to_world(neighbor) if neighbor_is_road else center.lerp(tile_to_world(neighbor), 0.48)
		var wobble_seed := absi(tile.x * 41 + tile.y * 67 + neighbor.x * 13 + neighbor.y * 29)
		var direction := (finish - center).normalized()
		var normal := Vector2(-direction.y, direction.x)
		var midpoint := center.lerp(finish, 0.5) + normal * (-1.4 if wobble_seed % 2 == 0 else 1.4)
		var road_points := PackedVector2Array([center, midpoint, finish])
		draw_polyline(road_points, base_color, 18.0, true)
		draw_polyline(road_points, light_color, 13.5, true)
		var rut_offset := normal * 3.1
		draw_polyline(PackedVector2Array([center + rut_offset, midpoint + rut_offset, finish + rut_offset]), rut_color, 1.0, true)
		draw_polyline(PackedVector2Array([center - rut_offset, midpoint - rut_offset, finish - rut_offset]), rut_color, 1.0, true)
	if road_neighbor_count >= 3:
		draw_circle(center, 11.0, base_color)
		draw_circle(center, 8.0, light_color)
	var pattern := absi(tile.x * 31 + tile.y * 17)
	if pattern % 4 == 0:
		var pebble := center + Vector2(float(pattern % 9 - 4), float(pattern % 5 - 2))
		draw_circle(pebble, 1.15, Color(0.48, 0.38, 0.25, alpha * 0.38))
	if simulation.is_gate_tile(tile):
		_draw_gate(tile, simulation.is_gate_closed())


func _draw_gate(tile: Vector2i, closed: bool) -> void:
	var base := tile_to_object_base(tile)
	var timber := Color(0.30, 0.17, 0.075, 1)
	var iron := Color(0.13, 0.12, 0.10, 1)
	draw_line(base + Vector2(-15, -3), base + Vector2(-15, -35), timber, 7.0)
	draw_line(base + Vector2(15, -3), base + Vector2(15, -35), timber, 7.0)
	draw_line(base + Vector2(-18, -35), base + Vector2(18, -35), timber, 8.0)
	if closed:
		for offset in [-10.0, -5.0, 0.0, 5.0, 10.0]:
			draw_line(base + Vector2(offset, -4), base + Vector2(offset, -31), iron, 2.4)
		draw_line(base + Vector2(-12, -17), base + Vector2(12, -17), iron, 2.0)
	else:
		draw_line(base + Vector2(-14, -4), base + Vector2(-14, -29), iron, 3.0)
		draw_line(base + Vector2(14, -4), base + Vector2(14, -29), iron, 3.0)


func _road_neighbor_tiles(tile: Vector2i) -> Array[Vector2i]:
	return simulation.get_road_connection_tiles(tile)


func _road_visual_neighbor_tiles(tile: Vector2i) -> Array[Vector2i]:
	var tiles := _road_neighbor_tiles(tile)
	for direction_value in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var direction: Vector2i = direction_value
		var neighbor: Vector2i = tile + direction
		if tiles.has(neighbor) or not simulation.is_inside_map(neighbor):
			continue
		var building: Dictionary = simulation.get_building_at_tile(neighbor)
		if not building.is_empty() and String(building.get("type", "")) != Defs.BUILDING_ROAD:
			tiles.append(neighbor)
	return tiles


func _road_edge_point(center: Vector2, tile: Vector2i, neighbor: Vector2i) -> Vector2:
	var delta := neighbor - tile
	if delta == Vector2i(1, 0):
		return center + Vector2(TILE_WIDTH * 0.25, TILE_HEIGHT * 0.25)
	if delta == Vector2i(-1, 0):
		return center + Vector2(-TILE_WIDTH * 0.25, -TILE_HEIGHT * 0.25)
	if delta == Vector2i(0, 1):
		return center + Vector2(-TILE_WIDTH * 0.25, TILE_HEIGHT * 0.25)
	if delta == Vector2i(0, -1):
		return center + Vector2(TILE_WIDTH * 0.25, -TILE_HEIGHT * 0.25)
	return center


func _road_connector_polygon(start: Vector2, finish: Vector2, width: float) -> PackedVector2Array:
	var direction := finish - start
	if direction.length_squared() <= 0.01:
		return PackedVector2Array()
	var normal := Vector2(-direction.y, direction.x).normalized() * width * 0.5
	return PackedVector2Array([
		start + normal,
		finish + normal,
		finish - normal,
		start - normal
	])


func _draw_town_hall(center: Vector2) -> void:
	draw_colored_polygon(_diamond_polygon(center + Vector2(0, 2), TILE_WIDTH * 1.18, TILE_HEIGHT * 1.0), Color(0.95, 0.72, 0.22, 0.18))
	_draw_grounded_iso_block(center, 78, 34, 46, Color(0.6, 0.43, 0.28, 1), Color(0.34, 0.23, 0.15, 1), Color(0.5, 0.34, 0.21, 1))
	_draw_grounded_iso_block(center + Vector2(0, -38), 88, 38, 18, Color(0.62, 0.16, 0.13, 1), Color(0.34, 0.07, 0.06, 1), Color(0.52, 0.11, 0.09, 1))
	_draw_grounded_iso_block(center + Vector2(28, -54), 18, 9, 28, Color(0.78, 0.68, 0.42, 1), Color(0.42, 0.36, 0.22, 1), Color(0.62, 0.53, 0.32, 1))
	draw_line(center + Vector2(39, -82), center + Vector2(39, -112), Color(0.85, 0.76, 0.56, 1), 3)
	draw_colored_polygon(PackedVector2Array([center + Vector2(39, -110), center + Vector2(65, -102), center + Vector2(39, -94)]), Color(0.86, 0.22, 0.18, 1))


func _draw_house(center: Vector2) -> void:
	_draw_grounded_iso_block(center, 48, 26, 24, Color(0.62, 0.44, 0.31, 1), Color(0.39, 0.27, 0.19, 1), Color(0.52, 0.36, 0.25, 1))
	_draw_grounded_iso_block(center + Vector2(0, -18), 54, 29, 12, Color(0.38, 0.28, 0.52, 1), Color(0.22, 0.16, 0.33, 1), Color(0.31, 0.22, 0.44, 1))


func _draw_lumber_camp(center: Vector2) -> void:
	_draw_grounded_iso_block(center + Vector2(8, 0), 48, 25, 23, Color(0.56, 0.32, 0.14, 1), Color(0.33, 0.18, 0.08, 1), Color(0.47, 0.25, 0.1, 1))
	_draw_grounded_iso_block(center + Vector2(8, -17), 54, 28, 12, Color(0.18, 0.45, 0.23, 1), Color(0.1, 0.27, 0.13, 1), Color(0.14, 0.36, 0.18, 1))
	_draw_grounded_iso_block(center + Vector2(-20, 0), 30, 12, 8, Color(0.49, 0.26, 0.09, 1), Color(0.25, 0.12, 0.04, 1), Color(0.58, 0.33, 0.13, 1))


func _draw_quarry(center: Vector2) -> void:
	_draw_grounded_iso_block(center + Vector2(-6, 0), 44, 23, 19, Color(0.48, 0.5, 0.51, 1), Color(0.28, 0.3, 0.31, 1), Color(0.39, 0.41, 0.42, 1))
	_draw_grounded_iso_block(center + Vector2(18, 0), 28, 16, 13, Color(0.33, 0.35, 0.36, 1), Color(0.2, 0.21, 0.22, 1), Color(0.28, 0.29, 0.3, 1))


func _draw_sawmill(center: Vector2) -> void:
	_draw_grounded_iso_block(center, 56, 28, 24, Color(0.58, 0.36, 0.18, 1), Color(0.34, 0.19, 0.08, 1), Color(0.48, 0.28, 0.13, 1))
	_draw_grounded_iso_block(center + Vector2(0, -18), 60, 30, 12, Color(0.54, 0.19, 0.14, 1), Color(0.31, 0.09, 0.07, 1), Color(0.45, 0.14, 0.1, 1))
	_draw_grounded_iso_block(center + Vector2(23, 0), 24, 9, 8, Color(0.77, 0.68, 0.45, 1), Color(0.46, 0.39, 0.25, 1), Color(0.68, 0.58, 0.36, 1))


func _draw_farm(center: Vector2) -> void:
	for offset in [Vector2(-18, -4), Vector2(0, 2), Vector2(18, 8)]:
		draw_colored_polygon(_diamond_polygon(center + offset, 24, 10), Color(0.76, 0.66, 0.25, 1))
	_draw_grounded_iso_block(center, 36, 20, 19, Color(0.5, 0.32, 0.2, 1), Color(0.28, 0.17, 0.1, 1), Color(0.42, 0.25, 0.15, 1))


func _draw_bakery(center: Vector2) -> void:
	_draw_grounded_iso_block(center, 52, 28, 24, Color(0.68, 0.54, 0.38, 1), Color(0.42, 0.32, 0.22, 1), Color(0.57, 0.43, 0.3, 1))
	_draw_grounded_iso_block(center + Vector2(0, -18), 58, 30, 12, Color(0.76, 0.37, 0.2, 1), Color(0.45, 0.2, 0.1, 1), Color(0.63, 0.29, 0.15, 1))
	draw_circle(center + Vector2(21, -38), 6, Color(0.12, 0.09, 0.08, 1))


func _draw_watchtower(center: Vector2) -> void:
	_draw_grounded_iso_block(center, 24, 14, 50, Color(0.5, 0.34, 0.19, 1), Color(0.3, 0.19, 0.1, 1), Color(0.42, 0.27, 0.15, 1))
	_draw_grounded_iso_block(center + Vector2(0, -42), 46, 24, 12, Color(0.38, 0.39, 0.42, 1), Color(0.21, 0.22, 0.25, 1), Color(0.31, 0.32, 0.36, 1))


func _draw_outpost(center: Vector2) -> void:
	_draw_grounded_iso_block(center, 58, 31, 30, Color(0.39, 0.44, 0.47, 1), Color(0.23, 0.27, 0.29, 1), Color(0.32, 0.36, 0.39, 1))
	_draw_grounded_iso_block(center + Vector2(0, -22), 66, 34, 14, Color(0.21, 0.42, 0.52, 1), Color(0.11, 0.24, 0.31, 1), Color(0.16, 0.34, 0.43, 1))
	draw_line(center + Vector2(0, -50), center + Vector2(0, -88), Color(0.82, 0.82, 0.72, 1), 3)
	draw_circle(center + Vector2(0, -90), 6, GOLD)


func _draw_construction_site(center: Vector2, building: Dictionary) -> void:
	_draw_grounded_iso_block(center, 52, 26, 10, Color(0.47, 0.4, 0.31, 1), Color(0.27, 0.22, 0.16, 1), Color(0.39, 0.32, 0.24, 1))
	for x in [-19, 19]:
		draw_line(center + Vector2(x, -4), center + Vector2(x, -42), Color(0.62, 0.48, 0.3, 1), 3)
	draw_line(center + Vector2(-24, -34), center + Vector2(24, -14), Color(0.62, 0.48, 0.3, 1), 3)
	if String(building.get("status", "")) == "Building." and String(building.get("planned_type", "")) != Defs.BUILDING_TOWN_HALL:
		var builder_center := center + Vector2(-30, 5)
		var builder_size := Vector2(22, 32)
		draw_texture_rect_region(
			SETTLER_WALK_TEXTURE,
			Rect2(builder_center + Vector2(-builder_size.x * 0.5, -builder_size.y), builder_size),
			Rect2(Vector2(SETTLER_FRAME_SIZE.x, 0.0), SETTLER_FRAME_SIZE),
			Color(0.94, 0.72, 0.34, 1.0)
		)
		_draw_worker_action({"state": "Building", "path": [], "id": int(building.get("id", 0))}, builder_center)
	_draw_progress_bar(center + Vector2(0, -56), _construction_fraction(building), Color(0.86, 0.7, 0.24, 1), 46)


func _draw_planned_road(tile: Vector2i, building: Dictionary) -> void:
	var center := tile_to_world(tile)
	draw_colored_polygon(_diamond_polygon(center, TILE_WIDTH * 0.82, TILE_HEIGHT * 0.64), Color(0.72, 0.59, 0.34, 0.30))
	_draw_polygon_outline(_diamond_polygon(center, TILE_WIDTH * 0.86, TILE_HEIGHT * 0.68), Color(0.95, 0.78, 0.35, 0.82), 2.0)
	var total := maxf(0.01, float(building.get("construction_total", OneShardSimulation.ROAD_BUILD_SECONDS)))
	var progress := 1.0 - float(building.get("construction_remaining", total)) / total
	if progress > 0.0:
		draw_colored_polygon(_diamond_polygon(center, TILE_WIDTH * 0.70 * progress, TILE_HEIGHT * 0.50 * progress), Color(0.80, 0.66, 0.39, 0.88))


func _draw_building_overlays(center: Vector2, building: Dictionary) -> void:
	var texture := _building_texture(String(building.get("type", "")))
	var alert_y := -60.0 if texture == null else -float(texture.get_height()) + 12.0
	if not bool(building.get("connected", false)) and String(building["type"]) != Defs.BUILDING_TOWN_HALL:
		draw_circle(center + Vector2(0, alert_y), 8, Color(0.88, 0.12, 0.1, 1))
	if bool(building.get("abandoned", false)):
		var alert_center := center + Vector2(14, alert_y)
		draw_circle(alert_center, 8, Color(0.88, 0.65, 0.12, 1))
		draw_line(alert_center + Vector2(-3, -3), alert_center + Vector2(3, 3), Color(0.2, 0.12, 0.04, 1), 2)
		draw_line(alert_center + Vector2(3, -3), alert_center + Vector2(-3, 3), Color(0.2, 0.12, 0.04, 1), 2)
	if float(building.get("damage_flash", 0.0)) > 0.0:
		draw_colored_polygon(_diamond_polygon(center + Vector2(0, -8), TILE_WIDTH * 0.95, TILE_HEIGHT * 0.95), Color(1.0, 0.05, 0.02, 0.28))
	if int(building["hp"]) < int(building["max_hp"]):
		_draw_progress_bar(center + Vector2(0, alert_y - 12), float(building["hp"]) / float(building["max_hp"]), Color(0.9, 0.18, 0.12, 1), 48)
	var building_type := String(building.get("type", ""))
	if building_type == Defs.BUILDING_BARRACKS:
		var training_fraction := clampf(float(building.get("training_progress", 0.0)) / OneShardSimulation.BARRACKS_TRAIN_SECONDS, 0.0, 1.0)
		_draw_activity_bar(center + Vector2(0, 10), training_fraction, "Training" if training_fraction > 0.0 else String(building.get("status", "Idle")))
	elif Defs.PRODUCTION_DEFS.has(building_type):
		var definition: Dictionary = Defs.PRODUCTION_DEFS[building_type]
		var interval := maxf(0.01, float(definition.get("interval", 1.0)))
		var fraction := 0.0 if bool(building.get("storage_paused", false)) else clampf(float(building.get("production_timer", 0.0)) / interval, 0.0, 1.0)
		_draw_activity_bar(center + Vector2(0, 10), fraction, String(building.get("status", "Idle")))


func _draw_activity_bar(center: Vector2, fraction: float, label: String) -> void:
	var normal_state := label in ["Active.", "Ready.", "Watching.", "Working.", "Working indoors"]
	var bar_color := Color(0.34, 0.78, 0.40, 0.9) if normal_state else Color(0.92, 0.64, 0.18, 0.92)
	_draw_progress_bar(center + Vector2(0, 5), fraction, bar_color, 36)
	if not normal_state:
		draw_circle(center + Vector2(23, 5), 3.0, bar_color)


func _draw_workers() -> void:
	for worker in simulation.get_workers():
		if String(worker.get("state", "")) in ["Sheltered", "Working indoors", "Waiting indoors", "Guarding indoors"]:
			continue
		_draw_worker(worker)


func _draw_worker(worker: Dictionary) -> void:
	var center := _interpolated_worker_position(worker) + Vector2(0, TILE_HEIGHT * 0.58)
	var attack_flash := float(worker.get("attack_flash", 0.0))
	var attack_direction := Vector2.RIGHT
	if attack_flash > 0.0:
		var combat_target := _data_to_tile(worker.get("combat_target_position", {}))
		attack_direction = (tile_to_world(combat_target) - tile_to_world(worker["position"])).normalized()
		if attack_direction == Vector2.ZERO:
			attack_direction = Vector2.RIGHT
	var attack_progress := 1.0 - clampf(attack_flash / GUARD_ATTACK_ANIMATION_SECONDS, 0.0, 1.0)
	var body_rotation := 0.0
	var body_scale := Vector2.ONE
	if attack_flash > 0.0:
		var pose := _melee_attack_pose(attack_progress, attack_direction, 0.72)
		center += Vector2(pose["offset"])
		body_rotation = float(pose["rotation"])
		body_scale = Vector2(pose["scale"])
	var hit_remaining := maxf(0.0, float(worker.get("hit_until", 0.0)) - simulation.elapsed_seconds)
	if hit_remaining > 0.0:
		var attacker_tile := _data_to_tile(worker.get("hit_direction", {}))
		var recoil_direction := (tile_to_world(worker["position"]) - tile_to_world(attacker_tile)).normalized()
		var recoil := sin(clampf(hit_remaining / 0.26, 0.0, 1.0) * PI)
		center += recoil_direction * 7.0 * recoil
		body_rotation += sin(recoil * PI) * 0.08
	draw_colored_polygon(_diamond_polygon(center + Vector2(0, 1), 13, 4), Color(0.0, 0.0, 0.0, 0.24))
	if int(worker.get("id", 0)) == selected_worker_id:
		draw_arc(center + Vector2(0, 1), 10.0, 0.0, TAU, 24, Color(1.0, 0.78, 0.28, 0.92), 1.8, true)
	var path: Array = worker.get("path", [])
	var frame := _movement_frame(path, float(worker.get("move_elapsed", 0.0)) + tick_accumulator, simulation.get_worker_step_seconds(worker))
	var flip := false
	if attack_flash > 0.0:
		flip = attack_direction.x < 0.0
	elif not path.is_empty():
		flip = (tile_to_world(path[0]) - tile_to_world(worker["position"])).x < 0.0
	elif String(worker.get("state", "")) == "Confused":
		flip = int(floor(simulation.elapsed_seconds * 1.7)) % 2 == 0
	var tint := _worker_tint(String(worker.get("type", "settler")))
	if hit_remaining > 0.0:
		tint = tint.lerp(Color(1.0, 0.38, 0.3, 1.0), 0.56)
	draw_set_transform(center, body_rotation, Vector2((-1.0 if flip else 1.0) * body_scale.x, body_scale.y))
	draw_texture_rect_region(
		SETTLER_WALK_TEXTURE,
		Rect2(Vector2(-SETTLER_DRAW_SIZE.x * 0.5, -SETTLER_DRAW_SIZE.y), SETTLER_DRAW_SIZE),
		Rect2(Vector2(float(frame) * SETTLER_FRAME_SIZE.x, 0.0), SETTLER_FRAME_SIZE),
		tint
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if String(worker.get("type", "")) == "guard" and attack_flash > 0.0:
		_draw_melee_weapon(center, attack_direction, attack_progress, Color(0.82, 0.88, 0.96, 1.0), 18.0)
	_draw_worker_action(worker, center)
	if hit_remaining > 0.0:
		_draw_hit_spark(center + Vector2(0, -20), hit_remaining / 0.26)
	if int(worker.get("carried_amount", 0)) > 0:
		draw_texture_rect(CRATES_TEXTURE, Rect2(center + Vector2(1, -15), Vector2(18, 9)), false, Color(1, 1, 1, 0.96))
		draw_circle(center + Vector2(13, -10), 2.5, _resource_color(String(worker["carried_resource"])))
	if bool(worker.get("hungry", false)):
		_draw_hunger_marker(center + Vector2(0, -38))
	var reaction := String(worker.get("reaction", ""))
	if reaction != "" and float(worker.get("reaction_until", 0.0)) > simulation.elapsed_seconds:
		var reaction_bob := sin(simulation.elapsed_seconds * 8.0 + float(worker.get("id", 0))) * 1.5
		draw_circle(center + Vector2(0, -42 + reaction_bob), 7.5, Color(0.12, 0.075, 0.03, 0.94))
		draw_string(ThemeDB.fallback_font, center + Vector2(-4, -37 + reaction_bob), reaction, HORIZONTAL_ALIGNMENT_CENTER, 8, 12, Color(1.0, 0.84, 0.32, 1.0))
	if int(worker.get("hp", OneShardSimulation.WORKER_MAX_HP)) < int(worker.get("max_hp", OneShardSimulation.WORKER_MAX_HP)):
		_draw_progress_bar(center + Vector2(0, -34), float(worker.get("hp", 0)) / float(worker.get("max_hp", 1)), Color(0.9, 0.2, 0.14, 1), 20)


func _draw_worker_action(worker: Dictionary, center: Vector2) -> void:
	var path: Array = worker.get("path", [])
	if not path.is_empty():
		return
	var state := String(worker.get("state", "")).to_lower()
	var worker_type := String(worker.get("type", ""))
	var phase := fmod(simulation.elapsed_seconds * 2.2 + float(worker.get("id", 0)) * 0.19, 1.0)
	if state == "building":
		var swing := absf(sin(phase * TAU))
		var shoulder := center + Vector2(2, -24)
		var hand := center + Vector2(6, -19)
		var hammer_head := hand + Vector2(7.0 - swing * 4.0, -8.0 + swing * 11.0)
		draw_line(shoulder, hand, Color(0.72, 0.51, 0.28, 1.0), 3.0)
		draw_line(hand, hammer_head, Color(0.36, 0.21, 0.11, 1.0), 2.5)
		var head_direction := Vector2(0.86, 0.50)
		draw_line(hammer_head - head_direction * 4.0, hammer_head + head_direction * 4.0, Color(0.48, 0.50, 0.49, 1.0), 4.0)
	elif worker_type in ["woodcutter", "clearer"] and state in ["working", "clearing land", "gathering"]:
		_draw_axe_swing(center, phase)
	elif worker_type == "miner" and state == "working":
		var strike := absf(sin(phase * TAU))
		var hand := center + Vector2(3, -20)
		var pick_end := hand + Vector2(12.0 - strike * 8.0, -13.0 + strike * 16.0)
		draw_line(hand, pick_end, Color(0.36, 0.22, 0.12, 1.0), 2.5)
		draw_line(pick_end + Vector2(-5, -2), pick_end + Vector2(5, 2), Color(0.52, 0.54, 0.54, 1.0), 3.0)
	elif worker_type == "sawyer" and state == "working":
		var saw_x := sin(phase * TAU) * 7.0
		draw_line(center + Vector2(-9 + saw_x, -13), center + Vector2(9 + saw_x, -13), Color(0.68, 0.69, 0.66, 1.0), 2.5)


func _draw_axe_swing(center: Vector2, phase: float) -> void:
	var swing := sin(clampf(phase, 0.0, 1.0) * PI)
	var hand := center + Vector2(4, -20)
	var axe_end := hand + Vector2(11.0 - swing * 8.0, -13.0 + swing * 17.0)
	draw_line(hand, axe_end, Color(0.40, 0.24, 0.12, 1.0), 2.5)
	draw_colored_polygon(PackedVector2Array([
		axe_end + Vector2(-2, -5),
		axe_end + Vector2(7, -2),
		axe_end + Vector2(5, 4),
		axe_end
	]), Color(0.61, 0.64, 0.62, 1.0))


func _draw_hunger_marker(center: Vector2) -> void:
	draw_circle(center, 8.0, Color(0.12, 0.08, 0.035, 0.94))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -5),
		center + Vector2(5, 5),
		center + Vector2(-5, 5)
	]), Color(0.98, 0.7, 0.16, 1.0))
	draw_line(center + Vector2(0, -1), center + Vector2(0, 2), Color(0.18, 0.1, 0.03, 1.0), 1.5)
	draw_circle(center + Vector2(0, 4), 1.0, Color(0.18, 0.1, 0.03, 1.0))


func _interpolated_worker_position(worker: Dictionary) -> Vector2:
	var current := tile_to_world(worker["position"])
	var path: Array = worker.get("path", [])
	if path.is_empty():
		return current
	var step_seconds: float = simulation.get_worker_step_seconds(worker)
	var render_elapsed := float(worker.get("move_elapsed", 0.0)) + tick_accumulator
	var fraction := clampf(render_elapsed / step_seconds, 0.0, 1.0)
	return current.lerp(tile_to_world(path[0]), fraction)


func _movement_frame(path: Array, elapsed: float, step_seconds: float) -> int:
	if path.is_empty():
		return 1
	var fraction := clampf(elapsed / maxf(step_seconds, 0.01), 0.0, 0.999)
	return mini(3, floori(fraction * 4.0))


func _worker_tint(worker_type: String) -> Color:
	if worker_type == "miner":
		return Color(0.77, 0.83, 0.9, 1)
	if worker_type == "farmer":
		return Color(0.95, 0.8, 0.34, 1)
	if worker_type == "woodcutter" or worker_type == "sawyer":
		return Color(0.76, 0.92, 0.62, 1)
	if worker_type == "baker":
		return Color(1.0, 0.88, 0.72, 1)
	if worker_type == "guard":
		return Color(0.76, 0.78, 0.98, 1)
	if worker_type == "clearer":
		return Color(0.94, 0.72, 0.34, 1)
	return Color.WHITE


func _draw_worker_paths() -> void:
	for worker in simulation.get_workers():
		var path: Array = worker.get("path", [])
		if path.is_empty():
			continue
		var points := PackedVector2Array()
		points.append(tile_to_world(worker["position"]))
		for tile in path:
			points.append(tile_to_world(tile))
		if points.size() >= 2:
			draw_polyline(points, Color(0.95, 0.65, 0.18, 0.72), 3.0, true)


func _draw_enemy(enemy: Dictionary) -> void:
	var base := _interpolated_enemy_position(enemy) + Vector2(0, 6)
	var enemy_type := String(enemy.get("enemy_type", OneShardSimulation.ENEMY_RAIDER))
	var role_scale := 1.0
	var role_tint := Color.WHITE
	var pose_weight := 1.0
	if enemy_type == OneShardSimulation.ENEMY_SKITTERER:
		role_scale = 0.72
		role_tint = Color(0.82, 0.67, 1.0, 1.0)
		pose_weight = 0.75
	elif enemy_type == OneShardSimulation.ENEMY_BRUTE:
		role_scale = 1.42
		role_tint = Color(0.82, 0.42, 0.30, 1.0)
		pose_weight = 1.35
	elif enemy_type == OneShardSimulation.ENEMY_HEXER:
		role_scale = 0.94
		role_tint = Color(0.48, 0.88, 1.0, 1.0)
		pose_weight = 0.55
	var attack_flash := float(enemy.get("attack_flash", 0.0))
	var target_tile := _data_to_tile(enemy.get("target_position", {}))
	var attack_direction := (tile_to_world(target_tile) - tile_to_world(enemy["position"])).normalized()
	if attack_direction == Vector2.ZERO:
		attack_direction = Vector2.LEFT
	base += _enemy_combat_slot_offset(enemy, attack_direction)
	var attack_progress := 1.0 - clampf(attack_flash / ENEMY_ATTACK_ANIMATION_SECONDS, 0.0, 1.0)
	var body_rotation := 0.0
	var body_scale := Vector2.ONE
	if attack_flash > 0.0:
		var pose := _melee_attack_pose(attack_progress, attack_direction, pose_weight)
		base += Vector2(pose["offset"])
		body_rotation = float(pose["rotation"])
		body_scale = Vector2(pose["scale"])
	body_scale *= role_scale
	var hit_remaining := maxf(0.0, float(enemy.get("hit_until", 0.0)) - simulation.elapsed_seconds)
	if hit_remaining > 0.0:
		var attacker_tile := _data_to_tile(enemy.get("hit_direction", {}))
		var recoil_direction := (tile_to_world(enemy["position"]) - tile_to_world(attacker_tile)).normalized()
		var recoil := sin(clampf(hit_remaining / 0.26, 0.0, 1.0) * PI)
		base += recoil_direction * 9.0 * recoil
		body_rotation += (-0.11 if recoil_direction.x < 0.0 else 0.11) * recoil
	var path: Array = enemy.get("path", [])
	var frame := _movement_frame(path, float(enemy.get("move_elapsed", 0.0)) + tick_accumulator, simulation.get_enemy_step_seconds(enemy))
	var flip := attack_direction.x > 0.0
	if attack_flash <= 0.0 and not path.is_empty():
		flip = (tile_to_world(path[0]) - tile_to_world(enemy["position"])).x > 0.0
	var tint := role_tint
	if hit_remaining > 0.0:
		tint = Color(1.0, 0.46, 0.38, 1.0)
	draw_circle(base + Vector2(0, -1), 8.0 * role_scale, Color(0.0, 0.0, 0.0, 0.3))
	draw_set_transform(base, body_rotation, Vector2((-1.0 if flip else 1.0) * body_scale.x, body_scale.y))
	draw_texture_rect_region(
		NIGHT_RAIDER_WALK_TEXTURE,
		Rect2(Vector2(-RAIDER_DRAW_SIZE.x * 0.5, -RAIDER_DRAW_SIZE.y), RAIDER_DRAW_SIZE),
		Rect2(Vector2(float(frame) * RAIDER_FRAME_SIZE.x, 0.0), RAIDER_FRAME_SIZE),
		tint
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if attack_flash > 0.0 and enemy_type == OneShardSimulation.ENEMY_HEXER:
		var spell_origin := base + Vector2(0, -24)
		var spell_target := tile_to_object_base(target_tile) + Vector2(0, -16)
		var pulse := sin(clampf(attack_progress, 0.0, 1.0) * PI)
		draw_circle(spell_origin, 4.0 + pulse * 4.0, Color(0.35, 0.82, 1.0, 0.65))
		draw_line(spell_origin, spell_target, Color(0.40, 0.78, 1.0, 0.22 + pulse * 0.5), 2.5)
	elif attack_flash > 0.0:
		_draw_melee_weapon(base, attack_direction, attack_progress, Color(0.72, 0.76, 0.8, 1.0), 20.0)
	if hit_remaining > 0.0:
		_draw_hit_spark(base + Vector2(0, -22), hit_remaining / 0.26)
	var health_color := Color(0.34, 0.75, 1.0, 1.0) if enemy_type == OneShardSimulation.ENEMY_HEXER else Color(0.9, 0.12, 0.12, 1)
	var enemy_hp_fraction := float(enemy["hp"]) / float(enemy["max_hp"])
	if enemy_hp_fraction < 0.999 or attack_flash > 0.0 or hit_remaining > 0.0:
		_draw_progress_bar(
			base + Vector2(0, -RAIDER_DRAW_SIZE.y * role_scale - 3),
			enemy_hp_fraction,
			health_color,
			24.0 * maxf(0.8, role_scale)
		)


func _draw_enemies() -> void:
	for enemy in simulation.get_enemies():
		if _is_enemy_visible(enemy) and _is_world_visible(tile_to_world(enemy["position"]), 80.0):
			_draw_enemy(enemy)


func _melee_attack_pose(progress: float, direction: Vector2, weight: float) -> Dictionary:
	var offset := Vector2.ZERO
	var rotation := 0.0
	var scale := Vector2.ONE
	if progress < 0.32:
		var windup := smoothstep(0.0, 0.32, progress)
		offset = -direction * 5.0 * windup * weight
		rotation = (-0.09 if direction.x >= 0.0 else 0.09) * windup * weight
		scale = Vector2(1.0 + 0.05 * windup, 1.0 - 0.04 * windup)
	elif progress < 0.58:
		var strike := smoothstep(0.32, 0.58, progress)
		offset = direction * lerpf(-5.0, 14.0, strike) * weight
		rotation = (0.13 if direction.x >= 0.0 else -0.13) * strike * weight
		scale = Vector2(1.0 - 0.08 * strike, 1.0 + 0.08 * strike)
	else:
		var recover := smoothstep(0.58, 1.0, progress)
		offset = direction * lerpf(14.0, 0.0, recover) * weight
		rotation = (0.13 if direction.x >= 0.0 else -0.13) * (1.0 - recover) * weight
		scale = Vector2(0.92, 1.08).lerp(Vector2.ONE, recover)
	return {"offset": offset, "rotation": rotation, "scale": scale}


func _draw_melee_weapon(center: Vector2, direction: Vector2, progress: float, blade_color: Color, reach: float) -> void:
	var slash_progress := clampf((progress - 0.18) / 0.58, 0.0, 1.0)
	var weapon_direction := direction.rotated(lerpf(-1.05, 0.62, slash_progress)).normalized()
	var hand := center + Vector2(0, -20) + Vector2(-direction.y, direction.x) * 3.0
	var hilt := hand - weapon_direction * 4.0
	var tip := hand + weapon_direction * reach
	draw_line(hilt, hand, Color(0.34, 0.2, 0.09, 1.0), 4.0)
	draw_line(hand, tip, Color(0.18, 0.2, 0.22, 1.0), 4.0)
	draw_line(hand, tip, blade_color, 2.0)
	if progress >= 0.30 and progress <= 0.66:
		var alpha := sin(clampf((progress - 0.30) / 0.36, 0.0, 1.0) * PI) * 0.72
		draw_arc(
			center + Vector2(0, -18),
			reach + 3.0,
			direction.angle() - 0.82,
			direction.angle() + 0.52,
			12,
			Color(blade_color.r, blade_color.g, blade_color.b, alpha),
			2.4,
			true
		)


func _draw_hit_spark(center: Vector2, strength: float) -> void:
	var pulse := sin(clampf(strength, 0.0, 1.0) * PI)
	var color := Color(1.0, 0.72, 0.22, 0.86 * pulse)
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN, Vector2(1, 1).normalized(), Vector2(-1, 1).normalized()]:
		draw_line(center + direction * 3.0, center + direction * (7.0 + 5.0 * pulse), color, 1.8)


func _enemy_combat_slot_offset(enemy: Dictionary, attack_direction: Vector2) -> Vector2:
	if int(enemy.get("target_id", 0)) <= 0:
		return Vector2.ZERO
	var slot := posmod(int(enemy.get("id", 0)), 3) - 1
	var tangent := Vector2(-attack_direction.y, attack_direction.x)
	return tangent * float(slot) * 9.0


func _is_enemy_visible(enemy: Dictionary) -> bool:
	return simulation.is_revealed(enemy["position"])


func _interpolated_enemy_position(enemy: Dictionary) -> Vector2:
	var current := tile_to_world(enemy["position"])
	var path: Array = enemy.get("path", [])
	if path.is_empty():
		return current
	var render_elapsed := float(enemy.get("move_elapsed", 0.0)) + tick_accumulator
	var fraction := clampf(render_elapsed / simulation.get_enemy_step_seconds(enemy), 0.0, 1.0)
	return current.lerp(tile_to_world(path[0]), fraction)


func _draw_projectiles() -> void:
	for projectile in simulation.get_projectiles():
		var from_tile := _data_to_tile(projectile.get("from", {}))
		var to_tile := _data_to_tile(projectile.get("to", {}))
		var alpha := clampf(float(projectile.get("life", 0.0)) / max(0.01, float(projectile.get("total", 0.2))), 0.0, 1.0)
		if String(projectile.get("kind", "")) == "hex":
			var from_point := tile_to_object_base(from_tile) + Vector2(0, -24)
			var to_point := tile_to_object_base(to_tile) + Vector2(0, -20)
			draw_line(from_point, to_point, Color(0.35, 0.82, 1.0, alpha * 0.8), 3.0)
			draw_circle(from_point.lerp(to_point, 1.0 - alpha), 4.0, Color(0.55, 0.92, 1.0, alpha))
		else:
			draw_line(tile_to_world(from_tile) + Vector2(0, -96), tile_to_world(to_tile) + Vector2(0, -20), Color(1.0, 0.78, 0.22, alpha), 4.0)


func _draw_tree(tile: Vector2i, center: Vector2) -> void:
	var variant := int(abs(center.x * 0.17 + center.y * 0.11)) % 7
	var size := Vector2(66, 78)
	if variant in [0, 4]:
		size *= 1.12
	elif variant in [2, 6]:
		size *= 0.88
	var tint := Color(0.82, 0.96, 0.78, 1.0) if variant % 3 == 0 else Color.WHITE
	var being_cut := active_chop_tiles.has(simulation._tile_key(tile))
	var sway := sin(simulation.elapsed_seconds * 11.0) * 0.035 if being_cut else 0.0
	draw_set_transform(center, sway, Vector2.ONE)
	draw_texture_rect(TREE_PAINTERLY_TEXTURE, Rect2(Vector2(-size.x * 0.5, -size.y), size), false, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if being_cut:
		for index in range(3):
			var chip_phase := fmod(simulation.elapsed_seconds * 4.0 + float(index) * 0.31, 1.0)
			var chip := center + Vector2(-8.0 + float(index) * 7.0, -12.0 + 14.0 * chip_phase)
			draw_circle(chip, 1.4, Color(0.68, 0.43, 0.18, 0.9 * (1.0 - chip_phase)))


func _draw_rock(center: Vector2) -> void:
	var texture := ROCK_A_TEXTURE if int(abs(center.x + center.y)) % 2 == 0 else ROCK_B_TEXTURE
	draw_texture(texture, center - Vector2(texture.get_width() * 0.5, texture.get_height()))


func _draw_shard(center: Vector2) -> void:
	var strength := 0.22 if simulation.is_night else 0.11
	draw_circle(center + Vector2(0, -42), 70 if simulation.is_night else 48, Color(0.18, 0.58, 1.0, strength))
	draw_arc(center, RivalryTuning.SHARD_CLAIM_RADIUS * TILE_WIDTH * 0.52, 0.0, TAU, 64, Color(0.32, 0.78, 1.0, 0.35), 2.0)
	draw_texture(
		SHARD_TEXTURE,
		center - Vector2(SHARD_TEXTURE.get_width() * 0.5, SHARD_TEXTURE.get_height() - 7.0),
		Color(0.72, 0.90, 1.0, 1.0) if simulation.is_night else Color.WHITE
	)


func _terrain_color(tile: Vector2i, revealed: bool) -> Color:
	if not revealed:
		return Color(0.055, 0.075, 0.07, 1)
	var terrain: String = simulation.get_tile(tile)
	if terrain == Defs.TILE_SHARD:
		return Color(0.22, 0.1, 0.28, 1)
	var pattern := (tile.x * 13 + tile.y * 7 + tile.x * tile.y) % 5
	var elevation_light := float(simulation.get_height(tile)) * 0.025
	if pattern == 0:
		return Color(0.25, 0.43, 0.19, 1).lightened(elevation_light)
	if pattern == 1:
		return Color(0.235, 0.415, 0.18, 1).lightened(elevation_light)
	return Color(0.243, 0.422, 0.184, 1).lightened(elevation_light)


func _resource_color(resource_type: String) -> Color:
	if resource_type == Defs.RESOURCE_WOOD:
		return Color(0.55, 0.31, 0.13, 1)
	if resource_type == Defs.RESOURCE_STONE:
		return Color(0.55, 0.57, 0.57, 1)
	if resource_type == Defs.RESOURCE_PLANKS:
		return Color(0.8, 0.62, 0.33, 1)
	if resource_type == Defs.RESOURCE_WHEAT:
		return Color(0.83, 0.72, 0.28, 1)
	if resource_type == Defs.RESOURCE_BREAD:
		return Color(0.78, 0.44, 0.2, 1)
	return Color(0.9, 0.9, 0.86, 1)


func _construction_fraction(building: Dictionary) -> float:
	var needed: Dictionary = building.get("materials_needed", {})
	var delivered: Dictionary = building.get("materials_delivered", {})
	var needed_total := 0
	var delivered_total := 0
	for resource_type in needed.keys():
		needed_total += int(needed.get(resource_type, 0))
		delivered_total += min(int(delivered.get(resource_type, 0)), int(needed.get(resource_type, 0)))
	var material_fraction := 1.0 if needed_total <= 0 else clampf(float(delivered_total) / float(needed_total), 0.0, 1.0)
	if material_fraction < 1.0:
		return material_fraction * 0.45
	var total_time := float(building.get("construction_total", 0.0))
	if total_time <= 0.0:
		return 1.0
	var remaining := clampf(float(building.get("construction_remaining", total_time)), 0.0, total_time)
	return 0.45 + clampf(1.0 - remaining / total_time, 0.0, 1.0) * 0.55


func _draw_progress_bar(center: Vector2, fraction: float, color: Color, width: float) -> void:
	var height := 5.0
	var bg := Rect2(center.x - width * 0.5, center.y - height * 0.5, width, height)
	draw_rect(bg, Color(0.04, 0.04, 0.04, 0.75), true)
	draw_rect(Rect2(bg.position, Vector2(width * clampf(fraction, 0.0, 1.0), height)), color, true)


func _draw_tile_highlight(tile: Vector2i, color: Color, width: float) -> void:
	if not simulation.is_inside_map(tile):
		return
	var polygon := _tile_polygon(tile)
	draw_colored_polygon(polygon, Color(color.r, color.g, color.b, color.a * 0.13))
	_draw_polygon_outline(polygon, color, width)


func _draw_iso_block(top_center: Vector2, width: float, height: float, depth: float, top: Color, left: Color, right: Color) -> void:
	var top_polygon := _diamond_polygon(top_center, width, height)
	var down := Vector2(0.0, depth)
	var left_face := PackedVector2Array([top_polygon[3], top_polygon[2], top_polygon[2] + down, top_polygon[3] + down])
	var right_face := PackedVector2Array([top_polygon[2], top_polygon[1], top_polygon[1] + down, top_polygon[2] + down])
	draw_colored_polygon(left_face, left)
	draw_colored_polygon(right_face, right)
	draw_colored_polygon(top_polygon, top)
	_draw_polygon_outline(left_face, Color(0.0, 0.0, 0.0, 0.24), 1.0)
	_draw_polygon_outline(right_face, Color(0.0, 0.0, 0.0, 0.2), 1.0)
	_draw_polygon_outline(top_polygon, Color(0.04, 0.05, 0.04, 0.24), 1.0)


func _draw_grounded_iso_block(base_center: Vector2, width: float, height: float, depth: float, top: Color, left: Color, right: Color) -> void:
	var top_center: Vector2 = base_center - Vector2(0.0, height * 0.5 + depth)
	_draw_iso_block(top_center, width, height, depth, top, left, right)


func _diamond_polygon(center: Vector2, width: float, height: float) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(0.0, -height * 0.5),
		center + Vector2(width * 0.5, 0.0),
		center + Vector2(0.0, height * 0.5),
		center + Vector2(-width * 0.5, 0.0)
	])


func _tile_polygon(tile: Vector2i) -> PackedVector2Array:
	return _diamond_polygon(tile_to_world(tile), TILE_WIDTH, TILE_HEIGHT)


func _draw_polygon_outline(polygon: PackedVector2Array, color: Color, width: float) -> void:
	if polygon.is_empty():
		return
	var outline := PackedVector2Array()
	for point in polygon:
		outline.append(point)
	outline.append(polygon[0])
	draw_polyline(outline, color, width, true)


func tile_to_world(tile: Vector2i) -> Vector2:
	var elevation: int = simulation.get_height(tile) if simulation != null else 0
	return Vector2((tile.x - tile.y) * TILE_WIDTH * 0.5, (tile.x + tile.y) * TILE_HEIGHT * 0.5 - float(elevation) * HEIGHT_STEP)


func tile_position_to_world(tile: Vector2, elevation_tile: Vector2i) -> Vector2:
	var elevation: int = simulation.get_height(elevation_tile) if simulation != null else 0
	return Vector2((tile.x - tile.y) * TILE_WIDTH * 0.5, (tile.x + tile.y) * TILE_HEIGHT * 0.5 - float(elevation) * HEIGHT_STEP)


func _continuous_tile_to_world(position: Vector2) -> Vector2:
	if simulation == null:
		return Vector2((position.x - position.y) * TILE_WIDTH * 0.5, (position.x + position.y) * TILE_HEIGHT * 0.5)
	var low := Vector2i(floori(position.x), floori(position.y))
	var high := Vector2i(mini(low.x + 1, simulation.map_size.x - 1), mini(low.y + 1, simulation.map_size.y - 1))
	low.x = clampi(low.x, 0, simulation.map_size.x - 1)
	low.y = clampi(low.y, 0, simulation.map_size.y - 1)
	var fraction := position - Vector2(low)
	var height_top := lerpf(float(simulation.get_height(low)), float(simulation.get_height(Vector2i(high.x, low.y))), fraction.x)
	var height_bottom := lerpf(float(simulation.get_height(Vector2i(low.x, high.y))), float(simulation.get_height(high)), fraction.x)
	var elevation := lerpf(height_top, height_bottom, fraction.y)
	return Vector2(
		(position.x - position.y) * TILE_WIDTH * 0.5,
		(position.x + position.y) * TILE_HEIGHT * 0.5 - elevation * HEIGHT_STEP
	)


func tile_to_object_base(tile: Vector2i) -> Vector2:
	return tile_to_world(tile) + Vector2(0.0, TILE_HEIGHT * 0.58)


func world_to_tile(world_position: Vector2) -> Vector2i:
	var half_width := TILE_WIDTH * 0.5
	var half_height := TILE_HEIGHT * 0.5
	var tile_x := (world_position.x / half_width + world_position.y / half_height) * 0.5
	var tile_y := (world_position.y / half_height - world_position.x / half_width) * 0.5
	var estimate := Vector2i(floori(tile_x), floori(tile_y))
	if simulation == null:
		return estimate
	var best := estimate
	var best_distance := INF
	for y in range(estimate.y - 4, estimate.y + 5):
		for x in range(estimate.x - 4, estimate.x + 5):
			var candidate := Vector2i(x, y)
			if not simulation.is_inside_map(candidate):
				continue
			if Geometry2D.is_point_in_polygon(world_position, _tile_polygon(candidate)):
				var distance := world_position.distance_squared_to(tile_to_world(candidate))
				if distance < best_distance:
					best = candidate
					best_distance = distance
	return best


func _update_hovered_tile() -> void:
	if _pointer_over_ui():
		hovered_tile = Vector2i(-1, -1)
		return
	hovered_tile = world_to_tile(get_global_mouse_position())


func _pointer_over_ui() -> bool:
	var hovered_control := get_viewport().gui_get_hovered_control()
	return hovered_control != null and hovered_control.mouse_filter != Control.MOUSE_FILTER_IGNORE


func _clamp_camera() -> void:
	if camera == null or simulation == null or not is_inside_tree():
		return
	var bounds := _map_bounds().grow(180.0)
	var viewport_size := get_viewport_rect().size / camera.zoom.x
	var half_view := viewport_size * 0.5
	var min_position := bounds.position + half_view
	var max_position := bounds.end - half_view
	if min_position.x > max_position.x:
		camera.position.x = bounds.get_center().x
	else:
		camera.position.x = clampf(camera.position.x, min_position.x, max_position.x)
	if min_position.y > max_position.y:
		camera.position.y = bounds.get_center().y
	else:
		camera.position.y = clampf(camera.position.y, min_position.y, max_position.y)


func _map_bounds() -> Rect2:
	if cached_map_bounds.size != Vector2.ZERO:
		return cached_map_bounds
	var bounds := Rect2(_tile_polygon(Vector2i(0, 0))[0], Vector2.ZERO)
	for y in range(simulation.map_size.y):
		for x in range(simulation.map_size.x):
			for point in _tile_polygon(Vector2i(x, y)):
				bounds = bounds.expand(point)
	cached_map_bounds = bounds
	return cached_map_bounds


func _is_world_visible(point: Vector2, margin: float = 0.0) -> bool:
	if camera == null or not is_inside_tree():
		return true
	var half_view := get_viewport_rect().size * 0.5 / camera.zoom.x
	var visible := Rect2(camera.position - half_view - Vector2.ONE * margin, half_view * 2.0 + Vector2.ONE * margin * 2.0)
	return visible.has_point(point)


func _data_to_tile(data) -> Vector2i:
	if typeof(data) != TYPE_DICTIONARY:
		return Vector2i.ZERO
	return Vector2i(int(data.get("x", 0)), int(data.get("y", 0)))


func _short_build_name(building_type: String) -> String:
	if building_type == Defs.BUILDING_LUMBER_CAMP:
		return "Lumber"
	if building_type == Defs.BUILDING_WATCHTOWER:
		return "Tower"
	if building_type == Defs.BUILDING_LUMEN_PILLAR:
		return "Lumen"
	if building_type == Defs.BUILDING_OUTPOST:
		return "Outpost"
	return Defs.building_name(building_type)
