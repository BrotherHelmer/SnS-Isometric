# demo_playthrough_v10 — TEST #22 accept

Feature freeze on PR #88 (`cursor/idle-overview-a689`). No new events.
Headless `--accept` rerun of seeds 260821, 261306, 261597, 260918, plus
official 3D 260821.

Idle gate is 90 s (slack `90 + STEP(8) = 98`). Longest command-gap is the
8 s step on every seed because the founding hour (through the crater march)
counts as play.

| Seed | Victory | Idle | ISS before | ISS after | Ch | path | first_12 | first_build |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 260821 | 50:36 (3036) | 8 s | 16093 | 11151 | 1 | shelter/refine/wall | 48:16 | 0:08 |
| 261306 | 52:44 (3164) | 8 s | 16491 | 12960 | 1 | fortify/secure/overcharge | 51:04 | 0:08 |
| 261597 | 46:04 (2764) | 8 s | 17502 | 14587 | 1 | shelter/refine/wall | 43:44 | 0:08 |
| 260918 | 52:12 (3132) | 8 s | 6138 | 2355 | 1 | fortify/secure/overcharge | 50:32 | 0:08 |

All four `DEMO_PLAYTHROUGH PASS`. Channel HUD / tooltip / loop / victory
report `Ward restored: +40 HP` or `Ward held: next 40 dmg prevented`.
Crew shortcut jumps to the real bottleneck (Sawmill / transport / the
blocked building). Sealed fissure keeps cyan as the focus, not a white
wash. Victory holds the stabilized fissure 2 s before the overlay.
