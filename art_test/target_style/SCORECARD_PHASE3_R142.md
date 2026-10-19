# SCORECARD PHASE3 R142 (round218) — CROWN GEOMETRY via PRIM TRADING (internal, Black to judge)

Base: R141 665103b (round217, prims 541,405). Building painting gain (R141) fully retained.
Layout FROZEN — diff audit: only crown-mesh internals, far-crown segments, terrain grid
steps changed in target_style_scene.gd. No position/Transform3D/colour-law line touched;
R114/R141 crown colour law operates unchanged on the new geometry. Sun rig untouched.

## PRIM AUDIT (instrumented call counts; authored tris; casters x2 in frame incl shadow pass)
| category | calls | tris/unit | authored | frame share |
|---|---|---|---|---|
| terrain grid 230x230 (no shadow) | 1 | 105,800 | 105,800 | ~105.8k of 541k (19.5%) |
| near canopy lobes 10x6 | 561 | 100 | 56,100 | ~112k (cast, x2) |
| far canopy lobes 9x5 | 164 | 72 | 11,808 | ~24k (cast, x2) |
| noised_box walls (R139 subdiv) | 8 | 108 | 864 | negligible - NOT a trade |
| roof2 prisms (R139 subdiv) | 6 | 32 | 192 | negligible - NOT a trade |
| rest (buildings/props/terrain-excluded authored + GLB statics/carriers/tufts) | - | - | rest of 232,926 authored + uncounted | balance to 541,405 measured |

## TRADES (freed) -> SPEND
- Terrain grid 230 -> 180 steps: -37,350 frame prims (105,800 -> 68,450; rendered once).
- Far crowns 9x5 -> 8x4: -3,936 authored / ~-7,872 frame (164 lobes, cast x2).
- Total freed ~45.2k frame prims.
- SPEND: rich crown mesh 13x9 (208 tris vs 100) for lobes at scale >=0.51 (the 20-40px
  lobes): 176 lobes, +19,008 authored / ~+38,016 frame. PLUS no-prim-cost silhouette work:
  3 seeded displacement variants per crown class (previously every lobe shared ONE
  silhouette, rotated) + added low-frequency asymmetric bulge terms (0.15/0.10) so crown
  outlines are irregular and differ lobe-to-lobe. Smaller lobes keep 10x6 (3 variants too).
- NET: prims 541,405 -> 533,461 (UNDER the R141 total and the ~550k ceiling; margin 16.5k).
  draws 288 (cap). authored_tris 232,926 -> 246,686.

## TRADED-AREA REGRESSION CHECK (native A/B vs round217)
- Hill view (round217_hill vs round218_hill): terrain silhouette, rock bands, cliff read
  unchanged at native size; coarser grid NOT visible. Far treeline (8x4) read unchanged.
- Close view: terrain/stone/paths unchanged; only crowns differ (fuller).
- Classifier side effects of the terrain resample, reported openly below (dirt/grass/rock
  shares move because slope/colour functions are sampled on the coarser grid).

## GUARDS (classify_r130, round217 -> round218; NO colour retune — shifts are geometry/coverage)
- canopy (53,93,18) -> (53,91,17): -0/-2/-1; share 15.74% -> 18.60% (fuller silhouettes
  cover more; toward target share 23.78%).
- roofs (152,76,43) -> (155,79,44): +3/+3/+1; share -0.49pp (crowns overlap more roof pixels).
- stone (176,179,150) -> (166,173,146): -10/-6/-4, share -0.28pp. OPENLY the largest shift:
  geometry-only cause (bigger crown silhouettes occlude lit stone; remaining stone pixels
  skew shaded). No stone colour/shader line changed since R141.
- dirt (144,117,56) -> (148,120,57): +4/+3/+1; share 29.73% -> 25.09% (terrain-grid
  resample of the slope->dirt classification; median moves slightly toward target).
- grass share 37.23% -> 39.65%, rock/hill (168,171,96) -> (187,192,107): terrain resample.

## Self-judgement, FULL FRAME FIRST (native 1280x720 vs round217): FAIL ~6.7/10
First crown change in three rounds that visibly moves the crop read: crowns are fuller,
silhouettes vary lobe-to-lobe (no longer one rotated star), rich lobes show smaller/more
even facets, clusters overlap into denser leafy masses, canopy coverage +2.9pp. In the
crown A/B the 218 trees read as leaf clusters where 217 read as spiky facet stars.
BUT at full frame they are still pale faceted clusters — better geometry, same material
read; not yet hand-painted masses. Geometry helped more than either painting round;
it did not finish the job. Remaining prim margin (16.5k) could buy one more step
(rich threshold lower / 14x10 rich) — expected incremental, not transformational.
Kept: all trades + rich/variant crowns. Dropped: nothing; noised_box/roof2 trades
evaluated and rejected as negligible (864/192 authored).
