# SnS Nordic Diorama kit - pure procedural, CC0. Run: blender -b -P build_kit.py -- <outdir>
import bpy, bmesh, math, sys, os
from mathutils import Vector
argv = sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
OUT = os.path.abspath(argv[0] if argv else os.path.join(os.path.dirname(__file__), ".."))
PAL = {"stone":"#b8b4a8","stone_dk":"#8f8a7e","roof":"#c23b2a","thatch":"#d9a84e","timber":"#6b4423",
       "plaster":"#efe3c8","leaf":"#5fa83a","leaf_lt":"#8fd14f","pine":"#3f8a4a","dirt":"#c9a86a","window":"#3a2a1e","log":"#a0703f"}
def hexc(h): h=h.lstrip('#'); return tuple(((int(h[i:i+2],16)/255)**2.2) for i in (0,2,4))+(1,)
MATS={}
def mat(n):
    if n not in MATS:
        m=bpy.data.materials.new("sns_"+n); m.use_nodes=True
        b=m.node_tree.nodes["Principled BSDF"]; b.inputs["Base Color"].default_value=hexc(PAL[n]); b.inputs["Roughness"].default_value=0.85
        MATS[n]=m
    return MATS[n]
def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True); MATS.clear()
def fin(o,m,bev=0.0,seg=1):
    o.data.materials.append(mat(m))
    if bev:
        md=o.modifiers.new("b","BEVEL"); md.width=bev; md.segments=seg; md.limit_method='ANGLE'
    return o
def box(m,loc,size,bev=0.04,rot=(0,0,0)):
    bpy.ops.mesh.primitive_cube_add(location=loc,rotation=rot); o=bpy.context.object; o.scale=(size[0]/2,size[1]/2,size[2]/2)
    bpy.ops.object.transform_apply(scale=True); return fin(o,m,bev)
def cyl(m,loc,r,h,v=12,bev=0.03,r2=None):
    if r2 is None: bpy.ops.mesh.primitive_cylinder_add(vertices=v,radius=r,depth=h,location=(loc[0],loc[1],loc[2]+h/2))
    else: bpy.ops.mesh.primitive_cone_add(vertices=v,radius1=r,radius2=r2,depth=h,location=(loc[0],loc[1],loc[2]+h/2))
    return fin(bpy.context.object,m,bev)
def cone(m,loc,r,h,v=12): return cyl(m,loc,r,h,v,0,0.0)
def gable(m,loc,w,d,h,over=0.15,rotz=0):
    # triangular prism roof, ridge along Y
    bm=bmesh.new(); w2=w/2+over; d2=d/2+over
    vs=[bm.verts.new(p) for p in [(-w2,-d2,0),(w2,-d2,0),(0,-d2,h),(-w2,d2,0),(w2,d2,0),(0,d2,h)]]
    for f in [(0,1,2),(5,4,3),(0,3,4,1),(1,4,5,2),(2,5,3,0)]: bm.faces.new([vs[i] for i in f])
    me=bpy.data.meshes.new("roof"); bm.to_mesh(me); o=bpy.data.objects.new("roof",me); bpy.context.collection.objects.link(o)
    o.location=loc; o.rotation_euler=(0,0,rotz); bpy.context.view_layer.objects.active=o; o.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT'); bpy.ops.mesh.solidify() if False else None
    bpy.ops.mesh.normals_make_consistent(inside=False); bpy.ops.object.mode_set(mode='OBJECT')
    return fin(o,m,0.03)
def export(name):
    bpy.ops.object.select_all(action='SELECT')
    for o in bpy.context.selected_objects:
        for md in o.modifiers: pass
    bpy.context.view_layer.objects.active=bpy.context.selected_objects[0]
    bpy.ops.object.convert(target='MESH'); bpy.ops.object.join()
    o=bpy.context.object; o.name=name
    bpy.ops.object.shade_flat()
    p=os.path.join(OUT,"glb",name+".glb")
    bpy.ops.export_scene.gltf(filepath=p,export_format='GLB',export_yup=True,export_apply=True)
    dg=bpy.context.evaluated_depsgraph_get(); tri=sum(len(pl.vertices)-2 for pl in o.data.polygons)
    preview(name); print(f"KIT {name} tris={tri} -> {p}"); return tri
def preview(name):
    sc=bpy.context.scene; o=bpy.context.object
    r=max(o.dimensions)*1.0
    cam=bpy.data.objects.new("cam",bpy.data.cameras.new("cam")); sc.collection.objects.link(cam)
    cam.data.type='ORTHO'; cam.data.ortho_scale=r*1.6
    cam.location=(r*2,-r*2,r*1.9+o.dimensions.z/2); cam.rotation_euler=(math.radians(55),0,math.radians(45)); sc.camera=cam
    sun=bpy.data.objects.new("sun",bpy.data.lights.new("sun","SUN")); sun.data.energy=4; sun.rotation_euler=(math.radians(50),0,math.radians(30)); sc.collection.objects.link(sun)
    w=bpy.data.worlds.new("w"); sc.world=w; w.use_nodes=True; w.node_tree.nodes["Background"].inputs[0].default_value=(0.75,0.82,0.9,1); w.node_tree.nodes["Background"].inputs[1].default_value=0.8
    sc.render.engine='BLENDER_EEVEE_NEXT'; sc.render.resolution_x=sc.render.resolution_y=512
    sc.render.filepath=os.path.join(OUT,"preview",name+"_blender-preview.png"); bpy.ops.render.render(write_still=True)

def town_hall():
    reset()
    box("stone_dk",(0,0,0.15),(4.4,3.4,0.3))
    box("stone",(0,0,1.6),(3.0,2.2,2.6))              # hall body
    gable("roof",(0,0,2.9),3.0,2.2,1.6,rotz=math.pi/2)
    box("stone",(0,0,2.6),(1.4,1.4,4.6))               # central keep
    cone("roof",(0,0,4.9),1.15,2.2,8)
    for x,y,s in [(-1.7,-1.3,1),(1.7,-1.3,1),(-1.7,1.3,.85),(1.7,1.3,.85)]:
        cyl("stone",(x,y,0.3),0.55*s,3.2*s,10)
        cone("roof",(x,y,0.3+3.2*s),0.75*s,1.6*s,10)
    box("timber",(0,-1.12,0.95),(0.8,0.1,1.3))         # door
    for x in (-1,1): box("window",(x,-1.12,2.0),(0.35,0.08,0.55),0.01)
    return export("sns_town_hall")
def house():
    reset()
    box("stone_dk",(0,0,0.25),(2.1,1.7,0.5))
    box("plaster",(0,0,1.0),(2.0,1.6,1.1))
    for x in (-0.95,0.95):
        for y in (-0.75,0.75): box("timber",(x,y,1.0),(0.14,0.14,1.1),0.02)
    box("timber",(0,-0.8,1.5),(2.0,0.08,0.12),0.01)
    gable("roof",(0,0,1.55),2.0,1.6,1.5)
    box("stone",(0.55,0.4,2.4),(0.35,0.35,1.2))        # chimney
    box("timber",(0,-0.82,0.8),(0.5,0.06,0.9),0.01)
    box("window",(-0.6,-0.82,1.05),(0.3,0.05,0.3),0.01)
    return export("sns_house")
def lumber_camp():
    reset()
    box("dirt",(0,0,0.03),(3.6,2.6,0.06),0.02)
    for x in (-1.2,1.2):
        for y in (-0.7,0.7): cyl("timber",(x,y,0),0.09,1.6,6,0)
    gable("thatch",(0,0,1.6),2.4,1.4,0.7,0.2,rotz=math.pi/2)
    for i in range(3):                                 # log pile
        for j in range(3-i): 
            bpy.ops.mesh.primitive_cylinder_add(vertices=8,radius=0.14,depth=1.4,location=(-0.3+j*0.29+i*0.145,1.45,0.14+i*0.25),rotation=(0,math.pi/2,0)); fin(bpy.context.object,"log")
    cyl("log",(1.3,-1.0,0.0),0.3,0.4,10)               # chopping stump
    box("timber",(1.3,-1.0,0.55),(0.05,0.05,0.5),0.01,rot=(0,0.4,0))
    return export("sns_lumber_camp")
def tree_pine():
    reset(); cyl("timber",(0,0,0),0.12,0.6,6,0)
    for i,(r,h) in enumerate([(0.9,1.1),(0.7,1.0),(0.45,0.9)]): cone("pine" if i!=1 else "leaf",(0,0,0.5+i*0.65),r,h,8)
    return export("sns_tree_pine")
def tree_round():
    reset(); cyl("timber",(0,0,0),0.12,1.0,6,0)
    for loc,r,m in [((0,0,1.5),0.75,"leaf"),((0.35,0.2,1.85),0.5,"leaf_lt"),((-0.3,-0.2,1.3),0.5,"leaf")]:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=r,location=loc); fin(bpy.context.object,m)
    return export("sns_tree_round")
def path_strip():
    reset(); bpy.ops.mesh.primitive_grid_add(x_subdivisions=8,y_subdivisions=2,size=1)
    o=bpy.context.object; o.scale=(4,0.8,1); bpy.ops.object.transform_apply(scale=True)
    for v in o.data.vertices: v.co.y+=0.12*math.sin(v.co.x*1.7); v.co.z=0.01
    fin(o,"dirt"); return export("sns_path_strip")
tris={f():0 for f in []}
res={n:f() for n,f in [("town_hall",town_hall),("house",house),("lumber_camp",lumber_camp),("tree_pine",tree_pine),("tree_round",tree_round),("path_strip",path_strip)]}
open(os.path.join(OUT,"TRIS.txt"),"w").write("\n".join(f"{k}: {v} tris" for k,v in res.items())+"\n")
print("KIT DONE",res)
