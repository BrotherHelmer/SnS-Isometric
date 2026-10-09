# GFX-J self-playtest notes

Harness: `tests/t_gfx_j_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe. Seed = `DEFAULT_SEED` (260821). `SNS_PLAYTEST_LOG=1` also
wrote `artifacts/gfx_j/playtest/dpm.csv`.

CSV: `docs/gfx/gfx_j_playtest.csv`  
Comparison cameras: `tests/t_gfx_j_shots.gd` → `artifacts/gfx_j/after/`.  
CONCEPT vs NOW / GFX-I vs GFX-J:
    `/opt/cursor/artifacts/gfx-j/concept_vs_now_*.png` and
`gfxi_vs_gfxj_*.png`.

Master bus stayed `1.000`. Scout result:
`Astrid scouts toward the fog.` Showcase roads: **37**.

Stacked on GFX-I (`6d0ce8e`, ChatGPT **6.5/10**, approved baseline,
**no reverts**). Day grade knobs (sat 1.12 / contrast 1.12 /
exposure 0.86) were not retuned. This pass is the four finishing
tests only: screen shroud, limestone landmarks, organic meadow,
ridge / creek in the opening camera.

## Script

1. Stamp the deterministic ~15-building showcase, shoot zoom 26 and 39.
2. Fresh opening hamlet + ridge / creek on the same seed at the closer default.
3. Spawn / select a free patrol guard and issue Scout (Y) toward the
   western fog. Result: `Astrid scouts toward the fog.`
4. Force night, spawn two raiders, capture the RAID banner.
5. Return to **day** and pull back to the **1.5× zoom cap** (39).

No scout / guard / raider outline files were touched.

## Frame / wait times (lavapipe, not a 4070)

| event | wait_ms | frame_ms | night | notes |
| --- | ---: | ---: | ---: | --- |
| showcase_day | 5561 | 319.4 | 0 | 15 buildings + 37 roads, limestone hall |
| showcase_wide | 4438 | 386.5 | 0 | 1.5× cap (39) |
| opening_day | 3473 | 226.7 | 0 | pale hall + ridge / creek in frame |
| scout_day | 3128 | 226.0 | 0 | scout order live |
| night_raid | 2398 | 204.0 | 1 | moonlit blue, screen shroud |
| fog_edge | 2995 | 252.2 | 0 | zoom 39, **day**, no triangular cut |

`wait_ms` is wall time for 12 process frames + one `frame_post_draw`.
`frame_ms` is `Performance.TIME_PROCESS` on software Vulkan.

## Perf guard (same machine)

| step | GFX-I lavapipe | lavapipe GFX-J |
| --- | ---: | ---: |
| `start_new_3d` | 450 ms | **451 ms** |
| showcase `_sync_presentation` | 514 ms | **529 ms** |
| first frame after showcase | 1947 ms | **2085 ms** |

`T_GFX_E_PERF` PASS. Start stays inside 2× GFX-D (1000 ms). First
frame is ~2.1 s on this lavapipe run (screen-composited shroud).
Playtest frames after warmup are 204–387 ms.

## Tests

| test | result |
| --- | --- |
| `t_gfx_j` | PASS |
| `t_gfx_j_playtest` | PASS |
| `t_gfx_j_shots` | PASS |
| `t_gfx_i` | PASS (gates widened for J plaster / slate / explored 0.45) |
| `t_gfx_h` | PASS |
| `t_gfx_g` | PASS |
| `t_gfx_f` | PASS |
| `t_gfx_e` | PASS |
| `t_gfx_e_perf` | PASS |
| `t_gfx_d` | PASS |
| `t_gfx_light` | PASS (plaster roughness 0.80–0.85) |
| `t_gfx_b` | PASS |
| `t_gfx_c` | PASS |
| `t_gfx_perf` | PASS (`GFX_PERF_DONE`) |
| `opening_style_models` | PASS |
| `phase4_2_parse_smoke` | PASS |
| `audit_export_packing.py` | PASS (`MISSING FROM EXPORT: 0`) |

## 3D-area metrics (HUD cropped, lavapipe)

`luma / luma_std / sat / hue`

| shot | CONCEPT | GFX-I | GFX-J |
| --- | --- | --- | --- |
| opening_day | 75.5 / 50.7 / 0.501 / 78° | 66.8 / 48.0 / 0.513 / 87° | 61.0 / 45.3 / 0.519 / 90° |
| showcase_day | 72.4 / 50.3 / 0.505 / 87° | 71.3 / 48.0 / 0.545 / 69° | 66.9 / 45.9 / 0.529 / 75° |
| fog_edge | — | 73.6 / 37.6 / 0.449 / 170° | 63.9 / 43.9 / 0.489 / 121° |

Hue was not retuned. Fog-edge luma dropped because the 1.5× cap and
screen shroud no longer show a bright island in a pale void.

## Strict self-score

**6.6 / 10** on lavapipe. ChatGPT wanted ~7 after these four tests.
I am not calling 7. The hall is now pale limestone, the shroud no
longer prints a dark triangle, zoom cannot pull back onto a diamond
board, and a rock / creek mass sits in the opening camera. The meadow
is still flatter than the concept, the landmark is a simple limestone
box rather than carved masonry, and lavapipe does not show a 7.5+
read against `concept_1.png`. A 4070 shot may read a half-step higher.
Do not merge on this score.

## Four acceptance tests

| test | lavapipe |
| --- | --- |
| Screen shroud, BG `#17272A`, alpha 1.0 / 0.45 / 0.0, 1–1.5 cell feather, 1.5× zoom | Pass — no triangular AABB cut |
| Landmark limestone `#C5B69B` + teal slate roof | Pass — hall is pale, not dark teal |
| Meadow 1–3 road-width patches, 15–25% dark grass, 20–35% shoulders | Partial — structure is in the shader / clumps; still reads flat at zoom 26 |
| Ridge / creek 1.5–2 TH widths, `#B3A78A` / `#66685B` / `#315D66`, 5–10% of view | Pass — dark rock mass + creek in the opening lawn |
