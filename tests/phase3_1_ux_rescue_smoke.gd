extends SceneTree

const Scene = preload("res://src/GodotClient3D/Scenes/production_3d.tscn")
const Defs = preload("res://src/GodotClient/Scripts/one_shard_defs.gd")
const Catalog = preload("res://src/GodotClient3D/Scripts/production_asset_catalog.gd")
const Adapter = preload("res://src/GodotClient3D/Scripts/production_presentation_adapter.gd")
const Fixture = preload("res://src/GodotClient3D/Scripts/production_demo_fixture.gd")
const RivalryTuning = preload("res://src/GodotClient/Scripts/one_shard_rivalry_tuning.gd")

const VIEWPORT_SIZE := Vector2i(1920, 1080)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = VIEWPORT_SIZE
	var failures: Array[String] = []
	var game := Scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game._hide_start_menu()
	game.simulation_host.paused = true
	var simulation = game.simulation_host.simulation
	var fixture := Fixture.new()
	var fixture_result: Dictionary = fixture.apply(simulation, "developed")
	_check(failures, bool(fixture_result.get("success", false)), "developed settlement is available for the rescue checks")
	game._initialize_presentation()
	game._update_ui()
	await process_frame

	_check_default_ui(failures, game)
	_check_fog_and_overlays(failures, game)
	await _check_road_workflow(failures, game)
	_check_barracks(failures, game, fixture)
	_check_hostiles(failures, game, fixture)
	_check_sovereign(failures, game)
	_check_selection_priority(failures, game)
	_check_audio_and_animation(failures, game)

	game.queue_free()
	await process_frame
	_finish(failures)


func _check_default_ui(failures: Array[String], game) -> void:
	var top_bar := game.ui_layer.find_child("TopBar", true, false) as Control
	var visible_area := top_bar.size.x * top_bar.size.y
	if game.alert_panel.visible:
		visible_area += game.alert_panel.size.x * game.alert_panel.size.y
	var occupancy := visible_area / float(VIEWPORT_SIZE.x * VIEWPORT_SIZE.y)
	_check(failures, not game.build_panel.visible and not game.inspector_panel.visible and not game.placement_panel.visible, "normal gameplay opens with no build, inspector, activity, or placement panel")
	_check(failures, occupancy <= 0.15, "normal player HUD occupies at most fifteen percent of the 1920x1080 world view")
	var visible_text := _visible_control_text(game.ui_layer).to_lower()
	var developer_free := not "production 3d" in visible_text and not "real workers displayed" in visible_text and not "authoritative" in visible_text and not "active job states" in visible_text
	_check(failures, developer_free, "normal player UI contains no reported developer-first language")
	game._set_build_palette_visible(true)
	var design_scale: float = float(VIEWPORT_SIZE.x) / float(ProjectSettings.get_setting("display/window/size/viewport_width", 1280))
	var palette_width_1080p: float = game.build_panel.size.x * design_scale
	_check(failures, game.build_panel.visible and palette_width_1080p >= 300.0 and palette_width_1080p <= 380.0, "BUILD opens a compact categorized palette")
	var remembered: String = game.current_build_category
	game._set_build_palette_visible(false)
	game._set_build_palette_visible(true)
	_check(failures, game.current_build_category == remembered, "build palette remembers its selected category")
	game._set_build_palette_visible(false)


func _check_fog_and_overlays(failures: Array[String], game) -> void:
	var fog: Dictionary = game.world_view.fog_configuration()
	_check(failures, bool(fog.get("uses_smoothed_texture", false)) and bool(fog.get("filter_linear", false)), "FOW uses a linearly sampled smoothed visibility texture")
	_check(failures, int(fog.get("edge_feather_cells", 0)) >= 2 and float(fog.get("noise_strength", 0.0)) > 0.0, "FOW boundary is feathered and subtly irregular")
	_check(failures, int(fog.get("mesh_count", 0)) <= 1, "FOW is rendered as one atmospheric world mask rather than a logical-cell grid")
	game.world_view.set_claim_overlay_visible(false)
	game.world_view.set_watchtower_overlay(Vector2.ZERO, 0.0, false)
	game._sync_presentation()
	_check(failures, game.world_view.claims_root.get_child_count() == 0, "claim and range circles are hidden during normal play")
	var watchtower := _find_building(game.simulation_host.simulation, Defs.BUILDING_WATCHTOWER)
	if not watchtower.is_empty():
		game.select_building(int(watchtower.get("id", 0)))
		game._sync_presentation()
		_check(failures, game.world_view.claims_root.get_child_count() == 1, "selecting a Watchtower shows only its contextual attack range")
	game.begin_placement(Defs.BUILDING_LUMEN_PILLAR)
	game._sync_presentation()
	_check(failures, game.world_view.claims_root.get_child_count() > 0, "claim overlays appear while a claim tool is selected")
	game.cancel_placement()
	game._sync_presentation()


func _check_road_workflow(failures: Array[String], game) -> void:
	var simulation = game.simulation_host.simulation
	var route := _find_valid_road_route(simulation)
	_check(failures, route.size() >= 3, "a multi-section connected road route is available")
	if route.size() < 3:
		return
	game.begin_placement(Defs.BUILDING_ROAD)
	var start_world: Vector3 = game.world_view.tile_to_world(Vector2(route.front())) + Vector3.UP * 0.05
	var end_world: Vector3 = game.world_view.tile_to_world(Vector2(route.back())) + Vector3.UP * 0.05
	var start_screen: Vector2 = game.camera_rig.camera.unproject_position(start_world)
	var end_screen: Vector2 = game.camera_rig.camera.unproject_position(end_world)
	game._start_road_drag(start_screen)
	game._update_road_drag_preview(end_screen)
	_check(failures, game.road_dragging and game.road_preview_route.size() >= 3 and game.world_view.road_preview_root.get_child_count() >= 3, "road drag displays a continuous live route preview")
	var plans_before := _road_plan_count(simulation)
	game._finish_road_drag(end_screen)
	var plans_after := _road_plan_count(simulation)
	_check(failures, plans_after > plans_before, "releasing a valid road drag commits multiple connected road plans")
	_check(failures, game.placement_type == Defs.BUILDING_ROAD and game.placement_panel.visible, "Road Building Mode remains active after commit without reselection")
	game.cancel_placement()
	_check(failures, game.placement_type == "" and not game.placement_panel.visible, "right-click or Escape cancellation has a complete road-mode exit path")
	var road_view = game.world_view.road_views.values()[0] if not game.world_view.road_views.is_empty() else null
	_check(failures, road_view != null and road_view.find_child("ContinuousDirt", true, false) != null and road_view.find_child("WheelRut", true, false) != null, "completed roads use narrow continuous dirt and rut meshes without circular tile nodes")


func _check_barracks(failures: Array[String], game, fixture) -> void:
	var simulation = game.simulation_host.simulation
	var barracks := _find_building(simulation, Defs.BUILDING_BARRACKS)
	if barracks.is_empty():
		var site: Vector2i = fixture._ensure_site(simulation, Defs.BUILDING_BARRACKS, simulation.town_hall_position + Vector2i(13, 10))
		barracks = simulation._add_completed_building(Defs.BUILDING_BARRACKS, site)
		simulation._rebuild_occupied_tiles()
		simulation._recompute_road_network()
	_check(failures, Catalog.building_path(Defs.BUILDING_BARRACKS) != Catalog.building_path(Defs.BUILDING_TOWN_HALL) and "barracks" in Catalog.building_path(Defs.BUILDING_BARRACKS).to_lower(), "Barracks uses a distinct military building asset rather than the Town Hall silhouette")
	barracks["connected"] = true
	barracks["assigned_staff"] = Defs.building_staff(Defs.BUILDING_BARRACKS)
	barracks["staffed"] = true
	simulation.population_current = maxi(simulation.population_current, simulation.workers_assigned + simulation.soldiers_total + 3)
	simulation.soldiers_total = 0
	simulation.central_inventory[Defs.RESOURCE_BREAD] = 12
	simulation.central_inventory[Defs.RESOURCE_PLANKS] = 0
	var bread_before := int(simulation.central_inventory[Defs.RESOURCE_BREAD])
	var planks_before := int(simulation.central_inventory[Defs.RESOURCE_PLANKS])
	simulation._update_barracks(simulation.BARRACKS_TRAIN_SECONDS + 0.1)
	_check(failures, simulation.soldiers_total == 1 and int(simulation.central_inventory[Defs.RESOURCE_BREAD]) == bread_before - simulation.SOLDIER_BREAD_COST, "Barracks trains one recruit with Bread and time")
	_check(failures, int(simulation.central_inventory[Defs.RESOURCE_PLANKS]) == planks_before and simulation.SOLDIER_PLANK_COST == 0, "Planks are construction material, not a recurring soldier-training input")
	game._initialize_presentation()
	game.select_building(int(barracks.get("id", 0)))
	var view = game.world_view.building_views.get(int(barracks.get("id", 0)))
	var military_yard := view != null and view.find_child("BarracksTrainingYard", true, false) != null and view.find_child("BarracksWeaponRack", true, false) != null and view.find_child("BarracksTrainingTarget", true, false) != null
	_check(failures, military_yard, "Barracks wrapper includes a training yard, weapon racks, and target")
	var inspector: String = game.inspector_label.text
	_check(failures, "Recruit" in inspector and "Bread" in inspector and "Training" in inspector and not "plank" in inspector.to_lower(), "Barracks inspector explains recruit, Bread, and training progress without a Planks requirement")


func _check_hostiles(failures: Array[String], game, fixture) -> void:
	var simulation = game.simulation_host.simulation
	var origin := _find_clear_test_area(simulation, 7)
	_check(failures, origin.x >= 0, "a clear route test area exists")
	if origin.x >= 0:
		for y in range(origin.y, origin.y + 7):
			for x in range(origin.x, origin.x + 7):
				simulation._prepare_test_tile(Vector2i(x, y), Defs.TILE_GRASS)
		var tree := origin + Vector2i(3, 3)
		simulation._prepare_test_tile(tree, Defs.TILE_TREE)
		simulation.path_grid_dirty = true
		var path: Array = simulation._find_weighted_path(origin + Vector2i(1, 3), [origin + Vector2i(5, 3)], true)
		var avoids_tree := not path.is_empty() and not tree in path
		for step_value in path:
			avoids_tree = avoids_tree and simulation._is_enemy_walkable(Vector2i(step_value))
		_check(failures, avoids_tree, "authoritative hostile routing goes around tree and building occupancy")
	var enemy := {
		"id": 901, "enemy_type": simulation.ENEMY_RAIDER, "position": simulation.town_hall_position + Vector2i(7, 0),
		"path": [simulation.town_hall_position + Vector2i(6, 0)], "move_elapsed": 0.1, "hp": 40, "max_hp": 40,
		"hit_until": 0.0, "attack_flash": 0.0, "retreating": false,
	}
	simulation._reveal_radius(Vector2i(enemy.position), 3)
	var descriptor: Dictionary = Adapter.new().enemy_descriptor(enemy, simulation)
	_check(failures, String(descriptor.get("state", "")) == Adapter.RUN and String(descriptor.get("tool", "")) == "axe" and String(descriptor.get("faction", "")) == "hostile", "visible Raider presents as an armed, running hostile")
	_check(failures, Vector2(descriptor.get("presentation_offset", Vector2.ZERO)) != Vector2.ZERO, "hostile group presentation applies restrained formation spacing")


func _check_sovereign(failures: Array[String], game) -> void:
	var simulation = game.simulation_host.simulation
	var removed_move: Dictionary = simulation.set_player_sovereign_target(simulation.town_hall_position)
	var removed_extract: Dictionary = simulation.request_player_wyrd_extraction()
	game._sync_presentation()
	var has_sovereign := false
	for value in game.current_frame_snapshot.get("combatants", []):
		has_sovereign = has_sovereign or "sovereign" in String(Dictionary(value).get("worker_type", ""))
	_check(failures, not bool(removed_move.get("success", false)) and not bool(removed_extract.get("success", false)), "direct Sovereign movement and extraction commands are removed")
	_check(failures, game.ui_layer.find_child("SovereignFocus", true, false) == null and not has_sovereign, "normal HUD and world presentation contain no player Sovereign")


func _check_selection_priority(failures: Array[String], game) -> void:
	var worker_snapshot := {}
	for value in game.current_frame_snapshot.get("workers", []):
		if bool(Dictionary(value).get("visible", true)):
			worker_snapshot = Dictionary(value)
			break
	if worker_snapshot.is_empty():
		_check(failures, false, "worker selection snapshot exists")
		return
	var logical := Vector2(worker_snapshot.get("logical_position", Vector2.ZERO))
	var raider := worker_snapshot.duplicate(true)
	raider["id"] = 888888
	raider["worker_type"] = "enemy_raider"
	raider["selection_kind"] = "enemy"
	raider["logical_position"] = logical + Vector2(1.5, 0.0)
	game.current_frame_snapshot["combatants"] = [raider]
	game.current_frame_snapshot["workers"] = []
	var raider_screen: Vector2 = game.camera_rig.camera.unproject_position(game.world_view.tile_to_world(Vector2(raider.logical_position)) + Vector3.UP * 1.15)
	_check(failures, String(game._screen_space_character_pick(raider_screen).get("kind", "")) == "enemy", "Raider remains directly selectable beside scenery")


func _check_audio_and_animation(failures: Array[String], game) -> void:
	var enemy_audio = game.audio_players.get("enemy")
	_check(failures, game.ambient_player != null and game.ambient_player.stream != null and enemy_audio != null and enemy_audio.stream != null, "settlement ambience and raid warning audio remain wired")
	_check(failures, float(enemy_audio.volume_db) >= -2.1, "raid warning audio has stronger priority than routine work sounds")
	var hostile_view = null
	for value in game.world_view.combatant_views.values():
		if String(value.current_faction) == "hostile":
			hostile_view = value
			break
	_check(failures, hostile_view == null or hostile_view.animation_tree != null, "shared character animation architecture remains active for hostiles")


func _find_valid_road_route(simulation) -> Array[Vector2i]:
	for building_value in simulation.buildings:
		var building: Dictionary = building_value
		if String(building.get("type", "")) != Defs.BUILDING_ROAD or bool(building.get("construction", false)):
			continue
		var start := Vector2i(building.get("position", Vector2i.ZERO))
		for direction in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var route: Array[Vector2i] = [start, start + direction, start + direction * 2, start + direction * 3]
			var validation: Dictionary = simulation.validate_road_route(route)
			var new_sections := 0
			for segment_value in validation.get("segments", []):
				if not bool(Dictionary(segment_value).get("reuse", false)):
					new_sections += 1
			if bool(validation.get("success", false)) and new_sections >= 2:
				return route
	return []


func _find_clear_test_area(simulation, width: int) -> Vector2i:
	for y in range(2, simulation.map_size.y - width - 2):
		for x in range(2, simulation.map_size.x - width - 2):
			var clear := true
			for oy in width:
				for ox in width:
					var tile := Vector2i(x + ox, y + oy)
					if not simulation.get_building_at_tile(tile).is_empty() or (simulation.rivalry != null and simulation.rivalry.is_rivalry_occupied(tile)):
						clear = false
						break
				if not clear:
					break
			if clear:
				return Vector2i(x, y)
	return Vector2i(-1, -1)


func _road_plan_count(simulation) -> int:
	var count := 0
	for building_value in simulation.buildings:
		var building: Dictionary = building_value
		if bool(building.get("construction", false)) and String(building.get("planned_type", "")) == Defs.BUILDING_ROAD:
			count += 1
	return count


func _find_building(simulation, building_type: String) -> Dictionary:
	for building_value in simulation.buildings:
		var building: Dictionary = building_value
		if String(building.get("type", "")) == building_type and not bool(building.get("construction", false)):
			return building
	return {}


func _visible_control_text(node: Node) -> String:
	var parts: Array[String] = []
	if node is Control and not (node as Control).is_visible_in_tree():
		return ""
	if node is Label or node is Button or node is RichTextLabel:
		parts.append(String(node.text))
	for child in node.get_children():
		parts.append(_visible_control_text(child))
	return " ".join(parts)


func _check(failures: Array[String], condition: bool, label: String) -> void:
	print("%s %s" % ["PASS" if condition else "FAIL", label])
	if not condition:
		failures.append(label)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("PHASE3_1_UX_RESCUE_SMOKE PASS")
		quit(0)
	else:
		print("PHASE3_1_UX_RESCUE_SMOKE FAIL count=%d" % failures.size())
		quit(1)
