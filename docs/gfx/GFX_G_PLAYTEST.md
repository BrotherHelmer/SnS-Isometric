# GFX-G self-playtest notes

Harness: `tests/t_gfx_g_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe. Seed = `DEFAULT_SEED` (260821). `SNS_PLAYTEST_LOG=1` also
wrote `artifacts/gfx_g/playtest/dpm.csv`.

CSV: `docs/gfx/gfx_g_playtest.csv`  
Comparison cameras: `tests/t_gfx_g_shots.gd` → `artifacts/gfx_g/after/`.  
CONCEPT vs NOW / GFX-F vs GFX-G:
`/opt/cursor/artifacts/gfx-g/concept_vs_now_*.png` and
`gfxf_vs_gfxg_*.png`.

Master bus stayed `1.000`. Scout result expected:
`Astrid scouts toward the fog.`

An RTX 4070 capture of GFX-F (`3386cbd`) measured night luma **17.9**
(unplayable), wide/opening hue **102° / 111°** (cool olive-teal), sat
~0.33–0.37 vs concept 0.48, contrast std 31–39 vs 47. This pass lifts
moonlight, warms the meadow, dresses the opening as a hamlet, and
dissolves the diamond map edge into the wilderness shroud.

## Script

1. Stamp the deterministic ~15-building showcase, shoot zoom 26 and 42.
2. Fresh opening hamlet on the same seed (no showcase) at the closer default.
3. Spawn / select a free patrol guard and issue Scout (Y) toward the
   western fog. Result: `Astrid scouts toward the fog.`
4. Force night, spawn two raiders, capture the RAID banner.
5. Return to **day** and pull back to the fog edge (zoom 68).

No scout / guard / raider outline files were touched.

## Frame / wait times

Filled after the lavapipe harness run.

## Tests

Filled after the harness run.

## 4070 GFX-F baseline (this branch starts from)

| shot | luma / std / sat / hue |
| --- | --- |
| showcase_day | 88.7 / 31.7 / 0.35 / 68° |
| showcase_wide | 75.2 / 38.4 / 0.37 / 102° |
| opening_day | 77.7 / 39.5 / 0.33 / 111° |
| night_raid | 17.9 / 10.0 / 0.34 / 183° |
| fog_edge | 87.3 / 33.6 / 0.28 / 153° |

## Score vs `concept_1.png`

Pending lavapipe composites. Target **6.5+ / 10**.

CSV committed at `docs/gfx/gfx_g_playtest.csv`.
