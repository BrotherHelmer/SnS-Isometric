# One Shard Visual Direction

## Decision

Keep the isometric camera. The failed feeling came from static systems, invisible labor, flat debug geometry, and inconsistent scale, not from isometric projection itself.

The target is an original 1990s Amiga-era settlement: broad 96x48 terrain spacing, warm medieval buildings, readable resource piles, and many small people visibly doing useful work. This is a tonal reference, not a copy of any Settlers asset or layout.

## Reference Images

- `concepts/amiga_settlement_direction.png`: target scene density, color, UI restraint, visible jobs, and settlement charm.
- `concepts/buildings_atlas_direction.png`: target silhouettes and material language for the production building set.
- `current_gameplay_capture.png`: current in-engine checkpoint after the first terrain, worker, logistics, and UI pass.
- `current_night_capture.png`: night readability, sheltered civilians, active guards, and the Shard threat.
- `current_hunger_capture.png`: the morning hunger marker and reduced-production state.
- `current_log_capture.png`: the expanded in-game Realm Chronicle.

## Rules

- Keep a strict 2:1 isometric grid and nearest-neighbor texture filtering.
- Use one authored palette across terrain, buildings, workers, resources, and effects.
- Make every staffed job visible in the world.
- Show goods at their source, in transit, and at their destination.
- Prefer readable silhouettes and animation over surface detail.
- Keep the UI compact, warm, and secondary to the settlement.
- Do not use imported assets that conflict with the medieval settlement direction.

## Integrated Art Pass

- Nine transparent, role-scaled building sprites now use the concept atlas language, including a new Shard-warded Outpost.
- The Shard and night raider have matching authored sprites instead of debug geometry.
- The landscape uses a continuous grass surface, larger ground scale, clear work yards, and narrow earth lanes instead of a visible checkerboard.
- Settlers and night raiders use four-frame direction-aware walk cycles at a calmer simulation pace.
- Raiders remain hidden in fog when they spawn and no longer expose the Shard by appearing on it.
- Houses and the Town Hall show warm occupancy lights at night.
- Local stock, hunger, health, damage, staffing failure, and road disconnection remain readable overlays.

## Next Art Pass

1. Add profession-specific work cycles and dedicated carrying poses.
2. Replace colored stock markers with individual stone, wood, wheat, plank, and bread piles.
3. Add small ambient loops: chimney smoke, wheel rotation, sawing, mining, crop movement, and flags.
4. Add directional attack and hit frames for the night raider and guards.
5. Recheck readability at minimum and maximum camera zoom after animation is present.
