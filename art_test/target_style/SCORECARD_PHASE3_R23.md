# Scorecard Phase 3 R23 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.
This round was content/model work (no colour levers).

## Per point
- Geometry: IMPROVED. Houses gained porch (posts + sloped canopy),
  lean-to side extension with shed slab, roof dormer with window,
  second chimney. Castle gained gatehouse protrusion with cone,
  annex tower, extra battlements. Trees gained two trunk branches
  under layered canopy clusters. Silhouettes are less plain-box at
  full frame, though still simple compared to target's modelled
  detail (no roof overhang trim, no varied footprints/heights yet).
- Ground density: IMPROVED. 900 MultiMesh-instanced grass tufts
  (cross-quads, 4 tris each, ONE draw call; round63's 1300 oversized
  pale tufts read as confetti and were shrunk/darkened/reduced).
  Added log piles, a wheeled cart, a stone well with roof, sacks +
  crates at houses/market, a fence line, switchback + branch paths.
  Meadow now has visible texture/density at full frame. Still
  sparser than target's dense small-prop world; figures unchanged
  (7th carrier added then removed to hold draw budget — see perf).
- Mountain integration: IMPROVED, partial. Mine entrance on the face
  (timber frame, dark opening, rails + ore cart) reads clearly at
  right; watchtower built on the hill at (17,-11) — in the full
  frame it sits high/behind the crest and is barely visible, honest
  miss on placement; dirt switchback path zigzags village -> mine;
  3 terrace/field strips on lower slopes; 4 extra trees planted on
  slopes. Hill now has content, not just an empty slope, but the
  tower needs moving into view and terraces read subtle.

## Perf
Round65: 194 draw calls, 130,657 prims, ~38,110 authored tris
(includes 900 tufts x4 tris instanced in 1 draw; 6 carriers +
3 static figures as before). Round63 peaked at 211 draws with a
7th carrier — removed to stay under the ~200 cap; the only cap
growth vs R22 (171) is content geometry + the 1-draw tuft mesh.
Buildings remain <1500 tri each (merged low-poly boxes/cylinders).

Rounds: 63 (content + oversized tufts, 211 draws), 64 (tufts
shrunk/darkened, 203), 65 (carrier trimmed, 194).
Screenshots: phase3/round65.png, phase3/round63.png;
scorecard SCORECARD_PHASE3_R23.png.
