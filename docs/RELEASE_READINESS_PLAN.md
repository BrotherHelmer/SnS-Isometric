# One Shard: review and Steam release plan

Review date: 2026-09-25. Route confirmed by the owner: **closed Steam Playtest, then public demo**.

## Verdict

The current 3D source is a substantial playable vertical slice, suitable for supervised internal testing. It is not yet a verified external release candidate. The major systems exist and nine focused suites passed in this review. The next work should establish a dependable build, protect progress, make the opening readable, and validate a natural full match with players.

Do not distribute the existing `dist/ShardAndSovereign_Demo_Windows` package as the current game: its executable, resource pack, ZIP and accompanying documentation are dated 2026-07-24, before the current 3D work. Current gameplay source was modified on 2026-09-02. No replacement export or Steam upload was performed in this review.

## Which goals are current?

The original build brief established physical logistics, a settlement-first experience, authoritative simulation, a readable isometric world, and a complete local win/loss loop. Those remain the design foundation. Later Phase 4–7 work establishes the current product: autonomous settlers in 3D, Wyrd Pressure, a rival realm, explicit Shard Binding, and the Reckoning.

Several older documents conflict with the implementation. Treat them as historical until reconciled:

| Topic | Older wording | Current evidence / planning baseline |
| --- | --- | --- |
| Product | Woodcutter/warehouse prototype; combat excluded | Settlement economy, survival, and single-player Shard rivalry |
| Presentation | 2D pixel art / manual renderer | Production 3D scene with an isometric camera |
| Authority | C# is canonical | Production host instantiates the GDScript simulation; C# is an earlier separate implementation |
| Match duration | Original brief: 15–25 minutes | Phase 4: intended 35–55 minutes; human timing remains unproven |
| Winning | Two nights in original brief; one held night in README | Explicit 120-second Binding, subject to requirements and interruption |
| Roads | Paid and instant in older docs | Current definition has zero resource cost; production construction and rivalry connectivity paths need consistent player copy |
| Failure | Sovereign death in old Steam checklist | Current Phase 4 rules: Town Hall loss, population collapse, or rival Binding |
| Performance | Technical debt still describes ~9 FPS at 200 live inhabitants | Phase 3 documents a substantial fix, with remaining frame-time spikes; minimum hardware is still unmeasured |

**Recommended scope freeze:** Windows, keyboard/mouse, one complete province, existing economy/defence buildings, autonomous units, rival race, Pressure, Binding, save/continue and clear results. Keep 35–55 minutes as a provisional playtest hypothesis, not a store promise. Measure real time and simulation time separately, including pause and speed changes. Revisit duration after the first cohort rather than retuning it blindly to the original brief.

Do not add more buildings, multiplayer, hero combat, campaigns, or a new engine before this loop is validated. Steam Cloud, achievements and controller/Deck support can be separate milestones; advertise only support actually verified.

## Comparison with the design pillars

| Goal | Assessment | Evidence and remaining gap |
| --- | --- | --- |
| Living logistics | Implemented; focused checks pass | Construction, production, carrying and bakery hauling have coverage. A naturally built, sustained economy still needs full-session verification. |
| Settlement before empire | Mechanically present; opening presentation weak | Fresh opening shows a large empty lawn, Town Hall and one visible character. Test whether newcomers find the first satisfying delivery quickly. |
| Simulation owns truth | Largely maintained | Production host calls GDScript authority. The 7,446-line simulation and 2,827-line game root conflict with the brief's modularity goal; isolate risky changes without a wholesale rewrite. |
| Player as founder | Implemented; comprehension unproven | Roads/building requests, autonomous work, growth, defence and expansion exist. Observe players explaining why buildings stall and how to recover. |
| Readable isometric world | Partially met | Fresh captures reproduce near-invisible Pressure text, stair-stepped fog and visible map rim. Minimap, objective guidance and Shard compass exist. |
| Complete strategic match | State transitions work; natural completion unproven | Binding, interruption, rival victory and defeat checks pass. Several harnesses directly prepare state or advance claims; they are not unassisted playthroughs. |
| Reliable release | Not met | Old export, untracked production source, renderer mismatch, weak save validation, and absent clean-machine/Steam install evidence. |

## Evidence from this review

Evidence folder: `artifacts/release_audit_2026_09_25/`. `source_manifest.json` records hashes and dates for key source/configuration files and the existing resource pack. The working-tree snapshot records the pre-existing uncommitted migration; no reset, staging, commit or gameplay edit was made.

Nine existing suites were rerun with the bundled Godot 4.7 engine, headless, with isolated APPDATA inside the evidence folder. All exited 0 with their PASS marker:

| Suite | What it supports |
| --- | --- |
| `phase4_2_parse_smoke` | Current production scripts load |
| `godot_rebuild_smoke` | Broad simulation and reconstruction regressions |
| `godot_rivalry_smoke` | Realm rules, Binding and deterministic rival timing |
| `phase8_bakery_haul` | Farm/bakery hauling regression |
| `phase4_wyrdfall_smoke` | Pressure, objectives and Binding rules |
| `phase4_full_run_harness` | Prepared state checks on seeds 260821, 424242 and 717171 |
| `phase4_2_human_playtest_rescue` | Placement/clearing, storage, guidance and combat checks; despite its name, an automated test |
| `phase6_presence` | Minimap, score wiring, grass layer and fog objects |
| `phase7_review_evidence` | Opening guidance and Night 2 reaching/damaging the yard while remaining survivable |

The tests emitted `Failed to read the root certificate store`; many also emitted ObjectDB/resource cleanup errors. Preserve and investigate these logs. Passing assertions do not make the output error-free. These runs do not establish exported-build stability, audible mix quality or real GPU performance.

A fresh Forward+ capture of the production scene completed on the RTX 4070. Visually inspected:

- `screenshots/01_founding_loop.png`: Pressure text is almost black on a dark field; the opening clearing feels sparse.
- `screenshots/02_fog_edge.png`: the jagged reveal boundary and exposed diagonal island rim remain visible.

These are diagnostic, scripted captures, not human gameplay or store screenshots. A third corner capture was also generated. The render log records engine, renderer and GPU.

The additional `save_validation_probe.gd` reproduced acceptance of a valid save relabelled with unsupported schema version 999. Truncated JSON was correctly rejected, preserving serialized state except the status message. Code inspection also found direct overwrite of the sole save file, no temporary-file/backup transaction, and no production autosave call. Interrupted writes were not fault-injected in this review.

Historical performance evidence is better than the old debt log suggests: Phase 3 reports 69.4 average FPS with 180 civilians plus 20 hostiles on an RTX 4070, but 42.87 ms p95 frames in a four-second sample. This is historical evidence, not a fresh benchmark or proof of sustained minimum-spec performance.

No unassisted human match, 60-minute soak, lower-end GPU test, clean-machine install or Steamworks account inspection was performed. No claim of a fully playable or fun release follows from these automated passes alone.

## Ordered work plan

P0 blocks external distribution or threatens progress. P1 blocks a credible public demo and may be tested in a controlled cohort once disclosed. Estimates below are planning ranges for one developer, not commitments; discovery, tester availability and Valve turnaround can extend them.

### 1. Establish one reproducible current build — P0, 1–2 developer days

Owner: developer; product owner confirms the written scope. Start here.

- Preserve and checkpoint the existing migration in version control after reviewing deletions/untracked files. The current Git history does not contain most of the production game. Ensure a fresh checkout plus documented asset setup is sufficient to build.
- Reconcile README, scope, UX, technical debt, architecture authority, controls and Steam checklist against the current source. Preserve old phase reports as history.
- Pin engine/export-template versions. Give the candidate a unique version/build identifier visible in-game and in diagnostics, with source revision and export hashes in a manifest.
- Make editor, local launcher and exported release use the same chosen renderer. `project.godot` currently defaults to Compatibility while `launch_client.ps1` forces Forward+. Verify a fallback separately if supported.
- Create one release verification/export command, using isolated test saves. Collect exit codes, PASS markers and unexpected engine errors; do not accept exit 0 alone.
- Review export contents. `all_resources` plus the current exclusions is not a demonstrated production-only allowlist; ensure legacy content, lab projects, captures and vendor source are excluded unless needed at runtime.
- Export into a new versioned directory, retaining the July package as historical. Package runtime dependencies and notices, then launch the extracted package from outside the repository.

Exit: a second clean environment can reproduce/import/export the same revision, and the new executable opens the correct 3D game without `.tools`, the editor or source checkout. Exact byte reproducibility is optional; traceable inputs and matching gameplay/version are mandatory.

### 2. Protect saves and make failures diagnosable — P0, 2–4 developer days

Owner: developer. Depends on a known candidate baseline; may share the first release branch.

- Replace direct save overwrite with a validated temporary write, flush/close, safe replacement and last-known-good backup. Handle write failure without damaging the previous save.
- Validate version bounds, required structure, map dimensions and entity references before mutating the live simulation. Reject unknown future formats. Test supported v6/v7-to-v8 migration explicitly; keep older unsupported saves intact with clear copy.
- Add a modest rolling autosave and a clear save/quit flow. Prevent accidental loss from Quit or starting another realm; test window-close as well as menu actions.
- Test real disk save, process exit, relaunch and continue during construction delivery, worker cargo, hunger, active raid, rival progression and mid-Binding. Check inventories, reservations, targets and objective progress; continue simulation after reload.
- Separate Playtest and demo save locations or establish an explicit tested migration policy before shipping both under the same Godot application name.
- Export a small local feedback bundle: build, seed, settings, current save and relevant log. Preserve previous-run evidence across restart; avoid requiring testers to locate developer folders.
- Triage certificate-store and cleanup errors in normal exported startup/quit. Document environment-only exceptions with evidence; fix errors reproduced in the shipped game.

Exit: no lost/duplicated goods or broken progression in the persistence matrix; corrupt/unsupported saves fail safely; interrupted saves recover from the previous valid file. No unresolved reproducible crash, save loss or progression blocker.

### 3. Fix the first ten minutes and essential readability — P1, 2–3 developer days

Owner: developer/design. Depends on the candidate baseline.

- Fix Pressure label contrast independently of the meter fill; check every band at 1280×720 and 1920×1080. Object visibility assertions are insufficient for readability.
- Improve the fog boundary and cover the exposed map rim at supported zoom/pan limits. Preserve hidden-world information rules.
- Compose a more inhabited founding yard using existing art, props, work activity and camera framing. Keep placement space usable; add no buildings or artificial production.
- Present one actionable opening instruction consistent with the current House/Lumber/Farm economy. Explain road access, staffing, full storage, wheat-to-bread hauling and the next remedy through inspection.
- Make threat direction, dusk preparation, rival progress and Binding requirements understandable without the developer narrating. Show what interrupted Binding and how to restore it.
- Verify menu/build/inspector/minimap overlap, font size, pause/resume, focus loss, display changes and volume settings. Confirm which settings persist; current fullscreen toggle only changes the running window.

Exit: in a five-person observed pilot, at least four can begin useful construction and explain a visible delivery within five minutes, and explain the next objective by ten minutes, without coaching. Treat this as a proposed small-sample gate, not statistical proof.

### 4. Prove a complete natural match and a stable package — P0/P1, 2–4 developer days plus tester time

Owner: developer/QA and testers. Requires stages 1–3 for the test candidate.

- Run the current full regression set through the production authority, including UI/input and disk persistence. Record stale test expectations separately from actual game failures; do not change rules to satisfy obsolete tests.
- Build a command-driven full-match regression on seeds 260821, 424242 and 717171 using normal starting resources and public gameplay requests. No injected stockpiles, instant buildings, invulnerable units, fabricated claim state or direct `_finish_run` call. Accelerated simulation is acceptable but must be labelled.
- Play at least three complete human sessions on different seeds, including one natural victory and one understandable defeat. Record where the player stalled, time to food stability, first raid, first expansion, Binding and result.
- Exercise broken roads/reconnection, clearing, depleted deposits, full storage, starvation/recovery, soldier staffing, interrupted Binding, rival victory and restart. Expand to a broader seed sweep to look for inaccessible resources and unwinnable openings.
- Run a 60-minute soak of the packaged executable with saves/reloads, repeated nights, combat, menus and restart. Check memory growth, hangs and log errors.
- Run clean installs on Windows machines without Godot; test at least one integrated/low-end GPU plus the development GPU. Measure developed settlement and Reckoning frame times, not just an empty opening.
- Proposed performance budgets: 60 FPS target on the selected recommended system; 45 FPS target on selected minimum hardware at Low, with p95 frame time no worse than 33 ms and no repeated >100 ms stalls in normal supported play. Choose actual hardware and validate these budgets before publishing requirements.
- Test 720p, 1080p, 16:10, ultrawide, high-DPI and fullscreen/windowed; keyboard layouts, alt-tab and audio device changes. Advertise only the platforms and input modes exercised.

Exit: stage 2 safety gates remain green; all three seeds support a natural complete loop; representative hardware meets the adopted budget; the installer/package needs no developer intervention. Human run-length and comprehension evidence replace intended timing claims.

### 5. Prepare Steam and asset provenance in parallel — P0, owner + developer

Begin administrative preparation while stages 1–4 are underway. Steamworks account, real App IDs, onboarding status and existing store assets were not accessible/verified in this review.

- Owner: establish the real base-game app and complete applicable Steamworks onboarding; confirm product name, publisher identity and positioning. Use the current One Shard game in store claims.
- Create a separate linked **Steam Playtest** child app; configure Windows depot, launch executable, assets and required review. Use controlled admissions or Playtest keys for the initial closed cohort. A passworded branch alone does not give testers ownership. [Steam Playtest documentation](https://partner.steamgames.com/doc/features/playtest)
- Developer: prepare SteamPipe configuration using real IDs, upload the approved candidate to a test branch, verify installation/update on a non-developer account, preserve save compatibility and retain a rollback build. Account changes and uploads are future work, not completed by this plan.
- Complete an inventory of the assets actually shipped. The KayKit CC0 ledger and original-synthesis audio ledger are useful existing evidence; reconcile them with runtime assets, UI/fonts, legacy generated images, logo and notices. Do not repeat the old blanket assertion that no provenance exists, or treat a partial ledger as clearance for every exported asset.
- Owner: complete the content survey, including relevant player-facing AI-generated art/audio/text if present. Ordinary procedural synthesis is not automatically generative-AI content; inspect actual provenance. [Steam Content Survey](https://partner.steamgames.com/doc/gettingstarted/contentsurvey)
- Supply current gameplay screenshots, capsule/library assets, clear description, supported languages, measured system requirements and a working support route. Keep optional platform features off the advertised list until validated.

Exit: exact current build installs and runs through Steam; access, update, rollback and save behaviour are tested; required content/rights records and Steam checklists are complete. Owner controls public release timing.

### 6. Closed Steam Playtest — 1–2 calendar weeks for two feedback rounds

Owner: product owner recruits; developer triages; testers play. Depends on stages 1–5 passing their external-test gates.

First cohort: 5–8 people, mostly unfamiliar with the project. Observe the first ten minutes without coaching, then let them continue. Second cohort: 15–25 people after the highest-impact fixes. These are proposed practical cohort sizes.

Capture build/seed/hardware, session duration, first successful delivery, food recovery, first night outcome, reason for stopping, result, save/continue success, and whether they chose to start another run. Ask them to explain Pressure, roads and the Shard race in their own words. Use existing local journals and voluntary feedback; remote analytics are not required.

Triage order: crash/save loss -> progression/economy lock -> misunderstanding -> pacing/balance -> visual/audio polish. Reproduce each serious report with its seed and save before tuning broadly. Each round uses one identifiable build; rerun affected gates after fixes.

Public-demo gate, proposed:

- Zero unresolved reproducible crashes, save corruption or economy/Binding blockers.
- At least 80% of observed new players perform the opening economy loop without coaching; at least 80% can explain the Shard objective and why danger rises by the relevant encounter.
- At least five unassisted complete matches across three seeds and multiple machines, including natural victories and defeats. Record completion and voluntary restart rates; if most players quit before seeing the central tradeoff, improve the experience before launch.
- No recurring critical readability complaint; normal supported play meets the hardware budget.
- A follow-up cohort confirms the important fixes. Small samples guide iteration; they do not establish market demand.

### 7. Public Steam demo

Owner: product owner and developer. Depends on the closed-playtest gate.

- Freeze a demo candidate with one complete One Shard loop, current controls, known issues, support route and version. Apply final asset/packaging audit to this exact build.
- Create/configure the separate Demo app linked to the base game. Ensure the base game's Coming Soon page is public before releasing a demo ahead of the game. Complete demo review; after release, republish the base page so the download button appears. [Steam demo documentation](https://partner.steamgames.com/doc/store/application/demos)
- Submit near-final materials with scheduling buffer: Valve currently describes 3–5 business days for review and asks developers to allow at least seven business days. Do not promise a launch date before readiness and review dependencies are satisfied. [Steam review process](https://partner.steamgames.com/doc/store/review_process)
- Verify the exact Steam download on a clean non-developer account, with save/continue, result/restart, update and rollback. Publish current gameplay footage showing a developed economy, readable night defence and Binding.
- Staff the initial support window, keep a tested rollback available and triage actual player failures. Reassess scope/retention before committing to paid Early Access or a full commercial release.

## Suggested sequence and first task

Allow roughly **7–13 developer days** for stages 1–4, plus Steam/store work, human testing and review buffers. Stages 5 and recruiting can overlap engineering. This is a budgeting range, not a release-date estimate; no hardware results or player outcomes are yet available to justify one.

The immediate task is **create the current, reproducible Windows playtest candidate and harden its saves**. Follow with Pressure contrast and fog/yard readability, then the five-person pilot. Keep broader content expansion behind the public-demo gate.

## Primary project references

- `_briefs/Shard_and_Sovereign_Codex_Build_Brief.md`: founding goals and non-negotiable rules.
- `docs/design/game_pillars.md`: logistics, founder role and readability.
- `docs/architecture/PHASE_4_WYRDFALL_ONE_SHARD_PLAYABLE_CORE.md`: current match loop and unproven human timing.
- `docs/architecture/PHASE_6_PRESENCE.md`, `docs/tasks/current_task.md`: latest presentation direction.
- `docs/architecture/PHASE_3_LIVING_SETTLEMENT_COMBAT_REPORT.md`: historical performance improvement and frame-tail limits.
- `docs/art/ASSET_LEDGER.md`, `docs/art/AUDIO_LICENSE_LEDGER.md`: existing provenance records.
- `artifacts/release_audit_2026_09_25/logs/`: fresh checks and save reproduction.
