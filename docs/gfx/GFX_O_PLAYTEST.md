# GFX-O self-playtest notes

Harness: `tests/t_gfx_o_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe. Seed = `DEFAULT_SEED` (260821). Covers the first **15 game
minutes** (opening, build, scout, first night, raid).

CSV: `docs/gfx/gfx_o_playtest.csv` (filled after the harness run).
Comparison cameras: `tests/t_gfx_o_shots.gd` → `artifacts/gfx_o/after/`.
Package 1 magenta / solid `#556D3F` / red road-mask frames are captured
from the **gameplay camera**.

Stacked on GFX-N (`db38020`, PR #71, ChatGPT **6.5/10**). Day grade
knobs (sat 1.12 / contrast 1.12 / exposure 0.86) stay **frozen**.
KayKit architecture, roofs, Poly Haven textures, forest, and wheat
stay. Chalk-white meadow output and flat dark-green patches were
reverted.

W = Town Hall 4×4 = **10.0 m**. R = cell × 0.97 = **2.425 m**.

## Per-item (plan order)

| item | result | notes |
| --- | --- | --- |
| 1 Diagnose terrain pipeline | pending | magenta / solid / red-mask from gameplay camera |
| 2 Distance-field roads | pending | `#AD8D66` last-blend, X/Z world UVs |
| 3 Blended meadow | pending | `#3E5938` max 0.35, no cylinder blobs |
| 4 Light-stone castle | pending | `#CFC2A6` / `#E0D0B2` / `#847C6B`, wall_lift 1.32 |
| 5 Clearing + forest + ridge | pending | 2.5–3W, 40–55% perimeter, camera-side creek |

Licences: `docs/ASSET_LICENSES.md` (GFX-O distance-field row).
