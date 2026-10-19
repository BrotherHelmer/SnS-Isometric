# Phase 3 R133 — named canopy residual (value + residual saturation)

Draws 283 (cap 290) | Prims 543,291 (~550k ceiling) | Authored tris unchanged — vertex tones/material only. Stone untouched.

## Choice
The named canopy residual from R131/R132: canopy value .275 vs target .333 and saturation still +.07 (class sat .800 vs .729). Lift value at the canopy root without giving back R131's saturation gains.

## Before (classify_r130.py rerun on round208)
Canopy median (47,70,14) HSV (.235,.800,.275) vs target (65,85,23) HSV (.220,.729,.333). Lit/shade split (green-hue pixels, shade = v<.38): ours shade val .247 sat .860 (n=17,784) / lit val .553, ratio 2.24; target shade .216 / lit .506, ratio 2.35. Lit faces were already at target lightness — the class-median value gap is shade-mass weight inside crowns (R114 dark steps), not absolute brightness.

## Fix (canopy only)
- `add_canopy` + `add_canopy_low`: after the R131 desaturation, vertex tone ×1.20 with proportional rescale at the 1.1 cap (R114 quantized steps, flat cluster normals, sun/shade law all preserved in structure). Measured alone: value .275 → .282 — mostly absorbed by the boost cap and texture.
- Canopy material albedo (1.03,0.96,0.85) → (1.28,1.19,1.05) — the effective lift.
- R131 desaturation then strengthened .55 → .62 (value-preserving) to recover the lift's saturation give-back.
- No geometry/placement/light changes; foliage texture and R113 palettes untouched.

Incident: the first albedo edit placed a `#` comment mid multi-statement line, so the canopy node was never added (281 draws / 360k prims). Caught by the perf check, fixed, final verified at 283 draws / 543,291 prims.

## After (round209, same method)
- Canopy median (58,86,16) HSV (.233,.814,.337): **value gap closed** (.275 → .337 vs target .333), dRGB .055 → **.020** — closest class measured yet. Saturation .800 → .814 (net give-back +.014 after the .62 recovery; residual +.085 vs target .729).
- Split: shade val .247 → .302 (lifted, no near-black — shade count falls 17,784 → 12,286 as pixels cross v=.38), lit .553 → .549 (not washed out). Split ratio 2.24 → 1.82 vs target 2.35: shade lifted proportionally more than target's split — the one trade made, stated; cluster steps still visibly separate faces.
- Guards: roofs median identical (150,77,46), dRGB .081 → .081; stone .075 → .072 (stone untouched in R133, classifier spill only); dirt .078 → .076. Grass dRGB .038 → .034 but share −6.26 → −0.10pp: classifier spill — lifted crowns cross the grass-class boundary (v≥.45); terrain grass itself untouched, as in R131. Rock classifier .075 → .102 spill from lifted green pixels; no rock materials changed in R133.

## Honest verdict
FAIL (self-assessment), borderline ~6.5/10. Crowns now sit at target lightness in the muted olive family on both faces at first glance, and canopy is the closest-measured class so far (dRGB .020, value matched). Residuals: saturation +.085, compressed lit/shade ratio (1.82 vs 2.35), and composition-bound canopy share (+4.67pp after boundary spill). Next named candidate: dirt/worn saturation (.669 vs target .454). Nothing shown to Helmer.
