# Phase 3 R121 - Scorecard

## Choice (stated)
Village rooftops - roof FORM variety per building type. Castle roofs/cones untouched
(roof2 legacy path preserved for the castle keep and market stall), walls/openings
R104-R106 unchanged except reseats noted below.

## Diagnosis (before R121)
- Houses (x2): roof2 deformed prism with only 3 pitch values tied to the wall variant,
  identical ridge treatment (two fixed segments + full light line) and fixed plan size
  on every house; shingle relief (R83/R94) already good.
- Aframes (x2): bare roof2 slabs - no ridge cap, no shingle relief at all; the roof is
  the whole building, so this was the largest single gap.
- Roundhouses (x2), roundbarn, octstores (x2): smooth textured cones (12/14/8 sides);
  village cones never got the R95 tile-ring relief the castle cones have. Heights
  mostly fixed (roundhouse had a small sin variation only).
- Huts (x5): thatch cone height/rings/battens identical on every hut (rings at fixed
  heights regardless of cone, 8 battens always, fixed cap).

## What changed (existing keys only, zero new draws)
- roof2 gains an opt-in seeded variation path (v121): per-building ridge sag
  (0.06-0.24), twist/eave-drop amplification, gable king-post + seeded diagonal brace
  on the plaster gables, and (v121=2) a segmented ridge cap following the sag.
  Castle keep roof and market stall call the legacy path - geometrically untouched.
- Houses: pitch jitter x0.92-1.08 on top of the 3 variants, roof plan/overhang jitter
  (width x0.94-1.08, depth x0.95-1.06), ridge segment positions/lengths jittered,
  eave trim reseated to the varied plan. Chimneys/dormers ride the same pitch variable.
- Aframes: opt-in roof2 (gable timber + ridge cap) plus 3 seeded shingle rows x2
  segments on both slopes in the existing house shingle tones.
- Village cones: R95 _cone_relief ring segments (helper unchanged) on roundhouse,
  roundbarn and octstore cones; barn cone height varies +-0.30, octstore cap +-0.18
  with its stone cap reseated; relief tones reuse the existing a15f43 family keys.
- Huts: thatch cone height x0.88-1.18 per hut, rings recomputed as cone fractions,
  eave ring and cap reseated on the varied cone, battens rotated by a seeded offset
  with one sometimes missing.

## Verification
- Full frame: cones now carry segmented tile rings (clearest on the roundhouses),
  aframe roofs show rows + ridge, hut thatches differ in height/profile; no roof
  floats or detached caps seen in full/hill/close; castle cones/roofs pixel-identical
  construction (legacy path), R115/R116 forms intact.
- Colour guard: no new roof colours - all tones are the existing muted roof.darkened/
  lightened and a15f43/9c4a34 keys; nothing went bright (roof material groups unchanged).
- Reseat check: hut chimneys still pierce the varied thatch (offset from cone axis),
  octstore cap sits on its varied cone, house dormer/chimney ride pitch2 as before.

## Perf
- round197: draws=283 (cap 290, unchanged), prims=495717
  (close 189/470533, hill 173/456300). Authored tris ~201k (+2.8k relief).

## Honest verdict
FAIL as an overall target match (still borderline ~6.5/10 expected). The repeated-slab
reading is reduced where it was worst: village cones are now tiled constructions like
the castle's, aframes have ridges and shingle rows, and no two hut thatches share a
profile. At full frame the gain is real but modest - most roofs are 40-90px and the
roofp texture was already doing much of the work; this round removes the identical-form
tells rather than transforming the roofscape. Roofs remain muted low-poly prisms/cones
versus the target's painted tile/thatch masses.
