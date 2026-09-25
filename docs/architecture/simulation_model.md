# Simulation Model

## Purpose

The simulation model defines the authoritative game state for One Shard. It should be plain C# and independent from Godot scene nodes.

## Initial Concepts

### ResourceType

Implemented in `src/Simulation/Resources/ResourceType.cs`.

```csharp
public enum ResourceType
{
    Wood = 1
}
```

### Inventory

Implemented in `src/Simulation/Resources/Inventory.cs`.

Current responsibilities:

- adding resources
- removing resources
- querying resources
- enforcing capacity

Current rules:

- amounts cannot be negative
- removing more than available is rejected
- adding beyond total capacity is rejected
- current Wood amount can be queried

### BuildingType

Implemented in `src/Simulation/Buildings/BuildingType.cs`.

```csharp
public enum BuildingType
{
    Warehouse = 1,
    Woodcutter = 2
}
```

### Building

Implemented in `src/Simulation/Buildings/Building.cs`.

Current fields:

```text
BuildingId
BuildingType
TilePosition
Footprint
OccupiedTiles
```

`Warehouse` and `Woodcutter` both use a 2x2 footprint.

### Warehouse

Implemented in `src/Simulation/Buildings/Warehouse.cs`.

Current fields:

```text
BuildingId
BuildingType.Warehouse
TilePosition
Footprint
Inventory
```

The warehouse has storage for Wood. Production, construction, and UI are not implemented.

### Woodcutter

Implemented in `src/Simulation/Buildings/Woodcutter.cs`.

Current fields:

```text
BuildingId
BuildingType.Woodcutter
TilePosition
Footprint
OutputInventory
ProductionIntervalTicks
ProductionAmount
TicksUntilNextProduction
ProductionStatus
```

Production behavior:

- produces 1 Wood every 3 production ticks by default
- stores produced Wood in `OutputInventory`
- stops ticking production while the output inventory is full
- resumes ticking once output space becomes available
- exposes `WoodcutterProductionStatus` for debugging

Production is deterministic and does not depend on rendering, workers, hauling, or pathfinding.

### Worker

Implemented in `src/Simulation/Workers/Worker.cs`.

Current fields:

```text
WorkerId
WorkerType
TilePosition
CarriedResourceType
CarriedAmount
CarryCapacity
CurrentTaskSourceBuildingId
CurrentTaskDestinationBuildingId
State
CurrentPath
```

Current behavior:

- workers are currently Carrier workers
- workers can receive a path
- workers move one tile per simulation tick
- workers become `Idle` when their path is complete
- workers become `Blocked` when a requested path fails
- Carrier workers can carry Wood
- Carrier workers can move through the first hauling loop

### WorkerState

Implemented in `src/Simulation/Workers/WorkerState.cs`.

```text
Idle
MovingToPickup
PickingUp
MovingToDropoff
DroppingOff
Blocked
Moving
```

### Task

No standalone task queue has been implemented yet.

The first hauling loop stores simple source and destination building ids directly on the Carrier worker.

Planned task type:

```text
HaulResourceTask
```

Fields:

```text
TaskId
SourceBuildingId
DestinationBuildingId
ResourceType
Amount
TaskState
```

### WorldState

Implemented in `src/Simulation/World/WorldState.cs`.

Current fields:

```text
MapWidth
MapHeight
Buildings
Workers
TickNumber
```

Current responsibilities:

- define local map bounds
- store buildings
- store workers
- increment the simulation tick
- query buildings by id
- query workers by id
- spawn Carrier workers
- validate building placement commands
- create Warehouse and Woodcutter state through placement commands
- reject buildings outside the map
- reject overlapping building footprints
- find A* paths over the tile grid
- treat building occupied tiles as blocked
- assign paths to workers
- advance workers along paths on simulation ticks
- tick Woodcutter production
- run the simple Carrier hauling loop
- move Carrier workers to pickup Wood
- remove Wood from Woodcutter output inventory
- move Carrier workers to a Warehouse
- deposit Wood into Warehouse inventory

Task queue infrastructure, persistence, and save/load are not implemented yet.

### Placement Commands

Implemented in `src/Simulation/World`.

Current command/result types:

```text
PlaceBuildingCommand
PlaceBuildingResult
PlacementFailureReason
```

Current behavior:

- `WorldState.PlaceBuilding` receives a `PlaceBuildingCommand`.
- The simulation validates the requested building footprint against map bounds.
- The simulation rejects overlaps with existing building occupied tiles.
- On success, the simulation creates the requested `Warehouse` or `Woodcutter`.
- On failure, no building is added to world state.

### Pathfinding and Movement

Implemented in `src/Simulation/World`.

Current result types:

```text
PathfindingResult
PathfindingFailureReason
```

Current behavior:

- `WorldState.FindPath` uses A* over the tile grid.
- Movement is four-directional.
- Building occupied tiles are blocked.
- The returned path excludes the start tile and includes the destination tile.
- `WorldState.MoveWorkerTo` assigns a path to a worker when pathfinding succeeds.
- `WorldState.IncrementTick` advances moving workers one tile per tick.
- A failed move request clears the worker path and sets worker state to `Blocked`.

### Hauling Loop

Implemented in `src/Simulation/World/WorldState.cs`.

Current behavior:

- `WorldState.IncrementTick` ticks Woodcutter production.
- Idle Carrier workers look for a Woodcutter with available Wood.
- Carrier workers select the first Warehouse with available capacity.
- Carrier workers path to an adjacent interaction tile near the Woodcutter.
- Carrier workers pick up Wood from the Woodcutter output inventory.
- Carrier workers path to an adjacent interaction tile near the Warehouse.
- Carrier workers deposit Wood into the Warehouse inventory.
- Carrier workers return to `Idle` and can repeat the loop.

Current simplifications:

- no job priority
- no task queue
- no multiple resources
- no multiple worker types
- no roads

## Current Implementation Status

The simulation foundation and basic Woodcutter production are implemented and tested.

Tests live in `tests/SimulationTests` and currently cover:

- Inventory add/remove/query behavior
- Inventory negative amount rejection
- Inventory capacity enforcement
- WorldState building storage and lookup
- WorldState worker storage and lookup
- WorldState tick increments
- Woodcutter production over time
- Woodcutter output capacity limit
- Woodcutter blocked production status
- Woodcutter resumed production after Wood is removed
- Warehouse placement command success
- Woodcutter placement command success
- outside-map placement rejection
- overlapping placement rejection
- Carrier worker spawning
- reachable pathfinding
- unreachable destination refusal
- blocked tile avoidance
- worker movement over simulation ticks
- world tick Woodcutter production
- Carrier pickup from Woodcutter
- Carrier delivery to Warehouse
- repeated Carrier hauling

The next recommended task is save/load.
