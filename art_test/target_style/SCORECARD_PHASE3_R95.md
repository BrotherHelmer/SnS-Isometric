# SCORECARD — Phase 3 R95 (round170): cones hand-tiled, not stepped (internal only)

Reference: restored target, R94 round169. Same focus as R94 (roofs), all other
gains/background unchanged. House gables left as R94 (their slab rows did not
show the stepped-band reading; verified in full frame).

## Breaking the stepped rings — 7/10
`_cone_relief()` reworked at the root:
- Continuous cylinder rings **removed**. Each cone level (5 levels at
  t=0.16-0.90) is now a ring of individual tile segments: segment count scales
  with circumference (5-10), each segment is a seeded box with tangential
  width 72-100% of its slot, height jitter ±0.035, random angular offset per
  level (staggered joints, no aligned verticals), slope tilt computed from
  the cone's own atan2(rb-rt, h), and **14% of segments randomly omitted** —
  gaps where the cone texture and individual tiles take over.
- Individual tile coverage roughly doubled: 4 levels x 7 tiles (was 3x5) over
  a wider visible arc (-1.25 to +1.55 rad, front + right side), seeded size
  0.17-0.28u / depth jitter / tilt, same existing tone keys.
**Do cones read hand-tiled or still stepped at full frame? Hand-tiled, mostly.**
The continuous horizontal bands are gone; castle cones read as chunky,
irregular tiled caps at full frame and individual segments/tiles with shadow
gaps in close. Honest remainder: the segments still organise into loose
courses (as real shingle courses do) and are more regular than the target's
hand-laid caps, so the read is "tiled/modelled" rather than fully painted.

**Overall honest self-score ~6.5/10. Not a Black PASS claim.**

## Perf
R95 round170: **275 draws / 317,153 prims / ~145,683 authored tris** — draws
identical to R94 (segments/tiles reuse the same 4 roof tone keys).

Renders: evidence `phase3/round170.png` + `phase3/round170_close.png` (1280x800).
