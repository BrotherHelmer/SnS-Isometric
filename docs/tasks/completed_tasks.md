# Completed Tasks

## 2026-06-28: Initial structure and documentation

Created the One Shard starter structure and documentation set.

Files created:

- `README.md`
- `docs/design/game_pillars.md`
- `docs/design/one_shard_scope.md`
- `docs/design/user_experience.md`
- `docs/architecture/architecture_overview.md`
- `docs/architecture/simulation_model.md`
- `docs/architecture/data_contracts.md`
- `docs/architecture/pathfinding.md`
- `docs/architecture/save_load.md`
- `docs/architecture/debug_overlay.md`
- `docs/decisions/adr_001_engine_choice.md`
- `docs/decisions/adr_002_simulation_separation.md`
- `docs/tasks/backlog.md`
- `docs/tasks/current_task.md`
- `docs/tasks/completed_tasks.md`
- `docs/technical_debt.md`

No gameplay, rendering, simulation, or Godot scene code was added.

## 2026-06-28: Simulation foundation

Implemented the first plain C# simulation foundation.

Code added:

- `src/Simulation/Core/BuildingId.cs`
- `src/Simulation/Core/WorkerId.cs`
- `src/Simulation/Core/TilePosition.cs`
- `src/Simulation/Core/Footprint.cs`
- `src/Simulation/Resources/ResourceType.cs`
- `src/Simulation/Resources/Inventory.cs`
- `src/Simulation/Buildings/BuildingType.cs`
- `src/Simulation/Buildings/Building.cs`
- `src/Simulation/Buildings/Warehouse.cs`
- `src/Simulation/Buildings/Woodcutter.cs`
- `src/Simulation/Workers/Worker.cs`
- `src/Simulation/Workers/WorkerState.cs`
- `src/Simulation/World/WorldState.cs`

Project files added:

- `SnsOneShard.sln`
- `src/Simulation/SnsOneShard.Simulation.csproj`
- `tests/SimulationTests/SnsOneShard.SimulationTests.csproj`

Tests added:

- `tests/SimulationTests/Program.cs`

Acceptance criteria covered:

- Inventory can add Wood.
- Inventory can remove Wood.
- Inventory rejects negative amounts.
- Inventory rejects removing more than available.
- Inventory respects capacity.
- Inventory can report the current Wood amount.
- WorldState can store buildings.
- WorldState can store workers.
- WorldState can increment a simulation tick.
- WorldState can query buildings by id.
- WorldState can query workers by id.

No Godot rendering, UI, pathfinding, production, or hauling code was added.

## 2026-06-28: Woodcutter production

Implemented deterministic Woodcutter production in the simulation layer only.

Code added or updated:

- `src/Simulation/Buildings/Woodcutter.cs`
- `src/Simulation/Buildings/WoodcutterProductionStatus.cs`
- `tests/SimulationTests/Program.cs`
- `docs/architecture/simulation_model.md`
- `docs/tasks/current_task.md`
- `docs/tasks/completed_tasks.md`

Behavior added:

- Woodcutter has an output inventory.
- Woodcutter produces 1 Wood every 3 production ticks by default.
- Woodcutter stops production while output inventory is full.
- Woodcutter resumes production once output space becomes available.
- Woodcutter exposes production status for debugging.

Tests added:

- Wood production over time.
- Output capacity limit.
- Blocked production when full.
- Resumed production after Wood is removed.

No Godot rendering, UI, workers, hauling, or pathfinding code was added.

## 2026-06-28: Godot isometric client shell

Created the first Godot client shell without connecting full gameplay.

Files added or updated:

- `src/GodotClient/project.godot`
- `src/GodotClient/Scenes/main.tscn`
- `src/GodotClient/Scripts/main.gd`
- `docs/architecture/architecture_overview.md`
- `docs/architecture/debug_overlay.md`
- `docs/tasks/current_task.md`
- `docs/tasks/completed_tasks.md`
- `docs/technical_debt.md`

Client behavior added:

- simple placeholder isometric tile map
- camera pan by mouse drag
- camera zoom by mouse wheel
- hovered tile coordinate detection
- selected tile coordinate tracking
- simple debug overlay for hover, selection, camera position, and zoom

Not added:

- building placement
- workers
- pathfinding
- hauling
- production UI
- save/load UI
- simulation integration

## 2026-06-28: Building placement

Implemented building placement through simulation commands and added Godot shell placement rendering.

Simulation files added or updated:

- `src/Simulation/Buildings/Building.cs`
- `src/Simulation/World/WorldState.cs`
- `src/Simulation/World/PlaceBuildingCommand.cs`
- `src/Simulation/World/PlaceBuildingResult.cs`
- `src/Simulation/World/PlacementFailureReason.cs`
- `tests/SimulationTests/Program.cs`

Godot client files added or updated:

- `src/GodotClient/Scripts/main.gd`
- `src/GodotClient/Scripts/client_simulation.gd`

Docs updated:

- `docs/architecture/architecture_overview.md`
- `docs/architecture/simulation_model.md`
- `docs/tasks/current_task.md`
- `docs/tasks/completed_tasks.md`
- `docs/technical_debt.md`

Behavior added:

- player can select Select, Warehouse, or Woodcutter mode
- clicking a valid tile in placement mode requests building placement
- placement validates map bounds and occupied footprints
- buildings cannot overlap
- buildings cannot be placed outside the map
- Godot renders simple building footprints from placement state

Tests added:

- Warehouse placement succeeds.
- Woodcutter placement succeeds.
- Outside-map placement is rejected.
- Overlapping placement is rejected.

Not added:

- production UI
- workers
- hauling
- pathfinding

## 2026-06-28: Worker movement and pathfinding

Implemented basic Carrier worker movement and A* pathfinding.

Simulation files added or updated:

- `src/Simulation/Workers/Worker.cs`
- `src/Simulation/Workers/WorkerState.cs`
- `src/Simulation/Workers/WorkerType.cs`
- `src/Simulation/World/WorldState.cs`
- `src/Simulation/World/PathfindingResult.cs`
- `src/Simulation/World/PathfindingFailureReason.cs`
- `tests/SimulationTests/Program.cs`

Godot client files updated:

- `src/GodotClient/Scripts/main.gd`
- `src/GodotClient/Scripts/client_simulation.gd`

Docs updated:

- `docs/architecture/pathfinding.md`
- `docs/architecture/simulation_model.md`
- `docs/architecture/debug_overlay.md`
- `docs/tasks/current_task.md`
- `docs/tasks/completed_tasks.md`

Behavior added:

- Carrier worker type
- A* pathfinding over the tile grid
- building occupied tiles block movement
- worker movement requests
- worker movement one tile per simulation tick
- blocked worker state when movement fails
- Godot debug visualization for worker state and current path

Tests added:

- Carrier worker spawning.
- Reachable pathfinding succeeds.
- Unreachable destination is refused.
- Paths avoid blocked building tiles.
- Worker moves along path over simulation ticks.

Not added:

- hauling
- resource pickup
- warehouse delivery
- roads

## 2026-06-28: First hauling loop

Implemented the first Woodcutter to Carrier to Warehouse hauling loop.

Simulation files updated:

- `src/Simulation/Workers/Worker.cs`
- `src/Simulation/World/WorldState.cs`
- `tests/SimulationTests/Program.cs`

Godot client files updated:

- `src/GodotClient/Scripts/main.gd`
- `src/GodotClient/Scripts/client_simulation.gd`

Docs updated:

- `docs/architecture/simulation_model.md`
- `docs/architecture/debug_overlay.md`
- `docs/tasks/current_task.md`
- `docs/tasks/completed_tasks.md`
- `docs/technical_debt.md`

Behavior added:

- Woodcutter output is produced during world ticks.
- Carrier workers find available Wood at a Woodcutter.
- Carrier workers path to an adjacent Woodcutter interaction tile.
- Carrier workers pick up Wood.
- Carrier workers path to an adjacent Warehouse interaction tile.
- Carrier workers deposit Wood into the Warehouse.
- Warehouse inventory increases.
- Carrier workers repeat the loop.

Tests added:

- World tick produces Woodcutter output.
- Carrier collects Wood from Woodcutter.
- Carrier delivers Wood to Warehouse.
- Carrier repeats the hauling loop.

Not added:

- job priority
- multiple resource types
- multiple worker types
- roads
- markets

## 2026-06-28: Save/load

Implemented local save/load for the simulation and Godot debug shell.

Simulation files added or updated:

- `src/Simulation/Persistence/WorldSaveData.cs`
- `src/Simulation/Persistence/WorldSaveService.cs`
- `src/Simulation/Buildings/Woodcutter.cs`
- `src/Simulation/Workers/Worker.cs`
- `src/Simulation/World/WorldState.cs`
- `tests/SimulationTests/Program.cs`

Godot client files updated:

- `project.godot`
- `src/GodotClient/Scenes/main.tscn`
- `src/GodotClient/Scripts/main.gd`
- `src/GodotClient/Scripts/client_simulation.gd`

Docs updated:

- `docs/architecture/save_load.md`
- `docs/tasks/current_task.md`
- `docs/tasks/completed_tasks.md`
- `docs/technical_debt.md`

Behavior added:

- world state can be serialized to JSON
- world state can be deserialized from JSON
- local save files persist tick number, buildings, inventories, workers, and carried Wood
- Godot debug UI exposes Save and Load buttons
- save/load result is shown in the debug overlay action line
- loaded workers reset active paths and resume from restored state

Not added:

- accounts
- online persistence
- multiplayer
- procedural generation

## 2026-06-28: Godot visual hardening pass

Improved the Godot client shell presentation without adding new gameplay systems.

Godot client files updated:

- `src/GodotClient/Scripts/main.gd`

Behavior and presentation updated:

- raised isometric terrain blocks replaced the flat green debug grid
- Warehouse and Woodcutter render as simple low-poly structures instead of flat colored footprints
- Carrier renders as a small low-poly worker with visible carried Wood
- worker path and placement preview colors were softened
- debug UI was restyled with a warmer panel, selected button state, and a compact top status strip

Not added:

- combat
- multiplayer
- procedural map generation
- new resource types
- new worker types
