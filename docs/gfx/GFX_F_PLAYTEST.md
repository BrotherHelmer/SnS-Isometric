# GFX-F self-playtest notes

Harness: `tests/t_gfx_f_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe. Seed = `DEFAULT_SEED` (260821). `SNS_PLAYTEST_LOG=1` also
wrote `artifacts/gfx_f/playtest/dpm.csv`.

CSV: `docs/gfx/gfx_f_playtest.csv`  
Comparison cameras: `tests/t_gfx_f_shots.gd` → `artifacts/gfx_f/after/`.  
CONCEPT vs NOW / GFX-E vs GFX-F:
`/opt/cursor/artifacts/gfx-f/concept_vs_now_*.png` and
`gfxe_vs_gfxf_*.png`.

Master bus stayed `1.000`. Scout result:
`Astrid scouts toward the fog.`

An RTX 4070 capture of GFX-E (`5419e50`) measured 3D-area sat ~0.30
vs concept 0.48, luma 113–125 vs 85, contrast std 34–37 vs 47. Night
was luma 91.6 / hue 177°. This pass applies ChatGPT's Filmic 0.78 /
sat 1.10 / ambient 0.25 / moon 0.18 preset, 4-split shadows, and a
presentation-only opening dress. Lavapipe remains a faithful-but-softer
stand-in for hardware.

## Script

1. Stamp the deterministic ~15-building showcase, shoot zoom 26 and 42.
2. Fresh opening day on the same seed (no showcase) at the closer default.
3. Spawn / select a free patrol guard and issue Scout (Y) toward the
   western fog. Result: `Astrid scouts toward the fog.`
4. Force night, spawn two raiders, capture the RAID banner.
5. Return to **day** and pull back to the fog edge (zoom 68).

No scout / guard / raider outline files were touched.

## Frame / wait times (lavapipe, not a 4070)

| event | wait_ms | frame_ms | night | notes |
| --- | ---: | ---: | ---: | --- |
| showcase_day | 5392 | 364.7 | 0 | 15 buildings + 37 roads, zoom 26 |
| showcase_wide | 4296 | 383.9 | 0 | zoom 42 |
| opening_day | 4326 | 342.0 | 0 | forest-framed founding, zoom 26 |
| scout_day | 6144 | 311.3 | 0 | scout order live |
| night_raid | 3455 | 304.6 | 1 | moon 0.18 / ambient 0.16 |
| fog_edge | 3791 | 327.0 | 0 | zoom 68, **day**, opaque shroud |

`wait_ms` is wall time for 12 process frames + one `frame_post_draw`.
`frame_ms` is `Performance.TIME_PROCESS` on software Vulkan.

## Perf guard (same machine, after GFX-E batching)

| step | GFX-D 4070 | GFX-E 4070 before | lavapipe after (this pass) |
| --- | ---: | ---: | ---: |
| `start_new_3d` | < 1 s | ~8 s | **421 ms** |
| showcase apply | — | — | 10 ms |
| showcase `_sync_presentation` | — | — | **534 ms** |
| first frame after showcase | ~9 s | ~112 s | **2541 ms** |

`T_GFX_E_PERF` PASS. The 8 s / 112 s 4070 regression stays fixed.

## Tests

| test | result |
| --- | --- |
| `t_gfx_f` | PASS |
| `t_gfx_f_playtest` | PASS |
| `t_gfx_f_shots` | PASS |
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

Concept (left of the GFX-E composite): luma **86.6** / std **47.9** /
sat **0.481** / hue **62°**. ChatGPT + 4070 concept: 84.8 / 47.3 / 0.48 / 66°.

| shot | GFX-E luma/std/sat/hue | GFX-F luma/std/sat/hue |
| --- | --- | --- |
| showcase_day | 113.3 / 38.3 / 0.342 / 55° | **83.9 / 32.4 / 0.365 / 65°** |
| showcase_wide | 109.6 / 38.3 / 0.328 / 73° | 72.5 / 38.5 / 0.380 / 96° |
| opening_day | 124.5 / 37.2 / 0.294 / 79° | 74.8 / 37.6 / 0.328 / 112° |
| night_raid | 92.6 / 24.8 / 0.300 / 177° | 17.4 / 9.5 / 0.342 / 185° |
| fog_edge | 133.4 / 30.5 / 0.259 / 155° | 89.6 / 32.1 / 0.262 / 156° |

showcase_day luma is now on the concept's 85. Saturation moved toward
0.40–0.45 but is not there yet. Contrast std is still ~32–38 vs 47.
Night is substantially darker than GFX-E's cyan wash; the RAID banner
and hall windows stay readable. 4070 will be ~2–3% brighter.

## Score vs `concept_1.png`

**5.8 / 10** on lavapipe. Target was **6.5 / 10**. ChatGPT + 4070
scored GFX-E **5.0 / 10**.

Opening is no longer one hall on an empty lawn — a presentation-only
forest frame and rock cluster sit around a playable clearing. Night is
a night. The fog edge lost the peach beach. Day luma on the showcase
close shot finally matches the concept. I will not mark 6.5 while
directional building shadows still fail to separate on these Forward+
software frames, wheat is still a dark block at zoom 26, and contrast
std has not moved toward 47.

### Why not 6.5

- Long, dark, warm-key / cool-shadow building shadows stay weak on
  llvmpipe. Bias, 4 splits, sun 1.20 / ambient 0.25 are set; hardware
  has to prove them.
- Terrain clumps exist and the meadow is darker `#536B3E`, but the
  ground is still one olive plane at zoom 26.
- Opening is a framed cottage, not the concept hamlet.
- Night may be *too* dark on lavapipe (luma 17 vs GFX-D's 68). Raids
  stay playable via the banner and window `#F5B36B`.
- Units remain KayKit ticks. Building silhouettes stay inside the
  locked AABB.

### What did move vs GFX-E (same cameras)

- Day sat 0.95 → 1.10, exposure 0.90 → 0.78, ambient 0.45 → 0.25,
  sun 0.95 → 1.20 `#FFF0DE`, Filmic white 6. Recommended is 4 PSSM
  splits.
- Meadow `#536B3E` / sunlit `#72884D`. Beach / water / horizon lost
  the peach/teal void. Off-map fog alpha is opaque `#17262A`.
- OpeningDress: forest frame, rock landmark, worn path. Wheat gold
  `#C9A24A`.
- Night moon 0.18 / ambient 0.16 / exposure 0.67. Windows `#F5B36B`.

### GPU_SHOTS

A normal Windows export with `SNS_GFX_SHOTS=<dir>` writes the same
cameras at 1920×1080, pauses, and quits. Isolate `user://` with a temp
`APPDATA` / `LOCALAPPDATA` or `XDG_DATA_HOME`. See
`docs/gfx/GPU_SHOTS.md`. That is the path for a 4070 GFX-F pass.

CSV committed at `docs/gfx/gfx_f_playtest.csv`.
