# Steam Demo Checklist

> **Historical July candidate checklist.** The listed export predates the current production 3D source. Do not use its readiness verdict for the current game. Follow [the 2026-09-25 release readiness plan](RELEASE_READINESS_PLAN.md), which adds the owner-confirmed closed Steam Playtest stage and current save, asset, QA and packaging gates.

## Build Delivered

- Windows x86_64 executable: `dist/ShardAndSovereign_Demo_Windows/ShardAndSovereign_Demo.exe`
- Resource pack: `dist/ShardAndSovereign_Demo_Windows/ShardAndSovereign_Demo.pck`
- Upload archive: `dist/ShardAndSovereign_Demo_Windows.zip`
- Display name: Shard & Sovereign Demo
- Version: 0.1.0-demo
- Default resolution: 1280 x 720, resizable.
- Launch executable: `ShardAndSovereign_Demo.exe`
- Runtime dependencies: none expected beyond supported Windows system components; Godot is packaged in the executable.

## Human Steamworks Steps

- Create or select the real Steam demo App ID. No App ID has been invented or embedded.
- Create the Windows depot and assign it to the demo application.
- Configure the launch option to `ShardAndSovereign_Demo.exe` with no arguments.
- Upload the contents of `dist/ShardAndSovereign_Demo_Windows/` with SteamPipe.
- Put the build on a password-protected playtest branch first.
- Verify install, launch, update, uninstall, and save behavior from a clean Steam client account.
- Complete store capsule art, library assets, description, content survey, supported languages, system requirements, privacy disclosures, and age-rating information.
- Choose whether to enable Steam Cloud for the Godot user-data save folder; test conflict behavior before enabling it publicly.
- Decide whether achievements, overlay integration, or Steam Input are in scope. None are implemented in this demo build.
- Review crash reporting and support/contact routing.
- Consider Windows code signing and submit the exact packaged build to antivirus/reputation checks.
- Run Valve's review checklist and submit only after the lower-end hardware and licensing gates below are closed.

## Required Human Verification

- Verify ownership and commercial-distribution rights for every image and audio file in `assets/settlement/`. The repository describes audio as generated, but a complete provenance/license manifest is not present.
- Confirm that the project name, icon, logo, and tagline are cleared for public use.
- Retain the Godot Engine MIT notice supplied with the package.
- Run a clean-room test on a machine without Godot or development tools installed.
- Test integrated graphics and a lower-spec CPU against the 60/45 FPS targets.
- Run at least a 60-minute soak covering save/continue, repeated day/night transitions, defeat, restart, and victory.
- Check 16:9, 16:10, ultrawide, high-DPI, and borderless fullscreen behavior.
- Test keyboard layouts other than US QWERTY if those regions will be advertised.
- Decide whether the immediate player-Sovereign-death defeat is the intended public rule.
- Investigate the test-harness-only ObjectDB/resource cleanup warnings before calling the build final-commercial quality.

## Screenshot Set

- `artifacts/demo_screenshots/01_day_settlement.png`
- `artifacts/demo_screenshots/02_hauling_and_production.png`
- `artifacts/demo_screenshots/03_sunset_warning.png`
- `artifacts/demo_screenshots/04_night_defense_roles.png`
- `artifacts/demo_screenshots/05_shard_claim.png`

These are direct rendered captures from the implemented Godot build fixture, not mockups.

## Readiness Gate

The candidate is ready for external playtesting. It is not yet ready for Steam review submission until asset/licensing provenance, clean-machine/lower-end QA, Steamworks configuration, and the longer soak pass are complete.
