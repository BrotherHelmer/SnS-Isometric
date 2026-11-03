# SCORECARD — Phase 3 R70 (round142-143) vs Black priorities (internal only)

Reference: R69 round141. Target bottom half. Full frame only. R69 gains kept
(tree cull/brightness, MSAA crisp, path web, no tufts, pennants/settlers/shadows).

## 1) Mountain mass reshape — 5.5/10
`_h` reshaped: north mass shifted/concentrated NE (centre x15->19.5), the east lobe
that formed the frame-cutting wall demoted (height 9->3.2, onset x17->20, recentred
z-4->-10 = foothill), NE corner mass strengthened (13.5 high, smoother exponents) so
the mountain is one brown rock slope receding into the upper-right corner. Mine
headframe re-sited onto it (14.5,-11.5) with the switchback stone road extended to it;
terrain dirt-feature patches moved with it. Pale snow slab bottom-right FIXED: cause
was the snow lerp (h>4.2, flat slope) firing on low SE plateau tops; snow now requires
h>4.6 AND z<-7 (back/north). Honest remainder: snow itself is still weak in frame —
classification only lands on flat high tops (steep faces are overridden by the rock
mix in the terrain shader) and the highest corner is above frame; terrace plank
fields on the reshaped slope float at their edges.

## 2) Muted palette — 6/10
Environment saturation 1.10->0.93 (round142 tried 0.88 = too dark, calibrated back),
contrast 1.08->1.04, terrain vertex colours desaturated 10% toward luminance in
`_build_terrain`. Overall values now closer to target's muted painted range.
Trees judged after the change: R69 fix holds — canopies remain mid-green (their
x2.0 vertex boost survives the global saturation cut), not near-black.

**Overall honest self-score ~5.5/10 (R69 ~5/10). Not a Black PASS claim.**
Next lever if continued: snow on slope faces (shader-level snow by height+normal,
careful: not a post effect), terrace grounding on the new slope, mine colour/material.

## Perf
R70 round143: **218 draws / 284,173 prims / ~118,992 authored tris** (R69: 217 draws).
Budget <=290 met.

Renders: evidence `phase3/round142.png` (first reshape), `phase3/round143.png` (final).
