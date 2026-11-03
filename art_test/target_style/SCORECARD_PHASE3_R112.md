# Phase 3 — R112 Scorecard (round187) — internal only

## MY CHOICE (stated as required): continue airiness into the wider settlement
Market, southern houses and hill cluster — the zones Black named — with the proven R110/R111 exact-coordinate method. Castle apron (R111) and SW/mid-east lanes (R110) kept.

## Diagnosis by zone
- **Market:** two stalls. Stall #1 (-4,6.45) had been glued to the R110-moved aframe (footprints overlapped, reading as one mass); stall #2 (5.9,7.9) sat ~2.7u from the R110-moved hut. Neither read as an open square.
- **South:** house (15,5.5), octstore (14,12.5) and the (13,10) tree formed a tight triangle; east house carried full R75 clutter.
- **Hill cluster:** hill hut (17.5,1.0) sat close under the watchtower/mine terraces; spacing-safe only (composition and mine focal point untouched).

## Changes (`target_style_scene.gd`, layout only)
- Market #1 shifted +1.6u east (posts/roof/crate/sacks together) off the aframe; market #2 (5.9,7.9)→(4.2,9.0), opening the square against the hut.
- South: house (15,5.5)→(16.8,7.8) and octstore (14,12.5)→(12.8,14.2), all references moved (build calls, detail anchors, yards, path polylines incl. the 14.0,12.0 path end →13.0,13.6); gluing tree (13,10) removed; east house added to the clutter skip list.
- Hill: hut (17.5,1.0)→(19.2,2.8) — seats via `_h` in its build call and in the detail pass (R101 displacement zone; verified grounded in the south/hill crops, no float/sink against the displaced heights). Mine, watchtower, terraces, snow untouched.
- Replacement counts verified per coordinate (1–2 sites each, as expected). Freed ground is open meadow with paths; nothing refilled; settlers/pennants/lit windows remain throughout.

## Perf
- **283 draws** (unchanged), prims 458,132, authored tris ~165,974.

## Judgement (full frame vs target, first glance)
- Market stalls now stand apart from houses; southern buildings read as separate forms with grass between; the hill hut sits clear of the terraces. Settlement remains inhabited everywhere.
- **Honest limit, stated plainly:** after R110+R111+R112, each zone has been spread as far as individual safe moves allow. What remains is the village's fundamental footprint — buildings are simply closer together, on a smaller disc, than the target's painted village. Further airiness is no longer a sequence of safe moves; it is a wholesale re-layout (new building positions, path network, detail web and yard system designed together), with correspondingly higher breakage risk. That is the honest ceiling of this method.

## Verdict
**R112: honest self-assessment — wider settlement airier zone by zone, borderline overall; layout-move method approaching its ceiling.** Awaiting Black. Nothing to Helmer.
