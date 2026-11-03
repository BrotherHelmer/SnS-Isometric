# SCORECARD — Phase 3 R98 (round173): trees/vegetation (internal only)

## My choice: trees/vegetation
Meadow's remainder (R97) is a matter of degree; trees were still a matter of
kind — faceted modelled blobs vs target's soft painted foliage. R69 count/
scale/colour discipline kept throughout (no recount, no resizing, no
near-black, contact shadow discs untouched).

## Canopy diagnosis + fixes — 6.5/10
Diagnosis: (1) canopy spheres were 9x5 segments with **flat per-face
normals**, so every sphere shaded as facets; (2) silhouette displacement was
mild (max ~1.68x, regular sines); (3) the foliage texture was dot-speckle
circles, which read as dots at frame scale (R66 lesson).
- Smooth vertex normals in `add_canopy` (radial normals instead of face
  normals) — canopy masses now shade soft; the face normal is still used for
  per-cluster colour variation, where sun warm/cool tint was added
  (sun-facing clusters warmed, shaded cooled, R90-style at cluster scale).
- Canopy sphere raised to 13x7 segments with stronger multi-scale
  displacement (extra 13.7/11.3 octave) for irregular silhouettes.
- `foliage_painted.png` repainted at cluster scale (seed 9801): layered
  leaf-cluster ellipses 22-170px in four value layers (deep shade to warm
  light), no dots below 22px.
**Do canopies stop reading as faceted blobs at full frame? The faceting does,
mostly** — trees now read as soft, irregular green masses with warm lit and
cool shaded clusters, and the dot texture is gone. They still read as modelled
masses rather than the target's layered hand-painted foliage (silhouette is
displaced-sphere, not leaf-built), so the kind gap narrows but does not close.
Note: an intermediate render in this round briefly lost canopies entirely
(a trailing comment swallowed `add_vertex` on its line); that was caught by
the draw/prim count check, fixed, and the final renders above are the fixed
ones — draws returning to exactly 275 was part of the verification.

**Overall honest self-score ~6.5/10. Not a Black PASS claim.**

## Perf
R98 round173: **275 draws / 347,312 prims / ~147,062 authored tris** — draws
identical (canopy is a single vertex-colour mesh); prims +28.6k from the
denser canopy spheres, reported honestly.

Renders: evidence `phase3/round173.png` + `phase3/round173_close.png` (1280x800).
