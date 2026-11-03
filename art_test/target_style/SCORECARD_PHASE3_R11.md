# Phase3 R11 scorecard — for Black PASS/FAIL, NOT Helmer
Screenshots: round34.png, round35.png (final, ledges moved onto slope); sheet SCORECARD_PHASE3_R11.png
Perf R34/R35: 176 draw calls (at ~180 cap — 9 KayKit figures dominate; merged world cheap), ~90k prims, ~21,990 authored tris; buildings <1500.

1. Geology: IMPROVED NOT PASS — snowline 2.0->1.5 (snow larger, white, top frame like target corner), 11 stepped ledges + dark strata bands with rock_painted texture on slope, boulders. Ledges still read as stepped slabs, no true cliff faces; hill mass still smooth between ledges.
2. Painterly richness: IMPROVED — texture tiling 4->6 finer, roofs shingle grid reads everywhere (SOLVED stays solved, verified round34/35 full frame), thatch/stone read, dirt paths painted. Grass still fairly uniform hue at distance.
3. Trees: IMPROVED NOT PASS — palette lightened (55a03c/8cc65e + variants), forest texture tint 0.45->0.30; canopies brighter in frame bottom, core trees still darkish blobs vs target painterly foliage.
4. Light: IMPROVED NOT PASS — pools 0.4->0.85/0.9, shadow opacity 0.55, vignette; warm pools still subtle, core depth modest.
5. Density/life: IMPROVED — market stall (posts, red/white canopy, crates), 3 more flags (blue/red), 3 STATIC work figures with varied clips log-verified: Tools_/Chopping (Farmer_A), General_/Idle_A (Knight, white helmet visible by castle), Tools_/Hammering (Farmer_B at stall), plus 6 walking carriers in 4 skins. Animals: NONE exist in ledger/game (Phase 1 confirmed) — not invented, stated here.
Roofs check: SOLVED maintained in full frame, not only close-up.

VERDICT: NOT MATCHES — closest round yet (frame is alive, roofs/snow/geology all read), but first glance still distinguishes: target is denser, softer, painterly; ours is crisp low-poly with slab geology.
