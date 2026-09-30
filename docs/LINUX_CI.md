# Linux CI (headless + Xvfb)

`tools/linux_ci.sh` is the Linux version of `build_release.ps1`, `verify_release.ps1` and `test_release_package.ps1`. It also runs the in-engine `--evidence-ui` screenshot capture under Xvfb. It runs locally only; there is no GitHub Actions workflow.

## Requirements

- Godot **4.7.stable.official.5b4e0cb0f** for Linux, plus the matching export templates (verify both against the official SHA512-SUMS). Point the script at them with `GODOT_HOME` (default `/home/box/godot/4.7`). That folder must contain `Godot_v4.7-stable_linux.x86_64` and `templates/`.
- `xvfb` / `xvfb-run`, `mesa-vulkan-drivers` (lavapipe) and `libgl1-mesa-dri`, so Forward+ can render in software.
- `python3` with Pillow (for the export audit and the screenshot comparison).

## Usage

```bash
tools/linux_ci.sh --out /tmp/sns_ci                        # full run
tools/linux_ci.sh --repo ../other-checkout --out /tmp/b    # test another checkout
tools/linux_ci.sh --ref path/to/ref_shots --ref-label "before" --label "after"
```

Other options: `--skip-windows`, `--timeout SEC` (per test), `--quick` (dev only; always reports FAIL).

The exit code is 0 only if every step passes. `$OUT/summary.txt` holds the per-step results.

## Steps

| Step | Windows equivalent |
|---|---|
| Engine version pin | build manifest |
| Headless `--editor --import` | `build_release.ps1` import |
| `--check-only` on every `.gd` in `src/ tests/ tools/` (0 parse errors) | parse check |
| `tools/audit_export_packing.py` | export audit |
| The 22 release tests, same list and pass rule | `verify_release.ps1` |
| Extra tests (`EXTRA_TESTS`, e.g. `t_sns_ui_leftovers`), reported separately | – |
| Engine notices + Linux export (+ Windows export) | `build_release.ps1` export |
| Packaged Linux build, `--headless -- --verify-release --soak-seconds=8` | `test_release_package.ps1` (headless) |
| Packaged build under `xvfb-run` (1280x720), `--evidence-ui` | `--evidence-ui` capture |
| Optional PIL comparison against `--ref` shots | – |

## Notes

- Each Godot process gets its own `HOME` and `XDG_*` directories under `$OUT/users/<step>`, so real user data is never touched.
- The export runs in a scratch copy under `$OUT`. There the script adds a "Linux CI" preset and sets `application/modify_resources=false`, because rcedit is not available on Linux, so the Windows .exe icon and version info are not patched. `export_presets.cfg` in the repository is never modified.
- Software rendering (llvmpipe) is roughly 10× slower than a GPU, so the evidence capture takes about 90 s. HUD, fonts and layout match Windows; the 3D world differs slightly in shading and animation timing.
- The import step rewrites some audio `.import` files in the checkout, the same as on Windows. Do not commit those changes.
