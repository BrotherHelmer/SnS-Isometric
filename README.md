# Shard & Sovereign

A Windows 3D settlement survival game: build an economy, move goods with workers, defend against night raids, and race a rival realm to Bind the central Shard.

## Current candidate

`0.2.0-playtest.1` is an internal test candidate. The agreed release sequence is **closed Steam Playtest, then public demo**. Steamworks setup is deferred. The July `0.1.0-demo` package is historical and does not represent this source.

- [Execution status and open release gates](docs/RELEASE_EXECUTION_STATUS.md)
- [Current product rules](docs/CURRENT_PRODUCT.md)
- [Playtest instructions](docs/PLAYTEST_GUIDE.md)
- [Candidate limitations](docs/PLAYTEST_KNOWN_ISSUES.md)
- [Build and verification](docs/BUILD_AND_TEST.md)
- [Full release plan](docs/RELEASE_READINESS_PLAN.md)

The versioned Windows folder and ZIP are under `dist/ShardAndSovereign_0.2.0-playtest.1`. A build manifest records source and executable hashes. Git HEAD alone does not identify an uncommitted candidate.

## Development

Use Godot **4.7 stable, 5b4e0cb0f**, with matching Windows export templates. The launcher, editor and exported candidate use Forward+.

```powershell
./tools/verify_release.ps1
./tools/build_release.ps1
./tools/test_release_package.ps1 -Rendered -SoakSeconds 60
```

Launch locally with `Play SnS 3D.bat`, or open `ShardAndSovereign.exe` from the extracted candidate. Keep its PCK beside the executable.

Production scene: `src/GodotClient3D/Scenes/production_3d.tscn`. Authority: `src/GodotClient/Scripts/one_shard_simulation.gd` and its `one_shard_*` rules modules. The 3D client displays authoritative state and sends gameplay requests. Earlier C# and 2D prototypes are historical; their tests do not establish production readiness.

Runtime models, textures and animation libraries live in `assets/settlement3d/runtime`; audio lives in `assets/settlement/audio`. Raw vendor archives are excluded from the export. See the [art ledger](docs/art/ASSET_LEDGER.md) and [audio ledger](docs/art/AUDIO_LICENSE_LEDGER.md).

Previous README claims are preserved in `docs/history/README_before_playtest.md`. Follow current scope and execution status when an older phase report disagrees.
