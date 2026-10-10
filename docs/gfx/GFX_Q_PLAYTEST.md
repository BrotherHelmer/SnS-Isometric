# GFX-Q self-playtest notes

Harness: `tests/t_gfx_q_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe. Seed = `DEFAULT_SEED` (260821). Covers the first **15 game
minutes** (opening, build, scout, first night, raid).
`SNS_PLAYTEST_LOG=1` also wrote `artifacts/gfx_q/playtest/dpm.csv`.

CSV: `docs/gfx/gfx_q_playtest.csv`  
Comparison cameras: `tests/t_gfx_q_shots.gd` → `artifacts/gfx_q/after/`.  
CONCEPT vs NOW / GFX-P vs GFX-Q:
    `/opt/cursor/artifacts/gfx-q/concept_vs_now_*.png` and
`gfxp_vs_gfxq_*.png`. Same GFX-P gameplay cameras at 1280×720.

Every package frame was captured from the **gameplay camera**.

Master bus stayed `1.000`. Scout result:
`Bjorn scouts toward the fog.` Build road / house: **true / true**.
Showcase buildings / roads / pop: **16 / 60 / 29/40** (playtest) and
**15 / 60 / 25/35** (shots, 9 workers). Script errors: **0**.

Stacked on GFX-P (`60171c2`, PR #73, ChatGPT **7.1/10**, +0.1 vs O).
Day grade knobs (sat 1.12 / contrast 1.12 / exposure 0.86) and night
stay **frozen**. Occupancy mask, distance-field road graph, KayKit
houses / mill, meadow baseline, forest, west creek, and fog stay.

W = Town Hall 4×4 = **10.0 m**. R = cell × 0.97 = **2.425 m**.

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

## Per-item (ChatGPT's five defects)

| item | result | notes |
| --- | --- | --- |
| 1 Terrain richness | **Pass (lavapipe-quiet)** | Meadow samples dirt / rock maps, dry grass, soil and flowers. Back ridge relief 1.229 m (0.08–0.18B), darker stone `#8A8270` / `#6E6A5C` / `#4E5348` plus ledges. Village stays flat. Still reads quieter than the concept at gameplay zoom. |
| 2 Castle stone | **Pass** | Authored `civic_keep.gltf` / `civic_castle.gltf` + 1K Poly Haven maps. Light-wall ratio **52.6%** (gate ≥50%). Identity limestone `#CDBFA2`, masonry lean on plinth / crenel, slate roofs are geometry. Not P's chalky KayKit hexagon (`gfxp_vs_gfxq_castle.png`). |
| 3 Worn roads | **Pass** | Distance-field graph kept. Circular junction pads, world-space ruts (no fract lattice), visual width 1.06, raised meshes 4.2 / 6.2 cm in the dip. Showcase HUD no longer counts the lattice as buildings. |
| 4 Water readability | **Pass** | Creek `#2F7A7E`, roughness 0.22, wet shoreline, stones and reeds. No emission wedge. Reads in the wide showcase; opening still hides most of the ribbon under the west trees. |
| 5 Lived-in + pop lie | **Pass** | Showcase inhabit sets housing from houses (25/35 shots, 29/40 playtest). HUD Buildings skips ROAD (15 / 16, not 76). 9–15 workers, daytime chimney smoke, farm wheat aprons, contact AO. |

Licences: `docs/ASSET_LICENSES.md` (GFX-Q civic keep + Poly Haven
architecture rows). No Quaternius files were imported.

## Frame / wait times (lavapipe, not a 4070)

| event | wait_ms | frame_ms | night | errors | notes |
| --- | ---: | ---: | ---: | ---: | --- |
| opening_day | 3731 | 209.0 | 0 | 0 | authored keep, ridge, west creek |
| build_day | 2659 | 219.9 | 0 | 0 | road + house placed |
| scout_day | 3091 | 231.7 | 0 | 0 | `Bjorn scouts toward the fog.` |
| first_night | 2320 | 197.7 | 1 | 0 | first night inside the window |
| night_raid | 2171 | 196.6 | 1 | 0 | RAID banner, moonlit blue |
| fifteen_minutes | 2929 | 244.4 | 0 | 0 | elapsed 901.6 s |
| showcase_day | 4073 | 342.8 | 0 | 0 | 16 buildings / 60 roads / 29 pop |
| showcase_wide | 4366 | 362.1 | 0 | 0 | 1.5× cap (39) |
| fog_edge | 4396 | 362.2 | 0 | 0 | zoom 39, **day** |

`wait_ms` is wall time for 12 process frames + one `frame_post_draw`.
`frame_ms` is `Performance.TIME_PROCESS` on software Vulkan.

## Perf guard (same machine)

| step | GFX-P lavapipe warm | lavapipe GFX-Q cold | lavapipe GFX-Q warm |
| --- | ---: | ---: | ---: |
| `start_new_3d` | 633 ms | **907 ms** | **918 ms** |
| showcase `_sync_presentation` | 621 ms | **885 ms** | **899 ms** |
| first frame after showcase | 1524 ms warm | 1635 ms | **1662 ms** |

Cold first frame is shader compile. The gate is the warm frame
(**1662 ms**, under 3 s).

## Tests

| harness | result |
| --- | --- |
| `t_gfx_q` | PASS (castle light-wall 52.6%, pop 25/35, buildings 15, workers 9) |
| `t_gfx_q_playtest` | PASS (15 game minutes, errors=0) |
| `t_gfx_q_shots` | PASS |
| `t_gfx_p` | PASS |
| `t_gfx_o` | PASS |
| `t_gfx_n` | PASS |
| `t_gfx_m` | PASS |
| `t_gfx_l` | PASS |
| `t_gfx_k` | PASS |
| `t_gfx_j` | PASS |
| `t_gfx_i` | PASS |
| `t_gfx_h` | PASS (widened for 4.2 / 6.2 cm worn meshes) |
| `t_gfx_g` | PASS |
| `t_gfx_e_perf` | PASS (cold + warm) |
| `audit_export_packing.py` | PASS (`MISSING FROM EXPORT: 0`) |

## Playability gates

| gate | result |
| --- | --- |
| No crashes / script errors | **Pass** — playtest `errors=0` |
| First frame < 3 s | **Pass** — warm lavapipe **1662 ms** |
| All tests + perf guard | **Pass** |
| Export MISSING | **0** |
| Master bus | **1.000** |
| 15-minute self-playtest | **Pass** — opening, build, scout, first night, raid |

## Strict self-score

**7.6 / 10** on lavapipe. ChatGPT scored P **7.1** and projected
**8.0–8.5** if all five defects landed. Helmer's holiday bar is
**≥ 8/10**. I am not calling 8.

The authored keep, inhabited showcase (25/35 next to 15 buildings,
not 2/5 next to 76), worn junctions, and blue-green creek are real
deltas versus P. Meadow variation and ridge breakup are present in
the shader / dress but still read quietly at gameplay zoom on
software Vulkan — that is why this is 7.6, not 8. Judge from the
composites, not from this number. Do not merge on this score.
