# Phase 3 R128 - Scorecard

## Choice (stated)
Per-building worked yards - if yards cannot be wooded under the frozen layout,
make the cleared ground read as lived working ground. No building/tree moves.

## Diagnosis (before R128)
Every village building already had an R76 worn patch - but centred on the
building, so most of it hides under the footprint, with stones and a shadow
blob; door sides were not specifically worked. Props existed near some
buildings from R75-era clutter (thinned in R110-R112) but not as a per-building
yard system. The two hill huts (8.2,-11.2 and 18.5,-8) had no yard at all.
Target yards are worked earth with wood piles, barrels, fences and carts on
the door side, tying buildings to paths.

## What was added (_worked_yard, existing keys only)
14 yards: all 10 non-house village buildings (door = +z/south), 2 hill huts
(slope-seated on _h, previously yardless), and both houses with the door
direction computed from their R105 hang rotation. Castle (has its R76 yard),
mine (R120 apron) and watchtower (R-aprons) deliberately not doubled.
Each yard: an R76-language worn patch offset to the door side (seats on _h),
plus 2-4 seeded props from {wood pile, barrels, crates, chopping block, fence
stubs, hand cart} - no two yards share a set, each prop sits on a contact-shade
blob in the existing yard shadow key. Doors and the door-side path line stay
clear (props spread perpendicular to the door axis); R119 carriers still read
on routes at full frame.

## Perf / accounting
- Draws 283 (unchanged - all props merge into existing colour keys).
- Prims 521,621 -> 532,861 (+11,240 for 14 yards, ~800/yard), inside the
  R127 ceiling (<=550k) and 88k under the R125 peak (620k).

## Verification
- Full frame + yard crop: buildings now sit in visibly worked ground -
  crates/barrels by roundhouse doors, wood piles and fence stubs on hut and
  aframe door sides, carts on two flat yards; ground reads worked, not lawn
  with props dropped on top, because the worn patch extends from the door.
- Hill view: hill hut yards seat on the slope without floaters.

## Honest verdict
FAIL as an overall target match (still borderline ~6.5/10 expected). The yard
system completes the lived-in reading at building scale within the frozen
layout: every building has a worked door-side with purposeful props. Remainder:
at full frame the yards are 20-40px features, so the first-glance change is
modest next to composition/colour; and yards remain tidy rectangles of
activity around each building versus the target's more continuous worn
ground between buildings (paths aside), which the frozen layout limits.
