# Phase 3 R125 - Scorecard

## Choice (stated)
Continuous background woods at low prim cost - answering both halves of Black's
R124 note (target framing is continuous; canopy prims are the largest line item).

## Cost accounting (renderer prims, measured)
- Near tree (R124, _build_tree: 21 canopy spheres at 13x7 + lobes + trunk):
  +103,394 prims / 17 trees = ~6,080 prims per tree (round199 -> round200).
- Distant tree (R125, _build_tree_far: 4 crowns at 8x4 + thin trunk + disc):
  +21,344 prims / 29 trees = ~736 prims per tree (round200 -> round201).
- Distant construction is ~8x cheaper per tree. Draws unchanged at 283 in both
  steps (crowns merge into the single canopy mesh, trunks into existing keys).
- Totals: 495,717 (R123) -> 599,111 (R124) -> 620,455 (R125). Authored tris
  ~241,288 (far tree ~256 authored tris vs ~2,900 near).

## What was built
- canopy_sphere_low: the near crown's scalloped-lobe displacement on an 8x4
  sphere; add_canopy_low applies add_canopy's exact R114 cluster-tone law
  (quantized steps, flat cluster normals, sun/shade cluster split, R113 olive
  family) on the low mesh - cheaper geometry, same language, no smooth lumps.
- _build_tree_far: 4 low crowns + 6-seg trunk, stronger R80-style distance haze
  (0.45-0.60 lerp to the far palette), seated on _h.
- Placements screened as R124 (projection-checked, building/path clearances,
  apron >6.5u, mine crest open): back row of 11 behind the castle at z~-18
  (two depths), front far row of 8 filling between the R124 background trees,
  6 left-margin depth + 4 left-front far trees. Near framing (R124) unchanged.

## Verification
- Full frame: the top of frame is now a continuous dark treeline behind the
  castle running into the hill foot; left margin has depth; no building occluded,
  castle apron clear, mine crest and switchback open, carriers still visible.
- Far crowns at full frame read as hazy cluster masses in the same olive family;
  in hill close they are visibly simpler than near crowns (stated limit - they
  are not meant for close inspection, and no far tree sits in the close frame's
  focus area).

## Honest verdict
FAIL as an overall target match (still borderline ~6.5/10 expected). The valley
now reads as continuously wooded behind and to the left at ~1/8 the per-tree
cost Black flagged. Remainder: the target's woods are still denser and closer
around the settlement (its treeline hugs the village), while ours keeps a
clearing for the frozen layout; and total prims (620k) keep climbing with any
future density - the budget conversation is now prims, not draws.
