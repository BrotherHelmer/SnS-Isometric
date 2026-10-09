# GFX-L self-playtest notes

Harness: `tests/t_gfx_l_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe. Seed = `DEFAULT_SEED` (260821). Covers the first **15 game
minutes** (opening, build, scout, first night, raid).

CSV: `docs/gfx/gfx_l_playtest.csv`  
Comparison cameras: `tests/t_gfx_l_shots.gd` → `artifacts/gfx_l/after/`.  
CONCEPT vs NOW / GFX-K vs GFX-L:
    `/opt/cursor/artifacts/gfx-l/concept_vs_now_*.png` and
`gfxk_vs_gfxl_*.png`.

Stacked on GFX-K (`b8d7f9f`, ChatGPT **6.7/10**). Day grade knobs were
not retuned. K fog / forest / wheat / trim / night stay.

Timings, Master, export, and the strict score are filled after the live
harness.
