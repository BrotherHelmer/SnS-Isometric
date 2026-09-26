# Codex Build Brief: Shard & Sovereign — One Shard Vertical Slice

## Objective
Build the current Shard & Sovereign Codex/Godot prototype into a complete, playable **One Shard** vertical slice.

This is **not** the full MMO, not PvP, and not the long-term UE action-combat dream. This is the isometric Settlers-like validation game: one small province, one Town Hall, roads, workers, carriers, resource chains, food pressure, night attacks, towers, an Outpost near the Shard, and a win/loss state.

The attached Gemini HTML prototype is the mechanics reference. The existing Codex project is the implementation target. Do not blindly paste browser code. Port the design into clean Godot architecture.

---

## Current State
The current build appears to have:

- Isometric tile map rendering.
- Basic camera/panning/zoom/debug view.
- Selection state and hovered/selected tile feedback.
- UI buttons for Select, Warehouse, Woodcutter, Move, Save, Load.
- Basic resources: Wood, Output, Worker state, Tick counter.
- A single worker/debug loop.
- Save/load hooks.

Treat this as a skeleton. Keep what works, but refactor toward a real simulation architecture before adding more mechanics.

---

## Target Player Experience
A new player should be able to start a run and complete or lose it in roughly 15-25 minutes:

1. Start with a Town Hall and limited resources.
2. Build roads outward from the Town Hall.
3. Place production buildings adjacent to existing infrastructure.
4. Watch workers gather and process resources.
5. Watch carriers physically deliver materials through the road network.
6. Build houses to support more workers.
7. Feed the population through farming and baking.
8. Survive escalating night attacks from the Shard.
9. Build a Watchtower network and then an Outpost adjacent to the Shard.
10. Defend the Outpost through two nights to claim sovereignty and win.

The game must be readable without external explanation: roads connect, carriers carry, local inventories matter, disconnected buildings stall, starvation disables production, night pressure escalates, and the Shard claim is the climax.

---

## Non-Negotiable Design Rules

1. **Simulation owns truth.** Rendering and UI display state; they do not own game state.
2. **Input requests changes.** Player actions call simulation/build requests. The simulation validates and mutates state.
3. **No fake logistics.** Resources cannot simply teleport into construction or processors. Carriers must visibly move goods along valid road paths.
4. **Roads are the lifeblood.** Production buildings and construction sites must be connected to the Town Hall road network to function.
5. **Local inventories matter.** Buildings store local inputs/outputs. Central storage is the Town Hall/warehouse abstraction.
6. **Keep the scope to One Shard.** Do not add multiplayer, hero combat, factions, diplomacy, markets, or procedural expansion beyond this run structure.
7. **Readable before pretty.** Use placeholder art where necessary, but every important state must be visible.
8. **No single giant script.** Break systems into clear modules/classes/resources.
9. **Save/load must preserve a live run.** It must restore map, buildings, inventories, workers, enemies, time, objectives, and claim state.
10. **Balance for a playable loop.** The first pass should be winnable but losable.

---

## Recommended Godot Architecture

Refactor toward these responsibilities. Names can vary, but the separation should not.

### Scenes / Nodes

- `GameRoot.tscn` — owns startup, simulation tick, UI, save/load, pause, and scene wiring.
- `WorldView.tscn` / `WorldView.gd` — renders isometric terrain, buildings, workers, enemies, projectiles, overlays.
- `UIRoot.tscn` / `UIController.gd` — top bar, build bar, objectives, log, info panel, pause, summary screens.
- `FloatingTextLayer.gd` — feedback text and transient notifications.

### Simulation Modules

- `GameState.gd` — serializable state container: resources, map, buildings, workers, enemies, time, score, objectives.
- `Definitions.gd` or JSON resources — tile/building/resource definitions and costs.
- `WorldGrid.gd` — tile grid, fog of war, placement bounds, coordinate conversion helpers.
- `RoadNetwork.gd` — computes Town Hall-connected road graph and connection status.
- `Pathfinder.gd` — pathfinding over connected roads and valid target adjacency.
- `BuildSystem.gd` — placement validation, construction sites, reservations, demolition, completion.
- `ResourceSystem.gd` — central storage, local inventories, resource reservations, production conversions.
- `WorkerSystem.gd` — production workers and carriers; task assignment; movement/state machines.
- `FoodSystem.gd` — food demand, starvation, abandonment, restaffing.
- `TimeSystem.gd` — day/night cycle, night transition events.
- `CombatSystem.gd` — enemy waves, enemy movement/attacks, towers, projectiles, destruction.
- `ObjectiveSystem.gd` — tutorial objectives and completion.
- `ScoreSystem.gd` — scoring and run summary.
- `SaveSystem.gd` — JSON save/load with versioning.

Use a fixed simulation tick. Rendering may interpolate, but game state should update deterministically.

---

## Data Definitions

Implement definitions as data, not hardcoded UI branches where possible.

### Tiles

```text
GRASS
TREE
ROCK
SHARD
```

### Buildings

```text
NONE
TOWN_HALL
ROAD
HOUSE
LUMBER_CAMP
QUARRY
SAWMILL
FARM
BAKERY
WATCHTOWER
OUTPOST
CONSTRUCTION_SITE
```

### Resources

```text
wood
planks
stone
wheat
bread
population_used
population_max
```

### Starting Resources

```text
wood: 30
planks: 0
stone: 0
wheat: 0
bread: 15
population_used: 0
population_max: 5
```

### Building Costs and Staff

| Building | Cost | Staff | Effect |
|---|---:|---:|---|
| Road | 1 wood | 0 | Connects road network; reveals nearby tiles |
| House | 4 wood | 0 | +5 population cap |
| Lumber Camp | 2 wood | 1 | Produces local wood from trees |
| Quarry | 2 wood | 1 | Produces local stone from rock deposit |
| Sawmill | 4 wood, 2 stone | 1 | Converts delivered wood into planks |
| Farm | 4 wood | 2 | Produces local wheat |
| Bakery | 4 planks, 4 stone | 1 | Converts delivered wheat into bread |
| Watchtower | 4 stone, 2 planks | 2 | Shoots visible enemies |
| Outpost | 8 planks, 5 stone | 0 | +5 population cap; starts Shard claim if adjacent to Shard |

### Building HP Reference

```text
Town Hall: 500
Road: 20
Lumber Camp: 100
Farm: 100
Outpost: 250
Quarry: 150
Sawmill: 150
Bakery: 150
Watchtower: 300
House: 80
Construction Site: 50
```

---

## Core Mechanics to Implement

### 1. World Generation

Generate a 35x35 isometric map.

- Town Hall starts near the center.
- Clear a small safe area around Town Hall.
- Scatter trees and rock deposits.
- Place one Shard far enough away to require expansion.
- Add rocks around the Shard to make the final approach feel deliberate.
- Fog of war:
  - Town Hall reveals radius 7.
  - Roads reveal radius 2.
  - Completed non-road buildings reveal radius 3.

Acceptance:
- New run always has reachable trees and rocks near the early expansion area.
- Shard is not visible immediately unless fog is disabled in debug mode.

---

### 2. Camera, Selection, and Build UX

Implement clean isometric interaction.

Required:

- Pan and zoom.
- Hovered tile highlight.
- Selected tile highlight.
- Build ghost preview.
- Valid placement = green/positive feedback.
- Invalid placement = red/negative feedback with reason.
- Building info panel showing:
  - Name
  - Connected/disconnected state
  - Staffed/abandoned state
  - HP
  - Local inventory
  - Construction progress if under construction
  - Restaff button if abandoned

Acceptance:
- It must always be obvious why a placement fails.
- Clicking a building must show useful information.

---

### 3. Road Network

Implement a Town Hall-connected road graph.

Rules:

- Roads connect orthogonally.
- A building is connected if it is orthogonally adjacent to a connected road or the Town Hall.
- Road network recomputes after road placement, building demolition, or destruction.
- Disconnected production buildings do not work.
- Disconnected construction sites do not receive materials.

Acceptance:
- Build a disconnected sawmill: it does nothing and clearly says “No road connection”.
- Connect it by road: it starts receiving inputs and functioning.

---

### 4. Construction Sites and Material Delivery

Non-road buildings should not complete instantly.

Flow:

1. Player selects a building type and places it on a valid tile.
2. A construction site/scaffold appears.
3. Required materials are reserved or assigned so multiple build orders cannot double-spend the same resources.
4. Carriers deliver materials from central storage to the construction site.
5. Progress bar updates as materials arrive.
6. Building completes only when all materials have been delivered.

Roads may remain instant-build for now and cost 1 wood immediately.

Acceptance:
- Starting construction with insufficient materials fails clearly.
- Starting multiple construction sites cannot overcommit the same wood/stone/planks.
- Construction progress is visible.

---

### 5. Workers and Carriers

Production workers are tied to buildings. Carriers are logistics workers based from the Town Hall.

Worker types:

- `woodcutter`: travels to visible tree, works, returns wood to Lumber Camp local inventory.
- `miner`: works at Quarry, reduces local rock deposit, adds stone to Quarry local inventory.
- `farmer`: works at Farm, adds wheat to local inventory.
- `sawyer`: consumes local wood at Sawmill, produces local planks.
- `baker`: consumes local wheat at Bakery, produces local bread.
- `carrier`: moves resources between central storage, construction sites, processors, and output buildings.

Carrier task priority:

1. Deliver reserved construction materials to connected construction sites.
2. Deliver input materials to connected processors: wood to Sawmill, wheat to Bakery.
3. Fetch local outputs from connected buildings back to central storage.

Carrier scaling:

- Start with at least one carrier once a road/logistics need exists.
- Target carriers can scale with population cap; reference prototype used `floor(popMax / 5) * 2`.
- Do not let carrier spawning consume production population unless explicitly modeled. Keep it simple and legible.

Acceptance:
- The player can watch goods physically moving.
- Removing a road breaks carrier paths and stalls logistics.
- Destroying or demolishing a building removes its workers safely.

---

### 6. Production Chains

Implement these chains end-to-end:

```text
Tree -> Lumber Camp -> local wood -> Carrier -> central wood
Rock deposit -> Quarry -> local stone -> Carrier -> central stone
Central wood -> Carrier -> Sawmill local wood -> planks -> Carrier -> central planks
Farm -> local wheat -> Carrier -> central wheat
Central wheat -> Carrier -> Bakery local wheat -> bread -> Carrier -> central bread
Central resources -> Carrier -> Construction Site -> completed building
```

Acceptance:
- The player can build a Sawmill only after generating stone.
- The player can build a Bakery only after generating planks and stone.
- The Outpost requires the full economy to function.

---

### 7. Population, Food, Starvation, and Restaffing

Rules:

- Houses add +5 population cap.
- Outpost also adds +5 population cap.
- Production/defense buildings consume staff population.
- Food is consumed every 15 seconds.
- Food demand = `ceil(population_used / 2)` per food tick.
- During night, food demand is doubled.
- Bread is consumed first.
- If no bread is available, wheat can be consumed at a worse rate.
- If food demand cannot be met, one staffed non-house building becomes abandoned.
- Abandoned buildings stop production and release their staff population.
- Player can restaff if enough population is available.

Acceptance:
- Starvation should hurt but not instantly end the run.
- Abandoned state must be visible on the map and in the info panel.

---

### 8. Day/Night Cycle and Threat

Reference timing:

```text
Day length: 240 seconds
Night length: 120 seconds
Food tick: every 15 seconds
```

At night:

- Screen visibly darkens.
- Warning is shown before night starts.
- Enemy wave spawns from the Shard.
- Workers except carriers can sleep/stop during night unless this hurts readability; prioritize clear balance.
- Food consumption doubles.

Enemy wave reference:

```text
wave_size = day_count * 3 + 4
if claiming: wave_size += 10
enemy_hp = 50 + day_count * 15
enemy_damage = 15
```

Enemy targeting:

- If Shard claim is active, enemies prioritize the claim Outpost.
- Otherwise, enemies target the nearest valuable building, falling back to the Town Hall.
- If the Town Hall is destroyed, the run ends in defeat.

Acceptance:
- Night 1 should be survivable with poor/no defense but still threatening.
- Later nights should force towers and better road planning.

---

### 9. Defense

Implement Watchtowers.

Rules:

- Watchtower requires road connection and staff.
- It targets visible enemies within range.
- Reference range: 7 tiles.
- Reference projectile damage: 15.
- Show projectiles or clear attack feedback.

Acceptance:
- Towers visibly shoot enemies.
- Disconnected or abandoned towers do not fire.

---

### 10. Shard Claim and Victory

Rules:

- Outpost can be built normally anywhere valid.
- If an Outpost completes adjacent to the Shard, Shard claim starts.
- Claim requires surviving two nights while the Outpost remains alive.
- During claim, enemy waves are larger and prioritize the Outpost.
- If the Outpost is destroyed or demolished, claim fails/cancels.
- After surviving two claim nights, victory screen appears.

Acceptance:
- The player understands claim progress: `Survived 0/2`, `1/2`, `2/2`.
- Victory screen shows score and run summary.

---

### 11. Objectives, Log, Notifications, and Summary

Implement onboarding objectives:

```text
Build a Road from Town Hall
Build Lumber Camp and wait for carrier logistics
Build a House for Population
Build an Outpost near the Shard
```

Implement realm log:

- Construction started/completed.
- Objective completed.
- Night warning.
- Enemy attack / building destroyed.
- Starvation / abandoned building.
- Claim started / claim progress / victory / defeat.

Implement summary screens:

- Victory: “Sovereignty Claimed!”
- Defeat: “The Realm Has Fallen.”
- Show score, best score, days survived, buildings completed, enemies defeated, buildings abandoned, buildings destroyed, Shard claimed.

Acceptance:
- Player should always understand what happened and why.

---

### 12. Save/Load

Save to local user storage in JSON.

Must save:

- Version number.
- RNG seed if used.
- Map tiles and fog state.
- Rock deposits.
- Buildings, HP, disabled/abandoned state.
- Construction queue and reserved materials.
- Central resources and local building inventories.
- Workers, tasks, positions, states, carried resources.
- Enemies, HP, targets/positions.
- Projectiles if active.
- Day/night/time/tick.
- Claim state.
- Objectives and log.
- Score stats.

Acceptance:
- Save during night attack, quit, load, and continue correctly.
- Save during construction, load, and carriers continue delivery.
- Save during claim, load, and claim progress remains correct.

---

## Polish Requirements

Do not treat polish as optional. The prototype must not feel vibe-coded.

Minimum polish:

- Distinct terrain: grass, trees, rocks, Shard.
- Distinct buildings, even if placeholder low-poly/simple sprites.
- Visible workers and carriers with carried resource indicators.
- Clear building icons/status overlays.
- Construction progress bars.
- HP bars when damaged.
- Red danger flash/overlay when structures are attacked.
- Night overlay.
- Good invalid-action messages.
- UI should work at 1280x720.
- Debug panel can exist, but the default experience should look like a game, not a tech test.

---

## Implementation Order

Do this in small, verifiable steps. After each milestone, run the project and fix errors before continuing.

### Milestone 0 — Audit and Refactor Plan

- Inspect the current repo.
- Identify current scenes/scripts/resources.
- Create or update `IMPLEMENTATION_PLAN.md` with the planned file changes.
- Keep existing working rendering/input if it is usable.
- Do not rewrite the entire project blindly.

### Milestone 1 — State and Definitions

- Add data definitions for tiles, resources, buildings, costs, HP, staff requirements.
- Add serializable `GameState`.
- Add fixed tick simulation loop.
- Preserve existing debug tick display if useful.

### Milestone 2 — Map, Camera, Fog, Selection

- Implement stable map generation.
- Add fog of war.
- Add hover/selection/build ghost.
- Add camera pan/zoom.

### Milestone 3 — Roads and Building Placement

- Implement placement validation.
- Implement roads and connected-road graph.
- Implement construction sites and demolition.
- Show invalid reasons.

### Milestone 4 — Inventories, Construction Delivery, Carriers

- Implement central storage and local inventories.
- Implement material reservation.
- Implement carriers and road pathfinding.
- Complete buildings only through delivered materials.

### Milestone 5 — Production Chain

- Lumber Camp, Quarry, Sawmill, Farm, Bakery.
- Workers produce into local inventories.
- Carriers fetch outputs and supply processors.

### Milestone 6 — Population and Food

- Houses and Outpost population cap.
- Staff requirements.
- Food tick and starvation.
- Abandon/restaff behavior.

### Milestone 7 — Night, Enemies, Towers

- Day/night cycle.
- Enemy waves from Shard.
- Enemy pathing/attacks.
- Watchtower targeting and projectiles.
- Damage/destruction/loss state.

### Milestone 8 — Shard Claim, Victory, Summary

- Outpost adjacency to Shard starts claim.
- Survive two nights.
- Victory/defeat summary and score.

### Milestone 9 — Save/Load and UX Pass

- Robust JSON save/load.
- Pause/menu/resume.
- Objective panel, realm log, notifications, info panel.
- Balance pass for 15-25 minute run.

---

## Testing Checklist

Before considering the build done, verify manually:

- New game starts with no errors.
- Roads cost wood and connect correctly.
- Disconnected buildings show as disconnected and do not function.
- Construction site receives carrier deliveries and completes.
- Wood becomes planks through Sawmill.
- Wheat becomes bread through Bakery.
- Population cap and population used update correctly.
- Food demand updates and starvation disables a building.
- Restaffing works.
- Night starts, enemies spawn, enemies damage buildings.
- Towers shoot enemies only when staffed and connected.
- HQ destruction triggers defeat.
- Outpost next to Shard starts claim.
- Claim survives two nights and triggers victory.
- Save/load works in normal play, during construction, during night combat, and during claim.
- UI remains usable at 1280x720.

---

## Definition of Done

The vertical slice is done when:

1. A player can start a run, learn the loop, and reach victory or defeat without developer guidance.
2. The simulation is visibly logistics-driven, not just counters changing.
3. There is a real strategic arc: expand, produce, feed, defend, claim.
4. Save/load works.
5. There are no critical runtime errors in a normal 20-minute run.
6. The code is modular enough that adding provinces, more buildings, or richer visuals later will not require a rewrite.

---

## Tone Reminder

This should feel like founding a realm at the edge of a dangerous world:

> Build the kingdom. Connect the roads. Feed the workers. Hold the night. Claim sovereignty.
