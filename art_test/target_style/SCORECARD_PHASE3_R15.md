# Scorecard Phase 3 R15 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per criterion
- Chunky rock face at full frame: IMPROVED, closest yet on geology.
  Per-quad hash variance (cf 0.74–1.30) is now baked into terrain vertex
  colours on the steep band, so the face reads as chunky light/dark grey
  facets at full frame regardless of texture; 15 darker/lighter stone
  blocks are merged partly embedded on the face (y sunk to slope height).
  Fog lowered 0.0045->0.0028 so the hill stays crisp while edges keep
  vignette/grade softness. Still NOT: the face reads dark charcoal-grey
  and uniformly steep vs target's sunlit broken rock with visible loose
  stones/scree texture; embedded blocks blend into the facet noise
  rather than reading as distinct stones.
  Next lever: warm the rock slightly toward target's sunlit grey-brown
  and scale up distinct scree stones at the face base.
- Snow definition: IMPROVED. Noise-gated snow now uses a sharp step
  (patch>0.40 x8, h>2.9 x3, slope<=1.65) in near-white f8fafc; white
  caps/streaks are clearly visible on the upper face in frame. Still
  streakier/thinner than target's broader white caps.
- Fog/softness balance: PARTIAL. Hill is crisp now; overall frame still
  sharp low-poly (buildings, terrain facets) vs target painterly soft.
  Softness retained via vignette, warm grade, soft shadows only.
- Retained: composition (castle centre, hill right third), bright leafy
  canopies, shingled roofs, density/life. No animals invented.

Rounds: 45 (per-face chunk, embedded stones, fog down), 46 (face
lightened, snow caps sharpened).
Perf round46: 164 draw calls, 103,077 prims, ~24,158 authored tris.
Screenshot: phase3/round46.png; scorecard SCORECARD_PHASE3_R15.png.
