# Scorecard Phase 3 R18 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

All per-surface textures repainted at 2048 with LARGE features + fine
grain (Pillow, seeds 61–67), and wall textures now span one texture per
wall face (uv1_scale 6 -> 1 for stone/plaster/thatch/rock; dirt kept
tiled). R17 grade/FXAA/soft shadows retained throughout.

## Per surface
- Walls: IMPROVED at close range. Castle stone now shows individual
  large stones with top highlight / bottom shadow, cracks and moss in
  joints — clearly readable in round53_close.png. Plaster has soft
  blotches, cracks, base moss, but on houses it is mostly hidden behind
  timber geometry and reads only in strips at full frame; house side
  panels remain flat dark timber. At game distance the castle gain is
  visible, house-wall gain is minor.
- Grass terrain: PARTIAL. Terrain detail texture repainted with large
  soft meadow patches + brush strokes and now spans ~14 world units
  (uv 0.5 -> 0.07), plus low-frequency vertex patch tint (green ->
  worn-earth). Variation exists but renders pale/subtle at full frame;
  grass still reads as a fairly uniform light-green field vs target's
  rich varied meadow. Worn earth near buildings not convincingly shown.
- Rock face: UNCHANGED in structure (R16 warm chunky facets retained);
  rock_painted repainted large-strata, but the terrain face itself is
  vertex-coloured, so the new rock texture has little effect on the
  main face — honest note: rock texture work does not reach the
  heightfield. Face gain this round ≈ none.
- Roofs: RETAINED with variation. Repainted 6 large shingle rows with
  per-shingle highlight/shadow and moss; round52 washed salmon under
  the brighter albedo, round53 deepened paint (seed 67) restored red.
  Shingles read at close and full frame as before — no regression,
  modest variation gain. Thatch repainted with big straw strokes;
  reads pale-soft at frame, similar to before.
- Softness: R17 retained (ACES+sat, FXAA, tamed sky ambient, blur 7,
  grain). Frame got slightly paler this round from brighter texture
  albedo (0.78->0.88) + lighter terrain detail base.

Net: close-range surface detail materially better (castle especially);
first-glance full frame still flat-shaded low-poly, not painterly
target. Next lever would be house-wall composition itself (plaster
visible area vs timber) and richer grass colour depth, not more grade.

Rounds: 52 (2048 textures, one-span walls, close shot), 53 (roof
deepened, albedo trimmed).
Perf round53: 167 draw calls, 104,117 prims, ~25,822 authored tris.
Screenshots: phase3/round53.png, phase3/round53_close.png;
scorecard SCORECARD_PHASE3_R18.png.
