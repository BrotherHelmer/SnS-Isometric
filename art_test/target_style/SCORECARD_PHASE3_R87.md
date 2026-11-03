# SCORECARD — Phase 3 R87 (round162): rubble masonry texture (internal only)

## My choice: break horizontal courses toward rubble (same root cause)
Continuing R86's root-cause focus rather than switching surface: the ashlar
course structure itself was the remaining regularity. Texture-only round;
relief R83-R85 untouched.

## Rubble texture — 7/10
`stone_painted.png` repainted as toroidal-Voronoi rubble (numpy, seed 8711,
72 cells, same muted warm-grey family / tint-through):
- Irregular polygon stones (tall, wide, near-square mixed), joints in multiple
  directions, **no horizontal bands anywhere in the tile**; mortar = darker
  cell-border bands of irregular width, edge shading per stone, per-stone
  value (±20) + warm/cool spread, soft blotches, sparse cracks.
- Toroidal distance metric, so the tile wraps without seam banding — checked
  on tower cylinders in the facade close (no cut/band at the wrap).
- Large scale kept: ~72 stones/tile ≈ 240px cells ≈ 0.4u-equivalent at
  uv 0.55.
**Relief scale check (asked): no clash.** Texture stones (~0.4u-equiv) sit in
the same size family as R85 relief stones (0.24-0.52u); in close the relief
still reads as proud blocks over the rubble instead of fighting it. No relief
adjustment made.
Honest remainder: Voronoi rubble is more mosaic-regular in cell size than
hand-laid rubble (cells are similar areas even if shapes differ), and at full
frame the castle still reads as grey stonework first, rubble second. But the
dominant horizontal course lines are gone at both sizes.

**Overall honest self-score ~6.5/10. Not a Black PASS claim.**

## Perf
R87 round162: **273 draws / 312,737 prims / ~141,279 authored tris** — identical
to R86 (texture-only).

Renders: evidence `phase3/round162.png` + `phase3/round162_close.png` (1280x800).
