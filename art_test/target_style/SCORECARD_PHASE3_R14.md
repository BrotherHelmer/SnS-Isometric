# Scorecard Phase 3 R14 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per criterion
- Grey craggy rock: IMPROVED, not solved. Steep-band albedo is now cool
  grey (878b91 -> 787c83 base, dark 565a61 deep faces), terrain detail
  texture repainted stronger (speckle + strata streaks), crag displacement
  amplitude roughly doubled in `_h` (0.42/0.28/0.18 -> 0.85/0.55/0.35 +
  higher-frequency terms), strata darkening 0.28, crevice AO 0.45, rock
  mottling toward light grey. The hill face is grey and faceted rather
  than taupe-smooth. Still NOT: at full frame it reads as a hazy grey
  slope wall — facet/crag contrast is washed by fog and light, lacking
  target's broken, chunky rock surface and boulder detail on the face.
  Next lever: bake stronger per-face rock colour variance into terrain
  vertices (larger amplitude, lower frequency chunks) and reduce fog
  wash on the hill specifically.
- Snow in frame / composition: IMPROVED. Hill centre moved x17->x14,
  camera look target shifted to (1.3,0.5,-1.1), so the composition now
  matches target layout closer: castle centre, village around, hill
  rising on the right third, trees framing edges. Snow is now patchy
  (noise-gated, h>3.0) and visible as white patches/streaks on the upper
  face in frame, like target's top-of-hill snow. Still less defined than
  target's distinct white cap patches.
- Foliage: RETAINED (R13 bright leafy mottled canopies, per-face variance).
- Softness: PARTIAL, retained gains; fog slightly reduced (0.0060->0.0045)
  to stop the hill washing out, which trades a little softness.
- Roofs/density: RETAINED — shingles read, carriers/figures/stall intact.
  No animals invented.

Rounds: 42 (grey rock, reframed, crag up), 43 (contrast + snow patches),
44 (crevice/snow definition).
Perf round44: 160 draw calls, 100,677 prims, ~22,238 authored tris.
Screenshot: phase3/round44.png; scorecard SCORECARD_PHASE3_R14.png.
