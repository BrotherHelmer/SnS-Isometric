# Scorecard Phase 3 R19 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per criterion
- House walls: IMPROVED. House redesigned — dark vertical timber strips
  and the big dark door inset removed; now light timber FRAME only
  (corner posts + top/bottom rails, 7a5a36), plaster dominant and warm,
  lighter framed door, two warm windows, side window, flower box with
  red/white blooms. round54_close.png proves it: houses read light
  timber-framed, not dark boxes. At full frame houses are visibly
  lighter/cream with brown trim. Still simpler/flatter than target's
  detailed facades.
- Grass depth: PARTIAL, small gain. Base darkened (27631d/3f842c),
  patch tints strengthened (light meadow + worn-earth + pale patches),
  omni wash reduced (0.85->0.55, centre pool 0.9->0.6). Meadow patches
  are visible in the lower frame, but the field still renders pale
  light-green overall under sky ambient + sun vs target's rich
  saturated meadow. Colour depth remains a gap; light levels, not
  albedo, are now the limiter.
- Rock material detail: PARTIAL / proof mixed. Detail now goes through
  the path that actually renders the face — terrain vertex colour:
  crack darkening (sin-based crevice lines, x0.30) and lichen tint
  patches (7d8f4e) added inside the steep-band shading, on top of
  R15 chunk variance + strata. round55_hill.png shows the chunky
  faceted face + talus close, BUT in that shot the upper face is
  mostly blown white by snow + glow, so cracks/lichen are not clearly
  discernible. Honest: detail is in the material path and affects the
  face at full frame (facet/crack contrast), but the close proof is
  weak and lichen is not visibly reading. Next: tone snow brightness
  on steep faces so rock detail survives next to caps.
- Retained: R17 grade/FXAA/soft shadows, roofs (shingles read close),
  castle stone, bright canopies, composition, density/life.
  No animals invented.

Rounds: 54 (house redesign, deeper grass, crack/lichen vertex detail,
full + house close + hill close), 55 (omni wash down, wider hill cam).
Perf round55: 171 draw calls, 107,645 prims, ~27,250 authored tris.
Screenshots: phase3/round55.png, round54_close.png, round55_hill.png;
scorecard SCORECARD_PHASE3_R19.png.
