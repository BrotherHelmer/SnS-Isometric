# Scorecard Phase 3 R44 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per point
- Deformed roof geometry: DONE mechanically. roof2 rewritten as
  a deformed prism: ridge split at a sagging midpoint (-0.13),
  ridge-end heights ±0.12, eave corners ±0.08, ridge twist
  ±0.10, seeded per building position; shingle texture UVs
  follow the split slopes (v eave->ridge preserved, verified
  reading in renders), merged shingle slabs follow the average
  slope underneath. Applies to the 2 remaining parametric
  houses AND both A-frames (all roof2 users), tint-group roof
  merging (R36) untouched, no draw change.
  Honest read: deformation is real in geometry but subtle in
  frame — and only 4 buildings use roof2 now, two of them at
  frame edges, so the full-frame effect is small. The village's
  rectilinear read was already minority after R39/R40
  conversions (7/12 non-box); deformed roofs make the last
  prism roofs irregular rather than changing the whole read.
- Remaining box cottages: only 2 parametric _build_house calls
  remain ((-5.5,10.8), (13.5,4.5)); both now carry deformed
  walls (R43) + deformed roofs + massing wings. Rectilinear
  prism-roof cottages are a minority of the village.
- Facade softening: per-house window/door jitter (sin-seeded
  ±0.13 offset, slight window height variance) applied to the
  parametric houses; no detached facades in close shots.
- Retained: round/oct/A-frame builders, crowd (32 figures),
  hill/summit, castle, grade. No animals invented.

Perf round100: 285 draw calls (unchanged), 385,015 prims,
~123,740 authored tris.

Rounds: 100 (full + close).
Screenshots: phase3/round100.png, phase3/round100_close.png;
scorecard SCORECARD_PHASE3_R44.png.
