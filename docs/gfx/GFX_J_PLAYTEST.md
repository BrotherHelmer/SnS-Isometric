# GFX-J self-playtest notes

Harness: `tests/t_gfx_j_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe. Seed = `DEFAULT_SEED` (260821). `SNS_PLAYTEST_LOG=1` also
wrote `artifacts/gfx_j/playtest/dpm.csv`.

CSV: `docs/gfx/gfx_j_playtest.csv`  
Comparison cameras: `tests/t_gfx_j_shots.gd` → `artifacts/gfx_j/after/`.  
CONCEPT vs NOW / GFX-I vs GFX-J:
    `/opt/cursor/artifacts/gfx-j/concept_vs_now_*.png` and
`gfxi_vs_gfxj_*.png`.

Master bus stayed `1.000`. Numbers below are filled after the harness
run on this machine.

## Script

1. Stamp the deterministic ~15-building showcase, shoot zoom 26 and 39.
2. Fresh opening hamlet + ridge / creek on the same seed at the closer default.
3. Spawn / select a free patrol guard and issue Scout (Y) toward the
   western fog.
4. Force night, spawn two raiders, capture the RAID banner.
5. Return to **day** and pull back to the 1.5× zoom cap.

No scout / guard / raider outline files were touched.

## Frame / wait times (lavapipe, not a 4070)

Filled after `t_gfx_j_playtest`.

## Perf guard

Filled after `t_gfx_e_perf`.

## Tests

Filled after the suite.
