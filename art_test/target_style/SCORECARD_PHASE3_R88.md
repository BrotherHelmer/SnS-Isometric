# SCORECARD — Phase 3 R88 (round163): varied-area rubble (internal only)

**Reference note:** the original `helmer_target_look_2026-10-18.jpg` is missing
on this box after the filesystem change; the judgement reference was restored
by cropping the target panel out of the repo's `SCORECARD_PHASE3_R87.png`
side-by-side and saved in evidence as `phase3/target_reference_restored.png`.
Judged against that bottom-half target composition as before. Work done in the
fresh clone `/workspace/sns-beta-r88` @492a492.

## Varied cell areas — 7/10
`stone_painted.png` repainted, keeping R87's toroidal-Voronoi rubble approach,
muted warm-grey family and tint-through:
- Multi-scale seeding: 8 isolated large seeds with a 330-360px keep-out for all
  other points (very large cells), 34 medium seeds, ~60 small stones clustered
  around 14 anchors plus small fill. **Measured cell areas: min 12,330px,
  median 40,022px, max 163,208px — max/median 4.1x, min/median 0.31x** (R87
  was visually near-uniform).
- Warm spread widened inside the family (warm/cool ±14, 15% of stones get an
  extra warm tan push); palette base and the 45% stone tint-through unchanged.
- No horizontal bands, multi-direction joints, irregular mortar bands,
  per-stone edge shading/blotches/cracks as R87. Toroidal wrap re-verified on
  tower cylinders (facade close shows no seam banding).
**Is cell uniformity actually broken at full frame? In the texture and in
close, yes clearly** — facade close shows very large pale stones beside small
clustered ones on castle tower/roundhouse. At full frame the mix reads, but
more quietly: the castle still reads **grey-warm first**, rubble second,
despite the wider warm spread — honest note, the 'grey first' reading is
reduced, not eliminated, and I did not change palette family to chase it.
Relief scale check: the largest texture stones (~0.6-0.7u-equiv) are somewhat
bigger than R85 relief stones (0.24-0.52u), but relief still reads as proud
blocks over the texture in close — no clear clash, relief left unchanged.

**Overall honest self-score ~6.5/10. Not a Black PASS claim.**

## Perf
R88 round163: **273 draws / 312,737 prims / ~141,279 authored tris** — identical
to R87 (texture-only). A `--import` pass was needed on the fresh clone before
rendering; no import/settings files are included in the commit.

Renders: evidence `phase3/round163.png` + `phase3/round163_close.png` (1280x800),
`phase3/target_reference_restored.png` restored reference.
