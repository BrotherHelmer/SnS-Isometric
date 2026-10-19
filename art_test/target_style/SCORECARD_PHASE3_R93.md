# SCORECARD — Phase 3 R93 (round168): roofs + plaster/timber (internal only)

## My choice: roofs + timber/plaster building surfaces
After stone, these are the largest remaining uniform building surfaces.
Same proven principles as the stone work (large features, per-element value
variation, real joints), textures only. Stone R88-R92, R90 per-face warmth,
relief, background, terracotta material colours all unchanged.

## Roofs — 6.5/10
`roof_painted.png` repainted (seed 9301): individual tiles 210-430px wide in
varied-height courses (92-150px), per-tile value ±26 + warm spread within the
terracotta family, dark real joints, lit-top/shadow-bottom per tile, ~7% moss
tiles and ~10% worn tiles. Mean hue kept at the old muted terracotta
(~172/104/70 in-tile before material tints), so the R78 lesson holds: roofs
stay terracotta, distinct from warm stone walls, no bright red — the flat
slab/eave geometry colours were already muted in R78 and were not touched.
**Do roofs still read as flat slabs at full frame? Partly.** In close the
tiles + the modelled shingle-row relief read as individual shingles; at full
frame the castle cones are still dominated by the modelled rows and read
slab-leaning, though per-tile value breaks mean they are no longer flat colour.

## Plaster / timber — 6/10
`plaster_painted.png` repainted (seed 9311): warm cream base with 260 large
soft mottling blotches, 46 subtle plaster patch areas, faint cracks and sparse
speckle — hand-worked but soft, deliberately no strong pattern (plaster should
not compete with stone). `wood_painted.png` repainted (seed 9321): strong
planks (150-260px) with long grain streaks, knots, and dark plank joints,
replacing the fine cross-grain that averaged away.
**Per-face light variation for roof/plaster: not extended, honestly reported.**
Unlike stone in R90 (where faces told one uniform warm story because the
texture was the only variation), roofs/plaster already get per-face variation
from real directional shading plus modelled relief (shingle rows, timber
frames, plaster fans), and their materials are shared with non-building uses;
adding the normal-based shader there was judged unnecessary this round rather
than genuinely applicable.

**Overall honest self-score ~6.5/10. Not a Black PASS claim.**

## Perf
R93 round168: **275 draws / 312,749 prims / ~141,279 authored tris** — unchanged
(three textures repainted; no geometry/material keys added or removed).

Renders: evidence `phase3/round168.png` + `phase3/round168_close.png` (1280x800).
