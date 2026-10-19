# Phase 3 R123 - Scorecard

## Choice (stated)
Roofs' shaded faces - Black's/R122's named remainder, addressed at roof-material
level only. No geometry/layout/light-rig changes; prims identical in all views.

## Diagnosis
Roof shading came from three places: (1) flat StandardMaterials on the roofp
surfaces (instance prisms + surf cones) with no face awareness - shaded faces kept
the full R122 albedo saturation and were only dimmed by the R108/R109 light rig;
(2) plain-colour relief tones (roof.darkened/lightened surf keys) whose darkened
variants are inherently saturated; (3) the light rig itself, which this round was
instructed not to re-grade. R90's stone shader proved the face-aware pattern.

## Method (same HSV measurement as R122; medians, lit/shaded split by value)
| sample | sat (lit) | val (lit) | sat (shaded) | val (shaded) |
|---|---|---|---|---|
| target reference | 0.408 | 0.769 | 0.426 | 0.286 |
| R122 round198 | 0.676 | 0.800 | 0.824 | 0.412 |
| R123 round199 | 0.652 | 0.706 | 0.786 | 0.333 |

## What changed (materials/shader only)
- Face-aware roof shader (R90 spirit, shared): world-normal light factor against
  the established sun vector; faces above the lit band pass the R122 albedo through
  exactly, shaded faces are desaturated 52% toward grey and deepened x(0.55,0.57,0.63)
  with a cool shift. Applied to (a) surf roofp materials (castle/village cones,
  watchtower) via mat_for, (b) the three roof-instance prism materials (tints =
  R122 spread), (c) plain roof-derived relief tones only - mat_for recognises the
  exact roof-root darkened/lightened variant set (a8664e/a05a44 families) and gives
  those the same shader on the grain base. Thatch and all other colours untouched.
- _cone_relief's darkest tone compressed 35% toward its own grey at construction.
- Two weaker shader tunings were measured and strengthened before landing (v1
  barely moved the medians; cone normals tilt upward, keeping lf mid-range).

## Verification / honest limits
- Shaded faces moved: sat 0.824 -> 0.786, val 0.412 -> 0.333 (target 0.426/0.286).
  Value is most of the way; saturation is not. Two stated reasons: the value-split
  median also captures the texture's darkest tiles on lit faces (unmutable by face),
  and darkened relief tones under ambient light stay chromatic. Closing the rest
  would need either re-desaturating the texture (R122 already rejected that as mud)
  or re-grading the light rig (out of scope by instruction).
- Lit faces: sat 0.652/val 0.706 vs R122's 0.676/0.800 - near-lit mid-slope faces
  are slightly deepened by the wider shaded band; no bright orange, no muddy lit
  faces, R108 cast shadows unchanged (custom shaders still cast via roof instances).
- Full/close/hill: roofs now read as one muted family on both faces (close cone:
  warm lit side, cooler muted shaded side, relief still legible, not dead grey).

## Perf
- round199: draws=283 (282 at R122 + 1 for the new grey-compressed relief tone key;
  cap 290), prims=495717 - identical to R121/R122 in all views (close 189/470533,
  hill 173/456300), verifying no geometry changed.

## Honest verdict
FAIL as an overall target match (still borderline ~6.5/10 expected), but the named
shaded-face remainder is materially reduced at the correct root: shaded roofs are
deeper and cooler, lit roofs keep the R122 calibration, and the family reads as one
painted material across both faces. What remains (shaded saturation) is a
texture-dark-tile + light-rig residue that material-level face shading cannot
fully reach, stated plainly rather than tuned into mud.
