# Phase 3 — R118 Scorecard (round193) — internal only

## MY CHOICE (stated as required): finish the path root
Replace the two-step flat halo with a genuinely feathered edge and give the dirt hand-painted variation — Black's two named remainders. No building/layout moves; endpoints byte-identical.

## Feather method — diagnosis and honest choice
Alpha-gradient decals were considered and **rejected, stated plainly**: a transparent ground material would (a) need a new transparent draw key, (b) risk depth-sorting artefacts against the opaque terrain in the headless GLES3 render (paths sit at three stacked heights within 0.03u), and (c) cylinder/box UVs are not radial, so a painted radial falloff cannot map cleanly onto branch discs. The honest in-construction feather is an **opaque 3-step tonal fringe with irregular breaks**:
- Outer step: grass-transition tones (existing patch keys 7fae4a/6f9a42, alternating per segment/path) at width +1.18 with seeded width jitter; junction fringe discs r1.28.
- Mid step: the R117 worn a8895a at +0.60. Dirt surface on top as before.
- **Irregular fringe blobs** (flattened, existing keys) at seeded intervals on alternating edges of every main segment, breaking the remaining ring line; branch paths get the same outer fringe disc (r+0.60) under the worn step.

## Dirt variation
- `dirt_painted.png` repainted: base darkened (mean (168,140,96)→(156,132,89) per Black's "lighter than target"), 36 large soft tonal patches (120–340px: tan/grey-brown family), cluster speckle at soft scale, and subtle olive encroachment patches along the canvas edges. R117 worn centres, ruts, widths and junctions kept.
- Grass (R96/R97/R113) unchanged and visible right up to the fringe; castle apron/hill unchanged.

## Perf
- **283 draws exactly** (fringe uses already-existing patch colour keys; dirt is the same texture key), prims 477,731, authored tris ~179,418 (fringe geometry).

## Judgement (full frame vs target + close edge check)
- Close: the path edge now steps grass-green → worn tan → dirt with irregular blob breaks; the single hard ring of R117 is gone. Dirt surface has visible tonal patchiness and darker, richer value.
- Full frame: paths sit *in* the meadow rather than on it; junctions read as worn crossings.
- Honest limit: it is a graduated 3-step edge, not a continuous alpha feather — at very close range the steps can still be told apart, and that is the construction's honest best without transparent decals. Dirt variation is present but still more uniform than the target's hand-painted ground.

## Verdict
**R118: honest self-assessment — both named path remainders addressed at the root available to this construction; borderline overall.** Awaiting Black. Nothing to Helmer.
