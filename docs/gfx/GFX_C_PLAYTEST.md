# GFX-C self-playtest notes

Harness: `tests/t_gfx_c_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe (`llvmpipe LLVM 20.1.2`). Seed = `DEFAULT_SEED`.
`SNS_PLAYTEST_LOG=1` also wrote `artifacts/gfx_c/playtest/dpm.csv`.

CSV: `/workspace/artifacts/gfx_c/playtest/gfx_c_playtest.csv`

## Script

1. Opening day, close camera on the Town Hall.
2. Spawn / select a free patrol guard and issue Scout (Y) toward the
   western map edge. Result: `Astrid scouts toward the fog.`
3. Force night, spawn two raiders, capture the RAID banner.
4. Pull back to the fog edge.
5. Far island view.

## Frame / wait times (lavapipe, not a 4070)

| event | wait_ms | frame_ms | notes |
| --- | ---: | ---: | --- |
| opening_day | 4849 | 290.7 | close iso, day |
| scout_day | 5676 | 300.8 | scout order live |
| night_raid | 3877 | 265.1 | SSAO off (night cheap-path) |
| fog_edge | 3049 | 266.6 | zoom 68 |
| day_far | 7449 | 332.9 | zoom 130, whole island |

`wait_ms` is wall time for 12 process frames + one `frame_post_draw`.
`frame_ms` is `Performance.TIME_PROCESS` on software Vulkan. On an RTX
4070 the same views should sit well under a 16 ms frame; nothing heavier
than High-toggle glow shipped on Recommended.

## What looks good

- Meadow is actually green. GFX-B’s khaki pancake is gone at close and
  far zoom.
- Tree crowns are mixed conifer / broadleaf and no longer a black
  cone-wall. Birch / oak read lighter than spruce.
- Town Hall roof is readable blue-grey slate on cream plaster, not a
  brown toy lid.
- Night still has warm panes; the RAID banner and pressure chip stay
  where T-SNS-UI put them.
- Scout (Y) on a guard works without touching outline / scout gameplay
  files from the parallel branch.

## What still looks bad / short of the concept

- Opening day is one civic cottage on a lawn. The north-star shot is a
  finished village with a pale multi-tower castle, wheat and a busy
  waterline. That is content, not a shader.
- Keep / towers cannot grow past the locked AABB, so the hall is not
  yet a castle silhouette.
- Units are still small KayKit figures. The new rim helps at close zoom;
  at fog-edge they remain ticks. Raiders in the night shot are far off
  camera-left (spawned west of the hall).
- Far / fog views still show the unknown as a cool slate sheet around a
  green square. Better than olive khaki, not yet atmosphere.
- HUD gold hairline is thicker but the layout is the same navy bars.
- Lavapipe frame times are not a shipping perf signal.

## Readability

- Day: hall, trees, grass and HUD all separate cleanly.
- Night: hall + windows hold; grass is dark green rather than black;
  the RAID toast is the brightest UI. Raider bodies need the parallel
  outline pass (PR #58) for combat ticks at this zoom.
- Fog edge: the unknown is cool, the island is green, the sea is teal.
  Shore foam is visible only at closer zooms.

## Shots

- `/workspace/artifacts/gfx_c/playtest/opening_day.png`
- `/workspace/artifacts/gfx_c/playtest/scout_day.png`
- `/workspace/artifacts/gfx_c/playtest/night_raid.png`
- `/workspace/artifacts/gfx_c/playtest/fog_edge.png`
- `/workspace/artifacts/gfx_c/playtest/day_far.png`
