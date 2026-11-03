# Phase 3 — R103 Scorecard (round178) — internal only

## Change (`target_style_scene.gd`)
- New helper `_rock_prism(rw, rd, h, seed)`: irregular rock fragment built as a jittered hexagonal prism — footprint corners angle/radially jittered (non-parallel edges), top face chamfered (0.72–0.92 inset) with per-corner height variation (varied thickness along the length, broken corners), flat-shaded per-face normals.
- Each R102 ledge is now **2–3 such fragments split by shadow gaps and offset** (main + side fragment at different yaw/tilt/height; every third ledge adds a smaller stacked fragment on top). Seeded per ledge (`seed = li*7.13+3.7` driving all jitters) — no two read alike, none is a box.
- Kept from R102: same 14 ledge positions/footprint widths (2.6–5.0u — judge-scale break preserved), flat slope-matching grey-tan family (9a8a76/8a7a66/a89478, same 3 colour keys — the timber-plank texture mistake not repeated), deep seating per fragment on the displaced `_h` (each fragment seats at its own `_h(x,z)`).
- Kept: R101 `_h` displacement, R100 rock texture, mine as sole crest focal point (placement still clears mine/watchtower/switchback), snow fans/switchback/terraces untouched.

## Perf
- Full frame: **278 draws** (unchanged, cap 290), prims 372,978, authored tris ~163,912 (+~370 fragment tris vs R102).

## Judgement (full frame vs target + hill close)
- Full frame: ledges no longer read as rectangular cut steps — the slope carries irregular angled chunks with visible gaps between fragments; size still breaks the slope at judge scale (R102 gain kept).
- Hill close: fragments seat on the displaced heightfield, chamfered tops and offset splits read as shattered strata pieces; no float/bury observed, nothing buried over terraces/paths.
- Honest limit: individual fragments can read as chunky hexagonal tablets in the close view (regular 6-corner base under the jitter); at full frame the aggregate reads shattered rather than cut. The rectangular-slab failure Black named is addressed at the geometry root.

## Verdict
**R102's named failure (rectangular cut ledges) fixed in form; overall PASS/FAIL is Black's call** — self-assessed borderline-to-improved, no regressions. Awaiting Black. Nothing to Helmer.
