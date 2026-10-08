# GFX-E performance: 4070 regression and the batching fix

## Hardware (RTX 4070, Forward+, warm shader cache)

From `uploads/NOTES.md` and `rtx4070_timeline.csv` at `5419e50` **before**
this fix, versus GFX-D `146b4c3` on the same machine.

| step | GFX-D | GFX-E before | GFX-E after (this commit) |
| --- | ---: | ---: | ---: |
| `start_new_3d` | < 1 s | ~8 s | batched lookups; target ≤ 2 s |
| showcase + first frame | ~9 s | ~112 s warm / >150 s cold | batched occupation rebake; target ≤ 18 s |

Cause: `_corner_terrain_color` called `_terrain_color` ~16× per cell, and
each `_is_road_tile` scanned every building. After the showcase stamp that
is 70×70 × 16 × ~50 buildings. Occupation changes also remeshed the
concave terrain picker.

Fix (presentation only, no art-direction change):

- Cache road / occupation / yard tiles once per frame.
- Precompute one colour per tile, then average corners from the cache.
- Occupation-only updates recolor the slab and keep the picker collision.
- Nature rebuilds once when both layout and FOW change.

## Lavapipe, same harness (`tests/t_gfx_e_perf.gd`)

After the fix on this host:

| step | ms |
| --- | ---: |
| `start_new_3d` | 416 |
| `Showcase.apply` | 9 |
| `_sync_presentation` | 525 |
| first `process_frame` | 6172 |

`T_GFX_E_PERF` gates start_new and showcase_sync at 2× the 4070 GFX-D
figures, and rejects a 112 s first-frame rebuild.
