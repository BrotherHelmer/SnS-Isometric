# SnS Nordic Diorama Kit (Gate B, procedural, 0 DKK)
Rebuild (headless, ~65 s):
    /home/box/bin/blender -b -P scripts/build_kit.py -- /workspace/sns-visual-rescue-gate-b/kit
Outputs: glb/*.glb, preview/*_blender-preview.png (Blender EEVEE previews — NOT Gate B in-engine evidence), TRIS.txt.
Assets: sns_town_hall (846 tri), sns_house (472), sns_lumber_camp (484), sns_tree_pine (62), sns_tree_round (80), sns_path_strip (32).
Transform: authored Z-up in Blender, exported glTF +Y up (export_yup), modifiers applied, 1 unit = 1 m, origin at ground centre (footprint base z=0), front (door) faces -Y Blender = +Z Godot. Each GLB = one joined mesh, flat shading, multiple Principled materials named sns_<palette>. Godot: import as scene; scale 1; drop on tile centre.
Footprints (m): town hall ~4.4x3.4, house ~2.1x1.7, lumber camp ~3.6x2.6, trees ~1.8 dia.
Palette (sRGB hex, in script PAL): stone #b8b4a8, roof #c23b2a, thatch #d9a84e, timber #6b4423, dirt #c9a86a, leaf #5fa83a/#8fd14f, pine #3f8a4a, plaster #efe3c8.
