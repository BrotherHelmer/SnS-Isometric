# Scorecard Phase 3 R66 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per point
- Tiling attacked: mat_for uv1_scale — meadow 18 -> 3,
  all non-hero textures (wood "timber", dirt) 6 -> 1.5;
  plain-colour grain 3 -> 1.5. Hero surfaces (roof,
  stone, plaster, thatch, rock) were ALREADY at 1
  (per-face 0-1 UV, 2048 texture per face type, the R18
  arrangement). Draws unchanged (288).
- Verification at frame scale: before/after crops of the
  castle area from the actual full frames (round137_crop
  vs round138_crop, 2x enlargement, saved in evidence)
  are near-identical — because the hero faces in that
  crop never tiled. Where tiling did change (wood beams,
  dirt paths, grain on plain geometry), strokes/grain
  now span larger per face, a small readability gain on
  secondary surfaces in the close shot.
- Honest conclusion: tiling is NOT the main limiter for
  hero assets in this scene — their UVs were already
  per-face. Strokes mip away because hero faces are
  ~40-90 px on screen at the 25-unit frame; no UV
  arrangement changes face screen size. This closes the
  tiling hypothesis with evidence (third documented
  texture-limit data point, after R41/R65).
- Per-building painted patches: houses already carry 3
  plaster tints + per-house roof tint groups + patches;
  no further gain found there this round.
- Retained: all composition/form/integration work.
  No animals invented.

Perf round138: 288 draw calls, 482,213 prims, ~164,788
authored tris (material-scale only).

Rounds: 138 (full + close + frame crops).
Screenshots: phase3/round138.png, round138_close.png,
round137_crop.png, round138_crop.png;
scorecard SCORECARD_PHASE3_R66.png.
