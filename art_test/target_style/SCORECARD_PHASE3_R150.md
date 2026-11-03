# Phase 3 — R150 (round226) scorecard — stacked variant gets the card analogue

Self-score: **FAIL ~6.8/10** (verdict for Black; nothing to Helmer)

## 1. What changed (diff audit)

`target_style_scene.gd` only: inside the `vi == 1` stacked branch of
`_build_tree`, the 4 stacked `add_canopy` sphere lobes became 2 crossed card
pairs each (`add_foliage_card`, 8 calls/tree) at the same lobe positions, same
per-lobe stacked toning passed through the same `card_col146` law tail, on the
**existing combined card mesh** — no new mesh, material or pass. Far treeline
(29 `_build_tree_far`) untouched; origins/layout/terrain/colour law frozen.

**Stacked trees converted: 13** (runtime-logged): (-15.5,4.5), (11,1.5),
(16,4.8), (16.5,-3.5), (21.5,14), (-19,-6.5), (-13,-12), (-13,-15),
(-8.5,-14.5), (-4,-14.5) + 3 hill-elevation trees. Frame now: 22 + 13 = 35
card trees; only far treeline + autumn/sphere remnants remain non-card.

## 2. Process lessons — verified explicitly

1. **Multi-line commits**: card commit is still the R147 multi-line block; this
   round changed one statement inside the stacked branch (no one-liners).
2. **Texture import fresh**: .ctex 08:46 > source 08:31; editor import re-run
   clean before judging.
3. **Runtime disable-test**: commit disabled = **288 draws / 392,901 prims**;
   cast OFF = 289 / 395,781; final cast ON = **290 / 398,661**. Card prims
   +2,880 per pass = 22×112 + 13×32 exactly. Disable-vs-final pixel diff =
   121,847 px across all 35 crowns; instrumented run logged the 13 stacked
   positions. Stacked cards are provably in the render.

## 3. STOP CONDITION — not triggered

Stacked conversion landed at **290 draws** — same combined mesh, **zero new
draws** (288 disabled / 289 cast OFF / 290 cast ON, identical structure to
R149). Prims **398,661** (−26,208 vs R149: stacked spheres leave both passes,
32 card tris/tree enter). No financing attempted or needed.

## 4. Shadow / distance

Cast ON/OFF = **17,282 changed px** frame-wide (up from 7,956: stacked main
masses previously cast via the sphere canopy in the OFF state, now they cast
via cards only in ON). Lit ground ×0.876, already-dark ×0.795 — **no
double-dark crush**; stacked shadows sun-correct on the same open-ground
pattern as R148/R149. Distance: farthest converted (back-row + hill stacked)
hold as soft masses in stills (`round226_distance_series.png`); temporal
shimmer remains the stated residual risk.

## 5. Guards (classifier) — median and share reported openly

| class | round226 | R149 | target |
|---|---|---|---|
| canopy | **(53,94,18) HSV(.257,.809,.369) 14.78%** | (52,91,18) 16.58% | (65,85,23) (.22,.729,.333) |
| roofs | (155,79,44) 8.50% | (155,79,44) | (152,107,76) |
| stone | (166,172,146) 1.36% | (165,172,145) | (139,139,128) |
| dirt | (148,120,57) 25.46% | (148,120,57) | (163,139,89) |

Canopy median nudged (+1R, +3G) and **share fell again: 16.58% → 14.78%**
(cumulative vs R147: **−3.94 pp**). No colour-law change — same `card_col146`
tail; this is the classifier seeing card crowns (incl. the taller stacked
columns) as brighter/greener and partly as grass. Reported, not hidden: the
share drift tracks the card fraction and is the number to watch if Black
weighs the closed-class balance. Roofs identical; stone/dirt within Δ1.

## 6. Seam + TEXTURE-REPETITION JUDGEMENT (required)

**Seam: closed.** Behind the castle and at the left margin the former faceted
stacked crowns now read as soft (slightly columnar, willow-like) painted
masses in the same language as their card neighbours — see
`round226_seam_AB.png` (R149 top vs R150 bottom). The two-language clash at
equal depth is gone; only the distant treeline remains faceted, at distance.

**Texture repetition: variation carries it — not the next weakness.** No two
crowns read as photocopies: 28–32 quads per crown at seeded rotations, varied
scale and law-tail tint composite into distinct masses (`round226_repetition.png`).
What repeats is a *vocabulary* — same blob-alpha language, same pale tone
family, similar dab size — so the forest reads as one species, which is
plausible. The most repetitive single read is the stacked variant itself (same
blob stacked ×4 vertically). Judged honestly, the next visible weakness is
**not** the single texture: it is the unshaded flatness (crowns take no light —
they read as decals beside shaded roofs) and the single pale tone family.
Judged only, per mandate; nothing fixed.

## 7. Verdict

Fork (a) executed exactly: 13 stacked trees converted on the same mesh, seam
closed, draws still 290, prims down, shadows plausible, texture import and
live-render verified. Canopy share keeps drifting under cards (−3.94 pp
cumulative) and crowns remain unshaded decals — the round does not meet
Black's bar. **FAIL ~6.8/10. Nothing to Helmer.**
