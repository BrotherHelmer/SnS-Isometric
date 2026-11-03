# Scorecard Phase 3 R31 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per asset
- Roof relief: PARTIAL. Modelled shingle rows added to every house
  roof (5 thin offset slabs per slope, alternating tints, merged —
  2 draw keys total), thatch huts gained edge ring + top cap.
  Round76 rows were too proud/misaligned-looking in close-up;
  thinned/flush in round77. Honest result: at game distance roofs
  still read mainly as painted shingle texture; the modelled rows
  contribute a subtle stepped edge/ridge read, not strong relief.
  The relief-versus-paint balance is not yet at target's chunky
  modelled shingles.
- Foliage softer: IMPROVED modestly. Clusters 7 -> 10 per tree
  (3 smaller outer clusters), graded per-cluster tint (a->b lerp +
  periodic lightening). Canopies are fuller with softer, less
  uniform silhouettes in full frame; still faceted spheres at
  heart, no painted softness inside the canopy surface.
- Sculpted form: SMALL gains. Castle corner towers tapered
  (0.58 -> 0.45), houses gained stone foundation skirts, roof
  overhang shadow eave retained. Forms remain box/cylinder based;
  no bevelled edges — relief-on-box character persists.
- Hill content: IMPROVED modestly. +2 lower field strips with
  fence posts, a thatched slope shed, 2 more slope trees; with
  R24 terraces (now 6) and mine/tower the slope has ~8 features.
  Still far emptier than target's worked mountain.

Perf round77: 263 draw calls (cap ~270), 266,569 prims,
~77,742 authored tris (canopy HD spheres + shingle rows are the
growth; all merged, no new per-asset draws except 2 shingle tints).

Rounds: 76 (relief/clusters/taper/hill), 77 (rows thinned flush).
Screenshots: phase3/round77.png, phase3/round77_close.png;
scorecard SCORECARD_PHASE3_R31.png.
