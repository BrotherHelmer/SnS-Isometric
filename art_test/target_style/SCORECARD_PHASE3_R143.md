# SCORECARD PHASE3 R143 (round219) — CROWN SILHOUETTE round 2 (internal, Black to judge)

Base: R142 10283e0 (round218, prims 533,461, margin ~16.5k to ~550k). Layout FROZEN,
R141 building gain untouched, R142 trades held. Diff audit: only crown-internal lines —
lobe offsets within clusters, lobe mesh choice, rich threshold. Tree origins, trunks,
buildings, terrain, colour/tone law all byte-unchanged; R114/R141 law runs as-is on the
new outlines (per-lobe toning follows the TRANSFORMED offsets).

## (b) NEW SILHOUETTE TECHNIQUE (beyond R142 segments/variants)
1. Per-tree whole-cluster asymmetry (seeded by tree position, no two trees alike):
   stretch asx/asz = 1 +/- 0.24 on lobe offsets, vertical squash sqy = 1 +/- 0.16 about
   crown centre, lean lnx/lnz = +/- 0.20 growing with lobe height. Stacked (vi==1)
   crowns lean progressively by stack level. Applied to main 14 lobes AND mini lobes.
2. Hanging skirt fringe: 5 low offset lobes per tree at radius ~1.48 cluster units,
   below the main crown bottom (y ~1.58 vs 1.9+), breaking the circular outline at the
   base/sides; on the 8x4 low mesh, coloured from the existing a/b family, shaded by the
   existing low-crown law. A/B checked: reads as lower foliage, NOT spikes/noise. KEPT.

## (a) MARGIN SPEND + internal trade (prim accounting, measured frame prims)
- Internal trade: the 8 perimeter mini-lobes per tree moved 10x6 standard (100 tris) ->
  8x4 low mesh (48 tris): they sit at 10-18px, facets unread there (A/B verified).
- Spend: skirt fringe (5 low lobes/tree, +96 frame prims each incl. shadow) and rich-mesh
  threshold lowered 0.51 -> 0.42 (more 20-40px lobes on the 13x9 rich mesh, +216 each).
  (0.40 was tried first: 542,661 — inside Black's ~550k authorization; settled at 0.42 to
  also stay under the older 541,405 line.)
- NET: 533,461 -> 540,021 frame prims (draw calls in shadow pass included), UNDER both
  541,405 and the ~550k ceiling. draws 288 (cap). authored_tris 247,350.

## TRADED-AREA / GUARD CHECK (classify_r130, round218 -> round219)
Hill + close A/B: R142 traded areas (terrain 180, far crowns 8x4) show NO further change
(buildings/terrain lines untouched this round).
- canopy (53,91,17) -> (52,91,17): -1/0/0; share 18.60% -> 18.67%.
- roofs (155,79,44) -> (155,79,44): IDENTICAL.
- stone (166,173,146) -> (166,172,146): 0/-1/0.
- dirt (148,120,57) -> (147,119,57): -1/-1/0, share identical 25.09%.
Cleanest guard round of the crown series — silhouette work moved almost no medians.

## Self-judgement, FULL FRAME FIRST (native 1280x720 vs round218 + target): FAIL ~6.8/10
Outlines are now genuinely per-tree: crowns lean, stretch, squash differently; skirt
fringes widen and irregularise crown bases; the foreground trees in particular no longer
read as round lollipop clusters, and combined with R142's fuller/varied lobes the tree
masses are denser and more organic. In the trees A/B the 219 outlines are broader and
clearly non-circular where 218 was still cluster-round.
Honest limit: at full frame the crowns still read as clustered faceted spheres with
better outlines — "clustered spheres with fringe" is partly still true. The silhouette
is organic; the surface inside the silhouette still facet-reads (pale R131/R133 palette
+ facet plates). Each crown round moves the read; none has crossed into painted canopy.
Kept: asymmetry + skirt + threshold spend + mini-lobe trade (all verified in A/B).
Dropped: nothing. Not attempted: colour retune (forbidden), further prim spend beyond
0.42 threshold (would break 541,405 for negligible facet gain).
