# SCORECARD — Phase 3 R69 (round141) vs Black verdict deviations (internal only)

Baseline: R68 round140 (Black ~4/10), untouched as A/B panel. Target bottom half.
Paid-2.5D loop stopped; this round is only in `art_test/target_style/`. Full frame judged.

## Per-deviation honest verdict (Black priority order)
1. **Trees — 6.5/10 (biggest win).** ~50% culled deterministically in `_build_tree`, scale
   x0.64, canopy shading de-crushed (the near-black was texture x vertex double-green:
   boost x2.0-2.1, underside darkening 0.42->0.16). Result: fewer, smaller, mid-green
   pines + round canopies, settlement no longer buried. Some clusters still lime-bright.
2. **Crisp / wall smear — 6/10.** Causes found and removed: vignette overlay (deleted),
   FXAA (-> MSAA 4X), sun shadow_blur 7.0->1.4, fog 0.0012->0.0005. Rock smear fixed in
   terrain shader with two-plane rock UV projection by world normal. Frame is crisp;
   right wall now reads as textured rock, though it still dominates (see 5).
   (One mid-round bug: a `#` comment inside the shader string broke compilation and
   whitened the terrain; caught on first render, fixed, re-rendered.)
3. **Path network — 6/10.** Paths narrowed (1.5->1.05 main, discs r0.82->0.60), lightened,
   and given merged stone edging (grey stones every other step along the walking paths).
   The light dirt web between buildings and up the switchback now reads at full frame.
4. **Floating green specks — 8/10.** `_spawn_tufts` (1000 instanced grass cards) removed
   entirely. Speck noise gone; flower patches remain as grounded blobs (target-like).
5. **Mountain/quarry — 4/10 (weakest).** Rock is crisper and browner, mine headframe got
   a wheel, stone road exists, but the east mass still cuts the frame as a wall and an
   odd pale snow slab sits bottom-right. Needs terrain-mass reshaping (one corner slope),
   which is a bigger `_h` change than this round's scope — flagged, not attempted.
6. **Spacing — 6.5/10.** Tree cull + smaller bushes open real grass between buildings;
   settlement breathes. Foreground left is now arguably too empty.
7. **Shadows / pennants / settlers — 6/10.** Sun shadows now cast readably (blur 1.4,
   opacity 0.55) plus existing contact discs; 7 territory pennant poles added on path
   junctions (blue/red), 5 extra settlers placed on paths; carriers/minis already present
   now actually visible after de-cluttering.

**Overall honest self-score ~5/10 (R68 was Black 4/10). Not a Black PASS claim.**
Remaining: mountain mass composition (5), overall saturation/palette vs target's muted
painted look, building texture richness.

## Perf
R69 round141: **217 draws / 283,909 prims / ~118,980 authored tris** (R68: 288 draws /
482,213 prims). Under the <=290 draw budget.

Render: evidence `phase3/round141.png` (1280x800, full frame).
