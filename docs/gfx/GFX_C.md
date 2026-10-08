# GFX-C: full graphics overhaul (presentation only)

Stacked on GFX-B (`cursor/gfx-b-visual-pass-9d8f`). North star: the
Farthest Frontier–like Nordic diorama (`concept_1.png`).
No RTS rewrite, no scout / night-guard / raider-outline gameplay, no
Master-volume change, no `.github/workflows` edits.

## Shipped

- **Buildings remeshed** inside existing `BUILDING_UNIT_SIZE` AABBs: pale
  masonry, steep slate / terracotta roofs, thicker half-timber, distinct
  farm barn, civic keep, watchtower and barracks. Construction / occupancy
  cues unchanged.
- **Tree kit**: authored fir / fir_tall / spruce / broadleaf / oak / birch
  plus LOD pair for the edge forest. KayKit cones left the live kit.
  Foliage shader splits trunk vs canopy and lifts living greens.
- **Terrain**: greener authored meadow, stronger macro / meadow patches.
  Dirt and wheat stay.
- **Water**: teal-green deep / shallow, brighter foam, light ripple on
  Recommended (cheap path still freezes swell at night).
- **Lighting**: slightly warmer day key. High quality adds subtle glow and
  softer shadow blur. Recommended still has glow / SSIL / volumetrics off.
- **Units**: role-tinted fresnel rim so settlers, guards and raiders read
  at isometric zoom without the parallel outline branch.
- **HUD**: thicker gold hairline, more opaque navy console.

## Still off on Recommended

SDFGI, volumetric fog, PCSS, SSIL, glow. RTX 4070 is the target; glow
only behind the High quality toggle.
