# Phase 3 — R111 Scorecard (round186) — internal only

## MY CHOICE (stated as required): the castle centre itself
Finish what R110's small moves could not: an open meadow apron for the castle with clearly separated neighbouring forms.

## Diagnosis of castle crowding (before)
Octstore sat ~5.2u east of the castle and the NE roundhouse ~10.5u away; two full trees (1.5,-7.5) and (6,-6) flanked the towers so canopies merged with the castle mass at first glance; a bush sat NW; R75 side-clutter (woodpiles/lean-tos/crates) filled the remaining gaps around castle and octstore; the worn castle yard (r=2.35) read as a plaza apron.

## Changes (`target_style_scene.gd`, layout only, R110 coordinate discipline)
- **Octstore (3.2,-1.2)→(5.4,-0.4)** and **roundhouse (9,-4.5)→(10.2,-3.8)**: every reference moved by exact coordinate replacement (build calls, detail-pass anchors, worn yards, path polylines, flag poles, contact discs — replacement counts verified: 5+4 and 4+2 sites). Both keep flat-disc seating (radii 10.6/10.9); crops verify grounded.
- Two castle-flanking trees and the NW bush removed (removal only — R69 spacing discipline is about not crowding, nothing was added back).
- Centre clutter thinned decisively: castle and octstore homes (hi 0, 1) join the R110 skip list for R75 side-clutter; door lanterns/steps remain at every home.
- Castle worn yard 2.35→1.85 radius so the apron reads varied meadow with paths crossing it (target: paths across open grass, not a plaza), not bare dirt.
- Freed centre ground is open R96–R97 meadow, unfilled. Castle's own towers/wings intact and still the central focal group; hill/mine/snow composition and all surfaces R86–R110 unchanged.

## Perf
- **283 draws** (unchanged), prims 457,494, authored tris ~165,418.

## Judgement (full frame vs target + centre crop)
- Centre crop: the castle now stands in grass with clear air on its east and north sides; octstore and roundhouse read as separate forms; paths cross the apron to the castle doors. Still inhabited — settlers, pennants, lanterns and lit windows remain; it does not read Phase-2 sparse.
- Full frame first glance: the castle group separates more clearly from its neighbours than in R110, though the wider settlement (market, houses south, hill cluster) remains denser than the target's airy spacing. The specific named centre density is substantially opened; a fully target-airy village would need a wholesale re-layout, which this round deliberately did not do.

## Verdict
**R111: honest self-assessment — castle centre opened as briefed, borderline overall.** Awaiting Black. Nothing to Helmer.
