# SCORECARD PHASE3 R146 (round222) — NON-SPHERE CROWN PROTOTYPE, BOUNDED (internal, Black to judge)

Base: R145 a37fc58 (round221). ONE variable changed: crown construction in ONE delimited
sector. Everything else (layout, buildings, terrain, colour law incl. R145 v2) frozen.

## DELIMITED AREA
Sector: _build_tree positions with x in [-18, 2] and z >= 3 — the south-west FOREGROUND
tree group (same camera sector in round221_AB_vs221.png). In that sector, the 14 MAIN
lobes of each tree are built as painted cards instead of sphere lobes: 2 crossed card
pairs per lobe (existing add_foliage_card cross, +0.85 rad second pair), at the SAME
lobe centres/scales (R143 stretch/lean/skirt offsets unchanged), coloured by the canopy
law tail (card_col146 = R69 lift + R131 desat + R133 lift/cap on the R141-toned lobe
colour). Mini lobes, skirt lobes, trunks, stacked-variant (vi==1) trees: unchanged
spheres. Tree origins byte-identical; NO other tree in the frame changed.

## PAINTED TEXTURE (procedural, bounded to prototype)
foliage_card.png repainted (was unused by any caller): alpha leaf-cluster silhouette
(overlapping blobs, soft edge), painted leaf dabs + soft light/shade clumps in target
style, mean RGB tuned to (160,163,99) so card crowns sit on the measured canopy median.
Card material: existing card_st slot, alpha_scissor 0.45, cull disabled, UNSHADED
(lambert shading gave binary dark slabs on flat quads — dropped within the same
technique; painted shading lives in the texture, as in the 2.5D target).

## DRAWS/PRIMS + TRADES (measured)
- draws 288 (= cap, = R145), prims 540,021 -> 534,181 (cards free prims: sector sphere
  lobes + their shadow pass removed, cards are 8 tris/lobe and cast nothing).
- Draw accounting, honestly: shaded cards cost +1 draw (289). Trades tried: (a) merging
  the 3 cliff instances into 1 (KEPT — identical world geometry/material, hill A/B
  pixel-identical; measured draw-neutral in this camera), merged cliffs cast OFF (also
  measured neutral, no visible hill change); (b) merging the 3 roof groups with tints
  baked to vertex colours — pixel-exact roofs but +2 counted draws (cascade bounds),
  REVERTED byte-identical. Final offset: the unshaded card material itself renders in
  one fewer pass — measured 289 (shaded) -> 288 (unshaded, final). Net draws unchanged.

## GUARDS (classify_r130, round221 -> round222)
- canopy (52,90,17) HSV(0.253,0.811,0.353) -> (52,90,17) HSV(0.253,0.811,0.353) IDENTICAL;
  share 18.90% -> 18.76%. Held vs target (65,85,23) exactly as R145.
- roofs (155,79,44) -> (154,79,44): -1 R (card overlap at sector edge).
- stone (166,172,146) -> (165,172,146): -1/0/0.
- dirt (147,119,57) -> (147,119,57) IDENTICAL.

## SHADOW / SORTING VERDICT (explicit, as ordered)
- Cards cast_shadow OFF (draw cap). FINDING: prototype crowns' MAIN masses cast no
  shadow. Residual ground shadow remains from the sector trees' sphere mini/skirt lobes
  + contact discs, so trees are not shadowless, but the main-mass shadow a sphere crown
  casts is absent. In the sector A/B this is not conspicuous at full frame; it IS a
  real loss vs sphere crowns and a blocker to resolve before any wholesale switch
  (alpha-scissor cast-ON was draw-blocked at 289 in shaded mode and is untested at
  final settings — not hidden, stated).
- Unshaded cards also RECEIVE no shadow (a roof shadow crossing a card crown would not
  darken it). Not triggered visibly in this sector; known limitation, stated.
- Alpha sorting: NONE observed. Cutout (scissor) + opaque queue: no halo, no sort
  popping, card/sphere-lobe intersections depth-test cleanly at full and close views.
  Edges stay clean at foreground distance (sector is near-camera by design).

## Self-judgement, FULL FRAME FIRST: FAIL ~6.9/10 overall; prototype itself WORKS locally
In the sector crops the card crowns are the first crowns in six rounds that do NOT read
as faceted spheres at all: soft painted leaf masses, colour-matched to their sphere
neighbours (median identical), outlines irregular. The foreground trees read closer to
the target's painted trees than any sphere construction achieved. Costs are flatness
(no form modelling beyond the painted texture) and the shadow findings above.
At FULL frame the change is deliberately local (SW sector only, ~1% of pixels): the
frame as a whole still reads sphere-crowns elsewhere, so no PASS is claimed. But the
bounded question Black asked is answered: YES, the non-sphere construction moves the
crown read where applied, within caps and guards. Wholesale replacement, shadow
resolution (cast-ON within draw budget), and card LOD/mip behaviour at distance are
the open items for Black's/Helmer's next decision — not iterated here, per bounds.
Kept: sector cards + texture + cliff merge. Dropped/reverted: lambert card shading,
roof-group merge. Nothing else touched.
