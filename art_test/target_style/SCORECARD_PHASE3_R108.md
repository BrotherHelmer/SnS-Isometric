# Phase 3 — R108 Scorecard (round183) — internal only

## HEADLINE: SUN KEPT
The bounded experiment passes Black's test: real cast shadows + directional modelling move the first-glance image toward the target (soft top-left shadows grounding buildings/trees), with no validated reading broken and draws inside the cap. The sun version is committed as R108.

## Experiment protocol
- Baseline (BEFORE): R107 renders round182, same cameras (full/close/hill).
- Change: `add_child(sun)` executed (it was comment-swallowed in the baseline), sun rotation (-52,-38) — shadows fall lower-right, i.e. light from top-left, consistent with R90/R69 shadow language. PSSM 4 splits, blur 1.4 (R69 crisp-soft), opacity 0.70.
- Rebalance (part of the experiment, light roots only): sun energy had to come down to **0.20** — at 0.92/0.60 the frame blew out (measured mean 185 vs baseline 101; the R107 rig was ambient/omni-only, so any full directional doubles top-face light). Final rig: sun 0.20 warm (1,0.90,0.74), pools 0.15/0.12, fill 0.04, ambient amb×0.30, saturation 1.12 / contrast 1.10.
- Draw-budget fix: with all merged bodies casting, draws hit **399** (shadow pass). Merged surf bodies now cast OFF; canopy (trees), roof groups and cliffs keep casting — the grounding shadows that matter. Result: **283 draws** (cap 290).

## Before/after judgement (see R108_before_after.png, same camera)
- Cast shadows now ground trees and roofs across the settlement; directional modelling gives lit/shade sides on roofs, cones and the watchtower; hill close shows shadows seating the mine, terraces and trees.
- Breakage check against every validated reading: roofs still muted terracotta (not bright red) ✓; castle still warm rubble first ✓; cones still hand-tiled ✓; meadow varied, paths readable ✓; trees bright with shade masses, not near-black ✓; mountain composition and snow patches unchanged ✓; skin/wood/stone families distinct ✓; crisp, no fog/vignette added ✓.
- Honest reservation: the sun frame is brighter/paler than the target (mean ~153 vs target ~115) — sunny, but grass in full sun still reads lighter than the target's richer olive. The shadows/modelling gain is real; the exposure richness is not fully the target's.

## Perf
- Full frame: **283 draws** (≤290), prims 459,528 (shadow pass over the kept casters; baseline 375,288), authored tris ~166,206 unchanged. Headless full render ~8–11s (vs ~7s baseline) — shadow pass cost is the kept casters only.

## Verdict
**R108: SUN KEPT — experiment positive, self-assessed improvement toward target; overall PASS/FAIL remains Black's call.** Nothing to Helmer.
