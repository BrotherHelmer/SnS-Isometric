# Phase3 R4 scorecard — for Black PASS/FAIL, NOT Helmer
Screenshots: phase3/round17.png round18.png round19.png(final); sheet SCORECARD_PHASE3_R4.png
Perf R19: 100 draw calls (4 animated KayKit carriers dominate; merged world ~65), 58,514 prims, ~18,420 authored tris incl 6,272 terrain; buildings <1500 ea.

1. Landscape sculpt/rock: IMPROVED NOT PASS — noise-jagged slopes, strata banding (darkened alternate height bands on steep), rock texture grain via meadow multiply, 12 merged boulders, mountain raised to 9m moved into back-right. Still reads brown smooth ramp, snow cap does NOT appear in frame (peak out of frame / below threshold at visible slope — diagnosed, not faked), no cliff faces/ledges.
2. Painterly grass: IMPROVED NOT PASS — multi-scale vertex noise + texture grain, 10 earth patches, 36 flower speckles (white/yellow/pink discs), path-worn branches. Grain still coarse/dark, speckles sparse and disc-like.
3. Castle: IMPROVED NOT PASS — enlarged base 5.4m, stone texture+courses+chips, battlements wall+keep, red banners on towers, prominent red cones, flags. Still boxy keep, towers smooth cylinders.
4. Trees: IMPROVED NOT PASS — 3 canopy colour variants by position, flat-faceted clusters, varied; still uniform shape family, dark.
5. Light: IMPROVED NOT PASS — shadow opacity 0.30->0.46, warm/cool contrast; village area still fairly flat, AO discs subtle.
6. Density/life: IMPROVED NOT PASS (biggest gain) — visible path network incl 4 branch paths, 4 animated KayKit carriers across frame (Walking_A log-verified), carts/barrels/fences/flags/earth/flower detail. Still far from target's dense activity; carriers all same Farmer skin/hat.

VERDICT: NOT MATCHES — first glance still distinguishes instantly (painterly richness, geology, texture scale). Progress is structural: heightfield+strata, path network, multi-figure life now exist to iterate on.
