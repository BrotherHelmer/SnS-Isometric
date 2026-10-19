# Phase 3 — R102 Scorecard (round177) — internal only

## MY CHOICE (stated as required): sharper ledges
R101's own diagnosis: the 0.52u terrain grid caps step sharpness achievable in `_h` displacement, so the root fix at judge scale is **added geometry**, not more displacement. R101 `_h` displacement is kept (it reseats everything and breaks the close read); this round fixes the full-frame read with geometry.

## Change (`target_style_scene.gd`, `_build_hill`)
- R101's 10 small benches (2.2–3.4u, 0.5 high) replaced by **14 sharp ledge slabs, 2.6–5.0u wide, 0.7–1.15u high, 1.3–2.0u deep**, staggered down the fall line with varied yaw (±0.30), tilt and heights — shattered strata, deliberately not aligned stairs and not horizontal banding (stagger lesson from R95 cones).
- 5 of them carry a smaller stacked sub-slab offset on top (same colour key).
- Material lesson applied mid-round: first pass used the "rock" texture key × brown outcrop tints and read as **timber planks** at full frame — rejected. Final: flat slope-matching grey-tan colours (9a8a76 / 8a7a66 / a89478, 3 keys), flat-shaded BoxMesh faces, crisp edges.
- Seating: centre at `_h(x,z)+0.18·h` (deeply half-buried against the displaced R101 surface; verified in hill close — no floating cantilevers after deepening, no buried watchtower/mine/terraces).
- Placement kept clear of the mine (14.5,-11.5), watchtower (14.2,-6.9) and the switchback corridor; no ledge at the crest — mine remains sole crest focal point. Snow fans/switchback/terraces unchanged and still seated on `_h`.

## Perf
- Full frame: **278 draws** (cap 290; R101 was 279 — rock-key reuse attempt reverted for colour reasons, 3 flat colour keys net −1 vs R101's 4), prims 372,612, authored tris ~163,546.

## Judgement (full frame vs target + hill close)
- Full frame: the upper-right slope now shows distinct stepped grey-tan slabs breaking the surface — the wavy-contour read of R101 is replaced by stepped geometry that survives judge scale. Composition unchanged: one brown slope upper-right, not a wall.
- Hill close: ledges seat into the displaced heightfield, edges crisp, sub-slabs read as shattered steps.
- Honest limit: slabs are still recognisably rectangular blocks — angular and staggered, but more "cut ledges" than fully rubble-shattered rock. The smooth-welded read is gone at both scales; whether the slab read is broken enough is Black's call.

## Verdict
**R102: honest self-assessment — borderline.** The specific R101 failure (wavy contours at full frame) is addressed at the root with judge-scale geometry and no regressions; remaining risk is slab regularity. Awaiting Black. Nothing to Helmer.
