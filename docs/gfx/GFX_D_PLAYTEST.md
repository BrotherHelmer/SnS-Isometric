# GFX-D self-playtest notes

Harness: `tests/t_gfx_d_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe (`llvmpipe LLVM 20.1.2`, Vulkan 1.4.318). Seed = `DEFAULT_SEED`
(260821). `SNS_PLAYTEST_LOG=1` also wrote `artifacts/gfx_d/playtest/dpm.csv`.

CSV: `/workspace/artifacts/gfx_d/playtest/gfx_d_playtest.csv`  
Copy: `/opt/cursor/artifacts/gfx-d/playtest/gfx_d_playtest.csv`

Comparison cameras: `tests/t_gfx_d_shots.gd` → `artifacts/gfx_d/after/`.  
GFX-C same-camera refs: `tests/t_gfx_c_playtest.gd` on
`cursor/gfx-c-visual-pass-b224` → `artifacts/gfx_c/playtest/` (copied to
`/opt/cursor/artifacts/gfx-d/gfx_c_ref/`).

Master bus stayed `1.000`. Scout result:
`Astrid scouts toward the fog.`

## Script

1. Stamp the deterministic ~15-building showcase, shoot zoom 26 and 42.
2. Fresh opening day on the same seed (no showcase) at the closer default.
3. Spawn / select a free patrol guard and issue Scout (Y) toward the
   western fog. Result: `Astrid scouts toward the fog.`
4. Force night, spawn two raiders, capture the RAID banner.
5. Pull back to the fog edge (zoom 68).

No scout / guard / raider outline files from PR #58 were touched.

## Frame / wait times (lavapipe, not a 4070)

| event | wait_ms | frame_ms | notes |
| --- | ---: | ---: | --- |
| showcase_day | 9867 | 681.2 | 15 buildings + 37 roads, zoom 26 |
| showcase_wide | 7688 | 537.2 | zoom 42, forest rim in frame |
| opening_day | 5482 | 454.6 | normal founding, zoom 26 |
| scout_day | 4991 | 389.8 | scout order live |
| night_raid | 4191 | 356.1 | SSAO off (night cheap-path) |
| fog_edge | 3867 | 333.6 | zoom 68 |

`wait_ms` is wall time for 12 process frames + one `frame_post_draw`.
`frame_ms` is `Performance.TIME_PROCESS` on software Vulkan. On an RTX
4070 the same views should sit well under a 16 ms frame; Recommended
still keeps glow off and 2 shadow splits. High is the opt-in 4-split /
glow path.

## Score vs `concept_1.png`

**5 / 10** (GFX-C review was 3.5 / 10). Target was 6 / 10.

The showcase village is the first frame that *composes* like the concept:
a civic keep, terracotta houses, a wheat block, and a forest rim. That is
a real step. The captured lavapipe frames still read as a Banished lawn —
warm, cleaner, closer — not a handcrafted miniature. I will not mark 6
while dirt roads, occupation aprons and golden-hour shadows fail to
separate in the Forward+ software shots.

### Why not 6

- Opening day is still one civic cottage on a founding apron. The concept
  is a finished hamlet with roads, yards and a pale multi-tower castle.
- Ground variation and occupation are authored (vertex splat + meadow
  noise + cart-track) but lavapipe Forward+ flattens them into a single
  yellow-green plane. Roads do not read as worn earth in these shots.
- Building language is closer (teal civic roof, terracotta homesteads,
  chimney, a few yard props) but silhouettes stay inside the locked AABB.
  The hall is not the concept castle.
- Long soft shadows / strong warm-cool contrast do not show on llvmpipe.
  The grade is a mild warmth, not golden hour.
- Units remain KayKit ticks. Night is readable, not atmospheric.

### What did move vs GFX-C (same cameras)

- Default camera 38 → 26 (~32% closer). GFX-C playtest close is zoom 34;
  GFX-D `after_day_close.png` matches that framing.
- Black grass speckle is gone. Meadow is warmer yellow-green, not olive.
- More trees sit at the edge of the founding frame (forest crescent
  outside the Manhattan-6 build pocket).
- Showcase exists as a fixed benchmark (15 non-road buildings, 37 roads).
- Night stays readable; RAID banner and pressure chip unchanged.

## Readability

- Day: hall, trees, HUD and wheat separate cleanly. Ground does not.
- Night: warm panes hold; grass is dark green rather than black; RAID
  toast is the brightest UI. Raiders still need the parallel outline
  pass (PR #58) at this zoom.
- Fog edge: cool unknown vs green island. Shore foam is a thin band.
- Scout (Y) works without touching outline / scout gameplay files.

## Shots

Playtest:

- `/workspace/artifacts/gfx_d/playtest/showcase_day.png`
- `/workspace/artifacts/gfx_d/playtest/showcase_wide.png`
- `/workspace/artifacts/gfx_d/playtest/opening_day.png`
- `/workspace/artifacts/gfx_d/playtest/scout_day.png`
- `/workspace/artifacts/gfx_d/playtest/night_raid.png`
- `/workspace/artifacts/gfx_d/playtest/fog_edge.png`

Same-camera GFX-D suite (`t_gfx_d_shots.gd`):

- `/workspace/artifacts/gfx_d/after/opening_day.png`
- `/workspace/artifacts/gfx_d/after/after_day_close.png` (zoom 34)
- `/workspace/artifacts/gfx_d/after/after_day_far.png`
- `/workspace/artifacts/gfx_d/after/after_fog_edge.png`
- `/workspace/artifacts/gfx_d/after/after_night_raid.png`
- `/workspace/artifacts/gfx_d/after/showcase_day.png`
- `/workspace/artifacts/gfx_d/after/showcase_wide.png`

Composites (also under `/opt/cursor/artifacts/gfx-d/compare/`):

- `/workspace/artifacts/gfx_d/compare/concept_vs_now_showcase.png`
- `/workspace/artifacts/gfx_d/compare/concept_vs_now_opening.png`
- `/workspace/artifacts/gfx_d/compare/gfxc_vs_gfxd_opening_z34.png`
- `/workspace/artifacts/gfx_d/compare/gfxc_vs_gfxd_opening.png`
- `/workspace/artifacts/gfx_d/compare/gfxc_vs_gfxd_night.png`
- `/workspace/artifacts/gfx_d/compare/gfxc_vs_gfxd_fog.png`
- `/workspace/artifacts/gfx_d/compare/gfxc_vs_gfxd_scout.png`
