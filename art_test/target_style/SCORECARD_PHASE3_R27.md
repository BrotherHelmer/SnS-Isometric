# Scorecard Phase 3 R27 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per point
- Ground into surface: DONE mechanically. Instanced flower/stone
  MultiMeshes REMOVED; detail_noise repainted (seed 81) with tuft
  strokes, 42 painted flower clusters and 52 stone-speckle clusters
  at texture scale, so ground detail now lives in the terrain
  surface (height/XZ UV paths from R21). White pebble dots are gone.
  Honest: painted flowers are subtle at game distance (they multiply
  with green vertex colour, so they read as light meadow flecks,
  not coloured blooms), and the kept 1200 instanced tufts still
  read as small green specks — ground is more integrated than R26
  but not yet one rich painted surface like target.
- Scale/silhouette: IMPROVED. Camera widened (ortho 21 -> 23.5) so
  the village sits smaller in frame with more meadow/hill context;
  house roof pitches raised (1.32/1.10/1.55), castle corner towers
  slimmer and taller (r0.52 h3.3, cones up), centre cone taller.
  Frame reads less big-toy. Buildings are still chunkier in
  proportion than target's slim illustrated shapes.
- Life smaller + mountain content: IMPROVED. KayKit figures scaled
  0.92 -> 0.80 (13 figures, clips unchanged). Six tiny merged
  worker figures (~1.2 units, no extra draw calls beyond 2 new
  merged colours) added: 3 on terraces/mine path, 3 in village
  fields — total figure count 19 at two scales, like target's
  many small workers. They are small at frame scale (a strength
  for density, a weakness for readability of poses — they are
  static merged shapes, not animated).
- Retained: roofs, plaster houses + rotation, geology/snow,
  watchtower/mine, gardens aligned, grade. No animals invented.

Perf round71: 254 draw calls (aim ~250 — 4 over, reported;
-2 from removed MultiMeshes, +~6 new merged colour keys from
mini-figure colours and wider frustum showing more instances),
168,021 prims, ~47,354 authored tris.

Rounds: 71 only.
Screenshots: phase3/round71.png; scorecard SCORECARD_PHASE3_R27.png.
