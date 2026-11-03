# Phase3 R7 scorecard — for Black PASS/FAIL, NOT Helmer
Screenshots: round26.png (v2 hero pass), round27.png (final, roof v3); sheet SCORECARD_PHASE3_R7.png
Perf R27: 117 draws, 65,030 prims, ~22,224 authored tris; buildings <1500 ea (castle ~1,100 with buttresses, house ~520).

Texture method v2/v3 (Pillow, seed 11/12, 2048px, textures_painted/, reimported):
- grass v2: 5,200 fine mottles + 3,800 strokes + baked dirt patches
- stone v2: finer courses (72-105px), darker mortar (92,84,70, 7px), highlight lines, baked AO gradient bottom 260px
- roof v2 (22 rows, too fine — failed to read) -> v3: 10 bold rows, 14px outlines, highlight strokes (reads only as eave fringe on slabs — BoxMesh top-face UV compresses rows; honest fail, needs custom roof UV mesh next)
- thatch v2: 7,000 vertical strokes + bands (reads well)
- plaster v2 thick timber bands (dominated, houses looked log-brown) -> v3 thin bands 44px (plaster still subtle)
Hero models: castle buttresses at 4 corners (stone tex), framed inset windows (gold+dark), door; house thick beam geometry front+sides, inset door frame; dedicated per-face UV via Box/Cylinder primitives (1:1 per face, no tiling stretch on walls).

Painted fidelity: IMPROVED NOT PASS — stone+thatch read, grass fine green, plaster/beams now visible as timber houses.
Roofs/plaster: NOT PASS — shingle rows still not reading on roof slopes (UV issue diagnosed above), plaster cream subtle vs timber.
Terrain/geology/snow: NOT PASS — snow area larger/paler top-right but washes lime-yellow, hill no geology weight.
Trees: SAME NOT PASS — faceted varied, core dark.
Light depth: IMPROVED NOT PASS — AO discs 0.28->0.45, warm Omni pool at village centre (0.55, 13m); still no vignette, core fairly flat (Environment has no cheap vignette; noted).
Density: IMPROVED — 7 houses + 2 huts + castle frame-filling now; still activity only 4 identical carriers.

VERDICT: NOT MATCHES. Key concrete blocker found: roof needs a custom UV-mapped prism mesh (not BoxMesh) for shingles to read; that + a real vignette/grade are the next technical steps.
