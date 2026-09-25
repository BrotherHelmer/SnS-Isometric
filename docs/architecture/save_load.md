# Save and Load

## Goal

The world is serializable to a local save file and restorable without hidden scene state.

## State To Persist

- tick number
- map dimensions
- buildings
- building positions
- building inventories
- woodcutter output inventory
- workers
- worker positions
- worker carried resources
- worker source and destination building ids, if present

## Current Implementation

The simulation layer uses explicit JSON save contracts:

- `WorldSaveData`
- `BuildingSaveData`
- `WorkerSaveData`
- `WorldSaveService`

`WorldSaveService` can serialize/deserialize in memory and save/load from a local file path.

The Godot debug shell has Save and Load buttons. The shell writes to:

```text
user://one_shard_save.json
```

The Godot save mirrors the current prototype state:

- version
- map size
- next building id
- tick number
- building type, id, position, footprint
- warehouse Wood inventory
- woodcutter output inventory
- woodcutter production timer
- Carrier position
- Carrier carried Wood amount
- Carrier source and destination ids

## Format

Use readable JSON with explicit fields. Do not serialize Godot scene nodes or rendering-only state.

## Worker Path Simplification

Active worker paths are not persisted. Loaded workers reset to `Idle` and rebuild their next path from restored simulation state on the next tick.

This is intentional for the first local save/load slice and is tracked in `docs/technical_debt.md`.
