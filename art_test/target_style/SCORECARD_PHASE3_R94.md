# SCORECARD — Phase 3 R94 (round169): modelled roof relief (internal only)

Reference: restored target, R93 round168. Stone/plaster/wood gains, background,
muted terracotta unchanged.

## Roof relief — 6.5/10
New `_cone_relief()` following each cone's own geometry:
- **Castle cones** (4 tower cones + keep cone with tiles; wing + annex cones
  rings-only): 4 stepped shingle rings per cone whose radii interpolate the
  cone's bottom/top radius at each height (real curvature, real shadow gaps,
  existing `roof.darkened(0.22)` key), plus 15 irregular front-arc tiles per
  main cone (seeded size 0.17-0.27u, depth jitter, tilt -0.38 rad to lie on
  the cone slope, value cycling through existing shingle keys
  darkened(0.22)/lightened(0.15)/darkened(0.46)/base).
- **House gables**: 12 irregular proud tiles on the camera-facing (+x) slope
  per house (seeded per house, same keys), on top of the R83 chunky shingle
  rows and R78 slope wear fans.
Texture/relief scale check: R93 texture tiles are 210-430px (~0.25-0.5u at
roof UV) and relief tiles are 0.17-0.42u — same family, no double-read or
clash found in close; texture not adjusted.
**Do cones stop reading as slabs at full frame? Partly.** They no longer read
as smooth flat slabs — stepped rings break every cone silhouette and the
close shows individual tiles with shadow gaps — but at full frame the rings
dominate the read and the individual front-arc tiles are subtle, so cones
read "stepped/modelled" rather than "hand-tiled" like the target.

**Overall honest self-score ~6.5/10. Not a Black PASS claim.**

## Perf
R94 round169: **275 draws / 315,617 prims / ~143,587 authored tris** — draws
identical to R93 (every ring/tile reuses existing roof colour keys; relief is
merged geometry only, +2,868 prims).

Renders: evidence `phase3/round169.png` + `phase3/round169_close.png` (1280x800).
