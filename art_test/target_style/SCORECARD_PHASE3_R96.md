# SCORECARD — Phase 3 R96 (round171): grass/terrain ground (internal only)

## My choice: grass/terrain ground
Largest single surface in the frame and the remaining first-glance flat one;
buildings are now textured stone+roof+timber/plaster. Reference: restored
target, R95 round170.

## Meadow enrichment — 6/10
- `detail_noise.png` (the terrain material's meadow texture) repainted,
  seed 9601: 90 large soft tone drifts (220-520px ≈ 2-5u at the shader's
  0.07 world scale), 900 medium tuft-scale mottling clumps (28-95px), 2,600
  worn speckle clumps, then 1,500 short grass strokes drawn after the blur —
  all wrap-drawn so tiling has no cut edges. Varied green family around the
  existing mean (lush mid-green, lighter worn, deeper shade) so the established
  palette/vertex colours and the R80-R82 depth haze are untouched in balance.
- Terrain shader: meadow now mixes a second sample of the same texture at
  0.29 world scale (32%) — two-scale sampling breaks the single tile period
  across the frame; snow/haze/rock terms were not modified, background depth
  does not regress (checked full frame: crest still patchy pale, treeline calm).
- No floating specks: every detail lives in the terrain texture/material
  (R69 lesson kept; no billboards or tuft geometry reintroduced).
- Integration check: paths with stone edging still read clearly, worked-earth
  patches (R76) do not double-read against the new mottling (they sit above
  the texture and are browner/larger), boulders/logs unchanged. No clash
  found; nothing outside the texture + one shader line was adjusted.
**Does grass stop reading flat uniform at full frame? Partly.** Field and
frame-edge grass now shows tone drift and mottling at judged size; the
settlement centre, where the vertex colour is darkest and occupancy is dense,
still reads fairly uniform deep green — the lush, varied meadow of the target
is approached at the margins first, not yet in the middle of frame.

**Overall honest self-score ~6.5/10. Not a Black PASS claim.**

## Perf
R96 round171: **275 draws / 317,153 prims / ~145,683 authored tris** — unchanged
(texture repaint + one shader mix line).

Renders: evidence `phase3/round171.png` + `phase3/round171_close.png` (1280x800).
