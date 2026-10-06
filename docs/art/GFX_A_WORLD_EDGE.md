# G1: world edge as an island

The playable province is no longer a slab in a teal void.

- **Water plane** around the map: cheap `settlement_water.gdshader`,
  subtle vertex waves by day, foam in a short shore band. Night LOD
  turns waves off. Interior discarded so grass stays grass.
- **Rim** of beach / rock around the whole slab, plus a cheap foam
  band. Interior unexplored tiles stay under #47 fog; the coast is
  world geography so far zoom reads as an island.
- **Horizon**: two low-detail hill rings (near shore + far sea) plus the
  period sky gradient so far zoom never shows a box.
- Fog-of-war keeps #47 on-map behaviour: unexplored tiles stay unknown.
  Off-map is the G1 sea/horizon (not a 220 m teal pad). A short mist
  lip sits on revealed shores. PSSM split 0.82, terrain does not cast,
  flat world-up ground normals, SSAO sharpness 0.35.

Stacked on GFX-10 over `cursor/dawn-aftermath-72ce`. No HUD, audio,
gameplay-rule or workflow changes.
