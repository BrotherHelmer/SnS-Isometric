# GFX-C report

Head: see the draft PR on `cursor/gfx-c-visual-pass-b224`.
Base: `cursor/gfx-b-visual-pass-9d8f` (GFX-B).

## What changed

Helmer asked for a proper graphics overhaul toward `concept_1.png`, not
another cheap remap. GFX-C remeshes and re-kits presentation only.

| Area | Done |
| --- | --- |
| Buildings | Town hall, castle, house, farm, bakery, storehouse, lumber camp, watchtower, barracks remeshed. Pale cream masonry, blue-grey slate civic roofs, terracotta homestead roofs, thicker half-timber. AABBs still match `BUILDING_UNIT_SIZE`. Construction / sockets / selection unchanged. |
| Trees | Six authored silhouettes + two LOD meshes. KayKit `Tree_1–4` retired from the live kit. Foliage shader height-splits trunk / canopy and lifts Nordic greens. MultiMesh batches unchanged. |
| Terrain | Sunlit grass `#5A8B44`, moss `#3A6840`, stronger meadow patches. Dirt / crops kept. |
| Water | Teal-green sea, brighter foam band, cheap ripple (off on the night cheap-path). |
| Lighting / post | Day key `#F4CC90`. New **High** quality profile: glow on, shadow blur 1.6. Recommended still glow/SSIL/volumetrics off. |
| Units | Role rim (cream settler, steel guard, rust raider). No outline files from PR #58. |
| HUD | Thicker gold hairline, more opaque navy frames (`tools/generate_ui_art.py`). |

## What remains vs the concept art

The attached north star is a developed Farthest Frontier–like settlement:
a pale multi-tower castle, terracotta house cluster, lush mixed forest,
wheat, teal water, navy/gold chrome. GFX-C is a **clear step**, not
parity.

Still short:

- Opening-day Town Hall is a civic cottage with a squat keep, not the
  full pale castle (that mesh appears after the barracks upgrade).
- AABB lock prevents heroic height; towers cannot outgrow the old box.
- Forest is fuller and greener, not a dense understory / waterline wood.
- Coast is still the G1 rounded-rect + jut. No carved coves / rock stacks.
- Units read better but stay KayKit rigs; no new hero sculpts.
- HUD chrome is thicker navy/gold, not new frame art or type.
- True volumetrics / bloom-on-Recommended stay postponed.

## Screenshot paths

All also copied under `/opt/cursor/artifacts/gfx-c/`.

**GFX-B before vs GFX-C after** (same cameras as `tests/t_gfx_b_shots.gd`):

- `/workspace/artifacts/gfx_c/compare/compare_day_close.png`
- `/workspace/artifacts/gfx_c/compare/compare_day_far.png`
- `/workspace/artifacts/gfx_c/compare/compare_night_raid.png`
- `/workspace/artifacts/gfx_c/compare/compare_fog_edge.png`

Raw frames:

- before: `/workspace/artifacts/gfx_c/before/before_*.png`
- after: `/workspace/artifacts/gfx_c/after/after_*.png`

**CONCEPT vs NOW:** `concept_1.png` was attached to the brief but not
present on disk in this checkout. Composites use the in-repo art-direction
sheet `docs/design/concepts/amiga_settlement_direction.png` against the
GFX-C opening-day cameras:

- `/workspace/artifacts/gfx_c/compare/compare_concept_now.png`
- `/workspace/artifacts/gfx_c/compare/compare_concept_far.png`

Playtest frames: `/workspace/artifacts/gfx_c/playtest/`.

## Tests

| Gate | Result |
| --- | --- |
| `t_gfx_b` | PASS |
| `t_gfx_light` | PASS |
| `t_fog_reveal` | PASS |
| `opening_style_models` | PASS |
| `t_gfx_c` (new) | PASS |
| `t_gfx_c_playtest` | PASS (scout order succeeded: “Astrid scouts toward the fog.”) |

`t_gfx_c` is **not** added to `tools/linux_ci.sh` or `.github/workflows`.

## Playtest

See `docs/gfx/GFX_C_PLAYTEST.md`. CSV:
`/workspace/artifacts/gfx_c/playtest/gfx_c_playtest.csv`.

Frame times are **llvmpipe / lavapipe** in this box (237–333 ms/frame),
not an RTX 4070. Triangle counts stay in the previous envelope (buildings
5–10k tris, hero trees ≤ 1.3k, LOD trees 240–580).

## Assets / licence

`ASSETS/credits.md`. All new meshes and HUD frames are project-authored
CC0. Fonts remain SIL OFL as already ledgered.

## Intentionally not touched

Gameplay / save format, scout-guard-raider outline presentation (PR #58),
default Master volume, `.github/workflows`, extra CI jobs.
