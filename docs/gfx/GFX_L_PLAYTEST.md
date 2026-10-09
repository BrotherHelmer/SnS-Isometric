# GFX-L self-playtest notes

Harness: `tests/t_gfx_l_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe. Seed = `DEFAULT_SEED` (260821). Covers the first **15 game
minutes** (opening, build, scout, first night, raid).
`SNS_PLAYTEST_LOG=1` also wrote `artifacts/gfx_l/playtest/dpm.csv`.

CSV: `docs/gfx/gfx_l_playtest.csv`  
Comparison cameras: `tests/t_gfx_l_shots.gd` → `artifacts/gfx_l/after/`.  
CONCEPT vs NOW / GFX-K vs GFX-L:
    `/opt/cursor/artifacts/gfx-l/concept_vs_now_*.png` and
`gfxk_vs_gfxl_*.png`.

Master bus stayed `1.000`. Scout result:
`Bjorn scouts toward the fog.` Build road / house: **true / true**.
Showcase buildings / roads: **16 / 37** (playtest) and **15 / 37**
(shots). Script errors: **0**.

Stacked on GFX-K (`b8d7f9f`, PR #68, ChatGPT **6.7/10**). Day grade
knobs (sat 1.12 / contrast 1.12 / exposure 0.86) were not retuned.
K fog / forest / wheat / trim / night stay.

W = Town Hall 4×4 = **10.0 m**. R = cell × 0.97 = **2.425 m**.

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
| 1 Regressions | **Pass** | Foundation ≤ 0.06B, face `#A99D82` / top `#C1B394` / edge `#756C5B`. TrimFacade bunker wrap removed. Straight turquoise `PlaneMesh` creek removed. Farm dirt_plot plate dropped; remaining plots tinted `#886C49`. |
| 2 Architecture | **Pass** | Limestone `#CDBD9F`, plaster `#E0CDAE`, timber `#64452F`, slate `#456D68`. Modular façade panels, recessed arch, parapets, house plaster face. K pilasters / beams / dressing kept. |
| 3 Authored ground | **Pass** | Meadow `#5A7545`, lush `#344D34`, earth `#886C49`, road `#B0926C`, gravel `#929080`. Sparse rut Decals (`albedo_mix` 0.65) on hash-selected crossroads. |
| 4 Framing / shroud | **Pass** | 1.5× zoom cap stays. Apron continues meadow under the shroud. Explored brightness 0.45; overlay alpha stays K's 0.55. |
| 5 Ridge + creek | **Pass** | 10 bevelled masses + KayKit Forest Nature CC0 rocks. Curve3D ribbon, water `#315C61`, roughness 0.28. |

Licences: `docs/ASSET_LICENSES.md`. No Quaternius / Poly Haven files
were imported.

## Frame / wait times (lavapipe, not a 4070)

| event | wait_ms | frame_ms | night | errors | notes |
| --- | ---: | ---: | ---: | ---: | --- |
| opening_day | 9761 | 229.3 | 0 | 0 | ridge / creek landmark |
| build_day | 2978 | 218.9 | 0 | 0 | road + house placed |
| scout_day | 5196 | 232.0 | 0 | 0 | `Bjorn scouts toward the fog.` |
| first_night | 3215 | 197.7 | 1 | 0 | first night inside the window |
| night_raid | 2242 | 205.9 | 1 | 0 | RAID banner, moonlit blue |
| fifteen_minutes | 3058 | 255.8 | 0 | 0 | elapsed 901.6 s |
| showcase_day | 3970 | 318.5 | 0 | 0 | 16 buildings / 37 roads |
| showcase_wide | 4306 | 361.8 | 0 | 0 | 1.5× cap (39) |
| fog_edge | 4331 | 375.6 | 0 | 0 | zoom 39, **day** |

`wait_ms` is wall time for 12 process frames + one `frame_post_draw`.
`frame_ms` is `Performance.TIME_PROCESS` on software Vulkan.

## Perf guard (same machine)

| step | GFX-K lavapipe | lavapipe GFX-L cold | lavapipe GFX-L warm |
| --- | ---: | ---: | ---: |
| `start_new_3d` | 461 ms | **460 ms** | **465 ms** |
| showcase `_sync_presentation` | 527 ms | **541 ms** | **530 ms** |
| first frame after showcase | 2103 ms | 8305 ms | **2033 ms** |

`T_GFX_E_PERF` PASS. `T_GFX_PERF` PASS (`GFX_PERF_DONE`: day 228 /
dusk 224 / night 183 / first-view 164 ms). Start stays inside 2×
GFX-D (1000 ms). Helmer's first-frame gate is **< 3 s**: the warm
lavapipe first frame is **2.03 s**. The 8.3 s cold number is shader
compile on llvmpipe, not a GDScript rebuild.

## Tests

| test | result |
| --- | --- |
| `t_gfx_l` | PASS |
| `t_gfx_l_playtest` | PASS (15 game minutes, errors=0) |
| `t_gfx_l_shots` | PASS |
| `t_gfx_k` | PASS |
| `t_gfx_j` | PASS |
| `t_gfx_i` | PASS (stone `#716A5D` accepted) |
| `t_gfx_h` | PASS (meadow_lush x ≥ 0.18) |
| `t_gfx_g` | PASS (meadow_lush x ≥ 0.18) |
| `t_gfx_f` | PASS |
| `t_gfx_e` | PASS |
| `t_gfx_e_perf` | PASS |
| `t_gfx_d` | PASS |
| `t_gfx_light` | PASS (roof roughness ≤ 0.88) |
| `t_gfx_b` | PASS |
| `t_gfx_c` | PASS |
| `t_gfx_perf` | PASS (`GFX_PERF_DONE`) |
| `opening_style_models` | PASS |
| `phase4_2_parse_smoke` | PASS |
| `audit_export_packing.py` | PASS (`MISSING FROM EXPORT: 0`) |

## 3D-area metrics (HUD cropped, lavapipe)

`luma / luma_std / sat / hue`

| shot | CONCEPT | GFX-K | GFX-L |
| --- | --- | --- | --- |
| opening_day | 75.5 / 50.7 / 0.501 / 78° | 61.1 / 45.5 / 0.487 / 100° | 63.3 / 47.5 / 0.480 / 97° |
| showcase_day | 72.4 / 50.3 / 0.505 / 87° | 70.6 / 47.7 / 0.507 / 76° | 71.7 / 49.0 / 0.491 / 77° |
| showcase_wide | 75.5 / 50.7 / 0.501 / 78° | 71.0 / 44.2 / 0.482 / 114° | 71.1 / 44.6 / 0.474 / 115° |
| fog_edge | — | 65.3 / 43.3 / 0.464 / 131° | 66.4 / 44.1 / 0.461 / 130° |
| night_raid | — | 42.7 / 25.4 / 0.322 / 182° | 43.1 / 25.4 / 0.316 / 184° |

Hue was not retuned. Opening luma lifted ~2 points vs K because the
bunker wrap and pale dirt_plot are gone and the meadow floor is
`#5A7545`. Saturation is slightly lower. The concept is still a
denser, higher-contrast Nordic diorama.

## Playability gates

| gate | result |
| --- | --- |
| No crashes / script errors | **Pass** — playtest `errors=0` |
| First frame < 3 s | **Pass** — warm lavapipe **2033 ms** |
| All tests + perf guard | **Pass** |
| Export MISSING | **0** |
| Master bus | **1.000** |
| 15-minute self-playtest | **Pass** — opening, build, scout, first night, raid |

## Strict self-score

**7.0 / 10** on lavapipe. Helmer's holiday bar is **≥ 8/10**. I am
not calling 8. Against `concept_1.png` the board is still KayKit
boxes on a flatter meadow: the bunker foundation, turquoise creek
strip, and white wheat square are gone; the hall sits on a low
three-tone plinth with modular façade panels; the creek is a dark
Curve3D ribbon; KayKit Forest Nature rocks sit on the ridge. That is
a half-step from K's 6.7, not an 8. Wheat, forest mix, screen shroud,
and moonlit night stay. A 4070 shot may add a quarter-step of shadow
depth. Do not merge on this score.

## Five acceptance tests

| test | lavapipe |
| --- | --- |
| 1 No bunker / turquoise strip / white wheat square | Pass — low foundation, ribbon creek, farm wheat-only |
| 2 Modular limestone / plaster / timber across hall, house, workshop | Pass — panels + plaster face; still KayKit silhouettes |
| 3 Authored roads + terrain splat + sparse decals | Pass — `#B0926C` centre, shoulders, rut Decals |
| 4 Framing / terrain under shroud | Pass — 1.5× cap, meadow apron, explored 0.45 / overlay 0.55 |
| 5 Curved creek + rocky ridge | Pass — Curve3D `#315C61` + 10 bevelled + CC0 KayKit rocks |
