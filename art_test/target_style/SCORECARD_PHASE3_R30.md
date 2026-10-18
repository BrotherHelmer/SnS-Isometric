# Scorecard Phase 3 R30 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per asset
- Castle: IMPROVED. Modelled stonework relief added: ~40 extruded
  stone blocks (2 tints, stone texture) on front + right walls,
  arched gate top (rotated cylinder), battlements along both side
  top edges, centre-tower roof ring. round75_close.png shows the
  relief blocks and textured stonework reading at close range; at
  full frame the castle silhouette is denser. Still box-based
  masonry underneath — relief is applied detail, not sculpted form.
- Houses: IMPROVED. Timber frame now uses the painted timber
  texture (grain on posts/rails/porch), chimneys use painted stone
  texture (reads clearly in close shot, bottom-right house), ridge
  caps added along rooflines, dormer/porch/lean-to retained from
  R23-24 with R29 overhang. Roofs still smooth prism planes with
  painted shingles — modelled shingle relief not attempted.
- Trees: IMPROVED modestly. Canopy geometry upgraded to a 12x6
  faceted sphere (from 8x4) and clusters 5 -> 7 per tree with two
  smaller outer clusters, per-cluster tint via existing vertex
  variance. Silhouettes are fuller/rounder in close and full
  frame; still faceted low-poly masses, not soft painted foliage.
- Ground (secondary): 18 worn-earth discs + 3 crop plots with rows
  added across open areas; worked zones now spread wider, though
  pale worn discs read a bit spotty.
- Hill (secondary): terraces 4 -> 6 strips, mine-side barrel/crate
  and 3 flag posts along the switchback added. Hill still much
  emptier than target's worked mountain.

Perf round75: 257 draw calls (cap ~260 this round; +14 from new
merged tint/texture keys), 235,489 prims, ~65,638 authored tris.
Hero buildings still way under the 2500-tri aim (merged boxes/
cylinders, castle relief ~500 extra tris total).

Rounds: 75 (full + close).
Screenshots: phase3/round75.png, phase3/round75_close.png;
scorecard SCORECARD_PHASE3_R30.png.
