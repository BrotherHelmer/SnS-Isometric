# Asset licences — GFX-L and later

This file records every source used by the live 3D presentation from GFX-L
onward. It does not replace `docs/art/ASSET_LEDGER.md` (KayKit vendor
hashes) or `docs/art/AUDIO_LICENSE_LEDGER.md`.

All runtime meshes and terrain maps below are **CC0 1.0** (public domain).
Attribution is optional. The Nordic diorama look stays KayKit-coherent.

| Asset | Path | Source | Licence | Notes |
| --- | --- | --- | --- | --- |
| Authored civic keep | `assets/settlement3d/runtime/buildings/civic_keep.gltf` | Project-authored (`tools/build_civic_keep.gd`) | CC0 | GFX-Q live Town Hall. Light limestone, timber, slate roof, towers, crenellations. 4×4 / 10 m footprint. |
| Authored civic castle | `assets/settlement3d/runtime/buildings/civic_castle.gltf` | Project-authored (`tools/build_civic_keep.gd`) | CC0 | GFX-Q live Castle. Same keep plus rear towers. |
| Architecture stone 1024² | `assets/settlement3d/runtime/gfx/architecture/stone_diff.jpg` | Poly Haven — brick_wall_02 1K diff | CC0 1.0 | https://polyhaven.com/a/brick_wall_02 — luma/detail under `#CDBFA2`. |
| Architecture plaster 1024² | `assets/settlement3d/runtime/gfx/architecture/plaster_diff.jpg` | Poly Haven — plastered_stone_wall 1K diff | CC0 1.0 | https://polyhaven.com/a/plastered_stone_wall — luma/detail under `#E0D0B2`. |
| Architecture timber 1024² | `assets/settlement3d/runtime/gfx/architecture/timber_diff.jpg` | Poly Haven — wood_planks 1K diff | CC0 1.0 | https://polyhaven.com/a/wood_planks — luma/detail under `#5F442F`. |
| Architecture slate 1024² | `assets/settlement3d/runtime/gfx/architecture/slate_diff.jpg` | Poly Haven — roof_07 1K diff | CC0 1.0 | https://polyhaven.com/a/roof_07 — luma/detail under `#456B68`. |
| Civic architecture shader | `src/GodotClient3D/Shaders/settlement_architecture.gdshader` | Project-authored | CC0 | Binds by Civic* mesh name. tex_mix 0.28. Does not use the green Hexagon atlas. |
| GFX-Q terrain relief | procedural `_visual_relief_y` | Project-authored | CC0 | Presentation only. Back ridge 0.08–0.18B, creek cut −12 cm, road dip 3–6 cm. Occupy mask unchanged. |
| KayKit Medieval Hexagon castle | `assets/settlement3d/runtime/buildings/building_castle_green.gltf` | Kay Lousberg — KayKit Medieval Hexagon Pack 1.0 FREE | CC0 1.0 | Retired as live Town Hall in GFX-Q. Still shipped. Ledgered in `docs/art/ASSET_LEDGER.md`. |
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
| Curved creek ribbon | procedural `Curve3D` + `SurfaceTool` | Project-authored | CC0 | Opaque water `#345F65`. GFX-P west-forest ribbon, bake 0.15R / sample 0.20R, no emission wedge. |
| Kaykit remap shader | `src/GodotClient3D/Shaders/settlement_kaykit_remap.gdshader` | Project-authored | CC0 | Per-surface remap of the Hexagon atlas. GFX-P civic walls ignore atlas RGB and emit limestone / plaster from the world normal. |
| GFX-O distance-field road mask | procedural 512² `Image` + `settlement_ground.gdshader` | Project-authored | CC0 | World-space X/Z distance field. Linear control (no `source_color`). Gameplay-camera debug modes 1–3. |
| GFX-P worn path edges | `settlement_ground.gdshader` noise on the O mask | Project-authored | CC0 | Edge displacement ±0.07R. Centre `#9F805B`. Graph and widths unchanged. |
| KayKit characters, farm, tools, resources | `assets/settlement3d/runtime/` | Kay Lousberg — Adventurers, Mystery Monthly 6, Resource Bits, RPG Tools | CC0 1.0 | Unchanged from prior ledgers. |
| Cinzel / Source Sans 3 | HUD fonts | Google Fonts | SIL OFL 1.1 | See `docs/art/ASSET_LEDGER.md`. |

No Quaternius files were imported in GFX-M or GFX-Q. Terrain splat maps
and the GFX-Q architecture maps are the Poly Haven 1K diffs listed
above. ambientCG 1K packs were considered as a fallback and are **not**
shipped.

Vendor `License.txt` files remain beside the immutable KayKit source
trees. Do not ship a pack whose licence is not CC0 / SIL OFL / project
CC0.
