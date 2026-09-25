# ADR 002: Simulation Separation

## Status

Accepted

## Decision

Keep simulation state separate from rendering state.

## Core Rule

Simulation owns the truth. Rendering displays the truth. Input requests changes.

## Context

Shard & Sovereign may eventually need server-authoritative simulation. Even though One Shard is local, the prototype should avoid making Godot scene nodes the source of game state.

## Consequences

- Gameplay state lives in plain C# simulation classes.
- Godot scripts send commands to the simulation.
- Godot scenes render simulation state.
- Save/load serializes simulation state, not scene tree state.
- Tests can exercise the simulation without launching the client.
