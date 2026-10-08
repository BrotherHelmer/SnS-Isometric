# GFX-D: art-direction pass (presentation only)

Stacked on GFX-C (`cursor/gfx-c-visual-pass-b224`). North star:
`concept_1.png`. Target: 6/10 against the concept.

No RTS rewrite, no scout / night-guard / raider-outline gameplay, no
Master-volume change, no `.github/workflows` edits.

## Shipped

- **Camera**: default orthogonal size 38 → 26 (~32% closer). Strategic
  zoom still 68.
- **Golden hour**: Filmic tonemap, warm key `#FFD5A3` at 30–40° elevation,
  cool fill, sat 1.08 / contrast 1.06, stronger SSAO. Glow and 4-split
  shadows stay behind the High quality toggle.
- **Ground**: meadow / warm-meadow / flower tint / gravel. Vertex colour
  now carries occupation (roads, building aprons, visual cart-track,
  forest litter). Black speckle is gone.
- **Dressing**: denser grass, wildflower patches, forest-edge bushes and
  rocks. Grass/flowers do not cast shadows.
- **Buildings**: house, Town Hall and farm rebuilt with half-timber
  X-braces, teal civic roofs, terracotta homesteads, chimneys, pale
  plaster. AABB lock unchanged.
- **Worldgen composition**: a forest crescent and rock shoulder sit just
  outside the founding meadow so NORMAL opening day frames like the
  concept. Expansion toward the Shard stays clear.
- **Showcase**: `ProductionGfxDShowcase` stamps a deterministic ~15
  building village on `DEFAULT_SEED` for like-for-like shots.

## Still off

- Units remain KayKit rigs.
- Coast is still the G1 rounded-rect.
- True volumetrics / SSIL / SDFGI stay postponed.
- Getting from ~6/10 to 8/10 needs more bespoke building silhouettes
  and carved terrain.
