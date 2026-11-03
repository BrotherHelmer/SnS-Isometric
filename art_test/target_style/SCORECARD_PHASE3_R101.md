# Phase 3 — R101 Scorecard (round176) — internal only

**Method chosen: change `_h` itself in the rock zone** (not added-geometry-only). Rationale: every hill feature seats via `_h` at build time — mine (`_h(14.5,-11.5)`), watchtower, switchback road segments (`_h(mid)`), terraces (`_terrace` conforms to `_h`), snow jagged fans and ground patches (per-vertex `_h`), hill trees, outcrops/talus, ribs — so displaced heights reseat all of them coherently with no float/sink risk from stale heights.

## Change (`target_style_scene.gd`, `_h` + `_build_hill`)
- Rock-zone mask `rzm = clamp((hill+nemass)/7) * clamp((x+2)/6)` — full on the brown slope/crest, fading to **zero** at the grass-rock boundary, in the settlement, and on the left green hills.
- Displacement: multi-scale sines (2.9 / 5.7 / 7.3) + angular `abs(sin)` ridge term, **step-quantized** (`floor(rdsp*2.8)/2.8`, 65% mix) ×1.15 — ledges/benches rather than smooth waves; max ~±0.9u on the face, typical ~0.4u.
- 10 seated ledge boxes (2.2–3.4u long, half-buried at `_h+0.10`, flat-shaded, warm rock tones, varied yaw/tilt) across the face — silhouette/shading breaks independent of terrain grid resolution (0.52u).

## Side-effect verification
- Settlement/buildings: `rzm=0` there — full frame settlement pixel-identical in seating; nothing floats/sinks.
- Grass-rock boundary: mask fades over ~6u in x and with hill/nemass falloff; hill trees/terraces at the boundary reseat via `_h` (checked in hill close — grounded).
- Mine: seats at `_h(14.5,-11.5)+0.55` — remains sole crest focal point, grounded in both views.
- Snow jagged fans / ground patches: per-vertex `_h` seating — reseated on new heights.
- Switchback road: segment boxes at `_h(mid)+0.06` — reseated.
- Rock texture R100 and all other surfaces unchanged.

## Perf
- Full frame: **279 draws** (275 R100 + 4 ledge colour keys; cap 290), prims 372,504, authored tris ~163,438.

## Judgement (full frame vs target + hill close)
- Slope silhouette and shading now break up: stepped ledge shading and displaced contours replace the smooth welded read of R100, strongest in the hill close (stepped bands + flat ledge faces on the left face).
- Honest limit: at full-frame distance the displacement still reads partly as wavy contouring rather than fully shattered rock — the 0.52u terrain grid caps how sharp the steps can be, and the ledges are small at this framing. Improvement is real but modest full-frame.

## Verdict
**R101: FAIL expected (self-assessed)** — geometry-before-texture applied at the root (`_h`) with clean reseating and no regressions; slope is measurably less smooth-welded, but full-frame broken-hill read vs target likely still short. Awaiting Black. Nothing to Helmer.
