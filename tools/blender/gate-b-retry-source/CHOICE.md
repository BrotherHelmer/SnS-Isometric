# CHOICE — Town Hall
Foundation: **KayKit `building_barracks_green.gltf`** (4007 tri, real authored hall: buttressed stone base, arched timber door, banners, crenellations, hipped roof).
Kitbash: **KayKit `building_tower_A_green.gltf`** (2138 tri) scaled 0.62 and merged as corner tower → combined 8107 tri after bevel.
Why not civic_keep: it is project-procedural primitives (1788 tri, see INVENTORY) — exactly what Black forbade. Why not castle_green: 4 m tall castle silhouette collides with the separate Castle tier. home_A: too small/simple (1011 tri) for a founding hall.
Modifications (Blender 4.2.3): atlas recolour (green roofs→#c23b2a red with shading kept, grey stone→#b8b4a8, wood→darker tarred timber), roughness 0.85, angle bevel 1.2 cm ×2 + weighted normals, join, normalize, export GLB Y-up.
Scale: see polish pass below (supersedes first-pass figures).
Known issues (honest): tower lands near the front-left and adds the barracks crossed-swords shield → reads somewhat "castle/military"; stone reads near-white rather than warm limestone in preview. Fix candidates for next pass: move tower to rear, delete swords/weapon-rack islands, warmer stone tint. Not yet judged in-engine vs baseline/day.png.

## Polish pass 1 — LANDED (2026-11-04 20:34 CET)
- Tower moved to **rear-right**, scale 0.62→0.85, embedded into the rear wall (its timber-framed lookout cap now reads as a Nordic timber accent from the back).
- Deleted the crossed-swords shield above the door and the weapon rack by the door (860 verts removed via loose-island filter in script) → reads as hall, not barracks.
- Stone warmed: tint #b8ab93 (warm limestone variant of #b8b4a8), brightness capped so no chalk white.
- Result: **6914 tri, AABB 3.00 × 3.60 × 2.65 m** (w×d×h, Godot X×Z×Y), uniform scale 1.617, single mesh, Y-up GLB.
- Remaining concern: the tower's lookout cap overhangs the rear-right corner (visible in iso views); still reads castle-ish due to 5 crenellated turrets. Not yet judged in-engine.
