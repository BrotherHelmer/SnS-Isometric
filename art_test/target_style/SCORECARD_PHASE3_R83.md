# SCORECARD — Phase 3 R83 (round158): modelled relief facades (internal only)

## My choice: denser facade detail as MODELLED RELIEF (not more texture pattern)
Reason: R79's texture pattern inside panels enriched the texture read but did
not read as individual stones at full frame (mip-averaging, R18/R41/R65/R66
evidence again); modelled relief (R30-era extruded stone) casts real
light/shadow gaps at face scale and survives mip-averaging. Background left
exactly as R82 (organic recession, validated). No fine texture strokes added.

## Modelled relief — 6.5/10
- **Castle**: extruded large stone blocks (0.34-0.50u, 0.08-0.09 proud) on the
  keep front (3x3 staggered grid) and all 4 tower fronts (5 stones each,
  alternating values), on top of the pre-existing front/right relief courses.
- **Houses** (every `_build_house`): 4 foundation stone blocks across the front
  skirt and diagonal timber braces on the front frame; shingle slabs thickened
  (0.06 -> 0.085) so roof rows read as stepped relief more strongly.
- **Roundhouses**: 5 foundation arc stones following the drum curve.
All relief uses pre-existing colour keys only (castle relief
stone.darkened(0.12)/lightened(0.07)|stone, timber 54381f|timber, roof
dark/light keys): **draws unchanged at 273**, prims +0.6k only.
Facade close shows the relief shadow gaps on castle tower + roundhouse base;
at full frame the castle front and foundations read chunkier/more modelled,
though relief is still modest next to the target's dense hand-painted facades
— stones are large and sparse by design (0.35-0.5u) to survive the frame size.

**Overall honest self-score ~6.5/10. Not a Black PASS claim.**
Terracotta roofs and all R69-R82 gains kept (terraces, depth, snow, mine focal).

## Perf
R83 round158: **273 draws / 311,909 prims / ~140,499 authored tris** (R82: 273 draws).

Renders: evidence `phase3/round158.png` + `phase3/round158_close.png` (1280x800).
