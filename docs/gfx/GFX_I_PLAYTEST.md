# GFX-I self-playtest notes

Harness: `tests/t_gfx_i_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe. Seed = `DEFAULT_SEED` (260821). `SNS_PLAYTEST_LOG=1` also
wrote `artifacts/gfx_i/playtest/dpm.csv`.

CSV: `docs/gfx/gfx_i_playtest.csv`  
Comparison cameras: `tests/t_gfx_i_shots.gd` → `artifacts/gfx_i/after/`.  
CONCEPT vs NOW / GFX-H vs GFX-I:
`/opt/cursor/artifacts/gfx-i/concept_vs_now_*.png` and
`gfxh_vs_gfxi_*.png`.

Master bus stayed `1.000`. Numbers below are filled after the harness
run on this machine.

## Script

1. Stamp the deterministic ~15-building showcase, shoot zoom 26 and 42.
2. Fresh opening hamlet + ridge / creek on the same seed at the closer default.
3. Spawn / select a free patrol guard and issue Scout (Y) toward the
   western fog.
4. Force night, spawn two raiders, capture the RAID banner.
5. Return to **day** and pull back to the fog edge (zoom 68).

No scout / guard / raider outline files were touched.

## Frame / wait times (lavapipe, not a 4070)

Filled after `t_gfx_i_playtest`.

## Perf guard

Filled after `t_gfx_e_perf`.

## Tests

Filled after the suite.
