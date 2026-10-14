extends SceneTree
## Prints merged mesh AABBs of VisualLab kit pieces (dev helper).
func _init():
	var names := ["kenney_ftk/wall-wood.glb","kenney_ftk/wall-wood-door.glb","kenney_ftk/wall-wood-window-shutters.glb","kenney_ftk/roof-high.glb","kenney_ftk/wall.glb","kenney_ftk/planks.glb","kenney_ftk/pillar-wood.glb","kenney_ftk/chimney.glb","kenney_ftk/fence.glb","kenney_ftk/cart.glb","quaternius_mvm/Wall_Plaster_Straight.gltf","quaternius_mvm/Wall_Plaster_Door_Flat.gltf","quaternius_mvm/Wall_Plaster_Window_Wide_Flat.gltf","quaternius_mvm/Wall_UnevenBrick_Straight.gltf","quaternius_mvm/Wall_Plaster_WoodGrid.gltf","quaternius_mvm/Corner_Exterior_Wood.gltf","quaternius_mvm/Floor_WoodDark.gltf","quaternius_mvm/Prop_Chimney.gltf"]
	for n in names:
		var ps: PackedScene = load("res://assets/visuallab/" + n)
		if ps == null:
			print("FAIL ", n); continue
		var inst: Node3D = ps.instantiate()
		var ab := AABB(); var first := true
		for m in inst.find_children("*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			var t := Transform3D(); var nd: Node = mi
			while nd != null and nd != inst:
				if nd is Node3D: t = (nd as Node3D).transform * t
				nd = nd.get_parent()
			var b: AABB = t * mi.get_aabb()
			ab = b if first else ab.merge(b); first = false
		print("%s pos=%s size=%s" % [n, str(ab.position), str(ab.size)])
	quit()
