# Scorecard Phase 3 R21 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per criterion
- Grass shadow depth: IMPROVED. Low-frequency shaded-meadow patches
  (gsf 0.74–1.14 by sin patch field) now multiply grass/dirt vertex
  colour, giving sunlit vs shaded meadow contrast across the field on
  top of R20's terrain tint. Grass reads deeper and less flat-lit,
  especially lower frame. Still not as shadow-rich as target (real
  cast shadows remain limited to buildings/trees; patch shading is
  faked, not light-driven).
- Drawn cracks / lichen / glow: PARTIAL, with proof.
  * Drawn cracks: SOLVED as a path. Terrain detail texture repainted
    with crack polylines, and steep-band vertices now use
    height-projected UV (x,h)*0.09 instead of XZ, so the painted
    cracks/strata actually land on the face — round60_hill.png shows
    thin drawn crack lines on the rock (right face), not just facet
    contrast. No custom shader needed; cheap world-height UV in the
    existing single terrain material.
  * Trade-off: the same detail texture serves grass; round59 cracks
    (alpha 150) visibly squiggled on grass, repainted fainter
    (alpha 68, width 3, seed 72) — round60 grass shows them only
    very faintly, rock close still shows them. Balance acceptable,
    not perfect.
  * Lichen: strengthened in vertex colour (threshold 0.55, up to
    0.75 lerp to 6f8a48); green-grey tint patches are present on
    shaded rock in the hill close, still subtle.
  * Glow pockets: NOT fully killed. Snow darkened to bccbd8,
    glow_hdr_threshold 1.25 set, glow strength already 0.3 — white
    pockets on snow shelves behind talus persist in the hill close
    (lit snow + bloom). Reduced vs R19, not eliminated.
- Retained: houses/castle/roofs/canopies/composition/density, R17
  grade/FXAA. Terrain remains ONE material/draw as before.
  No animals invented.

Rounds: 59 (shade patches, height-UV cracks strong, glow threshold),
60 (cracks fainter for grass, snow darker).
Perf round60: 171 draw calls, 107,645 prims, ~27,250 authored tris.
Screenshots: phase3/round60.png, phase3/round60_hill.png;
scorecard SCORECARD_PHASE3_R21.png.
