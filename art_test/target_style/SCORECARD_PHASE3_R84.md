# SCORECARD — Phase 3 R84 (round159): relief, denser (internal only)

Reference: R83 round158. Target bottom half, full frame + facade close.
Choice continued from R83: modelled relief, denser. Background left as R82,
no texture strokes, all R69-R83 gains kept (terracotta roofs included).

## Relief density — 6.5/10
- **Castle keep**: R83's sparse 3x3 replaced by a 4-col x 5-row staggered grid
  (0.40x0.30u stones, 0.08 proud, alternating dark/light values, occasional
  deliberate gap) — front face now reads as continuous stonework.
- **Castle towers**: second staggered column added (5 -> 10 stones per tower
  front, 0.30-0.34u), filling the R83 single-column layout.
- **Houses**: foundation stone blocks extended around both visible sides
  (3 per side), two centre timber posts added to the front frame (proud
  54381f|timber geometry, joining existing posts/braces/beams), and a front
  eave trim bar (roof.darkened(0.35), existing key).
- **Roundhouses**: second staggered arc course at the base top plus a timber
  ring cylinder around the plaster drum (existing timber key).
Draw discipline: every stone reuses R83's exact keys
(stone.darkened(0.12)/lightened(0.07)|stone, 54381f|timber, roof keys) —
**draws unchanged at 273**, prims +0.8k for the added geometry.
Honest remainder: stonework is continuous on keep/tower fronts now and reads
modelled at full frame, but stones remain medium-and-regular compared with
the target's dense, irregular hand-painted masonry; that irregularity (varied
stone sizes/shapes per block) is the next lever if relief continues, not more
uniform rows.

**Overall honest self-score ~6.5/10. Not a Black PASS claim.**

## Perf
R84 round159: **273 draws / 312,737 prims / ~141,279 authored tris** (R83: 273 draws).

Renders: evidence `phase3/round159.png` + `phase3/round159_close.png` (1280x800).
