# SCORECARD — Phase 3 R81 (round156): gradual depth, not bands (internal only)

Reference: R80 round155. Target bottom half, full frame + slope/crest crop.
Choice from R80 stands (layered depth). Baked only, no post; foreground
(settlement terrain, dist<10) still mathematically untouched in the haze term.

## 1) Background wash varied along crest — 6.5/10
- Terrain-material haze is now noise-thinned: the R80 distance+height factor is
  multiplied by 0.45-1.20x of a 3-sine patch noise, and the pale target colour
  itself mixes between two pale tones by the same noise — so the wash thins and
  thickens along the crest instead of forming a constant band, with the
  underlying rock/snow shader terms showing through the thin passages.
- Geometry passages seated on the crest: 3 warm rock fans (existing 8f7355/
  6e5638 `_ground_patch` keys) and 3 jagged snow patches (existing e4e9ec key)
  interleaved with the R80/R77 haze fans.
Honest remainder: recession is more gradual and the top strip no longer reads
as one uniform band, but the noise period is still fairly regular if you look
for it, and banding is softened rather than fully painted away.

## 2) Treeline muted — 7/10
The 5-canopy mountain-foot treeline is now fed 3d5c2a / 466636 (was 5c8438 /
6d9440) to compensate the canopy material's ~2.1x R69 lift. In frame it now sits
at a mid value between the rich settlement trees and the hazy crest, separating
the layers quietly; the valley shadow band under it is unchanged.

**Overall honest self-score ~6.5/10. Not a Black PASS claim.**
Depth now reads settlement -> fields -> muted slope -> patchy pale crest with
no hard band edge at full frame; remaining gap is the regularity of the painted
noise and overall density vs target, not depth structure.

## Perf
R81 round156: **273 draws / 310,897 prims / ~139,507 authored tris** — draws
identical to R80/R79 (every passage reuses existing keys; canopy is one mesh).

Renders: evidence `phase3/round156.png` (1280x800, full frame).
