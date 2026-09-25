# Presentation Pass Validation

## Acceptance evidence

| Area | Evidence | Result |
| --- | --- | --- |
| Authored opening and first order | `godot_presentation_smoke.gd`; screenshots 02–07; `opening_sequence.png` | Pass |
| Left visual command dock | Screenshots 02, 08–12; smoke checks all 13 buildable thumbnails | Pass |
| No bottom grid / right inspector / desktop arrow pad | Presentation smoke and all 28 screenshots | Pass |
| Objective not truncated | Screenshot 04 and smoke exact-string assertion | Pass |
| Ordinary Lumen view has no precise cyan radius | Presentation smoke and night screenshot 12 | Pass |
| Settler, carrier, soldier, Sovereign and enemy locomotion | `character_motion_reel.png`; `CHARACTER_ANIMATION_AUDIT.md` | Pass with documented shared-atlas fallbacks |
| Main-menu and adaptive score resources | Five loaded synchronized stems asserted by presentation smoke; export-pack file list | Pass |
| Audio controls | Screenshot 13; values/defaults/mute exercised in presentation smoke | Pass |
| Both target resolutions | 14 screenshots at 1280×720 and 14 at 1920×1080 | Pass |
| Performance after UI/animation/audio | 135.8 opening, 81.8 busy day, 78.5 night at 1920×1080 | Pass |
| C# simulation regression | 28/28 from the Release executable test harness | Pass |
| Godot deterministic simulation regression | `REBUILD_SMOKE PASS` during this pass | Pass |
| Windows resource pack | Final `.pck` built successfully with 102 packed resources, including every new score/SFX import | Pass |
| ZIP integrity | Eight expected entries opened and enumerated through .NET ZipArchive | Pass |
| Final exported EXE click-through | Desktop launch approval was rejected after the Codex session hit its approval-usage limit | Not re-run on final PCK |

## Capture roots

- `artifacts/presentation_pass/1280x720/`
- `artifacts/presentation_pass/1920x1080/`
- `artifacts/presentation_pass/motion/`

The final fog optimisation was made after the screenshot run. It only replaces individually drawn unrevealed fog diamonds with the same scene’s continuous dark-green map backing; authored terrain, UI, characters and every captured acceptance state are unchanged.

## Package

- Folder: `dist/ShardAndSovereign_Demo_Windows/`
- ZIP: `dist/ShardAndSovereign_Demo_Windows.zip`

The executable wrapper is the previously validated Godot 4.7 Windows binary; the adjacent `.pck` is the newly built presentation content. The package should not be marked release-accepted until the final pair is launched once outside this constrained session and the Play Demo button, opening order, audio and pause/settings paths are exercised.
