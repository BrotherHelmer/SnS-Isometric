# Phase3 R6 scorecard — for Black PASS/FAIL, NOT Helmer
Screenshots: round23.png (painted textures FAILED to load, no .import — washed neon, documented), round24.png (imported, first real painted look), round25.png (final); sheet SCORECARD_PHASE3_R6.png
Perf R25: 110 draws, 62,710 prims, ~21,068 authored tris; buildings <1500 ea.

Painted textures (all Pillow-procedural, seed 7, 1024px, in art_test/target_style/textures_painted/ + .import):
- grass_painted: green base + 2600 alpha mottle ellipses + 900 brush strokes, blur
- stone_painted: hand-drawn rounded-rect stone courses, varied block size/shade, mortar outlines (lightened +28% in R25)
- plaster_painted: cream multi-octave mottling + strokes
- roof_painted: 18 rows offset rounded shingles, red shade variation
- thatch_painted: 2400 vertical strokes + band lines
- dirt_painted: mottling + 260 pebble ellipses
- rock_painted: 240 random polygon facets, grey-brown
Applied per surface family via TEX map (white->0.78 grey tint to compensate light sum); towers 8-sided + stone_painted; roof slabs/cones roof_painted (shingle rings kept); pine family replaced by elongated faceted clusters.

Painted richness: IMPROVED NOT PASS — castle stone courses and thatch strokes now read at camera, grass finer; but roof shingles still don't read on slabs, plaster subtle to invisible, texture scale still chunky vs target fine painterly.
Light/post: IMPROVED NOT PASS — dedicated round: filmic/glow tried R23 (blew out, glow off, back to linear, warm fog f2e3c2, contrast 1.12/sat 1.22, AO discs, shadow 0.46). Core still flat-ish, hill slope washes yellow.
Geology/snow: SAME NOT PASS — pale snow wedge top, ledges/outcrops, strata; hill still brown ramp.
Castle/buildings: IMPROVED NOT PASS — light stone with courses is closest yet; keep still boxy, towers faceted but plain caps.
Trees: IMPROVED — pine toy-cones replaced by elongated faceted clusters; still dark core blobs.
Density/life: SAME — paths, 4 walking carriers, props.

VERDICT: NOT MATCHES. Changed lever DID visibly change surface richness (R24 vs R22), confirming Black's diagnosis; needs a real painted-texture art pass at higher fidelity + UV-mapped models, not just procedural Pillow v1.
