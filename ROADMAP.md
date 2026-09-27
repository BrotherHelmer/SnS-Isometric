# Shard & Sovereign — Development Roadmap

**Last updated:** 2026-09-27  
**Current version:** 0.2.0-playtest.13  
**Target:** Closed Steam Playtest → Public Demo

This roadmap tracks progress toward a releasable Windows settlement survival game: build an economy with autonomous workers, defend against night raids, race a rival realm to Bind the central Shard. Owner-confirmed route: **closed Steam Playtest first, then public demo** after validation gates pass.

---

## Current Milestone

**Milestone: Internal Closed Playtest Candidate**

Prepare a validated Windows package for supervised external testing. The game must demonstrate a complete playable loop (founding → economy → defense → Shard race → victory/defeat) with comprehensible onboarding, reliable saves, and no progression blockers.

**Status:** Playtest.13 completes castle/barracks visual refinement matching title art. Core gameplay loop is implemented and passes automated checks. External human validation gates remain open.

---

## Completed Work (Recent)

### Playtest.13 (2026-09-27) — Castle & Barracks Visual Refinement
- Enhanced castle visual: 4-tower fortress (was 3-tower), taller keep, proper curtain walls with crenellations matching title splash art
- Dedicated barracks mesh: military watchtower structure with shields and weapon racks (was cottage + decorations)
- Town Hall → Castle morph (via `has_barracks` trigger) now reads as fortified multi-tower stronghold at strategic zoom
- Castle: 12,840 triangles, barracks: 6,200 triangles
- All opening_style models regenerated with updated geometry
- Fixes Wine playtest observation: buildings now match title art fidelity

### Playtest.12 (2026-09-27) — Multi-Tower Castle
- Replaced 3-tower castle with larger 4-tower opening_style design
- Improved fortress silhouette at strategic camera distances

### Playtest.11 (2026-09-27) — Castle Freeze Fix & Icon Improvements
- Fixed CASTLE per-frame rebuild regression (freeze-guard: `TOWN_HALL` + `has_barracks` → `CASTLE` view cached)
- Improved C&C bar building icons for better visual clarity
- Catalog paths and view logic preserved

### Playtest.10 (2026-09-26) — Audio Integration
- Integrated curated CC0 BGM and atmosphere audio (replaced procedural placeholders)
- Per-type spawn sounds for buildings, units, combat events
- Real foley replaces thin synthesized audio
- Fixed P0 bugs: castle freeze, camera zoom, audio volume, build bar

### Playtest.9 (2026-09-25) — Audio Foundation
- Replaced procedural audio with organic CC0 synthesis
- Enhanced audio warmth and presence
- Comprehensive audio provenance ledgers

### Playtest.8 (2026-09-24) — Visual Polish & UX
- Camera stability: removed automatic shard-reveal jump
- Building visual identity: lumber camp tent vs sawmill blade, farm sheep/paddock, enhanced barracks armor/banner
- Town Hall → Castle visual upgrade when Barracks built (turrets, crenellations, royal banner)
- C&C-style bottom bar: visual building icons (house silhouette, saw blade, shield/spear, etc.) replacing plain color blocks
- Build tooltips: show building purpose + resource costs on hover
- Resource icons: distinctive icons (log, wheat stalks, stone, bread loaf, Wyrd crystal)
- Fixed camera, color cast, clickable build bar

### Playtest.7 (2026-09-23) — Combat & Placement UX
- Removed premature Shard direction indicator
- Expanded build pad scanning radius (5→8 tiles) for better placement coverage
- Unmanned watchtowers treated as lower-priority targets
- Tower guards engage enemies properly (no fleeing)
- Removed "Carrying" field from guard inspection (guards don't haul)
- Occupancy indicators: subtle daytime window emission when staffed/garrisoned

### Playtest.6 (2026-09-22) — Early Defense Readability
- Increased starting fog-of-war reveal (8→12 tiles) around Town Hall
- Players can now place Watchtower sensibly on Day 1 before first night
- Improved road connectivity error messages with explicit guidance
- Increased starting Bread (12→18) and Town Hall overflow storage (8→20)
- Added Storehouse and Watchtower to early objectives
- Improved night lighting (ambient 0.38→0.50, sun 0.24→0.35, fill 0.24→0.32)
- Enhanced first-night warning mentions defensive buildings
- Reduced attack notification spam

### Playtest.5 and earlier — Foundation
- Three-seed command-only bot now completes all matches including mid-Binding save/reload (seeds 260821, 424242, 717171)
- Accelerated natural-match diagnostic passes 3/3 with authored starting resources and public construction/Binding/assault requests
- Supported save formats: versions 6–8 with structural validation, migration, and future-version rejection
- Temporary save writes with last-valid backup recovery
- Autosave every 2 minutes active real time
- Save-before-quit flow with window-close handling
- Verified cargo, raid, mid-Binding, and hunger persistence cases
- Fixed construction reservation stranding, zero-capacity clearer accumulation, manual order cargo discard, night task reload drift
- Removed simulation/rivalry reference cycle
- Pressure contrast fix, smoother fog boundary, exterior mist
- Owner-selected assault/recall command for rival Outpost removal
- Fixed zero-scale death animations producing singular-transform errors
- Cross-process persistence checks, audio-mixer sampling in diagnostics
- Versioned Forward+ export, pinned Godot 4.7/templates, explicit runtime resources, hash manifests
- Source/output validation, standalone-copy testing, engine/component license notices
- 19 opening-style model scenes with coordinated terrain/lighting and character materials
- All 20 suite checks pass (including wall-direction assertion)

---

## Current Work

1. **Comprehensive repository audit and documentation sync**
   - Audit all docs against current 0.2.0-playtest.13 baseline
   - Update version references in README, PLAYTEST_GUIDE, RELEASE_EXECUTION_STATUS, PLAYTEST_KNOWN_ISSUES
   - Replace ancient `docs/tasks/backlog.md` (woodcutter prototype milestones) with pointer to this ROADMAP
   - Update `docs/tasks/current_task.md` to reflect current milestone and gates

2. **Validation and evidence gathering**
   - Complete clean 60-minute package test with audio-mixer sampling
   - Inspect logs and test audible device reconnection
   - Verify lower-end GPU performance (current evidence: RTX 4070 only)
   - Test separate physical Windows machine (clean install, no Godot dev tools)

---

## Prioritized Backlog

### P0 — Release Blockers (Must complete before external distribution)

**External Validation Gates**
- **Observed new-player pilots:** Conduct 5-person unassisted first-session pilot using `OBSERVED_PLAYTEST.md`. Target: 4/5 understand construction/delivery within 5 minutes and next objective by 10 minutes.
- **Human full matches:** Play 3+ complete human sessions on different seeds including natural victory and understandable defeat. Record stall points, time to food stability, first raid, first expansion, Binding, and result.
- **Hour-long soak:** Complete 60-minute rendered package test with audio-mixer sampling, log inspection, and audible WASAPI device reconnect validation.
- **Lower-end GPU:** Test on integrated/low-end GPU at Scalable Low settings. Verify 45 FPS target with p95 frame time ≤33ms and no >100ms stalls. Current evidence limited to RTX 4070.
- **Physical clean machine:** Test clean Windows install without Godot, verify installation, saves, full match on non-development PC.

**Steamworks & Distribution (Owner-led)**
- Owner: establish real base-game App ID, complete Steamworks onboarding, confirm product name/publisher/positioning
- Create separate linked **Steam Playtest** child app with Windows depot configuration
- Developer: prepare SteamPipe config, upload approved candidate to test branch, verify installation/update on non-dev account
- Complete asset provenance inventory: reconcile KayKit CC0 ledger, audio ledger, UI/fonts, logo, notices with actual exported runtime assets
- Owner: complete content survey including player-facing AI-generated art/audio/text (title splash art is pre-generated AI; runtime kit is KayKit + authored; audio is CC0)
- Supply current gameplay screenshots, capsule/library assets, clear description, measured system requirements, working support route

**Why P0:** Cannot distribute externally without Steamworks setup, asset rights clearance, and human validation evidence. Automated checks prove stability, not fun or comprehension.

---

### P1 — Closed Playtest Readiness (Required before public demo)

**First-Ten-Minutes Readability** (if pilots reveal issues)
- If pressure label contrast still poor at 720p/1080p: improve independently of meter fill
- If fog boundary or exposed map rim visible at supported zoom/pan: refine boundary smoothing and exterior mist coverage
- If founding yard feels sparse/uninhabited: compose denser scene using existing props/activity without adding buildings
- If opening instruction unclear: ensure one actionable step consistent with House/Lumber/Farm economy, explain road access, staffing, full storage, wheat-to-bread hauling
- Verify threat direction, dusk prep, rival progress, Binding requirements understandable without developer narration
- Verify menu/build/inspector/minimap overlap, font size, pause/resume, focus loss, display changes, volume settings, persistence

**Natural Match Validation**
- Run full regression set through production authority including UI/input and disk persistence
- Build command-driven full-match regression (seeds 260821, 424242, 717171) using normal starting resources and public requests (no injected stockpiles, instant buildings, or fabricated victory state)
- Expand seed sweep to look for inaccessible resources and unwinnable openings
- Exercise broken roads/reconnection, clearing, depleted deposits, full storage, starvation/recovery, soldier staffing, interrupted Binding, rival victory, restart

**Why P1:** Required for credible public demo. Small comprehension issues can be tolerated in closed cohort with disclosed limitations; public demo needs to onboard independently.

---

### P2 — Post-Demo Polish & Expansion (Defer until core loop validated)

**Visual & Audio Polish**
- C&C build bar icons: evaluate if current procedural ColorRect silhouettes need replacement with rendered 3D building thumbnails or higher-fidelity sprites matching opening_style models
- Character animation: current rigs retained with palette materials; consider full opening_style character art matching title illustration (deferred until gameplay validated)
- Additional ambient audio: expand soundscape for construction, weather, time-of-day transitions (current: curated CC0 foley + BGM)

**UX Refinements**
- Tutorial/objectives: expand objective detail panel with clearer next-step guidance
- Advanced camera options: evaluate dynamic vegetation fade for occlusion (current: composition-based suppression near roads/yards)
- Feedback report: enhance local bundle with additional diagnostics, seed reproduction steps

**Technical Improvements**
- Simulation performance: profile authoritative tick, amortize worker/task search (current: 200 live inhabitants stress test fails at ~9 FPS on RTX 4070)
- Save/load: test genuine historical-save compatibility (current: test relabeling, not real historical fixtures)
- Lower-end hardware: calibrate `scalable_low` quality profile from measured minimum-spec GPU evidence

**Content Expansion (Scope Freeze Until Validation)**
- DO NOT add: new buildings, multiplayer, hero combat, campaigns, engine changes
- After public demo validation: consider additional economy/defense buildings within One Shard scope
- Controller/Steam Deck/Linux support: not currently advertised; validate separately if pursued

**Why P2:** These are improvements, not blockers. Core loop must prove fun and comprehensible before expanding content or chasing lower-end hardware extremes.

---

## Known Bugs

**Confirmed Issues:**
- WASAPI audio device invalidation: 60-min playtest.1 soak logged `GetBufferSize error` around minute 35. Godot 4.7 WASAPI driver retries initialization but audible recovery unobserved. Next package diagnostic records mixer freshness; physical disconnect/reconnect listening remains unverified. (P0 gate)

**Historical/Monitoring:**
- Restricted dev environment: cannot read Windows certificate store. Unrestricted export clean; environment-only error recorded separately from game failures.
- ObjectDB/resource cleanup errors: emitted by tests but assertions pass. Preserve logs; investigate if exported build reproduces.
- Simulation/rivalry reference cycle: removed in playtest.5+. Old saves may carry legacy references; migration tested via relabeling, not genuine historical fixtures.
- Construction reservation stranding: fixed for cancellation-before-pickup, clearers, manual orders. Monitor for edge cases.
- Night task reload drift: fixed. Cargo state, targets, priorities validated across save/reload.

**Resolved (retain for regression monitoring):**
- Castle per-frame rebuild freeze: fixed playtest.11+ with freeze-guard (`TOWN_HALL` + `has_barracks` → cached `CASTLE` view)
- Zero-scale death animations: fixed, no longer produce singular-transform errors
- Duplicate road authority at Town Hall entrance: presentation adapter deduplicates; authoritative repair deferred pending simulation regression
- Thin procedural audio: replaced with curated CC0 foley in playtest.9+
- Camera jump to shard: removed playtest.8+, camera stays on settlement
- Pressure text contrast: improved; verify at 720p/1080p during pilots
- Premature shard direction reveal: removed playtest.7+

---

## Design Decisions Requiring Owner Input

**Visual Identity Confirmation**
1. **Castle/Barracks vs Title Art:** Playtest.13 castle (4-tower fortress, 12,840 tri) and barracks (military tower, 6,200 tri) now match title art fortress scale and craft language. Requires human visual judgment: does the in-game castle upgrade read as the title splash's fortified settlement when zoomed to strategic view? Wine playtest prompted this revision; final approval needed.

2. **Walls: KayKit Bridge vs Opening_Style Treatment:** Current walls use KayKit vendor geometry extended with opening_style crenellations (playtest.4). This is a deliberate bridge strategy. Decision needed: keep hybrid approach for scope/schedule, or commit to full opening_style wall reconstruction matching castle/barracks craft language? Latter adds art/performance work; former may read as visual inconsistency.

**Product Scope & Timing**
3. **Steamworks / App IDs / Store Identity:** Owner controls Steam account, App ID creation, Playtest child-app setup, store page content, and public release timing. Developer cannot proceed with Steam upload/testing without real IDs and permissions. Confirm timing: set up Steamworks in parallel with current validation work, or defer until human pilots pass?

4. **Session Length Hypothesis:** Current 35–55 minute target is provisional (from Phase 4 design). Three-seed bot completes matches in 1,710–2,205 simulation seconds (accelerated). Human pacing, pause usage, and fun remain unvalidated. After first human full matches: adjust economy tuning, adjust target, or accept wide variance?

5. **Content Survey & AI Disclosure:** Title splash art (`title_settlement_v1.png`) and art kit reference (`settlement_kit_reference_v1.png`) are pre-generated OpenAI images (2026-09-26, documented in `assets/art_direction/opening_style_v1/README.md`). Runtime 3D models are authored low-poly adaptations; KayKit vendor runtime is CC0; audio is curated CC0. Steam content survey requires disclosure of player-facing AI-generated content. Confirm: title splash screen = yes, runtime gameplay = no AI-generated content?

**Abandoned Concepts (Confirm Exclusion)**
6. **Google Drive POC Design Doc v4 (Unreal/PvP/Caravans):** User instructions state this is a different abandoned concept, NOT the current Godot game. Confirm for record: do not import mechanics, scope, or promises from that document. Current source of truth: `_briefs/Shard_and_Sovereign_Codex_Build_Brief.md`, `docs/CURRENT_PRODUCT.md`, `docs/RELEASE_READINESS_PLAN.md`, `docs/design/`.

**Polish & Accessibility**
7. **Lower-End GPU Minimum Requirements:** Current evidence limited to RTX 4070 (183.5 FPS avg, 28.2ms p95 at Recommended; 181.4 FPS, 28.8ms at Low). Scalable Low profile exists but unmeasured on integrated GPU. Before publishing Steam minimum requirements: define target hardware (Intel integrated? GTX 1050?), measure, tune, or raise minimum spec?

8. **Night Lighting Readability:** Playtest.6 improved night lighting (ambient 0.50, sun 0.35, fill 0.32) while maintaining atmospheric mood. Rendered mean luminance ~0.27 (night/day ratio). Pilots must verify units, threats, and UI remain readable without destroying cozy-horror aesthetic. If pilots report visibility issues: iterate lighting or add optional brightness slider?

---

## Release Blockers

**Cannot distribute to external testers until:**
1. ✅ Versioned reproducible build exists (playtest.13 current)
2. ✅ Saves are safe (validated temp writes, backup recovery, version rejection, structural validation)
3. ✅ No unresolved reproducible crash, save loss, or progression blocker in automated checks (20/20 suites pass)
4. ❌ **60-minute rendered package soak with audio device reconnection validation**
5. ❌ **5-person observed new-player pilot (target 4/5 comprehension gate)**
6. ❌ **3+ human complete matches including natural win and understandable defeat**
7. ❌ **Lower-end GPU performance evidence at Scalable Low settings**
8. ❌ **Clean physical Windows machine test (non-dev environment)**

**Cannot proceed to closed Steam Playtest until:**
- All above gates pass
- Owner Steamworks account / App IDs / Playtest child app configured
- Asset provenance inventory reconciled with exported runtime
- Steam content survey completed (AI disclosure, rights clearance)
- SteamPipe upload tested on non-dev Steam account
- Store page materials ready (screenshots, capsule, description, measured requirements)

**Cannot proceed to public Steam demo until:**
- Closed playtest cohort feedback processed (crashes, progression blocks, comprehension, pacing)
- High-impact fixes validated in follow-up cohort
- Proposed public-demo gate (from RELEASE_READINESS_PLAN):
  - Zero unresolved crashes, save corruption, or economy/Binding blockers
  - 80%+ observed new players complete opening loop without coaching
  - 80%+ can explain Shard objective and danger escalation by relevant encounter
  - 5+ unassisted complete matches across 3 seeds and multiple machines
  - No recurring critical readability complaints; hardware budget met
  - Follow-up cohort confirms important fixes

---

## References & Documentation

**Primary Design & Scope:**
- `_briefs/Shard_and_Sovereign_Codex_Build_Brief.md` — founding goals, non-negotiable rules, One Shard vertical slice scope
- `docs/CURRENT_PRODUCT.md` — production rules, persistence, supported candidate scope (updated 2026-09-25)
- `docs/design/game_pillars.md` — living logistics, settlement-first, simulation authority, readable isometric world
- `docs/design/one_shard_scope.md` — single-province match rules, rivalry, Binding
- `docs/design/one_shard_rivalry.md` — rival realm behavior, Outpost contention, assault mechanics
- `docs/design/visual_direction.md` — opening_style craft language, cozy-horror aesthetic

**Release Planning:**
- `docs/RELEASE_READINESS_PLAN.md` — ordered work plan, P0/P1 gates, Steam release sequence (approved 2026-09-25)
- `docs/RELEASE_EXECUTION_STATUS.md` — validation results, evidence, remaining gates (**needs update to playtest.13**)
- `docs/PLAYTEST_GUIDE.md` — player-facing instructions, controls, first-session guidance (**needs update to playtest.13**)
- `docs/PLAYTEST_KNOWN_ISSUES.md` — disclosed limitations, UX improvements by playtest version (**needs update to playtest.13**)
- `docs/OBSERVED_PLAYTEST.md` — structured pilot observation protocol

**Architecture & Technical:**
- `docs/architecture/architecture_overview.md` — system responsibilities, simulation/presentation separation
- `docs/architecture/simulation_model.gd` — authoritative GDScript simulation, one_shard_* modules
- `docs/architecture/data_contracts.md` — building/resource/entity definitions
- `docs/architecture/save_load.md` — persistence format, validation, migration
- `docs/architecture/pathfinding.md` — road network, carrier routing
- `docs/technical_debt.md` — known limitations, cleanup triggers (**needs review for stale items**)

**Art & Audio:**
- `docs/art/OPENING_STYLE_MODELS.md` — 19 opening_style model scenes, generation, validation (playtest.3–13)
- `docs/art/ASSET_LEDGER.md` — KayKit CC0 runtime provenance
- `docs/art/AUDIO_LICENSE_LEDGER.md` — curated CC0 audio provenance
- `docs/art/AUDIO_PROVENANCE_PLAYTEST10.md` — BGM integration details
- `assets/art_direction/opening_style_v1/README.md` — art kit generation prompts, AI disclosure

**Build & Verification:**
- `docs/BUILD_AND_TEST.md` — build commands, verification suite
- `tools/build_release.ps1` — versioned Windows export, hash manifest
- `tools/verify_release.ps1` — 20-suite validation runner
- `tools/test_release_package.ps1` — rendered soak tests
- `tests/` — automated regression suites (parse, rebuild, rivalry, bakery, wyrdfall, full_run, etc.)

---

## Summary

**Current Status:** Playtest.13 delivers castle/barracks visual refinement matching title art. Core gameplay loop implemented, 20/20 automated checks pass, saves validated. Ready for human validation gates.

**Next Critical Path:** 
1. Complete documentation sync (version references, task pointers)
2. Execute remaining P0 validation gates (60-min soak, pilot, full matches, lower-GPU, clean machine)
3. Owner: initiate Steamworks setup in parallel
4. Closed playtest cohort → feedback → fixes → public demo

**Scope Discipline:** No new buildings, multiplayer, hero combat, or engine changes until One Shard loop validated with real players. Focus on shipping a complete, comprehensible, reliable experience within existing scope.
