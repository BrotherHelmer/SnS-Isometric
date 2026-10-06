class_name ProductionGameRoot3D
extends Node3D

const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Simulation = preload("res://src/GodotClient/Scripts/one_shard_simulation.gd")
const Catalog = preload("res://src/GodotClient3D/Scripts/production_asset_catalog.gd")
const ScaleProfile = preload("res://src/GodotClient3D/Scripts/production_scale_profile.gd")
const DemoFixture = preload("res://src/GodotClient3D/Scripts/production_demo_fixture.gd")
const QualityProfile = preload("res://src/GodotClient3D/Scripts/production_quality_profile.gd")
const RivalryTuning = preload("res://src/GodotClient/Scripts/one_shard_rivalry_tuning.gd")
const Identity = preload("res://src/GodotClient3D/Scripts/production_identity.gd")
const AudioDirector = preload("res://src/GodotClient3D/Scripts/production_audio_director.gd")
const PressureMeterScript = preload("res://src/GodotClient3D/Scripts/wyrd_pressure_meter.gd")
const MinimapScript = preload("res://src/GodotClient3D/Scripts/production_minimap.gd")
const DISPLAY_SETTINGS_PATH := "user://display_settings.cfg"
const PREVIOUS_REALM_PATH := "user://previous_realm.json"

const DEFAULT_SEED := 260821
const FIXTURE_SAVE_PATH := "res://artifacts/phase2/persistence/reloaded_fixture.json"
const BUILD_PALETTE := [
	Defs.BUILDING_ROAD,
	Defs.BUILDING_HOUSE,
	Defs.BUILDING_LUMBER_CAMP,
	Defs.BUILDING_QUARRY,
	Defs.BUILDING_FARM,
	Defs.BUILDING_SAWMILL,
	Defs.BUILDING_BAKERY,
	Defs.BUILDING_STOREHOUSE,
	Defs.BUILDING_WALL,
	Defs.BUILDING_WATCHTOWER,
	Defs.BUILDING_BARRACKS,
	Defs.BUILDING_LUMEN_PILLAR,
	Defs.BUILDING_OUTPOST,
	Defs.TOOL_CLEAR_AREA,
]
const BUILD_CATEGORIES := {
	"ESSENTIALS": [Defs.BUILDING_ROAD, Defs.BUILDING_HOUSE, Defs.BUILDING_LUMBER_CAMP, Defs.BUILDING_FARM, Defs.BUILDING_WATCHTOWER, Defs.BUILDING_OUTPOST],
	"INFRASTRUCTURE": [Defs.BUILDING_ROAD, Defs.TOOL_CLEAR_AREA],
	"HOUSING": [Defs.BUILDING_HOUSE],
	"FOOD": [Defs.BUILDING_FARM, Defs.BUILDING_BAKERY],
	"INDUSTRY": [Defs.BUILDING_LUMBER_CAMP, Defs.BUILDING_QUARRY, Defs.BUILDING_SAWMILL, Defs.BUILDING_STOREHOUSE],
	"MILITARY": [Defs.BUILDING_WALL, Defs.BUILDING_WATCHTOWER, Defs.BUILDING_BARRACKS],
	"SPECIAL": [Defs.BUILDING_LUMEN_PILLAR, Defs.BUILDING_OUTPOST],
}
const BUILD_PURPOSES := {
	"ROAD": "Connects buildings and speeds travel.",
	"HOUSE": "Adds housing capacity and shelters residents at night.",
	"LUMBER_CAMP": "Harvests nearby trees into Wood.",
	"QUARRY": "Extracts Stone from a rock deposit.",
	"FARM": "Produces Wheat for the food chain.",
	"SAWMILL": "Turns Wood into Planks.",
	"BAKERY": "Turns Wheat into Bread for residents.",
	"STOREHOUSE": "Expands central resource storage.",
	"WALL": "Extends a defensive wall from a Watchtower.",
	"WATCHTOWER": "A staffed tower fires on visible raiders.",
	"BARRACKS": "Trains a free recruit using Bread and time.",
	"LUMEN_PILLAR": "Extends Lumen so settlement can exist in the Wyrd-corrupted wilds.",
	"CLAIMANT_OUTPOST": "Pushes your realm toward the Shard. Harvests Wyrd and raises night pressure.",
	"CLEAR_AREA": "Mark trees for high-priority clearing. Not required for normal building.",
}
const AUDIO_PATHS := {
	"build_start": "res://assets/settlement/audio/build_start.wav",
	"build_complete": "res://assets/settlement/audio/build_complete.wav",
	"delivery": "res://assets/settlement/audio/delivery.wav",
	"road": "res://assets/settlement/audio/road.wav",
	"enemy": "res://assets/settlement/audio/enemy.wav",
	"night": "res://assets/settlement/audio/night.wav",
	"attack": "res://assets/settlement/audio/attack.wav",
	"tower": "res://assets/settlement/audio/tower.wav",
	"soldier": "res://assets/settlement/audio/soldier.wav",
	"destroyed": "res://assets/settlement/audio/destroyed.wav",
}

@onready var simulation_host: ProductionSimulationHost3D = $SimulationHost
@onready var presentation_adapter: ProductionPresentationAdapterHost3D = $PresentationAdapter
@onready var world_view: ProductionWorldView3D = $WorldView3D
@onready var camera_rig: ProductionIsometricCameraRig3D = $IsometricCameraRig
@onready var lighting_rig: Node3D = $LightingRig
@onready var audio_root: Node = $AudioRoot
@onready var ui_layer: CanvasLayer = $UI

var placement_type := ""
var placement_rotation := 0
var placement_tile := Vector2i(-1, -1)
var placement_validation: Dictionary = {}
var placement_preview_locked := false
var placement_ghost: Node3D
var ghost_footprint: MeshInstance3D
var ghost_access: MeshInstance3D
var ghost_clearing_label: Label3D
var road_dragging := false
var wall_dragging := false
var map_drag_active := false
var map_drag_moved := false
var map_drag_origin := Vector2.ZERO
var road_drag_start := Vector2i(-1, -1)
var road_preview_route: Array[Vector2i] = []
var road_preview_validation: Dictionary = {}
var wall_drag_start := Vector2i(-1, -1)
var wall_preview_route: Array[Vector2i] = []
var selected_building_id := 0
var selected_worker_id := 0
var selected_entity_kind := ""
var last_synced_tick := -1
var ui_elapsed := 0.0
var status_label: Label
var resource_label: Label
var placement_label: Label
var placement_legend_label: Label
var inspector_label: RichTextLabel
var assault_button: Button
var recall_button: Button
var scout_button: Button
var scout_aiming := false
var pause_button: Button
var play_button: Button
var speed_button: Button
var phase_label: Label
var raid_banner_icon: TextureRect
var raid_eta_row: HBoxContainer
var raid_eta_label: Label
var raid_banner_dismissed := false
var raid_banner_active := false
const RAID_BANNER_WIDTH := 372.0
var alert_label: Label
var alert_panel: PanelContainer
var build_panel: PanelContainer
var inspector_panel: PanelContainer
var placement_panel: PanelContainer
var build_toggle_button: Button
var build_category_select: OptionButton
var build_category_sections: Dictionary = {}
var debug_info_button: Button
var current_build_category := "ESSENTIALS"
var build_strip: PanelContainer
var build_strip_buttons: Array = []
## Playtest.31 debug harness (command-line only: --debug-audio-cycle / --debug-ui-scene=).
var debug_audio_cycle_active := false
var debug_ui_scene := ""
var debug_quit_after := false
var debug_clock := 0.0
var debug_stage := 0
## --evidence-capture=<dir>: scripted in-engine PNG captures of the CoS UI scenes
## (viewport texture only; never the desktop). Inert without the flag.
var evidence_capture_dir := ""
## Evidence-only pointer for the placement ghost (synthetic events do not move
## the OS cursor, which get_mouse_position() reports on Windows). x < 0 = unused.
var evidence_mouse_override := Vector2(-1, -1)
## Playtest.31 UI: per-button type/container/cost label for affordability + tooltip gating.
var build_strip_types: Array[String] = []
var build_strip_containers: Array = []
var build_strip_cost_labels: Array = []
var build_strip_dim_nodes: Array = []
var build_strip_tooltips: Array[String] = []
var resource_chip_flash_until: Dictionary = {}
var resource_chip_base_colors: Dictionary = {}
const CHIP_KEYS_BY_RESOURCE := {
	"wood": "wood", "planks": "planks", "stone": "stone", "wheat": "wheat", "bread": "bread", "wyrd": "wyrd"
}
const COLOR_UNAFFORDABLE := Color("#ff6b5a")
# Playtest.31 (T-SNS-009): dimmed buttons keep their cost at full opacity in a
# lighter red with a dark outline so it stays readable.
const COLOR_UNAFFORDABLE_COST := Color("#ff9d8f")
const PLACEMENT_HINT_TEXT_WIDTH := 440.0
const HudSkin = preload("res://src/GodotClient3D/Scripts/production_hud_skin.gd")
const TOP_BAR_HEIGHT := 46.0
const CONSOLE_HEIGHT := 184.0
const MINIMAP_INNER := 128.0
const BUILD_GRID_COLUMNS := 7
const BUILD_SLOT_SIZE := Vector2(70, 58)
const BUILD_HOTKEYS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0, KEY_Z, KEY_X, KEY_C, KEY_V]
const BUILD_HOTKEY_LABELS := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "Z", "X", "C", "V"]
const RATE_WINDOW_SECONDS := 30.0
const STRIP_SHORT_NAMES := {"LUMBER_CAMP": "Lumber", "LUMEN_PILLAR": "Lumen", "CLEAR_AREA": "Clear"}
const NOTICE_FEED_LIMIT := 4
## T-SNS-UI leftovers: idle-worker notice. Game seconds a free worker may stand
## idle (by day) before the left feed says so, and the minimum gap between notices.
const IDLE_NOTICE_AFTER_SECONDS := 40.0
const IDLE_NOTICE_COOLDOWN_SECONDS := 150.0
var hud_console: PanelContainer
var selection_host: PanelContainer
var realm_overview: RichTextLabel
var portrait_host: Control
var portrait_hp_bar: ProgressBar
var portrait_hp_fill: StyleBoxFlat
var portrait_hp_label: Label
var portrait_key := ""
var status_plate: PanelContainer
var notice_feed: VBoxContainer
var notice_feed_entries: Array = []
var soldier_label: Label
var day_icon: TextureRect
var phase_bar: ProgressBar
var resource_rate_labels: Dictionary = {}
var resource_rate_history: Array = []
var startup_overlay: Control
var menu_backdrop: TextureRect
var seed_edit: LineEdit
var quality_select: OptionButton
var build_buttons: Dictionary = {}
var fixture_stage := ""
var fixture_requested := false
var fixture_result: Dictionary = {}
var quality_profile: Dictionary = QualityProfile.get_profile("recommended")
var current_frame_snapshot: Dictionary = {}
var environment_resource: Environment
var sun_light: DirectionalLight3D
var fill_light: DirectionalLight3D
var sky_material: ProceduralSkyMaterial
var audio_players: Dictionary = {}
var ambient_player: AudioStreamPlayer
var status_message_until := 0.0
var status_message_text := ""
var debug_visible := false
var objective_label: Label
var pressure_label: Label
var loop_label: Label
var bind_button: Button
var result_overlay: Control
var result_title: Label
var result_body: RichTextLabel
var confirm_overlay: Control
var menu_card: Control
var new_realm_card: Control
var settings_card: Control
var continue_button: Button
var resume_button: Button
var menu_save_button: Button
var play_camera_focus := Vector3.ZERO
var play_camera_zoom := ProductionIsometricCameraRig3D.NORMAL_ZOOM
var reach_guidance_shown := false
var last_objective_id := ""
var last_run_seed := DEFAULT_SEED
var hud_root: Control
var play_has_begun := false
var resource_chips: Dictionary = {}
var time_label: Label
var population_label: Label
var pressure_meter: Control
var audio_director
var nightfall_panel: PanelContainer
var nightfall_label: Label
var nightfall_event_until := 0.0
var last_nightfall_day := -1
var master_slider: HSlider
var music_slider: HSlider
var sfx_slider: HSlider
var fullscreen_check: CheckBox
var result_more_button: Button
var result_more_stats := false
var last_result_stats: Dictionary = {}
var work_audio_elapsed := 0.0
var seed_advanced: Control
var binding_percent_label: Label
var toast_title: Label
var toast_body: Label
var toast_until := 0.0
var toast_severity := "info"
var event_log_button: Button
var event_log_panel: PanelContainer
var event_log_body: RichTextLabel
var objective_detail_panel: PanelContainer
var objective_detail_body: Label
var objective_button: Button
var shard_glance_until := 0.0
var shard_glance_from := Vector3.ZERO
var shard_compass: Label
var minimap
var clear_dragging := false
var clear_drag_start := Vector2i(-1, -1)
var last_toast_key := ""
## HUD clock: accumulated frame time. Toasts and feed entries age on it instead of
## the wall clock, so a slow frame (software GL, hitch) cannot swallow a notice.
var hud_clock := 0.0
var idle_workers_button: Button
var idle_workers_since := 0.0
var idle_workers_tracking := false
var idle_notice_last := -1000000.0


func _ready() -> void:
	get_tree().auto_accept_quit = false
	simulation_host.autosave_finished.connect(func(success: bool, message: String) -> void:
		_show_status("Autosaved." if success else "AUTOSAVE FAILED · " + message, 4.0)
	)
	get_window().title = "Shard & Sovereign"
	call_deferred("_apply_window_title")
	var launch := _parse_launch_options()
	quality_profile = QualityProfile.get_profile(String(launch.get("quality", "recommended")))
	_create_lighting()
	_create_ui()
	_restore_display_settings()
	_create_audio()
	_create_placement_ghost()
	fixture_stage = String(launch.get("fixture", ""))
	fixture_requested = fixture_stage != ""
	var loaded := false
	if bool(launch.get("load", false)):
		loaded = simulation_host.load_existing()
	if not loaded:
		simulation_host.start_new(int(launch.get("seed", DEFAULT_SEED)), true)
	_initialize_presentation()
	if fixture_requested:
		call_deferred("_apply_requested_fixture")
	var auto_start := bool(launch.get("autostart", false)) or fixture_requested or bool(launch.get("load", false))
	if auto_start:
		_hide_start_menu()
		simulation_host.paused = false
	else:
		simulation_host.paused = true
		_show_start_menu()
	if "--verify-release" in OS.get_cmdline_user_args():
		call_deferred("_run_release_check")
	debug_audio_cycle_active = bool(launch.get("debug_audio_cycle", false))
	debug_ui_scene = String(launch.get("debug_ui_scene", ""))
	debug_quit_after = bool(launch.get("debug_quit", false))
	evidence_capture_dir = String(launch.get("evidence_capture", ""))
	if evidence_capture_dir != "":
		call_deferred("_run_evidence_capture")
	elif String(launch.get("evidence_ui", "")) != "":
		evidence_capture_dir = String(launch.get("evidence_ui", ""))
		call_deferred("_run_ui_evidence_capture")
	if debug_audio_cycle_active or debug_ui_scene != "":
		print("[%s] DEBUG_LAUNCH audio_cycle=%s ui_scene=%s version=%s" % [Time.get_datetime_string_from_system(), str(debug_audio_cycle_active), debug_ui_scene, String(ProjectSettings.get_setting("application/config/version", ""))])


func _run_release_check() -> void:
	var check_script = load("res://src/GodotClient3D/Scripts/production_release_check.gd")
	await check_script.run(self)


func _process(delta: float) -> void:
	hud_clock += delta
	var ticks := simulation_host.advance(delta)
	if ticks > 0 or last_synced_tick < 0:
		_sync_presentation()
	_update_placement_ghost()
	ui_elapsed += delta
	if ui_elapsed >= 0.15:
		ui_elapsed = 0.0
		_update_ui()
		_update_day_night_lighting()
	_process_audio_events()
	_tick_audio(delta)
	if debug_audio_cycle_active or debug_ui_scene != "":
		_tick_debug_harness(delta)
	_tick_toasts(delta)
	_tick_notice_feed()
	_tick_shard_glance()
	_tick_edge_pan(delta)
	_update_shard_compass()
	_tick_minimap(delta)
	if simulation_host.simulation != null and simulation_host.simulation.game_finished:
		if result_overlay != null and not result_overlay.visible and (startup_overlay == null or not startup_overlay.visible):
			_show_result_screen()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R and placement_type != "":
			placement_rotation = posmod(placement_rotation + 1, 4)
			_refresh_build_pads()
			_update_placement_ghost(true)
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_ESCAPE and placement_type != "":
			_cancel_road_drag()
			cancel_placement()
			_set_build_palette_visible(false)
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_ESCAPE and build_panel != null and build_panel.visible:
			_set_build_palette_visible(false)
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_ESCAPE and scout_aiming:
			scout_aiming = false
			_show_status("Scout cancelled.")
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_ESCAPE and objective_detail_panel != null and objective_detail_panel.visible:
			_show_objective_detail(false)
			get_viewport().set_input_as_handled()
			return
		if startup_overlay != null and startup_overlay.visible:
			return
		if _handle_hud_hotkey(event as InputEventKey):
			get_viewport().set_input_as_handled()
			return
		match event.keycode:
			KEY_F3:
				debug_visible = not debug_visible
				if debug_info_button != null:
					debug_info_button.visible = debug_visible
				if startup_overlay != null:
					var review := startup_overlay.find_child("NewReviewSeed", true, false)
					if review != null:
						review.visible = debug_visible
					var legacy := startup_overlay.find_child("Legacy2D", true, false)
					if legacy != null:
						legacy.visible = debug_visible
				_show_status("Developer diagnostics %s." % ["shown" if debug_visible else "hidden"])
		if event.keycode == KEY_F3:
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseMotion and clear_dragging:
		_update_clear_drag(event.position)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and road_dragging:
		_update_road_drag_preview(event.position)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and wall_dragging:
		_update_wall_drag_preview(event.position)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and map_drag_active:
		if not map_drag_moved and event.position.distance_to(map_drag_origin) > 8.0:
			map_drag_moved = true
		if map_drag_moved and camera_rig != null:
			camera_rig.pan_from_mouse(event.relative)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _pointer_over_ui():
				return
			if placement_type == Defs.BUILDING_ROAD:
				_start_road_drag(event.position)
			elif placement_type == Defs.BUILDING_WALL:
				_start_wall_drag(event.position)
			elif placement_type == Defs.TOOL_CLEAR_AREA:
				_start_clear_drag(event.position)
			elif placement_type != "":
				_commit_placement()
			else:
				_set_build_palette_visible(false)
				map_drag_active = true
				map_drag_moved = false
				map_drag_origin = event.position
			get_viewport().set_input_as_handled()
		else:
			var consumed := road_dragging or wall_dragging or clear_dragging or map_drag_active
			if road_dragging:
				_finish_road_drag(event.position)
			if wall_dragging:
				_finish_wall_drag(event.position)
			if clear_dragging:
				_finish_clear_drag(event.position)
			if map_drag_active:
				if not map_drag_moved:
					if scout_aiming:
						_commit_scout_click(event.position)
					else:
						_select_from_pointer(event.position)
				map_drag_active = false
				map_drag_moved = false
			if consumed:
				get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			if road_dragging or wall_dragging or clear_dragging or placement_type != "":
				_cancel_road_drag()
				_cancel_wall_drag()
				clear_dragging = false
				cancel_placement()
				_set_build_palette_visible(false)
				get_viewport().set_input_as_handled()
				return
			if not _pointer_over_ui() and camera_rig != null:
				camera_rig.begin_pointer_pan()
				get_viewport().set_input_as_handled()
		else:
			if camera_rig != null:
				camera_rig.end_pointer_pan()
		return


## T-SNS-UI: every console action has a hotkey, and every hotkey is printed
## on its button or tooltip so the UI teaches it.
func _handle_hud_hotkey(event: InputEventKey) -> bool:
	if not play_has_begun or event.ctrl_pressed or event.alt_pressed or event.meta_pressed:
		return false
	if result_overlay != null and result_overlay.visible:
		return false
	if confirm_overlay != null and confirm_overlay.visible:
		return false
	var slot := BUILD_HOTKEYS.find(event.keycode)
	if slot >= 0 and slot < build_strip_types.size():
		begin_placement(build_strip_types[slot])
		return true
	match event.keycode:
		KEY_SPACE:
			_toggle_pause()
			return true
		KEY_B:
			_toggle_build_palette()
			return true
		KEY_L:
			_toggle_event_log()
			return true
		KEY_H:
			_select_town_hall()
			return true
		KEY_Y:
			if _begin_scout_aim():
				return true
	return false


func _begin_scout_aim() -> bool:
	if simulation_host.simulation == null:
		return false
	var worker: Dictionary = simulation_host.simulation.get_worker_by_id(selected_worker_id) if selected_worker_id > 0 else {}
	if worker.is_empty() or not simulation_host.simulation.is_patrol_scout(worker) or worker.has("scout_mission"):
		_show_status("Select a free patrol soldier, then press Scout (Y).")
		return false
	scout_aiming = true
	cancel_placement()
	_show_status("Scout Direction — click into the fog. %s will walk there and return on his own." % String(worker.get("display_name", "The soldier")))
	return true


func _commit_scout_click(screen_position: Vector2) -> void:
	scout_aiming = false
	if simulation_host.simulation == null or world_view == null:
		return
	var hit: Dictionary = _raycast_terrain(screen_position)
	if hit.is_empty():
		_show_status("Click the land to choose a scouting direction.")
		return
	var tile := world_view.world_to_tile(hit.position)
	var result: Dictionary = simulation_host.simulation.request_scout_direction(selected_worker_id, tile)
	_show_command_result(result)


func _select_town_hall() -> void:
	if simulation_host.simulation == null:
		return
	for building_value in simulation_host.simulation.buildings:
		var building: Dictionary = building_value
		if String(building.get("type", "")) == Defs.BUILDING_TOWN_HALL:
			select_building(int(building.get("id", 0)))
			if camera_rig != null:
				camera_rig.focus_world(world_view.tile_to_world(Vector2(Vector2i(building.get("position", Vector2i.ZERO))) + Vector2(1.5, 1.5)))
			return


func start_new_3d(seed_value := DEFAULT_SEED) -> void:
	last_run_seed = seed_value
	if result_overlay != null:
		result_overlay.visible = false
	if confirm_overlay != null:
		confirm_overlay.visible = false
	simulation_host.start_new(seed_value, true)
	play_has_begun = false
	reach_guidance_shown = false
	last_objective_id = ""
	selected_building_id = 0
	selected_worker_id = 0
	selected_entity_kind = ""
	cancel_placement()
	_initialize_presentation()
	simulation_host.paused = false
	_hide_start_menu()
	_show_status("Settlement founded.", 3.0)


func save_game() -> bool:
	var success := simulation_host.save_current()
	_show_status("Settlement saved." if success else "SAVE FAILED · %s" % simulation_host.simulation.get_last_message(), 4.0)
	return success


func load_game() -> bool:
	var success := simulation_host.load_existing()
	if success:
		selected_building_id = 0
		selected_worker_id = 0
		selected_entity_kind = ""
		cancel_placement()
		_initialize_presentation()
		simulation_host.paused = false
		_hide_start_menu()
	_show_status("Settlement loaded." if success else "LOAD FAILED · %s" % simulation_host.simulation.get_last_message(), 4.0)
	return success


func begin_placement(building_type: String) -> void:
	# Check affordability first
	if simulation_host.simulation != null and building_type != Defs.TOOL_CLEAR_AREA:
		var missing_info: Array = _missing_resources(building_type)
		if not missing_info.is_empty():
			var missing: Array[String] = []
			for entry_value in missing_info:
				var entry: Dictionary = entry_value
				missing.append("%s (%d/%d)" % [String(entry["resource"]).capitalize(), int(entry["have"]), int(entry["need"])])
				_flash_resource_chip(String(entry["resource"]), 2.6)
			# One action -> one message: drop any stale placement (and its INVALID
			# footprint hint) so only the resource toast explains the refusal.
			if placement_type != "":
				cancel_placement()
			audio_director.play_ui_click()
			_show_toast("Insufficient Resources", "%s needs %s" % [Defs.building_name(building_type), ", ".join(missing)], "warning", 3.5)
			simulation_host.simulation.note_player_command("resource_blocked", String(building_type))
			return
	
	# Cancel any existing placement or dragging state first
	_cancel_road_drag()
	_cancel_wall_drag()
	map_drag_active = false
	map_drag_moved = false
	# Now start fresh placement
	placement_preview_locked = false
	placement_type = building_type
	if simulation_host.simulation != null:
		simulation_host.simulation.note_player_command("player_command", "place:%s" % building_type)
	placement_rotation = 0
	placement_ghost.visible = true
	selected_building_id = 0
	selected_worker_id = 0
	selected_entity_kind = ""
	world_view.set_selection(0, 0)
	world_view.set_watchtower_overlay(Vector2.ZERO, 0.0, false)
	inspector_panel.visible = false
	placement_panel.visible = true
	var instruction := ""
	var legend := ""
	if building_type == Defs.TOOL_CLEAR_AREA:
		instruction = "drag to mark trees · right-click cancels"
		legend = ""
	elif building_type in [Defs.BUILDING_ROAD, Defs.BUILDING_WALL]:
		instruction = "hold and drag to draw · right-click cancels"
		legend = ""
	else:
		instruction = "R rotates · click to place · right-click cancels"
		legend = "GREEN = valid · YELLOW = needs clearing · RED = blocked"
	placement_label.text = "%s · %s" % [Defs.building_name(building_type), instruction]
	placement_legend_label.text = legend
	world_view.set_claim_overlay_visible(building_type in [Defs.BUILDING_LUMEN_PILLAR, Defs.BUILDING_OUTPOST])
	_set_build_palette_visible(false)
	_show_objective_detail(false)
	_refresh_build_pads()
	_update_placement_ghost(true)


func cancel_placement() -> void:
	_cancel_road_drag()
	_cancel_wall_drag()
	map_drag_active = false
	map_drag_moved = false
	placement_preview_locked = false
	placement_type = ""
	placement_tile = Vector2i(-1, -1)
	placement_validation.clear()
	if world_view != null:
		world_view.set_claim_overlay_visible(false)
		world_view.clear_road_preview()
		world_view.clear_build_pads()
	if placement_ghost != null:
		placement_ghost.visible = false
	if placement_label != null:
		placement_label.text = ""
	if placement_legend_label != null:
		placement_legend_label.text = ""
	if placement_panel != null:
		placement_panel.visible = false


func select_building(id: int) -> void:
	selected_building_id = id
	selected_worker_id = 0
	selected_entity_kind = "building"
	world_view.set_selection(selected_building_id, selected_worker_id)
	var building: Dictionary = simulation_host.simulation.get_building_by_id(id)
	var display_type := String(building.get("planned_type", "")) if bool(building.get("construction", false)) else String(building.get("type", ""))
	var center: Vector2i = simulation_host.simulation._footprint_center(Vector2i(building.get("position", Vector2i.ZERO)), simulation_host.simulation._building_footprint(building)) if not building.is_empty() else Vector2i.ZERO
	world_view.set_watchtower_overlay(Vector2(center), float(Simulation.TOWER_RANGE), display_type == Defs.BUILDING_WATCHTOWER)
	world_view.set_claim_overlay_visible(display_type in [Defs.BUILDING_LUMEN_PILLAR, Defs.BUILDING_OUTPOST])
	_update_inspector()


func select_worker(id: int) -> void:
	selected_worker_id = id
	selected_building_id = 0
	selected_entity_kind = "worker"
	world_view.set_selection(selected_building_id, selected_worker_id)
	world_view.set_watchtower_overlay(Vector2.ZERO, 0.0, false)
	_update_inspector()


func _initialize_presentation() -> void:
	var world_snapshot := presentation_adapter.capture_world(simulation_host.simulation)
	world_view.setup(simulation_host.simulation, world_snapshot, quality_profile)
	world_view.bind_fog_overlay(camera_rig.camera)
	camera_rig.configure_for_map(simulation_host.simulation.map_size)
	var town_center := Vector2(simulation_host.simulation.town_hall_position) + Vector2(1.5, 1.5)
	camera_rig.compose_view(world_view.tile_to_world(town_center), ProductionIsometricCameraRig3D.NORMAL_ZOOM)
	if minimap != null:
		minimap.bind(simulation_host.simulation, world_view, camera_rig)
	last_synced_tick = -1
	_sync_presentation()


func _sync_presentation() -> void:
	var frame := presentation_adapter.capture_frame(simulation_host.simulation, simulation_host.render_lead_seconds())
	current_frame_snapshot = frame
	world_view.sync_frame(frame)
	var frontier_pad := 48.0 if placement_type != "" else 28.0
	camera_rig.configure_pan_bounds(world_view.revealed_camera_bounds(camera_rig.target_zoom, frontier_pad))
	last_synced_tick = int(frame.get("tick", -1))


func _create_lighting() -> void:
	get_viewport().msaa_3d = Viewport.MSAA_2X if bool(quality_profile.get("shadows", true)) else Viewport.MSAA_DISABLED
	var environment_node := WorldEnvironment.new()
	environment_node.name = "ShardlitEnvironment"
	var environment := Environment.new()
	environment_resource = environment
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material_value := ProceduralSkyMaterial.new()
	sky_material = sky_material_value
	sky_material_value.sky_top_color = Color("#3E5A68")
	sky_material_value.sky_horizon_color = Color("#C4A882")
	sky_material_value.ground_bottom_color = Color("#14241E")
	sky_material_value.ground_horizon_color = Color("#2E4036")
	sky.sky_material = sky_material_value
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#718FA3")
	environment.ambient_light_energy = 0.62
	# The Director: AgX carries contrast. B/C/S stay near 1.0; period 3D LUTs lift shadows.
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	environment.tonemap_exposure = 1.0
	environment.tonemap_white = 8.0
	environment.ssao_enabled = bool(quality_profile.get("ssao", quality_profile.get("shadows", true)))
	# The Director: GFX-04 Forward+ SSAO at ~1 m, low direct-light dirt.
	# Half-res is the project default (rendering/environment/ssao/half_size).
	environment.ssao_radius = 0.95
	environment.ssao_intensity = 1.05
	environment.ssao_power = 1.25
	environment.ssao_detail = 0.50
	environment.ssao_horizon = 0.06
	# Sharp half-res SSAO striped the flats when the camera panned.
	environment.ssao_sharpness = 0.35
	environment.ssao_light_affect = 0.10
	environment.ssao_ao_channel_affect = 0.55
	environment.ssil_enabled = bool(quality_profile.get("ssil", false))
	environment.ssil_radius = 3.0
	environment.ssil_intensity = 0.75
	environment.ssil_sharpness = 0.96
	environment.glow_enabled = bool(quality_profile.get("glow", false))
	environment.glow_normalized = true
	environment.glow_intensity = 0.22
	environment.glow_strength = 0.85
	environment.glow_bloom = 0.08
	environment.set("glow_levels/1", 0.0)
	environment.set("glow_levels/2", 1.0)
	environment.set("glow_levels/3", 0.75)
	environment.set("glow_levels/4", 0.45)
	environment.set("glow_levels/5", 0.0)
	environment.set("glow_levels/6", 0.0)
	environment.set("glow_levels/7", 0.0)
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.94
	environment.adjustment_contrast = 1.0
	environment.adjustment_brightness = 1.0
	environment.adjustment_color_correction = Identity.grade_lut_for("day")
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_light_color = Color("#607681")
	environment.fog_light_energy = 0.55
	environment.fog_density = 0.0
	environment.fog_height = 0.0
	environment.fog_height_density = 0.0
	environment.fog_aerial_perspective = 0.55
	environment.fog_sun_scatter = 0.25
	environment.fog_depth_begin = 28.0
	environment.fog_depth_end = 65.0
	environment.volumetric_fog_enabled = bool(quality_profile.get("volumetric_fog", false))
	environment_node.environment = environment
	lighting_rig.add_child(environment_node)
	var sun := DirectionalLight3D.new()
	sun_light = sun
	sun.name = "Sun"
	sun.light_color = Color("#FFD09A")
	sun.light_energy = 1.25
	# The Director: GFX-05 one key sun, PSSM 2-split, no PCSS softness.
	sun.light_angular_distance = 0.0
	sun.shadow_enabled = bool(quality_profile.get("shadows", true))
	_apply_sun_shadow_settings(sun)
	lighting_rig.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill_light = fill
	fill.name = "CoolFill"
	fill.light_color = Color("#7A93A6")
	fill.light_energy = 0.18
	fill.shadow_enabled = false
	lighting_rig.add_child(fill)
	_apply_lighting_palette(Identity.lighting_palette("day"))


func _create_ui() -> void:
	var root := Control.new()
	root.name = "ProductionHUD"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(root)
	hud_root = root

	# T-SNS-UI: one shared stone-and-gold theme for every HUD control.
	root.theme = HudSkin.hud_theme()

	# T-SNS-UI Look lift: the top bar is regrouped into navy capsules —
	# economy (values with per-minute rates underneath), people (population with
	# the idle count as a sub-label, soldiers), the clock ("Night in m:ss"), a
	# pressure chip that only appears when something is happening, then BUILD
	# and the icon speed controls on the right.
	var top_panel := PanelContainer.new()
	top_panel.name = "TopBar"
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_left = 0.0
	top_panel.offset_top = 0.0
	top_panel.offset_right = 0.0
	top_panel.offset_bottom = TOP_BAR_HEIGHT
	var bar_style := HudSkin.frame("bar", 6.0)
	bar_style.content_margin_top = 4.0
	bar_style.content_margin_bottom = 4.0
	top_panel.add_theme_stylebox_override("panel", bar_style)
	root.add_child(top_panel)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 6)
	top_panel.add_child(top_row)
	var chip_host := _top_capsule(top_row, "ResourceStrip")
	resource_label = Label.new()
	resource_label.visible = false
	chip_host.add_child(resource_label)
	resource_chips["wood"] = _add_resource_chip(chip_host, "wood", "Wood")
	resource_chips["planks"] = _add_resource_chip(chip_host, "planks", "Planks")
	resource_chips["stone"] = _add_resource_chip(chip_host, "stone", "Stone")
	resource_chips["wheat"] = _add_resource_chip(chip_host, "wheat", "Wheat")
	resource_chips["bread"] = _add_resource_chip(chip_host, "bread", "Bread")
	resource_chips["wyrd"] = _add_resource_chip(chip_host, "wyrd", "Wyrd")
	var people_host := _top_capsule(top_row, "PeopleGroup")
	population_label = _add_top_stat(people_host, "PopulationChip", "pop", "Population / housing")
	idle_workers_button = _add_idle_workers_button(population_label.get_parent())
	soldier_label = _add_top_stat(people_host, "SoldierChip", "soldier", "Soldiers (free / total)")
	var soldier_sub := Label.new()
	soldier_sub.name = "SoldierSub"
	soldier_sub.text = "free / total"
	soldier_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	HudSkin.set_font(soldier_sub, HudSkin.ui_font(400), HudSkin.SIZE_MIN, HudSkin.COLOR_CAPTION)
	soldier_label.get_parent().add_child(soldier_sub)
	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(top_spacer)
	var clock := _top_capsule(top_row, "DayClock")
	clock.tooltip_text = "Day and time until the next phase"
	clock.get_parent().tooltip_text = clock.tooltip_text
	clock.get_parent().mouse_filter = Control.MOUSE_FILTER_STOP
	day_icon = HudSkin.icon_rect("sun", 24.0)
	clock.add_child(day_icon)
	var clock_stack := VBoxContainer.new()
	clock_stack.add_theme_constant_override("separation", -2)
	clock_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	clock_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clock_stack.custom_minimum_size.x = 84.0
	clock.add_child(clock_stack)
	time_label = Label.new()
	time_label.name = "TimeChip"
	time_label.tooltip_text = "Day and time"
	time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	HudSkin.set_font(time_label, HudSkin.ui_font(700), HudSkin.SIZE_VALUE - 1, HudSkin.COLOR_GOLD)
	clock_stack.add_child(time_label)
	phase_label = Label.new()
	phase_label.name = "PhaseCountdown"
	phase_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	HudSkin.set_font(phase_label, HudSkin.ui_font(600), HudSkin.SIZE_CAPTION, HudSkin.COLOR_TEXT)
	clock_stack.add_child(phase_label)
	phase_bar = ProgressBar.new()
	phase_bar.name = "PhaseProgress"
	phase_bar.show_percentage = false
	phase_bar.custom_minimum_size = Vector2(84, 3)
	phase_bar.max_value = 1.0
	phase_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var phase_bg := StyleBoxFlat.new()
	phase_bg.bg_color = Color(0.02, 0.03, 0.03, 0.9)
	var phase_fill := StyleBoxFlat.new()
	phase_fill.bg_color = HudSkin.COLOR_GOLD_DIM
	phase_bar.add_theme_stylebox_override("background", phase_bg)
	phase_bar.add_theme_stylebox_override("fill", phase_fill)
	clock_stack.add_child(phase_bar)
	pressure_meter = PressureMeterScript.new()
	pressure_meter.name = "WyrdPressure"
	# Look lift: the chip is hidden while the realm is QUIET by day (see
	# _pressure_chip_should_show); it appears for rising pressure, night or a raid.
	pressure_meter.visible = false
	pressure_meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_row.add_child(pressure_meter)
	var top_spacer_right := Control.new()
	top_spacer_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_spacer_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(top_spacer_right)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.custom_minimum_size.x = 118.0
	status_label.clip_text = true
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color("#d6bd7c"))
	status_label.visible = false
	root.add_child(status_label)
	build_toggle_button = Button.new()
	build_toggle_button.name = "BuildMenuToggle"
	build_toggle_button.text = "Build"
	build_toggle_button.icon = HudSkin.icon("hammer")
	build_toggle_button.toggle_mode = true
	build_toggle_button.tooltip_text = "Open the full list of settlement plans  [B]"
	build_toggle_button.pressed.connect(_toggle_build_palette)
	build_toggle_button.custom_minimum_size = Vector2(84, 32)
	build_toggle_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	build_toggle_button.focus_mode = Control.FOCUS_NONE
	build_toggle_button.add_theme_constant_override("icon_max_width", 18)
	HudSkin.apply_button(build_toggle_button, true)
	HudSkin.set_font(build_toggle_button, HudSkin.ui_font(700), HudSkin.SIZE_BODY)
	var build_cell := Control.new()
	build_cell.name = "BuildToggleCell"
	build_cell.custom_minimum_size = build_toggle_button.custom_minimum_size
	build_cell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	build_cell.add_child(build_toggle_button)
	build_toggle_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_attach_hotkey_badge(build_cell, "B")
	top_row.add_child(build_cell)
	var controls := _top_capsule(top_row, "SpeedControls")
	controls.add_theme_constant_override("separation", 3)
	pause_button = HudSkin.icon_button("pause", "Pause  [Space]", 30.0)
	pause_button.name = "PauseGame"
	pause_button.toggle_mode = true
	pause_button.focus_mode = Control.FOCUS_NONE
	pause_button.pressed.connect(_toggle_pause)
	controls.add_child(pause_button)
	play_button = HudSkin.icon_button("play", "Play at normal speed (1x)", 30.0)
	play_button.name = "PlayNormal"
	play_button.toggle_mode = true
	play_button.focus_mode = Control.FOCUS_NONE
	play_button.pressed.connect(_play_normal_speed)
	controls.add_child(play_button)
	speed_button = HudSkin.icon_button("fast", "Fast forward: 2x, press again for 4x", 30.0)
	speed_button.name = "GameSpeed"
	speed_button.toggle_mode = true
	speed_button.focus_mode = Control.FOCUS_NONE
	speed_button.custom_minimum_size.x = 30.0
	speed_button.pressed.connect(_cycle_speed)
	controls.add_child(speed_button)
	for control_button in [pause_button, play_button, speed_button]:
		HudSkin.apply_button(control_button, true)
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			var box: StyleBoxTexture = (control_button as Button).get_theme_stylebox(state)
			box.content_margin_left = 6.0
			box.content_margin_right = 6.0
			box.content_margin_top = 6.0
			box.content_margin_bottom = 6.0
	var menu_button := HudSkin.icon_button("menu", "Main menu, save and settings", 30.0)
	menu_button.name = "MainMenu"
	menu_button.focus_mode = Control.FOCUS_NONE
	menu_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	menu_button.pressed.connect(_show_start_menu)
	controls.add_child(_hud_divider())
	controls.add_child(menu_button)
	_sync_speed_controls()

	# Objective plate (left) and pressure/rival status plate (right) replace the
	# old full-width loop bar; the gap between them stays click-through.
	var loop_panel := HBoxContainer.new()
	loop_panel.name = "LoopBar"
	loop_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	loop_panel.offset_left = 8.0
	loop_panel.offset_top = TOP_BAR_HEIGHT + 4.0
	loop_panel.offset_right = -8.0
	loop_panel.offset_bottom = TOP_BAR_HEIGHT + 40.0
	loop_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loop_panel.add_theme_constant_override("separation", 8)
	root.add_child(loop_panel)
	var objective_plate := PanelContainer.new()
	objective_plate.name = "ObjectivePlate"
	# Look lift: the objective is a slim pill (quest icon, text, chevron that
	# opens the goal list); LOG is its own button beside it.
	objective_plate.custom_minimum_size.x = 440.0
	var pill_style := HudSkin.frame("capsule", 4.0)
	pill_style.content_margin_left = 6.0
	pill_style.content_margin_right = 4.0
	objective_plate.add_theme_stylebox_override("panel", pill_style)
	loop_panel.add_child(objective_plate)
	var loop_row := HBoxContainer.new()
	loop_row.add_theme_constant_override("separation", 6)
	objective_plate.add_child(loop_row)
	loop_row.add_child(HudSkin.icon_rect("quest", 22.0))
	objective_button = Button.new()
	objective_button.name = "MacroObjective"
	objective_button.flat = true
	objective_button.clip_text = true
	objective_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	objective_button.pressed.connect(_toggle_objective_detail)
	Identity.apply_button(objective_button)
	for flat_state in ["normal", "pressed", "hover_pressed", "disabled"]:
		objective_button.add_theme_stylebox_override(flat_state, StyleBoxEmpty.new())
	var objective_hover := StyleBoxFlat.new()
	objective_hover.bg_color = Color(0.94, 0.78, 0.5, 0.10)
	objective_button.add_theme_stylebox_override("hover", objective_hover)
	HudSkin.set_font(objective_button, HudSkin.ui_font(600), HudSkin.SIZE_BODY + 1, Color("#fff1cf"))
	objective_button.tooltip_text = "Current objective: click for the goal list"
	loop_row.add_child(objective_button)
	var chevron := Button.new()
	chevron.name = "ObjectiveChevron"
	chevron.text = "›"
	chevron.flat = true
	chevron.focus_mode = Control.FOCUS_NONE
	chevron.custom_minimum_size = Vector2(22, 24)
	chevron.tooltip_text = "Show all goals"
	HudSkin.set_font(chevron, HudSkin.ui_font(700), HudSkin.SIZE_TITLE + 2, HudSkin.COLOR_GOLD)
	chevron.pressed.connect(_toggle_objective_detail)
	loop_row.add_child(chevron)
	objective_label = Label.new()
	objective_label.visible = false
	loop_row.add_child(objective_label)
	event_log_button = Button.new()
	event_log_button.name = "EventLogToggle"
	event_log_button.text = "Log"
	event_log_button.tooltip_text = "Event log: every notice this realm has raised  [L]"
	event_log_button.custom_minimum_size = Vector2(52.0, 30.0)
	event_log_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	event_log_button.focus_mode = Control.FOCUS_NONE
	HudSkin.apply_button(event_log_button)
	HudSkin.set_font(event_log_button, HudSkin.ui_font(700), HudSkin.SIZE_CAPTION + 1)
	event_log_button.pressed.connect(_toggle_event_log)
	var log_cell := Control.new()
	log_cell.name = "EventLogCell"
	log_cell.custom_minimum_size = event_log_button.custom_minimum_size
	log_cell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	log_cell.add_child(event_log_button)
	event_log_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_attach_hotkey_badge(log_cell, "L")
	loop_panel.add_child(log_cell)
	pressure_label = Label.new()
	pressure_label.visible = false
	loop_panel.add_child(pressure_label)
	var loop_gap := Control.new()
	loop_gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	loop_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loop_panel.add_child(loop_gap)
	status_plate = PanelContainer.new()
	status_plate.name = "ThreatPlate"
	var status_style := HudSkin.frame("panel", 5.0)
	status_style.content_margin_left = 12.0
	status_style.content_margin_right = 12.0
	status_plate.add_theme_stylebox_override("panel", status_style)
	loop_panel.add_child(status_plate)
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 8)
	status_plate.add_child(status_row)
	loop_label = Label.new()
	loop_label.name = "LoopStatus"
	loop_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loop_label.add_theme_font_size_override("font_size", 14)
	loop_label.add_theme_color_override("font_color", Color("#e6dcc0"))
	status_row.add_child(loop_label)
	bind_button = Button.new()
	bind_button.name = "BeginBinding"
	bind_button.text = "BIND THE SHARD"
	bind_button.visible = false
	bind_button.custom_minimum_size.x = 132.0
	Identity.apply_button(bind_button, true)
	bind_button.pressed.connect(_prompt_binding)
	status_row.add_child(bind_button)
	binding_percent_label = Label.new()
	binding_percent_label.name = "BindingProgress"
	binding_percent_label.visible = false
	Identity.apply_label(binding_percent_label, "wyrd")
	status_row.add_child(binding_percent_label)

	# RoN-style notification feed: recent notices stack on the left and fade.
	notice_feed = VBoxContainer.new()
	notice_feed.name = "NoticeFeed"
	notice_feed.set_anchors_preset(Control.PRESET_TOP_LEFT)
	notice_feed.offset_left = 10.0
	notice_feed.offset_top = TOP_BAR_HEIGHT + 48.0
	notice_feed.offset_right = 350.0
	notice_feed.offset_bottom = TOP_BAR_HEIGHT + 330.0
	notice_feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice_feed.add_theme_constant_override("separation", 4)
	root.add_child(notice_feed)

	# Look lift: no centre pop-ups during play. Critical notices (RAID, Town
	# Hall under attack) use this top-right banner; everything else goes to the
	# left feed. While a raid is on, the banner keeps a live count, direction
	# and ETA. (Node/var names kept: alert_panel / toast_title / toast_body.)
	alert_panel = PanelContainer.new()
	alert_panel.name = "RaidBanner"
	alert_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	alert_panel.offset_left = -RAID_BANNER_WIDTH - 8.0
	alert_panel.offset_top = TOP_BAR_HEIGHT + 4.0
	alert_panel.offset_right = -8.0
	alert_panel.offset_bottom = TOP_BAR_HEIGHT + 96.0
	alert_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	alert_panel.add_theme_stylebox_override("panel", HudSkin.frame("alert", 10.0))
	var alert_margin := MarginContainer.new()
	alert_margin.add_theme_constant_override("margin_left", 4)
	alert_margin.add_theme_constant_override("margin_right", 0)
	alert_margin.add_theme_constant_override("margin_top", 0)
	alert_margin.add_theme_constant_override("margin_bottom", 0)
	alert_panel.add_child(alert_margin)
	var alert_row := HBoxContainer.new()
	alert_row.add_theme_constant_override("separation", 10)
	alert_margin.add_child(alert_row)
	raid_banner_icon = HudSkin.icon_rect("swords", 40.0)
	raid_banner_icon.name = "ToastIcon"
	raid_banner_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	alert_row.add_child(raid_banner_icon)
	var toast_copy := VBoxContainer.new()
	toast_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toast_copy.add_theme_constant_override("separation", 0)
	alert_row.add_child(toast_copy)
	toast_title = HudSkin.title_label("", HudSkin.SIZE_TITLE, Color("#ffe2c8"))
	toast_title.name = "ToastTitle"
	toast_copy.add_child(toast_title)
	toast_body = Label.new()
	toast_body.name = "ToastBody"
	toast_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_body.max_lines_visible = 2
	HudSkin.set_font(toast_body, HudSkin.ui_font(400), HudSkin.SIZE_BODY - 1, Color("#f2dcd0"))
	toast_copy.add_child(toast_body)
	raid_eta_row = HBoxContainer.new()
	raid_eta_row.name = "RaidEtaRow"
	raid_eta_row.add_theme_constant_override("separation", 4)
	raid_eta_row.visible = false
	toast_copy.add_child(raid_eta_row)
	raid_eta_row.add_child(HudSkin.icon_rect("hourglass", 16.0))
	raid_eta_label = Label.new()
	raid_eta_label.name = "RaidEta"
	HudSkin.set_font(raid_eta_label, HudSkin.ui_font(700), HudSkin.SIZE_CAPTION, Color("#ffcf9a"))
	raid_eta_row.add_child(raid_eta_label)
	alert_label = toast_title
	var dismiss := Button.new()
	dismiss.name = "DismissBanner"
	dismiss.text = "×"
	dismiss.flat = true
	dismiss.focus_mode = Control.FOCUS_NONE
	dismiss.custom_minimum_size = Vector2(24, 24)
	dismiss.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	dismiss.tooltip_text = "Dismiss (the raid stays in the feed and the Log)"
	HudSkin.set_font(dismiss, HudSkin.ui_font(700), HudSkin.SIZE_TITLE, Color("#ffd3c0"))
	dismiss.pressed.connect(_dismiss_toast)
	alert_row.add_child(dismiss)
	alert_panel.visible = false

	event_log_panel = PanelContainer.new()
	event_log_panel.name = "EventLog"
	event_log_panel.visible = false
	event_log_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	event_log_panel.offset_left = -360.0
	event_log_panel.offset_top = TOP_BAR_HEIGHT + 44.0
	event_log_panel.offset_right = -8.0
	event_log_panel.offset_bottom = TOP_BAR_HEIGHT + 330.0
	event_log_panel.add_theme_stylebox_override("panel", HudSkin.frame("panel", 12.0))
	root.add_child(event_log_panel)
	var log_margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		log_margin.add_theme_constant_override(side, 10)
	event_log_panel.add_child(log_margin)
	event_log_body = RichTextLabel.new()
	event_log_body.bbcode_enabled = true
	event_log_body.scroll_active = true
	event_log_body.fit_content = false
	event_log_body.add_theme_font_size_override("normal_font_size", Identity.SIZE_BODY)
	event_log_body.add_theme_color_override("default_color", Identity.COLOR_NEUTRAL)
	log_margin.add_child(event_log_body)

	root.add_child(alert_panel)

	objective_detail_panel = PanelContainer.new()
	objective_detail_panel.name = "ObjectiveDetail"
	objective_detail_panel.visible = false
	objective_detail_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	objective_detail_panel.anchor_right = 0.0
	objective_detail_panel.anchor_bottom = 0.0
	objective_detail_panel.offset_left = 8.0
	objective_detail_panel.offset_top = TOP_BAR_HEIGHT + 44.0
	objective_detail_panel.offset_right = 300.0
	objective_detail_panel.offset_bottom = TOP_BAR_HEIGHT + 200.0
	objective_detail_panel.custom_minimum_size = Vector2(286, 156)
	objective_detail_panel.clip_contents = true
	objective_detail_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	objective_detail_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.04, 0.05, 0.055, 0.92), Color("#efcf8a")))
	root.add_child(objective_detail_panel)
	var objective_margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		objective_margin.add_theme_constant_override(side, 10)
	objective_detail_panel.add_child(objective_margin)
	var objective_box := VBoxContainer.new()
	objective_box.add_theme_constant_override("separation", 6)
	objective_margin.add_child(objective_box)
	var objective_header := HBoxContainer.new()
	objective_box.add_child(objective_header)
	var objective_title := Label.new()
	objective_title.text = "Goals"
	objective_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Identity.apply_label(objective_title, "caption")
	objective_header.add_child(objective_title)
	var close_goals := Button.new()
	close_goals.text = "×"
	close_goals.custom_minimum_size = Vector2(32, 28)
	close_goals.pressed.connect(_show_objective_detail.bind(false))
	Identity.apply_button(close_goals)
	objective_header.add_child(close_goals)
	var objective_scroll := ScrollContainer.new()
	objective_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	objective_scroll.custom_minimum_size = Vector2(0, 96)
	objective_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	objective_box.add_child(objective_scroll)
	objective_detail_body = Label.new()
	objective_detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_detail_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Identity.apply_label(objective_detail_body, "body")
	objective_scroll.add_child(objective_detail_body)

	shard_compass = Label.new()
	shard_compass.name = "ShardCompass"
	shard_compass.text = "▲  SHARD"
	shard_compass.visible = false
	shard_compass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Identity.apply_label(shard_compass, "wyrd")
	shard_compass.add_theme_font_size_override("font_size", 16)
	root.add_child(shard_compass)

	nightfall_panel = PanelContainer.new()
	nightfall_panel.name = "NightfallEvent"
	nightfall_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	nightfall_panel.offset_left = -210.0
	nightfall_panel.offset_top = TOP_BAR_HEIGHT + 120.0
	nightfall_panel.offset_right = 210.0
	nightfall_panel.offset_bottom = TOP_BAR_HEIGHT + 186.0
	nightfall_panel.add_theme_stylebox_override("panel", HudSkin.frame("toast", 10.0))
	root.add_child(nightfall_panel)
	var nightfall_margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		nightfall_margin.add_theme_constant_override(side, 10)
	nightfall_panel.add_child(nightfall_margin)
	nightfall_label = Label.new()
	nightfall_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nightfall_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Identity.apply_label(nightfall_label, "warning")
	nightfall_margin.add_child(nightfall_label)
	nightfall_panel.visible = false

	build_panel = PanelContainer.new()
	build_panel.name = "BuildPalette"
	# T-SNS-UI: the full plan list opens as a themed popup above the console.
	build_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	build_panel.offset_left = 8.0
	build_panel.offset_right = 300.0
	build_panel.offset_top = -CONSOLE_HEIGHT - 8.0 - 380.0
	build_panel.offset_bottom = -CONSOLE_HEIGHT - 8.0
	build_panel.add_theme_stylebox_override("panel", HudSkin.frame("panel", 4.0))
	root.add_child(build_panel)
	var build_margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		build_margin.add_theme_constant_override(side, 14)
	build_panel.add_child(build_margin)
	var build_box := VBoxContainer.new()
	build_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build_box.add_theme_constant_override("separation", 10)
	build_margin.add_child(build_box)
	var build_header := HBoxContainer.new()
	build_box.add_child(build_header)
	var build_title := Label.new()
	build_title.text = "Settlement Plans"
	build_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build_title.add_theme_color_override("font_color", HudSkin.COLOR_GOLD)
	build_title.add_theme_font_size_override("font_size", 20)
	build_header.add_child(build_title)
	var close_build := Button.new()
	close_build.name = "CloseBuildPalette"
	close_build.text = "×"
	close_build.custom_minimum_size = Vector2(36, 32)
	close_build.pressed.connect(_set_build_palette_visible.bind(false))
	build_header.add_child(close_build)
	build_category_select = OptionButton.new()
	build_category_select.name = "BuildCategory"
	build_category_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for category in BUILD_CATEGORIES:
		build_category_select.add_item(String(category).capitalize())
		build_category_select.set_item_metadata(build_category_select.item_count - 1, String(category))
	build_category_select.item_selected.connect(_set_build_category)
	build_box.add_child(build_category_select)
	var build_scroll := ScrollContainer.new()
	build_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	build_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	build_box.add_child(build_scroll)
	var section_host := VBoxContainer.new()
	section_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_host.add_theme_constant_override("separation", 8)
	build_scroll.add_child(section_host)
	for category in BUILD_CATEGORIES:
		var section := VBoxContainer.new()
		section.name = "%sPlans" % String(category).capitalize()
		section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		section.add_theme_constant_override("separation", 7)
		section_host.add_child(section)
		build_category_sections[category] = section
		for building_type in BUILD_CATEGORIES[category]:
			var button := Button.new()
			button.name = "Build_%s" % String(building_type)
			button.text = "%s  ·  %s\n%s" % [Defs.building_name(building_type), Defs.formatted_cost(building_type), String(BUILD_PURPOSES.get(building_type, "Settlement building."))]
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.clip_text = true
			button.custom_minimum_size.y = 48
			button.add_theme_font_size_override("font_size", 13)
			button.tooltip_text = _building_tooltip(String(building_type))
			button.pressed.connect(begin_placement.bind(building_type))
			section.add_child(button)
			build_buttons[building_type] = button
	var utility_row := HBoxContainer.new()
	utility_row.add_theme_constant_override("separation", 8)
	build_box.add_child(utility_row)
	debug_info_button = Button.new()
	debug_info_button.name = "CopyDebugInfo"
	debug_info_button.text = "COPY DEBUG INFO"
	debug_info_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	debug_info_button.pressed.connect(_copy_debug_info)
	utility_row.add_child(debug_info_button)
	debug_info_button.visible = false
	build_panel.visible = false
	_set_build_category(0)
	
	# T-SNS-UI: Rise-of-Nations-style bottom console. Build grid (left), framed
	# province map (centre) and the selection / realm panel (right) share one
	# themed frame, so macro and micro information sit in a single place.
	hud_console = PanelContainer.new()
	hud_console.name = "HudConsole"
	hud_console.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hud_console.offset_left = 0.0
	hud_console.offset_right = 0.0
	hud_console.offset_top = -CONSOLE_HEIGHT
	hud_console.offset_bottom = 0.0
	hud_console.add_theme_stylebox_override("panel", HudSkin.frame("console", 10.0))
	root.add_child(hud_console)
	var console_row := HBoxContainer.new()
	console_row.add_theme_constant_override("separation", 8)
	hud_console.add_child(console_row)

	build_strip = PanelContainer.new()
	build_strip.name = "BuildStrip"
	build_strip.add_theme_stylebox_override("panel", HudSkin.frame("slot", 6.0))
	console_row.add_child(build_strip)
	var strip_box := VBoxContainer.new()
	strip_box.add_theme_constant_override("separation", 3)
	build_strip.add_child(strip_box)
	var strip_header := HBoxContainer.new()
	strip_header.add_theme_constant_override("separation", 8)
	strip_box.add_child(strip_header)
	strip_header.add_child(HudSkin.title_label("Build", HudSkin.SIZE_BODY, HudSkin.COLOR_GOLD))
	var strip_hint := HudSkin.caption("Hover for cost  ·  R rotates", HudSkin.SIZE_MIN)
	strip_hint.add_theme_color_override("font_color", Color("#8f8a76"))
	strip_header.add_child(strip_hint)
	var strip_grid := GridContainer.new()
	strip_grid.name = "BuildGrid"
	strip_grid.columns = BUILD_GRID_COLUMNS
	strip_grid.add_theme_constant_override("h_separation", 4)
	strip_grid.add_theme_constant_override("v_separation", 4)
	strip_box.add_child(strip_grid)
	var slot_index := 0
	for building_type in BUILD_PALETTE:
		var btn_container := PanelContainer.new()
		btn_container.name = "Plan_%s" % String(building_type)
		btn_container.add_theme_stylebox_override("panel", HudSkin.frame("slot", 2.0))
		strip_grid.add_child(btn_container)

		# Make the entire slot (icon + text) a single clickable button.
		var btn := Button.new()
		btn.custom_minimum_size = BUILD_SLOT_SIZE
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var hover_box := StyleBoxFlat.new()
		hover_box.bg_color = Color(0.94, 0.78, 0.50, 0.16)
		hover_box.border_color = HudSkin.COLOR_GOLD
		hover_box.set_border_width_all(1)
		btn.add_theme_stylebox_override("hover", hover_box)
		var pressed_box := hover_box.duplicate() as StyleBoxFlat
		pressed_box.bg_color = Color(0.94, 0.78, 0.50, 0.28)
		btn.add_theme_stylebox_override("pressed", pressed_box)
		btn.pressed.connect(begin_placement.bind(building_type))
		var purpose := String(BUILD_PURPOSES.get(building_type, "Settlement building."))
		var cost := Defs.formatted_cost(building_type)
		var hotkey := String(BUILD_HOTKEY_LABELS[slot_index]) if slot_index < BUILD_HOTKEY_LABELS.size() else ""
		btn.tooltip_text = "%s   [%s]\n\n%s\nCost: %s" % [Defs.building_name(building_type), hotkey, purpose, cost]
		btn.mouse_entered.connect(_on_strip_button_hovered.bind(String(building_type)))
		btn_container.add_child(btn)

		var btn_vbox := VBoxContainer.new()
		# Look lift: Source Sans 3 lines are ~17 px at 11 px, so the stack overlaps by 1 px each.
		btn_vbox.add_theme_constant_override("separation", -1)
		btn_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn.add_child(btn_vbox)

		var icon_canvas := Control.new()
		icon_canvas.custom_minimum_size = Vector2(BUILD_SLOT_SIZE.x, 24)
		icon_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Look lift: rendered thumbnail (glyph fallback if a type has none). It is
		# taller than the 24 px row and sits behind the outlined name label.
		var icon_drawing: Control
		if HudSkin.thumbnail(String(building_type)) != null:
			icon_drawing = HudSkin.thumbnail_rect(String(building_type), Vector2(58, 34))
			icon_drawing.name = "Thumbnail"
			icon_drawing.set_anchors_preset(Control.PRESET_TOP_LEFT)
			icon_drawing.position = Vector2((BUILD_SLOT_SIZE.x - 58.0) * 0.5, -3)
		else:
			icon_drawing = _create_building_icon_visual(building_type)
			icon_drawing.set_anchors_preset(Control.PRESET_TOP_LEFT)
			icon_drawing.size = Vector2(72, 34)
			icon_drawing.scale = Vector2(0.8, 0.8)
			icon_drawing.position = Vector2((BUILD_SLOT_SIZE.x - 72.0 * 0.8) * 0.5, 0)
		icon_canvas.add_child(icon_drawing)
		btn_vbox.add_child(icon_canvas)

		var label := Label.new()
		label.text = String(STRIP_SHORT_NAMES.get(building_type, Defs.building_name(building_type)))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.clip_text = true
		HudSkin.set_font(label, HudSkin.ui_font(600), HudSkin.SIZE_MIN)
		label.add_theme_constant_override("outline_size", 3)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn_vbox.add_child(label)
		var cost_label := Label.new()
		cost_label.name = "Cost"
		cost_label.text = _compact_cost(String(building_type))
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_label.clip_text = true
		HudSkin.set_font(cost_label, HudSkin.ui_font(600), HudSkin.SIZE_MIN)
		cost_label.add_theme_color_override("font_color", Color("#e8dcb4"))
		cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn_vbox.add_child(cost_label)
		var key_badge := HudSkin.hotkey_badge(hotkey)
		key_badge.name = "Hotkey"
		key_badge.position = Vector2(3, 2)
		key_badge.visible = hotkey != ""
		btn.add_child(key_badge)

		build_strip_buttons.append(btn)
		build_strip_types.append(String(building_type))
		build_strip_containers.append(btn_container)
		build_strip_cost_labels.append(cost_label)
		build_strip_dim_nodes.append([icon_canvas, label])
		build_strip_tooltips.append(btn.tooltip_text)
		slot_index += 1

	# T-SNS-UI leftovers: RoN-style idle-worker button, floating just above the
	# console's right end (outside every container, so it cannot push layout).

	# Centre: framed province map. The holder keeps a fixed rect even while the
	# minimap itself is hidden (menu), so layout never collapses.
	var map_holder := Control.new()
	map_holder.name = "MinimapHolder"
	map_holder.custom_minimum_size = Vector2(MINIMAP_INNER + 12.0, MINIMAP_INNER + 28.0)
	map_holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	map_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	console_row.add_child(map_holder)
	minimap = MinimapScript.new()
	minimap.focus_requested.connect(_focus_from_minimap)
	map_holder.add_child(minimap)
	minimap.apply_console_layout(MINIMAP_INNER, HudSkin.frame("slot", 6.0))
	minimap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	minimap.visible = false

	# Right: selection panel (portrait + info + actions) or, with nothing
	# selected, a realm overview so macro state is always one glance away.
	selection_host = PanelContainer.new()
	selection_host.name = "SelectionPanel"
	selection_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selection_host.add_theme_stylebox_override("panel", HudSkin.frame("slot", 8.0))
	console_row.add_child(selection_host)
	realm_overview = RichTextLabel.new()
	realm_overview.name = "RealmOverview"
	realm_overview.bbcode_enabled = true
	realm_overview.scroll_active = false
	realm_overview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	realm_overview.add_theme_font_size_override("normal_font_size", 14)
	realm_overview.add_theme_font_size_override("bold_font_size", 14)
	selection_host.add_child(realm_overview)

	inspector_panel = PanelContainer.new()
	inspector_panel.name = "Inspector"
	inspector_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	selection_host.add_child(inspector_panel)
	var inspector_row := HBoxContainer.new()
	inspector_row.add_theme_constant_override("separation", 10)
	inspector_panel.add_child(inspector_row)
	var portrait_column := VBoxContainer.new()
	portrait_column.add_theme_constant_override("separation", 4)
	inspector_row.add_child(portrait_column)
	var portrait_frame := PanelContainer.new()
	portrait_frame.name = "Portrait"
	portrait_frame.custom_minimum_size = Vector2(104, 92)
	portrait_frame.add_theme_stylebox_override("panel", HudSkin.frame("panel", 4.0))
	portrait_column.add_child(portrait_frame)
	portrait_host = Control.new()
	portrait_host.clip_contents = true
	portrait_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_frame.add_child(portrait_host)
	portrait_hp_bar = ProgressBar.new()
	portrait_hp_bar.name = "PortraitHP"
	portrait_hp_bar.show_percentage = false
	portrait_hp_bar.max_value = 1.0
	portrait_hp_bar.custom_minimum_size = Vector2(104, 16)
	# Look lift: thick HP bar with the value written on it.
	portrait_hp_label = Label.new()
	portrait_hp_label.name = "PortraitHPValue"
	portrait_hp_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	HudSkin.set_font(portrait_hp_label, HudSkin.ui_font(700), HudSkin.SIZE_MIN, Color("#f6f2e4"))
	portrait_hp_label.add_theme_constant_override("outline_size", 3)
	portrait_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_hp_bar.add_child(portrait_hp_label)
	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.05, 0.04, 0.03, 0.95)
	hp_bg.border_color = Color("#5c5c54")
	hp_bg.set_border_width_all(1)
	portrait_hp_fill = StyleBoxFlat.new()
	portrait_hp_fill.bg_color = Color("#79c26a")
	portrait_hp_bar.add_theme_stylebox_override("background", hp_bg)
	portrait_hp_bar.add_theme_stylebox_override("fill", portrait_hp_fill)
	portrait_column.add_child(portrait_hp_bar)
	var inspector_box := VBoxContainer.new()
	inspector_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspector_box.add_theme_constant_override("separation", 4)
	inspector_row.add_child(inspector_box)
	inspector_label = RichTextLabel.new()
	inspector_label.bbcode_enabled = true
	inspector_label.fit_content = false
	inspector_label.scroll_active = true
	inspector_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inspector_label.add_theme_color_override("default_color", Color("#e2dfcf"))
	inspector_label.add_theme_font_size_override("normal_font_size", 14)
	inspector_box.add_child(inspector_label)
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 6)
	inspector_box.add_child(action_row)
	assault_button = Button.new()
	assault_button.name = "AssaultOutpost"
	assault_button.text = "ASSAULT OUTPOST"
	assault_button.tooltip_text = "Send free patrol soldiers. Tower sentries stay home. Soldiers must reach the Outpost and can be killed en route."
	Identity.apply_button(assault_button)
	assault_button.pressed.connect(_order_selected_outpost_assault)
	action_row.add_child(assault_button)
	assault_button.visible = false
	recall_button = Button.new()
	recall_button.name = "RecallAssault"
	recall_button.text = "RECALL SOLDIERS"
	Identity.apply_button(recall_button)
	recall_button.pressed.connect(func() -> void: _show_command_result(simulation_host.simulation.recall_assault_soldiers()))
	action_row.add_child(recall_button)
	recall_button.visible = false
	scout_button = Button.new()
	scout_button.name = "ScoutDirection"
	scout_button.text = "SCOUT (Y)"
	scout_button.tooltip_text = "Scout Direction: click into the fog. The soldier walks short legs, reveals as he goes, and returns on his own."
	Identity.apply_button(scout_button)
	scout_button.pressed.connect(_begin_scout_aim)
	action_row.add_child(scout_button)
	scout_button.visible = false
	inspector_panel.visible = false

	placement_panel = PanelContainer.new()
	placement_panel.name = "PlacementHint"
	placement_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	placement_panel.offset_left = -235.0
	placement_panel.offset_right = 235.0
	placement_panel.offset_top = -CONSOLE_HEIGHT - 70.0
	placement_panel.offset_bottom = -CONSOLE_HEIGHT - 8.0
	# Playtest.31 (T-SNS-009): long INVALID reasons wrap inside a fixed-width
	# panel that grows upward, so they never run under the console.
	placement_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	placement_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	placement_panel.add_theme_stylebox_override("panel", HudSkin.frame("toast", 10.0))
	root.add_child(placement_panel)
	var placement_vbox := VBoxContainer.new()
	placement_vbox.add_theme_constant_override("separation", 4)
	placement_panel.add_child(placement_vbox)
	placement_legend_label = Label.new()
	placement_legend_label.text = ""
	placement_legend_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	placement_legend_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placement_legend_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placement_legend_label.add_theme_color_override("font_color", Color("#b9c6a8"))
	placement_legend_label.add_theme_font_size_override("font_size", 12)
	placement_vbox.add_child(placement_legend_label)
	placement_label = Label.new()
	placement_label.text = ""
	placement_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	placement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placement_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placement_label.add_theme_color_override("font_color", Color("#f0e2b8"))
	placement_label.add_theme_font_size_override("font_size", 15)
	placement_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	placement_label.custom_minimum_size = Vector2(PLACEMENT_HINT_TEXT_WIDTH, 0)
	placement_vbox.add_child(placement_label)
	placement_panel.visible = false
	_create_start_menu(root)
	_create_result_overlay(root)
	_create_binding_confirm(root)


func _toggle_build_palette() -> void:
	_set_build_palette_visible(build_panel == null or not build_panel.visible)


func _set_build_palette_visible(value: bool) -> void:
	if build_panel == null:
		return
	build_panel.visible = value
	build_toggle_button.button_pressed = value
	if value:
		_show_objective_detail(false)
		if inspector_panel != null:
			inspector_panel.visible = false
	elif not value:
		_update_inspector()


func _set_build_category(index: int) -> void:
	if build_category_select != null and index >= 0 and index < build_category_select.item_count:
		current_build_category = String(build_category_select.get_item_metadata(index))
	for category in build_category_sections:
		(build_category_sections[category] as Control).visible = String(category) == current_build_category
	if build_panel != null:
		var card_count := Array(BUILD_CATEGORIES.get(current_build_category, [])).size()
		build_panel.size.y = minf(410.0, 145.0 + float(card_count) * 61.0)


func _create_placement_ghost() -> void:
	placement_ghost = Node3D.new()
	placement_ghost.name = "PlacementGhost"
	placement_ghost.visible = false
	add_child(placement_ghost)
	ghost_footprint = MeshInstance3D.new()
	ghost_footprint.name = "Footprint"
	placement_ghost.add_child(ghost_footprint)
	ghost_access = MeshInstance3D.new()
	ghost_access.name = "AccessDirection"
	var arrow_mesh := PrismMesh.new()
	arrow_mesh.size = Vector3(0.75, 0.18, 1.4)
	ghost_access.mesh = arrow_mesh
	ghost_access.position.y = 0.16
	placement_ghost.add_child(ghost_access)
	ghost_clearing_label = Label3D.new()
	ghost_clearing_label.name = "ClearingRequired"
	ghost_clearing_label.text = "CLEARING REQUIRED"
	ghost_clearing_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ghost_clearing_label.no_depth_test = true
	ghost_clearing_label.font_size = 48
	ghost_clearing_label.outline_size = 10
	ghost_clearing_label.modulate = Color("#ffd36a")
	ghost_clearing_label.position = Vector3(0.0, 2.6, 0.0)
	ghost_clearing_label.visible = false
	placement_ghost.add_child(ghost_clearing_label)


func _refresh_build_pads() -> void:
	if world_view == null or simulation_host.simulation == null:
		return
	if placement_type == "" or placement_type in [Defs.BUILDING_ROAD, Defs.TOOL_CLEAR_AREA]:
		world_view.clear_build_pads()
		return
	var pads: Dictionary = simulation_host.simulation.collect_build_pads(placement_type, placement_rotation, 40)
	world_view.show_build_pads(pads.get("valid", []), pads.get("clearing", []))


func _update_placement_ghost(force := false) -> void:
	if placement_type == "" or camera_rig.camera == null:
		return
	if placement_preview_locked or road_dragging or wall_dragging:
		return
	var pointer := evidence_mouse_override if evidence_mouse_override.x >= 0.0 else get_viewport().get_mouse_position()
	var hit := _raycast_terrain(pointer)
	if hit.is_empty():
		placement_ghost.visible = false
		return
	var next_tile := world_view.world_to_tile(hit.position)
	if not simulation_host.simulation.is_inside_map(next_tile):
		placement_ghost.visible = false
		return
	if not force and next_tile == placement_tile:
		return
	placement_tile = next_tile
	if placement_type == Defs.BUILDING_ROAD:
		placement_validation = simulation_host.simulation.validate_road_route([placement_tile])
		world_view.show_road_preview(placement_validation.get("segments", []))
		placement_ghost.visible = false
		if ghost_clearing_label != null:
			ghost_clearing_label.visible = false
		world_view.clear_build_pads()
		placement_label.text = "%s · drag from the road network" % String(placement_validation.get("message", "Road Building Mode"))
		return
	if placement_type == Defs.TOOL_CLEAR_AREA:
		var clearable: bool = String(simulation_host.simulation.get_tile(placement_tile)) == Defs.TILE_TREE
		placement_validation = {"success": clearable, "message": "CLEAR trees in this area." if clearable else "Select harvestable trees."}
		var clear_box := BoxMesh.new()
		clear_box.size = Vector3(ScaleProfile.LOGICAL_CELL_METRES, 0.14, ScaleProfile.LOGICAL_CELL_METRES)
		ghost_footprint.mesh = clear_box
		var clear_color := Color(0.92, 0.72, 0.28, 0.45) if clearable else Color(0.92, 0.25, 0.22, 0.46)
		ghost_footprint.material_override = _ghost_material(clear_color)
		ghost_access.material_override = _ghost_material(clear_color.lightened(0.18))
		placement_ghost.position = world_view.tile_to_world(Vector2(placement_tile)) + Vector3.UP * 0.08
		placement_ghost.visible = true
		if ghost_clearing_label != null:
			ghost_clearing_label.visible = false
		placement_label.text = String(placement_validation.get("message", "CLEAR"))
		return
	placement_validation = simulation_host.simulation.validate_placement(placement_type, placement_tile, placement_rotation)
	var footprint := Defs.building_footprint(placement_type)
	if posmod(placement_rotation, 2) == 1:
		footprint = Vector2i(footprint.y, footprint.x)
	var valid := bool(placement_validation.get("success", false))
	var needs_clearing := valid and "CLEARING REQUIRED" in String(placement_validation.get("message", ""))
	var ghost_height := 0.58 if needs_clearing else 0.14
	var box := BoxMesh.new()
	box.size = Vector3(float(footprint.x) * ScaleProfile.LOGICAL_CELL_METRES, ghost_height, float(footprint.y) * ScaleProfile.LOGICAL_CELL_METRES)
	ghost_footprint.mesh = box
	var ghost_color := Color(0.95, 0.68, 0.18, 0.52) if needs_clearing else (Color(0.26, 0.86, 0.48, 0.42) if valid else Color(0.92, 0.25, 0.22, 0.46))
	ghost_footprint.material_override = _ghost_material(ghost_color)
	ghost_access.material_override = _ghost_material(ghost_color.lightened(0.18))
	var center := Vector2(placement_tile) + Vector2(footprint - Vector2i.ONE) * 0.5
	placement_ghost.position = world_view.tile_to_world(center) + Vector3.UP * (0.08 + ghost_height * 0.5)
	placement_ghost.rotation.y = -float(placement_rotation) * PI * 0.5
	ghost_access.position.z = float(footprint.y) * ScaleProfile.LOGICAL_CELL_METRES * 0.5 + 0.72
	placement_ghost.visible = true
	if ghost_clearing_label != null:
		ghost_clearing_label.visible = needs_clearing
		ghost_clearing_label.position.y = ghost_height + 2.15
	var quality: Dictionary = placement_validation.get("placement_quality", {})
	if quality.is_empty() and simulation_host.simulation.has_method("evaluate_placement_quality"):
		quality = simulation_host.simulation.evaluate_placement_quality(placement_type, placement_tile, placement_rotation)
	var quality_text := String(quality.get("label", ""))
	var prefix := "CLEARING REQUIRED" if needs_clearing else ("VALID" if valid else "INVALID")
	if quality_text != "":
		placement_label.text = "%s · %s" % [prefix, quality_text]
	else:
		placement_label.text = "%s · %s" % [prefix, String(placement_validation.get("message", ""))]


func _commit_placement() -> void:
	if placement_type == "" or placement_tile.x < 0:
		return
	var result: Dictionary = simulation_host.simulation.request_build(placement_type, placement_tile, placement_rotation)
	_show_status(String(result.get("message", "")), 3.0)
	if bool(result.get("success", false)):
		_sync_presentation()
		if placement_type == Defs.BUILDING_ROAD:
			placement_tile = Vector2i(-1, -1)
			_update_placement_ghost(true)
		else:
			cancel_placement()
			_set_build_palette_visible(false)
	else:
		placement_validation = result
		_update_placement_ghost(true)


func _start_road_drag(screen_position: Vector2) -> void:
	var hit := _raycast_terrain(screen_position)
	if hit.is_empty():
		return
	road_drag_start = world_view.world_to_tile(hit.position)
	road_dragging = true
	road_preview_route = [road_drag_start]
	_update_road_drag_preview(screen_position)


func _update_road_drag_preview(screen_position: Vector2) -> void:
	if not road_dragging:
		return
	var hit := _raycast_terrain(screen_position)
	if hit.is_empty():
		return
	var endpoint := world_view.world_to_tile(hit.position)
	road_preview_route = _choose_road_route(road_drag_start, endpoint)
	road_preview_validation = simulation_host.simulation.validate_road_route(road_preview_route)
	world_view.show_road_preview(road_preview_validation.get("segments", []))
	var prefix := "ROAD MODE"
	placement_label.text = "%s · %s" % [prefix, String(road_preview_validation.get("message", "Route unavailable"))]


func _finish_road_drag(screen_position: Vector2) -> void:
	_update_road_drag_preview(screen_position)
	var result := road_preview_validation
	road_dragging = false
	var planned := 0
	if bool(result.get("success", false)):
		for segment_value in result.get("segments", []):
			var segment: Dictionary = segment_value
			if bool(segment.get("reuse", false)):
				continue
			var build_result: Dictionary = simulation_host.simulation.request_build(Defs.BUILDING_ROAD, Vector2i(segment.get("tile", Vector2i.ZERO)), 0)
			if not bool(build_result.get("success", false)):
				result = build_result
				break
			planned += 1
	if planned > 0:
		_show_status("Planned %d connected road sections." % planned, 3.0)
		_sync_presentation()
	elif not bool(result.get("success", false)):
		_show_status(String(result.get("message", "Road route is blocked.")), 3.0)
	road_preview_route.clear()
	road_preview_validation.clear()
	road_drag_start = Vector2i(-1, -1)
	world_view.clear_road_preview()
	placement_tile = Vector2i(-1, -1)
	_update_placement_ghost(true)


func _cancel_road_drag() -> void:
	road_dragging = false
	road_drag_start = Vector2i(-1, -1)
	road_preview_route.clear()
	road_preview_validation.clear()
	if world_view != null:
		world_view.clear_road_preview()


func _start_wall_drag(screen_position: Vector2) -> void:
	var hit := _raycast_terrain(screen_position)
	if hit.is_empty():
		return
	wall_drag_start = world_view.world_to_tile(hit.position)
	wall_dragging = true
	wall_preview_route = [wall_drag_start]
	_update_wall_drag_preview(screen_position)


func _update_wall_drag_preview(screen_position: Vector2) -> void:
	if not wall_dragging:
		return
	var hit := _raycast_terrain(screen_position)
	if hit.is_empty():
		return
	var endpoint := world_view.world_to_tile(hit.position)
	var horizontal := _axis_road_route(wall_drag_start, endpoint, true)
	var vertical := _axis_road_route(wall_drag_start, endpoint, false)
	wall_preview_route = horizontal if _wall_route_score(horizontal) >= _wall_route_score(vertical) else vertical
	var segments := _wall_preview_segments(wall_preview_route)
	world_view.show_road_preview(segments)
	var valid_count := 0
	for segment_value in segments:
		if bool(Dictionary(segment_value).get("valid", false)):
			valid_count += 1
	placement_label.text = "WALL MODE · hold and drag  ·  %d sections" % valid_count


func _finish_wall_drag(screen_position: Vector2) -> void:
	_update_wall_drag_preview(screen_position)
	var planned := 0
	var last_message := ""
	for tile in wall_preview_route:
		var result: Dictionary = simulation_host.simulation.request_build(Defs.BUILDING_WALL, tile, 0)
		last_message = String(result.get("message", ""))
		if bool(result.get("success", false)):
			planned += 1
		else:
			break
	wall_dragging = false
	if planned > 0:
		_show_status("Planned %d wall sections." % planned, 3.0)
		_sync_presentation()
	elif last_message != "":
		_show_status(last_message, 3.0)
	_cancel_wall_drag()
	placement_tile = Vector2i(-1, -1)
	_update_placement_ghost(true)


func _cancel_wall_drag() -> void:
	wall_dragging = false
	wall_drag_start = Vector2i(-1, -1)
	wall_preview_route.clear()
	if world_view != null:
		world_view.clear_road_preview()


func _wall_preview_segments(route: Array[Vector2i]) -> Array:
	var segments: Array = []
	var virtual: Dictionary = {}
	for tile in route:
		var valid := _wall_drag_tile_valid(tile, virtual)
		segments.append({"tile": tile, "valid": valid, "reuse": false})
		if valid:
			virtual[simulation_host.simulation._tile_key(tile)] = true
	return segments


func _wall_drag_tile_valid(tile: Vector2i, virtual: Dictionary) -> bool:
	var simulation = simulation_host.simulation
	var result: Dictionary = simulation.validate_placement(Defs.BUILDING_WALL, tile)
	if bool(result.get("success", false)):
		return true
	if not simulation.is_inside_map(tile) or not simulation.is_revealed(tile):
		return false
	if not simulation.get_building_at_tile(tile).is_empty():
		return false
	if not simulation._tile_allows_clear_and_build(tile, Defs.BUILDING_WALL):
		return false
	for neighbor in simulation._neighbors(tile):
		if virtual.has(simulation._tile_key(neighbor)):
			return true
	return false


func _wall_route_score(route: Array[Vector2i]) -> int:
	var score := 0
	var virtual: Dictionary = {}
	for tile in route:
		if _wall_drag_tile_valid(tile, virtual):
			score += 10
			virtual[simulation_host.simulation._tile_key(tile)] = true
	return score


func _choose_road_route(start: Vector2i, endpoint: Vector2i) -> Array[Vector2i]:
	var routed := _find_preview_road_route(start, endpoint)
	if not routed.is_empty() and bool(simulation_host.simulation.validate_road_route(routed).get("success", false)):
		return routed
	var horizontal_first := _axis_road_route(start, endpoint, true)
	var vertical_first := _axis_road_route(start, endpoint, false)
	var horizontal_score := _road_route_score(horizontal_first)
	var vertical_score := _road_route_score(vertical_first)
	if horizontal_score == vertical_score:
		return horizontal_first if absi(endpoint.x - start.x) >= absi(endpoint.y - start.y) else vertical_first
	return horizontal_first if horizontal_score > vertical_score else vertical_first


func _find_preview_road_route(start: Vector2i, endpoint: Vector2i) -> Array[Vector2i]:
	var simulation = simulation_host.simulation
	if simulation == null or not simulation.is_inside_map(start) or not simulation.is_inside_map(endpoint):
		return []
	var frontier: Array[Vector2i] = [start]
	var came_from: Dictionary = {}
	var costs: Dictionary = {simulation._tile_key(start): 0.0}
	var scores: Dictionary = {simulation._tile_key(start): float(abs(start.x - endpoint.x) + abs(start.y - endpoint.y))}
	while not frontier.is_empty():
		frontier.sort_custom(func(first: Vector2i, second: Vector2i) -> bool:
			var first_key: String = simulation._tile_key(first)
			var second_key: String = simulation._tile_key(second)
			var first_score: float = float(scores.get(first_key, INF))
			var second_score: float = float(scores.get(second_key, INF))
			return first_key < second_key if is_equal_approx(first_score, second_score) else first_score < second_score
		)
		var current: Vector2i = frontier.pop_front()
		if current == endpoint:
			var route: Array[Vector2i] = [current]
			while current != start:
				current = Vector2i(came_from[simulation._tile_key(current)])
				route.push_front(current)
			return route
		for direction in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
			var neighbor: Vector2i = current + direction
			if not _preview_road_tile_passable(neighbor, start):
				continue
			if abs(simulation.get_height(current) - simulation.get_height(neighbor)) > 2:
				continue
			var existing: Dictionary = simulation.get_building_at_tile(neighbor)
			var reuses_road: bool = not existing.is_empty() and String(existing.get("type", "")) == Defs.BUILDING_ROAD
			var next_cost: float = float(costs[simulation._tile_key(current)]) + (0.22 if reuses_road else 1.0)
			var neighbor_key: String = simulation._tile_key(neighbor)
			if next_cost >= float(costs.get(neighbor_key, INF)):
				continue
			came_from[neighbor_key] = current
			costs[neighbor_key] = next_cost
			scores[neighbor_key] = next_cost + float(abs(neighbor.x - endpoint.x) + abs(neighbor.y - endpoint.y))
			if not frontier.has(neighbor):
				frontier.append(neighbor)
	return []


func _preview_road_tile_passable(tile: Vector2i, _start: Vector2i) -> bool:
	var simulation = simulation_host.simulation
	if not simulation.is_inside_map(tile) or not simulation.is_revealed(tile):
		return false
	var existing: Dictionary = simulation.get_building_at_tile(tile)
	if not existing.is_empty():
		return String(existing.get("type", "")) == Defs.BUILDING_ROAD
	if String(simulation.get_tile(tile)) != Defs.TILE_GRASS or simulation._enemy_camp_at_tile(tile):
		return false
	return simulation.rivalry == null or not simulation.rivalry.is_rivalry_occupied(tile)


func _axis_road_route(start: Vector2i, endpoint: Vector2i, horizontal_first: bool) -> Array[Vector2i]:
	var route: Array[Vector2i] = [start]
	var cursor := start
	var axes := [Vector2i(1, 0), Vector2i(0, 1)] if horizontal_first else [Vector2i(0, 1), Vector2i(1, 0)]
	for axis in axes:
		var target_value := endpoint.x if axis.x != 0 else endpoint.y
		while (cursor.x if axis.x != 0 else cursor.y) != target_value:
			var current_value := cursor.x if axis.x != 0 else cursor.y
			cursor += axis * (1 if target_value > current_value else -1)
			route.append(cursor)
	return route


func _road_route_score(route: Array[Vector2i]) -> int:
	var validation: Dictionary = simulation_host.simulation.validate_road_route(route)
	var score := 100000 if bool(validation.get("success", false)) else 0
	for segment_value in validation.get("segments", []):
		var segment: Dictionary = segment_value
		if bool(segment.get("valid", false)):
			score += 100
		if bool(segment.get("reuse", false)):
			score += 8
	return score


func _select_from_pointer(screen_position: Vector2) -> void:
	var character_pick := _screen_space_character_pick(screen_position)
	if not character_pick.is_empty():
		var picked_kind := String(character_pick.get("kind", "worker"))
		var picked_id := int(character_pick.get("id", 0))
		if picked_kind == "worker":
			select_worker(picked_id)
		else:
			select_semantic_entity(picked_kind, picked_id, false)
		return
	var hit: Dictionary = _raycast_selection(screen_position)
	if not hit.is_empty():
		var collider: Object = hit.get("collider")
		if collider != null and collider.has_meta("selection_kind"):
			var kind := String(collider.get_meta("selection_kind"))
			var id := int(collider.get_meta("entity_id", 0))
			if kind == "building":
				select_building(id)
				return
			if kind == "worker":
				select_worker(id)
				return
			if kind in ["enemy", "rival_worker"]:
				select_semantic_entity(kind, id, false)
				return
			if kind == "rivalry_structure":
				select_semantic_entity(kind, id, true)
				return
	var terrain_hit: Dictionary = _raycast_terrain(screen_position)
	if not terrain_hit.is_empty():
		var tile := world_view.world_to_tile(terrain_hit.position)
		var building: Dictionary = simulation_host.simulation.get_building_at_tile(tile)
		if not building.is_empty():
			select_building(int(building.get("id", 0)))
			return
	selected_building_id = 0
	selected_worker_id = 0
	selected_entity_kind = ""
	world_view.set_selection(0, 0)
	world_view.set_watchtower_overlay(Vector2.ZERO, 0.0, false)
	_update_inspector()


func _screen_space_character_pick(screen_position: Vector2) -> Dictionary:
	if camera_rig.camera == null:
		return {}
	var best := {}
	var best_score := INF
	var collections := [
		{"items": current_frame_snapshot.get("combatants", []), "default_kind": "enemy"},
		{"items": current_frame_snapshot.get("workers", []), "default_kind": "worker"},
	]
	for collection_value in collections:
		var collection: Dictionary = collection_value
		for snapshot_value in collection.get("items", []):
			var snapshot: Dictionary = snapshot_value
			if not bool(snapshot.get("visible", true)):
				continue
			var logical := Vector2(snapshot.get("logical_position", Vector2.ZERO)) + Vector2(snapshot.get("presentation_offset", Vector2.ZERO))
			var world_position := world_view.tile_to_world(logical) + Vector3.UP * 1.15
			if camera_rig.camera.is_position_behind(world_position):
				continue
			var projected := camera_rig.camera.unproject_position(world_position)
			var distance := projected.distance_to(screen_position)
			var kind := String(snapshot.get("selection_kind", collection.get("default_kind", "worker")))
			var radius := 27.0
			if distance > radius:
				continue
			var score := distance
			if score < best_score:
				best_score = score
				best = {"kind": kind, "id": int(snapshot.get("id", 0))}
	return best


func select_semantic_entity(kind: String, id: int, building_like: bool) -> void:
	selected_entity_kind = kind
	if building_like:
		selected_building_id = id
		selected_worker_id = 0
	else:
		selected_worker_id = id
		selected_building_id = 0
	world_view.set_selection(selected_building_id, selected_worker_id)
	world_view.set_watchtower_overlay(Vector2.ZERO, 0.0, false)
	_update_inspector()


func _raycast_terrain(screen_position: Vector2) -> Dictionary:
	return _raycast(screen_position, 1, false)


func _raycast_selection(screen_position: Vector2) -> Dictionary:
	return _raycast(screen_position, 2, true)


func _raycast(screen_position: Vector2, collision_mask: int, areas: bool) -> Dictionary:
	if camera_rig.camera == null:
		return {}
	var origin := camera_rig.camera.project_ray_origin(screen_position)
	var end := origin + camera_rig.camera.project_ray_normal(screen_position) * 500.0
	var query := PhysicsRayQueryParameters3D.create(origin, end, collision_mask)
	query.collide_with_areas = areas
	query.collide_with_bodies = not areas
	return get_world_3d().direct_space_state.intersect_ray(query)


func _update_ui() -> void:
	if simulation_host.simulation == null:
		return
	var resources: Dictionary = simulation_host.simulation.get_resources()
	var settlement: Dictionary = current_frame_snapshot.get("settlement", {})
	var chip_values := {
		"wood": int(resources.get(Defs.RESOURCE_WOOD, 0)),
		"planks": int(resources.get(Defs.RESOURCE_PLANKS, 0)),
		"stone": int(resources.get(Defs.RESOURCE_STONE, 0)),
		"wheat": int(resources.get(Defs.RESOURCE_WHEAT, 0)),
		"bread": int(resources.get(Defs.RESOURCE_BREAD, 0)),
		"wyrd": int(resources.get(Defs.RESOURCE_WYRD, 0))
	}
	for key in chip_values:
		if resource_chips.has(key):
			(resource_chips[key] as Label).text = str(chip_values[key])
	_update_resource_rates(chip_values)
	if population_label != null:
		population_label.text = "%d/%d" % [int(resources.get(Defs.RESOURCE_POPULATION_USED, 0)), int(resources.get(Defs.RESOURCE_POPULATION_MAX, 0))]
	if soldier_label != null:
		soldier_label.text = "%d/%d" % [int(simulation_host.simulation.soldiers_available()), int(simulation_host.simulation.soldiers_total)]
	_update_idle_workers()
	var night_now := bool(simulation_host.simulation.is_night)
	if time_label != null:
		time_label.text = _clock_title()
	if phase_label != null:
		phase_label.text = _phase_countdown_text()
	_sync_speed_controls()
	if day_icon != null:
		day_icon.texture = HudSkin.icon("moon" if night_now else "sun")
	if phase_bar != null:
		var phase_length := float(simulation_host.simulation.NIGHT_LENGTH_SECONDS if night_now else simulation_host.simulation.DAY_LENGTH_SECONDS)
		phase_bar.value = clampf(float(simulation_host.simulation.phase_time) / maxf(phase_length, 1.0), 0.0, 1.0)
		(phase_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color("#7f9fd6") if night_now else HudSkin.COLOR_GOLD_DIM
	if resource_label != null:
		resource_label.text = ""
	if Time.get_ticks_msec() / 1000.0 >= status_message_until:
		status_label.text = ""
		status_message_text = ""
	_ingest_simulation_notices()
	_update_raid_banner()
	_update_loop_hud()
	for building_type in build_buttons:
		var button: Button = build_buttons[building_type]
		var reason := _build_unavailable_reason(String(building_type))
		button.disabled = reason != ""
		var recommend := _should_recommend_frontier(String(building_type))
		var label := "%s  ·  %s\n%s" % [Defs.building_name(String(building_type)), Defs.formatted_cost(String(building_type)), String(BUILD_PURPOSES.get(building_type, "Settlement building."))]
		if recommend:
			label = "FRONTIER  ·  " + label
		button.text = label
		button.tooltip_text = _building_tooltip(String(building_type)) + ("\n\nUnavailable: %s" % reason if reason != "" else "")
	_refresh_build_strip_state()
	_refresh_resource_chip_flash()
	_update_inspector()


## Playtest.31 UI: affordability on the C&C strip (cost on button, dimmed when
## unaffordable) and building tooltips suppressed while the placement hint is up
## so only one panel is visible at a time.
func _refresh_build_strip_state() -> void:
	var placing := placement_type != ""
	for index in build_strip_buttons.size():
		var building_type: String = build_strip_types[index] if index < build_strip_types.size() else ""
		var btn: Button = build_strip_buttons[index]
		var affordable := building_type == Defs.TOOL_CLEAR_AREA or _missing_resources(building_type).is_empty()
		# Dim the button background, icon and name, but never the cost label:
		# the red cost is the one thing the player needs to read here.
		if index < build_strip_containers.size():
			(build_strip_containers[index] as Control).self_modulate = Color(1, 1, 1, 1) if affordable else Color(0.42, 0.42, 0.42, 1.0)
		if index < build_strip_dim_nodes.size():
			for node in build_strip_dim_nodes[index]:
				(node as CanvasItem).modulate = Color(1, 1, 1, 1) if affordable else Color(0.6, 0.6, 0.6, 0.55)
		if index < build_strip_cost_labels.size():
			var cost_label := build_strip_cost_labels[index] as Label
			cost_label.add_theme_color_override("font_color", Color("#e8dcb4") if affordable else COLOR_UNAFFORDABLE_COST)
			cost_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.0) if affordable else Color("#140806"))
			cost_label.add_theme_constant_override("outline_size", 0 if affordable else 4)
		var base_tip: String = build_strip_tooltips[index] if index < build_strip_tooltips.size() else btn.tooltip_text
		btn.tooltip_text = "" if placing else (base_tip if affordable else base_tip + "\n\nCannot afford yet.")


func _missing_resources(building_type: String) -> Array:
	var missing: Array = []
	if simulation_host == null or simulation_host.simulation == null or building_type == Defs.TOOL_CLEAR_AREA:
		return missing
	var resources: Dictionary = simulation_host.simulation.get_resources()
	var cost: Dictionary = Defs.building_cost(building_type)
	for resource_type in cost:
		var needed := int(cost[resource_type])
		var available := int(resources.get(resource_type, 0))
		if available < needed:
			missing.append({"resource": String(resource_type), "have": available, "need": needed})
	return missing


func _compact_cost(building_type: String) -> String:
	if building_type == Defs.TOOL_CLEAR_AREA:
		return "Free"
	var cost: Dictionary = Defs.building_cost(building_type)
	if cost.is_empty():
		return "Free"
	var parts: Array[String] = []
	for resource_type in Defs.RESOURCE_TYPES:
		if cost.has(resource_type):
			parts.append("%d%s" % [int(cost[resource_type]), Defs.resource_name(resource_type).substr(0, 2)])
	return " ".join(parts)


func _on_strip_button_hovered(building_type: String) -> void:
	for entry_value in _missing_resources(building_type):
		_flash_resource_chip(String(Dictionary(entry_value)["resource"]), 1.4)
	_refresh_resource_chip_flash()


func _flash_resource_chip(resource_type: String, seconds: float) -> void:
	var key := String(CHIP_KEYS_BY_RESOURCE.get(resource_type, ""))
	if key == "":
		return
	resource_chip_flash_until[key] = maxf(float(resource_chip_flash_until.get(key, 0.0)), Time.get_ticks_msec() / 1000.0 + seconds)


func _refresh_resource_chip_flash() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	for key in resource_chips:
		var value_label: Label = resource_chips[key]
		var flashing := now < float(resource_chip_flash_until.get(key, 0.0))
		if flashing:
			if not resource_chip_base_colors.has(key):
				resource_chip_base_colors[key] = value_label.get_theme_color("font_color")
			var blink := int(now * 4.0) % 2 == 0
			value_label.add_theme_color_override("font_color", COLOR_UNAFFORDABLE if blink else Color("#ffd2c8"))
		elif resource_chip_flash_until.has(key):
			if resource_chip_base_colors.has(key):
				value_label.add_theme_color_override("font_color", Color(resource_chip_base_colors[key]))
				resource_chip_base_colors.erase(key)
			resource_chip_flash_until.erase(key)


func _update_loop_hud() -> void:
	if simulation_host.simulation == null:
		return
	var wyrdfall: Dictionary = current_frame_snapshot.get("wyrdfall", {})
	if wyrdfall.is_empty() and simulation_host.simulation.has_method("get_wyrdfall_presentation"):
		wyrdfall = simulation_host.simulation.get_wyrdfall_presentation()
	var objective: Dictionary = wyrdfall.get("objective", {})
	var binding_active := bool(wyrdfall.get("binding_active", false))
	var steps: Array = objective.get("steps", [])
	if objective_button != null:
		var intention: Dictionary = simulation_host.simulation.get_current_intention()
		var sim_objectives: Array = simulation_host.simulation.get_objectives()
		var active_sim_obj := ""
		for obj in sim_objectives:
			if not bool(obj.get("complete", false)):
				active_sim_obj = String(obj.get("text", ""))
				break
		if binding_active:
			objective_button.text = "HOLD THE BINDING"
		elif not intention.is_empty():
			var next_step := String(intention.get("title", ""))
			for row in intention.get("criteria", []):
				if not bool(row.get("done", false)):
					next_step = "%s — %s" % [String(intention.get("title", "")), String(row.get("label", ""))]
					break
			objective_button.text = next_step
		elif active_sim_obj != "":
			objective_button.text = active_sim_obj
		elif not steps.is_empty():
			objective_button.text = String(steps[0])
		else:
			objective_button.text = String(objective.get("title", "FEED THE SETTLEMENT"))
		var tip_title := String(intention.get("title", objective.get("title", "")))
		var tip_detail := String(intention.get("detail", objective.get("detail", "Click for the next step.")))
		objective_button.tooltip_text = "%s — %s" % [tip_title, tip_detail]
	var objective_id := String(objective.get("id", ""))
	# Issue #1 fix: Do NOT snap camera to shard location automatically
	# if objective_id == "reach" and not reach_guidance_shown and play_has_begun:
	#	reach_guidance_shown = true
	#	_glance_at_shard()
	last_objective_id = objective_id
	var pressure: Dictionary = wyrdfall.get("pressure", {})
	var hostiles := 0
	if simulation_host.simulation.has_method("living_hostile_count"):
		hostiles = int(simulation_host.simulation.living_hostile_count())
	if pressure_meter != null and pressure_meter.has_method("set_pressure"):
		pressure_meter.set_pressure(pressure)
		if pressure_meter.has_method("set_threat"):
			pressure_meter.set_threat(bool(simulation_host.simulation.is_night), hostiles)
		pressure_meter.visible = _pressure_chip_should_show(pressure_meter.band, bool(simulation_host.simulation.is_night), hostiles)
		pressure_meter.tooltip_text = String(wyrdfall.get("pressure_tooltip", "Wyrd Pressure"))
		# Q6: while the chip is hidden the QUIET state lives in the clock tooltip.
		if day_icon != null and day_icon.get_parent() != null and day_icon.get_parent().get_parent() is Control:
			(day_icon.get_parent().get_parent() as Control).tooltip_text = "Day and time until the next phase" + ("" if pressure_meter.visible else "\nWyrd Pressure: %s" % String(pressure_meter.band).capitalize())
	if pressure_label != null:
		pressure_label.text = String(pressure.get("band", "QUIET"))
	if binding_percent_label != null:
		binding_percent_label.visible = binding_active
		binding_percent_label.text = "%d%%" % int(wyrdfall.get("binding_percent", 0))
	if loop_label != null:
		var parts: Array[String] = []
		if binding_active:
			parts.append("Reckoning")
		elif simulation_host.simulation.is_night:
			parts.append("RAID · %d hostiles" % hostiles if hostiles > 0 else "NIGHT · no hostiles in sight")
		else:
			var remaining: float = float(simulation_host.simulation.DAY_LENGTH_SECONDS) - float(simulation_host.simulation.phase_time)
			if remaining <= 90.0:
				_maybe_show_nightfall(wyrdfall)
				var threat := String(Dictionary(wyrdfall.get("forecast", {})).get("threat", "QUIET"))
				parts.append("Night in %d:%02d · %s" % [int(remaining / 60.0), int(remaining) % 60, threat])
		var rival_line := String(wyrdfall.get("rival_line", ""))
		if rival_line != "":
			parts.append(rival_line)
		loop_label.text = "  ·  ".join(parts)
		if status_plate != null:
			status_plate.visible = (loop_label.text != "" or (bind_button != null and bind_button.visible) or binding_active) and not (alert_panel != null and alert_panel.visible)
			var raid_now := bool(simulation_host.simulation.is_night) and hostiles > 0
			loop_label.add_theme_color_override("font_color", Color("#ff9d8f") if raid_now else (Color("#b9c8ff") if simulation_host.simulation.is_night else Color("#e6dcc0")))
	if bind_button != null:
		bind_button.visible = bool(wyrdfall.get("binding_ready", false)) and not simulation_host.simulation.game_finished and not binding_active
	if nightfall_panel != null:
		nightfall_panel.visible = Time.get_ticks_msec() / 1000.0 < nightfall_event_until and (startup_overlay == null or not startup_overlay.visible)
	var dawn: Dictionary = wyrdfall.get("dawn_summary", {})
	if not dawn.is_empty():
		_show_status("DAWN\nNight survived  ·  %d threats defeated  ·  %d lost  ·  %d damaged" % [
			int(dawn.get("enemies_defeated", 0)),
			int(dawn.get("settlers_lost", 0)),
			int(dawn.get("buildings_damaged", 0))
		], 6.0)
		simulation_host.simulation.consume_dawn_summary()
	var hint: Dictionary = wyrdfall.get("onboarding", {})
	if not hint.is_empty() and status_message_text == "":
		_show_status(String(hint.get("text", "")), 8.0)
		if simulation_host.simulation.has_method("consume_onboarding_hint"):
			simulation_host.simulation.consume_onboarding_hint()


## T-SNS-UI: the console selection panel. The core fills inspector_label as
## before; this wrapper adds the portrait + HP bar, lays the stats out in two
## columns and shows the realm overview when nothing is selected.
func _update_inspector() -> void:
	if inspector_label == null or inspector_panel == null or simulation_host.simulation == null:
		return
	_update_inspector_core()
	if inspector_panel.visible:
		_decorate_inspector()
	if realm_overview != null:
		realm_overview.visible = not inspector_panel.visible
		if realm_overview.visible:
			_update_realm_overview()


func _update_inspector_core() -> void:
	assault_button.visible = false
	recall_button.visible = false
	if scout_button != null:
		scout_button.visible = false
	if selected_entity_kind == "rivalry_structure" and selected_building_id > 0:
		var structure_snapshot := _find_frame_entity("rivalry_structures", selected_building_id)
		if not structure_snapshot.is_empty():
			var realm_name := "Your realm" if String(structure_snapshot.get("realm", "")) == RivalryTuning.PLAYER_REALM else "Rival realm"
			assault_button.visible = String(structure_snapshot.get("realm", "")) == RivalryTuning.AI_REALM and String(structure_snapshot.get("type", "")) == Defs.BUILDING_OUTPOST
			recall_button.visible = assault_button.visible
			inspector_label.text = "\n".join([
				"[font_size=22][color=#efcf8a]%s[/color][/font_size]" % Defs.building_name(String(structure_snapshot.get("type", ""))),
				"[color=#9fb7b0]%s[/color]" % realm_name,
				"",
				"%s" % String(structure_snapshot.get("status", "")),
				"HP  %d / %d" % [int(structure_snapshot.get("hp", 0)), int(structure_snapshot.get("max_hp", 1))],
				"Lumen  %s" % ["Connected" if bool(structure_snapshot.get("connected", false)) else "Disconnected"],
				_debug_id_line(selected_building_id),
			])
			inspector_panel.visible = true
			return
		selected_building_id = 0
		selected_entity_kind = ""
		inspector_panel.visible = false
		return
	if selected_entity_kind in ["enemy", "rival_worker"] and selected_worker_id > 0:
		var entity_snapshot := _find_frame_entity("combatants", selected_worker_id)
		if not entity_snapshot.is_empty():
			var unit_status := String(entity_snapshot.get("simulation_state", "Ready"))
			inspector_label.text = "\n".join([
				"[font_size=22][color=#efcf8a]%s[/color][/font_size]" % String(entity_snapshot.get("profession", "Unit")),
				"[color=%s]%s[/color]" % ["#e36b5d" if selected_entity_kind == "enemy" else "#9fc6b2", unit_status],
				"",
				"HP  %d / %d" % [int(entity_snapshot.get("hp", 0)), int(entity_snapshot.get("max_hp", 1))],
				"Moves and fights independently",
				_debug_id_line(selected_worker_id),
			])
			inspector_panel.visible = true
			return
	if selected_building_id > 0:
		var building: Dictionary = simulation_host.simulation.get_building_by_id(selected_building_id)
		if building.is_empty():
			selected_building_id = 0
		else:
			var construction := bool(building.get("construction", false))
			var type_name := String(building.get("planned_type", "")) if construction else String(building.get("type", ""))
			var lines: Array[String] = [
				"[font_size=22][color=#efcf8a]%s[/color][/font_size]" % Defs.building_name(type_name),
				"[color=%s]%s[/color]" % ["#e3a36b" if construction else "#9fc6a5", _building_player_status(building, type_name)],
				"",
				"Workers  %d / %d" % [int(building.get("assigned_staff", 0)), Defs.building_staff(type_name)],
				"Road  %s" % ["Connected" if bool(building.get("connected", false)) else "Not connected"],
				"HP  %d / %d" % [int(building.get("hp", 0)), int(building.get("max_hp", 1))],
			]
			if type_name == Defs.BUILDING_HOUSE:
				lines.append("Residents  %d / %d" % [_building_night_occupants(selected_building_id), Defs.adds_population(type_name)])
			var production_def: Dictionary = Defs.PRODUCTION_DEFS.get(type_name, {})
			if not production_def.is_empty():
				var input_resource := String(production_def.get("input", ""))
				var output_resource := String(production_def.get("output", ""))
				if input_resource != "":
					lines.append("%s  %d" % [Defs.resource_name(input_resource), int(Dictionary(building.get("local_inventory", {})).get(input_resource, 0))])
				lines.append("%s  %d" % [Defs.resource_name(output_resource), int(Dictionary(building.get("local_inventory", {})).get(output_resource, 0))])
				var stall: Dictionary = simulation_host.simulation.diagnose_building_dict(building)
				if bool(stall.get("stalled", false)):
					lines.append("[color=#f0a06e]%s[/color]" % String(stall.get("line", "")))
					var last_ago := float(stall.get("last_delivery_seconds", -1.0))
					if last_ago >= 0.0:
						lines.append("Last delivery  %d sec ago" % int(round(last_ago)))
					else:
						lines.append("Last delivery  none yet")
				var band := String(building.get("placement_band", ""))
				if band != "" and int(building.get("placement_percent", 0)) > 0 and String(building.get("type", "")) in [Defs.BUILDING_LUMBER_CAMP, Defs.BUILDING_QUARRY, Defs.BUILDING_FARM]:
					lines.append("Site  %d%% %s" % [int(building.get("placement_percent", 0)), band])
				else:
					var diagnostic := _production_diagnostic(building, type_name)
					if diagnostic != "active":
						lines.append("[color=#f0a06e]%s[/color]" % diagnostic.capitalize())
			if type_name == Defs.BUILDING_BARRACKS and not construction:
				var progress := clampf(float(building.get("training_progress", 0.0)) / Simulation.BARRACKS_TRAIN_SECONDS, 0.0, 1.0)
				lines.append("Recruit  %d available" % simulation_host.simulation.workers_free())
				lines.append("Bread  %d available" % int(simulation_host.simulation.central_inventory.get(Defs.RESOURCE_BREAD, 0)))
				lines.append("Training cost  %d Bread" % Simulation.SOLDIER_BREAD_COST)
				lines.append("Training  %d%%" % roundi(progress * 100.0))
				if int(simulation_host.simulation.central_inventory.get(Defs.RESOURCE_BREAD, 0)) < Simulation.SOLDIER_BREAD_COST:
					lines.append("[color=#f0a06e]Needs Bread[/color]")
			if construction:
				lines.append("Delivered  %s" % _format_inventory(building.get("materials_delivered", {})))
				lines.append("Needed  %s" % _format_inventory(building.get("materials_needed", {})))
			lines.append(_debug_id_line(selected_building_id))
			inspector_label.text = "\n".join(lines)
			inspector_panel.visible = true
			return
	if selected_worker_id > 0 and selected_entity_kind == "worker":
		var worker: Dictionary = simulation_host.simulation.get_worker_by_id(selected_worker_id)
		if worker.is_empty():
			selected_worker_id = 0
		else:
			var descriptor: Dictionary = presentation_adapter.worker_descriptor(worker, simulation_host.simulation)
			var lines := [
				"[font_size=22][color=#efcf8a]%s[/color][/font_size]" % String(descriptor.get("profession", "Worker")),
				"[color=#9fc6a5]%s[/color]" % _worker_player_status(String(descriptor.get("simulation_state", "Idle"))),
				"",
				"%s" % ("Fed" if not bool(worker.get("hungry", false)) else "[color=#f0a06e]Hungry[/color]"),
				"%s" % ("Healthy" if int(worker.get("hp", 0)) >= int(worker.get("max_hp", 1)) else "Injured  %d / %d HP" % [int(worker.get("hp", 0)), int(worker.get("max_hp", 1))]),
			]
			if String(worker.get("type", "")) not in ["guard"]:
				lines.append("Carrying  %s" % ("%s ×%d" % [String(descriptor.get("cargo", "")).capitalize(), int(descriptor.get("cargo_amount", 0))] if int(descriptor.get("cargo_amount", 0)) > 0 else "—"))
			else:
				var scout_name := String(worker.get("display_name", "Soldier"))
				if worker.has("scout_mission"):
					lines.append("%s is scouting." % scout_name)
				else:
					lines.append("%s can Scout (Y) into the fog." % scout_name)
			lines.append(_debug_id_line(selected_worker_id))
			inspector_label.text = "\n".join(lines)
			inspector_panel.visible = true
			if scout_button != null:
				scout_button.visible = simulation_host.simulation.is_patrol_scout(worker) and not worker.has("scout_mission")
			return
	if debug_visible:
		var metrics := world_view.presentation_metrics()
		inspector_label.text = "\n".join([
			"[font_size=20][color=#efcf8a]Debug UI[/color][/font_size]",
			"Workers %d · active %d" % [int(metrics.get("real_workers", 0)), int(metrics.get("active_job_workers", 0))],
			"Cargo carriers %d" % int(metrics.get("carriers_with_cargo", 0)),
			"Construction %d · hostiles %d" % [int(metrics.get("construction_activity", 0)), int(metrics.get("hostile_views", 0))],
		])
		inspector_panel.visible = true
	else:
		inspector_label.text = ""
		inspector_panel.visible = false
		if scout_button != null:
			scout_button.visible = false


## Look lift: stat rows get an icon, a muted label and a bold value, laid out
## in two columns; the name uses the Cinzel display face.
const DISPLAY_FONT_PATH := "res://assets/settlement3d/runtime/interface/fonts/cinzel_bold.tres"
const UI_ICON_PATH := "res://assets/settlement3d/runtime/interface/ui/icon_%s.png"
const STAT_ICON_KEYS := [
	["Workers", "worker"], ["Residents", "house"], ["Recruit", "pop"], ["Road", "road"],
	["HP", "shield"], ["Healthy", "shield"], ["Injured", "shield"], ["Hungry", "hunger"], ["Fed", "bread"],
	["Bread", "bread"], ["Training", "soldier"], ["Wood", "wood"], ["Planks", "planks"], ["Stone", "stone"],
	["Wheat", "wheat"], ["Wyrd", "wyrd"], ["Lumen", "wyrd"], ["Carrying", "worker"], ["Delivered", "hammer"],
	["Needed", "hammer"], ["Population", "pop"], ["Free workers", "worker"], ["Soldiers", "soldier"],
	["Buildings", "house"],
]


static func stat_icon_key(line: String) -> String:
	var plain := line.strip_edges()
	for pair in STAT_ICON_KEYS:
		if plain.begins_with(String(pair[0])) or plain.begins_with("[color=#f0a06e]" + String(pair[0])):
			return String(pair[1])
	return ""


static func _stat_cell(line: String, padding := "0,0,16,2") -> String:
	var key := stat_icon_key(line)
	var icon := ("[img=16x16]%s[/img] " % (UI_ICON_PATH % key)) if key != "" else ""
	var split := line.find("  ")
	var body := line
	if split > 0 and not line.begins_with("["):
		body = "[color=#b9ab86]%s[/color]  [b]%s[/b]" % [line.substr(0, split), line.substr(split + 2)]
	return "[cell padding=%s]%s%s[/cell]" % [padding, icon, body]


func _decorate_inspector() -> void:
	var lines: PackedStringArray = inspector_label.text.split("\n")
	var header: Array[String] = []
	var stats: Array[String] = []
	for index in lines.size():
		var line := String(lines[index]).replace("[font_size=22]", "[font_size=20]").replace("[font_size=19]", "[font_size=20]")
		if index == 0:
			line = "[font=%s]%s[/font]" % [DISPLAY_FONT_PATH, line]
		if index < 2:
			header.append(line)
			if index == 1:
				var purpose := _selection_purpose()
				if purpose != "":
					header.append("[font_size=12][color=#a8a08a]%s[/color][/font_size]" % purpose)
		elif line.strip_edges() != "":
			stats.append(line)
	var hp := -1
	var max_hp := -1
	var hp_regex := RegEx.new()
	hp_regex.compile("(\\d+)\\s*/\\s*(\\d+)\\s*HP|HP\\s+(\\d+)\\s*/\\s*(\\d+)")
	var cells := ""
	for stat in stats:
		var found := hp_regex.search(stat)
		if found != null and hp < 0:
			hp = int(found.get_string(1) if found.get_string(1) != "" else found.get_string(3))
			max_hp = int(found.get_string(2) if found.get_string(2) != "" else found.get_string(4))
		cells += _stat_cell(stat)
	var text := "\n".join(header)
	if cells != "":
		text += "\n[table=2]%s[/table]" % cells
	inspector_label.text = text
	if portrait_hp_label != null:
		portrait_hp_label.text = "%d / %d" % [hp, max_hp] if max_hp > 0 else "Healthy"
	var portrait := _selection_portrait_key()
	if portrait != portrait_key:
		portrait_key = portrait
		_rebuild_portrait(portrait)
	if portrait_hp_bar != null:
		var ratio := 1.0 if max_hp <= 0 else clampf(float(hp) / float(max_hp), 0.0, 1.0)
		portrait_hp_bar.value = ratio
		portrait_hp_bar.tooltip_text = "HP %d / %d" % [hp, max_hp] if max_hp > 0 else "Healthy"
		if portrait_hp_fill != null:
			portrait_hp_fill.bg_color = Color("#79c26a") if ratio > 0.6 else (Color("#e0b04c") if ratio > 0.3 else Color("#e0604c"))


func _selection_purpose() -> String:
	var key := _selection_portrait_key()
	if not key.begins_with("building:"):
		return ""
	var type_name := key.substr(9)
	if type_name == Defs.BUILDING_TOWN_HALL:
		return "Seat of your realm. Settlers, carts and stores start here. Lose it and the realm falls."
	return String(BUILD_PURPOSES.get(type_name, ""))


func _selection_portrait_key() -> String:
	if selected_entity_kind == "rivalry_structure" and selected_building_id > 0:
		return "building:" + String(_find_frame_entity("rivalry_structures", selected_building_id).get("type", ""))
	if selected_entity_kind == "enemy":
		return "icon:enemy"
	if selected_entity_kind == "rival_worker":
		return "icon:rival"
	if selected_building_id > 0:
		var building: Dictionary = simulation_host.simulation.get_building_by_id(selected_building_id)
		var construction := bool(building.get("construction", false))
		return "building:" + (String(building.get("planned_type", "")) if construction else String(building.get("type", "")))
	if selected_worker_id > 0:
		return "icon:worker"
	return "icon:debug"


func _rebuild_portrait(key: String) -> void:
	if portrait_host == null:
		return
	for child in portrait_host.get_children():
		child.queue_free()
	if key.begins_with("building:") and HudSkin.thumbnail(key.substr(9)) != null:
		# Look lift: the portrait is the rendered building thumbnail.
		var thumb := HudSkin.thumbnail_rect(key.substr(9), Vector2(96, 72))
		thumb.name = "PortraitThumbnail"
		thumb.position = Vector2(0, 8)
		portrait_host.add_child(thumb)
		return
	if key.begins_with("building:"):
		var holder := Control.new()
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.scale = Vector2(1.3, 1.3)
		holder.position = Vector2(2, 22)
		holder.size = Vector2(72, 40)
		var portrait_type := key.substr(9)
		var portrait_icon := _create_town_hall_portrait() if portrait_type == Defs.BUILDING_TOWN_HALL else _create_building_icon_visual(portrait_type)
		portrait_icon.set_anchors_preset(Control.PRESET_TOP_LEFT)
		portrait_icon.size = Vector2(72, 40)
		holder.add_child(portrait_icon)
		portrait_host.add_child(holder)
		return
	var icon_key := "pop"
	var tint := Color(1, 1, 1, 1)
	match key:
		"icon:enemy":
			icon_key = "soldier"
			tint = Color("#ff8a7a")
		"icon:rival":
			icon_key = "soldier"
			tint = Color("#d98c96")
		"icon:debug":
			icon_key = "wyrd"
	var rect := HudSkin.icon_rect(icon_key, 72.0)
	rect.modulate = tint
	rect.position = Vector2(12, 8)
	rect.size = Vector2(72, 72)
	portrait_host.add_child(rect)


## Small stone-keep emblem for the Town Hall portrait (the strip has no Town
## Hall plan, so there is no strip icon to reuse).
func _create_town_hall_portrait() -> Control:
	var canvas := Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var parts := [
		[Vector2(14, 12), Vector2(44, 26), Color("#8a8778")],
		[Vector2(8, 4), Vector2(12, 34), Color("#a3a090")],
		[Vector2(52, 4), Vector2(12, 34), Color("#a3a090")],
		[Vector2(26, 0), Vector2(20, 12), Color("#3f5a52")],
		[Vector2(31, 24), Vector2(10, 14), Color("#4a2f1c")],
		[Vector2(16, 16), Vector2(5, 6), Color(0.95, 0.78, 0.42, 0.9)],
		[Vector2(51, 16), Vector2(5, 6), Color(0.95, 0.78, 0.42, 0.9)],
		[Vector2(35, -8), Vector2(2, 10), Color("#5c4a32")],
		[Vector2(37, -8), Vector2(9, 5), Color("#3f7380")],
	]
	for merlon_x in [8, 14, 52, 58]:
		parts.append([Vector2(merlon_x, 0), Vector2(5, 4), Color("#a3a090")])
	for part in parts:
		var rect := ColorRect.new()
		rect.position = part[0]
		rect.size = part[1]
		rect.color = part[2]
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(rect)
	return canvas


func _update_realm_overview() -> void:
	var sim = simulation_host.simulation
	var settlement: Dictionary = current_frame_snapshot.get("settlement", {})
	var buildings := 0
	var constructing := 0
	for building_value in sim.buildings:
		if bool(Dictionary(building_value).get("construction", false)):
			constructing += 1
		else:
			buildings += 1
	var free_workers := int(sim.workers_free())
	var food := int(settlement.get("food", 0))
	var demand := int(settlement.get("next_food_demand", 0))
	var cells: Array[String] = [
		_stat_cell("Population  %d / %d" % [int(sim.population_current), int(sim.housing_capacity)], "0,0,22,2"),
		_stat_cell("Free workers  %s" % ("[color=#8fe08a]%d[/color]" % free_workers if free_workers > 0 else "[color=#ff9d8f]0[/color]"), "0,0,22,2"),
		_stat_cell("Soldiers  %d" % int(sim.soldiers_total), "0,0,22,2"),
		_stat_cell("Buildings  %d%s" % [buildings, ("  (+%d rising)" % constructing) if constructing > 0 else ""], "0,0,22,2"),
		_stat_cell("Bread  %s" % ("%d / %d needed" % [food, demand] if demand > 0 else str(food)), "0,0,22,2"),
		_stat_cell("Hungry  %s" % ("[color=#ff9d8f]%d[/color]" % int(settlement.get("hungry", 0)) if int(settlement.get("hungry", 0)) > 0 else "0"), "0,0,22,2"),
	]
	realm_overview.text = "[font=%s][font_size=20][color=#f0c880]Your Realm[/color][/font_size][/font]   [color=#b9ab86]%s  ·  %s[/color]\n[table=2]%s[/table]\n[font_size=12][color=#8f8a76]Click a building or settler to inspect it  ·  H jumps to the Town Hall[/color][/font_size]" % [
		DISPLAY_FONT_PATH, _clock_title(), _phase_countdown_text(), "".join(cells)]


func _building_player_status(building: Dictionary, type_name: String) -> String:
	if bool(building.get("construction", false)):
		return "Under construction"
	if type_name == Defs.BUILDING_BARRACKS:
		if simulation_host.simulation.workers_free() <= 0:
			return "Idle — no free recruits"
		if int(simulation_host.simulation.central_inventory.get(Defs.RESOURCE_BREAD, 0)) < Simulation.SOLDIER_BREAD_COST:
			return "Idle — needs Bread"
		if float(building.get("training_progress", 0.0)) > 0.0:
			return "Training Soldier"
		return "Ready to train"
	if not bool(building.get("connected", false)) and type_name not in [Defs.BUILDING_WALL, Defs.BUILDING_WATCHTOWER]:
		return "Not connected to a road"
	if Defs.building_staff(type_name) > 0 and int(building.get("assigned_staff", 0)) < Defs.building_staff(type_name):
		return "Needs workers"
	return String(building.get("status", "Ready")).trim_suffix(".")


func _worker_player_status(raw_status: String) -> String:
	var lower := raw_status.to_lower()
	if "return" in lower:
		return "Returning to camp"
	if "pickup" in lower or "collect" in lower:
		return "Collecting supplies"
	if "dropoff" in lower or "deliver" in lower:
		return "Delivering supplies"
	if "shelter" in lower:
		return "Heading to shelter" if "going" in lower else "Resting in shelter"
	if "work" in lower:
		return "Working"
	if "moving" in lower or "walk" in lower:
		return "Travelling"
	return raw_status.capitalize()


func _debug_id_line(id: int) -> String:
	return "[color=#71827d]ID %d[/color]" % id if debug_visible else ""


func _order_selected_outpost_assault() -> void:
	var snapshot := _find_frame_entity("rivalry_structures", selected_building_id)
	_show_command_result(simulation_host.simulation.request_outpost_assault(int(snapshot.get("authority_id", 0))))


func _find_frame_entity(collection_name: String, id: int) -> Dictionary:
	for snapshot_value in current_frame_snapshot.get(collection_name, []):
		var snapshot: Dictionary = snapshot_value
		if int(snapshot.get("id", 0)) == id:
			return snapshot
	return {}


func _building_night_occupants(id: int) -> int:
	var snapshot := _find_frame_entity("buildings", id)
	return int(snapshot.get("sheltered_occupants", 0))


func _production_diagnostic(building: Dictionary, type_name: String) -> String:
	if bool(building.get("construction", false)):
		return "construction incomplete"
	if not bool(building.get("connected", false)):
		return "idle — no road access"
	if int(building.get("assigned_staff", 0)) < Defs.building_staff(type_name):
		return "idle — unstaffed"
	var status := String(building.get("status", ""))
	if "full" in status.to_lower() or "blocked" in status.to_lower():
		return "blocked output — %s" % status
	if "waiting" in status.to_lower() or "needs" in status.to_lower():
		return "missing input — %s" % status
	return "active" if bool(building.get("staffed", true)) else "idle"


func _building_tooltip(building_type: String) -> String:
	var footprint := Defs.building_footprint(building_type)
	return "%s\nCost: %s\nFootprint: %dx%d\n%s" % [
		Defs.building_name(building_type),
		Defs.formatted_cost(building_type),
		footprint.x,
		footprint.y,
		String(BUILD_PURPOSES.get(building_type, "Settlement building.")),
	]


func _current_alert_text(settlement: Dictionary) -> String:
	if int(settlement.get("enemies", 0)) > 0:
		return "RAID ACTIVE  ·  %d hostiles are inside the frontier" % int(settlement.get("enemies", 0))
	for building_value in simulation_host.simulation.buildings:
		var building: Dictionary = building_value
		if int(building.get("hp", 1)) < int(building.get("max_hp", 1)):
			return "BUILDING UNDER ATTACK  ·  %s" % Defs.building_name(String(building.get("type", "")))
	if int(settlement.get("homeless", 0)) > 0:
		return "NOT ENOUGH HOUSING  ·  %d residents need a home" % int(settlement.get("homeless", 0))
	if int(settlement.get("food", 0)) < int(settlement.get("next_food_demand", 0)):
		return "FOOD SHORTAGE  ·  %d Bread available, %d needed" % [int(settlement.get("food", 0)), int(settlement.get("next_food_demand", 0))]
	if int(settlement.get("hungry", 0)) > 0:
		return "%d RESIDENTS ARE HUNGRY  ·  work is slower" % int(settlement.get("hungry", 0))
	for building_value in simulation_host.simulation.buildings:
		var status := String(Dictionary(building_value).get("status", ""))
		if "storage full" in status.to_lower():
			return "STORAGE FULL  ·  build a Storehouse or free capacity"
		if bool(Dictionary(building_value).get("construction", false)) and ("waiting" in status.to_lower() or "blocked" in status.to_lower()):
			return "CONSTRUCTION BLOCKED  ·  %s" % status
	if int(settlement.get("workers_free", 0)) <= 0:
		return "NO FREE WORKERS  ·  add housing and allow population growth"
	return ""


func _ingest_simulation_notices() -> void:
	if simulation_host.simulation == null or not simulation_host.simulation.has_method("consume_pending_notices"):
		return
	for notice_value in simulation_host.simulation.consume_pending_notices():
		var notice: Dictionary = notice_value
		var severity := String(notice.get("severity", "info"))
		# Look lift: critical notices go to the top-right banner; everything
		# else lands in the left-hand feed. All of it stays in the LOG.
		if severity == "critical" or notice_feed == null:
			_show_toast(String(notice.get("title", "")), String(notice.get("body", "")), severity)
		else:
			_push_notice_feed(String(notice.get("title", "")), String(notice.get("body", "")), severity)
	_refresh_event_log()


func _push_notice_feed(title: String, body: String, severity: String) -> void:
	if notice_feed == null or title == "":
		return
	# Repeats of the newest entry refresh it instead of stacking copies.
	if not notice_feed_entries.is_empty() and String(notice_feed_entries[0].get("key", "")) == "%s:%s" % [title, body] and is_instance_valid(notice_feed_entries[0]["node"]):
		notice_feed_entries[0]["until"] = hud_clock + (16.0 if severity == "critical" else 11.0)
		(notice_feed_entries[0]["node"] as Control).modulate.a = 1.0
		return
	var entry := PanelContainer.new()
	entry.name = "Notice"
	entry.mouse_filter = Control.MOUSE_FILTER_IGNORE
	entry.add_theme_stylebox_override("panel", HudSkin.frame("toast", 7.0))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	entry.add_child(row)
	var stripe := ColorRect.new()
	stripe.custom_minimum_size = Vector2(4, 0)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stripe.color = {"critical": Color("#e0604c"), "warning": Color("#e0a15c"), "success": Color("#79c26a")}.get(severity, Color("#6bcfe0"))
	row.add_child(stripe)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 0)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(copy)
	var title_label := Label.new()
	title_label.text = title
	HudSkin.set_font(title_label, HudSkin.ui_font(700), HudSkin.SIZE_BODY, HudSkin.COLOR_GOLD if severity != "critical" else Color("#ffb4a4"))
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(title_label)
	if body != "":
		var body_label := Label.new()
		body_label.text = body
		body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body_label.max_lines_visible = 2
		HudSkin.set_font(body_label, HudSkin.ui_font(400), HudSkin.SIZE_CAPTION, Color("#ddd4bd"))
		body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		copy.add_child(body_label)
	notice_feed.add_child(entry)
	notice_feed.move_child(entry, 0)
	var hold := 16.0 if severity == "critical" else 11.0
	notice_feed_entries.push_front({"node": entry, "until": hud_clock + hold, "key": "%s:%s" % [title, body]})
	while notice_feed_entries.size() > NOTICE_FEED_LIMIT:
		var dropped: Dictionary = notice_feed_entries.pop_back()
		(dropped["node"] as Node).queue_free()


func _tick_notice_feed() -> void:
	if notice_feed_entries.is_empty():
		return
	var now := hud_clock
	for index in range(notice_feed_entries.size() - 1, -1, -1):
		var entry: Dictionary = notice_feed_entries[index]
		var node_value = entry["node"]
		if not is_instance_valid(node_value):
			notice_feed_entries.remove_at(index)
			continue
		var node := node_value as Control
		var remaining := float(entry["until"]) - now
		if remaining <= 0.0:
			node.queue_free()
			notice_feed_entries.remove_at(index)
		elif remaining < 1.2:
			node.modulate.a = remaining / 1.2


func _show_toast(title: String, body: String, severity: String = "info", hold_seconds: float = -1.0) -> void:
	if title == "":
		return
	# Look lift: no centre pop-ups. Only critical notices use the banner; the
	# rest (e.g. "Insufficient Resources") go to the left feed.
	if severity != "critical" and notice_feed != null:
		_push_notice_feed(title, body, severity)
		return
	var key := "%s:%s" % [title, body]
	if key == last_toast_key and hud_clock < toast_until:
		return
	last_toast_key = key
	toast_severity = severity
	if toast_title != null:
		toast_title.text = title
	if toast_body != null:
		toast_body.text = body
	var hold := hold_seconds if hold_seconds > 0.0 else (7.5 if severity == "critical" else 4.2)
	toast_until = hud_clock + hold
	if alert_panel != null:
		alert_panel.visible = startup_overlay == null or not startup_overlay.visible
		alert_panel.modulate.a = 1.0


## Look lift raid banner: while hostiles are alive at night the banner shows
## "N raiders · from the west · ETA ~0:45" and stays up (unless dismissed for
## this raid). ETA = the soonest raider's remaining path x step time, or the
## straight-line tile distance to the Town Hall when it has no path yet.
func raid_status() -> Dictionary:
	var sim = simulation_host.simulation
	if sim == null:
		return {}
	var count := int(sim.living_hostile_count())
	if count <= 0:
		return {"count": 0}
	var town: Vector2i = sim._footprint_center(sim.town_hall_position, Defs.building_footprint(Defs.BUILDING_TOWN_HALL))
	var best_eta := INF
	var nearest := Vector2i.ZERO
	var nearest_distance := INF
	for enemy_value in sim.enemies:
		var enemy: Dictionary = enemy_value
		if int(enemy.get("hp", 0)) <= 0 or bool(enemy.get("retreating", false)):
			continue
		var position := Vector2i(enemy.get("position", Vector2i.ZERO))
		var distance := float(maxi(absi(position.x - town.x), absi(position.y - town.y)))
		var step := float(sim.ENEMY_STEP_SECONDS) * float(enemy.get("speed_multiplier", 1.0))
		var path: Array = enemy.get("path", [])
		var eta := float(path.size()) * step if not path.is_empty() else distance * step
		best_eta = minf(best_eta, eta)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = position
	var bearing := String(sim._bearing_from_town(nearest))
	var eta_seconds := 0 if best_eta == INF else int(ceil(best_eta))
	var at_gates := nearest_distance <= 4.0
	var eta_text := "at the Town Hall" if at_gates else "ETA ~%d:%02d" % [eta_seconds / 60, eta_seconds % 60]
	return {
		"count": count,
		"bearing": bearing,
		"eta_seconds": eta_seconds,
		"at_gates": at_gates,
		"line": "%d raider%s  ·  from %s  ·  %s" % [count, "" if count == 1 else "s", bearing, eta_text],
	}


func _update_raid_banner() -> void:
	if alert_panel == null or simulation_host.simulation == null:
		return
	var status := raid_status()
	var raiding := int(status.get("count", 0)) > 0 and play_has_begun
	if raiding and not raid_banner_active:
		raid_banner_dismissed = false
	raid_banner_active = raiding
	if raid_eta_row != null:
		raid_eta_row.visible = raiding
	if not raiding:
		return
	raid_eta_label.text = String(status.get("line", ""))
	if raid_banner_dismissed:
		return
	if toast_title.text != "RAID" and toast_until > hud_clock and toast_severity == "critical" and last_toast_key != "":
		return  # another critical notice (e.g. Town Hall under attack) is showing
	toast_title.text = "RAID"
	toast_body.text = "%d hostile%s coming from %s." % [int(status.get("count", 0)), " is" if int(status.get("count", 0)) == 1 else "s are", String(status.get("bearing", "the wilds"))]
	toast_until = maxf(toast_until, hud_clock + 1.5)
	toast_severity = "critical"
	alert_panel.visible = startup_overlay == null or not startup_overlay.visible
	alert_panel.modulate.a = 1.0


func _dismiss_toast() -> void:
	toast_until = 0.0
	if raid_banner_active:
		raid_banner_dismissed = true
	if alert_panel != null:
		alert_panel.visible = false


func _tick_toasts(_delta: float) -> void:
	if alert_panel == null or not alert_panel.visible:
		return
	var remaining := toast_until - hud_clock
	if remaining <= 0.0:
		alert_panel.visible = false
		return
	alert_panel.modulate.a = clampf(remaining / 0.6, 0.0, 1.0) if remaining < 0.6 else 1.0


func _toggle_event_log() -> void:
	if event_log_panel == null:
		return
	event_log_panel.visible = not event_log_panel.visible
	if event_log_panel.visible:
		_refresh_event_log()


func _refresh_event_log() -> void:
	if event_log_body == null or simulation_host.simulation == null:
		return
	if not simulation_host.simulation.has_method("get_notice_log"):
		return
	var lines: Array[String] = []
	var log: Array = simulation_host.simulation.get_notice_log()
	for index in range(log.size() - 1, -1, -1):
		var notice: Dictionary = log[index]
		lines.append("[b]%s[/b]\n%s" % [String(notice.get("title", "")), String(notice.get("body", ""))])
	event_log_body.text = "\n\n".join(lines) if not lines.is_empty() else "No recent events."


func _pressure_unlocked() -> bool:
	return simulation_host.simulation != null


func _toggle_objective_detail() -> void:
	if objective_detail_panel == null:
		return
	_show_objective_detail(not objective_detail_panel.visible)


func _tick_edge_pan(delta: float) -> void:
	if camera_rig == null or not camera_rig.input_enabled or not play_has_begun:
		return
	if camera_rig.dragging or map_drag_active:
		return
	if startup_overlay != null and startup_overlay.visible:
		return
	if _pointer_over_ui():
		return
	var mouse := get_viewport().get_mouse_position()
	var view_size := get_viewport().get_visible_rect().size
	if mouse == Vector2.ZERO or mouse.x < 0.0 or mouse.y < 0.0 or mouse.x > view_size.x or mouse.y > view_size.y:
		return
	var margin := 34.0
	var edge := Vector2.ZERO
	if mouse.x <= margin:
		edge.x -= 1.0
	elif mouse.x >= view_size.x - margin:
		edge.x += 1.0
	if mouse.y <= margin:
		edge.y -= 1.0
	elif mouse.y >= view_size.y - margin:
		edge.y += 1.0
	if edge == Vector2.ZERO:
		return
	camera_rig.pan_from_axes(edge.normalized() * delta * camera_rig.target_zoom * 0.40, "edge")


func _show_objective_detail(value: bool) -> void:
	if objective_detail_panel == null or simulation_host.simulation == null:
		return
	objective_detail_panel.visible = value
	if not value:
		return
	objective_detail_panel.size = Vector2(286, 156)
	var intentions: Array = simulation_host.simulation.get_settlement_intentions()
	var sim_objectives: Array = simulation_host.simulation.get_objectives()
	var lines: Array[String] = ["What matters next", ""]
	for intention_value in intentions:
		var intention: Dictionary = intention_value
		lines.append(String(intention.get("title", "")))
		for row in intention.get("criteria", []):
			lines.append("%s %s" % ["[✓]" if bool(row.get("done", false)) else "[ ]", String(row.get("label", ""))])
		lines.append("")
	if intentions.is_empty():
		if sim_objectives.is_empty():
			var objective: Dictionary = simulation_host.simulation.get_macro_objective()
			lines.append(String(objective.get("title", "FEED THE SETTLEMENT")))
			lines.append(String(objective.get("summary", objective.get("detail", ""))))
			lines.append("")
			var steps: Array = objective.get("steps", [])
			for step in steps:
				lines.append("• %s" % String(step))
		else:
			for obj in sim_objectives:
				var complete := bool(obj.get("complete", false))
				var mark := "[✓]" if complete else "[ ]"
				var text := String(obj.get("text", ""))
				lines.append("%s %s" % [mark, text])
	objective_detail_body.text = "\n".join(lines)


func _glance_at_shard() -> void:
	if camera_rig == null or world_view == null or simulation_host.simulation == null:
		return
	shard_glance_from = camera_rig.global_position if camera_rig.has_method("get_focus_position") else Vector3.ZERO
	var shard_world := world_view.tile_to_world(Vector2(simulation_host.simulation.shard_position))
	camera_rig.compose_view(shard_world, ProductionIsometricCameraRig3D.NORMAL_ZOOM)
	shard_glance_until = Time.get_ticks_msec() / 1000.0 + 1.35
	simulation_host.simulation.note_player_command("camera_jump", "shard")


func _tick_shard_glance() -> void:
	if shard_glance_until <= 0.0:
		return
	if Time.get_ticks_msec() / 1000.0 < shard_glance_until:
		return
	shard_glance_until = 0.0
	if camera_rig == null or world_view == null or simulation_host.simulation == null:
		return
	var town := Vector2(simulation_host.simulation.town_hall_position) + Vector2(1.5, 1.5)
	camera_rig.compose_view(world_view.tile_to_world(town), ProductionIsometricCameraRig3D.NORMAL_ZOOM)


func _tick_minimap(delta: float) -> void:
	if minimap == null:
		return
	var menu_visible := startup_overlay != null and startup_overlay.visible
	var result_visible := result_overlay != null and result_overlay.visible
	minimap.visible = play_has_begun and not menu_visible and not result_visible
	if minimap.visible:
		minimap.tick(delta, current_frame_snapshot)


func _focus_from_minimap(world_position: Vector3) -> void:
	if camera_rig != null:
		camera_rig.focus_world(world_position)


func _update_shard_compass() -> void:
	if shard_compass == null:
		return
	shard_compass.visible = false


func _should_recommend_frontier(building_type: String) -> bool:
	if simulation_host.simulation == null or not simulation_host.simulation.has_method("_starter_economy_ready"):
		return false
	if not bool(simulation_host.simulation._starter_economy_ready()):
		return false
	return building_type in [Defs.BUILDING_OUTPOST, Defs.BUILDING_LUMEN_PILLAR]


func _start_clear_drag(screen_position: Vector2) -> void:
	var hit := _raycast_terrain(screen_position)
	if hit.is_empty():
		return
	clear_drag_start = world_view.world_to_tile(hit.position)
	clear_dragging = true
	_update_clear_drag(screen_position)


func _update_clear_drag(screen_position: Vector2) -> void:
	if not clear_dragging:
		return
	var hit := _raycast_terrain(screen_position)
	if hit.is_empty():
		return
	var endpoint := world_view.world_to_tile(hit.position)
	var count := absi(endpoint.x - clear_drag_start.x) + 1
	count *= absi(endpoint.y - clear_drag_start.y) + 1
	placement_label.text = "CLEAR · marking %d tiles" % count


func _finish_clear_drag(screen_position: Vector2) -> void:
	_update_clear_drag(screen_position)
	var hit := _raycast_terrain(screen_position)
	clear_dragging = false
	if hit.is_empty() or simulation_host.simulation == null:
		return
	var endpoint := world_view.world_to_tile(hit.position)
	var tiles: Array[Vector2i] = []
	for y in range(mini(clear_drag_start.y, endpoint.y), maxi(clear_drag_start.y, endpoint.y) + 1):
		for x in range(mini(clear_drag_start.x, endpoint.x), maxi(clear_drag_start.x, endpoint.x) + 1):
			tiles.append(Vector2i(x, y))
	var result: Dictionary = simulation_host.simulation.request_clear_area(tiles)
	_show_status(String(result.get("message", "")), 3.0)
	if bool(result.get("success", false)):
		_sync_presentation()
		cancel_placement()
		_set_build_palette_visible(false)


func _can_attempt_build(building_type: String) -> bool:
	return _build_unavailable_reason(building_type) == ""


func _build_unavailable_reason(building_type: String) -> String:
	if simulation_host.simulation == null:
		return "No settlement is active"
	if building_type == Defs.TOOL_CLEAR_AREA:
		return ""
	if building_type == Defs.BUILDING_ROAD and simulation_host.simulation.workers_free() <= 0:
		return "No free worker can build the road"
	for resource_type in Defs.building_cost(building_type):
		if simulation_host.simulation.get_available_resource(resource_type) < int(Defs.building_cost(building_type)[resource_type]):
			return "Needs %s" % Defs.formatted_cost(building_type)
	return ""


func _format_inventory(inventory_value) -> String:
	var inventory: Dictionary = inventory_value if typeof(inventory_value) == TYPE_DICTIONARY else {}
	var parts: Array[String] = []
	for resource_type in Defs.RESOURCE_TYPES:
		var amount := int(inventory.get(resource_type, 0))
		if amount > 0:
			parts.append("%s %d" % [Defs.resource_name(resource_type), amount])
	return ", ".join(parts) if not parts.is_empty() else "empty"


func _toggle_pause() -> void:
	simulation_host.paused = not simulation_host.paused
	world_view.set_presentation_paused(simulation_host.paused)
	_sync_speed_controls()


## ▶: resume (if paused) at normal speed.
func _play_normal_speed() -> void:
	simulation_host.speed_multiplier = 1.0
	if simulation_host.paused:
		simulation_host.paused = false
		world_view.set_presentation_paused(false)
	_sync_speed_controls()


## ⏩: 1x -> 2x -> 4x -> 2x ... (▶ returns to 1x). Also resumes a paused game.
func _cycle_speed() -> void:
	simulation_host.speed_multiplier = 4.0 if is_equal_approx(simulation_host.speed_multiplier, 2.0) else 2.0
	if simulation_host.paused:
		simulation_host.paused = false
		world_view.set_presentation_paused(false)
	_sync_speed_controls()


## Look lift: the three icon buttons behave like one radio group; the active
## state is shown by the gold "pressed" frame, the details live in tooltips.
func _sync_speed_controls() -> void:
	if pause_button == null or simulation_host == null:
		return
	var paused := bool(simulation_host.paused)
	var speed := float(simulation_host.speed_multiplier)
	pause_button.set_pressed_no_signal(paused)
	pause_button.tooltip_text = ("Resume" if paused else "Pause") + "  [Space]"
	if play_button != null:
		play_button.set_pressed_no_signal(not paused and speed <= 1.0)
	if speed_button != null:
		speed_button.set_pressed_no_signal(not paused and speed > 1.0)
		speed_button.text = ("%dx" % int(speed)) if speed > 1.0 else ""
		speed_button.custom_minimum_size.x = 50.0 if speed > 1.0 else 30.0
		speed_button.tooltip_text = "Fast forward (now %dx): 2x, press again for 4x" % int(speed) if speed > 1.0 else "Fast forward: 2x, press again for 4x"


func _create_start_menu(root: Control) -> void:
	startup_overlay = ColorRect.new()
	startup_overlay.name = "PlaytestStartMenu"
	startup_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	startup_overlay.color = Color(0.012, 0.018, 0.028, 0.28)
	startup_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(startup_overlay)
	menu_backdrop = TextureRect.new()
	menu_backdrop.name = "TitleArtwork"
	menu_backdrop.texture = preload("res://assets/settlement3d/runtime/interface/title_settlement_v1.png")
	menu_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	menu_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	menu_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	startup_overlay.add_child(menu_backdrop)

	menu_card = _menu_panel("StartPanel", Vector2(-180, -220), Vector2(360, 440))
	startup_overlay.add_child(menu_card)
	menu_card.add_theme_stylebox_override("panel", Identity.panel_style(Color(0.018, 0.035, 0.044, 0.84), Color(0.65, 0.53, 0.32, 0.45), 10))
	var menu_box := _menu_box(menu_card)
	var title := Label.new()
	title.name = "GameTitle"
	title.text = "SHARD &\nSOVEREIGN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Identity.apply_label(title, "title")
	title.add_theme_font_size_override("font_size", 36)
	menu_box.add_child(title)
	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0, 1)
	rule.color = Identity.COLOR_WYRD.darkened(0.25)
	menu_box.add_child(rule)
	var subtitle := Label.new()
	subtitle.text = "Warm civilisation. Cold Wyrd."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Identity.apply_label(subtitle, "caption")
	menu_box.add_child(subtitle)
	resume_button = _menu_action(menu_box, "ResumePlay", "RESUME", 48, _resume_from_menu)
	resume_button.visible = false
	menu_save_button = _menu_action(menu_box, "SaveFromMenu", "SAVE", 40, save_game)
	menu_save_button.visible = false
	_menu_action(menu_box, "NewSettlement", "NEW REALM", 48, _show_new_realm_card)
	continue_button = _menu_action(menu_box, "LoadSettlement", "CONTINUE", 44, load_game)
	_menu_action(menu_box, "OpenSettings", "SETTINGS", 40, _show_settings_card)
	_menu_action(menu_box, "FeedbackBundle", "SAVE FEEDBACK REPORT", 32, _export_feedback)
	_menu_action(menu_box, "QuitGame", "SAVE & QUIT", 40, _request_quit)
	var build_label := Label.new()
	build_label.text = "PLAYTEST · " + String(ProjectSettings.get_setting("application/config/version", "development"))
	build_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Identity.apply_label(build_label, "caption")
	menu_box.add_child(build_label)
	_place_start_column(menu_card, 360.0)

	new_realm_card = _menu_panel("NewRealmPanel", Vector2(-180, -170), Vector2(360, 340))
	startup_overlay.add_child(new_realm_card)
	var realm_box := _menu_box(new_realm_card)
	var realm_title := Label.new()
	realm_title.text = "NEW REALM"
	realm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Identity.apply_label(realm_title, "heading")
	realm_box.add_child(realm_title)
	var difficulty := Label.new()
	difficulty.text = "Difficulty  FRONTIER"
	difficulty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Identity.apply_label(difficulty, "caption")
	realm_box.add_child(difficulty)
	_menu_action(realm_box, "BeginRealm", "BEGIN", 52, _start_from_menu)
	var advanced := Button.new()
	advanced.text = "ADVANCED"
	Identity.apply_button(advanced)
	advanced.pressed.connect(func() -> void:
		if seed_advanced != null:
			seed_advanced.visible = not seed_advanced.visible
	)
	realm_box.add_child(advanced)
	seed_advanced = VBoxContainer.new()
	seed_advanced.visible = false
	realm_box.add_child(seed_advanced)
	var seed_label := Label.new()
	seed_label.text = "Seed"
	Identity.apply_label(seed_label, "caption")
	seed_advanced.add_child(seed_label)
	seed_edit = LineEdit.new()
	seed_edit.name = "SeedInput"
	seed_edit.placeholder_text = "RANDOM"
	seed_advanced.add_child(seed_edit)
	_menu_action(realm_box, "BackFromRealm", "BACK", 36, _show_main_menu_card)
	new_realm_card.visible = false
	_place_start_column(new_realm_card, 360.0)

	settings_card = _menu_panel("SettingsPanel", Vector2(-190, -210), Vector2(380, 420))
	startup_overlay.add_child(settings_card)
	var settings_box := _menu_box(settings_card)
	var settings_title := Label.new()
	settings_title.text = "SETTINGS"
	settings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Identity.apply_label(settings_title, "heading")
	settings_box.add_child(settings_title)
	var audio_settings := Identity.load_audio_settings()
	master_slider = _add_volume_slider(settings_box, "Master", float(audio_settings.get("master", 1.0)))
	music_slider = _add_volume_slider(settings_box, "Music", float(audio_settings.get("music", 0.72)))
	sfx_slider = _add_volume_slider(settings_box, "Effects", float(audio_settings.get("sfx", 0.85)))
	var quality_row := HBoxContainer.new()
	var quality_label := Label.new()
	quality_label.text = "Visual quality"
	quality_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Identity.apply_label(quality_label, "caption")
	quality_row.add_child(quality_label)
	quality_select = OptionButton.new()
	quality_select.name = "QualityProfile"
	quality_select.add_item("Recommended", 0)
	quality_select.set_item_metadata(0, "recommended")
	quality_select.add_item("Scalable Low", 1)
	quality_select.set_item_metadata(1, "scalable_low")
	quality_select.item_selected.connect(func(_index: int) -> void:
		_apply_menu_quality()
		_save_display_settings()
	)
	quality_row.add_child(quality_select)
	settings_box.add_child(quality_row)
	fullscreen_check = CheckBox.new()
	fullscreen_check.text = "Fullscreen"
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_check.toggled.connect(_set_fullscreen)
	settings_box.add_child(fullscreen_check)
	_menu_action(settings_box, "BackFromSettings", "BACK", 36, _show_main_menu_card)
	settings_card.visible = false
	_place_start_column(settings_card, 380.0)

	var review_button := Button.new()
	review_button.name = "NewReviewSeed"
	review_button.text = "New Settlement · Review Seed %d" % DEFAULT_SEED
	review_button.visible = false
	review_button.pressed.connect(_start_review_seed)
	startup_overlay.add_child(review_button)
	var legacy_button := Button.new()
	legacy_button.name = "Legacy2D"
	legacy_button.text = "Legacy 2D safety rail"
	legacy_button.visible = false
	legacy_button.pressed.connect(_return_to_legacy_2d)
	startup_overlay.add_child(legacy_button)
	startup_overlay.visible = false


func _menu_panel(panel_name: String, position: Vector2, size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = position.x
	panel.offset_top = position.y
	panel.offset_right = position.x + size.x
	panel.offset_bottom = position.y + size.y
	panel.add_theme_stylebox_override("panel", Identity.panel_style(Identity.COLOR_MENU_PANEL, Identity.COLOR_PANEL_BORDER, 10))
	return panel


func _place_start_column(panel: Control, width: float) -> void:
	if panel == null:
		return
	panel.reset_size()
	var viewport := Vector2(1280.0, 720.0)
	if get_viewport() != null:
		viewport = get_viewport().get_visible_rect().size
	var min_size := panel.get_combined_minimum_size()
	var width_px := maxf(width, min_size.x)
	var height_px := maxf(min_size.y, 160.0)
	height_px = minf(height_px, maxf(240.0, viewport.y - 40.0))
	panel.anchor_left = 0.0
	panel.anchor_right = 0.0
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = 36.0
	panel.offset_right = 36.0 + width_px
	panel.offset_top = -height_px * 0.5
	panel.offset_bottom = height_px * 0.5
	var top := viewport.y * 0.5 + panel.offset_top
	if top < 20.0:
		var shift := 20.0 - top
		panel.offset_top += shift
		panel.offset_bottom += shift


func _menu_box(panel: PanelContainer) -> VBoxContainer:
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 28)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	return box


func _menu_action(host: VBoxContainer, node_name: String, text: String, height: float, callback: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size.y = height
	Identity.apply_button(button, text in ["BEGIN", "NEW REALM", "BEGIN BINDING", "RESUME"])
	button.pressed.connect(func() -> void:
		if audio_director != null:
			audio_director.play_ui_click()
		callback.call()
	)
	host.add_child(button)
	return button


func _show_main_menu_card() -> void:
	menu_card.visible = true
	menu_backdrop.visible = not play_has_begun
	var feedback := menu_card.find_child("FeedbackBundle", true, false) as Button
	if feedback != null:
		feedback.visible = play_has_begun
	var quit_button := menu_card.find_child("QuitGame", true, false) as Button
	if quit_button != null:
		quit_button.text = "SAVE & QUIT" if play_has_begun else "QUIT"
	new_realm_card.visible = false
	settings_card.visible = false
	if continue_button != null and simulation_host.simulation != null:
		continue_button.disabled = not simulation_host.simulation.has_save_file()
	if resume_button != null:
		resume_button.visible = play_has_begun
	if menu_save_button != null:
		menu_save_button.visible = play_has_begun
	_place_start_column(menu_card, 360.0)


func _show_new_realm_card() -> void:
	menu_card.visible = false
	settings_card.visible = false
	new_realm_card.visible = true
	_place_start_column(new_realm_card, 360.0)


func _show_settings_card() -> void:
	menu_card.visible = false
	new_realm_card.visible = false
	settings_card.visible = true
	_place_start_column(settings_card, 380.0)


func _create_result_overlay(root: Control) -> void:
	result_overlay = ColorRect.new()
	result_overlay.name = "ResultOverlay"
	result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_overlay.color = Color(0.02, 0.03, 0.04, 0.55)
	result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	result_overlay.visible = false
	root.add_child(result_overlay)
	var panel := _menu_panel("ResultPanel", Vector2(-260, -250), Vector2(520, 500))
	result_overlay.add_child(panel)
	var box := _menu_box(panel)
	result_title = Label.new()
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Identity.apply_label(result_title, "title")
	result_title.add_theme_font_size_override("font_size", 26)
	box.add_child(result_title)
	result_body = RichTextLabel.new()
	result_body.bbcode_enabled = true
	result_body.fit_content = true
	result_body.scroll_active = true
	result_body.custom_minimum_size.y = 168
	result_body.add_theme_color_override("default_color", Identity.COLOR_NEUTRAL)
	box.add_child(result_body)
	result_more_button = Button.new()
	result_more_button.text = "MORE STATS"
	Identity.apply_button(result_more_button)
	result_more_button.pressed.connect(_toggle_result_stats)
	box.add_child(result_more_button)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
	box.add_child(actions)
	var try_again := Button.new()
	try_again.name = "TryAgain"
	try_again.text = "TRY AGAIN"
	Identity.apply_button(try_again, true)
	try_again.pressed.connect(_try_again)
	actions.add_child(try_again)
	var new_realm := Button.new()
	new_realm.name = "ResultNewRealm"
	new_realm.text = "NEW REALM"
	Identity.apply_button(new_realm, true)
	new_realm.pressed.connect(_result_new_realm)
	actions.add_child(new_realm)
	var main_menu := Button.new()
	main_menu.name = "ResultMainMenu"
	main_menu.text = "MAIN MENU"
	Identity.apply_button(main_menu)
	main_menu.pressed.connect(_result_main_menu)
	actions.add_child(main_menu)


func _create_binding_confirm(root: Control) -> void:
	confirm_overlay = ColorRect.new()
	confirm_overlay.name = "BindingConfirm"
	confirm_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confirm_overlay.color = Color(0.02, 0.03, 0.05, 0.55)
	confirm_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	confirm_overlay.visible = false
	root.add_child(confirm_overlay)
	var panel := _menu_panel("BindingPanel", Vector2(-220, -140), Vector2(440, 260))
	confirm_overlay.add_child(panel)
	var box := _menu_box(panel)
	var title := Label.new()
	title.text = "BEGIN SHARD BINDING"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Identity.apply_label(title, "wyrd")
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)
	var warning := Label.new()
	warning.text = "The Wyrd will react violently.\nRequires an operational Shard Outpost and 12 Wyrd."
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Identity.apply_label(warning, "caption")
	box.add_child(warning)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var confirm := Button.new()
	confirm.text = "BEGIN BINDING"
	Identity.apply_button(confirm, true)
	confirm.pressed.connect(_confirm_binding)
	row.add_child(confirm)
	var cancel := Button.new()
	cancel.text = "NOT YET"
	Identity.apply_button(cancel)
	cancel.pressed.connect(func() -> void: confirm_overlay.visible = false)
	row.add_child(cancel)


func _prompt_binding() -> void:
	if confirm_overlay != null:
		confirm_overlay.visible = true


func _confirm_binding() -> void:
	if confirm_overlay != null:
		confirm_overlay.visible = false
	if simulation_host.simulation == null:
		return
	var result: Dictionary = simulation_host.simulation.request_begin_binding()
	_show_command_result(result)


func _show_result_screen() -> void:
	if result_overlay == null or simulation_host.simulation == null:
		return
	simulation_host.paused = true
	last_result_stats = simulation_host.simulation.get_run_statistics()
	result_more_stats = false
	_refresh_result_body()
	var try_again := result_overlay.find_child("TryAgain", true, false) as Button
	if try_again != null:
		try_again.visible = not bool(last_result_stats.get("victory", false))
	result_overlay.visible = true
	_set_play_chrome_visible(false)
	if simulation_host.simulation != null and world_view != null and camera_rig != null:
		simulation_host.simulation._reveal_radius(simulation_host.simulation.shard_position, 7)
		world_view.last_revealed_count = -1
		_sync_presentation()
		camera_rig.compose_view(world_view.tile_to_world(Vector2(simulation_host.simulation.shard_position)), 42.0)
	_update_day_night_lighting()


func _toggle_result_stats() -> void:
	result_more_stats = not result_more_stats
	_refresh_result_body()


func _refresh_result_body() -> void:
	var stats := last_result_stats
	var won := bool(stats.get("victory", false))
	result_title.text = "SHARD BOUND\nREALM SECURED" if won else "THE REALM HAS FALLEN"
	var minutes := int(float(stats.get("elapsed_seconds", 0.0)) / 60.0)
	var seconds := int(float(stats.get("elapsed_seconds", 0.0))) % 60
	var lines: Array[String] = [
		"" if won else "[color=#e37b6a]%s[/color]" % String(stats.get("defeat_reason", "")),
		"Days survived  %d" % int(stats.get("days_survived", 0)),
		"Population  %d" % int(stats.get("population", 0)),
		"Wyrd extracted  %d" % int(stats.get("wyrd_extracted", 0)),
		"Enemies defeated  %d" % int(stats.get("enemies_defeated", 0)),
		"Settlers lost  %d" % int(stats.get("workers_lost", 0)),
		"Completion time  %d:%02d" % [minutes, seconds],
	]
	if result_more_stats:
		lines.append_array([
			"",
			"Peak population  %d" % int(stats.get("peak_population", 0)),
			"Buildings constructed  %d" % int(stats.get("buildings_completed", 0)),
			"Highest Pressure  %s" % String(stats.get("pressure_band", "")),
			"Territory revealed  %d" % int(stats.get("territory_revealed", 0))
		])
	result_body.text = "\n".join(lines)
	if result_more_button != null:
		result_more_button.text = "FEWER STATS" if result_more_stats else "MORE STATS"


func _try_again() -> void:
	result_overlay.visible = false
	start_new_3d(last_run_seed)


func _result_new_realm() -> void:
	result_overlay.visible = false
	_show_start_menu()
	_show_new_realm_card()


func _result_main_menu() -> void:
	result_overlay.visible = false
	_show_start_menu()
	_show_main_menu_card()


func _start_from_menu() -> void:
	var entered := seed_edit.text.strip_edges() if seed_edit != null else ""
	var seed_value := int(entered) if entered.is_valid_int() else int(Time.get_unix_time_from_system()) % 2147483647
	_start_menu_seed(seed_value)


func _start_menu_seed(seed_value: int) -> void:
	if play_has_begun and not simulation_host.simulation.game_finished:
		if not simulation_host.save_to_path(PREVIOUS_REALM_PATH):
			_show_status("Cannot preserve the previous realm. " + simulation_host.simulation.get_last_message(), 8.0)
			return
	_apply_menu_quality()
	start_new_3d(seed_value)
	if not simulation_host.simulation.save_to_path(Simulation.AUTOSAVE_PATH):
		_show_status(simulation_host.simulation.get_last_message(), 8.0)


func _start_review_seed() -> void:
	_start_menu_seed(DEFAULT_SEED)


func _apply_menu_quality() -> void:
	if quality_select == null:
		return
	apply_quality_profile(String(quality_select.get_selected_metadata()))


func apply_quality_profile(profile_name: String) -> void:
	quality_profile = QualityProfile.get_profile(profile_name)
	get_viewport().msaa_3d = Viewport.MSAA_2X if bool(quality_profile.get("shadows", true)) else Viewport.MSAA_DISABLED
	if sun_light != null:
		sun_light.shadow_enabled = bool(quality_profile.get("shadows", true))
		sun_light.light_angular_distance = 0.0
		_apply_sun_shadow_settings(sun_light)
	_apply_quality_features()
	if world_view != null:
		world_view.apply_quality_profile(quality_profile)


func _show_start_menu() -> void:
	if startup_overlay == null:
		return
	if play_has_begun and camera_rig != null:
		play_camera_focus = camera_rig.target_position
		play_camera_zoom = camera_rig.target_zoom
	startup_overlay.visible = true
	_show_main_menu_card()
	_set_play_chrome_visible(false)
	simulation_host.paused = true
	world_view.set_presentation_paused(true)
	camera_rig.input_enabled = false
	_sync_speed_controls()
	_author_title_composition()
	_update_day_night_lighting()
	call_deferred("_place_start_column", menu_card, 360.0)


func _apply_window_title() -> void:
	DisplayServer.window_set_title("Shard & Sovereign")


func _hide_start_menu() -> void:
	if startup_overlay != null:
		startup_overlay.visible = false
	_set_play_chrome_visible(true)
	if world_view != null:
		world_view.set_presentation_paused(false)
	if camera_rig != null:
		camera_rig.input_enabled = true
	_sync_speed_controls()
	play_has_begun = true


func _resume_from_menu() -> void:
	if camera_rig != null and play_has_begun:
		camera_rig.compose_view(play_camera_focus, play_camera_zoom)
	_hide_start_menu()
	simulation_host.paused = false
	if world_view != null:
		world_view.set_presentation_paused(false)


func _author_title_composition() -> void:
	if simulation_host.simulation == null or world_view == null or camera_rig == null:
		return
	var simulation = simulation_host.simulation
	if not play_has_begun:
		var town_tile: Vector2i = simulation.town_hall_position
		var shard_tile: Vector2i = simulation.shard_position
		simulation._reveal_radius(town_tile, 6)
		for step in 12:
			var sample: Vector2 = Vector2(town_tile).lerp(Vector2(shard_tile), float(step) / 12.0)
			simulation._reveal_radius(Vector2i(roundi(sample.x), roundi(sample.y)), 2)
		simulation._reveal_radius(shard_tile, 4)
		world_view.last_revealed_count = -1
		_sync_presentation()
	var town: Vector3 = world_view.tile_to_world(Vector2(simulation.town_hall_position) + Vector2(1.5, 1.5))
	var shard: Vector3 = world_view.tile_to_world(Vector2(simulation.shard_position))
	camera_rig.compose_view(town.lerp(shard, 0.34), 48.0)


func _set_play_chrome_visible(value: bool) -> void:
	if hud_root == null:
		return
	for chrome_name in ["TopBar", "LoopBar", "ProvinceMinimap", "NoticeFeed"]:
		var chrome := hud_root.find_child(chrome_name, true, false)
		if chrome != null:
			chrome.visible = value


func _create_audio() -> void:
	audio_director = AudioDirector.new()
	audio_director.name = "AudioDirector"
	audio_root.add_child(audio_director)
	audio_director.setup(audio_root, camera_rig.camera if camera_rig != null else null)


func _process_audio_events() -> void:
	if simulation_host.simulation == null:
		return
	for event_name in simulation_host.simulation.consume_audio_events():
		if audio_director != null:
			audio_director.handle_sim_event(String(event_name))
		elif audio_players.has(event_name):
			(audio_players[event_name] as AudioStreamPlayer).play()


func _tick_audio(delta: float) -> void:
	if audio_director == null:
		return
	var menu_visible := startup_overlay != null and startup_overlay.visible
	var result_visible := result_overlay != null and result_overlay.visible
	audio_director.tick(simulation_host.simulation, delta, menu_visible, result_visible, simulation_host.paused)
	work_audio_elapsed += delta
	if work_audio_elapsed < 2.6 or menu_visible or camera_rig == null:
		return
	work_audio_elapsed = 0.0
	if camera_rig.target_zoom >= ProductionIsometricCameraRig3D.STRATEGIC_ZOOM - 4.0:
		return
	for snapshot_value in current_frame_snapshot.get("buildings", []):
		var snapshot: Dictionary = snapshot_value
		if not bool(snapshot.get("production_active", false)):
			continue
		var type_name := String(snapshot.get("type", ""))
		if type_name not in ["LUMBER_CAMP", "SAWMILL", "QUARRY", "FARM", "BAKERY", "BARRACKS"]:
			continue
		var kind := "chop"
		if type_name == "SAWMILL":
			kind = "saw"
		elif type_name not in ["LUMBER_CAMP"]:
			kind = "hammer"
		audio_director.play_work_at(world_view.tile_to_world(Vector2(snapshot.get("center", Vector2.ZERO))), kind)
		break


func _update_day_night_lighting() -> void:
	if environment_resource == null or sun_light == null:
		return
	var menu_visible := startup_overlay != null and startup_overlay.visible
	_apply_lighting_palette(Identity.palette_for_cycle(simulation_host.simulation if simulation_host != null else null, menu_visible))


func _apply_quality_features() -> void:
	if environment_resource == null:
		return
	var night := simulation_host != null and simulation_host.simulation != null and bool(simulation_host.simulation.is_night)
	var want_ssao := bool(quality_profile.get("ssao", quality_profile.get("shadows", true)))
	# The Director: night drops SSAO. Very-Low still left lavapipe 1 ms
	# over the +15% GFX-1 guard; windows/moon carry night form instead.
	environment_resource.ssao_enabled = want_ssao and not night
	environment_resource.ssao_radius = 0.95
	environment_resource.ssao_intensity = 1.05
	environment_resource.ssao_detail = 0.50
	environment_resource.ssao_sharpness = 0.35
	environment_resource.ssao_light_affect = 0.10
	RenderingServer.environment_set_ssao_quality(
		RenderingServer.ENV_SSAO_QUALITY_LOW,
		true,
		0.5,
		2,
		50.0,
		300.0
	)
	environment_resource.ssil_enabled = bool(quality_profile.get("ssil", false))
	environment_resource.glow_enabled = bool(quality_profile.get("glow", false))
	environment_resource.volumetric_fog_enabled = bool(quality_profile.get("volumetric_fog", false))


func _apply_sun_shadow_settings(light: DirectionalLight3D) -> void:
	# The Director: keep GFX-05's 2-split key, but park the cascade seam
	# past the settlement and bias the flats so panning does not stripe.
	if light == null:
		return
	light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	light.directional_shadow_blend_splits = true
	light.directional_shadow_split_1 = 0.82
	light.directional_shadow_max_distance = float(quality_profile.get("shadow_distance", 48.0))
	light.directional_shadow_fade_start = 0.86
	light.directional_shadow_pancake_size = 4.0
	light.shadow_bias = 0.06
	light.shadow_normal_bias = 1.6


func sun_light_direction() -> Vector3:
	if sun_light == null:
		return Vector3.DOWN
	return -sun_light.global_transform.basis.z.normalized()


func camera_view_direction() -> Vector3:
	if camera_rig == null:
		return Vector3(0.0, -0.707, -0.707)
	return camera_rig.view_direction()


func sun_camera_angle_degrees() -> float:
	return rad_to_deg(acos(clampf(sun_light_direction().dot(camera_view_direction()), -1.0, 1.0)))


func _apply_lighting_palette(palette: Dictionary) -> void:
	if environment_resource == null or sun_light == null:
		return
	# Keep lane tint near-neutral so dusk cannot paint an orange carpet.
	var sun_color: Color = palette.get("sun_color", Color.WHITE)
	var road_tint := Color(0.94, 0.94, 0.93).lerp(sun_color.lerp(Color.WHITE, 0.72), 0.16)
	road_tint.a = 1.0
	ProductionRoadView3D.set_lighting(road_tint, float(palette.get("road_lift", 0.06)))
	environment_resource.ambient_light_energy = float(palette.get("ambient", 0.5))
	environment_resource.ambient_light_color = palette.get("ambient_color", palette.get("fill_color", Color("#718FA3")))
	environment_resource.fog_density = float(palette.get("fog_density", 0.0))
	environment_resource.fog_light_color = palette.get("fog_color", Color("#607681"))
	environment_resource.fog_light_energy = float(palette.get("fog_energy", 0.55))
	environment_resource.fog_aerial_perspective = float(palette.get("fog_aerial", 0.55))
	environment_resource.fog_sun_scatter = float(palette.get("fog_sun_scatter", 0.25))
	environment_resource.fog_depth_begin = float(palette.get("fog_begin", 28.0))
	environment_resource.fog_depth_end = float(palette.get("fog_end", 65.0))
	environment_resource.fog_height = 0.0
	environment_resource.fog_height_density = 0.0
	environment_resource.adjustment_saturation = float(palette.get("saturation", 0.94))
	environment_resource.adjustment_contrast = float(palette.get("contrast", 1.0))
	environment_resource.adjustment_brightness = float(palette.get("brightness", 1.0))
	environment_resource.tonemap_exposure = float(palette.get("exposure", 1.0))
	environment_resource.tonemap_white = float(palette.get("tonemap_white", 8.0))
	environment_resource.adjustment_color_correction = Identity.grade_lut_for(String(palette.get("grade", "day")))
	_apply_quality_features()
	sun_light.light_energy = float(palette.get("sun_energy", 1.1))
	sun_light.light_color = palette.get("sun_color", Color("#FFD09A"))
	var camera_yaw := rad_to_deg(camera_rig.rotation.y) if camera_rig != null else -35.5
	var orbit := float(palette.get("sun_orbit", 120.0))
	sun_light.rotation_degrees = Vector3(float(palette.get("sun_pitch", -25.0)), camera_yaw - orbit, 0.0)
	if fill_light != null:
		fill_light.light_energy = float(palette.get("fill_energy", 0.18))
		fill_light.light_color = palette.get("fill_color", Color("#7A93A6"))
		fill_light.rotation_degrees = Vector3(-36.0, camera_yaw - orbit + 180.0, 0.0)
	if sky_material != null:
		sky_material.sky_top_color = palette.get("sky_top", Color("#3E5A68"))
		sky_material.sky_horizon_color = palette.get("sky_horizon", Color("#C4A882"))
		sky_material.ground_bottom_color = palette.get("ground_bottom", Color("#14241E"))
		sky_material.ground_horizon_color = palette.get("ground_horizon", Color("#2E4036"))
	if world_view != null:
		world_view.apply_light_palette(palette)


func _show_command_result(result: Dictionary) -> void:
	_show_status(String(result.get("message", "Command unavailable.")), 3.0)


func _show_status(message: String, seconds := 2.5) -> void:
	status_message_text = message
	if status_label != null:
		status_label.text = message
	status_message_until = Time.get_ticks_msec() / 1000.0 + seconds


func _copy_debug_info() -> void:
	if simulation_host.simulation == null:
		return
	var simulation = simulation_host.simulation
	var metrics := world_view.presentation_metrics()
	var info := "Shards & Sovereign Phase 4\nBuild: One Shard playable core\nSeed: %d\nDay/time: %s\nPopulation: %d/%d\nHungry: %d\nEntities: workers %d, enemies %d\nPresentation: %s\nSave schema: 8" % [
		simulation.rng_seed,
		simulation.get_time_label(),
		simulation.population_current,
		simulation.housing_capacity,
		simulation.hungry_population,
		simulation.workers.size(),
		simulation.enemies.size(),
		JSON.stringify(metrics),
	]
	DisplayServer.clipboard_set(info)
	_show_status("Debug info copied to clipboard.", 3.0)


func _return_to_legacy_2d() -> void:
	get_tree().change_scene_to_file("res://src/GodotClient/Scenes/main.tscn")


func _pointer_over_ui() -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	return hovered != null and hovered.mouse_filter != Control.MOUSE_FILTER_IGNORE


func _panel_style(_background: Color, _border: Color) -> StyleBox:
	# T-SNS-UI: every HUD panel uses the stone-and-gold frame.
	return HudSkin.frame("panel")


## Look lift pressure-chip rule: hidden while the realm is QUIET by day with
## no hostiles; shown for any higher band, at night, or during a raid.
func _pressure_chip_should_show(band: String, night: bool, hostiles: int) -> bool:
	if not play_has_begun:
		return false
	return night or hostiles > 0 or not String(band).to_upper().contains("QUIET")


## Look lift clock: "Day 3" / "Night 3" on top, "Night in 4:12" underneath
## (the game has no seasons; the next phase is what the player plans for).
func _clock_title() -> String:
	var sim = simulation_host.simulation
	if sim == null:
		return ""
	return "%s %d" % ["Night" if bool(sim.is_night) else "Day", int(sim.day_count)]


func _phase_countdown_text() -> String:
	var sim = simulation_host.simulation
	if sim == null:
		return ""
	var night := bool(sim.is_night)
	var length := float(sim.NIGHT_LENGTH_SECONDS if night else sim.DAY_LENGTH_SECONDS)
	var remaining := maxi(0, int(ceil(length - float(sim.phase_time))))
	return "%s in %d:%02d" % ["Dawn" if night else "Night", remaining / 60, remaining % 60]


## Look lift: a navy capsule (gold hairline) in the top bar; returns the row
## that holds the capsule's content.
func _top_capsule(host: HBoxContainer, node_name: String) -> HBoxContainer:
	var capsule := PanelContainer.new()
	capsule.name = node_name
	capsule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capsule.size_flags_vertical = Control.SIZE_FILL
	var style := HudSkin.frame("capsule", 4.0)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 1.0
	style.content_margin_bottom = 1.0
	capsule.add_theme_stylebox_override("panel", style)
	host.add_child(capsule)
	var row := HBoxContainer.new()
	row.name = "Row"
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capsule.add_child(row)
	return row


## Small dim hotkey badge pinned to the top-right corner of a control.
func _attach_hotkey_badge(host: Control, text: String) -> Label:
	var badge := HudSkin.hotkey_badge(text)
	badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	badge.offset_left = -14.0
	badge.offset_right = 1.0
	badge.offset_top = -3.0
	badge.offset_bottom = 12.0
	badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	host.add_child(badge)
	return badge


func _add_resource_chip(host: HBoxContainer, key: String, caption: String) -> Label:
	# T-SNS-UI: real icon, readable amount and a live rate per minute
	# (Look lift: the rate sits underneath the value).
	var cell := PanelContainer.new()
	cell.name = "Chip_%s" % key
	cell.tooltip_text = caption
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	cell.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(row)
	row.add_child(HudSkin.icon_rect(key, 24.0))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", -4)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.custom_minimum_size.x = 38.0
	row.add_child(stack)
	var value := Label.new()
	value.name = "Value"
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	HudSkin.set_font(value, HudSkin.ui_font(700), HudSkin.SIZE_VALUE, Identity.COLOR_WYRD if key == "wyrd" else Color("#f6eed6"))
	stack.add_child(value)
	var rate := Label.new()
	rate.name = "Rate"
	rate.text = ""
	rate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	HudSkin.set_font(rate, HudSkin.ui_font(600), HudSkin.SIZE_MIN, HudSkin.COLOR_GAIN)
	stack.add_child(rate)
	resource_rate_labels[key] = rate
	host.add_child(cell)
	return value


func _add_top_stat(host: HBoxContainer, node_name: String, icon_key: String, tip: String) -> Label:
	var cell := HBoxContainer.new()
	cell.name = node_name + "Cell"
	cell.add_theme_constant_override("separation", 4)
	cell.tooltip_text = tip
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	cell.add_child(HudSkin.icon_rect(icon_key, 24.0))
	var stack := VBoxContainer.new()
	stack.name = node_name + "Stack"
	stack.add_theme_constant_override("separation", -4)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.custom_minimum_size.x = 44.0
	cell.add_child(stack)
	var label := Label.new()
	label.name = node_name
	label.tooltip_text = tip
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	HudSkin.set_font(label, HudSkin.ui_font(700), HudSkin.SIZE_VALUE, Color("#f6eed6"))
	stack.add_child(label)
	host.add_child(cell)
	return label


## Idle free workers: settlers with no workplace, clearing order or road job.
func idle_worker_count() -> int:
	var sim = simulation_host.simulation
	if sim == null:
		return 0
	return maxi(0, int(sim.workers_free()) - int(sim._clearer_count()))


## Look lift: the idle count is a sub-label of the population group (it used
## to float above the console). Clicking it still opens the BUILD plans.
func _add_idle_workers_button(host: Control) -> Button:
	var button := Button.new()
	button.name = "IdleWorkers"
	button.text = "0 idle"
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var box := StyleBoxEmpty.new()
		button.add_theme_stylebox_override(state, box)
	HudSkin.set_font(button, HudSkin.ui_font(700), HudSkin.SIZE_MIN, Color("#ffcf7a"))
	button.add_theme_color_override("font_hover_color", HudSkin.COLOR_GOLD)
	button.add_theme_color_override("font_outline_color", HudSkin.COLOR_OUTLINE)
	button.add_theme_constant_override("outline_size", 2)
	button.pressed.connect(_on_idle_workers_pressed)
	button.visible = false
	host.add_child(button)
	return button


func _on_idle_workers_pressed() -> void:
	# Idle settlers only get work from a new workplace: open the BUILD plans.
	_set_build_palette_visible(true)


func _update_idle_workers() -> void:
	var idle := idle_worker_count()
	if idle_workers_button != null:
		idle_workers_button.text = "%d idle" % idle
		# Hidden at night: settlers shelter then, so "idle" would be noise mid-raid.
		idle_workers_button.visible = idle > 0 and play_has_begun and not bool(simulation_host.simulation.is_night) and (startup_overlay == null or not startup_overlay.visible)
		if population_label != null:
			population_label.get_parent().get_parent().tooltip_text = "Population / housing" + ("\n%d idle: click to open Build" % idle if idle_workers_button.visible else "")
		idle_workers_button.tooltip_text = "%d free worker%s without a job. Click to open BUILD: each workplace (Lumber Camp, Quarry, Farm, Sawmill, Bakery) employs settlers." % [idle, "" if idle == 1 else "s"]
	_tick_idle_workers(idle)


func _tick_idle_workers(idle: int) -> void:
	var sim = simulation_host.simulation
	if sim == null or not play_has_begun or bool(sim.game_finished):
		idle_workers_tracking = false
		return
	var now := float(sim.elapsed_seconds)
	# Workers shelter at night; idle only counts by day.
	if idle <= 0 or bool(sim.is_night):
		idle_workers_tracking = false
		return
	if not idle_workers_tracking or now < idle_workers_since:
		idle_workers_tracking = true
		idle_workers_since = now
		return
	if now - idle_workers_since < IDLE_NOTICE_AFTER_SECONDS:
		return
	if now - idle_notice_last < IDLE_NOTICE_COOLDOWN_SECONDS and now >= idle_notice_last:
		return
	idle_notice_last = now
	_push_notice_feed("Idle workers", "%d settler%s been idle for %ds. Build a Lumber Camp, Quarry or Farm to put them to work." % [idle, " has" if idle == 1 else "s have", int(now - idle_workers_since)], "warning")


func _hud_divider() -> Control:
	var line := ColorRect.new()
	line.color = Color(0.77, 0.59, 0.33, 0.45)
	line.custom_minimum_size = Vector2(1, 26)
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


## Samples central stock against simulation time and shows the net change per
## minute over the last RATE_WINDOW_SECONDS next to each resource.
func _update_resource_rates(chip_values: Dictionary) -> void:
	if simulation_host.simulation == null:
		return
	var now := float(simulation_host.simulation.elapsed_seconds)
	if resource_rate_history.is_empty() or now - float(resource_rate_history[-1].get("t", 0.0)) >= 1.0 or now < float(resource_rate_history[-1].get("t", 0.0)):
		if not resource_rate_history.is_empty() and now < float(resource_rate_history[-1].get("t", 0.0)):
			resource_rate_history.clear()
		resource_rate_history.append({"t": now, "v": chip_values.duplicate()})
		while resource_rate_history.size() > 2 and now - float(resource_rate_history[0].get("t", 0.0)) > RATE_WINDOW_SECONDS:
			resource_rate_history.pop_front()
	var oldest: Dictionary = resource_rate_history[0]
	var span := now - float(oldest.get("t", now))
	for key in resource_rate_labels:
		var rate_label: Label = resource_rate_labels[key]
		if span < 8.0:
			rate_label.text = ""
			continue
		var per_minute := (float(chip_values.get(key, 0)) - float(Dictionary(oldest.get("v", {})).get(key, 0))) / span * 60.0
		if absf(per_minute) < 0.5:
			rate_label.text = ""
		else:
			rate_label.text = "%+d/min" % roundi(per_minute)
			rate_label.add_theme_color_override("font_color", HudSkin.COLOR_GAIN if per_minute > 0.0 else HudSkin.COLOR_LOSS)
		var chip := rate_label.get_parent().get_parent().get_parent() as Control
		if chip != null:
			chip.tooltip_text = "%s: %d in store%s" % [key.capitalize(), int(chip_values.get(key, 0)), ("\nNet %s per minute (last %ds)" % [rate_label.text.trim_suffix("/min"), int(span)]) if rate_label.text != "" else ""]


func _add_volume_slider(host: VBoxContainer, caption: String, value: float) -> HSlider:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = caption
	label.custom_minimum_size.x = 72.0
	Identity.apply_label(label, "caption")
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_volume_changed)
	row.add_child(slider)
	host.add_child(row)
	return slider


func _on_volume_changed(_value: float = 0.0) -> void:
	if audio_director == null:
		return
	audio_director.apply_settings({
		"master": master_slider.value if master_slider != null else 1.0,
		"music": music_slider.value if music_slider != null else 0.72,
		"sfx": sfx_slider.value if sfx_slider != null else 0.85
	})


func _set_fullscreen(enabled: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)
	_save_display_settings()


func _save_display_settings() -> void:
	var settings := ConfigFile.new()
	settings.set_value("display", "fullscreen", fullscreen_check.button_pressed)
	settings.set_value("display", "quality", String(quality_select.get_selected_metadata()))
	settings.save(DISPLAY_SETTINGS_PATH)


func _restore_display_settings() -> void:
	var settings := ConfigFile.new()
	if settings.load(DISPLAY_SETTINGS_PATH) != OK:
		return
	var low := String(settings.get_value("display", "quality", "recommended")) == "scalable_low"
	quality_select.select(1 if low else 0)
	_apply_menu_quality()
	fullscreen_check.set_pressed_no_signal(bool(settings.get_value("display", "fullscreen", false)))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_check.button_pressed else DisplayServer.WINDOW_MODE_WINDOWED)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_request_quit()


func _request_quit() -> void:
	if play_has_begun and simulation_host.simulation != null:
		if not save_game():
			var warning := AcceptDialog.new()
			warning.title = "Your realm could not be saved"
			warning.dialog_text = simulation_host.simulation.get_last_message() + "\nThe game will stay open so you can retry."
			add_child(warning)
			warning.confirmed.connect(warning.queue_free)
			warning.popup_centered(Vector2i(520, 180))
			return
	get_tree().quit()


func _export_feedback() -> void:
	var folder := "user://feedback/%s" % Time.get_datetime_string_from_system().replace(":", "-")
	if DirAccess.make_dir_recursive_absolute(folder) != OK:
		_show_status("Could not create the feedback folder.", 5.0)
		return
	if simulation_host.simulation != null:
		simulation_host.save_to_path(folder + "/realm.json")
	for path in [Simulation.RUN_JOURNAL_PATH, Simulation.RUN_JOURNAL_PATH + ".previous", "user://logs/godot.log"]:
		if FileAccess.file_exists(path):
			DirAccess.copy_absolute(path, folder + "/" + path.get_file())
	var report := FileAccess.open(folder + "/report.txt", FileAccess.WRITE)
	if report != null:
		report.store_string("Shard & Sovereign playtest\nVersion: %s\nEngine: %s\nOS: %s\nGPU: %s\nQuality: %s\nSeed: %s\n\nWhat happened?\nWhat did you expect?\nHow can we reproduce it?\n" % [ProjectSettings.get_setting("application/config/version"), Engine.get_version_info().string, OS.get_name(), RenderingServer.get_video_adapter_name(), quality_select.get_selected_metadata(), last_run_seed])
		report.close()
	_show_status("Feedback report saved. Add a description before sharing it.", 5.0)
	OS.shell_open(ProjectSettings.globalize_path(folder))


func _maybe_show_nightfall(wyrdfall: Dictionary) -> void:
	var day := int(simulation_host.simulation.day_count)
	if day == last_nightfall_day:
		return
	last_nightfall_day = day
	var forecast: Dictionary = wyrdfall.get("forecast", {})
	if nightfall_label != null:
		nightfall_label.text = "DUSK APPROACHES\nThreat: %s   Likely activity: %s" % [
			String(forecast.get("threat", "QUIET")),
			String(forecast.get("activity", "Unknown"))
		]
	# Look lift: no centre pop-ups; dusk is a feed notice so the player can still act.
	_push_notice_feed("Dusk approaches", "Threat: %s  ·  Likely activity: %s" % [String(forecast.get("threat", "QUIET")).capitalize(), String(forecast.get("activity", "Unknown"))], "warning")


func _ghost_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.no_depth_test = true
	return material


func _parse_launch_options() -> Dictionary:
	var options := {"seed": DEFAULT_SEED, "load": false, "fixture": "", "quality": "recommended", "autostart": false, "debug_audio_cycle": false, "debug_ui_scene": "", "debug_quit": false, "evidence_capture": "", "evidence_ui": ""}
	for argument in OS.get_cmdline_user_args():
		if argument == "--load":
			options["load"] = true
		elif argument.begins_with("--seed="):
			options["seed"] = int(argument.trim_prefix("--seed="))
		elif argument.begins_with("--fixture="):
			options["fixture"] = argument.trim_prefix("--fixture=")
		elif argument.begins_with("--quality="):
			options["quality"] = argument.trim_prefix("--quality=")
		elif argument == "--autostart":
			options["autostart"] = true
		elif argument == "--debug-audio-cycle":
			options["debug_audio_cycle"] = true
			options["autostart"] = true
		elif argument.begins_with("--debug-ui-scene="):
			options["debug_ui_scene"] = argument.trim_prefix("--debug-ui-scene=")
			options["autostart"] = true
		elif argument == "--debug-quit-after":
			options["debug_quit"] = true
		elif argument.begins_with("--evidence-capture="):
			options["evidence_capture"] = argument.trim_prefix("--evidence-capture=")
		elif argument.begins_with("--evidence-ui="):
			options["evidence_ui"] = argument.trim_prefix("--evidence-ui=")
			options["autostart"] = true
	return options


func _apply_requested_fixture() -> void:
	fixture_result = DemoFixture.new().apply(simulation_host.simulation, fixture_stage)
	if fixture_stage == "reloaded":
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/phase2/persistence"))
		var saved: bool = simulation_host.save_to_path(FIXTURE_SAVE_PATH)
		var loaded: bool = saved and simulation_host.load_from_path(FIXTURE_SAVE_PATH)
		fixture_result["save_reloaded"] = loaded
	_initialize_presentation()
	var focus_id := 0
	for type_name in [Defs.BUILDING_LUMBER_CAMP, Defs.BUILDING_FARM, Defs.BUILDING_STOREHOUSE, Defs.BUILDING_HOUSE]:
		if Dictionary(fixture_result.get("building_ids", {})).has(type_name):
			focus_id = int(Dictionary(fixture_result.get("building_ids", {}))[type_name])
			break
	if focus_id > 0:
		camera_rig.compose_view(world_view.focus_for_building(focus_id), 30.0)
	if fixture_stage == "placement":
		var candidates: Dictionary = fixture_result.get("placement_candidates", {})
		if candidates.has(Defs.BUILDING_LUMBER_CAMP):
			preview_placement_at(Defs.BUILDING_LUMBER_CAMP, Vector2i(candidates[Defs.BUILDING_LUMBER_CAMP]))
	status_label.text = "Fixture %s: %s" % [fixture_stage, "ready" if bool(fixture_result.get("success", false)) else "; ".join(fixture_result.get("report", []))]


func _building_icon_color(building_type: String) -> Color:
	match building_type:
		Defs.BUILDING_LUMBER_CAMP: return Color("#8b6f47")
		Defs.BUILDING_SAWMILL: return Color("#5a4a3a")
		Defs.BUILDING_QUARRY: return Color("#9a9588")
		Defs.BUILDING_FARM: return Color("#d4b86a")
		Defs.BUILDING_BAKERY: return Color("#c8524a")
		Defs.BUILDING_BARRACKS: return Color("#6a4a4a")
		Defs.BUILDING_WATCHTOWER: return Color("#6a4a4a")
		Defs.BUILDING_HOUSE: return Color("#a99377")
		Defs.BUILDING_STOREHOUSE: return Color("#8a7a5a")
		Defs.BUILDING_LUMEN_PILLAR: return Color("#6bcfe0")
		Defs.BUILDING_OUTPOST: return Color("#8b6f47")
		Defs.BUILDING_ROAD: return Color("#7a6a4a")
		Defs.BUILDING_WALL: return Color("#9a9588")
		Defs.TOOL_CLEAR_AREA: return Color("#597a59")
		_: return Color("#6a6a6a")


func _building_icon_accent(building_type: String) -> Color:
	match building_type:
		Defs.BUILDING_LUMBER_CAMP: return Color("#6b4423")
		Defs.BUILDING_SAWMILL: return Color("#4a3a2a")
		Defs.BUILDING_QUARRY: return Color("#7a7568")
		Defs.BUILDING_FARM: return Color("#c4a850")
		Defs.BUILDING_BAKERY: return Color("#a83830")
		Defs.BUILDING_BARRACKS: return Color("#c84a4a")
		Defs.BUILDING_WATCHTOWER: return Color("#c84a4a")
		Defs.BUILDING_HOUSE: return Color("#779367")
		Defs.BUILDING_STOREHOUSE: return Color("#6a5a3a")
		Defs.BUILDING_LUMEN_PILLAR: return Color("#4bafc0")
		Defs.BUILDING_OUTPOST: return Color("#c8524a")
		Defs.BUILDING_ROAD: return Color("#5a4a2a")
		Defs.BUILDING_WALL: return Color("#7a7568")
		Defs.TOOL_CLEAR_AREA: return Color("#3a5a3a")
		_: return Color("#4a4a4a")


func _create_building_icon_visual(building_type: String) -> Control:
	var canvas := Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var accent_color := _building_icon_accent(building_type)
	match building_type:
		Defs.BUILDING_HOUSE:
			var roof_base := ColorRect.new()
			roof_base.color = accent_color.darkened(0.1)
			roof_base.position = Vector2(14, 8)
			roof_base.size = Vector2(44, 12)
			canvas.add_child(roof_base)
			var roof := ColorRect.new()
			roof.color = accent_color
			roof.position = Vector2(16, 6)
			roof.size = Vector2(40, 10)
			canvas.add_child(roof)
			for i in 3:
				var shingle := ColorRect.new()
				shingle.color = accent_color.darkened(0.05)
				shingle.position = Vector2(18 + i * 14, 10)
				shingle.size = Vector2(12, 2)
				canvas.add_child(shingle)
			var walls := ColorRect.new()
			walls.color = accent_color.darkened(0.2)
			walls.position = Vector2(20, 16)
			walls.size = Vector2(32, 16)
			canvas.add_child(walls)
			var window1 := ColorRect.new()
			window1.color = Color(0.92, 0.76, 0.42, 0.7)
			window1.position = Vector2(24, 19)
			window1.size = Vector2(6, 6)
			canvas.add_child(window1)
			var window2 := ColorRect.new()
			window2.color = Color(0.92, 0.76, 0.42, 0.7)
			window2.position = Vector2(42, 19)
			window2.size = Vector2(6, 6)
			canvas.add_child(window2)
			var door := ColorRect.new()
			door.color = accent_color.darkened(0.45)
			door.position = Vector2(32, 22)
			door.size = Vector2(8, 10)
			canvas.add_child(door)
			var door_detail := ColorRect.new()
			door_detail.color = accent_color.darkened(0.3)
			door_detail.position = Vector2(33, 23)
			door_detail.size = Vector2(3, 8)
			canvas.add_child(door_detail)
		Defs.BUILDING_LUMBER_CAMP:
			var tent := ColorRect.new()
			tent.color = accent_color
			tent.position = Vector2(10, 8)
			tent.size = Vector2(24, 20)
			canvas.add_child(tent)
			for i in 3:
				var log := ColorRect.new()
				log.color = accent_color.darkened(0.3)
				log.position = Vector2(38 + i * 6, 14 + i * 2)
				log.size = Vector2(16, 5)
				canvas.add_child(log)
		Defs.BUILDING_SAWMILL:
			var building := ColorRect.new()
			building.color = accent_color.darkened(0.3)
			building.position = Vector2(8, 14)
			building.size = Vector2(24, 18)
			canvas.add_child(building)
			var roof := ColorRect.new()
			roof.color = accent_color.darkened(0.15)
			roof.position = Vector2(6, 10)
			roof.size = Vector2(28, 6)
			canvas.add_child(roof)
			var window := ColorRect.new()
			window.color = Color(0.92, 0.76, 0.42, 0.5)
			window.position = Vector2(14, 18)
			window.size = Vector2(6, 6)
			canvas.add_child(window)
			var blade_housing := ColorRect.new()
			blade_housing.color = accent_color.darkened(0.2)
			blade_housing.position = Vector2(32, 10)
			blade_housing.size = Vector2(20, 20)
			canvas.add_child(blade_housing)
			var blade := ColorRect.new()
			blade.color = Color(0.68, 0.68, 0.72)
			blade.position = Vector2(36, 6)
			blade.size = Vector2(20, 20)
			canvas.add_child(blade)
			var blade_center := ColorRect.new()
			blade_center.color = Color(0.48, 0.48, 0.52)
			blade_center.position = Vector2(43, 13)
			blade_center.size = Vector2(6, 6)
			canvas.add_child(blade_center)
			for i in 4:
				var tooth := ColorRect.new()
				tooth.color = Color(0.78, 0.78, 0.82)
				tooth.size = Vector2(3, 8)
				match i:
					0: 
						tooth.position = Vector2(44, -2)
						tooth.rotation_degrees = 0
					1: 
						tooth.position = Vector2(58, 14)
						tooth.rotation_degrees = 90
					2: 
						tooth.position = Vector2(44, 26)
						tooth.rotation_degrees = 180
					3: 
						tooth.position = Vector2(30, 14)
						tooth.rotation_degrees = 270
				canvas.add_child(tooth)
			for j in 3:
				var plank := ColorRect.new()
				plank.color = accent_color.lightened(0.1)
				plank.position = Vector2(56 + j * 2, 26)
				plank.size = Vector2(8, 2)
				canvas.add_child(plank)
		Defs.BUILDING_FARM:
			var barn := ColorRect.new()
			barn.color = accent_color.darkened(0.25)
			barn.position = Vector2(8, 10)
			barn.size = Vector2(22, 18)
			canvas.add_child(barn)
			var barn_roof_base := ColorRect.new()
			barn_roof_base.color = accent_color.darkened(0.05)
			barn_roof_base.position = Vector2(6, 6)
			barn_roof_base.size = Vector2(26, 6)
			canvas.add_child(barn_roof_base)
			var barn_roof := ColorRect.new()
			barn_roof.color = accent_color
			barn_roof.position = Vector2(7, 4)
			barn_roof.size = Vector2(24, 6)
			canvas.add_child(barn_roof)
			var barn_door := ColorRect.new()
			barn_door.color = accent_color.darkened(0.4)
			barn_door.position = Vector2(14, 18)
			barn_door.size = Vector2(8, 10)
			canvas.add_child(barn_door)
			for i in 2:
				var shingle := ColorRect.new()
				shingle.color = accent_color.darkened(0.08)
				shingle.position = Vector2(10 + i * 8, 7)
				shingle.size = Vector2(6, 2)
				canvas.add_child(shingle)
			var fence := ColorRect.new()
			fence.color = accent_color.darkened(0.3)
			fence.position = Vector2(32, 14)
			fence.size = Vector2(32, 3)
			canvas.add_child(fence)
			for post in 4:
				var fence_post := ColorRect.new()
				fence_post.color = accent_color.darkened(0.4)
				fence_post.position = Vector2(32 + post * 10, 12)
				fence_post.size = Vector2(2, 7)
				canvas.add_child(fence_post)
			for row in 3:
				var crop_field := ColorRect.new()
				crop_field.color = Color(0.76, 0.62, 0.32, 0.3)
				crop_field.position = Vector2(33 + row * 10, 18)
				crop_field.size = Vector2(8, 12)
				canvas.add_child(crop_field)
				for stalk in 3:
					var wheat := ColorRect.new()
					wheat.color = Color(0.86, 0.75, 0.42)
					wheat.position = Vector2(34 + row * 10 + stalk * 2, 20 + stalk)
					wheat.size = Vector2(1, 8 - stalk)
					canvas.add_child(wheat)
					var grain := ColorRect.new()
					grain.color = Color(0.92, 0.82, 0.52)
					grain.position = Vector2(34 + row * 10 + stalk * 2, 19 + stalk)
					grain.size = Vector2(2, 2)
					canvas.add_child(grain)
		Defs.BUILDING_QUARRY:
			var mine := ColorRect.new()
			mine.color = accent_color.darkened(0.2)
			mine.position = Vector2(12, 12)
			mine.size = Vector2(24, 18)
			canvas.add_child(mine)
			var entrance := ColorRect.new()
			entrance.color = Color.BLACK.lightened(0.2)
			entrance.position = Vector2(18, 18)
			entrance.size = Vector2(12, 12)
			canvas.add_child(entrance)
			for i in 3:
				var rock := ColorRect.new()
				rock.color = accent_color.darkened(i * 0.1)
				rock.position = Vector2(40 + i * 8, 16 - i * 2)
				rock.size = Vector2(10, 10 + i * 2)
				canvas.add_child(rock)
		Defs.BUILDING_BAKERY:
			var building := ColorRect.new()
			building.color = accent_color.darkened(0.25)
			building.position = Vector2(16, 16)
			building.size = Vector2(36, 18)
			canvas.add_child(building)
			var roof := ColorRect.new()
			roof.color = accent_color.darkened(0.1)
			roof.position = Vector2(14, 12)
			roof.size = Vector2(40, 6)
			canvas.add_child(roof)
			var window := ColorRect.new()
			window.color = Color(0.92, 0.76, 0.42, 0.6)
			window.position = Vector2(22, 20)
			window.size = Vector2(6, 6)
			canvas.add_child(window)
			var oven_base := ColorRect.new()
			oven_base.color = accent_color
			oven_base.position = Vector2(34, 18)
			oven_base.size = Vector2(16, 14)
			canvas.add_child(oven_base)
			var oven_opening := ColorRect.new()
			oven_opening.color = Color(0.92, 0.42, 0.22, 0.8)
			oven_opening.position = Vector2(38, 22)
			oven_opening.size = Vector2(8, 8)
			canvas.add_child(oven_opening)
			var oven_glow := ColorRect.new()
			oven_glow.color = Color(0.98, 0.72, 0.32, 0.6)
			oven_glow.position = Vector2(40, 24)
			oven_glow.size = Vector2(4, 4)
			canvas.add_child(oven_glow)
			var chimney_base := ColorRect.new()
			chimney_base.color = accent_color.darkened(0.3)
			chimney_base.position = Vector2(50, 4)
			chimney_base.size = Vector2(10, 14)
			canvas.add_child(chimney_base)
			var chimney := ColorRect.new()
			chimney.color = accent_color.darkened(0.25)
			chimney.position = Vector2(52, 0)
			chimney.size = Vector2(6, 18)
			canvas.add_child(chimney)
			for i in 3:
				var brick := ColorRect.new()
				brick.color = accent_color.darkened(0.35)
				brick.position = Vector2(53, 2 + i * 4)
				brick.size = Vector2(4, 2)
				canvas.add_child(brick)
			var smoke1 := ColorRect.new()
			smoke1.color = Color("#b0b0b0", 0.5)
			smoke1.position = Vector2(54, -6)
			smoke1.size = Vector2(4, 8)
			canvas.add_child(smoke1)
			var smoke2 := ColorRect.new()
			smoke2.color = Color("#c0c0c0", 0.35)
			smoke2.position = Vector2(56, -10)
			smoke2.size = Vector2(6, 6)
			canvas.add_child(smoke2)
			var smoke3 := ColorRect.new()
			smoke3.color = Color("#d0d0d0", 0.22)
			smoke3.position = Vector2(60, -12)
			smoke3.size = Vector2(5, 5)
			canvas.add_child(smoke3)
		Defs.BUILDING_BARRACKS:
			var building := ColorRect.new()
			building.color = accent_color.darkened(0.25)
			building.position = Vector2(14, 12)
			building.size = Vector2(34, 20)
			canvas.add_child(building)
			for i in 2:
				var window := ColorRect.new()
				window.color = Color(0.92, 0.76, 0.42, 0.5)
				window.position = Vector2(28 + i * 10, 16)
				window.size = Vector2(4, 6)
				canvas.add_child(window)
			var shield_back := ColorRect.new()
			shield_back.color = accent_color.darkened(0.1)
			shield_back.position = Vector2(16, 10)
			shield_back.size = Vector2(16, 20)
			canvas.add_child(shield_back)
			var shield := ColorRect.new()
			shield.color = accent_color
			shield.position = Vector2(18, 11)
			shield.size = Vector2(12, 18)
			canvas.add_child(shield)
			var shield_boss := ColorRect.new()
			shield_boss.color = accent_color.lightened(0.3)
			shield_boss.position = Vector2(22, 17)
			shield_boss.size = Vector2(4, 4)
			canvas.add_child(shield_boss)
			for j in 2:
				var cross_h := ColorRect.new()
				cross_h.color = accent_color.darkened(0.15)
				cross_h.position = Vector2(20, 14 + j * 6)
				cross_h.size = Vector2(8, 2)
				canvas.add_child(cross_h)
			var spear_shaft := ColorRect.new()
			spear_shaft.color = accent_color.darkened(0.3)
			spear_shaft.position = Vector2(50, 6)
			spear_shaft.size = Vector2(3, 25)
			canvas.add_child(spear_shaft)
			var spear_head := ColorRect.new()
			spear_head.color = Color(0.75, 0.75, 0.75)
			spear_head.position = Vector2(47, 2)
			spear_head.size = Vector2(9, 8)
			canvas.add_child(spear_head)
			var spear_tip := ColorRect.new()
			spear_tip.color = Color(0.85, 0.85, 0.85)
			spear_tip.position = Vector2(49, 0)
			spear_tip.size = Vector2(5, 4)
			canvas.add_child(spear_tip)
			var banner_pole := ColorRect.new()
			banner_pole.color = accent_color.darkened(0.4)
			banner_pole.position = Vector2(56, 8)
			banner_pole.size = Vector2(2, 10)
			canvas.add_child(banner_pole)
			var banner := ColorRect.new()
			banner.color = Color("#c84a4a")
			banner.position = Vector2(58, 10)
			banner.size = Vector2(8, 6)
			canvas.add_child(banner)
		Defs.BUILDING_WATCHTOWER:
			var base := ColorRect.new()
			base.color = accent_color.darkened(0.3)
			base.position = Vector2(24, 20)
			base.size = Vector2(24, 12)
			canvas.add_child(base)
			for i in 3:
				var stone := ColorRect.new()
				stone.color = accent_color.darkened(0.25 + i * 0.05)
				stone.position = Vector2(25 + i * 2, 21 + i)
				stone.size = Vector2(4, 4)
				canvas.add_child(stone)
			var tower := ColorRect.new()
			tower.color = accent_color
			tower.position = Vector2(28, 2)
			tower.size = Vector2(16, 28)
			canvas.add_child(tower)
			for j in 4:
				var brick := ColorRect.new()
				brick.color = accent_color.darkened(0.1)
				brick.position = Vector2(29, 4 + j * 6)
				brick.size = Vector2(14, 2)
				canvas.add_child(brick)
			var window := ColorRect.new()
			window.color = Color(0.92, 0.76, 0.42, 0.6)
			window.position = Vector2(33, 14)
			window.size = Vector2(6, 6)
			canvas.add_child(window)
			var top_left := ColorRect.new()
			top_left.color = accent_color.lightened(0.15)
			top_left.position = Vector2(26, 0)
			top_left.size = Vector2(6, 4)
			canvas.add_child(top_left)
			var top_right := ColorRect.new()
			top_right.color = accent_color.lightened(0.15)
			top_right.position = Vector2(40, 0)
			top_right.size = Vector2(6, 4)
			canvas.add_child(top_right)
			var top_center := ColorRect.new()
			top_center.color = accent_color.lightened(0.1)
			top_center.position = Vector2(32, 0)
			top_center.size = Vector2(8, 3)
			canvas.add_child(top_center)
			var flag_pole := ColorRect.new()
			flag_pole.color = accent_color.darkened(0.4)
			flag_pole.position = Vector2(45, -4)
			flag_pole.size = Vector2(2, 12)
			canvas.add_child(flag_pole)
			var flag := ColorRect.new()
			flag.color = Color("#c84a4a")
			flag.position = Vector2(47, -2)
			flag.size = Vector2(12, 7)
			canvas.add_child(flag)
		Defs.BUILDING_STOREHOUSE:
			var building := ColorRect.new()
			building.color = accent_color.darkened(0.2)
			building.position = Vector2(14, 8)
			building.size = Vector2(36, 22)
			canvas.add_child(building)
			for i in 2:
				for j in 2:
					var crate := ColorRect.new()
					crate.color = accent_color.darkened(0.1 * (i + j))
					crate.position = Vector2(18 + i * 16, 12 + j * 10)
					crate.size = Vector2(12, 8)
					canvas.add_child(crate)
		Defs.BUILDING_LUMEN_PILLAR:
			var base_platform := ColorRect.new()
			base_platform.color = accent_color.darkened(0.3)
			base_platform.position = Vector2(24, 22)
			base_platform.size = Vector2(24, 8)
			canvas.add_child(base_platform)
			var base := ColorRect.new()
			base.color = accent_color.darkened(0.15)
			base.position = Vector2(26, 18)
			base.size = Vector2(20, 12)
			canvas.add_child(base)
			for i in 3:
				var stone_detail := ColorRect.new()
				stone_detail.color = accent_color.darkened(0.2)
				stone_detail.position = Vector2(28 + i * 6, 20)
				stone_detail.size = Vector2(4, 8)
				canvas.add_child(stone_detail)
			var pillar := ColorRect.new()
			pillar.color = accent_color
			pillar.position = Vector2(30, 2)
			pillar.size = Vector2(12, 26)
			canvas.add_child(pillar)
			var glow_outer := ColorRect.new()
			glow_outer.color = accent_color.lightened(0.5)
			glow_outer.position = Vector2(30, 4)
			glow_outer.size = Vector2(12, 14)
			canvas.add_child(glow_outer)
			var glow := ColorRect.new()
			glow.color = accent_color.lightened(0.7)
			glow.position = Vector2(32, 6)
			glow.size = Vector2(8, 10)
			canvas.add_child(glow)
			var core := ColorRect.new()
			core.color = Color(0.92, 0.98, 1.0, 0.9)
			core.position = Vector2(34, 8)
			core.size = Vector2(4, 6)
			canvas.add_child(core)
			for j in 4:
				var ray := ColorRect.new()
				ray.color = accent_color.lightened(0.4 - j * 0.08)
				match j:
					0:
						ray.position = Vector2(20, 10)
						ray.size = Vector2(12, 2)
					1:
						ray.position = Vector2(48, 10)
						ray.size = Vector2(12, 2)
					2:
						ray.position = Vector2(34, -4)
						ray.size = Vector2(4, 8)
					3:
						ray.position = Vector2(34, 18)
						ray.size = Vector2(4, 6)
				canvas.add_child(ray)
			for k in 3:
				var pulse := ColorRect.new()
				pulse.color = accent_color.lightened(0.35)
				pulse.position = Vector2(28 + k * 8, 10 - k * 2)
				pulse.size = Vector2(2, 8 + k * 2)
				canvas.add_child(pulse)
		Defs.BUILDING_ROAD:
			var path := ColorRect.new()
			path.color = accent_color
			path.position = Vector2(8, 14)
			path.size = Vector2(56, 10)
			canvas.add_child(path)
			for i in 4:
				var dash := ColorRect.new()
				dash.color = accent_color.lightened(0.3)
				dash.position = Vector2(10 + i * 14, 17)
				dash.size = Vector2(8, 4)
				canvas.add_child(dash)
		Defs.BUILDING_WALL:
			for i in 3:
				var segment := ColorRect.new()
				segment.color = accent_color
				segment.position = Vector2(14 + i * 16, 8)
				segment.size = Vector2(12, 22)
				canvas.add_child(segment)
				for j in 2:
					var merlon := ColorRect.new()
					merlon.color = accent_color.lightened(0.2)
					merlon.position = Vector2(16 + i * 16 + j * 6, 6)
					merlon.size = Vector2(4, 4)
					canvas.add_child(merlon)
		Defs.BUILDING_OUTPOST:
			var platform_base := ColorRect.new()
			platform_base.color = accent_color.darkened(0.3)
			platform_base.position = Vector2(18, 22)
			platform_base.size = Vector2(36, 10)
			canvas.add_child(platform_base)
			var platform := ColorRect.new()
			platform.color = accent_color.darkened(0.15)
			platform.position = Vector2(20, 20)
			platform.size = Vector2(32, 10)
			canvas.add_child(platform)
			for i in 3:
				var plank := ColorRect.new()
				plank.color = accent_color.darkened(0.2)
				plank.position = Vector2(22 + i * 10, 22)
				plank.size = Vector2(8, 2)
				canvas.add_child(plank)
			var post := ColorRect.new()
			post.color = accent_color
			post.position = Vector2(30, 6)
			post.size = Vector2(12, 24)
			canvas.add_child(post)
			for j in 4:
				var band := ColorRect.new()
				band.color = accent_color.darkened(0.15)
				band.position = Vector2(31, 8 + j * 5)
				band.size = Vector2(10, 2)
				canvas.add_child(band)
			var crystal_holder := ColorRect.new()
			crystal_holder.color = accent_color.darkened(0.2)
			crystal_holder.position = Vector2(32, 2)
			crystal_holder.size = Vector2(8, 6)
			canvas.add_child(crystal_holder)
			var crystal_glow := ColorRect.new()
			crystal_glow.color = Color("#6bcfe0", 0.6)
			crystal_glow.position = Vector2(30, -4)
			crystal_glow.size = Vector2(12, 12)
			canvas.add_child(crystal_glow)
			var crystal := ColorRect.new()
			crystal.color = Color("#6bcfe0")
			crystal.position = Vector2(32, -2)
			crystal.size = Vector2(8, 10)
			canvas.add_child(crystal)
			var crystal_core := ColorRect.new()
			crystal_core.color = Color("#abeef8")
			crystal_core.position = Vector2(34, 0)
			crystal_core.size = Vector2(4, 6)
			canvas.add_child(crystal_core)
			for k in 4:
				var ray := ColorRect.new()
				ray.color = Color("#6bcfe0", 0.4 - k * 0.08)
				match k:
					0:
						ray.position = Vector2(22, 2)
						ray.size = Vector2(10, 2)
					1:
						ray.position = Vector2(48, 2)
						ray.size = Vector2(10, 2)
					2:
						ray.position = Vector2(34, -8)
						ray.size = Vector2(4, 6)
					3:
						ray.position = Vector2(34, 8)
						ray.size = Vector2(4, 4)
				canvas.add_child(ray)
		Defs.TOOL_CLEAR_AREA:
			var tree := ColorRect.new()
			tree.color = Color("#4a6a3a")
			tree.position = Vector2(20, 8)
			tree.size = Vector2(8, 20)
			canvas.add_child(tree)
			var tree_top := ColorRect.new()
			tree_top.color = Color("#3a5a2a")
			tree_top.position = Vector2(16, 6)
			tree_top.size = Vector2(16, 8)
			canvas.add_child(tree_top)
			var slash := ColorRect.new()
			slash.color = Color("#e37b6a")
			slash.position = Vector2(32, 10)
			slash.size = Vector2(24, 4)
			canvas.add_child(slash)
			slash.rotation_degrees = -30
		_:
			var box := ColorRect.new()
			box.color = accent_color
			box.position = Vector2(24, 10)
			box.size = Vector2(24, 18)
			canvas.add_child(box)
	return canvas


func _create_resource_icon(resource_key: String) -> Control:
	# Issue #8: Create visual icons for resources
	var icon := Control.new()
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var color: Color = Identity.RESOURCE_CHIP_COLORS.get(resource_key, Identity.COLOR_NEUTRAL) as Color
	match resource_key:
		"wood":
			var log := ColorRect.new()
			log.color = color
			log.position = Vector2(2, 8)
			log.size = Vector2(16, 6)
			icon.add_child(log)
			var rings := ColorRect.new()
			rings.color = color.darkened(0.3)
			rings.position = Vector2(14, 9)
			rings.size = Vector2(3, 4)
			icon.add_child(rings)
		"planks":
			for i in 3:
				var plank := ColorRect.new()
				plank.color = color.darkened(i * 0.1)
				plank.position = Vector2(3, 6 + i * 4)
				plank.size = Vector2(14, 2)
				icon.add_child(plank)
		"stone":
			var rock := ColorRect.new()
			rock.color = color
			rock.position = Vector2(4, 6)
			rock.size = Vector2(12, 10)
			icon.add_child(rock)
			var highlight := ColorRect.new()
			highlight.color = color.lightened(0.3)
			highlight.position = Vector2(6, 7)
			highlight.size = Vector2(4, 3)
			icon.add_child(highlight)
		"wheat":
			for i in 3:
				var stalk := ColorRect.new()
				stalk.color = color
				stalk.position = Vector2(5 + i * 4, 8)
				stalk.size = Vector2(2, 10)
				icon.add_child(stalk)
				var grain := ColorRect.new()
				grain.color = color.lightened(0.2)
				grain.position = Vector2(4 + i * 4, 6)
				grain.size = Vector2(3, 3)
				icon.add_child(grain)
		"bread":
			var loaf := ColorRect.new()
			loaf.color = color
			loaf.position = Vector2(4, 9)
			loaf.size = Vector2(12, 7)
			icon.add_child(loaf)
			var crust := ColorRect.new()
			crust.color = color.darkened(0.2)
			crust.position = Vector2(5, 8)
			crust.size = Vector2(10, 2)
			icon.add_child(crust)
		"wyrd":
			var crystal := ColorRect.new()
			crystal.color = color
			crystal.position = Vector2(7, 4)
			crystal.size = Vector2(6, 12)
			icon.add_child(crystal)
			var glow := ColorRect.new()
			glow.color = color.lightened(0.5)
			glow.position = Vector2(9, 8)
			glow.size = Vector2(2, 4)
			icon.add_child(glow)
		_:
			var box := ColorRect.new()
			box.color = color
			box.position = Vector2(5, 6)
			box.size = Vector2(10, 10)
			icon.add_child(box)
	return icon


func preview_placement_at(building_type: String, tile: Vector2i) -> void:
	placement_preview_locked = true
	placement_type = building_type
	placement_rotation = 0
	placement_tile = tile
	placement_validation = simulation_host.simulation.validate_placement(building_type, tile, 0)
	var footprint := Defs.building_footprint(building_type)
	var box := BoxMesh.new()
	box.size = Vector3(float(footprint.x) * ScaleProfile.LOGICAL_CELL_METRES, 0.14, float(footprint.y) * ScaleProfile.LOGICAL_CELL_METRES)
	ghost_footprint.mesh = box
	var valid := bool(placement_validation.get("success", false))
	var color := Color(0.26, 0.86, 0.48, 0.42) if valid else Color(0.92, 0.25, 0.22, 0.46)
	ghost_footprint.material_override = _ghost_material(color)
	ghost_access.material_override = _ghost_material(color.lightened(0.18))
	var center := Vector2(tile) + Vector2(footprint - Vector2i.ONE) * 0.5
	placement_ghost.position = world_view.tile_to_world(center) + Vector3.UP * 0.08
	ghost_access.position.z = float(footprint.y) * ScaleProfile.LOGICAL_CELL_METRES * 0.5 + 0.72
	placement_ghost.visible = true
	placement_label.text = "%s · %s footprint and access preview" % ["VALID" if valid else "INVALID", Defs.building_name(building_type)]


## Scripted, deterministic walk through day -> dusk -> night -> night_combat ->
## night -> day so packaged builds can prove the music state machine and the
## monster-kill cheer from logs alone. Never runs without the launch flag.
func _tick_debug_harness(delta: float) -> void:
	var simulation = simulation_host.simulation
	if simulation == null:
		return
	debug_clock += delta
	if debug_ui_scene != "":
		_tick_debug_ui_scene(simulation)
		return
	match debug_stage:
		0:
			if debug_clock >= 4.0:
				_debug_log("stage=dusk")
				simulation.phase_time = float(simulation.DAY_LENGTH_SECONDS) - 50.0
				debug_stage = 1
		1:
			if debug_clock >= 9.0:
				_debug_log("stage=nightfall")
				simulation.day_count = maxi(2, int(simulation.day_count))
				simulation.phase_time = float(simulation.DAY_LENGTH_SECONDS) - 0.05
				debug_stage = 2
		2:
			if debug_clock >= 17.0:
				# A real patrol soldier (survives _sync_production_workers).
				simulation.soldiers_total = int(simulation.soldiers_total) + 1
				simulation._sync_production_workers()
				var guard: Dictionary = {}
				for worker_value in simulation.workers:
					var worker: Dictionary = worker_value
					if String(worker.get("type", "")) == "guard" and int(worker.get("building_id", 0)) == 0:
						guard = worker
				if guard.is_empty():
					_debug_log("stage=engage NO_PATROL_SOLDIER")
					debug_stage = 3
					return
				var guard_tile: Vector2i = simulation.town_hall_position + Vector2i(3, 0)
				guard["position"] = guard_tile
				guard["path"] = []
				simulation._reveal_radius(guard_tile, 6)
				for index in 3:
					simulation._spawn_enemy(guard_tile + Vector2i(1, 0), simulation.GUARD_DAMAGE, 1, 0.0, 0, simulation.ENEMY_RAIDER)
				_debug_log("stage=engage guard=%d at=%s hostiles_spawned=3 hp_each=%d" % [int(guard.get("id", 0)), str(guard_tile), int(simulation.GUARD_DAMAGE)])
				debug_stage = 3
		3:
			if debug_clock >= 28.0:
				_debug_kill_hostiles(simulation, 2, "volley_1")
				debug_stage = 4
		4:
			if debug_clock >= 28.3:
				_debug_kill_hostiles(simulation, 1000, "volley_2")
				debug_stage = 5
		5:
			if debug_clock >= 40.0:
				_debug_log("stage=dawn kills=%d cheers=%d throttled=%d" % [int(simulation.player_monster_kills), int(audio_director.cheers_played), int(audio_director.cheers_throttled)])
				simulation.phase_time = float(simulation.NIGHT_LENGTH_SECONDS) - 0.05
				debug_stage = 6
		6:
			if debug_clock >= 48.0:
				var snapshot: Dictionary = audio_director.evidence_snapshot()
				_debug_log("DONE transitions=%s stems=%s buses=%s kills=%d cheers=%d" % [
					",".join(snapshot.get("transitions", [])), ",".join(snapshot.get("stems", [])),
					JSON.stringify(snapshot.get("buses", {})), int(simulation.player_monster_kills), int(snapshot.get("cheers_played", 0))
				])
				debug_stage = 7
				debug_audio_cycle_active = false
				if audio_director != null:
					audio_director.finish_recording()
				if debug_quit_after:
					get_tree().quit(0)


func _tick_debug_ui_scene(simulation) -> void:
	match debug_ui_scene:
		"outpost_placing":
			if debug_stage == 0 and debug_clock >= 3.0:
				begin_placement(Defs.BUILDING_OUTPOST)
				_debug_log("ui_scene=outpost_placing placement=%s strip_tooltips_suppressed=%s" % [placement_type, str(_strip_tooltips_suppressed())])
				debug_stage = 1
		"night_unafford":
			if debug_stage == 0 and debug_clock >= 3.0:
				simulation.day_count = maxi(1, int(simulation.day_count))
				simulation.phase_time = float(simulation.DAY_LENGTH_SECONDS) - 0.05
				debug_stage = 1
			elif debug_stage == 1 and debug_clock >= 6.0:
				simulation.central_inventory[Defs.RESOURCE_PLANKS] = 8
				begin_placement(Defs.BUILDING_BAKERY)
				_debug_log("ui_scene=night_unafford first placement=%s panel=%s" % [placement_type, str(placement_panel.visible)])
				debug_stage = 2
			elif debug_stage == 2 and debug_clock >= 7.0:
				simulation.central_inventory[Defs.RESOURCE_PLANKS] = 8
				begin_placement(Defs.BUILDING_BARRACKS)
				_debug_log("ui_scene=night_unafford barracks_click placement=%s placement_panel_visible=%s toast_visible=%s toast=%s" % [placement_type, str(placement_panel.visible), str(alert_panel.visible if alert_panel != null else false), toast_body.text if toast_body != null else ""])
				debug_stage = 3
		_:
			pass


## Simulates a Watchtower volley finishing living hostiles through the same kill
## credit path as real bolts (one audio event per frame, cheer throttle applies).
func _debug_kill_hostiles(simulation, limit: int, label: String) -> void:
	var killed := 0
	for enemy_value in simulation.enemies:
		var enemy: Dictionary = enemy_value
		if killed >= limit or int(enemy.get("hp", 0)) <= 0 or bool(enemy.get("retreating", false)):
			continue
		enemy["hp"] = 0
		simulation._note_combat()
		simulation._credit_player_kill(enemy, "tower", 0)
		killed += 1
	_debug_log("stage=%s killed=%d living_left=%d kills_total=%d" % [label, killed, int(simulation.living_hostile_count()), int(simulation.player_monster_kills)])


func _strip_tooltips_suppressed() -> bool:
	_refresh_build_strip_state()
	for btn in build_strip_buttons:
		if String((btn as Button).tooltip_text) != "":
			return false
	return true


func _debug_log(line: String) -> void:
	if audio_director != null and audio_director.record_active:
		print("[%s] t_wav=%.3f DEBUG_HARNESS t=%.2f %s" % [Time.get_datetime_string_from_system(), audio_director.wav_time(), debug_clock, line])
	else:
		print("[%s] DEBUG_HARNESS t=%.2f %s" % [Time.get_datetime_string_from_system(), debug_clock, line])


## Evidence capture for the CoS UI MAJORs. Scene setup is scripted; hover is a
## synthetic InputEventMouseMotion (the OS cursor is never moved) and every image
## is the game's own viewport texture.
func _run_evidence_capture() -> void:
	var dir := evidence_capture_dir
	DirAccess.make_dir_recursive_absolute(dir)
	var simulation = simulation_host.simulation
	var shown_at := get_window().position
	if DisplayServer.get_name() != "headless":
		# Keep the evidence window off the user's desktop: the viewport texture
		# still renders while the window sits outside every screen.
		get_window().position = Vector2i(-6000, -6000)
	_evidence_log("start dir=%s viewport=%s window=%s pos_initial=%s pos_now=%s" % [dir, str(get_viewport().get_visible_rect().size), str(get_window().size), str(shown_at), str(get_window().position)])
	await _evidence_wait(4.0)
	_evidence_hover_point(Vector2(640, 300))
	await _evidence_wait(0.5)
	await _evidence_shot("20_after", "clean autostart: cost line on every strip button, minimap above the strip, Clear visible")
	var outpost_button := _evidence_strip_button(Defs.BUILDING_OUTPOST)
	_evidence_hover_control(outpost_button)
	await _evidence_wait(1.4)
	_evidence_hover_control(outpost_button, Vector2(2, 1))
	await _evidence_wait(1.2)
	await _evidence_shot("44_after_hover_only", "hovering Outpost while not placing: the building tooltip alone (reference)")
	begin_placement(Defs.BUILDING_OUTPOST)
	_evidence_hover_control(outpost_button, Vector2(-2, 0))
	await _evidence_wait(1.4)
	_evidence_hover_control(outpost_button, Vector2(1, 1))
	await _evidence_wait(1.2)
	await _evidence_shot("44_after", "Outpost placement while hovering its button: only the placement hint, tooltip suppressed")
	cancel_placement()
	_evidence_hover_point(Vector2(640, 300))
	simulation.day_count = maxi(1, int(simulation.day_count))
	simulation.phase_time = float(simulation.DAY_LENGTH_SECONDS) - 0.05
	await _evidence_wait(3.0)
	if int(simulation.living_hostile_count()) == 0:
		for index in 3:
			simulation._spawn_enemy(simulation.town_hall_position + Vector2i(9, 7 + index), 30, 1, 0.0, 0, simulation.ENEMY_RAIDER)
	simulation.central_inventory[Defs.RESOURCE_PLANKS] = 8
	simulation.central_inventory[Defs.RESOURCE_STONE] = 10
	# Let the nightfall RAID notice expire on its own so the pre-click frame
	# shows only the stale placement hint.
	for attempt in 120:
		if alert_panel == null or not alert_panel.visible:
			break
		await _evidence_wait(0.1)
	begin_placement(Defs.BUILDING_BAKERY)
	# Point the ghost at the Town Hall footprint so the stale placement hint
	# reads INVALID (the 71 before showed INVALID + resource toast for one click).
	evidence_mouse_override = Vector2(655, 330)
	_evidence_hover_point(evidence_mouse_override)
	_update_placement_ghost(true)
	await _evidence_wait(0.8)
	await _evidence_shot("71_after_pre_click", "night raid, Bakery placement over the Town Hall: stale INVALID placement hint only (frame BEFORE the unaffordable click)")
	var barracks_button := _evidence_strip_button(Defs.BUILDING_BARRACKS)
	_evidence_hover_control(barracks_button)
	simulation.central_inventory[Defs.RESOURCE_PLANKS] = 8
	begin_placement(Defs.BUILDING_BARRACKS)
	evidence_mouse_override = Vector2(-1, -1)
	await _evidence_wait(0.7)
	for attempt in 30:
		if int(Time.get_ticks_msec() / 1000.0 * 4.0) % 2 == 0:
			break
		await get_tree().process_frame
	await _evidence_shot("71_after", "night raid, unaffordable Barracks click: one toast, INVALID hint gone, dimmed buttons, red cost, Planks chip highlighted, RAID badge")
	await _evidence_capture_t009(simulation)
	_evidence_log("done pos=%s" % str(get_window().position))
	if audio_director != null:
		audio_director.finish_recording()
	get_tree().quit(0)


## T-SNS-009 round 3: readable dimmed cost, own Town Hall hover, long INVALID
## hint beside the minimap. Target tiles are picked from the simulation and
## projected through the camera; the OS cursor is never moved.
func _evidence_capture_t009(simulation) -> void:
	cancel_placement()
	evidence_mouse_override = Vector2(-1, -1)
	_evidence_hover_point(Vector2(640, 300))
	for attempt in 120:
		if alert_panel == null or not alert_panel.visible:
			break
		await _evidence_wait(0.1)
	simulation.central_inventory[Defs.RESOURCE_PLANKS] = 8
	simulation.central_inventory[Defs.RESOURCE_STONE] = 10
	await _evidence_wait(0.4)
	var barracks_button := _evidence_strip_button(Defs.BUILDING_BARRACKS)
	var barracks_index := build_strip_types.find(Defs.BUILDING_BARRACKS)
	var barracks_cost: Label = build_strip_cost_labels[barracks_index] if barracks_index >= 0 else null
	_evidence_log("rect name=t009_dimmed_cost barracks_button=%s cost_label=%s cost_text='%s' cost_color=#%s outline=%d container_self_modulate=%s" % [
		str(barracks_button.get_global_rect()) if barracks_button != null else "-",
		str(barracks_cost.get_global_rect()) if barracks_cost != null else "-",
		barracks_cost.text if barracks_cost != null else "",
		barracks_cost.get_theme_color("font_color").to_html(false) if barracks_cost != null else "",
		barracks_cost.get_theme_constant("outline_size") if barracks_cost != null else -1,
		str((build_strip_containers[barracks_index] as Control).self_modulate) if barracks_index >= 0 else "-"])
	await _evidence_shot("t009_dimmed_cost", "not placing, Planks 8 / Stone 10: unaffordable buttons dimmed, cost label full opacity, light red with dark outline")
	simulation.central_inventory[Defs.RESOURCE_WOOD] = 200
	simulation.central_inventory[Defs.RESOURCE_STONE] = 200
	simulation.central_inventory[Defs.RESOURCE_PLANKS] = 200
	begin_placement(Defs.BUILDING_HOUSE)
	var hall_tile: Vector2i = simulation.town_hall_position
	var hall_fp: Vector2i = Defs.building_footprint(Defs.BUILDING_TOWN_HALL)
	var hall_world := world_view.tile_to_world(Vector2(hall_tile) + Vector2(hall_fp - Vector2i.ONE) * 0.5)
	evidence_mouse_override = camera_rig.camera.unproject_position(hall_world)
	_evidence_hover_point(evidence_mouse_override)
	_update_placement_ghost(true)
	await _evidence_wait(0.6)
	_update_placement_ghost(true)
	_evidence_log("rect name=t009_town_hall_hover pointer=%s tile=%s hall=%s panel=%s minimap=%s" % [str(evidence_mouse_override), str(placement_tile), str(hall_tile), str(placement_panel.get_global_rect()), str(minimap.get_global_rect())])
	await _evidence_shot("t009_town_hall_hover", "House placement hovering the player's own Town Hall: names the Town Hall, no road/rival wording")
	var best_tile := Vector2i(-1, -1)
	var best_point := Vector2(-1, -1)
	var best_len := 0
	var view_size := get_viewport().get_visible_rect().size
	for y in range(0, int(simulation.map_size.y), 2):
		for x in range(0, int(simulation.map_size.x), 2):
			var tile := Vector2i(x, y)
			var world_point := world_view.tile_to_world(Vector2(tile))
			if camera_rig.camera.is_position_behind(world_point):
				continue
			var screen_point := camera_rig.camera.unproject_position(world_point)
			if screen_point.x < 120.0 or screen_point.x > view_size.x - 260.0 or screen_point.y < 110.0 or screen_point.y > view_size.y - 380.0:
				continue
			var check: Dictionary = simulation.validate_placement(Defs.BUILDING_HOUSE, tile, 0)
			var message := String(check.get("message", ""))
			if not bool(check.get("success", false)) and message.length() > best_len:
				best_len = message.length()
				best_tile = tile
				best_point = screen_point
	if best_tile.x >= 0:
		evidence_mouse_override = best_point
		_evidence_hover_point(best_point)
		_update_placement_ghost(true)
		await _evidence_wait(0.6)
		_update_placement_ghost(true)
	await get_tree().process_frame
	_evidence_log("rect name=t009_long_invalid_hint pointer=%s tile=%s message_len=%d panel=%s label=%s minimap=%s" % [str(best_point), str(placement_tile), best_len, str(placement_panel.get_global_rect()), str(placement_label.get_global_rect()), str(minimap.get_global_rect())])
	await _evidence_shot("t009_long_invalid_hint", "House placement over the longest INVALID reason on screen: text wraps inside the hint panel, clear of the minimap")
	evidence_mouse_override = Vector2(-1, -1)
	cancel_placement()


## T-SNS-UI: the same four scenes before and after the UI rework (Day 1 start,
## a building selected, the build menu open, night raid pressure). In-engine
## viewport PNGs only; the window is moved offscreen first.
func _run_ui_evidence_capture() -> void:
	var dir := evidence_capture_dir
	DirAccess.make_dir_recursive_absolute(dir)
	var simulation = simulation_host.simulation
	var shown_at := get_window().position
	if DisplayServer.get_name() != "headless":
		get_window().position = Vector2i(-6000, -6000)
	_evidence_log("ui_start dir=%s viewport=%s pos_initial=%s pos_now=%s" % [dir, str(get_viewport().get_visible_rect().size), str(shown_at), str(get_window().position)])
	await _evidence_wait(6.0)
	_evidence_hover_point(Vector2(640, 330))
	await _evidence_wait(0.5)
	await _evidence_shot("ui_01_day1_start", "Day 1 autostart, nothing selected")
	var hall_id := 0
	for building in simulation.buildings:
		if String(building.get("type", "")) == Defs.BUILDING_TOWN_HALL:
			hall_id = int(building.get("id", 0))
	if hall_id > 0:
		select_building(hall_id)
	await _evidence_wait(0.6)
	await _evidence_shot("ui_02_building_selected", "Town Hall selected: inspector / selection panel")
	selected_building_id = 0
	selected_entity_kind = ""
	world_view.set_selection(0, 0)
	_update_inspector()
	_set_build_palette_visible(true)
	var farm_button := _evidence_strip_button(Defs.BUILDING_FARM)
	_evidence_hover_control(farm_button)
	await _evidence_wait(1.4)
	_evidence_hover_control(farm_button, Vector2(2, 1))
	await _evidence_wait(1.2)
	await _evidence_shot("ui_03_build_menu_open", "BUILD menu open, hovering the Farm plan (tooltip with cost)")
	_set_build_palette_visible(false)
	_evidence_hover_point(Vector2(640, 330))
	# T-SNS-UI leftovers (after-only scene): idle-worker notice + top-bar idle count.
	# Time-shift the idle timer (like phase_time below) so the real rule fires now.
	if idle_worker_count() > 0:
		idle_workers_tracking = true
		idle_workers_since = float(simulation.elapsed_seconds) - IDLE_NOTICE_AFTER_SECONDS - 1.0
		idle_notice_last = -1000000.0
		_update_ui()
		await _evidence_wait(0.6)
		await _evidence_shot("ui_06_idle_workers", "Day 1: idle-worker notice in the left feed, idle button above the console")
		for feed_entry in notice_feed_entries:
			if is_instance_valid(feed_entry["node"]):
				(feed_entry["node"] as Node).queue_free()
		notice_feed_entries.clear()
	else:
		_evidence_log("ui_06 skipped: no idle workers")
	simulation.phase_time = float(simulation.DAY_LENGTH_SECONDS) - 0.05
	await _evidence_wait(3.0)
	if int(simulation.living_hostile_count()) == 0:
		for index in 3:
			simulation._spawn_enemy(simulation.town_hall_position + Vector2i(9, 7 + index), 30, 1, 0.0, 0, simulation.ENEMY_RAIDER)
	await _evidence_wait(2.5)
	await _evidence_shot("ui_04_night_raid", "night 1 with raiders alive: pressure indicator, notifications")
	# Extra (after-only) scene: the event LOG open, and the left feed showing
	# this run's own notices (replayed from the real notice log).
	if notice_feed != null and simulation.has_method("get_notice_log"):
		var real_log: Array = simulation.get_notice_log()
		for index in range(maxi(0, real_log.size() - 3), real_log.size()):
			var entry: Dictionary = real_log[index]
			_push_notice_feed(String(entry.get("title", "")), String(entry.get("body", "")), String(entry.get("severity", "info")))
		_evidence_log("ui_05 feed replayed %d real notices" % mini(3, real_log.size()))
	if event_log_panel != null and not event_log_panel.visible:
		_toggle_event_log()
	await _evidence_wait(0.6)
	await _evidence_shot("ui_05_log_and_feed", "event LOG open + notification feed (this run's real notices)")
	_evidence_log("ui_done pos=%s" % str(get_window().position))
	if audio_director != null:
		audio_director.finish_recording()
	get_tree().quit(0)


func _evidence_wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _evidence_strip_button(building_type: String) -> Control:
	var index := build_strip_types.find(building_type)
	if index < 0 or index >= build_strip_buttons.size():
		return null
	return build_strip_buttons[index]


func _evidence_hover_control(control: Control, nudge := Vector2.ZERO) -> void:
	if control == null:
		_evidence_log("hover target missing")
		return
	_evidence_hover_point(control.get_global_rect().get_center() + nudge)


func _evidence_hover_point(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	motion.relative = Vector2(1, 0)
	Input.parse_input_event(motion)
	Input.flush_buffered_events()


func write_gfx_tile_mask_json(path: String) -> void:
	# Sidecar for tools/gfx_pixel_gates.py: every on-screen road tile vs grass two tiles away.
	if world_view == null or camera_rig == null or camera_rig.camera == null or simulation_host == null:
		return
	var sim = simulation_host.simulation
	if sim == null:
		return
	var cam: Camera3D = camera_rig.camera
	var road_set := {}
	for key in sim.connected_roads.keys():
		var parts := String(key).split(",")
		if parts.size() != 2:
			continue
		road_set[Vector2i(int(parts[0]), int(parts[1]))] = true
	for building_value in sim.get_buildings():
		var building: Dictionary = building_value
		if String(building.get("type", "")) != Defs.BUILDING_ROAD:
			continue
		road_set[Vector2i(building.get("position", Vector2i.ZERO))] = true
	var viewport_size := get_viewport().get_visible_rect().size
	var y0 := 90.0
	var y1 := viewport_size.y - 184.0
	var roads: Array = []
	var grass: Array = []
	for tile in road_set.keys():
		var screen := _gfx_tile_screen(cam, Vector2i(tile))
		if screen.y < y0 or screen.y >= y1 or screen.x < 0.0 or screen.x >= viewport_size.x:
			continue
		roads.append([snappedf(screen.x, 0.1), snappedf(screen.y, 0.1)])
	for y in world_view.map_size.y:
		for x in world_view.map_size.x:
			var tile := Vector2i(x, y)
			if road_set.has(tile):
				continue
			if not sim.is_revealed(tile) or String(sim.get_tile(tile)) != Defs.TILE_GRASS:
				continue
			var min_d := 999
			for road_tile in road_set.keys():
				min_d = mini(min_d, maxi(absi(tile.x - road_tile.x), absi(tile.y - road_tile.y)))
			if min_d != 2:
				continue
			var screen := _gfx_tile_screen(cam, tile)
			if screen.y < y0 or screen.y >= y1 or screen.x < 0.0 or screen.x >= viewport_size.x:
				continue
			grass.append([snappedf(screen.x, 0.1), snappedf(screen.y, 0.1)])
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"roads": roads, "grass": grass, "road_tiles": roads.size(), "grass_tiles": grass.size()}))


func _gfx_tile_screen(cam: Camera3D, tile: Vector2i) -> Vector2:
	var world := world_view.tile_to_world(Vector2(tile))
	return cam.unproject_position(world)


func _evidence_shot(shot_name: String, description: String) -> void:
	_update_ui()
	_refresh_resource_chip_flash()
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := evidence_capture_dir.path_join(shot_name + ".png")
	var err := ERR_UNAVAILABLE
	if image != null and not image.is_empty():
		err = image.save_png(path)
		write_gfx_tile_mask_json(evidence_capture_dir.path_join(shot_name + ".roads.json"))
	var planks_color := ""
	if resource_chips.has("planks"):
		planks_color = (resource_chips["planks"] as Label).get_theme_color("font_color").to_html(false)
	_evidence_log("shot name=%s idle=%d" % [shot_name, idle_worker_count()])
	_evidence_log("shot name=%s err=%d size=%s placing=%s placement_panel=%s hint='%s' toast=%s toast_body='%s' pressure='%s' hostiles=%d night=%s planks_chip=#%s what=%s" % [
		shot_name, err, str(image.get_size()) if image != null else "-", placement_type,
		str(placement_panel.visible if placement_panel != null else false),
		placement_label.text if placement_label != null and placement_panel != null and placement_panel.visible else "",
		str(alert_panel.visible if alert_panel != null else false), toast_body.text if toast_body != null else "",
		pressure_meter.display_text() if pressure_meter != null and pressure_meter.has_method("display_text") else "",
		int(simulation_host.simulation.living_hostile_count()), str(simulation_host.simulation.is_night), planks_color, description
	])


func _evidence_log(line: String) -> void:
	print("[%s] EVIDENCE_CAPTURE %s" % [Time.get_datetime_string_from_system(), line])
