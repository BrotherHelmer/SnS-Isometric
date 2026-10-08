extends SceneTree

const Catalog = preload("res://src/GodotClient3D/Scripts/production_asset_catalog.gd")
const Profile = preload("res://src/GodotClient3D/Scripts/production_scale_profile.gd")
const View = preload("res://src/GodotClient3D/Scripts/production_building_view_3d.gd")
const OUT := "res://artifacts/opening_style"
var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	for kind in ["TOWN_HALL", "HOUSE", "STOREHOUSE", "LUMBER_CAMP", "BAKERY", "WATCHTOWER", "FARM", "SAWMILL", "CLAIMANT_OUTPOST", "QUARRY", "BARRACKS", "LUMEN_PILLAR", "ENEMY_CAMP"]:
		var packed := load(Catalog.building_path(kind)) as PackedScene
		check(packed != null, kind + " loads")
		var model := packed.instantiate()
		var mesh: Mesh = model.get_node("Model").mesh
		check(mesh.get_aabb().size.is_equal_approx(Profile.BUILDING_UNIT_SIZE[kind]), kind + " matches socket and selection bounds")
		check(absf(mesh.get_aabb().position.y) < 0.001, kind + " grounded")
		model.free()
		var view := View.new()
		root.add_child(view)
		var snapshot := {"id": 12, "type": kind, "footprint": Vector2i(4, 4), "rotation": 1, "construction": false, "hp": 80, "max_hp": 100}
		view.configure(snapshot)
		check(view.model_root != null and view.selection_area != null, kind + " playable selection")
		check(view.sockets.has("carrier_dropoff"), kind + " delivery socket")
		snapshot["construction"] = true
		snapshot["construction_fraction"] = 0.4
		view.apply_snapshot(snapshot)
		check(view.construction_root != null, kind + " construction")
		snapshot["construction"] = false
		view.apply_snapshot(snapshot)
		check(view.model_root != null, kind + " completes")
		view.queue_free()
	var wall := View.new()
	root.add_child(wall)
	wall.configure({"id": 99, "type": "WALL", "footprint": Vector2i.ONE, "wall_mask": 15, "hp": 100, "max_hp": 100})
	var arms := {}
	for part in wall.model_root.get_children():
		if part.get_child_count() == 3:
			arms[Vector2i(roundi(part.position.x), roundi(part.position.z))] = true
	check(arms.has(Vector2i(0, -1)) and arms.has(Vector2i(1, 0)) and arms.has(Vector2i(0, 1)) and arms.has(Vector2i(-1, 0)), "wall arms follow all four connection directions")
	wall.queue_free()
	for label in ["fir", "fir_tall", "spruce", "broadleaf", "oak", "birch", "fir_lod", "broadleaf_lod", "rocks", "fence", "lantern", "cart", "grass", "bush", "wheat"]:
		var packed := load("res://assets/settlement3d/runtime/opening_style/" + label + ".tscn") as PackedScene
		var model := packed.instantiate()
		check(model.get_child_count() == 1 and model.get_child(0) is MeshInstance3D, label + " single merged mesh compatible with nature instancing")
		model.free()
	await process_frame
	if DisplayServer.get_name() != "headless":
		await gallery()
	if failures.is_empty():
		print("OPENING_STYLE_TEST PASS bounds, construction, completion, selection, sockets and merged props")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)

func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func gallery() -> void:
	root.size = Vector2i(1600, 1000)
	DisplayServer.window_set_size(root.size)
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("253c40")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("b5c8d3")
	environment.environment.ambient_light_energy = 0.55
	environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	stage.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color("ffdfa9")
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	stage.add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(38, 29)
	floor_mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("62684c")
	floor_mesh.material_override = mat
	stage.add_child(floor_mesh)
	var kinds := ["TOWN_HALL", "HOUSE", "STOREHOUSE", "LUMBER_CAMP", "BAKERY", "WATCHTOWER"]
	for i in kinds.size():
		var kind: String = kinds[i]
		var model := (load(Catalog.building_path(kind)) as PackedScene).instantiate() as Node3D
		model.scale = Vector3.ONE * Profile.building_scale(kind)
		model.position = Vector3((i % 3 - 1) * 9, 0, (i / 3) * 9 - 5)
		stage.add_child(model)
	for i in 6:
		var label: String = ["fir", "broadleaf", "rocks", "fence", "lantern", "cart"][i]
		var model := (load("res://assets/settlement3d/runtime/opening_style/" + label + ".tscn") as PackedScene).instantiate() as Node3D
		model.position = Vector3((i - 2.5) * 4.3, 0, 11)
		stage.add_child(model)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 38
	camera.position = Vector3(21, 29, 39)
	camera.look_at(Vector3(0, 1.3, 2))
	camera.current = true
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + "/model_gallery.png")
	stage.queue_free()
	await process_frame
