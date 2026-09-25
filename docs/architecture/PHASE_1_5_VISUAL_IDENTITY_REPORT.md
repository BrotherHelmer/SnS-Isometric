# Shards & Sovereign — Phase 1.5: Visual Identity & Settlement Quality Gate

Date: 2026-08-21  
Godot: `4.7.stable.official.5b4e0cb0f`  
Scope: isolated `phase1_3d_lab` presentation only  
Final status: **PASS — promote presentation into Phase 2**

## Executive result

The isolated lab now reads as a deliberately composed Shards & Sovereign settlement rather than a rectangular KayKit test map. The hidden square simulation grid, authoritative simulation, adapter/view architecture, animation system, scale profile, catalogs, wrappers, and runtime asset pipeline remain intact.

The visible world is an irregular wooded island with a shallow shoreline, animated deep water, coherent regional ground treatment, and no visible terrain or water rectangle in the acceptance views. A compact village is organized around the Town Hall with a residential pocket and dedicated lumber, farm, mine, defensive, and harbour districts. Workplaces are visually self-explanatory, inhabitants are staged by purpose, and a rare cyan/violet civic Shard motif provides restrained original identity.

The six required 1920×1080 screenshots were rendered without HUD obstruction and reviewed at original resolution. The 24/100/200 actor profiles remain comfortably above the current target. Phase 1.5 therefore passes, but this report does not perform or authorize broad production migration.

## 1. Visual changes made

- Replaced the slab silhouette with a shader-clipped irregular island while preserving the rectangular logical/collision space beneath it.
- Replaced one flat ground color with coherent grass, dry grass, shore, rocky, work-yard, farm, and harbour regions.
- Rebuilt water and shore presentation, road geometry, forest distribution, settlement layout, work yards, activity staging, lighting, camera framing, and palette.
- Expanded the six proven semantic building types to eight wrapper instances by adding two more House wrappers for a readable residential pocket.
- Added five simultaneous work VFX cues, 18 staged job-related actors, and three persistent staged cargo movements while retaining the authoritative lumber worker and real Wood 12→14 proof.
- Kept all acceptance screenshots free of the lab HUD so the visual centre is unobstructed.

## 2. Terrain changes

The visible terrain is now an organic island centered around the settlement. A continuous rectangular mesh still supports the proven navigation, collision, and hidden logical grid, but the terrain shader discards pixels outside a multi-frequency elliptical boundary. This makes the visible coast smooth and irregular without rebuilding simulation or map generation.

Terrain height retains broad elevation, district flattening, and a shallow coastal falloff. Vertex-color regions provide a grounded grass base, warm dry grass, slate mine ground, ochre lumber/farm dirt, a worn harbour apron, and a wet shore transition. Variation uses large coherent functions and district masks rather than random speckling.

## 3. Road solution

The three wide Phase 1 strips were replaced by five hierarchical routes:

- a 1.48 m main harbour–civic–lumber route;
- a 1.18 m mine path;
- a 1.12 m defensive approach;
- a 0.92 m farm path;
- a 0.78 m residential footpath.

Catmull–Rom sampling creates smoother bends. Width varies mildly along each route. Five cross-road color bands provide softer edges, two restrained rut lines, and a warmer centre. All routes converge legibly at the Town Hall without dominating the village.

## 4. Water and shore solution

Deep water uses a low-cost subdivided plane with two small shader-driven wave components and a restrained blue-green palette. The surface was enlarged beyond every accepted camera frustum, so no rectangular water edge appears.

A separate irregular ring follows the entire island boundary as a lighter shallow-water band. Selective shoreline rocks, a darker wet ground transition, and small reed clusters break up the edge. The harbour pier crosses the land boundary into usable water and is reinforced with mooring posts, cargo, logs, and a rope coil.

## 5. Forest composition rules

The proof still contains exactly 284 nature instances, but placement now follows composition rules:

- dense interiors concentrate at the north, east, south, and non-harbour west island edges;
- settlement, district, and road masks push trees out of work space;
- thinner forest borders prefer bushes, grass, and smaller trees;
- dense interiors prefer larger mixed tree variants;
- eastern rocky woodland occasionally substitutes rock variants;
- the southern camera-facing edge uses smaller vegetation before the dense interior to reduce foreground occlusion;
- the harbour, mine, farm, lumber yard, civic centre, residential area, and watch approach retain authored clearings.

The strategic image now distinguishes forest, clearing, settlement, rocky mine, and shore at a glance.

## 6. Settlement composition

Seven readable districts form one compact settlement:

1. Civic centre — Town Hall, road convergence, plaza, banners, civic goods, and Lumen marker.
2. Residential — three House wrappers grouped between Town Hall and watch approach.
3. Lumber edge — sawmill, timber yard, workers, smoke, chips, and adjacent forest.
4. Farm yard — six ordered plots, crop rows, tools, wheelbarrow, and low fence.
5. Mine — rock face, slate ground, ore, cart, tools, debris, and dedicated road.
6. Defensive edge — Watchtower on the western approach with visible guard activity.
7. Harbour — pier, staging apron, posts, cargo, rope, logs, and direct road access.

Wilderness surrounds the settlement instead of filling gaps between evenly distributed buildings.

## 7. Building and work-yard treatments

| Building | Treatment |
| --- | --- |
| Town Hall | Clear central silhouette, road convergence, feathered civic plaza, two violet banners, arriving/departing people, civic cargo, and one restrained Lumen Shard |
| Houses | Three wrappers create a compact residential pocket with small domestic cargo props |
| Lumbermill | Ochre yard, two log stacks, two plank stacks, stump, exposed axe and saw, three relevant workers, smoke, and wood chips |
| Mine | Slate yard, six-rock face, stone and iron stacks, wheelbarrow, exposed pickaxe, two miners, and dust |
| Farm | Six plots, two crop types in rows, wheelbarrow, shovel, pitchfork, five-segment fence, farmers, and soil dust |
| Watchtower | Edge placement, direct approach path, patrolling knight, and ranged guard |
| Docks | Pier into water, four mooring posts, rope coil, barrels, crates, timber, dockworker, and road connection |

Clutter is concentrated around economic meaning rather than scattered uniformly.

## 8. Character staging changes

The baseline remains exactly 24 animated people. Ambient presentation now uses a curated `person + place + purpose` table before any overflow actors are generated. The acceptance scene contains:

- 18 actors in job, carry, or work states;
- woodcutters beside the lumber edge;
- miners in the rock yard;
- farmers inside the fenced plots;
- a sawyer and builder at relevant stations;
- three cargo carriers moving along authored road segments;
- a dockworker at the cargo apron;
- a knight patrol and ranged guard at the defensive edge;
- ordinary civic and residential traffic.

Four presentation-only route actors move continuously between authored endpoints. These routes create visual life but do not award resources or alter simulation state. The authoritative production worker remains separately identifiable and continues to drive the real lumber/cargo proof.

## 9. Palette and material changes

The environment now follows the “Shardlit Frontier” direction:

- warm muted olive grass with coherent dry regions;
- deeper, calmer forest greens;
- charcoal/slate mine ground and rocks;
- ochre roads and timber yards;
- warm timber and pale stone;
- reduced global saturation with modest filmic contrast;
- characters left comparatively colorful against a quieter environment.

Runtime model materials are not replaced. Shared tinted duplicates preserve vendor textures while gently warming buildings/props and darkening nature. Faction color remains limited to cloth/banner accents.

## 10. SnS identity additions

The civic centre contains the only supernatural visual cluster: a four-sided cyan Lumen shard, two smaller cyan/violet fragments, a small local light, and a geometric cyan slash on two violet banners. The effect is bright enough to make the Town Hall unique but rare enough to retain meaning. Ordinary tools, houses, trees, and roads do not glow.

## 11. Default camera recommendation

Recommend an orthographic size of **30** at the existing preferred yaw of **−0.62 radians**. This is substantially closer than the Phase 1 normal size of 43, yet still includes the civic centre, residential pocket, farm, lumber edge, defensive approach, and road to the mine.

Workers, tools, cargo, crop plots, and building silhouettes remain readable at this default. The close preset is 21. The strategic preset is 58 and intentionally abstracts individual activity while preserving settlement/forest/shore relationships. Rotation remains available in the lab, but the accepted images use a stable preferred orientation except for workplace framing.

## 12. New screenshot paths

All images are verified at 1920×1080:

| Required view | Path | Visual proof |
| --- | --- | --- |
| Hero close | `phase1_3d_lab\artifacts\screenshots_phase1_5\hero_close.png` | Town Hall identity, residents, roads, cargo traffic, farm, and lumber context |
| Default gameplay | `phase1_3d_lab\artifacts\screenshots_phase1_5\default_gameplay.png` | Intended playing zoom and compact village/wilderness relationship |
| Strategic | `phase1_3d_lab\artifacts\screenshots_phase1_5\strategic.png` | Organic island boundary, full settlement footprint, forest bands, and shallow-water halo |
| Lumber activity | `phase1_3d_lab\artifacts\screenshots_phase1_5\lumber_activity.png` | Sawmill, animated workers, physical cargo, logs, planks, tools, smoke/chips, and forest edge |
| Farm activity | `phase1_3d_lab\artifacts\screenshots_phase1_5\farm_activity.png` | Farmers, ordered fields, crop rows, tools, wheelbarrow, and fence |
| Harbour/shore | `phase1_3d_lab\artifacts\screenshots_phase1_5\harbour_shore.png` | Water, shallows, pier, road, worker, staged timber, rope, and mooring posts |

The corresponding capture logs are `phase1_3d_lab\artifacts\capture_phase1_5_*.log`.

## 13. Performance regression comparison

Method matches Phase 1: Forward+ at 1280×720 on the NVIDIA GeForce RTX 4070, VSync disabled, 120 warm-up frames, and 180 sampled frames. Phase 1.5 was required to rerun only 24, 100, and 200 actors.

| Actors | Phase 1 FPS | Phase 1.5 FPS | Phase 1.5 CPU ms | Phase 1.5 GPU ms | Phase 1.5 draw calls | Phase 1.5 VRAM | Interpretation |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 24 | 618.00 | 406.46 | 1.987 | 0.457 | 311 | 212.57 MB | Lower unlocked ceiling from water shader, extra props, shadows, and environment passes; still very large headroom |
| 100 | 247.00 | 255.00 | 4.996 | 0.650 | 595 | 221.38 MB | FPS +3.2%; draw calls −18.3% because composed forests occlude more of the scene at the closer camera |
| 200 | 116.88 | 124.38 | 8.441 | 1.272 | 1,093 | 233.28 MB | FPS +6.4%; CPU −5.7%, GPU −4.9%, draw calls −26.2% |

VRAM increased by approximately 10 MB at each actor count. The low-actor 24 case remains far beyond the current strategy-camera target, so no MultiMesh or major LOD rewrite was introduced.

### Physics profiler anomaly

Godot defines `Performance.TIME_PHYSICS_PROCESS` as the time to complete one physics frame, while physics callbacks normally run at a fixed tick interval. The old harness sampled that most recently completed physics value once per unlocked render frame, repeatedly weighting stale values; it is therefore not an additive per-render-frame budget. This interpretation is an inference from the monitor definition and the harness's unlocked sampling method. See the [Godot Performance monitor documentation](https://docs.godotengine.org/en/4.5/classes/class_performance.html#enum-performance-monitor) and [Node physics-process documentation](https://docs.godotengine.org/en/stable/classes/class_node.html).

The Phase 1.5 profile keeps the engine monitor under the explicit name `physics_monitor_last_tick_ms_average` and separately times the lab's `_physics_process` callback:

| Actors | Repeated engine monitor | Lab callback average | Lab callback maximum |
| ---: | ---: | ---: | ---: |
| 24 | 17.472 ms | 0.438 ms | 21.431 ms |
| 100 | 1.121 ms | 0.401 ms | 22.141 ms |
| 200 | 3.770 ms | 0.358 ms | 20.835 ms |

The occasional ~21–22 ms callback maximum is a real simulation synchronization spike worth watching, but the ~0.36–0.44 ms average explains why the prior repeated low-actor number did not match observed frame rate. Do not use the repeated engine-monitor average as a production budget.

Machine-readable profiles are in `phase1_3d_lab\artifacts\performance_phase1_5`.

## 14. Known visual weaknesses still remaining

- The harbour uses the allowlisted bridge model as a pier and has no authored boat. The staging reads correctly, but a small original pier/boat set would materially improve a later production pass.
- Houses and forest assets still repeat because this phase deliberately retained KayKit and avoided a custom-model pipeline.
- Terrain regions are procedural/code-authored rather than artist-painted. Production maps will eventually benefit from authored biome masks and terrain texture detail.
- The island silhouette is appropriate for this proof, not a commitment that every production map must be an island.
- Strategic zoom intentionally loses individual cargo readability.
- Dense foreground forest can occlude activity at arbitrary rotated angles; the preferred gameplay orientation is composed, but unrestricted rotation will need production camera/occlusion policy.
- Presentation-only ambient routes communicate work without changing economy. Only authoritative workers should be used when the production UI claims an economic outcome.

## 15. Files changed

- `phase1_3d_lab\scripts\phase1_lab.gd` — island, palette, water/shore, roads, forest rules, districts, work yards, activity staging, lighting, visual identity, capture composition, and physics instrumentation.
- `phase1_3d_lab\scripts\orthographic_camera_rig.gd` — 21/30/58 zoom recommendations and deterministic shot composition.
- `phase1_3d_lab\tests\capture_lab.gd` — named six-shot capture workflow and HUD-free output.
- `phase1_3d_lab\tests\profile_lab.gd` — Phase 1.5 output routing and corrected physics metric semantics.
- `phase1_3d_lab\tests\lab_smoke.gd` — visual-structure/activity assertions while retaining the authoritative lumber checks.
- `phase1_3d_lab\artifacts\screenshots_phase1_5\` — final six-image set.
- `phase1_3d_lab\artifacts\performance_phase1_5\` — final 24/100/200 profiles.
- `phase1_3d_lab\artifacts\capture_phase1_5_*.log` and `phase1_5_lab_smoke.log` — validation evidence.
- `docs\architecture\PHASE_1_5_VISUAL_IDENTITY_REPORT.md` — this report.

No shipping `main.tscn`, save format, gameplay balance, campaign, combat, UI, asset-source pipeline, or production simulation system was migrated or rewritten.

## 16. Recommendation

**PASS — promote presentation into Phase 2.**

The screenshot gate answers yes to the required majority: the world reads as a place, the simulation boundary is hidden, coastline and road hierarchy are coherent, forest edges are composed, the settlement has an obvious centre, economic buildings explain themselves through work yards, people visibly do useful work, default-zoom workers/cargo/buildings remain legible, the palette no longer resembles an untouched KayKit sample, and the civic Shard language is restrained but distinctive.

Phase 2 should promote these presentation patterns in small regression-tested slices. This report does not begin broad migration automatically.
