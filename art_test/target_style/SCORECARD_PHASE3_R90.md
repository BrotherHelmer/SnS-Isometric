# SCORECARD — Phase 3 R90 (round165): per-face warmth (internal only)

Reference: restored target, R89 round164. Rubble layout, warm palette family,
terracotta roofs, background unchanged.

## Per-face / per-orientation warmth — 6.5/10
Implemented at the material root, not as overlay slabs: in `mat_for`, the
`stone` texture branch now returns a ShaderMaterial whose fragment warms or
cools by **world-space face normal** against the top-left sun direction
(normalize(-0.45, 0.75, 0.50)): sun-facing faces multiplied by warm
(1.10, 1.01, 0.86), opposing faces by cooler/darker (0.90, 0.96, 1.05),
smooth in between. It applies to every stone-textured surface (castle walls/
towers/keep, house foundations, roundhouses, relief stones using the stone
texture) with the real geometry orientation, and the R89 tint is passed as the
shader `tint` uniform (45% lerp preserved, texture sampled at uv 0.55 as
before). Family variation on top: keep uses `stone.lightened(0.06)` and the
four towers `stone.darkened(0.07)` as their tint colours (2 new material keys).
Full frame: neighbouring castle faces now tell visibly different warm stories
(lit front warm, side faces cooler), towers sit slightly cooler than the keep,
and the wall as a whole **still reads warm first** — the cool side is a shaded
warm-grey, not a return to cool-grey-first.
**Roundhouse blank stone (R89 flag): still stands out.** Per-face work does not
fix it — that drum face has one normal, so it takes one uniform tint; the very
large pale texture cell there remains a blank area in close. Reported, not
touched (fixing it is relief/texture-cell work, not per-face warmth).

**Overall honest self-score ~6.5/10. Not a Black PASS claim.**

## Perf
R90 round165: **275 draws / 312,749 prims / ~141,279 authored tris** (R89: 273;
+2 exactly from the keep/tower family keys, <=290 as required).

Renders: evidence `phase3/round165.png` + `phase3/round165_close.png` (1280x800).
