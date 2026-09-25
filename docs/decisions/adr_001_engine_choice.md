# ADR 001: Engine Choice

## Status

Accepted

## Decision

Use Godot 4 with C# for the One Shard prototype.

## Context

The prototype needs fast iteration, isometric 2D/2.5D support, a practical editor, and code that can stay readable under AI-assisted development.

## Rationale

Godot 4 with C# is a good fit because:

- it supports fast local iteration
- it is lighter than Unreal for this vertical slice
- it works well for isometric 2D/2.5D prototypes
- C# encourages clearer domain models than loosely structured scripts
- simulation logic can live outside rendering code

## Consequences

- The Godot client should remain a display/input layer.
- Core simulation classes should avoid Godot-specific base classes.
- The first milestone can be built without opening the Godot editor.
