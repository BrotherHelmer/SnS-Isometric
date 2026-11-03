# Scorecard Phase 3 R20 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per criterion
- Grass richness under light: IMPROVED, verified against target tones.
  Fix was terrain-specific, not global: terrain material albedo tint
  (1.0 -> 0.68/0.74/0.62 in r56 -> 0.55/0.63/0.49 in r57) multiplies
  the deepened vertex meadow, so grass darkened without touching
  buildings. Sampled render grass ≈ RGB(130,190,90) in open patches
  (was ~150,210,120 pre-R20) vs target bottom-half grass samples
  ≈ (80–160, 110–170, 10–115): hue now matches, still somewhat
  lighter/less shadow-deep than target but no longer pale-uniform;
  meadow patch variation reads across the field. Houses/castle did
  NOT darken with it (separate materials) — no regression.
- Snow / rock detail coexistence: PARTIAL. Snow toned grey-blue
  (f8fafc -> d0dbe4), restricted to gentler faces (slope <=1.65 ->
  1.30 -> 1.10) and glow strength 0.5 -> 0.3. round58_hill.png: the
  chunky faceted rock face, strata and talus read without the r55
  full-white blowout over most of the face; snow sits on shelves.
  Still: pockets of near-white glow remain on snow shelves behind
  talus, and crack lines read as facet contrast rather than drawn
  cracks; lichen tint is present in shading but subtle. Coexistence
  is better, not clean.
- Retained: houses light timber-framed (no darkening regression),
  castle stone, roofs, canopies, composition, density/life, R17
  grade/FXAA/soft shadows. No animals invented.

Rounds: 56 (terrain tint 0.68, snow grey-blue/slope 1.30),
57 (tint 0.55 — grass rich), 58 (snow slope 1.10, glow 0.3).
Perf round58: 171 draw calls, 107,645 prims, ~27,250 authored tris.
Screenshots: phase3/round58.png, phase3/round58_hill.png;
scorecard SCORECARD_PHASE3_R20.png.
