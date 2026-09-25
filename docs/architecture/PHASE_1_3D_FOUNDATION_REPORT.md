# Shards & Sovereign — Phase 1: 3D Foundation & Living Settlement Proof

Date: 2026-08-21  
Godot: `4.7.stable.official.5b4e0cb0f`  
Renderer: Forward+ on NVIDIA GeForce RTX 4070  
Final status: **PASS — ready to proceed to Phase 2**

## Executive result

Phase 1 is complete in the isolated `phase1_3d_lab` subproject without replacing the shipping `main.tscn`, renderer, or production presentation. All six newly supplied KayKit archives passed the asset gate and were ingested beside the three preserved Medieval Hexagon archives. A 127-file runtime allowlist now separates immutable vendor source from imported assets.

Godot directly reuses the Rig_Medium animation libraries on Adventurer and Farmer characters; no retargeting is required. The lab renders a continuous isometric settlement with 284 nature instances, six stable building wrappers, exactly 24 active baseline `AnimationTree` characters, semantic tools/cargo, and an authoritative production lumber route. The smoke proof observed wood production, a visible log attached to the worker's hand, delivery, prop removal, and central storage changing from 12 to 14.

The complete 1280×720 and 1920×1080 close/normal/strategic screenshot matrix was captured. Performance was profiled at 24, 50, 100, and 200 animated actors; the 200-actor case averaged 116.88 FPS on the measured machine. Existing rebuild, construction, rivalry, presentation, and release suites still pass. The separately tracked rendered mouse harness reproduces its same three known click failures and is not a new Phase 1 regression.

| Acceptance gate | Result | Evidence |
| --- | --- | --- |
| Exact asset availability, licenses, hashes, extraction | **PASS** | Nine preserved archives; file counts match extraction; CC0 licenses retained |
| Rig_Medium direct compatibility | **PASS** | 3 characters, 23 named bones, 8 libraries, 139 clips, required clips deform poses |
| Isolated living-settlement lab | **PASS** | Forward+, continuous terrain/water/roads, 284 nature, 6 wrappers, 24 animated people |
| Semantic presentation boundary | **PASS** | Simulation → adapter → `CharacterView3D` → `AnimationTree` |
| Real lumber loop | **PASS** | Production and cargo observed; authoritative Wood 12→14 |
| Scale, screenshots, and profiles | **PASS** | Automated scale checks, six images, four actor-count profiles |
| Production regressions | **PASS** | Five authoritative suites pass; no new failure |

## 1. Godot version and execution boundary

The proof uses the installed Godot 4.7 stable desktop executable. The isolated subproject declares Forward+ and imports only its curated runtime assets. The existing shipping project remains separate and retains its own scene and renderer configuration.

Headless validation is performed one Godot process at a time with explicit project paths and log files. The desktop executable is used for all final checks because it provides the reliable project and `user://` behavior established by the Phase 0 gate. The console wrapper's lab-only headless crash is not treated as a project failure because the desktop executable completes the same imports and tests consistently.

## 2. Installed packs, versions, and license metadata

The authoritative vendor drop now contains:

- Character Animations 1.1.
- Adventurers Character Pack 2.0 FREE.
- Monthly Mystery Characters Series 6 1.1.
- Forest Nature Pack 1.0 FREE.
- Resource Bits 1.0 FREE.
- RPG Tools Bits 1.0 FREE.
- Medieval Hexagon Pack 1.0 FREE, EXTRA, and SOURCE.

All nine original ZIP archives and extracted versioned directories are preserved. Each extraction has an included `License.txt`; every license is CC0 1.0. Exact byte sizes, SHA-256 hashes, source directory names, member counts, and license dates are recorded in `docs\art\ASSET_LEDGER.md`.

## 3. Formats imported and rig compatibility

Rigged characters and animations use vendor-supplied GLB. Static environment, buildings, tools, and resources use the supplied glTF with their BIN and texture dependencies. No lossy or opaque conversion step was introduced.

The focused Godot gate loaded Barbarian, Farmer_A, and Farmer_B. All expose the same 23 named joints with compatible parent and rest relationships. Farmer_B's numeric bone indices differ, confirming that name-based binding is required. All eight Rig_Medium libraries bind directly and visibly deform the meshes; no retargeting is needed.

## 4. Exact scale profile chosen

The canonical profile is centralized in `scale_profile.gd`:

| Quantity | Value |
| --- | ---: |
| Godot world unit | 1 metre |
| Logical simulation cell | 2.50 m |
| Terrain elevation unit | 0.45 m |
| Character source-to-world scale | 0.75 |
| Tool scale | 0.82 |
| Cargo scale | 0.72 |
| Character forward axis | +Z |
| Character ground offset | 0.02 m |
| Door-clearance target | 2.10 m |

Measured final character heights are 1.7983 m for Barbarian, 1.8084 m for Farmer_A, and 1.7468 m for Farmer_B. Normalized building heights range from 2.093 m to 4.974 m and clear the canonical humanoid target. The wrapper origin represents the footprint centre at terrain height while vendor pivots remain unchanged; dock supports intentionally extend below the shoreline surface.

## 5. Source/runtime asset boundary

`assets\Kaykit` is immutable source and is hidden from the root Godot scanner with `.gdignore`. `tools\phase1_sync_runtime_assets.ps1` copies only allowlisted source files into `phase1_3d_lab\assets\runtime`, includes all required dependencies, mirrors the four production simulation scripts, and writes a hash manifest.

The current manifest contains 127 unique runtime paths: 8 characters, 8 animation libraries, 19 building assets, 13 farm assets, 45 nature files, 19 resource files, 11 tool files, and 4 integration scripts. Re-running the sync script reconstructs that boundary without editing vendor content.

## 6. Display versus source actor count

The acceptance baseline contains exactly 24 displayed characters and 24 active `AnimationTree` instances. Actual simulation workers are included in that count; ambient inhabitants fill the remainder to keep the proof stable while the live worker roster changes. The character rotation includes six Adventurers plus Farmer_A and Farmer_B and presents farmer, civilian, soldier, worker, and combat-readable roles.

The profile harness can raise the displayed count to 50, 100, or 200 through a runtime argument without altering the 24-actor acceptance scene.

## 7. Available and tested animations

The eight Rig_Medium libraries import 139 clips: CombatMelee 22, CombatRanged 20, General 15, MovementAdvanced 13, MovementBasic 11, Simulation 14, Special 15, and Tools 29.

The rig test verified availability and actual pose change for Idle_A, Walking_A, Running_A, Chop, Hammer, Pickaxe, Melee_1H_Attack_Chop, Hit_A, and Death_A. Holding_A is present and the holding proof attaches a real log to `handslot.r`. The semantic state set covers Idle, Walk, Run, Carry, WorkGeneric, Chop, Mine, Farm, Hammer, Saw, Sleep, Flee, Melee, Ranged, Hit, and Die.

Although the source libraries contain 43 root-position tracks, world translation is intentionally simulation-owned. Animation root movement is not applied to economic or navigational state.

## 8. Static asset count by category

The runtime allowlist provides six named building models, 22 distinct nature model choices backed by 45 dependency files, five hand tools, five cargo/resource choices, seven workyard props, and five farm/yard props. The scene instantiates 284 nature objects, shoreline rocks, workyard/farm/dock dressing, six buildings, and three dirt-road ribbons.

The scene count is deliberately different from the source-pack count: only the assets required for the living-settlement proof enter Godot's import graph.

## 9. Preferred formats actually imported

GLB is preferred for rigged assets because it carries mesh, skin, skeleton, and animation data as one authored file. Vendor GLB is used for all eight characters and eight animation libraries. Supplied glTF is used directly for static content because its explicit BIN/texture dependency set is deterministic and already supported by Godot 4.7. No FBX or OBJ asset is used at runtime.

## 10. Navigation and physics approach

The landscape is a continuous triangulated terrain mesh with broad elevation, a flattened settlement clearing, a matching concave static collision shape, and one `NavigationRegion3D`. Water is a separate surface with a dressed shoreline. Roads are three continuous ribbons with bends and a visible junction rather than disconnected tile decals.

The authoritative simulation continues to own logical tile routes. The presentation maps those tile positions into the 2.5 m world-cell profile, smooths displayed movement, and turns the character toward travel direction. This keeps gameplay path decisions independent from animation playback.

## 11. Wrapper and integration behavior

Six `BuildingView3D` wrappers expose stable entity IDs, semantic type names, camera focus points, and presentation states for TownHall, House, Lumbermill, Mine, Watchtower, and Docks. Their states include Placed, Selected, Built, Damaged, Destroyed, and Completed, with a wrapper-owned selection ring.

The character path is:

`production Simulation snapshot → SemanticPresentationAdapter → CharacterView3D → AnimationTree`

Only the adapter interprets simulation dictionaries. `CharacterView3D` receives semantic state, heading, tool, and cargo; it never writes production, inventory, pathfinding, or combat state. Tools and cargo come from semantic catalogs and attach through named `BoneAttachment3D` sockets.

The lumber proof loads byte-for-byte mirrors of the production definitions, tuning, rivalry, and simulation scripts. It constructs a real road, Lumber Camp, reachable tree, producer inventory, and carrier route. The animation layer observes the simulation and cannot manufacture the successful result.

## 12. Screenshot paths and explanations

All captures passed exact-dimension checks:

| Resolution | Close — character/cargo readability | Normal — living-settlement composition | Strategic — full footprint |
| --- | --- | --- | --- |
| 1280×720 | `phase1_3d_lab\artifacts\screenshots\1280x720\close.png` | `phase1_3d_lab\artifacts\screenshots\1280x720\normal.png` | `phase1_3d_lab\artifacts\screenshots\1280x720\strategic.png` |
| 1920×1080 | `phase1_3d_lab\artifacts\screenshots\1920x1080\close.png` | `phase1_3d_lab\artifacts\screenshots\1920x1080\normal.png` | `phase1_3d_lab\artifacts\screenshots\1920x1080\strategic.png` |

Close capture waits for the live physical cargo state. Normal and strategic captures wait for the authoritative delivery state, so their HUD shows the completed 12→14 Wood change. The matrix depicts the same running proof at three orthographic sizes rather than composited stills.

## 13. Camera controls and comfort notes

The camera is orthographic with close, normal, and strategic sizes of 20, 43, and 66. WASD or arrow keys pan relative to the current yaw, Q/E rotate, the mouse wheel zooms, and middle-mouse drag pans. Motion, rotation, and zoom ease toward targets, and pan bounds prevent losing the settlement.

The default isometric view uses an elevated 34 m camera offset and a slightly rotated yaw. Important silhouettes, roads, work zones, water, and the six building types remain readable at all three presets.

## 14. Performance metrics

Method: Forward+ at 1280×720, VSync disabled, 120 warm-up frames followed by 180 sampled frames. Values are hardware-specific development measurements, not cross-device release guarantees.

| Animated actors | Avg FPS | Minimum FPS | CPU frame ms | Render CPU ms | GPU ms | Draw calls | Objects | Visible objects | Video memory |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 24 | 618.00 | 618 | 1.933 | 0.274 | 0.331 | 251 | 3,476 | 688 | 202.51 MB |
| 50 | 347.00 | 347 | 2.801 | 0.402 | 0.443 | 406 | 4,012 | 851 | 205.52 MB |
| 100 | 247.00 | 247 | 4.601 | 0.836 | 0.572 | 728 | 5,050 | 1,188 | 211.32 MB |
| 200 | 116.88 | 116 | 8.952 | 1.878 | 1.337 | 1,482 | 7,123 | 1,990 | 223.24 MB |

Machine-readable results are under `phase1_3d_lab\artifacts\performance`.

## 15. Optimization decisions

- Curated 127-file import boundary instead of importing every FREE/EXTRA/SOURCE duplicate.
- Packed scenes and animation libraries are loaded through one catalog and reused across wrappers.
- One shared semantic animation graph shape is built per view; presentation never duplicates simulation logic.
- Nature is grouped into spatial chunks for organization and future visibility work.
- The Phase 1 proof retains individual nature instances and active trees to measure a conservative, inspectable scene. MultiMesh, animation distance throttling, and LOD remain available for later scaling but are not needed for the 200-actor target on the measured hardware.

## 16. Known risks and cleanup items

- Performance numbers come from one RTX 4070 Windows development machine. Integrated GPUs and target minimum hardware still need release profiling.
- The lab reports exit-time cleanup warnings for 8 ObjectDB instances and 2 resources. They occur after successful checks and should be removed before demanding leak-clean CI.
- The rendered mouse harness still fails three established synthetic-click checks: return from How to Play, open Settings, and start New Game. Keyboard/headless release behavior and the other click checks pass. This failure predates and is independent of the isolated 3D lab.
- The source tree has extensive pre-existing uncommitted rebuild changes. Phase 1 did not normalize, discard, or commit those unrelated changes.
- The runtime integration scripts are mirrors, so their hashes should be refreshed with the sync tool whenever the production simulation changes.

## 17. Files added or modified

Primary Phase 1 deliverables:

- `assets\Kaykit\` — preserved archives, immutable extracted source, licenses, and `.gdignore`.
- `tools\phase1_sync_runtime_assets.ps1` — deterministic runtime asset and integration mirror sync.
- `phase1_3d_lab\project.godot` and `main.tscn` — isolated Forward+ project and entry scene.
- `phase1_3d_lab\scripts\asset_catalog.gd` — semantic runtime paths.
- `phase1_3d_lab\scripts\scale_profile.gd` — canonical units, scales, axes, and pivots.
- `phase1_3d_lab\scripts\semantic_presentation_adapter.gd` — simulation-to-presentation boundary.
- `phase1_3d_lab\scripts\character_view_3d.gd` — rig, animation tree, socket, tool, and cargo wrapper.
- `phase1_3d_lab\scripts\building_view_3d.gd` — stable building wrapper.
- `phase1_3d_lab\scripts\orthographic_camera_rig.gd` — comfortable isometric controls.
- `phase1_3d_lab\scripts\phase1_lab.gd` — continuous settlement, real simulation bridge, and proof HUD.
- `phase1_3d_lab\tests\` — rig, scale, lab smoke, capture, and profile harnesses.
- `phase1_3d_lab\artifacts\` — validation logs, JSON profiles, and screenshot matrix.
- `docs\art\ASSET_LEDGER.md` and this report — durable audit and handoff.

The shipping `main.tscn` was not replaced.

## 18. Commands used to validate the phase

From `D:\SnS_Isometric`:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\phase1_sync_runtime_assets.ps1

.\.tools\godot-4.7\Godot_v4.7-stable_win64.exe --headless --path .\phase1_3d_lab --import
.\.tools\godot-4.7\Godot_v4.7-stable_win64.exe --headless --path .\phase1_3d_lab --script res://tests/rig_validation.gd
.\.tools\godot-4.7\Godot_v4.7-stable_win64.exe --headless --path .\phase1_3d_lab --script res://tests/scale_validation.gd
.\.tools\godot-4.7\Godot_v4.7-stable_win64.exe --headless --path .\phase1_3d_lab --script res://tests/lab_smoke.gd
```

Capture and profile harnesses accept `--size=1280x720`, `--zoom=close|normal|strategic`, and `--actors=24|50|100|200`. Final logs and JSON files are retained with the artifacts, along with the production regression logs under `artifacts\phase1_resume`.

## 19. Requirements proven

Every Phase 1 acceptance item is now proven:

- exact required assets, licenses, hashes, extraction, and runtime provenance;
- direct shared-rig compatibility without retargeting;
- canonical scale and pivot profile;
- isolated Forward+ living settlement with continuous terrain, roads, water, elevation, 284 nature instances, and six building wrappers;
- 24 simultaneous animated people and the complete semantic state vocabulary;
- semantic tool and cargo sockets;
- real authoritative wood production and delivery with visible physical cargo;
- orthographic camera controls, lighting, shadows, environmental atmosphere, and work VFX;
- required two-resolution, three-zoom screenshot matrix;
- 24/50/100/200 animated-actor performance profiles;
- preserved production rebuild, construction, rivalry, presentation, and release behavior.

No required acceptance item remains blocked.

## 20. Final recommendation

**PASS. Proceed to Phase 2.**

Treat `phase1_3d_lab` as the reference presentation architecture: keep simulation authoritative, promote catalog/wrapper/adapter patterns deliberately into the shipping client, and preserve the source/runtime asset boundary. Phase 2 should first choose target hardware budgets and then fold the proven components into production in small regression-tested slices rather than swapping the shipping main scene wholesale.
