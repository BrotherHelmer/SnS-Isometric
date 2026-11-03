# Scorecard Phase 3 R29 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per point
- Flower meadows: IMPROVED. Scattered flecks replaced by 6 defined
  meadow zones (near village/paths/open grass): light-green underlay
  patch + 30 dense bigger blooms each (0.25 scale) in red/yellow/
  pink. Left-of-village and bottom-centre meadows now read as
  flower patches at full frame, not confetti everywhere. Still
  blob-dense rather than painted-soft, and 2 of 6 zones land partly
  under trees/slope so only ~4 read clearly.
- Tufts softer: PARTIAL. Count 1200->1000, heights varied
  (0.55–1.35 relative), colours matched closer to meadow
  (2c5e17–5b963a), painted tuft strokes in terrain texture
  strengthened (+1800 strokes). Card read reduced — mid-field
  reads as grass texture; close inspection still shows cards.
- Buildings finer: IMPROVED. Roof overhang widened (3.0->3.35 wf,
  depth 2.8), windows/door narrowed, chimney slimmer+taller
  (0.37 x 1.18). Houses read finer-proportioned; castle unchanged
  this round beyond R28 slimming.
- Draw calls: 243 (unchanged — meadows used existing merged
  colours, underlay reuses garden green).

## Updated top-3 first-glance gaps (my judgement)
1. Render style itself: ours is a clean flat low-poly 3D render;
   target is a painted illustration with soft modelled forms.
   Every surface (roofs, plaster, canopies, rock) is recognisably
   "3D model" at first glance. This is now the dominant gap and
   would need per-asset painted modelling, not scene tweaks.
2. Ground completeness: target's terrain is fully worked —
   paths, plots, stones, tufts, worn earth edge-to-edge. Ours has
   worked zones (meadows, terraces, gardens) on a still largely
   smooth green field between them.
3. Hill as a place: mine/tower/terraces exist, but target's hill
   carries a whole worked landscape (mine complex, tower, paths,
   fields, banners) at the same density as the village; ours is
   still mostly empty slope around 3 features.

Perf round74: 243 draw calls, 197,761 prims, ~58,714 authored tris.
Screenshots: phase3/round74.png; scorecard SCORECARD_PHASE3_R29.png.
