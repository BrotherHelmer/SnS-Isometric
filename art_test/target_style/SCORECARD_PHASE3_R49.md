# Scorecard Phase 3 R49 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Full-frame first-glance ranking (this round's method)
Judged round105 side-by-side vs target bottom half BEFORE
touching close-up polish. Re-ranked biggest gaps:
1. PALETTE at frame: roofs screamed bright red-orange, trees
   lime, saturation 1.24 — target is muted terracotta roofs,
   medium natural greens, warm earth. (Attacked this round.)
2. COMPOSITION/SCALE: target settlement is spread out with
   a winding dirt-path network and a steep brown mountain
   filling the right third; ours is a compact village, hill
   partly hidden behind the tree line, buildings/roofs
   larger relative to frame.
3. RENDER STYLE: painted illustration vs textured low-poly
   (the long-standing gap; close-up triangles are NOT in the
   top-3 at full frame and were deprioritised per brief).

## Actions (round106-107)
- Roof texture repainted muted terracotta (clay/brown/
  weathered shingle rows, soft edges); global saturation
  1.24 -> 1.10; leaf palette deepened (79c24d/a9dd77 ->
  4e8f33/7cb54f, tree variants likewise), canopy material
  tint balanced (0.88,0.92,0.84 in round107 after round106
  went too dark); canopy texture UV scale 0.5 -> 0.7 so
  painted clusters read larger inside the silhouette.
- Camera shifted right (look 1.6,-1.9 -> 3.4,-2.4, matched
  position) so hill/summit sit more in the right of frame.
- Rock warmed grey -> brown (8d8172 -> 8f7a5f, dark band
  5f4c38) toward target's brown scree (subtle in frame,
  hill is hazed/behind trees).
- Aprons: +7 irregular perimeter lobes per feature
  (alternating grass/dirt, offset radii) on top of R48's
  darkened stony patches — oval outline further broken at
  frame; hill close still shows the patch shape.
Result at full frame: roofs no longer dominate by colour,
trees read natural deep green, first-glance palette is
measurably closer to target. Composition (gap 2) and
render style (gap 3) are now the top remaining gaps.

Perf round107: 280 draw calls, 397,077 prims, ~153,752
authored tris. (Draws fell 287 -> 280 with the camera
shift/frustum.)

Rounds: 106 (palette+camera+apron lobes), 107 (rock brown,
canopy rebalance; full + hill close).
Screenshots: phase3/round106.png, round107.png,
round107_hill.png; scorecard SCORECARD_PHASE3_R49.png.
