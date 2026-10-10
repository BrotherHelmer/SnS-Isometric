# GFX-T self-playtest notes

Harness: `tests/t_gfx_t_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe (no `--headless` — that path uses the dummy renderer and never
presents a 1280×720 frame). Seed = `DEFAULT_SEED` (260821). Covers the
first **15 game minutes** (opening, build, scout, first night, raid).
`SNS_PLAYTEST_LOG=1` also wrote `artifacts/gfx_t/playtest/dpm.csv`.

CSV: `docs/gfx/gfx_t_playtest.csv`
Comparison cameras: `tests/t_gfx_t_shots.gd` → `artifacts/gfx_t/after/`.
CONCEPT vs NOW / GFX-S vs GFX-T:
    `/opt/cursor/artifacts/gfx-t/concept_vs_now_*.png` and
`gfxs_vs_gfxt_*.png`. Same GFX-S / GFX-R / GFX-Q / GFX-P gameplay
cameras at 1280×720. Showcase frames dismiss the RAID banner and clear
hostiles.

Every package frame was captured from the **gameplay camera**.

Master bus stayed `1.000`. Scout result:
`Bjorn scouts toward the fog.` Build road / house: **true / true**.
Showcase buildings / roads / pop: **16 / 60 / 29/40** (playtest) and
**15 / 60 / 25/35** (shots, 9 workers). Script errors: **0**.
Castle light-wall ratio **99.1%** on the opening keep at zoom 34.

Stacked on GFX-S (`5533a7b`, PR #76, ChatGPT **8.0/10**, +0.3 vs R).
Day grade knobs (sat 1.12 / contrast 1.12 / exposure 0.86) stay
**frozen**. Night stays frozen. Day *light* is the T refinement
(sun `#FFD2A0` 1.10 at 30°, ambient `#A8A088` 0.40, fill `#C8B488`).

W = Town Hall 4×4 = **10.0 m**. R = cell × 0.97 = **2.425 m**.

## Script

1. Fresh opening hamlet + lush meadow / scenic west creek / gardens
   and wash-line, camera on `opening_camera_focus()` at zoom 26.
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

## Per-item (five GFX-T changes)

| item | result | notes |
| --- | --- | --- |
| 1 Lush terrain | **Pass (lavapipe-quiet)** | 3×3 clumps still, plus weed clusters and shader weed / reward patches. Meadow identity stays `#536C3F`. Map-wide grass stayed on the S budget so lavapipe fill-rate held. At zoom 26 the lawn is richer than S, not concept-lush. |
| 2 Supporting buildings | **Pass** | Porches, doors, chimneys, loading docks, house/farm gardens. KayKit house / mill meshes stay. Cottage trim nodes present on dress and live HOUSE views. |
| 3 Scenic creek | **Pass** | Irregular banks, deep run, reed clumps, extra stones, timber `CreekBridge`. Water stays `#2F7A7E`. At the opening camera the ribbon is still a west-edge feature, not a hero close-up. |
| 4 Forest-edge mix | **Pass (lavapipe-quiet)** | Wider tree scale, more deciduous mid-story, denser understory. Coverage stayed planted / candidates (**0.38–0.58**). No map-wide extra trees. |
| 5 Lived-in hamlet + light | **Pass** | Gardens, wash-line, pitchfork, extra wood / barrels. Warmer day ambient `#A8A088`, fill `#C8B488`, horizon `#C8B8A0`. Night moon `#A8B8D4` 0.42 / ambient 0.30 unchanged. |

Licences: `docs/ASSET_LICENSES.md` (GFX-T lush / creek / hamlet row).
No Quaternius files were imported.

## Frame / wait times (lavapipe, not a 4070)

| event | wait_ms | frame_ms | night | errors | notes |
| --- | ---: | ---: | ---: | ---: | --- |
| opening_day | 3565 | 196.9 | 0 | 0 | lush meadow, scenic creek, gardens |
| build_day | 2482 | 206.6 | 0 | 0 | road + house placed |
| scout_day | 2937 | 219.5 | 0 | 0 | `Bjorn scouts toward the fog.` |
| first_night | 2284 | 175.6 | 1 | 0 | first night inside the window |
| night_raid | 2189 | 196.2 | 1 | 0 | RAID banner, moonlit blue |
| fifteen_minutes | 2912 | 243.3 | 0 | 0 | elapsed 901.6 s |
| showcase_day | 3794 | 305.4 | 0 | 0 | 16 buildings / 60 roads / 29 pop |
| showcase_wide | 4356 | 359.6 | 0 | 0 | 1.5× cap (39) |
| fog_edge | 4360 | 358.8 | 0 | 0 | zoom 39, **day** |

`wait_ms` is wall time for 12 process frames + one `frame_post_draw`.
`frame_ms` is `Performance.TIME_PROCESS` on software Vulkan.

## Perf guard (same machine)

| step | GFX-S lavapipe warm | lavapipe GFX-T run 1 | lavapipe GFX-T run 2 |
| --- | ---: | ---: | ---: |
| `start_new_3d` | 893 ms | **902 ms** | **909 ms** |
| first frame after showcase | 1536 ms | **1554 ms** | **1556 ms** |

`t_gfx_e_perf` PASS twice. First frame **1.55 s** (under 3 s).
`audit_export_packing.py` PASS (`MISSING FROM EXPORT: 0`).

## Stacked gates

| test | result |
| --- | --- |
| `t_gfx_t` | PASS (Master 1.000, gardens, wash-line, creek bridge, house porch) |
| `t_gfx_t_playtest` | PASS (15 game minutes, errors=0) |
| `t_gfx_t_shots` | PASS (showcase RAID dismissed; opening light-wall 99.1%) |
| `t_gfx_s` | PASS (widened day fill hexes for T warmth) |
| `t_gfx_r` | PASS |
| `t_gfx_q` | PASS |
| `t_gfx_p` | PASS |
| `t_gfx_o` | PASS |
| `t_gfx_n` | PASS |
| `t_gfx_m` | PASS |
| `t_gfx_l` | PASS |
| `t_gfx_k` | PASS |
| `t_gfx_j` | PASS |
| `t_gfx_i` | PASS |
| `t_gfx_h` | PASS |
| `t_gfx_g` | PASS |
| `t_gfx_e_perf` | PASS (twice) |
| `audit_export_packing.py` | PASS (`MISSING FROM EXPORT: 0`) |

## Strict lavapipe score

**8.1 / 10.** ChatGPT S was **8.0**. The five T items landed in the
opening dress, the live house/farm/workshop trim, the creek ribbon,
the clustered ground patches, and a slightly warmer day fill. At
native 1280×720 on lavapipe the delta versus S is real but quiet —
warmer grass, more cottage attachments, a footbridge and gardens —
not yet the concept's lush diorama. That is not an 8.5 against the
concept stills. Night and grade knobs were not touched.
