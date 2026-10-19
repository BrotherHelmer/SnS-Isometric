# Phase 3 — R117 Scorecard (round192) — internal only

## MY CHOICE (stated as required): the dirt path network
Large frame share, ties every building together, no dedicated round since early work. No building moves — paths follow the R110–R112 layout exactly; no wholesale re-layout (Helmer's pending decision).

## Diagnosis (paths vs target)
- Main winding path: single hard-edged textured boxes, 1.05u wide, with r0.58 node discs — an applied ribbon with a crisp outline on the grass.
- Branch paths: uniform r0.60 discs every 0.65u — a scalloped strip of identical width with no wear variation.
- No worn centre, no ruts, junctions only where discs happened to overlap; colour/value close to the worn yards, so the ribbon edge did all the (wrong) work. Target: wide, light, soft-edged worn dirt with natural variation and rounded junctions.

## Changes (path geometry only; existing keys: dirt texture, a8895a/8a6c42 worn, d9ba7c light dirt)
- **Soft edge:** every main segment and branch step gets a wider worn underlay (a8895a) beneath the dirt surface — a halo that breaks the hard ribbon outline into worn ground.
- **Width + variation:** main segments widened 1.05→1.25–1.55u with per-segment seeded widths (rng seed 11701); node discs 0.58→0.80 with 0.98 underlays (rounded junctions); branch disc radius varies 0.56–0.73 along each path (seeded sine by step/path).
- **Worn centres and ruts:** light centre discs (d9ba7c) along main segments; paired cart ruts (8a6c42, ±0.34u) on ~65% of main segments, seeded so no repeating strip pattern.
- All path coordinates, endpoints and door/gate connections are byte-identical to R116 — only widths, underlays and wear detail changed; every path was already authored against the moved buildings and still arrives at the same doors, thresholds and castle gate. Grass (R96/R97/R113) untouched and still visible between paths; castle apron and hill (incl. switchback) unchanged.

## Perf
- **283 draws exactly** (all added geometry merged into existing colour keys), prims 467,924 (underlay discs/boxes; authored tris ~172,618).

## Judgement (full frame vs target + path crop)
- Full frame: paths read as light worn ground threading the settlement rather than applied strips — edges soften into the grass, junctions round out, width breathes along each route.
- Path crop: halo edges, worn centres and ruts are visible at close scale without becoming a repeating pattern; buildings still sit on their yards with paths arriving at doors.
- Honest limit: the underlay halo is a flat colour ring, not a feathered blend — at close range the two-step edge (halo, then dirt) can still be discerned, and paths remain lighter/more uniform than the target's hand-painted dirt variation. The ribbon read is gone at first glance; painted softness is approached, not matched.

## Verdict
**R117: honest self-assessment — paths converted from ribbons to worn ground at first glance; borderline overall.** Awaiting Black. Nothing to Helmer.
