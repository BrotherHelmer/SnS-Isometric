# GFX-B: concept closer (presentation only)

Stacked on GFX-A / G1. See `GFX_B_GAP.md` for the full gap list.
No HUD rewrite, no audio, no gameplay-rule or save-format changes.
No raider / scout / night-guard outline edits.

## Shipped

- **Fog of war**: cool slate unknown + three-octave wisps. On-map unknown
  stays covering (#47). Off-map is still the G1 beach / sea.
- **Grass**: living-green authored hues (`#6A824E` / `#456038`), stronger
  macro, cheap meadow patches. Dirt and farm wheat stay.
- **Buildings**: runtime remap only. Castle → pale masonry + blue-grey
  slate. House / farm / bakery teal roofs → terracotta.
- **Night**: moon 0.56, ambient 0.74, fill 0.32, ground tint lifted.
  Windows remain the bright pixels. Road lift stays 0.12.
- **Water**: teal-green deep / shallow. Still unshaded, fog-disabled.
- **Canopy**: one-step tint lift. Same 6-silhouette kit.

## Still off on Recommended

SDFGI, volumetric fog, PCSS, SSIL, glow. RTX 4070 is the target; nothing
heavier ships without a quality toggle.

## Assets

CC0 KayKit runtime + project-authored opening-style meshes
(`docs/art/ASSET_LEDGER.md`). No new vendor drops.
