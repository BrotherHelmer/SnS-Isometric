# Release execution status — 2026-09-25

Milestone: internal Windows candidate for closed Steam Playtest, then public demo. Steamworks setup remains deferred by the owner. **Not approved for external release.**

## Implemented

- Versioned Forward+ export, pinned Godot/templates, explicit runtime resources, source/output hash manifest, standalone-copy validation and engine/component license notices.
- Verified temporary save writes, last-valid backup recovery, unsupported-version rejection, map/entity/nested ledger validation, exact RNG state, clearing targets/priorities, autosave, saved display settings, save-before-quit and previous-realm preservation.
- Fixed construction reservations stranded by cancellation before pickup, temporary clearers accumulating as zero-capacity carriers, manual orders discarding carried goods, and night tasks altered on reload.
- Removed the simulation/rivalry reference cycle and unused audio objects. Scene tests allow the audio thread to drain before process shutdown.
- Pressure contrast, smoother fog boundary, exterior mist and existing founding-yard props. Fresh captures were inspected; all supported zoom/pan limits still warrant review.
- Owner-selected remedy for the Outpost deadlock: an assault/recall command for trained patrol soldiers, travel and in-range strikes against visible rival Outposts, with disk persistence.
- Local feedback bundle and current scope/build/playtest documentation. Historical demo and phase evidence retained.

## Evidence and limits

The verification runner records focused save, logistics, session, assault, UI, economy, rivalry and combat checks in `artifacts/release_candidate/verification.json`. Supported-version migration tests relabel current data to exercise branches; genuine historical-save compatibility remains unproven.

An earlier exported candidate was copied outside the checkout and passed a rendered 60-second menu/assets/save/continue test. Its longer run was deliberately interrupted when another source fix was found; that is not a completed 60-minute soak. Read the latest package report for subsequent results. Release-template engine memory counters return zero; the package runner measures Windows process memory separately.

Unrestricted export was clean. Restricted tests emit an environment-only Windows certificate-store access error; the runner records that exact exception and rejects other engine/script errors. Supported scripts isolate APPDATA so tests do not touch normal saves.

`tests/release_natural_match.gd` is an accelerated command-only diagnostic: authored starting resources, public construction/Binding/assault requests and ordinary ticks, plus disk save/reload. The first attempt ended in three natural defeats and exposed the Outpost rule conflict. Its construction strategy and the new assault path are being checked separately. Do not count a prepared victory as a natural win.

Older `phase4_full_run_harness` prepares world/claim state, and `phase3_2_real_playthrough` jumps the day clock. These remain useful regressions; neither is an unassisted full-match test.

## Remaining gates

1. Demonstrate natural wins through the three-seed command-only harness; finish disk-relaunch coverage for live cargo, hunger, raids and mid-Binding.
2. Complete a 60-minute test of the final package, inspect process memory/logs, and run a current performance profile. Check lower-end graphics and a separate physical Windows machine.
3. Checkpoint the migration and prove clean source reconstruction. The dirty-tree manifest identifies current source; Git HEAD is not yet a full production snapshot.
4. Observe five new players; target four understanding useful construction/delivery within five minutes and the next objective by ten. Play three human full matches, including a natural win and understandable defeat.
5. Later: owner Steamworks/App IDs, distribution/branding rights review, Playtest setup, store assets and Valve review. Then a closed cohort; public demo depends on resulting fixes.

Automated checks cannot certify fun, comprehension, commercial rights, actual minimum hardware or Steam account readiness.
