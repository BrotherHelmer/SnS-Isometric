extends Node3D
var mode := "b"
func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mode="): mode = a.trim_prefix("--mode=")
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color("bfe3ef"); env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color.WHITE; env.ambient_light_energy = 0.6; we.environment = env; add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-52,-38,0); sun.light_energy = 1.0; add_child(sun)
	var cam := Camera3D.new(); cam.projection = Camera3D.PROJECTION_ORTHOGONAL; cam.size = 5.0; cam.look_at_from_position(Vector3(5,4.5,5), Vector3(0,0.7,0), Vector3.UP); cam.current = true; add_child(cam)
	var ground := MeshInstance3D.new(); var gm := BoxMesh.new(); gm.size = Vector3(10,0.1,10); ground.mesh = gm; ground.position.y = -0.06; var gmat := StandardMaterial3D.new(); gmat.albedo_color = Color("69b83f"); ground.material_override = gmat; add_child(ground)
	# prism identical construction to house roof (w=3,d=2.5,h=1.15) at y=0.9 on a small base
	var base := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(2.3,0.9,1.9); base.mesh = bm; base.position.y = 0.45; var bmat := StandardMaterial3D.new(); bmat.albedo_color = Color("e8d9b8"); base.material_override = bmat; add_child(base)
	var prism := _prism(3.0, 2.5, 1.15); prism.position = Vector3(0, 0.9, 0)
	var tex: Texture2D = load("res://art_test/prism_test/checker.png")
	var mat := StandardMaterial3D.new(); mat.albedo_texture = tex
	if mode == "c": mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if mode == "e": mat.uv1_scale = Vector3(2,2,1)
	if mode == "a":
		# merged path like house: SurfaceTool append_from, material via merged mesh instance
		var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES); st.append_from(prism.mesh, 0, Transform3D.IDENTITY)
		var mi := MeshInstance3D.new(); mi.mesh = st.commit(); mi.position = Vector3(0,0.9,0); mi.material_override = mat; add_child(mi)
		var chk: Array = mi.mesh.surface_get_arrays(0); print("TEST a merged uv_count=", (chk[Mesh.ARRAY_TEX_UV] as PackedVector2Array).size(), " surf_count=", mi.mesh.get_surface_count())
	elif mode == "d":
		prism.mesh.surface_set_material(0, mat); add_child(prism); print("TEST d mesh-surface material, instance override=", prism.material_override)
	else:
		prism.material_override = mat; add_child(prism)
	print("TEST mode=", mode, " mat=", mat, " albedo_tx=", mat.albedo_texture != null, " uv1_scale=", mat.uv1_scale, " filter=", mat.texture_filter)
	await get_tree().process_frame; await get_tree().process_frame; await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("/home/box/cos/evidence/2026-10-18-sns-visual-target/phase3/prism_test_" + mode + ".png")
	get_tree().quit()
func _prism(w: float, d: float, h: float) -> MeshInstance3D:
	var hw := w/2.0
	var A := Vector3(-hw,0,-d/2); var B := Vector3(-hw,0,d/2); var C := Vector3(0,h,-d/2); var D := Vector3(0,h,d/2)
	var E := Vector3(hw,0,-d/2); var F := Vector3(hw,0,d/2)
	var verts := PackedVector3Array(); var norms := PackedVector3Array(); var uvs := PackedVector2Array()
	for q in [[A,C,D,B],[F,D,C,E]]:
		var n: Vector3 = (q[1]-q[0]).cross(q[3]-q[0]).normalized(); if n.y < 0: n = -n
		var uvq := [Vector2(0,0), Vector2(0,1), Vector2(2,1), Vector2(2,0)]
		for idx in [0,1,2,0,2,3]: verts.append(q[idx]); norms.append(n); uvs.append(uvq[idx])
	var arrays := []; arrays.resize(Mesh.ARRAY_MAX); arrays[Mesh.ARRAY_VERTEX]=verts; arrays[Mesh.ARRAY_NORMAL]=norms; arrays[Mesh.ARRAY_TEX_UV]=uvs
	var mesh := ArrayMesh.new(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new(); mi.mesh = mesh; return mi
