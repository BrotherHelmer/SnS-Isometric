# GFX-S self-playtest notes

Harness: `tests/t_gfx_s_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe (no `--headless` — that path uses the dummy renderer and never
presents a 1280×720 frame). Seed = `DEFAULT_SEED` (260821). Covers the
first **15 game minutes** (opening, build, scout, first night, raid).
`SNS_PLAYTEST_LOG=1` also wrote `artifacts/gfx_s/playtest/dpm.csv`.

CSV: `docs/gfx/gfx_s_playtest.csv`  
Comparison cameras: `tests/t_gfx_s_shots.gd` → `artifacts/gfx_s/after/`.  
CONCEPT vs NOW / GFX-R vs GFX-S:
    `/opt/cursor/artifacts/gfx-s/concept_vs_now_*.png` and
`gfxr_vs_gfxs_*.png`. Same GFX-R / GFX-Q / GFX-P gameplay cameras at
1280×720. Showcase frames dismiss the RAID banner and clear hostiles.

Every package frame was captured from the **gameplay camera**.

Master bus stayed `1.000`. Scout result:
`Bjorn scouts toward the fog.` Build road / house: **true / true**.
Showcase buildings / roads / pop: **16 / 60 / 29/40** (playtest) and
**15 / 60 / 25/35** (shots, 9 workers). Script errors: **0**.
Castle light-wall ratio **78.2%** (stacked `t_gfx_r` on this head) and
**99.2%** on the opening keep at zoom 34. Tall tower top **9.55 m**.

Stacked on GFX-R (`d384baf`, PR #75, ChatGPT **7.7/10**, +0.4 vs Q).
Day grade knobs (sat 1.12 / contrast 1.12 / exposure 0.86) stay
**frozen**. Night stays frozen. Day *light* is the S refinement
(sun `#FFD2A0` 1.10 at 30°, ambient `#9A9A88` 0.40, fill `#C4B088`).

W = Town Hall 4×4 = **10.0 m**. R = cell × 0.97 = **2.425 m**.

## Script

1. Fresh opening hamlet + grassy ridge / west creek, camera on
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

## Per-item (five GFX-S changes)

| item | result | notes |
| --- | --- | --- |
| 1 Castle facade / gatehouse | **Pass (lavapipe-quiet)** | Buttresses, recessed portal, gate arch, string courses, slit windows, timber trim, herald. Nodes present. At 720p the front wall is no longer one slab, but it still reads as a fortified manor more than the concept castle. Light-wall **78.2%** / opening **99.2%**. |
| 2 Clustered ground detail | **Pass (lavapipe-quiet)** | 3×3 MultiMesh clumps of tufts / flowers / stones. `t_gfx_s` confirmed several Patch_* MultiMeshes. Density is better than R's even scatter; not concept-lush at zoom 26. |
| 3 Roads / aprons | **Pass** | Visual width **0.72** of authored, wobble, grass-eating shoulders, smaller irregular pads. Paths still flatten at zoom 26 on lavapipe. |
| 4 Colour / light | **Pass** | Cooler ambient `#9A9A88`, fill `#C4B088`, horizon `#C4B8A4`. Sunlit grass cooled off yellow-olive. Meadow identity stays `#536C3F`. Night moon `#A8B8D4` 0.42 / ambient 0.30 unchanged. |
| 5 Forest edges | **Pass (lavapipe-quiet)** | Opening-ring understory and saplings. Coverage stayed planted / candidates (**0.38–0.58**). Map-wide extra trees were rejected so lavapipe fill-rate stayed inside the first-frame gate. |

Licences: `docs/ASSET_LICENSES.md` (GFX-S civic keep + ground / roads /
light rows). No Quaternius files were imported.

## Frame / wait times (lavapipe, not a 4070)

| event | wait_ms | frame_ms | night | errors | notes |
| --- | ---: | ---: | ---: | ---: | --- |
| opening_day | 3592 | 199.2 | 0 | 0 | articulated keep, grassy ridge, west creek |
| build_day | 2445 | 202.7 | 0 | 0 | road + house placed |
| scout_day | 2839 | 217.4 | 0 | 0 | `Bjorn scouts toward the fog.` |
| first_night | 2166 | 208.0 | 1 | 0 | first night inside the window |
| night_raid | 2020 | 183.8 | 1 | 0 | RAID banner, moonlit blue |
| fifteen_minutes | 2642 | 227.2 | 0 | 0 | elapsed 901.6 s |
| showcase_day | 3683 | 318.5 | 0 | 0 | 16 buildings / 60 roads / 29 pop |
| showcase_wide | 4150 | 352.2 | 0 | 0 | 1.5× cap (39) |
| fog_edge | 4388 | 340.0 | 0 | 0 | zoom 39, **day** |

`wait_ms` is wall time for 12 process frames + one `frame_post_draw`.
`frame_ms` is `Performance.TIME_PROCESS` on software Vulkan.

## Perf guard (same machine)

| step | GFX-R lavapipe warm | lavapipe GFX-S cold | lavapipe GFX-S warm |
| --- | ---: | ---: | ---: |
| `start_new_3d` | 930 ms | **927 ms** | **893 ms** |
| first frame after showcase | — | **1531 ms** | **1536 ms** |

`t_gfx_e_perf` PASS twice. First frame **1.53 s** (under 3 s).
`audit_export_packing.py` PASS (`MISSING FROM EXPORT: 0`).

## Stacked gates

| test | result |
| --- | --- |
| `t_gfx_s` | PASS (Master 1.000, pop 25/35, buildings 15, workers 9, tower 9.55 m) |
| `t_gfx_s_playtest` | PASS (15 game minutes, errors=0) |
| `t_gfx_s_shots` | PASS (showcase RAID dismissed; opening light-wall 99.2%) |
| `t_gfx_r` | PASS (castle light-wall 78.2%) |
| `t_gfx_q` | PASS (castle light-wall 78.3%) |
| `t_gfx_p` | PASS (castle light-wall 78.2%) |
| `t_gfx_o` | PASS |
| `t_gfx_n` | PASS |
| `t_gfx_m` | PASS |
| `t_gfx_l` | PASS |
| `t_gfx_k` | PASS |
| `t_gfx_j` | PASS |
| `t_gfx_i` | PASS |
| `t_gfx_h` | PASS |
| `t_gfx_g` | PASS |
| `t_gfx_e_perf` | PASS (cold + warm) |
| `audit_export_packing.py` | PASS (`MISSING FROM EXPORT: 0`) |

## Strict lavapipe score

**7.8 / 10.** ChatGPT R was **7.7**. The five S items landed in the
authored meshes, the distance-field roads, the day palette, and the
opening forest extras. At native 1280×720 on lavapipe the keep is still
a pale manor, the lawn is still a meadow rather than a concept diorama,
and the paths still flatten. That is not an 8 against the concept
stills. Night and grade knobs were not touched.
