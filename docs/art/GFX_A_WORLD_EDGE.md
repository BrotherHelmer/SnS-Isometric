# G1: world edge as an island

The playable province is no longer a slab in a teal void.

- **Water**: a huge unshaded, fog-disabled plane (`settlement_water.gdshader`)
  that outruns max zoom. No sun-glint or dusk sun-scatter streaks.
  Colour fades into the sky-ground so there is no visible outer sea
  edge. Subtle day waves; night LOD turns them off. Interior discarded
  so grass stays grass.
- **Coast**: the ground shader and skipped coastal cells share one
  noisy waterline (coves, headlands, beach/rock). No cream torus /
  bevel plate / rectangular tree ring in the sea. Interior unexplored
  tiles stay under #47 fog.
- **Horizon**: two low-detail hill rings plus the period sky gradient.
- Fog-of-war keeps #47 on-map behaviour: unexplored tiles stay unknown.
  Off-map is the G1 sea/horizon. PSSM split 0.82, terrain does not
  cast, flat world-up ground normals, SSAO sharpness 0.35.

Stacked on GFX-10 over `cursor/dawn-aftermath-72ce`. No HUD, audio,
gameplay-rule or workflow changes.
