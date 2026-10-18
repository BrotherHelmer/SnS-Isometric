# Scorecard Phase 3 R41 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## What was done
- Large brush-stroke repaints (not fine grain): plaster/stone/roof
  overlaid with wide soft strokes; own wood_painted texture (long
  grain strokes) replaces the KayKit timber path in TEX; foliage
  repainted with bigger leaf clusters + stronger light tips;
  terrain detail regenerated with LARGE soft mottling (r280–680
  blobs), wide strokes, faint cracks and flecks — green now has
  broad light/dark painterly variation edge-to-edge at full frame.
- Painted edges: light ridge-highlight strip on every house roof
  (existing tint key), shadow-wash AO discs (r2.7) under all 9
  houses, canopy per-face variance deepened (0.70–1.32) with
  stronger top lightening (0.26).

## Honest judgement at full frame
Texture richness improved close (castle stone, wood grain and
stone chimney read painted in round95_close) and the meadow's
large mottling is visible in the lower frame. BUT the first-glance
read is still "textured low-poly models": silhouettes and facet
planes dominate over brushwork. The repaint moved surfaces from
flat to textured; it did not make them illustrated. This is the
same conclusion as R17/R29 at a higher texture quality — the
remaining style gap is in the modelled forms and per-asset
painted modelling depth, which texture scale alone cannot close
in this procedural test scene.

## Updated top-3 remaining gaps (my judgement)
1. Modelled form language: target's assets are soft, irregular,
   illustrated volumes; ours are primitives (even round/oct ones)
   with painted skins. Facets and hard edges still announce "3D
   model" before any texture reads.
2. Figure/prop scale and count: target crowds the scene with
   many tiny workers, goods, carts and details at miniature
   scale; ours has 26 figures (15 animated) that still read
   large, and prop density thins away from the centre.
3. Mountain as painted place: our hill is a faceted heightfield
   with features placed on it; target's hill is a fully painted
   rocky landscape (mine, tower, paths, snow) integrated with
   the settlement at the same richness as the village.

Perf round95: 285 draw calls (unchanged — textures and merged
strips only), 395,483 prims, ~121,980 authored tris.
Screenshots: phase3/round95.png, phase3/round95_close.png;
scorecard SCORECARD_PHASE3_R41.png.
