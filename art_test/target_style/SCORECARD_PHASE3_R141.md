# SCORECARD PHASE3 R141 (round217) — FORM-FOLLOWING VALUE PAINTING (internal, Black to judge)

Base: R140 d43f693 (round216). Layout AND geometry FROZEN. Diff audit: only
target_style_scene.gd changed (35+/11-); every add_vertex/set_uv/set_normal/Transform3D
line byte-identical except set_color colour arguments; no texture repainted this round
(R140 foliage v3 etc. kept). Only shader strings, a material branch, vertex colours,
per-lobe colour factors, and the canopy material tint changed. Sun rig R108/R109 untouched.

## What was done (paint LARGE value masses that FOLLOW forms)
1. CROWNS, two scales:
   a. Within each lobe (add_canopy/add_canopy_low): per-vertex painted gradient —
      sun/top light mass vs lower/shade mass from the vertex radial direction
      (value 0.38..1.45, warm lit / cool-deep shade), on top of the R114 face law.
   b. CLUSTER scale (the real crown form — trees are 14-lobe clusters): each lobe toned
      by its offset within the crown (height + sun-side): 0.40..1.38 in _build_tree,
      mini-lobes 0.48..1.32, stacked variant by stack height 0.48..1.34, far trees
      (_build_tree_far) 0.45..1.34. Pushed in 3 A/B iterations (v1->v4) until building
      masses read; crowns stopped improving (see limit).
   c. Canopy material lift 1.28/1.19/1.05 -> 1.36/1.26/1.10 as median compensation.
2. ROOFS: R123 face-aware shader strengthened in all 3 copies (mat_for roofp, roof-tone
   relief, roof_groups): clear lit-slope (warm x1.12/1.04/0.90) vs shade-slope
   (x0.50/0.53/0.62 + 45% cool desaturation), split smoothstep(0.38,0.90,lf).
3. STONE: R90 shader gains strong value mass mix(0.64,1.20,lf) + painted base shadow
   pocket (world-y smoothstep, -26% at base) following towers.
4. PLASTER + THATCH: new face-aware ShaderMaterial (R90 precedent, replaces flat
   StandardMaterial): warm lit face x1.16/1.07/0.90 vs cool shade face x0.62/0.68/0.84,
   base shadow pocket -26%. UV scales replicated (plaster 0.55, thatch 1.0).
   Thatch lit faces now read warm sunlit gold (strong, noted).

## Perf / frozen proof
draws 288 (cap), prims 541,405 — IDENTICAL to round216/215. Shader/colour only.
(One intermediate render briefly showed 286/348,901: a mid-line comment ate the canopy
commit line; caught by the prims audit, fixed, final numbers identical.)

## Guards (classify_r130, round216 -> round217) — SHIFTS REPORTED OPENLY
- canopy (56,94,19) -> (53,93,18): shift -3/-1/-1, share 15.61%->15.74%.
  The deeper shade masses cost 3R/1G/1B of median despite the +6% material lift
  (lift is capped downstream by R133). Judged acceptable: direction is deeper shade,
  deviation vs target dRGB .029->~.030 (unchanged class rank).
- roofs (148,75,45) -> (152,76,43): shift +4/+1/-2; value now .596 = target value
  exactly; dRGB vs target IMPROVED .088->.082.
- stone (180,183,152) -> (176,179,150): shift -4/-4/-2; dRGB vs target IMPROVED
  .142->.132 (median was far above target value; this moves toward it).
- dirt (146,115,56) -> (144,117,56): shift -2/+2/0 (dirt texture untouched;
  classifier spillover from plaster shading at path edges).
No median was silently moved; all shifts above, all small, roofs/stone improved vs target.

## Self-judgement, FULL FRAME FIRST (native 1280x720): FAIL ~6.6/10
What moved: roofs are now genuinely modelled at first glance — castle cones and
roundhouse roofs show clear lit-slope/shade-slope painting; thatch reads sunlit;
stone towers and plaster walls carry visible warm/cool faces and base pockets.
Buildings are the win of this round.
What did not move: crowns. Even with per-vertex gradients AND cluster-scale lobe
toning pushed to 0.40..1.38 across three iterations, at full frame the crowns still
read as pale faceted lobe clusters — the R131 desat + R133 cap compress the painted
range, real directional lighting re-flattens it, and the facet plates remain the
dominant read. Bottom-of-cluster shade deepened measurably (canopy lum p10 62->57)
but first glance does not change.
PLAIN LIMIT STATEMENT (as Black invited): for crowns, painting-on-model is at its
limit. Value painting cannot turn 10x6 faceted lobe clusters into painted masses at
20-40px; the form language itself (facet structure) is what reads. Buildings show
painting still has some headroom where large flat faces exist (roofs), but the crown
problem is geometric/silhouette, not surface. Two consecutive painting rounds
(R140 textures, R141 form-following values/shaders) both failed to move full-frame
crowns; a third painting round on crowns is not recommended.
Kept: all of the above (buildings gain real, guards acceptable). Dropped: nothing
reverted, but crown contrast was NOT pushed past v4 (garish/median risk, no read gain).
