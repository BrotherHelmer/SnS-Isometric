# GFX-M self-playtest notes

Harness: `tests/t_gfx_m_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe. Seed = `DEFAULT_SEED` (260821). Covers the first **15 game
minutes** (opening, build, scout, first night, raid).

CSV: `docs/gfx/gfx_m_playtest.csv`  
Comparison cameras: `tests/t_gfx_m_shots.gd` → `artifacts/gfx_m/after/`.  
CONCEPT vs NOW / GFX-L vs GFX-M:
    `/opt/cursor/artifacts/gfx-m/concept_vs_now_*.png` and
`gfxl_vs_gfxm_*.png`.

Stacked on GFX-L (`a21f0d4`, ChatGPT **6.7/10**). Day grade knobs were
not retuned. L/K fog / forest / wheat / night stay.

Timings, Master, export, and the strict score are filled after the live
harness.
