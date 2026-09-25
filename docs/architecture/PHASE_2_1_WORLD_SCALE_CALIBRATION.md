# Shards & Sovereign — Phase 2.1 World Scale Calibration

Date: 2026-08-21  
Status: **PASS — begin Phase 3**

Phase 2.1 recalibrates the production 3D settlement around the unchanged Rig_Medium humanoid. It changes presentation scale, composition, sockets, selection, work yards, and construction massing only. Simulation footprints, placement, road connectivity, pathfinding, economy, save schema, and the legacy 2D client remain authoritative and unchanged.

The deterministic Phase 2 developed fixture was the visual decision surface. Current scale, blanket 1.35×, 1.50×, and 1.65× candidates, and the final per-building profile were compared from the same 1920×1080 camera. Final values were selected from the screenshots, not numerical bounds alone.

## 1. Previous scale values

The unchanged character reference is `CHARACTER_MODEL_SCALE = 0.75`. Its imported presentation AABB is 1.635 world units high; Phase 2.1 normalizes that displayed height to the canonical 1.80 m visual person.

| Building | Previous scale | Previous character heights | Previous normalized height |
|---|---:|---:|---:|
| Town Hall | 1.25 | 3.042 | 5.476 m |
| House | 2.20 | 1.251 | 2.252 m |
| Lumber Camp | 1.50 | 1.567 | 2.821 m |
| Sawmill | 1.55 | 1.619 | 2.914 m |
| Quarry | 1.80 | 1.251 | 2.252 m |
| Farm | 1.55 | 0.882 | 1.588 m |
| Bakery | 1.90 | 1.081 | 1.946 m |
| Storehouse | 2.55 | 1.451 | 2.612 m |
| Watchtower | 1.50 | 2.011 | 3.620 m |
| Barracks | 1.50 | 3.651 | 6.572 m |

The baseline measurements are preserved at `artifacts/phase2_1/measurements/baseline_bounds.json`.

## 2. Candidate values tested

The ordinary-building baseline was reviewed at the requested blanket multipliers:

| Candidate | Relative multiplier | Result |
|---|---:|---|
| A | 1.35× | Better, but Houses and several reused production silhouettes still read as miniatures. |
| B | 1.50× | Stronger inhabitant/building relationship; House door and low-profile workplaces remained marginal. |
| C | 1.65× | Good general mass for House/Lumber, but a single multiplier flattened hierarchy and did not repair the very small Farm/Bakery baseline. |
| Final | Per building | Selected from door, roof, footprint, work-yard, clearance, and hierarchy review. |

Evidence:

- `artifacts/phase2_1/comparison/01_current_production_scale.png`
- `artifacts/phase2_1/comparison/02_candidate_a_1_35x.png`
- `artifacts/phase2_1/comparison/03_candidate_b_1_50x.png`
- `artifacts/phase2_1/comparison/04_candidate_c_1_65x.png`
- `artifacts/phase2_1/comparison/05_final_selected_calibration.png`

All five are 1920×1080. The final capture uses the production Forward+ renderer. The staged reference people are existing real fixture character views paused and repositioned beside semantic sockets for comparison only; simulation authority is not changed.

## 3. Final building scales

All final values and imported unit bounds are centralized in `production_scale_profile.gd`; there are no scene-local emergency scale overrides.

| Building | Final scale | Relative to previous | Character heights | Normalized visual height |
|---|---:|---:|---:|---:|
| Town Hall | 2.00 | 1.60× | 4.867 | 8.761 m |
| House | 4.40 | 2.00× | 2.503 | 4.505 m |
| Lumber Camp | 2.50 | 1.67× | 2.612 | 4.701 m |
| Sawmill | 2.60 | 1.68× | 2.716 | 4.888 m |
| Quarry | 3.25 | 1.81× | 2.259 | 4.067 m |
| Farm | 4.60 | 2.97× | 2.617 | 4.710 m |
| Bakery | 4.60 | 2.42× | 2.617 | 4.710 m |
| Storehouse | 5.50 | 2.16× | 3.128 | 5.631 m |
| Watchtower | 3.50 | 2.33× | 4.692 | 8.445 m |
| Barracks | 1.90 | 1.27× | 4.624 | 8.323 m |
| Wall | 0.86 | unchanged | — | — |
| Lumen Pillar | 2.10 | unchanged | — | — |
| Claimant Outpost | 3.25 | calibrated tower profile | — | — |

Quarry is the deliberate low, wide exception: its mine silhouette reads through breadth and mouth size rather than roof height. Farm, Bakery, and Storehouse reuse the same current KayKit home mesh but require different scale and yard treatment to communicate their semantic hierarchy.

Final recursive imported-mesh measurements are stored at `artifacts/phase2_1/measurements/final_bounds.json`.

## 4. Human/door measurements

- Reference person: 1.635 rendered world units at scale 0.75, normalized to 1.80 m visual height. Character scale was not changed.
- House: 4.092 rendered units high, 2.503 people to the roof ridge, and 4.505 m normalized overall. In the final Human-vs-House image, the stylized outer door arch is approximately 1.1–1.2 displayed human heights, or roughly 2.0–2.2 m visual clearance.
- Farm/Bakery use the same entrance mesh at the slightly larger 4.60 scale; their door clearance is therefore no smaller than House.
- Storehouse uses the same base entrance at 5.50 and reads as a larger service/storage doorway.
- Lumber Camp and Sawmill are open workplaces; their working bay/open side clears the worker rather than presenting a conventional closed door.
- Town Hall and Barracks use the castle portal; direct worker comparisons show the portal at usable stylized clearance while the overall civic/defensive mass remains within the intended hierarchy.
- Quarry uses its mine mouth as the primary usable opening. Watchtower/Outpost use their defensive platform access rather than an ordinary residential door.

Door clearance is a visual measurement because the KayKit meshes do not expose doors as separate semantic submeshes. `01_human_vs_house.png`, `02_human_vs_lumber_camp.png`, and `03_town_hall_hierarchy.png` are the authoritative presentation checks.

## 5. Tree adjustments

Only the largest canopy variants were reduced:

| Tree model | Final multiplier | Reduction |
|---|---:|---:|
| `Tree_1_C_Color1` | 0.85 | 15% |
| `Tree_2_B_Color1` | 0.92 | 8% |
| `Tree_2_C_Color1` | 0.88 | 12% |

All other trees, bushes, grass, and rocks remain at their previous model scales, preserving forest variation and mature-tree dominance. Nature transforms apply the centralized model multiplier for both map and boundary instances.

A presentation-only clearance rule suppresses nature instances within the larger of authoritative footprint extent or final visual extent, plus 1.35 logical tiles. It does not delete resources or modify terrain. The final forest-edge image keeps mature trees larger than Houses without diminishing the Town Hall into a miniature.

## 6. Road-width adjustments

The current 1.00 width and the requested 0.85/0.80/0.75 review range were assessed after building enlargement. The final `ROAD_WIDTH_SCALE` is **0.80**, a 20% presentation reduction.

Road centre discs and connectors use the same multiplier. Logical road tiles, connection masks, route semantics, placement, and pathfinding are unchanged. At normal zoom the route now reads as a road rather than a plaza while retaining comfortable two-character visual capacity.

## 7. Prop adjustments

World/work-yard props now have a separate centralized scale profile:

| Props | Final multiplier |
|---|---:|
| Wood/log and plank stacks | 0.82 |
| Stone stack | 0.85 |
| Barrel, crate | 0.90 |
| Long crate | 0.88 |
| Wheelbarrow | 0.85 |
| Dirt plot, pitchfork, carrot, lettuce | 0.90 |
| Decorative work-yard axe | 0.90 |

The Lumber work axe is a world prop placed beside the foreground log stack so the required worker/building/log/tool composition is explicit. Character-attached tools remain `TOOL_MODEL_SCALE = 0.82`; physical carried cargo remains `CARGO_MODEL_SCALE = 0.72`. Those character-relative values were not indiscriminately reduced.

Work-yard layouts were moved to the sides/back of the enlarged meshes: lumber stacks and planks flank the mill, quarry material and wheelbarrow sit laterally, farm plots extend behind the workshop, and civic/storage/bakery props no longer compete with their structures.

## 8. Wrapper/socket changes

`ProductionBuildingView3D` now derives presentation geometry from the final centralized imported bounds:

- the mesh front-aligns inside its unchanged hidden footprint so its visible entrance remains near the authoritative road/access edge;
- entrance, pickup, drop-off, worker station, construction delivery, left/right work-yard, VFX, and camera-focus sockets derive from final visual width/depth/height;
- pickup/drop-off and delivery remain outside the visible front face instead of inside enlarged walls;
- selection collision and ring use the union of authoritative footprint and final visual model mass;
- camera focus and VFX height follow the final silhouette;
- visual nature clearance follows the enlarged wrapper without changing occupancy.

The scale smoke verifies the recalibrated entrance lies outside the visible door face but remains within 0.75 m of the logical footprint edge. The normal simulation route/access point remains roughly one metre in front of that entrance, so live workers approach the visible door/work area without entering the mesh.

## 9. Construction visual changes

Construction presentation now derives from the same final model dimensions and model-front offset as the completed wrapper:

- foundation width/depth corresponds to final mass while remaining bounded by the logical footprint;
- foundation and emerging structure share the final model centre offset;
- scaffold post height and progress-label height follow final building height;
- visible partial stages use 46%, 76%, and 100% vertical reveal at the existing authoritative progress thresholds;
- the near-complete stage already uses the full final model scale, preventing a completion growth pop;
- construction delivery socket, selection area, and camera focus use calibrated geometry.

`phase2_1_world_scale_smoke.gd` verifies the foundation, all partial stages, and equality of near-complete/completed scale.

## 10. Screenshot paths

Required final Forward+ production screenshots, all verified at 1920×1080:

1. `artifacts/phase2_1/screenshots/01_human_vs_house.png`
2. `artifacts/phase2_1/screenshots/02_human_vs_lumber_camp.png`
3. `artifacts/phase2_1/screenshots/03_town_hall_hierarchy.png`
4. `artifacts/phase2_1/screenshots/04_village_default_view.png`
5. `artifacts/phase2_1/screenshots/05_forest_building_relationship.png`
6. `artifacts/phase2_1/screenshots/06_construction_scale.png`

The normal camera remains at orthographic size 30.0. Scale ratios solved the miniature-settlement problem, so no default-camera zoom change was needed and strategic zoom remains intact. The construction evidence turns the fixed camera 180 degrees for a clear view of the same deterministic site; it does not move the site or alter simulation state.

## 11. Regression results

Final 2026-08-21 results:

| Gate | Result |
|---|---|
| `phase2_1_world_scale_smoke.gd` | PASS — hierarchy, sockets, selection, footprint authority, props/trees/roads, and construction scale |
| `phase2_catalog_integrity.gd` | PASS |
| `phase2_vertical_slice_smoke.gd` | PASS — Lumber, Farm/Wheat, roads, save/load reconstruction |
| `phase2_production_3d_smoke.gd` | PASS — placement ghost, construction, stable wrappers, physical cargo, create/remove sync |
| `phase2_demo_playthrough.gd` | PASS — deterministic launch-to-reload proof |
| `godot_rebuild_smoke.gd` | PASS |
| `godot_construction_smoke.gd` | PASS |
| `godot_rivalry_smoke.gd` | PASS |
| `godot_presentation_smoke.gd` | PASS — rerun with writable isolated Godot user data so the settings-persistence assertion is valid |
| `godot_release_smoke.gd` | PASS |
| C# simulation suite | PASS — all 28 tests |
| `godot_release_mouse_smoke.gd` | Known debt unchanged — exactly 3 synthetic-click failures |

The unchanged rendered mouse failures remain: return from How to Play, open Settings, and start New Game. The same harness still passes button existence, opening How to Play, Back reachability, pause Resume existence, and pause Resume click. Scripted Godot shutdown continues to report the previously documented object/resource/RID leak warnings.

No economy values, simulation footprint definitions, save schema, or path/road connectivity code changed. The better screenshots do not hide a gameplay regression: placement, selection bounds, construction, worker access, physical cargo, Lumber, Farm/Wheat, and reconstruction all pass.

## 12. Remaining scale weaknesses

- Farm, Bakery, Storehouse, and House still share one KayKit base silhouette; scale and work yards distinguish them, but bespoke semantic wrappers remain future art work.
- KayKit doors are embedded geometry rather than named submeshes, so door clearance remains a screenshot-based stylized assessment rather than an automated door AABB measurement.
- Fixed-camera clearance handles the deterministic core well, but a selected-entity vegetation fade may still be useful if later playtests reveal occlusion at arbitrary edge settlements.
- Authoritative workers route to logical road/access positions rather than consuming presentation markers directly. Front alignment keeps the final stops visually plausible; future animation polish could bridge the remaining short doorstep distance without changing simulation routes.
- Construction scaffolding is deliberately approximate and parametric; it now matches final mass and completion scale but is not a bespoke kit for every silhouette.
- Large mature trees correctly remain larger than Houses, so isolated edge structures can still be partly framed by canopy at some pan positions. This is intentional unless playtest evidence shows loss of interaction readability.
- Generic later-game catalog fallbacks remain outside this scale-only pass. The Phase 2 live-200 simulation performance debt is unchanged and was not optimized.

## 13. Final recommendation

**PASS — begin Phase 3**

All acceptance questions can reasonably be answered yes. People read as inhabitants rather than giants; House doors are usable; Houses contain plausible interior volume; production buildings read as workplaces; Town Hall and towers establish civic/defensive hierarchy; props remain props; roads read as routes; mature forests stay imposing; the default view reads as a denser village; and simulation/economy authority remains unchanged.

Do not begin Phase 3 automatically from this task. Phase 2.1 is complete and the repository is ready for the user to authorize the next phase.
