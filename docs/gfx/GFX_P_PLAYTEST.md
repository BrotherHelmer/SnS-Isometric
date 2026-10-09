# GFX-P self-playtest notes

Harness: `tests/t_gfx_p_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe. Seed = `DEFAULT_SEED` (260821). Covers the first **15 game
minutes** (opening, build, scout, first night, raid).
`SNS_PLAYTEST_LOG=1` also wrote `artifacts/gfx_p/playtest/dpm.csv`.

CSV: `docs/gfx/gfx_p_playtest.csv`  
Comparison cameras: `tests/t_gfx_p_shots.gd` → `artifacts/gfx_p/after/`.  
CONCEPT vs NOW / GFX-O vs GFX-P:
    `/opt/cursor/artifacts/gfx-p/concept_vs_now_*.png` and
`gfxo_vs_gfp_*.png`.

Master bus, timings, and per-item results are filled after the
live run on this machine.

Stacked on GFX-O (`8870238`, PR #72, ChatGPT **7.0/10**). Day grade
and night stay **frozen**. Occupancy mask, distance-field roads,
KayKit meshes, meadow baseline, forest, and fog stay.

W = Town Hall 4×4 = **10.0 m**. R = cell × 0.97 = **2.425 m**.
H = house visual height ≈ **4.09 m**.
