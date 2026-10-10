# GFX-R self-playtest notes

Harness: `tests/t_gfx_r_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe. Seed = `DEFAULT_SEED` (260821). Covers the first **15 game
minutes** (opening, build, scout, first night, raid).
`SNS_PLAYTEST_LOG=1` also wrote `artifacts/gfx_r/playtest/dpm.csv`.

CSV: `docs/gfx/gfx_r_playtest.csv`  
Comparison cameras: `tests/t_gfx_r_shots.gd` → `artifacts/gfx_r/after/`.  
CONCEPT vs NOW / GFX-Q vs GFX-R:
    `/opt/cursor/artifacts/gfx-r/concept_vs_now_*.png` and
`gfxq_vs_gfxr_*.png`. Same GFX-Q / GFX-P gameplay cameras at 1280×720.
Showcase frames dismiss the RAID banner and clear hostiles.

Every package frame was captured from the **gameplay camera**.

Master bus stayed `1.000`. Scout result:
`Bjorn scouts toward the fog.` Build road / house: **true / true**.
Showcase buildings / roads / pop: **16 / 60 / 29/40** (playtest) and
**15 / 60 / 25/35** (shots, 9 workers). Script errors: **0**.
Castle light-wall ratio **72.7%**. Tall tower top **9.55 m**.

Stacked on GFX-Q (`182863a`, PR #74, ChatGPT **7.3/10**, +0.2 vs P).
Day grade knobs (sat 1.12 / contrast 1.12 / exposure 0.86) stay
**frozen**. Night stays frozen. Day *light* is the R exception
(sun `#FFD2A0` 1.10 at 30°, ambient `#A89878` 0.40, fill 0.14).

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

## Per-item (ChatGPT's five GFX-R changes)

| item | result | notes |
| --- | --- | --- |
| 1 Castle silhouette | **Pass (lavapipe-quiet)** | Raised keep, three roof masses, tall asymmetric tower 9.55 m, gate, recesses, banner. Light-wall **72.7%**. Still reads as a fortified manor more than the concept castle at zoom 26. |
| 2 Ridge geology | **Pass (lavapipe-quiet)** | Grassy slopes `#536C3F` / `#405A36` / `#344B33`, KayKit outcrops, six ledges, trees at the base. Not Q's tan mound. The hill still sits quietly behind the keep at 720p. |
| 3 Environmental density | **Pass (lavapipe-quiet)** | Three MultiMesh zones (settlement / meadow / forest-edge) with tufts, flowers, shrubs, stones. Empty lawn is smaller than Q but not concept-dense at gameplay zoom. |
| 4 Roads / water / footprints | **Pass** | Irregular aprons, varied widths, stronger world-space ruts. Creek swung to `(-3,6)` and reads as teal water on the west in the wide showcase. Paths still flatten at zoom 26. |
| 5 Late-afternoon light | **Pass** | Warm key, softer fill, chimney smoke and a banner that read on the keep. Night moon `#A8B8D4` 0.42 / ambient 0.30 unchanged. Workers remain small at 720p. |

Licences: `docs/ASSET_LICENSES.md` (GFX-R civic keep + grassy ridge
rows). No Quaternius files were imported.

## Frame / wait times (lavapipe, not a 4070)

| event | wait_ms | frame_ms | night | errors | notes |
| --- | ---: | ---: | ---: | ---: | --- |
| opening_day | 3724 | 204.7 | 0 | 0 | authored keep, grassy ridge, west creek |
| build_day | 2679 | 220.5 | 0 | 0 | road + house placed |
| scout_day | 3052 | 237.7 | 0 | 0 | `Bjorn scouts toward the fog.` |
| first_night | 2302 | 179.4 | 1 | 0 | first night inside the window |
| night_raid | 2173 | 199.1 | 1 | 0 | RAID banner, moonlit blue |
| fifteen_minutes | 2932 | 233.7 | 0 | 0 | elapsed 901.6 s |
| showcase_day | 3972 | 330.4 | 0 | 0 | 16 buildings / 60 roads / 29 pop |
| showcase_wide | 4698 | 435.8 | 0 | 0 | 1.5× cap (39) |
| fog_edge | 4282 | 358.4 | 0 | 0 | zoom 39, **day** |

`wait_ms` is wall time for 12 process frames + one `frame_post_draw`.
`frame_ms` is `Performance.TIME_PROCESS` on software Vulkan.

## Perf guard (same machine)

| step | GFX-Q lavapipe warm | lavapipe GFX-R cold | lavapipe GFX-R warm |
| --- | ---: | ---: | ---: |
| `start_new_3d` | 918 ms | **920 ms** | **930 ms** |
| showcase `_sync_presentation` | 899 ms | **848 ms** | **834 ms** |
| first frame after showcase | 1662 ms | 1598 ms | **1618 ms** |

Cold first frame is shader compile. The gate is the warm frame
(**1618 ms**, under 3 s).

## Tests

| harness | result |
| --- | --- |
| `t_gfx_r` | PASS (castle light-wall 72.7%, tower 9.55 m, pop 25/35, buildings 15, workers 9) |
| `t_gfx_r_playtest` | PASS (15 game minutes, errors=0) |
| `t_gfx_r_shots` | PASS (showcase RAID dismissed) |
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
| `t_gfx_e_perf` | PASS (cold + warm) |
| `audit_export_packing.py` | PASS (`MISSING FROM EXPORT: 0`) |

## Playability gates

| gate | result |
| --- | --- |
| No crashes / script errors | **Pass** — playtest `errors=0` |
| First frame < 3 s | **Pass** — warm lavapipe **1618 ms** |
| All tests + perf guard | **Pass** |
| Export MISSING | **0** |
| Master bus | **1.000** |
| 15-minute self-playtest | **Pass** — opening, build, scout, first night, raid |

## Strict self-score

**7.6 / 10** on lavapipe. ChatGPT scored Q **7.3** and asked for a
castle silhouette, real geology, density, blended paths/water, and
late-afternoon light. Helmer's holiday bar is **≥ 8/10**. Target
**8.5**. I am not calling 8.

The raised keep, tall tower, banner, and clean showcase (no RAID
popup) are real deltas versus Q. The grassy ridge, MultiMesh tufts,
meadow creek, and warmer day key are present, but at native 1280×720
they still read quieter than the concept diorama — empty lawn, a
manor-like keep, and a modest hill. That is why this is 7.6, not 8.
Judge from the composites, not from this number. Do not merge on
this score.
