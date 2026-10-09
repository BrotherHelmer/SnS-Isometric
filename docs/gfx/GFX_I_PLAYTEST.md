# GFX-I self-playtest notes

Harness: `tests/t_gfx_i_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe. Seed = `DEFAULT_SEED` (260821). `SNS_PLAYTEST_LOG=1` also
wrote `artifacts/gfx_i/playtest/dpm.csv`.

CSV: `docs/gfx/gfx_i_playtest.csv`  
Comparison cameras: `tests/t_gfx_i_shots.gd` → `artifacts/gfx_i/after/`.  
CONCEPT vs NOW / GFX-H vs GFX-I:
    `/opt/cursor/artifacts/gfx-i/concept_vs_now_*.png` and
`gfxh_vs_gfxi_*.png`.

Master bus stayed `1.000`. Scout result:
`Astrid scouts toward the fog.` Showcase roads: **37**.

Stacked on GFX-H (`58ae447`, ChatGPT **6.0/10**, agent H self-score
6.7 lavapipe / ~5.7 4070). Day grade knobs (sat 1.12 / contrast 1.12 /
exposure 0.86) were not retuned. This pass reverts only the GFX-H
haze, then adds a world-space shroud, local lighting, chunked ground
clumps, building trim, and an opening ridge / creek.

## Script

1. Stamp the deterministic ~15-building showcase, shoot zoom 26 and 42.
2. Fresh opening hamlet + ridge / creek on the same seed at the closer default.
3. Spawn / select a free patrol guard and issue Scout (Y) toward the
   western fog. Result: `Astrid scouts toward the fog.`
4. Force night, spawn two raiders, capture the RAID banner.
5. Return to **day** and pull back to the fog edge (zoom 68).

No scout / guard / raider outline files were touched.

## Frame / wait times (lavapipe, not a 4070)

| event | wait_ms | frame_ms | night | notes |
| --- | ---: | ---: | ---: | --- |
| showcase_day | 6578 | 417.0 | 0 | 15 buildings + 37 roads, zoom 26 |
| showcase_wide | 5472 | 457.2 | 0 | zoom 42 |
| opening_day | 4660 | 337.1 | 0 | hamlet + ridge / creek |
| scout_day | 4065 | 305.9 | 0 | scout order live |
| night_raid | 3447 | 283.2 | 1 | moonlit blue, no haze |
| fog_edge | 3812 | 345.1 | 0 | zoom 68, **day**, `#17272A` shroud |

`wait_ms` is wall time for 12 process frames + one `frame_post_draw`.
`frame_ms` is `Performance.TIME_PROCESS` on software Vulkan.

## Perf guard (same machine)

| step | GFX-H lavapipe | lavapipe GFX-I |
| --- | ---: | ---: |
| `start_new_3d` | 421 ms | **450 ms** |
| showcase `_sync_presentation` | 471 ms | **514 ms** |
| first frame after showcase | 5713 ms | **1947 ms** |

`T_GFX_E_PERF` PASS. First frame is under 2 s on this lavapipe run
(haze / edge-veil work is gone; ground patches are chunked
MultiMeshes). Start and sync stay at the GFX-H GDScript cost. Playtest
frames after warmup are 283–457 ms. 4070 GFX-F/G first frame was 0.5 s;
this pass does not reintroduce the occupation remesh.

## Tests

| test | result |
| --- | --- |
| `t_gfx_i` | PASS |
| `t_gfx_i_playtest` | PASS |
| `t_gfx_i_shots` | PASS |
| `t_gfx_h` | PASS |
| `t_gfx_g` | PASS |
| `t_gfx_f` | PASS |
| `t_gfx_e` | PASS |
| `t_gfx_e_perf` | PASS |
| `t_gfx_d` | PASS |
| `t_gfx_light` | PASS (day sun/camera angle gate ≥ 85° after pitch −38) |
| `t_gfx_b` | PASS |
| `t_gfx_c` | PASS |
| `t_gfx_perf` | PASS (`GFX_PERF_DONE`) |
| `opening_style_models` | PASS |
| `phase4_2_parse_smoke` | PASS |
| `audit_export_packing.py` | PASS (`MISSING FROM EXPORT: 0`) |

## Lavapipe 3D-area metrics (HUD + chrome crop)

Luma / contrast std are display Y′ × 255. Crop is top 78 / bottom 168
so the dark chrome is out; same band as the GFX-H published opening
~78 / 38.5 / 0.405. Concept opening on this crop:
**84.0 / 48.4 / 0.484 / 67°** (ChatGPT + 4070 concept was
84.8 / 47.3 / 0.48 / 66°).

| shot | GFX-H lavapipe (this crop) | GFX-I lavapipe |
| --- | --- | --- |
| showcase_day | 78.0 / 39.3 / 0.422 / 76° | **78.6 / 46.5 / 0.563 / 60°** |
| showcase_wide | 75.8 / 38.0 / 0.386 / 119° | 68.3 / 44.4 / 0.524 / 86° |
| opening_day | 77.4 / 40.0 / 0.395 / 99° | **73.3 / 47.3 / 0.525 / 77°** |
| night_raid | 53.0 / 19.8 / 0.235 / 163° | **45.8 / 22.9 / 0.268 / 145°** |
| fog_edge | 97.6 / 34.3 / 0.317 / 188° | **81.3 / 32.8 / 0.448 / 165°** |

Opening sat and hue moved toward the concept (0.395 → 0.525 vs 0.484;
99° → 77° vs 67°). Contrast 40.0 → 47.3 vs concept 48.4. Luma dropped
a little (clumps + no haze wash). Fog-edge luma 97.6 → 81.3: the
island is no longer a grey soup. Night stays in the playable band
(45.8) and stays blue (145°), not olive.

## Score vs `concept_1.png`

**6.9 / 10** on lavapipe. I will not mark **7**. Lavapipe has scored
about 1 point above the 4070 every round; 6.9 here is about **5.9** on
the 4070. Target was 7 only if lavapipe showed ~7.5+.

### Why not 7

- The settlement is still KayKit mid-poly. Concept roofs, plaster
  wear, packed earth and dense housing are not here.
- Opening luma slipped 77.4 → 73.3. Sat / hue / contrast improved;
  the meadow is still a clean olive field with disk clumps, not the
  concept's broken dirt.
- The ridge / creek is dressed west of the millpond (tests see
  `DressRidge` / `DressCreek`) but the default opening camera keeps it
  mostly off-frame. It is not a first-read landmark.
- Town Hall luma is floored and trim is on, but the hall / castle
  still read dark next to the terracotta houses.
- `fog_edge` is a hard `#17272A` cut instead of haze. The revealed
  shape is still a rounded island. Off-map is opaque, which is the
  requested fix.
- Building shadows stay soft on software Vulkan. SSAO 0.55 / 1.10 and
  blur 1.0 are the new local-light preset; form shading is still
  bevel-heavy.
- Units remain KayKit ticks. Building silhouettes stay inside the
  locked AABB.

### What did move vs GFX-H (same cameras)

- Environment fog and the shader `edge_veil` are gone. FOW is a
  world-space shroud: visible 0, explored 0.55, unexplored 1.0,
  colour `#17272A`, irregular 1–2 cell feather.
- Day sun `#FFE8CE` at 1.10 and 38°, shadow_opacity 0.85, blur 1.0,
  ambient `#91A29A` at 0.32, SSAO radius 0.55 / intensity 1.10.
- Chunked 40 m MultiMesh ground disks (dark grass, soil, flowers,
  stones). Wheat / roads / occupation splat from H stay.
- Town Hall / house / bakery trim: plaster `#D6C5A2`, timber
  `#553C2B`, hall roof `#426863`, stone `#A39A85`. House roofs stay
  terracotta so `t_gfx_d` holds. Town Hall masonry has a luma floor.
- Opening DressRidge + DressCreek west of the millpond.
- Night stays moonlit blue; window pools still glow.

### GPU_SHOTS

A normal Windows export with `SNS_GFX_SHOTS=<dir>` writes the same
cameras at 1920×1080, pauses, and quits. Isolate `user://` with a temp
`APPDATA` / `LOCALAPPDATA` or `XDG_DATA_HOME`. See
`docs/gfx/GPU_SHOTS.md`. That is the path for a 4070 GFX-I pass.

CSV committed at `docs/gfx/gfx_i_playtest.csv`.
