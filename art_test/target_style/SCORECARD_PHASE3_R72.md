# SCORECARD — Phase 3 R72 (round147) vs Black's two levers (internal only)

Reference: R71 round146. Target bottom half, full frame + slope close.
R69-R71 gains kept (terraces grounded, mid-green trees, MSAA crisp, path web,
no specks, muted palette sat 0.93, pennants/settlers/shadows).

## Lever 1 — Snow on the camera-facing slope — 6/10
Not threshold recalibration (proven weak in R71). Two new mechanisms:
(a) GEOMETRY patches: 16 primary + 16 secondary flattened snow ellipsoids seated
on `_h` across the SE (camera-facing) face of the NE mass (x17-25, z-2.5..-13.5,
following the terrace seating approach), patchy sizes 1.1-2.3u; (b) aspect+height
snow tone in the terrain material keyed to SE-facing normals (dot(normal.xz,
(0.62,0.72))) x height band x a second patch-noise, supporting the geometry.
Result: white patches now read on the face the camera sees, in full frame and
slope close, distributed patchily like the target rather than a flat-top cap.
Remainder: patches are smooth ellipsoids (no gully-following irregular outline),
and the highest crest snow is still mostly above frame.

## Lever 2 — Mine reads against rock — 6/10
Headframe rebuilt at ~1.7x mass (position kept 14.5,-11.5): 3.3-tall warm timber
posts/braces (7c4c22/5d3a1e), 0.88r dark-iron wheel with timber hub, timber
platform, wood cart, lantern, red pennant, ore crates. Neighbouring crest/talus/rib
rocks treated together: tinted warm (6e665c -> 96795c / 8f7355) so the mine area
no longer reads grey-on-grey. At full frame the timber frame + wheel now read in
the upper-right; slope close confirms the silhouette. Remainder: a separate set of
grey pillar rocks on the crest (other rock sites) still reads grey and competes
for attention; mine could still be larger relative to the mass.

**Overall honest self-score ~6/10 (R71 5.5, R70 5.5, R69 5). Not a Black PASS claim.**
Trajectory is still slow; the remaining gap to target is scene-wide illustration
richness (unique detail, texture, atmosphere), not a single lever.

## Perf
R72 round147: **227 draws / 295,441 prims / ~126,756 authored tris** (R71: 222 draws).
Budget <=290 met. Slope close: 119 draws.

Renders: evidence `phase3/round147.png` + `phase3/round147_slope.png` (1280x800).
