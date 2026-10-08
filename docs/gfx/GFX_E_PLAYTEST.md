# GFX-E self-playtest notes

Harness: `tests/t_gfx_e_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe. Seed = `DEFAULT_SEED` (260821). `SNS_PLAYTEST_LOG=1` also
wrote `artifacts/gfx_e/playtest/dpm.csv`.

CSV: `/workspace/artifacts/gfx_e/playtest/gfx_e_playtest.csv`  
Copy: `/opt/cursor/artifacts/gfx-e/playtest/gfx_e_playtest.csv`

Comparison cameras: `tests/t_gfx_e_shots.gd` → `artifacts/gfx_e/after/`.  
CONCEPT vs NOW: `/opt/cursor/artifacts/gfx-e/concept_vs_now_showcase_wide.png`
and `concept_vs_now_opening_day.png`.

Master bus stayed `1.000`. Scout result:
`Astrid scouts toward the fog.`

An RTX 4070 capture of GFX-D (#61) is only ~2–3% brighter than
lavapipe, same sat, same yellow-green. These notes treat the yellow as
real content. This pass neutralized the grade; lavapipe remains a
faithful-but-softer stand-in for hardware.

## Script

1. Stamp the deterministic ~15-building showcase, shoot zoom 26 and 42.
2. Fresh opening day on the same seed (no showcase) at the closer default.
3. Spawn / select a free patrol guard and issue Scout (Y) toward the
   western fog. Result: `Astrid scouts toward the fog.`
4. Force night, spawn two raiders, capture the RAID banner.
5. Return to **day** and pull back to the fog edge (zoom 68). GFX-D
   left this shot at night.

No scout / guard / raider outline files from PR #58 were touched.

## Frame / wait times (lavapipe, not a 4070)

| event | wait_ms | frame_ms | night | notes |
| --- | ---: | ---: | ---: | --- |
| showcase_day | 12209 | 566.1 | 0 | 15 buildings + 37 roads, zoom 26 |
| showcase_wide | 6488 | 583.6 | 0 | zoom 42, forest rim in frame |
| opening_day | 5338 | 412.9 | 0 | normal founding, zoom 26 |
| scout_day | 7198 | 360.7 | 0 | scout order live |
| night_raid | 4501 | 330.2 | 1 | SSAO off (night cheap-path) |
| fog_edge | 4315 | 379.0 | 0 | zoom 68, **day** |

`wait_ms` is wall time for 12 process frames + one `frame_post_draw`.
`frame_ms` is `Performance.TIME_PROCESS` on software Vulkan. Recommended
still keeps glow off and 2 shadow splits.

## Tests

| test | result |
| --- | --- |
| `t_gfx_e` | PASS |
| `t_gfx_e_playtest` | PASS |
| `t_gfx_e_shots` | PASS |
| `t_gfx_d` | PASS (needs ~4 min on lavapipe after showcase sync) |
| `t_gfx_light` | PASS |
| `t_gfx_b` | PASS |
| `t_gfx_c` | PASS |
| `t_gfx_perf` | PASS (`GFX_PERF_DONE`) |
| `opening_style_models` | PASS |
| `phase4_2_parse_smoke` | PASS |
| `audit_export_packing.py` | PASS (`MISSING FROM EXPORT: 0`) |

`export_files` now lists birch / fir_tall / oak / spruce / flowers /
farm / fir_lod / broadleaf_lod. The audit scans code-referenced model
paths, so a stale TREES list cannot hide another #61 export 404.

## Score vs `concept_1.png`

**5.5 / 10.** Target was 6 / 10. GFX-D was 4.5–5 / 10.

The yellow-green grade is gone. Meadow reads olive (`#657A49` family),
not banana. That was the 4070 fact and it shows on lavapipe. The
showcase still composes as a civic keep + terracotta houses + wheat
block + forest rim. I will not mark 6 while dirt roads, occupation
aprons and directional shadows fail to separate in these Forward+
software shots, and opening day is still one civic cottage.

### Why not 6

- Opening day is still one hall on a founding apron. The concept is a
  finished hamlet with worn paths, yards and a pale multi-tower castle.
- Occupation splat and roads are authored (softer chew, `#A3865F`) but
  lavapipe Forward+ still flattens them into one olive plane.
- Grass clumps exist as a 4-blade tuft and no longer use the tree
  trunk shader, but they do not read at zoom 26 on these frames.
- Long shadows / warm-cool contrast stay weak on llvmpipe. Bias and
  opacity are set; hardware has to prove them.
- Units remain KayKit ticks. Building silhouettes stay inside the
  locked AABB.

### What did move vs GFX-D (same cameras)

- Day sat 1.08 → 0.95, exposure 0.90, white ground tint. The 4070
  over-yellow is treated as real and is no longer stacked on top of a
  warm meadow hash.
- Per-tile meadow hue is gone (that was the isometric checkerboard).
  Vertex colour is occupation only.
- Forest kit is clustered ~55/30/15 with dark conifers and
  fir_tall / spruce / birch / oak / LOD. Edge-forest shadows stay on.
- `fog_edge` is daytime.
- Clean export should no longer 404 birch / fir_tall / oak / spruce /
  flowers / farm / fir_lod / broadleaf_lod.

### GPU_SHOTS

A normal Windows export with `SNS_GFX_SHOTS=<dir>` writes the same
cameras at 1920×1080, pauses, and quits. Godot ignores `--user-data-dir`;
isolate `user://` with a temp `APPDATA` / `LOCALAPPDATA` (Windows) or
`XDG_DATA_HOME` (Linux). Pass `--position -10000,-10000` so the window
never appears. See `docs/gfx/GPU_SHOTS.md`. That is the path for a
4070 GFX-E pass.

CSV committed at `docs/gfx/gfx_e_playtest.csv`.
