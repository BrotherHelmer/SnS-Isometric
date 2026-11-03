# SCORECARD PHASE3 R145 (round221) — MEASURED CROWN COLOUR-LAW REOPENING (internal, Black to judge)

Base: R144 8e0f56e (round220). Black's choice executed: crowns-only colour/cell law +
shading model, measured against R131/R133. NOT touched: R131 desaturation factor, R133
value lift/cap, palette/albedo (canopy material tint), R142/R143 silhouette, R144 clump
displacement/normals, R141 buildings, layout, terrain. Diff audit: ONLY colour-law lines
inside add_canopy/add_canopy_low changed. draws 288, prims 540,021 — identical to R144.

## KEPT (v2 colour law, both canopy functions)
- Per-face plate contrast collapsed: R114 face-index vary 0.84+0.12*steps -> 0.96+0.03*steps
  (neighbours no longer get unrelated tones face-by-face).
- Hard fn.y steps -> smooth masses: lightened(smoothstep(0.25,0.75,fn.y)*0.20) (was 0.22 step
  at 0.45); darkened((1-smoothstep(-0.05,0.35,fn.y))*0.14) (was 0.16 step at 0.1).
- clus face step halved (0.10/0.18 -> 0.05/0.09).
- NEW spatially-coherent clump cells, per-VERTEX: 4-step quantized product-of-sines field
  on the vertex radial direction (seeded per lobe), factor 0.74..1.24 — neighbouring faces
  share cells, cell size ~2-3 per lobe diameter (painted-dab scale at 20-40px), edges
  softened by vertex interpolation. v1 (0.82..1.24, higher frequency) was too diluted;
  v2 (this) is the kept strength.

## ATTEMPTED AND DROPPED (crown shading model)
- Crown-only ShaderMaterial, soft-posterized light: wrapped NdotL version brightened
  crowns out of class (canopy share 18.64->13.65%, rock/hill share 2.62->10.87% spurious).
  Unwrapped 3-band mix 0.50 and 4-band mix 0.75 versions: guards recovered (52,90,17) but
  at 100% crops the bands are invisible — normals are interpolated, so posterizing only
  draws soft contour lines at this scale; facet edges (geometric + face-cell colour at
  mesh-vertex scale) are untouched by it. DROPPED, StandardMaterial restored byte-identical.

## GUARD TABLE (classify_r130 medians)
| class | R144 (220) | R145 (221) | target | note |
|---|---|---|---|---|
| canopy | (52,91,17) HSV(0.255,0.813,0.357) | (52,90,17) HSV(0.253,0.811,0.353) | (65,85,23) HSV(0.22,0.729,0.333) | median -0/-1/0; value +.020 over target (was +.024); sat +.082 (R133 residual +.085 — not worsened) |
| roofs | (155,79,44) | (155,79,44) | (152,107,76) | IDENTICAL |
| stone | (166,172,145) | (166,172,146) | (139,139,128) | +1 B only |
| dirt | (147,119,57) | (147,119,57) | (163,139,89) | IDENTICAL |
Canopy share 18.64% -> 18.90%. Held as ordered; every other class guarded, not assumed.

## Self-judgement, FULL FRAME FIRST (native 1280x720 vs round220 + target): FAIL ~6.8/10
The kept law softens plate contrast slightly at crop level (broader, quieter tonal
patches on foreground crowns; less face-by-face speckle in tone). At full frame the
interior still reads as faceted displaced spheres. PLAIN LIMIT STATEMENT with proof:
colour law is now also at its limit for crown interiors. Three levers inside the measured
reopening all failed to move the full-frame read: (1) spatial clump cells at two strengths
— diluted by texture multiply, the R131 desaturation, and per-vertex interpolation across
~5px mesh vertices; (2) collapsing per-face steps merely removes one of three facet
sources; (3) posterized crown lighting is invisible on interpolated normals (and its
wrapped form breaks the measured median). What remains carrying the facet read is the
construction itself: displaced-sphere geometry whose internal edges, mesh-scale colour
cells and smooth gradient cannot imitate painted leaf masses at 20-40px, no matter the
law on top. Per Black's framing, this is the trigger condition for the separate
non-sphere (cards/sprites) decision — sphere crowns have now hit their limit on all
three axes: painting (R140/R141), geometry/normals (R142-R144), colour law (R145).
Kept: v2 colour law (small, real, free, guards exact). Dropped: crown shader, all versions.
