# Internal candidate limitations

- This candidate is not yet cleared for public Steam release. Steamworks setup and IDs are deferred at the owner's request.
- Human first-session comprehension, unassisted full-match wins/losses, integrated-GPU performance and clean physical Windows-machine testing remain external gates.
- The prior playtest.1 build passed a clean 60-minute rerun after an earlier Windows audio-device invalidation. Playtest.4 passed a rendered 60-second package check; its own hour-long soak and an audible device-reconnection check remain outstanding.
- Nineteen opening-style model scenes, coordinated terrain/lighting and character materials are integrated. This is a stylized adaptation; animated character geometry is retained. Lower-end performance with the new geometry remains unmeasured.
- The three-seed command-only bot now completes all three matches, including mid-Binding save/reload. Human strategy, difficulty and session length remain unvalidated.
- The intended 35–55 minute session length is provisional. Automated checks and accelerated simulations do not establish whether the game is fun or well paced.
- Controller, Steam Deck, Linux, achievements and Steam Cloud are not advertised as supported. The Windows renderer is Forward+; Compatibility is an unverified fallback.
- Asset provenance records cover the KayKit runtime, project-synthesised audio and pre-generated AI title illustration; final branding and the exact distribution manifest still need owner sign-off before public publication.
- Supported save formats are versions 6–8. Test copies of real historical saves before relying on migration for a public update. A save written by a future build is rejected.
- The restricted development environment cannot read the Windows certificate store. An unrestricted save-safety run is clean; this exact environment error is recorded separately from game failures.

See `docs/RELEASE_EXECUTION_STATUS.md` in the project for current validation results and remaining work.
