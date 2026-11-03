# Phase3 R2 scorecard — for Black PASS/FAIL, NOT Helmer
Screenshots: phase3/round9.png round10.png round11.png round12.png(final); sheet SCORECARD_PHASE3_R2.png
Perf R12: 78 draw calls, ~36k prims (R10 log 36,874; R12 same scene +ground), ~9.8-10.3k authored tris vignette; per building <1500 (castle ~900, house ~450, hut ~350). Merged-by-colour + KayKit carriers; textures 1024 CC0 repo only.

1. Landscape: IMPROVED NOT PASS — terrain now fills frame (64m ground), back plateau, cliff row, distant hills+snow, fog+mist, edge tree ring. Still mostly flat settlement plane, seam line visible, cliffs are blobs, no true height/cliff geology or mist depth like target.
2. Grass: IMPROVED NOT PASS — plaster/meadow muddy-olive fixed toward lush bright (tint 93dc62, finer 18x grain, square patches gone); still washed/pale in fog and grain repetitive, not painterly lush.
3. Buildings: IMPROVED NOT PASS — house near-black walls FIXED (cause found: plaster_diff mean RGB 67, now flat light plaster); castle stone texture+courses, shingles, thatch rings. Castle keep/towers still smooth/simple vs target.
4. Density/scale: IMPROVED NOT PASS — 5 houses, 2 huts, castle, 17+ trees, props/flags/fences, wider camera; still reads sparse diorama vs target dense living village, paths largely hidden.
5. Trees/carrier: MIXED — Carrier SOLVED technically: Rig_Medium libraries attached (General/MovementBasic/Tools), log shows CARRIER playing MovementBasic_/Walking_A, advance(0.65) mid-stride, log carried; still screenshot-static proof only, needs video. Trees: forest texture on canopies added but still smooth lollipop silhouettes.
Shadows: softer (opacity .38, AO discs) but still flat/hard vs warm soft target.

VERDICT: NOT MATCHES (first-glance test fails clearly). Recommend Black FAIL again; landscape needs real heightfield terrain (not boxes/blobs) as next headline, then canopy faceting.
