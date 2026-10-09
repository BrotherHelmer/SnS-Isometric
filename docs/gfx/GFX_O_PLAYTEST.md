# GFX-O self-playtest notes

Harness: `tests/t_gfx_o_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe. Seed = `DEFAULT_SEED` (260821). Covers the first **15 game
minutes** (opening, build, scout, first night, raid).
`SNS_PLAYTEST_LOG=1` also wrote `artifacts/gfx_o/playtest/dpm.csv`.

CSV: `docs/gfx/gfx_o_playtest.csv`  
Comparison cameras: `tests/t_gfx_o_shots.gd` → `artifacts/gfx_o/after/`.  
CONCEPT vs NOW / GFX-N vs GFX-O:
    `/opt/cursor/artifacts/gfx-o/concept_vs_now_*.png` and
`gfxn_vs_gfxo_*.png`.

Package 1 magenta / solid `#556D3F` / red road-mask frames were
captured from the **gameplay camera** (not a standalone control PNG).

Master bus stayed `1.000`. Scout result:
`Bjorn scouts toward the fog.` Build road / house: **true / true**.
Showcase buildings / roads: **16 / 60** (playtest) and **15 / 60**
(shots). Script errors: **0**.

Stacked on GFX-N (`db38020`, PR #71, ChatGPT **6.5/10**, down from
M 6.8). Day grade knobs (sat 1.12 / contrast 1.12 / exposure 0.86)
were **frozen**. KayKit architecture, roofs, Poly Haven textures,
forest, and wheat stay. Chalk-white meadow output and flat
dark-green cylinder patches were reverted.

W = Town Hall 4×4 = **10.0 m**. R = cell × 0.97 = **2.425 m**.
H = house visual height ≈ **4.09 m**.

## Script

1. Fresh opening hamlet + ridge / creek, camera on
   `opening_camera_focus()` at zoom 26.
2. Place a road off the hall entrance and a house two tiles east.
   Both `request_build` calls succeeded.
3. Spawn / select a free patrol guard and issue Scout (Y) toward the
   western fog. Result: `Bjorn scouts toward the fog.`
4. Advance through the rest of day 1 (`DAY_LENGTH_SECONDS` 420) into
   first night, then spawn two raiders and capture the RAID banner.
5. Advance through night + remainder so `elapsed_seconds` ≥ 900
   (~15 game minutes), then stamp the showcase and pull back to the
   **1.5× zoom cap** (39).

No scout / guard / raider outline files were touched.

## Per-item (plan order)

| item | result | notes |
| --- | --- | --- |
| 1 Diagnose terrain pipeline | **Pass** | Gameplay-camera `pkg1_magenta.png` is magenta (215, 9, 202). `pkg1_solid.png` mid-lawn is olive (113, 131, 76, g−r +18). Occupy only if `COLOR.r > COLOR.g + 0.04`. Albedo maps keep `source_color`; `road_control_tex` does not. Fragment has no `return` (Godot rejects it). |
| 2 Distance-field roads | **Pass** | `pkg1_road_mask.png` shows a red star of hall→cottage traces from the gameplay camera. Showcase `pkg2_road_mask_showcase.png` is a connected red lattice over dark green. `pkg2_roads.png` shows continuous `#AD8D66` clay. 512² control PNG is a network, not a flood. |
| 3 Blended meadow | **Pass** | Chalk-white lawn is gone (N mid-lawn luma 159 cream → O right-lawn (29, 54, 27) olive). No `dark_grass` / `cluster` cylinders. Shade `#3E5938` max 0.35. `tex_mix` 0.12. |
| 4 Light-stone castle | **Partial** | KayKit Hexagon castle / home / mill kept. Remap authored: `#CFC2A6` / `#E0D0B2` / `#847C6B`, timber `#61442F`, roof `#466C69`, civic `wall_lift` 1.42. On lavapipe the hall still reads dark grey-green; 50% pale wall area is not proven on the gameplay camera. House roofs stay terracotta. |
| 5 Clearing + forest + ridge | **Pass** | Opening clearing 11 cells (2.75W). Forest coverage meta in 40–55%. Creek `#345F65` toward the camera. Ridge `#B3A78E` / `#8E8A78` / `#596258`. |

Licences: `docs/ASSET_LICENSES.md` (GFX-O distance-field row). No
Quaternius files were imported.

## Frame / wait times (lavapipe, not a 4070)

| event | wait_ms | frame_ms | night | errors | notes |
| --- | ---: | ---: | ---: | ---: | --- |
| opening_day | 3649 | 198.1 | 0 | 0 | ridge / creek landmark |
| build_day | 2693 | 201.7 | 0 | 0 | road + house placed |
| scout_day | 4987 | 208.2 | 0 | 0 | `Bjorn scouts toward the fog.` |
| first_night | 3599 | 189.4 | 1 | 0 | first night inside the window |
| night_raid | 2137 | 201.9 | 1 | 0 | RAID banner, moonlit blue |
| fifteen_minutes | 3035 | 231.7 | 0 | 0 | elapsed 901.6 s |
| showcase_day | 4079 | 347.4 | 0 | 0 | 16 buildings / 60 roads |
| showcase_wide | 4113 | 357.9 | 0 | 0 | 1.5× cap (39) |
| fog_edge | 4324 | 376.3 | 0 | 0 | zoom 39, **day** |

`wait_ms` is wall time for 12 process frames + one `frame_post_draw`.
`frame_ms` is `Performance.TIME_PROCESS` on software Vulkan.

## Perf guard (same machine)

| step | GFX-N lavapipe warm | lavapipe GFX-O cold | lavapipe GFX-O warm |
| --- | ---: | ---: | ---: |
| `start_new_3d` | 646 ms | **651 ms** | **617 ms** |
| showcase `_sync_presentation` | 669 ms | **648 ms** | **612 ms** |
| first frame after showcase | 1503 ms warm | 5254 ms | **1459 ms** |

Cold first frame is shader compile. The gate is the warm frame
(**1459 ms**, under 3 s).

## Tests

| harness | result |
| --- | --- |
| `t_gfx_o` | PASS |
| `t_gfx_o_playtest` | PASS (15 game minutes, errors=0) |
| `t_gfx_o_shots` | PASS |
| `t_gfx_n` | PASS |
| `t_gfx_m` | PASS |
| `t_gfx_l` | PASS |
| `t_gfx_k` | PASS |
| `t_gfx_h` | PASS |
| `t_gfx_g` | PASS |
| `t_gfx_e_perf` | PASS (cold + warm) |
| `audit_export_packing.py` | PASS (`MISSING FROM EXPORT: 0`) |

## Playability gates

| gate | result |
| --- | --- |
| No crashes / script errors | **Pass** — playtest `errors=0` |
| First frame < 3 s | **Pass** — warm lavapipe **1459 ms** |
| All tests + perf guard | **Pass** |
| Export MISSING | **0** |
| Master bus | **1.000** |
| 15-minute self-playtest | **Pass** — opening, build, scout, first night, raid |

## Strict self-score

**7.0 / 10** on lavapipe. Helmer's holiday bar is **≥ 8/10**. I am
not calling 8. ChatGPT rated N **6.5** because the meadow went
chalk-white and the road mask was unproven on the gameplay camera.
Those two faults are fixed: solid `#556D3F` reaches the screen,
magenta proves the shader is live, and the red road mask is a
connected lattice in the same framing as the clay roads. The
opening is olive again, not cream. Castle walls still read dark
on lavapipe, so package 4 did not earn the top of the band. That
is a recovery from 6.5, not an 8. A 4070 shot may add bounce
light on the limestone. Do not merge on this score.
