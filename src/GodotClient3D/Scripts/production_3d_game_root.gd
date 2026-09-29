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
var pause_button: Button
var speed_button: Button
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
## Playtest.31 UI: per-button type/container/cost label for affordability + tooltip gating.
var build_strip_types: Array[String] = []
var build_strip_containers: Array = []
var build_strip_cost_labels: Array = []
var build_strip_tooltips: Array[String] = []
var resource_chip_flash_until: Dictionary = {}
var resource_chip_base_colors: Dictionary = {}
const CHIP_KEYS_BY_RESOURCE := {
	"wood": "wood", "planks": "planks", "stone": "stone", "wheat": "wheat", "bread": "bread", "wyrd": "wyrd"
}
const COLOR_UNAFFORDABLE := Color("#ff6b5a")
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
	if debug_audio_cycle_active or debug_ui_scene != "":
		print("[%s] DEBUG_LAUNCH audio_cycle=%s ui_scene=%s version=%s" % [Time.get_datetime_string_from_system(), str(debug_audio_cycle_active), debug_ui_scene, String(ProjectSettings.get_setting("application/config/version", ""))])


func _run_release_check() -> void:
	var check_script = load("res://src/GodotClient3D/Scripts/production_release_check.gd")
	await check_script.run(self)


func _process(delta: float) -> void:
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
		if event.keycode == KEY_ESCAPE and objective_detail_panel != null and objective_detail_panel.visible:
			_show_objective_detail(false)
			get_viewport().set_input_as_handled()
			return
		if startup_overlay != null and startup_overlay.visible:
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
			return
	
	# Cancel any existing placement or dragging state first
	_cancel_road_drag()
	_cancel_wall_drag()
	map_drag_active = false
	map_drag_moved = false
	# Now start fresh placement
	placement_preview_locked = false
	placement_type = building_type
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
	sky_material_value.sky_top_color = Color("#1a2428")
	sky_material_value.sky_horizon_color = Color("#243830")
	sky_material_value.ground_bottom_color = Color("#0c1614")
	sky_material_value.ground_horizon_color = Color("#14221c")
	sky.sky_material = sky_material_value
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_energy = 0.56
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.ssao_enabled = bool(quality_profile.get("shadows", true))
	environment.ssao_radius = 1.5
	environment.ssao_intensity = 1.3
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.04
	environment.adjustment_contrast = 1.05
	environment.fog_enabled = true
	environment.fog_light_color = Color("#1e322c")
	environment.fog_light_energy = 0.38
	environment.fog_density = 0.0035
	environment.fog_height = 4.0
	environment.fog_height_density = 0.045
	environment_node.environment = environment
	lighting_rig.add_child(environment_node)
	var sun := DirectionalLight3D.new()
	sun_light = sun
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-54.0, -34.0, 0.0)
	sun.light_color = Color("#f2ecc4")
	sun.light_energy = 1.12
	sun.shadow_enabled = bool(quality_profile.get("shadows", true))
	sun.directional_shadow_max_distance = float(quality_profile.get("shadow_distance", 170.0))
	lighting_rig.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill_light = fill
	fill.name = "CoolFill"
	fill.rotation_degrees = Vector3(-36.0, 145.0, 0.0)
	fill.light_color = Color("#8aa9bd")
	fill.light_energy = 0.30
	fill.shadow_enabled = false
	lighting_rig.add_child(fill)


func _create_ui() -> void:
	var root := Control.new()
	root.name = "ProductionHUD"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(root)
	hud_root = root

	var top_panel := PanelContainer.new()
	top_panel.name = "TopBar"
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_left = 14.0
	top_panel.offset_top = 12.0
	top_panel.offset_right = -14.0
	top_panel.offset_bottom = 68.0
	top_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.055, 0.057, 0.88), Color("#526f6c")))
	root.add_child(top_panel)
	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 12)
	top_margin.add_theme_constant_override("margin_right", 10)
	top_margin.add_theme_constant_override("margin_top", 7)
	top_margin.add_theme_constant_override("margin_bottom", 7)
	top_panel.add_child(top_margin)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	top_margin.add_child(top_row)
	var chip_host := HBoxContainer.new()
	chip_host.name = "ResourceStrip"
	chip_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip_host.add_theme_constant_override("separation", 10)
	top_row.add_child(chip_host)
	resource_label = Label.new()
	resource_label.visible = false
	chip_host.add_child(resource_label)
	resource_chips["wood"] = _add_resource_chip(chip_host, "wood", "Wood")
	resource_chips["planks"] = _add_resource_chip(chip_host, "planks", "Planks")
	resource_chips["stone"] = _add_resource_chip(chip_host, "stone", "Stone")
	resource_chips["wheat"] = _add_resource_chip(chip_host, "wheat", "Wheat")
	resource_chips["bread"] = _add_resource_chip(chip_host, "bread", "Bread")
	resource_chips["wyrd"] = _add_resource_chip(chip_host, "wyrd", "Wyrd")
	pressure_meter = PressureMeterScript.new()
	pressure_meter.name = "WyrdPressure"
	pressure_meter.visible = true
	chip_host.add_child(pressure_meter)
	population_label = Label.new()
	population_label.name = "PopulationChip"
	population_label.tooltip_text = "Population / housing"
	population_label.mouse_filter = Control.MOUSE_FILTER_STOP
	Identity.apply_label(population_label, "numeric")
	chip_host.add_child(population_label)
	time_label = Label.new()
	time_label.name = "TimeChip"
	time_label.tooltip_text = "Day and time"
	time_label.mouse_filter = Control.MOUSE_FILTER_STOP
	Identity.apply_label(time_label, "numeric")
	chip_host.add_child(time_label)
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
	build_toggle_button.text = "BUILD"
	build_toggle_button.toggle_mode = true
	build_toggle_button.tooltip_text = "Open settlement plans"
	build_toggle_button.pressed.connect(_toggle_build_palette)
	top_row.add_child(build_toggle_button)
	pause_button = Button.new()
	pause_button.name = "PauseGame"
	pause_button.text = "PAUSE"
	pause_button.pressed.connect(_toggle_pause)
	top_row.add_child(pause_button)
	speed_button = Button.new()
	speed_button.name = "GameSpeed"
	speed_button.text = "1x"
	speed_button.custom_minimum_size.x = 48.0
	speed_button.pressed.connect(_cycle_speed)
	top_row.add_child(speed_button)
	var menu_button := Button.new()
	menu_button.name = "MainMenu"
	menu_button.text = "MENU"
	menu_button.pressed.connect(_show_start_menu)
	top_row.add_child(menu_button)
	var compact_button_widths := [58.0, 58.0, 48.0, 58.0]
	var compact_button_index := 0
	for compact_button in [build_toggle_button, pause_button, speed_button, menu_button]:
		(compact_button as Button).add_theme_font_size_override("font_size", 12)
		(compact_button as Button).custom_minimum_size.x = compact_button_widths[compact_button_index]
		compact_button_index += 1

	var loop_panel := PanelContainer.new()
	loop_panel.name = "LoopBar"
	loop_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	loop_panel.offset_left = 14.0
	loop_panel.offset_top = 72.0
	loop_panel.offset_right = -14.0
	loop_panel.offset_bottom = 108.0
	loop_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.040, 0.050, 0.055, 0.82), Color("#3d5c66")))
	root.add_child(loop_panel)
	var loop_margin := MarginContainer.new()
	loop_margin.add_theme_constant_override("margin_left", 12)
	loop_margin.add_theme_constant_override("margin_right", 10)
	loop_margin.add_theme_constant_override("margin_top", 5)
	loop_margin.add_theme_constant_override("margin_bottom", 5)
	loop_panel.add_child(loop_margin)
	var loop_row := HBoxContainer.new()
	loop_row.add_theme_constant_override("separation", 16)
	loop_margin.add_child(loop_row)
	objective_button = Button.new()
	objective_button.name = "MacroObjective"
	objective_button.flat = true
	objective_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	objective_button.add_theme_font_size_override("font_size", 13)
	objective_button.pressed.connect(_toggle_objective_detail)
	Identity.apply_button(objective_button)
	loop_row.add_child(objective_button)
	objective_label = Label.new()
	objective_label.visible = false
	loop_row.add_child(objective_label)
	event_log_button = Button.new()
	event_log_button.name = "EventLogToggle"
	event_log_button.text = "LOG"
	event_log_button.custom_minimum_size.x = 52.0
	Identity.apply_button(event_log_button)
	event_log_button.pressed.connect(_toggle_event_log)
	loop_row.add_child(event_log_button)
	pressure_label = Label.new()
	pressure_label.visible = false
	loop_row.add_child(pressure_label)
	loop_label = Label.new()
	loop_label.name = "LoopStatus"
	loop_label.add_theme_font_size_override("font_size", 12)
	loop_label.add_theme_color_override("font_color", Color("#c5d0c8"))
	loop_row.add_child(loop_label)
	bind_button = Button.new()
	bind_button.name = "BeginBinding"
	bind_button.text = "BIND THE SHARD"
	bind_button.visible = false
	bind_button.custom_minimum_size.x = 132.0
	Identity.apply_button(bind_button, true)
	bind_button.pressed.connect(_prompt_binding)
	loop_row.add_child(bind_button)
	binding_percent_label = Label.new()
	binding_percent_label.name = "BindingProgress"
	binding_percent_label.visible = false
	Identity.apply_label(binding_percent_label, "wyrd")
	loop_row.add_child(binding_percent_label)

	alert_panel = PanelContainer.new()
	alert_panel.name = "AlertToast"
	alert_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	alert_panel.offset_left = -210.0
	alert_panel.offset_top = 104.0
	alert_panel.offset_right = 210.0
	alert_panel.offset_bottom = 168.0
	alert_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.12, 0.075, 0.055, 0.94), Color("#c68559")))
	root.add_child(alert_panel)
	var alert_margin := MarginContainer.new()
	alert_margin.add_theme_constant_override("margin_left", 12)
	alert_margin.add_theme_constant_override("margin_right", 8)
	alert_margin.add_theme_constant_override("margin_top", 8)
	alert_margin.add_theme_constant_override("margin_bottom", 8)
	alert_panel.add_child(alert_margin)
	var alert_row := HBoxContainer.new()
	alert_row.add_theme_constant_override("separation", 10)
	alert_margin.add_child(alert_row)
	var toast_icon := Label.new()
	toast_icon.name = "ToastIcon"
	toast_icon.text = "!"
	toast_icon.custom_minimum_size = Vector2(18, 18)
	toast_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_icon.add_theme_font_size_override("font_size", 16)
	toast_icon.add_theme_color_override("font_color", Color("#ffd3a8"))
	alert_row.add_child(toast_icon)
	var toast_copy := VBoxContainer.new()
	toast_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alert_row.add_child(toast_copy)
	toast_title = Label.new()
	toast_title.name = "ToastTitle"
	toast_title.add_theme_font_size_override("font_size", 13)
	toast_title.add_theme_color_override("font_color", Color("#ffd3a8"))
	toast_copy.add_child(toast_title)
	toast_body = Label.new()
	toast_body.name = "ToastBody"
	toast_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_body.add_theme_font_size_override("font_size", 11)
	toast_body.add_theme_color_override("font_color", Color("#d7c4b2"))
	toast_copy.add_child(toast_body)
	alert_label = toast_title
	var dismiss := Button.new()
	dismiss.text = "X"
	dismiss.custom_minimum_size = Vector2(28, 28)
	Identity.apply_button(dismiss)
	dismiss.pressed.connect(_dismiss_toast)
	alert_row.add_child(dismiss)
	alert_panel.visible = false

	event_log_panel = PanelContainer.new()
	event_log_panel.name = "EventLog"
	event_log_panel.visible = false
	event_log_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	event_log_panel.offset_left = -340.0
	event_log_panel.offset_top = 108.0
	event_log_panel.offset_right = -16.0
	event_log_panel.offset_bottom = 360.0
	event_log_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.04, 0.05, 0.055, 0.94), Color("#3d5c66")))
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

	objective_detail_panel = PanelContainer.new()
	objective_detail_panel.name = "ObjectiveDetail"
	objective_detail_panel.visible = false
	objective_detail_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	objective_detail_panel.anchor_right = 0.0
	objective_detail_panel.anchor_bottom = 0.0
	objective_detail_panel.offset_left = 14.0
	objective_detail_panel.offset_top = 96.0
	objective_detail_panel.offset_right = 300.0
	objective_detail_panel.offset_bottom = 252.0
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
	nightfall_panel.offset_top = 148.0
	nightfall_panel.offset_right = 210.0
	nightfall_panel.offset_bottom = 214.0
	nightfall_panel.add_theme_stylebox_override("panel", Identity.panel_style(Color(0.08, 0.06, 0.05, 0.92), Identity.COLOR_WARNING))
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
	build_panel.position = Vector2(14, 100)
	build_panel.size = Vector2(232, 322)
	build_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.052, 0.043, 0.94), Color("#8e774c")))
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
	build_title.text = "Build"
	build_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build_title.add_theme_color_override("font_color", Color("#efcf8a"))
	build_title.add_theme_font_size_override("font_size", 22)
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
			button.custom_minimum_size.y = 44
			button.add_theme_font_size_override("font_size", 12)
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
	
	build_strip = PanelContainer.new()
	build_strip.name = "BuildStrip"
	build_strip.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	build_strip.offset_left = 16.0
	build_strip.offset_right = -16.0
	build_strip.offset_top = -100.0
	build_strip.offset_bottom = -12.0
	build_strip.add_theme_stylebox_override("panel", _panel_style(Color(0.050, 0.048, 0.040, 0.92), Color("#6b5d3e")))
	root.add_child(build_strip)
	var strip_margin := MarginContainer.new()
	strip_margin.add_theme_constant_override("margin_left", 8)
	strip_margin.add_theme_constant_override("margin_right", 8)
	strip_margin.add_theme_constant_override("margin_top", 6)
	strip_margin.add_theme_constant_override("margin_bottom", 6)
	build_strip.add_child(strip_margin)
	var strip_scroll := ScrollContainer.new()
	strip_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	strip_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	strip_margin.add_child(strip_scroll)
	var strip_box := HBoxContainer.new()
	strip_box.add_theme_constant_override("separation", 4)
	strip_scroll.add_child(strip_box)
	for building_type in BUILD_PALETTE:
		# Issue #7 fix: Better C&C-style icons with tooltips showing requirements
		var btn_container := PanelContainer.new()
		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = _building_icon_color(building_type)
		btn_style.border_color = Color("#3a3a3a")
		btn_style.set_border_width_all(1)
		btn_style.corner_radius_top_left = 3
		btn_style.corner_radius_top_right = 3
		btn_style.corner_radius_bottom_left = 3
		btn_style.corner_radius_bottom_right = 3
		btn_container.add_theme_stylebox_override("panel", btn_style)
		strip_box.add_child(btn_container)
		
		# Make the entire area (icon + text) a single clickable button
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(72, 62)
		btn.flat = true
		btn.pressed.connect(begin_placement.bind(building_type))
		var purpose := String(BUILD_PURPOSES.get(building_type, "Settlement building."))
		var cost := Defs.formatted_cost(building_type)
		btn.tooltip_text = "%s\n\n%s\nCost: %s" % [Defs.building_name(building_type), purpose, cost]
		btn.mouse_entered.connect(_on_strip_button_hovered.bind(String(building_type)))
		btn_container.add_child(btn)
		
		var btn_vbox := VBoxContainer.new()
		btn_vbox.add_theme_constant_override("separation", 2)
		btn_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(btn_vbox)
		
		var icon_canvas := Control.new()
		icon_canvas.custom_minimum_size = Vector2(72, 32)
		icon_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon_drawing := _create_building_icon_visual(building_type)
		icon_canvas.add_child(icon_drawing)
		btn_vbox.add_child(icon_canvas)
		
		var label := Label.new()
		label.text = Defs.building_name(building_type) if building_type != Defs.TOOL_CLEAR_AREA else "Clear"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 9)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn_vbox.add_child(label)
		var cost_label := Label.new()
		cost_label.name = "Cost"
		cost_label.text = _compact_cost(String(building_type))
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_label.add_theme_font_size_override("font_size", 9)
		cost_label.add_theme_color_override("font_color", Color("#e8dcb4"))
		cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn_vbox.add_child(cost_label)
		
		build_strip_buttons.append(btn)
		build_strip_types.append(String(building_type))
		build_strip_containers.append(btn_container)
		build_strip_cost_labels.append(cost_label)
		build_strip_tooltips.append(btn.tooltip_text)

	inspector_panel = PanelContainer.new()
	inspector_panel.name = "Inspector"
	inspector_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	inspector_panel.offset_left = -246.0
	inspector_panel.offset_top = 144.0
	inspector_panel.offset_right = -10.0
	inspector_panel.offset_bottom = 346.0
	inspector_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.056, 0.059, 0.94), Color("#638a93")))
	root.add_child(inspector_panel)
	var inspector_margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		inspector_margin.add_theme_constant_override(side, 16)
	inspector_panel.add_child(inspector_margin)
	var inspector_box := VBoxContainer.new()
	inspector_margin.add_child(inspector_box)
	inspector_label = RichTextLabel.new()
	inspector_label.bbcode_enabled = true
	inspector_label.fit_content = true
	inspector_label.scroll_active = true
	inspector_label.add_theme_color_override("default_color", Color("#d5ddd0"))
	inspector_label.add_theme_font_size_override("normal_font_size", 15)
	inspector_box.add_child(inspector_label)
	assault_button = Button.new()
	assault_button.name = "AssaultOutpost"
	assault_button.text = "ASSAULT RIVAL OUTPOST"
	assault_button.tooltip_text = "Send free patrol soldiers. Tower sentries stay home. Soldiers must reach the Outpost and can be killed en route."
	Identity.apply_button(assault_button)
	assault_button.pressed.connect(_order_selected_outpost_assault)
	inspector_box.add_child(assault_button)
	assault_button.visible = false
	recall_button = Button.new()
	recall_button.name = "RecallAssault"
	recall_button.text = "RECALL ASSAULT SOLDIERS"
	Identity.apply_button(recall_button)
	recall_button.pressed.connect(func() -> void: _show_command_result(simulation_host.simulation.recall_assault_soldiers()))
	inspector_box.add_child(recall_button)
	recall_button.visible = false
	inspector_panel.visible = false

	placement_panel = PanelContainer.new()
	placement_panel.name = "PlacementHint"
	placement_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	placement_panel.offset_left = -235.0
	placement_panel.offset_right = 235.0
	placement_panel.offset_top = -176.0
	placement_panel.offset_bottom = -112.0
	placement_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.055, 0.052, 0.90), Color("#6e8e72")))
	root.add_child(placement_panel)
	var placement_vbox := VBoxContainer.new()
	placement_vbox.add_theme_constant_override("separation", 4)
	placement_panel.add_child(placement_vbox)
	placement_legend_label = Label.new()
	placement_legend_label.text = ""
	placement_legend_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	placement_legend_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placement_legend_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placement_legend_label.add_theme_color_override("font_color", Color("#a8b89c"))
	placement_legend_label.add_theme_font_size_override("font_size", 11)
	placement_vbox.add_child(placement_legend_label)
	placement_label = Label.new()
	placement_label.text = ""
	placement_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	placement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placement_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placement_label.add_theme_color_override("font_color", Color("#e2d4ad"))
	placement_vbox.add_child(placement_label)
	placement_panel.visible = false
	minimap = MinimapScript.new()
	minimap.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	minimap.anchor_left = 1.0
	minimap.anchor_right = 1.0
	minimap.anchor_top = 1.0
	minimap.anchor_bottom = 1.0
	# Playtest.31: minimap sits above the build strip instead of covering its
	# right end (the Clear tool was hidden under it).
	minimap.offset_left = -214.0
	minimap.offset_top = -346.0
	minimap.offset_right = -16.0
	minimap.offset_bottom = -110.0
	minimap.visible = false
	minimap.focus_requested.connect(_focus_from_minimap)
	root.add_child(minimap)
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
	var hit := _raycast_terrain(get_viewport().get_mouse_position())
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
	placement_label.text = "%s · %s" % ["CLEARING REQUIRED" if needs_clearing else ("VALID" if valid else "INVALID"), String(placement_validation.get("message", ""))]


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
	if population_label != null:
		population_label.text = "Pop %d/%d" % [int(resources.get(Defs.RESOURCE_POPULATION_USED, 0)), int(resources.get(Defs.RESOURCE_POPULATION_MAX, 0))]
	if time_label != null:
		time_label.text = simulation_host.simulation.get_time_label()
	if resource_label != null:
		resource_label.text = ""
	if Time.get_ticks_msec() / 1000.0 >= status_message_until:
		status_label.text = ""
		status_message_text = ""
	_ingest_simulation_notices()
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
		if index < build_strip_containers.size():
			(build_strip_containers[index] as Control).modulate = Color(1, 1, 1, 1) if affordable else Color(0.62, 0.62, 0.62, 0.55)
		if index < build_strip_cost_labels.size():
			(build_strip_cost_labels[index] as Label).add_theme_color_override("font_color", Color("#e8dcb4") if affordable else COLOR_UNAFFORDABLE)
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
		var sim_objectives: Array = simulation_host.simulation.get_objectives()
		var active_sim_obj := ""
		for obj in sim_objectives:
			if not bool(obj.get("complete", false)):
				active_sim_obj = String(obj.get("text", ""))
				break
		if binding_active:
			objective_button.text = "HOLD THE BINDING"
		elif active_sim_obj != "":
			objective_button.text = active_sim_obj
		elif not steps.is_empty():
			objective_button.text = String(steps[0])
		else:
			objective_button.text = String(objective.get("title", "FEED THE SETTLEMENT"))
		objective_button.tooltip_text = "%s — %s" % [String(objective.get("title", "")), String(objective.get("detail", "Click for the next step."))]
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
		pressure_meter.visible = play_has_begun
		pressure_meter.set_pressure(pressure)
		if pressure_meter.has_method("set_threat"):
			pressure_meter.set_threat(bool(simulation_host.simulation.is_night), hostiles)
		pressure_meter.tooltip_text = String(wyrdfall.get("pressure_tooltip", "Wyrd Pressure"))
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


func _update_inspector() -> void:
	if inspector_label == null or inspector_panel == null or simulation_host.simulation == null:
		return
	assault_button.visible = false
	recall_button.visible = false
	if build_panel != null and build_panel.visible:
		inspector_panel.visible = false
		return
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
			lines.append(_debug_id_line(selected_worker_id))
			inspector_label.text = "\n".join(lines)
			inspector_panel.visible = true
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
		_show_toast(String(notice.get("title", "")), String(notice.get("body", "")), String(notice.get("severity", "info")))
	_refresh_event_log()


func _show_toast(title: String, body: String, severity: String = "info", hold_seconds: float = -1.0) -> void:
	if title == "":
		return
	var key := "%s:%s" % [title, body]
	if key == last_toast_key and Time.get_ticks_msec() / 1000.0 < toast_until:
		return
	last_toast_key = key
	toast_severity = severity
	if toast_title != null:
		toast_title.text = title
	if toast_body != null:
		toast_body.text = body
	var hold := hold_seconds if hold_seconds > 0.0 else (7.5 if severity == "critical" else 4.2)
	toast_until = Time.get_ticks_msec() / 1000.0 + hold
	if alert_panel != null:
		alert_panel.visible = startup_overlay == null or not startup_overlay.visible
		alert_panel.modulate.a = 1.0


func _dismiss_toast() -> void:
	toast_until = 0.0
	if alert_panel != null:
		alert_panel.visible = false


func _tick_toasts(_delta: float) -> void:
	if alert_panel == null or not alert_panel.visible:
		return
	var remaining := toast_until - Time.get_ticks_msec() / 1000.0
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
	var sim_objectives: Array = simulation_host.simulation.get_objectives()
	var lines: Array[String] = ["Current Goals", ""]
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
	pause_button.text = "Resume" if simulation_host.paused else "Pause"
	world_view.set_presentation_paused(simulation_host.paused)


func _cycle_speed() -> void:
	var speeds := [1.0, 2.0, 4.0]
	var current := speeds.find(simulation_host.speed_multiplier)
	simulation_host.speed_multiplier = speeds[(current + 1) % speeds.size()]
	speed_button.text = "%dx" % int(simulation_host.speed_multiplier)


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
	var profile_name := String(quality_select.get_selected_metadata())
	quality_profile = QualityProfile.get_profile(profile_name)
	get_viewport().msaa_3d = Viewport.MSAA_2X if bool(quality_profile.get("shadows", true)) else Viewport.MSAA_DISABLED
	if sun_light != null:
		sun_light.shadow_enabled = bool(quality_profile.get("shadows", true))
	if environment_resource != null:
		environment_resource.ssao_enabled = bool(quality_profile.get("shadows", true))


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
	if pause_button != null:
		pause_button.text = "Resume"
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
	if pause_button != null:
		pause_button.text = "Pause"
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
	for chrome_name in ["TopBar", "LoopBar", "ProvinceMinimap"]:
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
	if simulation_host.simulation == null or environment_resource == null or sun_light == null:
		return
	var simulation = simulation_host.simulation
	var palette: Dictionary
	var menu_visible := startup_overlay != null and startup_overlay.visible
	if menu_visible:
		palette = Identity.lighting_palette("dusk")
	elif bool(simulation.reckoning_active):
		palette = Identity.mix_lighting("night", "reckoning", 0.85)
	elif simulation.is_night:
		palette = Identity.lighting_palette("night")
	else:
		var remaining: float = float(simulation.DAY_LENGTH_SECONDS) - float(simulation.phase_time)
		if remaining < 60.0:
			palette = Identity.mix_lighting("day", "dusk", 1.0 - pow(clampf(remaining / 60.0, 0.0, 1.0), 1.35))
		elif simulation.day_count > 1 and simulation.phase_time < 40.0:
			palette = Identity.mix_lighting("night", "day", pow(clampf(simulation.phase_time / 40.0, 0.0, 1.0), 1.2))
		else:
			palette = Identity.lighting_palette("day")
	_apply_lighting_palette(palette)


func _apply_lighting_palette(palette: Dictionary) -> void:
	var road_brightness := clampf(float(palette.get("sun_energy", 1.1)) * 0.68 + float(palette.get("ambient", 0.5)) * 0.6, 0.22, 1.0)
	var road_tint := Color.WHITE.lerp(palette.get("sun_color", Color.WHITE), 0.25) * road_brightness
	road_tint.a = 1.0
	ProductionRoadView3D.set_lighting(road_tint)
	environment_resource.ambient_light_energy = float(palette.get("ambient", 0.5))
	environment_resource.ambient_light_color = palette.get("fill_color", Color("#849aaf"))
	environment_resource.fog_density = float(palette.get("fog_density", 0.003))
	environment_resource.fog_light_color = palette.get("fog_color", Color("#c8c2a5"))
	environment_resource.fog_light_energy = float(palette.get("fog_energy", 0.7))
	environment_resource.adjustment_saturation = float(palette.get("saturation", 1.0))
	environment_resource.adjustment_contrast = float(palette.get("contrast", 1.04))
	sun_light.light_energy = float(palette.get("sun_energy", 1.1))
	sun_light.light_color = palette.get("sun_color", Color("#ffe0a8"))
	sun_light.rotation_degrees.x = float(palette.get("sun_pitch", -52.0))
	if fill_light != null:
		fill_light.light_energy = float(palette.get("fill_energy", 0.28))
		fill_light.light_color = palette.get("fill_color", Color("#9bb4c4"))
	if sky_material != null:
		sky_material.sky_top_color = palette.get("sky_top", Color("#5a88a8"))
		sky_material.sky_horizon_color = palette.get("sky_horizon", Color("#d6c9a0"))
		sky_material.ground_bottom_color = palette.get("ground_bottom", Color("#303326"))
		sky_material.ground_horizon_color = palette.get("ground_horizon", Color("#8a8668"))


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


func _panel_style(background: Color, border: Color) -> StyleBoxFlat:
	return Identity.panel_style(background, border)


func _add_resource_chip(host: HBoxContainer, key: String, caption: String) -> Label:
	# Issue #8 fix: Use visual icons instead of just color bars
	var cell := HBoxContainer.new()
	cell.name = "Chip_%s" % key
	cell.add_theme_constant_override("separation", 6)
	cell.tooltip_text = caption
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	# Create an icon representation for each resource
	var icon_container := Control.new()
	icon_container.custom_minimum_size = Vector2(20, 20)
	var icon := _create_resource_icon(key)
	icon_container.add_child(icon)
	cell.add_child(icon_container)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", -1)
	var code := Label.new()
	code.text = caption
	Identity.apply_label(code, "caption")
	code.add_theme_font_size_override("font_size", 10)
	stack.add_child(code)
	var value := Label.new()
	value.name = "Value"
	Identity.apply_label(value, "numeric")
	if key == "wyrd":
		Identity.apply_label(value, "wyrd")
		value.add_theme_font_size_override("font_size", Identity.SIZE_NUMERIC)
	stack.add_child(value)
	cell.add_child(stack)
	host.add_child(cell)
	return value


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
		nightfall_label.text = "NIGHTFALL\nThreat: %s   Likely activity: %s" % [
			String(forecast.get("threat", "QUIET")),
			String(forecast.get("activity", "Unknown"))
		]
	nightfall_event_until = Time.get_ticks_msec() / 1000.0 + 5.2


func _ghost_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.no_depth_test = true
	return material


func _parse_launch_options() -> Dictionary:
	var options := {"seed": DEFAULT_SEED, "load": false, "fixture": "", "quality": "recommended", "autostart": false, "debug_audio_cycle": false, "debug_ui_scene": "", "debug_quit": false, "evidence_capture": ""}
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
	_evidence_log("start dir=%s viewport=%s window=%s pos=%s" % [dir, str(get_viewport().get_visible_rect().size), str(get_window().size), str(get_window().position)])
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
	await _evidence_wait(0.5)
	begin_placement(Defs.BUILDING_BAKERY)
	# Hover the Town Hall footprint so the stale placement hint reads INVALID
	# (the 71 before showed INVALID + resource toast for one click).
	_evidence_hover_point(Vector2(655, 330))
	await _evidence_wait(1.0)
	_evidence_hover_point(Vector2(657, 332))
	_update_placement_ghost(true)
	await _evidence_wait(0.8)
	await _evidence_shot("71_after_stale_invalid", "night raid, Bakery placement hovering the Town Hall: stale INVALID hint (state before the unaffordable click)")
	var barracks_button := _evidence_strip_button(Defs.BUILDING_BARRACKS)
	_evidence_hover_control(barracks_button)
	simulation.central_inventory[Defs.RESOURCE_PLANKS] = 8
	begin_placement(Defs.BUILDING_BARRACKS)
	await _evidence_wait(0.7)
	for attempt in 30:
		if int(Time.get_ticks_msec() / 1000.0 * 4.0) % 2 == 0:
			break
		await get_tree().process_frame
	await _evidence_shot("71_after", "night raid, unaffordable Barracks click: one toast, INVALID hint gone, dimmed buttons, red cost, Planks chip highlighted, RAID badge")
	_evidence_log("done")
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


func _evidence_shot(shot_name: String, description: String) -> void:
	_update_ui()
	_refresh_resource_chip_flash()
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := evidence_capture_dir.path_join(shot_name + ".png")
	var err := ERR_UNAVAILABLE
	if image != null and not image.is_empty():
		err = image.save_png(path)
	var planks_color := ""
	if resource_chips.has("planks"):
		planks_color = (resource_chips["planks"] as Label).get_theme_color("font_color").to_html(false)
	_evidence_log("shot name=%s err=%d size=%s placing=%s placement_panel=%s toast=%s toast_body='%s' pressure='%s' hostiles=%d night=%s planks_chip=#%s what=%s" % [
		shot_name, err, str(image.get_size()) if image != null else "-", placement_type,
		str(placement_panel.visible if placement_panel != null else false),
		str(alert_panel.visible if alert_panel != null else false), toast_body.text if toast_body != null else "",
		pressure_meter.display_text() if pressure_meter != null and pressure_meter.has_method("display_text") else "",
		int(simulation_host.simulation.living_hostile_count()), str(simulation_host.simulation.is_night), planks_color, description
	])


func _evidence_log(line: String) -> void:
	print("[%s] EVIDENCE_CAPTURE %s" % [Time.get_datetime_string_from_system(), line])
