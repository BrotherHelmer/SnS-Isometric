# GFX-G self-playtest notes

Harness: `tests/t_gfx_g_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe. Seed = `DEFAULT_SEED` (260821). `SNS_PLAYTEST_LOG=1` also
wrote `artifacts/gfx_g/playtest/dpm.csv`.

CSV: `docs/gfx/gfx_g_playtest.csv`  
Comparison cameras: `tests/t_gfx_g_shots.gd` → `artifacts/gfx_g/after/`.  
CONCEPT vs NOW / GFX-F vs GFX-G:
`/opt/cursor/artifacts/gfx-g/concept_vs_now_*.png` and
`gfxf_vs_gfxg_*.png`.

Master bus stayed `1.000`. Scout result:
`Astrid scouts toward the fog.`

An RTX 4070 capture of GFX-F (`3386cbd`) measured night luma **17.9**
(unplayable), wide/opening hue **102° / 111°**, sat ~0.33–0.37 vs
concept 0.48, contrast std 31–39 vs 47. This pass lifts moonlight into
the 45–60 band, warms the meadow, dresses the opening as a hamlet, and
tries to dissolve the diamond map edge into the wilderness shroud.

## Script

1. Stamp the deterministic ~15-building showcase, shoot zoom 26 and 42.
2. Fresh opening hamlet on the same seed (no showcase) at the closer default.
3. Spawn / select a free patrol guard and issue Scout (Y) toward the
   western fog. Result: `Astrid scouts toward the fog.`
4. Force night, spawn two raiders, capture the RAID banner.
5. Return to **day** and pull back to the fog edge (zoom 68).

No scout / guard / raider outline files were touched.

## Frame / wait times (lavapipe, not a 4070)

| event | wait_ms | frame_ms | night | notes |
| --- | ---: | ---: | ---: | --- |
| showcase_day | 5825 | 415.0 | 0 | 15 buildings + 37 roads, zoom 26 |
| showcase_wide | 5079 | 447.9 | 0 | zoom 42 |
| opening_day | 4531 | 344.5 | 0 | hamlet, zoom 26 |
| scout_day | 4011 | 323.3 | 0 | scout order live |
| night_raid | 3393 | 300.5 | 1 | moon 0.42 / ambient 0.30 |
| fog_edge | 3760 | 326.7 | 0 | zoom 68, **day** |

`wait_ms` is wall time for 12 process frames + one `frame_post_draw`.
`frame_ms` is `Performance.TIME_PROCESS` on software Vulkan.

## Perf guard (same machine)

| step | GFX-E 4070 before | lavapipe GFX-G |
| --- | ---: | ---: |
| `start_new_3d` | ~8 s | **414 ms** |
| showcase `_sync_presentation` | — | **467 ms** |
| first frame after showcase | ~112 s | **1583 ms** |

`T_GFX_E_PERF` PASS. 4070 GFX-F first frame was 0.5 s; this pass does
not reintroduce the 8 s / 112 s rebuild.

## Tests

| test | result |
| --- | --- |
| `t_gfx_g` | PASS |
| `t_gfx_g_playtest` | PASS |
| `t_gfx_g_shots` | PASS |
| `t_gfx_f` | PASS |
| `t_gfx_e` | PASS |
| `t_gfx_e_perf` | PASS |
| `t_gfx_d` | PASS |
| `t_gfx_light` | PASS |
| `t_gfx_b` | PASS |
| `t_gfx_c` | PASS |
| `t_gfx_perf` | PASS (`GFX_PERF_DONE`) |
| `opening_style_models` | PASS |
| `phase4_2_parse_smoke` | PASS |
| `audit_export_packing.py` | PASS (`MISSING FROM EXPORT: 0`) |

## Lavapipe 3D-area metrics (HUD cropped)

Concept (left of the GFX-F composite): luma **86.3** / std **48.1** /
sat **0.472** / hue **62°**. ChatGPT + 4070 concept: 84.8 / 47.3 / 0.48 / 66°.

| shot | GFX-F 4070 | GFX-G lavapipe |
| --- | --- | --- |
| showcase_day | 88.7 / 31.7 / 0.35 / 68° | **76.7 / 40.3 / 0.498 / 61°** |
| showcase_wide | 75.2 / 38.4 / 0.37 / 102° | 71.2 / 40.5 / 0.443 / 88° |
| opening_day | 77.7 / 39.5 / 0.33 / 111° | **78.3 / 42.9 / 0.486 / 71°** |
| night_raid | 17.9 / 10.0 / 0.34 / 183° | **51.3 / 19.0 / 0.247 / 124°** |
| fog_edge | 87.3 / 33.6 / 0.28 / 153° | 103.1 / 42.2 / 0.296 / 152° |

Night lands in the 45–60 band (51). Opening hue is 71° (target 65–75).
Day sat is 0.44–0.50. Contrast std moved to 40–43 vs 47. Day luma on
lavapipe is ~77; 4070 GFX-F tracked ~6% brighter than lavapipe on the
close shot, so hardware day may sit nearer 82–85.

## Score vs `concept_1.png`

**6.4 / 10** on lavapipe. Target was **6.5+ / 10**.

The opening is a hamlet (four cottages, fences, well, cart, wood)
instead of one hall on a lawn. Night is playable. Meadow hue left the
olive-teal hole on the opening camera. I will not mark 6.5 while the
fog-edge island is still a readable diamond, wide hue is 88° not 70°,
and contrast std has not crossed 45.

### Why not 6.5

- `fog_edge` still reads as a rounded-rect island in the shroud. Shore
  / water match `#17262A` and a rim veil is in the fog shader; the
  silhouette remains.
- `showcase_wide` hue is 88°, better than 102°, not yet 65–75°.
- Contrast std 40–43 vs concept 47. Dirt and clumps are there; the
  software frames still flatten building shadows.
- Night windows are warm dots, not large fire pools, on lavapipe.
- Units remain KayKit ticks. Building silhouettes stay inside the
  locked AABB.

### What did move vs GFX-F (same cameras)

- Night moon 0.18 → 0.42, ambient 0.16 → 0.30, exposure 0.67 → 0.84.
  Window / fire pools unclamped to 8–9 m. Luma 18 → 51.
- Meadow `#68743A` / sunlit `#8A9848` / forest `#3E4E28`. Opening hue
  111° → 71°. Wide 102° → 88°.
- Dirt 0.34 → 0.48, more grass clumps. Day sat 0.33–0.37 → 0.44–0.50.
- OpeningDress is a presentation hamlet. Nature rebuilds no longer
  wipe it.
- Shore / water / apron dissolve into fog `#17262A`. Five irregular
  edge-forest rings.

### GPU_SHOTS

A normal Windows export with `SNS_GFX_SHOTS=<dir>` writes the same
cameras at 1920×1080, pauses, and quits. Isolate `user://` with a temp
`APPDATA` / `LOCALAPPDATA` or `XDG_DATA_HOME`. See
`docs/gfx/GPU_SHOTS.md`. That is the path for a 4070 GFX-G pass.

CSV committed at `docs/gfx/gfx_g_playtest.csv`.
