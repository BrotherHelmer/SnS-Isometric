# Release execution status — 2026-09-25

Milestone: internal Windows candidate for closed Steam Playtest, then public demo. Steamworks setup remains deferred by the owner. **Not approved for external release.**

## Implemented

- Versioned Forward+ export, pinned Godot/templates, explicit runtime resources, source/output hash manifest, standalone-copy validation and engine/component license notices.
- Verified temporary save writes, last-valid backup recovery, unsupported-version rejection, map/entity/nested ledger validation, exact RNG state, clearing targets/priorities, autosave, saved display settings, save-before-quit and previous-realm preservation.
- Fixed construction reservations stranded by cancellation before pickup, temporary clearers accumulating as zero-capacity carriers, manual orders discarding carried goods, and night tasks altered on reload. Clearers now release exhausted targets removed by other workers and deliver existing cargo before harvesting again after shelter.
- Removed the simulation/rivalry reference cycle and unused audio objects. Scene tests allow the audio thread to drain before process shutdown.
- Pressure contrast, smoother fog boundary, exterior mist and existing founding-yard props. Raised exterior mist removes thin slab-edge lines at maximum zoom. Captures cover 720p/1080p and close/normal/strategic zoom; broader pan/seed review remains useful.
- Owner-selected remedy for the Outpost deadlock: an assault/recall command for trained patrol soldiers, travel and in-range strikes against visible rival Outposts, with disk persistence.
- Local feedback bundle and current scope/build/playtest documentation. Historical demo and phase evidence retained.
- Fixed zero-scale death animations that produced singular-transform rendering errors. Added cross-process persistence checks, audio-mixer sampling in package diagnostics and Windows-path quoting in test launchers.

## Evidence and limits

All 17 focused checks passed in the working checkout and a new temporary clone of source checkpoint `e8470c1`. The clone imported assets without an existing `.godot` cache and exported successfully. Its only generated untracked file was an assault-test UID, now included in the follow-up checkpoint. This proves reconstruction on this PC, not a second physical machine. The verification runner records focused save, logistics, session, assault, UI, economy, rivalry and combat checks in `artifacts/release_candidate/verification.json`. Supported-version migration tests relabel current data to exercise branches; genuine historical-save compatibility remains unproven.

The exported checkpoint completed 3,600.5 real seconds and 118 save/load/menu cycles, with no gameplay assertion failure or crash. The strict runner **failed** because WASAPI logged `GetBufferSize error` followed by an invalidated output-device warning around minute 35. Preserve this result as `package_rendered_60min_audio_invalidated`; do not relabel it a clean pass. Godot's [4.7 WASAPI driver](https://github.com/godotengine/godot/blob/4.7-stable/drivers/wasapi/audio_driver_wasapi.cpp) retries device initialization, but audible recovery was not observed. The next package diagnostic records mixer freshness as well as rejecting logged errors. Physical disconnect/reconnect listening remains unverified.

Windows private memory averaged about 1,298 MiB in minutes 15–20 and 1,304 MiB in minutes 45–50. This run shows no large sustained growth after warm-up; it is not a proof of leak freedom. Release-template engine memory counters return zero, so use `process_memory.json`. The latest package runner records an explicit overall `package_validation.json` alongside the in-game report.

Separate processes verified live cargo, an active night raid, natural mid-Binding and an explicitly prepared hunger case. Thirty simulation seconds after restore matched uninterrupted gameplay state within 0.00001 for floats, excluding journal text. Four corresponding standalone-package relaunches passed. A package copied into a path containing spaces also passed. These generated snapshots are not historical-save fixtures.

Current 1080p Forward+ stress samples on this RTX 4070 measured 183.5 average FPS / 28.2 ms p95 frame time at Recommended, and 181.4 FPS / 28.8 ms at Low. Each sample lasts 30 seconds after warm-up, starts with 180 requested civilians and 20 injected hostiles, and uses a scripted developed settlement. Population changes during the run; other diagnostics were running concurrently. These are diagnostic measurements, not minimum-hardware claims.

Unrestricted export was clean. Restricted tests emit an environment-only Windows certificate-store access error; the runner records that exact exception and rejects other engine/script errors. Supported scripts isolate APPDATA so tests do not touch normal saves.

`tests/release_natural_match.gd` is an accelerated command-only diagnostic: authored starting resources, public construction/Binding/assault requests and ordinary ticks, plus disk save/reload. The first attempt ended in three natural defeats and exposed the Outpost rule conflict. Each of the three seeds has since produced a victory across strategy iterations. The latest combined run wins seed 260821 in 1,695 simulation seconds and 717171 in 1,960 seconds; 424242 loses its Town Hall at 2,259.5 seconds during Binding. All three restore mid-Binding successfully. The combined three-win gate remains open. Earlier strategy evidence is retained; do not count a prepared victory as a natural win or retune game rules solely to make this bot pass.

Older `phase4_full_run_harness` prepares world/claim state, and `phase3_2_real_playthrough` jumps the day clock. These remain useful regressions; neither is an unassisted full-match test.

## Remaining gates

1. Improve the general bot strategy or validate the remaining seed through observed play; obtain a combined three-win automated run before closing that planned gate.
2. Rebuild the follow-up checkpoint and complete a clean final-package 60-minute test with audio-mixer sampling. Inspect logs and test audible device reconnection. Check lower-end graphics and a separate physical Windows machine.
3. Confirm the follow-up source reconstructs cleanly after the boundary and diagnostic additions. Read the distribution manifest for the exact packaged revision; do not confuse test-only changes with the frozen binary.
4. Observe five new players using `OBSERVED_PLAYTEST.md`; target four understanding useful construction/delivery within five minutes and the next objective by ten. Play three human full matches, including a natural win and understandable defeat.
5. Later: owner Steamworks/App IDs, distribution/branding rights review, Playtest setup, store assets and Valve review. Then a closed cohort; public demo depends on resulting fixes.

Automated checks cannot certify fun, comprehension, commercial rights, actual minimum hardware or Steam account readiness.
