# Debug Overlay

## Requirement

Debugging is mandatory. The debug overlay can be ugly, but it must be useful.

## Required Debug Signals

The prototype should expose:

- current tick
- selected tile
- selected building
- building inventory
- worker state
- worker current task
- worker path
- pathfinding failures
- production blocked/unblocked
- save/load status

## Display Bias

Prioritize clear text and simple highlights. Debug information should help diagnose the simulation, not impress the player.

## Current Implementation Status

The first Godot client debug overlay is implemented in `src/GodotClient/Scripts/main.gd`.

Currently visible:

- compact top status strip for Wood, output, worker state, and tick
- current debug tick
- hovered tile coordinates
- selected tile coordinates
- active placement mode
- building count
- worker state
- worker tile
- worker carried Wood amount
- worker path length
- worker path line
- total Woodcutter output
- total Warehouse Wood
- latest placement, movement, save, or load result
- camera position
- zoom level

Current presentation:

- the debug UI uses warm, high-contrast panel styling rather than default Godot controls
- selected placement mode is visually distinct
- the overlay remains diagnostic and is not treated as final player UI

Not connected yet:

- selected building
- worker current task
- production blocked/unblocked

Those signals should be added as their corresponding systems are connected to the client.
