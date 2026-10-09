# GFX-H self-playtest notes

Harness: `tests/t_gfx_h_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe. Seed = `DEFAULT_SEED` (260821). `SNS_PLAYTEST_LOG=1` also
wrote `artifacts/gfx_h/playtest/dpm.csv`.

CSV: `docs/gfx/gfx_h_playtest.csv`  
Comparison cameras: `tests/t_gfx_h_shots.gd` → `artifacts/gfx_h/after/`.  
CONCEPT vs NOW / GFX-G vs GFX-H:
`/opt/cursor/artifacts/gfx-h/concept_vs_now_*.png` and
`gfxg_vs_gfxh_*.png`.

Master bus stayed `1.000`. Scout result:
`Astrid scouts toward the fog.` Showcase roads: **37**.

An RTX 4070 capture of GFX-G (`1a361fb`) measured opening
**81 / 44.9 / 0.46 / 71°**. Day knobs (sat 1.12 / contrast 1.12 /
exposure 0.86 / meadow `#68743A`) were not retuned. This pass targets
the four gaps: ground, roads/crops, world edge, shadows, and a blue
night at luma ~50.

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
| showcase_day | 11334 | 497.4 | 0 | 15 buildings + 37 roads, zoom 26 |
| showcase_wide | 6116 | 523.4 | 0 | zoom 42 |
| opening_day | 5771 | 416.9 | 0 | hamlet + pond + crop rows |
| scout_day | 7341 | 385.4 | 0 | scout order live |
| night_raid | 4646 | 336.2 | 1 | moon 0.42 / ambient 0.30 / blue tint |
| fog_edge | 4231 | 372.0 | 0 | zoom 68, **day** |

`wait_ms` is wall time for 12 process frames + one `frame_post_draw`.
`frame_ms` is `Performance.TIME_PROCESS` on software Vulkan.

## Perf guard (same machine)

| step | GFX-G lavapipe | lavapipe GFX-H |
| --- | ---: | ---: |
| `start_new_3d` | 414 ms | **421 ms** |
| showcase `_sync_presentation` | 467 ms | **471 ms** |
| first frame after showcase | 1583 ms | **5713 ms** |

`T_GFX_E_PERF` PASS (not the 112 s remesh). Start and sync stay at the
GFX-G GDScript cost. The first-frame number on lavapipe is shader-bound
(denser wheat / rim woodland / ground shader). 4070 GFX-F/G first frame
was 0.5 s; this pass does not reintroduce the occupation remesh. Playtest
frames after warmup are 336–523 ms.

## Tests

| test | result |
| --- | --- |
| `t_gfx_h` | PASS |
| `t_gfx_h_playtest` | PASS |
| `t_gfx_h_shots` | PASS |
| `t_gfx_g` | PASS |
| `t_gfx_f` | PASS |
| `t_gfx_e` | PASS |
| `t_gfx_e_perf` | PASS |
| `t_gfx_d` | PASS |
| `t_gfx_light` | PASS (SSAO radius gate widened to 0.35–1.20) |
| `t_gfx_b` | PASS |
| `t_gfx_c` | PASS |
| `t_gfx_perf` | PASS (`GFX_PERF_DONE`) |
| `opening_style_models` | PASS |
| `phase4_2_parse_smoke` | PASS |
| `audit_export_packing.py` | PASS (`MISSING FROM EXPORT: 0`) |

## Lavapipe 3D-area metrics (HUD cropped)

Luma / contrast std are display Y′ × 255, same scale as GFX-G notes.
Concept (left of the composite): ChatGPT + 4070 concept
84.8 / 47.3 / 0.48 / 66°.

| shot | GFX-G 4070 | GFX-G lavapipe | GFX-H lavapipe |
| --- | --- | --- | --- |
| showcase_day | 88.7 / 31.7 / 0.35 / 68° | 76.7 / 40.3 / 0.498 / 61° | **79.8 / 37.2 / 0.418 / 72°** |
| showcase_wide | 75.2 / 38.4 / 0.37 / 102° | 71.2 / 40.5 / 0.443 / 88° | 78.0 / 36.2 / 0.377 / 121° |
| opening_day | **81 / 44.9 / 0.46 / 71°** | 78.3 / 42.9 / 0.486 / 71° | **78.0 / 38.5 / 0.405 / 93°** |
| night_raid | 17.9 (GFX-F) / G ~50 | 51.3 / 19.0 / 0.247 / 124° | **53.3 / 18.4 / 0.214 / 159°** |
| fog_edge | 87.3 / 33.6 / 0.28 / 153° | 103.1 / 42.2 / 0.296 / 152° | 97.2 / 34.4 / 0.319 / 191° |

Opening luma held (78.0 vs 78.3). Hardware day should still sit near
81. Night stays in the 45–60 band (53) and the hue left the olive-green
hole (124° → 159° cyan-blue). Showcase wheat rows are the clearest
camera read vs GFX-G.

## Score vs `concept_1.png`

**6.7 / 10** on lavapipe. I will not mark **7**. Lavapipe has scored
about 1 point above the 4070 every round; 6.7 here is about **5.7** on
the 4070. Target was 7 only if lavapipe showed ~7.5+.

### Why not 7

- Opening sat slipped 0.486 → 0.405 and hue 71° → 93°. Luma held; the
  extra forest / tufts greened the frame.
- The meadow is no longer a perfect olive sheet (dirt lanes, gold
  wheat on the showcase farm) but lavapipe still flattens the
  world-space breakup. Roads are packed clay and 37 of them stamp;
  they are readable as lighter dirt, not as the concept's worn tracks.
- `fog_edge` is still a rounded island in the shroud. Rim woodland and
  a stronger veil help; the AABB cut remains.
- Building shadows stay soft on software Vulkan. SSAO radius 0.42
  removed the large smear; form shading is bevel-only.
- Night is cooler and playable (luma 53) but window pools are still
  small warm dots, not large fire hearths.
- Units remain KayKit ticks. Building silhouettes stay inside the
  locked AABB.

### What did move vs GFX-G (same cameras)

- Ground shader: dirt 0.48 → 0.56, flowers, pebbles, tuft striping,
  crop furrows. Occupation splat keeps more of the road / wheat colour.
- Roads: `#C8A064` raised to 0.088 m, wider 1.52. Showcase still
  stamps 37.
- Farm halo doubled; showcase wheat reads as a gold field at zoom 26.
- Opening dress: crop rows, extra fences, millpond.
- Seven off-map rings + on-map rim woodland. Fog veil 1.5–42 m.
- SSAO radius 0.75 → 0.42, contact-AO 0.48 → 0.24, blur 0.32.
- Night moon `#A8B8D4`, ambient `#4A5E80`, ground tint cool blue.
  Luma 51 → 53, hue 124° → 159°.

### GPU_SHOTS

A normal Windows export with `SNS_GFX_SHOTS=<dir>` writes the same
cameras at 1920×1080, pauses, and quits. Isolate `user://` with a temp
`APPDATA` / `LOCALAPPDATA` or `XDG_DATA_HOME`. See
`docs/gfx/GPU_SHOTS.md`. That is the path for a 4070 GFX-H pass.

CSV committed at `docs/gfx/gfx_h_playtest.csv`.
