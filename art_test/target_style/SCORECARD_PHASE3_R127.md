# Phase 3 R127 - Scorecard

## Choice (stated)
Spend part of R126's freed prim headroom on Black's standing remainder: woods
hugging the village. Tree clusters in the outer gaps between buildings - no
building moves, R111 apron and all paths frozen.

## What was added (16 trees, screened as R124/R125)
7 near (9x5 construction) + 9 far (8x4) in outer gaps: west gap behind the
hut/roundbarn, behind the aframe, between hut and aframe, south gaps between
house/aframe and hut/octstore (bottom-centre), east gap between roundhouse
and the hill hut, and far trees filling behind roundhouses toward the hill
foot. Every near position passes the builder's hash cull (two first picks were
culled by it and were replaced with passing spots in the same gaps - checked,
not assumed), >3.5u from buildings except two at 3.5-3.6u behind buildings
(north side, doors face south - verified no door/path/carrier occlusion at
full frame), apron centre >8.5u from every new tree.

## Prim accounting (ceiling held)
- Ceiling set before placing: stay well under the 620,455 R125 peak, target
  <= ~550k. Result: 492,455 (R126) -> 521,621 (R127), +29,166 for 16 trees.
- Implied costs at current constructions: near ~3,200 prims/tree (9x5),
  far ~736/tree. Total is 99k under the R125 peak and only ~26k above the
  pre-framing R123 level, with R124+R125+R127 framing all in place.
- Draws 283 (unchanged, merged canopy/surf keys).

## Verification
- Full frame: outer buildings now have crowns behind/between them on the
  west, south and east edges; the settlement edge reads nestled rather than
  lawn-disc-inside-woods. Centre, castle apron, foreground centre, mine
  crest/switchback all stay open; carriers visible; no door or path covered.
- Hill/close views confirm nothing new blocks the slope or village focus.

## Honest verdict
FAIL as an overall target match (still borderline ~6.5/10 expected). The edge
reading is genuinely closer to the target's nestled settlement, at a quarter
of the prims R124's approach would have charged. Remainder: each building
still keeps its own clear yard (the frozen R110-R112 layout), so at close
range the village is buildings among trees rather than buildings inside
woods - the target's trees also stand between houses at the centre, which
the frozen apron/layout rules rightly forbid here.
