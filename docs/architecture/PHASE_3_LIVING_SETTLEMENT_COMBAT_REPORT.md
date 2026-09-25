# Shards & Sovereign — Phase 3 living settlement and combat report

## Executive result

Phase 3 turns the production 3D client into a directly launchable internal playtest build. The authoritative simulation remains the source of truth; living-settlement, rivalry, fog, claims, military, raids, projectiles, damage, persistence, and UI are presented through the existing adapter/view boundary. The default game uses real starting resources and real progression rather than the deterministic presentation fixture.

The former 200-live-agent cliff is materially resolved. In the isolated authoritative benchmark, 200 live inhabitants improved from **85.60 ms average / 100.13 ms p95** per tick to **7.32 ms / 8.76 ms**, while the complete outcome hash remained identical. In a rendered 1920×1080 mixed load of 180 civilians and 20 hostiles, Recommended averaged **69.4 FPS** on the RTX 4070, with a **14.16 ms authoritative average / 21.34 ms p95**. The remaining frame-tail cost is documented below rather than hidden.

## 1. Simulation profiling before optimization

The active production GDScript authority was instrumented with opt-in per-system counters and timings. The harness uses a developed deterministic authoritative settlement, adds real live worker dictionaries, runs 120 fixed ticks at each population, measures presentation extraction separately, records path/cache work and entity scans, and captures a canonical economic outcome. GDScript does not expose dependable per-call allocation counts, so the harness reports process static-memory deltas and scan volume as allocation/work proxies.

The full evidence is in `artifacts/phase3/performance/baseline_authoritative_profile.json`. At 200 inhabitants, the important baseline measurements were:

| System | Average ms/tick | p95 ms/tick | Calls/tick |
| --- | ---: | ---: | ---: |
| Worker update total | 85.254 | 99.712 | 1.000 |
| Carrier task discovery | 83.929 | 98.542 | 33.275 |
| Inventory/source/destination searches | 78.264 | 90.928 | 1,184.075 |
| Production-worker task discovery | 3.161 | 3.961 | 33.275 |
| Job assignment | 0.125 | 0.135 | 0.200 |
| AStar path generation | 0.072 | 0.233 | 0.717 |
| Rivalry update | 0.185 | 0.303 | 1.000 |
| Building production | 0.037 | 0.035 | 1.000 |

Pathfinding, presentation extraction, building production, hunger/housing, and rivalry were not the peaceful-scale cliff. Repeated global inventory and reservation discovery inside carrier work was.

## 2. Identified scaling bottlenecks

At 200 inhabitants the baseline performed about **239,382 dictionary/entity scan items per tick**. Each idle or retargeting carrier independently rediscovered broadly similar source, destination, and construction demand by scanning global dictionaries. The resulting cost grew superlinearly even though path requests and path-cache rebuilds remained controlled.

After combat was added, two additional measured tail-costs appeared under realistic mixed load:

- hostile target selection was generating paths for too many guard candidates during a refresh;
- every combat event opened and wrote the JSONL journal synchronously, producing large intermittent stalls during clustered attacks.

## 3. Optimization changes

The solution is deliberately narrower than a worker-AI rewrite:

- deterministic incoming-by-destination, outgoing-by-source, and incoming-to-central task reservation indexes wrap the existing task semantics;
- indexes are rebuilt/incrementally maintained with correctness checks against brute-force reservation totals;
- unchanged economic selection, inventory accounting, construction delivery, road rules, and worker state transitions are retained;
- hostile candidate ranking is cheap and deterministic, with AStar stopped after the best reachable target is found;
- non-urgent target refresh is staggered across seven deterministic buckets;
- diagnostic events remain immediately available in memory but JSONL lines are batched and flushed once per tick (at most 0.1 seconds), including an explicit flush before the last-run snapshot;
- existing path caches and occupancy-driven invalidation remain authoritative; `NavigationAgent3D` was not substituted for deterministic pathfinding.

At 200 inhabitants, carrier discovery fell to **5.684 ms average / 6.819 ms p95**, inventory search to **0.943 / 1.178 ms**, and total worker update to **7.030 / 8.343 ms**. Scan volume fell to about **2,767 items/tick**.

## 4. 25/50/100/150/200 inhabitant results

All timings below are fixed-tick authoritative timings; presentation extraction is measured separately. Values are from the same machine and harness before and after the task-index change.

| Live inhabitants | Baseline avg | Baseline p95 | Baseline p99 | Baseline max | Optimized avg | Optimized p95 | Optimized p99 | Optimized max | Speed-up by avg |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 25 | 0.604 ms | 1.258 ms | 1.648 ms | 1.708 ms | 0.501 ms | 0.799 ms | 1.007 ms | 1.013 ms | 1.21× |
| 50 | 2.896 ms | 4.075 ms | 4.648 ms | 5.164 ms | 1.126 ms | 1.522 ms | 1.728 ms | 1.760 ms | 2.57× |
| 100 | 18.567 ms | 23.433 ms | 33.094 ms | 34.411 ms | 2.853 ms | 3.358 ms | 3.562 ms | 3.739 ms | 6.51× |
| 150 | 44.746 ms | 48.947 ms | 51.328 ms | 56.014 ms | 5.134 ms | 7.165 ms | 9.412 ms | 9.979 ms | 8.72× |
| 200 | 85.599 ms | 100.125 ms | 113.661 ms | 128.981 ms | 7.324 ms | 8.758 ms | 10.443 ms | 13.595 ms | 11.69× |

Optimized 200-agent presentation snapshot extraction was 2.473 ms average and remained a secondary, bounded cost. Detailed per-system results are in `artifacts/phase3/performance/optimized_index_authoritative_profile.json`.

## 5. Economic regression comparison

The canonical outcomes match exactly at every population:

| Inhabitants | Baseline hash | Optimized hash | Result |
| ---: | ---: | ---: | --- |
| 25 | 1180584311 | 1180584311 | Identical |
| 50 | 2582431151 | 2582431151 | Identical |
| 100 | 2815118731 | 2815118731 | Identical |
| 150 | 3092201680 | 3092201680 | Identical |
| 200 | 496064444 | 496064444 | Identical |

The comparison covers resources, reservations, cargo, buildings/inventories/staffing/status, workers and their state distribution, population/housing/hunger, enemies, projectiles, and tick. Dedicated Phase 3 tests also compare indexes to brute-force values and exercise path-cache invalidation.

## 6. Housing integration

The adapter now exposes population, capacity, occupied housing, homeless pressure, free/assigned staff, and shelter occupancy. The HUD presents population/capacity and alerts; House inspection presents occupants. Actual residents travel according to authority. Occupied houses gain restrained warm window light at night rather than spawning decorative residents.

## 7. Hunger and food integration

Food, hungry population, consumption pressure, local input/output, and stalled production are visible in the HUD and inspector. The playable chain is the existing authoritative **Farm → Wheat → Bakery → Bread → population consumption** flow. The no-fixture playthrough built the chain from starting resources, observed naturally produced Wheat and Bread, then observed night consumption/hunger accounting without injected inventory.

## 8. Day/night/shelter integration

The adapter passes the current phase and worker shelter/rest states to production views. Workers finish or leave work, travel to shelter, disappear consistently into an occupied building, and return after rest according to the simulation. Sun/fill/sky lighting blend through daylight, dusk, night, and dawn; night remains deliberately readable. The approved semantic sleep mappings remain available, while the production strategy rule is exterior disappearance plus visible occupancy/window light rather than rendered interiors.

## 9. Production-status UI

The functional inspector explains staffed/unstaffed state, current worker count, input/output inventory, active/idle state, missing inputs, blocked outputs, construction progress, access/road issues, occupancy, HP/damage, and autonomous/direct-control status as relevant. Build failures surface their authoritative reason. Alerts cover housing/food/staffing/stalled production/construction and threat states with deduplication instead of raw dictionary output.

## 10. New building identities

The Phase 2.1 scale hierarchy and road/world proportions are unchanged. Existing semantic wrapper/catalog infrastructure now gives:

- **Farm**: a crop/work-yard identity with a distinct silo context;
- **Bakery**: oven/chimney and production-yard identity;
- **Storehouse**: wider storage wings/piles and a stronger warehouse silhouette.

They are distinguishable at normal gameplay zoom without requiring labels. This uses existing assets and kitbashing; no new custom-model pipeline was introduced.

## 11. Fog/scouting implementation

The world view renders an authoritative world-space unknown mask and hides unrevealed hostile entities. Revealed ground remains readable and enemy presentation cannot leak through unknown territory. The current authority supports permanent revealed versus unknown tiles; it does **not** model “explored but not currently visible” separately. Phase 3 therefore stops at the supported two-state distinction instead of faking a third state.

## 12. Rival presentation

Actual rival roads, workers, Sovereign, structures, camps, and lifecycle are included in semantic snapshots and reconciled into 3D registries. Rival ownership uses salmon/red cloth, banners, equipment accents, and readable unit treatment rather than whole-building recolors. Rival settlement activity remains authority-driven and was present throughout the fixture-free demonstration.

## 13. Claim/Lumen presentation

Own and rival claim relationships are rendered with restrained world-space rings/accents, emphasizing relevant territory without a permanent giant colored grid. Lumen sources and semantic connectivity come from authority snapshots. Rival claim rings, structures, and roads are visible in the scouting evidence; hidden hostile information remains fog-gated.

## 14. Sovereign control decision

**Decision A: the Sovereign remains directly controllable as a unique hero exception.**

W/A/S/D and right-click move only the player Sovereign. Q requests attack, E requests Wyrd extraction, C requests claim, and F focuses the camera. The production inspector labels ordinary workers and soldiers as autonomous/inspect-only. Camera pan moved to arrow keys or middle-drag so legacy W/A/S/D bindings cannot accidentally imply army micro-control.

## 15. Military integration

Friendly soldiers, rival military, raiders, and the Sovereigns reuse the shared character-view system with semantic Idle, Walk/Run, Guard/Patrol, Melee, Ranged, Hit, Die, and Flee mappings where authority supplies them. Silhouette/equipment, restrained banners, selection rings, hit reactions, and contextual damage state distinguish roles and allegiance. Ordinary soldiers remain autonomous and are influenced through military construction/staffing decisions.

## 16. Tower, wall, and gate integration

Watchtowers use authoritative staff, targeting, HP, attack, projectile origin, and destruction state. A migration defect found by the real playthrough—construction-site Watchtowers were omitted while seeding the wall-network connection check—was fixed by using the planned building type during construction.

Walls reconcile connection-aware straight/corner orientation and damage state. Gates are distinct, readable wrappers and retain authoritative occupancy/path behavior. Placement previews use the real selected building name, footprint, rotation, validity, and reason.

## 17. Raid proof

`tests/phase3_real_game_playthrough.gd` performs the required sequence through the production 3D start menu with seed `260821` and no fixture state or resource injection. It builds a road network, House, Lumber Camp, Watchtower, Quarry, Sawmill, Farm, Bakery, and Barracks; grows from population 2 to 8+; produces the required inputs; trains and staffs defence; reaches real night/shelter and meal processing; encounters two naturally spawned enemies; observes an authoritative tower projectile and casualty; resolves the raid; saves; exits the run; reloads exact post-raid state; reconstructs all views; and continues another 20 ticks.

The current persisted demonstration is `artifacts/phase3/persistence/real_game_playthrough.json`. The most recent verification reloaded at tick 12,002 and continued to tick 12,022 with the 32-building economy intact.

## 18. Combat presentation architecture

Combat remains:

`Simulation → ProductionPresentationAdapter → semantic snapshot → production 3D views`

The adapter exposes combatants, allegiance/role, animation state, target/damage/HP/death, towers, gates, projectiles, rival roads/structures, claims, and visibility. Character/building/projectile views interpolate and decorate those outcomes; they never decide collision or damage. Projectiles are glowing authoritative trails, not physics hit detectors. Death plays, remains briefly, then retires through a bounded view cleanup; corpses are not saved or accumulated.

## 19. Combat mixed-load performance

These 1920×1080 Forward+ profiles use the real no-fixture post-raid save, live economy, roads, active construction, workers, target selection, combatants, and projectile-capable defence. VSync was disabled; each result used a one-second warm-up and four-second rendered sample on an NVIDIA RTX 4070.

| Quality | Civilians + hostiles | Avg FPS | Frame mean | Frame p95 | Frame p99 | Tick avg | Tick p95 | Tick max |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Recommended | 100 + 20 | 135.1 | 7.40 ms | 26.78 ms | 31.66 ms | 7.37 ms | 11.92 ms | 35.77 ms |
| Recommended | 150 + 30 | 78.4 | 12.75 ms | 39.29 ms | 49.91 ms | 13.55 ms | 24.72 ms | 51.44 ms |
| Recommended | 180 + 20 | 69.4 | 14.41 ms | 42.87 ms | 49.60 ms | 14.16 ms | 21.34 ms | 45.34 ms |
| Scalable Low | 180 + 20 | 71.2 | 14.05 ms | 42.49 ms | 48.11 ms | 14.02 ms | 20.88 ms | 45.17 ms |

The old sustained 100+ ms authority cliff is gone, and 200 total active entities remain interactive above the requested 60 FPS average. A 42–43 ms p95 frame at this artificial mixed stress scale remains a real pacing limitation. Scalable Low changes draw cost less than expected here because authoritative live-agent work dominates. Full artifacts are the four `mixed_*.json` files in `artifacts/phase3/performance/`.

## 20. Save/load after combat

Save schema remains version 7. Combat/rivalry state serializes through the existing authority, including integer-keyed dictionaries (the Phase 3 playthrough exposed and fixed an unsafe `String(key)` conversion by using deterministic `str(key)`). The real demonstration saved after the raid, reset/exited the run, loaded, compared core economy/building state exactly, rebuilt production 3D registries, and continued simulation.

Save/load errors are surfaced in the normal UI instead of silently ignored. The default Windows save location is `%APPDATA%\Godot\app_userdata\Shard & Sovereign\one_shard_save.json`.

## 21. 3D interaction tests

New semantic interaction coverage validates the actual production UI rather than pixel comparison:

- normal start-menu visibility and New Settlement with a review seed;
- Load Settlement and Quit presence;
- categorized building menu and complete tooltip content;
- plan selection, placement preview, placement commit, and selection;
- pause/resume across simulation and presentation;
- Save, Load, and return-to-main-menu behavior.

`tests/phase3_ui_interaction_smoke.gd` passes. Living/combat lifecycle coverage is in `tests/phase3_living_combat_smoke.gd`; scale/index/cache coverage is in `tests/phase3_task_index_smoke.gd`.

## 22. Playtest UX

`Play SnS 3D.bat` opens the production 3D client to a normal menu with **New Settlement**, **Load Settlement**, **Quit**, editable/blank random seed, known-good review-seed guidance, and Recommended/Scalable Low quality selection. The game HUD exposes resources, population/housing, time/day, pause, 1×/2×/4× speed, categorized functional buildings, tooltips, inspection, Save, Load, alerts, and Copy Debug Info. Debug profiling is opt-in and not visible in normal play.

Semantic ambience, construction, work/production, raid warning, combat impact, and UI feedback are wired for playtest use; Phase 3 does not claim a final audio mix. The practical handoff is `docs/playtest/PHASE_3_PLAYTEST_GUIDE.md`.

## 23. Screenshot paths

All captures are 1920×1080 production 3D gameplay using Forward+:

1. `artifacts/phase3/screenshots/01_developed_daytime_settlement.png`
2. `artifacts/phase3/screenshots/02_night_shelter.png`
3. `artifacts/phase3/screenshots/03_food_housing_economy.png`
4. `artifacts/phase3/screenshots/04_rival_territory_scouting.png`
5. `artifacts/phase3/screenshots/05_defensive_settlement.png`
6. `artifacts/phase3/screenshots/06_raid_approaching.png`
7. `artifacts/phase3/screenshots/07_active_melee_ranged_combat.png`
8. `artifacts/phase3/screenshots/08_tower_projectile_engagement.png`
9. `artifacts/phase3/screenshots/09_post_raid_settlement.png`
10. `artifacts/phase3/screenshots/10_playtest_ui_build_menu.png`
11. `artifacts/phase3/screenshots/11_save_load_reconstructed.png`
12. `artifacts/phase3/screenshots/12_stress_200_inhabitants.png`

The capture harness is `tests/phase3_capture_suite.gd`; it loads the real playthrough save as its production base rather than a presentation-only fake economy.

## 24. Known issues

- Fog has authoritative revealed/unknown states but no separate temporary-current-visibility state.
- The 200-entity mixed stress case averages above 60 FPS but retains ~43 ms p95 frames; 100 civilians + 20 hostiles is substantially smoother.
- Scalable Low cannot remove the dominant authoritative live-agent cost at extreme population.
- The functional 1080p UI is dense and remains internal-playtest art.
- Night is intentionally strategy-readable rather than cinematic darkness.
- Death views retire after a short presentation; persistent corpses are outside current authority/save semantics.
- Audio is semantic and usable but not a final fully positioned mix.
- Automated Godot teardown reports certificate-store and occasional ObjectDB/resource cleanup warnings in the isolated harness. The functional suites exit successfully; these warnings are not observed as in-game failures.
- The first night can legitimately be quiet because raid size remains simulation-driven.

## 25. Legacy 2D status

The legacy 2D client and launcher path were preserved and continue to pass the established construction, presentation, rivalry, release, and rebuild authority suites. The rendered legacy mouse harness still reproduces exactly three known synthetic-click failures: return from How to Play, open Settings, and start a new game. This is the debt called out in the brief, not a new production-3D interaction failure. No legacy files were deleted to force the migration.

## 26. Exact launch instructions

From Windows Explorer, double-click:

`D:\SnS_Isometric\Play SnS 3D.bat`

The launcher runs the production scene in Forward+ with the Recommended profile and opens the start menu. Enter `260821` for the known-good review seed or leave the field blank for a generated seed, then choose **New Settlement**. Use **Load Settlement** on a later launch to continue the most recent version-7 save.

For a lower-cost presentation, select **Scalable Low** on the start menu. The older client remains reachable from the production UI and through `tools/launch_client.ps1` with its default legacy presentation.

## 27. Final recommendation

**PASS — ready for user playtest**

The measured 200-live authority cliff is resolved without economic divergence; real residents work, produce food, consume, shelter, and return; rivalry/claims/fog and autonomous raids/defence are visible; the production UI supports building, inspection, alerts, pause/speed, Save/Load, and feedback capture; the no-fixture real-game demonstration passes; the required screenshots exist; and established authoritative regressions remain green.

Validation completed for this candidate:

- 28/28 C# simulation tests pass;
- established Godot construction, presentation, rivalry, release, rebuild, Phase 2.1 scale, Phase 2 catalog, Phase 2 vertical slice, Phase 2 production 3D, and Phase 2 playthrough suites pass;
- all Phase 3 task-index, living/combat, production-3D UI, and no-fixture real-playthrough suites pass;
- the 1920×1080 Forward+ screenshot suite passes on the RTX 4070;
- the documented legacy synthetic mouse harness reproduces its expected three failures exactly.
