# Shards & Sovereign — Phase 2 Production 3D Migration Report

Date: 2026-08-21  
Status: **PASS — production 3D core settlement is viable**

Phase 2 adds a production 3D client beside the preserved 2D client. The real generated map, production simulation, construction, workers, carriers, roads, inventories, and version-7 save data remain authoritative. The 3D scene is a reconstructible view over that authority.

## 1. Migration architecture

The shipped dependency direction is:

```text
OneShardSimulation (authority)
  -> ProductionSimulationHost3D (fixed-tick scheduling and save/load delegation)
  -> ProductionPresentationAdapter3D (read-only semantic snapshots)
  -> ProductionAssetCatalog3D (SnS semantic keys and curated runtime assets)
  -> ProductionWorldView3D
       -> ProductionRoadView3D
       -> ProductionBuildingView3D
       -> ProductionCharacterView3D
```

`production_3d.tscn` has explicit `GameRoot`, `SimulationHost`, `PresentationAdapter`, `WorldView3D`, `IsometricCameraRig`, `LightingRig`, `AudioRoot`, and `UI` nodes. `WorldView3D` creates the required `Terrain`, `Water`, `Roads`, `Buildings`, `Characters`, `ResourceVisuals`, `Environment`, `VFX`, and `NavigationPresentation` roots.

Stable simulation entity IDs key every building and character wrapper. Visual paths, transforms, animation playback, materials, VFX, and navigation presentation never flow back into the simulation. The Phase 1 lab was used as a reference and component donor; it was not copied wholesale over production.

## 2. Production launch path

The existing project main scene remains the legacy 2D client. The reversible launcher selects a presentation explicitly:

```powershell
# Preserved 2D production client (default)
.\tools\launch_client.ps1 -Presentation legacy

# New production 3D client, new deterministic run
.\tools\launch_client.ps1 -Presentation 3d -Seed 260821 -Quality recommended

# Known deterministic 3D fixture for review
.\tools\launch_client.ps1 -Presentation 3d -Seed 260821 -Fixture early -Quality recommended

# Reconstruct the normal production save in 3D
.\tools\launch_client.ps1 -Presentation 3d -Load -Quality recommended
```

Manual reproducible demonstration:

1. Launch the `early` fixture with the command above. The fixture reaches its state only through production commands and ticks.
2. Pan with configured movement keys or middle-mouse drag; zoom with the wheel.
3. Click the Town Hall and inspect its authoritative state.
4. Choose Lumber Camp, move the snapped green footprint beside the connected road, rotate with `R` if desired, and click to call `request_build`.
5. Watch the construction foundation/posts, material delivery, build activity, and stable wrapper become the completed Lumber Camp.
6. Inspect the woodcutter and the carrier while physical Wood is attached; inspect the building inventory.
7. Place or extend Road and observe only the affected road cells/neighbours update.
8. Place Farm and observe Wheat production and Wheat cargo.
9. Use **Save settlement**, exit, relaunch with `-Load`, and confirm the settlement reconstructs.

The deterministic automated equivalent is `tests/phase2_demo_playthrough.gd`; it prints all ten major checkpoints from launch through reconstruction.

## 3. Renderer/config changes

Phase 2 did not make the 3D path the project-wide default and did not require a broad `project.godot` renderer change. `tools/launch_client.ps1` launches legacy 2D with `gl_compatibility` and launches the explicit production 3D scene with `forward_plus`.

The 3D path uses a procedural sky, filmic tonemapping, height fog, warm key/cool fill lighting, and directional shadows. The production HUD is on Canvas layer 10 so foreground 3D foliage cannot obscure interaction text.

Two data-driven quality profiles are available:

- `recommended`: full foliage, shadows at 170 m, full VFX/water/animation intent, project anti-aliasing, zero ambient actors.
- `scalable_low`: 45% foliage, shadows disabled, 80 m shadow intent, reduced water/VFX/animation detail, anti-aliasing-disable intent, zero ambient actors.

No lower-end hardware number is claimed without a second GPU.

## 4. Real-map terrain implementation

`ProductionPresentationAdapter3D.capture_world` reads the actual 70×70 generated map, elevation field, terrain/resource identifiers, seed, Shard position, buildings, roads, and workers. `ProductionWorldView3D` converts every real logical cell into one continuous `SurfaceTool` terrain mesh with shared visual continuity, vertex-colour blending, terraces/cliff faces, and a concave collision surface for 3D picking. The logical grid is never drawn.

`tile_to_world`/`world_to_tile` use a 2.5 m presentation cell and 0.45 m per authoritative elevation level. A large outer wilderness floor, deterministic edge forest, restrained colour transition, and fog keep the rectangular logical map from reading as a floating test slab at normal gameplay zoom. The approach does not assume an island and can accept future map shapes.

The scene owns a `Water` root, but the current production generator/definitions emit no water terrain identifier. Phase 2 therefore leaves the root empty instead of inventing water and changing map semantics.

## 5. Forest presentation mapping

Authoritative `TREE` and `ROCK` cells drive deterministic visual regions. The same seed and logical state reproduce the same compositions. Dense interiors can receive multiple mixed-size tree instances and understory; edges are thinner; rock clusters use mixed forms. Static nature uses grouped `MultiMeshInstance3D` batches rather than one live node per visual tree.

Road cells, construction footprints, completed building footprints, and work yards suppress nearby nature presentation without deleting authoritative resources. A visual tree is dressing, not a unit of Wood. When an authoritative tree/resource tile changes, the nature signature rebuilds the corresponding deterministic composition coherently. The fixed camera plus clearance policy is the Phase 2 occlusion strategy; trees are not globally transparent.

## 6. Road graph presentation

The adapter reads completed and planned production `ROAD` buildings and emits one semantic snapshot per unique logical road tile. Each view derives a four-way connection mask, rounded centre, soft edge, and overlapping connectors. This produces continuous intersections and bends while the real logical graph retains movement and connectivity authority.

`ProductionWorldView3D` keeps signatures per road tile. A placement, extension, completion, or removal replaces only changed views and their connection-dependent neighbours rather than rebuilding terrain or the full world.

The founding simulation currently contains two completed road records on the same Town Hall entrance tile. The adapter defensively deduplicates the visual cell while preserving both authoritative/save records; this simulation debt is documented rather than rewritten during the client migration.

## 7. Building wrappers promoted

The semantic catalog covers Town Hall, House, Lumber Camp, Sawmill, Quarry, Farm, Bakery, Storehouse, Watchtower, Barracks, Wall, Lumen Pillar, and Claimant Outpost without exposing raw vendor paths to controllers. Phase 2 gives the core settlement slice distinct readable models/scales and authored work-yard treatments; later-game types retain compatible semantic fallbacks for future migration.

`ProductionBuildingView3D` supplies stable semantic sockets for entrance, pickup, drop-off, worker station, construction delivery, work yard, VFX, camera focus, and selection bounds. Work yards show logs/planks, quarry stone, farm plots/produce/tools, crates/barrels, wheelbarrow, and restrained inventory indicators where applicable. Decorative props remain explicitly non-authoritative.

All runtime models resolve below `res://assets/settlement3d/runtime`. Its manifest contains 131 curated source files promoted from the Phase 1 allowlist. Raw `assets/Kaykit` paths do not appear in gameplay/controller code.

## 8. Character/worker integration

The frame adapter maps every authoritative worker record to stable ID, type/profession, interpolated logical position, facing, simulation state, semantic action, tool, cargo type/amount, building ID, visibility, and selection state. Character views are created, updated, and removed one-to-one by ID.

All production characters share the `Rig_Medium` animation-library/state-machine architecture. The semantic layer covers Idle, Walk, Run, Carry, WorkGeneric, Chop, Mine, Farm, Hammer, Saw, Sleep, Flee, Melee, Ranged, Hit, and Die. Logical routes remain authoritative; presentation interpolation uses `move_elapsed` plus bounded render lead, faces the next route point, aligns to terrain, and never advances delivery state.

Tools attach to the right-hand semantic socket. Wood, Planks, Stone, Wheat, Bread, and Wyrd cargo appear only when the worker record reports a positive carried amount and disappear on the authoritative transfer.

## 9. Construction integration

The production placement command creates the existing construction-site record. The same building ID owns one wrapper throughout foundation, posts/partial structure, emerging model, nearly complete, and completed presentation states. Delivered/needed materials and authoritative progress drive the stage; no presentation progress is persisted.

The deterministic gate observed Lumber Camp site ID 14 after Wood 2 was delivered, displayed the active site and build activity, completed it through normal ticks, and verified that the completed view retained the same stable entity ID. Construction cargo follows the normal carrier state and sockets.

## 10. Lumber production result

**PASS.** The repeatable fixture placed and completed a real Lumber Camp, produced via the existing worker/production rules, exposed the Lumber work yard, and reached a real carrier state with physical `Wood ×2`. The automated playthrough reported `physical_cargo=true` and a production resource ledger containing Wood 46 at its Lumber checkpoint. The carrier, action `Carry`, task, cargo type/amount, route, building inventory, and work animation all came from live simulation records.

Evidence: `artifacts/phase2/screenshots/05_lumber_logistics.png` and `artifacts/phase2/persistence/demo_playthrough.json`.

## 11. Second production-chain result

**PASS — Farm/Wheat.** The deterministic fixture used authoritative placement, construction, staffing, production, and hauling to complete a Farm and reach a carrier `Dropoff` state with physical `Wheat ×2`. Farm plots, produce, tools, farmer animation, road logistics, Wheat resource totals, and worker inspection demonstrate that the presentation is not a Lumber-only hardcode.

Evidence: `artifacts/phase2/screenshots/06_second_production_chain.png`.

## 12. Placement/picking result

The production 3D client raycasts against the generated terrain collision surface, converts the hit to a snapped logical anchor, handles `R` rotation, draws a translucent 3D footprint and access indicator, and colours valid/invalid state. The ghost is transient presentation only.

Every preview and commit delegates to the existing `validate_placement`/`request_build` authority, preserving footprint, occupancy, terrain/elevation, enemy, connection, cost, reservation, and other production restrictions. The lifecycle test previews a valid Lumber anchor, commits it through `request_build`, and observes the real construction site.

## 13. Selection/inspection result

Building and worker wrappers own selection areas on a dedicated collision layer; terrain picking remains separate. Selection rings/highlights are subtle and do not alter simulation state.

The production inspector displays building name/type, ID, construction/completion status, status message, assigned/visible workers, road connection, local inventory, and construction delivered/needed materials. Worker inspection displays profession, stable ID, task, semantic action, and authoritative cargo. Ordinary workers have no direct move/gather commands; this client exposes settlement/building commands and inspection only.

## 14. Save/load reconstruction result

**PASS with unchanged schema version 7.** The existing serializer/restorer remain intact. `save_to_file` and `load_from_file` now delegate to path-capable equivalents only so isolated tests can write their own artifacts; the payload and restore semantics did not change.

The vertical-slice and playthrough tests build, produce, carry, save, destroy the presentation instance, load through the production restore path, and reconstruct terrain, unique road views, building wrappers, and worker views from the loaded authority. Seed, buildings, workers, inventories, and resource ledger match. The JSON contains no GLB/GLTF/TSCN path, material, transform, animation time, navigation path, or VFX state.

Evidence: `artifacts/phase2/persistence/vertical_slice_round_trip.json`, `demo_playthrough.json`, and `reloaded_fixture.json`.

## 15. Test results

Final 2026-08-21 results:

| Gate | Result |
|---|---|
| `phase2_catalog_integrity.gd` | PASS — catalog resolution and no raw vendor references |
| `phase2_vertical_slice_smoke.gd` | PASS — roads, economy, stable IDs, unchanged-save reconstruction |
| `phase2_production_3d_smoke.gd` | PASS — scene architecture, placement, construction, cargo attach/remove, create/remove sync |
| `phase2_demo_playthrough.gd` | PASS — ten deterministic launch-to-reload checkpoints |
| `godot_rebuild_smoke.gd` | PASS — all authoritative rebuild checks |
| `godot_construction_smoke.gd` | PASS |
| `godot_rivalry_smoke.gd` | PASS |
| `godot_presentation_smoke.gd` | PASS |
| `godot_release_smoke.gd` | PASS |
| `godot_release_mouse_smoke.gd` | Known debt unchanged: exactly 3 synthetic-click failures |

The three mouse-harness failures remain: return from How to Play, open Settings, and start New Game. The same run still passes button existence, opening How to Play, Back reachability, pause Resume existence, and pause Resume click. No new failure was added.

Godot reports ObjectDB/resource/RID leak warnings during scripted process shutdown in both legacy and Phase 2 harnesses. They do not change exit status for passing suites, but remain cleanup debt.

## 16. Performance results

Method: NVIDIA GeForce RTX 4070, Vulkan Forward+, 1920×1080, VSync disabled, seed 260821 developed fixture, one-second warm-up, at least three rendered seconds per result. Synthetic scale fixtures create authoritative worker dictionaries with a representative 20% carrier target and production-worker mix; ambient actor count is always zero.

| Scenario | Sim | Actors / active | Mean frame | p95 | Mean FPS | Result |
|---|---:|---:|---:|---:|---:|---|
| Normal developed settlement, recommended | live | 6 / 6 | 1.142 ms | 1.519 ms | 875.9 | PASS |
| Representative 100 inhabitants, recommended | live | 100 / 83 | 6.774 ms | 30.018 ms | 147.6 | Practical; tick hitches visible in p95 |
| Representative 200 views, recommended | paused isolation | 200 / 123 semantic-active | 9.132 ms | 9.632 ms | 109.5 | Renderer PASS |
| Representative 200 views, scalable-low | paused isolation | 200 / 123 semantic-active | 9.190 ms | 9.709 ms | 108.8 | Renderer PASS; VRAM falls from 218.1 to 184.7 MiB |
| Representative 200 inhabitants, recommended | live | 200 / 166 | 108.702 ms | 173.898 ms | 9.2 | FAIL — simulation-side scaling cliff |

The provisional 60 FPS normal-gameplay gate passes with substantial headroom. A live 100-inhabitant representative mix is practical. The view layer can display 200 authoritative actors above 100 FPS; however, 200 concurrently simulated synthetic inhabitants are not supported yet. The failure persists while paused presentation is fast, locating the bottleneck in authoritative tick/task work rather than the 3D renderer. The 3D host bounds catch-up to four ticks per render frame and discards stale wall-clock backlog, preventing an unbounded catch-up spiral without changing the fixed simulation tick itself.

Raw evidence is in `artifacts/phase2/performance/*.json`. No minimum-GPU claim is made; `scalable_low` exists for later hardware testing.

## 17. Screenshot paths

All eight files are final 1920×1080 captures from `src/GodotClient3D/Scenes/production_3d.tscn`, not from `phase1_3d_lab`:

1. `artifacts/phase2/screenshots/01_fresh_generated_map.png` — real generated elevation/resource map, founded Town Hall/worker, composed forests/rocks, wilderness boundary, hidden grid.
2. `artifacts/phase2/screenshots/02_early_settlement.png` — production road spine, Town Hall, House, and real authoritative residents.
3. `artifacts/phase2/screenshots/03_building_placement_ghost.png` — valid Lumber footprint/access ghost over the authoritative snapped anchor.
4. `artifacts/phase2/screenshots/04_active_construction.png` — Lumber foundation/posts, real site ID, delivery/needed Wood, connected road, and workers.
5. `artifacts/phase2/screenshots/05_lumber_logistics.png` — completed Lumber yard and selected real carrier in `Carry` with physical `Wood ×2`.
6. `artifacts/phase2/screenshots/06_second_production_chain.png` — Farm plots and selected real carrier in `Dropoff` with physical `Wheat ×2`.
7. `artifacts/phase2/screenshots/07_developed_core_settlement.png` — six real workers, compact mixed settlement, work yards, joined road, and forest framing.
8. `artifacts/phase2/screenshots/08_reloaded_saved_settlement.png` — loaded resource ledger plus six reconstructed real worker views and six building views.

## 18. Known remaining 2D-only systems

Rival claims, camps, scouting/fog presentation, Sovereign control, military commands, combat/towers/projectiles, walls/gates, raids, hunger/night shelter UI depth, final adaptive audio presentation, and the full late-game building art roster remain primarily 2D. Their simulation and tests are preserved. The production 3D catalog has semantic-safe fallbacks for several later building types, but Phase 2 does not claim full 3D gameplay support for those systems.

The Phase 2 HUD is functional migration UI, not the final UI redesign. Direct individual worker control was intentionally not migrated.

## 19. Known technical/visual debt

- The fully live synthetic 200-inhabitant case fails; Phase 3 must profile and amortize authoritative task search/worker synchronization before claiming that tier.
- The founding state contains duplicate completed road authority at the entrance tile; the 3D adapter visually deduplicates it.
- The current generator has no water terrain, so production water presentation is structurally present but unexercised.
- Occlusion is fixed-camera composition plus local vegetation suppression, not camera-to-selection dynamic fading.
- Farm, Storehouse, Bakery, and some later-game types reuse curated base silhouettes with semantic yard differentiation; bespoke final wrappers remain later work.
- Normal zoom is readable, but further terrain hue/elevation contrast and broader settlement composition should be art-directed after gameplay validation.
- Scripted Godot shutdown still reports leak warnings.
- The legacy rendered mouse harness retains its three known synthetic-click failures.
- Only RTX 4070 performance was measured; `scalable_low` must be calibrated on actual minimum hardware.

These items are also recorded in `docs/technical_debt.md` where they need explicit cleanup triggers.

## 20. Files changed

Primary Phase 2 surface:

- `src/GodotClient3D/Scenes/production_3d.tscn`
- `src/GodotClient3D/Scripts/production_3d_game_root.gd`
- `production_simulation_host.gd`, `production_presentation_adapter.gd`, `production_presentation_adapter_host.gd`
- `production_world_view_3d.gd`, `production_road_view_3d.gd`, `production_building_view_3d.gd`, `production_character_view_3d.gd`
- `production_asset_catalog.gd`, `production_scale_profile.gd`, `production_quality_profile.gd`, `production_isometric_camera_rig.gd`, `production_demo_fixture.gd`
- `assets/settlement3d/runtime/**` and `allowlist_manifest.json` (131 curated runtime source files; generated Godot `.import` files remain project-local)
- `tools/launch_client.ps1`, `tools/phase1_sync_runtime_assets.ps1`
- `src/GodotClient/Scripts/one_shard_simulation.gd` (path-capable save/load delegation only)
- `tests/phase2_catalog_integrity.gd`, `phase2_vertical_slice_smoke.gd`, `phase2_production_3d_smoke.gd`, `phase2_demo_playthrough.gd`, `phase2_performance_profile.gd`, `phase2_capture.gd`
- `artifacts/phase2/screenshots/**`, `artifacts/phase2/performance/**`, `artifacts/phase2/persistence/**`
- `docs/technical_debt.md` and this report.

Existing unrelated/user worktree changes were preserved. Phase 2 did not clean repository history or delete the legacy client.

## 21. Legacy path/fallback status

**Intact.** The default `project.godot` entry remains the legacy 2D production scene. `-Presentation legacy` uses Compatibility rendering. The 3D scene is explicit and reversible; its HUD includes **Return to legacy 2D**. All five authoritative legacy suites pass after the final integration. Save schema compatibility is unchanged, so both presentations continue to address the same production authority.

The only failing legacy harness is the already-known rendered mouse automation with the same three failures; the non-mouse presentation/release suites pass.

## 22. Exact recommended Phase 3 scope

Phase 3 should be a focused **living-settlement scale and remaining gameplay presentation** phase, in this order:

1. Profile the authoritative 100/200-worker tick with per-system timings; optimize/amortize carrier task discovery, worker synchronization, and path requests without changing economic outcomes. Gate on a representative live 200-inhabitant save rather than synthetic presentation-only actors.
2. Add a dedicated regression for the duplicate founding entrance road, repair the occupancy/founding ordering in simulation, and verify legacy version-7 saves.
3. Migrate hunger/night shelter, housing/staffing feedback, and production status depth so the 3D client communicates the whole living-settlement loop.
4. Promote rivalry/scouting/fog, Sovereign selection/control, towers/projectiles, walls/gates, raids, and combat through the same adapter/catalog/view boundary; do not combine this with a simulation rewrite.
5. Replace generic Farm/Storehouse/Bakery/later-building silhouettes with distinct semantic wrappers and authored yards; improve terrain hue/elevation contrast from production playtest evidence.
6. Add targeted selected-entity vegetation fade only if fixed-camera playtests prove the existing clearance policy insufficient.
7. Implement water only when authoritative generation exposes a water terrain contract.
8. Run `recommended` and `scalable_low` on the selected minimum GPU and tune from measured 1080p results. Address the shutdown leak warnings and legacy mouse harness separately.

Do not remove the 2D fallback until these gameplay systems, saves, and regressions pass through production 3D.

## 23. Final recommendation

**PASS — production 3D core settlement is viable**

The real production game now launches in 3D, renders the generated authoritative world, supports real placement and construction, shows real workers and physical cargo, proves Lumber and Farm/Wheat economy paths, inspects live state, saves with the unchanged schema, exits, reloads, and reconstructs the equivalent 3D settlement. The legacy 2D safety rail remains runnable and authoritative regressions pass.

This recommendation does not claim the whole game is migrated or that 200 fully simulated inhabitants are ready. It recommends continuing from a sound presentation boundary, with the measured 200-live simulation cliff as the first Phase 3 engineering gate.
