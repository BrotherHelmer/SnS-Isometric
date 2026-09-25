# Reproduce the Windows candidate

## Pinned toolchain

Godot 4.7 stable, build `5b4e0cb0f`. Place the official Windows editor/console executables in `.tools/godot-4.7/` and the matching x86_64 debug/release export templates in `.tools/godot-4.7/templates/`. The build manifest records engine and template hashes. Do not substitute another engine version for a release build.

Production resources live in `assets/settlement3d/runtime/` and `assets/settlement/audio/`. Keep runtime GLTF/BIN/textures together. Godot recreates `.godot/` imports from these files. Raw vendor ZIPs, the phase-1 lab, historical outputs, and the C# prototype are not release inputs.

## Commands

From PowerShell at the repository root:

```powershell
./tools/verify_release.ps1
./tools/build_release.ps1
./tools/test_release_package.ps1 -Rendered -SoakSeconds 3600 -ValidationSave artifacts/phase3_2/persistence/eighteen_step_playthrough.json
```

On a fresh checkout, run `build_release.ps1` first: it imports GLB/textures before invoking verification. Use `verify_release.ps1` alone for an already imported workspace. Verification isolates user data for each test, imposes timeouts, records exit codes/PASS markers and rejects unexpected engine errors. `artifacts/release_candidate/verification.json` is the result index. The exact certificate-store error observed only under restricted execution is permitted; ordinary game/script errors are not.

The build imports assets, exports the pinned production project, records source/output hashes and source revision, copies playtest instructions/notices, and creates a ZIP. `-SkipVerification` is for internal packaging diagnosis only; it is not a release approval.

The selected-resource export includes the production scene and explicitly enumerated runtime models/audio, with their Godot dependencies. Validate the packaged executable from a directory outside the checkout and inspect its resource listing before distributing it. The source fingerprint is authoritative for an uncommitted candidate; Git HEAD alone is not its identity.

The local launcher, editor and export all use Forward+. New Playtest saves live in `ShardAndSovereign/Playtest`, separate from the old demo.

The package test copies the distribution outside the checkout, isolates its user data, samples Windows process memory, and drives the real executable through menus, saves/reloads and restarts. Its developed-settlement input is scripted; the soak does not establish natural match pacing or human usability. Native release binaries cannot load an external test script, so an explicit `--verify-release` diagnostic flag is built into the candidate and is inactive during normal play.

`tests/release_natural_match.gd` separately exercises a command-only bot on three authored seeds. It records orders and wins/defeats without adding stockpiles or completing buildings instantly. Run it headless with isolated APPDATA after the focused gate, and inspect `natural_match.json`; the default gate does not hide its result inside prepared-state tests.
