# Scorecard Phase 3 R47 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per point (A/B honest)
- Canopy facet break: A/B done in round103. Crossed alpha
  foliage cards (foliage_card.png, alpha-scissor, 1 draw)
  LOST: rendered as dark-framed flat planes, worst at hill
  close — removed from trees in round104 (helper left dormant,
  no cards placed, no draw). WINNER: irregular displaced
  shells — canopy sphere replaced by a 9x5 shell displaced
  radially (0.10-0.20 sin modes per unique vertex), keeping
  R46 size/cluster counts and painted leaf texture. Silhouettes
  are now jagged/leaf-cluster shaped, not spherical; close up
  the facets are still visible inside the silhouette.
- Mountain facets: direction tested = welded smooth-shaded
  heightfield. Terrain rebuilt as a shared-vertex indexed
  grid (104 steps) with smooth accumulated normals and
  CONTINUOUS colour functions (the old per-cell chunk hash,
  a main facet source, is now a smooth sin product, amplitude
  reduced). Kept: at full frame the hill/grass no longer show
  the checker-facet read (compare round102 vs 104 grass and
  back hill); hill close still shows large low-poly shading
  triangles on the rock — improved, not painted.
  (First attempt inverted the accumulated normals — terrain
  went near-black; flipped and re-rendered as round104.)
- Aprons: pale cyl discs replaced by overlapping tapered
  lens blobs (dirt colours + grass-green edge blobs, offset
  per feature, palette colours only). No hard disc edge now;
  honest: the worn patches still read as pale ovals at the
  summit in the hill close, just feathered/softer.
- Retained: miniature figures, centre forms, roofs, castle,
  houses, summit. No animals invented.

Perf round104: 287 draw calls (<=290; cards out, aprons use
existing palette keys), 372,763 prims, ~151,112 authored tris.

Rounds: 103 (A/B cards + inverted-normals reject), 104 (kept).
Screenshots: phase3/round103.png (reject evidence),
round104.png, round104_hill.png; scorecard SCORECARD_PHASE3_R47.png.
