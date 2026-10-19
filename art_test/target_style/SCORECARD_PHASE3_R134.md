# Phase 3 R134 — dirt/worn saturation (Black's named candidate)

Draws 283 (cap 290) | Prims 543,291 (~550k ceiling) | Authored tris unchanged — texture/material only. Stone and canopy closed (guard-measured only, not retuned).

## Choice
Dirt/worn saturation: round209 dirt class sat .671 vs target .454 (dS +.217), value and hue already matched.

## Before (classify_r130.py rerun on round209)
Dirt/worn median (161,119,53) HSV (.102,.671,.631) vs target (163,139,89) HSV (.113,.454,.639). Scope stated as one family: main/branch path dirt (R117/R118), worn yards (R128), desire links (R129), castle apron and mine apron/terraces sharing the same dirt keys. The palette itself sits at sat .43–.52 (d9ba7c .43, a8895a .46, 8a6c42 .52); rendering stacks warm sun + frame saturation on a low blue channel to reach .671.

## Fix
- `dirt_painted.png` desaturated toward mean-grey ×0.35 (pattern preserved).
- Dirt palette tones (d9ba7c, a8895a, 8a6c42, c9a86a, c9ab72, d6b878, b99a68/b89a68, b08d55 terraces, terrain dirt 9c7f52) desaturated ×0.30 toward mean-grey, then ×0.20 value-preserving (toward own max, canopy-style). Timber/prop wood colours deliberately excluded (not ground).
- Iterations measured: a second mean-grey pass overshot value (class val .631→.561, dRGB worsened); reverted to first-pass state and redone value-preserving. Final = texture ×0.35 + palette ×0.30 mean + ×0.20 value-preserving.
- No hue-family change (still warm dirt), no geometry/placement/light changes.

## After (round210, same method)
- Whole dirt class: sat .671 → .623 (gap .217 → .169), val .631 → .573, dRGB .076 → .098 — the class median pool is dominated by its dark bucket, so this line overstates/understates by turns.
- Light-ground subset (dirt-class pixels with v≥.55 = path/yard centres, the actual ground family): sat .543 → .518 (target .438; the intermediate first-pass state measured .488 — subset medians carry ~±.03 selection noise as desaturated pixels cross class boundaries), val .741 → .722 (target .710).
- Dark bucket (wood/hill pixels sharing the classifier bucket, out of scope): sat .700 → .640 via the terrace/fan tones that do share dirt keys.
- Value separation kept: light dirt .722 vs grass class .596 (+.126, warm-vs-green). Close panel: paths/yards read as pale warm earth against grass, R118 fringe steps still graduate, R117 ruts/centres still visible — not grey mud.
- Guards: canopy median identical (57,86,16), dRGB .020 → .021 (closed class, not retuned); roofs identical (150,77,46), .081 → .081; grass .034 → .035; stone .072 → .097 and rock .105 → .071 are classifier spill only — no stone/rock/canopy materials or textures changed in the R134 diff.

## Honest verdict
FAIL (self-assessment), borderline ~6.5/10. The ground family sits in target's muted warm earth at first glance — visibly less orange than round209 while paths still read — and light-ground saturation closed roughly half its gap on the first pass. Class-median closure is only partial (.671→.623) and noisy because the classifier's dirt bucket also counts timber/wood and hill pixels outside the ground family; residual saturation ≈ +.08 on light ground, +.17 on the whole bucket. Nothing shown to Helmer.
