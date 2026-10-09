# GFX-N self-playtest notes

Harness: `tests/t_gfx_n_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe. Seed = `DEFAULT_SEED` (260821). Covers the first **15 game
minutes** (opening, build, scout, first night, raid).
`SNS_PLAYTEST_LOG=1` also wrote `artifacts/gfx_n/playtest/dpm.csv`.

CSV: `docs/gfx/gfx_n_playtest.csv`  
Comparison cameras: `tests/t_gfx_n_shots.gd` → `artifacts/gfx_n/after/`.  
CONCEPT vs NOW / GFX-M vs GFX-N:
    `/opt/cursor/artifacts/gfx-n/concept_vs_now_*.png` and
`gfxm_vs_gfxn_*.png`.

Master bus stayed `1.000`. Numbers below are filled after the live
harness on this run.

Stacked on GFX-M (`83670a8`, PR #70, ChatGPT **6.8/10**). Day grade
knobs (sat 1.12 / contrast 1.12 / exposure 0.86) were **frozen**.
Meshes / texture system / creek / forest / night stay. Green roofs,
sandy terrain colours, and pale meadow rocks were reverted.

W = Town Hall 4×4 = **10.0 m**. R = cell × 0.97 = **2.425 m**.
H = house visual height ≈ **4.09 m**.

## Script

1. Fresh opening hamlet + ridge / creek, camera on
   `opening_camera_focus()` at zoom 26.
2. Place a road off the hall entrance and a house two tiles east.
3. Spawn / select a free patrol guard and issue Scout (Y) toward the
   western fog.
4. Advance through the rest of day 1 (`DAY_LENGTH_SECONDS` 420) into
   first night, then spawn two raiders and capture the RAID banner.
5. Advance through night + remainder so `elapsed_seconds` ≥ 900
   (~15 game minutes), then stamp the showcase and pull back to the
   **1.5× zoom cap** (39).

No scout / guard / raider outline files were touched.

## Per-item (plan order)

| item | result | notes |
| --- | --- | --- |
| 1 Lush green terrain | pending | Meadow `#556D3F`, tex_mix 0.20, roughness 0.94. |
| 2 Unmistakable roads | pending | Magenta debug, then `#AE906D` union mask, 512². |
| 3 KayKit remap | pending | Limestone / plaster / teal + terracotta. No emerald. |
| 4 Rocks + creek | pending | `#898776` ridge, hidden meadow rocks, water `#345E64`. |
| 5 Clustered groundcover | pending | Forest-edge / landmark tufts. |

Licences: `docs/ASSET_LICENSES.md` (Kaykit remap row).

## Frame / wait times (lavapipe, not a 4070)

Filled after `t_gfx_n_playtest`.

## Playability gates

| gate | result |
| --- | --- |
| No crashes / script errors | pending |
| First frame < 3 s | pending |
| All tests + perf guard | pending |
| Export MISSING | pending |
| Master bus | pending |
| 15-minute self-playtest | pending |

## Strict self-score

Pending live shots. ChatGPT projected 7.2–7.6 if all five land.
Do not claim 8. Do not merge on this score.
