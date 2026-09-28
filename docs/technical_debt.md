# Technical Debt

## Resolved Items

### 2026-09-27: Export packing silent omissions (RESOLVED: playtest.23/.24)
- **Issue:** `export_filter="resources"` with explicit `export_files` list could silently omit runtime assets when string-concatenated or hardcoded paths not added to list (castle.tscn in playtest.22, audio files prior to playtest.24)
- **Resolution:** Created `tools/audit_export_packing.py` to systematically compare runtime asset paths (from `ProductionAssetCatalog3D.all_runtime_paths()` + `ProductionAudioDirector3D` paths) against `export_presets.cfg` export_files list. Audit runs as build preflight; exit code 1 blocks release if runtime assets missing
- **Status:** Closed playtest.24; audit confirms 0 missing runtime paths

### 2026-09-27: Night verification threshold mismatch (RESOLVED: playtest.25)
- **Issue:** Night verification test threshold (0.28 = 25% of day 1.12) was stricter than actual designed night lighting (0.35 = 31.25% of day). Test would fail when lighting correctly applied, pass when timing race prevented full lighting update—classic flaky check symptom. Forced `-SkipVerification` workaround in playtest.24
- **Resolution:** Test now checks against actual `Identity.LIGHTING["night"]["sun_energy"]` (0.35) + 0.02 tolerance, plus extra `await process_frame` for GPU state settling
- **Status:** Closed playtest.25; night mood preserved (ambient 0.50, sun 0.35, fill 0.32), release builds pass verification without `-SkipVerification`

### 2026-09-27: verify_release ExitCode/deadlock saga (RESOLVED: playtest.28)
- **Issue:** `Start-Process -PassThru` with stream redirection could leave `ExitCode` null even after `WaitForExit()` (playtest.25). ProcessStartInfo fix (playtest.26) introduced pipe buffer deadlock when `WaitForExit` called before draining streams. Async pattern (playtest.27) fixed deadlock but caused PS 5.1 host abort and test_release_package ExitCode=null
- **Resolution:** Both `verify_release.ps1` and `test_release_package.ps1` now use `System.Diagnostics.Process` + `ProcessStartInfo` with `StandardOutput.ReadToEndAsync()` / `StandardError.ReadToEndAsync()` started immediately after `Start()`, then `WaitForExit()`, then `Result` property access. This portable pattern drains streams asynchronously during process execution on both PS 5.1 and PS 7, preventing deadlock while avoiding host abort and ExitCode null races
- **Status:** Closed playtest.28 (merged GitHub, not built); reliable non-null `Process.ExitCode` maintained across both PowerShell versions in both verification and package soak tests

---

## Active Technical Debt

## 2026-06-28: Godot client shell uses GDScript

- Decision: The first Godot client shell is implemented as a small Godot-native GDScript scene script.
- Reason: This keeps the editor shell simple and avoids introducing Godot C# project generation/version concerns before gameplay integration.
- Expected cleanup trigger: When the Godot client begins calling the C# simulation directly, decide whether to keep lightweight GDScript for view/input code or migrate client scripts to C# for stack consistency.

## 2026-06-28: Godot placement uses a temporary GDScript simulation adapter

- Decision: The Godot shell uses `src/GodotClient/Scripts/client_simulation.gd` to validate placement, store debug client state, and mirror worker pathfinding and hauling for the editor prototype, while the tested C# simulation owns the canonical placement, pathfinding, movement, and hauling models.
- Reason: The current Godot client is GDScript and the Godot C# bridge is not configured yet.
- Expected cleanup trigger: Before expanding hauling beyond the first prototype loop, connect Godot to the C# command/pathfinding/save path or formally define a generated/shared contract so the two implementations cannot drift.

## 2026-06-28: Hauling uses an implicit single-worker task

- Decision: The first hauling loop stores source and destination building ids directly on the Carrier worker instead of creating a general task queue.
- Reason: The current prototype has one resource, one worker type, and no job priority, so a full task system would add complexity before it proves value.
- Expected cleanup trigger: Introduce a real `HaulResourceTask` queue before adding multiple workers, multiple producers, job priorities, or competing task types.

## 2026-06-28: Loaded workers reset active paths

- Decision: Save files persist worker position, carried Wood, and source/destination building ids, but not the active tile path.
- Reason: Paths are derived state and may become invalid after restoring. Resetting to `Idle` lets the Carrier rebuild a valid route from restored simulation state on the next tick.
- Expected cleanup trigger: Persist formal task state once the prototype has a real task queue, multiple workers, or player-facing save continuity requirements.

## 2026-06-28: Godot save/load mirrors C# contracts

- Decision: The Godot shell writes its temporary adapter state to JSON separately from the tested C# `WorldSaveService`.
- Reason: The Godot C# bridge is still not connected, so the editor prototype needs local save/load before the client can call the canonical simulation directly.
- Expected cleanup trigger: Replace the GDScript save/load adapter with calls into the C# simulation save service or generate a shared save contract.

## 2026-08-21: Phase 2 founding entrance contains duplicate road authority

- Decision: The production 3D adapter deduplicates completed roads by logical tile before creating road views.
- Reason: A founded run currently contains two authoritative completed `ROAD` records at the same Town Hall entrance tile. Rewriting or deleting one would alter existing simulation/save behavior during a presentation migration.
- Expected cleanup trigger: Repair the founding/building occupancy rebuild order under an authoritative simulation regression, then remove the defensive adapter deduplication when legacy saves no longer require it.

## 2026-08-21: Fully live 200-inhabitant simulation stress misses the provisional target

- Decision: Phase 2 ships the 3D presentation because normal live play, a representative 100-inhabitant live mix, and 200 visible authoritative views all remain practical on the measured machine. The pathological 200-inhabitant fully live benchmark remains recorded as a failure instead of being hidden.
- Reason: At 200 synthetic authoritative inhabitants the renderer remains above 100 FPS when the simulation is paused, but unpaused simulation ticks reduce the mean to roughly 9 FPS. This identifies simulation work scheduling/task search as the limiting layer, not 3D rendering.
- Expected cleanup trigger: Phase 3 should profile the authoritative tick, amortize worker/task synchronization and carrier task search, then rerun 100/200 live settlements before treating 200 fully active inhabitants as supported.

## 2026-08-21: Production water presentation is not yet exercised by generated data

- Decision: `WorldView3D` owns the required `Water` presentation root, but the current production terrain definitions/generator do not emit a water cell type.
- Reason: Inventing water tiles would change map-generation semantics, which Phase 2 explicitly preserves.
- Expected cleanup trigger: Add a data-driven water rule and visual implementation when authoritative map generation introduces water terrain.

## 2026-08-21: Phase 2 occlusion policy is composed rather than dynamic

- Decision: The production camera uses the accepted fixed orientation and forest presentation suppresses vegetation near roads, work yards, and construction sites.
- Reason: This keeps active economic routes readable without globally fading the forest or adding an unproven dynamic transparency system.
- Expected cleanup trigger: Add targeted camera-to-selection vegetation fading only if playtests show remaining foreground blockage at the fixed production orientation.

## 2026-08-21: Lower-end GPU performance is defined but not measured

- Decision: The production path includes `recommended` and `scalable_low` controls for shadows, foliage, water detail, VFX, animation LOD, anti-aliasing intent, and ambient actor budget.
- Reason: Only an NVIDIA GeForce RTX 4070 was available in the current environment; minimum-hardware numbers would be invented.
- Expected cleanup trigger: Run the same time-based profile on the selected minimum GPU and calibrate the quality profile from evidence.
