# Shard & Sovereign Demo 0.1.0

Build by day. Survive the night. Claim the Shard.

This release-rescue build turns the current One Shard vertical slice into a Windows demo candidate with an authored first five minutes, a visual command interface, complete locomotion coverage, an original adaptive score, a layered soundscape, materially faster rendering and a tested menu-to-victory path.

## Highlights

- Fixed a release-menu input blocker where invisible full-screen modal containers intercepted clicks intended for every visible button.
- Added a proper main menu with Play Demo / New Game, validated Continue, How to Play, Settings, Quit, premise, tagline, and version.
- Added pause, save, restart, settings, main-menu, and quit flows.
- Replaced Town Hall placement with an authored clearing, completed Town Hall, entrance apron, one starter settler and nearby readable resources.
- Added a door-open/walk-out/confused-reaction introduction and a manual select/right-click first gather order with visible work and delivery.
- Replaced the bottom text grid and right terrain inspector with a collapsible left command dock containing selection art, commands, categories, thumbnails, costs and locked states.
- Removed the desktop arrow pad and ordinary-play Lumen radius geometry.
- Reworked tile/building information into short, actionable status: purpose, cost, road state, safety, staffing, input, output, storage, and suggested remedy.
- Removed persistent world-space status text that obscured buildings; retained small progress bars and alert markers.
- Added warmer settlement details, chimney smoke, clearer roads and walls, a smaller/more grounded Sovereign, and interpolated character movement.
- Strengthened the night grade and audio mix while retaining readable buildings, roads, Lumen protection, enemies, and projectiles.
- Expanded raids with four readable roles:
  - Raider: baseline attacker.
  - Skitterer: fast, fragile worker hunter.
  - Brute: slow, durable wall breaker.
  - Hexer: ranged Wyrd-draining support.
- Added `1x`, `2x`, and `4x` time speeds.
- Added persistent Master, Music, Effects and Ambience values, Mute Music, Restore Defaults and windowed/borderless-fullscreen selection.
- Added an original synchronized five-stem D-Dorian score that crossfades from pastoral day through dusk tension into night percussion and synthetic metal.
- Added a six-emitter positional work sound pool for footsteps, chopping, hammering and Lumen, over the existing event cues.
- Added four-frame Sovereign locomotion and movement-synchronised settler, soldier, rival and four-role enemy presentation.

## Performance Work

- Static terrain, roads, resources, and rivalry geography now live in a retained render layer instead of being rebuilt every animated frame.
- Animated world redraws are capped at 30 Hz while the simulation remains deterministic.
- HUD refreshes are throttled to 4 Hz and still update immediately after relevant input.
- Production worker synchronization is batched.
- Enemy targeting is cached and staggered; redundant path queries were removed.
- Release exports disable diagnostic snapshots and debug-world controls by default.

Measured at 1920×1080 on the development machine (Godot 4.7 Compatibility renderer, NVIDIA GeForce RTX 4070):

- Busy day: 81.8 FPS.
- Mixed-role night attack: 78.5 FPS.
- Authored opening: 135.8 FPS.

See [PERFORMANCE_REPORT.md](PERFORMANCE_REPORT.md) for the fixture and full measurements.

## Validation

- 28 C# simulation tests.
- 96 existing Godot gameplay, construction, and rivalry checks.
- Presentation smoke checks covering the prebuilt opening, one-settler first order, left dock, all build thumbnails, objective copy, hidden debug radii and synchronized mute-safe score.
- Rendered pointer-dispatch checks that physically press How to Play, Settings, Play Demo, Resume, and their Back buttons.
- Rendered menu-to-founding-to-settlement-to-night-to-claim-to-victory playthrough.
- Rendered five-scene screenshot capture.
- Windows export build and packaged-executable launch/responsiveness test.

## Known Limitations

- Keyboard and mouse are the supported input path; controller navigation has not been authored.
- Steamworks integration, achievements, cloud saves, depots, App ID, and store configuration are not included.
- The executable is not code-signed.
- Saves are local and versioned; Steam Cloud and cross-device conflict handling are not configured.
- Player Sovereign death ends the run immediately. The rival Sovereign uses the timed Town Hall respawn system.
- Automated Godot SceneTree harnesses report ObjectDB/resource-in-use warnings when they deliberately terminate immediately after assertions. No growing node count or in-match leak was observed in the release profile, but this exit cleanup should be revisited before a final commercial build.
- Performance and rendered QA were completed on one Windows/NVIDIA machine. Lower-end hardware, integrated GPUs, ultrawide displays, localization, and long soak sessions still need external coverage.
- The new presentation score and soundscape are original deterministic synthesis with source and provenance recorded in `AUDIO_ASSET_LEDGER.md`. Older repository art/audio still requires the project owner’s complete commercial-rights audit before public distribution.
- Enemy roles share one coherent four-frame atlas with scaling/tint differentiation; several attacks and profession actions use procedural overlays rather than bespoke body-frame strips. See `CHARACTER_ANIMATION_AUDIT.md`.
