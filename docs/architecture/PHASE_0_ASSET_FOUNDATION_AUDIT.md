# Shards & Sovereign Phase 0: Asset Foundation and Rebuild Architecture

**Audit date:** 2026-08-21  
**Engine target:** Godot 4.7  
**Recommendation:** **PARTIAL REBUILD**

## Executive decision

Replace the presentation layer, not the game.

The current playable build has a worthwhile settlement simulation: deterministic map generation, multi-cell placement, construction delivery, local inventories, five-resource production, population and hunger, autonomous production workers and carriers, road-weighted pathfinding, day/night raids, combat, rivalry AI, claim rules, diagnostics, and versioned saves. Re-implementing all of that at the same time as the visual conversion would create unnecessary risk.

The current presentation is the part that has reached its architectural limit. The shipped scene is a six-line `Node2D` scene. A 4,072-line `main.gd` creates the camera and UI in code, handles input, preloads raw sprites, performs coordinate transforms, and manually draws most of the world. The static layer is another manual `Node2D` renderer. Neither layer is a suitable foundation for a scene-based 3D world.

The active simulation is also not as clean as the repository's early architecture documents imply. The running game uses a 5,711-line GDScript simulation and a 1,873-line rivalry module. The separate C# library is an older, unused two-building prototype. The running GDScript simulation is separated from rendering well enough to survive the first visual migration, but it relies heavily on mutable dictionaries, string states, square-cell coordinates, and a monolithic update loop. It should be refactored behind stable interfaces as the 3D view is introduced, not rewritten in one pass.

The recommended destination is:

> **Hidden square logical grid + continuous 3D terrain + snapped building footprints + logical road graph + smooth visual paths/local avoidance.**

Do not expose KayKit hex terrain as the governing world structure. KayKit should supply the art language, not dictate the simulation topology.

## Audit basis and important caveats

### Repository state inspected

- Entry point: `src/GodotClient/Scenes/main.tscn`
- Active presentation/input/UI: `src/GodotClient/Scripts/main.gd`
- Static world rendering: `src/GodotClient/Scripts/static_world_layer.gd`
- Active settlement simulation: `src/GodotClient/Scripts/one_shard_simulation.gd`
- Active building/economy definitions: `src/GodotClient/Scripts/one_shard_defs.gd`
- Active rivalry simulation: `src/GodotClient/Scripts/one_shard_rivalry.gd`
- Rivalry tuning: `src/GodotClient/Scripts/one_shard_rivalry_tuning.gd`
- Earlier unused adapter: `src/GodotClient/Scripts/client_simulation.gd`
- Earlier unused C# simulation: `src/Simulation/`
- C# test harness: `tests/SimulationTests/`
- Godot smoke suites: `tests/godot_rebuild_smoke.gd`, `tests/godot_construction_smoke.gd`, and `tests/godot_rivalry_smoke.gd`

The worktree already contains a large uncommitted replacement of an older prototype. This audit treats the files currently on disk as the product baseline and does not try to restore the deleted legacy scene/script tree.

### KayKit contents actually present

`assets/Kaykit` currently contains only three distributions of **KayKit Medieval Hexagon Pack 1.0**:

| Package | Unpacked files | Approximate size | Notes |
| --- | ---: | ---: | --- |
| FREE | 1,473 | 61.7 MB | Subset; multiple interchange formats |
| EXTRA | 2,768 | 105.2 MB | Full runtime exports; multiple interchange formats |
| SOURCE | 2,769 | 139.3 MB | Same runtime exports plus one Blender source file |

Each unpacked package includes a local `License.txt` declaring the pack **CC0** and explicitly permitting commercial use. Preserve that license with the curated runtime assets and add KayKit to `docs/THIRD_PARTY_NOTICES.txt` before any distributable includes KayKit content.

The following asset packs named in the Phase 0 brief are **not present** in the supplied folder:

- KayKit Character Animations
- KayKit Character Pack: Adventurers
- KayKit Mystery Monthly Series 6 farmer characters
- KayKit Forest Nature Pack
- KayKit Resource Bits
- KayKit RPG Tools Bits

The Medieval pack's `units` are unrigged board-style pieces, not substitutes for those character packs. Sample GLTF inspection found zero animation clips. Representative native bounds also show why a cross-pack scale calibration is mandatory:

| Asset | Native bounds, approximately | Animation clips |
| --- | --- | ---: |
| Town Hall | 1.44 × 1.89 × 1.56 | 0 |
| Home A | 0.79 × 0.93 × 0.85 | 0 |
| Neutral unit token | 0.20 × 0.34 × 0.20 | 0 |
| Tree A | 0.57 × 1.20 × 0.55 | 0 |
| Grass hex | 2.00 × 1.00 × 2.31 | 0 |

No animated-character proof can be truthfully completed from the current asset folder. Phase 1 must begin by adding and licensing the missing character/animation/tool packs.

The three unpacked distributions also duplicate the same assets as FBX, OBJ, and GLTF, while the ZIP archives remain beside them. Keeping all of these below `res://` invites slow imports, repository bloat, and accidental use of the wrong variant. Curate one runtime format and keep source-only files below a `.gdignore` boundary.

### Verification status

- The existing C# harness executed successfully in Release configuration: **28/28 tests passed**.
- The Godot rebuild, construction, and rivalry smoke suites could not be executed in this environment. The local Godot 4.7 console executable crashed in native engine code with signal 11 before producing any test output.
- The same native crash occurred in an isolated project copy containing only the current game scripts and settlement assets, so it cannot be attributed specifically to the new KayKit folder or to a test assertion.
- This audit therefore records the Godot suites as **not run — engine/tooling crash**, not as simulation failures. Resolving the local Godot 4.7 headless/editor stability issue is a Phase 1 entry gate.

## Current architecture assessment

### Scene hierarchy and presentation

The main scene contains only a scripted `Node2D`. At runtime `main.gd` creates a `Camera2D`, static render layer, UI, audio players, menus, and overlays. Buildings, workers, terrain, roads, attacks, resources, shadows, and VFX are predominantly drawn from `_draw()` calls rather than represented by reusable scenes.

Consequences:

- There is no reusable building, character, environment, or VFX scene boundary.
- Raw art paths are preloaded directly in `main.gd` and `static_world_layer.gd`.
- Selection, input, camera, world rendering, UI construction, formatting, audio playback, and presentation animation share one script.
- The view reaches into simulation internals and private-style methods in several places.
- A 3D conversion cannot be achieved by swapping textures; the view hierarchy must be replaced.

### World, grid, placement, and paths

The active map is a seeded 70 × 70 square microtile array. It has four terrain identifiers (`GRASS`, `TREE`, `ROCK`, and `SHARD`) and a separate integer height array from 0 to 3. Terrain generation is deterministic and intentionally clears/levels authored settlement, rival, corridor, and claim areas after procedural resource scattering.

Building placement already has valuable rules:

- multi-cell, rotatable footprints;
- map, fog, occupancy, terrain, enemy-camp, rivalry, and slope checks;
- one-cell work-yard clearance for most buildings;
- quarry/resource requirements;
- road, wall, tower, Lumen, and Shard connectivity requirements;
- cost reservation, construction sites, physical delivery, build time, and completion.

Movement is four-directional. General worker/enemy routing uses a cached `AStarGrid2D`, with roads assigned a lower travel cost. Carrier logistics also use a road-only breadth-first search. The path grid is rebuilt when world occupancy or relevant terrain changes. Visual movement interpolates between cell positions; agents do not have independent collision, crowd flow, or local steering.

### Simulation and building data

The running simulation is non-rendering GDScript, which is a useful seam. It owns authoritative time, world cells, elevations, resources, buildings, workers, enemies, logistics, construction, production, combat, objectives, and saves. Rivalry rules are in a separate module and expose command-shaped APIs for roads, structures, extraction, attacks, and claims.

The weakest structural areas are:

- a 5,711-line settlement authority with many responsibilities;
- mutable dictionaries as every entity type;
- free-form string states used by both simulation and rendering;
- duplicated definitions between settlement and rivalry modules;
- UI/view code reading public arrays and private-style helpers;
- test-only smoke helpers embedded in the production simulation file;
- no standalone task/job model despite increasingly complex worker behavior.

`one_shard_defs.gd` is data-driven in spirit, but costs, footprints, HP, staffing, production, and UI names are parallel dictionaries. Adding approximately 20 buildings will amplify consistency errors unless they become validated definitions.

### Worker and military behavior

The prototype already shows carriers, production workers, clearers, miners, farmers, sawyers, bakers, guards, rival workers, multiple enemy archetypes, and Sovereigns. Worker state drives simple sprite selection and procedural tool overlays. This proves the simulation-to-presentation idea, but not the required 3D animation system.

The current UI permits selecting a worker and directly issuing move/gather orders. The player also directly moves the Sovereign with WASD/click-to-move and triggers attacks. That conflicts with the new requirement that workers and assigned military units act autonomously. Selection can remain for inspection, but per-unit movement and attack command paths must not become the new control model. If direct Sovereign control is still desired as a special exception, it needs an explicit product decision rather than leaking into the general unit architecture.

### Economy and combat

The most mature and reusable behavior is in:

- local output inventories and finite central storage;
- reservation and in-transit accounting;
- construction delivery;
- carrier pickup/dropoff and retry behavior;
- lumber, quarry, farm, sawmill, and bakery chains;
- staffing, housing, food, hunger, and recovery;
- day/night transitions, camps, raids, target selection, walls, gates, towers, projectiles, soldiers, and patrols;
- separate rivalry ledgers, deterministic AI, Lumen connectivity/upkeep, and claim state.

These rules are visually independent. Their behavior should survive the rebuild and be covered by regression tests while their representation is gradually typed and decomposed.

### Persistence

The running game writes version-7 JSON and persists the generated map, elevations, resources, buildings, workers, enemies, objectives, combat/run state, and serialized rivalry state. Versions below 6 are explicitly rejected. The old C# serializer uses a separate version-1 schema and is not used by the game.

The view-only 3D migration does not require a save-version change. A later world-schema change must use an explicit migrator; visual scene paths, imported asset paths, transforms, animation playback state, and transient navigation paths must never become authoritative save fields.

## KEEP / REFACTOR / REPLACE / REMOVE decisions

Classification applies to the current implementation, not merely the design idea.

| Subsystem | Decision | What survives / what changes |
| --- | --- | --- |
| Settlement/economy rules | **KEEP** | Preserve construction delivery, inventories, carriers, production, staffing, housing, hunger, and time rules as the behavior baseline. Add regression coverage before structural changes. |
| Rivalry AI and claim rules | **KEEP** | Preserve deterministic planner, isolated ledgers, Lumen, disruption, and claim conditions. Keep behind command/query APIs. |
| Audio content and event intent | **KEEP** | Preserve music, ambience, and semantic SFX events. Route world sounds through 3D audio anchors later. |
| Diagnostics, run journal, behavioral smoke coverage | **KEEP** | Preserve as migration safety rails. Move test-only helpers out of production code over time. |
| Seeded map-generation intent | **REFACTOR** | Preserve determinism, fair authored clearings, resource clusters, and seed logging. Produce typed biome/elevation/water data and continuous terrain chunks instead of a drawn diamond surface. |
| Hidden logical grid | **REFACTOR** | Retain square coordinates and occupancy for simulation. Introduce a `WorldGrid`/coordinate service, typed cell data, buildability masks, access points, and world-position conversion. Never render the grid by default. |
| Terrain presentation | **REPLACE** | Replace manually drawn diamonds/cliffs with continuous 3D chunk meshes, natural material blending, water, shore treatment, and instanced foliage/rocks. |
| General pathfinding | **REFACTOR** | Keep authoritative high-level route semantics and road cost. Abstract path queries, batch/cache requests, and add visual smoothing/local avoidance. Do not make one `NavigationAgent3D` query every frame. |
| Road network | **REFACTOR** | Preserve owned connectivity and movement bonus. Render a graph as joined dirt ribbons/meshes with natural bends and junctions; add logical access/lanes. |
| Building placement | **REFACTOR** | Preserve command validation and footprint rules. Add typed definitions, art bounds/pivots, door/access offsets, slope/foundation adaptation, 3D ray picking, and a scene-based build ghost. |
| Building definitions | **REFACTOR** | Replace parallel dictionaries with validated definition resources/data. Separate gameplay definition from presentation definition and raw art. |
| Worker/task logic | **REFACTOR** | Preserve autonomous job selection, logistics, sheltering, production, and patrol behavior. Replace string/dictionary state with semantic states and explicit jobs/tasks. Remove general direct unit orders. |
| Combat implementation | **REFACTOR** | Preserve autonomous targets, damage, towers, waves, patrols, and projectiles. Drive semantic animation events; make assigned military autonomous. Resolve direct Sovereign control separately. |
| Save/load | **REFACTOR** | Preserve versioning and v7 compatibility during Phase 1. Add migrators and stable IDs; exclude view/transient navigation state. Retire the separate unused C# schema. |
| Active scene hierarchy | **REPLACE** | Replace the flat `Node2D` runtime-built world with a composed `Node`/`Node3D` scene tree and reusable view scenes. |
| Rendering and camera | **REPLACE** | Replace `CanvasItem._draw`, sprites, `Camera2D`, and manual isometric projection with `Camera3D` orthographic projection, 3D scenes, lighting, shadows, and LOD/instancing. |
| Selection/input | **REFACTOR** | Replace 2D coordinate inversion with 3D ray/ground picking. Keep building placement and inspection. Remove worker move/gather and ordinary soldier attack/move commands. |
| UI implementation | **REFACTOR** | Preserve useful information architecture and world-state queries, but move programmatic UI into authored Control scenes and view-model/presenter adapters. Replace direct raw-art thumbnails. |
| `static_world_layer.gd` | **REPLACE** | Its caching lesson is useful; the manual renderer is not. Use terrain chunks, batched MultiMeshes, and view registries. |
| `client_simulation.gd` | **REMOVE** | It is an obsolete duplicate and is not used by the active entry scene. Remove only after confirming no test/tool references remain. |
| Old C# simulation and version-1 saves | **REMOVE** | Do not expand a second authority. Port any uniquely valuable tests/contracts, then archive or delete the unused library in a later cleanup change. Do not do this during the visual proof. |
| Current 2D settlement art/preloads | **REMOVE** | Retain only as visual/regression reference until the 3D gate passes, then remove from runtime/export. Do not mix it into the final 3D world. |

## World architecture options

| Option | Strengths | Costs / failure modes | Decision |
| --- | --- | --- | --- |
| Visible hex terrain | Fastest way to use pack terrain; clear adjacency | Strong board-game appearance; dictates settlement spacing; discards current square logic; asset-driven rather than game-driven | Reject |
| Hidden logical hex + natural terrain | Organic adjacency and radial expansion | Rewrites placement, footprints, paths, roads, saves, AI assumptions, and tests with no demonstrated gameplay gain | Reject for now |
| Visible or purely square grid | Best preservation and deterministic rules | A visible checkerboard repeats the current visual weakness; hard cell corners can make roads artificial | Use only as hidden logic |
| Fully free-positioned 3D + snapped buildings | Natural composition and roads | Weak deterministic occupancy, expensive save/path/crowd rules, more placement edge cases | Reject as authority |
| Navigation-only simulation | Smooth movement and flexible terrain | Couples authoritative behavior to Godot nav synchronisation and mutable meshes; poor headless determinism; path-query spikes | Reject as sole authority |
| **Hidden square grid + continuous terrain + road graph + navigation-assisted presentation** | Preserves mature rules and saves; natural visual surface; scalable placement; smooth worker presentation; asset-independent | Requires a clean coordinate/definition seam and two levels of movement responsibility | **Recommend** |

### Recommended world model

1. Keep a hidden square logical grid. Each cell stores elevation sample(s), biome, water/buildability, resource deposit, occupancy, road/wall edges, and region/chunk ID.
2. Represent buildings with stable IDs, an anchor cell, quarter-turn rotation, logical footprint, access offsets, and work sockets. The simulation owns these values.
3. Generate continuous terrain chunks from the logical height/biome field. Hide cell boundaries with interpolated geometry, material variation, foliage, rocks, and decals.
4. Treat water as a continuous world layer with shore meshes/decals and water-specific build rules. Do not assemble the main coastline from visible hex bases.
5. Keep roads as a logical graph connected to building access points. Render graph edges as joined dirt ribbons or a small modular mesh system with smoothed corners, ruts, junctions, and prop dressing.
6. Keep task and high-level route choice deterministic in the simulation. Convert logical routes to world waypoints. The character view follows those waypoints with interpolation and optional low-cost local avoidance/crowd offsets.
7. Use `NavigationServer3D`/path query objects only where free local movement adds value, such as yard entry, combat positioning, or shoreline/obstacle detours. Do not make it the economic truth and do not repath every agent every frame.
8. Partition terrain, foliage MultiMeshes, path data, and view synchronisation into chunks so culling and updates remain bounded.

This architecture retains square save coordinates and current placement semantics while making the visible world feel continuous. A future hex experiment remains possible behind the grid interface, but there is no evidence today that it would improve the game enough to justify the migration cost.

## Recommended rendering and camera architecture

### Scene composition

```text
GameRoot (Node)
├── SimulationHost
├── PresentationAdapter
├── WorldView3D (Node3D)
│   ├── TerrainChunks
│   ├── Water
│   ├── RoadViews
│   ├── BuildingViews
│   ├── CharacterViews
│   ├── ResourceVisuals
│   ├── EnvironmentInstances
│   ├── VFX
│   └── NavigationPresentation
├── IsometricCameraRig (Node3D)
│   └── Camera3D
├── LightingRig
│   ├── WorldEnvironment
│   └── DirectionalLight3D
├── AudioRoot
└── UI (CanvasLayer)
```

`PresentationAdapter` is the only layer allowed to translate simulation states/IDs into view commands. A building or character scene never becomes authoritative game state.

### Camera

- `Camera3D` with orthographic projection.
- Fixed yaw of approximately 45° and downward pitch of approximately 35–40°. Start at the mathematically familiar 35.264° and adjust within that range only after a readability comparison.
- No player orbit in normal play. Pan on the XZ ground plane and zoom by changing orthographic size, not node scale.
- Clamp to terrain bounds with a small overscroll allowance.
- Keep optional focus commands for Town Hall, alerts, and selected/inspected entities.
- At the standard 1080p gameplay zoom, a worker and carried load must be identifiable without a selection ring. Target roughly 28–44 vertical pixels for the character silhouette, then validate with the real rigs.
- Use a wider strategic zoom with simplified animation/shadow LOD and a closer observational zoom that exposes work animation and props.

### Lighting and performance

- Prefer the Forward+ renderer for the desktop commercial target; keep Compatibility only as a deliberate fallback profile.
- One primary `DirectionalLight3D`, restrained ambient/fill from `WorldEnvironment`, soft but readable contact shadows, and a consistent sun direction that does not hide building entrances.
- Use a limited number of shadow-casting tiers. Important buildings and near characters cast shadows; far foliage and small props use cheaper/no shadows.
- Use shared atlas materials and avoid per-instance material duplication.
- Use chunked `MultiMeshInstance3D` groups for trees, bushes, grasses, rocks, and repeat props. Chunking matters because a MultiMesh is culled as one object.
- Give skinned characters distance-based animation/update LOD. Spread expensive navigation and job queries across frames/ticks.
- Use subtle ambient occlusion/contact shading, color grading, and fog; avoid effects that reduce small-character readability.

Godot's official documentation supports the selected primitives: `AnimationTree` is the advanced transition layer over imported `AnimationPlayer` clips, `NavigationAgent3D` does not move its parent automatically and should not be treated as simulation authority, and MultiMesh trades individual culling for low draw-call overhead. See the [AnimationTree guide](https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html), [NavigationAgent guide](https://docs.godotengine.org/en/latest/tutorials/navigation/navigation_using_navigationagents.html), and [MultiMesh guide](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html).

## 3D orthographic proof specification

No proof scene was added in Phase 0 because the required rigged character and animation packs are absent. A static-only scene would falsely appear to validate the highest-risk part of the direction. The first Phase 1 deliverable must therefore be a contained, removable `phase1_3d_lab` scene with the following scope.

### Required contents

- Continuous grass terrain with at least one gentle height transition and no visible grid/hex outlines.
- One water edge with readable shore treatment.
- A connected dirt path with a bend and junction.
- KayKit Town Hall, home, lumbermill, mine, watchtower, and docks, each through an SnS wrapper scene.
- At least 250 instanced trees/rocks/ground details split across spatial chunks.
- At least 24 rigged KayKit characters using the common rig and shared animation library.
- Visible examples of Idle, Walk, Run, Carry, Chop, Hammer, Mine, Melee, Hit, and Die; tools and carried goods attached to sockets.
- Fixed orthographic camera, pan, clamped zoom, and focus command.
- Day lighting, useful shadows, smoke/dust/chop impact VFX, and one animated water treatment.
- A minimal CanvasLayer overlay showing current orthographic size, selected scale profile, character screen height, draw calls, frame time, and active animation count.

### Acceptance criteria

1. Buildings, characters, foliage, tools, and props share one credible scale profile with no per-instance emergency scaling.
2. A worker's profession and carried resource are readable at standard 1920 × 1080 gameplay zoom.
3. Building doors and logical access points align with character feet and road endpoints.
4. The standard view reads as a continuous landscape, not a hex board or checkerboard.
5. Camera rotation remains fixed; zoom never clips tall buildings or loses the settlement bounds.
6. Twenty-four animated characters, 250+ environment instances, shadows, water, and VFX sustain 60 FPS on the current development machine. Capture CPU frame, GPU frame, draw calls, object count, and video memory rather than reporting FPS alone.
7. A burst of path requests is staggered/cached and produces no visible frame spike.
8. Screenshots at 1280 × 720 and 1920 × 1080 pass a side-by-side readability review at minimum, normal, and maximum gameplay zoom.
9. The scene references only SnS wrapper scenes/catalog entries, never raw KayKit paths from gameplay/view-controller code.

Failure of character scale/rig compatibility, standard-zoom readability, or the performance gate pauses the broader rebuild and triggers a focused asset/animation correction. It does not trigger a world-simulation rewrite.

## Asset abstraction layer

### Required dependency direction

```text
KayKit source/export
        ↓
Curated normalized vendor model/material
        ↓
SnS art scene (pivot, scale, materials, sockets, VFX anchors)
        ↓
Presentation definition/catalog entry
        ↓
Generic runtime view bound to simulation entity ID
```

Example:

```text
KayKit building_mine_blue
        ↓
assets/third_party/kaykit/runtime/medieval/buildings/mine.glb
        ↓
art/scenes/buildings/sns_building_mine.tscn
        ↓
art/definitions/buildings/mine_presentation.tres
        ↓
BuildingView3D(entity_id, visual_id="building.mine")
```

The simulation stores `BuildingType.Mine`, stable entity ID, anchor cell, rotation, construction state, and inventories. It does not store or load `.glb`, `.tscn`, material, animation, or VFX paths.

### Proposed directory structure

```text
assets/
├── third_party/
│   └── kaykit/
│       ├── LICENSES/
│       │   └── medieval_hexagon_1_0_CC0.txt
│       ├── source/                       # contains .gdignore
│       │   ├── medieval_hexagon_1_0/
│       │   ├── character_animations/
│       │   ├── adventurers/
│       │   ├── mystery_series_6/
│       │   ├── forest_nature/
│       │   ├── resource_bits/
│       │   └── rpg_tools_bits/
│       └── runtime/                      # curated exports only
│           ├── medieval/
│           ├── characters/
│           ├── animations/
│           ├── nature/
│           ├── resources/
│           └── tools/
├── sns/
│   ├── source/                           # editable Blender sources; .gdignore
│   ├── models/                           # exported SnS-modified GLB
│   ├── materials/
│   │   ├── palettes/
│   │   ├── buildings/
│   │   ├── terrain/
│   │   ├── water/
│   │   └── characters/
│   ├── animations/
│   │   ├── common_rig/
│   │   ├── libraries/
│   │   └── retarget_profiles/
│   ├── textures/
│   └── vfx_textures/
art/
├── definitions/
│   ├── buildings/
│   ├── characters/
│   ├── resources/
│   ├── props/
│   └── environment/
├── scenes/
│   ├── buildings/
│   ├── characters/
│   ├── resources/
│   ├── props/
│   ├── environment/
│   └── vfx/
└── catalogs/
    ├── building_visual_catalog.tres
    ├── character_visual_catalog.tres
    └── tool_visual_catalog.tres
src/GodotClient/
├── Scenes/
├── Presentation/
│   ├── PresentationAdapter.gd
│   ├── WorldView3D.gd
│   ├── BuildingViewRegistry.gd
│   └── CharacterViewRegistry.gd
├── Camera/
├── Input/
└── UI/
```

### Import rules

1. Do not keep FREE, EXTRA, and SOURCE runtime duplicates together below the project importer.
2. Keep original ZIPs and Blender/source interchange formats outside runtime import, preferably outside the repository or below `.gdignore`.
3. Export one approved format, preferably GLB, from a repeatable Blender/export preset. Do not rely on live `.blend` import for release builds.
4. Normalise axis, scale, origin, naming, material slots, and texture paths once in the curated vendor layer.
5. Wrapper scenes own pivot correction, logical ground contact, collision/selection bounds, door/work/carry/VFX sockets, palette overrides, shadow flags, and LOD.
6. A validation tool must reject gameplay presentation definitions that reference raw source paths or lack required sockets.
7. Track asset origin, pack/version, original filename, license, modifications, export preset, and checksum in an asset ledger.

## Character and animation architecture

### Runtime scene

```text
CharacterView3D (Node3D)
├── VisualRoot (Node3D)
│   ├── RiggedModel
│   │   ├── Skeleton3D
│   │   └── MeshInstance3D
│   ├── RightHandTool (BoneAttachment3D)
│   ├── LeftHandTool (BoneAttachment3D)
│   ├── CarrySocket (BoneAttachment3D)
│   ├── BackSocket (BoneAttachment3D)
│   └── HeadSocket (BoneAttachment3D)
├── AnimationPlayer                  # imported/shared libraries
├── AnimationTree
├── GroundShadow
├── SelectionIndicator
├── StatusAnchor
├── AudioAnchor
└── VfxAnchors
```

Root motion must be disabled. Simulation/world waypoints control the character root; animation provides body motion only. This avoids drift and keeps saves deterministic.

### Semantic state contract

The simulation publishes a small presentation contract instead of raw internal strings:

```text
entity_id
world_position / facing
locomotion: Idle | Walk | Run | Flee
action: None | Carry | WorkGeneric | Chop | Mine | Farm | Hammer | Saw |
        Sleep | Melee | Ranged | Hit | Die
profession
equipped_tool
carried_resource / carried_amount
action_phase or event sequence
alive / visible / selected
```

During migration, one adapter maps current strings such as `Moving`, `Building`, `Working`, `Going to shelter`, `Guarding`, and `Confused` into this contract. No animation script should inspect production-building dictionaries directly.

### AnimationTree design

Use one top-level `AnimationNodeStateMachine`:

```text
Alive
├── Locomotion BlendTree
│   ├── Idle
│   ├── Walk
│   ├── Run
│   ├── Carry
│   └── Flee
├── Work StateMachine
│   ├── WorkGeneric
│   ├── Chop
│   ├── Mine
│   ├── Farm
│   ├── Hammer
│   └── Saw
├── Combat StateMachine
│   ├── Melee
│   └── Ranged
└── Sleep

Hit   # high-priority one-shot that returns to the prior valid alive state
Die   # terminal state; no automatic exit
```

Implementation notes:

- Blend Idle/Walk/Run by actual presentation speed where clips support it.
- Carry can be a dedicated full-body locomotion state or an upper-body layer only after visual testing proves the blend is clean.
- Work/combat actions enter from locomotion, lock for a semantic action window, emit contact/impact events, then return through the state machine.
- `Hit` interrupts work/combat but not `Die`.
- `Die` disables ordinary transitions and leaves a controlled corpse/despawn policy to the presentation adapter.
- `Sleep` is a stable state, not a looped walk with the model rotated.
- Animation notifies trigger impact VFX and sound, but damage/resource production remains simulation-authoritative.
- Tools and cargo are scenes from the tool/resource catalogs attached to named sockets. Profession is a data loadout, not a separate character implementation.

### Shared KayKit rig strategy

1. Select one canonical KayKit skeleton and document bone names, rest pose, forward axis, scale, and required sockets.
2. Import the Character Animations once as shared `AnimationLibrary` resources.
3. Reuse those libraries for every compatible KayKit character skin. If the Adventurers and farmer files are truly on the same rig/rest pose, do not duplicate clips per character.
4. If rest poses differ, create one import-time retarget profile and corrected rest pose; never hand-correct every animation.
5. Keep body mesh/skin, profession clothing/accent, tool, and animation set independently swappable.
6. Validate all required clips on at least one civilian, one farmer, and one soldier before producing character variants.

## Building asset gap matrix

`Direct` means the base mesh already communicates the role. It does not mean “ship untouched.” Every asset still passes through an SnS wrapper, palette/material pass, sockets, foundation, props, and scale validation.

| SnS building | Classification | KayKit basis | Recommended treatment |
| --- | --- | --- | --- |
| Town Hall | **Modified asset** | `building_townhall_*`, optionally `building_castle_*` elements | Preserve the readable massing; change roof/material palette, entrance, banner tower, Shard/Lumen motif, yard, and silhouette accents. Priority custom identity piece. |
| House | **Direct KayKit asset** | `building_home_A_*`, `building_home_B_*` | Use two variants, SnS roofs/trim, gardens, laundry/wood piles, warm night windows. |
| Storehouse / warehouse | **Kitbash required** | `building_market_*` or a large home/workshop, crates, pallets, sacks, lumber/stone props | Add broad loading doors, covered stock bays, yard stacks, and clear carrier sockets. |
| Lumber camp | **Kitbash required** | `building_tent_*`, lumber props, logs, stumps, carts | Create an open work yard rather than mislabeling the enclosed lumbermill. |
| Sawmill / lumbermill | **Direct / modified asset** | `building_lumbermill_*` | Add saw bench/work socket, log infeed, plank outfeed, sawdust, moving wheel/saw VFX. |
| Quarry | **Kitbash required** | Mine/scaffolding pieces, single rocks, cart, wheelbarrow | Open quarry face and crane/work yard; keep visually distinct from underground mine. |
| Mine | **Direct KayKit asset** | `building_mine_*` | Add rock-face integration, rails/carts, lanterns, ore piles, miner sockets. |
| Farm | **Kitbash required** | `building_grain`, fences, hay bales, troughs, carts | Farmstead wrapper plus separate crop-field plots. The field, not only the house, must show production. |
| Grain mill | **Direct KayKit asset** | `building_windmill_*` or `building_watermill_*` | Choose variant based on terrain; animate rotor/wheel and add grain/flour transfer props. |
| Bakery | **Modified asset + small custom addition** | `building_workshop_*` or `building_tavern_*` | Add a small SnS oven/chimney, bread racks/sacks, warm light, and baker work socket. No full custom building needed. |
| Blacksmith | **Direct KayKit asset** | `building_blacksmith_*` | Add anvil/tool assets when present, coal/metal resource piles, sparks/smoke, hammer socket. |
| General workshop | **Direct KayKit asset** | `building_workshop_*` | Re-prop per production role; keep shared base only if silhouettes remain distinguishable. |
| Market / trading post | **Direct / modified asset** | `building_market_*` | Recolor awnings, add changing goods displays and crowd/interaction sockets. |
| Well | **Direct KayKit asset** | `building_well_*` | Use as a small civic/support structure with buckets and gathering socket. |
| Barracks | **Direct / modified asset** | `building_barracks_*` | Add training yard, weapon racks, faction banner, autonomous squad muster sockets. |
| Archery range | **Direct KayKit asset** | `building_archeryrange_*`, target, arrow bucket | Add firing line and autonomous training loop. |
| Guard post / guard tower | **Modified asset** | `building_watchtower_*`, `building_tower_A/B_*`, tower base | Create a recognisable SnS roof/crest, stronger stair/door/readability, banner and patrol muster point. Priority identity piece. |
| Outpost | **Kitbash + source modification** | Watchtower/base, tent, fences/walls, gate, flag, small props | Build a low fortified compound distinct from both Town Hall and tower; add Shard-facing Lumen device. Priority identity piece. |
| Harbour / dock | **Modified asset** | `building_docks_*`, dock props, boat, anchor, crates | Rework the landward silhouette and roof, attach natural pier modules, cargo sockets, banner, water interaction. Priority identity piece. |
| Shipyard | **Direct / modified asset** | `building_shipyard_*`, boats, dock modules | Add incomplete hull/work stages, lumber stacks, saw/hammer sockets. |
| Walls and gates | **Direct modular assets** | wall straights/corners/gates and tower bases | Hide repetition with length variants, foundations, banners, damage states, and terrain-aware bases. |
| Lumen Pillar / Shard shrine | **Kitbash + small custom addition** | `building_shrine_*`, tower elements, flags | Add a unique crystal/emissive core and realm accents. This is the best small custom asset investment because it communicates SnS's own world premise. |

No full custom building is necessary for the first 20-building set. Town Hall, Outpost, Guard Tower, Harbour, and Lumen Pillar should receive source-level silhouette/material work before final marketing screenshots.

## SnS art-direction specification

### Working visual identity: “Shardlit frontier”

The world is a warm, materially grounded medieval frontier whose settlements are threaded with a restrained supernatural Shard/Lumen language. KayKit supplies friendly proportions and readable low-poly shapes; SnS supplies the palette, settlement density, landscape, activity, and realm symbolism.

### Rules

- **Palette:** warm lime-muted grass, deep pine forest, charcoal/slate rock, ochre dirt, warm timber, pale limestone, and desaturated roof colors. Reserve luminous cyan with a violet edge for Shard/Lumen energy. Avoid using KayKit's default bright-blue faction treatment unchanged.
- **Roofs/materials:** introduce an SnS slate/terracotta family with mild value variation, weathered lower edges, dark timber framing, and oxidised metal/copper details. Keep material count low through shared atlases.
- **Faction accents:** use narrow cloth/banner/paint accents, shields, and workwear tabs. Do not recolor entire buildings into team colors.
- **Banners/flags:** use a simple original divided-shard heraldic shape and consistent vertical proportions. Flags identify ownership and wind, not decoration everywhere.
- **Terrain:** continuous, softly terraced land with blended grass/dirt/rock, worn building yards, and no visible hex or square outlines in normal play.
- **Foliage:** dense at forest edges, sparse around roads/work yards, with layered canopy heights and understory. Clearings should look worked, not procedurally empty.
- **Lighting/shadows:** warm directional day light, cool restrained ambient fill, readable contact shadows, and slightly warmer settlement windows/fire at dusk. Keep faces/tools visible.
- **Water:** deep desaturated teal-blue with soft directional movement, lighter shore shallows, foam/reeds/rocks at selective contacts, and clear harbour silhouettes.
- **Roads:** ochre compacted earth with soft irregular edges, ruts, foot-worn junctions, occasional stones, and dust. Road width and traffic marks communicate importance.
- **VFX:** low-volume chimney smoke, sawdust, mining chips, hammer sparks, crop chaff, cart/foot dust, waterwheel spray, and restrained Lumen particles. VFX must explain work, not obscure it.
- **Building silhouettes:** exaggerate one role cue per building—mill wheel, mine portal, bakery chimney, storehouse doors, barracks yard, harbour crane/pier. Avoid relying on tooltip text.
- **Prop density:** concentrate props in authored work yards and logistics endpoints. Cargo must visibly accumulate, travel, and disappear/convert.
- **Profession readability:** silhouette first (tool/cargo/headwear), then cloth accent, then animation. Tint alone is insufficient.
- **Camera:** fixed orthographic angle; compose doors, work yards, and roads toward the camera where possible. Tall towers must not hide busy yards at standard view.
- **UI relationship:** warm dark neutral panels, thin brass/ochre accent, and Shard cyan only for supernatural systems/urgent focus. UI portraits and thumbnails render the wrapper scenes, not raw vendor images.

### Five highest-impact screenshot changes

1. **Customise the five signature silhouettes:** Town Hall, Outpost, Guard Tower, Harbour, and Lumen Pillar.
2. **Apply one SnS palette/material atlas:** especially roofs, timber/stone balance, restrained faction cloth, and Shard-only emissive color.
3. **Hide the grid completely:** continuous terrain, irregular forest edges, terrain-aware foundations, natural dirt roads, and non-hex water/coast presentation.
4. **Make work and goods visually dense:** role tools, animated work yards, visible stock piles, carriers/carts, smoke, dust, chips, sparks, and changing production props.
5. **Establish the Shardlit atmosphere:** characteristic sun/shadow direction, cool Lumen/Shard contrast, banner language, shallow-water color, and restrained world/UI color grading.

## Risk register

| Risk | Likelihood / impact | Mitigation and gate |
| --- | --- | --- |
| Required character/animation/tool packs are missing | Certain / blocking for animation proof | Add exact pack versions and local licenses before Phase 1 work. Do not use Medieval token units as a substitute. |
| Shared-rig claim is incomplete or rest poses differ | Medium / high | Run a rig audit: bone names/hierarchy, rest pose, skin weights, scale, forward axis, and 17 required clips across civilian/farmer/soldier skins. Build one retarget profile if required. |
| GLTF scale/orientation/pivot mismatch across packs | High / high | Create an `ArtScaleProfile`; calibrate canonical humanoid height, ground plane, door height, cell size, and forward axis in the lab. Fix once in curated exports/wrappers. |
| Import and repository bloat from duplicate packages/formats | Certain / medium-high | Keep source under `.gdignore`, retain one curated GLB runtime export, remove ZIP/FBX/OBJ/duplicate tier content from `res://` in a dedicated reviewed cleanup. |
| KayKit notice missing from shipping ledger | Certain / medium | Copy exact local license/version into the license folder and notices; ensure export includes it. Verify every additional pack separately. |
| 5,711-line mutable-dictionary simulation becomes harder to change safely | High / high | Freeze behavior with tests; introduce command/query interfaces, typed definitions, explicit tasks/states, and service extraction incrementally. No simultaneous C# rewrite. |
| Two simulation authorities create drift | Existing / high | Declare active GDScript authoritative. Port useful C# tests/contracts, then retire the unused C# library and obsolete GDScript adapter. |
| Save compatibility breaks when world coordinates/elevation evolve | Medium / high | Keep square anchor coordinates in Phase 1; do not persist art paths/transforms; add explicit schema migrators and fixture saves before version bump. |
| Path-query spikes with many autonomous workers | High / high | Keep high-level logical routes, cache/reuse paths, use road graph/flow fields where useful, stagger query groups, and avoid resetting NavigationAgent targets each frame. Profile 24, 50, 100, and 200 agents. |
| Crowd avoidance harms deterministic logistics or causes jitter | Medium / medium | Make avoidance presentation-only, use lanes/slot offsets at doors, reserve access sockets, and let simulation arrival remain authoritative. |
| Dynamic building placement invalidates navmesh | Medium / high | Prefer logical path authority plus local query regions; update small navigation regions/obstacles instead of rebaking the whole map. Test construction/demolition bursts. |
| Skinned animation, shadows, and many materials exceed frame budget | High / high | Shared meshes/materials/animation libraries, character update LOD, shadow tiers, chunked MultiMeshes, pooled VFX, and measured budgets in the Phase 1 lab. |
| Continuous terrain loses placement readability | Medium / high | Use build-mode overlays only: footprint decal, slope contour, access/road arrows, foundation ghost, and explicit valid/invalid feedback. Keep the normal world clean. |
| Water/coastline conflicts with building footprints and navigation | Medium / medium | Add a typed water/buildability mask, shore band, harbour-specific anchors, and water navigation layer. Validate docks on varied shore orientations. |
| Stock KayKit look overwhelms SnS identity | High / high | Enforce wrapper-only use, SnS material palette, five signature silhouettes, dense work-yard dressing, custom banner language, and screenshot review gates. |
| Current direct worker/Sovereign controls contradict autonomy requirement | Certain / design-high | Remove ordinary worker/military move/attack commands. Preserve inspection and high-level assignment. Decide explicitly whether Sovereign direct control is a documented exception. |
| Compatibility renderer limits desired 3D lighting/performance | Medium / medium | Prototype Forward+ as the desktop default and measure a Compatibility fallback separately before locking requirements. |
| Local Godot 4.7 console crashes before smoke-test output | Observed / high | Reproduce with editor and console builds, capture an engine log/minimal reproduction, verify the exact 4.7 binary and drivers, and do not begin the proof until a stable editor/headless test loop exists. |

## Phased rebuild plan

### Phase 1 — 3D foundation and living-settlement proof

Build the contained lab and one live wood-production loop through the art abstraction layer. Do not replace the shipping main scene until the visual, animation, and performance gates pass.

### Phase 2 — 3D presentation shell

- Compose the new `GameRoot`, `WorldView3D`, camera rig, lighting, UI scene shell, registries, and presentation adapter.
- Render the existing authoritative simulation in 3D.
- Implement chunk terrain, water, roads, building view lifecycle, selection/picking, and construction ghosts.
- Preserve version-7 save behavior and all simulation smoke tests.
- Keep the old 2D entry point available as a temporary comparison/fallback.

### Phase 3 — Character, job, and movement refactor

- Introduce semantic character presentation states and shared AnimationTree.
- Extract explicit job/task services and replace free-form worker strings at the adapter boundary.
- Add road lanes, building access sockets, yard work sockets, visual path smoothing, and bounded avoidance.
- Remove ordinary direct worker/military movement commands.
- Profile 50/100/200 workers and define final update/LOD budgets.

### Phase 4 — Economy/building content expansion

- Convert the retained production/logistics rules to validated building definitions.
- Deliver the approximately 20-building matrix, physical resource visuals, carts, construction phases, damage states, and work-yard animation.
- Add profession loadouts and the remaining required animation states.
- Expand terrain biomes: grassland, forest, mountain/rock, and water.

### Phase 5 — Combat/rivalry and save migration

- Adapt raids, towers, patrols, projectiles, Sovereigns, rival workers, Lumen, and claims to the 3D presentation contract.
- Resolve the Sovereign-control exception.
- Add any necessary schema migration only after world coordinates are stable; test real v7 fixture saves.

### Phase 6 — SnS identity, optimisation, and cutover

- Complete source-level Town Hall, Outpost, Guard Tower, Harbour, and Lumen work.
- Finalise palette, terrain materials, water, lighting, work VFX, prop density, UI/world relationship, and audio spatialisation.
- Run full performance, visual, save/load, and commercial-asset audits.
- Switch the main scene only after acceptance. Then remove the 2D runtime art/renderer, obsolete adapter, and unused C# authority in separate reversible changes.

## Exact Phase 1 scope

### Entry requirements

- Supply the Character Animations, Adventurers, Mystery Series 6, Forest Nature, Resource Bits, and RPG Tools Bits packs under `assets/Kaykit` or another agreed source location.
- Preserve and inspect the local license/version file for every pack.
- Confirm a Godot 4.7 Forward+ desktop launch on the development machine.
- Resolve the observed native Godot 4.7 console crash and restore a passing headless smoke-test loop.

### Work included

1. Create the source/runtime third-party boundary and asset ledger for only the assets used by the proof.
2. Export/curate one runtime model format and create a canonical scale/orientation profile.
3. Create wrapper scenes for Town Hall, home, lumbermill, mine, watchtower, docks, six nature/rock variants, wood/stone cargo, axe, pickaxe, hammer, and one rigged civilian/soldier/farmer skin each.
4. Create the wrapper/catalog validation layer. Gameplay/presentation-controller scripts may reference only semantic visual IDs or presentation resources.
5. Create the isolated `phase1_3d_lab` scene specified above.
6. Implement the fixed orthographic camera, pan, zoom, focus, 3D picking, and scale/readability overlay.
7. Implement continuous terrain, one height transition, one water edge, natural road ribbon, chunked foliage/rocks, one lighting rig, shadow tiers, and minimal work VFX.
8. Implement the shared rig, sockets, animation library, AnimationTree, and semantic adapter for Idle, Walk, Run, Carry, Chop, Mine, Hammer, Melee, Hit, and Die. Confirm that the architecture has named transitions/loadouts for WorkGeneric, Farm, Saw, Sleep, Flee, and Ranged even if content polish for those clips is deferred.
9. Bind one existing authoritative loop—Lumber Camp produces wood, a carrier visibly picks it up and delivers it to Storehouse/Town Hall storage—to the 3D view without altering economic outcomes.
10. Run the acceptance criteria, capture profiler data and screenshots, document scale/import decisions, and record pass/fail recommendations.

### Explicit exclusions

- No full conversion of the shipping `main.tscn`.
- No 20-building production pass.
- No rewrite/port of the GDScript simulation to C#.
- No new combat balance, rivalry AI, campaign generation, or multiplayer work.
- No final UI redesign.
- No destructive deletion of the current 2D renderer or art.
- No save-schema change unless a separately reviewed blocker makes it unavoidable.

### Phase 1 exit decision

Proceed to Phase 2 only if the lab passes scale/rig compatibility, continuous-world readability, wrapper-only asset use, 24-character animation, and measured performance gates. If it fails, correct the import/rig/camera/art direction inside the lab before touching the main game.

## Final recommendation

**PARTIAL REBUILD.**

Rebuild the scene hierarchy, world renderer, camera, terrain/water/roads, visual asset integration, character presentation, and UI composition. Retain the current simulation's proven economic, construction, worker, combat, rivalry, diagnostics, and persistence behavior. Refactor that behavior gradually behind stable typed commands, queries, definitions, tasks, and presentation snapshots.

A complete rewrite would discard the project's strongest work and combine simulation, content, animation, navigation, rendering, and save risk in one change. Keeping the current presentation would prevent KayKit 3D assets and an observable Settlers-like world from reaching their potential. The partial rebuild isolates those risks and gives the project a clear stop/go gate before the broad conversion begins.
