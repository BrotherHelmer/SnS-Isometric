# Phase 3 — R116 Scorecard (round191) — internal only

## MY CHOICE (stated as required): castle plan asymmetry
Castle-internal form, NOT village re-layout (not started; Helmer's pending decision). Village positions and the R111 apron are frozen; the castle stays in the same apron/footprint area.

## Diagnosis
The ground plan was a perfect rectangle: four towers at identical offsets (±1.85, ±1.45), identical footprints (r 0.58→0.45), keep centred, gate centred. R115 varied heights/roofs, but at first glance the *plan* still read as a symmetrical kit.

## Changes (`_build_castle` only; one plan array refactored through every tower-keyed element)
- New irregular tower plan `toff = [(-2.05,-1.60), (1.70,-1.30), (-1.65,1.55), (2.10,1.35)]` with varied footprints `trad = [0.64, 0.54, 0.50, 0.68]` (bottom radius; tops scale ×0.78). Towers embed unevenly into the main block corners.
- Everything tower-keyed follows the plan: tower cylinders, R115 cones/eaves (reseated per tower as in R115), side stones, R83 relief stones (south-face seating recomputed per radius: `off.y + trad + 0.04`), shadow strips and their inset stones (`trad×0.72 / ×0.88`), cone-top spires and pennants (`toff[0]/[3]`, `toff[1]/[2]`), front-tower banners (seated at `off.y + trad + 0.06`).
- Keep offset in plan (-0.25, -0.15): keep block, its cone, roof ring, flag, and the two keep-face patches all moved together (patch z recomputed to the keep's new front face, 0.815). Gate and gatehouse offset +0.35 in plan (gate panel, round gate boss, gatehouse block and its roof together).
- **Construction limit, stated honestly:** true wall-angle changes are not possible in the current construction — curtain walls are the noised main block (an axis-aligned box), so walls remain straight runs between the offset towers. No texture fakery was used; asymmetry is real geometry in tower placement/footprint, keep and gate.
- All surfaces (R86–R95 stone/roof, R90 warmth, R106 openings) and R115 heights/cones/pennants kept; no layout moves outside the castle; hill/mine unchanged; R111 cleared air not encroached (towers stay within the original footprint envelope ±0.25u).

## Perf
- **283 draws exactly**, prims 458,360, authored tris ~166,170 — no idea exceeded budget; nothing dropped.

## Judgement (full frame vs target + castle crop)
- Castle crop: towers now sit at uneven depths and widths — the smaller SW tower, larger SE tower, offset keep and gate break the mirrored read; banners/relief/shadow strips all sit correctly on their moved towers (verified, nothing floating or detached).
- Full frame: the stronghold reads more hand-built and remains the clear centre focal point in its apron.
- Honest limit: from the iso camera, plan asymmetry reads less strongly than height/roof variety did in R115 — the eye catches towers stepping unevenly rather than an obviously irregular footprint; and the straight curtain walls (construction limit above) still give modelled order. It is an irregular-plan modelled castle, not a painted one.

## Verdict
**R116: honest self-assessment — plan symmetry broken in real geometry within the castle footprint; borderline overall.** Awaiting Black. Nothing to Helmer.
