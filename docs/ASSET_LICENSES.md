# Asset licences — GFX-L and later

This file records every source used by the live 3D presentation from GFX-L
onward. It does not replace `docs/art/ASSET_LEDGER.md` (KayKit vendor
hashes) or `docs/art/AUDIO_LICENSE_LEDGER.md`.

All runtime meshes and terrain maps below are **CC0 1.0** (public domain).
Attribution is optional. The Nordic diorama look stays KayKit-coherent.

| Asset | Path | Source | Licence | Notes |
| --- | --- | --- | --- | --- |
| KayKit Medieval Hexagon castle | `assets/settlement3d/runtime/buildings/building_castle_green.gltf` | Kay Lousberg — KayKit Medieval Hexagon Pack 1.0 FREE | CC0 1.0 | Live Town Hall / castle from GFX-M. Ledgered in `docs/art/ASSET_LEDGER.md`. |
| KayKit Medieval Hexagon house | `assets/settlement3d/runtime/buildings/building_home_A_green.gltf` | Kay Lousberg — KayKit Medieval Hexagon Pack 1.0 FREE | CC0 1.0 | Live house from GFX-M. |
| KayKit Medieval Hexagon lumbermill | `assets/settlement3d/runtime/buildings/building_lumbermill_green.gltf` | Kay Lousberg — KayKit Medieval Hexagon Pack 1.0 FREE | CC0 1.0 | Live workshop / sawmill from GFX-M. |
| Hexagon trim atlas | `assets/settlement3d/runtime/buildings/hexagons_medieval.png` | Same pack | CC0 1.0 | Shared by the three Hexagon buildings. |
| KayKit Forest Nature rocks | `assets/settlement3d/runtime/nature/Rock_1_A_Color1.gltf` and `Rock_1_B`, `Rock_2_A`, `Rock_2_B` | Kay Lousberg — KayKit Forest Nature Pack 1.0 FREE | CC0 1.0 | Ridge debris, now at 0.15–0.55B. |
| Meadow splat 1024² | `assets/settlement3d/runtime/gfx/terrain/meadow_diff.jpg` | Poly Haven — aerial_grass_rock 1K diff | CC0 1.0 | https://polyhaven.com/a/aerial_grass_rock |
| Forest-floor splat 1024² | `assets/settlement3d/runtime/gfx/terrain/forest_diff.jpg` | Poly Haven — forrest_ground_01 1K diff | CC0 1.0 | https://polyhaven.com/a/forrest_ground_01 |
| Compacted-dirt splat 1024² | `assets/settlement3d/runtime/gfx/terrain/dirt_diff.jpg` | Poly Haven — brown_mud_03 1K diff | CC0 1.0 | https://polyhaven.com/a/brown_mud_03 |
| Rocky-soil splat 1024² | `assets/settlement3d/runtime/gfx/terrain/rock_diff.jpg` | Poly Haven — rock_ground_02 1K diff | CC0 1.0 | https://polyhaven.com/a/rock_ground_02 |
| Opening-style rocks / wheat / fence / lantern / cart | `assets/settlement3d/runtime/opening_style/*.tscn` | Project-authored (`tools/build_opening_style_models.gd`) | CC0 | See `ASSETS/credits.md`. |
| Road rut decal | `assets/settlement3d/runtime/gfx/road_rut_decal.png` | Project-authored Pillow mask | CC0 | Sparse Decal on crossroads. |
| Curved creek ribbon | procedural `Curve3D` + `SurfaceTool` | Project-authored | CC0 | Opaque water `#315D62`. |
| KayKit characters, farm, tools, resources | `assets/settlement3d/runtime/` | Kay Lousberg — Adventurers, Mystery Monthly 6, Resource Bits, RPG Tools | CC0 1.0 | Unchanged from prior ledgers. |
| Cinzel / Source Sans 3 | HUD fonts | Google Fonts | SIL OFL 1.1 | See `docs/art/ASSET_LEDGER.md`. |

No Quaternius files were imported in GFX-M. ambientCG 1K packs were
downloaded as a fallback and are **not** shipped; the live splat maps
are the Poly Haven 1K diffs listed above.

Vendor `License.txt` files remain beside the immutable KayKit source
trees. Do not ship a pack whose licence is not CC0 / SIL OFL / project
CC0.
