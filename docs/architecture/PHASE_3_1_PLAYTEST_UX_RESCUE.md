# Shards & Sovereign — Phase 3.1 Playtest UX Rescue

**Result: PASS — ready for second user playtest**

Phase 3.1 is a focused rescue of the production 3D play experience. It does not begin Phase 4, add a new major system, or change save schema 7. The production scene launched by `Play SnS 3D.bat` remains the tested game path.

## 1. User complaints reproduced

| Reported problem | Reproduced cause | Resolution |
|---|---|---|
| Fog looked like a stepped grey debug mask | One presentation primitive exposed each revealed logical cell boundary | One low-resolution atmospheric visibility texture, linearly filtered and shaded over the world |
| UI obscured the game | Permanent build, inspector, activity, and oversized top regions competed with the settlement | Compact top bar, transient toast, on-demand build palette, selection-only inspector, no default activity panel |
| Roads looked like discs/capsules | Each logical road tile advertised its centre instead of reading as one route | Continuous dirt connectors and junction surfaces with feathered edges, width variation, and ruts |
| Road had to be selected repeatedly | Successful placement exited the tool | Persistent Road Building Mode until right-click, Escape, or another tool |
| Camera could zoom but not pan | HUD `Control` nodes consumed events before the camera's `_unhandled_input` path | Camera receives `_input`; middle drag, arrows, and wheel remain independent of world selection and build UI |
| Barracks resembled Town Hall and had confusing inputs | Barracks reused a civic silhouette; soldier training also consumed recurring Planks | Dedicated barracks asset/wrapper and a Bread + recruit + time rule |
| Raiders looked weak and entered trees | Hostile routes reused the civilian path grid that did not treat resource trees as solid | Armed Barbarian presentation plus a separately cached hostile grid that blocks trees, rocks, Shard, gates, and buildings |
| Sovereign could enter buildings and become unselectable | Direct movement did not consistently validate footprint occupancy; physics hit order could prefer buildings | Occupancy-aware paths and recovery, screen-space selection priority, F shortcut, and HUD focus button |

The positive feedback was preserved: settlement and action audio remain connected, worker status remains available in player language, and the shared semantic animation architecture remains active.

## 2. Camera pan failure: root cause

The camera rig listened in `_unhandled_input`. The production HUD spans the viewport and its interactive `Control` nodes could mark a middle-button sequence handled before it reached the rig. This explains why semantic camera tests passed while the packaged playtest did not.

The camera now receives mouse buttons, motion, and wheel input in `_input`, before UI consumption. Its input is disabled only while the start overlay is open. Middle drag is immediate from the first motion event, including when the press begins over the inspector or build palette.

## 3. New camera behavior

- Middle mouse drag pans immediately and predictably.
- Arrow keys pan independently of Sovereign W/A/S/D movement.
- Mouse wheel zoom remains available after panning.
- Camera input remains live with no selection, a building selected, the inspector open, during placement, and after leaving build mode.
- `F` and the **SOVEREIGN** HUD button select and focus the player Sovereign.

`tests/phase3_1_camera_input_smoke.gd` uses `Input.parse_input_event` with real viewport positions. It covers New Settlement, empty selection, arrow state, an inspector-origin drag, build-palette/placement drag, return from build mode, and zoom after pan.

## 4. Fog of war before and after

The revealed/unknown simulation authority is unchanged. Unrevealed entities remain fully excluded from presentation.

Before, the presentation made the logical cell boundary visible as a staircase and washed unknown terrain with a broad grey-green treatment. After:

1. The monotonic authoritative reveal set is reduced to a 2-logical-cell-per-texel `L8` mask.
2. Partial 2×2 coverage is preserved in the byte mask.
3. The texture is linearly sampled by one persistent world plane.
4. A spatial shader applies a deep cool unknown colour, soft threshold, restrained low-frequency mist, and slow irregular edge movement.
5. The persistent `ImageTexture`, material, and plane are updated instead of reconstructed when reveal state changes.

This removes exposed squares and prevents the fog update from becoming a frame-time cliff during scouting. Revealed territory retains the Shardlit Frontier palette; unknown territory is dark and unreadable without becoming flat grey.

## 5. UI architecture and visual result

The normal 1920×1080 HUD now consists of:

- one 42-logical-pixel compact resource/status strip;
- fixed command buttons for Sovereign, Build, Save, Load, pause, speed, and menu;
- a small deduplicated contextual toast below the top bar;
- an on-demand categorized build palette;
- a 236-logical-pixel inspector, physically about 354 px under the project's canvas scale, shown only for selection;
- a compact placement/road hint only while a tool is active.

The top bar has responsive text overrun and fixed command-button widths. Transient command messages were moved out of the command row into the toast, eliminating long-value/button overlap at 1920×1080.

Normal play has no build palette, inspector, placement panel, activity panel, title banner, `PRODUCTION 3D`, IDs, raw action names, or authority terminology. F3 exposes the debug-only control. The automated occupancy check measures normal player UI at no more than 15% of the useful world view.

Reference comparison:

- Phase 3 developer-style build UI: `artifacts/phase3/screenshots/10_playtest_ui_build_menu.png`
- Phase 3.1 default HUD: `artifacts/phase3_1/screenshots/01_new_settlement_default_ui.png`
- Phase 3.1 build palette: `artifacts/phase3_1/screenshots/02_build_palette_open.png`
- Phase 3.1 worker/building inspectors: `07_worker_inspector.png`, `08_building_inspector.png`

## 6. Road rendering changes

Logical road authority and connectivity are unchanged. Each road view now produces a continuous dirt surface from its graph connections to neighbouring centres. The centre is only a compact blended junction, not a circular tile marker. A slightly wider low-opacity edge layer softens the silhouette; deterministic width variation, brown dirt, and subtle paired ruts reduce repetition. Intersections merge into compact junctions without plaza-sized blobs.

Planned and invalid previews reuse the same continuous route shape with subordinate green/red materials. No cylinders, discs, or giant cell squares are used.

## 7. Road placement workflow

The production interaction is now:

1. Open **BUILD** and select Road.
2. Press on an existing connected access/road location.
3. Drag to an endpoint.
4. See one live continuous candidate route and a short validity/reason message.
5. Release to plan all valid new sections.
6. Continue drawing without reselecting Road.

Route validation evaluates the complete virtual route, including earlier candidate sections, so multi-cell plans can connect as one action. Candidate selection compares horizontal-first and vertical-first paths and prefers the valid route with fewer new cells/existing-road reuse. Right-click or Escape exits cleanly.

## 8. Barracks visual change

Barracks no longer uses the Town Hall silhouette. The semantic catalog now points to the dedicated green barracks building asset. Its production wrapper adds a training yard, two weapon racks, a target, and banners. At normal zoom it reads as a broad military compound beside the taller civic Town Hall.

See `artifacts/phase3_1/screenshots/09_barracks_and_town_hall.png`.

## 9. Barracks economy before and after

Before, recurring training consumed Bread and Planks, producing the player-facing state “waiting for bread and planks.” Planks had no visible equipment meaning and were already the Barracks construction material.

After, one soldier requires:

- one free population/recruit;
- 2 Bread;
- 18 seconds of training.

Recurring Plank cost is zero. The inspector reports free recruits, available Bread, `Training cost 2 Bread`, and progress, or a direct idle reason such as `Idle — no free recruits`. The no-injection real playthrough grows the settlement, builds a Barracks, trains one soldier, and staffs the Watchtower under this rule.

## 10. Raider appearance and raid presentation

Raiders now use the hostile-capable Barbarian model with a visible axe, Run semantic, larger dark/red ownership marker, and restrained deterministic formation offsets. They remain human scale but are immediately distinct from civilians. Known raids produce a concise **RAID ACTIVE** toast, stronger warning audio than routine work sounds, and clustered approach presentation. Health is contextual rather than permanently plastered over every hostile.

See `10_raider_approach.png` and `11_active_raid.png`.

## 11. Raider tree pathing: cause and fix

This was authoritative case A, not merely decorative overlap. Civilian logistics historically allowed resource cells in its broad movement cache, and hostile path generation reused that cache. `_is_enemy_walkable` could reject a tree at a target check while A* still returned intermediate tree cells.

The simulation now builds two cached grids together on the same invalidation:

- civilian grid: preserves approved economic/logistics behavior;
- hostile/Sovereign grid: blocks trees, rocks, the Shard, closed gates, and non-road building occupancy.

Cache rebuilding uses an indexed building-type lookup rather than thousands of profiled linear building-ID scans. The regression route asserts that a real hostile route contains neither the test tree nor building footprint.

## 12. Sovereign stuck cause and recovery

The Sovereign accepted direct targets and continuous movement without a complete building-footprint route contract. Dense construction could therefore invalidate or envelop the current route.

The fix adds:

- destination rejection for occupied/non-walkable cells;
- hostile-grid A* routes for click movement;
- collision-aware manual axis sliding for W/A/S/D;
- route recomputation when progress stops;
- a 2.5-second conservative stuck threshold;
- emergency re-projection to the nearest safe authoritative cell only after route recovery fails;
- a `sovereign_recovered` diagnostic event and recovery count.

The test suite rejects a destination inside a building and deliberately places the hero in occupancy to verify nearest-safe-cell recovery.

## 13. Sovereign and selection reliability

World selection now tests projected screen-space character volumes before building physics and terrain. Sovereign receives the strongest character priority, followed by other directly visible characters. This resolves worker/building-edge and Raider/tree ambiguity without changing combat authority.

Three recovery paths are always present:

- click the visible Sovereign;
- press `F`;
- click the **SOVEREIGN** HUD button.

Both shortcut paths select the hero and move the camera focus target.

## 14. Interaction, first-five-minutes, and regression evidence

### First-five-minutes acceptance

The exact production scene and New Settlement menu path were exercised; `Play SnS 3D.bat` still routes to that production scene at recommended quality.

| Acceptance item | Result |
|---|---|
| World clearly visible and dominant | PASS |
| Atmospheric, non-grid FOW | PASS |
| Immediate middle-drag and arrow camera pan | PASS |
| Compact on-demand build menu | PASS |
| Several connected roads drawn without reselecting | PASS |
| Continuous narrow road presentation | PASS |
| Understandable placement preview and reasons | PASS |
| Compact useful worker/building selection | PASS |
| No persistent claim/range clutter | PASS |
| Settlement audio and semantic animation present | PASS |

### Combat mini-playtest

The real playthrough reaches a natural night and raid without fixture/resource injection. The capture suite also exercises a known visible raid state. Raid warning, Raider silhouette, tree/building avoidance, tower projectile authority, Barracks identification/training, Sovereign movement/reselection, stuck recovery, and authoritative casualties all pass.

### Automated suites

- `phase2_catalog_integrity.gd` — PASS
- `phase2_production_3d_smoke.gd` — PASS
- `phase2_vertical_slice_smoke.gd` — PASS
- `phase2_1_world_scale_smoke.gd` — PASS
- `phase3_task_index_smoke.gd` — PASS
- `phase3_living_combat_smoke.gd` — PASS
- `phase3_ui_interaction_smoke.gd` — PASS
- `phase3_1_camera_input_smoke.gd` — PASS
- `phase3_1_ux_rescue_smoke.gd` — PASS
- `phase3_real_game_playthrough.gd` — PASS
- `phase3_1_capture_suite.gd` — PASS, 12/12 at 1920×1080
- custom C# `SimulationTests` runner — PASS, 28/28

The real game playthrough starts through the actual menu, builds roads plus House/Lumber Camp/Watchtower/Quarry/Sawmill/Farm/Bakery/Barracks, observes population growth and both food conversions, trains and assigns a soldier, reaches night and a natural raid, observes a tower projectile/casualty, saves, reloads exact state, and continues.

## 15. Performance regression check

Actual project rendering path: **`gl_compatibility` / Compatibility**, not Forward+. Adapter: NVIDIA GeForce RTX 4070. Resolution: 1920×1080. VSync was disabled for the rendered profile.

| 100 civilians + 20 hostiles | Phase 3 baseline | Phase 3.1 | Change |
|---|---:|---:|---:|
| Mean FPS | 135.1 | 127.6 | -5.6% |
| Mean frame | 7.401 ms | 7.836 ms | +5.9% |
| Frame p95 | 26.783 ms | 28.070 ms | +4.8% |
| Phase 3.1 authoritative tick mean | — | 9.443 ms | within 100 ms simulation cadence |
| Phase 3.1 authoritative tick p95 | — | 19.278 ms | within 100 ms simulation cadence |

This is not a material playability regression. The Phase 3 task index remains active. The authoritative scale profile passes through 200 inhabitants: mean/p95 are 0.686/1.236 ms at 25, 2.511/3.297 at 50, 6.328/7.335 at 100, 10.047/12.034 at 150, and 12.143/15.905 at 200. Deterministic outcome hashes, path-request counts, and task-discovery call counts remain identical to the approved Phase 3 workload.

Two presentation cliffs found during final QA were fixed rather than waived:

- fog updates now reuse one mask texture/material/plane;
- the shared animation system uses staggered manual pose evaluation and a 32-civilian recommended-quality animation budget, prioritizing selected and active workers while keeping transforms smooth every frame; hostiles and the hero retain higher pose cadence.

Artifacts:

- `artifacts/phase3_1/performance/authoritative_profile.json`
- `artifacts/phase3_1/performance/mixed_recommended_100c_20h.json`

## 16. Required screenshot index

All files are 1920×1080 under `artifacts/phase3_1/screenshots/`:

1. `01_new_settlement_default_ui.png`
2. `02_build_palette_open.png`
3. `03_road_drag_preview.png`
4. `04_completed_road_network.png`
5. `05_fow_boundary_close.png`
6. `06_fow_strategic.png`
7. `07_worker_inspector.png`
8. `08_building_inspector.png`
9. `09_barracks_and_town_hall.png`
10. `10_raider_approach.png`
11. `11_active_raid.png`
12. `12_sovereign_dense_buildings.png`

The capture harness frees each production scene before composing the next frame, waits for layout/render completion, asserts the dimensions, and reports all 12 paths.

## 17. Remaining known issues

- The project intentionally remains on the Compatibility renderer. Forward+ migration is outside this rescue phase.
- Screen-edge scrolling is not implemented; it was optional. Middle drag and arrows are fully covered.
- At high population, only the prioritized 32 civilian skeletons update poses concurrently at recommended quality. All real actors remain visible, move smoothly, and retain semantic state; hero and hostile animation retain higher cadence.
- Godot test processes emit ObjectDB/resource-in-use warnings during immediate SceneTree teardown. The production playthrough and state round trips pass; cleanup of test-harness exit warnings remains non-blocking maintenance.
- The legacy 2D safety rail remains available and unchanged.

## 18. Final result

**PASS — ready for second user playtest**

The world is once again the dominant visual element. Fog reads as atmosphere, normal overlays are quiet, roads are continuous and enjoyable to draw, camera pan works through the actual input path, Barracks is visually and economically legible, Raiders read as a coordinated threat and avoid blocked scenery, and the Sovereign cannot become functionally lost.

Do not begin a new feature phase automatically.
