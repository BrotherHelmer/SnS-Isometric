# GFX-P self-playtest notes

Harness: `tests/t_gfx_p_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe. Seed = `DEFAULT_SEED` (260821). Covers the first **15 game
minutes** (opening, build, scout, first night, raid).
`SNS_PLAYTEST_LOG=1` also wrote `artifacts/gfx_p/playtest/dpm.csv`.

CSV: `docs/gfx/gfx_p_playtest.csv`  
Comparison cameras: `tests/t_gfx_p_shots.gd` → `artifacts/gfx_p/after/`.  
CONCEPT vs NOW / GFX-O vs GFX-P:
    `/opt/cursor/artifacts/gfx-p/concept_vs_now_*.png` and
`gfxo_vs_gfp_*.png`.

Every package frame was captured from the **gameplay camera**.

Master bus stayed `1.000`. Scout result:
`Bjorn scouts toward the fog.` Build road / house: **true / true**.
Showcase buildings / roads: **16 / 60** (playtest) and **15 / 60**
(shots). Script errors: **0**.

Stacked on GFX-O (`8870238`, PR #72, ChatGPT **7.0/10**, up from
N 6.8). Day grade knobs (sat 1.12 / contrast 1.12 / exposure 0.86)
and night stay **frozen**. Occupancy mask, distance-field road graph,
KayKit meshes, meadow baseline, forest, and fog stay.

W = Town Hall 4×4 = **10.0 m**. R = cell × 0.97 = **2.425 m**.
H = house visual height ≈ **4.09 m**.

## Script

1. Fresh opening hamlet + back ridge / west creek, camera on
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
| 1 Remove creek wedge | **Pass** | O's turquoise diagonal across the village is gone (`gfxo_vs_gfp_creek.png`). New ribbon is west of the hamlet, bake 0.15R / sample 0.20R, width 0.55–0.75R ±12%, water `#345F65`, no emission. Continues under the trees. |
| 2 Worn paths | **Pass** | Distance-field graph kept. Edge noise ±0.07R. Centre `#9F805B`. Showcase `pkg2_road_mask_showcase.png` is still a connected red lattice. Raised meshes match `#9F805B`. Not reverted. |
| 3 Light-stone castle | **Pass** | Civic remap ignores the green atlas. Gameplay-camera `pkg3_castle.png` light-wall ratio **67.8%** (gate ≥50%). Palette `#CDBFA2` / `#E0D0B2` / `#82796A`, roof `#456B68`, timber `#5F442F`, roughness 0.90. House roofs stay terracotta. |
| 4 Meadow richness | **Pass** | Occupy mask kept. Main `#536C3F`, deep `#405A36`, sunlit `#728853`, forest `#344B33`, dry soil `#8B7050`. Broad 4R @ 0.12, local 0.8R @ 0.08, `tex_mix` 0.16. No dark-grass cylinders. |
| 5 Composition / depth | **Pass** | Clearing stays 11 cells (2.75W). Forest 40–55%. One back-right formation 1.5–2.0B × 0.4–0.7B (`#B9AC92` / `#918C79` / `#61675B`). No large foreground rocks. Creek is secondary, not a diagonal obstruction. |

Licences: `docs/ASSET_LICENSES.md` (GFX-P worn-path + civic ignore-atlas
rows). No Quaternius files were imported.

## Frame / wait times (lavapipe, not a 4070)

| event | wait_ms | frame_ms | night | errors | notes |
| --- | ---: | ---: | ---: | ---: | --- |
| opening_day | 3763 | 214.2 | 0 | 0 | back ridge / west creek |
| build_day | 2496 | 216.3 | 0 | 0 | road + house placed |
| scout_day | 2978 | 221.2 | 0 | 0 | `Bjorn scouts toward the fog.` |
| first_night | 2826 | 178.8 | 1 | 0 | first night inside the window |
| night_raid | 2104 | 189.6 | 1 | 0 | RAID banner, moonlit blue |
| fifteen_minutes | 3098 | 239.5 | 0 | 0 | elapsed 901.6 s |
| showcase_day | 3935 | 348.1 | 0 | 0 | 16 buildings / 60 roads |
| showcase_wide | 4287 | 371.8 | 0 | 0 | 1.5× cap (39) |
| fog_edge | 4319 | 384.6 | 0 | 0 | zoom 39, **day** |

`wait_ms` is wall time for 12 process frames + one `frame_post_draw`.
`frame_ms` is `Performance.TIME_PROCESS` on software Vulkan.

## Perf guard (same machine)

| step | GFX-O lavapipe warm | lavapipe GFX-P cold | lavapipe GFX-P warm |
| --- | ---: | ---: | ---: |
| `start_new_3d` | 617 ms | **655 ms** | **633 ms** |
| showcase `_sync_presentation` | 612 ms | **666 ms** | **621 ms** |
| first frame after showcase | 1459 ms warm | 1506 ms | **1524 ms** |

Cold first frame is shader compile. The gate is the warm frame
(**1524 ms**, under 3 s).

## Tests

| harness | result |
| --- | --- |
| `t_gfx_p` | PASS (castle light-wall 67.8%) |
| `t_gfx_p_playtest` | PASS (15 game minutes, errors=0) |
| `t_gfx_p_shots` | PASS |
| `t_gfx_o` | PASS |
| `t_gfx_n` | PASS |
| `t_gfx_m` | PASS |
| `t_gfx_l` | PASS |
| `t_gfx_k` | PASS |
| `t_gfx_j` | PASS |
| `t_gfx_h` | PASS |
| `t_gfx_g` | PASS |
| `t_gfx_e_perf` | PASS (cold + warm) |
| `audit_export_packing.py` | PASS (`MISSING FROM EXPORT: 0`) |

## Playability gates

| gate | result |
| --- | --- |
| No crashes / script errors | **Pass** — playtest `errors=0` |
| First frame < 3 s | **Pass** — warm lavapipe **1524 ms** |
| All tests + perf guard | **Pass** |
| Export MISSING | **0** |
| Master bus | **1.000** |
| 15-minute self-playtest | **Pass** — opening, build, scout, first night, raid |

## Strict self-score

**7.5 / 10** on lavapipe. ChatGPT expected **7.5–7.8**. Helmer's
holiday bar is **≥ 8/10**. I am not calling 8.

O's village-wide turquoise wedge is gone and the civic keep is
measurably pale on the gameplay camera (67.8% light wall area vs O's
unproven dark olive). Worn-path edges keep the O road graph. The
meadow stays olive, not chalk. The west creek and back-right ridge
are authored; they read quieter than the old wedge, which is the
point. Terrain is still a flat plane, and the keep is still a remapped
KayKit hexagon — that is why this is 7.5, not 8. GFX-Q's authored
castle, architecture textures, and terrain relief are the remaining
climb. Do not merge on this score.
