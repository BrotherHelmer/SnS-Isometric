# Phase 3 — R148 (round224) scorecard — bounded cluster expansion

Self-score: **FAIL ~6.7/10** (verdict for Black; nothing to Helmer)

## 1. What changed (diff audit)

`target_style_scene.gd` only, 3 lines: the card condition gains a second box —
south foreground band x[8,21.5], z[8,15] — OR-ed with the R146/R147 SW box.
Same crossed-card construction, same `card_col146` law-tail colours, same
`foliage_card.png`, same multi-line card commit (cast ON). Everything else
byte-identical to R147.

**Converted trees: 4** (runtime-logged): SW (-10,8) [R147 tree], south (9,13.5),
SE (20,9.5), SE (20.3,13.2). In-band but unchanged by design: (21.5,14) stacked
vi==1 (sphere early-return); all other trees remain R145/R147 spheres.

## 2. Process lessons applied + render verification (explicit)

1. **No comment-killable one-liners**: the card commit stays the R147 multi-line
   block (each statement complete; comments only after complete statements).
2. **Runtime verification that cards render**: (a) instrumented run logged the 4
   card-tree positions above and the eligible-tree counts; (b) disabling the card
   commit (`if false`, temp) renders **288 draws / 518,341 prims** vs final
   **290 / 519,237** — the +896 prims = 4 trees × 112 card tris × (main+shadow
   passes); (c) pixel diff round224 vs round223 = 10,638 changed px clustered
   exactly on the 4 crowns. Cards are provably in the render.
3. **Texture import verified fresh before judging**: `foliage_card` .ctex
   (08:46) is newer than source PNG (08:31); editor import re-run confirmed
   nothing pending. All judgements below use the correctly imported texture.
4. **Draw counts measured live, cast OFF vs ON** (table below), never assumed.

## 3. Draw price — per mesh, not per tree (all measured, full camera)

| variant | draws | prims |
|---|---|---|
| cards disabled (commit off) | 288 | 518,341 |
| cluster 4 trees, cast OFF | 289 | 518,789 |
| **cluster 4 trees, cast ON (final)** | **290** | **519,237** |
| R147 reference: 1 tree cast ON | 289 | 534,293 |

- The cards live in **one combined SurfaceTool mesh** => **+1 draw total** for the
  mesh (cast OFF step), **+1 draw total** for its shadow (cast ON step) — going
  1 tree → 4 trees added **zero** main-pass draws. At 1-tree scale (R147) the
  shadow step measured +0; at cluster scale +1: the counter is cascade/culling
  sensitive (R146 precedent), but it is one mesh-level draw, never per-tree.
- Prims: each converted tree nets ≈ **−5,019 prims** (sphere main lobes leave both
  passes; cards add 224 counted tris). 4 trees: 534,293 → 519,237.

### Wholesale extrapolation vs the 290 ceiling

Runtime count: **22** `_build_tree` trees reach the crown loop (card-eligible:
cull-passing, non-stacked); of these, z>=3 "near/foreground" = **4 — the cluster
is already the complete south set**. If all 22 converted (same single mesh):

- **Draws: projected 290 — exactly AT the 290 ceiling, not breaking it**
  (+1 mesh draw, +1 mesh shadow draw, independent of tree count). Zero headroom;
  the cascade-sensitive counter must be re-measured at any real conversion.
- Prims: ≈ 519k − 18 × 5.0k ≈ **~429k** (estimate from the measured per-tree net),
  far under the 550k cap.
- Not included: `_build_tree_far` treeline trees (separate cheap builder, 29 trees)
  and stacked vi==1 trees (sphere early-return) — converting those is extra,
  unmeasured work. The 290 STOP condition is **not** triggered; no visible-change
  financing was attempted or needed.

## 4. Shadow on open ground (Blocker evidence)

Dedicated A/B on the uncovered SE pair (`round224_shadow_AB.png`, cast OFF vs ON,
final settings, same camera): **cast ON/OFF = 2,230 changed px scene-wide**
(SE zone 1,274; SW tree 627 onto tower roof/path as in R147; (9,13.5) 149).
The SE crowns' shadows land on **open grass and path at the crown bases**,
extending sun-correct (lower-right). Shape: soft, dappled, leaf-cluster patches —
plausible for cutout cards. Darkness: card shadow darkens lit ground to ×0.91
luminance (sphere-crown shadows nearby ≈ ×0.75): **lighter/softer than sphere
shadows** (partial alpha coverage), same direction and softness family. Where it
overlaps residual mini/skirt shadow: ×0.81 — **no absurd double-darkening**, no
crushed blacks. Verdict: shadow works and is visible on open ground, at
leaf-dapple weight rather than solid-crown weight.

## 5. Distance / mip

Farthest cluster tree = (-10,8) (~35 m). `round224_distance_series.png`
(100/50/25% on real pixels): dab structure holds at 100%, mass retained at 25%,
no cutout collapse — same as R147. SE pair reads painted at foreground scale.
Stills only; **temporal shimmer remains a stated residual risk, not solved.**

## 6. Guards (classifier)

| class | round224 | R147 | target |
|---|---|---|---|
| canopy | (52,90,17) HSV(.253,.811,.353) 18.34% | (52,90,17) 18.72% | (65,85,23) (.22,.729,.333) |
| roofs | (155,79,44) 8.44% | (155,79,44) | (152,107,76) |
| stone | (165,172,146) 1.36% | (165,172,146) | (139,139,128) |
| dirt | (147,119,57) 25.15% | (147,119,57) | (163,139,89) |

All medians identical to R147; canopy share −0.38 pp (cards classify slightly
less as canopy than the sphere crowns they replace — reported, not hidden).

## 7. Verdict

The cluster proves the construction at 4 trees: crowns read painted and soft
beside faceted sphere neighbours, the uncovered SE trees cast a real, plausible,
leaf-weight shadow on open ground, guards are identical, prims fell, and the
price is **per combined mesh (+2 draws total: 290) — not per tree**. Wholesale
(22 eligible trees) projects to exactly 290 draws / ~429k prims, at the ceiling
with zero headroom and a cascade-sensitive counter that must be re-measured.
Still one construction, one texture, thin species variety, shadow lighter than
sphere weight, shimmer unproven. **FAIL ~6.7/10 — evidence for Black's wholesale
decision, no PASS claim. Nothing to Helmer.**
