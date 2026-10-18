# Scorecard Phase 3 R24 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per point
- Watchtower/terraces: IMPROVED. Watchtower moved from behind the
  crest (17,-11) to the visible hill shoulder (14.2,-6.9) beside the
  mine, then raised in round67 (legs 3.2->4.2, cabin/cone up) — it
  now reads as a timber watchtower with red cone in frame, like
  target's hill tower. Terraces enlarged to 4 strips (4.4 wide) with
  retaining edges and 4 crop rows each in alternating green/soil;
  they read as field strips on the lower slope, still subtle at
  full frame but no longer invisible.
- House variety: IMPROVED. _build_house is now parametric by
  position-hash variant (3 variants): footprint width 0.84/1.0/1.18,
  variant 2 is two-storey (wall 2.45, extra window row, taller),
  roof pitch 0.95/1.15/1.35, roof tint varies per house
  (3 albedo variants in the instance commit), lean-to side
  alternates (variant 1 reads L-shaped). Top-left two-storey vs
  smaller cottages is visible in frame — village no longer cloned.
  Orientations still all face +z (merged-geometry limit).
- Prop density: IMPROVED. Per-house gardens (6 crop blobs + barrel),
  stone door paths (stepping discs), 2 laundry lines with cloth,
  10 scattered barrels/crates, plus R23 cart/well/log piles/fences/
  sacks. Trees now vary size (0.85–1.30 scale by hash). Empty grass
  is largely filled; still fewer/smaller props than target's dense
  tiny-detail world, and figures remain 6 carriers + 3 statics.
- Retained: composition, mine/switchback, castle, roofs, canopies,
  grade, tufts (900, 1 draw). No animals invented.

Perf round67: 207 draw calls (cap raised to ~220 this round for
content; growth is merged geometry, tufts still 1 draw),
140,383 prims, ~42,014 authored tris. Buildings <1500 tri each.

Rounds: 66 (tower moved, house variety, gardens/laundry/scatter),
67 (tower raised).
Screenshots: phase3/round67.png, phase3/round66.png;
scorecard SCORECARD_PHASE3_R24.png.
