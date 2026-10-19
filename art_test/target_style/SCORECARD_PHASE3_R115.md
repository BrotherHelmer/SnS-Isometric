# Phase 3 — R115 Scorecard (round190) — internal only

## MY CHOICE (stated as required): the castle's own form
Centre-of-frame focal form in both images; surfaces were done (R86–R95, R106), form variety had never had a round. No layout moves; no wholesale re-layout (Helmer's pending decision).

## Diagnosis (castle form vs target)
- Four corner towers stood at identical offsets with near-uniform heights (3.05–3.75) and — the kit tell — **identical cones (h1.7, r0.72) all seated at the same y=3.95 regardless of tower height**, with eaves rings also at fixed heights. Silhouette = four matching cones in a row.
- Central keep cone and annex tower existed, but the front face relied on two banners + gate; two cone tops had stone spires, two were bare; no pennants on the castle itself (target language: lively roofs + banners).

## Changes (`_build_castle` only; all existing keys, merged as before)
- Tower heights spread: [3.15, 3.95, 2.85, 4.05]; cone heights/pitches and radii varied per tower [1.50/1.90/1.30/2.00, r 0.66–0.80] and **seated on each tower's actual top** (eaves rings likewise reseated relative to tower height). Hand-tiled `_cone_relief` (R95) follows each cone.
- The two existing cone-top spires reseated onto the new apexes; **pennant poles added on the other two cone tops** (existing 6b4423/d43a2a keys).
- Two hanging banners added on the front towers (existing c22e22 key, varied height/size — the front towers previously had none; keep-face banners kept); small dormer turret added on the keep front (stone/roofp keys).
- All validated castle surfaces untouched in method: warm rubble (R88–R92), per-face warmth shader (R90), hand-tiled cones (R95), openings (R106). Castle stays central focal in its R111 apron; every other building/layout position frozen.

## Perf
- **283 draws exactly**, prims 458,360, authored tris ~166,170. No new keys were needed, so no form idea had to be dropped for budget.

## Judgement (full frame vs target + castle close)
- Full frame: the castle silhouette is no longer a row of matching cones — towers step at four heights, cones vary in pitch, pennants and front-tower banners catch the eye; it reads as a more hand-built stronghold and remains the clear centre focal point.
- Castle close: rubble stone, per-face warmth, tiled cones and framed openings all still read as before (surface gains verified intact).
- Honest limit: the massing underneath is still the same symmetrical four-corner plan (offsets unchanged) — variety was added in heights/roofs/dressing, not in plan asymmetry; and forms remain modelled low-poly, not painted. It is a varied kit, closer to the target's liveliness, not yet a painted castle.

## Verdict
**R115: honest self-assessment — castle form variety achieved at silhouette level; borderline overall.** Awaiting Black. Nothing to Helmer.
