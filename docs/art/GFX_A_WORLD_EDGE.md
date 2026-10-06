# G1: world edge as an island

The playable province is no longer a slab in a teal void.

- **Water**: a huge unshaded, fog-disabled plane (`settlement_water.gdshader`)
  that outruns max zoom. No sun-glint or dusk sun-scatter streaks.
  Colour fades into the sky-ground so there is no visible outer sea
  edge. Subtle day waves; night LOD turns them off. Interior discarded
  so grass stays grass.
- **Coast**: water, ground, and fog share one elliptical blob plus
  coves (not a rectangular inset). Beach/rock on the shore. No cream
  torus / bevel plate / rectangular tree ring. Interior unexplored
  tiles stay under #47 fog.
- **Horizon**: two low-detail hill rings plus the period sky gradient.
- Fog-of-war keeps #47 on-map behaviour: unexplored *interior* tiles
  stay unknown. The noisy waterline is world geography, so fog does
  not paint a rectangular pad over the sea. Off-map is the G1
  sea/horizon. PSSM split 0.82, terrain does not cast, flat world-up
  ground normals, SSAO sharpness 0.35.

Stacked on GFX-10 over `cursor/dawn-aftermath-72ce`. No HUD, audio,
gameplay-rule or workflow changes.
