# One Shard Vertical Slice Implementation Plan

> Historical implementation plan. For the current 3D game and the owner-confirmed closed Steam Playtest -> public demo route, use [the 2026-09-25 release readiness plan](docs/RELEASE_READINESS_PLAN.md). Scope, renderer, roads and victory rules below describe an earlier version.

## Audit

- Current Godot entry point is `src/GodotClient/Scenes/main.tscn` with `src/GodotClient/Scripts/main.gd`.
- Current playable shell is a narrow prototype: isometric grid, camera, tile hover/selection, Warehouse/Woodcutter placement, one carrier, wood hauling, and JSON save/load.
- Current C# simulation library remains at the earlier warehouse/woodcutter scope. It is useful as architectural precedent, but too small for the requested vertical slice.
- The existing root project points to the Godot client scene and uses a 1280x720 canvas setup.

## Approach

- Keep the existing manual isometric renderer and input model because it is already working.
- Replace the narrow GDScript client simulation with a fuller One Shard run simulation.
- Add a definitions script so building costs, HP, staffing, resources, terrain, and labels are data-driven.
- Keep rendering/UI as display and input request layers; simulation validates and mutates state.
- Preserve local JSON save/load, expanding it to all active run state.

## Planned Files

- `src/GodotClient/Scripts/one_shard_defs.gd`
  - Tiles, buildings, resources, costs, HP, staff, names, production recipes.
- `src/GodotClient/Scripts/one_shard_simulation.gd`
  - Serializable run state, map generation, road graph, placement, construction, logistics, production, food, night waves, combat, objectives, score, save/load.
- `src/GodotClient/Scripts/main.gd`
  - World rendering, build UI, info panel, objectives/log display, selection, hover/build ghosts, summary screens.
- `README.md`
  - Update status once the vertical slice pass is in place.

## Milestone Mapping

- Milestone 1: definitions and serializable state live in `one_shard_defs.gd` and `one_shard_simulation.gd`.
- Milestone 2: map generation, fog, camera, hover, selection, and build ghost are rendered in `main.gd`.
- Milestone 3: roads, placement validation, construction sites, and connection state are in the simulation.
- Milestone 4: inventories, material reservations, carriers, and road pathing are in the simulation.
- Milestone 5: wood, stone, planks, wheat, and bread chains are implemented.
- Milestone 6: population, food, starvation, abandoned buildings, and restaffing are implemented.
- Milestone 7: day/night, enemy waves, tower fire, damage, and defeat are implemented.
- Milestone 8: Outpost adjacency, Shard claim, two-night survival, victory, and summary are implemented.
- Milestone 9: save/load, objective panel, realm log, notifications, and UX pass are implemented.

## Known Scope Choices

- Buildings use one-tile footprints in this vertical slice to keep roads, readability, and logistics clear on a 35x35 map.
- Roads are instant-build and consume wood immediately.
- Non-road buildings become construction sites and require carrier delivery.
- Carriers are logistics workers spawned from population cap and do not consume production population.
- Every assigned production job has a visible worker entity. Carriers remain separate logistics labor and do not consume production population.
- Production output stays in a building's local inventory until a carrier collects it.
- Construction starts only after reserved materials are physically delivered.
- Staff priorities can rebalance the available population across workplaces.
- The visual target is an original 64x32 Amiga-era pixel settlement, documented in `docs/design/visual_direction.md`.
