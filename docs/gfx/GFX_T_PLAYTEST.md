# GFX-T self-playtest notes

Harness: `tests/t_gfx_t_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe (no `--headless` — that path uses the dummy renderer and never
presents a 1280×720 frame). Seed = `DEFAULT_SEED` (260821). Covers the
first **15 game minutes** (opening, build, scout, first night, raid).

CSV: `docs/gfx/gfx_t_playtest.csv`
Comparison cameras: `tests/t_gfx_t_shots.gd` → `artifacts/gfx_t/after/`.
CONCEPT vs NOW / GFX-S vs GFX-T:
    `/opt/cursor/artifacts/gfx-t/concept_vs_now_*.png` and
`gfxs_vs_gfxt_*.png`. Same GFX-S / GFX-R / GFX-Q / GFX-P gameplay
cameras at 1280×720.

Stacked on GFX-S (`5533a7b`, PR #76, ChatGPT **8.0/10**). Day grade
knobs stay **frozen**. Night stays frozen. Day *light* is the T
refinement (sun `#FFD2A0` 1.10 at 30°, ambient `#A8A088` 0.40, fill
`#C8B488`).

Results will be filled after the 15-minute run.
