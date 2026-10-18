# Scorecard Phase 3 R46 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per point
- Trees: canopy mass scaled x0.80 overall, clusters per tree
  10 -> 14 with smaller outer clusters (0.34-0.46), foliage
  texture repainted at 1024 with large soft leaf-cluster blobs
  (shadow/mid/light/tip layers, blurred, fine speckle on top)
  so painted clusters, not facet shading, carry the read.
  Judge: trees are visibly smaller and more broken-up in
  round102, canopy texture mottling reads at frame; they are
  still faceted sphere clusters underneath — the faceted-mass
  read is reduced, not broken.
- Mountain painted: terrain grid 88 -> 104 steps (smaller
  facets), broad strata banding added to the steep-slope
  vertex colour (light band / dark band by height+slope),
  feature dirt blend radius 3.2 -> 4.4, apron discs 2.1 -> 3.1.
  Hill close (round102_hill) shows strata + cracks + lichen
  together; honest: facets still plainly visible at frame,
  aprons read as pale worn discs around features.
- Miniature scale: KayKit figures 0.72 -> 0.62 scale (15
  animated figures), +8 merged minis (25 total, 40 figures
  overall) and +8 small crate/barrel clusters at village/hill
  spots, all merged — no new draw calls.
- Retained: centre deformed forms (R45), roofs, castle,
  houses, summit, grade. No animals invented.

Perf round102: 285 draw calls (unchanged), 455,275 prims
(up: +4 canopy clusters/tree + finer terrain), ~150,296
authored tris (canopy counting dominates the rise).

Rounds: 102 (full + hill close).
Screenshots: phase3/round102.png, phase3/round102_hill.png;
scorecard SCORECARD_PHASE3_R46.png.
