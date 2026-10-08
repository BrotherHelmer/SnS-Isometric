# GFX-F self-playtest notes

Harness: `tests/t_gfx_f_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe. Seed = `DEFAULT_SEED` (260821). `SNS_PLAYTEST_LOG=1` also
writes `artifacts/gfx_f/playtest/dpm.csv`.

CSV: `docs/gfx/gfx_f_playtest.csv`  
Comparison cameras: `tests/t_gfx_f_shots.gd` → `artifacts/gfx_f/after/`.

Master bus stays `1.000`. Scout result expected:
`Astrid scouts toward the fog.`

An RTX 4070 capture of GFX-E (`5419e50`) measured 3D-area sat ~0.30
vs concept 0.48, luma 113–125 vs 85, contrast std 34–37 vs 47. Night
was luma 91.6 / hue 177°. This pass applies ChatGPT's Filmic 0.78 /
sat 1.10 / ambient 0.25 / moon 0.18 preset and recomposes the
opening. Lavapipe remains a faithful-but-softer stand-in for hardware.

## Script

1. Stamp the deterministic ~15-building showcase, shoot zoom 26 and 42.
2. Fresh opening day on the same seed (no showcase) at the closer default.
3. Spawn / select a free patrol guard and issue Scout (Y) toward the
   western fog.
4. Force night, spawn two raiders, capture the RAID banner.
5. Return to **day** and pull back to the fog edge (zoom 68).

No scout / guard / raider outline files were touched.

## Frame / wait times

Filled after the harness run. `wait_ms` is wall time for 12 process
frames + one `frame_post_draw`. `frame_ms` is `Performance.TIME_PROCESS`
on software Vulkan.

## Tests

| test | result |
| --- | --- |
| `t_gfx_f` | pending |
| `t_gfx_f_playtest` | pending |
| `t_gfx_f_shots` | pending |
| `t_gfx_e` | pending |
| `t_gfx_e_perf` | pending |
| `t_gfx_d` | pending |
| `t_gfx_light` | pending |
| `t_gfx_b` | pending |
| `t_gfx_c` | pending |
| `t_gfx_perf` | pending |
| `opening_style_models` | pending |
| `phase4_2_parse_smoke` | pending |
| `audit_export_packing.py` | pending |

## Score vs `concept_1.png`

Pending lavapipe shots. Target **6.5 / 10**. ChatGPT + 4070 scored
GFX-E **5.0 / 10**.
