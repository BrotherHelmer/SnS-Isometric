# Phase 3 R139 — FORM round (round215): crowns + building masses at real screen size

Draws 288 (≤288 hard, unchanged) | Prims 541,405 (≤~550k; R138: 490,797) | Internal only, nothing to Helmer.
Start: HEAD cf7588e (R138) verified. LAYOUT FROZEN: git-diff audit shows no building/tree/path position line changed — only segment counts, geometry internals and shading normals on identical coordinates (position-bearing cyl lines changed only in their sides digit). No colour retune: no texture, material, palette or vertex-colour law touched; R108/R109 rig untouched.

## Diagnosis (native 1280×720 full + 100% crops vs target at same scale)
- Crowns: 9×5-segment spheres with flat face normals (R114) render as 20–40px crystalline plates — large flat faces, hard straight silhouette edges, one flat tone per plate. Target crowns at the same size show no visible facet plates: fine irregular silhouette + small-scale cluster shading.
- Buildings: wall boxes displace only at corners (noised_box on an unsubdivided box), so wall faces are one flat CAD plane with perfectly straight edges; roof2 prisms are 4 single quads per roof — one flat plane per slope; village cones/drums are 8–12-sided, reading as stacked faceted rings. Target masses have hand-uneven surfaces and small-scale painted shading throughout.

## Techniques kept
CROWNS
1. Finer crown geometry: near sphere 9×5 → 10×6, far 8×4 → 9×5 segments (facet plates shrink at screen size). TRIED 12×7/10×6 first: rendered prims 618,693 — over ceiling, because canopy casts in the shadow pass; reduced to the shipped counts (see prims). This is the honest construction limit found this round.
2. Blended normals: add_canopy/add_canopy_low now shade with normal = 0.50·face + 0.50·radial (was flat face). Flat plates get a light gradient across the crown while the R114 cluster COLOUR steps are still computed on the unchanged flat face normal — tone law untouched, only shading interpolation changed. First try at 0.45/0.55 brightened crowns more (canopy value .349→.376); shipped 50/50 (value .369).
3. Silhouette breakup: displacement gains a fine term (+0.09·sin(23.7x−13.1y)·sin(19.3z+11.7x)) on both crown spheres, and near-tree perimeter lobes 7 → 8. Crown outlines at full frame are visibly less geometric.
BUILDINGS
4. Roof prisms subdivided 2×2 per quad (roof2): centre vertex displaced ±0.045 along the quad normal (seeded; shared edges undisplaced, so no cracks), subface normals blended 0.55 quad / 0.45 own — one flat slope becomes four softly angled plates. Sag range 0.06–0.24 → 0.08–0.28, eave unevenness ×(0.9–2.6) (was 0.8–2.1).
5. Walls: noised_box subdivided 2×2×2 so displacement reaches face interiors, plus seeded mid-height jitter (±0.030, sin(t01·π) envelope, existing amt law unchanged) — walls belly/lean slightly instead of CAD planes.
6. Cones/drums finer: roundhouse cone 12→16, barn 14→16, octstore cap 8→12, hut thatch 10→14, roundhouse drums 12→16, octstore drum 8→12, watchtower cone 8→12 sides.

## Techniques dropped / limited (honest)
- 12×7 near crowns: dropped — prims over ceiling in the shadow pass (above).
- Wall jitter (5): real in close view, near-invisible at full judge scale — kept (it costs nothing and harms nothing) but NOT claimed as a full-frame gain.
- No texture repaint attempted: any painted-cluster texture rewrite would shift the closed canopy/stone/dirt/roof medians; form was attacked geometrically instead.

## Guard measurement (classify_r130.py, medians)
Canopy (57,89,16) → (56,94,19), dRGB vs target .025 → .029; stone (179,182,152) → (180,183,152) (small pool, as before); dirt (149,116,56) → (146,115,56); roofs (150,77,46) → (148,75,45). Closed classes preserved by construction and confirmed at the median. Canopy share falls 24.2% → 15.6% in the classifier — a threshold artefact, not a colour change: blended normals lift crown-top values across the classifier's v<0.5 canopy/grass boundary (canopy value .349 → .369); the canopy median itself is unchanged within (1,5,3)/255.

## Screen-size verdict (full frame first)
Crowns: first-glance improvement is real — crowns read rounder/softer with smaller facets and broken outlines, less "crystal model", especially in the forest frame and between-building trees. Buildings: cones/drums and roof slopes read marginally less machined; walls essentially unchanged at this scale. Against the target both still read as low-poly models, not painted masses — subdivision + normal blending soften the model read, they do not convert it. This is the stated construction limit of the merged low-poly approach at ≤550k prims with a shadow-casting canopy.
FAIL (self-assessment), borderline ~6.5/10 — form improved in the crown mass (the most visible surface), composition and colours hold, but the painted-mass gap remains. Nothing shown to Helmer; awaiting Black PASS/FAIL.

## Perf
Draws 288 (identical surf keys, no new materials). Prims 490,797 → 541,405 (+50,608: finer crowns counted again in the canopy shadow pass + subdivided roofs/walls; authored tris 219,800 → 232,926). Under the ~550k ceiling with ~8.6k to spare — stated plainly: crown density headroom is now essentially exhausted.
