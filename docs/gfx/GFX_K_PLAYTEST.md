# GFX-K self-playtest notes

Harness: `tests/t_gfx_k_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe. Seed = `DEFAULT_SEED` (260821). `SNS_PLAYTEST_LOG=1` also
wrote `artifacts/gfx_k/playtest/dpm.csv`.

CSV: `docs/gfx/gfx_k_playtest.csv`  
Comparison cameras: `tests/t_gfx_k_shots.gd` → `artifacts/gfx_k/after/`.  
CONCEPT vs NOW / GFX-J vs GFX-K:
    `/opt/cursor/artifacts/gfx-k/concept_vs_now_*.png` and
`gfxj_vs_gfxk_*.png`.

Master bus stayed `1.000`. Scout result:
`Astrid scouts toward the fog.` Showcase buildings / roads: **15 / 37**.

Stacked on GFX-J (`76fdc32`, PR #67, self-score **6.6/10**, approved
baseline, **no reverts**). Day grade knobs (sat 1.12 / contrast 1.12 /
exposure 0.86) were not retuned. Item 8 lighting A/B
(`#FFE9D3` / 1.08 / ambient 0.30 / SSAO 0.60) was evaluated and
**rolled back** — same-camera lavapipe delta was marginal and the
exact sun / ambient / SSAO gates would have broken.

W = Town Hall 4×4 = **10.0 m**. R = cell × 0.97 = **2.425 m**.

## Script

1. Stamp the deterministic ~15-building showcase, shoot zoom 26 and 39.
2. Fresh opening hamlet + ridge / creek on the same seed, camera on
   `opening_camera_focus()` (~53% / 56%).
3. Spawn / select a free patrol guard and issue Scout (Y) toward the
   western fog. Result: `Astrid scouts toward the fog.`
4. Force night, spawn two raiders, capture the RAID banner.
5. Return to **day** and pull back to the **1.5× zoom cap** (39).

No scout / guard / raider outline files were touched.

## Per-item (plan order, timeboxes)

| item | budget | spent | result | notes |
| --- | ---: | ---: | --- | --- |
| 1 Fog / boundary | 7 | 7 | **Pass** | Explored 0.55, noise 0.12 (≤0.15 cell), missing mask = unexplored, BG `#17272A`. No triangular AABB cut. |
| 2 Architecture hierarchy | 13 | 13 | **Pass** | Limestone `#CBBCA0`, plaster `#E0CDA9`, timber `#62432F`, slate `#426C67`. Pilasters, two bands, house beams / shutters / chimney, workshop awning. |
| 3 Opening landmark | 8 | 8 | **Pass** | Ridge 1.8W × 0.35W, creek 0.18W `#37646A`, 6–10 bevelled rocks, camera on hall + (−0.12W, 0, 0.18W). |
| 4 Worn medieval paths | 12 | 12 | **Pass** | Centre `#9F8260`, shoulders, ruts ±0.22R, gravel. Routing unchanged. |
| 5 Three-scale ground | 12 | 12 | **Pass** | Broad 3.0R (floored 8.0 m), medium 0.8R (floored 1.94 m), meadow `#60764A`. Clusters 12–18 / 100 R². |
| 6 Woodland edge | 9 | 9 | **Pass** | 55 / 25 / 20 mix, height bands, understory ~1.2W. |
| 7 Settlement dressing | 11 | 11 | **Pass** | Notice board + civic flag, house woodpile, extra lumber stacks. Deterministic. |
| 8 Selective lighting A/B | 8 | 8 | **Rolled back** | `#FFE9D3` / 1.08 / 0.30 / 0.60 not kept. Grade knobs untouched. |
| QA / rollback reserve | 10 | 10 | **Pass** | Tests + export + Master + composites. |

Sprint wall ~90 minutes of the timeboxed work. QA follow-up after the
first suite widened `t_gfx_e` (`patch_metres >= 1.80`) and `t_gfx_h`
(road `#9F8260`) and floored live/shader macro to 8.0 so `t_gfx_light`
stays green. Those are gate alignments, not a ninth visual item.

## Frame / wait times (lavapipe, not a 4070)

| event | wait_ms | frame_ms | night | notes |
| --- | ---: | ---: | ---: | --- |
| showcase_day | 5616 | 334.7 | 0 | 15 buildings + 37 roads, limestone hierarchy |
| showcase_wide | 4460 | 369.6 | 0 | 1.5× cap (39) |
| opening_day | 3402 | 220.1 | 0 | hall + ridge / creek in frame |
| scout_day | 3079 | 225.7 | 0 | scout order live |
| night_raid | 2338 | 187.6 | 1 | moonlit blue, screen shroud |
| fog_edge | 3101 | 269.2 | 0 | zoom 39, **day**, no triangular cut |

`wait_ms` is wall time for 12 process frames + one `frame_post_draw`.
`frame_ms` is `Performance.TIME_PROCESS` on software Vulkan.

## Perf guard (same machine)

| step | GFX-J lavapipe | lavapipe GFX-K |
| --- | ---: | ---: |
| `start_new_3d` | 451 ms | **461 ms** |
| showcase `_sync_presentation` | 529 ms | **527 ms** |
| first frame after showcase | 2085 ms | **2103 ms** |

`T_GFX_E_PERF` PASS. Start stays inside 2× GFX-D (1000 ms). First
frame is ~2.1 s on this lavapipe run (screen-composited shroud).
Playtest frames after warmup are 188–370 ms.

## Tests

| test | result |
| --- | --- |
| `t_gfx_k` | PASS |
| `t_gfx_k_playtest` | PASS |
| `t_gfx_k_shots` | PASS |
| `t_gfx_j` | PASS (gates widened for K colors / roughness / explored 0.55) |
| `t_gfx_i` | PASS |
| `t_gfx_h` | PASS (road `#9F8260` accepted) |
| `t_gfx_g` | PASS |
| `t_gfx_f` | PASS |
| `t_gfx_e` | PASS (`patch_metres >= 1.80`) |
| `t_gfx_e_perf` | PASS |
| `t_gfx_d` | PASS |
| `t_gfx_light` | PASS (macro floored 8.0) |
| `t_gfx_b` | PASS |
| `t_gfx_c` | PASS |
| `t_gfx_perf` | PASS (`GFX_PERF_DONE`) |
| `opening_style_models` | PASS |
| `phase4_2_parse_smoke` | PASS |
| `audit_export_packing.py` | PASS (`MISSING FROM EXPORT: 0`) |

## 3D-area metrics (HUD cropped, lavapipe)

`luma / luma_std / sat / hue`

| shot | CONCEPT | GFX-J | GFX-K |
| --- | --- | --- | --- |
| opening_day | 75.0 / 50.6 / 0.501 / 97° | 62.0 / 46.2 / 0.517 / 98° | 62.1 / 46.3 / 0.484 / 105° |
| showcase_day | 73.9 / 49.4 / 0.500 / 100° | 67.4 / 46.4 / 0.529 / 87° | 70.9 / 48.1 / 0.507 / 88° |
| showcase_wide | 75.0 / 50.6 / 0.501 / 97° | 67.9 / 43.7 / 0.503 / 111° | 70.9 / 44.5 / 0.484 / 113° |
| fog_edge | — | 64.2 / 44.4 / 0.488 / 122° | 65.5 / 43.8 / 0.463 / 128° |
| night_raid | — | 41.6 / 26.3 / 0.311 / 141° | 43.1 / 26.3 / 0.325 / 152° |

Hue was not retuned. Opening luma is unchanged vs J; showcase reads a
touch brighter because limestone / plaster / meadow floors lifted the
midtones. Saturation dropped slightly toward the concept, not by a
grade tweak.

## Strict self-score

**6.7 / 10** on lavapipe. ChatGPT hoped 7.3–7.7 if J's systems paid
off. I am not calling 7. Against `concept_1.png` the board is still
KayKit boxes on a flatter meadow: roads have ruts in the shader, the
opening camera now holds ridge rocks and a creek, the hall is pale
limestone with pilasters / bands, and the shroud stays a consistent
`#17272A` at the 1.5× cap. That is a half-step from J's 6.6, not a
7.5 read. A 4070 shot may add a quarter-step of shadow depth. Do not
merge on this score.

## Eight acceptance tests

| test | lavapipe |
| --- | --- |
| 1 Screen shroud, BG `#17272A`, alpha 1.0 / 0.55 / 0.0, 1.25-cell feather, ≤0.15-cell noise | Pass — no triangular AABB cut, no turquoise leak |
| 2 Landmark limestone `#CBBCA0` + teal slate, three archetypes | Pass — hall is pale; houses / workshops carry timber / awning |
| 3 Opening hall + ridge + creek in the first frame | Pass — rock mass and creek sit in the opening lawn |
| 4 Worn roads `#9F8260` with shoulders / ruts / gravel | Pass — routing unchanged; not a uniform ribbon |
| 5 Three-scale ground, meadow `#60764A`, no GFX-D lime | Pass — structure in shader / clumps; still flatter than the concept |
| 6 Woodland 55 / 25 / 20 + 1.2W understory | Pass — mix and height bands are in; silhouette is still simple |
| 7 Settlement dressing on hall / house / lumber | Pass — notice board, flag, woodpile, extra stacks |
| 8 Lighting A/B visibly better | **Rolled back** — marginal lavapipe delta |
