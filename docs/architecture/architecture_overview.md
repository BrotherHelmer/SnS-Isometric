# Architecture Overview

## Core Rule

Simulation state must be independent from rendering state.

The simulation owns:

- world grid
- buildings
- workers
- resources
- inventories
- tasks
- paths
- production
- save/load data

The Godot client owns:

- rendering
- camera
- input
- UI
- debug visualization
- scene instantiation

## Data Flow

```text
Input -> Command -> Simulation -> State Update -> Rendering Sync -> UI/Debug
```

## Example

The player clicks to place a warehouse.

The Godot client should not directly create the warehouse as game state.

Instead:

1. Godot detects tile click.
2. Godot sends `PlaceBuildingCommand`.
3. Simulation validates placement.
4. Simulation creates building state.
5. Godot renders the building based on simulation state.

## Long-Term Intent

This structure should allow the simulation to later move to a server or headless process without rewriting the whole game.

## Current Client Shell

The Godot client shell lives in `src/GodotClient`.

Current files:

- `project.godot`
- `src/GodotClient/project.godot`
- `src/GodotClient/Scenes/main.tscn`
- `src/GodotClient/Scripts/main.gd`
- `src/GodotClient/Scripts/client_simulation.gd`

Current responsibilities:

- draw a simple placeholder isometric tile grid
- own camera pan and zoom
- detect hovered tile coordinates
- store selected tile coordinates
- let the player select Warehouse or Woodcutter placement mode
- request placement through a command-shaped placement API
- render placed building footprints from simulation state
- draw a Carrier worker and its current path
- display hauling inventory totals
- expose Save and Load debug buttons
- display client-only debug information

Current boundary:

- the C# simulation project owns tested placement, production, pathfinding, hauling, and save/load rules
- the current GDScript shell uses `client_simulation.gd` as a temporary non-rendering simulation adapter because the Godot C# bridge is not set up yet
- the simulation project does not reference the Godot client
- no building placement state is stored in rendered building nodes
- active worker paths are reset on load in the first save/load implementation

The next architecture step should remove the temporary adapter by connecting the Godot client directly to the C# simulation project or by making an explicit decision to keep Godot-side view models as a translation layer.
