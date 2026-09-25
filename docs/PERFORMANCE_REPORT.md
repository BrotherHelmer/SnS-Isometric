# Shard & Sovereign Demo Performance Report

## Result

The completed presentation build meets the target on the current development machine at 1920×1080:

- Authored opening: 135.8 FPS / 7.36 ms.
- Busy daytime settlement: 81.8 FPS / 12.22 ms.
- Dense mixed-role night attack: 78.5 FPS / 12.74 ms.

The benchmark uses the actual rendered Godot scene, production assets, animation, adaptive audio, normal simulation ticks and a deterministic settlement. It samples 180 opening frames, 240 busy-day frames and 240 night-attack frames. The night fixture contains 14 attackers distributed across Raider, Skitterer, Brute and Hexer roles.

## Test machine

- Godot 4.7 stable, Compatibility / OpenGL 3.3 renderer.
- NVIDIA GeForce RTX 4070.
- 28 logical CPU threads reported by Godot.
- 1920×1080 final presentation viewport.

## Presentation-pass optimisation

The full animation/UI/audio build initially missed the desired 60 FPS floor in the heaviest night fixture. The final change retained a continuous dark-green fog backing while no longer issuing thousands of individual unrevealed fog diamonds.

| Scenario | Pre-optimisation FPS | Final FPS | Pre frame | Final frame | Average draw calls before → after |
| --- | ---: | ---: | ---: | ---: | ---: |
| Opening | 85.5 | 135.8 | 11.70 ms | 7.36 ms | 5,677 → 3,468 |
| Busy settlement | 62.5 | 81.8 | 16.00 ms | 12.22 ms | 7,106 → 5,092 |
| Mixed night attack | 57.5 | 78.5 | 17.38 ms | 12.74 ms | 7,170 → 5,163 |

Startup improved from 415.32 ms to 396.34 ms between those two 1920×1080 runs.

The previous release-rescue checkpoint, measured at the less demanding 1280×720 viewport before this presentation brief, was 165.7 FPS opening, 87.6 FPS busy day and 80.6 FPS night. The current 1920×1080 results remain above the operating target despite the higher resolution, animated command UI, full character pass, soundscape and five synchronized score stems. The two viewport sets are intentionally not presented as a direct percentage comparison.

## Final workload counters

| Scenario | Draw calls/frame | Dynamic render passes | UI updates | Path queries | Grid rebuilds | Visible agents |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Opening (180 frames) | 3,468 | 41 | 6 | 0 | 0 | 4 |
| Busy day (240 frames) | 5,092 | 89 | 12 | 14 | 0 | 18 |
| Night attack (240 frames) | 5,163 | 90 | 12 | 164 | 1 | 32 |

Maximum node count was 200 in all final fixtures. The score uses five long-lived players and the settlement soundscape uses a fixed pool of six positional players; neither creates nodes per cue.

## Retained optimisations

1. Terrain, elevation faces, roads, deposits and rivalry geography live in a retained static-world layer invalidated only by relevant world or camera-bucket changes.
2. Unscouted land uses one contiguous map backing rather than thousands of separate fog draw commands.
3. Dynamic redraw is capped at the animation presentation cadence while tile movement remains interpolated.
4. HUD refresh is throttled with immediate updates on player actions.
5. Enemy target selection and reachability are cached and staggered.
6. Production staffing synchronises in batches.
7. Release exports disable diagnostic snapshots and debug-world controls.
8. Ambient work audio uses a six-emitter pool with cooldowns and distance attenuation.

## Reproduction

Run the rendered profiling harness at the required viewport:

```powershell
.\.tools\godot-4.7\Godot_v4.7-stable_win64_console.exe --path . --resolution 1920x1080 --script res://tests/godot_release_profile.gd
```

Godot’s immediate SceneTree shutdown reports retained RID/ObjectDB warnings from test-owned nodes. The in-match profile shows no growing node count; those shutdown warnings are recorded as test-harness cleanup debt rather than evidence of a runtime growth leak.
