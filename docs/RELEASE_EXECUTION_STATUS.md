# Release execution status — 2026-09-27

Milestone: internal Windows candidate for closed Steam Playtest, then public demo. Steamworks setup remains deferred by the owner. **Not approved for external release.**

**Current version:** 0.2.0-playtest.27 (shipped) / 0.2.0-playtest.28 (merged, not built)  
**Comprehensive tracking:** See [ROADMAP.md](../ROADMAP.md) for current work, prioritized backlog, and release gates.

---

## Overnight Work Evidence (playtest.23–.28)

| Version | Date | Focus | Ship Status | Evidence |
|---------|------|-------|-------------|----------|
| **playtest.23** | 2026-09-27 | Castle morph export packing | Merged | Added `opening_style/castle.tscn` to export_files; Wine PASS (Town Hall → Castle morph visual confirmed) |
| **playtest.24** | 2026-09-27 | Audio export packing | Merged | 9 missing audio files added to export_files (bgm_settlement_loop.ogg, ambient_world.wav, saw.wav, 6 settler/building cues); audit tool confirms 0 missing runtime paths |
| **playtest.25** | 2026-09-27 | Night verify + audit preflight | Merged | Night threshold fixed (0.35 + 0.02 tolerance vs incorrect 0.28); audit_export_packing.py preflight integrated; **60-min soak: PARTIAL** (in-game RELEASE_PACKAGE_PROBE PASS 3601s / 0 errors; strict runner FAIL ExitCode=null) |
| **playtest.26** | 2026-09-27 | ExitCode capture fix | Merged (FAILED) | ProcessStartInfo pattern for reliable ExitCode; **introduced pipe buffer deadlock** (180s timeout, all test suites) |
| **playtest.27** | 2026-09-27 | Deadlock fix | **SHIPPED to Downloads** | Async stream draining (BeginOutputReadLine) fixed deadlock; full verification PASS; castle+audio packed; **SHA: zip DDDE0DF6… / HEAD c3601749** |
| **playtest.28** | 2026-09-27 | PS 5.1 compat + ExitCode | Merged, **NOT BUILT** | ReadToEndAsync pattern for PS 5.1/7 + verify_release + test_release_package; **Spawn offline overnight**, no build/ship |

**Key outcomes:**
- **Current playable:** 0.2.0-playtest.27 (Spawn Downloads, full verify PASS)
- **Soak status:** Playtest.25 60-min PARTIAL (in-game PASS, runner ExitCode=null fixed in .28 source but unshipped)
- **Steam status:** NO-GO (gates: Steamworks, pilots, full matches, low-end GPU, clean PC, WASAPI reconnect)
- **WASAPI reconnect:** NOT tested yet

---

## Implemented (playtest.25 and earlier)

**Build Pipeline & Verification (playtest.25, 24, 22):**
- Night verification hardened: test threshold now matches actual lighting design (0.35 + 0.02 tolerance vs incorrect 0.28), extra frame wait for GPU settling
- Export packing audit integrated: `audit_export_packing.py` runs as build preflight, exit code 1 blocks release if runtime assets missing
- Audit tool compares runtime paths from `ProductionAssetCatalog3D` + `ProductionAudioDirector3D` against `export_presets.cfg` export_files
- Prevents silent export omissions (playtest.22 castle.tscn, playtest.24 audio files) from reaching release
- Release builds can now pass verification without `-SkipVerification` flag (night check no longer flaky)

**Visual & Art (playtest.13, 12, 11, 8, 7, 6, 4, 3):**
- Castle visual: 4-tower fortress (was 3), taller keep, proper curtain walls, crenellations matching title art (12,840 tri)
- Barracks: dedicated military tower with shields, weapon racks (6,200 tri, was cottage + decorations)
- Town Hall → Castle morph (via `has_barracks`) reads as fortified stronghold at strategic zoom
- 19 opening-style model scenes: buildings, trees, rocks, props, walls
- Coordinated terrain/lighting/character materials for opening-style palette
- Pressure contrast, smoother fog boundary, exterior mist covering slab edges at max zoom
- Night lighting readable (ambient 0.50, sun 0.35, fill 0.32, night/day luminance ~0.27)
- C&C-style bottom building bar with visual icons (house silhouette, saw blade, shield/spear, etc.)
- Building occupancy indicators (window emission when staffed/garrisoned)
- Distinctive resource icons (log, wheat, stone, bread loaf, Wyrd crystal)
- Build tooltips showing purpose + costs on hover

**Audio (playtest.10, 9, 8):**
- Curated CC0 BGM and atmosphere audio (replaced procedural placeholders)
- Per-type spawn sounds for buildings, units, combat events
- Real foley with warmth and presence
- Comprehensive audio provenance ledgers

**Saves & Persistence (playtest.5, 4, 3, 2, 1):**
- Temporary save writes with last-valid backup recovery
- Unsupported-version rejection (formats 6–8 supported, future versions rejected)
- Map/entity/nested ledger validation, exact RNG state preservation
- Autosave every 2 minutes active real time
- Save-before-quit flow with window-close handling
- Previous-realm preservation, display settings persistence
- Verified cargo, active raid, mid-Binding, hunger save/reload cases
- Fixed construction reservation stranding, zero-capacity clearer accumulation, manual order cargo discard, night task reload drift

**Combat & Rivalry (playtest.5, 4):**
- Owner-selected assault/recall command for trained patrol soldiers
- Travel and in-range strikes against visible rival Outposts
- Disk persistence of assault state
- Tower guards engage properly (no fleeing), unmanned towers lower-priority
- Three-seed command-only bot completes all matches including mid-Binding reload (260821, 424242, 717171)

**UX & Readability (playtest.7, 6, 5):**
- Expanded fog-of-war reveal (8→12 tiles) for Day 1 Watchtower placement
- Road connectivity error messages with explicit guidance
- Increased starting Bread (12→18) and Town Hall overflow storage (8→20)
- Storehouse and Watchtower in early objectives
- Expanded build pad scanning (5→8 tiles) for better placement coverage
- Removed premature Shard direction indicator
- First-night warning mentions defensive buildings
- Reduced attack notification spam
- Camera stays on settlement (no auto-jump to shard)
- Build pad system highlights valid placement areas

**Technical (playtest.4, 3, 2, 1):**
- Versioned Forward+ export, pinned Godot 4.7/templates
- Explicit runtime resources, source/output hash manifest
- Standalone-copy validation, engine/component license notices
- Removed simulation/rivalry reference cycle
- Fixed zero-scale death animations (singular-transform errors)
- Cross-process persistence checks, audio-mixer sampling in diagnostics
- Windows-path quoting in test launchers
- Local feedback bundle (report, save, logs)
- 20-suite automated validation passes

## Evidence and limits

Current playable **0.2.0-playtest.27** is shipped to Spawn Downloads with full verification PASS, castle+audio packing confirmed (SHA: zip DDDE0DF6… / HEAD c3601749). Playtest.27 fixed the critical pipe buffer deadlock introduced in .26 via async stream draining (BeginOutputReadLine). Playtest.28 merged to GitHub (`82d587b50ccd888d385d5e2c2f5dbb68449747ca`) with ReadToEndAsync pattern for PowerShell 5.1/7 compatibility + ExitCode reliability in both verify_release and test_release_package, but **not built/shipped** (Spawn offline overnight).

Playtest.25 60-min soak: **PARTIAL pass** (in-game RELEASE_PACKAGE_PROBE PASS after 3601s with 0 errors; strict runner FAIL solely because `$process.ExitCode` was null, fixed in .28 source). Export packing audit (`tools/audit_export_packing.py`) runs as build preflight; exit code 1 blocks release if runtime assets missing from `export_presets.cfg`. This prevents silent export omissions (castle.tscn in playtest.23, audio files in playtest.24) from reaching release packages.

All **20** suite checks pass. The opening-style model set includes 19 authored scenes covering buildings, terrain features, and props. Character geometry and animations are retained with palette-adapted materials. See `docs/art/OPENING_STYLE_MODELS.md` for scope and limitations.

**Validation status:**
- ✅ Automated checks: 20/20 suites pass (parse, rebuild, rivalry, bakery, wyrdfall, full_run, human_playtest_rescue, presence, review_evidence, natural_match 3/3 seeds, opening_style_models, settlement_style_capture, etc.)
- ✅ Three-seed command-only bot completes all matches including mid-Binding save/reload (seeds 260821, 424242, 717171)
- ✅ Save safety: temporary writes, backup recovery, version rejection, structural validation
- ✅ Construction/logistics/rivalry/persistence cross-process checks pass
- ⚠️ 60-minute rendered package soak: playtest.25 PARTIAL (in-game PASS, runner ExitCode=null fixed in .28 source; awaiting .28 build+ship for complete soak)
- ❌ Observed new-player pilot (5-person, target 4/5 comprehension)
- ❌ Human complete matches (3+ natural sessions)
- ❌ Lower-end GPU performance (current evidence: RTX 4070 only)
- ❌ Clean physical Windows machine test
- ❌ WASAPI reconnect audible validation (not tested)

No complete hour-long soak, lower-end GPU test, or physical clean-machine validation has been performed for playtest.27 or .28.



## Historical Evidence (preserved for reference)

**Playtest.4** (2026-09-26) extended art direction across terrain, grass, bushes, wheat, character materials, remaining building models, wall crenellations, roads, fog and day/night lighting. All 20 suite checks passed. Rendered comparisons showed night/day mean luminance ~0.27. Exported package passed 60-second developed-settlement run (67.90s elapsed) with no errors. No hour-long soak performed for playtest.4.

Previous candidate **0.2.0-playtest.3** adds twelve playable opening-style models: six buildings, two trees, rocks, fence, lantern and cart. Related building roles reuse the appropriate new geometry. The town hall has a broader visual silhouette; its simulation footprint is unchanged. All **19** checks passed, including model bounds, grounding, selection, delivery sockets, construction/completion and nature-instancing structure. The exported Windows package passed a rendered 60-second developed-settlement check (66.27 seconds runner elapsed), with no errors. Actual model-gallery and exported opening screenshots were inspected. All runtime source hashes match the package manifest. See `docs/art/OPENING_STYLE_MODELS.md` for model scope, generation and remaining art work. This is a first playable adaptation; terrain, characters and remaining building families have not received the same treatment.

Previous candidate **0.2.0-playtest.2** replaces the opening backdrop with a dedicated illustrated settlement, preserves character animation state across menu pauses and animation-budget changes, and hides unexplored minimap markers (including the Shard and rival Town Hall). The worker T-pose came from animation-tree reactivation resetting playback to the empty Start state. All **18** focused checks pass, including a new presentation regression covering pause/resume, animation-budget toggles and hidden/revealed map pixels. The exported Windows package passed its rendered 60-second developed-settlement test with no logged errors. Its menu and opening screenshots were visually inspected. This candidate has not repeated the previous build's hour-long test.

All 17 focused checks passed in the working checkout and two new temporary clones. The latest source checkpoint `7ffc8ad` imported assets without an existing `.godot` cache, passed verification and exported successfully with `working_tree_dirty: false` in its manifest. This proves reconstruction on this PC, not a second physical machine. The verification runner records focused save, logistics, session, assault, UI, economy, rivalry and combat checks in `artifacts/release_candidate/verification.json`; `final_clean_verification.json` records the clean build. Supported-version migration tests relabel current data to exercise branches; genuine historical-save compatibility remains unproven.

The exported checkpoint completed 3,600.5 real seconds and 118 save/load/menu cycles, with no gameplay assertion failure or crash. The strict runner **failed** because WASAPI logged `GetBufferSize error` followed by an invalidated output-device warning around minute 35. Preserve this result as `package_rendered_60min_audio_invalidated`; do not relabel it a clean pass. Godot's [4.7 WASAPI driver](https://github.com/godotengine/godot/blob/4.7-stable/drivers/wasapi/audio_driver_wasapi.cpp) retries device initialization, but audible recovery was not observed. The next package diagnostic records mixer freshness as well as rejecting logged errors. Physical disconnect/reconnect listening remains unverified.

Windows private memory averaged about 1,298 MiB in minutes 15–20 and 1,304 MiB in minutes 45–50. This run shows no large sustained growth after warm-up; it is not a proof of leak freedom. Release-template engine memory counters return zero, so use `process_memory.json`. The latest package runner records an explicit overall `package_validation.json` alongside the in-game report.

The final `7ffc8ad` package passed a headless saved-cargo launch and a rendered 60-second developed-settlement check with audio-mixer sampling and no unexpected errors. The corresponding evidence is preserved in `package_rendered_final_60sec`. Its 60-minute rerun also passed: 3,600.517 in-game seconds, 118 save/load/menu cycles and no failures or logged errors. The in-game report and logs are preserved in `package_playtest1_completed_hour`; the overall result was read as passed before the newer candidate's test replaced the live runner outputs. This pass belongs to playtest.1. Playtest.2 evidence is archived in `package_playtest2_60sec`; `package_playtest3_60sec` preserves playtest.3; `package_rendered` now belongs to playtest.4. The ZIP contains the current known-issues note and provenance manifest.

Separate processes verified live cargo, an active night raid, natural mid-Binding and an explicitly prepared hunger case. Thirty simulation seconds after restore matched uninterrupted gameplay state within 0.00001 for floats, excluding journal text. Four corresponding standalone-package relaunches passed. A package copied into a path containing spaces also passed. These generated snapshots are not historical-save fixtures.

Current 1080p Forward+ stress samples on this RTX 4070 measured 183.5 average FPS / 28.2 ms p95 frame time at Recommended, and 181.4 FPS / 28.8 ms at Low. Each sample lasts 30 seconds after warm-up, starts with 180 requested civilians and 20 injected hostiles, and uses a scripted developed settlement. Population changes during the run; other diagnostics were running concurrently. These are diagnostic measurements, not minimum-hardware claims.

Unrestricted export was clean. Restricted tests emit an environment-only Windows certificate-store access error; the runner records that exact exception and rejects other engine/script errors. Supported scripts isolate APPDATA so tests do not touch normal saves.

`tests/release_natural_match.gd` is an accelerated command-only diagnostic: authored starting resources, public construction/Binding/assault requests and ordinary ticks, plus disk save/reload. The latest combined run **passes 3/3**: seed 260821 wins in 1,709.8 simulation seconds, 424242 in 2,205 seconds and 717171 in 1,985 seconds. All three restore from disk both during development and mid-Binding. The bot builds three defensive towers, permits Lumen detours around an occupied yard, and places a claim Outpost within the actual claim radius. These are strategy changes, not altered game costs, extra starting resources or fabricated victory state. Earlier failed strategies and the Outpost rule conflict are retained in the evidence. This does not prove human pacing, usability or every generated seed.

Older `phase4_full_run_harness` prepares world/claim state, and `phase3_2_real_playthrough` jumps the day clock. These remain useful regressions; neither is an unassisted full-match test.

## Remaining gates

1. Complete a clean final-package 60-minute test with audio-mixer sampling. Inspect logs and test audible device reconnection. Check lower-end graphics and a separate physical Windows machine.
2. Observe five new players using `OBSERVED_PLAYTEST.md`; target four understanding useful construction/delivery within five minutes and the next objective by ten. Play three human full matches, including a natural win and understandable defeat; then broaden the seed sweep.
3. Later: owner Steamworks/App IDs, distribution/branding rights review, Playtest setup, store assets and Valve review. Then a closed cohort; public demo depends on resulting fixes.

Automated checks cannot certify fun, comprehension, commercial rights, actual minimum hardware or Steam account readiness.
