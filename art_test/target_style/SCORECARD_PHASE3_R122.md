# Phase 3 R122 - Scorecard

## Choice (stated)
Roof colour calibration, measured before changing. Materials/texture only - no
geometry, layout, lights or environment changes (prims verified identical).

## Measurement (method + numbers)
Method: hand-picked tight roof-only boxes (castle cone, two village cones, aframe
roof, house roof in ours at 1280x800; castle + village tile roofs in the 640x400
target), every pixel filtered to warm-red roof pixels (R>G*1.08, R>B*1.05, sat>0.15,
hue<36deg), converted to HSV, split at the median value into lit/shaded halves.
Medians:

| sample | hue | sat (lit) | val (lit) | sat (shaded) | val (shaded) |
|---|---|---|---|---|---|
| target reference | 25.9 | 0.408 | 0.769 | 0.426 | 0.286 |
| R121 round197 | 22.3 | 0.786 | 0.773 | 0.889 | 0.376 |
| R122 round198 | 22.3 | 0.676 | 0.800 | 0.824 | 0.412 |

Diagnosis: hue family and lit value already matched the target - our roofs were NOT
duller or browner. The gap was saturation: lit faces ran nearly double the target's
measured saturation (vivid terracotta vs muted brick red). So this round desaturates
toward the target family; it does not chase more red.

## What changed (material roots only)
- roof_painted.png: saturation x0.75 cumulative (tile pattern/variation of R93 kept;
  two stronger passes were tried and rejected - x0.47 read muddy brown at full frame
  and killed the red signal, documented here honestly).
- Roof root colour a15f43 -> a8664e (less saturated brick), secondary roof red
  9c4a34 -> a05a44 (octstore/watchtower/market/detail roofs follow the same family;
  keys renamed, not added). Cone tint-through lerp 0.28 -> 0.24.
- Roof-instance material groups (the per-building seeded spread, by origin hash):
  widened to (0.94,0.80,0.68) / (0.82,0.66,0.55) / (0.74,0.63,0.55).
- Thatch family untouched. Lights/env/exposure (R109) untouched.
- Process note: Godot game runs do not reimport changed textures; an explicit
  --import pass was required before the desaturation appeared in renders.

## Verification
- Lit faces: sat 0.786 -> 0.676 toward target 0.408, value 0.80 vs target 0.77,
  hue 22.3 vs 25.9 - roofs still read warm red at first glance, no bright orange
  anywhere in full/close/hill; tile relief (R95/R121) shading preserved.
- Shaded faces remain more saturated/brighter than the target's (0.82/0.41 vs
  0.43/0.29): that remainder lives in relief dark tones + the R108/R109 light rig,
  which this round was instructed not to re-grade. Stated, not hidden.
- Prims identical to R121 in all views (495717 full) - no geometry changed.

## Perf
- round198: draws=282 (was 283; one roof key consolidated by the colour rename,
  cap 290), prims=495717 (close 188/470533, hill 172/456300).

## Honest verdict
FAIL as an overall target match (still borderline ~6.5/10 expected). Colour was only
half the suspected gap: hue/value already matched, and the fixable part (excess
saturation) is now halfway to the target's measured muting while keeping the red
settlement signal. Roofs still read as muted low-poly prisms/cones (R121's form
limit), and shaded roof faces stay livelier than the target's. Further desaturation
was measured and rejected on evidence: it traded the red signal for mud.
