# GFX-U self-playtest notes

Harness: `tests/t_gfx_u_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe (no `--headless` — that path uses the dummy renderer and never
presents a 1280×720 frame). Seed = `DEFAULT_SEED` (260821). Covers the
first **15 game minutes** (opening, build, scout, first night, raid).
`SNS_PLAYTEST_LOG=1` also wrote `artifacts/gfx_u/playtest/dpm.csv`.

CSV: `docs/gfx/gfx_u_playtest.csv`
Comparison cameras: `tests/t_gfx_u_shots.gd` → `artifacts/gfx_u/after/`.
CONCEPT vs NOW / GFX-T vs GFX-U:
    `/opt/cursor/artifacts/gfx-u/concept_vs_now_*.png` and
`gfxt_vs_gfxu_*.png`. Unlabeled Phase A checkpoint:
`artifacts/phaseA_unlabeled_t_vs_u.png` (T left, U right, no labels).
Same GFX-T / S / R / Q / P gameplay cameras at 1280×720. Showcase
frames dismiss the RAID banner and clear hostiles.

Every package frame was captured from the **gameplay camera**.

Master bus stayed `1.000`. Scout result:
`Bjorn scouts toward the fog.` Build road / house: **true / true**.
Showcase buildings / roads / pop: **16 / 60 / 29/40** (playtest) and
**15 / 60 / 25/35** (shots, 9 workers). Script errors: **0**.
Castle light-wall ratio **73.6%** on the opening keep at zoom 34
(T was 99% — the deeper recess / three-section front reads darker).

Stacked on GFX-T (`68aea57`, PR #77, ChatGPT **8.0/10**, ±0.0 vs S).
Day grade knobs (sat 1.12 / contrast 1.12 / exposure 0.86) stay
**frozen**. Night stays frozen. Day *light* is warm sun `#FFD2A0`
with cooler fill `#98A8BC` / ambient `#A0A8B0`.

W = Town Hall 4×4 = **10.0 m**. R = cell × 0.97 = **2.425 m**.

## Script

1. Fresh opening hamlet + patched meadow / woodland mass / rocky
   shore, camera on `opening_camera_focus()` at zoom 26.
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

## Per-item (art-direction, not five props)

| item | result | notes |
| --- | --- | --- |
| 1 Ground domains | **Pass (lavapipe-quiet)** | 22–32 m meadow / dark / earth masks + village/woodland uniforms. Meadow identity stays `#536C3F`. A 300×300 crop of the west meadow/shore is no longer one olive slab; inland grass still flattens under Filmic + lavapipe. |
| 2 Large-scale layout | **Pass** | Opening forest clustered to a back woodland mass (coverage still **0.38–0.58**). Camera-front rim thinned so the wide shot has a meadow foreground. West rocky shore + back ridge are the third mass. |
| 3 Castle proportions | **Pass** | Front wall is CivicWall_FrontL/C/R, deeper CivicRecess_Gate, larger CivicHerald. Existing Civic* names stay. At zoom 26 the keep is still a cream mass — recesses read more as a darker door than as three bays. |
| 4 Water | **Pass** | Island water shallows `#3AA8A4`-family turquoise, deep `#1A4558`, foam on the shoreline. DressCreek stays `#2F7A7E`. Night restores the frozen dark water. |
| 5 Light / colour | **Pass** | Warm sun `#FFD2A0` 1.10 at 30°, cooler fill `#98A8BC`, ambient `#A0A8B0`. Contact AO 0.48 on trees. Conifer canopy_lift 1.20–1.22. Night moon `#A8B8D4` 0.42 / ambient 0.30 unchanged. |

Licences: `docs/ASSET_LICENSES.md` (GFX-U ground / layout / light row).
No Quaternius files were imported.

## Frame / wait times (lavapipe, not a 4070)

| event | wait_ms | frame_ms | night | errors | notes |
| --- | ---: | ---: | ---: | ---: | --- |
| opening_day | 3640 | 204.7 | 0 | 0 | patched meadow, woodland, rocky shore |
| build_day | 2831 | 247.5 | 0 | 0 | road + house placed |
| scout_day | 3330 | 262.7 | 0 | 0 | `Bjorn scouts toward the fog.` |
| first_night | 2323 | 185.1 | 1 | 0 | first night inside the window |
| night_raid | 2198 | 197.3 | 1 | 0 | RAID banner, moonlit blue |
| fifteen_minutes | 3102 | 254.8 | 0 | 0 | elapsed 901.6 s |
| showcase_day | 3638 | 291.2 | 0 | 0 | 16 buildings / 60 roads / 29 pop |
| showcase_wide | 4163 | 347.4 | 0 | 0 | 1.5× cap (39) |
| fog_edge | 4305 | 359.2 | 0 | 0 | zoom 39, **day** |

`wait_ms` is wall time for 12 process frames + one `frame_post_draw`.
`frame_ms` is `Performance.TIME_PROCESS` on software Vulkan.

## Perf guard (same machine)

| step | GFX-T lavapipe warm | lavapipe GFX-U run 1 | lavapipe GFX-U run 2 |
| --- | ---: | ---: | ---: |
| `start_new_3d` | 902 / 909 ms | **919 ms** | **915 ms** |
| first frame after showcase | 1554 / 1556 ms | **1533 ms** | **1560 ms** |

`t_gfx_e_perf` PASS twice. First frame **1.53–1.56 s** (under 3 s).
`audit_export_packing.py` PASS (`MISSING FROM EXPORT: 0`).

## Stacked gates

| test | result |
| --- | --- |
| `t_gfx_u` | PASS (Master 1.000, domains, FrontL/C/R, turquoise shallows) |
| `t_gfx_u_playtest` | PASS (15 game minutes, errors=0) |
| `t_gfx_u_shots` | PASS (showcase RAID dismissed; light-wall 73.6%) |
| `t_gfx_t` | PASS (widened day fill hexes for U cooler fill) |
| `t_gfx_s` | PASS (widened day fill hexes) |
| `t_gfx_r` | PASS |
| `t_gfx_p` | PASS |
| `t_gfx_m` | PASS |
| `t_gfx_i` | PASS |
| `t_gfx_g` | PASS (fill.r vs fill.b widened) |
| `t_gfx_e_perf` | PASS (twice) |
| `audit_export_packing.py` | PASS (`MISSING FROM EXPORT: 0`) |

## Strict lavapipe score

**8.2 / 10.** ChatGPT T was **8.0**, same as S — five small props no
longer moved the 720p screenshot. U changed the *picture*: turquoise
shallows versus T's dead teal void, a thinner camera-front tree line,
cooler fill against warm sun, and a three-section keep that tests can
name. Inland grass still collapses toward one olive at strategic zoom
on lavapipe, and the keep still reads as a cream box from the
gameplay camera. That is not an 8.5 against the concept stills. Night
and grade knobs were not touched.
