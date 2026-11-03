# Scorecard Phase 3 R13 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.
Two of Black's three R12 blockers materially improved this round.

## Per criterion
- Carved rock in terrain: IMPROVED, not solved. Separate cliff panels are
  GONE. The back hill was steepened in `_h` itself (faster rise, crag noise
  displacement scaled by hill height), terrain grid refined 56->88, and the
  heightfield now shades continuously grass low / dirt mid / rock on steep
  slopes with strata band darkening + crevice vertex AO; steep faces shed
  snow. In frame the mountain is one continuous landform — no wall panels.
  Still NOT: the visible face reads as a smooth taupe slope band rather
  than target's craggy grey rock with a snow cap; the snowline now sits
  mostly above frame, so the white cap is largely absent in shot.
  Next lever: stronger/greyer rock albedo texture on steep band + pull
  snowline into frame (camera/hill framing), more aggressive crag amplitude.
- Canopy brightness/variance: IMPROVED, closest yet. Canopy texture was
  repainted as a near-white luminance mottle (it no longer dark-multiplies),
  canopies moved to a dedicated vertex-coloured merged mesh with per-face
  random brightness variance + top-face lightening, brighter spring palette
  (79c24d/a9dd77 + variants, one autumn accent). Trees now read as bright
  leafy mottled masses, not dark speckled blobs. Still slightly faceted/
  uniform vs target's painterly foliage.
- Softness/light: PARTIAL. Contrast 1.12->1.05, saturation 1.22->1.15,
  shadow opacity 0.55->0.45, fog denser warm. Frame is softer/warmer, but
  buildings/terrain still read sharp low-poly vs target painterly surfaces.
- Retained: shingled roofs read at full frame; density/life (carriers,
  posed work figures, market stall, flags) intact. No animals invented.

Rounds: 39 (panels removed, heightfield rock, bright canopy — 162 draws),
40 (rock band exposed, scree lightened), 41 (greyer rock, stronger strata).
Perf round41: 162 draw calls, 100,929 prims, ~22,238 authored tris.
Screenshot: phase3/round41.png; scorecard SCORECARD_PHASE3_R13.png.
