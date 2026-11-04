import bpy,glob,os
from mathutils import Vector
D="/workspace/sns-visual-rescue-gate-b/checkout/assets/settlement3d/runtime/buildings/"
for f in sorted(glob.glob(D+"*.gltf")):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=f)
    ms=[o for o in bpy.data.objects if o.type=='MESH']
    tri=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in ms)
    pts=[o.matrix_world@Vector(c) for o in ms for c in o.bound_box]
    mn=[min(p[i] for p in pts) for i in range(3)];mx=[max(p[i] for p in pts) for i in range(3)]
    mats=sorted({m.name for o in ms for m in o.data.materials if m})
    imgs=sorted({i.name for i in bpy.data.images})
    print("INV|%s|%d|%d|%.2fx%.2fx%.2f|%s|%s"%(os.path.basename(f),len(ms),tri,mx[0]-mn[0],mx[1]-mn[1],mx[2]-mn[2],",".join(mats)[:80],",".join(imgs)))
