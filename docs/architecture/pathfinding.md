# Pathfinding

## Goal

Pathfinding lets Carrier workers move across the tile grid while avoiding blocked tiles.

## Current Implementation

Implemented in `src/Simulation/World/WorldState.cs`.

Supporting types:

- `src/Simulation/World/PathfindingResult.cs`
- `src/Simulation/World/PathfindingFailureReason.cs`

## Algorithm

The simulation uses A* over the tile grid.

Current rules:

- movement is four-directional
- each tile step has cost 1
- Manhattan distance is used as the heuristic
- building occupied tiles are blocked
- destinations outside the map are rejected
- blocked destinations are rejected
- unreachable destinations return a failure result

The returned path excludes the starting tile and includes the destination tile.

## Worker Movement

`WorldState.MoveWorkerTo` computes a path from the worker's current tile to the requested destination.

On success:

- the worker receives the path
- the worker state becomes `Moving`
- each simulation tick moves the worker one tile along the path
- the worker returns to `Idle` when the path is complete

On failure:

- the worker path is cleared
- the worker state becomes `Blocked`
- the failure reason is available in `PathfindingResult`

## Debug Output

Pathfinding exposes:

- path success/failure
- failure reason
- path tile list
- worker state
- worker current path

The Godot shell currently mirrors pathfinding in `src/GodotClient/Scripts/client_simulation.gd` so the debug client can draw a path before the Godot C# bridge is set up. The canonical tested implementation is the C# simulation.

## Non-Goals

- hauling
- resource pickup
- warehouse delivery
- roads
- terrain movement costs
- multiple movement types
- large-scale navigation
- dynamic crowd avoidance
