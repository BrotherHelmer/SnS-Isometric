# Backlog

**Last updated:** 2026-09-28  
**Current version:** 0.2.0-playtest.27 (shipped) / 0.2.0-playtest.28 (merged, not built)

This document contains historical prototype milestones and is maintained for reference only.

---

## Current Development Tracking

**All active work is now tracked in the repository root ROADMAP:**

→ **[ROADMAP.md](../../ROADMAP.md)**

The ROADMAP includes:
- **Current Milestone** — what we're working toward right now
- **Completed Work** — recent playtest versions (playtest.13 back through foundation)
- **Current Work** — active tasks and validation efforts
- **Prioritized Backlog** — P0/P1/P2 work with rationale
- **Known Bugs** — confirmed issues and monitoring items
- **Design Decisions Requiring Owner Input** — blockers needing Helmer's judgment
- **Release Blockers** — gates that must pass before external distribution

---

## Historical Prototype Milestones (Completed)

The milestones below represent the original Codex build brief's foundational work. They have been completed and evolved into the current production 3D game (version 0.2.0-playtest.27 shipped, playtest.28 merged).

### ✅ Milestone 1: Simulation Foundation
- Core simulation domain classes (GDScript: `one_shard_simulation.gd`, `one_shard_defs.gd`)
- Inventory, world state, and tick system
- Simulation independent of presentation layer

### ✅ Milestone 2: Isometric Client
- 3D isometric world view with camera pan and zoom
- Tile hover and selection in 3D space
- Production scene: `src/GodotClient3D/Scenes/production_3d.tscn`

### ✅ Milestone 3: Building Placement
- Placement validation in simulation
- Overlap prevention and bounds checking
- 3D building views rendered from authoritative state
- Ghost preview with valid/invalid feedback
- Build pad system for placement guidance

### ✅ Milestone 4: Worker Movement
- Autonomous carrier and production workers
- A* pathfinding over road network
- Movement state machines and path following
- Carried resource indicators

### ✅ Milestone 5: Production and Hauling Loop
- Complete resource chains: Wood → Planks, Wheat → Bread
- Local building inventories and central storage
- Physical carrier hauling between buildings
- Construction material delivery system

### ✅ Milestone 6: Save and Load
- JSON serialization of full world state
- Save format versioning (currently v6–8 supported)
- Temporary writes with backup recovery
- Autosave every 2 minutes
- Building, inventory, worker, enemy, time, claim state persistence

### ✅ Milestone 7+: Extended Production Systems
- Day/night cycle, enemy waves, defense (Watchtowers, Barracks, soldiers)
- Population, food, starvation, abandonment, restaffing
- Wyrd Pressure, Lumen connectivity, Shard Binding mechanics
- Rival realm with deterministic planning and Outpost contention
- Assault/recall commands for trained soldiers
- Victory/defeat conditions and run summary
- Opening-style 3D models (19 scenes) matching title art
- Curated CC0 audio (BGM + atmosphere foley)
- Comprehensive UI: objectives, minimap, event log, inspection, settings
- Forward+ renderer, pinned Godot 4.7, versioned exports with hash manifests
- 20-suite automated validation covering simulation, persistence, UI, rivalry

**Status:** Production game is playable end-to-end. Automated checks pass. External human validation gates remain open (see ROADMAP.md for P0 blockers).

---

For current priorities and next tasks, see **[ROADMAP.md](../../ROADMAP.md)**.
