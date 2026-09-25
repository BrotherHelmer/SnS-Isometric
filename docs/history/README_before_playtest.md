# Shard & Sovereign: One Shard Prototype

> **2026-09-25 release review:** The current route is closed Steam Playtest, then public demo. See [release readiness and work plan](docs/RELEASE_READINESS_PLAN.md). The July package in `dist/` predates the current 3D game and is historical; the release/status descriptions below need reconciliation with the newer rules. Nine current focused suites passed, but packaging, save safety, human full-match testing and hardware/Steam verification remain open.

One Shard is the local isometric settlement and single-player rivalry prototype for Shard & Sovereign.

This is not the MMO. It is a playable two-realm skirmish built on the current settlement/logistics simulator: one province, autonomous gathering, paid owned roads, connected Lumen, combat disruption, and a shared one-night Shard claim.

## Demo Release Candidate

The 0.1.0-demo release-rescue candidate is available as a Windows x86_64 export in `dist/ShardAndSovereign_Demo_Windows/`, with the upload ZIP at `dist/ShardAndSovereign_Demo_Windows.zip`.

- [Demo controls](docs/DEMO_CONTROLS.md)
- [Release notes and known limitations](docs/DEMO_RELEASE_NOTES.md)
- [Before/after performance report](docs/PERFORMANCE_REPORT.md)
- [Character animation audit](docs/CHARACTER_ANIMATION_AUDIT.md)
- [Music and audio direction](docs/MUSIC_AND_AUDIO_DIRECTION.md)
- [Audio asset ledger](docs/AUDIO_ASSET_LEDGER.md)
- [Presentation pass validation](docs/PRESENTATION_PASS_VALIDATION.md)
- [Steam demo checklist](docs/STEAM_DEMO_CHECKLIST.md)

## Current Status

The Godot client now contains a playable One Shard vertical-slice pass:

- Player and deterministic rival realms start on opposite sides of a central Shard with isolated Wood/Wyrd ledgers and equal rivalry rules.
- Settlement-level Wyrd harvesting and claiming through connected roads, Lumen, and Claimant Outposts; no directly controlled player hero.
- A deterministic rival planner with visible autonomous workers that earns resources and builds a real route to the Shard.
- Paid realm-owned roads, road movement bonuses, Lumen Pillars with connected-network checks and nightly Wyrd upkeep, and Claimant Outposts.
- A shared match/claim state machine: operational Outpost, continuous road and Lumen, no enemy contesting Outpost, and one complete held night.
- Focused rivalry HUD, Realm Chronicle events, Shard/night visual modes, build ghosts, and optional F3 diagnostics.
- 70x70 microtile province with fog of war, broad height terraces, one Shard, and dormant enemy camps.
- Authored prebuilt Town Hall opening with one selectable settler, a scripted walk-out/reaction, and the first player-issued gather order.
- Left-side visual command dock with building thumbnails, categories, costs, locked states, contextual commands and a collapsible footprint.
- Local building inventories, finite central storage, output backpressure, and capacity-expanding Storehouses.
- Carrier logistics for construction materials, processor inputs, and production outputs, including travel through the Town Hall junction.
- Wood, stone, plank, wheat, and bread production chains.
- Visible production workers, slower animated movement, trained soldiers, staffed towers, and village patrols.
- Houses, food-driven population growth, staffing priorities, nightly meals, visible hunger, and morning production recovery.
- Road-weighted pathfinding and faster road travel for settlers, carriers, and night enemies.
- Camera movement via arrow keys and middle/right drag, wheel zoom, and Town Hall recentering. Workers and soldiers remain autonomous.
- Day/night cycle, hidden-threat escalation, weaker but larger waves, exposed-worker targeting, walls, soldier-only Watchtowers, and projectile feedback.
- Claimant Outpost beside the Shard, one-complete-night hold requirement, shared victory rules, score, best score, and run summary.
- Versioned JSON save/load for elevations, camps, multi-tile footprints, storage, soldiers, workers, enemies, objectives, time, combat, and claim state.
- Persistent JSONL run journal, ten-second state snapshots, final-run snapshot, and an in-game Realm Chronicle.
- 48x24 microtiles, multi-tile building yards, narrow earth roads, walls, and concept-derived medieval buildings.
- Four-frame pixel walk cycles for settlers and night raiders, with calmer movement timing and direction-aware sprite flipping.
- Persistent harvested clearings, exclusive tree/rock nodes, paid connected roads, and Barracks recruitment.
- Original five-stem adaptive score, generated village ambience and positional work sounds for roads, construction, deliveries, footsteps, Lumen, nightfall, enemies and soldiers.

Controls, architecture, AI behavior, tuning, debug information, and deferred systems are documented in [`docs/design/one_shard_rivalry.md`](docs/design/one_shard_rivalry.md).

## Project Shape

- Production Godot entry scene: `src/GodotClient3D/Scenes/production_3d.tscn`
- Production Godot UI/world view: `src/GodotClient3D/Scripts/production_3d_game_root.gd`
- Godot vertical-slice simulation: `src/GodotClient/Scripts/one_shard_simulation.gd`
- Data definitions: `src/GodotClient/Scripts/one_shard_defs.gd`
- Earlier C# simulation library and tests remain in `src/Simulation` and `tests/SimulationTests`.

## Core Rule

Simulation owns the truth. Rendering displays the truth. Input requests changes.

## Verification

The existing C# simulation tests pass:

```text
All 28 simulation tests passed.
```

Godot 4.7 was extracted locally from the existing archive in Downloads to `.tools/godot-4.7` and used directly for checks:

```text
REBUILD_SMOKE PASS (34 focused gameplay checks)
CONSTRUCTION_SMOKE PASS (6 focused presentation/input checks)
RIVALRY_SMOKE PASS (20 focused rivalry and full-match checks)
```

Run diagnostics are written to `user://one_shard_run_journal.jsonl`; a completed run also writes `user://one_shard_last_run.json`.
