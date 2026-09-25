# Backlog

## Milestone 1: Simulation Foundation

- Create core simulation domain classes.
- Add inventory tests.
- Add world state tests.
- Keep simulation code independent from Godot.

## Milestone 2: Isometric Client

- Create a simple isometric tile map.
- Add camera pan and zoom.
- Add tile hover and selection.
- Show selected tile coordinates in debug UI.

## Milestone 3: Building Placement

- Add placement commands.
- Validate placement in the simulation.
- Prevent overlap.
- Prevent placement outside the map.
- Render placed buildings from simulation state.

## Milestone 4: Worker Movement

- Add carrier worker entity.
- Implement A* pathfinding.
- Move worker along path.
- Display worker path and state in debug mode.

## Milestone 5: Production and Hauling Loop

- Make woodcutter produce Wood.
- Give woodcutter an output buffer.
- Let carrier pick up Wood.
- Let carrier deposit Wood in warehouse.
- Repeat the loop.

## Milestone 6: Save and Load

- Serialize world state.
- Deserialize world state.
- Persist buildings, inventories, workers, and tick number.
- Show save/load status in debug UI.
