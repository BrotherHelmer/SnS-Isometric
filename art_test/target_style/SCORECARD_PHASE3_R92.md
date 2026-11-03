# SCORECARD — Phase 3 R92 (round167): large cells subdivided (internal only)

Reference: restored target, R91 round166. Full frame + roundhouse/castle close.
Method chosen: subdivide the very large cells in texture generation.

## Subdivision — 7.5/10
Two-pass generation (same R88/R89 seed family and warm colour sequence):
pass 1 computes the R88 Voronoi areas; the **21 cells >65,000px each receive
daughter seeds inside the cell** (2 daughters <105k, 3 <140k, 4 above;
daughter colours inherit the parent ±9 value), and the Voronoi is recomputed
so daughters are real stones with the same warm mortar joints as the rest of
the rubble. Result: 83 -> 114 stones; **cell areas min/median/max now
10,868 / 35,112 / 79,885px** (max was 163,208) — varied-area distribution
kept (max/median still 2.3x, daughters are medium-large), medium/small layout
unchanged except where a subdivided cell bordered them. R91's internal
mottling/joints pass is retained on the 8 cells that remain >65k after
subdivision. Warm palette, per-face stone shader (R90), and all relief are
untouched.
**Verification as asked:** roundhouse close — the drum now shows jointed
daughter stones across the formerly blank area; there is **no single large
pale identifiable stone and no empty area next to the relief** (a medium pale
stone remains, but jointed and neighboured like the rest of the rubble).
Castle close does **not** read noisy: subdivision only touched the 21 largest
cells, daughters are 0.3-0.6u-equivalent, in the relief's size family.

**Overall honest self-score ~6.5/10. Not a Black PASS claim.**

## Perf
R92 round167: **275 draws / 312,749 prims / ~141,279 authored tris** — unchanged
(texture-only; clone .import/project.godot noise unstaged).

Renders: evidence `phase3/round167.png` + `phase3/round167_close.png` (1280x800).
