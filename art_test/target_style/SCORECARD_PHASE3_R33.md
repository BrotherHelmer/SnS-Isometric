# Scorecard Phase 3 R33 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per point
- Shingle scale: PARTIAL. Rows rebuilt again: 6 rows x 3 segments
  per slope (0.46 slabs, alternating tints, continuous shadow-gap
  slab under each row; geometry rows now match the painted
  texture's 6 rows). Segmented relief is visible in close views
  and adds stepped texture at full frame, but individual shingles
  still merge into the painted read at game distance — smaller
  scale achieved, readability similar to R32. Tris cost noted below.
- Silhouette at distance: SMALL gains. Eave shadow edge thickened
  (0.09 -> 0.17, reads as a dark roofline at full frame), castle
  gained spires on two corner towers + a body turret, canopy
  cluster scales irregularised (0.88–1.12 sin variance). Roofs and
  castle outline are slightly less plain; house bodies remain
  hard-edged boxes under their corner cylinders.
- Upper hill worked: IMPROVED. Summit feature added: standing-
  stone circle (5 tilted stones + centre stone on a disc) at
  (16,-16) with a 3-segment dirt path up from the watchtower,
  4 upper tree clusters, 3 rocky field strips with stone blobs,
  4 snow-drift blobs integrated near the top. Honest framing
  note: the summit sits at/above the top edge of the full frame
  (visible in hill close region only in part) — content exists
  but composition doesn't showcase it yet. Upper face between
  features is still bare rock vs target's worked mountain.
- Retained: all prior points. No animals invented.

Perf round79: 276 draw calls (cap ~290), 310,665 prims,
~95,818 authored tris (+11% vs R32, growth = segmented shingles
48 boxes/house + summit/hill geometry, all merged).

Rounds: 79 (full + hill close).
Screenshots: phase3/round79.png, phase3/round79_hill.png;
scorecard SCORECARD_PHASE3_R33.png.
