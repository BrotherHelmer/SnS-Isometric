# Phase 3 — R149 (round225) scorecard — FULL ROLLOUT to all 22 eligible trees

Self-score: **FAIL ~6.8/10** (verdict for Black; nothing to Helmer)

## 1. What changed (diff audit)

`target_style_scene.gd` only, 2 lines: the R146–R148 sector condition replaced by
`use_cards149 = true` in `_build_tree`. Every tree reaching the crown loop is by
construction card-eligible (cull-passing, non-stacked — stacked vi==1 returns
early), so all **22** now build crossed-card main lobes on the same single
combined mesh, same `card_col146` law-tail colours, same `foliage_card.png`.
Far treeline (`_build_tree_far`, 29 trees) and stacked trees: untouched spheres.
Origins/layout/buildings/terrain/colour law byte-frozen.

## 2. Process lessons — verified explicitly

1. **Multi-line card commit** retained (R147 block; comments only after complete
   statements). This round's edit changed 2 statement lines, no one-liners.
2. **Texture import fresh**: `foliage_card` .ctex 08:46 > source PNG 08:31;
   editor import re-run before rendering, nothing pending.
3. **Runtime disable-test**: commit disabled (temp) = **288 draws / 419,941
   prims**; cast OFF = 289 / 422,405; final cast ON = **290 / 424,869**.
   Card prims: +2,464 main (22 trees × 112) and +2,464 shadow — exact. Disable
   vs final pixel diff = 71,625 px on the crowns. Instrumented run logged
   **card_trees = 22** with positions. Cards are provably in the render.

## 3. STOP CONDITION — not triggered (measured live)

| variant | draws | prims |
|---|---|---|
| cards disabled | 288 | 419,941 |
| rollout, cast OFF | 289 | 422,405 |
| **rollout, cast ON (final)** | **290** | **424,869** |

Full conversion lands at **290 draws = exactly the ceiling** (the R148 projection
confirmed live: +1 mesh draw, +1 mesh shadow draw, independent of tree count).
No financing attempted, none needed. Prims **424,869** (R148 extrapolation
~429k — measured, close).

## 4. Shadow — frame-wide

Cast ON/OFF at final settings = **7,956 changed px**, distributed over every
tree band (SE 1,274 as in R148; village centre 836+529; hill/NE 834+633; back
row 372+268…), not only the SE pair. Direction sun-correct everywhere.
Darkening: lit ground ×0.885, already-dark overlap ×0.806 — **no absurd
double-darkening anywhere**; card shadows remain leaf-weight (softer than
sphere ×0.75), as in R148. No missing-shadow converted trees found in the
survey (every converted band shows its delta; individual crown-by-crown audit
was by diff cells, not per-tree).

## 5. Distance / mip

Farthest converted trees are the background/hill `_build_tree` crowns
(z −13…−15.5, hill elevations). In stills (`round225_distance_series.png`)
they hold as soft pale masses at 100%, mass retained at 25% downscale, no
cutout collapse — hazed law-tail colours keep them in the distance family.
Stills only; **temporal shimmer remains a stated residual risk, not solved.**

## 6. MIX JUDGEMENT (required, honest)

At full frame the conversion mostly reads **coherent**: painted crowns are now
the tree language of the near/mid field, and the untouched far treeline sits
pale and small at the frame edges, where it reads as hazed distance forest —
arguably a working depth cue rather than a seam. **The inconsistency is local:**
stacked vi==1 sphere trees stand at the SAME depth as card crowns (behind the
castle, left margin — see back crop in the PNG scorecard: a large faceted crown
beside soft card masses at comparable scale), and there the two languages clash
on direct neighbour comparison. It does not cry out across the frame, but it is
not fully intentional-looking either. Next-step fork for Black (not fixed here):
(a) give the stacked variant a card analogue, (b) accept treeline+stacked as
the distance language and stop, (c) extend to the far treeline builder.

## 7. Guards (classifier)

| class | round225 | R148 | target |
|---|---|---|---|
| canopy | (52,91,18) HSV(.256,.802,.357) **16.58%** | (52,90,17) 18.34% | (65,85,23) (.22,.729,.333) |
| roofs | (155,79,44) 8.45% | (155,79,44) | (152,107,76) |
| stone | (165,172,145) 1.37% | (165,172,146) | (139,139,128) |
| dirt | (148,120,57) 25.34% | (147,119,57) | (163,139,89) |

Canopy median within Δ1 per channel (G 90→91, B 17→18 as cards take over the
class); share **16.58%** (−1.76 pp vs R148, −2.14 pp cumulative vs R147 —
cards classify less as canopy than the spheres they replace; reported openly).
Roofs identical; stone/dirt within Δ1.

## 8. Verdict

Rollout executed exactly as mandated: 22 trees, one mesh, 290 draws at (not
over) the ceiling, prims 424,869, guards within ±1, shadows plausible
frame-wide, distance holds in stills. The scene's crowns are now uniformly
painted in the near/mid field; remaining seams are the stacked sphere trees at
card depth. As a visual-target round it still does not meet Black's bar.
**FAIL ~6.8/10. Nothing to Helmer.**
