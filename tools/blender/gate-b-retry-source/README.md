# Gate B retry — A+C Town Hall kitbash
Rebuild: `/home/box/bin/blender -b --python scripts/build_town_hall.py -- <checkout> <outdir>` (deterministic; ~40 s). Inventory: `scripts/inv.py`.
Output: `glb/sns_town_hall_kitbash.glb` (Y-up, single mesh, embedded recoloured atlas `sns_nordic_atlas`, origin at base centre, metres). Godot: drop in, scale 1, replace TH view mesh; footprint 2.46×2.67, h 2.80.
`blender-preview/*.png` are Blender EEVEE renders — NOT in-engine evidence. In-engine identical-camera compare vs GATE-B/baseline/day.png still to do (cloud agent).
