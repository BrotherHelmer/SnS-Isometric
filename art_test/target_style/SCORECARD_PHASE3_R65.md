# Scorecard Phase 3 R65 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per point
- Brushwork: directional stroke overlays painted on six
  textures — plaster (horizontal strokes), roof (streaks
  along shingle rows; second stronger pass alpha 80-130,
  22-40px wide, 260-600px long in round137), wood (long
  vertical grain), stone (large patches + light edges),
  meadow detail (directional grass strokes in the shader
  grass path), thatch (vertical straw). Judged at FULL
  frame: roofs show more streak variation, walls/roofs
  read less flat in close. Honest: at 25-unit frame most
  strokes still mip-average — the effect is real but
  incremental, the same limit found in R18/R41. Several
  materials tile textures (uv1_scale 6-18), shrinking
  painted strokes below frame readability regardless of
  texture-space size.
- Edge highlights: delivered as painted light strokes in
  the textures (roof row highlights, stone light edges,
  plaster light bands) rather than new geometry strips;
  house ridge highlight strips already existed. No new
  draw calls (288, unchanged).
- Per-face colour breakup: stone patches and roof streak
  variance add within-face variation on the largest
  textured faces (castle stone, roundhouse cones read
  more varied in round137 close); terrain meadow/wall
  already carry per-vertex patch breakup.
- Conclusion stands: brushwork on the existing textured
  low-poly construction moves the read by degrees, not
  by kind. The scene at first glance remains modelled
  objects on terrain, not a painting.

Perf round137: 288 draw calls, 482,213 prims, ~164,788
authored tris (unchanged — texture-only rounds).

Rounds: 136 (all six textures), 137 (stronger roof/
plaster pass; full + close).
Screenshots: phase3/round136.png, round137.png,
round137_close.png; scorecard SCORECARD_PHASE3_R65.png.
