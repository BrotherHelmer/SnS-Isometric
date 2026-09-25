# Shards & Sovereign — Phase 3.2 World Feel and Gameplay Readability

**Result: PASS — ready for a third user playtest**

Phase 3.2 implementation was already substantially complete. This continuation finished the verification gates that the previous runner could not: parse/regression, the 18-step real playthrough, the 40–50 minute rivalry match, the 15 rendered captures with visual review, and a fresh mixed performance profile. No screenshot, FPS number, or rivalry outcome below is invented.

The production scene remains `src/GodotClient3D/Scenes/production_3d.tscn`. It is the project's default main scene. `project.godot` currently sets `renderer/rendering_method="gl_compatibility"`; captures and the performance sample used that configured renderer, not a separate Forward+ override.

Engine used: Godot 4.7 stable (`D:\SnS_Isometric\.tools\godot-4.7\Godot_v4.7-stable_win64_console.exe`). Isolated user data: `artifacts/phase3_2/isolated_user`.

## 1. FOW root cause

The prior presentation mixed coordinate systems. The authoritative reveal set was written into a downsampled image, but the shader sampled that image from the fog plane's local UVs. The fog plane transform, terrain world origin, logical map axes, and texture sampling therefore did not share one explicit contract. The coarser two-tiles-per-texel mask also exposed logical coverage errors at boundaries. Unknown colour remained translucent enough that roads, resources, and terrain detail could be inferred beneath it.

## 2. FOW alignment fix

The chain is explicit:

`authoritative tile -> tile_to_world -> world XZ bounds -> full-resolution L8 reveal mask -> shader world position`

The shader receives `world_min_xz` and `world_size_xz`, derives mask UV from world XZ, and does not use camera or screen coordinates. The mask uses one texel per authoritative tile (`FOG_MASK_DIVISOR := 1`). `production_world_view_3d.gd` exposes deterministic world-to-fog helpers and retains the CPU mask bytes used for exact verification.

`phase3_2_world_feel_smoke.gd` samples revealed and unknown cells at the centre, corners, map edges, and an elevated cell. It also moves and zooms the camera and checks that the same tile returns the same fog UV and sample. **PASS after the continuation rerun.**

## 3. Unknown-territory treatment

- Unknown opacity remains `0.998`, suppressing readable terrain detail rather than tinting it.
- After visual review of the first capture set, unknown albedo was lifted from near-black `(0.025, 0.045, 0.070)` to cool blue-grey `(0.10, 0.16, 0.22)` with stronger mist mix, `edge_softness` `0.30`, and `noise_strength` `0.14`. Opacity was not lowered.
- Feathering happens in world-anchored shader space.
- Reveal authority still filters entities before presentation.
- Revealed terrain keeps its normal colour response.

Visual review of `02_aligned_fow_edge.png` and `03_strategic_fow_view.png` after the tweak: unknown reads as deep navy/blue-grey, the edge is soft rather than a hard staircase, and roads/resources are not readable through unknown. **FOW visual acceptance: PASS.**

## 4. Day/night art direction

Day targets a warm, safe frontier settlement: warm sunlight, brighter sky and horizon, restrained colour, active workers.

Night sets daylight to zero: environment ambient energy `0.11`, sun energy `0.08`, fog density `0.012`, cool moon/fog palette, saturation `0.68`, contrast `1.16`. Dusk still occupies the last 60 seconds of day; the blend now uses a `pow(..., 1.65)` ease so late dusk is visibly darker than a linear mix. Dawn returns over 40 seconds with a milder ease.

Visual review: `01_daytime_new_settlement.png` is bright and inviting. `10_dusk_transition.png` is cooler/darker with warm occupied windows. `11_night_lit_settlement.png` is immediately readable as night without the HUD. **Day/night visual acceptance: PASS.**

## 5. Night lighting and building lights

Town Hall, Houses, Bakery, Barracks, and Storehouse presentation supplies warm emissive windows/doors and restrained shadowless local lights when occupied or operational. Night captures show yellow/orange occupancy glow against a cold exterior. **PASS.**

## 6. Guard-night presentation

Autonomous guard authority drives the change. Tower guards enter `Night Watch`; settlement guards use `Night Patrol` or `Night Watch`. Guards use real sockets, keep an axe, and receive a small lantern. `12_night_guards.png` shows armoured guards in the lit settlement at Night 3. The 18-step playthrough asserted night-guard states. **PASS.**

## 7. Town Hall visual change

The Town Hall keeps the civic vertical anchor and adds timber/plaster wings, plaza, steps, posts, banners, and yard context. `04_town_hall_beside_houses.png` reads as a broader civic compound beside houses, not a narrow unrelated tower. **PASS.**

## 8. Sovereign dependency audit and removal

Removed from the production 3D path: HUD focus button, WASD/right-click/Q/E/C/F hero control, selection, alerts, hero rendering, and player-facing hero instructions.

The 18-step playthrough starts New Settlement through `NewReviewSeed`, finds no `SovereignFocus` control, and after reload `set_player_sovereign_target` still returns failure. Claims/Wyrd remain Outpost/realm systems (`claim_requirements.sovereign` is true for the player realm without “Sovereign” in the summary).

The rivalry save schema still contains a player compatibility dictionary. That record stays pinned, invisible, non-interactive, and excluded from claims, fog, combat, and presentation. **No save-schema migration was performed. Player Sovereign control was not restored. PASS.**

## 9. Claim and Wyrd replacement flow

Player Wyrd and claiming are settlement actions via an operational Claimant Outpost, connected owned road, and active Lumen. Contest authority is an opposing Outpost near the Shard. Legacy hero APIs return `Removed`. Rivalry smoke passed claim/Wyrd behaviour after the AI movement/target fixes.

## 10. Combat timing before and after

After this pass:

- guard damage `6`;
- `0.48 s` strike presentation, authority damage at the strike point;
- cadence `1.4 s`;
- at most two nearby guards commit to one target while alternatives exist;
- tower damage `7`, cooldown `1.65 s`, applied when the projectile arrives.

## 11. Soldier-vs-raider TTK

Focused contract (`phase3_2_world_feel_smoke.gd`): one guard, `18 HP` raider, at least three hits, death inside 3–7 s. **PASS on rerun.**

Expected focused TTK from the cadence: first hit at `0.48 s`, then `1.4 s` cadence, three hits of `6` = `18 HP` → about **3.3 s**. That is inside the 3–7 s band.

The 18-step playthrough observed a real raid with multiple HP drops and a travelling tower projectile (`hits=40` is a per-tick HP-drop counter, not distinct swings). `13_soldier_vs_raider.png` shows a hostile with a red health bar during `RAID ACTIVE`.

## 12. Tower combat timing

World-feel smoke: projectile created without immediate HP loss; damage lands on arrival; raider survives multiple shots. **PASS.** Playthrough recorded `projectile=true` and `delayed_damage=true`. `14_tower_engagement.png` shows a staffed tower, roads, and a marked hostile.

## 13. Road-gap root cause

Building occupancy used to surface as generic realm-structure errors, and preview routing only tried rigid L routes. Those caused unexplained gaps beside buildings.

## 14. Road access and routing fix

Explicit access candidates sit outside the real footprint. Preview uses revealed/passable/grade-aware A*, prefers existing roads, and falls back to L routes. Local reasons include `Building occupies this tile`.

18-step playthrough: roads connected onto Town Hall access cells; a blocked preview named the building footprint. `05_roads_tight_to_buildings.png` shows plank roads meeting building edges without a giant invalid halo. **PASS.**

## 15. Resource-visual authority mapping

Harvest visuals reconstruct from seed + authoritative deposits. Individual tree transforms are not saved. Automatic tree regrowth remains disabled (`tree_regrowth <= 0` is a stump marker).

## 16. Tree depletion result

18-step playthrough: deposits fell and a stump marker appeared (`stumps=1` at step 6, `stumps=8` after later harvest and reload). `06_freshly_cleared_forest.png` shows a harvested corridor with logs/stumps beside remaining trees. Focused save/load reconstructs grass + stump. **PASS.**

## 17. Stone depletion result

18-step playthrough: quarry production reduced `rock_deposits` and the reduced total survived save/load. `07_partially_depleted_stone.png` is the weakest capture: the camera is near civic buildings and a remnant stump/cylinder rather than a large staged quarry face. Authority and the playthrough still prove decline. **PASS with a known capture-framing limitation.**

## 18. Work-socket architecture

Playthrough forced a working lumber worker and verified presentation is off the access tile. Smoke asserts non-stacking sockets. `08_worker_at_lumber_camp.png` shows the lumber camp, log piles, and a worker in the yard. `09_worker_at_production_yard.png` is a posed production framing. **PASS.**

## 19. Save/load regression

Focused resource round-trip: PASS (world-feel smoke).

18-step save/reset/load: tick `11631` restored, stump count `8` restored, stone total restored, claims still Outpost-based, hero control still removed. **PASS.**

## 20. Performance regression

Fresh windowed sample, 1920×1080, recommended profile, real post-raid save scaled to 100 civilians + 20 hostiles, 1 s / 120-frame warm-up + 4 s sample, VSync off:

Source: `artifacts/phase3_2/performance/mixed_recommended_100c_20h.json`

| Metric | Value |
| --- | --- |
| Mean FPS | **181.4** |
| Frame mean | 5.512 ms |
| Frame p95 | 27.568 ms |
| Frame p99 | 34.759 ms |
| Authoritative tick mean | 8.200 ms |
| Tick p95 | 14.519 ms |
| Tick p99 / max | 39.225 ms |
| Draw calls mean | 1337 |
| GPU adapter | NVIDIA GeForce RTX 4070 |
| Renderer | gl_compatibility (project setting) |

Nature MultiMesh still rebuilds pooled batches globally on stage/layout signature change. This sample did not isolate a harvest hitch; mean FPS and tick times do not show a playability problem. Localized instance replacement remains a future optimization only if a hitch appears in play. **Performance gate: PASS. No MultiMesh redesign.**

## 21. Screenshot paths

All 15 files exist at 1920×1080 and were opened for visual review:

1. `artifacts/phase3_2/screenshots/01_daytime_new_settlement.png`
2. `artifacts/phase3_2/screenshots/02_aligned_fow_edge.png`
3. `artifacts/phase3_2/screenshots/03_strategic_fow_view.png`
4. `artifacts/phase3_2/screenshots/04_town_hall_beside_houses.png`
5. `artifacts/phase3_2/screenshots/05_roads_tight_to_buildings.png`
6. `artifacts/phase3_2/screenshots/06_freshly_cleared_forest.png`
7. `artifacts/phase3_2/screenshots/07_partially_depleted_stone.png`
8. `artifacts/phase3_2/screenshots/08_worker_at_lumber_camp.png`
9. `artifacts/phase3_2/screenshots/09_worker_at_production_yard.png`
10. `artifacts/phase3_2/screenshots/10_dusk_transition.png`
11. `artifacts/phase3_2/screenshots/11_night_lit_settlement.png`
12. `artifacts/phase3_2/screenshots/12_night_guards.png`
13. `artifacts/phase3_2/screenshots/13_soldier_vs_raider.png`
14. `artifacts/phase3_2/screenshots/14_tower_engagement.png`
15. `artifacts/phase3_2/screenshots/15_post_harvest_reloaded.png`

Suite log: `artifacts/phase3_2/logs/phase3_2_capture_suite.log` — `PHASE3_2_CAPTURE_SUITE PASS count=15`.

## 22. Verification and remaining known issues

### Gate A — focused Phase 3.2 / Phase 3 smokes

- `tests/phase3_2_world_feel_smoke.gd` — PASS (rerun after FOW/dusk tweaks)
- `tests/phase3_1_ux_rescue_smoke.gd` — PASS
- `tests/phase3_living_combat_smoke.gd` — PASS
- `tests/phase3_task_index_smoke.gd` — PASS

### Gate B — Phase 2 / 2.1 / 3 regression + C#

- C# `SimulationTests` — **28/28**
- `godot_rebuild_smoke`, `godot_construction_smoke`, `godot_presentation_smoke`, `godot_release_smoke` — PASS
- `phase2_catalog_integrity`, `phase2_vertical_slice_smoke`, `phase2_production_3d_smoke` — PASS
- `phase2_1_world_scale_smoke` — PASS
- `phase3_ui_interaction_smoke`, `phase3_1_camera_input_smoke` — PASS
- `phase2_demo_playthrough`, `phase3_real_game_playthrough` — PASS

### Gate C — rival full match

`tests/godot_rivalry_smoke.gd` — **PASS** (`artifacts/phase3_2/logs/godot_rivalry_smoke_retry2.log`).

Fixes required during this continuation (not a skip):

1. AI Sovereign movement overshot into the Town Hall footprint on 0.5 s ticks and looped.
2. Claim targeting used the unwalkable Shard tile.

`one_shard_rivalry.gd` now walks waypoint-to-waypoint without skipping into blocked tiles and snaps claim targets to a walkable cell in the claim ring. Rival builds roads, expands, and can win in the simulated 40–50 minute window. Player compatibility Sovereign cannot cause defeat.

### Gate D — 18-step real playtest

`tests/phase3_2_real_playthrough.gd` — **PASS** (`artifacts/phase3_2/logs/phase3_2_real_playthrough.log`).

Uses New Settlement / review seed, authored starting economy (no injected stockpile), real construction/production, stump wait until `tree_regrowth <= 0`, night, real raid, save/reset/load.

### Gate E — captures

See section 21. Visual FOW/day/night/Town Hall/roads/harvest/workers/combat reviewed from the PNGs, not from file existence alone.

### Honest remaining issues

- Capture `07` does not show a large staged quarry as clearly as `06` shows a cleared forest corridor. Stone decline is proven by authority + playthrough, not by a perfect before/after quarry beauty shot.
- Some capture stages pose workers/raiders on a paused loaded save so the camera can see the intended subject. The 18-step playthrough is the live-economy evidence.
- Developed-save captures often show `STORAGE FULL`. That is real economy feedback, not a Phase 3.2 blocker.
- Legacy 2D compatibility still contains historical hero UI. It is not the default path.
- Nature MultiMesh batches still rebuild globally on stage change. No hitch was measured in the mixed profile.
- `project.godot` uses Compatibility rendering. A Forward+ visual/perf comparison was not run because it would change the shipping renderer without a dedicated gate.
- Godot still reports a few leaked objects/resources on `--script` teardown. Known harness noise; tests still exit 0.

### Files changed during this continuation

- `src/GodotClient/Scripts/one_shard_rivalry.gd` — waypoint-clamped AI movement; walkable claim targeting
- `tests/godot_rivalry_smoke.gd` — entrance-travel regression
- `tests/phase3_2_real_playthrough.gd` — 18-step real playthrough
- `tests/phase3_2_capture_suite.gd` — standalone 15-capture suite on current APIs
- `src/GodotClient3D/Shaders/production_fog_of_war.gdshader` — cool blue-grey unknown + softer noisy edge
- `src/GodotClient3D/Scripts/production_world_view_3d.gd` — matching FOW material parameters
- `src/GodotClient3D/Scripts/production_3d_game_root.gd` — dusk/dawn ease so late day reads as dusk
- `docs/architecture/PHASE_3_2_WORLD_FEEL_AND_GAMEPLAY_READABILITY.md` — this report

## 23. Final result

**PASS — ready for a third user playtest**

During DAY the settlement is worth watching. Harvest changes the land. Workers attach to workplaces. Roads reach structures. Dusk changes the mood. Night makes the wild feel unsafe and the occupied town warm. Raids produce a fight instead of instant deletion. There is no player-controlled Sovereign to look for.
