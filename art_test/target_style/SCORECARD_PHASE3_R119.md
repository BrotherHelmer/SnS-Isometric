# Phase 3 R119 - Scorecard

## Choice (stated)
Settlement life - settlers/carriers (Black's nominated next decisive point): give the
settlement people-with-purpose readable at full frame. Layout, surfaces, paths unchanged.

## Diagnosis of existing figures (before R119)
- GLB characters: 8 carriers (scale 0.62, walking pose) on/near paths carrying NOTHING -
  loads invisible/absent; 7 statics at workplaces (chopping/hammering/idle) - these read
  best and were kept.
- _mini blocky figures (19: settlers, mine/field workers): ~1.25u tall, single raised arm,
  no loads, no ground contact - at full frame they read as tiny coloured markers; several
  sit scattered rather than clearly on routes/workplaces.

## What changed (all merged into EXISTING colour keys, zero new draws)
- _mini rebuilt larger (torso 0.42->0.50, height ~1.25->~1.5u), contact-shadow disc
  (existing alpha key, consistent with tree/boulder discs and grounds figures against the
  R108 sun shadows), seeded carried goods per figure (side sack / back crate, existing
  c9b18a/a67c4e keys).
- _build_carrier gains clothing-colour + load variants (log / back crate / twin sacks);
  3 merged carriers placed ON R117/R118 routes: main path east junction (red, crate),
  main path west (green, shoulder log), hill branch path (blue, sacks).
- Shoulder logs (8) + alternating sacks merged at the 8 GLB carrier positions so the
  animated carriers visibly carry goods in the still frame.

## Verification
- Full frame: figures now read as small people across paths/yards (hats, red/blue/green
  torsos, logs/sacks visible in centre crop); settlement feels populated at first glance,
  not empty/modelled. Grounded: contact discs + seated on _h/0 ground, no floaters seen.
- Workplace statics (mine switchback minis, field workers, GLB choppers) unchanged and
  still read as working figures.
- Breakage check: none - surfaces/paths/layout untouched; close frame confirms figures
  sit on paths without covering path painting.

## Perf
- round194: draws=283 (cap 290, unchanged - everything merged into existing keys),
  prims=483051 (close 188/458479, hill 173/443634).

## Honest verdict
FAIL as an overall target match (still borderline ~6.5/10 expected), but the settlement-
life gap is genuinely closed in kind: people-with-loads on the actual path routes read
at full frame for the first time. Remainder: figures are still simple constructions
(~15px at judge scale) versus the target's painted carriers, and several GLB shoulder
logs sit approximately (pose-dependent) rather than in animated hands - acceptable in a
still frame, stated plainly.
