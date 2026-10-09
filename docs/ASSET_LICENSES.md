# Asset licences — GFX-L and later

This file records every source used by the live 3D presentation from GFX-L
onward. It does not replace `docs/art/ASSET_LEDGER.md` (KayKit vendor
hashes) or `docs/art/AUDIO_LICENSE_LEDGER.md`.

All runtime meshes below are **CC0 1.0** (public domain). Attribution is
optional. The Nordic diorama look stays KayKit / opening-style coherent —
no new third-party style packs.

| Asset | Path | Source | Licence | Notes |
| --- | --- | --- | --- | --- |
| KayKit Forest Nature rocks | `assets/settlement3d/runtime/nature/Rock_1_A_Color1.gltf` and `Rock_1_B`, `Rock_2_A`, `Rock_2_B` | Kay Lousberg — KayKit Forest Nature Pack 1.0 FREE | CC0 1.0 | Ledgered in `docs/art/ASSET_LEDGER.md`. Used on the GFX-L opening ridge. |
| Opening-style rocks / wheat / fence / lantern / cart | `assets/settlement3d/runtime/opening_style/*.tscn` | Project-authored (`tools/build_opening_style_models.gd`) | CC0 | See `ASSETS/credits.md`. |
| Road rut decal | `assets/settlement3d/runtime/gfx/road_rut_decal.png` | Project-authored Pillow mask | CC0 | Sparse Decal on crossroads only. |
| Modular hall / house trim | procedural `BoxMesh` in `production_building_view_3d.gd` | Project-authored | CC0 | Low foundation + façade panels. Not a vendor mesh. |
| Curved creek ribbon | procedural `Curve3D` + `SurfaceTool` | Project-authored | CC0 | Opaque stylized water `#315C61`. |
| KayKit characters, buildings, farm, tools, resources | `assets/settlement3d/runtime/` | Kay Lousberg — Adventurers, Mystery Monthly 6, Resource Bits, RPG Tools, Medieval Hexagon | CC0 1.0 | Unchanged from prior ledgers. |
| Cinzel / Source Sans 3 | HUD fonts | Google Fonts | SIL OFL 1.1 | See `docs/art/ASSET_LEDGER.md`. |

No Quaternius or Poly Haven files were imported in GFX-L. If a later
round adds them, append a row here before the draft PR.

Vendor `License.txt` files remain beside the immutable KayKit source
trees. Do not ship a pack whose licence is not CC0 / SIL OFL / project
CC0.
