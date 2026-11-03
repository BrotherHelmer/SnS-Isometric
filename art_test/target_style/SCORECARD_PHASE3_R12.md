# Scorecard Phase 3 R12 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per criterion
- Cliff faces: NOT. Stepped ledge boxes removed; new noise-displaced flat-shaded
  cliff ArrayMeshes (own MeshInstances, painted rock texture, scree boulders).
  In frame they still read as rectangular wall panels at the hill edge —
  silhouette not carved into the mountain, colour dark taupe vs slope.
  Next lever: cliffs must be part of the heightfield (steepened displaced
  slope band with rock shading), not separate panels.
- Foliage: NOT. Painted foliage texture (leaf clusters + light tips) applied
  and palette lightened, one autumn accent; canopies still render as dark
  speckled blobs — texture multiplies too dark on faceted cores.
  Next lever: unmultiply (bright albedo / emissive lift) or rebake canopy
  texture at much higher key with per-face light variance.
- Light/softness: PARTIAL. Roughness 1.0, shadow blur up, warm fog denser;
  full frame is softer/warmer than R11 but still sharp low-poly vs target's
  painterly softness.
- Retained: roofs read shingled at full frame (R10 solve holds), density/life
  (6 carriers, 3 posed work figures, market stall) intact. No animals invented.

Rounds: round36 (cliffs culled/invisible, foliage dark), round37 (cliff wall
at slope toe), round38 (cliffs up-slope, brighter; still wall-like).
Perf round38: 178 draw calls, 92,713 prims, ~23,134 authored tris.
Screenshot: phase3/round38.png; scorecard SCORECARD_PHASE3_R12.png.
