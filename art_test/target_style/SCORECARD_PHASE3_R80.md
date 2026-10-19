# SCORECARD — Phase 3 R80 (round155): layered depth (internal only)

## My choice: clearer LAYERED DEPTH (not denser facade detail)
Reason from evidence: finer facade detail keeps mip-averaging at 40-90px faces
(R18/R41/R65/R66, and R79 itself showed density enriches texture read but does
not change kind), while depth layers act at full-frame scale where the remaining
gap vs target is largest. All baked into materials/geometry — no global post,
no vignette/FXAA return, MSAA foreground crispness untouched.

## What was built — 6.5/10
- **Terrain-material aerial perspective** (in the terrain shader, not post):
  haze factor = distance-from-settlement (smoothstep 10->30u, x0.38) + height
  (3.5->9u, x0.22), capped 0.55 toward pale cool (0.74,0.79,0.76). Terrain under
  the settlement (dist<10) is mathematically untouched, so the foreground plane
  stays rich/crisp; mid-slope mutes slightly, crest/high face pales most.
- **Far trees**: R77's hint strengthened to graded haze (z<-10 or dist>15,
  lerp 0.42->0.58 by distance toward pale b9c9ae/ccd9b8) in `_build_tree`.
- **Crest haze fans**: R77's 4 fans extended to 10 over the far crest/upper face,
  same alpha colour keys (no new draws).
- **Layer separators**: treeline/hedge band of 5 canopy trees along the mountain
  foot (12.5,-0.5)->(18.5,-12.5), a shadowed valley band of flattened dark discs
  under them (existing contact-shadow key), and a pale sky-side crest edge of
  flattened e4e9ec blobs along (18,-15.5)->(27,-13) (existing snow key).
Foreground check: settlement colours, terracotta roofs, shadows and MSAA edges
unchanged; haze lives only on far slope/crest/far trees as required.

Honest remainder: the far-hill wash from the terrain gradient is a bit uniform
on the top strip, and the new treeline canopies read brighter than the muted
mid-tone intended (canopy material's R69 brightness lift). Depth planes are now
clearly distinct, but they read as three bands more than the target's gradual
painted recession.

**Overall honest self-score ~6.5/10. Not a Black PASS claim.**

## Perf
R80 round155: **273 draws / 310,243 prims / ~138,883 authored tris** — draws
identical to R79 (separators reuse existing colour keys + the single canopy mesh).

Renders: evidence `phase3/round155.png` (1280x800, full frame).
