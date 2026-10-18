# Scorecard Phase 3 R35 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per point
- Summit cleared shoulder: PARTIAL, still not showcased. _h now
  raises a smoothed shoulder knoll at the stones (crag damped
  85% nearby, +1.15 bump), with a pale worn-earth clearing disc
  (r2.8) + stone ring; occluding hut/tree moved off the sightline
  in round83. In the full frame the stones are at the extreme
  right edge, partly behind the slope tree line — silhouetted
  against ground, not sky/snow, and easy to miss. Diagnosis:
  at this camera the hill's x14–18 band projects to the frame
  edge; a visible summit needs to sit more central (x~12) or the
  composition needs the hill centred differently. Not solved.
- House bodies at distance: PARTIAL. Large-scale reads only:
  timber frame darkened (54381f) and widened (posts 0.17->0.25,
  rails 0.15->0.21), wall tint varies per house (cream/pale/
  ochre, reusing existing plaster keys), foundations taller
  (0.32->0.58 stone), windows bigger (0.52x0.60) with green
  shutters. At full frame houses are warmer/varied and windows
  read; bodies are still essentially boxes — proportion/read
  improved, form unchanged.
- Upper face density: IMPROVED. +6 slope trees, +3 contiguous
  field strips with rock outcrops across the mid-upper band,
  on top of R34 fill — upper third now has content throughout
  its width, though still thinner than the village and the
  strips read as flat bands on the slope.
- Lower-left: IMPROVED. Camera rebalanced back (target
  1.6,0.6,-1.9, size 24.5) and a lower-left farm added (2 field
  strips with rows, 2 trees) — the empty meadow corner is
  partly filled; bottom strip of frame is still open grass.
- Draw calls: 297 — OVER the <=290 goal (was 292). A trim pass
  (plain colours instead of textured field strips) did not
  reduce the count, because those keys were already shared;
  the growth is visible-instance count from added content.
  Reported honestly; no life removed to chase the number.
- Retained: segmented shingles (kept, R34 decision), castle,
  canopies, figures (19), geology/snow. No animals invented.

Perf round83: 297 draw calls, 359,303 prims, ~113,822 authored
tris (R34: 103,202; growth = fields/trees/shoulder content).

Rounds: 82 (shoulder, large house reads, density, farm),
83 (un-occlude + trim attempt).
Screenshots: phase3/round83.png, phase3/round82.png;
scorecard SCORECARD_PHASE3_R35.png.
