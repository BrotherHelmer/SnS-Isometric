# Rebuild: blender -b --python build_town_hall.py -- <checkout> <outdir>
import bpy,sys,os,colorsys
from mathutils import Vector
a=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
CK=a[0] if a else "/workspace/sns-visual-rescue-gate-b/checkout"
OUT=a[1] if len(a)>1 else "/workspace/sns-visual-rescue-gate-b/retry/out"
os.makedirs(OUT,exist_ok=True)
B=CK+"/assets/settlement3d/runtime/buildings/"
bpy.ops.wm.read_factory_settings(use_empty=True)
def imp(n):
    pre=set(bpy.data.objects); bpy.ops.import_scene.gltf(filepath=B+n)
    return [o for o in bpy.data.objects if o not in pre and o.type=='MESH']
def bb(objs):
    p=[o.matrix_world@Vector(c) for o in objs for c in o.bound_box]
    return Vector([min(v[i] for v in p) for i in range(3)]),Vector([max(v[i] for v in p) for i in range(3)])
hall=imp("building_barracks_green.gltf")   # foundation: KayKit CC0 hall
# polish: strip barracks military props (weapon rack left of door, crossed-swords shield above door)
import bmesh
h=hall[0]; bm=bmesh.new(); bm.from_mesh(h.data); bm.verts.ensure_lookup_table()
seen=set(); kill=[]
for v0 in bm.verts:
    if v0.index in seen: continue
    isl=[];st=[v0];seen.add(v0.index)
    while st:
        v=st.pop();isl.append(v)
        for e in v.link_edges:
            w=e.other_vert(v)
            if w.index not in seen: seen.add(w.index);st.append(w)
    W=[h.matrix_world@v.co for v in isl]
    mn=[min(p[i] for p in W) for i in range(3)];mx=[max(p[i] for p in W) for i in range(3)]
    c=[(mn[i]+mx[i])/2 for i in range(3)];dim=max(mx[i]-mn[i] for i in range(3))
    rack=-0.46<c[0]<-0.21 and c[1]<-0.69 and c[2]<0.36 and dim<0.3
    shield=abs(c[0])<0.32 and c[1]<-0.6 and 0.5<c[2]<1.0 and dim<0.5
    if rack or shield: kill+=isl
bmesh.ops.delete(bm,geom=list(set(kill)),context='VERTS'); bm.to_mesh(h.data); bm.free()
print("POLISH removed verts",len(set(kill)))
tower=imp("building_tower_A_green.gltf")   # kitbash: KayKit CC0 tower as bell tower
for o in tower: o.scale=(0.85,0.85,0.85)
bpy.context.view_layer.update()
hmn,hmx=bb(hall); tmn,tmx=bb(tower)
# place tower at rear-right corner, base flush with hall base
off=Vector((hmx.x-0.30-(tmn.x+tmx.x)/2, hmx.y-0.20-(tmn.y+tmx.y)/2, hmn.z-tmn.z))  # rear-right corner, embedded in rear wall
for o in tower: o.location+=off
bpy.context.view_layer.update()
objs=hall+tower
# recolour atlas -> Nordic Diorama palette (roof red #c23b2a, stone #b8b4a8, timber)
img=next(i for i in bpy.data.images if "hexagons" in i.name)
nimg=img.copy(); nimg.name="sns_nordic_atlas"
px=list(nimg.pixels); RED=(0xc2/255,0x3b/255,0x2a/255); ST=(0xb8/255,0xab/255,0x93/255)  # #b8b4a8 warmed toward limestone
for i in range(0,len(px),4):
    r,g,b=px[i:i+3]; h,s,v=colorsys.rgb_to_hsv(r,g,b)
    if 0.17<h<0.50 and s>0.25:            # green roofs/trim -> Nordic red, keep shading
        k=v/0.6; px[i:i+3]=[min(1,c*k) for c in RED]
    elif s<0.15 and v>0.3:                # grey stone -> warm light limestone
        k=min(1.05,v/0.72); px[i:i+3]=[min(1,c*k) for c in ST]
    elif 0.03<h<0.12 and s>0.3:           # wood -> darker tarred Nordic timber
        px[i:i+3]=[r*0.75,g*0.62,b*0.55]
nimg.pixels[:]=px; nimg.pack()
for m in bpy.data.materials:
    if m.use_nodes:
        for n in m.node_tree.nodes:
            if n.type=='TEX_IMAGE' and n.image==img: n.image=nimg
        bsdf=m.node_tree.nodes.get("Principled BSDF")
        if bsdf: bsdf.inputs["Roughness"].default_value=0.85
# join, bevel + weighted normals (preserve detail, soften edges)
bpy.ops.object.select_all(action='DESELECT')
for o in objs: o.select_set(True)
bpy.context.view_layer.objects.active=hall[0]; bpy.ops.object.join()
ob=bpy.context.active_object; ob.name="sns_town_hall_kitbash"
bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
bv=ob.modifiers.new("bevel","BEVEL"); bv.width=0.012; bv.segments=2; bv.limit_method='ANGLE'
ob.modifiers.new("wn","WEIGHTED_NORMAL").keep_sharp=True
bpy.ops.object.modifier_apply(modifier="bevel"); bpy.ops.object.modifier_apply(modifier="wn")
# normalize to SnS Town Hall footprint 3.0 x 3.7 (ground) x 2.8 m tall (Blender Z-up), base at 0, centred
mn,mx=bb([ob]); d=mx-mn
s=min(3.0/d.x,3.7/d.y,2.8/d.z)
ob.scale=(s,s,s); bpy.ops.object.transform_apply(scale=True)
mn,mx=bb([ob]); ob.location-=Vector(((mn.x+mx.x)/2,(mn.y+mx.y)/2,mn.z))
bpy.ops.object.transform_apply(location=True)
mn,mx=bb([ob]); d=mx-mn
tri=sum(len(p.vertices)-2 for p in ob.data.polygons)
open(OUT+"/stats.txt","w").write("dims_m %.2f x %.2f x %.2f (w x d x h)\ntris %d\nscale %.3f\n"%(d.x,d.y,d.z,tri,s))
bpy.ops.export_scene.gltf(filepath=OUT+"/sns_town_hall_kitbash.glb",export_format='GLB',export_yup=True,use_selection=True)
# previews (blender-preview, not in-engine)
sc=bpy.context.scene; sc.render.engine='BLENDER_EEVEE_NEXT'; sc.render.resolution_x=1280; sc.render.resolution_y=960
w=bpy.data.worlds.new("w"); sc.world=w; w.use_nodes=True; w.node_tree.nodes["Background"].inputs[0].default_value=(0.62,0.68,0.74,1)
bpy.ops.mesh.primitive_plane_add(size=12); g=bpy.context.active_object
gm=bpy.data.materials.new("ground"); gm.diffuse_color=(0.36,0.42,0.26,1); g.data.materials.append(gm)
bpy.ops.object.light_add(type='SUN',rotation=(0.9,0.2,0.8)); bpy.context.active_object.data.energy=4
cam=bpy.data.cameras.new("c"); cam.type='ORTHO'; cam.ortho_scale=6.5
co=bpy.data.objects.new("c",cam); sc.collection.objects.link(co); sc.camera=co
for name,loc in [("iso",(8,-8,7)),("iso_back",(-8,8,7)),("front",(0,-11,5))]:
    co.location=loc; dirv=Vector((0,0,1.2))-Vector(loc); co.rotation_euler=dirv.to_track_quat('-Z','Y').to_euler()
    sc.render.filepath=OUT+"/blender-preview_%s.png"%name; bpy.ops.render.render(write_still=True)
