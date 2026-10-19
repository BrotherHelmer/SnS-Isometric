# SCORECARD PHASE3 R144 (round220) — CROWN INTERIOR SURFACE STRUCTURE (internal, Black to judge)

Base: R143 5df6377 (round219). FROZEN: R138 layout, R141 building painting, terrain/hill/
buildings/paths, R143 asymmetry+skirt, ALL colour law (no palette/albedo/desaturation line
touched). Final diff audit: only (1) one gentle clump-displacement term in both crown-mesh
builders, (2) a clump-normal perturbation in add_canopy/add_canopy_low, (3) comment lines.
No new draw keys/materials. draws 288, prims 540,021 — IDENTICAL to R143.

## KEPT (zero prims, zero colour change)
- Clump relief displacement: +0.10*sin(x*8.3)*sin(y*7.3)*sin(z*9.1) mid-frequency term in
  canopy_sphere_var + canopy_sphere_low displacement (bumps at ~1/8 lobe circumference,
  several px at 20-40px lobe scale). Low-frequency silhouette terms unchanged (R142/R143
  outline read preserved).
- Clump normals: per-face normal perturbed by a low-frequency orientation field
  (cn144 x 0.22) on top of the proven R139 0.50 flat/0.50 radial blend, both canopy funcs.
  Colour cc/cc141 computation byte-identical.

## ATTEMPTED AND DROPPED (A/B at 100% crops, classifier-witnessed)
1. Stronger scallop boost (mid terms 0.19->0.24, 0.13->0.17, clump 0.14) + interior
   sub-lobes (1 per large lobe, 8x4 sub mesh) funded by far 8x4->7x3 + terrain 180->172
   (prims 527,573): interiors read MORE crumpled/spiky, not softer clumps. Sub-lobes were
   swallowed by parent-lobe displacement. canopy share 18.67->17.70%. DROPPED ENTIRELY,
   trades reverted (final terrain/far state = R143 exactly; hill A/B confirms).
2. Smooth normals fork: blend 0.12 flat (prims unchanged): crowns became pale smooth
   balloon spheres; canopy class share COLLAPSED 18.67->12.30%, median (52,91,17)->
   (50,94,21) — lighting washout, classifier loses the crowns. DROPPED.
3. Intermediate blend 0.32 flat: same failure, share 13.33%. DROPPED. Any softening past
   the R139 0.50 blend brightens crowns out of their measured class within a few points.

## GUARDS (classify_r130, round219 -> round220 final)
- canopy (52,91,17) -> (52,91,17) IDENTICAL; share 18.67% -> 18.64%.
- roofs (155,79,44) -> (155,79,44) IDENTICAL.
- stone (166,172,146) -> (166,172,145): 0/0/-1.
- dirt (147,119,57) -> (147,119,57) IDENTICAL.
Cleanest possible guard outcome: interior relief moved no median.

## Self-judgement, FULL FRAME FIRST (native 1280x720 vs round219 + target): FAIL ~6.8/10
Kept relief gives a slight extra break-up inside crop-level crowns; at full frame the
interior read is essentially unchanged from R143. PLAIN CONCLUSION (proof above):
geometry/normals within the caps cannot move the crown interior either. The fork is
exhausted — more geometry relief crumples (1), smoother normals balloon/wash out (2,3),
and the facet read is carried by the per-face colour-cell law + flat-ish directional
lighting, i.e. the colour/shading model itself, which this round (and Black's no-reopen
order) forbids touching. Crown interiors would need either a colour-law reopening
(per-vertex colour smoothing / new cell law — a measured colour round, Black's call) or
a different crown construction entirely (card/sprite clusters), not more sphere work.
Silhouette (R142/R143) remains solved in kind; interior is now proven at its limit by
three independent failed levers, not asserted.
Kept: gentle clump displacement + clump normals (real, if small, crop-level relief;
zero cost, zero guard movement). Dropped: sub-lobes, both trades, both smooth-normal
blends — all reverted, nothing half-kept.
