# Scorecard Phase 3 R56 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per point
- Painted rock wall: detail_noise (the texture that reaches
  the steep face via height-projected UV, x*0.15/h*0.15)
  repainted with large painted strata bands (horizontal in
  texture = height bands on the face), 46 crack polylines,
  lichen/sunlit patches at painting scale. Hill close shows
  wavy painted strata following the face, less dependent on
  vertex facets. Side effect, honest: the same texture
  multiplies the meadow, so faint contour-like bands also
  show on foreground grass (soft, low contrast).
- Cliff ledges + crest: 8 geometry ledge bands (rock
  texture) across the east face, 7 jagged rock shells along
  the NE crest with small snow blobs only between rocks
  (crevices). Ledge bands are subtle at full frame; crest
  rocks read at the top-right ridge in the hill close.
- Strip bottom-right: fog density 0.0015 -> 0.0008 (hill
  also clearer). The far-ground strip is STILL faintly
  visible at the extreme corner — it is fog colour on the
  distant far plane, and at this point further fog cuts
  would flatten the whole frame's depth, so it was left;
  not sky/void, no hard edge.
- Full frame judge: right slope now carries painted strata
  + ledges + terraces + crest rocks over brown rock; it
  reads more like an illustrated worked slope than a bare
  shaded wall, still broader/thinner than target's steep
  mountain wall. Village left/centre unchanged/readable.
  No animals invented.

Perf round126: 283 draw calls, 462,589 prims, ~152,044
authored tris.

Rounds: 126 (full + hill close).
Screenshots: phase3/round126.png, round126_hill.png;
scorecard SCORECARD_PHASE3_R56.png.
