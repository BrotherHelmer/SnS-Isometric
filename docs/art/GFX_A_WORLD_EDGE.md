# G1: world edge as an island

The playable province is no longer a slab in a teal void.

- **Water**: a huge unshaded, fog-disabled plane (`settlement_water.gdshader`)
  that outruns max zoom. No sun-glint or dusk sun-scatter streaks.
  Colour fades into the sky-ground so there is no visible outer sea
  edge. Subtle day waves; night LOD turns them off. Interior discarded
  so grass stays grass.
- **Coast**: derived from the playable AABB, never carved through it.
  Every buildable tile keeps a 2-tile (5 m) beach. Noise only juts the
  shore seaward. The waterline is a rounded-rect iso-line plus a
  high-subdiv beach apron — a soft foam / wet-sand line, not a saw of
  2.5 m tiles. `t_g1_coast_land.gd` fails if any playable tile or placed
  building, road, field or halo sits off the land mask (18-step save and
  a fresh new game).
- **Horizon**: two low-detail hill rings plus the period sky gradient.
- Fog-of-war keeps #47 on-map behaviour: unexplored *interior* tiles
  stay unknown. Off-map is the G1 beach/sea. PSSM split 0.82, terrain
  does not cast, flat world-up ground normals, SSAO sharpness 0.35.

Stacked on GFX-10 over `cursor/dawn-aftermath-72ce`. No HUD, audio,
gameplay-rule or workflow changes.
