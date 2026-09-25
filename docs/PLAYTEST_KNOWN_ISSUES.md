# Internal candidate limitations

- This candidate is not yet cleared for public Steam release. Steamworks setup and IDs are deferred at the owner's request.
- Human first-session comprehension, unassisted full-match wins/losses, integrated-GPU performance and clean physical Windows-machine testing remain external gates.
- A 60-minute test completed its gameplay checks but logged a Windows audio-device invalidation. Audio reconnection needs a listening check; a clean final-package soak remains required.
- The three-seed command-only bot now completes all three matches, including mid-Binding save/reload. Human strategy, difficulty and session length remain unvalidated.
- The intended 35–55 minute session length is provisional. Automated checks and accelerated simulations do not establish whether the game is fun or well paced.
- Controller, Steam Deck, Linux, achievements and Steam Cloud are not advertised as supported. The Windows renderer is Forward+; Compatibility is an unverified fallback.
- Asset provenance records cover the KayKit runtime and project-synthesised audio; final branding and the exact distribution manifest still need owner sign-off before public publication.
- Supported save formats are versions 6–8. Test copies of real historical saves before relying on migration for a public update. A save written by a future build is rejected.
- The restricted development environment cannot read the Windows certificate store. An unrestricted save-safety run is clean; this exact environment error is recorded separately from game failures.

See `docs/RELEASE_EXECUTION_STATUS.md` in the project for current validation results and remaining work.
