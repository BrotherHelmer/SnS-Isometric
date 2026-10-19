# Phase 3 R126 - Scorecard

## Choice (stated)
Canopy prim economy - reduce near-canopy geometry cost while holding the
R98/R99/R113/R114 look. No placement, colour, layout or other surface changes.

## Trials (all measured, same scene otherwise)
Near crowns are displaced spheres (canopy_sphere) shared by _build_tree crowns,
mini-lobes, bushes and top-band canopies via add_canopy. Per-sphere tris:
13x7 = ~182, 10x5 = ~100, 9x5 = ~90, 8x5 = ~80.
| crown mesh | scene prims | vs R125 (620,455) | parity read |
|---|---|---|---|
| 13x7 (R125, round201) | 620,455 | - | reference |
| 10x5 | 507,815 | -112,640 (-18.2%) | holds at full frame + 2x crown crop |
| 9x5 (CHOSEN, round202) | 492,455 | -128,000 (-20.6%) | holds at full frame + 2x crown crop |
| 8x5 | 477,095 | -143,360 (-23.1%) | REJECTED: facets visibly coarsen on foreground crowns for only ~15k more |

## Parity evidence (stated honestly)
Pixel-diff round202 vs round201 is NOT near-zero (full-frame meanabs 5.8, 14.4%
of pixels change >30; crown regions ~28%): reducing face count re-indexes the
per-face cluster tones (R114 tones are face-index seeded) and resamples the
scallop, so individual cells move. Parity was therefore judged visually, not by
diff: at full frame the frame is indistinguishable at first glance, and at a 2x
foreground-crown crop the crowns keep the same scalloped silhouette, flat
cluster-cell facets, quantized tone steps and olive family at 9x5 - while 8x5
shows a clear coarsening step on the same crop. The diff numbers are reported
so the claim is checkable; the visual read is the parity criterion, as with
judge-scale lessons since R66.
Far trees unchanged (already 8x4 low construction from R125).

## Result
- Draws 283 (unchanged). Prims 620,455 -> 492,455 full (close 595,271 ->
  467,271; hill 581,038 -> 453,038). Per near tree the crown geometry roughly
  halves (~21 masses x ~90 tris saved); scene total is now BELOW the pre-R124
  level (495,717) while keeping all R124/R125 framing.
- authored tri_total estimate updated for the 9x5 sphere (128 -> 90 per mass).

## Honest verdict
FAIL as an overall target match (still borderline ~6.5/10 expected), and this
round deliberately does not claim visual progress - it buys back 128k prims
(20.6%) at visual parity, answering the cost Black flagged twice. The saving
also re-opens headroom: the prim budget conversation is no longer dominated
by canopy geometry. Note the frame is the same first-glance image as round201;
any future PASS judgement will not come from this round's change.
