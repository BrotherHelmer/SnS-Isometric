# GFX-K self-playtest notes

Harness: `tests/t_gfx_k_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe. Seed = `DEFAULT_SEED` (260821).

CSV: `docs/gfx/gfx_k_playtest.csv`  
Comparison cameras: `tests/t_gfx_k_shots.gd` → `artifacts/gfx_k/after/`.  
CONCEPT vs NOW / GFX-J vs GFX-K:
    `/opt/cursor/artifacts/gfx-k/concept_vs_now_*.png` and
`gfxj_vs_gfxk_*.png`.

Stacked on GFX-J (`76fdc32`). Day grade knobs were not retuned.
Item 8 lighting A/B was rolled back.

## Per-item

| item | result |
| --- | --- |
| 1 Fog / boundary | Pass |
| 2 Architecture hierarchy | Pass |
| 3 Opening landmark | Pass |
| 4 Worn medieval paths | Pass |
| 5 Three-scale ground | Pass |
| 6 Woodland edge | Pass |
| 7 Settlement dressing | Pass |
| 8 Selective lighting A/B | Rolled back |

Timings and score filled after the live harness.
