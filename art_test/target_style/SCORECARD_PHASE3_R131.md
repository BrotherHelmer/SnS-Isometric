# Phase 3 R131 — measurement-led canopy saturation

Draws 283 (cap 290) | Prims 543,291 (~550k ceiling) | Authored tris 244,082 — texture/vertex-tone only, no geometry/placement/light changes.

## Choice
Continue measurement-led: canopy saturation, R130's next named candidate (canopy sat .958 vs target .729, dS +.242 at R130; confirmed .958/+.229 on round206 rerun).

## Before (classify_r130.py, round206)
Canopy median (39,71,3) HSV (.245,.958,.278) vs target (65,85,23) HSV (.220,.729,.333): dS +.229, dRGB .078, share +10.69pp. Hue family already olive-green; the gap is saturation (blue channel ≈0) and pre-existing value (darker crowns).

## Root + fix (canopy only)
Root: canopy palette × `foliage_painted.png` (med sat .559) × R69 vertex boost (×2.1/2.0/2.1) stacks saturation. Fix:
- `foliage_painted.png`: value-preserving desaturation f=0.45 per pixel (blend toward own max channel): texture med sat .559 → .315, value .498 unchanged.
- `add_canopy` + `add_canopy_low`: after the R114 quantized cluster steps / sun-shade law and the R69 boost, vertex tone desaturated toward its own max channel ×0.55 — value-preserving, so sun/shade split and step structure are kept and shade faces lift in r/b rather than darkening. R113 olive palettes, hue family, cluster-cell normals untouched.
- Iterations measured: vertex ×.30 → class sat .829; ×.44 → .814; ×.55 → .800. Diminishing class-median returns are partly selection bias (desaturated crowns cross the classifier's grass boundary), checked boundary-free below.

## After (round207, same method)
- Canopy class: sat .958 → .800 (gap .229 → .071, 69% closed), dRGB .078 → .055, hue .245 → .235 (toward .220), value .278 → .275 (no darkening).
- Boundary-independent all-green pixels: median sat .827 → .727 (target all-green .637; target canopy-class .729); dark faces (v<.38) median sat .989 → .861 at unchanged value — shade faces muted, not near-black.
- Guards: roofs median identical (151,78,47), dRGB .077 → .077 (R122/R123 intact); stone dRGB .039 → .042 (no stone materials changed in R131; classifier spill only — R130 fix not drifted); dirt .068 → .069; rock/hill .110 → .098; snow/sky unchanged.
- Grass drag stated: grass-class median sat .645 → .599, dRGB .035 → .038. Terrain grass (meadow texture/palette) was not touched; desaturated light crowns now classify as grass (value ≥.45 boundary), shifting that class's median. A classifier effect, not a terrain change.

## Honest verdict
FAIL (self-assessment), borderline ~6.5/10. Crowns sit in target's muted olive family at first glance — top forest and right-hand trees visibly less neon than round206 — and measured dS closed 69% (to .727 on the boundary-free green median). Remaining canopy gaps: value .275 vs target .333 (crowns darker; pre-existing R114 shade balance, deliberately not touched — this fix was value-preserving by design) and saturation still +.07 on class median. No stone cooling (Black explicit; stone untouched). Nothing shown to Helmer.
